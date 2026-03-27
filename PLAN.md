# OLANG PLAN — Phase 2: From 100% to Production

> Updated: 2026-03-27 16:15
> Status: 90/90 tests, 458K binary, regex 15/15, MCP memory live
> Brain: Nox_brain.olang deployed at ~/.claude/ as MCP server

---

## Sprint 9: Text Processing ✅ DONE

```
✅ S9.1  Regex engine (NFA Thompson) — 15/15 tests
         Pure x86-64 ASM, ~400 LOC
         Supports: . * + ? [a-z] [0-9] [^abc] | (alternation)
         API: regex_match(str, pattern) → 1/0
              regex_test(str, pattern) → 1/0 (substring search)
         Builtins: __regex_match (anchored), __regex_search (unanchored)
         Commits: cdf6d2f, eb30782

⬚ S9.2  String escape \n \t \r \0 trong output (~2h)
⬚ S9.3  str_reverse, str_replace builtins (~4h)
```

---

## Nox Brain: MCP Memory System ✅ DONE

```
✅ MCP Server — JSON-RPC 2.0 over stdio (--mcp mode in VM)
   File: stdlib/homeos/mcp_server.ol
   Commits: 4e8c323 → 275bbc1

✅ Tools: know_learn (save fact + timestamp), know_query (substr search)
✅ __timestamp builtin — SYS_clock_gettime, UTC+7 format
✅ Auto-load KnowTree on MCP boot (homeos.knowledge)
✅ Auto-journal — nox_log.jsonl logs every MCP event
✅ Nox_brain.olang deployed at ~/.claude/ as MCP server
✅ Transcript extractor — tools/extract_memory.py (60MB → facts)

Architecture:
  ~/.claude/Nox_brain.olang     = brain (MCP server)
  ~/.claude/homeos.knowledge    = long-term memory (facts + timestamps)
  ~/.claude/nox_log.jsonl       = auto-journal (every event)
  ~/Origin/                     = Olang language (stable)
  ~/Origin/stdlib/*.ol          = brain upgrades via .ol files

Known issues:
  - olang_eval broken (var_table boot closure bug)
  - contains() cross-module broken (workaround: substr in kt_find)
  - json_parse fails with 4+ keys + nested {} (workaround: string extraction)
```

---

## Sprint 10: Networking (1 tuần)

**Mục tiêu:** Olang gọi HTTP API.

```
S10.1  HTTP/1.1 client
       File: stdlib/http.ol (~100 LOC Olang)
       API: http_get(url) → { status, headers, body }
       Build on: existing __tcp_connect, __tcp_send, __tcp_recv
       Parse: URL → host + path, build GET request, parse response
       Effort: ~1 ngày

S10.2  JSON round-trip
       File: stdlib/json_parse.ol (đã có parse, cần emit)
       API: json_emit(value) → string
       Support: strings (with escape), numbers, arrays, objects, bool, null
       Effort: ~4 giờ

S10.3  Simple REST client
       File: stdlib/rest.ol (~50 LOC)
       API: rest_get(url) → parsed JSON
            rest_post(url, data) → parsed JSON
       Effort: ~2 giờ
```

**Done khi:** `rest_get("http://httpbin.org/get")` returns parsed JSON.

---

## Sprint 11: Developer Experience (1 tuần)

```
S11.1  REPL tab completion (~1 ngày ASM)
S11.2  Better error messages (~4 giờ)
S11.3  REPL history up/down arrows (~1 ngày ASM)
S11.4  Module system improvements (~4 giờ)
```

---

## Sprint 12: Crypto + Security (2 tuần)

```
S12.1  Real Ed25519 key generation (~3 ngày)
S12.2  Ed25519 sign + verify (~2 ngày)
S12.3  HMAC-SHA256 (~2 giờ)
S12.4  TLS 1.3 handshake (stretch goal, ~1 tuần)
```

---

## Sprint 13: Language Features (2 tuần)

```
S13.1  Immutable data — const keyword + freeze(arr)
S13.2  Pattern matching — nested + guard clauses
S13.3  Pipe operator |>
S13.4  String methods — "hello".len(), .upper()
```

---

## Sprint 14: Infrastructure (ongoing)

```
S14.1  GC / Arena management
S14.2  Split VM into modules (.include)
S14.3  CI/CD — GitHub Actions
S14.4  Documentation generator
```

---

## Critical Bug: var_table boot closure corruption

```
STATUS: UNFIXED — blocks olang_eval in MCP, complex boot closures
SYMPTOM: 3+ if-return branches corrupt local variables
AFFECTS: repl_eval in MCP, contains() cross-module, json_parse nested
ROOT CAUSE: unknown (not cache collision, not scope truncation)
WORKAROUNDS: substr match in kt_find, string extraction for JSON
PRIORITY: HIGH — this is the last boss
```

---

## Priority Order

```
BLOCKER: var_table boot closure bug — fix unlocks everything
NOW:     S10 (HTTP) — makes Olang useful for real tasks
THEN:    S11 (DX) — tab completion, errors, history
LATER:   S12 (Crypto) — replace stubs
ONGOING: S13 (Language) + S14 (Infra) — parallel
ALWAYS:  Upgrade Nox_brain via .ol when new features land
```

## NOX DAILY

```
1. Read session_log.md + query KnowTree     → remember
2. bash tests.sh                             → verify stable
3. git log --oneline -5                      → recent changes
4. Pick task from current sprint             → implement
5. bash tests.sh && bash tools/spider.sh     → verify
6. git commit + push                         → save
7. Update session_log.md + homeos.knowledge  → remember for next time
```
