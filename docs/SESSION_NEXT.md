# Session Tiep Theo

## TRẠNG THÁI: G COMPLETE — Sẵn sàng code

### Đã xong:
- Phase 0-1 code (cũ, cần viết lại)
- **SPEC_G_COMPLETE.md** — 27 sections, toàn bộ thuật toán triển khai A-F
- Mọi mâu thuẫn giữa tài liệu đã giải quyết (G0)
- Mọi thắc mắc đã tìm đáp án trong A-F + UDC docs + SPEC_v3

### BƯỚC TIẾP THEO: Viết lại từ đầu

Code hiện tại = tích lũy lỗi qua nhiều session. Không sửa. Viết lại.

```
THỨ TỰ IMPLEMENT (theo G):
  1. G2  Core math (pack, compose, distance, dominant_dim)
  2. G3  Encode ∫ (text → chain)
  3. G1  Data structures (KnowTree tree, SilkIndex, STM, WM)
  4. G5  KnowTree ops (insert, nearest, classify)
  5. G6  Silk ops (walk, fire, decay)
  6. G4  Decode ∂ (lookup + generative)
  7. G9  Instincts (7 formulas)
  8. G10 SecurityGate (Bloom filter)
  9. G11 Homeostasis + ConversationCurve
  10. G12 Immune Selection + DNA Repair
  11. G8  Pipeline (14 steps, 5 checkpoints) — wires everything together
  12. G7  Memory (STM eviction, dream)
  13. G13-G14 Self-model + NAC
  14. G17 Agent cycle
  15. G18-G19 Bootstrap + Persistence
  16. G22-G27 Meta (goals, metrics, failure recovery, persistence, evolution)
```

### QUY TẮC:
- Mỗi step: viết code → `make test && make fixed-point`
- G23: HIỂU = tính tay được. Tính tay test cases TRƯỚC khi code
- Không skip step. Không check done khi chưa test
- Mỗi thuật toán = tham chiếu G section. Không tự sáng tạo

### ĐỌC TRƯỚC KHI LÀM GÌ:
1. **SPEC_G_COMPLETE.md** — THE implementation guide (27 sections)
2. **SPEC_A_FOUNDATION.md** — nếu thắc mắc → quay về A
3. **CLAUDE.md** — build rules

### Build:
```bash
cd ~/Origin && make vm && make self-build && make test && make fixed-point
```
