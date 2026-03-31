# Nox — Olang Self-Hosting AI

## BẮT BUỘC ĐỌC TRƯỚC KHI LÀM GÌ

1. **ĐỌC `docs/SPEC_G_COMPLETE.md`** — THE implementation guide (27 sections, MỌI thuật toán)
2. Đọc `docs/SESSION_NEXT.md` — biết đang ở phase nào, làm gì tiếp
3. Chạy: `cd ~/Origin && make vm && make self-build && make test && make fixed-point`
4. **HIỂU = tính tay được.** Tính tay test cases (G23) TRƯỚC khi code.

## LUẬT TUYỆT ĐỐI — VI PHẠM = SỤP ĐỔ

### A-D là não. KHÔNG thay đổi.
- `docs/SPEC_A_FOUNDATION.md` — SDF, P_weight u16, Encode ∫, Compose, Decode ∂
- `docs/SPEC_B_STRUCTURE.md` — Chain, KnowTree, Silk 9,200 types, QR
- `docs/SPEC_C_NEURON.md` — Neuron lifecycle, physics, 9 QT
- `docs/SPEC_D_PIPELINE.md` — 14 mechanisms, 7 instinct formulas, 5 checkpoints

### Hiểu SAI thường gặp (ĐÃ SỬA, KHÔNG LẶP LẠI):
- S = SDF (hàm khoảng cách, TĨNH). T = Spline (hàm theo thời gian, ĐỘNG). Không phải "dimensions"
- Silk = 3 vai trò: PHÂN LOẠI + ĐỊNH VỊ + LIÊN KẾT. Không chỉ connection weight
- Trong chain = structural silk (0 bytes). Giữa nhánh = Hebbian silk. KHÔNG dùng silk trong chain
- P_weight + Silk thay thế ISL. 16 bits đủ. Không cần ISL 8 bytes
- Compose IS fusion. Camera+Audio+Text → compose → 1 mol. KHÔNG cần fusion riêng
- Emotion = V/A TRONG P_weight. Organism state = ConversationCurve V(t). KHÔNG tạo emotion state riêng
- 9,200 L0 nodes + implicit silk giữa MỌI pair. KHÔNG phải "400 facts, 17 edges"
- UnicodeData mang MỌI THỨ. 42 formulas trích xuất từ Unicode metadata. KHÔNG phát minh encoding mới
- QR = công thức đã proven. QT = logic/math

### Quy tắc code:
- Mỗi thay đổi: `make test && make fixed-point` — KHÔNG skip
- Fix SAI trước, thêm MỚI sau
- 1 feature per commit
- `let` không bare assignment (fixed-point fails)
- NEVER push to `[]` with index, always `[]` + push
- Reassemble VM before build nếu sửa vm_x86_64.S
- KHÔNG sửa test để pass. Fix code.
- KHÔNG thêm `--knowledge` flag
- KHÔNG fake benchmarks

## Build
```bash
cd ~/Origin
make vm && make self-build && make test
# Verify: make fixed-point (Gen1 == Gen2)
# Bootstrap (first time): make bootstrap
```

## Specs
```
docs/SPEC_G_COMPLETE.md    — ★ IMPLEMENTATION GUIDE (27 sections, đọc TRƯỚC)
docs/SPEC_A_FOUNDATION.md  — Nền móng toán học (nếu thắc mắc → quay về A)
docs/SPEC_B_STRUCTURE.md   — Cấu trúc dữ liệu
docs/SPEC_C_NEURON.md      — Neuron model
docs/SPEC_D_PIPELINE.md    — Processing pipeline
docs/SPEC_E_ORGANISM.md    — Chi tiết thực hành A-D
docs/SPEC_F_AGENT.md       — Agent (hiện tại + tương lai)
docs/SPEC_G_CODE_AUDIT.md  — Audit cũ (superseded by G_COMPLETE)
docs/SPEC_UNIFIED.md       — Index tổng
```
