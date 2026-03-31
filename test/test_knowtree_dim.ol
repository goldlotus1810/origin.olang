// Test G5 KnowTree — bucket structure + nearest
kt_learn("nuoc soi o 100 do C");
kt_learn("bang tan o 0 do C");
kt_learn("Olang la ngon ngu lap trinh");
let _n = kt_nearest(_kt_real_mol("nhiet do nuoc"));
if len(_n) > 0 { emit "PASS"; } else { emit "FAIL: nearest empty"; };
