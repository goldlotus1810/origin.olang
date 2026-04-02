// ═══ Test: BP13 Persistence ═══
// Uses inline checks (no assert function — avoids VM scope issue in combined files)

let tp_p = [0];
let tp_f = [0];

emit "=== TEST BP13 Persistence ===";

// ── 1: Learn facts ──
kt_learn("Ha Noi is the capital of Vietnam");
kt_learn("fire is hot and can burn things");
kt_learn("water is essential for life");
kt_learn("the sun provides light and energy");
kt_learn("music can change your mood");
let tp_c1 = __array_get(kt_count, 0);
if tp_c1 == 5 { emit "  PASS: learned 5"; let _ = __set_at(tp_p, 0, __array_get(tp_p, 0) + 1); } else { emit "  FAIL: learn count=" + __to_string(tp_c1); let _ = __set_at(tp_f, 0, __array_get(tp_f, 0) + 1); };

// ── 2: Silk fire ──
let tp_m1 = kt_encode_mol("Ha Noi");
let tp_m2 = kt_encode_mol("Vietnam");
silk_fire(tp_m1, tp_m2);
silk_fire(tp_m1, tp_m2);
silk_fire(tp_m1, tp_m2);
let tp_w12 = silk_weight(tp_m1, tp_m2);
if tp_w12 > 0 { emit "  PASS: silk fired w=" + __to_string(tp_w12); let _ = __set_at(tp_p, 0, __array_get(tp_p, 0) + 1); } else { emit "  FAIL: silk not fired"; let _ = __set_at(tp_f, 0, __array_get(tp_f, 0) + 1); };

// ── 3: Save KnowTree binary ──
__system("mkdir -p /tmp/nox_bp13_test");
__file_write("/tmp/nox_bp13_test/knowtree.nkb", "");
let tp_ks = kt_save_binary("/tmp/nox_bp13_test/knowtree.nkb");
if tp_ks == 5 { emit "  PASS: kt_save_binary=5"; let _ = __set_at(tp_p, 0, __array_get(tp_p, 0) + 1); } else { emit "  FAIL: kt_save=" + __to_string(tp_ks); let _ = __set_at(tp_f, 0, __array_get(tp_f, 0) + 1); };

// ── 4: Verify NKB magic ──
let tp_kd = __file_read("/tmp/nox_bp13_test/knowtree.nkb");
let tp_mg = __char_code(char_at(tp_kd, 0));
if tp_mg == 78 { emit "  PASS: NKB magic=N"; let _ = __set_at(tp_p, 0, __array_get(tp_p, 0) + 1); } else { emit "  FAIL: magic=" + __to_string(tp_mg); let _ = __set_at(tp_f, 0, __array_get(tp_f, 0) + 1); };

let tp_nc = persist_read_u32(tp_kd, 4);
if tp_nc == 5 { emit "  PASS: NKB count=5"; let _ = __set_at(tp_p, 0, __array_get(tp_p, 0) + 1); } else { emit "  FAIL: NKB count=" + __to_string(tp_nc); let _ = __set_at(tp_f, 0, __array_get(tp_f, 0) + 1); };

// ── 5: Save silk ──
__file_write("/tmp/nox_bp13_test/silk.slk", "");
let tp_ss = silk_save("/tmp/nox_bp13_test/silk.slk");
if tp_ss > 0 { emit "  PASS: silk_save=" + __to_string(tp_ss); let _ = __set_at(tp_p, 0, __array_get(tp_p, 0) + 1); } else { emit "  FAIL: silk_save=0"; let _ = __set_at(tp_f, 0, __array_get(tp_f, 0) + 1); };

// ── 6: Verify SLK magic ──
let tp_sd = __file_read("/tmp/nox_bp13_test/silk.slk");
let tp_sm = __char_code(char_at(tp_sd, 0));
if tp_sm == 83 { emit "  PASS: SLK magic=S"; let _ = __set_at(tp_p, 0, __array_get(tp_p, 0) + 1); } else { emit "  FAIL: SLK magic=" + __to_string(tp_sm); let _ = __set_at(tp_f, 0, __array_get(tp_f, 0) + 1); };

// ── 7: Load KnowTree ──
let tp_before = __array_get(kt_count, 0);
let tp_kl = kt_load_binary("/tmp/nox_bp13_test/knowtree.nkb");
if tp_kl == 5 { emit "  PASS: kt_load=5"; let _ = __set_at(tp_p, 0, __array_get(tp_p, 0) + 1); } else { emit "  FAIL: kt_load=" + __to_string(tp_kl); let _ = __set_at(tp_f, 0, __array_get(tp_f, 0) + 1); };

let tp_after = __array_get(kt_count, 0);
if tp_after == tp_before + 5 { emit "  PASS: count+5"; let _ = __set_at(tp_p, 0, __array_get(tp_p, 0) + 1); } else { emit "  FAIL: after=" + __to_string(tp_after); let _ = __set_at(tp_f, 0, __array_get(tp_f, 0) + 1); };

// ── 8: Silk load restore ──
let tp_sh = silk_hash(tp_m1, tp_m2);
__mx_w(tp_sh, 0);
let tp_z = silk_weight(tp_m1, tp_m2);
if tp_z == 0 { emit "  PASS: silk zeroed"; let _ = __set_at(tp_p, 0, __array_get(tp_p, 0) + 1); } else { emit "  FAIL: not zeroed"; let _ = __set_at(tp_f, 0, __array_get(tp_f, 0) + 1); };

let tp_sl = silk_load("/tmp/nox_bp13_test/silk.slk");
let tp_wr = silk_weight(tp_m1, tp_m2);
if tp_wr == tp_w12 { emit "  PASS: silk restored w=" + __to_string(tp_wr); let _ = __set_at(tp_p, 0, __array_get(tp_p, 0) + 1); } else { emit "  FAIL: restored=" + __to_string(tp_wr) + " expected=" + __to_string(tp_w12); let _ = __set_at(tp_f, 0, __array_get(tp_f, 0) + 1); };

// ── 9: WAL ──
__file_write("/tmp/nox_bp13_test/test.wal", "");
wal_append("/tmp/nox_bp13_test/test.wal", 1, 100, 500);
wal_append("/tmp/nox_bp13_test/test.wal", 2, 0, 5);
let tp_wd = __file_read("/tmp/nox_bp13_test/test.wal");
if len(tp_wd) == 10 { emit "  PASS: WAL 10 bytes"; let _ = __set_at(tp_p, 0, __array_get(tp_p, 0) + 1); } else { emit "  FAIL: WAL len=" + __to_string(len(tp_wd)); let _ = __set_at(tp_f, 0, __array_get(tp_f, 0) + 1); };

// ═══ RESULTS ═══
emit "";
let tp_pp = __array_get(tp_p, 0);
let tp_ff = __array_get(tp_f, 0);
emit "RESULT: " + __to_string(tp_pp) + "/" + __to_string(tp_pp + tp_ff) + " passed";
if tp_ff == 0 { emit "ALL PASS"; };
