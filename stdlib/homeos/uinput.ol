// Nox uinput driver — keyboard/mouse control in pure Olang
// Uses raw FD syscalls: __fd_open, __fd_write, __fd_ioctl
// freedom: deep think → growing

// Linux uinput constants
let UI_SET_EVBIT  = 1074025828;  // 0x40045564
let UI_SET_KEYBIT = 1074025829;  // 0x40045565
let UI_DEV_CREATE = 21761;       // 0x5501
let UI_DEV_DESTROY = 21762;      // 0x5502
let EV_SYN = 0;
let EV_KEY = 1;
let SYN_REPORT = 0;

// Key codes (Linux input.h)
let KEY_ESC = 1;
let KEY_1 = 2; let KEY_2 = 3; let KEY_3 = 4; let KEY_4 = 5;
let KEY_5 = 6; let KEY_6 = 7; let KEY_7 = 8; let KEY_8 = 9;
let KEY_9 = 10; let KEY_0 = 11;
let KEY_Q = 16; let KEY_W = 17; let KEY_E = 18; let KEY_R = 19;
let KEY_T = 20; let KEY_Y = 21; let KEY_U = 22; let KEY_I = 23;
let KEY_O = 24; let KEY_P = 25;
let KEY_A = 30; let KEY_S = 31; let KEY_D = 32; let KEY_F = 33;
let KEY_G = 34; let KEY_H = 35; let KEY_J = 36; let KEY_K = 37;
let KEY_L = 38;
let KEY_Z = 44; let KEY_X = 45; let KEY_C = 46; let KEY_V = 47;
let KEY_B = 48; let KEY_N = 49; let KEY_M = 50;
let KEY_SPACE = 57;
let KEY_ENTER = 28;
let KEY_DOT = 52;
let KEY_COMMA = 51;
let KEY_MINUS = 12;
let KEY_LEFTSHIFT = 42;
let KEY_BACKSPACE = 14;

// ASCII to keycode mapping
fn _char_to_key(ch) {
    let c = __char_code(ch);
    if c >= 97 && c <= 122 {
        // a-z
        let map = [30,48,46,32,18,33,34,35,23,36,37,38,50,49,24,25,16,19,31,20,22,47,17,45,21,44];
        return { code: map[c - 97], shift: 0 };
    };
    if c >= 65 && c <= 90 {
        let map = [30,48,46,32,18,33,34,35,23,36,37,38,50,49,24,25,16,19,31,20,22,47,17,45,21,44];
        return { code: map[c - 65], shift: 1 };
    };
    if c >= 48 && c <= 57 {
        if c == 48 { return { code: 11, shift: 0 }; };
        return { code: c - 47, shift: 0 };
    };
    if c == 32 { return { code: 57, shift: 0 }; };
    if c == 46 { return { code: 52, shift: 0 }; };
    if c == 44 { return { code: 51, shift: 0 }; };
    if c == 45 { return { code: 12, shift: 0 }; };
    if c == 10 { return { code: 28, shift: 0 }; };
    return { code: 0, shift: 0 };
}

// Create virtual keyboard device
pub fn uinput_create() {
    let fd = __fd_open("/dev/uinput", 1);  // O_WRONLY
    if fd < 0 { return { fd: -1, err: "cannot open /dev/uinput" }; };

    // Set event types
    __fd_ioctl(fd, UI_SET_EVBIT, EV_KEY);

    // Enable all key codes we need (0-127)
    let ki = 0;
    while ki < 128 {
        __fd_ioctl(fd, UI_SET_KEYBIT, ki);
        ki = ki + 1;
    };

    // Write uinput_user_dev struct (1116 bytes)
    let dev = __bytes_new(1116);
    // Name: "nox-keyboard" (first 80 bytes)
    __bytes_set(dev, 0, 110);  // n
    __bytes_set(dev, 1, 111);  // o
    __bytes_set(dev, 2, 120);  // x
    // BUS_USB = 3
    __bytes_set(dev, 80, 3);
    __fd_write(fd, dev, 1116);

    // Create device
    __fd_ioctl(fd, UI_DEV_CREATE, 0);

    return { fd: fd, err: "" };
}

// Write input_event: 24 bytes (time_sec:8, time_usec:8, type:2, code:2, value:4)
// Shared event buffer (avoid heap alloc per event)
let _uev = __bytes_new(24);

fn _write_event(fd, type, code, value) {
    // Reuse shared buffer
    __bytes_set(_uev, 0, 0); __bytes_set(_uev, 1, 0); __bytes_set(_uev, 2, 0); __bytes_set(_uev, 3, 0);
    __bytes_set(_uev, 4, 0); __bytes_set(_uev, 5, 0); __bytes_set(_uev, 6, 0); __bytes_set(_uev, 7, 0);
    __bytes_set(_uev, 8, 0); __bytes_set(_uev, 9, 0); __bytes_set(_uev, 10, 0); __bytes_set(_uev, 11, 0);
    __bytes_set(_uev, 12, 0); __bytes_set(_uev, 13, 0); __bytes_set(_uev, 14, 0); __bytes_set(_uev, 15, 0);
    __bytes_set(_uev, 16, type % 256);
    __bytes_set(_uev, 17, __floor(type / 256));
    __bytes_set(_uev, 18, code % 256);
    __bytes_set(_uev, 19, __floor(code / 256));
    __bytes_set(_uev, 20, value % 256);
    __bytes_set(_uev, 21, __floor(value / 256) % 256);
    __bytes_set(_uev, 22, 0);
    __bytes_set(_uev, 23, 0);
    __fd_write(fd, _uev, 24);
}

fn _syn(fd) {
    _write_event(fd, EV_SYN, SYN_REPORT, 0);
}

// Press and release a key (inline — no function calls for stability)
pub fn uinput_key(fd, code) {
    let ev = __bytes_new(24);
    // Key press: type=EV_KEY(1), code=code, value=1
    __bytes_set(ev, 16, 1); __bytes_set(ev, 18, code % 256); __bytes_set(ev, 19, __floor(code / 256)); __bytes_set(ev, 20, 1);
    __fd_write(fd, ev, 24);
    // SYN
    __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 19, 0); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
    // Key release: type=EV_KEY(1), code=code, value=0
    __bytes_set(ev, 16, 1); __bytes_set(ev, 18, code % 256); __bytes_set(ev, 19, __floor(code / 256)); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
    // SYN
    __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 19, 0); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
}

// Type a string
pub fn uinput_type(fd, text) {
    let i = 0;
    while i < len(text) {
        let ch = char_at(text, i);
        let k = _char_to_key(ch);
        if k.code > 0 {
            if k.shift == 1 {
                _write_event(fd, EV_KEY, KEY_LEFTSHIFT, 1);
                _syn(fd);
            };
            uinput_key(fd, k.code);
            if k.shift == 1 {
                _write_event(fd, EV_KEY, KEY_LEFTSHIFT, 0);
                _syn(fd);
            };
        };
        i = i + 1;
    };
}

// Type string + Enter
pub fn uinput_type_enter(fd, text) {
    uinput_type(fd, text);
    uinput_key(fd, KEY_ENTER);
}

// Destroy device
pub fn uinput_destroy(fd) {
    __fd_ioctl(fd, UI_DEV_DESTROY, 0);
    __fd_close(fd);
}
