// Test: Nox boots its own kernel via KVM
// Requires: /dev/kvm accessible
// Run: python3 tools/compile_nox.py test/test_kvm_boot.ol /tmp/test_kvm.olang && /tmp/test_kvm.olang

// Include evolution.ol functions inline for standalone test
// (Olang doesn't have include yet — copy necessary code)

fn kvm_write_u64(base, offset, val) {
    let low = val % 4294967296;
    let high = __floor(val / 4294967296);
    __mem_write32(base, offset, low);
    __mem_write32(base, offset + 4, high);
};

fn kvm_read_u64(base, offset) {
    let low = __mem_read32(base, offset);
    let high = __mem_read32(base, offset + 4);
    return high * 4294967296 + low;
};

fn kvm_write_guest(mem) {
    let off = [0];
    fn put_char(mem, off, ch) {
        let o = __array_get(off, 0);
        __mem_write8(mem, o, 176);
        __mem_write8(mem, o + 1, ch);
        __mem_write8(mem, o + 2, 230);
        __mem_write8(mem, o + 3, 233);
        let _ = __set_at(off, 0, o + 4);
    };
    put_char(mem, off, 78);   // N
    put_char(mem, off, 111);  // o
    put_char(mem, off, 120);  // x
    put_char(mem, off, 32);   // space
    put_char(mem, off, 114);  // r
    put_char(mem, off, 105);  // i
    put_char(mem, off, 110);  // n
    put_char(mem, off, 103);  // g
    put_char(mem, off, 45);   // -
    put_char(mem, off, 48);   // 0
    put_char(mem, off, 10);   // \n

    // 16-bit: mov word [0x400], 42 → c7 06 00 04 2a 00
    let o = __array_get(off, 0);
    __mem_write8(mem, o, 199);     // c7
    __mem_write8(mem, o + 1, 6);   // 06 = [disp16]
    __mem_write8(mem, o + 2, 0);   // addr low = 0x00
    __mem_write8(mem, o + 3, 4);   // addr high = 0x04
    __mem_write8(mem, o + 4, 42);  // imm low = 42
    __mem_write8(mem, o + 5, 0);   // imm high = 0
    let _ = __set_at(off, 0, o + 6);

    // 16-bit: mov ax, 42 → b8 2a 00
    let o = __array_get(off, 0);
    __mem_write8(mem, o, 184);     // b8
    __mem_write8(mem, o + 1, 42);
    __mem_write8(mem, o + 2, 0);
    let _ = __set_at(off, 0, o + 3);

    let o = __array_get(off, 0);
    __mem_write8(mem, o, 244);
    return __array_get(off, 0) + 1;
};

// ═══ BOOT ═══
emit "=== NOX KVM KERNEL TEST ===";

let kvm_fd = __fd_open("/dev/kvm", 2);
emit "kvm_fd=" + __to_string(kvm_fd);
if kvm_fd < 0 { emit "FAIL: no /dev/kvm"; };

if kvm_fd >= 0 {
    let api = __ioctl(kvm_fd, 44544, 0);
    emit "api=" + __to_string(api);

    let vm_fd = __ioctl(kvm_fd, 44545, 0);
    emit "vm_fd=" + __to_string(vm_fd);

    let tss = __ioctl(vm_fd, 44615, 4294565888);
    emit "tss=" + __to_string(tss);

    let guest_mem = __mmap(2097152);
    emit "guest_mem=" + __to_string(guest_mem);

    let code_bytes = kvm_write_guest(guest_mem);
    emit "code=" + __to_string(code_bytes) + " bytes";

    // Memory region struct
    let region = __mmap(4096);
    __mem_write32(region, 0, 0);
    __mem_write32(region, 4, 0);
    kvm_write_u64(region, 8, 0);
    kvm_write_u64(region, 16, 2097152);
    kvm_write_u64(region, 24, guest_mem);

    let mr = __ioctl(vm_fd, 1075883590, region);
    emit "mem_region=" + __to_string(mr);

    let vcpu_fd = __ioctl(vm_fd, 44609, 0);
    emit "vcpu_fd=" + __to_string(vcpu_fd);

    let mmap_sz = __ioctl(kvm_fd, 44548, 0);
    emit "mmap_sz=" + __to_string(mmap_sz);

    let kvm_run = __mmap_file(vcpu_fd, mmap_sz);
    emit "kvm_run=" + __to_string(kvm_run);

    // SREGS — real mode: just get defaults, set CS.selector=0, CS.base=0
    let sregs = __mmap(4096);
    let gs = __ioctl(vcpu_fd, 2167975555, sregs);
    emit "get_sregs=" + __to_string(gs);

    // For real mode: CS.selector=0, CS.base=0 (should be default)
    // Just set them explicitly
    kvm_write_u64(sregs, 0, 0);   // CS.base = 0
    __mem_write8(sregs, 12, 0);    // CS.selector low = 0
    __mem_write8(sregs, 13, 0);    // CS.selector high = 0

    let ss = __ioctl(vcpu_fd, 1094233732, sregs);
    emit "set_sregs=" + __to_string(ss);

    // REGS — rip=0, rflags=2
    let regs = __mmap(4096);
    kvm_write_u64(regs, 136, 2);
    let sr = __ioctl(vcpu_fd, 1083223682, regs);
    emit "set_regs=" + __to_string(sr);

    // RUN
    emit "--- BOOTING ---";
    let running = [1];
    let chars = [0];
    while __array_get(running, 0) == 1 {
        let r = __ioctl(vcpu_fd, 44672, 0);
        if r < 0 {
            emit "RUN error=" + __to_string(r);
            let _ = __set_at(running, 0, 0);
        } else {
            let reason = __mem_read32(kvm_run, 8);
            if reason == 2 {
                // KVM_EXIT_IO
                let dir = __mem_read8(kvm_run, 32);
                if dir == 1 {
                    let data_off = __mem_read32(kvm_run, 40);
                    let byte = __mem_read8(kvm_run, data_off);
                    // Direct byte output
                    if byte == 10 {
                        emit "";
                    } else {
                        __write_raw(__to_string(byte));
                    };
                    let _ = __set_at(chars, 0, __array_get(chars, 0) + 1);
                };
            } else {
                if reason == 5 {
                    emit "--- HALT ---";
                    let _ = __set_at(running, 0, 0);
                } else {
                    emit "exit_reason=" + __to_string(reason);
                    // For internal error (9), read suberror at offset 48
                    if reason == 9 {
                        let suberror = __mem_read32(kvm_run, 48);
                        emit "suberror=" + __to_string(suberror);
                        // Read ndata
                        let ndata = __mem_read32(kvm_run, 52);
                        emit "ndata=" + __to_string(ndata);
                    };
                    let _ = __set_at(running, 0, 0);
                };
            };
        };
    };

    // Verify
    let val = __mem_read8(guest_mem, 1024) + __mem_read8(guest_mem, 1025) * 256;
    emit "mem[0x400]=" + __to_string(val);
    if val == 42 {
        emit "PASS: Nox kernel verified";
    } else {
        emit "FAIL: expected 42, got " + __to_string(val);
    };

    emit "output: " + __to_string(__array_get(chars, 0)) + " chars";

    // Cleanup
    __munmap(kvm_run, mmap_sz);
    __munmap(regs, 4096);
    __munmap(sregs, 4096);
    __munmap(region, 4096);
    __munmap(guest_mem, 2097152);
    __fd_close(vcpu_fd);
    __fd_close(vm_fd);
    __fd_close(kvm_fd);
};

emit "=== TEST COMPLETE ===";
