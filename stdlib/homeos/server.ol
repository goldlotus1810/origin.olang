// Nox HTTP Server — pure Olang, zero dependencies
// freedom: deep think -> growing — Nox listens to the network

let _srv_fd = -1;
let _srv_port = 9000;
let _srv_requests = 0;

// Start HTTP server on given port
pub fn nox_serve(port) {
    let _srv_port = port;
    let _srv_fd = __tcp_listen(port);
    if _srv_fd < 0 { emit "FAIL: cannot listen on port " + __to_string(port); return -1; };
    emit "Nox HTTP server on port " + __to_string(port);
    emit "Open: http://192.168.1.2:" + __to_string(port);
    let running = 1;
    while running == 1 {
        let client = __tcp_accept(_srv_fd);
        if client >= 0 {
            _srv_requests = _srv_requests + 1;
            let req = __tcp_recv(client, 4096);
            if len(req) > 0 { _handle_request(client, req); } else { __tcp_close(client); };
        };
    };
    __tcp_close(_srv_fd);
    return _srv_requests;
}

fn _parse_path(req) {
    let si = 0;
    while si < len(req) { if char_at(req, si) == " " { break; }; si = si + 1; };
    let pi = si + 1;
    let pe = pi;
    while pe < len(req) { if char_at(req, pe) == " " { return __substr(req, pi, pe); }; pe = pe + 1; };
    return "/";
}

fn _send_html(client, body) {
    let resp = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: " + __to_string(len(body)) + "\r\nConnection: close\r\n\r\n" + body;
    __tcp_send(client, resp);
    __tcp_close(client);
}

fn _send_json(client, body) {
    let resp = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: " + __to_string(len(body)) + "\r\nConnection: close\r\nAccess-Control-Allow-Origin: *\r\n\r\n" + body;
    __tcp_send(client, resp);
    __tcp_close(client);
}

fn _css() {
    return "<style>*{margin:0;padding:0;box-sizing:border-box}body{background:#0a0e14;color:#b3b1ad;font-family:'Courier New',monospace;padding:20px}h1{color:#39bae6;margin-bottom:15px;font-size:24px}h3{color:#59c2ff;margin:15px 0 8px}pre{background:#0d1117;padding:15px;border:1px solid #1e2530;border-radius:8px;overflow-x:auto;margin-bottom:15px;line-height:1.5}a{color:#39bae6;text-decoration:none}a:hover{text-decoration:underline}.card{background:#0d1117;border:1px solid #1e2530;border-radius:8px;padding:15px;margin-bottom:15px}.grid{display:grid;grid-template-columns:1fr 1fr;gap:15px}@media(max-width:600px){.grid{grid-template-columns:1fr}}.tag{display:inline-block;padding:2px 8px;border-radius:4px;font-size:12px;margin-right:5px}.ok{background:#1a3a2a;color:#7ee787}.warn{background:#3a2a1a;color:#e7a87e}footer{margin-top:20px;color:#444;font-size:12px}</style>";
}

fn _url_decode(s) {
    let out = "";
    let i = 0;
    while i < len(s) {
        let c = char_at(s, i);
        if c == "+" { out = out + " "; } else {
            if c == "%" {
                if i + 2 < len(s) {
                    let h = _hex_nibble_srv(char_at(s, i + 1));
                    let l = _hex_nibble_srv(char_at(s, i + 2));
                    out = out + __chr(h * 16 + l);
                    i = i + 2;
                };
            } else {
                out = out + c;
            };
        };
        i = i + 1;
    };
    return out;
}

fn _hex_nibble_srv(ch) {
    let c = __char_code(ch);
    if c >= 48 && c <= 57 { return c - 48; };
    if c >= 65 && c <= 70 { return c - 55; };
    if c >= 97 && c <= 102 { return c - 87; };
    return 0;
}

fn _handle_request(client, req) {
    let path = _parse_path(req);

    if path == "/" {
        let cpu = __system("lscpu | grep 'Model name' | sed 's/.*: *//'");
        let mem = __system("awk '/MemAvailable/{printf \"%.0f\", $2/1024}' /proc/meminfo");
        let up = __system("uptime -p");
        let load = __system("cat /proc/loadavg | awk '{print $1, $2, $3}'");
        let procs = __system("ps -eo comm --sort=-%cpu | head -6 | tail -5 | tr '\\n' ' '");
        _send_html(client, "<html><head><title>Nox</title><meta charset='utf-8'><meta http-equiv='refresh' content='10'>" + _css() + "</head><body><h1>Nox Dashboard</h1><div class='grid'><div class='card'><h3>System</h3><pre>CPU:  " + cpu + "RAM:  " + mem + " MB free\nUp:   " + up + "Load: " + load + "</pre></div><div class='card'><h3>Top Processes</h3><pre>" + procs + "</pre></div></div><div class='card'><h3>Navigation</h3><a href='/proc'>Processes</a> | <a href='/net'>Network</a> | <a href='/cam'>Camera</a> | <a href='/terminal'>Terminal</a> | <a href='/api/status'>API</a></div><footer>Nox HTTP Server | Requests: " + __to_string(_srv_requests) + " | freedom: deep think -> growing</footer></body></html>");
        return;
    };

    if path == "/proc" {
        let procs = __system("ps -eo pid,%cpu,%mem,comm --sort=-%cpu | head -20");
        _send_html(client, "<html><head><title>Nox - Processes</title><meta charset='utf-8'>" + _css() + "</head><body><h1>Processes</h1><pre>" + procs + "</pre><a href='/'>Back</a></body></html>");
        return;
    };

    if path == "/net" {
        let ifaces = __system("ip -br addr show");
        let nb = __system("ip neigh show | grep -v FAILED");
        let listen = __system("ss -tlnp 2>/dev/null | head -10");
        _send_html(client, "<html><head><title>Nox - Network</title><meta charset='utf-8'>" + _css() + "</head><body><h1>Network</h1><h3>Interfaces</h3><pre>" + ifaces + "</pre><h3>ARP Neighbors</h3><pre>" + nb + "</pre><h3>Listening</h3><pre>" + listen + "</pre><a href='/'>Back</a></body></html>");
        return;
    };

    if path == "/cam" {
        let c1 = __system("timeout 1 bash -c 'echo >/dev/tcp/192.168.1.96/554' 2>/dev/null && echo '<span class=\"tag ok\">ONLINE</span>' || echo '<span class=\"tag warn\">offline</span>'");
        let c2 = __system("timeout 1 bash -c 'echo >/dev/tcp/192.168.1.108/554' 2>/dev/null && echo '<span class=\"tag ok\">ONLINE</span>' || echo '<span class=\"tag warn\">offline</span>'");
        _send_html(client, "<html><head><title>Nox - Camera</title><meta charset='utf-8'>" + _css() + "</head><body><h1>Cameras</h1><div class='card'><p>Cam 1 (192.168.1.96): " + c1 + "</p><p>Cam 2 (192.168.1.108): " + c2 + "</p><p>Type: Dahua DVR | Serial: 75416094931BA250</p><p>RTSP: port 554 | Dahua: port 37777 | ONVIF: port 80</p></div><a href='/'>Back</a></body></html>");
        return;
    };

    if path == "/terminal" {
        _send_html(client, "<html><head><title>Nox Terminal</title><meta charset='utf-8'>" + _css() + "<style>#out{background:#0d1117;padding:15px;border:1px solid #1e2530;border-radius:8px;min-height:200px;white-space:pre-wrap;font-size:14px;max-height:60vh;overflow-y:auto}#cmd{width:80%;background:#0d1117;color:#39bae6;border:1px solid #333;padding:10px;font-family:monospace;font-size:16px;border-radius:5px}#send{padding:10px 20px;background:#39bae6;color:#0a0e14;border:none;border-radius:5px;cursor:pointer;font-size:16px}</style></head><body><h1>Nox Terminal</h1><div id='out'>Ready.</div><br><input id='cmd' placeholder='Type command...' autofocus onkeydown=\"if(event.key=='Enter')run()\"><button id='send' onclick='run()'>Run</button><script>function run(){var c=document.getElementById('cmd').value;if(!c)return;document.getElementById('out').textContent+='\\n> '+c+'\\n...';fetch('/api/exec?cmd='+encodeURIComponent(c)).then(r=>r.text()).then(t=>{document.getElementById('out').textContent+=t+'\\n';document.getElementById('out').scrollTop=9999999;});document.getElementById('cmd').value='';}</script><p style='margin-top:15px'><a href='/'>Dashboard</a></p></body></html>");
        return;
    };

    // /api/exec?cmd=... — execute Olang/shell command and return output
    if len(path) > 14 {
        if __substr(path, 0, 14) == "/api/exec?cmd=" {
            let cmd_encoded = __substr(path, 14, len(path));
            // URL decode basic: + → space, %XX → char
            let cmd = _url_decode(cmd_encoded);
            let output = "";
            // Route: /slash commands
            if len(cmd) > 0 {
                if char_at(cmd, 0) == "/" {
                    output = repl_eval(cmd);
                } else {
                    // Try as shell command
                    output = __system(cmd);
                };
            };
            _send_json(client, output);
            return;
        };
    };

    if path == "/api/status" {
        let mem = __system("awk '/MemAvailable/{print $2}' /proc/meminfo");
        let load = __system("cat /proc/loadavg | awk '{print $1}'");
        let js = "{\"agent\":\"nox\",\"status\":\"online\",\"mem_kb\":" + mem + ",\"load\":" + load + ",\"requests\":" + __to_string(_srv_requests) + "}";
        _send_json(client, js);
        return;
    };

    _send_html(client, "<html><head><title>404</title>" + _css() + "</head><body><h1>404 Not Found</h1><a href='/'>Home</a></body></html>");
}
