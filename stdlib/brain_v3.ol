// ═══ Brain v3 — Full 6-Layer Pipeline with Persistence + Feedback ═══
// Spec: SPEC_D (15 mechanisms, 6 CPs, PTAVF)
// Integrates: knowtree + silk + persist + feedback + generate
//
// Pipeline: Capture → Activate → Hypothesize → Repair → Decode → Evaluate
// Boot: persist_load → knowledge ready
// Save: persist_save → knowledge preserved

// ═══ STATE ═══
let _persist_dir = ["/tmp/nox_data"];
let _persist_turn = [0];
let _persist_interval = 20;  // auto-save every N turns

// ═══ BOOT ═══
// Try binary first (fast), fallback to text (slow)
fn brain_boot(dir) {
    let _ = __set_at(_persist_dir, 0, dir);
    let _ = __system("mkdir -p " + dir);

    let total = [0];

    // Try binary KnowTree first
    let nkb_path = dir + "/knowtree.nkb";
    let nkb_data = __file_read(nkb_path);
    if len(nkb_data) > 8 {
        // Check magic NKB
        if __char_code(char_at(nkb_data, 0)) == 78 {
            let nk = kt_load_binary(nkb_path);
            let _ = __set_at(total, 0, __array_get(total, 0) + nk);
        };
    };

    // If no binary loaded, try text fallback
    if __array_get(total, 0) == 0 {
        let txt_path = dir + "/facts.dat";
        let txt_data = __file_read(txt_path);
        if len(txt_data) > 0 {
            let nt = kt_load_simple(txt_path);
            let _ = __set_at(total, 0, __array_get(total, 0) + nt);
        };
    };

    // Load silk weights
    let slk_path = dir + "/silk.slk";
    let slk_data = __file_read(slk_path);
    if len(slk_data) > 8 {
        if __char_code(char_at(slk_data, 0)) == 83 {
            let ns = silk_load(slk_path);
            let _ = __set_at(total, 0, __array_get(total, 0) + ns);
        };
    };

    // Load feedback data
    let fbk_path = dir + "/feedback.fbk";
    let fbk_data = __file_read(fbk_path);
    if len(fbk_data) > 8 {
        if __char_code(char_at(fbk_data, 0)) == 70 {
            let nf = fb_load(fbk_path);
            let _ = __set_at(total, 0, __array_get(total, 0) + nf);
        };
    };

    return __array_get(total, 0);
};

// ═══ SAVE ═══
fn brain_save() {
    let dir = __array_get(_persist_dir, 0);

    // Save KnowTree binary
    let nkb_path = dir + "/knowtree.nkb";
    __file_write(nkb_path, "");
    let nk = kt_save_binary(nkb_path);

    // Save silk weights
    let slk_path = dir + "/silk.slk";
    __file_write(slk_path, "");
    let ns = silk_save(slk_path);

    // Save feedback
    let fbk_path = dir + "/feedback.fbk";
    __file_write(fbk_path, "");
    let nf = fb_save(fbk_path);

    return nk + ns + nf;
};

// ═══ PTAVF CYCLE — Perceive Think Act Verify Feedback ═══
// One full brain cycle for a query
fn ptav_cycle(query) {
    // P: Perceive — encode query
    let qmol = kt_encode_mol(query);

    // T: Think — generate response (retrieve + recombine + confidence)
    let response = generate_tracked(query);

    // A: Act — output response (caller handles display)

    // V: Verify — (implicit: will come from next interaction)
    // F: Feedback — auto-save check
    let _turn = [__array_get(_persist_turn, 0) + 1];
    if __array_get(_turn, 0) >= _persist_interval {
        brain_save();
        let _ = __set_at(_turn, 0, 0);
    };
    let _ = __set_at(_persist_turn, 0, __array_get(_turn, 0));

    return response;
};

// ═══ LEARN + PERSIST ═══
fn brain_learn(text) {
    let idx = kt_learn(text);
    // WAL entry
    let dir = __array_get(_persist_dir, 0);
    wal_append(dir + "/learning.wal", WAL_KT_LEARN, 0, idx);
    return idx;
};

// ═══ REWARD ═══
// Call after user feedback on last response
fn brain_reward(reward) {
    generate_reward(reward);
    // Calibrate
    let conf = gen_confidence(kt_nearest("", 1), 0);
    if reward > 500 {
        fb_calibrate_record(conf, 1);
    } else {
        fb_calibrate_record(conf, 0);
    };
};

// ═══ SHUTDOWN ═══
fn brain_shutdown() {
    brain_save();
};

emit "brain_v3 loaded (6-layer PTAVF)";
