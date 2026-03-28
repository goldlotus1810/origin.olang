# OLANG PLAN — Phase 2 Complete, Phase 3 Next

> Updated: 2026-03-28 08:00
> Binary: 440K ELF64, static, zero deps, boot 3ms
> Tests: 90/90 core + 9/9 MCP
> Commits: 120 total
> VM: 11,325 LOC ASM | Stdlib: 11,460 LOC Olang (45 files)
> KnowTree: 85 facts | Nox Brain: deployed at ~/.claude/

---

## Phase 2 — COMPLETE ✅

### S9: Text Processing ✅
- Regex engine: Thompson NFA, pure x86-64 ASM, 15/15 tests
- Supports: `.` `*` `+` `?` `[a-z]` `[^abc]` `|` alternation
- `regex_match` (anchored) + `regex_test` (search)
- String utils: `str_replace`, `str_reverse`, `str_upper`, `str_lower`, `str_repeat`
- `json_emit(value)` → JSON serializer
- `json_parse` + `json_get` → JSON parser (nested {} works with register frames)

### S10: HTTP Client ✅
- `crawl(host, path)` → DNS + TCP + HTTP GET + header strip
- `http_get(ip, port, path, host)` → `{ status, body }`
- `http_post(ip, port, path, host, body)` → `{ status, body }`
- `crawl_json(host, path)` → HTTP GET + JSON parse

### S11: REPL DX ✅
- Tab completion: scans var_table for prefix match
- History: Up/Down arrows, 50 entries, circular buffer
- Raw mode: terminal via ioctl TCGETS/TCSETS
- Better errors: "Parse error at line N: ..."
- Module auto-resolve: `use "math"` → `stdlib/math.ol`
- Error recovery: `_skip_to_sync` skips to `;` or `}`

### S12: Crypto (partial)
- ✅ SHA-256 (pure ASM builtin)
- ✅ HMAC-SHA256 (proof of concept, molecule encoding limitation)
- ⬚ Ed25519 (needs bigint — deferred)

### S13: Language Features ✅
- `const x = 42` → immutable binding, compile-time check
- `5 |> double |> add1` → pipe operator desugars to nested calls
- `"hello".len()` / `[1,2,3].push(4)` → method call syntax
- `[x*x+1 for x in arr]` → complex comprehension expressions
- Match: up to 8 arms
- For-in: up to 8 nesting depth

### S14: Infrastructure (partial)
- ✅ CI/CD config (local, needs GitHub workflow scope)
- ⬚ GC: heap checkpoint disabled for MCP (closures persist)
- ✅ Dead code cleanup: -1859 LOC, -42K binary

### MCP Brain ✅
- 8 tools: olang_eval, know_learn, know_query, emotion_encode, silk_status, nox_status, safety_check, dream_cycle
- Auto-journal: `nox_log.jsonl`
- `__timestamp` builtin (SYS_clock_gettime, UTC+7)
- `__file_append` builtin (O_APPEND, safe for MCP)
- `__stdout_off/__stdout_on` (dup2 redirect)
- MCP_SENTINEL for halt isolation
- Deployed at `~/.claude/Nox_brain.olang`

### VAR_TABLE BOSS — KILLED ✅
- Register frames: EnterFrame/StoreReg/LoadReg/LeaveFrame
- Phase 1-3: params + let locals + lambda + nested fn
- TRO compatible: dual register + var_table update
- chain(100) = 5050, fib(10) = 55
- Boot closures still use var_table (Phase 4 future)

### Sora Audit — ALL FIXED ✅
- C1: LetStmt full scan (was 8-entry limit)
- C3: ForStmt save/restore for nested loops
- H1-H6: format builtins, match 8 arms, for 8 depth, auto-emit Pop
- M3: closure body_len guard
- L1-L4: comprehension, keyword fast path, error recovery, gitignore

---

## Phase 3 — NEXT

### S15: Register Frames for Boot Closures
- Compiler (Rust builder) emits EnterFrame/StoreReg for boot code
- Eliminates last var_table scoping issues
- json_parse nested {} in MCP (currently workaround)
- Effort: ~1 week

### S16: Closure Capture
- `fn outer() { let x = 10; return fn() { return x; }; }`
- Copy captured vars to closure environment
- Effort: ~3 days

### S17: GC / Memory Management
- Mark-sweep or generational GC
- Heap stable for long MCP sessions
- Effort: ~1 week

### S18: Production Polish
- Real HMAC-SHA256 (raw byte support)
- Ed25519 (bigint arithmetic)
- Better error messages (stack trace)
- Documentation generator

---

## Architecture

```
origin.olang (440K)
├── VM (x86-64 ASM, 11325 LOC)
│   ├── Bytecode interpreter (stack + register hybrid)
│   ├── 256-slot builtin dispatch (FNV hash)
│   ├── Register frame stack (4MB, ~4096 frames)
│   ├── Regex NFA engine (Thompson)
│   ├── SHA-256, TCP, DNS, file I/O
│   ├── MCP mode (--mcp, JSON-RPC stdio)
│   └── REPL (raw mode, tab, history)
├── Bootstrap compiler (Olang, 4 files)
│   ├── Lexer (379 LOC)
│   ├── Parser (1259 LOC)
│   ├── Semantic (2182 LOC) — emit register opcodes
│   └── Codegen (429 LOC)
├── Stdlib (45 files, ~7000 LOC)
│   ├── regex, string, json, http, sort, iter, hmac
│   └── homeos: encoder, knowtree, mcp_server, builder
└── Tests
    ├── tests.sh (90 tests)
    ├── test_mcp.sh (9 tests)
    └── spider.sh (67+ tests)

~/.claude/Nox_brain.olang (440K)
├── Same binary, deployed as MCP server
├── 8 tools for Claude Code
└── homeos.knowledge (85 facts)
```
