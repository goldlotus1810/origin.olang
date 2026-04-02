// ═══ Test: BP16 Feedback — UCB1 + ACT-R utility ═══

let tf_p = [0];
let tf_f = [0];

emit "=== TEST BP16 Feedback ===";

// ── 1: Learn some facts for mols ──
kt_learn("cat is a pet animal");
kt_learn("dog is a loyal friend");
kt_learn("fish lives in water");

let tf_cat = kt_encode_mol("cat");
let tf_dog = kt_encode_mol("dog");
let tf_fish = kt_encode_mol("fish");

// Fire silk edges
silk_fire(tf_cat, tf_dog);
silk_fire(tf_cat, tf_fish);

// ── 2: Initial reward state = 0 ──
let tf_rs = fb_reward_sum(tf_cat, tf_dog);
if tf_rs == 0 { emit "  PASS: initial reward_sum=0"; let _ = __set_at(tf_p, 0, __array_get(tf_p, 0) + 1); } else { emit "  FAIL: initial rs=" + __to_string(tf_rs); let _ = __set_at(tf_f, 0, __array_get(tf_f, 0) + 1); };

let tf_rc = fb_reward_count(tf_cat, tf_dog);
if tf_rc == 0 { emit "  PASS: initial reward_count=0"; let _ = __set_at(tf_p, 0, __array_get(tf_p, 0) + 1); } else { emit "  FAIL: initial rc=" + __to_string(tf_rc); let _ = __set_at(tf_f, 0, __array_get(tf_f, 0) + 1); };

// ── 3: Positive reward ──
let tf_w_before = silk_weight(tf_cat, tf_dog);
fb_update(tf_cat, tf_dog, 800);
let tf_rs2 = fb_reward_sum(tf_cat, tf_dog);
if tf_rs2 == 800 { emit "  PASS: reward_sum=800"; let _ = __set_at(tf_p, 0, __array_get(tf_p, 0) + 1); } else { emit "  FAIL: rs=" + __to_string(tf_rs2); let _ = __set_at(tf_f, 0, __array_get(tf_f, 0) + 1); };

let tf_rc2 = fb_reward_count(tf_cat, tf_dog);
if tf_rc2 == 1 { emit "  PASS: reward_count=1"; let _ = __set_at(tf_p, 0, __array_get(tf_p, 0) + 1); } else { emit "  FAIL: rc=" + __to_string(tf_rc2); let _ = __set_at(tf_f, 0, __array_get(tf_f, 0) + 1); };

// ── 4: Silk weight changed by ACT-R update ──
let tf_w_after = silk_weight(tf_cat, tf_dog);
if tf_w_after != tf_w_before { emit "  PASS: weight changed " + __to_string(tf_w_before) + " -> " + __to_string(tf_w_after); let _ = __set_at(tf_p, 0, __array_get(tf_p, 0) + 1); } else { emit "  FAIL: weight unchanged"; let _ = __set_at(tf_f, 0, __array_get(tf_f, 0) + 1); };

// ── 5: Negative reward reduces weight ──
let tf_w_pre_neg = silk_weight(tf_cat, tf_fish);
fb_update(tf_cat, tf_fish, 0);
let tf_w_post_neg = silk_weight(tf_cat, tf_fish);
if tf_w_post_neg < tf_w_pre_neg { emit "  PASS: negative reward reduced weight"; let _ = __set_at(tf_p, 0, __array_get(tf_p, 0) + 1); } else { emit "  FAIL: neg w=" + __to_string(tf_w_post_neg); let _ = __set_at(tf_f, 0, __array_get(tf_f, 0) + 1); };

// ── 6: UCB1 — unvisited edge = infinity ──
let tf_ucb_new = fb_ucb1(tf_dog, tf_fish, 10);
if tf_ucb_new == 99999 { emit "  PASS: UCB1 unvisited=99999"; let _ = __set_at(tf_p, 0, __array_get(tf_p, 0) + 1); } else { emit "  FAIL: ucb_new=" + __to_string(tf_ucb_new); let _ = __set_at(tf_f, 0, __array_get(tf_f, 0) + 1); };

// ── 7: UCB1 — visited edge has finite score ──
let tf_ucb_vis = fb_ucb1(tf_cat, tf_dog, 10);
if tf_ucb_vis < 99999 { emit "  PASS: UCB1 visited=" + __to_string(tf_ucb_vis); let _ = __set_at(tf_p, 0, __array_get(tf_p, 0) + 1); } else { emit "  FAIL: ucb_vis infinite"; let _ = __set_at(tf_f, 0, __array_get(tf_f, 0) + 1); };

// ── 8: UCB1 select ──
let tf_cands = [];
push(tf_cands, tf_dog);
push(tf_cands, tf_fish);
let tf_sel = fb_select(tf_cands, tf_cat, 10);
emit "  INFO: selected index=" + __to_string(tf_sel);
if tf_sel >= 0 { emit "  PASS: fb_select returned valid index"; let _ = __set_at(tf_p, 0, __array_get(tf_p, 0) + 1); } else { emit "  FAIL: fb_select"; let _ = __set_at(tf_f, 0, __array_get(tf_f, 0) + 1); };

// ── 9: Reward path ──
let tf_path = [];
push(tf_path, tf_cat);
push(tf_path, tf_dog);
push(tf_path, tf_fish);
fb_reward_path(tf_path, 700);
let tf_rp1 = fb_reward_count(tf_cat, tf_dog);
let tf_rp2 = fb_reward_count(tf_dog, tf_fish);
if tf_rp1 > 1 { emit "  PASS: path reward cat-dog counted"; let _ = __set_at(tf_p, 0, __array_get(tf_p, 0) + 1); } else { emit "  FAIL: path rc1=" + __to_string(tf_rp1); let _ = __set_at(tf_f, 0, __array_get(tf_f, 0) + 1); };
if tf_rp2 > 0 { emit "  PASS: path reward dog-fish counted"; let _ = __set_at(tf_p, 0, __array_get(tf_p, 0) + 1); } else { emit "  FAIL: path rc2=" + __to_string(tf_rp2); let _ = __set_at(tf_f, 0, __array_get(tf_f, 0) + 1); };

// ── 10: Calibration ──
fb_calibrate_record(800, 1);
fb_calibrate_record(800, 1);
fb_calibrate_record(800, 0);
fb_calibrate_record(800, 1);
fb_calibrate_record(800, 1);
let tf_cal = fb_calibrated_confidence(800);
if tf_cal == 800 { emit "  PASS: calibrated 4/5=800"; let _ = __set_at(tf_p, 0, __array_get(tf_p, 0) + 1); } else { emit "  FAIL: cal=" + __to_string(tf_cal); let _ = __set_at(tf_f, 0, __array_get(tf_f, 0) + 1); };

// ── 11: Save/Load feedback ──
__system("mkdir -p /tmp/nox_fb_test");
__file_write("/tmp/nox_fb_test/feedback.fbk", "");
let tf_fs = fb_save("/tmp/nox_fb_test/feedback.fbk");
if tf_fs > 0 { emit "  PASS: fb_save=" + __to_string(tf_fs); let _ = __set_at(tf_p, 0, __array_get(tf_p, 0) + 1); } else { emit "  FAIL: fb_save=0"; let _ = __set_at(tf_f, 0, __array_get(tf_f, 0) + 1); };

let tf_fd = __file_read("/tmp/nox_fb_test/feedback.fbk");
let tf_fm = __char_code(char_at(tf_fd, 0));
if tf_fm == 70 { emit "  PASS: FBK magic=F"; let _ = __set_at(tf_p, 0, __array_get(tf_p, 0) + 1); } else { emit "  FAIL: magic=" + __to_string(tf_fm); let _ = __set_at(tf_f, 0, __array_get(tf_f, 0) + 1); };

// ═══ RESULTS ═══
emit "";
let tf_pp = __array_get(tf_p, 0);
let tf_ff = __array_get(tf_f, 0);
emit "RESULT: " + __to_string(tf_pp) + "/" + __to_string(tf_pp + tf_ff) + " passed";
if tf_ff == 0 { emit "ALL PASS"; };
