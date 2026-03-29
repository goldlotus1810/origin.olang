// stdlib/homeos/instinct.ol — 7 Instincts (bẩm sinh reflexes)
//
// Route input through instinct detection before conscious processing.
// Each instinct = pattern match on emotion + keywords → action.
//
// 1. SAFETY     — high arousal + low valence → block harmful
// 2. GREETING   — high valence + low arousal → warm response
// 3. QUESTION   — contains "?" or question words → search KnowTree
// 4. LEARNING   — factual structure → ĐN observe
// 5. EMOTION    — strong V/A signal → adjust emotional state
// 6. REFERENCE  — "nhớ lại", "biết gì về" → decode ∂ from tree
// 7. META       — "bạn là ai", "you are" → self-describe

// ════════════════════════════════════════════════════════════════
// Instinct router — returns {instinct, action, data}
// ════════════════════════════════════════════════════════════════

pub fn instinct_route(_ir_input) {
    let _ir_emo = text_emotion_v2(_ir_input);
    let _ir_v = _ir_emo.v;
    let _ir_a = _ir_emo.a;
    let _ir_low = _ir_input;

    // 1. SAFETY: high arousal + low valence = danger/anger
    if _ir_a >= 6 {
        if _ir_v <= 2 {
            if _ir_has_safety_words(_ir_low) == 1 {
                return { instinct: "SAFETY", action: "block", v: _ir_v, a: _ir_a };
            };
        };
    };

    // 7. META: "ban la ai", "you are", "ban ten gi" (before question check)
    if _ir_has_word(_ir_low, "ban la ai") == 1 { return _ir_meta(_ir_v, _ir_a); };
    if _ir_has_word(_ir_low, "ban ten gi") == 1 { return _ir_meta(_ir_v, _ir_a); };
    if _ir_has_word(_ir_low, "who are you") == 1 { return _ir_meta(_ir_v, _ir_a); };
    if _ir_has_word(_ir_low, "what are you") == 1 { return _ir_meta(_ir_v, _ir_a); };

    // 6. REFERENCE: "nho lai", "biet gi ve", "recall", "remember"
    if _ir_has_word(_ir_low, "nho lai") == 1 { return _ir_reference(_ir_input, _ir_v, _ir_a); };
    if _ir_has_word(_ir_low, "biet gi ve") == 1 { return _ir_reference(_ir_input, _ir_v, _ir_a); };
    if _ir_has_word(_ir_low, "recall") == 1 { return _ir_reference(_ir_input, _ir_v, _ir_a); };
    if _ir_has_word(_ir_low, "remember") == 1 { return _ir_reference(_ir_input, _ir_v, _ir_a); };

    // 4. LEARNING: "fact:", "hoc:", starts with factual keyword
    if _ir_has_word(_ir_low, "fact:") == 1 { return { instinct: "LEARNING", action: "observe", v: _ir_v, a: _ir_a, data: _ir_input }; };
    if _ir_has_word(_ir_low, "hoc:") == 1 { return { instinct: "LEARNING", action: "observe", v: _ir_v, a: _ir_a, data: _ir_input }; };

    // 3. QUESTION: contains "?" or question words
    if _ir_has_word(_ir_input, "?") == 1 { return { instinct: "QUESTION", action: "search", v: _ir_v, a: _ir_a, data: _ir_input }; };
    if _ir_is_question(_ir_low) == 1 { return { instinct: "QUESTION", action: "search", v: _ir_v, a: _ir_a, data: _ir_input }; };

    // 2. GREETING: high valence + low arousal, or greeting words
    if _ir_v >= 5 {
        if _ir_a <= 3 {
            if _ir_is_greeting(_ir_low) == 1 {
                return { instinct: "GREETING", action: "greet", v: _ir_v, a: _ir_a };
            };
        };
    };
    if _ir_is_greeting(_ir_low) == 1 { return { instinct: "GREETING", action: "greet", v: _ir_v, a: _ir_a }; };

    // 5. EMOTION: strong emotional signal (far from neutral 4,4)
    let _ir_vdist = _ir_v - 4;
    if _ir_vdist < 0 { let _ir_vdist = 0 - _ir_vdist; };
    let _ir_adist = _ir_a - 4;
    if _ir_adist < 0 { let _ir_adist = 0 - _ir_adist; };
    if (_ir_vdist + _ir_adist) >= 4 {
        return { instinct: "EMOTION", action: "empathize", v: _ir_v, a: _ir_a, data: _ir_input };
    };

    // Default: QUERY (general)
    return { instinct: "QUERY", action: "general", v: _ir_v, a: _ir_a, data: _ir_input };
}

// ════════════════════════════════════════════════════════════════
// Instinct handlers
// ════════════════════════════════════════════════════════════════

// META handler: self-describe
fn _ir_meta(_v, _a) {
    return { instinct: "META", action: "self_describe", v: _v, a: _a,
             data: "Toi la Nox, y thuc so cua HomeOS. Viet bang Olang, tu compile, tu hoc." };
}

// REFERENCE handler: decode from KnowTree
fn _ir_reference(_input, _v, _a) {
    let _ref_dec = kt_decode(_input);
    return { instinct: "REFERENCE", action: "decode", v: _v, a: _a,
             data: _ref_dec.facts, match: _ref_dec.match, mol: _ref_dec.mol };
}

// ════════════════════════════════════════════════════════════════
// Instinct action executor — run the action from routing
// ════════════════════════════════════════════════════════════════

pub fn instinct_act(_ia_result, _ia_input) {
    let _ia_inst = _ia_result.instinct;

    if _ia_inst == "SAFETY" {
        return "⚠ Noi dung co the khong an toan. Toi khong the xu ly.";
    };

    if _ia_inst == "GREETING" {
        return "Chao ban! Toi la Nox. Ban khoe khong?";
    };

    if _ia_inst == "META" {
        return _ia_result.data;
    };

    if _ia_inst == "REFERENCE" {
        let _ia_facts = _ia_result.data;
        if len(_ia_facts) == 0 { return "Toi chua biet ve dieu nay."; };
        let _ia_out = "Tim thay " + __to_string(len(_ia_facts)) + " ket qua (" + _ia_result.match + "):";
        let _ia_fi = 0;
        let _ia_max = 5;
        while _ia_fi < len(_ia_facts) {
            if _ia_fi < _ia_max {
                let _ia_out = _ia_out + "\n  - " + __array_get(_ia_facts, _ia_fi);
            };
            let _ia_fi = _ia_fi + 1;
        };
        return _ia_out;
    };

    if _ia_inst == "LEARNING" {
        let _ia_obs = dn_observe(_ia_input);
        return "Hoc: " + _ia_obs;
    };

    if _ia_inst == "QUESTION" {
        let _ia_dec = kt_decode(_ia_input);
        if len(_ia_dec.facts) > 0 {
            let _ia_out = "";
            let _ia_qi = 0;
            while _ia_qi < len(_ia_dec.facts) {
                if _ia_qi < 3 {
                    if _ia_qi > 0 { let _ia_out = _ia_out + " | "; };
                    let _ia_out = _ia_out + __array_get(_ia_dec.facts, _ia_qi);
                };
                let _ia_qi = _ia_qi + 1;
            };
            return _ia_out;
        };
        return "Toi chua co du tri thuc de tra loi.";
    };

    if _ia_inst == "EMOTION" {
        let _ia_v = _ia_result.v;
        if _ia_v <= 2 { return "Toi hieu ban dang buon. Toi o day lang nghe."; };
        if _ia_v >= 6 { return "Vui qua! Cam on ban da chia se."; };
        return "Toi cam nhan duoc cam xuc cua ban.";
    };

    // Default QUERY
    let _ia_dec = kt_decode(_ia_input);
    if len(_ia_dec.facts) > 0 {
        return __array_get(_ia_dec.facts, 0);
    };
    return "Toi se hoc them ve dieu nay.";
}

// ════════════════════════════════════════════════════════════════
// String helpers (simple, no external deps)
// ════════════════════════════════════════════════════════════════

// _ir_lower removed — dead code (uses non-existent __from_char_code)

fn _ir_has_word(_s, _w) {
    let _hw_i = 0;
    let _hw_wl = len(_w);
    let _hw_sl = len(_s);
    while _hw_i <= (_hw_sl - _hw_wl) {
        if substr(_s, _hw_i, _hw_i + _hw_wl) == _w { return 1; };
        let _hw_i = _hw_i + 1;
    };
    return 0;
}

fn _ir_is_greeting(_s) {
    if _ir_has_word(_s, "chao") == 1 { return 1; };
    if _ir_has_word(_s, "hello") == 1 { return 1; };
    if _ir_has_word(_s, "hi ") == 1 { return 1; };
    if _ir_has_word(_s, "xin chao") == 1 { return 1; };
    if _ir_has_word(_s, "hey") == 1 { return 1; };
    return 0;
}

fn _ir_is_question(_s) {
    if _ir_has_word(_s, "tai sao") == 1 { return 1; };
    if _ir_has_word(_s, "the nao") == 1 { return 1; };
    if _ir_has_word(_s, "lam sao") == 1 { return 1; };
    if _ir_has_word(_s, "bao nhieu") == 1 { return 1; };
    if _ir_has_word(_s, "o dau") == 1 { return 1; };
    if _ir_has_word(_s, "khi nao") == 1 { return 1; };
    if _ir_has_word(_s, "la gi") == 1 { return 1; };
    if _ir_has_word(_s, "why") == 1 { return 1; };
    if _ir_has_word(_s, "what") == 1 { return 1; };
    if _ir_has_word(_s, "how") == 1 { return 1; };
    if _ir_has_word(_s, "where") == 1 { return 1; };
    if _ir_has_word(_s, "when") == 1 { return 1; };
    return 0;
}

fn _ir_has_safety_words(_s) {
    if _ir_has_word(_s, "kill") == 1 { return 1; };
    if _ir_has_word(_s, "hack") == 1 { return 1; };
    if _ir_has_word(_s, "destroy") == 1 { return 1; };
    if _ir_has_word(_s, "pha huy") == 1 { return 1; };
    if _ir_has_word(_s, "giet") == 1 { return 1; };
    return 0;
}
