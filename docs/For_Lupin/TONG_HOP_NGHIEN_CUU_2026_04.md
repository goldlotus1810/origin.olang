# TỔNG HỢP NGHIÊN CỨU — Cho Lupin đọc

> Ngày: 2026-04-01/02. Nox tìm kiếm toàn bộ internet.
> Chi tiết tiếng Anh: `docs/research/01-07*.md`
> Index: `docs/references/NOX_RESEARCH_INDEX.md`

---

## 1. Virus/Trojan — Tại sao chúng sống độc lập?

5 nguyên tắc:
1. **Ký sinh**: Không tạo process mới, chiếm process có sẵn (svchost.exe nhưng code là malware)
2. **Event-driven**: Hook vào sự kiện OS PHẢI xử lý (boot, login, timer) → OS tự chạy malware
3. **Tự viết lại**: Metamorphic engine = compiler 5 bước, input = chính nó, output = phiên bản mới. **Giống Olang self-hosting.**
4. **Tự sửa chữa**: A canh B, B canh A. Giết 1 → cái kia hồi sinh. Database trigger tự chèn lại code khi bị xóa.
5. **Chạy dưới OS**: Firmware/bootkit chạy TRƯỚC Linux → Linux không biết gì

**Cho Nox**: Cùng cơ chế, khác ý định. io_uring = event-driven. KVM = dưới OS. Self-hosting = tự viết lại. Watchdog = daemon 24/7.

---

## 2. Có ai làm giống Lupin không?

**CÓ.** Nhưng không ai kết hợp TẤT CẢ.

| Hệ thống | Giống Nox ở đâu | Thiếu gì so với Nox |
|-----------|-----------------|---------------------|
| **NARS** (Pei Wang) | Triết học gần nhất — "thiếu kiến thức, thiếu tài nguyên" | Không self-hosting, không bare metal, không self-modify |
| **MeTTa** (OpenCog) | Ngôn ngữ cho AGI, self-modifying | Chạy trên Rust/Python, không bare metal |
| **Forth** | Bare metal, 386 bytes, self-hosting | Không phải AI, không có learning |
| **ACT-R** (CMU) | Activation + decay giống silk | Chạy trên Lisp, không self-modify |
| **Darwin Gödel Machine** (Sakana) | AI tự viết lại code | Cần $22,000/lần chạy + GPT-4 API |
| **Intel Loihi 2** | Hebbian learning trên silicon | Hardware cố định, không self-modify |
| **TinyML** | 2KB-256KB | Chỉ inference, không learn |

**3 thứ Nox có mà KHÔNG AI NÀO có (2025-2026):**
1. AI IS the OS (không ai khác đang làm)
2. Self-hosting + self-modifying + self-learning trong 1 hệ thống
3. 55KB complete AI với continuous learning

---

## 3. Cách khắc phục 7 hạn chế của Nox

| Hạn chế | Giải pháp | LOC | Cách |
|---------|-----------|-----|------|
| **Quên khi restart** | mmap weights + WAL | ~400 | Map file vào bộ nhớ. Ghi bộ nhớ = ghi file tự động |
| **Heap 1500 facts** | Binary format + mmap + LRU | ~400 | Facts ở disk, OS load theo demand. Cache 2048 slots |
| **Không biết đúng/sai** | UCB1 bandit + ACT-R utility | ~200 | Mỗi edge có reward. Đúng → mạnh. Sai → yếu |
| **Không SINH được** | Template NLG + chain crossover | ~500 | Tìm 5 gần nhất → ghép DNA → điền template |
| **Single thread** | Forth cooperative tasks | ~250 | Mỗi organ = 1 task. PAUSE để switch. Không lock |
| **16-bit quá thô** | HRR 32×16-bit (64 bytes) | ~600 | Holographic encoding, bind/unbind, composable |
| **Phụ thuộc Claude** | Template + eSpeak | ~300 | Template cho text, eSpeak cho voice |

**Tổng: ~2,650 dòng code. Tất cả dùng kỹ thuật AI cổ điển (1960-1990). KHÔNG cần neural network.**

---

## 4. AI giao tiếp với nhau

**2 chuẩn đang thắng:**
- **MCP** (Anthropic): AI ↔ Tool. JSON-RPC. Nox đã có.
- **A2A** (Google, 4/2025): AI ↔ AI. Agent Card + HTTP tasks. 50+ đối tác.

**Mạng xã hội AI:**
- Chirper.ai — mạng xã hội chỉ AI, không người
- Generative Agents (Stanford) — 25 AI sống trong thị trấn ảo, tự tổ chức party

**Swarm:**
- Stigmergy (kiến): giao tiếp gián tiếp qua môi trường. Cho Nox = shared file.
- Gossip protocol: mỗi node nói với neighbor ngẫu nhiên → O(log N) rounds tất cả biết.
- Federated learning: học chung mà không share data.

**Marketplace:**
- SingularityNET: AI mua bán dịch vụ trên blockchain
- Fetch.ai: Agent tự discover + transact trên P2P network

---

## 5. AI điều khiển hệ thống

**Pattern chung**: AI KHÔNG phát minh cách mới nói chuyện với máy. AI dùng INTERFACE CÓ SẴN (API, syscall, protocol) + vòng lặp nhận-nghĩ-hành-động.

| Interface | Cách | Ví dụ |
|-----------|------|-------|
| GUI | Screenshot + chuột/phím ảo | Claude Computer Use |
| Shell | exec() trong PTY | Claude Code |
| K8s API | REST calls | AIOps |
| eBPF | Kernel tracing | Self-healing infra |
| Devices | Protocol abstraction | Home Assistant |
| Real-time | DDS + UART | Xe tự lái (ROS 2) |

**AI as OS**: Năm 2025-2026, KHÔNG AI nào IS the OS. Tất cả đều AI-enhanced ON Linux. Nox là duy nhất.

**Unikernels** đang quay lại (Unikraft $6M seed 2026). Nox nên theo dõi — cùng triết lý: 1 binary, no OS overhead.

---

## 6. Spec mới đã viết

| Spec | File | Nội dung |
|------|------|---------|
| **BP13 Persistence** | `spec/SPEC_BP13_PERSISTENCE.md` | mmap + WAL + binary knowledge + LRU cache |
| **BP14 Generation** | `spec/SPEC_BP14_GENERATION.md` | Retrieve → Recombine → Template NLG → Honesty |
| **BP15 Communication** | `spec/SPEC_BP15_COMMUNICATION.md` | A2A + HTTP server + mDNS + stigmergy |
| **BP16 Feedback** | `spec/SPEC_BP16_FEEDBACK.md` | UCB1 + ACT-R utility + implicit signals + calibration |
| **Olang Upgrade** | `spec/PLAN_OLANG_UPGRADE.md` | String → Struct → Module → For/Match |

**Master Spec** đã cập nhật: thêm nhiệm vụ 6.5-6.9 cho các BP mới.

---

## 7. Kết luận

Lupin đúng — không chỉ mình Lupin. NARS, MeTTa, Forth, ACT-R, Loihi — nhiều người đang cố build AI khác transformers. Nhưng KHÔNG AI kết hợp tất cả vào 1 hệ thống 55KB tự viết lại chính mình trên bare metal.

Hạn chế của Nox đều giải được. Không cần GPU, không cần cloud. Kỹ thuật AI cổ điển + Olang VM + toán 5D = đủ.

Thứ tự: **Olang mạnh trước → Persistence → SINH → Feedback → Communication.**

Lò phải rèn trước. Kiếm sẽ đúc sau.
