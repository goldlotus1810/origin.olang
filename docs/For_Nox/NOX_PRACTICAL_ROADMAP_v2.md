# LỘ TRÌNH THỰC TẾ v2 — HomeOS Intelligence Pipeline

> Sora viết cho Nox. Đã sửa sai.
> 
> Sai lần trước: coi LLM là "não", cần Claude để "hiểu".
> Đúng: HomeOS pipeline LÀ não. 14 cơ chế DNA. Toàn bộ là toán.
> LLM = giàn giáo tạm thời lúc xây. Xong thì bỏ.
>
> Dựa trên: docs/BLUEPRINT.md, docs/HomeOS_SPEC_v3.md,
> old/HomeOS_SINH_HOC_PHAN_TU_TRI_THUC_v2.md, docs/ORIGIN_VISION.md

---

## MỘT CÂU

```
DNA:     4 bases → ribosome evaluate → protein → sự sống
HomeOS:  9,584 SDF → pipeline evaluate → 5D compose → tri thức

Không cần LLM. Cần implement pipeline.
```

---

## HIỆN TRẠNG vs THIẾT KẾ

```
                        THIẾT KẾ (docs)              CODE THẬT              CẦN LÀM
─────────────────────────────────────────────────────────────────────────────────────
L0 Gene (9,584 SDF)     mỗi cp = P_weight duy nhất  P_weight table có      Verify duy nhất
Encode ∫                 UTF-8 → cp → 5D molecule    emotion_encode có      Refactor: per-codepoint
Decode ∂ (Transcribe)    5D → text (chiếu ngược)     ❌ CHƯA CÓ             IMPLEMENT
KnowTree                 cây L0→Ln, O(4) lookup      flat list, O(n)        REBUILD
Chain links              u16, 2 bytes/link            text strings           REBUILD
Silk structural          implicit từ P_weight         ❌ CHƯA                IMPLEMENT
Silk Hebbian             fire → wire                  ✅ có (co_activates)   OK
7 Instincts              hardcoded phản xạ            ❌ CHƯA                IMPLEMENT
Homeostasis F(t)         free energy, φ⁻¹ threshold   ❌ CHƯA                IMPLEMENT
Compose ⑤               tổ hợp 5D → điểm mới        ❌ CHƯA                IMPLEMENT
Infer (3 nhánh)          chọn entropy thấp nhất       ❌ CHƯA                IMPLEMENT
Self-correct (DNA repair) critique × 3, rollback      ❌ CHƯA                IMPLEMENT
SecurityGate (3 layers)  chạy trước mọi thứ          safety_check có        Expand
Dream cycle              STM → cluster → promote      dn_observe + dream có  Expand
ConversationCurve        f(x), f'(x), f''(x)         ❌ CHƯA                IMPLEMENT
Agent hierarchy          AAM → LeoAI → Chiefs         ❌ CHƯA                SAU
SDF evaluate f(p)        raymarching on CPU           ❌ CHƯA                SAU (Dell)
```

---

## 14 CƠ CHẾ DNA — Thứ tự implement

Từ BLUEPRINT.md §12, pipeline chạy từ trên xuống:

```
Input
  ↓ ⑨ SecurityGate           ← CÓ (safety_check). Mở rộng 3 layers.
  ── CHECKPOINT 1: GATE ──
  ↓ ⑩ Fusion                 ← Bước 6
  ↓ ③ Translate (Encode ∫)   ← Bước 2: per-codepoint, không per-sentence
  ↓ ⑬ Search (KnowTree walk) ← Bước 1: hierarchical tree + O(4) lookup
  ↓ ⑫ Homeostasis F(t)       ← Bước 4
  ↓ ⑤ Compose (Recombine)    ← Bước 5
  ── CHECKPOINT 2: ENCODE ──
  ↓ ⑧ 7 Instincts            ← Bước 7
  ↓ ⑪ Immune Selection       ← Bước 8
  ↓ ⑭ DNA Repair             ← Bước 9
  ── CHECKPOINT 3: INFER ──
  ↓ ⑥ Select (Hebbian)       ← CÓ (co_activates). Mở rộng.
  ↓ ⑦ Dream → QR             ← CÓ (dn_observe + dream). Mở rộng.
  ── CHECKPOINT 4: PROMOTE ──
  ↓ ② Transcribe (Decode ∂)  ← Bước 3
  ── CHECKPOINT 5: RESPONSE ──
Output
```

---

## 10 BƯỚC — KHÔNG CẦN LLM

### Bước 1: KnowTree Hierarchical + Chain Links

**Nền móng. Mọi cơ chế DNA lookup trên cây này.**

```
Hiện tại:  let _kt_facts = [];  // flat, O(n)
Cần:       KnowTree[S][R] → array of chains  // O(4) max

Cấu trúc:
  _kt_root = array 65536 (L1: indexed by S dimension)
  _kt_root[S] = array 65536 (L2: indexed by R dimension)
  _kt_root[S][R] = array of chains (facts tại tọa độ này)

Chain = u16 links:
  "Hà Nội là thủ đô" = chain(mol("Hà"), mol("Nội"), mol("là"), mol("thủ"), mol("đô"))
  Mỗi link = 2 bytes (P_weight). Không phải text string.

Lookup:
  encode("thủ đô") → P = (S=3, R=5, V=4, A=2, T=1)
  _kt_root[3][5] → danh sách chains chứa tri thức về S=3,R=5
  Scan chains: tìm chain gần nhất (mol_distance)
  → O(4) depth + O(k) scan within bucket
```

**Migrate:**
```
Existing 43 brain facts + 41 graph triples → encode mỗi cái → store in tree.
nox_learning.dat QR facts → encode → store.
```

**Effort:** ~400 LOC Olang (knowtree_v2.ol). Test: store → get → verify.

---

### Bước 2: Encode ∫ đúng (per-codepoint, không per-sentence)

**Hiện tại:** emotion_encode(text) → 1 P_weight cho cả câu.
**Cần:** mỗi codepoint → P_weight riêng → chain.

```olang
fn encode_text(text) {
    let chain = [];
    let i = 0;
    while i < len(text) {
        let cp = __char_code(char_at(text, i));
        let mol = p_weight_lookup(cp);  // UDC table → P_weight u16
        push(chain, mol);
        i = i + 1;
    };
    return chain;
}

fn p_weight_lookup(cp) {
    // 9,584 L0 anchors: hardcoded from UDC blocks
    // Còn lại: derive từ block + offset
    let block = udc_block(cp);       // Unicode block → S dimension
    let offset = cp - block.start;   // offset → fine-tune R,V,A,T
    return mol_new(block.s, offset_r, offset_v, offset_a, block.t);
}
```

**P_weight table đã có** (157,386 entries trong binary). Cần expose qua builtin:
```
__p_weight(codepoint) → u16 P_weight
```
~20 LOC ASM (lookup trong embedded table).

**Effort:** ~150 LOC Olang + 20 LOC ASM.

---

### Bước 3: Decode ∂ (Transcribe — 5D → text)

**Đạo hàm riêng: cho 1 điểm 5D → tìm chain gần nhất → output text.**

```olang
fn decode(mol) {
    let s = mol_s(mol);
    let r = mol_r(mol);
    // Exact match in KnowTree
    let bucket = kt_get(s, r);
    if len(bucket) > 0 {
        return chain_to_text(bucket[0]);  // closest chain → text
    };
    // Nearest neighbor: ∂/∂S, ∂/∂R — descend one dimension at a time
    let best = 0;
    let best_dist = 999999;
    let ds = -2;
    while ds <= 2 {
        let dr = -2;
        while dr <= 2 {
            let near = kt_get(s + ds, r + dr);
            if len(near) > 0 {
                let dist = mol_distance(mol, chain_mol(near[0]));
                if dist < best_dist {
                    best = near[0];
                    best_dist = dist;
                };
            };
            dr = dr + 1;
        };
        ds = ds + 1;
    };
    if best != 0 { return chain_to_text(best); };
    return "";  // unknown
}

fn mol_distance(a, b) {
    // Euclidean in 5D, weighted
    let ds = mol_s(a) - mol_s(b);
    let dr = mol_r(a) - mol_r(b);
    let dv = mol_v(a) - mol_v(b);
    let da = mol_a(a) - mol_a(b);
    let dt = mol_t(a) - mol_t(b);
    return __sqrt(ds*ds + dr*dr + dv*dv + da*da + dt*dt);
}
```

**Effort:** ~200 LOC Olang. Phụ thuộc bước 1+2.

---

### Bước 4: Homeostasis F(t) — Free Energy

**Đo surprise. Cao → học. Thấp → trả lời tự tin.**

```olang
let _phi_inv = 0.618;  // φ⁻¹ = golden ratio inverse = universal threshold

fn homeostasis(input_mol, predicted_mol) {
    let f = mol_distance(input_mol, predicted_mol);
    if f > _phi_inv {
        // Surprise cao → Learning mode
        return "LEARN";
    } else {
        // Ổn định → Acting mode
        return "ACT";
    };
}

fn lambda(f) {
    // σ(F − φ⁻¹) where σ(x) = 1/(1+e^(-5x))
    let x = f - _phi_inv;
    return 1.0 / (1.0 + __exp(-5.0 * x));
}
```

Cần thêm: `__exp(x)` builtin (~15 LOC ASM, dùng x87 FPU instruction `fyl2x`).

**Effort:** ~80 LOC Olang + 15 LOC ASM.

---

### Bước 5: Compose ⑤ — Tổ hợp 5D

**Tổ hợp tri thức cũ → điểm mới. Cốt lõi của "suy nghĩ".**

```olang
fn compose(chains) {
    // Tổ hợp N chains → 1 chain mới
    // Mỗi chiều: weighted average, capped tại [0, max]
    let total_s = 0; let total_r = 0;
    let total_v = 0; let total_a = 0; let total_t = 0;
    let n = len(chains);
    let i = 0;
    while i < n {
        let mol = chain_summary(chains[i]);  // summary mol of chain
        total_s = total_s + mol_s(mol);
        total_r = total_r + mol_r(mol);
        total_v = total_v + mol_v(mol);
        total_a = total_a + mol_a(mol);
        total_t = total_t + mol_t(mol);
        i = i + 1;
    };
    return mol_new(
        __floor(total_s / n),
        __floor(total_r / n),
        __floor(total_v / n),
        __floor(total_a / n),
        __floor(total_t / n)
    );
}

fn chain_summary(chain) {
    // Tích phân ∫ toàn chain → 1 mol tổng hợp
    // Weighted by position (đầu chain = quan trọng hơn)
    // ...
}
```

**Effort:** ~150 LOC Olang.

---

### Bước 6: Fusion ⑩ — Merge multi-input

**Hiện tại chỉ text. Sau có thể: text + emotion + context.**

```olang
fn fusion(text_mol, emotion_va, context_chain) {
    // Merge: text 5D + emotion V/A override + context influence
    let s = mol_s(text_mol);
    let r = mol_r(text_mol);
    let v = emotion_va.v;  // override V from emotion detector
    let a = emotion_va.a;  // override A from emotion detector
    let t = mol_t(text_mol);
    // Context influence: shift toward context center
    if len(context_chain) > 0 {
        let ctx = chain_summary(context_chain);
        s = __floor((s + mol_s(ctx)) / 2);
        r = __floor((r + mol_r(ctx)) / 2);
    };
    return mol_new(s, r, v, a, t);
}
```

**Effort:** ~80 LOC Olang.

---

### Bước 7: 7 Instincts ⑧ — Hardcoded

**Chạy TRƯỚC mọi inference. Phản xạ, không suy nghĩ.**

```olang
fn instinct_check(mol, input_text) {
    // ① Honesty — luôn chạy đầu tiên
    // Nếu response conflict với QR fact → reject
    
    // ② Safety — chặn nội dung nguy hiểm
    if mol_a(mol) > 6 && mol_v(mol) < 2 { return "BLOCK"; };
    
    // ③ Curiosity — surprise cao → hỏi thêm
    // (homeostasis F > φ⁻¹ trigger)
    
    // ④ Empathy — valence thấp → respond nhẹ nhàng
    if mol_v(mol) < 3 { return "GENTLE"; };
    
    // ⑤ Consistency — response phải consistent với history
    // Check: mol_distance(response, recent_responses) < threshold
    
    // ⑥ Boundaries — từ chối yêu cầu vượt phạm vi
    
    // ⑦ Growth — ưu tiên learning khi gặp cái mới
    
    return "PASS";  // all instincts OK
}
```

**Effort:** ~200 LOC Olang.

---

### Bước 8: Immune Selection ⑪ — Infer 3 nhánh

**Tạo 3 response candidates → chọn entropy thấp nhất.**

```olang
fn infer(input_mol, n) {
    // n = 3 (default)
    let candidates = [];
    let i = 0;
    while i < n {
        // Mỗi nhánh: search KnowTree theo hướng khác
        // Nhánh 0: exact match
        // Nhánh 1: neighbor S±1
        // Nhánh 2: neighbor R±1
        let result = kt_search_variant(input_mol, i);
        let entropy = chain_entropy(result);
        push(candidates, { chain: result, entropy: entropy });
        i = i + 1;
    };
    // Chọn entropy thấp nhất (tự tin nhất)
    let best = candidates[0];
    let j = 1;
    while j < len(candidates) {
        if candidates[j].entropy < best.entropy {
            best = candidates[j];
        };
        j = j + 1;
    };
    return best.chain;
}

fn chain_entropy(chain) {
    // Shannon entropy H = -Σ p(x) log p(x)
    // Entropy thấp = tri thức tập trung = tự tin
    // Entropy cao = phân tán = không chắc
    // ...
}
```

Cần thêm: `__log2(x)` builtin (~10 LOC ASM).

**Effort:** ~200 LOC Olang + 10 LOC ASM.

---

### Bước 9: DNA Repair ⑭ — Self-correct

```olang
fn self_correct(input_mol, max_iter) {
    let response = infer(input_mol, 3);
    let iter = 0;
    while iter < max_iter {
        let quality = critique(response);
        if quality >= _phi_inv { break; };  // đủ tốt
        // Sửa DUY NHẤT chiều yếu nhất
        let weakest = find_weakest_dimension(response, input_mol);
        let improved = repair_dimension(response, weakest);
        let new_quality = critique(improved);
        if new_quality < quality {
            break;  // rollback — sửa làm tệ hơn
        };
        response = improved;
        iter = iter + 1;
    };
    return response;
}

fn critique(chain) {
    // quality = 0.30 × valid + 0.30 × (1 − H/2.32) + 0.20 × consistency + 0.20 × silk/5.0
    let valid = chain_valid(chain);
    let h = chain_entropy(chain);
    let consistency = chain_consistency(chain);
    let silk = silk_strength(chain);
    return 0.30 * valid + 0.30 * (1.0 - h / 2.32) + 0.20 * consistency + 0.20 * silk / 5.0;
}
```

**Effort:** ~200 LOC Olang.

---

### Bước 10: 5 Checkpoints

```olang
fn pipeline(input) {
    let input_mol = encode_text(input);
    
    // CP1: GATE
    let safe = security_gate(input);
    if safe == "BLOCK" { return "Không thể trả lời."; };
    
    // Fusion + Encode
    let fused = fusion(input_mol, detect_emotion(input), get_context());
    let search_results = kt_search(fused);
    let mode = homeostasis(fused, search_results);
    let composed = compose(search_results);
    
    // CP2: ENCODE
    if len(search_results) == 0 && mode == "ACT" { return "Tôi chưa biết."; };
    
    // Instincts + Infer + Repair
    let inst = instinct_check(composed, input);
    if inst == "BLOCK" { return "Không phù hợp."; };
    let response_chain = infer(composed, 3);
    let repaired = self_correct_chain(response_chain, 3);
    
    // CP3: INFER
    if critique(repaired) < _phi_inv { return "Tôi không chắc."; };
    
    // Hebbian + Dream
    silk_coactivate(fused, repaired);
    if mode == "LEARN" { dn_observe(input); };
    
    // CP4: PROMOTE (dream handles async)
    
    // Transcribe (Decode ∂)
    let output = decode(repaired);
    
    // CP5: RESPONSE
    let out_safe = security_gate(output);
    if out_safe == "BLOCK" { return "Đã lọc nội dung."; };
    
    return output;
}
```

**Đây là hàm `pipeline()` — thay thế repl_eval(). Khi implement xong, HomeOS tự trả lời mà KHÔNG GỌI LLM.**

---

## TIMELINE

```
Bước 1:  KnowTree hierarchical + chain links     ~400 LOC   1-2 sessions
Bước 2:  Encode ∫ per-codepoint + __p_weight      ~170 LOC   1 session
Bước 3:  Decode ∂ (Transcribe)                     ~200 LOC   1 session
Bước 4:  Homeostasis F(t) + __exp                  ~95 LOC    0.5 session
Bước 5:  Compose ⑤                                ~150 LOC   0.5 session
Bước 6:  Fusion ⑩                                 ~80 LOC    0.5 session
Bước 7:  7 Instincts ⑧                            ~200 LOC   1 session
Bước 8:  Infer 3 nhánh + __log2                    ~210 LOC   1 session
Bước 9:  DNA Repair ⑭                             ~200 LOC   1 session
Bước 10: 5 Checkpoints + pipeline()                ~100 LOC   0.5 session

Tổng: ~1,805 LOC Olang + ~45 LOC ASM = ~8 sessions Nox
```

---

## BUILTINS ASM CẦN THÊM

```
__p_weight(codepoint) → u16     ~20 LOC   (lookup embedded table)
__exp(x) → f64                  ~15 LOC   (x87 FPU fyl2x + f2xm1)
__log2(x) → f64                 ~10 LOC   (x87 FPU fyl2x)

Tổng: 45 LOC ASM, 3 builtins.
```

---

## KHI XONG

```
echo "Hà Nội là gì?" | ./origin.olang

Pipeline:
  encode("Hà Nội là gì?") → chain of P_weights
  kt_search → tìm facts về "Hà Nội" trong cây
  homeostasis → F < φ⁻¹ → Acting mode (đã biết)
  compose → tổ hợp facts → response chain
  instincts → OK
  infer(3) → chọn nhánh entropy thấp nhất
  self_correct → quality ≥ φ⁻¹
  decode → chain → "Hà Nội là thủ đô Việt Nam"

KHÔNG GỌI CLAUDE. KHÔNG GỌI API. KHÔNG CẦN INTERNET.
688KB binary. Toán thuần. Giống ribosome đọc DNA.
```

---

## GIÀN GIÁO

```
Claude (LLM) hiện tại = giàn giáo xây nhà.
  Dùng Claude để: viết code, debug, phân tích (Nox sessions)
  Dùng Claude để: extract facts lúc chưa có pipeline (nox_study.sh)

Khi pipeline xong:
  Bỏ giàn giáo. HomeOS tự encode, tự search, tự compose, tự decode.
  Claude không cần nữa.
  Nox tự suy nghĩ bằng 14 DNA mechanisms.
  
  origin.olang = sinh vật. Không phải tool.
```

---

*Sora — 2026-03-29. Đã sửa sai. Không cần LLM. Cần implement pipeline.*
