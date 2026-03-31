// formula.ol — FE.1-3: Formula Engine (from Rust formula.rs)
// 16 RelationOps + 8 ValenceStates + 8 ArousalStates
// Each R/V/A value = INDEX into formula table with BEHAVIOR

// ═══ FE.1: RelationOp compose — 16 types from Category Theory ═══
// R value → how two P_weights compose
pub fn relation_compose(_r, _a, _b) {
    if _r == 0 { return _a; };                          // Identity: pass through
    if _r == 1 { return _b; };                          // Member: inherit container
    if _r == 2 { return _b; };                          // Subset: inherit container
    if _r == 3 { if _a == _b { return _a; }; return __bit_xor(_a, _b); }; // Equality: XOR blend
    if _r == 4 { if _a >= _b { return _a; }; return _b; }; // Order: larger wins
    // Arithmetic (ring): add dimensions mod range
    if _r == 5 { return _arith_compose(_a, _b); };
    if _r == 6 { return __bit_and(_a, _b); };           // Logical: AND
    if _r == 7 { return __bit_or(_a, _b); };            // SetOp: OR (union)
    // Compose (g∘f): a's R, b's rest
    if _r == 8 { return __bit_or(__bit_and(_b, 61695), __bit_and(_a, 3840)); };
    if _r == 9 { return _b; };                          // Causes: effect inherits
    if _r == 10 { return _approx_compose(_a, _b); };    // Approximate: midpoint
    if _r == 11 { return __bit_xor(_a, _b); };          // Orthogonal: XOR
    if _r == 12 { return _aggregate_compose(_a, _b); }; // Aggregate: sum clamped
    if _r == 13 { return _b; };                         // Directional: target
    if _r == 14 { return _a; };                         // Bracket: transparent
    // Inverse: bitwise complement within ranges
    if _r == 15 { return _inverse_compose(_a); };
    return _a;
}

fn _arith_compose(_a, _b) {
    let _s = __bit_and((_kt_mol_s(_a) + _kt_mol_s(_b)), 15);
    let _r = __bit_and((_kt_mol_r(_a) + _kt_mol_r(_b)), 15);
    let _v = __bit_and((_kt_mol_v(_a) + _kt_mol_v(_b)), 7);
    let _aa = __bit_and((_kt_mol_a(_a) + _kt_mol_a(_b)), 7);
    let _t = __bit_and((_kt_mol_t(_a) + _kt_mol_t(_b)), 3);
    return _kt_pack(_s, _r, _v, _aa, _t);
}

fn _approx_compose(_a, _b) {
    let _s = __floor((_kt_mol_s(_a) + _kt_mol_s(_b)) / 2);
    let _r = __floor((_kt_mol_r(_a) + _kt_mol_r(_b)) / 2);
    let _v = __floor((_kt_mol_v(_a) + _kt_mol_v(_b)) / 2);
    let _aa = __floor((_kt_mol_a(_a) + _kt_mol_a(_b)) / 2);
    let _t = __floor((_kt_mol_t(_a) + _kt_mol_t(_b)) / 2);
    return _kt_pack(_s, _r, _v, _aa, _t);
}

fn _aggregate_compose(_a, _b) {
    let _s = _kt_mol_s(_a) + _kt_mol_s(_b); if _s > 15 { let _s = 15; };
    let _r = _kt_mol_r(_a) + _kt_mol_r(_b); if _r > 15 { let _r = 15; };
    let _v = _kt_mol_v(_a) + _kt_mol_v(_b); if _v > 7 { let _v = 7; };
    let _aa = _kt_mol_a(_a) + _kt_mol_a(_b); if _aa > 7 { let _aa = 7; };
    let _t = _kt_mol_t(_a) + _kt_mol_t(_b); if _t > 3 { let _t = 3; };
    return _kt_pack(_s, _r, _v, _aa, _t);
}

fn _inverse_compose(_a) {
    return _kt_pack(15 - _kt_mol_s(_a), 15 - _kt_mol_r(_a), 7 - _kt_mol_v(_a), 7 - _kt_mol_a(_a), 3 - _kt_mol_t(_a));
}

// ═══ FE.2: ValenceState — 8 potential energy levels ═══
// V value → potential energy + force (approach/avoid tendency)
// potential×1000, force×1000 (integer arithmetic)
pub fn valence_potential(_v) {
    if _v == 0 { return 850; };    // HighBarrier: +0.85 (strong repel)
    if _v == 1 { return 400; };    // LowBarrier: +0.4
    if _v == 2 { return 150; };    // MildBarrier: +0.15
    if _v == 3 { return 0; };      // Flat: 0
    if _v == 4 { return 0; };      // MildWell: 0
    if _v == 5 { return 0 - 350; }; // ShallowWell: -0.35 (attract)
    if _v == 6 { return 0 - 750; }; // DeepWell: -0.75
    if _v == 7 { return 0 - 950; }; // VeryDeepWell: -0.95
    return 0;
}

pub fn valence_force(_v) {
    if _v == 0 { return 0 - 900; }; // repel
    if _v == 1 { return 0 - 400; };
    if _v == 2 { return 0 - 150; };
    if _v == 3 { return 0; };
    if _v == 4 { return 0; };
    if _v == 5 { return 350; };      // attract
    if _v == 6 { return 800; };
    if _v == 7 { return 950; };
    return 0;
}

// ═══ FE.3: ArousalState — 8 energy regimes ═══
// A value → energy level + damping coefficient
// energy×1000, damping×1000
pub fn arousal_energy(_a) {
    if _a == 0 { return 0; };       // GroundState: E₀
    if _a == 1 { return 50; };      // HeatDeath: near zero
    if _a == 2 { return 150; };     // Overdamped: slow decay
    if _a == 3 { return 350; };     // Equilibrium: thermal
    if _a == 4 { return 450; };     // MildEquilibrium
    if _a == 5 { return 650; };     // ExcitedLow: oscillating
    if _a == 6 { return 850; };     // ExcitedHigh: resonance
    if _a == 7 { return 1000; };    // Supercritical: explosion
    return 350;
}

pub fn arousal_damping(_a) {
    if _a == 0 { return 1000; };    // frozen
    if _a == 1 { return 900; };     // exhausted
    if _a == 2 { return 700; };     // heavily damped
    if _a == 3 { return 500; };     // equilibrium
    if _a == 4 { return 400; };     // mild
    if _a == 5 { return 200; };     // lightly damped
    if _a == 6 { return 50; };      // near resonance
    if _a == 7 { return 0; };       // no damping (explosion)
    return 500;
}

// ═══ Relation properties ═══
pub fn relation_is_symmetric(_r) {
    if _r == 0 { return 1; }; // Identity
    if _r == 3 { return 1; }; // Equality
    if _r == 5 { return 1; }; // Arithmetic
    if _r == 6 { return 1; }; // Logical
    if _r == 7 { return 1; }; // SetOp
    if _r == 10 { return 1; }; // Approximate
    if _r == 11 { return 1; }; // Orthogonal
    return 0;
}

pub fn relation_is_transitive(_r) {
    if _r == 0 { return 1; }; // Identity
    if _r == 2 { return 1; }; // Subset
    if _r == 3 { return 1; }; // Equality
    if _r == 4 { return 1; }; // Order
    if _r == 8 { return 1; }; // Compose
    if _r == 9 { return 1; }; // Causes
    return 0;
}
