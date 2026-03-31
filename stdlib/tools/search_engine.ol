// stdlib/tools/search_engine.ol — Relevance search. Pure Olang.

pub fn relevance_score(_query, _fact) {
    let _score = [0];
    let _qwords = _split_to_words(_query);
    let _matches = [0];
    let _qi = 0;
    while _qi < len(_qwords) {
        let _qw = __array_get(_qwords, _qi);
        if len(_qw) >= 2 {
            if _str_has(_fact, _qw) {
                let _ = __set_at(_matches, 0, __array_get(_matches, 0) + 1);
                let _pos = _find_in(_fact, _qw);
                if _pos >= 0 {
                    if _pos < 20 { let _ = __set_at(_score, 0, __array_get(_score, 0) + 50); };
                };
            };
        };
        let _qi = _qi + 1;
    };
    let _ = __set_at(_score, 0, __array_get(_score, 0) + __array_get(_matches, 0) * 100);
    if len(_qwords) > 0 {
        let _ = __set_at(_score, 0, __array_get(_score, 0) + __array_get(_matches, 0) * 100 / len(_qwords));
    };
    if len(_fact) > 200 {
        let _ = __set_at(_score, 0, __array_get(_score, 0) - (len(_fact) - 200) / 10);
    };
    return __array_get(_score, 0);
}

pub fn mol_relevance(_query_mol, _fact_mol) {
    let _dist = _kt_mol_dist(_query_mol, _fact_mol);
    let _score = 100 - _dist * 2;
    if _score < 0 { return 0; };
    return _score;
}

pub fn combined_relevance(_query, _fact, _query_mol, _fact_mol) {
    return relevance_score(_query, _fact) * 7 + mol_relevance(_query_mol, _fact_mol) * 3;
}

pub fn ranked_search(_query, _k) {
    let _query_mol = _kt_real_mol(_query);
    let _candidates = [];
    let _cand_scores = [];
    // Source 1: text search
    let _text_results = kt_find(_query, _k * 3);
    let _ti = 0;
    while _ti < len(_text_results) {
        let _fact = __array_get(_text_results, _ti);
        push(_candidates, _fact);
        push(_cand_scores, relevance_score(_query, _fact));
        let _ti = _ti + 1;
    };
    // Source 2: molecular nearest
    let _mol_result = kt_nearest(_query_mol);
    if len(_mol_result) > 0 {
        let _dup = [0];
        let _ci = 0;
        while _ci < len(_candidates) {
            if __array_get(_candidates, _ci) == _mol_result { let _ = __set_at(_dup, 0, 1); };
            let _ci = _ci + 1;
        };
        if __array_get(_dup, 0) == 0 {
            push(_candidates, _mol_result);
            push(_cand_scores, mol_relevance(_query_mol, _kt_real_mol(_mol_result)));
        };
    };
    // Sort by score descending, return top K
    return _top_k_by_score(_candidates, _cand_scores, _k);
}

pub fn respond(_query) {
    let _results = ranked_search(_query, 3);
    if len(_results) == 0 { return ""; };
    return __array_get(_results, 0);
}

pub fn _split_to_words(_text) {
    let _words = [];
    let _ws = [0];
    let _i = 0;
    while _i <= len(_text) {
        let _is_sp = 0;
        if _i == len(_text) { let _is_sp = 1; } else {
            let _ch = __char_code(char_at(_text, _i));
            if _ch == 32 { let _is_sp = 1; };
            if _ch == 63 { let _is_sp = 1; };
        };
        if _is_sp == 1 {
            let _s = __array_get(_ws, 0);
            if _i > _s { push(_words, substr(_text, _s, _i)); };
            let _ = __set_at(_ws, 0, _i + 1);
        };
        let _i = _i + 1;
    };
    return _words;
}

pub fn _find_in(_hay, _needle) {
    let _hlen = len(_hay);
    let _nlen = len(_needle);
    if _nlen > _hlen { return 0 - 1; };
    let _i = 0;
    while _i <= _hlen - _nlen {
        let _match = [1];
        let _j = 0;
        while _j < _nlen {
            if char_at(_hay, _i + _j) != char_at(_needle, _j) {
                let _ = __set_at(_match, 0, 0); let _j = _nlen;
            };
            let _j = _j + 1;
        };
        if __array_get(_match, 0) == 1 { return _i; };
        let _i = _i + 1;
    };
    return 0 - 1;
}

pub fn _top_k_by_score(_items, _scores, _k) {
    let _result = [];
    let _used = [];
    let _ri = 0;
    while _ri < len(_scores) { push(_used, 0); let _ri = _ri + 1; };
    let _picked = [0];
    while __array_get(_picked, 0) < _k {
        if __array_get(_picked, 0) >= len(_items) { return _result; };
        let _best_i = [0 - 1];
        let _best_s = [0 - 1];
        let _si = 0;
        while _si < len(_scores) {
            if __array_get(_used, _si) == 0 {
                if __array_get(_scores, _si) > __array_get(_best_s, 0) {
                    let _ = __set_at(_best_s, 0, __array_get(_scores, _si));
                    let _ = __set_at(_best_i, 0, _si);
                };
            };
            let _si = _si + 1;
        };
        let _bi = __array_get(_best_i, 0);
        if _bi < 0 { return _result; };
        push(_result, __array_get(_items, _bi));
        let _ = __set_at(_used, _bi, 1);
        let _ = __set_at(_picked, 0, __array_get(_picked, 0) + 1);
    };
    return _result;
}

pub fn dedup(_facts) {
    let _out = [];
    let _i = 0;
    while _i < len(_facts) {
        let _f = __array_get(_facts, _i);
        let _dup = [0];
        let _j = 0;
        while _j < len(_out) {
            if __array_get(_out, _j) == _f { let _ = __set_at(_dup, 0, 1); };
            let _j = _j + 1;
        };
        if __array_get(_dup, 0) == 0 { push(_out, _f); };
        let _i = _i + 1;
    };
    return _out;
}
