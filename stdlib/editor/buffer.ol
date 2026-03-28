// editor/buffer.ol — Text buffer (line-based)

pub fn buf_new() { return [""]; }

pub fn buf_load(_path) {
    let _content = __file_read(_path);
    if len(_content) == 0 { return [""]; };
    let _lines = split(_content, "\n");
    if len(_lines) == 0 { push(_lines, ""); };
    return _lines;
}

pub fn buf_line_count(_lines) { return len(_lines); }
