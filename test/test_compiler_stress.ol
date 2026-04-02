let pass = 0;
let fail = 0;

// T1: nested try/catch
let r1 = 0;
try {
    try {
        throw "inner";
    } catch(e1) {
        r1 = 1;
    };
    throw "outer";
} catch(e2) {
    r1 = r1 + 10;
};
if r1 == 11 { pass = pass + 1; } else { fail = fail + 1; emit "FAIL T1: nested try"; };

// T2: break in for loop
let r2 = 0;
for x in [10, 20, 30, 40, 50] {
    if x == 30 { break; };
    r2 = r2 + x;
};
if r2 == 30 { pass = pass + 1; } else { fail = fail + 1; emit "FAIL T2: for+break"; };

// T3: continue in for loop
let r3 = 0;
for x in [1, 2, 3, 4, 5] {
    if x == 3 { continue; };
    r3 = r3 + x;
};
if r3 == 12 { pass = pass + 1; } else { fail = fail + 1; emit "FAIL T3: for+continue"; };

// T4: match with variable patterns
let val = 42;
let r4 = 0;
match val {
    10 => r4 = 1;
    42 => r4 = 2;
    _ => r4 = 3;
};
if r4 == 2 { pass = pass + 1; } else { fail = fail + 1; emit "FAIL T4: match var"; };

// T5: closure captures with modification before call
let base = 100;
fn get_base(x) { return base + x; };
base = 200;
let r5 = get_base(5);
// At top level, no capture — uses current value of base (200)
if r5 == 205 { pass = pass + 1; } else { fail = fail + 1; emit "FAIL T5: closure timing"; };

// T6: nested for loops
let r6 = 0;
for i in [1, 2, 3] {
    for j in [10, 20] {
        r6 = r6 + i * j;
    };
};
// (1*10+1*20) + (2*10+2*20) + (3*10+3*20) = 30+60+90 = 180
if r6 == 180 { pass = pass + 1; } else { fail = fail + 1; emit "FAIL T6: nested for"; };

// T7: match with no default
let r7 = 99;
match 5 {
    1 => r7 = 10;
    5 => r7 = 50;
};
if r7 == 50 { pass = pass + 1; } else { fail = fail + 1; emit "FAIL T7: match no default"; };

// T8: while with both break and continue
let r8 = 0;
let k = 0;
while k < 100 {
    k = k + 1;
    if k % 2 == 0 { continue; };
    if k > 10 { break; };
    r8 = r8 + k;
};
// odd numbers 1,3,5,7,9 = 25
if r8 == 25 { pass = pass + 1; } else { fail = fail + 1; emit "FAIL T8: break+continue"; };

// T9: try/catch in for loop
let r9 = 0;
for x in [1, 2, 3] {
    try {
        if x == 2 { throw "skip"; };
        r9 = r9 + x;
    } catch(e) {
        r9 = r9 + 100;
    };
};
// 1 + 100 + 3 = 104
if r9 == 104 { pass = pass + 1; } else { fail = fail + 1; emit "FAIL T9: try in for"; };

// T10: complex expression in match
let r10 = 0;
match 2 + 3 {
    4 => r10 = 40;
    5 => r10 = 50;
    _ => r10 = 0;
};
if r10 == 50 { pass = pass + 1; } else { fail = fail + 1; emit "FAIL T10: match expr"; };

emit pass;
emit "/10 stress tests passed";
