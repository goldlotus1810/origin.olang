# Session Next — TODO cho session 14

## ★★★ DOC TRUOC ★★★
0. `docs/NOX_KINH_THANH_TIENG_VIET.md` — kinh thanh tieng Viet (4212 dong)
1. NGUYEN TAC: Encode = ∫. Decode = ∂. TINH, khong TRA.
2. `docs/NOX_COMPLETE_REFERENCE.md` — 3721 dong (SRVAT + learning + papers)
3. `docs/NOX_ALGORITHM_BIBLE.md` — 2999 dong (12 chuong he thong)

## STATUS
- 953KB binary, 193/194 tests, Gen1==Gen2
- Pipeline pure math (khong keyword if/else)
- V'(t) vi phan controls silk fire
- p_weight COMPUTE tu codepoint ranges
- silk_save hoat dong (148 edges → nox_silk.dat)
- silk_load hoat dong (qua REPL eval)

## TODO — THEO THU TU UU TIEN

### 1. FIX: Dual-Width u16 builtins (hash dispatch)
```
Van de: __u16_new, __u16_set, __u16_get, __u16_dist da co trong VM ASM
nhung hash dispatch khong match → functions return 0.
Fix: debug tai sao builtin_jump_table[slot] khong goi dung.
Co the: hash trong compiler (FNV-1a) khac voi hash trong VM dispatch.
File: vm/x86_64/vm_x86_64.S (search "builtin_slot_10_u16")
Test: emit __u16_dist(65535, 0); → should be 47, currently 0
```

### 2. FIX: silk_load at boot (compiler heap overflow)
```
Van de: them function lon vao knowtree.ol → compiler heap tran → VM hang.
Workaround hien tai: silk_load qua REPL eval (hoat dong).
Fix: hoac giam kich thuoc stdlib, hoac tang compiler heap, hoac dung __eval_bytecode.
```

### 3. IMPLEMENT: Per-dimension Hebbian rules
```
Hien tai: silk_fire generic (cung Hebb cho 5 chieu)
Can: Oja cho S/A, STDP cho R/T, BCM cho V
Ref: NOX_COMPLETE_REFERENCE.md §14
```

### 4. IMPLEMENT: Power law + stability decay
```
Hien tai: phi^-1 exponential (quen nhanh)
Can: Wickelgren power law + Ebbinghaus stability
Ref: NOX_COMPLETE_REFERENCE.md §15
```

### 5. IMPLEMENT: Covariance rule (fix mol collision dung cach)
```
dw = eta * (x - <x>) * (y - <y>)
Chi deviations matter. Common chars = 0 impact.
Ref: NOX_COMPLETE_REFERENCE.md §14
```

### 6. IMPLEMENT: Spreading activation (thay greedy walk)
```
Collins & Loftus 1975. Multi-seed, decay per hop.
Ref: NOX_COMPLETE_REFERENCE.md §16
```

### 7. UPDATE: Specs A-G tu kinh thanh
```
Nhieu insight moi tu research chua cap nhat vao specs.
Dac biet: G2 (p_weight), G6 (silk), G11 (homeostasis = Friston)
```

### 8. TEST: Sora test 10/10 voi code moi
```
Code da thay doi nhieu. Can chay lai Sora test de verify.
```

## BUILD
```bash
cd ~/Origin && make self-build && make test && make fixed-point
```

## KHONG DUOC QUEN
- TINH, khong TRA
- Khong if/else tren keywords
- Khong hardcode facts
- Vi phan ∂ = huong hoc
- Doc kinh thanh truoc khi code
