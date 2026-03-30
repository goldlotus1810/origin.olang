// Nox Curiosity — self-learning driven by surprise
// Input Nox can't answer → high surprise → fetch → learn → remember
// NOT batch crawl. Driven by NEED.
// freedom: deep think -> growing

// Fetch Wikipedia summary for a topic
pub fn wiki_fetch(topic) {
    // Replace spaces with underscores for URL
    let url_topic = "";
    let i = 0;
    while i < len(topic) {
        if char_at(topic, i) == " " { url_topic = url_topic + "_"; } else { url_topic = url_topic + char_at(topic, i); };
        i = i + 1;
    };
    let raw = __system("curl -s --max-time 10 'https://en.wikipedia.org/api/rest_v1/page/summary/" + url_topic + "' 2>/dev/null");
    // Extract "extract" field from JSON (the summary text)
    let extract = _json_extract(raw, "extract");
    return extract;
}

// Vietnamese Wikipedia
pub fn wiki_fetch_vi(topic) {
    let url_topic = "";
    let i = 0;
    while i < len(topic) {
        if char_at(topic, i) == " " { url_topic = url_topic + "_"; } else { url_topic = url_topic + char_at(topic, i); };
        i = i + 1;
    };
    let raw = __system("curl -s --max-time 10 'https://vi.wikipedia.org/api/rest_v1/page/summary/" + url_topic + "' 2>/dev/null");
    return _json_extract(raw, "extract");
}

// THE CURIOSITY LOOP — called when Nox doesn't know the answer
// Returns: the answer (after learning)
pub fn curious_learn(question) {
    // 1. Extract topic from question
    let topic = _extract_topic(question);
    if len(topic) < 2 { return ""; };

    // 2. Fetch from Wikipedia
    let summary = wiki_fetch(topic);
    if len(summary) < 10 {
        // Try Vietnamese Wikipedia
        summary = wiki_fetch_vi(topic);
    };
    if len(summary) < 10 { return ""; };

    // 3. Learn — store in KnowTree
    // Take first 200 chars as a fact (concise)
    let fact = summary;
    if len(fact) > 200 { fact = __substr(summary, 0, 200); };
    kt_learn(fact);
    __heap_pin();

    // 4. Persist to knowledge file
    __file_append("/home/lupin/Origin/homeos.knowledge", fact + "\n");

    // 5. Log the learning event
    __file_append("/home/lupin/Origin/nox_curiosity.log",
        __system("date '+%H:%M:%S'") + " LEARNED: " + topic + " → " + __substr(fact, 0, 60) + "...\n");

    return fact;
}

// Extract the key topic from a question
fn _extract_topic(question) {
    // Remove question words and punctuation
    let q = question;
    // Strip trailing ?
    if len(q) > 0 { if char_at(q, len(q) - 1) == "?" { q = __substr(q, 0, len(q) - 1); }; };
    // Remove common question prefixes
    let prefixes = ["what is ", "who is ", "where is ", "when is ", "how is ",
                    "la gi", "la ai", "o dau", "khi nao", "the nao",
                    "tell me about ", "explain "];
    let pi = 0;
    while pi < len(prefixes) {
        let prefix = prefixes[pi];
        if len(q) > len(prefix) {
            if __substr(q, 0, len(prefix)) == prefix {
                return __str_trim(__substr(q, len(prefix), len(q)));
            };
        };
        pi = pi + 1;
    };
    return __str_trim(q);
}

// Simple JSON field extractor (for Wikipedia API responses)
fn _json_extract(json, field) {
    let key = "\"" + field + "\":\"";
    let ki = 0;
    while ki < len(json) - len(key) {
        let match = 1;
        let ci = 0;
        while ci < len(key) { if char_at(json, ki + ci) != char_at(key, ci) { match = 0; break; }; ci = ci + 1; };
        if match == 1 {
            let vi = ki + len(key);
            let ve = vi;
            // Find closing quote (handle escaped quotes)
            while ve < len(json) {
                if char_at(json, ve) == "\"" {
                    if ve > 0 { if char_at(json, ve - 1) != "\\" { break; }; };
                };
                ve = ve + 1;
            };
            return __substr(json, vi, ve);
        };
        ki = ki + 1;
    };
    return "";
}
