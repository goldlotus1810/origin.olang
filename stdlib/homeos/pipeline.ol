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

// G8: Pipeline (simplified — wire G2-G11 together)
pub fn pipeline(input) {
    // CP1: SecurityGate
    if security_gate(input) == 1 {
        return "Neu ban can ho tro, xin goi 1800 599 920";
    };

    // Encode
    let _mol = _kt_real_mol(input);
    let _v = mol_get_dim(_mol, 2);
    // NRC-VAD: check first word for real V/A
    let _space = __str_index_of(input, " ");
    if _space < 0 { let _space = len(input); };
    let _first_word = substr(input, 0, _space);
    let _vad = vad_query(_first_word);
    if __array_get(_vad, 0) != 0 {
        // Real NRC-VAD data → use it
        let _real_v = __array_get(_vad, 0);  // v * 1000
        let _v = __floor((_real_v + 1000) * 7 / 2000);
        if _v > 7 { let _v = 7; };
        if _v < 0 { let _v = 0; };
    };
    _curve_push_v(_v);

    // Search: find first word ≥4 chars, search by that word
    let _text_results = [];
    let _sw = [0]; let _si = 0;
    while _si <= len(input) {
        let _is_sp = 0;
        if _si == len(input) { let _is_sp = 1; } else {
            if __char_code(char_at(input, _si)) == 32 { let _is_sp = 1; };
        };
        if _is_sp == 1 {
            let _word = substr(input, __array_get(_sw, 0), _si);
            if len(_word) >= 3 {
                let _wresults = kt_find(_word, 3);
                let _wi = 0;
                while _wi < len(_wresults) {
                    push(_text_results, __array_get(_wresults, _wi));
                    let _wi = _wi + 1;
                };
                if len(_text_results) > 0 { let _si = len(input); };
            };
            let _ = __set_at(_sw, 0, _si + 1);
        };
        let _si = _si + 1;
    };
    let _result = "";
    if len(_text_results) > 0 {
        let _result = __array_get(_text_results, 0);
    } else {
        let _result = kt_nearest(_mol);
    };

    // Homeostasis
    let _nearest_mol = 0;
    if len(_result) > 0 { let _nearest_mol = _kt_real_mol(_result); };
    let _surprise = _homeostasis(_mol, _nearest_mol);

    // LEARNING LOOP: fire silk between input ↔ ALL matching facts
    // + between matching facts with each other (cross-connect)
    if _nearest_mol > 0 { kt_silk_fire(_mol, _nearest_mol); };
    let _ri = 0;
    while _ri < len(_text_results) {
        let _rmol = _kt_real_mol(__array_get(_text_results, _ri));
        kt_silk_fire(_mol, _rmol);  // input ↔ each result
        // Cross-connect results with each other
        if _ri > 0 {
            let _prev_rmol = _kt_real_mol(__array_get(_text_results, _ri - 1));
            kt_silk_fire(_rmol, _prev_rmol);
        };
        let _ri = _ri + 1;
    };

    // Honesty check
    let _conf = instinct_honesty(_mol);
    if _conf < 400 {
        if len(_result) == 0 { return ""; };
    };

    // STM push
    kt_stm_push(input);

    // Dream check (every 8 turns)
    if (__array_get(__v_idx, 0) % 8) == 0 { dream(); };

    // ConversationCurve tone
    let _tone = _curve_tone();

    return _result;
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
