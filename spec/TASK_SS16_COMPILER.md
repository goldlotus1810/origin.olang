# PHÂN CÔNG: SS15 (VM) + SS16 (Compiler)

## SS15 ĐÃ LÀM (VM v2 — vm/x86_64/vm_nox.S)
- Boot sequence (mmap 4GB, read bytecode, init matrices)
- Dispatch loop (256 opcodes, jump table)
- Stack/Arithmetic/Comparison/Control flow opcodes
- Variable system (var_matrix 16384 slots, O(1))
- Register frames (EnterFrame/LeaveFrame/LoadReg/StoreReg)
- Closures (Closure/ClosureCapture/CallClosure)
- Exception handling (TryBegin/CatchEnd/Throw)
- String concat (in op_add)
- 30+ builtins wired (512-slot table)
- Molecular opcodes (Pack/Unpack/Dist/Compose/Dominant)
- KnowTree opcodes (Store/Load/Nearest)
- Silk opcodes (Fire/Decay/Implicit)
- Arena opcodes (AllocA/B/C/ResetC/HeapPin)
- Activation helpers (set/get/add/reset/decay_all)

## SS15 CÒN LÀM (khi SS16 cần)
- Thêm builtins mới (nếu compiler cần)
- Fix bugs VM khi compiler test phát hiện
- SIMD batch operations (§16)
- Security opcodes (§29)
- Self-modification protocol (§17)

## SS16 LÀM (Compiler mới)
- Compiler emit bytecode format "OLNG" (spec §5)
- Lexer + Parser + Codegen targeting VM v2 opcodes
- Builder: compile .ol files → append bytecode to VM binary
- Test: simple programs (emit, let, fn, if, while)
- Self-build: compiler compiles compiler (Gen1==Gen2)

# TASK cho SS16: Compiler mới targeting VM v2

> VM v2: vm/x86_64/vm_nox.S (3256 LOC, 34KB, builds clean)
> Tất cả opcodes + builtins đã wired. SS16 viết compiler emit bytecode cho VM này.

---

## VM v2 đã có gì

### Opcodes (dispatch table 256 entries)
```
Stack:      0x01 Push, 0x15 PushNum, 0x19 PushMol, 0x0B Dup, 0x0C Pop, 0x0D Swap
Variable:   0x02 Load, 0x13 Store, 0x1C StoreGlobal (=Store)
Register:   0x26 LoadReg, 0x27 StoreReg, 0x28 EnterFrame, 0x29 LeaveFrame
Arithmetic: 0x2A Add, 0x2B Sub, 0x2C Mul, 0x2D Div, 0x2E Mod
Comparison: 0x31 Eq, 0x32 Ne, 0x33 Lt, 0x34 Gt, 0x35 Le, 0x36 Ge
Control:    0x07 Call, 0x08 Ret, 0x09 Jmp, 0x0A Jz, 0x0E Loop, 0x0F Halt
Closure:    0x24 CallClosure, 0x25 Closure, 0x30 ClosureCapture
Exception:  0x1A TryBegin, 0x1B CatchEnd, 0x78 Throw
IO:         0x06 Emit
Molecular:  0x40-0x44 (MolPack/Unpack/Dist/Compose/Dominant)
KnowTree:   0x50-0x52 (KtStore/Load/Nearest)
Silk:       0x58-0x5B (Fire/Decay/Walk/Implicit)
Arena:      0x60-0x65 (AllocA/B/C/ResetC/ResetB/HeapPin)
```

### Builtins (512-slot table, FNV-1a hash & 0x1FF)
```
len(0x4C) substr(0x00) char_at(0x03) __floor(0xAF) __ceil(0x6A)
__abs(0x0D) __sqrt(0xA5) __exp(0x8A) __log2(0x43) push(0x9D)
__array_get(0x57) __set_at(0x0F) __heap_used(0xC7) __sleep(0x86)
__to_string(0x66) __char_code(0x99) __bit_and(0xD4) __bit_or(0x82)
__bit_xor(0xC8) __file_read(0x11E) __file_write(0x61)
__tcp_listen(0xC4) __tcp_accept(0xCF) __tcp_send(0xAD)
__tcp_recv(0x17) __tcp_close(0x71) __mx_w(0x54) __mxr(0x100)
__heap_pin(0x35)
```

### Bytecode Format (spec §5)
```
Header "OLNG" (48 bytes):
  [magic:4="OLNG"][version:1=2][arch:1=1][flags:1][reserved:1]
  [bc_off:4][bc_size:4][const_off:4][const_size:4]
  [func_off:4][func_size:4][know_off:4][know_size:4]
  [checksum:4][reserved:4]

Opcode format: [opcode:1][operands:variable]
  Push:      [0x01][len:2 LE][data:N bytes]
  PushNum:   [0x15][f64:8 bytes]
  Load:      [0x02][name_len:1][name:N]
  Store:     [0x13][name_len:1][name:N]
  Call:      [0x07][name_len:1][name:N][argc:1]
  Jmp/Jz:    [0x09/0x0A][offset:4 LE]
  Closure:   [0x25][param_count:1][body_len:4][body:N]
  ClosureCap:[0x30][params:1][caps:1][cap_names...][body_len:4][body:N]
  EnterFrame:[0x28][num_slots:1]
  LoadReg:   [0x26][slot:1]
  StoreReg:  [0x27][slot:1]
  Emit:      [0x06]
  Halt:      [0x0F]
```

### Memory Model
```
Stack entry: [ptr:8][len:8] = 16 bytes
  len = 0xFFFFFFFFFFFFFFFF → f64 number
  len = 0xFFFFFFFFFFFFFFFA → closure
  len = 0xFFFFFFFFFFFFFFFD → array
  len = 0xFFFFFFFFFFFFFFFB → molecule (u16)
  len = N                  → string (N u16 molecules)

Strings: u16 molecules (each = 1 codepoint). NOT UTF-8 bytes.
Arrays: heap [capacity:8][count:8][entries: (ptr:8,len:8)×N]
```

---

## SS16 cần làm

### 1. Compiler emit bytecode format "OLNG"
- Header 48 bytes theo spec §5.2
- Bytecode section: compiled opcodes
- Append to VM binary (same as current builder)

### 2. Opcodes compiler cần emit
```
Minimum cho self-build:
  let x = 42;        → PushNum(42) + Store("x")
  emit x;             → Load("x") + Emit
  x + y               → Load("x") + Load("y") + Add
  fn foo(a) { ... }   → Closure(1, body_len, body)
  foo(42)              → PushNum(42) + Call("foo", 1)
  if x > 0 { ... }    → Load("x") + PushNum(0) + Gt + Jz(else_offset)
  while ... { ... }    → Loop back
  let arr = [];        → create empty array
  push(arr, x);        → Load("arr") + Load("x") + Call("push", 2)
```

### 3. Builtin dispatch
```
Compiler emits: Call [name_len:1][name:N][argc:1]
VM hashes name at runtime, jumps to builtin_jump_table[hash & 0x1FF]
Compiler does NOT need to know hash slots — VM computes at dispatch.
```

### 4. Test: compile + run simple program
```olang
let x = 1 + 2;
emit x;
// Should output: 3
```

### 5. Test: self-build
```
Compiler compiles compiler → Gen1
Gen1 compiles compiler → Gen2
Gen1 == Gen2 (byte identical)
```

---

## Vị trí files
```
VM:       vm/x86_64/vm_nox.S (source) + vm/x86_64/vm_nox (binary)
Spec:     spec/VM_SPEC_COMPLETE.md (4711 lines, §1-§53)
Builder:  stdlib/homeos/builder.ol (current, targeting old VM)
```

SS16 có thể viết compiler mới trong Olang (chạy trên VM cũ, emit bytecode cho VM mới)
hoặc viết bootstrap compiler bằng Python/bash.
