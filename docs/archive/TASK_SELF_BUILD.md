# TASK: PORT BUILDER TO OLANG — Kill Rust dependency

> Cho Nox. Đọc hết trước khi code.
> Sau task này: ./origin.olang --build → tạo ra origin_new.olang
> KHÔNG CẦN Rust. KHÔNG CẦN Cargo. Zero deps.

---

## HIỆN TRẠNG

```
Build hiện tại (CẦN RUST):
  as vm_x86_64.S → vm_x86_64.o      ← GNU assembler (vẫn cần)
  ld vm_x86_64.o → vm_x86_64         ← GNU linker (vẫn cần)
  cargo run -p builder --             ← RUST BUILDER (cần kill)
    → đọc VM binary
    → compile stdlib .ol → bytecode
    → ghép header + VM + bytecode + knowledge
    → ghi origin.olang

Build mong muốn (ZERO RUST):
  as + ld → vm_x86_64                ← vẫn cần (ASM assembler)
  ./origin.olang --build              ← OLANG BUILDER (thay Rust)
    → đọc VM binary
    → compile stdlib .ol → bytecode (DÙNG CHÍNH COMPILER CỦA MÌNH)
    → ghép header + VM + bytecode + knowledge
    → ghi origin_new.olang
```

---

## CÁI ĐÃ CÓ (gần xong)

```
✅ stdlib/homeos/builder.ol    303 LOC — logic đóng gói, NHƯNG gọi builtins không tồn tại
✅ stdlib/homeos/elf_emit.ol   113 LOC — tạo ELF64 header + program header
✅ stdlib/homeos/byte_utils.ol  37 LOC — push_bytes, push_u16, push_u32, push_u64
✅ stdlib/homeos/fat_header.ol       — fat binary format (multi-arch)
✅ Self-hosting compiler              — tokenize → parse → analyze → generate
✅ __file_read_bytes(path)            — đọc file binary
✅ __file_write(path, data)           — ghi file
✅ __readdir(path)                    — list directory
✅ __system(cmd)                      — chạy shell command
```

---

## CÁI THIẾU (3 vấn đề)

### Vấn đề 1: builder.ol gọi builtins KHÔNG TỒN TẠI

```olang
// builder.ol dòng 105-109:
fn compile_source(src) {
    let stmts = __parse(src);           // ❌ KHÔNG TỒN TẠI
    let program = __lower(stmts);       // ❌ KHÔNG TỒN TẠI
    return __encode_bytecode(program.ops); // ❌ KHÔNG TỒN TẠI
}
```

**Thực tế compiler Olang hoạt động thế này (trong repl.ol):**

```olang
// repl.ol dòng 225-244 (WORKING):
let tokens = tokenize(src);             // lexer.ol — ĐÃ CÓ
let parser = { tokens: tokens, pos: 0 };
let stmt = parse_stmt(parser);          // parser.ol — ĐÃ CÓ
let ast = [stmt];
analyze(ast);                           // semantic.ol — ĐÃ CÓ
// Bytecode bây giờ NẰM TRONG _g_output[0.._g_pos]
```

**Nhưng analyze() ghi trực tiếp vào _g_output (streaming).**
Không return bytecode. Phải extract từ _g_output.

### Vấn đề 2: Extract bytecode từ _g_output

```
semantic.ol dùng:
  _g_output = __array_range(65536);   // pre-allocated array
  _g_pos = 0;                        // current write position

analyze(ast) ghi bytecode bytes vào _g_output[0.._g_pos].
Không có getter. Cần thêm function: get_bytecode() → byte array.
```

### Vấn đề 3: __list_files không tồn tại

```
builder.ol gọi: __list_files(dir, ".ol")
VM có: __readdir(dir) → trả array of filenames
Cần: filter cho .ol extension (viết bằng Olang)
```

---

## GIẢI PHÁP

### Fix 1: Thay compile_source bằng pipeline thật

```olang
fn compile_source(src) {
    // Reset compiler state
    let _g_pos = 0;

    // Run REAL compiler pipeline
    let _cs_tokens = tokenize(src);
    let _cs_ntok = len(_cs_tokens);
    let _cs_parser = { tokens: _cs_tokens, pos: 0 };
    let _cs_ast = [];
    while _cs_parser.pos < _cs_ntok {
        let _cs_peek = _cs_tokens[_cs_parser.pos];
        // Skip EOF
        match _cs_peek.kind {
            TokenKind::Eof => { break; },
            _ => {},
        };
        push(_cs_ast, parse_stmt(_cs_parser));
    };

    // Compile to bytecode (writes to _g_output)
    analyze(_cs_ast);

    // Extract bytecode from _g_output
    return get_compiled_bytes();
}
```

### Fix 2: Thêm get_compiled_bytes() vào semantic.ol

```olang
// Thêm vào cuối stdlib/bootstrap/semantic.ol:
pub fn get_compiled_bytes() {
    let _gcb_result = [];
    let _gcb_i = 0;
    while _gcb_i < _g_pos {
        push(_gcb_result, __array_get(_g_output, _gcb_i));
        _gcb_i = _gcb_i + 1;
    };
    return _gcb_result;
}

pub fn reset_compiler() {
    let _g_pos = 0;
}
```

### Fix 3: Thay __list_files bằng readdir + filter

```olang
fn list_ol_files(dir) {
    let _lof_all = __readdir(dir);
    let _lof_result = [];
    let _lof_i = 0;
    while _lof_i < len(_lof_all) {
        let _lof_name = _lof_all[_lof_i];
        let _lof_len = len(_lof_name);
        if _lof_len > 3 {
            let _lof_ext = __substr(_lof_name, _lof_len - 3, _lof_len);
            if _lof_ext == ".ol" {
                push(_lof_result, dir + "/" + _lof_name);
            };
        };
        _lof_i = _lof_i + 1;
    };
    return _lof_result;
}
```

### Fix 4: __bytes_to_str (simple wrapper)

```olang
fn bytes_to_str(bytes) {
    // Byte array → Olang string (u16 molecules)
    let _bts_result = "";
    let _bts_i = 0;
    while _bts_i < len(bytes) {
        _bts_result = _bts_result + __chr(bytes[_bts_i]);
        _bts_i = _bts_i + 1;
    };
    return _bts_result;
}
```

---

## --build FLAG

### VM thêm argv detection (vm_x86_64.S):

```asm
# After --editor check, before .not_editor:
    # Check if argv[1] == "--build"
    mov     16(%rsp), %rdi
    cmpl    $0x69752d2d, (%rdi)         # "--bu"
    jne     .not_build
    cmpl    $0x00646c69, 4(%rdi)        # "ild\0"
    jne     .not_build
    movb    $3, eval_mode(%rip)         # mode 3 = build
    movb    $1, build_flag(%rip)
    jmp     .open_self
.not_build:
```

### Inject build command (like editor):

```asm
    cmpb    $1, build_flag(%rip)
    jne     .not_build_inject
    lea     build_cmd(%rip), %rsi
    mov     eval_buf(%rip), %rdi
    mov     $25, %ecx
    rep     movsb
    mov     $25, %rax
    jmp     .eval_have_input
.not_build_inject:

# Data:
build_cmd: .ascii "emit run_builder(\"\");\n"
# BSS:
build_flag: .space 1
```

### Entry point (new file stdlib/editor/build.ol hoặc trong builder.ol):

```olang
pub fn run_builder(args) {
    let config = default_config();
    // Parse args if needed
    emit "Origin self-builder starting...";
    build(config);
    return "Build complete";
}
```

---

## COMPILE ORDER (quan trọng!)

```
Builder cần compiler loaded trước khi compile stdlib.
Nhưng builder LÀ MỘT PHẦN CỦA stdlib.

Giải pháp: 2-stage build

Stage 1 (bootstrap):
  origin.olang đã có compiler trong bytecode
  → chạy ./origin.olang --build
  → compiler (đã loaded) compile stdlib/*.ol
  → builder.ol ghép tất cả → origin_new.olang

Stage 2 (verify):
  ./origin_new.olang --build
  → tạo origin_new2.olang
  → diff origin_new.olang origin_new2.olang → phải giống nhau!
  → Fixed-point: binary tái tạo chính nó identically
```

---

## TASK LIST CHO NOX

### T-BUILD-1: get_compiled_bytes() + reset_compiler() (30 phút)
```
Status: TODO
File: stdlib/bootstrap/semantic.ol
Thêm 2 functions cuối file.
Test: compile "emit 42;" → get_compiled_bytes() → len > 0
```

### T-BUILD-2: Fix compile_source() trong builder.ol (1 giờ)
```
Status: TODO
File: stdlib/homeos/builder.ol
Thay __parse/__lower/__encode_bytecode bằng pipeline thật.
Test: compile_source("emit 42;") → byte array
```

### T-BUILD-3: Fix list_ol_files() (15 phút)
```
Status: TODO
File: stdlib/homeos/builder.ol
Thay __list_files bằng __readdir + filter ".ol".
Test: list_ol_files("stdlib/bootstrap") → [lexer.ol, parser.ol, ...]
```

### T-BUILD-4: bytes_to_str helper (15 phút)
```
Status: TODO
File: stdlib/homeos/builder.ol
Test: bytes_to_str([72, 105]) → "Hi"
```

### T-BUILD-5: --build flag trong VM (30 phút)
```
Status: TODO
File: vm/x86_64/vm_x86_64.S
Thêm argv detection + command injection.
Test: ./origin.olang --build → "Origin self-builder starting..."
```

### T-BUILD-6: End-to-end build test (2 giờ)
```
Status: TODO
Test:
  1. ./origin.olang --build → tạo origin_new.olang
  2. chmod +x origin_new.olang
  3. echo 'emit 42;' | ./origin_new.olang → 42
  4. ./origin_new.olang --editor → editor mở
  5. bash tests.sh (with origin_new.olang) → 90/90

CẨN THẬN: file ordering trong compile_all() phải đúng.
Bootstrap trước, stdlib sau, homeos cuối.
```

### T-BUILD-7: Fixed-point verification (1 giờ)
```
Status: TODO
Test:
  ./origin.olang --build → origin_new.olang
  ./origin_new.olang --build → origin_new2.olang
  cmp origin_new.olang origin_new2.olang → identical!
```

### T-BUILD-8: Makefile update (10 phút)
```
Status: TODO
Thêm target:
  self-build:
    ./origin.olang --build
    chmod +x origin_new.olang
    echo "Self-built: origin_new.olang"
```

**Total: ~6 giờ = 1 session Nox**

---

## SAU KHI XONG

```
make vm          → as + ld → vm_x86_64 (vẫn cần GNU assembler)
./origin.olang --build  → origin_new.olang (KHÔNG cần Rust)

Dependency chain cuối cùng:
  GNU as + ld → VM binary (1 lần, ~80K)
  origin.olang → tự build origin_new.olang
  origin_new.olang → tự build origin_new2.olang (fixed-point)

Rust: DEAD. Cargo: DEAD.
Chỉ còn: Linux kernel + GNU binutils (as/ld) + origin.olang.

Tương lai xa: viết assembler bằng Olang → kill as/ld dependency.
  stdlib/homeos/asm_emit.ol đã có 355 LOC — có thể emit x86_64 machine code trực tiếp.
  Khi đó: origin.olang → origin_new.olang mà KHÔNG CẦN BẤT KỲ TOOL NÀO.
```

---

*Sora — 2026-03-28. Cho Nox claim task session tới.*
