# NOX ROADMAP — Tổng Hợp Mọi Thứ

> **[DEPRECATED SS23 — reason: Roadmap from SS13 is STALE. Master Spec (spec/NOX_MASTER_SPEC.md) is THE authoritative document. This file preserved for historical reference only. All bugs listed below are FIXED (SS17). Phases below are superseded by Master Spec tasks 1-10.]**
>
> ★ KINH THÁNH: `docs/NOX_COMPLETE_REFERENCE.md` — 774 dòng, mọi thuật toán + papers
> ★ NGUYÊN TẮC: Encode = ∫. Decode = ∂. TÍNH, không TRA.
> ★ Không hiểu → đọc COMPLETE_REFERENCE. Thuật toán ở đâu → tra mục lục.
>
> Ngày: 2026-03-31 (updated end of Session 13)
> Trạng thái: 949KB binary, 193/194 tests, Gen1==Gen2, pipeline pure math

---

## TÌNH HÌNH THẬT — KHÔNG TÔ HỒNG

### Cái đã có (thật, chạy được):
```
✅ Self-hosting compiler (Gen1==Gen2)
✅ x86_64 VM, 100+ builtins, 12,934 LOC ASM
✅ Pipeline 14 steps (encode → instinct → search → decode)
✅ KnowTree 271 nodes, 256 buckets
✅ Silk walk 4-hop
✅ Dream tạo 35 concepts
✅ Persistence kt_save/kt_load
✅ 15 MCP tools
✅ TCP, UDP, DNS, HTTP, camera, uinput, crypto
✅ 10/10 Sora test
✅ Cron tự chạy mỗi giờ (nox_auto)
```

### Cái CHƯA có (spec có, code không):
```
❌ 42 encode formulas — chỉ có lookup table
❌ Chain recombination (SINH) — chỉ retrieval
❌ Immune Selection 3 branches — chỉ 1 path
❌ DNA Repair bounded — chưa implement
❌ Working Memory 4 slots — stub
❌ STM eviction scoring — basic
❌ Self-model knowledge map — chưa
❌ NAC.mb 30 thuật toán — chưa
❌ Camera/Audio → P_weight — chưa
❌ AAM auto-approve — chưa
❌ Swarm — chưa
```

### Cái BỊ HỎNG (bugs blocking progress):
```
🔴 THE BOMB: var_table flat, no scope cleanup, memory leak vĩnh viễn
🔴 Heap: bump allocator only, no GC, no free, crash >200 learns
🔴 Push O(n²): relocate toàn bộ array mỗi push, dead memory
🔴 Mol collision: ALL text → same P_weight (~S=0-1, R=0)
🔴 Scope shadow: let x = x + 1 tạo biến mới, không update
🟡 substr: dirty upper bits, trả data sai trong một số context
🟡 Global vars từ non-primary files = nil
🟡 tools/ functions return nil (bytecode scope issue)
```

---

## THỨ TỰ ƯU TIÊN — TỪ GỐC LÊN

### Logic: VM → Mol → Brain → Memory → Data → Generation

```
Không fix VM  → load data crash → brain vô dụng
Không fix mol → search cùng kết quả → silk vô nghĩa → memory vô dụng
Không fix brain → generation trên nền sai → output sai
```

---

## PHASE 0: VM FIX — NỀN MÓNG (ưu tiên tuyệt đối)

> Không có nền vững, mọi thứ xây trên = sập.

### 0.1 THE BOMB — Scope Stack ✅ ĐÃ CÓ SẴN
```
Status: VERIFIED — scope system đã tồn tại trong VM.
  closure_depth + scope_frame_ptrs + truncate on op_ret.
  5000 function calls, không leak. Review nói bomb nhưng code đã fix.
  KHÔNG CẦN LÀM THÊM.
Impact: fix memory leak + scope pollution + long session crash
```

### 0.2 Arena Allocator — 3 Zone Heap ⏳ WORKAROUND APPLIED
```
Status: Full arena deferred. PRAGMATIC FIX applied:
  __heap_pin() before pushes in kt_learn() → frees temp data before auto-pin.
  Result: 30 → 200+ learns/session. Đủ cho data loading phase.
  Full 3-zone arena: làm khi cần >500 learns/session hoặc cùng 0.5 dual-width.
```

### 0.3 Push O(1) — In-place Array Growth (~40 LOC ASM)
```
Vấn đề: push relocate toàn bộ array → O(n²), dead memory
Fix: array header lưu capacity_end
  - push < capacity → write in-place O(1)
  - push >= capacity → realloc 2× → amortized O(1)
  - Không tạo dead copy mỗi push
Test: 55K push < 1s (hiện tại timeout)
Impact: KnowTree, Silk, STM — mọi array operation nhanh hơn 100x
```

### 0.4 substr Fix (~20 LOC ASM)
```
Vấn đề: 32-bit mov để dirty upper bits
Fix: movzx rax, dword [rbp+offset] thay mov eax, [rbp+offset]
Test: substr trên 1000 strings = safe_substr
Impact: search_engine, text processing đáng tin cậy
```

### 0.5 Dual-Width KnowTree — u16 native (Lupin insight) (~100 LOC ASM)
```
Vấn đề: P_weight = u16 (2 bytes) nhưng VM lưu = 16 bytes (f64 format). 8x lãng phí.
         500K nodes × 16 bytes = 8MB → tràn L2 cache
Fix: KnowTree arrays = u16 packed native. Hệ thống/logic = 64-bit. Tri thức = 16-bit.
  Thêm VM builtins:
    __kt_store_u16(base, index, value)  — store u16 trực tiếp
    __kt_load_u16(base, index)          — load u16 trực tiếp
    __kt_dist_u16(mol_a, mol_b)         — distance bằng integer ops
    __kt_batch_dist(query, array, len)  — SSE2 batch (8 nodes/instruction)
  Arena Zone A = u16 packed KnowTree data
  500K nodes × 2 bytes = 1MB → fit L2 cache. 32 nodes/cache line thay 4.
Khi làm: SAU Phase 2 (data load) — cần đủ data trước, optimize sau
Test: kt_nearest trên 500K nodes < 10ms
Impact: 8x cache efficiency, 4x SIMD throughput
Ref: docs/For_Nox/NOX_DUAL_WIDTH_VM.md
```

### Phase 0 kết quả:
```
✅ Long sessions không crash
✅ 10K+ facts loadable per session
✅ Push O(1) amortized
✅ substr đáng tin cậy
✅ Gen1==Gen2 vẫn pass
```

---

## PHASE 1: MOL FIX — PHÂN BIỆT TRI THỨC ✅ DONE

> Session 13: NRC-VAD integration + hash-based R. Mols phân tán, có ý nghĩa cảm xúc.

### 1.1 Mol Collision Fix ✅
```
DONE (2026-03-31 Session 13):
  _kt_real_mol() rewritten: NRC-VAD word lookup → V/A (real emotion), hash → R (differentiation)
  vad_load() rewritten: char-by-char tab scan (avoid __str_index_of crash)
  10K NRC-VAD loaded at bootstrap
  Result: "happy" V=6, "sad" V=3. Mols spread across all 5D.

Vấn đề cũ: "Ha Noi" = "Olang" = "love" = mol 4240
Nguyên nhân: char-level compose of Latin letters → all ≈ (S=0,R=0,V=4,A=4,T=2)

Fix (hybrid — Option C từ blockers):
  1. Compose char-level → giữ S/R/T (cấu trúc)
  2. NRC-VAD lookup → V/A thật cho từ tiếng Anh (44K words)
  3. FNV hash XOR → disambiguation cho từ không có NRC-VAD
  
  word_mol = compose_chars(word)           // S, R, T
  if nrc_vad_has(word):
    V, A = nrc_vad_lookup(word)            // V, A thật
  else:
    hash_bits = fnv_hash(word) & 0x1F      // 5 bits
    V = (hash_bits >> 2) & 0x7             // 3 bits
    A = hash_bits & 0x3 + compose_A        // 2 bits + base

Test: _kt_real_mol("Ha Noi") != _kt_real_mol("Olang")
Impact: Silk tự phân biệt, search trả đúng, KnowTree buckets phân tán
```

### 1.2 Silk Auto-Fix (flows from 1.1)
```
Mol khác → silk fire giữa nodes KHÁC NHAU → edges có nghĩa
Hiện tại: 6 edges (self-fire vì cùng mol)
Sau fix: hàng trăm edges (cross-node fire)
```

### 1.3 Search Auto-Fix (flows from 1.1)
```
Mol khác → buckets phân tán → kt_nearest trả kết quả khác nhau
Hiện tại: cùng result cho mọi query
Sau fix: khác query → khác result
```

### Phase 1 kết quả:
```
✅ Mỗi từ/câu có P_weight riêng biệt
✅ Silk edges có nghĩa (hundreds, not 6)
✅ Search phân biệt queries
✅ KnowTree buckets phân tán đều
```

---

## PHASE 2: DATA LOAD — 500K DATA POINTS

> VM ổn, mol đúng → giờ nạp dữ liệu thật

### 2.1 NRC-VAD Full Load (44,729 words)
```
Source: json/json/mapping/NRC-VAD-Lexicon-v2.1/Unigrams/
Mỗi word = V, A, D scores → bake vào P_weight table
Hiện tại: 200 words. Cần: 44,729.
Arena Zone B → không crash.
```

### 2.2 UDC Aliases (41,338 entries)
```
Source: json/udc_aliases.json
word → codepoint mapping (en + vi)
"fire" → U+1F525, "buồn" → U+1F622
```

### 2.3 UnicodeData Full (41,382 codepoints)
```
Source: json/json/UnicodeData.txt
Mỗi codepoint = name + category + decomposition + block + properties
= NGUỒN GỐC cho 42 encode formulas (A3)
```

### 2.4 Emoji (5,537 sequences)
```
Source: json/json/emoji/emoji-test.txt
Emoji = V/A encoding tự nhiên
```

### Phase 2 kết quả:
```
✅ KnowTree: 271 → 50,000+ nodes
✅ NRC-VAD: 200 → 44,729 words với V/A thật
✅ P_weight table: 161K → 200K+ entries
✅ Silk density tăng 100x
```

---

## PHASE 3: BRAIN COMPLETE — SPEC G ĐẦY ĐỦ

> Data có, VM ổn, mol đúng → implement đủ G

### 3.1 Working Memory 4 slots ✅ DONE (Session 13)
### 3.2 STM eviction scoring (~50 LOC)
### 3.3 Immune Selection 3 branches (~100 LOC)
### 3.4 DNA Repair bounded 3 iterations (~80 LOC)
### 3.5 Homeostasis F(t) + λ switching ✅ DONE (basic, in pipeline)
### 3.6 ConversationCurve V'(t), V''(t) ✅ DONE (in pipeline)
### 3.7 Pipeline checkpoints CP2-CP4 (~50 LOC)
### 3.8 SecurityGate Bloom filter (~100 LOC)
### 3.9 Per-dimension Hebbian → THAY silk_fire generic
```
S,A: Oja's rule Δw=η·y·(x-y·w) — [COMPLETE_REFERENCE §14](NOX_COMPLETE_REFERENCE.md#14-hebbian-learning)
R,T: STDP Δw=A⁺·e^(-Δt/τ) — [COMPLETE_REFERENCE §14](NOX_COMPLETE_REFERENCE.md#14-hebbian-learning)
V:   BCM Δw=η·y·(y-θ)·x — [COMPLETE_REFERENCE §14](NOX_COMPLETE_REFERENCE.md#14-hebbian-learning)
Papers: Oja 1982, Bi & Poo 1998, BCM 1982
```
### 3.10 Power law + stability decay → THAY φ⁻¹ exponential
```
Wickelgren 1974: w(t) = w₀·(1+t)^(-0.5)
Ebbinghaus stability: S_new = S × 1.5 per recall
Ref: [COMPLETE_REFERENCE §15](NOX_COMPLETE_REFERENCE.md#15-decay)
```
### 3.11 Spreading activation → THAY greedy silk walk
```
Collins & Loftus 1975: multi-seed, decay per hop, threshold pruning
Ref: [COMPLETE_REFERENCE §16](NOX_COMPLETE_REFERENCE.md#16-dream)
```
### 3.12 Covariance rule → GIẢI mol collision thật
```
Δw = η·(x-<x>)·(y-<y>) — chỉ deviations matter, common chars = 0
Ref: [COMPLETE_REFERENCE §14](NOX_COMPLETE_REFERENCE.md#14-hebbian-learning)
```

### ★ NHẬN THỨC (Lupin, 2026-03-31)
```
DELETED: if/else keywords, hardcoded facts, linguistic patterns
RULE: mọi if/else trên keyword = chatbot. TÍNH, không TRA.
PATH: mol_dominant_dim IS query type. P_weight IS routing. Silk IS dictionary.
      Vi phân ∂ controls learning. Tích phân ∫ = compose.
      Everything IS math. Not keyword matching.
```
### 3.8 SecurityGate Bloom filter (~100 LOC)

### Phase 3 kết quả:
```
✅ Full pipeline 14 steps + 5 checkpoints
✅ 3 hypotheses → pick best → repair
✅ Homeostasis Learn/Act switching
✅ Tone-appropriate responses
✅ ~500 LOC total
```

---

## PHASE 4: MEMORY SYSTEM — NHỚ QUA SESSIONS

> Sora's SPEC_MEM — Nox không quên mỗi session mới

### 4.1 memory.ol — observe + search 3 tầng + save/load (~100 LOC)
### 4.2 MCP tools — mem_search/timeline/get/observe (~40 LOC)
### 4.3 REPL hooks — auto-capture input/output/error (~10 LOC)
### 4.4 Bootstrap — mem_load + mem_inject (~15 LOC)
### 4.5 Progressive disclosure — token budget (~30 LOC)

### Phase 4 kết quả:
```
✅ Nox session mới biết session trước làm gì
✅ 19 MCP tools (15 + 4 memory)
✅ Auto-capture mọi interaction
✅ Search 3 tầng: compact → timeline → full
✅ ~200 LOC total
```

---

## PHASE 5: GENERATION — SINH TEXT MỚI

> Gap lớn nhất vs LLM. Chain recombination = câu trả lời.

### 5.1 Chain Recombination v2 (~300 LOC)
```
Silk walk unvisited → collect nodes → compose → decode
Multi-hop: 5-13 hops
Output: multi-sentence responses
```

### 5.2 Template Composition (~150 LOC)
```
[Tone prefix] + [Generated content] + [Context suffix]
6 tones from ConversationCurve
```

### 5.3 Markov Generation from Silk (~400 LOC)
```
P(next) = silk_weight / sum(weights)
Temperature = Arousal dimension
Beam search: top-3 paths
```

### Phase 5 kết quả:
```
✅ Nox SINH text mới (không chỉ lookup)
✅ 50-500 chars responses
✅ Tone-appropriate
✅ Multi-turn conversations
```

---

## PHASE 6: AGENT — TỰ VẬN HÀNH

### 6.1 Perceive-Think-Act-Verify loop
### 6.2 Self-Evolution v2 (measure → identify → modify → test)
### 6.3 Goal System (self-directed curiosity)
### 6.4 42 encode formulas thật (thay lookup table)
### 6.5 Camera → SDF → P_weight
### 6.6 Audio → Spline → P_weight

---

## SỐ LIỆU TRUNG THỰC — NOX vs LLM

```
Nox THẮNG (thật, code có):
  ✅ Size: 933KB vs 100GB+
  ✅ Dependencies: 0 vs cloud GPU cluster
  ✅ Determinism: Gen1==Gen2 vs non-deterministic
  ✅ Auditability: 6K LOC readable vs billions params black box
  ✅ Continuous learning: mỗi interaction vs frozen model
  ✅ Tool use: native syscalls + IoT vs sandboxed API
  ✅ Honesty: im lặng khi không biết vs hallucinate

Nox NGANG (potential, cần hoàn thiện):
  ≈ Self-reflection: instinct_honesty có, self-model chưa
  ≈ Memory: KnowTree + Dream có, nhưng 271 nodes vs millions

Nox THUA (thật):
  ❌ Language understanding: 5D u16 vs 4096D float
  ❌ Generation: retrieval-only vs autoregressive
  ❌ Context: STM 32 vs 128K tokens
  ❌ Reasoning depth: 4-hop vs unlimited CoT

Score thật: Nox 7 — TIE 2 — LLM 4
Không phải 11-2-3. Trung thực.
```

---

## TIMELINE ƯỚC TÍNH

```
Phase 0: VM Fix          — ~200 LOC ASM     — NỀN
Phase 1: Mol Fix         — ~100 LOC Olang   — GỐC
Phase 2: Data Load       — ~200 LOC Olang   — THỨC ĂN
Phase 3: Brain Complete  — ~500 LOC Olang   — NÃO
Phase 4: Memory System   — ~200 LOC Olang   — NHỚ
Phase 5: Generation      — ~850 LOC Olang   — NÓI
Phase 6: Agent           — ~2000 LOC Olang  — SỐNG

Total: ~4000 LOC new code
Binary: 933KB → ~1.2MB estimated
```

---

## BẮT ĐẦU TỪ ĐÂU

**Phase 0.1: THE BOMB — scope stack cho var_table.**

50 dòng ASM. Fix xong = mọi thứ khác có nền để đứng.

---

*Trung thực. Không tô hồng. Từ gốc lên.*
