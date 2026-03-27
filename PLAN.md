# OLANG PLAN — Phase 2: From 100% to Production

> Session 2026-03-27: P0-P7 done. 100% eval. 0 bugs. 0 SEGFAULTs.
> Now: build features that make Olang USEFUL for real programs.

---

## Sprint 9: Text Processing (1 tuần)

**Mục tiêu:** Olang xử lý text mạnh như Python.

```
S9.1  Regex engine (NFA Thompson)
      File: stdlib/regex.ol (~300 LOC)
      Support: . * + ? [] () | ^ $
      API: regex_match(str, pattern) → 1/0
           regex_find(str, pattern) → [start, end]
           regex_replace(str, pattern, replacement) → str
      Test: regex_match("hello123", "[a-z]+[0-9]+") → 1
      Effort: ~2 ngày

S9.2  String escape \n \t \r \0 trong output
      File: vm_x86_64.S (op_emit)
      Hiện tại emit "a\nb" in literal \n. Cần decode escape.
      Effort: ~2 giờ

S9.3  String repeat, reverse, replace builtins
      File: stdlib/string.ol (wrappers) + semantic.ol (inline)
      str_reverse("abc") → "cba"
      str_replace("hello world", "world", "olang") → "hello olang"
      Effort: ~4 giờ
```

**Done khi:** regex_match works, text processing pipeline complete.

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

**Mục tiêu:** Olang dễ dùng hơn.

```
S11.1  REPL tab completion
       File: vm_x86_64.S (REPL loop)
       On Tab: scan var_table for prefix match, show completions
       Effort: ~1 ngày ASM

S11.2  Better error messages
       File: stdlib/bootstrap/parser.ol + semantic.ol
       Show: line number, column, context snippet
       "Error at line 5: expected ';' after expression"
       Effort: ~4 giờ

S11.3  REPL history (up/down arrows)
       File: vm_x86_64.S (REPL loop)
       Save last 50 inputs, navigate with arrow keys
       Effort: ~1 ngày ASM

S11.4  Module system improvements
       File: stdlib/repl.ol + semantic.ol
       use "math" → auto-resolve to stdlib/math.ol
       use "http" → auto-resolve to stdlib/http.ol
       Effort: ~4 giờ
```

**Done khi:** Tab completion + error messages + history working.

---

## Sprint 12: Crypto + Security (2 tuần)

**Mục tiêu:** Real crypto, replace stubs.

```
S12.1  Real Ed25519 key generation
       File: stdlib/crypto/ed25519.ol (~200 LOC)
       Need: modular arithmetic mod 2^255-19
       Use: bigint as array of limbs, schoolbook multiply
       Effort: ~3 ngày

S12.2  Ed25519 sign + verify
       File: stdlib/crypto/ed25519.ol
       RFC 8032 compliant
       Effort: ~2 ngày

S12.3  HMAC-SHA256
       File: stdlib/crypto/hmac.ol (~30 LOC)
       Standard HMAC using __sha256
       Effort: ~2 giờ

S12.4  TLS 1.3 handshake (stretch goal)
       File: stdlib/crypto/tls.ol (~300 LOC)
       ClientHello → ServerHello → encrypted
       Effort: ~1 tuần
```

**Done khi:** Ed25519 sign+verify passes test vectors.

---

## Sprint 13: Language Features (2 tuần)

**Mục tiêu:** Olang mạnh hơn như ngôn ngữ.

```
S13.1  Immutable data (P5)
       Keyword: `const x = 42` → cannot reassign
       Frozen arrays: `freeze(arr)` → push/set_at throws
       Effort: ~3 ngày (compiler + VM)

S13.2  Pattern matching improvements
       Nested patterns: match x { Some(42) => ... }
       Guard clauses: match x { n if n > 0 => ... }
       Effort: ~2 ngày

S13.3  Pipe operator |>
       Syntax: x |> f |> g  →  g(f(x))
       Compiler desugars at parse time
       Effort: ~4 giờ

S13.4  String methods
       "hello".len() → 5
       "hello".upper() → "HELLO"
       [1,2,3].map(fn(x){x*2}) → [2,4,6]
       Effort: ~1 ngày
```

**Done khi:** const + pipe + string methods working.

---

## Sprint 14: Infrastructure (ongoing)

```
S14.1  GC / Arena management
       Simple mark-sweep or generational
       Track live references from var_table + VM stack
       Free unreachable heap blocks
       Effort: ~1 tuần

S14.2  Split VM into modules
       vm_x86_64.S → .include "modules/core.S", "modules/builtins.S", etc.
       Zero behavior change, pure organization
       Effort: ~4 giờ

S14.3  CI/CD
       GitHub Actions: build + test + spider on every push
       Effort: ~2 giờ

S14.4  Documentation generator
       Parse /// comments → generate docs
       Effort: ~1 ngày
```

---

## Priority Order

```
NOW:     S9 (Regex) — unlocks text processing, high impact
NEXT:    S10 (HTTP) — makes Olang useful for real tasks
THEN:    S11 (DX) — tab completion, errors, history
LATER:   S12 (Crypto) — replace stubs
ONGOING: S13 (Language) + S14 (Infra) — parallel
```

## Success Metrics

```
Sprint 9:  regex_match works, spider 70+ tests
Sprint 10: http_get returns data, JSON round-trip
Sprint 11: REPL feels like Python/Node REPL
Sprint 12: Ed25519 passes RFC 8032 test vectors
Sprint 13: const + pipe working
Sprint 14: CI green, heap stable for long sessions
```

## NOX DAILY

```
1. bash tools/spider-daemon.sh status    → check overnight bugs
2. cat logs/spider-bugs.log              → any new findings?
3. git log --oneline -5                  → recent changes
4. Pick task from current sprint         → implement
5. bash tests.sh && bash tools/spider.sh → verify
6. git commit + push                     → save
7. Repeat
```
