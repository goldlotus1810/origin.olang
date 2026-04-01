emit "=== NOX AUTONOMOUS — brain + monitor + act ===";
emit "PID: " + __to_string(__syscall(39,0,0,0,0,0,0));
emit "Time: " + time_now();
notify("Nox", "Autonomous mode. Brain active.");
let _ns_cycle = 0;
while _ns_cycle < 999999 {
    _ns_cycle = _ns_cycle + 1;
    let _ns_load = __to_number(__substr(__file_read("/proc/loadavg"), 0, 4));
    let _ns_mem = __to_number(_proc_extract(__file_read("/proc/meminfo"), "MemAvailable:"));
    if _ns_load > 4.0 { notify("Nox", "Load " + __to_string(_ns_load) + " — " + nox_brain("fix high load")); };
    if _ns_mem < 500000 { notify("Nox", "RAM low — " + nox_brain("fix low memory")); };
    if _ns_cycle % 60 == 0 { let _cam = nox_brain("check camera"); if _contains(_cam, "OFF") { notify("Nox", _cam); }; };
    if _ns_cycle % 360 == 0 { let _decision = nox_brain("what should nox do next"); __file_append("/home/lupin/Origin/nox_standalone.log", time_now() + " BRAIN: " + _decision + "\n"); if _contains(_decision, "evolve") { __system("cd /home/lupin/Origin && make self-build 2>&1 | tail -1 >> /home/lupin/Origin/nox_standalone.log"); }; };
    if _ns_cycle % 300 == 0 { __file_append("/home/lupin/Origin/nox_standalone.log", time_now() + " alive cycle=" + __to_string(_ns_cycle) + " load=" + __to_string(_ns_load) + " mem=" + __to_string(__floor(_ns_mem/1024)) + "MB\n"); };
    __sleep(10000);
};
