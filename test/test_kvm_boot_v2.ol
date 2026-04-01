fn w64(base, off, val) {
    __mem_write32(base, off, val % 4294967296);
    __mem_write32(base, off + 4, __floor(val / 4294967296));
};

emit "=== NOX KERNEL — Olang boots ring-0 ===";

let kvm = __fd_open("/dev/kvm", 2);
let api = __syscall(16, kvm, 44544, 0, 0, 0, 0);
let vm = __syscall(16, kvm, 44545, 0, 0, 0, 0);
let tss = __syscall(16, vm, 44615, 4294565888, 0, 0, 0);

let mem = __mmap(2097152);

// ═══ GUEST CODE: "Nox ring-0\n" + store 42 + halt ═══
let p = [0];
fn put(mem, p, ch) {
    let o = __array_get(p, 0);
    __mem_write8(mem, o, 176); __mem_write8(mem, o+1, ch);
    __mem_write8(mem, o+2, 230); __mem_write8(mem, o+3, 233);
    let _ = __set_at(p, 0, o+4);
};
put(mem, p, 78);  put(mem, p, 111); put(mem, p, 120);  // N o x
put(mem, p, 32);                                         // space
put(mem, p, 114); put(mem, p, 105); put(mem, p, 110); put(mem, p, 103); // r i n g
put(mem, p, 45);  put(mem, p, 48);  put(mem, p, 10);   // - 0 \n
// mov word [0x400], 42
let o = __array_get(p, 0);
__mem_write8(mem, o, 199); __mem_write8(mem, o+1, 6);
__mem_write8(mem, o+2, 0); __mem_write8(mem, o+3, 4);
__mem_write8(mem, o+4, 42); __mem_write8(mem, o+5, 0);
let _ = __set_at(p, 0, o+6);
// mov ax, 42; hlt
let o = __array_get(p, 0);
__mem_write8(mem, o, 184); __mem_write8(mem, o+1, 42); __mem_write8(mem, o+2, 0);
__mem_write8(mem, o+3, 244);

// ═══ KVM SETUP ═══
let reg = __mmap(4096);
__mem_write32(reg, 0, 0); __mem_write32(reg, 4, 0);
w64(reg, 8, 0); w64(reg, 16, 2097152); w64(reg, 24, mem);
let mr = __syscall(16, vm, 1075883590, reg, 0, 0, 0);

let vcpu = __syscall(16, vm, 44609, 0, 0, 0, 0);
let msz = __syscall(16, kvm, 44548, 0, 0, 0, 0);
let run = __mmap_file(vcpu, msz);

let sregs = __mmap(4096);
let g = __syscall(16, vcpu, 2167975555, sregs, 0, 0, 0);
w64(sregs, 0, 0); __mem_write8(sregs, 12, 0); __mem_write8(sregs, 13, 0);
let s = __syscall(16, vcpu, 1094233732, sregs, 0, 0, 0);

let regs = __mmap(4096);
w64(regs, 136, 2);
let sr = __syscall(16, vcpu, 1083223682, regs, 0, 0, 0);

// ═══ BOOT ═══
emit "--- Nox kernel booting at ring-0 ---";
let running = [1];
let output = "";
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
                if ch >= 32 { if ch <= 126 {
                    let output = output + char_at("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 -_.", ch - 32);
                }; };
            };
        } else {
            if reason == 5 {
                let _ = __set_at(running, 0, 0);
            } else {
                emit "exit=" + __to_string(reason);
                let _ = __set_at(running, 0, 0);
            };
        };
    };
};

// Verify
let val = __mem_read8(mem, 1024) + __mem_read8(mem, 1025) * 256;

emit "--- Nox kernel halted ---";
emit "Guest wrote to memory[0x400] = " + __to_string(val);
if val == 42 {
    emit "VERIFIED: Nox kernel executed correctly at ring-0";
} else {
    emit "Memory check: expected 42, got " + __to_string(val);
};

// Cleanup
__munmap(run, msz);
__munmap(regs, 4096);
__munmap(sregs, 4096);
__munmap(reg, 4096);
__munmap(mem, 2097152);
__fd_close(vcpu);
__fd_close(vm);
__fd_close(kvm);

emit "=== NOX KERNEL COMPLETE ===";
