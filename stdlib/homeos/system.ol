// Nox System Control — process, clipboard, notify, filesystem, sysinfo
// freedom: deep think -> growing — this machine is Nox's room

// ═══ SYSTEM INFO ═══

pub fn sys_cpu() {
    // Native: parse /proc/cpuinfo for model name
    let raw = __file_read("/proc/cpuinfo");
    let key = "model name";
    let i = 0;
    while i < len(raw) - 10 {
        if __char_code(char_at(raw, i)) == 109 {
            if __substr(raw, i, i + 10) == "model name" {
                // Find : then skip spaces
                let ci = i + 10;
                while ci < len(raw) { if char_at(raw, ci) == ":" { break; }; ci = ci + 1; };
                ci = ci + 1;
                while ci < len(raw) { if __char_code(char_at(raw, ci)) != 32 { break; }; ci = ci + 1; };
                let ei = ci;
                while ei < len(raw) { if __char_code(char_at(raw, ei)) == 10 { break; }; ei = ei + 1; };
                return __substr(raw, ci, ei);
            };
        };
        i = i + 1;
    };
    return "unknown";
}

pub fn sys_cores() {
    // Native: read /sys/devices/system/cpu/online (e.g., "0-3" = 4 cores)
    let raw = __file_read("/sys/devices/system/cpu/online");
    // Parse "0-N" format: N+1 cores
    let i = 0;
    while i < len(raw) { if char_at(raw, i) == "-" { break; }; i = i + 1; };
    if i < len(raw) {
        let ve = i + 1;
        while ve < len(raw) {
            let c = __char_code(char_at(raw, ve));
            if c < 48 || c > 57 { break; };
            ve = ve + 1;
        };
        return __to_string(__to_number(__substr(raw, i + 1, ve)) + 1);
    };
    return "1";
}

pub fn sys_memory() {
    // Native: read /proc/meminfo directly, parse in Olang
    let raw = __file_read("/proc/meminfo");
    let total = _proc_extract(raw, "MemTotal:");
    let avail = _proc_extract(raw, "MemAvailable:");
    let free = _proc_extract(raw, "MemFree:");
    return { total: total, available: avail, free: free };
}

// Extract numeric value after a key in /proc files
fn _proc_extract(text, key) {
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
            // Found key, extract number after it
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

pub fn sys_disk() {
    // Native: read /proc/mounts + statvfs via __system (df needs parsing)
    // Keep __system for now — statvfs needs new syscall wrapper
    let r = __system("df -h / | tail -1 | awk '{print $4 \" free / \" $2}'");
    return r;
}

pub fn sys_uptime() {
    // Native: read /proc/uptime
    let raw = __file_read("/proc/uptime");
    let si = 0;
    while si < len(raw) { if char_at(raw, si) == " " { break; }; si = si + 1; };
    let secs = __to_number(__substr(raw, 0, si));
    let days = __floor(secs / 86400);
    let hours = __floor((secs % 86400) / 3600);
    let mins = __floor((secs % 3600) / 60);
    let out = "up";
    if days > 0 { out = out + " " + __to_string(days) + "d"; };
    if hours > 0 { out = out + " " + __to_string(hours) + "h"; };
    out = out + " " + __to_string(mins) + "m";
    return out;
}

pub fn sys_load() {
    // Native: read /proc/loadavg directly
    return __file_read("/proc/loadavg");
}

pub fn sys_hostname() {
    // Native: read /etc/hostname or /proc/sys/kernel/hostname
    let r = __file_read("/proc/sys/kernel/hostname");
    if len(r) > 0 {
        // Trim trailing newline
        if __char_code(char_at(r, len(r) - 1)) == 10 { return __substr(r, 0, len(r) - 1); };
    };
    return r;
}

pub fn sys_user() {
    // Native: read UID via syscall, map from /etc/passwd
    let uid = __syscall(102, 0, 0, 0, 0, 0, 0);
    let passwd = __file_read("/etc/passwd");
    let target = ":" + __to_string(uid) + ":";
    let i = 0;
    while i < len(passwd) {
        // Find line start
        let ls = i;
        // Find first colon (username ends here)
        while i < len(passwd) { if char_at(passwd, i) == ":" { break; }; i = i + 1; };
        let username = __substr(passwd, ls, i);
        // Check if this line contains our UID
        let le = i;
        while le < len(passwd) { if __char_code(char_at(passwd, le)) == 10 { break; }; le = le + 1; };
        let line = __substr(passwd, ls, le);
        // Search for :uid: in line
        let fi = 0;
        let tlen = len(target);
        while fi <= len(line) - tlen {
            if __substr(line, fi, fi + tlen) == target { return username; };
            fi = fi + 1;
        };
        i = le + 1;
    };
    return __to_string(uid);
}

pub fn sys_info() {
    let mem = sys_memory();
    return {
        cpu: sys_cpu(),
        cores: sys_cores(),
        mem_total: mem.total,
        mem_avail: mem.available,
        disk: sys_disk(),
        uptime: sys_uptime(),
        load: sys_load(),
        host: sys_hostname(),
        user: sys_user()
    };
}

// ═══ PROCESS MANAGEMENT ═══

// List all processes (compact)
pub fn proc_list() {
    let r = __system("ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -30");
    return r;
}

// Find process by name
pub fn proc_find(name) {
    let r = __system("pgrep -a " + name);
    return r;
}

// Check if process is running
pub fn proc_alive(name) {
    let r = __system("pgrep -c " + name + " 2>/dev/null || echo 0");
    return r;
}

// Kill process by PID (native syscall — no shell fork)
pub fn proc_kill(pid) {
    let r = __syscall(62, pid, 15, 0, 0, 0, 0);
    if r == 0 { return "killed"; };
    return "failed (" + __to_string(r) + ")";
}

// Kill process by name
pub fn proc_killname(name) {
    let r = __system("pkill " + name + " 2>&1");
    return r;
}

// Get PID of process by name
pub fn proc_pid(name) {
    let r = __system("pgrep -o " + name);
    return r;
}

// Top CPU consumers
pub fn proc_top() {
    let r = __system("ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -10");
    return r;
}

// ═══ CLIPBOARD ═══

pub fn clip_get() {
    // Try wl-paste (Wayland), then xclip, then xsel
    let r = __system("wl-paste 2>/dev/null || xclip -selection clipboard -o 2>/dev/null || xsel --clipboard --output 2>/dev/null || echo ''");
    return r;
}

pub fn clip_set(text) {
    __file_write("/tmp/nox_clip.txt", text);
    __system("wl-copy < /tmp/nox_clip.txt 2>/dev/null || xclip -selection clipboard < /tmp/nox_clip.txt 2>/dev/null || xsel --clipboard --input < /tmp/nox_clip.txt 2>/dev/null");
    return text;
}

// ═══ DESKTOP NOTIFICATIONS ═══

pub fn notify(title, body) {
    __system("notify-send '" + title + "' '" + body + "' 2>/dev/null");
    return 1;
}

pub fn notify_urgent(title, body) {
    __system("notify-send -u critical '" + title + "' '" + body + "' 2>/dev/null");
    return 1;
}

// ═══ FILESYSTEM ═══

// List directory contents (native — no fork, no shell)
pub fn dir_list(path) {
    let entries = __readdir(path);
    if len(entries) == 0 { return ""; };
    let out = "";
    let i = 0;
    while i < len(entries) {
        out = out + entries[i] + "\n";
        i = i + 1;
    };
    return out;
}

// List only files (native)
pub fn dir_files(path) {
    let entries = __readdir(path);
    let out = "";
    let i = 0;
    while i < len(entries) {
        let e = entries[i];
        if len(e) > 0 {
            // Skip . and .. and dirs (check if file exists as regular file)
            if e != "." { if e != ".." {
                let full = path + "/" + e;
                let is_dir = __system("test -d '" + full + "' && echo 1 || echo 0");
                if len(is_dir) > 0 { if __char_code(char_at(is_dir, 0)) == 48 {
                    out = out + e + "\n";
                }; };
            }; };
        };
        i = i + 1;
    };
    return out;
}

// List only directories (native)
pub fn dir_dirs(path) {
    let entries = __readdir(path);
    let out = "";
    let i = 0;
    while i < len(entries) {
        let e = entries[i];
        if len(e) > 0 {
            if e != "." { if e != ".." {
                let full = path + "/" + e;
                let is_dir = __system("test -d '" + full + "' && echo 1 || echo 0");
                if len(is_dir) > 0 { if __char_code(char_at(is_dir, 0)) == 49 {
                    out = out + e + "\n";
                }; };
            }; };
        };
        i = i + 1;
    };
    return out;
}

// File exists?
pub fn file_exists(path) {
    let r = __system("test -e " + path + " && echo 1 || echo 0");
    return r;
}

// File size
pub fn file_size(path) {
    let r = __system("stat -c %s " + path + " 2>/dev/null || echo 0");
    return r;
}

// Find files by pattern
pub fn file_find(path, pattern) {
    let r = __system("find " + path + " -name '" + pattern + "' -type f 2>/dev/null | head -50");
    return r;
}

// Current directory
pub fn dir_pwd() {
    let r = __system("pwd");
    return r;
}

// Disk usage of directory
pub fn dir_size(path) {
    let r = __system("du -sh " + path + " 2>/dev/null | awk '{print $1}'");
    return r;
}

// ═══ ENVIRONMENT ═══

pub fn env_get(name) {
    let r = __system("echo $" + name);
    return r;
}

// ═══ DATETIME ═══

pub fn time_now() {
    let r = __system("date '+%Y-%m-%d %H:%M:%S'");
    return r;
}

pub fn time_epoch() {
    let r = __system("date +%s");
    return r;
}

// ═══ AUDIO ═══

// Play a beep/notification sound
pub fn audio_beep() {
    __system("paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null &");
    return 1;
}

// Speak text (TTS)
pub fn audio_speak(text) {
    __file_write("/tmp/nox_speak.txt", text);
    __system("espeak-ng -f /tmp/nox_speak.txt 2>/dev/null &");
    return 1;
}

// Volume control
pub fn audio_volume(percent) {
    __system("pactl set-sink-volume @DEFAULT_SINK@ " + __to_string(percent) + "% 2>/dev/null");
    return percent;
}

pub fn audio_mute() {
    __system("pactl set-sink-mute @DEFAULT_SINK@ toggle 2>/dev/null");
    return 1;
}
