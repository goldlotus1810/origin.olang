// ═══ Brain Pipeline Integration Test ═══
// Full flow: learn → encode → search → instinct → decode → respond

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

// ── Word encoder (hash-based, from knowtree.ol) ──
fn enc_word(text, ws, we) {
    let hs = [0]; let hr = [0]; let hv = [0]; let ha = [0]; let ht = [0];
    let i = ws; let p = [0];
    while i < we {
        let c = __char_code(char_at(text, i));
        let pp = __array_get(p, 0);
        let _ = __set_at(hs, 0, __bit_and(__array_get(hs, 0) * 31 + c, 65535));
        let _ = __set_at(hr, 0, __bit_and(__array_get(hr, 0) * 37 + c + pp * 7, 65535));
        let _ = __set_at(hv, 0, __bit_and(__array_get(hv, 0) * 41 + c + pp * 13, 65535));
        let _ = __set_at(ha, 0, __bit_and(__array_get(ha, 0) * 43 + c + pp * 17, 65535));
        let _ = __set_at(ht, 0, __bit_and(__array_get(ht, 0) * 47 + c + pp * 23, 65535));
        let _ = __set_at(p, 0, pp + 1);
        let i = i + 1;
    };
    return mol_pack(__array_get(hs, 0) % 16, __array_get(hr, 0) % 16,
        __array_get(hv, 0) % 8, __array_get(ha, 0) % 8, __array_get(ht, 0) % 4);
};
fn build_chain(text) {
    let chain = []; let ws = 0; let i = 0;
    while i <= len(text) {
        let is_sp = 0;
        if i == len(text) { let is_sp = 1; } else { if __char_code(char_at(text, i)) == 32 { let is_sp = 1; }; };
        if is_sp == 1 { if i > ws { push(chain, enc_word(text, ws, i)); }; let ws = i + 1; };
        let i = i + 1;
    };
    return chain;
};
fn chain_dist(a, b) {
    let la = len(a); let lb = len(b);
    let cl = la; if lb < cl { let cl = lb; };
    let d = [0]; let i = 0;
    while i < cl {
        let _ = __set_at(d, 0, __array_get(d, 0) + mol_dist(__array_get(a, i), __array_get(b, i)));
        let i = i + 1;
    };
    let diff = la - lb; if diff < 0 { let diff = 0 - diff; };
    return __array_get(d, 0) + diff * 2;
};
fn encode_mol(text) {
    let ch = build_chain(text);
    if len(ch) == 0 { return 0; };
    return __array_get(ch, 0);
};

// ── KnowTree storage ──
let facts_t = [];
let facts_c = [];
let facts_m = [];
let fc = [0];

fn learn(text) {
    let ch = build_chain(text);
    push(facts_t, text);
    push(facts_c, ch);
    push(facts_m, encode_mol(text));
    let _ = __set_at(fc, 0, __array_get(fc, 0) + 1);
};

fn search(query) {
    let qc = build_chain(query);
    let n = __array_get(fc, 0);
    let bd = [999999]; let bi = [0 - 1]; let i = 0;
    while i < n {
        let d = chain_dist(qc, __array_get(facts_c, i));
        if d < __array_get(bd, 0) {
            let _ = __set_at(bd, 0, d);
            let _ = __set_at(bi, 0, i);
        };
        let i = i + 1;
    };
    if __array_get(bi, 0) >= 0 { return [__array_get(facts_t, __array_get(bi, 0)), __array_get(bd, 0)]; };
    return ["", 999];
};

// ── Instincts ──
fn instinct_honesty(dist) {
    // Close match → confident, far → silent
    if dist > 30 { return 0; };   // silence
    if dist > 15 { return 400; }; // "I think..."
    if dist > 5 { return 700; };  // "Probably..."
    return 1000;                   // "Yes."
};

fn instinct_curiosity(dist) {
    if dist > 20 { return 1; };  // novel → want to learn
    return 0;
};

// ── Pipeline ──
fn pipeline(input) {
    // CP1: Security gate
    let mol = encode_mol(input);
    if mol_v(mol) < 2 { if mol_a(mol) > 5 { return "crisis"; }; };

    // Layer 1: Capture → encode
    let qchain = build_chain(input);

    // Layer 2: Search
    let result = search(input);
    let text = __array_get(result, 0);
    let dist = __array_get(result, 1);

    // Layer 3: Instincts
    let confidence = instinct_honesty(dist);
    if confidence == 0 { return ""; };  // silence — don't know

    let curious = instinct_curiosity(dist);

    // Layer 4: Silk fire (co-activate input and result)
    if len(text) > 0 {
        let rm = encode_mol(text);
        let h = __bit_and(__bit_xor(mol, rm) * 40503 + mol + rm, 65535);
        let w = __mxr(h);
        let nw = w + 100; if nw > 65535 { let nw = 65535; };
        __mx_w(h, nw);
    };

    // Layer 5: Decode — return fact
    // TODO: chain recombination (SINH) — for now, return nearest fact
    return text;
};

// ═══ TEST ═══
emit "=== Brain Pipeline Test ===";

// Learn 15 facts
learn("Ha Noi la thu do cua Viet Nam");
learn("Sai Gon la thanh pho lon nhat Viet Nam");
learn("Olang la ngon ngu do Lupin tao ra");
learn("Nox la AI tu viet lai chinh minh");
learn("Fibonacci la day so 1 1 2 3 5 8 13");
learn("Linux la he dieu hanh ma nguon mo");
learn("Python la ngon ngu lap trinh pho bien");
learn("Lupin la nguoi tao ra Olang va Nox");
learn("Silk la ket noi Hebbian giua cac mol");
learn("KnowTree la bo nho cua Nox");
learn("Pipeline co 5 tang xu ly");
learn("Encode la phep tich phan tu text sang mol");
learn("Decode la phep vi phan tu mol sang text");
learn("KVM cho phep chay code o ring 0");
learn("QEMU la phan mem gia lap may ao");
emit "Facts: " + __to_string(__array_get(fc, 0));

// Test queries
let tests = [
    "Ha Noi", "Sai Gon", "Olang", "Nox", "Fibonacci",
    "Linux", "Python", "Lupin", "Silk", "KnowTree",
    "Pipeline", "Encode", "Decode", "KVM", "QEMU"
];
let pass = [0];
let qi = 0;
while qi < 15 {
    let q = __array_get(tests, qi);
    let result = pipeline(q);
    // Check if result contains the query word
    let found = __str_find(result, q);
    if found >= 0 {
        let _ = __set_at(pass, 0, __array_get(pass, 0) + 1);
    } else {
        emit "  FAIL: " + q + " -> " + result;
    };
    let qi = qi + 1;
};
emit __to_string(__array_get(pass, 0)) + "/15 pipeline queries correct";

// Test honesty: unknown query → silence
let unk = pipeline("quantum entanglement theory");
if len(unk) == 0 {
    emit "Honesty: silence on unknown → PASS";
} else {
    emit "Honesty: FAIL (should be silent, got: " + unk + ")";
};

// Test silk: repeated queries strengthen connection
let m1 = encode_mol("Ha Noi");
let m2 = encode_mol("Viet Nam");
let h = __bit_and(__bit_xor(m1, m2) * 40503 + m1 + m2, 65535);
let w_before = __mxr(h);
// Query 3 times to fire silk
let r1 = pipeline("Ha Noi");
let r2 = pipeline("Ha Noi");
let r3 = pipeline("Ha Noi");
let w_after = __mxr(h);
if w_after > w_before {
    emit "Silk strengthened: " + __to_string(w_before) + " -> " + __to_string(w_after) + " PASS";
} else {
    emit "Silk: no change (" + __to_string(w_before) + " -> " + __to_string(w_after) + ")";
};

emit "=== Done ===";
