// ═══ Test: S1 String Builtins (SS23) ═══
// Tests: __str_starts_with, __str_ends_with, __str_to_num, __str_join, __str_replace

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
    // String equality: check if __str_find(a, b) == 0 AND same length
    if len(a) == len(b) {
        if len(a) == 0 {
            let _ = __set_at(_pass, 0, __array_get(_pass, 0) + 1);
            return 0;
        };
        if __str_index_of(a, b) == 0 {
            let _ = __set_at(_pass, 0, __array_get(_pass, 0) + 1);
            return 0;
        };
    };
    emit "FAIL: " + msg + " | expected=[" + b + "] got=[" + a + "]";
    let _ = __set_at(_fail, 0, __array_get(_fail, 0) + 1);
    return 0;
};

// ═══ __str_starts_with ═══
emit "T1: __str_starts_with";
assert_eq(__str_starts_with("hello world", "hello"), 1, "starts_with hello");
assert_eq(__str_starts_with("hello world", "world"), 0, "not starts_with world");
assert_eq(__str_starts_with("hello", "hello world"), 0, "prefix longer");
assert_eq(__str_starts_with("hello", ""), 1, "empty prefix");
assert_eq(__str_starts_with("", "a"), 0, "empty text");
assert_eq(__str_starts_with("abc", "abc"), 1, "exact match");

// ═══ __str_ends_with ═══
emit "T2: __str_ends_with";
assert_eq(__str_ends_with("hello world", "world"), 1, "ends_with world");
assert_eq(__str_ends_with("hello world", "hello"), 0, "not ends_with hello");
assert_eq(__str_ends_with("hello", "hello world"), 0, "suffix longer");
assert_eq(__str_ends_with("hello", ""), 1, "empty suffix");
assert_eq(__str_ends_with("test.ol", ".ol"), 1, "ends_with .ol");
assert_eq(__str_ends_with("abc", "abc"), 1, "exact match");

// ═══ __str_to_num ═══
emit "T3: __str_to_num";
assert_eq(__str_to_num("42"), 42, "parse 42");
assert_eq(__str_to_num("0"), 0, "parse 0");
assert_eq(__str_to_num("-7"), 0 - 7, "parse -7");
assert_eq(__str_to_num("100"), 100, "parse 100");
assert_eq(__str_to_num(""), 0, "parse empty");
// Fractional: verify via arithmetic (since __to_string truncates)
assert_eq(__str_to_num("1.5") * 2, 3, "1.5*2=3");
assert_eq(__str_to_num("3.14") * 100, 314, "3.14*100=314");
assert_eq(__str_to_num("0.5") + __str_to_num("0.5"), 1, "0.5+0.5=1");
assert_eq(__str_to_num("-2.5") * 2, 0 - 5, "-2.5*2=-5");

// ═══ __str_join ═══
emit "T4: __str_join";
let a1 = [];
push(a1, "hello");
push(a1, "world");
assert_str(__str_join(a1, " "), "hello world", "join space");

let a2 = [];
push(a2, "a");
push(a2, "b");
push(a2, "c");
assert_str(__str_join(a2, ","), "a,b,c", "join comma");

let a3 = [];
push(a3, "only");
assert_str(__str_join(a3, ","), "only", "join single");

let a4 = [];
assert_str(__str_join(a4, ","), "", "join empty");

// ═══ __str_replace ═══
emit "T5: __str_replace";
assert_str(__str_replace("hello world", "world", "nox"), "hello nox", "replace basic");
assert_str(__str_replace("aaa", "a", "bb"), "bbbbbb", "replace expand");
assert_str(__str_replace("hello", "xyz", "abc"), "hello", "replace no match");
assert_str(__str_replace("hello", "", "x"), "hello", "replace empty needle");
assert_str(__str_replace("a.b.c", ".", "-"), "a-b-c", "replace dots");
assert_str(__str_replace("foo bar foo", "foo", "baz"), "baz bar baz", "replace multiple");

// ═══ Results ═══
emit "";
let p = __array_get(_pass, 0);
let f = __array_get(_fail, 0);
emit __to_string(p) + "/" + __to_string(p + f) + " tests passed";
if f == 0 { emit "ALL PASS"; } else { emit __to_string(f) + " FAILED"; };
