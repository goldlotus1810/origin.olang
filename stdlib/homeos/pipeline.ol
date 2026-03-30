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
    let _cvs_hlen = len(__conv_history);
    let _cvs_prev = __conv_history[_cvs_hlen - 1];
    let _cvs_prev2 = __conv_history[_cvs_hlen - 2];
    // D7: f'(t) = V(t) - V(t-1) — velocity
    let _cvs_dv = _kt_mol_v(_cvs_prev) - _kt_mol_v(_cvs_prev2);
    let _cvs_da = _kt_mol_a(_cvs_prev) - _kt_mol_a(_cvs_prev2);
    // D7: f''(t) = V'(t) - V'(t-1) — acceleration
    let _cvs_ddv = 0;
    if _cvs_hlen >= 3 {
        let _cvs_prev3 = __conv_history[_cvs_hlen - 3];
        let _cvs_dv_old = _kt_mol_v(_cvs_prev2) - _kt_mol_v(_cvs_prev3);
        let _cvs_ddv = _cvs_dv - _cvs_dv_old;
    };
    // D7: f(t) = 0.6 × f_conv(t) + 0.4 × f_dn — weighted
    // f_conv = V + 0.5×V' + 0.25×V'' (integer: V + V'/2 + V''/4)
    let _cvs_s = _kt_mol_s(_cvs_mol);
    let _cvs_r = _kt_mol_r(_cvs_mol);
    let _cvs_v = _kt_mol_v(_cvs_mol) + __floor(_cvs_dv / 2) + __floor(_cvs_ddv / 4);
    let _cvs_a = _kt_mol_a(_cvs_mol) + __floor(_cvs_da / 2);
    let _cvs_t = _kt_mol_t(_cvs_mol);
    // D7: Clamp ΔV_max = 3 per step (spec: 0.40 scaled to 0-7)
    let _cvs_orig_v = _kt_mol_v(_cvs_mol);
    let _cvs_delta = _cvs_v - _cvs_orig_v;
    if _cvs_delta > 3 { let _cvs_v = _cvs_orig_v + 3; };
    if _cvs_delta < -3 { let _cvs_v = _cvs_orig_v - 3; };
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

// ════════════════════════════════════════════════════════════════
// D2: 7 Instinct Formulas on 5D — evaluate quality/confidence
// ════════════════════════════════════════════════════════════════

// ① Honesty: confidence from evidence (silk weight + fire count + sources)
// Returns 0-1000 scale. <400=silent, 400-700=hypothesis, 700-900=opinion, >=900=fact
pub fn instinct_honesty(_ih_mol, _ih_facts) {
    let _ih_nfacts = len(_ih_facts);
    // silk_weight: best silk connection to any fact
    let _ih_sw = [0];
    let _ih_fi = 0;
    while _ih_fi < _ih_nfacts {
        if _ih_fi < 5 {
            let _ih_fm = _kt_fast_mol(__array_get(_ih_facts, _ih_fi));
            let _ih_w = kt_silk_weight(_ih_mol, _ih_fm);
            if _ih_w > __array_get(_ih_sw, 0) { let _ = __set_at(_ih_sw, 0, _ih_w); };
        };
        let _ih_fi = _ih_fi + 1;
    };
    // Normalize: silk 0-1000 → 0-300
    let _ih_silk = __floor(__array_get(_ih_sw, 0) * 300 / 1000);
    // source_count: number of facts found → 0-200
    let _ih_src = __floor(_ih_nfacts * 200 / 3);
    if _ih_src > 200 { let _ih_src = 200; };
    // consistency: mol distance from composed → 0-200 (closer = better)
    let _ih_cons = 200;
    if _ih_nfacts > 0 {
        let _ih_fm0 = _kt_fast_mol(__array_get(_ih_facts, 0));
        let _ih_d = _kt_mol_dist(_ih_mol, _ih_fm0);
        let _ih_cons = 200 - __floor(_ih_d * 200 / 47);
        if _ih_cons < 0 { let _ih_cons = 0; };
    };
    // Silk connectivity → 0-300 (fast: single lookup, no self_model scan)
    let _ih_silk2 = 0;
    if _ih_nfacts >= 2 {
        let _ih_fm0 = _kt_fast_mol(__array_get(_ih_facts, 0));
        let _ih_fm1 = _kt_fast_mol(__array_get(_ih_facts, 1));
        let _ih_silk2 = __floor(kt_silk_weight(_ih_fm0, _ih_fm1) * 300 / 1000);
    };
    return _ih_silk + _ih_src + _ih_cons + _ih_silk2;
}

// ② Contradiction: V distance high + R distance low = contradict
pub fn instinct_contradiction(_ic_a, _ic_b) {
    let _ic_dv = _kt_abs(_kt_mol_v(_ic_a) - _kt_mol_v(_ic_b));
    let _ic_dr = _kt_abs(_kt_mol_r(_ic_a) - _kt_mol_r(_ic_b));
    // dV > 5 (out of 7) AND dR < 2 (out of 15) → contradiction
    if _ic_dv > 5 { if _ic_dr < 2 { return 1; }; };
    return 0;
}

// ⑥ Curiosity: novelty = 1 - nearest_distance/max_distance
// Returns 0-1000: >500=explore, <300=familiar
pub fn instinct_curiosity(_icur_mol) {
    let _icur_near = kt_nearby(_icur_mol, 1);
    if len(_icur_near) == 0 { return 1000; };
    let _icur_d = __array_get(_icur_near, 0).distance;
    // max distance in 5D = 47
    let _icur_novelty = __floor((_icur_d * 1000) / 47);
    if _icur_novelty > 1000 { let _icur_novelty = 1000; };
    return _icur_novelty;
}

// ════════════════════════════════════════════════════════════════
// ⑩ Fusion — Merge text molecule + emotion + context
// ════════════════════════════════════════════════════════════════

pub fn fusion(_fu_text_mol, _fu_emo, _fu_context_mol) {
    // A4 rules: compose text_mol + context_mol
    if _fu_context_mol > 0 {
        let _fu_mols = [_fu_text_mol, _fu_context_mol];
        return compose(_fu_mols);
    };
    // No context: use text mol V/A from P_weight (not keyword emotion)
    return _fu_text_mol;
}

// ════════════════════════════════════════════════════════════════
// ⑤ Compose — Recombine N molecules → 1 new molecule
// ════════════════════════════════════════════════════════════════

pub fn compose(_co_mols) {
    let _co_n = len(_co_mols);
    if _co_n == 0 { return 0; };
    if _co_n == 1 { return __array_get(_co_mols, 0); };
    // A4 rules: S=max, R=Zipf, V=amplify, A=max, T=vote
    let _co_s_max = [0];
    let _co_r_sum = [0];
    let _co_r_wsum = [0];
    let _co_v_sum = [0];
    let _co_a_max = [0];
    let _co_t0 = [0];
    let _co_t1 = [0];
    let _co_t2 = [0];
    let _co_t3 = [0];
    let _co_i = 0;
    while _co_i < _co_n {
        let _co_m = __array_get(_co_mols, _co_i);
        let _co_s = _kt_mol_s(_co_m);
        let _co_r = _kt_mol_r(_co_m);
        let _co_v = _kt_mol_v(_co_m);
        let _co_a = _kt_mol_a(_co_m);
        let _co_t = _kt_mol_t(_co_m);
        // S = Union (max)
        if _co_s > __array_get(_co_s_max, 0) { let _ = __set_at(_co_s_max, 0, _co_s); };
        // R = Zipf-weighted average
        let _co_w = __floor(1000 / (_co_i + 1));
        let _ = __set_at(_co_r_sum, 0, __array_get(_co_r_sum, 0) + (_co_r * _co_w));
        let _ = __set_at(_co_r_wsum, 0, __array_get(_co_r_wsum, 0) + _co_w);
        // V = accumulate for amplify
        let _ = __set_at(_co_v_sum, 0, __array_get(_co_v_sum, 0) + _co_v);
        // A = Max
        if _co_a > __array_get(_co_a_max, 0) { let _ = __set_at(_co_a_max, 0, _co_a); };
        // T = vote
        if _co_t == 0 { let _ = __set_at(_co_t0, 0, __array_get(_co_t0, 0) + 1); };
        if _co_t == 1 { let _ = __set_at(_co_t1, 0, __array_get(_co_t1, 0) + 1); };
        if _co_t == 2 { let _ = __set_at(_co_t2, 0, __array_get(_co_t2, 0) + 1); };
        if _co_t == 3 { let _ = __set_at(_co_t3, 0, __array_get(_co_t3, 0) + 1); };
        let _co_i = _co_i + 1;
    };
    // S = max
    let _co_rs = __array_get(_co_s_max, 0) % 16;
    // R = Zipf weighted avg
    let _co_rw = __array_get(_co_r_wsum, 0);
    let _co_rr = 0;
    if _co_rw > 0 { let _co_rr = (__floor(__array_get(_co_r_sum, 0) / _co_rw)) % 16; };
    // V = amplify: base + sign × |spread| × 0.5 (spec A4)
    // "Cortisol + adrenaline → stress STRONGER than each alone"
    let _co_vsum = __array_get(_co_v_sum, 0);
    let _co_vbase = __floor(_co_vsum / _co_n);
    // Spread = max deviation from base across all inputs
    let _co_vspread = [0];
    let _co_vi = 0;
    while _co_vi < _co_n {
        let _co_vm = __array_get(_co_mols, _co_vi);
        let _co_vdev = _kt_mol_v(_co_vm) - _co_vbase;
        if _co_vdev < 0 { let _co_vdev = 0 - _co_vdev; };
        if _co_vdev > __array_get(_co_vspread, 0) { let _ = __set_at(_co_vspread, 0, _co_vdev); };
        let _co_vi = _co_vi + 1;
    };
    // Boost = spread / 2 (amplify, not average)
    let _co_vboost = __floor(__array_get(_co_vspread, 0) / 2);
    // Sign: if sum > neutral (4*n), positive boost; else negative
    let _co_rv = _co_vbase;
    if _co_vsum > (_co_n * 4) { let _co_rv = _co_vbase + _co_vboost; };
    if _co_vsum < (_co_n * 4) { let _co_rv = _co_vbase - _co_vboost; };
    if _co_rv > 7 { let _co_rv = 7; };
    if _co_rv < 0 { let _co_rv = 0; };
    // A = max
    let _co_ra = __array_get(_co_a_max, 0) % 8;
    // T = vote (majority wins)
    let _co_rt = 0;
    let _co_tmax = __array_get(_co_t0, 0);
    if __array_get(_co_t1, 0) > _co_tmax { let _co_rt = 1; let _co_tmax = __array_get(_co_t1, 0); };
    if __array_get(_co_t2, 0) > _co_tmax { let _co_rt = 2; let _co_tmax = __array_get(_co_t2, 0); };
    if __array_get(_co_t3, 0) > _co_tmax { let _co_rt = 3; };
    return (_co_rs * 4096) + (_co_rr * 256) + (_co_rv * 32) + (_co_ra * 4) + _co_rt;
}

// ════════════════════════════════════════════════════════════════
// Chain recombination — generate new content from existing chains
// Takes N fact texts, composes target mol, selects best segments
// ════════════════════════════════════════════════════════════════

pub fn chain_recombine(_cr_facts) {
    let _cr_n = len(_cr_facts);
    if _cr_n == 0 { return ""; };
    if _cr_n == 1 { return __array_get(_cr_facts, 0); };
    // Compose target mol from all facts
    let _cr_mols = [];
    let _cr_i = 0;
    while _cr_i < _cr_n {
        if _cr_i < 5 {
            let _cr_fm = _kt_fast_mol(__array_get(_cr_facts, _cr_i));
            if _cr_fm > 0 { push(_cr_mols, _cr_fm); };
        };
        let _cr_i = _cr_i + 1;
    };
    let _cr_target = compose(_cr_mols);
    if _cr_target == 0 { return __array_get(_cr_facts, 0); };
    // Split each fact into words, score each word's mol distance to target
    // Select words that are closest to the target mol (most relevant)
    let _cr_out = "";
    let _cr_used = [0, 0, 0, 0, 0, 0, 0, 0]; // dedup by word hash
    let _cr_fi = 0;
    while _cr_fi < _cr_n {
        if _cr_fi < 3 {
            let _cr_fact = __array_get(_cr_facts, _cr_fi);
            let _cr_words = _pl_split_words(_cr_fact);
            let _cr_wi = 0;
            while _cr_wi < len(_cr_words) {
                let _cr_w = __array_get(_cr_words, _cr_wi);
                if len(_cr_w) >= 3 {
                    let _cr_wm = _kt_fast_mol(_cr_w);
                    let _cr_dist = _kt_mol_dist(_cr_wm, _cr_target);
                    // Accept words within distance 10 of target
                    if _cr_dist <= 10 {
                        let _cr_wh = __bit_and(_kt_word_hash(_cr_w), 7);
                        if __array_get(_cr_used, _cr_wh) == 0 {
                            let _ = __set_at(_cr_used, _cr_wh, 1);
                            if len(_cr_out) > 0 { let _cr_out = _cr_out + " "; };
                            let _cr_out = _cr_out + _cr_w;
                        };
                    };
                };
                let _cr_wi = _cr_wi + 1;
            };
        };
        let _cr_fi = _cr_fi + 1;
    };
    // If recombination produced nothing useful, return first fact
    if len(_cr_out) < 5 { return __array_get(_cr_facts, 0); };
    return _cr_out;
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
        let _icf_m = _kt_fast_mol(__array_get(_icf_facts, _icf_i));
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
        let _ife_m = _kt_fast_mol(__array_get(_ife_facts, _ife_fi));
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
    // D5: 0.30×valid + 0.30×(1−H/2.32) + 0.20×consistency + 0.20×silk
    // ── Term 1: valid (0-300) ──
    let _cq_valid = 0;
    if _cq_mol > 0 {
        let _cq_s = _kt_mol_s(_cq_mol);
        let _cq_bucket = kt_get_dim(0, _cq_s);
        if len(_cq_bucket) > 0 { let _cq_valid = 300; };
    };
    // ── Term 2: 1 - H/2.32 (0-300) — low entropy = confident ──
    let _cq_s_val = _kt_mol_s(_cq_mol);
    let _cq_facts = kt_get_dim(0, _cq_s_val);
    let _cq_h = _is_fact_entropy(_cq_facts);
    // H scaled ×1000, max useful H ≈ 2320 (log2(5) × 1000)
    let _cq_h_norm = 300 - __floor(_cq_h * 300 / 2320);
    if _cq_h_norm < 0 { let _cq_h_norm = 0; };
    // ── Term 3: consistency = distance to input (0-200) ──
    let _cq_dist = _kt_mol_dist(_cq_mol, _cq_input_mol);
    let _cq_cons = 200 - __floor(_cq_dist * 200 / 47);
    if _cq_cons < 0 { let _cq_cons = 0; };
    // ── Term 4: silk weight to input (0-200) ──
    let _cq_silk = __floor(kt_silk_weight(_cq_mol, _cq_input_mol) * 200 / 1000);
    if _cq_silk > 200 { let _cq_silk = 200; };
    return _cq_valid + _cq_h_norm + _cq_cons + _cq_silk;
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

    // ⑩ Holistic Capture (E1): text + senses + context
    // sense_capture gates expensive sensors (screen/audio only when needed)
    let _pl_text_mol = _kt_fast_mol(_pl_input);
    let _pl_senses = sense_capture();
    // WM slot 0 = query, slot 1 = interoception
    wm_set(0, _pl_text_mol);
    wm_set(1, _pl_senses.intero);
    let _pl_context = wm_get(3);
    let _pl_fused = fusion(_pl_text_mol, 0, _pl_context);
    // Compose ALL active senses into fused signal (holistic capture D1)
    let _pl_sense_mols = [_pl_fused];
    if _pl_senses.intero > 0 { push(_pl_sense_mols, _pl_senses.intero); };
    if _pl_senses.screen > 0 { push(_pl_sense_mols, _pl_senses.screen); };
    if _pl_senses.audio > 0 { push(_pl_sense_mols, _pl_senses.audio); };
    if len(_pl_sense_mols) > 1 {
        let _pl_fused = compose(_pl_sense_mols);
    };
    // Apply conversation momentum
    let _pl_fused = _conv_shift(_pl_fused);

    // ⑬ Pronoun resolution: replace "it"/"that" with last topic
    let _pl_resolved = _pl_resolve_pronouns(_pl_input);
    // Search: MOLECULAR FIRST (5D P_weight), text fallback
    let _pl_mol_dec = kt_decode(_pl_resolved);
    let _pl_facts = _pl_mol_dec.facts;
    // Silk walk: follow associations depth 3, threshold 10 (weak links OK)
    if len(_pl_facts) > 0 {
        let _pl_sw_mol = _kt_fast_mol(__array_get(_pl_facts, 0));
        let _pl_silk = kt_silk_walk(_pl_sw_mol, 3, 10);
        let _pl_swi = 0;
        while _pl_swi < len(_pl_silk) {
            if len(_pl_facts) < 10 {
                push(_pl_facts, __array_get(_pl_silk, _pl_swi).text);
            };
            let _pl_swi = _pl_swi + 1;
        };
    };
    // Fallback: text search if molecular + silk found nothing
    if len(_pl_facts) == 0 {
        let _pl_facts = _pl_text_search(_pl_resolved);
    };

    // ⑫ Homeostasis: surprise detection
    let _pl_predicted = 0;
    if len(_pl_facts) > 0 { let _pl_predicted = _kt_fast_mol(__array_get(_pl_facts, 0)); };
    let _pl_home = homeostasis(_pl_fused, _pl_predicted);

    // ──── CHECKPOINT 2: ENCODE ────
    // CP2: |entities| >= 1, chain valid, compose non-zero
    // ⑧ Instincts first (short-circuit greetings, meta)
    let _pl_inst = _pl_safe;
    if _pl_inst.instinct == "GREETING" { return instinct_act(_pl_inst, _pl_input); };
    if _pl_inst.instinct == "META" { return instinct_act(_pl_inst, _pl_input); };

    if len(_pl_facts) == 0 {
        if _pl_home.mode == "LEARN" { dn_observe(_pl_input); kt_learn(_pl_input); __file_append("homeos.knowledge", _pl_input + "\n"); __heap_pin(); return "Toi se hoc them ve dieu nay."; };
        return "Toi chua biet.";
    };
    // CP2 verify: chain_mol valid
    if _pl_chain_mol == 0 { return "Loi ma hoa."; };

    // ⑤ Compose: recombine found knowledge
    let _pl_fact_mols = [];
    let _pl_fi = 0;
    while _pl_fi < len(_pl_facts) {
        if _pl_fi < 5 {
            let _pl_fm = _kt_fast_mol(__array_get(_pl_facts, _pl_fi));
            if _pl_fm > 0 { push(_pl_fact_mols, _pl_fm); };
        };
        let _pl_fi = _pl_fi + 1;
    };
    let _pl_composed = compose(_pl_fact_mols);

    // ──── CHECKPOINT 3: INFER ────
    // CP3: composed mol non-zero, at least 1 fact valid
    if _pl_composed == 0 { let _pl_composed = _pl_fused; };
    // Apply immune selection: 3 branches, pick lowest entropy
    let _pl_immune = immune_select(_pl_composed);
    // Use immune-selected facts if better than original
    if len(_pl_immune.facts) > 0 {
        if _pl_immune.entropy < _is_fact_entropy(_pl_facts) {
            let _pl_facts = _pl_immune.facts;
        };
    };
    // DNA repair: improve composed mol quality (max 3 iterations)
    let _pl_repaired = dna_repair(_pl_composed, _pl_fused, 3);
    // Use repaired mol for response selection (closer to input = better match)
    if _pl_repaired != _pl_composed {
        let _pl_composed = _pl_repaired;
    };

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

    // ⑪ Chain recombination: generate response from multiple facts
    let _pl_response = _pl_strip_ts(__array_get(_pl_facts, 0));
    if len(_pl_facts) >= 2 {
        let _pl_recomb = chain_recombine(_pl_facts);
        if len(_pl_recomb) >= 5 {
            let _pl_response = _pl_recomb;
        };
    };

    // ──── CHECKPOINT 4: PROMOTE ────
    // CP4: only learn/promote if quality sufficient
    // ⑥ Hebbian + ⑦ Dream — mode-dependent behavior
    if _pl_home.mode == "LEARN" {
        // LEARN: surprise high → learn aggressively + silk fire + dream
        dn_observe(_pl_input);
        kt_learn(_pl_input);
        __file_append("homeos.knowledge", _pl_input + "\n");
        // Silk: fire query↔response for future association
        let _pl_resp_mol = _kt_fast_mol(_pl_response);
        if _pl_resp_mol > 0 { kt_silk_fire(_pl_text_mol, _pl_resp_mol); };
    };
    // ACT mode: no learning, just respond confidently

    // ① Honesty instinct: confidence from evidence → prefix response
    let _pl_conf = instinct_honesty(_pl_fused, _pl_facts);
    if _pl_conf < 400 {
        let _pl_response = "Toi khong chac: " + _pl_response;
    };
    if _pl_conf >= 400 { if _pl_conf < 700 {
        let _pl_response = "Toi nghi: " + _pl_response;
    }; };
    // 700-900: "Co le:" (opinion) — skip prefix for cleaner output
    // >= 900: confident, no prefix needed

    // ──── CHECKPOINT 5: RESPONSE ────
    let _pl_out_safe = instinct_route(_pl_response);
    if _pl_out_safe.instinct == "SAFETY" { return "Da loc noi dung."; };

    // WM slot 2 = candidate (composed mol), slot 3 = result (response mol)
    wm_set(2, _pl_composed);
    wm_set(3, _kt_fast_mol(_pl_response));
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
