// pipeline.ol — 14-step pipeline for VM v2
// Encode → Search → Silk walk → Compose → Decode ∂

fn abs(x) { if x < 0 { return 0 - x; }; return x; };
fn mol_pack(s, r, v, a, t) { return s * 4096 + r * 256 + v * 32 + a * 4 + t; };
fn mol_s(m) { return __floor(m / 4096) % 16; };
fn mol_r(m) { return __floor(m / 256) % 16; };
fn mol_v(m) { return __floor(m / 32) % 8; };
fn mol_a(m) { return __floor(m / 4) % 8; };
fn mol_t(m) { return m % 4; };
fn mol_dist(a, b) {
    return abs(mol_s(a) - mol_s(b)) + abs(mol_r(a) - mol_r(b)) + abs(mol_v(a) - mol_v(b)) * 2 + abs(mol_a(a) - mol_a(b)) * 2 + abs(mol_t(a) - mol_t(b)) * 4;
};
fn mol_dominant(m) {
    let ns = abs(mol_s(m) * 100 / 15 - 50);
    let nr = abs(mol_r(m) * 100 / 15 - 50);
    let nv = abs(mol_v(m) * 100 / 7 - 50);
    let na = abs(mol_a(m) * 100 / 7 - 50);
    let nt = abs(mol_t(m) * 100 / 3 - 50);
    let best = 0; let bd = ns;
    if nr > bd { let best = 1; let bd = nr; };
    if nv > bd { let best = 2; let bd = nv; };
    if na > bd { let best = 3; let bd = na; };
    if nt > bd { let best = 4; };
    return best;
};

// Encode: text → mol (simplified: hash-based for now)
fn encode(text) {
    let h = 5381;
    let i = 0;
    while i < len(text) {
        let c = __char_code(char_at(text, i));
        let h = __bit_and(h * 33 + c, 65535);
        let i = i + 1;
    };
    return h;
};

// Security gate: V ≤ 1 AND A ≥ 6 → crisis
fn security_gate(mol) {
    if mol_v(mol) < 2 {
        if mol_a(mol) > 5 { return 1; };
    };
    return 0;
};

// Confidence (instinct honesty)
fn instinct_honesty(mol, result_count) {
    if result_count == 0 { return 0; };
    return result_count * 250;
};

// Pipeline: input → response
fn pipeline(input) {
    // Step 1: Security gate
    let mol = encode(input);
    if security_gate(mol) == 1 {
        return "Neu ban can ho tro, xin goi 1800 599 920";
    };

    // Step 2: Search — try word match first
    let results = [];
    // (word search would go here — needs kt_find)

    // Step 3: Mol nearest
    let near = kt_nearest_text(mol);
    if len(near) > 0 { push(results, near); };

    // Step 4: Honesty gate
    let conf = instinct_honesty(mol, len(results));
    if conf < 200 { return ""; };

    // Step 5: Compose response
    if len(results) == 0 { return ""; };
    let response = __array_get(results, 0);
    return response;
};

emit "pipeline loaded";
