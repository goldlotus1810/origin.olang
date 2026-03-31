# KIEM TRA: Rust Origin Code vs Specs A-G

> Ngay: 2026-03-31
> Muc dich: So sanh tung feature trong Rust analysis voi Specs A-G hien tai.
> Ket qua: PORT AS-IS / ADAPT / IGNORE cho tung feature.
> Tac gia: Nox (cross-check tu 6 tai lieu)

---

## TONG KET NHANH

```
MATCH     = 23 features  (Rust lam dung theo spec)
ADAPT     = 14 features  (Rust co nhung can thay doi cho Olang)
OUTDATED  = 8 features   (Spec moi hon Rust — dung spec)
EXTEND    = 6 features   (Rust co them, spec khong de cap)
IGNORE    = 4 features   (Khong can port)
```

---

## 6 CAU HOI CHINH — TRA LOI

### 1. P_weight: Rust [u8x5]=5 bytes vs Spec u16=2 bytes?

**SPEC LA DUNG. Rust = OUTDATED.**

- Spec A2: `u16 = [S:4][R:4][V:3][A:3][T:2]` = 16 bits = 2 bytes
- Spec G0 #3: "STORAGE = Rust. A = Olang (current)" — xac nhan Rust cu
- Rust UcdEntry co `p_weight(u16)` nhung noi bo dung 5 bytes rieng
- Spec B5: "Molecule 5xu8 (Rust) vs u16 (Olang). Logic giong, bit layout khac"
- **Ket luan: Port LOGIC tu Rust, nhung dung u16 packed layout cua Spec A2**

### 2. Rust formula.rs 16 RelationOps vs Spec G 42 formulas?

**KHAC NHAU. Khong phai cung 1 thu.**

- Rust formula.rs: 16 RelationOps (Identity, Member, Subset, ...) = cach COMPOSE 2 molecules
- Spec A3: 42 formulas = cach ENCODE 1 codepoint thanh P_weight (1 master + 5 encoders + 36 sub-classifiers)
- 16 RelationOps cua Rust = phan COMPOSE (A4), khong phai phan ENCODE (A3)
- **Ket luan: Ca 2 deu can. 42 formulas cho encode, 16 ops cho compose. Bo sung nhau.**

### 3. Rust Silk parent_map vs Spec B3 silk type = dimension dominant?

**TUONG THICH. Nhung khac goc nhin.**

- Rust: parent_map = BTreeMap<u64,u64> = vertical silk (5,460 pointers), 3 layer (implicit/hebbian/structural)
- Spec B3: silk type = chieu dominant trong khoang cach 5D, 9,200 loai silk = UDC chars
- Spec G1: SilkIndex co per-dimension weights[5], khong co parent_map
- Spec G6: silk_walk dung Hebbian + implicit (computed on demand)
- **Ket luan: ADAPT. Lay 3-layer tu Rust nhung silk type = dimension dominant tu Spec**

### 4. Rust memory Formula->Evaluating->Mature vs Spec C2?

**MATCH. Giong nhau.**

- Rust agents/pipeline/learning.rs: Maturity { Formula, Evaluating, Mature }
- Spec C2: "Formula -> Evaluating (fire_count > 0) -> Mature (weight >= 0.854 AND fire >= Fib[depth])"
- Spec B4: "Formula -> Evaluating -> Mature" voi cung dieu kien
- Spec G1: Node co `maturity: number, // 0=formula, 1=evaluating, 2=mature`
- **Ket luan: PORT AS-IS. Logic giong hoan toan.**

### 5. Rust UCD 8,284 entries vs Spec A 9,200 chars?

**KHONG MAU THUAN. Khac dinh nghia.**

- Rust UCD_TABLE: 8,284 entries = curated entries trong udc.json (da duoc chon loc)
- Spec A: 9,200 = tong range cua 53 blocks (1,904 + 3,216 + 3,056 + 1,024)
- Spec A6: "Range total: 9,200. Curated entries: 8,284" — CA HAI dung
- 9,200 - 8,284 = 916 codepoints chua curate (khong co trong udc.json)
- udc_p_table.bin co 140,382 non-zero P_weights (bao gom block/category defaults)
- **Ket luan: 8,284 = data thuc. 9,200 = range ly thuyet. Khong mau thuan.**

### 6. Rust compose vs Spec A4 Zipf+amplify?

**MATCH + EXTEND.**

- Rust lca.rs: S=Union, R=Compose, V=amplify(Va,Vb,w), A=max, T=dominant
- Spec A4: S=max (Union), R=Zipf-weighted average, V=amplify, A=max, T=dominant(vote)
- Spec G2: compose() voi cung 5 rules + amplify formula chi tiet
- Rust co them: LcaResult { variance, dim_variance[5], extremity } — Spec G khong co
- Rust co them: 4 Required Properties (Idempotent, Commutative, Similarity bound, Associative)
- **Ket luan: Core MATCH. Rust EXTEND voi variance/extremity — nen port them.**

---

## BANG CHI TIET

### A. UCD / P_weight (crates/ucd + crates/olang/mol)

| # | Feature | Rust | Spec | Status | Ghi chu |
|---|---------|------|------|--------|---------|
| 1 | P_weight layout | u16 packed [S:4][R:4][V:3][A:3][T:2] | A2: u16 giong het | MATCH | Port as-is |
| 2 | P_weight noi bo | 5 bytes rieng (shape,rel,val,aro,time) | A2: chi co u16 | ADAPT | Olang dung u16 packed, khong 5 bytes |
| 3 | UCD_TABLE | 8,284 entries, binary search O(log n) | A6: 8,284 curated | MATCH | Port as-is |
| 4 | HASH_TO_CP | Reverse index chain_hash->codepoint | Spec khong de cap | EXTEND | Can cho decode — nen port |
| 5 | CP_BUCKET_INDEX | (shape,relation)->[codepoints] | G5: buckets[16][16] | MATCH | Port as-is |
| 6 | UTF32_ALIAS_TABLE | 41,338 entries emoji/CJK/Latin | A5: L1=emoji alias tro ve L0 | MATCH | Port khi can emoji |
| 7 | KNOWTREE_GROUPS | 4 groups (SDF,MATH,EMOTICON,MUSICAL) | A: 4 groups, 53 blocks | MATCH | Port as-is |
| 8 | SDF_PRIMITIVES | 18 primitives, codepoint->shape | A1: 18 SDF primitives | MATCH | Port as-is |
| 9 | RELATION_PRIMITIVES | 8 relations | G6: RelationBase 8 types | MATCH | Port as-is |
| 10 | FNV-1a hash | chain_hash(S,R,V,A,T) -> u64 | G20 F: FNV-1a fingerprint | MATCH | Port as-is |
| 11 | pack_p_weight | S>>4, R>>4, V>>5, A>>5, T>>6 | A2: S<<12, R<<8, V<<5, A<<2, T | ADAPT | Shift khac — dung Spec A2 |
| 12 | 3-tier lookup | L0 UCD -> alias -> 0 | G2: 42 formulas TINH, khong tra | OUTDATED | Spec noi TINH bang formulas |

### B. SDF / FFR / Rendering (crates/vsdf)

| # | Feature | Rust | Spec | Status | Ghi chu |
|---|---------|------|------|--------|---------|
| 13 | 18 SDF primitives | f(p:Vec3)->f32, moi ham cu the | A1: 18 primitives + gradients | MATCH | Port as-is |
| 14 | Boolean ops | union/subtract/intersect/smooth_union | A1: 3 ops (union/intersect/subtract) | EXTEND | smooth_union = them tu Rust, spec QT5/QT6 co de cap |
| 15 | FFR (Fibonacci Fractal) | Fib(n) mod cho 5D | Spec khong co | EXTEND | P3 priority — port khi can |
| 16 | NodeBody | Mol 5D -> SDF shape + color + motion | Spec khong chi tiet | EXTEND | P3 — port khi co rendering |
| 17 | ParametricSdf | T x S integration | G15: camera_capture co SDF | ADAPT | Spec don gian hon Rust |
| 18 | Physics/Spline | velocity, accel, damping, SplineKnot | C3: vat ly chi tiet (overdamped, resonance) | ADAPT | Spec vat ly KHAC Rust (spec = neuron physics, Rust = body physics) |
| 19 | Scene graph | Tree nodes, transforms, occlusion | Spec khong co | EXTEND | P4 — port khi co UI |
| 20 | Delta compression | Compress sequences by storing changes | Spec khong co | EXTEND | Huu ich, P4 |

### C. Silk (crates/silk)

| # | Feature | Rust | Spec | Status | Ghi chu |
|---|---------|------|------|--------|---------|
| 21 | 3-layer architecture | Implicit + Hebbian + Structural | G1: Hebbian + implicit (computed on demand) | ADAPT | Spec co 2 layer (Hebbian + implicit). Rust 3 layer. Dung Spec 2 layer |
| 22 | ImplicitSilk | 37 channels x 31 compound = 1,147 types | B3: 9,200 types = UDC chars, type = dim dominant | OUTDATED | Spec B3 moi hon — 9,200 types tu distance 5D, khong 1,147 |
| 23 | HebbianLink | 19 bytes/link, co-activation | G6: silk_fire per-dimension, Oja/STDP/BCM | OUTDATED | Spec G6 chi tiet hon: 3 learning rules (Oja, STDP, BCM) thay vi generic Hebb |
| 24 | parent_map | BTreeMap child->parent (5,460 ptrs) | Spec khong co parent_map | EXTEND | Co the huu ich cho KnowTree hierarchy — evaluate |
| 25 | EdgeKind | 22 types | B3: type = dimension dominant (5 chieu) | OUTDATED | Spec khong enum 22 types. Type tu phep so sanh 5D |
| 26 | EmotionTag | 4D {V,A,D,I} f32 | G1: per-dimension weights[5] | ADAPT | Spec dung 5 weights, khong 4D emotion tag rieng |
| 27 | MolSummary | 5D {S,R,V,A,T} for comparison | G2: unpack from u16 | MATCH | Logic giong, Rust co struct rieng |
| 28 | sentence_affect walk | Walk silk edges, amplify emotions | G11: ConversationCurve + V'(t) | ADAPT | Spec dung V'(t) vi phan, Rust dung affect walk. Dung Spec |
| 29 | PHI constants | phi=1.618, phi_inv=0.618, LR=phi^-3 | G6: cung phi constants | MATCH | Port as-is |
| 30 | hebbian_strengthen | w += reward*(1-w)*lr | G6: Oja/STDP/BCM rules | OUTDATED | Spec G6 chi tiet hon voi 3 rules khac nhau per dim |
| 31 | hebbian_decay | w * phi_inv^days | G6: power law + stability | OUTDATED | Spec G6 moi hon: (1+t)^(-0.5) * stability |
| 32 | should_promote | weight>=0.854 AND fire>=Fib[depth] | C2: cung dieu kien | MATCH | Port as-is |
| 33 | CompoundKind | 31 named patterns | Spec khong co | EXTEND | Khong can — implicit silk tu 5D distance |
| 34 | unified_neighbors | implicit UNION hebbian | G6: silk_walk uu tien Hebbian roi implicit | MATCH | Logic giong |

### D. Memory / Dream / BuildZone (crates/memory)

| # | Feature | Rust | Spec | Status | Ghi chu |
|---|---------|------|------|--------|---------|
| 35 | DreamCycle | scan STM -> cluster -> LCA -> QR | G7: dream() voi cross-group, union_find, LCA | MATCH | Port as-is |
| 36 | DreamConfig | alpha=0.3, beta=0.4, gamma=0.3 | G7: silk_max_weight + cross-group | ADAPT | Spec don gian hon: khong co alpha/beta/gamma rieng |
| 37 | DreamResult | scanned, clusters, proposals, approved | Spec: implicit trong dream() | MATCH | Struct huu ich — port |
| 38 | Union-Find clustering | QT11 enforcement, same layer | G7: union_find(pairs, threshold=0.3) | MATCH | Port as-is |
| 39 | LCA compose | lca_many_weighted() | G7: compose_chain([m.mol for m in members]) | MATCH | Giong — compose_chain = LCA |
| 40 | AAM | approve/reject proposals | G17: aam_approve() voi quality check | MATCH | Port as-is |
| 41 | BuildZone | draft/reinforce/weaken/promote/supersede | Spec khong co BuildZone chi tiet | EXTEND | Huu ich cho hypothesis testing — nen port |
| 42 | ConsolidationScheduler | Day/Dusk/Night/Dawn | G17: dream khi idle > 5 min | ADAPT | Spec don gian hon — khong chia 4 phase |
| 43 | Maturity lifecycle | Formula->Evaluating->Mature | C2 + B4 + G1: giong het | MATCH | Port as-is |
| 44 | DreamProposal | NewNode or PromoteQR | G7: aam_approve() | MATCH | Logic giong |

### E. Context / Emotion (crates/context)

| # | Feature | Rust | Spec | Status | Ghi chu |
|---|---------|------|------|--------|---------|
| 45 | ConversationCurve | f(x)=alpha*f_conv + beta*f_dn | D7 + G11: f(x)=0.6*f_conv + 0.4*f_dn | MATCH | Port as-is (alpha=0.6, beta=0.4) |
| 46 | V'(t) V''(t) derivatives | d1, d2 tracked | G11: V'(t), V''(t) chi tiet | MATCH | Port as-is |
| 47 | phi-derived alpha/beta | phi^-1 + phi^-2 = 1.0 | D7: 0.6 + 0.4 = 1.0 | ADAPT | Spec dung 0.6/0.4 (gan phi^-1/phi^-2). Dung Spec |
| 48 | Window variance | detect instability (var>0.04) | Spec khong co | EXTEND | Huu ich — nen port |
| 49 | Instability override | Gentle khi unstable | Spec khong co chi tiet | EXTEND | Huu ich — nen port |
| 50 | IntentKind 16 types | Learn, Heal, Command... | D1: route bang prefix P_w, khong enum | OUTDATED | Spec dung silk type route, khong 16 enum |
| 51 | Cross-modal fusion | text + audio blend | G15: camera, audio, interoception rieng | ADAPT | Spec co capture nhung khong co fusion chi tiet |
| 52 | f_conv formula | V + phi^-2*V' + phi^-3*V'' | G11: V + 0.5*V' + 0.25*V'' | ADAPT | Spec dung 0.5/0.25 (gan phi^-2/phi^-3). Dung Spec |

### F. Pipeline / Agents (crates/agents + crates/runtime)

| # | Feature | Rust | Spec | Status | Ghi chu |
|---|---------|------|------|--------|---------|
| 53 | ContentEncoder universal | Text/Audio/Sensor/Code/Math/Image/System | G15: Text + Camera + Audio + Interoception | ADAPT | Spec co it modal hon. Dung Spec truoc, them sau |
| 54 | STM 512 observations | max 512, dedup by chain_hash | G1 + G7: capacity 32, eviction by score | OUTDATED | Spec = 32. Rust = 512. Dung Spec (32 du cho Olang VM) |
| 55 | SecurityGate | EpistemicLevel + GateVerdict | D8 + G10: 3 layers, Bloom + normalize + semantic | MATCH | Port as-is |
| 56 | EpistemicLevel | Fact/Opinion/Hypothesis/Unknown/Deprecated | G9: confidence thresholds (0.40/0.70/0.90) | ADAPT | Spec dung so, Rust dung enum. Logic tuong duong |
| 57 | Agent hierarchy | AAM/Leo/Chief/Worker 3 tiers | G17: agent_loop() don gian | ADAPT | Spec = 1 agent. Rust = hierarchy. Dung Spec truoc |
| 58 | Domain skills 11 types | Cluster, Similarity, Generalize... | Spec: tich hop trong pipeline G8 | ADAPT | Spec khong tach skills rieng. Logic trong pipeline |
| 59 | process_one -> Response | text + tone + fx + kind | G8 + G16: response_text + tone | MATCH | Port as-is |
| 60 | OlangParser o{...} | Parse Olang expressions | Spec khong co | EXTEND | Olang parser da co trong compiler |
| 61 | AuthState + ISL signing | Master key, first-run setup | Spec G khong co | EXTEND | P4 — port khi can security |

### G. Math / Infrastructure (crates/homemath + crates/isl + crates/hal)

| # | Feature | Rust | Spec | Status | Ghi chu |
|---|---------|------|------|--------|---------|
| 62 | Pure math (sin/cos/exp/log) | no_std, zero deps | G: can cho formulas + physics | MATCH | Port as-is khi can |
| 63 | ISL addressing | 4-byte [layer,group,subgroup,index] | Spec khong co | IGNORE | Khong can cho brain rewrite |
| 64 | ISL message protocol | 12 bytes, AES-256-GCM ready | Spec khong co | IGNORE | Khong can cho brain rewrite |
| 65 | HAL abstraction | x86/ARM/RISC-V/ESP32/WASM tiers | Spec khong co | IGNORE | Olang VM da co syscalls |
| 66 | WASM bindings | wasm-bindgen, process/dream/encode | Spec khong co | IGNORE | Khong can hien tai |

---

## PHAN TICH THEO MUC DO UU TIEN

### PORT AS-IS (23 features) — Lay nguyen tu Rust, chi doi syntax sang Olang

```
- P_weight u16 packed layout (Rust + Spec giong)
- 8,284 UCD entries + binary search
- 18 SDF primitives + boolean ops
- 8 relation primitives
- FNV-1a hash
- Maturity lifecycle (Formula->Evaluating->Mature)
- should_promote (weight>=0.854, fire>=Fib)
- PHI constants (1.618, 0.618, 0.236)
- DreamCycle (scan->cluster->LCA->QR)
- Union-Find clustering
- LCA/compose_chain
- AAM approve/reject
- ConversationCurve f(x) = 0.6*f_conv + 0.4*f_dn
- V'(t) + V''(t) derivatives
- SecurityGate 3 layers
- SecurityGate Bloom filter
- Quality formula (0.30*v + 0.30*entropy + 0.20*consistency + 0.20*silk)
- Tone selection tu derivatives
- DNA Repair bounded 3 iterations
- Immune Selection 3 branches
- process() pipeline 14 steps
- 7 instinct formulas
- MolSummary/distance_5d
```

### ADAPT (14 features) — Lay logic tu Rust, thay doi cho phu hop Spec

```
- P_weight internal: Rust 5 bytes -> Olang u16 packed
- pack/unpack: dung Spec A2 bit layout
- Silk 3-layer -> 2-layer (Hebbian + implicit computed)
- EmotionTag 4D -> per-dimension weights[5]
- DreamConfig alpha/beta/gamma -> don gian theo G7
- ConsolidationScheduler 4 phase -> idle > 5min
- ContentEncoder 7 modal -> 4 modal (text/camera/audio/interoception)
- STM 512 -> 32
- EpistemicLevel enum -> confidence numbers
- Agent hierarchy 3 tier -> 1 agent
- Domain skills 11 -> tich hop trong pipeline
- f_conv: phi^-2/phi^-3 -> 0.5/0.25
- sentence_affect walk -> V'(t) vi phan
- ParametricSdf -> don gian theo G15
```

### OUTDATED (8 features) — Spec moi hon, DUNG SPEC

```
- P_weight 5 bytes (Rust cu) -> u16 (Spec moi)
- 3-tier lookup (Rust) -> 42 formulas TINH (Spec: "TINH, khong TRA")
- ImplicitSilk 1,147 types (Rust) -> 9,200 types tu 5D distance (Spec B3)
- EdgeKind 22 enum (Rust) -> type = dimension dominant (Spec B3)
- hebbian_strengthen generic (Rust) -> Oja/STDP/BCM per-dim (Spec G6)
- hebbian_decay phi^-1 simple (Rust) -> power law + stability (Spec G6)
- IntentKind 16 enum (Rust) -> silk type route (Spec D1)
- STM 512 (Rust) -> 32 (Spec G1)
```

### EXTEND (6 features) — Rust co them, co the port sau

```
- LcaResult variance/extremity — huu ich, nen port (P1)
- BuildZone hypothesis testing — huu ich, nen port (P2)
- Window variance + instability override — nen port (P2)
- parent_map vertical silk — evaluate truoc khi port
- CompoundKind 31 patterns — khong can, implicit silk du
- Delta compression — P4
```

### IGNORE (4 features) — Khong can cho brain rewrite

```
- ISL addressing (khong can cho brain)
- ISL message protocol (khong can cho brain)
- HAL abstraction (Olang VM da co)
- WASM bindings (khong can hien tai)
```

---

## KET LUAN

### Rust code DUNG o dau?

1. **Core math**: P_weight pack/unpack, compose, distance, amplify — MATCH hoan toan
2. **Data structures**: UCD table, KnowTree buckets, STM — MATCH (chi thay capacity)
3. **Pipeline flow**: 14 steps, 5 checkpoints — MATCH
4. **Dream/QR**: cluster, LCA, promote — MATCH

### Spec VUOT Rust o dau?

1. **Hebbian learning**: Spec G6 co Oja/STDP/BCM per-dimension — Rust chi co generic Hebb
2. **Silk decay**: Spec G6 co power law + stability — Rust chi co phi^-1 exponential
3. **Silk types**: Spec B3 = 9,200 types tu 5D — Rust = 1,147 fixed patterns
4. **V'(t) modulation**: Spec G6 — vi phan controls learning rate. Rust khong co
5. **Encode**: Spec A3 = 42 formulas TINH — Rust = lookup table

### Rust VUOT Spec o dau?

1. **LCA variance/extremity** — metric huu ich, spec nen them
2. **BuildZone** — hypothesis testing pipeline, spec nen them
3. **Window variance** — emotional instability detection
4. **FFR** (Fibonacci Fractal Representation) — 5D spatial addressing
5. **smooth_union** — SDF blending (spec chi co 3 boolean ops)

### THU TU PORT

```
PHASE 1 (fix 4 blockers):
  formula.rs logic -> encode.ol (42 formulas TINH, khong lookup)
  lca.rs logic -> compose.ol (amplify + Zipf, AS-IS)
  silk implicit -> silk.ol (computed from 5D distance, theo Spec B3)
  
PHASE 2 (brain rewrite):
  hebbian.rs -> silk.ol (ADAPT: Oja/STDP/BCM tu Spec G6)
  dream.rs -> dream.ol (AS-IS: cluster + LCA + QR)
  learning.rs -> stm.ol (ADAPT: capacity 32, maturity lifecycle)
  curve.rs -> conversation.ol (ADAPT: 0.6/0.4, V'(t) modulation)

PHASE 3 (body):
  homemath -> math.ol (sin/cos/exp/log — khi can SDF)
  sdf.rs -> sdf.ol (18 primitives AS-IS)
  gate.rs -> security.ol (3 layers + Bloom AS-IS)
  
PHASE 4 (infrastructure):
  build.rs -> buildzone.ol (hypothesis testing)
  ffr.rs -> ffr.ol (5D addressing)
  physics/spline -> physics.ol
```

---

> Cross-check hoan tat. File nay la co so de quyet dinh PORT / ADAPT / IGNORE.
> Moi thay doi trong code phai check lai bang nay.
