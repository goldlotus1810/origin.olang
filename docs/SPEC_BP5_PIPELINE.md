# SPEC Bộ Phận 5: Pipeline — Decode ∂ / SINH

> Tác giả: Nox SS15
> Ngày: 2026-04-01
> Trạng thái: CHƯA ĐẠT
> Phụ thuộc: BP2 (Encode), BP4 (Silk), BP3 (KnowTree)
> Không ai ngoài Nox SS15 được sửa file này.

---

## Bản chất

Pipeline không phải search engine. Pipeline là **máy vi-tính**:
- Vi = vi phân ∂ (phân tích, tách nhỏ để hiểu)
- Tính = tính cách, nhân cách (suy luận, không đối chiếu)

Input → Encode ∫ (tích phân: nhiều → 1 mol)
→ Suy luận (spreading activation + immune selection + DNA repair)
→ Decode ∂ (vi phân: 1 mol → nhiều → text MỚI)

LLM: so sánh trọng số → output gần nhất.
Nox: phân tích cấu trúc 5D → suy luận toán học → tổng hợp.

---

## Kiến trúc: 5 tầng

```
Tầng 1: CAPTURE     — input → mol (Encode ∫, đã có)
Tầng 2: ACTIVATE    — mol → activation field (Spreading Activation)
Tầng 3: HYPOTHESIZE — field → 3 candidate chains (CLONALG Immune)
Tầng 4: REPAIR      — chains → best chain (DCA + DNA Repair)
Tầng 5: DECODE      — chain → text mới (∂ Differentiation)
```

---

## Tầng 1: CAPTURE (ĐÃ CÓ)

```
encode(input) → mol = pack(S, R, V, A, T)
wm_bind(0, mol)
dim = mol_dominant_dim(mol)
```

Cái đã có: `_kt_real_mol()`, `mol_dominant_dim()`, `wm_set()`.
Cái chưa đạt: p_weight vẫn dùng NRC-VAD lookup, chưa 42 formulas TÍNH.
→ Phụ thuộc BP2. BP5 dùng mol như black box — khi BP2 cải thiện, BP5 tự tốt hơn.

---

## Tầng 2: ACTIVATE (CHƯA ĐẠT)

### Hiện tại: silk_walk đơn tuyến
```
path = kt_silk_walk_dim(start, dim, depth=3)
→ 1 đường, greedy, bỏ lỡ nhiều nodes liên quan
```

### Cần: Spreading Activation (Collins & Loftus 1975)

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

            // Implicit edges (computed, 0 bytes)
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

        // Convergence check
        if no change > epsilon: break

    // Return top-K activated nodes
    return sorted(A, by=activation, descending)[:K]

Parameters:
    r = 0.3     (retention — 30% stays at source)
    d = 0.2     (decay — 20% lost per step)
    s = 50      (suppression threshold — below = zero)
    F = 100     (firing threshold — must exceed to spread)
    K = 10      (max activated nodes to return)
    max_steps = 5
```

### Tại sao spreading activation thay silk walk:

| | Silk Walk | Spreading Activation |
|---|---|---|
| Đường đi | 1 path, greedy | Nhiều path đồng thời |
| Bỏ lỡ | Nodes ngoài path | Tìm MỌI nodes liên quan |
| Context | Không | Nodes từ nhiều hướng hội tụ = context |
| Tốc độ | O(depth × degree) | O(steps × edges) |
| Kết quả | Sequence | Activation field (richer) |

### Implement trong Olang:

Vấn đề: Olang không có hashmap. Dùng mol_matrix (__mx_w/__mxr) làm activation map.

```olang
// mol_matrix slot 2 (dùng __mx_w offset): activation values
// Mỗi mol có 1 activation value trong matrix

fn _spread_activate(_source, _dim, _steps) {
    // Clear activation region (set all to 0 would be expensive)
    // Instead: use a "generation" counter — only read values from current gen
    // For now: maintain a small visited array

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
                        // Track in results
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
            let _ = __set_at(_next_val, _di, __floor(__array_get(_next_val, _di) * 800 / 1000));
            let _di = _di + 1;
        };
        let _active = _next;
        let _active_val = _next_val;
        let _t = _t + 1;
    };
    return [_result_mols, _result_vals];
}
```

### Yêu cầu VM (cho Nox sửa VM):

1. **Không cần thêm gì nếu dùng arrays** — Olang arrays đủ cho prototype.
2. **Tối ưu sau**: nếu chậm, cần `__mx_w2`/`__mxr2` — second matrix cho activation values (tránh conflict với fact index matrix).

---

## Tầng 3: HYPOTHESIZE (CHƯA ĐẠT)

### Hiện tại: 3 silk walk đơn tuyến
```
branch0 = silk_walk(start, dim0, depth=3)
branch1 = silk_walk(start, dim1, depth=3)
branch2 = silk_walk(alt_start, dim0, depth=3)
→ 3 paths cứng, không mutation, không exploration
```

### Cần: CLONALG (De Castro & Von Zuben 2002)

```
clonalg_generate(activated_nodes, query_mol):
    // Initial population: top-3 activated nodes as seeds
    population = []
    for i in 0..3:
        seed = activated_nodes[i]
        chain = build_chain(seed, query_mol, depth=4)
        population.push(chain)

    // Clone + mutate
    for gen in 0..3:                    // max 3 generations (bounded)
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

        // Evaluate all clones
        all = population + clones
        all.sort(by=affinity, descending)
        population = all[:3]                         // keep top 3

    return population

chain_affinity(chain, query_mol):
    // Composite of distance + silk + consistency
    composed = compose(chain)
    dist = 1000 - _kt_mol_dist(composed, query_mol) * 100
    silk = avg_silk_strength(chain)
    consistency = dimensional_consistency(chain)
    return __floor(dist * 0.4 + silk * 0.3 + consistency * 0.3)

mutate_chain(chain, alpha):
    // Replace random node with neighbor
    n_mutations = max(1, round(len(chain) * alpha))
    result = copy(chain)
    for m in 0..n_mutations:
        idx = random_index(result)     // Note: Nox không có random
                                        // → dùng hash-based deterministic
        dim = mol_dominant_dim(query_mol)
        alternatives = implicit_neighbors(result[idx], dim, 3)
        if len(alternatives) > 0:
            result[idx] = alternatives[hash(result[idx]) % len(alternatives)]
    return result
```

### Vấn đề: Nox không có random

CLONALG dùng random cho mutation. Nox cần deterministic alternative.

**Giải pháp: Hash-based pseudo-selection**
```
// Thay random bằng hash của mol + generation counter
_pseudo_select(mol, gen, max):
    return __floor((mol * 2654435761 + gen * 40503) % max)
```

Tính chất: deterministic, distributed, reproducible (Gen1==Gen2).

### Yêu cầu VM: Không cần. Olang đủ.

---

## Tầng 4: REPAIR (CHƯA ĐẠT)

### Hiện tại: thay 1 node yếu nhất
```
find weakest link by implicit_strength → replace with neighbor
→ Thô, chỉ sửa 1 chỗ, không phân tích danger signals
```

### Cần: DCA Danger Theory (Greensmith 2005)

```
dca_repair(chain, query_mol, max_iter=3):
    backup = copy(chain)
    backup_quality = quality(chain, query_mol)

    for iter in 0..max_iter:
        if quality(chain, query_mol) >= 618:  // φ⁻¹ threshold
            return chain

        // Compute danger signals for each segment
        for i in 0..len(chain):
            // Safe Signal (SS): silk support + consistency
            ss = 0
            if i > 0:
                ss += implicit_strength(chain[i-1], chain[i])
            if i < len(chain)-1:
                ss += implicit_strength(chain[i], chain[i+1])
            ss = ss / 2

            // Danger Signal (DS): distance from query + inconsistency
            ds = _kt_mol_dist(chain[i], query_mol) * 50
            ds += dimensional_jump(chain, i) * 100

            // Context value: positive = danger, negative = safe
            k_hat[i] = ds - 2 * ss

        // Find segment with highest danger (most problematic)
        worst = argmax(k_hat)

        // Try replacing worst segment
        dim = mol_dominant_dim(query_mol)
        if worst > 0:
            // Find alternative that connects better to neighbors
            prev = chain[worst - 1]
            alternatives = implicit_neighbors(prev, dim, 5)
            best_alt = chain[worst]
            best_q = quality(chain, query_mol)

            for alt in alternatives:
                trial = copy(chain)
                trial[worst] = _kt_real_mol(alt)
                trial_q = quality(trial, query_mol)
                if trial_q > best_q:
                    best_alt = _kt_real_mol(alt)
                    best_q = trial_q

            chain[worst] = best_alt

        // Rollback if worse
        if quality(chain, query_mol) < backup_quality:
            return backup

    return chain

dimensional_jump(chain, i):
    // How much dimensions "jump" at position i
    if i == 0 or i >= len(chain) - 1: return 0
    jump = 0
    for d in 0..5:
        prev = mol_get_dim(chain[i-1], d)
        curr = mol_get_dim(chain[i], d)
        next = mol_get_dim(chain[i+1], d)
        expected = (prev + next) / 2
        jump += abs(curr - expected)
    return jump
```

### Quality Function (G12 spec)

```
quality(chain, query_mol):
    // v = validity (all nodes in KnowTree)
    v = 1000
    for mol in chain:
        if mol == 0: v = 0
        if __mxr(mol) == 0: v = v - 200    // not indexed

    // h = entropy penalty (lower entropy = more coherent)
    h = path_entropy(chain)
    h_norm = 1000 - floor(h * 1000 / 232)   // normalize by max H=2.32
    if h_norm < 0: h_norm = 0

    // c = consistency (dimensional coherence)
    coherent = 0
    for d in 0..5:
        values = [mol_get_dim(m, d) for m in chain]
        variance = var(values)
        max_range = [15, 15, 7, 7, 3][d]
        if variance < max_range^2 / 4: coherent += 1
    consistency = coherent * 200               // 0-1000

    // s = silk support
    silk_sum = 0
    for i in 0..len(chain)-1:
        silk_sum += implicit_strength(chain[i], chain[i+1])
    silk_avg = silk_sum / max(len(chain)-1, 1)
    if silk_avg > 1000: silk_avg = 1000

    return floor(300*v/1000 + 300*h_norm/1000 + 200*consistency/1000 + 200*silk_avg/1000)

Thresholds:
    < 300   → reject (quality quá thấp)
    300-618 → attempt repair
    >= 618  → accept (φ⁻¹ threshold)
```

### Yêu cầu VM: Không cần. Olang đủ.

---

## Tầng 5: DECODE ∂ (CHƯA ĐẠT)

### Hiện tại: concatenate kt_nearest texts
```
for mol in path:
    fact = kt_nearest(mol)
    response += fact + ". "
→ Copy-paste, không phải vi phân
```

### Cần: Maximal Join (Sowa 1984) + Differentiation

**Nguyên lý:** Decode = ∂. Output = gradient field của knowledge graph.

```
decode_generate(chain, query_mol):
    // 1. Collect texts for each node in chain
    fragments = []
    for mol in chain:
        fact = kt_nearest(mol)
        if len(fact) > 0:
            fragments.push({text: fact, mol: mol})

    if len(fragments) == 0: return ""

    // 2. Maximal Join: find shared concepts between fragments
    //    Two fragments share concept if they have word overlap
    //    Join produces combined text preserving both

    joined = fragments[0].text
    for i in 1..len(fragments):
        overlap = find_overlap(joined, fragments[i].text)
        if len(overlap) > 0:
            // Join at overlap point — don't repeat shared content
            joined = merge_at_overlap(joined, fragments[i].text, overlap)
        else:
            // No overlap — concatenate with separator
            joined = joined + ". " + fragments[i].text

    // 3. Apply ConversationCurve tone
    tone = select_tone()

    // 4. Truncate if too long (max 3 distinct facts)
    // This is a practical limit, not theoretical

    return joined

find_overlap(text_a, text_b):
    // Find longest common substring (words, not chars)
    words_a = split(text_a, " ")
    words_b = split(text_b, " ")
    // Simple: check if any word in B appears in A
    shared = []
    for w in words_b:
        if len(w) >= 3:
            if contains(text_a, w):
                shared.push(w)
    return shared

merge_at_overlap(base, addition, overlap):
    // Remove overlapping part from addition, append rest
    // Example:
    //   base = "Olang la ngon ngu lap trinh"
    //   addition = "Olang la ngon ngu cua Nox"
    //   overlap = ["Olang", "ngon", "ngu"]
    //   result = "Olang la ngon ngu lap trinh, cua Nox"

    // Simple approach: if addition starts with known overlap, take only the new part
    for word in overlap:
        addition = remove_first_occurrence(addition, word)
    addition = trim(addition)
    if len(addition) > 0:
        return base + ", " + addition
    return base
```

### Vi phân thật: ∂P/∂dim

```
Decode không chỉ là "tìm text gần nhất". Decode là TRÍCH XUẤT theo dimension:

∂P/∂S → cấu trúc hình dạng → chọn SDF primitive → render hình
∂P/∂R → vai trò quan hệ → chọn relation type → "là", "thuộc", "gây ra"
∂P/∂V → cảm xúc → chọn từ positive/negative → "đẹp", "buồn"
∂P/∂A → cường độ → chọn mức intensity → "rất", "cực kỳ", ""
∂P/∂T → thời gian → chọn tense → "đang", "đã", "sẽ"

Khi decode 1 mol thành text:
1. R dimension quyết định CẤU TRÚC câu (subject-verb-object)
2. S dimension quyết định NỘI DUNG (shape/form of concepts)
3. V dimension quyết định GIỌNG ĐIỆU (emotional coloring)
4. A dimension quyết định CƯỜNG ĐỘ (intensity modifiers)
5. T dimension quyết định THỜI GIAN (temporal markers)

Hiện tại chưa implement được vì cần:
- Reverse lookup: mol → possible words (chưa có)
- Syntactic templates per R type (chưa có)
- Intensity modifiers per A level (chưa có)

→ Phụ thuộc BP2 (Encode) hoàn thiện reverse mapping.
→ Hiện tại dùng kt_nearest() fallback là đúng.
```

### Yêu cầu VM:

1. **String split builtin** — `__str_split(text, delimiter)` → array of strings. Hiện phải loop char-by-char.
2. **String contains builtin** — `__str_contains(haystack, needle)` → 0/1. Hiện phải dùng word index.

Không bắt buộc (có thể implement trong Olang) nhưng sẽ nhanh hơn nhiều nếu có trong VM.

---

## ConversationCurve (CẦN BỔ SUNG)

### Hiện tại:
```
V'(t) = V(t) - V(t-1)                  // đã có
V''(t) = V'(t) - V'(t-1)               // đã có
select_tone() → 5 tones                 // đã có
```

### Cần bổ sung:

```
// Tone application — thay đổi CÁCH nói, không thay đổi NỘI DUNG
apply_tone(text, tone):
    if tone == "supportive":
        // Prepend empathy marker
        return text
    if tone == "pause":
        // Shorten response
        return first_sentence(text)
    if tone == "reinforcing":
        return text
    if tone == "celebratory":
        return text
    return text  // "engaged" — no modification

// Rate limit: |ΔV| ≤ 0.40 per step (chưa implement)
// Cần clamp V changes trong _curve_push_v()
```

### Yêu cầu VM: Không cần.

---

## Instinct Integration (CẦN BỔ SUNG)

### Hiện tại: chỉ dùng Honesty
```
instinct_honesty(mol) → confidence score → nhưng không ảnh hưởng output
```

### Cần wire vào pipeline:

```
// Sau ACTIVATE, trước HYPOTHESIZE:

confidence = instinct_honesty(query_mol)
if confidence < 40:
    return ""                    // im lặng — không biết

contradiction = instinct_contradiction(query_mol, nearest_mol)
if contradiction > 700:
    // Phát hiện mâu thuẫn — cần resolve
    // ...

curiosity = instinct_curiosity(query_mol)
if curiosity > 500:
    // Input mới lạ — tăng learning rate
    learn_mode = 1
```

### Yêu cầu VM: Không cần. Instinct functions đã có trong instinct.ol.

---

## Checkpoints (CHƯA CÓ)

```
CP1 (GATE):     SecurityGate passed, mol valid         — đã có
CP2 (ENCODE):   chain.len >= 1, mol != 0               — đã có implicit
CP3 (INFER):    >=1 branch quality >= 618              — CHƯA CÓ
CP4 (PROMOTE):  weight >= 618, fire >= Fib(n)          — CHƯA CÓ
CP5 (RESPONSE): security_gate(response) safe           — CHƯA CÓ
```

### Yêu cầu VM: Không cần.

---

## Tổng hợp yêu cầu cho VM (Nox sửa VM)

| Yêu cầu | Mức độ | Lý do |
|----------|--------|-------|
| `__str_split(text, delim)` | Tốt nếu có | Decode cần split text thành words. Hiện dùng loop char-by-char. |
| ~~`__str_contains`~~ | ĐÃ CÓ | `__str_find(haystack, needle)` → array positions. Đủ. |
| `__mx_w2`/`__mxr2` (matrix 2) | Tối ưu sau | Activation field riêng, tránh conflict |
| Random/hash builtin | Không cần | Dùng hash-based deterministic |

Không có gì CHẶN pipeline. Tất cả có thể implement bằng Olang hiện tại.
VM builtins chỉ tăng tốc.

---

## Kiểm tra (CHƯA ĐẠT)

```
Test 1: "Olang la gi?" → response chứa "Olang" + thông tin từ nhiều facts
Test 2: "happiness" → response SINH (không phải copy 1 fact)
Test 3: Response khác nhau khi V'(t) thay đổi (tone hoạt động)
Test 4: 3 branches có entropy khác nhau (immune selection hoạt động)
Test 5: DNA repair cải thiện quality (trước < sau)
Test 6: Spreading activation tìm nodes mà silk walk bỏ lỡ
Test 7: Maximal join merge 2 facts thành 1 câu mới
Test 8: Confidence < 0.40 → im lặng (instinct honesty)
```

---

## Thứ tự phát triển

```
Giai đoạn 1: Spreading Activation thay silk walk đơn tuyến
Giai đoạn 2: CLONALG thay 3 branches cứng
Giai đoạn 3: DCA Danger Signals thay find-weakest-link
Giai đoạn 4: Maximal Join thay concatenate
Giai đoạn 5: Wire instincts (honesty silence, curiosity learn)
Giai đoạn 6: Checkpoints CP3-CP5
Giai đoạn 7: True ∂ decode (khi BP2 có reverse mapping)
```

Mỗi giai đoạn: implement → test → đạt/chưa đạt → tiếp.

---

## Tài liệu tham khảo

```
Collins, A.M. & Loftus, E.F. (1975). Spreading-Activation Theory. Psychological Review 82(6).
De Castro, L.N. & Von Zuben, F.J. (2002). CLONALG. IEEE Trans. Evolutionary Computation 6(3).
Greensmith, J. et al. (2005). Dendritic Cell Algorithm. ICARIS 2005.
Sowa, J.F. (1984). Conceptual Structures. Addison-Wesley.
Mann, W.C. & Thompson, S.A. (1988). Rhetorical Structure Theory. Text 8(3).
Mac Lane, S. (1971). Categories for the Working Mathematician. Springer.
Forrest, S. et al. (1994). Self-Nonself Discrimination. IEEE S&P.
Wickelgren, W.A. (1974). Power law of forgetting.
Oja, E. (1982). Normalized Hebbian learning.
Bi, G. & Poo, M. (1998). STDP. Journal of Neuroscience.
Bienenstock, E. et al. (1982). BCM theory.
```

---

*Bộ phận 5 CHƯA ĐẠT. Spec này là bản đồ. Mỗi session tiếp: đọc spec → implement 1 giai đoạn → test → đạt/chưa đạt.*
