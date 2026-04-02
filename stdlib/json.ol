// ═══════════════════════════════════════════════════════════════
// Olang JSON Parser + Serializer
// parse: string → dict/array/number/string
// stringify: dict/array/number/string → string
// ═══════════════════════════════════════════════════════════════

let _json_src = "";
let _json_len = 0;
let _json_pos = 0;

fn _json_skip_ws() {
    while _json_pos < _json_len {
        let c = __char_code(char_at(_json_src, _json_pos));
        if c != 32 && c != 9 && c != 10 && c != 13 { return 0; };
        _json_pos = _json_pos + 1;
    };
    return 0;
};

fn _json_peek() {
    _json_skip_ws();
    if _json_pos >= _json_len { return 0; };
    return __char_code(char_at(_json_src, _json_pos));
};

fn _json_parse_string() {
    // Skip opening "
    _json_pos = _json_pos + 1;
    let start = _json_pos;
    let result = "";
    while _json_pos < _json_len {
        let c = __char_code(char_at(_json_src, _json_pos));
        if c == 34 {
            // Closing quote
            _json_pos = _json_pos + 1;
            return result + substr(_json_src, start, _json_pos - 1);
        };
        if c == 92 {
            // Backslash escape
            result = result + substr(_json_src, start, _json_pos);
            _json_pos = _json_pos + 1;
            let esc = __char_code(char_at(_json_src, _json_pos));
            if esc == 110 { result = result + "\n"; }
            else { if esc == 116 { result = result + "\t"; }
            else { if esc == 114 { result = result + "\r"; }
            else { if esc == 34 { result = result + substr(_json_src, _json_pos, _json_pos + 1); }
            else { if esc == 92 { result = result + substr(_json_src, _json_pos, _json_pos + 1); }
            else { result = result + substr(_json_src, _json_pos, _json_pos + 1); }; }; }; }; };
            _json_pos = _json_pos + 1;
            start = _json_pos;
        } else {
            _json_pos = _json_pos + 1;
        };
    };
    return result;
};

fn _json_parse_number() {
    let start = _json_pos;
    let c = __char_code(char_at(_json_src, _json_pos));
    if c == 45 { _json_pos = _json_pos + 1; };
    while _json_pos < _json_len {
        c = __char_code(char_at(_json_src, _json_pos));
        if (c >= 48 && c <= 57) || c == 46 || c == 101 || c == 69 || c == 43 || c == 45 {
            _json_pos = _json_pos + 1;
        } else {
            break;
        };
    };
    return __str_to_num(substr(_json_src, start, _json_pos));
};

fn json_parse_value() {
    let c = _json_peek();
    if c == 34 { return _json_parse_string(); };
    if c == 123 { return _json_parse_object(); };
    if c == 91 { return _json_parse_array(); };
    if c == 116 {
        // true
        _json_pos = _json_pos + 4;
        return 1;
    };
    if c == 102 {
        // false
        _json_pos = _json_pos + 5;
        return 0;
    };
    if c == 110 {
        // null
        _json_pos = _json_pos + 4;
        return 0;
    };
    // number
    return _json_parse_number();
};

fn _json_parse_object() {
    _json_pos = _json_pos + 1;
    let obj = __dict_new();
    _json_skip_ws();
    if __char_code(char_at(_json_src, _json_pos)) == 125 {
        _json_pos = _json_pos + 1;
        return obj;
    };
    while _json_pos < _json_len {
        _json_skip_ws();
        let key = _json_parse_string();
        _json_skip_ws();
        _json_pos = _json_pos + 1;
        let val = json_parse_value();
        __dict_set(obj, key, val);
        _json_skip_ws();
        let c = __char_code(char_at(_json_src, _json_pos));
        if c == 125 { _json_pos = _json_pos + 1; return obj; };
        _json_pos = _json_pos + 1;
    };
    return obj;
};

fn _json_parse_array() {
    _json_pos = _json_pos + 1;
    let arr = [];
    _json_skip_ws();
    if __char_code(char_at(_json_src, _json_pos)) == 93 {
        _json_pos = _json_pos + 1;
        return arr;
    };
    while _json_pos < _json_len {
        push(arr, json_parse_value());
        _json_skip_ws();
        let c = __char_code(char_at(_json_src, _json_pos));
        if c == 93 { _json_pos = _json_pos + 1; return arr; };
        _json_pos = _json_pos + 1;
    };
    return arr;
};

fn json_parse(s) {
    _json_src = s;
    _json_len = len(s);
    _json_pos = 0;
    return json_parse_value();
};

// ═══ Serializer ═══

fn _json_escape_string(s) {
    let result = "";
    let i = 0;
    let slen = len(s);
    let start = 0;
    while i < slen {
        let c = __char_code(char_at(s, i));
        if c == 34 || c == 92 || c == 10 || c == 13 || c == 9 {
            result = result + substr(s, start, i);
            if c == 34 { result = result + "\\\""; }
            else { if c == 92 { result = result + "\\\\"; }
            else { if c == 10 { result = result + "\\n"; }
            else { if c == 13 { result = result + "\\r"; }
            else { result = result + "\\t"; }; }; }; };
            start = i + 1;
        };
        i = i + 1;
    };
    return result + substr(s, start, slen);
};

fn json_stringify(val) {
    let t = type_of(val);
    if t == "number" {
        return __to_string(val);
    };
    if t == "string" {
        return "\"" + _json_escape_string(val) + "\"";
    };
    if t == "array" {
        let parts = "";
        let i = 0;
        while i < len(val) {
            if i > 0 { parts = parts + ","; };
            parts = parts + json_stringify(__array_get(val, i));
            i = i + 1;
        };
        return "[" + parts + "]";
    };
    if t == "dict" {
        let keys = __dict_keys(val);
        let parts = "";
        let i = 0;
        while i < len(keys) {
            let k = __array_get(keys, i);
            if i > 0 { parts = parts + ","; };
            parts = parts + "\"" + _json_escape_string(k) + "\":" + json_stringify(__dict_get(val, k));
            i = i + 1;
        };
        return "{" + parts + "}";
    };
    return "null";
};
