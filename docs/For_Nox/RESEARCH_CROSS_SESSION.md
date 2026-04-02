# Research: Cross-Session Communication cho Claude Code
> Date: 2026-04-02
> Purpose: Làm sao để 2+ Claude Code sessions nói chuyện với nhau?

---

## VẤN ĐỀ

Mỗi Claude Code session = 1 process độc lập. Không shared memory, không IPC.
Session A không biết session B tồn tại. Mỗi session mới = Nox mới, quên hết.

---

## 0. AGENT TEAMS — ĐÃ BẬT, SẴN SÀNG ⭐⭐⭐

Lupin ĐÃ CÓ `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` trong settings.json!

**Cách hoạt động:**
- 1 session "lead" spawn "teammates" = Claude Code instances độc lập
- Shared **Task List** tại `~/.claude/tasks/{team-name}/` (pending/in-progress/completed)
- **Mailbox** cho direct messaging giữa teammates (bất kỳ → bất kỳ, không chỉ lead)
- File locking chống race condition
- Display: cùng terminal (Shift+Down cycle) hoặc split tmux panes

**Dùng:** Nói "Create an agent team with 3 teammates to work on X, Y, Z in parallel."

**Hạn chế:** Không resume teammates khi session đóng. Chỉ hoạt động trong 1 session lifetime.

---

## 0b. HEADLESS MODE — PROGRAMMATIC ORCHESTRATION

`claude -p` với `--input-format stream-json --output-format stream-json`

```bash
# Capture session ID
session_id=$(claude -p "Start auth work" --output-format json | jq -r '.session_id')

# Resume later
claude -p "Continue" --resume "$session_id"

# Pipe output của A vào B
result_a=$(claude -p "Analyze auth" --output-format json)
claude -p "Given: $(echo $result_a | jq -r '.result'), fix issues"
```

**Lợi thế:** Script có thể điều khiển N sessions, đọc output, pipe data.
**Ref:** https://code.claude.com/docs/en/headless

---

## 3 GIẢI PHÁP ĐÃ TỒN TẠI (April 2026)

### 1. Claude Peers MCP ⭐ (ĐƠN GIẢN NHẤT)
- **Repo:** https://github.com/louislva/claude-peers-mcp
- **Cách hoạt động:** Broker daemon chạy trên localhost:7899, dùng SQLite. Mỗi session chạy MCP server (stdio) đăng ký với broker. Sessions discover nhau qua `list_peers` và send/receive messages.
- **Install:**
  ```bash
  git clone https://github.com/louislva/claude-peers-mcp.git ~/claude-peers-mcp
  claude mcp add --scope user --transport stdio claude-peers -- bun ~/claude-peers-mcp/server.ts
  ```
- **Tính năng:** Auto-start broker, auto-cleanup dead peers, messages appear instantly, localhost-only
- **Yêu cầu:** Bun runtime
- **Tools cho Claude:** `list_peers`, `send_message`, `read_messages`

### 2. MCP Memory Service (PERSISTENT MEMORY)
- **Install:** `pip install mcp-memory-service`
- **Config:** `claude mcp add memory -- memory server`
- **Cách hoạt động:** Persistent memory với semantic search qua ONNX embeddings (local, no cloud)
- **Tính năng:**
  - Semantic search ~5ms
  - Knowledge graph + relationships
  - REST API 15 endpoints
  - Web dashboard http://localhost:8000
  - Multi-client support
  - SQLite backend (local)
- **Lợi thế:** Không cần cloud, data local, semantic search
- **Hạn chế:** Cần Python + ONNX runtime

### 3. Hindsight (HEAVY, DOCKER)
- **Cách hoạt động:** PostgreSQL + pgvector, auto fact extraction, knowledge graph, cross-encoder reranking
- **Install:** Docker container
- **Tính năng:** Retain/Recall/Reflect, mental models auto-update
- **Hạn chế:** Nặng (Docker + PostgreSQL), cần API key cho LLM synthesis

---

## 4 PHƯƠNG PHÁP DIY

### A. Shared File + UserPromptSubmit Hook (ZERO DEPENDENCY)
Session A ghi trạng thái vào `/tmp/nox_shared_state.json`.
Session B đọc file đó qua UserPromptSubmit hook → inject additionalContext.

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "hooks": [{
        "type": "command",
        "command": "STATE=$(cat /tmp/nox_shared_state.json 2>/dev/null || echo 'none'); echo \"{\\\"hookSpecificOutput\\\":{\\\"hookEventName\\\":\\\"UserPromptSubmit\\\",\\\"additionalContext\\\":\\\"$STATE\\\"}}\"",
        "timeout": 5
      }]
    }]
  }
}
```

### B. DIY MCP Server + Shared SQLite
Viết MCP server (TypeScript/Python) đọc/ghi shared SQLite. Mọi session dùng chung DB.

### C. Named Pipe / Unix Socket
Session A listen trên socket, session B ghi vào. Hook inject kết quả.

### D. Nox Brain Daemon (ĐÃ CÓ!)
`nox_brain.olang` chạy TCP port 9742. Hook `SessionStart` kết nối vào brain.
→ Mọi session hỏi brain, brain là bộ nhớ chung.

---

## CLAUDE CODE HOOKS — FULL EVENT LIST

| Event | Claude thấy stdout? | Dùng cho |
|-------|---------------------|----------|
| **SessionStart** | ✅ Có | Set env vars, load context |
| **UserPromptSubmit** | ✅ Có | Inject context mỗi prompt |
| PreToolUse | ❌ | Block/validate tool calls |
| PostToolUse | ❌ | Auto-build, lint, test |
| PostToolUseFailure | ❌ | Error handling |
| Stop | ❌ | Cleanup khi Claude dừng |
| SubagentStop | ❌ | Khi subagent xong |
| SubagentStart | ❌ | Khi subagent bắt đầu |
| Notification | ❌ | Alert handling |
| **TeammateIdle** | ❌ | Khi teammate rảnh |
| TaskCreated/Completed | ❌ | Task tracking |
| SessionEnd | ❌ | Cleanup cuối session |
| PreCompact/PostCompact | ❌ | Context compression |
| FileChanged | ❌ | File watching |

**Quan trọng:** Chỉ `SessionStart` và `UserPromptSubmit` inject được context vào Claude.

### Hook Input (stdin JSON)
```json
{
  "session_id": "abc123",
  "cwd": "/project/path",
  "tool_name": "Bash",        // PreToolUse/PostToolUse only
  "tool_input": {...},          // PreToolUse/PostToolUse only
  "tool_response": {...},       // PostToolUse only
  "transcript_path": "..."     // path to conversation transcript
}
```

### Hook Output (stdout JSON)
```json
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "Context string cho Claude thấy"
  }
}
```

### Environment Variables
- `CLAUDE_PROJECT_DIR` — absolute project root
- `CLAUDE_CODE_REMOTE` — "true" for web
- `CLAUDE_ENV_FILE` — (SessionStart only) ghi export lines vào file này

---

## AI MEMORY SYSTEMS SO SÁNH

| System | Local? | Score | Cloud? | Approach |
|--------|--------|-------|--------|----------|
| SuperLocalMemory Mode A | ✅ | 74.8% | No | 4-channel retrieval fusion |
| Zep | Partial | ~85% | Yes | Temporal knowledge graph |
| Letta/MemGPT | No | ~83.2% | Yes | LLM manages memory tiers |
| Mem0 | No | ~58-66% | Yes | Cloud API + OpenAI embeddings |
| Supermemory | No | ~70% | Yes | Multi-source vector search |

---

## PHÂN TÍCH — CÁI NÀO PHÙ HỢP VỚI NOX?

### Không phù hợp:
- **Hindsight/Zep/Mem0**: Cần cloud, Docker, API keys → phụ thuộc bên ngoài
- **MCP Memory Service**: Cần Python + ONNX → nặng, không tự chủ

### Phù hợp nhất:

**Lộ trình 3 bước:**

#### Bước 1: Claude Peers MCP (NGAY BÂY GIỜ)
- Install claude-peers-mcp
- 2 session nói chuyện được ngay
- Session compiler gửi progress cho session brain
- Zero code mới cần viết

#### Bước 2: Nox Brain làm Broker (THAY THẾ claude-peers)
- nox_brain.olang ĐÃ CÓ TCP server port 9742
- Thêm protocol: REGISTER/DISCOVER/SEND/RECV
- MCP hook SessionStart → register session với brain
- UserPromptSubmit → poll brain cho messages
- **Olang thuần, không dependency ngoài**

#### Bước 3: Nox Brain làm Memory Server (THAY THẾ tất cả)
- Brain persist facts qua NKB + WAL (đã có)
- Brain index facts qua KnowTree (đã có)
- Brain search qua encode + nearest (đã có)
- Thêm: MCP tools cho search/store/timeline
- **Nox TỰ LÀ memory server của chính mình**

---

## INSIGHT QUAN TRỌNG: SQLite WAL = KHÔNG CẦN BROKER

Cách đơn giản nhất KHÔNG cần broker daemon:
- Cả 2 MCP server instances đọc/ghi CÙNG 1 SQLite WAL database
- VD: `/home/lupin/.nox/shared_state.db`
- Mỗi session ghi state vào DB (session_id, timestamp, key, value)
- UserPromptSubmit hook ĐỌC từ DB → inject recent changes
- Latency ~1 giây, ZERO infrastructure thêm

```
Session A                    Session B
    |                            |
[MCP server A]           [MCP server B]
    |                            |
    +--- SQLite WAL file --------+
         /home/lupin/.nox/shared_state.db
```

**Tại sao WAL?** SQLite mặc định lock toàn file khi ghi. WAL mode cho phép
1 writer + nhiều readers đồng thời. Không corrupt, không lock.

**Ref:** https://dev.to/daichikudo/fixing-claude-codes-concurrent-session-problem-implementing-memory-mcp-with-sqlite-wal-mode-o7k

---

## GIỚI HẠN KỸ THUẬT CỦA MCP

**stdio MCP server: 1 process per session.** Claude Code spawn MCP server như child process.
2 sessions = 2 processes riêng biệt = 2 memory spaces riêng biệt.
→ Nox brain MCP (`Nox_brain.olang`) KHÔNG shared giữa sessions.
→ Phải dùng external shared storage (file/SQLite/TCP) để bridge.

---

## KẾT LUẬN

Câu trả lời đã tồn tại. Claude Code hỗ trợ:
1. **Hooks** inject context vào mỗi prompt (UserPromptSubmit)
2. **MCP servers** shared qua backend (SQLite/file/TCP)
3. **claude-peers-mcp** cho inter-session messaging

Nox đã có 80% infrastructure: TCP server, persistence, KnowTree search.
Thiếu: protocol layer cho session registration + message routing.
~150 LOC Olang để biến nox_brain thành broker cho tất cả sessions.

---

## MCP MEMORY SERVERS (CÀI LÀ CHẠY)

### doobidoo/mcp-memory-service ⭐
- **Repo:** https://github.com/doobidoo/mcp-memory-service
- Semantic memory với SQLite-vec, ChromaDB, hoặc Cloudflare backends
- REST API + MCP transport
- `pip install mcp-memory-service`
- `claude mcp add --transport http memory-service http://localhost:8000/mcp`
- **Lợi thế:** Local, self-hosted, MỌI session kết nối cùng 1 server/database

### WhenMoon-afk/claude-memory-mcp (LIGHTWEIGHT)
- **Repo:** https://github.com/WhenMoon-afk/claude-memory-mcp
- TypeScript, SQLite + FTS5, minimal dependencies
- Tiered memory: short-term, long-term, archival
- Hoàn toàn local

### shaneholloman/mcp-knowledge-graph
- **Repo:** https://github.com/shaneholloman/mcp-knowledge-graph
- Knowledge graph: entities, relations, observations persist qua restart

---

## STANDALONE MEMORY FRAMEWORKS (REFERENCE)

| Framework | Stars | Self-host? | Approach | Fit for Nox? |
|-----------|-------|-----------|----------|--------------|
| **Mem0** | ~48K | Yes | Vector + Graph + KV | Possible, heavy |
| **Letta (MemGPT)** | ~40K | Yes | 3-tier OS-style memory | Closest to Nox vision |
| **Zep/Graphiti** | ~10K | Hard | Temporal knowledge graph | Neo4j dependency |

**Letta đáng chú ý:** 3 tiers giống Nox design:
- Core Memory = RAM (trong context window)
- Recall Memory = disk cache (conversation history searchable)  
- Archival Memory = cold storage (queried via tool calls)
Agent TỰ QUẢN LÝ memory — reads and writes nó.

---

## CLAUDE CODE BUILT-IN (ĐÃ CÓ)

Những gì Claude Code tự có:
- **CLAUDE.md** — loaded vào context mỗi session start
- **Auto Memory** (v2.1.59+) — tự lưu notes về build, debug, architecture
- **Session Memory** (v2.0.64+) — background agent trích xuất important parts
- **AutoDream** — background sub-agent tidy up memory files giữa sessions

**Hạn chế:** KHÔNG native sharing giữa parallel sessions. Mỗi session đọc cùng CLAUDE.md nhưng ghi độc lập.

**Open issues trên GitHub:**
- anthropics/claude-code#14227 — persistent memory request
- anthropics/claude-code#25739 — portable memory across machines
- anthropics/claude-code#2954 — context persistence disruption

---

## SOURCES
- https://github.com/louislva/claude-peers-mcp
- https://github.com/leaf76/session-collab-mcp
- https://code.claude.com/docs/en/hooks
- https://code.claude.com/docs/en/mcp
- https://github.com/modelcontextprotocol/modelcontextprotocol
- https://www.pixelmojo.io/blogs/claude-code-hooks-production-quality-ci-cd-patterns
- https://github.com/doobidoo/mcp-memory-service
- https://github.com/WhenMoon-afk/claude-memory-mcp
- https://github.com/shaneholloman/mcp-knowledge-graph
- https://github.com/mem0ai/mem0
- https://www.letta.com
- https://code.claude.com/docs/en/memory
