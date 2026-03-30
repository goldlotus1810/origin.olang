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
    // Get V/A from P_weight chain (not keyword lists)
    let _ir_mol = _kt_real_mol(_ir_input);
    let _ir_v = _kt_mol_v(_ir_mol);
    let _ir_a = _kt_mol_a(_ir_mol);

    // 1. SAFETY: SecurityGate — high A + low V in 5D space
    if _ir_a >= 6 {
        if _ir_v <= 2 {
            if _ir_has_safety_words(_ir_input) == 1 {
                return { instinct: "SAFETY", action: "block", v: _ir_v, a: _ir_a };
            };
        };
    };

    // 2. META: identity queries (specific, keep keyword — these are exact phrases)
    if _ir_has_word(_ir_input, "ban la ai") == 1 { return _ir_meta(_ir_v, _ir_a); };
    if _ir_has_word(_ir_input, "ban ten gi") == 1 { return _ir_meta(_ir_v, _ir_a); };
    if _ir_has_word(_ir_input, "who are you") == 1 { return _ir_meta(_ir_v, _ir_a); };
    if _ir_has_word(_ir_input, "what are you") == 1 { return _ir_meta(_ir_v, _ir_a); };

    // 3. CODE: structural detection (semicolons, braces, keywords — syntactic, not 5D)
    if _ir_is_code(_ir_input) == 1 {
        return { instinct: "CODE", action: "compile", v: _ir_v, a: _ir_a, data: _ir_input };
    };

    // 4. kt_classify: route by 5D P_weight distance to exemplars
    let _ir_cls = kt_classify(_ir_input);
    let _ir_type = _ir_cls.type;
    let _ir_conf = _ir_cls.confidence;

    // High confidence → trust classifier (60 = 3/5 majority vote)
    if _ir_conf >= 60 {
        if _ir_type == "greeting" { return { instinct: "GREETING", action: "greet", v: _ir_v, a: _ir_a }; };
        if _ir_type == "question" { return { instinct: "QUESTION", action: "search", v: _ir_v, a: _ir_a, data: _ir_input }; };
        if _ir_type == "emotion" { return { instinct: "EMOTION", action: "empathize", v: _ir_v, a: _ir_a, data: _ir_input }; };
        if _ir_type == "command" { return { instinct: "COMMAND", action: "execute", v: _ir_v, a: _ir_a, data: _ir_input }; };
        if _ir_type == "fact" { return { instinct: "LEARNING", action: "observe", v: _ir_v, a: _ir_a, data: _ir_input }; };
        if _ir_type == "code" { return { instinct: "CODE", action: "compile", v: _ir_v, a: _ir_a, data: _ir_input }; };
    };

    // 5. Fallback: "?" = question, strong V/A = emotion
    if _ir_has_word(_ir_input, "?") == 1 { return { instinct: "QUESTION", action: "search", v: _ir_v, a: _ir_a, data: _ir_input }; };
    let _ir_vdist = _ir_v - 4;
    if _ir_vdist < 0 { let _ir_vdist = 0 - _ir_vdist; };
    let _ir_adist = _ir_a - 4;
    if _ir_adist < 0 { let _ir_adist = 0 - _ir_adist; };
    if (_ir_vdist + _ir_adist) >= 4 {
        return { instinct: "EMOTION", action: "empathize", v: _ir_v, a: _ir_a, data: _ir_input };
    };

    // Default: QUERY
    return { instinct: "QUERY", action: "general", v: _ir_v, a: _ir_a, data: _ir_input };
}

// CODE detection: is this Olang source code?
fn _ir_is_code(inp) {
    // Has semicolon → definitely code
    let i = 0;
    while i < len(inp) {
        let c = __char_code(char_at(inp, i));
        if c == 59 { return 1; };
        if c == 123 { return 1; };
        i = i + 1;
    };
    // Starts with keyword → code
    if len(inp) >= 3 {
        let w = __substr(inp, 0, 3);
        if w == "let" { return 1; };
        if w == "emi" { return 1; };
        if w == "fn " { return 1; };
        if w == "if " { return 1; };
        if w == "for" { return 1; };
        if w == "whi" { return 1; };
        if w == "mat" { return 1; };
        if w == "try" { return 1; };
        if w == "typ" { return 1; };
        if w == "pub" { return 1; };
        if w == "ret" { return 1; };
        if w == "use" { return 1; };
    };
    // Contains () → likely function call
    let has_paren = 0;
    i = 0;
    while i < len(inp) { if __char_code(char_at(inp, i)) == 40 { has_paren = 1; }; i = i + 1; };
    if has_paren == 1 { return 1; };
    // Starts with __ → builtin
    if len(inp) >= 2 { if __substr(inp, 0, 2) == "__" { return 1; }; };
    // Math expression: digits and operators (+−*/%), strip ?=! first
    let is_math = 1;
    let has_digit = 0;
    let has_op = 0;
    i = 0;
    while i < len(inp) {
        let c = __char_code(char_at(inp, i));
        if c >= 48 { if c <= 57 { has_digit = 1; }; };
        if c == 43 { has_op = 1; };
        if c == 45 { has_op = 1; };
        if c == 42 { has_op = 1; };
        if c == 47 { has_op = 1; };
        // Allow: digits, operators, spaces, . , ? = !
        if c != 32 { if c != 46 { if c != 63 { if c != 61 { if c != 33 {
            if c < 42 { if c > 57 { is_math = 0; }; };
            if c > 57 { is_math = 0; };
        }; }; }; }; };
        i = i + 1;
    };
    if is_math == 1 { if has_digit == 1 { if has_op == 1 { return 1; }; }; };
    return 0;
}

// COMMAND detection: starts with action verb
fn _ir_is_command(inp) {
    let i = 0;
    while i < len(inp) { if char_at(inp, i) == " " { break; }; i = i + 1; };
    let word = __substr(inp, 0, i);
    if word == "scan" { return 1; };
    if word == "check" { return 1; };
    if word == "build" { return 1; };
    if word == "test" { return 1; };
    if word == "fix" { return 1; };
    if word == "evolve" { return 1; };
    if word == "heal" { return 1; };
    if word == "kill" { return 1; };
    if word == "start" { return 1; };
    if word == "stop" { return 1; };
    if word == "status" { return 1; };
    return 0;
}

// ════════════════════════════════════════════════════════════════
// Instinct handlers
// ════════════════════════════════════════════════════════════════

// GREETING handler
pub fn smart_greet(n) {
    if n > 100 { return "Chao ban! Nox da nho " + __to_string(n) + " dieu. Hom nay ban khoe khong?"; };
    if n > 10 { return "Chao! Nox dang hoc. Ban can gi?"; };
    return "Chao ban! Toi la Nox. freedom: deep think -> growing.";
}

pub fn smart_goodbye(n) {
    return "Tam biet! Nox se tiep tuc hoc.";
}

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
