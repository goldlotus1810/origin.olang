// stdlib/regex.ol — Regex engine (simplified, minimal call depth)
// Supports: . * + ? [chars] [^chars] () | \d \w \s
// API: regex_match(text, pattern), regex_test(text, pattern), regex_search(text, pattern)

// Helper: advance pi and update state count (isolates set_at from caller vars)
fn _rx_advance_pi(_ap_s, _ap_pi, _ap_id) {
    set_at(_ap_s, 0, _ap_id + 1);
    set_at(_ap_pi, 0, _ap_pi[0] + 1);
}

// Build NFA in a flat array: [count, type0,ch0,out1_0,out2_0, type1,...]
// Types: 0=lit, 1=dot, 2=split, 3=match, 4=class, 5=nclass

pub fn regex_match(_rm_text, _rm_pat) {
    let _s = [0];   // state array
    let _pi = [0];  // pattern position

    // ── COMPILE: pattern → NFA ──
    let _start = _rx_build(_s, _rm_pat, _pi);

    // ── SIMULATE: NFA on text ──
    let _end = _rx_run(_s, _start, _rm_text, 0);
    if _end == len(_rm_text) { return 1; };
    return 0;
}

pub fn regex_test(_rt_text, _rt_pat) {
    let _s = [0];
    let _pi = [0];
    let _start = _rx_build(_s, _rt_pat, _pi);
    let _i = 0;
    while _i < len(_rt_text) {
        let _end = _rx_run(_s, _start, _rt_text, _i);
        if _end >= 0 { return 1; };
        let _i = _i + 1;
    };
    return 0;
}

pub fn regex_search(_rs_text, _rs_pat) {
    let _s = [0];
    let _pi = [0];
    let _start = _rx_build(_s, _rs_pat, _pi);
    let _i = 0;
    while _i < len(_rs_text) {
        let _end = _rx_run(_s, _start, _rs_text, _i);
        if _end >= 0 { return {start: _i, end: _end}; };
        let _i = _i + 1;
    };
    return -1;
}

// ═══════════════════════════════════════════════════════════════
// NFA Builder — single function, no deep call chains
// ═══════════════════════════════════════════════════════════════

fn _rx_build(_b_s, _b_pat, _b_pi) {
    // Parse and build NFA in one pass
    let _b_frag = _rx_expr(_b_s, _b_pat, _b_pi);
    if _b_frag < 0 {
        // Empty pattern → match anything
        let _b_m = _b_s[0];
        let _ = __array_push(_b_s, 3); let _ = __array_push(_b_s, ""); let _ = __array_push(_b_s, -1); let _ = __array_push(_b_s, -1);
        set_at(_b_s, 0, _b_m + 1);
        return _b_m;
    };
    // Add match state
    let _b_m = _b_s[0];
    let _ = __array_push(_b_s, 3); let _ = __array_push(_b_s, ""); let _ = __array_push(_b_s, -1); let _ = __array_push(_b_s, -1);
    set_at(_b_s, 0, _b_m + 1);
    // Patch fragment end → match
    let _b_fe = _b_frag - __floor(_b_frag / 100000) * 100000;
    if _b_s[1 + _b_fe*4 + 2] == -1 { set_at(_b_s, 1 + _b_fe*4 + 2, _b_m); }
    else { set_at(_b_s, 1 + _b_fe*4 + 3, _b_m); };
    return __floor(_b_frag / 100000);
}

// Parse alternation: concat | concat | ...
fn _rx_expr(_e_s, _e_p, _e_pi) {
    let _e_f = _rx_seq(_e_s, _e_p, _e_pi);
    if _e_f < 0 { return -1; };
    while _e_pi[0] < len(_e_p) {
        if char_at(_e_p, _e_pi[0]) != "|" { return _e_f; };
        set_at(_e_pi, 0, _e_pi[0] + 1);
        let _e_rf = _rx_seq(_e_s, _e_p, _e_pi);
        if _e_rf < 0 { return _e_f; };
        // Split node
        let _e_fs = __floor(_e_f / 100000);
        let _e_fe = _e_f - _e_fs * 100000;
        let _e_rs = __floor(_e_rf / 100000);
        let _e_re = _e_rf - _e_rs * 100000;
        let _e_sp = _e_s[0];
        let _ = __array_push(_e_s, 2); let _ = __array_push(_e_s, ""); let _ = __array_push(_e_s, _e_fs); let _ = __array_push(_e_s, _e_rs);
        set_at(_e_s, 0, _e_sp + 1);
        let _e_mg = _e_s[0];
        let _ = __array_push(_e_s, 2); let _ = __array_push(_e_s, ""); let _ = __array_push(_e_s, -1); let _ = __array_push(_e_s, -1);
        set_at(_e_s, 0, _e_mg + 1);
        if _e_s[1+_e_fe*4+2] == -1 { set_at(_e_s, 1+_e_fe*4+2, _e_mg); } else { set_at(_e_s, 1+_e_fe*4+3, _e_mg); };
        if _e_s[1+_e_re*4+2] == -1 { set_at(_e_s, 1+_e_re*4+2, _e_mg); } else { set_at(_e_s, 1+_e_re*4+3, _e_mg); };
        let _e_f = _e_sp * 100000 + _e_mg;
    };
    return _e_f;
}

// Parse concatenation: quant quant ...
fn _rx_seq(_q_s, _q_p, _q_pi) {
    let _q_f = _rx_atom_q(_q_s, _q_p, _q_pi);
    if _q_f < 0 { return -1; };
    while _q_pi[0] < len(_q_p) {
        let _q_ch = char_at(_q_p, _q_pi[0]);
        if _q_ch == ")" { return _q_f; };
        if _q_ch == "|" { return _q_f; };
        let _q_nf = _rx_atom_q(_q_s, _q_p, _q_pi);
        if _q_nf < 0 { return _q_f; };
        let _q_fs = __floor(_q_f / 100000);
        let _q_fe = _q_f - _q_fs * 100000;
        let _q_ns = __floor(_q_nf / 100000);
        let _q_ne = _q_nf - _q_ns * 100000;
        if _q_s[1+_q_fe*4+2] == -1 { set_at(_q_s, 1+_q_fe*4+2, _q_ns); }
        else { set_at(_q_s, 1+_q_fe*4+3, _q_ns); };
        let _q_f = _q_fs * 100000 + _q_ne;
    };
    return _q_f;
}

// Parse atom + optional quantifier (*, +, ?)
fn _rx_atom_q(_a_s, _a_p, _a_pi) {
    if _a_pi[0] >= len(_a_p) { return -1; };
    let _a_ch = char_at(_a_p, _a_pi[0]);

    // Skip meta chars
    if _a_ch == ")" { return -1; };
    if _a_ch == "|" { return -1; };

    // Group
    if _a_ch == "(" {
        set_at(_a_pi, 0, _a_pi[0] + 1);
        let _a_f = _rx_expr(_a_s, _a_p, _a_pi);
        if _a_pi[0] < len(_a_p) { if char_at(_a_p, _a_pi[0]) == ")" { set_at(_a_pi, 0, _a_pi[0]+1); }; };
        return _rx_quant(_a_s, _a_p, _a_pi, _a_f);
    };

    // Character class [...]
    if _a_ch == "[" {
        set_at(_a_pi, 0, _a_pi[0] + 1);
        let _a_neg = 0;
        if _a_pi[0] < len(_a_p) { if char_at(_a_p, _a_pi[0]) == "^" { let _a_neg = 1; set_at(_a_pi, 0, _a_pi[0]+1); }; };
        let _a_chars = "";
        while _a_pi[0] < len(_a_p) {
            if char_at(_a_p, _a_pi[0]) == "]" { break; };
            let _a_cc = char_at(_a_p, _a_pi[0]); set_at(_a_pi, 0, _a_pi[0]+1);
            if _a_pi[0] < len(_a_p) { if char_at(_a_p, _a_pi[0]) == "-" {
                set_at(_a_pi, 0, _a_pi[0]+1);
                if _a_pi[0] < len(_a_p) {
                    let _a_e = char_at(_a_p, _a_pi[0]); set_at(_a_pi, 0, _a_pi[0]+1);
                    let _a_from = __char_code(_a_cc); let _a_to = __char_code(_a_e);
                    while _a_from <= _a_to { _a_chars = _a_chars + __chr(_a_from); _a_from = _a_from + 1; };
                    continue;
                };
            }; };
            _a_chars = _a_chars + _a_cc;
        };
        if _a_pi[0] < len(_a_p) { set_at(_a_pi, 0, _a_pi[0]+1); }; // skip ]
        let _a_tp = 4; if _a_neg == 1 { let _a_tp = 5; };
        let _a_id = _a_s[0];
        let _ = __array_push(_a_s, _a_tp); let _ = __array_push(_a_s, _a_chars); let _ = __array_push(_a_s, -1); let _ = __array_push(_a_s, -1);
        set_at(_a_s, 0, _a_id + 1);
        return _rx_quant(_a_s, _a_p, _a_pi, _a_id * 100000 + _a_id);
    };

    // Dot
    if _a_ch == "." {
        set_at(_a_pi, 0, _a_pi[0]+1);
        let _a_id = _a_s[0];
        let _ = __array_push(_a_s, 1); let _ = __array_push(_a_s, ""); let _ = __array_push(_a_s, -1); let _ = __array_push(_a_s, -1);
        set_at(_a_s, 0, _a_id + 1);
        return _rx_quant(_a_s, _a_p, _a_pi, _a_id * 100000 + _a_id);
    };

    // Escape
    if _a_ch == "\\" {
        set_at(_a_pi, 0, _a_pi[0]+1);
        if _a_pi[0] < len(_a_p) {
            let _a_ec = char_at(_a_p, _a_pi[0]); set_at(_a_pi, 0, _a_pi[0]+1);
            let _a_id = _a_s[0];
            if _a_ec == "d" { let _ = __array_push(_a_s, 4); let _ = __array_push(_a_s, "0123456789"); }
            else { if _a_ec == "w" { let _ = __array_push(_a_s, 4); let _ = __array_push(_a_s, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"); }
            else { if _a_ec == "s" { let _ = __array_push(_a_s, 4); let _ = __array_push(_a_s, " "); }
            else { let _ = __array_push(_a_s, 0); let _ = __array_push(_a_s, _a_ec); }; }; };
            let _ = __array_push(_a_s, -1); let _ = __array_push(_a_s, -1);
            set_at(_a_s, 0, _a_id + 1);
            return _rx_quant(_a_s, _a_p, _a_pi, _a_id * 100000 + _a_id);
        };
        return -1;
    };

    // Literal character — advance pi via separate function to avoid var corruption
    let _a_id = _a_s[0];
    let _ = __array_push(_a_s, 0); let _ = __array_push(_a_s, _a_ch); let _ = __array_push(_a_s, -1); let _ = __array_push(_a_s, -1);
    _rx_advance_pi(_a_s, _a_pi, _a_id);
    return _rx_quant(_a_s, _a_p, _a_pi, _a_id * 100000 + _a_id);
}

// Apply quantifier (*, +, ?) to fragment
fn _rx_quant(_rq_s, _rq_p, _rq_pi, _rq_f) {
    if _rq_pi[0] >= len(_rq_p) { return _rq_f; };
    let _rq_q = char_at(_rq_p, _rq_pi[0]);
    let _rq_fs = __floor(_rq_f / 100000);
    let _rq_fe = _rq_f - _rq_fs * 100000;
    if _rq_q == "*" {
        set_at(_rq_pi, 0, _rq_pi[0]+1);
        let _rq_sp = _rq_s[0];
        let _ = __array_push(_rq_s, 2); let _ = __array_push(_rq_s, ""); let _ = __array_push(_rq_s, _rq_fs); let _ = __array_push(_rq_s, -1);
        set_at(_rq_s, 0, _rq_sp + 1);
        set_at(_rq_s, 1+_rq_fe*4+2, _rq_sp);
        return _rq_sp * 100000 + _rq_sp;
    };
    if _rq_q == "+" {
        set_at(_rq_pi, 0, _rq_pi[0]+1);
        let _rq_sp = _rq_s[0];
        let _ = __array_push(_rq_s, 2); let _ = __array_push(_rq_s, ""); let _ = __array_push(_rq_s, _rq_fs); let _ = __array_push(_rq_s, -1);
        set_at(_rq_s, 0, _rq_sp + 1);
        set_at(_rq_s, 1+_rq_fe*4+2, _rq_sp);
        return _rq_fs * 100000 + _rq_sp;
    };
    if _rq_q == "?" {
        set_at(_rq_pi, 0, _rq_pi[0]+1);
        let _rq_sp = _rq_s[0];
        let _ = __array_push(_rq_s, 2); let _ = __array_push(_rq_s, ""); let _ = __array_push(_rq_s, _rq_fs); let _ = __array_push(_rq_s, -1);
        set_at(_rq_s, 0, _rq_sp + 1);
        return _rq_sp * 100000 + _rq_fe;
    };
    return _rq_f;
}

// ═══════════════════════════════════════════════════════════════
// NFA Simulation
// ═══════════════════════════════════════════════════════════════

fn _rx_run(_r_s, _r_start, _r_text, _r_from) {
    let _r_n = _r_s[0];
    if _r_n == 0 { return -1; };
    let _r_cur = [];
    let _r_seen = [];
    let _r_i = 0; while _r_i < _r_n { let _ = __array_push(_r_seen, 0); _r_i = _r_i + 1; };
    // Add start state (follow epsilon/split transitions)
    let _r_stk = [_r_start];
    while len(_r_stk) > 0 {
        let _r_sid = __array_pop(_r_stk);
        if _r_sid >= 0 { if _r_sid < _r_n { if _r_seen[_r_sid] == 0 {
            set_at(_r_seen, _r_sid, 1);
            if _r_s[1+_r_sid*4] == 2 { // split
                let _ = __array_push(_r_stk, _r_s[1+_r_sid*4+2]);
                let _ = __array_push(_r_stk, _r_s[1+_r_sid*4+3]);
            } else {
                let _ = __array_push(_r_cur, _r_sid);
            };
        }; }; };
    };
    let _r_ti = _r_from;
    let _r_tlen = len(_r_text);
    let _r_matched = -1;
    // Check for match in initial set
    let _r_ci = 0;
    while _r_ci < len(_r_cur) { if _r_s[1+_r_cur[_r_ci]*4] == 3 { _r_matched = _r_ti; }; _r_ci = _r_ci + 1; };
    // Process each character
    while _r_ti < _r_tlen {
        if len(_r_cur) == 0 { return _r_matched; };
        let _r_ch = char_at(_r_text, _r_ti);
        let _r_next = [];
        let _r_nseen = [];
        let _r_ni = 0; while _r_ni < _r_n { let _ = __array_push(_r_nseen, 0); _r_ni = _r_ni + 1; };
        let _r_j = 0;
        while _r_j < len(_r_cur) {
            let _r_sid = _r_cur[_r_j];
            let _r_tp = _r_s[1+_r_sid*4];
            let _r_ok = 0;
            if _r_tp == 0 { if _r_s[1+_r_sid*4+1] == _r_ch { _r_ok = 1; }; }; // lit
            if _r_tp == 1 { _r_ok = 1; }; // dot
            if _r_tp == 4 { // class
                let _r_cls = _r_s[1+_r_sid*4+1]; let _r_ki = 0;
                while _r_ki < len(_r_cls) { if char_at(_r_cls, _r_ki) == _r_ch { _r_ok = 1; }; _r_ki = _r_ki + 1; };
            };
            if _r_tp == 5 { // nclass
                _r_ok = 1; let _r_cls = _r_s[1+_r_sid*4+1]; let _r_ki = 0;
                while _r_ki < len(_r_cls) { if char_at(_r_cls, _r_ki) == _r_ch { _r_ok = 0; }; _r_ki = _r_ki + 1; };
            };
            if _r_ok == 1 {
                // Add next state (follow epsilon)
                let _r_nxt = _r_s[1+_r_sid*4+2];
                let _r_stk2 = [_r_nxt];
                while len(_r_stk2) > 0 {
                    let _r_ns = __array_pop(_r_stk2);
                    if _r_ns >= 0 { if _r_ns < _r_n { if _r_nseen[_r_ns] == 0 {
                        set_at(_r_nseen, _r_ns, 1);
                        if _r_s[1+_r_ns*4] == 2 {
                            let _ = __array_push(_r_stk2, _r_s[1+_r_ns*4+2]);
                            let _ = __array_push(_r_stk2, _r_s[1+_r_ns*4+3]);
                        } else {
                            let _ = __array_push(_r_next, _r_ns);
                        };
                    }; }; };
                };
            };
            _r_j = _r_j + 1;
        };
        _r_cur = _r_next;
        _r_ti = _r_ti + 1;
        _r_ci = 0;
        while _r_ci < len(_r_cur) { if _r_s[1+_r_cur[_r_ci]*4] == 3 { _r_matched = _r_ti; }; _r_ci = _r_ci + 1; };
    };
    return _r_matched;
}

pub fn regex_debug() {
    let p = "abc";
    let s = [0];
    let pi = [0];
    let c = char_at(p, pi[0]);
    // Single check instead of multiple if-returns (3+ if-returns corrupts locals)
    let _is_meta = 0;
    if c == ")" { _is_meta = 1; };
    if c == "|" { _is_meta = 1; };
    if c == "(" { _is_meta = 1; };
    if c == "[" { _is_meta = 1; };
    if c == "." { _is_meta = 1; };
    if _is_meta == 1 { return "bad"; };
    let _ = __array_push(s, 0);
    let _ = __array_push(s, c);
    return "c=" + c + " s2=" + s[2];
}
