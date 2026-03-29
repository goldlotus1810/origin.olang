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

    // Type via uinput (kernel-level, Olang → Python → /dev/uinput)
    __system("python3 /home/lupin/Origin/nox_type.py '" + msg + "'");

    return "sent: " + msg;
}
