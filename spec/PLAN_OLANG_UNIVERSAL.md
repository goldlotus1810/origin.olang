# PLAN: Olang Universal

> Updated: 2026-04-02 SS23 (live)

## HIỆN TRẠNG
```
VM:       65KB, 120 builtins, x86-64 ASM, no libc
Syntax:   let fn if/else while for match struct import try/catch/throw
          break/continue arr[i] !expr closures(full mutable capture)
Stdlib:   json http regex persist feedback generate comm brain_v3
Math:     sin cos tan atan atan2 pow log log10 round min max random
Array:    sort slice reverse (in VM)
Debug:    line numbers + stack traces on uncaught throw
Perf:     integer fast-path div/mod, __time_now
FFI:      __ffi_call — call ANY function pointer (JIT code works!)
Net:      __tcp_connect + send/recv, http_get/post, JSON parse/stringify
Tests:    266+ assertions ALL PASS
```

## PROGRESS

| Phase | Name | Status |
|-------|------|--------|
| 1 | Language basics | ✅ try/catch, break, arr[i], closures, math |
| 2.1 | Line numbers | ✅ "Error at line N" |
| 2.2 | Stack traces | ✅ "at fn" call chain |
| 3.1 | FFI trampoline | ✅ __ffi_call works with JIT code |
| 3.4 | Array builtins | ✅ sort, slice, reverse |
| 4.4 | Int fast-path | ✅ idiv for div/mod |
| — | emit bug fix | ✅ critical: extra pop rsi |
| — | closure capture | ✅ VM + compiler, full mutable |
| — | HTTP client | ✅ http_get/post with JSON |
| 1.5 | Self-hosting sync | ⏳ compiler.ol needs new syntax |
| 3.2 | FFI .so loader | ⏳ Next — dlopen via ELF parse |
| 3.3 | Regex | ⏳ ~800 LOC Olang |
| 4.1 | Baseline JIT | ⏳ ~500 LOC — __ffi_call ready! |
| 4.2 | Typed arrays | ⏳ ~400 LOC |
| 4.3 | SIMD | ⏳ ~500 LOC |
| 5 | ARM64/WASM | ⏳ |
| 6 | Self-evolution | ⏳ |
