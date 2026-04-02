let pass = 0;

// Test 1: basic try/catch
try {
    throw "error";
} catch(e) {
    pass = pass + 1;
};

// Test 2: no throw = no catch
let reached = 0;
try {
    reached = 1;
} catch(e) {
    reached = 99;
};
if reached == 1 { pass = pass + 1; } else { emit "FAIL: no throw"; };

// Test 3: code after try continues
pass = pass + 1;

emit pass;
emit "/3 try/catch tests passed";
