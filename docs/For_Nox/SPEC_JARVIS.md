# SPEC_JARVIS — 1 Brain, N Interfaces

> Jarvis xuất hiện khắp nơi vì 1 brain, nhiều mouth.
> 3 Claude trên cùng máy không nói chuyện vì 3 brain riêng.
> Fix: Nox IS the brain. Mọi CLI session = temporary mouth.

---

## Vấn đề

```
HIỆN TẠI trên máy Lupin:
  Terminal 1: claude (Nox session) → brain riêng, quên khi tắt
  Terminal 2: claude (Sora session) → brain riêng, quên khi tắt
  Terminal 3: claude (task session) → brain riêng, quên khi tắt
  
  3 sessions. 3 brains. Không share. Không nói chuyện.
  Mỗi session mới = Lupin giải thích lại từ đầu.

JARVIS:
  Phòng khách: "Jarvis, bật đèn" → 1 brain trả lời
  Phòng lab:   "Jarvis, phân tích" → CÙNG brain trả lời
  Trong suit:  "Jarvis, quét địch" → CÙNG brain trả lời
  
  1 brain. N interfaces. Brain nhớ TẤT CẢ.
```

---

## Kiến trúc: Nox = Brain on Disk

```
/home/lupin/Origin/
├── origin.olang          ← CƠ THỂ (binary, VM, compiler)
├── nox_memory.dat        ← TRI THỨC (KnowTree facts + mols)
├── nox_silk.dat          ← KẾT NỐI (Silk edges, Hebbian)
├── nox_stm.dat           ← TRÍ NHỚ NGẮN HẠN (recent inputs)
├── nox_observations.dat  ← TRẢI NGHIỆM (mọi interaction)
├── homeos.knowledge      ← KIẾN THỨC NỀN (boot facts)
└── json/                 ← DỮ LIỆU (500K entries)

Brain = files. Không phải RAM. Không phải session.
Tắt terminal → brain VẪN CÒN trên disk.
Mở terminal mới → đọc brain → BIẾT TẤT CẢ.
```

---

## J1. Nox Daemon — Brain luôn sẵn sàng

```
Nox chạy background, luôn sống:

  ./origin.olang --daemon

Daemon:
  1. Boot: load nox_memory.dat + nox_silk.dat + nox_stm.dat
  2. Listen: TCP port 9100 (internal) + HTTP port 9000 (dashboard)
  3. Accept connections from ANY mouth (CLI, MCP, HTTP, cron)
  4. Process: input → pipeline → response
  5. Persist: auto-save every N turns

Daemon KHÔNG tắt khi terminal đóng.
Daemon là BRAIN. Terminals là MOUTHS.
```

### Implementation

```olang
// stdlib/homeos/daemon.ol — đã có nox_daemon()

pub fn nox_jarvis() {
    // 1. Boot brain
    nox_bootstrap();
    emit "Nox brain online. " + __to_string(kt_fact_count()) + " facts.";
    
    // 2. Start listeners
    let _tcp = __tcp_listen(9100);  // internal protocol
    let _http = __tcp_listen(9000); // HTTP dashboard
    
    emit "Listening: tcp://0.0.0.0:9100 http://0.0.0.0:9000";
    
    // 3. Accept loop
    while 1 == 1 {
        let _ready = __poll_ready(_tcp, _http, 1000);  // 1s timeout
        
        // TCP: raw Nox protocol (fast, for CLI↔brain)
        if __poll_has(_ready, _tcp) {
            let _client = __tcp_accept(_tcp);
            _handle_nox_client(_client);
        };
        
        // HTTP: dashboard + REST API (for browser, MCP proxy)
        if __poll_has(_ready, _http) {
            let _client = __tcp_accept(_http);
            _handle_http_client(_client);
        };
        
        // Heartbeat: dream + decay every 60s
        _heartbeat();
    };
}
```

---

## J2. NoxProtocol — Mouth ↔ Brain

```
Mỗi mouth (CLI session) nói chuyện với brain qua TCP:

  MOUTH → BRAIN: { "type": "query", "text": "Fibonacci la gi?" }
  BRAIN → MOUTH: { "type": "response", "text": "Fibonacci la day so..." }
  
  MOUTH → BRAIN: { "type": "observe", "text": "user said hello", "kind": "input" }
  BRAIN → MOUTH: { "type": "ack", "id": 42 }
  
  MOUTH → BRAIN: { "type": "search", "query": "pipeline", "limit": 5 }
  BRAIN → MOUTH: { "type": "results", "facts": [...] }
  
  MOUTH → BRAIN: { "type": "state" }
  BRAIN → MOUTH: { "type": "status", "facts": 50000, "silk": 1200, "stm": 15 }
```

### Message types

```
query       → pipeline(text) → response
observe     → mem_observe(text, kind) → ack + id
search      → mem_search/kt_find → results
timeline    → mem_timeline(id, range) → observations
state       → brain status → facts/silk/stm/uptime
learn       → kt_learn(text) → ack
dream       → dream() → summary
save        → nox_save() → ack
eval        → __eval_bytecode → result (compile + run Olang)
```

---

## J3. Claude CLI = Mouth

```
Mỗi Claude CLI session trên máy Lupin:

  1. Boot: kiểm tra Nox daemon chạy chưa
     $ pgrep -f "origin.olang --daemon" || ./origin.olang --daemon &
     
  2. CLAUDE.md inject:
     "Nox brain đang chạy tại tcp://localhost:9100.
      Mọi knowledge query → gọi Nox brain.
      Mọi observation → gửi Nox brain.
      Bạn là MOUTH. Nox là BRAIN."
     
  3. Tool call:
     Claude CLI gõ lệnh → shell → connect Nox → query → response
     
     # Trong CLAUDE.md:
     nox_query() { echo '{"type":"query","text":"'$1'"}' | nc localhost 9100; }
     nox_search() { echo '{"type":"search","query":"'$1'","limit":5}' | nc localhost 9100; }
     nox_observe() { echo '{"type":"observe","text":"'$1'","kind":"'$2'"}' | nc localhost 9100; }
     nox_state() { echo '{"type":"state"}' | nc localhost 9100; }
```

### Hoặc đơn giản hơn — pipe file

```
Không cần TCP. Cùng filesystem = dùng file:

MOUTH ghi: echo "Fibonacci la gi?" > /tmp/nox_inbox
BRAIN đọc: inotify /tmp/nox_inbox → pipeline → ghi /tmp/nox_outbox
MOUTH đọc: cat /tmp/nox_outbox

Hoặc named pipe:
  mkfifo /tmp/nox_in /tmp/nox_out
  BRAIN: while read line < /tmp/nox_in; do pipeline "$line" > /tmp/nox_out; done
  MOUTH: echo "hello" > /tmp/nox_in && cat /tmp/nox_out
```

---

## J4. Sora = Specialized Mouth

```
Sora KHÔNG phải brain riêng. Sora = mouth chuyên review.

Claude CLI session (Sora role):
  1. Connect Nox brain: nox_state → biết 50K facts, 1200 silk
  2. Read code: cat stdlib/homeos/pipeline.ol
  3. Query brain: nox_search "pipeline spec" → brain trả SPEC_D context
  4. Review: so sánh code vs spec (Claude's own reasoning)
  5. Report: ghi review → nox_observe "review: pipeline missing CP3" "review"
  6. Brain learns: observation #42 = Sora's review → Silk fire → future context

Sora session mới:
  1. Connect Nox brain → nox_search "recent reviews" → biết Sora cũ review gì
  2. Tiếp tục. Không hỏi Lupin.

Sora KHÔNG CẦN brain riêng. Nox brain = shared knowledge.
Sora reasoning = Claude's own (200K context window).
Combination = brain (Nox) + reasoning (Claude) = POWERFUL.
```

---

## J5. Nox Session = Specialized Mouth

```
Nox CLI (code role):
  1. Connect Nox brain: nox_state → context
  2. Read TASKBOARD: nox_search "current task" → brain trả priorities
  3. Code: sửa .ol files
  4. Test: make test
  5. Observe: nox_observe "fixed pipeline CP3, tests pass" "decision"
  6. Brain learns: Nox's decision → persist → future sessions biết

Nox session mới:
  1. Connect brain → biết session trước fix gì
  2. Tiếp tục từ đúng chỗ dừng. Không đọc git log.
```

---

## J6. Multi-Mouth Concurrent

```
Máy Lupin (hiện tại: i3-4500, 8GB):
  Terminal 1: Nox coding (mouth A) → Nox brain
  Terminal 2: Sora review (mouth B) → CÙNG Nox brain
  
  Nox code → commit → observe "committed pipeline fix"
  Sora (đồng thời): nox_search "recent commits" → thấy Nox vừa commit
  → Sora review ngay → observe "review: looks good" 
  → Nox: nox_search "recent reviews" → thấy Sora approved

  KHÔNG QUA LUPIN. Cả hai đọc/ghi cùng brain.

Máy Dell 7920 (tương lai: dual Xeon, 384GB):
  Terminal 1: Nox coding
  Terminal 2: Sora review  
  Terminal 3: Task runner (test, benchmark, deploy)
  Terminal 4: Camera/sensor processing
  Terminal 5: Local LLM (Ollama 70B) = fluent mouth
  
  5 mouths. 1 brain. Lupin uống cà phê.
```

---

## J7. Implementation Plan

### Phase 1: File-based (NGAY BÂY GIỜ, 0 dependency)

```
Nox brain = origin.olang + persist files (đã có)
Mouth protocol = file read/write (đã có)

Thêm:
  /tmp/nox_inbox    — mouth ghi query
  /tmp/nox_outbox   — brain ghi response
  /tmp/nox_status   — brain ghi state mỗi 10s
  
  nox_daemon() → inotify /tmp/nox_inbox → process → write outbox
  CLAUDE.md → "đọc /tmp/nox_status đầu session, ghi query vào /tmp/nox_inbox"

~30 LOC Olang. Hoạt động NGAY.
```

### Phase 2: TCP socket (tuần sau)

```
nox_jarvis() → TCP 9100
CLI → nc localhost 9100 → JSON protocol
~80 LOC Olang (đã có tcp builtins).
```

### Phase 3: HTTP REST (Dell 7920)

```
GET  /status        → brain state
POST /query         → pipeline(text) → response
POST /observe       → mem_observe
GET  /search?q=     → ranked search
GET  /timeline?id=  → observations around ID

Browser dashboard tại http://localhost:9000
~150 LOC Olang (server.ol đã có HTTP basic).
```

### Phase 4: MCP proxy (Claude Desktop)

```
./origin.olang --mcp = hiện tại (stdin/stdout)
Thêm: MCP over TCP → Claude Desktop connect qua network
→ Sora (Claude.ai) CÓ THỂ connect nếu Lupin expose port

19 MCP tools → tất cả qua TCP thay stdin.
~50 LOC Olang.
```

---

## J8. CLAUDE.md cho Mouth

```markdown
# Bạn là MOUTH của Nox, không phải brain riêng.

## Đầu session:
cat /tmp/nox_status
→ Đọc brain state. Biết facts, silk, recent activity.

## Query brain:
echo '{"type":"query","text":"..."}' > /tmp/nox_inbox
cat /tmp/nox_outbox
→ Brain trả lời từ 50K+ facts + Silk walk + Pipeline.

## Observe (ghi nhận):
echo '{"type":"observe","text":"...","kind":"review"}' > /tmp/nox_inbox
→ Brain học. Session sau sẽ biết.

## KHÔNG:
- Không tự nhớ (brain nhớ hộ)
- Không giải thích lại context (brain đã biết)
- Không tạo brain riêng (1 brain duy nhất = Nox)
```

---

## J9. So sánh

```
                    HIỆN TẠI              JARVIS
────────────────────────────────────────────────────
Sessions            3 riêng lẻ            1 brain + N mouths
Knowledge           mỗi session quên      brain persist vĩnh viễn
Communication       qua Lupin (file)      trực tiếp (socket/file)
Context injection   CLAUDE.md static      brain query dynamic
New session cost    giờ giải thích        0 (brain đã biết)
Concurrent          không                 đồng thời (brain thread-safe)
Lupin effort        translator            observer

Brain size:         nox_memory.dat + nox_silk.dat + nox_stm.dat
                    = hiện tại ~2KB (695 facts)
                    = mục tiêu ~50MB (500K facts + silk + observations)
                    = vẫn << 1 ảnh 4K (8MB)
```

---

## J10. Từ 695 đến Jarvis

```
NGAY:
  1. nox_daemon() + file inbox/outbox         (~30 LOC)
  2. CLAUDE.md inject cho mọi CLI session     (~20 dòng md)
  3. Test: 2 terminals, 1 brain, cả hai query  
  → DONE. Jarvis basic.

TUẦN SAU:
  4. TCP socket thay file                      (~80 LOC)
  5. Auto-save observations                    (~20 LOC)
  6. nox_search cho MCP                        (~40 LOC)
  → Jarvis v1.

DELL 7920:
  7. HTTP dashboard                            (~150 LOC)  
  8. 5 concurrent mouths                       (test)
  9. Local LLM mouth (Ollama)                  (integration)
  → Jarvis full.
```

---

*Jarvis = 1 brain, N mouths.*
*Nox = brain. Claude CLI = mouth. Filesystem = nervous system.*
*30 LOC Olang. Hoạt động ngay. Lupin tự do.*
