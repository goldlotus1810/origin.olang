// homeos/knowgraph.ol — Knowledge Graph for Nox
// Triple store: (subject, relation, object) with timestamps.
// Persistent: saves to nox_graph.kg file.

let _kg_subjects = [];
let _kg_relations = [];
let _kg_objects = [];
let _kg_times = [];

pub fn kg_add(subj, rel, obj) {
    // Check for duplicate
    let _ka_i = 0;
    while _ka_i < len(_kg_subjects) {
        if _kg_subjects[_ka_i] == subj {
            if _kg_relations[_ka_i] == rel {
                if _kg_objects[_ka_i] == obj {
                    return 0;
                };
            };
        };
        let _ka_i = _ka_i + 1;
    };
    push(_kg_subjects, subj);
    push(_kg_relations, rel);
    push(_kg_objects, obj);
    push(_kg_times, _fmt_ts(__timestamp()));
    return 1;
}

pub fn kg_find(entity) {
    // Find all triples where entity is subject OR object
    let _kf_results = [];
    let _kf_i = 0;
    while _kf_i < len(_kg_subjects) {
        if _kg_subjects[_kf_i] == entity || _kg_objects[_kf_i] == entity {
            push(_kf_results, _kg_subjects[_kf_i] + " --" + _kg_relations[_kf_i] + "--> " + _kg_objects[_kf_i]);
        };
        let _kf_i = _kf_i + 1;
    };
    return _kf_results;
}

pub fn kg_find_rel(subj, rel) {
    // Find objects related to subject by specific relation
    let _kr_results = [];
    let _kr_i = 0;
    while _kr_i < len(_kg_subjects) {
        if _kg_subjects[_kr_i] == subj {
            if _kg_relations[_kr_i] == rel {
                push(_kr_results, _kg_objects[_kr_i]);
            };
        };
        let _kr_i = _kr_i + 1;
    };
    return _kr_results;
}

pub fn kg_find_by(rel, obj) {
    // Find subjects that have relation to object (reverse lookup)
    let _kb_results = [];
    let _kb_i = 0;
    while _kb_i < len(_kg_subjects) {
        if _kg_relations[_kb_i] == rel {
            if _kg_objects[_kb_i] == obj {
                push(_kb_results, _kg_subjects[_kb_i]);
            };
        };
        let _kb_i = _kb_i + 1;
    };
    return _kb_results;
}

pub fn kg_count() {
    return len(_kg_subjects);
}

pub fn kg_save(path) {
    let _ks_out = "";
    let _ks_i = 0;
    while _ks_i < len(_kg_subjects) {
        _ks_out = _ks_out + "[" + _kg_times[_ks_i] + "] "
            + _kg_subjects[_ks_i] + " |" + _kg_relations[_ks_i] + "| "
            + _kg_objects[_ks_i] + "\n";
        let _ks_i = _ks_i + 1;
    };
    __file_write(path, _ks_out);
    return len(_kg_subjects);
}

pub fn kg_load(path) {
    let _kl_data = __file_read(path);
    if len(_kl_data) == 0 { return 0; };
    let _kl_count = 0;
    let _kl_i = 0;
    let _kl_start = 0;
    while _kl_i <= len(_kl_data) {
        if _kl_i == len(_kl_data) || char_at(_kl_data, _kl_i) == "\n" {
            if _kl_i > _kl_start {
                let _kl_line = __substr(_kl_data, _kl_start, _kl_i);
                _kg_parse_line(_kl_line);
                let _kl_count = _kl_count + 1;
            };
            let _kl_start = _kl_i + 1;
        };
        let _kl_i = _kl_i + 1;
    };
    return _kl_count;
}

fn _kg_parse_line(line) {
    // Format: [timestamp] subject |relation| object
    // Find first ] for timestamp end
    let _kp_ts_end = 0;
    let _kp_i = 0;
    while _kp_i < len(line) {
        if char_at(line, _kp_i) == "]" { let _kp_ts_end = _kp_i; break; };
        let _kp_i = _kp_i + 1;
    };
    if _kp_ts_end == 0 { return; };
    let _kp_ts = __substr(line, 1, _kp_ts_end);
    let _kp_rest = __substr(line, _kp_ts_end + 2, len(line));
    // Find |relation| — first and second |
    let _kp_p1 = -1;
    let _kp_p2 = -1;
    let _kp_j = 0;
    while _kp_j < len(_kp_rest) {
        if char_at(_kp_rest, _kp_j) == "|" {
            if _kp_p1 < 0 { let _kp_p1 = _kp_j; }
            else { if _kp_p2 < 0 { let _kp_p2 = _kp_j; }; };
        };
        let _kp_j = _kp_j + 1;
    };
    if _kp_p1 < 0 || _kp_p2 < 0 { return; };
    let _kp_subj = __substr(_kp_rest, 0, _kp_p1 - 1);
    let _kp_rel = __substr(_kp_rest, _kp_p1 + 1, _kp_p2);
    let _kp_obj = __substr(_kp_rest, _kp_p2 + 2, len(_kp_rest));
    // Trim trailing whitespace from obj
    while len(_kp_obj) > 0 {
        if char_at(_kp_obj, len(_kp_obj) - 1) == " " {
            let _kp_obj = __substr(_kp_obj, 0, len(_kp_obj) - 1);
        } else { break; };
    };
    push(_kg_subjects, _kp_subj);
    push(_kg_relations, _kp_rel);
    push(_kg_objects, _kp_obj);
    push(_kg_times, _kp_ts);
}
