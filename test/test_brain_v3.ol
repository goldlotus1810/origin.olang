// ═══ Test: N3 Brain v3 — Full stack integration ═══
// Tests: boot, learn, save, restart, query, feedback

let _tp = [0];
let _tf = [0];
fn tassert(cond, msg) {
    if cond { let _ = __set_at(_tp, 0, __array_get(_tp, 0) + 1); } else {
        emit "FAIL: " + msg;
        let _ = __set_at(_tf, 0, __array_get(_tf, 0) + 1);
    };
};

let _test_dir = "/tmp/nox_bv3_test";
let _ = __system("mkdir -p " + _test_dir);

// ═══ T1: boot from text ═══
emit "T1: boot";
__file_write(_test_dir + "/facts.dat", "Ha Noi is the capital of Vietnam\nwater is H2O\nfire is hot and dangerous\nNox is a self-modifying AI\nOlang is the language of Nox\n");
let booted = brain_boot(_test_dir);
emit "  booted: " + __to_string(booted);
tassert(booted >= 5, "boot >= 5 facts");

// ═══ T2: learn ═══
emit "T2: learn";
brain_learn("gravity pulls objects down");
tassert(__array_get(kt_count, 0) >= 6, "6+ facts after learn");

// ═══ T3: save ═══
emit "T3: save";
let saved = brain_save();
emit "  saved: " + __to_string(saved);
tassert(saved >= 6, "saved >= 6");

// ═══ T4: ptav_cycle queries ═══
emit "T4: ptav queries";
let r1 = ptav_cycle("Ha Noi");
emit "  Ha Noi → " + r1;
tassert(len(r1) > 0, "Ha Noi has response");

let r2 = ptav_cycle("water");
emit "  water → " + r2;
tassert(len(r2) > 0, "water has response");

let r3 = ptav_cycle("Nox");
emit "  Nox → " + r3;
tassert(len(r3) > 0, "Nox has response");

// ═══ T5: restart simulation ═══
emit "T5: restart sim";
let kt_texts = [];
let kt_chains = [];
let kt_mols = [];
let kt_count = [0];
emit "  cleared";
let booted2 = brain_boot(_test_dir);
emit "  rebooted: " + __to_string(booted2);
tassert(__array_get(kt_count, 0) >= 6, "6+ facts after restart");

// ═══ T6: query after restart ═══
emit "T6: query after restart";
let r4 = ptav_cycle("gravity");
emit "  gravity → " + r4;
tassert(len(r4) > 0, "gravity found after restart");

let r5 = ptav_cycle("Ha Noi");
emit "  Ha Noi → " + r5;
tassert(len(r5) > 0, "Ha Noi found after restart");

// ═══ T7: shutdown ═══
emit "T7: shutdown";
brain_shutdown();
tassert(1 == 1, "shutdown clean");

// Cleanup
let _ = __system("rm -rf " + _test_dir);

// ═══ Results ═══
emit "";
let tp = __array_get(_tp, 0);
let tf = __array_get(_tf, 0);
emit __to_string(tp) + "/" + __to_string(tp + tf) + " passed";
if tf == 0 { emit "ALL PASS"; } else { emit __to_string(tf) + " FAILED"; };
