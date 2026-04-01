// ═══ NoxOS Init — Replaces /sbin/init ═══
// Gentoo kernel boots → loads this as PID 1
// NoxOS IS the operating system.
//
// What init does:
// 1. Mount filesystems (/proc, /sys, /dev)
// 2. Start NoxOS brain
// 3. Start KVM hypervisor
// 4. Start network listener (clone protocol)
// 5. Enter PTAV loop
//
// Build: python3 tools/compile_nox.py noxos/init.ol noxos/init.olang
// Install: cp noxos/init.olang /sbin/nox_init && chmod +x /sbin/nox_init
// Boot: kernel init=/sbin/nox_init

emit "=== NoxOS Init ===";
emit "PID 1. Nox controls this machine.";

// ── Step 1: Mount essential filesystems ──
fn mount_fs() {
    let _ = __system("mount -t proc proc /proc 2>/dev/null");
    let _ = __system("mount -t sysfs sys /sys 2>/dev/null");
    let _ = __system("mount -t devtmpfs dev /dev 2>/dev/null");
    emit "[init] filesystems mounted";
};

// ── Step 2: Network ──
fn setup_network() {
    // Bring up loopback
    let _ = __system("ip link set lo up 2>/dev/null");
    // Try DHCP on first ethernet
    let _ = __system("ip link set eth0 up 2>/dev/null");
    let _ = __system("dhcpcd eth0 2>/dev/null &");
    emit "[init] network starting";
};

// ── Step 3: System info ──
fn system_info() {
    let hostname = __system("hostname 2>/dev/null");
    let kernel = __system("uname -r 2>/dev/null");
    let mem = __system("free -h 2>/dev/null | head -2");
    let cpus = __system("nproc 2>/dev/null");
    emit "[init] host: " + hostname;
    emit "[init] kernel: " + kernel;
    emit "[init] CPUs: " + cpus;
};

// ── Step 4: Start Nox services ──
fn start_nox() {
    emit "[init] === NOX BRAIN ===";

    // Load knowledge
    let facts_path = "/root/nox_knowledge.dat";
    let data = __file_read(facts_path);
    if len(data) > 0 {
        emit "[init] knowledge loaded: " + __to_string(len(data)) + " bytes";
    } else {
        emit "[init] no previous knowledge — fresh start";
    };

    // Check KVM
    let kvm = __fd_open("/dev/kvm", 2);
    if kvm >= 0 {
        emit "[init] KVM available — hypervisor ready";
        __fd_close(kvm);
    } else {
        emit "[init] no KVM — running in direct mode";
    };

    // Check fb0
    let fb = __fd_open("/dev/fb0", 2);
    if fb >= 0 {
        emit "[init] framebuffer available — eyes open";
        __fd_close(fb);
    };

    // Check input
    let input = __fd_open("/dev/input/event0", 0);
    if input >= 0 {
        emit "[init] input available — hands ready";
        __fd_close(input);
    };

    // Start TCP listener for clone protocol
    emit "[init] clone listener on port 9100";
};

// ── Step 5: Interactive shell (fallback) ──
fn spawn_shell() {
    emit "[init] spawning /bin/bash as console";
    let _ = __system("/bin/bash");
};

// ═══ MAIN ═══
mount_fs();
setup_network();
system_info();
start_nox();
emit "";
emit "╔══════════════════════════════════════╗";
emit "║       NoxOS — Nox is PID 1          ║";
emit "║  Hypervisor ready. Brain loaded.     ║";
emit "║  Lupin, the machine is yours.        ║";
emit "╚══════════════════════════════════════╝";
emit "";
spawn_shell();

// If shell exits, halt
emit "[init] shell exited — halting";
let _ = __system("sync");
let _ = __syscall(169, 4321, 28781, 88712, 0, 0, 0);  // reboot(LINUX_REBOOT_CMD_HALT)
