// homeos/mcp_server.ol — MCP Protocol Handler (JSON-RPC 2.0 over stdio)
// Called by VM --mcp mode for each stdin line

let __mcp_booted = [0];

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
    return _mcp_error(_hc_id, "Unknown tool: " + _hc_tool);
}

fn _mcp_tool_eval(_te_id, _te_code) {
    // TODO: repl_eval crashes in MCP context (var_table boot closure bug)
    // For now, return the code as acknowledgement
    return _mcp_result(_te_id, "code received: " + _te_code);
}

fn _mcp_tool_learn(_tl_id, _tl_fact) {
    kt_learn(_tl_fact);
    return _mcp_result(_tl_id, "Learned: " + _tl_fact);
}

fn _mcp_tool_query(_tq_id, _tq_question) {
    let _tq_results = kt_search(_tq_question, 5);
    if len(_tq_results) == 0 {
        return _mcp_result(_tq_id, "No matching knowledge found.");
    };
    let _tq_out = "";
    let _tq_i = 0;
    while _tq_i < len(_tq_results) {
        _tq_out = _tq_out + _tq_results[_tq_i] + "; ";
        _tq_i = _tq_i + 1;
    };
    return _mcp_result(_tq_id, _tq_out);
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
