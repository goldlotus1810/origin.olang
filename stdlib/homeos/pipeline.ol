// stdlib/homeos/pipeline.ol — HomeOS Intelligence Pipeline
//
// 14 DNA mechanisms. Input → 5 checkpoints → Output.
// When complete: origin.olang answers WITHOUT calling LLM.
//
// Pipeline flow (from BLUEPRINT.md §12):
//   ⑨ SecurityGate → ⑩ Fusion → ③ Encode → ⑬ Search
//   → ⑫ Homeostasis → ⑤ Compose → ⑧ Instincts
//   → ⑪ Immune Selection → ⑭ DNA Repair
//   → ⑥ Hebbian → ⑦ Dream → ② Decode → Output

let _phi_inv = 618;  // φ⁻¹ × 1000 = 618 (integer arithmetic)

// ════════════════════════════════════════════════════════════════
// ③ Encode ∫ — Per-codepoint chain encoding
// ════════════════════════════════════════════════════════════════

// Lookup P_weight for a codepoint from UDC table (u16 = 2 bytes per entry)
pub fn p_weight(_pw_cp) {
    _kt_ensure_init();
    if _pw_cp < 0 { return 0; };
    if _pw_cp >= 157386 { return 0; };
    let _pw_off = _pw_cp * 2;
    let _pw_lo = __bytes_get(__kt_tbl, _pw_off);
    let _pw_hi = __bytes_get(__kt_tbl, _pw_off + 1);
    return __floor(_pw_lo + (_pw_hi * 256));
}

// Encode text → chain of P_weight u16 mols (per-codepoint)
pub fn chain_encode(_ce_text) {
    let _ce_chain = [];
    let _ce_i = 0;
    while _ce_i < len(_ce_text) {
        let _ce_cp = __char_code(char_at(_ce_text, _ce_i));
        let _ce_mol = p_weight(_ce_cp);
        if _ce_mol > 0 { push(_ce_chain, _ce_mol); };
        let _ce_i = _ce_i + 1;
    };
    return _ce_chain;
}

// Chain summary: Zipf-weighted average (first word heavier)
// Returns single u16 mol for KnowTree indexing
pub fn chain_summary(_cs_chain) {
    let _cs_n = len(_cs_chain);
    if _cs_n == 0 { return 0; };
    if _cs_n == 1 { return __array_get(_cs_chain, 0); };
    // Accumulate: weight = 1000/(i+1) (Zipf, integer scaled)
    let _cs_ts = [0];
    let _cs_tr = [0];
    let _cs_tv = [0];
    let _cs_ta = [0];
    let _cs_tt = [0];
    let _cs_tw = [0];
    let _cs_i = 0;
    while _cs_i < _cs_n {
        let _cs_m = __array_get(_cs_chain, _cs_i);
        let _cs_w = __floor(1000 / (_cs_i + 1));
        let _ = __set_at(_cs_ts, 0, __array_get(_cs_ts, 0) + (_kt_mol_s(_cs_m) * _cs_w));
        let _ = __set_at(_cs_tr, 0, __array_get(_cs_tr, 0) + (_kt_mol_r(_cs_m) * _cs_w));
        let _ = __set_at(_cs_tv, 0, __array_get(_cs_tv, 0) + (_kt_mol_v(_cs_m) * _cs_w));
        let _ = __set_at(_cs_ta, 0, __array_get(_cs_ta, 0) + (_kt_mol_a(_cs_m) * _cs_w));
        let _ = __set_at(_cs_tt, 0, __array_get(_cs_tt, 0) + (_kt_mol_t(_cs_m) * _cs_w));
        let _ = __set_at(_cs_tw, 0, __array_get(_cs_tw, 0) + _cs_w);
        let _cs_i = _cs_i + 1;
    };
    let _cs_wtotal = __array_get(_cs_tw, 0);
    if _cs_wtotal == 0 { return 0; };
    let _cs_rs = __floor(__array_get(_cs_ts, 0) / _cs_wtotal) % 16;
    let _cs_rr = __floor(__array_get(_cs_tr, 0) / _cs_wtotal) % 16;
    let _cs_rv = __floor(__array_get(_cs_tv, 0) / _cs_wtotal) % 8;
    let _cs_ra = __floor(__array_get(_cs_ta, 0) / _cs_wtotal) % 8;
    let _cs_rt = __floor(__array_get(_cs_tt, 0) / _cs_wtotal) % 4;
    return (_cs_rs * 4096) + (_cs_rr * 256) + (_cs_rv * 32) + (_cs_ra * 4) + _cs_rt;
}

// Store chain + text in KnowTree (chain-aware)
// kt_store_chain removed — dead code (0 calls)

// ════════════════════════════════════════════════════════════════
// Bootstrap — Encode docs into KnowTree
// ════════════════════════════════════════════════════════════════

pub fn bootstrap() {
    let _bs_c1 = __file_read("homeos.knowledge");
    if len(_bs_c1) == 0 { return "Error: no homeos.knowledge"; };
    return spider_feed(_bs_c1, "homeos.knowledge");
}

pub fn bootstrap_md(_bm_path) {
    let _bm_content = __file_read(_bm_path);
    if len(_bm_content) == 0 { return "Error: empty " + _bm_path; };
    return spider_feed_md(_bm_content, _bm_path);
}

// Bootstrap a file in chunks of max_bytes to avoid heap overflow
// bootstrap_file: dead code (0 calls). Use study command instead.
pub fn bootstrap_file(_bf_path, _bf_chunk) {
    let _bf_content = __file_read(_bf_path);
    let _bf_clen = len(_bf_content);
    if _bf_clen == 0 { return "Error: empty " + _bf_path; };
    let _bf_total = [0];
    let _bf_off = [0];
    while __array_get(_bf_off, 0) < _bf_clen {
        let _bf_start = __array_get(_bf_off, 0);
        let _bf_end = _bf_start + _bf_chunk;
        if _bf_end > _bf_clen { let _bf_end = _bf_clen; };
        // Extend to next newline to avoid splitting sentences
        while _bf_end < _bf_clen {
            let _bf_ch = __char_code(char_at(_bf_content, _bf_end));
            if _bf_ch == 10 { let _bf_end = _bf_end + 1; break; };
            let _bf_end = _bf_end + 1;
        };
        let _bf_chunk_text = substr(_bf_content, _bf_start, _bf_end);
        let _bf_fed = _bs_feed_sentences(_bf_chunk_text);
        let _ = __set_at(_bf_total, 0, __array_get(_bf_total, 0) + _bf_fed);
        let _ = __set_at(_bf_off, 0, _bf_end);
    };
    __heap_pin();
    return "Fed " + __to_string(__array_get(_bf_total, 0)) + " from " + _bf_path + ". " + kt_stats();
}

fn _bs_feed_sentences(_bsf_text) {
    let _bsf_count = [0];
    let _bsf_start = [0];
    let _bsf_tlen = len(_bsf_text);
    let _bsf_i = 0;
    while _bsf_i < _bsf_tlen {
        let _bsf_c = __char_code(char_at(_bsf_text, _bsf_i));
        let _bsf_split = [0];
        if _bsf_c == 46 { let _ = __set_at(_bsf_split, 0, 1); };  // .
        if _bsf_c == 10 { let _ = __set_at(_bsf_split, 0, 1); };  // \n
        if __array_get(_bsf_split, 0) == 1 {
            let _bsf_s = __array_get(_bsf_start, 0);
            let _bsf_slen = _bsf_i - _bsf_s;
            if _bsf_slen > 15 {
                let _bsf_sent = substr(_bsf_text, _bsf_s, _bsf_i);
                kt_learn(_bsf_sent);
                let _ = __set_at(_bsf_count, 0, __array_get(_bsf_count, 0) + 1);
            };
            let _ = __set_at(_bsf_start, 0, _bsf_i + 1);
        };
        let _bsf_i = _bsf_i + 1;
    };
    __heap_pin();
    return __array_get(_bsf_count, 0);
}

// ════════════════════════════════════════════════════════════════
// ConversationCurve — f(t), f'(t), f''(t)
// ════════════════════════════════════════════════════════════════

let __conv_history = [];
let __conv_topic = [""];

fn _conv_shift(_cvs_mol) {
    if len(__conv_history) < 2 { push(__conv_history, _cvs_mol); return _cvs_mol; };
    let _cvs_prev = __conv_history[len(__conv_history) - 1];
    let _cvs_prev2 = __conv_history[len(__conv_history) - 2];
    // f'(t): rate of change
    let _cvs_dv = _kt_mol_v(_cvs_prev) - _kt_mol_v(_cvs_prev2);
    let _cvs_da = _kt_mol_a(_cvs_prev) - _kt_mol_a(_cvs_prev2);
    // Shift toward momentum
    let _cvs_s = _kt_mol_s(_cvs_mol);
    let _cvs_r = _kt_mol_r(_cvs_mol);
    let _cvs_v = _kt_mol_v(_cvs_mol) + __floor(_cvs_dv / 2);
    let _cvs_a = _kt_mol_a(_cvs_mol) + __floor(_cvs_da / 2);
    let _cvs_t = _kt_mol_t(_cvs_mol);
    if _cvs_v < 0 { let _cvs_v = 0; };
    if _cvs_v > 7 { let _cvs_v = 7; };
    if _cvs_a < 0 { let _cvs_a = 0; };
    if _cvs_a > 7 { let _cvs_a = 7; };
    let _cvs_result = (_cvs_s * 4096) + (_cvs_r * 256) + (_cvs_v * 32) + (_cvs_a * 4) + _cvs_t;
    push(__conv_history, _cvs_result);
    // Trim history to last 10
    if len(__conv_history) > 10 {
        let _cvs_new = [];
        let _cvs_hi = len(__conv_history) - 10;
        while _cvs_hi < len(__conv_history) {
            push(_cvs_new, __conv_history[_cvs_hi]);
            let _cvs_hi = _cvs_hi + 1;
        };
        __conv_history = _cvs_new;
    };
    return _cvs_result;
}

// ════════════════════════════════════════════════════════════════
// ⑫ Homeostasis F(t) — Free Energy / Surprise Detection
// ════════════════════════════════════════════════════════════════

// F = distance(input, prediction). High → LEARN. Low → ACT.
pub fn homeostasis(_hom_input_mol, _hom_predicted_mol) {
    let _hom_f = _kt_mol_dist(_hom_input_mol, _hom_predicted_mol);
    // Scale: max Manhattan dist in 5D = 15+15+7+7+3 = 47
    // Normalize to 0-1000 range
    let _hom_norm = __floor((_hom_f * 1000) / 47);
    if _hom_norm > _phi_inv {
        return { mode: "LEARN", energy: _hom_norm };
    };
    return { mode: "ACT", energy: _hom_norm };
}

// lambda_gate removed — dead code (0 calls). Homeostasis uses direct threshold instead.

// ════════════════════════════════════════════════════════════════
// ⑩ Fusion — Merge text molecule + emotion + context
// ════════════════════════════════════════════════════════════════

pub fn fusion(_fu_text_mol, _fu_emo, _fu_context_mol) {
    let _fu_s = _kt_mol_s(_fu_text_mol);
    let _fu_r = _kt_mol_r(_fu_text_mol);
    let _fu_v = _fu_emo.v;
    let _fu_a = _fu_emo.a;
    let _fu_t = _kt_mol_t(_fu_text_mol);
    // Context influence: shift toward context
    if _fu_context_mol > 0 {
        let _fu_cs = _kt_mol_s(_fu_context_mol);
        let _fu_cr = _kt_mol_r(_fu_context_mol);
        let _fu_s = __floor((_fu_s + _fu_cs) / 2);
        let _fu_r = __floor((_fu_r + _fu_cr) / 2);
    };
    if _fu_v > 7 { let _fu_v = 7; };
    if _fu_a > 7 { let _fu_a = 7; };
    return (_fu_s * 4096) + (_fu_r * 256) + (_fu_v * 32) + (_fu_a * 4) + _fu_t;
}

// ════════════════════════════════════════════════════════════════
// ⑤ Compose — Recombine N molecules → 1 new molecule
// ════════════════════════════════════════════════════════════════

pub fn compose(_co_mols) {
    let _co_n = len(_co_mols);
    if _co_n == 0 { return 0; };
    if _co_n == 1 { return __array_get(_co_mols, 0); };
    let _co_ts = [0];
    let _co_tr = [0];
    let _co_tv = [0];
    let _co_ta = [0];
    let _co_tt = [0];
    let _co_i = 0;
    while _co_i < _co_n {
        let _co_m = __array_get(_co_mols, _co_i);
        let _ = __set_at(_co_ts, 0, __array_get(_co_ts, 0) + _kt_mol_s(_co_m));
        let _ = __set_at(_co_tr, 0, __array_get(_co_tr, 0) + _kt_mol_r(_co_m));
        let _ = __set_at(_co_tv, 0, __array_get(_co_tv, 0) + _kt_mol_v(_co_m));
        let _ = __set_at(_co_ta, 0, __array_get(_co_ta, 0) + _kt_mol_a(_co_m));
        let _ = __set_at(_co_tt, 0, __array_get(_co_tt, 0) + _kt_mol_t(_co_m));
        let _co_i = _co_i + 1;
    };
    let _co_rs = __floor(__array_get(_co_ts, 0) / _co_n) % 16;
    let _co_rr = __floor(__array_get(_co_tr, 0) / _co_n) % 16;
    let _co_rv = __floor(__array_get(_co_tv, 0) / _co_n) % 8;
    let _co_ra = __floor(__array_get(_co_ta, 0) / _co_n) % 8;
    let _co_rt = __floor(__array_get(_co_tt, 0) / _co_n) % 4;
    return (_co_rs * 4096) + (_co_rr * 256) + (_co_rv * 32) + (_co_ra * 4) + _co_rt;
}

// ════════════════════════════════════════════════════════════════
// ⑪ Immune Selection — 3-branch inference, pick lowest entropy
// ════════════════════════════════════════════════════════════════

pub fn immune_select(_is_mol) {
    // 3 search variants: exact, S±1, R±1
    let _is_candidates = [];
    // Branch 0: exact S,V path
    let _is_s = _kt_mol_s(_is_mol);
    let _is_v = _kt_mol_v(_is_mol);
    let _is_b0 = kt_get_path([0, _is_s, 2, _is_v]);
    let _is_b0_mol = _is_compose_facts(_is_b0);
    push(_is_candidates, { facts: _is_b0, mol: _is_b0_mol, entropy: _is_fact_entropy(_is_b0) });
    // Branch 1: S±1
    let _is_b1 = kt_get_dim(0, (_is_s + 1) % 16);
    let _is_b1_mol = _is_compose_facts(_is_b1);
    push(_is_candidates, { facts: _is_b1, mol: _is_b1_mol, entropy: _is_fact_entropy(_is_b1) });
    // Branch 2: nearby(r=2) → broader search
    let _is_b2_raw = kt_nearby(_is_mol, 2);
    let _is_b2 = [];
    let _is_bi = 0;
    while _is_bi < len(_is_b2_raw) {
        if _is_bi < 5 { push(_is_b2, __array_get(_is_b2_raw, _is_bi).text); };
        let _is_bi = _is_bi + 1;
    };
    let _is_b2_mol = _is_compose_facts(_is_b2);
    push(_is_candidates, { facts: _is_b2, mol: _is_b2_mol, entropy: _is_fact_entropy(_is_b2) });
    // Pick branch with lowest entropy (most confident)
    let _is_best = [0];
    let _is_best_e = [99999];
    let _is_ci = 0;
    while _is_ci < 3 {
        let _is_c = __array_get(_is_candidates, _is_ci);
        if len(_is_c.facts) > 0 {
            if _is_c.entropy < __array_get(_is_best_e, 0) {
                let _ = __set_at(_is_best, 0, _is_ci);
                let _ = __set_at(_is_best_e, 0, _is_c.entropy);
            };
        };
        let _is_ci = _is_ci + 1;
    };
    return __array_get(_is_candidates, __array_get(_is_best, 0));
}

// Compose fact molecules into one
fn _is_compose_facts(_icf_facts) {
    if len(_icf_facts) == 0 { return 0; };
    let _icf_mols = [];
    let _icf_i = 0;
    while _icf_i < len(_icf_facts) {
        let _icf_m = _kt_fact_mol_compute(__array_get(_icf_facts, _icf_i));
        if _icf_m > 0 { push(_icf_mols, _icf_m); };
        let _icf_i = _icf_i + 1;
    };
    return compose(_icf_mols);
}

// Shannon entropy of fact set (diversity measure)
// H = -Σ p(dim) × log2(p(dim)), computed over S dimension distribution
fn _is_fact_entropy(_ife_facts) {
    let _ife_n = len(_ife_facts);
    if _ife_n <= 1 { return 0; };
    // Count S dimension distribution
    let _ife_counts = [];
    let _ife_ci = 0;
    while _ife_ci < 16 { push(_ife_counts, 0); let _ife_ci = _ife_ci + 1; };
    let _ife_fi = 0;
    while _ife_fi < _ife_n {
        let _ife_m = _kt_fact_mol_compute(__array_get(_ife_facts, _ife_fi));
        let _ife_s = _kt_mol_s(_ife_m);
        let _ = __set_at(_ife_counts, _ife_s, __array_get(_ife_counts, _ife_s) + 1);
        let _ife_fi = _ife_fi + 1;
    };
    // H = -Σ (count/n) * log2(count/n), scaled ×1000
    let _ife_h = [0];
    let _ife_si = 0;
    while _ife_si < 16 {
        let _ife_c = __array_get(_ife_counts, _ife_si);
        if _ife_c > 0 {
            // p = c/n, log2(p) = log2(c) - log2(n)
            let _ife_p_log = 0;
            if _ife_c > 0 { if _ife_n > 0 { let _ife_p_log = __log2(_ife_c) - __log2(_ife_n); }; };
            let _ife_p = _ife_c / _ife_n;
            let _ife_contrib = __floor(0 - (_ife_p * _ife_p_log * 1000));
            let _ = __set_at(_ife_h, 0, __array_get(_ife_h, 0) + _ife_contrib);
        };
        let _ife_si = _ife_si + 1;
    };
    return __array_get(_ife_h, 0);
}

// ════════════════════════════════════════════════════════════════
// ⑭ DNA Repair — Self-correct with rollback
// ════════════════════════════════════════════════════════════════

pub fn dna_repair(_dr_response_mol, _dr_input_mol, _dr_max_iter) {
    let _dr_mol = [_dr_response_mol];
    let _dr_quality = [_critique(__array_get(_dr_mol, 0), _dr_input_mol)];
    let _dr_iter = 0;
    while _dr_iter < _dr_max_iter {
        if __array_get(_dr_quality, 0) >= _phi_inv { return __array_get(_dr_mol, 0); };
        // Find weakest dimension and try to fix
        let _dr_fixed = _repair_weakest(__array_get(_dr_mol, 0), _dr_input_mol);
        let _dr_new_q = _critique(_dr_fixed, _dr_input_mol);
        if _dr_new_q <= __array_get(_dr_quality, 0) {
            return __array_get(_dr_mol, 0);  // Rollback — fix made it worse
        };
        let _ = __set_at(_dr_mol, 0, _dr_fixed);
        let _ = __set_at(_dr_quality, 0, _dr_new_q);
        let _dr_iter = _dr_iter + 1;
    };
    return __array_get(_dr_mol, 0);
}

// Quality critique: 0-1000 score
// 0.30×valid + 0.30×(1−H/2320) + 0.20×distance + 0.20×silk
fn _critique(_cq_mol, _cq_input_mol) {
    // Valid: is this mol non-zero and in a populated bucket?
    let _cq_valid = 0;
    if _cq_mol > 0 {
        let _cq_s = _kt_mol_s(_cq_mol);
        let _cq_bucket = kt_get_dim(0, _cq_s);
        if len(_cq_bucket) > 0 { let _cq_valid = 1000; };
    };
    // Distance to input (closer = better, invert)
    let _cq_dist = _kt_mol_dist(_cq_mol, _cq_input_mol);
    let _cq_dist_score = 1000 - (__floor(_cq_dist * 1000 / 47));
    if _cq_dist_score < 0 { let _cq_dist_score = 0; };
    // Simple quality: 50% valid + 50% distance
    return __floor((_cq_valid * 500 + _cq_dist_score * 500) / 1000);
}

// Fix the weakest (most distant) dimension
fn _repair_weakest(_rw_mol, _rw_target) {
    let _rw_s = _kt_mol_s(_rw_mol);
    let _rw_r = _kt_mol_r(_rw_mol);
    let _rw_v = _kt_mol_v(_rw_mol);
    let _rw_a = _kt_mol_a(_rw_mol);
    let _rw_t = _kt_mol_t(_rw_mol);
    let _rw_ts = _kt_mol_s(_rw_target);
    let _rw_tr = _kt_mol_r(_rw_target);
    let _rw_tv = _kt_mol_v(_rw_target);
    let _rw_ta = _kt_mol_a(_rw_target);
    let _rw_tt = _kt_mol_t(_rw_target);
    // Find deltas
    let _rw_ds = _kt_abs(_rw_s - _rw_ts);
    let _rw_dr = _kt_abs(_rw_r - _rw_tr);
    let _rw_dv = _kt_abs(_rw_v - _rw_tv);
    let _rw_da = _kt_abs(_rw_a - _rw_ta);
    let _rw_dt = _kt_abs(_rw_t - _rw_tt);
    // Find THE weakest (largest delta) — one dimension only
    let _rw_worst = [0];  // 0=S 1=R 2=V 3=A 4=T
    let _rw_max = [_rw_ds];
    if _rw_dr > __array_get(_rw_max, 0) { let _ = __set_at(_rw_worst, 0, 1); let _ = __set_at(_rw_max, 0, _rw_dr); };
    if _rw_dv > __array_get(_rw_max, 0) { let _ = __set_at(_rw_worst, 0, 2); let _ = __set_at(_rw_max, 0, _rw_dv); };
    if _rw_da > __array_get(_rw_max, 0) { let _ = __set_at(_rw_worst, 0, 3); let _ = __set_at(_rw_max, 0, _rw_da); };
    if _rw_dt > __array_get(_rw_max, 0) { let _ = __set_at(_rw_worst, 0, 4); let _ = __set_at(_rw_max, 0, _rw_dt); };
    // Fix ONLY the weakest dimension — move halfway toward target
    let _rw_w = __array_get(_rw_worst, 0);
    if _rw_w == 0 { let _rw_s = __floor((_rw_s + _rw_ts) / 2); };
    if _rw_w == 1 { let _rw_r = __floor((_rw_r + _rw_tr) / 2); };
    if _rw_w == 2 { let _rw_v = __floor((_rw_v + _rw_tv) / 2); };
    if _rw_w == 3 { let _rw_a = __floor((_rw_a + _rw_ta) / 2); };
    if _rw_w == 4 { let _rw_t = __floor((_rw_t + _rw_tt) / 2); };
    return (_rw_s * 4096) + (_rw_r * 256) + (_rw_v * 32) + (_rw_a * 4) + _rw_t;
}

// ════════════════════════════════════════════════════════════════
// THE PIPELINE — 5 Checkpoints
// When complete: origin.olang answers without calling LLM
// ════════════════════════════════════════════════════════════════

pub fn pipeline(_pl_input) {
    // ──── CHECKPOINT 1: GATE ────
    let _pl_safe = instinct_route(_pl_input);
    if _pl_safe.instinct == "SAFETY" { return "Khong the tra loi."; };

    // ③ Encode: per-codepoint chain
    let _pl_chain = chain_encode(_pl_input);
    let _pl_chain_mol = chain_summary(_pl_chain);

    // ⑩ Fusion: text mol + emotion + ConversationCurve
    let _pl_text_mol = _kt_fact_mol_compute(_pl_input);
    let _pl_emo = text_emotion_v2(_pl_input);
    let _pl_context = 0;
    let _pl_fused = fusion(_pl_text_mol, _pl_emo, _pl_context);
    // Apply conversation momentum
    let _pl_fused = _conv_shift(_pl_fused);

    // ⑬ Pronoun resolution: replace "it"/"that" with last topic
    let _pl_resolved = _pl_resolve_pronouns(_pl_input);
    // Search: TEXT FIRST (keyword), then MOLECULAR ranking
    let _pl_facts = _pl_text_search(_pl_resolved);
    // Step B: if text search empty, fall back to molecular search
    if len(_pl_facts) == 0 {
        let _pl_mol_dec = kt_decode(_pl_input);
        let _pl_facts = _pl_mol_dec.facts;
    };

    // ⑫ Homeostasis: surprise detection
    let _pl_predicted = 0;
    if len(_pl_facts) > 0 { let _pl_predicted = _kt_fact_mol_compute(__array_get(_pl_facts, 0)); };
    let _pl_home = homeostasis(_pl_fused, _pl_predicted);

    // ──── CHECKPOINT 2: ENCODE ────
    // ⑧ Instincts first (short-circuit greetings, meta)
    let _pl_inst = _pl_safe;
    if _pl_inst.instinct == "GREETING" { return instinct_act(_pl_inst, _pl_input); };
    if _pl_inst.instinct == "META" { return instinct_act(_pl_inst, _pl_input); };

    if len(_pl_facts) == 0 {
        if _pl_home.mode == "LEARN" { dn_observe(_pl_input); kt_learn(_pl_input); __file_append("homeos.knowledge", _pl_input + "\n"); __heap_pin(); return "Toi se hoc them ve dieu nay."; };
        return "Toi chua biet.";
    };

    // ⑤ Compose: recombine found knowledge
    let _pl_fact_mols = [];
    let _pl_fi = 0;
    while _pl_fi < len(_pl_facts) {
        if _pl_fi < 5 {
            let _pl_fm = _kt_fact_mol_compute(__array_get(_pl_facts, _pl_fi));
            if _pl_fm > 0 { push(_pl_fact_mols, _pl_fm); };
        };
        let _pl_fi = _pl_fi + 1;
    };
    let _pl_composed = compose(_pl_fact_mols);

    // Track topic for follow-up questions
    let _pl_topic_words = _pl_split_words(_pl_resolved);
    let _pl_ti = 0;
    while _pl_ti < len(_pl_topic_words) {
        let _pl_tw = __array_get(_pl_topic_words, _pl_ti);
        // First content word >= 4 chars = topic (skip short words)
        if len(_pl_tw) >= 4 {
            let _ = __set_at(__conv_topic, 0, _pl_tw);
            let _pl_ti = len(_pl_topic_words);  // break
        };
        let _pl_ti = _pl_ti + 1;
    };

    // ⑪ Compose response: combine top 2 facts if both relevant to query
    let _pl_response = _pl_strip_ts(__array_get(_pl_facts, 0));
    if len(_pl_facts) >= 2 {
        let _pl_f2 = _pl_strip_ts(__array_get(_pl_facts, 1));
        if len(_pl_f2) > 20 {
            // Only combine if 2nd fact shares a key query word with 1st
            let _pl_qw = _pl_split_words(_pl_input);
            let _pl_shared = [0];
            let _pl_qi = 0;
            while _pl_qi < len(_pl_qw) {
                let _pl_w = __array_get(_pl_qw, _pl_qi);
                if len(_pl_w) >= 3 {
                    if _pl_find_in(_pl_f2, _pl_w) >= 0 {
                        if _pl_find_in(_pl_response, _pl_w) >= 0 {
                            let _ = __set_at(_pl_shared, 0, 1);
                        };
                    };
                };
                let _pl_qi = _pl_qi + 1;
            };
            if __array_get(_pl_shared, 0) == 1 {
                let _pl_response = _pl_response + ". " + _pl_f2;
            };
        };
    };

    // ⑥ Hebbian + ⑦ Dream
    if _pl_home.mode == "LEARN" { dn_observe(_pl_input); kt_learn(_pl_input); __file_append("homeos.knowledge", _pl_input + "\n"); };

    // ──── CHECKPOINT 5: RESPONSE ────
    let _pl_out_safe = instinct_route(_pl_response);
    if _pl_out_safe.instinct == "SAFETY" { return "Da loc noi dung."; };

    return _pl_response;
}

// Text search: split query → kt_find each word → score by match count → rank
fn _pl_text_search(_pts_input) {
    let _pts_words = _pl_split_words(_pts_input);
    // Skip short/common words
    let _pts_qwords = [];
    let _pts_wi = 0;
    while _pts_wi < len(_pts_words) {
        let _pts_w = __array_get(_pts_words, _pts_wi);
        if len(_pts_w) >= 3 {
            // Skip question words
            let _pts_skip = [0];
            if _pts_w == "la" { let _ = __set_at(_pts_skip, 0, 1); };
            if _pts_w == "gi" { let _ = __set_at(_pts_skip, 0, 1); };
            if _pts_w == "nao" { let _ = __set_at(_pts_skip, 0, 1); };
            if _pts_w == "the" { let _ = __set_at(_pts_skip, 0, 1); };
            if _pts_w == "bao" { let _ = __set_at(_pts_skip, 0, 1); };
            if _pts_w == "nhieu" { let _ = __set_at(_pts_skip, 0, 1); };
            if _pts_w == "dau" { let _ = __set_at(_pts_skip, 0, 1); };
            if _pts_w == "sao" { let _ = __set_at(_pts_skip, 0, 1); };
            if _pts_w == "nhu" { let _ = __set_at(_pts_skip, 0, 1); };
            if _pts_w == "cua" { let _ = __set_at(_pts_skip, 0, 1); };
            if _pts_w == "voi" { let _ = __set_at(_pts_skip, 0, 1); };
            if __array_get(_pts_skip, 0) == 0 { push(_pts_qwords, _pts_w); };
        };
        let _pts_wi = _pts_wi + 1;
    };
    if len(_pts_qwords) == 0 { return []; };
    // Collect candidates with IDF weighting + hash dedup O(n) instead of O(n²)
    let _pts_facts = [];
    let _pts_scores = [];
    let _pts_seen = __array_range(256);  // hash dedup: fact_hash → position+1 (0=empty)
    let _pts_si = 0;
    while _pts_si < 256 { let _ = __set_at(_pts_seen, _pts_si, 0); let _pts_si = _pts_si + 1; };
    let _pts_qi = 0;
    while _pts_qi < len(_pts_qwords) {
        let _pts_qw = __array_get(_pts_qwords, _pts_qi);
        let _pts_found = kt_find_fast(_pts_qw, 10);
        let _pts_idf = 1;
        if len(_pts_found) > 0 { let _pts_idf = __floor(10 / len(_pts_found)); };
        if _pts_idf < 1 { let _pts_idf = 1; };
        if _pts_idf > 5 { let _pts_idf = 5; };
        let _pts_fi = 0;
        while _pts_fi < len(_pts_found) {
            let _pts_fact = __array_get(_pts_found, _pts_fi);
            // Hash dedup: O(1) lookup instead of O(n) scan
            let _pts_fh = __bit_and(_kt_word_hash(_pts_fact), 255);
            let _pts_idx = [__array_get(_pts_seen, _pts_fh) - 1];  // -1 = not found
            if __array_get(_pts_idx, 0) >= 0 {
                // Already seen → increment by IDF weight
                let _pts_existing = __array_get(_pts_idx, 0);
                let _ = __set_at(_pts_scores, _pts_existing, __array_get(_pts_scores, _pts_existing) + _pts_idf);
            };
            if __array_get(_pts_idx, 0) < 0 {
                // New fact — score: IDF base + position bonus + length bonus - timestamp penalty
                let _pts_pos_bonus = 0;
                let _pts_qw_pos = _pl_find_in(_pts_fact, _pts_qw);
                if _pts_qw_pos >= 0 { if _pts_qw_pos < 10 { let _pts_pos_bonus = 3; }; };
                let _pts_len_bonus = __floor(len(_pts_fact) / 60);
                if _pts_len_bonus > 2 { let _pts_len_bonus = 2; };
                let _pts_ts_pen = 0;
                if len(_pts_fact) > 0 { if __char_code(char_at(_pts_fact, 0)) == 91 { let _pts_ts_pen = 3; }; };
                let _pts_new_pos = len(_pts_facts);
                push(_pts_facts, _pts_fact);
                push(_pts_scores, _pts_idf + _pts_pos_bonus + _pts_len_bonus - _pts_ts_pen);
                let _ = __set_at(_pts_seen, _pts_fh, _pts_new_pos + 1);
            };
            let _pts_fi = _pts_fi + 1;
        };
        let _pts_qi = _pts_qi + 1;
    };
    // Sort by score descending (selection sort)
    let _pts_si = 0;
    while _pts_si < len(_pts_facts) {
        let _pts_best = [_pts_si];
        let _pts_best_s = [__array_get(_pts_scores, _pts_si)];
        let _pts_sj = _pts_si + 1;
        while _pts_sj < len(_pts_facts) {
            if __array_get(_pts_scores, _pts_sj) > __array_get(_pts_best_s, 0) {
                let _ = __set_at(_pts_best, 0, _pts_sj);
                let _ = __set_at(_pts_best_s, 0, __array_get(_pts_scores, _pts_sj));
            };
            let _pts_sj = _pts_sj + 1;
        };
        let _pts_bi = __array_get(_pts_best, 0);
        if _pts_bi != _pts_si {
            // Swap facts
            let _pts_tf = __array_get(_pts_facts, _pts_si);
            let _ = __set_at(_pts_facts, _pts_si, __array_get(_pts_facts, _pts_bi));
            let _ = __set_at(_pts_facts, _pts_bi, _pts_tf);
            // Swap scores
            let _pts_ts = __array_get(_pts_scores, _pts_si);
            let _ = __set_at(_pts_scores, _pts_si, __array_get(_pts_scores, _pts_bi));
            let _ = __set_at(_pts_scores, _pts_bi, _pts_ts);
        };
        let _pts_si = _pts_si + 1;
    };
    // Return top 10, skip very short facts (titles/headers < 30 chars)
    let _pts_out = [];
    let _pts_oi = 0;
    while _pts_oi < len(_pts_facts) {
        if len(_pts_out) < 10 {
            let _pts_f = __array_get(_pts_facts, _pts_oi);
            if len(_pts_f) >= 30 { push(_pts_out, _pts_f); };
        };
        let _pts_oi = _pts_oi + 1;
    };
    // If all were short, return whatever we have
    if len(_pts_out) == 0 {
        let _pts_oi = 0;
        while _pts_oi < len(_pts_facts) {
            if _pts_oi < 5 { push(_pts_out, __array_get(_pts_facts, _pts_oi)); };
            let _pts_oi = _pts_oi + 1;
        };
    };
    return _pts_out;
}

// Resolve pronouns: replace "it"/"that"/"this" with last conversation topic
fn _pl_resolve_pronouns(_prp_text) {
    let _prp_topic = __array_get(__conv_topic, 0);
    if len(_prp_topic) < 3 { return _prp_text; };
    // Replace " it " with " <topic> "
    let _prp_out = _prp_text;
    let _prp_out = _pl_replace_word(_prp_out, " it ", " " + _prp_topic + " ");
    let _prp_out = _pl_replace_word(_prp_out, " it?", " " + _prp_topic + "?");
    let _prp_out = _pl_replace_word(_prp_out, " that ", " " + _prp_topic + " ");
    let _prp_out = _pl_replace_word(_prp_out, " that?", " " + _prp_topic + "?");
    return _prp_out;
}

fn _pl_replace_word(_prw_text, _prw_from, _prw_to) {
    let _prw_pos = _pl_find_in(_prw_text, _prw_from);
    if _prw_pos < 0 { return _prw_text; };
    let _prw_before = substr(_prw_text, 0, _prw_pos);
    let _prw_after = substr(_prw_text, _prw_pos + len(_prw_from), len(_prw_text));
    return _prw_before + _prw_to + _prw_after;
}

// Strip "[YYYY-MM-DD HH:MM] " timestamp prefix from knowledge entries
fn _pl_strip_ts(_pst_text) {
    if len(_pst_text) < 20 { return _pst_text; };
    if __char_code(char_at(_pst_text, 0)) != 91 { return _pst_text; };  // not [
    // Find closing ]
    let _pst_i = 1;
    while _pst_i < 20 {
        if __char_code(char_at(_pst_text, _pst_i)) == 93 {  // ]
            // Skip ] and space after it
            let _pst_start = _pst_i + 1;
            if _pst_start < len(_pst_text) {
                if __char_code(char_at(_pst_text, _pst_start)) == 32 { let _pst_start = _pst_start + 1; };
            };
            return substr(_pst_text, _pst_start, len(_pst_text));
        };
        let _pst_i = _pst_i + 1;
    };
    return _pst_text;
}

// Find position of needle in haystack, -1 if not found
fn _pl_find_in(_pfi_hay, _pfi_needle) {
    let _pfi_hl = len(_pfi_hay);
    let _pfi_nl = len(_pfi_needle);
    let _pfi_i = 0;
    while _pfi_i <= (_pfi_hl - _pfi_nl) {
        if substr(_pfi_hay, _pfi_i, _pfi_i + _pfi_nl) == _pfi_needle { return _pfi_i; };
        let _pfi_i = _pfi_i + 1;
    };
    return 0 - 1;
}

fn _pl_split_words(_psw_text) {
    let _psw_out = [];
    let _psw_start = [0];
    let _psw_i = 0;
    let _psw_tlen = len(_psw_text);
    while _psw_i < _psw_tlen {
        let _psw_c = __char_code(char_at(_psw_text, _psw_i));
        if _psw_c == 32 {
            let _psw_s = __array_get(_psw_start, 0);
            if _psw_i > _psw_s { push(_psw_out, substr(_psw_text, _psw_s, _psw_i)); };
            let _ = __set_at(_psw_start, 0, _psw_i + 1);
        };
        if _psw_c == 63 {
            let _psw_s = __array_get(_psw_start, 0);
            if _psw_i > _psw_s { push(_psw_out, substr(_psw_text, _psw_s, _psw_i)); };
            let _ = __set_at(_psw_start, 0, _psw_i + 1);
        };
        let _psw_i = _psw_i + 1;
    };
    let _psw_s = __array_get(_psw_start, 0);
    if _psw_tlen > _psw_s { push(_psw_out, substr(_psw_text, _psw_s, _psw_tlen)); };
    return _psw_out;
}

// Pipeline stats
pub fn pipeline_stats() {
    return "Pipeline: 14 DNA mechanisms active. " + kt_stats();
}
