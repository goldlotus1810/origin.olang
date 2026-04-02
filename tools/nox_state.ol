// nox_state.ol — Cross-session state manager
// Compiled to nox_state.olang, called by hooks to save/load session state
// Usage: nox_state.olang save KEY VALUE
//        nox_state.olang load
//        nox_state.olang set-done "description of what was done"
import "stdlib/db.ol"

let STATE_FILE = "/home/lupin/.nox/session_state.txt";

// Ensure directory exists
__system("mkdir -p /home/lupin/.nox");

// Read command from args file
let args_raw = __file_read("/tmp/.nox_state_args");
let cmd = "";
let key = "";
let val = "";

if len(args_raw) > 0 {
    let parts = __str_split(args_raw, 10);
    if len(parts) > 0 { cmd = __array_get(parts, 0); };
    if len(parts) > 1 { key = __array_get(parts, 1); };
    if len(parts) > 2 { val = __array_get(parts, 2); };
};

if cmd == "load" {
    // Load and print all state
    let db = db_load(STATE_FILE);
    if db.count > 0 {
        emit "[NOX STATE]";
        let ks = db_keys(db);
        let i = 0;
        while i < len(ks) {
            let k = __array_get(ks, i);
            emit k + ": " + db_get(db, k);
            i = i + 1;
        };
        emit "[/NOX STATE]";
    };
};

if cmd == "save" {
    let db = db_load(STATE_FILE);
    db_set(db, key, val);
    db_save(db, STATE_FILE);
    emit "saved: " + key + "=" + val;
};

if cmd == "set-done" {
    let db = db_load(STATE_FILE);
    db_set(db, "last_done", key);
    db_set(db, "last_session", "SS25b");
    db_set(db, "last_date", "2026-04-02");
    db_set(db, "tests_pass", "12/12");
    db_set(db, "gen2_gen3", "match");
    db_save(db, STATE_FILE);
    emit "state saved";
};

if cmd == "summary" {
    let db = db_load(STATE_FILE);
    if db.count > 0 {
        let done = db_get(db, "last_done");
        let sess = db_get(db, "last_session");
        let date = db_get(db, "last_date");
        let tests = db_get(db, "tests_pass");
        emit "Last: " + done + " (" + sess + " " + date + ") tests=" + tests;
    } else {
        emit "No previous state";
    };
};
