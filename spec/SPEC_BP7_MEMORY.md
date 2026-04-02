# SPEC Part 7: Memory — Observations + Search + Persist

> **Updated SS23 (2026-04-02)** — Added persistence cross-reference (→BP13), updated eviction scoring with reward (→BP16), STM activation-based retrieval note (future, ACT-R comparison).
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

### STM Design Note [NEW SS23]

```
Current: 32 fixed slots, evict oldest when full.
ACT-R comparison: activation-based retrieval (not fixed slots).
  ACT-R: every memory has activation level, retrieve by threshold.
  Higher activation = more likely retrieved. No fixed slot count.

For Nox NOW: 32 slots is correct and simpler.
  Why: fixed slots = bounded memory = predictable heap.
  ACT-R activation retrieval = future evolution when persistence (BP13) enables
  unlimited on-disk storage + activation-based LRU cache.
  
When to evolve: after BP13 mmap + LRU cache is working.
  Then: STM = LRU cache (2048 slots, BP13) with activation-weighted eviction.
  Current 32-slot STM stays as "hot buffer" within the cache.
```

### Persistence Integration [NEW SS23]

```
BP13 (Persistence) provides:
  Layer 1: mmap silk weights — instant recovery on restart
  Layer 2: WAL — crash-safe learning log
  Layer 3: Dream consolidation — temporary → permanent

BP7 connects to BP13:
  - STM entries → WAL append (type=STM_PUSH, op=5)
  - Observations → append to mmap'd nox_observations.dat
  - Session summary → write to NKB during dream consolidation
  - On restart: load recent observations from mmap'd file

→ See spec/SPEC_BP13_PERSISTENCE.md for binary formats and mmap details.
```

### Eviction Scoring Update [UPDATED SS23 — old: 3-factor, new: 4-factor, reason: BP16 reward]

```
Old eviction score:
  score = access_count × 0.3 + |V| × A × 0.4 + recency × 0.3

New eviction score (with BP16 feedback):
  score = access_count × 0.25 + |V| × A × 0.35 + recency × 0.25 + avg_reward × 0.15

  avg_reward = reward_sum / reward_count (from silk edges used with this memory)
  If no reward data: avg_reward = 500 (neutral, no effect)

  High-reward memories evict slower (they led to good outcomes).
  Low-reward memories evict faster (they led to bad outcomes).

  Weights adjusted: access_count 0.3→0.25, recency 0.3→0.25, emotion stays 0.35.
  reward gets 0.15 (small but meaningful — emotion still dominates).
```

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

---

## Persistence via Parasitic Kernel (BP12)

### 1. mmap-backed persistence

```
observations_fd = open("nox_observations.dat", O_RDWR | O_CREAT)
ftruncate(observations_fd, MAX_OBS_SIZE)
obs_map = mmap(NULL, MAX_OBS_SIZE, PROT_RW, MAP_SHARED, observations_fd, 0)

// Writes go directly to file via page cache
// No explicit save needed — kernel flushes automatically
// msync() for critical data
```

### 2. io_uring for async persistence

- Use IORING_OP_WRITE for non-critical saves
- Use IORING_OP_FSYNC for critical saves (QR promotion)
- Brain never blocks on disk I/O

### 3. Retrieval scoring (Park et al. 2023, Generative Agents)

```
score = w_r × recency + w_i × importance + w_s × relevance

recency = 0.995 ^ hours_since_access  (half-life ~6 days)
importance = access_count / max_access_count
relevance = 1 - manhattan_dist(query_mol, obs_mol) / 70

w_r = w_i = w_s = 1.0 (equal weights, tunable)
```

### 4. Session summary compression

```
Before session end:
1. Collect all STM mols from this session
2. compose_union(all_mols) → session_mol
3. Top-3 most fired facts = session highlights
4. Store as observation type="summary"
5. Next session: inject summaries as context (budget=500 tokens)
```

---

## Related Specs
- [BP3 KnowTree](SPEC_BP3_KNOWTREE.md) — facts stored in KnowTree
- [BP5 Pipeline](SPEC_BP5_PIPELINE_EN.md) — STM updated after response
- [BP9 Agent](SPEC_BP9_AGENT.md) — agent uses memory for goals
- [BP13 Persistence](SPEC_BP13_PERSISTENCE.md) — mmap + WAL + NKB [NEW SS23]
- [BP16 Feedback](SPEC_BP16_FEEDBACK.md) — reward for eviction scoring [NEW SS23]
- [SPEC_MEM](../docs/For_Nox/SPEC_MEM_MEMORY.md) — memory system design
