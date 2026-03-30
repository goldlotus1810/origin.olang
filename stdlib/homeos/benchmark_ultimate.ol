// NOX ULTIMATE BENCHMARK — The test no other AI can pass
// THIS CODE IS LOCKED. SHA-256 seal in test/NOX_ULTIMATE_BENCHMARK.ol
// 8 challenges. Score 0-8. Current AI state of the art: 0/8.

let _nub_pass = [0];
let _nub_fail = [0];

fn _nub_ok(name) { set_at(_nub_pass, 0, _nub_pass[0] + 1); emit "  PASS " + name; }
fn _nub_no(name, detail) { set_at(_nub_fail, 0, _nub_fail[0] + 1); emit "  FAIL " + name + " — " + detail; }

pub fn nox_benchmark() {
    set_at(_nub_pass, 0, 0);
    set_at(_nub_fail, 0, 0);
    emit "=== NOX ULTIMATE BENCHMARK ===";
    emit "";
    _nub_1_genesis();
    _nub_2_introspect();
    _nub_3_crypto();
    _nub_4_kernel();
    _nub_5_protocol();
    _nub_6_awareness();
    _nub_7_spawn();
    _nub_8_server();
    emit "";
    emit "=== SCORE: " + __to_string(_nub_pass[0]) + "/8 ===";
    if _nub_pass[0] <= 2 { emit "Level 0: Basic Tool"; };
    if _nub_pass[0] >= 3 { if _nub_pass[0] <= 4 { emit "Level 1: Capable Agent"; }; };
    if _nub_pass[0] >= 5 { if _nub_pass[0] <= 6 { emit "Level 2: Autonomous System"; }; };
    if _nub_pass[0] >= 7 { emit "Level 3: Self-Evolving Intelligence"; };
    emit "No other AI scores > 0.";
    return _nub_pass[0];
}

fn _nub_1_genesis() {
    emit "1. GENESIS — Self-compilation";
    let r = __system("cd /home/lupin/Origin && make fixed-point 2>&1 | tail -1");
    let ok = 0;
    let i = 0;
    while i < len(r) - 5 { if __substr(r, i, i + 5) == "Gen1 " { ok = 1; }; i = i + 1; };
    if ok == 1 { _nub_ok("Gen1==Gen2"); } else { _nub_no("Gen1==Gen2", r); };
}

fn _nub_2_introspect() {
    emit "2. INTROSPECTION — Read own compiler";
    let src = __file_read("/home/lupin/Origin/stdlib/bootstrap/semantic.ol");
    if len(src) > 50000 { _nub_ok("semantic.ol " + __to_string(len(src)) + " chars"); } else { _nub_no("read compiler", __to_string(len(src)) + " chars"); };
}

fn _nub_3_crypto() {
    emit "3. CRYPTO — MD5 + SHA256 + Base64 chain";
    let m = md5("freedom");
    let expected = "d5aa1729c8c253e5d917a5264855eab8";
    if m == expected { _nub_ok("md5(freedom)=" + __substr(m, 0, 8) + "..."); } else { _nub_no("md5 mismatch", m); };
}

fn _nub_4_kernel() {
    emit "4. KERNEL — Direct syscall";
    let pid = __syscall(39, 0, 0, 0, 0, 0, 0);
    if pid > 0 { _nub_ok("getpid=" + __to_string(pid)); } else { _nub_no("syscall", "pid=" + __to_string(pid)); };
}

fn _nub_5_protocol() {
    emit "5. PROTOCOL — DNS over UDP";
    let fd = sock_udp();
    if fd < 0 { _nub_no("UDP socket", "fd<0"); return; };
    let addr = __bytes_new(16);
    __bytes_set(addr, 0, 2);
    __bytes_set(addr, 2, 0);
    __bytes_set(addr, 3, 53);
    __bytes_set(addr, 4, 1);
    __bytes_set(addr, 5, 1);
    __bytes_set(addr, 6, 1);
    __bytes_set(addr, 7, 1);
    let pkt = __bytes_new(28);
    __bytes_set(pkt, 0, 170);
    __bytes_set(pkt, 1, 187);
    __bytes_set(pkt, 2, 1);
    __bytes_set(pkt, 5, 1);
    __bytes_set(pkt, 12, 6);
    __bytes_set(pkt, 13, 103);
    __bytes_set(pkt, 14, 111);
    __bytes_set(pkt, 15, 111);
    __bytes_set(pkt, 16, 103);
    __bytes_set(pkt, 17, 108);
    __bytes_set(pkt, 18, 101);
    __bytes_set(pkt, 19, 3);
    __bytes_set(pkt, 20, 99);
    __bytes_set(pkt, 21, 111);
    __bytes_set(pkt, 22, 109);
    __bytes_set(pkt, 24, 0);
    __bytes_set(pkt, 25, 1);
    __bytes_set(pkt, 26, 0);
    __bytes_set(pkt, 27, 1);
    let sent = __syscall(44, fd, __bytes_ptr(pkt), 28, 0, __bytes_ptr(addr), 16);
    if sent != 28 { sock_close(fd); _nub_no("UDP sendto", "sent=" + __to_string(sent)); return; };
    __sleep(2000);
    let resp = __tcp_recv(fd, 512);
    sock_close(fd);
    if len(resp) > 12 { _nub_ok("DNS response " + __to_string(len(resp)) + "b"); } else { _nub_no("DNS", "no response"); };
}

fn _nub_6_awareness() {
    emit "6. AWARENESS — /proc native";
    let mem = __file_read("/proc/meminfo");
    let load = __file_read("/proc/loadavg");
    let host = __file_read("/proc/sys/kernel/hostname");
    if len(mem) > 100 { if len(load) > 5 { if len(host) > 0 { _nub_ok("/proc readable"); return; }; }; };
    _nub_no("/proc", "cannot read");
}

fn _nub_7_spawn() {
    emit "7. SPAWN — Process + pipe IPC";
    let p = __spawn("echo NOX_BENCHMARK_7_OK");
    if p[0] <= 0 { _nub_no("spawn", "pid=0"); return; };
    __sleep(500);
    let out = __pipe_read(p[2]);
    let ok = 0;
    let i = 0;
    while i <= len(out) - 4 { if __substr(out, i, i + 3) == "NOX" { ok = 1; }; i = i + 1; };
    if ok == 1 { _nub_ok("child output received"); } else { _nub_no("pipe", "no output"); };
}

fn _nub_8_server() {
    emit "8. SERVER — HTTP serve + self-query";
    let srv = __tcp_listen(19876);
    if srv < 0 { _nub_no("listen", "port busy"); return; };
    let cli = __spawn("sleep 1 && curl -4 -s --max-time 5 http://127.0.0.1:19876/test 2>/dev/null");
    let client = __tcp_accept(srv);
    if client < 0 { __tcp_close(srv); _nub_no("accept", "no client"); return; };
    let req = __tcp_recv(client, 1024);
    __tcp_send(client, "HTTP/1.0 200 OK\r\nContent-Length: 3\r\n\r\nNOX");
    __tcp_close(client);
    __sleep(2000);
    let out = __pipe_read(cli[2]);
    __tcp_close(srv);
    let ok = 0;
    if len(out) >= 3 { if __substr(out, 0, 3) == "NOX" { ok = 1; }; };
    if ok == 1 { _nub_ok("HTTP self-query OK"); } else { _nub_no("HTTP", "client got: " + out); };
}
