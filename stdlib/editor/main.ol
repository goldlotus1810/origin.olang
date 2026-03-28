// editor/main.ol — O Editor entry point

pub fn editor_start(_path) {
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

    term_clear();

    while _running == 1 {
        // Render title bar
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
                let _num = to_string(_li + 1);
                if _li + 1 < 10 { term_write("  " + _num + " "); }
                else { if _li + 1 < 100 { term_write(" " + _num + " "); }
                else { term_write(_num + " "); }; };
                term_color(237); term_write("│ ");
                term_color(252);
                term_fill_line(_lines[_li], _cols - 6);
            } else {
                term_bg(234); term_color(238);
                term_fill_line("~", _cols);
            };
            _i = _i + 1;
        };

        // Status bar
        term_goto(_rows, 1);
        term_bg(235); term_color(252);
        term_fill_line(" " + _mode + " │ Ln " + to_string(_cur_row + 1) + ", Col " + to_string(_cur_col + 1) + " │ " + to_string(len(_lines)) + " lines │ Olang", _cols);
        term_reset();

        // Cursor
        term_goto(_cur_row - _scroll + 2, _cur_col + 7);
        term_show_cursor();

        // Read key
        let _key = __read_byte();
        if _key < 0 { __sleep(16); } else {
            if _key == 17 { _running = 0; };   // Ctrl-Q = quit
            if _key == 27 {                     // ESC
                if _mode == "INSERT" { _mode = "NORMAL"; }
                else {
                    let _k2 = __read_byte();
                    if _k2 == 91 {
                        let _k3 = __read_byte();
                        if _k3 == 65 { if _cur_row > 0 { _cur_row = _cur_row - 1; }; };
                        if _k3 == 66 { if _cur_row < len(_lines) - 1 { _cur_row = _cur_row + 1; }; };
                        if _k3 == 67 { _cur_col = _cur_col + 1; };
                        if _k3 == 68 { if _cur_col > 0 { _cur_col = _cur_col - 1; }; };
                    };
                };
            };
            if _mode == "NORMAL" {
                if _key == 105 { _mode = "INSERT"; };          // i
                if _key == 106 { if _cur_row < len(_lines) - 1 { _cur_row = _cur_row + 1; }; }; // j
                if _key == 107 { if _cur_row > 0 { _cur_row = _cur_row - 1; }; };                // k
                if _key == 104 { if _cur_col > 0 { _cur_col = _cur_col - 1; }; };                // h
                if _key == 108 { _cur_col = _cur_col + 1; };                                      // l
            };
            // Scroll
            if _cur_row < _scroll { _scroll = _cur_row; };
            if _cur_row >= _scroll + _rows - 2 { _scroll = _cur_row - _rows + 3; };
        };
    };

    term_clear();
    term_show_cursor();
    term_reset();
    return "O Editor closed";
}
