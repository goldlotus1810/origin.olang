// Test 7 Instincts router
let _ti_ok = [1];
let _ti_err = [];

// Seed some knowledge for REFERENCE/QUESTION instincts
kt_learn("Trai Dat quay quanh Mat Troi mat 365 ngay");
kt_learn("Olang tu compile chinh minh trong 1021 kilobyte");
kt_learn("khi nguoi ta buon nen lang nghe va dong cam");

// 1. GREETING
let _r1 = instinct_route("chao ban");
if _r1.instinct != "GREETING" { let _ = __set_at(_ti_ok, 0, 0); push(_ti_err, "greeting: " + _r1.instinct); };
emit "chao ban → " + _r1.instinct;

// 2. META
let _r2 = instinct_route("ban la ai");
if _r2.instinct != "META" { let _ = __set_at(_ti_ok, 0, 0); push(_ti_err, "meta: " + _r2.instinct); };
emit "ban la ai → " + _r2.instinct;

// 3. QUESTION
let _r3 = instinct_route("Trai Dat la gi?");
if _r3.instinct != "QUESTION" { let _ = __set_at(_ti_ok, 0, 0); push(_ti_err, "question: " + _r3.instinct); };
emit "question → " + _r3.instinct;

// 4. LEARNING
let _r4 = instinct_route("fact: nuoc dong bang o 0 do C");
if _r4.instinct != "LEARNING" { let _ = __set_at(_ti_ok, 0, 0); push(_ti_err, "learning: " + _r4.instinct); };
emit "fact: → " + _r4.instinct;

// 5. REFERENCE
let _r5 = instinct_route("nho lai ve Olang");
if _r5.instinct != "REFERENCE" { let _ = __set_at(_ti_ok, 0, 0); push(_ti_err, "reference: " + _r5.instinct); };
emit "nho lai → " + _r5.instinct;

// 6. EMOTION (strong negative)
let _r6 = instinct_route("toi rat buon va so qua");
emit "buon so → " + _r6.instinct + " V=" + __to_string(_r6.v) + " A=" + __to_string(_r6.a);

// 7. Action: greeting
let _a1 = instinct_act(_r1, "chao ban");
emit "greet act: " + _a1;

// 8. Action: meta
let _a2 = instinct_act(_r2, "ban la ai");
emit "meta act: " + _a2;

// 9. Action: question with knowledge
let _a3 = instinct_act(_r3, "Trai Dat la gi?");
emit "question act: " + _a3;

if __array_get(_ti_ok, 0) == 1 { if len(_ti_err) == 0 { emit "PASS"; } else { emit "FAIL " + __to_string(len(_ti_err)); let _ei = 0; while _ei < len(_ti_err) { emit "  " + __array_get(_ti_err, _ei); let _ei = _ei + 1; }; }; } else { emit "FAIL"; };
