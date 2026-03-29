// test_framework.ol — Self-contained test framework for Olang
// Usage: assert_eq(actual, expected, "test name");
//        test_report();

let _tf_pass = [0];       // box: pass count
let _tf_fail = [0];       // box: fail count
let _tf_errors = [];

pub fn assert_eq(actual, expected, name) {
    if __to_string(actual) == __to_string(expected) {
        set_at(_tf_pass, 0, _tf_pass[0] + 1);
    } else {
        set_at(_tf_fail, 0, _tf_fail[0] + 1);
        push(_tf_errors, name + ": expected " + __to_string(expected) + ", got " + __to_string(actual));
    };
}

pub fn assert_true(val, name) {
    assert_eq(val, 1, name);
}

pub fn assert_false(val, name) {
    assert_eq(val, 0, name);
}

pub fn test_report() {
    let _tr_total = _tf_pass[0] + _tf_fail[0];
    if _tf_fail[0] == 0 {
        emit "ALL PASS: " + __to_string(_tf_pass[0]) + "/" + __to_string(_tr_total);
    } else {
        emit "FAIL: " + __to_string(_tf_fail[0]) + "/" + __to_string(_tr_total);
        let _tr_i = 0;
        while _tr_i < len(_tf_errors) {
            emit "  x " + _tf_errors[_tr_i];
            let _tr_i = _tr_i + 1;
        };
    };
    return _tf_fail[0] == 0;
}

pub fn test_reset() {
    set_at(_tf_pass, 0, 0);
    set_at(_tf_fail, 0, 0);
    let _tf_errors = [];
}
