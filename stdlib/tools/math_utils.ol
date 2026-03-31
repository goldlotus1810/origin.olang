// stdlib/tools/math_utils.ol — Math, sorting, ranking, statistics
// LLM: ranks results by score. Nox: returns first match. This fixes that.

// ═══ SORTING ═══

// Sort array of numbers (ascending, insertion sort — fine for <10K)
pub fn sort_asc(_arr) {
    let _n = len(_arr);
    let _i = 1;
    while _i < _n {
        let _key = __array_get(_arr, _i);
        let _j = _i - 1;
        while _j >= 0 {
            if __array_get(_arr, _j) > _key {
                set_at(_arr, _j + 1, __array_get(_arr, _j));
                let _j = _j - 1;
            } else { let _j = -1; };  // break
        };
        set_at(_arr, _j + 1, _key);
        let _i = _i + 1;
    };
    return _arr;
}

// Sort descending
pub fn sort_desc(_arr) {
    let _n = len(_arr);
    let _i = 1;
    while _i < _n {
        let _key = __array_get(_arr, _i);
        let _j = _i - 1;
        while _j >= 0 {
            if __array_get(_arr, _j) < _key {
                set_at(_arr, _j + 1, __array_get(_arr, _j));
                let _j = _j - 1;
            } else { let _j = -1; };
        };
        set_at(_arr, _j + 1, _key);
        let _i = _i + 1;
    };
    return _arr;
}

// Sort parallel arrays by scores: reorder _items same as _scores
// Returns sorted items (highest score first)
pub fn sort_by_score(_items, _scores) {
    let _n = len(_scores);
    if _n == 0 { return []; };
    // Build index array
    let _idx = [];
    let _i = 0;
    while _i < _n { push(_idx, _i); let _i = _i + 1; };
    // Sort indices by score (descending)
    let _i = 1;
    while _i < _n {
        let _key_idx = __array_get(_idx, _i);
        let _key_score = __array_get(_scores, _key_idx);
        let _j = _i - 1;
        while _j >= 0 {
            let _j_idx = __array_get(_idx, _j);
            if __array_get(_scores, _j_idx) < _key_score {
                set_at(_idx, _j + 1, _j_idx);
                let _j = _j - 1;
            } else { let _j = -1; };
        };
        set_at(_idx, _j + 1, _key_idx);
        let _i = _i + 1;
    };
    // Build sorted result
    let _result = [];
    let _i = 0;
    while _i < _n {
        push(_result, __array_get(_items, __array_get(_idx, _i)));
        let _i = _i + 1;
    };
    return _result;
}

// Top-K: return K highest scoring items
pub fn top_k(_items, _scores, _k) {
    let _sorted = sort_by_score(_items, _scores);
    let _result = [];
    let _i = 0;
    while _i < _k {
        if _i >= len(_sorted) { return _result; };
        push(_result, __array_get(_sorted, _i));
        let _i = _i + 1;
    };
    return _result;
}

// ═══ STATISTICS ═══

pub fn arr_sum(_arr) {
    let _s = 0;
    let _i = 0;
    while _i < len(_arr) { let _s = _s + __array_get(_arr, _i); let _i = _i + 1; };
    return _s;
}

pub fn arr_mean(_arr) {
    if len(_arr) == 0 { return 0; };
    return arr_sum(_arr) / len(_arr);
}

pub fn arr_min(_arr) {
    if len(_arr) == 0 { return 0; };
    let _m = __array_get(_arr, 0);
    let _i = 1;
    while _i < len(_arr) {
        let _v = __array_get(_arr, _i);
        if _v < _m { let _m = _v; };
        let _i = _i + 1;
    };
    return _m;
}

pub fn arr_max(_arr) {
    if len(_arr) == 0 { return 0; };
    let _m = __array_get(_arr, 0);
    let _i = 1;
    while _i < len(_arr) {
        let _v = __array_get(_arr, _i);
        if _v > _m { let _m = _v; };
        let _i = _i + 1;
    };
    return _m;
}

pub fn arr_variance(_arr) {
    if len(_arr) < 2 { return 0; };
    let _mean = arr_mean(_arr);
    let _sum = 0;
    let _i = 0;
    while _i < len(_arr) {
        let _d = __array_get(_arr, _i) - _mean;
        let _sum = _sum + _d * _d;
        let _i = _i + 1;
    };
    return _sum / (len(_arr) - 1);
}

pub fn arr_stddev(_arr) {
    return __sqrt(arr_variance(_arr));
}

// Histogram: count values in N bins between min..max
pub fn histogram(_arr, _bins) {
    if len(_arr) == 0 { return []; };
    let _lo = arr_min(_arr);
    let _hi = arr_max(_arr);
    if _hi == _lo { let _hi = _lo + 1; };
    let _step = (_hi - _lo) / _bins;
    let _counts = [];
    let _i = 0;
    while _i < _bins { push(_counts, 0); let _i = _i + 1; };
    let _i = 0;
    while _i < len(_arr) {
        let _v = __array_get(_arr, _i);
        let _bin = __floor((_v - _lo) / _step);
        if _bin >= _bins { let _bin = _bins - 1; };
        if _bin < 0 { let _bin = 0; };
        set_at(_counts, _bin, __array_get(_counts, _bin) + 1);
        let _i = _i + 1;
    };
    return _counts;
}

// ═══ MATH HELPERS ═══

pub fn clamp(_v, _lo, _hi) {
    if _v < _lo { return _lo; };
    if _v > _hi { return _hi; };
    return _v;
}

pub fn lerp(_a, _b, _t) {
    return _a + (_b - _a) * _t;
}

pub fn map_range(_v, _from_lo, _from_hi, _to_lo, _to_hi) {
    if _from_hi == _from_lo { return _to_lo; };
    let _t = (_v - _from_lo) / (_from_hi - _from_lo);
    return lerp(_to_lo, _to_hi, _t);
}

// φ⁻¹ = 0.618... (golden ratio inverse — HomeOS sole threshold)
pub fn phi_inv() { return 0.6180339887; }

// Exponential decay: value × φ⁻¹^(dt/period)
pub fn decay(_value, _dt, _period) {
    if _period <= 0 { return 0; };
    let _steps = _dt / _period;
    let _factor = 1;
    let _i = 0;
    while _i < __floor(_steps) {
        let _factor = _factor * phi_inv();
        let _i = _i + 1;
    };
    // Fractional step
    let _frac = _steps - __floor(_steps);
    if _frac > 0 {
        let _factor = _factor * (1 - _frac * (1 - phi_inv()));
    };
    return _value * _factor;
}

// Normalize array to 0..1 range
pub fn normalize(_arr) {
    if len(_arr) == 0 { return []; };
    let _lo = arr_min(_arr);
    let _hi = arr_max(_arr);
    if _hi == _lo { let _hi = _lo + 1; };
    let _result = [];
    let _i = 0;
    while _i < len(_arr) {
        push(_result, (__array_get(_arr, _i) - _lo) / (_hi - _lo));
        let _i = _i + 1;
    };
    return _result;
}

// Softmax-like: convert scores to weights summing to 1
pub fn softweights(_arr) {
    if len(_arr) == 0 { return []; };
    let _total = 0;
    let _i = 0;
    while _i < len(_arr) {
        let _v = __array_get(_arr, _i);
        if _v < 0 { let _v = 0; };
        let _total = _total + _v;
        let _i = _i + 1;
    };
    if _total == 0 { let _total = 1; };
    let _result = [];
    let _i = 0;
    while _i < len(_arr) {
        let _v = __array_get(_arr, _i);
        if _v < 0 { let _v = 0; };
        push(_result, _v / _total);
        let _i = _i + 1;
    };
    return _result;
}
