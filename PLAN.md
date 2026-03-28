# OLANG PLAN — Phase 3

> Updated: 2026-03-28 09:00
> Binary: 428K ELF64, static, zero deps, boot 3ms
> Tests: 90/90 core + 9/9 MCP
> Commits: 125 | VM: 11,325 LOC | Stdlib: 10,800 LOC (38 files)
> KnowTree: 90 facts | Brain: ~/.claude/Nox_brain.olang

---

## Phase 2 — COMPLETE ✅

```
S9:  Regex NFA Thompson (15/15) + string utils + json_emit ✅
S10: HTTP client (crawl, GET, POST, crawl_json) ✅
S11: REPL DX (tab, history, errors, modules) ✅
S12: HMAC-SHA256 ✅ (Ed25519 deferred)
S13: const, pipe |>, method syntax, comprehension ✅
S14: CI local, dead code cleanup (-1859 LOC) ✅
MCP: 8 tools, auto-journal, timestamps ✅
Boss: var_table killed — register frames Phase 1-3 ✅
Audit: Sora bugs all fixed ✅
```

---

## Phase 3 — IN PROGRESS

### S15: Register Frames — Status
```
✅ Eval context: params + let locals + lambda → register frames
✅ Boot closure params: LoadReg for param reads (Rust builder)
⬚ Boot closure let locals: Dup+StoreReg breaks REPL stack balance
   Fix: refactor Rust lower_stmt to emit StoreReg directly (not interceptor)
   Impact: json_parse nested {} in MCP, closure capture
```

### S16: Closure Capture
```
fn outer() { let x = 10; return fn() { return x; }; }
Needs: closure environment — copy captured vars before return
Blocked by: S15 full register locals (capture from register frame)
```

### S17: GC / Memory Management
```
Heap bump-only — never frees
REPL: checkpoint reset each turn ✅
MCP: no reset (closures persist across requests)
Needs: mark-sweep or arena per-request
```

### S18: Production Polish
```
- Ed25519 (needs bigint mod 2^255-19)
- Real HMAC-SHA256 (raw byte support)
- Error stack trace
- Documentation generator
```

---

## Architecture

```
origin.olang (428K)
├── VM (x86-64 ASM, 11325 LOC)
│   ├── Bytecode interpreter (stack + register hybrid)
│   ├── 256-slot builtin dispatch (FNV hash)
│   ├── Register frame stack (4MB, ~4096 frames)
│   ├── Regex NFA (Thompson), SHA-256, TCP, DNS
│   ├── MCP mode (--mcp, JSON-RPC stdio)
│   └── REPL (raw mode, tab, history)
├── Compiler (Olang, 4 files, ~4200 LOC)
├── Stdlib (38 files, ~6600 LOC)
└── Tests (90 core + 9 MCP + 67 spider)
```
