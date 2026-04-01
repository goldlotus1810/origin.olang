// ═══ brain.ol — Nox Brain: Pipeline 5 tầng + PTAV loop ═══
// Nối: encode.ol + core.ol + knowtree.ol + silk.ol + pipeline.ol
// Spec: BP5 Pipeline, BP6 Instincts, BP9 Agent PTAV

// ── Molecular helpers (from core.ol) ──
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

// ── Encode (from encode.ol, simplified) ──
fn encode_char(cp) {
    let s = 2; let r = 8; let v = 4; let a = 3; let t = 2;
    if cp >= 65 { if cp <= 90 { let s = 3; let a = 5; }; };
    if cp >= 97 { if cp <= 122 { let s = 2; let a = 3; }; };
    if cp >= 48 { if cp <= 57 { let s = 1; let r = 3; let a = 2; let t = 1; }; };
    if cp == 43 { let r = 0; };
    if cp == 33 { let v = 2; let a = 6; };
    if cp == 63 { let v = 4; let a = 5; };
    return mol_pack(s, r, v, a, t);
};

fn encode_text(text) {
    if len(text) == 0 { return 0; };
    let mol = [0];
    let ei = 0;
    while ei < len(text) {
        let c = __char_code(char_at(text, ei));
        let cm = encode_char(c);
        if ei == 0 {
            let _ = __set_at(mol, 0, cm);
        } else {
            let prev = __array_get(mol, 0);
            // Biological compose: S=max, R=first, V=amplify, A=max, T=first
            let s = mol_s(prev); let sb = mol_s(cm);
            if sb > s { let s = sb; };
            let r = mol_r(prev);  // Zipf: first dominates
            let va = mol_v(prev); let vb = mol_v(cm);
            let v_base = __floor((va + vb) / 2);
            let v = v_base;
            if va + vb > 6 { let v = v_base + 1; if v > 7 { let v = 7; }; };
            if va + vb < 6 { let v = v_base - 1; if v < 0 { let v = 0; }; };
            let a = mol_a(prev); let ab = mol_a(cm);
            if ab > a { let a = ab; };
            let t = mol_t(prev);
            let _ = __set_at(mol, 0, mol_pack(s, r, v, a, t));
        };
        let ei = ei + 1;
    };
    return __array_get(mol, 0);
};

// ── Layer 1: CAPTURE ──
fn capture(input) {
    let mol = encode_text(input);
    __wm_bind(0, mol);  // WM[0] = query
    let dim = __mol_dominant(mol);
    return mol;
};

// ── Security Gate (BP6 §1, BP5 CP1) ──
fn security_gate(mol) {
    // V ≤ 1 AND A ≥ 6 → crisis
    if mol_v(mol) < 2 {
        if mol_a(mol) > 5 {
            return 1;  // CRISIS
        };
    };
    // Bloom filter check
    if __bloom_check(mol) > 0 {
        return 2;  // PROHIBITED
    };
    return 0;  // SAFE
};

// ── Layer 2: ACTIVATE (Spreading Activation) ──
fn activate(mol, depth) {
    // Set source activation
    __act_reset();
    __act_set(mol, 1000);
    // Spread along dominant dimension
    let dim = __mol_dominant(mol);
    let steps = [0];
    while __array_get(steps, 0) < depth {
        // Get top-k activated nodes
        let top = __act_top_k(10);
        let ti = 0;
        while ti < len(top) {
            let node_mol = __array_get(top, ti);
            let node_act = __array_get(top, ti + 1);
            if node_act > 50 {  // threshold
                // Spread to neighbors via SilkWalk
                // Implicit strength as activation
                let spread = __floor(node_act * 300 / 1000);  // retention 0.3
                // Step ±1 in dominant dimension
                let step_val = 1;
                if dim == 0 { let step_val = 4096; };
                if dim == 1 { let step_val = 256; };
                if dim == 2 { let step_val = 32; };
                if dim == 3 { let step_val = 4; };
                let neighbor_p = node_mol + step_val;
                let neighbor_n = node_mol - step_val;
                if neighbor_p >= 0 { if neighbor_p <= 65535 {
                    __act_add(neighbor_p, spread);
                }; };
                if neighbor_n >= 0 { if neighbor_n <= 65535 {
                    __act_add(neighbor_n, spread);
                }; };
                // Check silk edges
                let sw = __silk_weight(mol, node_mol);
                if sw > 0 {
                    __act_add(node_mol, __floor(sw * spread / 65535));
                };
            };
            let ti = ti + 2;
        };
        // Decay all by 0.8
        __act_decay(800);
        let _ = __set_at(steps, 0, __array_get(steps, 0) + 1);
    };
    // Return top-k activated
    return __act_top_k(10);
};

// ── Layer 3: HYPOTHESIZE (CLONALG simplified) ──
fn hypothesize(activated, query_mol) {
    // Build 3 candidate chains from top activated nodes
    let candidates = __array_with_cap(3);
    let hi = 0;
    while hi < len(activated) {
        if hi >= 6 { };  // max 3 candidates (each 2 entries: mol+activation)
        if hi < 6 {
            let seed_mol = __array_get(activated, hi);
            // Build chain: seed → walk via silk
            let chain = __array_with_cap(8);
            push(chain, seed_mol);
            // Walk 3 more steps
            let current = [seed_mol];
            let wi = 0;
            while wi < 3 {
                let dim = __mol_dominant(__array_get(current, 0));
                let walked = __array_with_cap(4);
                // Try neighbors
                let step = 1;
                if dim == 0 { let step = 4096; };
                if dim == 1 { let step = 256; };
                if dim == 2 { let step = 32; };
                if dim == 3 { let step = 4; };
                let next = __array_get(current, 0) + step;
                if next >= 0 { if next <= 65535 {
                    if __mxr(next) > 0 {  // has fact in mol_matrix
                        push(chain, next);
                        let _ = __set_at(current, 0, next);
                    };
                }; };
                let wi = wi + 1;
            };
            push(candidates, chain);
        };
        let hi = hi + 2;  // skip activation values
    };
    return candidates;
};

// ── Layer 4: REPAIR (DCA simplified) ──
fn repair(candidates, query_mol) {
    // Pick best candidate by quality
    let best = [0];       // best chain index
    let best_q = [0];     // best quality
    let ri = 0;
    while ri < len(candidates) {
        let chain = __array_get(candidates, ri);
        let q = __chain_quality(chain, query_mol);
        if q > __array_get(best_q, 0) {
            let _ = __set_at(best_q, 0, q);
            let _ = __set_at(best, 0, ri);
        };
        let ri = ri + 1;
    };
    // Quality check: φ⁻¹ = 618
    if __array_get(best_q, 0) >= 618 {
        __wm_bind(2, __array_get(best_q, 0));  // WM[2] = candidate quality
        return __array_get(candidates, __array_get(best, 0));
    };
    // Below threshold — return empty
    return [];
};

// ── Instinct: Honesty (BP6 §1) ──
fn instinct_honesty(mol, result_count) {
    // confidence = result_count × 250 (simple: 4 results = full confidence)
    let confidence = result_count * 250;
    if confidence > 1000 { let confidence = 1000; };
    // < 400 → silence, 400-700 → hedge, > 900 → confident
    return confidence;
};

// ── Instinct: Curiosity (BP6 §6) ──
fn instinct_curiosity(mol) {
    // novelty = min_distance from known facts
    // High novelty → learning mode
    let nearest_dist = mol_dist(mol, __wm_read(1));  // compare to context
    if nearest_dist > 35 { return 1; };  // novel → explore
    return 0;  // familiar
};

// ── Layer 5: DECODE ∂ ──
fn decode(chain, query_mol) {
    // Compose chain → single mol
    let composed = __chain_compose(chain);
    __wm_bind(3, composed);  // WM[3] = result
    // Find text via mol_matrix lookup
    let fact_idx = __mxr(composed);
    if fact_idx > 0 {
        return fact_idx;  // found matching fact
    };
    // Fallback: return chain length as signal
    return len(chain);
};

// ── ConversationCurve ──
fn update_tone(mol) {
    let v = mol_v(mol);
    __v_push(v);
    return __conv_tone();
};

// ── Homeostasis ──
fn update_homeostasis(predicted_mol, actual_mol) {
    let f = __homeostasis(predicted_mol, actual_mol);
    // F > 618 → learning mode, F < 618 → acting mode
    return f;
};

// ═══ PIPELINE: Full 5-layer respond ═══
fn pipeline_respond(input) {
    // CP1: Security Gate
    let mol = capture(input);
    let gate = security_gate(mol);
    if gate == 1 { return "crisis_detected"; };
    if gate == 2 { return "prohibited"; };

    // CP2: Encode OK (mol > 0)
    if mol == 0 { return ""; };

    // Layer 2: Activate
    let activated = activate(mol, 3);
    if len(activated) == 0 { return ""; };

    // Layer 3: Hypothesize
    let candidates = hypothesize(activated, mol);

    // Layer 4: Repair + Quality check
    let best_chain = repair(candidates, mol);
    if len(best_chain) == 0 {
        // Below φ⁻¹ threshold — check honesty
        let conf = instinct_honesty(mol, 0);
        if conf < 400 { return ""; };  // silence
    };

    // Layer 5: Decode
    let result = decode(best_chain, mol);

    // Post-process
    // STM push
    __stm_push(mol, input);
    // Silk fire between input and result
    if len(best_chain) > 0 {
        let composed = __chain_compose(best_chain);
        // Fire silk (opcode, not builtin — can't call directly from here)
        // Use silk_weight as proxy to check connection exists
        let sw = __silk_weight(mol, composed);
    };
    // Update conversation curve
    let tone = update_tone(mol);
    // Update homeostasis
    let f_energy = update_homeostasis(__wm_read(1), mol);

    // Clean WM for next turn
    __wm_bind(1, mol);  // WM[1] = context (for next turn)

    return result;
};

// ═══ PTAV LOOP (BP9 Agent) ═══
fn ptav_cycle(input) {
    // PERCEIVE
    let mol = encode_text(input);

    // THINK
    let response = pipeline_respond(input);

    // ACT
    // (response is returned to caller for output)

    // VERIFY
    let curiosity = instinct_curiosity(mol);
    if curiosity > 0 {
        // Novel input — boost learning
        __act_add(mol, 500);  // extra activation
    };

    return response;
};

// ═══ Boot ═══
emit "brain.ol loaded";
