// db.ol — NoxDB v1: key-value store bằng Olang thuần
// Format: text-based, one entry per line: KEY\tVALUE\n
// v1: linear scan, string I/O. Đủ cho <10K entries.

// Create new empty database
fn db_new() {
    let db = {
        keys: [],
        vals: [],
        count: 0
    };
    return db;
};

// Get value by key. Returns "" if not found.
fn db_get(db, key) {
    let i = 0;
    while i < db.count {
        if __array_get(db.keys, i) == key {
            return __array_get(db.vals, i);
        };
        i = i + 1;
    };
    return "";
};

// Set key=value. Overwrites if exists, appends if new.
fn db_set(db, key, val) {
    let i = 0;
    while i < db.count {
        if __array_get(db.keys, i) == key {
            __set_at(db.vals, i, val);
            return 0;
        };
        i = i + 1;
    };
    push(db.keys, key);
    push(db.vals, val);
    db.count = db.count + 1;
    return 0;
};

// Delete key. Returns 1 if found, 0 if not.
fn db_delete(db, key) {
    let i = 0;
    while i < db.count {
        if __array_get(db.keys, i) == key {
            let last = db.count - 1;
            if i < last {
                __set_at(db.keys, i, __array_get(db.keys, last));
                __set_at(db.vals, i, __array_get(db.vals, last));
            };
            db.count = db.count - 1;
            return 1;
        };
        i = i + 1;
    };
    return 0;
};

// Check if key exists
fn db_has(db, key) {
    let i = 0;
    while i < db.count {
        if __array_get(db.keys, i) == key { return 1; };
        i = i + 1;
    };
    return 0;
};

// Serialize to string (tab-separated, newline-delimited)
fn db_serialize(db) {
    let out = "";
    let i = 0;
    while i < db.count {
        out = out + __array_get(db.keys, i) + "\t" + __array_get(db.vals, i) + "\n";
        i = i + 1;
    };
    return out;
};

// Save to file
fn db_save(db, path) {
    __file_write(path, db_serialize(db));
    return db.count;
};

// Load from string
fn db_load_string(text) {
    let db = db_new();
    // __str_split takes char CODE (f64), not string. 10=newline, 9=tab.
    let lines = __str_split(text, 10);
    let i = 0;
    while i < len(lines) {
        let line = __array_get(lines, i);
        if len(line) > 0 {
            let tab_pos = __str_index_of(line, "\t");
            if tab_pos >= 0 {
                let key = substr(line, 0, tab_pos);
                let val = substr(line, tab_pos + 1, len(line));
                db_set(db, key, val);
            };
        };
        i = i + 1;
    };
    return db;
};

// Load from file
fn db_load(path) {
    let text = __file_read(path);
    if len(text) == 0 { return db_new(); };
    return db_load_string(text);
};

// List all keys
fn db_keys(db) {
    let result = [];
    let i = 0;
    while i < db.count {
        push(result, __array_get(db.keys, i));
        i = i + 1;
    };
    return result;
};
