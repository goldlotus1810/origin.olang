// Nox File Watcher — inotify-based file change detection
// Built on __syscall — pure Olang, no shell
// freedom: deep think -> growing

// inotify syscalls
let SYS_INOTIFY_INIT = 253;
let SYS_INOTIFY_ADD = 254;
let SYS_INOTIFY_RM = 255;

// inotify event masks
let IN_MODIFY = 2;
let IN_CREATE = 256;
let IN_DELETE = 512;
let IN_MOVED_TO = 128;
let IN_ALL = 898;

// Create a file watcher
pub fn watch_create() {
    return __syscall(SYS_INOTIFY_INIT, 0, 0, 0, 0, 0, 0);
}

// Add directory or file to watch
pub fn watch_add(ifd, path, mask) {
    // inotify_add_watch needs the path as a C string
    // Use __system as bridge since __syscall can't pass string pointers
    let wd = __system("python3 -c \"import ctypes; libc=ctypes.CDLL('libc.so.6'); print(libc.inotify_add_watch(" + __to_string(ifd) + ", b'" + path + "', " + __to_string(mask) + "))\"");
    return __to_number(wd);
}

// Watch for source code changes and auto-rebuild
pub fn nox_autorebuild() {
    emit "=== NOX AUTO-REBUILD ===";
    emit "Watching ~/Origin/stdlib for changes...";
    emit "Ctrl+C to stop";

    let ifd = watch_create();
    if ifd < 0 { emit "Cannot create inotify"; return -1; };

    // Watch stdlib directories
    let wd1 = watch_add(ifd, "/home/lupin/Origin/stdlib", IN_MODIFY);
    let wd2 = watch_add(ifd, "/home/lupin/Origin/stdlib/homeos", IN_MODIFY);
    let wd3 = watch_add(ifd, "/home/lupin/Origin/stdlib/bootstrap", IN_MODIFY);
    emit "Watching 3 directories (wd=" + __to_string(wd1) + "," + __to_string(wd2) + "," + __to_string(wd3) + ")";

    let rebuilds = 0;
    while rebuilds < 100 {
        // Wait for event (blocking read on inotify fd)
        let event = __tcp_recv(ifd, 256);
        if len(event) > 0 {
            rebuilds = rebuilds + 1;
            let ts = __system("date '+%H:%M:%S'");
            emit "[" + ts + "] Change detected! Rebuilding...";

            // Auto-rebuild
            let result = __system("cd /home/lupin/Origin && make self-build 2>&1 | tail -3");
            emit result;

            // Auto-test
            let test = __system("cd /home/lupin/Origin && bash tests.sh 2>&1 | grep -E 'passed|FAIL'");
            emit test;

            // Notify
            __system("notify-send 'Nox' 'Auto-rebuild #" + __to_string(rebuilds) + " complete' 2>/dev/null");
        };
    };

    __syscall(SYS_CLOSE, ifd, 0, 0, 0, 0, 0);
    return rebuilds;
}

// Watch a specific file and call back when it changes
pub fn watch_file(path, callback_cmd) {
    let ifd = watch_create();
    if ifd < 0 { return -1; };
    let wd = watch_add(ifd, path, IN_MODIFY);
    if wd < 0 { __syscall(SYS_CLOSE, ifd, 0, 0, 0, 0, 0); return -1; };

    emit "Watching: " + path;
    let events = 0;
    while events < 1000 {
        let ev = __tcp_recv(ifd, 256);
        if len(ev) > 0 {
            events = events + 1;
            __system(callback_cmd);
        };
    };
    __syscall(SYS_CLOSE, ifd, 0, 0, 0, 0, 0);
    return events;
}
