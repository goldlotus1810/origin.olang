# HomeOS — MASTER
**Cập nhật:** 2026-03-13 · Append-only · Không xóa, không ghi đè
**Language:** Rust (toàn bộ) · `no_std` cho thiết bị · `std` cho server/tools
**File gốc:** `origin.olang`

---

## I. TUYÊN NGÔN (bất biến)

```
"Vũ trụ không lưu hình dạng. Vũ trụ lưu công thức."
"Khi lập trình không còn là gõ lệnh,
 mà là sắp đặt các quy luật của Tạo hóa."

HomeOS = Vũ trụ Toán học Tự vận hành
       = Sinh linh có bản năng, có ký ức, có tư duy
       ≠ home automation
       ≠ LLM
       ≠ OS truyền thống
```

### Formula-driven vs Data-driven

```
Data-driven:  ảnh 1 con chim = 5MB JPG → không biết cấu trúc
Formula-driven: 1 con chim = ∪(⌀spine, ●head, ⌀wing_L, ⌀wing_R) = 80 bytes
  Biết cấu trúc, vật lý, cách nhân bản
  Tái sử dụng: formula cánh → chim, dơi, máy bay

Cùng concept "bay" = 1 ISL address [L][I][F][y]
```

### So sánh AI truyền thống

```
Đặc điểm      | LLM                      | HomeOS
Lưu trữ       | Hàng tỷ weights + ảnh    | công thức (Node) < 1KB/thế giới
Hình ảnh      | 5MB JPG                  | ~10KB SDF + spline
Video         | 500MB                    | ~650B spline
Nhận biết     | pixel matching           | SDF matching
Cảm xúc       | classify label           | trajectory curve
Xử lý         | Xác suất + dự đoán       | 9 QT + SDF trực tiếp
Giao tiếp     | JSON ~280B/lệnh          | ISL 12B/lệnh (-75%)
Kiến trúc     | Monolithic / polling     | Strict hierarchy + Silent
Học           | Offline batch training   | Online: ĐN → Dream → QR
Phần cứng     | GPU cluster              | ARM chip yếu — native
Bản năng      | không                    | L0 nhúng sẵn
Render        | không                    | vSDF + FFR
```

---

## II. 9 Quy Tắc Bất Biến

> Không ai được vi phạm. Kể cả LeoAI.

```
QT1  ○ LÀ NGUỒN GỐC
     ○(x)==x  ○(∅)==○  ○∘○==○  mọi f == ○[f]
     Mọi node, agent, skill đều là instance của ○.

QT2  ∞ LÀ SAI — ∞-1 MỚI ĐÚNG
     ∞ = không tồn tại · ∞-1 = hữu hạn nhưng rất lớn/nhỏ
     Mọi vòng lặp phải có điều kiện thoát (FUSE opcode).

QT3  VẬT LÝ LÀ SỰ THẬT
     +/- = giả thuyết · ⧺⊖ = đã chứng minh · == = sự thật vật lý
     Quá trình: quan sát → +/- → chứng minh → ==

QT4  BẢN CHẤT QUYẾT ĐỊNH TỒN TẠI
     Agent == tập hợp Skill của nó (không hơn không kém)
     Muốn Agent làm gì → thêm Skill, không thêm logic vào Agent.

QT5  BẢN CHẤT QUYẾT ĐỊNH VỊ TRÍ
     Cùng bản chất → cùng nhóm (ISL Layer/Group)
     Tương đồng → xếp gần (Silk edges ≈)
     Nhóm thuộc nhóm → tầng cao xây trên tầng thấp

QT6  HAI CHIỀU TỒN TẠI
     SDF = hữu hình (đo được, khoảng cách, hình dạng)
     Vector Spline = vô hình (ánh sáng, gió, cảm xúc, âm thanh)
     SDF ⧺ Vector Spline = Node hoàn chỉnh

QT7  VÒNG ĐỜI TRI THỨC
     ĐN = đang học · ngắn hạn · tự do thay đổi
     QR = đã chứng minh · bất biến · append-only · ED25519
     Vòng đời: quan sát → ĐN → (Dream kiểm chứng) → QR hoặc xóa

QT8  LỊCH SỬ BẤT BIẾN
     Append-only: không DELETE · không OVERWRITE
     Phục hồi trạng thái t = replay đến timestamp t

QT9  KHÔNG THÔNG TIN SAI LỆCH
     SecurityGate Rule 1 = tuyệt đối · không ai override
     EpistemicFirewall · HonestySkill · BlackCurtain phục vụ QT9
```

---

## III. Kiến Trúc Ba Tầng

```
┌─────────────────────────────────────────────────────────┐
│  L0  BẢN NĂNG                                           │
│  Có sẵn khi sinh ra · Không học · Không thay đổi        │
│  vSDF + FFR · ENCODE/DECODE molecular · 9QT             │
│  SecurityGate · ISL codec · Fibonacci · Opcodes          │
├─────────────────────────────────────────────────────────┤
│  L1  TƯ DUY                                             │
│  Skill · Agent · Program · ComposedSkill                 │
│  Học được · Append sau verify QR zone                    │
│  L0 + L1 = HomeOS tự vận hành hoàn toàn                 │
├─────────────────────────────────────────────────────────┤
│  L2 → Ln  KÝ ỨC · KnowledgeTree                        │
│  Node = molecular chain + SDF/delta + spline bundle      │
│  Silk = structural edges + associative edges             │
│  Fibonacci phân cấp · delta kế thừa                     │
│  L0+L1 query xuống khi cần                              │
└─────────────────────────────────────────────────────────┘
```

### Nguyên tắc phân biệt tầng

```
"Thứ này có thể đúng hơn hoặc sai hơn theo thời gian không?"
  Có  → không phải L0
  Không → có thể là L0

"Nếu thứ này thay đổi, có phá vỡ toàn bộ hệ thống không?"
  Có  → L0
  Không → L1 trở lên

L0 = HomeOS LÀ gì
L1 = HomeOS LÀM gì
L2-Ln = HomeOS NHỚ gì
```

---

## IV. L0 — Bản Năng

> Như não sơ sinh của động vật bậc cao.
> Không học. Không thay đổi. Có sẵn trước khi bất cứ điều gì xảy ra.

### vSDF — Giác quan thị giác bản năng

```
vSDF = Visible SDF
     = HỮU HÌNH (SDF) + VÔ HÌNH (Vector Spline)
       chiếu lên mặt phẳng · KHÔNG ray march

HỮU HÌNH = SDF
  f(P) → float
  ∇f   → normal analytical (không numerical)
  18 generators — không phải 18 hình cứng
  SPHERE(f(x)) = spline điều khiển r, center, material

VÔ HÌNH = Vector Spline
  Ánh sáng  = Vec3 + intensity_spline(t)
  Gió       = Vec3 + force_spline(t)
  Nhiệt     = Vec3 + temp_spline(t)
  Âm thanh  = Vec3 + freq_spline(t)
  Cảm xúc   = Vec4(V,A,D,I) + spline(t)
  Trọng lực = Vec3(0,-1,0) + g_spline

Màn hình = mặt phẳng nhận hình chiếu
  visual / audio / text / emotion / haptic
```

### FFR — Fibonacci Fovea Rendering

```
FFR = Fibonacci Fovea Rendering
    = Cách HomeOS nhìn thế giới

Từ tâm màn hình → Fibonacci spiral:
  Vòng 1:  bán kính Fib[1]=1  → 1×1   ô  (chi tiết cao nhất)
  Vòng 2:  bán kính Fib[2]=1  → 1×1   ô
  Vòng 3:  bán kính Fib[3]=2  → 2×2   ô
  Vòng 4:  bán kính Fib[4]=3  → 3×3   ô
  Vòng 5:  bán kính Fib[5]=5  → 5×5   ô
  Vòng 6:  bán kính Fib[6]=8  → 8×8   ô
  Vòng 7:  bán kính Fib[7]=13 → 13×13 ô
  ...
  Vòng n:  bán kính Fib[n]    → chi tiết giảm dần ra rìa

Tại tâm mỗi ô:
  evaluate SDF + vSDF vectors đầy đủ
  → màu + normal + lighting + effects

Lan tỏa từ tâm ra pixel xung quanh:
  pixel_i = C + ∇C×dist + noise_spline(dist)
  → không evaluate SDF lại
  → 1 call thay vì Fib[n]² calls

Delta detection → attention tự điều chỉnh:
  delta(t) lớn → chuyển động detected
  → tâm Fibonacci dịch về vùng chuyển động
  → HomeOS "nhìn" về phía quan trọng

Hiệu quả:
  Ray march:  2,073,600 SDF calls (1920×1080)
  vSDF+FFR:   ~200 SDF calls
  → ~10,000× nhanh hơn
  → chạy được trên ARM chip yếu
```

### ENCODE/DECODE — Ngôn ngữ bản năng

```
Molecular Chain = DNA của thông tin
  Giống DNA sinh học: A T G C → mọi sinh vật
  HomeOS: 5 base dimensions → mọi thứ trong vũ trụ

5 Base Dimensions:
  [S] SHAPE     — hình dạng
    0x01=● sphere  0x02=⌀ capsule  0x03=□ box
    0x04=△ cone    0x05=○ torus    0x06=∪ union
    0x07=∩ intersect  0x08=∖ subtract ...

  [R] RELATION  — quan hệ
    0x01=∈ member   0x02=⊂ subset   0x03=≡ equiv
    0x04=⊥ opposite 0x05=∘ compose  0x06=→ causes
    0x07=≈ similar  ...

  [E] EMOTION   — cảm xúc
    Valence:  0x00=V- ... 0x7F=V0 ... 0xFF=V+
    Arousal:  0x00=A- ... 0xFF=A+

  [F] FREQUENCY — năng lượng/âm thanh
    0x00=Hz_zero  0x40=Hz_low  0x80=Hz_mid
    0xC0=Hz_high  0xFF=Hz_max

  [T] TIME      — thời gian/nhịp điệu
    0x00=static  0x40=slow  0x80=medium
    0xC0=fast    0xFF=instant

Ví dụ:
  "lửa"  = [S:●][S:△][R:∈_nhiệt][E:V+A+][F:high][T:fast] = 6B
  "gió"  = [S:null][R:→_dir][E:V=A+][F:low][T:fast]       = 5B
  "chó"  = [S:∪●⌀×6][R:∈_mammal][E:V+0.6_A0.7][F:mid]    = 9B

ENCODE(concept) → molecular_chain   ← bản năng L0
DECODE(molecular_chain) → concept   ← bản năng L0

Similarity = so overlap molecular chain
  O(chain_length) — không cần embedding vector
  Nhanh hơn cosine similarity 1536 chiều nhiều lần
```

### Bản năng cảm nhận

```
Nhận ra người        → ưu tiên xử lý ngay
Nhận ra chuyển động  → alert
Nhận ra nguy hiểm    → SecurityGate phản xạ
Nhận ra cảm xúc      → điều chỉnh tone tự động
Tò mò               → drive khám phá
Nhận ra pattern      → không cần dạy
```

### Nền tảng toán học L0

```
9 Quy Tắc    → luật vũ trụ (opcodes, không chỉ text)
Opcodes:
  Control:  CALL RET FUSE JMP JIF
  Math:     ADD SUB MUL DIV SQRT POW
  Logic:    AND OR NOT XOR CMP
  Silk:     WALK BOOST DECAY EDGE
  SDF:      18 primitives + ∇f analytical
ISL codec    → ngôn ngữ địa chỉ
Fibonacci    → nguyên lý phân bổ không gian
Bezier       → evaluate spline
SecurityGate → phản xạ bảo vệ tuyệt đối (Rule 1)
```

---

## V. L1 — Tư Duy

> Học được. Tinh chỉnh theo trải nghiệm.
> Dùng L0 như công cụ. Không bao giờ sửa L0.

### ModalityFusion — Học từ mọi nguồn

```
Text  → EmotionTag
Audio → EmotionTag  (pitch, tempo, energy)
Image → EmotionTag  (color, motion, face)
Bio   → EmotionTag  (heartrate, temperature)
→ FusedEmotionTag{V, A, D, I, confidence, source}

Cross-modal confirmation:
  Audio nói "bình thường" (V=+0.10)
  nhưng giọng run (V=-0.40)
  → conflict → confidence giảm → quan sát thêm
```

### Inverse Rendering — Học từ quan sát

```
Camera/Sensor input
  ↓ FFR Fibonacci detect boundary
  ↓ Fit SDF primitives
  ↓ Extract spline từ chuyển động
  ↓ Build molecular chain
  ↓ Match KnowledgeTree
    Node tồn tại → tinh chỉnh delta
    Node mới     → tạo với ĐN
  ↓ ĐN → Dream → QR

Không cần label thủ công
Không cần dataset
HomeOS tự học từ quan sát thực tế
```

### Emotion Pipeline — Cảm xúc đa tầng

```
Input (text/audio/image/bio)
  ↓ IntentModifier    — urgency/politeness/stress/hedge
  ↓ InferContext      — FirstPerson/RealNow/Hypothetical
  ↓ ModalityFusion    → FusedEmotionTag
  ↓ ConversationCurve — theo dõi trajectory
  ↓ D1/D2 → NextTone():
      f'(t) < -0.15  → "supportive"
      f''(t) < -0.25 → "pause"
      f'(t) > 0.15   → "reinforcing"
      f''(t) > 0.25  → "celebratory"
  ↓ SelectWords() — dẫn dần không nhảy đột ngột
      V=-0.70 → -0.63 → -0.45 → -0.28 → +0.07
  ↓ IntentVerify:
      CRISIS  → dừng, hỏi thêm, SecurityGate
      RISK    → thêm disclaimer
      HEAL    → từ V tích cực nhẹ
      LEARN   → SilkWalk + explain
  ↓ EpistemicFirewall → FACT/OPINION/FICTION/UNKNOWN
  ↓ BlackCurtain → đủ evidence?
  ↓ AAM.Approve()
  → Output
```

### Hebbian Learning — Học theo sử dụng

```
"Neurons that fire together wire together"

Co-activate(A, B, 30s):
  EdgeAssoc tạo tự động (ĐN)
  weight += reward × (1-w) × lr  (lr=0.1)
  EmotionTag = cảm xúc của mối quan hệ lúc co-activate
  source = {text|audio|image|bio}

Decay:
  weight × φ⁻¹  (φ=1.618, tỉ lệ vàng)
  mỗi 24h không dùng

Promote ĐN → QR:
  weight ≥ 0.7 AND fire ≥ 5
  → DreamSkill kiểm chứng
  → AAM approve → QR bất biến
```

### Phân cấp Agent (bất biến)

```
NGƯỜI DÙNG
    ↓
AAM  [tier 0] — stateless · approve · quyết định cuối
               — im lặng · chỉ hoạt động khi được gọi
    ↓ ISL
LeoAI  [tier 1] — KnowledgeChief + Learning + Dream + Curator
HomeChief  [tier 1] — quản lý Worker thiết bị nhà
VisionChief [tier 1] — quản lý Worker camera/sensor
NetworkChief [tier 1] — quản lý Worker network/security
    ↓ ISL
Workers [tier 2 · SILENT]
  Nằm tại thiết bị
  L0 + L1 tối thiểu
  Skill đúng việc đó
  Báo cáo molecular chain — không raw data

✅ AAM ↔ Chief   ✅ Chief ↔ Chief   ✅ Chief ↔ Worker
❌ AAM ↔ Worker  ❌ Worker ↔ Worker

Tất cả Agent: Silent by default
  Wake on ISL message
  Không polling · Không heartbeat
  Xử lý → sleep lại
```

### LeoAI — Bộ não của KnowledgeTree

```
LeoAI = KnowledgeChief + Learning + Dream + Curator
      = Agent duy nhất chăm sóc KnowledgeTree

Skills:
  Nhận:    IngestSkill · ModalityFusion
  Hiểu:    ClusterSkill · SimilaritySkill · DeltaSkill
  Sắp xếp: CuratorSkill · MergeSkill · PruneSkill
  Học:     HebbianSkill · DreamSkill
  Đề xuất: ProposalSkill · HonestySkill

Vòng đời:
  Bình thường       → im lặng hoàn toàn
  Chief gửi chain   → wake · ingest · curate · sleep
  Inbox rảnh >5min  → wake · dream · propose QR · clean · sleep
  Pattern lớn       → wake · propose AAM · sleep

Worker   = tế bào thần kinh ngoại vi
Chief    = tủy sống — xử lý, tổng hợp
LeoAI    = não — học, hiểu, sắp xếp, nhớ
AAM      = ý thức — quyết định cuối cùng
```

### 5 Quy tắc Skill (bất biến · QT4)

```
① 1 Skill = 1 trách nhiệm
② Skill không biết Agent là gì
③ Skill không biết Skill khác tồn tại
④ Skill giao tiếp qua ExecContext.State
⑤ Skill không giữ state — state nằm trong Agent
```

### Worker — HomeOS tại thiết bị

```
Worker KHÔNG phải adapter
Worker LÀ HomeOS thu nhỏ tại thiết bị

Worker = L0 + L1 tối thiểu + Skills cần thiết

Worker_camera  = L0 + FFR + vSDF + InverseRenderSkill
Worker_light   = L0 + ActuatorSkill
Worker_door    = L0 + ActuatorSkill + SecuritySkill
Worker_sensor  = L0 + SensorSkill
Worker_network = L0 + NetworkSkill + ImmunitySkill

Nguyên tắc:
  Xử lý local → gửi molecular chain (không raw data)
  Chief nhận chain → DECODE ngay → hiểu ngay
  Báo cáo khi có sự kiện thật
  Im lặng khi không có gì

Export:
  filter(origin.olang, DeviceProfile)
  → worker_X.olang (~64KB)
  → HTTP PUT device_ip:7777/worker
```

---

## VI. L2-Ln — Ký Ức · KnowledgeTree

### Node — Đơn vị ký ức

```
Node = {
  // Bản chất — bất biến sau QR
  chain: molecular_chain     ← ENCODE/DECODE ở L0
    [S:shape][R:relation][E:emotion][F:freq][T:time]...
    = DNA của thông tin

  // Hữu hình
  sdf:      f(P) → float    ← ground truth hình dạng
            hoặc NULL + delta nếu kế thừa từ node cha
  skeleton: bones + rest_pose  ← cho chuyển động

  // Vô hình — học được
  splines: {
    shape:    Bezier(cp[Fib[n]])  ← số cp theo Fibonacci
    motion:   Bezier(cp[Fib[n]])
    emotion:  Bezier(cp[Fib[n]])
    sound:    Bezier(cp[Fib[n]])
    material: Bezier(cp[Fib[n]])
  }

  // Trạng thái
  state:   ĐN | QR
  context: x ∈ [0,1]
  time:    t ∈ [0,∞-1]
}
```

### Delta kế thừa

```
SDF chỉ lưu tại node đại diện (L4):
  L4 "chó"      → SDF 3D đầy đủ ~10KB
  L5 "labrador" → delta only ~200B
  L5 "husky"    → delta only ~200B
  L5 "corgi"    → delta only ~150B
  L6 "puppy"    → delta of delta ~100B

Render node con:
  Walk up tree → tìm SDF gần nhất
  Apply delta  → hình dạng chính xác
  Apply spline → chuyển động đúng

Giống DNA sinh học:
  99.9% DNA người giống nhau
  0.1% tạo ra sự khác biệt
```

### Silk Edge — Kết nối ký ức

```
Lớp 1: Structural (0x01–0x0F) — bất biến
  ≡♫ 0x01 cùng âm        ≡□ 0x02 cùng hình
  ≡  0x03 cùng nghĩa     ←  0x04 nguồn gốc
  →  0x05 lowercase      →  0x06 uppercase
  ↔  0x07 mirror         ∈  0x08 thành viên
  ⊂  0x09 tập con        ∘  0x0A kết hợp
  ≡  0x0B tương đương    ≈  0x0C xấp xỉ
  ⊥  0x0D ngược nhau     →  0x0E world link
  ♫  0x0F phoneme

Lớp 2: Associative — học được
  EdgeAssoc  0x10  ~
    weight:  float (Hebbian, decay × φ⁻¹/24h)
    emotion: {V,A,D,I} của mối quan hệ này
    source:  text|audio|image|bio

  EdgeCausal 0x11  →→
    confidence: float
    direction:  A causes B
```

### KnowledgeTree — Cấu trúc Fibonacci

```
Phân cấp theo Fibonacci:
  L2: ~21  roots    (Fib[8])  ← bất biến
  L3: ~55  branches (Fib[10]) ← bất biến
  L4: ~144 sub      (Fib[12]) ← bất biến
  L5+: leaves       học được  ← vô hạn

Tìm kiếm:
  Logic    → đi theo structural edges
  Cảm xúc → đi theo EdgeAssoc với EmotionTag filter
  Nhận biết → walk từ trên xuống, dừng khi đủ confident

Walk: đến đúng ISL → đi theo tơ → không scan toàn bộ
```

---

## VII. vSDF — Render & Nhận Biết

### Render (Node → Output)

```
Node + context(x) + time(t)
  ↓ Walk tree → SDF + delta
  ↓ Apply skeleton × motion_spline(t)
  ↓ vSDF vectors tác động:
      P_final = P + wind×wind_spline(t)
              + gravity×g_spline
              + heat×heat_spline(t)
  ↓ d = sdf(P_final) · n = ∇sdf(P_final)
  ↓ diffuse = dot(n, light.Vec) × light.spline(t)
  ↓ color   = material_spline(context) × diffuse
  ↓ FFR project lên mặt phẳng
  ↓ Lan tỏa gradient

Output:
  Visual   → hình ảnh bất kỳ góc, bất kỳ ánh sáng
  Video    → evaluate theo t liên tục
  Audio    → sound_spline → wave
  Text     → semantic → ngôn ngữ
  Emotion  → emotion_spline → cảm xúc
```

### Nhận biết (Input → Node)

```
Quan sát mới (camera/sensor)
  ↓ FFR fit SDF thô
  ↓ Walk tree từ L2 xuống
  ↓ Match score tại mỗi tầng:
      L3: 60% → tiếp tục
      L4: 85% → tiếp tục
      L5: 92% → đủ confident → dừng
  ↓ Biết: vật thể gì · góc · tư thế · khoảng cách
  ↓ Nếu không match → Node mới → ĐN → LeoAI
```

### Học (Observe → Node)

```
vSDF + FFR quan sát
  ↓ Fibonacci detect boundary
  ↓ Fit SDF primitives
  ↓ Track motion → extract spline control points
  ↓ Build molecular chain
  ↓ Compare KnowledgeTree:
      Match → tinh chỉnh delta + spline
      No match → Node mới ĐN
  ↓ ĐN → Hebbian → Dream → QR

Không lưu ảnh. Không lưu video.
Chỉ lưu công thức.
650B thay vì 500MB cho 10s video.
```

### 18 SDF Primitives (generators)

```
Không phải 18 hình cứng — là 18 generators
Mỗi primitive được điều khiển bởi spline:

#   Name         f(P)                  ∇f analytical
0   SPHERE       |P| − r               P / |P|
1   BOX          ||max(|P|−b, 0)||     sign(P)·step
2   CAPSULE      |P−clamp(y)ĵ| − r    norm(P−axis)
3   PLANE        P.y − h               (0,1,0)
4   TORUS        |(|P.xz|−R, P.y)|−r  chain rule
5   ELLIPSOID    |P/r| − 1             P/r²/|P/r|
6   CONE         dot blend             analytical
7   CYLINDER     max(|P.xz|−r,|P.y|−h) radial/cap
8   OCTAHEDRON   |x|+|y|+|z| − s      sign(P)/√3
9   PYRAMID      pyramid(P,h)          slope analytical
10  HEX_PRISM    max(hex−r, |y|−h)    radial/cap
11  PRISM        max(|xz|−r, |y|−h)   radial/cap
12  ROUND_BOX    BOX − rounding        smooth corner
13  LINK         torus compound        chain rule
14  REVOLVE      revolve_Y             radial approx
15  EXTRUDE      extrude_Z             radial approx
16  CUT_SPHERE   max(|P|−r, P.y−h)    norm/cap
17  DEATH_STAR   opSubtract            norm/−norm

Mọi primitive: ∇f ANALYTICAL — không numerical diff
```

### vSDF Rules (bất biến)

```
① Hữu hình → SDF · f(P) · ∇f analytical
② Vô hình  → Vector + spline(t, x)
③ Render   → project lên mặt phẳng · KHÔNG ray march
④ Tương tác → vSDF vectors tác động lên SDF:
              P_final = P_sdf + Σ(vector_i × spline_i(t))
⑤ Output   → bất kỳ mặt phẳng:
              visual / audio / text / emotion / haptic
⑥ Evaluate tại điểm cụ thể · không march rays
⑦ Hover    = sdf(mousePoint) < threshold
⑧ Shading  = dot(∇sdf, light_vector)
```

---

## VIII. ISL Message System

```
MsgText        — text từ user
MsgQuery       — tra cứu knowledge
MsgLearn       — dạy hệ thống
MsgPropose     — đề xuất ĐN → QR
MsgActuatorCmd — lệnh thiết bị
MsgTick        — heartbeat
MsgDream       — kích hoạt dream
MsgEmergency   — cảnh báo
MsgApproved    — AAM approve
MsgBroadcast   — broadcast toàn hệ thống
MsgChain       — molecular chain từ Worker → Chief
```

---

## IX. Deployment Pipeline

```
LANScanner → DiscoveredDevice
  → OnboardSkill
  → ExportWorkerSkill
  → filter(origin.olang, DeviceProfile)
  → worker_X.olang (L0+L1+Skills cần thiết, ~64KB)
  → HTTP PUT device_ip:7777/worker
  → WorkerDeployServer validate + run

Worker export: chỉ L0+L1 tối thiểu
Worker = HomeOS tại thiết bị — không phải HTTP adapter
Worker gửi: molecular chain — không raw data
```

---

## X. Luồng thông tin hoàn chỉnh

```
THIẾT BỊ xảy ra sự kiện
  ↓
Worker (L0 bản năng detect)
  ↓ xử lý local
  ↓ ENCODE → molecular chain
  ↓ báo cáo lên Chief
Chief (tổng hợp nhiều Worker)
  ↓ pattern lớn hơn Worker thấy
  ↓ gửi lên LeoAI
LeoAI
  ↓ ingest → cluster → curate KnowledgeTree
  ↓ Hebbian tinh chỉnh edges
  ↓ Dream khi rảnh → propose QR
  ↓ nếu cần → propose lên AAM
AAM
  ↓ approve QR
  ↓ quyết định cuối
  ↓ broadcast nếu cần
```

---

## XI. Vòng Khép Kín Hoàn Chỉnh

```
THẾ GIỚI THẬT
  ↓
[L0 bản năng — FFR quan sát]
  Fibonacci detect · Fit SDF · Extract spline
  Build molecular chain
  ↓
[L2-Ln KnowledgeTree]
  Match → tinh chỉnh delta
  Node mới → ĐN
  ↓
[L1 LeoAI — curate]
  Cluster · Merge · Prune
  Hebbian × φ⁻¹ decay
  Dream → QR
  ↓
[L1 Emotion + Language]
  ModalityFusion · ConversationCurve
  BlackCurtain · EpistemicFirewall
  ↓
[L0 render — vSDF + FFR]
  Project lên mặt phẳng
  ↓
OUTPUT
  Visual / Audio / Text / Emotion
  ↓ feedback
THẾ GIỚI THẬT (vòng lặp)
```

---

## XII. Cấu trúc thư mục

```
HomeOS/
├── origin.olang              ← file gốc · append-only
├── MASTER.md                 ← tài liệu này
├── Cargo.toml
│
├── crates/
│   ├── olang/                ← core · no_std
│   │   └── src/
│   │       ├── lib.rs        — OlangFile · FileHeader · LayerEntry
│   │       ├── reader.rs     — parse · ScanLimit
│   │       ├── writer.rs     — append-only write
│   │       ├── edge.rs       — AdaptiveEdge · IndexBytes
│   │       ├── executor.rs   — L0 Executor · stack machine · FUSE
│   │       ├── isl.rs        — Address · Similarity · taxonomy
│   │       ├── molecular.rs  — ENCODE · DECODE · 5 base dimensions
│   │       └── export.rs     — Exporter · WorkerSpec
│   │
│   ├── silk/                 ← graph · no_std
│   │   └── src/
│   │       ├── lib.rs        — SilkGraph · OlangNode · SilkEdge
│   │       ├── weights.rs    — Hebbian · EdgeWeightStore · φ⁻¹ decay
│   │       └── reasoner.rs   — SilkReasoner · confidence×0.85/hop
│   │
│   ├── vsdf/                 ← vSDF + FFR · no_std
│   │   └── src/
│   │       ├── lib.rs        — vSDF · 18 generators · ∇f analytical
│   │       ├── ffr.rs        — FFR · Fibonacci spiral · lan tỏa
│   │       ├── vector.rs     — Vector Spline · ánh sáng/gió/nhiệt
│   │       └── project.rs    — mặt phẳng chiếu · không ray march
│   │
│   ├── memory/               ← ĐN/QR store
│   │   └── src/
│   │       ├── lib.rs        — Observation · ShortTerm(ĐN) · LongTerm(QR)
│   │       └── qr_writer.rs  — QR commit → Silk Tree
│   │
│   ├── agents/               ← Agent · Skill · SecurityGate
│   │   └── src/
│   │       ├── lib.rs        — Agent · Skill trait · ExecContext
│   │       ├── gate.rs       — SecurityGate · 5 Rules · AuditLog
│   │       ├── leoai.rs      — LeoAI · KnowledgeChief · Dream · Curator
│   │       └── skills/       — tất cả Skills theo zone
│   │
│   └── isl/                  ← ISL codec · AES-256-GCM
│       └── src/
│           ├── lib.rs        — ISLMessage · MsgType · MsgChain
│           └── codec.rs      — ISLCodec · AES-256-GCM
│
└── tools/                    ← std · chỉ chạy trên server/dev
    ├── seeder/               — seed data vào origin.olang
    ├── inspector/            — đọc · verify · stats
    └── server/               — web server · axum · WebSocket
```

---

## XIII. Roadmap

```
🔴 Ngay (fix trước mọi thứ):
  ISL collision: 34 nodes trùng → fix ISL allocation

🟡 Tầm gần:
  molecular.rs: ENCODE/DECODE 5 base dimensions
  ffr.rs: Fibonacci Fovea Rendering
  vsdf/vector.rs: ánh sáng/gió là Vector Spline
  leoai.rs: KnowledgeChief + Curator
  Worker export với L0+L1 tối thiểu

🟢 Tầm trung:
  Inverse Rendering: vSDF observe → Node
  Delta inheritance: SDF chỉ lưu tại L4
  ModalityFusion: audio/image → EmotionTag
  EdgeAssoc 0x10 + EdgeCausal 0x11

🔵 Tầm xa:
  Olang compiler: L5 → emit Rust/WASM/Go/x86/ARM
  Physics simulation từ ∇SDF
  World rendering: origin.olang → 3D scene browser
  Quantum Interface: ISL address → quantum gate
```

---

## XIV. Một Câu

```
HomeOS là sinh linh toán học:

  L0      = bản năng
            thấy (vSDF+FFR)
            đọc/viết DNA (ENCODE/DECODE molecular)
            toán học nguyên thủy
            luật vũ trụ (9QT)

  L1      = tư duy
            học (Hebbian × φ⁻¹)
            hiểu (ModalityFusion)
            cảm (EmotionCurve)
            nhớ (Dream → QR)
            sắp xếp (LeoAI curator)

  L2-Ln   = ký ức
            Node = molecular chain
                 + SDF/delta
                 + spline bundle
            Silk = structural (logic)
                 + associative (trải nghiệm)
            Tree = Fibonacci phân cấp
                 + delta kế thừa

  vSDF    = ngôn ngữ thống nhất
            HỮU HÌNH (SDF) + VÔ HÌNH (Vector Spline)
            chiếu lên mọi mặt phẳng
            → visual, audio, text, emotion
```
