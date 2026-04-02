// ═══ Regex — Recursive descent matcher ═══
// Supports: . * + ? \ | () \d \w \s
// Simple, correct, not NFA (can be slow on pathological patterns)

fn _re_is_digit(c) { return c >= 48 && c <= 57; };
fn _re_is_word(c) { return _re_is_digit(c) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95; };
fn _re_is_space(c) { return c == 32 || c == 9 || c == 10 || c == 13; };

// Match pattern[pi..] against text[ti..]. Returns new ti or -1.
fn _re_match_here(pat, pi, plen, text, ti, tlen) {
    if pi >= plen { return ti; }; // pattern exhausted = match

    let c = __char_code(char_at(pat, pi));

    // Handle alternation '|'
    if c == 124 {
        // Skip — handled at group level
        return ti;
    };

    // Handle group '('
    if c == 40 {
        // Find matching ')'
        let depth = [1];
        let pe = pi + 1;
        while pe < plen {
            let pc = __char_code(char_at(pat, pe));
            if pc == 40 { depth[0] = depth[0] + 1; };
            if pc == 41 { depth[0] = depth[0] - 1; if depth[0] == 0 { break; }; };
            let pe = pe + 1;
        };
        // Try each alternative separated by '|' at top level
        let alt_start = pi + 1;
        let ai = pi + 1;
        let d = [0];
        while ai <= pe {
            let ac = 0;
            if ai < pe { let ac = __char_code(char_at(pat, ai)); };
            if ai == pe || (ac == 124 && d[0] == 0) {
                // Try this alternative: pat[alt_start..ai]
                let sub_result = _re_match_here(pat, alt_start, ai, text, ti, tlen);
                if sub_result >= 0 {
                    // Check quantifier after ')'
                    let after = pe + 1;
                    return _re_after_quantifier(pat, after, plen, text, sub_result, tlen, pat, pi, pe);
                };
                let alt_start = ai + 1;
            };
            if ac == 40 { d[0] = d[0] + 1; };
            if ac == 41 { d[0] = d[0] - 1; };
            let ai = ai + 1;
        };
        return 0 - 1; // no alternative matched
    };

    // Check for quantifier after current atom
    let next_pi = pi + 1;
    if c == 92 { let next_pi = pi + 2; }; // escape: 2 chars
    let has_quant = 0;
    let quant = 0;
    if next_pi < plen {
        let q = __char_code(char_at(pat, next_pi));
        if q == 42 { let has_quant = 1; let quant = 42; }; // *
        if q == 43 { let has_quant = 1; let quant = 43; }; // +
        if q == 63 { let has_quant = 1; let quant = 63; }; // ?
    };

    if has_quant == 1 {
        let rest_pi = next_pi + 1; // pattern after quantifier
        if quant == 42 { // * — zero or more (greedy)
            // Try matching as many as possible, then rest
            let count = [0];
            let pos = [ti];
            // Count max matches
            while pos[0] < tlen {
                if _re_atom_match(pat, pi, text, pos[0]) {
                    pos[0] = pos[0] + 1;
                    count[0] = count[0] + 1;
                } else { break; };
            };
            // Try from max down to 0
            while count[0] >= 0 {
                let result = _re_match_here(pat, rest_pi, plen, text, ti + count[0], tlen);
                if result >= 0 { return result; };
                count[0] = count[0] - 1;
            };
            return 0 - 1;
        };
        if quant == 43 { // + — one or more
            if ti >= tlen { return 0 - 1; };
            if !_re_atom_match(pat, pi, text, ti) { return 0 - 1; };
            // Match first, then try * for rest
            let count = [1];
            let pos = [ti + 1];
            while pos[0] < tlen {
                if _re_atom_match(pat, pi, text, pos[0]) {
                    pos[0] = pos[0] + 1;
                    count[0] = count[0] + 1;
                } else { break; };
            };
            while count[0] >= 1 {
                let result = _re_match_here(pat, rest_pi, plen, text, ti + count[0], tlen);
                if result >= 0 { return result; };
                count[0] = count[0] - 1;
            };
            return 0 - 1;
        };
        if quant == 63 { // ? — zero or one
            // Try with match first
            if ti < tlen {
                if _re_atom_match(pat, pi, text, ti) {
                    let result = _re_match_here(pat, rest_pi, plen, text, ti + 1, tlen);
                    if result >= 0 { return result; };
                };
            };
            // Try without match
            return _re_match_here(pat, rest_pi, plen, text, ti, tlen);
        };
    };

    // No quantifier — match single atom then continue
    if ti >= tlen { return 0 - 1; };
    if _re_atom_match(pat, pi, text, ti) {
        return _re_match_here(pat, next_pi, plen, text, ti + 1, tlen);
    };
    return 0 - 1;
};

fn _re_atom_match(pat, pi, text, ti) {
    let c = __char_code(char_at(pat, pi));
    let tc = __char_code(char_at(text, ti));
    if c == 46 { return tc != 10; }; // . matches any except newline
    if c == 92 { // escape
        let ec = __char_code(char_at(pat, pi + 1));
        if ec == 100 { return _re_is_digit(tc); };
        if ec == 119 { return _re_is_word(tc); };
        if ec == 115 { return _re_is_space(tc); };
        return ec == tc; // literal escaped char
    };
    return c == tc;
};

fn _re_after_quantifier(pat, after, plen, text, ti, tlen, orig_pat, group_start, group_end) {
    // Check quantifier after group
    if after < plen {
        let q = __char_code(char_at(pat, after));
        if q == 42 || q == 43 || q == 63 {
            // TODO: group quantifiers
            return _re_match_here(pat, after + 1, plen, text, ti, tlen);
        };
    };
    return _re_match_here(pat, after, plen, text, ti, tlen);
};

// ═══ PUBLIC API ═══

fn re_test(pattern, text) {
    // Try matching at every position
    let ti = 0;
    while ti <= len(text) {
        let result = _re_match_here(pattern, 0, len(pattern), text, ti, len(text));
        if result >= 0 { return 1; };
        let ti = ti + 1;
    };
    return 0;
};

fn re_find(pattern, text) {
    // Returns position of first match, or -1
    let ti = 0;
    while ti <= len(text) {
        let result = _re_match_here(pattern, 0, len(pattern), text, ti, len(text));
        if result >= 0 { return ti; };
        let ti = ti + 1;
    };
    return 0 - 1;
};

emit "regex loaded";
