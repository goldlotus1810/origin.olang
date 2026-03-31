// Test P_weight — 42 formula output validation
// Semantic checks: emoji=high V, math=high R, geometric=high S
let ok = 1;
let pw_a = p_weight(97);
if pw_a == 0 { let ok = 0; emit "FAIL: a=0"; };
let pw_emoji = p_weight(128512);
let v_emoji = (__floor(pw_emoji / 32)) % 8;
if v_emoji < 5 { let ok = 0; emit "FAIL: emoji V=" + __to_string(v_emoji); };
let pw_int = p_weight(8747);
let r_int = (__floor(pw_int / 256)) % 16;
if r_int < 8 { let ok = 0; emit "FAIL: integral R=" + __to_string(r_int); };
let pw_circle = p_weight(9679);
let s_circle = (__floor(pw_circle / 4096)) % 16;
if s_circle < 8 { let ok = 0; emit "FAIL: circle S=" + __to_string(s_circle); };
if ok == 1 { emit "PASS"; };
