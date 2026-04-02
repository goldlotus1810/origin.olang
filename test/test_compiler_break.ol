let pass = 0;

// Test 1: break exits loop
let i = 0;
while i < 10 {
    if i == 5 { break; };
    i = i + 1;
};
if i == 5 { pass = pass + 1; } else { emit "FAIL: break"; };

// Test 2: continue skips iteration
let sum = 0;
let j = 0;
while j < 5 {
    j = j + 1;
    if j == 3 { continue; };
    sum = sum + j;
};
// sum = 1+2+4+5 = 12 (skip 3)
if sum == 12 { pass = pass + 1; } else { emit "FAIL: continue"; };

// Test 3: break in nested while only breaks inner
let outer = 0;
let inner_count = 0;
while outer < 3 {
    let k = 0;
    while k < 10 {
        if k == 2 { break; };
        k = k + 1;
    };
    inner_count = inner_count + k;
    outer = outer + 1;
};
// Each inner loop breaks at k=2, 3 iterations: inner_count = 2+2+2 = 6
if inner_count == 6 && outer == 3 { pass = pass + 1; } else { emit "FAIL: nested break"; };

emit pass;
emit "/3 break/continue tests passed";
