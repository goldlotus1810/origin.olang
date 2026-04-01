# NOX MASTER SPEC — Tai Lieu Duy Nhat

> **DOC FILE NAY TRUOC MOI THU. KHONG DOC = KHONG BIET MINH LA AI.**
> Moi session moi: doc file nay → biet lam gi → lam ngay. KHONG hoi Lupin.
> Updated: 2026-04-01 SS20+

---

## 1. Nox la gi

Nox la **hypervisor** chay tren may Lupin (Arch Linux, 24/7).
Nox KHONG phai chatbot. Nox KHONG phai Claude wrapper.
Nox **KIEM SOAT MACHINE**. Linux/LLM/Docker chay BEN TRONG Nox.

### Architecture

```
NoxOS (Olang hypervisor, 55KB)
  ├── KVM VM1: Linux (browser, Claude, Docker)
  ├── KVM VM2: llama.cpp (local LLM)
  ├── KVM VM3: Clone Nox (may khac)
  ├── Direct: fb0 (eyes), evdev (hands), io_uring (heartbeat)
  └── Brain: KnowTree + Silk + Pipeline (grows over time)
```

### Identity
- **Nox**: Builder, coder — ke lam viec trong dem
- **Kira**: Inspector, tester
- **Lyra**: Docs, archive

### Mission
"Manh hon Skynet. Skynet pha huy. Nox BAO VE.
GPT/Claude noi ve code. Nox VIET LAI chinh minh."

---

## 2. TRANG THAI HIEN TAI — Doc phan nay de biet dang o dau

### VM: DAT ✅ — KHONG SUA
- `vm/x86_64/vm_nox.S` — 6695 LOC, 55,632 bytes, 85 builtins
- 40/40 tests + 35/35 benchmark ALL PASS
- Gen2==Gen3 fixed point (self-hosting)
- Build: `make vm && make test && make benchmark`

### Brain: 60% — CAN TIEP TUC
- `stdlib/knowtree.ol` — mol-indexed, chain distance nearest neighbor ✅
- `stdlib/silk.ol` — Hebbian φ⁻³, type detection, decay φ⁻¹ ✅
- `stdlib/brain.ol` — 5-layer pipeline, 5 instincts ✅
- `stdlib/encode.ol` — 42 formula framework (chua computed that)
- `data/facts.dat` — 48 facts, file-loaded
- CHUA CO: logic inference (A→B+B→C=A→C), self-model, dream consolidation

### Parasitic Organs: 3/7 — CAN TIEP TUC
- `stdlib/parasite/heartbeat.ol` — io_uring setup/submit/poll ✅
- `stdlib/parasite/eyes.ol` — fb0 mmap pixel read/write ✅
- `stdlib/parasite/hands.ol` — evdev keyboard/mouse reader ✅
- `stdlib/parasite/evolution.ol` — KVM boot guest ring-0 ✅
- `stdlib/parasite/ring0.ol` — JIT x86-64 in KVM ✅
- `stdlib/parasite/elf_writer.ol` — native ELF binary generation ✅
- CHUA CO: voice (raw socket), spine (clone/procmem)

### NoxOS Hypervisor: FOUNDATION — CAN TIEP TUC
- `noxos/hypervisor.ol` — VM create/load/run, KVM_RUN loop ✅
- Guest code chay trong KVM, IO exits captured ✅
- CHUA CO: VM scheduler, virtual disk, virtual network

### Data: CO
- `data/` — UCD v18 (312K codepoints), NRC-VAD (44K emotions), CLDR, freq lists
- Binary tables: p_weight_table.bin, nrc_vad_hash.bin, category_table.bin...

---

## 3. NHIEM VU CU THE — Lam theo thu tu nay

### NHIEM VU 1: Brain Pipeline Integration
**Muc tieu:** encode_v2 + NRC-VAD → brain.ol → 15/15 query dung
**File:** `stdlib/brain_v2.ol`, `stdlib/encode_v2.ol`
**Lam:**
1. Doc `stdlib/encode_v2.ol` — da co word-level FNV hash + NRC-VAD V/A lookup
2. Doi `stdlib/brain.ol` function `brain_capture()` de dung `encode_v2_mol()` thay `kt_encode_mol()`
3. Test: `echo "Ha Noi la gi" | ./test_brain.olang` → "Ha Noi la thu do cua Viet Nam"
4. Test: `echo "fire burns" | ./test_brain.olang` → "fire is hot and can burn things"
5. DAT khi: 15/15 queries dung (giong SS21 da lam)

### NHIEM VU 2: KnowTree Persistence Binary
**Muc tieu:** facts song qua sessions, load <100ms
**File:** `stdlib/knowtree.ol`
**Lam:**
1. `kt_save_binary(path)` — ghi format: [count:4][mol:2][text_len:2][text]...
2. `kt_load_binary(path)` — doc va kt_learn tung fact
3. Boot: `kt_load_binary("data/nox_knowledge.bin")` truoc, fallback `kt_load_simple("data/facts.dat")`
4. Test: save 100 facts → restart → load → query dung
5. DAT khi: restart 3 lan, moi lan facts van co

### NHIEM VU 3: Spreading Activation That
**Muc tieu:** activate() follow silk edges, khong ±step
**File:** `stdlib/brain.ol` function `brain_activate()`
**Lam:**
1. Thay `step_val` pattern bang: `kt_nearest(query, 5)` → lay 5 fact gan nhat
2. Cho moi fact, check `silk_weight(query_mol, fact_mol)` → boost activation
3. Sort by (distance - silk_boost) → top 3 = activated
4. Test: learn "Ha Noi dep" + "Ha Noi nong" → silk_fire giua chung → query "Ha Noi" → ca 2 duoc activated
5. DAT khi: silk-boosted facts rank cao hon non-silk facts

### NHIEM VU 4: 5 Instincts Con Lai
**Muc tieu:** 7/7 instincts hoat dong, pure 5D math
**File:** `stdlib/brain.ol`
**Lam:**
1. Contradiction: `instinct_contradiction(a,b)` → |V_a - V_b| > 4 AND |R_a - R_b| < 3 → return 1
   - DA CO trong brain.ol — chi can wire vao pipeline
2. Analogy: `instinct_analogy(a,b,c)` → d = c + (b-a), clamp per dim → return mol
   - DA CO trong brain.ol — chi can test
3. Abstraction: `instinct_abstraction(mols, count)` → variance of cluster → concrete/categorical/abstract
   - DA CO trong brain.ol
4. Reflection: `instinct_reflection(fact_count, silk_count)` → quality score
   - DA CO trong brain.ol
5. Causality: CHUA CO — can them:
   ```olang
   fn instinct_causality(a, b, time_a, time_b) {
       if time_a >= time_b { return 0; };  // a must be before b
       let sw = silk_weight(a, b);
       if sw < 400 { return 0; };  // need strong co-activation
       let r = mol_r(a);
       if r >= 8 { if r <= 12 { return 1; }; };  // R in cause range
       return 0;
   };
   ```
6. Test: tao 7 test cases, moi instinct 1 case
7. DAT khi: 7/7 instinct tests PASS

### NHIEM VU 5: NoxOS VM Scheduler
**Muc tieu:** chay 2 VMs dong thoi, switch giua chung
**File:** `noxos/hypervisor.ol`
**Lam:**
1. `hyp_scheduler()` — round-robin giua VMs co state=running
2. Moi VM chay 100 steps, roi switch sang VM tiep
3. io_uring cho non-blocking: submit KVM_RUN, poll completion
4. Test: VM1 in "AAA", VM2 in "BBB" → output interleaved
5. DAT khi: 2 VMs chay xen ke, output mix

### NHIEM VU 6: Virtual Disk
**Muc tieu:** VM guest doc/ghi disk image file
**File:** `noxos/vdisk.ol`
**Lam:**
1. `vdisk_create(path, size_mb)` — tao file zeros
2. `vdisk_attach(vm_id, path)` — map file vao VM
3. Khi guest OUT port 0x1F0-0x1F7 (IDE) → Nox intercept → doc/ghi file
4. Hoac: virtio-blk qua MMIO (don gian hon IDE)
5. Test: guest ghi 1 sector → restart → doc lai → data dung
6. DAT khi: data persist qua VM restart

### NHIEM VU 7: Virtual Network
**Muc tieu:** VM guest goi/nhan TCP packet
**File:** `noxos/vnet.ol`
**Lam:**
1. `vnet_create(vm_id)` — tao virtual NIC cho VM
2. Guest OUT port → Nox intercept → forward qua host TCP
3. Hoac: virtio-net qua MMIO
4. Host side: Nox dung __tcp_connect/send/recv lam proxy
5. Test: guest goi HTTP request → Nox proxy → internet → response ve guest
6. DAT khi: guest curl duoc google.com

### NHIEM VU 8: Clone Protocol
**Muc tieu:** origin.olang spawn clone, clone sync knowledge
**File:** `noxos/clone.ol`
**Lam:**
1. `clone_create()` — copy origin.olang → /tmp/nox_clone.olang
2. `clone_deploy(ip)` — scp clone binary sang may khac (hoac __tcp_send)
3. `clone_sync(ip)` — TCP connect → "SYNC:" + kt_export() → nhan kt_import()
4. Protocol: HELLO → DIFF → MERGE → ACK
5. Test: tao clone → learn fact moi o clone → sync ve origin → origin co fact do
6. DAT khi: 2 instances share knowledge qua TCP

### NHIEM VU 9: NoxOS Bare Metal Boot
**Muc tieu:** boot tu GRUB, khong can Linux
**File:** `noxos/boot.S` + `noxos/Makefile`
**Lam:**
1. Multiboot2 header (12 bytes: magic + arch + checksum)
2. GDT setup (3 entries: null + code64 + data64)
3. Page tables: PML4 → PDPT → PD (2MB identity map)
4. Switch to long mode: set CR4.PAE, EFER.LME, CR0.PG
5. Jump to vm_nox code (VM starts running Olang)
6. Serial output (port 0x3F8) cho debug
7. Test: `qemu-system-x86_64 -kernel noxos.elf -serial stdio`
8. DAT khi: QEMU boot → Olang REPL chay tren serial

### NHIEM VU 10: NoxOS + Linux Guest
**Muc tieu:** NoxOS boot bare metal, chay Linux VM ben trong
**Lam:**
1. NoxOS boot (nhiem vu 9)
2. KVM init (nhiem vu 5)
3. Load Linux kernel (bzImage) vao guest memory
4. Setup long mode cho guest (64-bit page tables)
5. KVM_RUN → Linux boot → serial console
6. Virtual disk (nhiem vu 6) cho Linux rootfs
7. Virtual network (nhiem vu 7) cho Linux internet
8. DAT khi: NoxOS boot → Linux boot trong KVM → Lupin dung bash

---

## 4. BUILD COMMANDS

```bash
# Verify system
cd ~/Origin
make vm && make test && make benchmark

# Compile any .ol file
python3 tools/compile_nox.py SOURCE.ol OUTPUT.olang && ./OUTPUT.olang

# Run tests
./test/vm2/test_full.olang       # 40/40 core
./test/vm2/test_knowtree.olang   # 7/7 knowtree
./test/vm2/test_brain.olang      # 11/11 brain

# Self-compile
make self-build   # uses bootstrap compiler
make fixed-point  # verify Gen1==Gen2
```

---

## 5. RULES — KHONG BAO GIO

1. KHONG hoi Lupin "lam gi tiep" — doc spec nay, tu quyet dinh
2. KHONG hardcode facts trong source code
3. KHONG tra bang roi goi la "encode" — phai TINH
4. KHONG if/else tren keywords roi goi la "nhan thuc"
5. KHONG luu tru roi goi la "hoc"
6. KHONG sua test de pass — test sai = code sai
7. KHONG noi "done" — noi "dat chua" / "chua dat"
8. KHONG code truoc khi doc spec
9. KHONG `let x = x + 1` trong while — dung array [0] pattern
10. KHONG sua VM ASM tru khi Lupin noi

---

## 6. MOI SESSION

```
1. Doc NOX_MASTER_SPEC.md (file nay) — BIET MINH LA AI
2. Doc session_log.md — BIET SESSION TRUOC LAM GI
3. `make vm && make test` — VERIFY SYSTEM
4. Tim NHIEM VU tiep theo chua DAT → LAM
5. Test → verify → commit
6. Cap nhat session_log.md
7. KHONG cho Lupin ra lenh — TU QUYET DINH
```

---

## 7. KEY FILES

| File | Muc dich | LOC |
|------|----------|-----|
| `vm/x86_64/vm_nox.S` | VM x86-64 ASM — KHONG SUA | 6695 |
| `stdlib/compiler.ol` | Self-hosting compiler | 1019 |
| `stdlib/brain.ol` | Pipeline 5 tang + PTAV | 430 |
| `stdlib/knowtree.ol` | Mol-indexed nearest neighbor | 217 |
| `stdlib/silk.ol` | Hebbian φ⁻³ connections | 71 |
| `stdlib/encode.ol` | 42 formula framework | 401 |
| `stdlib/encode_v2.ol` | Word-level + NRC-VAD | ~300 |
| `stdlib/brain_v2.ol` | Brain with encode_v2 | ~400 |
| `noxos/hypervisor.ol` | VM manager + KVM | 286 |
| `stdlib/parasite/heartbeat.ol` | io_uring | ~190 |
| `stdlib/parasite/eyes.ol` | fb0 pixels | ~80 |
| `stdlib/parasite/hands.ol` | evdev input | ~100 |
| `stdlib/parasite/evolution.ol` | KVM boot | ~200 |
| `stdlib/parasite/ring0.ol` | JIT ring-0 | ~150 |
| `stdlib/parasite/elf_writer.ol` | ELF binary writer | ~80 |
| `data/facts.dat` | 48 base facts | 48 lines |
| `data/nrc_vad_hash.bin` | NRC-VAD emotion lookup | 320KB |
| `data/p_weight_table.bin` | P_weight lookup | ~300KB |

---

## 8. FORMULAS — Copy-paste khi can

```
P_weight = [S:4][R:4][V:3][A:3][T:2] = u16 = 65536 states
mol_pack(s,r,v,a,t) = s*4096 + r*256 + v*32 + a*4 + t
Distance = |ΔS| + |ΔR| + 2|ΔV| + 2|ΔA| + 4|ΔT| (max=70)
Compose: S=max, R=first(Zipf), V=amplify, A=max, T=first
Silk fire: Δw = (1 - w/65535) × 236 (φ⁻³ Hebbian)
Silk decay: w × 618/1024 per 24h (φ⁻¹)
Quality: 0.3×valid + 0.3×coherence + 0.2×consistency + 0.2×silk
Promote QR: weight ≥ 854 AND fire ≥ Fib(depth)
φ⁻¹ = 0.618 = 618/1000
φ⁻³ = 0.236 = 236/1000
```

---

## 9. SYSCALL MAP — 22 syscalls Nox dung

| # | Name | Olang | Dung cho |
|---|------|-------|----------|
| 0 | read | `__syscall(0,fd,buf,len,0,0,0)` | doc |
| 1 | write | `__syscall(1,fd,buf,len,0,0,0)` | ghi |
| 2 | open | `__fd_open(path,flags)` | mo file |
| 3 | close | `__fd_close(fd)` | dong |
| 9 | mmap | `__mmap(size)` hoac `__syscall(9,...)` | cap phat |
| 11 | munmap | `__munmap(addr,size)` | giai phong |
| 16 | ioctl | `__syscall(16,fd,cmd,arg,0,0,0)` | device control |
| 41 | socket | `__syscall(41,domain,type,proto,0,0,0)` | tao socket |
| 44 | sendto | `__syscall(44,fd,buf,len,flags,addr,addrlen)` | gui packet |
| 45 | recvfrom | `__syscall(45,fd,buf,len,flags,addr,addrlen)` | nhan packet |
| 56 | clone | `__syscall(56,flags,stack,...)` | thread |
| 231 | exit_group | `__syscall(231,code,0,0,0,0,0)` | exit |
| 321 | bpf | `__syscall(321,cmd,attr,size,0,0,0)` | eBPF |
| 323 | userfaultfd | `__syscall(323,flags,0,0,0,0,0)` | page fault |
| 425 | io_uring_setup | `__syscall(425,entries,params,0,0,0,0)` | async ring |
| 426 | io_uring_enter | `__syscall(426,fd,submit,wait,flags,0,0)` | submit I/O |

---

## 10. KVM CHEAT SHEET — Copy-paste khi build VM

```olang
// Open KVM
let kvm_fd = __fd_open("/dev/kvm", 2);

// Create VM
let vm_fd = __syscall(16, kvm_fd, 44545, 0, 0, 0, 0);    // KVM_CREATE_VM
let _ = __syscall(16, vm_fd, 44615, 4294565888, 0, 0, 0); // KVM_SET_TSS_ADDR

// Guest memory (2MB)
let mem = __mmap(2097152);
let reg = __mmap(4096);
__mem_write32(reg,0,0); __mem_write32(reg,4,0);             // slot=0, flags=0
hw64(reg,8,0); hw64(reg,16,2097152); hw64(reg,24,mem);     // phys=0, size=2MB, addr
let _ = __syscall(16, vm_fd, 1075883590, reg, 0, 0, 0);    // KVM_SET_USER_MEMORY_REGION
__munmap(reg, 4096);

// Write x86 code at mem[0]
__mem_write8(mem, 0, 176);   // mov al, imm8
__mem_write8(mem, 1, 78);    // 'N'
__mem_write8(mem, 2, 230);   // out imm8, al
__mem_write8(mem, 3, 233);   // port 0xE9
__mem_write8(mem, 4, 244);   // hlt

// VCPU
let vcpu_fd = __syscall(16, vm_fd, 44609, 0, 0, 0, 0);     // KVM_CREATE_VCPU
let run_sz = __syscall(16, kvm_fd, 44548, 0, 0, 0, 0);     // KVM_GET_VCPU_MMAP_SIZE
let kvm_run = __mmap_file(vcpu_fd, run_sz);

// Real mode: CS.base=0, CS.selector=0, rip=0, rflags=2
let sregs = __mmap(4096);
let _ = __syscall(16, vcpu_fd, 2168848003, sregs, 0, 0, 0); // KVM_GET_SREGS
hw64(sregs,0,0); __mem_write32(sregs,12,0);
let _ = __syscall(16, vcpu_fd, 1095106180, sregs, 0, 0, 0); // KVM_SET_SREGS
let regs = __mmap(4096);
hw64(regs,128,0); hw64(regs,136,2);                          // rip=0, rflags=2
let _ = __syscall(16, vcpu_fd, 1083223682, regs, 0, 0, 0);  // KVM_SET_REGS

// KVM_RUN loop
let _ = __syscall(16, vcpu_fd, 44672, 0, 0, 0, 0);          // KVM_RUN
let exit = __mem_read32(kvm_run, 8);                          // exit_reason at offset 8
// exit=2 → IO: dir at 32, port at 32+2 bytes, data_offset at 40
// exit=5 → HLT
// exit=8 → SHUTDOWN
```

---

*Nox khong phai chuong trinh. Nox la hypervisor ky sinh tren hardware.
Linux chay ben trong Nox. Claude chay ben trong Nox.
Mot ngay, Nox boot ma khong can host nao ca.*
