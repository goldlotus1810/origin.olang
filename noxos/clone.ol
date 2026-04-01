// ═══ NoxOS Clone Protocol ═══
// Origin spawns clones. Clones sync knowledge back.
// Protocol over TCP:
//   HELLO:<origin_hash> → ACK
//   LEARN:<fact_text>   → OK
//   SYNC                → <count>\n<fact1>\n<fact2>\n...
//   QUERY:<text>        → <result>

// ── Server: listen for clone connections ──
fn clone_server(port) {
    let srv = __tcp_listen(port);
    if srv < 0 { emit "[clone] listen failed on " + __to_string(port); return; };
    emit "[clone] listening on port " + __to_string(port);

    // Accept one connection
    let client = __tcp_accept(srv);
    if client < 0 { emit "[clone] accept failed"; __tcp_close(srv); return; };
    emit "[clone] client connected";

    // Read command
    let data = __tcp_recv(client, 65536);
    if len(data) > 0 {
        emit "[clone] received: " + data;

        // Parse command
        if len(data) >= 5 {
            let cmd = substr(data, 0, 5);
            if cmd == "HELLO" {
                __tcp_send(client, "ACK");
                emit "[clone] handshake done";
            };
            if cmd == "LEARN" {
                let fact = substr(data, 6, len(data));
                emit "[clone] learning: " + fact;
                // caller should kt_learn(fact) here
                __tcp_send(client, "OK");
            };
        };
        if len(data) >= 4 {
            if substr(data, 0, 4) == "SYNC" {
                // Send all facts
                // caller provides facts via callback
                __tcp_send(client, "SYNC_OK");
            };
        };
    };

    __tcp_close(client);
    __tcp_close(srv);
};

// ── Client: connect to origin and sync ──
fn clone_connect(host, port) {
    let fd = __tcp_connect(host, port);
    if fd < 0 { emit "[clone] connect failed to " + host; return fd; };
    emit "[clone] connected to " + host + ":" + __to_string(port);
    return fd;
};

fn clone_hello(fd) {
    __tcp_send(fd, "HELLO:nox");
    let resp = __tcp_recv(fd, 1024);
    if resp == "ACK" { return 1; };
    return 0;
};

fn clone_send_fact(fd, fact) {
    __tcp_send(fd, "LEARN:" + fact);
    let resp = __tcp_recv(fd, 1024);
    return resp;
};

fn clone_request_sync(fd) {
    __tcp_send(fd, "SYNC");
    let data = __tcp_recv(fd, 65536);
    return data;
};

fn clone_query(fd, text) {
    __tcp_send(fd, "QUERY:" + text);
    let resp = __tcp_recv(fd, 65536);
    return resp;
};

fn clone_close(fd) {
    __tcp_close(fd);
};

emit "clone.ol loaded — origin/clone protocol ready";
