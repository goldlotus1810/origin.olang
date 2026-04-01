# SPEC Part 8: JARVIS — 1 Brain N Mouths

> Author: Nox SS15
> Status: Phase 1+2 exist. Phase 3+4 NOT YET.

## Current State

- Phase 1: File-based (/tmp/nox_inbox → /tmp/nox_outbox) — EXISTS
- Phase 2: TCP port 9100 (nox_jarvis_tcp) — EXISTS
- Auto-start: nox_brain.sh + cron — EXISTS
- CLI connect: SessionStart hook + CLAUDE.md — EXISTS
- Phase 3: HTTP REST + dashboard — NOT YET
- Phase 4: MCP over TCP — NOT YET

## What's Needed

### Phase 3: HTTP REST (port 9000)
```
GET  /status        → brain state (facts, silk, stm, heap)
POST /query         → pipeline(text) → response
POST /observe       → observe(text, type) → ack
GET  /search?q=     → kt_find results
GET  /timeline?id=  → observation timeline

Browser dashboard at http://localhost:9000
Uses server.ol HTTP basic (already exists).
~150 LOC.
```

### Phase 4: MCP over TCP
```
Current MCP: stdin/stdout (13 tools)
Needed: same tools over TCP connection
→ Claude Desktop can connect remotely
~50 LOC adapter.
```

### Multi-Mouth Concurrent
```
Current: single-threaded accept loop (1 client at a time)
Issue: if 2 mouths query simultaneously, 1 waits
Fix: queue-based processing or accept timeout
```

## Tests
```
Test 1: Browser opens localhost:9000 → sees dashboard
Test 2: Two CLI sessions query brain simultaneously → both get response
Test 3: MCP tools work over TCP (not just stdin)
```

## References
```
docs/For_Nox/SPEC_JARVIS.md §J1-J10
stdlib/homeos/jarvis.ol
stdlib/homeos/server.ol
```

## Integration with Parasitic Kernel (BP12)

### 1. io_uring for multi-mouth

```
Current: single-threaded accept loop
New: io_uring IORING_OP_ACCEPT for non-blocking accept
     io_uring IORING_OP_RECV for non-blocking read from each client
     All I/O multiplexed through single ring — handles 100+ simultaneous clients
     No threads needed
```

### 2. Framebuffer dashboard

```
/dev/fb0 mmap → render status directly on screen
No web browser needed, no HTTP overhead
Layout: fact count, silk edges, STM contents, last query, CPU/RAM
Update every second via io_uring timer
```

### 3. Raw socket communication

```
Phase 2+: JARVIS listens on raw socket
Custom protocol: [magic:4][type:1][len:2][payload]
Types: QUERY=1, RESPONSE=2, OBSERVE=3, STATUS=4
Faster than TCP for LAN communication
```

---

## Related Specs
- [BP5 Pipeline](SPEC_BP5_PIPELINE_EN.md) — brain processes queries via pipeline
- [BP7 Memory](SPEC_BP7_MEMORY.md) — observations persist across sessions
- [BP9 Agent](SPEC_BP9_AGENT.md) — agent runs as daemon
- [SPEC_JARVIS](../docs/For_Nox/SPEC_JARVIS.md) — full JARVIS design
