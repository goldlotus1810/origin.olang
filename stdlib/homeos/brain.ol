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

// G18: Bootstrap — load knowledge from file
pub fn nox_bootstrap() {
    let _c = __file_read("homeos.knowledge");
    if len(_c) == 0 { return "no homeos.knowledge"; };
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
    return "Loaded " + __to_string(__array_get(_count, 0)) + " facts";
}

// G24: Growth metrics
pub fn nox_metrics() {
    return "facts:" + __to_string(kt_fact_count())
         + " stm:" + __to_string(stm_count())
         + " " + learning_status();
}
