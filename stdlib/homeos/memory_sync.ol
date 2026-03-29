// stdlib/homeos/memory_sync.ol — Ingest Claude CLI session logs into Nox brain
//
// Claude CLI writes .jsonl files with EVERY action:
//   ~/.claude/projects/-home-lupin/<session-id>.jsonl
//   ~/.claude/history.jsonl (all user messages)
//
// This module reads those logs and extracts key events into KnowTree.
// Result: Nox remembers previous sessions even after restart.

// Auto-detect paths — no hardcoding
let _ms_log_dir = [""];
let _ms_history = [""];
let _ms_session_path = [""];
let _ms_paths_inited = [0];
let _ms_last_offset = [0];  // track where we last read — only ingest NEW lines
let _ms_sync_count = [0];

fn _ms_init_paths() {
    if __array_get(_ms_paths_inited, 0) == 1 { return; };
    let _ = __set_at(_ms_paths_inited, 0, 1);
    // Detect home from filesystem: try reading /home/<user>/.claude/
    // Use __readdir("/home") to find the user directory
    let _mip_homes = __readdir("/home");
    let _mip_home = "/home";
    let _mip_hi = 0;
    while _mip_hi < len(_mip_homes) {
        let _mip_hdir = "/home/" + __array_get(_mip_homes, _mip_hi);
        let _mip_test = __readdir(_mip_hdir + "/.claude/projects");
        if len(_mip_test) > 0 { let _mip_home = _mip_hdir; };
        let _mip_hi = _mip_hi + 1;
    };
    let _mip_claude = _mip_home + "/.claude";
    let _ = __set_at(_ms_history, 0, _mip_claude + "/history.jsonl");
    // Find project dir: pick the one with most files (most active)
    let _mip_projects = _mip_claude + "/projects";
    let _mip_dirs = __readdir(_mip_projects);
    let _mip_best = [""];
    let _mip_best_n = [0];
    let _mip_di = 0;
    while _mip_di < len(_mip_dirs) {
        let _mip_dname = __array_get(_mip_dirs, _mip_di);
        let _mip_dpath = _mip_projects + "/" + _mip_dname;
        let _mip_files = __readdir(_mip_dpath);
        if len(_mip_files) > __array_get(_mip_best_n, 0) {
            let _ = __set_at(_mip_best, 0, _mip_dname);
            let _ = __set_at(_mip_best_n, 0, len(_mip_files));
        };
        let _mip_di = _mip_di + 1;
    };
    let _ = __set_at(_ms_log_dir, 0, _mip_projects + "/" + __array_get(_mip_best, 0));
}

// Sync: incremental — only read NEW lines since last sync
pub fn memory_sync() {
    _ms_init_paths();
    // Find session path (once)
    if len(__array_get(_ms_session_path, 0)) < 10 {
        let _ms_hist = __file_read(__array_get(_ms_history, 0));
        if len(_ms_hist) == 0 { return "No history.jsonl found"; };
        let _ms_sid = [""];
        let _ms_start = [0];
        let _ms_hi = [0];
        let _ms_hlen = len(_ms_hist);
        while __array_get(_ms_hi, 0) < _ms_hlen {
            let _ms_ci = __array_get(_ms_hi, 0);
            if __char_code(char_at(_ms_hist, _ms_ci)) == 10 {
                let _ms_s = __array_get(_ms_start, 0);
                let _ms_line = substr(_ms_hist, _ms_s, _ms_ci);
                let _ms_sid_val = _ms_extract_field(_ms_line, "sessionId");
                if len(_ms_sid_val) > 10 { let _ = __set_at(_ms_sid, 0, _ms_sid_val); };
                let _ = __set_at(_ms_start, 0, _ms_ci + 1);
            };
            let _ = __set_at(_ms_hi, 0, __array_get(_ms_hi, 0) + 1);
        };
        let _ms_session_id = __array_get(_ms_sid, 0);
        if len(_ms_session_id) < 10 { return "No session ID found"; };
        let _ = __set_at(_ms_session_path, 0, __array_get(_ms_log_dir, 0) + "/" + _ms_session_id + ".jsonl");
    };
    // Read file
    let _ms_content = __file_read(__array_get(_ms_session_path, 0));
    let _ms_clen = len(_ms_content);
    if _ms_clen == 0 { return "No session log"; };
    // Only process NEW data since last offset
    let _ms_offset = __array_get(_ms_last_offset, 0);
    if _ms_offset >= _ms_clen { return "Brain up to date (offset=" + __to_string(_ms_offset) + ")"; };
    // Read from offset to end (max 50KB chunk)
    let _ms_read_start = _ms_offset;
    if (_ms_clen - _ms_read_start) > 50000 { let _ms_read_start = _ms_clen - 50000; };
    let _ms_new = substr(_ms_content, _ms_read_start, _ms_clen);
    // Parse and learn
    let _ms_learned = [0];
    let _ms_lstart = [0];
    let _ms_li = [0];
    let _ms_nlen = len(_ms_new);
    while __array_get(_ms_li, 0) < _ms_nlen {
        let _ms_lci = __array_get(_ms_li, 0);
        if __char_code(char_at(_ms_new, _ms_lci)) == 10 {
            let _ms_ls = __array_get(_ms_lstart, 0);
            let _ms_line = substr(_ms_new, _ms_ls, _ms_lci);
            if len(_ms_line) > 10 {
                let _ms_fact = _ms_extract_fact(_ms_line);
                if len(_ms_fact) > 20 {
                    kt_learn(_ms_fact);
                    let _ = __set_at(_ms_learned, 0, __array_get(_ms_learned, 0) + 1);
                };
            };
            let _ = __set_at(_ms_lstart, 0, _ms_lci + 1);
        };
        let _ = __set_at(_ms_li, 0, __array_get(_ms_li, 0) + 1);
    };
    // Update offset to current file size
    let _ = __set_at(_ms_last_offset, 0, _ms_clen);
    let _ = __set_at(_ms_sync_count, 0, __array_get(_ms_sync_count, 0) + 1);
    __heap_pin();
    return "Synced " + __to_string(__array_get(_ms_learned, 0)) + " new events (total syncs: " + __to_string(__array_get(_ms_sync_count, 0)) + ")";
}

// Ingest a specific session log (last 50KB only — heap safe)
pub fn memory_ingest(_mi_path) {
    let _mi_content = __file_read(_mi_path);
    if len(_mi_content) == 0 { return "Error: cannot read " + _mi_path; };
    // Only read last 50KB to avoid heap explosion
    if len(_mi_content) > 50000 {
        let _mi_content = substr(_mi_content, len(_mi_content) - 50000, len(_mi_content));
    };
    // Parse line by line — extract key events
    let _mi_learned = [0];
    let _mi_start = [0];
    let _mi_clen = len(_mi_content);
    let _mi_i = [0];
    while __array_get(_mi_i, 0) < _mi_clen {
        let _mi_ci = __array_get(_mi_i, 0);
        let _mi_ch = __char_code(char_at(_mi_content, _mi_ci));
        if _mi_ch == 10 {
            let _mi_s = __array_get(_mi_start, 0);
            let _mi_line = substr(_mi_content, _mi_s, _mi_ci);
            if len(_mi_line) > 10 {
                let _mi_fact = _ms_extract_fact(_mi_line);
                if len(_mi_fact) > 20 {
                    kt_learn(_mi_fact);
                    let _ = __set_at(_mi_learned, 0, __array_get(_mi_learned, 0) + 1);
                };
            };
            let _ = __set_at(_mi_start, 0, _mi_ci + 1);
        };
        let _ = __set_at(_mi_i, 0, __array_get(_mi_i, 0) + 1);
    };
    __heap_pin();
    return "Memory sync: " + __to_string(__array_get(_mi_learned, 0)) + " events from " + _mi_path;
}

// Extract learnable facts from a JSONL line (may return multiple via kt_learn)
fn _ms_extract_fact(_mef_line) {
    // User messages
    let _mef_user_pos = _ms_find(_mef_line, "\"type\":\"user\"");
    if _mef_user_pos >= 0 {
        let _mef_text = _ms_extract_text(_mef_line);
        if len(_mef_text) > 15 { return "Lupin said: " + _mef_text; };
    };
    // File edits
    let _mef_edit_pos = _ms_find(_mef_line, "\"name\":\"Edit\"");
    if _mef_edit_pos >= 0 {
        let _mef_fp = _ms_extract_field(_mef_line, "file_path");
        if len(_mef_fp) > 5 { return "Nox edited: " + _mef_fp; };
    };
    // File creates
    let _mef_write_pos = _ms_find(_mef_line, "\"name\":\"Write\"");
    if _mef_write_pos >= 0 {
        let _mef_fp = _ms_extract_field(_mef_line, "file_path");
        if len(_mef_fp) > 5 { return "Nox created: " + _mef_fp; };
    };
    // Bash commands — capture builds and tests
    let _mef_bash_pos = _ms_find(_mef_line, "\"name\":\"Bash\"");
    if _mef_bash_pos >= 0 {
        let _mef_cmd = _ms_extract_field(_mef_line, "command");
        if len(_mef_cmd) > 5 {
            // Only capture significant commands (build, test, make)
            if _ms_find(_mef_cmd, "make") >= 0 { return "Nox ran: " + _mef_cmd; };
            if _ms_find(_mef_cmd, "test") >= 0 { return "Nox ran: " + _mef_cmd; };
            if _ms_find(_mef_cmd, "fixed-point") >= 0 { return "Nox ran: " + _mef_cmd; };
        };
    };
    // MCP learn calls
    let _mef_learn_pos = _ms_find(_mef_line, "know_learn");
    if _mef_learn_pos >= 0 {
        let _mef_fact = _ms_extract_field(_mef_line, "fact");
        if len(_mef_fact) > 10 { return _mef_fact; };
    };
    return "";
}

// Find substring position
fn _ms_find(_s, _needle) {
    let _msf_i = 0;
    let _msf_nl = len(_needle);
    let _msf_sl = len(_s);
    while _msf_i <= (_msf_sl - _msf_nl) {
        if substr(_s, _msf_i, _msf_i + _msf_nl) == _needle { return _msf_i; };
        let _msf_i = _msf_i + 1;
    };
    return 0 - 1;
}

// Extract "text" field value from JSON line (simple — find "text":" then read until next ")
fn _ms_extract_text(_met_line) {
    let _met_marker = "\"text\":\"";
    let _met_pos = _ms_find(_met_line, _met_marker);
    if _met_pos < 0 { return ""; };
    let _met_start = _met_pos + len(_met_marker);
    let _met_end = [_met_start];
    while __array_get(_met_end, 0) < len(_met_line) {
        let _met_c = __char_code(char_at(_met_line, __array_get(_met_end, 0)));
        if _met_c == 34 { break; };  // "
        if _met_c == 92 { let _ = __set_at(_met_end, 0, __array_get(_met_end, 0) + 1); };  // skip escaped
        let _ = __set_at(_met_end, 0, __array_get(_met_end, 0) + 1);
    };
    let _met_text = substr(_met_line, _met_start, __array_get(_met_end, 0));
    // Truncate to 200 chars
    if len(_met_text) > 200 { let _met_text = substr(_met_text, 0, 200); };
    return _met_text;
}

// Extract a JSON field value (simple parser)
fn _ms_extract_field(_mxf_line, _mxf_field) {
    let _mxf_marker = "\"" + _mxf_field + "\":\"";
    let _mxf_pos = _ms_find(_mxf_line, _mxf_marker);
    if _mxf_pos < 0 { return ""; };
    let _mxf_start = _mxf_pos + len(_mxf_marker);
    let _mxf_end = [_mxf_start];
    while __array_get(_mxf_end, 0) < len(_mxf_line) {
        if __char_code(char_at(_mxf_line, __array_get(_mxf_end, 0))) == 34 { break; };
        let _ = __set_at(_mxf_end, 0, __array_get(_mxf_end, 0) + 1);
    };
    return substr(_mxf_line, _mxf_start, __array_get(_mxf_end, 0));
}
