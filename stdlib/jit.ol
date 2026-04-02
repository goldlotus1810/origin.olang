// ═══ JIT Compiler — Olang bytecode → native x86-64 ═══
// Approach: for each opcode, emit a CALL to the VM handler address
// This removes the dispatch overhead (~7 cycles/opcode → 2 cycles/call)
// Expected speedup: 2-4x for typical code

// x86-64 encoding helpers
fn _jit_emit_byte(buf, pos, b) {
    __mem_write8(buf + pos[0], b);
    pos[0] = pos[0] + 1;
};

fn _jit_emit_u32(buf, pos, val) {
    __mem_write8(buf + pos[0], val % 256);
    __mem_write8(buf + pos[0] + 1, __floor(val / 256) % 256);
    __mem_write8(buf + pos[0] + 2, __floor(val / 65536) % 256);
    __mem_write8(buf + pos[0] + 3, __floor(val / 16777216) % 256);
    pos[0] = pos[0] + 4;
};

// Emit: call [rip+disp32] or call rel32
// For calling a known absolute address from JIT code:
// mov rax, addr; call rax = 10 bytes
fn _jit_emit_call_abs(buf, pos, addr) {
    // movabs rax, addr (48 B8 + 8 bytes LE)
    _jit_emit_byte(buf, pos, 0x48);
    _jit_emit_byte(buf, pos, 0xB8);
    // 8 bytes of address (little-endian)
    let i = 0;
    let a = addr;
    while i < 8 {
        _jit_emit_byte(buf, pos, a % 256);
        let a = __floor(a / 256);
        let i = i + 1;
    };
    // call rax (FF D0)
    _jit_emit_byte(buf, pos, 0xFF);
    _jit_emit_byte(buf, pos, 0xD0);
};

// Simple JIT: compile a tight numeric loop
// fn(N) { let sum = 0; let i = 0; while i < N { sum = sum + i; i = i + 1; }; return sum; }
// → native: xor eax,eax; xor ecx,ecx; .L: add eax,ecx; inc ecx; cmp ecx,edi; jl .L; ret
fn jit_sum_loop() {
    let page = __mmap(4096);
    let pos = [0];
    // xor eax, eax (sum = 0)
    _jit_emit_byte(page, pos, 0x31);
    _jit_emit_byte(page, pos, 0xC0);
    // xor ecx, ecx (i = 0)
    _jit_emit_byte(page, pos, 0x31);
    _jit_emit_byte(page, pos, 0xC9);
    // loop: add eax, ecx (sum += i)
    _jit_emit_byte(page, pos, 0x01);
    _jit_emit_byte(page, pos, 0xC8);
    // inc ecx (i++)
    _jit_emit_byte(page, pos, 0xFF);
    _jit_emit_byte(page, pos, 0xC1);
    // cmp ecx, edi (i < N, N is in rdi = first arg)
    _jit_emit_byte(page, pos, 0x39);
    _jit_emit_byte(page, pos, 0xF9);
    // jl -6 (loop back)
    _jit_emit_byte(page, pos, 0x7C);
    _jit_emit_byte(page, pos, 0xF8);
    // ret
    _jit_emit_byte(page, pos, 0xC3);
    // Make executable
    let _ = __syscall(10, page, 4096, 5, 0, 0, 0);
    return page;
};

// JIT a multiply-accumulate: dot(a_ptr, b_ptr, N)
// Assumes a and b are raw f64 pointers (from __f64_new + 8)
fn jit_dot_product() {
    let page = __mmap(4096);
    let pos = [0];
    // rdi = a_ptr, rsi = b_ptr, edx = N
    // xorpd xmm0, xmm0 (66 0F 57 C0)
    _jit_emit_byte(page, pos, 0x66); _jit_emit_byte(page, pos, 0x0F);
    _jit_emit_byte(page, pos, 0x57); _jit_emit_byte(page, pos, 0xC0);
    // test edx, edx
    _jit_emit_byte(page, pos, 0x85); _jit_emit_byte(page, pos, 0xD2);
    // jz done (+14)
    _jit_emit_byte(page, pos, 0x74); _jit_emit_byte(page, pos, 0x0E);
    // loop: movsd xmm1, [rdi] (F2 0F 10 0F)
    _jit_emit_byte(page, pos, 0xF2); _jit_emit_byte(page, pos, 0x0F);
    _jit_emit_byte(page, pos, 0x10); _jit_emit_byte(page, pos, 0x0F);
    // mulsd xmm1, [rsi] (F2 0F 59 0E)
    _jit_emit_byte(page, pos, 0xF2); _jit_emit_byte(page, pos, 0x0F);
    _jit_emit_byte(page, pos, 0x59); _jit_emit_byte(page, pos, 0x0E);
    // addsd xmm0, xmm1 (F2 0F 58 C1)
    _jit_emit_byte(page, pos, 0xF2); _jit_emit_byte(page, pos, 0x0F);
    _jit_emit_byte(page, pos, 0x58); _jit_emit_byte(page, pos, 0xC1);
    // add rdi, 8 (48 83 C7 08)
    _jit_emit_byte(page, pos, 0x48); _jit_emit_byte(page, pos, 0x83);
    _jit_emit_byte(page, pos, 0xC7); _jit_emit_byte(page, pos, 0x08);
    // add rsi, 8 (48 83 C6 08)
    _jit_emit_byte(page, pos, 0x48); _jit_emit_byte(page, pos, 0x83);
    _jit_emit_byte(page, pos, 0xC6); _jit_emit_byte(page, pos, 0x08);
    // dec edx (FF CA)
    _jit_emit_byte(page, pos, 0xFF); _jit_emit_byte(page, pos, 0xCA);
    // jnz loop (-22 = 0xEA)
    _jit_emit_byte(page, pos, 0x75); _jit_emit_byte(page, pos, 0xEA);
    // done: movq rax, xmm0 (return f64 as raw bits in rax)
    // 66 48 0F 7E C0
    _jit_emit_byte(page, pos, 0x66); _jit_emit_byte(page, pos, 0x48);
    _jit_emit_byte(page, pos, 0x0F); _jit_emit_byte(page, pos, 0x7E);
    _jit_emit_byte(page, pos, 0xC0);
    // ret
    _jit_emit_byte(page, pos, 0xC3);

    let _ = __syscall(10, page, 4096, 5, 0, 0, 0);
    return page;
};

emit "jit loaded";
