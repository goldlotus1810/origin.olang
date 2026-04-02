import "test/test_import_lib.ol"

let pass = 0;

// Test 1: use imported function
let r1 = add_nums(3, 4);
if r1 == 7 { pass = pass + 1; } else { emit "FAIL: import add"; };

// Test 2: another imported function
let r2 = mul_nums(5, 6);
if r2 == 30 { pass = pass + 1; } else { emit "FAIL: import mul"; };

// Test 3: duplicate import is ignored
import "test/test_import_lib.ol"
let r3 = add_nums(10, 20);
if r3 == 30 { pass = pass + 1; } else { emit "FAIL: dedup import"; };

emit pass;
emit "/3 import tests passed";
