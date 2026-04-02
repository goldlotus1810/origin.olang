// Test SCOPE-THROW: closure_depth + var_save_top restore after throw
import "stdlib/test.ol"

// Sora's test: throw from nested closures, catch block accesses outer var
let r1 = "";
fn outer1() {
    let x = "original";
    try {
        fn middle() {
            fn inner() {
                throw "boom";
            };
            inner();
        };
        middle();
    } catch(e) {
        r1 = x;
    };
};
outer1();
check("scope_restore", r1, "original");

// After throw, new function calls should work correctly
let r2 = 0;
fn add(a, b) { return a + b; };
r2 = add(10, 32);
check("fn_after_throw", r2, 42);

// Nested try/catch with function calls between
let r3 = "";
try {
    fn throws3() { throw "first"; };
    throws3();
} catch(e) {
    r3 = e;
};
try {
    fn throws3b() { throw "second"; };
    throws3b();
} catch(e) {
    r3 = r3 + "+" + e;
};
check("sequential_throw", r3, "first+second");

// Throw value type preserved
let r4 = 0;
try {
    fn throws_num() { throw 42; };
    throws_num();
} catch(e) {
    r4 = e;
};
check("throw_number", r4, 42);

// Deep nesting: 4 levels
let r5 = "";
fn level1() {
    fn level2() {
        fn level3() {
            fn level4() {
                throw "deep4";
            };
            level4();
        };
        level3();
    };
    level2();
};
try {
    level1();
} catch(e) {
    r5 = e;
};
check("4_levels_deep", r5, "deep4");

// Variable scoping after throw
let counter = [0];
fn inc() {
    __set_at(counter, 0, __array_get(counter, 0) + 1);
};
try {
    inc();
    inc();
    fn explode() { throw "x"; };
    explode();
    inc();
} catch(e) {
    inc();
};
check("counter_after_throw", __array_get(counter, 0), 3);

test_summary();
