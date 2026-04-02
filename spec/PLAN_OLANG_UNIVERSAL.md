# PLAN: Olang Universal

> Updated: 2026-04-02 SS23 end-of-session

## HIỆN TRẠNG
```
VM:         66KB, 120 builtins, x86-64 ASM, no libc
Syntax:     let fn if/else while for match struct import try/catch/throw
            break/continue arr[i] !expr closures(full mutable capture)
Stdlib:     json http regex jit persist feedback generate comm brain_v3 (23 files)
Math:       sin cos tan atan atan2 pow log log10 round min max random
Array:      sort slice reverse (VM), typed f64/u8 arrays
Debug:      line numbers + stack traces on uncaught throw
Perf:       AVX2 f64_dot (118x), JIT framework (282x), integer fast-path mod
Output:     __to_string with proper decimals (3.14, 0.5, 0.123456)
FFI:        __ffi_call — call ANY function pointer
Net:        __tcp_connect + http_get/post + JSON parse/stringify
Examples:   api_client.ol, sysmon.ol, search.ol
Tests:      59 files, 266+ assertions ALL PASS
Brain:      94KB REPL, 50+ facts, persist
```

## PROGRESS

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1.1 | try/catch/throw | ✅ | + line numbers on error |
| 1.2 | break/continue | ✅ | nested loops work |
| 1.3 | arr[i] / arr[i]=v | ✅ | compiler sugar |
| 1.4 | !operator | ✅ | !x → x==0 |
| 1.5 | Closures full mutable | ✅ | make_counter, compose, multi-capture |
| 1.6 | Math builtins (12) | ✅ | sin cos tan atan atan2 pow log log10 round min max random |
| 1.7 | String builtins (6) | ✅ | replace join starts_with ends_with to_num readline |
| 1.8 | Dict/struct | ✅ | {key:val} .field .field=val __dict_keys |
| 1.9 | Module import | ✅ | import "file.ol" with dedup |
| 1.10 | For/match sugar | ✅ | for x in arr, match x { v => s } |
| 2.1 | Line numbers | ✅ | "Error at line N" on throw |
| 2.2 | Stack traces | ✅ | "at fn" call chain |
| 2.3 | __to_string decimals | ✅ | 3.14, 0.5, 0.123456 |
| 2.4 | Division always float | ✅ | 7/2=3.5 not 3 |
| 3.1 | FFI __ffi_call | ✅ | call any fn pointer, JIT code works |
| 3.2 | __tcp_connect | ✅ | HTTP client, real API calls |
| 3.3 | JSON parse/stringify | ✅ | recursive, type-aware |
| 3.4 | HTTP get/post | ✅ | httpbin.org, ip-api.com verified |
| 3.5 | Regex | ✅ | .+*?\d\w\s, 16/16 tests |
| 3.6 | Array sort/slice/rev | ✅ | VM-level, 14/14 tests |
| 4.1 | Typed f64/u8 arrays | ✅ | contiguous, no tags, 4x faster |
| 4.2 | AVX2 f64_dot | ✅ | 118x faster than interpreted |
| 4.3 | Integer fast-path mod | ✅ | idiv for % |
| 4.4 | JIT framework | ✅ | jit.ol, 282x on tight loops |
| 4.5 | __time_now | ✅ | epoch ms for benchmarking |
| — | emit bug fix | ✅ | extra pop rsi (critical) |
| — | throw opcode fix | ✅ | codegen_table wired |
| — | type_of DICT fix | ✅ | returns "dict" |
| — | \r\0 escape fix | ✅ | HTTP \r\n works |
| — | Hash table drift fix | ✅ | table_start recalculated |

## REMAINING

| # | Item | LOC est | Impact |
|---|------|---------|--------|
| R1 | Self-hosting sync | ~500 | compiler.ol supports new syntax |
| R2 | FFI .so loader | ~600 | dlopen, unlock C ecosystem |
| R3 | Bytecode JIT | ~500 | 2-4x ALL Olang code |
| R4 | GC mark-sweep | ~800 | long-running programs |
| R5 | SIMD add/mul/scale | ~300 | typed array bulk ops |
| R6 | ARM64 VM | ~3000 | Raspberry Pi, mobile |
| R7 | WASM backend | ~2000 | browsers |
| R8 | Self-evolution | ~5000 | VM in Olang |
