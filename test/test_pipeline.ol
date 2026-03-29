// Test HomeOS Intelligence Pipeline — 14 DNA mechanisms
let _tp_ok = [1];
let _tp_err = [];

// Seed knowledge
kt_learn("Ha Noi la thu do cua Viet Nam");
kt_learn("Trai Dat quay quanh Mat Troi mat 365 ngay");
kt_learn("Olang tu compile chinh minh khong can dependency");
kt_learn("khi nguoi ta buon nen lang nghe va dong cam");
kt_learn("vui qua toi yeu cuoc song");

// Test __exp and __log2 builtins
let _tp_e1 = __exp(0);
if _tp_e1 != 1 { let _ = __set_at(_tp_ok, 0, 0); push(_tp_err, "exp(0) != 1"); };
let _tp_l1 = __log2(8);
if _tp_l1 != 3 { let _ = __set_at(_tp_ok, 0, 0); push(_tp_err, "log2(8) != 3"); };

// Test homeostasis
let _tp_m1 = _kt_fact_mol_compute("Ha Noi");
let _tp_m2 = _kt_fact_mol_compute("Ha Noi la thu do");
let _tp_h = homeostasis(_tp_m1, _tp_m2);
emit "homeostasis: " + _tp_h.mode + " energy=" + __to_string(_tp_h.energy);

// Test compose
let _tp_mols = [_tp_m1, _tp_m2];
let _tp_comp = compose(_tp_mols);
emit "compose: " + __to_string(_tp_comp);
if _tp_comp == 0 { let _ = __set_at(_tp_ok, 0, 0); push(_tp_err, "compose == 0"); };

// Test lambda_gate
let _tp_lg = lambda_gate(800);
emit "lambda(800): " + __to_string(_tp_lg);

// Test immune_select
let _tp_sel = immune_select(_tp_m1);
emit "immune: " + __to_string(len(_tp_sel.facts)) + " facts, entropy=" + __to_string(_tp_sel.entropy);

// Test dna_repair
let _tp_rep = dna_repair(_tp_comp, _tp_m1, 3);
emit "repair: " + __to_string(_tp_rep);

// Test full pipeline — knowledge query
let _tp_r1 = pipeline("Ha Noi la gi?");
emit "pipeline(Ha Noi): " + _tp_r1;
if len(_tp_r1) < 5 { let _ = __set_at(_tp_ok, 0, 0); push(_tp_err, "pipeline empty"); };

// Test pipeline — greeting
let _tp_r2 = pipeline("chao ban");
emit "pipeline(chao): " + _tp_r2;

// Test pipeline — emotion
let _tp_r3 = pipeline("toi rat buon");
emit "pipeline(buon): " + _tp_r3;

// Test pipeline — unknown
let _tp_r4 = pipeline("quantum entanglement theory");
emit "pipeline(unknown): " + _tp_r4;

emit pipeline_stats();

if __array_get(_tp_ok, 0) == 1 { if len(_tp_err) == 0 { emit "PASS"; } else { emit "FAIL " + __to_string(len(_tp_err)); let _ei = 0; while _ei < len(_tp_err) { emit "  " + __array_get(_tp_err, _ei); let _ei = _ei + 1; }; }; } else { emit "FAIL"; };
