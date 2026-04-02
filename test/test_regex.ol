import "../stdlib/regex.ol";

let _p = [0]; let _f = [0];
fn ok(c,m){if c{_p[0]=_p[0]+1;}else{emit "FAIL: "+m;_f[0]=_f[0]+1;};};

emit "T1: literal match";
ok(re_test("hello", "hello world") == 1, "hello in hello world");
ok(re_test("xyz", "hello world") == 0, "xyz not in hello world");

emit "T2: dot (any char)";
ok(re_test("h.llo", "hello") == 1, "h.llo matches hello");
ok(re_test("h.llo", "hxllo") == 1, "h.llo matches hxllo");

emit "T3: star (zero or more)";
ok(re_test("ab*c", "ac") == 1, "ab*c matches ac");
ok(re_test("ab*c", "abc") == 1, "ab*c matches abc");
ok(re_test("ab*c", "abbc") == 1, "ab*c matches abbc");

emit "T4: plus (one or more)";
ok(re_test("ab+c", "ac") == 0, "ab+c no match ac");
ok(re_test("ab+c", "abc") == 1, "ab+c matches abc");
ok(re_test("ab+c", "abbc") == 1, "ab+c matches abbc");

emit "T5: question (zero or one)";
ok(re_test("colou?r", "color") == 1, "colou?r matches color");
ok(re_test("colou?r", "colour") == 1, "colou?r matches colour");

emit "T6: digit class";
ok(re_test("\\d+", "abc123") == 1, "\\d+ finds digits");
ok(re_test("\\d+", "abcdef") == 0, "\\d+ no digits");

emit "T7: partial match";
ok(re_test("world", "hello world") == 1, "world in hello world");
ok(re_test("ell", "hello") == 1, "ell in hello");

emit "";
emit __to_string(_p[0]) + "/" + __to_string(_p[0]+_f[0]) + " passed";
if _f[0] == 0 { emit "ALL PASS"; };
