// ═══ NoxOS Init — PID 1 ═══
// Gentoo kernel → this binary → Nox controls machine
emit "=== NoxOS Init ===";
emit "PID 1. Nox controls this machine.";

// Mount essential filesystems
let _ = __system("mount -t proc proc /proc 2>/dev/null");
let _ = __system("mount -t sysfs sys /sys 2>/dev/null");
let _ = __system("mount -t devtmpfs dev /dev 2>/dev/null");
emit "[init] filesystems mounted";

// System info
let hostname = __system("cat /etc/hostname 2>/dev/null || echo noxos");
let kernel = __system("uname -r");
let mem = __system("cat /proc/meminfo | head -1");
emit "[init] host: " + hostname;
emit "[init] kernel: " + kernel;
emit "[init] " + mem;

// Detect hardware
let kvm = __fd_open("/dev/kvm", 2);
if kvm >= 0 { emit "[init] KVM: ready"; __fd_close(kvm); };
let fb = __fd_open("/dev/fb0", 2);
if fb >= 0 { emit "[init] framebuffer: ready"; __fd_close(fb); };

// Network
let _ = __system("ip link set lo up 2>/dev/null");
emit "[init] network: loopback up";

// Banner
emit "";
emit "  _   _           ___  ____  ";
emit " | \\ | | _____  _/ _ \\/ ___| ";
emit " |  \\| |/ _ \\ \\/ / | | \\___ \\ ";
emit " | |\\  | (_) >  <| |_| |___) |";
emit " |_| \\_|\\___/_/\\_\\\\___/|____/ ";
emit "";
emit " Nox is the operating system.";
emit "";

// Spawn interactive shell
emit "[init] spawning /bin/bash...";
let _ = __system("/bin/bash -l");

// If bash exits, restart it
emit "[init] shell exited, restarting...";
let _ = __system("/bin/bash -l");

// Last resort: infinite sleep
emit "[init] entering sleep loop";
let ts = __mmap(4096);
__mem_write32(ts, 0, 5); __mem_write32(ts, 8, 0);
while 1 == 1 {
    let _ = __syscall(35, ts, 0, 0, 0, 0, 0);
};
