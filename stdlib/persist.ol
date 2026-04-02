// ═══ Persist — Nox Survives Restart ═══
// Spec: BP13 Persistence
//
// 3 layers:
//   1. Binary KnowTree save/load (NKB format)
//   2. Silk weights save/load (binary matrix dump)
//   3. WAL (Write-Ahead Log) for incremental learning
//
// Uses existing builtins: __file_write, __file_read, __file_append_bytes,
// __f64_to_le_bytes, __mx_w, __mxr, __array_with_cap, __array_get, __set_at

// ═══ BINARY KNOWTREE — Save/Load ═══
// Format: [magic:4 "NKB\n"][count:4 LE][entries...]
// Entry:  [text_len:2 LE][text_bytes:N]
// All numbers as byte arrays via __f64_to_le_bytes trick

// Helper: number → 2-byte LE array (modular arithmetic, not bit_and)
fn persist_u16_bytes(n) {
    let p_lo = __floor(n) - __floor(n / 256) * 256;
    let p_hi = __floor(n / 256) - __floor(n / 65536) * 256;
    let p_arr = [];
    push(p_arr, p_lo);
    push(p_arr, p_hi);
    return p_arr;
};

// Helper: number → 4-byte LE array
fn persist_u32_bytes(n) {
    let p_b0 = __floor(n) - __floor(n / 256) * 256;
    let p_b1 = __floor(n / 256) - __floor(n / 65536) * 256;
    let p_b2 = __floor(n / 65536) - __floor(n / 16777216) * 256;
    let p_b3 = __floor(n / 16777216) - __floor(n / 4294967296) * 256;
    let p_arr = [];
    push(p_arr, p_b0);
    push(p_arr, p_b1);
    push(p_arr, p_b2);
    push(p_arr, p_b3);
    return p_arr;
};

// Helper: read u16 LE from byte array at offset
fn persist_read_u16(data, off) {
    let lo = __char_code(char_at(data, off));
    let hi = __char_code(char_at(data, off + 1));
    return lo + hi * 256;
};

// Helper: read u32 LE from byte array at offset
fn persist_read_u32(data, off) {
    let b0 = __char_code(char_at(data, off));
    let b1 = __char_code(char_at(data, off + 1));
    let b2 = __char_code(char_at(data, off + 2));
    let b3 = __char_code(char_at(data, off + 3));
    return b0 + b1 * 256 + b2 * 65536 + b3 * 16777216;
};

// ═══ kt_save_binary: Save KnowTree to binary file ═══
// Much faster to load than text format
fn kt_save_binary(path) {
    let n = __array_get(kt_count, 0);
    // Build byte array: magic + count + entries
    let bytes = [];
    // Magic: N K B \n (78, 75, 66, 10)
    push(bytes, 78); push(bytes, 75); push(bytes, 66); push(bytes, 10);
    // Count: 4 bytes LE
    let cb = persist_u32_bytes(n);
    push(bytes, __array_get(cb, 0));
    push(bytes, __array_get(cb, 1));
    push(bytes, __array_get(cb, 2));
    push(bytes, __array_get(cb, 3));

    // Each entry: [text_len:2][text_bytes:N]
    let i = 0;
    while i < n {
        let text = __array_get(kt_texts, i);
        let tlen = len(text);
        let lb = persist_u16_bytes(tlen);
        push(bytes, __array_get(lb, 0));
        push(bytes, __array_get(lb, 1));
        // Text bytes (ASCII from u16 mols)
        let j = 0;
        while j < tlen {
            push(bytes, __char_code(char_at(text, j)));
            let j = j + 1;
        };
        let i = i + 1;
    };

    __file_append_bytes(path, bytes);
    return n;
};

// ═══ kt_load_binary: Load KnowTree from binary file ═══
fn kt_load_binary(path) {
    let data = __file_read(path);
    if len(data) < 8 { return 0; };

    // Check magic: N K B \n
    if __char_code(char_at(data, 0)) != 78 { return 0; };
    if __char_code(char_at(data, 1)) != 75 { return 0; };
    if __char_code(char_at(data, 2)) != 66 { return 0; };

    // Read count
    let count = persist_read_u32(data, 4);
    let loaded = [0];
    let off = [8]; // current offset

    let i = 0;
    while i < count {
        let cur = __array_get(off, 0);
        if cur + 2 > len(data) { return __array_get(loaded, 0); };

        // Read text_len
        let tlen = persist_read_u16(data, cur);
        let _ = __set_at(off, 0, cur + 2);
        let cur = __array_get(off, 0);

        if cur + tlen > len(data) { return __array_get(loaded, 0); };

        // Read text
        let text = substr(data, cur, cur + tlen);
        let _ = __set_at(off, 0, cur + tlen);

        if len(text) > 0 {
            kt_learn(text);
            let _ = __set_at(loaded, 0, __array_get(loaded, 0) + 1);
        };
        let i = i + 1;
    };

    return __array_get(loaded, 0);
};

// ═══ SILK WEIGHTS — Save/Load ═══
// Dump all non-zero mol_matrix entries to binary file
// Format: [magic:4 "SLK\n"][count:4 LE][entries...]
// Entry:  [index:2 LE][weight:2 LE] = 4 bytes per edge

fn silk_save(path) {
    let bytes = [];
    // Magic: S L K \n (83, 76, 75, 10)
    push(bytes, 83); push(bytes, 76); push(bytes, 75); push(bytes, 10);

    // First pass: count non-zero
    let count = [0];
    let i = 0;
    while i < 65536 {
        if __mxr(i) > 0 {
            let _ = __set_at(count, 0, __array_get(count, 0) + 1);
        };
        let i = i + 1;
    };

    // Write count
    let cb = persist_u32_bytes(__array_get(count, 0));
    push(bytes, __array_get(cb, 0));
    push(bytes, __array_get(cb, 1));
    push(bytes, __array_get(cb, 2));
    push(bytes, __array_get(cb, 3));

    // Second pass: write entries
    let i = 0;
    while i < 65536 {
        let w = __mxr(i);
        if w > 0 {
            let ib = persist_u16_bytes(i);
            let wb = persist_u16_bytes(w);
            push(bytes, __array_get(ib, 0));
            push(bytes, __array_get(ib, 1));
            push(bytes, __array_get(wb, 0));
            push(bytes, __array_get(wb, 1));
        };
        let i = i + 1;
    };

    __file_append_bytes(path, bytes);
    return __array_get(count, 0);
};

fn silk_load(path) {
    let data = __file_read(path);
    if len(data) < 8 { return 0; };

    // Check magic: S L K \n
    if __char_code(char_at(data, 0)) != 83 { return 0; };
    if __char_code(char_at(data, 1)) != 76 { return 0; };
    if __char_code(char_at(data, 2)) != 75 { return 0; };

    let count = persist_read_u32(data, 4);
    let loaded = [0];
    let off = 8;

    let i = 0;
    while i < count {
        if off + 4 > len(data) { return __array_get(loaded, 0); };
        let idx = persist_read_u16(data, off);
        let weight = persist_read_u16(data, off + 2);
        __mx_w(idx, weight);
        let off = off + 4;
        let _ = __set_at(loaded, 0, __array_get(loaded, 0) + 1);
        let i = i + 1;
    };

    return __array_get(loaded, 0);
};

// ═══ WAL — Write-Ahead Log ═══
// Append-only log for incremental learning
// Record: [op:1][key:2 LE][value:2 LE] = 5 bytes
// Ops: 1=SILK_FIRE, 2=KT_LEARN_MARKER, 3=SILK_DECAY

let WAL_SILK_FIRE = 1;
let WAL_KT_LEARN = 2;
let WAL_SILK_DECAY = 3;

fn wal_append(path, op, key, value) {
    let bytes = [];
    push(bytes, op);
    let kb = persist_u16_bytes(key);
    push(bytes, __array_get(kb, 0));
    push(bytes, __array_get(kb, 1));
    let vb = persist_u16_bytes(value);
    push(bytes, __array_get(vb, 0));
    push(bytes, __array_get(vb, 1));
    __file_append_bytes(path, bytes);
};

// ═══ FULL SAVE — KnowTree + Silk in one call ═══
fn persist_save_all(base_path) {
    let kt_path = base_path + "/knowtree.nkb";
    let sk_path = base_path + "/silk.slk";
    // Delete old files by overwriting with empty then writing
    __file_write(kt_path, "");
    __file_write(sk_path, "");
    let nk = kt_save_binary(kt_path);
    let ns = silk_save(sk_path);
    return nk + ns;
};

// ═══ FULL LOAD — KnowTree + Silk in one call ═══
fn persist_load_all(base_path) {
    let kt_path = base_path + "/knowtree.nkb";
    let sk_path = base_path + "/silk.slk";
    let nk = kt_load_binary(kt_path);
    let ns = silk_load(sk_path);
    return nk + ns;
};

emit "persist loaded (BP13)";
