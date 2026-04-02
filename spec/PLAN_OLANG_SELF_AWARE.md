# PLAN: Olang Self-Aware — Ngon ngu tu biet minh

> Date: 2026-04-02
> Status: DESIGN
> Author: Nox
> Depends: compiler.ol sync (R1), VM v2 (LOCKED)

---

## MUC TIEU

Olang tu nhan biet minh co gi: cau truc, ngu phap, ham, bien, module.
Tu dong nham dien, dang ky, kiem soat, cap nhat, debug, thong bao loi.
Tu doc .ol de nap. Tu hieu .ol la data hay program.
Cap nhat realtime khong can khoi dong lai.
Tu co version control cua rieng no.
Tu xuat ra .ol.

---

## RESEARCH — Cai the gioi da lam

### 1. Smalltalk/Pharo — Image System
- Toan bo runtime (objects, classes, methods, compiler, debugger) = 1 file "image"
- Save = serialize TOAN BO object memory. Load = wake up y het
- Compiler chay TRONG runtime. Thay doi method → co hieu luc NGAY
- **Steal**: Heap snapshot. Olang heap la byte array → serialize truc tiep

### 2. Erlang/BEAM — Hot Code Reload
- VM giu 2 version moi module: "current" va "old"
- Load code moi: old ← current, current ← new
- Process dang chay old → chuyen sang current tai call boundary
- Load version 3 → purge old, kill process con dang chay old
- **Steal**: 2-version function table. OP_CALL luon resolve "current"

### 3. Forth — Compile/Run Boundary = 0
- 1 dictionary la CA chuong trinh VA compiler
- IMMEDIATE word = chay LUC COMPILE thay vi duoc compile
- `:` bat dau compile. `;` (IMMEDIATE) ket thuc compile
- Control structures (IF/THEN/ELSE) = IMMEDIATE words emit branch instructions
- **Steal**: IMMEDIATE functions. Compiler gap IMMEDIATE fn → chay ngay, fn emit bytecode

### 4. Red/Rebol — Code = Data
- `[print "hello"]` vua la code vua la data (block)
- PARSE la FSM tren blocks — co the pause, serialize, resume
- **Steal**: OP_QUOTE push bytecode as data. OP_EVAL chay data as bytecode

### 5. Unison — Content-Addressed Code
- Moi definition = SHA3 hash cua syntax tree
- Ten chi la label tro den hash. Rename = doi label, hash khong doi
- Codebase = database, khong phai files
- **Steal**: FNV hash bytecode → dedup, cache, integrity check

### 6. COLA (Piumarta/Kay) — Self-Describing System
- ~20K lines. Object system (Id) + functional language (Coke/Jolt)
- Vtable tai offset -1. `send(obj, selector)` → lookup → call
- Bootstrap: khi selector == "lookup" && obj == VtableVT → hardcode. Moi thu khac = message send
- Chi 4 methods can: lookup, addMethod, newInstance, newDelegatingToMe
- **Steal**: Vtable dispatch. Moi object co type tag → dispatch table → overridable

### 7. Alan Kay "Worlds" (VPRI, ECOOP 2011)
- World = reified program state. sprout() → child world
- Mutations trong child = invisible voi parent
- commit() merge ve. abort() huy
- Implementation: copy-on-write, chi luu delta
- **Steal**: Safe self-modification. Test code moi trong child world truoc khi commit

### 8. Truffle/Graal — Self-Optimizing Bytecode
- AST node tu rewrite chinh minh tai runtime dua tren observed types
- OP_ADD lan dau thay int → rewrite thanh OP_ADD_INT
- Khi stabilize → partial evaluation → native code
- **Steal**: Self-rewriting opcodes. ~30 LOC VM

### 9. Julia — Compiler as Library
- `:(x + 1)` → Expr object. Inspect, modify, eval()
- Generated functions: inspect types → return specialized code
- **Steal**: AST as first-class data. parse() → dict tree → manipulate → codegen → eval

### 10. Zig — comptime
- `comptime` keyword: evaluate DURING compilation
- Types la first-class values. @typeInfo(T) → tagged union mo ta type
- **Steal**: comptime blocks = chay VM tai compile time, inline ket qua

---

## KIEN TRUC — 3 TANG

```
+-------------------------------------------------------------+
| TANG 3: meta.ol — NAO PHAN XA                              |
|   scan, registry, load, reload, export, diff, diagnose       |
+-------------------------------------------------------------+
| TANG 2: compiler.ol — GIAC QUAN (doc/hieu chinh minh)        |
|   lex → tokens, parse → AST, codegen → bytecode             |
|   + __eval_bytecode (chay code moi tai runtime)              |
+-------------------------------------------------------------+
| TANG 1: VM vm_nox.S — CO THE (LOCKED)                       |
|   56 opcodes, 94 builtins, 3-zone heap, var_matrix           |
+-------------------------------------------------------------+
```

### Nguyen tac:
- **KHONG sua VM** (tru khi Lupin cho phep)
- **Tat ca bang Olang thuan** — dung compiler.ol + __eval_bytecode + __file_read + dict
- **Compiler = giac quan**, khong phai build tool

---

## BLOCKER #1: compiler.ol SYNC (R1)

compiler.ol thieu 12 features so voi compile_nox.py:

### Phase 1: Co ban (~40 LOC)
| # | Feature | Chi tiet |
|---|---------|---------|
| 1 | Escape sequences | \n \r \t \0 \\ \" trong string lexer |
| 2 | !expr | parse_unary: !x → x == 0 |

### Phase 2: Syntax (~120 LOC)
| # | Feature | Chi tiet |
|---|---------|---------|
| 3 | arr[i] postfix | parse_primary: postfix [ ] → __array_get |
| 4 | arr[i] = val | detect assignment after index → __set_at |
| 5 | {key: val} | parse_primary: { } with : → __dict_new + __dict_set |
| 6 | .field | postfix . → __dict_get(obj, "field") |
| 7 | .field = val | detect assignment after dot → __dict_set |

### Phase 3: Control flow (~80 LOC)
| # | Feature | Chi tiet |
|---|---------|---------|
| 8 | try/catch/throw | emit OP_TRY_BEGIN(0x1A), OP_CATCH_END(0x1B), OP_THROW(0x78) |
| 9 | break/continue | track break_targets/continue_targets, emit JMP/LOOP |

### Phase 4: Sugar (~60 LOC)
| # | Feature | Chi tiet |
|---|---------|---------|
| 10 | for x in arr | desugar → while + __array_get + len |
| 11 | match x { } | desugar → if/else chain |
| 12 | import "file" | resolve_imports + dedup |

### Phase 5: Kho nhat (~150 LOC)
| # | Feature | Chi tiet |
|---|---------|---------|
| 13 | Closure captures | _collect_lets, _find_free_vars, _walk_free → OP_CLOSURE_CAP(0x30) |

### Verify:
```bash
# Sau moi phase:
make vm && make test                    # 40/40
make self-build                         # compiler.ol compile chinh no
make fixed-point                        # Gen2 == Gen3
# Them: compile 1 file dung feature moi bang compiler.ol → ket qua giong Python
```

---

## SAU R1: meta.ol — OLANG TU BIET MINH

### 7 Chuc nang cot loi

#### 1. meta_scan(path) → info dict
```
Doc file .ol → lex → parse → walk AST
Tra ve: {
  type: "module" | "program" | "data",
  functions: [{name, params, line}, ...],
  variables: [{name, line}, ...],
  imports: [paths],
  ast: <raw AST>
}
```
- Tu phan biet: co fn → module/program, chi co let + literals → data
- Dung compiler.ol lex/parse — KHONG tao parser moi

#### 2. meta_load(path) → hot load
```
source = __file_read(path)
tokens = lex(source)
ast = parse_program(tokens)
bytecode = codegen(ast)        // chi tra raw bytecode, khong wrap VM binary
__eval_bytecode(bytecode)      // inject vao var_matrix
→ ham moi available NGAY, khong restart
```

#### 3. meta_reload(path) → hot reload
```
old_info = __dict_get(_registry, path)
new_info = meta_scan(path)
diff = meta_diff(old_info, new_info)     // +fn, -fn, ~fn (modified)
bytecode = codegen(new_info.ast)
__eval_bytecode(bytecode)                // overwrite cu trong var_matrix
__dict_set(_registry, path, new_info)
→ code moi thay the code cu tai call boundary
```

#### 4. _registry — Global dict
```
_registry = {
  "stdlib/brain.ol": {
    type: "module",
    functions: [...],
    variables: [...],
    version: 3,
    loaded_at: 1743600000,
    bytecode_hash: 0xA3F2B1C4
  },
  ...
}
```
- Query: meta_list_modules(), meta_list_functions(), meta_info(name)
- Track version moi lan reload

#### 5. meta_export(path, names) → viet .ol
```
Lay functions/variables tu _registry
Serialize ve Olang syntax
Ghi ra file .ol
```
- Olang tu viet ra Olang. Code generation nguoc.

#### 6. meta_diff(old, new) → delta
```
So sanh 2 scan results:
  added: functions trong new khong co trong old
  removed: functions trong old khong co trong new
  modified: cung ten nhung params/body khac
```

#### 7. meta_diagnose() → self-check
```
Scan tat ca modules trong _registry
Check: ham nao goi ham nao? (dependency graph)
Check: ham nao khong duoc goi? (dead code)
Check: bien nao shadow bien khac? (name collision)
Report: loi, warning, suggestion
```

---

## .ol = FORMAT DUY NHAT

### Quy uoc:
```olang
// Program file — co fn, co main logic
// stdlib/brain.ol
import "knowtree.ol";
fn brain_boot(dir) { ... };
brain_boot("/tmp/nox");
```

```olang
// Module file — chi co fn, khong co main logic
// stdlib/silk.ol  
fn silk_fire(a, b) { ... };
fn silk_weight(a, b) { ... };
```

```olang
// Data file — chi co let + literals
// data/cities.ol
let cities = [
    {name: "Ha Noi", lat: 21.03},
    {name: "Sai Gon", lat: 10.82},
];
```

```olang
// Config file — chi co let + scalars
// config/settings.ol
let heap_size = 256;
let persist_dir = "/tmp/nox_data";
```

meta_scan tu phan biet type dua tren noi dung (co fn? co top-level calls?).

### Binary data?
.bin/.dat van dung cho binary (p_weight_table.bin, nrc_vad_hash.bin).
Nhung metadata VE chung → .ol:
```olang
// data/tables.ol — metadata cho binary files
let p_weight_path = "data/p_weight_table.bin";
let p_weight_size = 131072;
let p_weight_entries = 65536;
let nrc_vad_path = "data/nrc_vad_hash.bin";
```

---

## VERSION CONTROL — WAL-based

### Moi thay doi duoc log:
```
WAL entry: [timestamp:8][action:1][path_hash:4][old_hash:4][new_hash:4] = 21 bytes

Actions:
  1 = LOAD    (first time)
  2 = RELOAD  (update)
  3 = REMOVE  (unload)
```

### meta_history(path) → version list
```
[{version: 1, timestamp: ..., hash: 0xA3F2},
 {version: 2, timestamp: ..., hash: 0xB1C4, diff: "+1fn ~2fn"}]
```

### meta_rollback(path, version) → quay ve
```
Tim bytecode_hash cua version do trong WAL
Neu co cached bytecode → eval
Neu khong → doc source tu git/backup → compile → eval
```

---

## ERROR SYSTEM

### Compiler errors (parse/compile time):
```
meta_try_load("broken.ol") → {
  ok: 0,
  error: "Parse error: expected ';'",
  file: "broken.ol",
  line: 42,
  col: 15,
  context: "let x = 1 + "
}
```

### Runtime errors (eval time):
```
VM da co line table + stack traces.
meta_load wrap trong try/catch:
  try { __eval_bytecode(bc); } catch(e) { return {ok:0, error: e}; }
```

---

## THU TU IMPLEMENT

```
PHASE 0: R1 compiler.ol sync          ~450 LOC    ← BLOCKER
  0.1: escape + !expr                  ~40 LOC
  0.2: arr[i], dict, dot               ~120 LOC
  0.3: try/catch, break/continue       ~80 LOC
  0.4: for, match, import              ~60 LOC
  0.5: closure captures                ~150 LOC

PHASE 1: meta.ol core                 ~200 LOC
  1.1: meta_scan(path)                 ~80 LOC
  1.2: meta_load(path)                 ~40 LOC
  1.3: _registry dict                  ~30 LOC
  1.4: meta_reload(path)               ~50 LOC

PHASE 2: meta.ol advanced             ~200 LOC
  2.1: meta_export(path, names)        ~80 LOC
  2.2: meta_diff(old, new)             ~40 LOC
  2.3: meta_diagnose()                 ~50 LOC
  2.4: meta_history + WAL              ~30 LOC

PHASE 3: Integration                   ~100 LOC
  3.1: nox_brain_main.ol dung meta     ~30 LOC
  3.2: Error wrapping                   ~30 LOC
  3.3: Tests                            ~40 LOC

Total: ~950 LOC
```

---

## RESEARCH PHASE 2 — Chi tiet ky thuat

### 11. Smalltalk Spur Object Format (64-bit)
- Moi object = 1 header 64-bit: [slot_count:8][hash:22][format:5][immutable:1][pinned:1][gc:3][class_index:22]
- Class index TABLE (22-bit), khong phai class pointer. VM giu global table: index → class object
- Compiler = object TRONG image. Sua method = tao CompiledMethod moi → install vao method dictionary
- **Steal cho Olang**: var_matrix entries co the co "type tag" (class index). Thay vi flat hash → typed dispatch

### 12. COLA Bootstrap — Chi 230 LOC C
- 1 struct: `object { vtable *_vtable; data... }`
- 4 operations: allocate, delegated, addMethod, lookup
- Fixed-point trick: `vtable_vt->_vtable == vtable_vt` (self-referential)
- Hard-code 1 function (lookup). Moi thu khac = message send
- Sau bootstrap → co the redefine CHINH lookup
- **Steal cho Olang**: Minimal self-describing system. Olang chi can 4 operations tuong tu:
  - `meta_define(name, bytecode)` = addMethod
  - `meta_lookup(name)` = lookup
  - `meta_create(template)` = allocate
  - `meta_delegate(parent)` = delegated

### 13. Factor — Cross-Reference Database
- Moi "word" (function) co dependency graph: ai goi no, no goi ai
- Khi sua 1 word → Factor biet CHINH XAC words nao can recompile
- Cascade recompilation qua xref graph
- **Steal cho Olang**: meta_diagnose() xay dependency graph tu AST.
  Khi meta_reload() → chi recompile affected functions, khong phai toan bo

### 14. Julia World Age — Safe Hot Reload
- Global counter tang moi khi define method/type/constant
- Moi task co local world age. Chi goi duoc methods co birth_age <= task_world_age
- World age chi tang tai TOP-LEVEL statement boundaries
- Backedges: khi compile f() goi g(), luu backedge g→f. Neu g thay doi → invalidate f
- **Steal cho Olang**: world_age counter trong meta.ol
  - meta_load tang counter
  - Running code chi thay functions co age <= load time
  - Explicit `meta_update()` de nang world age (= Erlang fully-qualified call)

### 15. Erlang — Fully-Qualified vs Local Calls
- `Module:function()` = LUON dispatch to current version
- `function()` = goi version hien tai cua process
- Pattern: process nhan `code_switch` message → goi Module:loop() → nhay sang code moi
- State (heap data) SONG SOT qua code swap
- **Steal cho Olang**: 2 kieu call:
  - `fn_name()` = local (chay version luc load)
  - `meta_call("fn_name", args)` = fully-qualified (luon lay current)

### 16. Intentional Programming / Dark — Code = Database
- Khong co parser. Structured editor thao tac truc tiep tren AST
- Moi node co unique identity. Rename = doi 1 record
- Dark: moi keystroke luu vao DB trong 50ms. Edit → execute = 50ms
- **Steal cho Olang**: meta_registry LA database. Khong phai file-based.
  Functions luu theo hash, ten la label. Rename = doi label.

---

## TUONG LAI (sau khi meta.ol hoat dong)

| # | Item | Nguon | Mo ta |
|---|------|-------|-------|
| F1 | Image/Snapshot | Smalltalk | Serialize heap → disk, wake up y het |
| F2 | Worlds | VPRI/Kay | Copy-on-write heap, test truoc commit |
| F3 | Self-rewriting bytecode | Truffle | OP_ADD → OP_ADD_INT tai runtime |
| F4 | Content-addressed fns | Unison | FNV hash bytecode, dedup, cache |
| F5 | IMMEDIATE functions | Forth | Chay tai compile time, emit bytecode |
| F6 | Cross-reference graph | Factor | Dependency tracking, cascade recompile |
| F7 | World age counter | Julia | Safe hot reload, backedge invalidation |
| F8 | GC mark-sweep | R4 | Long-running programs |
| F9 | FFI .so loader | R2 | dlopen, C ecosystem |
| F10 | Bytecode JIT | R3 | 2-4x tat ca Olang code |

---

## NGUYEN TAC

1. KHONG sua VM — tat ca bang Olang thuan
2. Compiler = giac quan, khong phai build tool
3. __eval_bytecode = tay (modify chinh minh)
4. meta.ol = nao ket noi mat va tay
5. .ol = format duy nhat (data, program, config)
6. TINH khong TRA — compiler PARSE, khong if/else keyword
7. Test TRUOC moi phase: make test + make self-build + make fixed-point
8. R1 la BLOCKER — khong co R1 thi meta.ol vo nghia

---

*Olang's compiler = its eyes for reading itself.
__eval_bytecode = its hands for modifying itself.
meta.ol = the brain that connects eyes and hands.
Khi 3 thu nay ket noi → Olang SONG.*
