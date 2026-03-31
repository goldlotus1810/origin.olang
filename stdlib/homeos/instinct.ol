// homeos/instinct.ol — G9: 7 Instinct Formulas on 5D
// ALL formulas. NO if/else on keywords. Pure P_weight math.

// G9①: Honesty — confidence from evidence
pub fn instinct_honesty(_mol) {
    let _near = kt_nearest(_mol);
    if len(_near) == 0 { return 0; };
    let _near_mol = _kt_real_mol(_near);
    let _sw = kt_silk_weight(_mol, _near_mol);
    let _dist = _kt_mol_dist(_mol, _near_mol);
    // Closer = higher confidence, silk = higher confidence
    let _proximity = 1000 - (_dist * 40);
    if _proximity < 0 { let _proximity = 0; };
    let _silk_score = _sw;
    let _conf = (_proximity * 300 + _silk_score * 700) / 1000;
    return _conf;  // 0-1000, threshold: 400=silence, 700=think, 900=fact
}

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
