// ═══ encode_v2.ol — Real Unicode + NRC-VAD Encode ═══
// Spec BP2: per-codepoint P_weight from UCD v18.0 tables
// + per-word V/A from NRC-VAD 44K emotions
// All via mmap O(1) — no loop, no hash heuristic for known chars
//
// Tables:
//   data/p_weight_table.bin  128KB  [u16 × 65536] codepoint → P_weight
//   data/nrc_vad_hash.bin     64KB  [u8 × 65536]  word_hash → packed(V,A)

// ── Load tables via mmap ──
let _pw_fd = __fd_open("data/p_weight_table.bin", 0);
let _pw_table = __syscall(9, 0, 131072, 1, 2, _pw_fd, 0);  // mmap PRIVATE READ

let _vad_fd = __fd_open("data/nrc_vad_hash.bin", 0);
let _vad_table = __syscall(9, 0, 65536, 1, 2, _vad_fd, 0);

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

// ═══ Per-codepoint encode: O(1) table lookup ═══
fn encode_cp(cp) {
    if _pw_table <= 0 { return mol_pack(1, 4, 4, 3, 2); };  // fallback
    if cp >= 65536 { return mol_pack(1, 8, 4, 3, 2); };      // above BMP: default
    // Read u16 from table: 2 bytes per entry, little-endian
    let lo = __mem_read8(_pw_table, cp * 2);
    let hi = __mem_read8(_pw_table, cp * 2 + 1);
    let pw = lo + hi * 256;
    if pw == 0 { return mol_pack(1, 0, 4, 3, 2); };  // unassigned
    return pw;
};

// ═══ Per-word NRC-VAD lookup: O(1) hash ═══
fn vad_word_hash(text, start, end) {
    let h = 5381;
    let i = start;
    while i < end {
        let c = __char_code(char_at(text, i));
        // lowercase
        if c >= 65 { if c <= 90 { let c = c + 32; }; };
        let h = __bit_and(h * 33 + c, 65535);
        let i = i + 1;
    };
    return h;
};

// Returns packed byte: V in bits 0-2, A in bits 3-5. 0 = not found.
fn vad_lookup(text, start, end) {
    if _vad_table <= 0 { return 0; };
    let h = vad_word_hash(text, start, end);
    return __mem_read8(_vad_table, h);
};

// ═══ Encode word: combine codepoint P_weights + NRC-VAD emotion ═══
fn encode_word(text, start, end) {
    // Step 1: compose codepoint P_weights for structural features (S, R, T)
    let s_max = 0;
    let r_first = 0;
    let t_first = 2;
    let first = 1;
    let i = start;
    while i < end {
        let cp = __char_code(char_at(text, i));
        let pw = encode_cp(cp);
        let cs = mol_s(pw);
        let cr = mol_r(pw);
        let ct = mol_t(pw);
        if cs > s_max { let s_max = cs; };
        if first == 1 {
            let r_first = cr;
            let t_first = ct;
            let first = 0;
        };
        let i = i + 1;
    };

    // Step 2: V/A from NRC-VAD (word-level emotion)
    let v = 4; let a = 3;  // neutral default
    let packed = vad_lookup(text, start, end);
    if packed > 0 {
        let v = __bit_and(packed, 7);
        let a = __bit_and(__floor(packed / 8), 7);
    };

    // Step 3: differentiate with word hash (R dimension)
    // Mix first codepoint R with word hash for uniqueness
    let wh = __bit_and(vad_word_hash(text, start, end), 15);
    // R = weighted: 60% codepoint structure + 40% hash
    let r = __floor(r_first * 6 / 10 + wh * 4 / 10);
    if r > 15 { let r = 15; };

    return mol_pack(s_max, r, v, a, t_first);
};

// ═══ Compose: biological (S=max, R=Zipf first, V=amplify, A=max, T=first) ═══
fn compose(a, b) {
    let sa = mol_s(a); let sb = mol_s(b); let s = sa; if sb > sa { let s = sb; };
    let ra = mol_r(a);  // Zipf: first dominates
    let va = mol_v(a); let vb = mol_v(b);
    let v = __floor((va + vb) / 2);
    // Amplify: same direction → boost
    if va > 4 { if vb > 4 { let v = v + 1; }; };
    if va < 4 { if vb < 4 { let v = v - 1; }; };
    if v > 7 { let v = 7; }; if v < 0 { let v = 0; };
    let aa = mol_a(a); let ab = mol_a(b); let ar = aa; if ab > aa { let ar = ab; };
    return mol_pack(s, ra, v, ar, mol_t(a));
};

// ═══ Encode sentence: word-level compose ═══
fn encode_text(text) {
    if len(text) == 0 { return 0; };
    let result = 0;
    let ws = 0; let first = 1; let i = 0;
    while i <= len(text) {
        let is_end = 0;
        if i == len(text) { let is_end = 1; }
        else { if __char_code(char_at(text, i)) == 32 { let is_end = 1; }; };
        if is_end == 1 {
            if i > ws {
                let wm = encode_word(text, ws, i);
                if first == 1 { let result = wm; let first = 0; }
                else { let result = compose(result, wm); };
            };
            let ws = i + 1;
        };
        let i = i + 1;
    };
    return result;
};

emit "encode_v2 loaded — UCD v18 + NRC-VAD 44K";
