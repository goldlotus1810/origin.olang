// editor/filetree.ol — File tree panel

pub fn ft_scan(_dir) {
    let _files = __readdir(_dir);
    let _sorted = [];
    // Separate dirs and files, add dirs first
    let _i = 0;
    while _i < len(_files) {
        let _f = _files[_i];
        // Check if it's a directory by trying readdir on it
        let _path = _dir + "/" + _f;
        let _sub = __readdir(_path);
        if len(_sub) > 0 {
            push(_sorted, _f + "/");
        };
        _i = _i + 1;
    };
    // Then files
    _i = 0;
    while _i < len(_files) {
        let _f = _files[_i];
        let _path = _dir + "/" + _f;
        let _sub = __readdir(_path);
        if len(_sub) == 0 {
            push(_sorted, _f);
        };
        _i = _i + 1;
    };
    return _sorted;
}

pub fn ft_render(_files, _sel, _rows, _scroll, _width) {
    let _i = 0;
    while _i < _rows {
        let _fi = _scroll + _i;
        term_goto(_i + 2, 1);
        term_bg(236);
        if _fi < len(_files) {
            let _name = _files[_fi];
            if _fi == _sel {
                term_bg(238);
                term_color(75);
                term_bold();
            } else {
                // Color by type
                let _nlen = len(_name);
                let _last = __substr(_name, _nlen - 1, _nlen);
                if _last == "/" {
                    term_color(75);
                } else {
                    term_color(252);
                };
            };
            // Truncate name to fit panel width
            if len(_name) > _width - 2 {
                _name = __substr(_name, 0, _width - 2);
            };
            __write_raw(" " + _name);
            let _pad = _width - len(_name) - 1;
            let _p = 0;
            while _p < _pad { __write_raw(" "); _p = _p + 1; };
            term_reset();
        } else {
            let _p = 0;
            while _p < _width { __write_raw(" "); _p = _p + 1; };
        };
        _i = _i + 1;
    };
}
