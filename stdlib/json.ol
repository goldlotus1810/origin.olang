// ═══ JSON Parser + Serializer ═══
// parse_json(str) → dict/array/number/string
// json_stringify(value) → str

// ── Helpers ──
fn _json_is_ws(c) { return c == 32 || c == 10 || c == 13 || c == 9; };

fn _json_skip_ws(s, i) {
    while i < len(s) {
        if !_json_is_ws(__char_code(char_at(s, i))) { return i; };
        let i = i + 1;
    };
    return i;
};

// ── Parse String ──
fn _json_parse_string(s, i) {
    // i points to opening "
    let i = i + 1;
    let start = i;
    while i < len(s) {
        let c = __char_code(char_at(s, i));
        if c == 34 { // closing "
            let val = substr(s, start, i);
            return [val, i + 1];
        };
        if c == 92 { let i = i + 1; }; // skip escaped char
        let i = i + 1;
    };
    return ["", i];
};

// ── Parse Number ──
fn _json_parse_number(s, i) {
    let start = i;
    let c = __char_code(char_at(s, i));
    if c == 45 { let i = i + 1; }; // minus
    while i < len(s) {
        let c = __char_code(char_at(s, i));
        if c >= 48 { if c <= 57 { let i = i + 1; continue; }; };
        if c == 46 { let i = i + 1; continue; }; // decimal
        if c == 101 || c == 69 { let i = i + 1; continue; }; // e/E
        if c == 43 || c == 45 { let i = i + 1; continue; }; // +/- in exponent
        break;
    };
    let num_str = substr(s, start, i);
    return [__str_to_num(num_str), i];
};

// ── Parse Value (recursive) ──
fn _json_parse_value(s, i) {
    let i = _json_skip_ws(s, i);
    if i >= len(s) { return [0, i]; };
    let c = __char_code(char_at(s, i));

    // String
    if c == 34 { return _json_parse_string(s, i); };

    // Number
    if c == 45 || (c >= 48 && c <= 57) { return _json_parse_number(s, i); };

    // true
    if c == 116 {
        if __str_starts_with(substr(s, i, i + 4), "true") == 1 {
            return [1, i + 4];
        };
    };

    // false
    if c == 102 {
        if __str_starts_with(substr(s, i, i + 5), "false") == 1 {
            return [0, i + 5];
        };
    };

    // null
    if c == 110 {
        if __str_starts_with(substr(s, i, i + 4), "null") == 1 {
            return [0, i + 4];
        };
    };

    // Array
    if c == 91 { return _json_parse_array(s, i); };

    // Object
    if c == 123 { return _json_parse_object(s, i); };

    return [0, i + 1]; // unknown, skip
};

// ── Parse Array ──
fn _json_parse_array(s, i) {
    let i = i + 1; // skip [
    let arr = [];
    let i = _json_skip_ws(s, i);
    if i < len(s) {
        if __char_code(char_at(s, i)) == 93 { return [arr, i + 1]; }; // empty ]
    };
    while i < len(s) {
        let result = _json_parse_value(s, i);
        push(arr, result[0]);
        let i = result[1];
        let i = _json_skip_ws(s, i);
        if i >= len(s) { break; };
        if __char_code(char_at(s, i)) == 93 { return [arr, i + 1]; }; // ]
        if __char_code(char_at(s, i)) == 44 { let i = i + 1; }; // comma
    };
    return [arr, i];
};

// ── Parse Object ──
fn _json_parse_object(s, i) {
    let i = i + 1; // skip {
    let obj = __dict_new();
    let i = _json_skip_ws(s, i);
    if i < len(s) {
        if __char_code(char_at(s, i)) == 125 { return [obj, i + 1]; }; // empty }
    };
    while i < len(s) {
        let i = _json_skip_ws(s, i);
        // Key (must be string)
        let key_result = _json_parse_string(s, i);
        let key = key_result[0];
        let i = key_result[1];
        let i = _json_skip_ws(s, i);
        // Colon
        if i < len(s) { if __char_code(char_at(s, i)) == 58 { let i = i + 1; }; };
        // Value
        let val_result = _json_parse_value(s, i);
        let obj = __dict_set(obj, key, val_result[0]);
        let i = val_result[1];
        let i = _json_skip_ws(s, i);
        if i >= len(s) { break; };
        if __char_code(char_at(s, i)) == 125 { return [obj, i + 1]; }; // }
        if __char_code(char_at(s, i)) == 44 { let i = i + 1; }; // comma
    };
    return [obj, i];
};

// ═══ PUBLIC API ═══
fn parse_json(s) {
    let result = _json_parse_value(s, 0);
    return result[0];
};

// ── Stringify (recursive, type-aware) ──
fn json_stringify(val) {
    let t = type_of(val);
    if t == "number" { return __to_string(val); };
    if t == "string" { return "\"" + val + "\""; };
    if t == "array" {
        let parts = [];
        let i = 0;
        while i < len(val) {
            push(parts, json_stringify(val[i]));
            let i = i + 1;
        };
        return "[" + __str_join(parts, ",") + "]";
    };
    if t == "dict" {
        let keys = __dict_keys(val);
        let parts = [];
        let i = 0;
        while i < len(keys) {
            let k = keys[i];
            let v = __dict_get(val, k);
            push(parts, "\"" + k + "\":" + json_stringify(v));
            let i = i + 1;
        };
        return "{" + __str_join(parts, ",") + "}";
    };
    return __to_string(val);
};

emit "json loaded";
