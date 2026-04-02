// ═══ Test: S2 Struct Syntax (SS23) ═══
// Tests: {key: val} dict literal, expr.field access, expr.field = val assignment

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
        if __str_index_of(a, b) == 0 {
            let _ = __set_at(_pass, 0, __array_get(_pass, 0) + 1); return 0;
        };
    };
    emit "FAIL: " + msg + " | expected=[" + b + "] got=[" + a + "]";
    let _ = __set_at(_fail, 0, __array_get(_fail, 0) + 1);
    return 0;
};

// ═══ T1: Dict literal ═══
emit "T1: dict literal";
let node = {mol: 42, weight: 100};
assert_eq(node.mol, 42, "node.mol == 42");
assert_eq(node.weight, 100, "node.weight == 100");

// ═══ T2: String values ═══
emit "T2: string values";
let person = {name: "Nox", role: "AI"};
assert_str(person.name, "Nox", "person.name == Nox");
assert_str(person.role, "AI", "person.role == AI");

// ═══ T3: Nested access ═══
emit "T3: nested values";
let config = {port: 9742, host: "localhost", debug: 0};
assert_eq(config.port, 9742, "config.port == 9742");
assert_str(config.host, "localhost", "config.host == localhost");
assert_eq(config.debug, 0, "config.debug == 0");

// ═══ T4: Dict set via dot ═══
emit "T4: dot assignment";
let d = {x: 1, y: 2};
d.x = 10;
d.y = 20;
assert_eq(d.x, 10, "d.x updated to 10");
assert_eq(d.y, 20, "d.y updated to 20");

// ═══ T5: Empty dict ═══
emit "T5: empty dict";
let empty = {};
assert_eq(empty.missing, 0, "missing key returns 0");

// ═══ T6: Dict in function ═══
emit "T6: dict in function";
fn make_point(px, py) {
    return {x: px, y: py};
};
let p = make_point(3, 4);
assert_eq(p.x, 3, "p.x == 3");
assert_eq(p.y, 4, "p.y == 4");

// ═══ T7: Dict with computed values ═══
emit "T7: computed values";
let a = 5;
let b = 10;
let calc = {sum: a + b, prod: a * b};
assert_eq(calc.sum, 15, "calc.sum == 15");
assert_eq(calc.prod, 50, "calc.prod == 50");

// ═══ T8: Dict keys ═══
emit "T8: dict keys";
let dk = {alpha: 1, beta: 2, gamma: 3};
let keys = __dict_keys(dk);
assert_eq(len(keys), 3, "3 keys");

// ═══ T9: Multiple sets to same key ═══
emit "T9: overwrite key";
let m = {val: 1};
m.val = 2;
m.val = 3;
assert_eq(m.val, 3, "m.val == 3 after 2 overwrites");

// ═══ Results ═══
emit "";
let p = __array_get(_pass, 0);
let f = __array_get(_fail, 0);
emit __to_string(p) + "/" + __to_string(p + f) + " tests passed";
if f == 0 { emit "ALL PASS"; } else { emit __to_string(f) + " FAILED"; };
