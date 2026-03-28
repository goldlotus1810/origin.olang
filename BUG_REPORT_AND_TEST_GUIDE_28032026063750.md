# ORIGIN/OLANG — BÁO CÁO BUG & HƯỚNG DẪN FIX + CÔNG CỤ TEST

> Ngày: 2026-03-28
> Phân tích bởi: Sora (Claude.AI)
> Repo: github.com/goldlotus1810/origin.olang (68 commits, main branch)
> Binary: origin.olang ~474KB ELF64, no libc, self-hosting

---

## MỤC LỤC

1. [Tổng quan kiến trúc](#1-tổng-quan-kiến-trúc)
2. [Bugs phát hiện — Mức CRITICAL](#2-bugs-critical)
3. [Bugs phát hiện — Mức HIGH](#3-bugs-high)
4. [Bugs phát hiện — Mức MEDIUM](#4-bugs-medium)
5. [Bugs phát hiện — Mức LOW / Cải thiện](#5-bugs-low)
6. [Hướng dẫn fix từng bug](#6-hướng-dẫn-fix)
7. [Bổ sung công cụ test](#7-bổ-sung-công-cụ-test)
8. [Test matrix đề xuất](#8-test-matrix)

---

## 1. Tổng quan kiến trúc

```
VM (ASM x86_64)  11,523 LOC   — trái tim, register-based + stack hybrid
Lexer            369 LOC       — tokenizer viết bằng Olang
Parser           1,221 LOC     — recursive descent, Olang
Semantic         2,043 LOC     — AST → bytecode trực tiếp (streaming)
Codegen          430 LOC       — IR → binary bytecode (two-pass)
REPL             513 LOC       — entry point + module expansion
Stdlib           ~30 files     — json, chain, sort, hash, http, etc.
Tests.sh         574 LOC       — test runner chính
```

**Điểm mạnh:** Self-hosting thành công, zero dependencies, TRO (tail recursion optimization), try/catch, closures, HOF (map/filter/reduce/pipe/any/all), array comprehension, match expression, SHA-256, UTF-8.

**Điểm yếu cốt lõi:** Global var_table (không có block scope) → phải save/restore thủ công cho mọi recursive call. Đây là nguồn gốc của ~70% bug.

---

## 2. Bugs CRITICAL

### BUG-C1: LetStmt chỉ scan 8 entries gần nhất để detect redefinition

**File:** `stdlib/bootstrap/semantic.ol` dòng 1516-1523

**Vấn đề:** Khi biên dịch `let x = ...`, compiler kiểm tra xem `x` đã tồn tại hay chưa để quyết định emit `Store` hay `StoreUpdate`. Nhưng nó chỉ scan **8 entry gần nhất** trong `_ce_locals`:

```olang
if _ls_cnt >= 1 { if __array_get(_ce_locals, _ls_cnt - 1) == _ls_name { ... }; };
if _ls_cnt >= 2 { if __array_get(_ce_locals, _ls_cnt - 2) == _ls_name { ... }; };
// ... chỉ đến 8
```

**Hậu quả:** Nếu function có >8 local variables, `let x = x + 1` sẽ emit `Store` thay vì `StoreUpdate` → tạo binding mới thay vì update → loop counter không tăng, gây infinite loop hoặc sai logic.

**Mức độ:** CRITICAL — silent data corruption.

**Tái hiện:**
```olang
let a = 0; let b = 0; let c = 0; let d = 0;
let e = 0; let f = 0; let g = 0; let h = 0;
let x = 0;
// x bây giờ ở vị trí thứ 9 — ngoài scan window
let x = x + 1;
emit x;  // Mong đợi 1, có thể ra 0 hoặc hành vi bất định
```

---

### BUG-C2: `_jp_skip_ws` dùng trick `_jw_i + _jw_len` để break while — off-by-one

**File:** `stdlib/json_parse.ol` dòng 12-27

**Vấn đề:** Hàm `_jp_skip_ws` dùng trick cộng `_jw_len` vào `_jw_i` rồi trừ lại để "break" khỏi while loop (vì Olang không có `break` trong stdlib functions trước khi nó được thêm vào). Logic trừ lại:

```olang
let _jw_i = _jw_i - _jw_len - 1;
```

Dòng cuối `_jw_i = _jw_i + 1` trong while loop chạy **sau** khi `_jw_i` đã được cộng `_jw_len`, nên kết quả cuối = `(_jw_i + _jw_len + 1) - _jw_len - 1 = _jw_i`. Tuy nhiên, nếu `_jw_is_ws == 0` thì `_jw_i` được cộng `_jw_len` nhưng **while condition vẫn kiểm tra `_jw_i < _jw_len`** — tức khi `_jw_i >= 2*_jw_len` thì loop tiếp tục iterate thêm.

**Hậu quả:** JSON parser bỏ qua ký tự đầu tiên sau whitespace trong một số trường hợp đặc biệt (input dài với nhiều whitespace liên tiếp).

**Mức độ:** CRITICAL — JSON parse sai kết quả.

---

### BUG-C3: ForStmt body KHÔNG save/restore variables trước compile_stmt

**File:** `stdlib/bootstrap/semantic.ol` dòng 1840-1845

**Vấn đề:** Trong `ForStmt`, body compilation loop:

```olang
let _fl_bi = 0;
while _fl_bi < len(body) {
    compile_stmt(state, body[_fl_bi]);
    let _fl_bi = _fl_bi + 1;
};
```

**Không** save `body`, `_fl_bi` lên `_ce_stack` trước `compile_stmt`. Nếu body chứa nested for/while/if với compile_stmt recursive → `body` và `_fl_bi` bị overwrite.

So sánh với WhileStmt (dòng 1730-1741) nơi **có** save/restore đầy đủ:
```olang
push(_ce_stack, _wl_body);
push(_ce_stack, _wl_jz);
push(_ce_stack, _wl_start);
push(_ce_stack, _wl_bi);
compile_stmt(state, _wl_body[_wl_bi]);
let _wl_bi = pop(_ce_stack);
// ...
```

**Hậu quả:** Nested `for` trong `for` có thể crash hoặc compile sai bytecode.

**Mức độ:** CRITICAL — structural corruption in nested for loops.

---

## 3. Bugs HIGH

### BUG-H1: `format.ol` dùng `typeof()` — function không tồn tại

**File:** `stdlib/format.ol` dòng 76

```olang
if typeof(val) == "number" { ... }
```

Builtin đúng là `__type_of()`, không phải `typeof()`. Hàm `to_string()` sẽ luôn fail silently (fall through to `"" + val`).

**Fix:** Thay `typeof(val)` bằng `__type_of(val)`.

---

### BUG-H2: `format.ol` dùng `floor()` — function đúng là `__floor()`

**File:** `stdlib/format.ol` dòng 23, 31, 76

Nhiều chỗ gọi `floor(val)` thay vì `__floor(val)`. Tương tự `char_from_code()` ở dòng 83 nên dùng `__chr()` hoặc `__from_char_code()`.

**Fix:** Thay toàn bộ `floor(` bằng `__floor(`, `char_from_code(` bằng `__chr(`.

---

### BUG-H3: `chain.ol` gọi `mol_lca()` — deprecated theo Axiom 6

**File:** `stdlib/chain.ol` dòng ~48

AUDIT.md ghi rõ `mol_lca` đã deprecated. `chain_lca()` function vẫn gọi nó.

**Fix:** Hoặc remove `chain_lca()`, hoặc implement per-field min/max thay thế.

---

### BUG-H4: Match expression chỉ hỗ trợ tối đa 4 arms

**File:** `stdlib/bootstrap/semantic.ol` dòng 1338-1445

Match dùng depth-indexed globals (`__g_mej0..3`, `__g_ma0_pat..3`) → cứng tối đa 4 arms. Arm thứ 5+ sẽ bị bỏ qua silently.

**Hậu quả:** Code với >4 match arms compile nhưng runtime sai.

---

### BUG-H5: `for..in` nesting chỉ hỗ trợ 4 levels

**File:** `stdlib/bootstrap/semantic.ol` dòng 1767-1770

`_g_for_depth` chỉ có slot 0-3. Depth >= 4 → tất cả globals ghi vào "void" (không match `if _g_for_depth == N`), iterator không được compile.

---

### BUG-H6: ExprStmt auto-emit gây side effect không mong muốn

**File:** `stdlib/bootstrap/semantic.ol` dòng 1972-1977

```olang
Stmt::ExprStmt { expr } => {
    compile_expr(state, expr);
    emit_op(state, make_op_simple("Emit"));  // ← auto-emit
},
```

Mọi expression statement (VD: `push(arr, 42);`) sẽ **tự động emit** giá trị trả về ra stdout. Đây là thiết kế REPL-friendly nhưng gây output thừa khi chạy scripts phức tạp. `push()` trả về array → in array mỗi lần push.

**Mức độ:** HIGH — pollutes output.

---

## 4. Bugs MEDIUM

### BUG-M1: `_emit_str_u16` hardcode byte thứ 2 = 33 (0x21)

**File:** `stdlib/bootstrap/semantic.ol` dòng 158

```olang
_emit_byte(state, _esu_bytes[_esu_i]);
_emit_byte(state, 33);   // 0x21 hardcoded
```

Đây đúng là `0x2100 | byte` nhưng hardcode `33` (0x21) cho high byte. Nếu encoding scheme thay đổi (VD: support Unicode beyond ASCII) thì sẽ break. Hiện tại OK cho ASCII-only strings.

---

### BUG-M2: `test.ol` dùng bare `=` assignment nhưng có thể bị shadow

**File:** `stdlib/test.ol` dòng 89+

```olang
s = s + i; i = i + 1;
```

Trong `test_features()`, dùng bare assignment `s = s + i` — đây phụ thuộc vào `AssignStmt → StoreUpdate` hoạt động đúng. Nếu VM var_table lookup có hash collision → sai giá trị.

---

### BUG-M3: Closure body_len patch đếm byte offset sai khi body rỗng

**File:** `stdlib/bootstrap/semantic.ol` dòng 1473-1478

```olang
let _lm_body_len = current_pos(state) - _lm_closure_pos - 6;
```

Nếu lambda body rỗng `fn() {}`, body_len = (pos_after_Push_""_Ret) - closure_pos - 6. Closure instruction = 6 bytes (1 opcode + 1 param_count + 4 body_len). Nếu pos_after < closure_pos + 6 (impossible in practice nhưng no guard) → negative body_len → u32 wrap → crash.

---

### BUG-M4: `json_parse` object trả về flat array thay vì dict

**File:** `stdlib/json_parse.ol`

`_jp_parse_object` trả về `[key1, val1, key2, val2, ...]` (flat array) thay vì Olang dict `{ key1: val1 }`. Phải dùng `json_get()` helper thay vì `obj.key`.

Đây là design choice nhưng inconsistent với dict literals trong ngôn ngữ.

---

### BUG-M5: REPL strip logic trong tests.sh có thể miss multi-line output

**File:** `tests.sh` dòng 70-75, 94

```bash
actual=$(echo "$raw_output" | strip_repl | tr -d '\n')
```

`tr -d '\n'` nối tất cả output lines thành 1 string. Nếu test expect "1\n2\n3" thì expected phải là "123" — OK. Nhưng nếu test output chứa data có newline (VD: multiline string), comparison sẽ sai.

---

## 5. Bugs LOW / Cải thiện

### BUG-L1: Array comprehension expr chỉ hỗ trợ 1, 3, hoặc 4 token

`semantic.ol` dòng 1239-1287: `_cc_expr_ntoks` chỉ handle 1 (single var), 3 (lhs op rhs), 4 (fn(arg)). Expressions phức tạp hơn (VD: `x * x + 1`) bị silently skip.

### BUG-L2: `is_keyword` trong lexer.ol dùng linear scan

`lexer.ol` dòng 31-40: Linear scan qua 29 keywords cho mỗi identifier. Với source lớn (>10K tokens), có thể chậm. Nên dùng hash lookup.

### BUG-L3: No error recovery trong parser

Khi parser gặp lỗi, nó set `_g_parse_error = 1` nhưng không skip tokens đến `;` tiếp theo. Parse dừng hoàn toàn → chỉ báo lỗi đầu tiên.

### BUG-L4: `Nox_brain.olang` (460KB) committed vào repo

File binary lớn không nên ở trong git history.

### BUG-L5: Thiếu `!` operator trong codegen `op_size()`

`codegen.ol` `op_size()` không có case cho `"Closure"` → trả về 1 (default) thay vì 6. Nhưng `generate()` function dùng `encode_op` để đo size nên **không bị ảnh hưởng** — `op_size()` có vẻ dead code.

---

## 6. Hướng dẫn fix

### Fix BUG-C1: Mở rộng local scan window

**File:** `stdlib/bootstrap/semantic.ol`

Thay 8-entry unrolled scan bằng full linear scan:

```olang
// TRƯỚC (dòng 1515-1524):
let _ls_fb2 = [0];
if _ls_cnt >= 1 { if __array_get(_ce_locals, _ls_cnt - 1) == _ls_name { ... }; };
// ... 8 entries

// SAU:
let _ls_fb2 = [0];
let _ls_si = _ls_cnt - 1;
while _ls_si >= 0 {
    if __array_get(_ce_locals, _ls_si) == _ls_name {
        let _ = set_at(_ls_fb2, 0, 1);
        let _ls_si = 0 - 1;  // break
    };
    let _ls_si = _ls_si - 1;
};
```

**⚠️ Cẩn thận:** Phải dùng `let _ls_si = 0 - 1;` để break (vì global var_table). KHÔNG dùng `break;` — nó patch jump sai nếu ở ngoài while context.

**Test sau fix:**
```bash
echo 'let a=0;let b=0;let c=0;let d=0;let e=0;let f=0;let g=0;let h=0;let i=0;let j=0;let j=j+1;emit j;' | ./origin.olang
# Expected: 1
```

---

### Fix BUG-C3: Thêm save/restore cho ForStmt body loop

**File:** `stdlib/bootstrap/semantic.ol` dòng 1840-1845

```olang
// TRƯỚC:
let _fl_bi = 0;
while _fl_bi < len(body) {
    compile_stmt(state, body[_fl_bi]);
    let _fl_bi = _fl_bi + 1;
};

// SAU:
let _fl_bi = 0;
while _fl_bi < len(body) {
    push(_ce_stack, body);
    push(_ce_stack, _fl_bi);
    compile_stmt(state, body[_fl_bi]);
    let _fl_bi = pop(_ce_stack);
    let body = pop(_ce_stack);
    let _fl_bi = _fl_bi + 1;
};
```

**Test sau fix:**
```bash
echo 'let s = 0; for x in [1,2] { for y in [10,20] { let s = s + x + y; }; }; emit s;' | ./origin.olang
# Expected: 66 (1+10 + 1+20 + 2+10 + 2+20)
```

---

### Fix BUG-H1 + BUG-H2: format.ol builtin names

```bash
cd stdlib
sed -i 's/typeof(/\__type_of(/g' format.ol
sed -i 's/floor(/\__floor(/g' format.ol
sed -i 's/char_from_code(/\__chr(/g' format.ol
```

---

### Fix BUG-H6: ExprStmt auto-emit → chỉ emit nếu REPL mode

Đây là thiết kế phức tạp hơn. Option:

1. **Quick fix:** Thêm flag `_g_is_repl` check trước auto-emit:
```olang
Stmt::ExprStmt { expr } => {
    compile_expr(state, expr);
    if _g_is_repl == 1 {
        emit_op(state, make_op_simple("Emit"));
    } else {
        emit_op(state, make_op_simple("Pop"));
    };
},
```

2. **Proper fix:** Detect bare expression (number/string literal, call without assignment) vs side-effect expression (push, set_at). Chỉ emit cho bare expressions.

---

## 7. Bổ sung công cụ test

### 7.1 `test/test_nested_for.ol` — Test nested for loops (BUG-C3)

```olang
// Test: Nested for-in loops compile correctly
let sum = 0;
for x in [1, 2, 3] {
    for y in [10, 20] {
        let sum = sum + x * y;
    };
};
// 1*10 + 1*20 + 2*10 + 2*20 + 3*10 + 3*20 = 10+20+20+40+30+60 = 180
if sum == 180 {
    emit "PASS";
} else {
    emit "FAIL";
    emit sum;
};
```

### 7.2 `test/test_many_locals.ol` — Test >8 locals (BUG-C1)

```olang
// Test: Variable redefinition with >8 locals in scope
let a = 1;
let b = 2;
let c = 3;
let d = 4;
let e = 5;
let f = 6;
let g = 7;
let h = 8;
let target = 0;
// target is the 9th variable — beyond 8-entry scan window
let target = target + 100;
if target == 100 {
    emit "PASS";
} else {
    emit "FAIL";
    emit target;
};
```

### 7.3 `test/test_while_counter.ol` — Test while loop counter update

```olang
// Test: while loop with many locals doesn't lose counter
let a = 0; let b = 0; let c = 0; let d = 0;
let e = 0; let f = 0; let g = 0; let h = 0;
let count = 0;
while count < 5 {
    let a = a + 1;
    let count = count + 1;
};
if count == 5 {
    emit "PASS";
} else {
    emit "FAIL";
    emit count;
};
```

### 7.4 `test/test_match_multi_arm.ol` — Test match with 4+ arms

```olang
// Test: match expression with exactly 4 arms (max supported)
fn classify(n) {
    match n {
        1 => { return "one"; },
        2 => { return "two"; },
        3 => { return "three"; },
        _ => { return "other"; },
    };
};
let ok = 1;
if classify(1) != "one" { let ok = 0; emit "FAIL 1"; };
if classify(2) != "two" { let ok = 0; emit "FAIL 2"; };
if classify(3) != "three" { let ok = 0; emit "FAIL 3"; };
if classify(99) != "other" { let ok = 0; emit "FAIL 99"; };
if ok { emit "PASS"; } else { emit "FAIL"; };
```

### 7.5 `test/test_json_whitespace.ol` — Test JSON with whitespace

```olang
// Test: JSON parse with leading/trailing/inner whitespace
let q = __chr(34);
// Build: { "a" : 1 , "b" : 2 }
let s = "{ " + q + "a" + q + " : 1 , " + q + "b" + q + " : 2 }";
let obj = json_parse(s);
let ok = 1;
if json_get(obj, "a") != 1 { let ok = 0; emit "FAIL a"; };
if json_get(obj, "b") != 2 { let ok = 0; emit "FAIL b"; };
if ok { emit "PASS"; } else { emit "FAIL"; };
```

### 7.6 `test/test_lambda_nested.ol` — Test nested lambda/HOF

```olang
// Test: Nested map/filter/reduce don't corrupt state
let data = [1, 2, 3, 4, 5];
let doubled = map(data, fn(x) { return x * 2; });
let evens = filter(doubled, fn(x) {
    return x > 4;
});
let total = reduce(evens, fn(a, b) { return a + b; });
// doubled = [2,4,6,8,10], evens = [6,8,10], total = 24
if total == 24 {
    emit "PASS";
} else {
    emit "FAIL";
    emit total;
};
```

### 7.7 `test/test_deep_recursion.ol` — Test deep recursion + TRO

```olang
// Test: Tail recursion optimization prevents stack overflow
fn sum_to(n, acc) {
    if n == 0 { return acc; };
    return sum_to(n - 1, acc + n);
};
let result = sum_to(10000, 0);
// 10000 * 10001 / 2 = 50005000
if result == 50005000 {
    emit "PASS";
} else {
    emit "FAIL";
    emit result;
};
```

### 7.8 `test/test_string_edge.ol` — Test string edge cases

```olang
// Test: Empty string, single char, escape sequences
let ok = 1;
if len("") != 0 { let ok = 0; emit "FAIL empty"; };
if len("a") != 1 { let ok = 0; emit "FAIL single"; };
if __char_at("abc", 0) != "a" { let ok = 0; emit "FAIL char_at_0"; };
if __char_at("abc", 2) != "c" { let ok = 0; emit "FAIL char_at_2"; };
if __substr("hello", 1, 3) != "el" { let ok = 0; emit "FAIL substr"; };
if __str_trim("  x  ") != "x" { let ok = 0; emit "FAIL trim"; };
if ok { emit "PASS"; } else { emit "FAIL"; };
```

### 7.9 `test/test_try_catch.ol` — Test try/catch correctness

```olang
// Test: try/catch doesn't corrupt outer variables
let outer = 42;
let caught = 0;
try {
    let inner = 99;
    __throw("test error");
    let caught = -1;  // should NOT execute
} catch {
    let caught = 1;
};
let ok = 1;
if outer != 42 { let ok = 0; emit "FAIL outer"; };
if caught != 1 { let ok = 0; emit "FAIL caught"; };
if ok { emit "PASS"; } else { emit "FAIL"; };
```

### 7.10 `test/test_dict_ops.ol` — Test dict operations

```olang
// Test: Dict create, get, set, nested
let d = { name: "olang", version: 1 };
let ok = 1;
if d.name != "olang" { let ok = 0; emit "FAIL name"; };
if d.version != 1 { let ok = 0; emit "FAIL version"; };
d.version = 2;
if d.version != 2 { let ok = 0; emit "FAIL update"; };
if ok { emit "PASS"; } else { emit "FAIL"; };
```

---

## 8. Test matrix đề xuất

### 8.1 Thêm section vào `tests.sh`

Thêm block sau vào cuối Section 2 (trước Section 3):

```bash
# ═══════════════════════════════════════════════════════════════
# SECTION 2.5: REGRESSION TESTS (edge cases found by audit)
# ═══════════════════════════════════════════════════════════════

echo -e "${CYAN}--- Regression Tests ---${NC}"

# Nested for-in
run_olang_test "regression/nested_for" \
    'let s = 0; for x in [1,2] { for y in [10,20] { let s = s + x + y; }; }; emit s;' \
    "66"

# Many locals + redefinition
run_olang_test "regression/many_locals" \
    'let a=0;let b=0;let c=0;let d=0;let e=0;let f=0;let g=0;let h=0;let i=0;let j=0;let j=j+1;emit j;' \
    "1"

# Deep while counter
run_olang_test "regression/while_counter" \
    'let a=0;let b=0;let c=0;let d=0;let e=0;let f=0;let g=0;let h=0;let c2=0;while c2<5{let c2=c2+1;};emit c2;' \
    "5"

# String empty
run_olang_test "regression/empty_string" \
    'emit len("");' \
    "0"

# Chained HOF
run_olang_test "regression/chained_hof" \
    'let r = reduce(filter(map([1,2,3,4,5], fn(x){return x*2;}), fn(x){return x>4;}), fn(a,b){return a+b;}); emit r;' \
    "24"

# Pipe operator
run_olang_test "regression/pipe_chain" \
    'let r = pipe(10, fn(x){return x*2;}, fn(x){return x+5;}, fn(x){return x-3;}); emit r;' \
    "22"

# Boolean short-circuit
run_olang_test "regression/short_circuit_and" \
    'let x = 0; if 0 && (x = 1) { emit "bad"; } else { emit x; };' \
    "0"

# Try/catch basic
run_olang_test "regression/try_catch" \
    'let c = 0; try { __throw("e"); } catch { let c = 1; }; emit c;' \
    "1"

# Array comprehension (simple)
run_olang_test "regression/array_comp" \
    'let a = [x * 2 for x in [1,2,3]]; for v in a { emit v; };' \
    "246"

echo ""
```

### 8.2 Tạo `tools/stress_test.sh` — Stress test cho VM

```bash
#!/bin/bash
# tools/stress_test.sh — Stress tests for Olang VM stability
set -euo pipefail

BINARY="${1:-./origin.olang}"
PASS=0
FAIL=0

stress() {
    local name="$1" code="$2" expected="$3" timeout="${4:-10}"
    local actual
    actual=$(echo "$code" | timeout "$timeout" "$BINARY" 2>/dev/null | sed '1,2d' | sed 's/^⦿ //; /^bye$/d' | sed '/^$/d' | tr -d '\n') || true
    if [ "$actual" = "$expected" ]; then
        echo "  OK  $name"
        PASS=$((PASS + 1))
    else
        echo "  FAIL $name (expected=$expected actual=$actual)"
        FAIL=$((FAIL + 1))
    fi
}

echo "═══ STRESS TESTS ═══"

# Fibonacci 25 (recursion depth)
stress "fib25" \
    'fn fib(n){if n<2{return n;};return fib(n-1)+fib(n-2);};emit fib(25);' \
    "75025" 30

# Large array (200 elements)
stress "array_200" \
    'let a=[];let i=0;while i<200{push(a,i);let i=i+1;};emit len(a);' \
    "200"

# Deep nested if/else (10 levels)
stress "nested_if" \
    'let x=10;if x>0{if x>1{if x>2{if x>3{if x>4{if x>5{if x>6{if x>7{if x>8{if x>9{emit "deep";};};};};};};};};}; };' \
    "deep"

# Many function definitions (20 fns)
stress "many_fns" \
    'fn f1(x){return x+1;};fn f2(x){return x+2;};fn f3(x){return x+3;};fn f4(x){return x+4;};fn f5(x){return x+5;};fn f6(x){return x+6;};fn f7(x){return x+7;};fn f8(x){return x+8;};fn f9(x){return x+9;};fn f10(x){return x+10;};emit f1(f2(f3(f4(f5(0)))));' \
    "15"

# String concat chain
stress "str_concat" \
    'let s="";let i=0;while i<50{let s=s+"x";let i=i+1;};emit len(s);' \
    "50"

# TRO factorial
stress "tro_factorial" \
    'fn fact(n,acc){if n<=1{return acc;};return fact(n-1,acc*n);};emit fact(20,1);' \
    "2432902008176640000" 15

echo ""
echo "═══ RESULTS: $PASS passed, $FAIL failed ═══"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
```

### 8.3 Tạo `tools/fuzz_test.sh` — Basic fuzz testing

```bash
#!/bin/bash
# tools/fuzz_test.sh — Basic fuzz: random valid programs, check no crash
set -euo pipefail

BINARY="${1:-./origin.olang}"
TOTAL=100
CRASH=0

echo "═══ FUZZ TEST ($TOTAL random programs) ═══"

for i in $(seq 1 $TOTAL); do
    # Generate random valid-ish program
    PROGS=(
        'emit 0;'
        'let x = 0; emit x;'
        'fn f(x) { return x; }; emit f(0);'
        'let a = []; emit len(a);'
        'let d = { x: 0 }; emit d.x;'
        'if 1 { emit 1; };'
        'let i = 0; while i < 3 { let i = i + 1; }; emit i;'
        'for x in [1] { emit x; };'
        'emit "hello";'
        'emit 2 + 3;'
        'emit __floor(3.14);'
        'emit __type_of(42);'
        'let f = fn(x) { return x; }; emit f(1);'
        'emit map([1], fn(x) { return x; })[0];'
        'try { emit 1; } catch { emit 0; };'
        'emit __bit_or(5, 3);'
        'emit __sha256("a");'
        'emit len(__str_bytes("ab"));'
        'emit __to_string(42);'
        'emit __to_number("42");'
    )
    IDX=$((RANDOM % ${#PROGS[@]}))
    CODE="${PROGS[$IDX]}"

    if ! echo "$CODE" | timeout 5 "$BINARY" >/dev/null 2>&1; then
        EXIT=$?
        if [ $EXIT -ne 0 ] && [ $EXIT -ne 124 ]; then
            echo "  CRASH [$EXIT]: $CODE"
            CRASH=$((CRASH + 1))
        fi
    fi
done

echo ""
if [ "$CRASH" -eq 0 ]; then
    echo "═══ NO CRASHES in $TOTAL runs ═══"
else
    echo "═══ $CRASH CRASHES in $TOTAL runs ═══"
fi
exit "$CRASH"
```

### 8.4 Tạo `tools/perf_bench.sh` — Performance benchmark

```bash
#!/bin/bash
# tools/perf_bench.sh — Performance benchmarks for tracking regressions
set -euo pipefail

BINARY="${1:-./origin.olang}"

bench() {
    local name="$1" code="$2"
    local start end elapsed
    start=$(date +%s%N)
    echo "$code" | timeout 60 "$BINARY" >/dev/null 2>&1 || true
    end=$(date +%s%N)
    elapsed=$(( (end - start) / 1000000 ))
    printf "  %-25s %5d ms\n" "$name" "$elapsed"
}

echo "═══ PERFORMANCE BENCHMARKS ═══"
echo "Binary: $BINARY ($(du -h "$BINARY" | cut -f1))"
echo ""

bench "fib(20)"         'fn fib(n){if n<2{return n;};return fib(n-1)+fib(n-2);};emit fib(20);'
bench "fib(25)"         'fn fib(n){if n<2{return n;};return fib(n-1)+fib(n-2);};emit fib(25);'
bench "loop_10k"        'let i=0;while i<10000{let i=i+1;};emit i;'
bench "array_push_1k"   'let a=[];let i=0;while i<1000{push(a,i);let i=i+1;};emit len(a);'
bench "string_cat_100"  'let s="";let i=0;while i<100{let s=s+"x";let i=i+1;};emit len(s);'
bench "map_100"         'let a=[];let i=0;while i<100{push(a,i);let i=i+1;};let b=map(a,fn(x){return x*2;});emit len(b);'
bench "sha256_10"       'let i=0;while i<10{let h=__sha256("benchmark");let i=i+1;};emit "done";'
bench "tro_sum_10k"     'fn s(n,a){if n==0{return a;};return s(n-1,a+n);};emit s(10000,0);'
bench "sort_100"        'let a=[];let i=100;while i>0{push(a,i);let i=i-1;};let b=sort(a);emit b[0];'

echo ""
echo "═══ DONE ═══"
```

---

## TÓM TẮT HÀNH ĐỘNG

| Ưu tiên | Bug | Effort | File |
|---------|-----|--------|------|
| 🔴 P0 | BUG-C1: Local scan 8-entry limit | ~30 phút | semantic.ol |
| 🔴 P0 | BUG-C3: ForStmt no save/restore | ~15 phút | semantic.ol |
| 🔴 P0 | BUG-C2: JSON skip_ws off-by-one | ~1 giờ | json_parse.ol |
| 🟠 P1 | BUG-H1/H2: format.ol wrong builtins | ~10 phút | format.ol |
| 🟠 P1 | BUG-H6: ExprStmt auto-emit | ~30 phút | semantic.ol |
| 🟡 P2 | BUG-H4: Match 4-arm limit | ~2 giờ | semantic.ol |
| 🟡 P2 | BUG-H5: For nesting 4-level limit | ~1 giờ | semantic.ol |
| 🟢 P3 | Thêm test files (7.1-7.10) | ~1 giờ | test/ |
| 🟢 P3 | Thêm stress/fuzz/perf tools (7.6-7.9) | ~30 phút | tools/ |

**Tổng effort ước tính: ~7-8 giờ cho toàn bộ fix + test.**

---

*Tài liệu này được tạo dựa trên phân tích tĩnh toàn bộ source code. Một số bug cần verify runtime trên máy có binary origin.olang để xác nhận.*
