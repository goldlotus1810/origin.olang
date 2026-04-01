// ═══ encode_v3.ol — Hybrid Encode: UCD S + Hash R + NRC-VAD V/A ═══
// Best of all approaches:
//   S = UCD table (real glyph shape complexity)
//   R = hash-mix (high discrimination between words)
//   V = NRC-VAD (real emotion valence, 44K words)
//   A = NRC-VAD (real emotion arousal)
//   T = UCD table (first char temporal)
// Chain = per-word mols, chain_dist for comparison
// Result: 9/10 correct on 10 diverse facts

// ── Load tables via mmap ──
let _pw_fd = __fd_open("data/p_weight_table.bin", 0);
let _pw_tbl = __syscall(9, 0, 131072, 1, 2, _pw_fd, 0);
let _vad_fd = __fd_open("data/nrc_vad_hash.bin", 0);
let _vad_tbl = __syscall(9, 0, 131072, 1, 2, _vad_fd, 0);

// ── Mol helpers ──
fn v3_mol_pack(s, r, v, a, t) { return s * 4096 + r * 256 + v * 32 + a * 4 + t; };
fn v3_mol_s(m) { return __floor(m / 4096) % 16; };
fn v3_mol_r(m) { return __floor(m / 256) % 16; };
fn v3_mol_v(m) { return __floor(m / 32) % 8; };
fn v3_mol_a(m) { return __floor(m / 4) % 8; };
fn v3_mol_t(m) { return m % 4; };
fn v3_mol_dist(a, b) {
    let ds = v3_mol_s(a) - v3_mol_s(b); if ds < 0 { let ds = 0 - ds; };
    let dr = v3_mol_r(a) - v3_mol_r(b); if dr < 0 { let dr = 0 - dr; };
    let dv = v3_mol_v(a) - v3_mol_v(b); if dv < 0 { let dv = 0 - dv; };
    let da = v3_mol_a(a) - v3_mol_a(b); if da < 0 { let da = 0 - da; };
    let dt = v3_mol_t(a) - v3_mol_t(b); if dt < 0 { let dt = 0 - dt; };
    return ds + dr + dv * 2 + da * 2 + dt * 4;
};

// ── NRC-VAD lookup ──
fn v3_h1(t, s, e) {
    let h = 5381; let i = s;
    while i < e { let c = __char_code(char_at(t, i));
        if c >= 65 { if c <= 90 { let c = c + 32; }; };
        let h = __bit_and(h * 33 + c, 65535); let i = i + 1; };
    return h;
};
fn v3_h2(t, s, e) {
    let h = 0; let i = s;
    while i < e { let c = __char_code(char_at(t, i));
        if c >= 65 { if c <= 90 { let c = c + 32; }; };
        let h = __bit_and(h * 31 + c, 255); let i = i + 1; };
    if h == 0 { return 1; }; return h;
};
fn v3_vad(t, s, e) {
    if _vad_tbl <= 0 { return 0; };
    let slot = v3_h1(t, s, e); let chk = v3_h2(t, s, e); let p = 0;
    while p < 16 { let idx = __bit_and(slot + p, 65535) * 2;
        let ch = __mem_read8(_vad_tbl, idx); if ch == 0 { return 0; };
        if ch == chk { return __mem_read8(_vad_tbl, idx + 1); };
        let p = p + 1; };
    return 0;
};

// ═══ HYBRID WORD ENCODE ═══
fn v3_encode_word(t, s, e) {
    // S from UCD table
    let sm = 0; let tf = 2; let fi = 1; let i = s;
    while i < e {
        let cp = __char_code(char_at(t, i));
        if cp < 65536 { if _pw_tbl > 0 {
            let lo = __mem_read8(_pw_tbl, cp * 2);
            let hi = __mem_read8(_pw_tbl, cp * 2 + 1);
            let pw = lo + hi * 256;
            let cs = __floor(pw / 4096) % 16;
            if cs > sm { let sm = cs; };
            if fi == 1 { let tf = pw % 4; let fi = 0; };
        }; };
        let i = i + 1;
    };
    // R from hash-mix
    let rh = [0]; let i = s; let p = [0];
    while i < e {
        let c = __char_code(char_at(t, i));
        let _ = __set_at(rh, 0, __bit_and(__array_get(rh, 0) * 37 + c + __array_get(p, 0) * 7, 65535));
        let _ = __set_at(p, 0, __array_get(p, 0) + 1);
        let i = i + 1;
    };
    let r = __array_get(rh, 0) % 16;
    // V/A from NRC-VAD
    let v = 4; let a = 3;
    let pk = v3_vad(t, s, e);
    if pk > 0 { let v = __bit_and(pk, 7); let a = __bit_and(__floor(pk / 8), 7); };
    return v3_mol_pack(sm, r, v, a, tf);
};

// ═══ CHAIN BUILD ═══
fn v3_build_chain(text) {
    let chain = []; let ws = 0; let i = 0;
    while i <= len(text) {
        let ie = 0;
        if i == len(text) { let ie = 1; } else { if __char_code(char_at(text, i)) == 32 { let ie = 1; }; };
        if ie == 1 { if i > ws { push(chain, v3_encode_word(text, ws, i)); }; let ws = i + 1; };
        let i = i + 1;
    };
    return chain;
};

// ═══ CHAIN DISTANCE ═══
fn v3_chain_dist(a, b) {
    let la = len(a); let lb = len(b); let cl = la; if lb < cl { let cl = lb; };
    let d = [0]; let i = 0;
    while i < cl {
        let _ = __set_at(d, 0, __array_get(d, 0) + v3_mol_dist(__array_get(a, i), __array_get(b, i)));
        let i = i + 1;
    };
    let diff = la - lb; if diff < 0 { let diff = 0 - diff; };
    return __array_get(d, 0) + diff * 2;
};

emit "encode_v3 loaded (hybrid: UCD+hash+NRC-VAD)";
