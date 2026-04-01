// ═══ elf_writer.ol — Olang writes its own ELF binaries ═══
//
// Olang generates x86-64 machine code → wraps in ELF → writes to disk → executable
// No GNU as. No ld. No C. Pure Olang.
//
// ELF64 format: header(64) + program_header(56) + code
// Static, no libc, entry = _start

fn elf_new() {
    return [];  // byte buffer
};

fn elf_push(buf, byte) {
    push(buf, byte % 256);
};

fn elf_push16(buf, val) {
    elf_push(buf, val % 256);
    elf_push(buf, __floor(val / 256) % 256);
};

fn elf_push32(buf, val) {
    elf_push(buf, val % 256);
    elf_push(buf, __floor(val / 256) % 256);
    elf_push(buf, __floor(val / 65536) % 256);
    elf_push(buf, __floor(val / 16777216) % 256);
};

fn elf_push64(buf, val) {
    elf_push32(buf, val % 4294967296);
    elf_push32(buf, __floor(val / 4294967296));
};

// ═══ ELF64 Header (64 bytes) ═══
fn elf_write_header(buf, entry_offset, code_size) {
    let load_addr = 4194304;  // 0x400000 — standard load address
    let header_size = 64 + 56;  // ELF header + 1 program header
    let entry = load_addr + header_size;
    let file_size = header_size + code_size;

    // e_ident[16]: magic + class + data + version + OS/ABI
    elf_push(buf, 127);  // 0x7F
    elf_push(buf, 69);   // 'E'
    elf_push(buf, 76);   // 'L'
    elf_push(buf, 70);   // 'F'
    elf_push(buf, 2);    // ELFCLASS64
    elf_push(buf, 1);    // ELFDATA2LSB (little-endian)
    elf_push(buf, 1);    // EV_CURRENT
    elf_push(buf, 0);    // ELFOSABI_NONE
    // padding 8 bytes
    elf_push(buf, 0); elf_push(buf, 0); elf_push(buf, 0); elf_push(buf, 0);
    elf_push(buf, 0); elf_push(buf, 0); elf_push(buf, 0); elf_push(buf, 0);

    elf_push16(buf, 2);          // e_type = ET_EXEC
    elf_push16(buf, 62);         // e_machine = EM_X86_64
    elf_push32(buf, 1);          // e_version = EV_CURRENT
    elf_push64(buf, entry);      // e_entry = load_addr + headers
    elf_push64(buf, 64);         // e_phoff = 64 (right after ELF header)
    elf_push64(buf, 0);          // e_shoff = 0 (no section headers)
    elf_push32(buf, 0);          // e_flags
    elf_push16(buf, 64);         // e_ehsize = 64
    elf_push16(buf, 56);         // e_phentsize = 56
    elf_push16(buf, 1);          // e_phnum = 1
    elf_push16(buf, 64);         // e_shentsize = 64
    elf_push16(buf, 0);          // e_shnum = 0
    elf_push16(buf, 0);          // e_shstrndx = 0

    // ═══ Program Header (56 bytes) ═══
    // PT_LOAD: load entire file into memory
    elf_push32(buf, 1);              // p_type = PT_LOAD
    elf_push32(buf, 5);              // p_flags = PF_R | PF_X (read + execute)
    elf_push64(buf, 0);              // p_offset = 0 (from start of file)
    elf_push64(buf, load_addr);      // p_vaddr = 0x400000
    elf_push64(buf, load_addr);      // p_paddr = 0x400000
    elf_push64(buf, file_size);      // p_filesz
    elf_push64(buf, file_size);      // p_memsz
    elf_push64(buf, 4096);           // p_align = 0x1000

    return entry;
};

// ═══ Syscall helpers for guest code ═══

fn elf_gen_syscall_exit(buf, code) {
    // mov edi, code; mov eax, 231; syscall
    // exit_group(code)
    elf_push(buf, 191);  // bf = mov edi, imm32
    elf_push32(buf, code);
    elf_push(buf, 184);  // b8 = mov eax, imm32
    elf_push32(buf, 231); // SYS_exit_group
    elf_push(buf, 15); elf_push(buf, 5);  // syscall
};

fn elf_gen_write_stdout(buf) {
    // write(1, rsi, rdx) — assumes rsi=buf, rdx=len already set
    // mov edi, 1; mov eax, 1; syscall
    elf_push(buf, 191);  // mov edi, imm32
    elf_push32(buf, 1);   // fd = stdout
    elf_push(buf, 184);  // mov eax, imm32
    elf_push32(buf, 1);   // SYS_write
    elf_push(buf, 15); elf_push(buf, 5);  // syscall
};

// ═══ Write ELF to disk ═══
fn elf_write_file(buf, path) {
    // Convert array of bytes to file
    // Use __file_write but need to build byte string
    // Simpler: write via __fd_open + __syscall(write)
    let fd = __fd_open(path, 577);  // O_WRONLY|O_CREAT|O_TRUNC = 0x241
    if fd < 0 { return fd; };

    // Write bytes via mmap buffer
    let size = len(buf);
    let tmp = __mmap(size + 4096);
    let bi = 0;
    while bi < size {
        __mem_write8(tmp, bi, __array_get(buf, bi));
        let bi = bi + 1;
    };

    // write(fd, tmp, size)
    __syscall(1, fd, tmp, size, 0, 0, 0);
    __fd_close(fd);
    __munmap(tmp, size + 4096);

    // chmod +x
    __syscall(90, path, 493, 0, 0, 0, 0);  // fchmod... actually need chmod

    return 0;
};

emit "elf_writer.ol loaded — Olang writes ELF binaries";
