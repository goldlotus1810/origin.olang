// ═══ Test: S3 Module Import (SS23) ═══
import "test_import_lib.ol";
import "test_import_lib2.ol";
// Import lib1 again — should be deduped (no double "lib loaded")
import "test_import_lib.ol";

let _pass = [0];
let _fail = [0];
fn assert_eq(a, b, msg) {
    if a == b {
        let _ = __set_at(_pass, 0, __array_get(_pass, 0) + 1);
    } else {
        emit "FAIL: " + msg + " | expected=" + __to_string(b) + " got=" + __to_string(a);
        let _ = __set_at(_fail, 0, __array_get(_fail, 0) + 1);
    };
};
fn assert_str(a, b, msg) {
    if len(a) == len(b) {
        if len(a) == 0 { let _ = __set_at(_pass, 0, __array_get(_pass, 0) + 1); return 0; };
        if __str_index_of(a, b) == 0 { let _ = __set_at(_pass, 0, __array_get(_pass, 0) + 1); return 0; };
    };
    emit "FAIL: " + msg + " | expected=[" + b + "] got=[" + a + "]";
    let _ = __set_at(_fail, 0, __array_get(_fail, 0) + 1);
    return 0;
};

emit "T1: functions from lib1";
assert_eq(add(3, 4), 7, "add(3,4)==7");
assert_str(greet("Nox"), "hello Nox", "greet(Nox)");
assert_eq(LIB_VERSION, 42, "LIB_VERSION==42");

emit "T2: functions from lib2";
assert_eq(multiply(5, 6), 30, "multiply(5,6)==30");

emit "T3: dedup — lib loaded should appear only ONCE above";
// Visual check: "lib loaded" should appear once, "lib2 loaded" once

emit "";
let p = __array_get(_pass, 0);
let f = __array_get(_fail, 0);
emit __to_string(p) + "/" + __to_string(p + f) + " tests passed";
if f == 0 { emit "ALL PASS"; } else { emit __to_string(f) + " FAILED"; };
