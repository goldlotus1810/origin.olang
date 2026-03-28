// stdlib/json_parse.ol — JSON parser + accessor for Olang
// Parses JSON string → Olang value (string, number, array, dict)
// Objects → flat array [key, val, key, val, ...]
// Usage: let obj = json_parse(text); let val = json_get(obj, "key");

pub fn json_parse(_jp_text) {
    let _jp_st = [0];
    return _jp_parse_value(_jp_text, _jp_st);
}

fn _jp_skip_ws(_jw_t, _jw_pos) {
    let _jw_len = len(_jw_t);
    let _jw_i = _jw_pos[0];
    while _jw_i < _jw_len {
        let _jw_c = __char_code(char_at(_jw_t, _jw_i));
        let _jw_is_ws = 0;
        if _jw_c == 32 { let _jw_is_ws = 1; };
        if _jw_c == 9 { let _jw_is_ws = 1; };
        if _jw_c == 10 { let _jw_is_ws = 1; };
        if _jw_c == 13 { let _jw_is_ws = 1; };
        if _jw_is_ws == 0 { _jw_i = _jw_i + _jw_len; };
        let _jw_i = _jw_i + 1;
    };
    let _jw_i = _jw_i - _jw_len - 1;
    set_at(_jw_pos, 0, _jw_i);
}

fn _jp_parse_value(_jv_t, _jv_pos) {
    _jp_skip_ws(_jv_t, _jv_pos);
    let _jv_i = _jv_pos[0];
    if _jv_i >= len(_jv_t) { return ""; };
    let _jv_c = __char_code(char_at(_jv_t, _jv_i));
    if _jv_c == 34 { return _jp_parse_string(_jv_t, _jv_pos); };
    if _jv_c == 91 { return _jp_parse_array(_jv_t, _jv_pos); };
    if _jv_c == 123 { return _jp_parse_object(_jv_t, _jv_pos); };
    if _jv_c == 116 { set_at(_jv_pos, 0, _jv_i + 4); return 1; };
    if _jv_c == 102 { set_at(_jv_pos, 0, _jv_i + 5); return 0; };
    if _jv_c == 110 { set_at(_jv_pos, 0, _jv_i + 4); return 0; };
    return _jp_parse_number(_jv_t, _jv_pos);
}

fn _jp_parse_string(_js_t, _js_pos) {
    let _js_i = _js_pos[0] + 1;
    let _js_start = _js_i;
    let _js_len = len(_js_t);
    while _js_i < _js_len {
        let _js_c = __char_code(char_at(_js_t, _js_i));
        if _js_c == 34 { set_at(_js_pos, 0, _js_i + 1); return __substr(_js_t, _js_start, _js_i); };
        if _js_c == 92 { let _js_i = _js_i + 1; };
        let _js_i = _js_i + 1;
    };
    set_at(_js_pos, 0, _js_i);
    return __substr(_js_t, _js_start, _js_i);
}

fn _jp_parse_number(_jn_t, _jn_pos) {
    let _jn_i = _jn_pos[0];
    let _jn_start = _jn_i;
    let _jn_len = len(_jn_t);
    while _jn_i < _jn_len {
        let _jn_c = __char_code(char_at(_jn_t, _jn_i));
        let _jn_ok = 0;
        if _jn_c >= 48 { if _jn_c <= 57 { let _jn_ok = 1; }; };
        if _jn_c == 45 { let _jn_ok = 1; };
        if _jn_c == 46 { let _jn_ok = 1; };
        if _jn_c == 101 { let _jn_ok = 1; };
        if _jn_c == 69 { let _jn_ok = 1; };
        if _jn_c == 43 { let _jn_ok = 1; };
        if _jn_ok == 0 { _jn_i = _jn_i + _jn_len; };
        let _jn_i = _jn_i + 1;
    };
    let _jn_i = _jn_i - _jn_len - 1;
    set_at(_jn_pos, 0, _jn_i);
    let _jn_str = __substr(_jn_t, _jn_start, _jn_i);
    return __to_number(_jn_str);
}

fn _jp_parse_array(_ja_t, _ja_pos) {
    set_at(_ja_pos, 0, _ja_pos[0] + 1);
    let _ja_result = [];
    _jp_skip_ws(_ja_t, _ja_pos);
    if __char_code(char_at(_ja_t, _ja_pos[0])) == 93 { set_at(_ja_pos, 0, _ja_pos[0] + 1); return _ja_result; };
    let _ja_val = _jp_parse_value(_ja_t, _ja_pos);
    push(_ja_result, _ja_val);
    _jp_skip_ws(_ja_t, _ja_pos);
    while __char_code(char_at(_ja_t, _ja_pos[0])) == 44 {
        set_at(_ja_pos, 0, _ja_pos[0] + 1);
        let _ja_val = _jp_parse_value(_ja_t, _ja_pos);
        push(_ja_result, _ja_val);
        _jp_skip_ws(_ja_t, _ja_pos);
    };
    set_at(_ja_pos, 0, _ja_pos[0] + 1);
    return _ja_result;
}

let __jp_stk = [];

fn _jp_parse_object(_jo_t, _jo_pos) {
    set_at(_jo_pos, 0, _jo_pos[0] + 1);
    _jp_skip_ws(_jo_t, _jo_pos);
    let _jo_result = [];
    if __char_code(char_at(_jo_t, _jo_pos[0])) == 125 { set_at(_jo_pos, 0, _jo_pos[0] + 1); return _jo_result; };
    // Save result before recursive parse_value (may call parse_object again)
    push(__jp_stk, _jo_result);
    let _jo_key = _jp_parse_string(_jo_t, _jo_pos);
    _jp_skip_ws(_jo_t, _jo_pos);
    set_at(_jo_pos, 0, _jo_pos[0] + 1);
    push(__jp_stk, _jo_key);
    let _jo_val = _jp_parse_value(_jo_t, _jo_pos);
    _jo_key = pop(__jp_stk);
    _jo_result = pop(__jp_stk);
    push(_jo_result, _jo_key);
    push(_jo_result, _jo_val);
    _jp_skip_ws(_jo_t, _jo_pos);
    while __char_code(char_at(_jo_t, _jo_pos[0])) == 44 {
        set_at(_jo_pos, 0, _jo_pos[0] + 1);
        push(__jp_stk, _jo_result);
        let _jo_key = _jp_parse_string(_jo_t, _jo_pos);
        _jp_skip_ws(_jo_t, _jo_pos);
        set_at(_jo_pos, 0, _jo_pos[0] + 1);
        push(__jp_stk, _jo_key);
        let _jo_val = _jp_parse_value(_jo_t, _jo_pos);
        _jo_key = pop(__jp_stk);
        _jo_result = pop(__jp_stk);
        push(_jo_result, _jo_key);
        push(_jo_result, _jo_val);
        _jp_skip_ws(_jo_t, _jo_pos);
    };
    set_at(_jo_pos, 0, _jo_pos[0] + 1);
    return _jo_result;
}

pub fn json_get(_jg_obj, _jg_key) {
    let _jg_i = 0;
    while _jg_i < len(_jg_obj) {
        if _jg_obj[_jg_i] == _jg_key { return _jg_obj[_jg_i + 1]; };
        let _jg_i = _jg_i + 2;
    };
    return "";
}
