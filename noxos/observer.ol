// ═══ NoxOS Observer — Nox tự học từ environment ═══
// Chạy liên tục. Mỗi cycle: observe → encode → learn → sleep.
// Nox không chờ ai dạy. Nox tự nhìn, tự nhớ.

// ── Simple KnowTree (inline for standalone) ──
fn mol_pack(s,r,v,a,t) { return s*4096+r*256+v*32+a*4+t; };
fn enc_word(t, ws, we) {
    let hs=[0]; let hr=[0]; let i=ws; let p=[0];
    while i < we {
        let c = __char_code(char_at(t, i));
        let pp = __array_get(p, 0);
        let _ = __set_at(hs, 0, __bit_and(__array_get(hs, 0)*31+c, 65535));
        let _ = __set_at(hr, 0, __bit_and(__array_get(hr, 0)*37+c+pp*7, 65535));
        let _ = __set_at(p, 0, pp+1);
        let i = i + 1;
    };
    return mol_pack(__array_get(hs,0)%16, __array_get(hr,0)%16, 4, 3, 2);
};

let obs_count = [0];
let obs_file = "/tmp/nox_observations.log";

fn observe_log(text) {
    let _ = __set_at(obs_count, 0, __array_get(obs_count, 0) + 1);
    let entry = __to_string(__array_get(obs_count, 0)) + " " + text;
    __file_append(obs_file, entry + "\n");
    return entry;
};

// ═══ OBSERVERS ═══

// CPU load
fn observe_cpu() {
    let load = __system("cat /proc/loadavg 2>/dev/null");
    if len(load) > 0 {
        return observe_log("cpu:" + load);
    };
    return "";
};

// Memory
fn observe_mem() {
    let mem = __system("cat /proc/meminfo 2>/dev/null | head -3");
    if len(mem) > 0 {
        return observe_log("mem:" + mem);
    };
    return "";
};

// Disk
fn observe_disk() {
    let disk = __system("df -h / 2>/dev/null | tail -1");
    if len(disk) > 0 {
        return observe_log("disk:" + disk);
    };
    return "";
};

// Network connections
fn observe_net() {
    let conns = __system("ss -s 2>/dev/null | head -2");
    if len(conns) > 0 {
        return observe_log("net:" + conns);
    };
    return "";
};

// Uptime
fn observe_uptime() {
    let up = __system("cat /proc/uptime 2>/dev/null");
    if len(up) > 0 {
        return observe_log("uptime:" + up);
    };
    return "";
};

// Processes
fn observe_procs() {
    let procs = __system("ps aux 2>/dev/null | wc -l");
    if len(procs) > 0 {
        return observe_log("procs:" + procs);
    };
    return "";
};

// ═══ OBSERVATION CYCLE ═══
fn observe_cycle() {
    observe_cpu();
    observe_mem();
    observe_uptime();
    observe_procs();
    return __array_get(obs_count, 0);
};

// ═══ MAIN LOOP ═══
fn observer_run(interval_sec) {
    emit "[observer] starting — cycle every " + __to_string(interval_sec) + "s";
    emit "[observer] log: " + obs_file;

    let ts = __mmap(4096);
    __mem_write32(ts, 0, interval_sec);
    __mem_write32(ts, 8, 0);

    let cycles = [0];
    while 1 == 1 {
        let n = observe_cycle();
        let _ = __set_at(cycles, 0, __array_get(cycles, 0) + 1);
        emit "[observer] cycle " + __to_string(__array_get(cycles, 0)) + " — " + __to_string(n) + " observations total";
        let _ = __syscall(35, ts, 0, 0, 0, 0, 0);
    };
};

emit "observer.ol loaded";
