// ═══ NOX GROWTH LOOP — Perceive → Think → Learn → Persist ═══
// Run: python3 tools/compile_nox.py stdlib/parasite/nox_loop.ol /tmp/nox_loop.olang && /tmp/nox_loop.olang
// Nox loads previous knowledge, processes stdin, learns, saves.
// Each run: smarter than before.

// ── KnowTree inline (minimal for standalone binary) ──
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
    return kt_mol_pack(__array_get(hs, 0) % 16, __array_get(hr, 0) % 16, __array_get(hv, 0) % 8, __array_get(ha, 0) % 8, __array_get(ht, 0) % 4);
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
    push(kt_texts, text); push(kt_chains, kt_build_chain(text));
    let _ = __set_at(kt_count, 0, __array_get(kt_count, 0) + 1);
};
fn kt_query(qtext) {
    let qc = kt_build_chain(qtext);
    let n = __array_get(kt_count, 0);
    let best_i = [0 - 1]; let best_d = [999999];
    let i = 0;
    while i < n {
        let d = kt_chain_dist(qc, __array_get(kt_chains, i));
        if d < __array_get(best_d, 0) { let _ = __set_at(best_d, 0, d); let _ = __set_at(best_i, 0, i); };
        let i = i + 1;
    };
    if __array_get(best_i, 0) >= 0 { return __array_get(kt_texts, __array_get(best_i, 0)); };
    return "";
};
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
fn kt_load_file(path) {
    let data = __file_read(path);
    if len(data) == 0 { return 0; };
    let loaded = [0]; let ls = 0; let i = 0;
    while i <= len(data) {
        let is_nl = 0;
        if i == len(data) { let is_nl = 1; } else { if __char_code(char_at(data, i)) == 10 { let is_nl = 1; }; };
        if is_nl == 1 {
            if i > ls { let line = substr(data, ls, i);
                if len(line) > 2 { kt_learn(line); let _ = __set_at(loaded, 0, __array_get(loaded, 0) + 1); };
            }; let ls = i + 1;
        };
        let i = i + 1;
    };
    return __array_get(loaded, 0);
};

// ═══ BOOT ═══
let KNOWLEDGE_FILE = "data/nox_knowledge.dat";

// Load previous knowledge
let prev = kt_load_file(KNOWLEDGE_FILE);
emit "[nox] loaded " + __to_string(prev) + " facts from memory";

// Also load base facts if this is first run
if prev == 0 {
    let base = kt_load_file("data/facts.dat");
    emit "[nox] first run: loaded " + __to_string(base) + " base facts";
};
__heap_pin();

emit "[nox] ready. " + __to_string(__array_get(kt_count, 0)) + " facts in brain.";
emit "[nox] type a question, or 'learn: <fact>' to teach me.";
emit "[nox] type 'save' to persist, 'quit' to exit.";

// ═══ REPL LOOP ═══
// Note: VM reads stdin line by line when compiled as standalone
// For now this just processes what's piped in
emit "[nox] (pipe mode — send lines via stdin)";
