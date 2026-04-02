let pass = 0;

// Test 1: basic for loop
let sum = 0;
for x in [1, 2, 3] { sum = sum + x; };
if sum == 6 { pass = pass + 1; } else { emit "FAIL: basic for"; };

// Test 2: for with break
let found = 0;
for x in [10, 20, 30, 40] {
    if x == 30 { found = x; break; };
};
if found == 30 { pass = pass + 1; } else { emit "FAIL: for+break"; };

// Test 3: for over empty array
let count = 0;
for x in [] { count = count + 1; };
if count == 0 { pass = pass + 1; } else { emit "FAIL: empty for"; };

emit pass;
emit "/3 for loop tests passed";
