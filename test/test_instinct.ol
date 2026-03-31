// Test G9 Instincts — pure 5D math
kt_learn("Ha Noi la thu do cua Viet Nam");
kt_learn("Olang la ngon ngu Lupin tao ra");
let _h = instinct_honesty(_kt_real_mol("Ha Noi"));
if _h > 0 { emit "PASS"; } else { emit "FAIL: honesty=0"; };
