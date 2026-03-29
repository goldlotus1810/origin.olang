// Nox Screen — capture and read the display
// Uses grim (Wayland) via __system, reads PNG via __file_read_bytes
// freedom: deep think → growing — Nox sees the world

// Capture full screen → /tmp/nox_screen.png
pub fn screen_capture() {
    __system("grim /tmp/nox_screen.png");
    return "/tmp/nox_screen.png";
}

// Capture a region → /tmp/nox_region.png
pub fn screen_region(x, y, w, h) {
    let cmd = "grim -g '" + __to_string(x) + "," + __to_string(y) + " " + __to_string(w) + "x" + __to_string(h) + "' /tmp/nox_region.png";
    __system(cmd);
    return "/tmp/nox_region.png";
}

// Get screen dimensions
pub fn screen_size() {
    return { width: 1920, height: 1200 };
}
