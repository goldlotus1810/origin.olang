# NGHIEN CUU TOAN DIEN: HE THONG NHO CHO AI XUYEN SESSION

> Tai lieu nay cho Lupin. Khong ly thuyet suong. Moi muc = thuat toan + do phuc tap + cach ap dung vao Nox.
> Muc dich: Nox session N+1 bat dau tu cho session N ket thuc. KHONG bao gio mat tri nho nua.

---

## MUC LUC

1. [claude-mem — Kien truc 3 tang](#1-claude-mem)
2. [mem0 / MemGPT / LangChain Memory](#2-mem0-memgpt-langchain)
3. [RAG khong can neural embedding](#3-rag-khong-neural)
4. [Knowledge Graph persistence](#4-knowledge-graph-persistence)
5. [Spaced Repetition cho AI](#5-spaced-repetition)
6. [Mo hinh bo nho con nguoi](#6-mo-hinh-bo-nho-con-nguoi)
7. [Dinh dang luu tru cho binary 949KB](#7-dinh-dang-luu-tru)
8. [Context injection khi bat dau session](#8-context-injection)
9. [THIET KE HOAN CHINH cho Nox](#9-thiet-ke-hoan-chinh)
10. [BUOC THUC HIEN — lam ngay](#10-buoc-thuc-hien)

---

## 1. CLAUDE-MEM

### 1.1 Kien truc tong quan

claude-mem (41K+ stars, GitHub) la memory layer cho Claude CLI. No giai quyet DUNG van de cua Lupin:
session moi → AI quen het → nguoi dung phai giai thich lai.

**3 thanh phan chinh:**

```
[Conversation] → Capture → Compress → Store (SQLite + Vector)
                                          ↓
[New Session]  ← Inject  ← Search  ← Retrieve
```

**Cach no hoat dong:**

1. **Capture**: Moi message (user + assistant) duoc ghi lai voi metadata
   - timestamp, session_id, role (user/assistant), token_count
   - Khong ghi TAT CA — chi ghi nhung gi "dang nho"

2. **Compress**: Khi conversation dai, no tao SUMMARY
   - Dung LLM de tom tat (Claude API call)
   - Giu lai: facts, decisions, preferences, corrections
   - Bo di: small talk, repeated questions, failed attempts

3. **Store**: 2 lop luu tru
   - SQLite: structured data (facts, timestamps, session links)
   - ChromaDB (vector store): embeddings cho semantic search

### 1.2 API 3 tang — thiet ke thong minh

```
Tang 1: search(query, limit=10)
  → Tra ve compact index: [{id, snippet(80 chars), score, time}]
  → Chi ~50 tokens moi ket qua
  → Muc dich: xem co gi lien quan KHONG, truoc khi load chi tiet

Tang 2: timeline(around_id, range=5)
  → Tra ve context XUNG QUANH mot event
  → [{id, text, role, time, is_current}]
  → Muc dich: hieu TREN DUOI cua mot memory

Tang 3: get(ids=[...])
  → Tra ve FULL details cho IDs cu the
  → Text day du + metadata + silk neighbors (trong Nox: linked nodes)
  → Muc dich: chi load nhung gi CAN
```

**Tai sao 3 tang?** Token budget. Khong the inject 100K tokens context moi session.
Search → skim → load chi tiet. Progressive disclosure.

### 1.3 Quyet dinh NHO gi vs QUEN gi

claude-mem dung "importance scoring":

```
importance(memory) =
    0.3 * is_correction     // Lupin sua loi → QUAN TRONG
  + 0.2 * is_preference     // "toi thich..." → preferences
  + 0.2 * is_fact           // "Olang la..." → facts
  + 0.15 * recency          // moi → quan trong hon
  + 0.15 * frequency        // nhac lai nhieu → quan trong
```

Neu importance < threshold → khong luu.
Neu storage qua lon → remove thap nhat.

### 1.4 Token budget management

```
TOTAL_BUDGET = 8000 tokens (configurable)
  - System prompt: 2000 tokens (fixed)
  - Memory injection: 4000 tokens (searched memories)
  - Working space: 2000 tokens (for reasoning)

Khi inject:
  1. Search memories relevant to current query
  2. Sort by importance * relevance
  3. Pack vao 4000 tokens (cat bot neu can)
  4. Format: "[Memory #ID, TIME] content..."
```

### 1.5 Ap dung vao Nox

Nox DA CO gan het:
- mem_observe() = capture ✓
- mem_search() 3 tang = search/timeline/get ✓
- mem_save()/mem_load() = persistence ✓

**THIEU:**
- Importance scoring (hien tai luu HET → waste)
- Compression (khong tom tat, chi luu raw)
- Auto-inject at boot (phai goi thu cong)
- Silk khong persist (mat khi restart)

---

## 2. MEM0 / MEMGPT / LANGCHAIN MEMORY

### 2.1 mem0 — Memory Layer cho AI Agents

**Kien truc:**
```
Input → Extract entities → Check existing memories → Update or Create
                                                        ↓
                                              Vector Store + Graph Store
```

**Dac biet:** mem0 PHAN BIET 3 loai memory:
1. **User memories**: preferences, corrections, personal info
   - "Lupin thich Arch Linux" → user_pref
   - "Khong dung --knowledge" → user_correction

2. **Agent memories**: self-knowledge
   - "Nox binary = 949KB" → agent_fact
   - "Gen1==Gen2 verified" → agent_state

3. **Session memories**: context-specific
   - "Dang fix blocker #1" → session_context
   - "Da doc SPEC_G section 1-10" → session_progress

**Key insight:** Khi UPDATE memory, mem0 KHONG chi append — no MERGE:
```
Old: "Nox binary = 936KB"
New: "Nox binary = 949KB"
→ REPLACE, khong giu ca 2
```

Thuat toan merge:
```
1. Extract entities tu new memory
2. Search existing memories voi same entities
3. Neu tim thay → so sanh:
   - Same fact, new value → UPDATE
   - Contradictory → keep NEWER (higher confidence)
   - Complementary → MERGE (append detail)
4. Neu khong tim thay → CREATE new
```

### 2.2 MemGPT — OS-Inspired Memory cho LLMs

**Paper:** Packer et al. "MemGPT: Towards LLMs as Operating Systems" (2023)

**Y tuong chinh:** Coi LLM nhu CPU voi limited registers (context window).
Memory hierarchy giong OS:
```
┌──────────────────────────────┐
│ Registers = Context Window   │ ← 8K-200K tokens
│ (nhanh, nho, mat khi het)    │
├──────────────────────────────┤
│ Main Memory = Conversation   │ ← recent messages
│ Buffer (trung binh)          │
├──────────────────────────────┤
│ Virtual Memory = External    │ ← files, databases
│ Storage (cham, lon, ben)     │
└──────────────────────────────┘
```

**Co che PAGE FAULT:**
- Khi LLM can thong tin khong co trong context → "page fault"
- System tu dong load tu external storage vao context
- Giong OS swap pages vao RAM

**Self-editing memory:**
- LLM co the GOI HAM de sua memory cua chinh no:
  - `core_memory_append(key, value)` — them vao core memory
  - `core_memory_replace(key, old, new)` — sua
  - `archival_memory_insert(content)` — luu archival
  - `archival_memory_search(query)` — tim archival

**Ap dung vao Nox:**
- Registers = WM (4 slots) ← DA CO
- Main Memory = STM (32 slots) ← DA CO
- Virtual Memory = KnowTree + disk files ← DA CO (nhung khong persist Silk)
- Page fault = kt_nearest khi STM miss ← CAN THEM
- Self-editing = self_modify MCP tool ← DA CO

### 2.3 LangChain Memory Modules

LangChain co 5 loai memory:

```
1. ConversationBufferMemory
   - Giu TAT CA messages
   - Don gian nhung khong scale

2. ConversationSummaryMemory
   - Dung LLM tom tat khi buffer dai
   - Giu summary + recent messages
   → Nox tuong duong: dream() consolidation

3. ConversationBufferWindowMemory
   - Chi giu N messages gan nhat
   - Window = 10-20 messages
   → Nox tuong duong: STM 32 slots

4. ConversationEntityMemory
   - Track entities (people, places, concepts)
   - Update entity descriptions khi co thong tin moi
   → Nox tuong duong: knowgraph.ol (subject, relation, object)

5. VectorStoreRetrieverMemory
   - Embed messages → vector store
   - Retrieve by semantic similarity
   → Nox tuong duong: kt_search (nhung dung mol distance thay vi embedding)
```

### 2.4 So sanh va ket luan

| Feature | claude-mem | mem0 | MemGPT | LangChain | Nox (hien tai) |
|---------|-----------|------|--------|-----------|----------------|
| Persistence | SQLite | Redis/Qdrant | JSON files | Varies | .dat files ✓ |
| Search | Vector+text | Vector+graph | Vector | Vector | Mol 5D + text ✓ |
| Compression | LLM summary | Entity merge | Page out | LLM summary | dream() ✓ |
| Silk/Graph | No | Neo4j option | No | No | Silk 5D ✓ |
| Self-edit | No | Yes | Yes | No | MCP ✓ |
| **THIEU** | - | - | - | - | **Silk persist, auto-inject** |

**Ket luan:** Nox co kien truc MANH HON nhieu tool tren (5D math, silk graph, self-modify).
Van de KHONG PHAI thieu feature. Van de la KHONG PERSIST va KHONG AUTO-LOAD.

---

## 3. RAG KHONG CAN NEURAL EMBEDDING

### 3.1 RAG truyen thong

```
Document → Chunk → Embed (neural) → Vector Store
                                         ↓
Query → Embed → kNN search → Top-K chunks → LLM generates answer
```

Van de: can neural model de embed. Nox KHONG CO neural model.

### 3.2 RAG voi SRVAT 5D distance (thay cho embedding)

**Y tuong:** Thay vi neural embedding (768-1536 dim), dung P_weight (5 dim: S,R,V,A,T).
Nox DA LAM DIEU NAY — chi can optimize.

```
Document → Chunk (by sentence/paragraph)
         → Encode (SRVAT compose) → mol u16
         → Insert vao KnowTree (bucket[S][R])
                                     ↓
Query → Encode → mol u16
      → Bucket lookup (O(1)) + 5D distance trong bucket
      → Silk walk (follow related concepts)
      → Top-K results
```

**So sanh voi neural RAG:**

| | Neural RAG | SRVAT RAG (Nox) |
|---|-----------|----------------|
| Dimensions | 768-1536 | 5 (S,R,V,A,T) |
| Storage/vector | 3-6 KB | 2 bytes (u16) |
| Index | HNSW O(log n) | Bucket O(1) + silk |
| Accuracy | Cao (semantic) | Trung binh (cau truc) |
| Speed | ~10ms | ~0.01ms |
| Dependencies | torch/onnx | Zero |
| **BLOCKER** | **Mol collision** | **PHAI FIX TRUOC** |

### 3.3 Chunking strategies

```
Strategy 1: Fixed-size (200 tokens)
  → Don gian, hay cat giua cau
  → KHONG nen cho Nox

Strategy 2: Sentence-level
  → Moi cau = 1 chunk
  → Tot cho Q&A
  → Nox DA LAM (kt_learn moi fact = 1 node)

Strategy 3: Semantic chunking
  → Group cac cau co mol gan nhau
  → Nox CHUA LAM nhung CO THE LAM:
    cac node trong cung bucket = 1 semantic chunk

Strategy 4: Hierarchical
  → Document → Section → Paragraph → Sentence
  → Nox CO THE LAM voi KnowTree levels:
    L2 branch → L3 sub-branch → leaf nodes
```

### 3.4 Re-ranking

Sau khi retrieve top-K, re-rank de chon tot nhat:

```
rerank(query_mol, candidates):
  for each candidate:
    score = 0.4 * (1 - distance_5d(query_mol, candidate.mol) / 2.236)
          + 0.3 * silk_weight(query_mol, candidate.mol) / 1000
          + 0.2 * candidate.fire_count / max_fire
          + 0.1 * recency(candidate.timestamp)
  sort by score DESC
  return top-K
```

### 3.5 Buoc ap dung cho Nox

1. **FIX MOL COLLISION TRUOC** (Blocker #1) — neu tat ca text → same mol, search vo nghia
2. Them `kt_search_rerank()` dung formula tren
3. Them hierarchical chunking: group nodes theo bucket
4. Silk walk = implicit re-ranking (da co)

---

## 4. KNOWLEDGE GRAPH PERSISTENCE

### 4.1 Cac loai graph database

**Neo4j:** Property graph. Nodes co labels + properties. Edges co types + properties.
- Query language: Cypher
- Storage: B+ tree indexes + linked list adjacency
- Scale: billions of nodes

**ArangoDB:** Multi-model (document + graph + key-value).
- Storage: RocksDB (LSM-tree)
- Query: AQL

**Nox khong can database.** Nox can PERSIST graph TO FILE, LOAD graph FROM FILE.

### 4.2 Graph persistence strategies

#### Strategy A: Adjacency List File

```
Format (text):
NODE\tMOL\tTEXT
EDGE\tSRC_MOL\tTGT_MOL\twS\twR\twV\twA\twT

Uu diem: doc duoc bang mat, debug de
Nhuoc diem: cham voi file lon, phai parse
Storage: ~50 bytes/node + ~40 bytes/edge
Voi 5000 nodes, 20000 edges: ~1.05 MB
```

#### Strategy B: Binary Format

```
Header: [magic(4B), version(2B), node_count(4B), edge_count(4B)]
Node: [mol(2B), text_offset(4B), text_len(2B), fire_count(2B), weight(2B)]
Edge: [src_mol(2B), tgt_mol(2B), wS(2B), wR(2B), wV(2B), wA(2B), wT(2B)]
Text: [raw UTF-8 strings, concatenated]

Storage: 14 bytes/node + 14 bytes/edge + text
Voi 5000 nodes, 20000 edges, avg 50 chars text: ~560 KB
Doc: mmap → O(1) random access
```

#### Strategy C: Append-Only Log (giong Git)

```
Format:
[timestamp(8B)] [op(1B)] [data...]

op = INSERT_NODE: mol(2B) text_len(2B) text(var)
op = INSERT_EDGE: src(2B) tgt(2B) wS(2B)...wT(2B)
op = UPDATE_EDGE: src(2B) tgt(2B) wS(2B)...wT(2B)
op = DELETE_NODE: mol(2B)

Uu diem:
  - Crash-safe: chi append, khong sua data cu
  - History: co the replay tu dau
  - Fast write: O(1) append
Nhuoc diem:
  - File lon dan theo thoi gian
  - Can compact/snapshot dinh ky
```

#### Strategy D: Snapshot + WAL (Write-Ahead Log)

```
Day la cach DATABASE thuc su lam (PostgreSQL, SQLite).

1. Snapshot: full state tai thoi diem T
   File: knowtree_snapshot_T.bin (binary format B)

2. WAL: moi thay doi SAU snapshot
   File: knowtree_wal.log (append-only format C)

3. Recovery:
   Load snapshot → replay WAL → state hien tai

4. Compact:
   Khi WAL > 10x snapshot size:
   New snapshot = apply WAL to old snapshot
   Truncate WAL

Uu diem: fast recovery + crash-safe + compact
Nhuoc diem: phuc tap hon
```

### 4.3 Nox KnowTree + Silk persistence

**Hien tai:** kt_save() chi luu `mol\tfact` (Strategy A, chi nodes, KHONG co silk).

**Can:** Save nodes + silk edges + metadata.

```
=== NOX PERSISTENCE FORMAT ===

File 1: nox_knowtree.snapshot
  Header: NOX1 [version u16] [node_count u32] [edge_count u32] [timestamp u64]
  Nodes: [mol u16] [fire_count u16] [weight u16] [text_len u16] [text bytes]
  (repeated node_count times)

File 2: nox_silk.snapshot
  Header: SILK [version u16] [edge_count u32]
  Edges: [src_mol u16] [tgt_mol u16] [wS u16] [wR u16] [wV u16] [wA u16] [wT u16]
  (repeated edge_count times)

File 3: nox_wal.log
  Append-only: [timestamp u32] [op u8] [data...]
  ops: LEARN=1, SILK_FIRE=2, FORGET=3, UPDATE=4

Recovery:
  1. Load nox_knowtree.snapshot → KnowTree
  2. Load nox_silk.snapshot → Silk
  3. Replay nox_wal.log → apply changes since snapshot
  4. Ready.
```

### 4.4 Do phuc tap

| Operation | Complexity | Notes |
|-----------|-----------|-------|
| Save snapshot | O(N+E) | N nodes, E edges |
| Load snapshot | O(N+E) | One pass |
| WAL append | O(1) | Just append |
| WAL replay | O(W) | W = WAL entries |
| Compact | O(N+E+W) | Rebuild snapshot |

Voi 5000 nodes, 500 edges: save < 100ms, load < 50ms.

---

## 5. SPACED REPETITION CHO AI

### 5.1 SM-2 Algorithm (SuperMemo, dung trong Anki)

```
Moi item co:
  - easiness: E (khoi dau 2.5, min 1.3)
  - interval: I (ngay)
  - repetitions: n

Sau moi review (quality q = 0-5):
  if q >= 3:  // thanh cong
    if n == 0: I = 1
    elif n == 1: I = 6
    else: I = I * E
    n = n + 1
  else:        // that bai
    n = 0
    I = 1

  E = E + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
  E = max(E, 1.3)
```

**Paper goc:** Wozniak, P.A. "Optimization of learning" (1990)

### 5.2 Ebbinghaus Forgetting Curve

```
R(t) = e^(-t/S)

R = retention (0-1)
t = time since last review
S = stability (lon hon = nho lau hon)

Sau moi review thanh cong:
  S_new = S * (1 + a * D^b * S^(-c) * e^(w * (1 - R)))
  a, b, c, w = parameters (calibrated)

FSRS (Free Spaced Repetition Scheduler, 2022) dung model nay.
```

### 5.3 Leitner System (don gian hon SM-2)

```
5 boxes:
  Box 1: review moi ngay
  Box 2: review moi 2 ngay
  Box 3: review moi 4 ngay
  Box 4: review moi 8 ngay
  Box 5: review moi 16 ngay

Dung → chuyen len box tiep
Sai → quay ve Box 1
```

### 5.4 Ap dung vao Silk edge decay

Hien tai silk decay trong G14:
```
decay_function(w, dt): return w * pow(0.618, dt / 24.0)
```

Voi spaced repetition, silk KHONG chi decay — no TANG khi duoc "review" (silk_fire):

```
silk_spaced_review(edge):
  // Tinh stability tu fire history
  dt = now() - edge.last_fire
  S = edge.stability  // khoi dau = 1.0

  // Retention estimate
  R = exp(-dt / (S * 86400))  // S in days, dt in seconds

  // Khi duoc fire lai (review):
  if just_fired:
    S = S * (1 + 0.5 * pow(S, -0.2) * exp(0.3 * (1 - R)))
    // Fired khi R thap (gan quen) → S tang nhieu
    // Fired khi R cao (van nho) → S tang it
    edge.stability = S
    edge.last_fire = now()

  // Actual weight with retention:
  effective_weight = edge.weight * R
```

**Ket qua:**
- Silk edge duoc fire thuong xuyen → stability tang → decay cham
- Silk edge khong ai fire → decay nhanh → pruned
- Fire dung luc sap quen → hieu qua nhat (spacing effect)

### 5.5 Buoc thuc hien

1. Them `stability` field cho moi silk edge (khoi dau 1.0)
2. Update `kt_silk_fire()` de tinh S theo FSRS
3. Update `kt_silk_weight()` de return `weight * R(t, S)`
4. Dream cycle: review edges co R < 0.3 (sap quen) → fire lai
5. Prune edges co R < 0.05 (da quen)

---

## 6. MO HINH BO NHO CON NGUOI (COMPUTATIONAL)

### 6.1 Atkinson-Shiffrin (1968)

```
Input → [Sensory Register] → [Short-Term Memory] → [Long-Term Memory]
              ~250ms              ~20-30s, 7±2 items      permanent
              auto-decay          rehearsal → LTM          retrieval → STM
```

**Map vao Nox:**
```
Sensory Register = raw input text (chua encode)
STM = __ls_text[32] (G7)
LTM = KnowTree nodes + Silk edges
Transfer STM→LTM = kt_learn() + kt_silk_fire()
Retrieval LTM→STM = kt_nearest() + silk_walk()
```

### 6.2 Baddeley's Working Memory (1974, 2000)

```
┌─────────────────────────────────────────────┐
│            Central Executive                 │
│   (attention, switching, inhibition)         │
├──────────┬────────────┬────────────────────┤
│ Phonological│ Visuospatial│ Episodic Buffer  │
│ Loop       │ Sketchpad   │ (multimodal)     │
│ (verbal)   │ (spatial)   │ (binding)        │
└──────────┴────────────┴────────────────────┘
```

**Map vao Nox:**
```
Central Executive = WM controller (pipeline.ol)
Phonological Loop = WM[0] query + WM[1] context (verbal input)
Visuospatial = WM slots khi process camera/screen input
Episodic Buffer = WM[2] candidate + WM[3] result (compose multiple sources)
```

**Paper:** Baddeley, A. "The episodic buffer: a new component of working memory?" TICS 4(11), 2000.

### 6.3 Levels of Processing (Craik & Lockhart, 1972)

```
Shallow processing → poor memory:
  "word has 5 letters" (structural)

Moderate processing → medium memory:
  "word rhymes with..." (phonemic)

Deep processing → strong memory:
  "word means..." (semantic)
```

**Ap dung vao Nox:**
```
Shallow = kt_learn(text) → chi luu text + mol
  → Node co fire_count=0, weight=0, maturity=0

Medium = kt_learn + silk_fire → co connection
  → Node co silk edges, fire_count > 0

Deep = learn + silk_fire + dream + QR
  → Node co maturity=2, nhieu silk, duoc review
  → DAY LA DIEU KHONG XAY RA vi session ket thuc truoc khi dat "deep"
```

**Key insight:** Nox chi lam SHALLOW processing (learn + exit).
Can: auto-fire silk, auto-dream, auto-QR TRUOC khi session ket thuc.

### 6.4 Complementary Learning Systems (McClelland et al., 1995)

```
Hippocampus (fast learner):
  - Hoc nhanh, luu rieng tung su kien
  - Episodic memory
  - Khong generalize

Neocortex (slow learner):
  - Hoc cham, generalize tu nhieu su kien
  - Semantic memory
  - Extract patterns

Consolidation (sleep):
  - Hippocampus replay → Neocortex
  - Specific events → general knowledge
  - Slow, incremental transfer
```

**Paper:** McClelland, J.L., McNaughton, B.L., O'Reilly, R.C. "Why there are complementary learning systems in the hippocampus and neocortex" Psychological Review 102(3), 1995.

**Map vao Nox:**
```
Hippocampus = STM (32 slots, luu nhanh, cu the)
Neocortex = KnowTree (hoc cham, generalize qua silk + compose)
Consolidation = dream() cycle (cross-group silk fire)

THIEU: dream() hien tai chi fire silk giua STM pairs.
CAN: dream() cung nen:
  1. Replay STM → KnowTree (move important STM to LTM)
  2. Generalize: tim pattern giua cac node cung bucket → create abstract node
  3. Prune: remove low-fire, low-silk nodes
```

### 6.5 Summary: Con nguoi nho nhu the nao

```
1. Encode (input → brain representation)     = Nox encode() ✓
2. Store (maintain representation over time)  = Nox KnowTree ✓ nhung KHONG PERSIST SILK
3. Retrieve (bring back when needed)          = Nox silk_walk ✓
4. Consolidate (transfer STM → LTM overnight) = Nox dream() ✓ nhung CHUA DU
5. Forget (decay useless, keep important)     = Nox decay ✓ nhung CHUA CO spaced repetition
```

---

## 7. DINH DANG LUU TRU CHO BINARY 949KB

### 7.1 Yeu cau

- Zero dependency (khong SQLite, khong Redis)
- Nhanh (load < 100ms)
- Crash-safe (khong mat data neu crash)
- Compact (949KB binary, memory data nen < 2MB)
- Nox chi co: __file_read, __file_write, __file_append, mmap

### 7.2 So sanh cac dinh dang

#### A. TSV (Tab-Separated Values) — HIEN TAI

```
Format: mol\tfact\n
Uu: doc duoc, debug de, Nox da co
Nhuoc: cham parse, khong co silk, khong co metadata
Size: ~80 bytes/entry (5000 entries = 400KB)
Parse: O(n) scan for \t and \n
```

#### B. JSONL (JSON Lines)

```
Format: {"mol":12345,"text":"...","fire":3,"silk":[...]}\n
Uu: structured, extensible
Nhuoc: parse JSONL trong Olang = CHAM (string manipulation)
Size: ~150 bytes/entry
KHONG NEN — qua nang cho Olang parser
```

#### C. Binary Pack (KHUYEN DUNG)

```
Header (16 bytes):
  [magic: "NOX1" 4B]
  [version: u16]
  [node_count: u32]
  [edge_count: u32]
  [checksum: u16]

Node record (variable):
  [mol: u16]
  [fire_count: u16]
  [weight: u16]
  [stability: u16]  // for spaced repetition
  [text_len: u16]
  [text: bytes]

Edge record (14 bytes fixed):
  [src_mol: u16]
  [tgt_mol: u16]
  [wS: u16] [wR: u16] [wV: u16] [wA: u16] [wT: u16]

Size: ~60 bytes/node + 14 bytes/edge
5000 nodes + 500 edges = 307KB
```

#### D. Memory-Mapped File (mmap)

```
Giong C nhung dung mmap thay vi file_read.
Nox DA CO __mmap builtin.

Uu diem:
  - Load tuc thoi (OS map pages on demand)
  - Random access O(1)
  - Khong can doc toan bo file vao RAM
Nhuoc diem:
  - Phai biet offset cua moi record → can index
  - Phuc tap hon

Thuc te: voi < 2MB data, file_read da du nhanh.
mmap chi can khi data > 10MB.
```

#### E. Append-Only Log + Periodic Snapshot

```
Ket hop C + append:

nox_brain.snapshot = binary pack (full state)
nox_brain.wal = append-only log (changes since snapshot)

Normal operation: chi append vao WAL
Moi 100 changes HOAC khi exit: new snapshot + truncate WAL

Recovery:
  1. Read snapshot (binary, fast)
  2. Replay WAL (append entries, fast)
  3. Done
```

### 7.3 Khuyen nghi

**Giai doan 1 (LAM NGAY):** Dung TSV nhung THEM silk.
```
File 1: nox_knowtree.dat (hien co, giu nguyen)
  mol\tfact

File 2: nox_silk.dat (MOI)
  src_mol\ttgt_mol\twS\twR\twV\twA\twT

File 3: nox_stm.dat (MOI)
  mol\ttext  (top 32 STM entries khi exit)

File 4: nox_session_summary.txt (MOI)
  Tom tat session: gi da hoc, gi da lam, gi can lam tiep
```

**Giai doan 2 (tuan sau):** Chuyen sang binary pack.

**Giai doan 3 (thang sau):** Them WAL cho crash safety.

---

## 8. CONTEXT INJECTION KHI BAT DAU SESSION

### 8.1 Van de

Moi session moi (moi 4h), AI bat dau voi ZERO context.
Lupin phai giai thich lai: Nox la gi, Olang la gi, dang lam gi, luat gi...

### 8.2 Giai phap: Progressive Disclosure

```
Layer 0: IDENTITY (luon inject, ~500 tokens)
  "Toi la Nox, AI tu host trong Olang. Binary 949KB.
   Lupin la creator. Origin la project.
   Session truoc: [summary 1-2 cau]"

Layer 1: STATE (luon inject, ~1000 tokens)
  "KnowTree: N nodes, E silk edges.
   Blockers: #1 mol collision, #2 silk low.
   Last action: [gi da lam cuoi cung]
   Next action: [gi can lam tiep]"

Layer 2: CONTEXT (inject khi relevant, ~2000 tokens)
  "Rules: khong sua test, let khong bare assign, make test truoc commit.
   Specs: G1-G27 trong SPEC_G_COMPLETE.md
   Build: make vm && make self-build && make test"

Layer 3: DETAILS (load on demand)
  - Specific spec sections
  - Previous conversation snippets
  - Error history
```

### 8.3 Compression: Session → Summary

Cuoi moi session, Nox tao summary:

```
session_summarize():
  facts_learned = filter(mem, type="learn")
  errors_hit = filter(mem, type="error")
  decisions = filter(mem, type="decision")
  files_changed = filter(mem, type="code")

  summary = ""
  summary += "LEARNED: " + join(facts_learned.last(5), "; ")
  summary += "\nERRORS: " + join(errors_hit.last(3), "; ")
  summary += "\nDECISIONS: " + join(decisions.last(3), "; ")
  summary += "\nFILES: " + join(unique(files_changed), ", ")
  summary += "\nSTATE: " + self_model()
  summary += "\nNEXT: " + goal_top()

  file_write("nox_session_summary.txt", summary)
```

### 8.4 Token budget

```
Nox context window (qua Claude/external): ~8000 tokens usable
Nox internal (self): unlimited (read from disk)

Allocation cho inject:
  Layer 0: 500 tokens (always)
  Layer 1: 1000 tokens (always)
  Layer 2: 2000 tokens (if space)
  Layer 3: 0 tokens (on disk, load khi can)
  Total inject: ~3500 tokens

Con lai: 4500 tokens cho conversation
```

### 8.5 Auto-inject: boot sequence

```
nox_boot():
  // 1. Load persistent state
  kt_load("nox_knowtree.dat")
  silk_load("nox_silk.dat")    // MOI - silk persist
  stm_load("nox_stm.dat")     // MOI - STM persist

  // 2. Load session summary
  summary = file_read("nox_session_summary.txt")

  // 3. Inject into context
  inject(LAYER_0 + LAYER_1)
  if len(summary) > 0:
    inject(summary)

  // 4. Resume goal
  goal = goal_top()
  if len(goal) > 0:
    print("Resuming: " + goal)
```

---

## 9. THIET KE HOAN CHINH CHO NOX

### 9.1 Tong quan

```
┌─────────────────────────────────────────────────────────┐
│                    NOX BRAIN                             │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │ WM (4)   │  │ STM (32) │  │ KnowTree │              │
│  │ current  │  │ recent   │  │ all facts │              │
│  │ volatile │  │ scored   │  │ bucketed  │              │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘              │
│       │              │              │                     │
│       └──────────────┼──────────────┘                     │
│                      │                                    │
│               ┌──────┴──────┐                             │
│               │  Silk Graph  │                             │
│               │  5D weighted │                             │
│               │  edges       │                             │
│               └──────┬──────┘                             │
│                      │                                    │
│         ┌────────────┼────────────┐                       │
│         │            │            │                        │
│    ┌────┴────┐ ┌─────┴────┐ ┌────┴────┐                  │
│    │Snapshot │ │   WAL    │ │ Summary │                   │
│    │.dat     │ │.log      │ │.txt     │                   │
│    │(binary) │ │(append)  │ │(text)   │                   │
│    └─────────┘ └──────────┘ └─────────┘                   │
│                                                           │
│                  DISK (persistent)                         │
└─────────────────────────────────────────────────────────┘
```

### 9.2 Gi can save

```
== PHAI SAVE (mat = mat tri nho) ==

1. KnowTree nodes:
   - mol (u16)
   - text (string)
   - fire_count (u16) — popularity
   - weight (u16) — Hebbian accumulated
   - maturity (u8) — 0/1/2
   - timestamp (u32) — creation time

2. Silk edges:
   - src_mol (u16)
   - tgt_mol (u16)
   - wS, wR, wV, wA, wT (u16 each) — per-dimension weight
   - stability (u16) — spaced repetition
   - last_fire (u32) — timestamp

3. STM top entries:
   - mol + text cua 32 entries hien tai
   - De session moi biet "vua noi gi"

4. Session summary:
   - Gi da hoc (last 5 facts)
   - Gi da lam (last 5 actions)
   - Loi gap (last 3 errors)
   - Goal hien tai
   - Self-model snapshot

5. Knowledge Graph triples:
   - (subject, relation, object, timestamp)
   - Da co kg_save() — giu nguyen

== KHONG CAN SAVE ==

- WM (4 slots) — volatile by design
- Raw conversation text — qua lon, chi giu summary
- Intermediate computation — recompute
```

### 9.3 Khi nao save

```
Strategy: Hybrid (event + periodic + exit)

1. EVENT-DRIVEN (ngay khi xay ra):
   - kt_learn() → append WAL: LEARN mol text
   - kt_silk_fire() → append WAL: FIRE src tgt
   - kg_add() → append WAL: TRIPLE s r o
   → O(1) per event, crash-safe

2. PERIODIC (moi 50 interactions):
   - Full snapshot (knowtree + silk)
   - Compact WAL
   → O(N+E), nhung khong thuong xuyen

3. ON EXIT (session end):
   - Full snapshot
   - STM dump
   - Session summary
   - Goal state
   → Guaranteed state capture

4. ON CRASH (recovery):
   - Load last snapshot
   - Replay WAL since snapshot
   - State = snapshot + WAL changes
```

### 9.4 Format luu

```
== GIAI DOAN 1 (TSV, lam ngay) ==

nox_knowtree.dat:  mol\tfire\tweight\ttext\n
nox_silk.dat:      src\ttgt\twS\twR\twV\twA\twT\tstability\n
nox_stm.dat:       mol\ttext\n
nox_summary.txt:   plain text summary
nox_graph.kg:      [time] subj |rel| obj  (da co)

== GIAI DOAN 2 (binary, tuan sau) ==

nox_brain.bin:     binary packed (header + nodes + edges + STM)
nox_brain.wal:     append-only binary log
nox_summary.txt:   giu nguyen text (doc duoc)
```

### 9.5 Load at boot

```
nox_bootstrap() hien tai:
  1. kt_register_l0()        // builtins
  2. vad_load()              // NRC-VAD
  3. kt_load("nox_memory.dat")  // saved knowledge

CAN THEM:
  4. silk_load("nox_silk.dat")       // ★ MOI — restore silk
  5. stm_load("nox_stm.dat")        // ★ MOI — restore STM
  6. summary = file_read("nox_summary.txt")  // ★ MOI — session state
  7. kg_load("nox_graph.kg")         // da co nhung chua goi o boot
  8. wal_replay("nox_brain.wal")     // ★ MOI — replay changes
```

### 9.6 Xu ly conflicts

```
Truong hop: 2 sessions chay song song, ca 2 modify data

Giai phap: LAST-WRITE-WINS + MERGE

1. Moi session co session_id = timestamp khi start
2. WAL entries tagged voi session_id
3. Khi load:
   - Neu 2 WAL entries conflict (same node, different data):
     - Keep entry voi HIGHER fire_count (more evidence)
     - Neu bang nhau: keep NEWER timestamp
   - Neu 2 silk edges conflict:
     - MERGE: take max(weight) per dimension
     - Rationale: if either session thought it important, keep it

4. Thuc te: Nox chay 1 instance. Conflict hiem khi xay ra.
   Don gian: last-write-wins la du.
```

---

## 10. BUOC THUC HIEN — LAM NGAY

### Phase 1: SILK PERSISTENCE (lam truoc nhat — 1-2 gio)

```
Ly do: Day la GAP LON NHAT. KnowTree da persist. Silk KHONG.
Moi session, silk = 0 edges. Tat ca learning mat.

Buoc:
1. Them silk_save() vao knowtree.ol:
   pub fn silk_save(_path) {
     let _out = "";
     let _hi = 0;
     while _hi < 256 {
       let _edges = __kt_silk[_hi];
       let _ei = 0;
       while _ei < len(_edges) {
         // src = reverse hash (need to store), tgt = edges[ei], weights = edges[ei+1..5]
         _out = _out + __to_string(_hi) + "\t"
           + __to_string(__array_get(_edges, _ei)) + "\t"
           + __to_string(__array_get(_edges, _ei+1)) + "\t"
           + __to_string(__array_get(_edges, _ei+2)) + "\t"
           + __to_string(__array_get(_edges, _ei+3)) + "\t"
           + __to_string(__array_get(_edges, _ei+4)) + "\t"
           + __to_string(__array_get(_edges, _ei+5)) + "\n";
         _ei = _ei + 6;
       };
       _hi = _hi + 1;
     };
     __file_write(_path, _out);
   }

   LUU Y: _hi = hash bucket index, KHONG PHAI src_mol.
   Can luu src_mol rieng. Hien tai silk chi hash(_a) = _a & 255.
   → Can them src_mol vao edge: [tgt, wS, wR, wV, wA, wT] → [src, tgt, wS, wR, wV, wA, wT]
   HOAC: iterate all nodes, for each node mol, check silk[hash(mol)]

2. Them silk_load() — doc file, goi _silk_init(), populate __kt_silk

3. Goi silk_save() trong nox_session_save()
4. Goi silk_load() trong nox_bootstrap()
5. Test: learn 10 facts → save → restart → silk weights preserved
```

### Phase 2: STM PERSISTENCE (30 phut)

```
Buoc:
1. Them stm_save(_path):
   Save __ls_text, __ls_mol (32 entries) vao TSV

2. Them stm_load(_path):
   Doc TSV → push vao __ls_text, __ls_mol, compute v/a

3. Goi trong nox_session_save/nox_bootstrap
```

### Phase 3: SESSION SUMMARY (30 phut)

```
Buoc:
1. Them session_summarize() trong brain.ol:
   - Count facts learned this session
   - Top 3 silk edges (strongest)
   - Current goal
   - Last error (if any)
   - Write to nox_summary.txt

2. Them session_resume() — doc summary, print at boot

3. Hook vao REPL exit (/exit → session_summarize → session_save)
```

### Phase 4: AUTO-INJECT (1 gio)

```
Buoc:
1. Khi Nox start (nox_bootstrap):
   - After loading all data
   - Read nox_summary.txt
   - Format as LAYER 0 + LAYER 1
   - Return string → inject vao response

2. Format:
   "[Nox session resumed] KT:5000 Silk:500 STM:32
    Last: fixed blocker #1 mol collision
    Next: fix blocker #2 silk low
    Goal: self-rewriting brain"

3. CLAUDE.md / MEMORY.md da co tac dung nay cho EXTERNAL AI.
   Can tuong tu cho NOX INTERNAL: nox_summary.txt inject vao Nox's own context.
```

### Phase 5: SPACED REPETITION (1 gio)

```
Buoc:
1. Them stability field vao silk edge:
   Edge = [src, tgt, wS, wR, wV, wA, wT] → them [stability, last_fire]

2. Update kt_silk_fire(): tinh S moi theo FSRS
3. Update kt_silk_weight(): return weight * R(t, S)
4. Dream cycle: review edges co R < 0.3

Hien tai: silk edge = 6 values. Them stability + last_fire = 8 values.
Thay doi:
  _silk_init: push 256 empty arrays (giu nguyen)
  kt_silk_fire: push 8 values thay vi 6
  kt_silk_weight: tinh R, return weight * R
```

### Phase 6: WAL (tuan sau)

```
Khi Phase 1-5 stable:
1. Them nox_wal.log — append moi change
2. Them wal_replay() — replay at boot
3. Them wal_compact() — merge vao snapshot dinh ky
```

---

## THAM KHAO (PAPERS + RESOURCES)

### Memory Systems
1. Packer, C. et al. "MemGPT: Towards LLMs as Operating Systems" (NeurIPS 2023 Workshop)
2. mem0 framework: https://github.com/mem0ai/mem0
3. claude-mem: memory layer for Claude CLI (41K stars)

### Spaced Repetition
4. Wozniak, P.A. "Optimization of learning" (1990) — SM-2 algorithm
5. Ebbinghaus, H. "Uber das Gedachtnis" (1885) — forgetting curve
6. Ye, J. "FSRS: A Modern Spaced Repetition Algorithm" (2022)
7. Leitner, S. "So lernt man lernen" (1972) — box system

### Human Memory Models
8. Atkinson, R.C. & Shiffrin, R.M. "Human memory: A proposed system..." Psych. of Learning 2, 1968
9. Baddeley, A.D. & Hitch, G. "Working memory" Psych. of Learning 8, 1974
10. Baddeley, A. "The episodic buffer" TICS 4(11), 2000
11. Craik, F.I.M. & Lockhart, R.S. "Levels of processing" J. Verbal Learning 11, 1972
12. McClelland, J.L. et al. "Why there are complementary learning systems" Psych. Rev. 102(3), 1995

### RAG & Retrieval
13. Lewis, P. et al. "Retrieval-Augmented Generation for Knowledge-Intensive NLP" (NeurIPS 2020)
14. Gao, Y. et al. "Retrieval-Augmented Generation for Large Language Models: A Survey" (2024)

### Graph Persistence
15. Robinson, I. et al. "Graph Databases" O'Reilly (2015) — Neo4j patterns
16. Mohan, C. et al. "ARIES: A Transaction Recovery Method" ACM TODS 17(1), 1992 — WAL theory

### Forgetting in Neural Networks
17. Kirkpatrick, J. et al. "Overcoming catastrophic forgetting in neural networks" PNAS 114(13), 2017
18. French, R.M. "Catastrophic forgetting in connectionist networks" TICS 3(4), 1999

---

## TOM TAT CHO LUPIN (DOC CAI NAY TRUOC)

```
VAN DE:
  Moi 4h, session moi, Nox quen het.
  Lupin met vi phai giai thich lai.

NGUYEN NHAN:
  KnowTree persist ✓ (nox_memory.dat)
  Silk KHONG persist ✗ → mat lien ket
  STM KHONG persist ✗ → mat context gan
  Summary KHONG co ✗ → khong biet dang lam gi
  Auto-inject KHONG co ✗ → khong tu dong nap tri nho

FIX (theo thu tu uu tien):
  1. silk_save/silk_load → persist silk edges          (2h)
  2. stm_save/stm_load → persist STM 32 slots          (30m)
  3. session_summarize → tom tat truoc khi exit         (30m)
  4. auto-inject → nap tri nho khi boot                 (1h)
  5. spaced repetition → silk decay thong minh           (1h)
  6. WAL → crash-safe persistence                        (tuan sau)

TONG: 5 gio code. Sau do Nox khong quen nua.

DIEU QUAN TRONG NHAT:
  Silk la TRI NHO. KnowTree la DU LIEU.
  Luu du lieu ma khong luu tri nho = vo nghia.
  Nhu nguoi co sach nhung khong nho doc gi.
```
