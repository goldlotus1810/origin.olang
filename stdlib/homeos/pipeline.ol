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

    // 3c: Silk walk on dominant dimension (reasoning — follow connections)
    let _walk = kt_silk_walk_dim(_mol, _dim, 3, 10);
    let _wi = 1;
    while _wi < len(_walk) {
        let _wmol = __array_get(_walk, _wi);
        if _kt_mol_dist(_mol, _wmol) < 8 {
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

    // STEP 10: Dream (periodic consolidation)
    if (__array_get(__v_idx, 0) % 8) == 0 { dream(); };

    // STEP 13: STM push
    kt_stm_push(input);

    // STEP 11: If learn mode + no results → learn this input
    if _learn_mode == 1 {
        if len(_text_results) == 0 { kt_learn(input); };
    };

    // STEP 12: Compose response — dedup, max 3
    let _seen = [];
    let _response = "";
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

    if len(_response) == 0 { wm_set(0, 0); wm_set(1, 0); wm_set(2, 0); wm_set(3, 0); return ""; };

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
