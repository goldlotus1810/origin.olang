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
    _curve_push_v(_v);

    // Search (molecular first, text fallback)
    let _result = kt_nearest(_mol);
    if len(_result) == 0 { let _result = kt_find(input, 1); if len(_result) > 0 { let _result = __array_get(_result, 0); }; };

    // Homeostasis
    let _nearest_mol = 0;
    if len(_result) > 0 { let _nearest_mol = _kt_real_mol(_result); };
    let _surprise = _homeostasis(_mol, _nearest_mol);

    // Hebbian: fire silk between input and nearest
    if _nearest_mol > 0 { kt_silk_fire(_mol, _nearest_mol); };

    // Honesty check
    let _conf = instinct_honesty(_mol);
    if _conf < 400 {
        if len(_result) == 0 { return ""; };
    };

    // STM push
    stm_push(input);

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
