let pass = 0;

// Test 1: match number
let r1 = 0;
match 2 {
    1 => r1 = 10;
    2 => r1 = 20;
    _ => r1 = 99;
};
if r1 == 20 { pass = pass + 1; } else { emit "FAIL: match number"; };

// Test 2: default case
let r2 = 0;
match 5 {
    1 => r2 = 10;
    2 => r2 = 20;
    _ => r2 = 99;
};
if r2 == 99 { pass = pass + 1; } else { emit "FAIL: match default"; };

// Test 3: match with expression
let val = 1 + 2;
let r3 = 0;
match val {
    1 => r3 = 10;
    3 => r3 = 30;
};
if r3 == 30 { pass = pass + 1; } else { emit "FAIL: match expr"; };

emit pass;
emit "/3 match tests passed";
