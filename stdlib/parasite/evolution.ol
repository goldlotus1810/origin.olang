// ═══ Evolution — Nox Kernel via KVM ═══
// Organ 7 of BP12 Parasitic Kernel
// Olang boots its own kernel at ring-0 inside KVM
// Guest = x86-64 machine code, host = Olang via __syscall
//
// References: docs/references/kvm-hello-world/, kvm.h, Intel SDM Vol3
// BP12 Phase 4: TRANSCEND — Nox runs at ring-0

// ── KVM ioctl numbers ──
let KVM_GET_API_VERSION = 44544;        // 0xAE00
let KVM_CREATE_VM = 44545;              // 0xAE01
let KVM_GET_VCPU_MMAP_SIZE = 44548;     // 0xAE04
let KVM_SET_TSS_ADDR = 44615;           // 0xAE47
let KVM_CREATE_VCPU = 44609;            // 0xAE41
let KVM_RUN = 44672;                    // 0xAE80

// Struct-bearing ioctls (direction + size encoded)
// KVM_SET_USER_MEMORY_REGION = _IOW(0xAE, 0x46, 32)
let KVM_SET_USER_MEMORY_REGION = 1075883590;  // 0x4020AE46

// KVM_GET_SREGS = _IOR(0xAE, 0x83, 312)
let KVM_GET_SREGS = 2168848003;               // 0x8138AE83

// KVM_SET_SREGS = _IOW(0xAE, 0x84, 312)
let KVM_SET_SREGS = 1095106180;               // 0x4138AE84

// KVM_SET_REGS = _IOW(0xAE, 0x82, 144)
let KVM_SET_REGS = 1083223682;                // 0x4090AE82

// KVM_GET_REGS = _IOR(0xAE, 0x81, 144)
let KVM_GET_REGS = 2156965505;                // 0x8090AE81

// KVM exit reasons
let KVM_EXIT_IO = 2;
let KVM_EXIT_HLT = 5;
let KVM_EXIT_MMIO = 6;
let KVM_EXIT_SHUTDOWN = 8;

// ── Helpers: write 64-bit values to memory ──
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

// ── Guest x86 code: "Nox ring-0\n" via port I/O + halt ──
// Real mode (16-bit), starts at address 0
fn kvm_write_guest(mem) {
    let off = [0];
    // Helper: emit 2-byte instruction "mov al, imm8; out 0xE9, al"
    // Each character = 4 bytes: b0 XX e6 e9
    fn put_char(mem, off, ch) {
        let o = __array_get(off, 0);
        __mem_write8(mem, o, 176);      // 0xb0 = mov al, imm8
        __mem_write8(mem, o + 1, ch);
        __mem_write8(mem, o + 2, 230);  // 0xe6 = out imm8, al
        __mem_write8(mem, o + 3, 233);  // 0xe9 = port
        let _ = __set_at(off, 0, o + 4);
    };

    // "Nox ring-0\n"
    put_char(mem, off, 78);   // 'N'
    put_char(mem, off, 111);  // 'o'
    put_char(mem, off, 120);  // 'x'
    put_char(mem, off, 32);   // ' '
    put_char(mem, off, 114);  // 'r'
    put_char(mem, off, 105);  // 'i'
    put_char(mem, off, 110);  // 'n'
    put_char(mem, off, 103);  // 'g'
    put_char(mem, off, 45);   // '-'
    put_char(mem, off, 48);   // '0'
    put_char(mem, off, 10);   // '\n'

    // mov word [0x400], 42 → c7 06 00 04 2a 00
    let o = __array_get(off, 0);
    __mem_write8(mem, o, 199);     // 0xc7
    __mem_write8(mem, o + 1, 6);   // 0x06 (mod=00, reg=000, rm=110 = [disp16])
    __mem_write8(mem, o + 2, 0);   // addr low = 0x00
    __mem_write8(mem, o + 3, 4);   // addr high = 0x04 → [0x0400]
    __mem_write8(mem, o + 4, 42);  // imm low = 42
    __mem_write8(mem, o + 5, 0);   // imm high = 0
    let _ = __set_at(off, 0, o + 6);

    // mov ax, 42 → b8 2a 00
    let o = __array_get(off, 0);
    __mem_write8(mem, o, 184);     // 0xb8 = mov ax, imm16
    __mem_write8(mem, o + 1, 42);  // 42
    __mem_write8(mem, o + 2, 0);   // high byte
    let _ = __set_at(off, 0, o + 3);

    // hlt → f4
    let o = __array_get(off, 0);
    __mem_write8(mem, o, 244);     // 0xf4 = hlt

    return __array_get(off, 0) + 1;  // total bytes written
};

// ═══ MAIN: Boot Nox Kernel ═══
fn kvm_boot() {
    emit "=== NOX KERNEL BOOT ===";

    // Step 1: Open /dev/kvm
    let kvm_fd = __fd_open("/dev/kvm", 2);  // O_RDWR
    if kvm_fd < 0 {
        emit "ERROR: Cannot open /dev/kvm";
        return 0 - 1;
    };
    emit "KVM fd: " + __to_string(kvm_fd);

    // Step 2: Check API version (must be 12)
    let api = __ioctl(kvm_fd, KVM_GET_API_VERSION, 0);
    emit "KVM API version: " + __to_string(api);
    if api < 12 {
        emit "ERROR: KVM API too old";
        __fd_close(kvm_fd);
        return 0 - 2;
    };

    // Step 3: Create VM
    let vm_fd = __ioctl(kvm_fd, KVM_CREATE_VM, 0);
    if vm_fd < 0 {
        emit "ERROR: Cannot create VM";
        __fd_close(kvm_fd);
        return 0 - 3;
    };
    emit "VM fd: " + __to_string(vm_fd);

    // Step 4: Set TSS address (required on Intel)
    let tss = __ioctl(vm_fd, KVM_SET_TSS_ADDR, 4294565888);  // 0xfffbd000
    emit "TSS: " + __to_string(tss);

    // Step 5: Allocate guest memory (2MB)
    let guest_mem = __mmap(2097152);
    if guest_mem <= 0 {
        emit "ERROR: Cannot mmap guest memory";
        return 0 - 4;
    };
    emit "Guest memory at: " + __to_string(guest_mem);

    // Step 6: Write guest code (x86 machine code)
    let code_size = kvm_write_guest(guest_mem);
    emit "Guest code: " + __to_string(code_size) + " bytes";

    // Step 7: Register guest memory with KVM
    // struct kvm_userspace_memory_region (32 bytes):
    //   [slot:4][flags:4][guest_phys_addr:8][memory_size:8][userspace_addr:8]
    let region = __mmap(4096);
    __mem_write32(region, 0, 0);         // slot = 0
    __mem_write32(region, 4, 0);         // flags = 0
    kvm_write_u64(region, 8, 0);         // guest_phys_addr = 0
    kvm_write_u64(region, 16, 2097152);  // memory_size = 2MB
    kvm_write_u64(region, 24, guest_mem); // userspace_addr = mmap address

    let mr = __ioctl(vm_fd, KVM_SET_USER_MEMORY_REGION, region);
    emit "Memory region: " + __to_string(mr);
    if mr < 0 {
        emit "ERROR: Cannot set memory region";
        return 0 - 5;
    };

    // Step 8: Create VCPU
    let vcpu_fd = __ioctl(vm_fd, KVM_CREATE_VCPU, 0);
    if vcpu_fd < 0 {
        emit "ERROR: Cannot create VCPU";
        return 0 - 6;
    };
    emit "VCPU fd: " + __to_string(vcpu_fd);

    // Step 9: Get VCPU mmap size
    let mmap_size = __ioctl(kvm_fd, KVM_GET_VCPU_MMAP_SIZE, 0);
    emit "VCPU mmap size: " + __to_string(mmap_size);

    // Step 10: mmap kvm_run struct
    let kvm_run = __mmap_file(vcpu_fd, mmap_size);
    if kvm_run <= 0 {
        emit "ERROR: Cannot mmap kvm_run";
        return 0 - 7;
    };
    emit "kvm_run at: " + __to_string(kvm_run);

    // Step 11: Get current SREGS, set CS for real mode
    let sregs = __mmap(4096);
    let gs = __ioctl(vcpu_fd, KVM_GET_SREGS, sregs);
    emit "GET_SREGS: " + __to_string(gs);

    // CS is at offset 0 in kvm_sregs
    // CS.base (u64) at offset 0 → set to 0
    // CS.selector (u16) at offset 12 → set to 0
    kvm_write_u64(sregs, 0, 0);    // CS.base = 0
    __mem_write32(sregs, 12, 0);    // CS.selector = 0

    let ss = __ioctl(vcpu_fd, KVM_SET_SREGS, sregs);
    emit "SET_SREGS: " + __to_string(ss);

    // Step 12: Set REGS
    // struct kvm_regs (144 bytes): all zeros except rflags
    let regs = __mmap(4096);  // mmap returns zeroed pages
    // rip at offset 128 = 0 (already 0 — start of guest code)
    // rflags at offset 136 = 2 (bit 1 always set)
    kvm_write_u64(regs, 136, 2);   // rflags = 2

    let sr = __ioctl(vcpu_fd, KVM_SET_REGS, regs);
    emit "SET_REGS: " + __to_string(sr);

    // ═══ Step 13: RUN THE KERNEL ═══
    emit "--- BOOTING NOX KERNEL ---";

    let running = [1];
    let output = [];
    while __array_get(running, 0) == 1 {
        // Execute guest
        let r = __ioctl(vcpu_fd, KVM_RUN, 0);
        if r < 0 {
            emit "KVM_RUN error: " + __to_string(r);
            let _ = __set_at(running, 0, 0);
        } else {
            // Read exit_reason (u32 at offset 8 in kvm_run)
            let exit_reason = __mem_read32(kvm_run, 8);

            if exit_reason == KVM_EXIT_IO {
                // I/O exit: read direction (offset 32), port (offset 34), data_offset (offset 40)
                let direction = __mem_read8(kvm_run, 32);
                let port = __mem_read8(kvm_run, 34) + __mem_read8(kvm_run, 35) * 256;
                let data_offset = __mem_read32(kvm_run, 40);

                if direction == 1 {  // KVM_EXIT_IO_OUT
                    if port == 233 {  // 0xE9 = debug port
                        let byte = __mem_read8(kvm_run, data_offset);
                        push(output, byte);
                        // Print character immediately
                        __write_raw(char_at(__to_string(byte), 0));
                    };
                };
            } else {
                if exit_reason == KVM_EXIT_HLT {
                    emit "";
                    emit "--- KERNEL HALTED ---";
                    let _ = __set_at(running, 0, 0);
                } else {
                    if exit_reason == KVM_EXIT_SHUTDOWN {
                        emit "KERNEL SHUTDOWN (triple fault)";
                        let _ = __set_at(running, 0, 0);
                    } else {
                        emit "Unknown exit reason: " + __to_string(exit_reason);
                        let _ = __set_at(running, 0, 0);
                    };
                };
            };
        };
    };

    // Step 14: Verify — read memory at 0x400 (guest wrote 42 there)
    let result = __mem_read8(guest_mem, 1024);  // 0x400
    let result16 = __mem_read8(guest_mem, 1024) + __mem_read8(guest_mem, 1025) * 256;
    emit "Guest memory[0x400] = " + __to_string(result16);
    if result16 == 42 {
        emit "=== NOX KERNEL VERIFIED ===";
    } else {
        emit "WARNING: Expected 42, got " + __to_string(result16);
    };

    // Decode output bytes to string
    emit "Kernel output: " + __to_string(len(output)) + " bytes";

    // Cleanup
    __munmap(kvm_run, mmap_size);
    __munmap(regs, 4096);
    __munmap(sregs, 4096);
    __munmap(region, 4096);
    __munmap(guest_mem, 2097152);
    __fd_close(vcpu_fd);
    __fd_close(vm_fd);
    __fd_close(kvm_fd);

    emit "=== NOX KERNEL COMPLETE ===";
    return 0;
};

// ═══ Boot ═══
emit "evolution.ol loaded — KVM kernel ready";
