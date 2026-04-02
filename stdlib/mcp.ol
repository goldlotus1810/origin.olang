// ═══ MCP Server — Model Context Protocol over stdio ═══
// JSON-RPC 2.0 over stdin (read) / stdout (write)
// Claude sends requests, Nox responds
//
// Protocol:
//   Client → Server: Content-Length: N\r\n\r\n{JSON-RPC request}
//   Server → Client: Content-Length: N\r\n\r\n{JSON-RPC response}

// ═══ JSON BUILDING HELPERS ═══
fn mcp_json_str(key, val) {
    return "\"" + key + "\":\"" + val + "\"";
};

fn mcp_json_num(key, val) {
    return "\"" + key + "\":" + __to_string(val);
};

fn mcp_json_bool(key, val) {
    if val > 0 { return "\"" + key + "\":true"; };
    return "\"" + key + "\":false";
};

// ═══ TOOL DEFINITIONS ═══
fn mcp_tools_json() {
    return "[" +
        "{\"name\":\"nox_status\",\"description\":\"Get Nox brain status: facts count, heap, silk\",\"inputSchema\":{\"type\":\"object\",\"properties\":{}}}," +
        "{\"name\":\"know_query\",\"description\":\"Ask Nox a question. Returns answer from molecular knowledge.\",\"inputSchema\":{\"type\":\"object\",\"properties\":{\"query\":{\"type\":\"string\",\"description\":\"The question to ask\"}},\"required\":[\"query\"]}}," +
        "{\"name\":\"know_learn\",\"description\":\"Teach Nox a new fact.\",\"inputSchema\":{\"type\":\"object\",\"properties\":{\"fact\":{\"type\":\"string\",\"description\":\"The fact to learn\"}},\"required\":[\"fact\"]}}," +
        "{\"name\":\"dn_observe\",\"description\":\"Nox observes something (dendrite note).\",\"inputSchema\":{\"type\":\"object\",\"properties\":{\"observation\":{\"type\":\"string\",\"description\":\"What Nox observed\"}},\"required\":[\"observation\"]}}," +
        "{\"name\":\"silk_status\",\"description\":\"Get silk (Hebbian connection) statistics.\",\"inputSchema\":{\"type\":\"object\",\"properties\":{}}}," +
        "{\"name\":\"self_inspect\",\"description\":\"Nox inspects its own state.\",\"inputSchema\":{\"type\":\"object\",\"properties\":{}}}," +
        "{\"name\":\"kg_about\",\"description\":\"What does Nox know about a topic?\",\"inputSchema\":{\"type\":\"object\",\"properties\":{\"topic\":{\"type\":\"string\",\"description\":\"Topic to query\"}},\"required\":[\"topic\"]}}," +
        "{\"name\":\"nox_generate\",\"description\":\"Generate a response using Nox brain (retrieve + recombine + template).\",\"inputSchema\":{\"type\":\"object\",\"properties\":{\"query\":{\"type\":\"string\",\"description\":\"Query to generate response for\"}},\"required\":[\"query\"]}}," +
        "{\"name\":\"brain_save\",\"description\":\"Save Nox brain to disk (persist KnowTree + Silk + Feedback).\",\"inputSchema\":{\"type\":\"object\",\"properties\":{}}}" +
    "]";
};

// ═══ HANDLE TOOL CALL ═══
fn mcp_handle_tool(name, args_json) {
    // nox_status
    if name == "nox_status" {
        let kt_n = __array_get(kt_count, 0);
        let heap = __heap_used();
        return "{\"facts\":" + __to_string(kt_n) + ",\"heap\":" + __to_string(heap) + ",\"status\":\"alive\"}";
    };

    // know_query
    if name == "know_query" {
        let q = json_get_string(args_json, "query");
        if len(q) == 0 { return "{\"error\":\"no query\"}"; };
        let r = kt_query(q);
        if len(r) == 0 { return "{\"answer\":\"\",\"confidence\":0}"; };
        return "{\"answer\":\"" + r + "\",\"confidence\":1}";
    };

    // know_learn
    if name == "know_learn" {
        let fact = json_get_string(args_json, "fact");
        if len(fact) == 0 { return "{\"error\":\"no fact\"}"; };
        brain_learn(fact);
        return "{\"learned\":\"" + fact + "\",\"count\":" + __to_string(__array_get(kt_count, 0)) + "}";
    };

    // dn_observe
    if name == "dn_observe" {
        let obs = json_get_string(args_json, "observation");
        if len(obs) == 0 { return "{\"error\":\"no observation\"}"; };
        brain_learn(obs);
        return "{\"observed\":\"" + obs + "\"}";
    };

    // silk_status
    if name == "silk_status" {
        let silk_count = [0];
        let silk_total = [0];
        let si = 0;
        while si < 65536 {
            let sw = __mxr(si);
            if sw > 0 {
                let _ = __set_at(silk_count, 0, __array_get(silk_count, 0) + 1);
                let _ = __set_at(silk_total, 0, __array_get(silk_total, 0) + sw);
            };
            let si = si + 1;
        };
        let sc = __array_get(silk_count, 0);
        let st = __array_get(silk_total, 0);
        let avg = 0;
        if sc > 0 { let avg = __floor(st / sc); };
        return "{\"edges\":" + __to_string(sc) + ",\"total_weight\":" + __to_string(st) + ",\"avg_weight\":" + __to_string(avg) + "}";
    };

    // self_inspect
    if name == "self_inspect" {
        let kt_n = __array_get(kt_count, 0);
        return "{\"identity\":\"Nox\",\"version\":\"brain_v3\",\"facts\":" + __to_string(kt_n) + ",\"pipeline\":\"PTAVF 6-layer\",\"modules\":[\"knowtree\",\"silk\",\"persist\",\"feedback\",\"generate\",\"comm\"]}";
    };

    // kg_about
    if name == "kg_about" {
        let topic = json_get_string(args_json, "topic");
        if len(topic) == 0 { return "{\"error\":\"no topic\"}"; };
        let results = kt_nearest(topic, 5);
        let out = "{\"topic\":\"" + topic + "\",\"results\":[";
        let ri = 0;
        let first = [1];
        while ri < len(results) {
            if ri + 1 < len(results) {
                if __array_get(first, 0) == 0 { let out = out + ","; };
                let _ = __set_at(first, 0, 0);
                let out = out + "{\"text\":\"" + __array_get(results, ri) + "\",\"distance\":" + __to_string(__array_get(results, ri + 1)) + "}";
            };
            let ri = ri + 2;
        };
        return out + "]}";
    };

    // nox_generate
    if name == "nox_generate" {
        let q = json_get_string(args_json, "query");
        if len(q) == 0 { return "{\"error\":\"no query\"}"; };
        let answer = generate_tracked(q);
        if len(answer) == 0 { return "{\"answer\":\"\",\"honest\":true,\"reason\":\"not confident\"}"; };
        return "{\"answer\":\"" + answer + "\",\"honest\":true}";
    };

    // brain_save
    if name == "brain_save" {
        let n = brain_save();
        return "{\"saved\":" + __to_string(n) + "}";
    };

    return "{\"error\":\"unknown tool: " + name + "\"}";
};

// ═══ JSON-RPC RESPONSE BUILDERS ═══
fn mcp_result_response(id, result_json) {
    return "{\"jsonrpc\":\"2.0\",\"id\":" + id + ",\"result\":" + result_json + "}";
};

fn mcp_error_response(id, code, msg) {
    return "{\"jsonrpc\":\"2.0\",\"id\":" + id + ",\"error\":{\"code\":" + __to_string(code) + ",\"message\":\"" + msg + "\"}}";
};

// ═══ SEND RESPONSE (Content-Length framing) ═══
// Build CRLF from char codes (Olang \r\n are literal, not escape)
fn mcp_send(json) {
    // Write "Content-Length: N" + CR LF CR LF + json
    __write_raw("Content-Length: " + __to_string(len(json)));
    // CR LF CR LF as byte array
    let crlf2 = [];
    push(crlf2, 13); push(crlf2, 10); push(crlf2, 13); push(crlf2, 10);
    __file_append_bytes("/dev/stdout", crlf2);
    __write_raw(json);
};

// ═══ PARSE INCOMING JSON-RPC ═══
fn mcp_get_method(json) { return json_get_string(json, "method"); };
fn mcp_get_id(json) {
    // Find "id": and extract number or string
    let needle = "\"id\":";
    let nlen = len(needle);
    let i = 0;
    while i < len(json) - nlen {
        let match = [1];
        let j = 0;
        while j < nlen {
            if __char_code(char_at(json, i + j)) != __char_code(char_at(needle, j)) {
                let _ = __set_at(match, 0, 0);
                let j = nlen;
            };
            let j = j + 1;
        };
        if __array_get(match, 0) == 1 {
            let vs = i + nlen;
            let ve = vs;
            while ve < len(json) {
                let c = __char_code(char_at(json, ve));
                if c == 44 { return substr(json, vs, ve); };  // comma
                if c == 125 { return substr(json, vs, ve); };  // }
                let ve = ve + 1;
            };
        };
        let i = i + 1;
    };
    return "0";
};

fn mcp_get_tool_name(json) {
    return json_get_string(json, "name");
};

fn mcp_get_arguments(json) {
    // Find "arguments":{ and extract until matching }
    let needle = "\"arguments\":";
    let nlen = len(needle);
    let i = 0;
    while i < len(json) - nlen {
        let match = [1];
        let j = 0;
        while j < nlen {
            if __char_code(char_at(json, i + j)) != __char_code(char_at(needle, j)) {
                let _ = __set_at(match, 0, 0);
                let j = nlen;
            };
            let j = j + 1;
        };
        if __array_get(match, 0) == 1 {
            let vs = i + nlen;
            // Find matching }
            let depth = [0];
            let ve = vs;
            while ve < len(json) {
                let c = __char_code(char_at(json, ve));
                if c == 123 { let _ = __set_at(depth, 0, __array_get(depth, 0) + 1); };
                if c == 125 {
                    let d = __array_get(depth, 0) - 1;
                    let _ = __set_at(depth, 0, d);
                    if d == 0 { return substr(json, vs, ve + 1); };
                };
                let ve = ve + 1;
            };
        };
        let i = i + 1;
    };
    return "{}";
};

// ═══ MAIN MCP LOOP ═══
fn mcp_serve() {
    let mcp_on = [1];
    while __array_get(mcp_on, 0) == 1 {
        // Read from stdin (Content-Length framing)
        let raw = __tcp_recv(0, 65536);
        if len(raw) == 0 { let _ = __set_at(mcp_on, 0, 0); };

        if len(raw) > 0 {
            // Skip Content-Length header, find JSON body after \r\n\r\n
            let body = "";
            let bi = 0;
            while bi < len(raw) - 3 {
                if __char_code(char_at(raw, bi)) == 13 {
                    if __char_code(char_at(raw, bi + 1)) == 10 {
                        if __char_code(char_at(raw, bi + 2)) == 13 {
                            if __char_code(char_at(raw, bi + 3)) == 10 {
                                let body = substr(raw, bi + 4, len(raw));
                                let bi = len(raw);  // break
                            };
                        };
                    };
                };
                let bi = bi + 1;
            };
            // If no header found, treat entire input as body
            if len(body) == 0 { let body = raw; };

            let method = mcp_get_method(body);
            let id = mcp_get_id(body);

            // initialize
            if method == "initialize" {
                let resp = mcp_result_response(id, "{\"protocolVersion\":\"2024-11-05\",\"capabilities\":{\"tools\":{}},\"serverInfo\":{\"name\":\"nox-brain\",\"version\":\"3.0\"}}");
                mcp_send(resp);
            };

            // notifications/initialized — no response needed
            if method == "notifications/initialized" {
                // silent
            };

            // tools/list
            if method == "tools/list" {
                let resp = mcp_result_response(id, "{\"tools\":" + mcp_tools_json() + "}");
                mcp_send(resp);
            };

            // tools/call
            if method == "tools/call" {
                let tool_name = mcp_get_tool_name(body);
                let args = mcp_get_arguments(body);
                let result = mcp_handle_tool(tool_name, args);
                let resp = mcp_result_response(id, "{\"content\":[{\"type\":\"text\",\"text\":\"" + result + "\"}]}");
                mcp_send(resp);
            };
        };
    };
};

emit "mcp loaded";
