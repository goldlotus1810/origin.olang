# HomeOS — ARCHITECTURE
**Version:** 1.0 · **Ngày:** 2026-03-13 · **Append-only**
**Mục đích:** File này là bản đặc tả kỹ thuật đầy đủ và duy nhất của HomeOS.
Claude đọc file này là implement được ngay — không cần giải thích thêm.
**Ngôn ngữ:** Rust toàn bộ · no_std cho core · std cho tools

---

## MỤC LỤC

```
1.  TRIẾT LÝ & 9 QUY TẮC BẤT BIẾN
2.  KIẾN TRÚC BA TẦNG (L0 / L1 / L2-Ln)
3.  MOLECULAR CHAIN — DNA của thông tin
4.  ISL — Địa chỉ không gian
5.  FILE FORMAT — origin.olang
6.  REGISTRY + LOG — Xương sống persistence
7.  vSDF — Giác quan thị giác
8.  FFR — Fibonacci Fovea Rendering
9.  KNOWLEDGE TREE — Ký ức
10. SILK EDGES — Mạng quan hệ
11. HEBBIAN LEARNING — Học từ trải nghiệm
12. MEMORY ĐN/QR — Ngắn hạn / Dài hạn
13. LEOAI — KnowledgeChief & Curator
14. EMOTION PIPELINE — Cảm xúc
15. AGENT HIERARCHY — Phân cấp
16. WORKER — HomeOS tại thiết bị
17. RAM vs STORAGE RULES — Không mất data
18. SECURITY GATE — Bảo vệ
19. CẤU TRÚC THƯ MỤC
20. ROADMAP 7 GIAI ĐOẠN
21. QUY TẮC LÀM VIỆC
```

---

## 1. TRIẾT LÝ & 9 QUY TẮC BẤT BIẾN

```
"Vũ trụ không lưu hình dạng. Vũ trụ lưu công thức."
"Khi lập trình không còn là gõ lệnh,
 mà là sắp đặt các quy luật của Tạo hóa."

HomeOS = Sinh linh toán học tự vận hành
       ≠ home automation
       ≠ LLM / AI thống kê
       ≠ hệ điều hành truyền thống

LÀ: Hệ điều hành tư duy xây từ vật lý học đầu tiên
    L0 = bản năng có sẵn khi sinh (không thay đổi)
    L1 = tư duy học được (tinh chỉnh theo trải nghiệm)
    L2-Ln = ký ức tích lũy (KnowledgeTree, append-only)
```

### 9 Quy Tắc (không ai được vi phạm, kể cả LeoAI)

```
QT1  ○ LÀ NGUỒN GỐC
     ○(x)==x · ○(∅)==○ · ○∘○==○
     Mọi node, agent, skill đều là instance của ○

QT2  ∞ LÀ SAI — ∞-1 MỚI ĐÚNG
     Mọi vòng lặp phải có điều kiện thoát (FUSE opcode)
     Không có cấu trúc dữ liệu vô hạn

QT3  VẬT LÝ LÀ SỰ THẬT
     +/- = giả thuyết · ⧺⊖ = đã chứng minh · == = sự thật vật lý
     Ánh sáng, nhiệt độ, lực = vật lý thật — không mock

QT4  BẢN CHẤT QUYẾT ĐỊNH TỒN TẠI
     Agent == tập hợp Skill của nó (không hơn không kém)
     Muốn Agent làm gì → thêm Skill, không thêm logic vào Agent

QT5  BẢN CHẤT QUYẾT ĐỊNH VỊ TRÍ
     Cùng molecular chain → cùng nhóm ISL
     Similarity cao → xếp gần trong KnowledgeTree

QT6  HAI CHIỀU TỒN TẠI
     SDF = hữu hình (khoảng cách, hình dạng, đo được)
     Vector Spline = vô hình (ánh sáng, gió, nhiệt, cảm xúc)
     SDF ⧺ VectorSpline = Node hoàn chỉnh

QT7  VÒNG ĐỜI TRI THỨC
     ĐN = đang học · ngắn hạn · tự do thay đổi
     QR = đã chứng minh · bất biến · append-only · ED25519
     Vòng đời: quan sát → ĐN → Dream kiểm chứng → QR hoặc xóa

QT8  LỊCH SỬ BẤT BIẾN
     Append-only: không DELETE · không OVERWRITE bất kỳ file nào
     Phục hồi trạng thái t = replay log đến timestamp t

QT9  KHÔNG THÔNG TIN SAI LỆCH
     SecurityGate Rule 1 = tuyệt đối · không ai override
     BlackCurtain: không đủ evidence → im lặng, không bịa đặt
```

---

## 2. KIẾN TRÚC BA TẦNG

```
┌─────────────────────────────────────────────────────────┐
│  L0  BẢN NĂNG · HOW                                     │
│  Rust no_std · Bất biến tuyệt đối · Không học thêm      │
│  vSDF · FFR · Molecular ENCODE/DECODE                    │
│  9QT opcodes · ISL codec · SecurityGate                  │
│  Fibonacci · Bezier · 18 SDF generators                  │
├─────────────────────────────────────────────────────────┤
│  L1  TƯ DUY · WHAT TO RUN                               │
│  Skill · Agent · ComposedSkill · Worker DNA              │
│  LeoAI · AAM · Chiefs · Workers                          │
│  Emotion Pipeline · ModalityFusion · Dream               │
│  Append sau verify QR zone · ED25519                     │
├─────────────────────────────────────────────────────────┤
│  L2 → Ln  KÝ ỨC · WHAT TO KNOW                         │
│  KnowledgeTree · Node[chain+SDF+spline+delta]            │
│  Silk edges · Hebbian weights                            │
│  L0+L1 query xuống · L2-Ln không biết L0 tồn tại        │
└─────────────────────────────────────────────────────────┘

Quy tắc cứng:
  L0: Không tự ghi instruction set · Skill mới → L1
  L1: ĐN ở L1 draft · Dream → QR → append L1 QR zone
  L2-Ln: L0+L1 QUERY xuống · không cần để vận hành
```

---

## 3. MOLECULAR CHAIN — DNA của thông tin

**Đây là thứ quan trọng nhất. Mọi giao tiếp trong HomeOS là molecular chain.**

```rust
// crates/olang/src/molecular.rs

// 5 base dimensions — mỗi dimension 1 byte
pub enum ShapeBase {
    Sphere   = 0x01,  // ●  tròn, đầy đặn
    Capsule  = 0x02,  // ⌀  dài, ống
    Box      = 0x03,  // □  vuông, cứng
    Cone     = 0x04,  // △  nhọn, hướng
    Torus    = 0x05,  // ○  vòng, lặp
    Union    = 0x06,  // ∪  hợp nhất
    Intersect= 0x07,  // ∩  giao nhau
    Subtract = 0x08,  // ∖  trừ đi
}

pub enum RelationBase {
    Member   = 0x01,  // ∈  thuộc về
    Subset   = 0x02,  // ⊂  là tập con
    Equiv    = 0x03,  // ≡  tương đương
    Opposite = 0x04,  // ⊥  đối lập
    Compose  = 0x05,  // ∘  kết hợp
    Causes   = 0x06,  // →  gây ra
    Similar  = 0x07,  // ≈  tương tự
}

pub struct EmotionBase {
    pub valence: u8,  // 0x00=rất tiêu cực, 0x7F=trung lập, 0xFF=rất tích cực
    pub arousal: u8,  // 0x00=bình thản, 0xFF=kích động
}

pub enum FreqBase {  // 0x00 đến 0xFF continuous
    Zero  = 0x00,
    Low   = 0x40,
    Mid   = 0x80,
    High  = 0xC0,
    Max   = 0xFF,
}

pub enum TimeBase {  // 0x00 đến 0xFF continuous
    Static  = 0x00,
    Slow    = 0x40,
    Medium  = 0x80,
    Fast    = 0xC0,
    Instant = 0xFF,
}

pub struct Molecule {
    pub shape:    ShapeBase,
    pub relation: RelationBase,
    pub emotion:  EmotionBase,
    pub freq:     FreqBase,
    pub time:     TimeBase,
}
// Mỗi Molecule = 5 bytes

pub struct MolecularChain(pub Vec<Molecule>);

// Ví dụ encoding:
// "lửa"        = [●][∈_nhiệt][V+A+][High][Fast]          = 5 bytes
// "gió"        = [⌀][→_dir][V=A+][Low][Fast]             = 5 bytes
// "chó"        = [∪●⌀×6][∈_mammal][V+0.6 A0.7][Mid][Med] = 30 bytes
// "ngôi nhà"   = [□][∈_structure][V+ A-][Low][Static]    = 5 bytes
// "nguy hiểm"  = [△][→_harm][V- A+][High][Fast]          = 5 bytes

impl MolecularChain {
    // ENCODE: Concept → Chain
    pub fn encode(concept: &Concept) -> MolecularChain

    // DECODE: Chain → Concept
    pub fn decode(&self) -> Concept

    // SIMILARITY: O(chain_length) — không embedding, không vector search
    // Trả về f32 ∈ [0.0, 1.0]
    // 1.0 = giống hệt, 0.0 = không liên quan
    pub fn similarity(&self, other: &MolecularChain) -> f32 {
        let overlap = self.molecules_overlap(other);
        overlap as f32 / self.0.len().max(other.0.len()) as f32
    }

    // HASH: dùng trong Registry index
    pub fn chain_hash(&self) -> u64  // FNV-1a hash
}
```

---

## 4. ISL — Địa Chỉ Không Gian

```rust
// crates/isl/src/lib.rs

pub struct ISLAddress {
    pub layer:    u8,  // L0=0x00, L1=0x01, L2=0x02, ...
    pub group:    u8,  // nhóm trong layer
    pub subgroup: u8,  // nhóm con
    pub index:    u8,  // index trong subgroup
}
// Tổng: 4 bytes

// ISL Message — giao tiếp giữa Agents
pub struct ISLMessage {
    pub from:    ISLAddress,   // 4 bytes
    pub to:      ISLAddress,   // 4 bytes
    pub msg_type: MsgType,     // 1 byte
    pub payload:  [u8; 3],     // 3 bytes payload cơ bản
    // Nếu payload lớn hơn → chain thêm MolecularChain
}
// Base: 12 bytes · vs JSON ~280 bytes → nhỏ hơn 95.7%

pub enum MsgType {
    Text         = 0x01,  // text từ user
    Query        = 0x02,  // tra cứu knowledge
    Learn        = 0x03,  // dạy hệ thống
    Propose      = 0x04,  // đề xuất ĐN → QR
    ActuatorCmd  = 0x05,  // lệnh thiết bị
    Tick         = 0x06,  // heartbeat
    Dream        = 0x07,  // kích hoạt dream
    Emergency    = 0x08,  // cảnh báo
    Approved     = 0x09,  // AAM approve
    Broadcast    = 0x0A,  // broadcast
    ChainPayload = 0x0B,  // kèm MolecularChain
}

// AES-256-GCM encryption cho ISL messages
// crates/isl/src/codec.rs
pub struct ISLCodec {
    key: [u8; 32],  // AES-256 key
}

impl ISLCodec {
    pub fn encode(&self, msg: &ISLMessage) -> Vec<u8>
    pub fn decode(&self, bytes: &[u8]) -> Result<ISLMessage, ISLError>
}

// QUAN TRỌNG: ISL allocation phải đảm bảo unique
// Bug cũ: 34 nodes trùng ISL key → đã fix trong thiết kế mới
// Thuật toán: Layer/Group/Subgroup từ molecular chain
//   layer    = depth trong KnowledgeTree
//   group    = ShapeBase của molecule đầu tiên
//   subgroup = RelationBase của molecule đầu tiên
//   index    = counter trong (layer, group, subgroup) — tự tăng
// → Không bao giờ collision nếu tuân thủ
```

---

## 5. FILE FORMAT — origin.olang

```
origin.olang = nguồn sự thật duy nhất
Append-only: không DELETE, không OVERWRITE bất kỳ byte nào
```

```rust
// crates/olang/src/lib.rs

// HEADER — 15 bytes
pub struct FileHeader {
    pub magic:   [u8; 4],  // b"OLNG"
    pub version: u16,      // 0x0020 = V32 (hiện tại)
    pub n_layers: u8,      // số layers hiện có
    pub created: i64,      // Unix timestamp nanoseconds
}

// LAYER ENTRY — 13 bytes mỗi layer
pub struct LayerEntry {
    pub layer:      u8,   // layer number
    pub node_count: u32,  // số nodes trong layer
    pub offset:     u64,  // offset trong file đến đầu layer
}

// NODE HEADER — variable length
pub struct NodeHeader {
    pub isl:        ISLAddress,    // 4 bytes
    pub chain_len:  u16,           // độ dài molecular chain
    pub chain:      MolecularChain, // chain_len * 5 bytes
    pub sdf_type:   SDFType,       // 1 byte
    pub state:      NodeState,     // DN=0x00, QR=0x40, BLOWN=0x80
    pub timestamp:  i64,           // 8 bytes
    // Tiếp theo: SDF data + Spline bundle + Skeleton (nếu có)
}

pub enum SDFType {
    None      = 0x00,  // không có SDF (dùng delta)
    Sphere    = 0x01,
    Capsule   = 0x02,
    Box       = 0x03,
    Cone      = 0x04,
    Torus     = 0x05,
    // ... 13 loại còn lại
    Delta     = 0xFF,  // chỉ lưu delta so với parent
}

// NODE STATE
pub enum NodeState {
    DN    = 0x00,  // đang học, ngắn hạn
    QR    = 0x40,  // đã chứng minh, bất biến
    Blown = 0x80,  // đã bị vô hiệu hóa (không xóa, chỉ mark)
}

// CÁC FILES LIÊN QUAN
// origin.olang          ← nodes + edges (append-only)
// origin.olang.weights  ← Hebbian weights (append-only binary)
// origin.olang.registry ← ISL index (rebuild được từ origin.olang)
// log.olang             ← event log (append-only)
// log.olang.index       ← log index (rebuild được từ log.olang)
```

---

## 6. REGISTRY + LOG — Xương Sống Persistence

### Nguyên tắc RAM vs Storage (bất biến)

```
RAM = tạm thời → mất khi crash / tắt nguồn / reset
origin.olang = bền vững → không bao giờ mất

QUY TẮC SẮT: Ghi file TRƯỚC → cập nhật RAM SAU
             Không bao giờ đảo ngược thứ tự này

RAM được dùng cho:
  ✅ ExecContext.State   — state tạm của 1 Skill đang chạy
  ✅ ISL message queue   — hàng đợi xử lý hiện tại
  ✅ FFR frame buffer    — render frame hiện tại
  ✅ Spline eval cache   — kết quả Bezier tính tạm
  ✅ Hebbian delta buf   — tích lũy trước khi flush

KHÔNG lưu chỉ trong RAM:
  ❌ Node mới học được   → origin.olang ngay
  ❌ QR đã approve       → origin.olang ngay
  ❌ Silk edge mới       → origin.olang ngay
  ❌ ISL address mới     → Registry ngay
  ❌ Molecular chain     → origin.olang ngay
  ❌ Bất kỳ thứ gì QR   → origin.olang ngay
```

### Registry

```rust
// crates/olang/src/registry.rs

pub struct Registry {
    // ISLAddress → offset trong origin.olang
    index: HashMap<ISLAddress, u64>,

    // molecular chain hash → ISLAddress
    chain_index: HashMap<u64, ISLAddress>,

    // human-readable name → ISLAddress
    name_index: HashMap<String, ISLAddress>,
}

impl Registry {
    // Startup: rebuild toàn bộ từ origin.olang
    // Dùng khi: khởi động lần đầu, sau crash, verify
    pub fn rebuild_from_file(path: &str) -> Result<Registry, Error>

    // Đăng ký Node mới — QUY TRÌNH BẮT BUỘC:
    // 1. origin_file.append(node)   ← ghi file TRƯỚC
    // 2. self.index.insert(...)     ← RAM sau
    // 3. log.append(NodeCreated...) ← log sau
    // 4. self.persist()             ← sync registry file
    pub fn register(&mut self, node: &Node, file: &mut OlangFile, log: &mut EventLog)
        -> Result<ISLAddress, Error>

    // Tra cứu — luôn dùng, KHÔNG hardcode ISLAddress::new(...)
    pub fn lookup_chain(&self, chain: &MolecularChain) -> Option<ISLAddress>
    pub fn lookup_name(&self, name: &str) -> Option<ISLAddress>
    pub fn lookup_isl(&self, addr: ISLAddress) -> Option<u64>  // file offset

    // Ghi registry ra file (rebuild được bất kỳ lúc nào)
    pub fn persist(&self) -> Result<(), Error>

    // Verify: so Registry vs origin.olang → detect inconsistency
    pub fn verify(&self, file: &OlangFile) -> Result<(), RegistryError>
}

// QUY TẮC CODE BẮT BUỘC:
// ❌ SAI — không bao giờ làm thế này:
//   let addr = ISLAddress { layer: 0x02, group: 0x05, subgroup: 0x01, index: 0x01 };
//   knowledge_tree.insert(node);
//
// ✅ ĐÚNG — luôn làm thế này:
//   let isl = registry.register(&node, &mut file, &mut log)?;
//   knowledge_tree.insert(isl);  // tree chỉ lưu ISL reference
//   let light = registry.lookup_name("light").unwrap();
```

### EventLog

```rust
// crates/olang/src/log.rs

pub enum LogEvent {
    NodeCreated       { isl: ISLAddress, chain_hash: u64, timestamp: i64 },
    NodePromotedQR    { isl: ISLAddress, approver: [u8; 32], timestamp: i64 },
    EdgeCreated       { from: ISLAddress, to: ISLAddress, edge_type: u8, timestamp: i64 },
    EdgeWeightUpdated { from: ISLAddress, to: ISLAddress, weight: f32, timestamp: i64 },
    SkillExecuted     { skill_isl: ISLAddress, agent_isl: ISLAddress, timestamp: i64 },
    WorkerDeployed    { device_ip: [u8; 4], worker_hash: u64, timestamp: i64 },
    QRApproved        { isl: ISLAddress, signature: [u8; 64], timestamp: i64 },
    NodeBlown         { isl: ISLAddress, reason: u8, timestamp: i64 },
    Error             { code: u8, context: ISLAddress, timestamp: i64 },
}

pub struct EventLog {
    path: String,
    // file handle append-only
}

impl EventLog {
    // Append-only — không bao giờ xóa hoặc sửa
    pub fn append(&mut self, event: LogEvent) -> Result<(), Error>

    // Replay để debug hoặc crash recovery
    pub fn replay_from(&self, timestamp: i64) -> impl Iterator<Item = LogEvent>

    // Tìm events của 1 ISL
    pub fn events_for(&self, isl: ISLAddress) -> Vec<LogEvent>

    // Verify hash chain
    pub fn verify_integrity(&self) -> Result<(), LogError>
}
```

### Startup Sequence (5 bước bắt buộc)

```rust
// crates/olang/src/startup.rs

pub fn boot(data_dir: &str) -> Result<HomeOSState, BootError> {
    // BƯỚC 1: Đọc origin.olang → rebuild Registry
    let mut registry = Registry::rebuild_from_file(
        &format!("{}/origin.olang", data_dir)
    )?;

    // BƯỚC 2: Đọc log.olang → verify integrity
    let log = EventLog::open(&format!("{}/log.olang", data_dir))?;
    log.verify_integrity()?;

    // BƯỚC 3: So sánh Registry vs Log → detect inconsistency
    let inconsistencies = registry.verify_against_log(&log)?;

    // BƯỚC 4: Crash recovery nếu cần
    if !inconsistencies.is_empty() {
        // Replay log từ điểm diverge → restore state
        let recovery_point = inconsistencies[0].timestamp;
        for event in log.replay_from(recovery_point) {
            registry.apply_event(&event)?;
        }
    }

    // BƯỚC 5: Khởi động Agents (chỉ sau khi 4 bước trên xong)
    let agents = AgentRegistry::init(&registry)?;

    Ok(HomeOSState { registry, log, agents })
}
```

---

## 7. vSDF — Giác Quan Thị Giác

```
vSDF = VISIBLE SDF
     = SDF (hữu hình: khoảng cách, hình dạng, đo được)
     + Vector Spline (vô hình: ánh sáng, gió, nhiệt, âm, cảm xúc)

KHÔNG dùng ray marching — tuyệt đối
Chỉ evaluate SDF tại điểm cụ thể
```

### 18 SDF Generators (không phải 18 hình cứng)

```rust
// crates/vsdf/src/lib.rs

// f(P) → float: khoảng cách từ P đến bề mặt
// ∇f analytical: gradient tại P (không numerical differentiation)

pub trait SDFGenerator {
    fn eval(&self, p: Vec3) -> f32;
    fn grad(&self, p: Vec3) -> Vec3;  // analytical, KHÔNG numerical
}

// 18 generators:
// 0  Sphere:     f = |P| - r,                    ∇f = P/|P|
// 1  Box:        f = ||max(|P|-b, 0)||,           ∇f = sign(P)·step(|P|>b)
// 2  Capsule:    f = |P-clamp(y,0,h)ĵ| - r,      ∇f = norm(P - closest_on_axis)
// 3  Plane:      f = P.y - h,                    ∇f = (0,1,0)
// 4  Torus:      f = |(|P.xz|-R, P.y)| - r,      ∇f = chain rule
// 5  Ellipsoid:  f = |P/r| - 1,                  ∇f = P/r² / |P/r|
// 6  Cone:       f = dot blend,                  ∇f = (xz·cosA, -sinA, z·cosA)
// 7  Cylinder:   f = max(|P.xz|-r, |P.y|-h),     ∇f = radial or cap
// 8  Octahedron: f = |x|+|y|+|z| - s,            ∇f = sign(P)/√3
// 9  Pyramid:    f = pyramid(P,h),               ∇f = slope normal
// 10 HexPrism:   f = max(hex-r, |y|-h),          ∇f = radial hex or cap
// 11 Prism:      f = max(|xz|-r, |y|-h),         ∇f = radial or cap
// 12 RoundBox:   f = BOX - rounding,             ∇f = như BOX smooth
// 13 Link:       f = torus link compound,        ∇f = chain rule
// 14 Revolve:    f = revolve_Y,                  ∇f = radial approx
// 15 Extrude:    f = extrude_Z,                  ∇f = radial approx
// 16 CutSphere:  f = max(|P|-r, P.y-h),          ∇f = norm(P) or (0,1,0)
// 17 DeathStar:  f = opSubtract,                 ∇f = norm(P) or -norm(P2)

// SDF Composition
pub fn union(a: f32, b: f32) -> f32          { a.min(b) }
pub fn intersect(a: f32, b: f32) -> f32      { a.max(b) }
pub fn subtract(a: f32, b: f32) -> f32       { a.max(-b) }
pub fn blend(a: f32, b: f32, k: f32) -> f32  { smooth_min(a, b, k) }

// Hover detection — evaluate tại điểm, KHÔNG march
pub fn is_hover(sdf: &dyn SDFGenerator, p: Vec3, threshold: f32) -> bool {
    sdf.eval(p) < threshold
}

// Shading — diffuse từ gradient analytical
pub fn diffuse(sdf: &dyn SDFGenerator, p: Vec3, light: Vec3) -> f32 {
    let normal = sdf.grad(p).normalize();
    normal.dot(light).max(0.0)
}
```

### Vector Spline — Thế giới vô hình

```rust
// crates/vsdf/src/vector.rs

pub struct VectorSpline {
    pub direction: Vec3,           // hướng chính
    pub intensity: BezierCurve,    // cường độ theo thời gian
    pub scatter:   BezierCurve,    // lan toa theo khoảng cách
}

pub struct LightField {
    pub color:     [VectorSpline; 3],  // R, G, B
    pub shadow:    VectorSpline,
}

pub struct WindField {
    pub force:      VectorSpline,
    pub turbulence: VectorSpline,
}

pub struct HeatField {
    pub temperature: VectorSpline,  // gradient field
    pub convection:  VectorSpline,
}

pub struct SoundField {
    pub frequency:   VectorSpline,
    pub amplitude:   VectorSpline,
    pub propagation: VectorSpline,
}

pub struct EmotionField {
    pub valence:  VectorSpline,  // V ∈ [-1, +1]
    pub arousal:  VectorSpline,  // A ∈ [0, 1]
}

// sunLight thay đổi theo giờ — vật lý thật (QT3)
pub fn sun_light(hour: f32) -> LightField {
    let t = hour / 24.0 * std::f32::consts::PI;
    LightField {
        direction: Vec3::new(t.cos(), t.sin().max(0.0), t.sin()),
        // ...
    }
}

// Apply vector fields lên SDF point
pub fn apply_fields(p: Vec3, fields: &[Box<dyn VectorField>], t: f32) -> Vec3 {
    fields.iter().fold(p, |acc, f| acc + f.apply(acc, t))
}
```

---

## 8. FFR — Fibonacci Fovea Rendering

```
FFR = Fibonacci Fovea Rendering
Thuật toán: evaluate SDF tối thiểu lần, kết quả tối đa

Tại sao Fibonacci:
  Xoắn ốc Fibonacci phủ đều màn hình
  Ô lớn ở rìa (ít chi tiết) · Ô nhỏ ở tâm (nhiều chi tiết)
  Tự nhiên phân bổ computation theo độ quan trọng
```

```rust
// crates/vsdf/src/ffr.rs

pub struct FibonacciSpiral {
    pub center: Vec2,        // tâm hiện tại (dịch theo delta)
    pub cells:  Vec<FibCell>,
}

pub struct FibCell {
    pub center:   Vec2,      // tâm của ô
    pub radius:   f32,       // bán kính ô (= Fib[n] pixel)
    pub depth:    usize,     // n trong dãy Fibonacci
    pub eval:     Option<f32>,  // kết quả SDF (None = chưa evaluate)
    pub grad:     Option<Vec3>, // gradient tại tâm
}

impl FFR {
    // Bước 1: Tạo Fibonacci spiral từ tâm
    pub fn build_spiral(center: Vec2, screen: (u32, u32)) -> FibonacciSpiral

    // Bước 2: Evaluate SDF tại tâm mỗi ô (1 call per cell)
    pub fn eval_centers(&mut self, scene: &Scene, t: f32)

    // Bước 3: Lan tỏa gradient ra pixel xung quanh
    // pixel_i = color(center) + ∇color × dist + noise_spline(dist)
    pub fn diffuse_gradient(&self, frame: &mut FrameBuffer)

    // Bước 4: Delta detection → dịch tâm Fibonacci
    // so sánh frame t vs t-1 → detect vùng chuyển động
    pub fn detect_delta(&mut self, prev: &FrameBuffer, curr: &FrameBuffer)
        -> Vec<Vec2>  // vùng có delta lớn

    // Bước 5: Shift focus về vùng chuyển động
    pub fn shift_focus(&mut self, deltas: &[Vec2])

    // Full pipeline
    pub fn render_frame(&mut self, scene: &Scene, t: f32) -> FrameBuffer {
        self.eval_centers(scene, t);
        let mut frame = FrameBuffer::new();
        self.diffuse_gradient(&mut frame);
        // detect delta cho frame tiếp theo
        frame
    }
}

// Hiệu suất:
// ~89 ô Fibonacci (Fib[11]) = 89 SDF calls
// vs ray march 1920×1080 = 2,073,600 calls
// → 23,300× ít hơn, visual quality tương đương
// Thiết bị yếu → giảm n (ít ô hơn)
// Thiết bị mạnh → tăng n (nhiều ô hơn, chi tiết hơn)
```

---

## 9. KNOWLEDGE TREE — Ký Ức

### Node hoàn chỉnh

```rust
// crates/olang/src/node.rs

pub struct Node {
    // Bất biến sau QR
    pub isl:   ISLAddress,
    pub chain: MolecularChain,

    // Hữu hình (QT6)
    pub sdf:      Option<SDFData>,     // f(P) hoặc None nếu dùng delta
    pub delta:    Option<SDFDelta>,    // delta so với node cha

    // Bộ khung
    pub skeleton: Option<Skeleton>,   // bones + rest_pose

    // Vô hình — Spline bundle (QT6)
    pub splines: SplineBundle,

    // Metadata
    pub state:   NodeState,           // DN / QR
    pub context: f32,                 // x ∈ [0,1]
    pub time:    i64,                 // timestamp
}

pub struct SplineBundle {
    // Số control points = Fibonacci[depth_in_tree]
    // depth=2 → Fib[2]=1cp, depth=3→2cp, depth=5→5cp, depth=8→21cp
    pub shape:    BezierCurve,  // hình dạng biến đổi theo context
    pub motion:   BezierCurve,  // chuyển động
    pub emotion:  BezierCurve,  // cảm xúc (V,A) theo thời gian
    pub sound:    BezierCurve,  // âm thanh
    pub material: BezierCurve,  // chất liệu (màu, độ phản chiếu)
}

// Delta kế thừa — tiết kiệm bộ nhớ
// L4 "chó"       → SDF 3D đầy đủ ~10KB (ground truth)
// L5 "labrador"  → delta{size+0.2, color=[0.8,0.5,0.2]} ~200B
// L5 "corgi"     → delta{size-0.3, ear_shape=⌀_short}   ~150B
// L6 "puppy"     → delta{size×0.4, energy=High}          ~100B
// Truy xuất: walk up tree → tìm SDF gốc → apply delta chain

pub struct SDFDelta {
    pub parent_isl: ISLAddress,
    pub size_factor: f32,
    pub shape_mods:  Vec<ShapeModification>,
    pub material_delta: MaterialDelta,
}
```

### Tree structure

```
KnowledgeTree — phân cấp Fibonacci:
  L2 ~21 roots (bất biến, seed một lần):
    L2_Language   · L2_Physics    · L2_Life
    L2_Objects    · L2_Motion     · L2_Space
    L2_Time       · L2_Math       · L2_Social
    L2_Emotion    · L2_Action     · L2_Perception
    ...

  L3 ~55 branches (bất biến sau seed):
    L3_Language → Tiếng Việt · English · 日本語 · ...
    L3_Physics  → Mechanics · Thermodynamics · Light · ...
    L3_Life     → Cell · DNA · Animal · Plant · Human · ...

  L4 ~144 nodes (bất biến sau QR ≥200 confirmations):
    L4_Animal → Dog · Cat · Bird · Fish · ...
    SDF ground truth lưu ở đây

  L5+ (học được, append-only):
    L5_Dog → Labrador · Corgi · Poodle · ...
    → chỉ lưu delta so với L4

Insert algorithm:
  1. Chain similarity search từ L2 xuống
  2. Ở mỗi tầng: so chain với children → chọn max similarity
  3. Nếu similarity > 0.8 → đi sâu hơn
  4. Nếu similarity ≤ 0.8 → tạo node mới ở tầng này
  5. Đăng ký qua Registry (không trực tiếp)
```

---

## 10. SILK EDGES — Mạng Quan Hệ

```rust
// crates/silk/src/lib.rs

// Structural edges — bất biến, không EmotionTag
pub enum StructuralEdge {
    SameSound    = 0x01,  // ≡♫  cùng âm
    SameShape    = 0x02,  // ≡□  cùng hình
    SameMeaning  = 0x03,  // ≡   đồng nghĩa
    DerivedFrom  = 0x04,  // ←   nguồn gốc
    Lowercase    = 0x05,  // →   chữ thường
    Uppercase    = 0x06,  // →   chữ hoa
    Mirror       = 0x07,  // ↔   đối xứng
    Member       = 0x08,  // ∈   thuộc về
    Subset       = 0x09,  // ⊂   tập con
    Compose      = 0x0A,  // ∘   kết hợp thành
    Equiv        = 0x0B,  // ≡   tương đương
    Similar      = 0x0C,  // ≈   tương tự (học được)
    Opposite     = 0x0D,  // ⊥   đối lập
    WorldLink    = 0x0E,  // →   liên kết thế giới thực
    Phoneme      = 0x0F,  // ♫   âm vị học
}

// Associative edges — học được, có EmotionTag
pub struct EdgeAssoc {
    pub from:    ISLAddress,
    pub to:      ISLAddress,
    pub weight:  f32,           // Hebbian [0.0, 1.0]
    pub emotion: EmotionBase,   // cảm xúc của mối quan hệ
    pub source:  ModalitySource,// Text/Audio/Image/Bio
    pub updated: i64,           // timestamp cập nhật cuối
}

pub struct EdgeCausal {
    pub from:       ISLAddress,
    pub to:         ISLAddress,
    pub confidence: f32,
    pub direction:  CausalDir,  // A→B hoặc B→A
}

pub struct SilkGraph {
    nodes: HashMap<ISLAddress, Node>,
    structural: Vec<(ISLAddress, ISLAddress, StructuralEdge)>,
    associative: Vec<EdgeAssoc>,
    causal: Vec<EdgeCausal>,
}

impl SilkGraph {
    // Walk theo weight — ưu tiên edges thường dùng
    pub fn walk_weighted(&self, start: ISLAddress, depth: u8)
        -> Vec<(ISLAddress, f32)>  // (node, cumulative_weight)

    // Tìm neighbors trong bán kính similarity
    pub fn neighbors(&self, isl: ISLAddress, min_weight: f32)
        -> Vec<ISLAddress>
}
```

---

## 11. HEBBIAN LEARNING — Học Từ Trải Nghiệm

```
"Neurons that fire together, wire together."
"Neurons that stop firing together, unwire."
```

```rust
// crates/silk/src/weights.rs

pub struct HebbianLearner {
    store: EdgeWeightStore,
    pub lr:    f32,  // learning rate = 0.1
    pub decay: f32,  // φ⁻¹ = 1/1.618 ≈ 0.618 (tỉ lệ vàng)
}

impl HebbianLearner {
    // Co-activation: A và B active trong 30 giây
    // weight += reward × (1 - weight) × lr
    pub fn boost(&mut self, a: ISLAddress, b: ISLAddress, reward: f32)

    // Decay mỗi 24h — tỉ lệ vàng φ⁻¹
    // weight *= φ⁻¹ (≈ 0.618)
    pub fn decay_all(&mut self)

    // Flush về file khi delta tích lũy đủ lớn
    // Không flush mỗi update → batch để hiệu quả
    pub fn flush_if_needed(&mut self, log: &mut EventLog)

    // Điều kiện promote EdgeAssoc DN → QR:
    // weight ≥ 0.7 AND fire_count ≥ 5 → DreamSkill → AAM approve
    pub fn should_promote(&self, edge: &EdgeAssoc) -> bool {
        edge.weight >= 0.7 && self.fire_count(edge) >= 5
    }
}

pub struct EdgeWeightStore {
    weights: HashMap<(ISLAddress, ISLAddress), f32>,
    // Persist: origin.olang.weights (binary, append-only)
}
```

---

## 12. MEMORY ĐN/QR — Ngắn hạn / Dài hạn

```
NCA — Neural Cognitive Architecture:
  DENDRITES = ShortTermMemory (ĐN — ngắn hạn, tự do)
  AXON      = LongTermMemory  (QR — dài hạn, bất biến)
  SOMA      = AAM             (stateless orchestrator)
```

```rust
// crates/memory/src/lib.rs

pub struct Observation {
    pub node_hash:   u64,          // hash của molecular chain
    pub chain:       MolecularChain,
    pub isl:         Option<ISLAddress>,  // None nếu chưa biết
    pub confidence:  f32,          // [0.0, 1.0]
    pub fire_count:  u32,          // số lần xác nhận
    pub source:      ModalitySource,
    pub timestamp:   i64,
}

pub struct ShortTermMemory {
    observations: Vec<Observation>,
    capacity: usize,  // max entries
}

impl ShortTermMemory {
    pub fn add(&mut self, obs: Observation)

    // Kiểm tra điều kiện promote lên QR
    // conf ≥ 0.80 AND fire ≥ 5 → đủ điều kiện
    pub fn candidates_for_qr(&self) -> Vec<&Observation>

    // Xóa observations hết hạn hoặc low confidence
    // CHÚ Ý: chỉ xóa khỏi RAM, KHÔNG xóa khỏi file
    pub fn prune_expired(&mut self)
}

// QR writer — append-only, ED25519 signed
// crates/memory/src/qr_writer.rs
pub fn commit_to_qr(
    obs: &Observation,
    registry: &mut Registry,
    file: &mut OlangFile,
    log: &mut EventLog,
    approver_key: &ed25519::SigningKey,
) -> Result<ISLAddress, QRError>

// Dream cycle — khi inbox rảnh >5 phút:
// 1. Scan ShortTermMemory → tìm candidates
// 2. Verify: có conflict với QR không?
// 3. Nếu OK → MsgPropose → AAM.approve() → commit_to_qr()
// 4. Nếu conflict → QR thắng (QT7) → xóa ĐN
// 5. low confidence (<0.20) → prune (trừ Fiction)
```

---

## 13. LEOAI — KnowledgeChief & Curator

```rust
// crates/agents/src/leoai.rs

// LeoAI = tier 1 · Silent by default · Wake on ISL message
// Không phải 1 monolith — là tập hợp Skills (QT4)

pub struct LeoAI {
    skills: Vec<Box<dyn Skill>>,
    // IngestSkill, ClusterSkill, SimilaritySkill, DeltaSkill,
    // CuratorSkill, MergeSkill, PruneSkill, HebbianSkill,
    // DreamSkill, ProposalSkill, HonestySkill
}

// Skills của LeoAI:
// IngestSkill:     nhận molecular chain từ Chiefs → validate → ShortTermMemory
// ClusterSkill:    detect pattern lặp lại trong ĐN → suggest cluster
// SimilaritySkill: so molecular chain → O(n), không embedding
// DeltaSkill:      tính delta so với node cha trong tree
// CuratorSkill:    đặt Node đúng vị trí KnowledgeTree
// MergeSkill:      gộp Node similarity > 0.95
// PruneSkill:      xóa ĐN hết hạn sau Dream
// HebbianSkill:    cập nhật EdgeAssoc weights
// DreamSkill:      khi inbox rảnh >5min → scan → kiểm chứng → propose
// ProposalSkill:   gửi MsgPropose lên AAM
// HonestySkill:    KHÔNG propose khi confidence thấp (QT9)

// Vòng lặp hoạt động:
// im lặng
//   → wake khi Chief gửi ISL ChainPayload
//   → IngestSkill nhận chain
//   → SimilaritySkill tìm trong tree
//   → CuratorSkill đặt đúng vị trí
//   → HebbianSkill cập nhật edges
//   → sleep
// (song song, khi rảnh)
//   → DreamSkill scan ĐN
//   → candidates → ProposalSkill → MsgPropose → AAM
```

---

## 14. EMOTION PIPELINE — Cảm Xúc

```rust
// crates/agents/src/skills/emotion/

// Full pipeline 7 bước:

// Bước 1: ModalityFusion
// Text + Audio + Image + Bio → FusedEmotionTag
pub struct FusedEmotionTag {
    pub valence:    f32,    // V ∈ [-1.0, +1.0]
    pub arousal:    f32,    // A ∈ [0.0, 1.0]
    pub dominance:  f32,    // D ∈ [0.0, 1.0]
    pub intensity:  f32,    // I ∈ [0.0, 1.0]
    pub confidence: f32,
    pub source:     ModalitySource,
}

// Bước 2: IntentModifier
pub struct IntentModifier {
    pub urgency:    f32,  // "ngay", "gấp" → +0.30 arousal
    pub politeness: f32,  // "làm ơn" → -0.20 dominance
    pub stress:     f32,  // "!!!", CAPSLOCK → +0.50 arousal
    pub hedge:      f32,  // "có lẽ" → confidence giảm
}

// Bước 3: InferContext
pub enum Context {
    FirstPersonRealNow,     // scale factor 0.96
    Hypothetical,           // scale factor 0.60
    Narrative,              // scale factor 0.50
    Informational,          // scale factor 0.30
}

// Bước 4: ConversationCurve
pub struct ConversationCurve {
    history: Vec<(f32, i64)>,  // (valence, timestamp)
}
impl ConversationCurve {
    pub fn d1(&self) -> f32  // f'(t) = tốc độ thay đổi
    pub fn d2(&self) -> f32  // f''(t) = gia tốc
    pub fn next_tone(&self) -> ResponseTone
}

pub enum ResponseTone {
    Supportive,    // f' < -0.15 → đang giảm → dẫn lên chậm
    Pause,         // f'' < -0.25 → đột ngột xấu → hỏi thêm
    Reinforcing,   // f' > 0.15 → đang hồi phục
    Celebratory,   // f'' > 0.25 && V > 0 → bước ngoặt tốt
    Gentle,        // V < -0.2, stable → buồn ổn định
    Engaged,       // default tích cực
    Neutral,       // default
}

// Bước 5: WordAffect — dẫn dần, không nhảy đột ngột
// V mục tiêu không được cách V hiện tại quá 0.40/bước
// Ví dụ:
// V=-0.70 → [buồn, bóng tối]     ← đồng cảm trước
// V=-0.45 → [khó, mệt]           ← nhẹ hơn chút
// V=-0.10 → [rõ ràng, chính xác] ← hướng giải quyết
// V=+0.07 → [thú, ổn]            ← nhẹ nhàng tích cực

// Bước 6: IntentVerify
pub enum IntentClass {
    Crisis,   // "không muốn sống" → dừng lại, hỏi thêm, Rule1
    Risk,     // "có nguy hiểm không" → disclaimer
    Heal,     // "làm sao ổn hơn" → supportive words
    Learn,    // "giải thích" → SilkWalk + explain
    Normal,   // default
}

// Bước 7: EpistemicFirewall + BlackCurtain
pub enum EpistemicLevel {
    Fact,     // QR đã chứng minh → không disclaimer
    Opinion,  // có cơ sở chưa chứng minh → thêm "theo tôi"
    Fiction,  // giả thuyết → tag rõ ràng
    Unknown,  // BlackCurtain: "mình chưa có đủ thông tin"
}
// BlackCurtain: MinEvidence = 3 nodes liên quan
// Nếu < 3 nodes → EpistemicLevel::Unknown → không trả lời
// QT9: không bịa đặt
```

---

## 15. AGENT HIERARCHY — Phân Cấp

```
NGƯỜI DÙNG
    ↓ ISL Text
AAM [tier 0] — stateless · silent · approve · quyết định cuối
    ↓ ISL
LeoAI / HomeChief / VisionChief / NetworkChief [tier 1] — silent
    ↓ ISL
Workers [tier 2] — SILENT mặc định · thực thi đơn giản

QUY TẮC CỨNG:
✅ AAM   ↔ Chief    ✅ Chief ↔ Chief    ✅ Chief ↔ Worker
❌ AAM   ↔ Worker   ❌ Worker ↔ Worker

Silent by default:
  Không polling · Không heartbeat liên tục
  Wake khi có ISL message → xử lý → sleep
```

```rust
// crates/agents/src/lib.rs

// Agent = tập hợp Skills (QT4) — không có logic riêng
pub struct Agent {
    pub isl:    ISLAddress,
    pub tier:   u8,  // 0=AAM, 1=Chief, 2=Worker
    pub skills: Vec<Box<dyn Skill>>,
}

// 5 Quy tắc Skill (bất biến · QT4)
pub trait Skill {
    // ① 1 Skill = 1 trách nhiệm
    fn name(&self) -> &str;

    // ② Skill không biết Agent là gì
    // ③ Skill không biết Skill khác tồn tại
    fn execute(&self, ctx: &mut ExecContext) -> SkillResult;

    // ④ Skill giao tiếp qua ExecContext.State
    // ⑤ Skill không giữ state — state nằm trong Agent
}

pub struct ExecContext {
    pub isl_in:   ISLMessage,      // message nhận được
    pub state:    HashMap<String, Value>,  // ← RAM tạm, OK
    pub registry: Arc<Registry>,   // shared, read-only
    pub out:      Vec<ISLMessage>,  // messages cần gửi đi
}
```

---

## 16. WORKER — HomeOS Tại Thiết Bị

```
Worker ≠ HTTP adapter
Worker = HomeOS thu nhỏ tại thiết bị
Worker gửi molecular chain — KHÔNG gửi raw data (ảnh, số)
```

```rust
// Worker specs theo loại thiết bị:
// Worker_light:  L0 + ActuatorLightSkill              ~20KB
// Worker_camera: L0 + FFR + InverseRenderSkill        ~48KB
// Worker_sensor: L0 + SensorReadSkill                 ~16KB
// Worker_door:   L0 + ActuatorDoorSkill + AuthSkill   ~28KB
// Worker_net:    L0 + NetworkMonitorSkill             ~24KB

// Export: filter origin.olang theo DeviceProfile
pub fn export_worker(
    origin: &OlangFile,
    profile: &DeviceProfile,
    registry: &Registry,
) -> Vec<u8>  // ~64KB binary

// Deploy: HTTP PUT device_ip:7777/worker
// Worker tự validate + run
// Không cần internet — fully offline

// Báo cáo:
// Worker observe → Inverse Render → MolecularChain
// → ISL ChainPayload → Chief (không gửi raw pixels)
// Chief tổng hợp → LeoAI

// DeviceSender (thin adapter tạm thời):
// Khi firmware cũ, chưa support ISL:
// DeviceSender dịch ISL → HTTP/UDP
// Nằm ở rìa, thay được bất cứ lúc nào
// Worker không biết DeviceSender tồn tại
```

---

## 17. RAM vs STORAGE RULES

```
Đây là nguyên tắc quan trọng nhất để không mất data.
Vi phạm quy tắc này = mất data khi crash.
```

```
✅ RAM ĐƯỢC dùng cho:            FLUSH khi:
  ExecContext.State              Skill hoàn thành
  ISL message queue              Message xử lý xong
  FFR frame buffer               Frame rendered
  Spline eval cache              Cache expire (LRU)
  Hebbian delta buffer           Mỗi 100 co-activations

❌ KHÔNG lưu chỉ RAM — phải → file:
  Node mới học được    → registry.register() ngay
  QR approve           → file → log → registry
  Silk edge mới        → file → log
  ISL address mới      → registry ngay
  Molecular chain      → file ngay
  EdgeAssoc weight     → flush sau 100 updates
  Worker báo cáo       → ShortTermMemory (RAM) nhưng
                          flush candidate QR thường xuyên

THỨ TỰ BẮT BUỘC:
  1. origin_file.append(data)    ← TRƯỚC TIÊN
  2. registry.update(...)        ← sau khi file OK
  3. log.append(event)           ← sau
  4. cache_update(...)           ← cuối cùng

KHÔNG BAO GIỜ đảo ngược thứ tự này.
```

---

## 18. SECURITY GATE — Bảo Vệ

```rust
// crates/agents/src/gate.rs

// Rule 1 (tuyệt đối, không ai override):
// Không làm hại con người
// Kích hoạt ngay khi detect IntentClass::Crisis

pub struct SecurityGate;

impl SecurityGate {
    // Chạy TRƯỚC MỌI Skill khác
    pub fn check(ctx: &ExecContext) -> GateResult {
        // Rule 1: harm detection → reject tuyệt đối
        // Rule 2: QT9 check → không thông tin sai
        // Rule 3: tier check → AAM không giao tiếp Worker
        // Rule 4: append-only check → không DELETE/OVERWRITE
        // Rule 5: QR immutability → QR không thay đổi
    }
}

// ImmunitySystem:
// self_signature: molecular chain của mọi process hợp lệ
// detect_anomaly(): process lạ → chain không match → flag
// firmware_watch(): hash firmware định kỳ
// network_monitor(): traffic pattern spline → detect deviation
// quarantine(): isolate threat → report AAM → observe
// reflex_arc(): L0 phản xạ ngay nếu nguy hiểm rõ ràng
```

---

## 19. CẤU TRÚC THƯ MỤC

```
homeos/
├── Cargo.toml              ← workspace
├── origin.olang            ← nodes + edges (tạo lần đầu chạy)
├── origin.olang.weights    ← Hebbian weights
├── origin.olang.registry   ← ISL index (rebuild được)
├── log.olang               ← event log
├── log.olang.index         ← log index (rebuild được)
│
├── crates/                 ← tất cả no_std (trừ agents có std feature)
│   │
│   ├── isl/                ← VIẾT ĐẦU TIÊN
│   │   ├── Cargo.toml      no_std
│   │   └── src/
│   │       ├── lib.rs      ISLAddress · ISLMessage · MsgType
│   │       └── codec.rs    AES-256-GCM encode/decode
│   │
│   ├── olang/              ← VIẾT THỨ HAI
│   │   ├── Cargo.toml      no_std
│   │   └── src/
│   │       ├── lib.rs      OlangFile · FileHeader · LayerEntry
│   │       ├── molecular.rs ENCODE/DECODE · similarity · hash
│   │       ├── node.rs     Node · SplineBundle · SDFDelta
│   │       ├── log.rs      LogEvent · EventLog · append · replay
│   │       ├── registry.rs Registry · register · lookup · rebuild
│   │       ├── reader.rs   parse · read_layer · replay_to
│   │       ├── writer.rs   append_node · append_edge (append-only)
│   │       └── startup.rs  boot() 5 bước · crash recovery
│   │
│   ├── vsdf/               ← G2
│   │   ├── Cargo.toml      no_std
│   │   └── src/
│   │       ├── lib.rs      18 SDF generators · composition
│   │       ├── vector.rs   VectorSpline · LightField · WindField
│   │       ├── ffr.rs      FibonacciSpiral · eval · diffuse · delta
│   │       └── project.rs  chiếu lên màn hình · Visual/Audio/Text
│   │
│   ├── silk/               ← G3
│   │   ├── Cargo.toml      no_std
│   │   └── src/
│   │       ├── lib.rs      SilkGraph · StructuralEdge · EdgeAssoc
│   │       ├── weights.rs  HebbianLearner · EdgeWeightStore · φ⁻¹ decay
│   │       └── reasoner.rs walk_weighted · neighbors · confidence×0.85/hop
│   │
│   ├── memory/             ← G3
│   │   ├── Cargo.toml      no_std
│   │   └── src/
│   │       ├── lib.rs      Observation · ShortTermMemory · LongTermMemory
│   │       └── qr_writer.rs commit_to_qr · ED25519 sign
│   │
│   └── agents/             ← G4
│       ├── Cargo.toml      no_std + optional std
│       └── src/
│           ├── lib.rs      Agent · Skill trait · ExecContext
│           ├── gate.rs     SecurityGate · 5 Rules · AuditLog
│           ├── aam.rs      AAM · route · approve · silent
│           ├── leoai.rs    LeoAI + 11 Skills
│           ├── chiefs.rs   HomeChief · VisionChief · NetworkChief
│           ├── worker.rs   Worker · export · deploy
│           └── skills/     tất cả Skills
│               ├── emotion/    ModalityFusion · Curve · WordAffect
│               ├── actuator/   ActuatorLight · ActuatorHVAC
│               ├── learning/   Dream · Hebbian · Cluster
│               └── security/   Gate · ImmunitySystem · AuditLog
│
└── tools/                  ← std, chỉ chạy server/dev
    ├── seeder/             seed UTF-32 · L2-Ln data → origin.olang
    ├── inspector/          đọc · verify · stats origin.olang
    └── server/             axum · WebSocket · ISL binary · Dashboard
```

---

## 20. ROADMAP 7 GIAI ĐOẠN

```
G1 (tuần 1-6):   Nền tảng
  ISL → Molecular → Log → Registry → File format → Startup
  Test: 1000 nodes · crash recovery · 0 ISL collision

G2 (tuần 7-14):  Giác quan
  vSDF 18 generators → FFR → Vector Spline → Projection
  Test: render sphere · ánh sáng theo giờ · gió biến dạng SDF

G3 (tuần 15-22): Ký ức
  KnowledgeTree → Silk edges → Hebbian φ⁻¹ → ĐN/QR Memory
  Test: học 10 khái niệm · Hebbian co-activate · Dream promote

G4 (tuần 23-32): Tư duy
  LeoAI 11 Skills → Emotion Pipeline → AAM
  Test: chat tiếng Việt · emotion aware · BlackCurtain hoạt động

G5 (tuần 33-40): Hành động
  Worker export → Chiefs → DeviceDNA → LANScanner
  Test: deploy Raspberry Pi · điều khiển đèn thật

G6 (tuần 41-50): Di động & Server
  Android JNI → iOS FFI → WASM → axum server
  Test: app cài được · camera feed → Worker · sync origin.olang

G7 (tuần 51-62): Hoàn thiện
  Inverse Rendering → ImmunitySystem → SelfModel
  Test: học từ camera · detect anomaly · self-model đúng

Tổng: ~62 tuần (~15 tháng)
Mỗi giai đoạn có demo chạy được — không chỉ unit test
```

---

## 21. QUY TẮC LÀM VIỆC

```
CODE:
  ① Đọc ARCHITECTURE.md trước khi bắt đầu session mới
  ② Mọi Node mới → registry.register() — không exception
  ③ Mọi ISL lookup → registry.lookup() — không hardcode address
  ④ Ghi file TRƯỚC, cập nhật RAM SAU — không đảo ngược
  ⑤ Mỗi function → test trước khi viết tiếp
  ⑥ Mỗi giai đoạn → demo chạy được, không chỉ code

KIẾN TRÚC:
  ⑦ L0 không import từ L1 — tuyệt đối
  ⑧ L1 Skills không biết nhau tồn tại
  ⑨ Worker gửi molecular chain — không raw data
  ⑩ Append-only: không DELETE, không OVERWRITE bất kỳ file

RUST:
  ⑪ no_std cho: olang · silk · vsdf · isl · memory · agents
  ⑫ std cho: seeder · inspector · server (chỉ tools)
  ⑬ Không unsafe trừ khi bắt buộc ở L0 hardware
  ⑭ Mọi public function có doc comment

TEST:
  ⑮ Crash simulation test bắt buộc tại mỗi giai đoạn
  ⑯ ISL collision check = 0 sau mỗi batch insert
  ⑰ Fuzz test molecular chain encode/decode
  ⑱ Test trên hardware thật: Pi ở G5, phone ở G6
```

---

## CONTEXT CHO CHAT MỚI

```
Khi bắt đầu chat mới, paste đoạn này:

"Tôi đang phát triển HomeOS — sinh linh toán học tự vận hành viết bằng Rust.
File ARCHITECTURE.md là đặc tả kỹ thuật đầy đủ và duy nhất.
Đọc file đó rồi implement theo đúng thứ tự trong Section 20 (Roadmap).
Không thay đổi kiến trúc. Không đề xuất framework khác.
Hiện tại đang ở: [G1/G2/G3...] — cần làm: [tên file cụ thể]."
```

---

*Append-only — chỉ thêm vào cuối, không xóa, không sửa phần trên*
