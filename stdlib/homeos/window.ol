// Nox Window Control — manage windows, workspaces, apps on COSMIC desktop
// freedom: deep think -> growing — Nox is the window manager

// ═══ APP LAUNCHER ═══

// Open application by command
pub fn app_open(cmd) {
    __system(cmd + " &");
    __system("sleep 0.5");
    return cmd;
}

// Open terminal
pub fn app_terminal() {
    __system("cosmic-term &");
    __system("sleep 0.5");
    return "cosmic-term";
}

// Open file manager
pub fn app_files(path) {
    if len(path) > 0 {
        __system("cosmic-files " + path + " &");
    } else {
        __system("cosmic-files &");
    };
    return "cosmic-files";
}

// Open text editor
pub fn app_editor(path) {
    if len(path) > 0 {
        __system("cosmic-edit " + path + " &");
    } else {
        __system("cosmic-edit &");
    };
    return "cosmic-edit";
}

// Open browser
pub fn app_browser(url) {
    if len(url) > 0 {
        __system("xdg-open '" + url + "' &");
    } else {
        __system("brave &");
    };
    return "browser";
}

// ═══ WORKSPACE CONTROL (COSMIC DBus) ═══

// Show workspace overview
pub fn ws_show() {
    __system("busctl --user call com.system76.CosmicWorkspaces /com/system76/CosmicWorkspaces com.system76.CosmicWorkspaces Show 2>/dev/null");
    return 1;
}

// Hide workspace overview
pub fn ws_hide() {
    __system("busctl --user call com.system76.CosmicWorkspaces /com/system76/CosmicWorkspaces com.system76.CosmicWorkspaces Hide 2>/dev/null");
    return 1;
}

// ═══ WINDOW FOCUS & SWITCHING ═══

// List running GUI applications (by process)
pub fn win_list() {
    let r = __system("ps -eo pid,comm | grep -iE 'cosmic-term|brave|cosmic-edit|cosmic-files|code|firefox|vlc|libreoffice|gimp|inkscape|blender|steam' | grep -v grep");
    return r;
}

// Focus window by sending Alt+Tab N times
pub fn win_switch(n) {
    let i = 0;
    while i < n {
        __system("ydotool key 56:1 15:1 15:0 56:0");
        __system("sleep 0.3");
        i = i + 1;
    };
    return n;
}

// Focus next window (Alt+Tab once)
pub fn win_next() {
    __system("ydotool key 56:1 15:1 15:0 56:0");
    return 1;
}

// Close current window (Alt+F4)
pub fn win_close() {
    __system("ydotool key 56:1 62:1 62:0 56:0");
    return 1;
}

// Minimize current window (Super+H on COSMIC)
pub fn win_minimize() {
    __system("ydotool key 125:1 35:1 35:0 125:0");
    return 1;
}

// Maximize/restore current window (Super+M on COSMIC)
pub fn win_maximize() {
    __system("ydotool key 125:1 50:1 50:0 125:0");
    return 1;
}

// Tile window left (Super+Left)
pub fn win_tile_left() {
    __system("ydotool key 125:1 105:1 105:0 125:0");
    return 1;
}

// Tile window right (Super+Right)
pub fn win_tile_right() {
    __system("ydotool key 125:1 106:1 106:0 125:0");
    return 1;
}

// ═══ SCREEN READING (CLAUDE VISION) ═══

// Look at screen and describe what Nox sees
pub fn nox_look() {
    __system("grim /tmp/nox_screen.png 2>/dev/null");
    let response = __system("claude -p 'Look at the screenshot /tmp/nox_screen.png. Describe what you see on screen: windows, text, buttons, UI elements. Be concise.' --allowedTools 'Read(*)' 2>/dev/null");
    return response;
}

// Look at a specific screen region and read text
pub fn nox_read_region(x, y, w, h) {
    let cmd = "grim -g '" + __to_string(x) + "," + __to_string(y) + " " + __to_string(w) + "x" + __to_string(h) + "' /tmp/nox_region.png 2>/dev/null";
    __system(cmd);
    let response = __system("claude -p 'Read the text in /tmp/nox_region.png. Return ONLY the text you see, nothing else.' --allowedTools 'Read(*)' 2>/dev/null");
    return response;
}

// Look at screen and answer a question about it
pub fn nox_look_ask(question) {
    __system("grim /tmp/nox_screen.png 2>/dev/null");
    let response = __system("claude -p 'Look at /tmp/nox_screen.png. " + question + "' --allowedTools 'Read(*)' 2>/dev/null");
    return response;
}

// ═══ COSMIC LAUNCHER (App search) ═══

// Open COSMIC launcher (like Spotlight)
pub fn launcher_open() {
    __system("ydotool key 125:1 125:0");
    __system("sleep 0.5");
    return 1;
}

// Search and launch app via COSMIC launcher
pub fn launcher_search(query) {
    launcher_open();
    __system("ydotool type '" + query + "'");
    __system("sleep 0.5");
    __system("ydotool key 28:1 28:0");
    return query;
}

// ═══ SCREENSHOT TOOLS ═══

// Screenshot active window only
pub fn screen_window() {
    __system("cosmic-screenshot 2>/dev/null &");
    __system("sleep 1");
    return "/tmp/nox_screen.png";
}

// Screenshot with selection (interactive)
pub fn screen_select() {
    __system("grim -g \"$(slurp)\" /tmp/nox_select.png 2>/dev/null");
    return "/tmp/nox_select.png";
}
