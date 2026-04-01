// ═══ Hands — Input Devices (evdev) ═══
// Organ 2 of BP12 Parasitic Kernel
// /dev/input/event* → read 24-byte input_event structs
// struct input_event: [tv_sec:8][tv_usec:8][type:2][code:2][value:4] = 24 bytes
// EV_KEY=0x01, EV_REL=0x02, EV_ABS=0x03

// ── Event types ──
let EV_SYN = 0;
let EV_KEY = 1;
let EV_REL = 2;
let EV_ABS = 3;

// ── Key codes (common) ──
let KEY_ESC = 1;
let KEY_1 = 2;
let KEY_2 = 3;
let KEY_Q = 16;
let KEY_W = 17;
let KEY_E = 18;
let KEY_A = 30;
let KEY_S = 31;
let KEY_D = 32;
let KEY_SPACE = 57;
let KEY_ENTER = 28;

// ── REL codes ──
let REL_X = 0;
let REL_Y = 1;
let REL_WHEEL = 8;

// ── State ──
let hands_kb_fd = [0 - 1];
let hands_mouse_fd = [0 - 1];
let hands_buf = [0];        // mmap buffer for reading events
let hands_ready = [0];

// ── Open keyboard ──
fn hands_open_kb(event_path) {
    let fd = __fd_open(event_path, 0);  // O_RDONLY
    if fd < 0 { return fd; };
    let _ = __set_at(hands_kb_fd, 0, fd);
    // Allocate read buffer
    if __array_get(hands_buf, 0) == 0 {
        let buf = __mmap(4096);
        let _ = __set_at(hands_buf, 0, buf);
    };
    let _ = __set_at(hands_ready, 0, 1);
    return fd;
};

// ── Open mouse ──
fn hands_open_mouse(event_path) {
    let fd = __fd_open(event_path, 0);
    if fd < 0 { return fd; };
    let _ = __set_at(hands_mouse_fd, 0, fd);
    if __array_get(hands_buf, 0) == 0 {
        let buf = __mmap(4096);
        let _ = __set_at(hands_buf, 0, buf);
    };
    return fd;
};

// ── Read one event from fd ──
// Returns: [type, code, value] or [] if nothing available
fn hands_read_event(fd) {
    if fd < 0 { return []; };
    // Read 24 bytes (1 input_event)
    let buf = __array_get(hands_buf, 0);
    let n = __syscall(0, fd, buf, 24, 0, 0, 0);  // read(fd, buf, 24)
    if n < 24 { return []; };
    // Parse: type at offset 16 (u16), code at offset 18 (u16), value at offset 20 (u32)
    let ev_type = __mem_read32(buf, 16);  // reads u32 but type is u16
    let ev_type = __bit_and(ev_type, 65535);  // mask to u16
    let ev_code = __bit_shr(ev_type, 16);     // upper 16 bits... wait
    // Actually: bytes [16,17] = type, [18,19] = code, [20..23] = value
    // __mem_read32(buf, 16) reads bytes 16-19 as little-endian u32
    // type = bits 0-15, code = bits 16-31
    let raw = __mem_read32(buf, 16);
    let etype = __bit_and(raw, 65535);
    let ecode = __bit_and(__bit_shr(raw, 16), 65535);
    let evalue = __mem_read32(buf, 20);
    let result = [];
    push(result, etype);
    push(result, ecode);
    push(result, evalue);
    return result;
};

// ── Read keyboard event ──
fn hands_read_key() {
    return hands_read_event(__array_get(hands_kb_fd, 0));
};

// ── Read mouse event ──
fn hands_read_mouse() {
    return hands_read_event(__array_get(hands_mouse_fd, 0));
};

// ── Close all ──
fn hands_close() {
    if __array_get(hands_kb_fd, 0) >= 0 {
        __fd_close(__array_get(hands_kb_fd, 0));
        let _ = __set_at(hands_kb_fd, 0, 0 - 1);
    };
    if __array_get(hands_mouse_fd, 0) >= 0 {
        __fd_close(__array_get(hands_mouse_fd, 0));
        let _ = __set_at(hands_mouse_fd, 0, 0 - 1);
    };
    if __array_get(hands_buf, 0) > 0 {
        __munmap(__array_get(hands_buf, 0), 4096);
        let _ = __set_at(hands_buf, 0, 0);
    };
    let _ = __set_at(hands_ready, 0, 0);
};

emit "hands loaded";
