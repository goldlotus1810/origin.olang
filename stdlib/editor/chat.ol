// editor/chat.ol — Claude chat panel for O Editor
// Sends selected code or typed messages to Claude, displays responses.

let _ch_lines = [];        // chat history lines
let _ch_input = "";        // current input
let _ch_proc = [];         // Claude process [pid, stdin_fd, stdout_fd]
let _ch_active = 0;        // 1 if Claude process is running

fn ch_init() {
    _ch_lines = [];
    push(_ch_lines, "── Claude ── (type message, Enter to send, Ctrl-A to close)");
    push(_ch_lines, "Starting claude...");
    _ch_input = "";
    // Spawn claude in print mode
    _ch_proc = __spawn("claude --print 2>/dev/null");
    if len(_ch_proc) == 3 {
        _ch_active = 1;
        push(_ch_lines, "Claude ready.");
    } else {
        push(_ch_lines, "Failed to start claude.");
        _ch_active = 0;
    };
}

fn ch_send(_cs_msg) {
    push(_ch_lines, "You: " + _cs_msg);
    if _ch_active == 1 {
        __pipe_write(_ch_proc[1], _cs_msg + "\n");
        // Wait for response
        __sleep(500);
        let _cs_tries = 0;
        let _cs_response = "";
        while _cs_tries < 20 {
            let _cs_ready = __poll_ready(_ch_proc[2], 500);
            if _cs_ready == 1 {
                let _cs_chunk = __pipe_read(_ch_proc[2]);
                if len(_cs_chunk) > 0 {
                    _cs_response = _cs_response + _cs_chunk;
                    _cs_tries = 0;
                } else {
                    _cs_tries = _cs_tries + 1;
                };
            } else {
                if len(_cs_response) > 0 { break; };
                _cs_tries = _cs_tries + 1;
            };
        };
        if len(_cs_response) > 0 {
            // Split response by newlines
            push(_ch_lines, "");
            let _cs_i = 0;
            let _cs_start = 0;
            while _cs_i <= len(_cs_response) {
                if _cs_i == len(_cs_response) || char_at(_cs_response, _cs_i) == "\n" {
                    push(_ch_lines, __substr(_cs_response, _cs_start, _cs_i));
                    _cs_start = _cs_i + 1;
                };
                _cs_i = _cs_i + 1;
            };
            push(_ch_lines, "");
        } else {
            push(_ch_lines, "(no response)");
        };
    } else {
        push(_ch_lines, "(Claude not connected)");
    };
}

fn ch_close() {
    if _ch_active == 1 {
        __process_kill(_ch_proc[0]);
        _ch_active = 0;
    };
}

fn ch_render(_cr_top, _cr_height, _cr_width) {
    let _cr_vis = _cr_height - 1;
    let _cr_start = len(_ch_lines) - _cr_vis;
    if _cr_start < 0 { _cr_start = 0; };
    let _cr_i = 0;
    while _cr_i < _cr_vis {
        term_goto(_cr_top + _cr_i, 1);
        term_bg(232); term_color(147);
        let _cr_li = _cr_start + _cr_i;
        if _cr_li < len(_ch_lines) {
            let _cr_line = _ch_lines[_cr_li];
            if len(_cr_line) > _cr_width {
                _cr_line = __substr(_cr_line, 0, _cr_width);
            };
            // Color "You:" lines differently
            if len(_cr_line) >= 4 {
                if __substr(_cr_line, 0, 4) == "You:" {
                    term_color(75); term_bold();
                };
            };
            __write_raw(_cr_line);
            let _cr_pad = _cr_width - len(_cr_line);
            let _cr_p = 0;
            while _cr_p < _cr_pad { __write_raw(" "); _cr_p = _cr_p + 1; };
        } else {
            let _cr_p = 0;
            while _cr_p < _cr_width { __write_raw(" "); _cr_p = _cr_p + 1; };
        };
        term_reset();
        _cr_i = _cr_i + 1;
    };
    // Input line
    term_goto(_cr_top + _cr_vis, 1);
    term_bg(236); term_color(183); term_bold();
    let _cr_prompt = "⦿ " + _ch_input;
    if len(_cr_prompt) > _cr_width {
        _cr_prompt = __substr(_cr_prompt, len(_cr_prompt) - _cr_width, len(_cr_prompt));
    };
    __write_raw(_cr_prompt);
    let _cr_pp = _cr_width - len(_cr_prompt);
    let _cr_ppi = 0;
    while _cr_ppi < _cr_pp { __write_raw(" "); _cr_ppi = _cr_ppi + 1; };
    term_reset();
}

fn ch_handle_key(_ck_key) {
    if _ck_key == 13 || _ck_key == 10 {
        if len(_ch_input) > 0 {
            ch_send(_ch_input);
            _ch_input = "";
        };
        return 1;
    };
    if _ck_key == 127 {
        if len(_ch_input) > 0 {
            _ch_input = __substr(_ch_input, 0, len(_ch_input) - 1);
        };
        return 1;
    };
    if _ck_key == 1 {
        // Ctrl-A — close chat
        ch_close();
        return 0;
    };
    if _ck_key == 12 {
        // Ctrl-L — clear
        _ch_lines = [];
        push(_ch_lines, "── Claude ──");
        return 1;
    };
    if _ck_key >= 32 {
        _ch_input = _ch_input + __chr(_ck_key);
        return 1;
    };
    return 1;
}
