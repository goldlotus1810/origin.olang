// ═══ Test: S4 For/Match Sugar (SS23) ═══

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

// ═══ FOR ═══
emit "T1: basic for loop";
let sum = [0];
let nums = [1, 2, 3, 4, 5];
for n in nums {
    let _ = __set_at(sum, 0, __array_get(sum, 0) + n);
};
assert_eq(__array_get(sum, 0), 15, "sum 1..5 == 15");

emit "T2: for with strings";
let result = [0];
let words = ["hello", "world"];
for w in words {
    let _ = __set_at(result, 0, __array_get(result, 0) + 1);
};
assert_eq(__array_get(result, 0), 2, "2 words iterated");

emit "T3: for with empty array";
let count = [0];
let empty = [];
for x in empty {
    let _ = __set_at(count, 0, __array_get(count, 0) + 1);
};
assert_eq(__array_get(count, 0), 0, "empty array = 0 iterations");

emit "T4: nested for";
let total = [0];
let a = [1, 2];
let b = [10, 20];
for x in a {
    for y in b {
        let _ = __set_at(total, 0, __array_get(total, 0) + x * y);
    };
};
// (1*10 + 1*20) + (2*10 + 2*20) = 30 + 60 = 90
assert_eq(__array_get(total, 0), 90, "nested for sum == 90");

// ═══ MATCH ═══
emit "T5: basic match";
let x = 2;
let matched = [0];
match x {
    1 => let _ = __set_at(matched, 0, 10);
    2 => let _ = __set_at(matched, 0, 20);
    3 => let _ = __set_at(matched, 0, 30);
    _ => let _ = __set_at(matched, 0, 0 - 1);
};
assert_eq(__array_get(matched, 0), 20, "match 2 → 20");

emit "T6: match default";
let y = 99;
let def_hit = [0];
match y {
    1 => let _ = __set_at(def_hit, 0, 1);
    _ => let _ = __set_at(def_hit, 0, 999);
};
assert_eq(__array_get(def_hit, 0), 999, "match default → 999");

emit "T7: match with expressions";
let code = 200;
let status = [0];
match code {
    200 => let _ = __set_at(status, 0, 1);
    404 => let _ = __set_at(status, 0, 2);
    500 => let _ = __set_at(status, 0, 3);
    _ => let _ = __set_at(status, 0, 0);
};
assert_eq(__array_get(status, 0), 1, "match 200 → status 1");

// ═══ Results ═══
emit "";
let p = __array_get(_pass, 0);
let f = __array_get(_fail, 0);
emit __to_string(p) + "/" + __to_string(p + f) + " tests passed";
if f == 0 { emit "ALL PASS"; } else { emit __to_string(f) + " FAILED"; };
