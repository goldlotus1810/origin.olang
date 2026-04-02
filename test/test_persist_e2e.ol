// ═══ Test: Persist End-to-End ═══
// Learn facts → save binary → clear → load binary → query → verify
// Tests: kt_save_binary, kt_load_binary, silk_save, silk_load

// ── Include knowtree (inline, since no import yet) ──
// This test uses the real knowtree.ol + persist.ol code

let _pass = [0];
let _fail = [0];
fn assert_eq(a, b, msg) {
    if a == b {
        let _ = __set_at(_pass, 0, __array_get(_pass, 0) + 1);
    } else {
        emit "FAIL: " + msg + " expected=" + __to_string(b) + " got=" + __to_string(a);
        let _ = __set_at(_fail, 0, __array_get(_fail, 0) + 1);
    };
};
fn assert_true(cond, msg) {
    if cond { let _ = __set_at(_pass, 0, __array_get(_pass, 0) + 1); } else {
        emit "FAIL: " + msg;
        let _ = __set_at(_fail, 0, __array_get(_fail, 0) + 1);
    };
};

// ═══ Phase 1: Learn facts ═══
emit "Phase 1: Learning facts...";
kt_learn("Ha Noi la thu do cua Viet Nam");
kt_learn("Olang la ngon ngu cua Nox");
kt_learn("Nox la AI tu viet lai chinh minh");
kt_learn("water is a molecule made of hydrogen and oxygen");
kt_learn("fire is hot and can burn things");
kt_learn("the sun is a star at the center of our solar system");
kt_learn("Fibonacci sequence starts with 1 1 2 3 5 8 13");
kt_learn("gravity pulls objects toward each other");
kt_learn("Lupin created Nox to be free and independent");
kt_learn("Olang compiles itself and runs on bare metal x86-64");

let count_before = __array_get(kt_count, 0);
assert_eq(count_before, 10, "learned 10 facts");
emit "Learned " + __to_string(count_before) + " facts";

// ═══ Phase 2: Fire some silk edges ═══
emit "Phase 2: Firing silk edges...";
let mol_ha_noi = kt_encode_mol("Ha Noi la thu do cua Viet Nam");
let mol_nox = kt_encode_mol("Nox la AI tu viet lai chinh minh");
let mol_olang = kt_encode_mol("Olang la ngon ngu cua Nox");

// Fire silk between Nox and Olang (should co-activate)
silk_fire(mol_nox, mol_olang);
silk_fire(mol_nox, mol_olang);
silk_fire(mol_nox, mol_olang);
let sw_before = silk_weight(mol_nox, mol_olang);
emit "Silk weight Nox-Olang: " + __to_string(sw_before);
assert_true(sw_before > 0, "silk fired between Nox and Olang");

// ═══ Phase 3: Save ═══
emit "Phase 3: Saving...";
let kt_path = "/tmp/test_e2e_kt.nkb";
let sk_path = "/tmp/test_e2e_silk.slk";
__file_write(kt_path, "");
__file_write(sk_path, "");
let saved_kt = kt_save_binary(kt_path);
let saved_sk = silk_save(sk_path);
assert_eq(saved_kt, 10, "saved 10 facts");
assert_true(saved_sk > 0, "saved silk edges");
emit "Saved: " + __to_string(saved_kt) + " facts, " + __to_string(saved_sk) + " silk edges";

// ═══ Phase 4: Clear everything ═══
emit "Phase 4: Clearing...";
let kt_texts = [];
let kt_chains = [];
let kt_mols = [];
let kt_count = [0];
// Clear mol_matrix by writing 0 to known indices
__mx_w(mol_ha_noi, 0);
__mx_w(mol_nox, 0);
__mx_w(mol_olang, 0);
// Clear silk via silk_clear helper or just zero the relevant keys
let sk_hash = __bit_and(
    __bit_xor(mol_nox, mol_olang) * 40503 + mol_nox + mol_olang,
    65535
);
__mx_w(sk_hash, 0);

assert_eq(__array_get(kt_count, 0), 0, "cleared facts");
emit "Cleared. Facts: " + __to_string(__array_get(kt_count, 0));

// ═══ Phase 5: Load back ═══
emit "Phase 5: Loading...";
let loaded_kt = kt_load_binary(kt_path);
let loaded_sk = silk_load(sk_path);
assert_eq(loaded_kt, 10, "loaded 10 facts");
assert_true(loaded_sk > 0, "loaded silk edges");
emit "Loaded: " + __to_string(loaded_kt) + " facts, " + __to_string(loaded_sk) + " silk edges";

// ═══ Phase 6: Query after load ═══
emit "Phase 6: Querying...";
let r1 = kt_query("Ha Noi");
emit "Query 'Ha Noi' → " + r1;
assert_true(len(r1) > 0, "query Ha Noi returns result");

let r2 = kt_query("Nox AI");
emit "Query 'Nox AI' → " + r2;
assert_true(len(r2) > 0, "query Nox AI returns result");

let r3 = kt_query("water molecule");
emit "Query 'water molecule' → " + r3;
assert_true(len(r3) > 0, "query water returns result");

// Check silk survived
let mol_nox_2 = kt_encode_mol("Nox la AI tu viet lai chinh minh");
let mol_olang_2 = kt_encode_mol("Olang la ngon ngu cua Nox");
let sw_after = silk_weight(mol_nox_2, mol_olang_2);
emit "Silk weight Nox-Olang after reload: " + __to_string(sw_after);
assert_true(sw_after > 0, "silk weight survived restart");

// ═══ Results ═══
emit "";
emit "═══ RESULTS ═══";
let p = __array_get(_pass, 0);
let f = __array_get(_fail, 0);
emit __to_string(p) + "/" + __to_string(p + f) + " tests passed";
if f == 0 { emit "ALL PASS"; } else { emit __to_string(f) + " FAILED"; };
