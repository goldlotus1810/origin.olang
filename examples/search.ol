// ═══ Nox Search — find files and content ═══
// Usage: echo "pattern" | ./search.olang
// Or: echo "/path pattern" | ./search.olang

import "../stdlib/regex.ol";

fn search_in_file(path, pattern) {
    let content = __file_read(path);
    if len(content) == 0 { return 0; };
    let lines = __str_split(content, 10);
    let found = [0];
    let i = 0;
    while i < len(lines) {
        let line = lines[i];
        if re_test(pattern, line) {
            if found[0] == 0 {
                emit path + ":";
            };
            emit "  " + __to_string(i + 1) + ": " + line;
            found[0] = found[0] + 1;
        };
        let i = i + 1;
    };
    return found[0];
};

fn list_files(dir) {
    // Use ls via __system to get file list
    let tmp = "/tmp/.nox_ls_" + __to_string(__round(__random() * 99999));
    __system("find " + dir + " -name '*.ol' -type f 2>/dev/null > " + tmp);
    let data = __file_read(tmp);
    __system("rm -f " + tmp);
    if len(data) == 0 { return []; };
    return __str_split(data, 10);
};

// ═══ Main ═══
emit "Nox Search — enter: [dir] pattern";
emit "> ";
let input = __readline();
if len(input) == 0 {
    emit "Usage: echo 'pattern' | ./search.olang";
    emit "   or: echo '/path pattern' | ./search.olang";
} else {
    // Parse: if starts with /, split into dir + pattern
    let dir = ["."];
    let pattern = [input];
    // Split on first space
    let sp = __str_index_of(input, " ");
    if sp >= 0 {
        dir[0] = substr(input, 0, sp);
        pattern[0] = substr(input, sp + 1, len(input));
    };
    let dir = dir[0];
    let pattern = pattern[0];

    emit "Searching for '" + pattern + "' in " + dir + "...";
    let files = list_files(dir);
    let total = [0];
    let t1 = __time_now();
    let fi = 0;
    while fi < len(files) {
        let f = files[fi];
        if len(f) > 0 {
            let found = search_in_file(f, pattern);
            total[0] = total[0] + found;
        };
        let fi = fi + 1;
    };
    let t2 = __time_now();
    emit "";
    emit "Found " + __to_string(total[0]) + " matches in " + __to_string(len(files)) + " files (" + __to_string(__round(t2-t1)) + "ms)";
};
