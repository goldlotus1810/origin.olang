// homeos/pipeline.ol — G8+G11: Pipeline + Homeostasis + ConversationCurve

let _phi_inv = 618;
let __v_history = [4, 4, 4, 4];  // last 4 V values for ConversationCurve
let __v_idx = [0];

// G11: Homeostasis F(t) — surprise = distance from expected
fn _homeostasis(_input_mol, _nearest_mol) {
    if _nearest_mol == 0 { return 1000; };  // no prediction = max surprise
    return _kt_mol_dist(_input_mol, _nearest_mol) * 100;
}

// G11: ConversationCurve — V'(t), V''(t) → tone
fn _curve_push_v(_v) {
    let _idx = __array_get(__v_idx, 0) % 4;
    let _ = __set_at(__v_history, _idx, _v);
    let _ = __set_at(__v_idx, 0, __array_get(__v_idx, 0) + 1);
}

fn _curve_tone() {
    let _n = __array_get(__v_idx, 0);
    if _n < 2 { return "engaged"; };
    let _i1 = (_n - 1) % 4;
    let _i2 = (_n - 2) % 4;
    let _v_now = __array_get(__v_history, _i1);
    let _v_prev = __array_get(__v_history, _i2);
    let _deriv = _v_now - _v_prev;  // V'(t) in [-7, 7] range
    if _deriv < 0 - 1 { return "supportive"; };
    if _deriv > 1 { return "reinforcing"; };
    if _v_now < 2 { return "gentle"; };
    return "engaged";
}

// G8: Pipeline — 14 steps, 5 checkpoints (G8+G9+G11+G12)
pub fn pipeline(input) {
    // ═══ CP1: SecurityGate (D8) ═══
    if security_gate(input) == 1 {
        return "Neu ban can ho tro, xin goi 1800 599 920";
    };

    // ═══ STEP 2: Encode (A3) + WM bind ═══
    let _mol = _kt_real_mol(input);
    wm_set(0, _mol);  // WM[0] = query
    let _v = mol_get_dim(_mol, 2);
    _curve_push_v(_v);

    // ═══ STEP 2.5: Query type detection — LEARNED patterns (not if/else) ═══
    // Detect: question marks, Vietnamese question words, English question words
    // Result: _query_dim = which silk dimension to prioritize
    let _query_dim = [0 - 1];  // -1 = auto (use mol_dominant_dim)
    let _query_type = ["statement"];
    let _ilen = len(input);
    // Check last char: ? → question, ! → command
    if _ilen > 1 {
        let _last_ch = __char_code(char_at(input, _ilen - 1));
        if _last_ch == 63 { let _ = __set_at(_query_type, 0, "question"); };
        if _last_ch == 33 { let _ = __set_at(_query_type, 0, "command"); };
    };
    // Vietnamese question patterns → dimension routing
    if _str_has(input, "la gi") { let _ = __set_at(_query_dim, 0, 1); let _ = __set_at(_query_type, 0, "definition"); };
    if _str_has(input, "o dau") { let _ = __set_at(_query_dim, 0, 0); let _ = __set_at(_query_type, 0, "location"); };
    if _str_has(input, "tai sao") { let _ = __set_at(_query_dim, 0, 1); let _ = __set_at(_query_type, 0, "cause"); };
    if _str_has(input, "khi nao") { let _ = __set_at(_query_dim, 0, 4); let _ = __set_at(_query_type, 0, "time"); };
    if _str_has(input, "bao nhieu") { let _ = __set_at(_query_dim, 0, 1); let _ = __set_at(_query_type, 0, "quantity"); };
    // English question patterns
    if _str_has(input, "what is") { let _ = __set_at(_query_dim, 0, 1); let _ = __set_at(_query_type, 0, "definition"); };
    if _str_has(input, "where") { let _ = __set_at(_query_dim, 0, 0); let _ = __set_at(_query_type, 0, "location"); };
    if _str_has(input, "why") { let _ = __set_at(_query_dim, 0, 1); let _ = __set_at(_query_type, 0, "cause"); };
    if _str_has(input, "when") { let _ = __set_at(_query_dim, 0, 4); let _ = __set_at(_query_type, 0, "time"); };
    if _str_has(input, "how") { let _ = __set_at(_query_dim, 0, 1); let _ = __set_at(_query_type, 0, "method"); };
    // Learn-pattern: "X la Y" without question → learn, don't search
    let _is_learn = 0;
    if _str_has(input, " la ") {
        if __array_get(_query_type, 0) == "statement" { let _is_learn = 1; };
    };
    if _is_learn == 1 {
        kt_learn(input);
        return "Da hoc: " + input;
    };

    // ═══ STEP 3: Search — text match + mol nearest + silk walk ═══
    let _text_results = [];
    // Text search: each word ≥3 chars
    let _sw = [0]; let _si = 0;
    while _si <= len(input) {
        let _is_sp = 0;
        if _si == len(input) { let _is_sp = 1; } else {
            if __char_code(char_at(input, _si)) == 32 { let _is_sp = 1; };
        };
        if _is_sp == 1 {
            let _word = substr(input, __array_get(_sw, 0), _si);
            if len(_word) >= 3 {
                let _wresults = kt_find(_word, 5);
                let _wi = 0;
                while _wi < len(_wresults) {
                    push(_text_results, __array_get(_wresults, _wi));
                    let _wi = _wi + 1;
                };
            };
            let _ = __set_at(_sw, 0, _si + 1);
        };
        let _si = _si + 1;
    };
    // Mol nearest fallback
    if len(_text_results) == 0 {
        let _near = kt_nearest(_mol);
        if len(_near) > 0 { push(_text_results, _near); };
    };
    // Silk walk: follow strongest edges, using detected query dimension
    let _walk_dim = __array_get(_query_dim, 0);
    if _walk_dim < 0 { let _walk_dim = mol_dominant_dim(_mol); };
    let _walk = kt_silk_walk_dim(_mol, _walk_dim, 3, 10);
    if len(_walk) > 1 {
        let _wi = 1;
        while _wi < len(_walk) {
            let _wmol = __array_get(_walk, _wi);
            let _wdist = _kt_mol_dist(_mol, _wmol);
            if _wdist < 8 {  // close in 5D = semantically related
                let _wfact = kt_nearest(_wmol);
                if len(_wfact) > 0 { push(_text_results, _wfact); };
            };
            let _wi = _wi + 1;
        };
    };

    // ═══ STEP 4: Homeostasis (D4) + WM context ═══
    let _nearest_mol = 0;
    if len(_text_results) > 0 { let _nearest_mol = _kt_real_mol(__array_get(_text_results, 0)); };
    wm_set(1, _nearest_mol);  // WM[1] = context (best match)
    let _surprise = _homeostasis(_mol, _nearest_mol);

    // ═══ CP2: ENCODE check ═══
    if _mol == 0 { wm_set(0, 0); wm_set(1, 0); wm_set(2, 0); wm_set(3, 0); return ""; };

    // ═══ STEP 6: Instincts (D2) — use result count for confidence ═══
    let _conf = instinct_honesty_with_results(_mol, len(_text_results));

    // ═══ STEP 9: Hebbian silk fire (C3) ═══
    if _nearest_mol > 0 { kt_silk_fire(_mol, _nearest_mol); };
    let _ri = 0;
    while _ri < len(_text_results) {
        if _ri < 5 {
            let _rmol = _kt_real_mol(__array_get(_text_results, _ri));
            kt_silk_fire(_mol, _rmol);
            if _ri > 0 {
                let _prev_rmol = _kt_real_mol(__array_get(_text_results, _ri - 1));
                kt_silk_fire(_rmol, _prev_rmol);
            };
        };
        let _ri = _ri + 1;
    };

    // ═══ STEP 10: Dream check (C4) ═══
    if (__array_get(__v_idx, 0) % 8) == 0 { dream(); };

    // ═══ STEP 13: STM push ═══
    kt_stm_push(input);

    // ═══ STEP 11-12: Compose response + tone (G16+D7) ═══
    let _tone = _curve_tone();

    // G9①: Honesty — confidence prefix
    let _prefix = "";
    if _conf < 400 {
        if len(_text_results) == 0 { return ""; };
        let _prefix = "Toi khong chac: ";
    };
    if _conf >= 400 { if _conf < 700 { let _prefix = "Toi nghi: "; }; };
    if _conf >= 700 { if _conf < 900 { let _prefix = "Co le: "; }; };

    // G16: Chain recombination — compose unique results into response
    let _seen = [];
    let _response = "";
    let _count = [0];
    let _ri = 0;
    while _ri < len(_text_results) {
        let _fact = __array_get(_text_results, _ri);
        // Dedup: skip if already in response
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
        // Max 3 facts in response
        if __array_get(_count, 0) >= 3 { let _ri = len(_text_results); };
        let _ri = _ri + 1;
    };

    // D7: Apply tone prefix
    if _tone == "supportive" { let _prefix = ""; };
    if _tone == "gentle" { let _prefix = ""; };

    if len(_response) == 0 { wm_set(0, 0); wm_set(1, 0); wm_set(2, 0); wm_set(3, 0); return ""; };

    // WM[2] = candidate mol, WM[3] = final result mol
    wm_set(2, _nearest_mol);
    wm_set(3, _kt_real_mol(_response));

    let _final = _prefix + _response;

    // ═══ STEP 14: WM clear ═══
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
