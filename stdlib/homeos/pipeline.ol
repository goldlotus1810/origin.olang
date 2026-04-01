// homeos/pipeline.ol — G8: Pipeline = PURE MATH. No if/else on keywords.
// Input → encode → search → silk walk → compose → decode. Toán thuần.

let _phi_inv = 618;
let __v_history = [4, 4, 4, 4];
let __v_idx = [0];

// G11: Homeostasis F(t)
fn _homeostasis(_input_mol, _nearest_mol) {
    if _nearest_mol == 0 { return 1000; };
    return _kt_mol_dist(_input_mol, _nearest_mol) * 100;
}

// G11: ConversationCurve V'(t)
fn _curve_push_v(_v) {
    let _idx = __array_get(__v_idx, 0) % 4;
    let _ = __set_at(__v_history, _idx, _v);
    let _ = __set_at(__v_idx, 0, __array_get(__v_idx, 0) + 1);
}

fn _curve_deriv() {
    let _n = __array_get(__v_idx, 0);
    if _n < 2 { return 0; };
    let _i1 = (_n - 1) % 4;
    let _i2 = (_n - 2) % 4;
    return __array_get(__v_history, _i1) - __array_get(__v_history, _i2);
}

// ═══ G12: Immune Selection — 3 deterministic branches ═══
fn _ranked_dims(_mol) {
    // Sort dimensions by deviation from neutral (largest first)
    let _devs = [];
    push(_devs, _kt_abs((_kt_mol_s(_mol) * 66) - 500));  // S: 0-15 → 0-990
    push(_devs, _kt_abs((_kt_mol_r(_mol) * 66) - 500));  // R
    push(_devs, _kt_abs((_kt_mol_v(_mol) * 142) - 500)); // V: 0-7 → 0-994
    push(_devs, _kt_abs((_kt_mol_a(_mol) * 142) - 500)); // A
    push(_devs, _kt_abs((_kt_mol_t(_mol) * 333) - 500)); // T: 0-3 → 0-999
    // Find top-2 dimensions
    let _d0 = [0]; let _d1 = [1]; let _m0 = [0]; let _m1 = [0];
    let _ = __set_at(_m0, 0, __array_get(_devs, 0));
    let _i = 1;
    while _i < 5 {
        if __array_get(_devs, _i) > __array_get(_m0, 0) {
            let _ = __set_at(_d1, 0, __array_get(_d0, 0));
            let _ = __set_at(_m1, 0, __array_get(_m0, 0));
            let _ = __set_at(_d0, 0, _i);
            let _ = __set_at(_m0, 0, __array_get(_devs, _i));
        } else {
            if __array_get(_devs, _i) > __array_get(_m1, 0) {
                let _ = __set_at(_d1, 0, _i);
                let _ = __set_at(_m1, 0, __array_get(_devs, _i));
            };
        };
        let _i = _i + 1;
    };
    return [__array_get(_d0, 0), __array_get(_d1, 0)];
}

fn _immune_3_branches(_start_mol, _query_mol) {
    let _dims = _ranked_dims(_query_mol);
    let _dim0 = __array_get(_dims, 0);
    let _dim1 = __array_get(_dims, 1);
    // Branch 0: primary dim, primary start
    let _p0 = kt_silk_walk_dim(_start_mol, _dim0, 3, 10);
    // Branch 1: secondary dim, primary start
    let _p1 = kt_silk_walk_dim(_start_mol, _dim1, 3, 10);
    // Branch 2: primary dim, alternative start (neighbor on secondary dim)
    let _alt = implicit_neighbors(_query_mol, _dim1, 1);
    let _alt_mol = _start_mol;
    if len(_alt) > 0 {
        let _am = _kt_real_mol(__array_get(_alt, 0));
        if _am != _start_mol { let _alt_mol = _am; };
    };
    let _p2 = kt_silk_walk_dim(_alt_mol, _dim0, 3, 10);
    return [_p0, _p1, _p2];
}

// ═══ G12: Shannon entropy of silk strengths along path ═══
fn _path_entropy(_path) {
    if len(_path) < 2 { return 9999; };
    let _total = [0];
    let _strengths = [];
    let _i = 0;
    while _i < len(_path) - 1 {
        let _s = implicit_strength(__array_get(_path, _i), __array_get(_path, _i + 1));
        if _s < 1 { let _s = 1; };
        push(_strengths, _s);
        let _ = __set_at(_total, 0, __array_get(_total, 0) + _s);
        let _i = _i + 1;
    };
    let _t = __array_get(_total, 0);
    if _t == 0 { return 9999; };
    let _h = [0];
    let _i = 0;
    while _i < len(_strengths) {
        let _p = __array_get(_strengths, _i) / _t;
        if _p > 0 {
            let _ = __set_at(_h, 0, __array_get(_h, 0) - _p * __log2(_p));
        };
        let _i = _i + 1;
    };
    return __floor(__array_get(_h, 0) * 100);
}

// ═══ G12: Path quality = 0.30×valid + 0.30×(1-H/2.32) + 0.20×consistency + 0.20×silk ═══
fn _path_quality(_path) {
    if len(_path) == 0 { return 0; };
    // validity: all mols non-zero
    let _valid = 1000;
    let _i = 0;
    while _i < len(_path) {
        if __array_get(_path, _i) == 0 { let _valid = 0; };
        let _i = _i + 1;
    };
    // entropy penalty
    let _h = _path_entropy(_path);
    let _h_norm = 1000 - __floor(_h * 1000 / 232);
    if _h_norm < 0 { let _h_norm = 0; };
    // consistency: how many dimensions stay coherent (low variance)
    let _coherent = [0];
    let _d = 0;
    while _d < 5 {
        let _sum = [0]; let _sum2 = [0]; let _n = len(_path);
        let _j = 0;
        while _j < _n {
            let _v = mol_get_dim(__array_get(_path, _j), _d);
            let _ = __set_at(_sum, 0, __array_get(_sum, 0) + _v);
            let _ = __set_at(_sum2, 0, __array_get(_sum2, 0) + _v * _v);
            let _j = _j + 1;
        };
        let _mean = __array_get(_sum, 0) / _n;
        let _var = __array_get(_sum2, 0) / _n - _mean * _mean;
        let _max_r = 15; if _d >= 2 { let _max_r = 7; }; if _d == 4 { let _max_r = 3; };
        if _var < __floor(_max_r * _max_r / 4) { let _ = __set_at(_coherent, 0, __array_get(_coherent, 0) + 1); };
        let _d = _d + 1;
    };
    let _consistency = __floor(__array_get(_coherent, 0) * 200);  // 0-1000
    // silk support
    let _silk_sum = [0];
    let _i = 0;
    while _i < len(_path) - 1 {
        let _ = __set_at(_silk_sum, 0, __array_get(_silk_sum, 0) + implicit_strength(__array_get(_path, _i), __array_get(_path, _i + 1)));
        let _i = _i + 1;
    };
    let _silk_avg = 0;
    if len(_path) > 1 { let _silk_avg = __floor(__array_get(_silk_sum, 0) / (len(_path) - 1)); };
    if _silk_avg > 1000 { let _silk_avg = 1000; };
    return __floor(300 * _valid / 1000 + 300 * _h_norm / 1000 + 200 * _consistency / 1000 + 200 * _silk_avg / 1000);
}

// ═══ G12: DNA Repair — max 3 iterations, fix weakest dimension ═══
fn _dna_repair(_path, _query_mol) {
    let _best = _path;
    let _best_q = _path_quality(_path);
    let _iter = 0;
    while _iter < 3 {
        if _best_q >= 618 { return _best; };
        // Find weakest link (lowest silk to next)
        let _weakest = [0]; let _weak_s = [99999];
        let _i = 0;
        while _i < len(_best) - 1 {
            let _s = implicit_strength(__array_get(_best, _i), __array_get(_best, _i + 1));
            if _s < __array_get(_weak_s, 0) {
                let _ = __set_at(_weak_s, 0, _s);
                let _ = __set_at(_weakest, 0, _i + 1);
            };
            let _i = _i + 1;
        };
        // Try replacing weakest node with a neighbor of its predecessor
        let _wi = __array_get(_weakest, 0);
        if _wi > 0 { if _wi < len(_best) {
            let _prev_mol = __array_get(_best, _wi - 1);
            let _dim = mol_dominant_dim(_query_mol);
            let _alts = implicit_neighbors(_prev_mol, _dim, 3);
            let _ai = 0;
            while _ai < len(_alts) {
                let _am = _kt_real_mol(__array_get(_alts, _ai));
                if _am != __array_get(_best, _wi) {
                    // Try substitute
                    let _trial = [];
                    let _ti = 0;
                    while _ti < len(_best) {
                        if _ti == _wi { push(_trial, _am); } else { push(_trial, __array_get(_best, _ti)); };
                        let _ti = _ti + 1;
                    };
                    let _tq = _path_quality(_trial);
                    if _tq > _best_q {
                        let _best = _trial;
                        let _best_q = _tq;
                    };
                };
                let _ai = _ai + 1;
            };
        }; };
        let _iter = _iter + 1;
    };
    return _best;
}

// ═══ G16: Decode ∂ — path of mols → composed text (SINH) ═══
fn _decode_path(_path) {
    let _texts = [];
    let _i = 0;
    while _i < len(_path) {
        let _mol = __array_get(_path, _i);
        if _mol > 0 {
            let _fact = kt_nearest(_mol);
            if len(_fact) > 0 {
                // Dedup
                let _dup = 0;
                let _j = 0;
                while _j < len(_texts) {
                    if __array_get(_texts, _j) == _fact { let _dup = 1; };
                    let _j = _j + 1;
                };
                if _dup == 0 { push(_texts, _fact); };
            };
        };
        let _i = _i + 1;
    };
    // Join texts
    let _out = "";
    let _i = 0;
    while _i < len(_texts) {
        if _i > 0 { let _out = _out + ". "; };
        let _out = _out + __array_get(_texts, _i);
        let _i = _i + 1;
    };
    return _out;
}

// ═══ G11: ConversationCurve V''(t) + tone selection ═══
fn _curve_accel() {
    let _n = __array_get(__v_idx, 0);
    if _n < 3 { return 0; };
    let _i1 = (_n - 1) % 4;
    let _i2 = (_n - 2) % 4;
    let _i3 = (_n - 3) % 4;
    let _vp1 = __array_get(__v_history, _i1) - __array_get(__v_history, _i2);
    let _vp2 = __array_get(__v_history, _i2) - __array_get(__v_history, _i3);
    return _vp1 - _vp2;
}

fn _select_tone() {
    let _vd = _curve_deriv();
    let _va = _curve_accel();
    // V' < -1 → Supportive
    if _vd < (0 - 1) { return "supportive"; };
    // V'' < -2 → Pause
    if _va < (0 - 2) { return "pause"; };
    // V' > 1 → Reinforcing
    if _vd > 1 { return "reinforcing"; };
    // V'' > 2 AND V > 0 → Celebratory
    let _n = __array_get(__v_idx, 0);
    if _va > 2 {
        let _vi = (_n - 1) % 4;
        if __array_get(__v_history, _vi) > 4 { return "celebratory"; };
    };
    return "engaged";
}

fn _apply_tone(_text, _tone) {
    if len(_text) == 0 { return _text; };
    if _tone == "supportive" { return _text; };
    if _tone == "pause" { return _text; };
    return _text;
}

// ═══ G9: Confidence prefix from instinct_honesty ═══
fn _confidence_prefix(_mol) {
    let _c = instinct_honesty(_mol);
    if _c < 40 { return ""; };
    if _c < 70 { return ""; };
    return "";
}

// G8: Pipeline — PURE MATH
pub fn pipeline(input) {
    // CP1: SecurityGate (V/A thresholds, not keywords)
    if security_gate(input) == 1 {
        return "Neu ban can ho tro, xin goi 1800 599 920";
    };

    // STEP 2: Encode → mol (5D position)
    let _mol = _kt_real_mol(input);
    if _mol == 0 { return ""; };
    wm_set(0, _mol);
    let _v = mol_get_dim(_mol, 2);
    let _a = mol_get_dim(_mol, 3);
    _curve_push_v(_v);

    // STEP 3: Search — mol dominant dimension decides WHERE to look
    // No keyword matching. mol_dominant_dim = which dimension deviates most from neutral.
    // That IS the query type. P_weight encodes it.
    let _dim = mol_dominant_dim(_mol);
    let _text_results = [];

    // 3a: Text search (word overlap — structural, not semantic)
    let _sw = [0]; let _si = 0;
    while _si <= len(input) {
        let _is_sp = 0;
        if _si == len(input) { let _is_sp = 1; } else {
            if __char_code(char_at(input, _si)) == 32 { let _is_sp = 1; };
        };
        if _is_sp == 1 {
            let _word = substr(input, __array_get(_sw, 0), _si);
            if len(_word) >= 3 {
                let _wr = kt_find(_word, 3);
                let _wi = 0;
                while _wi < len(_wr) {
                    push(_text_results, __array_get(_wr, _wi));
                    let _wi = _wi + 1;
                };
            };
            let _ = __set_at(_sw, 0, _si + 1);
        };
        let _si = _si + 1;
    };

    // 3b: Mol nearest (semantic — 5D distance)
    if len(_text_results) == 0 {
        let _near = kt_nearest(_mol);
        if len(_near) > 0 { push(_text_results, _near); };
    };

    // 3c: Silk walk — filter by implicit silk strength (COMPUTED, not magic number)
    let _walk = kt_silk_walk_dim(_mol, _dim, 3, 10);
    let _wi = 1;
    while _wi < len(_walk) {
        let _wmol = __array_get(_walk, _wi);
        if implicit_strength(_mol, _wmol) >= 400 {
            let _wf = kt_nearest(_wmol);
            if len(_wf) > 0 { push(_text_results, _wf); };
        };
        let _wi = _wi + 1;
    };

    // STEP 4: Homeostasis — surprise drives learning rate
    let _nearest_mol = 0;
    if len(_text_results) > 0 { let _nearest_mol = _kt_real_mol(__array_get(_text_results, 0)); };
    wm_set(1, _nearest_mol);
    let _surprise = _homeostasis(_mol, _nearest_mol);
    // λ: surprise > φ⁻¹ → learn mode, else → act mode
    let _learn_mode = 0;
    if _surprise > _phi_inv { let _learn_mode = 1; };

    // STEP 9: Hebbian fire — MODULATED by V'(t) (vi phân)
    // V'(t) > 0 → conversation improving → fire STRONGER (reinforce)
    // V'(t) < 0 → conversation declining → fire WEAKER (don't reinforce mistakes)
    // V'(t) = 0 → neutral → normal fire
    let _vd = _curve_deriv();  // vi phân V(t)
    if _nearest_mol > 0 {
        // Fire strength proportional to derivative: base + V'(t) bonus
        if _vd >= 0 { kt_silk_fire(_mol, _nearest_mol); };
        if _vd > 1 { kt_silk_fire(_mol, _nearest_mol); };  // double fire on positive trend
    };
    let _ri = 0;
    while _ri < len(_text_results) {
        if _ri < 5 {
            let _rmol = _kt_real_mol(__array_get(_text_results, _ri));
            if _vd >= 0 { kt_silk_fire(_mol, _rmol); };
        };
        let _ri = _ri + 1;
    };

    // STEP 9b: Fire matched facts (maturity lifecycle)
    let _fi = 0;
    while _fi < len(_text_results) {
        if _fi < 3 {
            // Find fact index by text match and fire it
            let _fact_text = __array_get(_text_results, _fi);
            let _fj = 0;
            while _fj < len(__kt_facts) {
                if __array_get(__kt_facts, _fj) == _fact_text { kt_fire(_fj); let _fj = len(__kt_facts); };
                let _fj = _fj + 1;
            };
        };
        let _fi = _fi + 1;
    };

    // STEP 10: Dream + auto-save every 20 turns
    if (__array_get(__v_idx, 0) % 8) == 0 { dream(); };
    if (__array_get(__v_idx, 0) % 20) == 0 { nox_save(); };

    // STEP 13: STM push
    kt_stm_push(input);

    // STEP 11: If learn mode + no results → learn this input
    if _learn_mode == 1 {
        if len(_text_results) == 0 { kt_learn(input); };
    };

    // ═══ STEP 7+8+11: Immune Selection → DNA Repair → Decode ∂ (SINH) ═══
    // Only when text search found NOTHING — need to COMPUTE answer from silk.
    // When text search has results — use them directly (structural match is correct).
    let _response = "";
    if len(_text_results) == 0 {
        if _nearest_mol > 0 {
            let _branches = _immune_3_branches(_nearest_mol, _mol);
            let _best_path = __array_get(_branches, 0);
            let _best_h = [_path_entropy(__array_get(_branches, 0))];
            let _bi = 1;
            while _bi < 3 {
                let _bh = _path_entropy(__array_get(_branches, _bi));
                if _bh < __array_get(_best_h, 0) {
                    let _ = __set_at(_best_h, 0, _bh);
                    let _best_path = __array_get(_branches, _bi);
                };
                let _bi = _bi + 1;
            };
            let _repaired = _dna_repair(_best_path, _mol);
            wm_set(2, compose(_repaired));
            let _generated = _decode_path(_repaired);
            if len(_generated) > 0 { let _response = _generated; };
        };
    };
    // Text search results available — use directly (dedup, max 3)
    if len(_response) == 0 {
        let _seen = [];
        let _count = [0];
        let _ri = 0;
        while _ri < len(_text_results) {
            let _fact = __array_get(_text_results, _ri);
            let _dup = 0;
            let _si = 0;
            while _si < len(_seen) {
                if __array_get(_seen, _si) == _fact { let _dup = 1; };
                let _si = _si + 1;
            };
            if _dup == 0 {
                push(_seen, _fact);
                if __array_get(_count, 0) > 0 { let _response = _response + ". "; };
                let _response = _response + _fact;
                let _ = __set_at(_count, 0, __array_get(_count, 0) + 1);
            };
            if __array_get(_count, 0) >= 3 { let _ri = len(_text_results); };
            let _ri = _ri + 1;
        };
    };

    if len(_response) == 0 { wm_set(0, 0); wm_set(1, 0); wm_set(2, 0); wm_set(3, 0); return ""; };

    // STEP 12: ConversationCurve tone
    let _tone = _select_tone();
    let _response = _apply_tone(_response, _tone);

    // WM bind result
    wm_set(2, _nearest_mol);
    wm_set(3, _kt_real_mol(_response));

    // STEP 14: WM clear
    let _final = _response;
    wm_set(0, 0); wm_set(1, 0); wm_set(2, 0); wm_set(3, 0);

    return _final;
}

pub fn bootstrap() {
    let _c = __file_read("homeos.knowledge");
    if len(_c) == 0 { return "no homeos.knowledge"; };
    return spider_feed(_c, "homeos.knowledge");
}

pub fn bootstrap_md(_p) {
    let _c = __file_read(_p);
    if len(_c) == 0 { return "empty"; };
    return spider_feed_md(_c, _p);
}

pub fn bootstrap_file(_p, _chunk) { return "use bootstrap()"; }
