# Nox — VM v2

## ĐẦU TIÊN
```bash
make vm && make test    # verify 40/40 pass trước khi làm gì
git log --oneline -10   # biết session trước làm gì
```
Đọc `spec/` — mỗi bộ phận có spec riêng. Hiểu trước, code sau.

## Build
```bash
make vm                 # as + ld → vm/x86_64/vm_nox (46KB)
make test               # compile + run test_full.ol (40/40)
make benchmark          # compile + run benchmark.ol (35/35)
python3 tools/compile_nox.py SOURCE.ol OUTPUT.olang && ./OUTPUT.olang
```

## Status
- VM: vm/x86_64/vm_nox.S (5100 LOC, 46KB)
- Compiler: tools/compile_nox.py (Python bootstrap)
- Stdlib: stdlib/ (core, knowtree, silk, pipeline, compiler)
- Tests: 40/40 + 35/35 benchmark
- Self-hosting compiler: stdlib/compiler.ol (WIP — bug 15: parse error)

## KHÔNG BAO GIỜ
- Hardcode data, if/else trên keywords → dùng toán 5D
- Nói "done"/"hoàn thành" → nói "đạt chưa"/"chưa đạt"
- Test tự sinh đáp án → test phải random/external
- Code trước khi đọc spec → đọc spec trước
- `let x = x + 1` trong while/fn → dùng `let x = [0]; __set_at(x, 0, ...)`
- `let arr = []` rồi push >8 → dùng `__array_with_cap(N)`

## Nguyên tắc
- Encode = ∫ (tích phân). Decode = ∂ (vi phân). TÍNH, không TRA.
- P_weight = u16 = [S:4][R:4][V:3][A:3][T:2] = 65536 molecules
- Silk = hệ quả toán học 5D, 0 bytes storage (implicit)
- Học = thay đổi weights. Không phải lưu thêm strings.

## Specs
```
spec/VM_SPEC_COMPLETE.md    — VM (53 sections, by SS16)
spec/SPEC_BP2_ENCODE.md     — 42 formulas
spec/SPEC_BP3_KNOWTREE.md   — fractal tree, KD-tree
spec/SPEC_BP4_SILK.md       — covariance, decay, homeostatic
spec/SPEC_BP5_PIPELINE_EN.md — Decode ∂, spreading activation, CLONALG
spec/SPEC_BP6_INSTINCTS.md  — 7 pure 5D formulas
spec/SPEC_BP7_MEMORY.md     — observations, Park et al. scoring
spec/SPEC_BP8_JARVIS.md     — 1 brain N mouths
spec/SPEC_BP9_AGENT.md      — PTAV loop
spec/SPEC_BP10_DATA.md      — 500K facts
spec/SPEC_BP11_BODY.md      — camera, audio, interoception
spec/SPEC_EVAL_TOOL.md      — evaluation tool (SS17 task)
spec/TASK_SS16_COMPILER.md  — self-build compiler task
```

## Open Bugs
- Bug 15: compiler.ol parse error on VM (deep nesting?)
- Push realloc: arrays > initial capacity → use __array_with_cap()
- let scope: creates local in fn/while → use array [0] pattern
