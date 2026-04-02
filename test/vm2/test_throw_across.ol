// Test CRASH-1 fix: throw across function boundaries
// Before fix: SEGFAULT. After fix: catches correctly.

let pass = 0;
let total = 0;

// Test 1: throw from nested function
total = total + 1;
let r1 = "";
try {
    fn inner1() {
        throw "from inner";
    };
    inner1();
} catch(e) {
    r1 = "caught";
};
if r1 == "caught" { pass = pass + 1; emit "PASS 1: throw from 1 function deep"; } else { emit "FAIL 1"; };

// Test 2: throw from 2 levels deep
total = total + 1;
let r2 = "";
try {
    fn a2() {
        fn b2() {
            throw "deep";
        };
        b2();
    };
    a2();
} catch(e) {
    r2 = "caught2";
};
if r2 == "caught2" { pass = pass + 1; emit "PASS 2: throw from 2 functions deep"; } else { emit "FAIL 2"; };

// Test 3: throw from 3 levels deep
total = total + 1;
let r3 = "";
try {
    fn x3() {
        fn y3() {
            fn z3() {
                throw "very deep";
            };
            z3();
        };
        y3();
    };
    x3();
} catch(e) {
    r3 = "caught3";
};
if r3 == "caught3" { pass = pass + 1; emit "PASS 3: throw from 3 functions deep"; } else { emit "FAIL 3"; };

// Test 4: throw value preserved
total = total + 1;
let r4 = "";
try {
    fn thrower4() {
        throw "hello error";
    };
    thrower4();
} catch(e) {
    r4 = e;
};
if r4 == "hello error" { pass = pass + 1; emit "PASS 4: throw value preserved across function"; } else { emit "FAIL 4: got " + __to_string(r4); };

// Test 5: code after try/catch still works
total = total + 1;
let r5 = 0;
try {
    fn boom5() { throw "x"; };
    boom5();
} catch(e) {
    r5 = 1;
};
let after = r5 + 41;
if after == 42 { pass = pass + 1; emit "PASS 5: code after try/catch works"; } else { emit "FAIL 5"; };

// Test 6: nested try/catch with throw across functions
total = total + 1;
let r6 = "";
try {
    try {
        fn inner6() { throw "inner"; };
        inner6();
    } catch(e) {
        r6 = "inner caught";
    };
} catch(e) {
    r6 = "outer caught";
};
if r6 == "inner caught" { pass = pass + 1; emit "PASS 6: nested try/catch + function throw"; } else { emit "FAIL 6: " + r6; };

emit "";
emit __to_string(pass) + "/" + __to_string(total) + " tests passed";
if pass == total { emit "ALL PASS"; } else { emit "SOME FAILED"; };
