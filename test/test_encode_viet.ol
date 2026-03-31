// Test Vietnamese encoding — compose produces meaningful P_weight
let ok = 1;
let chain_vn = chain_encode("Viet Nam");
if len(chain_vn) < 2 { let ok = 0; emit "FAIL: chain too short"; };
let mol_vn = compose(chain_vn);
if mol_vn == 0 { let ok = 0; emit "FAIL: mol=0"; };
let mol_en = compose(chain_encode("English"));
if mol_vn == mol_en { let ok = 0; emit "FAIL: same mol"; };
if ok == 1 { emit "PASS"; };
