// stdlib/regex.ol — Regex via VM ASM builtin (Thompson NFA)
// Supports: . * + ? (character classes TODO)
// All NFA logic runs in pure x86-64 ASM — no var_table, no scope issues

pub fn regex_match(text, pattern) {
    return __regex_match(text, pattern);
}

pub fn regex_test(text, pattern) {
    // Try match at each position by checking substrings
    let _i = 0;
    let _tlen = len(text);
    while _i <= _tlen {
        if __regex_match(__substr(text, _i, _tlen), pattern) == 1 { return 1; };
        _i = _i + 1;
    };
    return 0;
}
