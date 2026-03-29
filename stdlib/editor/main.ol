// editor/main.ol — O Editor entry point

pub fn editor_start(_path) {
    let _tr = __term_raw();

    let _cols = term_cols();
    let _rows = term_rows();
    if _cols < 10 { _cols = 80; };
    if _rows < 5 { _rows = 24; };

    let _lines = buf_new();
    if len(_path) > 0 { _lines = buf_load(_path); };

    let _mode = "NORMAL";
    let _cur_row = 0;
    let _cur_col = 0;
    let _scroll = 0;
    let _running = 1;
    let _need_render = 1;
    let _last_key = 0;
    let _scroll_col = 0;

    // Search state
    let _search = "";
    let _searching = 0;

    // Command palette state
    let _cmd_buf = "";

    // Terminal panel state
    let _term_open = 0;
    let _term_height = 10;

    // Chat panel state
    let _chat_open = 0;
    let _chat_height = 12;

    // File tree state
    let _ft_open = 0;
    let _ft_focus = 0;
    let _ft_files = [];
    let _ft_sel = 0;
    let _ft_scroll = 0;
    let _ft_width = 24;
    let _ft_dir = ".";

    // Enter alternate screen buffer
    __write_raw(__esc()); __write_raw("[?1049h");
    __write_raw(__esc()); __write_raw("[?2004h");
    term_hide_cursor();
    term_clear();

    while _running == 1 {
        if _need_render == 1 {
        _need_render = 0;
        term_hide_cursor();

        // Calculate editor offset (shifted right when file tree is open)
        let _ed_off = 0;
        if _ft_open == 1 { _ed_off = _ft_width + 1; };
        let _ed_cols = _cols - _ed_off;

        // Title bar
        term_goto(1, 1);
        term_bg(235); term_color(69); term_bold();
        term_fill_line(" O ─ " + _path, _cols);
        term_reset();

        // File tree panel (if open)
        if _ft_open == 1 {
            let _fi = 0;
            while _fi < _rows - 2 {
                term_goto(_fi + 2, 1);
                term_bg(236);
                let _idx = _ft_scroll + _fi;
                if _idx < len(_ft_files) {
                    let _fname = _ft_files[_idx];
                    if _idx == _ft_sel {
                        term_bg(238); term_color(75); term_bold();
                    } else {
                        // Dirs in blue, files in white
                        let _fnlen = len(_fname);
                        if __substr(_fname, _fnlen - 1, _fnlen) == "/" {
                            term_color(75);
                        } else { term_color(252); };
                    };
                    if len(_fname) > _ft_width - 2 {
                        _fname = __substr(_fname, 0, _ft_width - 2);
                    };
                    __write_raw(" ");
                    __write_raw(_fname);
                    let _pad = _ft_width - len(_fname) - 1;
                    let _pp = 0;
                    while _pp < _pad { __write_raw(" "); _pp = _pp + 1; };
                } else {
                    let _pp = 0;
                    while _pp < _ft_width { __write_raw(" "); _pp = _pp + 1; };
                };
                term_reset();
                // Separator
                term_bg(234); term_color(237);
                __write_raw("│");
                _fi = _fi + 1;
            };
        };

        // Render editor lines
        let _ed_rows = _rows - 2;
        if _term_open == 1 { _ed_rows = _ed_rows - _term_height - 1; };
        if _chat_open == 1 { _ed_rows = _ed_rows - _chat_height - 1; };
        let _i = 0;
        while _i < _ed_rows {
            term_goto(_i + 2, _ed_off + 1);
            let _li = _scroll + _i;
            if _li < len(_lines) {
                term_bg(234); term_color(238);
                let _num = __to_string(_li + 1);
                if _li + 1 < 10 { term_write("  " + _num + " "); }
                else { if _li + 1 < 100 { term_write(" " + _num + " "); }
                else { term_write(_num + " "); }; };
                term_color(237); term_write("│ ");
                term_color(252);
                let _text_w = _ed_cols - 6;
                if _text_w < 1 { _text_w = 1; };
                let _line_text = _lines[_li];
                if _scroll_col > 0 {
                    if _scroll_col < len(_line_text) {
                        _line_text = __substr(_line_text, _scroll_col, len(_line_text));
                    } else { _line_text = ""; };
                };
                render_line_hl(_line_text, _text_w);
            } else {
                term_bg(234); term_color(238);
                term_fill_line("~", _ed_cols);
            };
            _i = _i + 1;
        };

        // Terminal panel (if open)
        if _term_open == 1 {
            // Separator line
            term_goto(_rows - _term_height - 1, 1);
            term_bg(235); term_color(237);
            let _sep = 0;
            while _sep < _cols { __write_raw("─"); _sep = _sep + 1; };
            term_reset();
            tp_render(_rows - _term_height, _term_height, _cols);
        };

        // Chat panel (if open)
        if _chat_open == 1 {
            let _ch_top = _rows - _term_height - _chat_height - 1;
            if _term_open == 0 { _ch_top = _rows - _chat_height - 1; };
            // Separator
            term_goto(_ch_top, 1);
            term_bg(235); term_color(183);
            let _csep = 0;
            while _csep < _cols { __write_raw("─"); _csep = _csep + 1; };
            term_reset();
            ch_render(_ch_top + 1, _chat_height, _cols);
        };

        // Status bar
        term_goto(_rows, 1);
        term_bg(235); term_color(252);
        let _status = " " + _mode;
        if _ft_focus == 1 { _status = " TREE"; };
        if _mode == "SEARCH" { _status = " /" + _search; }
        else { if _mode == "COMMAND" { _status = " :" + _cmd_buf; } }
        else { _status = _status + " │ Ln " + __to_string(_cur_row + 1) + ", Col " + __to_string(_cur_col + 1) + " │ " + __to_string(len(_lines)) + " lines"; };
        if len(_search) > 0 { if _mode != "SEARCH" { _status = _status + " │ /" + _search; }; };
        term_fill_line(_status, _cols);
        term_reset();

        // Cursor positioning
        if _chat_open == 1 {
            let _ch_input_row = _rows - 1;
            if _term_open == 1 { _ch_input_row = _rows - _term_height - 1; };
            term_goto(_ch_input_row, len(_ch_input) + 3);
            term_show_cursor();
        } else { if _term_open == 1 {
            let _tc_prompt_len = len(_tp_cwd) + 2 + len(_tp_input);
            term_goto(_rows - 1, _tc_prompt_len + 1);
            term_show_cursor();
        } else { if _ft_focus == 0 {
            term_goto(_cur_row - _scroll + 2, _ed_off + _cur_col - _scroll_col + 7);
            term_show_cursor();
        }; }; };
        }; // end if _need_render

        // Read key
        let _key = __read_byte();
        if _key < 0 { __sleep(50); } else {
            _need_render = 1;
            _last_key = _key;

            if _key == 17 { _running = 0; }   // Ctrl-Q = quit
            else { if _chat_open == 1 {
                // Chat panel is open — route keys to chat
                let _ck = ch_handle_key(_key);
                if _ck == 0 {
                    _chat_open = 0;
                    term_clear();
                };
            } else { if _term_open == 1 {
                // Terminal panel is open — route all keys to terminal
                let _th = tp_handle_key(_key);
                if _th == 0 {
                    _term_open = 0;
                    term_clear();
                };
            } else { if _key == 1 {                // Ctrl-A = toggle chat
                _chat_open = 1;
                ch_init();
                term_clear();
            } else { if _key == 20 {              // Ctrl-T = toggle terminal
                _term_open = 1;
                tp_init();
                term_clear();
            }
            else { if _key == 19 {              // Ctrl-S = save
                if len(_path) > 0 {
                    let _save_buf = "";
                    let _si = 0;
                    while _si < len(_lines) {
                        if _si > 0 { _save_buf = _save_buf + "\n"; };
                        _save_buf = _save_buf + _lines[_si];
                        _si = _si + 1;
                    };
                    _save_buf = _save_buf + "\n";
                    __file_write(_path, _save_buf);
                    _mode = "SAVED";
                };
            } else { if _ft_focus == 1 {
                // FILE TREE FOCUSED
                if _key == 106 {                // j — down
                    if _ft_sel < len(_ft_files) - 1 { _ft_sel = _ft_sel + 1; };
                } else { if _key == 107 {       // k — up
                    if _ft_sel > 0 { _ft_sel = _ft_sel - 1; };
                } else { if _key == 13 || _key == 10 {  // Enter — open file
                    if _ft_sel < len(_ft_files) {
                        let _sel_name = _ft_files[_ft_sel];
                        let _snlen = len(_sel_name);
                        if __substr(_sel_name, _snlen - 1, _snlen) == "/" {
                            // Directory — enter it
                            let _subdir = __substr(_sel_name, 0, _snlen - 1);
                            _ft_dir = _ft_dir + "/" + _subdir;
                            _ft_files = ft_scan(_ft_dir);
                            _ft_sel = 0;
                            _ft_scroll = 0;
                        } else {
                            // File — open it
                            _path = _ft_dir + "/" + _sel_name;
                            _lines = buf_load(_path);
                            _cur_row = 0;
                            _cur_col = 0;
                            _scroll = 0;
                            _scroll_col = 0;
                            _ft_focus = 0;
                            term_clear();
                        };
                    };
                } else { if _key == 27 || _key == 101 { // ESC or 'e' — back to editor
                    _ft_focus = 0;
                } else { if _key == 104 {       // h — go up directory
                    // Find last / in _ft_dir
                    let _dlen = len(_ft_dir);
                    if _dlen > 1 {
                        let _di = _dlen - 1;
                        let _found = 0;
                        while _found == 0 {
                            if _di <= 0 { _found = 1; }
                            else {
                                if __substr(_ft_dir, _di, _di + 1) == "/" {
                                    _ft_dir = __substr(_ft_dir, 0, _di);
                                    _found = 1;
                                } else { _di = _di - 1; };
                            };
                        };
                        if _di <= 0 { _ft_dir = "."; };
                        _ft_files = ft_scan(_ft_dir);
                        _ft_sel = 0;
                        _ft_scroll = 0;
                    };
                }; }; }; }; };
                // File tree scroll
                if _ft_sel < _ft_scroll { _ft_scroll = _ft_sel; };
                if _ft_sel >= _ft_scroll + _rows - 2 { _ft_scroll = _ft_sel - _rows + 3; };
            } else { if _key == 27 {               // ESC or arrow key
                let _k2 = __read_byte();
                if _k2 == 91 {
                    let _k3 = __read_byte();
                    if _k3 == 65 { if _cur_row > 0 { _cur_row = _cur_row - 1; }; }     // Up
                    else { if _k3 == 66 { if _cur_row < len(_lines) - 1 { _cur_row = _cur_row + 1; }; } // Down
                    else { if _k3 == 67 { _cur_col = _cur_col + 1; }                    // Right
                    else { if _k3 == 68 { if _cur_col > 0 { _cur_col = _cur_col - 1; }; } // Left
                    else { if _k3 == 50 {
                        // Paste start: ESC[200~
                        let _k4 = __read_byte();
                        if _k4 == 48 {
                            let _k5 = __read_byte();
                            if _k5 == 48 {
                                let _k6 = __read_byte();
                                if _k6 == 126 {
                                    let _paste_end = 0;
                                    while _paste_end == 0 {
                                        let _pb = __read_byte();
                                        if _pb < 0 { _paste_end = 1; }
                                        else { if _pb == 27 {
                                            let _pe2 = __read_byte();
                                            if _pe2 == 91 {
                                                let _pe3 = __read_byte();
                                                if _pe3 == 50 {
                                                    let _pe4 = __read_byte();
                                                    if _pe4 == 48 {
                                                        let _pe5 = __read_byte();
                                                        if _pe5 == 49 {
                                                            let _pe6 = __read_byte();
                                                            _paste_end = 1;
                                                        };
                                                    };
                                                };
                                            };
                                        } else { if _pb == 10 || _pb == 13 {
                                            let _pline = _lines[_cur_row];
                                            set_at(_lines, _cur_row, __substr(_pline, 0, _cur_col));
                                            let _pnew = [];
                                            let _pni = 0;
                                            while _pni < len(_lines) {
                                                push(_pnew, _lines[_pni]);
                                                if _pni == _cur_row { push(_pnew, __substr(_pline, _cur_col, len(_pline))); };
                                                _pni = _pni + 1;
                                            };
                                            _lines = _pnew;
                                            _cur_row = _cur_row + 1;
                                            _cur_col = 0;
                                        } else { if _pb >= 32 {
                                            let _pline2 = _lines[_cur_row];
                                            set_at(_lines, _cur_row, __substr(_pline2, 0, _cur_col) + __chr(_pb) + __substr(_pline2, _cur_col, len(_pline2)));
                                            _cur_col = _cur_col + 1;
                                        }; }; }; };
                                    };
                                };
                            };
                        };
                    } else { if _k3 == 49 {
                        // Could be F5: ESC[15~ (bytes: 27 91 49 53 126)
                        let _fk4 = __read_byte();
                        if _fk4 == 53 {
                            let _fk5 = __read_byte();
                            if _fk5 == 126 {
                                // F5 — save + compile + run
                                if len(_path) > 0 {
                                    // Save first
                                    let _save_buf = "";
                                    let _fsi = 0;
                                    while _fsi < len(_lines) {
                                        if _fsi > 0 { _save_buf = _save_buf + "\n"; };
                                        _save_buf = _save_buf + _lines[_fsi];
                                        _fsi = _fsi + 1;
                                    };
                                    _save_buf = _save_buf + "\n";
                                    __file_write(_path, _save_buf);
                                    // Exit alternate screen
                                    __write_raw(__esc()); __write_raw("[?1049l");
                                    __term_cooked();
                                    // Run the file
                                    let _run_out = __system("./origin.olang " + _path + " 2>&1");
                                    __write_raw("\n─── Output ───\n");
                                    __write_raw(_run_out);
                                    __write_raw("\n─── Press any key ───\n");
                                    __term_raw();
                                    let _wait = __read_byte();
                                    while _wait < 0 { __sleep(50); _wait = __read_byte(); };
                                    // Re-enter alternate screen
                                    __write_raw(__esc()); __write_raw("[?1049h");
                                    term_clear();
                                };
                            };
                        };
                    }; }; }; }; }; };
                } else {
                    // Bare ESC
                    if _mode == "INSERT" { _mode = "NORMAL"; };
                };
            } else { if _mode == "SEARCH" {
                if _key == 27 { _mode = "NORMAL"; _searching = 0; }         // ESC cancel
                else { if _key == 13 || _key == 10 {                         // Enter confirm
                    _mode = "NORMAL";
                    _searching = 0;
                    // Jump to first match from current position
                    if len(_search) > 0 {
                        let _found = 0;
                        let _sr = _cur_row;
                        let _sc = _cur_col;
                        while _found == 0 {
                            if _sr >= len(_lines) { _found = 2; }
                            else {
                                let _sline = _lines[_sr];
                                let _hits = __str_find(_sline, _search);
                                let _hi = 0;
                                while _hi < len(_hits) {
                                    if _hits[_hi] >= _sc {
                                        if _found == 0 {
                                            _cur_row = _sr;
                                            _cur_col = _hits[_hi];
                                            _found = 1;
                                        };
                                    };
                                    _hi = _hi + 1;
                                };
                                _sr = _sr + 1;
                                _sc = 0;
                            };
                        };
                    };
                } else { if _key == 127 {                                    // Backspace
                    if len(_search) > 0 {
                        _search = __substr(_search, 0, len(_search) - 1);
                    };
                } else { if _key >= 32 {                                     // Printable char
                    _search = _search + __chr(_key);
                }; }; }; };
            } else { if _mode == "COMMAND" {
                if _key == 27 { _mode = "NORMAL"; }
                else { if _key == 13 || _key == 10 {
                    _mode = "NORMAL";
                    // Execute command
                    if _cmd_buf == "q" { _running = 0; }
                    else { if _cmd_buf == "w" {
                        if len(_path) > 0 {
                            let _sv = "";
                            let _svi = 0;
                            while _svi < len(_lines) {
                                if _svi > 0 { _sv = _sv + "\n"; };
                                _sv = _sv + _lines[_svi];
                                _svi = _svi + 1;
                            };
                            __file_write(_path, _sv + "\n");
                            _mode = "SAVED";
                        };
                    } else { if _cmd_buf == "wq" {
                        if len(_path) > 0 {
                            let _sv = "";
                            let _svi = 0;
                            while _svi < len(_lines) {
                                if _svi > 0 { _sv = _sv + "\n"; };
                                _sv = _sv + _lines[_svi];
                                _svi = _svi + 1;
                            };
                            __file_write(_path, _sv + "\n");
                        };
                        _running = 0;
                    } else { if _cmd_buf == "build" {
                        // Exit alt screen, run make self-build
                        __write_raw(__esc()); __write_raw("[?1049l");
                        __term_cooked();
                        let _bout = __system("cd " + _tp_cwd + " && make self-build 2>&1");
                        __write_raw("\n─── Build ───\n" + _bout + "\n─── Press any key ───\n");
                        __term_raw();
                        let _w = __read_byte();
                        while _w < 0 { __sleep(50); _w = __read_byte(); };
                        __write_raw(__esc()); __write_raw("[?1049h");
                        term_clear();
                    } else { if _cmd_buf == "test" {
                        __write_raw(__esc()); __write_raw("[?1049l");
                        __term_cooked();
                        let _tout = __system("cd " + _tp_cwd + " && bash tests.sh 2>&1");
                        __write_raw("\n─── Tests ───\n" + _tout + "\n─── Press any key ───\n");
                        __term_raw();
                        let _w = __read_byte();
                        while _w < 0 { __sleep(50); _w = __read_byte(); };
                        __write_raw(__esc()); __write_raw("[?1049h");
                        term_clear();
                    } else {
                        // Run as shell command
                        if len(_cmd_buf) > 1 {
                            if __substr(_cmd_buf, 0, 1) == "!" {
                                __write_raw(__esc()); __write_raw("[?1049l");
                                __term_cooked();
                                let _sout = __system(__substr(_cmd_buf, 1, len(_cmd_buf)) + " 2>&1");
                                __write_raw("\n" + _sout + "\n─── Press any key ───\n");
                                __term_raw();
                                let _w = __read_byte();
                                while _w < 0 { __sleep(50); _w = __read_byte(); };
                                __write_raw(__esc()); __write_raw("[?1049h");
                                term_clear();
                            };
                        };
                    }; }; }; }; }; };
                    _cmd_buf = "";
                } else { if _key == 127 {
                    if len(_cmd_buf) > 0 { _cmd_buf = __substr(_cmd_buf, 0, len(_cmd_buf) - 1); };
                } else { if _key >= 32 {
                    _cmd_buf = _cmd_buf + __chr(_key);
                }; }; }; };
            } else { if _mode == "SAVED" { _mode = "NORMAL"; }
            else { if _mode == "NORMAL" {
                // Extended keys (sequential ifs to stay under else-if depth limit)
                let _nx = 0;
                if _key == 103 { _cur_row = 0; _cur_col = 0; _nx = 1; };
                if _key == 48 { _cur_col = 0; _nx = 1; };
                if _key == 36 { _cur_col = len(_lines[_cur_row]); _nx = 1; };
                if _key == 68 {
                    if len(_lines) > 1 {
                        let _dd_new = [];
                        let _dd_i = 0;
                        while _dd_i < len(_lines) {
                            if _dd_i != _cur_row { push(_dd_new, _lines[_dd_i]); };
                            _dd_i = _dd_i + 1;
                        };
                        _lines = _dd_new;
                        if _cur_row >= len(_lines) { _cur_row = len(_lines) - 1; };
                    } else { set_at(_lines, 0, ""); _cur_col = 0; };
                    _nx = 1;
                };
                // Main key chain (only if not handled above)
                if _nx == 0 {
                if _key == 105 { _mode = "INSERT"; }          // i
                else { if _key == 106 { if _cur_row < len(_lines) - 1 { _cur_row = _cur_row + 1; }; }  // j
                else { if _key == 107 { if _cur_row > 0 { _cur_row = _cur_row - 1; }; }                // k
                else { if _key == 104 { if _cur_col > 0 { _cur_col = _cur_col - 1; }; }                // h
                else { if _key == 108 { _cur_col = _cur_col + 1; }                                     // l
                else { if _key == 101 {                                                                  // e — toggle file tree
                    if _ft_open == 0 {
                        _ft_open = 1;
                        _ft_focus = 1;
                        _ft_files = ft_scan(_ft_dir);
                        _ft_sel = 0;
                        _ft_scroll = 0;
                        term_clear();
                    } else {
                        _ft_open = 0;
                        _ft_focus = 0;
                        term_clear();
                    };
                } else { if _key == 120 {                                                                // x — delete char at cursor
                    let _line = _lines[_cur_row];
                    if _cur_col < len(_line) {
                        set_at(_lines, _cur_row, __substr(_line, 0, _cur_col) + __substr(_line, _cur_col + 1, len(_line)));
                    };
                } else { if _key == 111 {                                                                // o — new line below, enter INSERT
                    let _new = [];
                    let _oi = 0;
                    while _oi < len(_lines) {
                        push(_new, _lines[_oi]);
                        if _oi == _cur_row { push(_new, ""); };
                        _oi = _oi + 1;
                    };
                    _lines = _new;
                    _cur_row = _cur_row + 1;
                    _cur_col = 0;
                    _mode = "INSERT";
                } else { if _key == 71 {                                                                 // G — go to last line
                    _cur_row = len(_lines) - 1;
                    _cur_col = 0;
                } else { if _key == 58 {                                                                 // : — command palette
                    _cmd_buf = "";
                    _mode = "COMMAND";
                } else { if _key == 47 {                                                                 // / — start search
                    _searching = 1;
                    _search = "";
                    _mode = "SEARCH";
                } else { if _key == 110 {                                                                // n — next match
                    if len(_search) > 0 {
                        let _found = 0;
                        let _sr = _cur_row;
                        let _sc = _cur_col + 1;
                        while _found == 0 {
                            if _sr >= len(_lines) { _found = 2; }
                            else {
                                let _sline = _lines[_sr];
                                let _hits = __str_find(_sline, _search);
                                let _hi = 0;
                                while _hi < len(_hits) {
                                    if _hits[_hi] >= _sc {
                                        if _found == 0 {
                                            _cur_row = _sr;
                                            _cur_col = _hits[_hi];
                                            _found = 1;
                                        };
                                    };
                                    _hi = _hi + 1;
                                };
                                _sr = _sr + 1;
                                _sc = 0;
                            };
                        };
                    };
                } else { if _key == 78 {                                                                // N — prev match
                    if len(_search) > 0 {
                        let _found = 0;
                        let _sr = _cur_row;
                        let _sc = _cur_col - 1;
                        while _found == 0 {
                            if _sr < 0 { _found = 2; }
                            else {
                                let _sline = _lines[_sr];
                                let _hits = __str_find(_sline, _search);
                                let _hi = len(_hits) - 1;
                                while _hi >= 0 {
                                    if _hits[_hi] <= _sc {
                                        if _found == 0 {
                                            _cur_row = _sr;
                                            _cur_col = _hits[_hi];
                                            _found = 1;
                                        };
                                    };
                                    _hi = _hi - 1;
                                };
                                _sr = _sr - 1;
                                if _sr >= 0 { _sc = len(_lines[_sr]); };
                            };
                        };
                    };
                }; }; }; }; }; }; }; }; }; }; }; }; };
                };
            } else {
                // INSERT mode
                if _key == 127 {
                    if _cur_col > 0 {
                        let _line = _lines[_cur_row];
                        set_at(_lines, _cur_row, __substr(_line, 0, _cur_col - 1) + __substr(_line, _cur_col, len(_line)));
                        _cur_col = _cur_col - 1;
                    };
                } else { if _key == 13 || _key == 10 {
                    let _line = _lines[_cur_row];
                    set_at(_lines, _cur_row, __substr(_line, 0, _cur_col));
                    let _new = [];
                    let _ni = 0;
                    while _ni < len(_lines) {
                        push(_new, _lines[_ni]);
                        if _ni == _cur_row { push(_new, __substr(_line, _cur_col, len(_line))); };
                        _ni = _ni + 1;
                    };
                    _lines = _new;
                    _cur_row = _cur_row + 1;
                    _cur_col = 0;
                } else { if _key == 9 {
                    let _line = _lines[_cur_row];
                    set_at(_lines, _cur_row, __substr(_line, 0, _cur_col) + "    " + __substr(_line, _cur_col, len(_line)));
                    _cur_col = _cur_col + 4;
                } else { if _key >= 32 {
                    let _line = _lines[_cur_row];
                    set_at(_lines, _cur_row, __substr(_line, 0, _cur_col) + __chr(_key) + __substr(_line, _cur_col, len(_line)));
                    _cur_col = _cur_col + 1;
                }; }; }; };
            }; }; }; }; }; }; }; }; }; }; }; };
            // Clamp cursor col to line length
            let _line_len = len(_lines[_cur_row]);
            if _cur_col > _line_len { _cur_col = _line_len; };
            // Vertical scroll
            if _cur_row < _scroll { _scroll = _cur_row; };
            if _cur_row >= _scroll + _rows - 2 { _scroll = _cur_row - _rows + 3; };
            // Horizontal scroll
            let _ed_cols2 = _cols;
            if _ft_open == 1 { _ed_cols2 = _cols - _ft_width - 1; };
            let _text_w = _ed_cols2 - 6;
            if _text_w < 1 { _text_w = 1; };
            if _cur_col < _scroll_col { _scroll_col = _cur_col; };
            if _cur_col >= _scroll_col + _text_w { _scroll_col = _cur_col - _text_w + 1; };
        };
    };

    // Cleanup
    __write_raw(__esc()); __write_raw("[?2004l");
    __write_raw(__esc()); __write_raw("[?1049l");
    term_show_cursor();
    term_reset();
    __term_cooked();
    return "O Editor closed";
}
