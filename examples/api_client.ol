// ═══ Nox API Client — Fetch JSON from web APIs ═══
// Demonstrates: import, HTTP, JSON, regex, closures, structs, for/match

import "../stdlib/json.ol";
import "../stdlib/http.ol";
import "../stdlib/regex.ol";

// ═══ Fetch and display IP info ═══
fn fetch_ip_info() {
    emit "Fetching IP info...";
    let resp = http_get("http://ip-api.com/json/");
    if resp.status == 200 {
        let data = parse_json(resp.body);
        emit "  IP: " + __dict_get(data, "query");
        emit "  Country: " + __dict_get(data, "country");
        emit "  City: " + __dict_get(data, "city");
        emit "  ISP: " + __dict_get(data, "isp");
        return data;
    } else {
        emit "  Failed: " + resp.error;
        return {};
    };
};

// ═══ Simple HTTP API test ═══
fn test_api(url, name) {
    emit "Testing " + name + "...";
    let t1 = __time_now();
    let resp = http_get(url);
    let t2 = __time_now();
    let ms = __round(t2 - t1);
    emit "  Status: " + __to_string(resp.status) + " (" + __to_string(ms) + "ms)";
    if resp.status == 200 {
        emit "  Body length: " + __to_string(len(resp.body));
        if re_test("\\{", resp.body) {
            emit "  (JSON response)";
        };
    };
    return resp;
};

// ═══ Main ═══
emit "═══ Nox API Client ═══";
emit "Features: HTTP + JSON + Regex + Closures + Typed Arrays";
emit "";

// Test connectivity
test_api("http://httpbin.org/get", "httpbin");
emit "";

// Fetch IP info
fetch_ip_info();
emit "";

// Benchmark: create typed array, compute dot product
emit "Benchmark: f64 dot product";
let N = 10000;
let a = __f64_new(N);
let b = __f64_new(N);
let i = 0;
while i < N {
    __f64_set(a, i, __sin(i * 0.01));
    __f64_set(b, i, __cos(i * 0.01));
    let i = i + 1;
};
let t1 = __time_now();
let dot = __f64_dot(a, b, N);
let t2 = __time_now();
emit "  dot(sin, cos, " + __to_string(N) + ") = " + __to_string(__round(dot * 1000) / 1000);
emit "  Time: " + __to_string(__round(t2 - t1)) + "ms";

emit "";
emit "═══ Done ═══";
