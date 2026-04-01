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

// G11: ConversationCurve V'(t) — with rate limit (A7: |ΔV| ≤ 3)
fn _curve_push_v(_v) {
    let _n = __array_get(__v_idx, 0);
    let _clamped = _v;
    if _n > 0 {
        let _prev = __array_get(__v_history, (_n - 1) % 4);
        let _delta = _v - _prev;
        if _delta > 3 { let _clamped = _prev + 3; };
        if _delta < (0 - 3) { let _clamped = _prev - 3; };
    };
    let _idx = _n % 4;
    let _ = __set_at(__v_history, _idx, _clamped);
    let _ = __set_at(__v_idx, 0, _n + 1);
}

fn _curve_deriv() {
    let _n = __array_get(__v_idx, 0);
    if _n < 2 { return 0; };
    let _i1 = (_n - 1) % 4;
    let _i2 = (_n - 2) % 4;
    return __array_get(__v_history, _i1) - __array_get(__v_history, _i2);
}

// ═══ Layer 2: Spreading Activation (Collins & Loftus 1975) ═══
// Multi-path: Hebbian + implicit edges. Merge duplicates (SUM). A1/A2/A8.
fn _spread_activate(_source, _dim, _steps, _threshold) {
    let _res_m = [_source]; let _res_v = [1000];
    let _act_m = [_source]; let _act_v = [1000];
    let _t = 0;
    while _t < _steps {
        let _raw_m = []; let _raw_v = [];
        let _ai = 0;
        while _ai < len(_act_m) {
            let _mol = __array_get(_act_m, _ai);
            let _act = __array_get(_act_v, _ai);
            if _act >= _threshold {
                // Implicit edges
                let _nbrs = implicit_neighbors(_mol, _dim, 5);
                let _ni = 0;
                while _ni < len(_nbrs) {
                    let _nm = _kt_real_mol(__array_get(_nbrs, _ni));
                    if _nm > 0 {
                        let _w = implicit_strength(_mol, _nm);
                        let _sp = __floor(_act * _w / 1000);
                        if _sp >= _threshold { push(_raw_m, _nm); push(_raw_v, _sp); };
                    };
                    let _ni = _ni + 1;
                };
                // Hebbian edges
                let _edges = __kt_silk[_silk_hash(_mol)];
                let _ei = 0;
                while _ei < len(_edges) {
                    let _tgt = __array_get(_edges, _ei);
                    let _w = __array_get(_edges, _ei + 1 + _dim);
                    if _w > 0 {
                        let _sp = __floor(_act * _w / 100);
                        if _sp >= _threshold { push(_raw_m, _tgt); push(_raw_v, _sp); };
                    };
                    let _ei = _ei + 6;
                };
                // Retention 30%
                let _r = __floor(_act * 300 / 1000);
                if _r >= _threshold { push(_raw_m, _mol); push(_raw_v, _r); };
            };
            let _ai = _ai + 1;
        };
        // Merge duplicates: SUM (A1)
        let _mg_m = []; let _mg_v = [];
        let _ri = 0;
        while _ri < len(_raw_m) {
            let _m = __array_get(_raw_m, _ri); let _v = __array_get(_raw_v, _ri);
            let _f = [0]; let _fi = 0;
            while _fi < len(_mg_m) {
                if __array_get(_mg_m, _fi) == _m {
                    let _ = __set_at(_mg_v, _fi, __array_get(_mg_v, _fi) + _v);
                    let _ = __set_at(_f, 0, 1);
                };
                let _fi = _fi + 1;
            };
            if __array_get(_f, 0) == 0 { push(_mg_m, _m); push(_mg_v, _v); };
            let _ri = _ri + 1;
        };
        // Decay 20%
        let _di = 0;
        while _di < len(_mg_v) {
            let _ = __set_at(_mg_v, _di, __floor(__array_get(_mg_v, _di) * 800 / 1000));
            let _di = _di + 1;
        };
        // Update results (top 10)
        let _ui = 0;
        while _ui < len(_mg_m) {
            let _m = __array_get(_mg_m, _ui); let _v = __array_get(_mg_v, _ui);
            let _f = [0]; let _fi = 0;
            while _fi < len(_res_m) {
                if __array_get(_res_m, _fi) == _m {
                    if _v > __array_get(_res_v, _fi) { let _ = __set_at(_res_v, _fi, _v); };
                    let _ = __set_at(_f, 0, 1);
                };
                let _fi = _fi + 1;
            };
            if __array_get(_f, 0) == 0 { if len(_res_m) < 10 { push(_res_m, _m); push(_res_v, _v); }; };
            let _ui = _ui + 1;
        };
        let _act_m = _mg_m; let _act_v = _mg_v;
        let _t = _t + 1;
    };
    return [_res_m, _res_v];
}

// ═══ Build chain from seed (A3: Hebbian + implicit) ═══
fn _build_chain(_seed, _query_mol, _dim, _depth) {
    let _chain = [_seed]; let _cur = _seed; let _d = 0;
    while _d < _depth {
        let _nbrs = implicit_neighbors(_cur, _dim, 3);
        let _bm = [0]; let _bs = [0];
        let _ni = 0;
        while _ni < len(_nbrs) {
            let _nm = _kt_real_mol(__array_get(_nbrs, _ni));
            if _nm > 0 { if _nm != _cur {
                let _s = implicit_strength(_cur, _nm);
                // Check Hebbian (A5)
                let _edges = __kt_silk[_silk_hash(_cur)];
                let _ei = 0;
                while _ei < len(_edges) {
                    if __array_get(_edges, _ei) == _nm {
                        let _hw = __array_get(_edges, _ei + 1 + _dim);
                        if _hw * 10 > _s { let _s = _hw * 10; };
                    };
                    let _ei = _ei + 6;
                };
                let _in = [0]; let _ci = 0;
                while _ci < len(_chain) {
                    if __array_get(_chain, _ci) == _nm { let _ = __set_at(_in, 0, 1); };
                    let _ci = _ci + 1;
                };
                if __array_get(_in, 0) == 0 {
                    if _s > __array_get(_bs, 0) {
                        let _ = __set_at(_bs, 0, _s); let _ = __set_at(_bm, 0, _nm);
                    };
                };
            }; };
            let _ni = _ni + 1;
        };
        if __array_get(_bm, 0) == 0 { let _d = _depth; } else {
            push(_chain, __array_get(_bm, 0)); let _cur = __array_get(_bm, 0);
        };
        let _d = _d + 1;
    };
    return _chain;
}

// ═══ CLONALG (De Castro 2002) — 3 candidates, 3 generations ═══
fn _pseudo_select(_mol, _gen, _max) {
    if _max <= 0 { return 0; };
    return __floor((_mol * 2654435761 + _gen * 40503) % _max);
}

fn _clonalg_generate(_activated, _query_mol, _dim) {
    // Initial population: top-3 activated as seeds
    let _pop = [];
    let _pi = 0;
    while _pi < 3 {
        if _pi < len(_activated) {
            let _seed = __array_get(_activated, _pi);
            push(_pop, _build_chain(_seed, _query_mol, _dim, 4));
        };
        let _pi = _pi + 1;
    };
    if len(_pop) == 0 { return []; };
    // 3 generations of clone + mutate (bounded)
    let _gen = 0;
    while _gen < 3 {
        let _all = [];
        let _all_q = [];
        // Evaluate + clone existing
        let _pi = 0;
        while _pi < len(_pop) {
            let _chain = __array_get(_pop, _pi);
            let _q = _path_quality(_chain);
            push(_all, _chain); push(_all_q, _q);
            // Mutate: alpha = exp(-2 * f_norm)
            let _f_norm = _q / 1000;
            let _alpha = __exp(0 - 2 * _f_norm);
            let _n_mut = __floor(len(_chain) * _alpha);
            if _n_mut < 1 { let _n_mut = 1; };
            // Create 1 mutated clone
            let _clone = [];
            let _ci = 0;
            while _ci < len(_chain) { push(_clone, __array_get(_chain, _ci)); let _ci = _ci + 1; };
            let _mi = 0;
            while _mi < _n_mut {
                let _idx = _pseudo_select(__array_get(_clone, 0), _gen * 7 + _mi, len(_clone));
                let _alts = implicit_neighbors(__array_get(_clone, _idx), _dim, 3);
                if len(_alts) > 0 {
                    let _pick = _pseudo_select(__array_get(_clone, _idx), _gen * 13 + _mi, len(_alts));
                    let _nm = _kt_real_mol(__array_get(_alts, _pick));
                    if _nm > 0 { let _ = __set_at(_clone, _idx, _nm); };
                };
                let _mi = _mi + 1;
            };
            push(_all, _clone); push(_all_q, _path_quality(_clone));
            let _pi = _pi + 1;
        };
        // Select top 3
        let _new_pop = [];
        let _sel = 0;
        while _sel < 3 {
            let _best_i = [0]; let _best_q = [0 - 1];
            let _si = 0;
            while _si < len(_all) {
                if __array_get(_all_q, _si) > __array_get(_best_q, 0) {
                    let _ = __set_at(_best_q, 0, __array_get(_all_q, _si));
                    let _ = __set_at(_best_i, 0, _si);
                };
                let _si = _si + 1;
            };
            if __array_get(_best_q, 0) >= 0 {
                push(_new_pop, __array_get(_all, __array_get(_best_i, 0)));
                let _ = __set_at(_all_q, __array_get(_best_i, 0), 0 - 999);
            };
            let _sel = _sel + 1;
        };
        let _pop = _new_pop;
        let _gen = _gen + 1;
    };
    return _pop;
}

// ═══ Shannon entropy of path ═══
fn _path_entropy(_path) {
    if len(_path) < 2 { return 9999; };
    let _total = [0]; let _strengths = [];
    let _i = 0;
    while _i < len(_path) - 1 {
        let _s = implicit_strength(__array_get(_path, _i), __array_get(_path, _i + 1));
        // Also check Hebbian (A5)
        let _edges = __kt_silk[_silk_hash(__array_get(_path, _i))];
        let _ei = 0;
        while _ei < len(_edges) {
            if __array_get(_edges, _ei) == __array_get(_path, _i + 1) {
                let _hw = __array_get(_edges, _ei + 1);
                if _hw * 10 > _s { let _s = _hw * 10; };
            };
            let _ei = _ei + 6;
        };
        if _s < 1 { let _s = 1; };
        push(_strengths, _s);
        let _ = __set_at(_total, 0, __array_get(_total, 0) + _s);
        let _i = _i + 1;
    };
    let _t = __array_get(_total, 0);
    if _t == 0 { return 9999; };
    let _h = [0]; let _i = 0;
    while _i < len(_strengths) {
        let _p = __array_get(_strengths, _i) / _t;
        if _p > 0 { let _ = __set_at(_h, 0, __array_get(_h, 0) - _p * __log2(_p)); };
        let _i = _i + 1;
    };
    return __floor(__array_get(_h, 0) * 100);
}

// ═══ Path quality ═══
fn _path_quality(_path) {
    if len(_path) == 0 { return 0; };
    let _valid = 1000;
    let _i = 0;
    while _i < len(_path) {
        if __array_get(_path, _i) == 0 { let _valid = 0; };
        let _i = _i + 1;
    };
    let _h = _path_entropy(_path);
    let _h_norm = 1000 - __floor(_h * 1000 / 232);
    if _h_norm < 0 { let _h_norm = 0; };
    let _coherent = [0]; let _d = 0;
    while _d < 5 {
        let _sum = [0]; let _sum2 = [0]; let _n = len(_path); let _j = 0;
        while _j < _n {
            let _v = mol_get_dim(__array_get(_path, _j), _d);
            let _ = __set_at(_sum, 0, __array_get(_sum, 0) + _v);
            let _ = __set_at(_sum2, 0, __array_get(_sum2, 0) + _v * _v);
            let _j = _j + 1;
        };
        let _mean = __array_get(_sum, 0) / _n;
        let _var = __array_get(_sum2, 0) / _n - _mean * _mean;
        let _mr = 15; if _d >= 2 { let _mr = 7; }; if _d == 4 { let _mr = 3; };
        if _var < __floor(_mr * _mr / 4) { let _ = __set_at(_coherent, 0, __array_get(_coherent, 0) + 1); };
        let _d = _d + 1;
    };
    let _consistency = __floor(__array_get(_coherent, 0) * 200);
    let _silk_sum = [0]; let _i = 0;
    while _i < len(_path) - 1 {
        let _ = __set_at(_silk_sum, 0, __array_get(_silk_sum, 0) + implicit_strength(__array_get(_path, _i), __array_get(_path, _i + 1)));
        let _i = _i + 1;
    };
    let _silk_avg = 0;
    if len(_path) > 1 { let _silk_avg = __floor(__array_get(_silk_sum, 0) / (len(_path) - 1)); };
    if _silk_avg > 1000 { let _silk_avg = 1000; };
    return __floor(300 * _valid / 1000 + 300 * _h_norm / 1000 + 200 * _consistency / 1000 + 200 * _silk_avg / 1000);
}

// ═══ DCA DNA Repair (A5: Hebbian in safe signal) ═══
fn _dna_repair(_path, _query_mol) {
    let _best = _path;
    let _best_q = _path_quality(_path);
    let _iter = 0;
    while _iter < 3 {
        if _best_q >= 618 { return _best; };
        // Danger signals per segment
        let _worst_i = [0]; let _worst_k = [0 - 99999];
        let _si = 0;
        while _si < len(_best) {
            // Safe signal: silk support (implicit + Hebbian)
            let _ss = 0;
            if _si > 0 { let _ss = _ss + implicit_strength(__array_get(_best, _si - 1), __array_get(_best, _si)); };
            if _si < len(_best) - 1 { let _ss = _ss + implicit_strength(__array_get(_best, _si), __array_get(_best, _si + 1)); };
            let _ss = _ss / 2;
            // Danger signal: distance from query
            let _ds = _kt_mol_dist(__array_get(_best, _si), _query_mol) * 50;
            let _k = _ds - 2 * _ss;
            if _k > __array_get(_worst_k, 0) {
                let _ = __set_at(_worst_k, 0, _k);
                let _ = __set_at(_worst_i, 0, _si);
            };
            let _si = _si + 1;
        };
        let _wi = __array_get(_worst_i, 0);
        if _wi > 0 { if _wi < len(_best) {
            let _prev = __array_get(_best, _wi - 1);
            let _dim = mol_dominant_dim(_query_mol);
            let _alts = implicit_neighbors(_prev, _dim, 5);
            let _ai = 0;
            while _ai < len(_alts) {
                let _am = _kt_real_mol(__array_get(_alts, _ai));
                if _am != __array_get(_best, _wi) { if _am > 0 {
                    let _trial = []; let _ti = 0;
                    while _ti < len(_best) {
                        if _ti == _wi { push(_trial, _am); } else { push(_trial, __array_get(_best, _ti)); };
                        let _ti = _ti + 1;
                    };
                    let _tq = _path_quality(_trial);
                    if _tq > _best_q { let _best = _trial; let _best_q = _tq; };
                }; };
                let _ai = _ai + 1;
            };
        }; };
        let _iter = _iter + 1;
    };
    return _best;
}

// ═══ Decode ∂ — path → texts → maximal join (A6: mol-level) ═══
fn _decode_path(_path) {
    let _texts = []; let _i = 0;
    while _i < len(_path) {
        let _mol = __array_get(_path, _i);
        if _mol > 0 {
            let _fact = kt_nearest(_mol);
            if len(_fact) > 0 {
                let _dup = 0; let _j = 0;
                while _j < len(_texts) {
                    if __array_get(_texts, _j) == _fact { let _dup = 1; };
                    let _j = _j + 1;
                };
                if _dup == 0 { push(_texts, _fact); };
            };
        };
        let _i = _i + 1;
    };
    return _maximal_join(_texts);
}

// ═══ Maximal Join: merge texts removing overlapping words ═══
fn _maximal_join(_texts) {
    if len(_texts) == 0 { return ""; };
    if len(_texts) == 1 { return __array_get(_texts, 0); };
    let _result = __array_get(_texts, 0);
    let _ti = 1;
    while _ti < len(_texts) {
        let _add = __array_get(_texts, _ti);
        let _new = []; let _wi = 0; let _ws = [0];
        while _wi <= len(_add) {
            let _sp = 0;
            if _wi == len(_add) { let _sp = 1; } else {
                if __char_code(char_at(_add, _wi)) == 32 { let _sp = 1; };
            };
            if _sp == 1 {
                let _word = substr(_add, __array_get(_ws, 0), _wi);
                if len(_word) >= 3 {
                    let _found = [0]; let _ri = 0; let _rws = [0];
                    while _ri <= len(_result) {
                        let _rsp = 0;
                        if _ri == len(_result) { let _rsp = 1; } else {
                            if __char_code(char_at(_result, _ri)) == 32 { let _rsp = 1; };
                        };
                        if _rsp == 1 {
                            if substr(_result, __array_get(_rws, 0), _ri) == _word { let _ = __set_at(_found, 0, 1); };
                            let _ = __set_at(_rws, 0, _ri + 1);
                        };
                        let _ri = _ri + 1;
                    };
                    if __array_get(_found, 0) == 0 { push(_new, _word); };
                } else { if len(_word) > 0 { push(_new, _word); }; };
                let _ = __set_at(_ws, 0, _wi + 1);
            };
            let _wi = _wi + 1;
        };
        if len(_new) > 0 {
            let _extra = ""; let _pi = 0;
            while _pi < len(_new) {
                if _pi > 0 { let _extra = _extra + " "; };
                let _extra = _extra + __array_get(_new, _pi);
                let _pi = _pi + 1;
            };
            if len(_extra) > 0 { let _result = _result + ", " + _extra; };
        };
        let _ti = _ti + 1;
    };
    return _result;
}

// ═══ ConversationCurve V''(t) + tone ═══
fn _curve_accel() {
    let _n = __array_get(__v_idx, 0);
    if _n < 3 { return 0; };
    let _vp1 = __array_get(__v_history, (_n - 1) % 4) - __array_get(__v_history, (_n - 2) % 4);
    let _vp2 = __array_get(__v_history, (_n - 2) % 4) - __array_get(__v_history, (_n - 3) % 4);
    return _vp1 - _vp2;
}

fn _select_tone() {
    let _vd = _curve_deriv(); let _va = _curve_accel();
    if _vd < (0 - 1) { return "supportive"; };
    if _va < (0 - 2) { return "pause"; };
    if _vd > 1 { return "reinforcing"; };
    let _n = __array_get(__v_idx, 0);
    if _va > 2 { if __array_get(__v_history, (_n - 1) % 4) > 4 { return "celebratory"; }; };
    return "engaged";
}

fn _apply_tone(_text, _tone) {
    if len(_text) == 0 { return _text; };
    return _text;
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

    // ═══ STEP 7+8+11: Spreading Activation → CLONALG → DNA Repair → Decode ∂ ═══
    let _response = "";
    if len(_text_results) == 0 {
        if _nearest_mol > 0 {
            // A8: Homeostasis modulates activation parameters
            let _steps = 3; let _thresh = 80;
            if _surprise > _phi_inv { let _steps = 5; let _thresh = 30; };
            // Layer 2: Spreading Activation
            let _field = _spread_activate(_nearest_mol, _dim, _steps, _thresh);
            let _field_mols = __array_get(_field, 0);
            // Layer 3: CLONALG — 3 candidates, 3 generations
            let _candidates = _clonalg_generate(_field_mols, _mol, _dim);
            if len(_candidates) > 0 {
                // Pick lowest entropy
                let _best_path = __array_get(_candidates, 0);
                let _best_h = [_path_entropy(__array_get(_candidates, 0))];
                let _bi = 1;
                while _bi < len(_candidates) {
                    let _bh = _path_entropy(__array_get(_candidates, _bi));
                    if _bh < __array_get(_best_h, 0) {
                        let _ = __set_at(_best_h, 0, _bh);
                        let _best_path = __array_get(_candidates, _bi);
                    };
                    let _bi = _bi + 1;
                };
                // Layer 4: DCA DNA Repair
                let _repaired = _dna_repair(_best_path, _mol);
                wm_set(2, compose(_repaired));
                // Layer 5: Decode ∂ (SINH)
                let _generated = _decode_path(_repaired);
                if len(_generated) > 0 { let _response = _generated; };
            };
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

    // CP5: SecurityGate on OUTPUT (A10 — block unsafe generated content)
    if security_gate(_response) == 1 {
        wm_set(0, 0); wm_set(1, 0); wm_set(2, 0); wm_set(3, 0);
        return "";
    };

    // STEP 12: ConversationCurve tone
    let _tone = _select_tone();
    let _response = _apply_tone(_response, _tone);

    // A9: STM push output (track both sides for ConversationCurve)
    if len(_response) > 0 { kt_stm_push(_response); };

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
