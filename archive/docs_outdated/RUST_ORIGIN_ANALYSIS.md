# Rust Origin Project — Full Crate Analysis

> Generated 2026-03-31 by deep-reading every .rs source file in ~/Origin_project/crates/
> Purpose: Identify what Nox (origin.olang) is MISSING compared to Rust implementation.

---

## 1. crates/ucd — Unicode Character Database (Formula Engine Foundation)

### What it does
Static compile-time lookup tables generated from `json/udc.json` (8,284 characters, 53 blocks, 4 groups).
Provides the FOUNDATION for all molecular encoding — every concept starts here.

### Key data structures
- **UcdEntry**: per-codepoint record with `cp, group, shape, relation, valence, arousal, time, p_weight(u16), hash(u64), name`
- **P_weight packed u16**: `[S:4][R:4][V:3][A:3][T:2]` — 16-bit packed 5D coordinate
- **UCD_TABLE**: 8,284 entries sorted by codepoint (binary search O(log n))
- **HASH_TO_CP**: reverse index chain_hash -> codepoint (binary search O(log n))
- **CP_BUCKET_INDEX/DATA**: (shape, relation) -> [codepoints] for top-n decode (O(1))
- **UTF32_ALIAS_TABLE**: 41,338 entries for emoji/CJK/Latin (T15 spec)
- **KNOWTREE_GROUPS**: 4 groups (SDF, MATH, EMOTICON, MUSICAL) with aggregate P_weights
- **KNOWTREE_BLOCKS**: 53 blocks with range-mapped characters
- **SDF_PRIMITIVES**: 18 SDF primitives (codepoint -> shape_index)
- **RELATION_PRIMITIVES**: 8 relation primitives (codepoint -> relation_byte)

### Key algorithms
- **FNV-1a hash**: `chain_hash(shape, relation, valence, arousal, time)` — 5-byte hash
- **pack_p_weight**: S>>4, R>>4, V>>5, A>>5, T>>6 -> packed u16
- **mode_p_weight**: per-dimension mode (most frequent) for aggregate P_weights
- **3-tier lookup**: `p_weight_full(cp)` = L0 UCD_TABLE -> alias table -> 0

### What Nox DOES NOT have
1. **NO static UCD table at compile time** — Nox uses runtime `_dna_table` (161K P_weights) but no O(log n) binary search on 8,284 entries
2. **NO reverse index** (hash -> codepoint) — critical for MolecularChain decode
3. **NO bucket index** (shape,relation -> codepoints) — needed for top-n candidates
4. **NO alias table** (41K entries for emoji/CJK/Latin) — Nox only has ~72 word affects
5. **NO KnowTree hierarchy** (4 groups, 53 blocks) with aggregate P_weights
6. **NO 18 SDF primitive mapping** from codepoints
7. **NO 8 relation primitive mapping** from codepoints

---

## 2. crates/vsdf — Volumetric SDF + FFR Rendering

### What it does
18 signed distance functions for 3D shape representation + Fibonacci Fractal Representation (FFR) for 5D addressing + parametric rendering + physics dynamics.

### Sub-modules

#### shape/sdf.rs — 18 SDF primitives
Each is a function `f(p: Vec3) -> f32` where negative = inside, 0 = surface, positive = outside.

**All 18 primitives**:
1. Sphere, 2. Box, 3. Cone, 4. Torus, 5. Capsule, 6. Cylinder, 7. Ellipsoid,
8. Pyramid, 9. Plane, 10. RoundBox, 11. Link, 12. HexPrism, 13. TriPrism,
14. SolidAngle, 15. CutSphere, 16. CutHollow, 17. DeathStar, 18. Octahedron

**Boolean ops**: union (min), subtract (max(-b,a)), intersect (max), smooth_union (blending)

#### shape/body.rs — NodeBody (per-node physical representation)
Maps Molecule 5D coordinates to physical body: SDF shape + color + motion pattern.
`body_from_molecule_full()`: shape from S, color from V/A, motion from T.

#### shape/fit.rs — Shape fitting
Fit observed data to SDF primitive with confidence score.

#### render/ffr.rs — Fibonacci Fractal Representation
**FFR(n)** = position n on 5D Fibonacci spiral:
- `shape = Fib(n) mod 7`
- `relation = Fib(n+1) mod 8`
- `valence = Fib(n+2) mod 256`
- `arousal = Fib(n+3) mod 256`
- `time = Fib(n+4) mod 5`

Key functions: `FfrPoint::at(n)`, `ffr_chain(start, n)`, `ffr_nearest(target, max)`

#### render/parametric.rs — T x S Integration (FE.8)
`ParametricSdf`: SDF primitive + T parameters (amplitude=size, phase=position, frequency=motion).
CSG composition: `sdf_union()`, `sdf_smooth_union()`.
Example: `snowman()` = 3 spheres stacked via phase offset.

#### render/scene.rs — Scene graph
Scene tree with nodes, transforms, visibility.

#### render/occlusion.rs — Occlusion culling
Spatial partitioning for rendering optimization.

#### dynamics/spline.rs — SplineKnot
Temporal keyframes: `{timestamp, amplitude, frequency, phase, duration}`.

#### dynamics/physics.rs — Physics simulation
Velocity, acceleration, damping on SDF bodies.

#### dynamics/delta.rs — Delta compression
Compress sequences of molecules by storing only changes.

#### dynamics/vector.rs — Vector math
Vec2, Vec3, Vec4 operations.

### What Nox DOES NOT have
1. **NO SDF primitives** — Nox has zero 3D shape math
2. **NO FFR** (Fibonacci Fractal Representation) — no 5D spatial addressing
3. **NO parametric rendering** — no T x S integration
4. **NO CSG boolean operations** (union/subtract/intersect/smooth_union)
5. **NO NodeBody** — no physical representation of nodes
6. **NO physics simulation** or delta compression
7. **NO scene graph** or occlusion culling

---

## 3. crates/silk — 3-Layer Silk Architecture

### What it does
3-layer connection graph between knowledge nodes:
1. **Implicit** (SilkIndex): 37 channels x 31 compound patterns = 1,147 relationship types, **0 bytes** per edge
2. **Learned** (HebbianLink): 19 bytes/link, co-activation tracking
3. **Structural** (SilkEdge): 46 bytes/edge, backward compat

### Key data structures

#### edge.rs
- **EmotionTag**: 4D `{valence: f32, arousal: f32, dominance: f32, intensity: f32}`
  - `from_ucd_bytes(v, a)`: valence = byte/128.0 - 1.0
  - `blend(other, alpha)`: weighted average
  - `distance_va()`: Euclidean V/A distance
- **EdgeKind**: 22 types (8 structural: Member/Subset/Equiv/Orthogonal/Compose/Causes/Similar/DerivedFrom + spatial + temporal + language + associative + QR supersession)
- **SilkEdge**: full edge (46 bytes): `{from_hash, to_hash, kind, emotion, weight, fire_count, timestamps, source, confidence}`
- **HebbianLink**: slim (19 bytes): `{from_hash, to_hash, weight:u8, fire_count:u16}`
- **ModalitySource**: Text/Audio/Image/Bio/Fused

#### index.rs — Implicit Silk (0-cost connections)
- **37 channels**: 8 Shape + 8 Relation + 8 Valence zones + 8 Arousal zones + 5 Time
- **31 compound patterns**: C(5,1)=5 + C(5,2)=10 + C(5,3)=10 + C(5,4)=5 + C(5,5)=1
- **ImplicitSilk**: `{shared_dims, strength, shared_count}` — computed at query time
- **CompoundKind**: 31 named patterns (Identical, AllButShape, ShapeRelation, ValenceArousal, etc.)

#### graph.rs — SilkGraph (unified 3-layer)
- **MolSummary**: lightweight 5D `{shape, relation, valence, arousal, time}` for comparison
  - `similarity()`: per-dimension comparison -> [0.0, 1.0]
- **SilkNeighbor**: `{hash, weight, implicit, hebbian, shared_dims}`
- **SilkGraph**: edges Vec + edge_index BTreeMap + SilkIndex + learned Vec + **parent_map BTreeMap<u64,u64>**
- **Unified query**: `unified_weight(A,B) = max(implicit, hebbian)`, `unified_neighbors(A) = implicit UNION hebbian`
- **parent_map**: child_hash -> parent_hash (vertical silk, 5460 pointers)

#### hebbian.rs — Hebbian Learning
All constants derived from golden ratio phi = (1+sqrt(5))/2:
- **PHI** = 1.618034
- **PHI_INV** = 0.618034 (decay factor per 24h)
- **LR** = phi^-3 = 0.236 (learning rate)
- **PROMOTE_WEIGHT** = phi^-1 + phi^-3 = 0.854 (promotion threshold)
- **hebbian_strengthen**: `w += reward * (1-w) * lr` (f64 precision internally)
- **hebbian_decay**: `w * phi_inv^days` (f64 precision)
- **should_promote**: `weight >= 0.854 AND fire_count >= Fib[depth]`
- **blend_emotion**: weighted blend of EmotionTags

#### walk.rs — Silk Graph Walk
- **sentence_affect()**: walk Silk edges between consecutive words, amplify emotions by edge weight
- **response_tone()**: derive tone from valence curve
- **ResponseTone**: Supportive/Pause/Reinforcing/Celebratory/Gentle/Engaged

### What Nox DOES NOT have
1. **NO 3-layer architecture** — Nox has flat silk array (~6 edges), no implicit layer
2. **NO ImplicitSilk** (37 channels, 1147 relationship types) — the most powerful layer is completely missing
3. **NO parent_map** (vertical silk) — no hierarchical node relationships
4. **NO Hebbian learning with phi-derived constants** — Nox uses simple co-activation
5. **NO 22 EdgeKind types** — Nox has generic associative only
6. **NO MolSummary 5D comparison** — Nox compares by keyword text
7. **NO sentence_affect walk** — Nox doesn't amplify emotions through graph walk
8. **NO HebbianLink (19-byte slim)** — Nox stores full edges
9. **NO CompoundKind patterns** — no semantic classification of relationships
10. **NO unified_neighbors()** merging implicit + learned layers

---

## 4. crates/memory — DreamCycle + QR Promotion + BuildZone

### What it does
Memory consolidation: scan STM -> cluster -> LCA -> propose QR. Plus hypothesis testing (BuildZone) and temporal scheduling.

### Key data structures

#### dream.rs — DreamCycle
- **DreamConfig**: `{scan_top_n, cluster_threshold(0.6), min_cluster_size(3), tree_depth, alpha(0.3), beta(0.4), gamma(0.3)}`
  - `for_conversation()`: lower threshold (0.30), smaller clusters (2)
- **DreamResult**: `{scanned, clusters_found, proposals, approved, rejected, matured_nodes}`
- **DreamCycle**: `run(stm, graph, ts)` -> DreamResult

**Pipeline**:
1. Scan STM top-N observations
2. Detect matured nodes (fire_count >= Fib[depth] AND Hebbian weight check)
3. Cluster by dual-threshold: `score = alpha*(chain_sim + implicit_bonus) + beta*hebbian_weight + gamma*co_act_ratio`
4. Union-Find clustering within same layer (QT11 enforcement)
5. LCA(cluster) -> new chain via `lca_many_weighted()`
6. Create DreamProposal (new node OR promote QR)
7. AAM review (approve/reject)

#### proposal.rs — AAM + DreamProposal
- **DreamProposal**: `{kind: NewNode{chain,sources,emotion,confidence} | PromoteQR{hash,fire_count,confidence}}`
- **AAM** (Autonomous Approval Module): reviews proposals
  - `Approved` if confidence >= threshold AND fire_count sufficient
  - `Rejected` if below threshold
  - `Pending` if borderline
- **RegistryGate**: validates before writing to registry, generates alerts

#### build.rs — BuildZone (Hypothesis Testing)
- **DraftEntry**: `{chain, description, fire_count, confidence, emotion, status, timestamps}`
- **BuildZone**: sandbox for hypotheses
  - `draft()` -> add hypothesis
  - `reinforce()` -> add evidence (diminishing returns)
  - `weaken()` -> counter-evidence
  - `promote()` -> confidence >= 0.90 + fire >= 5 -> DreamProposal
  - `supersede()` -> mark replaced (append-only, never delete)
- **ConsolidationScheduler**: circadian phases
  - Day (active, idle < 60s)
  - Dusk (light consolidation, 60s-5m idle)
  - Night (deep dream, 5m-30m idle, max 5 dreams)
  - Dawn (review, promote candidates)

### What Nox DOES NOT have
1. **NO proper DreamCycle** — Nox has `dream_cycle()` but it's keyword-based, not cluster+LCA
2. **NO dual-threshold clustering** (alpha/beta/gamma scoring)
3. **NO Union-Find clustering** within layers (QT11)
4. **NO AAM** (Autonomous Approval Module) — no proposal review
5. **NO BuildZone** (hypothesis testing) — no draft/reinforce/weaken/promote pipeline
6. **NO ConsolidationScheduler** (Day/Dusk/Night/Dawn phases)
7. **NO maturity detection** (Formula -> Evaluating -> Mature lifecycle)
8. **NO LCA-based chain generation** from clusters

---

## 5. crates/context — ContextEngine (Emotion + Analysis + Language)

### What it does
`f(x) = 0.6 * f_conv(t) + 0.4 * f_dn(nodes)` — emotional derivative across conversation.

### Sub-modules

#### emotion/affect.rs — Intent Detection + Word Affect
- **IntentKind**: 16 types (Learn, Heal, Command, Inform, Research, Technical, Creative, Explore, Manipulate, Risk, Crisis, Chat, Confirm, Deny, LearnCommand, ConfirmKnowledge)
- **IntentKind::detect()**: pattern matching on Vietnamese + English keywords
- **sentence_affect()**: word-level V/A + Silk walk amplification

#### emotion/curve.rs — ConversationCurve
- **f(x) = alpha * f_conv + beta * f_dn** where alpha = phi^-1, beta = phi^-2
- **f_conv = V + phi^-2 * V'(t) + phi^-3 * V''(t)** (first + second derivatives)
- Tracks: `curve, d1, d2, fx_conv, fx_dn, fx, window_variance, unstable`
- **Window variance**: detect emotional instability (variance > 0.04 + sign changes >= 2)
- **Instability override**: Gentle instead of Celebratory when unstable
- **update_dn()**: EMA `old * phi^-1 + new * phi^-2` (sum = 1.0 exact)

#### emotion/context.rs — ContextState
Full context tracking per conversation.

#### emotion/snapshot.rs — Emotion snapshots
Point-in-time emotion state capture.

#### analysis/engine.rs — ContextEngine
Main analysis engine combining all sub-modules.

#### analysis/fusion.rs — Cross-modal fusion
Text + audio -> blended emotion.

#### analysis/infer.rs — Inference engine
Context inference from STM + Silk.

#### analysis/intent.rs — Intent estimation
`estimate_intent()`, `decide_action()`, `IntentAction`.

#### language/phrase.rs — Phrase patterns
Vietnamese + English phrase templates.

#### language/word_guide.rs — Word lexicon
Emotion values per word.

#### language/template.rs — Response templates
Template-based response generation.

#### language/modality.rs — Multi-modal input
Text, audio, sensor modalities.

### What Nox DOES NOT have
1. **NO ConversationCurve with derivatives** — Nox has EMA 60/40 but no d1, d2, phi-derived constants
2. **NO window variance** (emotional instability detection)
3. **NO instability override** (Gentle when unstable)
4. **NO phi-derived alpha/beta** (phi^-1 + phi^-2 = 1.0 exact)
5. **NO cross-modal fusion** (text + audio)
6. **NO full 16-type IntentKind** — Nox has basic intent classification
7. **NO context inference** from STM + Silk combined

---

## 6. crates/homemath — Pure-Rust Math Library (no_std)

### What it does
Replaces libm with pure-Rust implementations of all math functions.

### Key functions (all no_std, zero deps)
- `sqrt(x)`: bit-level seed + 5 Newton-Raphson iterations (f64)
- `log(x)`: argument reduction + 11-term Taylor series
- `exp(x)`: range reduction + 13-term Taylor + 2^k bit manipulation
- `pow(x, y)`: integer fast-path + general exp(y*ln(x))
- `sin(x), cos(x)`: range reduction to [-pi/2, pi/2] + 8-term Taylor
- `tan(x), atan(x), atan2(y,x)`: derived from sin/cos
- `acosf(x)`: via asin with sqrt identity (f64 precision internally)
- f32 variants: `sqrtf, sinf, cosf, powf, log2f, fabsf, fmaxf, fminf`

### What Nox DOES NOT have
1. Nox has basic math via VM builtins (`__sqrt`, `__floor`, `__ceil`) but no trig, no log, no exp
2. **NO sin/cos/tan** — needed for SDF, FFR, physics
3. **NO log/exp/pow** — needed for Hebbian decay, formula evaluation
4. **NO atan/atan2** — needed for 3D rendering

---

## 7. crates/isl — ISL Encrypted Communication

### What it does
ISL = HomeOS addressing system. 4-byte addresses for all nodes.

### Key data structures
- **ISLAddress**: `[layer:u8, group:u8, subgroup:u8, index:u8]` = 4 bytes
  - ROOT = [0,0,0,0], BROADCAST = [FF,FF,FF,FF]
  - `child()`: create sub-address at next layer
- **ISLAllocator**: counter per (layer,group,subgroup) namespace -> unique index
  - `alloc_from_hash(depth, hash)`: derive address from molecular chain hash
  - Max 256 addresses per namespace
- **ISLMessage**: 12 bytes base (codec.rs)
- **ISLCodec**: encode/decode + AES-256-GCM ready (codec.rs)
- **ISLQueue**: message queue (queue.rs)

### What Nox DOES NOT have
1. **NO ISL addressing** — nodes have no spatial address
2. **NO ISLAllocator** — no collision-free address assignment
3. **NO ISL message protocol** — no inter-agent communication format

---

## 8. crates/hal — Hardware Abstraction Layer

### What it does
Platform-agnostic traits for x86/ARM/RISC-V/ESP32/WASM.

### Key types
- **Architecture**: x86_64, ARM64, RISCV64, WASM, ESP32, RP2040
- **HardwareTier**: T0 (embedded), T1 (mobile), T2 (desktop), T3 (server)
- **HalPlatform trait**: device discovery, capability query
- **SystemProbe**: vulnerability scanning, security assessment
- **SecurityScanner**: process inspection, network connections, threat level
- **PlatformBridge**: FFI to native platform APIs

### What Nox DOES NOT have
- Nox has direct syscalls (TCP, UDP, file I/O) but no HAL abstraction
- No tier classification, no security scanning, no platform bridge

---

## 9. crates/agents — Agent Hierarchy

### What it does
3-tier agent architecture: AAM (tier 0) / LeoAI+Chief (tier 1) / Worker (tier 2).

### Sub-modules

#### hierarchy/leo.rs — LeoAI (orchestrator)
Main AI personality. Coordinates all agents.

#### hierarchy/chief.rs — Chief (domain expert)
Specialized chiefs for different domains.

#### hierarchy/worker.rs — Worker (device agent)
HomeOS instance on each device.

#### pipeline/encoder.rs — ContentEncoder
Universal encoder for ALL input types:
- **Text**: split sentences -> phrases -> words -> chars -> encode_codepoint -> LCA chains
- **Audio**: freq_hz, amplitude, pitch -> molecule
- **Sensor**: temperature/humidity/light/motion/sound/power -> molecule
- **Code**: structure/complexity -> molecule
- **Math**: operator/operands -> molecule
- **Image**: SDF type + brightness + motion + regions -> molecule
- **System**: event type -> molecule

#### pipeline/learning.rs — LearningLoop
**ShortTermMemory**: max 512 observations with dedup by chain_hash
**Observation**: `{chain, emotion, timestamp, fire_count, mol_summary, maturity, layer}`
**Maturity lifecycle**: Formula -> Evaluating -> Mature (advance_with_eval)

#### pipeline/gate.rs — SecurityGate
- **EpistemicLevel**: Fact/Opinion/Hypothesis/Unknown/Deprecated
- **GateVerdict**: Allow/Block/BlackCurtain/Crisis
- Rule 1: no harm (absolute)
- Rule 2: insufficient evidence -> silence (QT9)
- Rule 3: no DELETE/OVERWRITE (QT8)

#### skills/ — Stateless skills
- **Instinct**: L0 hardwired behaviors
- **Skill trait**: `execute(input, context) -> output`
- **Domain skills**: Cluster, Similarity, Generalization, Ingest, Delta, Hebbian, Curator, Merge, Prune, TemporalPattern, InverseRender

### What Nox DOES NOT have
1. **NO multi-modal encoder** — Nox only encodes text (and barely)
2. **NO Maturity lifecycle** (Formula -> Evaluating -> Mature)
3. **NO SecurityGate with EpistemicLevel** — Nox has basic instincts
4. **NO agent hierarchy** — Nox has single flat agent
5. **NO domain skills** (11 specialized skills)
6. **NO audio/sensor/image/code encoding** — text only

---

## 10. crates/runtime — HomeRuntime

### What it does
Main runtime: `process_one(input) -> Response`. Coordinates all subsystems.

### Key components
- **HomeRuntime**: owns LearningLoop, ContextEngine, SilkGraph, Registry, etc.
- **OlangParser**: `○{...}` expression parser
- **MessageRouter**: route inputs to appropriate handler
- **AuthState**: master key, first-run setup, ISL signing
- **ResponseTemplate**: compose_response with language detection (Vietnamese/English)
- **Response**: `{text, tone, fx, kind}` where kind = Natural/OlangResult/Crisis/Blocked/System

### What Nox DOES NOT have
1. Nox has REPL but no full runtime pipeline
2. **NO OlangParser** for `○{...}` expressions
3. **NO AuthState** with ISL signing
4. **NO ResponseTemplate** with language detection

---

## 11. crates/olang — Core Language + Molecular Foundation

### What it does
Core types: Molecule, MolecularChain, LCA, encoder, KnowTree, VM, compiler, crypto.

### Key molecular types

#### mol/molecular.rs
- **Molecule**: packed u16 `[S:4][R:4][V:3][A:3][T:2]`
- **MolecularChain**: `Vec<u16>` — DNA of a concept
- **ShapeBase**: 18 SDF primitives (0-17)
- **RelationBase**: 8 relations (Member/Subset/Equiv/Orthogonal/Compose/Causes/Similar/DerivedFrom)
- **CsgOp**: Union/Intersect/Subtract
- **Maturity**: Formula -> Evaluating -> Mature
- **ComposeOp**: how chain was created
- **NodeState**: Draft/Active/Superseded

#### mol/formula.rs — Formula Engine (FE.1-8)
- **RelationOp**: 16 category theory operations (Identity, Member, Subset, Equality, Order, Arithmetic, Logical, SetOp, Compose, Causes, Approximate, Orthogonal, Aggregate, Directional, Bracket, Inverse)
  - Each has `compose(a, b) -> u16` with specific semantics
- **ValenceState**: 8 states (HighBarrier -> VeryDeepWell) with potential energy physics
  - `potential(v)`, `force(v)` — derived from v_norm
- **ArousalState**: 8 states with damped oscillator physics
  - `damping(a)`, `frequency(a)`, `amplitude(a)`

#### mol/formula_adaptive.rs — KnowTree-backed formula
3-tier fallback: KnowTree L1 -> UCD P_weight table -> hardcode
Fibonacci sample sizes by maturity: gen0=2, gen1=5, gen2=13, gen3=55

#### mol/encoder.rs — Codepoint -> MolecularChain
- `encode_codepoint(cp)`: UCD lookup -> Molecule (3-tier: L0 table -> alias -> raw)
- `encode_zwj_sequence()`: ZWJ emoji -> multi-molecule chain
- `encode_flag()`: regional indicator pair

#### mol/lca.rs — LCA Compose Engine
v2 rules (biological, NOT averaging):
- S = Union(A_s, B_s) — dominant shape (CSG)
- R = Compose — if inputs differ
- V = amplify(Va, Vb, w) — synergy amplification
- A = max(A_a, B_a) — intensity takes higher
- T = dominant(A_t, B_t) — time takes dominant

**LcaResult**: `{chain, variance, dim_variance[5], extremity}`
- variance < 0.15 = concrete, < 0.40 = categorical, >= 0.40 = abstract

4 Required Properties: Idempotent, Commutative, Similarity bound, Associative

#### mol/spline.rs — SplineKnot
`{timestamp, amplitude, frequency, phase, duration}` for T dimension animation.

#### storage/knowtree.rs — KnowTree
Hierarchical knowledge storage: L0 (UCD) -> L1 -> L2 -> ... with aggregate P_weights.

#### storage/registry.rs — Registry
Node registration with ISL addresses, fire counts, timestamps.

### What Nox DOES NOT have
1. **NO Formula Engine** (16 RelationOps, 8 ValenceStates, 8 ArousalStates) — this is the BRAIN Nox needs
2. **NO LCA compose** (biological amplification, not averaging)
3. **NO variance/extremity** in LCA results
4. **NO formula_adaptive** (3-tier KnowTree -> UCD -> hardcode)
5. **NO Maturity lifecycle** (Formula -> Evaluating -> Mature)
6. **NO proper MolecularChain** operations (similarity_full, chain_hash)
7. **NO SplineKnot** for T dimension

---

## 12. crates/wasm — WebAssembly Bindings

### What it does
Exposes HomeOS API to JavaScript/browser via wasm-bindgen.

### Key API
- `HomeOSWasm::process(input) -> JSON`
- `drain_events() -> binary frames`
- `read_book(text) -> sentence_count`
- `dream()`, `stats()`, `encode_cp()`

### What Nox DOES NOT have
- Nox has `wasm_emit.ol` stub but no working WASM target

---

## PRIORITY PORT LIST (What Nox needs most urgently)

### BLOCKER-LEVEL (must port to fix current blockers)

| Priority | Rust Module | Why | Nox Impact |
|----------|------------|-----|------------|
| **P0** | `olang/mol/formula.rs` | 16 RelationOps + compose() | Fixes BLOCKER #1 (mol collision) — different text gets different P_weights |
| **P0** | `olang/mol/lca.rs` | Biological LCA (amplify, not average) | Fixes BLOCKER #2 (silk low) + BLOCKER #4 (search same) |
| **P0** | `silk/index.rs` | Implicit Silk (37 channels, 0-cost) | Fixes BLOCKER #2 (silk low) — instant 1147 relationship types |
| **P1** | `silk/hebbian.rs` | Phi-derived constants, proper strengthen/decay | Better learning, prevents weight saturation |
| **P1** | `memory/dream.rs` | Proper DreamCycle with clustering | Knowledge consolidation actually works |

### HIGH PRIORITY (brain rewrite foundation)

| Priority | Rust Module | What to port |
|----------|------------|-------------|
| **P2** | `silk/graph.rs` | 3-layer SilkGraph + parent_map + unified_neighbors |
| **P2** | `context/emotion/curve.rs` | ConversationCurve with d1/d2/phi-derived/instability |
| **P2** | `memory/build.rs` | BuildZone + ConsolidationScheduler |
| **P2** | `olang/mol/formula_adaptive.rs` | 3-tier lookup: KnowTree -> UCD -> hardcode |
| **P2** | `agents/pipeline/learning.rs` | Maturity lifecycle (Formula -> Evaluating -> Mature) |

### MEDIUM PRIORITY (body / rendering)

| Priority | Rust Module | What to port |
|----------|------------|-------------|
| **P3** | `homemath` | sin/cos/exp/log/pow — needed for SDF + physics |
| **P3** | `vsdf/shape/sdf.rs` | 18 SDF primitives |
| **P3** | `vsdf/render/ffr.rs` | FFR 5D addressing |
| **P3** | `isl/address.rs` | ISLAddress + ISLAllocator |
| **P3** | `agents/pipeline/gate.rs` | SecurityGate + EpistemicLevel |

### LOWER PRIORITY (infrastructure)

| Priority | Rust Module | What to port |
|----------|------------|-------------|
| **P4** | `vsdf/render/parametric.rs` | T x S integration |
| **P4** | `vsdf/dynamics/` | Physics, splines, delta compression |
| **P4** | `hal/` | Hardware abstraction |
| **P4** | `agents/hierarchy/` | Agent tiers (Leo/Chief/Worker) |
| **P4** | `wasm/` | WASM bindings |

---

## KEY INSIGHT: The 4 blockers trace to 2 missing Rust modules

```
BLOCKER #1 (mol collision) ← missing formula.rs (RelationOp.compose())
BLOCKER #2 (silk low)      ← missing silk/index.rs (ImplicitSilk)
BLOCKER #3 (VM heap)       ← VM bug (not Rust-related)
BLOCKER #4 (search same)   ← missing lca.rs (biological compose, not average)
```

**The rewrite should start with: formula.rs -> lca.rs -> silk/index.rs -> hebbian.rs -> dream.rs**

This matches the spec order: A (Molecule) -> B (Silk) -> C (Neuron lifecycle) -> D (Pipeline).
