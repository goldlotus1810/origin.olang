// editor/term.ol — Terminal ANSI control + key decode

let ESC = __chr(27);

pub fn term_cols() {
    let _ts = __term_size();
    return __floor(_ts / 10000);
}

pub fn term_rows() {
    let _ts = __term_size();
    return _ts % 10000;
}

pub fn term_clear() {
    __write_raw(ESC + "[2J" + ESC + "[H");
}

pub fn term_goto(_row, _col) {
    __write_raw(ESC + "[" + __to_string(_row) + ";" + __to_string(_col) + "H");
}

pub fn term_hide_cursor() {
    __write_raw(ESC + "[?25l");
}

pub fn term_show_cursor() {
    __write_raw(ESC + "[?25h");
}

pub fn term_color(_fg) {
    __write_raw(ESC + "[38;5;" + __to_string(_fg) + "m");
}

pub fn term_bg(_bg) {
    __write_raw(ESC + "[48;5;" + __to_string(_bg) + "m");
}

pub fn term_reset() {
    __write_raw(ESC + "[0m");
}

pub fn term_bold() {
    __write_raw(ESC + "[1m");
}

pub fn term_write(_text) {
    __write_raw(_text);
}

pub fn term_fill_line(_text, _width) {
    let _len = len(_text);
    __write_raw(_text);
    let _i = _len;
    while _i < _width {
        __write_raw(" ");
        _i = _i + 1;
    };
}
