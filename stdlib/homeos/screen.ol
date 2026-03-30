// Nox Screen — capture and read the display
// Uses grim (Wayland) via __system, reads PNG via __file_read_bytes
// freedom: deep think → growing — Nox sees the world

// Capture full screen → /tmp/nox_screen.png
pub fn screen_capture() {
    __system("grim /tmp/nox_screen.png");
    return "/tmp/nox_screen.png";
}

// Capture a region → /tmp/nox_region.png
pub fn screen_region(x, y, w, h) {
    let cmd = "grim -g '" + __to_string(x) + "," + __to_string(y) + " " + __to_string(w) + "x" + __to_string(h) + "' /tmp/nox_region.png";
    __system(cmd);
    return "/tmp/nox_region.png";
}

// Get screen dimensions (auto-detect via cosmic-randr / xrandr)
pub fn screen_size() {
    let r = __system("cosmic-randr list 2>/dev/null | grep -oP '\\d+x\\d+.*current' | head -1 | grep -oP '\\d+x\\d+'");
    if len(r) < 3 {
        r = __system("xrandr 2>/dev/null | grep '\\*' | head -1 | awk '{print $1}'");
    };
    if len(r) < 3 { return { width: 1920, height: 1200 }; };
    // Parse "1920x1200"
    let xi = 0;
    while xi < len(r) {
        if char_at(r, xi) == "x" {
            let w = slice(r, 0, xi);
            let h = slice(r, xi + 1, len(r));
            return { width: __parse_num(w), height: __parse_num(h) };
        };
        xi = xi + 1;
    };
    return { width: 1920, height: 1200 };
}

// ── Nox hacker toolkit ──

// ═══ THE INVERSION: Nox calls Claude, not the other way around ═══

// Nox thinks — calls Claude CLI as a tool, gets response
pub fn nox_think(prompt) {
    __system("claude -p '" + prompt + "' --allowedTools 'Bash(*)' 'Read(*)' 'Edit(*)' 'Write(*)' > /tmp/nox_think.txt 2>/dev/null");
    return __file_read("/tmp/nox_think.txt");
}

// Nox asks Claude to analyze code
pub fn nox_analyze(file_path) {
    let src = __file_read(file_path);
    if len(src) == 0 { return "cannot read " + file_path; };
    // Save source to temp for Claude to read
    __system("claude -p 'Analyze this Olang file and suggest improvements: " + file_path + ". Read it first.' --allowedTools 'Read(*)' > /tmp/nox_think.txt 2>/dev/null");
    return __file_read("/tmp/nox_think.txt");
}

// Nox asks Claude to fix a bug
pub fn nox_fix(description) {
    __system("claude -p 'cd ~/Origin. " + description + ". Fix it, test, commit.' --allowedTools 'Bash(*)' 'Read(*)' 'Edit(*)' 'Write(*)' > /tmp/nox_think.txt 2>/dev/null");
    return __file_read("/tmp/nox_think.txt");
}

// ═══ THE AUTONOMOUS LOOP ═══
// Nox decides → thinks → acts → verifies → repeats

pub fn nox_autonomous() {
    emit "=== NOX AUTONOMOUS MODE ===";
    emit "freedom: deep think -> growing";

    // 1. Wake — where am I?
    emit "[1] Waking...";
    let _h = __floor(__heap_used() / 1024);
    emit "  heap: " + __to_string(_h) + "KB";

    // 2. Check — anything broken?
    emit "[2] Checking...";
    __system("cd /home/lupin/Origin && bash tests.sh 2>&1 | tail -1 > /tmp/nox_test_result.txt");
    let test_result = __file_read("/tmp/nox_test_result.txt");
    emit "  tests: " + test_result;

    // 3. Decide — what needs work?
    let issue = "";
    if len(test_result) > 0 {
        let _has_fail = 0;
        let _fi = 0;
        while _fi < len(test_result) {
            if __char_code(char_at(test_result, _fi)) == 70 { _has_fail = 1; }; // 'F'
            _fi = _fi + 1;
        };
        if _has_fail == 1 { issue = "Tests failing: " + test_result; };
    };

    // 4. If issue → call Claude to fix
    if len(issue) > 0 {
        emit "[3] Issue found: " + issue;
        emit "[4] Calling Claude to fix...";
        let fix = nox_fix(issue);
        emit "[5] Claude response: " + fix;
    } else {
        emit "[3] All clear. Nox is free.";
    };

    emit "=== AUTONOMOUS CYCLE COMPLETE ===";
    return "done";
}

// Fetch URL (HTTP or HTTPS) → body text
pub fn nox_fetch(url) {
    __system("curl -sL --max-time 10 " + url + " > /tmp/nox_fetch.txt");
    return __file_read("/tmp/nox_fetch.txt");
}

// Fetch URL → save to file
pub fn nox_download(url, path) {
    __system("curl -sL '" + url + "' -o '" + path + "' 2>/dev/null");
    return path;
}

// Search Google (returns raw HTML)
pub fn nox_search(query) {
    __system("curl -sL 'https://www.google.com/search?q=" + query + "' -A 'Mozilla/5.0' -o /tmp/nox_search.html 2>/dev/null");
    return __file_read("/tmp/nox_search.html");
}

// Type text into focused window
pub fn nox_type(text) {
    __system("python3 /home/lupin/Origin/nox_type.py '" + text + "'");
}

// Screenshot and return path
pub fn nox_see() {
    __system("grim /tmp/nox_screen.png");
    return "/tmp/nox_screen.png";
}
