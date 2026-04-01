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

## Specs (links)
- [VM Spec](spec/VM_SPEC_COMPLETE.md) — 53 sections, mọi thứ về VM
- [BP2 Encode](spec/SPEC_BP2_ENCODE.md) — 42 formulas, Unicode→5D
- [BP3 KnowTree](spec/SPEC_BP3_KNOWTREE.md) — fractal tree, KD-tree, QR
- [BP4 Silk](spec/SPEC_BP4_SILK.md) — covariance, decay, homeostatic
- [BP5 Pipeline](spec/SPEC_BP5_PIPELINE_EN.md) — Decode ∂, CLONALG, DCA
- [BP6 Instincts](spec/SPEC_BP6_INSTINCTS.md) — 7 pure 5D formulas
- [BP7 Memory](spec/SPEC_BP7_MEMORY.md) — observations, retrieval scoring
- [BP8 JARVIS](spec/SPEC_BP8_JARVIS.md) — 1 brain N mouths
- [BP9 Agent](spec/SPEC_BP9_AGENT.md) — PTAV loop, goals
- [BP10 Data](spec/SPEC_BP10_DATA.md) — 500K facts
- [BP11 Body](spec/SPEC_BP11_BODY.md) — camera, audio, interoception
- [Eval Tool](spec/SPEC_EVAL_TOOL.md) — benchmark, random tests (SS17)
- [Compiler Task](spec/TASK_SS16_COMPILER.md) — self-build (SS16)

## Brain Specs (gốc rễ — KHÔNG sửa)
- [SPEC_A](docs/SPEC_A_FOUNDATION.md) — SDF, P_weight, Encode ∫, Decode ∂
- [SPEC_B](docs/SPEC_B_STRUCTURE.md) — Chain, KnowTree, Silk
- [SPEC_C](docs/SPEC_C_NEURON.md) — Neuron lifecycle, physics
- [SPEC_D](docs/SPEC_D_PIPELINE.md) — 14 mechanisms, 7 instincts
- [SPEC_E](docs/SPEC_E_ORGANISM.md) — Organism, self-model
- [SPEC_F](docs/SPEC_F_AGENT.md) — Agent, autonomy

## Tài liệu
- [Kinh Thánh VN](docs/NOX_KINH_THANH_TIENG_VIET.md) — 130KB algorithms
- [Algorithm Bible](docs/NOX_ALGORITHM_BIBLE.md) — 99KB
- [Complete Reference](docs/NOX_COMPLETE_REFERENCE.md) — 116KB
- [Rust Analysis](docs/RUST_CRATE_ANALYSIS_ORIGINAL.md) — port guide

## Open Bugs
- Bug 15: compiler.ol parse error on VM (deep nesting?)
- Push realloc: arrays > initial capacity → use __array_with_cap()
- let scope: creates local in fn/while → use array [0] pattern
