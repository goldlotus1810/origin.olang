let pass = 0;

// Test 1: closure captures outer variable
let x = 10;
fn add_x(y) { return x + y; };
let r1 = add_x(5);
if r1 == 15 { pass = pass + 1; } else { emit "FAIL: basic capture"; };

// Test 2: closure captures multiple vars
let a = 100;
let b = 200;
fn sum_ab(c) { return a + b + c; };
let r2 = sum_ab(3);
if r2 == 303 { pass = pass + 1; } else { emit "FAIL: multi capture"; };

// Test 3: no capture (simple function)
fn double(n) { return n * 2; };
let r3 = double(7);
if r3 == 14 { pass = pass + 1; } else { emit "FAIL: no capture"; };

emit pass;
emit "/3 closure capture tests passed";
