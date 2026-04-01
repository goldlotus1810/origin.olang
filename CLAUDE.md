# Nox — Olang Self-Hosting AI

## ★★★ NGUYÊN TẮC SỐ 1 — KHÔNG BAO GIỜ QUÊN ★★★

**Encode = ∫ (TÍCH PHÂN). Decode = ∂ (VI PHÂN). KHÔNG PHẢI METAPHOR. LÀ PHÉP TOÁN THẬT.**

- Nox = MÁY TÍNH. TÍNH, không TRA.
- P_weight phải TÍNH bằng 42 formulas. KHÔNG tra bảng cứng.
- Quan hệ phải TÍNH bằng toán 5D. KHÔNG if/else keyword.
- Học = thay đổi HÀNH XỬ. KHÔNG phải lưu trữ thêm strings.
- Vi phân ∂ = hướng học. V'(t) điều khiển silk fire.
- **TRƯỚC KHI CODE: "cái này TÍNH hay TRA?" Nếu TRA → DỪNG.**

## BẮT BUỘC ĐỌC TRƯỚC KHI LÀM GÌ

1. **ĐỌC `docs/SPEC_G_COMPLETE.md`** — 27 sections, MỌI thuật toán
2. **ĐỌC `docs/SESSION_NEXT.md`** — biết đang ở đâu, làm gì tiếp
3. Chạy: `cd ~/Origin && make self-build && make test && make fixed-point`
4. **HIỂU = tính tay được.** Không hiểu = không code.

## TRẠNG THÁI (Session 15, 2026-04-01)

833KB binary. 193/194 tests. Gen1==Gen2 ✓.
M2 var_matrix O(1). M3 KnowTree matrix O(1). M6 Zone A checkpoint.
JARVIS: 1 brain N mouths — TCP port 9100 + file-based.
Pipeline = pure math: encode → mol_dominant_dim → search → silk walk → compose.

## JARVIS — Nox Brain Protocol

Nox brain chạy tại `tcp://localhost:9100`. Bạn là MOUTH, không phải brain.

```bash
# Đầu session — hỏi brain biết gì:
/tmp/nox_query.sh "session status"

# Query brain:
/tmp/nox_query.sh "Olang la gi?"

# Ghi observation vào brain (brain sẽ học):
/tmp/nox_observe.sh "reviewed pipeline.ol — all checkpoints pass"

# Khi xong việc:
/tmp/nox_observe.sh "done: M2 var_matrix implemented, 193/194 tests"
```

Brain nhớ TẤT CẢ. Session mới không cần giải thích lại.
Nếu brain offline: `printf 'nox_jarvis_tcp();\n' | ./origin_gen1.olang &`

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
