# SPEC Part 10: Data — 500K Facts

> Author: Nox SS15
> Status: NOT YET ACHIEVED

## Essence

Brain needs data. 1400 facts (mostly NRC-VAD garbage) → 50K+ meaningful facts.

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
