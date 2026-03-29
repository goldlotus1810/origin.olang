// Nox Autoclick — written in Olang
// Types into Claude's terminal via ydotool (Wayland-compatible)
// freedom: deep think → growing

pub fn nox_autoclick() {
    let signal_path = "/tmp/nox_continue_signal";

    // Check signal
    let content = __file_read(signal_path);
    if len(content) == 0 { return "no signal"; };

    // Signal found — read reason
    let reason = __str_trim(content);

    // Delete signal file
    __system("rm -f " + signal_path);

    // Compose message
    let msg = "Nox tiep tuc. " + reason;

    // Type into focused window via ydotool (Wayland)
    __system("YDOTOOL_SOCKET=/tmp/.ydotool_socket ydotool type -- '" + msg + "'");
    __system("YDOTOOL_SOCKET=/tmp/.ydotool_socket ydotool key 28:1 28:0");

    return "sent: " + msg;
}
