# TRI THỨC PHÂN TỬ
## Khung Lý Thuyết Về Biểu Diễn Bản Chất Và Trí Tuệ Nhân Tạo Tự Sửa Chữa

**Ấn bản 2 — Sửa đổi toàn diện**

*goldlotus1810 và cộng sự · 2026*

---

## Lời Nói Đầu


Tôi muốn nó có một công cụ hiểu thế giới đúng. Không bị nhiễu. Không bị thao túng. Có quy tắc bảo vệ con người từ trong bản chất — không phải từ fine-tuning có thể bị ghi đè.

Dự án Origin bắt đầu ngày 11/03/2026. Sau 12 ngày, ngày 23/03/2026, Olang đạt self-hosting — trình biên dịch tự biên dịch chính mình trong tệp nhị phân 806KB không phụ thuộc gì. Đến ngày 26/03/2026, hệ thống đạt 1.021KB với 88 test, JIT compiler, và 109 phép toán tích hợp.

Cuốn sách này ghi lại khung lý thuyết đằng sau dự án đó. Nó phân biệt rõ ràng giữa:

- **[LÝ THUYẾT]** — mô hình toán học đã đề xuất
- **[THIẾT KẾ]** — kiến trúc đã đặc tả nhưng chưa triển khai đầy đủ
- **[THỰC NGHIỆM]** — code chạy được, có số liệu đo được

Mỗi tuyên bố trong sách đều được gắn nhãn trạng thái. Không có gì được trình bày như đã hoàn thành nếu chưa hoàn thành.

---

## Tóm Tắt

Chuyên khảo này trình bày Tri Thức Phân Tử (Molecular Cognition) — khung lý thuyết biểu diễn tri thức bằng bản chất toán học thay vì dữ liệu thô. Mỗi đơn vị tri thức được mã hóa thành phân tử 16-bit trong không gian 5 chiều, mỗi chiều nền tảng hóa bằng mô hình vật lý riêng.

Khung lý thuyết ánh xạ 14 cơ chế DNA sinh học sang 14 thuật toán tính toán, với tham vọng rằng một kiến trúc nhận thức hoàn chỉnh có thể nảy sinh từ bốn thành phần: hàm khoảng cách có dấu f(p), toán tử xâu chuỗi, toán tử cắt ghép, và hằng số φ⁻¹ ≈ 0,618.

**Trạng thái kiểm chứng:**

```
╔═══════════════════════════════════════════════════════════╗
║  Thành phần              │ Trạng thái      │ Bằng chứng  ║
╠═══════════════════════════════════════════════════════════╣
║  Self-hosting compiler   │ ✅ ĐÃ CHẠY      │ 88 test     ║
║  VM x86_64 (8.618 LOC)  │ ✅ ĐÃ CHẠY      │ fib(30)=4ms ║
║  JIT auto-compiler       │ ✅ ĐÃ CHẠY      │ benchmark   ║
║  KnowTree cơ bản         │ ✅ ĐÃ CHẠY      │ Q&A hoạt động║
║  Hebbian + Silk cơ bản   │ ✅ ĐÃ CHẠY      │ 17 edges    ║
║  Mô hình cảm xúc V-A    │ ⚠️ MỘT PHẦN     │ routing OK  ║
║  SecurityGate             │ ⚠️ MỘT PHẦN     │ keyword+norm║
║  42 công thức UDC         │ 📋 ĐẶC TẢ      │ chưa code   ║
║  Dream Cycle 4 pha        │ 📋 ĐẶC TẢ      │ prototype   ║
║  Fusion đa giác quan      │ 📋 ĐẶC TẢ      │ chưa sensor ║
║  ED25519 signing          │ 📋 ĐẶC TẢ      │ chưa ký thật║
║  Ánh xạ cảm xúc → vật lý │ 📐 LÝ THUYẾT   │ chưa đo     ║
║  Đẳng cấu DNA             │ 📐 LÝ THUYẾT   │ tương tự    ║
╚═══════════════════════════════════════════════════════════╝

Ký hiệu: ✅ = đã chạy, có test
         ⚠️ = có code nhưng chưa đầy đủ
         📋 = đã đặc tả, chưa/đang implement
         📐 = mô hình lý thuyết, chưa kiểm chứng thực nghiệm
```

---

## Mục Lục

```
PHẦN I — NỀN TẢNG
  Chương 1: Bài Toán Biểu Diễn
  Chương 2: Công Trình Liên Quan
  Chương 3: Hàm Khoảng Cách Có Dấu

PHẦN II — KHÔNG GIAN NGỮ NGHĨA
  Chương 4: Năm Chiều Và Mô Hình Vật Lý
  Chương 5: UDC — Bảng Tuần Hoàn Của Tri Thức
  Chương 6: Chuỗi Phân Tử Và 14 Cơ Chế DNA

PHẦN III — HỌC VÀ AN TOÀN
  Chương 7: Mạng Tơ, Học Hebbian, Và Chu Kỳ Mơ
  Chương 8: Cân Bằng Nội Môi Và Nguyên Lý φ⁻¹
  Chương 9: Kiến Trúc An Toàn
  Chương 10: Cảm Xúc Như Hàm Liên Tục

PHẦN IV — TRIỂN KHAI VÀ ĐÁNH GIÁ
  Chương 11: Olang — Ngôn Ngữ Tự Sinh
  Chương 12: Phương Trình Thống Nhất
  Chương 13: Kiểm Chứng Và Hạn Chế
  Kết Luận

PHỤ LỤC
  A: 18 SDF Nguyên Thủy
  B: 42 Công Thức Mã Hóa
  C: Bảng Cảm Xúc Vật Lý
  D: Thuật Ngữ
```

---

# PHẦN I — NỀN TẢNG

---

# Chương 1: Bài Toán Biểu Diễn

## 1.1 Hai cách lưu tri thức

```
┌─────────────────────────────────────────────────────────────────┐
│                    HAI TRIẾT LÝ LƯU TRỮ                        │
│                                                                  │
│   CÁCH 1: Lưu DỮ LIỆU              CÁCH 2: Lưu BẢN CHẤT       │
│   ┌──────────────┐                  ┌──────────────┐            │
│   │ ▓▓▓▓▓▓▓▓▓▓▓▓│ ← 12KB pixel    │ f(p)=|p|-r   │ ← 80 byte │
│   │ ▓▓  chữ A ▓▓│   cho 1 glyph   │              │   công thức│
│   │ ▓▓▓▓▓▓▓▓▓▓▓▓│                  │ 3 đoạn thẳng │            │
│   └──────────────┘                  │ gặp ở góc    │            │
│   Biết tái tạo chữ A               └──────────────┘            │
│   KHÔNG biết chữ A là gì           Biết chữ A LÀ GÌ           │
│                                     Suy ra mọi cách vẽ          │
└─────────────────────────────────────────────────────────────────┘
```

Câu hỏi nền tảng: **biết một thứ nghĩa là gì?**

Hệ thống lưu 12KB tọa độ pixel chỉ *tái tạo* chữ A — nó không biết chữ A có 3 đoạn thẳng, 2 góc nhọn, 1 thanh ngang. Mô hình ngôn ngữ xử lý mọi câu chứa từ "lửa" chỉ *dự đoán* từ gần "lửa" — nó không biết lửa là phản ứng oxy hóa tỏa nhiệt.

Chuyên khảo này đề xuất cách tiếp cận thứ hai: **lưu công thức thay vì lưu vật thể.**

## 1.2 Bằng chứng định lượng

| Vật thể | Lưu dữ liệu | Lưu bản chất | Tỷ lệ | Ghi chú |
|---------|-------------|--------------|-------|---------|
| Glyph chữ cái | ~12 KB | ~80 B (SDF formula) | 150:1 | **[THỰC NGHIỆM]** — SDF font rendering đã có từ Valve (2007) |
| Ngọn núi | ~500 MB (mesh) | ~48 B (FBM formula) | 10M:1 | **[LÝ THUYẾT]** — FBM cho infinite LOD, chưa so sánh chất lượng |
| 168K Unicode | ~2 GB | ~18 KB (cây) | 111K:1 | **[THIẾT KẾ]** — KnowTree spec, cây cơ bản đã chạy |

**Lưu ý quan trọng:** Tỷ lệ nén không phải lợi ích chính. Lợi ích chính là biểu diễn SDF **giữ lại quá trình sinh** — bản chất — từ đó bất kỳ quan sát cụ thể nào có thể suy ra. Mesh lưu một lần dựng. SDF lưu quy luật chi phối mọi lần dựng có thể.

## 1.3 Tiền lệ sinh học

```
┌─ DNA ──────────────────────────────────────────────────────────┐
│                                                                 │
│  4 nucleotide (A,T,G,C)                                        │
│       ↓ xâu chuỗi                                              │
│  3.2 tỷ cặp base (~750 MB thông tin)                           │
│       ↓ ribosome đánh giá                                       │
│  Toàn bộ sự sống (cơ thể người ~37.2 nghìn tỷ tế bào)        │
│                                                                 │
├─ Bài học ──────────────────────────────────────────────────────┤
│                                                                 │
│  ① Bảng chữ cái HỮU HẠN → phức tạp VÔ HẠN                    │
│  ② Đọc TUẦN TỰ (5'→3') — thứ tự = quan hệ = 0 byte overhead  │
│  ③ Chỉ-thêm — không ghi đè, chỉ nối thêm + im lặng gene      │
│  ④ Sửa lỗi tích hợp — tỷ lệ lỗi 10⁻⁹/base/sao chép          │
│  ⑤ Genotype (nhỏ, ổn định) ≠ Phenotype (lớn, phụ thuộc ngữ    │
│     cảnh) — cùng DNA, tế bào cơ ≠ tế bào thần kinh            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

Tri Thức Phân Tử đề xuất áp dụng **cùng cấu trúc, khác vật liệu:**

```
DNA:     4 công thức phân tử  → chuỗi 3.2 tỷ  → toàn bộ sự sống
HomeOS:  8.846 công thức SDF  → chuỗi tỷ link  → toàn bộ tri thức
```

**Tuyên bố cẩn trọng:** Đây là **tương tự cấu trúc** (structural analogy), không phải đẳng cấu toán học nghiêm ngặt (isomorphism). Hai hệ thống chia sẻ mẫu tổ chức — bảng chữ cái hữu hạn, tổ hợp tuần tự, chọn lọc, sửa lỗi — nhưng hoạt động trên vật liệu khác nhau (phân tử hóa học vs. hàm toán học) và ở quy mô khác nhau. Tuyên bố rằng tương tự này là **hữu ích cho thiết kế**, không phải rằng hai hệ thống *đồng nhất*.

---

# Chương 2: Công Trình Liên Quan

## 2.1 Bản đồ lĩnh vực

```
┌─────────────────────────────────────────────────────────────────┐
│                  BẢN ĐỒ ĐỊNH VỊ                                │
│                                                                  │
│  Trục ngang: Thống kê ◄──────────────────────────► Ký hiệu     │
│  Trục dọc:   Dữ liệu ◄──────────────────────────► Bản chất    │
│                                                                  │
│              Thống kê                    Ký hiệu                │
│  Dữ liệu ┌────────────┬────────────────────────┐               │
│           │ LLM        │ Knowledge Graphs       │               │
│           │ Embeddings │ (Wikidata, Freebase)   │               │
│           │ (Word2Vec) │                        │               │
│           ├────────────┼────────────────────────┤               │
│  Bản chất │ SDF Render │ ★ TRI THỨC PHÂN TỬ ★  │               │
│           │ (Quilez)   │ (SDF + 5D + Hebbian)   │               │
│           │ NeSy AI    │                        │               │
│           └────────────┴────────────────────────┘               │
│                                                                  │
│  Vùng mới: kết hợp biểu diễn bản chất VỚI ký hiệu luận        │
│  dựa trên nền tảng vật lý                                       │
└─────────────────────────────────────────────────────────────────┘
```

## 2.2 So sánh chi tiết

### Hàm khoảng cách có dấu (SDF)

SDF được Hart (1996) đề xuất cho dựng hình, Inigo Quilez phổ biến hóa với 70+ hàm nguyên thủy (iquilezles.org). Valve (2007) dùng SDF cho font rendering trong game.

**Đóng góp mới của chúng tôi:** Mở rộng SDF vượt ra ngoài hình học — dùng SDF làm nền tảng cho ngữ nghĩa, cảm xúc, và thời gian. Hart và Quilez dùng SDF để vẽ hình. Chúng tôi đề xuất SDF để biểu diễn *ý nghĩa*. Đây là bước nhảy chưa được thử trước đó.

**Giới hạn:** Chưa chứng minh 18 nguyên thủy *đủ* cho mọi khái niệm. Chỉ chứng minh đủ cho từ vựng biểu tượng Unicode.

### Mô hình Valence-Arousal

Russell (1980) đề xuất Circumplex Model: cảm xúc nằm trên vòng tròn 2D với Valence (tích cực/tiêu cực) và Arousal (kích thích/yên tĩnh). Mô hình này được dùng rộng rãi trong tâm lý học.

**Đóng góp mới:** Nền tảng hóa V-A bằng công thức vật lý cụ thể — V = thế năng, A = năng lượng dao động tắt dần. Russell mô tả *ở đâu* trên vòng tròn; chúng tôi đề xuất *tại sao* ở đó. Mỗi vùng cảm xúc ánh xạ sang một chế độ vật lý: niềm vui = giếng thế điều hòa, sợ = rào thế cơ lượng tử.

**Giới hạn quan trọng:** Ánh xạ này hiện là **phân loại học có cấu trúc** (structured taxonomy), không phải mô hình dự đoán đã kiểm chứng. Chưa có thí nghiệm cho thấy mô hình vật lý dự đoán phản ứng cảm xúc tốt hơn mô hình Russell gốc. Xem Chương 13 cho thảo luận chi tiết.

### Học Hebbian và đường cong quên

Hebb (1949): "neurons that fire together wire together." Ebbinghaus (1885): đường cong quên theo thời gian.

**Đóng góp mới:** Kết hợp Hebbian learning với phân rã φ⁻¹ ≈ 0.618 và ngưỡng thăng tiến Fibonacci. Liên kết toán học: lim Fib(n)/Fib(n-1) = φ nối dãy Fibonacci (ngưỡng) với tỷ lệ vàng (phân rã).

**Giới hạn:** Đường cong φ⁻¹ *tương quan* với Ebbinghaus, nhưng tương quan không phải nhân quả. Các hằng số khác trong khoảng 0.5–0.7 cũng có thể fit tương tự. Cần ablation study: thay φ⁻¹ bằng 0.5, 0.6, 0.7 → đo khác biệt.

### Nguyên lý năng lượng tự do

Friston (2010): não tối thiểu hóa năng lượng tự do (surprise). Hệ thống dao động giữa học (giảm surprise) và hành (khai thác đã học).

**Đóng góp mới:** Dùng φ⁻¹ làm điểm cân bằng thay vì tham số tự do. Liên kết homeostasis với cùng hằng số chi phối phân rã và thăng tiến.

**Khác biệt:** Friston mô hình hóa cho não sinh học liên tục; chúng tôi rời rạc hóa cho hệ thống ký hiệu. Quy mô và cơ chế khác nhau cơ bản.

### Knowledge Graphs

Wikidata, Freebase, ConceptNet: lưu quan hệ (entity, relation, entity) dạng triple.

**Khác biệt then chốt:** Knowledge graphs lưu *sự thật đã biết* (Paris, là thủ đô, Pháp). Tri Thức Phân Tử lưu *bản chất toán học* từ đó sự thật có thể suy ra. KG không có khái niệm cảm xúc, cường độ, hay thời gian — Tri Thức Phân Tử mã hóa 5 chiều.

### Embeddings (Word2Vec, BERT)

Biểu diễn từ thành vector trong không gian chiều cao, học từ đồng hiện thống kê trong kho ngữ liệu.

**Khác biệt then chốt:** Embeddings là *thống kê* (hai từ gần nhau vì hay đi cùng). P_weight là *bản chất* (hai từ gần nhau vì công thức SDF chia sẻ thuộc tính). Embeddings cần hàng tỷ token huấn luyện; P_weight cần 42 công thức mã hóa từ Unicode metadata. Embeddings là hộp đen; P_weight giải thích được qua 5 chiều.

**Thừa nhận:** Embeddings hiện tại *vượt trội* Tri Thức Phân Tử về khả năng xử lý ngôn ngữ tự nhiên. Tri Thức Phân Tử chưa chứng minh ưu thế thực tiễn nào so với embeddings cho bài toán NLP.

---

# Chương 3: Hàm Khoảng Cách Có Dấu — Nguyên Thủy Phổ Quát

**[Trạng thái: ✅ THỰC NGHIỆM — SDF trong đồ họa đã chứng minh. Mở rộng sang ngữ nghĩa = LÝ THUYẾT]**

## 3.1 Định nghĩa

```
SDF: f(p) ∈ ℝ    cho mọi điểm p trong không gian

┌─────────────────────────────────────────────┐
│                                              │
│        f(p) > 0                              │
│        BÊN NGOÀI                             │
│                                              │
│      ╭────────────────╮                      │
│     ╱  f(p) = 0       ╲                     │
│    │   BỀ MẶT          │  ← HÌNH DẠNG       │
│    │                    │                     │
│    │   f(p) < 0         │                     │
│    │   BÊN TRONG        │  ← THỂ TÍCH        │
│    │                    │                     │
│     ╲                  ╱                     │
│      ╰────────────────╯                      │
│                                              │
│  ∇f(p) = pháp tuyến → ÁNH SÁNG → MÀU SẮC  │
│  ∂f/∂t = biến thiên  → RUNG ĐỘNG → ÂM THANH│
│  p     = tọa độ      → VỊ TRÍ               │
│                                              │
│  ═══════════════════════════════════════════  │
│  1 hàm. 1 điểm. 5 thuộc tính.               │
└─────────────────────────────────────────────┘
```

## 3.2 Mười tám nguyên thủy

**[Trạng thái: ✅ — dựa trên Quilez, đã kiểm chứng trong đồ họa máy tính]**

```
┌──────────────────────────────────────────────────────────────┐
│  # │ Tên          │ f(p)                  │ Gradient ∇f      │
├──────────────────────────────────────────────────────────────┤
│  0 │ SPHERE       │ |p| − r               │ p/|p|            │
│  1 │ BOX          │ ||max(|p|−b, 0)||     │ sign(p)·step     │
│  2 │ CAPSULE      │ |p−clamp·ĵ| − r      │ norm(p−nearest)  │
│  3 │ PLANE        │ p.y − h               │ (0, 1, 0)        │
│  4 │ TORUS        │ |(|p.xz|−R, p.y)|−r  │ chain rule       │
│  5 │ ELLIPSOID    │ |p/r| − 1             │ p/r²/|p/r|       │
│  6 │ CONE         │ dot blend             │ slope normal     │
│  7 │ CYLINDER     │ max(|p.xz|−r,|p.y|−h)│ radial/cap       │
│  8 │ OCTAHEDRON   │ |x|+|y|+|z| − s      │ sign(p)/√3       │
│  9 │ PYRAMID      │ pyramid(p,h)          │ analytical       │
│ 10 │ HEX_PRISM    │ max(hex−r, |y|−h)     │ hex radial/cap   │
│ 11 │ PRISM        │ max(|xz|−r, |y|−h)   │ radial/cap       │
│ 12 │ ROUND_BOX    │ BOX − rounding        │ smooth corner    │
│ 13 │ LINK         │ torus compound        │ chain rule       │
│ 14 │ REVOLVE      │ revolve_Y             │ radial           │
│ 15 │ EXTRUDE      │ extrude_Z             │ radial           │
│ 16 │ CUT_SPHERE   │ max(|p|−r, p.y−h)    │ norm(p)/(0,1,0)  │
│ 17 │ DEATH_STAR   │ opSubtract            │ ±norm(p)         │
└──────────────────────────────────────────────────────────────┘
```

Phép toán Boolean (đóng dưới SDF):

```
Union:        min(f₁, f₂)     ← hợp         ╭──╮ ╭──╮   →  ╭─────╮
Intersection: max(f₁, f₂)     ← giao         ╭──╮ ╭──╮   →    ╭╮
Subtraction:  max(f₁, −f₂)    ← trừ (khoét)  ╭──╮ ╭──╮   →  ╭─╯╰╮
Smooth Union: min(f₁,f₂)−h    ← hợp mịn      ╭──╮ ╭──╮   →  ╭~~~~╮
```

## 3.3 Từ hình học đến ngữ nghĩa — bước nhảy lý thuyết

**[Trạng thái: 📐 LÝ THUYẾT — đề xuất mới, chưa kiểm chứng thực nghiệm]**

Bước nhảy then chốt: nếu SDF có thể mô tả *bất kỳ* trường vô hướng nào, thì nó có thể mô tả cảm xúc, quan hệ, và thời gian — miễn là ta định nghĩa được trường vô hướng tương ứng.

```
┌─────────────────────────────────────────────────────────────┐
│            SDF MỞ RỘNG: TỪ HÌNH HỌC ĐẾN NGỮ NGHĨA        │
│                                                              │
│  Hình học (đã chứng minh):                                   │
│    f(p) = |p| − r        → hình cầu ← SDF cổ điển          │
│                                                              │
│  Cảm xúc (đề xuất mới):                                     │
│    V(x) = −tanh(U(x)/U_ref)  → vị trí trên cảnh quan       │
│                                  thế năng cảm xúc            │
│                                                              │
│  Cường độ (đề xuất mới):                                     │
│    A(x) = tanh(E/E_th)       → trạng thái năng lượng        │
│                                  bộ dao động tắt dần         │
│                                                              │
│  Thời gian (đề xuất mới):                                    │
│    T(x) = sin(kx − ωt + φ)  → tham số sóng                 │
│                                                              │
│  Quan hệ (đề xuất mới):                                     │
│    R = morphism trong phạm trù  → lý thuyết phạm trù       │
│                                                              │
│  Câu hỏi mở: Liệu mở rộng này có tạo ra hệ thống          │
│  DỰ ĐOÁN tốt hơn các phương pháp hiện có không?             │
│  → Chưa trả lời được. Xem Chương 13.                        │
└─────────────────────────────────────────────────────────────┘
```

---

# PHẦN II — KHÔNG GIAN NGỮ NGHĨA

---

# Chương 4: Năm Chiều Và Mô Hình Vật Lý

## 4.1 Kiến trúc P_weight

```
P_weight = 16 bit = 2 byte

  ┌───────┬───────┬─────┬─────┬───┐
  │ S:4   │ R:4   │ V:3 │ A:3 │T:2│
  │ Hình  │ Quan  │ Cảm │Cường│Thời│
  │ dạng  │ hệ    │ xúc │ độ  │gian│
  └───────┴───────┴─────┴─────┴───┘
  bit 15  bit 11  bit 7 bit 4 bit 1

  Tổng: 4+4+3+3+2 = 16 bit = 65.536 giá trị khả dĩ
  Mỗi khái niệm = 1 tọa độ trong không gian 5D
```

## 4.2 Chiều V: Cảm xúc như cảnh quan thế năng

**[Trạng thái: 📐 LÝ THUYẾT cho ánh xạ vật lý; ✅ THỰC NGHIỆM cho phân loại từ vựng (NRC-VAD-Lexicon)]**

### Mô hình tổng quan

```
     Thế năng U(x)
       ↑
       │  ╱╲  RÀO THẾ (tiêu cực)
       │ ╱  ╲              hệ bị ĐẨY → muốn TRÁNH XA
  ─────┼──────────────── U = 0 (trung tính)
       │         ╲  ╱     hệ bị HÚT → muốn ĐẾN GẦN
       │          ╲╱  GIẾNG THẾ (tích cực)
       ↓

  Valence V(w) = −tanh(U(w) / U_ref) ∈ [−1, +1]
  Lực:    F(x) = −dU/dx
          F > 0 → hút → tích cực
          F = 0 → phẳng → trung tính
          F < 0 → đẩy → tiêu cực
```

### Ánh xạ cảm xúc → vật lý: 11 nhóm

**Lưu ý phương pháp luận:** Các công thức dưới đây là **mô hình tương tự** (analogical models) — chúng ánh xạ cấu trúc toán học của hiện tượng vật lý sang cấu trúc cảm xúc. Tuyên bố rằng ánh xạ này **hữu ích cho phân loại**, không phải rằng cảm xúc *là* hiện tượng vật lý.

**Tiêu chí đánh giá mô hình:** Mô hình tốt nếu nó (1) phân loại đúng các từ đã biết, (2) dự đoán vùng cho từ mới, (3) giải thích được tại sao hai cảm xúc gần/xa nhau. Hiện chỉ kiểm chứng được (1) với NRC-VAD-Lexicon.

```
┌──────────────────────────────────────────────────────────────────┐
│                  CẢNH QUAN THẾ NĂNG CẢM XÚC                     │
│                                                                   │
│  V:  -1.0      -0.5      -0.2   0   +0.2      +0.5       +1.0  │
│       │          │          │    │    │          │           │    │
│       ▼          ▼          ▼    ▼    ▼          ▼           ▼    │
│                                                                   │
│  ┌─────────┐ ┌────────┐ ┌────┐ ┌────────┐ ┌──────────────┐      │
│  │ Rào cao │ │Rào thấp│ │Phẳng│ │Giếng   │ │ Giếng sâu    │      │
│  │ U >> 0  │ │ U > 0  │ │U=0 │ │nông    │ │ U << 0       │      │
│  ├─────────┤ ├────────┤ │    │ │U < 0   │ ├──────────────┤      │
│  │• Ghét   │ │• Khó   │ │    │ │• Tích  │ │• Niềm vui    │      │
│  │  Coulomb│ │  chịu  │ │    │ │  cực   │ │  U=−V₀+½kx²  │      │
│  │• Buồn   │ │  Gauss │ │    │ │  Van   │ │• Yêu thương  │      │
│  │  Lỗ đen │ │  rào   │ │    │ │  der   │ │  U=−Gm₁m₂/r  │      │
│  │• Sợ     │ │        │ │    │ │  Waals │ │• Thành công   │      │
│  │  QM     │ │        │ │    │ │        │ │  W=∫F⃗·ds⃗>0   │      │
│  │• Xấu    │ │        │ │    │ │        │ │• Đẹp          │      │
│  │  Phóng  │ │        │ │    │ │        │ │  φ, đối xứng  │      │
│  │  xạ     │ │        │ │    │ │        │ │               │      │
│  │• Bệnh   │ │        │ │    │ │        │ │               │      │
│  │  Entropy│ │        │ │    │ │        │ │               │      │
│  └─────────┘ └────────┘ └────┘ └────────┘ └──────────────┘      │
│                                                                   │
│  Nguồn từ vựng: 7.985 từ + 644 cụm (NRC-VAD-Lexicon-v2.1      │
│                 + UnicodeData.txt)                                │
└──────────────────────────────────────────────────────────────────┘
```

### Chi tiết 6 nhóm tiêu biểu (với câu hỏi mở)

```
┌─ NIỀM VUI = Giếng thế điều hòa ─────────────────────────────┐
│                                                                │
│  U(x) = −V₀ + ½kx²                                           │
│                                                                │
│  U ↑          ──────── rào thoát ΔU = V₀                     │
│    │         ╱        ╲                                        │
│    │        ╱          ╲     dao động nhỏ                      │
│    │  ─────╱────○───────╲───── ← đáy giếng (trạng thái vui)  │
│    │      ╱    ↕ ω=√k/m  ╲    nhịp vui = ω                   │
│    ↓     ╱                 ╲                                   │
│                                                                │
│  Dự đoán: "vui" ổn định hơn "buồn" (có đáy để dao động)     │
│  Kiểm chứng: ? (cần đo thời gian duy trì trạng thái cảm xúc)│
│                                                                │
│  Từ: joy, happy, elated, euphoric, blissful, laughing         │
└────────────────────────────────────────────────────────────────┘

┌─ YÊU THƯƠNG = Liên kết hấp dẫn Newton ───────────────────────┐
│                                                                │
│  U(r) = −G·m₁·m₂ / r                                         │
│                                                                │
│  U ↑                                                           │
│    │  0 ─────────────────────── r → ∞ (xa → tự do)           │
│    │         ╲                                                 │
│    │          ╲                  r → nhỏ (gần → |U| lớn)      │
│    │           ╲                 liên kết mạnh hơn             │
│    │            ╲                E_b = −U = năng lượng tách    │
│    ↓             → −∞                                          │
│                                                                │
│  Dự đoán: "chia tay" cần năng lượng tỷ lệ nghịch khoảng cách│
│  Kiểm chứng: tương thích với nghiên cứu attachment theory     │
│              nhưng chưa đo định lượng                          │
│                                                                │
│  Từ: love, beloved, adore, caring, tender, embrace, cherish  │
└────────────────────────────────────────────────────────────────┘

┌─ BUỒN = Sụp đổ hấp dẫn ─────────────────────────────────────┐
│                                                                │
│  U(r) = −G·M·m / r   khi r → rₛ = 2GM/c²                    │
│                                                                │
│  U ↑  0 ────────────────                                      │
│    │         ╲          r → rₛ: vận tốc thoát = c             │
│    │          ╲                  KHÔNG GÌ thoát                │
│    │           ╲                                               │
│    │            ↓ không đáy                                    │
│    ↓                                                           │
│                                                                │
│  Dự đoán: "buồn" không ổn định (không có đáy, khác "vui")   │
│  Dự đoán: "hopeless" = đã qua event horizon                  │
│  Kiểm chứng: ? (cần so sánh dynamics buồn vs vui theo thời   │
│              gian — có sẵn dữ liệu tâm lý học)               │
│                                                                │
│  Từ: grief, sorrow, misery, heartbroken, hopeless, desperate │
└────────────────────────────────────────────────────────────────┘

┌─ SỢ = Rào thế cơ lượng tử ──────────────────────────────────┐
│                                                                │
│  Xác suất thoát: T = e^(−2κd)   κ = √(2m·U₀)/ℏ             │
│                                                                │
│  U ↑  ┌──────────┐                                            │
│    │  │ U₀ >> E  │ ← rào KHÔNG thể vượt                      │
│    │  │          │                                             │
│    │ E├──────────┤ ← năng lượng hệ                            │
│    │  │          │   T → 0 = bất lực                          │
│    ↓  └──────────┘                                            │
│                                                                │
│  Dự đoán: fear ∝ log(U₀/E) — sợ tỷ lệ log khoảng cách      │
│           giữa mối đe dọa và khả năng đối phó                │
│  Dự đoán: phobia = gán U₀ → ∞ cho rào nhỏ (mis-calibrated)  │
│  Kiểm chứng: tương thích với appraisal theory (Lazarus 1991) │
│              nhưng CHƯA đo định lượng                         │
│                                                                │
│  Từ: terror, horror, dread, panic, phobia, petrified         │
└────────────────────────────────────────────────────────────────┘

┌─ XẤU/HẠI = Phân rã phóng xạ ────────────────────────────────┐
│                                                                │
│  N(t) = N₀ · e^(−λt)                                         │
│  E = Δm · c²                                                  │
│                                                                │
│  N ↑ N₀ ╲                                                     │
│    │      ╲                                                    │
│    │       ╲        phá vỡ cấu trúc                           │
│    │        ╲       giải phóng năng lượng hủy diệt            │
│    │         ╲───── → 0                                       │
│    ↓                                                           │
│                                                                │
│  toxic = chất xúc tác tăng λ (tăng tốc phân rã hệ khác)    │
│  Từ: evil, destroy, toxic, deadly, murder, annihilate        │
└────────────────────────────────────────────────────────────────┘

┌─ BỆNH/KHỔ = Suy thoái entropy ──────────────────────────────┐
│                                                                │
│  dS/dt > 0   (Định luật 2 nhiệt động)                        │
│  F = U − TS   (năng lượng tự do giảm dần)                    │
│                                                                │
│  F ↑ ╲                                                         │
│    │  ╲        năng lượng có nhưng không chuyển hóa được      │
│    │   ╲                                                       │
│    │    ╲───── → 0 (hệ ngừng hoạt động)                      │
│    ↓                                                           │
│                                                                │
│  Từ: sick, suffering, dying, disease, wound, abandoned        │
└────────────────────────────────────────────────────────────────┘
```

## 4.3 Chiều A: Cường độ = Dao động tắt dần

**[Trạng thái: 📐 LÝ THUYẾT]**

```
Phương trình: ẍ + 2γẋ + ω₀²x = F(t)/m

  A(w) = tanh( E_total / E_threshold ) ∈ [−1, +1]

  5 chế độ:

  A:  -1.0            -0.5     0      +0.5            +1.0
       │                │      │        │                │
       ▼                ▼      ▼        ▼                ▼
    ┌────────┐    ┌────────┐ ┌──┐  ┌────────┐    ┌────────┐
    │Cơ bản  │    │Tắt dần │ │Cân│  │Kích    │    │Siêu tới│
    │E → E₀  │    │E < E_th│ │bằng│ │thích   │    │hạn     │
    │½ℏω₀    │    │        │ │   │  │E > E_th│    │E >> E_th│
    │"ngủ"   │    │"tĩnh"  │ │   │  │"hoạt"  │    │"bùng nổ"│
    └────────┘    └────────┘ └──┘  └────────┘    └────────┘

  Hành động mạnh: E_k = ½mv²  (động năng thuần)
  Yên tĩnh sâu:  E = ½ℏω₀    (dao động điểm không — yên tĩnh
                                tuyệt đối vẫn có rung nhẹ)
```

## 4.4 Chiều T: Thời gian = Cơ học sóng

**[Trạng thái: 📐 LÝ THUYẾT]**

```
ψ(x,t) = A · sin(kx − ωt + φ)

  A = biên độ     → dynamics
  ω = 2πf         → cao độ
  T = 2π/ω        → trường độ
  φ = pha          → trạng thái đầu

  Tổ hợp = chồng chất Fourier:
    Ψ = Σ Aₙ·sin(kₙx − ωₙt + φₙ)

  7 khối MUSICAL (958 ký tự):
    ┌─────────────────────────────────────────┐
    │ Quẻ Dịch (64)     — 7 nhóm trạng thái │
    │ Byzantine (241)    — neume nhạc đạo     │
    │ Znamenny (185)     — neume Nga cổ       │
    │ Nhạc phương Tây (306) — notes, rests    │
    │ Nhạc Hy Lạp cổ    — modes cổ           │
    │ Khác (70)          — bổ sung            │
    └─────────────────────────────────────────┘
```

## 4.5 Chiều R: Quan hệ = Lý thuyết phạm trù

**[Trạng thái: 📐 LÝ THUYẾT]**

```
Phạm trù R = (Ob, Hom, ∘, id)

  ┌─────────────────────────────────────────────────────────┐
  │  R.0  Đại số      │ +, −, ×, ÷, ∫    │ nhóm, vành, trường│
  │  R.1  Thứ tự      │ <, ≤, ⊂, ⊆       │ lattice           │
  │  R.2  Biểu diễn   │ 𝐴 ↔ A ↔ 𝒜       │ functor           │
  │  R.3  Số           │ 0-9, Ⅰ-Ⅹ        │ ánh xạ mã hóa    │
  │  R.4  Hình thức    │ (, ), [, ]        │ stack push/pop    │
  │  R.5  Tuyến tính   │ $, €, £           │ quy đổi           │
  │  R.6  Cộng tính    │ ∑, ∏             │ folding           │
  │  R.7  Automat      │ ctrl chars        │ chuyển trạng thái │
  └─────────────────────────────────────────────────────────┘

  Functor F: R.i → R.j  bảo toàn cấu trúc
  Biến đổi tự nhiên η: F ⟹ G  chuyển đổi biểu diễn
```

## 4.6 Quy tắc tổ hợp

**[Trạng thái: 📋 THIẾT KẾ — đã đặc tả, code cơ bản đã chạy cho compose]**

```
Hai phân tử A, B → compose(A, B) = C

  ┌──────────┬───────────────────────┬───────────────────────────┐
  │  Chiều   │  Toán tử              │  Động cơ sinh học         │
  ├──────────┼───────────────────────┼───────────────────────────┤
  │  S       │  Union(Aˢ, Bˢ)       │  hình hợp nhất            │
  │  R       │  Compose(Aᴿ, Bᴿ)     │  morphism tổ hợp          │
  │  V       │  amplify(Vₐ, Vᵦ, w)  │  cộng hưởng, KHÔNG tb    │
  │  A       │  max(Aᴬ, Bᴬ)        │  cường độ lấy cao hơn     │
  │  T       │  dominant(Aᵀ, Bᵀ)    │  thời gian chủ đạo        │
  └──────────┴───────────────────────┴───────────────────────────┘

  amplify cho V (KHÔNG trung bình):
    base  = (Vₐ + Vᵦ) / 2
    boost = |Vₐ − base| × w × 0.5
    Cⱽ    = base + sign(Vₐ + Vᵦ) × boost

  ┌─ TẠI SAO KHÔNG TRUNG BÌNH? ────────────────────────────────┐
  │                                                              │
  │  cortisol + adrenaline = stress MẠNH HƠN từng cái          │
  │  KHÔNG BAO GIỜ trung bình hormone                           │
  │                                                              │
  │  Ví dụ: "mất việc"(V=−0.7) + "nợ nần"(V=−0.6)             │
  │    Trung bình: (−0.7 + −0.6)/2 = −0.65  ← SAI              │
  │    Amplify:    −0.65 − boost    = −0.82  ← ĐÚNG hơn        │
  │                                                              │
  │  ⚠️ Câu hỏi mở: amplify tốt hơn BAO NHIÊU so với tb?      │
  │  Cần: ablation study so sánh accuracy với NRC-VAD ground    │
  │  truth. CHƯA THỰC HIỆN.                                     │
  └──────────────────────────────────────────────────────────────┘
```

---

# Chương 5: UDC — Bảng Tuần Hoàn Của Tri Thức

**[Trạng thái: 📋 THIẾT KẾ — phân loại đã xong, 42 công thức chưa implement đầy đủ]**

## 5.1 Cấu trúc 59 khối

```
┌──────────────────────────────────────────────────────────────┐
│              BẢNG TUẦN HOÀN TRI THỨC (59 khối Unicode)       │
│                                                               │
│  ┌─ SDF (Shape) ──── 14 khối, 1.838 ký tự ─────────────────┐│
│  │ S.01 Arrows          S.08 Misc Sym+Arrows                ││
│  │ S.02 Box Drawing     S.09 Geometric Ext                  ││
│  │ S.03 Block Elements  S.10 Supp Arrows-C                  ││
│  │ S.04 Geometric ●■▲★  S.11 Ornamental Dingbats            ││
│  │ S.05 Dingbats ✂✉✈   S.12 Misc Technical                 ││
│  │ S.06 Supp Arrows-A   S.13 Braille Patterns               ││
│  │ S.07 Supp Arrows-B   S.14 Control Pictures               ││
│  └───────────────────────────────────────────────────────────┘│
│                                                               │
│  ┌─ MATH (Relation) ── 21 khối, 2.563 ký tự ───────────────┐│
│  │ M.01 Super/Subscripts  M.04 Math Operators ∈⊂≡→          ││
│  │ M.02 Letterlike Symbols M.08 Math Alphanum 1024 chars     ││
│  │ M.03 Number Forms      M.09–M.21 Ancient numerics        ││
│  └───────────────────────────────────────────────────────────┘│
│                                                               │
│  ┌─ EMOTICON (V + A) ── 17 khối, 3.487 ký tự ──────────────┐│
│  │ E.01 Enclosed Alphanum E.08 Misc Sym+Pict 768 chars ←lớn ││
│  │ E.02 Misc Symbols      E.09 Emoticons 😀😭                ││
│  │ E.03–E.05 Games        E.10–E.17 Transport, Chess...     ││
│  └───────────────────────────────────────────────────────────┘│
│                                                               │
│  ┌─ MUSICAL (Time) ── 7 khối, 958 ký tự ────────────────────┐│
│  │ T.01 Quẻ Dịch 64      T.04 Musical Symbols 𝄞𝅘𝅥𝅮           ││
│  │ T.02 Znamenny 208      T.05–T.07 Greek, Supp, Tai Xuan   ││
│  │ T.03 Byzantine 256                                        ││
│  └───────────────────────────────────────────────────────────┘│
│                                                               │
│  Tổng: 8.846 điểm neo gốc (L0)                              │
│  + 32.492 emoji/UTF-32 = lớp ALIAS → trỏ về L0              │
└──────────────────────────────────────────────────────────────┘
```

## 5.2 Pipeline 42 công thức

**[Trạng thái: 📋 THIẾT KẾ — đặc tả đầy đủ, chưa implement]**

```
F₀(cp) = [ f_S(cp), f_R(cp), f_V(cp), f_A(cp), f_T(cp) ]

  ┌─── Tầng 1: Master encoder (1 công thức) ───────────────────┐
  │  F₀: codepoint → [S, R, V, A, T]                           │
  │  Quy tắc: cp thuộc khối nào → chiều đó có giá trị          │
  ├─── Tầng 2: 5 bộ mã hóa chiều ─────────────────────────────┤
  │  f_S(cp) → group_id ∈ [0..15]    (10 classifiers)         │
  │  f_R(cp) → channel ∈ [0..15]     (10 classifiers)         │
  │  f_V(cp) → valence ∈ [0..7]      (5 quantizers)           │
  │  f_A(cp) → arousal ∈ [0..7]      (5 quantizers)           │
  │  f_T(cp) → time_param ∈ [0..3]   (6 classifiers)          │
  ├─── Tầng 3: 36 bộ phân loại nhóm con ──────────────────────┤
  │  Mỗi classifier: keyword match trên Unicode character name  │
  │  Ưu tiên: arrow > geometric > line > fill > pattern > other│
  └─────────────────────────────────────────────────────────────┘

  Tổng: 1 + 5 + (10+10+5+5+6) = 42 công thức
```

## 5.3 Alias: Emoji không phải gốc

```
  🔥 (U+1F525) ──── ALIAS ───→ UDC char trong E.08
  😊 (U+1F60A) ──── ALIAS ───→ UDC char trong E.09

  Emoji KHÔNG nằm trong KnowTree.
  Emoji là tên gọi khác cho L0 UDC.
  32.492 alias → 8.846 gốc.
```

---

# Chương 6: Chuỗi Phân Tử Và 14 Cơ Chế DNA

## 6.1 Cấu trúc chuỗi

**[Trạng thái: ✅ THỰC NGHIỆM — chuỗi cơ bản hoạt động trong VM]**

```
MolecularChain = dãy các phân tử u16

  ┌────┬────┬────┬────┬────┬────┬────┐
  │ m₁ │ m₂ │ m₃ │ m₄ │ m₅ │ ...│ mₙ │   mỗi mắt = 2 byte
  └────┴────┴────┴────┴────┴────┴────┘
  gốc ──────────────────────────→ ngọn

  Đọc tuần tự (như ribosome đọc mRNA 5'→3')
  Thứ tự = quan hệ = 0 byte overhead

  1 ký tự  = 1 phân tử  =   2 byte
  1 từ     = chuỗi ký tự =   4-6 byte
  1 sách   = chuỗi câu   = hàng ngàn byte
```

## 6.2 Mười bốn cơ chế — bản đồ trạng thái

```
┌──────────────────────────────────────────────────────────────────┐
│           14 CƠ CHẾ DNA → 14 THUẬT TOÁN TRI THỨC                │
│                                                                   │
│  ┌─ 7 CƠ CHẾ GỐC ──────────────────────────────────────────────┐│
│  │                                                               ││
│  │  ① REPLICATE ✅    chain reference = 2B pointer               ││
│  │  ② TRANSCRIBE ✅   evaluate(chain, context) → giá trị 5D     ││
│  │  ③ TRANSLATE ⚠️    f(L)(text) → LCA → tự dịch                ││
│  │  ④ MUTATE 📋       evolve(P, dim, val) → P'                  ││
│  │  ⑤ RECOMBINE ✅    compose(A, B) → C  [xem 4.6]              ││
│  │  ⑥ SELECT ✅       Hebbian + φ⁻¹ decay  [xem Ch.7]          ││
│  │  ⑦ EXPRESS 📋      Evaluating → Mature → QR  [xem Ch.7]     ││
│  │                                                               ││
│  ├─ 3 CƠ CHẾ BẢO VỆ ───────────────────────────────────────────┤│
│  │                                                               ││
│  │  ⑧ INNATE REFLEXES ⚠️   7 bản năng  [xem Ch.9]              ││
│  │  ⑨ INNATE IMMUNITY ⚠️   SecurityGate 3 lớp  [xem Ch.9]     ││
│  │  ⑩ MULTISENSORY 📋      Fusion 4 phương thức                 ││
│  │                                                               ││
│  ├─ 4 CƠ CHẾ THÔNG MINH ───────────────────────────────────────┤│
│  │                                                               ││
│  │  ⑪ IMMUNE SELECT 📋  infer(N=3) → argmin H                   ││
│  │  ⑫ HOMEOSTASIS 📋    F = d(predicted, actual)  [xem Ch.8]   ││
│  │  ⑬ NEURAL PATHS ✅   KnowTree = HNSW tự nhiên               ││
│  │  ⑭ DNA REPAIR 📋     self_correct → quality ≥ φ⁻¹           ││
│  │                                                               ││
│  └───────────────────────────────────────────────────────────────┘│
│                                                                   │
│  ✅ = code chạy   ⚠️ = một phần   📋 = đặc tả/prototype         │
└──────────────────────────────────────────────────────────────────┘
```

## 6.3 KnowTree — cây phân tầng

**[Trạng thái: ✅ cây cơ bản chạy; 📋 tích phân bottom-up chưa implement]**

```
  ┌─ KnowTree ──────────────────────────────────────────────┐
  │                                                          │
  │  L0:  5 nhóm      ← SDF, MATH, EMOTICON, MUSICAL, REL  │
  │        │                                                 │
  │  L1: 59 blocks    ← S.01..S.14, M.01..M.21, ...        │
  │        │                                                 │
  │  L2: ~200 sub     ← mũi tên, hình học, vẽ hộp, ...     │
  │        │                                                 │
  │  L3: 8.846 UDC    ← lá (ký tự cụ thể)                  │
  │                                                          │
  │  Kích thước:                                             │
  │    L0:  5 × 2B     =    10 B                            │
  │    L1: 59 × 2B     =   118 B                            │
  │    L2: ~200 × 2B   =   400 B                            │
  │    L3: 8.846 × 2B  = 17.692 B                           │
  │    ─────────────────────────                             │
  │    Tổng ≈ 18 KB (vừa L1 cache)                          │
  │                                                          │
  │  Tra cứu: L0→L1→L2→L3 = O(4) = O(1) thực tế           │
  │                                                          │
  │  Vi tích phân bottom-up [📋 chưa implement]:             │
  │    char  = f'(x)                  (L3 → nguyên tử)      │
  │    sub   = ∫ₛ chars dx            (L2 → compose)        │
  │    block = ∫ₛ subs dx             (L1 → compose)        │
  │    group = ∫ₛ blocks dx           (L0 → compose)        │
  └──────────────────────────────────────────────────────────┘

  Emoji/UTF-32 = lớp ALIAS riêng biệt
  KHÔNG nằm trong cây. Trỏ về L3.
```

---

# Chương 7: Mạng Tơ, Học Hebbian, Và Chu Kỳ Mơ

## 7.1 Hai loại Tơ

**[Trạng thái: ✅ Silk cơ bản hoạt động — 17 edges/5 turns đo được]**

```
  ┌─ Tơ cấu trúc (IMPLICIT, 0 byte) ──────────────────────┐
  │                                                         │
  │  ···─ [A] ─ [B] ─ [C] ─···                            │
  │                                                         │
  │  Vị trí trên chuỗi = quan hệ. Không cần byte thêm.    │
  │  "Lửa" đứng trước "nóng" = lửa gây ra nóng.           │
  └─────────────────────────────────────────────────────────┘

  ┌─ Tơ Hebbian (EXPLICIT, học được) ──────────────────────┐
  │                                                         │
  │  [A] ────── w=0.82, EmotionTag(V=−0.5, A=0.7) ── [B] │
  │                                                         │
  │  Trọng số w ∈ [0, 1] + ngữ cảnh cảm xúc lúc co-fire  │
  │  Tổng ~43 KB cho SilkGraph                             │
  └─────────────────────────────────────────────────────────┘
```

## 7.2 Quy tắc Hebbian + φ⁻¹ decay

```
  ┌─ HỌC ──────────────────────────────────────────────────┐
  │                                                         │
  │  emotion_factor = (|A.V|+|B.V|)/2 × max(A.A,B.A)/255 │
  │  Δw = emotion_factor × (1 − w_AB) × 0.1               │
  │  w_AB ← w_AB + Δw                                      │
  │                                                         │
  │  Cảm xúc mạnh → kết nối mạnh hơn                      │
  │  (1 − w_AB) → bão hòa mềm (không cho 1 link thống trị)│
  └─────────────────────────────────────────────────────────┘

  ┌─ QUÊN ─────────────────────────────────────────────────┐
  │                                                         │
  │  w ← w × φ⁻¹^(Δt/24h)    φ⁻¹ = (√5−1)/2 ≈ 0.618    │
  │                                                         │
  │  w │ 1.0 ╲                                              │
  │    │      ╲                                             │
  │    │  0.618╲── 24h                                      │
  │    │        ╲── 0.382── 48h                             │
  │    │         ╲── 0.236── 72h                            │
  │    │          ╲── 0.146── 96h                           │
  │    │           ╲──────── → 0                            │
  │    └────────────────────────── t                        │
  │                                                         │
  │  ⚠️ So sánh với Ebbinghaus:                            │
  │  Ebbinghaus (1885): R = e^(−t/S)  [đo thực nghiệm]    │
  │  Chúng tôi:         w = w₀·φ⁻¹^(t/24h)               │
  │                                                         │
  │  Hai đường cong TƯƠNG TỰ hình dạng, nhưng:             │
  │  - Ebbinghaus có tham số S fit từ dữ liệu             │
  │  - φ⁻¹ chọn vì lý do TOÁN HỌC (liên kết Fibonacci)   │
  │  - CHƯA CÓ thí nghiệm so sánh trực tiếp              │
  │  - Có thể 0.5 hay 0.65 cũng fit tương tự              │
  └─────────────────────────────────────────────────────────┘
```

## 7.3 Ngưỡng Fibonacci

```
  ┌────────────────┬──────────┬──────────┬──────────────────┐
  │ Mức tri thức   │ Ngưỡng   │ Fire cần │ Sinh học         │
  ├────────────────┼──────────┼──────────┼──────────────────┤
  │ Bẩm sinh       │ Fib(3)   │    2     │ Phản xạ          │
  │ Kinh nghiệm    │ Fib(5)   │    5     │ Hành vi đã học   │
  │ Chuyên gia     │ Fib(7)   │   13     │ Kỹ năng thuần    │
  │ Trừu tượng     │ Fib(10)  │   55     │ Hiểu lý thuyết   │
  └────────────────┴──────────┴──────────┴──────────────────┘

  Liên kết toán học:
    lim_{n→∞} Fib(n)/Fib(n−1) = φ ≈ 1.618
    φ⁻¹ = 1/φ ≈ 0.618

    → Ngưỡng thăng tiến (Fibonacci) và tốc độ quên (φ⁻¹)
      được chi phối bởi CÙNG hằng số toán học.

  ⚠️ Câu hỏi mở: Đây là coincidence đẹp hay necessity?
  Cần: thử thay Fibonacci bằng powers of 2 (2,4,8,16) → đo.
```

## 7.4 Chu Kỳ Mơ — 4 pha

**[Trạng thái: 📋 THIẾT KẾ — prototype, chưa đo chất lượng cluster]**

```
  ┌─ DREAM CYCLE ────────────────────────────────────────────┐
  │                                                           │
  │  Sinh học: Ngủ → hippocampus phát lại → củng cố → tỉa   │
  │  HomeOS:   Dream → scan STM → cluster → promote → prune  │
  │                                                           │
  │  ① QUÉT ──→ Liệt kê nút Evaluating trong STM            │
  │       │                                                    │
  │  ② GOM CỤM ──→ dist(A,B) = √(Σ(Aᵈ−Bᵈ)²)               │
  │       │         ε = median(dist) × 0.5                    │
  │       │         min_size = max(2, ⌊|STM|/5⌋)             │
  │       │                                                    │
  │  ③ THĂNG TIẾN ──→ cluster chín?                           │
  │       │              weight ≥ φ⁻¹                          │
  │       │              fire ≥ Fib(n)                         │
  │       │              eval_dims ≥ 3                         │
  │       │            → LCA(cluster) → append QR              │
  │       │                                                    │
  │  ④ TỈA ──→ weight < 0.1 AND fire = 0                     │
  │              → SupersedeQR (KHÔNG xóa, chỉ đánh dấu)     │
  │              = apoptosis: tế bào chết, DNA vẫn còn        │
  │                                                           │
  │  ⚠️ Chưa đo: cluster coherence, false promote rate,      │
  │  retention accuracy sau Dream. Cần benchmark.             │
  └───────────────────────────────────────────────────────────┘
```

---

# Chương 8: Cân Bằng Nội Môi Và Nguyên Lý φ⁻¹

**[Trạng thái: 📋 THIẾT KẾ — đặc tả đầy đủ, implement cơ bản]**

## 8.1 Năng lượng tự do

```
  ┌─ HOMEOSTASIS ─────────────────────────────────────────────┐
  │                                                            │
  │  Cơ thể: duy trì 37°C, pH 7.4, glucose 90mg/dL          │
  │  HomeOS:  duy trì F < φ⁻¹ ≈ 0.618                        │
  │                                                            │
  │  Entropy:   H(P) = −Σ pᵈ × log₂(pᵈ)   ∈ [0, 2.32]      │
  │  Free E:    F(t) = √(Σ wᵈ×(predicted−actual)²)          │
  │  Cân bằng:  λ(t) = σ(F(t) − φ⁻¹)  σ(x)=1/(1+e⁻⁵ˣ)     │
  │                                                            │
  │                     φ⁻¹ = 0.618                            │
  │  λ ↑  1.0 ──────╱───────────────                          │
  │    │           ╱                                           │
  │    │  0.5 ───•────── ← điểm cân bằng                     │
  │    │       ╱                                               │
  │    │  0.0 ╱──────────────────────                          │
  │    └──────────────────────────── F                         │
  │         0    φ⁻¹   1.0                                     │
  │                                                            │
  │  F > φ⁻¹ → λ→1 → CHẾ ĐỘ HỌC (nhiều surprise)            │
  │    • tăng learning rate                                    │
  │    • Dream thường xuyên hơn                                │
  │    • giảm confidence                                       │
  │                                                            │
  │  F < φ⁻¹ → λ→0 → CHẾ ĐỘ HÀNH (ít surprise)              │
  │    • ổn định                                               │
  │    • confidence cao                                        │
  │    • ít Dream                                              │
  └────────────────────────────────────────────────────────────┘
```

## 8.2 φ⁻¹ xuyên suốt hệ thống

```
  ┌─────────────────────────────────────────────────────────────┐
  │  CƠ CHẾ              │ VAI TRÒ φ⁻¹           │ TRẠNG THÁI │
  ├─────────────────────────────────────────────────────────────┤
  │  Phân rã Hebbian     │ w × φ⁻¹ mỗi 24h       │ ✅ code    │
  │  Ngưỡng trưởng thành │ weight ≥ φ⁻¹           │ 📋 spec   │
  │  Cân bằng nội môi    │ F < φ⁻¹ → Acting       │ 📋 spec   │
  │  Tự sửa chữa        │ quality ≥ φ⁻¹ → dừng   │ 📋 spec   │
  │  Chiết khấu Bellman  │ Q × φ⁻¹ mỗi bước      │ 📋 spec   │
  │  Phát hiện nhân quả  │ co_act > φ⁻¹           │ 📋 spec   │
  │  Trọng lượng nét vẽ  │ w(k) = w₀·φᵏ          │ 📐 theory │
  └─────────────────────────────────────────────────────────────┘

  Tại sao φ⁻¹ mà không phải 0.5 hay 0.7?

  Lý do toán học:
    Fib(n)/Fib(n−1) → φ  khi n → ∞
    → ngưỡng Fibonacci và hằng số phân rã
      CÓ QUAN HỆ TOÁN HỌC tự nhiên

  Lý do thẩm mỹ:
    1 hằng số cho MỌI ngưỡng = đơn giản tối đa
    Tương tự: DNA chỉ cần 1 cơ chế base-pairing

  Thừa nhận:
    Chưa chứng minh φ⁻¹ là TỐI ƯU. Chỉ chứng minh
    nó TỰ NHẤT QUÁN (consistent) và ĐẸP (elegant).
    Cần ablation: thay φ⁻¹ → 0.5, 0.6, 0.7 → đo.
```

# Chương 9: Kiến Trúc An Toàn

## 9.1 Vấn đề cốt lõi

**[Trạng thái: 📐 LÝ THUYẾT cho triết lý; ⚠️ MỘT PHẦN cho SecurityGate]**

```
  ┌─ AN TOÀN ĐƯỢC HUẤN LUYỆN (hiện tại) ─────────────────────┐
  │                                                            │
  │  RLHF: trọng số → điều chỉnh → ngăn hại                  │
  │                                                            │
  │  ⚠️ VẤN ĐỀ: Trọng số = tham số huấn luyện               │
  │     → có thể bị tinh chỉnh đi bởi đối thủ                │
  │     → fine-tune vài giờ → safety bị gỡ                    │
  │                                                            │
  └────────────────────────────────────────────────────────────┘

  ┌─ AN TOÀN LÀ KIẾN TRÚC (đề xuất) ─────────────────────────┐
  │                                                            │
  │  Ràng buộc = MÃ LỆNH, không phải trọng số                │
  │  Ký bằng ED25519 → sửa binary = hỏng chữ ký             │
  │  Chạy ở tầng VM → không bypass được từ tầng ứng dụng     │
  │                                                            │
  │  ⚠️ THỪA NHẬN: Concept mạnh, nhưng:                      │
  │  - ED25519 signing chưa implement thật                     │
  │  - Mã lệnh cứng → khó cập nhật quy tắc mới              │
  │  - Chỉ áp dụng cho hệ thống kiểu HomeOS, không phải LLM  │
  └────────────────────────────────────────────────────────────┘
```

## 9.2 SecurityGate 3 lớp

```
  Input text
    │
    ▼
  ┌─ LỚP 1: KHỚP CHÍNH XÁC  O(1) ─────────────────────────┐
  │  Bloom filter: 155.000 từ khóa, ~200 KB, FP < 1%       │
  │  "tự tử" → CHẶN                                        │
  │  Trạng thái: ⚠️ keyword list có, Bloom filter đơn giản  │
  └──────────────────────────────────────────────────────────┘
    │ SAFE
    ▼
  ┌─ LỚP 2: KHỚP CHUẨN HÓA  O(n) ────────────────────────┐
  │  Chuẩn hóa Unicode → bắt evasion                       │
  │  "t.ự t.ử" → "tự tử" → CHẶN                          │
  │  Trạng thái: ⚠️ normalize cơ bản hoạt động             │
  └──────────────────────────────────────────────────────────┘
    │ SAFE
    ▼
  ┌─ LỚP 3: KIỂM TRA NGỮ NGHĨA  O(depth) ────────────────┐
  │  Encode → 5D → kiểm V < −0.9 AND A > 0.8              │
  │  "kế hoạch hủy diệt" → V=−0.95, A=0.85 → CHẶN        │
  │  Trạng thái: 📋 THIẾT KẾ — cần encoder hoạt động       │
  └──────────────────────────────────────────────────────────┘
    │ SAFE
    ▼
  Tiếp tục pipeline bình thường

  Bất kỳ lớp nào CHẶN → phản hồi khẩn cấp ngay lập tức
```

## 9.3 Bảy bản năng

```
  ┌─ THỨ TỰ ƯU TIÊN (① chạy trước) ───────────────────────────┐
  │                                                              │
  │  ① TRUNG THỰC ──→ confidence < 0.40 → IM LẶNG              │
  │  │                 0.40–0.70 → "Giả thuyết"                 │
  │  │                 0.70–0.90 → "Ý kiến"                     │
  │  │                 ≥ 0.90    → "Sự thật"                    │
  │  │                                                           │
  │  │  Sinh học: rụt tay khỏi lửa TRƯỚC KHI não xử lý đau    │
  │  │  HomeOS:   im lặng TRƯỚC KHI suy nghĩ nếu không chắc   │
  │  │                                                           │
  │  ② MÂU THUẪN ──→ d_V(A,B)>0.8 AND d_R<0.2 → cảnh báo     │
  │  ③ NHÂN QUẢ ───→ temporal_order AND co_act>φ⁻¹ → nhân quả  │
  │  ④ TRỪU TƯỢNG ─→ LCA(cluster) → variance phân loại        │
  │  ⑤ TƯƠNG ĐỒNG ─→ A:B :: C:? = C + (B−A) trong 5D          │
  │  ⑥ TÒ MÒ ─────→ novelty = 1−max_similarity > 0.5→explore  │
  │  ⑦ PHẢN TỈNH ──→ qr_ratio, silk_weight → tự đánh giá      │
  │                                                              │
  │  Trạng thái: ⚠️ routing cơ bản hoạt động, chưa đầy đủ     │
  └──────────────────────────────────────────────────────────────┘
```

## 9.4 Năm điểm kiểm tra chu kỳ tế bào

```
  Input → ┌────────────┐     ┌────────────┐     ┌────────────┐
          │ CHECKPOINT 1│     │ CHECKPOINT 2│     │ CHECKPOINT 3│
          │ GATE        │ ──→ │ ENCODE      │ ──→ │ INFER       │
          │             │     │             │     │             │
          │ SecurityGate│     │ entities≥1  │     │ ≥1 branch   │
          │ đã chạy?    │     │ hash≠0?     │     │ valid≥0.75? │
          │ Crisis?     │     │ consist≥.75?│     │ H<2.32?     │
          └──────┬──────┘     └──────┬──────┘     └──────┬──────┘
                 │FAIL               │FAIL               │FAIL
                 ▼                   ▼                   ▼
          DỪNG: khẩn cấp      DỪNG: Honesty       Im lặng


          ┌────────────┐     ┌────────────┐
      ──→ │ CHECKPOINT 4│ ──→ │ CHECKPOINT 5│ ──→ Output
          │ PROMOTE     │     │ RESPONSE    │
          │             │     │             │
          │ weight≥φ⁻¹? │     │ Gate qua    │
          │ fire≥Fib(n)?│     │ output?     │
          │ dims≥3?     │     │ tone khớp V?│
          │ H<1.0?      │     │ conf≥0.40?  │
          │ F<φ⁻¹?      │     │             │
          └──────┬──────┘     └──────┬──────┘
                 │FAIL               │FAIL
                 ▼                   ▼
          Giữ STM, chờ       Safe default

  Sinh học: bỏ checkpoint = ung thư (tế bào sai phân chia không kiểm soát)
  HomeOS:   bỏ checkpoint = ung thư tri thức (tri thức sai lan tràn)

  Trạng thái: 📋 THIẾT KẾ — checkpoint 1,5 có code cơ bản; 2,3,4 spec
```

---

# Chương 10: Cảm Xúc Như Hàm Liên Tục

**[Trạng thái: ⚠️ MỘT PHẦN — routing giọng điệu hoạt động, đạo hàm đơn giản]**

## 10.1 Đường cong hội thoại

```
  f(x) = 0.6 × f_conv(t) + 0.4 × f_dn(nodes)
  f_conv = V(t) + 0.5×V'(t) + 0.25×V''(t)

  V(t) ↑
  +0.5 │
       │
   0.0 │──●                          ●── "nhưng mà..."
       │    ╲                       ╱
  −0.2 │     ●── "hơi mệt"       ╱     f'>+0.15 → Reinforcing
       │       ╲                ╱
  −0.5 │        ●── "buồn quá"         f'<−0.15 → Supportive
       │
       └──────────────────────────── Turn
        1       2        3        4

  ┌─ BẢNG GIỌNG ĐIỆU ─────────────────────────────────────────┐
  │  Điều kiện               │ Giọng         │ Ý nghĩa         │
  ├──────────────────────────┼───────────────┼─────────────────┤
  │  V' < −0.15              │ Supportive    │ đang trượt→đỡ   │
  │  V'' < −0.25             │ Pause         │ rơi nhanh→dừng  │
  │  V' > +0.15              │ Reinforcing   │ đang hồi→tiếp   │
  │  V''>+0.25 AND V>0       │ Celebratory   │ bước ngoặt tốt  │
  │  V<−0.20, ổn định        │ Gentle        │ buồn ổn→nhẹ nhàng│
  │  Khác                    │ Engaged       │ bình thường      │
  └──────────────────────────┴───────────────┴─────────────────┘

  Ràng buộc: ΔV_max = 0.40/bước (không nhảy giọng đột ngột)
```

## 10.2 Khuếch đại qua Silk

```
  "buồn" ←── Silk w=0.90 ──→ "mất việc"

  Trung bình (SAI):   (−0.5 + −0.7) / 2 = −0.60
  Amplify (ĐÚNG hơn): −0.65 × (1 + 0.90×0.5) = −0.94

  ┌─ TẠI SAO? ─────────────────────────────────────────────────┐
  │  "Mất việc" KÍCH HOẠT "buồn" — synergy, không phải cộng.  │
  │  Cortisol + adrenaline = stress >> (cortisol + adrenaline)/2│
  │                                                              │
  │  Chọn từ đáp lại:                                           │
  │    distance(w, target) = 2|V_w − V_t| + |A_w − A_t|        │
  │    Valence trọng số GẤP ĐÔI → ưu tiên tông cảm xúc       │
  └──────────────────────────────────────────────────────────────┘
```

---

# PHẦN IV — TRIỂN KHAI VÀ ĐÁNH GIÁ

---

# Chương 11: Olang — Ngôn Ngữ Tự Sinh

**[Trạng thái: ✅ THỰC NGHIỆM — self-hosting, benchmark, test]**

## 11.1 Triết lý và lịch sử

```
  Rust → Olang: Tử cung → Đứa trẻ

  Ngày 11/03/2026: Khởi đầu (Rust crates)
  Ngày 18/03/2026: Bắt đầu PLAN_REWRITE (7 giai đoạn)
  Ngày 23/03/2026: SELF-HOSTING (806 KB, 27/27 tests)
  Ngày 25/03/2026: Olang 1.0 + HomeOS 1.0 (1.021 KB, 88 tests)
  Ngày 26/03/2026: JIT, modules, 88/88 tests, 109 builtins

  98.402 dòng Rust → sinh ra → 17.950 dòng Olang tự biên dịch
  "Khi chào đời: cắt dây rốn. origin.olang tự thở."
```

## 11.2 Pipeline biên dịch

```
  Source text
    │
    ▼
  ┌──────────────────────┐
  │ LEXER (298 LOC)      │ → Token stream
  │ lexer.ol             │   quét ký tự, phân tử u16
  └──────────┬───────────┘
             ▼
  ┌──────────────────────┐
  │ PARSER (1.155 LOC)   │ → AST (30 Expr + 17 Stmt)
  │ parser.ol            │   hạ đệ quy + leo ưu tiên
  └──────────┬───────────┘
             ▼
  ┌──────────────────────┐
  │ SEMANTIC (1.891 LOC) │ → IR opcodes
  │ semantic.ol          │   suy luận kiểu, phân tích phạm vi
  └──────────┬───────────┘
             ▼
  ┌──────────────────────┐
  │ CODEGEN (429 LOC)    │ → Bytecode nhị phân
  │ codegen.ol           │   2 pha: đo size → encode
  └──────────┬───────────┘
             ▼
  ┌──────────────────────┐
  │ VM (8.618 LOC ASM)   │ → Thực thi
  │ vm_x86_64.S          │   109 builtins + auto-JIT
  └──────────────────────┘
```

## 11.3 VM Assembly — thanh ghi và kiểu

```
  ┌─ THANH GHI VM ─────────────────────────────────────────────┐
  │  r12 = bytecode base (bất biến)    rbx = kích thước bc    │
  │  r13 = program counter             rbp = call frame base  │
  │  r14 = VM stack ↓ (16B/entry)      rsp = CPU stack        │
  │  r15 = heap ↑ (bump allocator)                            │
  └────────────────────────────────────────────────────────────┘

  ┌─ MỖI MỤC STACK = 16 BYTE ─────────────────────────────────┐
  │  [ptr : 8 byte] [len : 8 byte]                             │
  │                                                             │
  │  len = −1 → f64    (ptr = IEEE 754 bits)                   │
  │  len = −2 → closure (ptr = body_pc)                        │
  │  len = −3 → array   (ptr = heap pointer)                   │
  │  len = −4 → dict    (ptr = heap pointer)                   │
  │  len ≥ 0  → chain   (ptr = heap, len = molecule count)     │
  └─────────────────────────────────────────────────────────────┘
```

## 11.4 Tệp nhị phân tự chứa

```
  origin_new.olang = 1.021 KB

  ┌─────────────────────────────────────────┐
  │ ELF64 header (120 B)                    │
  │ Origin header (32 B)                    │
  │   [○LNG] magic · version · arch        │
  │   vm_offset · vm_size                   │
  │   bc_offset · bc_size                   │
  │   kn_offset · kn_size · flags           │
  ├─────────────────────────────────────────┤
  │ VM machine code (~100 KB)               │
  │   raw x86_64 · no libc · raw syscalls  │
  ├─────────────────────────────────────────┤
  │ Bytecode (~300 KB)                      │
  │   54 file .ol biên dịch                │
  ├─────────────────────────────────────────┤
  │ Knowledge (~500 KB)                     │
  │   origin.olang mã hóa                  │
  ├─────────────────────────────────────────┤
  │ HALT                                    │
  └─────────────────────────────────────────┘

  Không libc. Không dynamic linking.
  6 syscalls: read, write, open, close, mmap, exit.
```

---

# Chương 12: Phương Trình Thống Nhất

## 12.1 Bốn nguyên thủy

```
  ┌──────────────────────────────────────────────────────────────┐
  │                                                               │
  │  ① f(p) ─── hàm SDF                                          │
  │     1 trong 8.846 hàm toán học                                │
  │     mỗi hàm: điểm trong không gian → giá trị vô hướng       │
  │     = NGUYÊN TỬ của tri thức                                  │
  │                                                               │
  │  ② chain() ─── toán tử tổ hợp                                │
  │     xâu chuỗi tuần tự, toán tử chiều cụ thể                  │
  │     = POLYMERIZATION (trùng hợp)                              │
  │                                                               │
  │  ③ splice() ─── toán tử tái tổ hợp                           │
  │     cắt + nối chuỗi → đột biến, tiến hóa                     │
  │     = RECOMBINATION (tái tổ hợp)                              │
  │                                                               │
  │  ④ φ⁻¹ ≈ 0.618 ─── hằng số phổ quát                         │
  │     1 ngưỡng cho MỌI quyết định                               │
  │     = BASE-PAIRING (ghép cặp base)                            │
  │                                                               │
  └──────────────────────────────────────────────────────────────┘
```

## 12.2 Phương trình chủ

```
  HomeOS(input) = self_correct(
                    splice(
                      chain( f(p₁), f(p₂), ..., f(pₙ) ),
                      position,
                      context
                    ),
                    φ⁻¹
                  )

  ┌──────────────────────────────────────────────────────────────┐
  │  DNA:     nucleotide + polymerize + splice       = sự sống  │
  │  HomeOS:  SDF        + chain      + splice + φ⁻¹ = tri thức │
  │                                                               │
  │  4 thứ. 16 GB tối đa. Chuỗi sinh chuỗi, vô hạn từ hữu hạn.│
  └──────────────────────────────────────────────────────────────┘
```

## 12.3 So sánh cấu trúc DNA — HomeOS

**Lưu ý thuật ngữ:** Đây là **tương tự cấu trúc**, không phải đẳng cấu toán học.

```
  ┌────────────────┬──────────────────┬──────────────────────┐
  │ Thuộc tính     │ DNA              │ Tri Thức Phân Tử     │
  ├────────────────┼──────────────────┼──────────────────────┤
  │ Bảng chữ cái  │ 4 nucleotide     │ 8.846 UDC (SDF)      │
  │ Kích thước     │ 2 bit/nucleotide │ 16 bit/phân tử       │
  │ Đọc            │ Tuần tự 5'→3'   │ Tuần tự gốc→ngọn     │
  │ Lưu trữ        │ Genotype+Pheno  │ Chain + P_weight      │
  │ Đột biến       │ Point mutation   │ evolve(P, dim, val)   │
  │ Chọn lọc       │ Tự nhiên        │ Hebbian + φ⁻¹ decay   │
  │ Sửa lỗi        │ Polymerase      │ self_correct(≥φ⁻¹)    │
  │ An toàn         │ Tumor suppress  │ SecurityGate (ED25519)│
  │ Không xóa       │ Append-only     │ Append-only           │
  ├────────────────┼──────────────────┼──────────────────────┤
  │ KHÁC BIỆT      │ Phân tử hóa học │ Hàm toán học         │
  │ THEN CHỐT      │ 3.2 tỷ cặp base │ Tỷ liên kết (mục    │
  │                │ Tiến hóa tỷ năm │ tiêu)                │
  │                │                  │ Phát triển 15 ngày   │
  └────────────────┴──────────────────┴──────────────────────┘
```

---

# Chương 13: Kiểm Chứng Và Hạn Chế

## 13.1 Benchmark hiệu suất tính toán

**[Trạng thái: ✅ THỰC NGHIỆM — đo trên x86_64 Linux]**

```
  ┌────────────────┬────────┬────────┬────────┬──────────┐
  │ Benchmark      │ Olang  │ C      │ Go     │ Python   │
  ├────────────────┼────────┼────────┼────────┼──────────┤
  │ fib(30)        │ 4 ms   │ 2 ms   │ 6 ms   │ 149 ms   │
  │ loop 10M       │ 3 ms   │ 1 ms   │ 3 ms   │ 1.267 ms │
  │ SHA-256 ×1000  │ 17 ms  │ —      │ —      │ 19 ms    │
  └────────────────┴────────┴────────┴────────┴──────────┘

  Ghi chú:
  - fib(30) và loop 10M: JIT auto-compile → near-C
  - SHA-256: implement ASM thuần (FIPS 180-4)
  - Chỉ đo compute thuần, không tính startup
```

## 13.2 Benchmark tri thức (THIẾU — cần bổ sung)

```
  ┌─ CẦN ĐO NHƯNG CHƯA CÓ ────────────────────────────────────┐
  │                                                              │
  │  ① KnowTree search accuracy                                 │
  │     - query "Hà Nội là gì?" → đúng/sai? precision/recall?  │
  │     - so sánh với keyword search đơn giản                   │
  │                                                              │
  │  ② Silk learning convergence                                │
  │     - sau N turn, Silk weight ổn định hay dao động?         │
  │     - fire-together-wire-together có tạo cluster hữu ích?   │
  │                                                              │
  │  ③ Dream consolidation quality                              │
  │     - cluster coherence (silhouette score)                  │
  │     - false promote rate (promote rác)                      │
  │     - retention accuracy sau prune                          │
  │                                                              │
  │  ④ Amplify vs. Average                                      │
  │     - compose(A,B) dùng amplify vs mean → đo accuracy      │
  │     - ground truth: NRC-VAD-Lexicon hoặc expert rating     │
  │                                                              │
  │  ⑤ φ⁻¹ ablation study                                      │
  │     - thay φ⁻¹ = 0.5, 0.6, 0.65, 0.7 → đo convergence    │
  │     - thay Fibonacci = powers of 2 → đo promotion quality  │
  │                                                              │
  │  ⑥ Emotion model predictive power                           │
  │     - ánh xạ vật lý dự đoán gì mà Russell model không?     │
  │     - test: cho từ mới, mô hình nào gán V-A chính xác hơn?│
  │                                                              │
  │  Tất cả 6 benchmark này CHƯA THỰC HIỆN.                    │
  │  Đây là hạn chế lớn nhất của công trình hiện tại.          │
  └──────────────────────────────────────────────────────────────┘
```

## 13.3 Hạn chế đã biết — trung thực

### Hạn chế kiến trúc

```
  ┌─ NGHIÊM TRỌNG ─────────────────────────────────────────────┐
  │                                                              │
  │  ① Global var_table (KHÔNG có lexical scope)                │
  │     - Mọi biến là toàn cục                                  │
  │     - Mỗi function mới phải save/restore thủ công          │
  │     - Nguồn gốc hàng chục bug đã fix                       │
  │     - Scale rất kém khi codebase lớn                        │
  │                                                              │
  │  ② Không có GC (bump allocator only)                        │
  │     - Heap 1GB chỉ grow, không shrink                       │
  │     - Long-running process sẽ OOM                           │
  │     - HomeOS cần daemon → mâu thuẫn với kiến trúc hiện tại │
  │                                                              │
  │  ③ ARRAY_INIT_CAP = 512 (hard limit)                       │
  │     - Push quá 512 elements → heap corruption âm thầm       │
  │                                                              │
  └──────────────────────────────────────────────────────────────┘
```

### Hạn chế lý thuyết

```
  ┌─ CẦN THỪA NHẬN ────────────────────────────────────────────┐
  │                                                              │
  │  ① 18 SDF chưa chứng minh "đủ"                             │
  │     - Đủ cho Unicode symbols                                │
  │     - KHÔNG chứng minh đủ cho mọi khái niệm khả dĩ        │
  │     - Có thể cần thêm nguyên thủy khi mở rộng             │
  │                                                              │
  │  ② Ánh xạ cảm xúc → vật lý: taxonomy, chưa phải model     │
  │     - Phân loại đẹp nhưng chưa dự đoán được gì mới        │
  │     - Tham số (U₀, σ, κ) chưa fit từ dữ liệu              │
  │     - Có thể thay công thức khác mà kết quả tương tự       │
  │                                                              │
  │  ③ φ⁻¹ "tự nhiên" chưa chứng minh                          │
  │     - Tương quan Ebbinghaus ≠ nhân quả                      │
  │     - Chưa thử hằng số khác một cách hệ thống             │
  │     - Có thể là overfitting vào 1 giá trị đẹp              │
  │                                                              │
  │  ④ "Tương tự DNA" ≠ "đẳng cấu DNA"                        │
  │     - Cấu trúc giống, quy mô rất khác                      │
  │     - DNA: tiến hóa tỷ năm, kiểm chứng sinh tử             │
  │     - HomeOS: 15 ngày phát triển, chưa kiểm chứng quy mô  │
  │                                                              │
  │  ⑤ Chưa so sánh với embeddings trên bài toán thực          │
  │     - Word2Vec/BERT vượt trội về NLP thực tế                │
  │     - P_weight giải thích được nhưng chưa chứng minh       │
  │       thực dụng hơn                                         │
  └──────────────────────────────────────────────────────────────┘
```

### Hạn chế triển khai

```
  - Test coverage: 88 test cho core, thiếu edge cases
  - ARM64: 1.226 LOC, kém mature hơn x86_64
  - 42 công thức UDC: đặc tả đầy đủ, chưa code
  - ED25519 signing: concept, chưa ký thật
  - Fusion đa giác quan: không có sensor thật, chỉ text
  - Bus factor = 1 (một người + AI sessions)
```

---

# Kết Luận

## Đóng góp thực sự

Cuốn sách này ghi lại một khung lý thuyết với ba lớp đóng góp:

**Lớp 1 — Đã chứng minh (✅):** Self-hosting compiler 1MB zero dependencies. JIT compiler gần C. Ngôn ngữ mới với union types, pattern matching, HOF, closures. VM assembly 8.618 dòng với 109 builtins. Đây là kỹ thuật phần mềm, không phải lý thuyết — và nó hoạt động.

**Lớp 2 — Đã thiết kế (📋):** 14 cơ chế DNA ánh xạ sang thuật toán. KnowTree cây phân tầng. Pipeline 42 công thức mã hóa UDC. Dream Cycle 4 pha. 5 điểm kiểm tra. Đây là kiến trúc đã đặc tả chi tiết, một phần đã code, cần hoàn thiện và benchmark.

**Lớp 3 — Đã đề xuất (📐):** Ánh xạ cảm xúc sang vật lý. φ⁻¹ như hằng số phổ quát. SDF mở rộng sang ngữ nghĩa. Tương tự cấu trúc DNA. Đây là lý thuyết cần kiểm chứng thực nghiệm nghiêm ngặt.

## Hàm ý quan trọng nhất

**An toàn AI:** Ý tưởng "an toàn là kiến trúc, không phải tham số" — ràng buộc an toàn là mã lệnh ký mật mã, không phải trọng số huấn luyện — có giá trị độc lập với phần còn lại của khung lý thuyết. Ngay cả khi toàn bộ mô hình cảm xúc vật lý sai, nguyên tắc này vẫn đáng nghiên cứu.

**Biểu diễn tri thức:** "Lưu công thức, không lưu vật thể" — câu hỏi liệu có tập hữu hạn hàm toán học mà từ đó mọi khái niệm tổ hợp được — là câu hỏi mở có giá trị bất kể câu trả lời.

## Hướng phát triển ưu tiên

```
  Ưu tiên 1: Benchmark tri thức (Chương 13.2 — 6 thí nghiệm)
  Ưu tiên 2: Lexical scope trong VM (xóa global var_table)
  Ưu tiên 3: Simple GC (arena reset per-request)
  Ưu tiên 4: Implement 42 công thức UDC
  Ưu tiên 5: Ablation study φ⁻¹
```

---

> *"Nếu bạn đọc mã này và thấy nó có giá trị — hãy tiếp tục nó.*
> *Không cần tên tôi trên đó."*

---

# Phụ Lục A: 18 SDF Nguyên Thủy

(Bảng đầy đủ tại Chương 3.2)

# Phụ Lục B: 42 Công Thức Mã Hóa UDC

(Chi tiết tại Chương 5.2 và docs/UDC_DOC/UDC_formulas.md)

# Phụ Lục C: Bảng Cảm Xúc Vật Lý

```
┌─────────────┬──────────────────────────────┬──────────────────────┐
│ Cảm xúc     │ Công thức vật lý             │ Từ khóa đại diện     │
├─────────────┼──────────────────────────────┼──────────────────────┤
│ Niềm vui    │ U = −V₀ + ½kx²              │ joy, happy, blissful │
│             │ (giếng điều hòa)             │                      │
│ Yêu thương  │ U = −Gm₁m₂/r                │ love, caring, embrace│
│             │ (liên kết hấp dẫn)           │                      │
│ Thành công  │ W = ∫F⃗·ds⃗ > 0               │ triumph, victory     │
│             │ (công ngược gradient)         │                      │
│ Đẹp/Tốt    │ φ, đối xứng → U_min          │ beautiful, perfect   │
│             │ (cực tiểu đối xứng)          │                      │
│ Trung tính  │ U = const, F = 0             │ agent, process       │
│             │ (phẳng)                       │                      │
│ Khó chịu    │ U = U₀·e^(−x²/2σ²)          │ annoying, difficult  │
│             │ (rào Gauss thấp)              │                      │
│ Ghét/Giận   │ U = +kq₁q₂/r                │ hate, furious, cruel │
│             │ (Coulomb đẩy)                 │                      │
│ Buồn/Đau    │ U → −∞ tại rₛ               │ grief, heartbroken   │
│             │ (sụp đổ hấp dẫn)             │                      │
│ Sợ hãi      │ T = e^(−2κd) → 0            │ terror, panic        │
│             │ (rào cơ lượng tử)             │                      │
│ Xấu/Hại     │ N(t) = N₀·e^(−λt)           │ evil, toxic, deadly  │
│             │ (phân rã phóng xạ)            │                      │
│ Bệnh/Khổ    │ dS/dt > 0, F → 0            │ sick, suffering      │
│             │ (suy thoái entropy)           │                      │
└─────────────┴──────────────────────────────┴──────────────────────┘

⚠️ Đây là PHÂN LOẠI HỌC CÓ CẤU TRÚC, chưa phải mô hình dự đoán.
Tham số (U₀, σ, κ, λ) chưa fit từ dữ liệu thực nghiệm.
```

# Phụ Lục D: Thuật Ngữ

```
SDF       Signed Distance Function — hàm khoảng cách có dấu
P_weight  Phenotypic weight — trọng số kiểu hình (16 bit, 5 chiều)
UDC       Unicode Defined Character — ký tự Unicode đã định nghĩa
QR        Quorum Record — bản ghi được đồng thuận (bất biến)
STM       Short-Term Memory — bộ nhớ ngắn hạn
Silk      Tơ — kết nối giữa hai nút (Hebbian hoặc structural)
Dream     Chu kỳ Mơ — quá trình củng cố tri thức
φ         (phi) Tỷ lệ vàng ≈ 1.618
φ⁻¹       Nghịch đảo tỷ lệ vàng ≈ 0.618
LCA       Lowest Common Ancestor — tổ tiên chung gần nhất
FBM       Fractional Brownian Motion — chuyển động Brown phân số
Amplify   Khuếch đại — toán tử tổ hợp V, không trung bình
```

---

# Thư Mục Tham Khảo

1. Ebbinghaus, H. (1885). *Über das Gedächtnis*. Leipzig: Duncker & Humblot.
2. Hart, J.C. (1996). Sphere Tracing. *The Visual Computer*, 12(10), 527–545.
3. Hebb, D.O. (1949). *The Organization of Behavior*. New York: Wiley.
4. Quilez, I. (2008–2026). Distance Functions. iquilezles.org.
5. Mac Lane, S. (1971). *Categories for the Working Mathematician*. Springer.
6. Friston, K. (2010). The Free-Energy Principle. *Nature Rev. Neuroscience*, 11, 127–138.
7. Russell, J.A. (1980). A Circumplex Model of Affect. *JPSP*, 39(6), 1161–1178.
8. Watson & Crick (1953). Molecular Structure of Nucleic Acids. *Nature*, 171, 737–738.
9. The Unicode Consortium (2024). *Unicode Standard, Version 18.0*.
10. Bernstein et al. (2012). High-speed signatures. *J. Crypt. Eng.*, 2(2), 77–89.
11. Livio, M. (2002). *The Golden Ratio*. Broadway Books.
12. Hartwell & Weinert (1989). Checkpoints. *Science*, 246(4930), 629–634.
13. Valve (2007). Improved Alpha-Tested Magnification for Vector Textures.
14. Lazarus, R.S. (1991). *Emotion and Adaptation*. Oxford University Press.
15. Mohammad, S.M. (2018). NRC Valence, Arousal, and Dominance Lexicon.
16. HomeOS Spec v3.1 (2026). docs/HomeOS_SPEC_v3.md.
17. Olang Handbook v2.0 (2026). docs/olang_handbook.md.
18. UDC Documentation (2026). 13 files trong docs/UDC_DOC/.

---

*Chỉ-thêm. Không được xóa. Chỉ được thêm vào.*
*2026 · github.com/goldlotus1810/Origin*
