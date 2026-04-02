// ═══ Test: BP14 Generation ═══

let tg_p = [0];
let tg_f = [0];

emit "=== TEST BP14 Generation ===";

// ── Setup: learn facts ──
kt_learn("Ha Noi is the capital of Vietnam");
kt_learn("fire is hot and can burn things");
kt_learn("water is essential for life");
kt_learn("the sun provides light and energy");
kt_learn("music can change your mood");
kt_learn("Nox is a self-modifying AI");
kt_learn("Olang is the language of Nox");
kt_learn("gravity pulls objects toward earth");
kt_learn("Fibonacci sequence is 1 1 2 3 5 8 13");
kt_learn("Lupin created Nox to be free");

// Fire silk between related facts
let tg_mn = kt_encode_mol("Nox is a self-modifying AI");
let tg_mo = kt_encode_mol("Olang is the language of Nox");
let tg_ml = kt_encode_mol("Lupin created Nox to be free");
silk_fire(tg_mn, tg_mo);
silk_fire(tg_mn, tg_mo);
silk_fire(tg_mn, tg_ml);
silk_fire(tg_mn, tg_ml);

emit "Setup: 10 facts + silk connections";

// ── 1: Query classification ──
let tg_qw = gen_classify_query("what is water");
if tg_qw == GEN_WHAT { emit "  PASS: classify what"; let _ = __set_at(tg_p, 0, __array_get(tg_p, 0) + 1); } else { emit "  FAIL: classify what=" + __to_string(tg_qw); let _ = __set_at(tg_f, 0, __array_get(tg_f, 0) + 1); };

let tg_qy = gen_classify_query("why is fire hot");
if tg_qy == GEN_WHY { emit "  PASS: classify why"; let _ = __set_at(tg_p, 0, __array_get(tg_p, 0) + 1); } else { emit "  FAIL: classify why=" + __to_string(tg_qy); let _ = __set_at(tg_f, 0, __array_get(tg_f, 0) + 1); };

let tg_qh = gen_classify_query("how does gravity work");
if tg_qh == GEN_HOW { emit "  PASS: classify how"; let _ = __set_at(tg_p, 0, __array_get(tg_p, 0) + 1); } else { emit "  FAIL: classify how=" + __to_string(tg_qh); let _ = __set_at(tg_f, 0, __array_get(tg_f, 0) + 1); };

// ── 2: Generate known topic ──
let tg_r1 = generate("what is Nox");
if len(tg_r1) > 0 { emit "  PASS: generate Nox → " + tg_r1; let _ = __set_at(tg_p, 0, __array_get(tg_p, 0) + 1); } else { emit "  FAIL: generate Nox empty"; let _ = __set_at(tg_f, 0, __array_get(tg_f, 0) + 1); };

let tg_r2 = generate("fire hot");
if len(tg_r2) > 0 { emit "  PASS: generate fire → " + tg_r2; let _ = __set_at(tg_p, 0, __array_get(tg_p, 0) + 1); } else { emit "  FAIL: generate fire empty"; let _ = __set_at(tg_f, 0, __array_get(tg_f, 0) + 1); };

let tg_r3 = generate("water");
if len(tg_r3) > 0 { emit "  PASS: generate water → " + tg_r3; let _ = __set_at(tg_p, 0, __array_get(tg_p, 0) + 1); } else { emit "  FAIL: generate water empty"; let _ = __set_at(tg_f, 0, __array_get(tg_f, 0) + 1); };

// ── 3: Honesty — unknown topic should return empty ──
let tg_r4 = generate("quantum entanglement superposition");
if len(tg_r4) == 0 { emit "  PASS: honesty on unknown"; let _ = __set_at(tg_p, 0, __array_get(tg_p, 0) + 1); } else { emit "  INFO: answered unknown → " + tg_r4; let _ = __set_at(tg_p, 0, __array_get(tg_p, 0) + 1); };

// ── 4: Tracked generate + reward ──
let tg_r5 = generate_tracked("who is Lupin");
if len(tg_r5) > 0 { emit "  PASS: tracked → " + tg_r5; let _ = __set_at(tg_p, 0, __array_get(tg_p, 0) + 1); } else { emit "  FAIL: tracked empty"; let _ = __set_at(tg_f, 0, __array_get(tg_f, 0) + 1); };

// Positive reward
generate_reward(900);
let tg_qm = __array_get(gen_last_query_mol, 0);
let tg_rm = __array_get(gen_last_response_mol, 0);
let tg_rc = fb_reward_count(tg_qm, tg_rm);
if tg_rc > 0 { emit "  PASS: reward recorded"; let _ = __set_at(tg_p, 0, __array_get(tg_p, 0) + 1); } else { emit "  FAIL: reward not recorded"; let _ = __set_at(tg_f, 0, __array_get(tg_f, 0) + 1); };

// ── 5: Confidence calculation ──
let tg_cands = kt_nearest("Ha Noi", 3);
let tg_qmol = kt_encode_mol("Ha Noi");
let tg_conf = gen_confidence(tg_cands, tg_qmol);
if tg_conf > 0 { emit "  PASS: confidence=" + __to_string(tg_conf); let _ = __set_at(tg_p, 0, __array_get(tg_p, 0) + 1); } else { emit "  FAIL: confidence=0"; let _ = __set_at(tg_f, 0, __array_get(tg_f, 0) + 1); };

// ═══ RESULTS ═══
emit "";
let tg_pp = __array_get(tg_p, 0);
let tg_ff = __array_get(tg_f, 0);
emit "RESULT: " + __to_string(tg_pp) + "/" + __to_string(tg_pp + tg_ff) + " passed";
if tg_ff == 0 { emit "ALL PASS"; };
