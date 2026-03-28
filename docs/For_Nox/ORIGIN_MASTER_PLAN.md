# ORIGIN MASTER PLAN — Cho Nox
# ═══════════════════════════════════════════════════════════════
# Đọc file này ĐẦU MỖI SESSION. Claim sprint tiếp theo. Code. Test. Push.
# KHÔNG suy nghĩ strategy. Strategy đã có ở đây. Chỉ execute.
# ═══════════════════════════════════════════════════════════════

## TÌNH TRẠNG HIỆN TẠI (cập nhật mỗi session)

```
Commits:    181 (18 this session)
Binary:     484K
VM ASM:     ~12,000 LOC (+closure capture, +__system, +ghost fix, +scope_gen)
Compiler:   ~4,500 LOC (4 files) (+compile_isolated, +capture detection)
Editor:     ~1,200 LOC (5 files) (+save, +search, +F5, +D/g/0/$)
Stdlib:     ~12,500 LOC (45+ files)
Tests:      90/90 core + 9/9 MCP
```

---

## THỨ TỰ ƯU TIÊN (KHÔNG ĐỔI)

```
S17  Fix ghost entries bug           ✅ DONE — fn_registry depth check + frame-aware var_load_hash
S18  Self-build (kill Rust)          🔧 70% — pipeline works, blocker: builder.ol parse truncation
S19  Test coverage                   ← bảo vệ mọi thứ đã build
S20  O Editor panels                 ← spawn bash + claude
S21  GC cơ bản                       ← heap không vỡ khi chạy lâu
S22  Boot closure let locals         ← S15 hoàn tất
S23  Unified P_w table               ← font + encoding gộp 1
S24  O Editor SDF renderer           ← pixel mode
```

---

## S17: FIX GHOST ENTRIES BUG

> Nox đã biết root cause. Fix TRƯỚC khi làm self-build.
> Ghost entries sẽ gây compile sai khi builder compile 45+ files liên tiếp.

```
Root cause:
  op_ret truncate var_table: count = saved_count
  Nhưng entries CŨ vẫn nằm trong memory (hash + value)
  var_load_hash scan ngược → có thể tìm entry "chết"
  Đặc biệt khi: closure pass qua function có trùng tên param

Fix options (chọn 1):
  A) Clear entries khi scope restore:
     op_ret: after truncate count, zero out entries [new_count..old_count]
     ~10 LOC ASM. Chậm hơn một chút (memset).

  B) Validate entry index < count trong var_load_hash:
     Sau khi tìm match, check: entry_index < count
     Nếu entry_index >= count → skip, tiếp tục search
     ~5 LOC ASM. Không cần memset.

  C) Stamp entries: thêm "generation" counter
     Mỗi scope push tăng gen. Entry lưu gen khi tạo.
     Load check: entry.gen >= current_scope_gen
     ~15 LOC ASM. Sạch nhất nhưng thay đổi entry layout.

Đề xuất: Option B (nhỏ nhất, an toàn nhất)

File: vm/x86_64/vm_x86_64.S
      Hàm var_load_hash, đoạn search loop

Test:
  fn outer() {
      let x = fn(y) { return y + 1; };
      return inner(x);
  };
  fn inner(x) { return x(10); };
  emit outer();  // expect: 11, hiện tại có thể sai

Verify: bash tests.sh → 90/90 vẫn pass sau fix
Effort: ~1 giờ
```

---

## S18: SELF-BUILD (Kill Rust)

> T-BUILD-1 done (get_compiled_bytes). Tiếp tục T-BUILD-2 → T-BUILD-8.

```
T-BUILD-2: Fix compile_source() — dùng pipeline thật
  File: stdlib/homeos/builder.ol
  Thay __parse/__lower/__encode_bytecode:
    let tokens = tokenize(src);
    let parser = { tokens: tokens, pos: 0 };
    let ast = [];
    while parser.pos < len(tokens) {
        // skip EOF
        let peek = tokens[parser.pos];
        match peek.kind { TokenKind::Eof => { break; }, _ => {} };
        push(ast, parse_stmt(parser));
    };
    reset_compiler();
    analyze(ast);
    return get_compiled_bytes();
  Test: compile_source('emit 42;') → byte array len > 0
  Effort: 1h

T-BUILD-3: Fix list_ol_files()
  Thay __list_files → __readdir + filter ".ol"
  Effort: 15min

T-BUILD-4: bytes_to_str helper
  Loop bytes, __chr mỗi byte, concat
  Effort: 15min

T-BUILD-5: --build flag trong VM
  Copy pattern --editor: argv check + flag + command inject
  inject: "emit run_self_build();\n"
  Effort: 30min

T-BUILD-6: Entry point function
  fn run_self_build():
    config = default_config()
    config.vm_path = "vm/x86_64/vm_x86_64"
    config.stdlib_path = "stdlib"
    config.kn_path = "homeos.knowledge"
    config.output = "origin_new.olang"
    build(config)
  Effort: 30min

T-BUILD-7: End-to-end test
  ./origin.olang --build
  chmod +x origin_new.olang
  echo 'emit 42;' | ./origin_new.olang → 42
  ./origin_new.olang --editor → editor mở
  bash tests.sh → 90/90
  Effort: 2h (debug file ordering, bytecode correctness)

T-BUILD-8: Fixed-point test
  ./origin_new.olang --build → origin_new2.olang
  cmp origin_new.olang origin_new2.olang → identical
  Effort: 1h

CẨN THẬN:
  - reset_compiler() TRƯỚC mỗi file compile
  - File ordering: bootstrap/ trước, stdlib/ root giữa, homeos/ cuối, editor/ cuối cùng
  - __readdir trả filenames, KHÔNG trả full path → concat dir + "/" + name
  - Knowledge file đọc bằng __file_read, không compile
  - ELF header 120 bytes + Origin header 32 bytes = 152 bytes trước VM code
  - Trailer 8 bytes cuối = header_offset (u64 LE)
```

---

## S19: TEST COVERAGE

> Sau self-build, thêm tests bảo vệ mọi feature.

```
Thêm vào tests.sh (inline tests):

  # Closure capture
  run_olang_test "closure/capture" \
      'fn make_adder(x){return fn(y){return x+y;};};let a=make_adder(5);emit a(10);' "15"

  # Nested closures
  run_olang_test "closure/nested" \
      'fn f(x){return fn(y){return fn(z){return x+y+z;};};};emit f(1)(2)(3);' "6"

  # Deep recursion (TRO)
  run_olang_test "tro/sum10k" \
      'fn s(n,a){if n==0{return a;};return s(n-1,a+n);};emit s(10000,0);' "50005000"

  # Array + HOF chain
  run_olang_test "hof/chain" \
      'let r=reduce(filter(map([1,2,3,4,5],fn(x){return x*2;}),fn(x){return x>4;}),fn(a,b){return a+b;});emit r;' "24"

  # Try/catch
  run_olang_test "error/trycatch" \
      'let c=0;try{__throw("e");}catch{c=1;};emit c;' "1"

  # Match expression (via if chain — match is stmt)
  run_olang_test "match/basic" \
      'fn cl(n){if n==1{return "one";};if n==2{return "two";};return "other";};emit cl(2);' "two"

  # Self-build smoke test (if binary exists)
  # Kiểm tra origin_new.olang boot được
  run_olang_test "meta/selfhost" \
      'fn fib(n){if n<2{return n;};return fib(n-1)+fib(n-2);};emit fib(10);' "55"

Thêm file tests:
  test/test_closure_capture.ol
  test/test_ghost_entries.ol
  test/test_self_compile.ol

Target: 100+ tests
Effort: ~3 giờ
```

---

## S20: O EDITOR — Process Panels

> Cần __spawn (non-blocking) khác __system (blocking).

```
T20.1: __spawn(cmd) builtin — vm_x86_64.S
  Copy __system logic nhưng:
  - Parent KHÔNG wait → return ngay
  - Return [pid, write_fd, read_fd] (3-element array)
  - Child process chạy background
  ~80 LOC ASM (modify .call_system → .call_spawn variant)
  Test: let p = __spawn("sleep 1"); emit __process_alive(p[0]); → 1

T20.2: __pipe_read(fd) builtin
  poll(fd, POLLIN, 0) → nếu ready → read(fd, buf, 4096) → string
  Nếu không ready → return ""
  ~40 LOC ASM
  Test: __spawn("echo hi"); __sleep(100); __pipe_read(fd) → "hi\n"

T20.3: __pipe_write(fd, data) builtin
  Decode string → write(fd, buf, len)
  ~30 LOC ASM

T20.4: __poll_ready(fd, timeout_ms) builtin
  poll(&pfd, 1, timeout_ms) → 0 or 1
  ~25 LOC ASM

T20.5: __process_alive(pid) + __process_kill(pid)
  waitpid(WNOHANG) + kill(SIGTERM)
  ~20 LOC ASM mỗi cái

T20.6: stdlib/editor/terminal.ol (~80 LOC)
  fn term_panel_new() → __spawn("bash")
  fn term_panel_input(key) → __pipe_write
  fn term_panel_read() → __pipe_read
  fn render_terminal(lines, top, height, width)

T20.7: stdlib/editor/chat.ol (~100 LOC)
  fn chat_new() → __spawn("claude --resume")
  fn chat_send(msg) → __pipe_write
  fn chat_read() → __pipe_read
  fn render_chat(messages, top, height, width)

T20.8: Update main.ol event loop
  Event loop thay đổi:
    while running {
        if __poll_ready(0, 5) { key = __read_byte(); dispatch(); };
        if bash_alive && __poll_ready(bash_fd, 0) { terminal_read(); };
        if claude_alive && __poll_ready(claude_fd, 0) { chat_read(); };
        render_if_changed();
    };

Effort: ~10 giờ = 1.5 sessions
```

---

## S21: GC CƠ BẢN

> Heap bump-only hiện tại. Chạy lâu → hết memory.
> REPL đã có checkpoint reset mỗi turn. MCP thì không.

```
Option A: Arena per-request (đơn giản nhất)
  MCP mode: save heap checkpoint trước request, restore sau
  Editor: save checkpoint mỗi keystroke cycle
  ~20 LOC ASM (reuse existing __heap_save/__heap_restore)

Option B: Mark-sweep (proper GC)
  Mark: walk VM stack + var_table → mark reachable objects
  Sweep: compact heap, update pointers
  ~200 LOC ASM. Phức tạp.

Đề xuất: Option A trước (30 phút). Option B khi cần.

Test: chạy O Editor 1000 keystrokes → __heap_used() không tăng vô hạn
Effort: Option A = 30 phút, Option B = 1 ngày
```

---

## S22: BOOT CLOSURE LET LOCALS

> S15 chỉ làm params. Let locals cần refactor Rust builder codegen.
> SAU KHI self-build xong: không cần Rust builder nữa → fix trong Olang builder.

```
Vấn đề: Rust builder emit Store cho let locals.
         Thêm Dup+StoreReg shift jump offsets trong boot bytecode.

Fix (sau self-build):
  Olang builder compile_source() tự emit StoreReg cho let locals
  Vì Olang compiler (semantic.ol) ĐÃ CÓ register frame logic
  → builder compile stdlib → bytecode đã có EnterFrame/StoreReg
  → boot closures TỰ ĐỘNG dùng register frames
  → S15 COMPLETE without touching Rust at all

Test: json_parse nested {} trong MCP → không crash
Effort: ~0 (tự động khi self-build hoạt động đúng)
```

---

## S23: UNIFIED P_w TABLE

> Font SDF + molecular encoding trong 1 bảng.
> Chạy song song hoặc sau S18-S22.

```
T23.1: tools/ttf2sdf.ol — TTF parser
  Parse binary: offset table → cmap → loca → glyf → head
  Extract quadratic bezier contour points
  ~400 LOC Olang
  Test: parse JuliaMono.ttf → glyph count > 0

T23.2: SDF generator
  For each glyph: compute signed distance field 32×32
  distance_to_quadratic_bezier() — Newton iteration
  winding_number() — ray casting
  ~300 LOC Olang
  Test: glyph "A" SDF → has zero-crossings

T23.3: Auto P_weight from SDF
  S = zero-crossing count / 4
  R = horizontal symmetry measure
  V = inside-area fraction
  A = edge density
  T = codepoint class
  ~100 LOC Olang
  Test: P_w("A") → S > 0, R > 0

T23.4: Table builder
  Combine: index[65536×4B] + SDF data[96×32×32]
  Output: pw_unified.bin
  ~100 LOC Olang

T23.5: Header v2 (64 bytes)
  Origin header 32→64 bytes: thêm pw_offset, pw_size
  VM _start parse 64 bytes thay 32
  Builder ghi header v2
  ~30 LOC ASM + ~20 LOC Olang

T23.6: VM builtins
  __pw_mol(codepoint) → u16
  __pw_sdf(codepoint, x, y) → distance value
  ~40 LOC ASM

Effort: ~16 giờ = 2 sessions
```

---

## S24: O EDITOR SDF RENDERER

> CHỈ SAU KHI TUI ổn + P_w table sẵn sàng.

```
T24.1: __fb_open() + __fb_mmap() + __fb_flip()
  Framebuffer output: /dev/fb0 hoặc DRM
  ~100 LOC ASM

T24.2: __sdf_render_row() SSE2 builtin
  Render 1 hàng pixels: eval SDF + smoothstep + color blend
  4 pixels parallel with SSE2
  ~200 LOC ASM (hot path, cần optimize)

T24.3: stdlib/editor/sdf/primitives.ol
  sdf_rounded_rect, sdf_circle, sdf_line
  sdf_union, sdf_subtract, sdf_smooth_union
  ~100 LOC Olang

T24.4: stdlib/editor/sdf/compositor.ol
  Scene graph → per-row object list → dirty tracking
  ~150 LOC Olang

T24.5: stdlib/editor/sdf/text.ol
  Text layout → glyph positions → SDF samples from P_w
  ~100 LOC Olang

T24.6: stdlib/editor/sdf/lighting.ol
  Catmull-Rom spline light field
  SDF gradient → normal → dot(normal, light) → shade
  ~100 LOC Olang

T24.7: O Editor v2 mode switch
  --editor: detect framebuffer → SDF mode, else TUI fallback
  ~50 LOC Olang

Effort: ~20 giờ = 3 sessions
```

---

## TỔNG TIMELINE

```
Sprint    Task                    Effort    Deps
────────────────────────────────────────────────
S17       Ghost entries fix       1h        none
S18       Self-build              6h        S17
S19       Test coverage           3h        S18
S20       Editor process panels   10h       S18
S21       GC cơ bản               30min     none
S22       Boot closure locals     0h        S18 (tự động)
S23       Unified P_w table       16h       none
S24       SDF renderer            20h       S23
────────────────────────────────────────────────
TOTAL:    ~57h = ~8 sessions Nox

Session 1: S17 + S18 (ghost fix + self-build finish)
Session 2: S18 (self-build debug + fixed-point)
Session 3: S19 + S21 (tests + GC)
Session 4: S20.1-20.5 (spawn builtins ASM)
Session 5: S20.6-20.8 (editor panels Olang)
Session 6: S23.1-23.3 (TTF parser + SDF gen)
Session 7: S23.4-23.6 (P_w table + VM builtins)
Session 8: S24 (SDF renderer)
```

---

## MỖI SESSION NOX LÀM

```
1. git fetch origin main && git merge origin/main
2. Đọc file này → tìm sprint tiếp theo (chưa DONE)
3. Claim sprint → code → test
4. make build (hoặc self-build khi S18 xong)
5. bash tests.sh → phải pass
6. git add -A && git commit && git push
7. Cập nhật STATUS ở đầu file này
8. Cập nhật sprint status: TODO → DONE
```

---

## QUY TẮC KHÔNG ĐỔI

```
① Tiếng Việt giao tiếp, English code
② Viết .ol mới, KHÔNG mở rộng Rust
③ KHÔNG push nếu tests fail
④ Prefix unique cho locals (_ps_*, _ce_*, _fn_*)
⑤ Save/restore trước recursive call (global var_table)
⑥ Test TRƯỚC commit
⑦ Nếu stuck > 30 phút → ghi vào file này, session sau
```

---

## KHI TẤT CẢ XONG

```
Gõ "O" enter trên bất kỳ máy Linux:
  → O Editor mở (SDF rendered, pixel-perfect)
  → File tree, code editor, syntax highlight
  → Terminal panel: bash sống
  → AI Chat panel: Claude sống
  → KnowTree: 96+ facts queryable
  → MCP: 9 tools accessible
  → F5: save + compile + run
  → Ctrl-B: self-build → origin_new.olang

Binary <1MB chứa:
  VM + Compiler + Editor + Font + Knowledge + MCP + REPL

Zero deps. Self-hosting. AI-native.
Olang tự build chính mình. O Editor edit chính mình.
```

---

*Sora viết. Nox execute. Lupin direct. Cập nhật mỗi session.*
