// ═══ Brain E2E Test — KnowTree + Silk + Pipeline ═══
// Verify: brain COMPUTES (5D distance), not LOOKS UP (keyword)

// ── KnowTree inline (from knowtree.ol) ──
fn kt_mol_pack(s, r, v, a, t) { return s * 4096 + r * 256 + v * 32 + a * 4 + t; };
fn kt_mol_s(m) { return __floor(m / 4096) % 16; };
fn kt_mol_r(m) { return __floor(m / 256) % 16; };
fn kt_mol_v(m) { return __floor(m / 32) % 8; };
fn kt_mol_a(m) { return __floor(m / 4) % 8; };
fn kt_mol_t(m) { return m % 4; };
fn kt_mol_dist(a, b) {
    let ds = kt_mol_s(a) - kt_mol_s(b); if ds < 0 { let ds = 0 - ds; };
    let dr = kt_mol_r(a) - kt_mol_r(b); if dr < 0 { let dr = 0 - dr; };
    let dv = kt_mol_v(a) - kt_mol_v(b); if dv < 0 { let dv = 0 - dv; };
    let da = kt_mol_a(a) - kt_mol_a(b); if da < 0 { let da = 0 - da; };
    let dt = kt_mol_t(a) - kt_mol_t(b); if dt < 0 { let dt = 0 - dt; };
    return ds + dr + dv * 2 + da * 2 + dt * 4;
};
fn kt_enc_char(cp) {
    let s = 1; let r = 4; let v = 4; let a = 3; let t = 2;
    if cp >= 97 { if cp <= 122 { let s = __bit_and(cp * 7, 15); let r = 8; let a = 3; }; };
    if cp >= 65 { if cp <= 90 { let s = __bit_and(cp * 7 + 3, 15); let r = 8; let a = 5; }; };
    if cp >= 48 { if cp <= 57 { let s = __bit_and(cp * 3, 15); let r = 3; let a = 2; let t = 1; }; };
    if cp == 32 { let s = 0; let r = 0; let v = 3; let a = 1; let t = 0; };
    return kt_mol_pack(s, r, v, a, t);
};
fn kt_compose(a, b) {
    let sa = kt_mol_s(a); let sb = kt_mol_s(b); let s = sa; if sb > sa { let s = sb; };
    let va = kt_mol_v(a); let vb = kt_mol_v(b);
    let vbase = __floor((va + vb) / 2); let v = vbase;
    if va + vb > 6 { let v = vbase + 1; if v > 7 { let v = 7; }; };
    if va + vb < 6 { let v = vbase - 1; if v < 0 { let v = 0; }; };
    let aa = kt_mol_a(a); let ab = kt_mol_a(b); let ar = aa; if ab > aa { let ar = ab; };
    return kt_mol_pack(s, kt_mol_r(a), v, ar, kt_mol_t(a));
};
fn kt_enc_word(text, ws, we) {
    let r = [0]; let i = ws;
    while i < we {
        let m = kt_enc_char(__char_code(char_at(text, i)));
        if i == ws { let _ = __set_at(r, 0, m); } else { let _ = __set_at(r, 0, kt_compose(__array_get(r, 0), m)); };
        let i = i + 1;
    };
    return __array_get(r, 0);
};
fn kt_build_chain(text) {
    let chain = []; let ws = 0; let i = 0;
    while i <= len(text) {
        let is_sp = 0;
        if i == len(text) { let is_sp = 1; } else { if __char_code(char_at(text, i)) == 32 { let is_sp = 1; }; };
        if is_sp == 1 { if i > ws { push(chain, kt_enc_word(text, ws, i)); }; let ws = i + 1; };
        let i = i + 1;
    };
    return chain;
};
fn kt_chain_mol(chain) {
    if len(chain) == 0 { return 0; };
    let r = __array_get(chain, 0); let i = 1;
    while i < len(chain) { let r = kt_compose(r, __array_get(chain, i)); let i = i + 1; };
    return r;
};
fn kt_chain_dist(a, b) {
    let la = len(a); let lb = len(b);
    let clen = la; if lb < clen { let clen = lb; };
    let d = [0]; let i = 0;
    while i < clen {
        let _ = __set_at(d, 0, __array_get(d, 0) + kt_mol_dist(__array_get(a, i), __array_get(b, i)));
        let i = i + 1;
    };
    let diff = la - lb; if diff < 0 { let diff = 0 - diff; };
    return __array_get(d, 0) + diff * 2;
};
fn kt_encode_mol(text) { return kt_chain_mol(kt_build_chain(text)); };

let kt_texts = []; let kt_chains = []; let kt_count = [0];
fn kt_learn(text) {
    let chain = kt_build_chain(text);
    push(kt_texts, text); push(kt_chains, chain);
    let _ = __set_at(kt_count, 0, __array_get(kt_count, 0) + 1);
};
fn kt_query(qtext) {
    let qc = kt_build_chain(qtext);
    let n = __array_get(kt_count, 0);
    let best_i = [0 - 1]; let best_d = [999999];
    let i = 0;
    while i < n {
        let d = kt_chain_dist(qc, __array_get(kt_chains, i));
        if d < __array_get(best_d, 0) {
            let _ = __set_at(best_d, 0, d); let _ = __set_at(best_i, 0, i);
        };
        let i = i + 1;
    };
    if __array_get(best_i, 0) >= 0 { return __array_get(kt_texts, __array_get(best_i, 0)); };
    return "";
};
// kt_nearest: returns [text, dist, text, dist, ...]
fn kt_nearest(query_mol, k) {
    // For brain test: use kt_query style but return mol-based query
    // Simplified: linear scan, return top-k texts and distances
    return [];  // brain_activate will use kt_query directly
};

// ── Silk inline ──
fn silk_hash(a, b) { return __bit_and(__bit_xor(a, b) * 40503 + a + b, 65535); };
fn silk_fire(a, b) {
    let h = silk_hash(a, b);
    let w = __mxr(h);
    let delta = __floor((65535 - w) * 236 / 65535);
    if delta < 1 { let delta = 1; };
    let nw = w + delta; if nw > 65535 { let nw = 65535; };
    __mx_w(h, nw);
    return nw;
};
fn silk_weight(a, b) { return __mxr(silk_hash(a, b)); };
fn silk_type(a, b) {
    let ds = kt_mol_s(a) - kt_mol_s(b); if ds < 0 { let ds = 0 - ds; };
    let dr = kt_mol_r(a) - kt_mol_r(b); if dr < 0 { let dr = 0 - dr; };
    let dv = kt_mol_v(a) - kt_mol_v(b); if dv < 0 { let dv = 0 - dv; };
    let da = kt_mol_a(a) - kt_mol_a(b); if da < 0 { let da = 0 - da; };
    let dt = kt_mol_t(a) - kt_mol_t(b); if dt < 0 { let dt = 0 - dt; };
    let ns = ds * 1000 / 15; let nr = dr * 1000 / 15;
    let nv = dv * 1000 / 7; let na = da * 1000 / 7; let nt = dt * 1000 / 3;
    let best = 0; let bval = ns;
    if nr > bval { let best = 1; let bval = nr; };
    if nv > bval { let best = 2; let bval = nv; };
    if na > bval { let best = 3; let bval = na; };
    if nt > bval { let best = 4; };
    return best;
};

// ── Instinct: Analogy (BP6 §5) ──
fn instinct_analogy(a, b, c) {
    let ds = kt_mol_s(b) - kt_mol_s(a) + kt_mol_s(c);
    let dr = kt_mol_r(b) - kt_mol_r(a) + kt_mol_r(c);
    let dv = kt_mol_v(b) - kt_mol_v(a) + kt_mol_v(c);
    let da = kt_mol_a(b) - kt_mol_a(a) + kt_mol_a(c);
    let dt = kt_mol_t(b) - kt_mol_t(a) + kt_mol_t(c);
    if ds < 0 { let ds = 0; }; if ds > 15 { let ds = 15; };
    if dr < 0 { let dr = 0; }; if dr > 15 { let dr = 15; };
    if dv < 0 { let dv = 0; }; if dv > 7 { let dv = 7; };
    if da < 0 { let da = 0; }; if da > 7 { let da = 7; };
    if dt < 0 { let dt = 0; }; if dt > 3 { let dt = 3; };
    return kt_mol_pack(ds, dr, dv, da, dt);
};

// ═══ TESTS ═══
let pass = [0]; let fail = [0];
fn check(name, got, expected) {
    if got == expected { let _ = __set_at(pass, 0, __array_get(pass, 0) + 1);
    } else { emit "FAIL " + name; let _ = __set_at(fail, 0, __array_get(fail, 0) + 1); };
};

// Learn facts
kt_learn("Ha Noi la thu do");
kt_learn("Sai Gon la thanh pho");
kt_learn("Olang la ngon ngu");
kt_learn("fire is hot");
kt_learn("water is cold");

// ── Test 1: KnowTree nearest by mol distance, NOT keyword ──
check("kt_hanoi", kt_query("Ha Noi o dau"), "Ha Noi la thu do");
check("kt_fire", kt_query("fire burns"), "fire is hot");

// ── Test 2: Silk fire + read ──
let ma = kt_encode_mol("Ha Noi");
let mb = kt_encode_mol("Sai Gon");
check("silk_init", silk_weight(ma, mb), 0);
let _ = silk_fire(ma, mb);
check("silk_fired", silk_weight(ma, mb) > 0, 1);

// ── Test 3: Silk type detection ──
// Ha Noi mol vs Sai Gon mol → dominant dimension
let st = silk_type(ma, mb);
check("silk_type_valid", st >= 0, 1);
check("silk_type_valid2", st <= 4, 1);

// ── Test 4: Silk diminishing returns ──
let w1 = silk_weight(ma, mb);
let _ = silk_fire(ma, mb);
let w2 = silk_weight(ma, mb);
let _ = silk_fire(ma, mb);
let w3 = silk_weight(ma, mb);
let d1 = w2 - w1;
let d2 = w3 - w2;
check("diminish", d2 <= d1, 1);

// ── Test 5: Analogy (a:b :: c:?) ──
let mol_a = kt_mol_pack(3, 8, 4, 5, 2);   // "structured, high arousal"
let mol_b = kt_mol_pack(3, 8, 6, 5, 2);   // same but V=6 (positive)
let mol_c = kt_mol_pack(10, 8, 2, 3, 2);  // different S, V=2 (negative)
let mol_d = instinct_analogy(mol_a, mol_b, mol_c);
// d should have V = V_c + (V_b - V_a) = 2 + (6-4) = 4
check("analogy_v", kt_mol_v(mol_d), 4);

// ── Test 6: Contradiction detection ──
let mol_pos = kt_mol_pack(3, 8, 7, 3, 2);  // V=7 (very positive)
let mol_neg = kt_mol_pack(3, 8, 0, 3, 2);  // V=0 (very negative)
let mol_sim = kt_mol_pack(3, 8, 6, 3, 2);  // V=6 (similar to pos)
fn instinct_contradiction(a, b) {
    let dv = kt_mol_v(a) - kt_mol_v(b); if dv < 0 { let dv = 0 - dv; };
    let dr = kt_mol_r(a) - kt_mol_r(b); if dr < 0 { let dr = 0 - dr; };
    if dv > 4 { if dr < 3 { return 1; }; };
    return 0;
};
check("contra_yes", instinct_contradiction(mol_pos, mol_neg), 1);
check("contra_no", instinct_contradiction(mol_pos, mol_sim), 0);

// ── Test 7: Different word order → different chain → different distance ──
let c1 = kt_build_chain("Ha Noi dep");
let c2 = kt_build_chain("dep Ha Noi");
check("word_order", kt_chain_dist(c1, c2) > 0, 1);

let p = __array_get(pass, 0); let f = __array_get(fail, 0);
emit __to_string(p) + "/" + __to_string(p + f) + " brain tests";
if f == 0 { emit "ALL PASS"; } else { emit __to_string(f) + " FAILED"; };
