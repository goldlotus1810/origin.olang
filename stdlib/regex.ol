// stdlib/regex.ol — Regex via VM ASM builtin (Thompson NFA)
// Supports: . * + ? (character classes TODO)
// All NFA logic runs in pure x86-64 ASM — no var_table, no scope issues

pub fn regex_match(text, pattern) {
    return __regex_match(text, pattern);
}

pub fn regex_test(text, pattern) {
    return __regex_search(text, pattern);
}
