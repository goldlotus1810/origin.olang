// stdlib/regex.ol — NFA regex engine (Thompson's construction)
// Supports: . * + ? [] [^] () | \d \w \s
// State passed as mutable array to avoid global mutation issues.

// State array: s[0]=count, s[1..]=flat state data (4 per state: type,ch,out1,out2)
// Types: 0=lit, 1=dot, 2=split, 3=match, 4=class, 5=nclass
// Fragment encoding: start*100000 + end

fn _rx_ns(s, t, c, o1, o2) {
    let _id = s[0];
    push(s, t); push(s, c); push(s, o1); push(s, o2);
    set_at(s, 0, _id + 1);
    return _id;
}
fn _rx_t(s, id) { return s[1 + id*4]; }
fn _rx_c(s, id) { return s[1 + id*4+1]; }
fn _rx_o1(s, id) { return s[1 + id*4+2]; }
fn _rx_o2(s, id) { return s[1 + id*4+3]; }
fn _rx_so1(s, id, v) { set_at(s, 1 + id*4+2, v); }
fn _rx_so2(s, id, v) { set_at(s, 1 + id*4+3, v); }

fn _rx_fs(f) { return __floor(f / 100000); }
fn _rx_fe(f) { return f - __floor(f / 100000) * 100000; }

// Parse atom
fn _rx_pa(s, p, pi) {
    if pi[0] >= len(p) { return -1; };
    let _c = char_at(p, pi[0]);
    if _c == ")" || _c == "|" { return -1; };
    if _c == "(" {
        set_at(pi, 0, pi[0]+1);
        let _f = _rx_pl(s, p, pi);
        if pi[0] < len(p) { if char_at(p, pi[0]) == ")" { set_at(pi, 0, pi[0]+1); }; };
        return _f;
    };
    if _c == "[" {
        set_at(pi, 0, pi[0]+1);
        let _neg = 0;
        if pi[0] < len(p) { if char_at(p, pi[0]) == "^" { let _neg = 1; set_at(pi, 0, pi[0]+1); }; };
        let _chars = "";
        while pi[0] < len(p) {
            if char_at(p, pi[0]) == "]" { break; };
            let _cc = char_at(p, pi[0]); set_at(pi, 0, pi[0]+1);
            if pi[0] < len(p) { if char_at(p, pi[0]) == "-" {
                set_at(pi, 0, pi[0]+1);
                if pi[0] < len(p) {
                    let _e = char_at(p, pi[0]); set_at(pi, 0, pi[0]+1);
                    let _f = __char_code(_cc); let _t = __char_code(_e);
                    while _f <= _t { _chars = _chars + __chr(_f); let _f = _f + 1; };
                    continue;
                };
            }; };
            _chars = _chars + _cc;
        };
        if pi[0] < len(p) { set_at(pi, 0, pi[0]+1); }; // skip ]
        let _tp = 4; if _neg == 1 { let _tp = 5; };
        let _id = _rx_ns(s, _tp, _chars, -1, -1);
        return _id * 100000 + _id;
    };
    if _c == "." { set_at(pi, 0, pi[0]+1); let _id = _rx_ns(s, 1, "", -1, -1); return _id*100000+_id; };
    if _c == "\\" {
        set_at(pi, 0, pi[0]+1);
        if pi[0] < len(p) {
            let _ec = char_at(p, pi[0]); set_at(pi, 0, pi[0]+1);
            if _ec == "d" { let _id = _rx_ns(s, 4, "0123456789", -1, -1); return _id*100000+_id; };
            if _ec == "w" { let _id = _rx_ns(s, 4, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_", -1, -1); return _id*100000+_id; };
            if _ec == "s" { let _id = _rx_ns(s, 4, " ", -1, -1); return _id*100000+_id; };
            let _id = _rx_ns(s, 0, _ec, -1, -1); return _id*100000+_id;
        };
        return -1;
    };
    set_at(pi, 0, pi[0]+1);
    let _id = _rx_ns(s, 0, _c, -1, -1);
    return _id*100000+_id;
}

// Parse quantifier: atom followed by * + ?
fn _rx_pq(s, p, pi) {
    let _f = _rx_pa(s, p, pi);
    if _f == -1 { return -1; };
    if pi[0] >= len(p) { return _f; };
    let _q = char_at(p, pi[0]);
    let _fs = _rx_fs(_f); let _fe = _rx_fe(_f);
    if _q == "*" { set_at(pi, 0, pi[0]+1);
        let _sp = _rx_ns(s, 2, "", _fs, -1);
        _rx_so1(s, _fe, _sp);
        return _sp*100000+_sp;
    };
    if _q == "+" { set_at(pi, 0, pi[0]+1);
        let _sp = _rx_ns(s, 2, "", _fs, -1);
        _rx_so1(s, _fe, _sp);
        return _fs*100000+_sp;
    };
    if _q == "?" { set_at(pi, 0, pi[0]+1);
        let _sp = _rx_ns(s, 2, "", _fs, -1);
        return _sp*100000+_fe;
    };
    return _f;
}

// Parse concatenation
fn _rx_pc(s, p, pi) {
    let _f = _rx_pq(s, p, pi);
    if _f == -1 { return -1; };
    let _fs = _rx_fs(_f); let _fe = _rx_fe(_f);
    while pi[0] < len(p) {
        let _ch = char_at(p, pi[0]);
        if _ch == ")" || _ch == "|" { break; };
        let _nf = _rx_pq(s, p, pi);
        if _nf == -1 { break; };
        let _ns = _rx_fs(_nf); let _ne = _rx_fe(_nf);
        if _rx_o1(s, _fe) == -1 { _rx_so1(s, _fe, _ns); } else { _rx_so2(s, _fe, _ns); };
        let _fe = _ne;
    };
    return _fs*100000+_fe;
}

// Parse alternation
fn _rx_pl(s, p, pi) {
    let _f = _rx_pc(s, p, pi);
    if _f == -1 { return -1; };
    let _fs = _rx_fs(_f); let _fe = _rx_fe(_f);
    while pi[0] < len(p) {
        if char_at(p, pi[0]) != "|" { break; };
        set_at(pi, 0, pi[0]+1);
        let _rf = _rx_pc(s, p, pi);
        if _rf == -1 { break; };
        let _rs = _rx_fs(_rf); let _re = _rx_fe(_rf);
        let _sp = _rx_ns(s, 2, "", _fs, _rs);
        let _mg = _rx_ns(s, 2, "", -1, -1);
        if _rx_o1(s, _fe) == -1 { _rx_so1(s, _fe, _mg); } else { _rx_so2(s, _fe, _mg); };
        if _rx_o1(s, _re) == -1 { _rx_so1(s, _re, _mg); } else { _rx_so2(s, _re, _mg); };
        let _fs = _sp; let _fe = _mg;
    };
    return _fs*100000+_fe;
}

fn _rx_compile(pat) {
    let _s = [0]; // state array: [count, ...data]
    let _pi = [0]; // position as mutable ref
    let _f = _rx_pl(_s, pat, _pi);
    if _f == -1 { _rx_ns(_s, 3, "", -1, -1); return _s; };
    let _m = _rx_ns(_s, 3, "", -1, -1);
    let _fe = _rx_fe(_f);
    if _rx_o1(_s, _fe) == -1 { _rx_so1(_s, _fe, _m); } else { _rx_so2(_s, _fe, _m); };
    // Store start state at the returned array (use _f's start)
    push(_s, _rx_fs(_f)); // last element = start state
    return _s;
}

// ═══════════════════════════════════════════════════════════════
// NFA Simulation
// ═══════════════════════════════════════════════════════════════

fn _rx_incls(ch, cls) {
    let _i = 0;
    while _i < len(cls) { if char_at(cls, _i) == ch { return 1; }; let _i = _i + 1; };
    return 0;
}

fn _rx_addst(s, set, seen, sid, n) {
    let _stk = [sid];
    while len(_stk) > 0 {
        let _cur = pop(_stk);
        if _cur < 0 { continue; };
        if _cur >= n { continue; };
        if seen[_cur] == 1 { continue; };
        set_at(seen, _cur, 1);
        if _rx_t(s, _cur) == 2 {
            push(_stk, _rx_o1(s, _cur));
            push(_stk, _rx_o2(s, _cur));
        } else {
            push(set, _cur);
        };
    };
}

fn _rx_sim(s, start, text, from) {
    let _n = s[0];
    let _cur = [];
    let _seen = [];
    let _i = 0; while _i < _n { push(_seen, 0); let _i = _i + 1; };
    _rx_addst(s, _cur, _seen, start, _n);
    let _ti = from;
    let _tlen = len(text);
    let _matched = -1;
    let _ci = 0;
    while _ci < len(_cur) { if _rx_t(s, _cur[_ci]) == 3 { let _matched = _ti; }; let _ci = _ci + 1; };
    while _ti < _tlen {
        if len(_cur) == 0 { return _matched; };
        let _ch = char_at(text, _ti);
        let _next = [];
        let _nseen = [];
        let _ni = 0; while _ni < _n { push(_nseen, 0); let _ni = _ni + 1; };
        let _j = 0;
        while _j < len(_cur) {
            let _sid = _cur[_j];
            let _tp = _rx_t(s, _sid);
            let _ok = 0;
            if _tp == 0 { if _rx_c(s, _sid) == _ch { let _ok = 1; }; };
            if _tp == 1 { let _ok = 1; };
            if _tp == 4 { if _rx_incls(_ch, _rx_c(s, _sid)) == 1 { let _ok = 1; }; };
            if _tp == 5 { if _rx_incls(_ch, _rx_c(s, _sid)) == 0 { let _ok = 1; }; };
            if _ok == 1 { _rx_addst(s, _next, _nseen, _rx_o1(s, _sid), _n); };
            let _j = _j + 1;
        };
        let _cur = _next;
        let _ti = _ti + 1;
        let _ci = 0;
        while _ci < len(_cur) { if _rx_t(s, _cur[_ci]) == 3 { let _matched = _ti; }; let _ci = _ci + 1; };
    };
    return _matched;
}

// ═══════════════════════════════════════════════════════════════
// Public API
// ═══════════════════════════════════════════════════════════════

pub fn regex_match(text, pattern) {
    let _s = _rx_compile(pattern);
    let _start = _s[len(_s)-1]; // start state stored at end
    let _end = _rx_sim(_s, _start, text, 0);
    if _end == len(text) { return 1; };
    return 0;
}

pub fn regex_search(text, pattern) {
    let _s = _rx_compile(pattern);
    let _start = _s[len(_s)-1];
    let _i = 0;
    while _i < len(text) {
        let _end = _rx_sim(_s, _start, text, _i);
        if _end >= 0 { return {start: _i, end: _end}; };
        let _i = _i + 1;
    };
    return -1;
}

pub fn regex_test(text, pattern) {
    if regex_search(text, pattern) == -1 { return 0; };
    return 1;
}
