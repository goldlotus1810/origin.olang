# SPEC Part 7: Memory — Observations + Search + Persist

> Author: Nox SS15
> Status: NOT YET ACHIEVED

## Essence

Brain remembers across sessions. Not RAM. Files on disk.
3 tiers: compact summary → timeline → full detail.

## Current State

- STM: 32 slots with eviction scoring (EXISTS)
- WM: 4 slots (EXISTS)
- Persist: silk+stm save/load (EXISTS, kt_save disabled)
- JARVIS: brain state via /tmp/nox_status (EXISTS)
- Observations: NOT implemented (pipeline doesn't store decisions)
- Session summary: NOT implemented
- Progressive disclosure: NOT implemented

## What's Needed (SPEC_MEM §M1-M5)

### 1. Observation System
```
observe(text, type, mol):
    record = {text, type, mol, timestamp, session_id}
    append to nox_observations.dat
    index by mol in observation_matrix

Types: "input", "output", "decision", "review", "error", "learn"
```

### 2. Search 3 Tiers
```
Tier 1: Compact — return mol + type + timestamp (for context injection)
Tier 2: Timeline — return N observations around a timestamp
Tier 3: Full — return complete text of specific observation
```

### 3. Session Summary
```
Before session end: compress conversation into 1-3 key observations.
Summary = compose(all STM mols) → decode → compact text.
Store as type="summary" observation.
```

### 4. Progressive Disclosure
```
When injecting context into new session:
  Budget = 500 tokens
  Priority: recent summaries > high-fire facts > recent observations
  Truncate to fit budget.
```

## Tests
```
Test 1: observe("fixed pipeline", "decision") → persisted to file
Test 2: search("pipeline") → finds observation from Test 1
Test 3: New session loads observations from previous
Test 4: Summary compresses 10 turns into 1-2 lines
```

## Research Insights

### Retrieval Scoring (Park et al. 2023)
```
score = recency + relevance + importance  (equal weights)
recency   = 0.995 ^ hours_since_access  (half-life ~6 days)
relevance = 1 - manhattan_dist(mol, query_mol) / 70
importance = access_count / max_access_count
```

### A-MEM Zettelkasten (2025)
Each observation = note with context + keywords + mol-computed links.
New notes auto-link to old. Old notes evolve when new links form.

## References
```
Park et al. (2023): Generative Agents
A-MEM (2025): Zettelkasten agent memory
docs/For_Nox/SPEC_MEM_MEMORY.md
SPEC_G_COMPLETE.md §G7, §G19, §G26
```
