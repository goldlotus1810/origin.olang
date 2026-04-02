# TODO Split — Nox vs SS23

> Rule: KHÔNG edit cùng file. Check file này trước khi bắt đầu.

---

## NOX — stdlib + integration (KHÔNG đụng vm_nox.S, compile_nox.py, compiler.ol)

### N1: Generation — `stdlib/generate.ol` (NEW)
- Retrieve → Recombine → Template NLG → Honesty gate
- Spec: `spec/SPEC_BP14_GENERATION.md`
- Depends: knowtree.ol (read only), silk.ol (read only), feedback.ol (read only)
- Test: `test/test_generate.ol` (NEW)

### N2: Communication — `stdlib/comm.ol` (NEW)
- HTTP server, A2A Agent Card, JSON response
- Spec: `spec/SPEC_BP15_COMMUNICATION.md`
- Depends: __tcp_listen/accept/send/recv (already in VM)
- Test: `test/test_comm.ol` (NEW)

### N3: Brain pipeline integration — `stdlib/brain_v3.ol` (NEW, don't edit brain.ol)
- Wire persist + feedback + generate into 6-layer pipeline
- Load knowledge on start: `persist_load_all()`
- Save on shutdown: `persist_save_all()`
- UCB1 selection in Hypothesize layer
- Reward update in new Evaluate layer
- Spec: SPEC_D updated by SS23 (15 mechanisms, 6 CPs, PTAVF)
- Test: `test/test_brain_v3.ol` (NEW)

### N4: Boot integration — `Origin.olang` rebuild
- Compile full stack: knowtree + silk + persist + feedback + generate + brain_v3
- Boot flow: load persist → brain loop → save on exit
- Test: manual — run and query

**Files Nox OWNS (create/edit):**
```
stdlib/generate.ol      (NEW)
stdlib/comm.ol          (NEW)
stdlib/brain_v3.ol      (NEW)
test/test_generate.ol   (NEW)
test/test_comm.ol       (NEW)
test/test_brain_v3.ol   (NEW)
```

**Files Nox reads but DOES NOT edit:**
```
stdlib/knowtree.ol
stdlib/silk.ol
stdlib/persist.ol
stdlib/feedback.ol
stdlib/brain.ol
stdlib/encode.ol / encode_v2.ol
vm/x86_64/vm_nox.S
tools/compile_nox.py
```

---

## SS23 — VM + compiler (KHÔNG đụng stdlib/ trừ compiler.ol)

### S1: String builtins — `vm/x86_64/vm_nox.S`
- Add 5 builtins: __str_replace, __str_join, __str_starts_with, __str_ends_with, __str_to_num
- Add to builtin_hash_table (79/512 slots used, plenty of room)
- Pattern: read args from r14, u16 molecules, allocate on r15 (Zone C)
- Test: `test/test_string_v2.ol` (NEW)

### S2: Struct syntax — `tools/compile_nox.py` + `stdlib/compiler.ol`
- `{key: val}` → dict literal
- `expr.field` → `__dict_get(expr, "field")`
- Need dict builtins in VM: __dict_new, __dict_get, __dict_set
- Spec: `spec/PLAN_OLANG_UPGRADE.md` Phase 2
- Test: `test/test_struct.ol` (NEW)

### S3: Module import — `tools/compile_nox.py` + `stdlib/compiler.ol`
- `import "file.ol"` → compile-time inclusion with dedup
- Spec: `spec/PLAN_OLANG_UPGRADE.md` Phase 3
- Test: `test/test_import.ol` + `test/test_import_lib.ol` (NEW)

### S4: For/Match sugar — `tools/compile_nox.py` + `stdlib/compiler.ol`
- `for x in arr { ... }` → while loop desugar
- `match x { 1 => ...; _ => ...; }` → if/else chain
- Compiler-only change, no VM change
- Test: `test/test_for_match.ol` (NEW)

### S5: Self-build verify
- After S1-S4: `make self-build` → verify Gen2==Gen3
- Must pass before merge

### S6: VM readline builtin — `vm/x86_64/vm_nox.S`
- Add `__readline()` → reads from fd 0 (stdin) byte-by-byte until \n
- Returns string without trailing \n
- Needed for nox_brain.olang interactive mode

### S7: TCP server debug — `vm/x86_64/vm_nox.S`
- `__tcp_send` / `__tcp_recv` may have issues with HTTP request/response
- comm.ol HTTP server connects but curl gets empty response
- Debug: verify tcp_send actually writes, check if accept blocks properly

**Files SS23 OWNS (create/edit):**
```
vm/x86_64/vm_nox.S         (string builtins, dict builtins)
tools/compile_nox.py        (struct, module, for/match)
stdlib/compiler.ol          (self-hosting updates)
test/test_string_v2.ol      (NEW)
test/test_struct.ol         (NEW)
test/test_import.ol         (NEW)
test/test_import_lib.ol     (NEW)
test/test_for_match.ol      (NEW)
```

**Files SS23 reads but DOES NOT edit:**
```
stdlib/knowtree.ol
stdlib/silk.ol
stdlib/persist.ol
stdlib/feedback.ol
stdlib/brain.ol
```

---

## Thứ tự

```
Phase A (song song):
  Nox: N1 (generate.ol)     | SS23: S1 (string builtins)
  
Phase B (song song):
  Nox: N2 (comm.ol)         | SS23: S2 (struct syntax)

Phase C (song song):
  Nox: N3 (brain_v3.ol)     | SS23: S3 (module import)

Phase D:
  SS23: S4 (for/match) + S5 (self-build verify)
  Nox: N4 (boot integration — after S1 done, can use new string builtins)
```

## Conflict check
- Nox: stdlib/*.ol (NEW files) + test/*.ol (NEW)
- SS23: vm_nox.S + compile_nox.py + compiler.ol + test/*.ol (NEW, different names)
- **ZERO overlap.**
