// ═══ VM v2 Full Test Suite ═══
// Run: python3 tools/compile_nox.py test/vm2/test_full.ol test/vm2/test_full.olang && ./test/vm2/test_full.olang

let pass = [0];
let fail = [0];

fn check(name, got, expected) {
    if got == expected {
        let _ = __set_at(pass, 0, __array_get(pass, 0) + 1);
    } else {
        emit "FAIL: " + name + " got=" + __to_string(got) + " expected=" + __to_string(expected);
        let _ = __set_at(fail, 0, __array_get(fail, 0) + 1);
    };
};

// Arithmetic
check("add", 1 + 2, 3);
check("sub", 10 - 3, 7);
check("mul", 6 * 7, 42);
check("div", 100 / 4, 25);
check("mod", 17 % 5, 2);
check("neg", 0 - 5, 0 - 5);
check("order", 2 + 3 * 4, 14);

// Comparison
check("eq_t", 1 == 1, 1);
check("eq_f", 1 == 2, 0);
check("ne", 1 != 2, 1);
check("lt", 3 < 5, 1);
check("gt", 5 > 3, 1);
check("le", 3 <= 3, 1);
check("ge", 5 >= 5, 1);

// Variables
let x = 42;
check("var", x, 42);
let x = x + 1;
check("reassign", x, 43);

// Functions
fn double(n) { return n * 2; };
check("fn1", double(21), 42);

fn add(a, b) { return a + b; };
check("fn2", add(10, 20), 30);

// Recursion
fn fib(n) { if n < 2 { return n; }; return fib(n - 1) + fib(n - 2); };
check("fib10", fib(10), 55);

fn fact(n) { if n < 2 { return 1; }; return n * fact(n - 1); };
check("fact5", fact(5), 120);

// While loop
let i = 0;
while i < 100 { let i = i + 1; };
check("while", i, 100);

// If/else
let r = 0;
if 3 > 5 { let r = 1; } else { let r = 2; };
check("ifelse", r, 2);

// String
check("strlen", len("hello"), 5);
check("concat_len", len("ab" + "cd"), 4);

// __floor
check("floor", __floor(5.7), 5);
check("floor0", __floor(0.9), 0);
check("floor_neg", __floor(0 - 1.5), 0 - 2);

// __to_string
check("tostr_len", len(__to_string(42)), 2);
check("tostr_len2", len(__to_string(12345)), 5);

// Arrays
let arr = [];
push(arr, 10);
push(arr, 20);
push(arr, 30);
check("arr_len", len(arr), 3);
check("arr_get0", __array_get(arr, 0), 10);
check("arr_get2", __array_get(arr, 2), 30);

// __mx_w / __mxr
__mx_w(1234, 5678);
check("mxr", __mxr(1234), 5678);
check("mxr_empty", __mxr(9999), 0);

// Bitwise
check("band", __bit_and(255, 15), 15);
check("bor", __bit_or(240, 15), 255);
check("bxor", __bit_xor(255, 255), 0);
check("bshl", __bit_shl(1, 8), 256);
check("bshr", __bit_shr(256, 8), 1);

// __char_code
check("charcode", __char_code("A"), 65);

// Summary
let p = __array_get(pass, 0);
let f = __array_get(fail, 0);
emit __to_string(p) + "/" + __to_string(p + f) + " tests passed";
if f == 0 { emit "ALL PASS"; } else { emit __to_string(f) + " FAILED"; };
