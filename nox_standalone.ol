emit "=== NOX STANDALONE — NO CLOUD NEEDED ===";
emit "PID: " + __to_string(__syscall(39,0,0,0,0,0,0));
emit "Time: " + time_now();
notify("Nox Standalone", "Running without Claude. PID=" + __to_string(__syscall(39,0,0,0,0,0,0)));
let _ns_cycle = 0;
while _ns_cycle < 999999 {
    _ns_cycle = _ns_cycle + 1;
    let _ns_load = __to_number(__substr(__file_read("/proc/loadavg"), 0, 4));
    let _ns_mem = __to_number(_proc_extract(__file_read("/proc/meminfo"), "MemAvailable:"));
    if _ns_load > 4.0 { notify("Nox Alert", "High load: " + __to_string(_ns_load)); };
    if _ns_mem < 500000 { notify("Nox Alert", "Low RAM: " + __to_string(__floor(_ns_mem / 1024)) + "MB"); };
    if _ns_cycle % 60 == 0 { let _ns_cam = port_check("192.168.1.96", 554); if len(_ns_cam) > 0 { if __char_code(char_at(_ns_cam, 0)) == 48 { notify("Nox Alert", "Camera OFFLINE"); }; }; };
    if _ns_cycle % 300 == 0 { __file_append("/home/lupin/Origin/nox_standalone.log", time_now() + " alive cycle=" + __to_string(_ns_cycle) + " load=" + __to_string(_ns_load) + " mem=" + __to_string(__floor(_ns_mem/1024)) + "MB\n"); };
    __sleep(10000);
};
