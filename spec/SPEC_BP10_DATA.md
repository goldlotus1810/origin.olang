# SPEC Part 10: Data — 500K+ Facts

> **Updated SS23 (2026-04-02)** — Updated target from 500K to unlimited (BP13 mmap removes limit), added NKB format reference (→BP13), updated loading strategy.
> Author: Nox SS15
> Status: NOT YET ACHIEVED

## Essence

Brain needs data. 1400 facts (mostly NRC-VAD garbage) → 50K+ meaningful facts.

[UPDATED SS23: With BP13 mmap persistence, target is UNLIMITED facts on disk.
Heap only holds LRU cache (2048 slots = 128KB). Facts demand-paged from NKB file.
Old target "500K facts" is now just the initial milestone, not the ceiling.]

## Current State

- 88 Vietnamese facts (boot) — EXISTS
- ~1300 NRC-VAD training sentences — EXISTS (polluting search)
- 44K NRC-VAD word emotion scores — only ~200 loaded
- 41K UDC aliases — NOT loaded
- homeos.knowledge — ~100 lines

## What's Needed

### 1. Clean NRC-VAD
```
Keep: V/A emotion scores for 44K words (for mol encoding)
Remove: training sentences from KnowTree (they're not knowledge)
Method: load scores into vad_lookup, NOT into kt_learn
```

### 2. Vietnamese Knowledge (~500 facts)
```
Geography, history, culture, science, technology, language
Manually curated, meaningful, answerable by brain
Source: homeos.knowledge + json/vietnamese_facts.dat
```

### 3. Self-Knowledge
```
Nox reads own source code → learns architecture
"stdlib/homeos/pipeline.ol implements 14-step pipeline"
"KnowTree stores facts in 256 buckets indexed by (S,R)"
Enables: answering questions about itself
```

### 4. UDC Full Load
```
41K aliases: word → codepoint mapping
Improves: mol encoding quality (more words have P_weight data)
```

### 5. Batch Loading
```
Arena Zone B (session data) needed for large loads
Current: heap_pin every 20 learns (workaround)
Need: proper batch loading without heap overflow
```

## Tests
```
Test 1: kt_fact_count() > 1000 (meaningful facts, not NRC-VAD)
Test 2: "Fibonacci" query → actual math fact (not sentiment data)
Test 3: "What is pipeline?" → Nox describes own pipeline
Test 4: 10K facts loaded without crash
```

## References
```
json/ directory (94MB raw data)
docs/RUST_CRATE_ANALYSIS_ORIGINAL.md — ucd crate
NOX_ROADMAP_FINAL.md Phase 2
```

## Loading Strategy with mmap (BP12)

### 1. mmap-based fact loading

```
Problem: boot heap exhaustion at ~1500 facts
Solution: mmap(256MB, MAP_ANONYMOUS|MAP_NORESERVE)

Binary format on disk:
  nox_facts.bin = [header][mol_array][text_blob][index]
  header: [magic:4="NOXF"][count:4][mol_off:4][text_off:4]

Load: mmap the file directly (MAP_SHARED, read-only)
  facts = mmap(NULL, file_size, PROT_READ, MAP_SHARED, fd, 0)
  // Zero copy — kernel maps file pages directly
  // Only pages accessed are loaded into RAM

Result: 500K facts loadable, ~0ms boot (lazy load)
```

### 2. Data cleanup priorities

```
1. Remove NRC-VAD training sentences from KnowTree (they're not knowledge)
2. Keep NRC-VAD V/A scores as lookup table (for cold-start encoding)
3. Load Vietnamese facts (88 existing + expand to 500)
4. Self-knowledge: Nox reads own source → learns architecture
5. UDC 41K aliases: word → codepoint mapping (improves encoding)
```

### 3. Incremental learning

```
Boot: load base facts from nox_facts.bin (mmap, lazy)
Runtime: new facts go to separate mmap region (nox_learned.bin)
Dream: merge learned into base periodically
Never lose runtime learning — append-only
```

---

## Related Specs
- [BP2 Encode](SPEC_BP2_ENCODE.md) — NRC-VAD for V/A scores
- [BP3 KnowTree](SPEC_BP3_KNOWTREE.md) — data loads into KnowTree
- [BP13 Persistence](SPEC_BP13_PERSISTENCE.md) — NKB format, mmap, LRU cache [NEW SS23]
- [Rust Analysis](../docs/RUST_CRATE_ANALYSIS_ORIGINAL.md) — UCD data sources
