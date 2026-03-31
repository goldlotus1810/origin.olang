// stdlib/tools/search_engine.ol — Relevance search. Pure Olang.
// LLM: attention scores → weighted sum → ranked results.
// Nox: first match. This fixes that.

// ═══ RELEVANCE SCORING ═══

// Score how relevant a fact is to a query
// Higher = more relevant. Combines:
//   - Word overlap (how many query words appear in fact)
//   - Position bonus (query word early in fact = more relevant)
//   - Length penalty (very long facts dilute relevance)
//   - 5D distance (P_weight molecular similarity)
pub fn relevance_score(_query, _fact) {
    let _score = 0;
    
    // 1. Word overlap: each query word found in fact = +100
    let _qwords = _split_to_words(_query);
    let _matches = 0;
    let _qi = 0;
    while _qi < len(_qwords) {
        let _qw = __array_get(_qwords, _qi);
        if len(_qw) >= 2 {
            if _str_has(_fact, _qw) {
                let _matches = _matches + 1;
                // Position bonus: word found early = +50
                let _pos = _find_in(_fact, _qw);
                if _pos >= 0 {
                    if _pos < 20 { let _score = _score + 50; };
                };
            };
        };
        let _qi = _qi + 1;
    };
    let _score = _score + _matches * 100;
    
    // 2. Coverage: what fraction of query words matched
    if len(_qwords) > 0 {
        let _coverage = _matches * 100 / len(_qwords);
        let _score = _score + _coverage;
    };
    
    // 3. Length penalty: facts > 200 chars get penalized
    if len(_fact) > 200 {
        let _score = _score - (len(_fact) - 200) / 10;
    };
    
    // 4. Exact match bonus
    if _fact == _query { let _score = _score + 500; };
    
    return _score;
}

// Score using 5D molecular distance (lower distance = more relevant)
pub fn mol_relevance(_query_mol, _fact_mol) {
    let _dist = _kt_mol_dist(_query_mol, _fact_mol);
    // Invert: distance 0 = score 100, distance 50 = score 0
    let _score = 100 - _dist * 2;
    if _score < 0 { let _score = 0; };
    return _score;
}

// Combined relevance: text overlap + molecular distance
pub fn combined_relevance(_query, _fact, _query_mol, _fact_mol) {
    let _text_score = relevance_score(_query, _fact);
    let _mol_score = mol_relevance(_query_mol, _fact_mol);
    // Text match weighs more (70/30) because 5D is still coarse
    return _text_score * 7 + _mol_score * 3;
}

// ═══ RANKED SEARCH ═══

// Search KnowTree and return top K results ranked by relevance
pub fn ranked_search(_query, _k) {
    let _query_mol = _kt_real_mol(_query);
    
    // Collect candidates from multiple sources
    let _candidates = [];
    let _cand_scores = [];
    
    // Source 1: text search (word match)
    let _text_results = kt_find(_query, _k * 3);  // get 3x more for ranking
    let _ti = 0;
    while _ti < len(_text_results) {
        let _fact = __array_get(_text_results, _ti);
        push(_candidates, _fact);
        push(_cand_scores, relevance_score(_query, _fact));
        let _ti = _ti + 1;
    };
    
    // Source 2: molecular nearest (5D bucket search)
    let _mol_result = kt_nearest(_query_mol);
    if len(_mol_result) > 0 {
        // Check not duplicate
        let _dup = 0;
        let _ci = 0;
        while _ci < len(_candidates) {
            if __array_get(_candidates, _ci) == _mol_result { let _dup = 1; };
            let _ci = _ci + 1;
        };
        if _dup == 0 {
            push(_candidates, _mol_result);
            push(_cand_scores, mol_relevance(_query_mol, _kt_real_mol(_mol_result)));
        };
    };
    
    // Source 3: silk walk (associated facts)
    let _silk_results = kt_silk_walk(_query_mol, 2, 5);
    let _si = 0;
    while _si < len(_silk_results) {
        let _silk_mol = __array_get(_silk_results, _si);
        // Find fact for this mol
        let _fi = 0;
        while _fi < len(__kt_facts_mol) {
            if __array_get(__kt_facts_mol, _fi) == _silk_mol {
                let _fact = __array_get(__kt_facts, _fi);
                // Check not duplicate
                let _dup = 0;
                let _ci = 0;
                while _ci < len(_candidates) {
                    if __array_get(_candidates, _ci) == _fact { let _dup = 1; };
                    let _ci = _ci + 1;
                };
                if _dup == 0 {
                    push(_candidates, _fact);
                    // Silk walk results get bonus for associative connection
                    push(_cand_scores, relevance_score(_query, _fact) + 30);
                };
                let _fi = len(__kt_facts_mol);  // break
            };
            let _fi = _fi + 1;
        };
        let _si = _si + 1;
    };
    
    // Rank and return top K
    if len(_candidates) == 0 { return []; };
    return top_k(_candidates, _cand_scores, _k);
}

// ═══ DEDUPLICATION ═══

// Remove duplicate facts from array (exact match)
pub fn dedup(_facts) {
    let _result = [];
    let _i = 0;
    while _i < len(_facts) {
        let _fact = __array_get(_facts, _i);
        let _dup = 0;
        let _j = 0;
        while _j < len(_result) {
            if __array_get(_result, _j) == _fact { let _dup = 1; let _j = len(_result); };
            let _j = _j + 1;
        };
        if _dup == 0 { push(_result, _fact); };
        let _i = _i + 1;
    };
    return _result;
}

// Near-dedup: remove facts with >80% word overlap
pub fn dedup_fuzzy(_facts) {
    let _result = [];
    let _i = 0;
    while _i < len(_facts) {
        let _fact = __array_get(_facts, _i);
        let _dup = 0;
        let _j = 0;
        while _j < len(_result) {
            if _word_overlap(__array_get(_result, _j), _fact) > 80 {
                let _dup = 1; let _j = len(_result);
            };
            let _j = _j + 1;
        };
        if _dup == 0 { push(_result, _fact); };
        let _i = _i + 1;
    };
    return _result;
}

// ═══ HELPERS ═══

// Split text into words (by space), filter len >= 2
fn _split_to_words(_text) {
    let _words = [];
    let _start = 0;
    let _i = 0;
    while _i < len(_text) {
        if __char_code(char_at(_text, _i)) == 32 {
            if _i > _start {
                let _w = substr(_text, _start, _i);
                if len(_w) >= 2 { push(_words, _w); };
            };
            let _start = _i + 1;
        };
        let _i = _i + 1;
    };
    if _start < len(_text) {
        let _w = substr(_text, _start, len(_text));
        if len(_w) >= 2 { push(_words, _w); };
    };
    return _words;
}

// Find first occurrence of needle in haystack, return position or -1
fn _find_in(_hay, _needle) {
    let _hlen = len(_hay);
    let _nlen = len(_needle);
    if _nlen > _hlen { return -1; };
    let _i = 0;
    while _i <= _hlen - _nlen {
        let _match = 1;
        let _j = 0;
        while _j < _nlen {
            if char_at(_hay, _i + _j) != char_at(_needle, _j) {
                let _match = 0; let _j = _nlen;
            };
            let _j = _j + 1;
        };
        if _match == 1 { return _i; };
        let _i = _i + 1;
    };
    return -1;
}

// Word overlap percentage between two texts
fn _word_overlap(_a, _b) {
    let _wa = _split_to_words(_a);
    let _wb = _split_to_words(_b);
    if len(_wa) == 0 { return 0; };
    let _match = 0;
    let _i = 0;
    while _i < len(_wa) {
        let _word = __array_get(_wa, _i);
        let _j = 0;
        while _j < len(_wb) {
            if __array_get(_wb, _j) == _word { let _match = _match + 1; let _j = len(_wb); };
            let _j = _j + 1;
        };
        let _i = _i + 1;
    };
    return _match * 100 / len(_wa);
}
