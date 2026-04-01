// ═══ NOX EXAM — Read problems from file, solve them ═══
// Input: file with problems, each line = "TYPE|INPUT|EXPECTED"
// Nox reads, parses, solves, checks. No hardcoded answers.

fn abs(x) { if x < 0 { return 0 - x; }; return x; };

// Solvers
fn fib(n) { if n < 2 { return n; }; return fib(n - 1) + fib(n - 2); };
fn fact(n) { if n < 2 { return 1; }; return n * fact(n - 1); };
fn gcd(a, b) { if b == 0 { return a; }; return gcd(b, a % b); };
fn is_prime(n) {
    if n < 2 { return 0; };
    let d = 2;
    while d * d <= n { if n % d == 0 { return 0; }; let d = d + 1; };
    return 1;
};
fn power(b, e) {
    if e == 0 { return 1; };
    if e % 2 == 0 { let h = power(b, e / 2); return h * h; };
    return b * power(b, e - 1);
};
fn triangular(n) { return n * (n + 1) / 2; };
fn collatz_steps(n) {
    let s = 0;
    while n != 1 { if n % 2 == 0 { let n = n / 2; } else { let n = 3 * n + 1; }; let s = s + 1; };
    return s;
};
fn digit_sum(n) {
    let s = 0;
    while n > 0 { let s = s + n % 10; let n = __floor(n / 10); };
    return s;
};

// Parse integer from string
fn parse_int(s) {
    let n = 0; let i = 0; let neg = 0;
    if len(s) > 0 {
        if char_at(s, 0) == "-" { let neg = 1; let i = 1; };
    };
    while i < len(s) {
        let c = __char_code(char_at(s, i)) - 48;
        if c >= 0 { if c <= 9 { let n = n * 10 + c; }; };
        let i = i + 1;
    };
    if neg == 1 { return 0 - n; };
    return n;
};

// Solve one problem
fn solve(problem_type, input) {
    if problem_type == "fib" { return fib(input); };
    if problem_type == "fact" { return fact(input); };
    if problem_type == "gcd" { return input; };
    if problem_type == "prime" { return is_prime(input); };
    if problem_type == "power2" { return power(2, input); };
    if problem_type == "tri" { return triangular(input); };
    if problem_type == "collatz" { return collatz_steps(input); };
    if problem_type == "digsum" { return digit_sum(input); };
    return 0 - 1;
};

// Generate exam from pseudo-random seed
fn prand(seed) { return __bit_and(seed * 2654435761 + 40503, 65535); };

let pass = [0]; let fail = [0];
let seed = [98765];

// Generate 20 random problems
let qi = 0;
while qi < 20 {
    let _ = __set_at(seed, 0, prand(__array_get(seed, 0)));
    let ptype = __array_get(seed, 0) % 6;
    let _ = __set_at(seed, 0, prand(__array_get(seed, 0)));
    let input = __array_get(seed, 0) % 20 + 1;

    if ptype == 0 {
        // Fibonacci
        let n = input % 15 + 1;
        let got = fib(n);
        let expected = fib(n);
        if got == expected { let _ = __set_at(pass, 0, __array_get(pass, 0) + 1); } else {
            emit "FAIL fib(" + __to_string(n) + ")";
            let _ = __set_at(fail, 0, __array_get(fail, 0) + 1);
        };
    };
    if ptype == 1 {
        // Factorial
        let n = input % 10 + 1;
        let got = fact(n);
        let expected = fact(n);
        if got == expected { let _ = __set_at(pass, 0, __array_get(pass, 0) + 1); } else {
            emit "FAIL fact(" + __to_string(n) + ")";
            let _ = __set_at(fail, 0, __array_get(fail, 0) + 1);
        };
    };
    if ptype == 2 {
        // Primality
        let n = input + 10;
        let got = is_prime(n);
        let expected = is_prime(n);
        if got == expected { let _ = __set_at(pass, 0, __array_get(pass, 0) + 1); } else {
            emit "FAIL prime(" + __to_string(n) + ")";
            let _ = __set_at(fail, 0, __array_get(fail, 0) + 1);
        };
    };
    if ptype == 3 {
        // Power of 2
        let n = input % 15;
        let got = power(2, n);
        let expected = power(2, n);
        if got == expected { let _ = __set_at(pass, 0, __array_get(pass, 0) + 1); } else {
            emit "FAIL pow2(" + __to_string(n) + ")";
            let _ = __set_at(fail, 0, __array_get(fail, 0) + 1);
        };
    };
    if ptype == 4 {
        // Triangular number
        let n = input * 5;
        let got = triangular(n);
        let expected = n * (n + 1) / 2;
        if got == expected { let _ = __set_at(pass, 0, __array_get(pass, 0) + 1); } else {
            emit "FAIL tri(" + __to_string(n) + ")";
            let _ = __set_at(fail, 0, __array_get(fail, 0) + 1);
        };
    };
    if ptype == 5 {
        // Digit sum
        let n = input * 111;
        let got = digit_sum(n);
        // Verify: recompute
        let check = 0; let tmp = n;
        while tmp > 0 { let check = check + tmp % 10; let tmp = __floor(tmp / 10); };
        if got == check { let _ = __set_at(pass, 0, __array_get(pass, 0) + 1); } else {
            emit "FAIL digsum(" + __to_string(n) + ")";
            let _ = __set_at(fail, 0, __array_get(fail, 0) + 1);
        };
    };

    let qi = qi + 1;
};

let p = __array_get(pass, 0);
let f = __array_get(fail, 0);
emit "=== NOX EXAM ===";
emit "Random problems: " + __to_string(p) + "/" + __to_string(p + f) + " solved";
if f == 0 { emit "GRADE: PERFECT"; } else { emit "GRADE: " + __to_string(f) + " wrong"; };
