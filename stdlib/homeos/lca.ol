// lca.ol — v2 Compose Engine (from Rust lca.rs)
// LCA(a, b) → parent. Sinh hoc — KHONG trung binh.
// S=Union, R=Compose, V=Amplify, A=Max, T=Dominant

// Compose 2 mols into LCA (biological, not average)
pub fn mol_lca(_a, _b) {
    // S = Union = max (CSG union of shapes)
    let _sa = _kt_mol_s(_a); let _sb = _kt_mol_s(_b);
    let _S = _sa; if _sb > _sa { let _S = _sb; };

    // R = use relation_compose from Formula Engine (16 typed operations)
    let _ra = _kt_mol_r(_a);
    let _composed = relation_compose(_ra, _a, _b);
    let _R = _kt_mol_r(_composed);

    // V = Amplify synergy (NOT average!)
    let _va = _kt_mol_v(_a); let _vb = _kt_mol_v(_b);
    let _base = __floor((_va + _vb) / 2);
    let _dev = _kt_abs(_va - _base);
    let _boost = __floor(_dev / 2);  // synergy boost
    let _dir = 0; if (_va + _vb) > 8 { let _dir = 1; } else { let _dir = 0 - 1; };
    let _V = _base + (_dir * _boost);
    if _V > 7 { let _V = 7; };
    if _V < 0 { let _V = 0; };

    // A = max (take higher intensity)
    let _aa = _kt_mol_a(_a); let _ab = _kt_mol_a(_b);
    let _A = _aa; if _ab > _aa { let _A = _ab; };

    // T = dominant (majority vote, first if tie)
    let _ta = _kt_mol_t(_a); let _tb = _kt_mol_t(_b);
    let _T = _ta;

    return _kt_pack(_S, _R, _V, _A, _T);
}

// Variance between two mols (how different are they)
// Returns 0-1000: 0=identical, 1000=maximally different
pub fn mol_variance(_a, _b) {
    let _ds = _kt_abs(_kt_mol_s(_a) - _kt_mol_s(_b)) * 67;  // /15 * 1000
    let _dr = _kt_abs(_kt_mol_r(_a) - _kt_mol_r(_b)) * 67;
    let _dv = _kt_abs(_kt_mol_v(_a) - _kt_mol_v(_b)) * 143; // /7 * 1000
    let _da = _kt_abs(_kt_mol_a(_a) - _kt_mol_a(_b)) * 143;
    let _dt = _kt_abs(_kt_mol_t(_a) - _kt_mol_t(_b)) * 333; // /3 * 1000
    return __floor((_ds + _dr + _dv + _da + _dt) / 5);
}

// Extremity: how far from neutral (midpoint) on V+A
// Returns 0-1000: 0=neutral, 1000=extremely positive/negative
pub fn mol_extremity(_mol) {
    let _v = _kt_mol_v(_mol);
    let _a = _kt_mol_a(_mol);
    let _vext = _kt_abs(_v - 4) * 250;  // /4 * 1000
    let _aext = _kt_abs(_a - 4) * 250;
    return __floor((_vext + _aext) / 2);
}

// Classify abstraction level from variance
// Returns: 0=concrete (<150), 1=categorical (<400), 2=abstract (>=400)
pub fn mol_abstraction(_variance) {
    if _variance < 150 { return 0; };
    if _variance < 400 { return 1; };
    return 2;
}
