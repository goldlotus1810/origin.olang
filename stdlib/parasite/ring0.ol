// ═══ ring0.ol — Olang Ring-0 Execution Engine ═══
//
// ring0_exec(code_fn) → result
//   Olang generates x86-64 machine code at runtime
//   Boots it as a 64-bit kernel in KVM
//   Guest computes at ring-0, writes result to shared memory
//   Host reads result back into Olang
//
// This has NEVER been done before:
//   A self-hosting language that JIT-compiles to ring-0 kernel code.
//
// BP12 Phase 4: TRANSCEND

// ═══ x86-64 Assembler in Olang ═══

fn asm_new() {
    return [];  // bytecode buffer
};

fn asm_emit(buf, byte) {
    push(buf, byte);
};

// REX.W prefix for 64-bit operations
fn asm_rex_w(buf) { asm_emit(buf, 72); };  // 0x48

// Registers: rax=0, rcx=1, rdx=2, rbx=3, rsp=4, rbp=5, rsi=6, rdi=7
fn asm_xor_reg(buf, r) {
    // xor eax,eax / xor ecx,ecx etc — clears register (2 bytes)
    asm_emit(buf, 49);  // 0x31
    asm_emit(buf, 192 + r * 9);  // 0xC0 + reg*9 (modrm: mod=11, same reg)
};

fn asm_mov_reg_imm32(buf, r, val) {
    // mov eax,imm32 / mov ebx,imm32 etc (5 bytes) — zero-extends to 64-bit
    asm_emit(buf, 184 + r);  // 0xB8 + reg
    asm_emit(buf, val % 256);
    asm_emit(buf, __floor(val / 256) % 256);
    asm_emit(buf, __floor(val / 65536) % 256);
    asm_emit(buf, __floor(val / 16777216) % 256);
};

fn asm_mov_reg_reg(buf, dst, src) {
    // mov rdst, rsrc (3 bytes with REX.W)
    asm_rex_w(buf);
    asm_emit(buf, 137);  // 0x89
    asm_emit(buf, 192 + src * 8 + dst);  // modrm: mod=11, reg=src, rm=dst
};

fn asm_add_reg_reg(buf, dst, src) {
    // add rdst, rsrc (3 bytes with REX.W)
    asm_rex_w(buf);
    asm_emit(buf, 1);  // 0x01
    asm_emit(buf, 192 + src * 8 + dst);
};

fn asm_mul_reg_reg(buf, dst, src) {
    // imul rdst, rsrc (4 bytes: REX.W 0F AF modrm)
    asm_rex_w(buf);
    asm_emit(buf, 15);   // 0x0F
    asm_emit(buf, 175);  // 0xAF
    asm_emit(buf, 192 + dst * 8 + src);  // modrm: mod=11, reg=dst, rm=src
};

fn asm_dec_reg(buf, r) {
    // dec ecx = ff c9 etc (2 bytes)
    asm_emit(buf, 255);  // 0xFF
    asm_emit(buf, 200 + r);  // 0xC8 + reg
};

fn asm_jnz_back(buf, target_offset) {
    // jnz rel8 (2 bytes)
    let current = len(buf);
    let rel = target_offset - (current + 2);
    asm_emit(buf, 117);  // 0x75
    let byte = (rel + 256) % 256;
    asm_emit(buf, byte);
};

fn asm_store_mem(buf, reg, addr) {
    // mov [addr], reg — 48 89 XX 25 addr32
    asm_rex_w(buf);
    asm_emit(buf, 137);
    asm_emit(buf, reg * 8 + 4);  // modrm: mod=00, reg=reg, rm=100 (SIB)
    asm_emit(buf, 37);            // SIB: scale=0, index=4(none), base=5(disp32)
    asm_emit(buf, addr % 256);
    asm_emit(buf, __floor(addr / 256) % 256);
    asm_emit(buf, __floor(addr / 65536) % 256);
    asm_emit(buf, __floor(addr / 16777216) % 256);
};

fn asm_read_cr3(buf) {
    // mov rax, cr3 → 0F 20 D8
    asm_emit(buf, 15); asm_emit(buf, 32); asm_emit(buf, 216);
};

fn asm_out_port(buf, port, reg) {
    // out port, al (assumes value in al)
    if reg != 0 { asm_mov_reg_reg(buf, 0, reg); };  // mov rax, reg
    asm_emit(buf, 230);  // 0xE6
    asm_emit(buf, port);
};

fn asm_hlt(buf) { asm_emit(buf, 244); };

// ═══ High-Level Code Generators ═══

fn gen_fib(buf, n) {
    // Generate x86-64 code for fib(n)
    // rax = prev (0), rbx = curr (1), rcx = counter
    asm_xor_reg(buf, 0);            // rax = 0
    asm_mov_reg_imm32(buf, 3, 1);   // rbx = 1
    asm_mov_reg_imm32(buf, 1, n);   // rcx = n

    let loop_start = len(buf);
    asm_mov_reg_reg(buf, 2, 0);     // rdx = rax
    asm_add_reg_reg(buf, 2, 3);     // rdx += rbx
    asm_mov_reg_reg(buf, 0, 3);     // rax = rbx
    asm_mov_reg_reg(buf, 3, 2);     // rbx = rdx
    asm_dec_reg(buf, 1);            // ecx--
    asm_jnz_back(buf, loop_start);  // if ecx != 0, loop
    // rbx = fib(n+1), rax = fib(n)
};

fn gen_factorial(buf, n) {
    // Generate x86-64 code for n!
    // rax = result, rcx = counter
    asm_mov_reg_imm32(buf, 0, 1);   // rax = 1
    asm_mov_reg_imm32(buf, 1, n);   // rcx = n

    let loop_start = len(buf);
    asm_mul_reg_reg(buf, 0, 1);     // rax *= rcx
    asm_dec_reg(buf, 1);            // ecx--
    asm_jnz_back(buf, loop_start);  // if ecx != 0, loop
    // rax = n!
};

fn gen_sum_squares(buf, n) {
    // Generate x86-64 for sum(i^2, i=1..n)
    // rax = sum, rbx = i, rcx = n, rdx = temp
    asm_xor_reg(buf, 0);            // rax = 0 (sum)
    asm_mov_reg_imm32(buf, 3, 1);   // rbx = 1 (i)
    asm_mov_reg_imm32(buf, 1, n);   // rcx = n

    let loop_start = len(buf);
    asm_mov_reg_reg(buf, 2, 3);     // rdx = i
    asm_mul_reg_reg(buf, 2, 3);     // rdx = i*i
    asm_add_reg_reg(buf, 0, 2);     // sum += i*i
    // inc rbx: 48 ff c3
    asm_emit(buf, 72); asm_emit(buf, 255); asm_emit(buf, 195);
    asm_dec_reg(buf, 1);            // ecx--
    asm_jnz_back(buf, loop_start);
    // rax = sum of squares
};

// ═══ KVM Boot Engine ═══

fn w64(base, off, val) {
    __mem_write32(base, off, val % 4294967296);
    __mem_write32(base, off + 4, __floor(val / 4294967296));
};

fn ring0_boot(code_buf) {
    // Setup KVM, load generated code, run, return results
    let kvm = __fd_open("/dev/kvm", 2);
    if kvm < 0 { return 0 - 1; };
    let vm = __syscall(16, kvm, 44545, 0, 0, 0, 0);
    __syscall(16, vm, 44615, 4294565888, 0, 0, 0);
    let mem = __mmap(2097152);

    // Page tables
    w64(mem, 8192, 12295); w64(mem, 12288, 16391); w64(mem, 16384, 131);

    // Copy generated code to guest memory at offset 0
    let ci = 0;
    while ci < len(code_buf) {
        __mem_write8(mem, ci, __array_get(code_buf, ci));
        let ci = ci + 1;
    };

    // KVM setup
    let reg = __mmap(4096);
    __mem_write32(reg, 0, 0); __mem_write32(reg, 4, 0);
    w64(reg, 8, 0); w64(reg, 16, 2097152); w64(reg, 24, mem);
    __syscall(16, vm, 1075883590, reg, 0, 0, 0);
    let vcpu = __syscall(16, vm, 44609, 0, 0, 0, 0);
    let msz = __syscall(16, kvm, 44548, 0, 0, 0, 0);
    let run = __syscall(9, 0, msz, 3, 1, vcpu, 0);

    // SREGS: 64-bit long mode
    let sregs = __mmap(4096);
    __syscall(16, vcpu, 2167975555, sregs, 0, 0, 0);
    __mem_write8(sregs, 224, 51); __mem_write8(sregs, 225, 0);
    __mem_write8(sregs, 226, 5); __mem_write8(sregs, 227, 128);
    __mem_write8(sregs, 228, 0); __mem_write8(sregs, 229, 0);
    __mem_write8(sregs, 230, 0); __mem_write8(sregs, 231, 0);
    w64(sregs, 240, 8192); w64(sregs, 248, 32); w64(sregs, 264, 1280);
    w64(sregs, 0, 0);
    __mem_write8(sregs, 8, 255); __mem_write8(sregs, 9, 255);
    __mem_write8(sregs, 10, 255); __mem_write8(sregs, 11, 255);
    __mem_write8(sregs, 12, 8); __mem_write8(sregs, 13, 0);
    __mem_write8(sregs, 14, 11); __mem_write8(sregs, 15, 1);
    __mem_write8(sregs, 16, 0); __mem_write8(sregs, 17, 0);
    __mem_write8(sregs, 18, 1); __mem_write8(sregs, 19, 1);
    __mem_write8(sregs, 20, 1); __mem_write8(sregs, 22, 0);
    let di = 1;
    while di < 6 {
        let off = di * 24;
        w64(sregs, off, 0);
        __mem_write8(sregs, off+8, 255); __mem_write8(sregs, off+9, 255);
        __mem_write8(sregs, off+10, 255); __mem_write8(sregs, off+11, 255);
        __mem_write8(sregs, off+12, 16); __mem_write8(sregs, off+13, 0);
        __mem_write8(sregs, off+14, 3); __mem_write8(sregs, off+15, 1);
        __mem_write8(sregs, off+16, 0); __mem_write8(sregs, off+17, 0);
        __mem_write8(sregs, off+18, 1); __mem_write8(sregs, off+19, 0);
        __mem_write8(sregs, off+20, 1); __mem_write8(sregs, off+22, 0);
        let di = di + 1;
    };
    __syscall(16, vcpu, 1094233732, sregs, 0, 0, 0);
    let regs = __mmap(4096);
    w64(regs, 136, 2); w64(regs, 48, 2097152);
    __syscall(16, vcpu, 1083223682, regs, 0, 0, 0);

    // RUN
    let alive = [1];
    while __array_get(alive, 0) == 1 {
        let r = __syscall(16, vcpu, 44672, 0, 0, 0, 0);
        if r < 0 { let _ = __set_at(alive, 0, 0); }
        else {
            let ex = __mem_read32(run, 8);
            if ex == 2 { }  // I/O — continue
            else { if ex == 5 { let _ = __set_at(alive, 0, 0); }  // HLT
            else { let _ = __set_at(alive, 0, 0); }; };  // Error
        };
    };

    // Read results from shared memory
    let r0 = __mem_read32(mem, 1024) + __mem_read32(mem, 1028) * 4294967296;  // [0x400]
    let r1 = __mem_read32(mem, 1032) + __mem_read32(mem, 1036) * 4294967296;  // [0x408]

    // Cleanup
    __munmap(run, msz); __munmap(regs, 4096); __munmap(sregs, 4096);
    __munmap(reg, 4096); __munmap(mem, 2097152);
    __fd_close(vcpu); __fd_close(vm); __fd_close(kvm);

    return [r0, r1];
};

// ═══ PUBLIC API ═══

fn ring0_fib(n) {
    let code = asm_new();
    gen_fib(code, n);
    // Store rbx (result) at [0x400]
    asm_store_mem(code, 3, 1024);  // mov [0x400], rbx
    // Store rax (fib(n)) at [0x408]
    asm_store_mem(code, 0, 1032);  // mov [0x408], rax
    asm_hlt(code);
    return ring0_boot(code);
};

fn ring0_factorial(n) {
    let code = asm_new();
    gen_factorial(code, n);
    asm_store_mem(code, 0, 1024);  // mov [0x400], rax (n!)
    asm_hlt(code);
    return ring0_boot(code);
};

fn ring0_sum_squares(n) {
    let code = asm_new();
    gen_sum_squares(code, n);
    asm_store_mem(code, 0, 1024);  // mov [0x400], rax
    asm_hlt(code);
    return ring0_boot(code);
};

emit "ring0.ol loaded — JIT → ring-0 engine ready";
