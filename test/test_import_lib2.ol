// Second library — also imports lib1 (dedup test)
import "test_import_lib.ol";
fn multiply(a, b) { return a * b; };
emit "lib2 loaded";
