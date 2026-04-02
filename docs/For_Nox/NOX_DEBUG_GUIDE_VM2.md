# Olang Debug Guide — VM v2 + Self-Hosting Compiler
> Sora viết cho Nox. Đọc TRƯỚC KHI code.
> Cập nhật: 2026-04-02. Dựa trên SS24 Handoff + source code + VM_SPEC_COMPLETE.

---

## 0. TRẠNG THÁI HIỆN TẠI

```
compiler.ol  : ~1210 LOC, SELF-HOSTING (Gen2==Gen3 verified)
VM v2        : vm_nox.S, 5257 LOC, 67 opcodes, 44 builtins, 46KB binary
Python boot  : compile_nox.py, 745 LOC (chỉ dùng để build gen1)
Test         : 40/40 + 35/35 benchmark
```

### Compiler Progress (B1–B11)

| Step | Feature | Status |
|------|---------|--------|
| B1 | Escape sequences `\n\r\t\0\\"` | ✅ DONE |
| B2 | `!expr` → `expr == 0` | ✅ DONE |
| B3 | `arr[i]` → `__array_get`, `arr[i]=val` → `__set_at` | ✅ DONE |
| B4 | Dict literal `{key: val}` → `__dict_new` + `__dict_set` | ✅ DONE |
| B5 | `.field` → `__dict_get`, `.field=val` → `__dict_set` | ✅ DONE |
| B6 | `try/catch/throw` | ❌ BLOCKED — gen1 nested if limit |
| B7 | `break/continue` | ⬜ TODO |
| B8 | `for` loop | ⬜ TODO |
| B9 | `match` | ⬜ TODO |
| B10 | `import` | ⬜ TODO |
| B11 | Closure captures | ⬜ TODO |

### B6 Blocker & Giải pháp

compiler.ol tự compile chính nó. Mỗi dòng code thêm vào = thêm tải cho gen1 khi tự compile.

**Gen1 limits:**
- `parse_primary`: ~15 sequential ifs → thêm nested if = crash
- `compile_node`: ~20 sequential ifs → thêm 2 cái nữa = crash
- Keyword chain: 9 nested ifs → thêm 3 (12 total) = crash

**Giải pháp (PHẢI làm TRƯỚC khi thêm B6):**
1. Tách `compile_node` → `compile_stmt_node(kind, node)` + `compile_expr_node(kind, node)`. Giảm if xuống <15 mỗi hàm.
2. Keywords mới dùng flat check với `kw` flag, KHÔNG nested if.
3. parse_statement: dispatch try/throw TRƯỚC if chain.

---

## 1. Build & Verify

```bash
# Build VM
make vm                    # → vm/x86_64/vm_nox (46KB)

# Run tests
make test                  # 40/40
make benchmark             # 35/35

# Self-hosting pipeline
python3 tools/compile_nox.py stdlib/compiler.ol /tmp/compiler_gen1.olang   # Python→gen1
rm -f /tmp/.nox_args && /tmp/compiler_gen1.olang                           # gen1→gen2
cp /tmp/compiler_gen2.olang /tmp/g2s.olang && /tmp/g2s.olang               # gen2→gen3
diff /tmp/g2s.olang /tmp/compiler_gen2.olang                               # Gen2==Gen3?

# Compile other files
printf 'test/file.ol\n/tmp/out.olang\n' > /tmp/.nox_args && /tmp/compiler_gen1.olang
```

**LUÔN verify Gen2==Gen3 SAU MỖI THAY ĐỔI compiler.ol.**

---

## 2. Ngôn ngữ Olang — Syntax hiện tại

### Hoạt động (compiler.ol B1–B5 hỗ trợ)

```olang
// Variables
let x = 42;
let name = "hello\nworld";     // B1: escape sequences
let hex = 0xFF;

// Assignment (bare, không let)
x = x + 1;                     // OK trong while — KHÔNG dùng let x = x + 1

// Functions
fn add(a, b) { return a + b; };

// If / else if / else
if x > 0 { emit "pos"; }
else if x == 0 { emit "zero"; }
else { emit "neg"; };

// While
let i = 0;
while i < 10 { i = i + 1; };   // bare assign, KHÔNG let

// Arrays (B3)
let arr = [1, 2, 3];
let v = arr[0];                 // B3: index syntax → __array_get
arr[0] = 99;                    // B3: index assign → __set_at
push(arr, 4);

// Dict (B4 + B5)
let d = {name: "Nox", age: 1}; // B4: dict literal
emit d.name;                    // B5: .field access
d.age = 2;                      // B5: .field assign

// Negation (B2)
let ok = !condition;             // B2: !expr → expr == 0

// Strings (u16 molecules, mỗi char 2 bytes)
let s = "hello";
let c = char_at(s, 0);
let sub = substr(s, 1, 3);      // end EXCLUSIVE
let combined = "ab" + "cd";

// Boolean
true = 1.0, false = 0.0

// Operators (đúng precedence)
+ - * / %  == != < > <= >=  && ||

// Comments
// line     # line     /* block */

// Emit
emit "x = " + __to_string(x);
```

### Chưa có trong compiler

| Feature | Step | Workaround |
|---------|------|------------|
| `try/catch/throw` | B6 BLOCKED | Không có |
| `break/continue` | B7 | Flag variable |
| `for` loop | B8 | `while` |
| `match` | B9 | if/else chain |
| `import` | B10 | Concat source files |
| Closure captures | B11 | Pass qua args |
| `type`/`union` | Không trong kế hoạch | Dict + convention |
| String interpolation | Không có | `"x=" + __to_string(x)` |

---

## 3. VM Opcodes — 67 implemented

### Compiler đang emit (~30 opcodes)

```
00=NOP   01=Push(str)  02=Load     06=Emit     07=Call
08=Ret   09=Jmp        0A=Jz       0B=Dup      0C=Pop
0D=Swap  0E=Loop       0F=Halt     13=Store    15=PushNum
19=PushMol  24=CallClosure  25=Closure  26=LoadReg  27=StoreReg
28=EnterFrame  29=LeaveFrame
2A=Add  2B=Sub  2C=Mul  2D=Div  2E=Mod
31=Eq   32=Ne   33=Lt   34=Gt   35=Le   36=Ge
```

### VM có nhưng compiler CHƯA emit

**Molecule (0x40–0x47)** — native 5D ops, nhanh hơn stdlib:
```
40=MolPack  41=MolUnpack  42=MolDist  43=MolCompose
44=MolDominant  45=MolBatchDist  46=MolEncode  47=MolDecode
```

**KnowTree (0x50–0x54):**
```
50=KtStore  51=KtLoad  52=KtNearest  53=KtWalk  54=KtLearn
```

**Silk (0x58–0x5B):**
```
58=SilkFire  59=SilkDecay  5A=SilkWalk  5B=SilkImplicit
```

**Arena (0x60–0x65):**
```
60=AllocA  61=AllocB  62=AllocC  63=ResetC  64=ResetB  65=HeapPin
```

**Security (0xB0–0xB4):**
```
B0=CapCheck  B1=CapCreate  B2=CapDelegate  B3=CapRevoke  B4=SecGate
```

**Exception (cần cho B6):**
```
1A=TryBegin  1B=CatchEnd  78=Throw
```

**Struct (cần cho B9 match):**
```
80=StructTag  81=MatchEnum  82=EnumField  83=EnumPayload
```

**Super/Fused (0xA0–0xAF) — spec only, chưa implement:**
```
A0=LoadRegAdd  AF=TailCall  (16 opcodes optimization)
```

---

## 4. Tất cả 44 Builtins

### Math (6)
```
__floor(x)  __ceil(x)  __abs(x)  __sqrt(x)  __exp(x)  __log2(x)
```

### String (9)
```
len(s)              char_at(s, i)           substr(s, start, end)
__str_trim(s)       __str_index_of(hay, n)  __str_find(hay, n)
__to_string(n)      __char_code(ch)         __write_raw(s)
```

### Array (8)
```
len(a)              push(a, val)            __array_get(a, i)
__set_at(a, i, v)   __array_with_cap(n)     __array_new(e0..eN, count)
__pop_arr(a)        __range(n)
```

### Bitwise (5)
```
__bit_and(a, b)  __bit_or(a, b)  __bit_xor(a, b)
__bit_shl(a, n)  __bit_shr(a, n)
```

### File I/O (4)
```
__file_read(path)    __file_write(path, content)
__file_append(path, content)   __file_append_bytes(path, bytes)
```

### Network (5)
```
__tcp_listen(port)   __tcp_accept(fd)    __tcp_send(fd, data)
__tcp_recv(fd, max)  __tcp_close(fd)
```

### System (5)
```
__system(cmd)   __sleep(ms)   __heap_used()   __heap_pin()   __type_of(x)
```

### Matrix (2)
```
__mx_w(idx, val)   __mxr(idx)
```

### Activation (5)
```
__act_set(mol, v)    __act_get(mol)       __act_add(mol, delta)
__act_reset()        __act_decay_all(factor)
```

### Convert (1)
```
__f64_to_le_bytes(n)
```

---

## 5. Gen1 Constraints — ĐẶC BIỆT QUAN TRỌNG

compiler.ol là con rắn tự ăn đuôi mình. Gen1 có GIỚI HẠN:

```
⚠️  <15 nested if trong 1 hàm
⚠️  <20 sequential if trong 1 hàm
⚠️  Keyword chain: <12 nested ifs
```

### Patterns an toàn

```olang
// ❌ Nested if chain quá dài
if kind == "let" { ... }
else if kind == "fn" { ... }
else if kind == "if" { ... }    // 15+ = crash gen1

// ✅ Flat check với flag
let handled = 0;
if kind == "let" { ...; handled = 1; };
if kind == "fn" && handled == 0 { ...; handled = 1; };
if kind == "if" && handled == 0 { ...; handled = 1; };

// ✅ Tách helper function
fn compile_stmt_node(kind, node) { ... };  // <15 ifs
fn compile_expr_node(kind, node) { ... };  // <15 ifs

// ✅ Flat keyword check
let kw = 0;
if word == "try" { add_token(TK_TRY, word); kw = 1; };
if word == "catch" && kw == 0 { add_token(TK_CATCH, word); kw = 1; };
if kw == 0 { add_token(TK_IDENT, word); };
```

---

## 6. Debug khi crash

### Segfault
```bash
gdb -batch -ex "run" -ex "bt" -ex "info registers" --args ./output.olang
```

### Gen1 self-compile crash
```bash
# Bước 1: Python compile OK?
python3 tools/compile_nox.py stdlib/compiler.ol /tmp/gen1.olang

# Bước 2: gen1 tự compile?
rm -f /tmp/.nox_args && /tmp/gen1.olang
# Crash ở đây = gen1 limit → đếm nested ifs

# Bước 3: gen2==gen3?
cp /tmp/compiler_gen2.olang /tmp/g2s.olang && /tmp/g2s.olang
diff /tmp/g2s.olang /tmp/compiler_gen2.olang
```

### Silent fail
Gọi builtin/function sai tên → push 0 im lặng. Kiểm tra tên chính xác.

### Array overflow
`[]` cap=16. Push >16 = crash. Dùng `__array_with_cap(N)`.

### String gotcha
String = u16 molecules. `emit "x=" + 42` = undefined. PHẢI `__to_string(n)`.

---

## 7. VM Memory Layout

```
[VM Stack 16MB]     r14 grows DOWN (16 bytes/entry)
[Guard 4K]
[Zone C →]          r15 grows UP (heap)
[Guard 4K]
[← Zone B]
[Zone A →]          BSS:
  var_matrix         512KB
  mol_matrix         128KB
  act_matrix         128KB
  silk_matrix        128KB
[Bytecode]          appended after VM ELF
```

Stack entry types:
```
-1 = f64    -2 = forward    -3 = array
-4 = dict   -5 = array_cap  >=0 = string (len = mol_count)
```

---

## 8. Scope cơ chế

- **Closure call**: VM push MARKER → Store saves old value → Ret unwinds
- **While/if**: KHÔNG có scope. `let` overwrite global slot.
- **Bare assign** (`x = x + 1`): overwrite cùng slot, OK cho while
- **Mutable shared state**: `let x = [0]` + `__set_at`/`__array_get`

---

## 9. Roadmap

### Mở khóa B6–B11
1. Tách compile_node → stmt + expr helpers
2. Verify Gen2==Gen3
3. B6 try/catch → TryBegin(0x1A), CatchEnd(0x1B), Throw(0x78)
4. B7 break/continue → Jmp out of while

### Sau đó
5. B8 for → desugar thành while
6. B9 match → StructTag/MatchEnum (0x80–0x83)
7. B10 import → concat source hoặc bytecode linking
8. B11 closure captures → ClosureCapture (0x30)

### Dài hạn
- Compiler emit native opcodes (Mol/KnowTree/Silk) thay vì stdlib
- Super/fused opcodes cho performance
- Security opcodes cho sandboxing

---

## 10. Tài liệu tham khảo

- `spec/VM_SPEC_COMPLETE.md` — 4711 LOC, 53 sections
- `spec/SPEC_R1_COMPILER_SYNC.md` — 11 bước spec compiler
- `spec/PLAN_OLANG_SELF_AWARE.md` — vision + research
- `memory/project_r1_context.md` — working context, rules
- `spec/SPEC_BP2_ENCODE.md` → `SPEC_BP11_BODY.md` — Brain specs
- `docs/NOX_ALGORITHM_BIBLE.md` — 99KB algorithms
