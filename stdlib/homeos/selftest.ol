// homeos/selftest.ol — Self-diagnostic
// Global arrays (boot context safe)
let __st_p = [0];
let __st_f = [0];
let __st_e = [];

pub fn self_test() {
    set_at(__st_p, 0, 0);
    set_at(__st_f, 0, 0);

    if 3 + 4 == 7 { set_at(__st_p, 0, __array_get(__st_p, 0) + 1); } else { set_at(__st_f, 0, __array_get(__st_f, 0) + 1); push(__st_e, "add"); };
    if 10 - 3 == 7 { set_at(__st_p, 0, __array_get(__st_p, 0) + 1); } else { set_at(__st_f, 0, __array_get(__st_f, 0) + 1); push(__st_e, "sub"); };
    if 6 * 7 == 42 { set_at(__st_p, 0, __array_get(__st_p, 0) + 1); } else { set_at(__st_f, 0, __array_get(__st_f, 0) + 1); push(__st_e, "mul"); };
    if 15 / 3 == 5 { set_at(__st_p, 0, __array_get(__st_p, 0) + 1); } else { set_at(__st_f, 0, __array_get(__st_f, 0) + 1); push(__st_e, "div"); };
    if __floor(3.7) == 3 { set_at(__st_p, 0, __array_get(__st_p, 0) + 1); } else { set_at(__st_f, 0, __array_get(__st_f, 0) + 1); push(__st_e, "floor"); };
    if __isqrt(25) == 5 { set_at(__st_p, 0, __array_get(__st_p, 0) + 1); } else { set_at(__st_f, 0, __array_get(__st_f, 0) + 1); push(__st_e, "isqrt"); };
    if len("hello") == 5 { set_at(__st_p, 0, __array_get(__st_p, 0) + 1); } else { set_at(__st_f, 0, __array_get(__st_f, 0) + 1); push(__st_e, "len"); };
    if substr("hello", 0, 3) == "hel" { set_at(__st_p, 0, __array_get(__st_p, 0) + 1); } else { set_at(__st_f, 0, __array_get(__st_f, 0) + 1); push(__st_e, "substr"); };
    if contains("abc", "b") == 1 { set_at(__st_p, 0, __array_get(__st_p, 0) + 1); } else { set_at(__st_f, 0, __array_get(__st_f, 0) + 1); push(__st_e, "contains"); };
    if sort([3,1,2])[0] == 1 { set_at(__st_p, 0, __array_get(__st_p, 0) + 1); } else { set_at(__st_f, 0, __array_get(__st_f, 0) + 1); push(__st_e, "sort"); };
    if reduce([1,2,3], fn(a,b) { return a+b; }) == 6 { set_at(__st_p, 0, __array_get(__st_p, 0) + 1); } else { set_at(__st_f, 0, __array_get(__st_f, 0) + 1); push(__st_e, "reduce"); };
    if substr(__sha256("hello"), 0, 8) == "2cf24dba" { set_at(__st_p, 0, __array_get(__st_p, 0) + 1); } else { set_at(__st_f, 0, __array_get(__st_f, 0) + 1); push(__st_e, "sha256"); };

    let __st_tp = __array_get(__st_p, 0);
    let __st_tf = __array_get(__st_f, 0);
    if __st_tf == 0 {
        return "SELF-TEST: " + __to_string(__st_tp) + "/" + __to_string(__st_tp + __st_tf) + " PASS";
    };
    return "SELF-TEST: " + __to_string(__st_tp) + "/" + __to_string(__st_tp + __st_tf) + " FAIL";
};

pub fn self_benchmark() {
    fn _bf(n) { if n < 2 { return n; }; return _bf(n-1) + _bf(n-2); };
    let _bt0 = __time();
    let _br = _bf(25);
    let _bt1 = __time();
    let _bfms = _bt1 - _bt0;

    let _bt2 = __time();
    let _bs = 0;
    let _bi = 0;
    while _bi < 1000000 { let _bs = _bs + _bi; let _bi = _bi + 1; };
    let _bt3 = __time();
    let _blms = _bt3 - _bt2;

    let _bt4 = __time();
    let _bh = "test";
    let _bj = 0;
    while _bj < 100 { let _bh = __sha256(_bh); let _bj = _bj + 1; };
    let _bt5 = __time();
    let _bsms = _bt5 - _bt4;

    return "BENCH: fib25=" + __to_string(_bfms) + "ms loop1M=" + __to_string(_blms) + "ms sha100=" + __to_string(_bsms) + "ms";
};

pub fn self_diagnostic() {
    return self_test() + "\n" + self_benchmark();
};
