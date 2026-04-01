# SPEC Part 3: KnowTree — Semantic Fractal Tree

> Author: Nox SS15
> Status: NOT YET ACHIEVED

## Essence

KnowTree = content-addressable memory. P_weight IS the address.
Fractal: same structure at every level (char → word → sentence → book).
L0 at center, L2+ grows outward.

## Current State

- 256 buckets indexed by (S×16 + R) — flat, not fractal
- mol_matrix (__mxr): O(1) exact lookup by mol — EXISTS (Session 15)
- kt_nearest: 3-layer (exact → implicit scan → bucket fallback)
- kt_learn/kt_learn_fast/kt_learn_raw — all store to buckets + matrix
- kt_find: word-level index (256 hash buckets)
- Persistence: silk+stm save/load (kt_save disabled — timeout)

## What's Missing

### 1. Fractal Structure (SPEC_B §B2)
```
Current: flat buckets[256]
Needed: L2 → L3 → L4 → ... → Ln-1 hierarchical grouping
  L2: main groups (facts, code, emotions, people, places)
  L3: sub-groups within each
  Ln-1: leaf nodes

NOT nested arrays. Each level = 1 classification stage.
kt_classify(mol) → which L2 branch → depth search within.
```

### 2. QR Promotion (SPEC_B §B4)
```
Current: facts are all equal (no maturity distinction in search)
Needed: Mature facts (fire ≥ Fib(n), weight ≥ 0.854) → QR (permanent)
  QR = append-only, signed, never deleted
  Supersede mechanism: old QR → inactive, not removed

kt_maturity() exists but not used in search ranking.
kt_fire() exists but doesn't trigger promotion.
```

### 3. Binary Persistence
```
Current: TSV text format (slow, timeout on large data)
Needed: binary format for fast save/load
  [count:4][entries: mol:2, text_offset:4, text_len:2, fire:2, maturity:1]
  Separate text blob for strings
```

### 4. Scale Test
```
Current: ~1400 facts, works fine
Target: 500K facts, kt_nearest < 10ms
Need: VP-tree or HNSW index for large-scale search
Currently: bucket scan O(9×bucket_size) — OK for 1K, bad for 500K
```

## Architecture

```
KnowTree
├─ mol_matrix[65536]    — O(1) exact lookup (EXISTS)
├─ buckets[256]         — O(bucket) nearest search (EXISTS)
├─ word_index[256]      — O(1) word → facts (EXISTS)
├─ L2_branches[]        — semantic groups (NOT YET)
│   ├─ facts/           — verified knowledge
│   ├─ conversations/   — interaction history
│   ├─ code/            — programming patterns
│   └─ ...
├─ QR_store             — promoted permanent records (NOT YET)
└─ facts_mol[]          — parallel arrays (EXISTS)
    facts_fire[]
    facts_maturity[]
```

## Tests
```
Test 1: kt_fact_count() > 1000 (can hold large data)
Test 2: kt_nearest() finds correct fact for known query
Test 3: Mature facts (fire ≥ 8) rank higher in search
Test 4: Save + load preserves all data (round-trip)
Test 5: 10K facts, kt_nearest < 100ms
```

## References
```
SPEC_B_STRUCTURE.md §B2 (hierarchy)
SPEC_B_STRUCTURE.md §B4 (QR promotion)
SPEC_G_COMPLETE.md §G1 (data structures), §G5 (operations)
NOX_ALGORITHM_BIBLE.md §9-10 (VP-tree, HNSW)
```
