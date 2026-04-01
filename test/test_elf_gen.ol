// ═══ Test: Olang generates and runs its own ELF binary ═══
// No GNU as. No ld. No C. Pure Olang → ELF → Execute.

// ── inline helpers ──
fn elf_push(buf, b) { push(buf, b % 256); };
fn elf_push16(buf, v) { elf_push(buf, v % 256); elf_push(buf, __floor(v / 256) % 256); };
fn elf_push32(buf, v) {
    elf_push(buf, v % 256); elf_push(buf, __floor(v / 256) % 256);
    elf_push(buf, __floor(v / 65536) % 256); elf_push(buf, __floor(v / 16777216) % 256);
};
fn elf_push64(buf, v) { elf_push32(buf, v % 4294967296); elf_push32(buf, __floor(v / 4294967296)); };
fn w64(b, o, v) { __mem_write32(b, o, v % 4294967296); __mem_write32(b, o+4, __floor(v / 4294967296)); };

emit "=== Olang ELF Generator ===";

// First, generate the x86-64 code we want in the binary
let code = [];

// _start:
// Write "Nox\n" to stdout
// lea rsi, [rip + msg_offset]  — we'll compute this
// For simplicity: push bytes on stack, write from stack

// mov rbp, rsp (save stack)
push(code, 72); push(code, 137); push(code, 229);  // 48 89 e5

// Push "Nox\n" onto stack (reversed, 4 bytes)
// push 0x0a786f4e = '\n' 'x' 'o' 'N'
push(code, 104);  // 68 = push imm32
push(code, 78);   // 'N' = 0x4e
push(code, 111);  // 'o' = 0x6f
push(code, 120);  // 'x' = 0x78
push(code, 10);   // '\n' = 0x0a

// write(1, rsp, 4)
// mov rdi, 1
push(code, 72); push(code, 199); push(code, 199); push(code, 1);
push(code, 0); push(code, 0); push(code, 0);
// Actually: mov edi, 1 = bf 01 00 00 00
let code = [];  // reset — cleaner approach

// === Simpler: use direct bytes ===
// mov edx, 4          ; len = 4
push(code, 186); push(code, 4); push(code, 0); push(code, 0); push(code, 0);

// sub rsp, 8          ; make room on stack
push(code, 72); push(code, 131); push(code, 236); push(code, 8);

// mov dword [rsp], 0x0a786f4e  ; "Nox\n" (little-endian)
push(code, 199); push(code, 4); push(code, 36);  // c7 04 24 = mov dword [rsp], imm32
push(code, 78); push(code, 111); push(code, 120); push(code, 10);

// mov rsi, rsp        ; buf = stack
push(code, 72); push(code, 137); push(code, 230);  // 48 89 e6

// mov edi, 1          ; fd = stdout
push(code, 191); push(code, 1); push(code, 0); push(code, 0); push(code, 0);

// mov eax, 1          ; SYS_write
push(code, 184); push(code, 1); push(code, 0); push(code, 0); push(code, 0);

// syscall
push(code, 15); push(code, 5);

// --- Now compute fib(30) and print as exit code ---
// xor eax, eax        ; a = 0
push(code, 49); push(code, 192);
// mov ebx, 1          ; b = 1
push(code, 187); push(code, 1); push(code, 0); push(code, 0); push(code, 0);
// mov ecx, 30         ; counter
push(code, 185); push(code, 30); push(code, 0); push(code, 0); push(code, 0);

// loop:
let loop_off = len(code);
// mov edx, eax
push(code, 137); push(code, 194);
// add edx, ebx
push(code, 1); push(code, 218);
// mov eax, ebx
push(code, 137); push(code, 216);
// mov ebx, edx
push(code, 137); push(code, 211);
// dec ecx
push(code, 255); push(code, 201);
// jnz loop
let jnz_pos = len(code);
let rel = loop_off - (jnz_pos + 2);
push(code, 117); push(code, (rel + 256) % 256);

// ebx = fib(31). Use as exit code (mod 256)
// mov edi, ebx        ; exit code = fib result
push(code, 137); push(code, 223);  // 89 df
// mov eax, 231        ; SYS_exit_group
push(code, 184); push(code, 231); push(code, 0); push(code, 0); push(code, 0);
// syscall
push(code, 15); push(code, 5);

let code_size = len(code);
emit "Code: " + __to_string(code_size) + " bytes of x86-64";

// ═══ Build ELF ═══
let elf = [];
let load_addr = 4194304;  // 0x400000
let hdr_size = 120;  // 64 + 56
let entry = load_addr + hdr_size;
let file_size = hdr_size + code_size;

// ELF header (64 bytes)
// e_ident
elf_push(elf, 127); elf_push(elf, 69); elf_push(elf, 76); elf_push(elf, 70);  // .ELF
elf_push(elf, 2); elf_push(elf, 1); elf_push(elf, 1); elf_push(elf, 0);       // 64-bit, LE, v1, NONE
elf_push(elf, 0); elf_push(elf, 0); elf_push(elf, 0); elf_push(elf, 0);
elf_push(elf, 0); elf_push(elf, 0); elf_push(elf, 0); elf_push(elf, 0);
elf_push16(elf, 2);           // ET_EXEC
elf_push16(elf, 62);          // EM_X86_64
elf_push32(elf, 1);           // EV_CURRENT
elf_push64(elf, entry);       // e_entry
elf_push64(elf, 64);          // e_phoff
elf_push64(elf, 0);           // e_shoff
elf_push32(elf, 0);           // e_flags
elf_push16(elf, 64);          // e_ehsize
elf_push16(elf, 56);          // e_phentsize
elf_push16(elf, 1);           // e_phnum
elf_push16(elf, 64);          // e_shentsize
elf_push16(elf, 0);           // e_shnum
elf_push16(elf, 0);           // e_shstrndx

// Program header (56 bytes)
elf_push32(elf, 1);           // PT_LOAD
elf_push32(elf, 5);           // PF_R | PF_X
elf_push64(elf, 0);           // p_offset
elf_push64(elf, load_addr);   // p_vaddr
elf_push64(elf, load_addr);   // p_paddr
elf_push64(elf, file_size);   // p_filesz
elf_push64(elf, file_size);   // p_memsz
elf_push64(elf, 4096);        // p_align

emit "ELF header: " + __to_string(len(elf)) + " bytes (expect 120)";

// Append code
let ci = 0;
while ci < code_size {
    elf_push(elf, __array_get(code, ci));
    let ci = ci + 1;
};

emit "Total ELF: " + __to_string(len(elf)) + " bytes";

// ═══ Write to disk ═══
let elf_size = len(elf);
let tmp = __mmap(elf_size + 4096);
let wi = 0;
while wi < elf_size {
    __mem_write8(tmp, wi, __array_get(elf, wi));
    let wi = wi + 1;
};

// open + write + close
// Write using __file_append_bytes — writes raw bytes from mmap buffer
// But simpler: use __file_write which takes a string
// Problem: we need raw bytes, not string. Use __fd_open + syscall write with mmap buffer.
// __fd_open handles string→cstring conversion
let fd = __fd_open("/tmp/nox_born.elf", 577);  // O_WRONLY|O_CREAT|O_TRUNC
emit "fd=" + __to_string(fd);

if fd >= 0 {
    // write(fd, tmp_buffer, size)
    let wr = __syscall(1, fd, tmp, elf_size, 0, 0, 0);
    emit "wrote=" + __to_string(wr) + " bytes";
    __fd_close(fd);
};
__munmap(tmp, elf_size + 4096);

// Execute!
emit "--- Running Olang-born binary ---";
let output = __system("chmod +x /tmp/nox_born.elf && /tmp/nox_born.elf; echo \"exit=$?\"");
emit output;

emit "=== Olang wrote and ran its own ELF binary ===";
