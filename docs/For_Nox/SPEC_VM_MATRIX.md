# SPEC_VM_MATRIX — Matrix 65536 VM

> Mọi operation = O(1). Không scan. Không if/else chain.
> 128KB matrix. Fit L1 cache. 1 memory access per instruction.

---

## Tại sao

```
HIỆN TẠI:
  var_table:  flat array, scan backward O(n), leak vĩnh viễn
  opcode:     if/else chain hoặc jump table (đã có 256-slot)
  KnowTree:   256 buckets, scan O(bucket_size)
  Silk:       hash → scan adjacency list
  
  → THE BOMB: var_table leak
  → O(n) mọi nơi
  → Crash khi data lớn

SAU:
  var_table:  matrix[hash] → O(1), overwrite thay accumulate → không leak
  opcode:     matrix[op] → O(1) jump
  KnowTree:   matrix[mol] → O(1) exact, O(243) nearest
  Silk:       matrix[mol_pair] → O(1)
  
  → THE BOMB chết
  → O(1) mọi nơi
  → Scale tới 65536 entries per matrix
```

---

## M1. Matrix cấu trúc

```
Matrix = contiguous u16[65536] hoặc u64[65536]
Index = 16-bit key (0x0000 — 0xFFFF)
Value = tùy loại matrix

Memory:
  u16 matrix: 65536 × 2 bytes = 128 KB
  u64 matrix: 65536 × 8 bytes = 512 KB
  Cả hai fit L1/L2 cache.
  
Allocate: mmap tại boot, cùng lúc với heap.
Clear: memset 0, O(1) amortized (lazy clear hoặc generation counter).
```

---

## M2. Var Matrix — thay var_table

### Hiện tại

```asm
;; var_table: flat array [hash:8][ptr:8][len:8] × N entries
;; Lookup: scan backward → O(n)
;; Store: push entry → never pop → LEAK
;; THE BOMB: entries tích lũy vĩnh viễn
```

### Sau

```asm
;; var_matrix: u64[65536] — mỗi slot = 1 biến
;; Index = hash(name) & 0xFFFF
;; Value = packed [ptr:48][len:16] hoặc [f64 bits]

;; Store(name, value):
;;   slot = hash(name) & 0xFFFF
;;   var_matrix[slot] = value
;;   → O(1). Overwrite. Không accumulate. Không leak.

;; Load(name):
;;   slot = hash(name) & 0xFFFF
;;   return var_matrix[slot]
;;   → O(1). Không scan.

;; Scope cleanup (function return):
;;   Option A: Generation counter
;;     Mỗi slot = [gen:16][value:48]
;;     fn call → gen++
;;     fn return → gen--
;;     Load: chỉ thấy slot có gen <= current
;;     → O(1) cleanup (lazy, không clear slots)
;;
;;   Option B: Scope snapshot bitmap
;;     fn call → save bitmap (which slots occupied) → 65536 bits = 8KB
;;     fn return → restore bitmap → clear new slots
;;     → O(changed_slots) cleanup
;;
;;   Option C: Shadow stack per slot
;;     var_matrix[slot] = top of mini-stack
;;     fn call → push NULL marker
;;     fn return → pop until marker
;;     → O(locals_in_function) cleanup
```

### ASM implementation (Option A — simplest)

```asm
;; BSS:
var_matrix:     .space 65536 * 16    ;; [gen:8][ptr:8] per slot = 1MB
                                     ;; hoặc [gen:2][value:14] = 1MB
var_gen:        .quad 0              ;; current generation

;; Store:
op_store_matrix:
    ;; rax = hash(name)
    and     $0xFFFF, %eax            ;; slot = hash & 0xFFFF
    lea     var_matrix(%rip), %rdx
    shl     $4, %eax                 ;; slot × 16 bytes
    mov     var_gen(%rip), %rcx      ;; current generation
    mov     %rcx, (%rdx, %rax)      ;; store gen
    ;; store value (from VM stack)
    mov     (%r14), %rsi             ;; ptr
    mov     8(%r14), %rdi            ;; len
    mov     %rsi, 8(%rdx, %rax)     ;; store ptr  (offset +8)
    ;; len stored separately or packed
    add     $16, %r14                ;; pop stack
    jmp     vm_loop

;; Load:
op_load_matrix:
    and     $0xFFFF, %eax
    lea     var_matrix(%rip), %rdx
    shl     $4, %eax
    mov     (%rdx, %rax), %rcx      ;; load gen
    cmp     var_gen(%rip), %rcx      ;; gen <= current?
    ja      .load_undefined          ;; expired → undefined
    mov     8(%rdx, %rax), %rsi     ;; load ptr
    sub     $16, %r14
    mov     %rsi, (%r14)
    movq    $F64_MARKER, 8(%r14)    ;; or real len
    jmp     vm_loop

;; Scope enter (function call):
op_scope_enter:
    incq    var_gen(%rip)            ;; gen++
    jmp     vm_loop

;; Scope leave (function return):
op_scope_leave:
    decq    var_gen(%rip)            ;; gen--
    ;; Slots from inner scope now invisible (gen > current)
    ;; NO cleanup needed. Lazy. O(1).
    jmp     vm_loop
```

---

## M3. KnowTree Matrix — thay bucket array

### Hiện tại

```
256 buckets (S×16 + R) → bỏ V, A, T
Nearest = scan 3×3 buckets → O(9 × bucket_size)
```

### Sau

```
kt_matrix: u16[65536]
Index = mol (16-bit P_weight = CHÍNH LÀ index)
Value = fact_index (u16, trỏ vào __kt_facts array)

Exact match:
  fact_idx = kt_matrix[mol]
  → O(1)

Nearest (khi exact miss):
  Scan 5D neighbors: S±1, R±1, V±1, A±1, T±1
  = 3^5 = 243 cells max
  → O(243) = O(1) constant

  Optimized: scan by dimension priority
    1. Same S,R (cùng bucket cũ) → check V±1, A±1, T±1 = 27 cells
    2. Nếu miss → expand S±1 hoặc R±1 → 81 cells
    3. Nếu miss → full 243
  Average: <50 lookups
```

### Collision (nhiều facts cùng mol)

```
Option A: kt_matrix[mol] = head of linked list trên heap
  Matrix chứa pointer → first fact_idx
  fact_idx.next → second fact_idx → ...
  Lookup O(1), iterate O(k) với k = facts cùng mol

Option B: kt_matrix[mol] = bucket_array_index
  Mỗi mol có 1 mini-array chứa tất cả fact indices
  = giống bucket hiện tại nhưng index = mol thay S×16+R

Option C: kt_matrix[mol] = first fact_idx, overflow → linear probe
  Simple. Tốt nếu collision rate thấp (<10%).
  65536 slots, ~500K facts → ~8 facts/slot average
  → Cần Option A hoặc B
```

### ASM

```asm
;; BSS:
kt_matrix:      .space 65536 * 2    ;; u16[65536] = 128KB

;; Exact lookup:
;;   movzwl mol, %eax
;;   movzwl kt_matrix(,%rax,2), %ecx   ;; fact_idx = kt_matrix[mol]
;;   test %ecx, %ecx
;;   jz .kt_miss                        ;; 0 = empty

;; Store:
;;   movzwl mol, %eax
;;   movw fact_idx, kt_matrix(,%rax,2)  ;; kt_matrix[mol] = fact_idx

;; Nearest (5D neighbor scan):
kt_nearest_matrix:
    ;; Unpack query mol → (S,R,V,A,T)
    ;; For each neighbor in 5D:
    ;;   repack (S±δs, R±δr, V±δv, A±δa, T±δt)
    ;;   check kt_matrix[neighbor_mol]
    ;;   if found → compute distance → track min
    ;; Return closest
```

---

## M4. Opcode Matrix — thay dispatch chain

### Hiện tại (đã tốt — 256-slot jump table)

```
Nox đã có: builtin_jump_table[256] × 8 bytes = 2KB
Dispatch: read opcode → jump_table[op] → execute
→ O(1). Giữ nguyên. Không cần thay.
```

### Mở rộng (optional): 2-byte opcode

```
Nếu cần >256 opcodes:
  opcode_matrix: u64[65536] = 512KB
  2-byte opcode → 65536 possible operations
  → custom opcodes cho KnowTree, Silk, Pipeline
  → opcode 0x0100 = kt_nearest, 0x0101 = kt_learn, ...
  → Pipeline steps = dedicated opcodes thay function calls
```

---

## M5. Silk Matrix — thay adjacency list

### Hiện tại

```
__kt_silk: 256 hash buckets, each = [target, weight, w, w, w, w] × N
Lookup: hash(mol) → scan bucket → O(bucket_size)
```

### Sau

```
Option A: Sparse silk matrix
  silk_matrix: u16[65536] — weight of edge from query to nearest
  Index = (mol_a XOR mol_b) & 0xFFFF
  Value = weight (0 = no edge, >0 = strength)
  → O(1) lookup
  Collision: XOR hash → some false positives. Acceptable.

Option B: Implicit silk (ĐÃ CÓ — implicit_silk.ol)
  Silk = mathematical consequence of 5D space
  implicit_strength(a, b) = computed from shared dimensions
  → O(1), 0 bytes storage, EXACT
  
  Explicit Silk (Hebbian fire) = BONUS on top of implicit
  silk_matrix chỉ lưu BONUS weight, not total
  Total = implicit_strength + silk_matrix[hash(a,b)]
```

---

## M6. Arena + Matrix — cùng lúc

```
mmap layout tại boot:

Address:    [0              ] → VM Stack (16MB)
            [16MB           ] → Heap Zone C — Turn temps (grows up, reset per turn)
            [16MB + zone_c  ] → Heap Zone B — Session data (grows up, reset per session)
            [zone_b_end     ] → Heap Zone A — Permanent (KnowTree facts, strings)
            [zone_a_end     ] → var_matrix (1MB)
            [+1MB           ] → kt_matrix (128KB)
            [+128KB         ] → silk_matrix (128KB, optional)
            [+128KB         ] → Bytecode + Knowledge (from binary)

Total: ~20MB fixed + zones grow as needed.
Tất cả fit trong 4GB mmap hiện tại.
```

### Boot sequence

```asm
_start:
    ;; 1. mmap 4GB
    ;; 2. Partition:
    mov     %rax, %r14              ;; r14 = stack base
    add     $STACK_SIZE, %r14
    
    lea     var_matrix(%rip), %rdi
    xor     %eax, %eax
    mov     $65536*16, %ecx
    rep     stosb                   ;; clear var_matrix
    
    lea     kt_matrix(%rip), %rdi
    mov     $65536*2, %ecx
    rep     stosb                   ;; clear kt_matrix
    
    ;; 3. Load bytecode into heap
    ;; 4. Run boot
```

---

## M7. Collision handling

```
65536 slots. Probability analysis:

Variables:
  Typical program: ~100 active variables
  100 / 65536 = 0.15% occupancy → collision near 0
  Even 1000 vars → 1.5% → collision ~0.01%
  → Open addressing (linear probe) đủ

KnowTree:
  500K facts → 500K / 65536 = 7.6 facts/slot average
  → CHAINING required (linked list per slot)
  kt_matrix[mol] = head_ptr → fact1 → fact2 → ...
  Average chain: 7-8 facts → iterate = fast

Silk:
  Sparse. Explicit edges << 65536²
  Hash collision = false positive → weight slightly wrong
  → Acceptable. Implicit silk = ground truth anyway.
```

---

## M8. Benchmark kỳ vọng

```
                    HIỆN TẠI          MATRIX 65536
─────────────────────────────────────────────────
var lookup          O(n) scan         O(1)
var store           O(1) push+leak    O(1) no leak
scope cleanup       NONE (leak)       O(1) gen counter
kt_exact            O(bucket_size)    O(1)
kt_nearest          O(9×bucket)       O(243) = O(1)
silk lookup         O(bucket)         O(1)
opcode dispatch     O(1) (jump tbl)   O(1) (same)

Memory:
  var_matrix        —                 1MB (or 512KB)
  kt_matrix         —                 128KB
  silk_matrix       —                 128KB (optional)
  Total new         —                 ~1.3MB

Boot time:
  Clear matrices    —                 <1ms (memset)
```

---

## Implement order

```
1. var_matrix + gen counter      (~80 LOC ASM)
   = fix THE BOMB + O(1) lookup
   Test: 1000 nested fn calls, no leak, vars correct

2. kt_matrix + chaining          (~60 LOC ASM + ~40 LOC Olang)
   = O(1) KnowTree lookup
   Test: 500K facts, kt_nearest < 1ms

3. Arena zones (C=turn, B=session, A=permanent)  (~80 LOC ASM)
   = temp strings freed per turn
   Test: load 10K facts/turn, no crash

4. silk_matrix (optional)        (~30 LOC ASM)
   = O(1) silk lookup
   Already have implicit_silk → bonus only

Total: ~250 LOC ASM + ~40 LOC Olang
```

---

## API không đổi

```olang
// Olang code KHÔNG CẦN THAY ĐỔI
let x = 42;              // var_matrix[hash("x")] = 42
let y = kt_nearest(mol); // kt_matrix[mol] → fact
let w = kt_silk_weight(a, b); // silk_matrix[hash(a,b)]

// Nox thấy: nhanh hơn. Không crash. Không leak.
// Nox KHÔNG thấy: matrix bên trong.
```

---

*Matrix 65536 = mọi operation O(1).*
*128KB fit cache. 250 LOC ASM.*
*THE BOMB chết. Scope sạch. KnowTree instant.*
*VM không còn giới hạn.*
