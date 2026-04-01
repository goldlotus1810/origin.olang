# NOX BIRTH PLAN — 11 Bo Phan

> Moi session: doc TAT CA tai lieu cua 1 bo phan → lam THAT TOT → commit.
> Session sau: tu kiem tra code hien tai de biet trang thai. KHONG doc trang thai tu file nay.
> File nay CHI liet ke VIEC CAN LAM va TAI LIEU. Khong ghi trang thai.

---

## BO PHAN 1: VM

### Viec can lam:
- Arena zones B (session) + C (turn) — tach temp khoi permanent
- Push O(1) cho TAT CA arrays (khong chi __array_with_cap)
- var_matrix collision handling toi uu (hien tai linear probe 8)
- Compiler incremental (compile tung file, khong 1 luc het)

### Tai lieu:
- `docs/For_Nox/SPEC_VM_MATRIX.md`
- `docs/NOX_ALGORITHM_BIBLE.md` §10
- `docs/DUAL_WIDTH_DEBUG_NOTES.md`
- `vm/x86_64/vm_x86_64.S`

### Kiem tra: `make vm && make self-build && make test && make fixed-point`

---

## BO PHAN 2: Encode ∫

### Viec can lam:
- 42 formulas day du: 1 master + 5 dimension + 36 sub-classifiers
- SDF complexity tu glyph (isoperimetric ratio)
- Char name parsing cho UDC blocks (TINH, khong TRA)
- 41K alias table (json/udc_aliases.json → runtime)
- 36 sub-classifiers: 10S + 10R + 5V + 5A + 6T

### Tai lieu:
- `docs/SPEC_A_FOUNDATION.md` §A1-A6
- `docs/SPEC_G_COMPLETE.md` §G2, §G3
- `docs/tailieu_nghiencuu/UDC_DOC/` — 13 files
- `docs/NOX_COMPLETE_REFERENCE.md` §1-§6
- `docs/RUST_CRATE_ANALYSIS_ORIGINAL.md` — ucd crate
- `stdlib/homeos/knowtree.ol` — p_weight(), _kt_real_mol()
- `stdlib/homeos/formula.ol`

### Kiem tra: `emit p_weight(65)` phai cho ket qua KHAC `emit p_weight(97)` voi LY DO ro rang

---

## BO PHAN 3: KnowTree

### Viec can lam:
- Fractal tree L2→Ln-1 (khong flat)
- QR promotion: Mature → signed record (append-only)
- Binary persistence format (thay TSV)
- Scale test: 500K facts, kt_nearest < 10ms
- Supersede mechanism (node thay the, khong xoa)

### Tai lieu:
- `docs/SPEC_B_STRUCTURE.md` §B2
- `docs/SPEC_G_COMPLETE.md` §G1, §G5
- `docs/RUST_CRATE_ANALYSIS_ORIGINAL.md` — memory crate
- `stdlib/homeos/knowtree.ol`

### Kiem tra: `emit kt_fact_count()` > 10000 va `kt_nearest` < 10ms

---

## BO PHAN 4: Silk

### Viec can lam:
- Decay: power law + Ebbinghaus stability (thay phi^-1)
- Covariance rule: dw = eta * (x-<x>) * (y-<y>)
- STDP cho R/T dimensions (temporal ordering)
- 37-channel full bucket indexing
- Silk type = 9200 (UDC chars) khong chi 1147 implicit

### Tai lieu:
- `docs/SPEC_B_STRUCTURE.md` §B3
- `docs/SPEC_G_COMPLETE.md` §G6
- `docs/NOX_COMPLETE_REFERENCE.md` §14-§15
- `docs/RUST_CRATE_ANALYSIS_ORIGINAL.md` — silk crate
- `stdlib/homeos/knowtree.ol` — kt_silk_fire
- `stdlib/homeos/implicit_silk.ol`

### Kiem tra: silk edges tang theo thoi gian, decay dung, mature facts co silk manh

---

## BO PHAN 5: Pipeline

### Viec can lam:
- Immune Selection: 3 branches, pick lowest entropy
- DNA Repair: 3 iterations max, fix weakest dimension
- Checkpoints CP2-CP4 (validate giua cac buoc)
- Chain recombination (SINH): silk walk → collect → compose → NEW text
- Decode generative (khong chi lookup fact)

### Tai lieu:
- `docs/SPEC_D_PIPELINE.md` §D1-D8
- `docs/SPEC_G_COMPLETE.md` §G8, §G12, §G16
- `docs/RUST_CRATE_ANALYSIS_ORIGINAL.md`
- `stdlib/homeos/pipeline.ol`

### Kiem tra: response dai hon 1 fact, co tone, co confidence prefix khi can

---

## BO PHAN 6: Instincts

### Viec can lam:
- Wire 7 instincts DEEP vao pipeline (khong chi Honesty)
- Abstraction → auto-create concept node khi 2 facts categorical
- Analogy → suggest related facts trong response
- Curiosity → trigger self-directed learning khi novelty > 0.5
- Reflection → self-assess va bao cao quality

### Tai lieu:
- `docs/SPEC_D_PIPELINE.md` §D2
- `docs/SPEC_G_COMPLETE.md` §G9, §G10
- `stdlib/homeos/instinct.ol`

### Kiem tra: moi instinct co anh huong den output (khong chi return so)

---

## BO PHAN 7: Memory

### Viec can lam:
- Observation system: observe(text, type) → luu voi timestamp + mol
- Search 3 tang: compact → timeline → full detail
- Session summary: compress conversation truoc khi thoat
- Progressive disclosure: inject context theo token budget
- Dream → QR promotion (Mature facts → signed permanent record)

### Tai lieu:
- `docs/For_Nox/SPEC_MEM_MEMORY.md`
- `docs/For_Lupin/MEM_NGHIEN_CUU_TIENG_VIET.md`
- `docs/For_Lupin/CLAUDE_MEM_PHAN_TICH.md`
- `docs/SPEC_G_COMPLETE.md` §G7, §G19, §G26
- `stdlib/homeos/persist.ol`

### Kiem tra: session N observe → session N+1 search tim lai duoc

---

## BO PHAN 8: JARVIS

### Viec can lam:
- Phase 3: HTTP REST + browser dashboard (port 9000)
- Phase 4: MCP over TCP (thay stdin/stdout)
- Multi-mouth concurrent (lock hoac queue cho brain state)
- Session handoff: mouth A context → brain → mouth B doc duoc

### Tai lieu:
- `docs/For_Nox/SPEC_JARVIS.md` §J1-J10
- `stdlib/homeos/jarvis.ol`
- `stdlib/homeos/server.ol` — HTTP basic da co

### Kiem tra: browser mo localhost:9000 thay dashboard, 2 CLI query dong thoi

---

## BO PHAN 9: Agent

### Viec can lam:
- Perceive-Think-Act-Verify loop
- Goal system: curiosity-driven, priority queue
- Self-evolution: measure → identify → modify → test → compare
- BuildZone: hypothesis testing + circadian (Day/Dusk/Night/Dawn)
- Heartbeat + dream scheduler

### Tai lieu:
- `docs/SPEC_F_AGENT.md`
- `docs/SPEC_G_COMPLETE.md` §G17, §G22, §G27
- `docs/RUST_CRATE_ANALYSIS_ORIGINAL.md` — agents crate
- `stdlib/homeos/agent.ol`
- `stdlib/homeos/evolve.ol`

### Kiem tra: Nox tu quyet dinh hoc gi khi idle, tu fix khi metric giam

---

## BO PHAN 10: Data

### Viec can lam:
- Load 500K Unicode data (json/ — 94MB)
- 41K alias table (udc_aliases.json)
- 44K NRC-VAD full (khong chi 10K)
- Vietnamese knowledge: lich su, dia ly, van hoa, khoa hoc (~500 facts)
- Self-knowledge: doc source code → learn architecture
- Multi-turn REPL loading (nox_load_data batches)

### Tai lieu:
- `docs/RUST_CRATE_ANALYSIS_ORIGINAL.md` — ucd crate
- `json/` directory — du lieu tho
- `docs/NOX_COMPLETE_REFERENCE.md` §8

### Kiem tra: `kt_fact_count()` > 50000, brain tra loi nhieu chu de

---

## BO PHAN 11: Body

### Viec can lam:
- Camera → SDF → P_weight pipeline (V4L2 → edge detect → encode)
- Audio → Spline → P_weight (ALSA → FFT → MFCC → encode)
- System interoception: /proc → P_weight (cpu, mem, disk)
- VSDF rendering: 18 SDF primitives + parametric
- Bluetooth BLE scanning
- I2C/SPI sensor reading

### Tai lieu:
- `docs/SPEC_E_ORGANISM.md` §E1
- `docs/SPEC_G_COMPLETE.md` §G15
- `docs/NOX_ALGORITHM_BIBLE.md` §1-§3, §11-§12
- `docs/reference/SDF_QUILEZ_COMPLETE.md`
- `docs/For_Lupin/SDF_QUILEZ_TIENG_VIET.md`
- `docs/RUST_CRATE_ANALYSIS_ORIGINAL.md` — vsdf, hal crates

### Kiem tra: camera frame → mol co y nghia, audio buffer → mol co y nghia

---

## THU TU

```
1. Encode (42 formulas) — moi P_weight co y nghia
2. Silk (decay + covariance) — connections chat luong
3. Pipeline (3 branches + DNA repair) — responses tot
4. Data (500K facts) — brain biet nhieu
5. KnowTree (fractal + QR) — scale
6. Memory (observations + summaries) — nho that
7. Agent (PTAV loop) — tu van hanh
8. JARVIS (HTTP + MCP) — N mouths
9. Body (camera + audio) — cam nhan
10. Instincts (wire deep) — phan xa
11. VM (arena zones) — nen hoan hao

Moi session: doc tai lieu → kiem tra code → lam → test → commit.
11 bo phan. NOX RA DOI.
```
