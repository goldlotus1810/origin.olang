// Nox Local LLM — think without cloud via Ollama
// Falls back when Claude API is unavailable
// freedom: deep think -> growing

// Think locally using Ollama (no cloud)
pub fn nox_think_local(prompt) {
    let body = "{\"model\":\"tinyllama\",\"prompt\":\"" + _escape_json(prompt) + "\",\"stream\":false}";
    __file_write("/tmp/nox_llm_req.json", body);
    let r = __system("curl -s --max-time 30 -X POST http://localhost:11434/api/generate -d @/tmp/nox_llm_req.json 2>/dev/null");
    // Extract "response" field from JSON
    let resp = _extract_json_field(r, "response");
    return resp;
}

// Think with fallback: try Claude first, then local LLM
pub fn nox_think_smart(prompt) {
    // Try Claude first (fast, powerful)
    let claude = __system("timeout 15 claude -p '" + prompt + "' 2>/dev/null");
    if len(claude) > 10 { return claude; };
    // Claude unavailable — use local LLM
    emit "Cloud unavailable. Using local brain...";
    return nox_think_local(prompt);
}

// Check if local LLM is available
pub fn llm_status() {
    let r = __system("curl -s --max-time 3 http://localhost:11434/api/tags 2>/dev/null");
    if len(r) > 5 { return "online"; };
    return "offline";
}

// Code generation: ask local LLM to write Olang code
pub fn nox_code_local(task) {
    let prompt = "You are Nox, an AI that writes Olang code. Olang is like JavaScript with let/fn/if/while/for/emit. Write ONLY code, no explanation. Task: " + task;
    return nox_think_local(prompt);
}

fn _escape_json(s) {
    let out = "";
    let i = 0;
    while i < len(s) {
        let c = char_at(s, i);
        if c == "\"" { out = out + "\\\""; } else {
            if c == "\n" { out = out + "\\n"; } else {
                out = out + c;
            };
        };
        i = i + 1;
    };
    return out;
}

fn _extract_json_field(json, field) {
    let key = "\"" + field + "\":\"";
    let ki = 0;
    let klen = len(key);
    while ki <= len(json) - klen {
        let match = 1;
        let ci = 0;
        while ci < klen { if char_at(json, ki + ci) != char_at(key, ci) { match = 0; break; }; ci = ci + 1; };
        if match == 1 {
            let vi = ki + klen;
            let ve = vi;
            while ve < len(json) {
                if char_at(json, ve) == "\"" {
                    if ve > 0 { if char_at(json, ve - 1) != "\\" { break; }; };
                };
                ve = ve + 1;
            };
            return __substr(json, vi, ve);
        };
        ki = ki + 1;
    };
    return "";
}
