// homeos/nlcompute.ol — Natural Language → Olang Code → Result
// Vietnamese + English support. Pattern matching approach.
// Supports both diacritics (tổng, sắp xếp) and ASCII (tong, sap xep).

// ═══════════════════════════════════════════════════════════════
// Helper: check if first word of text matches (for NL dispatch)
// ═══════════════════════════════════════════════════════════════
fn _nl_first(_nf_text, _nf_word) {
    let _nf_wl = len(_nf_word);
    if len(_nf_text) < _nf_wl { return 0; };
    let _nf_j = 0;
    while _nf_j < _nf_wl {
        if char_at(_nf_text, _nf_j) != char_at(_nf_word, _nf_j) { return 0; };
        let _nf_j = _nf_j + 1;
    };
    // After match: must be end of string or space
    if len(_nf_text) == _nf_wl { return 1; };
    let _nf_after = char_at(_nf_text, _nf_wl);
    if _nf_after == " " { return 1; };
    if _nf_after == "[" { return 1; };
    return 0;
};

// ═══════════════════════════════════════════════════════════════
// Helper: check if text contains word (boot-compatible)
// ═══════════════════════════════════════════════════════════════
fn _nl_has(_nh_text, _nh_word) {
    let _nh_tl = len(_nh_text);
    let _nh_wl = len(_nh_word);
    if _nh_wl > _nh_tl { return 0; };
    let _nh_i = 0;
    while _nh_i <= (_nh_tl - _nh_wl) {
        let _nh_m = 1;
        let _nh_j = 0;
        while _nh_j < _nh_wl {
            if char_at(_nh_text, _nh_i + _nh_j) != char_at(_nh_word, _nh_j) {
                let _nh_m = 0;
            };
            let _nh_j = _nh_j + 1;
        };
        if _nh_m == 1 { return 1; };
        let _nh_i = _nh_i + 1;
    };
    return 0;
};

// Extract number after a word (e.g. "den 100" → 100)
fn _nl_num_after(_na_text, _na_word) {
    let _na_tl = len(_na_text);
    let _na_wl = len(_na_word);
    let _na_i = 0;
    while _na_i <= (_na_tl - _na_wl) {
        let _na_m = 1;
        let _na_j = 0;
        while _na_j < _na_wl {
            if char_at(_na_text, _na_i + _na_j) != char_at(_na_word, _na_j) { let _na_m = 0; };
            let _na_j = _na_j + 1;
        };
        if _na_m == 1 {
            // Found word, skip it + space, read number
            let _na_k = _na_i + _na_wl;
            if _na_k < _na_tl {
                if __char_code(char_at(_na_text, _na_k)) == 32 { let _na_k = _na_k + 1; };
            };
            let _na_num = "";
            while _na_k < _na_tl {
                let _na_c = __char_code(char_at(_na_text, _na_k));
                if _na_c >= 48 { if _na_c <= 57 { let _na_num = _na_num + char_at(_na_text, _na_k); }; };
                if _na_c == 32 { if len(_na_num) > 0 { return __to_number(_na_num); }; };
                let _na_k = _na_k + 1;
            };
            if len(_na_num) > 0 { return __to_number(_na_num); };
        };
        let _na_i = _na_i + 1;
    };
    return 0;
};

// Extract array from text: [1,2,3] or 1,2,3
fn _nl_extract_array(_ea_text) {
    let _ea_start = 0;
    let _ea_end = len(_ea_text);
    // Find [ and ]
    let _ea_i = 0;
    while _ea_i < len(_ea_text) {
        if char_at(_ea_text, _ea_i) == "[" { let _ea_start = _ea_i; };
        if char_at(_ea_text, _ea_i) == "]" { let _ea_end = _ea_i + 1; };
        let _ea_i = _ea_i + 1;
    };
    return __substr(_ea_text, _ea_start, _ea_end);
};

// ═══════════════════════════════════════════════════════════════
// NL → Olang code generator
// ═══════════════════════════════════════════════════════════════
pub fn nl_to_code(_nc_input) {
    let _nc_raw = __str_trim(_nc_input);
    // Normalize: strip diacritics so "tổng" and "tong" both match "tong"
    let _nc_s = strip_diacritics(_nc_raw);

    // Tổng/sum: "tong tu X den Y" / "sum from X to Y"
    if _nl_has(_nc_s, "tong") == 1 || _nl_first(_nc_s, "sum") == 1 {
        let _nc_from = _nl_num_after(_nc_s, "tu");
        if _nc_from == 0 { let _nc_from = _nl_num_after(_nc_s, "from"); };
        let _nc_to = _nl_num_after(_nc_s, "den");
        if _nc_to == 0 { let _nc_to = _nl_num_after(_nc_s, "to"); };
        if _nc_to > 0 {
            // Use Gauss formula: sum(a..b) = b*(b+1)/2 - (a-1)*a/2
            return "emit " + __to_string(_nc_to) + " * (" + __to_string(_nc_to) + " + 1) / 2 - (" + __to_string(_nc_from) + " - 1) * " + __to_string(_nc_from) + " / 2;";
        };
    };

    // Sắp xếp/sort (normalized: "sap xep [...]" / "sort [...]")
    if _nl_first(_nc_s, "sap") == 1 || _nl_first(_nc_s, "sort") == 1 {
        let _nc_arr = _nl_extract_array(_nc_s);
        if len(_nc_arr) > 0 {
            return "emit sort(" + _nc_arr + ");";
        };
    };

    // Fibonacci: "fibonacci X" / "fib X"
    if _nl_first(_nc_s, "fibonacci") == 1 || _nl_first(_nc_s, "fib") == 1 {
        let _nc_n = _nl_num_after(_nc_s, "fibonacci");
        if _nc_n == 0 { let _nc_n = _nl_num_after(_nc_s, "fib"); };
        if _nc_n > 0 {
            return "fn _fib(n) { if n < 2 { return n; }; return _fib(n-1) + _fib(n-2); }; emit _fib(" + __to_string(_nc_n) + ");";
        };
    };

    // Giai thừa/factorial (normalized: "giai thua X" / "factorial X" / "fact X")
    if _nl_first(_nc_s, "giai") == 1 || _nl_first(_nc_s, "factorial") == 1 || _nl_first(_nc_s, "fact") == 1 {
        let _nc_n = _nl_num_after(_nc_s, "giai thua");
        if _nc_n == 0 { let _nc_n = _nl_num_after(_nc_s, "factorial"); };
        if _nc_n == 0 { let _nc_n = _nl_num_after(_nc_s, "fact"); };
        if _nc_n > 0 {
            return "fn _fact(n) { if n < 2 { return 1; }; return n * _fact(n-1); }; emit _fact(" + __to_string(_nc_n) + ");";
        };
    };

    // Số nguyên tố/prime (normalized: "nguyen to" / "primes under X")
    if _nl_has(_nc_s, "nguyen to") == 1 || _nl_first(_nc_s, "primes") == 1 || _nl_first(_nc_s, "prime") == 1 || _nl_first(_nc_s, "prim") == 1 {
        let _nc_n = _nl_num_after(_nc_s, "hon");
        if _nc_n == 0 { let _nc_n = _nl_num_after(_nc_s, "under"); };
        if _nc_n == 0 { let _nc_n = _nl_num_after(_nc_s, "duoi"); };
        if _nc_n == 0 { let _nc_n = _nl_num_after(_nc_s, "prim"); };
        if _nc_n == 0 { let _nc_n = _nl_num_after(_nc_s, "prime"); };
        if _nc_n == 0 { let _nc_n = _nl_num_after(_nc_s, "primes"); };
        if _nc_n > 0 {
            return "fn _is_p(n) { if n < 2 { return 0; }; let d = 2; while d * d <= n { if n % d == 0 { return 0; }; let d = d + 1; }; return 1; }; let r = []; let i = 2; while i < " + __to_string(_nc_n) + " { if _is_p(i) == 1 { let _ = push(r, i); }; let i = i + 1; }; emit r;";
        };
    };

    // Đảo ngược/reverse (normalized: "dao nguoc [...]" / "reverse [...]")
    if _nl_first(_nc_s, "dao") == 1 || _nl_first(_nc_s, "reverse") == 1 || _nl_first(_nc_s, "rev") == 1 {
        let _nc_arr = _nl_extract_array(_nc_s);
        if len(_nc_arr) > 0 {
            return "let _a = " + _nc_arr + "; let _r = []; let _i = len(_a) - 1; while _i >= 0 { let _ = push(_r, _a[_i]); let _i = _i - 1; }; emit _r;";
        };
    };

    // Tích/product (normalized: "tich tu X den Y" / "product from X to Y")
    if _nl_first(_nc_s, "tich") == 1 || _nl_first(_nc_s, "product") == 1 {
        let _nc_from = _nl_num_after(_nc_s, "tu");
        if _nc_from == 0 { let _nc_from = _nl_num_after(_nc_s, "from"); };
        let _nc_to = _nl_num_after(_nc_s, "den");
        if _nc_to == 0 { let _nc_to = _nl_num_after(_nc_s, "to"); };
        if _nc_to > 0 {
            return "fn _prod(a, b) { if a > b { return 1; }; return a * _prod(a + 1, b); }; emit _prod(" + __to_string(_nc_from) + ", " + __to_string(_nc_to) + ");";
        };
    };

    // Căn bậc 2/sqrt (normalized: "can bac 2 cua X" / "sqrt X")
    if _nl_first(_nc_s, "can") == 1 || _nl_first(_nc_s, "sqrt") == 1 {
        let _nc_n = _nl_num_after(_nc_s, "cua");
        if _nc_n == 0 { let _nc_n = _nl_num_after(_nc_s, "sqrt"); };
        if _nc_n == 0 { let _nc_n = _nl_num_after(_nc_s, "can"); };
        if _nc_n > 0 {
            return "emit __isqrt(" + __to_string(_nc_n) + ");";
        };
    };

    return "";
};
