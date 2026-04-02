// ═══ Feedback — Nox Knows Right from Wrong ═══
// Spec: BP16 Feedback
//
// UCB1 bandit selection on silk edges + ACT-R utility update
// Each silk edge tracks: reward_sum, reward_count (stored in act_matrix)
// act_matrix layout: slot = silk_hash
//   __act_set(slot, value) — set reward_sum
//   __act_get(slot) — get reward_sum
//   __act_add(slot, delta) — add to reward_sum
// reward_count stored at slot + 32768 (upper half of act_matrix)

let FB_COUNT_OFFSET = 32768;

// ── Get reward stats for a silk edge ──
fn fb_reward_sum(mol_a, mol_b) {
    let h = silk_hash(mol_a, mol_b);
    return __act_get(h);
};

fn fb_reward_count(mol_a, mol_b) {
    let h = silk_hash(mol_a, mol_b);
    return __act_get(h + FB_COUNT_OFFSET);
};

// ── Update reward for a silk edge ──
// reward: 0-1000 (0=terrible, 500=neutral, 1000=perfect)
fn fb_update(mol_a, mol_b, reward) {
    let h = silk_hash(mol_a, mol_b);
    // Add to reward_sum
    __act_add(h, reward);
    // Increment reward_count
    let rc = __act_get(h + FB_COUNT_OFFSET);
    __act_set(h + FB_COUNT_OFFSET, rc + 1);

    // ACT-R utility update on silk weight
    // weight += alpha * (reward - weight) / 1000
    let w = __mxr(h);
    let alpha = 100;  // learning rate 0.1 × 1000
    let delta = __floor(alpha * (reward - w) / 1000);
    let nw = w + delta;
    if nw < 0 { let nw = 0; };
    if nw > 65535 { let nw = 65535; };
    __mx_w(h, nw);
    return nw;
};

// ── UCB1 score for a silk edge ──
// Higher = should explore/exploit this edge more
fn fb_ucb1(mol_a, mol_b, total_plays) {
    let h = silk_hash(mol_a, mol_b);
    let rc = __act_get(h + FB_COUNT_OFFSET);
    if rc == 0 { return 99999; };  // unvisited = explore first
    let rs = __act_get(h);
    // exploit = avg reward
    let exploit = __floor(rs / rc);
    // explore = sqrt(2 * ln(total) / count)
    // ln ≈ log2 * 0.693, use log2 builtin
    let log_total = __log2(total_plays);
    let explore_sq = __floor(2 * log_total * 693 / (rc * 1000));
    let explore = __floor(__sqrt(explore_sq) * 1000);
    return exploit + explore;
};

// ── Select best candidate from array of mols using UCB1 ──
// candidates = array of mol values
// query_mol = the query being answered
// Returns index of best candidate
fn fb_select(candidates, query_mol, total_plays) {
    let best_idx = [0];
    let best_score = [0 - 1];
    let i = 0;
    let n = len(candidates);
    while i < n {
        let c = __array_get(candidates, i);
        let score = fb_ucb1(query_mol, c, total_plays);
        if score > __array_get(best_score, 0) {
            let _ = __set_at(best_score, 0, score);
            let _ = __set_at(best_idx, 0, i);
        };
        let i = i + 1;
    };
    return __array_get(best_idx, 0);
};

// ── Batch reward: reward all edges along a path ──
// path = array of mols visited during generation
// reward = 0-1000
fn fb_reward_path(path, reward) {
    let i = 0;
    let n = len(path);
    while i < n - 1 {
        let a = __array_get(path, i);
        let b = __array_get(path, i + 1);
        fb_update(a, b, reward);
        let i = i + 1;
    };
};

// ── Confidence calibration ──
// 10 buckets (0-99, 100-199, ..., 900-999)
// Track predictions and correct outcomes per bucket
let fb_cal_total = __array_with_cap(10);
let fb_cal_correct = __array_with_cap(10);
// Init buckets to 0
let fb_ci = 0;
while fb_ci < 10 {
    push(fb_cal_total, 0);
    push(fb_cal_correct, 0);
    let fb_ci = fb_ci + 1;
};

fn fb_calibrate_record(confidence, was_correct) {
    let bucket = __floor(confidence / 100);
    if bucket > 9 { let bucket = 9; };
    if bucket < 0 { let bucket = 0; };
    let t = __array_get(fb_cal_total, bucket);
    let _ = __set_at(fb_cal_total, bucket, t + 1);
    if was_correct > 0 {
        let c = __array_get(fb_cal_correct, bucket);
        let _ = __set_at(fb_cal_correct, bucket, c + 1);
    };
};

fn fb_calibrated_confidence(raw) {
    let bucket = __floor(raw / 100);
    if bucket > 9 { let bucket = 9; };
    if bucket < 0 { let bucket = 0; };
    let t = __array_get(fb_cal_total, bucket);
    if t < 5 { return raw; };  // not enough data, return raw
    let c = __array_get(fb_cal_correct, bucket);
    return __floor(c * 1000 / t);
};

// ── Save/Load feedback data ──
// Format: [magic:4 "FBK\n"][count:4][entries...]
// Entry: [hash:2][reward_sum:2][reward_count:2] = 6 bytes
fn fb_save(path) {
    let fb_bytes = [];
    // Magic: F B K \n (70, 66, 75, 10)
    push(fb_bytes, 70);
    push(fb_bytes, 66);
    push(fb_bytes, 75);
    push(fb_bytes, 10);

    // Count non-zero entries
    let fb_cnt = [0];
    let fb_i = 0;
    while fb_i < 32768 {
        let fb_rc = __act_get(fb_i + FB_COUNT_OFFSET);
        if fb_rc > 0 {
            let _ = __set_at(fb_cnt, 0, __array_get(fb_cnt, 0) + 1);
        };
        let fb_i = fb_i + 1;
    };

    let fb_cb = persist_u32_bytes(__array_get(fb_cnt, 0));
    push(fb_bytes, __array_get(fb_cb, 0));
    push(fb_bytes, __array_get(fb_cb, 1));
    push(fb_bytes, __array_get(fb_cb, 2));
    push(fb_bytes, __array_get(fb_cb, 3));

    // Write entries
    let fb_i = 0;
    while fb_i < 32768 {
        let fb_rc = __act_get(fb_i + FB_COUNT_OFFSET);
        if fb_rc > 0 {
            let fb_rs = __act_get(fb_i);
            let fb_hb = persist_u16_bytes(fb_i);
            let fb_sb = persist_u16_bytes(fb_rs);
            let fb_rb = persist_u16_bytes(fb_rc);
            push(fb_bytes, __array_get(fb_hb, 0));
            push(fb_bytes, __array_get(fb_hb, 1));
            push(fb_bytes, __array_get(fb_sb, 0));
            push(fb_bytes, __array_get(fb_sb, 1));
            push(fb_bytes, __array_get(fb_rb, 0));
            push(fb_bytes, __array_get(fb_rb, 1));
        };
        let fb_i = fb_i + 1;
    };

    __file_append_bytes(path, fb_bytes);
    return __array_get(fb_cnt, 0);
};

fn fb_load(path) {
    let fb_data = __file_read(path);
    if len(fb_data) < 8 { return 0; };
    if __char_code(char_at(fb_data, 0)) != 70 { return 0; };

    let fb_count = persist_read_u32(fb_data, 4);
    let fb_loaded = [0];
    let fb_off = 8;
    let fb_i = 0;
    while fb_i < fb_count {
        if fb_off + 6 > len(fb_data) { return __array_get(fb_loaded, 0); };
        let fb_h = persist_read_u16(fb_data, fb_off);
        let fb_rs = persist_read_u16(fb_data, fb_off + 2);
        let fb_rc = persist_read_u16(fb_data, fb_off + 4);
        __act_set(fb_h, fb_rs);
        __act_set(fb_h + FB_COUNT_OFFSET, fb_rc);
        let fb_off = fb_off + 6;
        let _ = __set_at(fb_loaded, 0, __array_get(fb_loaded, 0) + 1);
        let fb_i = fb_i + 1;
    };
    return __array_get(fb_loaded, 0);
};

emit "feedback loaded (BP16)";
