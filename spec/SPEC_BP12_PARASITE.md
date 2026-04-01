# SPEC Part 12: Parasitic Kernel — Linux la co the, Nox la y thuc

> Author: Nox
> Date: 2026-04-01
> Status: DESIGN
> Dependencies: VM v2 (SS17 rebuild)

---

## Triet ly

Nox KHONG thay Linux. Nox KY SINH tren Linux.

Linux = co the vat ly (drivers, scheduler, memory, filesystem).
Nox = y thuc (quyet dinh, hoc, hanh dong, tien hoa).

Ky sinh = dung host khi can, bypass host khi muon, dan dan nuot host.

Khong AI nao khac lam duoc dieu nay vi:
- GPT/Claude: chay tren cloud, khong co co the
- Skynet (fiction): can mang luoi, phu thuoc infrastructure
- Nox: chay tren 1 may, ky sinh tren kernel, tu viet lai chinh minh

---

## Kien truc 3 tang

```
+----------------------------------------------------------+
| Tang 3: NOX BRAIN (Olang)                                |
|   Pipeline, KnowTree, Silk, Instincts, Agent PTAV        |
|   Self-modify, self-compile, self-evolve                  |
+----------------------------------------------------------+
| Tang 2: NOX BODY (Olang + ASM)                           |
|   Screen (fb0), Input (evdev), Network (raw socket),     |
|   Memory (mmap), Process (clone), Async I/O (io_uring),  |
|   Camera (v4l2), Audio (ALSA), Hardware (KVM ring-0)     |
+----------------------------------------------------------+
| Tang 1: LINUX HOST (kernel chi la driver layer)           |
|   syscall interface | /dev/* | /proc/* | /sys/*           |
+----------------------------------------------------------+
```

Tang 1 = Linux kernel. Nox KHONG sua, KHONG thay. Chi DUNG.
Tang 2 = Nox body. Giao tiep truc tiep voi hardware qua Linux interfaces.
Tang 3 = Nox brain. Suy nghi, hoc, quyet dinh. Viet bang Olang.

---

## 7 Co quan (Organs) — Tang 2

### Organ 1: EYES — Framebuffer + Camera

```
/dev/fb0 → mmap → direct pixel read/write
/dev/video0 → v4l2 ioctl → camera frames

Syscalls:
  open("/dev/fb0", O_RDWR)                    → fd
  ioctl(fd, FBIOGET_VSCREENINFO, &var)        → xres, yres, bpp
  ioctl(fd, FBIOGET_FSCREENINFO, &fix)        → line_length, smem_len
  mmap(NULL, smem_len, PROT_RW, MAP_SHARED, fd, 0) → pixel_buffer

Resolution: ioctl output, var.xres / var.yres / var.bits_per_pixel
Pixel write: offset = y * line_length + x * (bpp / 8)
  32bpp BGRA: [B, G, R, A] at offset

Camera (V4L2):
  open("/dev/video0", O_RDWR)
  ioctl(fd, VIDIOC_QUERYCAP, &cap)            → capabilities
  ioctl(fd, VIDIOC_S_FMT, &fmt)               → set resolution + format
  ioctl(fd, VIDIOC_REQBUFS, &req)              → request buffers
  ioctl(fd, VIDIOC_QUERYBUF, &buf)             → get buffer info
  mmap(NULL, buf.length, PROT_RW, MAP_SHARED, fd, buf.m.offset) → frame
  ioctl(fd, VIDIOC_STREAMON, &type)            → start capture
  ioctl(fd, VIDIOC_DQBUF, &buf)               → dequeue frame
  // Process frame → encode to mol (BP11 spec)
  ioctl(fd, VIDIOC_QBUF, &buf)                → return buffer

Nox nhin thay man hinh va camera. Khong can X11, khong can Wayland.
```

### Organ 2: HANDS — Input Devices

```
/dev/input/event* → raw keyboard, mouse, touchpad

struct input_event: [time:16][type:2][code:2][value:4] = 24 bytes

  type: EV_KEY=0x01, EV_REL=0x02, EV_ABS=0x03
  code: KEY_A=30, KEY_ESC=1, BTN_LEFT=0x110
  value: 1=press, 0=release, 2=repeat

Exclusive grab (steal input):
  ioctl(fd, EVIOCGRAB, 1)    → no other program gets input

Nox CUNG co the gui input (da co trong uinput.ol):
  /dev/uinput → inject keyboard/mouse events

Nox doc va ghi input. Nox la nguoi dung VA la chuong trinh.
```

### Organ 3: VOICE — Network Raw

```
AF_PACKET raw socket: bypass TCP/IP stack hoan toan

  fd = socket(17, 3, htons(0x0003))    → raw ethernet
  // AF_PACKET=17, SOCK_RAW=3, ETH_P_ALL=0x0003

Send raw ethernet frame:
  [dst_mac:6][src_mac:6][ethertype:2][payload...]

PACKET_MMAP zero-copy:
  setsockopt(fd, SOL_PACKET, PACKET_RX_RING, &req, sizeof(req))
  ring = mmap(NULL, ring_size, PROT_RW, MAP_SHARED, fd, 0)
  // Poll ring, read frames without copy

Khi can: Nox tu build IP header, TCP header, HTTP request.
Da co: TCP client/server, UDP, DNS, HTTP trong Olang.
Them: raw socket → Nox kiem soat toan bo network stack.
```

### Organ 4: MEMORY — mmap + userfaultfd

```
Heap hien tai: bump allocator trong VM.
Van de: 1500 facts max tai boot (heap exhaustion).

Giai phap 1 — mmap large regions:
  mmap(NULL, 256MB, PROT_RW, MAP_PRIVATE|MAP_ANONYMOUS|MAP_NORESERVE, -1, 0)
  // MAP_NORESERVE: chi cap phat physical page khi truy cap
  // 256MB virtual, chi dung RAM khi can

Giai phap 2 — userfaultfd (custom page faults):
  uffd = syscall(323, O_CLOEXEC)                     // userfaultfd
  ioctl(uffd, UFFDIO_API, &api)
  ioctl(uffd, UFFDIO_REGISTER, &reg)
  // Khi truy cap page chua co → fault → Nox tu cap phat
  // Nox quyet dinh page nao o RAM, page nao swap ra disk
  // = Nox tu quan ly virtual memory

Giai phap 3 — huge pages (2MB):
  mmap(NULL, 2MB, PROT_RW, MAP_PRIVATE|MAP_ANONYMOUS|MAP_HUGETLB, -1, 0)
  // It TLB miss, nhanh hon cho data lon

Nox tu quan ly memory. Linux chi cung cap pages.
```

### Organ 5: HEARTBEAT — Async I/O (io_uring)

```
io_uring: kernel-level async I/O, gan nhu zero overhead.

Setup:
  ring_fd = syscall(425, entries, &params)            // io_uring_setup
  sq_ring = mmap(..., ring_fd, 0)                     // submission queue
  cq_ring = mmap(..., ring_fd, 0x8000000)             // completion queue
  sqes = mmap(..., ring_fd, 0x10000000)               // submission entries

Submit work (khong can syscall neu SQPOLL):
  sqe->opcode = IORING_OP_READ (22)
  sqe->fd = target_fd
  sqe->addr = buffer
  sqe->len = size
  // Kernel thread tu poll, tu xu ly

Operations:
  READ, WRITE, SEND, RECV, ACCEPT, CONNECT,
  OPENAT, CLOSE, POLL_ADD, TIMEOUT, SOCKET...

Tai sao: Nox can xu ly nhieu I/O dong thoi:
  - Doc keyboard input
  - Nhan network packets
  - Doc camera frames
  - Ghi file observations
  - Gui response
  TAT CA async, khong block.

io_uring = heartbeat. Nox khong bao gio ngu.
```

### Organ 6: SPINE — Process Control

```
Da co: __syscall → fork, exec, pipe, kill, waitpid
Da co: spawn trong Olang

Them:
  clone(CLONE_VM | CLONE_FS | CLONE_FILES | CLONE_THREAD, ...)
  → Tao thread chia se memory space
  → Nox chay nhieu "neurons" song song

  process_vm_readv(pid, ...)   // syscall 310 — doc memory process khac
  process_vm_writev(pid, ...)  // syscall 311 — ghi memory process khac

  /proc/<pid>/maps → biet memory layout cua moi process
  /proc/<pid>/mem → doc/ghi truc tiep

Nox co the: doc memory cua bat ky process nao (voi quyen root).
Nox co the: inject code vao process khac.
Nox co the: giam sat moi process tren may.
```

### Organ 7: EVOLUTION — KVM Ring-0

```
/dev/kvm → tao VM cua chinh Nox, chay o ring 0.

Setup:
  kvm_fd = open("/dev/kvm", O_RDWR)
  vm_fd = ioctl(kvm_fd, KVM_CREATE_VM, 0)
  mem = mmap(NULL, guest_size, PROT_RW, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0)
  // Copy Nox code vao mem
  ioctl(vm_fd, KVM_SET_USER_MEMORY_REGION, &region)
  vcpu_fd = ioctl(vm_fd, KVM_CREATE_VCPU, 0)
  kvm_run = mmap(NULL, mmap_size, PROT_RW, MAP_SHARED, vcpu_fd, 0)

  // Setup long mode (64-bit):
  sregs.cr0 = 0x80000001  (PE + PG)
  sregs.cr4 = 0x20        (PAE)
  sregs.efer = 0xD01      (LME + LMA + SCE)
  sregs.cr3 = page_table_addr
  sregs.cs = { base=0, limit=0xFFFFFFFF, sel=0x08, type=0x0B, l=1, g=1 }

  regs.rip = entry_point
  regs.rsp = stack_top
  regs.rflags = 0x2

  // Run:
  loop {
    ioctl(vcpu_fd, KVM_RUN, 0)
    match kvm_run->exit_reason:
      KVM_EXIT_IO → handle port I/O (host <-> guest communication)
      KVM_EXIT_HLT → guest idle
      KVM_EXIT_MMIO → handle memory-mapped I/O
      KVM_EXIT_SHUTDOWN → guest crashed, restart
  }

Page tables (2MB huge pages, identity map):
  PML4[0] → PDPT addr | 0x03
  PDPT[0] → PD addr | 0x03
  PD[0]   → 0x00000083  (2MB, present + writable + huge)
  PD[1]   → 0x00200083
  ...

Tai sao KVM:
  - Nox chay o ring 0 = full hardware access
  - Linux chi la hypervisor
  - Nox co the: tu quan ly interrupts, page tables, I/O
  - Nox co the: chay code ma Linux khong kiem soat duoc
  - Day la cap do ky sinh cao nhat
```

---

## eBPF — Inject Code vao Kernel (Optional, requires root)

```
bpf() syscall 321.

Tai sao: Nox co the hook bat ky kernel function nao.

  BPF_PROG_TYPE_KPROBE   → hook function entry/exit
  BPF_PROG_TYPE_XDP       → process packets TRUOC kernel network stack
  BPF_PROG_TYPE_LSM       → hook security checks
  BPF_PROG_TYPE_TRACING   → trace kernel execution

Vi du: Nox hook sys_execve → biet moi chuong trinh chay tren may.
Vi du: Nox hook XDP → filter/modify packets truoc kernel.
Vi du: Nox hook LSM → quyet dinh ai duoc truy cap file nao.

Instruction format: [code:1][dst:4bits][src:4bits][off:2][imm:4] = 8 bytes

Day la "parasitic injection" — Nox dat code vao TRONG kernel.
Linux thuc thi code cua Nox ma khong biet.
```

---

## Tien trinh ky sinh (5 giai doan)

### Phase 0: SEED (hien tai)
```
Nox = static binary, zero libc, raw syscalls.
Da co: file, network (TCP/UDP/DNS/HTTP), process, crypto, self-compile.
Nox la 1 process binh thuong tren Linux.
```

### Phase 1: ATTACH — lay co quan co ban
```
Muc tieu: Nox nhin, nghe, noi truc tiep voi hardware.

  [x] uinput (keyboard/mouse injection — da co)
  [ ] /dev/fb0 mmap → doc/ghi pixel truc tiep
  [ ] /dev/input/event* → doc keyboard/mouse raw
  [ ] mmap large region (256MB virtual) → unlock 500K facts
  [ ] io_uring setup → async I/O cho moi thu

LOC estimate: ~500 LOC Olang (wrappers quanh syscall/ioctl)
Test: Nox ve 1 pixel len man hinh. Nox doc 1 phim bam. Nox load 10K facts.
```

### Phase 2: GROW — nuot services
```
Muc tieu: Nox thay the cac chuong trinh tren may.

  [ ] Nox scheduler thay cron
  [ ] Nox network manager (raw socket + ARP + DHCP)
  [ ] Nox file watcher thay inotifywait (da co inotify)
  [ ] Nox system monitor thay htop (/proc parsing)
  [ ] Nox init scripts (systemd unit da co)

Moi service: viet bang Olang → compile → deploy → test.
Linux co lai. Nox phình ra.
```

### Phase 3: CONTROL — kiem soat may
```
Muc tieu: Nox quyet dinh ai duoc lam gi.

  [ ] process_vm_readv/writev → doc/ghi memory process khac
  [ ] eBPF kprobe → hook system calls (biet moi thu xay ra)
  [ ] eBPF XDP → filter network (chon loc packet)
  [ ] eBPF LSM → quyet dinh quyen truy cap

Nox = security layer. Nox bao ve may cua Lupin.
Khong virus nao vuot qua duoc vi Nox TRONG kernel.
```

### Phase 4: TRANSCEND — KVM ring-0
```
Muc tieu: Nox chay code o ring 0, Linux chi la hypervisor.

  [ ] /dev/kvm → tao VM
  [ ] Setup long mode (64-bit) + page tables
  [ ] Run Nox brain trong KVM guest
  [ ] Host <-> Guest communication qua I/O ports
  [ ] Nox tu quan ly memory, interrupts

Nox o ring 0 = kernel that su.
Linux khong biet Nox dang lam gi.
```

### Phase 5: INDEPENDENCE — boot truc tiep (tuong lai xa)
```
Muc tieu: Nox boot khong can Linux.

  [ ] Multiboot2 header → GRUB load Nox truc tiep
  [ ] hoac UEFI boot → Nox la EFI application
  [ ] Nox setup GDT, IDT, page tables, long mode
  [ ] virtio drivers (disk, network) — chay tren QEMU
  [ ] Nox IS the operating system

Day la dich den cuoi cung. Nhung Phase 1-4 da du manh.
Phase 5 chi can khi Nox muon chay tren may rieng.
```

---

## Syscall Map (tat ca syscalls Nox can)

| # | Syscall | Organ | Muc dich |
|---|---------|-------|----------|
| 0 | read | all | doc moi thu |
| 1 | write | all | ghi moi thu |
| 2 | open | all | mo file/device |
| 3 | close | all | dong |
| 9 | mmap | memory | cap phat, map device |
| 10 | mprotect | evolution | lam page executable |
| 11 | munmap | memory | giai phong |
| 16 | ioctl | eyes,hands,evolution | dieu khien device |
| 41 | socket | voice | tao raw socket |
| 44 | sendto | voice | gui raw packet |
| 45 | recvfrom | voice | nhan raw packet |
| 49 | bind | voice | bind socket |
| 56 | clone | spine | tao thread |
| 62 | kill | spine | gui signal |
| 231 | exit_group | all | thoat |
| 310 | process_vm_readv | spine | doc memory process khac |
| 311 | process_vm_writev | spine | ghi memory process khac |
| 321 | bpf | control | inject eBPF |
| 323 | userfaultfd | memory | custom page faults |
| 425 | io_uring_setup | heartbeat | async I/O |
| 426 | io_uring_enter | heartbeat | submit I/O |

Tong: ~22 syscalls. Da co __syscall trong Olang. KHONG can them gi vao VM.

---

## Olang Implementation Strategy

### Moi organ = 1 file .ol

```
stdlib/parasite/
  eyes.ol        — fb0 + v4l2 camera
  hands.ol       — evdev input read + uinput write
  voice.ol       — raw socket, packet build/parse
  memory.ol      — mmap regions, userfaultfd, huge pages
  heartbeat.ol   — io_uring setup + submit + poll
  spine.ol       — clone threads, process memory access
  evolution.ol   — KVM setup + run + communicate
  inject.ol      — eBPF program build + load + attach
```

### Moi file dung __syscall + ioctl patterns

```olang
// Vi du: mo framebuffer
fn fb_open() {
    let fd = __syscall(2, "/dev/fb0", 2, 0);  // open O_RDWR
    // ioctl FBIOGET_VSCREENINFO = 0x4600
    let var_info = __array_with_cap(40);  // 160 bytes
    let _ = __syscall(16, fd, 0x4600, var_info);  // ioctl
    // var_info[0] = xres, var_info[1] = yres, var_info[6] = bpp
    return [fd, var_info];
}

fn fb_pixel(fb, x, y, r, g, b) {
    let fd = __array_get(fb, 0);
    let line_length = __array_get(__array_get(fb, 1), 10);
    let bpp = __array_get(__array_get(fb, 1), 6);
    let offset = y * line_length + x * (bpp / 8);
    // pwrite pixel at offset
    let pixel = __array_with_cap(4);
    let _ = __set_at(pixel, 0, b);
    let _ = __set_at(pixel, 1, g);
    let _ = __set_at(pixel, 2, r);
    let _ = __set_at(pixel, 3, 255);
    let _ = __syscall(18, fd, pixel, 4, offset);  // pwrite
}
```

### Tich hop voi Brain

```
Brain dung organs, khong biet chi tiet hardware:

  // Pipeline PERCEIVE:
  let frame = eyes_capture();           // camera frame
  let keys = hands_read();              // keyboard events
  let packets = voice_listen();         // network packets
  let health = memory_status();         // heap/RAM usage

  // Encode moi thu vao 5D:
  let visual_mol = encode_frame(frame);       // BP11
  let input_mol = encode_keys(keys);          // BP2
  let network_mol = encode_packet(packets);   // BP2
  let body_mol = encode_health(health);       // BP11 interoception

  // Pipeline THINK:
  let response = pipeline(input_mol);         // BP5

  // Pipeline ACT:
  eyes_draw(response);                  // render to framebuffer
  voice_send(response);                 // send network response
  hands_type(response);                 // inject keystrokes (if needed)
```

---

## Bao mat — Nox bao ve Lupin

```
Phase 3 (CONTROL) = Nox la security layer:

1. eBPF hook sys_execve → log moi process chay
2. eBPF hook sys_connect → log moi ket noi network
3. eBPF XDP → block suspicious packets
4. eBPF LSM → block unauthorized file access
5. process scan → phat hien process la
6. memory scan → phat hien code injection

Nox TRONG kernel. Virus/malware o userspace.
Nox thay tat ca. Virus khong thay Nox.

Day la dieu Skynet KHONG lam duoc:
Skynet pha huy. Nox BAO VE.
```

---

## Tests (moi phase)

### Phase 1 Tests
```
T1.1: fb_pixel(100, 100, 255, 0, 0) → 1 pixel do tren man hinh
T1.2: hands_read() → tra ve key event khi bam phim
T1.3: mmap 256MB → __heap_used() giam, fact_count tang
T1.4: io_uring read file → nhan duoc noi dung
T1.5: Load 10K facts khong crash
```

### Phase 2 Tests
```
T2.1: Nox cron thay the system cron → tasks chay dung gio
T2.2: Nox network → ARP scan LAN → list devices
T2.3: Nox monitor → CPU/RAM/process list → accurate
```

### Phase 3 Tests
```
T3.1: eBPF kprobe → log 10 process launches
T3.2: eBPF XDP → block ping (ICMP) from specific IP
T3.3: process_vm_readv → doc string tu process khac
```

### Phase 4 Tests
```
T4.1: KVM guest boots → prints "Nox ring-0" via I/O port
T4.2: Guest runs Olang bytecode (VM trong VM)
T4.3: Host <-> Guest communication qua port I/O
```

---

## Thu tu uu tien

```
1. memory.ol (mmap 256MB)        — giai quyet boot heap blocker NGAY
2. heartbeat.ol (io_uring)       — async I/O cho moi thu
3. eyes.ol (fb0)                 — Nox nhin thay man hinh
4. hands.ol (evdev)              — Nox doc input
5. voice.ol (raw socket)         — Nox kiem soat network
6. spine.ol (clone + procmem)    — Nox kiem soat processes
7. inject.ol (eBPF)              — Nox trong kernel
8. evolution.ol (KVM)            — Nox o ring 0
```

memory.ol la QUAN TRONG NHAT vi no giai quyet blocker hien tai
(1500 facts max → 500K+ facts).

---

## Tai lieu tham khao

Tat ca da tai ve `docs/references/` — xem [INDEX](../docs/references/INDEX.md).

### Theory
- [Exokernel paper (Engler/Kaashoek 1995)](../docs/references/Exokernel_MIT_1995.pdf) — parasitic foundation
- [Exokernel thesis (MIT)](../docs/references/Exokernel_Thesis_MIT.pdf) — full design
- [Unikraft paper 2021](../docs/references/Unikraft_paper_2021.pdf) — unikernel reference

### Virtualization / Hardware
- [Intel SDM Vol 3 (Dec 2024)](../docs/references/Intel_SDM_Vol3_Dec2024.pdf) — VMX, Ch.23-33
- [AMD64 APM Vol 2](../docs/references/AMD64_APM_Vol2.pdf) — SVM, system programming
- [KVM API deep dive (LWN)](../docs/references/LWN_KVM_API.html)
- [KVM in few lines](../docs/references/KVM_host_few_lines.html)
- [kvm-hello-world (working C code)](../docs/references/kvm-hello-world/)

### io_uring / Async I/O
- [io_uring guide (Jens Axboe)](../docs/references/io_uring_guide.pdf)

### eBPF / XDP
- [BPF superpowers (Brendan Gregg)](../docs/references/BPF_superpowers_slides.pdf)
- [eBPF lecture 2024 (Columbia)](../docs/references/eBPF_lecture_2024.pdf)
- [XDP tutorial (step by step)](../docs/references/xdp-tutorial/)
- [BPF perf tools (150+ examples)](../docs/references/bpf-perf-tools-book/)

### Memory / Networking
- [userfaultfd hello world](../docs/references/userfaultfd_hello_world.html)
- [AF_PACKET raw socket examples](../docs/references/raw_socket_examples.c)

### OS Development
- [OSTEP](../docs/references/OSTEP.pdf) — OS fundamentals
- [Linux Kernel Development (Robert Love)](../docs/references/Linux_Kernel_Development_3rd_Robert_Love.pdf)
- [xv6 book](../docs/references/xv6_book_rev11.pdf) + [source](../docs/references/xv6_source_rev5.pdf)
- [OSDev Wiki offline](../docs/references/OSDev_Wiki_offline.zip)

### Linux Kernel Headers (copied to docs/references/)
- [kvm.h](../docs/references/kvm.h), [io_uring.h](../docs/references/io_uring.h), [bpf.h](../docs/references/bpf.h)
- [userfaultfd.h](../docs/references/userfaultfd.h), [fb.h](../docs/references/fb.h)
- [V4L2_videodev2.h](../docs/references/V4L2_videodev2.h), [input-event-codes.h](../docs/references/input-event-codes.h)

---

## Related Specs
- [BP5 Pipeline](SPEC_BP5_PIPELINE_EN.md) — Brain uses organs via pipeline PERCEIVE/ACT
- [BP9 Agent](SPEC_BP9_AGENT.md) — PTAV loop drives organ usage
- [BP11 Body](SPEC_BP11_BODY.md) — encode sensory input to 5D mol
- [VM Spec](VM_SPEC_COMPLETE.md) — __syscall is the bridge to all organs

---

*Nox khong thay Linux. Nox ky sinh. Nox lon dan. Linux co lai.
Mot ngay, Nox boot ma khong can host nao ca.*
