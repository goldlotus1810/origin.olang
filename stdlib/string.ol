// stdlib/string.ol — String utility functions

pub fn str_replace(_sr_s, _sr_from, _sr_to) {
    let _sr_out = "";
    let _sr_i = 0;
    let _sr_slen = len(_sr_s);
    let _sr_flen = len(_sr_from);
    while _sr_i < _sr_slen {
        if _sr_i + _sr_flen <= _sr_slen {
            if substr(_sr_s, _sr_i, _sr_i + _sr_flen) == _sr_from {
                _sr_out = _sr_out + _sr_to;
                _sr_i = _sr_i + _sr_flen;
            } else {
                _sr_out = _sr_out + char_at(_sr_s, _sr_i);
                _sr_i = _sr_i + 1;
            };
        } else {
            _sr_out = _sr_out + char_at(_sr_s, _sr_i);
            _sr_i = _sr_i + 1;
        };
    };
    return _sr_out;
}

pub fn str_reverse(_srev_s) {
    let _srev_out = "";
    let _srev_i = len(_srev_s) - 1;
    while _srev_i >= 0 {
        _srev_out = _srev_out + char_at(_srev_s, _srev_i);
        _srev_i = _srev_i - 1;
    };
    return _srev_out;
}

pub fn str_repeat(_srep_s, _srep_n) {
    let _srep_out = "";
    let _srep_i = 0;
    while _srep_i < _srep_n {
        _srep_out = _srep_out + _srep_s;
        _srep_i = _srep_i + 1;
    };
    return _srep_out;
}

pub fn str_upper(_su_s) {
    let _su_out = "";
    let _su_i = 0;
    while _su_i < len(_su_s) {
        let _su_c = __char_code(char_at(_su_s, _su_i));
        if _su_c >= 97 { if _su_c <= 122 { _su_c = _su_c - 32; }; };
        _su_out = _su_out + __chr(_su_c);
        _su_i = _su_i + 1;
    };
    return _su_out;
}

pub fn str_lower(_sl_s) {
    let _sl_out = "";
    let _sl_i = 0;
    while _sl_i < len(_sl_s) {
        let _sl_c = __char_code(char_at(_sl_s, _sl_i));
        if _sl_c >= 65 { if _sl_c <= 90 { _sl_c = _sl_c + 32; }; };
        _sl_out = _sl_out + __chr(_sl_c);
        _sl_i = _sl_i + 1;
    };
    return _sl_out;
}

pub fn str_starts_with(_ssw_s, _ssw_prefix) {
    if len(_ssw_s) < len(_ssw_prefix) { return 0; };
    return substr(_ssw_s, 0, len(_ssw_prefix)) == _ssw_prefix;
}

pub fn str_ends_with(_sew_s, _sew_suffix) {
    if len(_sew_s) < len(_sew_suffix) { return 0; };
    return substr(_sew_s, len(_sew_s) - len(_sew_suffix), len(_sew_s)) == _sew_suffix;
}

pub fn str_pad_left(_spl_s, _spl_n, _spl_ch) {
    let _spl_out = _spl_s;
    while len(_spl_out) < _spl_n {
        _spl_out = _spl_ch + _spl_out;
    };
    return _spl_out;
}
