import "../stdlib/json.ol";
import "../stdlib/http.ol";
emit "Fetching...";
let resp = http_get("http://127.0.0.1:18082/hello");
emit "status: " + __to_string(resp.status);
if resp.status == 200 {
    emit "body: " + resp.body;
    let data = parse_json(resp.body);
    emit "msg: " + __dict_get(data, "msg");
    emit "path: " + __dict_get(data, "path");
    emit "SUCCESS";
} else {
    emit "error: " + resp.error;
};
