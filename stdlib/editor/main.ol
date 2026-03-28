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

    // Enter alternate screen buffer (like vim/htop)
    __write_raw(__esc()); __write_raw("[?1049h");
    term_hide_cursor();
    term_clear();
    let _need_render = 1;
    let _last_key = 0;
    let _scroll_col = 0;

    while _running == 1 {
        if _need_render == 1 {
        _need_render = 0;
        // Render (overwrite in place, no clear — reduces flicker)
        term_hide_cursor();
        term_goto(1, 1);
        term_bg(235); term_color(69); term_bold();
        term_fill_line(" O ─ " + _path, _cols);
        term_reset();

        // Render editor lines
        let _i = 0;
        while _i < _rows - 2 {
            term_goto(_i + 2, 1);
            let _li = _scroll + _i;
            if _li < len(_lines) {
                term_bg(234); term_color(238);
                let _num = __to_string(_li + 1);
                if _li + 1 < 10 { term_write("  " + _num + " "); }
                else { if _li + 1 < 100 { term_write(" " + _num + " "); }
                else { term_write(_num + " "); }; };
                term_color(237); term_write("│ ");
                term_color(252);
                let _text_w = _cols - 6;
                let _line_text = _lines[_li];
                if _scroll_col > 0 {
                    if _scroll_col < len(_line_text) {
                        _line_text = __substr(_line_text, _scroll_col, len(_line_text));
                    } else { _line_text = ""; };
                };
                term_fill_line(_line_text, _text_w);
            } else {
                term_bg(234); term_color(238);
                term_fill_line("~", _cols);
            };
            _i = _i + 1;
        };

        // Status bar
        term_goto(_rows, 1);
        term_bg(235); term_color(252);
        term_fill_line(" " + _mode + " │ Ln " + __to_string(_cur_row + 1) + ", Col " + __to_string(_cur_col + 1) + " │ " + __to_string(len(_lines)) + " lines │ key=" + __to_string(_last_key), _cols);
        term_reset();

        // Cursor
        term_goto(_cur_row - _scroll + 2, _cur_col - _scroll_col + 7);
        term_show_cursor();
        }; // end if _need_render

        // Read key (blocking — waits for input)
        let _key = __read_byte();
        if _key < 0 { __sleep(50); } else {
            _need_render = 1;
            _last_key = _key;
            if _key == 17 { _running = 0; }   // Ctrl-Q = quit
            else { if _key == 27 {               // ESC or arrow key
                let _k2 = __read_byte();
                if _k2 == 91 {
                    // Arrow key sequence — works in BOTH modes
                    let _k3 = __read_byte();
                    if _k3 == 65 { if _cur_row > 0 { _cur_row = _cur_row - 1; }; };     // Up
                    if _k3 == 66 { if _cur_row < len(_lines) - 1 { _cur_row = _cur_row + 1; }; }; // Down
                    if _k3 == 67 { _cur_col = _cur_col + 1; };                           // Right
                    if _k3 == 68 { if _cur_col > 0 { _cur_col = _cur_col - 1; }; };     // Left
                } else {
                    // Bare ESC — switch to NORMAL
                    if _mode == "INSERT" { _mode = "NORMAL"; };
                };
            } else { if _mode == "NORMAL" {
                if _key == 105 { _mode = "INSERT"; }          // i — mode switch only
                else { if _key == 106 { if _cur_row < len(_lines) - 1 { _cur_row = _cur_row + 1; }; }  // j
                else { if _key == 107 { if _cur_row > 0 { _cur_row = _cur_row - 1; }; }                // k
                else { if _key == 104 { if _cur_col > 0 { _cur_col = _cur_col - 1; }; }                // h
                else { if _key == 108 { _cur_col = _cur_col + 1; };                                    // l
                }; }; }; };
            } else {
                // INSERT mode — type text
                if _key == 127 {
                    if _cur_col > 0 {
                        let _line = _lines[_cur_row];
                        set_at(_lines, _cur_row, __substr(_line, 0, _cur_col - 1) + __substr(_line, _cur_col, len(_line)));
                        _cur_col = _cur_col - 1;
                    };
                } else { if _key == 13 || _key == 10 { // Enter (CR or LF)
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
                } else { if _key >= 32 {
                    let _line = _lines[_cur_row];
                    set_at(_lines, _cur_row, __substr(_line, 0, _cur_col) + __chr(_key) + __substr(_line, _cur_col, len(_line)));
                    _cur_col = _cur_col + 1;
                }; }; };
            }; }; };
            // Clamp cursor col to line length
            let _line_len = len(_lines[_cur_row]);
            if _cur_col > _line_len { _cur_col = _line_len; };
            // Vertical scroll
            if _cur_row < _scroll { _scroll = _cur_row; };
            if _cur_row >= _scroll + _rows - 2 { _scroll = _cur_row - _rows + 3; };
            // Horizontal scroll
            let _text_w = _cols - 6;
            if _cur_col < _scroll_col { _scroll_col = _cur_col; };
            if _cur_col >= _scroll_col + _text_w { _scroll_col = _cur_col - _text_w + 1; };
        };
    };

    // Leave alternate screen buffer
    __write_raw(__esc()); __write_raw("[?1049l");
    term_show_cursor();
    term_reset();
    __term_cooked();
    return "O Editor closed";
}
