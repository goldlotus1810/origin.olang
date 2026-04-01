// ═══ Encode ∫ — Word-level 5D encoding ═══
// SPEC BP2: NRC-VAD for V/A, hash for R, char properties for S/T
// Key insight: encode per WORD, not per char. Hash differentiates words.
// Then compose words → sentence mol.

// ── P_weight bit layout: [S:4][R:4][V:3][A:3][T:2] = u16 ──
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

// ═══ FNV-1a Hash → R dimension ═══
// Different words → different R values. This is the KEY differentiator.
fn fnv_hash(text, start, end) {
    let h = 2166136261;  // FNV offset basis (fits in f64)
    let i = start;
    while i < end {
        let c = __char_code(char_at(text, i));
        // h = (h XOR c) * 16777619
        let h = __bit_xor(h, c);
        // Multiply by FNV prime — use modular arithmetic to stay in range
        let h = __bit_and(h * 16777619, 4294967295);  // mod 2^32... but bit_and max is unclear
        // Simpler: use smaller prime to avoid overflow
        let h = __bit_xor(h * 33 + c, h);
        let i = i + 1;
    };
    // Map to 0-15 for R dimension
    return __bit_and(__floor(h / 256), 15);
};

// ═══ S dimension: structural complexity ═══
fn encode_S(text, start, end) {
    let length = end - start;
    let has_upper = [0];
    let has_digit = [0];
    let has_special = [0];
    let i = start;
    while i < end {
        let c = __char_code(char_at(text, i));
        if c >= 65 { if c <= 90 { let _ = __set_at(has_upper, 0, 1); }; };
        if c >= 48 { if c <= 57 { let _ = __set_at(has_digit, 0, 1); }; };
        if c < 48 { if c != 32 { let _ = __set_at(has_special, 0, 1); }; };
        let i = i + 1;
    };
    // S = complexity: length + features
    let s = 0;
    if length > 0 { let s = 1; };
    if length > 3 { let s = 2; };
    if length > 6 { let s = 3; };
    if length > 10 { let s = 4; };
    if __array_get(has_upper, 0) > 0 { let s = s + 2; };
    if __array_get(has_digit, 0) > 0 { let s = s + 3; };
    if __array_get(has_special, 0) > 0 { let s = s + 2; };
    if s > 15 { let s = 15; };
    return s;
};

// ═══ V dimension: valence (emotion polarity) ═══
// Default neutral (4). Later: NRC-VAD lookup.
fn encode_V(text, start, end) {
    // Heuristic: ! → high arousal low V, ? → curious, capital → assertive
    let v = 4;  // neutral
    let i = start;
    while i < end {
        let c = __char_code(char_at(text, i));
        if c == 33 { let v = 2; };  // ! → slightly negative (urgent)
        if c == 63 { let v = 4; };  // ? → neutral
        let i = i + 1;
    };
    return v;
};

// ═══ A dimension: arousal (intensity) ═══
fn encode_A(text, start, end) {
    let a = 3;  // moderate
    let i = start;
    while i < end {
        let c = __char_code(char_at(text, i));
        if c >= 65 { if c <= 90 { let a = 5; }; };  // uppercase → high arousal
        if c == 33 { let a = 6; };  // ! → very high
        if c == 63 { let a = 5; };  // ? → high
        let i = i + 1;
    };
    return a;
};

// ═══ T dimension: temporal ═══
fn encode_T(text, start, end) {
    return 2;  // medium (default for text)
};

// ═══ Encode 1 word → mol ═══
fn encode_word(text, start, end) {
    let s = encode_S(text, start, end);
    let r = fnv_hash(text, start, end);
    let v = encode_V(text, start, end);
    let a = encode_A(text, start, end);
    let t = encode_T(text, start, end);
    return mol_pack(s, r, v, a, t);
};

// ═══ Compose: biological (S=max, R=Zipf first, V=amplify, A=max, T=first) ═══
fn compose(a, b) {
    let sa = mol_s(a); let sb = mol_s(b); let s = sa; if sb > sa { let s = sb; };
    let ra = mol_r(a);  // Zipf: first word's R dominates
    let va = mol_v(a); let vb = mol_v(b);
    let v = __floor((va + vb) / 2);
    if va + vb > 6 { let v = v + 1; if v > 7 { let v = 7; }; };
    if va + vb < 6 { let v = v - 1; if v < 0 { let v = 0; }; };
    let aa = mol_a(a); let ab = mol_a(b); let ar = aa; if ab > aa { let ar = ab; };
    return mol_pack(s, ra, v, ar, mol_t(a));
};

// ═══ Encode sentence → mol (word-level compose) ═══
fn encode_text(text) {
    if len(text) == 0 { return 0; };
    let result = [0];
    let ws = [0];
    let first = [1];
    let i = 0;
    while i <= len(text) {
        let is_end = 0;
        if i == len(text) { let is_end = 1; }
        else { if __char_code(char_at(text, i)) == 32 { let is_end = 1; }; };

        if is_end == 1 {
            if i > __array_get(ws, 0) {
                let word_mol = encode_word(text, __array_get(ws, 0), i);
                if __array_get(first, 0) == 1 {
                    let _ = __set_at(result, 0, word_mol);
                    let _ = __set_at(first, 0, 0);
                } else {
                    let _ = __set_at(result, 0, compose(__array_get(result, 0), word_mol));
                };
            };
            let _ = __set_at(ws, 0, i + 1);
        };
        let i = i + 1;
    };
    return __array_get(result, 0);
};

emit "encode.ol loaded — word-level 5D";
