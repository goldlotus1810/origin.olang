// homeos/brain.ol — G13+G17+G18: Self-model, Agent, Bootstrap

// G13: Self-model — what do I know? per-bucket confidence
pub fn self_model() {
    let _total = kt_fact_count();
    if _total == 0 { return "empty"; };
    let _out = "Knowledge: " + __to_string(_total) + " facts";
    let _out = _out + " | STM: " + __to_string(stm_count());
    let _out = _out + " | " + learning_status();
    return _out;
}

// G17: Agent cycle — perceive → think → act → verify
pub fn nox_brain(input) {
    // Perceive: encode input
    let _result = pipeline(input);
    if len(_result) > 0 { return _result; };
    // If pipeline returns empty, try text search
    let _found = kt_find(input, 3);
    if len(_found) > 0 { return __array_get(_found, 0); };
    return "";
}

// G18: Bootstrap — load ALL data
pub fn nox_bootstrap() {
    // Load NRC-VAD (54K word emotions)
    let _vad_n = vad_load("json/json/mapping/NRC-VAD-Lexicon-v2.1/NRC-VAD-Lexicon-v2.1.txt");

    // Load knowledge facts
    let _c = __file_read("homeos.knowledge");
    if len(_c) == 0 { return "NRC-VAD:" + __to_string(_vad_n) + " facts:0"; };
    // Split by newlines, learn each
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
    // Last line
    let _last = substr(_c, __array_get(_start, 0), len(_c));
    if len(_last) > 3 { kt_learn(_last); let _ = __set_at(_count, 0, __array_get(_count, 0) + 1); };
    __heap_pin();
    return "NRC-VAD:" + __to_string(_vad_n) + " facts:" + __to_string(__array_get(_count, 0));
}

// G24: Growth metrics
pub fn nox_metrics() {
    return "facts:" + __to_string(kt_fact_count())
         + " stm:" + __to_string(stm_count())
         + " goals:" + __to_string(goal_count())
         + " " + learning_status();
}

// G25: Failure recovery — log failures as negative knowledge
let __fail_count = [0];

pub fn nox_fail(_input, _reason) {
    let _ = __set_at(__fail_count, 0, __array_get(__fail_count, 0) + 1);
    // Mark this region as knowledge gap
    nac_mark(_input);
    // Add goal to learn about this topic
    let _dim = mol_dominant_dim(_kt_real_mol(_input));
    goal_add("gap_dim" + __to_string(_dim), 800);
    return "logged failure #" + __to_string(__array_get(__fail_count, 0));
}

// G26: Session persistence
pub fn nox_session_save() {
    let _r = kt_save_state("nox_knowtree.dat");
    // Append growth log
    let _log = __to_string(__array_get(__fail_count, 0)) + " fails, "
             + __to_string(kt_fact_count()) + " facts, "
             + __to_string(stm_count()) + " stm\n";
    __file_append("nox_growth.log", _log);
    return _r;
}

pub fn nox_session_load() {
    return kt_load_state("nox_knowtree.dat");
}

// G27: Self-evolution — measure → identify → report
pub fn nox_evolve_check() {
    let _facts = kt_fact_count();
    let _fails = __array_get(__fail_count, 0);
    let _goals = goal_count();
    let _top = goal_top();
    let _out = "Evolution: " + __to_string(_facts) + " facts";
    let _out = _out + ", " + __to_string(_fails) + " fails";
    let _out = _out + ", " + __to_string(_goals) + " goals";
    if len(_top) > 0 { let _out = _out + ", top: " + _top; };
    return _out;
}
