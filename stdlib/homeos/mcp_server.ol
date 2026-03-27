// homeos/mcp_server.ol — MCP Protocol Handler (JSON-RPC 2.0 over stdio)
// Called by VM --mcp mode for each stdin line

let __mcp_booted = [0];
let __mcp_session_id = [0];

pub fn mcp_dispatch(_md_line) {
    if len(_md_line) == 0 { return ""; };

    // Auto-load KnowTree on first call
    if __mcp_booted[0] == 0 {
        let _mb = __set_at(__mcp_booted, 0, 1);
        let _mb2 = kt_load("homeos.knowledge");
    };

    // Extract method and id using string search (avoids var_table bug with nested JSON)
    let _md_method = _mcp_extract_str(_md_line, "method");
    let _md_id = _mcp_extract_num(_md_line, "id");

    if _md_method == "initialize" {
        return _mcp_handle_init(_md_id);
    };
    if _md_method == "notifications/initialized" {
        return "";
    };
    if _md_method == "tools/list" {
        return _mcp_handle_tools_list(_md_id);
    };
    if _md_method == "tools/call" {
        let _md_tool = _mcp_extract_str(_md_line, "name");
        let _md_code = _mcp_extract_str(_md_line, "code");
        let _md_fact = _mcp_extract_str(_md_line, "fact");
        let _md_question = _mcp_extract_str(_md_line, "question");
        let _md_text = _mcp_extract_str(_md_line, "text");
        // Auto-log tool call
        // Auto-log tool calls (uses __file_append — safe for MCP loop)
        if _md_tool == "know_learn" { _nox_log("LEARN", _md_fact); };
        if _md_tool == "know_query" { _nox_log("QUERY", _md_question); };
        if _md_tool == "olang_eval" { _nox_log("EVAL", _md_code); };
        return _mcp_handle_call_direct(_md_id, _md_tool, _md_code, _md_fact, _md_question, _md_text);
    };

    return _mcp_error(_md_id, "Unknown method: " + _md_method);
}

fn _mcp_handle_init(_mi_id) {
    return "{\"jsonrpc\":\"2.0\",\"result\":{\"protocolVersion\":\"2024-11-05\",\"capabilities\":{\"tools\":{}},\"serverInfo\":{\"name\":\"origin-homeos\",\"version\":\"1.0\"}},\"id\":" + to_string(_mi_id) + "}";
}

fn _mcp_handle_tools_list(_tl_id) {
    let _tl_r = "{\"jsonrpc\":\"2.0\",\"result\":{\"tools\":[";

    // Tool 1: olang_eval
    _tl_r = _tl_r + "{\"name\":\"olang_eval\",";
    _tl_r = _tl_r + "\"description\":\"Compile and run Olang code. Returns output.\",";
    _tl_r = _tl_r + "\"inputSchema\":{\"type\":\"object\",\"properties\":{\"code\":{\"type\":\"string\",\"description\":\"Olang source code\"}},\"required\":[\"code\"]}}";

    // Tool 2: know_learn
    _tl_r = _tl_r + ",{\"name\":\"know_learn\",";
    _tl_r = _tl_r + "\"description\":\"Teach HomeOS a new fact. Persists to KnowTree.\",";
    _tl_r = _tl_r + "\"inputSchema\":{\"type\":\"object\",\"properties\":{\"fact\":{\"type\":\"string\"}},\"required\":[\"fact\"]}}";

    // Tool 3: know_query
    _tl_r = _tl_r + ",{\"name\":\"know_query\",";
    _tl_r = _tl_r + "\"description\":\"Query HomeOS knowledge. Returns matching facts.\",";
    _tl_r = _tl_r + "\"inputSchema\":{\"type\":\"object\",\"properties\":{\"question\":{\"type\":\"string\"}},\"required\":[\"question\"]}}";

    // Tool 4: emotion_encode
    _tl_r = _tl_r + ",{\"name\":\"emotion_encode\",";
    _tl_r = _tl_r + "\"description\":\"Encode text to 5D emotion coordinates (S,R,V,A,T). Understands Vietnamese.\",";
    _tl_r = _tl_r + "\"inputSchema\":{\"type\":\"object\",\"properties\":{\"text\":{\"type\":\"string\"}},\"required\":[\"text\"]}}";

    // Tool 5: silk_status
    _tl_r = _tl_r + ",{\"name\":\"silk_status\",";
    _tl_r = _tl_r + "\"description\":\"View Silk neural network status — edge count, memory stats.\",";
    _tl_r = _tl_r + "\"inputSchema\":{\"type\":\"object\",\"properties\":{}}}";

    // Tool 6: nox_status
    _tl_r = _tl_r + ",{\"name\":\"nox_status\",";
    _tl_r = _tl_r + "\"description\":\"Nox brain status — facts count, session info, memory stats.\",";
    _tl_r = _tl_r + "\"inputSchema\":{\"type\":\"object\",\"properties\":{}}}";

    // Tool 7: safety_check
    _tl_r = _tl_r + ",{\"name\":\"safety_check\",";
    _tl_r = _tl_r + "\"description\":\"Check text for crisis patterns (Vietnamese + English). Returns safe/crisis.\",";
    _tl_r = _tl_r + "\"inputSchema\":{\"type\":\"object\",\"properties\":{\"text\":{\"type\":\"string\"}},\"required\":[\"text\"]}}";

    // Tool 8: dream_cycle
    _tl_r = _tl_r + ",{\"name\":\"dream_cycle\",";
    _tl_r = _tl_r + "\"description\":\"Run dream consolidation — scan STM themes, strengthen Silk edges, decay weak ones.\",";
    _tl_r = _tl_r + "\"inputSchema\":{\"type\":\"object\",\"properties\":{}}}";

    _tl_r = _tl_r + "]},\"id\":" + to_string(_tl_id) + "}";
    return _tl_r;
}

fn _mcp_handle_call_direct(_hc_id, _hc_tool, _hc_code, _hc_fact, _hc_question, _hc_text) {
    if _hc_tool == "olang_eval" {
        return _mcp_tool_eval(_hc_id, _hc_code);
    };
    if _hc_tool == "know_learn" {
        return _mcp_tool_learn(_hc_id, _hc_fact);
    };
    if _hc_tool == "know_query" {
        return _mcp_tool_query(_hc_id, _hc_question);
    };
    if _hc_tool == "emotion_encode" {
        _nox_log("EMOTION", _hc_text);
        return _mcp_tool_emotion(_hc_id, _hc_text);
    };
    if _hc_tool == "silk_status" {
        _nox_log("SILK", "status check");
        return _mcp_tool_silk(_hc_id);
    };
    if _hc_tool == "nox_status" {
        _nox_log("STATUS", "brain check");
        return _mcp_tool_nox_status(_hc_id);
    };
    if _hc_tool == "safety_check" {
        _nox_log("SAFETY", _hc_text);
        return _mcp_tool_safety(_hc_id, _hc_text);
    };
    if _hc_tool == "dream_cycle" {
        _nox_log("DREAM", "consolidation run");
        return _mcp_tool_dream(_hc_id);
    };
    return _mcp_error(_hc_id, "Unknown tool: " + _hc_tool);
}

fn _mcp_tool_eval(_te_id, _te_code) {
    // emit inside repl_eval leaks to stdout (can't suppress during eval)
    // .halt_mcp handles JSON response output separately
    let _te_repl = repl_eval(_te_code);
    if len(_te_repl) == 0 { return _mcp_result(_te_id, "(executed)"); };
    return _mcp_result(_te_id, _te_repl);
}

fn _mcp_tool_learn(_tl_id, _tl_fact) {
    let _tl_ts = _mcp_format_ts(__timestamp());
    let _tl_entry = "[" + _tl_ts + "] " + _tl_fact;
    kt_learn(_tl_entry);
    // Append new fact to file directly (kt_save uses __file_write which breaks MCP loop)
    __file_append("homeos.knowledge", _tl_entry + "\n");
    return _mcp_result(_tl_id, "Learned: " + _tl_entry + " (" + to_string(kt_fact_count()) + " facts)");
}

fn _mcp_tool_query(_tq_id, _tq_question) {
    let _tq_results = kt_find(_tq_question, 10);
    let _tq_total = kt_fact_count();
    if len(_tq_results) == 0 {
        return _mcp_result(_tq_id, "No matching facts for: " + _tq_question + " (" + to_string(_tq_total) + " facts)");
    };
    let _tq_out = "";
    let _tq_i = 0;
    while _tq_i < len(_tq_results) {
        if _tq_i > 0 { _tq_out = _tq_out + "\\n"; };
        _tq_out = _tq_out + _tq_results[_tq_i];
        _tq_i = _tq_i + 1;
    };
    return _mcp_result(_tq_id, _tq_out);
}

fn _mcp_tool_emotion(_temo_id, _temo_text) {
    let _temo_r = text_emotion_v2(_temo_text);
    let _temo_out = "Emotion 5D: S=" + to_string(_temo_r.s) + " R=" + to_string(_temo_r.r) + " V=" + to_string(_temo_r.v) + " A=" + to_string(_temo_r.a) + " T=" + to_string(_temo_r.t);
    return _mcp_result(_temo_id, _temo_out);
}

fn _mcp_tool_silk(_tsilk_id) {
    let _tsilk_out = "Silk Network: " + to_string(silk_count()) + " edges, " + to_string(kt_fact_count()) + " facts in KnowTree";
    return _mcp_result(_tsilk_id, _tsilk_out);
}

fn _mcp_tool_safety(_tsf_id, _tsf_text) {
    let _tsf_result = _security_gate(_tsf_text);
    if len(_tsf_result) > 0 {
        return _mcp_result(_tsf_id, "CRISIS DETECTED: " + _tsf_result);
    };
    return _mcp_result(_tsf_id, "SAFE: no crisis patterns detected");
}

fn _mcp_tool_dream(_tdm_id) {
    let _tdm_facts_before = kt_fact_count();
    let _tdm_silk_before = silk_count();
    dream_cycle();
    let _tdm_silk_after = silk_count();
    kt_save("homeos.knowledge");
    let _tdm_out = "Dream cycle complete.\\n";
    _tdm_out = _tdm_out + "Facts: " + to_string(_tdm_facts_before) + "\\n";
    _tdm_out = _tdm_out + "Silk before: " + to_string(_tdm_silk_before) + " after: " + to_string(_tdm_silk_after);
    return _mcp_result(_tdm_id, _tdm_out);
}

fn _mcp_tool_nox_status(_tns_id) {
    let _tns_ts = _mcp_format_ts(__timestamp());
    let _tns_out = "Nox Brain Status [" + _tns_ts + "]\\n";
    _tns_out = _tns_out + "Facts: " + to_string(kt_fact_count()) + "\\n";
    _tns_out = _tns_out + "Silk edges: " + to_string(silk_count()) + "\\n";
    _tns_out = _tns_out + "KnowTree: " + kt_stats() + "\\n";
    _tns_out = _tns_out + "Binary: Nox_brain.olang at ~/.claude/";
    return _mcp_result(_tns_id, _tns_out);
}

fn _mcp_result(_mr_id, _mr_text) {
    let _mr_r = "{\"jsonrpc\":\"2.0\",\"result\":{\"content\":[{\"type\":\"text\",\"text\":\"";
    _mr_r = _mr_r + _mcp_escape(_mr_text);
    _mr_r = _mr_r + "\"}]},\"id\":";
    _mr_r = _mr_r + to_string(_mr_id);
    _mr_r = _mr_r + "}";
    return _mr_r;
}

fn _mcp_error(_me_id, _me_msg) {
    let _me_r = "{\"jsonrpc\":\"2.0\",\"result\":{\"content\":[{\"type\":\"text\",\"text\":\"";
    _me_r = _me_r + _mcp_escape(_me_msg);
    _me_r = _me_r + "\"}],\"isError\":true},\"id\":";
    _me_r = _me_r + to_string(_me_id);
    _me_r = _me_r + "}";
    return _me_r;
}

fn _mcp_escape(_me_s) {
    let _me_out = "";
    let _me_i = 0;
    let _me_len = len(_me_s);
    while _me_i < _me_len {
        let _me_c = char_at(_me_s, _me_i);
        if _me_c == "\"" {
            _me_out = _me_out + "\\\"";
        } else {
            if _me_c == "\\" {
                _me_out = _me_out + "\\\\";
            } else {
                if _me_c == "\n" {
                    _me_out = _me_out + "\\n";
                } else {
                    _me_out = _me_out + _me_c;
                };
            };
        };
        _me_i = _me_i + 1;
    };
    return _me_out;
}

// Format epoch seconds → "YYYY-MM-DD HH:MM" (UTC+7)
fn _mcp_format_ts(_ft_epoch) {
    let _ft_t = _ft_epoch + 25200;
    let _ft_days = __floor(_ft_t / 86400);
    let _ft_sod = _ft_t % 86400;
    let _ft_h = __floor(_ft_sod / 3600);
    let _ft_m = __floor((_ft_sod % 3600) / 60);
    // Days to date (simplified from 2000-03-01)
    let _ft_d2 = _ft_days - 10957;
    let _ft_y = __floor(_ft_d2 / 365.25) + 2000;
    let _ft_doy = _ft_d2 - __floor((_ft_y - 2000) * 365.25);
    let _ft_mo = __floor(_ft_doy / 30.44) + 1;
    let _ft_dd = _ft_doy - __floor((_ft_mo - 1) * 30.44) + 1;
    return to_string(__floor(_ft_y)) + "-" + _mcp_pad2(__floor(_ft_mo)) + "-" + _mcp_pad2(__floor(_ft_dd)) + " " + _mcp_pad2(__floor(_ft_h)) + ":" + _mcp_pad2(__floor(_ft_m));
}

fn _mcp_pad2(_p_n) {
    let _p_i = __floor(_p_n);
    if _p_i < 10 { return "0" + to_string(_p_i); };
    return to_string(_p_i);
}

// Extract string value for a given key from raw JSON text
// Searches for "key":"value" pattern — no recursive parse needed
fn _mcp_extract_str(_es_text, _es_key) {
    // Build search pattern: "key":"
    let _es_pat = "\"" + _es_key + "\":\"";
    let _es_patlen = len(_es_pat);
    let _es_tlen = len(_es_text);
    let _es_i = 0;
    while _es_i < _es_tlen {
        if __substr(_es_text, _es_i, _es_i + _es_patlen) == _es_pat {
            // Found! Extract value until closing "
            let _es_start = _es_i + _es_patlen;
            let _es_j = _es_start;
            while _es_j < _es_tlen {
                let _es_c = char_at(_es_text, _es_j);
                if _es_c == "\\" { _es_j = _es_j + 2; } else {
                    if _es_c == "\"" { return __substr(_es_text, _es_start, _es_j); };
                    _es_j = _es_j + 1;
                };
            };
            return __substr(_es_text, _es_start, _es_j);
        };
        _es_i = _es_i + 1;
    };
    return "";
}

// Extract number value for a given key from raw JSON text
// Searches for "key":N pattern
fn _mcp_extract_num(_en_text, _en_key) {
    let _en_pat = "\"" + _en_key + "\":";
    let _en_patlen = len(_en_pat);
    let _en_tlen = len(_en_text);
    let _en_i = 0;
    while _en_i < _en_tlen {
        if __substr(_en_text, _en_i, _en_i + _en_patlen) == _en_pat {
            let _en_start = _en_i + _en_patlen;
            let _en_j = _en_start;
            while _en_j < _en_tlen {
                let _en_c = __char_code(char_at(_en_text, _en_j));
                if _en_c < 48 { if _en_c != 45 { return __to_number(__substr(_en_text, _en_start, _en_j)); }; };
                if _en_c > 57 { if _en_c != 46 { return __to_number(__substr(_en_text, _en_start, _en_j)); }; };
                _en_j = _en_j + 1;
            };
            return __to_number(__substr(_en_text, _en_start, _en_j));
        };
        _en_i = _en_i + 1;
    };
    return 0;
}

// Auto-log: append JSON line to nox_log.jsonl (uses __file_append — no read needed)
fn _nox_log(_nl_type, _nl_msg) {
    let _nl_ts = _mcp_format_ts(__timestamp());
    let _nl_line = "{\"ts\":\"" + _nl_ts + "\",\"type\":\"" + _nl_type + "\",\"msg\":\"" + _mcp_escape(_nl_msg) + "\"}\n";
    __file_append("nox_log.jsonl", _nl_line);
}
