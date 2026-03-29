// Test KnowTree v3 — 5D Dimension Index + Emotion Encode + Decode
let _td_ok = [1];
let _td_err = [];
let _td_base = kt_fact_count();

// Learn facts with different emotional signatures
kt_learn("Trai Dat quay quanh Mat Troi mat 365 ngay");
kt_learn("Nuoc soi o 100 do C va dong bang o 0 do C");
kt_learn("Einstein phat minh thuyet tuong doi nam 1905");
kt_learn("khi nguoi ta buon nen lang nghe va dong cam");
kt_learn("vui qua di toi yeu cuoc song nay");
kt_learn("Olang tu compile chinh minh trong 1021 kilobyte");

let _td_new = kt_fact_count() - _td_base;
if _td_new != 6 { let _ = __set_at(_td_ok, 0, 0); push(_td_err, "new facts != 6"); };
emit "new facts: " + __to_string(_td_new) + " (base=" + __to_string(_td_base) + ")";

// Check dimension index populated
if len(__kt_fact_mol) < (_td_base + 6) { let _ = __set_at(_td_ok, 0, 0); push(_td_err, "fact_mol short"); };

// Verify emotional dimensions differ between happy/sad facts
let _td_mol_sad = kt_fact_mol_at(_td_base + 3);
let _td_mol_happy = kt_fact_mol_at(_td_base + 4);
let _td_v_sad = _kt_mol_v(_td_mol_sad);
let _td_v_happy = _kt_mol_v(_td_mol_happy);
let _td_a_sad = _kt_mol_a(_td_mol_sad);
let _td_a_happy = _kt_mol_a(_td_mol_happy);
emit "sad V=" + __to_string(_td_v_sad) + " A=" + __to_string(_td_a_sad) + " happy V=" + __to_string(_td_v_happy) + " A=" + __to_string(_td_a_happy);
if _td_v_sad == _td_v_happy { push(_td_err, "V same for sad/happy"); };

// Test kt_decode — emotional query
let _td_dec = kt_decode("buon qua lang nghe");
emit "decode buon: " + _td_dec.match + " " + __to_string(len(_td_dec.facts)) + " facts mol=" + __to_string(_td_dec.mol);
if len(_td_dec.facts) < 1 { let _ = __set_at(_td_ok, 0, 0); push(_td_err, "decode buon empty"); };

// Test kt_decode — science query
let _td_dec2 = kt_decode("vat ly khoa hoc");
emit "decode science: " + _td_dec2.match + " " + __to_string(len(_td_dec2.facts)) + " facts";

// Test kt_nearby — fact should find itself at distance 0
let _td_mol0 = kt_fact_mol_at(_td_base);
let _td_near = kt_nearby(_td_mol0, 2);
emit "nearby(r=2): " + __to_string(len(_td_near)) + " candidates";
if len(_td_near) > 0 {
    // Check if any result has distance 0 (exact self-match)
    let _td_has_zero = [0];
    let _td_ni = 0;
    while _td_ni < len(_td_near) {
        let _td_entry = __array_get(_td_near, _td_ni);
        if _td_entry.distance == 0 { let _ = __set_at(_td_has_zero, 0, 1); };
        let _td_ni = _td_ni + 1;
    };
    if __array_get(_td_has_zero, 0) == 0 { push(_td_err, "no dist=0 in nearby"); };
};

// Test path query
let _td_s0 = _kt_mol_s(_td_mol0);
let _td_v0 = _kt_mol_v(_td_mol0);
let _td_path = kt_get_path([0, _td_s0, 2, _td_v0]);
emit "path[S=" + __to_string(_td_s0) + ",V=" + __to_string(_td_v0) + "]: " + __to_string(len(_td_path));
if len(_td_path) < 1 { let _ = __set_at(_td_ok, 0, 0); push(_td_err, "path query empty"); };

// Stats
emit kt_stats();

if __array_get(_td_ok, 0) == 1 { if len(_td_err) == 0 { emit "PASS"; } else { emit "FAIL " + __to_string(len(_td_err)); let _ei = 0; while _ei < len(_td_err) { emit "  " + __array_get(_td_err, _ei); let _ei = _ei + 1; }; }; } else { emit "FAIL"; };
