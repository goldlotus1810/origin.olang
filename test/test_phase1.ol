// ═══ Test: Phase 1 — Language Basics (SS23) ═══
// Tests: try/catch, throw, break, continue, arr[i], !operator

let _p = [0];
let _f = [0];
fn ok(cond, msg) {
    if cond { let _ = __set_at(_p, 0, _p[0] + 1); } else {
        emit "FAIL: " + msg;
        let _ = __set_at(_f, 0, _f[0] + 1);
    };
};

// ═══ arr[i] indexing ═══
emit "T1: array indexing";
let arr = [10, 20, 30];
ok(arr[0] == 10, "arr[0]==10");
ok(arr[1] == 20, "arr[1]==20");
ok(arr[2] == 30, "arr[2]==30");

// ═══ arr[i] = v assignment ═══
emit "T2: array index assignment";
arr[1] = 99;
ok(arr[1] == 99, "arr[1]=99");

// ═══ ! operator ═══
emit "T3: logical not";
ok(!0 == 1, "!0==1");
ok(!1 == 0, "!1==0");
ok(!false == 1, "!false==1");
let x = 5;
ok(!x == 0, "!5==0");
ok(!(x == 3), "!(5==3)");

// ═══ break ═══
emit "T4: break";
let count = [0];
let i = 0;
while i < 100 {
    if i == 5 { break; };
    count[0] = count[0] + 1;
    let i = i + 1;
};
ok(count[0] == 5, "break at 5");

// ═══ continue ═══
emit "T5: continue";
let sum = [0];
let j = 0;
while j < 10 {
    let j = j + 1;
    if j == 3 { continue; };
    if j == 7 { continue; };
    sum[0] = sum[0] + j;
};
// 1+2+4+5+6+8+9+10 = 45
ok(sum[0] == 45, "continue skips 3,7 → sum=45");

// ═══ try/catch ═══
emit "T6: try/catch";
let caught = [0];
try {
    throw 42;
    // should not reach here
    caught[0] = 999;
} catch(e) {
    caught[0] = 1;
};
ok(caught[0] == 1, "catch executed after throw");

// ═══ try without throw ═══
emit "T7: try no throw";
let normal = [0];
try {
    normal[0] = 100;
} catch(e) {
    normal[0] = 999;
};
ok(normal[0] == 100, "no throw → catch skipped");

// ═══ nested break ═══
emit "T8: nested break";
let outer = [0];
let k = 0;
while k < 5 {
    let m = 0;
    while m < 5 {
        if m == 2 { break; };
        let m = m + 1;
    };
    outer[0] = outer[0] + 1;
    let k = k + 1;
};
ok(outer[0] == 5, "inner break doesn't break outer");

// ═══ Results ═══
emit "";
let p = _p[0];
let f = _f[0];
emit __to_string(p) + "/" + __to_string(p + f) + " passed";
if f == 0 { emit "ALL PASS"; } else { emit __to_string(f) + " FAILED"; };
