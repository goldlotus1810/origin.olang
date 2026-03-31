// stdlib/tools/text_utils.ol — String tools. Pure Olang.
// Nox có __char_code, char_at, substr, len, concat, __str_trim, __str_find
// Tools này mở rộng thành split, join, lowercase, normalize, count...

// Split string by separator character
pub fn str_split(_text, _sep) {
    let _result = [];
    let _start = 0;
    let _sep_code = __char_code(_sep);
    let _i = 0;
    while _i < len(_text) {
        if __char_code(char_at(_text, _i)) == _sep_code {
            if _i > _start {
                push(_result, substr(_text, _start, _i));
            };
            let _start = _i + 1;
        };
        let _i = _i + 1;
    };
    if _start < len(_text) {
        push(_result, substr(_text, _start, len(_text)));
    };
    return _result;
}

// Split string by newline → array of lines
pub fn str_lines(_text) {
    return str_split(_text, "\n");
}

// Split by tab
pub fn str_split_tab(_text) {
    return str_split(_text, "\t");
}

// Split by space → words
pub fn str_words(_text) {
    return str_split(_text, " ");
}

// Join array with separator
pub fn str_join(_arr, _sep) {
    let _out = "";
    let _i = 0;
    while _i < len(_arr) {
        if _i > 0 { let _out = _out + _sep; };
        let _out = _out + __array_get(_arr, _i);
        let _i = _i + 1;
    };
    return _out;
}

// Lowercase ASCII (a-z only, sufficient for English data)
pub fn str_lower(_s) {
    let _out = "";
    let _i = 0;
    while _i < len(_s) {
        let _c = __char_code(char_at(_s, _i));
        if _c >= 65 { if _c <= 90 { let _c = _c + 32; }; };
        let _out = _out + __chr(_c);
        let _i = _i + 1;
    };
    return _out;
}

// Count occurrences of substring
pub fn str_count(_hay, _needle) {
    let _count = 0;
    let _nlen = len(_needle);
    if _nlen == 0 { return 0; };
    let _i = 0;
    while _i <= len(_hay) - _nlen {
        let _match = 1;
        let _j = 0;
        while _j < _nlen {
            if char_at(_hay, _i + _j) != char_at(_needle, _j) {
                let _match = 0;
                let _j = _nlen;
            };
            let _j = _j + 1;
        };
        if _match == 1 { let _count = _count + 1; let _i = _i + _nlen; }
        else { let _i = _i + 1; };
    };
    return _count;
}

// Line count
pub fn str_line_count(_text) {
    let _count = 1;
    let _i = 0;
    while _i < len(_text) {
        if __char_code(char_at(_text, _i)) == 10 { let _count = _count + 1; };
        let _i = _i + 1;
    };
    return _count;
}

// Head: first N lines
pub fn str_head(_text, _n) {
    let _count = 0;
    let _i = 0;
    while _i < len(_text) {
        if __char_code(char_at(_text, _i)) == 10 {
            let _count = _count + 1;
            if _count >= _n { return substr(_text, 0, _i); };
        };
        let _i = _i + 1;
    };
    return _text;
}

// Tail: last N lines
pub fn str_tail(_text, _n) {
    let _positions = [];
    let _i = 0;
    while _i < len(_text) {
        if __char_code(char_at(_text, _i)) == 10 {
            push(_positions, _i);
        };
        let _i = _i + 1;
    };
    let _total = len(_positions);
    if _total <= _n { return _text; };
    let _start = __array_get(_positions, _total - _n) + 1;
    return substr(_text, _start, len(_text));
}

// Starts with prefix
pub fn str_starts_with(_text, _prefix) {
    if len(_prefix) > len(_text) { return 0; };
    return substr(_text, 0, len(_prefix)) == _prefix;
}

// Ends with suffix
pub fn str_ends_with(_text, _suffix) {
    if len(_suffix) > len(_text) { return 0; };
    return substr(_text, len(_text) - len(_suffix), len(_text)) == _suffix;
}

// Pad right to width
pub fn str_pad_right(_text, _width) {
    let _out = _text;
    while len(_out) < _width { let _out = _out + " "; };
    return _out;
}

// Get line N from text (0-indexed)
pub fn str_get_line(_text, _n) {
    let _count = 0;
    let _start = 0;
    let _i = 0;
    while _i < len(_text) {
        if __char_code(char_at(_text, _i)) == 10 {
            if _count == _n { return substr(_text, _start, _i); };
            let _count = _count + 1;
            let _start = _i + 1;
        };
        let _i = _i + 1;
    };
    if _count == _n { return substr(_text, _start, len(_text)); };
    return "";
}

// Get lines from N to M (inclusive)
pub fn str_get_lines(_text, _from, _to) {
    let _out = "";
    let _count = 0;
    let _start = 0;
    let _i = 0;
    while _i < len(_text) {
        if __char_code(char_at(_text, _i)) == 10 {
            if _count >= _from { if _count <= _to {
                if len(_out) > 0 { let _out = _out + "\n"; };
                let _out = _out + substr(_text, _start, _i);
            }; };
            let _count = _count + 1;
            let _start = _i + 1;
            if _count > _to { return _out; };
        };
        let _i = _i + 1;
    };
    if _count >= _from { if _count <= _to {
        if len(_out) > 0 { let _out = _out + "\n"; };
        let _out = _out + substr(_text, _start, len(_text));
    }; };
    return _out;
}

// FNV-1a hash (same as _kt_real_mol uses)
pub fn str_hash(_text) {
    let _h = 2166136261;
    let _i = 0;
    while _i < len(_text) {
        let _h = __bit_xor(_h, __char_code(char_at(_text, _i)));
        // FNV multiply: h * 0x01000193 
        // Olang doesn't have unsigned multiply, use shifts
        let _h = _h * 16777619;
        let _i = _i + 1;
    };
    return __bit_and(_h, 65535);  // u16 range
}
