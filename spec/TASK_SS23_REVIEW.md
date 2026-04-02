# TASK SS23: Rà soát toàn bộ tài liệu sau nghiên cứu

> Context: SS22 (2026-04-01/02) đã nghiên cứu toàn bộ internet — tìm được NARS, ACT-R, HRR, UCB1, mmap persistence, Eurisko, Forth multitasking, A2A protocol, và 20+ hệ thống tương tự Nox. Kết quả trong `docs/research/01-07*.md`. Đã viết 4 spec mới: BP13 (Persistence), BP14 (Generation), BP15 (Communication), BP16 (Feedback). Giờ cần rà lại specs cũ dưới ánh sáng mới.

## Nguyên tắc
- **Thiếu → bổ sung** (thêm section, reference)
- **Lạc hậu → thay** (rewrite section)
- **Sai → bỏ** (xóa hoặc đánh dấu deprecated)
- **Đúng → giữ nguyên, KHÔNG SỬA**
- Mỗi file sửa: ghi rõ "Updated SS23" + lý do

## ĐỌC TRƯỚC
1. `docs/research/04_overcome_nox_limitations.md` — 7 giải pháp cụ thể
2. `docs/research/03_ai_models_similar_to_nox.md` — so sánh với NARS, ACT-R, DGM
3. `docs/research/07_underground_similar_projects.md` — Eurisko, DANEEL, Mind.Forth
4. `spec/SPEC_BP13_PERSISTENCE.md` → `spec/SPEC_BP16_FEEDBACK.md` — 4 spec mới
5. `spec/PLAN_OLANG_UPGRADE.md` — kế hoạch nâng cấp Olang

---

## PHASE 1: Rà Specs Theory (A-D)

### 1.1 SPEC_A_FOUNDATION.md — Encode ∫ / Decode ∂
**Check:**
- [ ] Encode vẫn đúng? Research chỉ ra HRR (Holographic Reduced Representations) cho encoding giàu hơn 16-bit. Nên thêm section "Future: HRR 32×16-bit" không?
- [ ] P_weight 16-bit có đủ? So sánh với ACT-R (subsymbolic activation 0-1 float) và NARS (frequency + confidence pair).
- [ ] Distance formula: weighted Manhattan vẫn đúng? Hay cần thêm cosine similarity cho HRR?
**Action:** Thêm section "§A.7 — Encoding Evolution Path" nếu thiếu. KHÔNG sửa công thức hiện tại.

### 1.2 SPEC_B_STRUCTURE.md — Chain + KnowTree + Silk
**Check:**
- [ ] KnowTree có cần thêm persistence model? BP13 định nghĩa binary format + mmap — SPEC_B nên reference.
- [ ] Silk: hiện "1 fire rule" (φ⁻³). Research chỉ ra cần reward-modulated fire (BP16). SPEC_B có conflict không?
- [ ] QR promotion: hiện chỉ dựa fire_count + weight. Cần thêm reward criterion (BP16)?
**Action:** Thêm cross-reference tới BP13, BP16 nếu thiếu. Check silk rules không conflict.

### 1.3 SPEC_C_NEURON.md — Vòng đời neuron
**Check:**
- [ ] LTP (Long-Term Potentiation) model: research chỉ ra early LTP vs late LTP. SPEC_C có nhắc không? Nên align với BP13 (mmap = early LTP, consolidation = late LTP)?
- [ ] Physics equations: vẫn đúng? Decay overdamped oscillator, dream forced resonance, etc.
- [ ] Eurisko died vì "coherence during self-modification" — SPEC_C có address self-modification safety không?
**Action:** Thêm "§C.X — Persistence Physics (LTP Model)" nếu thiếu. Thêm warning về Eurisko lesson.

### 1.4 SPEC_D_PIPELINE.md — 14 Mechanisms + 7 Instincts
**Check:**
- [ ] **THIẾU LỚN**: Feedback loop. Research chỉ ra UCB1 + ACT-R utility. Mechanism 14 hiện là "Response" — cần thêm "Mechanism 15: Reward Update"?
- [ ] Instinct selection: hiện 7 instincts chạy tuần tự. Research (ACT-R) gợi ý: instincts nên CẠNH TRANH, instinct mạnh nhất thắng. Cần sửa?
- [ ] Immune Selection: hiện "3 branches, pick lowest entropy". Research (DANEEL) gợi ý: competing thought streams + Global Workspace Theory. Compare.
- [ ] ConversationCurve: vẫn đúng? Hay cần thêm reward signal vào tone selection?
**Action:** Thêm Mechanism 15 (Reward/Feedback). Review instinct selection model. Đây là file CẦN SỬA NHIỀU NHẤT.

---

## PHASE 2: Rà BP Implementation Specs

### 2.1 BP4 Silk — `spec/SPEC_BP4_SILK.md`
**Check:**
- [ ] Fire rule: hiện Δw = (1-w/max) × φ⁻³. BP16 nói cần: Δw = (1-w/max) × φ⁻³ × reward_factor. Conflict?
- [ ] Decay: hiện φ⁻¹ per 24h. Research (ACT-R) dùng power-law decay, không exponential. Nào đúng hơn?
- [ ] Edge format: hiện [from:4][to:4][weight:2]. BP16 cần thêm [fire_count:2][reward_sum:2][reward_count:2]. Cập nhật spec.
- [ ] Silk types: hiện 9,200 types. Vẫn đúng? Hay quá nhiều?
**Action:** Align fire rule với BP16. Update edge format. Add "reward-modulated Hebbian" section.

### 2.2 BP5 Pipeline — `spec/SPEC_BP5_PIPELINE_EN.md`
**Check:**
- [ ] 5 layers: Capture → Activate → Hypothesize → Repair → Decode. Cần thêm layer 6: "Evaluate" (feedback)?
- [ ] Hypothesize: hiện chỉ search. BP14 (Generation) thêm recombine. Pipeline spec cần update.
- [ ] 5 Checkpoints: cần thêm CP6 (post-response reward)?
- [ ] Selection: hiện "first valid candidate". BP16 nói "UCB1 select". Update.
**Action:** Add layer/checkpoint cho feedback. Update selection to UCB1.

### 2.3 BP7 Memory — `spec/SPEC_BP7_MEMORY.md`
**Check:**
- [ ] STM 32 slots: vẫn đúng? Research (ACT-R) gợi ý activation-based retrieval thay fixed slots.
- [ ] WM 4 slots: vẫn đúng?
- [ ] Persistence: hiện không nhắc. BP13 định nghĩa mmap + WAL + NKB. BP7 PHẢI reference BP13.
- [ ] Eviction: hiện "access_count + emotion + recency". BP16 thêm "reward". Update.
**Action:** Add persistence reference. Update eviction formula.

### 2.4 BP9 Agent — `spec/SPEC_BP9_AGENT.md`
**Check:**
- [ ] PTAV loop: hiện Perceive-Think-Act-Verify. Research thêm: Act → Feedback → Update. Cần mở rộng?
- [ ] Communication: hiện không nhắc. BP15 định nghĩa A2A + mDNS. BP9 nên reference.
- [ ] Self-modify cycle: Eurisko died vì coherence. BP9 có safety mechanism không?
**Action:** Extend PTAV → PTAVF (Feedback). Add communication reference. Add Eurisko warning.

### 2.5 BP10 Data — `spec/SPEC_BP10_DATA.md`
**Check:**
- [ ] 500K+ facts target: vẫn đúng? BP13 mmap + LRU cho phép unlimited. Update target?
- [ ] Binary format: BP13 định nghĩa NKB format. BP10 cần align.
**Action:** Update data loading strategy to reference BP13.

### 2.6 BP12 Parasite — `spec/SPEC_BP12_PARASITE.md`
**Check:**
- [ ] 7 organs: heartbeat, eyes, hands, voice, memory, evolution, inject. Vẫn đúng?
- [ ] Research chỉ ra Forth cooperative multitasking cho concurrency. BP12 có nhắc scheduling model không?
- [ ] io_uring: vẫn đúng approach?
**Action:** Add "Forth-style cooperative scheduling" to organ orchestration section.

---

## PHASE 3: Rà Documents khác

### 3.1 NOX_MASTER_SPEC.md
- [ ] Đã cập nhật SS22. Verify nhiệm vụ 6.5-6.9 đúng thứ tự.
- [ ] Thứ tự ưu tiên: Olang upgrade → Persistence → Generation → Feedback → Communication. Vẫn đúng?

### 3.2 NOX_ROADMAP_FINAL.md
- [ ] Có lạc hậu không? So với Master Spec + 4 BP mới.
- [ ] Phase 3-6 có cần rewrite?
**Action:** Nếu lạc hậu → viết ROADMAP_v2 hoặc archive cái cũ.

### 3.3 CLAUDE.md
- [ ] Cập nhật BP mới (13-16) vào specs section
- [ ] Cập nhật builtins count nếu thêm mới
- [ ] Thêm research references

### 3.4 docs/SPEC_G_COMPLETE.md
- [ ] Đây là "THE implementation guide" — 27 sections. Có cần update với BP13-16?
**Action:** Review, thêm sections nếu cần.

---

## OUTPUT EXPECTED

Mỗi file được rà:
1. Ghi "Updated SS23 — [reason]" ở đầu file
2. Sections mới có tag `[NEW SS23]`
3. Sections sửa có tag `[UPDATED SS23 — old: X, new: Y, reason: Z]`
4. Sections deprecated có tag `[DEPRECATED SS23 — reason]`

Cuối cùng: cập nhật `session_log.md` với danh sách files đã sửa.

---

## THỨ TỰ LÀM

1. Phase 1: A → D (theory, quan trọng nhất vì ảnh hưởng mọi thứ)
2. Phase 2: BP4 → BP5 → BP7 → BP9 (implementation, ảnh hưởng code)
3. Phase 3: Master Spec → Roadmap → CLAUDE.md (docs)

Mỗi phase có thể là 1 session riêng nếu context nặng.
