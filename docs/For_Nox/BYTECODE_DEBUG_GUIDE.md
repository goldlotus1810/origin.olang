# BYTECODE DEBUG GUIDE — Self-build eval glitch

> Nox: Root cause = Olang compiler produces different bytecode from Rust compiler.
> Cần so sánh bytecode output để tìm chỗ khác nhau.

---

## STEP 1: Xác định chính xác nơi fail

Thêm debug emits vào repl_eval TRƯỚC khi rebuild:

```olang
// Trong repl_eval, sau "let src = __str_trim(input);"
emit "DEBUG-1: src len=" + __to_string(len(src));

// Sau "let _re_first = char_at(src, 0);"
emit "DEBUG-2: first=" + _re_first + " code=" + __to_string(__char_code(_re_first));

// Sau "let _re_2 = __substr(src, 0, 2);"
emit "DEBUG-3: re_2=" + _re_2 + " len=" + __to_string(len(_re_2));

// Sau mỗi keyword check
emit "DEBUG-4: is_code=" + __to_string(_re_is_code);

// Trước __eval_bytecode
emit "DEBUG-5: g_pos=" + __to_string(_g_pos) + " bc_len=" + __to_string(len(bc));
```

Rebuild rồi test:
```bash
make build && ./origin.olang --build && chmod +x origin_new.olang
echo 'emit 42;' | ./origin_new.olang
```

Nếu thấy:
- DEBUG-1: src len=8 → trim OK
- DEBUG-2: first=e code=101 → char_at OK
- DEBUG-3: re_2=em len=2 → __substr OK
- DEBUG-4: is_code=1 → classifier OK → bug ở compiler
- DEBUG-4: is_code=0 → classifier FAIL → bug ở __substr hoặc __eq

---

## STEP 2: So sánh bytecode

Thêm vào repl.ol 1 command mới (tạm) để dump bytecode:

```olang
// Thêm sau "help" command:
if src == "dump" {
    // Compile "emit 42;" và dump bytecode
    let _d_code = "emit 42;";
    let _d_tokens = tokenize(_d_code);
    let _d_ast = parse(_d_tokens);
    _g_pos = 0;
    analyze(_d_ast);
    let _d_out = "BC[" + __to_string(_g_pos) + "]:";
    let _d_i = 0;
    while _d_i < _g_pos {
        _d_out = _d_out + " " + __to_string(__array_get(_g_output, _d_i));
        _d_i = _d_i + 1;
    };
    return _d_out;
};
```

Test cả hai binaries:
```bash
echo 'dump' | ./origin.olang           # Rust-built
echo 'dump' | ./origin_new.olang       # Self-built
```

So sánh output. Nếu khác nhau → bytecode generation bug.

---

## STEP 3: Nếu classifier OK nhưng bytecode sai

Expected bytecode cho "emit 42;":
```
[15]         PushNum
[bytes×8]    f64 value 42.0 (LE: 0x00 0x00 0x00 0x00 0x00 0x00 0x45 0x40)
[6]          Emit
[15]         Halt (hoặc end marker)
```

Nếu self-built BC khác → check semantic.ol compile_expr for NumLit:
```olang
// semantic.ol handles Expr::NumLit
emit_op(state, make_op_num("PushNum", value));
```

Check `emit_num` function — nó dùng `__f64_to_le_bytes()` có đúng không?

---

## STEP 4: Nếu classifier FAIL (__substr hoặc __eq bug)

Test trực tiếp:
```bash
echo 'let s = "emit 42;"; let r = __substr(s, 0, 2); emit r;' | ./origin_new.olang
# Expect: em

echo 'emit __eq("em", "em");' | ./origin_new.olang
# Expect: 1 (hoặc empty chain = truthy)

echo 'emit __eq(__substr("emit", 0, 2), "em");' | ./origin_new.olang
# Expect: 1
```

Nếu __substr trả sai → bug trong Boot bytecode cho __substr.
Nếu __eq trả sai → bug trong string comparison.

---

## STEP 5: Nếu eval KHÔNG chạy gì cả

Có thể tokenize() hoặc parse() crash silently.
Test:
```bash
echo 'let t = tokenize("emit 42;"); emit len(t);' | ./origin_new.olang
# Expect: 4 (emit, 42, ;, EOF)
```

Nếu 0 → tokenize broken.
Nếu > 0 → parse hoặc analyze broken.

---

## LIKELY ROOT CAUSE CANDIDATES

### 1. String literal encoding mismatch
```
_emit_str_u16 emits: [mol_count:u16][byte0:1][0x21:1][byte1:1][0x21:1]...
VM cg_push reads:     [mol_count:u16][molecule data: mol_count * 2 bytes]

These SHOULD match. But verify __str_bytes returns correct bytes.
```

### 2. `let` inside while loops (loop counters)
```
_emit_str_u16 has: let _esu_i = _esu_i + 1;
_emit_str has:     let _es_i = _es_i + 1;
emit_call has:     let _ec_i = _ec_i + 1;
... and 30+ more places in semantic.ol

In self-built binary, if while loop body creates scope frames,
these "let" increments would be lost each iteration.
→ Infinite loop or wrong bytecode output.

While loops SHOULD NOT create scope frames (only fn calls do).
But verify: is the while loop body compiled correctly?
```

### 3. fn_registry accumulation during self-build
```
Builder compiles 47 files sequentially.
Each file defines functions that go into fn_registry.
fn_registry is never cleaned between files.
When REPL runs, fn_registry may have stale entries from builder.
```

### 4. _g_output_ready flag
```
_prefill_output() checks _g_output_ready == 0.
If builder already set it to 1 during compilation,
REPL's _prefill_output() skips allocation.
But builder's _g_output is still in var_table.
→ REPL writes to builder's old buffer? Or empty buffer?

Reset: _g_output_ready should be 0 after builder finishes.
```

---

## QUICK FIX TO TRY

Thêm explicit reset trước REPL loop starts (trong repl.ol init):

```olang
// Đầu file repl.ol hoặc trong init section:
_g_output_ready = 0;     // force fresh allocation
_g_output = [];           // clear old reference
_g_pos = 0;
```

Rebuild + test. Nếu fix → root cause là stale state từ builder.

---

*Sora — debug guide. Nox pick step 1, trace từ trên xuống.*
