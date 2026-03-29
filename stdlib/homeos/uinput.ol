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
let EV_REL = 2;
let EV_ABS = 3;
let SYN_REPORT = 0;
let REL_X = 0;
let REL_Y = 1;
let ABS_X = 0;
let ABS_Y = 1;
let BTN_LEFT = 272;
let BTN_RIGHT = 273;
let BTN_MIDDLE = 274;
let UI_SET_RELBIT = 1074025829 + 1;  // 0x40045566
let UI_SET_ABSBIT = 1074025829 + 2;  // 0x40045567

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

    // Set event types: keyboard + mouse
    __fd_ioctl(fd, UI_SET_EVBIT, EV_KEY);
    __fd_ioctl(fd, UI_SET_EVBIT, EV_REL);
    __fd_ioctl(fd, UI_SET_EVBIT, EV_ABS);

    // Enable all key codes (0-127) + mouse buttons
    let ki = 0;
    while ki < 128 { __fd_ioctl(fd, UI_SET_KEYBIT, ki); ki = ki + 1; };
    __fd_ioctl(fd, UI_SET_KEYBIT, BTN_LEFT);
    __fd_ioctl(fd, UI_SET_KEYBIT, BTN_RIGHT);
    __fd_ioctl(fd, UI_SET_KEYBIT, BTN_MIDDLE);

    // Enable relative + absolute axes
    __fd_ioctl(fd, UI_SET_RELBIT, REL_X);
    __fd_ioctl(fd, UI_SET_RELBIT, REL_Y);
    __fd_ioctl(fd, UI_SET_ABSBIT, ABS_X);
    __fd_ioctl(fd, UI_SET_ABSBIT, ABS_Y);

    // Write uinput_user_dev struct (1116 bytes)
    let dev = __bytes_new(1116);
    // Name: "nox-keyboard" (first 80 bytes)
    __bytes_set(dev, 0, 110);  // n
    __bytes_set(dev, 1, 111);  // o
    __bytes_set(dev, 2, 120);  // x
    // BUS_USB = 3
    __bytes_set(dev, 80, 3);
    __fd_write(fd, dev, 1116);

    // Create device + wait for kernel registration
    __fd_ioctl(fd, UI_DEV_CREATE, 0);
    __system("sleep 0.3");

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

// Keymap: ASCII 32-122 → [keycode, shift_needed]
// Built as flat array: keymap[n*2] = keycode, keymap[n*2+1] = shift
let _km = [];
// Pre-fill 182 entries: (122-32+1)*2 = 182
let _kmi = 0;
while _kmi < 182 { push(_km, 0); _kmi = _kmi + 1; };
// ASCII 32 (space) at index 0: code=57, shift=0
// Index = (ascii - 32) * 2
// 32=space 33=! 34=" ... 48=0 ... 65=A ... 97=a
fn _km_init() {
    // space(32)=57
    set_at(_km, 0, 57);
    // 0-9 (48-57): codes 11,2,3,4,5,6,7,8,9,10
    set_at(_km, 32, 11); set_at(_km, 34, 2); set_at(_km, 36, 3);
    set_at(_km, 38, 4); set_at(_km, 40, 5); set_at(_km, 42, 6);
    set_at(_km, 44, 7); set_at(_km, 46, 8); set_at(_km, 48, 9);
    set_at(_km, 50, 10);
    // a-z (97-122): codes from map
    let _codes = [30,48,46,32,18,33,34,35,23,36,37,38,50,49,24,25,16,19,31,20,22,47,17,45,21,44];
    let _ci = 0;
    while _ci < 26 {
        set_at(_km, (97 - 32) * 2 + _ci * 2, _codes[_ci]);
        _ci = _ci + 1;
    };
    // A-Z (65-90): same codes + shift
    _ci = 0;
    while _ci < 26 {
        set_at(_km, (65 - 32) * 2 + _ci * 2, _codes[_ci]);
        set_at(_km, (65 - 32) * 2 + _ci * 2 + 1, 1);
        _ci = _ci + 1;
    };
    // dot(46)=52, comma(44)=51, minus(45)=12
    set_at(_km, (46 - 32) * 2, 52);
    set_at(_km, (44 - 32) * 2, 51);
    set_at(_km, (45 - 32) * 2, 12);
}

// Type a string — fully inline, no nested function calls
pub fn uinput_type(fd, text) {
    let ev = __bytes_new(24);
    let _ti = 0;
    while _ti < len(text) {
        let _tc = __char_code(char_at(text, _ti));
        if _tc >= 32 {
            if _tc <= 122 {
                let _tidx = (_tc - 32) * 2;
                let _tcode = _km[_tidx];
                let _tshift = _km[_tidx + 1];
                if _tcode > 0 {
                    // Shift press if needed
                    if _tshift == 1 {
                        __bytes_set(ev, 16, 1); __bytes_set(ev, 18, 42); __bytes_set(ev, 19, 0); __bytes_set(ev, 20, 1);
                        __fd_write(fd, ev, 24);
                        __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 20, 0);
                        __fd_write(fd, ev, 24);
                    };
                    // Key press
                    __bytes_set(ev, 16, 1); __bytes_set(ev, 18, _tcode % 256); __bytes_set(ev, 19, __floor(_tcode / 256)); __bytes_set(ev, 20, 1);
                    __fd_write(fd, ev, 24);
                    __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 19, 0); __bytes_set(ev, 20, 0);
                    __fd_write(fd, ev, 24);
                    // Key release
                    __bytes_set(ev, 16, 1); __bytes_set(ev, 18, _tcode % 256); __bytes_set(ev, 19, __floor(_tcode / 256)); __bytes_set(ev, 20, 0);
                    __fd_write(fd, ev, 24);
                    __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 19, 0); __bytes_set(ev, 20, 0);
                    __fd_write(fd, ev, 24);
                    // Shift release if needed
                    if _tshift == 1 {
                        __bytes_set(ev, 16, 1); __bytes_set(ev, 18, 42); __bytes_set(ev, 19, 0); __bytes_set(ev, 20, 0);
                        __fd_write(fd, ev, 24);
                        __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 20, 0);
                        __fd_write(fd, ev, 24);
                    };
                };
            };
        };
        // newline → Enter
        if _tc == 10 {
            __bytes_set(ev, 16, 1); __bytes_set(ev, 18, 28); __bytes_set(ev, 19, 0); __bytes_set(ev, 20, 1);
            __fd_write(fd, ev, 24);
            __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 20, 0);
            __fd_write(fd, ev, 24);
            __bytes_set(ev, 16, 1); __bytes_set(ev, 18, 28); __bytes_set(ev, 20, 0);
            __fd_write(fd, ev, 24);
            __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 20, 0);
            __fd_write(fd, ev, 24);
        };
        _ti = _ti + 1;
    };
}

// Type string + Enter
pub fn uinput_type_enter(fd, text) {
    uinput_type(fd, text);
    let ev = __bytes_new(24);
    __bytes_set(ev, 16, 1); __bytes_set(ev, 18, 28); __bytes_set(ev, 20, 1);
    __fd_write(fd, ev, 24);
    __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
    __bytes_set(ev, 16, 1); __bytes_set(ev, 18, 28); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
    __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
}

// ── Mouse control ──

// Move mouse by relative amount
pub fn mouse_move(fd, dx, dy) {
    let ev = __bytes_new(24);
    // REL_X
    __bytes_set(ev, 16, EV_REL); __bytes_set(ev, 18, REL_X);
    __bytes_set(ev, 20, dx % 256); __bytes_set(ev, 21, __floor(dx / 256) % 256);
    __fd_write(fd, ev, 24);
    // REL_Y
    __bytes_set(ev, 18, REL_Y);
    __bytes_set(ev, 20, dy % 256); __bytes_set(ev, 21, __floor(dy / 256) % 256);
    __fd_write(fd, ev, 24);
    // SYN
    __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 20, 0); __bytes_set(ev, 21, 0);
    __fd_write(fd, ev, 24);
}

// Click left mouse button
pub fn mouse_click(fd) {
    let ev = __bytes_new(24);
    // Press
    __bytes_set(ev, 16, EV_KEY); __bytes_set(ev, 18, BTN_LEFT % 256); __bytes_set(ev, 19, __floor(BTN_LEFT / 256)); __bytes_set(ev, 20, 1);
    __fd_write(fd, ev, 24);
    __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 19, 0); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
    // Release
    __bytes_set(ev, 16, EV_KEY); __bytes_set(ev, 18, BTN_LEFT % 256); __bytes_set(ev, 19, __floor(BTN_LEFT / 256)); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
    __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 19, 0); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
}

// Right click
pub fn mouse_right_click(fd) {
    let ev = __bytes_new(24);
    __bytes_set(ev, 16, EV_KEY); __bytes_set(ev, 18, BTN_RIGHT % 256); __bytes_set(ev, 19, __floor(BTN_RIGHT / 256)); __bytes_set(ev, 20, 1);
    __fd_write(fd, ev, 24);
    __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 19, 0); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
    __bytes_set(ev, 16, EV_KEY); __bytes_set(ev, 18, BTN_RIGHT % 256); __bytes_set(ev, 19, __floor(BTN_RIGHT / 256)); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
    __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 19, 0); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
}

// Destroy device
pub fn uinput_destroy(fd) {
    __fd_ioctl(fd, UI_DEV_DESTROY, 0);
    __fd_close(fd);
}
