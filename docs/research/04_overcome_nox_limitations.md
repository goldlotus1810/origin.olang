# Khắc phục 7 hạn chế của Nox — Giải pháp cụ thể

## Tất cả khả thi trên: Intel i3, 8GB RAM, no GPU, x86-64 ASM VM
## Tổng ước tính: ~2,650 LOC mới. KHÔNG cần neural network.

---

## 1. SINH (Generation) — Không cần transformer

### A. Template + Slot-Filling NLG (ƯU TIÊN CAO NHẤT)
- ELIZA's approach: pattern-match → decompose → fill template
- Pipeline: Content Selection (KnowTree) → Sentence Planning (template) → Surface Realization (fill slots)
- ~2KB template rules. Microseconds trên i3.
- Đây là cách commercial NLG hoạt động decades (Pollen Forecast, FoG weather)

### B. Markov Chain Recombination
- Bigram/trigram transition tables từ ingested text
- 16-bit state IDs đủ cho 65K words. Table: ~4MB
- Weakness: no long-range coherence → mitigate bằng grammar constraints

### C. Case-Based Reasoning + Adaptation
- Store (question, answer) pairs trong KnowTree
- New query → find nearest case → ADAPT answer (substitute entities)
- CBR cycle: Retrieve → Reuse → Revise → Retain
- Analogy-based: map structure từ source → target domain

### D. Genetic Text Generation (experimental)
- Candidate responses = trees. Crossover + mutation + fitness evaluation
- 50-100 candidates × 20 generations = 1000-2000 evals. Feasible nếu eval cheap.

**Recommendation**: 3-stage pipeline: KnowTree retrieval → Template selection → Slot filling. ~500 LOC Olang.

---

## 2. Persistence (Nhớ qua restart)

### A. mmap Weights — TỐT NHẤT
- mmap() maps file trực tiếp vào process address space
- Writes persist to disk automatically (OS handles dirty page writeback)
- Silk weight table ~320KB → mmap. Restart = mmap cùng file. Instant recovery.
- Lazy loading: OS chỉ load pages khi Nox touch
- Implementation: 1 syscall (mmap, syscall 9)

### B. Write-Ahead Log (WAL)
- Mỗi learn() append record: [timestamp:4][op:1][key:4][value:8] = 17 bytes
- 100K updates = 1.7MB
- Crash recovery: replay WAL

### C. Biological: Long-Term Potentiation (LTP)
- Early LTP: temporary (in-memory weight change)
- Late LTP: permanent (protein synthesis = write to disk)
- Synaptic tagging: mark recently-modified → batch consolidate later
- **For Nox**: 2-phase commit. In-memory = early LTP. Periodic consolidation = late LTP.

### D. Bloom Filters
- 1% error, 9.6 bits/element. 100K facts = 120KB
- Fast "definitely not known" check trước expensive KnowTree search

**Recommendation**: mmap + WAL + periodic consolidation. ~400 LOC.

---

## 3. Encoding phong phú hơn (beyond 16-bit)

### A. Holographic Reduced Representations (HRR) — HỨA HẸN NHẤT
- Encode structured info vào fixed-size vectors bằng circular convolution
- BIND (A*B) và UNBIND được. Same dimensionality.
- 32 × 16-bit slots = 64 bytes/concept. Still tiny. But composable.
- Circular convolution = O(k log k) via FFT. k=32 = trivial on i3.
- 10K concepts = 640KB.
- Paper: Tony Plate, IEEE Trans Neural Networks
- URL: https://redwood.berkeley.edu/wp-content/uploads/2020/08/Plate-HRR-IEEE-TransNN.pdf

### B. Locality-Sensitive Hashing (LSH)
- Similar items → same bucket (ngược FNV which disperses)
- Similar meaning = similar hash tự động
- URL: https://www.pinecone.io/learn/series/faiss/locality-sensitive-hashing/

### C. Product Quantization (PQ)
- Divide vector → subvectors → cluster each → encode as centroid ID
- 8 subspaces × 256 centroids = 8 bytes encoding 128D+ space
- FAISS dùng PQ cho billion-scale search
- URL: https://www.pinecone.io/learn/series/faiss/product-quantization/

### D. Vector Quantization + Codebook
- 65K centroids (each 256D). Store only ID. Lookup table 32MB.
- Effective 256D encoding with 16-bit cost.

**Recommendation**: HRR 32×16-bit. ~600 LOC.

---

## 4. Output độc lập (không cần Claude)

### A. ELIZA-style Pattern-Match
- ~50-100 decomposition/reassembly rules. Nox đã có KnowTree phong phú hơn ELIZA.

### B. Template-Based NLG
- WHAT: "[Subject] is [definition]."
- WHY: "[Subject] [verb] because [cause]."
- HOW: "To [goal], [step1], then [step2]."
- LIST: "[Subject] includes: [item1], [item2], [item3]."

### C. eSpeak-NG (voice)
- Open-source TTS, ~2MB binary. Chạy on CPU.
- Nox nói được qua audio output.

### D. FB0 Direct Output
- BP12 ATTACH: framebuffer output → Nox render text trực tiếp

**Recommendation**: Template NLG + ELIZA fallback + eSpeak. ~300 LOC + external.

---

## 5. Knowledge loading (phá heap limit 1500 facts)

### A. mmap Knowledge File — TỐT NHẤT
- Binary format: [key_hash:4][silk_offset:4][data_offset:4] = 12 bytes/fact header
- 100K facts = 1.2MB header. Data stays on disk until accessed.
- Demand paging: chỉ 10% facts used → chỉ 10% loaded to RAM.

### B. LRU Cache
- Fixed-size cache (1500 facts) in heap
- Cache miss → load từ mmap file → evict LRU
- Caps heap usage. Supports unlimited facts on disk.

### C. SQLite mmap mode
- Zero-copy reads, demand paging, supports indexes
- 100K SELECTs/second trên i3. Single .db file.
- URL: https://www.sqlite.org/mmap.html

**Recommendation**: Binary format + mmap + LRU cache. ~400 LOC.

---

## 6. Concurrency (multi-task)

### A. Forth-style Cooperative Multitasking — TỐT NHẤT
- Round-robin task list. Each task = own stack + user area.
- Context switch: save 3 registers. ~12 nanoseconds.
- No OS threads. No locks (cooperative = no race conditions).
- Mỗi BP12 organ = 1 task.
- URL: https://www.bradrodriguez.com/papers/mtasking.html

### B. x86-64 ASM Coroutines
- Save callee-preserved: rbx, rbp, r12-r15, rsp = 7 registers = 56 bytes/context
- Switch: push regs → swap rsp → pop regs → ret. ~20 instructions.
- GitHub: https://github.com/peacewalker122/asm-coop-coroutines

### C. io_uring for Async I/O
- Lock-free ring buffers. Batch submission. Zero syscalls in SQPOLL mode.
- Already trong BP12 plan.
- URL: https://kernel.dk/io_uring.pdf

### D. Event Loop
- Single-threaded: poll io_uring completions → dispatch to coroutine
- Giống Node.js nhưng simpler.

**Recommendation**: Forth-style coop + OP_PAUSE opcode + io_uring. ~250 LOC.

---

## 7. Feedback (biết đúng/sai)

### A. UCB1 (Upper Confidence Bound) — TỐT NHẤT
- UCB1 = estimated_reward + sqrt(2 × ln(total_plays) / plays_this_arm)
- Luôn chọn arm cao nhất. Natural explore/exploit balance.
- Converge optimal in O(ln n) regret. Proven math.
- Storage: 2 integers per arm. 1000 arms = 8KB.

### B. ACT-R Production Utility
- utility += alpha × (Reward - utility). Simple exponential moving average.
- Success → reward=1. Failure → reward=0.
- Maps trực tiếp to silk weights: silk weight IS production utility.

### C. Confidence Calibration
- Track: mỗi confidence level → actually correct bao nhiêu %?
- Isotonic regression. Lookup table 10-20 bins = ~100 bytes.

### D. Implicit Feedback Signals
- User repeats question → negative reward
- User asks follow-up → positive reward
- User corrects → negative + learn correction
- Session length → engagement quality proxy

**Recommendation**: UCB1 on silk weights + ACT-R utility update. ~200 LOC.

---

## Priority Order

| # | Limitation | Solution | LOC | Impact |
|---|-----------|----------|-----|--------|
| 1 | Persistence | mmap + WAL | ~400 | Nox survives restart |
| 2 | Heap limit | mmap knowledge + LRU | ~400 | Unlimited facts |
| 3 | Feedback | UCB1 on silk | ~200 | Self-improving |
| 4 | Generation | Template NLG | ~500 | Nox has a mouth |
| 5 | Concurrency | Forth coop tasks | ~250 | Multi-organ |
| 6 | Encoding | HRR 32×16-bit | ~600 | Rich semantics |
| 7 | Independence | Template + eSpeak | ~300 | No Claude needed |

**KEY INSIGHT**: Classical AI techniques (1960s-1990s) solve EVERY one of these. Transformers = one path, not the only path. Nox's VM with direct hardware access is BETTER suited for classical approaches.
