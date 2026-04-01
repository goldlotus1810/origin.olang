// ═══ Eyes — Framebuffer + Camera ═══
// Organ 1 of BP12 Parasitic Kernel
// /dev/fb0 mmap → direct pixel read/write
// All via __syscall — zero dependencies

// ── State ──
let eyes_fb_fd = [0 - 1];
let eyes_fb_addr = [0];
let eyes_xres = [0];
let eyes_yres = [0];
let eyes_bpp = [0];
let eyes_line_len = [0];
let eyes_fb_size = [0];
let eyes_ready = [0];

// ── Open framebuffer ──
fn eyes_open() {
    let fd = __fd_open("/dev/fb0", 2);
    if fd < 0 { return fd; };
    let _ = __set_at(eyes_fb_fd, 0, fd);

    // Get variable screen info
    let info = __mmap(4096);
    let _ = __syscall(16, fd, 17920, info, 0, 0, 0);  // FBIOGET_VSCREENINFO
    let _ = __set_at(eyes_xres, 0, __mem_read32(info, 0));
    let _ = __set_at(eyes_yres, 0, __mem_read32(info, 4));
    let _ = __set_at(eyes_bpp, 0, __mem_read32(info, 24));

    // Get fixed screen info for line_length
    let _ = __syscall(16, fd, 17922, info, 0, 0, 0);  // FBIOGET_FSCREENINFO
    let _ = __set_at(eyes_line_len, 0, __mem_read32(info, 48));
    __munmap(info, 4096);

    // mmap framebuffer
    let fb_size = __array_get(eyes_yres, 0) * __array_get(eyes_line_len, 0);
    let _ = __set_at(eyes_fb_size, 0, fb_size);
    let fb = __mmap_file(fd, fb_size);
    if fb <= 0 { __fd_close(fd); return 0 - 1; };
    let _ = __set_at(eyes_fb_addr, 0, fb);
    let _ = __set_at(eyes_ready, 0, 1);
    return 0;
};

// ── Close ──
fn eyes_close() {
    if __array_get(eyes_ready, 0) == 0 { return; };
    __munmap(__array_get(eyes_fb_addr, 0), __array_get(eyes_fb_size, 0));
    __fd_close(__array_get(eyes_fb_fd, 0));
    let _ = __set_at(eyes_ready, 0, 0);
};

// ── Write pixel (x, y, ARGB color as u32) ──
fn eyes_pixel(x, y, color) {
    if __array_get(eyes_ready, 0) == 0 { return; };
    let off = y * __array_get(eyes_line_len, 0) + x * 4;
    __mem_write32(__array_get(eyes_fb_addr, 0), off, color);
};

// ── Draw filled rectangle ──
fn eyes_rect(x1, y1, x2, y2, color) {
    if __array_get(eyes_ready, 0) == 0 { return; };
    let fb = __array_get(eyes_fb_addr, 0);
    let ll = __array_get(eyes_line_len, 0);
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

// ── Read pixel ──
fn eyes_read_pixel(x, y) {
    if __array_get(eyes_ready, 0) == 0 { return 0; };
    let off = y * __array_get(eyes_line_len, 0) + x * 4;
    return __mem_read32(__array_get(eyes_fb_addr, 0), off);
};

emit "eyes loaded";
