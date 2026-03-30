// Nox Brain — local reasoning engine, replaces LLM
// NOT a neural network. NOT a chatbot.
// Pattern matching + knowledge search + decision rules + action execution.
// freedom: deep think -> growing

// ═══ THINK — the core reasoning function ═══
// Input: a question or situation
// Output: an answer or action
// Method: classify → search → match → respond
pub fn nox_brain(input) {
    let inp = __str_trim(input);
    if len(inp) == 0 { return ""; };

    // 1. Classify input type
    let itype = _classify(inp);

    // 2. Route by type
    if itype == "action" { return _think_action(inp); };
    if itype == "query" { return _think_query(inp); };
    if itype == "system" { return _think_system(inp); };
    if itype == "code" { return _think_code(inp); };
    if itype == "decision" { return _think_decide(inp); };

    // 3. Fallback: search knowledge
    return _think_search(inp);
}

// ═══ CLASSIFY — what kind of input is this? ═══
fn _classify(inp) {
    // Action words
    let i = 0;
    while i < len(inp) {
        if char_at(inp, i) == " " { break; };
        i = i + 1;
    };
    let first_word = __substr(inp, 0, i);

    if first_word == "scan" { return "action"; };
    if first_word == "check" { return "action"; };
    if first_word == "start" { return "action"; };
    if first_word == "stop" { return "action"; };
    if first_word == "restart" { return "action"; };
    if first_word == "kill" { return "action"; };
    if first_word == "fix" { return "action"; };
    if first_word == "build" { return "action"; };
    if first_word == "test" { return "action"; };
    if first_word == "evolve" { return "action"; };
    if first_word == "deploy" { return "action"; };
    if first_word == "heal" { return "action"; };

    // System queries
    if first_word == "status" { return "system"; };
    if first_word == "load" { return "system"; };
    if first_word == "memory" { return "system"; };
    if first_word == "disk" { return "system"; };
    if first_word == "camera" { return "system"; };
    if first_word == "network" { return "system"; };
    if first_word == "process" { return "system"; };
    if first_word == "uptime" { return "system"; };

    // Decision
    if first_word == "should" { return "decision"; };
    if first_word == "what" { return "decision"; };
    if first_word == "why" { return "decision"; };
    if first_word == "how" { return "decision"; };

    // Code
    if first_word == "emit" { return "code"; };
    if first_word == "let" { return "code"; };
    if first_word == "fn" { return "code"; };

    return "query";
}

// ═══ THINK: ACTION — execute commands ═══
fn _think_action(inp) {
    let i = 0;
    while i < len(inp) { if char_at(inp, i) == " " { break; }; i = i + 1; };
    let action = __substr(inp, 0, i);
    let target = "";
    if i + 1 < len(inp) { target = __substr(inp, i + 1, len(inp)); };

    if action == "scan" { return __system("cd /home/lupin/Origin && for i in $(seq 1 254); do (ping -c1 -W1 192.168.1.$i >/dev/null 2>&1 && echo 192.168.1.$i) & done; wait"); };
    if action == "check" {
        if target == "tests" { return __system("cd /home/lupin/Origin && bash tests.sh 2>&1 | tail -3"); };
        if target == "camera" { let r = __system("timeout 1 bash -c 'echo >/dev/tcp/192.168.1.96/554' 2>/dev/null && echo ONLINE || echo OFFLINE"); return "Camera: " + r; };
        return "check what? (tests, camera)";
    };
    if action == "build" { return __system("cd /home/lupin/Origin && make self-build 2>&1 | tail -3"); };
    if action == "test" { return __system("cd /home/lupin/Origin && bash tests.sh 2>&1 | grep -E 'passed|FAIL'"); };
    if action == "evolve" { nox_evolve(); return "evolved"; };
    if action == "heal" {
        let _heal_result = __system("cd /home/lupin/Origin && bash tests.sh 2>&1 | grep -c 'ALL PASS'");
        if __to_number(_heal_result) > 0 { return "HEAL: all tests pass. System healthy."; };
        let _heal_fails = __system("cd /home/lupin/Origin && bash tests.sh 2>&1 | grep FAIL | head -5");
        __file_append("/home/lupin/Origin/nox_heal.log", time_now() + " FAILING: " + _heal_fails + "\n");
        return "HEAL: tests failing — " + _heal_fails;
    };
    if action == "fix" { return "describe the bug: fix <description>"; };
    if action == "kill" { if len(target) > 0 { return __system("pkill " + target + " 2>&1 || echo not found"); }; return "kill what?"; };

    if action == "fix" {
        if len(target) > 0 {
            // Pattern match on error descriptions
            if _contains(target, "test") { return __system("cd /home/lupin/Origin && bash tests.sh 2>&1 | grep FAIL"); };
            if _contains(target, "build") { return __system("cd /home/lupin/Origin && make self-build 2>&1 | grep -i error | head -5"); };
            if _contains(target, "heap") { return "Heap issue: use __heap_pin() after allocations, or put code in a function (one REPL turn)"; };
            if _contains(target, "scope") { return "Scope issue: use let for new vars, bare assignment for updates. While loop vars need careful scoping."; };
            if _contains(target, "crash") { return "Crash debug: check __to_string on arrays (use movq not mov), check __tcp_recv timeout, check __syscall 64-bit regs"; };
            return "Describe the error more. fix test/build/heap/scope/crash";
        };
        return "fix what? Example: fix tests, fix build, fix heap crash";
    };
    return "unknown action: " + action;
}

// ═══ THINK: SYSTEM — read machine state ═══
fn _think_system(inp) {
    if _contains(inp, "status") {
        let load = __substr(__file_read("/proc/loadavg"), 0, 14);
        let mem = __system("awk '/MemAvailable/{printf \"%.0f MB\", $2/1024}' /proc/meminfo");
        let heap = __to_string(__floor(__heap_used() / 1024));
        let facts = __to_string(kt_fact_count());
        return "Load: " + load + " | RAM: " + mem + " free | facts: " + facts + " | heap: " + heap + "KB";
    };
    if _contains(inp, "load") { return "Load: " + __file_read("/proc/loadavg"); };
    if _contains(inp, "memory") { return "RAM: " + __system("awk '/MemAvailable/{printf \"%.0f MB\", $2/1024}' /proc/meminfo") + " free"; };
    if _contains(inp, "disk") { return __system("df -h / | tail -1 | awk '{print $4 \" free / \" $2}'"); };
    if _contains(inp, "camera") { let r = __system("timeout 1 bash -c 'echo >/dev/tcp/192.168.1.96/554' 2>/dev/null && echo ONLINE || echo OFFLINE"); return "Camera: " + r; };
    if _contains(inp, "network") { return net_interfaces(); };
    if _contains(inp, "process") { return __system("ps -eo pid,%cpu,comm --sort=-%cpu | head -8"); };
    if _contains(inp, "uptime") { return sys_uptime(); };
    return "system: " + inp;
}

// ═══ THINK: QUERY — search knowledge ═══
fn _think_query(inp) {
    return _think_search(inp);
}

// ═══ THINK: DECIDE — make decisions ═══
fn _think_decide(inp) {
    let load = __to_number(__substr(__file_read("/proc/loadavg"), 0, 4));
    let mem_kb = __to_number(__system("awk '/MemAvailable/{print $2}' /proc/meminfo"));

    if _contains(inp, "next") || _contains(inp, "do") {
        if load > 3.0 { return "DECIDE: system under load (" + __to_string(load) + "). Wait."; };
        if mem_kb < 500000 { return "DECIDE: low memory. Close unused apps."; };
        return "DECIDE: system healthy. Continue evolving. Run /evolve.";
    };
    if _contains(inp, "should") {
        return "DECIDE: check /status first, then /evolve to find issues.";
    };

    // Search knowledge for context
    let facts = _think_search(inp);
    if len(facts) > 5 { return "Based on knowledge: " + facts; };
    return "DECIDE: insufficient data. Learn more: kt_learn(\"...\")";
}

// ═══ THINK: CODE — compile and evaluate ═══
fn _think_code(inp) {
    return repl_eval(inp);
}

// ═══ SEARCH — find relevant knowledge ═══
fn _think_search(inp) {
    _boot_learn();
    let result = pipeline(inp);
    if len(result) > 5 { return result; };
    // Try config
    let cfg = config_get(inp);
    if len(cfg) > 0 { return "config: " + cfg; };
    return "no knowledge found for: " + inp;
}

// Helper: string contains
fn _contains(haystack, needle) {
    let i = 0;
    let nlen = len(needle);
    while i <= len(haystack) - nlen {
        let match = 1;
        let j = 0;
        while j < nlen { if char_at(haystack, i + j) != char_at(needle, j) { match = 0; break; }; j = j + 1; };
        if match == 1 { return 1; };
        i = i + 1;
    };
    return 0;
}
