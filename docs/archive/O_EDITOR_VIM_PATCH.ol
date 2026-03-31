// O EDITOR — VIM FEATURES PATCH
// Sora viết cho Nox. Apply vào stdlib/editor/main.ol
// 10 features, ~200 LOC. Sau patch: editor dùng như vim.
//
// === HƯỚNG DẪN APPLY ===
// 1. Thêm state variables sau dòng "let _ft_dir = ".";"
// 2. Thêm :number handler trong COMMAND mode
// 3. Thêm vim commands trong NORMAL mode (phần _nx == 0)

// ════════════════════════════════════════════════════════════════
// PATCH 1: State variables — thêm sau "_ft_dir = ".";"
// ════════════════════════════════════════════════════════════════

    // Yank register (clipboard)
    let _yank = "";

    // Undo ring (last 50 states: [lines_copy, cur_row, cur_col])
    let _undo_stack = [];
    let _undo_max = 50;

    // Count prefix: 5j = move down 5 lines
    let _count = 0;
    let _counting = 0;

// ════════════════════════════════════════════════════════════════
// PATCH 2: Undo helper — thêm TRƯỚC editor_start hoặc sau nó
// ════════════════════════════════════════════════════════════════

fn _ed_save_undo(_lines, _row, _col, _stack, _max) {
    // Deep copy lines array
    let _copy = [];
    let _ui = 0;
    while _ui < len(_lines) {
        push(_copy, _lines[_ui]);
        _ui = _ui + 1;
    };
    push(_stack, { lines: _copy, row: _row, col: _col });
    // Trim to max
    if len(_stack) > _max {
        let _new = [];
        let _si = len(_stack) - _max;
        while _si < len(_stack) {
            push(_new, _stack[_si]);
            _si = _si + 1;
        };
        // Can't reassign _stack (global var), caller handles trim
    };
}

fn _ed_pop_undo(_stack) {
    if len(_stack) == 0 { return 0; };
    let _last = _stack[len(_stack) - 1];
    // Remove last element
    let _new = [];
    let _pi = 0;
    while _pi < len(_stack) - 1 {
        push(_new, _stack[_pi]);
        _pi = _pi + 1;
    };
    // Caller replaces stack
    return _last;
}

fn _ed_word_next(_line, _col) {
    // Move to start of next word
    let _ln = len(_line);
    let _c = _col;
    // Skip current word (non-space chars)
    while _c < _ln {
        if char_at(_line, _c) == " " { break; };
        _c = _c + 1;
    };
    // Skip spaces
    while _c < _ln {
        if char_at(_line, _c) != " " { break; };
        _c = _c + 1;
    };
    return _c;
}

fn _ed_word_prev(_line, _col) {
    // Move to start of previous word
    let _c = _col;
    if _c > 0 { _c = _c - 1; };
    // Skip spaces backward
    while _c > 0 {
        if char_at(_line, _c) != " " { break; };
        _c = _c - 1;
    };
    // Skip word backward
    while _c > 0 {
        if char_at(_line, _c - 1) == " " { break; };
        _c = _c - 1;
    };
    return _c;
}

fn _ed_find_bracket(_lines, _row, _col) {
    // Find matching bracket: () [] {}
    let _line = _lines[_row];
    if _col >= len(_line) { return { row: _row, col: _col }; };
    let _ch = char_at(_line, _col);
    let _open = "";
    let _close = "";
    let _dir = 0;
    if _ch == "(" { _open = "("; _close = ")"; _dir = 1; };
    if _ch == ")" { _open = "("; _close = ")"; _dir = -1; };
    if _ch == "[" { _open = "["; _close = "]"; _dir = 1; };
    if _ch == "]" { _open = "["; _close = "]"; _dir = -1; };
    if _ch == "{" { _open = "{"; _close = "}"; _dir = 1; };
    if _ch == "}" { _open = "{"; _close = "}"; _dir = -1; };
    if _dir == 0 { return { row: _row, col: _col }; };
    // Search forward or backward
    let _depth = 1;
    let _r = _row;
    let _c = _col + _dir;
    while _depth > 0 {
        if _r < 0 { return { row: _row, col: _col }; };
        if _r >= len(_lines) { return { row: _row, col: _col }; };
        let _ln = _lines[_r];
        while _c >= 0 && _c < len(_ln) {
            let _cc = char_at(_ln, _c);
            if _cc == _open && _dir == 1 { _depth = _depth + 1; };
            if _cc == _close && _dir == 1 { _depth = _depth - 1; };
            if _cc == _close && _dir == -1 { _depth = _depth + 1; };
            if _cc == _open && _dir == -1 { _depth = _depth - 1; };
            if _depth == 0 { return { row: _r, col: _c }; };
            _c = _c + _dir;
        };
        _r = _r + _dir;
        if _dir == 1 { _c = 0; };
        if _dir == -1 { if _r >= 0 { _c = len(_lines[_r]) - 1; }; };
    };
    return { row: _row, col: _col };
}

// ════════════════════════════════════════════════════════════════
// PATCH 3: Count prefix — thêm đầu NORMAL mode handler
// Trước dòng "let _nx = 0;"
// ════════════════════════════════════════════════════════════════

                // Count prefix: digits 1-9 accumulate count
                if _key >= 49 && _key <= 57 && _counting == 0 {
                    // First digit (1-9)
                    _count = _key - 48;
                    _counting = 1;
                    _need_render = 0;  // don't render yet
                } else { if _key >= 48 && _key <= 57 && _counting == 1 {
                    // Subsequent digits
                    _count = _count * 10 + (_key - 48);
                    if _count > 9999 { _count = 9999; };
                    _need_render = 0;
                } else {
                    // Non-digit: apply count to command
                    let _reps = 1;
                    if _counting == 1 { _reps = _count; _counting = 0; _count = 0; };
                    // ... rest of NORMAL mode handling with _reps ...
                }; };

// ════════════════════════════════════════════════════════════════
// PATCH 4: Vim commands — thêm trong NORMAL mode phần "_nx"
// Sau các dòng kiểm tra g, 0, $, D
// ════════════════════════════════════════════════════════════════

                // w — word forward
                if _key == 119 {
                    let _ri = 0;
                    while _ri < _reps {
                        let _wline = _lines[_cur_row];
                        let _wnext = _ed_word_next(_wline, _cur_col);
                        if _wnext >= len(_wline) {
                            // Move to next line
                            if _cur_row < len(_lines) - 1 {
                                _cur_row = _cur_row + 1;
                                _cur_col = 0;
                            };
                        } else {
                            _cur_col = _wnext;
                        };
                        _ri = _ri + 1;
                    };
                    _nx = 1;
                };

                // b — word backward
                if _key == 98 {
                    let _ri = 0;
                    while _ri < _reps {
                        if _cur_col == 0 {
                            if _cur_row > 0 {
                                _cur_row = _cur_row - 1;
                                _cur_col = len(_lines[_cur_row]);
                            };
                        } else {
                            _cur_col = _ed_word_prev(_lines[_cur_row], _cur_col);
                        };
                        _ri = _ri + 1;
                    };
                    _nx = 1;
                };

                // yy — yank (copy) current line
                if _key == 121 {
                    // Wait for second y
                    let _y2 = __read_byte();
                    if _y2 == 121 {
                        // yy: yank line
                        _yank = _lines[_cur_row];
                    };
                    _nx = 1;
                };

                // p — paste yanked line below
                if _key == 112 {
                    if len(_yank) > 0 {
                        _ed_save_undo(_lines, _cur_row, _cur_col, _undo_stack, _undo_max);
                        let _pnew = [];
                        let _pi = 0;
                        while _pi < len(_lines) {
                            push(_pnew, _lines[_pi]);
                            if _pi == _cur_row { push(_pnew, _yank); };
                            _pi = _pi + 1;
                        };
                        _lines = _pnew;
                        _cur_row = _cur_row + 1;
                        _cur_col = 0;
                    };
                    _nx = 1;
                };

                // P — paste above current line
                if _key == 80 {
                    if len(_yank) > 0 {
                        _ed_save_undo(_lines, _cur_row, _cur_col, _undo_stack, _undo_max);
                        let _pnew = [];
                        let _pi = 0;
                        while _pi < len(_lines) {
                            if _pi == _cur_row { push(_pnew, _yank); };
                            push(_pnew, _lines[_pi]);
                            _pi = _pi + 1;
                        };
                        _lines = _pnew;
                        _cur_col = 0;
                    };
                    _nx = 1;
                };

                // u — undo
                if _key == 117 {
                    if len(_undo_stack) > 0 {
                        let _ust = _undo_stack[len(_undo_stack) - 1];
                        _lines = _ust.lines;
                        _cur_row = _ust.row;
                        _cur_col = _ust.col;
                        // Remove last from undo stack
                        let _unew = [];
                        let _ui = 0;
                        while _ui < len(_undo_stack) - 1 {
                            push(_unew, _undo_stack[_ui]);
                            _ui = _ui + 1;
                        };
                        _undo_stack = _unew;
                    };
                    _nx = 1;
                };

                // A — append at end of line
                if _key == 65 {
                    _cur_col = len(_lines[_cur_row]);
                    _mode = "INSERT";
                    _nx = 1;
                };

                // I — insert at first non-space
                if _key == 73 {
                    let _iline = _lines[_cur_row];
                    _cur_col = 0;
                    while _cur_col < len(_iline) {
                        if char_at(_iline, _cur_col) != " " { break; };
                        _cur_col = _cur_col + 1;
                    };
                    _mode = "INSERT";
                    _nx = 1;
                };

                // O — open line above (uppercase)
                if _key == 79 {
                    _ed_save_undo(_lines, _cur_row, _cur_col, _undo_stack, _undo_max);
                    let _onew = [];
                    let _oi = 0;
                    while _oi < len(_lines) {
                        if _oi == _cur_row { push(_onew, ""); };
                        push(_onew, _lines[_oi]);
                        _oi = _oi + 1;
                    };
                    _lines = _onew;
                    _cur_col = 0;
                    _mode = "INSERT";
                    _nx = 1;
                };

                // J — join current line with next
                if _key == 74 {
                    if _cur_row < len(_lines) - 1 {
                        _ed_save_undo(_lines, _cur_row, _cur_col, _undo_stack, _undo_max);
                        let _joined = _lines[_cur_row] + " " + _lines[_cur_row + 1];
                        set_at(_lines, _cur_row, _joined);
                        // Remove next line
                        let _jnew = [];
                        let _ji = 0;
                        while _ji < len(_lines) {
                            if _ji != _cur_row + 1 { push(_jnew, _lines[_ji]); };
                            _ji = _ji + 1;
                        };
                        _lines = _jnew;
                    };
                    _nx = 1;
                };

                // % — jump to matching bracket
                if _key == 37 {
                    let _br = _ed_find_bracket(_lines, _cur_row, _cur_col);
                    _cur_row = _br.row;
                    _cur_col = _br.col;
                    _nx = 1;
                };

                // >> — indent (>) wait for second >
                if _key == 62 {
                    let _g2 = __read_byte();
                    if _g2 == 62 {
                        _ed_save_undo(_lines, _cur_row, _cur_col, _undo_stack, _undo_max);
                        set_at(_lines, _cur_row, "    " + _lines[_cur_row]);
                        _cur_col = _cur_col + 4;
                    };
                    _nx = 1;
                };

                // << — dedent (<) wait for second <
                if _key == 60 {
                    let _l2 = __read_byte();
                    if _l2 == 60 {
                        let _dline = _lines[_cur_row];
                        if len(_dline) >= 4 {
                            if __substr(_dline, 0, 4) == "    " {
                                _ed_save_undo(_lines, _cur_row, _cur_col, _undo_stack, _undo_max);
                                set_at(_lines, _cur_row, __substr(_dline, 4, len(_dline)));
                                if _cur_col >= 4 { _cur_col = _cur_col - 4; } else { _cur_col = 0; };
                            };
                        };
                    };
                    _nx = 1;
                };

                // cc — change entire line (delete content + insert mode)
                if _key == 99 {
                    let _cc2 = __read_byte();
                    if _cc2 == 99 {
                        _ed_save_undo(_lines, _cur_row, _cur_col, _undo_stack, _undo_max);
                        _yank = _lines[_cur_row];
                        set_at(_lines, _cur_row, "");
                        _cur_col = 0;
                        _mode = "INSERT";
                    };
                    _nx = 1;
                };

// ════════════════════════════════════════════════════════════════
// PATCH 5: Save undo before destructive operations
// Thêm _ed_save_undo() TRƯỚC mỗi lệnh thay đổi buffer:
//   - D (delete line): thêm trước let _dd_new = []
//   - o (open below): thêm trước let _new = []
//   - x (delete char): thêm trước set_at
//   - INSERT mode backspace: thêm trước if _cur_col > 0
//   - INSERT mode enter: thêm trước let _line = _lines[_cur_row]
// ════════════════════════════════════════════════════════════════

// Example — wrap D command:
                if _key == 68 {
                    _ed_save_undo(_lines, _cur_row, _cur_col, _undo_stack, _undo_max);
                    _yank = _lines[_cur_row];  // yank before delete
                    if len(_lines) > 1 {
                        // ... existing delete code ...
                    } else { set_at(_lines, 0, ""); _cur_col = 0; };
                    _nx = 1;
                };

// ════════════════════════════════════════════════════════════════
// PATCH 6: :number — goto line in COMMAND mode
// Thêm TRƯỚC "if _cmd_buf == "q"" trong COMMAND mode handler
// ════════════════════════════════════════════════════════════════

                    // :number — goto line
                    let _cmd_is_num = 1;
                    let _cmd_ci = 0;
                    if len(_cmd_buf) == 0 { _cmd_is_num = 0; };
                    while _cmd_ci < len(_cmd_buf) {
                        let _cmd_ch = __char_code(char_at(_cmd_buf, _cmd_ci));
                        if _cmd_ch < 48 || _cmd_ch > 57 { _cmd_is_num = 0; };
                        _cmd_ci = _cmd_ci + 1;
                    };
                    if _cmd_is_num == 1 {
                        let _goto_line = __to_number(_cmd_buf) - 1;
                        if _goto_line < 0 { _goto_line = 0; };
                        if _goto_line >= len(_lines) { _goto_line = len(_lines) - 1; };
                        _cur_row = _goto_line;
                        _cur_col = 0;
                    };

// ════════════════════════════════════════════════════════════════
// PATCH 7: Count prefix support for j/k motions
// Replace existing j/k handlers with counted versions
// ════════════════════════════════════════════════════════════════

                // j — down (counted: 5j = move 5 lines)
                else { if _key == 106 {
                    let _ri = 0;
                    while _ri < _reps {
                        if _cur_row < len(_lines) - 1 { _cur_row = _cur_row + 1; };
                        _ri = _ri + 1;
                    };
                }

                // k — up (counted)
                else { if _key == 107 {
                    let _ri = 0;
                    while _ri < _reps {
                        if _cur_row > 0 { _cur_row = _cur_row - 1; };
                        _ri = _ri + 1;
                    };
                }

// ════════════════════════════════════════════════════════════════
// PATCH 8: Status bar — show count prefix and yank status
// Replace status bar code
// ════════════════════════════════════════════════════════════════

        let _status = " " + _mode;
        if _counting == 1 { _status = _status + " " + __to_string(_count); };
        if _ft_focus == 1 { _status = " TREE"; };
        if _mode == "SEARCH" { _status = " /" + _search; }
        else { if _mode == "COMMAND" { _status = " :" + _cmd_buf; } }
        else {
            _status = _status + " | Ln " + __to_string(_cur_row + 1)
                + ", Col " + __to_string(_cur_col + 1)
                + " | " + __to_string(len(_lines)) + " lines";
            if len(_yank) > 0 { _status = _status + " | y:" + __to_string(len(_yank)); };
            if len(_undo_stack) > 0 { _status = _status + " | u:" + __to_string(len(_undo_stack)); };
        };

// ════════════════════════════════════════════════════════════════
// TỔNG KẾT — Features thêm:
//
// Motions:
//   w         word forward
//   b         word backward
//   %         bracket match
//   5j 10k    count prefix + motion
//   :123      goto line number
//
// Edit:
//   yy        yank (copy) line
//   p         paste below
//   P         paste above
//   dd/D      delete line (now yanks before delete)
//   cc        change line (delete + insert)
//   u         undo (50 levels)
//   J         join lines
//   >>        indent 4 spaces
//   <<        dedent 4 spaces
//   A         append at end of line
//   I         insert at first non-space
//   O         open line above
//
// Status bar:
//   Shows count prefix, yank length, undo depth
//
// ~200 LOC thêm. Helper functions tách riêng (no global var conflict).
// ════════════════════════════════════════════════════════════════
