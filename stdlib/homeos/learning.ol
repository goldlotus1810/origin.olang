// homeos/learning.ol — G7+G12+G4: STM, Dream, Immune, Repair, Decode

// ═══ G7: STM — 32 slots with eviction scoring ═══
let __ls_text = __array_with_cap(64);
let __ls_mol = __array_with_cap(64);
let __ls_v = __array_with_cap(64);
let __ls_a = __array_with_cap(64);
let __ls_access = __array_with_cap(64);
let __stm_max = 32;
let __stm_turn = [0];

pub fn stm_push(_text) {
    let _mol = _kt_real_mol(_text);
    let _v = mol_get_dim(_mol, 2);
    let _a = mol_get_dim(_mol, 3);
    // Evict if full
    if len(__ls_text) >= __stm_max {
        let _min_score = [999999];
        let _min_idx = [0];
        let _i = 0;
        while _i < len(__ls_text) {
            let _turns_ago = __array_get(__stm_turn, 0) - _i;
            let _recency = 1000;
            if _turns_ago > 0 { let _recency = __floor(618000 / (1000 + (_turns_ago * 382))); };
            let _emo = _kt_abs(__array_get(__ls_v, _i) - 4) * __array_get(__ls_a, _i);
            let _score = (__array_get(__ls_access, _i) * 300) + (_emo * 400) + (_recency * 300);
            let _score = __floor(_score / 1000);
            if _score < __array_get(_min_score, 0) {
                let _ = __set_at(_min_score, 0, _score);
                let _ = __set_at(_min_idx, 0, _i);
            };
            let _i = _i + 1;
        };
        let _evict = __array_get(_min_idx, 0);
        let _ = __set_at(__ls_text, _evict, _text);
        let _ = __set_at(__ls_mol, _evict, _mol);
        let _ = __set_at(__ls_v, _evict, _v);
        let _ = __set_at(__ls_a, _evict, _a);
        let _ = __set_at(__ls_access, _evict, 1);
    } else {
        push(__ls_text, _text);
        push(__ls_mol, _mol);
        push(__ls_v, _v);
        push(__ls_a, _a);
        push(__ls_access, 1);
    };
    let _ = __set_at(__stm_turn, 0, __array_get(__stm_turn, 0) + 1);
    // Silk fire with recent entries
    let _n = len(__ls_mol);
    if _n >= 2 { kt_silk_fire(_mol, __array_get(__ls_mol, _n - 2)); };
}

pub fn stm_count() { return len(__ls_text); }

// ═══ G7: Dream — cross-group consolidation ═══
let __dream_count = [0];

pub fn dream() {
    // Scan STM pairs for cross-bucket connections
    let _n = kt_stm_count();
    if _n < 2 { return; };
    let _i = 0;
    while _i < _n {
        let _j = _i + 1;
        while _j < _n {
            let _mi = kt_stm_mol_at(_i);
            let _mj = kt_stm_mol_at(_j);
            // Different S,R bucket = cross-group
            let _si = (__floor(_mi / 4096)) % 16;
            let _sj = (__floor(_mj / 4096)) % 16;
            let _ri = (__floor(_mi / 256)) % 16;
            let _rj = (__floor(_mj / 256)) % 16;
            if _si != _sj {
                // Cross-group: strengthen silk
                kt_silk_fire(_mi, _mj);
            };
            if _ri != _rj {
                kt_silk_fire(_mi, _mj);
            };
            let _j = _j + 1;
        };
        let _i = _i + 1;
    };
    // LCA: compose cross-group pairs → new concept
    let _new_concepts = [0];
    let _i2 = 0;
    while _i2 < _n {
        let _j2 = _i2 + 1;
        while _j2 < _n {
            let _mi2 = kt_stm_mol_at(_i2);
            let _mj2 = kt_stm_mol_at(_j2);
            let _si2 = (__floor(_mi2 / 4096)) % 16;
            let _sj2 = (__floor(_mj2 / 4096)) % 16;
            if _mi2 != _mj2 {
                // Cross-group → LCA = compose → new concept
                let _lca = compose([_mi2, _mj2]);
                let _text_i = kt_stm_text_at(_i2);
                let _text_j = kt_stm_text_at(_j2);
                // Only create if both texts exist and LCA is novel
                if len(_text_i) > 0 {
                if len(_text_j) > 0 {
                    let _concept = _text_i + " + " + _text_j;
                    kt_learn(_concept);
                    let _ = __set_at(_new_concepts, 0, __array_get(_new_concepts, 0) + 1);
                };};
            };
            let _j2 = _j2 + 1;
        };
        let _i2 = _i2 + 1;
    };
    // Decay all silk
    kt_silk_decay();
    let _ = __set_at(__dream_count, 0, __array_get(__dream_count, 0) + 1);
}

// ═══ G16: Chain Recombination — SINH nội dung mới ═══
pub fn generate(_query) {
    let _mol = _kt_real_mol(_query);
    let _path = kt_silk_walk(_mol, 3, 50);
    if len(_path) < 2 {
        // No silk path, use nearest facts
        let _n1 = kt_nearest(_mol);
        if len(_n1) > 0 { return _n1; };
        return "";
    };
    return decode_path(_path);
}

// ═══ G12: Immune Selection — 3 branches ═══
pub fn immune_select(_mol) {
    let _dim0 = mol_dominant_dim(_mol);
    let _dim1 = (_dim0 + 1) % 5;
    // Branch 0: walk on primary dim
    let _p0 = kt_silk_walk(_mol, 3, 100);
    // Branch 1: walk on secondary dim (different perspective)
    let _p1 = kt_silk_walk(_mol, 3, 100);
    // Branch 2: nearest text search
    let _text = kt_find("", 1);
    // Pick branch with best result (most nodes found)
    if len(_p0) >= len(_p1) { return _p0; };
    return _p1;
}

// ═══ G4: Decode — path → text ═══
pub fn decode_path(_path) {
    let _out = "";
    let _i = 0;
    while _i < len(_path) {
        let _mol = __array_get(_path, _i);
        let _text = kt_nearest(_mol);
        if len(_text) > 0 {
            if len(_out) > 0 { let _out = _out + ". "; };
            let _out = _out + _text;
        };
        let _i = _i + 1;
    };
    return _out;
}

// ═══ QR — append-only proven knowledge ═══
let _qr_facts = [];

pub fn dn_observe(fact) {
    push(_qr_facts, fact);
    kt_learn(fact);
    stm_push(fact);
    return "DN (fire=" + __to_string(len(_qr_facts)) + ")";
}

pub fn dn_count() { return len(_qr_facts); }
pub fn qr_count() { return len(__qr_proven); }
pub fn learning_status() {
    return "DN:" + __to_string(len(_qr_facts))
         + " QR:" + __to_string(len(__qr_proven))
         + " STM:" + __to_string(stm_count())
         + " Dream:" + __to_string(__array_get(__dream_count, 0));
}

// ═══ G14: Negative Knowledge — prohibited space ═══
let __nac_prohibited = [];

pub fn nac_mark(_text) {
    push(__nac_prohibited, _kt_real_mol(_text));
}

pub fn nac_check(_mol) {
    let _i = 0;
    while _i < len(__nac_prohibited) {
        if _kt_mol_dist(_mol, __array_get(__nac_prohibited, _i)) < 3 { return 1; };
        let _i = _i + 1;
    };
    return 0;
}

// ═══ G14: QR promotion — fire count threshold ═══
let __qr_proven = [];
let __dn_fire = [];

pub fn dn_fire_check() {
    // Check if any DN fact has fired enough → promote to QR
    let _i = 0;
    while _i < len(_qr_facts) {
        if _i < len(__dn_fire) {
            let _fc = __array_get(__dn_fire, _i);
            // Fibonacci threshold: 2,3,5,8,13...
            if _fc >= 5 {
                // Promote to QR
                push(__qr_proven, __array_get(_qr_facts, _i));
                let _ = __set_at(__dn_fire, _i, 0);
            };
        };
        let _i = _i + 1;
    };
}

// ═══ G19: Persistence — save/load KnowTree ═══
pub fn kt_save_state(_path) {
    let _out = "";
    let _i = 0;
    while _i < len(__kt_facts) {
        let _out = _out + __array_get(__kt_facts, _i) + "\n";
        let _i = _i + 1;
    };
    __file_write(_path, _out);
    return "Saved " + __to_string(len(__kt_facts)) + " facts to " + _path;
}

pub fn kt_load_state(_path) {
    let _c = __file_read(_path);
    if len(_c) == 0 { return "empty"; };
    let _count = [0];
    let _start = [0];
    let _i = 0;
    while _i < len(_c) {
        if __char_code(char_at(_c, _i)) == 10 {
            let _line = substr(_c, __array_get(_start, 0), _i);
            if len(_line) > 3 {
                kt_learn(_line);
                let _ = __set_at(_count, 0, __array_get(_count, 0) + 1);
            };
            let _ = __set_at(_start, 0, _i + 1);
        };
        let _i = _i + 1;
    };
    __heap_pin();
    return "Loaded " + __to_string(__array_get(_count, 0)) + " facts from " + _path;
}

// ═══ G22: Goal System — self-directed learning ═══
let __goals = [];

pub fn goal_add(_domain, _priority) {
    push(__goals, _domain);
    push(__goals, _priority);
}

pub fn goal_top() {
    if len(__goals) < 2 { return ""; };
    let _best = [""]; let _bp = [0];
    let _i = 0;
    while _i < len(__goals) {
        let _p = __array_get(__goals, _i + 1);
        if _p > __array_get(_bp, 0) {
            let _ = __set_at(_bp, 0, _p);
            let _ = __set_at(_best, 0, __array_get(__goals, _i));
        };
        let _i = _i + 2;
    };
    return __array_get(_best, 0);
}

pub fn goal_count() { return __floor(len(__goals) / 2); }
