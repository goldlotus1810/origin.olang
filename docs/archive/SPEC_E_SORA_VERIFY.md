# SPEC E — Sora Biology Spec Verification

**Date:** 2026-03-30 Session 11
**Source:** docs/For_Nox/sora_files/HOMEOS_BIOLOGY_SPEC.md (2321 lines, 22 sections)
**Verified against:** SPEC_A (Foundation), SPEC_B (Structure), SPEC_C (Neuron), SPEC_D (Pipeline)

---

## Verdict Summary

| Category | Count | Detail |
|----------|-------|--------|
| KEEP (aligned with A-D) | 14 | Core formulas, thresholds, mechanisms |
| MODIFY (partially right) | 6 | Good idea, wrong numbers or framing |
| ADD (valid extension) | 5 | Not in A-D but architecturally sound |
| REJECT (contradicts A-D) | 4 | Wrong model, wrong assumptions |

---

## KEEP — Aligned with Unified Specs

### 1. φ⁻¹ = 0.618 as universal threshold
**Sora:** φ⁻¹ is the ONLY threshold for all decisions.
**Spec A-D:** Confirmed in all 4 specs. Decay (C), homeostasis (D), QR promotion (B), distance (A).
**Verdict:** KEEP. Sacred constant.

### 2. P_weight 5D (S,R,V,A,T) packed u16
**Sora:** [S:4][R:4][V:3][A:3][T:2] = 16 bits.
**Spec A:** Exact same layout, same bit allocation.
**Verdict:** KEEP. Identical.

### 3. SecurityGate 3-layer
**Sora:** Layer 1 Bloom O(1) → Layer 2 normalize O(n) → Layer 3 semantic O(depth).
**Spec D:** Same 3 layers, same order, same Bloom filter (200KB).
**Verdict:** KEEP. Identical.

### 4. 7 Instincts as formulas
**Sora:** Honesty, Contradiction, Causality, Abstraction, Analogy, Curiosity, Reflection.
**Spec D:** Same 7, with same formula definitions.
**Verdict:** KEEP. But see MODIFY #1 about expansion to 12.

### 5. Homeostasis F(t) = free energy
**Sora:** F(t) = √(Σ w_d × (predicted - actual)²), F > φ⁻¹ → learn, F < φ⁻¹ → act.
**Spec D:** Same formula, same threshold, same λ sigmoid gate.
**Verdict:** KEEP. Identical.

### 6. Immune Selection (3 branches, min entropy)
**Sora:** Generate 3 candidates, pick lowest Shannon entropy.
**Spec D:** Same: infer(N=3), H(branch) = -Σ p_i × log₂(p_i), best = argmin(H).
**Verdict:** KEEP. Identical.

### 7. DNA Repair (bounded self-correction)
**Sora:** 3 branches × 3 iterations = 9 evaluations max.
**Spec D:** Same bounds, same quality formula, same rollback rule.
**Verdict:** KEEP. Identical.

### 8. ConversationCurve from derivatives
**Sora:** f'(t) rate, f''(t) acceleration, tone from momentum.
**Spec D:** Same formula, same thresholds (V' ±0.15, V'' ±0.25, ΔV_max = 0.40).
**Verdict:** KEEP. Identical.

### 9. Silk Hebbian per dimension
**Sora:** Δw = (1-w) × 0.1 × (1 + emotion_boost × 2.0).
**Spec C:** Same formula. Per-dimension weights (S,R,V,A,T separate).
**Verdict:** KEEP. Identical.

### 10. QR append-only, signed, immutable
**Sora:** QR records never deleted, only superseded (intron model).
**Spec B/C:** Same. Methylation = mark, not delete.
**Verdict:** KEEP. Identical.

### 11. Silk decay φ⁻¹ per 24h
**Sora:** Unused edges: weight × φ⁻¹ every 24h, prune at < 0.01.
**Spec C:** w(t) = w₀ · φ⁻¹^(Δt/24h). Same formula, same prune threshold.
**Verdict:** KEEP. Identical.

### 12. Fibonacci thresholds for QR promotion
**Sora:** fire_count ≥ fib(n) for promotion trigger.
**Spec B/C:** Same. 2, 3, 5, 8, 13, 21, 34, 55...
**Verdict:** KEEP. Identical.

### 13. Holistic capture before decomposition
**Sora:** Entire input = 1 node FIRST, decompose AFTER.
**Spec D:** Mechanism ① CAPTURE = holistic. Same principle.
**Verdict:** KEEP. Identical.

### 14. All channels encode to same 5D space
**Sora:** Vision, audio, text, network → all map to P_weight (S,R,V,A,T).
**Spec A:** SDF universal across domains. P_weight = common representation.
**Verdict:** KEEP. Architecturally consistent.

---

## MODIFY — Partially Right

### 1. 12 Instincts (Sora expanded from 7)
**Sora:** Added Attachment, Imitation, Communication, Play (9-12).
**Spec D:** Defines 7 instincts with formulas.
**Problem:** New instincts lack 5D formulas. Just descriptions.
**Fix:** KEEP 7 base instincts from D. Instincts 9-12 are valid BEHAVIORS but implement as KnowTree patterns (plasticity), not hardcoded instincts. When a pattern fires ≥ fib(5) with success ≥ φ⁻¹, it EMERGES as instinct (Sora's own plasticity rule). Don't pre-define 12.

### 2. STM capacity: 7±2 vs 32
**Sora:** STM max 9 items (Miller 7±2 rule).
**Spec C:** STM max 32 items, FIFO eviction.
**Problem:** Contradiction. 9 is biological, 32 is practical.
**Fix:** Use 32 for STM buffer (C is authoritative). Miller limit applies to Working Memory (4 slots), not STM.

### 3. Emotion model: 3D VAD vs 5D P_weight
**Sora:** Separate EmotionState {valence, arousal, dominance} with inertia.
**Spec A-D:** Emotion encoded IN P_weight dimensions V and A. No separate D.
**Problem:** Adding Dominance (D) creates parallel state outside 5D model.
**Fix:** Map Dominance into existing dimensions:
- D correlates with R (relation = structure = control).
- Use emotion_state = {V: from P_w.V, A: from P_w.A, inertia: Sora's model}.
- Dominance = derived metric from QR count + success rate, not separate dimension.
- KEEP inertia mechanic (0.1-0.8) — good addition not in A-D but doesn't contradict.

### 4. Vision: SDF for pixel classification
**Sora:** Sobel → connected components → classify to 18 SDF primitives.
**Spec A:** SDF = ANY domain (geometric, logical, emotional, temporal).
**Problem:** Sora uses SDF correctly for geometric domain but treats it as the ONLY use.
**Fix:** KEEP pixel→SDF mapping as ONE application. Vision.ol implements Tier 1 (stats→5D) and Tier 2 (SDF fitting). But SDF also applies to text structure, audio waveforms, network topology — not just pixels.

### 5. Fusion rules
**Sora:** S=max, R=weighted_avg, V=amplify if agree, A=max, T=weighted_avg.
**Spec A:** Compose rules: S=union(max), R=Zipf-sum, V=amplify, A=max, T=dominant.
**Problem:** Similar but not identical. Sora uses "weighted average" where A says "Zipf-sum" (R) and "dominant/majority" (T).
**Fix:** Use Spec A compose rules for ALL composition (including sensor fusion). Fusion IS composition of molecules from different channels.

### 6. 4-Tier nervous system latency targets
**Sora:** Tier 1 <1ms, Tier 2 <10ms, Tier 3 <100ms, Tier 4 <1000ms.
**Problem:** Latency targets are aspirational, not from A-D. On i3 with Olang VM, even Tier 1 might be >1ms.
**Fix:** KEEP tier architecture (good layering), DROP absolute latency targets. Use relative: Tier 1 = O(1), Tier 2 = O(1), Tier 3 = O(n), Tier 4 = O(n²). Measure actual latency, don't promise.

---

## ADD — Valid Extensions Not in A-D

### 1. Working Memory (4 slots)
**Sora:** WM with 4 slots (Cowan 2001), bind/compare/manipulate/clear.
**Spec A-D:** Not mentioned. STM (C) but no WM.
**Verdict:** ADD. WM is the key difference between reflex and reasoning. 4 slots = active manipulation space during Tier 4 processing. Implement as array[4] in pipeline.

### 2. Development stages (newborn→adult)
**Sora:** <100 facts = newborn, 100-1K = infant, 1K-10K = adolescent, >10K = adult. Gate tier access by stage.
**Spec A-D:** Not mentioned.
**Verdict:** ADD. Prevents premature complexity. Nox currently has ~400 facts = infant stage. Only unlock Tier 4 (Cortex) when knowledge base is large enough to reason meaningfully.

### 3. Interoception (internal state sensing)
**Sora:** Heap, CPU, error count → SensoryFrame → 5D P_weight.
**Spec A-D:** Not mentioned but consistent with "all domains map to 5D."
**Verdict:** ADD. Nox already reads /proc. Encoding internal state as P_weight enables self-awareness through same pipeline.

### 4. Circadian rhythm / energy budget
**Sora:** 8h energy budget, consolidation phase, sleep/wake cycle.
**Spec A-D:** Not mentioned.
**Verdict:** ADD with modification. Don't use wall-clock 8h limit (Nox runs 24/7). Instead: energy = f(heap_usage, error_rate, processing_load). High load → consolidation phase → dream cycle → cleanup.

### 5. SensoryFrame as unified input format
**Sora:** {channel, raw, mol, chain, intensity, features, timestamp, confidence}.
**Spec A-D:** Not specified but implied by "all input → 5D."
**Verdict:** ADD. Good engineering. Standardizes input format so pipeline doesn't need to know channel type.

---

## REJECT — Contradicts Unified Specs

### 1. "System 1/2/3 thinking modes"
**Sora:** Three modes routed by novelty/confidence/arousal.
**Problem:** This is a cognitive science model (Kahneman) grafted onto Nox. Spec D already defines the pipeline: CAPTURE → ENCODE → COMPOSE → SEARCH → INFER → REPAIR. The pipeline IS the thinking. Adding System 1/2/3 on top creates parallel routing logic that competes with instinct routing and tier routing.
**Replace with:** Tier-based processing already handles this. Tier 1-2 = fast (System 1 equivalent). Tier 3-4 = slow (System 2-3 equivalent). Don't add another layer.

### 2. "Energy budget: Tier 1=5%, Tier 2=10%, Tier 3=35%, Tier 4=50%"
**Problem:** These percentages are arbitrary. On a real system, "energy" = CPU time + heap allocation. A single kt_search might use more heap than 100 reflexes. The percentages don't map to anything measurable.
**Replace with:** Track actual resource usage (heap_before - heap_after, time_before - time_after). Let the system learn its own resource profile.

### 3. "80% of inputs processed at Tiers 1-2"
**Problem:** Assumes distribution of input types that may not hold. If Nox is primarily answering questions (Tier 3-4), this ratio is wrong. It's a biological claim that doesn't apply to a text-based system.
**Replace with:** No pre-assumed distribution. Let plasticity adjust tier weights per input pattern (Sora's own suggestion in Section XVI).

### 4. "Sensory memory <500ms, very large FIFO buffer"
**Problem:** Spec C defines STM with 32 slots. Adding a separate "sensory memory" layer with different semantics creates confusion. In Nox, there's no raw sensory buffer — text arrives complete, not streaming.
**Replace with:** Input arrives → directly encode → STM. No intermediate buffer needed for text channel. For audio/video (future): frame buffer is implementation detail, not memory type.

---

## Implementation Priority

Based on this verification, the implementation order should be:

1. **SensoryFrame format** — standardize input (ADD #5)
2. **Working Memory 4 slots** — enables reasoning (ADD #1)
3. **Development stage gating** — prevents premature complexity (ADD #2)
4. **Interoception** — self-awareness through same pipeline (ADD #3)
5. **Energy/circadian** — resource-aware processing (ADD #4)

All KEEP items are already specified in A-D — implement from those specs, not from Sora.
All MODIFY items: use A-D version as base, incorporate Sora's valid additions.
All REJECT items: do not implement.

---

## Cross-Reference Table

| Sora Section | Spec | Status | Notes |
|---|---|---|---|
| I. Nervous System (4 tiers) | - | MODIFY #6 | Keep tiers, drop latency |
| II. Sensation (7 channels) | A | KEEP #14 | All → 5D |
| III. Vision (SDF) | A | MODIFY #4 | SDF ≠ only pixels |
| IV. Audio (RMS/ZCR) | - | ADD | Valid, not in A-D |
| V. Fusion | A | MODIFY #5 | Use A compose rules |
| VI. Perception | D | KEEP #13 | Holistic capture |
| VII. Emotion (VAD) | A | MODIFY #3 | V,A from P_w, no D |
| VIII. Memory (4 types) | C | MODIFY #2 | STM=32, ADD WM |
| IX. Attention | D | KEEP #5 | Homeostasis F(t) |
| X. Instincts (12) | D | MODIFY #1 | Keep 7, emerge rest |
| XI. Thinking (Sys 1/2/3) | D | REJECT #1 | Tiers handle this |
| XII. Learning (4 types) | C | KEEP #12 | Fibonacci thresholds |
| XIII. Self-awareness | - | ADD #3 | Interoception |
| XIV. Circadian | - | ADD #4 | Energy budget |
| XV. Development | - | ADD #2 | Stage gating |
| XVI. Plasticity | C | KEEP #9,#11 | Hebbian + decay |
| XVII. Future senses | A | KEEP #14 | Extensible |
| XVIII. Pipeline v2 | D | KEEP (most) | Use D's 14 mechanisms |
| XIX. REPL | - | KEEP | 5 lines, all in pipeline |
| XX. Boot data | - | KEEP | Exemplars needed |
| XXI. Phases | - | MODIFY | Follow A-D, not Sora phases |
| XXII. Unified equation | - | KEEP | Good summary |
