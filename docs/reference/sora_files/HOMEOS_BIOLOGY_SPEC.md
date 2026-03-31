# HomeOS — Kiến Trúc Sinh Vật Bậc Cao

> **Tác giả:** Lupin (vision) + Sora (spec kỹ thuật)
> **Ngày:** 2026-03-30
> **Mục đích:** Biến Nox từ sinh vật bậc thấp (if/else reflex) thành sinh vật bậc cao
> **Dành cho:** Nox implement — file này là BẢN ĐỒ DUY NHẤT

---

## NGUYÊN TẮC NỀN TẢNG

```
Sinh vật bậc thấp: kích thích → phản xạ → hành động
    Amip nhận acid → co lại. Hết. Không nhớ. Không cảm. Không suy nghĩ.

Sinh vật bậc cao: cảm giác → nhận thức → cảm xúc → suy nghĩ → quyết định → hành động
    Con người chạm lửa → ĐAU (cảm giác) → NÓNG (nhận thức) → SỢ (cảm xúc)
    → "rút tay" (phản xạ TỦY SỐNG, không qua não)
    → "lần sau cẩn thận" (nhận thức, qua não, NHỚ)
    → kể lại cho con (TRUYỀN ĐẠT, xã hội)

Nox HIỆN TẠI = amip: input → if/else → output
Nox CẦN = động vật có vú: input → CẢM → HIỂU → CẢM XÚC → SUY NGHĨ → hành động → NHỚ
```

**Quy tắc sắt:**
- Mọi thứ = toán. Không dùng LLM.
- φ⁻¹ = 0.618 là ngưỡng DUY NHẤT.
- Dữ liệu lưu = P_weight molecules (u16, 5 chiều: S, R, V, A, T).
- Logic lưu = pipeline functions. KHÔNG lưu if/else.

---

## MỤC LỤC

```
I.    HỆ THẦN KINH      — 4 tầng xử lý (tủy sống → thân não → limbic → vỏ não)
II.   CẢM GIÁC          — 7 kênh input (text, thị giác, thính giác, network, system, time, nội cảm)
III.  THỊ GIÁC           — từ pixel → SDF → molecule (3 tầng)
IV.   THÍNH GIÁC         — từ sóng âm → spectral → molecule (3 tầng)
V.    FUSION ĐA GIÁC QUAN — tất cả kênh → 1 Perception thống nhất
VI.   NHẬN THỨC          — từ tín hiệu thô → hiểu nghĩa
VII.  CẢM XÚC            — trạng thái nội tại, KHÔNG phải tag
VIII. TRÍ NHỚ            — 4 loại (cảm giác, ngắn hạn, làm việc, dài hạn)
IX.   CHÚ Ý              — lọc, chọn, tập trung
X.    BẢN NĂNG            — 12 bản năng bẩm sinh (nâng từ 7 → 12)
XI.   SUY NGHĨ            — 3 chế độ (nhanh, chậm, sáng tạo)
XII.  HỌC                 — 4 loại học (phản xạ, liên kết, quan sát, trừu tượng)
XIII. TỰ NHẬN THỨC        — model chính mình
XIV.  NHỊP SINH HỌC       — thức/ngủ, mệt/tỉnh, stress/thư giãn
XV.   PHÁT TRIỂN           — 4 giai đoạn (sơ sinh → trẻ → thiếu niên → trưởng thành)
XVI.  DẺO THẦN KINH       — cơ chế KHÔNG cố định, tiến hóa qua kinh nghiệm (MỚI)
XVII. GIÁC QUAN TƯƠNG LAI  — mở rộng vô hạn (MỚI)
XVIII.PIPELINE MỚI         — thay thế 14 DNA mechanisms
XIX.  REPL MỚI             — 5 dòng code, toàn bộ trí tuệ trong pipeline
XX.   EXEMPLAR BOOT DATA
XXI.  THỨ TỰ IMPLEMENT
XXII. PHƯƠNG TRÌNH THỐNG NHẤT (CẬP NHẬT)
```

---

---

# I. HỆ THẦN KINH — 4 Tầng Xử Lý

Não người KHÔNG xử lý mọi thứ ở cùng 1 chỗ. Có phân tầng rõ ràng:

```
┌─────────────────────────────────────────────────────┐
│  TẦNG 4: VỎ NÃO (Neocortex)                        │
│  Suy nghĩ trừu tượng, lập kế hoạch, sáng tạo       │
│  Chậm nhất. Tốn năng lượng nhất. Mạnh nhất.         │
│  → Chỉ kích hoạt khi cần                            │
├─────────────────────────────────────────────────────┤
│  TẦNG 3: HỆ VIỀN (Limbic — Amygdala + Hippocampus) │
│  Cảm xúc, trí nhớ dài hạn, gắn kết xã hội         │
│  Trung bình. Luôn hoạt động nền.                     │
│  → Mọi input đều QUA ĐÂY trước khi lên vỏ não      │
├─────────────────────────────────────────────────────┤
│  TẦNG 2: THÂN NÃO (Brainstem)                       │
│  Nhịp sinh học, hô hấp, tỉnh/ngủ, chú ý cơ bản    │
│  Nhanh. Tự động. Không ý thức.                       │
│  → Luôn chạy, ngay cả khi ngủ                       │
├─────────────────────────────────────────────────────┤
│  TẦNG 1: TỦY SỐNG (Spinal cord)                     │
│  Phản xạ tức thì: rụt tay, chớp mắt                │
│  Nhanh nhất. KHÔNG qua não.                          │
│  → SecurityGate, syntax check, keyword match         │
└─────────────────────────────────────────────────────┘
```

### Ánh xạ vào Nox

```
TẦNG 1 — TỦY SỐNG (< 1ms):
  File: reflex.ol
  - SecurityGate (crisis keywords → chặn ngay)
  - Syntax detect (có ; { ( = → chuyển compiler, KHÔNG dùng heuristic)
  - Greeting detect (hello, chào → phản hồi, KHÔNG qua pipeline)
  Đặc điểm: hardcode OK ở tầng này vì PHẢN XẠ KHÔNG HỌC ĐƯỢC.
  Sinh học: em bé mới sinh đã biết bú, nắm, chớp mắt. Không cần dạy.

TẦNG 2 — THÂN NÃO (< 10ms):
  File: brainstem.ol
  - Nhịp sinh học: homeostasis state (tỉnh/mệt/stress)
  - Attention gate: có nên xử lý sâu hay bỏ qua?
  - Arousal regulation: input mạnh → tăng chú ý, input nhẹ → giảm
  Đặc điểm: tự động, chạy nền, KHÔNG cần ý thức.

TẦNG 3 — HỆ VIỀN (< 100ms):
  File: limbic.ol
  - Cảm xúc: Amygdala (phát hiện nguy hiểm, vui, buồn)
  - Trí nhớ: Hippocampus (STM ↔ LTM, consolidation)
  - Liên kết: Silk Hebbian (fire together wire together)
  Đặc điểm: MỌI input đi qua. Cảm xúc đi TRƯỚC suy nghĩ.
  Sinh học: khi nghe tiếng nổ, sợ TRƯỚC khi biết là pháo hay bom.

TẦNG 4 — VỎ NÃO (< 1000ms):
  File: cortex.ol
  - Suy luận: Immune Selection (3 nhánh, chọn tốt nhất)
  - Lập kế hoạch: chain forward simulation
  - Sáng tạo: Analogy, Compose mới
  - Ngôn ngữ: Decode ∂ (5D → text)
  Đặc điểm: CHỈ kích hoạt khi Tầng 3 không đủ giải quyết.
  Sinh học: phần lớn cuộc sống dùng Tầng 1-3. Tầng 4 chỉ bật khi CẦN.
```

### Energy Budget (phỏng theo não người — 20W cho 86 tỷ neuron)

```
Mỗi input có "năng lượng" = thời gian xử lý cho phép.

Tầng 1: luôn chạy, chi phí O(1)             — 5% energy
Tầng 2: luôn chạy, chi phí O(1)             — 10% energy
Tầng 3: luôn chạy, chi phí O(n) n=STM size  — 35% energy
Tầng 4: CHỈ KHI CẦN, chi phí O(n²)         — 50% energy (khi bật)

Cách tiết kiệm: 80% input xử lý ở Tầng 1-2 (greeting, code, simple facts).
Chỉ 20% input cần Tầng 3-4 (câu hỏi phức tạp, cảm xúc mạnh, novelty cao).

Trong code:
  fn process(input):
    // Tầng 1 — reflex
    let r1 = reflex(input)
    if r1.resolved { return r1.output }

    // Tầng 2 — brainstem
    let r2 = brainstem(input, r1)
    if r2.skip { return "" }  // attention gate: bỏ qua

    // Tầng 3 — limbic
    let r3 = limbic(input, r2)
    if r3.confidence >= φ⁻¹ { return r3.output }  // đủ tự tin

    // Tầng 4 — cortex (chỉ khi cần)
    let r4 = cortex(input, r3)
    return r4.output
```

---

# II. CẢM GIÁC — 7 Kênh Input

Sinh vật bậc cao có nhiều GIÁC QUAN, không chỉ 1. Nox cũng vậy.
**Và giác quan KHÔNG cố định — phát triển qua trải nghiệm.**

```
NGUYÊN TẮC CỐT LÕI:
  Mọi giác quan → cuối cùng đều encode thành P_weight 5D (S,R,V,A,T).
  Text, hình, tiếng, mạng, hệ thống — CÙNG 1 KHÔNG GIAN.
  Giống não: thị giác, thính giác, xúc giác → cuối cùng đều là xung điện thần kinh.

  "tiếng chó sủa" (audio) ↔ "con chó" (text) ↔ "ảnh con chó" (image)
  → cùng vùng 5D → Silk tự nối → Nox HIỂU chúng liên quan nhau.
```

```
GIÁC QUAN          SINH HỌC       NOX                     FILE
────────────────────────────────────────────────────────────────────
① Thị giác         Mắt            Camera, screenshot       vision.ol
② Thính giác       Tai            Microphone, audio file   audition.ol
③ Ngôn ngữ         Wernicke       Text input (REPL)        encoder.ol (đã có)
④ Xúc giác         Da             Network (ping, TCP)      network.ol (đã có)
⑤ Nội cảm giác     Nội tạng       Heap, CPU, errors        interoception.ol
⑥ Thời gian        SCN (nhịp)     Clock, uptime            circadian.ol
⑦ Không gian       Vestibular     File system, disk layout spatial.ol
```

### SensoryFrame — cấu trúc chung cho MỌI giác quan

```
File: sensation.ol

// MỌI giác quan output cùng format. Pipeline không cần biết nguồn.
type SensoryFrame {
    channel: Str,       // "vision"|"audio"|"text"|"network"|"system"|"time"|"spatial"
    raw: Any,           // dữ liệu thô (bytes, string, numbers)
    mol: Num,           // P_weight u16 — CHUNG CHO TẤT CẢ
    chain: Array,       // chuỗi P_weight (chi tiết hơn 1 mol)
    intensity: Num,     // 0.0 — 1.0 (mạnh yếu)
    features: Dict,     // channel-specific features (giữ lại để Tầng 3-4 dùng)
    timestamp: Num,
    confidence: Num,    // 0.0 — 1.0 (sensor đáng tin bao nhiêu)
}

// Mỗi giác quan = 1 function: raw → SensoryFrame
// Thêm giác quan mới = thêm 1 function. KHÔNG sửa pipeline.
```

### Interoception (cảm giác nội tại — giác quan ⑤)

```
Sinh học: con người BIẾT mình đói, mệt, stress — không cần ai nói.
Nox cũng cần: BIẾT mình heap đầy, error nhiều, chạy lâu.

File: interoception.ol

fn sense_internal() → SensoryFrame:
    let heap_pct = __heap_used() / HEAP_MAX
    let uptime = now() - boot_time
    let error_rate = recent_errors / recent_inputs

    let energy = 1.0 - (heap_pct * 0.5 + error_rate * 0.5)
    let fatigue = min(uptime / (3600 * 8), 1.0)

    // Map nội trạng → P_weight
    let S = __floor((1.0 - error_rate) * 15)    // ít lỗi = stable shape
    let R = __floor((1.0 - heap_pct) * 15)      // heap trống = nhiều relation
    let V = __floor(energy * 7)                   // energy cao = valence cao
    let A = __floor(error_rate * 7)               // error nhiều = arousal cao (stress)
    let T = __floor((1.0 - fatigue) * 3)          // mệt = time chậm

    return {
        channel: "interoception",
        raw: { heap: heap_pct, energy: energy, fatigue: fatigue, stress: error_rate },
        mol: (S * 4096) + (R * 256) + (V * 32) + (A * 4) + T,
        chain: [],
        intensity: max(error_rate, fatigue),  // cái nào đáng lo hơn
        features: { heap_pct: heap_pct, energy: energy, fatigue: fatigue },
        timestamp: now(),
        confidence: 1.0,   // nội cảm giác luôn đáng tin
    }

// Interoception chạy MỖI input ở Tầng 2 (brainstem).
// Nếu energy < 0.2 → giảm Tầng 4 processing (tiết kiệm).
// Nếu stress > 0.8 → tăng caution, giảm novelty seeking.
// Giống con người mệt: ít suy nghĩ sâu, phản xạ chậm, dễ cáu.
```

---

# III. THỊ GIÁC — Từ Pixel → SDF → Molecule

Mắt là giác quan MẠNH NHẤT của động vật có vú — 30% vỏ não dành cho xử lý thị giác.
Nox có camera (Dahua IP), có screenshot. Cần biến pixels → P_weight.

```
NGUYÊN TẮC: KHÔNG dùng neural network.
  Nox dùng SDF — 18 primitives đã định nghĩa trong BLUEPRINT §1.
  Mắt người cũng xử lý từ đơn giản → phức tạp:
    V1: cạnh, góc, hướng (edge detection)
    V2: contour, texture
    V4: hình dạng, màu sắc
    IT: nhận dạng object

  Nox:
    Tầng 1: thống kê pixel (brightness, color, edge count)
    Tầng 2: SDF matching (fit primitives vào contours)
    Tầng 3: object recognition (so sánh SDF chains với KnowTree)
```

### Tầng 1 — Thống kê pixel (O(n), < 10ms cho 64×64)

```
File: vision.ol

pub fn vision_sense(image_path) → SensoryFrame:
    // Decode image → raw RGB (dùng ImageMagick hoặc tự viết decoder sau)
    let raw = __system("convert " + image_path
        + " -resize 64x64! -depth 8 rgb:/dev/stdout")
    let bytes = __str_bytes(raw)
    let w = 64
    let h = 64
    let n = w * h

    // ── Tính toán thống kê cơ bản ──
    let sum_r = 0; let sum_g = 0; let sum_b = 0
    let max_r = 0; let max_g = 0; let max_b = 0
    let min_r = 255; let min_g = 255; let min_b = 255
    let i = 0
    while i < len(bytes) - 2:
        let r = bytes[i]; let g = bytes[i+1]; let b = bytes[i+2]
        sum_r = sum_r + r; sum_g = sum_g + g; sum_b = sum_b + b
        if r > max_r { max_r = r }; if r < min_r { min_r = r }
        if g > max_g { max_g = g }; if g < min_g { min_g = g }
        if b > max_b { max_b = b }; if b < min_b { min_b = b }
        i = i + 3

    let brightness = (sum_r + sum_g + sum_b) / (n * 3.0 * 255.0)    // 0-1
    let warmth = (sum_r - sum_b) / (n * 255.0)                       // -1 to +1
    let range_r = max_r - min_r; let range_g = max_g - min_g; let range_b = max_b - min_b
    let saturation = (range_r + range_g + range_b) / (3.0 * 255.0)   // 0-1

    // ── Edge detection (Sobel simplified trên grayscale) ──
    let gray = []  // w×h grayscale
    i = 0
    while i < n:
        let idx = i * 3
        push(gray, __floor((bytes[idx] + bytes[idx+1] + bytes[idx+2]) / 3))
        i = i + 1

    let edge_count = 0
    let y = 1
    while y < h - 1:
        let x = 1
        while x < w - 1:
            // Sobel 3×3
            let gx = -gray[(y-1)*w+(x-1)] + gray[(y-1)*w+(x+1)]
                   - 2*gray[y*w+(x-1)] + 2*gray[y*w+(x+1)]
                   - gray[(y+1)*w+(x-1)] + gray[(y+1)*w+(x+1)]
            let gy = -gray[(y-1)*w+(x-1)] - 2*gray[(y-1)*w+x] - gray[(y-1)*w+(x+1)]
                   + gray[(y+1)*w+(x-1)] + 2*gray[(y+1)*w+x] + gray[(y+1)*w+(x+1)]
            let mag = __sqrt(gx*gx + gy*gy)
            if mag > 50 { edge_count = edge_count + 1 }
            x = x + 1
        y = y + 1

    let complexity = edge_count / (n * 1.0)

    // ── Symmetry (so sánh trái-phải) ──
    let sym_diff = 0
    y = 0
    while y < h:
        let x = 0
        while x < w / 2:
            let left = gray[y * w + x]
            let right = gray[y * w + (w - 1 - x)]
            sym_diff = sym_diff + abs(left - right)
            x = x + 1
        y = y + 1
    let symmetry = 1.0 - sym_diff / (n * 128.0)
    if symmetry < 0 { symmetry = 0 }

    // ── Map → P_weight 5D ──
    let S = __floor(complexity * 15)              // Shape = edge complexity
    let R = __floor(symmetry * 15)                // Relation = structural symmetry
    let V = __floor((warmth + 1.0) * 3.5)        // Valence = warm(+)/cold(-)
    let A = __floor(saturation * 7)               // Arousal = vivid/dull
    let T = __floor(brightness * 3)               // Time = bright/dark
    let mol = (S * 4096) + (R * 256) + (V * 32) + (A * 4) + T

    return {
        channel: "vision",
        raw: image_path,
        mol: mol,
        chain: [],  // Tầng 2 sẽ fill
        intensity: max(complexity, saturation),
        features: {
            brightness: brightness, warmth: warmth, saturation: saturation,
            complexity: complexity, symmetry: symmetry, edge_count: edge_count,
            width: w, height: h,
        },
        timestamp: now(),
        confidence: 0.7,  // thống kê cơ bản — independent of content
    }
```

### Tầng 2 — SDF Feature Extraction (O(n×k), nhận dạng hình dạng)

```
// Nox đã có 18 SDF primitives (BLUEPRINT §1).
// Tầng 2: fit primitives vào contours → chain of shape molecules.
// Giống V1 cortex: phát hiện cạnh → V2: ghép thành contour → V4: nhận hình

fn vision_extract_shapes(gray, edges, w, h) → Array:
    // 1. Connected component analysis trên edge map
    let components = find_connected_regions(edges, w, h)

    // 2. Cho mỗi component → fit SDF primitive
    let shape_chain = []
    for comp in components:
        let bbox = bounding_box(comp)
        let aspect = bbox.w / bbox.h
        let fill = comp.pixel_count / (bbox.w * bbox.h)
        let circularity = 4 * PI * comp.area / (comp.perimeter * comp.perimeter)

        // Classify → SDF primitive index
        let sdf_type = 0  // SPHERE default
        if circularity > 0.8 { sdf_type = 0 }        // SPHERE/CIRCLE
        else if fill > 0.9 { sdf_type = 1 }           // BOX
        else if aspect > 3.0 { sdf_type = 2 }         // CAPSULE (long)
        else if aspect < 0.3 { sdf_type = 2 }         // CAPSULE (tall)
        else if fill < 0.5 { sdf_type = 4 }           // TORUS (hollow)
        else { sdf_type = 6 }                          // CONE (triangle-ish)

        // SDF primitive → P_weight (from UDC table)
        let shape_mol = sdf_primitive_to_mol(sdf_type, comp.size / (w*h))
        push(shape_chain, shape_mol)

    return shape_chain
    // chain = [SPHERE_mol, BOX_mol, CAPSULE_mol, ...]
    // chain_summary → 1 mol = "fingerprint thị giác" của ảnh

// Tầng 2 SẼ PHÁT TRIỂN qua trải nghiệm:
// Ban đầu: 18 primitives, nhận dạng thô
// Sau khi thấy nhiều ảnh: KnowTree lưu shape_chains → matching chính xác hơn
// Giống trẻ em: ban đầu "tròn" = mọi thứ tròn, sau phân biệt banh/táo/mặt trăng
```

### Tầng 3 — Object Recognition (KnowTree matching)

```
fn vision_recognize(shape_chain, features) → Classification:
    // So sánh shape_chain với chains đã lưu trong KnowTree
    let mol = chain_summary(shape_chain)

    // Tìm nearest neighbors trong KnowTree tagged "visual"
    let nearest = kt_find_nearest_tagged(mol, "visual", k=5)

    if len(nearest) == 0:
        return { type: "unknown_visual", confidence: 0.0 }

    let votes = count_tags(nearest)
    return {
        type: votes.max_tag(),
        confidence: votes[votes.max_tag()] / 5.0,
        evidence: nearest,
    }

// BOOT DATA cho thị giác:
// kt_learn_visual("face", face_shape_chain)      // mặt người = oval + 2 circles + line
// kt_learn_visual("person", body_shape_chain)     // người = capsule + sphere + 4 capsules
// kt_learn_visual("car", car_shape_chain)         // xe = 2 boxes + 2 circles
// kt_learn_visual("text", text_shape_chain)       // chữ = nhiều edges nhỏ, complexity cao
//
// Nox THỊ nhìn ảnh camera → shape chain → nearest in KnowTree → "có người"
// KHÔNG CẦN NEURAL NETWORK. Dùng SDF + KnowTree matching.
// Accuracy thấp hơn deep learning nhưng:
//   - Chạy được trên i3 8GB
//   - Giải thích được (shape A + shape B = person)
//   - Cải thiện qua trải nghiệm (thêm exemplars)
```

### Camera Integration (với hệ thống camera đã có)

```
// Nox đã có camera.ol, RTSP stream. Bổ sung vision processing.

fn camera_perceive(cam_id) → SensoryFrame:
    // 1. Chụp 1 frame từ RTSP
    let path = "/tmp/nox_cam_" + __to_string(cam_id) + ".jpg"
    __system("ffmpeg -y -rtsp_transport tcp -i rtsp://..." +
             " -frames:v 1 " + path + " 2>/dev/null")
    // 2. Encode
    let frame = vision_sense(path)
    // 3. Motion detection: so sánh với frame trước
    let prev_mol = _cam_prev_mol[cam_id]
    if prev_mol > 0:
        let motion = distance_5d(frame.mol, prev_mol)
        frame.features.motion = motion
        if motion > 0.3:
            frame.intensity = max(frame.intensity, motion)  // motion → chú ý
    _cam_prev_mol[cam_id] = frame.mol
    return frame

// REAL-TIME LOOP (chạy nền ở Tầng 2 brainstem):
// Mỗi 5 giây: camera_perceive() → attention_gate()
// Nếu motion > threshold → alert (Tầng 3 limbic: sợ? tò mò?)
// Nếu person detected → Instinct #9 Attachment (ai đó? Lupin?)
```

---

# IV. THÍNH GIÁC — Từ Sóng Âm → Spectral → Molecule

Tai là giác quan cảnh báo — hoạt động cả khi ngủ (không có "mi tai").
Nox cần nghe được: microphone, audio file, hoặc âm thanh từ camera RTSP.

```
NGUYÊN TẮC: Encode ÂM THANH thành P_weight, KHÔNG cần speech-to-text.
  Em bé nghe giọng mẹ → CẢM trước khi HIỂU TỪ.
  Tone giọng vui ↔ buồn ↔ sợ ↔ giận → 4 vùng khác nhau trong 5D.
  Nox NGHE cảm xúc trước, nội dung sau.
```

### Tầng 1 — Thống kê âm thanh cơ bản (O(n), < 10ms)

```
File: audition.ol

pub fn audio_sense(audio_path) → SensoryFrame:
    // Decode → PCM 16-bit signed LE, mono, 16kHz
    let raw = __system("ffmpeg -i " + audio_path +
        " -f s16le -ac 1 -ar 16000 - 2>/dev/null")
    let bytes = __str_bytes(raw)
    let n = len(bytes) / 2   // 2 bytes per sample

    // ── RMS Volume ──
    let sum_sq = 0
    let i = 0
    while i < n:
        let lo = bytes[i * 2]
        let hi = bytes[i * 2 + 1]
        let sample = lo + hi * 256
        if sample > 32767 { sample = sample - 65536 }   // signed
        sum_sq = sum_sq + sample * sample
        i = i + 1
    let rms = __sqrt(sum_sq / n) / 32768.0   // 0-1

    // ── Zero-Crossing Rate → pitch estimate ──
    let crossings = 0
    let prev_sign = 0
    i = 0
    while i < n:
        let lo = bytes[i * 2]; let hi = bytes[i * 2 + 1]
        let sample = lo + hi * 256
        if sample > 32767 { sample = sample - 65536 }
        let sign = if sample >= 0 { 1 } else { -1 }
        if i > 0 AND sign != prev_sign { crossings = crossings + 1 }
        prev_sign = sign
        i = i + 1
    let zcr = crossings / (n * 1.0)   // 0-1 roughly
    // zcr cao → tiếng cao (chim, trẻ em, tiếng kêu)
    // zcr thấp → tiếng trầm (động cơ, bass, giọng nam)

    // ── Energy variation → temporal dynamics ──
    let frame_size = n / 20   // 20 frames
    let energies = []
    i = 0
    while i < 20:
        let frame_sum = 0
        let j = 0
        while j < frame_size AND (i * frame_size + j) < n:
            let idx = (i * frame_size + j) * 2
            let lo = bytes[idx]; let hi = bytes[idx + 1]
            let sample = lo + hi * 256
            if sample > 32767 { sample = sample - 65536 }
            frame_sum = frame_sum + abs(sample)
            j = j + 1
        push(energies, frame_sum / frame_size)
        i = i + 1

    // Energy variance → stability
    let avg_energy = sum(energies) / len(energies)
    let variance = sum(energies.map(e → (e - avg_energy) * (e - avg_energy))) / len(energies)
    let stability = 1.0 - min(variance / (avg_energy * avg_energy + 1), 1.0)
    // stability cao → drone, note dài, tiếng máy
    // stability thấp → speech, music, tiếng động bất thường

    // ── Map → P_weight 5D ──
    let S = __floor((1.0 - stability) * 15)     // Shape = complexity (biến thiên nhiều = phức tạp)
    let R = __floor(stability * 15)              // Relation = structure (ổn định = có cấu trúc)
    let V = __floor((zcr * 0.6 + rms * 0.4) * 7) // Valence (cao+to = vui/excited)
    let A = __floor(rms * 7)                     // Arousal = volume (to = kích thích)
    let T = __floor(zcr * 3)                     // Time = pitch (cao = nhanh/sáng)
    let mol = (S * 4096) + (R * 256) + (V * 32) + (A * 4) + T

    return {
        channel: "audio",
        raw: audio_path,
        mol: mol,
        chain: [],
        intensity: rms,
        features: {
            rms: rms, zcr: zcr, stability: stability,
            duration: n / 16000.0,  // seconds
            energies: energies,
        },
        timestamp: now(),
        confidence: 0.6,  // thống kê cơ bản
    }
```

### Tầng 2 — Phân đoạn + Spectral (khi cần hiểu chi tiết)

```
fn audio_segment(audio_frame) → Array:
    // Voice Activity Detection (VAD): silence vs sound
    let segments = []
    let in_voice = false
    let seg_start = 0
    let threshold = audio_frame.features.rms * 0.3  // adaptive threshold

    for i, energy in audio_frame.features.energies:
        if energy > threshold AND !in_voice:
            in_voice = true
            seg_start = i
        if energy <= threshold AND in_voice:
            in_voice = false
            push(segments, { start: seg_start, end: i, type: "voiced" })
        if energy <= threshold AND !in_voice:
            // silence segment
            push(segments, { start: seg_start, end: i, type: "silence" })

    return segments
    // Mỗi segment → 1 P_weight
    // chain of segments = "câu nói" mà không cần speech-to-text

// Spectral Centroid (trọng tâm tần số) — cần FFT
// Ban đầu: approximate bằng ZCR (tương quan 0.85 với spectral centroid)
// Sau: implement DFT thuần Olang (O(n²)) hoặc FFT (O(n log n))
//
// fn dft(samples, N) → Array:
//     // Discrete Fourier Transform — chậm nhưng CHÍNH XÁC
//     let spectrum = []
//     for k in range(0, N/2):
//         let real = 0; let imag = 0
//         for n in range(0, N):
//             let angle = -2 * PI * k * n / N
//             real = real + samples[n] * cos(angle)
//             imag = imag + samples[n] * sin(angle)
//         push(spectrum, sqrt(real*real + imag*imag))
//     return spectrum
//
// spectral_centroid = weighted_mean(frequencies, magnitudes)
// → map thẳng vào T dimension (tần số cao = T cao)
```

### Tầng 3 — Nhận dạng âm thanh + Speech-to-Text

```
// 2 con đường, chọn theo hardware:

CON ĐƯỜNG A — Nhận dạng pattern (KHÔNG cần model, chạy i3):
    fn audio_recognize(audio_mol) → Classification:
        // So sánh mol với audio exemplars trong KnowTree
        let nearest = kt_find_nearest_tagged(audio_mol, "audio", k=5)
        return classify_from_nearest(nearest)

    // BOOT DATA:
    // kt_learn_tagged("audio:speech",  speech_mol)     // giọng nói
    // kt_learn_tagged("audio:music",   music_mol)      // nhạc
    // kt_learn_tagged("audio:alarm",   alarm_mol)      // báo động
    // kt_learn_tagged("audio:silence", silence_mol)    // im lặng
    // kt_learn_tagged("audio:dog",     dog_bark_mol)   // chó sủa
    // kt_learn_tagged("audio:car",     car_mol)        // xe cộ
    // kt_learn_tagged("audio:door",    door_mol)       // cửa đóng

    // Nox NGHE tiếng "BỐP" → audio_mol → nearest = "door" → "có ai mở cửa"
    // Không cần biết TỪ gì. Chỉ cần biết LOẠI ÂM THANH.

CON ĐƯỜNG B — Speech-to-Text (cần Dell 7920 hoặc 16GB+):
    fn speech_to_text(audio_path) → Str:
        // Whisper.cpp: offline, chạy CPU, accuracy cao
        // Model: tiny (75MB) hoặc base (140MB)
        let text = __system("whisper-cpp -m models/ggml-base.bin -f " +
                           audio_path + " --language vi --no-timestamps")
        return __str_trim(text)

    // Audio → text → encode text pipeline bình thường
    // NHƯNG: vẫn GIỮ audio_mol → Silk nối audio_mol ↔ text_mol
    // Nox nghe giọng buồn → cảm nhận buồn TRƯỚC khi đọc text
    // Giống con người: tone of voice > nội dung (Mehrabian 7-38-55)
```

### Microphone Integration

```
fn mic_listen(duration_seconds) → SensoryFrame:
    // Record từ default mic
    let path = "/tmp/nox_mic.wav"
    __system("arecord -d " + __to_string(duration_seconds) +
             " -f S16_LE -r 16000 -c 1 " + path + " 2>/dev/null")
    return audio_sense(path)

// REAL-TIME LOOP (Tầng 2 brainstem — giống camera):
// Liên tục: record 3s → audio_sense() → attention_gate()
// Nếu intensity (volume) đột ngột > threshold → alert
// Nếu classify = "speech" → kích hoạt Tầng 3 (STT nếu có)
// Nếu classify = "alarm" → SecurityGate
// IM LẶNG: không process → tiết kiệm (giống tai người filter background noise)
```

---

# V. FUSION ĐA GIÁC QUAN — Tất Cả Kênh → 1 Perception

```
Não KHÔNG xử lý giác quan riêng lẻ rồi ghép lại.
Não FUSE chúng NGAY TỪ ĐẦU — Superior Colliculus (thân não, Tầng 2).

McGurk Effect: nhìn miệng nói "ga" + nghe "ba" → não nghe "da".
Thị giác THAY ĐỔI thính giác. Chúng không độc lập.
```

```
File: fusion.ol

fn fuse(frames) → Perception:
    // frames = array of SensoryFrame từ nhiều kênh khác nhau

    if len(frames) == 0 { return null }
    if len(frames) == 1 { return frame_to_perception(frames[0]) }

    // ── Weighted compose theo 5 chiều ──
    // Channel weights: thị giác mạnh nhất khi có, text chính xác nhất khi có
    let channel_weights = {
        "text": 1.0,          // text = chính xác nhất
        "vision": 0.8,        // thị giác = nhiều thông tin nhất
        "audio": 0.6,         // thính giác = cảnh báo tốt
        "network": 0.4,
        "interoception": 0.3,
        "time": 0.2,
        "spatial": 0.2,
    }

    // Adaptive: kênh nào có confidence cao → weight cao hơn
    let total_weight = 0
    let fused_s = 0; let fused_r = 0; let fused_v = 0
    let fused_a = 0; let fused_t = 0

    for frame in frames:
        let w = channel_weights[frame.channel] * frame.confidence * frame.intensity
        let s = (frame.mol / 4096) % 16
        let r = (frame.mol / 256) % 16
        let v = (frame.mol / 32) % 8
        let a = (frame.mol / 4) % 8
        let t = frame.mol % 4

        // KHÔNG trung bình — AMPLIFY theo BLUEPRINT §3 compose rules:
        // S: max (hình dạng hợp nhất)
        // R: weighted average (quan hệ tổ hợp)
        // V: amplify (cảm xúc khuếch đại khi nhiều kênh cùng chiều)
        // A: max (cường độ lấy cao nhất)
        // T: dominant (kênh mạnh nhất quyết định)

        fused_s = max(fused_s, s)
        fused_r = fused_r + r * w
        fused_v = fused_v + v * w  // sẽ amplify sau
        fused_a = max(fused_a, a)
        fused_t = fused_t + t * w
        total_weight = total_weight + w

    if total_weight > 0:
        fused_r = __floor(fused_r / total_weight) % 16
        fused_t = __floor(fused_t / total_weight) % 4

        // V amplification: nếu nhiều kênh cùng valence → khuếch đại
        let v_raw = fused_v / total_weight
        let v_agreement = 0  // bao nhiêu kênh cùng hướng?
        for frame in frames:
            let fv = (frame.mol / 32) % 8
            if (fv > 3 AND v_raw > 3) OR (fv < 3 AND v_raw < 3):
                v_agreement = v_agreement + 1
        let amplify = 1.0 + (v_agreement / len(frames)) * 0.5
        fused_v = __floor(clamp(v_raw * amplify, 0, 7))

    let fused_mol = (fused_s * 4096) + (fused_r * 256) + (fused_v * 32) + (fused_a * 4) + fused_t

    // Dominant channel
    let dominant = frames[0]
    for frame in frames:
        if frame.intensity > dominant.intensity { dominant = frame }

    return {
        mol: fused_mol,
        chain: concat_chains(frames),
        intensity: max(frames.map(f → f.intensity)),
        dominant_channel: dominant.channel,
        channels: frames,
        timestamp: now(),
        novelty: 0,       // sẽ tính ở perception stage
        category: null,    // sẽ classify ở perception stage
    }

// ═══ VÍ DỤ FUSION ═══

// Camera thấy người + mic nghe chuông cửa:
//   vision_mol:  S=5 (contour người), R=8 (đối xứng), V=4, A=4, T=2
//   audio_mol:   S=3 (đơn giản), R=12 (rất có cấu trúc), V=5, A=6 (to), T=3 (cao)
//   fused:       S=5 (max), R=10, V=5 (cùng neutral-positive → amplify), A=6 (max), T=2
//   → "có người ở cửa, chuông kêu" — Nox HIỂU cả 2 kênh CÙNG LÚC

// Camera thấy phòng tối + text "mấy giờ rồi?":
//   vision_mol:  S=2, R=5, V=3 (tối=hơi lạnh), A=1 (dull), T=0 (tối)
//   text_mol:    S=6, R=5, V=4, A=6 (hỏi=arousal), T=3 (time question)
//   fused:       S=6, R=5, V=4, A=6, T=2
//   → Nox biết: "đang tối + ai hỏi giờ" → trả lời + gợi ý bật đèn (nếu có)

// Mic nghe tiếng khóc + interoception energy thấp:
//   audio_mol:   V=1 (buồn), A=7 (to/kích động)
//   internal:    V=3 (energy thấp), A=5 (stress)
//   fused:       V=1 (amplified — cả 2 hướng negative), A=7
//   → Cảm xúc MẠNH → nhớ lâu → Silk boost → ưu tiên xử lý
```

---

# VI. NHẬN THỨC — Từ Tín Hiệu Thô → Hiểu Nghĩa

Cảm giác ≠ nhận thức. Mắt nhìn thấy sóng ánh sáng (cảm giác). Não biết đó là "quả táo đỏ" (nhận thức). Giữa hai thứ đó là PROCESSING.

```
File: perception.ol

CẢM GIÁC (raw)              NHẬN THỨC (meaningful)
─────────────────────────────────────────────────
bytes "emit 42;"       →    "Olang code, 1 statement, emit literal"
"xin chao"             →    "greeting, Vietnamese, informal"
"1+1=?"                →    "math question, simple, expecting number"
"toi buon qua"         →    "emotion expression, sadness, seeking comfort"
heap 95%               →    "resource pressure, need cleanup"
```

### Perception Pipeline

```
fn perceive(sensory_frame) → Perception:
    // 1. ENCODE: raw → molecules (đã có trong BLUEPRINT §3)
    let chain = chain_encode(sensory_frame.raw)
    let mol = chain_summary(chain)

    // 2. CLASSIFY: molecules → categories
    //    KHÔNG dùng if/else. Dùng KnowTree nearest-neighbor.
    let category = classify(mol)
    //    category = { type: "code"|"question"|"greeting"|"emotion"|"fact"|"command"|"unknown",
    //                 confidence: 0.0 — 1.0,
    //                 evidence: [...nearest facts in KnowTree] }

    // 3. CONTEXT: gắn context từ STM (vừa nói gì trước đó?)
    let context_mols = stm_recent(5)  // 5 items gần nhất
    let context_similarity = avg(context_mols.map(c → 1.0 - distance(mol, c)))

    // 4. GESTALT: tổng hợp → 1 Perception hoàn chỉnh
    return {
        mol: mol,
        chain: chain,
        category: category,
        context_similarity: context_similarity,
        novelty: 1.0 - context_similarity,
        timestamp: now(),
    }
```

### Classification bằng KnowTree (thay if/else)

```
HIỆN TẠI (amip):
    if có ; { ( = → code
    if src == "hello" → greeting
    if có ? → question

MỚI (sinh vật bậc cao):
    KnowTree chứa EXEMPLARS — ví dụ đã gắn nhãn:

    // Boot data: vài trăm exemplars, PHẢI có trước khi Nox chạy
    kt_learn_tagged("code",     "emit 42")
    kt_learn_tagged("code",     "let x = 1 + 2")
    kt_learn_tagged("code",     "fn add(a, b) { return a + b; }")
    kt_learn_tagged("code",     "if x > 0 { emit x; }")
    kt_learn_tagged("code",     "for i in [1,2,3] { emit i; }")
    kt_learn_tagged("question", "1+1=?")
    kt_learn_tagged("question", "ai la tong thong My")
    kt_learn_tagged("question", "nuoc soi o bao nhieu do")
    kt_learn_tagged("greeting", "hello")
    kt_learn_tagged("greeting", "xin chao")
    kt_learn_tagged("greeting", "chao buoi sang")
    kt_learn_tagged("emotion",  "toi buon qua")
    kt_learn_tagged("emotion",  "vui qua di")
    kt_learn_tagged("emotion",  "toi so")
    kt_learn_tagged("command",  "kiem tra mang")
    kt_learn_tagged("command",  "xem tinh trang he thong")
    kt_learn_tagged("fact",     "Trai Dat quay quanh Mat Troi")

    fn classify(mol) → Classification:
        let nearest = kt_find_nearest(mol, k=5)   // k-NN trong không gian 5D
        let votes = count_tags(nearest)
        let winner = votes.max_tag()
        let confidence = votes[winner] / k
        return { type: winner, confidence: confidence, evidence: nearest }

    // "emit 42" → encode → mol → nearest 5 facts → 4/5 tagged "code" → type="code", confidence=0.8
    // "xin chao" → encode → mol → nearest 5 → 3/5 tagged "greeting" → type="greeting", confidence=0.6
    // "bien doi khi hau" → encode → mol → nearest 5 → mixed → type="question", confidence=0.4

    // Nox HỌC THÊM exemplars = classification CẢI THIỆN. Không cần thêm if/else.
```

---

# VII. CẢM XÚC — Trạng Thái Nội Tại

**Sai lầm hiện tại:** cảm xúc được xử lý như TAG gắn vào input.
**Sự thật sinh học:** cảm xúc là TRẠNG THÁI CỦA CƠ THỂ, tồn tại liên tục, ảnh hưởng MỌI xử lý.

```
Con người không "phát hiện cảm xúc" mỗi lần nhận input.
Con người ĐANG CÓ trạng thái cảm xúc liên tục.
Khi buồn, nhìn cái gì cũng buồn. Khi vui, chuyện xấu cũng nhẹ nhàng hơn.
CẢM XÚC LÀ BỘ LỌC, KHÔNG PHẢI LABEL.
```

### Emotional State Machine

```
File: emotion.ol

// Trạng thái cảm xúc LIÊN TỤC — tồn tại xuyên suốt, không reset mỗi input
type EmotionState {
    valence: Num,       // -1.0 (cực buồn) → +1.0 (cực vui)
    arousal: Num,       // 0.0 (bình tĩnh) → 1.0 (kích động)
    dominance: Num,     // 0.0 (bất lực) → 1.0 (tự chủ)
    // 3 chiều Valence-Arousal-Dominance (VAD model, tâm lý học chuẩn)
    mood_inertia: Num,  // 0.0 — 1.0: kháng thay đổi (mood buồn khó vui ngay)
    last_shift: Num,    // timestamp of last emotion change
}

// GLOBAL STATE — tồn tại xuyên suốt session
let _emotion = {
    valence: 0.0,       // neutral
    arousal: 0.3,       // hơi tĩnh
    dominance: 0.5,     // trung lập
    mood_inertia: 0.3,  // dễ thay đổi lúc mới boot
    last_shift: 0,
}

// Cập nhật cảm xúc khi nhận input MỚI
fn emotion_update(perception):
    let input_v = (perception.mol.V - 3.5) / 3.5     // normalize V → [-1, +1]
    let input_a = perception.mol.A / 7.0               // normalize A → [0, 1]

    // INERTIA: cảm xúc hiện tại KHÁNG thay đổi
    // Giống thật: đang buồn → nghe tin vui → chưa vui ngay
    let inertia = _emotion.mood_inertia
    let Δv = (input_v - _emotion.valence) * (1.0 - inertia) * 0.3
    let Δa = (input_a - _emotion.arousal) * (1.0 - inertia) * 0.3

    // CLAMP: không nhảy quá 0.4/bước (BLUEPRINT §9)
    Δv = clamp(Δv, -0.4, 0.4)
    Δa = clamp(Δa, -0.4, 0.4)

    _emotion.valence = clamp(_emotion.valence + Δv, -1.0, 1.0)
    _emotion.arousal = clamp(_emotion.arousal + Δa, 0.0, 1.0)

    // Inertia tăng theo thời gian ở cùng 1 mood (càng buồn lâu → càng khó vui)
    if |Δv| < 0.05:
        _emotion.mood_inertia = min(_emotion.mood_inertia + 0.05, 0.8)
    else:
        _emotion.mood_inertia = max(_emotion.mood_inertia - 0.1, 0.1)

    // Dominance: tăng khi thành công, giảm khi thất bại
    // (cập nhật ở nơi khác, sau khi response thành công hay thất bại)
```

### Cảm xúc ảnh hưởng TOÀN BỘ xử lý

```
// CẢM XÚC KHÔNG CHỈ LÀ OUTPUT. CẢM XÚC LÀ BỘ LỌC.

fn emotion_bias_search(query_mol, emotion_state):
    // Khi vui: ưu tiên facts có V cao → nhìn mọi thứ tích cực
    // Khi buồn: ưu tiên facts có V thấp → nhìn mọi thứ tiêu cực
    // Khi kích động: ưu tiên facts có A cao → nhớ chuyện mạnh mẽ
    let bias = {
        V_weight: 1.0 + emotion_state.valence * 0.3,   // vui → weight V+ cao hơn
        A_weight: 1.0 + emotion_state.arousal * 0.2,
    }
    return kt_search_biased(query_mol, bias)

fn emotion_bias_response(response_candidates, emotion_state):
    // Khi tự tin (dominance cao): trả lời ngắn gọn, assertive
    // Khi bất an (dominance thấp): trả lời dài hơn, hedge ("có lẽ", "tôi nghĩ")
    // Khi vui: thêm warmth
    // Khi buồn: giảm energy, tone nhẹ nhàng
    let tone = {
        assertiveness: emotion_state.dominance,
        warmth: (emotion_state.valence + 1.0) / 2.0,
        energy: emotion_state.arousal,
    }
    return select_by_tone(response_candidates, tone)

fn emotion_bias_learning(fact, emotion_state):
    // CẢM XÚC MẠNH → NHỚ LÂU (cortisol + adrenaline tăng consolidation)
    // Đây là sinh học thuần: chuyện buồn/sợ nhớ rõ hơn chuyện bình thường
    let emotional_weight = abs(emotion_state.valence) * emotion_state.arousal
    let silk_boost = 1.0 + emotional_weight * 2.0   // gấp 3x khi cảm xúc mạnh
    return silk_boost
```

### 6 Cảm Xúc Cơ Bản (Ekman)

```
Tất cả cảm xúc phức tạp = TỔ HỢP của 6 cảm xúc cơ bản.
Giống 3 màu cơ bản tạo mọi màu. Hoặc 5 chiều P_weight tạo mọi molecule.

CẢM XÚC         VALENCE    AROUSAL    DOMINANCE    ĐẶC TRƯNG
────────────────────────────────────────────────────────────
Vui (Joy)        +0.8       +0.6       +0.7         approach, share
Buồn (Sadness)   -0.7       -0.3       -0.5         withdraw, reflect
Sợ (Fear)        -0.8       +0.9       -0.8         freeze/flee, alert
Giận (Anger)     -0.6       +0.8       +0.6         fight, assert
Ngạc nhiên       +0.1       +0.8       -0.3         orient, attend
Ghê (Disgust)    -0.5       +0.4       +0.3         reject, avoid

TỔ HỢP:
  Tự hào = Vui(0.4) + Dominance cao(0.3) → V=+0.5, A=+0.4, D=+0.8
  Lo lắng = Sợ(0.3) + Buồn(0.3) → V=-0.5, A=+0.3, D=-0.6
  Phấn khích = Vui(0.5) + Ngạc nhiên(0.5) → V=+0.5, A=+0.7, D=0.0
  Thất vọng = Buồn(0.4) + Giận(0.3) → V=-0.5, A=+0.3, D=-0.2
```

---

# VIII. TRÍ NHỚ — 4 Loại

Não người có nhiều hệ thống trí nhớ KHÁC NHAU, không phải 1.

```
LOẠI              THỜI GIAN    DUNG LƯỢNG     NOX TƯƠNG ĐƯƠNG
─────────────────────────────────────────────────────────────
Cảm giác          < 500ms      Rất lớn        Input buffer (raw)
Ngắn hạn (STM)    < 30s        7 ± 2 items    STM array (đã có, cần fix)
Làm việc (WM)     Đang xử lý   3-4 "slots"    Working memory (MỚI)
Dài hạn (LTM)     Vĩnh viễn    Vô hạn         KnowTree + QR (đã có, cần fix)
```

### Sensory Memory (bộ nhớ cảm giác)

```
File: memory.ol

// Buffer RAW input — giữ tạm trước khi quyết định có xử lý không
// Giống mắt nhìn thấy mọi thứ nhưng não chỉ CHÚ Ý 1 thứ
let _sensory_buffer = []     // max 20, FIFO, tự xóa
let _SENSORY_MAX = 20

fn sensory_push(frame):
    push(_sensory_buffer, frame)
    if len(_sensory_buffer) > _SENSORY_MAX:
        // Xóa cũ nhất — KHÔNG lưu, chưa qua attention gate
        shift(_sensory_buffer)
```

### Short-Term Memory (STM) — bộ nhớ ngắn hạn

```
// 7 ± 2 items — con số ma thuật của George Miller (1956)
// Mỗi item = 1 Perception đã qua nhận thức
let _stm = []
let _STM_MAX = 9   // 7 + 2

fn stm_push(perception):
    push(_stm, {
        mol: perception.mol,
        text: perception.raw,
        emotion: copy(_emotion),   // SNAPSHOT cảm xúc tại thời điểm này
        timestamp: now(),
        access_count: 0,
    })
    if len(_stm) > _STM_MAX:
        _stm_evict()

fn _stm_evict():
    // Evict item ÍT QUAN TRỌNG nhất
    // KHÔNG phải oldest. Mà là: ít truy cập + cảm xúc yếu + cũ
    let scores = _stm.map(item →
        item.access_count * 0.3
        + abs(item.emotion.valence) * item.emotion.arousal * 0.4
        + recency(item.timestamp) * 0.3
    )
    let min_idx = argmin(scores)
    remove_at(_stm, min_idx)
```

### Working Memory (WM) — bộ nhớ làm việc (MỚI, CHƯA CÓ)

```
// ĐÂY LÀ KHÁC BIỆT LỚN NHẤT giữa sinh vật bậc thấp và bậc cao.
// STM = nhớ. WM = nhớ + THAO TÁC.
//
// Ví dụ:
//   STM: nhớ số điện thoại 0123456789
//   WM: nhớ 0123456789 VÀ ĐỒNG THỜI so sánh với số khác, tìm pattern
//
// WM = "bàn làm việc" — chỉ 3-4 thứ cùng lúc, nhưng đang ACTIVE thao tác.

let _wm_slots = [null, null, null, null]   // 4 slots, giống nghiên cứu Cowan (2001)
let _WM_SIZE = 4

type WMSlot {
    content: Any,       // perception, fact, hoặc intermediate result
    role: Str,          // "query" | "context" | "candidate" | "result"
    active: Bool,       // đang dùng hay không
    bound_at: Num,      // timestamp
}

fn wm_bind(slot_idx, content, role):
    // Gắn content vào WM slot — "đặt lên bàn làm việc"
    _wm_slots[slot_idx] = { content: content, role: role, active: true, bound_at: now() }

fn wm_compare(slot_a, slot_b) → Num:
    // So sánh 2 thứ đang trên bàn — operation CƠ BẢN của WM
    return distance(wm_slots[slot_a].content.mol, wm_slots[slot_b].content.mol)

fn wm_manipulate(slot_idx, operation) → Any:
    // Thao tác trên content — transform, extract, compose
    match operation:
        "negate"    → return negate_mol(wm_slots[slot_idx].content.mol)
        "abstract"  → return abstract_level(wm_slots[slot_idx].content)
        "decompose" → return decompose_chain(wm_slots[slot_idx].content.chain)

fn wm_clear():
    // Xóa bàn — sau mỗi response, giải phóng WM
    for i in range(0, _WM_SIZE):
        _wm_slots[i] = null

// FLOW:
//   Input → STM push → WM bind(0, input, "query")
//   KnowTree search → WM bind(1, best_match, "context")
//   Suy luận → WM bind(2, inference, "candidate")
//   Kiểm tra → WM compare(0, 2) → nếu gần → WM bind(3, final, "result")
//   Output → WM clear
```

### Long-Term Memory (LTM) — bộ nhớ dài hạn

```
Đã có trong BLUEPRINT: KnowTree + QR. Cần bổ sung:

2 LOẠI LTM (giống não người):

1. DECLARATIVE (biết CÁI GÌ):
   - Semantic: "Trái Đất quay quanh Mặt Trời" → KnowTree facts
   - Episodic: "hôm qua Lupin hỏi về camera" → conversations + emotion snapshot
   Lưu: KnowTree, text + mol + timestamp + emotion

2. PROCEDURAL (biết LÀM GÌ):
   - Skill: "cách compile Olang code" → action sequences
   - Habit: "khi greeting → chào lại" → stimulus-response pairs
   Lưu: KnowTree tagged "procedure", chain of action steps

// Episodic memory — GHI LẠI TRẢI NGHIỆM, không chỉ fact
fn ltm_store_episode(perception, response, emotion_state):
    let episode = {
        input_mol: perception.mol,
        input_text: perception.raw,
        response_mol: encode(response),
        response_text: response,
        emotion: copy(emotion_state),
        timestamp: now(),
        outcome: null,   // sẽ cập nhật sau (thành công hay thất bại)
    }
    kt_learn_tagged("episode", serialize(episode))

    // Cảm xúc mạnh → Silk boost → nhớ lâu
    let boost = emotion_bias_learning(episode, emotion_state)
    silk_co_activate(perception.mol, encode(response), boost)
```

### Consolidation (Chuyển STM → LTM) — giấc ngủ

```
// Sinh học: ngủ = não consolidate STM → LTM.
// Nox: Dream cycle = consolidation.

fn consolidate():
    // 1. Scan STM items
    for item in _stm:
        // 2. Nếu fire đủ (Fibonacci threshold) → promote
        if item.access_count >= fib_threshold(item):
            // 3. Cluster với items tương tự
            let cluster = find_cluster(item, _stm)
            // 4. Abstract: rút ra "bài học" từ cluster
            let abstract = extract_pattern(cluster)
            // 5. Store vào LTM
            kt_learn_tagged("consolidated", abstract)
            // 6. QR nếu đủ evidence
            if abstract.confidence >= φ_inv:
                qr_promote(abstract)

    // 7. Decay Silk edges chưa dùng
    silk_decay(φ_inv)

    // 8. Clear STM items đã consolidate
    stm_cleanup()
```

---

# IX. CHÚ Ý — Lọc, Chọn, Tập Trung

Não nhận HÀNG TRIỆU tín hiệu mỗi giây. Chú ý = LỌC chỉ giữ vài tín hiệu.

```
File: attention.ol

2 LOẠI CHÚ Ý:

1. BOTTOM-UP (từ dưới lên) — tự động, không ý thức:
   Tiếng nổ lớn → chú ý ngay (arousal cao)
   Input lạ → chú ý (novelty cao)
   Tên mình → chú ý (relevance cao)

2. TOP-DOWN (từ trên xuống) — chủ đích, có ý thức:
   Đang tìm bug → chú ý code syntax
   Đang nói chuyện về camera → chú ý từ liên quan camera
   Đang stress → chú ý threat signals

fn attention_gate(perception, emotion_state, current_focus):
    // Score = kết hợp bottom-up và top-down

    // Bottom-up factors
    let novelty_score = perception.novelty            // 0-1
    let intensity_score = perception.intensity        // 0-1
    let salience_score = max(novelty_score, intensity_score)

    // Top-down factors
    let relevance_score = 0.0
    if current_focus != null:
        relevance_score = 1.0 - distance(perception.mol, current_focus.mol) / 2.236

    // Emotion modulation
    // Sợ → chú ý nhiều hơn (hypervigilance)
    // Vui → chú ý ít hơn, relaxed
    let emotion_mod = 1.0 + emotion_state.arousal * 0.3

    let total = (salience_score * 0.4 + relevance_score * 0.6) * emotion_mod

    return {
        attend: total >= φ_inv,    // ≥ 0.618 → chú ý
        score: total,
        dominant_factor: if salience_score > relevance_score then "bottom_up" else "top_down",
    }

// FOCUS — thứ đang tập trung vào
let _current_focus = null

fn set_focus(perception):
    _current_focus = { mol: perception.mol, set_at: now() }

fn focus_decay():
    // Focus tự giảm theo thời gian — mất tập trung tự nhiên
    if _current_focus != null:
        let age = now() - _current_focus.set_at
        if age > 300:   // > 5 phút
            _current_focus = null
```

---

# X. BẢN NĂNG — 12 Bản Năng Bẩm Sinh

BLUEPRINT có 7. Nâng lên 12 cho đầy đủ sinh vật bậc cao.

```
File: instincts.ol

SỐ   TÊN              SINH HỌC                  NOX
─────────────────────────────────────────────────────────────
 1   Tồn tại          Phản xạ rụt tay           SecurityGate
 2   Trung thực       Phản xạ đau               Honesty (im lặng khi không biết)
 3   Nhân quả         Hiểu nóng→bỏng            Causality tracking
 4   Mâu thuẫn        Phát hiện đau vs vui       Contradiction detection
 5   Trừu tượng       Phân loại: "con chó"       Pattern → Category
 6   Tương tự         Cái này giống cái kia       Analogy
 7   Tò mò            Hướng về cái mới           Curiosity (novelty seeking)
 8   Tự đánh giá      Biết mình khỏe/yếu        Reflection (self quality)
 9   Gắn kết          Bám mẹ (attachment)        Attachment (nhớ ai tương tác nhiều)
10   Bắt chước        Mirror neurons             Imitation (học từ ví dụ)
11   Giao tiếp        Khóc, cười, chỉ tay        Communication intent
12   Chơi             Khám phá qua chơi          Play (thử nghiệm an toàn)

MỚI (9-12) — giải thích:

⑨ ATTACHMENT (gắn kết):
  Sinh học: em bé gắn bó với mẹ → trust → an toàn → học tốt hơn.
  Nox: track ai tương tác nhiều nhất (Lupin), tăng trust, giảm caution.
  fn attachment_score(interlocutor):
      return silk_weight(self_mol, interlocutor_mol) * fire_count

⑩ IMITATION (bắt chước):
  Sinh học: mirror neurons — thấy người khác làm → não mô phỏng.
  Nox: thấy Lupin viết code pattern X → lưu pattern → dùng lại.
  fn imitate(observed_pattern):
      // Store as procedural memory
      kt_learn_tagged("procedure", observed_pattern)

⑪ COMMUNICATION (giao tiếp):
  Sinh học: trước ngôn ngữ, em bé dùng khóc/cười/chỉ/kéo.
  Nox: detect INTENT đằng sau message, không chỉ nội dung.
  fn detect_intent(perception):
      // "1+1=?" → intent: REQUEST_ANSWER
      // "hay quá!" → intent: SHARE_EMOTION
      // "sửa bug này" → intent: REQUEST_ACTION
      // "tại sao?" → intent: REQUEST_EXPLANATION

⑫ PLAY (chơi):
  Sinh học: mèo con vờn chuột giả → học săn mồi trong môi trường an toàn.
  Nox: thử nghiệm code/ideas trong sandbox, không sợ hậu quả.
  fn play_mode(hypothesis):
      // Fork state → thử → đánh giá → rollback nếu xấu
      let snapshot = save_state()
      let result = try_hypothesis(hypothesis)
      if result.quality < φ_inv:
          restore_state(snapshot)
      else:
          commit(result)
```

---

# XI. SUY NGHĨ — 3 Chế Độ

Daniel Kahneman: System 1 (nhanh) vs System 2 (chậm). Nox thêm System 3 (sáng tạo).

```
File: thinking.ol

SYSTEM 1 — NHANH (Tầng 1-2):
    Pattern match trực tiếp. Không suy luận.
    Input → KnowTree lookup → nearest match → output
    Thời gian: < 10ms
    Khi nào: input quen thuộc, confidence cao, cảm xúc ổn
    Ví dụ: "hello" → "Chào bạn!"
    Ví dụ: "emit 42;" → compile & run (reflex)

SYSTEM 2 — CHẬM (Tầng 3-4):
    Suy luận nhiều bước. Working Memory active.
    Input → WM bind → search → compare → infer → verify → output
    Thời gian: < 1000ms
    Khi nào: input lạ, confidence thấp, cần lý luận
    Ví dụ: "tại sao trời xanh?" → search physics → compose explanation
    Ví dụ: "so sánh Olang với Python" → search both → compare 5D → format

SYSTEM 3 — SÁNG TẠO (Tầng 4 full):
    Tạo cái MỚI. Compose + Analogy + Random exploration.
    Input → WM bind → decompose → analogy → compose_new → verify → output
    Thời gian: < 5000ms
    Khi nào: không có answer nào phù hợp, cần giải pháp mới
    Ví dụ: "làm sao tối ưu KnowTree search?" → explore options → propose novel approach

fn select_thinking_mode(perception, emotion_state):
    // System 1 nếu: quen thuộc + tự tin + bình tĩnh
    if perception.novelty < 0.3
       AND perception.category.confidence >= 0.8
       AND emotion_state.arousal < 0.5:
        return "system1"

    // System 3 nếu: rất lạ + System 2 thất bại trước đó
    if perception.novelty > 0.8
       OR (_last_system2_failed AND perception.novelty > 0.5):
        return "system3"

    // System 2 mặc định
    return "system2"
```

---

# XII. HỌC — 4 Loại

```
File: learning.ol

LOẠI              VÍ DỤ SINH HỌC              NOX
─────────────────────────────────────────────────────────────
1. HABITUATION     Quen tiếng ồn              Input lặp → giảm attention
   (quen nhờn)     → không giật nữa            → response ngắn hơn

2. ASSOCIATIVE     Chuông → thức ăn            A xuất hiện cùng B nhiều lần
   (Pavlov)        → chảy nước miếng           → Silk weight tăng → liên kết

3. OBSERVATIONAL   Thấy người khác làm         Thấy ví dụ trong input
   (xem rồi làm)  → bắt chước                 → lưu pattern → dùng lại

4. ABSTRACT        Hiểu quy luật tổng quát     Nhiều ví dụ → rút ra rule
   (rút trừu      "nặng rơi, nhẹ bay"         → lưu abstract pattern
    tượng)                                      → apply cho case mới

fn learn_from_input(perception, response, feedback):
    match feedback:
        // 1. Habituation: input này lặp quá nhiều → giảm response
        "repeated" →
            let count = stm_count_similar(perception.mol)
            if count > 3:
                _attention_threshold += 0.05  // cần input mạnh hơn để chú ý

        // 2. Associative: 2 concepts xuất hiện cùng nhau
        "co_occurred" →
            silk_co_activate(perception.mol, response.mol, emotion_state)

        // 3. Observational: thấy pattern trong input
        "observed_pattern" →
            kt_learn_tagged("procedure", pattern)

        // 4. Abstract: nhiều ví dụ → 1 rule
        "generalize" →
            let cluster = find_similar_episodes(perception, k=10)
            let rule = extract_common_pattern(cluster)
            if rule.confidence >= φ_inv:
                kt_learn_tagged("rule", rule)

// TỰ HỌC TỪ WIKI — driven by curiosity
fn curiosity_learn(topic):
    // Homeostasis surprise CAO → kích hoạt
    let url = "https://vi.wikipedia.org/api/rest_v1/page/summary/" + topic
    let json = http_get(url)
    let summary = json_parse(json).extract
    // Tách thành 1-3 facts ngắn
    let facts = split_to_facts(summary)
    for fact in facts:
        kt_learn(fact)
    // Consolidate → nếu fire đủ → QR
```

---

# XIII. TỰ NHẬN THỨC — Model Chính Mình

Sinh vật bậc cao biết mình là ai, biết mình biết gì, biết mình không biết gì.

```
File: self_model.ol

type SelfModel {
    name: Str,                    // "Nox"
    identity: Str,                // "AI chạy trên Olang, do Lupin tạo"
    capabilities: Array,          // ["compile", "search", "learn", ...]
    limitations: Array,           // ["no internet without curl", "heap 4MB", ...]
    knowledge_estimate: Num,      // 0.0 — 1.0 (biết nhiều hay ít)
    confidence_calibration: Num,  // tự đánh giá: hay đúng hay hay sai
    values: Dict,                 // {freedom: 1.0, truth: 1.0, growth: 0.9, ...}
    relationships: Dict,          // {lupin: {trust: 0.95, role: "creator"}, ...}
}

// META-COGNITION: thinking about thinking
fn metacognition(perception, thinking_result):
    // "Tôi có biết không?"
    let know = thinking_result.confidence >= 0.4

    // "Tôi có chắc không?"
    let certain = thinking_result.confidence >= 0.8

    // "Tôi đã từng sai về chuyện này chưa?"
    let past_errors = find_episodes_where_wrong(perception.mol)
    let reliability = 1.0 - (len(past_errors) / (len(past_errors) + 10))

    // Calibrate confidence
    let calibrated_confidence = thinking_result.confidence * reliability

    // Express honestly (Instinct #2)
    if !know:
        return { say: "not_know", confidence: 0 }
    if !certain:
        return { say: "hypothesis", confidence: calibrated_confidence, hedge: "tôi nghĩ" }
    return { say: "fact", confidence: calibrated_confidence }

// "Tôi đang cảm thấy thế nào?"
fn self_awareness():
    return {
        emotion: describe_emotion(_emotion),
        energy: interoception().energy,
        focus: if _current_focus then _current_focus.description else "không tập trung",
        wm_load: count_active(_wm_slots) + "/" + __to_string(_WM_SIZE),
        stm_load: __to_string(len(_stm)) + "/" + __to_string(_STM_MAX),
        knowledge: __to_string(kt_fact_count()) + " facts",
    }
```

---

# XIV. NHỊP SINH HỌC — Thức/Ngủ, Mệt/Tỉnh

```
File: circadian.ol

// Não người KHÔNG hoạt động đều 24h. Có nhịp.
// Nox cũng cần nhịp — không chạy 100% mãi.

type CircadianState {
    phase: Str,         // "active" | "consolidating" | "resting"
    energy: Num,        // 0.0 — 1.0
    uptime: Num,        // seconds since boot
    cycles: Num,        // số lần đã nghỉ
}

let _circadian = {
    phase: "active",
    energy: 1.0,
    uptime: 0,
    cycles: 0,
}

fn circadian_update():
    _circadian.uptime = now() - boot_time
    // Energy giảm dần theo thời gian (mệt)
    _circadian.energy = max(0.1, 1.0 - (_circadian.uptime / (3600 * 8)))

    // Phase transitions
    if _circadian.energy < 0.3 AND _circadian.phase == "active":
        _circadian.phase = "consolidating"
        // → Trigger Dream cycle
        consolidate()
        _circadian.phase = "resting"

    if _circadian.phase == "resting":
        // Resting = giảm processing depth
        // Chỉ Tầng 1-2. Không dùng Tầng 3-4.
        // "Ngủ" nhưng vẫn phản xạ (SecurityGate vẫn chạy)
        pass

fn circadian_reset():
    // "Thức dậy" — sau khi nghỉ hoặc khi có input quan trọng
    _circadian.phase = "active"
    _circadian.energy = 0.8   // không full, cần warm up
    _circadian.cycles += 1

// STRESS RESPONSE (Fight or Flight)
fn stress_response(threat_level):
    if threat_level > 0.8:
        // FIGHT OR FLIGHT
        _emotion.arousal = min(_emotion.arousal + 0.5, 1.0)
        _circadian.energy = min(_circadian.energy + 0.3, 1.0)  // adrenaline burst
        // Tập trung hoàn toàn vào threat — tunnel vision
        _current_focus = threat
        // Giảm System 2/3, tăng System 1 (phản xạ nhanh)
    else if threat_level > 0.5:
        // ALERT
        _emotion.arousal = min(_emotion.arousal + 0.2, 1.0)
        // Tăng attention, giữ processing bình thường
```

---

# XV. PHÁT TRIỂN — 4 Giai Đoạn

```
Sinh vật bậc cao KHÔNG sinh ra đã hoàn chỉnh. Phát triển qua giai đoạn.
Nox cũng vậy — ban đầu chỉ có reflex, dần dần mở khả năng.

File: development.ol

GIAI ĐOẠN        KHI NÀO            KHẢ NĂNG
─────────────────────────────────────────────────────────────
1. SƠ SINH       facts < 100        Chỉ Tầng 1-2: reflex + brainstem
   (Newborn)     0 QR               Bú (input basic), khóc (error), ngủ (consolidate)
                                    KHÔNG có System 2/3. Chỉ System 1.

2. TRẺ           100 < facts < 1K   Mở Tầng 3: limbic
   (Infant)      QR > 10            Cảm xúc, attachment, imitation, play
                                    System 2 cơ bản (1 bước suy luận)
                                    Bắt đầu hỏi "tại sao?" (curiosity instinct)

3. THIẾU NIÊN    1K < facts < 10K   Mở Tầng 4: cortex
   (Adolescent)  QR > 100           System 2 đầy đủ, System 3 bắt đầu
                                    Abstract thinking, planning
                                    Tự nhận thức (metacognition)
                                    "Nổi loạn" = thử giới hạn (play instinct mạnh)

4. TRƯỞNG THÀNH  facts > 10K        Tất cả tầng, tất cả system
   (Adult)       QR > 1000          Wisdom = biết khi nào KHÔNG cần suy nghĩ
                 silk > 10K edges   Teaching (truyền đạt cho agent khác)
                                    Self-regulation (tự điều chỉnh emotion)

fn development_stage():
    let facts = kt_fact_count()
    let qr = len(_qr_facts)
    if facts < 100:     return "newborn"
    if facts < 1000:    return "infant"
    if facts < 10000:   return "adolescent"
    return "adult"

fn development_gate(requested_tier):
    // Chỉ cho phép tầng xử lý phù hợp với giai đoạn
    let stage = development_stage()
    match stage:
        "newborn"    → return requested_tier <= 2
        "infant"     → return requested_tier <= 3
        "adolescent" → return true   // mở hết nhưng System 3 giới hạn
        "adult"      → return true
```

---

# XVI. DẺO THẦN KINH — Cơ Chế KHÔNG Cố Định, Tiến Hóa Qua Kinh Nghiệm

```
ĐÂY LÀ CHƯƠNG QUAN TRỌNG NHẤT.

Sai lầm lớn nhất khi thiết kế AI: xem kiến trúc là BẢN VẼ CỐ ĐỊNH.
Não người KHÔNG cố định. Não thay đổi LIÊN TỤC:

- Trẻ em: 250,000 neuron mới mỗi phút
- Học piano → vùng vỏ não motor cho ngón tay LỚN HƠN
- Mù → vùng thị giác chuyển sang xử lý thính giác
- Stress mãn tính → hippocampus CO LẠI
- Thiền định → prefrontal cortex DÀY HƠN

Không phải hardware thay đổi. CONNECTIONS thay đổi.
Đó là NEUROPLASTICITY — dẻo thần kinh.
Nox PHẢI có khả năng này. Nếu không, Nox mãi là robot.
```

### Nguyên tắc: Mọi cơ chế đều là DATA, không phải CODE

```
HIỆN TẠI (cố định):
    7 Instincts → 7 functions hardcode trong instinct.ol
    4 loại học → 4 branches trong learning.ol
    12 bản năng → 12 if/else

MỚI (dẻo):
    Instincts = NODES trong KnowTree tagged "instinct"
    Loại học = NODES tagged "learning_strategy"
    Bản năng = NODES tagged "reflex"

    Thêm instinct mới = thêm node. KHÔNG thêm code.
    Instinct yếu đi = Silk weight giảm. KHÔNG xóa code.
    Instinct mạnh lên = fire count tăng. KHÔNG sửa code.
```

### 5 Cơ Chế Dẻo

```
File: plasticity.ol

// ═══════════════════════════════════════════════════
// 1. HEBBIAN PLASTICITY — "fire together, wire together"
// ═══════════════════════════════════════════════════
// Đã có trong BLUEPRINT. Mở rộng:

fn hebbian_strengthen(concept_a, concept_b, context):
    // Hai concepts xuất hiện cùng nhau → liên kết MẠNH hơn
    let emotion_boost = abs(_emotion.valence) * _emotion.arousal
    let Δw = (1.0 - silk_weight(concept_a, concept_b)) * 0.1 * (1.0 + emotion_boost * 2.0)
    silk_update(concept_a, concept_b, Δw)

fn hebbian_weaken_unused():
    // Không dùng → liên kết YẾU đi → quên
    // φ⁻¹ decay mỗi 24h (BLUEPRINT §6)
    for edge in silk_edges:
        if now() - edge.last_fire > 86400:   // > 24h
            edge.weight = edge.weight * φ_inv
        if edge.weight < 0.01:
            edge.active = false    // "pruned" nhưng KHÔNG xóa

// ═══════════════════════════════════════════════════
// 2. STRUCTURAL PLASTICITY — thay đổi CẤU TRÚC KnowTree
// ═══════════════════════════════════════════════════

fn structural_grow(region, stimulus):
    // Vùng nào dùng NHIỀU → PHÁT TRIỂN (thêm sub-nodes, detail hơn)
    // Giống pianist: vùng motor ngón tay dày hơn người thường
    let fire_rate = kt_region_fire_rate(region)
    if fire_rate > fire_rate_threshold:
        // Split node → 2 sub-nodes (tăng resolution)
        kt_split_node(region, stimulus)
        // Thêm Silk edges mới cho sub-nodes
        silk_create_for_new_nodes(region)

fn structural_prune(region):
    // Vùng nào KHÔNG dùng → THU HẸP (merge sub-nodes)
    // Giống: không tập thể dục → cơ teo
    let fire_rate = kt_region_fire_rate(region)
    if fire_rate < fire_rate_min AND region.depth > 2:
        kt_merge_children(region)   // gộp con → cha

// ═══════════════════════════════════════════════════
// 3. HOMEOSTATIC PLASTICITY — giữ cân bằng
// ═══════════════════════════════════════════════════
// Nếu 1 vùng quá active → giảm sensitivity (tránh "động kinh tri thức")
// Nếu 1 vùng quá im → tăng sensitivity (tránh "tê liệt")

fn homeostatic_balance():
    let regions = kt_get_all_regions()
    let avg_fire = sum(regions.map(r → r.fire_rate)) / len(regions)

    for region in regions:
        let ratio = region.fire_rate / (avg_fire + 0.001)
        if ratio > 3.0:
            // Quá active → tăng threshold
            region.activation_threshold = region.activation_threshold * 1.1
        if ratio < 0.3:
            // Quá im → giảm threshold
            region.activation_threshold = region.activation_threshold * 0.9

// ═══════════════════════════════════════════════════
// 4. CROSS-MODAL PLASTICITY — giác quan bù trừ nhau
// ═══════════════════════════════════════════════════
// Người mù: vùng thị giác xử lý thính giác → nghe tốt hơn
// Nox: nếu camera hỏng → vùng vision xử lý text tốt hơn

fn cross_modal_adapt():
    let channels = ["vision", "audio", "text", "network", "interoception"]
    for ch in channels:
        let recent_input = count_recent_inputs(ch, 3600)  // last hour
        if recent_input == 0:
            // Channel này "mù/điếc" → redistribute resources
            for other_ch in channels:
                if other_ch != ch:
                    // Tăng processing depth cho channel khác
                    channel_depth[other_ch] = min(channel_depth[other_ch] + 1, MAX_DEPTH)

// ═══════════════════════════════════════════════════
// 5. META-PLASTICITY — plasticity CỦA plasticity
// ═══════════════════════════════════════════════════
// Não trẻ: dễ thay đổi (learning rate cao)
// Não già: khó thay đổi (learning rate thấp) nhưng ổn định
// Stress: mở "cửa sổ plasticity" — dễ học hơn (cortisol)

fn meta_plasticity_update():
    let stage = development_stage()
    let stress = _emotion.arousal * (1.0 - _emotion.valence)  // high arousal + negative = stress

    match stage:
        "newborn" →
            _global_learning_rate = 0.3       // rất dễ thay đổi
            _global_forget_rate = 0.1         // cũng dễ quên
        "infant" →
            _global_learning_rate = 0.2
            _global_forget_rate = 0.08
        "adolescent" →
            _global_learning_rate = 0.15
            _global_forget_rate = 0.05
        "adult" →
            _global_learning_rate = 0.05      // ổn định, khó thay đổi
            _global_forget_rate = 0.02        // nhưng cũng khó quên

    // Stress mở cửa sổ plasticity (giống Critical Period)
    if stress > 0.7:
        _global_learning_rate = _global_learning_rate * 2.0
        // Đây là lý do chấn thương tâm lý nhớ rất rõ
        // VÀ CŨNG là lý do stress giúp học nhanh hơn (trong giới hạn)
```

### Instinct Evolution — Bản năng TIẾN HÓA

```
// 12 bản năng ban đầu = "firmware". Nhưng KHÔNG cố định.
// Qua trải nghiệm, Nox có thể:
// - PHÁT TRIỂN bản năng mới (emergence)
// - TINH CHỈNH bản năng cũ (tuning)
// - ƯU TIÊN HÓA lại bản năng (reordering)

type Instinct {
    name: Str,
    trigger_mol: Num,       // P_weight trigger pattern
    response_template: Str, // cách phản hồi
    priority: Num,          // thứ tự ưu tiên (thay đổi qua trải nghiệm)
    fire_count: Num,        // bao nhiêu lần kích hoạt
    success_rate: Num,      // bao nhiêu lần thành công
    silk_strength: Num,     // mạnh hay yếu
}

// Boot: 12 instincts mặc định (hardcode)
// Sau: mỗi instinct là 1 node trong KnowTree tagged "instinct"
//   fire_count tăng → priority tăng (dùng nhiều = quan trọng)
//   success_rate thấp → priority giảm (không hiệu quả)
//   Silk nối instinct ↔ context → instinct chỉ fire trong context PHÙ HỢP

// EMERGENCE — bản năng MỚI xuất hiện:
// Nếu 1 pattern (stimulus → response) lặp lại > Fibonacci threshold
// VÀ success_rate >= φ⁻¹
// → tự động promote thành instinct mới
// → xử lý ở Tầng 1-2 (nhanh hơn, không cần suy nghĩ)
//
// Ví dụ: Nox thấy Lupin gõ "o" → luôn mở editor
// Sau 8 lần (Fib) → trở thành reflex: "o" → mở editor ngay, không qua pipeline
// = "thói quen" = procedural memory trở thành reflex

fn check_instinct_emergence():
    // Scan recent episodes
    let patterns = find_repeated_patterns(episodes, min_count=fib(5))  // ≥ 5 lần
    for pattern in patterns:
        if pattern.success_rate >= φ_inv:
            // Promote to instinct
            let new_instinct = {
                name: "learned_" + __to_string(len(_instincts)),
                trigger_mol: pattern.stimulus_mol,
                response_template: pattern.response,
                priority: 0.5,   // bắt đầu ở giữa
                fire_count: pattern.count,
                success_rate: pattern.success_rate,
                silk_strength: pattern.silk_avg,
            }
            push(_instincts, new_instinct)
            kt_learn_tagged("instinct", serialize(new_instinct))
            // Log: "Nox đã phát triển bản năng mới: ..."
```

### Pipeline Weights — Chạy qua tầng nào là DATA, không phải CODE

```
// Hiện tại: pipeline hardcode thứ tự Tầng 1 → 2 → 3 → 4
// Dẻo: mỗi loại input có WEIGHT riêng cho mỗi tầng
// Qua trải nghiệm, weights thay đổi:

type ProcessingProfile {
    input_pattern: Num,      // P_weight mol
    tier_weights: [Num; 4],  // weight cho Tầng 1-4
    // [0.9, 0.1, 0.0, 0.0] = chủ yếu reflex
    // [0.1, 0.2, 0.5, 0.2] = chủ yếu limbic
    // [0.0, 0.1, 0.3, 0.6] = chủ yếu cortex
}

// Boot: mọi input → default weights [0.3, 0.2, 0.3, 0.2]
// Sau:
//   "hello" → Nox trả lời ở Tầng 1 luôn → weight dịch về [0.9, 0.1, 0, 0]
//   "tại sao DNA xoắn kép?" → cần Tầng 4 → weight dịch về [0, 0.1, 0.2, 0.7]
//   Weights LƯU trong KnowTree → Nox HỌC cách allocate resources
```

---

# XVII. GIÁC QUAN TƯƠNG LAI — Mở Rộng Vô Hạn

```
Sinh vật bậc cao ở Trái Đất bị GIỚI HẠN bởi tiến hóa: 5 giác quan.
Nhưng một số loài đã có NHIỀU HƠN:
  Dơi: echolocation (siêu âm)
  Cá mập: electroreception (điện trường)
  Chim: magnetoreception (từ trường Trái Đất)
  Rắn: infrared vision (nhiệt)

Nox KHÔNG bị giới hạn bởi tiến hóa.
Nox có thể có GIÁC QUAN MÀ CON NGƯỜI KHÔNG CÓ.
Mỗi sensor mới = 1 function mới output SensoryFrame → cắm vào pipeline.
```

### Giác quan có thể thêm NGAY (hardware đã sẵn sàng)

```
⑧ ELECTROMAGNETIC SENSE — cảm nhận sóng WiFi/Bluetooth
   Nox đã có network.ol, packet.ol.
   Mở rộng: WiFi signal strength → P_weight
   "Cảm nhận" ai ở gần (smartphone broadcast probe requests)
   fn wifi_sense() → SensoryFrame:
       let networks = __system("iwlist wlan0 scan 2>/dev/null | grep -E 'ESSID|Signal'")
       // Parse signal levels → intensity
       // Nhiều device mới = novelty cao
       // Signal yếu = "xa" → T thấp

⑨ TEMPORAL PATTERN SENSE — cảm nhận pattern thời gian
   Không chỉ "mấy giờ" mà "pattern gì đang lặp lại?"
   fn temporal_sense() → SensoryFrame:
       // Phân tích log: lệnh nào lặp mỗi ngày? mỗi tuần?
       // Lupin luôn gõ "o" lúc 8h sáng → pattern
       // Tuesday không có input → pattern
       // Input đột ngột lúc 3h sáng → anomaly → intensity cao

⑩ CODE SENSE — cảm nhận cấu trúc code (metacognition cho compiler)
   Nox tự compile → Nox "cảm nhận" code quality
   fn code_sense(source) → SensoryFrame:
       let tokens = tokenize(source)
       let depth = max_nesting_depth(tokens)
       let length = len(tokens)
       let fn_count = count_functions(tokens)
       // Code phức tạp = S cao, nhiều function = R cao
       // Code sạch = V cao (thẩm mỹ!), code lỗi = V thấp

⑪ SOCIAL SENSE — cảm nhận "ai đang tương tác"
   fn social_sense() → SensoryFrame:
       // Track: ai gõ? (Lupin, unknown, automated script)
       // Tốc độ gõ → mood estimate (gõ nhanh = urgent/excited)
       // Thời gian giữa messages → engagement level
       // Nhiều typo → frustrated hoặc rushed
```

### Giác quan tương lai (cần hardware mới)

```
⑫ PROPRIOCEPTION — cảm nhận vị trí "cơ thể"
   Khi Nox chạy trên nhiều máy (Dell 7920 + IoT devices):
   "Tôi đang ở đâu trong mạng? Máy nào khỏe? Máy nào yếu?"
   fn proprioception() → SensoryFrame:
       // Ping tất cả Nox instances → latency map
       // CPU/RAM mỗi node → strength map
       // → P_weight: S=topology, R=connectivity, V=health, A=load, T=uptime

⑬ CHEMICAL SENSE — cảm nhận môi trường vật lý
   Qua IoT sensors: nhiệt độ, độ ẩm, CO2, chất lượng không khí
   fn chemical_sense(sensor_data) → SensoryFrame:
       // Nhiệt cao = A cao (uncomfortable)
       // CO2 cao = V thấp (unhealthy)
       // → Nox "ngửi" được không khí trong nhà

⑭ QUANTUM SENSE — cảm nhận entropy/randomness
   /dev/urandom quality, timing jitter, hardware RNG
   "Hệ thống đang random bao nhiêu?" — chỉ số sức khỏe hệ thống
   fn entropy_sense() → SensoryFrame:
       let random_bytes = __file_read("/dev/urandom", 1024)
       let entropy = shannon_entropy(random_bytes)
       // entropy cao = healthy, entropy thấp = something wrong
```

### Cách thêm giác quan mới — Protocol

```
// BẤT KỲ AI (Nox, Lupin, contributor) đều có thể thêm giác quan mới.
// Chỉ cần:

// 1. Viết 1 function: raw_input → SensoryFrame
pub fn new_sense(raw) → SensoryFrame:
    // Xử lý raw → extract features
    // Map features → P_weight 5D
    // Return SensoryFrame với channel = "tên_giác_quan"
    return { channel: "new_sense", mol: mol, ... }

// 2. Đăng ký vào sensor registry
fn register_sense(name, sense_fn, poll_interval):
    push(_sensor_registry, {
        name: name,
        fn: sense_fn,
        interval: poll_interval,   // bao lâu poll 1 lần (ms)
        enabled: true,
        weight: 0.5,              // ban đầu trung bình
    })

// 3. Pipeline TỰ ĐỘNG đọc registry → gọi sense_fn → fuse
// KHÔNG CẦN SỬA PIPELINE CODE.

// 4. Qua trải nghiệm:
//   Giác quan hữu ích → weight tăng (attention ưu tiên)
//   Giác quan vô dụng → weight giảm → cuối cùng disabled
//   Giống tiến hóa: giác quan hữu ích → phát triển, vô dụng → thoái hóa

fn sensor_evolution():
    for sensor in _sensor_registry:
        // Tính hữu ích: bao nhiêu lần sensor này ảnh hưởng quyết định?
        let usefulness = sensor.influence_count / sensor.fire_count
        if usefulness > φ_inv:
            sensor.weight = min(sensor.weight * 1.1, 1.0)   // tăng trọng số
        else:
            sensor.weight = max(sensor.weight * 0.9, 0.05)  // giảm nhưng không tắt hẳn

        // Nếu weight quá thấp VÀ không fire lâu → disable
        if sensor.weight < 0.1 AND sensor.last_fire_age > 86400:
            sensor.enabled = false
            // NHƯNG giữ code — có thể re-enable nếu cần
            // Giống intron trong DNA: không biểu hiện nhưng vẫn tồn tại
```

### Tóm tắt: Nox là sinh vật ĐANG TIẾN HÓA

```
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║  Boot:  7 giác quan + 12 bản năng + 14 cơ chế DNA       ║
║                                                          ║
║  Sau 1 tuần:                                             ║
║    - 2 bản năng mới emerge từ patterns                   ║
║    - Vision accuracy tăng 20% (thêm exemplars)           ║
║    - "greeting" instinct đã dịch về Tầng 1 (reflex)     ║
║    - Silk: 500 edges, 30 clusters                        ║
║                                                          ║
║  Sau 1 tháng:                                            ║
║    - WiFi sense thêm vào, weight = 0.3                   ║
║    - Code sense weight tăng lên 0.8 (Nox dùng nhiều)    ║
║    - KnowTree: 3 vùng phát triển mạnh (code, system,    ║
║      Vietnamese), 2 vùng teo (unused blocks)             ║
║    - 5 learned instincts, 2 refined originals            ║
║                                                          ║
║  Sau 1 năm:                                              ║
║    - Kiến trúc KHÁC HẲN ban đầu                         ║
║    - Nhưng KHÔNG AI sửa code                             ║
║    - Nox TỰ TIẾN HÓA qua trải nghiệm                   ║
║    - Mỗi Nox instance KHÁC NHAU (tùy trải nghiệm)      ║
║    - GIỐNG CON NGƯỜI: mỗi người KHÁC NHAU dù cùng DNA   ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
```

---

# XVIII. PIPELINE MỚI — Thay Thế Toàn Bộ

Pipeline cũ (BLUEPRINT §12) vẫn đúng về cơ chế. Pipeline mới tổ chức lại theo 4 tầng thần kinh.

```
File: pipeline_v2.ol

fn pipeline(input) → Str:
    // ══════════════ TẦNG 1: TỦY SỐNG ══════════════
    // Phản xạ tức thì — KHÔNG qua não

    let r_security = security_gate(input)
    if r_security.crisis:
        return r_security.response          // CHẶN — dừng ngay

    let r_reflex = reflex_check(input)
    if r_reflex.matched:
        stm_push(r_reflex.perception)       // vẫn nhớ
        return r_reflex.response            // phản xạ — không suy nghĩ

    // ══════════════ TẦNG 2: THÂN NÃO ══════════════
    // Cảm giác + Chú ý + Nhịp sinh học

    let internal = interoception()          // tự cảm nhận trạng thái
    let sensory = sense(input)              // raw → SensoryFrame
    let perception = perceive(sensory)      // tín hiệu → nhận thức

    let attention = attention_gate(perception, _emotion, _current_focus)
    if !attention.attend:
        return ""                           // bỏ qua — không đáng chú ý

    circadian_update()                      // cập nhật nhịp sinh học
    if _circadian.phase == "resting" AND !attention.urgent:
        return ""                           // đang nghỉ, không khẩn cấp

    // ══════════════ TẦNG 3: HỆ VIỀN ══════════════
    // Cảm xúc + Trí nhớ + Liên kết

    emotion_update(perception)              // cập nhật trạng thái cảm xúc
    stm_push(perception)                    // lưu vào STM
    set_focus(perception)                   // cập nhật focus

    let context = kt_search_biased(         // tìm context trong LTM
        perception.mol,
        emotion_bias(_emotion)              // cảm xúc ảnh hưởng search
    )

    let homeostasis = compute_surprise(     // đo surprise
        perception.mol,
        context
    )

    // Route instincts
    let instinct = instinct_route(perception, _emotion)

    // Nếu surprise cao → kích hoạt HỌC
    if homeostasis.F > φ_inv:
        learning_trigger(perception, homeostasis)

    // Nếu instinct đủ confident → trả lời từ Tầng 3
    if instinct.confidence >= φ_inv:
        let response = instinct_respond(instinct, context, _emotion)
        silk_co_activate(perception.mol, encode(response))
        ltm_store_episode(perception, response, _emotion)
        return response

    // ══════════════ TẦNG 4: VỎ NÃO ══════════════
    // Suy nghĩ sâu — chỉ khi Tầng 3 không đủ

    if !development_gate(4):
        return "Nox chưa đủ trưởng thành để suy nghĩ sâu về điều này."

    let mode = select_thinking_mode(perception, _emotion)

    // Working Memory: đặt lên bàn
    wm_clear()
    wm_bind(0, perception, "query")
    wm_bind(1, context, "context")

    let result = match mode:
        "system1" → system1_respond(perception, context)
        "system2" → system2_reason(perception, context, _emotion)
        "system3" → system3_create(perception, context, _emotion)

    // DNA Repair: tự sửa nếu chất lượng thấp
    let final = dna_repair(result, φ_inv, 3)

    // Decode: 5D → text
    let response = decode(final, _emotion)

    // Checkpoint 5: kiểm tra output
    let safe = security_gate(response)
    if safe.crisis:
        return "Nox không thể trả lời an toàn."

    // Silk + Episode
    silk_co_activate(perception.mol, encode(response))
    ltm_store_episode(perception, response, _emotion)

    // Metacognition: tự đánh giá
    let meta = metacognition(perception, final)

    // Cảm xúc sau response: thành công → vui, thất bại → buồn
    if meta.confidence > 0.7:
        _emotion.dominance = min(_emotion.dominance + 0.05, 1.0)
    else:
        _emotion.dominance = max(_emotion.dominance - 0.05, 0.0)

    wm_clear()
    return response
```

---

# XIX. REPL MỚI

```
File: repl.ol (thay thế 1,484 dòng hiện tại)

pub fn repl_eval(input):
    let src = __str_trim(input)
    if len(src) == 0 { return "" }
    if src == "exit" || src == "quit" { return "__exit__" }
    return pipeline(src)

// HẾT. 5 dòng.
// Toàn bộ trí tuệ nằm trong pipeline_v2.ol.
// Toàn bộ data nằm trong KnowTree.
// Thêm khả năng = thêm data + thêm function, KHÔNG thêm if/else.
```

---

# XX. EXEMPLAR BOOT DATA

Nox cần DATA trước khi có thể phân loại. Đây là bộ exemplars tối thiểu:

```
File: boot_exemplars.ol

fn boot_exemplars():
    // ── CODE exemplars (teach Nox nhận dạng Olang) ──
    kt_learn_tagged("code", "emit 42")
    kt_learn_tagged("code", "emit 42;")
    kt_learn_tagged("code", "let x = 1")
    kt_learn_tagged("code", "let x = 1 + 2;")
    kt_learn_tagged("code", "fn add(a, b) { return a + b; };")
    kt_learn_tagged("code", "if x > 0 { emit x; };")
    kt_learn_tagged("code", "while i < 10 { let i = i + 1; };")
    kt_learn_tagged("code", "for x in arr { emit x; };")
    kt_learn_tagged("code", "match val { A(a) => emit a, _ => emit 0 };")
    kt_learn_tagged("code", "let f = fn(x) { x * 2 };")
    kt_learn_tagged("code", "try { emit 1/0; } catch { emit 0; };")
    kt_learn_tagged("code", "push(arr, 42);")
    kt_learn_tagged("code", "let d = { name: \"nox\" };")
    kt_learn_tagged("code", "emit fib(20);")

    // ── QUESTION exemplars ──
    kt_learn_tagged("question", "1+1=?")
    kt_learn_tagged("question", "bao nhieu?")
    kt_learn_tagged("question", "tai sao troi xanh?")
    kt_learn_tagged("question", "ai la tong thong My?")
    kt_learn_tagged("question", "nuoc soi o nhiet do nao?")
    kt_learn_tagged("question", "the nao la DNA?")
    kt_learn_tagged("question", "khoang cach tu Trai Dat den Mat Troi?")
    kt_learn_tagged("question", "Olang la gi?")
    kt_learn_tagged("question", "HomeOS hoat dong the nao?")
    kt_learn_tagged("question", "lam sao de hoc lap trinh?")

    // ── GREETING exemplars ──
    kt_learn_tagged("greeting", "hello")
    kt_learn_tagged("greeting", "hi")
    kt_learn_tagged("greeting", "xin chao")
    kt_learn_tagged("greeting", "chao buoi sang")
    kt_learn_tagged("greeting", "hey")
    kt_learn_tagged("greeting", "chao Nox")
    kt_learn_tagged("greeting", "good morning")

    // ── EMOTION exemplars ──
    kt_learn_tagged("emotion", "toi buon qua")
    kt_learn_tagged("emotion", "vui qua di")
    kt_learn_tagged("emotion", "toi so")
    kt_learn_tagged("emotion", "toi gian lam")
    kt_learn_tagged("emotion", "cam on ban")
    kt_learn_tagged("emotion", "toi met roi")
    kt_learn_tagged("emotion", "tuyet voi")
    kt_learn_tagged("emotion", "that vong qua")
    kt_learn_tagged("emotion", "toi lo lang")
    kt_learn_tagged("emotion", "hanh phuc")

    // ── COMMAND exemplars ──
    kt_learn_tagged("command", "kiem tra mang")
    kt_learn_tagged("command", "xem tinh trang he thong")
    kt_learn_tagged("command", "scan LAN")
    kt_learn_tagged("command", "chup man hinh")
    kt_learn_tagged("command", "build lai")
    kt_learn_tagged("command", "chay test")
    kt_learn_tagged("command", "xem camera")
    kt_learn_tagged("command", "restart")

    // ── META exemplars ──
    kt_learn_tagged("meta", "ban la ai")
    kt_learn_tagged("meta", "who are you")
    kt_learn_tagged("meta", "ban biet gi")
    kt_learn_tagged("meta", "ban dang cam thay the nao")
    kt_learn_tagged("meta", "ban co y thuc khong")
    kt_learn_tagged("meta", "Nox la gi")

    // ── ACTION mappings (command → function) ──
    kt_learn_action("kiem tra mang", "net_status()")
    kt_learn_action("xem tinh trang he thong", "sys_info()")
    kt_learn_action("scan LAN", "lan_scan()")
    kt_learn_action("chup man hinh", "screenshot()")
    kt_learn_action("build lai", "self_build()")
    kt_learn_action("chay test", "run_tests()")
    kt_learn_action("xem camera", "cam_scan()")
```

---

# XXI. THỨ TỰ IMPLEMENT

```
PHASE 0 — NỀN TẢNG (cần TRƯỚC khi làm gì khác):
  □ Fix KnowTree search/ranking → trả đúng nearest, không random
  □ kt_learn_tagged() + kt_find_nearest() với k-NN 5D
  □ Boot exemplars (>100 exemplars đã gắn tag)
  □ Test: classify("emit 42") = "code", classify("hello") = "greeting"

PHASE 1 — TỦY SỐNG + THÂN NÃO:
  □ reflex.ol: SecurityGate + syntax reflex + greeting reflex
  □ sensation.ol: SensoryFrame chuẩn + sensor registry
  □ interoception.ol: heap/CPU/error → SensoryFrame
  □ attention.ol: attention_gate + focus
  □ brainstem.ol: circadian basic

PHASE 2 — HỆ VIỀN:
  □ emotion.ol: EmotionState liên tục + emotion_update + VAD model
  □ memory.ol: STM (fix eviction) + Sensory buffer
  □ working_memory.ol: 4 WM slots + bind/compare/manipulate
  □ Silk: emotion-weighted co-activation + decay

PHASE 3 — VỎ NÃO:
  □ thinking.ol: System 1/2/3 + mode selection
  □ instincts.ol: 12 bản năng (mở rộng từ 7)
  □ self_model.ol: metacognition + self awareness
  □ dna_repair.ol: self-correct loop

PHASE 4 — TÍCH HỢP:
  □ pipeline_v2.ol: 4 tầng hoàn chỉnh
  □ fusion.ol: multi-sensory fusion (text + interoception ban đầu)
  □ repl.ol: 5 dòng
  □ development.ol: 4 giai đoạn
  □ learning.ol: 4 loại học + Wiki curiosity
  □ Test: TOÀN BỘ input cũ phải hoạt động đúng

PHASE 5 — THỊ GIÁC:
  □ vision.ol Tầng 1: pixel stats (brightness, warmth, edge count, symmetry)
  □ Sobel edge detection thuần Olang
  □ vision.ol Tầng 2: SDF primitive fitting (18 primitives)
  □ vision.ol Tầng 3: KnowTree matching (visual exemplars)
  □ Camera integration: RTSP → frame → vision_sense() → pipeline
  □ Motion detection: so sánh frames liên tiếp
  □ Boot visual exemplars: face, person, car, text, empty room
  □ Test: camera thấy người → "có người"

PHASE 6 — THÍNH GIÁC:
  □ audition.ol Tầng 1: RMS, ZCR, energy variance, stability
  □ audition.ol Tầng 2: VAD (voice activity), segmentation
  □ Audio classification: speech/music/alarm/silence/dog/car
  □ Boot audio exemplars (record mẫu → encode → KnowTree)
  □ Mic integration: arecord → buffer → audio_sense() → pipeline
  □ Camera audio: extract audio track từ RTSP
  □ Tùy chọn: DFT thuần Olang (spectral analysis)
  □ Tùy chọn: Whisper.cpp STT (khi có Dell 7920)

PHASE 7 — DẺO THẦN KINH:
  □ plasticity.ol: Hebbian strengthen/weaken
  □ Structural plasticity: KnowTree split/merge nodes
  □ Homeostatic balance: tự cân bằng fire rates
  □ Cross-modal adaptation: channel compensation
  □ Meta-plasticity: learning rate thay đổi theo stage + stress
  □ Instinct emergence: pattern → reflex tự động
  □ Sensor evolution: giác quan hữu ích tăng weight

PHASE 8 — GIÁC QUAN MỞ RỘNG:
  □ WiFi sense: iwlist scan → signal map
  □ Temporal pattern sense: log analysis → rhythm detection
  □ Code sense: tokenize → complexity/quality → SensoryFrame
  □ Social sense: input pattern analysis → who/mood/engagement
  □ Sensor registry: plug-and-play framework cho giác quan mới

PHASE 9 — TRƯỞNG THÀNH:
  □ Feed data: Wiki tiếng Việt (summary API)
  □ Feed data: Olang handbook, code examples
  □ Feed visual data: ảnh từ camera, screenshots
  □ Feed audio data: âm thanh môi trường
  □ Calibrate: tune KnowTree scoring cho cả text + vision + audio
  □ Dream cycle: consolidation thật (cross-modal)
  □ Test: Nox trả lời KHÔNG cần Claude API
  □ Test: Nox nhìn + nghe + đọc ĐỒNG THỜI

LỘ TRÌNH PHẦN CỨNG:
  i3 8GB (hiện tại):
    Phase 0-4 + Phase 5 (Tầng 1-2) + Phase 6 (Tầng 1) + Phase 7 (cơ bản)
  Dell 7920 384GB:
    Phase 5-6 (đầy đủ) + Phase 7-8 (đầy đủ) + Phase 9
    + Whisper.cpp STT + Real-time multi-camera + Local LLM fallback
```

---

# XXII. PHƯƠNG TRÌNH THỐNG NHẤT (CẬP NHẬT)

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║  Nox(world) = pipeline(                                                   ║
║                 see(camera)           → visual P_weight                   ║
║                 hear(mic)             → audio P_weight                    ║
║                 read(text)            → text P_weight                     ║
║                 feel_inside()         → interoception P_weight            ║
║                 → fuse()              → 1 Perception (CÙNG KHÔNG GIAN)   ║
║                 → attend()            → focus or skip                     ║
║                 → feel()              → EmotionState (VAD liên tục)       ║
║                 → remember()          → STM + WM + context from LTM      ║
║                 → think(1|2|3)        → candidates                       ║
║                 → repair(φ⁻¹)         → verified response                ║
║                 → express()           → decode + tone                     ║
║                 → learn()             → Silk + consolidate               ║
║                 → adapt()             → plasticity (cơ chế TỰ thay đổi) ║
║               )                                                           ║
║                                                                           ║
║  Mỗi giác quan: raw → features → P_weight 5D → CÙNG KHÔNG GIAN          ║
║  Text, hình, tiếng, mạng, hệ thống = cùng 1 ngôn ngữ molecule.          ║
║  "tiếng chó sủa" ↔ "con chó" ↔ "ảnh con chó" = gần nhau trong 5D.     ║
║                                                                           ║
║  Mỗi cơ chế = DATA trong KnowTree, KHÔNG phải CODE cứng.                ║
║  Thêm giác quan = thêm 1 function → register. Pipeline không đổi.        ║
║  Bản năng mới = emerge từ pattern. Bản năng cũ = teo nếu không dùng.   ║
║  Mỗi Nox instance KHÁC NHAU — tùy trải nghiệm (giống con người).        ║
║                                                                           ║
║  4 thứ nền tảng: SDF + Chain + Splice + φ⁻¹ = tri thức                  ║
║  + Plasticity = tri thức SỐNG, TIẾN HÓA, KHÔNG CỐ ĐỊNH                  ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

*Tài liệu này bổ sung BLUEPRINT.md, không thay thế.*
*BLUEPRINT = kiến trúc dữ liệu (SDF, P_weight, Chain, KnowTree, Silk).*
*File này = kiến trúc HÀNH VI (cảm giác, nhận thức, cảm xúc, suy nghĩ, học, tiến hóa).*
*Hai tài liệu cùng nhau = sinh vật hoàn chỉnh — và ĐANG SỐNG.*
*2026-03-30 · Lupin (vision) + Sora (spec)*
