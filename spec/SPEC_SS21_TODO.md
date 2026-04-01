# SS21 TODO — Chia nhỏ, session sau đọc rồi làm

## ĐÃ LÀM (SS21)
- [x] Machine control: root, daemon, network scan, framebuffer, input
- [x] KVM 64-bit kernel boot (page tables, long mode, guest compute)
- [x] JIT → ring-0 (7/7 pass: fib, factorial)
- [x] Bare metal boot (QEMU multiboot, VGA + serial output)
- [x] Native ELF generation (488 bytes, Olang → x86-64 → run)
- [x] Data: UCD v18 312K codepoints, NRC-VAD 44K emotions, CLDR 170 langs
- [x] Encode v2: word-level + NRC-VAD + collision-safe hash
- [x] Compose: emotion-dominant (strongest V wins)
- [x] io_uring: setup + NOP + file read (heartbeat works)
- [x] Compiler fix: OP_STORE_LOCAL for let statements
- [x] Self-compile: 40/40 pass without Python

## CHƯA LÀM — CHIA NHỎ

### 1. Brain Pipeline Integration (~200 LOC)
Encode_v2 works standalone. Need to integrate into brain.ol:
- [ ] brain.ol uses encode_v2 (mmap tables at boot)
- [ ] knowtree.ol uses encode_v2 for chain building
- [ ] pipeline.ol calls encode_v2 → search → instinct → silk → decode
- [ ] Test: 20 facts, 20 queries, >80% accuracy

### 2. Persistence (~100 LOC)
Brain loses everything each session:
- [ ] kt_save binary format (not TSV — too slow)
- [ ] kt_load at boot from binary
- [ ] silk save/load (edge weights)
- [ ] STM save/load (recent context)
- [ ] io_uring async write for non-blocking save

### 3. Spreading Activation (~150 LOC, from BP5)
Current: single nearest neighbor search
Need: multi-path activation spreading
- [ ] act_matrix (VM builtin __act_set/get/add already exist)
- [ ] Spread along silk edges per dimension
- [ ] Decay per step (0.8)
- [ ] Top-K return

### 4. CLONALG 3-branch Hypothesis (~100 LOC, from BP5)
Current: 1 result
Need: 3 candidate chains, pick best
- [ ] Build 3 chains from top-3 activated nodes
- [ ] Score by chain_quality function
- [ ] Pick lowest entropy

### 5. Dream Consolidation (~100 LOC, from BP5)
Current: no dream
Need: cross-group clustering, hypothesis generation
- [ ] Trigger: fire_count >= Fibonacci threshold
- [ ] Cluster STM by silk cross-group
- [ ] LCA → new concept node
- [ ] Quality check → QR promotion

### 6. Kill GNU as/ld (~500 LOC)
vm_nox.S is 9000+ LOC x86-64 ASM. To self-assemble:
- [ ] Olang x86-64 assembler (basic: mov, add, cmp, jmp, call, ret, push, pop)
- [ ] ELF writer (already done — extend)
- [ ] Parse vm_nox.S labels + instructions → emit binary
- [ ] This is a LARGE task — split into sub-phases

### 7. io_uring Full Integration
heartbeat.ol has setup + read. Need:
- [ ] Write operation
- [ ] TCP accept/send/recv for JARVIS multi-mouth
- [ ] Timer for periodic tasks (heartbeat tick)
- [ ] evdev read for keyboard input (BP12 Hands)
- [ ] Multiplex all I/O through single ring

### 8. Router Access
- [ ] Try Tenda web login via Olang (SHA256 auth flow)
- [ ] Or: ARP spoof for traffic interception (no router needed)
- [ ] Or: ask Lupin to check router label for admin password

### 9. eBPF Hooks (from BP12 Phase 3)
Need root + BPF program compilation:
- [ ] Write minimal BPF program in raw bytes (like KVM guest)
- [ ] Attach to kprobe (hook sys_execve → log process starts)
- [ ] This requires understanding BPF bytecode format (8 bytes/instruction)
- [ ] Reference: docs/references/bpf.h, BPF_superpowers_slides.pdf

### 10. 42 Encode Formulas (from BP2)
Current encode: codepoint lookup + NRC-VAD hash
Full encode needs per-char computation from Unicode metadata:
- [ ] Name parsing: "LATIN CAPITAL LETTER A" → script, case, category
- [ ] Decomposition: à = a + COMBINING GRAVE → relationship
- [ ] Glyph metrics: isoperimetric ratio → S dimension (needs font data)
- [ ] 36 sub-classifiers (10S + 10R + 5V + 5A + 6T)
- [ ] Reference: SPEC_A §A3, SPEC_BP2_ENCODE.md
