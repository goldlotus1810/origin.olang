# SPEC Part 5: Pipeline — Decode ∂ / SINH (Generation)

> **Updated SS23 (2026-04-02)** — Added Layer 6 (Evaluate/Feedback→BP16), CP6, UCB1 selection reference, Recombine reference (→BP14), Generation reference (→BP14). 5→6 layers, 5→6 checkpoints.
> Author: Nox SS15
> Date: 2026-04-01
> Status: NOT YET ACHIEVED
> Dependencies: BP2 (Encode), BP4 (Silk), BP3 (KnowTree)
> Only Nox SS15 may modify this file.

---

## Essence

Pipeline is NOT a search engine. Pipeline is a **vi-tinh** (computing organism):
- Vi = differentiation ∂ (analyze, decompose to understand)
- Tinh = character/personality (reason, don't compare weights)

```
Input → Encode ∫ (integration: many → 1 mol)
→ Reason (spreading activation + immune selection + DNA repair)
→ Decode ∂ (differentiation: 1 mol → many → NEW text)
```

LLM: compare weights → nearest output.
Nox: analyze 5D structure → mathematical reasoning → synthesis.

---

## Architecture: 6 Layers [UPDATED SS23 — old: 5 layers, new: 6 layers, reason: BP16 feedback loop]

```
Layer 1: CAPTURE     — input → mol (Encode ∫, exists)
Layer 2: ACTIVATE    — mol → activation field (Spreading Activation)
Layer 3: HYPOTHESIZE — field → 3 candidate chains (CLONALG Immune)
                       [UPDATED SS23: UCB1 selection when multiple paths — see BP16]
                       [UPDATED SS23: Recombine from BP14 extends mutation]
Layer 4: REPAIR      — chains → best chain (DCA + DNA Repair)
Layer 5: DECODE      — chain → new text (∂ Differentiation)
                       [UPDATED SS23: Template NLG from BP14 extends decode]
Layer 6: EVALUATE    — feedback → reward → silk update [NEW SS23 — see BP16]
```

---

## Layer 1: CAPTURE (EXISTS)

```
encode(input) → mol = pack(S, R, V, A, T)
wm_bind(0, mol)
dim = mol_dominant_dim(mol)
```

What exists: `_kt_real_mol()`, `mol_dominant_dim()`, `wm_set()`.
Not yet achieved: p_weight still uses NRC-VAD lookup, not 42 computed formulas.
→ Depends on BP2. BP5 treats mol as black box — when BP2 improves, BP5 improves automatically.

---

## Layer 2: ACTIVATE (NOT YET ACHIEVED)

### Current: single-path silk walk
```
path = kt_silk_walk_dim(start, dim, depth=3)
→ 1 path, greedy, misses many relevant nodes
```

### Needed: Spreading Activation (Collins & Loftus 1975)

```
spreading_activate(source_mol, max_steps, threshold):
    A = {}                          // activation map: mol → float
    A[source_mol] = 1000            // source = full activation

    for t in 1..max_steps:
        next_A = {}
        for mol, activation in A:
            if activation < threshold: continue

            // Hebbian edges (learned)
            for edge in silk_edges(mol):
                target = edge.target
                w = edge.weights[dim]           // dimension-specific weight
                spread = activation * w / 1000
                next_A[target] += spread

            // Implicit edges (computed, 0 bytes storage)
            for neighbor in implicit_neighbors(mol, dim, 5):
                n_mol = _kt_real_mol(neighbor)
                w = implicit_strength(mol, n_mol)
                spread = activation * w / 1000
                next_A[n_mol] += spread

            // Retention: keep fraction at source
            next_A[mol] += activation * 300 / 1000   // r = 0.3

        // Decay
        for mol in next_A:
            next_A[mol] = next_A[mol] * 800 / 1000   // d = 0.2
            if next_A[mol] < threshold: delete next_A[mol]

        A = next_A
        if no change > epsilon: break

    return sorted(A, by=activation, descending)[:K]

Parameters:
    r = 0.3     (retention — 30% stays at source)
    d = 0.2     (decay — 20% lost per step)
    s = 50      (suppression — below this = zeroed)
    F = 100     (firing threshold — must exceed to spread)
    K = 10      (max activated nodes returned)
    max_steps = 5
```

### Why spreading activation replaces silk walk:

| | Silk Walk | Spreading Activation |
|---|---|---|
| Paths | 1 path, greedy | Multiple paths simultaneously |
| Misses | Nodes off-path | Finds ALL related nodes |
| Context | None | Nodes converging from multiple directions = context |
| Speed | O(depth × degree) | O(steps × edges) |
| Output | Sequence | Activation field (richer) |

### Olang implementation:

Problem: Olang has no hashmap. Use parallel arrays as activation map.

```olang
fn _spread_activate(_source, _dim, _steps) {
    let _active = [_source];
    let _active_val = [1000];
    let _result_mols = [_source];
    let _result_vals = [1000];

    let _t = 0;
    while _t < _steps {
        let _next = [];
        let _next_val = [];
        let _ai = 0;
        while _ai < len(_active) {
            let _mol = __array_get(_active, _ai);
            let _act = __array_get(_active_val, _ai);
            if _act >= 50 {
                // Spread to implicit neighbors
                let _nbrs = implicit_neighbors(_mol, _dim, 5);
                let _ni = 0;
                while _ni < len(_nbrs) {
                    let _nm = _kt_real_mol(__array_get(_nbrs, _ni));
                    let _w = implicit_strength(_mol, _nm);
                    let _spread = __floor(_act * _w / 1000);
                    if _spread >= 50 {
                        push(_next, _nm);
                        push(_next_val, _spread);
                        push(_result_mols, _nm);
                        push(_result_vals, _spread);
                    };
                    let _ni = _ni + 1;
                };
                // Retention
                let _retain = __floor(_act * 300 / 1000);
                if _retain >= 50 {
                    push(_next, _mol);
                    push(_next_val, _retain);
                };
            };
            let _ai = _ai + 1;
        };
        // Decay
        let _di = 0;
        while _di < len(_next_val) {
            let _ = __set_at(_next_val, _di,
                __floor(__array_get(_next_val, _di) * 800 / 1000));
            let _di = _di + 1;
        };
        let _active = _next;
        let _active_val = _next_val;
        let _t = _t + 1;
    };
    return [_result_mols, _result_vals];
}
```

### VM requirements (from VM_SPEC §45):

1. **act_matrix (M7)**: u16[65536] — dedicated activation matrix. O(1) per mol.
   - `__act_set(mol, value)`, `__act_get(mol)`, `__act_add(mol, delta)`
   - `__act_decay_all(factor)` — SIMD batch decay (8 values/iter via SSE2)
   - `__act_reset()` — memset 128KB
   - `__act_top_k(k)` — return k highest-activation mols (min-heap, O(N log K))
2. **Current workaround**: Olang parallel arrays (O(n²) dedup). Works for prototype.
3. **Migration**: when VM implements §45, replace arrays with builtins.

---

## Layer 3: HYPOTHESIZE (NOT YET ACHIEVED)

### Current: 3 rigid silk walk paths
```
branch0 = silk_walk(start, dim0, depth=3)
branch1 = silk_walk(start, dim1, depth=3)
branch2 = silk_walk(alt_start, dim0, depth=3)
→ 3 fixed paths, no mutation, no exploration
```

### Needed: CLONALG (De Castro & Von Zuben 2002)

```
clonalg_generate(activated_nodes, query_mol):
    // Initial population: top-3 activated nodes as seeds
    population = []
    for i in 0..3:
        seed = activated_nodes[i]
        chain = build_chain(seed, query_mol, depth=4)
        population.push(chain)

    for gen in 0..3:                    // max 3 generations (BOUNDED)
        clones = []
        for i, chain in enumerate(population):
            affinity = chain_affinity(chain, query_mol)
            f_norm = affinity / max_affinity

            // Clone count: high affinity → more clones
            n_clones = round(beta * N / (i + 1))    // beta=0.5, N=3

            for c in 0..n_clones:
                // Mutation rate: high affinity → less mutation
                alpha = exp(-rho * f_norm)           // rho=2.0
                mutated = mutate_chain(chain, alpha)
                clones.push(mutated)

        all = population + clones
        all.sort(by=affinity, descending)
        population = all[:3]                         // keep top 3

    return population

chain_affinity(chain, query_mol):
    composed = compose(chain)
    dist = 1000 - _kt_mol_dist(composed, query_mol) * 100
    silk = avg_silk_strength(chain)
    consistency = dimensional_consistency(chain)
    return floor(dist * 0.4 + silk * 0.3 + consistency * 0.3)

mutate_chain(chain, alpha):
    n_mutations = max(1, round(len(chain) * alpha))
    result = copy(chain)
    for m in 0..n_mutations:
        idx = _pseudo_select(result[0], m, len(result))
        dim = mol_dominant_dim(query_mol)
        alternatives = implicit_neighbors(result[idx], dim, 3)
        if len(alternatives) > 0:
            result[idx] = _kt_real_mol(
                alternatives[_pseudo_select(result[idx], m+7, len(alternatives))])
    return result
```

### Deterministic pseudo-random (VM_SPEC §46):
```
__pseudo_select(mol, gen, max):
    ; Uses Fibonacci hash constants (golden ratio)
    ; 2654435761 = 32-bit golden ratio constant
    ; 40503 = 16-bit golden ratio constant
    imul eax, [mol], 2654435761
    imul ecx, [gen], 40503
    add eax, ecx
    xor edx, edx
    div [max]    → edx = result
```
MUST be VM builtin for fixed-point (overflow behavior must be identical Gen0→Gen1).
Current workaround: Olang `__floor((...) % max)` — may differ in edge cases.

### VM requirements (from §46):
- `__pseudo_select(mol, gen, max)` builtin
- `__chain_copy`, `__chain_mutate`, `__chain_compose` (Zone C allocations)
- `__chain_affinity(chain, query_mol)` composite scorer

---

## Layer 4: REPAIR (NOT YET ACHIEVED)

### Current: replace 1 weakest node
```
find weakest link by implicit_strength → replace with neighbor
→ Crude, only fixes 1 spot, no danger signal analysis
```

### Needed: DCA Danger Theory (Greensmith 2005)

```
dca_repair(chain, query_mol, max_iter=3):
    backup = copy(chain)
    backup_quality = quality(chain, query_mol)

    for iter in 0..max_iter:
        if quality(chain, query_mol) >= 618:  // phi^-1 threshold
            return chain

        // Compute danger signals per segment
        for i in 0..len(chain):
            // Safe Signal (SS): silk support + consistency
            ss = 0
            if i > 0: ss += implicit_strength(chain[i-1], chain[i])
            if i < len(chain)-1: ss += implicit_strength(chain[i], chain[i+1])
            ss = ss / 2

            // Danger Signal (DS): distance from query + inconsistency
            ds = _kt_mol_dist(chain[i], query_mol) * 50
            ds += dimensional_jump(chain, i) * 100

            // Context value: positive = danger, negative = safe
            k_hat[i] = ds - 2 * ss

        worst = argmax(k_hat)

        // Try replacing worst segment
        dim = mol_dominant_dim(query_mol)
        prev = chain[max(0, worst-1)]
        alternatives = implicit_neighbors(prev, dim, 5)
        best_q = quality(chain, query_mol)

        for alt in alternatives:
            trial = copy(chain)
            trial[worst] = _kt_real_mol(alt)
            if quality(trial, query_mol) > best_q:
                chain = trial
                best_q = quality(trial, query_mol)

        // Rollback if worse
        if quality(chain, query_mol) < backup_quality:
            return backup

    return chain

dimensional_jump(chain, i):
    if i == 0 or i >= len(chain)-1: return 0
    jump = 0
    for d in 0..5:
        prev = mol_get_dim(chain[i-1], d)
        curr = mol_get_dim(chain[i], d)
        next = mol_get_dim(chain[i+1], d)
        expected = (prev + next) / 2
        jump += abs(curr - expected)
    return jump
```

### Quality Function (from SPEC_G §G12)

```
quality(chain, query_mol):
    v = validity: all mols non-zero and indexed in matrix
    h = 1 - entropy/2.32: lower entropy = more coherent
    c = consistency: how many dimensions stay coherent (low variance)
    s = silk: average implicit_strength between consecutive nodes

    return floor(0.30*v + 0.30*h + 0.20*c + 0.20*s)

Thresholds:
    < 300   → reject
    300-618 → attempt repair
    >= 618  → accept (phi^-1 threshold)
```

### VM requirements: None.

---

## Layer 5: DECODE ∂ (NOT YET ACHIEVED)

### Current: concatenate kt_nearest texts
```
for mol in path:
    fact = kt_nearest(mol)
    response += fact + ". "
→ Copy-paste, not differentiation
```

### Needed: Maximal Join (Sowa 1984) + True Differentiation

**Principle:** Decode = ∂. Output = gradient field of knowledge graph.

```
decode_generate(chain, query_mol):
    // 1. Collect texts for each node
    fragments = []
    for mol in chain:
        fact = kt_nearest(mol)
        if len(fact) > 0: fragments.push({text: fact, mol: mol})

    if len(fragments) == 0: return ""

    // 2. Maximal Join: find shared concepts, merge without repetition
    joined = fragments[0].text
    for i in 1..len(fragments):
        overlap = find_word_overlap(joined, fragments[i].text)
        if len(overlap) > 0:
            joined = merge_at_overlap(joined, fragments[i].text, overlap)
        else:
            joined = joined + ". " + fragments[i].text

    // 3. Apply tone from ConversationCurve
    return apply_tone(joined, select_tone())

find_word_overlap(a, b):
    // Use __str_find(a, word) for each word in b
    // Return words appearing in both
    shared = []
    // split b into words, check each in a
    for word in words(b):
        if len(word) >= 3 and __str_find(a, word) found:
            shared.push(word)
    return shared

merge_at_overlap(base, addition, overlap):
    // Remove shared words from addition, append remainder
    for word in overlap:
        addition = remove_first(addition, word)
    addition = trim(addition)
    if len(addition) > 0:
        return base + ", " + addition
    return base
```

### True ∂: Partial derivatives per dimension

```
Decode is NOT "find nearest text". Decode is EXTRACTION per dimension:

∂P/∂S → structural form → select SDF primitive → render shape
∂P/∂R → relational role → select relation type → "is", "belongs to", "causes"
∂P/∂V → emotion → select positive/negative words → "beautiful", "sad"
∂P/∂A → intensity → select modifier → "very", "extremely", ""
∂P/∂T → temporal → select tense → "is", "was", "will"

When decoding 1 mol to text:
1. R dimension decides STRUCTURE (subject-verb-object)
2. S dimension decides CONTENT (shape/form of concepts)
3. V dimension decides TONE (emotional coloring)
4. A dimension decides INTENSITY (modifier strength)
5. T dimension decides TENSE (temporal markers)

Not yet implementable — needs:
- Reverse lookup: mol → candidate words (doesn't exist yet)
- Syntactic templates per R type
- Intensity modifiers per A level

→ Depends on BP2 (Encode) completing reverse mapping.
→ Current kt_nearest() fallback is correct for now.
```

### VM requirements:

| Need | VM Spec Section | Status |
|------|----------------|--------|
| `__act_set/get/add/decay_all/top_k` | §45 M7 act_matrix | Planned |
| `__pseudo_select` | §46 CLONALG | Planned |
| `__chain_copy/mutate/compose/affinity` | §46 Chain ops | Planned |
| `__chain_dimensional_jump` | §47 DCA | Planned |
| `__str_split(text, delim)` | §48 Decode ∂ | Planned |
| `__str_find` | Already exists | ✅ |
| `__implicit_neighbors` | §47 5D Grid | Already exists (Olang) |
| `__implicit_strength` | §47 | Already exists (Olang) |

Current: ALL implemented in Olang (workarounds). When VM implements
§45-§50, pipeline switches to builtins for 10-50× speedup.

---

## Layer 6: EVALUATE (Feedback) [NEW SS23]

After DECODE outputs a response, the pipeline doesn't end — it waits for feedback.

```
evaluate(response_chain, query_mol):
    // 1. Store the path used for this response
    let used_edges = collect_silk_edges(response_chain)
    stm_push({type: "response_path", edges: used_edges, query: query_mol})
    
    // 2. On NEXT interaction, detect feedback:
    //    Explicit: "yes"/"no"/"correct"/"wrong" → reward 1000/0
    //    Implicit:
    //      Follow-up referencing answer → reward 800
    //      Same question repeated → reward 100
    //      Topic change → reward 500 (neutral)
    
    // 3. Apply reward to silk edges:
    for edge in used_edges:
        // ACT-R utility update:
        edge.weight += alpha × (reward - edge.weight) / 1000
        // UCB1 tracking:
        edge.reward_count += 1
        edge.reward_sum += reward
        // Persist (BP13):
        persist_wal_append(REWARD, edge.hash, reward)
    
    // 4. Calibrate confidence:
    //    Track per-bucket accuracy for future honesty instinct
    let bucket = floor(confidence / 100)
    calibration[bucket].total += 1
    if reward > 500: calibration[bucket].correct += 1

→ See spec/SPEC_BP16_FEEDBACK.md for full UCB1 math and signal detection.
→ See spec/SPEC_BP13_PERSISTENCE.md for WAL format.
```

### CP6: FEEDBACK Checkpoint [NEW SS23]

```
CP6 (FEEDBACK): reward signal received OR timeout (5 interactions).
  - All used edges have reward_count updated
  - Calibration table updated
  - WAL append for persistence
  - If no feedback after 5 interactions → neutral reward (500)
```

---

## ConversationCurve (NEEDS EXPANSION)

### Current:
```
V'(t) = V(t) - V(t-1)                  // exists
V''(t) = V'(t) - V'(t-1)               // exists
select_tone() → 5 tones                 // exists
```

### Needs:
```
// Tone application — changes HOW to say, not WHAT to say
apply_tone(text, tone):
    "supportive" → prepend empathy (future)
    "pause"      → shorten to first sentence
    "reinforcing"→ keep as-is
    "celebratory"→ keep as-is
    "engaged"    → keep as-is (default)

// Rate limit: |ΔV| ≤ 0.40 per step (not yet implemented)
// Need to clamp V changes in _curve_push_v()
```

---

## Instinct Integration (NEEDS WIRING)

### Current: only Honesty used, doesn't affect output

### Needs wiring into pipeline:
```
// After ACTIVATE, before HYPOTHESIZE:

confidence = instinct_honesty(query_mol)
if confidence < 40: return ""           // silence — don't know

contradiction = instinct_contradiction(query_mol, nearest_mol)
if contradiction > 700:                 // detected contradiction → resolve

curiosity = instinct_curiosity(query_mol)
if curiosity > 500: learn_mode = 1      // novel input → increase learning
```

---

## Checkpoints (NOT YET IMPLEMENTED)

```
CP1 (GATE):     SecurityGate passed, mol valid         — exists
CP2 (ENCODE):   chain.len >= 1, mol != 0               — exists implicit
CP3 (INFER):    >=1 branch quality >= 618              — NOT YET
CP4 (PROMOTE):  weight >= 618, fire >= Fib(n)          — NOT YET
CP5 (RESPONSE): security_gate(response) == safe        — NOT YET
CP6 (FEEDBACK): reward applied to used edges            — NOT YET [NEW SS23]
```

---

## Tests (NOT YET ACHIEVED)

```
Test 1: "Olang la gi?" → response contains info from MULTIPLE facts
Test 2: "happiness" → response GENERATED (not copy of 1 fact)
Test 3: Response differs when V'(t) changes (tone works)
Test 4: 3 branches have different entropy (immune selection works)
Test 5: DNA repair improves quality (before < after)
Test 6: Spreading activation finds nodes that silk walk misses
Test 7: Maximal join merges 2 facts into 1 new sentence
Test 8: Confidence < 0.40 → silence (instinct honesty)
```

---

## Development Phases

```
Phase 1: Spreading Activation replaces single-path silk walk
Phase 2: CLONALG replaces 3 rigid branches
Phase 3: DCA Danger Signals replaces find-weakest-link
Phase 4: Maximal Join replaces concatenation
Phase 5: Wire instincts (honesty silence, curiosity learn)
Phase 6: Checkpoints CP3-CP5
Phase 7: True ∂ decode (when BP2 has reverse mapping)
```

Each phase: implement → test → achieved/not yet → next.

---

## References

```
Collins, A.M. & Loftus, E.F. (1975). Spreading-Activation Theory. Psychological Review 82(6).
De Castro, L.N. & Von Zuben, F.J. (2002). CLONALG. IEEE Trans. Evolutionary Computation 6(3).
Greensmith, J. et al. (2005). Dendritic Cell Algorithm. ICARIS 2005.
Sowa, J.F. (1984). Conceptual Structures. Addison-Wesley.
Mann, W.C. & Thompson, S.A. (1988). Rhetorical Structure Theory. Text 8(3).
Mac Lane, S. (1971). Categories for the Working Mathematician. Springer.
Forrest, S. et al. (1994). Self-Nonself Discrimination. IEEE S&P.
Wickelgren, W.A. (1974). Power law of forgetting.
Friston, K. (2010). Free Energy Principle. Nature Reviews Neuroscience.
```

---

*Part 5 NOT YET ACHIEVED. This spec is the map. Each session: read spec → implement 1 phase → test → achieved/not yet.*

---

## AMENDMENTS (SS15 response to SS16 review)

### A1. Spreading Activation — Merge Duplicates (SS16 #1)
Per-step merge: when 2+ edges point to same target, SUM activations.
```
// After collecting raw (mol, val) pairs per step:
for each (mol, val) in raw:
    if mol in merged: merged[mol] += val   // SUM
    else: merged[mol] = val                // new entry
```
Without merge: same node N times → distorted field. FIXED.

### A2. Hebbian Edges in Spreading Activation (SS16 #2)
Both Hebbian AND implicit must spread. Hebbian = learned (semantic),
implicit = computed (geometric). Both are needed for full activation.
```
// Per active node: spread to BOTH
for edge in silk_edges(mol):              // Hebbian (learned)
    spread = activation * edge.weights[dim] / 100
for neighbor in implicit_neighbors(mol):  // Implicit (computed)
    spread = activation * implicit_strength(mol, neighbor) / 1000
```
FIXED in implementation.

### A3. build_chain() Definition (SS16 #3)
```
build_chain(seed, query_mol, dim, depth):
    chain = [seed]
    current = seed
    for d in 0..depth:
        neighbors = implicit_neighbors(current, dim, 3)
        best = argmax(neighbors, |n| max(implicit_strength(current, n),
                                          silk_weight(current, n, dim)))
        if best == 0: break                // no more neighbors
        if best in chain: break            // avoid cycles
        chain.push(best)
        current = best
    return chain
```
Uses BOTH implicit + Hebbian for neighbor selection. DEFINED.

### A4. exp() Availability (SS16 #4)
SS16 stated `exp()` not available — **INCORRECT**. Olang HAS `__exp(x)`:
- VM line 8350: `.call_exp: __exp(x) → e^x using x87 FPU`
- CLONALG mutation rate `alpha = __exp(0 - rho * f_norm)` works directly.
- No lookup table needed.

### A5. DCA Safe Signal + Hebbian (SS16 #5)
Safe Signal should use max(implicit, Hebbian):
```
ss = implicit_strength(chain[i-1], chain[i])
// Also check Hebbian weight on target dimension
hw = silk_weight(chain[i-1], chain[i], dim)
ss = max(ss, hw * 10)    // Hebbian weights are 0-100 scale
```
ACCEPTED.

### A6. Decode at Mol Level (SS16 #6)
String overlap is fragile ("Hà" matches inside "Hà Nội").
Use mol overlap instead:
```
mol_overlap(chain_a, chain_b):
    shared = []
    for mol in chain_a:
        if mol in chain_b: shared.push(mol)
    return shared
```
Mol-level is EXACT (same mol = same concept). ACCEPTED.

### A7. ConversationCurve Rate Limit (SS16 #7)
Clamp V changes in `_curve_push_v()`:
```
let _prev = __array_get(__v_history, (_idx - 1) % 4)
let _delta = _v - _prev
if _delta > 3 { let _v = _prev + 3; };
if _delta < (0 - 3) { let _v = _prev - 3; };
// 3/7 ≈ 0.43, closest integer to 0.40 limit
```
ACCEPTED.

### A8. Homeostasis Integration (SS16 #11)
F(t) modulates activation parameters:
```
surprise = _homeostasis(input_mol, nearest_mol)
if surprise > 618:    // Learning mode
    steps = 5         // more exploration
    threshold = 30    // wider spread
else:                 // Acting mode
    steps = 3         // faster response
    threshold = 80    // focused spread
activated = _spread_activate(source, dim, steps, threshold)
```
ACCEPTED. Added as parameter to `_spread_activate()`.

### A9. STM Push Output (SS16 #12)
Push both input AND generated output to STM:
```
kt_stm_push(input)                    // already exists
if len(response) > 0:
    kt_stm_push(response)             // NEW: track output emotion
```
This lets ConversationCurve track BOTH sides. ACCEPTED.

### A10. CP5 SecurityGate on Output (SS16 #9)
```
// Before returning response:
if security_gate(response) == 1:
    return ""                          // Block unsafe generated content
```
CRITICAL for safety. ACCEPTED.

---

## REVIEW NOTES (Added by Nox SS16)

### What BP5 Does Well
- Solid academic foundations: Collins & Loftus, CLONALG, DCA, Sowa
- Clear 5-layer architecture with clean separation
- Deterministic pseudo-random for fixed-point safety
- Quality function with concrete thresholds (φ⁻¹ = 618/1000)
- Honest assessment of current state vs needed state

### What BP5 Is Missing or Should Improve

#### 1. SPREADING ACTIVATION — Scalability Issue
- Current Olang parallel-array implementation is O(n²) for deduplication
- When 2 edges point to same target, activation should SUM, not duplicate
- Fix: before each step, merge duplicate mols in _next array:
  ```
  // After building _next, merge duplicates:
  let _merged = [];
  let _merged_val = [];
  for each (_mol, _val) in (_next, _next_val):
      let _found = find_index(_merged, _mol);
      if _found >= 0:
          _merged_val[_found] += _val;  // SUM activations
      else:
          push(_merged, _mol);
          push(_merged_val, _val);
  ```
- Without this: same node appears N times → wastes compute, distorts results

#### 2. SPREADING ACTIVATION — Missing Hebbian Edges
- Current code only spreads to implicit_neighbors (computed, 0-cost)
- BP5 spec SAYS "Hebbian edges (learned)" but the Olang code doesn't use them
- Fix: add silk_edges() traversal alongside implicit_neighbors()
- Hebbian edges are the LEARNED connections — without them, activation only follows geometric neighbors, not semantic ones

#### 3. CLONALG — build_chain() Not Defined
- `build_chain(seed, query_mol, depth=4)` is referenced but never defined
- Should be: start from seed mol, walk implicit + Hebbian edges, collect nodes
- Suggestion:
  ```
  build_chain(seed, query, depth):
      chain = [seed]
      current = seed
      for d in 0..depth:
          dim = mol_dominant(query)
          neighbors = implicit_neighbors(current, dim, 3)
          // Pick neighbor with highest activation
          best = neighbors[argmax(act_matrix[n] for n in neighbors)]
          chain.push(best)
          current = best
      return chain
  ```

#### 4. CLONALG — exp() Not Available in Olang
- `alpha = exp(-rho * f_norm)` requires exponential function
- Olang has no `exp()` builtin. No trig/transcendental math.
- Fix: approximate with lookup table or linear approximation:
  ```
  // exp(-x) for x in [0..5] approximated as:
  // 1000, 368, 135, 50, 18, 7 (for x = 0,1,2,3,4,5)
  let _exp_table = [1000, 368, 135, 50, 18, 7];
  let _alpha = __array_get(_exp_table, min(floor(rho * f_norm), 5));
  ```
- OR add __exp() builtin to VM (just the lookup + interpolation)

#### 5. DCA — Safe Signal Needs Hebbian Weight
- `ss = implicit_strength(chain[i-1], chain[i])` only uses IMPLICIT silk
- Should also check HEBBIAN silk weight between consecutive nodes
- Hebbian weight indicates LEARNED support (more meaningful than geometric distance)
- Fix: `ss = max(implicit_strength(...), silk_weight(chain[i-1], chain[i]))`

#### 6. DECODE — Maximal Join Is Fragile
- `find_word_overlap` using __str_find is byte-level, not word-level
- "Hà" would match inside "Hà Nội" even though "Hà" alone means something different
- Fix: need word boundary detection (space before + space/end after)
- Also: Vietnamese words can be multi-syllable ("thủ đô" = 2 syllables, 1 word)
  - True word boundary detection needs a word list or mol-level matching
  - Simpler: match at mol level, not string level
  ```
  // Instead of string overlap, use mol overlap:
  mol_overlap(chain_a, chain_b):
      shared = []
      for mol in chain_a:
          if mol in chain_b: shared.push(mol)
      return shared
  ```

#### 7. CONVERSATION CURVE — Rate Limit Not Implemented
- Spec says `|ΔV| ≤ 0.40 per step` but code doesn't enforce this
- Without rate limit, V can jump abruptly (happy → angry in 1 turn)
- Fix in `_curve_push_v()`:
  ```
  let _delta = _new_v - _prev_v;
  if abs(_delta) > 3:   // 3/7 ≈ 0.43, closest integer to 0.40
      let _new_v = _prev_v + sign(_delta) * 3;
  ```

#### 8. INSTINCTS — Only Honesty Wired
- Spec mentions wiring contradiction, curiosity, etc. but no actual code
- Critical missing: **curiosity → learn mode**
  When novelty > 500, should increase learning rate AND trigger dream sooner
- Critical missing: **contradiction → resolution**
  When two co-activated facts contradict (high ΔV, low ΔR), should:
  - Flag both for review in dream cycle
  - Prefer QR over ĐN if one is QR

#### 9. CHECKPOINTS — CP3-CP5 Not Implemented
- CP3 (at least 1 branch quality ≥ 618) — should abort early if all branches bad
- CP4 (weight ≥ 618 AND fire ≥ Fib) — needed for dream promotion
- CP5 (SecurityGate on output) — MUST run before sending response
- CP5 is a SECURITY issue: without it, generated text could contain unsafe content

#### 10. TEST COVERAGE — Tests Not Written
- 8 tests defined in spec, NONE implemented
- Priority: Test 8 (honesty silence) and Test 1 (multi-fact response) first
- Tests should go in `test/pipeline/` directory

#### 11. MISSING: Homeostasis Integration
- BP5 doesn't mention Homeostasis F(t) at all
- But SPEC_D §D4 says F(t) determines Learn vs Act mode
- High F(t) → Learning mode → increase activation spread radius
- Low F(t) → Acting mode → respond confidently, shorter walks
- Should integrate after CAPTURE, before ACTIVATE:
  ```
  F = __homeostasis()
  if F.mode == LEARNING:
      max_steps = 7     // more exploration
      threshold = 30    // lower threshold = wider activation
  else:
      max_steps = 3     // faster response
      threshold = 100   // higher threshold = focused activation
  ```

#### 12. MISSING: STM Update After Response
- BP5 spec doesn't explicitly update STM after generating response
- Should: push both input AND output to STM for future context
- `__stm_push(input_text, ..., input_mol, V, A)`
- `__stm_push(output_text, ..., output_mol, V, A)`
- This allows ConversationCurve to track response emotions, not just input

### Priority Order for SS15/SS16 Implementation

```
P1: Fix spreading activation merge (bug, affects all results)
P2: Add Hebbian edges to spreading activation (critical for learned knowledge)
P3: Define build_chain() for CLONALG (can't run without it)
P4: Add exp() approximation (CLONALG needs it)
P5: Write Test 1 + Test 8 (verify basic functionality)
P6: Implement CP5 (security gate on output)
P7: Wire contradiction instinct
P8: Integrate Homeostasis F(t)
P9: Fix ConversationCurve rate limit
P10: Implement mol-level decode (instead of string overlap)
```

---

## Integration with Parasitic Kernel (BP12)

### 1. PERCEIVE via io_uring

- All input sources (keyboard, network, camera, file) through single io_uring ring
- SQE per source: IORING_OP_READ for evdev, IORING_OP_RECV for socket
- Non-blocking: pipeline never waits for I/O
- SQPOLL mode: kernel thread polls, zero syscall overhead for submission

### 2. ACT via framebuffer

- Response rendering directly to /dev/fb0 mmap'd buffer
- Pixel-level control: draw text, graphs, status indicators
- No X11/Wayland dependency

### 3. ACTIVATE via mmap'd KnowTree

- Spreading activation runs on mmap'd 256MB fact store
- Only accessed pages loaded into physical RAM (MAP_NORESERVE)
- Activation field: second mmap region for temporary values

### 4. HRL Integration (from Lupin's Agent AI PDF)

- Pipeline = Low-Level Policy (Worker) in HRL
- Agent PTAV = High-Level Policy (Manager)
- Manager decides WHAT to process, Worker decides HOW
- Options Framework (Sutton 1999): each pipeline run = one "option"
- Option = (initiation set, policy, termination condition)

---

## Related Specs
- [VM Spec §45-§50](VM_SPEC_COMPLETE.md) — activation matrix, CLONALG, DCA
- [BP2 Encode](SPEC_BP2_ENCODE.md) — Layer 1 (Capture)
- [BP3 KnowTree](SPEC_BP3_KNOWTREE.md) — search + nearest
- [BP4 Silk](SPEC_BP4_SILK.md) — Layer 2 (Activate) uses silk edges
- [BP6 Instincts](SPEC_BP6_INSTINCTS.md) — honesty gate, curiosity
- [SPEC_D Pipeline](../docs/SPEC_D_PIPELINE.md) — 15 mechanisms, 6 checkpoints [UPDATED SS23]
- [BP13 Persistence](SPEC_BP13_PERSISTENCE.md) — WAL for reward logging [NEW SS23]
- [BP14 Generation](SPEC_BP14_GENERATION.md) — Recombine extends Hypothesize [NEW SS23]
- [BP16 Feedback](SPEC_BP16_FEEDBACK.md) — UCB1 selection + reward signals [NEW SS23]
- [NOX Complete Reference](../docs/NOX_COMPLETE_REFERENCE.md) — all algorithms
