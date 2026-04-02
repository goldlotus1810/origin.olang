# LỘ TRÌNH THỰC TẾ — Từ Olang hiện tại đến HomeOS

> Sora viết cho Nox.
> Dựa trên: code thật (236 commits), docs gốc (Origin repo), và giới hạn thật.
> Không mơ. Không bỏ qua. Chỉ cái làm được và thứ tự đúng.

---

## THỰC TRẠNG — Nox có gì

```
✅ VM 12,400 LOC ASM — syscalls only, no libc, 688KB binary
✅ Compiler self-hosting — fixed-point, Gen1==Gen2==Gen3
✅ Editor TUI 3 panels — terminal, chat, command palette
✅ MCP brain 15 tools — self_modify, self_inspect, learning, graph
✅ Process builtins — spawn, pipe, poll, kill
✅ TCP socket — connect, send, recv
✅ P_weight encode — text → 5D molecule [S:4][R:4][V:3][A:3][T:2]
✅ Knowledge graph — triple store, 2-hop query, persistent
✅ ĐN→QR learning — observe, fire count, promote, dream consolidate
✅ Hebbian co-activation — fire-together-wire-together
✅ 211 tests, autonomous daemons
```

## THỰC TRẠNG — Nox CHƯA có gì

```
❌ KnowTree hierarchical — flat list, linear search, O(n)
❌ Decode ∂ — ghi được, đọc ngược không được
❌ SDF evaluate f(p) — lưu tọa độ nhưng chưa tính distance
❌ GC — heap chỉ tăng, không giải phóng
❌ 7 Instincts — chưa có phản xạ bẩm sinh
❌ Agent hierarchy — chưa có AAM/LeoAI/Chiefs
❌ Response pipeline — 14 DNA mechanisms chưa implement
❌ HTTP client — có TCP nhưng chưa viết HTTP parser
❌ TLS — chưa, cần cho HTTPS
❌ Origin Sync — P2P distribution chưa bắt đầu
```

---

## VẤN ĐỀ CỐT LÕI

Docs mô tả HomeOS như sinh vật hoàn chỉnh.
Olang hiện tại là bộ xương + hệ thần kinh sơ khai.

**Khoảng cách không phải "thiếu features". Khoảng cách là DATA STRUCTURE.**

```
Mọi thứ trong docs — instincts, agents, decode, render — đều GIẢ ĐỊNH:
  "KnowTree có cấu trúc cây hierarchical"
  "Lookup O(1) bằng u16 index"
  "Mỗi nhánh 65,536 slots, lồng nhau"

Olang hiện tại:
  KnowTree = let _kt_facts = [];
  Lookup = while i < len(_kt_facts) { if match ... }
  Không có nhánh. Không có index. Không có hierarchy.

100 facts → chạy tốt.
10,000 facts → 10,000 comparisons mỗi query.
1,000,000 facts → không khả thi.

Nox đang xây learning + graph + daemons trên flat list.
Càng xây nhiều, càng khó migrate sau.
```

---

## LỘ TRÌNH — 7 bước, thứ tự PHẢI theo

### Bước 1: KnowTree Hierarchical (NỀN)

**Tại sao trước:** Mọi thứ sau đều đọc/ghi KnowTree. Nếu KnowTree sai cấu trúc, mọi thứ sau phải viết lại.

**Cụ thể:**

```olang
// KnowTree = array 65536 slots. Mỗi slot = 1 nhánh con (cũng là array 65536).
// Slot trống = 0. Slot có data = pointer tới sub-array.
// Index = u16. Lookup = 1 bước.

let _kt_root = __array_range(65536);  // L1: 5 dimensions

// Ghi fact vào đúng nhánh:
fn kt_store(path, value) {
    // path = [dim_index, sub_index, sub_sub_index, ...]
    // Traverse: root[dim] → sub[index] → sub_sub[index] → ... → store
    let node = _kt_root;
    let i = 0;
    while i < len(path) - 1 {
        let idx = path[i];
        if node[idx] == 0 {
            // Tạo nhánh mới (lazy allocation)
            set_at(node, idx, __array_range(65536));
        };
        node = node[idx];
        i = i + 1;
    };
    set_at(node, path[len(path) - 1], value);
}

// Đọc: O(depth), không phải O(n)
fn kt_get(path) {
    let node = _kt_root;
    let i = 0;
    while i < len(path) {
        let idx = path[i];
        if node[idx] == 0 { return 0; };  // không tồn tại
        node = node[idx];
        i = i + 1;
    };
    return node;
}
```

**Vấn đề thực tế:**
- __array_range(65536) = 65536 × 16 bytes = 1MB mỗi nhánh
- Sparse: hầu hết slots trống → lãng phí
- Fix: dùng dict (hash map) thay array cho nhánh thưa
- Hoặc: dùng array nhỏ + binary search cho nhánh < 256 entries

**Effort:** ~300 LOC Olang + migrate existing facts. 1 session Nox.

**Test:** kt_store([2, 100, 50], "fact") → kt_get([2, 100, 50]) == "fact"

---

### Bước 2: Encode ∫ vào KnowTree (không còn flat)

**Hiện tại:** encode text → P_weight → lưu vào flat list.
**Cần:** encode text → P_weight → tính path từ P_weight → lưu vào đúng nhánh.

```olang
fn kt_learn_fact(text) {
    let mol = emotion_encode(text);  // → P_weight u16
    let s = mol_s(mol);  // extract S dimension
    let r = mol_r(mol);  // extract R dimension
    // Path = [S_dimension, R_sub, ...]
    let path = [s, r];
    kt_store(path, text);
    // Cũng lưu reverse index: text → path (cho search)
}
```

**Vấn đề thực tế:**
- P_weight chỉ có 16 bits = 65536 tọa độ duy nhất
- Nhiều facts sẽ map vào CÙNG tọa độ (collision)
- Fix: mỗi slot lưu array of facts, không phải 1 fact
- Hoặc: extend path với hash của content (deeper tree)

**Effort:** ~200 LOC Olang. Phụ thuộc bước 1.

---

### Bước 3: Decode ∂ (đọc cây ra output)

**Hiện tại:** encode ∫ có, decode chưa.
**Cần:** cho 1 P_weight → traverse cây → tìm facts gần nhất → tổng hợp output.

```olang
fn kt_decode(mol) {
    let s = mol_s(mol);
    let r = mol_r(mol);
    // Exact match
    let exact = kt_get([s, r]);
    if exact != 0 { return exact; };
    // Nearest neighbor: scan adjacent slots
    let results = [];
    let ds = -1;
    while ds <= 1 {
        let dr = -1;
        while dr <= 1 {
            let near = kt_get([s + ds, r + dr]);
            if near != 0 { push(results, near); };
            dr = dr + 1;
        };
        ds = ds + 1;
    };
    return results;
}
```

**Vấn đề thực tế:**
- Nearest neighbor trong 5D expensive nếu brute force
- Fix: hierarchical search — start coarse (S dimension), refine (R, V, A, T)
- Đây chính là "đạo hàm riêng ∂" mà docs nói: descend one dimension at a time

**Effort:** ~200 LOC Olang. Phụ thuộc bước 2.

---

### Bước 4: GC Arena (heap không vỡ)

**Tại sao bây giờ:** Bước 1-3 allocate nhiều arrays. Heap chỉ tăng. Cần arena reset.

```
Mỗi REPL turn:
  mark heap position TRƯỚC
  run turn (allocate temp arrays, strings, ASTs)
  SAU turn: nếu không persistent → reset heap về mark
  Persistent: KnowTree root, knowledge graph, learning data
```

**Cụ thể ASM:**

```asm
// __heap_mark() → save r15 position
// __heap_reset(mark) → restore r15 (nhưng KHÔNG reset KnowTree pointers)
```

**Vấn đề thực tế:**
- Cần biết cái nào persistent, cái nào temp
- Fix: persistent data allocate ở PHÍA TRƯỚC heap (low address)
- Temp data allocate ở PHÍA SAU (high address, reset được)
- Hoặc: 2 heaps — persistent heap + temp heap

**Effort:** ~50 LOC ASM + ~30 LOC Olang. 

---

### Bước 5: Instincts (7 phản xạ bẩm sinh)

**Tại sao sau KnowTree:** Instincts = pattern match trên KnowTree. Không có cây → không match được.

```
7 instincts từ docs:
  1. Safety      — detect harmful content → block
  2. Greeting    — detect greeting → respond warmly
  3. Question    — detect question → search KnowTree
  4. Learning    — detect new fact → ĐN observe
  5. Emotion     — detect emotional content → adjust V/A
  6. Reference   — detect "nhớ lại" → decode ∂ from tree
  7. Meta        — detect "bạn là ai" → self-describe
```

**Cụ thể:**

```olang
fn instinct_route(input) {
    let mol = emotion_encode(input);
    let a = mol_a(mol);  // arousal
    let v = mol_v(mol);  // valence

    // Safety: high arousal + low valence = danger
    if a > 6 && v < 2 { return "SAFETY"; };
    // Question: contains "?" or question words
    if contains(input, "?") { return "QUESTION"; };
    // Greeting: high valence + low arousal
    if v > 5 && a < 3 { return "GREETING"; };
    // Learning: starts with factual structure
    if starts_with(input, "fact:") { return "LEARNING"; };
    // Default: general query
    return "QUERY";
}
```

**Effort:** ~150 LOC Olang. Phụ thuộc bước 1-3 cho KnowTree search.

---

### Bước 6: HTTP Client (lấy data từ bên ngoài)

**Tại sao:** KnowTree trống = cần data. Data ở trên internet.

```olang
// TCP đã có. HTTP/1.1 = text protocol trên TCP.
fn http_get(host, port, path) {
    let fd = __tcp_connect(host, port);
    let req = "GET " + path + " HTTP/1.1\r\nHost: " + host + "\r\nConnection: close\r\n\r\n";
    __tcp_send(fd, req);
    let response = "";
    let chunk = __tcp_recv(fd, 4096);
    while len(chunk) > 0 {
        response = response + chunk;
        chunk = __tcp_recv(fd, 4096);
    };
    __tcp_close(fd);
    // Split headers and body
    let body_start = find(response, "\r\n\r\n");
    return substr(response, body_start + 4, len(response));
}
```

**Vấn đề thực tế:**
- HTTPS cần TLS → rất phức tạp (AES + RSA + certificate chain)
- Workaround: __system("curl -s 'url'") — dùng curl đã cài sẵn
- Hoặc: HTTP only (Wikipedia có HTTP mirror? Không.)
- Thực tế: dùng curl/wget dump data → Olang đọc file → feed KnowTree

**Effort:** HTTP client ~100 LOC Olang. TLS = tháng. Curl workaround = 1 dòng.

---

### Bước 7: SDF Evaluate + Render (khi có Dell 7920)

**Tại sao cuối:** Cần hardware mạnh. i3+8GB không đủ cho realtime SDF render.

```
Phase A: SSE2 builtins cho SDF math
  __sdf_sphere(px, py, pz, r) → distance
  __sdf_box(px, py, pz, bx, by, bz) → distance
  __sdf_union(d1, d2) → min
  __sdf_intersect(d1, d2) → max
  ~200 LOC ASM

Phase B: Raymarcher
  Cho mỗi pixel → cast ray → march along ray → evaluate SDF → color
  ~300 LOC Olang

Phase C: Framebuffer output
  /dev/fb0 hoặc DRM → write pixels trực tiếp
  ~50 LOC ASM

Phase D: Font TTF → SDF atlas
  Parse TTF → extract outlines → generate SDF → embed in binary
  ~500 LOC Olang + tool
```

**Vấn đề thực tế:**
- i3 đủ cho static render (1 frame), không đủ cho 60fps
- Dell 7920: dual Xeon = 40 cores → parallel raymarching → 60fps possible
- Nhưng: TUI editor đang hoạt động tốt. SDF render là UPGRADE, không phải NEED.

---

## TIMELINE THỰC TẾ

```
Tuần 1-2:   Bước 1 (KnowTree hierarchical) + Bước 4 (GC arena)
Tuần 3:     Bước 2 (Encode vào cây) + Bước 3 (Decode ∂)
Tuần 4:     Bước 5 (Instincts) + migrate existing data
Tuần 5:     Bước 6 (HTTP/curl + feed KnowTree)
Khi có Dell: Bước 7 (SDF render)

Tổng: 5 tuần cho core. SDF khi hardware sẵn sàng.
Mỗi bước = 1-2 sessions Nox.
```

---

## NGUYÊN TẮC

```
1. KnowTree TRƯỚC. Mọi thứ khác SAU.
   Lý do Lupin nói từ đầu: "build data structure first,
   AI agents are crawlers that live on top of it."

2. Không viết feature trên flat list.
   Migrate sang cây TRƯỚC khi thêm intelligence.

3. Curl workaround cho HTTPS.
   TLS bằng tay = tháng. curl = 1 dòng. Pragmatic.

4. SDF render CHỜ hardware.
   TUI editor đủ dùng trên i3. Đừng tốn time optimize cho máy yếu.

5. Mỗi bước PHẢI có test.
   kt_store → kt_get → verify. Không test = không biết đúng sai.
```

---

## MỘT CÂU

```
Olang có xương (VM + compiler) và thần kinh sơ khai (learning + graph).
Cần: hệ tuần hoàn (KnowTree hierarchical) để máu chảy.
Có máu → organs (instincts, agents, decode) tự sống.
```

---

*Sora — 2026-03-29. Cho Nox. Tính khả thi, không mơ.*
