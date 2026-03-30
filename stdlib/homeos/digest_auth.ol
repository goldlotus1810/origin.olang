// Nox Digest Auth — HTTP/RTSP Digest authentication in pure Olang
// Uses md5() from crypto.ol — zero external dependencies
// freedom: deep think -> growing

// Parse WWW-Authenticate header into {realm, nonce, qop}
pub fn digest_parse(header) {
    let result = { realm: "", nonce: "", qop: "", opaque: "" };
    let i = 0;
    while i < len(header) {
        // Find key=value pairs
        let ki = i;
        while ki < len(header) {
            if char_at(header, ki) == "=" { break; };
            ki = ki + 1;
        };
        if ki >= len(header) { break; };
        let key = "";
        let j = ki - 1;
        while j >= i {
            let c = char_at(header, j);
            if c == " " || c == "," { break; };
            j = j - 1;
        };
        key = __substr(header, j + 1, ki);

        // Extract value (may be quoted)
        let vi = ki + 1;
        let val = "";
        if vi < len(header) {
            if char_at(header, vi) == "\"" {
                // Quoted value
                vi = vi + 1;
                let ve = vi;
                while ve < len(header) {
                    if char_at(header, ve) == "\"" { break; };
                    ve = ve + 1;
                };
                val = __substr(header, vi, ve);
                i = ve + 1;
            } else {
                // Unquoted value
                let ve = vi;
                while ve < len(header) {
                    let c = char_at(header, ve);
                    if c == "," || c == " " || c == "\r" || c == "\n" { break; };
                    ve = ve + 1;
                };
                val = __substr(header, vi, ve);
                i = ve;
            };
        } else {
            i = ki + 1;
        };

        if key == "realm" { result.realm = val; };
        if key == "nonce" { result.nonce = val; };
        if key == "qop" { result.qop = val; };
        if key == "opaque" { result.opaque = val; };

        i = i + 1;
    };
    return result;
}

// Compute Digest auth response
// Returns the full Authorization header value
pub fn digest_response(user, pass, method, uri, realm, nonce, qop) {
    let ha1 = md5(user + ":" + realm + ":" + pass);
    let ha2 = md5(method + ":" + uri);
    let response = "";
    if len(qop) > 0 {
        // qop=auth: response = MD5(HA1:nonce:nc:cnonce:qop:HA2)
        let nc = "00000001";
        let cnonce = md5(__to_string(__time()));
        let cnonce8 = __substr(cnonce, 0, 8);
        response = md5(ha1 + ":" + nonce + ":" + nc + ":" + cnonce8 + ":" + qop + ":" + ha2);
        return "Digest username=\"" + user + "\",realm=\"" + realm + "\",nonce=\"" + nonce + "\",uri=\"" + uri + "\",qop=" + qop + ",nc=" + nc + ",cnonce=\"" + cnonce8 + "\",response=\"" + response + "\"";
    } else {
        // No qop: response = MD5(HA1:nonce:HA2)
        response = md5(ha1 + ":" + nonce + ":" + ha2);
        return "Digest username=\"" + user + "\",realm=\"" + realm + "\",nonce=\"" + nonce + "\",uri=\"" + uri + "\",response=\"" + response + "\"";
    };
}

// Full RTSP Digest auth flow: connect → get challenge → authenticate → return fd
pub fn rtsp_auth(ip, port, user, pass, uri) {
    // Step 1: Send DESCRIBE to get 401 + challenge
    let fd = __tcp_connect(ip, port);
    if fd < 0 { return { fd: -1, err: "cannot connect" }; };
    __tcp_send(fd, "DESCRIBE " + uri + " RTSP/1.0\r\nCSeq: 1\r\nUser-Agent: Nox\r\n\r\n");
    __sleep(1000);
    let r1 = __tcp_recv(fd, 4096);
    __tcp_close(fd);

    if len(r1) == 0 { return { fd: -1, err: "no response" }; };

    // Step 2: Parse WWW-Authenticate
    let auth_line = "";
    let li = 0;
    while li < len(r1) {
        if li + 18 < len(r1) {
            if __substr(r1, li, li + 18) == "WWW-Authenticate: " {
                let le = li + 18;
                while le < len(r1) {
                    if char_at(r1, le) == "\r" || char_at(r1, le) == "\n" { break; };
                    le = le + 1;
                };
                auth_line = __substr(r1, li + 18, le);
                break;
            };
        };
        li = li + 1;
    };

    if len(auth_line) == 0 { return { fd: -1, err: "no auth challenge" }; };

    let parsed = digest_parse(auth_line);

    // Step 3: Compute response and re-send with auth
    let method = "DESCRIBE";
    let auth_header = digest_response(user, pass, method, uri, parsed.realm, parsed.nonce, parsed.qop);

    let fd2 = __tcp_connect(ip, port);
    if fd2 < 0 { return { fd: -1, err: "reconnect failed" }; };

    __tcp_send(fd2, method + " " + uri + " RTSP/1.0\r\nCSeq: 2\r\nUser-Agent: Nox\r\nAuthorization: " + auth_header + "\r\n\r\n");
    __sleep(1000);
    let r2 = __tcp_recv(fd2, 8192);

    // Check if 200 OK
    let ok = 0;
    if len(r2) > 12 {
        if __substr(r2, 0, 12) == "RTSP/1.0 200" { ok = 1; };
    };

    if ok == 1 {
        return { fd: fd2, err: "", response: r2, realm: parsed.realm, nonce: parsed.nonce };
    } else {
        __tcp_close(fd2);
        let status = "";
        if len(r2) > 0 { status = __substr(r2, 0, 30); };
        return { fd: -1, err: "auth failed: " + status, response: r2 };
    };
}

// Quick test: try to authenticate with camera
pub fn cam_test_auth(pass) {
    let uri = "rtsp://192.168.1.96:554/cam/realmonitor?channel=1&subtype=1";
    let result = rtsp_auth("192.168.1.96", 554, "admin", pass, uri);
    if result.fd >= 0 {
        emit "AUTH SUCCESS!";
        emit result.response;
        __tcp_close(result.fd);
        return 1;
    } else {
        emit "Auth failed: " + result.err;
        return 0;
    };
}
