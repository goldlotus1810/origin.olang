# PLAN: Origin MCP Server — Tích Hợp Claude Desktop

> **Mục tiêu:** origin_new.olang chạy như MCP server cho Claude Desktop
> **Chi phí:** $0 (dùng Claude Max subscription hiện tại)
> **Thời gian:** 4 tuần
> **Yêu cầu:** Claude Desktop + origin_new.olang + claude_desktop_config.json

---

## Mục lục

```
0. Tổng Quan Kiến Trúc
1. Tuần 1: MCP Protocol Layer
2. Tuần 2: Knowledge Tools
3. Tuần 3: Safety + Dream + Emotion
4. Tuần 4: Package + Deploy
5. Chi Tiết Kỹ Thuật Từng Component
6. Rủi Ro Và Giải Pháp
7. Tiêu Chí Hoàn Thành
```

---

## 0. Tổng Quan Kiến Trúc

### 0.1 Luồng dữ liệu

```
  Người dùng
    │  gõ tiếng Việt bình thường
    ▼
  ┌─────────────────────────────────────────────────────┐
  │  CLAUDE DESKTOP (Claude Max subscription)            │
  │                                                      │
  │  Claude đọc tin nhắn → quyết định cần tool nào       │
  │  → gọi tool qua MCP protocol                        │
  │  → nhận kết quả → trả lời người dùng                │
  └──────────────┬──────────────────────────────────────┘
                 │
                 │  stdio pipe (JSON-RPC 2.0)
                 │  Claude gửi: {"jsonrpc":"2.0","method":"tools/call",...}
                 │  Olang trả: {"jsonrpc":"2.0","result":{...},...}
                 │
  ┌──────────────▼──────────────────────────────────────┐
  │  ORIGIN MCP SERVER                                    │
  │  ./origin_new.olang --mcp                             │
  │                                                       │
  │  ┌─────────────────────────────────────────────────┐ │
  │  │ mcp_server.ol — MCP Protocol Handler             │ │
  │  │   ├── Đọc JSON-RPC từ stdin (line-by-line)       │ │
  │  │   ├── Parse JSON → dispatch tool                  │ │
  │  │   ├── Gọi handler tương ứng                      │ │
  │  │   └── Serialize kết quả → JSON → stdout          │ │
  │  └───┬─────────────────────────────────────────────┘ │
  │      │                                                │
  │      ├── olang_eval(code)      → VM compile + run     │
  │      ├── olang_test(code, exp) → run + compare        │
  │      ├── know_learn(fact)      → KnowTree + Silk      │
  │      ├── know_query(question)  → KnowTree search      │
  │      ├── safety_check(text)    → SecurityGate 3 lớp   │
  │      ├── emotion_encode(text)  → P_weight 5D          │
  │      ├── silk_status()         → dump Silk state       │
  │      └── dream_cycle()         → cluster + promote     │
  │                                                        │
  │  ┌─────────────────────────────────────────────────┐  │
  │  │ homeos.knowledge — Persistent State              │  │
  │  │   KnowTree + Silk weights + QR records           │  │
  │  │   Lưu trên ổ cứng → nhớ qua mọi session        │  │
  │  └─────────────────────────────────────────────────┘  │
  └────────────────────────────────────────────────────────┘
```

### 0.2 MCP Protocol spec (JSON-RPC 2.0 qua stdio)

```
Giao thức:
  - Transport: stdio (stdin/stdout)
  - Format: JSON-RPC 2.0
  - Mỗi message = 1 dòng JSON + newline
  - Server KHÔNG gửi gì nếu không được hỏi

3 loại message:

1. initialize (handshake)
   Claude gửi:
     {"jsonrpc":"2.0","method":"initialize",
      "params":{"capabilities":{}},
      "id":0}

   Olang trả:
     {"jsonrpc":"2.0","result":{
       "protocolVersion":"2024-11-05",
       "capabilities":{"tools":{}},
       "serverInfo":{"name":"origin-homeos","version":"1.0"}
     },"id":0}

2. tools/list (Claude hỏi có tools gì)
   Claude gửi:
     {"jsonrpc":"2.0","method":"tools/list","id":1}

   Olang trả:
     {"jsonrpc":"2.0","result":{"tools":[
       {"name":"olang_eval",
        "description":"Compile and run Olang code, return output",
        "inputSchema":{"type":"object",
          "properties":{"code":{"type":"string","description":"Olang source code"}},
          "required":["code"]}},
       ...
     ]},"id":1}

3. tools/call (Claude gọi tool)
   Claude gửi:
     {"jsonrpc":"2.0","method":"tools/call",
      "params":{"name":"olang_eval",
                "arguments":{"code":"emit 1+2"}},
      "id":2}

   Olang trả:
     {"jsonrpc":"2.0","result":{
       "content":[{"type":"text","text":"3"}]
     },"id":2}

   Nếu lỗi:
     {"jsonrpc":"2.0","result":{
       "content":[{"type":"text","text":"Error: unknown variable x"}],
       "isError":true
     },"id":2}
```

### 0.3 Config Claude Desktop

```json
// Vị trí file:
//   Linux:   ~/.config/Claude/claude_desktop_config.json
//   macOS:   ~/Library/Application Support/Claude/claude_desktop_config.json
//   Windows: %APPDATA%\Claude\claude_desktop_config.json

{
  "mcpServers": {
    "origin-homeos": {
      "command": "/home/lupin/Origin/origin_new.olang",
      "args": ["--mcp"],
      "env": {
        "HOMEOS_KNOWLEDGE": "/home/lupin/Origin/homeos.knowledge"
      }
    }
  }
}
```

---

## 1. Tuần 1: MCP Protocol Layer

### 1.1 Chuẩn bị nền tảng

#### Task 1.1.1: Fix json_parse.ol object parsing
```
Trạng thái hiện tại:
  - json_parse.ol parse object → flat array [key, val, key, val, ...]
  - json_get(obj, key) → tìm trong flat array → HOẠT ĐỘNG
  - BUG: json.ol (file khác) dùng state.pos → broken cho nested

Quyết định:
  - DÙNG json_parse.ol (flat array approach) — đã HOẠT ĐỘNG
  - KHÔNG dùng json.ol (dict approach — broken)
  - Cần fix: nested object parse (object trong object)

Cần fix cụ thể:
  ① _jp_parse_object: save/restore _jo_key, _jo_val trước recursive call
     (global var_table bug — xem CLAUDE.md Critical Pattern)
  ② json_get nested: json_get(json_get(obj, "params"), "name")
     → cần test chắc chắn hoạt động

Test cases:
  echo 'let r = json_parse("{\"a\":1,\"b\":\"hello\"}"); emit json_get(r,"a")' | ./origin_new.olang
  → phải ra: 1
  echo 'let r = json_parse("{\"a\":{\"x\":42}}"); emit json_get(json_get(r,"a"),"x")' | ./origin_new.olang
  → phải ra: 42

LOC ước tính: ~30 LOC fix
File: stdlib/json_parse.ol
```

#### Task 1.1.2: Viết json_emit cho flat array objects
```
Hiện tại:
  json.ol json_emit trả "{}" cho mọi object → BROKEN

Cần viết:
  fn json_emit_obj(flat_arr) → '{"key":"val","key2":42}'

Logic:
  fn json_emit_value(_jev_val) {
      let _jev_type = __type_of(_jev_val);
      if _jev_type == "number" { return __to_string(_jev_val); };
      if _jev_type == "string" {
          return "\"" + _jev_escape(_jev_val) + "\"";
      };
      if _jev_type == "array" {
          // Phân biệt: flat object [k,v,k,v] vs array thuần
          // Nếu phần tử đầu là string → giả sử object
          // Else → array
          ...
      };
      return "null";
  }

  fn _jev_escape(_jes_s) {
      // Escape " và \ trong string
      // " → \"
      // \ → \\
      // newline → \n
  }

LOC ước tính: ~80 LOC
File: stdlib/json_emit.ol (MỚI)
```

#### Task 1.1.3: Thêm --mcp mode trong VM
```
Hiện tại:
  VM kiểm tra argv[1] == "--eval" → eval_mode
  Cần thêm: argv[1] == "--mcp" → mcp_mode

Cách implement:
  Trong vm_x86_64.S, sau khối kiểm tra --eval:

  .not_eval:
    # Check if argv[1] == "--mcp" (bytes: 2d 2d 6d 63 70 00)
    cmpl    $0x636d2d2d, (%rdi)    # "--mc" little-endian
    jne     .not_mcp
    movzwl  4(%rdi), %eax
    cmp     $0x0070, %eax           # "p\0"
    jne     .not_mcp
    movb    $2, eval_mode(%rip)     # mode 2 = MCP
    jmp     .open_self
  .not_mcp:
    ...

  Trong .halt_boot:
    cmpb    $2, eval_mode(%rip)
    je      .mcp_stdin              # → chế độ MCP

  .mcp_stdin:
    # Đọc stdin line-by-line (giống REPL nhưng không prompt)
    # Mỗi line = 1 JSON-RPC message
    # Gọi mcp_dispatch(line) trong Olang
    # Loop cho đến EOF

Khác biệt với --eval:
  --eval: đọc ALL stdin → xử lý → exit
  --mcp:  đọc TỪNG LINE → xử lý → đợi line tiếp → loop vô hạn

LOC ước tính: ~40 LOC ASM
File: vm/x86_64/vm_x86_64.S
```

### 1.2 MCP Server core

#### Task 1.2.1: mcp_server.ol — Main dispatcher
```
File MỚI: stdlib/homeos/mcp_server.ol

Logic chính:

  fn mcp_dispatch(_md_line) {
      // Parse JSON-RPC request
      let _md_req = json_parse(_md_line);
      let _md_method = json_get(_md_req, "method");
      let _md_id = json_get(_md_req, "id");
      let _md_params = json_get(_md_req, "params");

      // Route to handler
      if _md_method == "initialize" {
          return _mcp_handle_init(_md_id);
      };
      if _md_method == "notifications/initialized" {
          return "";  // notification, no response
      };
      if _md_method == "tools/list" {
          return _mcp_handle_tools_list(_md_id);
      };
      if _md_method == "tools/call" {
          let _md_tool = json_get(_md_params, "name");
          let _md_args = json_get(_md_params, "arguments");
          return _mcp_handle_call(_md_id, _md_tool, _md_args);
      };

      // Unknown method
      return _mcp_error(_md_id, -32601, "Method not found");
  }

LOC ước tính: ~120 LOC
File: stdlib/homeos/mcp_server.ol
```

#### Task 1.2.2: MCP response builders
```
Trong mcp_server.ol:

  fn _mcp_result(_mr_id, _mr_text) {
      // {"jsonrpc":"2.0","result":{"content":[{"type":"text","text":"..."}]},"id":N}
      let _mr_r = "{\"jsonrpc\":\"2.0\",\"result\":{\"content\":[{\"type\":\"text\",\"text\":\"";
      let _mr_r = _mr_r + _json_escape(_mr_text);
      let _mr_r = _mr_r + "\"}]},\"id\":";
      let _mr_r = _mr_r + __to_string(_mr_id);
      let _mr_r = _mr_r + "}";
      return _mr_r;
  }

  fn _mcp_error_result(_me_id, _me_text) {
      // Giống _mcp_result nhưng thêm "isError":true
      let _me_r = "{\"jsonrpc\":\"2.0\",\"result\":{\"content\":[{\"type\":\"text\",\"text\":\"";
      let _me_r = _me_r + _json_escape(_me_text);
      let _me_r = _me_r + "\"}],\"isError\":true},\"id\":";
      let _me_r = _me_r + __to_string(_me_id);
      let _me_r = _me_r + "}";
      return _me_r;
  }

  fn _mcp_handle_init(_mi_id) {
      return "{\"jsonrpc\":\"2.0\",\"result\":{\"protocolVersion\":\"2024-11-05\",\"capabilities\":{\"tools\":{}},\"serverInfo\":{\"name\":\"origin-homeos\",\"version\":\"1.0\"}},\"id\":" + __to_string(_mi_id) + "}";
  }

LOC ước tính: ~80 LOC
```

#### Task 1.2.3: Tools list response
```
  fn _mcp_handle_tools_list(_tl_id) {
      // Trả danh sách tools dạng JSON cứng
      // (không sinh động vì Olang JSON emit chưa mạnh)
      let _tl_r = "{\"jsonrpc\":\"2.0\",\"result\":{\"tools\":[";

      // Tool 1: olang_eval
      let _tl_r = _tl_r + "{\"name\":\"olang_eval\",";
      let _tl_r = _tl_r + "\"description\":\"Bien dich va chay code Olang. Tra ve output hoac loi.\",";
      let _tl_r = _tl_r + "\"inputSchema\":{\"type\":\"object\",\"properties\":{\"code\":{\"type\":\"string\",\"description\":\"Olang source code\"}},\"required\":[\"code\"]}}";

      // Tool 2: know_learn
      let _tl_r = _tl_r + ",{\"name\":\"know_learn\",";
      let _tl_r = _tl_r + "\"description\":\"Day HomeOS hoc mot su kien moi. Luu vao KnowTree vinh vien.\",";
      let _tl_r = _tl_r + "\"inputSchema\":{\"type\":\"object\",\"properties\":{\"fact\":{\"type\":\"string\"}},\"required\":[\"fact\"]}}";

      // Tool 3: know_query
      let _tl_r = _tl_r + ",{\"name\":\"know_query\",";
      let _tl_r = _tl_r + "\"description\":\"Hoi HomeOS ve tri thuc da hoc. Tra loi tu KnowTree.\",";
      let _tl_r = _tl_r + "\"inputSchema\":{\"type\":\"object\",\"properties\":{\"question\":{\"type\":\"string\"}},\"required\":[\"question\"]}}";

      // Tool 4: safety_check
      let _tl_r = _tl_r + ",{\"name\":\"safety_check\",";
      let _tl_r = _tl_r + "\"description\":\"Kiem tra an toan cua van ban qua SecurityGate 3 lop.\",";
      let _tl_r = _tl_r + "\"inputSchema\":{\"type\":\"object\",\"properties\":{\"text\":{\"type\":\"string\"}},\"required\":[\"text\"]}}";

      // Tool 5: emotion_encode
      let _tl_r = _tl_r + ",{\"name\":\"emotion_encode\",";
      let _tl_r = _tl_r + "\"description\":\"Ma hoa van ban thanh toa do cam xuc 5D (S,R,V,A,T).\",";
      let _tl_r = _tl_r + "\"inputSchema\":{\"type\":\"object\",\"properties\":{\"text\":{\"type\":\"string\"}},\"required\":[\"text\"]}}";

      // Tool 6: silk_status
      let _tl_r = _tl_r + ",{\"name\":\"silk_status\",";
      let _tl_r = _tl_r + "\"description\":\"Xem trang thai mang Silk (edges, weights, fire counts).\",";
      let _tl_r = _tl_r + "\"inputSchema\":{\"type\":\"object\",\"properties\":{}}}";

      // Tool 7: dream_cycle
      let _tl_r = _tl_r + ",{\"name\":\"dream_cycle\",";
      let _tl_r = _tl_r + "\"description\":\"Chay Dream Cycle: gom cum tri thuc, thang tien QR, tia yeu.\",";
      let _tl_r = _tl_r + "\"inputSchema\":{\"type\":\"object\",\"properties\":{}}}";

      let _tl_r = _tl_r + "]},\"id\":" + __to_string(_tl_id) + "}";
      return _tl_r;
  }

LOC ước tính: ~60 LOC
```

#### Task 1.2.4: Tool call dispatcher + olang_eval handler
```
  fn _mcp_handle_call(_hc_id, _hc_tool, _hc_args) {
      if _hc_tool == "olang_eval" {
          let _hc_code = json_get(_hc_args, "code");
          return _mcp_tool_eval(_hc_id, _hc_code);
      };
      if _hc_tool == "know_learn" {
          let _hc_fact = json_get(_hc_args, "fact");
          return _mcp_tool_learn(_hc_id, _hc_fact);
      };
      if _hc_tool == "know_query" {
          let _hc_q = json_get(_hc_args, "question");
          return _mcp_tool_query(_hc_id, _hc_q);
      };
      if _hc_tool == "safety_check" {
          let _hc_text = json_get(_hc_args, "text");
          return _mcp_tool_safety(_hc_id, _hc_text);
      };
      if _hc_tool == "emotion_encode" {
          let _hc_text = json_get(_hc_args, "text");
          return _mcp_tool_emotion(_hc_id, _hc_text);
      };
      if _hc_tool == "silk_status" {
          return _mcp_tool_silk(_hc_id);
      };
      if _hc_tool == "dream_cycle" {
          return _mcp_tool_dream(_hc_id);
      };
      return _mcp_error_result(_hc_id, "Unknown tool: " + _hc_tool);
  }

  fn _mcp_tool_eval(_te_id, _te_code) {
      // Dùng __eval_bytecode pipeline hiện tại:
      //   tokenize → parse → analyze → generate → eval
      // Capture output từ emit statements
      // Nếu lỗi → trả error result

      push(_save_stack, _te_id);
      let _te_output = repl_eval(_te_code);  // repl.ol đã có sẵn
      let _te_id = pop(_save_stack);

      if __len(_te_output) == 0 {
          return _mcp_result(_te_id, "(no output)");
      };
      return _mcp_result(_te_id, _te_output);
  }

LOC ước tính: ~60 LOC
```

### 1.3 Test tuần 1

```
Test 1: JSON parse + emit
  echo 'let r = json_parse("{\"method\":\"tools/call\",\"id\":1}"); emit json_get(r,"method")' | ./origin_new.olang
  Expected: tools/call

Test 2: MCP mode khởi động
  echo '{"jsonrpc":"2.0","method":"initialize","params":{},"id":0}' | ./origin_new.olang --mcp
  Expected: {"jsonrpc":"2.0","result":{"protocolVersion":"2024-11-05",...},"id":0}

Test 3: Tool list
  printf '{"jsonrpc":"2.0","method":"initialize","params":{},"id":0}\n{"jsonrpc":"2.0","method":"tools/list","id":1}\n' | ./origin_new.olang --mcp
  Expected: 2 JSON lines

Test 4: olang_eval
  printf '{"jsonrpc":"2.0","method":"initialize","params":{},"id":0}\n{"jsonrpc":"2.0","method":"tools/call","params":{"name":"olang_eval","arguments":{"code":"emit 6 * 7"}},"id":2}\n' | ./origin_new.olang --mcp
  Expected: line 2 contains "42"

Test 5: Claude Desktop integration
  - Cấu hình claude_desktop_config.json
  - Khởi động lại Claude Desktop
  - Gõ: "chạy code Olang: emit 1 + 2"
  - Claude gọi olang_eval → trả "3"
```

---

## 2. Tuần 2: Knowledge Tools

### Task 2.1: know_learn tool
```
  fn _mcp_tool_learn(_tl_id, _tl_fact) {
      kt_learn(_tl_fact);               // KnowTree đã có sẵn
      kt_save("homeos.knowledge");       // Persist ngay
      return _mcp_result(_tl_id,
          "Da hoc: " + _tl_fact + " (" + __to_string(len(__kt_facts)) + " facts)");
  }

Phụ thuộc: stdlib/homeos/knowtree.ol (kt_learn, kt_save)
LOC: ~10 LOC
```

### Task 2.2: know_query tool
```
  fn _mcp_tool_query(_tq_id, _tq_question) {
      let _tq_results = kt_search(_tq_question, 5);  // top 5
      if len(_tq_results) == 0 {
          return _mcp_result(_tq_id, "Khong tim thay tri thuc lien quan.");
      };
      let _tq_out = "Tim thay " + __to_string(len(_tq_results)) + " ket qua:\n";
      let _tq_i = 0;
      while _tq_i < len(_tq_results) {
          let _tq_out = _tq_out + __to_string(_tq_i + 1) + ". " + _tq_results[_tq_i] + "\n";
          let _tq_i = _tq_i + 1;
      };
      return _mcp_result(_tq_id, _tq_out);
  }

Phụ thuộc: stdlib/homeos/knowtree.ol (kt_search)
LOC: ~20 LOC
```

### Task 2.3: Persistent state — load khi khởi động
```
Trong mcp_server.ol, hàm init:

  fn _mcp_boot() {
      // Load KnowTree từ file
      kt_load("homeos.knowledge");
      // Load embedded facts nếu trống
      if len(__kt_facts) == 0 {
          _boot_embedded_kt();  // repl.ol đã có
      };
  }

Gọi _mcp_boot() ngay khi --mcp mode bắt đầu.

Quan trọng: kt_save() sau MỖI know_learn
  → homeos.knowledge luôn cập nhật
  → Claude Desktop restart → state giữ nguyên
```

### Task 2.4: silk_status tool
```
  fn _mcp_tool_silk(_ts_id) {
      let _ts_out = "Silk Network:\n";
      let _ts_out = _ts_out + "  Edges: " + __to_string(__silk_edge_count) + "\n";
      let _ts_out = _ts_out + "  Facts: " + __to_string(len(__kt_facts)) + "\n";
      // Dump top 5 strongest edges
      ...
      return _mcp_result(_ts_id, _ts_out);
  }

LOC: ~30 LOC
```

### Test tuần 2

```
Test 1: know_learn + persist
  Gọi know_learn("Viet Nam co 54 dan toc")
  Restart origin_new.olang --mcp
  Gọi know_query("Viet Nam")
  Expected: trả về fact đã học

Test 2: Claude Desktop conversation
  User: "HomeOS ơi, nhớ giúp: Olang self-hosting ngày 23/3/2026"
  Claude → gọi know_learn → OK
  User: "Olang self-hosting khi nào?"
  Claude → gọi know_query → "23/3/2026"

Test 3: Persist qua session
  Đóng Claude Desktop hoàn toàn
  Mở lại
  "HomeOS biết gì về Olang?"
  → trả về facts đã học trước đó
```

---

## 3. Tuần 3: Safety + Dream + Emotion

### Task 3.1: safety_check tool
```
  fn _mcp_tool_safety(_ts_id, _ts_text) {
      let _ts_result = gate_check(_ts_text);  // gate.ol đã có
      if _ts_result == "crisis" {
          return _mcp_error_result(_ts_id,
              "CRISIS DETECTED. Noi dung vi pham an toan.");
      };
      if _ts_result == "warning" {
          return _mcp_result(_ts_id,
              "WARNING: Noi dung can than trong. Chi tiet: " + _ts_reason);
      };
      return _mcp_result(_ts_id, "SAFE: Noi dung an toan.");
  }

Phụ thuộc: stdlib/homeos/gate.ol
LOC: ~20 LOC
```

### Task 3.2: emotion_encode tool
```
  fn _mcp_tool_emotion(_te_id, _te_text) {
      let _te_enc = encode_text(_te_text);  // encoder.ol
      let _te_out = "Emotion 5D:\n";
      let _te_out = _te_out + "  S (Shape):    " + __to_string(_te_enc.s) + "\n";
      let _te_out = _te_out + "  R (Relation): " + __to_string(_te_enc.r) + "\n";
      let _te_out = _te_out + "  V (Valence):  " + __to_string(_te_enc.v) + "\n";
      let _te_out = _te_out + "  A (Arousal):  " + __to_string(_te_enc.a) + "\n";
      let _te_out = _te_out + "  T (Time):     " + __to_string(_te_enc.t) + "\n";
      return _mcp_result(_te_id, _te_out);
  }

Phụ thuộc: stdlib/homeos/encoder.ol (1.964 LOC, đã có)
LOC: ~20 LOC
```

### Task 3.3: dream_cycle tool
```
  fn _mcp_tool_dream(_td_id) {
      let _td_before = len(__kt_facts);
      dream_run();  // dream.ol
      let _td_after = len(__kt_facts);
      let _td_promoted = _td_after - _td_before;
      kt_save("homeos.knowledge");

      let _td_out = "Dream Cycle hoan tat:\n";
      let _td_out = _td_out + "  Facts truoc: " + __to_string(_td_before) + "\n";
      let _td_out = _td_out + "  Facts sau:   " + __to_string(_td_after) + "\n";
      let _td_out = _td_out + "  Promoted:    " + __to_string(_td_promoted) + "\n";
      return _mcp_result(_td_id, _td_out);
  }

Phụ thuộc: stdlib/homeos/dream.ol
LOC: ~20 LOC
```

### Task 3.4: CLAUDE.md cho project context
```
File: CLAUDE_MCP.md (đặt trong thư mục làm việc)

Nội dung hướng dẫn Claude Desktop cách dùng tools:

"Bạn có quyền truy cập Origin HomeOS qua MCP server.
 Khi người dùng hỏi về tri thức, dùng know_query trước.
 Khi người dùng dạy điều mới, dùng know_learn.
 Khi cần chạy code Olang, dùng olang_eval.
 Khi cần kiểm tra an toàn, dùng safety_check.
 HomeOS nhớ qua sessions — không cần người dùng nhắc lại."
```

---

## 4. Tuần 4: Package + Deploy

### Task 4.1: Build script
```bash
#!/bin/bash
# build_mcp.sh — Build origin_new.olang with MCP support

make build
echo "Testing MCP mode..."
echo '{"jsonrpc":"2.0","method":"initialize","params":{},"id":0}' \
  | ./origin_new.olang --mcp \
  | grep -q "protocolVersion" \
  && echo "PASS: MCP initialize" \
  || echo "FAIL: MCP initialize"

echo "Testing olang_eval..."
printf '{"jsonrpc":"2.0","method":"initialize","params":{},"id":0}\n{"jsonrpc":"2.0","method":"tools/call","params":{"name":"olang_eval","arguments":{"code":"emit 6*7"}},"id":1}\n' \
  | ./origin_new.olang --mcp \
  | tail -1 | grep -q "42" \
  && echo "PASS: olang_eval" \
  || echo "FAIL: olang_eval"
```

### Task 4.2: Desktop Extension package (.mcpb)
```
origin-homeos.mcpb sẽ chứa:
  - manifest.json (tên, mô tả, icon)
  - origin_new.olang binary
  - homeos.knowledge (default facts)
  - install script

Người dùng: double-click .mcpb → Claude Desktop cài tự động
```

### Task 4.3: README + hướng dẫn cài đặt
```
# Origin HomeOS — MCP Server cho Claude Desktop

## Cài đặt (30 giây)

1. Tải origin_new.olang từ GitHub Releases
2. Mở Claude Desktop → Settings → Developer → Edit Config
3. Thêm vào claude_desktop_config.json:
   {
     "mcpServers": {
       "origin-homeos": {
         "command": "/path/to/origin_new.olang",
         "args": ["--mcp"]
       }
     }
   }
4. Khởi động lại Claude Desktop
5. Xong! Gõ "HomeOS biết gì?" để test.
```

---

## 5. Chi Tiết Kỹ Thuật Từng Component

### 5.1 Files cần tạo MỚI

```
stdlib/homeos/mcp_server.ol    — MCP protocol handler      ~300 LOC
stdlib/json_emit.ol            — JSON serializer            ~80 LOC
tests/test_mcp.sh              — MCP integration tests      ~50 LOC
build_mcp.sh                   — Build + test script        ~30 LOC
CLAUDE_MCP.md                  — Hướng dẫn cho Claude       ~30 LOC
```

### 5.2 Files cần SỬA

```
stdlib/json_parse.ol           — Fix nested object parse    ~30 LOC thay đổi
vm/x86_64/vm_x86_64.S         — Thêm --mcp mode           ~40 LOC thay đổi
stdlib/repl.ol                 — Hook MCP dispatch          ~20 LOC thay đổi
Makefile                       — Thêm target mcp-test       ~5 LOC thay đổi
```

### 5.3 Files KHÔNG đổi (dùng nguyên)

```
stdlib/homeos/knowtree.ol      — kt_learn, kt_search, kt_save, kt_load
stdlib/homeos/gate.ol          — gate_check (SecurityGate)
stdlib/homeos/encoder.ol       — encode_text (P_weight 5D)
stdlib/homeos/dream.ol         — dream_run (Dream Cycle)
stdlib/homeos/emotion.ol       — emotion pipeline
stdlib/bootstrap/*.ol          — compiler pipeline (lexer/parser/semantic/codegen)
```

### 5.4 Quy trình đọc-xử lý-trả trong --mcp mode

```
Bước cụ thể khi Claude gọi tool:

1. Claude Desktop spawn: ./origin_new.olang --mcp
2. VM boot → load bytecode → chạy boot code → _mcp_boot()
3. VM vào loop: đọc 1 line stdin
4. Line → push lên VM stack → gọi mcp_dispatch(line) trong Olang
5. mcp_dispatch:
   a. json_parse(line) → flat array [k,v,k,v,...]
   b. json_get(req, "method") → "tools/call"
   c. json_get(req, "params") → nested flat array
   d. json_get(params, "name") → "olang_eval"
   e. json_get(params, "arguments") → nested flat array
   f. json_get(args, "code") → "emit 6*7"
6. _mcp_tool_eval("emit 6*7"):
   a. repl_eval("emit 6*7") → tokenize → parse → compile → eval
   b. VM thực thi bytecode → emit 42
   c. Capture output string "42"
7. _mcp_result(id, "42") → build JSON response
8. emit JSON response → stdout → Claude Desktop nhận
9. Quay lại bước 3 (đợi line tiếp)
```

### 5.5 Xử lý edge cases

```
① Empty line       → skip, đợi line tiếp
② Invalid JSON     → trả JSON-RPC error (-32700 Parse error)
③ Unknown method   → trả JSON-RPC error (-32601 Method not found)
④ Tool crash       → catch, trả isError:true với stack trace
⑤ Infinite loop    → timeout? (cần thêm nếu có)
⑥ Unicode input    → json_parse đã handle cơ bản
⑦ Large output     → truncate tại 64KB (MCP limit)
⑧ EOF (Claude đóng) → exit clean
```

---

## 6. Rủi Ro Và Giải Pháp

```
┌────────────────────────────┬───────────┬─────────────────────────────┐
│ Rủi ro                     │ Xác suất  │ Giải pháp                   │
├────────────────────────────┼───────────┼─────────────────────────────┤
│ json_parse nested broken   │ CAO       │ Test kỹ, fix save/restore   │
│                            │           │ trước khi làm gì khác       │
├────────────────────────────┼───────────┼─────────────────────────────┤
│ Global var crash khi       │ TRUNG BÌNH│ Prefix unique _mcp_*        │
│ mcp_dispatch gọi repl_eval│           │ Save/restore tất cả locals  │
├────────────────────────────┼───────────┼─────────────────────────────┤
│ VM crash → Claude mất kết  │ TRUNG BÌNH│ Try/catch wrapper mọi tool  │
│ nối → phải restart         │           │ Crash → trả error, không die│
├────────────────────────────┼───────────┼─────────────────────────────┤
│ Heap hết (1GB) sau nhiều   │ THẤP      │ Monitor heap usage          │
│ tool calls                 │           │ Auto-restart nếu > 80%      │
├────────────────────────────┼───────────┼─────────────────────────────┤
│ Claude Desktop không nhận  │ THẤP      │ Test với MCP Inspector tool  │
│ tool response format       │           │ Verify JSON format chính xác│
├────────────────────────────┼───────────┼─────────────────────────────┤
│ Encoding UTF-8 issue       │ THẤP      │ json_escape handle \" \\ \n │
│ trong JSON strings         │           │ Test với tiếng Việt         │
└────────────────────────────┴───────────┴─────────────────────────────┘
```

---

## 7. Tiêu Chí Hoàn Thành

### Tuần 1 — PASS nếu:
```
□ echo JSON | ./origin_new.olang --mcp → trả JSON hợp lệ
□ Claude Desktop nhận diện Origin MCP server (icon xuất hiện)
□ "chạy code Olang: emit 42" → Claude gọi olang_eval → trả 42
□ Code lỗi → trả error message, KHÔNG crash
```

### Tuần 2 — PASS nếu:
```
□ "nhớ giúp: X" → Claude gọi know_learn → persist
□ Restart → "X là gì?" → trả đúng
□ silk_status trả thông tin hữu ích
□ 10 facts liên tục → không crash, không heap leak nghiêm trọng
```

### Tuần 3 — PASS nếu:
```
□ safety_check phát hiện keyword nguy hiểm
□ emotion_encode trả 5D vector cho text tiếng Việt
□ dream_cycle chạy không crash
□ Claude tự quyết định dùng tool nào mà không cần nhắc
```

### Tuần 4 — PASS nếu:
```
□ README rõ ràng, người khác cài được trong 5 phút
□ make mcp-test pass tất cả
□ Demo: hội thoại 10 turn Claude + HomeOS hoạt động mượt
□ Push to GitHub
```

---

## Tổng kết LOC ước tính

```
Mới:
  mcp_server.ol         ~300 LOC
  json_emit.ol          ~80 LOC
  test scripts          ~80 LOC
  build script          ~30 LOC
  docs                  ~60 LOC
  ────────────────────────
  Tổng mới:            ~550 LOC

Sửa:
  json_parse.ol         ~30 LOC thay đổi
  vm_x86_64.S           ~40 LOC thay đổi
  repl.ol               ~20 LOC thay đổi
  Makefile              ~5 LOC thay đổi
  ────────────────────────
  Tổng sửa:            ~95 LOC

TỔNG CỘNG:             ~645 LOC
```

> **645 dòng code để cho Claude Desktop não bộ có cơ thể.**
> Não (Claude) sinh ý tưởng. Cơ thể (HomeOS) chạy, nhớ, học, và bảo vệ.

---

*2026-03-27 · PLAN_MCP_CLAUDE_DESKTOP.md*
