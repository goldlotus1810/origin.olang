# SPEC Part 5: Pipeline — Decode ∂ / SINH (Generation)

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

## Architecture: 5 Layers

```
Layer 1: CAPTURE     — input → mol (Encode ∫, exists)
Layer 2: ACTIVATE    — mol → activation field (Spreading Activation)
Layer 3: HYPOTHESIZE — field → 3 candidate chains (CLONALG Immune)
Layer 4: REPAIR      — chains → best chain (DCA + DNA Repair)
Layer 5: DECODE      — chain → new text (∂ Differentiation)
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

### VM requirements:

1. **None required for prototype** — Olang arrays sufficient.
2. **Optimization later**: `__mx_w2`/`__mxr2` — second u16 matrix for activation values (avoids conflict with fact index matrix).

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

### Deterministic pseudo-random (Nox has no random):
```
_pseudo_select(mol, gen, max):
    return floor((mol * 2654435761 + gen * 40503) % max)
```
Properties: deterministic, well-distributed, reproducible (Gen1==Gen2).

### VM requirements: None. Olang sufficient.

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

| Need | Level | Reason |
|------|-------|--------|
| `__str_split(text, delim)` | Nice-to-have | Decode needs word splitting. Currently char-by-char loop. |
| ~~`__str_contains`~~ | EXISTS | `__str_find(haystack, needle)` → array of positions. Sufficient. |
| `__mx_w2`/`__mxr2` | Optimize later | Separate activation matrix, avoid conflict with fact index. |

Nothing BLOCKS pipeline. Everything implementable in current Olang.
VM builtins only add speed.

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
