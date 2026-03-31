// stdlib/tools/response_gen.ol — Response generation. Pure Olang.
// LLM: composes fluent text from internal representations.
// Nox: returns 1 raw fact verbatim. This fixes that.

// ═══ RESPONSE COMPOSE ═══

// Generate response from query using ranked search + compose
pub fn respond(_query) {
    // 1. Ranked search: get top 3 relevant facts
    let _results = ranked_search(_query, 3);
    if len(_results) == 0 { return ""; };
    
    // 2. Single result: return as-is (clean)
    if len(_results) == 1 { return __array_get(_results, 0); };
    
    // 3. Multiple results: compose
    return compose_response(_query, _results);
}

// Compose response from multiple facts
pub fn compose_response(_query, _facts) {
    if len(_facts) == 0 { return ""; };
    if len(_facts) == 1 { return __array_get(_facts, 0); };
    
    // Score each fact for relevance
    let _scores = [];
    let _i = 0;
    while _i < len(_facts) {
        push(_scores, relevance_score(_query, __array_get(_facts, _i)));
        let _i = _i + 1;
    };
    
    // Best fact first
    let _best_idx = 0;
    let _best_score = __array_get(_scores, 0);
    let _i = 1;
    while _i < len(_scores) {
        if __array_get(_scores, _i) > _best_score {
            let _best_score = __array_get(_scores, _i);
            let _best_idx = _i;
        };
        let _i = _i + 1;
    };
    
    let _out = __array_get(_facts, _best_idx);
    
    // Add supplementary facts if they add new info (< 60% overlap)
    let _i = 0;
    while _i < len(_facts) {
        if _i != _best_idx {
            let _fact = __array_get(_facts, _i);
            if _word_overlap_pct(_out, _fact) < 60 {
                let _out = _out + ". " + _fact;
            };
        };
        let _i = _i + 1;
    };
    
    return _out;
}

// ═══ RESPONSE TEMPLATES ═══

// Factual answer: "X là Y"
pub fn answer_what(_subject, _facts) {
    if len(_facts) == 0 { return _subject + ": Nox khong biet."; };
    return __array_get(_facts, 0);
}

// List answer: "Co N ket qua: ..."
pub fn answer_list(_query, _facts) {
    if len(_facts) == 0 { return "Khong tim thay ket qua cho: " + _query; };
    let _out = "Co " + __to_string(len(_facts)) + " ket qua:\n";
    let _i = 0;
    while _i < len(_facts) {
        let _out = _out + "  " + __to_string(_i + 1) + ". " + __array_get(_facts, _i) + "\n";
        let _i = _i + 1;
    };
    return _out;
}

// Compare answer: "A vs B"
pub fn answer_compare(_a, _b) {
    let _facts_a = ranked_search(_a, 2);
    let _facts_b = ranked_search(_b, 2);
    let _out = _a + ": ";
    if len(_facts_a) > 0 { let _out = _out + __array_get(_facts_a, 0); } 
    else { let _out = _out + "(khong biet)"; };
    let _out = _out + "\n" + _b + ": ";
    if len(_facts_b) > 0 { let _out = _out + __array_get(_facts_b, 0); }
    else { let _out = _out + "(khong biet)"; };
    return _out;
}

// Emotion-aware response: adjust tone based on V/A
pub fn answer_emotional(_query, _facts, _v, _a) {
    if len(_facts) == 0 {
        if _v < 3 { return "Nox hieu. Nox khong biet nhung Nox lang nghe."; };
        return "Nox khong biet ve dieu nay.";
    };
    let _response = __array_get(_facts, 0);
    // Low valence (sadness) → softer prefix
    if _v < 3 {
        let _response = "Nox hieu cam giac do. " + _response;
    };
    // High arousal (excitement) → acknowledge energy
    if _a > 5 {
        let _response = _response + " Day la dieu thu vi!";
    };
    return _response;
}

// Confidence-rated response
pub fn answer_with_confidence(_query, _facts, _scores) {
    if len(_facts) == 0 { return {text: "Nox khong biet.", confidence: 0}; };
    let _best_score = __array_get(_scores, 0);
    let _conf = 0;
    if _best_score > 300 { let _conf = 90; }
    else { if _best_score > 100 { let _conf = 60; }
    else { let _conf = 30; }; };
    return {text: __array_get(_facts, 0), confidence: _conf};
}

// ═══ SUMMARIZE ═══

// Summarize N facts into 1 sentence
pub fn summarize(_facts, _max_words) {
    if len(_facts) == 0 { return ""; };
    if len(_facts) == 1 { return __array_get(_facts, 0); };
    
    // Take first _max_words words from deduped facts
    let _unique = dedup(_facts);
    let _combined = "";
    let _word_count = 0;
    let _fi = 0;
    while _fi < len(_unique) {
        let _fact = __array_get(_unique, _fi);
        let _words = _split_to_words(_fact);
        let _wi = 0;
        while _wi < len(_words) {
            if _word_count >= _max_words { return _combined; };
            if _word_count > 0 { let _combined = _combined + " "; };
            let _combined = _combined + __array_get(_words, _wi);
            let _word_count = _word_count + 1;
            let _wi = _wi + 1;
        };
        let _fi = _fi + 1;
    };
    return _combined;
}

// ═══ HELPERS ═══

fn _word_overlap_pct(_a, _b) {
    let _wa = _split_to_words(_a);
    let _wb = _split_to_words(_b);
    if len(_wa) == 0 { return 0; };
    let _match = 0;
    let _i = 0;
    while _i < len(_wa) {
        let _w = __array_get(_wa, _i);
        let _j = 0;
        while _j < len(_wb) {
            if __array_get(_wb, _j) == _w { let _match = _match + 1; let _j = len(_wb); };
            let _j = _j + 1;
        };
        let _i = _i + 1;
    };
    return _match * 100 / len(_wa);
}
