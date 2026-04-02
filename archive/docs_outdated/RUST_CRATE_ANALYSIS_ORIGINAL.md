# RUST CRATE ANALYSIS -- Original Unmodified Source

**Source**: `/tmp/Origin_RUST/Origin-claude-review-and-fix-project-dSfvz/crates/`
**Date**: 2026-03-31
**Purpose**: Complete extraction of algorithms, formulas, data structures from ALL 12 Rust crates. For each item, note whether Olang (origin.olang) currently has it.

---

## Table of Contents

1. [ucd -- THE FORMULA ENGINE](#1-ucd----the-formula-engine)
2. [vsdf -- SDF RENDERING](#2-vsdf----sdf-rendering)
3. [silk -- SILK SYSTEM](#3-silk----silk-system)
4. [memory -- MEMORY + MATURITY](#4-memory----memory--maturity)
5. [homemath -- MATH FORMULAS](#5-homemath----math-formulas)
6. [olang -- CORE MOLECULAR SYSTEM](#6-olang----core-molecular-system)
7. [agents -- LEARNING PIPELINE](#7-agents----learning-pipeline)
8. [context -- CONTEXT ENGINE](#8-context----context-engine)
9. [isl -- INTER-SYSTEM LANGUAGE](#9-isl----inter-system-language)
10. [runtime -- RUNTIME + AUTH](#10-runtime----runtime--auth)
11. [hal -- HARDWARE ABSTRACTION](#11-hal----hardware-abstraction)
12. [wasm -- WASM BRIDGE](#12-wasm----wasm-bridge)
13. [PORTING PRIORITY](#13-porting-priority)

---

## 1. ucd -- THE FORMULA ENGINE

**Files**: `src/lib.rs`, `build.rs`
**Role**: Unicode Character Database -- maps codepoint to 5D P_weight. THE source of truth for all molecular encoding.

### Data Structures

```
UcdEntry {
    cp:       u32,     // Unicode codepoint
    group:    u8,      // 0x01=SDF, 0x02=MATH, 0x03=EMOTICON, 0x04=MUSICAL
    shape:    u8,      // S dimension (raw u8 from udc.json)
    relation: u8,      // R dimension
    valence:  u8,      // V dimension 0x00..0xFF
    arousal:  u8,      // A dimension 0x00..0xFF
    time:     u8,      // T dimension
    p_weight: u16,     // packed [S:4][R:4][V:3][A:3][T:2]
    hash:     u64,     // FNV-1a of [shape,rel,val,aro,time]
    name:     &str,    // human-readable name
}
```

### P_weight Packing Formula

```
P_weight u16: [S:4][R:4][V:3][A:3][T:2] = 16 bits total
  S = shape >> 4        (4 bits, 0-15)
  R = relation >> 4     (4 bits, 0-15)
  V = valence >> 5      (3 bits, 0-7)
  A = arousal >> 5      (3 bits, 0-7)
  T = time >> 6         (2 bits, 0-3)

pack_p_weight(s,r,v,a,t) = (s4<<12) | (r4<<8) | (v3<<5) | (a3<<2) | t2
```

### Key Algorithms

| Algorithm | Description | Olang has? |
|-----------|-------------|------------|
| `lookup(cp)` | Forward: cp -> UcdEntry via binary search O(log n) | YES -- `ucd_lookup` builtin |
| `decode_hash(hash)` | Reverse: FNV-1a hash -> cp via binary search O(log n) | PARTIAL -- has FNV hash but no reverse table |
| `bucket_cps(shape, relation)` | Bucket: (S,R) -> [cp] for top-n candidates O(1) | NO |
| `p_weight_of(cp)` | Packed u16 P_weight lookup | YES -- `mol_encode` |
| `p_weight_full(cp)` | L0 first, then alias table fallback | YES -- encoder handles this |
| `alias_p_weight(cp)` | UTF-32 alias table (33K+ entries) for non-L0 codepoints | YES -- DNA has 161K P_weights |
| `chain_hash(s,r,v,a,t)` | FNV-1a of 5 bytes | YES -- `mol_hash` builtin |
| `mode_p_weight(pws)` | Per-dimension mode (most frequent) for aggregate | NO -- Olang uses average |
| `shape_of/relation_of/valence_of/arousal_of/time_of` | Per-dimension accessors with defaults | YES |

### KnowTree Hierarchy (build.rs)

- **4 groups (L0)**: SDF, MATH, EMOTICON, MUSICAL
- **53 blocks (L1)**: Unicode block ranges, each mapped to a group
- **8,284 characters (L2)**: Individual UcdEntry sorted by codepoint
- **Aggregate P_weight**: Per-dimension mode (most frequent value across children)
- **Block range parsing**: "2190..21FF" hex range format

| Feature | Olang has? |
|---------|------------|
| 4-group L0 hierarchy | YES |
| 53-block L1 hierarchy | PARTIAL -- flat array, no block structure |
| Aggregate P_weight via mode | NO -- uses average or first |
| group_blocks(idx) / block_chars(idx) API | NO |

### SDF + RELATION Primitives (build.rs)

- **18 SDF Primitives**: Sphere(0x25CF), Box(0x25A0), Capsule(0x25AC), Plane(0x25BD), Torus(0x25CB), Ellipsoid(0x2B2E), Cone(0x25B2), Cylinder(0x25AD), Diamond/Octahedron(0x25C6), Pyramid(0x25B3), HexPrism(0x2B21), Prism(0x25B1), RoundBox(0x25A2), Link/Infinity(0x221E), Revolve(0x21BB), Extrude(0x21E7), CutSphere(0x25D0), DeathStar(0x2606)
- **8 RELATION Primitives**: Member(0x2208), Subset(0x2282), Equiv(0x2261), Orthogonal(0x22A5), Compose(0x2218), Causes(0x2192), Similar(0x2248), DerivedFrom(0x2190)

| Feature | Olang has? |
|---------|------------|
| 18 SDF primitive constants | YES -- in sdf_data |
| 8 RELATION primitive constants | YES |
| is_sdf_primitive(cp) check | NO |

### UTF-32 Alias Table (T15)

- **41,338 entries** from `udc_utf32_compact.json`
- Format: `(codepoint: u32, p_weight: u16)` sorted by cp
- Excludes L0 codepoints (already in UCD_TABLE)
- Binary search O(log n) for lookup

| Feature | Olang has? |
|---------|------------|
| Alias table for non-L0 codepoints | YES -- DNA has this |
| Binary search on alias table | YES |

---

## 2. vsdf -- SDF RENDERING

**Files**: `shape/sdf.rs`, `shape/fit.rs`, `shape/body.rs`, `render/ffr.rs`, `render/parametric.rs`, `render/scene.rs`, `render/occlusion.rs`, `dynamics/physics.rs`, `dynamics/vector.rs`, `dynamics/spline.rs`, `dynamics/delta.rs`

### Data Structures

```
Vec3 { x: f32, y: f32, z: f32 }           -- 3D point
SdfKind (enum, 18 variants, 0x01..0x12)    -- SDF primitive type
SdfParams { r, r2, h, b: Vec3 }            -- SDF parameters
FfrPoint { index, shape, relation, valence, arousal, time }  -- Fibonacci 5D point
ParametricSdf { shape, amplitude, phase, frequency }         -- SDF + T params
Transform { position: Vec3, scale, rotation_y }              -- 3D transform
Material { r, g, b, alpha, roughness, emission }             -- Visual material
SceneNode { id, kind, params, transform, material, parent, chain_hash, visible, label }
SceneGraph { nodes, camera_pos, light_dir, ambient }
OcclusionBuffer { frames[5], head, count }  -- Ring buffer for SDF occlusion
SdfDelta { kind?, scale?, offset?, r_delta?, h_delta? }     -- Delta inheritance
BezierSegment { p0, p1, p2, p3 }           -- Cubic Bezier
VectorSpline { segments: Vec<BezierSegment> }
VectorField { kind, direction: Vec3, intensity: VectorSpline, ambient }
EmotionField { valence, arousal, dominance, intensity: 4x VectorSpline }
Particle { pos: Vec3, vel: Vec3, mass, radius }
PhysicsWorld { obstacle_kind, obstacle_params, gravity, wind, heat, damping, time }
```

### 18 SDF Functions (sdf.rs)

Each function computes signed distance: f(p) < 0 inside, = 0 surface, > 0 outside.

| SDF | Formula | Olang has? |
|-----|---------|------------|
| sphere(p, r) | `len(p) - r` | NO |
| sdf_box(p, b) | `len(max(abs(p)-b, 0)) + min(max_comp(abs(p)-b), 0)` | NO |
| round_box(p, b, r) | `sdf_box(p, b) - r` | NO |
| torus(p, r1, r2) | `len(sqrt(px^2+pz^2)-r1, py) - r2` | NO |
| capsule(p, a, b, r) | `len(pa - ba*clamp(dot(pa,ba)/dot(ba,ba))) - r` | NO |
| cone(p, h, r1, r2) | Complex -- truncated cone | NO |
| cylinder(p, r, h) | `min(max(xz_len-r, abs(y)-h), 0) + len(max(...))` | NO |
| ellipsoid(p, r) | `k0*(k0-1)/k1` where k0,k1 = normalized lengths | NO |
| pyramid(p, h) | Complex -- 4-sided pyramid | NO |
| plane(p, n, h) | `dot(p, n) + h` | NO |
| link(p, le, r1, r2) | Chain link topology | NO |
| hex_prism(p, h) | Hexagonal cross-section | NO |
| tri_prism(p, h) | Triangular cross-section | NO |
| solid_angle(p, r, angle) | Wedge shape | NO |
| cut_sphere(p, r, h) | Sphere with flat cut | NO |
| cut_hollow_sphere(p, r, h, t) | Hollow cut sphere | NO |
| death_star(p, ra, rb, d) | `max(sphere(p,ra), -sphere(p-d,rb))` | NO |
| octahedron(p, s) | 8-faced solid | NO |

### SDF Boolean Operations

| Operation | Formula | Olang has? |
|-----------|---------|------------|
| union(a, b) | `min(a, b)` | NO |
| subtract(a, b) | `max(-b, a)` | NO |
| intersect(a, b) | `max(a, b)` | NO |
| smooth_union(a, b, k) | `min(a,b) - h*h*k*0.25` where h = max(k-abs(a-b), 0)/k | NO |

### FFR -- Fibonacci Fractal Representation (ffr.rs)

```
FFR(n) = position n on 5D Fibonacci spiral:
  shape    = Fib(n) mod 7
  relation = Fib(n+1) mod 8
  valence  = Fib(n+2) mod 256
  arousal  = Fib(n+3) mod 256
  time     = Fib(n+4) mod 5

fib64(n) -- Fibonacci mod 2^64
FfrPoint::at(n) -- compute 5D coordinates
FfrPoint::to_molecule() -- convert to Molecule with quantized bits
ffr_chain(start, n) -- generate chain of n consecutive FFR points
ffr_nearest(target, max_index) -- find closest FFR point to molecule
molecule_similarity(a, b) = 0.3*shape + 0.2*relation + 0.4*emotion + 0.1*time
```

| Feature | Olang has? |
|---------|------------|
| Fibonacci sequence computation | NO |
| FFR 5D spiral addressing | NO |
| FFR nearest search | NO |
| molecule_similarity() | PARTIAL -- has mol_similarity but different weights |

### Parametric SDF (parametric.rs) -- FE.8: T x S Integration

```
ParametricSdf = SDF primitive + T parameters (amplitude, phase, frequency)
  T.amplitude -> radius/size
  T.phase -> Y-axis position offset
  T.frequency -> oscillation (sin(freq * t * TAU) * r * 0.1)

eval(p, time) = sdf(kind, p_local, params) where p_local adjusted by phase + motion
sdf_union(shapes, p, time) = min over all shapes
sdf_smooth_union(shapes, p, time, k) = smooth_union fold
```

| Feature | Olang has? |
|---------|------------|
| T x S parametric integration | NO |
| Motion oscillation from frequency | NO |
| CSG union/smooth_union of parametric shapes | NO |

### Scene Graph (scene.rs)

```
SceneGraph: manages 3D scene with nodes, camera, lighting
  add() / remove() / set_parent() -- scene hierarchy
  render_list() -- front-to-back sort by distance to camera
  ray_hit(origin, dir, max_dist) -- sphere marching (64 steps)
  to_json() -- export for browser/WebGL
  to_bytes() -- compact binary export (33 bytes/node)

Transform: world_to_local / local_to_world with rotation + scale
diffuse_shade(kind, p, params, light, ambient, intensity) = ambient + max(0, dot(grad, light)) * intensity
```

| Feature | Olang has? |
|---------|------------|
| Scene graph with hierarchy | NO |
| Sphere marching ray casting | NO |
| Transform (translate/rotate/scale) | NO |
| JSON/binary scene export | NO |
| Diffuse shading | NO |

### Physics (physics.rs)

```
gradient(kind, p, params) -- analytical nabla-SDF per primitive
  grad_sphere(p) = normalize(p)
  grad_plane() = (0,1,0)
  grad_box(p, params) -- sign-based, face selection
  grad_capsule(p, params) -- clamp projection
  grad_torus(p, params) -- chain rule analytical
  grad_cylinder(p, params) -- radial vs cap
  grad_numerical(kind, p, params) -- central differences fallback (eps=0.001)

Particle physics:
  integrate(force, dt) -- semi-implicit Euler: v += a*dt, p += v*dt
  damp(factor) -- velocity *= factor
  PhysicsWorld.step(particles, dt):
    1. Collect forces from VectorFields (gravity + wind + heat)
    2. Integrate particle
    3. Collision resolve via gradient: push out + reflect velocity (bounce=0.3)
```

| Feature | Olang has? |
|---------|------------|
| Analytical SDF gradients | NO |
| Numerical gradient fallback | NO |
| Particle physics simulation | NO |
| Collision resolution via SDF gradient | NO |
| VectorField force integration | NO |

### VectorField (vector.rs) -- QT6: Invisible = Vector Spline

```
FieldKind: Light, Wind, Heat, Audio, Emotion, Gravity, Custom
VectorField { kind, direction: Vec3, intensity: VectorSpline, ambient }
  evaluate(t) = direction * (intensity.evaluate(t) + ambient)
  sunlight() -- day cycle: dawn->noon->dusk via Bezier
  gravity(g) -- constant (0,-1,0)*g
  wind(dir, strength) -- constant direction + flat intensity
  heat(source, temp) -- point source + flat temp

EmotionField { valence, arousal, dominance, intensity: 4x VectorSpline }
  sample(t) -> EmotionSample { t, v, a, d, i }
  arc(start_v, peak_v, end_v, duration) -- emotion arc via Bezier
  valence_rate(t) -- derivative of valence spline
```

| Feature | Olang has? |
|---------|------------|
| VectorField with spline intensity | NO |
| Sunlight day cycle | NO |
| EmotionField with 4D splines | NO |
| Emotion arc (start->peak->end) | NO |
| Bezier cubic spline evaluation | NO |
| Bezier derivative | NO |

### Delta Inheritance (delta.rs)

```
SdfDelta { kind?, scale?, offset?, r_delta?, h_delta? }
  L4 stores full SDF, L5+ stores only delta from parent
  apply_delta(base_kind, base_params, delta) -> (kind, params)
  walk_up(deltas) -> cumulative delta

Savings: 99.9% shared -> only store 0.1% difference (~20 bytes vs ~32 bytes full)
```

| Feature | Olang has? |
|---------|------------|
| Delta inheritance for SDF | NO |
| Walk-up delta chain | NO |

### Occlusion Buffer (occlusion.rs)

```
OcclusionBuffer: ring buffer of 5 frames
  push(frame) -- FIFO ring
  is_occluded() -- all 5 frames have distance < 0
  movement_variance() -- variance of distances across frames
```

| Feature | Olang has? |
|---------|------------|
| Temporal occlusion buffer | NO |
| Movement detection via variance | NO |

---

## 3. silk -- SILK SYSTEM

**Files**: `edge.rs`, `graph.rs`, `hebbian.rs`, `index.rs`, `walk.rs`

### Data Structures

```
EmotionTag { valence: f32, arousal: f32, dominance: f32, intensity: f32 }
EdgeKind (enum, 22 variants: 8 structural + 5 space + 5 time + 1 language + 3 associative)
ModalitySource (enum: Text, Audio, Image, Bio, Fused)
SilkEdge { from_hash, to_hash, kind, emotion, weight, fire_count, created_at, updated_at, source, confidence } -- 46 bytes
HebbianLink { from_hash, to_hash, weight: u8, fire_count: u16 } -- 19 bytes (59% smaller)
MolSummary { shape, relation, valence, arousal, time: all u8 }
SilkNeighbor { hash, weight, implicit, hebbian, shared_dims }
SilkDim (enum: Shape(u8), Relation(u8), Valence(u8), Arousal(u8), Time(u8))
ImplicitSilk { shared_dims: Vec<SilkDim>, strength: f32, shared_count: u8 }
CompoundKind (enum, 31 variants: C(5,1)+C(5,2)+C(5,3)+C(5,4)+C(5,5))
SilkIndex { buckets: 37 channels (8S+8R+8V+8A+5T), each = Vec<u64> }
SilkGraph { edges, edge_index (BTreeMap), index (SilkIndex), learned (Vec<HebbianLink>), parent_map (BTreeMap) }
```

### 3-Layer Architecture

| Layer | Type | Storage | Description |
|-------|------|---------|-------------|
| 1. Implicit | SilkIndex | 0 bytes/edge | 37 channels x 5D -- mathematical consequence |
| 2. Learned | HebbianLink | 19 bytes/link | Hebbian co-activation discovery |
| 3. Structural | SilkEdge | 46 bytes/edge | Backward compat, parent pointers |

### Key Algorithms

| Algorithm | Formula | Olang has? |
|-----------|---------|------------|
| `MolSummary::similarity(a, b)` | 5D comparison: each dim match +0.20, near +0.10 | PARTIAL -- has mol_similarity but simpler |
| `EmotionTag::blend(other, alpha)` | `self*alpha + other*(1-alpha)` per dim | YES |
| `EmotionTag::distance_va(other)` | `sqrt(dv^2 + da^2)` | YES |
| `EmotionTag::from_ucd_bytes(v_byte, a_byte)` | V: byte/128 - 1.0, A: byte/255 | YES |

### Hebbian Learning (hebbian.rs) -- CRITICAL FORMULAS

```
PHI = (1 + sqrt(5)) / 2 = 1.618034       -- golden ratio, COMPUTED not hardcoded
PHI_INV = (sqrt(5) - 1) / 2 = 0.618034   -- decay factor per 24h
LR = PHI_INV^3 = 0.236                    -- learning rate
PROMOTE_WEIGHT = PHI_INV + PHI_INV^3 = 0.854  -- promote threshold

hebbian_strengthen(weight, reward):
  delta = reward * (1 - w) * phi_inv^3
  return min(w + delta, 1.0)
  (Uses f64 internally for precision)

hebbian_decay(weight, elapsed_ns):
  days = elapsed_ns / 86_400_000_000_000
  return weight * phi_inv^days
  (Uses f64 phi_inv computed from sqrt)

should_promote(weight, fire_count, depth):
  weight >= PROMOTE_WEIGHT AND fire_count >= Fib(depth)

fib(n): Fibonacci sequence -- threshold per depth level
blend_emotion(current, new, intensity): blend with intensity weight
```

| Feature | Olang has? |
|---------|------------|
| PHI from sqrt(5) computation | YES -- `phi_golden` |
| hebbian_strengthen formula | YES -- `silk_strengthen` |
| hebbian_decay with PHI_INV^days | YES -- `silk_decay` |
| Fibonacci threshold per depth | YES -- `fib` function |
| should_promote logic | YES -- `silk_promote_check` |
| f64 precision for Hebbian | NO -- Olang uses f64 natively in VM |

### Implicit Silk Index (index.rs)

```
37 channels: 8 Shape + 8 Relation + 8 Valence zones + 8 Arousal zones + 5 Time
1147 relationship types: 37 channels x 31 compound patterns

SilkIndex::implicit_silk(mol_a, mol_b):
  Compare each of 5 dimensions
  shape: same base (mod 8) -> shared
  relation: same base (mod 8) -> shared
  valence: same zone (byte / 32) -> shared
  arousal: same zone (byte / 32) -> shared
  time: same base (mod 5) -> shared
  strength = base + precision_bonus (exact match)

31 CompoundKind patterns:
  C(5,1)=5 single-dim, C(5,2)=10 pairs, C(5,3)=10 triples,
  C(5,4)=5 four-dim, C(5,5)=1 identical

index_node(hash, mol) -- register into buckets
query_bucket(dim, value) -- all nodes in bucket
neighbors_of(hash) -- all bucket co-members
```

| Feature | Olang has? |
|---------|------------|
| 37-channel implicit Silk | NO -- only explicit edges |
| 31 CompoundKind patterns | NO |
| Bucket-based 5D indexing | NO |
| implicit_silk(a, b) computation | NO |
| 1147 relationship type classification | NO |

### Parent Map (Silk Vertical)

```
parent_map: BTreeMap<u64, u64> -- child_hash -> parent_hash
register_parent(child, parent)
parent_of(hash) -> Option<u64>
children_of(parent) -> Vec<u64>
layer_of(hash) -> u8 (walk up parent chain, max 16)
```

| Feature | Olang has? |
|---------|------------|
| parent_map persistence | YES -- know_tree has parent pointers |
| layer_of() via parent walk | PARTIAL -- has layer field but not walk |

### SilkGraph Unified API

```
co_activate(hash_a, hash_b, emotion, reward, ts):
  1. Index both nodes
  2. Create/strengthen HebbianLink
  3. Optionally create SilkEdge for backward compat

unified_weight(a, b) = max(implicit_strength, hebbian_weight)
unified_neighbors(hash, mol_summary) = implicit UNION hebbian (merged by hash)
assoc_weight(from, to) -- Hebbian weight lookup
cluster_score_partial(ha, hb, max_fire) -- for Dream clustering
```

| Feature | Olang has? |
|---------|------------|
| co_activate() | YES -- `silk_coactivate` |
| unified_weight combining implicit + learned | NO |
| unified_neighbors merging layers | NO |
| Structural + associative edge separation | PARTIAL |

---

## 4. memory -- MEMORY + MATURITY

**Files**: `dream.rs`, `build.rs`, `proposal.rs`

### DreamCycle (dream.rs)

```
DreamConfig {
  scan_top_n: 32, cluster_threshold: 0.6, min_cluster_size: 3,
  tree_depth: 3, alpha: 0.3, beta: 0.4, gamma: 0.3
}

DreamCycle::run(stm, graph, ts):
  1. Scan STM top-N observations
  1a. Collect matured nodes (fire_count >= fib(depth) + Hebbian weight check)
  2. find_clusters() via dual-threshold + Union-Find
  3. For each cluster: LCA(chains, weights) -> new chain
  4. Create DreamProposal (new_node, promote_qr)
  5. AAM review -> approve/reject

Cluster score formula:
  score(A,B) = alpha * (chain_sim + implicit_bonus) + beta * hebbian_weight + gamma * co_act_ratio
  Default: 0.3 * similarity + 0.4 * hebbian + 0.3 * co_activation
  
  chain_sim: MolSummary::similarity() or chain byte similarity (fallback)
  implicit_bonus: SilkIndex::implicit_silk(a,b).strength * 0.5
  hebbian: bidirectional max assoc_weight
  co_act: cluster_score_partial from graph

Clustering: Union-Find within same layer (QT11 enforcement)
Maturity check: advance_with_eval(fire_count, weight, fib_threshold, eval_dims)
```

| Feature | Olang has? |
|---------|------------|
| DreamCycle scan + cluster | YES -- `dream_cycle` command |
| Dual-threshold clustering formula | PARTIAL -- simpler clustering |
| Union-Find algorithm | NO -- uses simpler grouping |
| LCA with weighted chains | YES -- `lca_weighted` |
| AAM review flow | PARTIAL -- auto-approve |
| Maturity tracking (Formula->Evaluating->Mature) | NO |
| Per-layer clustering (QT11) | NO |
| Implicit Silk bonus in cluster score | NO |

### BuildZone (build.rs) -- Hypothesis Testing

```
DraftStatus: Active, Promoted, Superseded
DraftEntry { chain, description, fire_count, confidence, emotion, status, timestamps }
BuildZone { entries (append-only), promote_threshold: 0.90, min_fire: 5 }

draft() -> add hypothesis
reinforce(idx, conf, ts): fire_count++, confidence += conf*(1-conf)*0.5 (diminishing returns)
weaken(idx, penalty, ts): confidence -= penalty
is_promotable(): status==Active AND confidence >= 0.90 AND fire_count >= 5
promote(idx, ts) -> DreamProposal
supersede(idx, ts) -- mark replaced (NEVER delete, append-only QT10)

ConsolidationScheduler:
  idle < 60s  -> Day (active learning)
  60s-5min    -> Dusk (light consolidation)
  5min-30min  -> Night (deep dream, max 5 dreams)
  >30min      -> Dawn (review promotions)
```

| Feature | Olang has? |
|---------|------------|
| BuildZone hypothesis testing | NO |
| Diminishing returns reinforcement | NO |
| QT18 honesty threshold (0.90) | NO |
| Supersede (append-only, never delete) | NO |
| ConsolidationScheduler (Day/Dusk/Night/Dawn) | NO |

### Proposals (proposal.rs)

```
ProposalKind: NewNode, PromoteQR, NewEdge, SupersedeQR
DreamProposal { kind, confidence, timestamp }
AAMDecision: Approved, Rejected, Pending
AAM { min_confidence: 0.3 }
InsightKind: Causal, Contradiction, Abstraction, Analogy, Curiosity, SkillPattern
SkillProposal { skill_name, kind: InsightKind, confidence }
```

| Feature | Olang has? |
|---------|------------|
| Structured proposal system | PARTIAL -- has learn/promote |
| AAM gating with confidence | NO |
| InsightKind classification | NO |
| SkillProposal from instincts | NO |

---

## 5. homemath -- MATH FORMULAS

**Files**: `src/lib.rs`
**Role**: Pure Rust no_std math library replacing libm.

### Functions

| Function | Algorithm | Olang has? |
|----------|-----------|------------|
| `sqrt(x)` | Bit-level seed + 5 Newton-Raphson iterations (f64) | YES -- VM has sqrt |
| `log(x)` | Decompose x=m*2^e, ln(m) via series t + t^3/3 + ... (21 terms) | NO |
| `exp(x)` | Range reduction + Taylor e^r (13 terms) + 2^k bit manipulation | NO |
| `pow(x, y)` | Integer: squaring. General: exp(y*ln(x)) | YES -- VM has pow |
| `sin(x)` | Range reduction to [-pi/2, pi/2] + Taylor (9 terms) | YES -- VM has trig |
| `cos(x)` | sin(x + pi/2) | YES |
| `tan(x)` | sin/cos | YES |
| `atan(x)` | Range reduction + Taylor-like polynomial (6 terms) | NO |
| `atan2(y, x)` | Quadrant-aware atan | NO |
| `asin_f64(x)` | For abs(x)>0.7: identity transform + asin_small | NO |
| `acosf(x)` | pi/2 - asin(x) via f64 | NO |
| `floor/ceil/round` | Cast-based | YES -- VM builtins |
| `sqrtf(x)` | Bit-level seed + 4 Newton-Raphson (f32) | YES |
| `log2f(x)` | log(x) * LOG2_E | NO |
| `powf(x, y)` | Delegates to f64 pow | YES |

---

## 6. olang -- CORE MOLECULAR SYSTEM

**Files**: `mol/molecular.rs`, `mol/encoder.rs`, `mol/lca.rs`, `mol/formula.rs`, `mol/hash.rs`, `mol/separator.rs`, `mol/spline.rs`

### Data Structures (molecular.rs)

```
ShapeBase (enum, 18 variants: Sphere..DeathStar)
CsgOp (enum: Union, Intersect, Subtract)
RelationBase (enum, 8 variants: Member..DerivedFrom)
TimeDim (enum, 5 variants: Static..Instant)
EmotionDim { valence: u8, arousal: u8 }
ComposeOp (enum: Mean, Dominant, Amplify, Max)
CompositionOrigin (enum: Single, Pair, LCA)
NodeState (enum: STM, Evaluating, LTM, Protected)
Maturity (enum: Formula, Evaluating, Mature) -- lifecycle stages
Dimension (enum: Shape, Relation, Valence, Arousal, Time)

Molecule (u16 packed):
  bits: u16 -- packed [S:4][R:4][V:3][A:3][T:2]
  from_u16(bits) / pack(s,r,v,a,t) / raw(s,r,v,a,t)
  shape() / relation() / valence() / arousal() / time() -- quantized accessors
  shape_u8() / relation_u8() / valence_u8() / arousal_u8() / time_u8() -- raw byte accessors
  evaluated_count() -- number of dimensions with non-default values

MolecularChain(Vec<u16>):
  single(mol) / empty() / from_bits(vec)
  chain_hash() -- FNV-1a of all molecule bits
  first() / mol_at(idx) / len() / is_empty()
  similarity_full(other) -- 5D similarity per molecule, averaged
```

| Feature | Olang has? |
|---------|------------|
| Molecule packed u16 | YES -- `mol_new`, `mol_encode` |
| MolecularChain | YES -- arrays of packed molecules |
| chain_hash via FNV-1a | YES -- `mol_hash` |
| similarity_full | YES -- `mol_similarity` |
| Maturity lifecycle (Formula->Evaluating->Mature) | NO |
| evaluated_count() | NO |
| ComposeOp variants | NO |

### Encoder (encoder.rs)

```
encode_codepoint(cp):
  1. Try p_weight_of(cp) -- L0 UCD_TABLE
  2. Try p_weight_full(cp) -- alias table fallback
  3. Last resort: raw values from per-dim accessors
  Returns MolecularChain::single(Molecule::from_u16(p_weight))

encode_zwj_sequence(codepoints):
  mol[0..N-2].relation = Compose
  mol[N-1].relation = Member

encode_flag(ri1, ri2) -- Regional Indicator pair
```

| Feature | Olang has? |
|---------|------------|
| encode_codepoint from UCD | YES -- `mol_encode` |
| ZWJ sequence encoding | NO |
| Flag encoding | NO |

### LCA -- v2 Compose Engine (lca.rs)

```
LCA v2 compose rules (biological, NOT averaging):
  S = Union(A_s, B_s) -- dominant shape (CSG Union)
  R = Compose         -- if inputs differ
  V = amplify(Va, Vb, w) -- synergy amplification (NOT average)
  A = max(A_a, B_a)   -- intensity takes higher
  T = dominant(A_t, B_t) -- dominant time

4 required properties:
  1. Idempotent: LCA(a,a) == a
  2. Commutative: LCA(a,b) == LCA(b,a)
  3. Similarity bound: sim(LCA(a,b), a) >= sim(a,b) - epsilon
  4. Associative: LCA(LCA(a,b),c) ~ LCA(a,LCA(b,c))

LcaResult { chain, variance, dim_variance[5], extremity }
  variance: mean(1 - similarity(input_i, lca))
  extremity: mean(abs(value - midpoint)) for V+A
  
lca(a, b) -- equal weight
lca_weighted(pairs) -- with fire_count weights
lca_with_variance(pairs) -- full result with diagnostics
lca_many(chains) / lca_many_weighted(chains, weights)
```

| Feature | Olang has? |
|---------|------------|
| LCA compose | YES -- `lca` builtin |
| LCA weighted by fire_count | YES -- `lca_weighted` |
| LCA variance output | NO |
| LCA extremity measurement | NO |
| Per-dimension variance tracking | NO |
| Biological compose rules (amplify, not average) | PARTIAL |

### Formula Dispatch (formula.rs) -- FE.1-FE.3

```
FE.1 -- RelationOp (R: 0-15, 16 types from Category Theory):
  Identity, Member, Subset, Equality, Order, Arithmetic, Logical, SetOp,
  Compose, Causes, Approximate, Orthogonal, Aggregate, Directional, Bracket, Inverse

  Each RelationOp has compose(a_pw, b_pw) -> u16:
    Identity: pass through a
    Member/Subset: inherit container (b)
    Equality: if a==b then a, else a XOR b
    Order: max(a, b)
    Arithmetic: add dimensions mod range
    Logical: a AND b
    SetOp: a OR b
    Compose: use a's R, blend others from b
    Causes: b (effect inherits)
    Approximate: per-dimension average

FE.2 -- ValenceState (V: 0-7, potential energy physics):
  [Details in formula.rs beyond line 150]

FE.3 -- ArousalState (A: 0-7, damped oscillator physics):
  [Details in formula.rs beyond line 150]
```

| Feature | Olang has? |
|---------|------------|
| 16 RelationOp with compose semantics | NO |
| RelationOp::compose(a, b) -> u16 | NO |
| ValenceState physics model | NO |
| ArousalState damped oscillator | NO |
| Formula dispatch from P_weight | NO |

### SplineKnot / TimeHistory (spline.rs) -- FE.4, FE.5

```
SplineKnot { timestamp: u64, amplitude: f32, frequency: f32, phase: f32, duration: f32 } -- 24 bytes
TimeMode: Timeless(0), Sequential(1), Cyclical(2), Rhythmic(3) -- from T 2-bit value
TimeHistory { knots: Vec<SplineKnot> } -- append-only observation history
  push(knot), interpolate(t), predict(future_t)
```

| Feature | Olang has? |
|---------|------------|
| SplineKnot temporal observations | NO |
| TimeMode from T bits | NO |
| TimeHistory append-only | NO |
| Spline interpolation/prediction | NO |

### Separator System (separator.rs)

```
4 separators: ZWJ(U+200D), Plus(+), Space, Juxtapose(none)
  ZWJ: compose semantic -> 1 chain N molecules
  +: LCA operation -> 1 chain
  space: separate -> N chains
  none: juxtapose -> N chains

parse_tokens(input) -> Vec<SepToken>
token_to_chain(token) -> MolecularChain
parse_to_chains(input) -> Vec<MolecularChain>
```

| Feature | Olang has? |
|---------|------------|
| 4 separator types | PARTIAL -- has space and some operators |
| ZWJ sequence parsing | NO |
| Plus as LCA operator | NO |
| parse_to_chains pipeline | NO |

### FNV-1a Hash (hash.rs)

```
FNV_OFFSET = 0xcbf29ce484222325
FNV_PRIME = 0x100000001b3
fnv1a(data) -- hash bytes
fnv1a_str(s) -- hash string
fnv1a_namespaced(ns, data) -- hash with namespace prefix to avoid cross-domain collision
```

| Feature | Olang has? |
|---------|------------|
| FNV-1a hash | YES -- `fnv1a` builtin |
| Namespaced hashing | NO |

---

## 7. agents -- LEARNING PIPELINE

**Files**: `pipeline/learning.rs`, `pipeline/encoder.rs`, `pipeline/gate.rs`, `skills/instinct.rs`, `skills/skill.rs`, `hierarchy/chief.rs`, `hierarchy/leo.rs`, `hierarchy/worker.rs`

### ShortTermMemory (learning.rs)

```
Observation {
  chain, emotion, timestamp, fire_count,
  mol_summary: Option<MolSummary>,
  maturity: Maturity,
  layer: u8
}

ShortTermMemory { observations: Vec<Observation>, max_size: 512 }
  push(chain, emotion, ts): if exists -> fire_count++, blend emotion, advance maturity
  top_n(n) -> sorted by fire_count descending
```

| Feature | Olang has? |
|---------|------------|
| STM with observations | YES -- has STM array |
| fire_count tracking | YES |
| mol_summary caching | NO |
| Maturity advancement on push | NO |
| Layer-aware observations | NO |

### 7 Instinct Skills (instinct.rs)

```
1. AnalogySkill: A:B :: C:? via 5D delta
   D = C + (B - A) in quantized domain
   confidence = delta magnitude * clarity

2. AbstractionSkill: cluster -> common features
   Uses lca_with_variance for variance-based classification:
   < 0.15 concrete, < 0.40 categorical, >= 0.40 abstract

3. CausalitySkill: correlation vs causation
   Checks: time ordering + Hebbian weight + Silk path

4. ContradictionSkill: incompatible claims
   Detects: opposite valence + high arousal

5. CuriositySkill: knowledge gaps
   Novelty = 1.0 - max_similarity to existing nodes

6. ReflectionSkill: meta-knowledge
   Confidence in own knowledge

7. HonestySkill: "I don't know"
   Suppress output when confidence < threshold
```

| Feature | Olang has? |
|---------|------------|
| AnalogySkill (5D delta) | NO |
| AbstractionSkill (LCA variance) | NO |
| CausalitySkill | NO |
| ContradictionSkill | NO |
| CuriositySkill (novelty detection) | NO |
| ReflectionSkill | NO |
| HonestySkill | NO |

### ContentEncoder (encoder.rs)

```
ContentInput { text, sensor_kind, timestamp, emotion }
SensorKind: Text, Audio, Image, System
EncodedContent { chains, emotion, sensor, timestamp }

encode(input) -> EncodedContent:
  Parse text into segments
  Each segment -> encode_codepoint or alias lookup
  Return list of MolecularChains
```

| Feature | Olang has? |
|---------|------------|
| Multi-modal content encoding | PARTIAL -- text only |
| SensorKind classification | NO |

### SecurityGate (gate.rs)

```
GateVerdict: Allow, Deny(reason), RateLimit
SecurityGate { max_rate, deny_patterns }
gate.check(input) -> GateVerdict
```

| Feature | Olang has? |
|---------|------------|
| Input security gate | PARTIAL -- `safety_check` MCP tool |

---

## 8. context -- CONTEXT ENGINE

**Files**: `emotion/affect.rs`, `emotion/curve.rs`, `emotion/context.rs`, `emotion/snapshot.rs`, `analysis/engine.rs`, `analysis/fusion.rs`, `analysis/infer.rs`, `analysis/intent.rs`, `language/phrase.rs`, `language/word_guide.rs`, `language/template.rs`, `language/modality.rs`

### Core Formula

```
f(x) = 0.6 * f_conv(t) + 0.4 * f_dn(nodes)
x = emotion derivative of entire conversation
```

### Modules

| Module | Purpose | Olang has? |
|--------|---------|------------|
| emotion/affect | Emotion state V/A/D/I | PARTIAL -- has V/A only |
| emotion/curve | Conversation emotion curve | NO |
| emotion/context | Context accumulation | PARTIAL |
| emotion/snapshot | Emotion snapshots at key moments | NO |
| analysis/engine | ContextEngine main loop | NO |
| analysis/fusion | Cross-modal fusion | NO |
| analysis/infer | Inference from context | NO |
| analysis/intent | Intent classification | NO |
| language/phrase | Phrase templates | PARTIAL -- has response templates |
| language/word_guide | Word lexicon | NO |
| language/template | Response generation templates | PARTIAL |
| language/modality | Multi-modal handling | NO |

---

## 9. isl -- INTER-SYSTEM LANGUAGE

**Files**: `address.rs`, `codec.rs`, `message.rs`, `queue.rs`

```
ISLAddress: 4 bytes [layer/group/subgroup/index]
ISLMessage: 12 bytes base (95.7% smaller than JSON)
ISLCodec: encode/decode + AES-256-GCM ready
ISLQueue: priority queue for inter-agent messages
```

| Feature | Olang has? |
|---------|------------|
| ISL address system | NO |
| ISL message encoding | NO |
| ISL codec | NO |
| Priority message queue | NO |

---

## 10. runtime -- RUNTIME + AUTH

**Files**: `core/origin.rs`, `core/parser.rs`, `core/router.rs`, `auth/`, `output/`, `pipeline/`

- Router: HTTP/TCP message routing
- Auth: Ed25519 key management, signing, verification
- Output: Response templates, metrics, error formatting
- Pipeline: Concurrency, emotion tests

| Feature | Olang has? |
|---------|------------|
| HTTP routing | YES -- body has HTTP builtins |
| Auth/signing | YES -- crypto builtins |
| Metrics tracking | NO |
| Response templates | PARTIAL |

---

## 11. hal -- HARDWARE ABSTRACTION

**Files**: `detect/arch.rs`, `detect/probe.rs`, `detect/security.rs`, `detect/tier.rs`, `interface/driver.rs`, `interface/ffi.rs`, `interface/platform.rs`

- Hardware detection (CPU, memory, GPU)
- Security tier classification
- Platform-specific FFI

| Feature | Olang has? |
|---------|------------|
| Hardware detection | PARTIAL -- has syscall builtins |
| Security tiers | NO |
| FFI interface | NO |

---

## 12. wasm -- WASM BRIDGE

**Files**: `bridge.rs`, `lib.rs`

- WebAssembly bridge for browser execution
- Export core functions to WASM

| Feature | Olang has? |
|---------|------------|
| WASM bridge | NO |

---

## 13. PORTING PRIORITY

### CRITICAL -- Port FIRST (Blocker fixes)

1. **formula.rs FE.1-FE.3**: 16 RelationOp compose semantics + ValenceState + ArousalState. Without this, P_weights are just numbers with no behavioral meaning.

2. **Implicit Silk (index.rs)**: 37-channel 5D indexing + 31 CompoundKind patterns. This is why Olang has only 6 edges -- it has no implicit layer.

3. **formula.rs ValenceState/ArousalState**: Physics-based emotion (damped oscillator for arousal, potential energy for valence). Without this, all text maps to same P_weight.

### HIGH -- Port for brain rewrite

4. **DreamCycle cluster formula**: `alpha*chain_sim + beta*hebbian + gamma*co_act` with implicit bonus. Current Dream is too simple.

5. **BuildZone + ConsolidationScheduler**: Hypothesis testing + temporal consolidation (Day/Dusk/Night/Dawn cycle).

6. **7 Instinct Skills**: Analogy (5D delta), Abstraction (LCA variance), Causality, Contradiction, Curiosity, Reflection, Honesty.

7. **Maturity lifecycle**: Formula -> Evaluating -> Mature with evaluated_count tracking.

### MEDIUM -- Port for body enhancement

8. **18 SDF functions**: All distance functions from sdf.rs.

9. **SDF gradients**: Analytical gradients for sphere, box, capsule, torus, cylinder + numerical fallback.

10. **FFR addressing**: Fibonacci 5D spiral for spatial addressing.

11. **VectorField + EmotionField**: Spline-based time-varying fields.

12. **Scene graph**: 3D scene with hierarchy, ray casting, JSON/binary export.

### LOW -- Port when needed

13. **Parametric SDF**: T x S integration for motion.
14. **Delta inheritance**: L5+ compact storage.
15. **Occlusion buffer**: Temporal coherence for rendering.
16. **ISL messaging**: Inter-agent communication protocol.
17. **WASM bridge**: Browser execution.

---

## Summary Statistics

| Category | Rust has | Olang has | Gap |
|----------|---------|-----------|-----|
| SDF primitives | 18 functions | 0 | 18 |
| SDF boolean ops | 4 | 0 | 4 |
| SDF gradients | 6 analytical + 1 numerical | 0 | 7 |
| Silk implicit channels | 37 | 0 | 37 |
| CompoundKind patterns | 31 | 0 | 31 |
| Instinct skills | 7 | 0 | 7 |
| RelationOp compose | 16 | 0 | 16 |
| Hebbian formulas | 3 (strengthen, decay, promote) | 3 | 0 |
| Math functions | 16 (f64+f32) | ~8 | 8 |
| VectorField types | 6 | 0 | 6 |
| Spline/temporal | 3 (Bezier, VectorSpline, TimeHistory) | 0 | 3 |
| Memory lifecycle | 3 stages + BuildZone + Consolidation | 0 | 5 |

**Total algorithms in Rust**: ~170+
**Olang currently has**: ~30-40 of these
**Gap**: ~130 algorithms to port
