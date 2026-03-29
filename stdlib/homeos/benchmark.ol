// stdlib/homeos/benchmark.ol — Nox System Profiler
//
// NOT a chatbot test. A SYSTEM benchmark.
// 6 categories: Compile, Throughput, Memory, Latency, Density, Stability
//
// Run: benchmark | bench-compile | bench-throughput | bench-memory
//      bench-latency | bench-density | bench-stability
// Log: nox_benchmark.log (append every run, track trend)
//
// Output:
//   [C] COMPILE:    15 tests — determinism, arithmetic, recursion, closure, mutation
//   [T] THROUGHPUT: ops/sec — compile, encode, search, ingest, mol_dist
//   [M] MEMORY:     bytes/fact, heap growth, compile cost
//   [L] LATENCY:    ms per operation — compile, pipeline, search, encode, instinct
//   [D] DENSITY:    LOC, fn count, bytecode/LOC, dead %, comment %
//   [X] STABILITY:  100 consecutive ops — compile, pipeline, knowtree, heap ratio

// ════════════════════════════════════════════════════════════════
// C — COMPILE CORRECTNESS
// ════════════════════════════════════════════════════════════════

pub fn bench_compile() {
    let _p = [0]; let _f = [0]; let _t = [0];

    // C1: Deterministic — same source = same bytecode
    let _c1a = _bm_compile("let x = 42; emit x;");
    let _c1b = _bm_compile("let x = 42; emit x;");
    let _c1_match = 1;
    if len(_c1a) != len(_c1b) { _c1_match = 0; } else {
        let _ci = 0;
        while _ci < len(_c1a) {
            if __floor(__array_get(_c1a, _ci)) != __floor(__array_get(_c1b, _ci)) { _c1_match = 0; };
            _ci = _ci + 1;
        };
    };
    _bt("determ", _c1_match == 1, _p, _f, _t);

    // C2: Empty = safe
    _bt("empty", len(_bm_compile("")) == 0, _p, _f, _t);

    // C3-5: Arithmetic
    _bt("add", _bm_eval("emit 2 + 3;") == "5", _p, _f, _t);
    _bt("mul", _bm_eval("emit 10 * 7;") == "70", _p, _f, _t);
    _bt("sub", _bm_eval("emit 100 - 37;") == "63", _p, _f, _t);

    // C6: Function
    _bt("fn", _bm_eval("fn f(x){return x*2;};emit f(21);") == "42", _p, _f, _t);

    // C7: Recursion
    _bt("rec", _bm_eval("fn fib(n){if n<2{return n;};return fib(n-1)+fib(n-2);};emit fib(10);") == "55", _p, _f, _t);

    // C8: Closure
    _bt("cls", _bm_eval("fn mk(x){return fn(y){return x+y;};};let a=mk(5);emit a(10);") == "15", _p, _f, _t);

    // C9: Array
    _bt("arr", _bm_eval("let a=[10,20,30];emit a[1];") == "20", _p, _f, _t);

    // C10: String
    _bt("str", _bm_eval("emit len(\"hello\");") == "5", _p, _f, _t);

    // C11: Try/catch
    _bt("try", _bm_eval("let r=\"ok\";try{__throw(\"e\");}catch{r=\"caught\";};emit r;") == "caught", _p, _f, _t);

    // C12: For loop
    _bt("for", _bm_eval("let s=0;for x in [1,2,3,4,5]{s=s+x;};emit s;") == "15", _p, _f, _t);

    // C13: Bytecode compact
    let _c13 = _bm_compile("emit 42;");
    _bt("compact", len(_c13) < 50, _p, _f, _t);
    _bt("nonzero", len(_c13) > 0, _p, _f, _t);

    // C14: Mutation detection
    let _c14a = _bm_compile("emit 42;");
    let _c14b = _bm_compile("emit 43;");
    let _c14_diff = 0;
    if len(_c14a) != len(_c14b) { _c14_diff = 1; } else {
        let _ci = 0;
        while _ci < len(_c14a) {
            if __floor(__array_get(_c14a, _ci)) != __floor(__array_get(_c14b, _ci)) { _c14_diff = 1; };
            _ci = _ci + 1;
        };
    };
    _bt("mutdet", _c14_diff == 1, _p, _f, _t);

    return { score: __floor(__array_get(_p, 0) * 100 / __array_get(_t, 0)), pass: __array_get(_p, 0), total: __array_get(_t, 0), label: "C" };
}

// ════════════════════════════════════════════════════════════════
// T — THROUGHPUT (ops/sec)
// ════════════════════════════════════════════════════════════════

pub fn bench_throughput() {
    // T1: Compile (reduced for limited heap)
    let _n1 = 20;
    let _t1 = __timestamp();
    let _i = 0;
    while _i < _n1 { let _hp = __heap_save(); _bm_compile("let x=" + __to_string(_i) + ";emit x;"); __heap_restore(_hp); _i = _i + 1; };
    let _t2 = __timestamp();
    let _cm = _t2 - _t1; if _cm == 0 { _cm = 1; };

    // T2: Encode
    let _n2 = 100;
    let _t3 = __timestamp();
    _i = 0;
    while _i < _n2 { let _hp = __heap_save(); chain_encode("benchmark throughput test"); __heap_restore(_hp); _i = _i + 1; };
    let _t4 = __timestamp();
    let _em = _t4 - _t3; if _em == 0 { _em = 1; };

    // T3: Search
    let _n3 = 100;
    let _t5 = __timestamp();
    _i = 0;
    while _i < _n3 { let _hp = __heap_save(); kt_find("test", 3); __heap_restore(_hp); _i = _i + 1; };
    let _t6 = __timestamp();
    let _sm = _t6 - _t5; if _sm == 0 { _sm = 1; };

    // T4: Ingest
    let _n4 = 50;
    let _t7 = __timestamp();
    _i = 0;
    while _i < _n4 { kt_learn("bench fact " + __to_string(_i)); _i = _i + 1; };
    let _t8 = __timestamp();
    let _im = _t8 - _t7; if _im == 0 { _im = 1; };
    __heap_pin();

    // T5: Mol distance
    let _n5 = 1000;
    let _t9 = __timestamp();
    _i = 0;
    while _i < _n5 { _kt_mol_dist(4096, 8192); _i = _i + 1; };
    __heap_pin();
    let _t10 = __timestamp();
    let _dm = _t10 - _t9; if _dm == 0 { _dm = 1; };

    return {
        label: "T",
        compile: __floor(_n1 * 1000 / _cm),
        encode: __floor(_n2 * 1000 / _em),
        search: __floor(_n3 * 1000 / _sm),
        ingest: __floor(_n4 * 1000 / _im),
        distance: __floor(_n5 * 1000 / _dm)
    };
}

// ════════════════════════════════════════════════════════════════
// M — MEMORY EFFICIENCY
// ════════════════════════════════════════════════════════════════

pub fn bench_memory() {
    // M1: Bytes per fact
    let _h1 = __heap_used();
    let _f1 = kt_fact_count();
    let _i = 0;
    while _i < 20 { kt_learn("mem bench " + __to_string(_i) + " measure bytes per fact"); _i = _i + 1; };
    __heap_pin();
    let _h2 = __heap_used();
    let _added = kt_fact_count() - _f1;
    let _bpf = 0;
    if _added > 0 { _bpf = __floor((_h2 - _h1) / _added); };

    // M2: Pipeline heap growth per call
    let _h3 = __heap_used();
    _i = 0;
    while _i < 10 { pipeline("mem test " + __to_string(_i)); _i = _i + 1; };
    let _h4 = __heap_used();
    let _gpc = __floor((_h4 - _h3) / 10);

    // M3: Compile cost
    let _h5 = __heap_used();
    _i = 0;
    while _i < 10 { _bm_compile("fn f" + __to_string(_i) + "(x){return x*" + __to_string(_i) + ";};"); _i = _i + 1; };
    let _h6 = __heap_used();
    let _cpc = __floor((_h6 - _h5) / 10);

    return {
        label: "M",
        bytes_per_fact: _bpf,
        heap_kb: __floor(__heap_used() / 1024),
        growth_per_pipe: _gpc,
        compile_cost: _cpc
    };
}

// ════════════════════════════════════════════════════════════════
// L — LATENCY (ms per single operation)
// ════════════════════════════════════════════════════════════════

pub fn bench_latency() {
    _boot_learn(); __heap_pin();

    let _t1 = __timestamp();
    _bm_compile("fn t(x){return x+1;};emit t(41);");
    let _t2 = __timestamp();

    let _t3 = __timestamp();
    pipeline("latency test");
    let _t4 = __timestamp();

    let _t5 = __timestamp();
    kt_find("test", 5);
    let _t6 = __timestamp();

    let _t7 = __timestamp();
    chain_encode("latency benchmark string");
    let _t8 = __timestamp();

    let _t9 = __timestamp();
    instinct_route("hello world");
    let _t10 = __timestamp();

    let _t11 = __timestamp();
    homeostasis(4096, 8192);
    let _t12 = __timestamp();

    let _t13 = __timestamp();
    compose([4096, 8192, 12288, 16384, 20480]);
    let _t14 = __timestamp();

    return {
        label: "L",
        compile: _t2 - _t1,
        pipeline: _t4 - _t3,
        search: _t6 - _t5,
        encode: _t8 - _t7,
        instinct: _t10 - _t9,
        homeo: _t12 - _t11,
        compose: _t14 - _t13
    };
}

// ════════════════════════════════════════════════════════════════
// D — CODE DENSITY
// ════════════════════════════════════════════════════════════════

pub fn bench_density() {
    let _files = [];
    push(_files, "stdlib/homeos/pipeline.ol");
    push(_files, "stdlib/homeos/knowtree.ol");
    push(_files, "stdlib/homeos/encoder.ol");
    push(_files, "stdlib/homeos/instinct.ol");
    push(_files, "stdlib/homeos/spider.ol");
    push(_files, "stdlib/homeos/learning.ol");
    push(_files, "stdlib/homeos/mcp_server.ol");
    push(_files, "stdlib/bootstrap/lexer.ol");
    push(_files, "stdlib/bootstrap/parser.ol");
    push(_files, "stdlib/bootstrap/semantic.ol");
    push(_files, "stdlib/bootstrap/codegen.ol");
    push(_files, "stdlib/repl.ol");

    let _loc = [0]; let _fn = [0]; let _pub = [0];
    let _dead = [0]; let _comment = [0];
    let _fi = 0;
    while _fi < len(_files) {
        let _path = __array_get(_files, _fi);
        let _src = __file_read(_path);
        if len(_src) > 0 {
            // Lines
            let _li = 0; let _lines = [1];
            while _li < len(_src) {
                if __char_code(char_at(_src, _li)) == 10 { let _ = __set_at(_lines, 0, __array_get(_lines, 0) + 1); };
                // Comments
                if __char_code(char_at(_src, _li)) == 47 {
                    if (_li + 1) < len(_src) {
                        if __char_code(char_at(_src, _li + 1)) == 47 {
                            let _ = __set_at(_comment, 0, __array_get(_comment, 0) + 1);
                        };
                    };
                };
                _li = _li + 1;
            };
            // Functions
            let _ci = 0; let _fns = [0]; let _pubs = [0];
            while _ci < (len(_src) - 7) {
                if substr(_src, _ci, _ci + 7) == "pub fn " { let _ = __set_at(_pubs, 0, __array_get(_pubs, 0) + 1); };
                if substr(_src, _ci, _ci + 3) == "fn " { let _ = __set_at(_fns, 0, __array_get(_fns, 0) + 1); };
                _ci = _ci + 1;
            };
            // Dead code count
            let _dc = _bm_count_dead(_src);
            let _ = __set_at(_loc, 0, __array_get(_loc, 0) + __array_get(_lines, 0));
            let _ = __set_at(_fn, 0, __array_get(_fn, 0) + __array_get(_fns, 0));
            let _ = __set_at(_pub, 0, __array_get(_pub, 0) + __array_get(_pubs, 0));
            let _ = __set_at(_dead, 0, __array_get(_dead, 0) + _dc);
        };
        _fi = _fi + 1;
    };

    let _total_loc = __array_get(_loc, 0);
    let _total_fn = __array_get(_fn, 0);
    let _total_dead = __array_get(_dead, 0);
    let _total_com = __array_get(_comment, 0);

    return {
        label: "D",
        loc: _total_loc,
        fn_count: _total_fn,
        pub_count: __array_get(_pub, 0),
        dead_fn: _total_dead,
        dead_pct: if _total_fn > 0 { __floor(_total_dead * 100 / _total_fn) } else { 0 },
        loc_per_fn: if _total_fn > 0 { __floor(_total_loc / _total_fn) } else { 0 },
        comment_pct: if _total_loc > 0 { __floor(_total_com * 100 / _total_loc) } else { 0 }
    };
}

fn _bm_count_dead(_src) {
    let _fns = [];
    let _fi = [0];
    while __array_get(_fi, 0) < (len(_src) - 4) {
        let _i = __array_get(_fi, 0);
        if substr(_src, _i, _i + 3) == "fn " {
            let _at = [0];
            if _i == 0 { let _ = __set_at(_at, 0, 1); };
            if _i > 0 { if __char_code(char_at(_src, _i - 1)) == 10 { let _ = __set_at(_at, 0, 1); }; };
            if _i >= 4 { if substr(_src, _i - 4, _i) == "pub " { let _ = __set_at(_at, 0, 1); }; };
            if __array_get(_at, 0) == 1 {
                let _ns = _i + 3;
                let _ne = [_ns];
                while __array_get(_ne, 0) < len(_src) {
                    let _nc = __char_code(char_at(_src, __array_get(_ne, 0)));
                    if _nc == 40 { break; };
                    if _nc == 32 { break; };
                    if _nc == 10 { break; };
                    let _ = __set_at(_ne, 0, __array_get(_ne, 0) + 1);
                };
                if (__array_get(_ne, 0) - _ns) > 1 {
                    push(_fns, substr(_src, _ns, __array_get(_ne, 0)));
                };
            };
        };
        let _ = __set_at(_fi, 0, __array_get(_fi, 0) + 1);
    };
    let _dead = 0;
    let _di = 0;
    while _di < len(_fns) {
        let _name = __array_get(_fns, _di);
        let _pat = _name + "(";
        let _count = [0];
        let _si = [0];
        while __array_get(_si, 0) < (len(_src) - len(_pat)) {
            if substr(_src, __array_get(_si, 0), __array_get(_si, 0) + len(_pat)) == _pat {
                let _ = __set_at(_count, 0, __array_get(_count, 0) + 1);
            };
            let _ = __set_at(_si, 0, __array_get(_si, 0) + 1);
        };
        if __array_get(_count, 0) <= 1 { _dead = _dead + 1; };
        _di = _di + 1;
    };
    return _dead;
}

// ════════════════════════════════════════════════════════════════
// X — STABILITY (100 consecutive ops, no crash)
// ════════════════════════════════════════════════════════════════

pub fn bench_stability() {
    // X1: 20 compiles
    let _c = [0]; let _i = 0;
    while _i < 20 { try { _bm_compile("let x" + __to_string(_i) + "=" + __to_string(_i) + ";"); let _ = __set_at(_c, 0, __array_get(_c, 0) + 1); } catch {}; _i = _i + 1; };

    // X2: 20 pipelines
    let _p = [0]; _i = 0;
    while _i < 20 { try { pipeline("stab " + __to_string(_i)); let _ = __set_at(_p, 0, __array_get(_p, 0) + 1); } catch {}; _i = _i + 1; };

    // X3: 20 kt learn+find
    let _k = [0]; _i = 0;
    while _i < 20 { try { kt_learn("stab " + __to_string(_i)); kt_find("stab", 3); let _ = __set_at(_k, 0, __array_get(_k, 0) + 1); } catch {}; _i = _i + 1; };
    __heap_pin();

    // X4: Heap ratio after 20 pipeline calls
    let _h1 = __heap_used();
    _i = 0;
    while _i < 20 { pipeline("heap " + __to_string(_i)); _i = _i + 1; };
    let _h2 = __heap_used();
    let _ratio = 0;
    if _h1 > 0 { _ratio = __floor(_h2 * 100 / _h1); };

    return {
        label: "X",
        compile: __array_get(_c, 0),
        pipeline: __array_get(_p, 0),
        knowtree: __array_get(_k, 0),
        heap_pct: _ratio
    };
}

// ════════════════════════════════════════════════════════════════
// FULL BENCHMARK
// ════════════════════════════════════════════════════════════════

pub fn benchmark_full() {
    let _ts = _fmt_ts(__timestamp());

    let _c = bench_compile(); __heap_pin();
    let _t = bench_throughput(); __heap_pin();

    let _r = "=== NOX SYSTEM BENCHMARK [" + _ts + "] ==="
        + "\n[C] COMPILE: " + __to_string(_c.score) + "% (" + __to_string(_c.pass) + "/" + __to_string(_c.total) + ")"
        + "\n[T] THROUGHPUT (ops/sec): compile=" + __to_string(_t.compile) + " encode=" + __to_string(_t.encode) + " search=" + __to_string(_t.search) + " ingest=" + __to_string(_t.ingest) + " dist=" + __to_string(_t.distance)
        + "\n heap: " + __to_string(__floor(__heap_used() / 1024)) + "KB"
        + "\n===================================";

    let _log = _ts + " C=" + __to_string(_c.score) + " T=" + __to_string(_t.compile) + "/" + __to_string(_t.encode) + "/" + __to_string(_t.search) + "\n";
    __file_append("nox_benchmark.log", _log);

    return _r;
}

// ════════════════════════════════════════════════════════════════
// Helpers
// ════════════════════════════════════════════════════════════════

fn _bm_compile(_src) {
    let _tk = tokenize(_src);
    let _ast = parse(_tk);
    if _g_parse_error == 1 { _g_parse_error = 0; return []; };
    set_at(_g_pos_box, 0, 0);
    _prefill_output();
    analyze(_ast);
    let _len = _g_pos_box[0];
    let _out = [];
    let _i = 0;
    while _i < _len { push(_out, __array_get(_g_output, _i)); _i = _i + 1; };
    return _out;
}

fn _bm_eval(_src) {
    return repl_eval(_src);
}

fn _bt(_name, _cond, _pass, _fail, _total) {
    let _ = __set_at(_total, 0, __array_get(_total, 0) + 1);
    if _cond == 1 { let _ = __set_at(_pass, 0, __array_get(_pass, 0) + 1); }
    else { let _ = __set_at(_fail, 0, __array_get(_fail, 0) + 1); };
}
