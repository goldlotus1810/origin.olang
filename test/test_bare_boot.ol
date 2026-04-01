// ═══ NOX BARE METAL — Boots from BIOS, no OS needed ═══
// Multiboot1 kernel: QEMU loads directly
// Outputs to serial (COM1 0x3F8) + VGA (0xB8000)
// Computes fib(30) = 1346269 on bare metal
// BP12 Phase 5: INDEPENDENCE

fn ep(buf, b) { push(buf, b % 256); };
fn ep32(buf, v) {
    ep(buf, v%256); ep(buf, __floor(v/256)%256);
    ep(buf, __floor(v/65536)%256); ep(buf, __floor(v/16777216)%256);
};

emit "=== Building Nox Bare Metal ===";
let bin = [];

// ═══ MULTIBOOT1 HEADER (32 bytes) ═══
// Magic = 0x1BADB002 (LE: 02 B0 AD 1B)
ep(bin, 2); ep(bin, 176); ep(bin, 173); ep(bin, 27);
// Flags = 0x00010003 (bit0: align, bit1: meminfo, bit16: address fields)
ep(bin, 3); ep(bin, 0); ep(bin, 1); ep(bin, 0);
// Checksum = -(magic + flags) mod 2^32 = 0xE4514FFB
ep(bin, 251); ep(bin, 79); ep(bin, 81); ep(bin, 228);
// header_addr = 0x100000 (1MB — where kernel loads)
ep32(bin, 1048576);
// load_addr = 0x100000
ep32(bin, 1048576);
// load_end = 0 (load entire file)
ep32(bin, 0);
// bss_end = 0
ep32(bin, 0);
// entry = 0x100000 + 32 (right after header)
ep32(bin, 1048608);

// ═══ CODE — starts at offset 32 ═══

// Setup stack
ep(bin, 188); ep32(bin, 524288);  // mov esp, 0x80000

// ── Serial output helper: mov dx, 0x3F8; mov al, ch; out dx, al ──
fn serial_char(bin, ch) {
    ep(bin, 102); ep(bin, 186); ep(bin, 248); ep(bin, 3);  // mov dx, 0x03F8
    ep(bin, 176); ep(bin, ch);                               // mov al, ch
    ep(bin, 238);                                            // out dx, al
};

// ── VGA char: mov byte [0xB8000 + pos*2], ch ──
fn vga_char(bin, ch, pos, color) {
    let addr = 753664 + pos * 2;  // 0xB8000 + pos*2
    // mov byte [addr], ch → c6 05 addr32 ch
    ep(bin, 198); ep(bin, 5); ep32(bin, addr); ep(bin, ch);
    // mov byte [addr+1], color
    ep(bin, 198); ep(bin, 5); ep32(bin, addr + 1); ep(bin, color);
};

// Print "Nox OS" to serial + VGA
let msg = "Nox OS ";
let mi = 0;
while mi < len(msg) {
    let ch = __char_code(char_at(msg, mi));
    serial_char(bin, ch);
    vga_char(bin, ch, mi, 10);  // green
    let mi = mi + 1;
};

// Compute fib(30)
ep(bin, 49); ep(bin, 192);       // xor eax, eax
ep(bin, 187); ep32(bin, 1);      // mov ebx, 1
ep(bin, 185); ep32(bin, 30);     // mov ecx, 30

let fib_loop = len(bin);
ep(bin, 137); ep(bin, 194);      // mov edx, eax
ep(bin, 1); ep(bin, 218);        // add edx, ebx
ep(bin, 137); ep(bin, 216);      // mov eax, ebx
ep(bin, 137); ep(bin, 211);      // mov ebx, edx
ep(bin, 255); ep(bin, 201);      // dec ecx
let jnz1 = len(bin);
ep(bin, 117); ep(bin, (fib_loop - (jnz1+2) + 256) % 256);

// Print "fib=" to serial
serial_char(bin, 102); serial_char(bin, 105); serial_char(bin, 98); serial_char(bin, 61);

// itoa: ebx → decimal → push digits → pop and print
ep(bin, 137); ep(bin, 222);      // mov esi, ebx (save)
ep(bin, 49); ep(bin, 201);       // xor ecx, ecx (count)
ep(bin, 137); ep(bin, 240);      // mov eax, esi
ep(bin, 187); ep32(bin, 10);     // mov ebx, 10

let itoa_loop = len(bin);
ep(bin, 49); ep(bin, 210);       // xor edx, edx
ep(bin, 247); ep(bin, 243);      // div ebx
ep(bin, 128); ep(bin, 194); ep(bin, 48);  // add dl, '0'
ep(bin, 82);                      // push edx
ep(bin, 65);                      // inc ecx
ep(bin, 133); ep(bin, 192);      // test eax, eax
let jnz2 = len(bin);
ep(bin, 117); ep(bin, (itoa_loop - (jnz2+2) + 256) % 256);

// Print digits via serial
let pr_loop = len(bin);
ep(bin, 88);                      // pop eax
ep(bin, 102); ep(bin, 186); ep(bin, 248); ep(bin, 3);  // mov dx, 0x03F8
ep(bin, 238);                     // out dx, al
ep(bin, 255); ep(bin, 201);      // dec ecx
let jnz3 = len(bin);
ep(bin, 117); ep(bin, (pr_loop - (jnz3+2) + 256) % 256);

// Newline
serial_char(bin, 10);

// Halt
let halt_pos = len(bin);
ep(bin, 250);  // cli
ep(bin, 244);  // hlt
ep(bin, 235); ep(bin, (halt_pos - (len(bin)+2) + 256) % 256);  // jmp halt

let total = len(bin);
emit "Kernel: " + __to_string(total) + " bytes";

// ═══ Write to disk ═══
let tmp = __mmap(total + 4096);
let wi = 0;
while wi < total { __mem_write8(tmp, wi, __array_get(bin, wi)); let wi = wi + 1; };
let fd = __fd_open("/tmp/nox_os.bin", 577);
if fd >= 0 {
    __syscall(1, fd, tmp, total, 0, 0, 0);
    __fd_close(fd);
};
__munmap(tmp, total + 4096);

// ═══ BOOT IN QEMU ═══
emit "--- BOOTING NOX OS ---";
let out = __system("chmod +r /tmp/nox_os.bin && timeout 3 qemu-system-x86_64 -kernel /tmp/nox_os.bin -nographic -no-reboot 2>&1 | tail -5");
emit out;
emit "=== Nox booted on bare metal ===";
