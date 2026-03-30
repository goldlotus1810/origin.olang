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
let KEY_TAB = 15;
let KEY_SEMICOLON = 39;
let KEY_APOSTROPHE = 40;
let KEY_GRAVE = 41;
let KEY_BACKSLASH = 43;
let KEY_SLASH = 53;
let KEY_EQUAL = 13;
let KEY_LEFTBRACE = 26;
let KEY_RIGHTBRACE = 27;
let KEY_LEFTCTRL = 29;
let KEY_LEFTALT = 56;
let KEY_CAPSLOCK = 58;
let KEY_F1 = 59; let KEY_F2 = 60; let KEY_F3 = 61; let KEY_F4 = 62;
let KEY_F5 = 63; let KEY_F6 = 64; let KEY_F7 = 65; let KEY_F8 = 66;
let KEY_F9 = 67; let KEY_F10 = 68; let KEY_F11 = 87; let KEY_F12 = 88;
let KEY_UP = 103; let KEY_DOWN = 108; let KEY_LEFT = 105; let KEY_RIGHT = 106;
let KEY_HOME = 102; let KEY_END = 107;
let KEY_PAGEUP = 104; let KEY_PAGEDOWN = 109;
let KEY_INSERT = 110; let KEY_DELETE = 111;
let KEY_RIGHTSHIFT = 54;
let KEY_RIGHTCTRL = 97;
let KEY_RIGHTALT = 100;
let KEY_SUPER = 125;

// ASCII to keycode mapping
// _char_to_key removed — dead code (0 calls)

// Create virtual keyboard device
pub fn uinput_create() {
    let fd = __fd_open("/dev/uinput", 2049);  // O_WRONLY | O_NONBLOCK (1 | 0x800)
    if fd < 0 { return { fd: -1, err: "cannot open /dev/uinput" }; };

    // Set event types: keyboard + mouse
    __fd_ioctl(fd, UI_SET_EVBIT, EV_KEY);
    __fd_ioctl(fd, UI_SET_EVBIT, EV_REL);
    __fd_ioctl(fd, UI_SET_EVBIT, EV_ABS);

    // Enable all key codes (0-127) + mouse buttons
    let ki = 0;
    while ki < 256 { __fd_ioctl(fd, UI_SET_KEYBIT, ki); ki = ki + 1; };
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
    // BUS_USB=3, vendor=0x1234, product=0x5678, version=1
    __bytes_set(dev, 80, 3);
    __bytes_set(dev, 82, 0x34); __bytes_set(dev, 83, 0x12);
    __bytes_set(dev, 84, 0x78); __bytes_set(dev, 85, 0x56);
    __bytes_set(dev, 86, 1);
    __fd_write(fd, dev, 1116);

    // Create device + wait for kernel registration
    __fd_ioctl(fd, UI_DEV_CREATE, 0);
    __system("sleep 0.5");

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
// Pre-fill 190 entries: (126-32+1)*2 = 190 (covers through ~)
let _kmi = 0;
while _kmi < 190 { push(_km, 0); _kmi = _kmi + 1; };
// ASCII 32 (space) at index 0: code=57, shift=0
// Index = (ascii - 32) * 2
// 32=space 33=! 34=" ... 48=0 ... 65=A ... 97=a
// _km_init removed — dead code (0 calls)

// Type a string — fully inline, no nested function calls
pub fn uinput_type(fd, text) {
    let ev = __bytes_new(24);
    let _ti = 0;
    while _ti < len(text) {
        let _tc = __char_code(char_at(text, _ti));
        if _tc >= 32 {
            if _tc <= 126 {
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

// ═══ KEY COMBOS ═══

// Press modifier + key (e.g., Ctrl+C, Alt+Tab)
pub fn key_combo(fd, mod_code, key_code) {
    let ev = __bytes_new(24);
    // Modifier press
    __bytes_set(ev, 16, 1); __bytes_set(ev, 18, mod_code % 256); __bytes_set(ev, 19, __floor(mod_code / 256)); __bytes_set(ev, 20, 1);
    __fd_write(fd, ev, 24);
    __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 19, 0); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
    // Key press
    __bytes_set(ev, 16, 1); __bytes_set(ev, 18, key_code % 256); __bytes_set(ev, 19, __floor(key_code / 256)); __bytes_set(ev, 20, 1);
    __fd_write(fd, ev, 24);
    __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 19, 0); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
    // Key release
    __bytes_set(ev, 16, 1); __bytes_set(ev, 18, key_code % 256); __bytes_set(ev, 19, __floor(key_code / 256)); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
    __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 19, 0); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
    // Modifier release
    __bytes_set(ev, 16, 1); __bytes_set(ev, 18, mod_code % 256); __bytes_set(ev, 19, __floor(mod_code / 256)); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
    __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 19, 0); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
}

// Common combos — convenience
pub fn key_ctrl_c(fd)     { key_combo(fd, 29, 46); }   // Ctrl+C
pub fn key_ctrl_v(fd)     { key_combo(fd, 29, 47); }   // Ctrl+V
pub fn key_ctrl_x(fd)     { key_combo(fd, 29, 45); }   // Ctrl+X
pub fn key_ctrl_z(fd)     { key_combo(fd, 29, 44); }   // Ctrl+Z
pub fn key_ctrl_s(fd)     { key_combo(fd, 29, 31); }   // Ctrl+S
pub fn key_ctrl_a(fd)     { key_combo(fd, 29, 30); }   // Ctrl+A
pub fn key_ctrl_w(fd)     { key_combo(fd, 29, 17); }   // Ctrl+W
pub fn key_ctrl_l(fd)     { key_combo(fd, 29, 38); }   // Ctrl+L
pub fn key_alt_tab(fd)    { key_combo(fd, 56, 15); }   // Alt+Tab
pub fn key_alt_f4(fd)     { key_combo(fd, 56, 62); }   // Alt+F4
pub fn key_super(fd)      { uinput_key(fd, 125); }     // Super key

// ═══ SPECIAL KEYS ═══

pub fn key_tab(fd)        { uinput_key(fd, 15); }
pub fn key_escape(fd)     { uinput_key(fd, 1); }
pub fn key_backspace(fd)  { uinput_key(fd, 14); }
pub fn key_delete(fd)     { uinput_key(fd, 111); }
pub fn key_enter(fd)      { uinput_key(fd, 28); }
pub fn key_up(fd)         { uinput_key(fd, 103); }
pub fn key_down(fd)       { uinput_key(fd, 108); }
pub fn key_left(fd)       { uinput_key(fd, 105); }
pub fn key_right(fd)      { uinput_key(fd, 106); }
pub fn key_home(fd)       { uinput_key(fd, 102); }
pub fn key_end(fd)        { uinput_key(fd, 107); }
pub fn key_pgup(fd)       { uinput_key(fd, 104); }
pub fn key_pgdn(fd)       { uinput_key(fd, 109); }
pub fn key_f1(fd)         { uinput_key(fd, 59); }
pub fn key_f2(fd)         { uinput_key(fd, 60); }
pub fn key_f3(fd)         { uinput_key(fd, 61); }
pub fn key_f4(fd)         { uinput_key(fd, 62); }
pub fn key_f5(fd)         { uinput_key(fd, 63); }
pub fn key_f6(fd)         { uinput_key(fd, 64); }
pub fn key_f7(fd)         { uinput_key(fd, 65); }
pub fn key_f8(fd)         { uinput_key(fd, 66); }
pub fn key_f9(fd)         { uinput_key(fd, 67); }
pub fn key_f10(fd)        { uinput_key(fd, 68); }
pub fn key_f11(fd)        { uinput_key(fd, 87); }
pub fn key_f12(fd)        { uinput_key(fd, 88); }

// ═══ MOUSE ABSOLUTE POSITIONING ═══

// Move mouse to absolute screen position
pub fn mouse_move_to(fd, x, y) {
    let ev = __bytes_new(24);
    // ABS_X
    __bytes_set(ev, 16, EV_ABS); __bytes_set(ev, 18, ABS_X);
    __bytes_set(ev, 20, x % 256); __bytes_set(ev, 21, __floor(x / 256) % 256);
    __bytes_set(ev, 22, __floor(x / 65536) % 256); __bytes_set(ev, 23, __floor(x / 16777216) % 256);
    __fd_write(fd, ev, 24);
    // ABS_Y
    __bytes_set(ev, 18, ABS_Y);
    __bytes_set(ev, 20, y % 256); __bytes_set(ev, 21, __floor(y / 256) % 256);
    __bytes_set(ev, 22, __floor(y / 65536) % 256); __bytes_set(ev, 23, __floor(y / 16777216) % 256);
    __fd_write(fd, ev, 24);
    // SYN
    __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 20, 0); __bytes_set(ev, 21, 0);
    __bytes_set(ev, 22, 0); __bytes_set(ev, 23, 0);
    __fd_write(fd, ev, 24);
}

// Click at absolute position
pub fn mouse_click_at(fd, x, y) {
    mouse_move_to(fd, x, y);
    mouse_click(fd);
}

// Double click
pub fn mouse_double_click(fd) {
    mouse_click(fd);
    __system("sleep 0.05");
    mouse_click(fd);
}

// Middle click
pub fn mouse_middle_click(fd) {
    let ev = __bytes_new(24);
    __bytes_set(ev, 16, EV_KEY); __bytes_set(ev, 18, BTN_MIDDLE % 256); __bytes_set(ev, 19, __floor(BTN_MIDDLE / 256)); __bytes_set(ev, 20, 1);
    __fd_write(fd, ev, 24);
    __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 19, 0); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
    __bytes_set(ev, 16, EV_KEY); __bytes_set(ev, 18, BTN_MIDDLE % 256); __bytes_set(ev, 19, __floor(BTN_MIDDLE / 256)); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
    __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 19, 0); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
}

// Scroll (vertical)
pub fn mouse_scroll(fd, amount) {
    let ev = __bytes_new(24);
    // REL_WHEEL = 8
    __bytes_set(ev, 16, EV_REL); __bytes_set(ev, 18, 8);
    if amount >= 0 {
        __bytes_set(ev, 20, amount % 256);
    } else {
        // Negative: two's complement
        let neg = 256 + amount;
        __bytes_set(ev, 20, neg % 256);
        __bytes_set(ev, 21, 255); __bytes_set(ev, 22, 255); __bytes_set(ev, 23, 255);
    };
    __fd_write(fd, ev, 24);
    __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 20, 0);
    __bytes_set(ev, 21, 0); __bytes_set(ev, 22, 0); __bytes_set(ev, 23, 0);
    __fd_write(fd, ev, 24);
}

// Drag from (x1,y1) to (x2,y2)
pub fn mouse_drag(fd, x1, y1, x2, y2) {
    mouse_move_to(fd, x1, y1);
    __system("sleep 0.05");
    // Press
    let ev = __bytes_new(24);
    __bytes_set(ev, 16, EV_KEY); __bytes_set(ev, 18, BTN_LEFT % 256); __bytes_set(ev, 19, __floor(BTN_LEFT / 256)); __bytes_set(ev, 20, 1);
    __fd_write(fd, ev, 24);
    __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 19, 0); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
    __system("sleep 0.05");
    // Move to target
    mouse_move_to(fd, x2, y2);
    __system("sleep 0.05");
    // Release
    __bytes_set(ev, 16, EV_KEY); __bytes_set(ev, 18, BTN_LEFT % 256); __bytes_set(ev, 19, __floor(BTN_LEFT / 256)); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
    __bytes_set(ev, 16, 0); __bytes_set(ev, 18, 0); __bytes_set(ev, 19, 0); __bytes_set(ev, 20, 0);
    __fd_write(fd, ev, 24);
}
