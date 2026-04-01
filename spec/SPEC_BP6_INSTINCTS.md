# SPEC Part 6: Instincts — 7 Pure 5D Formulas

> Author: Nox SS15
> Status: NOT YET ACHIEVED

## Essence

7 instincts = deterministic evaluation functions on 5D space.
NOT learned. NOT if/else on keywords. Pure math from P_weight.

## Current State

- instinct_honesty: exists, wired into pipeline (confidence gate)
- instinct_contradiction: exists, NOT wired
- instinct_curiosity: exists, wired (learn mode boost)
- instinct_causality: exists, NOT wired
- instinct_abstraction: NOT implemented
- instinct_analogy: NOT implemented
- instinct_reflection: NOT implemented

## 7 Formulas (SPEC_G §G9)

### ① Honesty — confidence from evidence
```
confidence = 0.3×silk + 0.3×fire + 0.2×sources + 0.2×consistency
< 0.40 → silence | 0.40-0.70 → "I think..." | ≥ 0.90 → "Correct."
EXISTS. WIRED in pipeline.
```

### ② Contradiction — V distance + same topic
```
contradict = (d_V > 0.8) AND (d_R < 0.2)
EXISTS. NOT WIRED — should flag for dream review.
```

### ③ Causality — temporal + co-activation + R type
```
is_causal = (temporal_order) + (silk > φ⁻¹) + (R in [8..12])
Need ≥ 2/3 evidence. EXISTS. NOT WIRED.
```

### ④ Abstraction — variance in cluster
```
variance = Σ dist(member, center)² / |cluster|
< 0.3 → concrete | < 0.7 → categorical | ≥ 0.7 → abstract
NOT IMPLEMENTED. Needed for: auto-create concept nodes in dream.
```

### ⑤ Analogy — vector arithmetic in 5D
```
a:b :: c:? → d = c + (b - a)
Result = kt_nearest(d)
NOT IMPLEMENTED. Needed for: creative generation, "X is like Y".
```

### ⑥ Curiosity — novelty = distance from known
```
novelty = min_distance / √5
> 0.5 → explore | < 0.3 → familiar
EXISTS. WIRED (learn mode boost).
```

### ⑦ Reflection — self-assessment
```
quality = 0.6 × (QR_count/total) + 0.4 × (avg_silk × edges/nodes)
NOT IMPLEMENTED. Needed for: self-model, meta-learning.
```

## What to Wire into Pipeline

```
After ACTIVATE, before HYPOTHESIZE:
  ① Honesty → silence if < 0.40 (DONE)
  ② Contradiction → flag conflicting facts for dream
  ③ Causality → annotate causal chains in response
  ⑥ Curiosity → learn mode boost (DONE)

After DECODE, before output:
  ⑦ Reflection → compare predicted vs actual quality
```

## Tests
```
Test 1: Unknown query → silence (honesty < 0.40)
Test 2: "fire is cold" + "fire is hot" → contradiction detected
Test 3: "king:queen :: man:?" → "woman" (analogy)
Test 4: High novelty input → learn_mode activated
Test 5: Reflection score tracks pipeline quality over turns
```

## References
```
SPEC_D_PIPELINE.md §D2 (7 instincts)
SPEC_G_COMPLETE.md §G9 (formulas)
instinct.ol (current implementation)
```

---

## Verified Formulas (from AIMA + research)

### 1. ⑤ Analogy — Vector Arithmetic (verified from AIMA Ch.12)

```
a:b :: c:? → d = c + (b - a)

In 5D P_weight space:
d_S = c_S + (b_S - a_S), clamped to [0,15]
d_R = c_R + (b_R - a_R), clamped to [0,15]
d_V = c_V + (b_V - a_V), clamped to [0,7]
d_A = c_A + (b_A - a_A), clamped to [0,7]
d_T = c_T + (b_T - a_T), clamped to [0,3]

result_mol = pack(d_S, d_R, d_V, d_A, d_T)
answer = kt_nearest(result_mol)
```

### 2. ④ Abstraction — Cluster Variance

```
Given cluster C of mols:
center = compose_union(C)  // average of all mols
variance = Σ manhattan_dist(mol_i, center)² / |C|
max_variance = (15² + 15² + 7² + 7² + 3²) = 553

abstraction_level = variance / max_variance
< 0.3 → concrete (specific fact)
< 0.7 → categorical (group)
≥ 0.7 → abstract (concept)
```

### 3. ⑦ Reflection — Self-Assessment

```
quality = 0.6 × knowledge_density + 0.4 × connectivity

knowledge_density = QR_count / total_facts
connectivity = avg_silk_weight × edge_count / node_count

Track over time: quality(t) - quality(t-1) = growth_rate
growth_rate > 0 → learning working
growth_rate ≤ 0 → something wrong, trigger self-diagnosis
```

### 4. Instinct Wiring into Pipeline

```
After CAPTURE:
  ① Honesty < 0.40 → silence (DONE)
  ⑥ Curiosity > 0.50 → learn_mode boost (DONE)

After ACTIVATE:
  ② Contradiction detected → flag for dream review
  ③ Causality → annotate temporal chains

After DECODE:
  ⑤ Analogy → "X is like Y" enrichment
  ⑦ Reflection → compare predicted vs actual quality

In DREAM:
  ④ Abstraction → auto-create concept nodes for high-variance clusters
```

---

## Related Specs
- [BP5 Pipeline](SPEC_BP5_PIPELINE_EN.md) — instincts wired into pipeline
- [BP4 Silk](SPEC_BP4_SILK.md) — honesty uses silk weights
- [BP3 KnowTree](SPEC_BP3_KNOWTREE.md) — curiosity checks KnowTree distance
- [SPEC_D Pipeline §D2](../docs/SPEC_D_PIPELINE.md) — 7 instinct formulas
- [SPEC_G §G9](../docs/SPEC_G_COMPLETE.md) — instinct formulas detail
