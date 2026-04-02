# PLAN: Nâng cấp Olang — Làm chủ công cụ

> **ALL 4 PHASES COMPLETE (SS23, 2026-04-02)**
> Phase 1: String builtins ✅ (31/31 tests)
> Phase 2: Struct syntax ✅ (16/16 tests)
> Phase 3: Module import ✅ (4/4 tests)
> Phase 4: For/Match sugar ✅ (7/7 tests)
> Self-build: Gen2==Gen3 verified ✅
> Note: compiler.ol (self-hosting) does NOT yet support struct/import/for/match syntax.
> Python bootstrap compiler has all features. Self-hosting update is future work.

Nguyên tắc: Hoàn thiện Olang TRƯỚC. SINH tự đến sau.

## Hiện trạng Olang

| Có | Thiếu |
|----|-------|
| f64, string | integer, byte, u16 |
| array, dict (marker -4) | struct/record |
| fn, closure | module/import |
| let, while, if/else | for, match/switch |
| 77 builtins | str_replace, str_format, str_join |
| try/catch | stack trace, error types |
| Python bootstrap compiler | Olang-native import (compiler.ol chỉ compile 1 file) |

## 4 Phase — Thứ tự ưu tiên

---

### Phase 1: STRING (tuần 1)
**Mục tiêu**: Olang xử lý text không cần Python

Thêm 5 builtins vào VM (vm_nox.S):

| Builtin | Signature | Làm gì |
|---------|-----------|--------|
| `__str_replace` | (haystack, needle, replacement) → string | Thay thế substring |
| `__str_join` | (array, separator) → string | Nối array thành string |
| `__str_starts_with` | (str, prefix) → 0/1 | Check prefix |
| `__str_ends_with` | (str, suffix) → 0/1 | Check suffix |
| `__str_to_num` | (str) → f64 | Parse number |

Mỗi builtin = ~30-50 LOC ASM. Thêm vào builtin_hash_table.
Cập nhật cả compile_nox.py và compiler.ol.

**Test**: test/test_string_v2.ol — 10 test cases.
**Verify**: make test pass, make self-build pass.

---

### Phase 2: STRUCT (tuần 2)
**Mục tiêu**: Gom data có tên, không nhớ index bằng đầu

Dict đã có (DICT_MARKER = -4) nhưng chưa có syntax.
Approach: **dùng dict làm struct** — thêm syntax sugar.

**Compiler change** (compile_nox.py + compiler.ol):
```
// Syntax mới:
let node = {mol: 42, weight: 100, fire: 0};
node.mol;           // → __dict_get(node, "mol")
node.weight = 200;  // → __dict_set(node, "weight", 200)
```

**VM change**: 3 builtins mới:
| Builtin | Signature | Làm gì |
|---------|-----------|--------|
| `__dict_new` | () → dict | Tạo dict rỗng |
| `__dict_get` | (dict, key_str) → value | Lấy value theo key |
| `__dict_set` | (dict, key_str, value) → dict | Set value |

**Parser change**:
- `{key: value, ...}` → dict literal
- `expr.field` → `__dict_get(expr, "field")`
- `expr.field = value` → `__dict_set(expr, "field", value)`

**Test**: test/test_struct.ol — 10 test cases.

---

### Phase 3: MODULE (tuần 3)
**Mục tiêu**: import tường minh, không collision, không Python ghép file

**Approach**: Compile-time import resolution.

```
// Syntax:
import "encode.ol";      // compiler đọc file, compile, merge bytecode
import "knowtree.ol";
```

**Compiler change**:
- Lexer: nhận keyword `import`
- Parser: top-level `import "path"` statement
- Codegen: đọc source file → compile → nối bytecode trước main
- Dedup: nếu file đã import rồi → skip

**Không cần thay đổi VM.** Import = compile-time file inclusion, giống #include nhưng có dedup.

Compiler.ol phải tự import được. Đó là bước self-hosting thật sự.

**Test**: test/test_import.ol imports test_import_lib.ol.

---

### Phase 4: FOR + MATCH (tuần 4)
**Mục tiêu**: Syntax tiện hơn cho loop và branching

```
// for — sugar cho while
for item in array {
    emit item;
}
// → let __i = 0; while (__i < len(array)) { let item = __array_get(array, __i); ...; let __i = __i + 1; }

// match — sugar cho if/else chain
match x {
    1 => emit "one";
    2 => emit "two";
    _ => emit "other";
}
```

**Chỉ thay đổi compiler**, không thay đổi VM. Desugar tại compile time.

---

## Checklist mỗi Phase

1. [ ] Viết spec ngắn (cái gì, tại sao, syntax)
2. [ ] Code VM builtins (nếu cần)
3. [ ] Code compiler change (compile_nox.py)
4. [ ] Code compiler change (compiler.ol) — self-hosting
5. [ ] Viết tests
6. [ ] `make vm && make test` — 40/40 + tests mới
7. [ ] `make self-build` — Gen2==Gen3
8. [ ] Commit

## Không làm

- Không thêm class/inheritance — struct đủ rồi
- Không thêm generics — Olang dùng duck typing
- Không thêm async/await — concurrency đợi sau khi SINH hoạt động
- Không refactor VM register convention — đã stable, đừng đụng
