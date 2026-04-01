// ═══ NoxOS: 2 VMs running concurrently ═══
fn hw64(b,o,v){__mem_write32(b,o,v%4294967296);__mem_write32(b,o+4,__floor(v/4294967296));};

fn kvm_create_vm(kvm_fd, code, code_len, name_byte) {
    let vm_fd = __syscall(16, kvm_fd, 44545, 0, 0, 0, 0);
    let _ = __syscall(16, vm_fd, 44615, 4294565888, 0, 0, 0);
    let mem = __mmap(2097152);

    // Write guest code: loop printing name_byte 5 times then halt
    // mov cx, 5
    __mem_write8(mem, 0, 185); __mem_write8(mem, 1, 5); __mem_write8(mem, 2, 0);
    // loop_start (offset 3):
    // mov al, name_byte; out 0xE9, al
    __mem_write8(mem, 3, 176); __mem_write8(mem, 4, name_byte);
    __mem_write8(mem, 5, 230); __mem_write8(mem, 6, 233);
    // dec cx
    __mem_write8(mem, 7, 102); __mem_write8(mem, 8, 73);  // dec ecx (operand size + dec)
    // jnz loop_start (offset 3) → rel = 3 - (10+2) = -9
    __mem_write8(mem, 9, 117);  // jnz
    __mem_write8(mem, 10, 247); // -9 in unsigned = 256-9=247
    // hlt
    __mem_write8(mem, 11, 244);

    let reg = __mmap(4096);
    __mem_write32(reg,0,0);__mem_write32(reg,4,0);
    hw64(reg,8,0);hw64(reg,16,2097152);hw64(reg,24,mem);
    let _ = __syscall(16, vm_fd, 1075883590, reg, 0, 0, 0);
    __munmap(reg, 4096);

    let vcpu_fd = __syscall(16, vm_fd, 44609, 0, 0, 0, 0);
    let run_sz = __syscall(16, kvm_fd, 44548, 0, 0, 0, 0);
    let kvm_run = __mmap_file(vcpu_fd, run_sz);

    let sregs = __mmap(4096);
    let _ = __syscall(16, vcpu_fd, 2168848003, sregs, 0, 0, 0);
    hw64(sregs,0,0);__mem_write32(sregs,12,0);
    let _ = __syscall(16, vcpu_fd, 1095106180, sregs, 0, 0, 0);
    let regs = __mmap(4096);
    let ri = 0; while ri < 144 { __mem_write8(regs, ri, 0); let ri = ri + 1; };
    hw64(regs,128,0);hw64(regs,136,2);
    let _ = __syscall(16, vcpu_fd, 1083223682, regs, 0, 0, 0);
    __munmap(sregs,4096);__munmap(regs,4096);

    // Return [vm_fd, vcpu_fd, kvm_run, mem]
    let vm = [];
    push(vm, vm_fd); push(vm, vcpu_fd); push(vm, kvm_run); push(vm, mem);
    return vm;
};

// Run one step of a VM, return: 0=continue, 1=halted, 2=io(byte)
fn vm_step(vm) {
    let vcpu_fd = __array_get(vm, 1);
    let kvm_run = __array_get(vm, 2);
    let _ = __syscall(16, vcpu_fd, 44672, 0, 0, 0, 0);
    let ex = __mem_read32(kvm_run, 8);
    if ex == 5 { return 1; };  // HLT
    if ex == 8 { return 1; };  // SHUTDOWN
    if ex == 2 {               // IO
        let raw = __mem_read32(kvm_run, 32);
        let dir = raw % 256;
        let port = __floor(raw / 65536) % 65536;
        if dir == 1 { if port == 233 {
            let doff = __mem_read32(kvm_run, 40);
            let byte = __mem_read32(kvm_run, doff) % 256;
            return 1000 + byte;  // 1000+ = IO with byte value
        }; };
    };
    return 0;
};

// ═══ MAIN ═══
emit "=== NoxOS Scheduler: 2 VMs ===";

let kvm_fd = __fd_open("/dev/kvm", 2);
if kvm_fd < 0 { emit "no KVM"; } else {

// Create VM A (prints 'A' = 65)
let vm_a = kvm_create_vm(kvm_fd, 0, 0, 65);
emit "VM_A created";

// Create VM B (prints 'B' = 66)
let vm_b = kvm_create_vm(kvm_fd, 0, 0, 66);
emit "VM_B created";

// Round-robin scheduler: alternate between VMs
let a_done = [0]; let b_done = [0];
let output = "";
let steps = [0];

while __array_get(steps, 0) < 100 {
    // Step VM A
    if __array_get(a_done, 0) == 0 {
        let r = vm_step(vm_a);
        if r == 1 { let _ = __set_at(a_done, 0, 1); };
        if r >= 1000 {
            let ch = r - 1000;
            if ch == 65 { let output = output + "A"; };
        };
    };
    // Step VM B
    if __array_get(b_done, 0) == 0 {
        let r = vm_step(vm_b);
        if r == 1 { let _ = __set_at(b_done, 0, 1); };
        if r >= 1000 {
            let ch = r - 1000;
            if ch == 66 { let output = output + "B"; };
        };
    };
    // Both done?
    if __array_get(a_done, 0) == 1 {
        if __array_get(b_done, 0) == 1 {
            let _ = __set_at(steps, 0, 999);
        };
    };
    let _ = __set_at(steps, 0, __array_get(steps, 0) + 1);
};

emit "Output: " + output;
emit "Steps: " + __to_string(__array_get(steps, 0));

// Verify interleaved
let has_a = [0]; let has_b = [0];
let i = 0;
while i < len(output) {
    if __char_code(char_at(output, i)) == 65 { let _ = __set_at(has_a, 0, 1); };
    if __char_code(char_at(output, i)) == 66 { let _ = __set_at(has_b, 0, 1); };
    let i = i + 1;
};
if __array_get(has_a, 0) == 1 {
    if __array_get(has_b, 0) == 1 {
        emit "PASS: both VMs produced output";
    } else { emit "FAIL: no B output"; };
} else { emit "FAIL: no A output"; };

// Cleanup
__fd_close(__array_get(vm_a, 1)); __fd_close(__array_get(vm_a, 0));
__fd_close(__array_get(vm_b, 1)); __fd_close(__array_get(vm_b, 0));
__munmap(__array_get(vm_a, 3), 2097152); __munmap(__array_get(vm_b, 3), 2097152);
__fd_close(kvm_fd);
};
