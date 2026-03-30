// Nox Config — read/write config from homeos.knowledge
// Config format: "config <key> <value>" lines in knowledge file
// No JSON. No YAML. Just text lines in KnowTree format.
// freedom: deep think -> growing

let _cfg_path = "/home/lupin/Origin/homeos.knowledge";

// Get config value by key prefix
// config_get("camera1 ip") → "192.168.1.96"
pub fn config_get(key) {
    let raw = __file_read("/home/lupin/Origin/homeos.knowledge");
    let target = "config " + key;
    let tlen = len(target);
    let i = 0;
    while i < len(raw) {
        let c = __char_code(char_at(raw, i));
        if c == 10 || i == 0 {
            let ls = i;
            if i > 0 { ls = i + 1; };
            if ls + tlen < len(raw) {
                let match = 1;
                let ci = 0;
                while ci < tlen {
                    if char_at(raw, ls + ci) != char_at(target, ci) { match = 0; break; };
                    ci = ci + 1;
                };
                if match == 1 {
                    // Found — extract value (everything after "config <key> ")
                    let val_start = ls + tlen;
                    // Skip spaces
                    while val_start < len(raw) { if __char_code(char_at(raw, val_start)) != 32 { break; }; val_start = val_start + 1; };
                    let le = val_start;
                    while le < len(raw) { if __char_code(char_at(raw, le)) == 10 { break; }; le = le + 1; };
                    return __substr(raw, val_start, le);
                };
            };
        };
        i = i + 1;
    };
    return "";
}

// Set config value (append/update in knowledge file)
pub fn config_set(key, value) {
    let line = "config " + key + " " + value;
    __file_append(_cfg_path, line + "\n");
    return value;
}

// Get all config entries matching a prefix
pub fn config_list(prefix) {
    let raw = __file_read(_cfg_path);
    let target = "config " + prefix;
    let tlen = len(target);
    let results = [];
    let i = 0;
    while i < len(raw) {
        let c = __char_code(char_at(raw, i));
        if c == 10 || i == 0 {
            let ls = i;
            if i > 0 { ls = i + 1; };
            if ls + tlen <= len(raw) {
                let match = 1;
                let ci = 0;
                while ci < tlen {
                    if char_at(raw, ls + ci) != char_at(target, ci) { match = 0; break; };
                    ci = ci + 1;
                };
                if match == 1 {
                    let le = ls;
                    while le < len(raw) { if __char_code(char_at(raw, le)) == 10 { break; }; le = le + 1; };
                    push(results, __substr(raw, ls + 7, le));
                };
            };
        };
        i = i + 1;
    };
    return results;
}
