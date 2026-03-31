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

    // 1. NRC-VAD (54K word emotions)
    let _vad_n = vad_load("json/json/mapping/NRC-VAD-Lexicon-v2.1/NRC-VAD-Lexicon-v2.1.txt");
    let _stats = _stats + "VAD:" + __to_string(_vad_n);

    // 2. UDC aliases (41K chars with names en+vi)
    let _alias_n = kt_load_aliases("json/udc_aliases.json");
    let _stats = _stats + " Alias:" + __to_string(_alias_n);

    // 3. Knowledge facts
    let _fact_n = _load_lines("homeos.knowledge");
    let _stats = _stats + " Facts:" + __to_string(_fact_n);

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
