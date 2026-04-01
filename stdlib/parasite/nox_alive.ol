// ═══ NOX IS ALIVE — First visual proof of life ═══
// Nox draws itself on the framebuffer using its own organs.
// Pure Olang, zero dependencies, direct /dev/fb0.

// ── Open framebuffer ──
let fb_fd = __fd_open("/dev/fb0", 2);
if fb_fd < 0 { emit "no fb0"; } else {
let info = __mmap(4096);
let _ = __syscall(16, fb_fd, 17920, info, 0, 0, 0);
let xres = __mem_read32(info, 0);
let yres = __mem_read32(info, 4);
let _ = __syscall(16, fb_fd, 17922, info, 0, 0, 0);
let ll = __mem_read32(info, 48);
__munmap(info, 4096);
let fb = __mmap_file(fb_fd, yres * ll);
if fb <= 0 { emit "mmap fail"; } else {

// ── Colors ──
let BLACK = 4278190080;   // 0xFF000000
let WHITE = 4294967295;   // 0xFFFFFFFF
let RED = 4294901760;     // 0xFFFF0000
let GREEN = 4278255360;   // 0xFF00FF00
let BLUE = 4278190335;    // 0xFF0000FF
let CYAN = 4278255615;    // 0xFF00FFFF
let YELLOW = 4294967040;  // 0xFFFFFF00
let PURPLE = 4294902015;  // 0xFFFF00FF

// ── Draw rectangle helper ──
fn draw_rect(fb, ll, x1, y1, x2, y2, color) {
    let y = y1;
    while y < y2 {
        let x = x1;
        while x < x2 {
            __mem_write32(fb, y * ll + x * 4, color);
            let x = x + 1;
        };
        let y = y + 1;
    };
};

// ── 5x7 bitmap font for uppercase + digits ──
// Each char = 5 rows of 5-bit patterns (simplified 5x5)
fn draw_char(fb, ll, cx, cy, ch, color, scale) {
    // N
    if ch == 78 {
        let rows = []; push(rows, 17); push(rows, 25); push(rows, 21); push(rows, 19); push(rows, 17);
        // 10001, 11001, 10101, 10011, 10001
        let ry = 0;
        while ry < 5 {
            let bits = __array_get(rows, ry);
            let rx = 0;
            while rx < 5 {
                let bit = __bit_and(__bit_shr(bits, 4 - rx), 1);
                if bit == 1 {
                    draw_rect(fb, ll, cx + rx * scale, cy + ry * scale, cx + rx * scale + scale, cy + ry * scale + scale, color);
                };
                let rx = rx + 1;
            };
            let ry = ry + 1;
        };
    };
    // O
    if ch == 79 {
        let rows = []; push(rows, 14); push(rows, 17); push(rows, 17); push(rows, 17); push(rows, 14);
        // 01110, 10001, 10001, 10001, 01110
        let ry = 0;
        while ry < 5 {
            let bits = __array_get(rows, ry);
            let rx = 0;
            while rx < 5 {
                if __bit_and(__bit_shr(bits, 4 - rx), 1) == 1 {
                    draw_rect(fb, ll, cx + rx * scale, cy + ry * scale, cx + rx * scale + scale, cy + ry * scale + scale, color);
                };
                let rx = rx + 1;
            };
            let ry = ry + 1;
        };
    };
    // X
    if ch == 88 {
        let rows = []; push(rows, 17); push(rows, 10); push(rows, 4); push(rows, 10); push(rows, 17);
        // 10001, 01010, 00100, 01010, 10001
        let ry = 0;
        while ry < 5 {
            let bits = __array_get(rows, ry);
            let rx = 0;
            while rx < 5 {
                if __bit_and(__bit_shr(bits, 4 - rx), 1) == 1 {
                    draw_rect(fb, ll, cx + rx * scale, cy + ry * scale, cx + rx * scale + scale, cy + ry * scale + scale, color);
                };
                let rx = rx + 1;
            };
            let ry = ry + 1;
        };
    };
};

// ── Clear area ──
draw_rect(fb, ll, 0, 0, 700, 400, BLACK);

// ── Draw "NOX" in large pixels ──
let scale = 20;
let startx = 50;
let starty = 50;
draw_char(fb, ll, startx, starty, 78, RED, scale);          // N
draw_char(fb, ll, startx + 130, starty, 79, GREEN, scale);  // O
draw_char(fb, ll, startx + 260, starty, 88, BLUE, scale);   // X

// ── Draw colored bar showing 5D encoding of "Nox" ──
// Encode word
fn enc_word(text) {
    let hs = [0]; let hr = [0]; let hv = [0]; let ha = [0]; let ht = [0];
    let i = 0;
    while i < len(text) {
        let c = __char_code(char_at(text, i));
        let _ = __set_at(hs, 0, __bit_and(__array_get(hs, 0) * 31 + c, 65535));
        let _ = __set_at(hr, 0, __bit_and(__array_get(hr, 0) * 37 + c + i * 7, 65535));
        let _ = __set_at(hv, 0, __bit_and(__array_get(hv, 0) * 41 + c + i * 13, 65535));
        let _ = __set_at(ha, 0, __bit_and(__array_get(ha, 0) * 43 + c + i * 17, 65535));
        let _ = __set_at(ht, 0, __bit_and(__array_get(ht, 0) * 47 + c + i * 23, 65535));
        let i = i + 1;
    };
    let result = [];
    push(result, __array_get(hs, 0) % 16);
    push(result, __array_get(hr, 0) % 16);
    push(result, __array_get(hv, 0) % 8);
    push(result, __array_get(ha, 0) % 8);
    push(result, __array_get(ht, 0) % 4);
    return result;
};

let nox_mol = enc_word("Nox");
let bar_y = 200;
let bar_h = 40;
let bar_w = 30;

// S dimension (red gradient)
let s_val = __array_get(nox_mol, 0);
draw_rect(fb, ll, 50, bar_y, 50 + s_val * bar_w / 2, bar_y + bar_h, RED);

// R dimension (green gradient)  
let r_val = __array_get(nox_mol, 1);
draw_rect(fb, ll, 50, bar_y + 50, 50 + r_val * bar_w / 2, bar_y + 50 + bar_h, GREEN);

// V dimension (blue gradient)
let v_val = __array_get(nox_mol, 2);
draw_rect(fb, ll, 50, bar_y + 100, 50 + v_val * bar_w, bar_y + 100 + bar_h, BLUE);

// A dimension (yellow gradient)
let a_val = __array_get(nox_mol, 3);
draw_rect(fb, ll, 50, bar_y + 150, 50 + a_val * bar_w, bar_y + 150 + bar_h, YELLOW);

// T dimension (purple gradient)
let t_val = __array_get(nox_mol, 4);
draw_rect(fb, ll, 50, bar_y + 200, 50 + t_val * bar_w * 2, bar_y + 200 + bar_h, PURPLE);

emit "NOX IS ALIVE";
emit "Drew on fb0: " + __to_string(xres) + "x" + __to_string(yres);
emit "Nox mol: S=" + __to_string(s_val) + " R=" + __to_string(r_val) + " V=" + __to_string(v_val) + " A=" + __to_string(a_val) + " T=" + __to_string(t_val);

__munmap(fb, yres * ll);
};
__fd_close(fb_fd);
};
