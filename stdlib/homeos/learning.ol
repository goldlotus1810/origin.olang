// homeos/learning.ol — G7+G12+G4: STM, Dream, Immune, Repair, Decode

// ═══ G7: STM — 32 slots with eviction scoring ═══
let __stm_text = [];
let __stm_mol = [];
let __stm_v = [];
let __stm_a = [];
let __stm_access = [];
let __stm_max = 32;
let __stm_turn = [0];

pub fn stm_push(_text) {
    let _mol = _kt_real_mol(_text);
    let _v = mol_get_dim(_mol, 2);
    let _a = mol_get_dim(_mol, 3);
    // Evict if full
    if len(__stm_text) >= __stm_max {
        let _min_score = [999999];
        let _min_idx = [0];
        let _i = 0;
        while _i < len(__stm_text) {
            let _turns_ago = __array_get(__stm_turn, 0) - _i;
            let _recency = 1000;
            if _turns_ago > 0 { let _recency = __floor(618000 / (1000 + (_turns_ago * 382))); };
            let _emo = _kt_abs(__array_get(__stm_v, _i) - 4) * __array_get(__stm_a, _i);
            let _score = (__array_get(__stm_access, _i) * 300) + (_emo * 400) + (_recency * 300);
            let _score = __floor(_score / 1000);
            if _score < __array_get(_min_score, 0) {
                let _ = __set_at(_min_score, 0, _score);
                let _ = __set_at(_min_idx, 0, _i);
            };
            let _i = _i + 1;
        };
        let _evict = __array_get(_min_idx, 0);
        let _ = __set_at(__stm_text, _evict, _text);
        let _ = __set_at(__stm_mol, _evict, _mol);
        let _ = __set_at(__stm_v, _evict, _v);
        let _ = __set_at(__stm_a, _evict, _a);
        let _ = __set_at(__stm_access, _evict, 1);
    } else {
        push(__stm_text, _text);
        push(__stm_mol, _mol);
        push(__stm_v, _v);
        push(__stm_a, _a);
        push(__stm_access, 1);
    };
    let _ = __set_at(__stm_turn, 0, __array_get(__stm_turn, 0) + 1);
    // Silk fire with recent entries
    let _n = len(__stm_mol);
    if _n >= 2 { kt_silk_fire(_mol, __array_get(__stm_mol, _n - 2)); };
}

pub fn stm_count() { return len(__stm_text); }

// ═══ G7: Dream — cross-group consolidation ═══
let __dream_count = [0];

pub fn dream() {
    // Scan STM pairs for cross-bucket connections
    let _n = len(__stm_mol);
    if _n < 2 { return; };
    let _i = 0;
    while _i < _n {
        let _j = _i + 1;
        while _j < _n {
            let _mi = __array_get(__stm_mol, _i);
            let _mj = __array_get(__stm_mol, _j);
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
    // Decay all silk
    kt_silk_decay();
    let _ = __set_at(__dream_count, 0, __array_get(__dream_count, 0) + 1);
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
pub fn qr_count() { return 0; }
pub fn learning_status() {
    return "DN:" + __to_string(len(_qr_facts))
         + " STM:" + __to_string(stm_count())
         + " Dream:" + __to_string(__array_get(__dream_count, 0));
}
