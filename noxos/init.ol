// ═══ NoxOS Init — Minimal PID 1 ═══
emit "=== NoxOS Init ===";
emit "PID 1. Nox controls this machine.";
emit "Heap: " + __to_string(__heap_used());

// Detect hardware
let kvm = __fd_open("/dev/kvm", 2);
if kvm >= 0 { emit "[nox] KVM ready"; __fd_close(kvm); };
let fb = __fd_open("/dev/fb0", 2);
if fb >= 0 { emit "[nox] framebuffer ready"; __fd_close(fb); };

emit "[nox] entering main loop";

// PID 1 must NEVER exit. Infinite nanosleep via syscall.
let ts = __mmap(4096);
__mem_write32(ts, 0, 2);   // tv_sec = 2
__mem_write32(ts, 8, 0);   // tv_nsec = 0
while 1 == 1 {
    let _ = __syscall(35, ts, 0, 0, 0, 0, 0);  // nanosleep
    emit "[nox] alive";
};
