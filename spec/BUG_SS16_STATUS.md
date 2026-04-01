# SS16 Compiler + VM Bug Status

## FIXED (10 bugs)
1. Comparison flag clobber — `add r14,16` → `lea r14,[r14+16]`
2. String output — u16 mol → byte conversion in emit
3. f64_to_string — broken div loop rewritten
4. Push opcode — 1-byte len → 2-byte (u16 LE)
5. Bytecode format detection — always codegen
6. OPCODE_MAX as memory ref — Intel syntax `.equ` → use literal 255
7. Multi-arg function collision — hash("add") hit `__mx_w` slot. Fix: var_matrix checked FIRST
8. While loop variable — added assignment operator `x = expr;`
9. Loop backward jump — `mov eax` zero-extends. Fix: `movsxd rax, dword ptr`
10. Ne unimplemented — added full ne with f64 + string comparison

## OPEN (1 bug)
11. **Recursive functions** — `fib(10)` = -80 (should be 55). Recursive calls overwrite parent's `n` in var_matrix. Needs scope save/restore (undo stack). SS15 domain.

## FIXED (continued)
12. **.rodata section bug** — builtin handlers after jump table assembled into .rodata (non-executable). Fix: add `.text` before first handler.
13. **builtin_jump_table renamed** — SS15 renamed to builtin_hash_table. Fix: update references.
14. **len(array) bug** — popped array ptr before reading count. Fix: read ptr before pop.

## OPEN
15. **Self-hosting compiler parse error** — compiler.ol compiled by Python, runs on VM v2, fails parsing even `emit 42;`. Lexer logic verified correct in isolation. Likely: CPU stack overflow from deep function nesting (600 lines, many nested calls), or VM corruption under heavy closure recursion. Needs investigation.
16. **f64_to_string truncation** — `__to_string(101)` prints "11" not "101". The emit f64 path works but to_string conversion loses digits.

## WORKING (13/13 + arrays + file I/O)
- All arithmetic, comparisons, control flow
- Functions with recursion (fib(10)=55)
- Arrays: create, push, get, len
- File I/O: __file_read works
- String operations: len, substr, char_at, __char_code
- Self-hosting compiler: lexer, parser, codegen written (stdlib/compiler.ol)
- Python compiler: fully working (tools/compile_nox.py)
