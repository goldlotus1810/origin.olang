// ═══ KnowTree — Mol-indexed Content-Addressable Memory ═══
// Spec: BP3 KnowTree. Chain = per-word mols. Nearest = 5D distance.
// TÍNH distance, KHÔNG keyword match.

// ── Mol helpers ──
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

// ── Encode word: hash-mix all chars across 5D ──
// Each char contributes to all dimensions via position-dependent hashing.
// Same word → same mol. Different word → different mol.
// COMPUTED from codepoints, not lookup table.
fn kt_enc_word(text, ws, we) {
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
    return kt_mol_pack(
        __array_get(hs, 0) % 16, __array_get(hr, 0) % 16,
        __array_get(hv, 0) % 8, __array_get(ha, 0) % 8,
        __array_get(ht, 0) % 4
    );
};

// ── Build chain: array of per-word mols ──
fn kt_build_chain(text) {
    let chain = [];
    let ws = 0; let i = 0;
    while i <= len(text) {
        let is_sp = 0;
        if i == len(text) { let is_sp = 1; } else { if __char_code(char_at(text, i)) == 32 { let is_sp = 1; }; };
        if is_sp == 1 { if i > ws { push(chain, kt_enc_word(text, ws, i)); }; let ws = i + 1; };
        let i = i + 1;
    };
    return chain;
};

// ── Chain → sentence mol (first word mol as representative) ──
fn kt_chain_mol(chain) {
    if len(chain) == 0 { return 0; };
    return __array_get(chain, 0);
};

// ── Chain distance: sum word mol_dist + length penalty ──
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

// ═══ STORAGE — flat arrays, linear scan ═══
// For <1000 facts, linear scan is fast enough.
// Bucket optimization: later when >1000.
let kt_texts = [];
let kt_chains = [];
let kt_mols = [];
let kt_count = [0];

// ═══ LEARN ═══
fn kt_learn(text) {
    let chain = kt_build_chain(text);
    let mol = kt_chain_mol(chain);
    let idx = __array_get(kt_count, 0);
    push(kt_texts, text);
    push(kt_chains, chain);
    push(kt_mols, mol);
    let _ = __set_at(kt_count, 0, idx + 1);
    // Index in mol_matrix for O(1) exact mol lookup
    __mx_w(mol, idx + 1);
    return idx;
};

// ═══ EXACT LOOKUP by mol ═══
fn kt_exact(mol) {
    let idx = __mxr(mol);
    if idx > 0 { return __array_get(kt_texts, idx - 1); };
    return "";
};

// ═══ NEAREST by chain distance ═══
fn kt_nearest(query_text, k) {
    let qc = kt_build_chain(query_text);
    let n = __array_get(kt_count, 0);
    if n == 0 { return []; };

    // Compute all distances
    let dists = __array_with_cap(n);
    let i = 0;
    while i < n {
        push(dists, kt_chain_dist(qc, __array_get(kt_chains, i)));
        let i = i + 1;
    };

    // Select top-k by min distance
    let results = [];
    let found = [0];
    while __array_get(found, 0) < k {
        let min_d = [999999]; let min_i = [0 - 1];
        let i = 0;
        while i < n {
            let d = __array_get(dists, i);
            if d >= 0 { if d < __array_get(min_d, 0) {
                let _ = __set_at(min_d, 0, d);
                let _ = __set_at(min_i, 0, i);
            }; };
            let i = i + 1;
        };
        if __array_get(min_i, 0) < 0 { return results; };
        let bi = __array_get(min_i, 0);
        push(results, __array_get(kt_texts, bi));
        push(results, __array_get(dists, bi));
        let _ = __set_at(dists, bi, 0 - 1);  // mark taken
        let _ = __set_at(found, 0, __array_get(found, 0) + 1);
    };
    return results;
};

// ═══ QUERY (convenience: return best match text) ═══
fn kt_query(text) {
    let r = kt_nearest(text, 1);
    if len(r) >= 2 { return __array_get(r, 0); };
    return "";
};

// ═══ ENCODE_MOL (public: text → mol) ═══
fn kt_encode_mol(text) {
    let chain = kt_build_chain(text);
    return kt_chain_mol(chain);
};

// ═══ PERSISTENCE — save/load facts to disk ═══
fn kt_save(path) {
    let n = __array_get(kt_count, 0);
    let out = __to_string(n) + "\n";
    let i = 0;
    while i < n {
        let out = out + __array_get(kt_texts, i) + "\n";
        let i = i + 1;
    };
    __file_write(path, out);
    return n;
};

fn kt_load(path) {
    let data = __file_read(path);
    if len(data) == 0 { return 0; };
    let loaded = [0];
    let ls = 0; let i = 0; let first = [1];
    while i <= len(data) {
        let is_nl = 0;
        if i == len(data) { let is_nl = 1; } else { if __char_code(char_at(data, i)) == 10 { let is_nl = 1; }; };
        if is_nl == 1 {
            if i > ls {
                let line = substr(data, ls, i);
                if __array_get(first, 0) == 1 {
                    let _ = __set_at(first, 0, 0);
                } else {
                    if len(line) > 0 {
                        kt_learn(line);
                        let _ = __set_at(loaded, 0, __array_get(loaded, 0) + 1);
                    };
                };
            };
            let ls = i + 1;
        };
        let i = i + 1;
    };
    return __array_get(loaded, 0);
};

// ═══ LOAD from simple text file (one fact per line, no header) ═══
fn kt_load_simple(path) {
    let data = __file_read(path);
    if len(data) == 0 { return 0; };
    let loaded = [0];
    let ls = 0; let i = 0;
    while i <= len(data) {
        let is_nl = 0;
        if i == len(data) { let is_nl = 1; } else { if __char_code(char_at(data, i)) == 10 { let is_nl = 1; }; };
        if is_nl == 1 {
            if i > ls {
                let line = substr(data, ls, i);
                if len(line) > 2 {
                    kt_learn(line);
                    let _ = __set_at(loaded, 0, __array_get(loaded, 0) + 1);
                };
            };
            let ls = i + 1;
        };
        let i = i + 1;
    };
    return __array_get(loaded, 0);
};

emit "knowtree loaded";
