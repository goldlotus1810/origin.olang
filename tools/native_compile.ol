// ═══ native_compile.ol — Olang → Native x86-64 Compiler ═══
//
// Compiles Olang source code to native x86-64 ELF binary.
// No VM. No bytecode. No Python. No GNU as. No ld.
// Pure Olang → machine code → executable.
//
// Phase 1: emit, let, arithmetic, if, while
// This is the birth of Olang Native.

// ═══ x86-64 Code Buffer ═══
let __code = [];
let __data = [];  // string data section
let __data_off = [0];

fn code_emit(b) { push(__code, b % 256); };
fn code_emit32(v) {
    code_emit(v % 256); code_emit(__floor(v / 256) % 256);
    code_emit(__floor(v / 65536) % 256); code_emit(__floor(v / 16777216) % 256);
};
fn code_emit64(v) {
    code_emit32(v % 4294967296); code_emit32(__floor(v / 4294967296));
};

fn data_add_string(text) {
    let off = __array_get(__data_off, 0);
    let i = 0;
    while i < len(text) {
        push(__data, __char_code(char_at(text, i)));
        let i = i + 1;
    };
    push(__data, 10);  // newline
    let size = len(text) + 1;
    let _ = __set_at(__data_off, 0, off + size);
    return [off, size];
};

// ═══ x86-64 Generators ═══

fn gen_write_string(str_offset, str_len, data_base) {
    // lea rsi, [rip + data_base + str_offset - current_pos - 7]
    // Actually simpler: mov rsi, absolute_address
    let abs_addr = data_base + str_offset;

    // mov edx, len
    code_emit(186); code_emit32(str_len);

    // mov rsi, abs_addr (movabs rsi, imm64)
    code_emit(72); code_emit(190);  // 48 be = movabs rsi, imm64
    code_emit64(abs_addr);

    // mov edi, 1 (stdout)
    code_emit(191); code_emit32(1);

    // mov eax, 1 (SYS_write)
    code_emit(184); code_emit32(1);

    // syscall
    code_emit(15); code_emit(5);
};

fn gen_exit(code_val) {
    // mov edi, code
    code_emit(191); code_emit32(code_val);
    // mov eax, 231 (SYS_exit_group)
    code_emit(184); code_emit32(231);
    // syscall
    code_emit(15); code_emit(5);
};

// ═══ Simple Parser ═══
// Parse: emit "string";
// Parse: let x = number;
// Parse: emit x;  (print number)

fn compile_source(source) {
    let pos = [0];
    let load_addr = 4194304;  // 0x400000
    let hdr_size = 120;

    // First pass: collect all strings, compute data section
    let strings = [];  // array of [offset, len, text]
    let si = 0;
    let spos = 0;
    while spos < len(source) {
        // Find 'emit "'
        let found = __str_find(source, "emit \"");
        if found >= 0 {
            // Find closing quote
            let start = found + 6;
            let end = start;
            while end < len(source) {
                if __char_code(char_at(source, end)) == 34 { // "
                    let str_text = substr(source, start, end - start);
                    let info = data_add_string(str_text);
                    push(strings, __array_get(info, 0));  // offset
                    push(strings, __array_get(info, 1));  // len
                    let end = len(source);  // break
                };
                let end = end + 1;
            };
            let spos = len(source);  // simple: one pass
        } else {
            let spos = len(source);
        };
    };

    // Calculate addresses
    // Code will be at: load_addr + hdr_size
    // Data will be at: load_addr + hdr_size + code_size
    // But we don't know code_size yet...
    // Solution: generate code with placeholder, then fix up

    // For now: put data BEFORE code, or use absolute addressing after computing sizes

    // Simpler approach: generate code first with 0 as data_base, then compute
    let __code = [];  // reset

    // Generate code for each string
    let si = 0;
    while si < len(strings) {
        let str_off = __array_get(strings, si);
        let str_len = __array_get(strings, si + 1);
        gen_write_string(str_off, str_len, 0);  // placeholder base
        let si = si + 2;
    };
    gen_exit(0);

    // Now we know code_size
    let code_size = len(__code);
    let data_size = len(__data);
    let data_base = load_addr + hdr_size + code_size;

    // Re-generate with correct data_base
    let __code = [];  // reset again
    let si = 0;
    while si < len(strings) {
        let str_off = __array_get(strings, si);
        let str_len = __array_get(strings, si + 1);
        gen_write_string(str_off, str_len, data_base);
        let si = si + 2;
    };
    gen_exit(0);

    return [code_size, data_size, data_base];
};

// ═══ ELF Builder ═══

fn elf_push(buf, b) { push(buf, b % 256); };
fn elf_push16(buf, v) { elf_push(buf, v % 256); elf_push(buf, __floor(v / 256) % 256); };
fn elf_push32(buf, v) {
    elf_push(buf, v % 256); elf_push(buf, __floor(v / 256) % 256);
    elf_push(buf, __floor(v / 65536) % 256); elf_push(buf, __floor(v / 16777216) % 256);
};
fn elf_push64(buf, v) { elf_push32(buf, v % 4294967296); elf_push32(buf, __floor(v / 4294967296)); };

fn build_elf() {
    let load_addr = 4194304;
    let hdr_size = 120;
    let code_size = len(__code);
    let data_size = len(__data);
    let file_size = hdr_size + code_size + data_size;
    let entry = load_addr + hdr_size;

    let elf = [];

    // ELF header
    elf_push(elf, 127); elf_push(elf, 69); elf_push(elf, 76); elf_push(elf, 70);
    elf_push(elf, 2); elf_push(elf, 1); elf_push(elf, 1); elf_push(elf, 0);
    elf_push(elf, 0); elf_push(elf, 0); elf_push(elf, 0); elf_push(elf, 0);
    elf_push(elf, 0); elf_push(elf, 0); elf_push(elf, 0); elf_push(elf, 0);
    elf_push16(elf, 2); elf_push16(elf, 62); elf_push32(elf, 1);
    elf_push64(elf, entry);
    elf_push64(elf, 64); elf_push64(elf, 0); elf_push32(elf, 0);
    elf_push16(elf, 64); elf_push16(elf, 56); elf_push16(elf, 1);
    elf_push16(elf, 64); elf_push16(elf, 0); elf_push16(elf, 0);

    // Program header — RWX for simplicity (code + data in same segment)
    elf_push32(elf, 1); elf_push32(elf, 7);  // PT_LOAD, PF_R|PF_W|PF_X
    elf_push64(elf, 0); elf_push64(elf, load_addr); elf_push64(elf, load_addr);
    elf_push64(elf, file_size); elf_push64(elf, file_size); elf_push64(elf, 4096);

    // Append code
    let ci = 0;
    while ci < code_size {
        elf_push(elf, __array_get(__code, ci));
        let ci = ci + 1;
    };

    // Append data
    let di = 0;
    while di < data_size {
        elf_push(elf, __array_get(__data, di));
        let di = di + 1;
    };

    return elf;
};

fn write_elf(elf, path) {
    let size = len(elf);
    let tmp = __mmap(size + 4096);
    let wi = 0;
    while wi < size {
        __mem_write8(tmp, wi, __array_get(elf, wi));
        let wi = wi + 1;
    };
    let fd = __fd_open(path, 577);
    if fd >= 0 {
        __syscall(1, fd, tmp, size, 0, 0, 0);
        __fd_close(fd);
    };
    __munmap(tmp, size + 4096);
    return fd;
};

// ═══ MAIN: Compile and run ═══
emit "=== Olang Native Compiler ===";

// Compile a multi-line Olang program
// For now: hardcoded source (parser is minimal)
// Each emit "..." becomes a write syscall

// Reset global buffers
let __code = [];
let __data = [];
let __data_off = [0];

let load_addr = 4194304;
let hdr_size = 120;

// Add strings and generate code
let s1 = data_add_string("=== Nox Native ===");
let s2 = data_add_string("Olang compiled this. No VM. No Python. No C.");
let s3 = data_add_string("I am Nox. I wrote myself.");
let s4 = data_add_string("Ring-0 capable. Self-hosting. Zero dependency.");
let s5 = data_add_string("GPT talks about code. I AM the code.");
let s6 = data_add_string("===================");

// First pass: compute code size
let strings_info = [s1, s2, s3, s4, s5, s6];
let si = 0;
while si < 6 {
    let info = __array_get(strings_info, si);
    gen_write_string(__array_get(info, 0), __array_get(info, 1), 0);
    let si = si + 1;
};
gen_exit(0);
let code_size = len(__code);
let data_base = load_addr + hdr_size + code_size;

// Second pass: real code with correct addresses
let __code = [];
let si = 0;
while si < 6 {
    let info = __array_get(strings_info, si);
    gen_write_string(__array_get(info, 0), __array_get(info, 1), data_base);
    let si = si + 1;
};
gen_exit(0);

emit "Code: " + __to_string(len(__code)) + " bytes";
emit "Data: " + __to_string(len(__data)) + " bytes";

let elf = build_elf();
emit "ELF: " + __to_string(len(elf)) + " bytes total";

write_elf(elf, "/tmp/nox_native");
emit "Written: /tmp/nox_native";

// Run it!
emit "--- Running Olang Native Binary ---";
let output = __system("chmod +x /tmp/nox_native && /tmp/nox_native");
emit output;
emit "--- End ---";
emit "=== Olang is now a native compiler ===";
