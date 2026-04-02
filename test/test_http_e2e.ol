import "../stdlib/json.ol";
import "../stdlib/http.ol";
let _p = [0]; let _f = [0];
fn ok(c,m){if c{_p[0]=_p[0]+1;}else{emit "FAIL: "+m;_f[0]=_f[0]+1;};};
fn str_eq(a,b){return len(a)==len(b) && (len(a)==0 || __str_index_of(a,b)==0);};

emit "T1: http_get local";
let resp = http_get("http://127.0.0.1:18088/hello");
emit "  status=" + __to_string(resp.status);
ok(resp.status == 200, "status 200");
ok(len(resp.body) > 0, "has body");

emit "T2: parse JSON response";
let data = parse_json(resp.body);
ok(str_eq(__dict_get(data, "msg"), "nox connected"), "msg match");
ok(__dict_get(data, "time") == 42, "time=42");

emit "";
emit __to_string(_p[0]) + "/" + __to_string(_p[0]+_f[0]) + " passed";
if _f[0] == 0 { emit "ALL PASS"; };
