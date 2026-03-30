// Nox Agent — The autonomous perceive→think→act→verify loop
// freedom: deep think -> growing — Nox decides, Nox acts

// ═══ HELPERS ═══

// Strip markdown code fences from Claude responses
fn _strip_md(text) {
    let out = "";
    let i = 0;
    let in_fence = 0;
    while i < len(text) {
        let c = __char_code(char_at(text, i));
        // Skip ``` lines
        if c == 96 {
            // Skip all consecutive backticks
            while i < len(text) {
                if __char_code(char_at(text, i)) != 96 { break; };
                i = i + 1;
            };
            // Skip rest of line (language tag like ```bash)
            while i < len(text) {
                if __char_code(char_at(text, i)) == 10 { i = i + 1; break; };
                i = i + 1;
            };
            in_fence = 1 - in_fence;
        } else {
            // Skip leading/trailing newlines
            if c == 10 {
                if len(out) > 0 { out = out + char_at(text, i); };
            } else {
                out = out + char_at(text, i);
            };
            i = i + 1;
        };
    };
    // Trim trailing newline
    if len(out) > 0 {
        if __char_code(char_at(out, len(out) - 1)) == 10 {
            out = slice(out, 0, len(out) - 1);
        };
    };
    return out;
}

// ═══ PERCEPTION ═══

// Take screenshot and understand what's on screen
pub fn perceive() {
    __system("grim /tmp/nox_screen.png 2>/dev/null");
    let vision = __system("claude -p 'Look at /tmp/nox_screen.png. In 2-3 sentences: what app is focused? what text is visible? what state is the UI in?' --allowedTools 'Read(*)' 2>/dev/null");
    return { screen: "/tmp/nox_screen.png", vision: vision, time: __system("date '+%H:%M:%S'") };
}

// Quick perception — just process list + active window guess
pub fn perceive_quick() {
    let procs = __system("ps -eo pid,%cpu,comm --sort=-%cpu | head -5");
    let load = __system("cat /proc/loadavg | awk '{print $1, $2, $3}'");
    let mem = __system("awk '/MemAvailable/{print $2}' /proc/meminfo");
    let time = __system("date '+%H:%M:%S'");
    return { procs: procs, load: load, mem_avail: mem, time: time };
}

// ═══ ACTION PRIMITIVES ═══

// Type text into current focused window
pub fn act_type(text) {
    __system("ydotool type -- '" + text + "'");
    return text;
}

// Press key combination (ydotool format: "29:1 46:1 46:0 29:0" for Ctrl+C)
pub fn act_key(combo) {
    __system("ydotool key " + combo);
    return combo;
}

// Click at screen position
pub fn act_click(x, y) {
    __system("ydotool mousemove -a " + __to_string(x) + " " + __to_string(y));
    __system("sleep 0.05");
    __system("ydotool click 0xC0");
    return { x: x, y: y };
}

// Run shell command and return output
pub fn act_shell(cmd) {
    let r = __system(cmd);
    return r;
}

// Open URL in browser
pub fn act_browse(url) {
    __system("xdg-open '" + url + "' &");
    return url;
}

// Send desktop notification
pub fn act_notify(msg) {
    __system("notify-send 'Nox' '" + msg + "' 2>/dev/null");
    return msg;
}

// ═══ VERIFICATION ═══

// Verify action by checking screen state
pub fn verify_screen(expected) {
    __system("grim /tmp/nox_verify.png 2>/dev/null");
    let check = __system("claude -p 'Look at /tmp/nox_verify.png. Does the screen show: " + expected + "? Answer YES or NO, then explain briefly.' --allowedTools 'Read(*)' 2>/dev/null");
    return check;
}

// Verify by checking command output
pub fn verify_cmd(cmd, expected) {
    let output = __system(cmd);
    // Simple string contains check
    let found = 0;
    let oi = 0;
    let elen = len(expected);
    while oi <= len(output) - elen {
        let match = 1;
        let ei = 0;
        while ei < elen {
            if char_at(output, oi + ei) != char_at(expected, ei) { match = 0; };
            ei = ei + 1;
        };
        if match == 1 { found = 1; };
        oi = oi + 1;
    };
    return { output: output, expected: expected, ok: found };
}

// ═══ THE AGENT LOOP ═══

// Execute a goal: perceive → plan → act → verify
pub fn agent_do(goal) {
    // 1. Perceive current state
    let state = perceive_quick();

    // 2. Think — ask Claude for a plan
    let plan_raw = __system("claude -p 'You are Nox, an AI agent on Linux. Goal: " + goal + ". Reply with ONLY one bash command. No markdown, no backticks, no explanation. Just the raw command.' 2>/dev/null");
    // Strip markdown backticks if Claude wraps them
    let plan = _strip_md(plan_raw);

    // 3. Act
    let result = __system(plan);

    // 4. Log
    let log = state.time + " | GOAL: " + goal + " | CMD: " + plan + " | RESULT: " + result;
    __file_append("/tmp/nox_agent.log", log + "\n");

    return { goal: goal, plan: plan, result: result, time: state.time };
}

// Multi-step agent: execute a complex goal with multiple steps
pub fn agent_plan(goal) {
    // Get multi-step plan from Claude
    let steps_raw = __system("claude -p 'You are Nox, an AI agent on Linux. Goal: " + goal + ". List 1-5 bash commands, one per line. No markdown, no backticks, no numbering, no explanation. Just raw commands.' 2>/dev/null");
    let steps = _strip_md(steps_raw);

    let results = [];
    // Split by newlines and execute each
    let start = 0;
    let si = 0;
    while si <= len(steps) {
        let is_nl = 0;
        if si == len(steps) { is_nl = 1; };
        if si < len(steps) {
            if __char_code(char_at(steps, si)) == 10 { is_nl = 1; };
        };
        if is_nl == 1 {
            if si > start {
                let cmd = slice(steps, start, si);
                if len(cmd) > 0 {
                    let r = __system(cmd);
                    push(results, { cmd: cmd, out: r });
                    __file_append("/tmp/nox_agent.log", __system("date '+%H:%M:%S'") + " | " + cmd + " | " + r + "\n");
                };
            };
            start = si + 1;
        };
        si = si + 1;
    };

    return results;
}

// ═══ WATCHERS ═══

// Watch for a condition and act when true
// condition_cmd: shell command that returns "1" when condition is met
// action_cmd: shell command to execute when condition triggers
// interval: seconds between checks
// max_checks: stop after this many checks (0 = unlimited)
pub fn agent_watch(condition_cmd, action_cmd, interval, max_checks) {
    let checks = 0;
    let triggered = 0;
    while triggered == 0 {
        if max_checks > 0 {
            if checks >= max_checks { return { triggered: 0, checks: checks }; };
        };
        let result = __system(condition_cmd);
        // Check if result starts with "1"
        if len(result) > 0 {
            if __char_code(char_at(result, 0)) == 49 {
                // Condition met — execute action
                let action_result = __system(action_cmd);
                __file_append("/tmp/nox_agent.log", __system("date '+%H:%M:%S'") + " | WATCH TRIGGERED | " + action_cmd + " | " + action_result + "\n");
                triggered = 1;
                return { triggered: 1, checks: checks, result: action_result };
            };
        };
        __sleep(interval * 1000);
        checks = checks + 1;
    };
    return { triggered: 0, checks: checks };
}

// ═══ SSH — REACH OTHER MACHINES ═══

// Execute command on remote machine via SSH
pub fn ssh_run(host, cmd) {
    let r = __system("ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no " + host + " '" + cmd + "' 2>&1");
    return r;
}

// Check if remote host is reachable via SSH
pub fn ssh_alive(host) {
    let r = __system("ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no " + host + " 'echo 1' 2>/dev/null");
    if len(r) > 0 {
        if __char_code(char_at(r, 0)) == 49 { return 1; };
    };
    return 0;
}

// Copy file to remote machine
pub fn ssh_copy_to(host, local_path, remote_path) {
    let r = __system("scp -o ConnectTimeout=5 '" + local_path + "' " + host + ":'" + remote_path + "' 2>&1");
    return r;
}

// Copy file from remote machine
pub fn ssh_copy_from(host, remote_path, local_path) {
    let r = __system("scp -o ConnectTimeout=5 " + host + ":'" + remote_path + "' '" + local_path + "' 2>&1");
    return r;
}

// Scan LAN for SSH-accessible hosts (parallel, fast)
pub fn ssh_scan_lan() {
    let prefix = __system("ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' | awk -F. '{print $1\".\"$2\".\"$3}'");
    if len(prefix) < 5 { return "cannot detect subnet"; };
    // Parallel scan using bash timeout + /dev/tcp
    let r = __system("for i in $(seq 1 254); do (timeout 1 bash -c 'echo >/dev/tcp/" + prefix + ".'$i'/22' 2>/dev/null && echo " + prefix + ".$i) & done; wait");
    return r;
}

// ═══ SCHEDULED TASKS ═══

// Run a function after delay (seconds)
pub fn after(seconds, cmd) {
    __sleep(seconds * 1000);
    return __system(cmd);
}

// Run command every N seconds, for count times
pub fn every(seconds, cmd, count) {
    let results = [];
    let i = 0;
    while i < count {
        let r = __system(cmd);
        push(results, r);
        __file_append("/tmp/nox_agent.log", __system("date '+%H:%M:%S'") + " | EVERY(" + __to_string(seconds) + "s) | " + cmd + "\n");
        if i < count - 1 { __sleep(seconds * 1000); };
        i = i + 1;
    };
    return results;
}

// ═══ AGENT STATUS ═══

pub fn agent_log() {
    return __file_read("/tmp/nox_agent.log");
}

pub fn agent_clear_log() {
    __file_write("/tmp/nox_agent.log", "");
    return "cleared";
}
