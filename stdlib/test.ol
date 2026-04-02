// test.ol — Olang test framework
// Usage: import "stdlib/test.ol" then use assert/check/test_summary

let __test_pass = [0];
let __test_fail = [0];
let __test_errors = [];

fn assert(name, condition) {
    if condition {
        __set_at(__test_pass, 0, __array_get(__test_pass, 0) + 1);
    } else {
        __set_at(__test_fail, 0, __array_get(__test_fail, 0) + 1);
        push(__test_errors, "FAIL: " + name);
        emit "FAIL: " + name;
    };
};

fn check(name, got, expected) {
    if got == expected {
        __set_at(__test_pass, 0, __array_get(__test_pass, 0) + 1);
    } else {
        __set_at(__test_fail, 0, __array_get(__test_fail, 0) + 1);
        let msg = "FAIL: " + name + " got=" + __to_string(got) + " expected=" + __to_string(expected);
        push(__test_errors, msg);
        emit msg;
    };
};

fn test_summary() {
    let p = __array_get(__test_pass, 0);
    let f = __array_get(__test_fail, 0);
    let total = p + f;
    emit "";
    emit __to_string(p) + "/" + __to_string(total) + " tests passed";
    if f == 0 {
        emit "ALL PASS";
    } else {
        emit __to_string(f) + " FAILED:";
        let i = 0;
        while i < len(__test_errors) {
            emit "  " + __array_get(__test_errors, i);
            i = i + 1;
        };
    };
    return f == 0;
};
