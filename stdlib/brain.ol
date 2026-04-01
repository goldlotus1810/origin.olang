// ═══ brain.ol — Nox Brain: Pipeline 5 tầng + PTAV ═══
// Uses: knowtree (kt_*), silk (silk_*), encode (encode.ol)
// Pipeline: Capture → Activate → Hypothesize → Repair → Decode

// ── Mol helpers ──
fn mol_pack(s, r, v, a, t) { return s * 4096 + r * 256 + v * 32 + a * 4 + t; };
fn mol_s(m) { return __floor(m / 4096) % 16; };
fn mol_r(m) { return __floor(m / 256) % 16; };
fn mol_v(m) { return __floor(m / 32) % 8; };
fn mol_a(m) { return __floor(m / 4) % 8; };
fn mol_t(m) { return m % 4; };
fn mol_dist(a, b) {
    let ds = mol_s(a) - mol_s(b); if ds < 0 { let ds = 0 - ds; };
    let dr = mol_r(a) - mol_r(b); if dr < 0 { let dr = 0 - dr; };
    let dv = mol_v(a) - mol_v(b); if dv < 0 { let dv = 0 - dv; };
    let da = mol_a(a) - mol_a(b); if da < 0 { let da = 0 - da; };
    let dt = mol_t(a) - mol_t(b); if dt < 0 { let dt = 0 - dt; };
    return ds + dr + dv * 2 + da * 2 + dt * 4;
};

// ── Layer 1: CAPTURE ──
fn brain_capture(input) {
    let mol = kt_encode_mol(input);
    __wm_bind(0, mol);  // WM[0] = query mol
    return mol;
};

// ── Security Gate (BP6 §1) ──
fn brain_security(mol) {
    if mol_v(mol) < 2 { if mol_a(mol) > 5 { return 1; }; };
    if __bloom_check(mol) > 0 { return 2; };
    return 0;
};

// ── Layer 2: ACTIVATE (follow silk edges + KnowTree nearest) ──
fn brain_activate(mol) {
    // Get top-3 nearest from KnowTree
    let nearest = kt_nearest(mol, 3);
    if len(nearest) == 0 { return []; };

    // Collect activated mols from nearest results
    let activated = [];
    let i = 0;
    while i < len(nearest) {
        let fact_text = __array_get(nearest, i);
        let fact_dist = __array_get(nearest, i + 1);
        let fact_mol = kt_encode_mol(fact_text);
        // Activation = inverse of distance (closer = higher)
        let act = 1000 - fact_dist * 10;
        if act < 100 { let act = 100; };
        push(activated, fact_mol);
        push(activated, act);
        // Follow silk edges from this fact
        let sw = silk_weight(mol, fact_mol);
        if sw > 0 {
            // Boost activation by silk strength
            let boost = __floor(sw * 500 / 65535);
            let _ = __set_at(activated, len(activated) - 1, act + boost);
        };
        let i = i + 2;
    };
    return activated;
};

// ── Instinct: Honesty (BP6 §1) — confidence from evidence ──
fn instinct_honesty(result_count, silk_strength) {
    // 0.3×results + 0.3×silk + 0.2×fire + 0.2×consistency
    let conf = result_count * 300 + __floor(silk_strength * 300 / 65535);
    if conf > 1000 { let conf = 1000; };
    return conf;
};

// ── Instinct: Curiosity (BP6 §6) — novelty ──
fn instinct_curiosity(mol, nearest_dist) {
    // novelty = 1 - (dist / max_dist)
    let novelty = 1000 - nearest_dist * 14;  // max_dist ≈ 70
    if novelty < 0 { let novelty = 0; };
    // > 500 → explore, < 300 → familiar
    return novelty;
};

// ── Instinct: Contradiction (BP6 §2) — V distance + same topic ──
fn instinct_contradiction(a, b) {
    let dv = mol_v(a) - mol_v(b); if dv < 0 { let dv = 0 - dv; };
    let dr = mol_r(a) - mol_r(b); if dr < 0 { let dr = 0 - dr; };
    // Opposite valence + same topic
    if dv > 4 { if dr < 3 { return 1; }; };
    return 0;
};

// ── Instinct: Analogy (BP6 §5) — vector arithmetic in 5D ──
// a:b :: c:? → d = c + (b - a)
fn instinct_analogy(a, b, c) {
    let ds = mol_s(b) - mol_s(a) + mol_s(c);
    let dr = mol_r(b) - mol_r(a) + mol_r(c);
    let dv = mol_v(b) - mol_v(a) + mol_v(c);
    let da = mol_a(b) - mol_a(a) + mol_a(c);
    let dt = mol_t(b) - mol_t(a) + mol_t(c);
    // Clamp
    if ds < 0 { let ds = 0; }; if ds > 15 { let ds = 15; };
    if dr < 0 { let dr = 0; }; if dr > 15 { let dr = 15; };
    if dv < 0 { let dv = 0; }; if dv > 7 { let dv = 7; };
    if da < 0 { let da = 0; }; if da > 7 { let da = 7; };
    if dt < 0 { let dt = 0; }; if dt > 3 { let dt = 3; };
    return mol_pack(ds, dr, dv, da, dt);
};

// ── Instinct: Abstraction (BP6 §4) — variance in cluster ──
fn instinct_abstraction(mols, count) {
    if count < 2 { return 0; };
    // Compute center
    let cs = [0]; let cr = [0]; let cv = [0]; let ca = [0]; let ct = [0];
    let i = 0;
    while i < count {
        let m = __array_get(mols, i * 2);
        let _ = __set_at(cs, 0, __array_get(cs, 0) + mol_s(m));
        let _ = __set_at(cr, 0, __array_get(cr, 0) + mol_r(m));
        let _ = __set_at(cv, 0, __array_get(cv, 0) + mol_v(m));
        let _ = __set_at(ca, 0, __array_get(ca, 0) + mol_a(m));
        let _ = __set_at(ct, 0, __array_get(ct, 0) + mol_t(m));
        let i = i + 1;
    };
    let center = mol_pack(
        __floor(__array_get(cs, 0) / count),
        __floor(__array_get(cr, 0) / count),
        __floor(__array_get(cv, 0) / count),
        __floor(__array_get(ca, 0) / count),
        __floor(__array_get(ct, 0) / count)
    );
    // Compute variance (sum of distances from center)
    let var = [0];
    let i = 0;
    while i < count {
        let d = mol_dist(__array_get(mols, i * 2), center);
        let _ = __set_at(var, 0, __array_get(var, 0) + d * d);
        let i = i + 1;
    };
    return __floor(__array_get(var, 0) / count);
    // < 10 → concrete, < 30 → categorical, ≥ 30 → abstract
};

// ── Instinct: Reflection (BP6 §7) ──
fn instinct_reflection(fact_count, silk_count) {
    if fact_count == 0 { return 0; };
    return __floor(silk_count * 1000 / fact_count);
};

// ── Layer 3: HYPOTHESIZE (pick best from activated) ──
fn brain_hypothesize(activated, query_mol) {
    if len(activated) == 0 { return ""; };
    // Best = closest activated mol to query
    let best_i = [0]; let best_d = [999999];
    let i = 0;
    while i < len(activated) {
        let fact_mol = __array_get(activated, i);
        let act = __array_get(activated, i + 1);
        // Score = distance penalty - activation bonus
        let d = mol_dist(query_mol, fact_mol);
        let score = d * 100 - act;
        if score < __array_get(best_d, 0) {
            let _ = __set_at(best_d, 0, score);
            let _ = __set_at(best_i, 0, i);
        };
        let i = i + 2;
    };
    // Return best mol → lookup in KnowTree
    let best_mol = __array_get(activated, __array_get(best_i, 0));
    return kt_exact(best_mol);
};

// ── Layer 4: REPAIR (quality check) ──
fn brain_repair(result, query_mol) {
    if len(result) == 0 { return ""; };
    // Quality check: is result relevant?
    let result_mol = kt_encode_mol(result);
    let d = mol_dist(query_mol, result_mol);
    // φ⁻¹ threshold: distance < 35 (half of max 70)
    if d > 35 { return ""; };
    return result;
};

// ── Layer 5: DECODE ∂ ──
fn brain_decode(result, query_mol) {
    // For now: return result text directly
    // Future: chain → partial derivatives → generated text
    return result;
};

// ═══ PIPELINE: Full 5-layer ═══
fn pipeline_respond(input) {
    // CP1: Security
    let mol = brain_capture(input);
    let gate = brain_security(mol);
    if gate > 0 { return ""; };

    // CP2: Encode OK
    if mol == 0 { return ""; };

    // Layer 2: Activate (KnowTree nearest + silk edges)
    let activated = brain_activate(mol);
    if len(activated) == 0 { return ""; };

    // Honesty check
    let sw = 0;
    if len(activated) >= 2 {
        let sw = silk_weight(mol, __array_get(activated, 0));
    };
    let conf = instinct_honesty(__floor(len(activated) / 2), sw);
    if conf < 200 { return ""; };  // too uncertain → silence

    // Layer 3: Hypothesize
    let result = brain_hypothesize(activated, mol);

    // Layer 4: Repair
    let result = brain_repair(result, mol);

    // Layer 5: Decode
    let result = brain_decode(result, mol);

    // Post: STM push + silk fire
    __stm_push(mol, input);
    if len(result) > 0 {
        let result_mol = kt_encode_mol(result);
        let _ = silk_fire(mol, result_mol);
    };

    // ConversationCurve
    __v_push(mol_v(mol));
    __wm_bind(1, mol);  // WM[1] = context for next turn

    return result;
};

// ═══ PTAV ═══
fn ptav_cycle(input) {
    let response = pipeline_respond(input);
    let mol = __wm_read(0);
    // VERIFY: curiosity
    let act = brain_activate(mol);
    if len(act) >= 2 {
        let nearest_dist = __array_get(act, 1);
        let curiosity = instinct_curiosity(mol, __floor(nearest_dist / 10));
    };
    return response;
};

emit "brain loaded";
