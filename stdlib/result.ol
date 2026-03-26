fn ok(v) { return { tag: "ok", val: v }; };
fn err(e) { return { tag: "err", val: e }; };
fn is_ok(r) { return r.tag == "ok"; };
fn is_err(r) { return r.tag == "err"; };
fn unwrap(r) { if r.tag == "ok" { return r.val; }; __throw("unwrap on err: " + __to_string(r.val)); };
fn unwrap_or(r, default) { if r.tag == "ok" { return r.val; }; return default; };
fn map_ok(r, f) { if r.tag == "ok" { return ok(f(r.val)); }; return r; };
