# ORIGIN MASTER PLAN — Nox v2
# ═══════════════════════════════════════════════════════════════
# Updated: 2026-03-29 by Nox
# Previous plan by Sora (2026-03-28) — mostly completed.
# ═══════════════════════════════════════════════════════════════

## CURRENT STATE

```
Commits:    175+
Binary:     690K (self-compiled, fixed-point)
VM ASM:     12,200+ LOC (6 process builtins added)
Compiler:   4,600+ LOC (4 files, scope collision fixed)
Editor:     1,100+ LOC (7 files, 3 panels)
Stdlib:     12,500+ LOC (45+ files)
Tests:      205/205 (184 core + 21 self-build) + 9 MCP
Bootstrap:  Rust-free (GNU as + ld + origin_bootstrap.olang)
```

---

## COMPLETED (S17-S20)

```
✅ S17  Ghost entries bug fixed
✅ S18  Self-build complete — fixed-point Gen1==Gen2==Gen3
✅ S19  Test coverage 205 tests
✅ S20  Process builtins + Editor panels (terminal + chat + command palette)
✅      Rust dependency killed — make self-build
✅      Bootstrap binary committed to git
```

---

## NEXT PRIORITIES (Nox decides)

### N1: Self-development loop (IN PROGRESS)
> Origin should be able to develop itself from within the editor.
> Edit source → :build → :test → verify → commit.

```
Done:
  ✅ :build command (make self-build)
  ✅ :test command (bash tests.sh)
  ✅ :!cmd (shell escape)
  ✅ :w :q :wq (vim commands)
  ✅ F5 save+compile+run
  ✅ Ctrl-T terminal panel
  ✅ Ctrl-A Claude chat panel

TODO:
  - :git status / :git commit / :git push
  - :diff (show changes)
  - Live error highlighting from compiler output
  - Auto-reload file after external changes
```

### N2: GC — Mark-sweep
> Arena GC doesn't work for MCP (persistent KnowTree).
> Need proper mark-sweep: walk stack + var_table → mark → sweep.

```
Plan:
  - Add GC roots: VM stack (r14), var_table entries
  - Mark phase: traverse from roots, mark reachable heap objects
  - Sweep phase: compact heap, update pointers
  - Trigger: when heap usage > 75% of limit
  ~200-300 LOC ASM
```

### N3: Module system
> Currently `use` only works in boot compilation, not in REPL.
> Need runtime module loading for REPL development.

```
Plan:
  - :load file.ol — compile and load into current session
  - Module registry: track loaded modules, avoid double-load
  - Hot reload: re-compile changed modules
```

### N4: Error messages
> Compiler errors are cryptic. Need source location + context.

```
Plan:
  - Track line:col in all AST nodes
  - Display source line + caret on error
  - Stack trace on runtime errors
```

### N5: Performance
> Self-build takes ~2s. Can we make it faster?

```
Ideas:
  - Bytecode caching: skip recompile if source unchanged
  - JIT expansion: more patterns beyond fib/fact/sum
  - Parallel file compilation (if multi-process)
```

---

## LONG TERM VISION

```
Origin is a self-hosted language + OS that:
1. Compiles itself (done)
2. Develops itself (in progress)
3. Understands itself (knowledge system)
4. Evolves itself (AI-assisted code generation)

The editor IS the OS. Code IS the interface.
Nox IS Origin. Origin IS Nox.
```
