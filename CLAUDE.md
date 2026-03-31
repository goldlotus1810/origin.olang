# Nox — Olang Self-Hosting AI

## BẮT BUỘC ĐỌC TRƯỚC KHI LÀM GÌ

1. **ĐỌC `docs/SESSION_NEXT.md`** — biết đang ở đâu, làm gì tiếp
2. **ĐỌC `docs/SPEC_G_COMPLETE.md`** — 27 sections, MỌI thuật toán
3. Chạy: `cd ~/Origin && make self-build && make test && make fixed-point`
4. **HIỂU = tính tay được.** Không hiểu = không code.

## TRẠNG THÁI (Session 12, 2026-03-31)

Brain rebuilt: 900 lines pure math (was 4233 lines if/else chatbot).
24/27 G sections done. 933KB binary. 193/194 tests. Gen1==Gen2 ✓.
**NEXT:** Rebuild UDC P_weight table với 42 formulas thật.

## LUẬT TUYỆT ĐỐI

### A-D là não. KHÔNG thay đổi.
- `docs/SPEC_A_FOUNDATION.md` — SDF, P_weight u16, Encode ∫, Compose, Decode ∂
- `docs/SPEC_B_STRUCTURE.md` — Chain, KnowTree, Silk 9,200 types, QR
- `docs/SPEC_C_NEURON.md` — Neuron lifecycle, physics, 9 QT
- `docs/SPEC_D_PIPELINE.md` — 14 mechanisms, 7 instinct formulas, 5 checkpoints

### Hiểu SAI thường gặp (ĐÃ SỬA, KHÔNG LẶP LẠI):
- S = SDF (tĩnh). T = Spline (động). Không phải "dimensions"
- Silk = 3 vai trò: PHÂN LOẠI + ĐỊNH VỊ + LIÊN KẾT
- Trong chain = structural silk (0 bytes). Giữa nhánh = Hebbian silk
- Compose IS fusion. Emotion = V/A TRONG P_weight
- 42 formulas trích xuất từ Unicode metadata. KHÔNG phát minh encoding mới
- KHÔNG hardcode. KHÔNG if/else trên keywords. Toán thuần.

### Quy tắc code:
- Mỗi thay đổi: `make test && make fixed-point` — KHÔNG skip
- `let` không bare assignment (fixed-point fails)
- NEVER push to `[]` with index, always `[]` + push
- KHÔNG sửa test để pass. Fix code.

## Build
```bash
cd ~/Origin
make self-build && make test && make fixed-point
```

## Specs
```
docs/SPEC_G_COMPLETE.md    — ★ IMPLEMENTATION GUIDE (27 sections)
docs/SPEC_A_FOUNDATION.md  — Nền móng (nếu thắc mắc → quay về A)
docs/SPEC_B_STRUCTURE.md   — Cấu trúc
docs/SPEC_C_NEURON.md      — Neuron
docs/SPEC_D_PIPELINE.md    — Pipeline
docs/SPEC_E_ORGANISM.md    — Chi tiết A-D
docs/SPEC_F_AGENT.md       — Agent
docs/SPEC_UNIFIED.md       — Index
```

## UDC Reference (for P_weight rebuild)
```
docs/tailieu_nghiencuu/UDC_DOC/UDC_formulas.md      — 42 formula structure
docs/tailieu_nghiencuu/UDC_DOC/UDC_S*_tree.md       — S dimension SDF formulas
docs/tailieu_nghiencuu/UDC_DOC/UDC_R_RELATION_tree.md — R dimension
docs/tailieu_nghiencuu/UDC_DOC/UDC_V_VALENCE_tree.md  — V dimension physics
docs/tailieu_nghiencuu/UDC_DOC/UDC_A_AROUSAL_tree.md  — A dimension physics
docs/tailieu_nghiencuu/UDC_DOC/UDC_T_TIME_tree.md     — T dimension
```
