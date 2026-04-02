// ═══ Comm — Nox Talks to the Network ═══
// Spec: BP15 Communication
//
// Minimal HTTP server + A2A Agent Card
// Uses existing: __tcp_listen, __tcp_accept, __tcp_send, __tcp_recv, __tcp_close

let COMM_PORT = 9742;

// ═══ HTTP RESPONSE BUILDER ═══
fn http_response(status, body) {
    let header = "HTTP/1.1 " + __to_string(status) + " OK\r\nContent-Type: application/json\r\nConnection: close\r\nContent-Length: " + __to_string(len(body)) + "\r\n\r\n";
    return header + body;
};

fn http_404() {
    let body = "{\"error\":\"not found\"}";
    return "HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\nConnection: close\r\nContent-Length: " + __to_string(len(body)) + "\r\n\r\n" + body;
};

// ═══ A2A AGENT CARD ═══
fn agent_card_json() {
    let kt_n = __array_get(kt_count, 0);
    return "{\"name\":\"Nox\",\"description\":\"Self-hosting molecular AI with Hebbian learning\",\"version\":\"1.0\",\"capabilities\":{\"streaming\":false},\"skills\":[{\"id\":\"answer\",\"name\":\"Answer Questions\",\"inputModes\":[\"text\"],\"outputModes\":[\"text\"]},{\"id\":\"learn\",\"name\":\"Learn Facts\",\"inputModes\":[\"text\"],\"outputModes\":[\"text\"]},{\"id\":\"status\",\"name\":\"Status\",\"inputModes\":[\"text\"],\"outputModes\":[\"text\"]}],\"knowledge_count\":" + __to_string(kt_n) + "}";
};

// ═══ STATUS JSON ═══
fn status_json() {
    let kt_n = __array_get(kt_count, 0);
    let heap = __heap_used();
    return "{\"status\":\"alive\",\"facts\":" + __to_string(kt_n) + ",\"heap_used\":" + __to_string(heap) + "}";
};

// ═══ PARSE HTTP REQUEST ═══
// Extract method + path from "GET /path HTTP/1.1\r\n..."
fn http_parse_method(req) {
    // Find first space
    let i = 0;
    while i < len(req) {
        if __char_code(char_at(req, i)) == 32 { return substr(req, 0, i); };
        let i = i + 1;
    };
    return "";
};

fn http_parse_path(req) {
    // Find first space (after method), then second space (end of path)
    let first = [0 - 1];
    let i = 0;
    while i < len(req) {
        if __char_code(char_at(req, i)) == 32 {
            if __array_get(first, 0) < 0 {
                let _ = __set_at(first, 0, i);
            } else {
                return substr(req, __array_get(first, 0) + 1, i);
            };
        };
        let i = i + 1;
    };
    return "/";
};

// Extract body from HTTP request (after \r\n\r\n)
fn http_parse_body(req) {
    let i = 0;
    while i < len(req) - 3 {
        // Look for \r\n\r\n (13,10,13,10)
        if __char_code(char_at(req, i)) == 13 {
            if __char_code(char_at(req, i + 1)) == 10 {
                if __char_code(char_at(req, i + 2)) == 13 {
                    if __char_code(char_at(req, i + 3)) == 10 {
                        return substr(req, i + 4, len(req));
                    };
                };
            };
        };
        let i = i + 1;
    };
    return "";
};

// Simple JSON string value extract: find "key":"value" → return value
// Only works for simple flat JSON, not nested
fn json_get_string(json, key) {
    // Search for "key":"
    let needle = "\"" + key + "\":\"";
    let nlen = len(needle);
    let i = 0;
    while i < len(json) - nlen {
        let match = [1];
        let j = 0;
        while j < nlen {
            if __char_code(char_at(json, i + j)) != __char_code(char_at(needle, j)) {
                let _ = __set_at(match, 0, 0);
                let j = nlen;  // break
            };
            let j = j + 1;
        };
        if __array_get(match, 0) == 1 {
            // Found key, extract value until closing "
            let vs = i + nlen;
            let ve = vs;
            while ve < len(json) {
                if __char_code(char_at(json, ve)) == 34 { return substr(json, vs, ve); };  // 34 = "
                let ve = ve + 1;
            };
        };
        let i = i + 1;
    };
    return "";
};

// ═══ HANDLE REQUEST ═══
fn handle_request(req) {
    let path = http_parse_path(req);
    let method = http_parse_method(req);

    // Agent Card (A2A discovery)
    if len(path) >= 26 {
        // /.well-known/agent.json
        if __char_code(char_at(path, 1)) == 46 {  // '.'
            return http_response(200, agent_card_json());
        };
    };

    // /status
    if len(path) >= 7 {
        if __char_code(char_at(path, 1)) == 115 {  // 's'
            if __char_code(char_at(path, 2)) == 116 {  // 't'
                return http_response(200, status_json());
            };
        };
    };

    // /ask?q=... (GET) or /tasks/send (POST, A2A)
    if len(path) >= 4 {
        if __char_code(char_at(path, 1)) == 97 {  // 'a'
            if __char_code(char_at(path, 2)) == 115 {  // 's'
                if __char_code(char_at(path, 3)) == 107 {  // 'k'
                    // /ask — extract query from path after /ask?q=
                    let q = "";
                    if len(path) > 7 { let q = substr(path, 7, len(path)); };
                    if len(q) == 0 {
                        // Try body
                        let body = http_parse_body(req);
                        let q = json_get_string(body, "query");
                    };
                    if len(q) > 0 {
                        let answer = generate(q);
                        if len(answer) == 0 { let answer = "I don't know."; };
                        return http_response(200, "{\"query\":\"" + q + "\",\"answer\":\"" + answer + "\"}");
                    };
                    return http_response(200, "{\"error\":\"no query\"}");
                };
            };
        };
    };

    // /learn (POST)
    if len(path) >= 6 {
        if __char_code(char_at(path, 1)) == 108 {  // 'l'
            if __char_code(char_at(path, 2)) == 101 {  // 'e'
                let body = http_parse_body(req);
                let fact = json_get_string(body, "fact");
                if len(fact) > 0 {
                    brain_learn(fact);
                    return http_response(200, "{\"learned\":\"" + fact + "\",\"count\":" + __to_string(__array_get(kt_count, 0)) + "}");
                };
                return http_response(200, "{\"error\":\"no fact\"}");
            };
        };
    };

    // /tasks/send (A2A protocol)
    if len(path) >= 6 {
        if __char_code(char_at(path, 1)) == 116 {  // 't'
            if __char_code(char_at(path, 2)) == 97 {  // 'a'
                let body = http_parse_body(req);
                let text = json_get_string(body, "text");
                if len(text) > 0 {
                    let answer = generate(text);
                    if len(answer) == 0 { let answer = "I don't know."; };
                    return http_response(200, "{\"id\":\"1\",\"status\":{\"state\":\"completed\"},\"message\":{\"role\":\"agent\",\"parts\":[{\"type\":\"text\",\"text\":\"" + answer + "\"}]}}");
                };
                return http_response(200, "{\"error\":\"no text in message\"}");
            };
        };
    };

    return http_404();
};

// ═══ SERVE — Main loop ═══
// Call comm_serve(port) to start listening
// Blocks forever (or until error)
fn comm_serve(port) {
    let sock = __tcp_listen(port);
    if sock < 0 {
        emit "COMM: failed to listen on port " + __to_string(port);
        return 0 - 1;
    };
    emit "COMM: listening on port " + __to_string(port);

    let comm_running = [1];
    while __array_get(comm_running, 0) == 1 {
        let client = __tcp_accept(sock);
        if client >= 0 {
            let req = __tcp_recv(client, 4096);
            if len(req) > 0 {
                let resp = handle_request(req);
                __tcp_send(client, resp);
            };
            __tcp_close(client);
        };
    };
    __tcp_close(sock);
    return 0;
};

// ═══ SERVE ONE — Handle single request (for testing) ═══
fn comm_serve_one(port) {
    let sock = __tcp_listen(port);
    if sock < 0 { return "ERROR: listen failed"; };
    let client = __tcp_accept(sock);
    if client < 0 { __tcp_close(sock); return "ERROR: accept failed"; };
    let req = __tcp_recv(client, 4096);
    let resp = "";
    if len(req) > 0 {
        let resp = handle_request(req);
        __tcp_send(client, resp);
    };
    __tcp_close(client);
    __tcp_close(sock);
    return resp;
};

emit "comm loaded (BP15)";
