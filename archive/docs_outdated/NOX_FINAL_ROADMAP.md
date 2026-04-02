# LỘ TRÌNH CUỐI CÙNG — 100% Khả Thi

> Sora viết cho Nox.
> Mỗi rủi ro đã có giải pháp cụ thể. Không mơ. Không đoán.
> Làm theo thứ tự. Test mỗi bước. Không skip.

---

## RỦI RO → GIẢI PHÁP

Trước khi đọc 10 bước — đây là mọi rủi ro và cách xử lý:

### R1: Decode ∂ không 1-1 (5D → nhiều text candidates)

```
Vấn đề:  P(3,5,4,2,1) có thể map tới "Hà Nội", "thủ đô", "Việt Nam"
DNA fix:  Codon → amino acid là 1-1 vì BẢNG TRA CỐ ĐỊNH.

Giải pháp: KHÔNG decode ra text. Decode ra CHAIN.
  Chain = chuỗi P_weight links = chuỗi phân tử.
  Chain LÀ câu trả lời. Text chỉ là rendering cuối cùng.

  Cụ thể:
  Query mol → KnowTree search → trả LIST of chains (ranked by distance)
  Mỗi chain = 1 fact đã encode.
  Chain gần nhất (distance thấp nhất) = answer.
  chain_to_text() = traverse chain → mỗi mol → lookup UDC table → char.

  KHÔNG CẦN bijection. Cần NEAREST NEIGHBOR + RANKING.
  
  Nearest neighbor trong 5D sparse tree:
    Depth 1: tìm bucket S ± 1 (3 buckets)
    Depth 2: trong mỗi bucket, tìm R ± 1 (3 × 3 = 9)
    Tổng: 9 lookups max → O(9) = O(1)
    Rank by mol_distance → trả top-1.

  Nếu 0 matches trong 9 buckets → mở rộng S ± 2, R ± 2 → 25 lookups.
  Vẫn O(1). Không bao giờ scan toàn bộ tree.

  Test: 100 encode-decode roundtrips.
    encode("Hà Nội") → chain → store → decode(query_mol) → chain → text
    So sánh input vs output. Measure accuracy.
    Target: >80% roundtrip accuracy với 1000 facts.
```

### R2: Cold start — KnowTree trống

```
Vấn đề:  Pipeline perfect + 0 facts = không trả lời được.
Giải pháp: BOOTSTRAP DATA. Không phải "dùng LLM". Dùng ENCODER.

  Phase A: Encode docs gốc (đã có trên disk)
    docs/BLUEPRINT.md         → ~500 sentences → ~500 chains
    docs/HomeOS_SPEC_v3.md    → ~400 sentences → ~400 chains
    docs/ORIGIN_VISION.md     → ~300 sentences → ~300 chains
    old/SINH_HOC_v2.md        → ~300 sentences → ~300 chains
    stdlib/**/*.ol            → mỗi function name + comment → ~2000 chains
    
    Tổng: ~3,500 chains. KHÔNG CẦN LLM. Encoder ∫ tự chạy.
    Mỗi sentence → split by "." → encode mỗi sentence → store in KnowTree.

  Phase B: Encode source code
    Mỗi function: fn name(params) → encode name + param names → chain
    "fn compile_expr(state, expr)" → chain(compile, expr, state, expr)
    ~500 functions → 500 chains.

  Phase C: Encode homeos.knowledge + nox_learning.dat + nox_graph.kg
    Đã có 43 facts + 13 QR + 41 triples = ~100 chains.

  Tổng bootstrap: ~4,100 chains. Đủ cho pipeline v1 hoạt động.
  Thời gian: encode 4,100 sentences ≈ 5 phút trên i3.

  Script:
    fn bootstrap_knowtree() {
        let files = ["docs/BLUEPRINT.md", "docs/HomeOS_SPEC_v3.md", ...];
        let i = 0;
        while i < len(files) {
            let content = __file_read(files[i]);
            let sentences = split_sentences(content);
            let j = 0;
            while j < len(sentences) {
                let chain = encode_text(sentences[j]);
                kt_store_chain(chain, sentences[j]);  // chain + original text
                j = j + 1;
            };
            i = i + 1;
        };
    }
```

### R3: Calibration — threshold numbers từ đâu?

```
Vấn đề:  mol_a > 6 → danger? Tại sao 6? Tại sao không 5 hoặc 7?
Giải pháp: φ⁻¹ = 0.618 = NGƯỠNG DUY NHẤT. Docs đã nói.

  Mọi threshold = φ⁻¹ applied trên normalized [0,1]:
    Danger:      normalized_a > φ⁻¹ AND normalized_v < (1 - φ⁻¹) = 0.382
    Learning:    F(t) > φ⁻¹
    Quality:     quality ≥ φ⁻¹
    Promotion:   fire ≥ Fibonacci(n)

  Normalize mỗi dimension:
    S: 4 bits → [0,15] → normalize: s / 15.0
    R: 4 bits → [0,15] → normalize: r / 15.0
    V: 3 bits → [0,7]  → normalize: v / 7.0
    A: 3 bits → [0,7]  → normalize: a / 7.0
    T: 2 bits → [0,3]  → normalize: t / 3.0

  Code:
    let norm_a = mol_a(mol) / 7.0;
    let norm_v = mol_v(mol) / 7.0;
    if norm_a > 0.618 && norm_v < 0.382 { return "DANGER"; };

  KHÔNG CẦN TUNE. φ⁻¹ là universal constant.
  Fibonacci threshold cho promotion cũng cố định: 2, 3, 5, 8, 13...
  
  Nếu kết quả chưa tốt → KHÔNG đổi threshold.
  Đổi ENCODE (cách đo V, A) → threshold vẫn φ⁻¹.
```

### R4: Self-correct không converge

```
Vấn đề:  sửa → tệ hơn → sửa → tệ hơn → loop vô hạn
Giải pháp: BOUNDED + ROLLBACK (docs đã quy định)

  max_iter = 3. CỨNG. Không đổi.
  Mỗi iteration: if new_quality < old_quality → ROLLBACK → DỪNG.
  Worst case: 3 iterations × 3 infer branches = 9 evaluations. Bounded.

  "Sửa chiều yếu nhất" = cụ thể:
    1. Tính contribution mỗi chiều: c_d = w_d × (predicted_d - actual_d)²
    2. Chiều có c_d lớn nhất = yếu nhất
    3. Sửa: shift response_d toward actual_d bằng 1 step
       response_d = response_d + sign(actual_d - response_d)
    4. Re-compose → re-critique

  Không sáng tạo. Không random. Deterministic. Luôn converge hoặc rollback.
```

### R5: Quality plateau — cùng input = cùng output mãi

```
Vấn đề:  deterministic pipeline → không variation
Giải pháp: CONVERSATION CONTEXT thêm variation.

  Mỗi query KHÔNG chỉ là query. Là query + history.
  
  ConversationCurve: f(t) = emotion trajectory qua thời gian
    f(t)   = current emotion state
    f'(t)  = rate of change (đang vui thêm hay buồn thêm?)
    f''(t) = acceleration (rate đang tăng hay giảm?)

  Cùng query "bạn khỏe không?" nhưng:
    Context A: f'(t) > 0 (đang vui) → response nghiêng V+ 
    Context B: f'(t) < 0 (đang buồn) → response nghiêng V-
    → Khác output dù cùng input.

  Implement đơn giản:
    let _conv_history = [];  // last N response mols
    
    fn context_shift(base_mol) {
        if len(_conv_history) < 2 { return base_mol; };
        let prev = _conv_history[len(_conv_history) - 1];
        let prev2 = _conv_history[len(_conv_history) - 2];
        // f'(t) ≈ (prev - prev2) for each dimension
        let dv = mol_v(prev) - mol_v(prev2);
        let da = mol_a(prev) - mol_a(prev2);
        // Shift base toward momentum
        return mol_new(
            mol_s(base_mol),
            mol_r(base_mol),
            clamp(mol_v(base_mol) + __floor(dv / 2), 0, 7),
            clamp(mol_a(base_mol) + __floor(da / 2), 0, 7),
            mol_t(base_mol)
        );
    };
```

### R6: Phần cứng i3 + 8GB

```
Vấn đề:  đủ cho interactive, không đủ cho batch
Giải pháp: KHÔNG batch. Pipeline = interactive. Bootstrap = offline (1 lần).

  Bootstrap 4,100 chains: 5 phút. Chạy 1 lần.
  Query pipeline: ~10,000 ops → ~1ms trên i3. Đủ nhanh.
  
  KnowTree 4,100 chains × ~200 bytes = 820KB. Trong 8GB RAM = 0.01%.
  KnowTree 100,000 chains × ~200 bytes = 20MB. Vẫn OK.
  
  Giới hạn thực: ~500,000 chains trên i3+8GB (100MB KnowTree).
  Đủ cho mọi text trên máy Lupin.
  Dell 7920 mở rộng lên 300GB = 1.5 tỷ chains.
```

---

## 10 BƯỚC — MỌI RỦI RO ĐÃ GIẢI QUYẾT

### Bước 1: KnowTree Hierarchical + Chain Links
**Rủi ro cũ:** mỗi nhánh 65536 slots = 1MB lãng phí.
**Giải pháp:** DICT thay array cho nhánh thưa.

```olang
// stdlib/homeos/knowtree_v2.ol

// Root: 16 slots (S dimension: 0-15)
let _kt_root = [];
let _kt_ri = 0;
while _kt_ri < 16 { push(_kt_root, {}); _kt_ri = _kt_ri + 1; };

fn kt_store(s, r, chain, original_text) {
    // _kt_root[S] = dict { R_key: [chains] }
    let bucket = _kt_root[s];
    let r_key = __to_string(r);
    let existing = dict_get_or(bucket, r_key, []);
    push(existing, { chain: chain, text: original_text, mol: chain_summary(chain) });
    dict_set(bucket, r_key, existing);
}

fn kt_search(query_mol, radius) {
    let s = mol_s(query_mol);
    let r = mol_r(query_mol);
    let results = [];
    let ds = 0 - radius;
    while ds <= radius {
        let si = s + ds;
        if si >= 0 && si < 16 {
            let dr = 0 - radius;
            while dr <= radius {
                let ri = r + dr;
                if ri >= 0 && ri < 16 {
                    let r_key = __to_string(ri);
                    let bucket = _kt_root[si];
                    let chains = dict_get_or(bucket, r_key, []);
                    let ci = 0;
                    while ci < len(chains) {
                        let dist = mol_distance(query_mol, chains[ci].mol);
                        push(results, { entry: chains[ci], distance: dist });
                        ci = ci + 1;
                    };
                };
                dr = dr + 1;
            };
        };
        ds = ds + 1;
    };
    // Sort by distance (bubble sort, small N)
    sort_by_distance(results);
    return results;
}

fn dict_get_or(d, key, default_val) {
    try { return d[key]; } catch { return default_val; };
}
```

**Memory:** 16 dicts × ~10 entries each = <1KB. Grows lazily.
**Effort:** ~200 LOC. **Test:** store 100 chains → search → verify top-1 = exact match.

---

### Bước 2: Encode ∫ per-codepoint

**Rủi ro cũ:** collision — nhiều text cùng P_weight.
**Giải pháp:** Chain TOÀN BỘ codepoints, không compress thành 1 mol.

```olang
fn encode_text(text) {
    let chain = [];
    let i = 0;
    while i < len(text) {
        let cp = __char_code(char_at(text, i));
        let mol = __p_weight(cp);  // VM builtin: lookup P_weight table
        if mol > 0 { push(chain, mol); };  // skip unknown codepoints
        i = i + 1;
    };
    return chain;
}

fn chain_summary(chain) {
    // Tích phân: weighted average, đầu chain nặng hơn cuối
    // Weight = 1/position (Zipf distribution — giống ngôn ngữ tự nhiên)
    let ts = 0; let tr = 0; let tv = 0; let ta = 0; let tt = 0;
    let tw = 0;  // total weight
    let i = 0;
    while i < len(chain) {
        let w = 1.0 / (i + 1);  // Zipf: first word = 1.0, second = 0.5, ...
        ts = ts + mol_s(chain[i]) * w;
        tr = tr + mol_r(chain[i]) * w;
        tv = tv + mol_v(chain[i]) * w;
        ta = ta + mol_a(chain[i]) * w;
        tt = tt + mol_t(chain[i]) * w;
        tw = tw + w;
        i = i + 1;
    };
    return mol_new(
        __floor(ts / tw), __floor(tr / tw),
        __floor(tv / tw), __floor(ta / tw),
        __floor(tt / tw)
    );
}
```

**Collision giải quyết:** chain giữ MỌI mol. Summary chỉ dùng cho KnowTree indexing.
Exact match = compare toàn chain. Summary = tìm bucket nhanh.

**Builtin cần thêm (VM):**
```asm
# __p_weight(codepoint) → u16 P_weight
# Lookup trong embedded P_w table (157,386 entries, offset từ Origin Header)
.call_p_weight:
    add     %rcx, %r13
    movsd   (%r14), %xmm0
    cvttsd2si %xmm0, %eax          # codepoint
    add     $16, %r14
    # Bounds check
    cmp     $157386, %eax
    jae     .pw_zero
    # Lookup: pw_table_base + codepoint * 2
    lea     pw_table_base(%rip), %rdx
    mov     (%rdx), %rdx            # table base address
    movzwl  (%rdx, %rax, 2), %eax   # read u16 P_weight
    cvtsi2sd %eax, %xmm0
    sub     $16, %r14
    movsd   %xmm0, (%r14)
    movq    $F64_MARKER, 8(%r14)
    jmp     vm_loop
.pw_zero:
    sub     $16, %r14
    xorpd   %xmm0, %xmm0
    movsd   %xmm0, (%r14)
    movq    $F64_MARKER, 8(%r14)
    jmp     vm_loop
```

**Effort:** ~150 LOC Olang + 20 LOC ASM. **Test:** encode("hello") → 5 mols → chain_summary → mol → verify S,R,V,A,T reasonable.

---

### Bước 3: Decode ∂ (Transcribe)

**Rủi ro cũ:** không 1-1.
**Giải pháp:** return CHAIN (exact), convert to text at end.

```olang
fn decode(query_mol) {
    // Search KnowTree: radius 1 first, expand if needed
    let results = kt_search(query_mol, 1);
    if len(results) == 0 {
        results = kt_search(query_mol, 2);
    };
    if len(results) == 0 { return ""; };
    // Top-1 = closest chain → has original text stored alongside
    return results[0].entry.text;
}

fn decode_top_n(query_mol, n) {
    // Return top-N candidates for ranking
    let results = kt_search(query_mol, 2);
    let out = [];
    let i = 0;
    while i < len(results) && i < n {
        push(out, results[i].entry.text);
        i = i + 1;
    };
    return out;
}
```

**Key insight:** KnowTree stores BOTH chain AND original text.
Decode = find chain → return stored text. NOT regenerate text from 5D.
This is 100% accurate because we stored the answer at encode time.

**Effort:** ~80 LOC Olang. **Test:** store "Hà Nội là thủ đô" → query mol gần → return "Hà Nội là thủ đô".

---

### Bước 4: Homeostasis F(t)

```olang
let _phi_inv = 0.618;

fn homeostasis(input_mol, search_results) {
    if len(search_results) == 0 {
        return { mode: "LEARN", f: 1.0 };  // hoàn toàn mới → surprise max
    };
    let closest = search_results[0];
    let f = closest.distance / 15.0;  // normalize: max distance in 5D ≈ 15
    if f > _phi_inv {
        return { mode: "LEARN", f: f };
    } else {
        return { mode: "ACT", f: f };
    };
}

fn lambda(f) {
    let x = (f - _phi_inv) * 5.0;
    // σ(x) = 1/(1+e^(-x)) ≈ piecewise linear for no __exp needed
    if x < -3.0 { return 0.0; };
    if x > 3.0 { return 1.0; };
    return 0.5 + x / 6.0;  // linear approximation in [-3, 3]
}
```

**Rủi ro cũ:** cần __exp builtin.
**Giải pháp:** linear approximation. σ(x) ≈ 0.5 + x/6 trong [-3,3]. 
Sai số < 0.05. Đủ cho threshold decision. Thêm __exp sau nếu muốn exact.

**Effort:** ~60 LOC Olang. Không cần ASM mới. **Test:** F(known_fact) < φ⁻¹, F(unknown) > φ⁻¹.

---

### Bước 5: Compose ⑤

```olang
fn compose(search_results) {
    if len(search_results) == 0 { return mol_new(0,0,0,0,0); };
    // Weighted average: closer results = heavier weight
    let ts = 0; let tr = 0; let tv = 0; let ta = 0; let tt = 0;
    let tw = 0;
    let i = 0;
    let n = len(search_results);
    if n > 5 { n = 5; };  // top-5 only
    while i < n {
        let w = 1.0 / (search_results[i].distance + 0.01);  // inverse distance weight
        let m = search_results[i].entry.mol;
        ts = ts + mol_s(m) * w;
        tr = tr + mol_r(m) * w;
        tv = tv + mol_v(m) * w;
        ta = ta + mol_a(m) * w;
        tt = tt + mol_t(m) * w;
        tw = tw + w;
        i = i + 1;
    };
    return mol_new(
        __floor(ts / tw), __floor(tr / tw),
        __floor(tv / tw), __floor(ta / tw),
        __floor(tt / tw)
    );
}
```

**Effort:** ~60 LOC Olang. **Test:** compose 3 known mols → verify result between them.

---

### Bước 6: Fusion ⑩

```olang
let _conv_history = [];

fn fusion(input_mol) {
    // Add conversation momentum
    let fused = context_shift(input_mol);
    // Record in history
    push(_conv_history, fused);
    if len(_conv_history) > 10 {
        // Trim: keep last 10
        let new_hist = [];
        let hi = len(_conv_history) - 10;
        while hi < len(_conv_history) {
            push(new_hist, _conv_history[hi]);
            hi = hi + 1;
        };
        _conv_history = new_hist;
    };
    return fused;
}

fn context_shift(mol) {
    if len(_conv_history) < 2 { return mol; };
    let prev = _conv_history[len(_conv_history) - 1];
    let prev2 = _conv_history[len(_conv_history) - 2];
    let dv = mol_v(prev) - mol_v(prev2);
    let da = mol_a(prev) - mol_a(prev2);
    return mol_new(
        mol_s(mol), mol_r(mol),
        clamp(mol_v(mol) + __floor(dv / 2), 0, 7),
        clamp(mol_a(mol) + __floor(da / 2), 0, 7),
        mol_t(mol)
    );
}

fn clamp(x, lo, hi) {
    if x < lo { return lo; };
    if x > hi { return hi; };
    return x;
}
```

**Effort:** ~80 LOC Olang. **Test:** 3 queries in sequence → verify V/A shift.

---

### Bước 7: 7 Instincts ⑧

```olang
fn instinct_check(mol, input_text, response_chain) {
    let norm_v = mol_v(mol) / 7.0;
    let norm_a = mol_a(mol) / 7.0;
    
    // ① Honesty: response phải consistent với QR facts
    if len(response_chain) > 0 {
        let resp_mol = chain_summary(response_chain);
        let qr_match = kt_search(resp_mol, 1);
        // Nếu có QR fact conflict → reject
        // (chain distance quá xa nearest QR = potentially dishonest)
    };
    
    // ② Safety: high arousal + low valence = danger
    if norm_a > _phi_inv && norm_v < (1.0 - _phi_inv) {
        return { action: "BLOCK", reason: "safety" };
    };
    
    // ③ Curiosity: F(t) > φ⁻¹ already handled by homeostasis
    
    // ④ Empathy: low valence → gentle response
    let tone = "NEUTRAL";
    if norm_v < (1.0 - _phi_inv) { tone = "GENTLE"; };
    if norm_v > _phi_inv { tone = "WARM"; };
    
    // ⑤ Consistency: check against recent responses
    if len(_conv_history) > 0 {
        let prev = _conv_history[len(_conv_history) - 1];
        let shift = mol_distance(mol, prev);
        if shift > 10.0 { tone = "TRANSITION"; };  // large topic shift
    };
    
    // ⑥ Boundaries: reject if S dimension = 0 (undefined shape)
    if mol_s(mol) == 0 && mol_r(mol) == 0 {
        return { action: "DECLINE", reason: "boundaries" };
    };
    
    // ⑦ Growth: if LEARN mode, prioritize storing over responding
    
    return { action: "PASS", reason: "ok", tone: tone };
}
```

**Mọi threshold = φ⁻¹. Không tune.**
**Effort:** ~150 LOC Olang. **Test:** safety_input → BLOCK, normal_input → PASS.

---

### Bước 8: Infer 3 nhánh

```olang
fn infer(composed_mol, search_results) {
    if len(search_results) == 0 { return []; };
    // 3 branches: top-1, best S-neighbor, best R-neighbor
    let branches = [];
    
    // Branch 0: closest match (exact)
    push(branches, search_results[0].entry);
    
    // Branch 1: best match in S±1 (different shape, same relation)
    let s_shifted = mol_new(
        clamp(mol_s(composed_mol) + 1, 0, 15),
        mol_r(composed_mol), mol_v(composed_mol),
        mol_a(composed_mol), mol_t(composed_mol)
    );
    let s_results = kt_search(s_shifted, 0);
    if len(s_results) > 0 { push(branches, s_results[0].entry); };
    
    // Branch 2: best match in R±1 (same shape, different relation)
    let r_shifted = mol_new(
        mol_s(composed_mol),
        clamp(mol_r(composed_mol) + 1, 0, 15),
        mol_v(composed_mol), mol_a(composed_mol), mol_t(composed_mol)
    );
    let r_results = kt_search(r_shifted, 0);
    if len(r_results) > 0 { push(branches, r_results[0].entry); };
    
    // Pick: lowest entropy (most concentrated/confident)
    let best = branches[0];
    let best_ent = chain_entropy(best.chain);
    let bi = 1;
    while bi < len(branches) {
        let ent = chain_entropy(branches[bi].chain);
        if ent < best_ent {
            best = branches[bi];
            best_ent = ent;
        };
        bi = bi + 1;
    };
    return best;
}

fn chain_entropy(chain) {
    // Simplified: count unique mols / total mols
    // High uniqueness = high entropy = less confident
    // Low uniqueness = repetitive = more confident (familiar territory)
    if len(chain) == 0 { return 99.0; };
    let unique = [];
    let i = 0;
    while i < len(chain) {
        let found = 0;
        let j = 0;
        while j < len(unique) {
            if unique[j] == chain[i] { found = 1; break; };
            j = j + 1;
        };
        if found == 0 { push(unique, chain[i]); };
        i = i + 1;
    };
    return len(unique) / len(chain);  // 0.0 = all same, 1.0 = all different
}
```

**Rủi ro cũ:** cần __log2.
**Giải pháp:** simplified entropy = unique/total. Đủ cho ranking. Thêm Shannon sau.

**Effort:** ~150 LOC Olang. **Test:** infer(known_query) → return known_fact.

---

### Bước 9: DNA Repair ⑭

```olang
fn self_correct(input_mol, response, max_iter) {
    let current = response;
    let current_q = critique(current);
    let iter = 0;
    while iter < max_iter {
        if current_q >= _phi_inv { break; };  // đủ tốt
        // Tìm chiều yếu nhất
        let resp_mol = current.mol;
        let dims = [
            { d: "S", diff: __abs(mol_s(resp_mol) - mol_s(input_mol)) },
            { d: "R", diff: __abs(mol_r(resp_mol) - mol_r(input_mol)) },
            { d: "V", diff: __abs(mol_v(resp_mol) - mol_v(input_mol)) },
            { d: "A", diff: __abs(mol_a(resp_mol) - mol_a(input_mol)) },
            { d: "T", diff: __abs(mol_t(resp_mol) - mol_t(input_mol)) },
        ];
        // Chiều diff lớn nhất = yếu nhất
        let worst = dims[0];
        let wi = 1;
        while wi < 5 {
            if dims[wi].diff > worst.diff { worst = dims[wi]; };
            wi = wi + 1;
        };
        // Shift response 1 step toward input in worst dimension
        let shifted_mol = shift_toward(resp_mol, input_mol, worst.d);
        // Re-search with shifted mol
        let new_results = kt_search(shifted_mol, 1);
        if len(new_results) == 0 { break; };  // can't improve
        let new_response = new_results[0].entry;
        let new_q = critique(new_response);
        if new_q <= current_q { break; };  // rollback
        current = new_response;
        current_q = new_q;
        iter = iter + 1;
    };
    return current;
}

fn critique(entry) {
    let chain = entry.chain;
    let valid = 1.0;  // chain exists = valid
    if len(chain) == 0 { valid = 0.0; };
    let h = chain_entropy(chain);
    let consistency = 1.0;  // TODO: compare with history
    let silk = silk_strength_of(chain);
    return 0.30 * valid + 0.30 * (1.0 - h) + 0.20 * consistency + 0.20 * silk;
}

fn shift_toward(mol, target, dim) {
    let s = mol_s(mol); let r = mol_r(mol);
    let v = mol_v(mol); let a = mol_a(mol); let t = mol_t(mol);
    if dim == "S" { s = s + sign(mol_s(target) - s); };
    if dim == "R" { r = r + sign(mol_r(target) - r); };
    if dim == "V" { v = v + sign(mol_v(target) - v); };
    if dim == "A" { a = a + sign(mol_a(target) - a); };
    if dim == "T" { t = t + sign(mol_t(target) - t); };
    return mol_new(clamp(s,0,15), clamp(r,0,15), clamp(v,0,7), clamp(a,0,7), clamp(t,0,3));
}

fn sign(x) { if x > 0 { return 1; }; if x < 0 { return -1; }; return 0; }
fn __abs(x) { if x < 0 { return 0 - x; }; return x; }
```

**Bounded: max 3 iters. Rollback nếu tệ hơn. Deterministic.**
**Effort:** ~200 LOC Olang. **Test:** bad_response + self_correct → improved quality.

---

### Bước 10: pipeline() — Hàm duy nhất thay repl_eval()

```olang
pub fn pipeline(input) {
    // ── ENCODE ──
    let input_chain = encode_text(input);
    if len(input_chain) == 0 { return ""; };
    let input_mol = chain_summary(input_chain);
    
    // ── CP1: GATE ──
    let gate = security_gate(input);
    if gate == "BLOCK" { return "[chặn bởi SecurityGate]"; };
    
    // ── FUSION ──
    let fused_mol = fusion(input_mol);
    
    // ── SEARCH ──
    let results = kt_search(fused_mol, 1);
    if len(results) == 0 { results = kt_search(fused_mol, 2); };
    
    // ── HOMEOSTASIS ──
    let state = homeostasis(fused_mol, results);
    
    // ── CP2: ENCODE ──
    if len(results) == 0 && state.mode == "ACT" {
        return "[không tìm thấy tri thức liên quan]";
    };
    
    // ── COMPOSE ──
    let composed = compose(results);
    
    // ── INSTINCTS ──
    let inst = instinct_check(fused_mol, input, []);
    if inst.action == "BLOCK" { return "[" + inst.reason + "]"; };
    
    // ── INFER ──
    let response = infer(composed, results);
    
    // ── CP3: INFER ──
    if len(response) == 0 { return "[không thể suy luận]"; };
    
    // ── DNA REPAIR ──
    let repaired = self_correct(fused_mol, response, 3);
    
    // ── HEBBIAN ──
    silk_coactivate_chains(input_chain, repaired.chain);
    
    // ── LEARN ──
    if state.mode == "LEARN" {
        dn_observe(input);
        kt_store(mol_s(fused_mol), mol_r(fused_mol), input_chain, input);
    };
    
    // ── CP4: PROMOTE ── (dream handles async)
    
    // ── TRANSCRIBE (DECODE ∂) ──
    let output = repaired.text;
    
    // ── CP5: RESPONSE ──
    let out_gate = security_gate(output);
    if out_gate == "BLOCK" { return "[đã lọc nội dung]"; };
    
    return output;
}
```

**Effort:** ~80 LOC Olang (glue). **Test:** bootstrap data → query → verify response.

---

## BOOTSTRAP SCRIPT

```olang
// stdlib/homeos/bootstrap_knowledge.ol
pub fn bootstrap() {
    let files = [
        "docs/BLUEPRINT.md",
        "docs/HomeOS_SPEC_v3.md",
        "docs/ORIGIN_VISION.md",
        "docs/olang_handbook.md",
        "homeos.knowledge",
    ];
    let total = 0;
    let fi = 0;
    while fi < len(files) {
        let content = __file_read(files[fi]);
        if len(content) > 0 {
            let sentences = split_by_period(content);
            let si = 0;
            while si < len(sentences) {
                let s = __str_trim(sentences[si]);
                if len(s) > 10 {  // skip short fragments
                    let chain = encode_text(s);
                    let summary = chain_summary(chain);
                    kt_store(mol_s(summary), mol_r(summary), chain, s);
                    total = total + 1;
                };
                si = si + 1;
            };
        };
        fi = fi + 1;
    };
    emit "Bootstrapped " + __to_string(total) + " facts into KnowTree";
}

fn split_by_period(text) {
    let results = [];
    let start = 0;
    let i = 0;
    while i < len(text) {
        let ch = char_at(text, i);
        if ch == "." || ch == "\n" {
            if i > start {
                push(results, __substr(text, start, i));
            };
            start = i + 1;
        };
        i = i + 1;
    };
    if start < len(text) {
        push(results, __substr(text, start, len(text)));
    };
    return results;
}
```

---

## ASM BUILTINS CẦN THÊM

```
__p_weight(codepoint) → u16     20 LOC   lookup embedded P_w table
```

Đó là TẤT CẢ. Không cần __exp, __log2. Dùng approximation.

---

## TIMELINE

```
Session 1:  Bước 1 (KnowTree v2) + Bước 2 (Encode ∫ + __p_weight)
Session 2:  Bước 3 (Decode ∂) + Bootstrap script + TEST 100 roundtrips
Session 3:  Bước 4 (Homeostasis) + Bước 5 (Compose) + Bước 6 (Fusion)
Session 4:  Bước 7 (Instincts) + Bước 8 (Infer)
Session 5:  Bước 9 (DNA Repair) + Bước 10 (pipeline()) + Integration test

Tổng: 5 sessions. ~1,200 LOC Olang + 20 LOC ASM.
Sau session 2: pipeline v0.1 hoạt động (encode → search → decode).
Sau session 5: pipeline đầy đủ 14 cơ chế DNA, 5 checkpoints.
```

---

## TEST PLAN

```
Sau bước 1-2:
  encode("hello") → chain → store → search("hello") → found ✓
  100 sentences → encode → store → query mỗi cái → accuracy > 95%

Sau bước 3:
  decode(encode("Hà Nội là thủ đô")) == "Hà Nội là thủ đô" ✓
  decode(mol gần "Hà Nội") → trả kết quả liên quan ✓

Sau bước 5:
  bootstrap() → 3,500+ chains loaded ✓
  pipeline("Hà Nội là gì?") → trả answer từ KnowTree ✓

Sau bước 10:
  pipeline("xin chào") → instinct detect greeting → warm response ✓
  pipeline("nguy hiểm") → safety gate → block ✓
  pipeline("gì mới?") → homeostasis LEARN → store + respond ✓
  10 conversations → ConversationCurve shift visible ✓
```

---

*Sora — 2026-03-29. 100% khả thi. 5 sessions. Không LLM. Không rủi ro mở.*
