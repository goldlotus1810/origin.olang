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

## Research Insights

### KD-tree for 5D u16 (NOT HNSW)
5D integer = low dimensional. KD-tree is optimal:
- Leaf size: 32 (integer comparisons cheap)
- Split: cycle S-R-V-A-T per level
- Distance: L1 Manhattan (no multiply needed)
- Expected: ~17 node visits at 100K facts
- HNSW: overkill (designed for D>20, approximate)

### Menzerath-Altmann Law — fractal validation
```
y = a × x^b × e^(-cx)
b ≈ -0.4 (compression parameter)
```
Self-similar across levels: book-chapter, sentence-word, word-syllable.
Validates KnowTree fractal design: same structure every level.

### Morton Ordering for cache locality
Interleave bits of all 5 dimensions → Z-order curve.
Sort facts by Morton code → cache-friendly range queries.

## References
```
SPEC_B_STRUCTURE.md §B2, §B4
SPEC_G_COMPLETE.md §G1, §G5
VM_SPEC_COMPLETE.md §8 (KnowTree Engine)
Menzerath-Altmann law (quantitative linguistics)
Bentley 1975 (KD-tree)
```

## Implementation Strategy (from research)

### 1. KD-tree for 5D u16 (from AIMA + Bentley 1975)

5 dimensions = low dimensional. KD-tree is optimal (not HNSW).

- **Split cycle**: S → R → V → A → T per level (repeat)
- **Leaf size**: 32 (integer comparisons are cheap — no float overhead)
- **Distance**: L1 Manhattan = |dS| + |dR| + |dV| + |dA| + |dT| — no multiply needed
- **Expected performance**: ~17 node visits at 100K facts
- **Build complexity**: O(n log n)
- **Query complexity**: O(n^(1-1/d) + k) = O(n^0.8) for d=5, k nearest neighbors

Why NOT HNSW:
- HNSW is designed for D>20, approximate results
- KD-tree gives EXACT nearest neighbor in 5D
- Integer comparisons = branch-prediction friendly on x86_64

### 2. Morton Z-order for cache locality

Interleave bits of all 5 dimensions to produce a single Z-order key:
```
For P_weight u16 with [S:4][R:4][V:3][A:3][T:2] = 16 bits total:
  morton(S,R,V,A,T) = interleave bits of each dimension

Since 4+4+3+3+2 = 16 bits, the Morton code fits in a u16!
```
Sort facts by Morton code before building KD-tree.
Result: spatially nearby facts are also nearby in memory → cache-friendly range queries.
This eliminates most cache misses during KD-tree traversal.

### 3. mmap for scale (from BP12)

Current bottleneck: heap bump allocator, max ~1500 facts at boot.

Solution:
```
mmap(NULL, 256MB, PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_PRIVATE|MAP_NORESERVE, -1, 0)
```
- Physical pages only allocated on first access (demand paging)
- 256MB virtual = ~16M facts capacity, but only used pages consume RAM
- Solves boot heap blocker immediately — no arena allocator needed
- VM syscall: mmap is syscall 9 on x86_64 Linux

### 4. Binary persistence format

```
Header:    [magic:4="NOXT"][version:2][fact_count:4][mol_offset:4][text_offset:4]
Mol array: [mol:2] x fact_count
Text blob: [len:2][utf8_bytes:len] x fact_count
Index:     [mol:2][text_offset:4] x fact_count (sorted by mol for binary search)
```

Benefits over current TSV:
- Load = mmap entire file + cast pointers (zero parsing)
- Save = write arrays directly (no formatting)
- Binary search on sorted index: O(log n) lookup by mol
- Estimated: 500K facts = ~50MB file, loads in <100ms via mmap

---

## Related Specs
- [VM Spec §8 KnowTree Engine](VM_SPEC_COMPLETE.md) — kt_matrix, mol_matrix
- [BP2 Encode](SPEC_BP2_ENCODE.md) — mol encoding quality affects search
- [BP4 Silk](SPEC_BP4_SILK.md) — silk walk uses KnowTree nodes
- [BP5 Pipeline](SPEC_BP5_PIPELINE_EN.md) — pipeline searches KnowTree
- [BP10 Data](SPEC_BP10_DATA.md) — data loading into KnowTree
- [SPEC_B Structure](../docs/SPEC_B_STRUCTURE.md) — fractal tree design
