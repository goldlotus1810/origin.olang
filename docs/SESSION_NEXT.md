# Session 15 — M2 var_matrix (PRIORITY #1)

## ★ SPEC: docs/For_Nox/SPEC_VM_MATRIX.md ★
## ★ Lupin + Sora: "moi lan gap gioi han lai ton thoi gian. Fix GOC." ★

## M2 PLAN: var_matrix + gen counter

### Buoc 1: Them var_matrix BSS (song song voi var_table)
```asm
;; BSS:
var_matrix: .space 16384 * 16    ;; 256KB: [gen:8][value_ptr:8] × 16384 slots
var_gen:    .space 8              ;; current generation counter
```

### Buoc 2: Implement var_matrix_store
```asm
;; slot = hash & 0x3FFF (16384 slots)
;; var_matrix[slot] = [gen, ptr, len]
;; O(1). Overwrite. No accumulate. No leak.
```

### Buoc 3: Implement var_matrix_load  
```asm
;; slot = hash & 0x3FFF
;; if var_matrix[slot].gen <= var_gen → valid, return value
;; else → undefined
;; O(1). No scan.
```

### Buoc 4: Scope enter/leave = gen++/gen--
```asm
;; scope_enter: incq var_gen → O(1)
;; scope_leave: decq var_gen → O(1)
;; Inner scope vars invisible after leave (gen > current)
;; NO cleanup needed. Lazy. O(1).
```

### Buoc 5: Collision handling
```
16384 slots. ~1000 active vars max.
Birthday: P(collision) ≈ 1000²/(2*16384) = 3%
Store full hash for exact match. Linear probe on collision.
[slot] = [stored_hash:8][gen:2][ptr:8][len:8] = 26 bytes
```

### Buoc 6: Replace var_table calls → var_matrix calls
### Buoc 7: Remove var_table heap allocation (free 393KB heap!)
### Buoc 8: Test: 193/194 tests, Gen1==Gen2, 1000 nested fn calls

## CURRENT STATUS (end session 14)
- 907KB binary, 193/194 tests, Gen1==Gen2
- 4GB heap, 4 u16 builtins, 2 matrix builtins (__mx_w/__mxr)
- Capacity-tracked push (no relocation for __array_with_cap)
- MEM: silk+stm persist, auto save/load
- Brain: Formula Engine, LCA, Implicit Silk, 7 Instincts, Maturity
- Rust: 7 features ported, ~120 remaining

## BUILD
```bash
cd ~/Origin && make vm && make self-build && make test && make fixed-point
```
