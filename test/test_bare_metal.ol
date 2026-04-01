// ═══ NOX BARE METAL KERNEL ═══
// Multiboot2 kernel — boots directly from GRUB/QEMU
// No Linux. No VM. Nox IS the operating system.
// BP12 Phase 5: INDEPENDENCE
//
// Flow: BIOS → GRUB/QEMU → Multiboot2 → 32-bit protected mode
//       → setup long mode → 64-bit Nox kernel → VGA output

fn ep(buf, b) { push(buf, b % 256); };
fn ep16(buf, v) { ep(buf, v%256); ep(buf, __floor(v/256)%256); };
fn ep32(buf, v) {
    ep(buf, v%256); ep(buf, __floor(v/256)%256);
    ep(buf, __floor(v/65536)%256); ep(buf, __floor(v/16777216)%256);
};

emit "=== Building Nox Bare Metal Kernel ===";

let bin = [];

// ═══ MULTIBOOT2 HEADER (must be in first 32KB) ═══
// Aligned to 8 bytes
// Multiboot2 header — write as bytes (values > 2^31 overflow ep32)
// Magic = 0xE85250D6
ep(bin, 214); ep(bin, 80); ep(bin, 82); ep(bin, 232);
// Architecture = 0 (i386)
ep32(bin, 0);
// Header length = 24
ep32(bin, 24);
// Checksum = 0x17ADAF12
ep(bin, 18); ep(bin, 175); ep(bin, 173); ep(bin, 23);

// End tag (type=0, flags=0, size=8)
ep16(bin, 0); ep16(bin, 0); ep32(bin, 8);

// ═══ 32-BIT ENTRY POINT ═══
// GRUB drops us here in 32-bit protected mode, paging OFF
// Registers: EAX=0x36D76289 (multiboot2 magic), EBX=info struct pointer
// We need to: setup stack, setup long mode, jump to 64-bit

// === Setup stack: mov esp, 0x7C00 (below kernel) ===
// Actually use high address: mov esp, 0x80000
ep(bin, 188);  // bc = mov esp, imm32
ep32(bin, 524288);  // 0x80000

// === Write "Nox" to VGA text buffer (0xB8000) directly ===
// In 32-bit mode, VGA text buffer is at physical 0xB8000
// Each char = 2 bytes: [ascii, attribute]
// attribute 0x0A = green on black

// mov edi, 0xB8000
ep(bin, 191);  // bf = mov edi
ep32(bin, 753664);  // 0xB8000

// 'N' green
ep(bin, 198); ep(bin, 7); ep(bin, 78);   // mov byte [edi], 'N'
ep(bin, 198); ep(bin, 71); ep(bin, 1); ep(bin, 10);  // mov byte [edi+1], 0x0A
// 'o' green
ep(bin, 198); ep(bin, 71); ep(bin, 2); ep(bin, 111); // mov byte [edi+2], 'o'
ep(bin, 198); ep(bin, 71); ep(bin, 3); ep(bin, 10);  // mov byte [edi+3], 0x0A
// 'x' green
ep(bin, 198); ep(bin, 71); ep(bin, 4); ep(bin, 120); // mov byte [edi+4], 'x'
ep(bin, 198); ep(bin, 71); ep(bin, 5); ep(bin, 10);  // mov byte [edi+5], 0x0A
// ' '
ep(bin, 198); ep(bin, 71); ep(bin, 6); ep(bin, 32);
ep(bin, 198); ep(bin, 71); ep(bin, 7); ep(bin, 10);
// 'O'
ep(bin, 198); ep(bin, 71); ep(bin, 8); ep(bin, 79);
ep(bin, 198); ep(bin, 71); ep(bin, 9); ep(bin, 10);
// 'S'
ep(bin, 198); ep(bin, 71); ep(bin, 10); ep(bin, 83);
ep(bin, 198); ep(bin, 71); ep(bin, 11); ep(bin, 10);

// === Compute fib(30) in 32-bit mode ===
// xor eax, eax
ep(bin, 49); ep(bin, 192);
// mov ebx, 1
ep(bin, 187); ep32(bin, 1);
// mov ecx, 30
ep(bin, 185); ep32(bin, 30);
// loop
let fib_loop = len(bin);
ep(bin, 137); ep(bin, 194);  // mov edx, eax
ep(bin, 1); ep(bin, 218);    // add edx, ebx
ep(bin, 137); ep(bin, 216);  // mov eax, ebx
ep(bin, 137); ep(bin, 211);  // mov ebx, edx
ep(bin, 255); ep(bin, 201);  // dec ecx
let jnz_pos = len(bin);
ep(bin, 117); ep(bin, (fib_loop - (jnz_pos+2) + 256) % 256);

// ebx = fib(31). Display decimal digits at VGA offset 24 (after "Nox OS ")
// Quick: just display "= " + digits
let vga_pos = 24;  // after "Nox OS " (6 chars * 2 bytes each = 12... wait let me recalculate)
// "Nox OS" = 6 chars, each 2 bytes = offset 12
let vga_pos = 12;

// mov edi, 0xB8000 + vga_pos
ep(bin, 191); ep32(bin, 753664 + vga_pos);

// '='
ep(bin, 198); ep(bin, 7); ep(bin, 61);    // mov [edi], '='
ep(bin, 198); ep(bin, 71); ep(bin, 1); ep(bin, 14);  // attr=yellow
// ' '
ep(bin, 198); ep(bin, 71); ep(bin, 2); ep(bin, 32);
ep(bin, 198); ep(bin, 71); ep(bin, 3); ep(bin, 14);

// Now convert ebx to decimal, write to VGA
// Save ebx to esi
ep(bin, 137); ep(bin, 222);  // mov esi, ebx

// itoa on stack
ep(bin, 49); ep(bin, 201);  // xor ecx, ecx (digit count)
ep(bin, 137); ep(bin, 240);  // mov eax, esi

// mov edi, 10 — oops, edi used for VGA. Use different approach.
// Push digits to stack, then pop and write
ep(bin, 187); ep32(bin, 10);  // mov ebx, 10

let itoa_loop = len(bin);
ep(bin, 49); ep(bin, 210);   // xor edx, edx
ep(bin, 247); ep(bin, 243);  // div ebx (eax/ebx → eax=q, edx=r)
ep(bin, 128); ep(bin, 194); ep(bin, 48);  // add dl, '0'
ep(bin, 82);                  // push edx
ep(bin, 65);                  // inc ecx
ep(bin, 133); ep(bin, 192);  // test eax, eax
let jnz2 = len(bin);
ep(bin, 117); ep(bin, (itoa_loop - (jnz2+2) + 256) % 256);

// ecx = digit count. Now pop and write to VGA
// mov edi, 0xB8000 + vga_pos + 4 (after "= ")
ep(bin, 191); ep32(bin, 753664 + vga_pos + 4);

let print_loop = len(bin);
ep(bin, 90);  // pop edx
// mov [edi], dl
ep(bin, 136); ep(bin, 23);  // mov [edi], dl (88 17)
// mov byte [edi+1], 0x0F (white on black)
ep(bin, 198); ep(bin, 71); ep(bin, 1); ep(bin, 15);
// add edi, 2
ep(bin, 131); ep(bin, 199); ep(bin, 2);  // add edi, 2
// dec ecx; jnz
ep(bin, 255); ep(bin, 201);
let jnz3 = len(bin);
ep(bin, 117); ep(bin, (print_loop - (jnz3+2) + 256) % 256);

// === HALT: infinite loop ===
let halt_loop = len(bin);
ep(bin, 250);  // cli
ep(bin, 244);  // hlt
ep(bin, 235); ep(bin, (halt_loop - (len(bin)+2) + 256) % 256);  // jmp halt

let total = len(bin);
emit "Kernel: " + __to_string(total) + " bytes";

// ═══ Write as flat binary (not ELF — multiboot2 is flat) ═══
let tmp = __mmap(total + 4096);
let wi = 0;
while wi < total {
    __mem_write8(tmp, wi, __array_get(bin, wi));
    let wi = wi + 1;
};

let fd = __fd_open("/tmp/nox_kernel.bin", 577);
__syscall(1, fd, tmp, total, 0, 0, 0);
__fd_close(fd);
__munmap(tmp, total + 4096);

emit "Written: /tmp/nox_kernel.bin";

// ═══ TEST IN QEMU ═══
emit "--- Booting in QEMU (3 seconds) ---";
let out = __system("timeout 3 qemu-system-x86_64 -kernel /tmp/nox_kernel.bin -display none -serial stdio -no-reboot 2>&1; echo 'QEMU exited'");
emit out;

// Also test with KVM acceleration
emit "--- Booting with KVM accel ---";
let out2 = __system("timeout 3 qemu-system-x86_64 -kernel /tmp/nox_kernel.bin -enable-kvm -display none -serial stdio -no-reboot 2>&1; echo 'QEMU+KVM exited'");
emit out2;

emit "=== Bare metal kernel built ===";
