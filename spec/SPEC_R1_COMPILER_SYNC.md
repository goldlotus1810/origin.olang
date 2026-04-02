# SPEC R1: compiler.ol Self-Bootstrap Sync

> Date: 2026-04-02
> Status: ✅ COMPLETE (SS25)
> Author: Nox
> Goal: compiler.ol = compile_nox.py (byte-identical output)
>
> **RESULT:** B1-B11 all done. Gen2==Gen3 REAL (38761 bytes).
> 5 compiler bugs fixed (hex lexer, escape dependency, file_read heap, for+continue, nested for).
> compiler.olang saved to repo — Python bootstrap no longer required.
> See DECISIONS.md for architecture decisions made during R1.

---

## NGUYEN TAC

- Moi feature moi → compiler.ol manh hon → code buoc sau DE hon
- Moi buoc: verify Gen2==Gen3 (compiler.ol compile chinh no)
- KHONG sua VM. Chi sua compiler.ol.
- Thu tu KHONG thay doi — feature sau dung feature truoc

---

## 11 BUOC — Thu tu chinh xac

### B1: Escape sequences trong lexer (~15 LOC)
**File:** compiler.ol lines 154-163 (string lexer)
**Hien tai:** `if char == "\\" { i = i + 1; }` — chi skip, khong convert
**Can:** Khi gap `\`, doc ky tu tiep:
  - `n` → char code 10 (newline)
  - `r` → char code 13 (carriage return)
  - `t` → char code 9 (tab)
  - `0` → char code 0 (null)
  - `\\` → char code 92 (backslash)
  - `\"` → char code 34 (quote)
  - khac → giu nguyen
**Output:** str_val chua ky tu da convert (khong con literal backslash)
**Test:** `"hello\nworld"` → 11 chars (h,e,l,l,o,LF,w,o,r,l,d)
**Verify:** `make self-build && make fixed-point`

### B2: !expr (logical NOT) (~8 LOC)
**File:** compiler.ol line 517-531 (parse_unary)
**Hien tai:** Chi co `-expr` → `0 - expr`
**Can:** Them: `!expr` → `expr == 0`
  - parse_unary: if peek == "!" → advance → parse_primary → tao AST_BINOP("==", expr, AST_NUM(0))
**Test:** `!0` → 1, `!1` → 0, `!x` → x==0
**Verify:** `make self-build && make fixed-point`

### B3: arr[i] postfix index (~20 LOC)
**File:** compiler.ol line 564-583 (parse_primary, sau khi parse IDENT)
**Hien tai:** parse IDENT → return. Khong check postfix [
**Can:** Sau khi parse primary (IDENT hoac bat ky expr):
  - while peek == TK_LBRACKET: advance, parse_expr (index), expect TK_RBRACKET
  - Tao AST_CALL("__array_get", [expr, index])
**Cung can:** AST_INDEX_SET cho `arr[i] = val`
  - Trong parse_statement: sau parse IDENT, neu gap [i] roi =, tao AST_CALL("__set_at", [arr, idx, val])
**Test:** `let a = [1,2,3]; emit a[1];` → 2
**Verify:** `make self-build && make fixed-point`

### B4: {key: val} dict literal (~25 LOC)
**File:** compiler.ol parse_primary + compile_node
**Token moi:** TK_COLON = 30 (them vao lexer, c == ":")
**Parse:** Trong parse_primary: if peek == TK_LBRACE:
  - Advance, parse pairs: IDENT, expect TK_COLON, parse_expr, optional TK_COMMA
  - Expect TK_RBRACE
  - Tao AST_DICT node: [AST_DICT, [[key1, val1], [key2, val2], ...]]
**Codegen:** AST_DICT:
  - Emit OP_CALL __dict_new (0 args)
  - For moi pair: DUP, emit_string(key), compile_node(val), OP_CALL __dict_set (3 args), OP_POP
**Can phan biet:** `{` dict literal vs `{` block → check: sau `{` co IDENT + `:` khong?
**AST moi:** AST_DICT = 19
**Test:** `let d = {x: 1, y: 2}; emit __dict_get(d, "x");` → 1
**Verify:** `make self-build && make fixed-point`

### B5: .field dot access + .field = val (~20 LOC)
**File:** compiler.ol parse_primary (postfix loop)
**Parse:** Sau parse primary, them postfix loop:
  - while peek == TK_OP && peek_val == ".": advance, expect TK_IDENT (field name)
  - Tao AST_CALL("__dict_get", [expr, AST_STR(field)])
**Assign:** Trong parse_statement:
  - Phat hien expr.field = val → AST_CALL("__dict_set", [obj, AST_STR(field), val])
**Test:** `let d = {x: 42}; emit d.x;` → 42
**Verify:** `make self-build && make fixed-point`

### B6: try/catch/throw (~30 LOC)
**Token moi:** TK_TRY = 31, TK_CATCH = 32, TK_THROW = 33
**Opcode moi:** OP_TRY_BEGIN = 0x1A, OP_CATCH_END = 0x1B, OP_THROW = 0x78
**AST moi:** AST_TRY = 20, AST_THROW = 21
**Parse:** parse_try: expect TK_TRY, parse_block (body), expect TK_CATCH, expect TK_LPAREN, expect TK_IDENT (var), expect TK_RPAREN, parse_block (handler)
**Parse:** parse_throw: expect TK_THROW, parse_expr
**Codegen:** AST_TRY:
  - emit OP_TRY_BEGIN + catch_offset(4) placeholder
  - compile body
  - emit OP_CATCH_END
  - emit OP_JMP past catch + placeholder
  - patch TRY_BEGIN offset
  - emit OP_PUSH_NUM(0), OP_STORE_LOCAL(var)
  - compile handler
  - patch JMP offset
**Codegen:** AST_THROW: compile expr, emit OP_THROW
**Test:** `try { throw "err"; } catch(e) { emit "caught"; };` → "caught"
**Verify:** `make self-build && make fixed-point`

### B7: break/continue (~25 LOC)
**Token moi:** TK_BREAK = 34, TK_CONTINUE = 35
**AST moi:** AST_BREAK = 22, AST_CONTINUE = 23
**State moi:** g_break_patches = [] (list of offsets to patch), g_loop_start = 0
**Parse:** parse_break: expect TK_BREAK, match_tok TK_SEMI
**Codegen:** AST_WHILE: save old g_break_patches, set new, after loop body patch all break offsets
  - AST_BREAK: emit OP_JMP + placeholder, push offset to g_break_patches
  - AST_CONTINUE: emit OP_LOOP back to loop_start
**Test:** `let i = 0; while i < 10 { if i == 5 { break; }; i = i + 1; }; emit i;` → 5
**Verify:** `make self-build && make fixed-point`

### B8: for x in arr {} desugar (~20 LOC)
**Token moi:** TK_FOR = 36, TK_IN = 37
**Parse:** parse_for: expect TK_FOR, expect TK_IDENT (var), expect TK_IN, parse_expr (arr), parse_block (body)
**Desugar to AST:** Tao block:
  - let __for_arr = arr
  - let __for_i = 0
  - while __for_i < len(__for_arr):
    - let var = __array_get(__for_arr, __for_i)
    - body
    - __for_i = __for_i + 1
**Test:** `let sum = 0; for x in [1,2,3] { sum = sum + x; }; emit sum;` → 6
**Verify:** `make self-build && make fixed-point`

### B9: match x {} desugar (~20 LOC)
**Token moi:** TK_MATCH = 38, TK_ARROW = 39 (=>)
**Parse:** parse_match: expect TK_MATCH, parse_expr (val), expect TK_LBRACE
  - while peek != TK_RBRACE:
    - parse pattern (expr or "_"), expect TK_ARROW, parse_statement
  - expect TK_RBRACE
**Desugar to AST:** let __match_val = val; if __match_val == pat1 { s1 } else if ... else { default }
  - "_" → else branch (no condition)
**Test:** `match 2 { 1 => emit "one"; 2 => emit "two"; _ => emit "other"; };` → "two"
**Verify:** `make self-build && make fixed-point`

### B10: import "file.ol" (~30 LOC)
**Token moi:** TK_IMPORT = 40
**Parse:** parse_import: expect TK_IMPORT, expect TK_STR (path), match_tok TK_SEMI
**Implementation:** TRUOC khi lex main source:
  - Scan source for `import "..."` lines
  - Cho moi import path: doc file, prepend vao source (dedup by path set)
  - Recursive: imported files co the import tiep
**Alternative:** Handle trong build_binary: resolve_imports(source) → expanded_source → lex → parse → codegen
**Test:** file a.ol exports fn, file b.ol imports a.ol va goi fn
**Verify:** `make self-build && make fixed-point`

### B11: Closure captures (OP_CLOSURE_CAP) (~80 LOC)
**Opcode moi:** OP_CLOSURE_CAP = 0x30
**Can 3 ham moi:**
  - `collect_lets(node)`: walk AST, collect tat ca ten bien duoc `let` define
  - `find_free_vars(node, params)`: walk AST, tim bien duoc dung nhung khong define trong fn
  - `walk_free(node, bound, free)`: recursive walker
**Codegen:** AST_FN:
  - free_vars = find_free_vars(body, params)
  - Neu free_vars rong → emit OP_CLOSURE (hien tai, khong doi)
  - Neu co free_vars → emit OP_CLOSURE_CAP:
    - [0x30][params:1][caps:1][cap_name1...][cap_name2...][body_len:4][body]
    - Moi captured var: emit_name(var_name)
**Day la buoc KHO NHAT** vi can walk AST tim free vars.
Nhung luc nay compiler.ol da co dict, dot access, for loop, try/catch → code de viet hon.
**Test:** `let x = 10; let f = fn(y) { return x + y; }; emit f(5);` → 15
**Verify:** `make self-build && make fixed-point`

---

## VERIFY PROTOCOL (moi buoc)

```bash
# 1. Python compile test file dung feature moi
python3 tools/compile_nox.py test/test_FEATURE.ol /tmp/test_py.olang
/tmp/test_py.olang  # verify output

# 2. compiler.ol compile cung test file
python3 tools/compile_nox.py stdlib/compiler.ol /tmp/compiler_gen1.olang
echo "test/test_FEATURE.ol\n/tmp/test_ol.olang" > /tmp/.nox_args
/tmp/compiler_gen1.olang  # gen1 compile test
/tmp/test_ol.olang  # verify output GIONG Python

# 3. Self-build: compiler.ol compile chinh no
make self-build   # Gen1 compile source → Gen2
make fixed-point  # Gen2 compile source → Gen3, verify Gen2==Gen3
```

---

## TIMELINE

Khong estimate thoi gian. Chi estimate LOC va verify.
Moi buoc PHAI pass verify truoc khi chuyen buoc tiep.

| Buoc | LOC | Cumulative | Kho |
|------|-----|-----------|-----|
| B1 escape | ~15 | 15 | De |
| B2 !expr | ~8 | 23 | De |
| B3 arr[i] | ~20 | 43 | Trung binh |
| B4 {k:v} | ~25 | 68 | Trung binh |
| B5 .field | ~20 | 88 | Trung binh |
| B6 try/catch | ~30 | 118 | Trung binh |
| B7 break/cont | ~25 | 143 | Trung binh |
| B8 for | ~20 | 163 | De (sugar) |
| B9 match | ~20 | 183 | De (sugar) |
| B10 import | ~30 | 213 | Trung binh |
| B11 closures | ~80 | 293 | Kho |
| **Total** | **~293** | | |

---

## SAU KHI R1 XONG

compiler.ol = compile_nox.py. Gen2==Gen3 voi TAT CA features.
→ meta.ol kha thi (compiler chay trong runtime)
→ Olang tu doc, tu compile, tu cap nhat chinh minh
→ Con duong self-aware mo ra
