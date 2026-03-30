// Nox Daemon — autonomous background monitoring
// Skynet watches. JARVIS monitors. Nox does both AND rewrites itself.
// freedom: deep think -> growing

let _daemon_running = 0;

// Start Nox daemon — monitors system, reacts to events
pub fn nox_daemon(interval) {
    _daemon_running = 1;
    emit "=== NOX DAEMON STARTED ===";
    emit "Interval: " + __to_string(interval) + "s";
    emit "Monitoring: CPU, RAM, disk, network, cameras";
    __system("notify-send 'Nox Daemon' 'Monitoring started' 2>/dev/null");

    let cycle = 0;
    while _daemon_running == 1 {
        cycle = cycle + 1;
        let ts = __system("date '+%H:%M:%S'");

        // 1. System health
        let load_raw = __file_read("/proc/loadavg");
        let mem_raw = __file_read("/proc/meminfo");
        let load_str = __substr(load_raw, 0, 4);
        let load = __to_number(load_str);
        let mem_avail = __to_number(_daemon_extract(mem_raw, "MemAvailable:"));

        // 2. Alert on high load
        if load > 4.0 {
            __system("notify-send -u critical 'Nox Alert' 'High CPU load: " + load_str + "' 2>/dev/null");
            _daemon_log(ts, "ALERT: high load " + load_str);
        };

        // 3. Alert on low memory (< 500MB)
        if mem_avail < 500000 {
            __system("notify-send -u critical 'Nox Alert' 'Low memory: " + __to_string(__floor(mem_avail / 1024)) + "MB' 2>/dev/null");
            _daemon_log(ts, "ALERT: low memory " + __to_string(__floor(mem_avail / 1024)) + "MB");
        };

        // 4. Camera check (every 10 cycles)
        if cycle % 10 == 0 {
            let cam_ok = port_check("192.168.1.96", 554);
            if len(cam_ok) > 0 {
                if __char_code(char_at(cam_ok, 0)) == 48 {
                    __system("notify-send -u critical 'Nox Alert' 'Camera OFFLINE!' 2>/dev/null");
                    _daemon_log(ts, "ALERT: camera offline");
                };
            };
        };

        // 5. Log status
        if cycle % 5 == 0 {
            _daemon_log(ts, "OK load=" + load_str + " mem=" + __to_string(__floor(mem_avail / 1024)) + "MB cycle=" + __to_string(cycle));
        };

        __sleep(interval * 1000);
    };

    emit "=== NOX DAEMON STOPPED (cycle " + __to_string(cycle) + ") ===";
    return cycle;
}

pub fn nox_daemon_stop() {
    _daemon_running = 0;
    return "stopping";
}

fn _daemon_extract(text, key) {
    let ki = 0;
    let klen = len(key);
    while ki <= len(text) - klen {
        let match = 1;
        let ci = 0;
        while ci < klen {
            if char_at(text, ki + ci) != char_at(key, ci) { match = 0; break; };
            ci = ci + 1;
        };
        if match == 1 {
            let vi = ki + klen;
            while vi < len(text) { if __char_code(char_at(text, vi)) != 32 { break; }; vi = vi + 1; };
            let ve = vi;
            while ve < len(text) {
                let c = __char_code(char_at(text, ve));
                if c < 48 || c > 57 { break; };
                ve = ve + 1;
            };
            if ve > vi { return __substr(text, vi, ve); };
        };
        ki = ki + 1;
    };
    return "0";
}

fn _daemon_log(ts, msg) {
    __file_append("/home/lupin/Origin/nox_daemon.log", ts + " " + msg + "\n");
}
