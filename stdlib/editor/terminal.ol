// editor/terminal.ol — Terminal panel for O Editor
// Ctrl-T toggles panel. Type commands, press Enter to run.

let _tp_lines = [];        // output lines (scrollback)
let _tp_input = "";        // current input
let _tp_scroll = 0;        // scroll offset
let _tp_proc = [];         // current process [pid, stdin_fd, stdout_fd]
let _tp_cwd = ".";         // working directory

fn tp_init() {
    _tp_lines = [];
    push(_tp_lines, "── Terminal ── (type command, Enter to run, Ctrl-T to close)");
    _tp_input = "";
    _tp_scroll = 0;
    _tp_proc = [];
    _tp_cwd = ".";
}

fn tp_run_cmd(_tc_cmd) {
    push(_tp_lines, "$ " + _tc_cmd);
    // Run via __spawn for non-blocking output capture
    let _tc_full = "cd " + _tp_cwd + " && " + _tc_cmd + " 2>&1";
    let _tc_out = __system(_tc_full);
    // Split output by newlines
    let _tc_i = 0;
    let _tc_start = 0;
    while _tc_i <= len(_tc_out) {
        if _tc_i == len(_tc_out) || char_at(_tc_out, _tc_i) == "\n" {
            if _tc_i > _tc_start {
                push(_tp_lines, __substr(_tc_out, _tc_start, _tc_i));
            };
            _tc_start = _tc_i + 1;
        };
        _tc_i = _tc_i + 1;
    };
    // Handle cd command — update cwd
    if len(_tc_cmd) >= 3 {
        if __substr(_tc_cmd, 0, 3) == "cd " {
            let _tc_dir = __substr(_tc_cmd, 3, len(_tc_cmd));
            // Resolve via shell
            let _tc_pwd = __system("cd " + _tp_cwd + " && cd " + _tc_dir + " && pwd 2>/dev/null");
            if len(_tc_pwd) > 0 {
                // Remove trailing newline
                if char_at(_tc_pwd, len(_tc_pwd) - 1) == "\n" {
                    _tc_pwd = __substr(_tc_pwd, 0, len(_tc_pwd) - 1);
                };
                _tp_cwd = _tc_pwd;
            };
        };
    };
    // Auto-scroll to bottom
    _tp_scroll = len(_tp_lines);
}

fn tp_render(_tr_top, _tr_height, _tr_width) {
    // Render terminal panel starting at row _tr_top, _tr_height rows, _tr_width cols
    let _tr_i = 0;
    let _tr_vis = _tr_height - 1;  // reserve 1 row for input
    // Auto-scroll: show last _tr_vis lines
    let _tr_start = len(_tp_lines) - _tr_vis;
    if _tr_start < 0 { _tr_start = 0; };
    while _tr_i < _tr_vis {
        term_goto(_tr_top + _tr_i, 1);
        term_bg(233); term_color(250);
        let _tr_li = _tr_start + _tr_i;
        if _tr_li < len(_tp_lines) {
            let _tr_line = _tp_lines[_tr_li];
            if len(_tr_line) > _tr_width {
                _tr_line = __substr(_tr_line, 0, _tr_width);
            };
            __write_raw(_tr_line);
            let _tr_pad = _tr_width - len(_tr_line);
            let _tr_p = 0;
            while _tr_p < _tr_pad { __write_raw(" "); _tr_p = _tr_p + 1; };
        } else {
            let _tr_p = 0;
            while _tr_p < _tr_width { __write_raw(" "); _tr_p = _tr_p + 1; };
        };
        _tr_i = _tr_i + 1;
    };
    // Input line
    term_goto(_tr_top + _tr_vis, 1);
    term_bg(236); term_color(40); term_bold();
    let _tr_prompt = _tp_cwd + "$ " + _tp_input;
    if len(_tr_prompt) > _tr_width {
        _tr_prompt = __substr(_tr_prompt, len(_tr_prompt) - _tr_width, len(_tr_prompt));
    };
    __write_raw(_tr_prompt);
    let _tr_pp = _tr_width - len(_tr_prompt);
    let _tr_ppi = 0;
    while _tr_ppi < _tr_pp { __write_raw(" "); _tr_ppi = _tr_ppi + 1; };
    term_reset();
}

fn tp_handle_key(_th_key) {
    // Returns 1 if handled, 0 if should close terminal
    if _th_key == 13 || _th_key == 10 {
        // Enter — run command
        if len(_tp_input) > 0 {
            tp_run_cmd(_tp_input);
            _tp_input = "";
        };
        return 1;
    };
    if _th_key == 127 {
        // Backspace
        if len(_tp_input) > 0 {
            _tp_input = __substr(_tp_input, 0, len(_tp_input) - 1);
        };
        return 1;
    };
    if _th_key == 20 {
        // Ctrl-T — close terminal
        return 0;
    };
    if _th_key == 12 {
        // Ctrl-L — clear
        _tp_lines = [];
        push(_tp_lines, "── Terminal ──");
        return 1;
    };
    if _th_key >= 32 {
        // Printable char
        _tp_input = _tp_input + __chr(_th_key);
        return 1;
    };
    return 1;
}
