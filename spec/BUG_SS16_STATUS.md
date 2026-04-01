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

## WORKING
- PushNum, Push (strings), Emit (f64 + strings)
- Variables: let, assign, load/store via var_matrix
- Arithmetic: +, -, *, /, %
- Comparisons: ==, !=, <, >, <=, >=
- Control flow: if/else, while (with backward jumps)
- Functions: definition, call, return (non-recursive OK)
- Functions shadow builtins correctly
- 12/13 test cases pass
