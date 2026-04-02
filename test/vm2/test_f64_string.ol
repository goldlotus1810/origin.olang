// Test DATA-2 fix: f64 + string and string + f64 auto-concat
import "stdlib/test.ol"

// string + number
check("str+int", "x=" + 42, "x=42");
check("str+float", "pi=" + 3.14, "pi=3.14");
check("str+zero", "val=" + 0, "val=0");
check("str+neg", "n=" + (0 - 5), "n=-5");

// number + string
check("int+str", 42 + " is answer", "42 is answer");
check("float+str", 3.14 + " pi", "3.14 pi");

// chained
check("chain", "a" + 1 + "b" + 2, "a1b2");

// edge cases
check("str+big", "n=" + 1000000, "n=1000000");

test_summary();
