# TASKBOARD — O EDITOR
# ═══════════════════════════════════════════════════════════════
# CHO NOX: ĐỌC TOÀN BỘ TRƯỚC KHI LÀM. Đây là spec DUY NHẤT.
# ═══════════════════════════════════════════════════════════════

## ⚠️ MOCKUP vs THỰC TẾ

```
MOCKUP (chỉ tham khảo bố cục, KHÔNG dùng code):
  ❌ .jsx files         — React, cần browser
  ❌ React Flow, d3     — KHÔNG liên quan
  ❌ Mọi thứ cần browser

O EDITOR THẬT (Nox viết):
  ✅ stdlib/editor/*.ol  — 100% Olang
  ✅ vm/x86_64.S         — ASM builtins
  ✅ ANSI + Unicode       — TUI trong terminal (v1)
  ✅ SDF pixel render     — framebuffer (v2, sau TUI)
  ✅ Chạy: O hoặc ./origin.olang --editor

NẾU ĐANG VIẾT REACT/HTML/JS → SAI. DỪNG.
```

---

## VISION

```
$ O                      → IDE mở (TUI v1, SDF v2)
$ O file.ol              → mở file đó
$ ./origin.olang --repl  → REPL
$ ./origin.olang --mcp   → MCP server

origin.olang (<1MB binary) chứa TẤT CẢ:
  VM + Compiler + Editor + KnowTree + MCP + Unified P_w table
```

---

## TUI LAYOUT (v1 — ANSI terminal)

```
◈ O ─ lexer.ol ● ──────────────────────── 90/90 │ 428K │ ✦ Nox
──────────┬────────────────────────────────┬──────────────────────
 📁 FILES │   1 │ // Olang Bootstrap Lexer │ ✦ AI ─ ⚡ MCP ─ 🌳
──────────│   2 │                          │──────────────────────
 ▾ bootstr│   3 │ union TokenKind {        │ ✦ Session resumed.
   lexer.o│   4 │   Keyword { name: Str }, │ KnowTree: 96 facts.
   parser.│   5 │   Ident { name: Str },   │
   semanti│   6 │   Number { value: Num }, │ ❯ fix boot closure
   codegen│   7 │   StringLit { value },   │
 ▾ homeos │   8 │   Symbol { ch: Str },    │ ✦ Analyzing...
   knowtre│   9 │   Eof,                   │ semantic.ol:1500
──────────│  10 │ }                        │ Dup+StoreReg shifts
 Makefile │  11 │                          │ jump offsets.
 PLAN.md  │  12 │ type Token {             │
          │  13 │   kind: TokenKind,       │ ❯ _
──────────┴────────────────────────────────┴──────────────────────
 ▸ TERMINAL ────────────────────────────────────────────────────
 $ make build && bash tests.sh
   ALL PASS: 91/91 tests passed
 $ _
──────────────────────────────────────────────────────────────────
 NORMAL │ Ln 5, Col 12 │ 369 lines │ lexer.ol │ Olang
```

### Colors (ANSI 256)

```
BG: 234  Surface: 235  Border: 237  Text: 252  Dim: 243  Muted: 238
Keyword: 141  String: 35  Number: 208  Comment: 243  Builtin: 45  Type: 220
Accent: 69  Green: 35  Orange: 208  Red: 196  Purple: 141  Cyan: 45
```

### Keybinds

```
NORMAL: h/j/k/l ←↓↑→  0/$ line start/end  gg/G file start/end
        i insert  a append  o new line below  x delete  dd delete line
        Ctrl-S save  Ctrl-Q quit  Ctrl-P file picker
        Ctrl-1/2/3 focus panels  Ctrl-` terminal  Ctrl-N cycle tabs
INSERT: type chars  Backspace  Enter  ESC→normal  Ctrl-S save
TERMINAL: keys→bash  Ctrl-`→unfocus
AI CHAT: type+Enter→send  ESC→unfocus
```

---

## UNIFIED P_w TABLE — KIẾN TRÚC CỐT LÕI

### Nguyên lý

```
Mỗi ký tự Unicode có 2 mặt:
  - Ngữ nghĩa: P_weight molecule [S:4][R:4][V:3][A:3][T:2]
  - Hình dạng: SDF (signed distance field)

Chúng KHÔNG PHẢI 2 thứ khác nhau.
  S (Shape) = tóm tắt 4-bit của SDF complexity
  R (Resonance) = symmetry trong SDF
  V (Valence) = bounding area trong SDF

→ 1 bảng duy nhất. 1 lookup. 1 nguồn sự thật.
```

### Binary format

```
P_w Unified Table:
  ┌─────────────────────────────────────────────┐
  │ INDEX: 65536 entries × 4 bytes = 256 KB     │
  │   [0..1] mol: u16 packed [S:4][R:4][V:3][A:3][T:2] │
  │   [2..3] sdf_offset: u16 (0 = no SDF data) │
  ├─────────────────────────────────────────────┤
  │ SDF DATA: variable length                   │
  │   96 ASCII glyphs × 32×32 × 1 byte = 96 KB │
  │   (or 48×48 = 216 KB for higher quality)    │
  │   Future: +200 Vietnamese diacritics        │
  └─────────────────────────────────────────────┘

  32×32 total: 256 + 96  = 352 KB
  48×48 total: 256 + 216 = 472 KB

  vs separate tables: 307 + 216 = 523 KB → saves 51 KB
```

### SDF data per glyph

```
Mỗi SDF cell (32×32 hoặc 48×48):
  Mỗi byte = signed distance (uint8):
    0   = deep inside glyph
    128 = on glyph boundary
    255 = far outside glyph
  Spread = ±4 pixels mapped to 0-255 range

Rendering pixel tại (x, y) cho glyph:
  u = (x - glyph_x) / glyph_w * cell_size
  v = (y - glyph_y) / glyph_h * cell_size
  d = sdf_data[glyph_offset + v * cell_size + u]
  alpha = smoothstep(124, 132, d)  // crisp edge
```

### Lookup flow

```olang
// 1 call, 2 kết quả:
fn pw_lookup(codepoint) {
    let idx = codepoint * 4;                     // index entry
    let mol = __pw_read_u16(idx);                // P_weight molecule
    let sdf_off = __pw_read_u16(idx + 2);       // SDF data offset
    return { mol: mol, sdf_offset: sdf_off };
}

// Compiler/encoder dùng mol:
let pw = pw_lookup(ch);
let shape = __mol_s(pw.mol);

// Renderer dùng sdf:
let pw = pw_lookup(ch);
if pw.sdf_offset > 0 {
    render_sdf_glyph(pw.sdf_offset, x, y);
};
```

### SDF derived from P_weight (auto-compute S,R,V)

```
Khi build SDF atlas từ TTF, ĐỒNG THỜI tính P_weight:

fn compute_pw_from_sdf(sdf_data, cell_size) {
    // S (Shape complexity) = number of zero-crossings / 4
    let crossings = count_zero_crossings(sdf_data);
    let S = min(crossings / 4, 15);

    // R (Resonance/symmetry) = correlation(left_half, flipped_right_half)
    let sym = measure_h_symmetry(sdf_data, cell_size);
    let R = floor(sym * 15);

    // V (Valence) = fraction of cells inside glyph
    let inside = count_below_128(sdf_data);
    let V = min(floor(inside / total * 7), 7);

    // A (Affinity) = edge density (perimeter/area ratio)
    let edge = count_near_128(sdf_data);
    let A = min(floor(edge / total * 7), 7);

    // T (Type) = 0:empty 1:punct 2:alpha 3:symbol
    let T = classify_glyph_type(codepoint);

    return __mol_pack(S, R, V, A, T);
}

// → P_weight KHÔNG CẦN hardcode nữa.
// → SDF sinh ra P_weight tự động.
// → Thêm font mới = chạy tool 1 lần, P_w tự tính.
```

---

## PHASES

```
PHASE 1-6:  O Editor v1 (TUI, ANSI terminal)     ← NGAY BÂY GIỜ
PHASE B:    Unified P_w table + TTF→SDF tool       ← song song
PHASE C-F:  O Editor v2 (SDF pixel renderer)       ← sau v1 ổn
```

### Phase 1: Process Syscalls — vm_x86_64.S (~7h)

```
T1.1  .equ SYS_POLL/PIPE/DUP2/FORK/EXECVE/WAIT4/KILL    TODO  5min
T1.2  __spawn(cmd) → [pid, stdin_fd, stdout_fd]           TODO  3h
T1.3  __pipe_read(fd) → string (non-blocking)             TODO  1h
T1.4  __pipe_write(fd, data) → n                          TODO  45min
T1.5  __poll_ready(fd, timeout_ms) → 0/1                  TODO  30min
T1.6  __process_alive(pid) → 0/1                          TODO  30min
T1.7  __process_kill(pid)                                  TODO  15min
T1.8  test/test_spawn.ol                                   TODO  30min
```

### Phase 2: Terminal Builtins — vm_x86_64.S (~3h)

```
T2.1  __term_raw() + __term_cooked()                      TODO  1h
T2.2  __read_byte() → f64 (-1 if no data)                TODO  30min
T2.3  __term_size() → push cols, push rows                TODO  30min
T2.4  test/test_terminal.ol                                TODO  30min
```

### Phase 3: Core TUI — stdlib/editor/*.ol (~8h)

```
T3.1  term.ol (ANSI, colors, key decode)                  TODO  2h
T3.2  buffer.ol (gap buffer, cursor, scroll)              TODO  3h
T3.3  render.ol (syntax HL, line render)                  TODO  3h
```

### Phase 4: Editor + Modal (~7h)

```
T4.1  Normal mode keybinds                                 TODO  2h
T4.2  Insert mode                                          TODO  2h
T4.3  File picker (Ctrl-P)                                 TODO  1h
T4.4  main.ol event loop (keyboard only)                  TODO  2h
```

### Phase 5: Process Panels (~8h)

```
T5.1  terminal.ol (spawn bash, pipe)                      TODO  3h
T5.2  chat.ol (spawn claude, pipe)                        TODO  3h
T5.3  Multi-fd poll event loop                             TODO  2h
```

### Phase 6: Integration (~7h)

```
T6.1  filetree.ol                                          TODO  2h
T6.2  knowtree_ui.ol + mcp_ui.ol                          TODO  2h
T6.3  panels.ol (layout, focus, resize)                   TODO  2h
T6.4  --editor flag + symlink "O"                         TODO  1h
```

### Phase B: Unified P_w + SDF (can run PARALLEL with Phase 3-6)

```
TB.1  TTF binary parser (Olang)                            TODO  4h
      tools/ttf2sdf.ol
      Parse: offset table, cmap, loca, glyf, head
      Extract: quadratic bezier contour points

TB.2  SDF generator (Olang)                                TODO  4h
      For each glyph: compute distance field
      distance_to_quadratic_bezier() — closed form
      winding_number() — inside/outside test
      Output: 32×32 or 48×48 uint8 per glyph

TB.3  Auto P_weight from SDF (Olang)                       TODO  2h
      S = zero-crossing count / 4
      R = horizontal symmetry measure
      V = inside-area fraction
      A = edge density
      T = codepoint class

TB.4  Unified table builder (Olang)                        TODO  2h
      tools/build_pw_unified.ol
      Input: font.ttf
      Output: pw_unified.bin
        [index: 65536×4 bytes][sdf_data: 96×32×32 bytes]
      P_weight auto-computed from SDF, NOT hardcoded

TB.5  Rust builder update                                  TODO  2h
      --pw flag → embed pw_unified.bin in binary
      Header v2: 64 bytes, pw_offset/pw_size fields
      Backward compat: old header still works

TB.6  VM builtins for table access                         TODO  1h
      __pw_mol(codepoint) → u16 molecule
      __pw_sdf(codepoint) → pointer to SDF data
      Read from mmap'd binary section (zero copy)

TB.7  Test + verify                                        TODO  1h
      Render glyph "A" SDF → verify distance values
      pw_lookup → mol matches expected S/R/V/A/T
      Round-trip: TTF → SDF → P_w → mol_pack → verify
```

**Phase B total: ~16h (2 sessions Nox, parallel with TUI work)**

### Phase C: Framebuffer Output — vm_x86_64.S

```
TC.1  __fb_open() → fd                                    TODO  2h
      open("/dev/fb0") or DRM fallback
      ioctl to get resolution, pixel format

TC.2  __fb_mmap() → pixel buffer pointer                  TODO  1h
      mmap framebuffer → direct pixel access

TC.3  __fb_flip() → flush/sync                            TODO  30min

TC.4  Test: fill screen solid color                        TODO  30min
```

### Phase D: SDF Renderer — ASM + Olang

```
TD.1  __sdf_render_row() ASM builtin (SSE2)               TODO  4h
      Input: scene objects, y coordinate, width, output buf
      4 pixels parallel with SSE2
      SDF eval + smoothstep + color blend → BGRA

TD.2  stdlib/editor/sdf/primitives.ol                     TODO  2h
      sdf_rounded_rect, sdf_circle, sdf_line
      sdf_union, sdf_subtract, sdf_smooth_union

TD.3  stdlib/editor/sdf/compositor.ol                     TODO  3h
      Scene graph → per-row object list
      Dirty region tracking

TD.4  stdlib/editor/sdf/text.ol                           TODO  2h
      Text layout → glyph positions → SDF samples from P_w

TD.5  stdlib/editor/sdf/lighting.ol                       TODO  2h
      Catmull-Rom spline light field
      SDF gradient → normal vector
      dot(normal, light) → diffuse shade
```

### Phase E: O Editor v2 (SDF mode)

```
TE.1  Replace ANSI render with SDF render                  TODO
TE.2  Detect: terminal → TUI, framebuffer → SDF           TODO
TE.3  Fallback: --tui flag forces TUI mode                TODO
```

### Phase F: Polish

```
TF.1  Soft shadows on panels                               TODO
TF.2  Cursor glow (SDF circle + radial)                   TODO
TF.3  Scroll inertia animation                             TODO
TF.4  Vietnamese diacritics SDF (+200 glyphs)             TODO
```

---

## FILE STRUCTURE

```
stdlib/editor/
  ├── term.ol           ~100  ANSI, colors, keys
  ├── buffer.ol         ~150  gap buffer, cursor
  ├── render.ol         ~200  syntax HL (TUI)
  ├── panels.ol         ~150  layout, focus
  ├── filetree.ol        ~80  file navigation
  ├── terminal.ol        ~80  bash spawn
  ├── chat.ol           ~100  claude spawn
  ├── knowtree_ui.ol     ~50  KT panel
  ├── mcp_ui.ol          ~50  MCP panel
  ├── main.ol           ~200  entry, event loop
  └── sdf/                    (Phase D-F)
      ├── primitives.ol  ~100
      ├── compositor.ol  ~150
      ├── text.ol        ~100
      └── lighting.ol    ~100

tools/
  ├── ttf2sdf.ol        ~400  TTF→SDF+P_w generator
  └── build_pw_unified.ol ~100  table builder
```

---

## BINARY LAYOUT (final)

```
origin.olang (<1MB):
  ┌──────────────────────────────────┐
  │ ELF header                       │
  │ VM code (x86_64 ASM)      ~80K  │
  ├──────────────────────────────────┤
  │ Origin Header v2           64B   │
  │   [0..31]  existing fields       │
  │   [32..35] pw_offset             │
  │   [36..39] pw_size               │
  │   [40..63] reserved              │
  ├──────────────────────────────────┤
  │ Bytecode (stdlib+editor)  ~400K  │
  ├──────────────────────────────────┤
  │ Knowledge (KnowTree)       ~7K  │
  ├──────────────────────────────────┤
  │ P_w Unified Table         ~352K  │
  │   Index: 65536×4B = 256K         │
  │   SDF: 96 glyphs×32×32 = 96K    │
  │   (P_weight auto-derived from    │
  │    SDF — NOT hardcoded)          │
  ├──────────────────────────────────┤
  │ Trailer (header_offset)     8B   │
  └──────────────────────────────────┘
  TOTAL: ~840K < 1MB

  Contains: VM + Compiler + Editor + Font + Knowledge +
            Encoder + MCP + KnowTree + REPL
  Needs: Linux kernel only. Nothing else.
```

---

## GHI NHỚ CHO NOX

```
 1. O Editor v1 = TUI. v2 = SDF pixel. Build v1 TRƯỚC.
 2. .jsx mockup = tham khảo layout, KHÔNG phải code.
 3. Unified P_w table: mol + SDF trong 1 bảng, 1 lookup.
 4. P_weight SINH TỪ SDF, không hardcode riêng.
 5. Phase B (P_w+SDF) chạy SONG SONG với Phase 3-6.
 6. __write_raw() cho TUI. __sdf_render_row() cho v2.
 7. __spawn("claude") cho AI chat. __spawn("bash") cho terminal.
 8. Event loop: __poll_ready() non-blocking trên nhiều fd.
 9. Binary <1MB chứa TẤT CẢ: code + font + knowledge.
10. Test trước push. Cập nhật file này mỗi session.
11. Dependency: Phase 1→2→3→4→5→6. Phase B song song.
12. Phase C→D→E→F chỉ sau khi v1 TUI hoạt động.
```

---

*File này là nguồn sự thật DUY NHẤT. Cập nhật mỗi session.*
