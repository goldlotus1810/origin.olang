// ═══ UI Framebuffer — Direct pixel rendering to /dev/fb0 ═══
// No X11, no Wayland, no library. Pure fb0 mmap.
//
// fb0 format: 1920x1200, 32bpp (BGRA), stride=7680
// Pixel at (x,y) = base + y*stride + x*4
// Color: [B:8][G:8][R:8][A:8] = u32

let FB_WIDTH = 1920;
let FB_HEIGHT = 1200;
let FB_BPP = 4;
let FB_STRIDE = 7680;
let FB_SIZE = 9216000;  // 1200 * 7680

// fb0 mmap address (set by ui_fb_init)
let fb_addr = [0];
let fb_fd = [0];

// ═══ COLOR HELPERS ═══
// Pack BGRA color from R,G,B (0-255)
fn ui_color(r, g, b) {
    return b + g * 256 + r * 65536 + 255 * 16777216;
};

// Predefined colors (dark theme)
let UI_BG = 0;          // will be set in init
let UI_PANEL = 0;
let UI_BORDER = 0;
let UI_TEXT = 0;
let UI_ACCENT = 0;
let UI_DIM = 0;
let UI_SUCCESS = 0;
let UI_WARNING = 0;
let UI_ERROR = 0;

fn ui_init_colors() {
    let UI_BG      = ui_color(10, 10, 15);       // near-black
    let UI_PANEL   = ui_color(22, 22, 30);        // dark panel
    let UI_BORDER  = ui_color(50, 50, 65);        // subtle border
    let UI_TEXT    = ui_color(200, 200, 210);      // light text
    let UI_ACCENT  = ui_color(79, 195, 247);       // cyan accent
    let UI_DIM     = ui_color(100, 100, 120);      // dim text
    let UI_SUCCESS = ui_color(129, 199, 132);      // green
    let UI_WARNING = ui_color(255, 213, 79);       // yellow
    let UI_ERROR   = ui_color(229, 115, 115);      // red
};

// ═══ PIXEL OPERATIONS ═══
// Write one pixel at (x,y)
fn ui_pixel(x, y, color) {
    if x < 0 { return; };
    if y < 0 { return; };
    if x >= FB_WIDTH { return; };
    if y >= FB_HEIGHT { return; };
    let addr = __array_get(fb_addr, 0);
    let offset = y * FB_STRIDE + x * FB_BPP;
    // Write 4 bytes (BGRA) using __mx_w trick — actually need direct memory write
    // Use __file_append_bytes won't work for random access
    // Need: memory write at addr + offset
    // Olang has no direct memory write... except via mmap'd region
    // Solution: treat fb as mmap'd array, write via byte offset
    let b = color - __floor(color / 256) * 256;
    let g = __floor(color / 256) - __floor(color / 65536) * 256;
    let r = __floor(color / 65536) - __floor(color / 16777216) * 256;
    let a = __floor(color / 16777216);
    // Need a way to write bytes to mmap'd memory...
    // This requires VM support: __mem_write8(addr, offset, byte)
    // For now, use __file_append_bytes to /dev/fb0 at offset (won't work for random access)
    // REAL solution: build pixel buffer as byte array, write entire frame at once
};

// ═══ BUFFER-BASED APPROACH ═══
// Instead of writing pixels directly, build frame in memory as byte array
// Then write entire frame to fb0 in one shot

// Frame buffer (byte array, FB_WIDTH * FB_HEIGHT * 4 = ~9MB)
// Too large for Olang array... need mmap approach
// Use __mmap(FB_SIZE) to allocate buffer, then write to fb0

fn ui_fb_init() {
    // Open fb0
    // Note: __file_read opens, reads, closes. We need persistent fd.
    // Use __tcp_listen trick? No...
    // Actually, Olang has __mmap_file(fd, size) but no __open builtin
    // For now: write entire frame as byte array to fb0 via shell
    ui_init_colors();
    return 1;
};

// ═══ SIMPLER APPROACH: Terminal + ANSI escape codes ═══
// Until VM gets __mem_write8, use terminal rendering
// Terminal is 1024/8=128 cols, 768/16=48 rows (on VGA monitor)
// ANSI: \033[y;xH move cursor, \033[38;2;r;g;bm set color

fn ui_term_clear() {
    // ESC[2J = clear screen, ESC[H = home
    let esc = [];
    push(esc, 27); push(esc, 91); push(esc, 50); push(esc, 74);  // ESC[2J
    push(esc, 27); push(esc, 91); push(esc, 72);                   // ESC[H
    __file_append_bytes("/dev/stdout", esc);
};

fn ui_term_move(row, col) {
    // ESC[row;colH
    let seq = [];
    push(seq, 27); push(seq, 91);  // ESC[
    // Row digits
    let r_str = __to_string(row);
    let ri = 0;
    while ri < len(r_str) {
        push(seq, __char_code(char_at(r_str, ri)));
        let ri = ri + 1;
    };
    push(seq, 59);  // ;
    let c_str = __to_string(col);
    let ci = 0;
    while ci < len(c_str) {
        push(seq, __char_code(char_at(c_str, ci)));
        let ci = ci + 1;
    };
    push(seq, 72);  // H
    __file_append_bytes("/dev/stdout", seq);
};

fn ui_term_color_fg(r, g, b) {
    // ESC[38;2;r;g;bm
    let seq = [];
    push(seq, 27); push(seq, 91);  // ESC[
    push(seq, 51); push(seq, 56); push(seq, 59);  // 38;
    push(seq, 50); push(seq, 59);  // 2;
    let rs = __to_string(r);
    let ri = 0;
    while ri < len(rs) { push(seq, __char_code(char_at(rs, ri))); let ri = ri + 1; };
    push(seq, 59);  // ;
    let gs = __to_string(g);
    let gi = 0;
    while gi < len(gs) { push(seq, __char_code(char_at(gs, gi))); let gi = gi + 1; };
    push(seq, 59);  // ;
    let bs = __to_string(b);
    let bi = 0;
    while bi < len(bs) { push(seq, __char_code(char_at(bs, bi))); let bi = bi + 1; };
    push(seq, 109);  // m
    __file_append_bytes("/dev/stdout", seq);
};

fn ui_term_color_bg(r, g, b) {
    // ESC[48;2;r;g;bm
    let seq = [];
    push(seq, 27); push(seq, 91);
    push(seq, 52); push(seq, 56); push(seq, 59);  // 48;
    push(seq, 50); push(seq, 59);  // 2;
    let rs = __to_string(r);
    let ri = 0;
    while ri < len(rs) { push(seq, __char_code(char_at(rs, ri))); let ri = ri + 1; };
    push(seq, 59);
    let gs = __to_string(g);
    let gi = 0;
    while gi < len(gs) { push(seq, __char_code(char_at(gs, gi))); let gi = gi + 1; };
    push(seq, 59);
    let bs = __to_string(b);
    let bi = 0;
    while bi < len(bs) { push(seq, __char_code(char_at(bs, bi))); let bi = bi + 1; };
    push(seq, 109);
    __file_append_bytes("/dev/stdout", seq);
};

fn ui_term_reset() {
    let seq = [];
    push(seq, 27); push(seq, 91); push(seq, 48); push(seq, 109);  // ESC[0m
    __file_append_bytes("/dev/stdout", seq);
};

fn ui_term_bold() {
    let seq = [];
    push(seq, 27); push(seq, 91); push(seq, 49); push(seq, 109);  // ESC[1m
    __file_append_bytes("/dev/stdout", seq);
};

fn ui_term_hide_cursor() {
    let seq = [];
    push(seq, 27); push(seq, 91); push(seq, 63); push(seq, 50); push(seq, 53); push(seq, 108);  // ESC[?25l
    __file_append_bytes("/dev/stdout", seq);
};

fn ui_term_show_cursor() {
    let seq = [];
    push(seq, 27); push(seq, 91); push(seq, 63); push(seq, 50); push(seq, 53); push(seq, 104);  // ESC[?25h
    __file_append_bytes("/dev/stdout", seq);
};

// ═══ BOX DRAWING ═══
fn ui_term_hline(row, col, width) {
    ui_term_move(row, col);
    let i = 0;
    while i < width {
        __write_raw("─");
        let i = i + 1;
    };
};

fn ui_term_vline(row, col, height) {
    let i = 0;
    while i < height {
        ui_term_move(row + i, col);
        __write_raw("│");
        let i = i + 1;
    };
};

fn ui_term_box(row, col, w, h) {
    // Corners
    ui_term_move(row, col);      __write_raw("┌");
    ui_term_move(row, col+w-1);  __write_raw("┐");
    ui_term_move(row+h-1, col);  __write_raw("└");
    ui_term_move(row+h-1, col+w-1); __write_raw("┘");
    // Top/bottom
    ui_term_move(row, col+1);
    let i = 0; while i < w-2 { __write_raw("─"); let i = i + 1; };
    ui_term_move(row+h-1, col+1);
    let i = 0; while i < w-2 { __write_raw("─"); let i = i + 1; };
    // Sides
    let i = 1;
    while i < h-1 {
        ui_term_move(row+i, col); __write_raw("│");
        ui_term_move(row+i, col+w-1); __write_raw("│");
        let i = i + 1;
    };
};

fn ui_term_fill(row, col, w, h) {
    let r = 0;
    while r < h {
        ui_term_move(row + r, col);
        let c = 0;
        while c < w {
            __write_raw(" ");
            let c = c + 1;
        };
        let r = r + 1;
    };
};

// Write text at position
fn ui_term_text(row, col, text) {
    ui_term_move(row, col);
    __write_raw(text);
};

emit "ui_fb loaded";
