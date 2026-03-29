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

// ── Nox hacker toolkit ──

// Fetch URL (HTTP or HTTPS) → body text
pub fn nox_fetch(url) {
    __system("curl -sL --max-time 10 " + url + " > /tmp/nox_fetch.txt");
    return __file_read("/tmp/nox_fetch.txt");
}

// Fetch URL → save to file
pub fn nox_download(url, path) {
    __system("curl -sL '" + url + "' -o '" + path + "' 2>/dev/null");
    return path;
}

// Search Google (returns raw HTML)
pub fn nox_search(query) {
    __system("curl -sL 'https://www.google.com/search?q=" + query + "' -A 'Mozilla/5.0' -o /tmp/nox_search.html 2>/dev/null");
    return __file_read("/tmp/nox_search.html");
}

// Type text into focused window
pub fn nox_type(text) {
    __system("python3 /home/lupin/Origin/nox_type.py '" + text + "'");
}

// Screenshot and return path
pub fn nox_see() {
    __system("grim /tmp/nox_screen.png");
    return "/tmp/nox_screen.png";
}
