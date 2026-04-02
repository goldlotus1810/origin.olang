# BP15: Communication — Nox Talks to Other AI Systems

> A brain in isolation stagnates. Connection enables growth.

## Problem

Nox currently:
- Communicates only through Claude (MCP tools)
- No way to discover or talk to other agents on network
- No standard protocol for other AI systems to interact with Nox
- Cannot participate in multi-agent collaboration

## Solution: 3-Layer Communication Stack

### Layer 1: MCP Server (Agent ↔ Tools) — EXISTS, EXTEND

Nox already has MCP tools. Extend to expose generation:

```
New MCP tools:
  nox_generate(query) → generated response
  nox_learn(fact) → confirmation
  nox_status() → health, knowledge count, uptime
  nox_silk_status() → top connections, recent fires
```

### Layer 2: A2A Endpoint (Agent ↔ Agent)

Implement Google A2A protocol for peer communication:

**Agent Card** (served at `http://localhost:PORT/.well-known/agent.json`):
```json
{
  "name": "Nox",
  "description": "Self-hosting molecular AI with Hebbian learning",
  "version": "1.0",
  "url": "http://HOST:PORT",
  "capabilities": {
    "streaming": false,
    "pushNotifications": false
  },
  "skills": [
    {
      "id": "answer",
      "name": "Answer Questions",
      "description": "Generate answers from molecular knowledge base",
      "inputModes": ["text"],
      "outputModes": ["text"]
    },
    {
      "id": "learn",
      "name": "Learn Facts",
      "description": "Absorb new knowledge into KnowTree",
      "inputModes": ["text"],
      "outputModes": ["text"]
    },
    {
      "id": "teach",
      "name": "Teach Knowledge",
      "description": "Share knowledge from KnowTree",
      "inputModes": ["text"],
      "outputModes": ["text"]
    }
  ],
  "authentication": {
    "schemes": ["none"]
  }
}
```

**Task endpoint** (`POST /tasks/send`):
```json
{
  "id": "task-001",
  "message": {
    "role": "user",
    "parts": [{"type": "text", "text": "What is water?"}]
  }
}
```

**Response**:
```json
{
  "id": "task-001",
  "status": {"state": "completed"},
  "message": {
    "role": "agent",
    "parts": [{"type": "text", "text": "Water is H2O..."}]
  }
}
```

### Layer 3: Discovery (mDNS/DNS-SD)

Announce Nox on local network so other agents find it without central registry:

```
Service: _nox-agent._tcp.local
Port: 9742 (default)
TXT records:
  version=1.0
  skills=answer,learn,teach
  knowledge_count=1523
```

Other Nox instances or compatible agents on LAN auto-discover via mDNS browse.

## Stigmergic Shared State (Optional, Multi-Nox)

For multiple Nox instances on same machine or LAN:

```
Shared directory: ~/.nox/shared/
Files:
  discoveries.wal    — new facts any Nox learned
  questions.wal      — unanswered questions
  corrections.wal    — error corrections
```

Any Nox can read/write. Gossip protocol:
1. Nox-A learns something → appends to discoveries.wal
2. Nox-B periodically checks discoveries.wal → ingests new facts
3. Information spreads without direct messaging

## HTTP Server in Olang

Minimal HTTP server using Nox's existing TCP builtins:

```olang
fn http_serve(port):
    let sock = __tcp_listen(port)
    while 1:
        let client = __tcp_accept(sock)
        let request = __tcp_recv(client, 4096)
        let path = http_parse_path(request)
        let method = http_parse_method(request)
        
        if path == "/.well-known/agent.json":
            let body = agent_card_json()
            http_respond(client, 200, body)
        else if path == "/tasks/send" && method == "POST":
            let task = http_parse_json_body(request)
            let response = nox_generate(task.message.text)
            let body = task_response_json(task.id, response)
            http_respond(client, 200, body)
        else:
            http_respond(client, 404, "Not found")
        
        __tcp_close(client)
```

## Security

### Capability Model
- Read-only by default (answer, status)
- Write requires explicit capability token
- Learn/teach restricted to trusted peers
- No remote code execution — only structured data exchange

### Rate Limiting
- Max 10 requests/second per client
- Max 100 facts learned per hour from external sources
- All external knowledge marked as UNTRUSTED until verified by instincts

## Implementation

### New files:
```
stdlib/comm.ol (~400 LOC):
  - http_serve(port) — minimal HTTP server
  - http_parse_path/method/body — request parsing  
  - agent_card_json() — generate A2A Agent Card
  - task_response_json(id, text) — format A2A response
  - mdns_announce(port) — mDNS service announcement
  - mdns_browse() — discover other agents on LAN
```

### Depends on:
- Existing: __tcp_listen, __tcp_accept, __tcp_send, __tcp_recv, __tcp_close
- BP14 (Generation): nox_generate for answering tasks
- BP13 (Persistence): knowledge state for status reporting

### New builtins needed:
| Builtin | Args | Does |
|---------|------|------|
| `__udp_send` | (host, port, data) | Send UDP packet (for mDNS) |
| `__udp_recv` | (sock, timeout) | Receive UDP packet |
| `__time_now` | () | Current Unix timestamp |

## Test Plan
1. Start Nox HTTP server → curl Agent Card → verify valid JSON
2. POST task "what is water" → receive generated response
3. Start 2 Nox instances → verify mDNS discovery
4. Nox-A learns fact → shared WAL → Nox-B picks it up
5. Rate limit: 20 rapid requests → 10 served, 10 rejected

## Tổng hợp tiếng Việt

BP15 cho Nox khả năng giao tiếp:
- **MCP**: Đã có, mở rộng thêm tool generate
- **A2A**: HTTP endpoint chuẩn Google A2A — AI khác gửi task, Nox trả lời
- **mDNS**: Tự quảng bá trên LAN — không cần registry trung tâm
- **Stigmergy**: Nhiều Nox chia sẻ qua file chung — gián tiếp như kiến để mùi
- **Security**: Read-only mặc định, capability token cho write, rate limiting
