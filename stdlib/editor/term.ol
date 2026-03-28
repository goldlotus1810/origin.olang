// editor/term.ol — Terminal ANSI control

pub fn term_cols() {
    let _ts = __term_size();
    return __floor(_ts / 10000);
}

pub fn term_rows() {
    let _ts = __term_size();
    return _ts % 10000;
}

pub fn term_clear() { __write_raw(__esc() + "[2J" + __esc() + "[H"); }
pub fn term_goto(_r, _c) { __write_raw(__esc() + "[" + __to_string(_r) + ";" + __to_string(_c) + "H"); }
pub fn term_hide_cursor() { __write_raw(__esc() + "[?25l"); }
pub fn term_show_cursor() { __write_raw(__esc() + "[?25h"); }
pub fn term_color(_fg) { __write_raw(__esc() + "[38;5;" + __to_string(_fg) + "m"); }
pub fn term_bg(_bg) { __write_raw(__esc() + "[48;5;" + __to_string(_bg) + "m"); }
pub fn term_reset() { __write_raw(__esc() + "[0m"); }
pub fn term_bold() { __write_raw(__esc() + "[1m"); }
pub fn term_write(_t) { __write_raw(_t); }

pub fn term_fill_line(_t, _w) {
    __write_raw(_t);
    let _i = len(_t);
    while _i < _w { __write_raw(" "); _i = _i + 1; };
}
