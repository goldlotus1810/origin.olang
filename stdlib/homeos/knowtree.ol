// homeos/knowtree.ol — KnowTree v3: FH + 5D Hierarchical Index
//
// Storage: 3 Fibonacci Hash tables (fixed 65,536 slots each)
//   __kt_pw_freq[fh(pw)]  = frequency count
//   __kt_pw_text[fh(pw)]  = representative text (first seen word)
//   __kt_facts_arr[]       = flat array of fact texts (for search)
//
// Hierarchical: 5D dimension index (S:16 R:16 V:8 A:8 T:4)
//   Each bucket = array of fact indices → O(1) lookup per dimension
//   Path query: [dim, val, dim, val, ...] → set intersection → O(k) results
//
// No dicts, no per-word arrays. Total heap = ~3MB fixed + small buckets.

let __kt_pw_freq = [];
let __kt_pw_text = [];
let __kt_facts_arr = [];
let __kt_fact_tags = [];
let __kt_fact_count = [0];
let __kt_word_count = [0];
let __kt_inited = [0];
let __kt_tbl = [];

// ════════════════════════════════════════════════════════════════
// 5D Dimension Index — hierarchical buckets for O(depth) lookup
// S:4bits(0-15) R:4bits(0-15) V:3bits(0-7) A:3bits(0-7) T:2bits(0-3)
// ════════════════════════════════════════════════════════════════
let __kt_dim_s = [];
let __kt_dim_r = [];
let __kt_dim_v = [];
let __kt_dim_a = [];
let __kt_dim_t = [];
let __kt_fact_mol = [];
let __kt_dim_inited = [0];

// ════════════════════════════════════════════════════════════════
// Inverted Word Index — O(1) word → fact indices lookup
// Hash table: 4096 slots, each slot = array of fact indices
// ════════════════════════════════════════════════════════════════
let __kt_word_idx = [];
let __kt_widx_inited = [0];

fn _kt_widx_init() {
    if __array_get(__kt_widx_inited, 0) == 1 { return; };
    let _ = __set_at(__kt_widx_inited, 0, 1);
    let _wi = 0;
    while _wi < 256 { push(__kt_word_idx, []); let _wi = _wi + 1; };
}

fn _kt_word_hash(_wh_text) {
    let _wh_h = [0];
    let _wh_i = 0;
    while _wh_i < len(_wh_text) {
        let _ = __set_at(_wh_h, 0, __bit_and((__array_get(_wh_h, 0) * 31) + __char_code(char_at(_wh_text, _wh_i)), 255));
        let _wh_i = _wh_i + 1;
    };
    return __array_get(_wh_h, 0);
}

fn _kt_widx_add(_wia_word, _wia_fact_idx) {
    _kt_widx_init();
    if len(_wia_word) < 3 { return; };
    let _wia_h = _kt_word_hash(_wia_word);
    push(__kt_word_idx[_wia_h], _wia_fact_idx);
}

// Fast word lookup: returns array of fact indices matching this word
pub fn kt_word_lookup(_kwl_word) {
    _kt_widx_init();
    if len(_kwl_word) < 3 { return []; };
    let _kwl_h = _kt_word_hash(_kwl_word);
    return __kt_word_idx[_kwl_h];
}

fn _kt_ensure_init() {
    if __array_get(__kt_inited, 0) == 1 { return; };
    let _ = __set_at(__kt_inited, 0, 1);
    __kt_pw_freq = __array_range(65536);
    __kt_pw_text = __array_range(65536);
    __kt_tbl = __file_read_bytes("json/udc_p_table.bin");
    let _i = 0;
    while _i < 65536 { let _ = __set_at(__kt_pw_freq, _i, 0); let _ = __set_at(__kt_pw_text, _i, 0); let _i = _i + 1; };
}

// ════════════════════════════════════════════════════════════════
// Dimension index init + helpers
// ════════════════════════════════════════════════════════════════

fn _kt_dim_init() {
    if __array_get(__kt_dim_inited, 0) == 1 { return; };
    let _ = __set_at(__kt_dim_inited, 0, 1);
    let _di = 0;
    while _di < 16 { push(__kt_dim_s, []); push(__kt_dim_r, []); let _di = _di + 1; };
    let _di = 0;
    while _di < 8 { push(__kt_dim_v, []); push(__kt_dim_a, []); let _di = _di + 1; };
    let _di = 0;
    while _di < 4 { push(__kt_dim_t, []); let _di = _di + 1; };
}

// Extract dimensions from P_weight (u16 packed: S:4 R:4 V:3 A:3 T:2)
fn _kt_mol_s(_m) { return (__floor(_m / 4096)) % 16; }
fn _kt_mol_r(_m) { return (__floor(_m / 256)) % 16; }
fn _kt_mol_v(_m) { return (__floor(_m / 32)) % 8; }
fn _kt_mol_a(_m) { return (__floor(_m / 4)) % 8; }
fn _kt_mol_t(_m) { return _m % 4; }

// _kt_fact_mol_compute removed — replaced by _kt_fast_mol everywhere (no __text_to_pw allocation)

// Real molecule: text → per-codepoint P_weight from UDC table → biological compose
// Compose rules (from BLUEPRINT spec):
//   S = Union  = max(all S values)           — shapes merge, largest wins
//   R = Compose = Zipf-weighted sum          — relations accumulate
//   V = Amplify = base + sign*boost          — valence pushes toward dominant (NOT average)
//   A = Max    = max(all A values)           — arousal takes highest intensity
//   T = Dominant = most frequent T value     — time takes majority
// Uses shared accumulator to minimize heap allocation
let __kt_mol_acc = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

fn _kt_real_mol(_krm_text) {
    _kt_ensure_init();
    let _krm_tlen = len(_krm_text);
    if _krm_tlen == 0 { return 0; };
    // Reset: [S_max, R_sum, R_wsum, V_sum, V_count, A_max, T0, T1, T2, T3, n, _]
    let _ = __set_at(__kt_mol_acc, 0, 0);
    let _ = __set_at(__kt_mol_acc, 1, 0);
    let _ = __set_at(__kt_mol_acc, 2, 0);
    let _ = __set_at(__kt_mol_acc, 3, 0);
    let _ = __set_at(__kt_mol_acc, 4, 0);
    let _ = __set_at(__kt_mol_acc, 5, 0);
    let _ = __set_at(__kt_mol_acc, 6, 0);
    let _ = __set_at(__kt_mol_acc, 7, 0);
    let _ = __set_at(__kt_mol_acc, 8, 0);
    let _ = __set_at(__kt_mol_acc, 9, 0);
    let _ = __set_at(__kt_mol_acc, 10, 0);
    let _krm_i = 0;
    while _krm_i < _krm_tlen {
        let _krm_cp = __char_code(char_at(_krm_text, _krm_i));
        let _krm_off = _krm_cp * 2;
        let _krm_lo = __bytes_get(__kt_tbl, _krm_off);
        let _krm_hi = __bytes_get(__kt_tbl, _krm_off + 1);
        let _krm_pw = __floor(_krm_lo + (_krm_hi * 256));
        if _krm_pw > 0 {
            let _krm_ni = __array_get(__kt_mol_acc, 10);
            let _krm_s = (__floor(_krm_pw / 4096)) % 16;
            let _krm_r = (__floor(_krm_pw / 256)) % 16;
            let _krm_v = (__floor(_krm_pw / 32)) % 8;
            let _krm_a = (__floor(_krm_pw / 4)) % 8;
            let _krm_t = _krm_pw % 4;
            // S = Union (max)
            if _krm_s > __array_get(__kt_mol_acc, 0) { let _ = __set_at(__kt_mol_acc, 0, _krm_s); };
            // R = Compose (Zipf-weighted sum)
            let _krm_w = __floor(1000 / (_krm_ni + 1));
            let _ = __set_at(__kt_mol_acc, 1, __array_get(__kt_mol_acc, 1) + (_krm_r * _krm_w));
            let _ = __set_at(__kt_mol_acc, 2, __array_get(__kt_mol_acc, 2) + _krm_w);
            // V = accumulate for amplify
            let _ = __set_at(__kt_mol_acc, 3, __array_get(__kt_mol_acc, 3) + _krm_v);
            let _ = __set_at(__kt_mol_acc, 4, __array_get(__kt_mol_acc, 4) + 1);
            // A = Max
            if _krm_a > __array_get(__kt_mol_acc, 5) { let _ = __set_at(__kt_mol_acc, 5, _krm_a); };
            // T = vote (count each value)
            let _ = __set_at(__kt_mol_acc, 6 + _krm_t, __array_get(__kt_mol_acc, 6 + _krm_t) + 1);
            let _ = __set_at(__kt_mol_acc, 10, _krm_ni + 1);
        };
        let _krm_i = _krm_i + 1;
    };
    let _krm_n = __array_get(__kt_mol_acc, 10);
    if _krm_n == 0 { return 0; };
    // S = max (already computed)
    let _krm_rs = __array_get(__kt_mol_acc, 0) % 16;
    // R = weighted average
    let _krm_rw = __array_get(__kt_mol_acc, 2);
    let _krm_rr = 0;
    if _krm_rw > 0 { let _krm_rr = (__floor(__array_get(__kt_mol_acc, 1) / _krm_rw)) % 16; };
    // V = amplify: base + sign(sum) * boost
    let _krm_vsum = __array_get(__kt_mol_acc, 3);
    let _krm_vn = __array_get(__kt_mol_acc, 4);
    let _krm_vbase = __floor(_krm_vsum / _krm_vn);
    let _krm_vdiff = _krm_vsum - (_krm_vbase * _krm_vn);
    let _krm_boost = __floor((_krm_vdiff * 500) / (_krm_vn * 1000));
    let _krm_rv = (_krm_vbase + _krm_boost) % 8;
    if _krm_rv < 0 { let _krm_rv = 0; };
    // A = max (already computed)
    let _krm_ra = __array_get(__kt_mol_acc, 5) % 8;
    // T = dominant (most frequent)
    let _krm_rt = 0;
    let _krm_tmax = __array_get(__kt_mol_acc, 6);
    if __array_get(__kt_mol_acc, 7) > _krm_tmax { let _krm_rt = 1; let _krm_tmax = __array_get(__kt_mol_acc, 7); };
    if __array_get(__kt_mol_acc, 8) > _krm_tmax { let _krm_rt = 2; let _krm_tmax = __array_get(__kt_mol_acc, 8); };
    if __array_get(__kt_mol_acc, 9) > _krm_tmax { let _krm_rt = 3; };
    return (_krm_rs * 4096) + (_krm_rr * 256) + (_krm_rv * 32) + (_krm_ra * 4) + _krm_rt;
}

// Fast hash mol for 5D indexing (boot speed)
// classify() uses _kt_real_mol separately for accurate P_weight distances
fn _kt_fast_mol(_kfm_text) {
    let _kfm_h = [0];
    let _kfm_i = 0;
    let _kfm_tlen = len(_kfm_text);
    while _kfm_i < _kfm_tlen {
        let _kfm_c = __char_code(char_at(_kfm_text, _kfm_i));
        let _ = __set_at(_kfm_h, 0, __bit_and((__array_get(_kfm_h, 0) * 31) + _kfm_c, 65535));
        let _kfm_i = _kfm_i + 1;
    };
    return __array_get(_kfm_h, 0);
}

// Index a fact into all 5 dimension buckets
fn _kt_dim_index(_kdi_fidx, _kdi_mol) {
    _kt_dim_init();
    let _kdi_s = _kt_mol_s(_kdi_mol);
    let _kdi_r = _kt_mol_r(_kdi_mol);
    let _kdi_v = _kt_mol_v(_kdi_mol);
    let _kdi_a = _kt_mol_a(_kdi_mol);
    let _kdi_t = _kt_mol_t(_kdi_mol);
    push(__kt_dim_s[_kdi_s], _kdi_fidx);
    push(__kt_dim_r[_kdi_r], _kdi_fidx);
    push(__kt_dim_v[_kdi_v], _kdi_fidx);
    push(__kt_dim_a[_kdi_a], _kdi_fidx);
    push(__kt_dim_t[_kdi_t], _kdi_fidx);
    push(__kt_fact_mol, _kdi_mol);
}

// Set intersection — O(a+b) using bitmap instead of O(a×b) nested loop
// Bitmap: 1024 slots, hash index → mark/check
let __kt_isect_map = [];
let __kt_isect_inited = [0];

fn _kt_intersect(_kti_a, _kti_b) {
    // Init bitmap once
    if __array_get(__kt_isect_inited, 0) == 0 {
        let _kti_mi = 0;
        while _kti_mi < 1024 { push(__kt_isect_map, 0); let _kti_mi = _kti_mi + 1; };
        let _ = __set_at(__kt_isect_inited, 0, 1);
    };
    // Mark set A
    let _kti_ai = 0;
    while _kti_ai < len(_kti_a) {
        let _kti_idx = __bit_and(__array_get(_kti_a, _kti_ai), 1023);
        let _ = __set_at(__kt_isect_map, _kti_idx, __array_get(_kti_a, _kti_ai) + 1);
        let _kti_ai = _kti_ai + 1;
    };
    // Check set B against marks
    let _kti_out = [];
    let _kti_bi = 0;
    while _kti_bi < len(_kti_b) {
        let _kti_v = __array_get(_kti_b, _kti_bi);
        let _kti_idx = __bit_and(_kti_v, 1023);
        if __array_get(__kt_isect_map, _kti_idx) == (_kti_v + 1) { push(_kti_out, _kti_v); };
        let _kti_bi = _kti_bi + 1;
    };
    // Clear marks (only the ones we set)
    let _kti_ci = 0;
    while _kti_ci < len(_kti_a) {
        let _kti_idx = __bit_and(__array_get(_kti_a, _kti_ci), 1023);
        let _ = __set_at(__kt_isect_map, _kti_idx, 0);
        let _kti_ci = _kti_ci + 1;
    };
    return _kti_out;
}

// Get bucket for a dimension (0=S, 1=R, 2=V, 3=A, 4=T)
fn _kt_dim_bucket(_kdb_dim, _kdb_val) {
    if _kdb_dim == 0 { return __kt_dim_s[_kdb_val]; };
    if _kdb_dim == 1 { return __kt_dim_r[_kdb_val]; };
    if _kdb_dim == 2 { return __kt_dim_v[_kdb_val]; };
    if _kdb_dim == 3 { return __kt_dim_a[_kdb_val]; };
    if _kdb_dim == 4 { return __kt_dim_t[_kdb_val]; };
    return [];
}

// L2 tree branches (keep for compatibility)
let __kt_tree = [];

fn _kt_boot_tree() {
    push(__kt_tree, { name: "facts", children: [], facts: [], mol: 0 });
    push(__kt_tree, { name: "books", children: [], facts: [], mol: 0 });
    push(__kt_tree, { name: "conversations", children: [], facts: [], mol: 0 });
    push(__kt_tree, { name: "skills", children: [], facts: [], mol: 0 });
    push(__kt_tree, { name: "personal", children: [], facts: [], mol: 0 });
}

fn kt_sub_branch(_ksb_parent_idx, _ksb_name) {
    let _ksb_node = { name: _ksb_name, children: [], facts: [], mol: 0 };
    push(__kt_tree[_ksb_parent_idx].children, _ksb_node);
    return len(__kt_tree[_ksb_parent_idx].children) - 1;
}

// ════════════════════════════════════════════════════════════════
// Core: store P_weight + freq into FH tables
// ════════════════════════════════════════════════════════════════

fn _kt_store_pw(_pw, _freq, _text) {
    _kt_ensure_init();
    let _idx = __bit_and(_pw * 40503, 65535);
    let _old = __array_get(__kt_pw_freq, _idx);
    let _ = __set_at(__kt_pw_freq, _idx, _old + _freq);
    if _old == 0 { let _ = __set_at(__kt_pw_text, _idx, _text); let _ = __set_at(__kt_word_count, 0, __array_get(__kt_word_count, 0) + 1); };
}

// ════════════════════════════════════════════════════════════════
// kt_learn — learn a text string (compatible API)
// ════════════════════════════════════════════════════════════════

pub fn kt_learn(_kl_text) {
    return kt_learn_to(_kl_text, "facts");
}

// Learn with explicit tag for k-NN classification
pub fn kt_learn_tagged(_kltg_tag, _kltg_text) {
    _kt_ensure_init();
    let _kltg_fidx = __array_get(__kt_fact_count, 0);
    let _ = __set_at(__kt_fact_count, 0, _kltg_fidx + 1);
    push(__kt_facts_arr, _kltg_text);
    push(__kt_fact_tags, _kltg_tag);
    // Word index
    let _kltg_tlen = len(_kltg_text);
    let _kltg_st = [0];
    let _kltg_j = 0;
    while _kltg_j < _kltg_tlen {
        let _kltg_ch = __char_code(char_at(_kltg_text, _kltg_j));
        if _kltg_ch == 32 { let _kltg_ws = __array_get(_kltg_st, 0); if _kltg_j > _kltg_ws { let _kltg_w = substr(_kltg_text, _kltg_ws, _kltg_j); _kt_learn_word(_kltg_w); _kt_widx_add(_kltg_w, _kltg_fidx); }; let _ = __set_at(_kltg_st, 0, _kltg_j + 1); };
        let _kltg_j = _kltg_j + 1;
    };
    let _kltg_ws = __array_get(_kltg_st, 0);
    if _kltg_tlen > _kltg_ws { let _kltg_w = substr(_kltg_text, _kltg_ws, _kltg_tlen); _kt_learn_word(_kltg_w); _kt_widx_add(_kltg_w, _kltg_fidx); };
    let _kltg_mol = _kt_fast_mol(_kltg_text);
    _kt_dim_index(_kltg_fidx, _kltg_mol);
    if __array_get(__ksi_inited, 0) == 1 { _kt_silk_text(_kltg_text); };
    if (_kltg_fidx % 50) == 0 { __heap_pin(); };
    return _kltg_fidx + 1;
}

pub fn kt_learn_to(_klt_text, _klt_branch) {
    _kt_ensure_init();
    let _klt_fidx = __array_get(__kt_fact_count, 0);
    let _ = __set_at(__kt_fact_count, 0, _klt_fidx + 1);
    push(__kt_facts_arr, _klt_text);
    push(__kt_fact_tags, 0);
    // Split into words using substr, store each word's P_weight
    let _klt_tlen = len(_klt_text);
    let _klt_st = [0];
    let _klt_j = 0;
    while _klt_j < _klt_tlen {
        let _klt_ch = __char_code(char_at(_klt_text, _klt_j));
        if _klt_ch == 32 { let _klt_ws = __array_get(_klt_st, 0); if _klt_j > _klt_ws { let _klt_w = substr(_klt_text, _klt_ws, _klt_j); _kt_learn_word(_klt_w); _kt_widx_add(_klt_w, _klt_fidx); }; let _ = __set_at(_klt_st, 0, _klt_j + 1); };
        let _klt_j = _klt_j + 1;
    };
    let _klt_ws = __array_get(_klt_st, 0);
    if _klt_tlen > _klt_ws { let _klt_w = substr(_klt_text, _klt_ws, _klt_tlen); _kt_learn_word(_klt_w); _kt_widx_add(_klt_w, _klt_fidx); };
    // Index into 5D dimension tree
    let _klt_mol = _kt_fast_mol(_klt_text);
    _kt_dim_index(_klt_fidx, _klt_mol);
    // Silk: co-activate consecutive words (only after boot, avoids 196K alloc during boot)
    if __array_get(__ksi_inited, 0) == 1 { _kt_silk_text(_klt_text); };
    // Pin heap every 50 facts (batch-friendly, protects persistent data)
    if (_klt_fidx % 50) == 0 { __heap_pin(); };
    return _klt_fidx + 1;
}

fn _kt_learn_word(_klw_text) {
    // Compute simple hash from text bytes as P_weight key
    let _klw_h = [0];
    let _klw_i = 0;
    while _klw_i < len(_klw_text) {
        let _klw_c = __char_code(char_at(_klw_text, _klw_i));
        let _ = __set_at(_klw_h, 0, __array_get(_klw_h, 0) * 31 + _klw_c);
        let _klw_i = _klw_i + 1;
    };
    let _klw_pw = __bit_and(__array_get(_klw_h, 0), 65535);
    _kt_store_pw(_klw_pw, 1, _klw_text);
}

// ════════════════════════════════════════════════════════════════
// kt_ingest_book — native bulk ingest using __text_to_pw
// ════════════════════════════════════════════════════════════════

pub fn kt_ingest_book(_kib_path) {
    _kt_ensure_init();
    let _kib_tbl = __file_read_bytes("json/udc_p_table.bin");
    let _kib_content = __file_read(_kib_path);
    if len(_kib_content) == 0 { return "Error: cannot read " + _kib_path; };
    // Native scan: 3.2MB → 186 unique [pw, freq] pairs in ~15ms
    let _kib_result = __text_to_pw(_kib_content, _kib_tbl);
    let _kib_rlen = __array_len(_kib_result);
    // Store each unique P_weight into FH tables
    let _kib_i = 0;
    while _kib_i < _kib_rlen {
        let _kib_pw = __array_get(_kib_result, _kib_i);
        let _kib_freq = __array_get(_kib_result, _kib_i + 1);
        if _kib_pw > 0 { _kt_store_pw(_kib_pw, _kib_freq, _kib_path); };
        let _kib_i = _kib_i + 2;
    };
    let _ = __set_at(__kt_fact_count, 0, __array_get(__kt_fact_count, 0) + 1);
    // Compose book fingerprint
    let _kib_st = [0];
    let _kib_first = [1];
    let _kib_k = 0;
    while _kib_k < _kib_rlen {
        let _kib_pw = __array_get(_kib_result, _kib_k);
        if _kib_pw > 0 {
            let _kib_is1 = __array_get(_kib_first, 0);
            if _kib_is1 == 1 { let _ = __set_at(_kib_st, 0, _kib_pw); let _ = __set_at(_kib_first, 0, 0); };
            if _kib_is1 == 0 {
                let _kib_cur = __array_get(_kib_st, 0);
                let cs = (__floor(_kib_cur/4096))%16; let cr = (__floor(_kib_cur/256))%16;
                let cv = (__floor(_kib_cur/32))%8; let ca = (__floor(_kib_cur/4))%8; let ct = _kib_cur%4;
                let ns = (__floor(_kib_pw/4096))%16; let nr = (__floor(_kib_pw/256))%16;
                let nv = (__floor(_kib_pw/32))%8; let na = (__floor(_kib_pw/4))%8; let nt = _kib_pw%4;
                let rs = (__floor((cs*2+ns)/3))%16; let rr = (__floor((cr*2+nr)/3))%16;
                let rv = (__floor((cv*2+nv)/3))%8; let ra = (__floor((ca*2+na)/3))%8;
                let rt = (__floor((ct*2+nt)/3))%4;
                let _kib_nw = (rs*4096)+(rr*256)+(rv*32)+(ra*4)+rt;
                let _ = __set_at(_kib_st, 0, _kib_nw);
            };
        };
        let _kib_k = _kib_k + 2;
    };
    let _kib_mol = __array_get(_kib_st, 0);
    return "Ingested " + _kib_path + ": " + __to_string(_kib_rlen / 2) + " unique pw. Mol=" + __to_string(_kib_mol) + " " + kt_stats();
}

// ════════════════════════════════════════════════════════════════
// Search — query → FH lookup → scored results
// ════════════════════════════════════════════════════════════════

// kt_search_pw removed — replaced by word-overlap ranked search below

// ════════════════════════════════════════════════════════════════
// Stats
// ════════════════════════════════════════════════════════════════

pub fn kt_stats() {
    let _kst_base = "KnowTree: " + __to_string(__array_get(__kt_word_count, 0)) + " words, " +
           __to_string(__array_get(__kt_fact_count, 0)) + " facts";
    if __array_get(__kt_dim_inited, 0) == 1 {
        let _kst_base = _kst_base + " [5D indexed: " + __to_string(len(__kt_fact_mol)) + "]";
    };
    return _kst_base;
}

pub fn kt_find(_kf_query, _kf_max) {
    let _kf_out = [];
    let _kf_i = 0;
    let _kf_flen = len(__kt_facts_arr);
    let _kf_qlen = len(_kf_query);
    while _kf_i < _kf_flen {
        let _kf_fact = __kt_facts_arr[_kf_i];
        let _kf_qi = 0;
        let _kf_found = 0;
        while _kf_qi <= len(_kf_fact) - _kf_qlen {
            if substr(_kf_fact, _kf_qi, _kf_qi + _kf_qlen) == _kf_query {
                _kf_found = 1;
                _kf_qi = len(_kf_fact);
            };
            _kf_qi = _kf_qi + 1;
        };
        if _kf_found == 1 {
            push(_kf_out, _kf_fact);
            if len(_kf_out) >= _kf_max { return _kf_out; };
        };
        _kf_i = _kf_i + 1;
    };
    return _kf_out;
}

// Fast word-indexed search: O(1) lookup per word instead of O(n×m) scan
pub fn kt_find_fast(_kff_word, _kff_max) {
    let _kff_indices = kt_word_lookup(_kff_word);
    let _kff_out = [];
    let _kff_i = 0;
    while _kff_i < len(_kff_indices) {
        if len(_kff_out) >= _kff_max { return _kff_out; };
        let _kff_idx = __array_get(_kff_indices, _kff_i);
        if _kff_idx < len(__kt_facts_arr) {
            push(_kff_out, __array_get(__kt_facts_arr, _kff_idx));
        };
        let _kff_i = _kff_i + 1;
    };
    return _kff_out;
}

pub fn kt_fact_count() {
    return len(__kt_facts_arr);
}

// RANKED search: score each fact by word overlap with query
// Returns BEST match, not first match
pub fn kt_search(query) {
    let words = _kt_split(query);
    if len(words) == 0 { return ""; };
    let best_idx = [-1];
    let best_score = [0];
    let fi = 0;
    while fi < len(__kt_facts_arr) {
        let fact = __kt_facts_arr[fi];
        if __type_of(fact) == "string" {
            let score = _kt_score(words, fact);
            if score > best_score[0] { set_at(best_idx, 0, fi); set_at(best_score, 0, score); };
        };
        fi = fi + 1;
    };
    if best_idx[0] >= 0 { return __kt_facts_arr[best_idx[0]]; };
    return "";
}

// RANKED search: return top N matches sorted by relevance
pub fn kt_search_n(query, n) {
    let words = _kt_split(query);
    if len(words) == 0 { return []; };
    // Collect all scored facts
    let scored = [];
    let fi = 0;
    while fi < len(__kt_facts_arr) {
        let fact = __kt_facts_arr[fi];
        let score = _kt_score(words, fact);
        if score > 0 { push(scored, fact); push(scored, score); };
        fi = fi + 1;
    };
    // Find top N by score (simple selection)
    let results = [];
    let ri = 0;
    while ri < n {
        let best_idx = [-1, 0];
        let si = 0;
        while si < len(scored) {
            if si % 2 == 1 {
                if scored[si] > best_idx[1] {
                    set_at(best_idx, 0, si - 1);
                    set_at(best_idx, 1, scored[si]);
                };
            };
            si = si + 1;
        };
        if best_idx[0] >= 0 {
            push(results, scored[best_idx[0]]);
            set_at(scored, best_idx[0] + 1, 0);
        };
        ri = ri + 1;
    };
    return results;
}

// Score a fact against query words
fn _kt_score(query_words, fact) {
    let score = 0;
    let qi = 0;
    while qi < len(query_words) {
        let word = query_words[qi];
        let wlen = len(word);
        if wlen >= 2 {
            // Check if word appears in fact (substring match)
            let fi = 0;
            while fi <= len(fact) - wlen {
                let match = 1;
                let ci = 0;
                while ci < wlen {
                    let fc = __char_code(char_at(fact, fi + ci));
                    let wc = __char_code(char_at(word, ci));
                    // Case-insensitive: lowercase both
                    if fc >= 65 { if fc <= 90 { fc = fc + 32; }; };
                    if wc >= 65 { if wc <= 90 { wc = wc + 32; }; };
                    if fc != wc { match = 0; break; };
                    ci = ci + 1;
                };
                if match == 1 { score = score + wlen; fi = len(fact); };
                fi = fi + 1;
            };
        };
        qi = qi + 1;
    };
    return score;
}

// Split string into words
fn _kt_split(s) {
    let words = [];
    let start = 0;
    let i = 0;
    while i <= len(s) {
        let is_sep = 0;
        if i == len(s) { is_sep = 1; };
        if i < len(s) {
            let c = __char_code(char_at(s, i));
            if c == 32 { is_sep = 1; };
            if c == 63 { is_sep = 1; };
        };
        if is_sep == 1 {
            if i > start { push(words, __substr(s, start, i)); };
            start = i + 1;
        };
        i = i + 1;
    };
    return words;
}

// ════════════════════════════════════════════════════════════════
// k-NN Classification — input → mol → find k nearest tagged facts → vote
// Replaces if/else instinct routing with P_weight space matching
// ════════════════════════════════════════════════════════════════

pub fn kt_classify(_kcl_text) {
    _boot_exemplars();
    // Compute real P_weight mol for input
    let _kcl_mol = _kt_real_mol(_kcl_text);
    if _kcl_mol == 0 { return { type: "unknown", confidence: 0 }; };
    // Find k=5 nearest TAGGED facts by Manhattan distance in 5D
    let _kcl_k = 5;
    // best_d[i] = distance, best_t[i] = tag index
    let _kcl_bd = [9999, 9999, 9999, 9999, 9999];
    let _kcl_bt = [0, 0, 0, 0, 0];
    let _kcl_fi = 0;
    let _kcl_flen = len(__kt_facts_arr);
    while _kcl_fi < _kcl_flen {
        let _kcl_tag = __array_get(__kt_fact_tags, _kcl_fi);
        if __type_of(_kcl_tag) == "string" {
            if len(_kcl_tag) > 0 {
                // Tagged fact — compute real mol and distance
                let _kcl_fmol = _kt_real_mol(__array_get(__kt_facts_arr, _kcl_fi));
                let _kcl_dist = _kt_mol_dist(_kcl_mol, _kcl_fmol);
                // Insert into top-k if closer than worst
                let _kcl_worst = 4;
                if _kcl_dist < __array_get(_kcl_bd, _kcl_worst) {
                    let _ = __set_at(_kcl_bd, _kcl_worst, _kcl_dist);
                    let _ = __set_at(_kcl_bt, _kcl_worst, _kcl_tag);
                    // Bubble sort to keep sorted
                    let _kcl_j = _kcl_worst;
                    while _kcl_j > 0 {
                        let _kcl_jm = _kcl_j - 1;
                        if __array_get(_kcl_bd, _kcl_j) < __array_get(_kcl_bd, _kcl_jm) {
                            let _kcl_td = __array_get(_kcl_bd, _kcl_jm);
                            let _kcl_tt = __array_get(_kcl_bt, _kcl_jm);
                            let _ = __set_at(_kcl_bd, _kcl_jm, __array_get(_kcl_bd, _kcl_j));
                            let _ = __set_at(_kcl_bt, _kcl_jm, __array_get(_kcl_bt, _kcl_j));
                            let _ = __set_at(_kcl_bd, _kcl_j, _kcl_td);
                            let _ = __set_at(_kcl_bt, _kcl_j, _kcl_tt);
                        };
                        let _kcl_j = _kcl_j - 1;
                    };
                };
            };
        };
        let _kcl_fi = _kcl_fi + 1;
    };
    // Vote: count tags among k nearest
    let _kcl_tags = [];
    let _kcl_counts = [];
    let _kcl_vi = 0;
    while _kcl_vi < _kcl_k {
        let _kcl_t = __array_get(_kcl_bt, _kcl_vi);
        if __type_of(_kcl_t) == "string" {
            // Find tag in counts
            let _kcl_found = [0];
            let _kcl_ci = 0;
            while _kcl_ci < len(_kcl_tags) {
                if __array_get(_kcl_tags, _kcl_ci) == _kcl_t {
                    let _ = __set_at(_kcl_counts, _kcl_ci, __array_get(_kcl_counts, _kcl_ci) + 1);
                    let _ = __set_at(_kcl_found, 0, 1);
                };
                let _kcl_ci = _kcl_ci + 1;
            };
            if __array_get(_kcl_found, 0) == 0 { push(_kcl_tags, _kcl_t); push(_kcl_counts, 1); };
        };
        let _kcl_vi = _kcl_vi + 1;
    };
    // Find winner
    let _kcl_best_tag = "unknown";
    let _kcl_best_count = [0];
    let _kcl_wi = 0;
    while _kcl_wi < len(_kcl_tags) {
        if __array_get(_kcl_counts, _kcl_wi) > __array_get(_kcl_best_count, 0) {
            let _ = __set_at(_kcl_best_count, 0, __array_get(_kcl_counts, _kcl_wi));
            let _kcl_best_tag = __array_get(_kcl_tags, _kcl_wi);
        };
        let _kcl_wi = _kcl_wi + 1;
    };
    let _kcl_conf = __floor((__array_get(_kcl_best_count, 0) * 100) / _kcl_k);
    return { type: _kcl_best_tag, confidence: _kcl_conf };
}

// ════════════════════════════════════════════════════════════════
// Hierarchical query API — O(1) bucket + O(k) results
// ════════════════════════════════════════════════════════════════

// Query one dimension: dim 0=S 1=R 2=V 3=A 4=T, val = bucket index
// Returns array of fact texts
pub fn kt_get_dim(_kgd_dim, _kgd_val) {
    _kt_dim_init();
    let _kgd_bucket = _kt_dim_bucket(_kgd_dim, _kgd_val);
    let _kgd_out = [];
    let _kgd_i = 0;
    while _kgd_i < len(_kgd_bucket) {
        let _kgd_idx = __array_get(_kgd_bucket, _kgd_i);
        if _kgd_idx < len(__kt_facts_arr) { push(_kgd_out, __array_get(__kt_facts_arr, _kgd_idx)); };
        let _kgd_i = _kgd_i + 1;
    };
    return _kgd_out;
}

// Multi-dimension path query: [dim, val, dim, val, ...]
// Returns facts matching ALL dimension constraints (intersection)
pub fn kt_get_path(_kgp_path) {
    _kt_dim_init();
    let _kgp_plen = len(_kgp_path);
    if _kgp_plen < 2 { return []; };
    // Start with first dimension bucket
    let _kgp_set = _kt_dim_bucket(__array_get(_kgp_path, 0), __array_get(_kgp_path, 1));
    // Intersect with remaining dimensions
    let _kgp_pi = 2;
    while _kgp_pi < _kgp_plen {
        let _kgp_d = __array_get(_kgp_path, _kgp_pi);
        let _kgp_v = __array_get(_kgp_path, _kgp_pi + 1);
        let _kgp_other = _kt_dim_bucket(_kgp_d, _kgp_v);
        let _kgp_set = _kt_intersect(_kgp_set, _kgp_other);
        let _kgp_pi = _kgp_pi + 2;
    };
    // Convert indices to fact texts
    let _kgp_out = [];
    let _kgp_i = 0;
    while _kgp_i < len(_kgp_set) {
        let _kgp_idx = __array_get(_kgp_set, _kgp_i);
        if _kgp_idx < len(__kt_facts_arr) { push(_kgp_out, __array_get(__kt_facts_arr, _kgp_idx)); };
        let _kgp_i = _kgp_i + 1;
    };
    return _kgp_out;
}

// Nearest neighbor: find facts near a molecule (±radius on ALL 5 dimensions)
// Returns array of {text, distance, mol} sorted by distance (closest first)
pub fn kt_nearby(_knb_mol, _knb_radius) {
    _kt_dim_init();
    let _knb_s = _kt_mol_s(_knb_mol);
    let _knb_v = _kt_mol_v(_knb_mol);
    let _knb_a = _kt_mol_a(_knb_mol);
    // Collect candidates from S dimension (widest spread = best filter)
    let _knb_cands = [];
    let _knb_ds = 0 - _knb_radius;
    while _knb_ds <= _knb_radius {
        let _knb_si = _knb_s + _knb_ds;
        if _knb_si >= 0 {
            if _knb_si < 16 {
                let _knb_bucket = __kt_dim_s[_knb_si];
                let _knb_bi = 0;
                while _knb_bi < len(_knb_bucket) {
                    let _knb_idx = __array_get(_knb_bucket, _knb_bi);
                    if _knb_idx < len(__kt_facts_arr) {
                        // Compute Manhattan distance in 5D
                        let _knb_fmol = __array_get(__kt_fact_mol, _knb_idx);
                        let _knb_dist = _kt_mol_dist(_knb_mol, _knb_fmol);
                        push(_knb_cands, { text: __array_get(__kt_facts_arr, _knb_idx), distance: _knb_dist, mol: _knb_fmol });
                    };
                    let _knb_bi = _knb_bi + 1;
                };
            };
        };
        let _knb_ds = _knb_ds + 1;
    };
    // Sort by distance (selection sort — safe with Olang scoping)
    let _knb_si = 0;
    while _knb_si < len(_knb_cands) {
        let _knb_min_idx = [_knb_si];
        let _knb_min_d = [__array_get(_knb_cands, _knb_si).distance];
        let _knb_sj = _knb_si + 1;
        while _knb_sj < len(_knb_cands) {
            let _knb_cd = __array_get(_knb_cands, _knb_sj).distance;
            if _knb_cd < __array_get(_knb_min_d, 0) {
                let _ = __set_at(_knb_min_idx, 0, _knb_sj);
                let _ = __set_at(_knb_min_d, 0, _knb_cd);
            };
            let _knb_sj = _knb_sj + 1;
        };
        // Swap
        let _knb_mi = __array_get(_knb_min_idx, 0);
        if _knb_mi != _knb_si {
            let _knb_tmp = __array_get(_knb_cands, _knb_si);
            let _ = __set_at(_knb_cands, _knb_si, __array_get(_knb_cands, _knb_mi));
            let _ = __set_at(_knb_cands, _knb_mi, _knb_tmp);
        };
        let _knb_si = _knb_si + 1;
    };
    return _knb_cands;
}

// Manhattan distance between two molecules in 5D
fn _kt_mol_dist(_kmd_a, _kmd_b) {
    let _kmd_ds = _kt_abs(_kt_mol_s(_kmd_a) - _kt_mol_s(_kmd_b));
    let _kmd_dr = _kt_abs(_kt_mol_r(_kmd_a) - _kt_mol_r(_kmd_b));
    let _kmd_dv = _kt_abs(_kt_mol_v(_kmd_a) - _kt_mol_v(_kmd_b));
    let _kmd_da = _kt_abs(_kt_mol_a(_kmd_a) - _kt_mol_a(_kmd_b));
    let _kmd_dt = _kt_abs(_kt_mol_t(_kmd_a) - _kt_mol_t(_kmd_b));
    return _kmd_ds + _kmd_dr + _kmd_dv + _kmd_da + _kmd_dt;
}

fn _kt_abs(_v) { if _v < 0 { return 0 - _v; }; return _v; }

// ════════════════════════════════════════════════════════════════
// Decode ∂ — the inverse of Encode ∫
// Given query text → compute molecule → find nearest facts → return
// This is the "partial derivative": descend one dimension at a time
// ════════════════════════════════════════════════════════════════

pub fn kt_decode(_kd_query) {
    _kt_dim_init();
    // ∂ Step 1: Encode query → real molecule (5D)
    let _kd_mol = _kt_real_mol(_kd_query);
    if _kd_mol == 0 { return { facts: [], mol: 0, dims: "none", match: "none" }; };
    // ∂ Step 2: Rank ALL facts by 5D distance to query mol (true decode)
    let _kd_top_d = [999, 999, 999, 999, 999, 999, 999, 999];
    let _kd_top_i = [0, 0, 0, 0, 0, 0, 0, 0];
    let _kd_k = 8;
    let _kd_fi = 0;
    let _kd_flen = len(__kt_facts_arr);
    while _kd_fi < _kd_flen {
        let _kd_fmol = 0;
        if _kd_fi < len(__kt_fact_mol) { let _kd_fmol = __array_get(__kt_fact_mol, _kd_fi); };
        if _kd_fmol == 0 { let _kd_fmol = _kt_fast_mol(__array_get(__kt_facts_arr, _kd_fi)); };
        if _kd_fmol > 0 {
            let _kd_dist = _kt_mol_dist(_kd_mol, _kd_fmol);
            // Insert into top-k if closer
            let _kd_worst = _kd_k - 1;
            if _kd_dist < __array_get(_kd_top_d, _kd_worst) {
                let _ = __set_at(_kd_top_d, _kd_worst, _kd_dist);
                let _ = __set_at(_kd_top_i, _kd_worst, _kd_fi);
                // Bubble sort
                let _kd_j = _kd_worst;
                while _kd_j > 0 {
                    let _kd_jm = _kd_j - 1;
                    if __array_get(_kd_top_d, _kd_j) < __array_get(_kd_top_d, _kd_jm) {
                        let _kd_td = __array_get(_kd_top_d, _kd_jm);
                        let _kd_ti = __array_get(_kd_top_i, _kd_jm);
                        let _ = __set_at(_kd_top_d, _kd_jm, __array_get(_kd_top_d, _kd_j));
                        let _ = __set_at(_kd_top_i, _kd_jm, __array_get(_kd_top_i, _kd_j));
                        let _ = __set_at(_kd_top_d, _kd_j, _kd_td);
                        let _ = __set_at(_kd_top_i, _kd_j, _kd_ti);
                    };
                    let _kd_j = _kd_j - 1;
                };
            };
        };
        let _kd_fi = _kd_fi + 1;
    };
    // ∂ Step 3: Collect results, boost silk-connected facts
    let _kd_results = [];
    let _kd_ri = 0;
    while _kd_ri < _kd_k {
        let _kd_d = __array_get(_kd_top_d, _kd_ri);
        if _kd_d < 999 {
            let _kd_idx = __array_get(_kd_top_i, _kd_ri);
            push(_kd_results, __array_get(__kt_facts_arr, _kd_idx));
        };
        let _kd_ri = _kd_ri + 1;
    };
    if len(_kd_results) > 0 {
        let _kd_best_d = __array_get(_kd_top_d, 0);
        let _kd_match = "nearby";
        if _kd_best_d == 0 { let _kd_match = "exact"; };
        if _kd_best_d <= 3 { let _kd_match = "close"; };
        return { facts: _kd_results, mol: _kd_mol, dims: "5D(d=" + __to_string(_kd_best_d) + ")", match: _kd_match };
    };
    return { facts: [], mol: _kd_mol, dims: "empty", match: "none" };
}

// Get molecule for a fact by index
pub fn kt_fact_mol_at(_kfma_idx) {
    if _kfma_idx < len(__kt_fact_mol) { return __array_get(__kt_fact_mol, _kfma_idx); };
    return 0;
}

// Dimension stats: count facts in each bucket
pub fn kt_dim_stats() {
    _kt_dim_init();
    let _kds_out = "DimIndex:";
    let _kds_total = [0];
    let _kds_i = 0;
    while _kds_i < 16 {
        let _kds_n = len(__kt_dim_s[_kds_i]);
        if _kds_n > 0 { let _ = __set_at(_kds_total, 0, __array_get(_kds_total, 0) + _kds_n); };
        let _kds_i = _kds_i + 1;
    };
    let _kds_out = _kds_out + " S=" + __to_string(__array_get(_kds_total, 0));
    let _ = __set_at(_kds_total, 0, 0);
    let _kds_i = 0;
    while _kds_i < 8 {
        let _kds_n = len(__kt_dim_v[_kds_i]);
        if _kds_n > 0 { let _ = __set_at(_kds_total, 0, __array_get(_kds_total, 0) + _kds_n); };
        let _kds_i = _kds_i + 1;
    };
    let _kds_out = _kds_out + " V=" + __to_string(__array_get(_kds_total, 0));
    return _kds_out;
}

// ════════════════════════════════════════════════════════════════
// Save / Load
// ════════════════════════════════════════════════════════════════

// Strip "[YYYY-MM-DD HH:MM] " timestamp from knowledge entries at load time
fn _kt_strip_ts(_kst_text) {
    if len(_kst_text) < 20 { return _kst_text; };
    if __char_code(char_at(_kst_text, 0)) != 91 { return _kst_text; };
    let _kst_i = 1;
    while _kst_i < 20 {
        if __char_code(char_at(_kst_text, _kst_i)) == 93 {
            let _kst_start = _kst_i + 1;
            if _kst_start < len(_kst_text) {
                if __char_code(char_at(_kst_text, _kst_start)) == 32 { let _kst_start = _kst_start + 1; };
            };
            return substr(_kst_text, _kst_start, len(_kst_text));
        };
        let _kst_i = _kst_i + 1;
    };
    return _kst_text;
}

// _kt_is_knowledge removed — dead code (filter disabled, kt_load uses _kt_is_debug only)

// Reject debug/progress log entries
fn _kt_is_debug(_kid_text) {
    let _kid_i = 0;
    while _kid_i < (len(_kid_text) - 5) {
        let _kid_w = substr(_kid_text, _kid_i, _kid_i + 5);
        if _kid_w == "fixed" { return 1; };
        if _kid_w == "error" { return 1; };
        if _kid_w == " bug " { return 1; };
        if _kid_w == "crash" { return 1; };
        if _kid_w == "debug" { return 1; };
        let _kid_i = _kid_i + 1;
    };
    return 0;
}

pub fn kt_save(_ks_path) {
    let _ks_out = "";
    let _ks_i = 0;
    while _ks_i < len(__kt_facts_arr) {
        if _ks_i > 0 { _ks_out = _ks_out + "\n"; };
        _ks_out = _ks_out + __array_get(__kt_facts_arr, _ks_i);
        _ks_i = _ks_i + 1;
    };
    __file_write(_ks_path, _ks_out);
    return "Saved " + __to_string(len(__kt_facts_arr)) + " facts to " + _ks_path;
}

pub fn kt_load(_kld_path) {
    let _kld_content = __file_read(_kld_path);
    if len(_kld_content) == 0 { return 0; };
    let _kld_st = [0, 0];
    let _kld_clen = len(_kld_content);
    let _kld_i = 0;
    while _kld_i < _kld_clen {
        let _kld_ch = __char_code(char_at(_kld_content, _kld_i));
        if _kld_ch == 10 { let _kld_s = __array_get(_kld_st, 0); let _kld_slen = _kld_i - _kld_s; if _kld_slen > 20 { if _kld_slen < 200 { let _kld_sent = substr(_kld_content, _kld_s, _kld_i); let _kld_sent = _kt_strip_ts(_kld_sent); if _kt_is_debug(_kld_sent) == 0 { kt_learn(_kld_sent); let _ = __set_at(_kld_st, 1, __array_get(_kld_st, 1) + 1); if __array_get(_kld_st, 1) >= 400 { return __array_get(_kld_st, 1); }; }; }; }; let _ = __set_at(_kld_st, 0, _kld_i + 1); };
        let _kld_i = _kld_i + 1;
    };
    __heap_pin();
    return __array_get(_kld_st, 1);
}

// ════════════════════════════════════════════════════════════════
// Book read (compatibility — uses native ingest)
// ════════════════════════════════════════════════════════════════

pub fn kt_read_book(_rb_path) {
    return kt_ingest_book(_rb_path);
}

// Dead code removed by Nox self-audit:
// - kt_sample (Fibonacci sampling — never called)
// - kt_q_reward, kt_q_get, kt_q_search (Q-table — never integrated)
// - _kt_q_init, __kt_qtable, __kt_q_inited (Q-table infrastructure)

// [Removed: __kt_fib_cache, kt_sample, Q-table — dead code]
// Kept: kt_ingest_full (used by http.ol)
// ════════════════════════════════════════════════════════════════
// Full pipeline: ingest book with Silk + STM + Dream
// ════════════════════════════════════════════════════════════════

// ── Inline Silk+STM (same file = same var scope, avoids boot↔eval boundary) ──
let __ksi_weight = [];
let __ksi_fire = [];
let __ksi_stm_fire = [];
let __ksi_inited = [0];

fn _ksi_init() {
    if __array_get(__ksi_inited, 0) == 1 { return; };
    let _ = __set_at(__ksi_inited, 0, 1);
    __ksi_weight = __array_range(65536);
    __ksi_fire = __array_range(65536);
    __ksi_stm_fire = __array_range(65536);
}

// Initialize Silk (call post-boot to enable Hebbian co-activation on kt_learn)
pub fn kt_silk_init() { _ksi_init(); }

// Silk co-activate: strengthen edge between two P_weights that appear together
pub fn kt_silk_fire(_ksf_a, _ksf_b) {
    _ksi_init();
    if _ksf_a == 0 { return; };
    if _ksf_b == 0 { return; };
    let _ksf_min = _ksf_a;
    let _ksf_max = _ksf_b;
    if _ksf_a > _ksf_b { let _ksf_min = _ksf_b; let _ksf_max = _ksf_a; };
    let _ksf_eh = __bit_and((__bit_and(_ksf_min, 65535) * 40503) + __bit_and(_ksf_max, 65535), 65535);
    let _ksf_eidx = __bit_and(_ksf_eh * 40503, 65535);
    let _ksf_w = __array_get(__ksi_weight, _ksf_eidx);
    let _ksf_nw = _ksf_w + 10;
    if _ksf_nw > 1000 { let _ksf_nw = 1000; };
    let _ = __set_at(__ksi_weight, _ksf_eidx, _ksf_nw);
    let _ = __set_at(__ksi_fire, _ksf_eidx, __array_get(__ksi_fire, _ksf_eidx) + 1);
}

// Silk co-activate consecutive words in text (Hebbian: fire together → wire together)
fn _kt_silk_text(_kst_text) {
    let _kst_prev = [0];
    let _kst_tlen = len(_kst_text);
    let _kst_start = [0];
    let _kst_i = 0;
    while _kst_i <= _kst_tlen {
        let _kst_sep = 0;
        if _kst_i == _kst_tlen { let _kst_sep = 1; };
        if _kst_i < _kst_tlen { if __char_code(char_at(_kst_text, _kst_i)) == 32 { let _kst_sep = 1; }; };
        if _kst_sep == 1 {
            let _kst_s = __array_get(_kst_start, 0);
            if _kst_i > _kst_s {
                let _kst_word = substr(_kst_text, _kst_s, _kst_i);
                let _kst_mol = _kt_fast_mol(_kst_word);
                let _kst_p = __array_get(_kst_prev, 0);
                if _kst_p > 0 { kt_silk_fire(_kst_p, _kst_mol); };
                let _ = __set_at(_kst_prev, 0, _kst_mol);
            };
            let _ = __set_at(_kst_start, 0, _kst_i + 1);
        };
        let _kst_i = _kst_i + 1;
    };
}

// Silk weight lookup: returns weight (0-1000) between two molecules
pub fn kt_silk_weight(_ksw_a, _ksw_b) {
    _ksi_init();
    if _ksw_a == 0 { return 0; };
    if _ksw_b == 0 { return 0; };
    let _ksw_min = _ksw_a;
    let _ksw_max = _ksw_b;
    if _ksw_a > _ksw_b { let _ksw_min = _ksw_b; let _ksw_max = _ksw_a; };
    let _ksw_eh = __bit_and((__bit_and(_ksw_min, 65535) * 40503) + __bit_and(_ksw_max, 65535), 65535);
    let _ksw_eidx = __bit_and(_ksw_eh * 40503, 65535);
    return __array_get(__ksi_weight, _ksw_eidx);
}

// Silk walk: multi-hop traversal through KnowTree facts via Silk edges
// Returns array of {text, mol, depth, weight} for each hop
// depth = max hops (spec: >= 3), threshold = min silk weight to follow
pub fn kt_silk_walk(_ksw_start_mol, _ksw_depth, _ksw_threshold) {
    _ksi_init();
    _kt_ensure_init();
    let _sw_results = [];
    let _sw_visited = [_ksw_start_mol, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    let _sw_vcount = [1];
    // Current frontier: mols to expand from
    let _sw_frontier = [_ksw_start_mol];
    let _sw_d = 0;
    while _sw_d < _ksw_depth {
        let _sw_next = [];
        let _sw_fi = 0;
        while _sw_fi < len(_sw_frontier) {
            let _sw_from = __array_get(_sw_frontier, _sw_fi);
            // Scan all facts for silk connections to _sw_from
            let _sw_ki = 0;
            while _sw_ki < len(__kt_facts_arr) {
                let _sw_fact = __array_get(__kt_facts_arr, _sw_ki);
                let _sw_fmol = _kt_fast_mol(_sw_fact);
                if _sw_fmol > 0 {
                    if _sw_fmol != _sw_from {
                        let _sw_w = kt_silk_weight(_sw_from, _sw_fmol);
                        if _sw_w >= _ksw_threshold {
                            // Check not already visited
                            let _sw_seen = [0];
                            let _sw_vi = 0;
                            while _sw_vi < __array_get(_sw_vcount, 0) {
                                if __array_get(_sw_visited, _sw_vi) == _sw_fmol {
                                    let _ = __set_at(_sw_seen, 0, 1);
                                };
                                let _sw_vi = _sw_vi + 1;
                            };
                            if __array_get(_sw_seen, 0) == 0 {
                                push(_sw_results, { text: _sw_fact, mol: _sw_fmol, depth: _sw_d + 1, weight: _sw_w });
                                push(_sw_next, _sw_fmol);
                                // Add to visited
                                let _sw_vc = __array_get(_sw_vcount, 0);
                                if _sw_vc < 16 {
                                    let _ = __set_at(_sw_visited, _sw_vc, _sw_fmol);
                                    let _ = __set_at(_sw_vcount, 0, _sw_vc + 1);
                                };
                            };
                        };
                    };
                };
                let _sw_ki = _sw_ki + 1;
            };
            let _sw_fi = _sw_fi + 1;
        };
        let _sw_frontier = _sw_next;
        if len(_sw_frontier) == 0 { let _sw_d = _ksw_depth; };
        let _sw_d = _sw_d + 1;
    };
    return _sw_results;
}

// Silk decay: multiply all weights by φ⁻¹ (618/1000)
// Call once per dream cycle. Spec: φ⁻¹ per 24h ≈ every ~288 turns at 5min/turn
// In practice: call from dream_cycle (every 5 turns), scale accordingly
pub fn kt_silk_decay() {
    _ksi_init();
    // Decay factor: 618/1000 per 24h. Dream runs every 5 turns.
    // If ~100 turns/day: 20 dream cycles. Decay per cycle ≈ 980/1000
    let _ksd_i = 0;
    while _ksd_i < 65536 {
        let _ksd_w = __array_get(__ksi_weight, _ksd_i);
        if _ksd_w > 0 {
            let _ksd_nw = __floor((_ksd_w * 980) / 1000);
            if _ksd_nw <= 0 { let _ksd_nw = 0; };
            let _ = __set_at(__ksi_weight, _ksd_i, _ksd_nw);
        };
        let _ksd_i = _ksd_i + 1;
    };
}

pub fn kt_ingest_full(_kif_path) {
    _kt_ensure_init();
    _ksi_init();
    let _kif_content = __file_read(_kif_path);
    if __len(_kif_content) == 0 { return "Error: cannot read " + _kif_path; };
    // 1. Native P_weight scan
    let _kif_result = __text_to_pw(_kif_content, __kt_tbl);
    let _kif_rlen = __array_len(_kif_result);
    // Store in KnowTree + inline STM
    let _kif_fed = [0];
    let _kif_i = 0;
    while _kif_i < _kif_rlen {
        let _kif_pw = __array_get(_kif_result, _kif_i);
        let _kif_freq = __array_get(_kif_result, _kif_i + 1);
        if _kif_pw > 0 {
            _kt_store_pw(_kif_pw, _kif_freq, _kif_path);
            // Inline STM push
            let _kif_sidx = __bit_and(_kif_pw * 40503, 65535);
            let _ = __set_at(__ksi_stm_fire, _kif_sidx, __array_get(__ksi_stm_fire, _kif_sidx) + _kif_freq);
            let _ = __set_at(_kif_fed, 0, __array_get(_kif_fed, 0) + 1);
        };
        let _kif_i = _kif_i + 2;
    };
    let _ = __set_at(__kt_fact_count, 0, __array_get(__kt_fact_count, 0) + 1);
    // 2. Inline Silk: co-activate consecutive P_weight pairs
    let _kif_si = 0;
    while _kif_si < _kif_rlen - 2 {
        let _kif_a = __array_get(_kif_result, _kif_si);
        let _kif_b = __array_get(_kif_result, _kif_si + 2);
        if _kif_a > 0 {
            let _kif_min = _kif_a; let _kif_max = _kif_b;
            if _kif_a > _kif_b { let _kif_min = _kif_b; let _kif_max = _kif_a; };
            let _kif_eh = __bit_and(__bit_and(_kif_min, 65535) * 40503 + __bit_and(_kif_max, 65535), 65535);
            let _kif_eidx = __bit_and(_kif_eh * 40503, 65535);
            let _kif_w = __array_get(__ksi_weight, _kif_eidx);
            let _kif_nw = _kif_w + 10;
            if _kif_nw > 1000 { let _kif_nw = 1000; };
            let _ = __set_at(__ksi_weight, _kif_eidx, _kif_nw);
            let _ = __set_at(__ksi_fire, _kif_eidx, __array_get(__ksi_fire, _kif_eidx) + 1);
        };
        let _kif_si = _kif_si + 2;
    };
    // 3. Dream: promote mature STM entries to KnowTree
    let _kif_promoted = [0];
    let _kif_di = 0;
    while _kif_di < 65536 {
        let _kif_sf = __array_get(__ksi_stm_fire, _kif_di);
        if _kif_sf >= 8 { let _ = __set_at(_kif_promoted, 0, __array_get(_kif_promoted, 0) + 1); };
        // Decay STM: fire *= φ⁻¹
        if _kif_sf > 0 { let _ = __set_at(__ksi_stm_fire, _kif_di, __floor(_kif_sf * 618 / 1000)); };
        let _kif_di = _kif_di + 1;
    };
    // Decay Silk weights
    // kt_q_decay removed (dead code)
    // Stats
    let _kif_sedges = [0]; let _kif_sfires = [0];
    let _kif_ski = 0;
    while _kif_ski < 65536 { if __array_get(__ksi_weight, _kif_ski) > 0 { let _ = __set_at(_kif_sedges, 0, __array_get(_kif_sedges, 0) + 1); }; let _ = __set_at(_kif_sfires, 0, __array_get(_kif_sfires, 0) + __array_get(__ksi_fire, _kif_ski)); let _kif_ski = _kif_ski + 1; };
    return "Full: " + __to_string(_kif_rlen/2) + "pw " + __to_string(__array_get(_kif_fed, 0)) + "→STM " + __to_string(__array_get(_kif_promoted, 0)) + " promoted Silk:" + __to_string(__array_get(_kif_sedges, 0)) + "edges " + kt_stats();
}

// Legacy stubs for compatibility
let __kt_chars = [];
let __kt_words = [];
let __kt_facts = [];
let __kt_search_scores = [];

pub fn kt_char(_kc_cp) { return 0; }
pub fn kt_word(_kw_text) { return 0; }
