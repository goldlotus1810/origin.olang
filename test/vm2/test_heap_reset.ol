// Test arena reset: __heap_pin + __heap_reset
// Brain pattern: pin after boot, reset between cycles
import "stdlib/test.ol"

// Get current heap usage
let h0 = __heap_used();

// Allocate some strings (consume heap)
let i = 0;
while i < 100 {
    let s = "temp string number " + __to_string(i);
    i = i + 1;
};
let h1 = __heap_used();
assert("heap_grew", h1 > h0);

// Pin current position
__heap_pin();
let h_pinned = __heap_used();

// Allocate more (these are "temp" above the pin)
i = 0;
while i < 200 {
    let s = "more temp " + __to_string(i) + " data here";
    i = i + 1;
};
let h2 = __heap_used();
assert("heap_grew_more", h2 > h_pinned);

// Reset — should free temp allocations back to pinned point
__heap_reset();
let h3 = __heap_used();
check("heap_reset", h3, h_pinned);

// Allocate again after reset — should reuse freed space
i = 0;
while i < 50 {
    let s = "reuse " + __to_string(i);
    i = i + 1;
};
let h4 = __heap_used();
assert("reuse_space", h4 < h2);

// Multiple reset cycles (simulating brain PTAV loops)
let cycle = 0;
while cycle < 10 {
    // Simulate one cycle: allocate temp, then reset
    let j = 0;
    while j < 50 {
        let s = "cycle" + __to_string(cycle) + "_" + __to_string(j);
        j = j + 1;
    };
    __heap_reset();
    cycle = cycle + 1;
};
let h_final = __heap_used();
check("stable_after_10_cycles", h_final, h_pinned);

test_summary();
