import "../stdlib/json.ol";

let _p = [0]; let _f = [0];
fn ok(c,m){if c{_p[0]=_p[0]+1;}else{emit "FAIL: "+m;_f[0]=_f[0]+1;};};
fn str_eq(a,b){return len(a)==len(b) && (len(a)==0 || __str_index_of(a,b)==0);};

emit "T1: parse primitives";
ok(str_eq(parse_json("\"hello\""), "hello"), "parse string");
ok(parse_json("42") == 42, "parse int");
ok(parse_json("3.14") * 100 == 314, "parse float");
ok(parse_json("true") == 1, "parse true");
ok(parse_json("false") == 0, "parse false");
ok(parse_json("null") == 0, "parse null");

emit "T2: parse array";
let arr = parse_json("[1,2,3]");
ok(len(arr) == 3, "array len 3");
ok(arr[0] == 1, "arr[0]");
ok(arr[2] == 3, "arr[2]");

emit "T3: parse object";
let obj = parse_json("{\"name\":\"Nox\",\"age\":42}");
ok(str_eq(__dict_get(obj, "name"), "Nox"), "obj.name");
ok(__dict_get(obj, "age") == 42, "obj.age");

emit "T4: parse nested";
let nested = parse_json("{\"data\":[1,2],\"meta\":{\"ok\":1}}");
let data = __dict_get(nested, "data");
ok(len(data) == 2, "nested array");
ok(data[0] == 1, "nested val");

emit "T5: stringify number";
ok(str_eq(json_stringify(42), "42"), "str num");

emit "T6: stringify string";
ok(str_eq(json_stringify("hi"), "\"hi\""), "str string");

emit "T7: stringify array";
let a = [1, 2, 3];
let sa = json_stringify(a);
ok(str_eq(sa, "[1,2,3]"), "str array");

emit "T8: stringify object";
let o = {name: "Nox", ver: 1};
let so = json_stringify(o);
ok(__str_index_of(so, "\"name\"") >= 0, "has name key");
ok(__str_index_of(so, "\"Nox\"") >= 0, "has Nox quoted");
ok(__str_index_of(so, "\"ver\"") >= 0, "has ver key");

emit "T9: roundtrip";
let input = "{\"x\":10,\"y\":20}";
let parsed = parse_json(input);
ok(__dict_get(parsed, "x") == 10, "roundtrip x");
ok(__dict_get(parsed, "y") == 20, "roundtrip y");
let back = json_stringify(parsed);
ok(__str_index_of(back, "\"x\"") >= 0, "roundtrip back x");

emit "";
emit __to_string(_p[0]) + "/" + __to_string(_p[0]+_f[0]) + " passed";
if _f[0] == 0 { emit "ALL PASS"; };
