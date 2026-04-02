import "../stdlib/json.ol";
import "../stdlib/http.ol";
let resp = http_get("http://127.0.0.1:18094/api");
emit "status=" + __to_string(resp.status);
emit "error=" + resp.error;
emit "bodylen=" + __to_string(len(resp.body));
if len(resp.body) > 2 {
    emit "body=" + resp.body;
    let data = parse_json(resp.body);
    emit "msg=" + __dict_get(data, "msg");
    emit "val=" + __to_string(__dict_get(data, "val"));
    emit "SUCCESS";
};
