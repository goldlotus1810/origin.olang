# VM ASM Map — vm_x86_64.S (9245 LOC)

## Sections

| Lines | Section | LOC | Description |
|-------|---------|-----|-------------|
| 1-65 | Constants | 65 | .equ definitions, markers, syscall numbers |
| 66-271 | Boot loader | 206 | _start, mmap, read bytecodes, var_table_init |
| 272-695 | Dispatch | 424 | vm_loop, codegen_table, ir.rs tables |
| 696-829 | Stack ops | 134 | Push, PushNum, Load, Store, Dup, Pop, Swap |
| 830-1825 | Control flow | 996 | Jmp, Jz, Call (+ builtin jump table), Ret, Closures |
| 1826-2037 | Math builtins | 212 | add, sub, mul, div, mod, floor, ceil, isqrt |
| 2038-2108 | Comparisons | 71 | eq, ne, lt, gt, le, ge |
| 2109-2605 | String builtins | 497 | len, substr, char_at, trim, concat, to_string, etc |
| 2606-2934 | Array builtins | 329 | new, get, set, push, pop, range, with_cap |
| 2935-3006 | Dict builtins | 72 | new, get, set, keys |
| 3007-3445 | Struct/Enum | 439 | struct_tag, match_enum, enum_field, enum_payload |
| 3446-3764 | Eval bytecode | 319 | __eval_bytecode, scope save/restore |
| 3765-4140 | JIT | 376 | auto-jit, jit_register, native call |
| 4141-5600 | SHA-256 | 1460 | Full FIPS 180-4 implementation |
| 5601-5939 | SHA-512 | 339 | FIPS 180-4 SHA-512 |
| 5940-6173 | Byte buffers | 234 | bytes_new, get, set, write, len |
| 6174-6272 | Molecule ops | 99 | mol_s, mol_r, mol_v, mol_a, mol_t, mol_pack |
| 6273-6370 | UTF-8 | 98 | utf8_cp, utf8_len |
| 6371-6611 | System builtins | 241 | sleep, time, write_raw, file I/O, AES, network |
| 6612-7033 | Emit + REPL | 422 | op_emit (f64/string/array/dict), REPL loop |
| 7034-7131 | Syscall wrappers | 98 | sys_write, file_read/write/append |
| 7132-7604 | LCA + Edge + Query | 473 | Molecular operations |
| 7605-7830 | Var table | 226 | hash_name, var_store_hash, var_load_hash, var_cache |
| 7831-8120 | Exit + REPL | 290 | op_halt, repl_loop, eval_stdin |
| 8121-8500 | Try/catch + misc | 380 | try_begin, catch_end, throw, coroutines |
| 8501-8900 | Data section | 400 | .rodata strings, hex chars, SHA-256 K table |
| 8901-9245 | BSS section | 345 | var_table, caches, SHA buffers, coroutine slots |

## Critical paths (hot code)

```
vm_loop → dispatch_codegen → codegen_table[opcode]
  → op_load_local → var_load_hash (+ var_cache)
  → op_store → var_store_hash (frame-aware)
  → op_call → hash_name → builtin_jump_table → .call_xxx
  → cg_call_closure → closure dispatch (boot/eval)
```

## var_table architecture (THE BOMB)

```
Current: flat array, 24 bytes/entry [hash:8, ptr:8, len:8]
  - var_store_hash: reverse search within frame, update or append
  - var_load_hash: reverse search + 256-entry cache
  - Frame: depth_stack[depth] = var_table count at call time
  - Boot context: depth=0, frame_start=0 (search ALL)
  - No cleanup on function return (entries accumulate forever)

Problem: O(n) search, no lexical scope, variables leak across calls
Fix needed: depth-tagged entries + cleanup on scope exit
```
