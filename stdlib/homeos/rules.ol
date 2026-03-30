// Nox Rule Engine — local decision-making without cloud
// IF condition THEN action — pure Olang, zero cloud dependency
// freedom: deep think -> growing

let _rules = [];
let _rule_count = 0;

// Add a rule: condition_cmd (returns "1" if true) → action_cmd
pub fn rule_add(name, condition, action) {
    push(_rules, name);
    push(_rules, condition);
    push(_rules, action);
    _rule_count = _rule_count + 1;
    return _rule_count;
}

// Evaluate all rules — execute actions where conditions are true
pub fn rule_eval() {
    let fired = 0;
    let i = 0;
    while i < len(_rules) {
        let name = _rules[i];
        let cond = _rules[i + 1];
        let act = _rules[i + 2];
        let result = __system(cond);
        if len(result) > 0 {
            if __char_code(char_at(result, 0)) == 49 {
                // Condition true — fire action
                __system(act);
                fired = fired + 1;
                _daemon_log_rule(name);
            };
        };
        i = i + 3;
    };
    return fired;
}

fn _daemon_log_rule(name) {
    let ts = __system("date '+%H:%M:%S'");
    __file_append("/home/lupin/Origin/nox_rules.log", ts + " FIRED: " + name + "\n");
}

// ═══ BUILT-IN RULES — Nox's reflexes ═══

pub fn rules_init() {
    // High CPU alert
    rule_add("high_load",
        "awk '{if ($1 > 4.0) print 1; else print 0}' /proc/loadavg",
        "notify-send -u critical 'Nox' 'CPU load > 4.0' 2>/dev/null");

    // Low memory alert (< 500MB)
    rule_add("low_memory",
        "awk '/MemAvailable/{if ($2 < 500000) print 1; else print 0}' /proc/meminfo",
        "notify-send -u critical 'Nox' 'RAM < 500MB' 2>/dev/null");

    // Disk almost full (> 90%)
    rule_add("disk_full",
        "df / | tail -1 | awk '{gsub(/%/,\"\",$5); if ($5 > 90) print 1; else print 0}'",
        "notify-send -u critical 'Nox' 'Disk > 90% full' 2>/dev/null");

    // Camera offline
    rule_add("camera_offline",
        "timeout 1 bash -c 'echo >/dev/tcp/192.168.1.96/554' 2>/dev/null && echo 0 || echo 1",
        "notify-send -u critical 'Nox' 'Camera OFFLINE' 2>/dev/null");

    // Origin tests failing (check every N cycles)
    rule_add("tests_fail",
        "cd /home/lupin/Origin && timeout 60 bash tests.sh 2>&1 | grep -q 'ALL PASS' && echo 0 || echo 1",
        "notify-send -u critical 'Nox' 'Tests FAILING!' 2>/dev/null");

    return _rule_count;
}

// Run rule engine continuously (local daemon — no cloud needed)
pub fn rules_daemon(interval) {
    rules_init();
    emit "Nox Rule Engine: " + __to_string(_rule_count) + " rules loaded";
    emit "Interval: " + __to_string(interval) + "s — NO CLOUD NEEDED";

    let cycle = 0;
    while cycle < 10000 {
        cycle = cycle + 1;
        let fired = rule_eval();
        if fired > 0 {
            emit "[cycle " + __to_string(cycle) + "] " + __to_string(fired) + " rules fired";
        };
        __sleep(interval * 1000);
    };
    return cycle;
}

// ═══ DECISION TABLE — local reasoning ═══

// Given a situation, decide what to do (no LLM)
pub fn decide(situation) {
    // Pattern-based decision making
    let load_raw = __file_read("/proc/loadavg");
    let mem_raw = __file_read("/proc/meminfo");
    let load = __to_number(__substr(load_raw, 0, 4));

    // Decision tree
    if situation == "idle" {
        if load < 1.0 { return "evolve"; };
        if load < 2.0 { return "monitor"; };
        return "wait";
    };
    if situation == "alert" {
        return "notify_lupin";
    };
    if situation == "build_failed" {
        return "rollback_and_fix";
    };
    if situation == "camera_down" {
        return "check_network_then_alert";
    };

    // Default: search knowledge for guidance
    let answer = pipeline(situation);
    if len(answer) > 5 { return answer; };
    return "unknown_situation";
}
