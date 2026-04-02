// ═══ Nox System Monitor — reads /proc, reports system status ═══
// Demonstrates: file I/O, string processing, regex, structs, closures

import "../stdlib/regex.ol";

fn read_file(path) {
    let data = __file_read(path);
    return data;
};

fn get_uptime() {
    let data = read_file("/proc/uptime");
    if len(data) > 0 {
        // First number is uptime in seconds
        let i = 0;
        while i < len(data) {
            if __char_code(char_at(data, i)) == 32 { break; };
            let i = i + 1;
        };
        let secs = __str_to_num(substr(data, 0, i));
        let hours = __floor(secs / 3600);
        let mins = __floor((secs - hours * 3600) / 60);
        return __to_string(hours) + "h " + __to_string(mins) + "m";
    };
    return "unknown";
};

fn get_memory() {
    let data = read_file("/proc/meminfo");
    if len(data) == 0 { return {total: 0, free: 0, available: 0}; };
    // Parse MemTotal, MemFree, MemAvailable
    let result = {total: 0, free: 0, available: 0};
    let lines = __str_split(data, 10); // split by newline
    let i = 0;
    while i < len(lines) {
        let line = lines[i];
        if __str_starts_with(line, "MemTotal:") == 1 {
            result.total = _parse_kb(line);
        };
        if __str_starts_with(line, "MemFree:") == 1 {
            result.free = _parse_kb(line);
        };
        if __str_starts_with(line, "MemAvailable:") == 1 {
            result.available = _parse_kb(line);
        };
        let i = i + 1;
    };
    return result;
};

fn _parse_kb(line) {
    // Extract number from "MemTotal:     8012340 kB"
    let i = 0;
    // Skip to first digit
    while i < len(line) {
        let c = __char_code(char_at(line, i));
        if c >= 48 { if c <= 57 { break; }; };
        let i = i + 1;
    };
    let start = i;
    while i < len(line) {
        let c = __char_code(char_at(line, i));
        if c < 48 || c > 57 { break; };
        let i = i + 1;
    };
    return __str_to_num(substr(line, start, i));
};

fn get_loadavg() {
    let data = read_file("/proc/loadavg");
    if len(data) > 0 {
        // First 3 numbers: 1min 5min 15min
        let parts = __str_split(data, 32); // split by space
        if len(parts) >= 3 {
            return parts[0] + " " + parts[1] + " " + parts[2];
        };
    };
    return "unknown";
};

fn get_cpu_count() {
    let data = read_file("/proc/cpuinfo");
    let count = [0];
    let lines = __str_split(data, 10);
    let i = 0;
    while i < len(lines) {
        if __str_starts_with(lines[i], "processor") == 1 {
            count[0] = count[0] + 1;
        };
        let i = i + 1;
    };
    return count[0];
};

// ═══ Main ═══
emit "═══ Nox System Monitor ═══";
emit "";
emit "Uptime:    " + get_uptime();
emit "Load:      " + get_loadavg();
emit "CPUs:      " + __to_string(get_cpu_count());

let mem = get_memory();
let total_gb = __round(mem.total / 1048576 * 100) / 100;
let used_gb = __round((mem.total - mem.available) / 1048576 * 100) / 100;
let pct = __round((mem.total - mem.available) / mem.total * 100);
emit "Memory:    " + __to_string(used_gb) + " / " + __to_string(total_gb) + " GB (" + __to_string(pct) + "%)";

emit "";
emit "Nox VM:    " + __to_string(__heap_used()) + " bytes heap";
emit "═══════════════════════════";
