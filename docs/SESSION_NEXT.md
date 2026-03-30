# Session Tiep Theo

## DA XONG:
```
Phase 0: Fix 5 SAI ✅
  ✅ kt_classify thay instinct if/else (threshold 60 = 3/5 majority)
  ✅ Molecular search primary, text fallback
  ✅ Emotion từ P_weight, bỏ keyword lists
  ✅ Compose fusion dùng A4 rules (S=max, R=Zipf, V=amplify, A=max, T=vote)

Phase 1: Brain Core ✅
  ✅ Silk walk multi-hop depth 3 (kt_silk_walk + kt_silk_weight in knowtree.ol)
  ✅ Chain recombination (chain_recombine in pipeline.ol)
  ✅ Decode ∂ real (kt_decode full 5D ranking, top-8 results)
  ✅ STM eviction scoring + WM 4 slots (recency+emo+knowledge)
  ✅ Homeostasis F(t) mode switching (LEARN: silk fire + "Co the:" prefix)
  ✅ ConversationCurve V'(t), V''(t) (D7 tone selection + ΔV_max clamp)
```

## ĐỌC TRƯỚC KHI LÀM GÌ:
1. **SPEC_A_FOUNDATION.md** — SDF, P_weight, Encode ∫, Compose, Decode ∂
2. **SPEC_B_STRUCTURE.md** — Chain, KnowTree (L0 center), Silk 9,200 types, QR
3. **SPEC_C_NEURON.md** — Vòng đời, vật lý, 9 QT
4. **SPEC_D_PIPELINE.md** — 14 mechanisms, 7 instinct formulas, 5 checkpoints
5. **SPEC_E_ORGANISM.md** — Capture, Silk triple-duty, Chain gen, Memory, Self-model, NAC.mb
6. **SPEC_F_AGENT.md** — Hiện tại: AAM gate + self-modify + actuators + scheduler
7. **SPEC_G_CODE_AUDIT.md** — 12 đúng, 5 SAI (đã fix), 22 thiếu (6 done), 4 phases
8. **SPEC_UNIFIED.md** — Index tổng

## HIỂU TRƯỚC KHI LÀM:
- S = SDF (hàm khoảng cách, tĩnh). T = Spline (hàm theo thời gian, động)
- Silk = 3 vai trò: phân loại + định vị + liên kết
- Trong chain: structural silk (0 bytes). Giữa nhánh: Hebbian silk
- P_weight + Silk thay thế ISL. 16 bits đủ.
- Compose IS fusion. Không cần fusion riêng
- Emotion = V/A trong P_weight. Organism state = ConversationCurve V(t)
- A-D = não. Sai 1 nhịp = sụp đổ.

## IMPLEMENT THEO THỨ TỰ (SPEC_G):
```
Phase 2: Brain Health
  □ Dream consolidation thật (cross-group resonance, not just count)
  □ Immune Selection 3 branches (real entropy comparison)
  □ DNA Repair dimension-level (fix weakest dimension only)
  □ Silk decay φ⁻¹ per 24h
  □ Pipeline checkpoints CP2-4
  □ Instinct formulas (confidence, contradiction, causality...)

Phase 3: Expand
  □ Camera/Audio/Interoception encoders
  □ Self-model
  □ NAC.mb negative knowledge + recovery

Phase 4: Agent
  □ AAM gate + scheduler + verify loop
```

## Build:
```bash
cd ~/Origin && make vm && make self-build && make test && make fixed-point
```
