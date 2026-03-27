// stdlib/json_emit.ol — JSON serializer
// json_emit(value) → JSON string

pub fn json_emit(_je_val) {
    let _je_t = type_of(_je_val);
    if _je_t == "number" {
        return to_string(_je_val);
    };
    if _je_t == "string" {
        return "\"" + _je_escape(_je_val) + "\"";
    };
    if _je_t == "array" {
        return _je_array(_je_val);
    };
    return "null";
}

fn _je_escape(_jes_s) {
    let _jes_out = "";
    let _jes_i = 0;
    let _jes_len = len(_jes_s);
    while _jes_i < _jes_len {
        let _jes_c = char_at(_jes_s, _jes_i);
        if _jes_c == "\"" { _jes_out = _jes_out + "\\\""; }
        else { if _jes_c == "\\" { _jes_out = _jes_out + "\\\\"; }
        else { if _jes_c == "\n" { _jes_out = _jes_out + "\\n"; }
        else { _jes_out = _jes_out + _jes_c; }; }; };
        _jes_i = _jes_i + 1;
    };
    return _jes_out;
}

fn _je_array(_jea_arr) {
    let _jea_out = "[";
    let _jea_i = 0;
    let _jea_len = len(_jea_arr);
    while _jea_i < _jea_len {
        if _jea_i > 0 { _jea_out = _jea_out + ","; };
        _jea_out = _jea_out + json_emit(_jea_arr[_jea_i]);
        _jea_i = _jea_i + 1;
    };
    return _jea_out + "]";
}
