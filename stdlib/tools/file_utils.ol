// stdlib/tools/file_utils.ol — File tools. Pure Olang.

// List files in directory (wraps __readdir)
pub fn ls(_dir) {
    let _files = __readdir(_dir);
    let _out = "";
    let _i = 0;
    while _i < len(_files) {
        if _i > 0 { let _out = _out + "\n"; };
        let _out = _out + __array_get(_files, _i);
        let _i = _i + 1;
    };
    return _out;
}

// List files with sizes
pub fn ls_detail(_dir) {
    let _files = __readdir(_dir);
    let _out = "";
    let _i = 0;
    while _i < len(_files) {
        let _name = __array_get(_files, _i);
        let _path = _dir + "/" + _name;
        let _content = __file_read(_path);
        let _size = len(_content);
        let _lines = 0;
        let _j = 0;
        while _j < _size {
            if __char_code(char_at(_content, _j)) == 10 { let _lines = _lines + 1; };
            let _j = _j + 1;
        };
        let _out = _out + _name + "\t" + __to_string(_size) + "B\t" + __to_string(_lines) + "L\n";
        let _i = _i + 1;
    };
    return _out;
}

// Grep: find lines containing pattern
pub fn grep(_path, _pattern) {
    let _content = __file_read(_path);
    if len(_content) == 0 { return ""; };
    let _out = "";
    let _line_num = 0;
    let _start = 0;
    let _i = 0;
    while _i < len(_content) {
        if __char_code(char_at(_content, _i)) == 10 {
            let _line = substr(_content, _start, _i);
            if _str_has(_line, _pattern) {
                let _out = _out + __to_string(_line_num) + ": " + _line + "\n";
            };
            let _line_num = _line_num + 1;
            let _start = _i + 1;
        };
        let _i = _i + 1;
    };
    return _out;
}

// Grep count: how many lines contain pattern
pub fn grep_count(_path, _pattern) {
    let _content = __file_read(_path);
    if len(_content) == 0 { return 0; };
    let _count = 0;
    let _start = 0;
    let _i = 0;
    while _i < len(_content) {
        if __char_code(char_at(_content, _i)) == 10 {
            let _line = substr(_content, _start, _i);
            if _str_has(_line, _pattern) { let _count = _count + 1; };
            let _start = _i + 1;
        };
        let _i = _i + 1;
    };
    return _count;
}

// Head: first N lines of file
pub fn file_head(_path, _n) {
    let _content = __file_read(_path);
    if len(_content) == 0 { return ""; };
    let _count = 0;
    let _i = 0;
    while _i < len(_content) {
        if __char_code(char_at(_content, _i)) == 10 {
            let _count = _count + 1;
            if _count >= _n { return substr(_content, 0, _i); };
        };
        let _i = _i + 1;
    };
    return _content;
}

// Tail: last N lines of file
pub fn file_tail(_path, _n) {
    let _content = __file_read(_path);
    if len(_content) == 0 { return ""; };
    let _positions = [];
    let _i = 0;
    while _i < len(_content) {
        if __char_code(char_at(_content, _i)) == 10 {
            push(_positions, _i);
        };
        let _i = _i + 1;
    };
    let _total = len(_positions);
    if _total <= _n { return _content; };
    let _start = __array_get(_positions, _total - _n) + 1;
    return substr(_content, _start, len(_content));
}

// Word count: lines, words, chars
pub fn wc(_path) {
    let _content = __file_read(_path);
    let _chars = len(_content);
    let _lines = 0;
    let _words = 0;
    let _in_word = 0;
    let _i = 0;
    while _i < _chars {
        let _c = __char_code(char_at(_content, _i));
        if _c == 10 { let _lines = _lines + 1; };
        if _c == 32 || _c == 10 || _c == 9 {
            if _in_word == 1 { let _words = _words + 1; };
            let _in_word = 0;
        } else {
            let _in_word = 1;
        };
        let _i = _i + 1;
    };
    if _in_word == 1 { let _words = _words + 1; };
    return __to_string(_lines) + " lines, " + __to_string(_words) + " words, " + __to_string(_chars) + " chars";
}

// Diff summary: count differences between 2 files
pub fn diff_count(_path_a, _path_b) {
    let _a = __file_read(_path_a);
    let _b = __file_read(_path_b);
    if len(_a) == 0 { return "file A empty"; };
    if len(_b) == 0 { return "file B empty"; };
    
    let _la = str_lines(_a);
    let _lb = str_lines(_b);
    
    let _only_a = 0;
    let _only_b = 0;
    let _common = 0;
    
    // Simple: count lines in A not in B (O(n×m) but fine for small files)
    let _i = 0;
    while _i < len(_la) {
        let _found = 0;
        let _j = 0;
        let _line_a = __array_get(_la, _i);
        while _j < len(_lb) {
            if _line_a == __array_get(_lb, _j) { let _found = 1; let _j = len(_lb); };
            let _j = _j + 1;
        };
        if _found == 1 { let _common = _common + 1; } else { let _only_a = _only_a + 1; };
        let _i = _i + 1;
    };
    let _only_b = len(_lb) - _common;
    
    return "A:" + __to_string(len(_la)) + " B:" + __to_string(len(_lb)) 
           + " common:" + __to_string(_common) 
           + " only-A:" + __to_string(_only_a) 
           + " only-B:" + __to_string(_only_b);
}
