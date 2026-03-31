# LUPIN INSIGHT: Dual-Width VM — 64-bit logic + 16-bit KnowTree

> Thêm vào Phase 0 roadmap. Nox implement cùng lúc arena + scope fix.

---

## Ý tưởng

```
HIỆN TẠI:
  VM = 64-bit everywhere
  P_weight = u16 nhưng lưu trên stack/heap = 16 bytes (f64 format)
  1 node stack entry = 16 bytes = 8x lãng phí
  500K nodes × 16 bytes = 8MB → tràn L2 cache

SAU:
  System/logic = 64-bit (pointers, addresses, control flow, bytecode)
  KnowTree data = 16-bit native (P_weight, mol, Silk weight, bucket index)
  1 node = 2 bytes = đúng kích thước P_weight
  500K nodes × 2 bytes = 1MB → fit L2 cache
```

---

## Tại sao nhanh hơn

```
1. Cache: 32 nodes/cache line thay 4 → 8x cache efficiency
2. SIMD: 8 u16/instruction thay 2 f64 → 4x throughput
3. Memory: 1MB thay 8MB cho 500K nodes
4. Distance: integer subtract thay float subtract → nhanh hơn
5. Bandwidth: 4x ít data di chuyển giữa RAM↔CPU
```

---

## Thêm vào Phase 0: 0.5 Dual-Width KnowTree

```
Phase 0.1 ✔ THE BOMB — scope stack
Phase 0.2 ◼ Arena 3-zone heap
Phase 0.3   Push O(1)
Phase 0.4   substr fix
Phase 0.5   Dual-Width KnowTree arrays ← MỚI
```

### 0.5 Implementation

```asm
;; KnowTree arrays = u16 packed, không qua f64 stack
;; Vùng riêng trong Arena Zone A (permanent)

;; Cấu trúc:
;;   kt_mols:    [u16] × capacity     — P_weight per node
;;   kt_silk:    [u16] × capacity     — Silk weight per edge  
;;   kt_buckets: [u16] × 256 × depth  — bucket→node index
;;   kt_dims:    [u16] × 5 × capacity — S,R,V,A,T unpacked per node (optional)

;; Builtins mới (u16 native):
;;   __kt_store_u16(base, index, value)  — store u16 trực tiếp
;;   __kt_load_u16(base, index)          — load u16 trực tiếp
;;   __kt_dist_u16(mol_a, mol_b)         — distance bằng integer ops
;;   __kt_search_u16(query_mol, bucket)  — search bucket bằng u16
;;   __kt_batch_dist(query, array, len)  — SIMD batch distance

;; SSE2 batch distance (8 nodes/instruction):
;;   movdqu xmm0, [kt_mols + offset]    — load 8 mols
;;   psubw  xmm0, xmm1                  — subtract query mol (packed)
;;   pabsw  xmm0, xmm0                  — absolute value (SSSE3)
;;   — hoặc manual abs cho SSE2:
;;   pxor   xmm2, xmm2
;;   psubw  xmm2, xmm0                  — negate
;;   pmaxsw xmm0, xmm2                  — max(x, -x) = abs
;;   — accumulate distances...
```

### Interface Olang (không đổi)

```olang
// Olang code KHÔNG CẦN THAY ĐỔI
// kt_learn, kt_nearest, kt_find — cùng API
// Bên trong: u16 operations thay f64
// Nox chỉ thấy: nhanh hơn, nhiều nodes hơn

let mol = _kt_real_mol("Ha Noi");  // trả u16 như hiện tại
let nearest = kt_nearest(mol);      // bên trong dùng u16 distance
let results = kt_find("Olang", 5);  // bên trong dùng u16 search
```

---

## Tại sao làm cùng Phase 0

```
Arena allocator (0.2) chia heap thành zones.
Zone A = permanent = KnowTree.
Nếu Zone A = u16 packed → tự nhiên dual-width.

0.2 + 0.5 LÀM CÙNG LÚC:
  Arena zones → Zone A u16 (KnowTree) + Zone B/C f64 (session/turn)
  = 1 lần thiết kế, không refactor sau.
```

---

## Benchmark kỳ vọng

```
                    HIỆN TẠI (f64)     SAU (u16)
────────────────────────────────────────────────
1 node size         16 bytes            2 bytes
Cache fit           4 nodes/line        32 nodes/line
500K nodes RAM      8 MB                1 MB
Distance calc       f64 subtract        integer subtract
SIMD throughput     2/instruction       8/instruction
kt_nearest 500K    ~50ms estimate      ~6ms estimate
```

---

## Tóm tắt cho Nox

```
vm_x86_64.S thêm:
  1. KnowTree zone trong arena = u16 packed
  2. __kt_store_u16, __kt_load_u16, __kt_dist_u16 builtins
  3. __kt_batch_dist = SSE2 packed u16 distance (8 nodes/cycle)
  4. kt_nearest/kt_find bên trong gọi u16 ops

stdlib không đổi API. Chỉ nhanh hơn.
~60 LOC ASM cho builtins + ~40 LOC cho arena u16 zone.
```

---

*64-bit cho logic. 16-bit cho tri thức. Đúng kích thước từng thứ.*
*500K nodes × 2 bytes = 1MB. Fit cache. Fit binary.*
*1 GenAI = 1MB. Không còn lý thuyết.*
