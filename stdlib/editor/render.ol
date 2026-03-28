// editor/render.ol — Syntax highlighting for Olang

fn _hl_is_alpha(_c) {
    let _r = __str_find("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_", _c);
    return len(_r) > 0;
}

fn _hl_is_alnum(_c) {
    let _r = __str_find("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789", _c);
    return len(_r) > 0;
}

fn _hl_is_digit(_c) {
    let _r = __str_find("0123456789", _c);
    return len(_r) > 0;
}

fn _hl_is_keyword(_w) {
    if _w == "fn" { return 1; };
    if _w == "let" { return 1; };
    if _w == "const" { return 1; };
    if _w == "pub" { return 1; };
    if _w == "if" { return 1; };
    if _w == "else" { return 1; };
    if _w == "while" { return 1; };
    if _w == "for" { return 1; };
    if _w == "return" { return 1; };
    if _w == "match" { return 1; };
    if _w == "import" { return 1; };
    if _w == "emit" { return 1; };
    if _w == "true" { return 1; };
    if _w == "false" { return 1; };
    return 0;
}

// Colors: 204=keyword(pink), 114=string(green), 242=comment(gray)
//         215=number(orange), 75=function(blue), 252=default(white)

pub fn render_line_hl(_text, _w) {
    let _tlen = len(_text);
    let _i = 0;
    let _col = 0;
    let _last_color = 0;

    while _i < _tlen {
        if _col >= _w { _i = _tlen; } else {
            let _ch = __substr(_text, _i, _i + 1);

            // Comment: //
            if _ch == "/" {
                let _is_comment = 0;
                if _i + 1 < _tlen {
                    if __substr(_text, _i + 1, _i + 2) == "/" { _is_comment = 1; };
                };
                if _is_comment == 1 {
                    if _last_color != 242 { term_color(242); _last_color = 242; };
                    let _rem = _tlen - _i;
                    if _rem > _w - _col { _rem = _w - _col; };
                    __write_raw(__substr(_text, _i, _i + _rem));
                    _col = _col + _rem;
                    _i = _tlen;
                } else {
                    if _last_color != 252 { term_color(252); _last_color = 252; };
                    __write_raw(_ch);
                    _col = _col + 1;
                    _i = _i + 1;
                };
            } else { if _ch == "\"" {
                // String literal
                if _last_color != 114 { term_color(114); _last_color = 114; };
                __write_raw(_ch);
                _col = _col + 1;
                _i = _i + 1;
                let _in_str = 1;
                while _in_str == 1 {
                    if _i >= _tlen { _in_str = 0; }
                    else { if _col >= _w { _in_str = 0; }
                    else {
                        let _sc = __substr(_text, _i, _i + 1);
                        __write_raw(_sc);
                        _col = _col + 1;
                        _i = _i + 1;
                        if _sc == "\\" {
                            // Escape: output next char too
                            if _i < _tlen {
                                if _col < _w {
                                    __write_raw(__substr(_text, _i, _i + 1));
                                    _col = _col + 1;
                                    _i = _i + 1;
                                };
                            };
                        } else { if _sc == "\"" { _in_str = 0; }; };
                    }; };
                };
                if _last_color != 252 { term_color(252); _last_color = 252; };
            } else { if _hl_is_alpha(_ch) == 1 {
                // Word (keyword, function, identifier)
                let _word_start = _i;
                _i = _i + 1;
                let _word_done = 0;
                while _word_done == 0 {
                    if _i >= _tlen { _word_done = 1; }
                    else {
                        if _hl_is_alnum(__substr(_text, _i, _i + 1)) == 1 {
                            _i = _i + 1;
                        } else { _word_done = 1; };
                    };
                };
                let _word = __substr(_text, _word_start, _i);
                // Check what follows: ( means function call
                let _next_is_paren = 0;
                if _i < _tlen {
                    if __substr(_text, _i, _i + 1) == "(" { _next_is_paren = 1; };
                };
                if _hl_is_keyword(_word) == 1 {
                    if _last_color != 204 { term_color(204); _last_color = 204; };
                } else { if _next_is_paren == 1 {
                    if _last_color != 75 { term_color(75); _last_color = 75; };
                } else {
                    if _last_color != 252 { term_color(252); _last_color = 252; };
                }; };
                let _wlen = len(_word);
                if _wlen > _w - _col { _wlen = _w - _col; };
                __write_raw(__substr(_word, 0, _wlen));
                _col = _col + _wlen;
                if _last_color != 252 { term_color(252); _last_color = 252; };
            } else { if _hl_is_digit(_ch) == 1 {
                // Number
                if _last_color != 215 { term_color(215); _last_color = 215; };
                __write_raw(_ch);
                _col = _col + 1;
                _i = _i + 1;
                let _in_num = 1;
                while _in_num == 1 {
                    if _i >= _tlen { _in_num = 0; }
                    else { if _col >= _w { _in_num = 0; }
                    else {
                        let _nc = __substr(_text, _i, _i + 1);
                        if _hl_is_digit(_nc) == 1 {
                            __write_raw(_nc);
                            _col = _col + 1;
                            _i = _i + 1;
                        } else { if _nc == "." {
                            __write_raw(_nc);
                            _col = _col + 1;
                            _i = _i + 1;
                        } else { _in_num = 0; }; };
                    }; };
                };
                if _last_color != 252 { term_color(252); _last_color = 252; };
            } else {
                // Operators, punctuation, spaces
                if _last_color != 252 { term_color(252); _last_color = 252; };
                __write_raw(_ch);
                _col = _col + 1;
                _i = _i + 1;
            }; }; }; };
        };
    };

    // Fill remaining with spaces
    while _col < _w { __write_raw(" "); _col = _col + 1; };
}
