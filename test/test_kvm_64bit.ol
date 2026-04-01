// ═══ NOX KERNEL — 64-bit Long Mode ═══
// Olang boots x86-64 kernel at ring-0 inside KVM
// Page tables + GDT + Long mode + 64-bit guest code
// BP12 Phase 4: TRANSCEND

fn w64(base, off, val) {
    __mem_write32(base, off, val % 4294967296);
    __mem_write32(base, off + 4, __floor(val / 4294967296));
};
fn r64(base, off) {
    return __mem_read32(base, off) + __mem_read32(base, off + 4) * 4294967296;
};

emit "=== NOX KERNEL 64-BIT — Long Mode ===";

let kvm = __fd_open("/dev/kvm", 2);
let api = __syscall(16, kvm, 44544, 0, 0, 0, 0);
let vm = __syscall(16, kvm, 44545, 0, 0, 0, 0);
let tss = __syscall(16, vm, 44615, 4294565888, 0, 0, 0);

// 2MB guest memory
let mem = __mmap(2097152);
emit "guest_mem=" + __to_string(mem);

// ═══ PAGE TABLES at 0x2000 (identity map, 2MB huge pages) ═══
// PML4[0] → PDPT at 0x3000
let pml4 = 8192;   // 0x2000
let pdpt = 12288;  // 0x3000
let pd   = 16384;  // 0x4000

// PML4[0] = pdpt_addr | PRESENT | RW | USER
// PDE64_PRESENT=1, PDE64_RW=2, PDE64_USER=4
w64(mem, pml4, pdpt + 7);       // 0x3000 | 0x07

// PDPT[0] = pd_addr | PRESENT | RW | USER
w64(mem, pdpt, pd + 7);         // 0x4000 | 0x07

// PD[0] = 0x000000 | PRESENT | RW | PS (2MB page)
// PDE64_PS = 0x80, so flags = 1|2|0x80 = 0x83
w64(mem, pd, 131);              // 0x00000083 = 2MB identity map 0x000000-0x1FFFFF

// ═══ GUEST CODE at 0x0000 ═══
// 64-bit x86-64 instructions
let p = [0];
fn put(mem, p, ch) {
    let o = __array_get(p, 0);
    __mem_write8(mem, o, 176); __mem_write8(mem, o+1, ch);    // mov al, ch
    __mem_write8(mem, o+2, 230); __mem_write8(mem, o+3, 233); // out 0xe9, al
    let _ = __set_at(p, 0, o+4);
};

// "Nox 64-bit ring-0\n"
put(mem, p, 78);  put(mem, p, 111); put(mem, p, 120);  // N o x
put(mem, p, 32);                                         // space
put(mem, p, 54);  put(mem, p, 52);                      // 6 4
put(mem, p, 45);                                         // -
put(mem, p, 98);  put(mem, p, 105); put(mem, p, 116);  // b i t
put(mem, p, 32);                                         // space
put(mem, p, 114); put(mem, p, 105); put(mem, p, 110); put(mem, p, 103); // r i n g
put(mem, p, 45);  put(mem, p, 48);  put(mem, p, 10);   // - 0 \n

// 64-bit: mov qword [0x400], 42
// 48 c7 04 25 00 04 00 00 2a 00 00 00
let o = __array_get(p, 0);
__mem_write8(mem, o, 72);      // 0x48 REX.W prefix (64-bit operand)
__mem_write8(mem, o+1, 199);   // 0xc7
__mem_write8(mem, o+2, 4);     // 0x04
__mem_write8(mem, o+3, 37);    // 0x25 = SIB byte for [disp32]
__mem_write8(mem, o+4, 0);     // addr byte 0
__mem_write8(mem, o+5, 4);     // addr byte 1 = 0x400
__mem_write8(mem, o+6, 0);     // addr byte 2
__mem_write8(mem, o+7, 0);     // addr byte 3
__mem_write8(mem, o+8, 42);    // imm32 = 42
__mem_write8(mem, o+9, 0);
__mem_write8(mem, o+10, 0);
__mem_write8(mem, o+11, 0);
let _ = __set_at(p, 0, o + 12);

// mov rax, 42; hlt
let o = __array_get(p, 0);
__mem_write8(mem, o, 72);      // 0x48 REX.W
__mem_write8(mem, o+1, 184);   // 0xb8 = mov rax, imm64... no, that's 10 bytes
// Simpler: mov eax, 42 (zero-extends to rax in 64-bit mode)
__mem_write8(mem, o, 184);     // 0xb8 = mov eax, imm32
__mem_write8(mem, o+1, 42);
__mem_write8(mem, o+2, 0);
__mem_write8(mem, o+3, 0);
__mem_write8(mem, o+4, 0);
__mem_write8(mem, o+5, 244);   // 0xf4 = hlt

let code_size = __array_get(p, 0) + 6;
emit "code=" + __to_string(code_size) + " bytes (64-bit)";

// ═══ KVM SETUP ═══
let reg = __mmap(4096);
__mem_write32(reg, 0, 0); __mem_write32(reg, 4, 0);
w64(reg, 8, 0); w64(reg, 16, 2097152); w64(reg, 24, mem);
let mr = __syscall(16, vm, 1075883590, reg, 0, 0, 0);
emit "memreg=" + __to_string(mr);

let vcpu = __syscall(16, vm, 44609, 0, 0, 0, 0);
let msz = __syscall(16, kvm, 44548, 0, 0, 0, 0);
let run = __mmap_file(vcpu, msz);

// ═══ SREGS — Setup Long Mode ═══
let sregs = __mmap(4096);
let g = __syscall(16, vcpu, 2167975555, sregs, 0, 0, 0);
emit "get_sregs=" + __to_string(g);

// Exact offsets from C: cr0=224, cr2=232, cr3=240, cr4=248, cr8=256, efer=264
// CR0: 0x80050033 — write as bytes to avoid u32 overflow
__mem_write8(sregs, 224, 51);   // 0x33
__mem_write8(sregs, 225, 0);    // 0x00
__mem_write8(sregs, 226, 5);    // 0x05
__mem_write8(sregs, 227, 128);  // 0x80
__mem_write8(sregs, 228, 0); __mem_write8(sregs, 229, 0);
__mem_write8(sregs, 230, 0); __mem_write8(sregs, 231, 0);

// CR3: page table at 0x2000
w64(sregs, 240, 8192);

// CR4: PAE = 0x20
w64(sregs, 248, 32);

// EFER at offset 264: LME(256) | LMA(1024) = 0x500 = 1280
w64(sregs, 264, 1280);

// CS: 64-bit code segment (inline — Olang has no hoisting)
w64(sregs, 0, 0);                       // CS.base = 0
// limit = 0xFFFFFFFF (write as 4 bytes to avoid u32 overflow)
__mem_write8(sregs, 8, 255); __mem_write8(sregs, 9, 255);
__mem_write8(sregs, 10, 255); __mem_write8(sregs, 11, 255);
__mem_write8(sregs, 12, 8);             // CS.selector = 0x08
__mem_write8(sregs, 13, 0);
__mem_write8(sregs, 14, 11);            // CS.type = 11
__mem_write8(sregs, 15, 1);             // CS.present = 1
__mem_write8(sregs, 16, 0);             // CS.dpl = 0
__mem_write8(sregs, 17, 0);             // CS.db = 0 (64-bit!)
__mem_write8(sregs, 18, 1);             // CS.s = 1
__mem_write8(sregs, 19, 1);             // CS.l = 1 (LONG MODE!)
__mem_write8(sregs, 20, 1);             // CS.g = 1
__mem_write8(sregs, 21, 0);             // CS.avl
__mem_write8(sregs, 22, 0);             // CS.unusable

// DS=ES=FS=GS=SS: 64-bit data segment
// selector=0x10, type=3, present=1, db=0, s=1, l=0, g=1
let di = 1;
while di < 6 {
    let off = di * 24;
    w64(sregs, off, 0);              // base
    __mem_write8(sregs, off+8, 255); __mem_write8(sregs, off+9, 255); __mem_write8(sregs, off+10, 255); __mem_write8(sregs, off+11, 255);  // limit=0xFFFFFFFF
    __mem_write8(sregs, off+12, 16); // selector = 0x10
    __mem_write8(sregs, off+13, 0);
    __mem_write8(sregs, off+14, 3);  // type = data r/w accessed
    __mem_write8(sregs, off+15, 1);  // present
    __mem_write8(sregs, off+16, 0);  // dpl
    __mem_write8(sregs, off+17, 0);  // db = 0 (64-bit)
    __mem_write8(sregs, off+18, 1);  // s = 1
    __mem_write8(sregs, off+19, 0);  // l = 0 (data seg)
    __mem_write8(sregs, off+20, 1);  // g = 1
    __mem_write8(sregs, off+22, 0);  // unusable = 0
    let di = di + 1;
};

let s = __syscall(16, vcpu, 1094233732, sregs, 0, 0, 0);
emit "set_sregs=" + __to_string(s);

// ═══ REGS ═══
let regs = __mmap(4096);
w64(regs, 128, 0);        // RIP = 0
w64(regs, 136, 2);        // RFLAGS = 2
w64(regs, 48, 2097152);   // RSP = top of 2MB (stack grows down)
let sr = __syscall(16, vcpu, 1083223682, regs, 0, 0, 0);
emit "set_regs=" + __to_string(sr);

// ═══ BOOT 64-BIT KERNEL ═══
emit "--- Booting Nox 64-bit kernel at ring-0 ---";
let running = [1];
let chars = [0];
while __array_get(running, 0) == 1 {
    let r = __syscall(16, vcpu, 44672, 0, 0, 0, 0);
    if r < 0 {
        emit "RUN error=" + __to_string(r);
        let _ = __set_at(running, 0, 0);
    } else {
        let reason = __mem_read32(run, 8);
        if reason == 2 {
            let dir = __mem_read8(run, 32);
            if dir == 1 {
                let doff = __mem_read32(run, 40);
                let ch = __mem_read8(run, doff);
                let _ = __set_at(chars, 0, __array_get(chars, 0) + 1);
            };
        } else {
            if reason == 5 {
                let _ = __set_at(running, 0, 0);
            } else {
                emit "exit=" + __to_string(reason);
                if reason == 9 {
                    emit "suberror=" + __to_string(__mem_read32(run, 48));
                };
                let _ = __set_at(running, 0, 0);
            };
        };
    };
};

let val = __mem_read32(mem, 1024);
emit "--- Kernel halted ---";
emit "Output: " + __to_string(__array_get(chars, 0)) + " chars from ring-0";
emit "Memory[0x400] = " + __to_string(val);
if val == 42 {
    emit "*** VERIFIED: Nox 64-bit kernel at ring-0 ***";
};

// Cleanup
__munmap(run, msz); __munmap(regs, 4096); __munmap(sregs, 4096);
__munmap(reg, 4096); __munmap(mem, 2097152);
__fd_close(vcpu); __fd_close(vm); __fd_close(kvm);
emit "=== COMPLETE ===";

// ═══ Helper: write CS for 64-bit code segment ═══
fn kvm_write_cs_64(sregs) {
    w64(sregs, 0, 0);              // CS.base = 0
    __mem_write32(sregs, 8, 4294967295);  // CS.limit = 0xFFFFFFFF
    __mem_write8(sregs, 12, 8);    // CS.selector = 0x08 = 1<<3
    __mem_write8(sregs, 13, 0);
    __mem_write8(sregs, 14, 11);   // CS.type = 11 (code, exec/read/accessed)
    __mem_write8(sregs, 15, 1);    // CS.present = 1
    __mem_write8(sregs, 16, 0);    // CS.dpl = 0
    __mem_write8(sregs, 17, 0);    // CS.db = 0 (NOT 32-bit — we're 64-bit)
    __mem_write8(sregs, 18, 1);    // CS.s = 1 (code/data, not system)
    __mem_write8(sregs, 19, 1);    // CS.l = 1 (LONG MODE — 64-bit!)
    __mem_write8(sregs, 20, 1);    // CS.g = 1 (4KB granularity)
    __mem_write8(sregs, 21, 0);    // CS.avl = 0
    __mem_write8(sregs, 22, 0);    // CS.unusable = 0
};
