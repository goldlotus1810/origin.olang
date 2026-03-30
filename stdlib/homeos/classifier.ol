// Nox Classifier — learn from tagged examples, not hardcoded if/else
// Replaces: 45 "if src==" checks in repl.ol
// Method: find nearest tagged fact in KnowTree → return tag
// freedom: deep think -> growing

// Classify input by finding nearest tagged example
pub fn classify(input) {
    let raw = __file_read("/home/lupin/Origin/homeos.knowledge");
    let best_tag = "";
    let best_score = 0;
    let inp_words = _split_words(input);

    // Scan tagged facts
    let i = 0;
    while i < len(raw) {
        // Find lines starting with "tag:"
        let is_line_start = 0;
        if i == 0 { is_line_start = 1; };
        if i > 0 { if __char_code(char_at(raw, i - 1)) == 10 { is_line_start = 1; }; };

        if is_line_start == 1 {
            if i + 4 < len(raw) {
                if __substr(raw, i, i + 4) == "tag:" {
                    // Extract tag and example text
                    let le = i;
                    while le < len(raw) { if __char_code(char_at(raw, le)) == 10 { break; }; le = le + 1; };
                    let line = __substr(raw, i + 4, le);

                    // Parse: "code emit 42" → tag="code", example="emit 42"
                    let si = 0;
                    while si < len(line) { if char_at(line, si) == " " { break; }; si = si + 1; };
                    let tag = __substr(line, 0, si);
                    let example = "";
                    if si + 1 < len(line) { let example = __substr(line, si + 1, len(line)); };

                    // Score: count matching words between input and example
                    let ex_words = _split_words(example);
                    let score = _word_overlap(inp_words, ex_words);

                    if score > best_score {
                        let best_score = score;
                        let best_tag = tag;
                    };
                };
            };
        };
        i = i + 1;
    };

    return best_tag;
}

// Classify and return both tag and action (for tag:action:fn patterns)
pub fn classify_action(input) {
    let raw = __file_read("/home/lupin/Origin/homeos.knowledge");
    let best_tag = "";
    let best_action = "";
    let best_score = 0;
    let inp_words = _split_words(input);

    let i = 0;
    while i < len(raw) {
        let is_line_start = 0;
        if i == 0 { is_line_start = 1; };
        if i > 0 { if __char_code(char_at(raw, i - 1)) == 10 { is_line_start = 1; }; };

        if is_line_start == 1 {
            if i + 11 < len(raw) {
                if __substr(raw, i, i + 11) == "tag:action:" {
                    let le = i;
                    while le < len(raw) { if __char_code(char_at(raw, le)) == 10 { break; }; le = le + 1; };
                    let line = __substr(raw, i + 11, le);
                    // Parse: "sys_info system info" → action="sys_info", text="system info"
                    let si = 0;
                    while si < len(line) { if char_at(line, si) == " " { break; }; si = si + 1; };
                    let action = __substr(line, 0, si);
                    let text = "";
                    if si + 1 < len(line) { let text = __substr(line, si + 1, len(line)); };

                    let ex_words = _split_words(text);
                    let score = _word_overlap(inp_words, ex_words);

                    if score > best_score {
                        let best_score = score;
                        let best_tag = "action";
                        let best_action = action;
                    };
                };
            };
        };
        i = i + 1;
    };

    return { tag: best_tag, action: best_action, score: best_score };
}

// Split string into words
fn _split_words(s) {
    let words = [];
    let start = 0;
    let i = 0;
    while i <= len(s) {
        let is_sep = 0;
        if i == len(s) { is_sep = 1; };
        if i < len(s) { if __char_code(char_at(s, i)) == 32 { is_sep = 1; }; };
        if is_sep == 1 {
            if i > start { push(words, __substr(s, start, i)); };
            start = i + 1;
        };
        i = i + 1;
    };
    return words;
}

// Count overlapping words between two word lists
fn _word_overlap(a, b) {
    let score = 0;
    let ai = 0;
    while ai < len(a) {
        let bi = 0;
        while bi < len(b) {
            if a[ai] == b[bi] { score = score + 1; };
            bi = bi + 1;
        };
        ai = ai + 1;
    };
    return score;
}
