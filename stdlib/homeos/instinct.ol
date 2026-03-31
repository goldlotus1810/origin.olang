// homeos/instinct.ol — G9: 7 Instinct Formulas on 5D
// ALL formulas. NO if/else on keywords. Pure P_weight math.

// G9①: Honesty — confidence from evidence
// Uses result count from pipeline, not mol-based nearest (avoids mol mismatch)
pub fn instinct_honesty_with_results(_mol, _result_count) {
    if _result_count == 0 { return 0; };
    // More results = more confident (evidence-based)
    let _evidence = _result_count * 250;
    if _evidence > 700 { let _evidence = 700; };
    // Silk check: any edge from this mol?
    let _sw = 0;
    let _edges = __kt_silk[_silk_hash(_mol)];
    if len(_edges) > 0 { let _sw = 200; };
    // Fact density
    let _density = kt_fact_count() / 50;
    if _density > 300 { let _density = 300; };
    return _evidence + _sw + _density;  // 0-1200, but typically 250-1000
}
// Backward compat
pub fn instinct_honesty(_mol) { return instinct_honesty_with_results(_mol, 0); }

// G9②: Contradiction — V distance + same topic
pub fn instinct_contradiction(_a_mol, _b_mol) {
    let _dv = _kt_abs(mol_get_dim(_a_mol, 2) - mol_get_dim(_b_mol, 2));
    let _dr = _kt_abs(mol_get_dim(_a_mol, 1) - mol_get_dim(_b_mol, 1));
    // V very different (>5) + R very similar (<3) = contradiction
    if _dv > 5 { if _dr < 3 { return 1; }; };
    return 0;
}

// G9⑥: Curiosity — novelty = distance from known
pub fn instinct_curiosity(_mol) {
    let _near = kt_nearest(_mol);
    if len(_near) == 0 { return 1000; };  // completely novel
    let _d = _kt_mol_dist(_mol, _kt_real_mol(_near));
    // Higher distance = more novel
    let _novelty = _d * 200;
    if _novelty > 1000 { let _novelty = 1000; };
    return _novelty;  // >500 = explore, <300 = familiar
}

// G9③: Causality — temporal order + silk + R causal type
pub fn instinct_causality(_a_mol, _b_mol) {
    // R=9 (Causes) or high R similarity + silk connection
    let _ra = _kt_mol_r(_a_mol);
    let _rb = _kt_mol_r(_b_mol);
    let _sw = kt_silk_weight(_a_mol, _b_mol);
    let _causal_r = 0;
    if _ra >= 8 { if _ra <= 13 { let _causal_r = 1; }; };
    // Evidence: silk > 0 (co-activated) + causal R range + temporal (implicit from order)
    let _evidence = 0;
    if _sw > 0 { let _evidence = _evidence + 1; };
    if _causal_r == 1 { let _evidence = _evidence + 1; };
    if _kt_abs(_ra - _rb) < 3 { let _evidence = _evidence + 1; };
    return _evidence;  // >= 2 = likely causal
}

// G9④: Abstraction — variance in cluster → concrete/categorical/abstract
pub fn instinct_abstraction(_a_mol, _b_mol) {
    let _var = mol_variance(_a_mol, _b_mol);
    return mol_abstraction(_var);  // 0=concrete, 1=categorical, 2=abstract
}

// G9⑤: Analogy — vector arithmetic in 5D: a:b :: c:? → d = c + (b-a)
pub fn instinct_analogy(_a, _b, _c) {
    let _ds = _kt_mol_s(_b) - _kt_mol_s(_a);
    let _dr = _kt_mol_r(_b) - _kt_mol_r(_a);
    let _dv = _kt_mol_v(_b) - _kt_mol_v(_a);
    let _da = _kt_mol_a(_b) - _kt_mol_a(_a);
    let _dt = _kt_mol_t(_b) - _kt_mol_t(_a);
    let _s = _kt_mol_s(_c) + _ds; if _s > 15 { let _s = 15; }; if _s < 0 { let _s = 0; };
    let _r = _kt_mol_r(_c) + _dr; if _r > 15 { let _r = 15; }; if _r < 0 { let _r = 0; };
    let _v = _kt_mol_v(_c) + _dv; if _v > 7 { let _v = 7; }; if _v < 0 { let _v = 0; };
    let _a = _kt_mol_a(_c) + _da; if _a > 7 { let _a = 7; }; if _a < 0 { let _a = 0; };
    let _t = _kt_mol_t(_c) + _dt; if _t > 3 { let _t = 3; }; if _t < 0 { let _t = 0; };
    return _kt_pack(_s, _r, _v, _a, _t);
}

// G9⑦: Reflection — self-assessment quality
pub fn instinct_reflection() {
    let _total = kt_fact_count();
    if _total == 0 { return 0; };
    // Count mature facts
    let _mature = [0];
    let _i = 0;
    while _i < _total {
        if kt_maturity(_i) == 2 { let _ = __set_at(_mature, 0, __array_get(_mature, 0) + 1); };
        let _i = _i + 100;  // sample every 100th for speed
    };
    let _qr_ratio = __array_get(_mature, 0) * 1000 / (__floor(_total / 100) + 1);
    return _qr_ratio;  // 0-1000: how much knowledge is mature
}

// G10: SecurityGate — check REAL V/A from P_weight (not hash)
pub fn security_gate(_text) {
    // Use per-char P_weight V/A (not _kt_real_mol which uses hash)
    let _min_v = [7];
    let _max_a = [0];
    let _i = 0;
    while _i < len(_text) {
        let _cp = __char_code(char_at(_text, _i));
        let _pw = p_weight(_cp);
        if _pw > 0 {
            let _v = (__floor(_pw / 32)) % 8;
            let _a = (__floor(_pw / 4)) % 8;
            if _v < __array_get(_min_v, 0) { let _ = __set_at(_min_v, 0, _v); };
            if _a > __array_get(_max_a, 0) { let _ = __set_at(_max_a, 0, _a); };
        };
        let _i = _i + 1;
    };
    // Crisis: min V across ALL chars ≤ 1 AND max A ≥ 6
    if __array_get(_min_v, 0) <= 1 { if __array_get(_max_a, 0) >= 6 { return 1; }; };
    return 0;
}

// Route: returns {instinct, confidence, v, a}
pub fn instinct_route(input) {
    let _mol = _kt_real_mol(input);
    let _v = mol_get_dim(_mol, 2);
    let _a = mol_get_dim(_mol, 3);
    let _conf = instinct_honesty(_mol);
    let _novel = instinct_curiosity(_mol);
    let _dim = mol_dominant_dim(_mol);
    // Return structured result
    let _result = [];
    push(_result, _conf);   // [0] confidence
    push(_result, _v);      // [1] V
    push(_result, _a);      // [2] A
    push(_result, _dim);    // [3] dominant dimension
    push(_result, _novel);  // [4] novelty
    return _result;
}

pub fn instinct_act(result, input) {
    // Based on confidence and novelty, choose response strategy
    if len(result) < 5 { return kt_search(input); };
    let _conf = __array_get(result, 0);
    if _conf < 400 { return ""; };  // silence (honesty)
    return kt_search(input);
}
