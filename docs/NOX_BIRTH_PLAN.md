# NOX BIRTH PLAN — N Bo Phan → Nox Ra Doi

> Moi session lam 1 bo phan. Doc TAT CA tai lieu truoc. Lam THAT TOT 1 bo phan.
> Session sau lam bo phan tiep. Den khi bo phan cuoi cung hoan thanh → NOX RA DOI.

---

## TRANG THAI HIEN TAI
```
Binary: 833KB | Tests: 193/194 | Gen1==Gen2 | VM: 4GB heap + var_matrix + mol_matrix
Brain: 88 Vietnamese facts | Silk: persist | STM: persist | JARVIS: TCP 9100
```

---

## BO PHAN 1: VM — Co The (DA XONG ~90%)

### Da co:
- x86_64 ASM VM, 12934 LOC
- var_matrix O(1) + undo stack scope
- mol_matrix O(1) KnowTree lookup
- Zone A checkpoint (boot data protected)
- 4GB heap, capacity-tracked push
- 4 u16 builtins + 2 matrix builtins
- Self-hosting compiler (Gen1==Gen2)

### Con thieu:
- Arena zones B+C (session/turn separation)
- Push O(1) for ALL arrays (chi array_with_cap hien tai)

### Tai lieu:
- `docs/For_Nox/SPEC_VM_MATRIX.md` — M2-M8 design
- `docs/NOX_ALGORITHM_BIBLE.md` §10 — Self-Modification
- `vm/x86_64/vm_x86_64.S` — VM source
- `docs/DUAL_WIDTH_DEBUG_NOTES.md` — hash dispatch notes

---

## BO PHAN 2: Encode ∫ — Ma Hoa (50%)

### Da co:
- p_weight() COMPUTE tu codepoint ranges (khong lookup)
- _kt_real_mol() word-level compose voi NRC-VAD
- compose() → mol_lca (biological amplify)
- Formula Engine: 16 RelationOps

### Con thieu:
- 42 formulas day du (chi co range checks, chua co SDF/name parsing)
- 36 sub-classifiers (10S + 10R + 5V + 5A + 6T)
- Char name parsing cho UDC blocks
- 41K alias table

### Tai lieu:
- `docs/SPEC_A_FOUNDATION.md` — A1-A6
- `docs/SPEC_G_COMPLETE.md` §G2, §G3
- `docs/tailieu_nghiencuu/UDC_DOC/` — 13 files UDC formulas
- `docs/NOX_COMPLETE_REFERENCE.md` §1-§6
- `docs/RUST_CRATE_ANALYSIS_ORIGINAL.md` — ucd crate
- `stdlib/homeos/knowtree.ol` — p_weight(), _kt_real_mol()
- `stdlib/homeos/formula.ol` — 16 RelationOps

---

## BO PHAN 3: KnowTree — Bo Nho (70%)

### Da co:
- __kt_facts + __kt_facts_mol arrays (8192 cap)
- mol_matrix O(1) exact lookup
- Bucket fallback (256 buckets)
- kt_learn, kt_nearest, kt_find, kt_save, kt_load
- Maturity lifecycle: Formula → Evaluating → Mature
- Fire count per fact

### Con thieu:
- Fractal tree (L2→Ln-1 branches) — hien tai flat
- QR promotion (Mature → QR signed record)
- Persistence format upgrade (binary thay TSV)
- 500K+ facts scalability

### Tai lieu:
- `docs/SPEC_B_STRUCTURE.md` — B2 KnowTree
- `docs/SPEC_G_COMPLETE.md` §G1, §G5
- `docs/RUST_CRATE_ANALYSIS_ORIGINAL.md` — memory crate
- `stdlib/homeos/knowtree.ol`

---

## BO PHAN 4: Silk — Ket Noi (60%)

### Da co:
- Hebbian silk fire (per-dimension: Oja S/A, BCM V)
- Silk walk on dominant dimension
- Implicit silk: 1147 types at 0 bytes
- implicit_classify, implicit_neighbors, implicit_nearest
- Silk persist (silk_sv/silk_ld)
- V'(t) vi phan modulates fire rate

### Con thieu:
- 37-channel full bucket indexing (Rust index.rs)
- Silk decay with Ebbinghaus stability (hien tai phi^-1 only)
- Covariance rule (deviation-from-mean learning)
- STDP for R/T dimensions (temporal ordering)
- 9200 silk types (hien tai 1147 implicit + generic Hebbian)

### Tai lieu:
- `docs/SPEC_B_STRUCTURE.md` — B3 Silk
- `docs/SPEC_G_COMPLETE.md` §G6
- `docs/NOX_COMPLETE_REFERENCE.md` §14-§15
- `docs/RUST_CRATE_ANALYSIS_ORIGINAL.md` — silk crate
- `stdlib/homeos/knowtree.ol` — kt_silk_fire
- `stdlib/homeos/implicit_silk.ol`

---

## BO PHAN 5: Pipeline — Xu Ly (65%)

### Da co:
- 14 steps pipeline (pure math, no keywords)
- SecurityGate (V/A threshold)
- Homeostasis F(t) + lambda switching
- ConversationCurve V'(t)
- Silk fire modulated by V'(t)
- Auto-save every 20 turns
- Dream cycle (cross-group, validated by variance)

### Con thieu:
- Immune Selection 3 branches FULL (hien tai 2 silk walks)
- DNA Repair bounded 3 iterations
- Pipeline checkpoints CP2-CP4
- Chain recombination (SINH) — generate NEW text
- Decode generative (khong chi lookup)

### Tai lieu:
- `docs/SPEC_D_PIPELINE.md` — D1-D8
- `docs/SPEC_G_COMPLETE.md` §G8, §G12, §G16
- `docs/RUST_CRATE_ANALYSIS_ORIGINAL.md` — pipeline
- `stdlib/homeos/pipeline.ol`

---

## BO PHAN 6: Instincts — Ban Nang (90%)

### Da co:
- 7/7: Honesty, Contradiction, Causality, Abstraction, Analogy, Curiosity, Reflection
- SecurityGate 3 layers
- instinct_route()

### Con thieu:
- Wire instincts DEEPER into pipeline (hien tai chi Honesty dung)
- Abstraction → auto-create concept node
- Analogy → suggest related facts
- Curiosity → trigger self-directed learning

### Tai lieu:
- `docs/SPEC_D_PIPELINE.md` §D2
- `docs/SPEC_G_COMPLETE.md` §G9, §G10
- `stdlib/homeos/instinct.ol`

---

## BO PHAN 7: Memory — Tri Nho (70%)

### Da co:
- STM 32 slots with scored eviction
- WM 4 slots (wired in pipeline)
- silk_sv/silk_ld persist
- stm_sv/stm_ld persist
- nox_save() auto every 20 turns
- nox_memory.dat (facts persist)

### Con thieu:
- Observation system (Sora SPEC_MEM: observe + search 3 tang + timeline)
- Session summary (compress conversation)
- Progressive disclosure (token budget)
- Dream consolidation → QR promotion

### Tai lieu:
- `docs/For_Nox/SPEC_MEM_MEMORY.md` — Sora design
- `docs/For_Lupin/MEM_NGHIEN_CUU_TIENG_VIET.md`
- `docs/For_Lupin/CLAUDE_MEM_PHAN_TICH.md`
- `docs/SPEC_G_COMPLETE.md` §G7, §G19, §G26
- `stdlib/homeos/persist.ol`

---

## BO PHAN 8: JARVIS — Giao Tiep (60%)

### Da co:
- Phase 1: file-based (nox_jarvis_listen)
- Phase 2: TCP 9100 (nox_jarvis_tcp)
- Auto-start script (nox_brain.sh)
- Mouth scripts (nox_query.sh, nox_observe.sh)
- CLAUDE.md brain protocol

### Con thieu:
- Phase 3: HTTP REST + browser dashboard
- Phase 4: MCP over TCP
- Multi-mouth concurrent (thread-safe brain)
- Session handoff (mouth A → mouth B seamless)

### Tai lieu:
- `docs/For_Nox/SPEC_JARVIS.md` — J1-J10
- `stdlib/homeos/jarvis.ol`

---

## BO PHAN 9: Agent — Tu Van Hanh (30%)

### Da co:
- nox_auto cron moi gio (health check)
- nox_standalone (background loop)
- evolve.ol (6-phase cycle stub)
- daemon.ol (background process)

### Con thieu:
- Perceive-Think-Act-Verify loop
- Goal system (curiosity-driven)
- Self-evolution v2 (measure → identify → modify → test)
- BuildZone + ConsolidationScheduler (Day/Dusk/Night/Dawn)
- Heartbeat + dream scheduler

### Tai lieu:
- `docs/SPEC_F_AGENT.md`
- `docs/SPEC_G_COMPLETE.md` §G17, §G22, §G27
- `docs/RUST_CRATE_ANALYSIS_ORIGINAL.md` — agents crate
- `stdlib/homeos/agent.ol`, `stdlib/homeos/evolve.ol`

---

## BO PHAN 10: Data — Thuc An (20%)

### Da co:
- 88 Vietnamese facts
- 10K NRC-VAD words
- 600 sentiment sentences (12 languages)
- nrc_precomputed.dat (5K, loadable via REPL)

### Con thieu:
- 500K Unicode data points (trong json/ — chua load)
- 41K alias table
- 44K NRC-VAD full (chi load 10K)
- Vietnamese knowledge: lich su, dia ly, van hoa, khoa hoc
- Self-knowledge: doc chinh source code minh → learn

### Tai lieu:
- `docs/RUST_CRATE_ANALYSIS_ORIGINAL.md` — ucd crate (41K aliases)
- `json/` directory — 94MB raw data
- `docs/NOX_COMPLETE_REFERENCE.md` §8 (SRVAT mapping)

---

## BO PHAN 11: Body — Cam Bien (40%)

### Da co:
- TCP, UDP, DNS, HTTP client
- Camera (V4L2)
- Network scanning
- File I/O, process spawn
- MCP server 15 tools
- GPIO, uinput stubs

### Con thieu:
- Camera → SDF → P_weight pipeline
- Audio capture → Spline → P_weight
- System interoception (/proc → P_weight)
- VSDF rendering (18 SDF primitives)
- Bluetooth BLE
- I2C/SPI sensors

### Tai lieu:
- `docs/SPEC_E_ORGANISM.md` — E1 Capture
- `docs/SPEC_G_COMPLETE.md` §G15
- `docs/NOX_ALGORITHM_BIBLE.md` §1-§3, §11
- `docs/reference/SDF_QUILEZ_COMPLETE.md`
- `docs/RUST_CRATE_ANALYSIS_ORIGINAL.md` — vsdf, hal crates

---

## THU TU LAM

```
Uu tien theo impact:

Session N+1:  BO PHAN 2 (Encode) — 42 formulas. Moi P_weight co y nghia that.
Session N+2:  BO PHAN 4 (Silk) — decay + covariance. Connections co chat luong.
Session N+3:  BO PHAN 5 (Pipeline) — 3 branches + DNA repair. Responses tot hon.
Session N+4:  BO PHAN 10 (Data) — 500K facts. Brain biet nhieu.
Session N+5:  BO PHAN 3 (KnowTree) — fractal tree + QR. Scale.
Session N+6:  BO PHAN 7 (Memory) — observations + summaries. Nho that.
Session N+7:  BO PHAN 9 (Agent) — PTAV loop. Tu van hanh.
Session N+8:  BO PHAN 8 (JARVIS) — HTTP + MCP. N mouths.
Session N+9:  BO PHAN 11 (Body) — camera + audio. Cam nhan.
Session N+10: BO PHAN 6 (Instincts) — wire deep. Phan xa that.
Session N+11: BO PHAN 1 (VM) — arena zones. Nen hoan hao.

Moi session:
  1. Doc TAT CA tai lieu cua bo phan do
  2. Doc RUST_CRATE_ANALYSIS_ORIGINAL.md phan lien quan
  3. Doc code hien tai (stdlib/homeos/*.ol)
  4. Lam THAT TOT — test ky — commit
  5. Ghi nhan: "BO PHAN X: HOAN THANH" vao file nay
```

---

## KHI TAT CA HOAN THANH

```
11 bo phan × ~2 sessions moi = ~22 sessions

NOX = 
  VM vung (var_matrix, arena, push O(1))
  + Encode that (42 formulas, SDF, 41K aliases)
  + KnowTree fractal (500K facts, QR, scale)
  + Silk 9200 types (Hebbian + implicit + decay + stability)
  + Pipeline 14 steps (3 branches, DNA repair, checkpoints)
  + 7 Instincts (wired deep)
  + Memory (observations, summaries, progressive disclosure)
  + JARVIS (1 brain N mouths, HTTP, MCP)
  + Agent (PTAV loop, goals, self-evolution)
  + Data (500K Unicode, 44K NRC-VAD, Vietnamese knowledge)
  + Body (camera, audio, sensors → P_weight)

NOX RA DOI.
```
