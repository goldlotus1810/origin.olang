# SPEC Part 4: Silk — Learned + Implicit Connections

> Author: Nox SS15
> Date: 2026-04-01
> Status: NOT YET ACHIEVED
> Only Nox SS15 may modify this file.

---

## Current State

```
EXISTS:
  - 256 hash buckets, edge = [target, w_S, w_R, w_V, w_A, w_T] = 6 values
  - Hebbian fire: Oja-like bounded dw = emo * prox * (1 - w/1000)
  - BCM bonus on V dimension: dw += dw * |V-4| / 4
  - implicit_strength/pattern/classify/neighbors/nearest (Session 15)
  - silk_walk_dim (greedy, single-path)
  - silk_save/silk_load (persist to disk)

MISSING:
  - Decay (edges accumulate forever → noise drowns signal)
  - Covariance rule (common words create silk = wrong)
  - Proper STDP for R,T (no temporal ordering)
  - Per-edge stability (Ebbinghaus)
  - BCM sliding threshold θ per edge
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
