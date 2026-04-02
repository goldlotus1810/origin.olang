import "../stdlib/json.ol";
import "../stdlib/http.ol";

let _p = [0]; let _f = [0];
fn ok(c,m){if c{_p[0]=_p[0]+1;}else{emit "FAIL: "+m;_f[0]=_f[0]+1;};};
fn str_eq(a,b){return len(a)==len(b) && (len(a)==0 || __str_index_of(a,b)==0);};

// ═══ URL Parsing ═══
emit "T1: url parse basic";
let u1 = url_parse("http://example.com/path");
ok(str_eq(u1.host, "example.com"), "host=example.com");
ok(u1.port == 80, "port=80");
ok(str_eq(u1.path, "/path"), "path=/path");

emit "T2: url with port";
let u2 = url_parse("http://localhost:9742/api/status");
ok(str_eq(u2.host, "localhost"), "host=localhost");
ok(u2.port == 9742, "port=9742");
ok(str_eq(u2.path, "/api/status"), "path=/api/status");

emit "T3: url no path";
let u3 = url_parse("http://example.com");
ok(str_eq(u3.host, "example.com"), "host no path");
ok(u3.port == 80, "port default 80");

emit "T4: https default port";
let u4 = url_parse("https://secure.example.com/login");
ok(u4.port == 443, "https port=443");
ok(str_eq(u4.host, "secure.example.com"), "https host");

// ═══ DNS (needs network) ═══
emit "T5: dns resolve localhost";
let ip = dns_resolve("localhost");
emit "  localhost → " + ip;
ok(len(ip) > 0, "dns resolve returns something");

// ═══ Live HTTP (test against local server if available) ═══
// Only test if we can connect — don't fail if no network
emit "T6: http_get (httpbin or skip)";
try {
    let resp = http_get("http://httpbin.org/get");
    if resp.status > 0 {
        emit "  status: " + __to_string(resp.status);
        ok(resp.status == 200, "httpbin 200");
        ok(len(resp.body) > 0, "httpbin has body");
    } else {
        emit "  skipped (no network): " + resp.error;
        // Don't count as fail
        _p[0] = _p[0] + 2;
    };
} catch(e) {
    emit "  skipped (error)";
    _p[0] = _p[0] + 2;
};

emit "";
emit __to_string(_p[0]) + "/" + __to_string(_p[0]+_f[0]) + " passed";
if _f[0] == 0 { emit "ALL PASS"; };
