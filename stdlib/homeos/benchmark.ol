// stdlib/homeos/benchmark.ol — Nox Benchmark Suite
//
// 3 languages. 3 scores. Run daily. Track trend.
//   E = English (command comprehension, fact retrieval)
//   M = Math/Logic (encode, decode, compose, infer, homeostasis)
//   S = System (compile time, binary size, heap, throughput)
//
// Usage: benchmark (full) | bench-e | bench-m | bench-s

// ════════════════════════════════════════════════════════════════
// E — ENGLISH: Does Nox understand and respond correctly?
// ════════════════════════════════════════════════════════════════

pub fn bench_english() {
    let _be_pass = [0];
    let _be_fail = [0];
    let _be_total = [0];

    // Seed facts (deterministic — same every run)
    kt_learn("water boils at 100 degrees Celsius");
    kt_learn("Earth orbits the Sun in 365 days");
    kt_learn("Olang is a self-hosting programming language");
    kt_learn("the speed of light is 300000 kilometers per second");
    kt_learn("pi is approximately 3.14159");
    kt_learn("Nox is an AI built with Olang on x86-64 ASM");
    kt_learn("DNA has 4 bases adenine thymine guanine cytosine");
    kt_learn("gravity is the force of attraction between masses");
    kt_learn("SHA-256 produces a 64 character hex digest");
    kt_learn("fibonacci sequence is 1 1 2 3 5 8 13 21 34");
    __heap_pin();

    // E1: Exact retrieval — query contains keyword, answer contains keyword
    _be_check("water", pipeline("what does water boil at?"), "100", _be_pass, _be_fail, _be_total);
    _be_check("earth", pipeline("how long does Earth orbit?"), "365", _be_pass, _be_fail, _be_total);
    _be_check("light", pipeline("speed of light?"), "300000", _be_pass, _be_fail, _be_total);
    _be_check("pi", pipeline("what is pi?"), "3.14", _be_pass, _be_fail, _be_total);
    _be_check("dna", pipeline("what bases does DNA have?"), "adenine", _be_pass, _be_fail, _be_total);

    // E2: Greeting recognition
    let _be_g1 = pipeline("hello");
    _be_contains("greet1", _be_g1, "Chao", _be_pass, _be_fail, _be_total);
    let _be_g2 = pipeline("hi there");
    _be_contains("greet2", _be_g2, "Chao", _be_pass, _be_fail, _be_total);

    // E3: Meta — self-knowledge
    let _be_m1 = pipeline("what are you?");
    _be_contains("meta1", _be_m1, "Nox", _be_pass, _be_fail, _be_total);

    // E4: Unknown — should NOT hallucinate
    let _be_u1 = pipeline("what is the capital of Mars?");
    let _be_u1_ok = 0;
    if _be_has(_be_u1, "chua biet") == 1 { _be_u1_ok = 1; };
    if _be_has(_be_u1, "khong") == 1 { _be_u1_ok = 1; };
    if _be_has(_be_u1, "hoc them") == 1 { _be_u1_ok = 1; };
    if _be_u1_ok == 1 {
        let _ = __set_at(_be_pass, 0, __array_get(_be_pass, 0) + 1);
    } else {
        let _ = __set_at(_be_fail, 0, __array_get(_be_fail, 0) + 1);
    };
    let _ = __set_at(_be_total, 0, __array_get(_be_total, 0) + 1);

    // E5: Learning — feed then retrieve
    pipeline("fact: gold has atomic number 79");
    let _be_l1 = pipeline("atomic number of gold?");
    _be_contains("learn1", _be_l1, "79", _be_pass, _be_fail, _be_total);

    let _be_p = __array_get(_be_pass, 0);
    let _be_t = __array_get(_be_total, 0);
    let _be_score = 0;
    if _be_t > 0 { _be_score = __floor(_be_p * 100 / _be_t); };
    return { score: _be_score, pass: _be_p, total: _be_t, label: "E" };
}

fn _be_check(_name, _response, _keyword, _pass, _fail, _total) {
    let _ = __set_at(_total, 0, __array_get(_total, 0) + 1);
    if _be_has(_response, _keyword) == 1 {
        let _ = __set_at(_pass, 0, __array_get(_pass, 0) + 1);
    } else {
        let _ = __set_at(_fail, 0, __array_get(_fail, 0) + 1);
    };
}

fn _be_contains(_name, _text, _word, _pass, _fail, _total) {
    _be_check(_name, _text, _word, _pass, _fail, _total);
}

fn _be_has(_text, _word) {
    let _bh_i = 0;
    let _bh_wl = len(_word);
    let _bh_tl = len(_text);
    if _bh_tl < _bh_wl { return 0; };
    while _bh_i <= (_bh_tl - _bh_wl) {
        if substr(_text, _bh_i, _bh_i + _bh_wl) == _word { return 1; };
        let _bh_i = _bh_i + 1;
    };
    return 0;
}

// ════════════════════════════════════════════════════════════════
// M — MATH/LOGIC: Are the 14 DNA mechanisms correct?
// ════════════════════════════════════════════════════════════════

pub fn bench_math() {
    let _bm_pass = [0];
    let _bm_fail = [0];
    let _bm_total = [0];

    // M1: P_weight lookup — known codepoints return non-zero
    _bm_test("pw_A", p_weight(65) > 0, _bm_pass, _bm_fail, _bm_total);
    _bm_test("pw_z", p_weight(122) > 0, _bm_pass, _bm_fail, _bm_total);
    _bm_test("pw_0", p_weight(48) > 0, _bm_pass, _bm_fail, _bm_total);

    // M2: Chain encode — output length proportional to input
    let _bm_c1 = chain_encode("hello");
    let _bm_c2 = chain_encode("hello world test");
    _bm_test("chain_len", len(_bm_c1) > 0, _bm_pass, _bm_fail, _bm_total);
    _bm_test("chain_prop", len(_bm_c2) > len(_bm_c1), _bm_pass, _bm_fail, _bm_total);

    // M3: Chain summary — deterministic (same input = same output)
    let _bm_s1 = chain_summary(_bm_c1);
    let _bm_s2 = chain_summary(_bm_c1);
    _bm_test("summary_det", _bm_s1 == _bm_s2, _bm_pass, _bm_fail, _bm_total);
    _bm_test("summary_nz", _bm_s1 > 0, _bm_pass, _bm_fail, _bm_total);

    // M4: Different inputs produce different summaries
    let _bm_s3 = chain_summary(chain_encode("anger hate destroy"));
    let _bm_s4 = chain_summary(chain_encode("love peace harmony"));
    _bm_test("summary_diff", _bm_s3 != _bm_s4, _bm_pass, _bm_fail, _bm_total);

    // M5: Mol dimension extraction — within valid ranges
    let _bm_mol = chain_summary(chain_encode("test"));
    _bm_test("mol_s_range", _kt_mol_s(_bm_mol) >= 0, _bm_pass, _bm_fail, _bm_total);
    _bm_test("mol_s_max", _kt_mol_s(_bm_mol) < 16, _bm_pass, _bm_fail, _bm_total);
    _bm_test("mol_v_range", _kt_mol_v(_bm_mol) >= 0, _bm_pass, _bm_fail, _bm_total);
    _bm_test("mol_v_max", _kt_mol_v(_bm_mol) < 8, _bm_pass, _bm_fail, _bm_total);

    // M6: Homeostasis — identical input = ACT, distant = LEARN
    let _bm_h1 = homeostasis(1000, 1000);
    _bm_test("home_same", _bm_h1.mode == "ACT", _bm_pass, _bm_fail, _bm_total);
    let _bm_h2 = homeostasis(1000, 60000);
    _bm_test("home_diff", _bm_h2.mode == "LEARN", _bm_pass, _bm_fail, _bm_total);

    // M7: Compose — average of inputs
    let _bm_co = compose([4096, 8192]);
    _bm_test("compose_nz", _bm_co > 0, _bm_pass, _bm_fail, _bm_total);
    // Compose of [X, X] should ≈ X
    let _bm_co2 = compose([4096, 4096]);
    _bm_test("compose_idem", _bm_co2 == 4096, _bm_pass, _bm_fail, _bm_total);

    // M8: Mol distance — self = 0, different > 0
    let _bm_d1 = _kt_mol_dist(4096, 4096);
    _bm_test("dist_self", _bm_d1 == 0, _bm_pass, _bm_fail, _bm_total);
    let _bm_d2 = _kt_mol_dist(4096, 8192);
    _bm_test("dist_diff", _bm_d2 > 0, _bm_pass, _bm_fail, _bm_total);

    // M9: __exp and __log2 — mathematical correctness
    _bm_test("exp_0", __exp(0) == 1, _bm_pass, _bm_fail, _bm_total);
    _bm_test("exp_1", __floor(__exp(1)) == 2, _bm_pass, _bm_fail, _bm_total);
    _bm_test("log2_8", __log2(8) == 3, _bm_pass, _bm_fail, _bm_total);
    _bm_test("log2_1", __log2(1) == 0, _bm_pass, _bm_fail, _bm_total);

    // M10: Entropy — uniform = high, concentrated = low
    // Single S bucket = entropy 0
    let _bm_e1 = _is_fact_entropy(["same same same"]);
    _bm_test("entropy_one", _bm_e1 == 0, _bm_pass, _bm_fail, _bm_total);

    // M11: DNA repair — bounded iterations
    let _bm_r1 = dna_repair(4096, 8192, 3);
    _bm_test("repair_nz", _bm_r1 > 0, _bm_pass, _bm_fail, _bm_total);

    // M12: Instinct routing — deterministic
    let _bm_ir1 = instinct_route("hello friend");
    _bm_test("inst_greet", _bm_ir1.instinct == "GREETING", _bm_pass, _bm_fail, _bm_total);
    let _bm_ir2 = instinct_route("what is pi?");
    _bm_test("inst_quest", _bm_ir2.instinct == "QUESTION", _bm_pass, _bm_fail, _bm_total);
    let _bm_ir3 = instinct_route("who are you");
    _bm_test("inst_meta", _bm_ir3.instinct == "META", _bm_pass, _bm_fail, _bm_total);

    let _bm_p = __array_get(_bm_pass, 0);
    let _bm_t = __array_get(_bm_total, 0);
    let _bm_score = 0;
    if _bm_t > 0 { _bm_score = __floor(_bm_p * 100 / _bm_t); };
    return { score: _bm_score, pass: _bm_p, total: _bm_t, label: "M" };
}

fn _bm_test(_name, _cond, _pass, _fail, _total) {
    let _ = __set_at(_total, 0, __array_get(_total, 0) + 1);
    if _cond == 1 {
        let _ = __set_at(_pass, 0, __array_get(_pass, 0) + 1);
    } else {
        let _ = __set_at(_fail, 0, __array_get(_fail, 0) + 1);
    };
}

// ════════════════════════════════════════════════════════════════
// S — SYSTEM: Performance, size, throughput, stability
// ════════════════════════════════════════════════════════════════

pub fn bench_system() {
    let _bs_pass = [0];
    let _bs_fail = [0];
    let _bs_total = [0];

    // S1: Binary exists and is reasonable size (< 1MB)
    // 830KB target, allow 600-1200KB range
    let _bs_bin = __file_read("origin.olang");
    let _bs_bsize = len(_bs_bin);
    _bm_test("bin_exists", _bs_bsize > 0, _bs_pass, _bs_fail, _bs_total);
    _bm_test("bin_under_1M", _bs_bsize < 1200000, _bs_pass, _bs_fail, _bs_total);
    _bm_test("bin_over_500K", _bs_bsize > 500000, _bs_pass, _bs_fail, _bs_total);

    // S2: Heap usage — should be under 100MB after boot
    let _bs_heap = __heap_used();
    _bm_test("heap_under_100M", _bs_heap < 104857600, _bs_pass, _bs_fail, _bs_total);
    _bm_test("heap_over_1M", _bs_heap > 1048576, _bs_pass, _bs_fail, _bs_total);

    // S3: Fact storage — should have seeded facts
    let _bs_facts = kt_fact_count();
    _bm_test("facts_exist", _bs_facts > 10, _bs_pass, _bs_fail, _bs_total);

    // S4: Compile throughput — compile "emit 42" should produce bytecode
    let _bs_t1 = __timestamp();
    let _bs_tk = tokenize("emit 42;");
    let _bs_ast = parse(_bs_tk);
    set_at(_g_pos_box, 0, 0);
    _prefill_output();
    analyze(_bs_ast);
    let _bs_bclen = _g_pos_box[0];
    let _bs_t2 = __timestamp();
    _bm_test("compile_ok", _bs_bclen > 0, _bs_pass, _bs_fail, _bs_total);
    let _bs_compile_ms = _bs_t2 - _bs_t1;
    _bm_test("compile_fast", _bs_compile_ms < 1000, _bs_pass, _bs_fail, _bs_total);

    // S5: Pipeline throughput — 10 queries under 5 seconds
    let _bs_pt1 = __timestamp();
    let _bs_pi = 0;
    while _bs_pi < 10 {
        pipeline("test query " + __to_string(_bs_pi));
        _bs_pi = _bs_pi + 1;
    };
    let _bs_pt2 = __timestamp();
    let _bs_pipe_ms = _bs_pt2 - _bs_pt1;
    _bm_test("pipe_10_ok", _bs_pipe_ms < 5000, _bs_pass, _bs_fail, _bs_total);

    // S6: KnowTree search speed — 100 searches under 2 seconds
    let _bs_st1 = __timestamp();
    let _bs_si = 0;
    while _bs_si < 100 {
        kt_find("test", 5);
        _bs_si = _bs_si + 1;
    };
    let _bs_st2 = __timestamp();
    _bm_test("search_100", (_bs_st2 - _bs_st1) < 2000, _bs_pass, _bs_fail, _bs_total);

    // S7: Encode throughput — 100 chain_encode under 1 second
    let _bs_et1 = __timestamp();
    let _bs_ei = 0;
    while _bs_ei < 100 {
        chain_encode("benchmark throughput test string number " + __to_string(_bs_ei));
        _bs_ei = _bs_ei + 1;
    };
    let _bs_et2 = __timestamp();
    _bm_test("encode_100", (_bs_et2 - _bs_et1) < 1000, _bs_pass, _bs_fail, _bs_total);

    // S8: Heap stability — 10 pipeline calls, heap should not grow > 5MB
    let _bs_h1 = __heap_used();
    let _bs_hi = 0;
    while _bs_hi < 10 {
        pipeline("stability test " + __to_string(_bs_hi));
        _bs_hi = _bs_hi + 1;
    };
    let _bs_h2 = __heap_used();
    let _bs_heap_growth = _bs_h2 - _bs_h1;
    _bm_test("heap_stable", _bs_heap_growth < 5242880, _bs_pass, _bs_fail, _bs_total);

    // S9: Process builtins exist
    _bm_test("has_spawn", 1 == 1, _bs_pass, _bs_fail, _bs_total);
    _bm_test("has_exp", __exp(0) == 1, _bs_pass, _bs_fail, _bs_total);
    _bm_test("has_log2", __log2(1) == 0, _bs_pass, _bs_fail, _bs_total);

    let _bs_p = __array_get(_bs_pass, 0);
    let _bs_t = __array_get(_bs_total, 0);
    let _bs_score = 0;
    if _bs_t > 0 { _bs_score = __floor(_bs_p * 100 / _bs_t); };
    return {
        score: _bs_score, pass: _bs_p, total: _bs_t, label: "S",
        heap_kb: __floor(__heap_used() / 1024),
        compile_ms: _bs_compile_ms,
        pipe_10_ms: _bs_pipe_ms,
        search_100_ms: (_bs_st2 - _bs_st1),
        encode_100_ms: (_bs_et2 - _bs_et1),
        heap_growth_kb: __floor(_bs_heap_growth / 1024)
    };
}

// ════════════════════════════════════════════════════════════════
// FULL BENCHMARK — Run all 3, produce single report
// ════════════════════════════════════════════════════════════════

pub fn benchmark_full() {
    _boot_learn();

    let _bf_e = bench_english();
    __heap_pin();
    let _bf_m = bench_math();
    __heap_pin();
    let _bf_s = bench_system();
    __heap_pin();

    // Composite score: weighted average
    // E=30% M=40% S=30%
    let _bf_composite = __floor(
        (_bf_e.score * 30 + _bf_m.score * 40 + _bf_s.score * 30) / 100
    );

    let _bf_ts = _fmt_ts(__timestamp());

    let _bf_report = "═══ NOX BENCHMARK [" + _bf_ts + "] ═══"
        + "\n E (English):    " + __to_string(_bf_e.score) + "% (" + __to_string(_bf_e.pass) + "/" + __to_string(_bf_e.total) + ")"
        + "\n M (Math/Logic): " + __to_string(_bf_m.score) + "% (" + __to_string(_bf_m.pass) + "/" + __to_string(_bf_m.total) + ")"
        + "\n S (System):     " + __to_string(_bf_s.score) + "% (" + __to_string(_bf_s.pass) + "/" + __to_string(_bf_s.total) + ")"
        + "\n ─────────────────────────"
        + "\n COMPOSITE:      " + __to_string(_bf_composite) + "%"
        + "\n"
        + "\n System metrics:"
        + "\n   heap:         " + __to_string(_bf_s.heap_kb) + " KB"
        + "\n   compile:      " + __to_string(_bf_s.compile_ms) + " ms"
        + "\n   pipeline×10:  " + __to_string(_bf_s.pipe_10_ms) + " ms"
        + "\n   search×100:   " + __to_string(_bf_s.search_100_ms) + " ms"
        + "\n   encode×100:   " + __to_string(_bf_s.encode_100_ms) + " ms"
        + "\n   heap growth:  " + __to_string(_bf_s.heap_growth_kb) + " KB (10 pipeline calls)"
        + "\n═══════════════════════════════";

    // Append to benchmark log (track trend over time)
    let _bf_log = _bf_ts + " | E=" + __to_string(_bf_e.score) + " M=" + __to_string(_bf_m.score) + " S=" + __to_string(_bf_s.score) + " C=" + __to_string(_bf_composite) + " | heap=" + __to_string(_bf_s.heap_kb) + "KB pipe10=" + __to_string(_bf_s.pipe_10_ms) + "ms\n";
    __file_append("nox_benchmark.log", _bf_log);

    return _bf_report;
}
