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

// Fast molecule: hash text chars → u16 mol (NO heap allocation, NO text_emotion_v2)
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

pub fn kt_learn_to(_klt_text, _klt_branch) {
    _kt_ensure_init();
    let _klt_fidx = __array_get(__kt_fact_count, 0);
    let _ = __set_at(__kt_fact_count, 0, _klt_fidx + 1);
    push(__kt_facts_arr, _klt_text);
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
    // Index into 5D dimension tree — lightweight hash (no __text_to_pw allocation)
    let _klt_mol = _kt_fast_mol(_klt_text);
    _kt_dim_index(_klt_fidx, _klt_mol);
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

pub fn kt_search(_ks_query) {
    _kt_ensure_init();
    // Use __text_to_pw for query → same P_weight key space as ingested data
    let _ks_pw = __text_to_pw(_ks_query, __kt_tbl);
    let _ks_plen = __array_len(_ks_pw);
    let _ks_hits = [0];
    let _ks_total_freq = [0];
    let _ks_i = 0;
    while _ks_i < _ks_plen {
        let _ks_p = __array_get(_ks_pw, _ks_i);
        let _ks_idx = __bit_and(_ks_p * 40503, 65535);
        let _ks_f = __array_get(__kt_pw_freq, _ks_idx);
        if _ks_f > 0 { let _ = __set_at(_ks_hits, 0, __array_get(_ks_hits, 0) + 1); let _ = __set_at(_ks_total_freq, 0, __array_get(_ks_total_freq, 0) + _ks_f); };
        let _ks_i = _ks_i + 2;
    };
    return { text: "hits=" + __to_string(__array_get(_ks_hits, 0)) + " freq=" + __to_string(__array_get(_ks_total_freq, 0)), score: __array_get(_ks_hits, 0) };
}

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
    // Compute query molecule (same pipeline as encode)
    let _kd_mol = _kt_fast_mol(_kd_query);
    if _kd_mol == 0 { return { facts: [], mol: 0, dims: "none" }; };
    let _kd_s = _kt_mol_s(_kd_mol);
    let _kd_r = _kt_mol_r(_kd_mol);
    let _kd_v = _kt_mol_v(_kd_mol);
    let _kd_a = _kt_mol_a(_kd_mol);
    // Step 1: Exact match — S AND V (most discriminating pair)
    let _kd_exact = kt_get_path([0, _kd_s, 2, _kd_v]);
    if len(_kd_exact) > 0 {
        return { facts: _kd_exact, mol: _kd_mol, dims: "S=" + __to_string(_kd_s) + " V=" + __to_string(_kd_v), match: "exact" };
    };
    // Step 2: Relax — try S only
    let _kd_s_only = kt_get_dim(0, _kd_s);
    if len(_kd_s_only) > 0 {
        return { facts: _kd_s_only, mol: _kd_mol, dims: "S=" + __to_string(_kd_s), match: "partial" };
    };
    // Step 3: Nearest neighbor — expand radius
    let _kd_near = kt_nearby(_kd_mol, 2);
    let _kd_texts = [];
    let _kd_ni = 0;
    let _kd_max = 10;
    while _kd_ni < len(_kd_near) {
        if _kd_ni < _kd_max {
            let _kd_entry = __array_get(_kd_near, _kd_ni);
            push(_kd_texts, _kd_entry.text);
        };
        let _kd_ni = _kd_ni + 1;
    };
    if len(_kd_texts) > 0 {
        return { facts: _kd_texts, mol: _kd_mol, dims: "nearby(r=2)", match: "nearby" };
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
