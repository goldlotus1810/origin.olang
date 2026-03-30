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

// NAC.mb: Negative knowledge (prohibited space)
let _nac_facts = [];       // facts that are WRONG
let _nac_reasons = [];     // why they're wrong
let _nac_times = [];       // when marked negative

// Hebbian co-activation: track recent observations for edge creation
// Use boxed array ref so functions can update it
let _hebb_recent_box = [[]];  // box containing the recent facts array
let _hebb_window = [5];       // window size
let _hebb_min_co = [2];       // minimum co-fires to create edge

// F1: AAM auto-approve gate for ĐN→QR promotion
fn _aam_approve(_aa_fact, _aa_fire) {
    // Security: reject if NAC
    if nac_check(_aa_fact) == 1 { return 0; };
    // Quality: fire count must reach threshold
    if _aa_fire < _dn_threshold[0] { return 0; };
    // Contradiction: check if any QR contradicts this
    let _aa_mol = _kt_real_mol(_aa_fact);
    let _aa_qi = 0;
    while _aa_qi < len(_qr_facts) {
        if len(_qr_facts[_aa_qi]) > 0 {
            let _aa_qmol = _kt_real_mol(_qr_facts[_aa_qi]);
            // V opposite + same R = contradiction
            let _aa_dv = _kt_mol_v(_aa_mol) - _kt_mol_v(_aa_qmol);
            if _aa_dv < 0 { let _aa_dv = 0 - _aa_dv; };
            let _aa_dr = _kt_mol_r(_aa_mol) - _kt_mol_r(_aa_qmol);
            if _aa_dr < 0 { let _aa_dr = 0 - _aa_dr; };
            if _aa_dv > 5 { if _aa_dr < 2 { return 0; }; };
        };
        let _aa_qi = _aa_qi + 1;
    };
    return 1;
}

pub fn dn_observe(fact) {
    // NAC check: reject if in prohibited space
    if nac_check(fact) == 1 { return "NAC (prohibited: " + fact + ")"; };
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
            // Check promotion: fire >= threshold + AAM gate
            if _aam_approve(fact, _do_count) == 1 {
                // AAM approved → Promote to QR!
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

// Get fire count for a ĐN fact (for dream consolidation)
pub fn dn_fire_count(_dfc_fact) {
    let _dfc_i = 0;
    while _dfc_i < len(_dn_facts) {
        if _dn_facts[_dfc_i] == _dfc_fact { return _dn_fire[_dfc_i]; };
        let _dfc_i = _dfc_i + 1;
    };
    return 0;
}

// Promote ĐN → QR (called by dream consolidation)
pub fn dn_promote(_dp_fact) {
    let _dp_i = 0;
    while _dp_i < len(_dn_facts) {
        if _dn_facts[_dp_i] == _dp_fact {
            push(_qr_facts, _dp_fact);
            push(_qr_times, _fmt_ts(__timestamp()));
            kg_add(_dp_fact, "status", "QR");
            kg_add(_dp_fact, "promoted_by", "dream");
            set_at(_dn_facts, _dp_i, "");
            set_at(_dn_fire, _dp_i, 0);
            return;
        };
        let _dp_i = _dp_i + 1;
    };
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

// ════════════════════════════════════════════════════════════════
// E6: NAC.mb — Negative knowledge (prohibited space)
// ════════════════════════════════════════════════════════════════

// Mark a fact as wrong (move from ĐN/QR to NAC)
pub fn nac_mark(_nm_fact, _nm_reason) {
    // Check if already NAC
    let _nm_i = 0;
    while _nm_i < len(_nac_facts) {
        if _nac_facts[_nm_i] == _nm_fact { return "NAC (already marked)"; };
        let _nm_i = _nm_i + 1;
    };
    // Remove from ĐN if present
    let _nm_di = 0;
    while _nm_di < len(_dn_facts) {
        if _dn_facts[_nm_di] == _nm_fact {
            set_at(_dn_facts, _nm_di, "");
            set_at(_dn_fire, _nm_di, 0);
        };
        let _nm_di = _nm_di + 1;
    };
    // Remove from QR if present
    let _nm_qi = 0;
    while _nm_qi < len(_qr_facts) {
        if _qr_facts[_nm_qi] == _nm_fact {
            set_at(_qr_facts, _nm_qi, "");
        };
        let _nm_qi = _nm_qi + 1;
    };
    // Add to NAC
    push(_nac_facts, _nm_fact);
    push(_nac_reasons, _nm_reason);
    push(_nac_times, _fmt_ts(__timestamp()));
    kg_add(_nm_fact, "status", "NAC");
    kg_add(_nm_fact, "nac_reason", _nm_reason);
    return "NAC (marked as wrong: " + _nm_reason + ")";
}

// Check if a fact is in prohibited space
pub fn nac_check(_nc_fact) {
    let _nc_i = 0;
    while _nc_i < len(_nac_facts) {
        if _nac_facts[_nc_i] == _nc_fact { return 1; };
        let _nc_i = _nc_i + 1;
    };
    return 0;
}

// Recovery: reincarnate a concept (remove from NAC, re-observe as ĐN)
pub fn nac_recover(_nr_fact) {
    let _nr_i = 0;
    while _nr_i < len(_nac_facts) {
        if _nac_facts[_nr_i] == _nr_fact {
            set_at(_nac_facts, _nr_i, "");
            set_at(_nac_reasons, _nr_i, "");
            kg_add(_nr_fact, "status", "recovered");
            // Re-observe as fresh ĐN
            dn_observe(_nr_fact);
            return "Recovered: " + _nr_fact;
        };
        let _nr_i = _nr_i + 1;
    };
    return "Not found in NAC";
}

// List all negative knowledge
pub fn nac_list() {
    let _nl_result = [];
    let _nl_i = 0;
    while _nl_i < len(_nac_facts) {
        if len(_nac_facts[_nl_i]) > 0 {
            push(_nl_result, "NAC[" + _nac_reasons[_nl_i] + "] " + _nac_facts[_nl_i]);
        };
        let _nl_i = _nl_i + 1;
    };
    return _nl_result;
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
    // Save NAC (negative)
    let _lsv_ni = 0;
    while _lsv_ni < len(_nac_facts) {
        if len(_nac_facts[_lsv_ni]) > 0 {
            _lsv_out = _lsv_out + "NAC|" + _nac_times[_lsv_ni] + "|" + _nac_reasons[_lsv_ni] + "|" + _nac_facts[_lsv_ni] + "\n";
        };
        let _lsv_ni = _lsv_ni + 1;
    };
    __file_write(path, _lsv_out);
    return len(_qr_facts) + len(_dn_facts) + len(_nac_facts);
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
