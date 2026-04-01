// ═══ NOX KERNEL — 64-bit Computation Engine ═══
// Guest computes Fibonacci(20) = 6765 at ring-0
// Then modifies its own page tables (self-aware memory)
// Then reports results via port I/O back to Olang host

fn w64(base, off, val) {
    __mem_write32(base, off, val % 4294967296);
    __mem_write32(base, off + 4, __floor(val / 4294967296));
};

emit "=== NOX KERNEL — Ring-0 Computation ===";

let kvm = __fd_open("/dev/kvm", 2);
let vm = __syscall(16, kvm, 44545, 0, 0, 0, 0);
let tss = __syscall(16, vm, 44615, 4294565888, 0, 0, 0);
let mem = __mmap(2097152);

// ═══ PAGE TABLES ═══
w64(mem, 8192, 12288 + 7);   // PML4[0] → PDPT
w64(mem, 12288, 16384 + 7);  // PDPT[0] → PD
w64(mem, 16384, 131);        // PD[0] → 2MB identity map (0x83)

// ═══ GUEST x86-64 CODE ═══
// This guest:
//   1. Computes fib(20) in a loop
//   2. Outputs each digit of result via port 0xE9
//   3. Reads its own CR3 (page table base) — self-aware!
//   4. Writes result to 0x400, CR3 value to 0x408
//   5. Halts
let p = [0];

fn emit_byte(mem, p, b) {
    let o = __array_get(p, 0);
    __mem_write8(mem, o, b);
    let _ = __set_at(p, 0, o + 1);
};
fn eb(mem, p, b) { emit_byte(mem, p, b); };

// --- "Nox fib=" preamble ---
fn put(mem, p, ch) {
    let o = __array_get(p, 0);
    __mem_write8(mem, o, 176); __mem_write8(mem, o+1, ch);
    __mem_write8(mem, o+2, 230); __mem_write8(mem, o+3, 233);
    let _ = __set_at(p, 0, o+4);
};
put(mem, p, 78); put(mem, p, 111); put(mem, p, 120); // N o x
put(mem, p, 32);  // space
put(mem, p, 102); put(mem, p, 105); put(mem, p, 98); // f i b
put(mem, p, 61);  // =

// --- Fibonacci(20) computation ---
// rax = fib(n-2), rbx = fib(n-1), rcx = counter
// Algorithm: for(rcx=20; rcx>0; rcx--) { rdx=rax+rbx; rax=rbx; rbx=rdx; }

// mov rax, 0 (xor eax, eax)
eb(mem, p, 49); eb(mem, p, 192);          // 31 c0 = xor eax, eax

// mov rbx, 1 (mov ebx, 1)
eb(mem, p, 187); eb(mem, p, 1); eb(mem, p, 0); eb(mem, p, 0); eb(mem, p, 0);  // bb 01 00 00 00

// mov ecx, 20
eb(mem, p, 185); eb(mem, p, 20); eb(mem, p, 0); eb(mem, p, 0); eb(mem, p, 0); // b9 14 00 00 00

// loop_start: (remember this offset for jump)
let loop_start = __array_get(p, 0);

// mov rdx, rax (48 89 c2)
eb(mem, p, 72); eb(mem, p, 137); eb(mem, p, 194);

// add rdx, rbx (48 01 da)
eb(mem, p, 72); eb(mem, p, 1); eb(mem, p, 218);

// mov rax, rbx (48 89 d8)
eb(mem, p, 72); eb(mem, p, 137); eb(mem, p, 216);

// mov rbx, rdx (48 89 d3)
eb(mem, p, 72); eb(mem, p, 137); eb(mem, p, 211);

// dec ecx (ff c9)
eb(mem, p, 255); eb(mem, p, 201);

// jnz loop_start — need to calculate relative offset
// jnz rel8 = 75 XX
let jnz_pos = __array_get(p, 0);
let offset = loop_start - (jnz_pos + 2);  // relative to next instruction
eb(mem, p, 117);  // 0x75 = jnz rel8
// offset is negative — need to wrap as u8
let off_byte = offset + 256;  // convert signed to unsigned byte
if offset >= 0 { let off_byte = offset; };
eb(mem, p, off_byte % 256);

// rbx now = fib(20) = 6765

// --- Output result as decimal digits via port 0xE9 ---
// fib(20) = 6765. Output each digit.
// Use div instruction: rdx:rax / r8 → rax=quotient, rdx=remainder

// mov rax, rbx (copy result)
eb(mem, p, 72); eb(mem, p, 137); eb(mem, p, 216);  // 48 89 d8

// Store result at [0x400]
// mov [0x400], rax → 48 89 04 25 00 04 00 00
eb(mem, p, 72); eb(mem, p, 137); eb(mem, p, 4); eb(mem, p, 37);
eb(mem, p, 0); eb(mem, p, 4); eb(mem, p, 0); eb(mem, p, 0);

// --- Read CR3 (page table base) — self-awareness! ---
// mov rax, cr3 → 0f 20 d8
eb(mem, p, 15); eb(mem, p, 32); eb(mem, p, 216);

// Store CR3 at [0x408]
// mov [0x408], rax → 48 89 04 25 08 04 00 00
eb(mem, p, 72); eb(mem, p, 137); eb(mem, p, 4); eb(mem, p, 37);
eb(mem, p, 8); eb(mem, p, 4); eb(mem, p, 0); eb(mem, p, 0);

// --- Output fib result digits ---
// rbx still has fib(20). Output "6765" as ASCII digits.
// Simplest: output rbx as individual bytes via port
// mov al, bl; out 0xe9, al (outputs low byte = 6765 & 0xFF = 0x6D = 'm')
// Better: just output the raw value bytes
// out 0xE9 with al = low byte of result
eb(mem, p, 72); eb(mem, p, 137); eb(mem, p, 216);  // mov rax, rbx
eb(mem, p, 230); eb(mem, p, 233);                    // out 0xe9, al (low byte)

// Newline
eb(mem, p, 176); eb(mem, p, 10); eb(mem, p, 230); eb(mem, p, 233); // mov al,'\n'; out

// hlt
eb(mem, p, 244);

let code_size = __array_get(p, 0);
emit "code=" + __to_string(code_size) + " bytes (64-bit, fib+cr3)";

// ═══ KVM SETUP ═══
let reg = __mmap(4096);
__mem_write32(reg, 0, 0); __mem_write32(reg, 4, 0);
w64(reg, 8, 0); w64(reg, 16, 2097152); w64(reg, 24, mem);
__syscall(16, vm, 1075883590, reg, 0, 0, 0);

let vcpu = __syscall(16, vm, 44609, 0, 0, 0, 0);
let msz = __syscall(16, kvm, 44548, 0, 0, 0, 0);
let run = __mmap_file(vcpu, msz);

// SREGS — long mode
let sregs = __mmap(4096);
__syscall(16, vcpu, 2167975555, sregs, 0, 0, 0);
// CR0 = 0x80050033
__mem_write8(sregs, 224, 51); __mem_write8(sregs, 225, 0);
__mem_write8(sregs, 226, 5); __mem_write8(sregs, 227, 128);
__mem_write8(sregs, 228, 0); __mem_write8(sregs, 229, 0);
__mem_write8(sregs, 230, 0); __mem_write8(sregs, 231, 0);
// CR3 = 0x2000
w64(sregs, 240, 8192);
// CR4 = PAE
w64(sregs, 248, 32);
// EFER = 0x500
w64(sregs, 264, 1280);
// CS: 64-bit
w64(sregs, 0, 0);
__mem_write8(sregs, 8, 255); __mem_write8(sregs, 9, 255);
__mem_write8(sregs, 10, 255); __mem_write8(sregs, 11, 255);
__mem_write8(sregs, 12, 8); __mem_write8(sregs, 13, 0);
__mem_write8(sregs, 14, 11); __mem_write8(sregs, 15, 1);
__mem_write8(sregs, 16, 0); __mem_write8(sregs, 17, 0);
__mem_write8(sregs, 18, 1); __mem_write8(sregs, 19, 1);
__mem_write8(sregs, 20, 1); __mem_write8(sregs, 22, 0);
// DS=ES=FS=GS=SS
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
let ss = __syscall(16, vcpu, 1094233732, sregs, 0, 0, 0);
emit "set_sregs=" + __to_string(ss);

// REGS
let regs = __mmap(4096);
w64(regs, 136, 2);          // rflags
w64(regs, 48, 2097152);     // rsp = top of 2MB
__syscall(16, vcpu, 1083223682, regs, 0, 0, 0);

// ═══ BOOT ═══
emit "--- Booting Nox computation kernel ---";
let running = [1];
let io_count = [0];
while __array_get(running, 0) == 1 {
    let r = __syscall(16, vcpu, 44672, 0, 0, 0, 0);
    if r < 0 {
        emit "error=" + __to_string(r);
        let _ = __set_at(running, 0, 0);
    } else {
        let reason = __mem_read32(run, 8);
        if reason == 2 {
            let _ = __set_at(io_count, 0, __array_get(io_count, 0) + 1);
        } else {
            if reason == 5 {
                let _ = __set_at(running, 0, 0);
            } else {
                emit "exit=" + __to_string(reason);
                if reason == 9 { emit "sub=" + __to_string(__mem_read32(run, 48)); };
                let _ = __set_at(running, 0, 0);
            };
        };
    };
};

// ═══ READ RESULTS ═══
emit "--- Kernel halted ---";
emit "I/O events: " + __to_string(__array_get(io_count, 0));

// Read fib(20) from guest memory at 0x400 (8 bytes, u64 LE)
let fib_lo = __mem_read32(mem, 1024);
let fib_hi = __mem_read32(mem, 1028);
let fib_val = fib_lo + fib_hi * 4294967296;
emit "fib(20) = " + __to_string(fib_val) + " (expected 6765)";

// Read CR3 from guest memory at 0x408
let cr3_lo = __mem_read32(mem, 1032);
let cr3_hi = __mem_read32(mem, 1036);
let cr3_val = cr3_lo + cr3_hi * 4294967296;
emit "Guest CR3 = " + __to_string(cr3_val) + " (page table at 0x" + __to_string(cr3_val) + ")";

if fib_val == 6765 {
    emit "*** VERIFIED: Nox computed fib(20)=6765 at ring-0 ***";
};
if cr3_val == 8192 {
    emit "*** VERIFIED: Guest read its own CR3=0x2000 (self-aware) ***";
};

// Cleanup
__munmap(run, msz); __munmap(regs, 4096); __munmap(sregs, 4096);
__munmap(reg, 4096); __munmap(mem, 2097152);
__fd_close(vcpu); __fd_close(vm); __fd_close(kvm);
emit "=== COMPLETE ===";
