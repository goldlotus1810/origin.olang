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
            let _ = __set_at(best_d, 0, d);
            let _ = __set_at(best_i, 0, i);
        };
        let i = i + 1;
    };
    if __array_get(best_i, 0) >= 0 { return __array_get(kt_texts, __array_get(best_i, 0)); };
    return "";
};

let pass = [0]; let fail = [0];
fn check(name, got, expected) {
    if got == expected { let _ = __set_at(pass, 0, __array_get(pass, 0) + 1);
    } else { emit "FAIL " + name; let _ = __set_at(fail, 0, __array_get(fail, 0) + 1); };
};

emit "heap before learn: " + __to_string(__heap_used());
kt_learn("Ha Noi la thu do");
kt_learn("Sai Gon la thanh pho");
kt_learn("Da Nang o mien Trung");
kt_learn("Olang la ngon ngu");
kt_learn("fire is hot");
emit "heap after 5 learns: " + __to_string(__heap_used());

check("count", __array_get(kt_count, 0), 5);
check("hanoi", kt_query("Ha Noi o dau"), "Ha Noi la thu do");
check("saigon", kt_query("Sai Gon dep"), "Sai Gon la thanh pho");
check("danang", kt_query("Da Nang co gi"), "Da Nang o mien Trung");
check("olang", kt_query("Olang chay sao"), "Olang la ngon ngu");
check("fire", kt_query("fire burns"), "fire is hot");

// Order matters
let ca = kt_build_chain("Ha Noi dep");
let cb = kt_build_chain("dep Ha Noi");
check("order", kt_chain_dist(ca, cb) > 0, 1);

let p = __array_get(pass, 0); let f = __array_get(fail, 0);
emit __to_string(p) + "/" + __to_string(p + f) + " tests";
if f == 0 { emit "ALL PASS"; } else { emit __to_string(f) + " FAILED"; };
