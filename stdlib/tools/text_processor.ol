// stdlib/tools/text_processor.ol — Text processing. Pure Olang.
// LLM: BPE/WordPiece tokenizer, attention. Nox: char_at. This bridges.

// ═══ NORMALIZATION ═══

// Clean text: trim, collapse spaces, lowercase
pub fn normalize_text(_text) {
    let _trimmed = __str_trim(_text);
    let _out = "";
    let _prev_space = 0;
    let _i = 0;
    while _i < len(_trimmed) {
        let _c = __char_code(char_at(_trimmed, _i));
        // Collapse multiple spaces
        if _c == 32 || _c == 9 || _c == 10 {
            if _prev_space == 0 { let _out = _out + " "; };
            let _prev_space = 1;
        } else {
            // Lowercase ASCII
            if _c >= 65 { if _c <= 90 { let _c = _c + 32; }; };
            let _out = _out + __chr(_c);
            let _prev_space = 0;
        };
        let _i = _i + 1;
    };
    return _out;
}

// Remove punctuation (keep alphanumeric + space)
pub fn strip_punct(_text) {
    let _out = "";
    let _i = 0;
    while _i < len(_text) {
        let _c = __char_code(char_at(_text, _i));
        // Keep: a-z A-Z 0-9 space
        let _keep = 0;
        if _c >= 48 { if _c <= 57 { let _keep = 1; }; };   // 0-9
        if _c >= 65 { if _c <= 90 { let _keep = 1; }; };   // A-Z
        if _c >= 97 { if _c <= 122 { let _keep = 1; }; };  // a-z
        if _c == 32 { let _keep = 1; };                      // space
        if _c > 127 { let _keep = 1; };                      // UTF-8 (Vietnamese, emoji)
        if _keep == 1 { let _out = _out + char_at(_text, _i); };
        let _i = _i + 1;
    };
    return _out;
}

// ═══ N-GRAMS ═══

// Character n-grams: "hello" with n=2 → ["he", "el", "ll", "lo"]
pub fn char_ngrams(_text, _n) {
    let _result = [];
    let _i = 0;
    while _i <= len(_text) - _n {
        push(_result, substr(_text, _i, _i + _n));
        let _i = _i + 1;
    };
    return _result;
}

// Word n-grams: "i love olang" with n=2 → ["i love", "love olang"]
pub fn word_ngrams(_text, _n) {
    let _words = _split_words_simple(_text);
    let _result = [];
    let _i = 0;
    while _i <= len(_words) - _n {
        let _gram = "";
        let _j = 0;
        while _j < _n {
            if _j > 0 { let _gram = _gram + " "; };
            let _gram = _gram + __array_get(_words, _i + _j);
            let _j = _j + 1;
        };
        push(_result, _gram);
        let _i = _i + 1;
    };
    return _result;
}

// ═══ TOKENIZER ═══

// Smart tokenize: split into meaningful tokens
// Handles: words, numbers, punctuation groups
pub fn tokenize_text(_text) {
    let _tokens = [];
    let _current = "";
    let _type = 0;  // 0=none, 1=alpha, 2=digit, 3=punct
    let _i = 0;
    
    while _i < len(_text) {
        let _c = __char_code(char_at(_text, _i));
        let _new_type = 0;
        if _c >= 97 { if _c <= 122 { let _new_type = 1; }; };  // a-z
        if _c >= 65 { if _c <= 90 { let _new_type = 1; }; };   // A-Z
        if _c > 127 { let _new_type = 1; };                      // UTF-8
        if _c >= 48 { if _c <= 57 { let _new_type = 2; }; };    // 0-9
        if _c == 32 || _c == 9 || _c == 10 { let _new_type = 0; };  // whitespace
        if _new_type == 0 {
            if _c != 32 { if _c != 9 { if _c != 10 { let _new_type = 3; }; }; };  // punct
        };
        
        if _new_type != _type {
            if len(_current) > 0 { push(_tokens, _current); };
            let _current = "";
            let _type = _new_type;
        };
        
        if _new_type > 0 {
            let _current = _current + char_at(_text, _i);
        };
        let _i = _i + 1;
    };
    if len(_current) > 0 { push(_tokens, _current); };
    return _tokens;
}

// ═══ VIETNAMESE SUPPORT ═══

// Vietnamese compound word detection
// "Ha Noi" = 1 compound, not 2 words
// Detect: 2 adjacent capitalized words = compound
pub fn detect_compounds(_text) {
    let _words = _split_words_simple(_text);
    let _result = [];
    let _i = 0;
    while _i < len(_words) {
        let _word = __array_get(_words, _i);
        // Check if next word exists and both start uppercase
        if _i + 1 < len(_words) {
            let _next = __array_get(_words, _i + 1);
            if _is_capitalized(_word) {
                if _is_capitalized(_next) {
                    // Compound: merge
                    push(_result, _word + " " + _next);
                    let _i = _i + 2;
                    continue;
                };
            };
        };
        push(_result, _word);
        let _i = _i + 1;
    };
    return _result;
}

// Vietnamese word is typically 2-4 chars. Questions end with special words.
pub fn detect_question(_text) {
    let _lower = normalize_text(_text);
    // Question markers in Vietnamese
    if _str_has(_lower, " gi") { return 1; };
    if _str_has(_lower, " nao") { return 1; };
    if _str_has(_lower, " dau") { return 1; };
    if _str_has(_lower, " sao") { return 1; };
    if _str_has(_lower, " khong") { return 1; };
    if _str_has(_lower, " chua") { return 1; };
    if _str_has(_lower, " bao nhieu") { return 1; };
    if _str_has(_lower, " the nao") { return 1; };
    if _str_has(_lower, " ai ") { return 1; };
    // English
    if _str_has(_lower, "what ") { return 1; };
    if _str_has(_lower, "where ") { return 1; };
    if _str_has(_lower, "who ") { return 1; };
    if _str_has(_lower, "how ") { return 1; };
    if _str_has(_lower, "why ") { return 1; };
    // ? at end
    if len(_text) > 0 {
        if __char_code(char_at(_text, len(_text) - 1)) == 63 { return 1; };
    };
    return 0;
}

// Detect greeting
pub fn detect_greeting(_text) {
    let _lower = normalize_text(_text);
    if _lower == "hello" { return 1; };
    if _lower == "hi" { return 1; };
    if _lower == "hey" { return 1; };
    if _str_has(_lower, "chao") { return 1; };
    if _str_has(_lower, "xin chao") { return 1; };
    if _str_has(_lower, "good morning") { return 1; };
    return 0;
}

// Detect emotion keywords
pub fn detect_emotion_text(_text) {
    let _lower = normalize_text(_text);
    let _v = 5;  // neutral
    let _a = 5;
    // Vietnamese emotion words
    if _str_has(_lower, "buon") { let _v = 2; let _a = 3; };
    if _str_has(_lower, "vui") { let _v = 8; let _a = 6; };
    if _str_has(_lower, "gian") { let _v = 2; let _a = 8; };
    if _str_has(_lower, "so") { let _v = 2; let _a = 7; };
    if _str_has(_lower, "yeu") { let _v = 9; let _a = 5; };
    if _str_has(_lower, "ghet") { let _v = 1; let _a = 7; };
    if _str_has(_lower, "chan") { let _v = 3; let _a = 2; };
    if _str_has(_lower, "hanh phuc") { let _v = 9; let _a = 6; };
    // Intensifiers
    if _str_has(_lower, "rat ") { if _v < 5 { let _v = _v - 1; } else { let _v = _v + 1; }; };
    if _str_has(_lower, "qua") { let _a = _a + 1; };
    // Clamp
    if _v < 0 { let _v = 0; }; if _v > 9 { let _v = 9; };
    if _a < 0 { let _a = 0; }; if _a > 9 { let _a = 9; };
    return {v: _v, a: _a};
}

// ═══ KEYWORD EXTRACTION ═══

// Extract important words (≥ 4 chars, not stopwords)
pub fn extract_keywords(_text) {
    let _words = _split_words_simple(normalize_text(_text));
    let _result = [];
    let _i = 0;
    while _i < len(_words) {
        let _w = __array_get(_words, _i);
        if len(_w) >= 4 {
            if _is_stopword(_w) == 0 {
                // Dedup
                let _dup = 0;
                let _j = 0;
                while _j < len(_result) {
                    if __array_get(_result, _j) == _w { let _dup = 1; let _j = len(_result); };
                    let _j = _j + 1;
                };
                if _dup == 0 { push(_result, _w); };
            };
        };
        let _i = _i + 1;
    };
    return _result;
}

// ═══ HELPERS ═══

fn _split_words_simple(_text) {
    let _words = [];
    let _start = 0;
    let _i = 0;
    while _i < len(_text) {
        if __char_code(char_at(_text, _i)) == 32 {
            if _i > _start { push(_words, substr(_text, _start, _i)); };
            let _start = _i + 1;
        };
        let _i = _i + 1;
    };
    if _start < len(_text) { push(_words, substr(_text, _start, len(_text))); };
    return _words;
}

fn _is_capitalized(_word) {
    if len(_word) == 0 { return 0; };
    let _c = __char_code(char_at(_word, 0));
    if _c >= 65 { if _c <= 90 { return 1; }; };
    return 0;
}

fn _is_stopword(_word) {
    // Vietnamese + English stopwords
    if _word == "nhung" { return 1; };
    if _word == "cua " { return 1; };
    if _word == "trong" { return 1; };
    if _word == "duoc" { return 1; };
    if _word == "cac " { return 1; };
    if _word == "the " { return 1; };
    if _word == "this" { return 1; };
    if _word == "that" { return 1; };
    if _word == "with" { return 1; };
    if _word == "from" { return 1; };
    if _word == "have" { return 1; };
    if _word == "been" { return 1; };
    if _word == "were" { return 1; };
    if _word == "will" { return 1; };
    if _word == "would" { return 1; };
    if _word == "could" { return 1; };
    if _word == "should" { return 1; };
    return 0;
}
