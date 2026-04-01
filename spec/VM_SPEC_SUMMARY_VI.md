# NOX VM SPEC — TÓM TẮT TIẾNG VIỆT

> Bản dịch tóm tắt của VM_SPEC_COMPLETE.md (53 sections, 149KB)
> Chỉ để Lupin đọc hiểu nhanh. Bản gốc tiếng Anh là bản chính.

---

## PART I — KIẾN TRÚC VM CỐT LÕI (§0-§24)

### §0 Triết lý thiết kế

7 nguyên tắc:
1. **TÍNH, KHÔNG TRA** — P_weight tính từ 42 formulas, không tra bảng
2. **Toán thuần** — Encode = ∫, Decode = ∂, không metaphor
3. **Không phụ thuộc** — x86-64 ASM thuần, chỉ Linux syscalls, không libc
4. **Tự biên dịch** — Gen1 == Gen2 (byte giống hệt) = bằng chứng đúng
5. **Tiết kiệm** — Chain link = 2 bytes, P_weight = 2 bytes
6. **Xác định** — Không GC pause, không allocation fail, cùng input → cùng output
7. **Không giới hạn** — 65,536^N addressing = không gian tri thức vô hạn

### §1 Kiến trúc tổng quan

**Hybrid Stack-Register:**
- Stack: đánh giá biểu thức, truyền tham số
- Register: biến local trong hàm (tối đa 64 slot, O(1) truy cập)
- Matrix: tra cứu O(1) cho biến global, KnowTree, Silk

**Dual-width:**
- Hệ thống: 64-bit (con trỏ, địa chỉ)
- Phân tử: 16-bit (P_weight, chain link, silk type)
- 16-bit → 32 molecules/cache line thay vì 4 → hiệu quả cache 8×

### §2 Bộ nhớ

```
[VM Stack 16MB] [Zone C — temp mỗi turn] [Zone B — session] [Zone A — vĩnh viễn]
[var_matrix 1MB] [kt_matrix 128KB] [silk_matrix 128KB] [Bytecode]
Tổng: 4GB mmap
```

Stack entry = 16 bytes [ptr:8][len:8]. Kiểu xác định bởi sentinel trong len:
- `0xFFFF...FF` = số f64
- `0xFFFF...FD` = array
- `0xFFFF...FC` = dict
- `0xFFFF...FB` = molecule (MỚI — kiểu riêng cho phân tử)
- `0xFFFF...FA` = closure

### §3 Register

```
r12 = bytecode base (bất biến)
r13 = program counter
r14 = VM stack pointer
r15 = heap pointer (bump allocator)
rbx = bytecode size (kiểm tra biên)
xmm0-15 = SIMD batch operations
```

### §4 Tập lệnh — 85 opcodes

**48 opcodes gốc** + **16 superinstructions** + **5 security** + **16 brain opcodes**

Opcodes mới quan trọng:
- `0x40-0x47`: Molecule (Pack, Unpack, Dist, Compose, Dominant, BatchDist, Encode, Decode)
- `0x50-0x55`: KnowTree (Store, Load, Nearest, Walk, Learn, Generate)
- `0x58-0x5B`: Silk (Fire, Decay, Walk, Implicit)
- `0x60-0x65`: Arena (AllocA, AllocB, AllocC, ResetC, ResetB, HeapPin)
- `0xA0-0xAF`: Superinstructions (LoadRegAdd, LoadReg2, TailCall, v.v.)
- `0xB0-0xB4`: Security (CapCheck, CapCreate, CapDelegate, CapRevoke, SecGate)

### §5 Định dạng bytecode

```
Header 48 bytes: magic "OLNG" + version + arch + flags + section offsets + checksum
Sections: Bytecode | Constant Pool | Function Table | Knowledge (tùy chọn) | Trailer
```

### §6 Hệ thống biến — var_matrix (GIẢI QUYẾT THE BOMB)

```
TRƯỚC:  var_table — scan ngược O(n), leak bộ nhớ vĩnh viễn → crash
SAU:    var_matrix — 65,536 slot × 16 bytes = 1MB cố định, O(1) mọi thứ

Scoping: generation counter
  Gọi hàm: gen++ | Return: gen--
  Entry với gen > current_gen → vô hình (không cần cleanup)
  → O(1) vào/ra scope
```

### §7 Molecular Engine — u16 native

```
P_weight = [S:4][R:4][V:3][A:3][T:2] = 16 bit = 65,536 trạng thái

Distance 5D = |ΔS| + |ΔR| + |ΔV|×2 + |ΔA|×2 + |ΔT|×4
  Scale factor bù cho bit-width khác nhau. Max = 70. Toàn số nguyên.

Compose(A,B) — KHÔNG giao hoán:
  S: max (hình lớn nhất thắng)
  R: trung bình có trọng Zipf (thứ tự quan trọng: "tôi yêu bạn" ≠ "bạn yêu tôi")
  V: khuếch đại (KHÔNG trung bình — cộng hưởng sinh học)
  A: max (1 tiếng ồn = cả phòng ồn)
  T: dominant (ổn định thắng)
```

### §8 KnowTree — kt_matrix

```
kt_matrix: u16[65,536] — molecule LÀ index
  Exact: O(1) | Nearest: O(243) = scan 5D láng giềng ±1 = O(1) constant
  Collision: linked list trên heap
  Fractal: bit 15 = 0 → leaf, bit 15 = 1 → sub-matrix → vô hạn depth
```

### §9 Silk Engine — silk_matrix

```
3 loại silk:
  Implicit (0 bytes) — tính từ distance 5D, 37 channels
  Hebbian (lưu trữ) — co-activate, weight update, decay φ⁻¹
  Structural (0 bytes) — vị trí trong chain = quan hệ

silk_matrix: u16[65,536] — hash(mol_a XOR mol_b) → edge index
  Fire: Δw = emotion_factor × (1 - w) × 0.1
  Decay: w × 618/1000 mỗi 24h (golden ratio)
  Silk walk: BFS theo dimension, follow edges mạnh nhất
```

### §10 Arena Allocator — 3 Zone

```
Zone A: VĨNH VIỄN — KnowTree, QR, strings. Không bao giờ giải phóng.
Zone B: SESSION — reset khi session kết thúc.
Zone C: TURN — reset sau mỗi pipeline cycle.

Không GC. Không fragmentation. Alloc = bump pointer (3 instructions).
Reset = restore pointer (1 instruction).
```

### §11 Array — O(1) Push

```
[capacity:8][count:8][elements...]
Push: if count < capacity → O(1). Else → realloc 2× (amortized O(1)).
Forward marker tại vị trí cũ khi relocate → redirect tự động.
```

### §12 String — UTF-8 Native, immutable, zero-copy substring

### §13 Function Calls — register frame, tail call optimization

### §14 Exception Handling — try/catch trên CPU stack, Zone C safe

### §15 Concurrency — Multi-Mouth (JARVIS)

```
1 brain (single-thread event loop) + N mouths (CLI, TCP 9100, HTTP 9000)
Request queue → brain xử lý tuần tự → response queue
Không multi-thread (tránh race condition trong ASM)
```

### §16 SIMD — SSE2 batch molecular distance

```
8 molecules/iteration. 500K mols ÷ 8 = 62,500 iterations.
~60 μs vs scalar ~2.5 ms = 40× speedup.
```

### §17 Tự sửa đổi

```
Chu kỳ: Inspect → Backup → Modify → Build → Test → Fixed-point → Commit/Rollback
Tối đa 1 file/chu kỳ. PHẢI backup. PHẢI test. PHẢI Gen1==Gen2.
Hot-reload tương lai: thay bytecode trong RAM, giữ Zone A.
Extension: tự định nghĩa builtin mới (slot 0x100-0x1FF).
```

### §18 Syscall — ~30 Linux syscalls, không libc

### §19 Security — bounds checking, SecurityGate 3 lớp

### §20 Boot — mmap 4GB → phân zone → clear matrix → load bytecode → vm_loop

### §21 Crypto — SHA-256 (1,460 LOC ASM), SHA-512, HMAC, AES-256-GCM, Ed25519

### §22 Debug — trace, inspect, breakpoint, performance counters

### §23 Mục tiêu hiệu năng

```
var_lookup:     O(n) → O(1)         | kt_nearest (500K):  ~50ms → ~0.06ms
array_push:     O(n²) → O(1)        | self_build:          ~60s → ~5s
boot (1500):    ~30s crash → ~2s ok  | pipeline (1 query):  ~100ms → ~10ms
```

### §24 Lộ trình di chuyển — 5 phase, mỗi bước PHẢI pass 4 checks

---

## PART II — TỐI ƯU NÂNG CAO (§25-§28)

### §25 Dispatch

- **Threaded dispatch**: mỗi handler tự dispatch ở cuối → 15-25% nhanh hơn
- **Superinstructions**: gộp cặp opcode phổ biến nhất → tới 4.55× speedup
- **Handler replication**: copy handler tại địa chỉ khác nhau → branch prediction tốt hơn
- **Hot/cold splitting**: `.text.hot` (top 20 handlers) vs `.text.cold` (hiếm dùng)
- **Quickening**: viết lại bytecode tại chỗ thành phiên bản chuyên biệt → 10-60%

### §26 Bộ nhớ

- **String interning**: deduplicate → equality = so sánh con trỏ O(1)
- **COW (Copy-on-Write)**: fork() cho multi-mouth → chia sẻ Zone A, 0 copy
- **mmap persistence**: mmap("nox_brain.dat") → lazy page-in → GIẢI QUYẾT boot blocker
  Boot: ~30s → ~0.1s (chỉ mmap, không parse)
- **Rope**: concat O(1), index O(log n) → cho text lớn

### §27 Tìm kiếm

- **Fibonacci hashing**: `(mol × 40503) >> 9` — 6× nhanh hơn modulo, không clustering
- **VP-Tree**: O(log n) nearest neighbor → 2,500× nhanh hơn linear scan cho 500K
- **LSH**: approximate nearest O(1) + O(bucket_size) → 250× speedup
- **Golden-section search**: interval giảm 0.618 mỗi bước (tối ưu cho unimodal)

### §28 Hebbian

- **Per-neuron traces**: 1 trace/node thay vì 1/edge → 100× giảm bộ nhớ
- **CSR (Compressed Sparse Row)**: cache-friendly, SIMD-able, compact
- **SADP**: linear-time learning O(N) thay vì O(N²)
- **Multiplicative update**: `Δw = η × w^μ × x` → tự cân bằng tải

---

## PART III — BẢO MẬT & ĐIỀU KHIỂN HỆ THỐNG (§29-§36)

### §29 Capability-Based Security

```
Mọi truy cập tài nguyên = cần token (capability) không thể giả mạo.
cap_table[256]: [object_type:1][object_id:4][permissions:2][owner:1]
Permissions: READ | WRITE | EXECUTE | DELEGATE | REVOKE | CREATE
Lấy cảm hứng từ seL4 (microkernel đã chứng minh hình thức).
```

### §30 Bảo vệ bộ nhớ

- **W^X**: trang nhớ KHÔNG BAO GIỜ vừa writable vừa executable
- **Guard pages**: PROT_NONE giữa các zone → overflow = SIGSEGV ngay
- **Stack canaries**: 8 bytes random mỗi frame, kiểm tra khi return
- **Internal ASLR**: random hóa địa chỉ zone bằng getrandom()
- **Secure key storage**: mlock + MADV_DONTDUMP cho trang chứa key

### §31 Seccomp-BPF — chỉ cho phép ~30 syscalls, kill process nếu vi phạm

### §32 Network Stack

- **Raw socket / TAP device**: truy cập Layer 2
- **TCP/IP stack tối thiểu**: parse Ethernet → IPv4 → TCP/UDP, static allocation
- **Firewall**: stateful inspection, connection table, BPF filtering
- **DNS**: UDP query đến nameserver:53, parse A record

### §33 Hardware — GPIO (sysfs), I2C (/dev/i2c-N), SPI (/dev/spidevN.N), USB direct

### §34 Process Isolation — Linux namespaces (PID, Mount, Network, User) + cgroups v2

### §35 Secure IPC

- Unix domain socket + SO_PEERCRED (kernel xác thực PID/UID)
- HMAC-SHA256 mọi message: [length:4][sequence:4][payload:N][hmac:32]
- memfd_create + sealing → shared memory bất biến, zero-copy

### §36 Phát hiện xâm nhập

- Hash code region định kỳ (SHA-256), phát hiện tampering
- Shadow call stack: stack return address riêng biệt → chống ROP
- Anti-debug: ptrace self-check, TracerPid, timing check
- Watchdog: process riêng, kiểm tra integrity mỗi 60s

---

## PART IV — TÍCH HỢP NÃO / SPEC_E (§37-§44)

### §37 Capture đa phương thức

- Camera (V4L2): Sobel edge → shape_count → S, symmetry → R, warmth → V, saturation → A, motion → T
- Audio (ALSA): RMS → A, ZCR → T, stability → R
- /proc: cpu_load → A, error_rate → V, process_count → R
- Holistic: compose(text, vision, audio, intero) → 1 mol → pipeline

### §38 Silk ba vai trò — Phân loại + Định vị + Liên kết

### §39 Chain Recombination (SINH) — tạo nội dung MỚI

```
Encode query → dominant dim → silk walk → collect nodes → compose NEW chain → decode
Câu mới CHƯA BAO GIỜ tồn tại trong KnowTree.
Như DNA recombination: gen cha + gen mẹ → con mới.
```

### §40 Vòng đời bộ nhớ

- **STM**: 32 slot, eviction scoring (access×0.3 + emotion×0.4 + recency×0.3)
- **WM**: 4 slot (query, context, candidate, result) — reset mỗi response
- **Dream**: trigger bởi Fibonacci fire_count / idle > 5min / heap > 80%

### §41 Self-Model — bản đồ tri thức, confidence per domain

### §42 NAC.mb 30 algorithms — pruning, perturbation, negative knowledge, archive, swarm

### §43 Conversation Curve — tone từ V'(t) và V''(t)

```
V' < -1 → Supportive | V'' < -2 → Pause | V' > 1 → Reinforcing
V'' > 2 AND V > 4 → Celebratory | V < 2, stable → Gentle | else → Engaged
```

### §44 Homeostasis — Free Energy F(t)

```
F > φ⁻¹ → Learning mode (tăng learning rate, dream nhiều hơn)
F < φ⁻¹ → Acting mode (trả lời tự tin, walk ngắn)
```

---

## PART V — HỖ TRỢ PIPELINE / BP5 (§45-§50)

### §45 Activation Matrix (M7)

```
act_matrix: u16[65,536] = 128KB — activation level cho Spreading Activation
SIMD batch decay: 8 values/iteration, 65,536 values trong ~8 μs
__act_top_k: tìm K mol có activation cao nhất
```

### §46 CLONALG — immune selection, deterministic pseudo-random, chain mutation

### §47 DCA — danger signals (Safe vs Danger), dimensional jump detection

### §48 Decode ∂ — reverse lookup (mol → text), Maximal Join (merge facts)

### §49 Quality function — validity×0.3 + (1-entropy)×0.3 + consistency×0.2 + silk×0.2

### §50 Pipeline orchestration — full flow 5 layers with 5 checkpoints

---

## PART VI — LÝ THUYẾT & THAM KHẢO (§51-§53)

### §51 Lý thuyết tính toán phân tử — CRN, SDF như metric universal, dual-rail encoding

### §52 Tiến hóa VM — genetic algorithms tối ưu tham số, tiến hóa tập lệnh

### §53 Tham khảo — 21 papers (Ertl & Gregg, Collins & Loftus, De Castro, Greensmith, Sowa, v.v.)

---

## SỐ LIỆU TỔNG QUAN

```
Tổng sections:     53
Tổng opcodes:      85 (48 gốc + 16 super + 5 security + 16 brain)
Tổng builtins:     512 slots (256 gốc + 256 extension)
Tổng matrices:     5 (var 1MB + kt 128KB + silk 128KB + act 128KB + rev 128KB)
Tổng zones:        3 (A permanent + B session + C turn)
Tổng syscalls:     ~30 (allowlisted via seccomp-BPF)
Tổng crypto:       SHA-256, SHA-512, HMAC, AES-256-GCM, Ed25519
Binary hiện tại:   833KB | Mục tiêu: < 1MB
Tests hiện tại:    193/194 | Mục tiêu: 194/194
```
