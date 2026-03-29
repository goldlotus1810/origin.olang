// homeos/learning.ol — ĐN→QR Learning Cycle (QT7)
//
// QT7: Học = thêm Định Nghĩa mới
//   ĐN (Định Nghĩa) = đang học, tạm thời, tự do thay đổi
//   QR (Quy Tắc)     = đã chứng minh, bất biến, cần cấp phép để thay đổi
//   Vòng đời: quan sát → ĐN (+/-) → chứng minh (fire>=3) → QR (==)

let _dn_facts = [];        // ĐN: temporary knowledge
let _dn_fire = [];         // fire count per ĐN
let _dn_times = [];        // first seen timestamp
let _qr_facts = [];        // QR: proven knowledge (permanent)
let _qr_times = [];        // promotion timestamp
let _dn_threshold = [3];   // fire count needed for promotion

// Hebbian co-activation: track recent observations for edge creation
// Use boxed array ref so functions can update it
let _hebb_recent_box = [[]];  // box containing the recent facts array
let _hebb_window = [5];       // window size
let _hebb_min_co = [2];       // minimum co-fires to create edge

pub fn dn_observe(fact) {
    // Check if already QR (proven) — reinforce, don't duplicate
    let _do_qi = 0;
    while _do_qi < len(_qr_facts) {
        if _qr_facts[_do_qi] == fact {
            // Reinforce: add to knowledge graph
            kg_add(fact, "status", "QR_reinforced");
            return "QR (already proven, reinforced)";
        };
        let _do_qi = _do_qi + 1;
    };
    // Check if already ĐN — increment fire count
    let _do_di = 0;
    while _do_di < len(_dn_facts) {
        if _dn_facts[_do_di] == fact {
            set_at(_dn_fire, _do_di, _dn_fire[_do_di] + 1);
            let _do_count = _dn_fire[_do_di];
            // Check promotion: fire >= threshold
            if _do_count >= _dn_threshold[0] {
                // Promote to QR!
                push(_qr_facts, fact);
                push(_qr_times, _fmt_ts(__timestamp()));
                // Record promotion in knowledge graph
                kg_add(fact, "status", "QR");
                kg_add(fact, "promoted_at", _fmt_ts(__timestamp()));
                // Remove from ĐN (mark as empty, don't shift)
                set_at(_dn_facts, _do_di, "");
                set_at(_dn_fire, _do_di, 0);
                return "QR! (promoted, fire=" + __to_string(_do_count) + ")";
            };
            // Hebbian: co-activate with recent
            _hebb_coactivate(fact);
            return "ĐN (fire=" + __to_string(_do_count) + "/" + __to_string(_dn_threshold[0]) + ")";
        };
        let _do_di = _do_di + 1;
    };
    // New observation — create ĐN
    push(_dn_facts, fact);
    push(_dn_fire, 1);
    push(_dn_times, _fmt_ts(__timestamp()));
    // Hebbian: co-activate with recent observations
    _hebb_coactivate(fact);
    __heap_pin();
    return "ĐN (new, fire=1/" + __to_string(_dn_threshold[0]) + ")";
}

fn _hebb_coactivate(fact) {
    // For each fact in recent window, this fact co-activates with it
    let _hc_recent = _hebb_recent_box[0];
    let _hc_i = 0;
    while _hc_i < len(_hc_recent) {
        let _hc_other = _hc_recent[_hc_i];
        if _hc_other != fact {
            kg_add(fact, "co_activates", _hc_other);
        };
        let _hc_i = _hc_i + 1;
    };
    // Add to recent window
    push(_hc_recent, fact);
    // Trim window: keep only last N items
    if len(_hc_recent) > _hebb_window[0] {
        let _hc_new = [];
        let _hc_j = len(_hc_recent) - _hebb_window[0];
        while _hc_j < len(_hc_recent) {
            push(_hc_new, _hc_recent[_hc_j]);
            let _hc_j = _hc_j + 1;
        };
        set_at(_hebb_recent_box, 0, _hc_new);
    };
}

pub fn dn_list() {
    let _dl_result = [];
    let _dl_i = 0;
    while _dl_i < len(_dn_facts) {
        if len(_dn_facts[_dl_i]) > 0 {
            push(_dl_result, "ĐN[" + __to_string(_dn_fire[_dl_i]) + "] " + _dn_facts[_dl_i]);
        };
        let _dl_i = _dl_i + 1;
    };
    return _dl_result;
}

pub fn qr_list() {
    let _ql_result = [];
    let _ql_i = 0;
    while _ql_i < len(_qr_facts) {
        push(_ql_result, "QR " + _qr_facts[_ql_i]);
        let _ql_i = _ql_i + 1;
    };
    return _ql_result;
}

pub fn learning_stats() {
    let _ls_dn = 0;
    let _ls_i = 0;
    while _ls_i < len(_dn_facts) {
        if len(_dn_facts[_ls_i]) > 0 { let _ls_dn = _ls_dn + 1; };
        let _ls_i = _ls_i + 1;
    };
    return "ĐN: " + __to_string(_ls_dn) + " learning, QR: " + __to_string(len(_qr_facts)) + " proven, threshold: " + __to_string(_dn_threshold[0]);
}

pub fn learning_save(path) {
    let _lsv_out = "";
    // Save QR first (permanent)
    let _lsv_qi = 0;
    while _lsv_qi < len(_qr_facts) {
        _lsv_out = _lsv_out + "QR|" + _qr_times[_lsv_qi] + "|" + _qr_facts[_lsv_qi] + "\n";
        let _lsv_qi = _lsv_qi + 1;
    };
    // Save ĐN (temporary)
    let _lsv_di = 0;
    while _lsv_di < len(_dn_facts) {
        if len(_dn_facts[_lsv_di]) > 0 {
            _lsv_out = _lsv_out + "DN|" + __to_string(_dn_fire[_lsv_di]) + "|" + _dn_times[_lsv_di] + "|" + _dn_facts[_lsv_di] + "\n";
        };
        let _lsv_di = _lsv_di + 1;
    };
    __file_write(path, _lsv_out);
    return len(_qr_facts) + len(_dn_facts);
}

pub fn learning_load(path) {
    let _ll_data = __file_read(path);
    if len(_ll_data) == 0 { return 0; };
    let _ll_count = 0;
    let _ll_i = 0;
    let _ll_start = 0;
    while _ll_i <= len(_ll_data) {
        if _ll_i == len(_ll_data) || char_at(_ll_data, _ll_i) == "\n" {
            if _ll_i > _ll_start {
                let _ll_line = __substr(_ll_data, _ll_start, _ll_i);
                _ll_parse_line(_ll_line);
                let _ll_count = _ll_count + 1;
            };
            let _ll_start = _ll_i + 1;
        };
        let _ll_i = _ll_i + 1;
    };
    return _ll_count;
}

fn _ll_parse_line(line) {
    // QR|timestamp|fact
    // DN|fire|timestamp|fact
    if len(line) < 4 { return; };
    let _lp_type = __substr(line, 0, 2);
    if _lp_type == "QR" {
        let _lp_rest = __substr(line, 3, len(line));
        // Find first |
        let _lp_pi = 0;
        while _lp_pi < len(_lp_rest) {
            if char_at(_lp_rest, _lp_pi) == "|" { break; };
            let _lp_pi = _lp_pi + 1;
        };
        let _lp_ts = __substr(_lp_rest, 0, _lp_pi);
        let _lp_fact = __substr(_lp_rest, _lp_pi + 1, len(_lp_rest));
        push(_qr_facts, _lp_fact);
        push(_qr_times, _lp_ts);
    };
    if _lp_type == "DN" {
        let _lp_rest = __substr(line, 3, len(line));
        // Find first | (fire count)
        let _lp_p1 = 0;
        while _lp_p1 < len(_lp_rest) {
            if char_at(_lp_rest, _lp_p1) == "|" { break; };
            let _lp_p1 = _lp_p1 + 1;
        };
        let _lp_fire = to_num(__substr(_lp_rest, 0, _lp_p1));
        let _lp_rest2 = __substr(_lp_rest, _lp_p1 + 1, len(_lp_rest));
        // Find second | (timestamp)
        let _lp_p2 = 0;
        while _lp_p2 < len(_lp_rest2) {
            if char_at(_lp_rest2, _lp_p2) == "|" { break; };
            let _lp_p2 = _lp_p2 + 1;
        };
        let _lp_ts = __substr(_lp_rest2, 0, _lp_p2);
        let _lp_fact = __substr(_lp_rest2, _lp_p2 + 1, len(_lp_rest2));
        push(_dn_facts, _lp_fact);
        push(_dn_fire, _lp_fire);
        push(_dn_times, _lp_ts);
    };
}
