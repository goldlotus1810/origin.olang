import "../stdlib/jit.ol";

let _p = [0]; let _f = [0];
fn ok(c,m){if c{_p[0]=_p[0]+1;}else{emit "FAIL: "+m;_f[0]=_f[0]+1;};};

emit "T1: JIT sum loop";
let sum_fn = jit_sum_loop();
let r = __ffi_call(sum_fn, 100, 1);
ok(r == 4950, "sum(100)=4950");
let r2 = __ffi_call(sum_fn, 1000000, 1);
ok(r2 > 0, "sum(1M) returns");

emit "T2: JIT vs Olang benchmark";
let N = 10000000;
let t1 = __time_now();
let jit_sum = __ffi_call(sum_fn, N, 1);
let t2 = __time_now();
emit "  JIT sum(10M)=" + __to_string(jit_sum) + " in " + __to_string(__round(t2-t1)) + "ms";

let t3 = __time_now();
let olang_sum = [0]; let i = 0;
while i < N { olang_sum[0] = olang_sum[0] + i; let i = i + 1; };
let t4 = __time_now();
emit "  Olang sum(10M)=" + __to_string(olang_sum[0]) + " in " + __to_string(__round(t4-t3)) + "ms";
emit "  Speedup: ~" + __to_string(__round((t4-t3) / __max(t2-t1, 0.01))) + "x";

__munmap(sum_fn, 4096);

emit "";
emit __to_string(_p[0]) + "/" + __to_string(_p[0]+_f[0]) + " passed";
if _f[0] == 0 { emit "ALL PASS"; };
