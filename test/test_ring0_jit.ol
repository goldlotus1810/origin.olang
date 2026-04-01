// ═══ Test: Olang JIT → Ring-0 Computation ═══
// First ever: self-hosting language generates x86-64 at runtime
// and boots it as a kernel. No one has done this before.

// ── inline ring0.ol (Olang has no include) ──
fn asm_new() { return []; };
fn asm_emit(buf, byte) { push(buf, byte); };
fn asm_rex_w(buf) { asm_emit(buf, 72); };
fn asm_xor_reg(buf, r) { asm_emit(buf, 49); asm_emit(buf, 192 + r * 9); };
fn asm_mov_reg_imm32(buf, r, val) {
    asm_emit(buf, 184 + r);
    asm_emit(buf, val % 256);
    asm_emit(buf, __floor(val / 256) % 256);
    asm_emit(buf, __floor(val / 65536) % 256);
    asm_emit(buf, __floor(val / 16777216) % 256);
};
fn asm_mov_reg_reg(buf, dst, src) {
    asm_rex_w(buf); asm_emit(buf, 137); asm_emit(buf, 192 + src * 8 + dst);
};
fn asm_add_reg_reg(buf, dst, src) {
    asm_rex_w(buf); asm_emit(buf, 1); asm_emit(buf, 192 + src * 8 + dst);
};
fn asm_mul_reg_reg(buf, dst, src) {
    asm_rex_w(buf); asm_emit(buf, 15); asm_emit(buf, 175); asm_emit(buf, 192 + dst * 8 + src);
};
fn asm_dec_reg(buf, r) { asm_emit(buf, 255); asm_emit(buf, 200 + r); };
fn asm_jnz_back(buf, target) {
    let rel = target - (len(buf) + 2);
    asm_emit(buf, 117); asm_emit(buf, (rel + 256) % 256);
};
fn asm_store_mem(buf, reg, addr) {
    asm_rex_w(buf); asm_emit(buf, 137);
    asm_emit(buf, reg * 8 + 4); asm_emit(buf, 37);
    asm_emit(buf, addr % 256); asm_emit(buf, __floor(addr / 256) % 256);
    asm_emit(buf, __floor(addr / 65536) % 256); asm_emit(buf, __floor(addr / 16777216) % 256);
};
fn asm_hlt(buf) { asm_emit(buf, 244); };

fn gen_fib(buf, n) {
    asm_xor_reg(buf, 0);
    asm_mov_reg_imm32(buf, 3, 1);
    asm_mov_reg_imm32(buf, 1, n);
    let ls = len(buf);
    asm_mov_reg_reg(buf, 2, 0);
    asm_add_reg_reg(buf, 2, 3);
    asm_mov_reg_reg(buf, 0, 3);
    asm_mov_reg_reg(buf, 3, 2);
    asm_dec_reg(buf, 1);
    asm_jnz_back(buf, ls);
};

fn gen_factorial(buf, n) {
    asm_mov_reg_imm32(buf, 0, 1);
    asm_mov_reg_imm32(buf, 1, n);
    let ls = len(buf);
    asm_mul_reg_reg(buf, 0, 1);
    asm_dec_reg(buf, 1);
    asm_jnz_back(buf, ls);
};

fn w64(b, o, v) {
    __mem_write32(b, o, v % 4294967296);
    __mem_write32(b, o + 4, __floor(v / 4294967296));
};

fn ring0_boot(code_buf) {
    let kvm = __fd_open("/dev/kvm", 2);
    let vm = __syscall(16, kvm, 44545, 0, 0, 0, 0);
    __syscall(16, vm, 44615, 4294565888, 0, 0, 0);
    let mem = __mmap(2097152);
    w64(mem, 8192, 12295); w64(mem, 12288, 16391); w64(mem, 16384, 131);
    let ci = 0;
    while ci < len(code_buf) {
        __mem_write8(mem, ci, __array_get(code_buf, ci));
        let ci = ci + 1;
    };
    let reg = __mmap(4096);
    __mem_write32(reg, 0, 0); __mem_write32(reg, 4, 0);
    w64(reg, 8, 0); w64(reg, 16, 2097152); w64(reg, 24, mem);
    __syscall(16, vm, 1075883590, reg, 0, 0, 0);
    let vcpu = __syscall(16, vm, 44609, 0, 0, 0, 0);
    let msz = __syscall(16, kvm, 44548, 0, 0, 0, 0);
    let run = __syscall(9, 0, msz, 3, 1, vcpu, 0);
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
        let off = di * 24; w64(sregs, off, 0);
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
    let alive = [1];
    while __array_get(alive, 0) == 1 {
        let r = __syscall(16, vcpu, 44672, 0, 0, 0, 0);
        if r < 0 { let _ = __set_at(alive, 0, 0); }
        else {
            let ex = __mem_read32(run, 8);
            if ex == 5 { let _ = __set_at(alive, 0, 0); }
            else { if ex != 2 { let _ = __set_at(alive, 0, 0); }; };
        };
    };
    let r0 = __mem_read32(mem, 1024) + __mem_read32(mem, 1028) * 4294967296;
    __munmap(run, msz); __munmap(regs, 4096); __munmap(sregs, 4096);
    __munmap(reg, 4096); __munmap(mem, 2097152);
    __fd_close(vcpu); __fd_close(vm); __fd_close(kvm);
    return r0;
};

// ═══ TEST: JIT → Ring-0 Computation ═══
emit "=== Olang JIT → Ring-0 Engine ===";
emit "";

// Test 1: Fibonacci
let fib_tests = [5, 10, 20, 30];
let fib_expected = [8, 89, 10946, 1346269];
let ti = 0;
while ti < 4 {
    let n = __array_get(fib_tests, ti);
    let expected = __array_get(fib_expected, ti);
    let code = asm_new();
    gen_fib(code, n);
    asm_store_mem(code, 3, 1024);  // store rbx (fib result) at [0x400]
    asm_hlt(code);
    let result = ring0_boot(code);
    if result == expected {
        emit "fib(" + __to_string(n) + ") = " + __to_string(result) + " PASS";
    } else {
        emit "fib(" + __to_string(n) + ") = " + __to_string(result) + " FAIL (expected " + __to_string(expected) + ")";
    };
    let ti = ti + 1;
};

emit "";

// Test 2: Factorial
let fact_tests = [5, 10, 12];
let fact_expected = [120, 3628800, 479001600];
let ti = 0;
while ti < 3 {
    let n = __array_get(fact_tests, ti);
    let expected = __array_get(fact_expected, ti);
    let code = asm_new();
    gen_factorial(code, n);
    asm_store_mem(code, 0, 1024);  // store rax (n!) at [0x400]
    asm_hlt(code);
    let result = ring0_boot(code);
    if result == expected {
        emit __to_string(n) + "! = " + __to_string(result) + " PASS";
    } else {
        emit __to_string(n) + "! = " + __to_string(result) + " FAIL (expected " + __to_string(expected) + ")";
    };
    let ti = ti + 1;
};

emit "";
emit "=== First ever: self-hosting language JIT → ring-0 kernel ===";
