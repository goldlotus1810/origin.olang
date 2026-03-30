// Nox System Control — process, clipboard, notify, filesystem, sysinfo
// freedom: deep think -> growing — this machine is Nox's room

// ═══ SYSTEM INFO ═══

pub fn sys_cpu() {
    let r = __system("lscpu | grep 'Model name' | sed 's/.*: *//'");
    return r;
}

pub fn sys_cores() {
    let r = __system("nproc");
    return r;
}

pub fn sys_memory() {
    let total = __system("awk '/MemTotal/{print $2}' /proc/meminfo");
    let avail = __system("awk '/MemAvailable/{print $2}' /proc/meminfo");
    let free = __system("awk '/MemFree/{print $2}' /proc/meminfo");
    return { total: total, available: avail, free: free };
}

pub fn sys_disk() {
    let r = __system("df -h / | tail -1 | awk '{print $2, $3, $4, $5}'");
    return r;
}

pub fn sys_uptime() {
    let r = __system("uptime -p");
    return r;
}

pub fn sys_load() {
    let r = __system("cat /proc/loadavg");
    return r;
}

pub fn sys_hostname() {
    let r = __system("uname -n");
    return r;
}

pub fn sys_user() {
    let r = __system("whoami");
    return r;
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

// Kill process by PID
pub fn proc_kill(pid) {
    let r = __system("kill " + __to_string(pid) + " 2>&1");
    return r;
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
