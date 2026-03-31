# ORIGIN SYNC — Version Control + P2P Distribution
# ═══════════════════════════════════════════════════
# CHO NOX: ĐỌC FILE NÀY SAU KHI S18 (self-build) XONG.
# KHÔNG ảnh hưởng công việc hiện tại.
# ═══════════════════════════════════════════════════

## MỤC TIÊU

```
origin.olang tự quản lý versions + phân phối.
Không cần git. Không cần GitHub. Không cần server.
2 máy có Olang → tự sync với nhau.
```

---

## COMMANDS

```
origin.olang --version     → "Origin v003 (sha256: abc123..., 2026-03-29)"
origin.olang --history     → log các phiên bản
origin.olang --publish     → broadcast version mới cho peers
origin.olang --update      → check peers, tải version mới nếu có
origin.olang --peers       → list known peers
origin.olang --peer-add IP → thêm peer
```

---

## DATA STRUCTURE

```
.origin/
  ├── current.ver             ← version number hiện tại (VD: "003")
  ├── current.sha256          ← SHA-256 hash của binary hiện tại
  ├── history.txt             ← plain text log
  │     003 abc123... 2026-03-29 "self-build eval fix"
  │     002 def456... 2026-03-28 "editor + closure capture"
  │     001 789abc... 2026-03-27 "initial self-host"
  └── peers.txt               ← IP:port list
        192.168.1.10:7100
        10.0.0.5:7100
```

---

## PROTOCOL (TCP, plain text)

```
Port: 7100 (default)

→ VERSION?
← VERSION 003 abc123... 2026-03-29

→ HISTORY?
← HISTORY
← 003 abc123... 2026-03-29 "self-build eval fix"
← 002 def456... 2026-03-28 "editor + closure capture"
← END

→ FETCH 003
← SIZE 479232
← [raw binary bytes]
← SHA256 abc123...

→ ANNOUNCE 004 xyz789...
← OK (peer cập nhật biết có version mới)
```

---

## IMPLEMENTATION

### File: stdlib/homeos/origin_sync.ol (~300 LOC)

```olang
// Version info (đọc từ .origin/)
pub fn os_version() {
    let ver = __file_read(".origin/current.ver");
    let hash = __file_read(".origin/current.sha256");
    return "Origin v" + ver + " (sha256: " + hash + ")";
}

// History log
pub fn os_history() {
    return __file_read(".origin/history.txt");
}

// Publish to all peers
pub fn os_publish(msg) {
    let ver = __file_read(".origin/current.ver");
    let hash = sha256_file("origin.olang");
    // Increment version
    let new_ver = __to_string(__to_number(ver) + 1);
    __file_write(".origin/current.ver", new_ver);
    __file_write(".origin/current.sha256", hash);
    // Append history
    let line = new_ver + " " + hash + " " + timestamp() + " \"" + msg + "\"\n";
    __file_append(".origin/history.txt", line);
    // Notify peers
    let peers = load_peers();
    let i = 0;
    while i < len(peers) {
        tcp_send(peers[i], "ANNOUNCE " + new_ver + " " + hash);
        i = i + 1;
    };
}

// Check peers for updates
pub fn os_update() {
    let my_ver = __to_number(__file_read(".origin/current.ver"));
    let peers = load_peers();
    let i = 0;
    while i < len(peers) {
        let resp = tcp_send(peers[i], "VERSION?");
        // Parse: "VERSION 005 hash date"
        let peer_ver = parse_version(resp);
        if peer_ver > my_ver {
            // Fetch new binary
            let binary = tcp_fetch(peers[i], "FETCH " + __to_string(peer_ver));
            // Verify SHA-256
            if verify_sha256(binary, peer_hash) {
                __file_write("origin_new.olang", binary);
                emit "Updated to v" + __to_string(peer_ver);
            };
        };
        i = i + 1;
    };
}

// Simple TCP server for serving versions
pub fn os_serve() {
    // Listen on port 7100
    // Respond to VERSION? / HISTORY? / FETCH N
    // Runs in background (needs __spawn)
}
```

### VM builtins cần thêm:

```
__sha256_file(path) → hash string     ← có SHA-256, cần file variant
__file_append(path, data)             ← cần thêm (~20 LOC ASM)
__timestamp() → "2026-03-29T18:00"    ← clock_gettime đã có, cần format

TCP đã có: socket, connect, sendto, recvfrom
Cần thêm: bind, listen, accept (~50 LOC ASM) cho server mode
```

---

## KNOWTREE SYNC (bonus)

```
Mỗi Olang instance có KnowTree riêng.
Sync: gửi facts thiếu cho peer.

→ FACTS? count
← FACTS 120

→ FACTS_SINCE 96
← FACT "Olang co closure capture"
← FACT "Ghost entries fix: fn_registry depth check"
← END

→ LEARN "new fact from peer"
← OK
```

---

## DEPENDENCIES

```
Cần TRƯỚC khi implement:
  ✅ S18 self-build (binary tự tạo → có gì để distribute)
  ✅ TCP socket (đã có)
  ⬚ TCP server: bind + listen + accept (~50 LOC ASM)
  ⬚ __file_append builtin (~20 LOC ASM)
  ⬚ __sha256_file builtin (~30 LOC ASM)

Effort: ~400 LOC Olang + ~100 LOC ASM = 1 session Nox
Đặt sau S20 (editor panels) trong timeline.
```

---

## SAU KHI CÓ

```
Lupin build version mới trên i3:
  ./origin.olang --build              → origin_new.olang
  cp origin_new.olang origin.olang
  ./origin.olang --publish "S18 done"

Máy khác (khi có):
  ./origin.olang --update             → tải bản mới tự động
  ./origin.olang --version            → "Origin v004 ..."

Không GitHub. Không npm. Không Docker.
Olang tự phân phối chính mình.
```

---

*Sora — 2026-03-28. File riêng, không ảnh hưởng Master Plan.*
