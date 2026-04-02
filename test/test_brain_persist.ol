// ═══ Test: Brain + Persist Integration ═══
// Simulates: boot → learn → save → "restart" → boot → query

let _pass = [0];
let _fail = [0];
fn assert_true(cond, msg) {
    if cond { let _ = __set_at(_pass, 0, __array_get(_pass, 0) + 1); } else {
        emit "FAIL: " + msg;
        let _ = __set_at(_fail, 0, __array_get(_fail, 0) + 1);
    };
};

let _test_dir = "/tmp/nox_test_persist";
let _ = __system("mkdir -p " + _test_dir);

// ═══ Test 1: brain_boot with text fallback ═══
emit "T1: boot from text fallback...";
// Create a simple facts file
__file_write(_test_dir + "/facts.dat", "Ha Noi la thu do cua Viet Nam\nOlang la ngon ngu cua Nox\nwater is H2O\n");
let n = brain_boot(_test_dir);
assert_true(n >= 3, "T1: loaded >= 3 facts from text");
emit "  loaded: " + __to_string(n);

// Verify query works
let r = kt_query("Ha Noi");
emit "  query 'Ha Noi' → " + r;
assert_true(len(r) > 0, "T1: query Ha Noi returns result");

// ═══ Test 2: brain_save creates binary ═══
emit "T2: save to binary...";
let saved = brain_save();
emit "  saved: " + __to_string(saved);
assert_true(saved >= 3, "T2: saved >= 3");

// Verify binary file exists
let nkb = __file_read(_test_dir + "/knowtree.nkb");
assert_true(len(nkb) > 8, "T2: NKB file has content");
// Check magic bytes
assert_true(__char_code(char_at(nkb, 0)) == 78, "T2: NKB magic N");
assert_true(__char_code(char_at(nkb, 1)) == 75, "T2: NKB magic K");
assert_true(__char_code(char_at(nkb, 2)) == 66, "T2: NKB magic B");

// ═══ Test 3: Learn more, fire silk, then save ═══
emit "T3: learn + silk + save...";
kt_learn("fire is hot and dangerous");
kt_learn("the sun provides light and energy");
let mol_fire = kt_encode_mol("fire is hot and dangerous");
let mol_sun = kt_encode_mol("the sun provides light and energy");
silk_fire(mol_fire, mol_sun);
silk_fire(mol_fire, mol_sun);
let sw1 = silk_weight(mol_fire, mol_sun);
emit "  silk fire-sun: " + __to_string(sw1);
assert_true(sw1 > 0, "T3: silk fired");
let saved2 = brain_save();
emit "  saved: " + __to_string(saved2);
assert_true(saved2 >= 5, "T3: saved >= 5 total");

// ═══ Test 4: Simulate restart (clear + boot from binary) ═══
emit "T4: simulate restart...";
// Clear everything
let kt_texts = [];
let kt_chains = [];
let kt_mols = [];
let kt_count = [0];
emit "  cleared. facts=" + __to_string(__array_get(kt_count, 0));

// Boot from binary (should use NKB this time, not facts.dat)
let n2 = brain_boot(_test_dir);
emit "  booted: " + __to_string(n2) + " facts+silk";
assert_true(__array_get(kt_count, 0) >= 5, "T4: >= 5 facts after restart");

// ═══ Test 5: Query after restart ═══
emit "T5: query after restart...";
let r1 = kt_query("Ha Noi");
emit "  'Ha Noi' → " + r1;
assert_true(len(r1) > 0, "T5: Ha Noi found after restart");

let r2 = kt_query("Olang");
emit "  'Olang' → " + r2;
assert_true(len(r2) > 0, "T5: Olang found after restart");

let r3 = kt_query("fire");
emit "  'fire' → " + r3;
assert_true(len(r3) > 0, "T5: fire found after restart");

// ═══ Test 6: Silk survived restart ═══
emit "T6: silk after restart...";
let mol_fire2 = kt_encode_mol("fire is hot and dangerous");
let mol_sun2 = kt_encode_mol("the sun provides light and energy");
let sw2 = silk_weight(mol_fire2, mol_sun2);
emit "  silk fire-sun after restart: " + __to_string(sw2);
assert_true(sw2 > 0, "T6: silk survived restart");
assert_true(sw2 == sw1, "T6: silk weight unchanged");

// ═══ Test 7: Auto-save (simulate 20 turns) ═══
emit "T7: auto-save after 20 turns...";
// Reset turn counter
let _ = __set_at(_persist_turn, 0, 0);
let _persist_interval = 5;  // reduce for test (5 instead of 20)
kt_learn("test auto save fact");
let i = 0;
while i < 5 {
    let _ = ptav_cycle("test query " + __to_string(i));
    let i = i + 1;
};
// After 5 turns with interval=5, should have auto-saved
// Verify by checking turn counter reset to 0
assert_true(__array_get(_persist_turn, 0) == 0, "T7: turn counter reset after auto-save");

// ═══ Results ═══
emit "";
emit "═══ RESULTS ═══";
let p = __array_get(_pass, 0);
let f = __array_get(_fail, 0);
emit __to_string(p) + "/" + __to_string(p + f) + " tests passed";
if f == 0 { emit "ALL PASS"; } else { emit __to_string(f) + " FAILED"; };

// Cleanup
let _ = __system("rm -rf " + _test_dir);
