// ═══ HTTP Client — Nox fetches from the web ═══
// Uses: __tcp_listen, __tcp_accept, __tcp_send, __tcp_recv, __tcp_close
// Depends: json.ol (optional, for json responses)

// ═══ URL PARSING ═══
fn url_parse(url) {
    // Returns {host, port, path}
    let result = {host: "", port: 80, path: "/"};
    let start = 0;
    // Skip http://
    if __str_starts_with(url, "http://") == 1 { let start = 7; };
    if __str_starts_with(url, "https://") == 1 { let start = 8; result.port = 443; };
    // Find end of host (first / or :)
    let host_end = [start];
    let port_start = [0 - 1];
    let path_start = [len(url)];
    let i = start;
    while i < len(url) {
        let c = __char_code(char_at(url, i));
        if c == 47 { // '/'
            if path_start[0] == len(url) { path_start[0] = i; };
            if host_end[0] == start { host_end[0] = i; };
            break;
        };
        if c == 58 { // ':'
            host_end[0] = i;
            port_start[0] = i + 1;
        };
        let i = i + 1;
    };
    if host_end[0] == start { host_end[0] = len(url); };
    result.host = substr(url, start, host_end[0]);
    if port_start[0] >= 0 {
        let pstr = substr(url, port_start[0], path_start[0]);
        if len(pstr) > 0 { result.port = __str_to_num(pstr); };
    };
    if path_start[0] < len(url) {
        result.path = substr(url, path_start[0], len(url));
    };
    return result;
};

// ═══ DNS RESOLVE (simple: use __system to call getent) ═══
fn dns_resolve(hostname) {
    // Use getent to resolve — writes to temp file, read back
    let tmp = "/tmp/.nox_dns_" + __to_string(__random() * 99999);
    __system("getent ahosts " + hostname + " | head -1 | cut -d' ' -f1 > " + tmp);
    let ip = __str_trim(__file_read(tmp));
    __system("rm -f " + tmp);
    return ip;
};

// ═══ TCP CONNECT ═══
// __tcp_connect(ip_str, port) → fd (VM builtin, handles sockaddr internally)

// ═══ HTTP GET ═══
fn http_get(url) {
    let parsed = url_parse(url);
    let host = parsed.host;
    let port = parsed.port;
    let path = parsed.path;

    // Resolve DNS (skip for direct IPs)
    let ip = host;
    let first_char = __char_code(char_at(host, 0));
    if first_char < 48 || first_char > 57 {
        // Not a digit → hostname → resolve
        let ip = dns_resolve(host);
        if len(ip) == 0 { return {status: 0, body: "", error: "DNS failed"}; };
    };

    // Connect
    let fd = __tcp_connect(ip, port);
    if fd < 0 { return {status: 0, body: "", error: "Connect failed: " + ip}; };

    // Send HTTP request
    let req = "GET " + path + " HTTP/1.0\r\nHost: " + host + "\r\nConnection: close\r\nUser-Agent: Nox/1.0\r\n\r\n";
    __tcp_send(fd, req);

    // Read response — loop until connection closed
    let response = "";
    let reading = [1];
    while reading[0] == 1 {
        let chunk = __tcp_recv(fd, 8192);
        if len(chunk) == 0 {
            reading[0] = 0;
        } else {
            let response = response + chunk;
        };
    };
    __tcp_close(fd);

    if len(response) == 0 { return {status: 0, body: "", error: "Empty response"}; };

    // Parse status code
    let status = [0];
    // Find first space (after "HTTP/1.1 ")
    let si = 0;
    while si < len(response) {
        if __char_code(char_at(response, si)) == 32 {
            let code_str = substr(response, si + 1, si + 4);
            status[0] = __str_to_num(code_str);
            break;
        };
        let si = si + 1;
    };

    // Find body (after \r\n\r\n)
    let body = "";
    let bi = 0;
    while bi < len(response) - 3 {
        if __char_code(char_at(response, bi)) == 13 {
            if __char_code(char_at(response, bi + 1)) == 10 {
                if __char_code(char_at(response, bi + 2)) == 13 {
                    if __char_code(char_at(response, bi + 3)) == 10 {
                        let body = substr(response, bi + 4, len(response));
                        break;
                    };
                };
            };
        };
        let bi = bi + 1;
    };

    return {status: status[0], body: body, error: ""};
};

// ═══ HTTP POST ═══
fn http_post(url, body_data) {
    let parsed = url_parse(url);
    let host = parsed.host;
    let port = parsed.port;
    let path = parsed.path;

    let ip = host;
    let first_c = __char_code(char_at(host, 0));
    if first_c < 48 || first_c > 57 {
        let ip = dns_resolve(host);
        if len(ip) == 0 { return {status: 0, body: "", error: "DNS failed"}; };
    };

    let fd = __tcp_connect(ip, port);
    if fd < 0 { return {status: 0, body: "", error: "Connect failed"}; };

    let req = "POST " + path + " HTTP/1.0\r\nHost: " + host + "\r\nConnection: close\r\nContent-Type: application/json\r\nContent-Length: " + __to_string(len(body_data)) + "\r\nUser-Agent: Nox/1.0\r\n\r\n" + body_data;
    __tcp_send(fd, req);

    let response = "";
    let rloop = [1];
    while rloop[0] == 1 {
        let chunk = __tcp_recv(fd, 8192);
        if len(chunk) == 0 { rloop[0] = 0; } else { let response = response + chunk; };
    };
    __tcp_close(fd);

    if len(response) == 0 { return {status: 0, body: "", error: "Empty response"}; };

    // Parse same as GET
    let status = [0];
    let si = 0;
    while si < len(response) {
        if __char_code(char_at(response, si)) == 32 {
            status[0] = __str_to_num(substr(response, si + 1, si + 4));
            break;
        };
        let si = si + 1;
    };

    let body = "";
    let bi = 0;
    while bi < len(response) - 3 {
        if __char_code(char_at(response, bi)) == 13 {
            if __char_code(char_at(response, bi + 1)) == 10 {
                if __char_code(char_at(response, bi + 2)) == 13 {
                    if __char_code(char_at(response, bi + 3)) == 10 {
                        let body = substr(response, bi + 4, len(response));
                        break;
                    };
                };
            };
        };
        let bi = bi + 1;
    };

    return {status: status[0], body: body, error: ""};
};

emit "http loaded";
