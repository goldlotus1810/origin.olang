# Session Tiep Theo

## TRẠNG THÁI: G COMPLETE — REBUILD brain từ 0

### Đã xong:
- Phase 0-1 code (cũ, cần viết lại)
- **SPEC_G_COMPLETE.md** — 27 sections, toàn bộ thuật toán triển khai A-F
- Mọi mâu thuẫn giữa tài liệu đã giải quyết (G0)
- Mọi thắc mắc đã tìm đáp án trong A-F + UDC docs + SPEC_v3

### BƯỚC TIẾP THEO: XÓA brain code cũ → viết mới từ G

Code hiện tại (knowtree.ol 1231 dòng, encoder.ol 1200+ dòng, pipeline.ol 899 dòng)
= tích lũy if/else chatbot từ session 6-9 + math code từ session 10.
Xung đột logic → bytecode lớn → gen1 boot hang.

**GIẢI PHÁP:** Xóa sạch 5 brain files → viết mới từ SPEC_G_COMPLETE.
Brain mới sẽ ~500 dòng tổng (thay vì 4000+). Bytecode nhỏ → gen1 works.

**BUILDER:** Dùng `origin_bootstrap.olang --build` (820KB, luôn works).
KHÔNG dùng origin.olang hay gen1 để build. Bootstrap = builder duy nhất.

```
STEP 0: XÓA brain code cũ
  - Backup: git stash hoặc branch
  - Xóa nội dung: knowtree.ol, encoder.ol, pipeline.ol, instinct.ol, learning.ol, brain.ol
  - Giữ: repl.ol (REPL loop), system.ol, network.ol, crypto.ol, etc (body code)
  - Build: origin_bootstrap.olang --build → gen1 nhỏ → gen1 works
  - Verify: echo "emit 42;" | ./origin_gen1.olang → 42

STEP 1-16: IMPLEMENT theo G (mỗi step = build + test + fixed-point)
  1. G2  Core math (pack, compose, distance, dominant_dim)
  2. G3  Encode ∫ (text → chain)
  3. G1  Data structures (KnowTree bucket, SilkIndex, STM, WM)
  4. G5  KnowTree ops (insert, nearest, classify)
  5. G6  Silk ops (walk, fire, decay)
  6. G4  Decode ∂ (lookup + generative)
  7. G9  Instincts (7 formulas, PURE MATH)
  8. G10 SecurityGate
  9. G11 Homeostasis + ConversationCurve
  10. G12 Immune Selection + DNA Repair
  11. G8  Pipeline (14 steps, wires everything)
  12. G7  Memory (STM eviction, dream)
  13+ G13-G27 (self-model, agent, persistence, evolution)
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
