// ═══════════════════════════════════════════════════════════════════
// NoxOS Hypervisor — Olang controls the machine
// ═══════════════════════════════════════════════════════════════════
//
// Nox = hypervisor. Linux/LLM/Docker = guests.
// Everything runs INSIDE Nox. Nox sees all, controls all.
//
// Architecture:
//   NoxOS (this) → KVM VMs (guests) → io_uring (async I/O)
//   55KB Olang VM + this file = complete hypervisor
//
// Usage:
//   nox vm create linux1 2048 /path/to/disk.img
//   nox vm start linux1
//   nox vm list
//   nox vm console linux1
//   nox vm stop linux1

// ═══ KVM Constants ═══
let KVM_API_VERSION = 12;
let KVM_CREATE_VM = 44545;
let KVM_GET_VCPU_MMAP_SIZE = 44548;
let KVM_SET_TSS_ADDR = 44615;
let KVM_CREATE_VCPU = 44609;
let KVM_RUN = 44672;
let KVM_SET_USER_MEMORY_REGION = 1075883590;
let KVM_GET_SREGS = 2168848003;
let KVM_SET_SREGS = 1095106180;
let KVM_SET_REGS = 1083223682;
let KVM_GET_REGS = 2156965505;
let KVM_EXIT_IO = 2;
let KVM_EXIT_HLT = 5;
let KVM_EXIT_MMIO = 6;
let KVM_EXIT_SHUTDOWN = 8;

// ═══ VM State ═══
let MAX_VMS = 8;
let vm_names = [];      // name strings
let vm_kvm_fds = [];    // KVM fd per VM
let vm_vm_fds = [];     // VM fd per VM
let vm_vcpu_fds = [];   // VCPU fd per VM
let vm_run_ptrs = [];   // kvm_run mmap per VM
let vm_mem_ptrs = [];   // guest memory mmap per VM
let vm_mem_sizes = [];   // guest memory size
let vm_states = [];     // 0=stopped, 1=running, 2=halted
let vm_count = [0];

// Global KVM fd
let kvm_fd = [0 - 1];

// ═══ Helper: write 64-bit value to memory ═══
fn hyp_write_u64(base, offset, val) {
    __mem_write32(base, offset, val % 4294967296);
    __mem_write32(base, offset + 4, __floor(val / 4294967296));
};

// ═══ INIT: Open /dev/kvm ═══
fn hyp_init() {
    let fd = __fd_open("/dev/kvm", 2);
    if fd < 0 { emit "[noxos] ERROR: cannot open /dev/kvm"; return 0 - 1; };

    // Check API version
    let api = __syscall(16, fd, 44544, 0, 0, 0, 0);  // KVM_GET_API_VERSION
    if api != KVM_API_VERSION {
        emit "[noxos] ERROR: KVM API " + __to_string(api) + " != 12";
        __fd_close(fd);
        return 0 - 2;
    };

    let _ = __set_at(kvm_fd, 0, fd);
    emit "[noxos] KVM ready (fd=" + __to_string(fd) + ")";
    return 0;
};

// ═══ CREATE VM ═══
fn hyp_vm_create(name, mem_mb) {
    if __array_get(kvm_fd, 0) < 0 { emit "[noxos] KVM not initialized"; return 0 - 1; };
    let idx = __array_get(vm_count, 0);
    if idx >= MAX_VMS { emit "[noxos] max VMs reached"; return 0 - 2; };

    let kfd = __array_get(kvm_fd, 0);

    // Create VM
    let vm_fd = __syscall(16, kfd, KVM_CREATE_VM, 0, 0, 0, 0);
    if vm_fd < 0 { emit "[noxos] cannot create VM"; return vm_fd; };

    // Set TSS addr (required for Intel)
    let _ = __syscall(16, vm_fd, KVM_SET_TSS_ADDR, 4294565888, 0, 0, 0);

    // Allocate guest memory
    let mem_bytes = mem_mb * 1048576;
    let guest_mem = __mmap(mem_bytes);
    if guest_mem <= 0 { emit "[noxos] cannot mmap guest memory"; return 0 - 3; };

    // Register memory with KVM
    let region = __mmap(4096);
    __mem_write32(region, 0, 0);           // slot
    __mem_write32(region, 4, 0);           // flags
    hyp_write_u64(region, 8, 0);           // guest_phys_addr
    hyp_write_u64(region, 16, mem_bytes);  // size
    hyp_write_u64(region, 24, guest_mem);  // userspace_addr

    let mr = __syscall(16, vm_fd, KVM_SET_USER_MEMORY_REGION, region, 0, 0, 0);
    __munmap(region, 4096);
    if mr < 0 { emit "[noxos] cannot set memory region"; return mr; };

    // Create VCPU
    let vcpu_fd = __syscall(16, vm_fd, KVM_CREATE_VCPU, 0, 0, 0, 0);
    if vcpu_fd < 0 { emit "[noxos] cannot create VCPU"; return vcpu_fd; };

    // mmap kvm_run
    let mmap_sz = __syscall(16, kfd, KVM_GET_VCPU_MMAP_SIZE, 0, 0, 0, 0);
    let kvm_run = __mmap_file(vcpu_fd, mmap_sz);
    if kvm_run <= 0 { emit "[noxos] cannot mmap kvm_run"; return 0 - 4; };

    // Store VM state
    push(vm_names, name);
    push(vm_kvm_fds, kfd);
    push(vm_vm_fds, vm_fd);
    push(vm_vcpu_fds, vcpu_fd);
    push(vm_run_ptrs, kvm_run);
    push(vm_mem_ptrs, guest_mem);
    push(vm_mem_sizes, mem_bytes);
    push(vm_states, 0);
    let _ = __set_at(vm_count, 0, idx + 1);

    emit "[noxos] VM '" + name + "' created (idx=" + __to_string(idx) + " mem=" + __to_string(mem_mb) + "MB)";
    return idx;
};

// ═══ LOAD CODE INTO VM ═══
fn hyp_vm_load_code(idx, code_bytes, code_len) {
    let guest_mem = __array_get(vm_mem_ptrs, idx);
    // Copy code to guest physical address 0
    let i = 0;
    while i < code_len {
        __mem_write8(guest_mem, i, __array_get(code_bytes, i));
        let i = i + 1;
    };
    return code_len;
};

// ═══ SETUP REAL MODE (16-bit) ═══
fn hyp_vm_setup_real(idx) {
    let vcpu_fd = __array_get(vm_vcpu_fds, idx);
    let sregs = __mmap(4096);

    // Get current SREGS
    let _ = __syscall(16, vcpu_fd, KVM_GET_SREGS, sregs, 0, 0, 0);

    // Set CS.base=0, CS.selector=0 for real mode
    hyp_write_u64(sregs, 0, 0);    // CS.base
    __mem_write32(sregs, 12, 0);    // CS.selector (at offset 12 in kvm_segment)

    let _ = __syscall(16, vcpu_fd, KVM_SET_SREGS, sregs, 0, 0, 0);

    // Set REGS: rflags=2, rip=0
    let regs = __mmap(4096);
    let ri = 0;
    while ri < 144 { __mem_write8(regs, ri, 0); let ri = ri + 1; };

    // rflags at offset 128 in kvm_regs (after 16 GP registers × 8 bytes)
    hyp_write_u64(regs, 128, 2);   // rflags = 2 (bit 1 always set)
    // rip at offset 16*8 = 128... actually kvm_regs layout:
    // rax(0), rbx(8), rcx(16), rdx(24), rsi(32), rdi(40), rsp(48), rbp(56)
    // r8(64), r9(72), r10(80), r11(88), r12(96), r13(104), r14(112), r15(120)
    // rip(128), rflags(136)
    hyp_write_u64(regs, 128, 0);   // rip = 0
    hyp_write_u64(regs, 136, 2);   // rflags = 2

    let _ = __syscall(16, vcpu_fd, KVM_SET_REGS, regs, 0, 0, 0);
    __munmap(sregs, 4096);
    __munmap(regs, 4096);
    return 0;
};

// ═══ RUN VM (single step — returns exit reason) ═══
fn hyp_vm_step(idx) {
    let vcpu_fd = __array_get(vm_vcpu_fds, idx);
    let kvm_run = __array_get(vm_run_ptrs, idx);

    let ret = __syscall(16, vcpu_fd, KVM_RUN, 0, 0, 0, 0);
    if ret < 0 { return 0 - 1; };

    // Read exit_reason at offset 12 in kvm_run
    let exit = __mem_read32(kvm_run, 12);
    return exit;
};

// ═══ RUN VM (loop until halt/shutdown) ═══
fn hyp_vm_run(idx) {
    let _ = __set_at(vm_states, idx, 1);  // running
    emit "[noxos] VM " + __to_string(idx) + " starting...";

    let running = [1];
    let output = [];

    while __array_get(running, 0) == 1 {
        let exit = hyp_vm_step(idx);

        if exit == KVM_EXIT_HLT {
            emit "[noxos] VM " + __to_string(idx) + " halted";
            let _ = __set_at(running, 0, 0);
            let _ = __set_at(vm_states, idx, 2);
        };

        if exit == KVM_EXIT_SHUTDOWN {
            emit "[noxos] VM " + __to_string(idx) + " shutdown";
            let _ = __set_at(running, 0, 0);
            let _ = __set_at(vm_states, idx, 0);
        };

        if exit == KVM_EXIT_IO {
            // Handle I/O: read port and data from kvm_run
            let kvm_run = __array_get(vm_run_ptrs, idx);
            // io struct at offset 32 in kvm_run union
            // direction(1B) size(1B) port(2B) count(4B) data_offset(8B)
            let io_dir = __mem_read32(kvm_run, 32) % 256;
            let io_port = __mem_read32(kvm_run, 34) % 65536;
            let io_data_off = __mem_read32(kvm_run, 40);

            if io_dir == 1 {  // OUT
                if io_port == 233 {  // 0xE9 — serial/debug output
                    let byte = __mem_read32(kvm_run, io_data_off) % 256;
                    push(output, byte);
                };
            };
        };

        if exit < 0 {
            emit "[noxos] VM " + __to_string(idx) + " error: " + __to_string(exit);
            let _ = __set_at(running, 0, 0);
        };
    };

    // Convert output bytes to string
    let result = "";
    let i = 0;
    while i < len(output) {
        let ch = __array_get(output, i);
        if ch >= 32 { if ch < 127 {
            let result = result + char_at("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz !\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~", ch - 32);
        }; };
        if ch == 10 { let result = result + "\n"; };
        let i = i + 1;
    };
    return result;
};

// ═══ LIST VMs ═══
fn hyp_vm_list() {
    let n = __array_get(vm_count, 0);
    emit "[noxos] " + __to_string(n) + " VMs:";
    let i = 0;
    while i < n {
        let state = __array_get(vm_states, i);
        let st = "stopped";
        if state == 1 { let st = "running"; };
        if state == 2 { let st = "halted"; };
        let mem = __array_get(vm_mem_sizes, i);
        emit "  [" + __to_string(i) + "] " + __array_get(vm_names, i) + " " + st + " (" + __to_string(__floor(mem / 1048576)) + "MB)";
        let i = i + 1;
    };
};

// ═══ STOP VM ═══
fn hyp_vm_stop(idx) {
    // Close fds
    __fd_close(__array_get(vm_vcpu_fds, idx));
    __fd_close(__array_get(vm_vm_fds, idx));
    __munmap(__array_get(vm_mem_ptrs, idx), __array_get(vm_mem_sizes, idx));
    let _ = __set_at(vm_states, idx, 0);
    emit "[noxos] VM " + __to_string(idx) + " stopped";
};

// ═══ CONVENIENCE: Create + load + run guest code ═══
fn hyp_run_guest(name, code_bytes) {
    let idx = hyp_vm_create(name, 2);  // 2MB
    if idx < 0 { return "error"; };
    hyp_vm_load_code(idx, code_bytes, len(code_bytes));
    hyp_vm_setup_real(idx);
    let result = hyp_vm_run(idx);
    return result;
};

emit "[noxos] hypervisor.ol loaded";
