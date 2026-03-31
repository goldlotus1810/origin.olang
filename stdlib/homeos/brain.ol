// homeos/brain.ol — G13+G17+G18: Self-model, Agent, Bootstrap

// G13: Self-model
pub fn self_model() {
    let _total = kt_fact_count();
    if _total == 0 { return "empty"; };
    return "KT:" + __to_string(_total) + " STM:" + __to_string(stm_count()) + " " + learning_status();
}

// G17: Agent cycle
pub fn nox_brain(input) {
    let _result = pipeline(input);
    if len(_result) > 0 { return _result; };
    let _found = kt_find(input, 3);
    if len(_found) > 0 { return __array_get(_found, 0); };
    return "";
}

// G18: Bootstrap — load ALL DNA into KnowTree
pub fn nox_bootstrap() {
    let _stats = "";

    // L0: builtins as nodes (engine knows itself)
    kt_register_l0();
    // NRC-VAD: word → V/A emotion lookup (used by _kt_real_mol)
    let _vad_n = vad_load("json/nrc_vad_top10k.txt");
    // Saved knowledge from previous sessions
    let _mem_n = kt_load("nox_memory.dat");
    __heap_pin();
    // Multilingual sentiment (12 languages, V from labels — data file, not hardcode)
    let _sent_n = kt_load("json/sentiment_precomputed.dat");
    __heap_pin();
    let _boot = kt_fact_count();
    let _stats = "L0:" + __to_string(_boot) + " VAD:" + __to_string(_vad_n) + " Mem:" + __to_string(_mem_n) + " Sent:" + __to_string(_sent_n);

    // Fire semantic silk: facts in same bucket are RELATED → connect them
    _bkt_init();
    let _silk_n = [0];
    let _bi = 0;
    while _bi < 256 {
        let _bkt = __kt_buckets[_bi];
        let _blen = len(_bkt);
        if _blen >= 2 {
            // Connect first 10 pairs in bucket (O(n) not O(n²))
            let _j = 0;
            while _j < _blen {
                if _j >= 10 { let _j = _blen; } else {
                    if _j > 0 {
                        let _m1 = __array_get(__kt_facts_mol, __array_get(_bkt, _j));
                        let _m2 = __array_get(__kt_facts_mol, __array_get(_bkt, _j - 1));
                        kt_silk_fire(_m1, _m2);
                        let _ = __set_at(_silk_n, 0, __array_get(_silk_n, 0) + 1);
                    };
                };
                let _j = _j + 1;
            };
        };
        let _bi = _bi + 1;
    };
    let _stats = _stats + " Silk:" + __to_string(__array_get(_silk_n, 0));

    __heap_pin();
    return _stats;
}

// Helper: load file line by line into KnowTree
fn _load_lines(_path) {
    let _c = __file_read(_path);
    if len(_c) == 0 { return 0; };
    let _count = [0];
    let _start = [0];
    let _i = 0;
    while _i < len(_c) {
        if __char_code(char_at(_c, _i)) == 10 {
            let _line = substr(_c, __array_get(_start, 0), _i);
            if len(_line) > 3 {
                kt_learn(_line);
                let _ = __set_at(_count, 0, __array_get(_count, 0) + 1);
                if (__array_get(_count, 0) % 80) == 0 { __heap_pin(); };
            };
            let _ = __set_at(_start, 0, _i + 1);
        };
        let _i = _i + 1;
    };
    let _last = substr(_c, __array_get(_start, 0), len(_c));
    if len(_last) > 3 { kt_learn(_last); let _ = __set_at(_count, 0, __array_get(_count, 0) + 1); };
    __heap_pin();
    return __array_get(_count, 0);
}

// Load NRC-VAD words as KnowTree facts
fn _load_vad_as_facts(_path) {
    let _c = __file_read(_path);
    if len(_c) == 0 { return 0; };
    let _clen = len(_c);
    let _count = [0];
    let _line_start = [0];
    let _i = 0;
    while _i < _clen {
        let _ch = __char_code(char_at(_c, _i));
        if _ch == 10 {
            // Find first tab (char code 9) in this line
            let _tab_pos = [0 - 1];
            let _j = __array_get(_line_start, 0);
            while _j < _i {
                if __char_code(char_at(_c, _j)) == 9 {
                    let _ = __set_at(_tab_pos, 0, _j);
                    let _j = _i;
                };
                let _j = _j + 1;
            };
            let _tp = __array_get(_tab_pos, 0);
            if _tp > __array_get(_line_start, 0) {
                let _word = substr(_c, __array_get(_line_start, 0), _tp);
                if len(_word) >= 2 {
                    kt_learn(_word);
                    let _ = __set_at(_count, 0, __array_get(_count, 0) + 1);
                    if (__array_get(_count, 0) % 50) == 0 { __heap_pin(); };
                };
            };
            let _ = __set_at(_line_start, 0, _i + 1);
        };
        let _i = _i + 1;
    };
    __heap_pin();
    return __array_get(_count, 0);
}

// Batch load pre-computed: mol\tfact per line, no encoding
fn _batch_load_raw(_path) {
    let _c = __file_read(_path);
    if len(_c) == 0 { return 0; };
    let _clen = len(_c);
    let _count = [0];
    let _ls = [0];
    let _i = 0;
    while _i < _clen {
        if __char_code(char_at(_c, _i)) == 10 {
            let _s = __array_get(_ls, 0);
            if _i - _s > 5 {
                // Find tab
                let _tab = [0 - 1];
                let _j = _s;
                while _j < _i {
                    if __char_code(char_at(_c, _j)) == 9 {
                        let _ = __set_at(_tab, 0, _j);
                        let _j = _i;
                    };
                    let _j = _j + 1;
                };
                let _tp = __array_get(_tab, 0);
                if _tp > _s {
                    let _mol = __to_number(substr(_c, _s, _tp));
                    let _fact = substr(_c, _tp + 1, _i);
                    kt_learn_raw(_fact, _mol);
                    let _ = __set_at(_count, 0, __array_get(_count, 0) + 1);
                    if (__array_get(_count, 0) % 200) == 0 { __heap_pin(); };
                };
            };
            let _ = __set_at(_ls, 0, _i + 1);
        };
        let _i = _i + 1;
    };
    __heap_pin();
    return __array_get(_count, 0);
}

// REPL data loader: call from REPL to load NRC chunks (each call = 1 chunk, heap resets between)
let __nrc_chunk_idx = [0];
pub fn nox_load_data() {
    let _ci = __array_get(__nrc_chunk_idx, 0);
    if _ci >= 10 { return "All 10 chunks loaded. " + __to_string(kt_fact_count()) + " total facts."; };
    let _path = "json/nrc_chunk_" + __to_string(_ci) + ".dat";
    let _n = kt_load(_path);
    let _ = __set_at(__nrc_chunk_idx, 0, _ci + 1);
    return "Chunk " + __to_string(_ci) + ": " + __to_string(_n) + " facts. Total: " + __to_string(kt_fact_count()) + ". Call again for next.";
}

// G24: Growth metrics
pub fn nox_metrics() {
    return "facts:" + __to_string(kt_fact_count())
         + " stm:" + __to_string(stm_count())
         + " goals:" + __to_string(goal_count())
         + " " + learning_status();
}

// G25: Failure recovery
let __fail_count = [0];
pub fn nox_fail(_input, _reason) {
    let _ = __set_at(__fail_count, 0, __array_get(__fail_count, 0) + 1);
    nac_mark(_input);
    goal_add("gap_dim" + __to_string(mol_dominant_dim(_kt_real_mol(_input))), 800);
    return "fail #" + __to_string(__array_get(__fail_count, 0));
}

// G26: Session persistence
pub fn nox_session_save() {
    let _r = kt_save_state("nox_knowtree.dat");
    __file_append("nox_growth.log", __to_string(kt_fact_count()) + " facts\n");
    return _r;
}
pub fn nox_session_load() { return kt_load_state("nox_knowtree.dat"); }

// G27: Self-evolution check
pub fn nox_evolve_check() {
    return "facts:" + __to_string(kt_fact_count())
         + " fails:" + __to_string(__array_get(__fail_count, 0))
         + " goals:" + __to_string(goal_count())
         + " top:" + goal_top();
}
