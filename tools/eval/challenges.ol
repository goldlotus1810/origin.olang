// ═══ NOX CHALLENGE BOOK ═══
// Mọi bài toán tồn tại trên thế giới. Nox phải giải được.
// Không hardcode đáp án. Chỉ thuật toán.

fn abs(x) { if x < 0 { return 0 - x; }; return x; };
let pass = [0];
let fail = [0];
fn ok(name, got, expected) {
    if got == expected {
        let _ = __set_at(pass, 0, __array_get(pass, 0) + 1);
    } else {
        emit "FAIL " + name + ": " + __to_string(got) + " != " + __to_string(expected);
        let _ = __set_at(fail, 0, __array_get(fail, 0) + 1);
    };
};

// ═══ 1. NUMBER THEORY ═══

// 1.1 GCD (Euclid 300 BC)
fn gcd(a, b) { if b == 0 { return a; }; return gcd(b, a % b); };
ok("gcd(48,18)", gcd(48, 18), 6);
ok("gcd(1071,462)", gcd(1071, 462), 21);

// 1.2 LCM
fn lcm(a, b) { return a * b / gcd(a, b); };
ok("lcm(4,6)", lcm(4, 6), 12);
ok("lcm(21,6)", lcm(21, 6), 42);

// 1.3 Primality
fn is_prime(n) {
    if n < 2 { return 0; };
    let d = 2;
    while d * d <= n { if n % d == 0 { return 0; }; let d = d + 1; };
    return 1;
};
ok("prime(2)", is_prime(2), 1);
ok("prime(97)", is_prime(97), 1);
ok("prime(100)", is_prime(100), 0);

// 1.4 Count primes up to N
fn count_primes(n) {
    let c = 0; let i = 2;
    while i <= n { if is_prime(i) == 1 { let c = c + 1; }; let i = i + 1; };
    return c;
};
ok("primes<=100", count_primes(100), 25);

// 1.5 Fibonacci modular (prevent overflow)
fn fib_mod(n, m) {
    let a = 0; let b = 1; let i = 0;
    while i < n { let t = b; let b = (a + b) % m; let a = t; let i = i + 1; };
    return a;
};
ok("fib(10)%1000", fib_mod(10, 1000), 55);
ok("fib(50)%997", fib_mod(50, 997), 586);

// 1.6 Power mod (fast exponentiation)
fn pow_mod(base, exp, m) {
    let result = 1; let b = base % m;
    while exp > 0 {
        if exp % 2 == 1 { let result = result * b % m; };
        let exp = __floor(exp / 2);
        let b = b * b % m;
    };
    return result;
};
ok("2^10 mod 1000", pow_mod(2, 10, 1000), 24);
ok("3^13 mod 100", pow_mod(3, 13, 100), 87);

// ═══ 2. SORTING & SEARCHING ═══

// 2.1 Insertion sort
fn isort(arr) {
    let i = 1;
    while i < len(arr) {
        let key = __array_get(arr, i);
        let j = i - 1;
        while j >= 0 {
            if __array_get(arr, j) > key {
                let _ = __set_at(arr, j + 1, __array_get(arr, j));
                let j = j - 1;
            } else {
                let j = 0 - 1;
            };
        };
        let _ = __set_at(arr, j + 1, key);
        let i = i + 1;
    };
};
let a1 = __array_with_cap(16);
push(a1, 9); push(a1, 3); push(a1, 7); push(a1, 1); push(a1, 5);
push(a1, 8); push(a1, 2); push(a1, 6); push(a1, 4); push(a1, 10);
isort(a1);
ok("isort[0]", __array_get(a1, 0), 1);
ok("isort[9]", __array_get(a1, 9), 10);

// 2.2 Binary search
fn bsearch(arr, target) {
    let lo = 0; let hi = len(arr) - 1;
    while lo <= hi {
        let mid = __floor((lo + hi) / 2);
        let val = __array_get(arr, mid);
        if val == target { return mid; };
        if val < target { let lo = mid + 1; } else { let hi = mid - 1; };
    };
    return 0 - 1;
};
ok("bsearch(5)", bsearch(a1, 5), 4);
ok("bsearch(11)", bsearch(a1, 11), 0 - 1);

// 2.3 Linear search with sentinel
fn lsearch(arr, target) {
    let i = 0;
    while i < len(arr) {
        if __array_get(arr, i) == target { return i; };
        let i = i + 1;
    };
    return 0 - 1;
};
ok("lsearch(7)", lsearch(a1, 7), 6);

// ═══ 3. STRING ALGORITHMS ═══

// 3.1 String reverse
fn reverse(s) {
    let r = "";
    let i = len(s) - 1;
    while i >= 0 {
        let r = r + char_at(s, i);
        let i = i - 1;
    };
    return r;
};
ok("reverse", len(reverse("hello")), 5);

// 3.2 Palindrome check
fn is_palindrome(s) {
    let i = 0; let j = len(s) - 1;
    while i < j {
        if char_at(s, i) != char_at(s, j) { return 0; };
        let i = i + 1; let j = j - 1;
    };
    return 1;
};
ok("palindrome_yes", is_palindrome("abcba"), 1);
ok("palindrome_no", is_palindrome("abcde"), 0);
ok("palindrome_empty", is_palindrome(""), 1);

// 3.3 Count char occurrences
fn count_char(s, ch) {
    let c = 0; let i = 0;
    while i < len(s) {
        if char_at(s, i) == ch { let c = c + 1; };
        let i = i + 1;
    };
    return c;
};
ok("count_a", count_char("abracadabra", "a"), 5);

// ═══ 4. MATH PUZZLES ═══

// 4.1 Collatz conjecture (steps to reach 1)
fn collatz(n) {
    let steps = 0;
    while n != 1 {
        if n % 2 == 0 { let n = n / 2; } else { let n = 3 * n + 1; };
        let steps = steps + 1;
    };
    return steps;
};
ok("collatz(27)", collatz(27), 111);
ok("collatz(1)", collatz(1), 0);

// 4.2 Digital root (repeated digit sum until single digit)
fn digit_root(n) {
    while n >= 10 {
        let s = 0;
        while n > 0 { let s = s + n % 10; let n = __floor(n / 10); };
        let n = s;
    };
    return n;
};
ok("droot(493)", digit_root(493), 7);
ok("droot(99999)", digit_root(99999), 9);

// 4.3 Perfect number check (sum of divisors == n)
fn is_perfect(n) {
    let s = 0; let i = 1;
    while i < n {
        if n % i == 0 { let s = s + i; };
        let i = i + 1;
    };
    return s == n;
};
ok("perfect(6)", is_perfect(6), 1);
ok("perfect(28)", is_perfect(28), 1);
ok("perfect(12)", is_perfect(12), 0);

// ═══ 5. GRAPH/PATH ALGORITHMS ═══

// 5.1 Tower of Hanoi (count moves)
fn hanoi(n) { if n == 1 { return 1; }; return 2 * hanoi(n - 1) + 1; };
ok("hanoi(1)", hanoi(1), 1);
ok("hanoi(3)", hanoi(3), 7);
ok("hanoi(10)", hanoi(10), 1023);

// 5.2 Catalan number (recursive)
fn catalan(n) {
    if n <= 1 { return 1; };
    let c = 0; let i = 0;
    while i < n {
        let c = c + catalan(i) * catalan(n - 1 - i);
        let i = i + 1;
    };
    return c;
};
ok("catalan(0)", catalan(0), 1);
ok("catalan(4)", catalan(4), 14);
ok("catalan(5)", catalan(5), 42);

// ═══ 6. BITWISE OPERATIONS ═══

// 6.1 Count set bits (population count)
fn popcount(n) {
    let c = 0;
    while n > 0 {
        let c = c + __bit_and(n, 1);
        let n = __bit_shr(n, 1);
    };
    return c;
};
ok("popcount(255)", popcount(255), 8);
ok("popcount(1024)", popcount(1024), 1);
ok("popcount(7)", popcount(7), 3);

// 6.2 Is power of 2
fn is_pow2(n) {
    if n <= 0 { return 0; };
    return __bit_and(n, n - 1) == 0;
};
ok("pow2(64)", is_pow2(64), 1);
ok("pow2(100)", is_pow2(100), 0);

// 6.3 Next power of 2
fn next_pow2(n) {
    let p = 1;
    while p < n { let p = p * 2; };
    return p;
};
ok("npow2(5)", next_pow2(5), 8);
ok("npow2(1000)", next_pow2(1000), 1024);

// ═══ 7. SEQUENCE PUZZLES ═══

// 7.1 Tribonacci
fn trib(n) {
    if n == 0 { return 0; };
    if n <= 2 { return 1; };
    let a = 0; let b = 1; let c = 1; let i = 3;
    while i <= n {
        let t = a + b + c;
        let a = b; let b = c; let c = t;
        let i = i + 1;
    };
    return c;
};
ok("trib(7)", trib(7), 24);

// 7.2 Sum of squares
fn sum_sq(n) {
    let s = 0; let i = 1;
    while i <= n { let s = s + i * i; let i = i + 1; };
    return s;
};
ok("sumsq(10)", sum_sq(10), 385);

// 7.3 Triangular number
fn triangular(n) { return n * (n + 1) / 2; };
ok("tri(100)", triangular(100), 5050);

// ═══ 8. ARRAY ALGORITHMS ═══

// 8.1 Find max in array
fn arr_max(arr) {
    let m = __array_get(arr, 0); let i = 1;
    while i < len(arr) {
        let v = __array_get(arr, i);
        if v > m { let m = v; };
        let i = i + 1;
    };
    return m;
};

// 8.2 Array sum
fn arr_sum(arr) {
    let s = 0; let i = 0;
    while i < len(arr) { let s = s + __array_get(arr, i); let i = i + 1; };
    return s;
};

// 8.3 Generate + test with pseudo-random
fn prand(seed) { return __bit_and(seed * 2654435761 + 40503, 65535); };
let rdata = __array_with_cap(64);
let seed = 42;
let ri = 0;
while ri < 50 {
    let seed = prand(seed);
    push(rdata, seed % 1000);
    let ri = ri + 1;
};
ok("arr_max>0", arr_max(rdata) > 0, 1);
ok("arr_sum>0", arr_sum(rdata) > 0, 1);

// 8.4 Count unique (brute force)
fn count_unique(arr) {
    let c = 0; let i = 0;
    while i < len(arr) {
        let dup = 0; let j = 0;
        while j < i {
            if __array_get(arr, j) == __array_get(arr, i) { let dup = 1; };
            let j = j + 1;
        };
        if dup == 0 { let c = c + 1; };
        let i = i + 1;
    };
    return c;
};
ok("unique>=1", count_unique(rdata) >= 1, 1);

// ═══ 9. ENCODE/DECODE ═══

// 9.1 Hash consistency across 1000 strings
fn encode(text) {
    let h = 5381; let i = 0;
    while i < len(text) {
        let c = __char_code(char_at(text, i));
        let h = __bit_and(h * 33 + c, 65535);
        let i = i + 1;
    };
    return h;
};
let hash_ok = 1;
let hi = 0;
while hi < 100 {
    let s = "test" + __to_string(hi);
    let h1 = encode(s);
    let h2 = encode(s);
    if h1 != h2 { let hash_ok = 0; };
    let hi = hi + 1;
};
ok("hash_100_consistent", hash_ok, 1);

// 9.2 Mol roundtrip 100 random values
fn mol_pack(s, r, v, a, t) { return s * 4096 + r * 256 + v * 32 + a * 4 + t; };
fn mol_s(m) { return __floor(m / 4096) % 16; };
fn mol_r(m) { return __floor(m / 256) % 16; };
fn mol_v(m) { return __floor(m / 32) % 8; };
fn mol_a(m) { return __floor(m / 4) % 8; };
fn mol_t(m) { return m % 4; };
let mol_ok = 1;
let mi = 0;
let mseed = 777;
while mi < 100 {
    let mseed = prand(mseed);
    let s = mseed % 16;
    let r = __floor(mseed / 16) % 16;
    let v = __floor(mseed / 256) % 8;
    let a = __floor(mseed / 2048) % 8;
    let t = __floor(mseed / 16384) % 4;
    let m = mol_pack(s, r, v, a, t);
    if mol_s(m) != s { let mol_ok = 0; };
    if mol_r(m) != r { let mol_ok = 0; };
    if mol_v(m) != v { let mol_ok = 0; };
    if mol_a(m) != a { let mol_ok = 0; };
    if mol_t(m) != t { let mol_ok = 0; };
    let mi = mi + 1;
};
ok("mol_roundtrip_100", mol_ok, 1);

// ═══ REPORT ═══
let p = __array_get(pass, 0);
let f = __array_get(fail, 0);
emit "=== NOX CHALLENGE BOOK ===";
emit __to_string(p) + "/" + __to_string(p + f) + " challenges solved";
emit "1.NumberTheory 2.Sort/Search 3.Strings 4.MathPuzzles";
emit "5.Graph/Path 6.Bitwise 7.Sequences 8.Arrays 9.Encode/Decode";
if f == 0 { emit "RESULT: ALL SOLVED"; } else { emit "RESULT: " + __to_string(f) + " UNSOLVED"; };
