# SPEC Part 4: Silk — Learned + Implicit Connections

> Author: Nox SS15
> Date: 2026-04-01
> Status: NOT YET ACHIEVED
> Only Nox SS15 may modify this file.
> VM Reference: spec/VM_SPEC_COMPLETE.md §9 (Silk Engine)

---

## VM Spec (§9) Defines

```
silk_matrix: u16[65,536] — index = hash(mol_a, mol_b), value = edge_index
Edge (Zone A): [mol_a:2][mol_b:2][weight:2][emotion_V:1][emotion_A:1]
               [fire_count:2][last_fire:4][type:1][next:4] = 18 bytes
Hash: ((mol_a ^ mol_b) * 0x9E37 + (mol_a + mol_b)) & 0xFFFF (symmetric)
3 types: Implicit (0 bytes) + Hebbian (18 bytes/edge) + Structural (0 bytes)
Distance: scaled integer, max=70 (ΔV×2, ΔA×2, ΔT×4)
Decay: w × φ⁻¹^(hours/24), per 24h cycle
Walk: BFS with visited bitmap (8KB Zone C)
```

## Current State (Olang, not yet aligned with VM spec)

```
EXISTS (old format — needs migration to VM spec):
  - 256 hash buckets, edge = [target, w_S, w_R, w_V, w_A, w_T] = 6 values
  - Covariance fire with per-node η (Session 15 BP4)
  - Decay ×0.95 per dream + pruning + homeostatic scaling
  - implicit_strength/pattern/classify/neighbors/nearest
  - silk_walk_dim (greedy, single-path)

NEEDS MIGRATION TO VM SPEC:
  - 256 buckets → silk_matrix u16[65536]
  - 6-value edge → 18-byte edge with fire_count + last_fire
  - Per-edge decay (using last_fire) instead of global ×0.95
  - Type field per edge (dominant dimension)
  - BFS walk with visited bitmap instead of greedy
```

---

## What to Fix (no storage format change)

### 1. DECAY — power law, runs in dream()

Every dream cycle (~8 turns), decay ALL silk edges:

```
silk_decay_all():
    for bucket in __kt_silk:
        ei = 0
        while ei < len(bucket):
            for d in 0..5:
                w = bucket[ei + 1 + d]
                // Power law: w × 0.9 per dream cycle
                // φ⁻¹ per 24h ≈ 0.9 per 8 turns (at 3 turns/hour)
                new_w = floor(w * 900 / 1000)
                bucket[ei + 1 + d] = new_w
            // Prune dead edges: if max weight < 10, remove
            max_w = max(bucket[ei+1..ei+5])
            if max_w < 10: remove edge (compact array)
            else: ei += 6
```

Effect: unused edges fade. Used edges get re-fired → stay strong.
No storage change needed. Runs inside existing dream().

### 2. COVARIANCE — deviation from running mean

Problem: "the" and "happy" both get silk to everything because they're common.
Fix: only DEVIATIONS from mean create silk.

```
// Global running means per dimension (updated every fire)
let __silk_mean = [0, 0, 0, 0, 0];   // running average of fired values
let __silk_count = [0];                // total fires

silk_fire_covariance(a, b):
    for d in 0..5:
        val_a = mol_get_dim(a, d)
        val_b = mol_get_dim(b, d)
        mean = __silk_mean[d]

        // Covariance: only deviations matter
        dev_a = val_a - mean
        dev_b = val_b - mean
        covar = dev_a * dev_b

        // Positive covariance → strengthen
        // Negative covariance → weaken (but not below 0)
        dw = floor(emo * covar / 1000)
        w = w + dw
        if w < 0: w = 0
        if w > 1000: w = 1000

    // Update running mean (exponential moving average)
    for d in 0..5:
        mean = __silk_mean[d]
        val = (mol_get_dim(a, d) + mol_get_dim(b, d)) / 2
        __silk_mean[d] = floor(mean * 950 / 1000 + val * 50 / 1000)
    __silk_count[0] += 1
```

Effect: "the" + "the" → both at mean → deviation=0 → no silk.
"happy" + "sad" → V deviates strongly → strong V silk.

### 3. STDP for R,T — temporal ordering

```
// R,T: if a fires BEFORE b → strengthen a→b, weaken b→a
// Simplified: use turn count difference

silk_fire_stdp(a, b, dt_turns):
    for d in [1, 4]:  // R=1, T=4
        if dt_turns > 0:
            // a before b → LTP
            dw = floor(emo * prox * exp(-dt_turns / 3))
        else:
            // b before a → LTD
            dw = floor(-1.2 * emo * prox * exp(dt_turns / 3))

Currently no dt_turns tracked. Simplification: treat sequential
co-activation in pipeline as dt=1 (causal order).
```

### 4. BCM θ improvement

Current BCM is basic. Improvement without storage change:
use the MEAN silk weight as θ (instead of per-edge).

```
// θ = average silk weight on V dimension across all edges
theta_V = sum(all V weights) / edge_count

// BCM: dw = η × y × (y - θ) × x
// y > θ → LTP (strengthen beyond average)
// y < θ → LTD (weaken below average)
```

---

## Implementation Plan

```
Phase 1: Add decay to dream() — ~15 LOC in knowtree.ol
Phase 2: Add covariance to kt_silk_fire — ~20 LOC
Phase 3: Add STDP for R,T in fire — ~10 LOC
Phase 4: Improve BCM with mean θ — ~10 LOC
```

~55 LOC total. No storage format change. No VM changes.

---

## Tests

```
Test 1: Fire same pair 10x → weight increases
Test 2: Don't fire for 5 dream cycles → weight decreases
Test 3: "the"+"the" fires → low/no silk (covariance)
Test 4: "happy"+"sad" fires → strong V silk (deviation)
Test 5: Prune: unused edges removed after enough decay
```

---

## Research Insights (from literature review)

### Adaptive Decay (Pavlik & Anderson 2008)
Fixed decay kills important rarely-used edges. Make decay SLOW DOWN with use:
```
β_k = β₀ × fire_count^(-0.35)
// fire 1x → β=0.50 (fast decay)
// fire 10x → β=0.22 (slow decay)
// fire 100x → β=0.10 (near permanent)
```
This is the spacing effect — reviewed items retain longer.

### Homeostatic Scaling (Krotov & Hopfield 2020)
Without this, Hebbian + decay → either explosion or total silencing.
Every ~100 fires, scale ALL weights to maintain target activity:
```
scale = target_mean / actual_mean
w_all *= scale
// target_mean ≈ 200 (moderate connectivity)
```
CRITICAL. Add to dream() alongside decay.

### Per-Node Learning Rate
Hub nodes (high degree) should learn slower per edge:
```
η_node = η₀ / sqrt(degree(node))
// degree=1 → η=η₀
// degree=100 → η=η₀/10
// degree=10000 → η=η₀/100
```
Prevents common nodes from connecting to everything.

### Pruning: ALL 5 dims must be dead
Don't prune if any dimension still alive:
```
prune if: max(w_S, w_R, w_V, w_A, w_T) < 10
          AND fire_count == 0 in last 100 turns
```
An edge dead on S but alive on V = still useful.

### BCM Burn-in
First 50 fires: update θ only, freeze weights.
Otherwise θ=0 at start → pure Hebbian → explosion.
```
if __silk_count[0] < 50:
    // Update θ only
    θ = θ * 0.99 + y² * 0.01
    return  // don't update weights
```

## Updated Implementation Plan

```
Phase 1: Decay in dream() + homeostatic scaling — ~20 LOC
Phase 2: Covariance + per-node η scaling — ~25 LOC
Phase 3: Adaptive decay (β per fire_count) — ~10 LOC
Phase 4: BCM burn-in + θ improvement — ~10 LOC
Phase 5: Pruning (all 5 dims dead check) — ~10 LOC
```

~75 LOC total. No storage format change. No VM changes.

## References

```
Oja 1982: normalized Hebbian
Bi & Poo 1998: STDP
Bienenstock et al 1982: BCM
Wickelgren 1974: power law forgetting
Ebbinghaus 1885: forgetting curve + stability
Pavlik & Anderson 2008: adaptive decay (spacing effect)
Krotov & Hopfield 2020: modern Hopfield networks
Anderson & Schooler 1991: power law in memory
Sejnowski 1977: covariance learning rule
Pfister & Gerstner 2006: triplet STDP
Intrator & Cooper 1992: BCM initialization
```

## Implementation Strategy (from research)

### 1. Adaptive Decay (Pavlik & Anderson 2008)

Make decay rate depend on how often the edge has been used:
```
beta_k = beta_0 * fire_count^(-0.35)

fire 1x   → beta = 0.50 (fast decay — barely learned)
fire 10x  → beta = 0.22 (slow decay — well practiced)
fire 100x → beta = 0.10 (near permanent — deeply known)
```
This is the spacing effect: frequently accessed edges decay slower.
Implement in `dream()` cycle — replace flat 0.9 multiplier with adaptive beta per edge.

In Olang (integer math, no float):
```
// Approximate fire_count^(-0.35) with lookup table for [1..256]
// Or: beta = 500 / (fire_count * 350 / 1000 + 500)
// This gives beta ~0.50 at fire=1, ~0.22 at fire=10, ~0.10 at fire=100
```

### 2. Homeostatic Scaling (Krotov & Hopfield 2020)

Without this: Hebbian + decay leads to either weight explosion or total silence.
Both failure modes are catastrophic for learning.

```
Every ~100 fires (or every dream cycle):
  actual_mean = sum(all_weights) / edge_count
  scale = target_mean / actual_mean    // target ~ 200
  all_weights *= scale
```

In Olang integer math:
```
// scale = target * 1000 / actual  (fixed-point ×1000)
// new_w = w * scale / 1000
let target_mean = 200
let actual_sum = 0
// ... sum all weights ...
let actual_mean = actual_sum / edge_count
let scale_k = target_mean * 1000 / actual_mean
// ... apply: w = w * scale_k / 1000 for all edges ...
```

CRITICAL: must be in `dream()` alongside decay. Without homeostatic scaling,
the network will either explode (all weights → max) or go silent (all → 0).

### 3. Per-Node Learning Rate

Hub nodes (like "the", "is", "a") have high degree and would connect to everything
without rate limiting:

```
eta_node = eta_0 / sqrt(degree(node))

degree=1     → eta = eta_0     (full learning rate)
degree=100   → eta = eta_0/10  (10x slower per edge)
degree=10000 → eta = eta_0/100 (100x slower per edge)
```

In Olang (integer sqrt approximation):
```
// isqrt(n): integer square root via Newton's method
// eta = eta_0 * 1000 / isqrt(degree * 1000000)
// Or simpler: eta = eta_0 * 100 / (isqrt(degree) * 100)
```

This prevents "the" from having silk to every node in the tree.
Combined with covariance (Section 2 above), hub suppression is double-gated.

### 4. Integration with io_uring (from BP12)

Current silk save/load timeouts on large data (~244 edges OK, but 10K+ will fail).

Solution: io_uring async write for periodic silk persistence.
```
// During dream():
//   1. Serialize silk edges to buffer (synchronous, fast)
//   2. Submit io_uring SQE for write (non-blocking)
//   3. Brain continues processing
//   4. Next dream(): check CQE for completion before new write
```

Benefits:
- Non-blocking: brain continues while disk writes complete
- Batched: one syscall for many write operations
- Linux 5.1+ (available on Arch Linux)
- VM syscall: io_uring_setup=425, io_uring_enter=426

---

## Related Specs
- [VM Spec §9 Silk Engine](VM_SPEC_COMPLETE.md) — silk_matrix, 3 types
- [BP2 Encode](SPEC_BP2_ENCODE.md) — mol quality affects silk
- [BP3 KnowTree](SPEC_BP3_KNOWTREE.md) — silk connects KnowTree nodes
- [BP5 Pipeline](SPEC_BP5_PIPELINE_EN.md) — spreading activation uses silk
- [BP6 Instincts](SPEC_BP6_INSTINCTS.md) — instincts check silk weights
- [SPEC_B Structure §B3](../docs/SPEC_B_STRUCTURE.md) — 9200 silk types
