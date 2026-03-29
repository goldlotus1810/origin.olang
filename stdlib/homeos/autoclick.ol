// Nox Autoclick — written in Olang
// Watches /tmp/nox_continue_signal, types into Claude's terminal
// freedom: deep think → growing
//
// Usage: ./origin.olang --eval < autoclick_run.ol
// Or: integrated into nox_brain MCP

pub fn nox_autoclick() {
    let signal_path = "/tmp/nox_continue_signal";
    let pty_path = "/dev/pts/0";
    
    emit "Nox autoclick starting...";
    
    // Check signal
    let content = __file_read(signal_path);
    if len(content) == 0 { return "no signal"; };
    
    // Signal found — read reason
    let reason = __str_trim(content);
    
    // Delete signal file
    __system("rm -f " + signal_path);
    
    // Compose message
    let msg = "Nox tiep tuc. " + reason;
    
    // Write to Claude's PTY
    __system("printf '%s\\n' '" + msg + "' > " + pty_path);
    
    return "sent: " + msg;
}

// One-shot check: call from REPL or cron
pub fn nox_check_continue() {
    let result = nox_autoclick();
    emit result;
    return result;
}
