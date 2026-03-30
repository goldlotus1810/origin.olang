// Nox Classifier — learn from tagged examples, not hardcoded if/else
// Replaces: 45 "if src==" checks in repl.ol
// Method: find nearest tagged fact in KnowTree → return tag
// freedom: deep think -> growing

// Classify input by finding nearest tagged example
pub fn classify(input) {
    let raw = __file_read("/home/lupin/Origin/homeos.knowledge");
    let inp_words = _split_words(input);
    // Collect all tagged lines
    let tags = _extract_tagged_lines(raw);
    // Find best match (use arrays to avoid scope bug with let inside if)
    let best = ["", 0];
    let ti = 0;
    while ti < len(tags) {
        let entry = tags[ti];
        let ex_words = _split_words(entry.text);
        let score = _word_overlap(inp_words, ex_words);
        if _str_contains(entry.text, input) == 1 { score = score + 5; };
        if _str_contains(input, entry.text) == 1 { score = score + 3; };
        if score > best[1] { set_at(best, 0, entry.tag); set_at(best, 1, score); };
        ti = ti + 1;
    };
    return best[0];
}

// Extract all "tag:xxx text" lines from raw knowledge
fn _extract_tagged_lines(raw) {
    let results = [];
    let i = 0;
    while i < len(raw) - 4 {
        let at_start = 0;
        if i == 0 { at_start = 1; };
        if i > 0 { if __char_code(char_at(raw, i - 1)) == 10 { at_start = 1; }; };
        if at_start == 1 {
            if __substr(raw, i, i + 4) == "tag:" {
                let le = i;
                while le < len(raw) { if __char_code(char_at(raw, le)) == 10 { break; }; le = le + 1; };
                let line = __substr(raw, i + 4, le);
                let parsed = _parse_tag_line(line);
                push(results, parsed);
            };
        };
        i = i + 1;
    };
    return results;
}

fn _parse_tag_line(line) {
    let si = 0;
    while si < len(line) { if char_at(line, si) == " " { break; }; si = si + 1; };
    let tag = __substr(line, 0, si);
    let text = __substr(line, si + 1, len(line));
    if si >= len(line) { let text = tag; };
    return { tag: tag, text: text };
}

fn _str_contains(haystack, needle) {
    if len(needle) == 0 { return 0; };
    if len(haystack) < len(needle) { return 0; };
    let i = 0;
    while i <= len(haystack) - len(needle) {
        let match = 1;
        let j = 0;
        while j < len(needle) { if char_at(haystack, i + j) != char_at(needle, j) { match = 0; break; }; j = j + 1; };
        if match == 1 { return 1; };
        i = i + 1;
    };
    return 0;
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
