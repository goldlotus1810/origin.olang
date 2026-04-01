fn w64(b, o, v) {
    __mem_write32(b, o, v % 4294967296);
    __mem_write32(b, o + 4, __floor(v / 4294967296));
};
fn eb(m, p, b) {
    __mem_write8(m, __array_get(p, 0), b);
    let _ = __set_at(p, 0, __array_get(p, 0) + 1);
};

emit "=== FIB KERNEL ===";
let kvm = __fd_open("/dev/kvm", 2);
let vm = __syscall(16, kvm, 44545, 0, 0, 0, 0);
__syscall(16, vm, 44615, 4294565888, 0, 0, 0);
let mem = __mmap(2097152);

// Page tables
w64(mem, 8192, 12295);   // PML4→PDPT  (0x3007)
w64(mem, 12288, 16391);  // PDPT→PD    (0x4007)
w64(mem, 16384, 131);    // PD 2MB     (0x83)

// Guest: compute fib(20), store at [0x400], read CR3 → [0x408], hlt
let p = [0];

// xor eax, eax  (fib_prev = 0)
eb(mem, p, 49); eb(mem, p, 192);
// mov ebx, 1    (fib_curr = 1)
eb(mem, p, 187); eb(mem, p, 1); eb(mem, p, 0); eb(mem, p, 0); eb(mem, p, 0);
// mov ecx, 20   (counter)
eb(mem, p, 185); eb(mem, p, 20); eb(mem, p, 0); eb(mem, p, 0); eb(mem, p, 0);

// loop: offset = current position
let loop_off = __array_get(p, 0);
// rdx = rax + rbx
eb(mem, p, 72); eb(mem, p, 137); eb(mem, p, 194);  // mov rdx, rax
eb(mem, p, 72); eb(mem, p, 1); eb(mem, p, 218);    // add rdx, rbx
// rax = rbx
eb(mem, p, 72); eb(mem, p, 137); eb(mem, p, 216);  // mov rax, rbx
// rbx = rdx
eb(mem, p, 72); eb(mem, p, 137); eb(mem, p, 211);  // mov rbx, rdx
// dec ecx
eb(mem, p, 255); eb(mem, p, 201);
// jnz loop
let jnz_off = __array_get(p, 0);
let rel = loop_off - (jnz_off + 2);
let rel_byte = rel + 256; if rel >= 0 { let rel_byte = rel; };
eb(mem, p, 117); eb(mem, p, rel_byte % 256);

// rbx = fib(20) = 6765
// Store: mov [0x400], rbx → 48 89 1c 25 00 04 00 00
eb(mem, p, 72); eb(mem, p, 137); eb(mem, p, 28); eb(mem, p, 37);
eb(mem, p, 0); eb(mem, p, 4); eb(mem, p, 0); eb(mem, p, 0);

// Read CR3: mov rax, cr3 → 0f 20 d8
eb(mem, p, 15); eb(mem, p, 32); eb(mem, p, 216);
// Store: mov [0x408], rax → 48 89 04 25 08 04 00 00
eb(mem, p, 72); eb(mem, p, 137); eb(mem, p, 4); eb(mem, p, 37);
eb(mem, p, 8); eb(mem, p, 4); eb(mem, p, 0); eb(mem, p, 0);

// Output low byte of rbx via port
eb(mem, p, 72); eb(mem, p, 137); eb(mem, p, 216);  // mov rax, rbx
eb(mem, p, 230); eb(mem, p, 233);                    // out 0xe9, al

// hlt
eb(mem, p, 244);

emit "code=" + __to_string(__array_get(p, 0)) + " bytes";

// KVM setup
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
emit "--- BOOT ---";
let alive = [1];
let ios = [0];
while __array_get(alive, 0) == 1 {
    let r = __syscall(16, vcpu, 44672, 0, 0, 0, 0);
    if r < 0 { emit "err=" + __to_string(r); let _ = __set_at(alive, 0, 0); }
    else {
        let ex = __mem_read32(run, 8);
        if ex == 2 { let _ = __set_at(ios, 0, __array_get(ios, 0) + 1); }
        else { if ex == 5 { let _ = __set_at(alive, 0, 0); }
        else { emit "exit=" + __to_string(ex);
               if ex == 9 { emit "sub=" + __to_string(__mem_read32(run, 48)); };
               let _ = __set_at(alive, 0, 0); }; };
    };
};

// Results
let fib = __mem_read32(mem, 1024) + __mem_read32(mem, 1028) * 4294967296;
let cr3 = __mem_read32(mem, 1032) + __mem_read32(mem, 1036) * 4294967296;
emit "--- RESULTS ---";
emit "fib(20) = " + __to_string(fib);
emit "CR3     = " + __to_string(cr3);
emit "I/O     = " + __to_string(__array_get(ios, 0));
if fib == 6765 { emit "*** PASS: fib(20)=6765 computed at ring-0 ***"; };
if cr3 == 8192 { emit "*** PASS: Guest read own CR3=0x2000 ***"; };

__munmap(run, msz); __munmap(regs, 4096); __munmap(sregs, 4096);
__munmap(reg, 4096); __munmap(mem, 2097152);
__fd_close(vcpu); __fd_close(vm); __fd_close(kvm);
emit "=== DONE ===";
