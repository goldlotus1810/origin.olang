// Test NoxDB key-value store
import "stdlib/test.ol"
import "stdlib/db.ol"

// Create + set + get
let db = db_new();
db_set(db, "name", "Nox");
db_set(db, "version", "25");
db_set(db, "status", "alive");
check("get_name", db_get(db, "name"), "Nox");
check("get_version", db_get(db, "version"), "25");
check("count", db.count, 3);

// Overwrite
db_set(db, "version", "26");
check("overwrite", db_get(db, "version"), "26");
check("count_after_overwrite", db.count, 3);

// Has
check("has_yes", db_has(db, "name"), 1);
check("has_no", db_has(db, "missing"), 0);

// Delete
check("delete_yes", db_delete(db, "status"), 1);
check("count_after_delete", db.count, 2);
check("delete_no", db_delete(db, "nonexist"), 0);
check("get_deleted", db_get(db, "status"), "");

// Serialize + deserialize
db_set(db, "key1", "val1");
db_set(db, "key2", "val2");
let text = db_serialize(db);
assert("serialize_not_empty", len(text) > 0);
let db2 = db_load_string(text);
check("load_name", db_get(db2, "name"), "Nox");
check("load_version", db_get(db2, "version"), "26");
check("load_key1", db_get(db2, "key1"), "val1");
check("load_count", db2.count, 4);

// Save to file + load from file
db_save(db, "/tmp/test_noxdb.txt");
let db3 = db_load("/tmp/test_noxdb.txt");
check("file_name", db_get(db3, "name"), "Nox");
check("file_count", db3.count, 4);

// Keys list
let ks = db_keys(db);
check("keys_count", len(ks), 4);

test_summary();
