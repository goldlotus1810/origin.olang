// homeos/knowtree.ol — KnowTree (G1+G2+G3+G5)
// REBUILT from SPEC_G_COMPLETE.md. Zero legacy code.

let __kt_inited = [0];

fn _kt_ensure_init() {
    if __array_get(__kt_inited, 0) == 1 { return; };
    let _ = __set_at(__kt_inited, 0, 1);
    // P_weight is COMPUTED by p_weight(), not loaded from table.
}

// A2: Unpack P_weight
fn _kt_mol_s(_m) { return (__floor(_m / 4096)) % 16; }
fn _kt_mol_r(_m) { return (__floor(_m / 256)) % 16; }
fn _kt_mol_v(_m) { return (__floor(_m / 32)) % 8; }
fn _kt_mol_a(_m) { return (__floor(_m / 4)) % 8; }
fn _kt_mol_t(_m) { return _m % 4; }
fn _kt_abs(_v) { if _v < 0 { return 0 - _v; }; return _v; }
fn _kt_pack(_s, _r, _v, _a, _t) { return (_s * 4096) + (_r * 256) + (_v * 32) + (_a * 4) + _t; }

// G2: Distance
fn _kt_mol_dist(_a, _b) {
    return _kt_abs(_kt_mol_s(_a) - _kt_mol_s(_b)) + _kt_abs(_kt_mol_r(_a) - _kt_mol_r(_b)) + _kt_abs(_kt_mol_v(_a) - _kt_mol_v(_b)) + _kt_abs(_kt_mol_a(_a) - _kt_mol_a(_b)) + _kt_abs(_kt_mol_t(_a) - _kt_mol_t(_b));
}

// G2: Dominant dimension
pub fn mol_dominant_dim(_m) {
    let _ds = _kt_abs((_kt_mol_s(_m) * 66) - 500);
    let _dr = _kt_abs((_kt_mol_r(_m) * 66) - 500);
    let _dv = _kt_abs((_kt_mol_v(_m) * 142) - 500);
    let _da = _kt_abs((_kt_mol_a(_m) * 142) - 500);
    let _dt = _kt_abs((_kt_mol_t(_m) * 333) - 500);
    let _mx = _ds; let _di = 0;
    if _dr > _mx { let _mx = _dr; let _di = 1; };
    if _dv > _mx { let _mx = _dv; let _di = 2; };
    if _da > _mx { let _mx = _da; let _di = 3; };
    if _dt > _mx { let _di = 4; };
    return _di;
}

pub fn mol_get_dim(_m, _d) {
    if _d == 0 { return _kt_mol_s(_m); };
    if _d == 1 { return _kt_mol_r(_m); };
    if _d == 2 { return _kt_mol_v(_m); };
    if _d == 3 { return _kt_mol_a(_m); };
    return _kt_mol_t(_m);
}

pub fn mol_dim_range(_d) { if _d <= 1 { return 15; }; if _d <= 3 { return 7; }; return 3; }

// G2: Compose — now uses mol_lca (biological, not average)
pub fn compose(_mols) {
    let _n = len(_mols);
    if _n == 0 { return 0; };
    if _n == 1 { return __array_get(_mols, 0); };
    // Pairwise LCA with Zipf weighting (first element heaviest)
    let _result = __array_get(_mols, 0);
    let _i = 1;
    while _i < _n {
        let _result = mol_lca(_result, __array_get(_mols, _i));
        let _i = _i + 1;
    };
    return _result;
}

// G2: Compose legacy (kept for backward compat, used by chain_summary)
pub fn compose_legacy(_mols) {
    let _n = len(_mols);
    if _n == 0 { return 0; };
    if _n == 1 { return __array_get(_mols, 0); };
    let _sm = [0]; let _rs = [0]; let _rw = [0]; let _vs = [0]; let _am = [0]; let _t = [0,0,0,0];
    let _i = 0;
    while _i < _n {
        let _m = __array_get(_mols, _i);
        let _w = __floor(1000 / (_i + 1));
        if _kt_mol_s(_m) > __array_get(_sm, 0) { let _ = __set_at(_sm, 0, _kt_mol_s(_m)); };
        let _ = __set_at(_rs, 0, __array_get(_rs, 0) + (_kt_mol_r(_m) * _w));
        let _ = __set_at(_rw, 0, __array_get(_rw, 0) + _w);
        let _ = __set_at(_vs, 0, __array_get(_vs, 0) + _kt_mol_v(_m));
        if _kt_mol_a(_m) > __array_get(_am, 0) { let _ = __set_at(_am, 0, _kt_mol_a(_m)); };
        let _ti = _kt_mol_t(_m); let _ = __set_at(_t, _ti, __array_get(_t, _ti) + 1);
        let _i = _i + 1;
    };
    let _S = __array_get(_sm, 0) % 16;
    let _tw = __array_get(_rw, 0); let _R = 0;
    if _tw > 0 { let _R = (__floor(__array_get(_rs, 0) / _tw)) % 16; };
    let _V = __floor(__array_get(_vs, 0) / _n); if _V > 7 { let _V = 7; }; if _V < 0 { let _V = 0; };
    let _A = __array_get(_am, 0) % 8;
    let _T = 0; let _tm = __array_get(_t, 0);
    if __array_get(_t, 1) > _tm { let _T = 1; let _tm = __array_get(_t, 1); };
    if __array_get(_t, 2) > _tm { let _T = 2; let _tm = __array_get(_t, 2); };
    if __array_get(_t, 3) > _tm { let _T = 3; };
    return _kt_pack(_S, _R, _V, _A, _T);
}

// G3: P_weight lookup
// ═══ A3: p_weight — COMPUTE from codepoint properties, not lookup ═══
// 42 formulas: cp → category → S,R,V,A,T
// Category is COMPUTABLE from Unicode ranges. No table needed for basic Latin.
pub fn p_weight(_cp) {
    if _cp < 1 { return 0; };
    // ═══ TÍNH S: Shape/Structure ═══
    // Uppercase = heavier shape (S higher). Digits = structured. Symbols = complex.
    let _S = 0;
    if _cp >= 65 { if _cp <= 90 { let _S = 2; }; };    // A-Z uppercase → S=2
    if _cp >= 97 { if _cp <= 122 { let _S = 1; }; };   // a-z lowercase → S=1
    if _cp >= 48 { if _cp <= 57 { let _S = 3; }; };    // 0-9 digits → S=3
    if _cp >= 8592 { if _cp <= 8703 { let _S = 12; }; }; // Arrows → S=12
    if _cp >= 9632 { if _cp <= 9727 { let _S = 14; }; }; // Geometric shapes → S=14
    if _cp >= 9472 { if _cp <= 9599 { let _S = 10; }; }; // Box drawing → S=10
    if _cp >= 128512 { if _cp <= 128767 { let _S = 8; }; }; // Emoticons → S=8

    // ═══ TÍNH R: Relation/Role ═══
    // Letters = script role. Digits = numeric. Operators = math. Punctuation = structure.
    let _R = 0;
    if _cp >= 65 { if _cp <= 90 { let _R = 4; }; };     // Latin uppercase → R=4
    if _cp >= 97 { if _cp <= 122 { let _R = 4; }; };    // Latin lowercase → R=4
    if _cp >= 48 { if _cp <= 57 { let _R = 8; }; };     // Digits → R=8
    if _cp == 43 { let _R = 12; };  // + → operator
    if _cp == 45 { let _R = 12; };  // - → operator
    if _cp == 42 { let _R = 12; };  // * → operator
    if _cp == 47 { let _R = 12; };  // / → operator
    if _cp == 61 { let _R = 12; };  // = → operator
    if _cp == 60 { let _R = 12; };  // < → comparison
    if _cp == 62 { let _R = 12; };  // > → comparison
    if _cp >= 8704 { if _cp <= 8959 { let _R = 14; }; }; // Math operators → R=14
    if _cp == 46 { let _R = 2; };   // . → punctuation
    if _cp == 44 { let _R = 2; };   // , → punctuation
    if _cp == 63 { let _R = 6; };   // ? → query marker
    if _cp == 33 { let _R = 6; };   // ! → emphasis marker
    if _cp == 58 { let _R = 3; };   // : → definition marker
    if _cp == 59 { let _R = 2; };   // ; → separator

    // ═══ TÍNH V: Valence (from codepoint position — NOT lookup) ═══
    // Emoticon blocks encode V naturally. Latin = neutral.
    let _V = 4;  // neutral default
    if _cp >= 128512 { if _cp <= 128591 { let _V = 6; }; }; // face-positive emoticons
    if _cp >= 128544 { if _cp <= 128559 { let _V = 2; }; }; // face-negative emoticons
    if _cp == 10084 { let _V = 7; }; // ❤ → very positive
    if _cp == 128293 { let _V = 7; }; // 🔥 → high V
    if _cp == 128148 { let _V = 1; }; // 💔 → very negative

    // ═══ TÍNH A: Arousal (from codepoint properties) ═══
    let _A = 4;  // neutral default
    if _cp == 33 { let _A = 6; };    // ! → high arousal
    if _cp == 63 { let _A = 5; };    // ? → moderate arousal
    if _cp == 46 { let _A = 2; };    // . → low arousal
    if _cp >= 128512 { if _cp <= 128767 { let _A = 5; }; }; // emoticons → moderate-high
    if _cp >= 8592 { if _cp <= 8703 { let _A = 3; }; };     // arrows → calm/directional

    // ═══ TÍNH T: Time/Temporal ═══
    let _T = 0;  // static default
    if _cp >= 119040 { if _cp <= 119295 { let _T = 3; }; }; // Musical symbols → T=3
    if _cp >= 119296 { if _cp <= 119375 { let _T = 2; }; }; // Musical notation → T=2
    // Combining marks = modifier → T=1 (modifies parent in time)
    if _cp >= 768 { if _cp <= 879 { let _T = 1; }; };       // Combining diacriticals

    return _kt_pack(_S, _R, _V, _A, _T);
}

// G3: Encode text → chain
pub fn chain_encode(_text) {
    let _ch = []; let _i = 0;
    while _i < len(_text) {
        let _m = p_weight(__char_code(char_at(_text, _i)));
        if _m > 0 { push(_ch, _m); };
        let _i = _i + 1;
    };
    return _ch;
}

pub fn chain_summary(_ch) { return compose(_ch); }

// Real mol from text — word-level compose with NRC-VAD for V/A
// G3: encode(text) = split words → compose word mols → compose sentence mol
pub fn _kt_real_mol(_text) {
    _kt_ensure_init();
    _vad_init();
    let _tlen = len(_text);
    if _tlen == 0 { return 0; };

    // Per-char: S, R, T from char P_weights (structure)
    let _s_max = [0]; let _r_max = [0];
    let _t_vote = [0, 0, 0, 0];
    // Per-char: hash for disambiguation
    let _hash = [5381];

    // Per-word: V, A from NRC-VAD (real emotion) or hash fallback
    let _v_sum = [0]; let _a_sum = [0]; let _vad_count = [0];
    // Word accumulator
    let _word_start = [0];

    let _i = 0;
    while _i < _tlen {
        let _cp = __char_code(char_at(_text, _i));
        let _pw = p_weight(_cp);
        // Hash every char
        let _ = __set_at(_hash, 0, __bit_and((__array_get(_hash, 0) * 33) + _cp, 65535));
        // S, R, T from char P_weights
        if _pw > 0 {
            let _s = (__floor(_pw / 4096)) % 16;
            let _r = (__floor(_pw / 256)) % 16;
            let _t = _pw % 4;
            if _s > __array_get(_s_max, 0) { let _ = __set_at(_s_max, 0, _s); };
            if _r > __array_get(_r_max, 0) { let _ = __set_at(_r_max, 0, _r); };
            let _ = __set_at(_t_vote, _t, __array_get(_t_vote, _t) + 1);
        };
        // Word boundary: space or end of text
        let _is_boundary = 0;
        if _cp == 32 { let _is_boundary = 1; };
        if _cp == 10 { let _is_boundary = 1; };
        if _i == (_tlen - 1) { let _is_boundary = 1; };
        if _is_boundary == 1 {
            let _ws = __array_get(_word_start, 0);
            let _we = _i;
            if _i == (_tlen - 1) { let _we = _tlen; };
            if _we > _ws {
                let _word = substr(_text, _ws, _we);
                // NRC-VAD lookup for this word
                let _va = vad_query(_word);
                if __array_get(_va, 0) > 0 {
                    // Has NRC-VAD data: V/A are real emotion values
                    let _ = __set_at(_v_sum, 0, __array_get(_v_sum, 0) + __array_get(_va, 0));
                    let _ = __set_at(_a_sum, 0, __array_get(_a_sum, 0) + __array_get(_va, 1));
                    let _ = __set_at(_vad_count, 0, __array_get(_vad_count, 0) + 1);
                };
            };
            let _ = __set_at(_word_start, 0, _i + 1);
        };
        let _i = _i + 1;
    };

    // S, R from char compose
    let _S = __array_get(_s_max, 0);
    let _R = __array_get(_r_max, 0);
    // V, A: NRC-VAD average if available, hash fallback if not
    let _h = __array_get(_hash, 0);
    let _vc = __array_get(_vad_count, 0);
    let _V = 4; let _A = 4;  // neutral default
    if _vc > 0 {
        // NRC-VAD: raw values 0-1000 (0=min, 500=neutral, 1000=max) → V 0-7, A 0-7
        let _v_avg = __array_get(_v_sum, 0) / _vc;
        let _a_avg = __array_get(_a_sum, 0) / _vc;
        let _V = __floor(_v_avg / 143);  // 1000/7 ≈ 143
        if _V > 7 { let _V = 7; };
        let _A = __floor(_a_avg / 143);
        if _A > 7 { let _A = 7; };
    } else {
        // No NRC-VAD: use hash for differentiation
        let _V = (__floor(_h / 32)) % 8;
        let _A = (__floor(_h / 4)) % 8;
    };
    // R: use hash bits for differentiation when R=0 (plain text)
    if _R == 0 { let _R = (__floor(_h / 256)) % 16; };
    // T from vote
    let _T = 0; let _tm = __array_get(_t_vote, 0);
    if __array_get(_t_vote, 1) > _tm { let _T = 1; let _tm = __array_get(_t_vote, 1); };
    if __array_get(_t_vote, 2) > _tm { let _T = 2; let _tm = __array_get(_t_vote, 2); };
    if __array_get(_t_vote, 3) > _tm { let _T = 3; };

    return _kt_pack(_S, _R, _V, _A, _T);
}

// ═══ NRC-VAD: word → emotion lookup ═══
let __nrc_vad = [];
let __nrc_vad_ok = [0];

fn _vad_init() {
    if __array_get(__nrc_vad_ok, 0) == 1 { return; };
    let _ = __set_at(__nrc_vad_ok, 0, 1);
    // 256 hash buckets, each = [word, v*1000, a*1000, word, v, a, ...]
    let _i = 0; while _i < 256 { push(__nrc_vad, []); let _i = _i + 1; };
}

fn _vad_hash(_w) {
    let _h = [0]; let _i = 0;
    while _i < len(_w) {
        let _ = __set_at(_h, 0, __bit_and((__array_get(_h, 0) * 31) + __char_code(char_at(_w, _i)), 255));
        let _i = _i + 1;
    };
    return __array_get(_h, 0);
}

// Find tab (code 9) position in string, scanning char by char
fn _find_tab(_s, _from) {
    let _i = _from;
    while _i < len(_s) {
        if __char_code(char_at(_s, _i)) == 9 { return _i; };
        let _i = _i + 1;
    };
    return 0 - 1;
}

// Load NRC-VAD from tab-separated file: word\tV\tA[\tD]
pub fn vad_load(_path) {
    _vad_init();
    let _c = __file_read(_path);
    if len(_c) == 0 { return 0; };
    let _count = [0];
    let _ls = [0];  // line start
    let _i = 0;
    while _i < len(_c) {
        if __char_code(char_at(_c, _i)) == 10 {
            let _le = _i;  // line end
            let _lstart = __array_get(_ls, 0);
            if _le > _lstart {
                // Find tabs by scanning chars (avoid __str_index_of bug)
                let _t1 = _find_tab(_c, _lstart);
                if _t1 > _lstart {
                    let _t2 = _find_tab(_c, _t1 + 1);
                    if _t2 > _t1 {
                        let _word = substr(_c, _lstart, _t1);
                        let _vs = substr(_c, _t1 + 1, _t2);
                        // A: either next field or to end of line
                        let _t3 = _find_tab(_c, _t2 + 1);
                        let _ae = _le;
                        if _t3 > _t2 { let _ae = _t3; };
                        let _as = substr(_c, _t2 + 1, _ae);
                        let _v = __to_number(_vs);
                        let _a = __to_number(_as);
                        let _h = _vad_hash(_word);
                        push(__nrc_vad[_h], _word);
                        push(__nrc_vad[_h], __floor(_v));
                        push(__nrc_vad[_h], __floor(_a));
                        let _ = __set_at(_count, 0, __array_get(_count, 0) + 1);
                    };
                };
            };
            let _ = __set_at(_ls, 0, _i + 1);
        };
        let _i = _i + 1;
    };
    __heap_pin();
    return __array_get(_count, 0);
}

// Query: word → [v_raw*1000, a_raw*1000] or [0, 0]
pub fn vad_query(_word) {
    _vad_init();
    let _h = _vad_hash(_word);
    let _bkt = __nrc_vad[_h];
    let _i = 0;
    while _i < len(_bkt) {
        if __array_get(_bkt, _i) == _word {
            return [__array_get(_bkt, _i + 1), __array_get(_bkt, _i + 2)];
        };
        let _i = _i + 3;
    };
    return [0, 0];
}

// ═══ G7: STM with eviction scoring (capacity 32) ═══
let __kt_stm_text = __array_with_cap(64);
let __kt_stm_mol = __array_with_cap(64);
let __kt_stm_access = __array_with_cap(64);  // access count per entry
let __kt_stm_turn = [0];  // current turn number

pub fn kt_stm_push(_text) {
    let _mol = _kt_real_mol(_text);
    let _ = __set_at(__kt_stm_turn, 0, __array_get(__kt_stm_turn, 0) + 1);
    // G7: Evict if full (capacity=32). Remove entry with LOWEST score.
    if len(__kt_stm_text) >= 32 {
        let _min_score = [999999]; let _min_idx = [0];
        let _turn = __array_get(__kt_stm_turn, 0);
        let _i = 0;
        while _i < len(__kt_stm_text) {
            let _m = __array_get(__kt_stm_mol, _i);
            let _v = mol_get_dim(_m, 2);  // V dimension
            let _a = mol_get_dim(_m, 3);  // A dimension
            let _ac = __array_get(__kt_stm_access, _i);
            let _age = _turn - _i;  // older = higher age
            // Score = access×300 + |V-4|×A×400/28 + recency×300
            let _emo = (_kt_abs(_v - 4) * _a * 400) / 28;
            let _rec = 0;
            if _age < 32 { let _rec = (32 - _age) * 10; };
            let _score = (_ac * 300) + _emo + _rec;
            if _score < __array_get(_min_score, 0) {
                let _ = __set_at(_min_score, 0, _score);
                let _ = __set_at(_min_idx, 0, _i);
            };
            let _i = _i + 1;
        };
        // Overwrite lowest-score entry instead of removing (arrays can't shrink)
        let _evict = __array_get(_min_idx, 0);
        let _ = __set_at(__kt_stm_text, _evict, _text);
        let _ = __set_at(__kt_stm_mol, _evict, _mol);
        let _ = __set_at(__kt_stm_access, _evict, 1);
    } else {
        push(__kt_stm_text, _text);
        push(__kt_stm_mol, _mol);
        push(__kt_stm_access, 1);
    };
    // Auto-silk with previous
    let _n = len(__kt_stm_mol);
    if _n >= 2 { kt_silk_fire(_mol, __array_get(__kt_stm_mol, _n - 2)); };
}

// Boost access count when STM entry is retrieved
pub fn kt_stm_access(_i) {
    if _i >= 0 { if _i < len(__kt_stm_access) {
        let _ = __set_at(__kt_stm_access, _i, __array_get(__kt_stm_access, _i) + 1);
    }; };
}

pub fn kt_stm_count() { return len(__kt_stm_text); }
pub fn kt_stm_mol_at(_i) { return __array_get(__kt_stm_mol, _i); }
pub fn kt_stm_text_at(_i) { return __array_get(__kt_stm_text, _i); }

// ═══ String split: global buffer in knowtree scope (works across boot↔eval) ═══
let __kt_words = __array_with_cap(64);

pub fn kt_split_words(_text) {
    // Clear: set len to 0 by recreating (push appends, can't shrink)
    // Workaround: use count tracker
    let _ws = [0];
    let _wc = [0];
    let _i = 0;
    while _i <= len(_text) {
        let _is_sp = 0;
        if _i == len(_text) { let _is_sp = 1; } else {
            let _ch = __char_code(char_at(_text, _i));
            if _ch == 32 { let _is_sp = 1; };
            if _ch == 63 { let _is_sp = 1; };
        };
        if _is_sp == 1 {
            let _s = __array_get(_ws, 0);
            if _i > _s {
                push(__kt_words, substr(_text, _s, _i));
                let _ = __set_at(_wc, 0, __array_get(_wc, 0) + 1);
            };
            let _ = __set_at(_ws, 0, _i + 1);
        };
        let _i = _i + 1;
    };
    return __array_get(_wc, 0);
}

pub fn kt_word_at(_idx) {
    if _idx < len(__kt_words) { return __array_get(__kt_words, _idx); };
    return "";
}

// ═══ L0 Registry ═══
// Empty. Knowledge comes from experience (nox_memory.dat) and interaction.
// Not from hardcoded strings in source code.
pub fn kt_register_l0() {
    _kt_ensure_init(); _bkt_init(); _silk_init();
}

// ═══ Load UDC aliases JSON into KnowTree ═══
// Each alias = "U+XXXX name [vi: translation] [keywords]"
pub fn kt_load_aliases(_path) {
    _kt_ensure_init(); _bkt_init();
    let _c = __file_read(_path);
    if len(_c) < 10 { return 0; };
    // Simple JSON parse: find "XXXX":{"n":"NAME",...} patterns
    let _count = [0];
    let _i = 0;
    let _clen = len(_c);
    while _i < _clen {
        // Find "XXXX":
        if char_at(_c, _i) == "\"" {
            let _key_start = _i + 1;
            let _i = _i + 1;
            while _i < _clen {
                if char_at(_c, _i) == "\"" { break; };
                let _i = _i + 1;
            };
            let _key = substr(_c, _key_start, _i);
            let _i = _i + 1;
            // Skip to value
            if _i < _clen {
                if char_at(_c, _i) == ":" {
                    let _i = _i + 1;
                    // Find "n":"..." (name)
                    let _chunk_end = _i + 500;
                    if _chunk_end > _clen { let _chunk_end = _clen; };
                    let _n_pos = __str_index_of(substr(_c, _i, _chunk_end), "\"n\":\"");
                    if _n_pos >= 0 {
                        let _name_start = _i + _n_pos + 5;
                        let _name_end = _name_start;
                        while _name_end < _clen {
                            if char_at(_c, _name_end) == "\"" { break; };
                            let _name_end = _name_end + 1;
                        };
                        let _name = substr(_c, _name_start, _name_end);
                        // Find Vietnamese "v":"..."
                        let _ch_end = _i + 500;
                        if _ch_end > _clen { let _ch_end = _clen; };
                        let _chunk = substr(_c, _i, _ch_end);
                        let _v_pos = __str_index_of(_chunk, "\"v\":\"");
                        let _vi = "";
                        if _v_pos >= 0 {
                            let _vi_start = _i + _v_pos + 5;
                            let _vi_end = _vi_start;
                            while _vi_end < _clen {
                                if char_at(_c, _vi_end) == "\"" { break; };
                                let _vi_end = _vi_end + 1;
                            };
                            let _vi = substr(_c, _vi_start, _vi_end);
                        };
                        // Learn: "ARROW: LEFTWARDS ARROW (mũi tên hướng trái)"
                        let _fact = "U+" + _key + " " + _name;
                        if len(_vi) > 0 { let _fact = _fact + " (" + _vi + ")"; };
                        kt_learn(_fact);
                        let _ = __set_at(_count, 0, __array_get(_count, 0) + 1);
                        // Pin every 1000 to avoid heap overflow
                        if (__array_get(_count, 0) % 1000) == 0 { __heap_pin(); };
                    };
                    // Skip to next entry (find next "})
                    while _i < _clen {
                        if char_at(_c, _i) == "}" { break; };
                        let _i = _i + 1;
                    };
                };
            };
        };
        let _i = _i + 1;
    };
    __heap_pin();
    return __array_get(_count, 0);
}

// ═══ G1+G5: KnowTree bucket structure ═══
// Pre-allocate with 8192 capacity to prevent relocation crash
let __kt_facts = __array_with_cap(8192);
let __kt_facts_mol = __array_with_cap(8192);
let __kt_facts_fire = __array_with_cap(8192);    // fire count per fact
let __kt_facts_maturity = __array_with_cap(8192); // 0=Formula, 1=Evaluating, 2=Mature
let __kt_buckets = [];
let __kt_bkt_ok = [0];

fn _bkt_init() {
    if __array_get(__kt_bkt_ok, 0) == 1 { return; };
    let _ = __set_at(__kt_bkt_ok, 0, 1);
    let _i = 0; while _i < 256 { push(__kt_buckets, []); let _i = _i + 1; };
}

let __kt_learn_count = [0];

// Fast learn: skip word-level compose, use simple hash (10x faster)
pub fn kt_learn_fast(_text) {
    _kt_ensure_init(); _bkt_init(); _silk_init();
    // Fast mol: hash only (no per-char P_weight lookup)
    let _h = [2166136261];
    let _i = 0;
    while _i < len(_text) {
        let _ = __set_at(_h, 0, __bit_xor(__array_get(_h, 0), __char_code(char_at(_text, _i))));
        let _ = __set_at(_h, 0, __bit_and(__array_get(_h, 0) * 16777619, 65535));
        let _i = _i + 1;
    };
    let _mol = __array_get(_h, 0);
    let _idx = len(__kt_facts);
    push(__kt_facts, _text);
    push(__kt_facts_mol, _mol);
    push(__kt_facts_fire, 0); push(__kt_facts_maturity, 0);
    push(__kt_buckets[(_kt_mol_s(_mol) * 16) + _kt_mol_r(_mol)], _idx);
    __mx_w(_mol, _idx + 1);
    if _idx > 0 { kt_silk_fire(_mol, __array_get(__kt_facts_mol, _idx - 1)); };
    let _ = __set_at(__kt_learn_count, 0, __array_get(__kt_learn_count, 0) + 1);
    if (__array_get(__kt_learn_count, 0) % 20) == 0 { __heap_pin(); };
    return _idx;
}

// Raw learn: pre-computed mol, NO encoding, NO word index, NO silk = 0 temp strings
pub fn kt_learn_raw(_text, _mol) {
    _kt_ensure_init(); _bkt_init();
    let _idx = len(__kt_facts);
    push(__kt_facts, _text);
    push(__kt_facts_mol, _mol);
    push(__kt_facts_fire, 0); push(__kt_facts_maturity, 0);
    push(__kt_buckets[(_kt_mol_s(_mol) * 16) + _kt_mol_r(_mol)], _idx);
    __mx_w(_mol, _idx + 1);
    return _idx;
}

pub fn kt_learn(_text) {
    _kt_ensure_init(); _bkt_init(); _silk_init();
    let _mol = _kt_real_mol(_text);
    let _idx = len(__kt_facts);
    // Pin BEFORE pushes to prevent temp data from mol computation being permanently pinned
    __heap_pin();
    push(__kt_facts, _text);
    push(__kt_facts_mol, _mol);
    push(__kt_facts_fire, 0); push(__kt_facts_maturity, 0);
    push(__kt_buckets[(_kt_mol_s(_mol) * 16) + _kt_mol_r(_mol)], _idx);
    __mx_w(_mol, _idx + 1);
    // Auto-silk with previous
    if _idx > 0 { kt_silk_fire(_mol, __array_get(__kt_facts_mol, _idx - 1)); };
    // G20: Index words for O(1) lookup
    _widx_init();
    let _wi = 0; let _ws = [0];
    while _wi <= len(_text) {
        let _is_space = 0;
        if _wi == len(_text) { let _is_space = 1; } else {
            let _ch = __char_code(char_at(_text, _wi));
            if _ch == 32 { let _is_space = 1; };
            if _ch == 10 { let _is_space = 1; };
        };
        if _is_space == 1 {
            let _word = substr(_text, __array_get(_ws, 0), _wi);
            _widx_add(_word, _idx);
            let _ = __set_at(_ws, 0, _wi + 1);
        };
        let _wi = _wi + 1;
    };
    __heap_pin();
    return _idx;
}

// Maturity: fire a fact index, advance lifecycle
pub fn kt_fire(_idx) {
    if _idx < 0 { return; };
    if _idx >= len(__kt_facts_fire) { return; };
    let _fc = __array_get(__kt_facts_fire, _idx) + 1;
    let _ = __set_at(__kt_facts_fire, _idx, _fc);
    // Advance: Formula(0)→Evaluating(1) when fire>0
    let _mat = __array_get(__kt_facts_maturity, _idx);
    if _mat == 0 { let _ = __set_at(__kt_facts_maturity, _idx, 1); };
    // Advance: Evaluating(1)→Mature(2) when fire>=8 (Fib threshold)
    if _mat == 1 { if _fc >= 8 { let _ = __set_at(__kt_facts_maturity, _idx, 2); }; };
}
pub fn kt_maturity(_idx) { if _idx >= 0 { if _idx < len(__kt_facts_maturity) { return __array_get(__kt_facts_maturity, _idx); }; }; return 0; }
pub fn kt_fire_count(_idx) { if _idx >= 0 { if _idx < len(__kt_facts_fire) { return __array_get(__kt_facts_fire, _idx); }; }; return 0; }

pub fn kt_nearest(_mol) {
    _bkt_init();
    // Matrix fast path: O(1) exact match
    let _mx = __mxr(_mol);
    if _mx > 0 {
        let _fi = _mx - 1;
        if _fi < len(__kt_facts) { return __array_get(__kt_facts, _fi); };
    };
    // Bucket fallback: scan S±1, R±1 neighborhood
    let _s = _kt_mol_s(_mol); let _r = _kt_mol_r(_mol);
    let _bi = [0 - 1]; let _bd = [99999];
    let _ds = 0 - 1;
    while _ds <= 1 {
        let _dr = 0 - 1;
        while _dr <= 1 {
            let _si = _s + _ds; let _ri = _r + _dr;
            if _si >= 0 { if _si < 16 { if _ri >= 0 { if _ri < 16 {
                let _bk = __kt_buckets[(_si * 16) + _ri];
                let _j = 0;
                while _j < len(_bk) {
                    let _fi = __array_get(_bk, _j);
                    let _d = _kt_mol_dist(_mol, __array_get(__kt_facts_mol, _fi));
                    if _d < __array_get(_bd, 0) { let _ = __set_at(_bd, 0, _d); let _ = __set_at(_bi, 0, _fi); };
                    let _j = _j + 1;
                };
            };};};}; let _dr = _dr + 1;
        }; let _ds = _ds + 1;
    };
    let _idx = __array_get(_bi, 0);
    if _idx < 0 { return ""; };
    return __array_get(__kt_facts, _idx);
}

// G20: Word index — O(1) word → fact indices
let __kt_widx = [];
let __kt_widx_ok = [0];

fn _widx_init() {
    if __array_get(__kt_widx_ok, 0) == 1 { return; };
    let _ = __set_at(__kt_widx_ok, 0, 1);
    let _i = 0; while _i < 256 { push(__kt_widx, []); let _i = _i + 1; };
}

fn _widx_hash(_w) {
    let _h = [0]; let _i = 0;
    while _i < len(_w) {
        let _ = __set_at(_h, 0, __bit_and((__array_get(_h, 0) * 31) + __char_code(char_at(_w, _i)), 255));
        let _i = _i + 1;
    };
    return __array_get(_h, 0);
}

fn _widx_add(_word, _fidx) {
    _widx_init();
    if len(_word) < 3 { return; };
    push(__kt_widx[_widx_hash(_word)], _fidx);
}

pub fn kt_word_lookup(_w) {
    _widx_init();
    if len(_w) < 3 { return []; };
    return __kt_widx[_widx_hash(_w)];
}

// String contains: check if haystack contains needle (pure Olang, no builtins)
pub fn _str_has(_hay, _needle) {
    let _hlen = len(_hay);
    let _nlen = len(_needle);
    if _nlen == 0 { return 1; };
    if _nlen > _hlen { return 0; };
    let _i = 0;
    while _i <= _hlen - _nlen {
        let _match = [1];
        let _j = 0;
        while _j < _nlen {
            if char_at(_hay, _i + _j) != char_at(_needle, _j) {
                let _ = __set_at(_match, 0, 0);
                let _j = _nlen;
            };
            let _j = _j + 1;
        };
        if __array_get(_match, 0) == 1 { return 1; };
        let _i = _i + 1;
    };
    return 0;
}

pub fn kt_find(_q, _max) {
    // Word index → candidates → VERIFY with _str_has
    _widx_init();
    let _indices = kt_word_lookup(_q);
    let _out = [];
    if len(_indices) > 0 {
        let _i = 0;
        while _i < len(_indices) {
            if len(_out) >= _max { return _out; };
            let _fi = __array_get(_indices, _i);
            if _fi < len(__kt_facts) {
                let _fact = __array_get(__kt_facts, _fi);
                // VERIFY: fact must actually contain query
                if _str_has(_fact, _q) { push(_out, _fact); };
            };
            let _i = _i + 1;
        };
        if len(_out) > 0 { return _out; };
    };
    // Fallback: linear scan (slow but accurate)
    let _i = 0;
    while _i < len(__kt_facts) {
        if len(_out) >= _max { return _out; };
        if _str_has(__array_get(__kt_facts, _i), _q) { push(_out, __array_get(__kt_facts, _i)); };
        let _i = _i + 1;
    };
    return _out;
}

pub fn kt_fact_count() { return len(__kt_facts); }
pub fn kt_stats() { return "KT: " + __to_string(len(__kt_facts)) + " facts"; }

// ═══ DIAGNOSTICS — see what's inside KnowTree ═══

// Full map: how many nodes per (S,R) bucket
pub fn kt_map() {
    _bkt_init();
    let _out = "KnowTree Map (S×R buckets with nodes):\n";
    let _nonempty = [0];
    let _s = 0;
    while _s < 16 {
        let _r = 0;
        while _r < 16 {
            let _n = len(__kt_buckets[(_s * 16) + _r]);
            if _n > 0 {
                let _out = _out + "  S=" + __to_string(_s) + " R=" + __to_string(_r) + ": " + __to_string(_n) + " nodes\n";
                let _ = __set_at(_nonempty, 0, __array_get(_nonempty, 0) + 1);
            };
            let _r = _r + 1;
        };
        let _s = _s + 1;
    };
    let _out = _out + "Active buckets: " + __to_string(__array_get(_nonempty, 0)) + "/256\n";
    let _out = _out + "Total nodes: " + __to_string(len(__kt_facts));
    return _out;
}

// Silk stats: how many edges, average weight
pub fn kt_silk_stats() {
    _silk_init();
    let _total_edges = [0];
    let _total_weight = [0];
    let _active_buckets = [0];
    let _hi = 0;
    while _hi < 256 {
        let _edges = __kt_silk[_hi];
        let _n = __floor(len(_edges) / 6);
        if _n > 0 {
            let _ = __set_at(_active_buckets, 0, __array_get(_active_buckets, 0) + 1);
            let _ = __set_at(_total_edges, 0, __array_get(_total_edges, 0) + _n);
            let _ei = 0;
            while _ei < len(_edges) {
                let _max_w = 0;
                let _j = 1;
                while _j <= 5 {
                    let _w = __array_get(_edges, _ei + _j);
                    if _w > _max_w { let _max_w = _w; };
                    let _j = _j + 1;
                };
                let _ = __set_at(_total_weight, 0, __array_get(_total_weight, 0) + _max_w);
                let _ei = _ei + 6;
            };
        };
        let _hi = _hi + 1;
    };
    let _te = __array_get(_total_edges, 0);
    let _avg = 0;
    if _te > 0 { let _avg = __floor(__array_get(_total_weight, 0) / _te); };
    return "Silk: " + __to_string(_te) + " edges, "
         + __to_string(__array_get(_active_buckets, 0)) + " active buckets, "
         + "avg_w=" + __to_string(_avg);
}

// Show sample facts from each bucket
pub fn kt_sample(_max_per_bucket) {
    _bkt_init();
    let _out = "";
    let _s = 0;
    while _s < 16 {
        let _r = 0;
        while _r < 16 {
            let _bkt = __kt_buckets[(_s * 16) + _r];
            if len(_bkt) > 0 {
                let _out = _out + "[S=" + __to_string(_s) + " R=" + __to_string(_r) + "] ";
                let _j = 0;
                while _j < len(_bkt) {
                    if _j >= _max_per_bucket { break; };
                    let _fi = __array_get(_bkt, _j);
                    let _text = __array_get(__kt_facts, _fi);
                    if len(_text) > 60 { let _text = substr(_text, 0, 60) + "..."; };
                    let _out = _out + _text;
                    if _j < len(_bkt) - 1 { if _j < _max_per_bucket - 1 { let _out = _out + " | "; }; };
                    let _j = _j + 1;
                };
                let _out = _out + "\n";
            };
            let _r = _r + 1;
        };
        let _s = _s + 1;
    };
    return _out;
}

// Full diagnostic
pub fn kt_diagnostic() {
    let _out = "═══ KnowTree Diagnostic ═══\n";
    let _out = _out + "Nodes: " + __to_string(len(__kt_facts)) + "\n";
    let _out = _out + kt_silk_stats() + "\n";
    let _out = _out + kt_map();
    return _out;
}
pub fn kt_search(q) { return kt_nearest(_kt_real_mol(q)); }
pub fn kt_search_n(q, n) { return kt_find(q, n); }
// Classify = the mol itself. SRVAT IS the classification.
// No labels. No limits. Position in 5D = identity.
// Similar content → similar mol → same neighborhood → group emerges.
pub fn kt_classify(_t) { return _kt_real_mol(_t); }
pub fn kt_decode(_q) { return kt_nearest(_kt_real_mol(_q)); }
pub fn kt_learn_tagged(_t, _x) { return kt_learn(_x); }
pub fn kt_learn_to(_x, _b) { return kt_learn(_x); }
// G19: Persistence — save KnowTree to disk, load at boot
pub fn kt_save(_path) {
    let _out = "";
    let _i = 0;
    while _i < len(__kt_facts) {
        let _fact = __array_get(__kt_facts, _i);
        if len(_fact) > 0 {
            let _mol = __array_get(__kt_facts_mol, _i);
            let _out = _out + __to_string(_mol) + "\t" + _fact + "\n";
        };
        let _i = _i + 1;
    };
    __file_write(_path, _out);
    return "Saved " + __to_string(len(__kt_facts)) + " to " + _path;
}

pub fn kt_load(_path) {
    _kt_ensure_init(); _bkt_init(); _silk_init();
    let _c = __file_read(_path);
    if len(_c) == 0 { return 0; };
    let _count = [0];
    let _start = [0];
    let _i = 0;
    while _i < len(_c) {
        if __char_code(char_at(_c, _i)) == 10 {
            let _line = substr(_c, __array_get(_start, 0), _i);
            // Format: mol\tfact
            let _tab = [0 - 1];
            let _j = 0;
            while _j < len(_line) {
                if __char_code(char_at(_line, _j)) == 9 {
                    let _ = __set_at(_tab, 0, _j);
                    let _j = len(_line);
                };
                let _j = _j + 1;
            };
            let _tp = __array_get(_tab, 0);
            if _tp > 0 {
                let _mol_str = substr(_line, 0, _tp);
                let _fact = substr(_line, _tp + 1, len(_line));
                let _mol = __to_number(_mol_str);
                if len(_fact) > 0 {
                    if len(__kt_facts) < 7500 {
                        __heap_pin();
                        let _idx = len(__kt_facts);
                        push(__kt_facts, _fact);
                        push(__kt_facts_mol, _mol);
    push(__kt_facts_fire, 0); push(__kt_facts_maturity, 0);
                        push(__kt_buckets[(_kt_mol_s(_mol) * 16) + _kt_mol_r(_mol)], _idx);
                        let _ = __set_at(_count, 0, __array_get(_count, 0) + 1);
                    };
                };
            };
            let _ = __set_at(_start, 0, _i + 1);
        };
        let _i = _i + 1;
    };
    __heap_pin();
    return __array_get(_count, 0);
}
pub fn kt_dim_stats() { return ""; }

// Load plain text file (one fact per line) using kt_learn (fresh mol with NRC-VAD)
pub fn kt_load_text(_path) {
    _kt_ensure_init(); _bkt_init(); _silk_init();
    let _c = __file_read(_path);
    if len(_c) == 0 { return 0; };
    let _count = [0];
    let _ls = [0];
    let _i = 0;
    while _i < len(_c) {
        if __char_code(char_at(_c, _i)) == 10 {
            let _lstart = __array_get(_ls, 0);
            if _i > _lstart {
                if len(__kt_facts) < 7500 {
                    let _fact = substr(_c, _lstart, _i);
                    if len(_fact) > 2 {
                        kt_learn(_fact);
                        let _ = __set_at(_count, 0, __array_get(_count, 0) + 1);
                    };
                };
            };
            let _ = __set_at(_ls, 0, _i + 1);
        };
        let _i = _i + 1;
    };
    __heap_pin();
    return __array_get(_count, 0);
}
// ═══ G6: Silk — Hebbian per-dimension edges ═══
// Edge = [target_mol, wS, wR, wV, wA, wT] = 6 values
// Adjacency list: __kt_silk[hash(mol)] = [edge, edge, ...]
let __kt_silk = [];
let __kt_silk_ok = [0];

fn _silk_init() {
    if __array_get(__kt_silk_ok, 0) == 1 { return; };
    let _ = __set_at(__kt_silk_ok, 0, 1);
    let _i = 0; while _i < 256 { push(__kt_silk, []); let _i = _i + 1; };
}

fn _silk_hash(_mol) { return __bit_and(_mol, 255); }

pub fn kt_silk_init() { _silk_init(); }

// G6: Hebbian fire — strengthen edge between two mols
pub fn kt_silk_fire(_a, _b) {
    _silk_init();
    let _va = _kt_mol_v(_a); let _aa = _kt_mol_a(_a);
    let _emo = ((_kt_abs(_va - 4) * _aa) + 1) / 28;
    if _emo > 1000 { let _emo = 1000; };
    // Find or create edge
    let _h = _silk_hash(_a);
    let _edges = __kt_silk[_h];
    let _found = [0 - 1];
    let _ei = 0;
    while _ei < len(_edges) {
        if __array_get(_edges, _ei) == _b { let _ = __set_at(_found, 0, _ei); };
        let _ei = _ei + 6;
    };
    let _fi = __array_get(_found, 0);
    if _fi < 0 {
        // New edge: per-dimension initial weight from proximity
        push(_edges, _b);
        let _d = 0;
        while _d < 5 {
            let _da = mol_get_dim(_a, _d); let _db = mol_get_dim(_b, _d);
            let _prox = 1000 - (_kt_abs(_da - _db) * 1000 / mol_dim_range(_d));
            let _w = __floor(_prox * _emo / 1000);
            push(_edges, _w);
            let _d = _d + 1;
        };
    } else {
        // Update existing: PER-DIMENSION rules (Spec G6 + Bible §14)
        // S,A dims: Oja-like bounded: dw = emo * prox * (1 - w/1000)
        // R,T dims: STDP (temporal order matters, but simplified here)
        // V dim: BCM-like (stronger emotion = higher threshold)
        let _d = 0;
        while _d < 5 {
            let _da = mol_get_dim(_a, _d); let _db = mol_get_dim(_b, _d);
            let _prox = 1000 - (_kt_abs(_da - _db) * 1000 / mol_dim_range(_d));
            let _w = __array_get(_edges, _fi + 1 + _d);
            let _dw = __floor(_emo * _prox * (1000 - _w) / 10000000);
            // V dim: double update for strong emotion (BCM effect)
            if _d == 2 { let _dw = _dw + __floor(_dw * _kt_abs(_va - 4) / 4); };
            let _ = __set_at(_edges, _fi + 1 + _d, _w + _dw);
            let _d = _d + 1;
        };
    };
}

// G6: Get max silk weight between two mols
pub fn kt_silk_weight(_a, _b) {
    _silk_init();
    let _edges = __kt_silk[_silk_hash(_a)];
    let _ei = 0;
    while _ei < len(_edges) {
        if __array_get(_edges, _ei) == _b {
            let _max = 0; let _j = 1;
            while _j <= 5 {
                let _w = __array_get(_edges, _ei + _j);
                if _w > _max { let _max = _w; };
                let _j = _j + 1;
            };
            return _max;
        };
        let _ei = _ei + 6;
    };
    return 0;
}

// G6: Silk walk with explicit dimension (for query-routed search)
pub fn kt_silk_walk_dim(_start_mol, _dim, _depth, _threshold) {
    _silk_init(); _bkt_init();
    return _kt_silk_walk_internal(_start_mol, _dim, _depth, _threshold);
}

// G6: Silk walk — follow strongest edges on dominant dimension
pub fn kt_silk_walk(_start_mol, _depth, _threshold) {
    _silk_init(); _bkt_init();
    let _dim = mol_dominant_dim(_start_mol);
    return _kt_silk_walk_internal(_start_mol, _dim, _depth, _threshold);
}

fn _kt_silk_walk_internal(_start_mol, _dim, _depth, _threshold) {
    let _path = [_start_mol];
    let _cur = _start_mol;
    let _d = 0;
    while _d < _depth {
        // Find best neighbor on _dim
        let _edges = __kt_silk[_silk_hash(_cur)];
        let _best_mol = [0]; let _best_w = [0];
        let _ei = 0;
        while _ei < len(_edges) {
            let _target = __array_get(_edges, _ei);
            let _w = __array_get(_edges, _ei + 1 + _dim);
            if _w > __array_get(_best_w, 0) {
                let _ = __set_at(_best_w, 0, _w);
                let _ = __set_at(_best_mol, 0, _target);
            };
            let _ei = _ei + 6;
        };
        // If no Hebbian edge, find nearest DIFFERENT node in same bucket
        if __array_get(_best_w, 0) < _threshold {
            let _s = _kt_mol_s(_cur);
            let _r = _kt_mol_r(_cur);
            let _bkt = __kt_buckets[(_s * 16) + _r];
            let _bd = [99999]; let _bm = [0];
            let _bi = 0;
            while _bi < len(_bkt) {
                let _fi = __array_get(_bkt, _bi);
                let _fm = __array_get(__kt_facts_mol, _fi);
                if _fm != _cur {
                    // Check not already in path
                    let _in_path = [0]; let _pi = 0;
                    while _pi < len(_path) {
                        if __array_get(_path, _pi) == _fm { let _ = __set_at(_in_path, 0, 1); };
                        let _pi = _pi + 1;
                    };
                    if __array_get(_in_path, 0) == 0 {
                        let _dd = _kt_mol_dist(_cur, _fm);
                        if _dd < __array_get(_bd, 0) {
                            let _ = __set_at(_bd, 0, _dd);
                            let _ = __set_at(_bm, 0, _fm);
                        };
                    };
                };
                let _bi = _bi + 1;
            };
            if __array_get(_bm, 0) > 0 {
                let _ = __set_at(_best_mol, 0, __array_get(_bm, 0));
            };
        };
        let _next = __array_get(_best_mol, 0);
        if _next == 0 { return _path; };
        if _next == _cur { return _path; };
        push(_path, _next);
        let _cur = _next;
        let _d = _d + 1;
    };
    return _path;
}

// G6: Decay all silk edges by φ⁻¹
pub fn kt_silk_decay() {
    _silk_init();
    let _hi = 0;
    while _hi < 256 {
        let _edges = __kt_silk[_hi];
        let _ei = 0;
        while _ei < len(_edges) {
            let _j = 1;
            while _j <= 5 {
                let _w = __array_get(_edges, _ei + _j);
                let _ = __set_at(_edges, _ei + _j, __floor(_w * 618 / 1000));
                let _j = _j + 1;
            };
            let _ei = _ei + 6;
        };
        let _hi = _hi + 1;
    };
}
pub fn kt_word_lookup(_w) { return []; }
pub fn kt_get_dim(_d, _v) { return []; }
pub fn kt_get_path(_p) { return []; }
pub fn kt_nearby(_m, _r) { return []; }
pub fn kt_fact_mol_at(_i) { if _i < len(__kt_facts_mol) { return __array_get(__kt_facts_mol, _i); }; return 0; }
pub fn kt_ingest_book(_p) { return ""; }
pub fn kt_ingest_full(_p) { return ""; }
pub fn kt_read_book(_p) { return ""; }
pub fn kt_find_fast(_w, _m) { return kt_find(_w, _m); }
pub fn kt_char(_c) { return 0; }
pub fn kt_word(_w) { return 0; }
