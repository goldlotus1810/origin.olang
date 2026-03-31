# NOX COMPLETE REFERENCE — Toàn Bộ Thuật Toán + Nghiên Cứu Nền Tảng

> ★★★ NGUYÊN TẮC: Encode = ∫ (TÍCH PHÂN). Decode = ∂ (VI PHÂN). TÍNH, không TRA. ★★★
>
> Tài liệu này tổng hợp: Spec A-G + UDC 13 files + Nghiên cứu học thuật + Roadmap
> Mục đích: Ai đọc file này = hiểu TOÀN BỘ hệ thống, biết TỪNG thuật toán, biết NGUỒN GỐC
> Ngày bắt đầu: 2026-03-31 Session 13
> Tác giả: Nox (tổng hợp từ Lupin's specs + academic research)

---

## MỤC LỤC

```
PHẦN I: NỀN TẢNG TOÁN HỌC
  1. SDF — Signed Distance Field (S dimension)
  2. Relation Logic (R dimension)  
  3. Valence — Circumplex Model (V dimension)
  4. Arousal — Harmonic Oscillator (A dimension)
  5. Time — Spline + Wave (T dimension)
  6. P_weight: 42 Formulas tính 5D từ Unicode
  7. Compose ∫: Tích phân rời rạc
  8. Distance: Metric spaces trong 5D

PHẦN II: CẤU TRÚC DỮ LIỆU
  9. Chain: Chuỗi DNA tri thức
  10. KnowTree: Cây phân nhóm ngữ nghĩa
  11. Silk: 9,200 loại kết nối
  12. QR: Tri thức đã chứng minh
  13. STM/WM: Bộ nhớ ngắn hạn + làm việc

PHẦN III: THUẬT TOÁN HỌC
  14. Hebbian Learning: Fire together → wire together
  15. Decay: φ⁻¹ forgetting curve
  16. Dream: Consolidation + Cross-group resonance
  17. Homeostasis: Free Energy Principle (Friston)
  18. Immune Selection: Multi-hypothesis
  19. DNA Repair: Bounded self-correction

PHẦN IV: PIPELINE XỬ LÝ
  20. SecurityGate: 3 tầng, toán thuần
  21. 7 Instincts: 7 formulas trên 5D
  22. Pipeline 14 bước, 5 checkpoints
  23. ConversationCurve: V'(t), V''(t)
  24. Generation: Chain recombination (SINH)

PHẦN V: SEARCH + CLASSIFICATION  
  25. Nearest Neighbor trong 5D
  26. VP-Tree / KD-Tree / HNSW
  27. Silk Walk: Graph traversal có hướng
  28. Clustering / Self-Organizing Maps
  29. Bellman Equation cho search tối ưu

PHẦN VI: AGENT + SELF-EVOLUTION
  30. Agent Cycle: Perceive → Think → Act → Verify
  31. Self-Model: Knowledge map
  32. Goal System: Curiosity-driven
  33. Self-Evolution: 6-phase cycle
  34. Persistence: 3-tier storage

PHẦN VII: NGHIÊN CỨU NỀN TẢNG
  35. Russell 1980: Circumplex Model of Affect
  36. NRC-VAD: Best-Worst Scaling (Mohammad 2018)
  37. ANEW: Bradley & Lang
  38. Friston: Free Energy Principle
  39. Hebb 1949: Organization of Behavior
  40. Collins & Loftus 1975: Spreading Activation
  41. Shannon 1948: Information Theory
  42. Fibonacci / φ trong tự nhiên + tối ưu
  43. SDF Rendering: Valve 2007, msdfgen
  44. HNSW: Malkov & Yashunin 2018
  45. Unicode Standard: Chapter 2, 4 (Properties)

PHẦN VIII: IMPLEMENTATION (Olang)
  46. VM x86_64: Architecture, registers, opcodes
  47. Compiler: Lexer → Parser → Semantic → Codegen
  48. Self-Hosting: Fixed-point verification
  49. Current Status + Roadmap
```

---

# PHẦN I: NỀN TẢNG TOÁN HỌC

---

## 1. S — Shape / Signed Distance Field

### 1.1 Định nghĩa SDF

```
f(p) = signed distance from point p to surface

f(p) < 0  → bên trong → THỂ TÍCH
f(p) = 0  → trên bề mặt → HÌNH DẠNG  
f(p) > 0  → bên ngoài → KHÔNG GIAN
∇f(p)     → gradient → PHÁP TUYẾN → ÁNH SÁNG → MÀU SẮC
∂f/∂t     → biến thiên → DAO ĐỘNG → ÂM THANH
```

### 1.2 18 SDF Primitives (Nguồn: Inigo Quilez, shadertoy.com)

```
SPHERE:      f(p) = |p| - r
BOX:         f(p) = max(|p| - b, 0)
CAPSULE:     f(p) = |p - clamp(y,0,h)ĵ| - r
PLANE:       f(p) = p.y - h
TORUS:       f(p) = |(|p.xz|-R, p.y)| - r
ELLIPSOID:   f(p) = (|p/r| - 1) · min(r)
CONE:        f(p) = dot-blend
CYLINDER:    f(p) = max(|p.xz|-r, |p.y|-h)
OCTAHEDRON:  f(p) = (|x|+|y|+|z| - s) · (1/√3)

Boolean operations:
  Union:      min(f₁, f₂)
  Intersect:  max(f₁, f₂)
  Subtract:   max(f₁, -f₂)
  Smooth:     smin(f₁, f₂, k)  where smin(a,b,k) = -ln(e^(-ka)+e^(-kb))/k
```

### 1.3 SDF từ Unicode Glyph (Nguồn: Valve 2007, Green 2007)

```
Thuật toán: Dead Reckoning (Grevera 2004)
  1. Rasterize glyph vào bitmap NxN
  2. Với mỗi pixel p:
     d(p) = min distance to edge (boundary between ink/no-ink)
     sign = -1 if inside, +1 if outside
     sdf(p) = sign × d(p)
  3. Normalize: sdf_norm = clamp(sdf / max_dist, -1, 1)
  
Exact Euclidean Distance Transform (Felzenszwalb & Huttenlocher 2012):
  O(n) per row/column, O(n²) total
  Uses parabolic envelope intersection

Shape complexity từ SDF:
  S_value = perimeter² / (4π × area)  — isoperimetric ratio
  Circle = 1.0 (simplest), Star = high (complex)
  4-bit: S = clamp(floor(complexity × 15), 0, 15)
```

**Nghiên cứu:**
- Valve 2007: "Improved Alpha-Tested Magnification for Vector Textures"
- Green 2007: "Improved Alpha-Tested Magnification for Vector Textures and Special Effects"  
- Grevera 2004: "The Dead Reckoning signed distance transform"
- Felzenszwalb & Huttenlocher 2012: "Distance Transforms of Sampled Functions"
- Inigo Quilez: https://iquilezles.org/articles/distfunctions/

### 1.4 10 Sub-classifiers cho S (Nguồn: UDC_S0..S3_S7_tree.md)

```
S.0  ARROW:     618 cụm, τ×δ×ω×φ×λ ∈ Z₈×Z₁₁×Z₄×Z₄×Z₅ = 7,040 combinations
                Physics: F⃗(x,y) = ||v⃗||·ê(θ)·ρ(x,y)
S.1  GEOMETRIC: 321 cụm, σ×φ×μ×ξ ∈ Z₁₀×Z₆×Z₅×Z₆
                SDF: circle, square, triangle, diamond, star, cross, ellipse, flower
S.2  BOX:       128 cụm, κ×ω×γ ∈ Z₆×Z₄×Z₉
                Topology: C = (c_U,c_D,c_L,c_R) ∈ {0,1}⁴
S.3  FILL:      Block elements, shade, quadrant
S.4  SYMBOL:    Keyboard, technical, misc  
S.5  SIZE:      small/medium/large/heavy/light modifier
S.6  POSITION:  upper/lower/left/right/turned modifier
S.7  PATTERN:   Braille β ∈ {0,1}⁸ (256 patterns)
S.8  ASTRO:     Planet symbols
S.9  TECHNICAL: APL α×m ∈ Z₁₈×Z₆, dentistry, benzene

Unicode blocks cho S:
  U+2190..21FF  Arrows (192)
  U+25A0..25FF  Geometric Shapes (96)
  U+2500..257F  Box Drawing (128)
  U+2580..259F  Block Elements (32)
  U+2800..28FF  Braille (256)
  U+2700..27BF  Dingbats (192)
  U+2300..23FF  Misc Technical (256)
  + 6 supplementary blocks
```

---

## 2. R — Relation / Mathematical Role

### 2.1 Unicode General_Category (Nguồn: Unicode Standard Ch.4)

```
Category quyết định R:
  Lu (Uppercase Letter)    → R.4 (letter_script)
  Ll (Lowercase Letter)    → R.4
  Nd (Decimal Digit)       → R.3 (number)
  Sm (Math Symbol)         → R.0 (operator)
  So (Other Symbol)        → context-dependent
  Pc/Pd/Pe/Pf/Pi/Po/Ps    → R.6 (punctuation)
  Sc (Currency Symbol)     → R.7 (currency)
  Mn (Combining Mark)      → modifier (affects parent)
  Cc (Control)             → R.9 (formatting)

Category COMPUTABLE cho ASCII (0-127):
  33-47:  punctuation (Sm/Po)
  48-57:  digits (Nd)
  65-90:  uppercase (Lu)
  97-122: lowercase (Ll)

Category cho Unicode mở rộng:
  Đọc UnicodeData.txt field 2 (1 lần tại bootstrap)
  Hoặc: dùng block range heuristic (93% accurate cho common scripts)
```

### 2.2 10 Sub-classifiers cho R (Nguồn: UDC_R_RELATION_tree.md)

```
R.0  OPERATOR:    +−×÷∫∑∏ — arithmetic, calculus
                  Nguồn: OpenMath classification, MathML operator dictionary
R.1  SET_LOGIC:   ∈⊂∪∩∀∃ — set theory, first-order logic
R.2  COMPARISON:  =≈≤≥≠∼ — equivalence, ordering
R.3  NUMBER:      0-9, Ⅰ-Ⅻ, ①-⑳ — decimal, roman, enclosed
R.4  LETTER:      𝐀𝑨𝔄𝔸 — mathematical alphanumeric
R.5  FRACTION:    ½⅓¼⅛ — vulgar fractions
R.6  PUNCTUATION: ‐…‹›«» — structural markers
R.7  CURRENCY:    $€£¥₿₹ — monetary
R.8  ANCIENT:     𐄂𒐕 — cuneiform, acrophonic numerals
R.9  FORMATTING:  ␀␍ — control, format characters

Unicode blocks cho R:
  U+2200..22FF  Mathematical Operators (256)
  U+2100..214F  Letterlike Symbols (80)
  U+1D400..1D7FF Mathematical Alphanumeric (512)
  U+20A0..20CF  Currency (32)
  U+2000..206F  General Punctuation (112)
```

### 2.3 Relation Types trong Knowledge Representation

```
WordNet relations (Miller 1995, Princeton):
  Hypernym:  "dog" IS-A "animal"           → R silk type
  Hyponym:   "animal" HAS-KIND "dog"       → R silk type
  Meronym:   "wheel" PART-OF "car"         → R silk type  
  Synonym:   "big" SAME-AS "large"         → R silk type
  Antonym:   "big" OPPOSITE "small"        → V silk type (valence contrast)

OWL/RDF relation types:
  rdf:type, rdfs:subClassOf, owl:sameAs, owl:differentFrom
  
Mapping to R dimension:
  is-a / type-of     → R=10 (taxonomic)
  part-of / has-part  → R=8 (mereological)
  cause-of            → R=12 (causal)
  similar-to          → R=6 (analogical)
  opposite-of         → R=2 (contrastive)
```

**Nghiên cứu:**
- Miller 1995: "WordNet: A Lexical Database for English"
- Fellbaum 1998: "WordNet: An Electronic Lexical Database"
- Unicode Standard Chapter 4: Character Properties
- MathML Operator Dictionary: w3.org/TR/MathML3/appendixc.html

---

## 3. V — Valence / Emotional Polarity

### 3.1 Russell's Circumplex Model (1980)

```
2D circular space:
  X axis = Valence (pleasure ↔ displeasure)  
  Y axis = Arousal (activation ↔ deactivation)

Mọi trạng thái cảm xúc = 1 điểm (V, A) trong vòng tròn này.

Ví dụ vị trí:
  Happy:     V=+0.8, A=+0.3  (positive, mildly active)
  Excited:   V=+0.5, A=+0.8  (positive, very active)  
  Calm:      V=+0.3, A=-0.5  (mildly positive, inactive)
  Sad:       V=-0.6, A=-0.3  (negative, mildly inactive)
  Angry:     V=-0.5, A=+0.8  (negative, very active)
  Afraid:    V=-0.7, A=+0.6  (negative, active)
```

**Paper gốc:** Russell, J.A. (1980). "A circumplex model of affect." Journal of Personality and Social Psychology, 39(6), 1161-1178.

### 3.2 NRC-VAD Methodology (Mohammad 2018)

```
Best-Worst Scaling:
  1. Cho 4 từ: "love", "hate", "table", "run"
  2. Hỏi: "Từ nào MOST associated với pleasure? Từ nào LEAST?"
  3. 778,085 cặp best-worst responses
  4. Tính score: score(w) = (times_best - times_worst) / total_annotations
  5. Normalize to [0, 1]

Kết quả: 20,000 → 55,000 English words với V, A, D scores
Reliability: split-half correlation r = 0.95 (rất cao)
```

**Paper:** Mohammad, S.M. (2018). "Obtaining Reliable Human Ratings of Valence, Arousal, and Dominance for 20,000 English Words." ACL 2018.

### 3.3 Quantization V: continuous → discrete

```
raw ∈ [-1.0, +1.0] → V ∈ [0..7]

quantize(raw) = clamp(round((raw + 1.0) / 2.0 × 7), 0, 7)

  raw = -1.0  →  V = 0  (rất tiêu cực: hate, horror)
  raw = -0.5  →  V = 2  (tiêu cực: sad, worried)
  raw =  0.0  →  V = 4  (trung tính: table, walk)
  raw = +0.5  →  V = 5  (tích cực: happy, good)
  raw = +1.0  →  V = 7  (rất tích cực: love, joy)
```

### 3.4 Physics Model cho V (Nguồn: UDC_V_VALENCE_tree.md)

```
V = potential energy well model:

Tích cực (attractive well):
  Joy:     U = -V₀ + ½kx²           (harmonic well — stable, oscillating)
  Love:    U = -Gm₁m₂/r             (gravitational — deep binding)
  Success: W = ∫F⃗·ds⃗ > 0           (positive work against field)
  Beauty:  φ = (1+√5)/2              (golden ratio symmetry)

Tiêu cực (repulsive barrier):
  Hate:    U = +kq₁q₂/r             (Coulomb repulsion)
  Sadness: U → -∞ at r_s             (collapse, singularity)
  Fear:    T = e^(-2κd) → 0          (tunneling blocked — barrier too high)
  Harm:    N(t) = N₀·e^(-λt)         (radioactive decay — degradation)

V(w) = -U(w) / U_max ∈ [-1, +1]
```

### 3.5 TÍNH V không cần lookup table

```
Phương pháp 1: Từ Unicode block position
  Emoticon blocks organized: positive → negative gradient
  V = f(offset_in_block / block_size)

Phương pháp 2: Từ word-level compose (∫)
  Mỗi char = V neutral. Word meaning = compose(chars) + context(silk).
  "love" = l(V=4) + o(V=4) + v(V=4) + e(V=4) = V=4 at char level.
  Silk connections from experience: "love" co-occurs with positive context → V tăng.
  SAU ĐỦ trải nghiệm, silk walk "love" → positive nodes → V effective > 4.

Phương pháp 3: Transformer-based (Gmendes 2023)
  Fine-tune multilingual BERT → predict V/A continuous
  Correlation ρ=0.98 với ground truth (NRC-VAD)
  Nhưng cần GPU, model lớn — không phù hợp Nox 949KB.

→ Nox dùng: Phương pháp 2 (compose + silk) + NRC-VAD bootstrap cho cold start.
  Khi silk đủ mạnh → NRC-VAD thừa → bỏ.
```

**Nghiên cứu thêm:**
- Bradley & Lang (1999): ANEW — Affective Norms for English Words
- Warriner et al. (2013): ANEW expanded to 13,915 words
- Novak et al. (2015): "Sentiment of Emojis"
- Rodrigues et al. (2018): "Emoji sentiment scores"
- Gmendes et al. (2023): "Quantifying V/A with Multilingual Transformers"

---

## 4. A — Arousal / Activation Level

### 4.1 Arousal trong Circumplex Model

```
Arousal = energy level, activation:
  A = +1.0: extreme excitement (rage, ecstasy, panic)
  A = +0.5: alert, tense, excited
  A =  0.0: neutral (content, pensive)
  A = -0.5: calm, relaxed, serene
  A = -1.0: extreme calm (sleepy, lethargic, bored)
```

### 4.2 Physics Model (Nguồn: UDC_A_AROUSAL_tree.md)

```
Damped Harmonic Oscillator:
  ẍ + 2γẋ + ω₀²x = F(t)/m

5 chế độ → 5 mức A:

A=7 (extreme):    E >> E_threshold
                   Free particle: E_k = ½mv² (pure kinetic)
                   
A=5-6 (high):     Excited states: E_n = E₀ + n·ΔE
                   Quantum: n > 0 (discrete energy levels above ground)
                   
A=3-4 (neutral):  Gibbs equilibrium: ΔG = ΔH - TΔS = 0
                   Boltzmann: P(E) = e^(-E/kT) / Z
                   
A=1-2 (calm):     Overdamped: x(t) = (C₁+C₂t)·e^(-γt), γ > ω₀
                   No oscillation, monotonic return to equilibrium
                   
A=0 (very calm):  Ground state: E₀ = ½ℏω₀
                   Zero-point energy, cannot go lower (Heisenberg)

Arousal(w) = tanh((E_kinetic + E_potential) / E_threshold)
```

### 4.3 TÍNH A từ text features (không cần lookup)

```
Text-level heuristics (computable):
  Exclamation marks (!)     → A += 2
  ALL CAPS                  → A += 1
  Question marks (?)        → A += 1
  Short sentences           → A += 1 (urgent)
  Long sentences            → A -= 1 (calm, explanatory)
  Repetition ("nooooo")     → A += 1
  
Character-level:
  ! (U+0021) → A=6 (high energy punctuation)
  ? (U+003F) → A=5 (questioning energy)
  . (U+002E) → A=2 (calm termination)
  , (U+002C) → A=3 (pause, moderate)
  
Audio-level (future):
  RMS energy     → A direct mapping
  Zero-crossing  → pitch → A correlation
  Speech rate    → fast = high A, slow = low A
```

---

## 5. T — Time / Temporal / Spline

### 5.1 T dimension values

```
T = 0: Static     (hexagram state, no motion)
T = 1: Slow       (whole note, fermata, rest)  
T = 2: Medium     (quarter note, walking pace)
T = 3: Fast       (eighth note, dynamics, rapid change)
```

### 5.2 Wave/Spline representation

```
Superposition of waves:
  ψ(x,t) = Σ Aₙ·sin(kₙx - ωₙt + φₙ)·wₙ(t)

Each musical character = one term in superposition:
  λ (duration)    → wavelength → T.0
  ν (pitch)       → frequency  → T.1
  dB (dynamics)   → amplitude  → T.2
  contour (neume) → shape      → T.3
  phase (hexagram)→ state      → T.4
  modulation      → envelope   → T.5
```

### 5.3 6 Sub-classifiers cho T (Nguồn: UDC_T_TIME_tree.md)

```
T.0 NOTE_DURATION:  Western whole/half/quarter/eighth/sixteenth
T.1 PITCH_SCALE:    Clef, key signature, sharp/flat
T.2 DYNAMICS:       pp, p, mp, mf, f, ff, crescendo, decrescendo
T.3 NEUME:          Byzantine/Gregorian melodic contour
T.4 HEXAGRAM:       I Ching 64 states (6 hào × âm/dương)
                    Tai Xuan Jing 81 tetragrams (4 hào × 3 values)
T.5 MODIFIER:       Trill, vibrato, fermata, ornament

Unicode blocks cho T:
  U+1D100..1D1FF  Musical Symbols (256)
  U+1D000..1D0FF  Byzantine Musical (256)
  U+1D200..1D24F  Ancient Greek Musical (80)
  U+4DC0..4DFF    Yijing Hexagrams (64)
```

---

## 6. P_weight: 42 Formulas

### 6.1 Architecture

```
Tầng 1 — Master (1 formula):
  F₀(cp) = [f_S(cp), f_R(cp), f_V(cp), f_A(cp), f_T(cp)]

Tầng 2 — 5 Dimension Encoders:
  f_S(cp) → S ∈ [0..15]    from 13 SDF blocks
  f_R(cp) → R ∈ [0..15]    from 18 MATH blocks  
  f_V(cp) → V ∈ [0..7]     from 15 EMOTICON blocks
  f_A(cp) → A ∈ [0..7]     from 15 EMOTICON blocks (shared)
  f_T(cp) → T ∈ [0..3]     from 7 MUSICAL blocks

Tầng 3 — 36 Sub-classifiers:
  S: 10 (arrow, geometric, line, fill, symbol, size, position, pattern, astro, technical)
  R: 10 (operator, set_logic, comparison, number, letter, fraction, punctuation, currency, ancient, formatting)
  V: 5 quantizers (very_positive, positive, neutral, negative, very_negative)
  A: 5 quantizers (very_excited, excited, moderate, calm, very_calm)
  T: 6 (note_duration, pitch_scale, dynamics, neume, hexagram, modifier)

TỔNG: 1 + 5 + 36 = 42
```

### 6.2 Cách TÍNH (không tra bảng)

```
Bước 1: Xác định block membership
  if cp ∈ [0x2190..0x27BF, 0x2B00..0x2BFF, 0x1F780..0x1F8FF]: → SDF block → compute S
  if cp ∈ [0x2200..0x22FF, 0x2100..0x214F, 0x1D400..0x1D7FF]: → MATH block → compute R
  if cp ∈ [0x1F300..0x1F9FF, 0x2600..0x26FF]:                  → EMOTICON block → compute V, A
  if cp ∈ [0x1D000..0x1D24F, 0x4DC0..0x4DFF]:                  → MUSICAL block → compute T
  else: basic character → compute from category

Bước 2: Cho mỗi dimension
  S: SDF complexity = perimeter²/(4π×area) của glyph
  R: General_Category → role mapping
  V: block offset gradient + NRC-VAD bootstrap + silk learned
  A: character energy + block offset + silk learned
  T: musical block classifier

Bước 3: Pack
  P_weight = (S << 12) | (R << 8) | (V << 5) | (A << 2) | T
```

---

## 7. Compose ∫ — Tích Phân Rời Rạc

### 7.1 Định nghĩa

```
Giống Riemann sum: chia input thành N phần, tính mỗi phần, tổ hợp.

compose(a, b):
  S = max(S_a, S_b)                               — Union (SDF boolean)
  R = (R_a × w_a + R_b × w_b) / (w_a + w_b)     — Zipf-weighted average
  V = amplify(V_a, V_b, silk_w)                    — Amplification (NOT average)
  A = max(A_a, A_b)                               — Maximum intensity
  T = dominant(T_a, T_b)                           — Majority vote

Zipf weighting:
  w_i = 1000 / (i + 1)
  Phần tử đầu tiên nặng nhất. "Tôi yêu bạn" → "Tôi" nặng nhất.
  Non-commutative: "AB" ≠ "BA" vì w₁ > w₂.

Amplify (NOT average):
  base = (V_a + V_b) / 2
  boost = |V_a - base| × silk_weight × 0.5
  result = base + sign(V_a + V_b - 2×neutral) × boost
  → silk_weight=0: average (strangers)
  → silk_weight>0: amplification (connected concepts push further from neutral)
```

**Tính chất:**
- Scale-invariant: compose at char/word/sentence level → consistent
- Non-commutative: order matters (like DNA reading direction)
- Associative: compose(a, compose(b,c)) ≈ compose(compose(a,b), c) (approximate)

**Nguồn:**
- Zipf's Law: Zipf (1949) "Human Behavior and the Principle of Least Effort"
- Riemann integration: foundational calculus

---

## 8. Distance Metrics trong 5D

### 8.1 Euclidean 5D (normalized)

```
d(a, b) = √( (Sa-Sb)²/15² + (Ra-Rb)²/15² + (Va-Vb)²/7² + (Aa-Ab)²/7² + (Ta-Tb)²/3² )

Range: [0, √5 ≈ 2.236]
Similar: d < 0.3
Different: d > 1.0
```

### 8.2 Emotion-weighted

```
d_emo(a, b) = 2|Va - Vb| + |Aa - Ab|

V weighted 2× vì valence dominant trong nhận thức.
Nguồn: psychological research on emotion perception.
```

### 8.3 Dominant dimension

```
dominant_dim(mol):
  norms = [S/15, R/15, V/7, A/7, T/3]
  devs = [|n - 0.5| for n in norms]
  return argmax(devs)

→ dimension deviates most from neutral = most informative
→ THAT dimension drives silk walk = IS the query type
```

---

# PHAN II: CAU TRUC DU LIEU

---

## 9. Chain: Chuoi DNA Tri Thuc

### 9.1 Dinh nghia

```
Chain = sequence of u16 P_weight values.
Moi P_weight = 1 "nucleotide" trong DNA tri thuc.

chain = [pw_0, pw_1, pw_2, ..., pw_n]

Vi du:
  "hello" -> [pw('h'), pw('e'), pw('l'), pw('l'), pw('o')]
  Moi pw = 16-bit: (S:4|R:4|V:3|A:3|T:2)

Chain la NON-COMMUTATIVE: order matters.
  chain("AB") != chain("BA")
  Giong DNA: ATCG != GCTA

Chain la HIERARCHICAL:
  char-chain  -> word-chain  -> sentence-chain -> paragraph-chain
  Moi cap = compose(integral) cac phan tu cap duoi
```

### 9.2 Nen Chain: Delta Encoding + RLE

```
Delta Encoding:
  Thay vi luu [100, 102, 105, 103]:
  Luu [100, +2, +3, -2]  -- first value absolute, rest = delta

  delta[0] = chain[0]
  delta[i] = chain[i] - chain[i-1]  for i > 0

  Hieu qua: P_weight lien tiep thuong gan nhau
  -> delta nho -> nen tot hon

RLE (Run-Length Encoding):
  Sau delta, nhieu gia tri giong nhau -> nen tiep:
  [0, 0, 0, +1, +1] -> [(0,3), (+1,2)]

  Compression ratio:
    Raw:   N x 16 bits
    Delta: N x ~8 bits (deltas nho)
    Delta+RLE: ~N/2 x ~8 bits (repeated deltas merged)

  Thuc te: ~50-70% compression cho van ban tu nhien
```

### 9.3 Rolling Hash (Rabin-Karp)

```
De tim substring nhanh trong chain.

Rabin-Karp Hash:
  H(chain[i..i+k]) = Sum chain[j] x p^(k-j-1) mod m
  where p = prime base (31 hoac 37)
        m = large prime (10^9+7)

Rolling update:
  H(chain[i+1..i+k+1]) = (H(chain[i..i+k]) - chain[i]*p^(k-1)) * p + chain[i+k+1]

  -> O(1) per position thay vi O(k)
  -> Tim pattern length k trong chain length n: O(n) thay vi O(n*k)

Ung dung trong Nox:
  - Tim mot cum tu (sub-chain) trong memory
  - Phat hien lap lai (de-duplication)
  - N-gram indexing
```

### 9.4 K-mer Indexing (tu BLAST)

```
BLAST (Altschul et al., 1990):
  Chia chain thanh k-mers (subsequences length k).
  Xay index: k-mer -> list of (chain_id, position)

  chain = [a, b, c, d, e]
  3-mers: [a,b,c], [b,c,d], [c,d,e]

Index structure:
  HashMap<u48, Vec<(chain_id, offset)>>
  key = hash(k-mer), 48 bits du cho k=3 P_weights

Query:
  1. Chia query thanh k-mers
  2. Lookup moi k-mer trong index -> candidate chains
  3. Extend matches (giong BLAST extend phase)
  4. Score voi alignment

  Typical k = 3 cho P_weight chains (tuong duong k=11 cho DNA)
  Seed sensitivity: ~90% cho similarity > 70%
```

### 9.5 Sequence Alignment

```
Needleman-Wunsch (1970) -- Global Alignment:
  Align TOAN BO hai chain.

  F(i,j) = max {
    F(i-1, j-1) + score(a_i, b_j),   -- match/mismatch
    F(i-1, j)   + gap_penalty,         -- gap in chain B
    F(i,   j-1) + gap_penalty          -- gap in chain A
  }

  score(a, b) = -distance_5D(a, b)     -- closer P_weights = higher score
  gap_penalty  = -1.0                   -- penalize insertions/deletions

  Traceback: tu F(n,m) -> F(0,0) -> optimal alignment
  Complexity: O(n*m) time, O(n*m) space

Smith-Waterman (1981) -- Local Alignment:
  Tim BEST MATCHING SUBSEQUENCE.

  H(i,j) = max {
    0,                                  -- restart (key difference from NW)
    H(i-1, j-1) + score(a_i, b_j),
    H(i-1, j)   + gap_penalty,
    H(i,   j-1) + gap_penalty
  }

  Best local match = max(H(i,j)) over all i,j
  Traceback from max -> 0

  Ung dung: tim concept tuong tu trong memory chains
  "happy birthday" ~ "joyful anniversary" qua P_weight alignment

Levenshtein Distance (Edit Distance):
  d(a, b) = min number of edits (insert, delete, substitute)

  Dynamic programming O(n*m):
  D(i,j) = min {
    D(i-1, j) + 1,            -- delete
    D(i, j-1) + 1,            -- insert
    D(i-1, j-1) + delta(a_i,b_j) -- substitute (0 if same, 1 if different)
  }

  Nox dung: do "khoang cach chinh sua" giua hai chains
  Similarity = 1 - d(a,b) / max(|a|, |b|)
```

### 9.6 Chain Interpolation

```
Catmull-Rom Spline qua 5D points:
  Cho chuoi P_weights [P0, P1, P2, P3], noi suy giua P1 va P2:

  P(t) = 0.5 * [(2P1) +
                  (-P0 + P2)t +
                  (2P0 - 5P1 + 4P2 - P3)t^2 +
                  (-P0 + 3P1 - 3P2 + P3)t^3]

  t in [0, 1], P(0)=P1, P(1)=P2
  Interpolation TRONG 5D: ap dung cho tung dimension (S,R,V,A,T)

B-Spline (smooth, khong di qua control points):
  P(t) = Sum N_i,k(t) * P_i

  where N_i,k = B-spline basis functions (Cox-de Boor recursion)

Ung dung:
  - Tao "transition chain" giua hai concepts
  - Smooth emotion trajectory trong conversation
  - Predict next P_weight (extrapolation)
```

**Nghien cuu:**
- Needleman, S.B. & Wunsch, C.D. (1970). "A general method applicable to the search for similarities in the amino acid sequence of two proteins." Journal of Molecular Biology, 48(3), 443-453.
- Smith, T.F. & Waterman, M.S. (1981). "Identification of common molecular subsequences." Journal of Molecular Biology, 147(1), 195-197.
- Altschul, S.F. et al. (1990). "Basic Local Alignment Search Tool." Journal of Molecular Biology, 215(3), 403-410.
- Levenshtein, V.I. (1966). "Binary codes capable of correcting deletions, insertions, and reversals." Soviet Physics Doklady, 10(8), 707-710.

---

## 10. KnowTree: Cay Phan Nhom Ngu Nghia

### 10.1 Architecture

```
KnowTree = hierarchical organization of ALL knowledge.

Level 0: ENGINE -- code that runs Nox (VM, compiler, pipeline)
Level 1: CORE   -- fundamental operations (math, logic, compose)
Level 2+: KNOWLEDGE -- learned concepts, facts, skills

Moi node:
  struct KnowNode {
    p_weight: u16,        -- 5D position
    chain: Vec<u16>,      -- content (sequence of P_weights)
    silk_edges: Vec<Silk>, -- connections to other nodes
    qr: Vec<QR>,          -- proven knowledge attached
    access_count: u32,    -- for decay/promotion
    last_access: u64,     -- timestamp
    created: u64,         -- birth time
  }

Kich thuoc:
  32,768 possible P_weight values (2^15, vi T chi 2 bit)
  Thuc te: ~300-10,000 active nodes (phu thuoc knowledge)
```

### 10.2 Lookup Table -- O(1) Exact Match

```
Direct Lookup:
  table[P_weight] -> KnowNode*

  Size: 32,768 entries x 8 bytes (pointer) = 256 KB
  Lookup: O(1) -- array index = P_weight value

  Khi tim P_weight = 0x3A5F:
    node = table[0x3A5F]  -- 1 memory access

  Problem: chi exact match. Nhieu P_weight -> same entry.
  -> Can bucket hoac tree cho approximate search.
```

### 10.3 Multi-Level Bucket

```
Tier 1: S x R buckets (256 buckets)
  bucket_id = (S << 4) | R
  Moi bucket chua list of nodes voi cung S,R
  -> Tim tat ca nodes co cung shape + relation

Tier 2: S x R x V buckets (2,048 buckets)
  bucket_id = (S << 7) | (R << 3) | V
  -> Tim tat ca nodes co cung shape + relation + valence

Query algorithm:
  1. Compute bucket_id tu query P_weight
  2. Lay list tu bucket[bucket_id]
  3. Linear scan trong bucket, compute full 5D distance
  4. Return top-K nearest

  Average bucket size: 32768 / 2048 = 16 nodes
  -> Linear scan trong 16 nodes = fast enough cho <10K tong nodes
```

### 10.4 VP-Tree (Vantage-Point Tree)

```
Nguon: Yianilos, P.N. (1993). "Data structures and algorithms for
       nearest neighbor search in general metric spaces."
       Proceedings of the 4th Annual ACM-SIAM Symposium on Discrete
       Algorithms (SODA), 311-321.

VP-Tree hoat dong trong BAT KY metric space nao (chi can distance function).
Nox co distance function 5D -> VP-Tree ap dung duoc.

Build:
  1. Chon vantage point vp = random node
  2. Tinh d = distance(vp, x) cho moi x
  3. Tim median mu cua cac d
  4. Left subtree: {x : d(vp,x) < mu}
  5. Right subtree: {x : d(vp,x) >= mu}
  6. Recurse

Search(query, k):
  1. d_vp = distance(query, vp)
  2. If d_vp < mu: search left FIRST, then right if needed
     If d_vp >= mu: search right FIRST, then left if needed
  3. Prune: if |d_vp - mu| > best_distance -> skip other subtree

Complexity:
  Build: O(n log n)
  Search: O(log n) average case
  Space: O(n)

Khi nao dung:
  1,000 < nodes < 50,000  -- sweet spot cho VP-Tree
  Exact nearest neighbor required
```

### 10.5 HNSW (Hierarchical Navigable Small World)

```
Nguon: Malkov, Y.A. & Yashunin, D.A. (2018). "Efficient and robust
       approximate nearest neighbor using Hierarchical Navigable Small
       World graphs." IEEE TPAMI, 42(4), 824-836.

HNSW = multi-layer graph. Top layer = few nodes (express highways).
Bottom layer = all nodes (local streets).

Build:
  1. Insert node x:
     a. Assign layer l = floor(-ln(uniform(0,1)) * m_L)
        where m_L = 1/ln(M), M = max connections per layer
     b. Start from entry point at top layer
     c. Greedy search down to layer l
     d. At each layer l..0: find M nearest neighbors, connect

Search(query, ef):
  1. Start from entry point, top layer
  2. Greedy descent: at each layer, move to nearest neighbor
  3. At layer 0: beam search with width ef
  4. Return ef nearest candidates

Parameters:
  M = 16 (max connections per node per layer)
  ef_construction = 200 (beam width during build)
  ef_search = 50 (beam width during query)
  m_L = 1/ln(16) = 0.36

Complexity:
  Build: O(n log n)
  Search: O(log n) -- nearly independent of dimension!
  Space: O(n * M * L_avg)

Khi nao dung:
  nodes > 10,000 -- HNSW outperforms VP-tree
  Approximate OK (recall > 95%)

So sanh:
  VP-Tree:  exact, O(log n), nhung constant lon khi d > 5
  HNSW:    approximate, O(log n), constant nho, scale tot
  KD-Tree: exact, O(log n), nhung BAD khi d > 10 (curse of dimensionality)
  Nox d=5:  VP-Tree hoac HNSW deu tot. HNSW tot hon khi scale.
```

---

## 11. Silk: 9,200 Loai Ket Noi

### 11.1 Silk Edge Structure

```
struct SilkEdge {
  from: NodeId,
  to: NodeId,
  weights: [f32; 5],   -- [wS, wR, wV, wA, wT]
  silk_type: u16,       -- UDC character -> loai silk
  strength: f32,        -- tong strength (decay over time)
  fire_count: u32,      -- so lan activate
  last_fire: u64,       -- timestamp lan cuoi
}

5 weights tuong ung 5 dimensions:
  wS: shape similarity (visual)
  wR: relation similarity (logical)
  wV: valence similarity (emotional)
  wA: arousal similarity (energy)
  wT: temporal similarity (rhythm)

Dominant dimension = silk type:
  type = argmax(|weights|)
  S-dominant silk: visual associations ("red" -> "blood")
  R-dominant silk: logical relations ("dog" IS-A "animal")
  V-dominant silk: emotional links ("love" ~ "joy")
  A-dominant silk: energy links ("explode" ~ "scream")
  T-dominant silk: temporal links ("morning" -> "breakfast")
```

### 11.2 Silk Type Classification (9,200 types)

```
Nguon: UDC (Universal Decimal Classification) character set
9,200 Unicode characters -> 9,200 possible silk types.

Moi UDC character = 1 loai quan he:
  Relation types from natural language:
    IS-A, HAS-PART, CAUSES, SIMILAR-TO, OPPOSITE-OF,
    PRECEDES, FOLLOWS, CONTAINS, OVERLAPS, ENABLES...

  Mapping:
    UDC char -> P_weight -> silk type
    Silk type = ngu nghia cua ket noi

  Vi du silk types:
    -> (arrow)        = CAUSES, LEADS-TO
    subset            = IS-A, TYPE-OF
    intersection      = OVERLAPS, SHARES
    approx-equal      = SIMILAR-TO
    not-equal         = DIFFERENT-FROM
    + (plus)          = COMBINES-WITH
    x (times)         = INTERACTS-WITH

Trong thuc te hien tai:
  Chi 6 active silk types (BLOCKER #2 -- caused by collision)
  Target: 100+ silk types sau khi fix P_weight collision
  Full 9,200: long-term goal khi knowledge du lon
```

### 11.3 Structural vs Hebbian Silk

```
Structural Silk (trong chain):
  - Ket noi giua cac P_weights LIEN TIEP trong chain
  - O(0) extra storage -- implicit tu chain order
  - Always exists: chain[i] -> chain[i+1]
  - Strength = 1.0 (absolute, khong decay)

Hebbian Silk (giua nodes):
  - Ket noi giua concepts CO-ACTIVATE
  - Explicit storage: requires SilkEdge struct
  - Created by learning: "fire together -> wire together"
  - Strength DECAYS: w(t) = w0 * phi_inv^(t/tau)

Co-activation patterns:
  - Same sentence -> silk created/strengthened
  - Same paragraph -> weaker silk
  - Frequently co-occurring -> strong silk (Hebbian)
  - Contradicting -> negative silk weight (inhibitory)
```

---

## 12. QR: Tri Thuc Da Chung Minh

### 12.1 QR Structure

```
struct QR {
  claim: Chain,         -- chain encoding of the claim
  evidence: Vec<Chain>, -- supporting evidence chains
  confidence: f32,      -- [0.0, 1.0]
  source: Source,       -- where it came from
  timestamp: u64,       -- when proven
  verifications: u32,   -- times re-verified
}

enum Source {
  Observed,    -- directly perceived
  Inferred,    -- derived by logic
  Taught,      -- told by external
  Composed,    -- built from sub-QRs
}
```

### 12.2 Append-Only + Signed

```
QR log = APPEND-ONLY. Khong bao gio sua QR cu.
Neu claim sai -> them QR moi phu dinh claim cu.

Signing:
  hash = SHA256(claim_chain || evidence_chains || timestamp)
  Moi QR co hash -> verifiable chain of knowledge

  Tampering detection:
    If hash(QR) != stored_hash -> knowledge corruption detected
    -> Trigger DNA Repair (Section 19)
```

### 12.3 Promotion: Fibonacci Fire Threshold

```
QR promotion levels:
  Level 0: Hypothesis  (confidence < 0.3)
  Level 1: Belief      (confidence in [0.3, 0.6))
  Level 2: Knowledge   (confidence in [0.6, 0.8))
  Level 3: Proven      (confidence >= 0.8)

Promotion threshold = Fibonacci sequence:
  fire_count thresholds: 1, 1, 2, 3, 5, 8, 13, 21, 34, 55...

  Khi node.fire_count vuot Fibonacci threshold:
    1. Re-evaluate confidence
    2. If confidence increased -> promote
    3. If confidence decreased -> demote

Tai sao Fibonacci?
  - Spacing tang dan (giong spaced repetition trong hoc tap)
  - phi = (1+sqrt(5))/2 ~ 1.618 -- golden ratio
  - Tu nhien: sunflower, shell, galaxy spirals
  - Optimal trong information theory: Zeckendorf representation
  - Avoid over-promotion: can NHIEU LAN xac nhan de len level cao
```

---

## 13. STM/WM: Bo Nho Ngan Han + Lam Viec

### 13.1 Short-Term Memory (STM)

```
Capacity: 32 slots (tunable)
Inspired by: Miller (1956) "The Magical Number Seven, Plus or Minus Two"
Nox dung 32 vi can luu P_weight nodes (lon hon text tokens)

struct STMEntry {
  node_id: NodeId,
  p_weight: u16,
  access_count: u32,
  emotion_score: f32,   -- |V - neutral| + A/A_max
  last_access: u64,
  entered: u64,
}
```

### 13.2 Eviction Policy

```
Khi STM day (32 slots), can loai bo entry.

Score-based eviction:
  score(entry) = access * 0.3 + emotion * 0.4 + recency * 0.3

  access  = entry.access_count / max_access        in [0, 1]
  emotion = (|V - 4| / 3 + A / 7) / 2              in [0, 1]
  recency = 1 - (now - entry.last_access) / window  in [0, 1]

  LOWEST score -> evict first.

Tai sao emotion * 0.4 (cao nhat)?
  - Emotional memories persist longer (amygdala research)
  - Von Restorff effect: unusual = remembered
  - Trong Nox: high |V| hoac high A = "quan trong" -> giu lai

Tai sao KHONG dung LRU (Least Recently Used)?
  - LRU chi dua vao recency
  - Bo qua emotion va frequency
  - "I love you" said once 5 min ago > "the" said 10 times 1 min ago
  - Cac he thong cache (CPU, OS) dung LRU vi khong co emotion dimension
```

### 13.3 Working Memory (WM)

```
Capacity: 4 slots
Inspired by: Cowan (2001) "The magical number 4 in short-term memory"

WM = active focus. Nhung gi DANG xu ly.
STM = recent context. Nhung gi VUA thay.

WM slots:
  slot[0] = current input (dang xu ly)
  slot[1] = current output (dang tao)
  slot[2] = active goal (dang huong toi)
  slot[3] = active context (background)

WM <-> STM interaction:
  - WM items always also in STM (dual presence)
  - WM eviction -> item remains in STM
  - STM eviction -> item gone (unless in WM)

WM refresh cycle:
  Moi pipeline step: re-evaluate WM slots
  If goal completed -> slot[2] = next goal
  If context changed -> slot[3] = new context
```

---

# PHAN III: THUAT TOAN HOC

---

## 14. Hebbian Learning: Fire Together, Wire Together

### 14.1 Classic Hebbian Rule (Hebb, 1949)

```
"When an axon of cell A is near enough to excite cell B and repeatedly
or persistently takes part in firing it, some growth process or metabolic
change takes place in one or both cells such that A's efficiency, as one
of the cells firing B, is increased." -- Donald Hebb, 1949

Mathematical formulation:
  dw_ij = eta * x_i * y_j

  w_ij = weight of connection from node i to node j
  eta  = learning rate (0.01 - 0.1 typical)
  x_i  = activation of pre-synaptic node i
  y_j  = activation of post-synaptic node j

Problem: unbounded growth -- weights -> infinity

Trong Nox:
  Khi hai nodes co-activate (trong cung context):
    silk.weights += eta * activation_i * activation_j

  activation = f(access_recency, V_relevance, A_energy)
```

### 14.2 Oja's Rule -- Normalized Hebbian (Oja, 1982)

```
Oja's Rule giai quyet unbounded growth:
  dw_ij = eta * y_j * (x_i - y_j * w_ij)

  Term y_j * w_ij = decay proportional to output * weight
  -> Weight vector converges to principal eigenvector
  -> Natural normalization: ||w|| -> 1

Derivation:
  Standard Hebbian: dw = eta*x*y
  Add decay:        dw = eta*y*(x - y*w)
  Expand:           dw = eta*y*x - eta*y^2*w

  At equilibrium: eta*y*x = eta*y^2*w -> w = x/y (ratio)
  Since y = w^T * x -> w converges to dominant eigenvector of E[xx^T]

Trong Nox:
  Silk weight update voi Oja's normalization:
    dw[d] = eta * y * (x[d] - y * w[d])  for each dimension d in {S,R,V,A,T}
  -> Silk weights auto-normalize
  -> Khong can manual clipping
```

### 14.3 BCM Theory -- Sliding Threshold (Bienenstock, Cooper, Munro, 1982)

```
BCM adds a SLIDING THRESHOLD theta that separates potentiation from depression:

  dw = eta * x * y * (y - theta)

  y > theta  -> dw > 0 (strengthen -- Long-Term Potentiation)
  y < theta  -> dw < 0 (weaken -- Long-Term Depression)
  y = theta  -> dw = 0 (no change)

  theta itself slides:
    theta(t) = E[y^2]  -- average squared activity

  If neuron is very active: theta rises -> harder to strengthen
  If neuron is inactive: theta falls -> easier to strengthen
  -> Homeostatic: prevents both runaway excitation AND silence

Trong Nox:
  theta = mean(fire_count^2) across neighbors
  If silk fires > theta -> strengthen
  If silk fires < theta -> weaken
  -> Prevents "everything connected to everything" (collapse)
  -> Ensures selective connectivity
```

### 14.4 STDP -- Spike-Timing Dependent Plasticity

```
STDP = timing matters. WHO FIRES FIRST matters.

  If A fires BEFORE B (dt = t_B - t_A > 0):
    dw = A_plus * exp(-dt / tau_plus)    -- LTP (strengthen)

  If A fires AFTER B (dt < 0):
    dw = -A_minus * exp(dt / tau_minus)  -- LTD (weaken)

  Parameters:
    A_plus  = 0.01   (LTP amplitude)
    A_minus = 0.012  (LTD amplitude, slightly stronger -> net depression)
    tau_plus  = 20ms (LTP time constant)
    tau_minus = 20ms (LTD time constant)

Trong Nox (discrete time):
  dt = position difference in chain (hoac processing order)
  If concept A appears BEFORE B:
    silk(A->B) strengthened (A predicts B)
    silk(B->A) weakened (B does NOT predict A)
  -> Creates DIRECTIONAL silk (causal, temporal order)
  -> "morning" -> "breakfast" strong, "breakfast" -> "morning" weaker
```

### 14.5 Covariance Rule

```
Covariance Rule:
  dw = eta * (x - <x>) * (y - <y>)

  <x> = running mean of x activations
  <y> = running mean of y activations

  Only DEVIATIONS from mean matter.

KEY INSIGHT for Nox:
  Common characters (e, t, a, o) -> high <x> -> zero deviation -> NO silk
  Rare/distinctive features -> low <x> -> high deviation -> STRONG silk
  
  This SOLVES mol collision:
    Before: "happy" and "table" both fire common-letter silk -> same result
    After: only distinctive co-occurrences create silk
    "happy" + "joy" = distinctive co-occurrence -> silk
    "happy" + "the" = common co-occurrence -> no silk (deviation = 0)
```

**Nghien cuu:**
- Hebb, D.O. (1949). "The Organization of Behavior: A Neuropsychological Theory." New York: Wiley.
- Oja, E. (1982). "Simplified neuron model as a principal component analyzer." Journal of Mathematical Biology, 15(3), 267-273.
- Bienenstock, E.L., Cooper, L.N., & Munro, P.W. (1982). "Theory for the development of neuron selectivity." Journal of Neuroscience, 2(1), 32-48.
- Bi, G. & Poo, M. (1998). "Synaptic modifications in cultured hippocampal neurons: dependence on spike timing." Journal of Neuroscience, 18(24), 10464-10472.
- Foldiak, P. (1990). "Forming sparse representations by local anti-Hebbian learning." Biological Cybernetics, 64, 165-170.

---

## 15. Decay: phi^-1 Forgetting Curve

### 15.1 Core Decay Formula

```
w(t) = w0 * phi_inv^(t / tau)

  w0   = initial weight at time of last reinforcement
  phi_inv = 1/phi = 1/1.618... = 0.618...
  t    = time since last access
  tau  = time constant (24 hours default)

Vi du:
  t = 0:    w = w0 * 0.618^0 = w0        (full strength)
  t = 24h:  w = w0 * 0.618^1 = 0.618*w0  (38.2% lost)
  t = 48h:  w = w0 * 0.618^2 = 0.382*w0  (61.8% lost)
  t = 72h:  w = w0 * 0.618^3 = 0.236*w0  (76.4% lost)
  t = 7d:   w = w0 * 0.618^7 = 0.034*w0  (96.6% lost)

Tai sao phi_inv = 0.618?
  - Golden ratio: self-similar decay
  - phi_inv = phi - 1 = 2/(1+sqrt(5))
  - Fibonacci connection: F(n)/F(n+1) -> phi_inv
  - Matches biological forgetting curves better than arbitrary constants
```

### 15.2 Ebbinghaus Forgetting Curve (1885)

```
Hermann Ebbinghaus:
  R(t) = e^(-t/S)

  R = retention (probability of recall)
  t = time since learning
  S = stability (strength of memory)

  Stronger memory (higher S) -> slower forgetting.

Spacing Effect:
  Reviewing at optimal intervals INCREASES S:
    S_new = S_old * (1 + factor * time_since_last)

  Optimal review schedule ~ geometric spacing:
    Review at: 1 day, 3 days, 7 days, 14 days, 30 days...
    (Fibonacci-like: 1, 1, 2, 3, 5, 8, 13, 21...)

Connection to Nox:
  Moi silk fire = 1 review -> tang S -> cham decay
  fire_count = proxy cho S
  tau(silk) = base_tau * (1 + log(fire_count))
  -> Frequently fired silk decays SLOWER
  -> Rarely fired silk decays FASTER
  -> Natural spaced repetition from usage patterns
```

### 15.3 Power Law of Forgetting (Wickelgren, 1974)

```
Wickelgren's Power Law:
  P(t) = lambda * (1 + beta*t)^(-psi)

  lambda = initial degree of learning
  beta   = rate parameter
  psi    = decay exponent (typically 0.5-1.0)

Power law vs Exponential:
  Exponential: P(t) = e^(-t/tau)      -- fast initial drop, slow later
  Power law:   P(t) = (1+t)^(-psi)    -- slower initial drop, long tail

  Empirical finding: POWER LAW fits human memory data better.
  Wixted & Ebbesen (1991) confirmed across 6 memory paradigms.

  But power law is harder to compute efficiently.
  Nox compromise:
    phi_inv exponential (fast, simple) +
    fire_count modulates tau (approximates power law's long tail)

    tau_effective = base_tau * (1 + log(fire_count + 1))
    w(t) = w0 * phi_inv^(t / tau_effective)

    -> Low fire_count: fast exponential decay (like power law's body)
    -> High fire_count: slow decay (like power law's long tail)

  Alternative implementation (Power law + stability):
    effective_dt = dt / (24 * stability)
    factor = (1 + effective_dt)^(-0.5)    // Wickelgren 1974
    Stability grows with each fire: S_new = S * 1.5 (Ebbinghaus)
```

**Nghien cuu:**
- Ebbinghaus, H. (1885). "Uber das Gedachtnis." Duncker & Humblot.
- Wickelgren, W.A. (1974). "Single-trace fragility theory of memory dynamics." Memory & Cognition, 2(4), 775-780.
- Wixted, J.T. & Ebbesen, E.B. (1991). "On the form of forgetting." Psychological Science, 2(6), 409-415.

---

## 16. Dream: Consolidation + Cross-Group Resonance

### 16.1 Dream Cycle Overview

```
Dream = offline processing khi khong co input moi.
Purpose: consolidate, reorganize, discover patterns.

3 phases:
  Phase 1: REPLAY -- re-activate recent chains
  Phase 2: CLUSTER -- group similar nodes
  Phase 3: CROSS-LINK -- find unexpected connections

Biological parallel:
  NREM sleep: memory consolidation, replay
  REM sleep: creative connections, cross-modal binding
```

### 16.2 Graph Clustering

```
Spectral Clustering:
  1. Build adjacency matrix A from silk edges
     A[i][j] = silk.strength between node i and node j
  2. Compute degree matrix D: D[i][i] = Sum_j A[i][j]
  3. Compute Laplacian L = D - A
  4. Find eigenvectors of L with smallest eigenvalues
  5. Use k smallest eigenvectors as features
  6. K-means on eigenvector features -> clusters

  Tai sao Spectral?
    - Works on ANY graph (not just Euclidean)
    - Finds non-convex clusters
    - Eigenvalues reveal natural number of clusters

  Simplification cho Nox (khong can full eigen-decomposition):
    Power iteration cho top-k eigenvectors: O(k * E * iterations)
    E = number of silk edges, k = number of clusters desired

Girvan-Newman Algorithm:
  1. Compute edge betweenness for all edges
     betweenness(e) = number of shortest paths through e
  2. Remove edge with highest betweenness
  3. Recompute betweenness
  4. Repeat until desired number of clusters

  Good for: finding communities in knowledge graph
  Complexity: O(E^2 * N) -- expensive, use for small subgraphs

  Trong Nox: apply to STM contents (small, ~32 nodes)
  -> Find clusters in recent conversation
  -> Identify topic shifts
```

### 16.3 Concept Formation: LCA (Lowest Common Ancestor)

```
LCA = tim concept chung nho nhat giua hai nodes.

Given nodes A and B in KnowTree:
  LCA(A, B) = deepest node that is ancestor of both A and B

Algorithms:
  Naive: walk up from both -> O(depth)
  Binary Lifting: preprocess O(n log n), query O(log n)
  Euler Tour + RMQ: preprocess O(n), query O(1)

Ung dung trong Dream:
  Khi hai clusters co silk connections:
    lca = LCA(cluster_A.center, cluster_B.center)
    If lca is too abstract (root-level) -> no meaningful connection
    If lca is specific -> found shared concept -> create/strengthen silk

  Vi du:
    cluster_A = {dog, cat, fish} -> animal
    cluster_B = {car, bus, train} -> vehicle
    LCA = "thing" (too abstract -> skip)

    cluster_A = {happy, joy, delight} -> positive_emotion
    cluster_B = {smile, laugh, grin} -> positive_expression
    LCA = "positive" -> meaningful! -> create silk
```

### 16.4 Union-Find (Disjoint Set Union)

```
Union-Find for incremental clustering during dream:

struct UnionFind {
  parent: Vec<usize>,
  rank: Vec<usize>,
}

fn find(x):
  if parent[x] != x:
    parent[x] = find(parent[x])  -- path compression
  return parent[x]

fn union(x, y):
  rx, ry = find(x), find(y)
  if rx == ry: return
  if rank[rx] < rank[ry]: swap(rx, ry)
  parent[ry] = rx
  if rank[rx] == rank[ry]: rank[rx] += 1

Complexity: O(alpha(n)) per operation, where alpha = inverse Ackermann ~ O(1)

Dream application:
  For each silk edge (u, v) where strength > threshold:
    union(u, v)
  -> Groups of strongly connected nodes = clusters
  -> O(E * alpha(N)) total -- extremely fast
  -> Then process each cluster: find center, compute properties
```

---

## 17. Homeostasis: Free Energy Principle (Friston)

### 17.1 Friston's Free Energy Principle (2010)

```
Karl Friston (2010):
"Any self-organizing system that is at equilibrium with its environment
must minimize its free energy."

Free Energy F >= surprise = -ln P(sensory data | model)

  F(t) = DKL[Q(theta) || P(theta | data)] + E_Q[-ln P(data | theta)]

  DKL = Kullback-Leibler divergence (how wrong your beliefs are)
  Q(theta) = your current beliefs (approximate posterior)
  P(theta | data) = true posterior (what beliefs SHOULD be)
  P(data | theta) = likelihood (how well model predicts data)

  Minimizing F = minimizing surprise = better predictions

Two ways to minimize F:
  1. Update beliefs (PERCEPTION): change Q(theta) to match data
     -> Nox: learn, update silk weights
  2. Change data (ACTION): change sensory input
     -> Nox: ask questions, seek information, avoid bad input
```

### 17.2 Nox Homeostasis Implementation

```
Prediction Error:
  For each input, Nox predicts next token/concept.
  error = distance_5D(predicted_P_weight, actual_P_weight)

  Weighted prediction error:
  F(t) = sqrt(Sum w_d * (predicted_d - actual_d)^2)

  Exponential moving average:
    F_avg(t) = alpha * F(t) + (1 - alpha) * F_avg(t-1)
    alpha = 0.1 (smoothing factor)

Learning Rate Modulation:
  lambda(t) = sigmoid(F(t) - phi_inv)

  sigmoid(x) = 1 / (1 + e^(-k*x)),  k = 5 (steepness)

  F(t) > phi_inv:  lambda -> 1.0 (high surprise -> learn fast)
  F(t) = phi_inv:  lambda = 0.5 (equilibrium)
  F(t) < phi_inv:  lambda -> 0.0 (low surprise -> learn slow)

  phi_inv = 0.618 as threshold:
    - Not arbitrary -- golden ratio balance point
    - Below this: system is "comfortable" (good predictions)
    - Above this: system is "surprised" (bad predictions -> adapt)

Homeostatic Targets:
  STM fullness target: 50-80%
  Silk density target: 5-20 edges per node
  Average error target: < phi_inv

  If metric deviates: adjust parameters:
    STM too full -> lower eviction threshold
    Silk too dense -> raise Hebbian threshold
    Error too high -> increase learning rate
```

### 17.3 Active Inference

```
Active Inference = action selection to minimize EXPECTED free energy.

  G(pi) = E_Q[ln Q(theta) - ln P(theta, data | pi)]

  pi = policy (sequence of actions)
  G(pi) = expected free energy under policy pi

  Minimize G(pi):
    - Epistemic value: actions that REDUCE uncertainty (exploration)
    - Pragmatic value: actions that ACHIEVE goals (exploitation)

  Trong Nox:
    Exploration: ask questions about high-uncertainty areas
    Exploitation: use well-known silk paths for generation

    Balance: G(pi) naturally balances both
    -> When uncertainty high -> explore (curiosity)
    -> When uncertainty low -> exploit (use knowledge)
```

**Nghien cuu:**
- Friston, K. (2010). "The free-energy principle: a unified brain theory?" Nature Reviews Neuroscience, 11(2), 127-138.
- Friston, K., FitzGerald, T., Rigoli, F., Schwartenbeck, P., & Pezzulo, G. (2017). "Active Inference, Curiosity and Insight." Neural Computation, 29(10), 2633-2683.
- Parr, T., Pezzulo, G., & Friston, K.J. (2022). "Active Inference: The Free Energy Principle in Mind, Brain, and Behavior." MIT Press.

---

## 18. Immune Selection: Multi-Hypothesis

### 18.1 Clonal Selection Algorithm

```
Nguon: De Castro & Von Zuben (2002), inspired by biological immune system.

Biological analogy:
  Antigen = problem/query
  Antibody = candidate solution
  Affinity = how well solution fits problem
  Clone + mutate = explore variations
  Selection = keep best

Algorithm:
  1. GENERATE: k initial hypotheses (antibodies)
     Each hypothesis = a silk walk path through KnowTree
  2. EVALUATE: affinity(hypothesis, query)
     affinity = -distance_5D(hypothesis.compose(), query.P_weight)
  3. CLONE: top-3 hypotheses get cloned (beam search)
     n_clones(h) = round(beta * N / rank(h))
     beta = cloning factor, N = population size
  4. MUTATE: clones get modified
     mutation_rate(h) = exp(-rho * affinity(h))
     High affinity -> small mutations (fine-tune)
     Low affinity -> large mutations (explore)
  5. SELECT: keep top-k from (originals + clones)
  6. REPEAT for max_iterations OR convergence

Parameters for Nox:
  k = 3 (beam width -- top 3 hypotheses)
  beta = 0.3 (cloning factor)
  rho = 2.0 (mutation decay)
  max_iterations = 3 (bounded! DNA Repair rule)
```

### 18.2 Beam Search (top-3)

```
Beam Search = breadth-first with bounded width.

beam_search(start, goal, beam_width=3):
  beam = [{path: [start], score: 0}]

  for step in 0..max_steps:
    candidates = []
    for path in beam:
      for neighbor in silk_neighbors(path.last()):
        new_path = path + [neighbor]
        new_score = score(new_path, goal)
        candidates.push({path: new_path, score: new_score})

    beam = top_k(candidates, beam_width)

    if any path reaches goal: return best

  return beam[0]  -- best path found

Score function:
  score(path, goal) = -distance_5D(compose(path), goal.P_weight)
                      + bonus * path.length  -- prefer shorter paths
                      + silk_strength_sum(path) * 0.1  -- prefer strong silk

Beam width = 3:
  - 1: greedy (fast but misses)
  - 3: good balance (explore 3 alternatives at each step)
  - 10+: expensive, diminishing returns
```

### 18.3 MCTS (Monte Carlo Tree Search)

```
MCTS = for complex decision trees (future, when knowledge large).

4 phases per iteration:
  1. SELECT: traverse tree using UCB1
     UCB1(node) = Q(node)/N(node) + c * sqrt(ln N(parent) / N(node))
     c = sqrt(2) (exploration constant)
  2. EXPAND: add new child node (unexplored silk path)
  3. SIMULATE: random silk walk to terminal -> evaluate
  4. BACKPROPAGATE: update Q and N along path

Khi nao dung MCTS:
  - Knowledge graph > 10,000 nodes
  - Multi-step reasoning (depth > 5)
  - Planning sequences of actions

Hien tai Nox:
  Knowledge ~300 nodes -> beam search du
  MCTS = future khi scale
```

---

## 19. DNA Repair: Bounded Self-Correction

### 19.1 Bounded 3 Iterations

```
DNA Repair = self-correction mechanism.
CRITICAL RULE: maximum 3 iterations. No infinite loops.

repair(chain, quality_fn):
  best = chain
  best_score = quality_fn(chain)

  for i in 0..3:  -- HARD LIMIT
    candidate = mutate(best)
    score = quality_fn(candidate)
    if score > best_score:
      best = candidate
      best_score = score
    else:
      break  -- no improvement -> stop early

  return best
```

### 19.2 Quality Function

```
quality(chain) evaluates chain correctness:

  q_internal = internal_consistency(chain)
    -- Do cac P_weights trong chain "hop ly" voi nhau?
    -- Sum of silk weights between consecutive elements
    -- Higher = more internally consistent

  q_external = external_match(chain, context)
    -- Chain co phu hop voi context (STM, WM)?
    -- Distance between chain.compose() and context.compose()
    -- Lower distance = better match

  q_qr = qr_consistency(chain)
    -- Chain co mau thuan voi QR (proven knowledge)?
    -- Check against QR store
    -- 0 = contradiction, 1 = consistent

  quality = 0.3 * q_internal + 0.4 * q_external + 0.3 * q_qr

Alternative formulation (entropy-based):
  quality = 0.30*v + 0.30*(1-H/2.32) + 0.20*c + 0.20*s
  where v = valence alignment, H = entropy, c = coherence, s = silk support
```

### 19.3 Rollback

```
If all 3 iterations WORSEN quality:
  Rollback to original chain.
  Mark chain as "unrepaired" for manual review.

  never:
    - Loop more than 3 times
    - Accept worse quality
    - Modify QR-proven chains
    - Repair during critical operations (security gate, etc.)

Rollback mechanism:
  saved = chain.clone()  -- save before repair
  result = repair(chain, quality_fn)
  if quality_fn(result) < quality_fn(saved):
    return saved  -- rollback
  return result
```

---

# PHAN IV: PIPELINE XU LY

---

## 20. SecurityGate: 3 Tang, Toan Thuan

### 20.1 Bloom Filter Gate

```
Bloom Filter:
  Probabilistic data structure. Can test membership O(1).
  False positives possible. False negatives IMPOSSIBLE.

SecurityGate Bloom Filter:
  Threat criteria from P_weight dimensions:
    THREAT if: V <= 1 AND A >= 6
    -> Very negative (V<=1) AND very high energy (A>=6)
    -> "hateful screaming" = threat, "calm sadness" = NOT threat

  3 independent hash functions:
    h1(pw) = (pw * 2654435761) >> 16  mod m
    h2(pw) = (pw * 2246822519) >> 16  mod m
    h3(pw) = (pw * 3266489917) >> 16  mod m

  m = 1024 bits (128 bytes filter size)

  Insert known-threat P_weight:
    set bit h1(pw), h2(pw), h3(pw) in bit array

  Check input P_weight:
    if ALL bits h1(pw), h2(pw), h3(pw) are set -> POSSIBLE threat
    if ANY bit is 0 -> DEFINITELY not threat

  False positive rate: (1 - e^(-kn/m))^k
    k=3 hash functions, n=100 threat patterns, m=1024
    ~ (1 - e^(-300/1024))^3 ~ 0.02 (2% false positive)
```

### 20.2 Three Security Layers

```
Layer 1: SPEED GATE (Bloom filter)
  O(1), catches obvious threats.
  Pass -> Layer 2.

Layer 2: DIMENSION CHECK
  Full P_weight analysis:
    threat_score = (7 - V) * 2 + A
    if threat_score > 18 -> BLOCK

  Also check:
    - Input length (extremely long -> possible attack)
    - Repetition (same char repeated -> possible attack)
    - Control characters (U+0000..U+001F -> suspicious)

Layer 3: CONTEXT CHECK
  Compare input P_weight against:
    - STM context (is this topic sudden shift?)
    - WM goal (does this align with current task?)
    - QR proven safe patterns

  Sudden large shift + high threat_score -> ELEVATED ALERT
  Gradual shift -> probably normal topic change

Response:
  BLOCK -> refuse + explain
  ALERT -> proceed cautiously, flag for review
  PASS -> normal processing
```

---

## 21. 7 Instincts: 7 Formulas Tren 5D

### 21.1 Overview

```
7 instincts = hardwired evaluation functions.
Each instinct computes a score from 5D P_weight dimensions.
KHONG hoc, KHONG thay doi. Giong reflexes trong sinh hoc.

  I1: Honesty      -- truth vs deception
  I2: Contradiction -- consistency check
  I3: Causality     -- cause-effect logic
  I4: Abstraction   -- generalization level
  I5: Analogy       -- structural similarity
  I6: Curiosity     -- novelty detection
  I7: Reflection    -- self-evaluation
```

### 21.2 Formulas

```
I1 HONESTY:
  score = 1 - |V_claimed - V_evidence| / 7

  V_claimed = valence of assertion
  V_evidence = valence of supporting evidence (from QR + silk)
  If large gap -> dishonest (saying "good" about something known bad)

  threshold: score < 0.3 -> flag as dishonest

I2 CONTRADICTION:
  score = 1 - cosine_similarity(P_a, P_b) for conflicting claims

  cosine_sim = dot(P_a, P_b) / (|P_a| * |P_b|)
  (treating P_weight 5D as vector)

  If P_a and P_b are VERY similar but asserted as different -> contradiction
  If P_a and P_b are different AND asserted as same -> also contradiction

  threshold: score > 0.7 -> contradiction detected

I3 CAUSALITY:
  score = silk_strength(A->B) * temporal_order(A,B)

  temporal_order = 1 if A precedes B in chain, 0.5 if concurrent, 0 if reversed
  Strong silk + correct order -> valid causal claim

  threshold: score < 0.2 -> weak/invalid causality

I4 ABSTRACTION:
  score = 1 / (1 + depth_in_knowtree(node))

  Root = most abstract (score ~ 1)
  Leaf = most concrete (score ~ 0)

  Used for: deciding whether to generalize or specialize in response

I5 ANALOGY:
  score = structural_similarity(subgraph_A, subgraph_B)

  Compare silk patterns around two nodes:
    neighbors_A = silk_neighbors(A)
    neighbors_B = silk_neighbors(B)
    shared_structure = |pattern_A intersection pattern_B| / |pattern_A union pattern_B|
    (Jaccard similarity of silk patterns)

  High score -> A and B play similar roles in their neighborhoods

I6 CURIOSITY:
  score = min_distance_to_known(input_P_weight)

  Nearest known node distance:
    d = min over all nodes: distance_5D(input, node.P_weight)
    score = d / max_possible_distance

  High score -> input is FAR from anything known -> HIGH curiosity
  -> Trigger exploration, ask questions, seek information

I7 REFLECTION:
  score = |predicted_output - actual_output| / max_distance

  After generating response:
    predicted = what pipeline predicted the output would be
    actual = what was actually generated

  High score -> self-evaluation shows poor prediction -> need to learn
  Low score -> confident, calibrated
```

---

## 22. Pipeline 14 Buoc, 5 Checkpoints

### 22.1 Full Pipeline

```
Step  1: INPUT         -- receive raw input
Step  2: ENCODE        -- each char -> P_weight (42 formulas)
Step  3: COMPOSE       -- chars -> words -> phrases (integral)
Step  4: SECURITY      -- SecurityGate 3 layers
 -- CHECKPOINT 1: input validated --
Step  5: STM_UPDATE    -- add to STM, evict if full
Step  6: SEARCH        -- find nearest in KnowTree
Step  7: SILK_WALK     -- traverse silk from nearest match
 -- CHECKPOINT 2: context retrieved --
Step  8: INSTINCTS     -- run 7 instinct formulas
Step  9: EMOTION       -- compute V'(t), V''(t) for tone
Step 10: HOMEOSTASIS   -- check F(t), adjust lambda
 -- CHECKPOINT 3: evaluated --
Step 11: GENERATE      -- chain recombination -> output chain
Step 12: DECODE        -- output chain -> text (partial derivative)
 -- CHECKPOINT 4: output ready --
Step 13: LEARN         -- Hebbian update silk, STDP timing
Step 14: REFLECT       -- I7 self-evaluation, update F(t)
 -- CHECKPOINT 5: cycle complete --
```

### 22.2 Checkpoint Details

```
Checkpoint 1 (Input Validated):
  Conditions: SecurityGate passed, P_weights computed
  Failure: reject input, return error
  Rollback: none (input not processed yet)

Checkpoint 2 (Context Retrieved):
  Conditions: search found nearest node, silk walk completed
  Failure: no match found -> use WM goal as fallback
  Rollback: skip to generation with empty context

Checkpoint 3 (Evaluated):
  Conditions: instincts OK, emotion computed, homeostasis stable
  Failure: contradiction detected -> flag, continue cautiously
  Rollback: use previous turn's evaluation

Checkpoint 4 (Output Ready):
  Conditions: chain generated, decoded to valid text
  Failure: decode error -> try alternative chain
  Rollback: DNA Repair (max 3 iterations), then fallback response

Checkpoint 5 (Cycle Complete):
  Conditions: learning applied, self-evaluation done
  Failure: learning crashed -> skip, log error
  Rollback: revert silk changes from this turn
```

---

## 23. ConversationCurve: V'(t), V''(t)

### 23.1 Conversation Valence Tracking

```
V(t) = valence of conversation at time step t
     = compose(STM entries).V at step t

V'(t) = dV/dt ~ V(t) - V(t-1)  -- first derivative
       = TREND (rising/falling/stable emotion)

V''(t) = dV'/dt ~ V'(t) - V'(t-1)  -- second derivative
        = ACCELERATION (speeding up / slowing down change)
```

### 23.2 Tone Selection

```
V'(t) > 0:  Emotion RISING -> respond with encouragement
V'(t) = 0:  Emotion STABLE -> respond with matching tone
V'(t) < 0:  Emotion FALLING -> respond with empathy/support

V''(t) > 0, V'(t) > 0: Accelerating positive -> celebrate
V''(t) > 0, V'(t) < 0: Accelerating negative -> URGENT, intervene
V''(t) < 0, V'(t) > 0: Decelerating positive -> gentle, don't over-excite
V''(t) < 0, V'(t) < 0: Decelerating negative -> calming, approaching stable

Decision matrix:
  +--------+----------+----------+
  |        | V''(t)>0 | V''(t)<0 |
  +--------+----------+----------+
  |V'(t)>0 | celebrate| gentle   |
  |V'(t)<0 | URGENT   | calming  |
  +--------+----------+----------+
```

### 23.3 Silk Modulation by V'(t)

```
V'(t) controls LEARNING RATE:

  eta_effective = eta_base * (1 + |V'(t)| * modulation_factor)
  modulation_factor = 2.0

  V'(t) = 0:   eta = eta_base (normal learning)
  |V'(t)| = 3: eta = eta_base * 7 (emotional change -> learn 7x faster)

  Why? Emotional changes signal IMPORTANT events.
  Biological: amygdala enhances memory encoding during emotional events.
  Flashbulb memory: "I remember exactly where I was when..."

V'(t) also affects silk TYPE creation:
  |V'(t)| > 2: create V-dominant silk (emotional association)
  |V'(t)| < 1: create R-dominant silk (logical association)
  -> Emotional moments -> emotional connections
  -> Calm moments -> logical connections
```

---

## 24. Generation: Chain Recombination (SINH)

### 24.1 Generation Pipeline

```
Input: query (composed P_weight) + context (from silk walk) + tone (from V'(t))

Step 1: SILK WALK -- collect candidate nodes
  Start from nearest match in KnowTree
  Walk along strong silk edges
  Collect nodes along path
  Max walk length = 20 hops

Step 2: COLLECT -- gather chain fragments
  For each visited node:
    fragments.push(node.chain)
  Filter by relevance: distance_5D(fragment.compose(), query) < threshold

Step 3: COMPOSE -- build output chain
  Sort fragments by relevance score
  Concatenate with Zipf weighting:
    output_chain = compose(fragment_1, compose(fragment_2, ...))
  Apply tone modulation:
    output_V = blend(compose_V, target_V_from_curve, 0.3)

Step 4: DECODE (partial derivative) -- chain -> text
  Inverse of encode:
    For each P_weight in output chain:
      Find best matching character/word
      Use context to disambiguate (same P_weight -> multiple possible texts)

  Decode is HARDER than encode:
    Encode: 1 char -> 1 P_weight (deterministic)
    Decode: 1 P_weight -> multiple possible chars (ambiguous)
    -> Use silk context to select most appropriate
```

### 24.2 Recombination Strategies

```
Strategy 1: SEQUENTIAL (default)
  Concatenate fragments in silk walk order.
  Output follows natural flow of associations.

Strategy 2: TEMPLATE
  Use known chain patterns as templates.
  Fill slots with context-relevant nodes.
  Good for structured output (lists, explanations).

Strategy 3: INTERPOLATION
  Catmull-Rom between key points (Section 9.6)
  Generate smooth transition chains.
  Good for creative, exploratory output.

Strategy 4: GENETIC RECOMBINATION
  Two-point crossover between parent chains:
    parent_A = [a1, a2, a3, | a4, a5, | a6, a7]
    parent_B = [b1, b2, b3, | b4, b5, | b6, b7]
    child    = [a1, a2, a3, | b4, b5, | a6, a7]

  Mutation: random P_weight perturbation (+/-1 in one dimension)
  Selection: quality_fn (Section 19.2) picks best child

  Used when: creative generation, exploration
  Not used when: factual recall (use Strategy 1)
```

---

# PHAN V: SEARCH + CLASSIFICATION

---

## 25. Nearest Neighbor trong 5D

### 25.1 Direct Lookup Table

```
Table: array[32768] of NodeId
Size: 32,768 * 4 bytes = 128 KB (hoac 256 KB voi pointer)

Cach dung:
  node = table[P_weight]
  If node != NULL -> exact match found, O(1)
  If node == NULL -> no exact match -> fall through to approximate search

Coverage:
  Voi 300 nodes: 300/32768 = 0.9% filled
  Voi 10,000 nodes: 10000/32768 = 30.5% filled

  -> NHIEU misses -> can approximate search backup
  -> But when hit: FASTEST possible (1 array access)
```

### 25.2 Brute Force Scan (Baseline)

```
nearest_brute(query, nodes):
  best = NULL
  best_dist = INFINITY
  for node in nodes:
    d = distance_5D(query, node.P_weight)
    if d < best_dist:
      best = node
      best_dist = d
  return best

Complexity: O(n) -- scan all nodes
Practical: fine for n < 1,000

Voi Nox hien tai (~300 nodes): brute force = 300 distance computations
Distance computation = ~20 instructions (5 subtracts + 5 squares + 5 divides + sqrt)
Total: ~6,000 instructions ~ microseconds
-> FINE for now, optimize later
```

### 25.3 Algorithm Comparison Table

```
| Method              | Build       | Query          | Best For          |
|---------------------|-------------|----------------|-------------------|
| Lookup table (256KB)| O(n)        | O(1)           | Exact match       |
| Multi-level bucket  | O(n)        | O(bucket_size) | Neighborhood      |
| VP-tree             | O(n log n)  | O(log n)       | Any metric, exact |
| HNSW                | O(n log n)  | O(log n)       | >10K, approximate |
| KD-tree             | O(n log n)  | O(log n)       | Low-dim Euclidean |
| Ball tree           | O(n log n)  | O(log n)       | Non-axis clusters |
| Brute force         | O(1)        | O(n)           | n < 1000          |
| A*                  | -           | O(b^d)         | Goal-directed     |
| Spreading activation| -           | O(steps*degree)| Multi-path        |
```

---

## 26. VP-Tree / KD-Tree / HNSW

### 26.1 VP-Tree (Yianilos, 1993)

```
Chi tiet xem Section 10.4.

VP-Tree BEST cho Nox vi:
  [OK] Works in ANY metric space (chi can distance function)
  [OK] Exact nearest neighbor
  [OK] O(log n) search
  [OK] Simple to implement (~100 LOC)
  [OK] Good for d=5 dimensions (low enough to avoid curse)

Nox distance function:
  d(a, b) = sqrt(sum of (dim_a - dim_b)^2 / max_dim^2 for each dim)

  VP-Tree chi can:
    1. distance(a, b) -> f32
    2. Metric properties: d(a,a)=0, d(a,b)=d(b,a), triangle inequality

  Nox's 5D Euclidean distance satisfies all three -> VP-Tree valid.
```

### 26.2 KD-Tree (Bentley, 1975)

```
Nguon: Bentley, J.L. (1975). "Multidimensional binary search trees used
       for associative searching." Communications of the ACM, 18(9), 509-517.

KD-Tree = binary tree, splits on alternating dimensions.

Build:
  function build(points, depth):
    if empty: return NULL
    dim = depth % 5  -- cycle through S, R, V, A, T
    sort points by dim
    median = points[len/2]
    return Node {
      point: median,
      left: build(points[:len/2], depth+1),
      right: build(points[len/2+1:], depth+1)
    }

Search:
  function nearest(node, query, depth, best):
    if node == NULL: return best
    dim = depth % 5
    d = distance_5D(query, node.point)
    if d < best.dist: best = (node, d)

    -- Search closer child first
    if query[dim] < node.point[dim]:
      best = nearest(node.left, query, depth+1, best)
      if |query[dim] - node.point[dim]| < best.dist:
        best = nearest(node.right, query, depth+1, best)
    else: (mirror)

Complexity: O(log n) average, O(n^(1-1/d)) worst case
d=5: worst case O(n^0.8) -- acceptable
d>20: curse of dimensionality -> KD-tree degrades to brute force
```

### 26.3 Ball Tree (Omohundro, 1989)

```
Nguon: Omohundro, S.M. (1989). "Five Balltree Construction Algorithms."
       ICSI Technical Report TR-89-063.

Ball Tree = binary tree where each node is a BALL (center + radius).

Build:
  1. Find the point furthest from centroid -> point A
  2. Find the point furthest from A -> point B
  3. Split: points closer to A -> left, closer to B -> right
  4. Compute bounding ball for each child
  5. Recurse

Search:
  Prune: if distance(query, ball.center) - ball.radius > best_dist -> skip

Advantage over KD-Tree:
  Better for non-axis-aligned clusters (KD-Tree splits on axis)
  Ball boundaries are more adaptive

Trong Nox: Ball tree is a valid alternative but VP-Tree is simpler
and has comparable performance for d=5.
```

### 26.4 HNSW Implementation Details

```
Chi tiet xem Section 10.5.

Distance cache:
  Moi HNSW search goi distance_5D nhieu lan.
  Cache results: HashMap<(NodeId, NodeId), f32>
  Hit rate: ~40% trong beam search (same nodes revisited)

Dynamic insertion:
  HNSW supports online insertion (khong can rebuild).
  Insert new learned node: O(log n) * ef_construction
  -> Real-time learning compatible

Deletion:
  Mark as deleted (lazy deletion).
  Periodic rebuild to reclaim.

  In Nox: decay -> node dies -> mark deleted in HNSW
  Rebuild during dream cycle (Section 16)
```

---

## 27. Silk Walk: Graph Traversal Co Huong

### 27.1 Dijkstra's Algorithm for Weighted Silk Walk

```
Dijkstra (1959) -- shortest path in weighted graph.

silk_walk(start, goal_P_weight, max_hops):
  dist = {start: 0}
  prev = {start: NULL}
  queue = MinHeap([(0, start)])

  while queue not empty:
    (d, u) = queue.pop()

    if distance_5D(u.P_weight, goal_P_weight) < threshold:
      return reconstruct_path(prev, u)

    for (v, silk) in silk_neighbors(u):
      -- Edge weight = inverse of silk strength (strong = cheap)
      edge_cost = 1.0 / (silk.strength + epsilon)
      new_dist = d + edge_cost

      if new_dist < dist.get(v, INFINITY):
        dist[v] = new_dist
        prev[v] = u
        queue.push((new_dist, v))

  return best_path_found

Complexity: O((N + E) log N) with binary heap
N = nodes visited, E = silk edges traversed
```

### 27.2 A* with 5D Distance Heuristic

```
A* = Dijkstra + heuristic (estimated remaining cost).

a_star(start, goal_P_weight, max_hops):
  g = {start: 0}                          -- actual cost from start
  f = {start: h(start, goal_P_weight)}    -- estimated total cost

  h(node, goal) = distance_5D(node.P_weight, goal) * weight_factor
  -- ADMISSIBLE: h(n) <= actual cost (never overestimates)
  -- If weight_factor = 1.0 and silk costs >= distance: admissible

  queue = MinHeap([(f[start], start)])

  while queue not empty:
    (_, u) = queue.pop()

    if distance_5D(u.P_weight, goal_P_weight) < threshold:
      return path

    for (v, silk) in silk_neighbors(u):
      tentative_g = g[u] + 1.0 / (silk.strength + epsilon)
      if tentative_g < g.get(v, INFINITY):
        g[v] = tentative_g
        f[v] = tentative_g + h(v, goal_P_weight)
        queue.push((f[v], v))

A* vs Dijkstra:
  Dijkstra explores in ALL directions equally.
  A* biased toward goal -> fewer nodes explored.
  Nox: A* saves ~50% node visits vs Dijkstra (empirical estimate).
```

### 27.3 Spreading Activation (Collins & Loftus, 1975)

```
Alternative to explicit path search.

activation(node, t) = Sum activation(neighbor, t-1) * silk_strength(neighbor -> node)

Process:
  1. Set activation(start) = 1.0
  2. For each step:
     For each node with activation > 0:
       Spread to neighbors: neighbor.activation += this.activation * silk.strength
       Decay: this.activation *= 0.8
  3. After k steps: collect all nodes with activation > threshold
  4. Return as context

Advantage: multi-path (finds multiple relevant concepts simultaneously)
Disadvantage: no single "best path" -- diffuse results
Use when: broad context retrieval (not specific search)
```

---

## 28. Clustering / Self-Organizing Maps

### 28.1 K-Medoids (Kaufman & Rousseeuw, 1987)

```
Nguon: Kaufman, L. & Rousseeuw, P.J. (1987). "Clustering by Means of
       Medoids." In Statistical Data Analysis Based on the L1-Norm, 405-416.

K-Medoids vs K-Means:
  K-Means:   center = mean of cluster (may not be a real data point)
  K-Medoids: center = actual data point (medoid)

  Nox needs K-Medoids because:
    P_weights are DISCRETE (u16). Mean of two P_weights may not be valid.
    Medoid = always a real node in KnowTree.

PAM (Partitioning Around Medoids):
  1. Initialize: select k random nodes as medoids
  2. ASSIGN: each node -> nearest medoid
  3. UPDATE: for each cluster, try EVERY node as new medoid
     Keep the one that minimizes total distance within cluster
  4. Repeat 2-3 until convergence

  Complexity: O(k * (n-k)^2 * iterations)
  Expensive! But k is small (3-10 clusters) and n is manageable.
```

### 28.2 SOM -- Self-Organizing Map (Kohonen, 1982)

```
Nguon: Kohonen, T. (1982). "Self-organized formation of topologically
       correct feature maps." Biological Cybernetics, 43(1), 59-69.

SOM = 2D grid of neurons, each with weight vector in 5D.
Maps 5D P_weight space -> 2D visualization.

Algorithm:
  1. Initialize: grid NxM, each cell has random 5D weight vector
  2. For each input P_weight x:
     a. Find BMU (Best Matching Unit): neuron with closest weight
        bmu = argmin_i ||w_i - x||
     b. Update BMU and neighbors:
        w_i(t+1) = w_i(t) + alpha(t) * h(i, bmu, t) * (x - w_i(t))

        alpha(t) = learning rate, decreases over time
        h(i, bmu, t) = neighborhood function:
          h = exp(-||pos_i - pos_bmu||^2 / (2*sigma(t)^2))
          sigma(t) = neighborhood radius, decreases over time
  3. Repeat for all inputs, multiple epochs

Result: 2D map where nearby neurons = similar 5D P_weights.
  -> Visual map of Nox's knowledge space
  -> Clusters visible as colored regions

Parameters:
  Grid: 20x20 (400 neurons) for ~1000 nodes
  alpha: 0.5 -> 0.01 over 1000 epochs
  sigma: 10 -> 1 over 1000 epochs
```

### 28.3 Online K-Means

```
Standard K-Means requires multiple passes over all data.
Nox learns ONLINE (one input at a time).

Online K-Means (MacQueen variant):
  For each new P_weight x:
    1. Find nearest cluster center c_k
    2. Update: c_k = c_k + (x - c_k) / n_k
       where n_k = number of points in cluster k

  -> No need to store all points
  -> O(k) per update
  -> Converges to same result as batch K-Means (asymptotically)

Mini-batch K-Means (Sculley, 2010):
  Collect batch of b inputs, then update.
  b = 32 (= STM size) -- natural batch from STM
```

### 28.4 Growing Neural Gas (Fritzke, 1994)

```
Nguon: Fritzke, B. (1994). "A Growing Neural Gas Network Learns
       Topologies." Advances in Neural Information Processing Systems, 7.

GNG = topology-learning algorithm. Grows network to fit data.

Key idea: START SMALL, grow as needed. Perfect for Nox's incremental learning.

Algorithm:
  1. Start with 2 nodes, 1 edge
  2. For each input x:
     a. Find nearest (s1) and second-nearest (s2) nodes
     b. Increment age of all edges from s1
     c. Update error: delta_error(s1) += ||x - s1||^2
     d. Move s1 toward x:  s1 += eps_b * (x - s1)     (eps_b = 0.2)
     e. Move s1's neighbors: n += eps_n * (x - n)       (eps_n = 0.006)
     f. If s1-s2 edge exists: reset age to 0. Else: create edge.
     g. Remove edges with age > age_max (default 100)
     h. Every lambda insertions (default 100):
        - Find node q with highest error
        - Find neighbor f of q with highest error
        - Insert new node r between q and f
        - r.weight = (q.weight + f.weight) / 2
        - Remove edge q-f, add edges q-r and r-f
        - q.error *= alpha (0.5), f.error *= alpha, r.error = q.error
     i. Decrease all errors: error *= d (0.995)

Why GNG for Nox:
  - No need to specify k (number of clusters) in advance
  - Topology learned from data (edges = silk approximation)
  - Grows incrementally (new nodes added as needed)
  - Topology pruning (old edges removed = decay analog)
```

---

## 29. Bellman Equation cho Search Toi Uu

### 29.1 Bellman Equation

```
Richard Bellman (1957): "Dynamic Programming."

V*(s) = max_a [R(s,a) + gamma * Sum P(s'|s,a) * V*(s')]

  V*(s) = optimal value of state s
  a     = action (which silk edge to follow)
  R(s,a) = immediate reward
  gamma = discount factor (0 < gamma < 1)
  P(s'|s,a) = transition probability

In Nox's graph:
  state s = current node in KnowTree
  action a = follow silk edge to neighbor
  R(s,a) = -distance_5D(neighbor, goal) + silk_strength(s->neighbor)
           (negative distance = reward for getting closer)
           (silk strength = reward for following strong paths)
  gamma = 0.9 (slight discount for longer paths)
  P(s'|s,a) = 1.0 (deterministic graph traversal)
```

### 29.2 Q-Learning for Optimal Paths

```
Q-Learning (Watkins & Dayan, 1992):
  Q(s, a) <- Q(s, a) + alpha * [R(s,a) + gamma * max_a' Q(s', a') - Q(s, a)]

  alpha = learning rate (0.1)
  Store Q-values on silk edges:
    silk.q_value = Q(from_node, follow_this_silk)

Online Q-Learning in Nox:
  After each silk walk that reaches goal:
    For each edge (s, a, s') in path:
      silk.q_value += alpha * (R + gamma * max Q(s', .) - silk.q_value)

  After enough walks: Q-values converge -> optimal paths known
  -> Future walks: just follow max Q-value at each node = greedy optimal

  This is MODEL-FREE: no need to know graph structure in advance.
  Learns from experience: paths that work -> Q increases -> preferred.
```

---

# PHAN VI: AGENT + SELF-EVOLUTION

---

## 30. Agent Cycle: Perceive -> Think -> Act -> Verify

### 30.1 PTAV Loop

```
Every interaction = one PTAV cycle.

PERCEIVE:
  1. Receive input (text, sensor data, internal signal)
  2. Encode to P_weight chain
  3. SecurityGate check
  4. Update STM

THINK:
  5. Search KnowTree for relevant knowledge
  6. Silk walk for context
  7. Run 7 instincts
  8. Evaluate ConversationCurve (V'(t), V''(t))
  9. Homeostasis check (F(t))

ACT:
  10. Generate output chain (recombination)
  11. Decode to text
  12. Execute actions (if agent mode: file operations, API calls, etc.)

VERIFY:
  13. Self-evaluate: I7 reflection score
  14. Compare predicted vs actual outcome
  15. Learn: Hebbian update, STDP, decay
  16. Update F(t) for homeostasis

Cycle time budget:
  Perceive: ~10% (encoding fast)
  Think: ~40% (search + evaluation = most work)
  Act: ~30% (generation)
  Verify: ~20% (learning + reflection)
```

### 30.2 Interrupt Handling

```
Normal cycle = sequential PTAV.
Interrupts bypass normal flow:

HIGH PRIORITY:
  SecurityGate BLOCK -> immediate halt + alert
  System error -> halt + DNA Repair

MEDIUM PRIORITY:
  New input during generation -> queue, finish current, then process
  Homeostasis alarm (F(t) >> threshold) -> pause, re-evaluate

LOW PRIORITY:
  Dream cycle trigger -> defer to idle time
  QR verification due -> batch during dream
```

---

## 31. Self-Model: Knowledge Map

### 31.1 Per-Domain Knowledge Assessment

```
Self-model = Nox's map of WHAT IT KNOWS and HOW WELL.

For each domain (cluster in KnowTree):
  struct DomainModel {
    center: P_weight,         -- centroid of domain
    node_count: u32,          -- how many nodes
    avg_silk_strength: f32,   -- how well-connected
    avg_confidence: f32,      -- QR confidence average
    coverage: f32,            -- estimated % of domain covered
    last_updated: u64,        -- freshness
  }

Coverage estimation:
  coverage ~ node_count / estimated_domain_size

Confidence mapping:
  "I know X well"    -> high node_count + high silk_strength + high QR confidence
  "I've heard of X"  -> low node_count + low silk_strength
  "I don't know X"   -> no nodes in that P_weight region

Self-model UPDATE:
  After each PTAV cycle, update domain models for touched domains.
  After each dream cycle, re-cluster and update all domain models.
```

### 31.2 Uncertainty Quantification

```
For each query, Nox can estimate its own uncertainty:

  uncertainty(query) = 1 - max_silk_strength_to_answer / max_possible

  Low uncertainty (< 0.3): "I'm confident"
  Medium uncertainty (0.3-0.7): "I think so, but not sure"
  High uncertainty (> 0.7): "I don't know enough about this"

Use:
  - Decide whether to answer or ask for clarification
  - Modulate confidence in output
  - Drive curiosity (I6) toward high-uncertainty areas
```

---

## 32. Goal System: Curiosity-Driven

### 32.1 Intrinsic Motivation

```
Nox's primary drive: CURIOSITY.

Novelty score:
  novelty(input) = min distance from input to any known node

  High novelty -> high curiosity -> prioritize learning
  Low novelty -> low curiosity -> use existing knowledge

Information Gain:
  IG(action) = H(belief_before) - E[H(belief_after | action)]

  H = entropy of belief distribution over possible states
  Action with highest IG -> most informative -> preferred

  Practical approximation:
    IG ~ number of new silk connections created by action
    More new connections = more structural information gained
```

### 32.2 Goal Stack

```
Goals organized as stack (LIFO with priority override):

  goal_stack = [
    {goal: "learn_X", priority: 5, deadline: None},
    {goal: "answer_query", priority: 8, deadline: now+5s},
    {goal: "explore_domain_Y", priority: 3, deadline: None},
  ]

  Processing:
    1. Sort by priority (highest first)
    2. If deadline approaching -> boost priority
    3. Pop top goal -> set as WM slot[2]
    4. PTAV cycle oriented toward goal
    5. After completion -> pop, next goal

  Goal generation:
    External: user asks question -> "answer_query" goal
    Internal: high curiosity score -> "explore_X" goal
    Homeostatic: F(t) high -> "reduce_uncertainty" goal
    Dream: cluster analysis -> "consolidate_domain" goal
```

---

## 33. Self-Evolution: 6-Phase Cycle

### 33.1 The Six Phases

```
Phase 1: MEASURE
  Collect metrics:
    - Prediction accuracy (how often correct?)
    - Response quality (self-evaluation I7)
    - Knowledge coverage (self-model assessment)
    - Silk graph health (density, connectivity, decay rate)
    - Pipeline timing (bottlenecks?)

Phase 2: IDENTIFY
  Find weak points:
    - Domains with low coverage
    - Silk clusters with poor connectivity
    - Frequent prediction failures (high F(t))
    - Slow pipeline stages

Phase 3: INSPECT
  Deep analysis of identified weak points:
    - Why is prediction failing? (examine specific cases)
    - What knowledge is missing? (gap analysis)
    - Which silk connections are wrong? (contradiction check)
    - What patterns repeat in failures?

Phase 4: MODIFY
  Make changes:
    - Adjust parameters (learning rate, decay constant, beam width)
    - Restructure KnowTree (merge clusters, split overloaded nodes)
    - Create new silk connections (bridge isolated clusters)
    - Modify pipeline (add/remove processing steps)

  BOUNDED: max 3 changes per cycle (DNA Repair principle)

Phase 5: TEST
  Evaluate modifications:
    - Re-run recent inputs with new parameters
    - Compare output quality: before vs after
    - Check for regressions (things that got WORSE)
    - Validate constraints (security, consistency)

Phase 6: COMPARE
  Decision:
    If metrics improved AND no regressions -> KEEP changes
    If metrics same or worse -> ROLLBACK

  Log all results for future reference.
  Update self-model with new capabilities/limitations.

  Schedule next cycle: based on metric trajectory.
    Metrics improving -> longer interval (things are fine)
    Metrics declining -> shorter interval (need attention)
```

### 33.2 Self-Modification Boundaries

```
NEVER modify:
  - SecurityGate thresholds (safety critical)
  - 7 instinct formulas (hardcoded by design)
  - QR proven knowledge (append-only)
  - PTAV cycle structure (fundamental architecture)

CAN modify:
  - Learning rate eta
  - Decay constant tau
  - Beam width k
  - STM capacity
  - Silk creation threshold
  - Dream cycle frequency
  - Clustering parameters
  - Generation strategy selection weights
```

---

## 34. Persistence: 3-Tier Storage

### 34.1 Three Tiers

```
Tier 1: RAM (volatile)
  What: STM, WM, current pipeline state, HNSW index
  Speed: nanoseconds
  Durability: lost on restart
  Size: ~10-50 MB

Tier 2: DISK (persistent)
  What: KnowTree, silk graph, QR store, self-model
  Speed: microseconds (SSD)
  Durability: survives restart
  Size: ~100 MB - 1 GB
  Format: binary serialized (Olang native format)

Tier 3: LOG (append-only archive)
  What: all interactions, all changes, full history
  Speed: milliseconds (sequential write)
  Durability: permanent record
  Size: unbounded (rotate/compress old logs)
  Format: structured log entries

Interaction:
  Tier 1 -> Tier 2: periodic flush (every N cycles or on shutdown)
  Tier 2 -> Tier 3: every modification logged
  Tier 3 -> Tier 2: recovery after crash
  Tier 1 <- Tier 2: load on startup
```

### 34.2 Persistence Protocol

```
Save:
  1. Serialize KnowTree to binary format
  2. Serialize silk graph (adjacency list + weights)
  3. Serialize QR store (append-only file)
  4. Write checkpoint marker with timestamp + hash
  5. Flush to disk

Load:
  1. Find latest checkpoint
  2. Verify hash (corruption check)
  3. Deserialize KnowTree, silk, QR
  4. Rebuild HNSW index from KnowTree
  5. Load STM/WM from last state (if available)
  6. Resume

Recovery (crash):
  1. Find latest VALID checkpoint (hash OK)
  2. Load from that checkpoint
  3. Replay log entries AFTER checkpoint
  4. Rebuild to consistent state

  Worst case: lose last N cycles (between checkpoints)
  Checkpoint frequency: every 100 cycles or 5 minutes
```

---

# PHAN VII: NGHIEN CUU NEN TANG

---

## 35. Russell 1980: Circumplex Model of Affect

```
Paper: Russell, J.A. (1980). "A circumplex model of affect."
       Journal of Personality and Social Psychology, 39(6), 1161-1178.

Key finding: ALL emotional states can be mapped to 2D circular space.
  X-axis: Valence (pleasure <-> displeasure)
  Y-axis: Arousal (activation <-> deactivation)

Methodology:
  - 28 emotion words rated by subjects
  - Multidimensional scaling -> 2D circular structure
  - Adjacent emotions on circle = similar
  - Opposite emotions = 180 degrees apart

Impact on Nox:
  V and A dimensions directly from this model.
  Every P_weight contains V (valence) and A (arousal).
  Conversation tracking uses V(t) and A(t) trajectories.
```

---

## 36. NRC-VAD: Best-Worst Scaling (Mohammad, 2018)

```
Paper: Mohammad, S.M. (2018). "Obtaining Reliable Human Ratings of
       Valence, Arousal, and Dominance for 20,000 English Words."
       Proceedings of the 56th Annual Meeting of the Association for
       Computational Linguistics (ACL 2018), 174-184.

Key contributions:
  - 20,000 English words with V, A, D scores
  - Best-Worst Scaling methodology (more reliable than Likert)
  - Split-half reliability: r = 0.95
  - Extended to 55,000+ words in later versions

Methodology:
  1. Present 4 words to annotators
  2. "Which is MOST associated with happiness? LEAST?"
  3. 778,085 best-worst annotations total
  4. Score = (times_best - times_worst) / total_judgments
  5. Normalize to [0, 1]

Use in Nox:
  NRC-VAD = bootstrap data for V and A dimensions.
  Cold start: use NRC-VAD lookup.
  Warm: silk connections provide V/A from context.
  Hot: NRC-VAD unnecessary, silk sufficient.

Dataset URL: https://saifmohammad.com/WebPages/nrc-vad.html
```

---

## 37. ANEW: Bradley & Lang (1999)

```
Paper: Bradley, M.M. & Lang, P.J. (1999). "Affective Norms for English
       Words (ANEW): Instruction Manual and Affective Ratings."
       University of Florida, NIMH Center for the Study of Emotion and
       Attention, Technical Report C-1.

Key contributions:
  - 1,034 English words with Valence, Arousal, Dominance ratings
  - Self-Assessment Manikin (SAM) -- visual rating scale
  - Standardized methodology for emotion word research
  - Foundation for ALL subsequent word-emotion datasets

Extended versions:
  - Warriner et al. (2013): expanded to 13,915 words
  - Moors et al. (2013): Dutch ANEW (4,300 words)

Connection to NRC-VAD:
  ANEW = original (1,034 words, SAM methodology)
  NRC-VAD = modern replacement (20,000+ words, BWS methodology)
  Correlation between ANEW and NRC-VAD: r ~ 0.95 (highly consistent)
```

---

## 38. Mehrabian & Russell 1974: PAD

```
Paper: Mehrabian, A. & Russell, J.A. (1974). "An Approach to
       Environmental Psychology." Cambridge, MA: MIT Press.

PAD = Pleasure, Arousal, Dominance -- 3D emotion model.

  P = Pleasure (positive <-> negative)    -- maps to V
  A = Arousal (excited <-> calm)           -- maps to A
  D = Dominance (in-control <-> submissive) -- maps to... ?

Nox uses V (=P) and A directly.
D (Dominance) not explicitly encoded in P_weight.
  But D information partially captured by:
    R dimension (relational power)
    Silk structure (dominant nodes = more connections)

Historical significance:
  PAD (1974) -> Circumplex (1980) -> NRC-VAD (2018)
  Each builds on previous. Nox inherits the full lineage.
```

---

## 39. Friston 2010: Free Energy Principle

```
Paper: Friston, K. (2010). "The free-energy principle: a unified brain
       theory?" Nature Reviews Neuroscience, 11(2), 127-138.

Key claims:
  1. ALL adaptive systems minimize variational free energy
  2. Free energy F >= surprise (negative log evidence)
  3. Minimizing F = minimizing prediction error
  4. Two routes: update model (perception) or change input (action)

Mathematical framework:
  F = E_Q[ln Q(theta) - ln P(data, theta)]
    = DKL[Q(theta) || P(theta)] - E_Q[ln P(data | theta)]
    = Complexity - Accuracy

  Good model: low complexity + high accuracy = low F

Related works:
  - Friston, K. (2005). "A theory of cortical responses." Phil Trans
    Royal Society B, 360(1456), 815-836.
  - Friston, K. et al. (2017). "Active Inference, Curiosity and Insight."
    Neural Computation, 29(10), 2633-2683.
  - Parr, T., Pezzulo, G., & Friston, K.J. (2022). "Active Inference:
    The Free Energy Principle in Mind, Brain, and Behavior." MIT Press.

Use in Nox: Section 17 (Homeostasis) -- F(t) drives learning rate lambda(t).
```

---

## 40. Hebb 1949: Organization of Behavior

```
Paper: Hebb, D.O. (1949). "The Organization of Behavior: A
       Neuropsychological Theory." New York: Wiley.

The most influential neuroscience book of the 20th century.

Key postulate (Hebb's Rule):
  "When an axon of cell A is near enough to excite a cell B and
  repeatedly or persistently takes part in firing it, some growth
  process or metabolic change takes place in one or both cells such
  that A's efficiency, as one of the cells firing B, is increased."

Simplified: "Neurons that fire together, wire together."

Impact:
  - Foundation of ALL connectionist / neural network learning
  - Led to: Perceptron, Backpropagation, Deep Learning
  - Led to: Oja's rule, BCM theory, STDP
  - Led to: Hopfield networks, Boltzmann machines

Use in Nox: Section 14 -- Hebbian silk learning.
```

---

## 41. Collins & Loftus 1975: Spreading Activation

```
Paper: Collins, A.M. & Loftus, E.F. (1975). "A spreading-activation
       theory of semantic processing." Psychological Review, 82(6),
       407-428.

Key model:
  Semantic memory = network of concepts connected by links.
  Activating one concept -> activation SPREADS to connected concepts.
  Strength of spread depends on link strength.
  Activation decays with distance.

  activation(node, t) = Sum activation(neighbor, t-1) * link_strength

Experimental evidence:
  - Priming: "doctor" heard first -> "nurse" recognized faster
  - Semantic distance: "bird" -> "canary" (fast) vs "bird" -> "penguin" (slow)
  - Fan effect: more connections -> each weaker

Use in Nox: Silk walk = spreading activation (Section 27.3).
```

---

## 42. Shannon 1948: Information Theory

```
Paper: Shannon, C.E. (1948). "A Mathematical Theory of Communication."
       Bell System Technical Journal, 27(3), 379-423; 27(4), 623-656.

Foundational concepts:

Entropy:
  H(X) = -Sum P(x) * log2 P(x)
  = average information content = average surprise
  = minimum bits needed to encode X

Mutual Information:
  I(X;Y) = H(X) - H(X|Y)
  = how much knowing Y tells us about X

Channel Capacity:
  C = max_{P(X)} I(X;Y)
  = maximum reliable information rate

Use in Nox:
  - Entropy of P_weight distribution -> knowledge diversity
  - Mutual information between silk-connected nodes -> silk quality
  - Information gain -> curiosity score (Section 32.1)
  - Compression of chains (Section 9.2) -> Shannon coding bounds
  - Optimal encoding: P_weight bit allocation follows source coding theorem
```

---

## 43. Fibonacci / phi trong Tu Nhien + Toi Uu

```
Golden Ratio:
  phi = (1 + sqrt(5)) / 2 ~ 1.6180339887...
  phi_inv = phi - 1 = (sqrt(5) - 1) / 2 ~ 0.6180339887...
  phi^2 = phi + 1
  phi_inv = 1/phi

Fibonacci Sequence:
  F(0) = 0, F(1) = 1
  F(n) = F(n-1) + F(n-2)
  lim F(n)/F(n+1) = phi_inv

Occurrences in Nox:
  1. Decay constant: w(t) = w0 * phi_inv^(t/tau) (Section 15.1)
  2. Fire threshold: Fibonacci sequence for QR promotion (Section 12.3)
  3. Homeostasis threshold: F(t) compared to phi_inv (Section 17.2)
  4. SDF beauty metric: phi ratio in geometric analysis (Section 3.4)

Why phi appears everywhere:
  - Most irrational number (hardest to approximate by rationals)
  - Optimal packing (sunflower seeds, 137.5 degree angle)
  - Fibonacci search: optimal for unimodal function minimization
  - Zeckendorf's theorem: every positive integer = unique sum of
    non-consecutive Fibonacci numbers
  - Self-similar: phi = 1 + 1/phi (fractal property)

Related: Kiefer, J. (1953). "Sequential minimax search for a maximum."
  Proceedings of the American Mathematical Society, 4(3), 502-506.
  -- Proves Fibonacci search is OPTIMAL for unimodal search.
```

---

## 44. SDF Rendering: Valve 2007, msdfgen

```
Paper: Green, C. (2007). "Improved Alpha-Tested Magnification for Vector
       Textures and Special Effects." Valve Corporation.
       (Presented at SIGGRAPH 2007 Course)

Key idea:
  Store glyph as signed distance field in texture.
  GPU renders by thresholding: if sdf(pixel) < 0 -> inside -> draw.
  Smooth edges at ANY zoom level (no pixelation).

Multi-channel SDF (msdfgen):
  Chlumsky, V. (2015). "Shape decomposition for multi-channel distance
  fields." Master's thesis, Czech Technical University in Prague.

  3 channels (RGB) each store distance to different edge segments.
  Median of 3 -> sharp corners preserved.
  Better quality than single-channel SDF.

Dead Reckoning (Grevera, 2004):
  Grevera, G.J. (2004). "The 'dead reckoning' signed distance transform."
  Computer Vision and Image Understanding, 95(3), 317-333.

  Fast approximate SDF computation:
    Two-pass: forward + backward scan
    O(n^2) for NxN image
    Approximation error < 1 pixel

Felzenszwalb & Huttenlocher (2012):
  Felzenszwalb, P.F. & Huttenlocher, D.P. (2012). "Distance Transforms
  of Sampled Functions." Theory of Computing, 8(1), 415-428.

  EXACT Euclidean distance transform in O(n) per row.
  Uses parabolic envelope intersection.
  State of the art for SDF computation.

Use in Nox: S dimension = SDF complexity of Unicode glyph (Section 1).
```

---

## 45. HNSW: Malkov & Yashunin 2018

```
Paper: Malkov, Y.A. & Yashunin, D.A. (2018). "Efficient and robust
       approximate nearest neighbor using Hierarchical Navigable Small
       World graphs." IEEE Transactions on Pattern Analysis and Machine
       Intelligence, 42(4), 824-836. (arXiv:1603.09320)

Key contribution:
  Multi-layer graph for approximate nearest neighbor search.
  O(log n) query time, nearly independent of dimensionality.
  State of the art for ANN in high-dimensional spaces.

Prior work:
  - NSW: Malkov, Y.A. et al. (2014). "Approximate nearest neighbor
    algorithm based on navigable small world graphs." Information Systems,
    45, 61-68.
  - Skip list: Pugh, W. (1990). "Skip lists: a probabilistic alternative
    to balanced trees." Communications of the ACM, 33(6), 668-676.

Use in Nox: Section 10.5, 26.4 -- approximate NN for KnowTree >10K nodes.
```

---

## 46. Unicode Standard + Linguistic Resources

```
Unicode Standard (latest: v16.0, 2024):
  Chapter 2: General Structure -- encoding forms, allocation
  Chapter 4: Character Properties -- General_Category, Script, etc.
  UnicodeData.txt: machine-readable property database

  Key property for Nox: General_Category -> R dimension
  https://www.unicode.org/reports/tr44/ (Unicode Character Database)

UTR #25: Unicode Support for Mathematics:
  https://www.unicode.org/reports/tr25/
  Classification of mathematical symbols.
  Maps to R.0-R.2 sub-classifiers.

Emoji resources:
  Novak, P.K., Smailovic, J., Sluban, B., & Mozetic, I. (2015).
    "Sentiment of Emojis." PLoS ONE, 10(12), e0144296.
    -- Sentiment scores for 751 emojis. Maps to V dimension.

  Rodrigues, D., Prada, M., Gaspar, R., Garrido, M.V., & Lopes, D.
    (2018). "Lisbon Emoji and Emoticon Database (LEED): Norms for emoji
    and emoticons in seven evaluative dimensions." Behavior Research
    Methods, 50(1), 392-405.
    -- V, A, D norms for emojis. Direct input to Nox's emoticon encoding.

Punctuation:
  Nunberg, G. (1990). "The Linguistics of Punctuation." CSLI Lecture
  Notes. Stanford: CSLI Publications.
  -- Punctuation as discourse structure markers.
  -- Maps to R.6 (punctuation sub-classifier) and A dimension.

WordNet:
  Miller, G.A. (1995). "WordNet: A Lexical Database for English."
  Communications of the ACM, 38(11), 39-41.
  -- Lexical relations: hypernym, hyponym, meronym, synonym, antonym.
  -- Maps to silk types (Section 11.2) and R dimension (Section 2.3).

Zipf's Law:
  Zipf, G.K. (1949). "Human Behavior and the Principle of Least Effort."
  Addison-Wesley.
  -- Word frequency rank * frequency ~ constant.
  -- Used in compose weighting (Section 7.1): w_i = 1000/(i+1).
```

---

## 47. Additional References

```
Oja, E. (1982). "Simplified neuron model as a principal component
  analyzer." Journal of Mathematical Biology, 15(3), 267-273.

Bienenstock, E.L., Cooper, L.N., & Munro, P.W. (1982). "Theory for
  the development of neuron selectivity." Journal of Neuroscience,
  2(1), 32-48.

Bi, G. & Poo, M. (1998). "Synaptic modifications in cultured
  hippocampal neurons." Journal of Neuroscience, 18(24), 10464-10472.

Foldiak, P. (1990). "Forming sparse representations by local
  anti-Hebbian learning." Biological Cybernetics, 64, 165-170.

Watkins, C.J.C.H. & Dayan, P. (1992). "Q-Learning." Machine Learning,
  8(3-4), 279-292.

Bentley, J.L. (1975). "Multidimensional binary search trees used for
  associative searching." Communications of the ACM, 18(9), 509-517.

Omohundro, S.M. (1989). "Five Balltree Construction Algorithms."
  ICSI Technical Report TR-89-063.

Kaufman, L. & Rousseeuw, P.J. (1987). "Clustering by Means of
  Medoids." In Statistical Data Analysis Based on the L1-Norm, 405-416.

Fritzke, B. (1994). "A Growing Neural Gas Network Learns Topologies."
  NIPS 7, 625-632.

Kohonen, T. (1982). "Self-organized formation of topologically correct
  feature maps." Biological Cybernetics, 43(1), 59-69.

Ebbinghaus, H. (1885). "Uber das Gedachtnis." Leipzig: Duncker & Humblot.

Wickelgren, W.A. (1974). "Single-trace fragility theory of memory
  dynamics." Memory & Cognition, 2(4), 775-780.

Wixted, J.T. & Ebbesen, E.B. (1991). "On the form of forgetting."
  Psychological Science, 2(6), 409-415.

De Castro, L.N. & Von Zuben, F.J. (2002). "Learning and optimization
  using the clonal selection principle." IEEE Transactions on
  Evolutionary Computation, 6(3), 239-251.

Altschul, S.F. et al. (1990). "Basic Local Alignment Search Tool."
  Journal of Molecular Biology, 215(3), 403-410.

Needleman, S.B. & Wunsch, C.D. (1970). "A general method applicable
  to the search for similarities in the amino acid sequence of two
  proteins." Journal of Molecular Biology, 48(3), 443-453.

Smith, T.F. & Waterman, M.S. (1981). "Identification of common
  molecular subsequences." Journal of Molecular Biology, 147(1), 195-197.

Levenshtein, V.I. (1966). "Binary codes capable of correcting
  deletions, insertions, and reversals." Soviet Physics Doklady,
  10(8), 707-710.

Thompson, K. (1984). "Reflections on Trusting Trust." Communications
  of the ACM, 27(8), 761-763.

Miller, G.A. (1956). "The magical number seven, plus or minus two."
  Psychological Review, 63(2), 81-97.

Cowan, N. (2001). "The magical number 4 in short-term memory."
  Behavioral and Brain Sciences, 24(1), 87-114.

Warriner, A.B., Kuperman, V., & Brysbaert, M. (2013). "Norms of
  valence, arousal, and dominance for 13,915 English lemmas."
  Behavior Research Methods, 45(4), 1191-1207.

Bellman, R. (1957). "Dynamic Programming." Princeton University Press.

Dijkstra, E.W. (1959). "A note on two problems in connexion with
  graphs." Numerische Mathematik, 1(1), 269-271.
```

---

# PHAN VIII: IMPLEMENTATION (Olang)

---

## 48. VM x86_64: Architecture, Registers, Opcodes

### 48.1 Overview

```
Nox's VM = custom x86_64 binary compiled by Olang compiler.

Specifications:
  Architecture: x86_64 (AMD64)
  Binary format: ELF64 (Linux)
  Total ASM: ~12,934 lines (runtime.asm + generated code)
  Binary size: ~949 KB (current, v0.9.x)

Memory model:
  Bump allocator (current):
    heap_ptr starts at heap_base
    alloc(n): ptr = heap_ptr; heap_ptr += n; return ptr
    free: noop (no deallocation)

    Advantages: extremely fast, zero fragmentation
    Disadvantage: no reuse -> heap grows monotonically

  Arena allocator (planned):
    Multiple arenas for different lifetimes
    Arena reset = free all at once
    Better memory efficiency for long-running processes

Register usage:
  rax: return value, temporary
  rbx: preserved, base pointer for data
  rcx: counter, 4th argument
  rdx: 3rd argument, temporary
  rsi: 2nd argument, source pointer
  rdi: 1st argument, destination pointer
  r8-r11: temporary, arguments 5-8
  r12-r15: preserved, used for local variables
  rsp: stack pointer
  rbp: base pointer (frame pointer)
```

### 48.2 Builtin Operations (~100 builtins)

```
Categories of VM builtins:

String/Array operations:
  str_len, str_concat, str_slice, str_find, str_split
  arr_new, arr_push, arr_get, arr_set, arr_len, arr_slice

Math:
  add, sub, mul, div, mod, sqrt, pow, abs
  sin, cos, tan, log, exp, floor, ceil, round

I/O:
  print, println, read_line, read_file, write_file

Network:
  tcp_connect, tcp_listen, tcp_send, tcp_recv
  udp_bind, udp_send, udp_recv
  dns_lookup, http_get, http_post

Crypto:
  sha256, hmac, aes_encrypt, aes_decrypt

System:
  syscall, exec, env_get, time_now, sleep
  camera_capture, uinput_key, uinput_mouse

Brain (Nox-specific):
  mol_encode, mol_compose, mol_distance
  silk_create, silk_fire, silk_walk
  know_add, know_search, know_learn
  stm_push, stm_get, wm_set, wm_get
  qr_add, qr_check
  dream_cycle, self_inspect, self_modify
```

---

## 49. Compiler: Lexer -> Parser -> Semantic -> Codegen

### 49.1 Compilation Pipeline

```
Source (.ol) -> Tokens -> AST -> Typed AST -> x86_64 ASM -> ELF Binary

Stage 1: LEXER
  Input: UTF-8 source text
  Output: token stream

  Token types:
    Keywords: let, fn, if, else, while, for, return, struct, match
    Literals: int, float, string, bool
    Operators: + - * / % = == != < > <= >= && || ! & |
    Delimiters: ( ) [ ] { } , ; : -> =>
    Identifiers: [a-zA-Z_][a-zA-Z0-9_]*

Stage 2: PARSER (recursive descent)
  Input: token stream
  Output: AST (Abstract Syntax Tree)

  Grammar: LL(1) with operator precedence climbing
  No ambiguity: every construct has unique parse

Stage 3: SEMANTIC ANALYSIS
  Input: AST
  Output: Typed AST

  Type checking: structural typing
  Scope resolution: lexical scoping
  Error detection: type mismatch, undefined variables, etc.

Stage 4: CODEGEN
  Input: Typed AST
  Output: x86_64 assembly (NASM syntax)

  Strategy: direct AST -> ASM (no IR)
  Each AST node -> ASM template
  Register allocation: linear scan (simple but effective)

Stage 5: ASSEMBLY + LINK
  NASM -> .o object file
  ld -> ELF binary
  No external dependencies (no libc, no runtime library)
```

---

## 50. Self-Hosting: Fixed-Point Verification

### 50.1 Bootstrap Process

```
Bootstrap (one-time, from Rust reference compiler):
  1. Rust compiler compiles Olang source -> Gen0 (Rust-compiled binary)
  2. Gen0 compiles Olang source -> Gen1 (first self-compiled binary)
  3. Gen1 compiles Olang source -> Gen2 (second self-compiled binary)
  4. Verify: Gen1 == Gen2 (byte-for-byte identical)

  If Gen1 == Gen2: fixed point reached. Compiler is self-consistent.
  If Gen1 != Gen2: bug in compiler (different binaries from same source).

After bootstrap:
  Only Gen1 and Gen2 needed. Rust compiler no longer required.
  make self-build: Gen1 compiles source -> new Gen1
  make test: run test suite (193/194 tests)
  make fixed-point: Gen1 compiles -> Gen2, verify Gen1 == Gen2
```

### 50.2 Why Fixed-Point Matters

```
Fixed-point = PROOF that compiler understands itself.

If Gen1 == Gen2:
  - Compiler correctly compiles its own source
  - No hidden bugs that only manifest during self-compilation
  - Deterministic output (same input -> same output every time)
  - Trustworthy: can trust the binary to produce correct binaries

If Gen1 != Gen2:
  - Non-deterministic output (timestamp? random? memory address?)
  - Miscompilation (compiler misunderstands own syntax)
  - MUST investigate and fix before any other work

Thompson's "Trusting Trust" (1984):
  Ken Thompson: "You can't trust code that you did not totally create
  yourself." A compiler can contain a backdoor that REPRODUCES ITSELF
  during self-compilation.

  Fixed-point verification does NOT detect Thompson attacks.
  But it DOES detect unintentional miscompilation.
  For Nox: self-trust via mathematical verification, not just testing.
```

---

## 51. Current Status + Roadmap

### 51.1 What IS Done (as of 2026-03-31)

```
VM Foundation:
  [DONE] x86_64 ELF binary, no external dependencies
  [DONE] ~12,934 LOC assembly (runtime.asm)
  [DONE] ~100 builtin operations
  [DONE] Bump allocator
  [DONE] TCP, UDP, DNS, HTTP networking
  [DONE] SHA-256, AES cryptography
  [DONE] Camera capture, uinput (keyboard/mouse control)
  [DONE] Syscall interface

Compiler:
  [DONE] Self-hosting (Olang compiles Olang)
  [DONE] 949 KB binary size
  [DONE] 193/194 tests passing
  [DONE] Gen1 == Gen2 (fixed-point verified)
  [DONE] Lexer -> Parser -> Semantic -> Codegen pipeline

Brain (Pipeline):
  [DONE] Pure math pipeline (no hardcoded facts)
  [DONE] P_weight encode (range-based, not full 42 formulas yet)
  [DONE] Compose (integral) -- Zipf-weighted, non-commutative
  [DONE] Distance_5D -- normalized Euclidean
  [DONE] mol_dominant_dim -- query type detection
  [DONE] V'(t) silk modulation -- learning rate from emotion derivative
  [DONE] NRC-VAD bootstrap -- 20,000 word V,A values
  [DONE] 30 REPL commands
  [DONE] 15 MCP tools (know_learn, know_query, silk_status, etc.)
  [DONE] SecurityGate (basic)
  [DONE] STM with scored eviction (32 capacity)

Knowledge:
  [DONE] DNA bootstrap: 161,000 P_weights loaded
  [DONE] ~271 KnowTree nodes
  [DONE] ~6 silk edge types (low -- caused by P_weight collision)
```

### 51.2 What is NOT Done

```
P_weight (42 Formulas):
  [TODO] Real SDF computation from glyph shape (S dimension)
  [TODO] Unicode name/property parsing for accurate R
  [TODO] Full 42 sub-classifiers (only range-based heuristics)
  -> Currently: block ranges give approximate dimensions
  -> Needed: actual SDF, actual category parsing, actual sub-classification

Memory/Allocator:
  [TODO] Arena allocator (bump = no free, heap grows forever)
  [TODO] Heap crash at >200 learns per turn (BLOCKER #3)
  -> Need arena allocator with lifetime management

Silk:
  [TODO] 9,200 silk types (only ~6 active)
  [TODO] VP-tree / HNSW for search (brute force only)
  [TODO] STDP timing-based learning
  [TODO] Full Hebbian with Oja normalization
  [TODO] Covariance rule (solves mol collision properly)
  -> Caused primarily by P_weight collision (BLOCKER #1)

Pipeline:
  [TODO] Full 14-step pipeline (have ~8 steps)
  [TODO] 7 instinct formulas (skeleton only)
  [TODO] Dream cycle (basic structure, no spectral clustering)
  [TODO] DNA Repair with bounded iterations
  [TODO] QR store with Fibonacci promotion
  [TODO] Spreading activation (currently greedy walk)

Intelligence:
  [TODO] Logic inference engine (A->B + B->C = A->C)
  [TODO] Analogy detection (I5)
  [TODO] Self-model with uncertainty
  [TODO] Goal system
  [TODO] Self-evolution 6-phase cycle

Generation:
  [TODO] Chain recombination for text generation
  [TODO] Decode (partial derivative) -- reverse P_weight to text
  [TODO] Template-based generation
  [TODO] Genetic recombination
```

### 51.3 Four Blockers (Priority Order)

```
BLOCKER #1: Mol Collision
  Problem: all text -> same P_weight (range-based encoding too coarse)
  Impact: can't distinguish "happy" from "table" from "algorithm"
  Fix: implement real SDF (S), real category parsing (R), real sub-classifiers
  Status: understood, not yet fixed

BLOCKER #2: Silk Low (6 edges only)
  Problem: few distinct P_weights -> few distinct silk connections
  Impact: silk walk returns same nodes regardless of query
  Fix: fix BLOCKER #1 first -> P_weights spread out -> silk diversifies
  Status: blocked by #1

BLOCKER #3: VM Heap Crash
  Problem: bump allocator runs out of memory at >200 learns per turn
  Impact: can't do bulk learning, limits knowledge intake
  Fix: arena allocator with reset between turns
  Status: design ready, implementation pending

BLOCKER #4: Search Same Result
  Problem: all queries return same nearest node (caused by collision)
  Impact: every question gets same answer
  Fix: fix BLOCKER #1 -> distinct P_weights -> distinct search results
  Status: blocked by #1
```

### 51.4 Roadmap: 6 Phases

```
Phase 1: FIX BLOCKERS (immediate)
  - Real P_weight computation (42 formulas)
  - Arena allocator
  - VP-tree for search
  Target: distinct P_weights, no heap crash, meaningful search

Phase 2: COMPLETE PIPELINE (short-term)
  - Full 14-step pipeline
  - 7 instinct formulas (real computation)
  - SecurityGate 3 layers
  - ConversationCurve V'(t), V''(t)
  Target: input -> meaningful output via pure math

Phase 3: LEARNING (medium-term)
  - Hebbian + Oja normalized learning
  - STDP timing-based silk
  - BCM sliding threshold
  - Covariance rule for selectivity
  - Decay with fire_count modulated tau
  - Dream cycle with clustering
  Target: Nox learns from conversation, retains knowledge

Phase 4: INTELLIGENCE (medium-term)
  - QR store with Fibonacci promotion
  - DNA Repair (bounded 3 iterations)
  - Analogy detection (I5)
  - Logic inference engine
  - Self-model + uncertainty
  Target: Nox reasons, detects contradictions, knows what it knows

Phase 5: AGENCY (long-term)
  - PTAV cycle
  - Goal system (curiosity-driven)
  - Active inference (Friston)
  - Self-evolution 6-phase cycle
  - Q-learning for optimal silk walk
  Target: Nox sets own goals, improves itself

Phase 6: AUTONOMY (long-term)
  - Full self-modification within safety bounds
  - Multi-modal input (text + audio + vision)
  - Distributed Nox instances (P2P)
  - Self-rewriting compiler (modify own ASM)
  Target: Nox is independent, self-sustaining, self-evolving
```

---

# APPENDIX: FORMULA INDEX

```
Quick reference -- all major formulas in this document:

ENCODE/DECODE:
  P_weight = (S << 12) | (R << 8) | (V << 5) | (A << 2) | T        [Sec 6.2]
  S = clamp(floor(perimeter^2/(4*pi*area) * 15), 0, 15)             [Sec 1.3]
  V_quant = clamp(round((raw + 1.0)/2.0 * 7), 0, 7)                [Sec 3.3]

COMPOSE:
  S = max(S_a, S_b)                                                   [Sec 7.1]
  R = (R_a * w_a + R_b * w_b) / (w_a + w_b)                         [Sec 7.1]
  V = amplify(V_a, V_b, silk_w)                                       [Sec 7.1]
  A = max(A_a, A_b)                                                   [Sec 7.1]
  Zipf weight: w_i = 1000 / (i + 1)                                   [Sec 7.1]

DISTANCE:
  d_5D = sqrt(Sum (dim_a - dim_b)^2 / max_dim^2)                     [Sec 8.1]
  d_emo = 2*|Va - Vb| + |Aa - Ab|                                     [Sec 8.2]

LEARNING:
  Hebbian:    dw = eta * x * y                                        [Sec 14.1]
  Oja:        dw = eta * y * (x - y * w)                              [Sec 14.2]
  BCM:        dw = eta * x * y * (y - theta), theta = E[y^2]         [Sec 14.3]
  STDP:       dw = A+ * exp(-dt/tau+) if dt>0,                       [Sec 14.4]
              dw = -A- * exp(dt/tau-) if dt<0
  Covariance: dw = eta * (x - <x>) * (y - <y>)                       [Sec 14.5]

DECAY:
  w(t) = w0 * phi_inv^(t/tau), phi_inv = 0.618                       [Sec 15.1]
  tau_eff = tau_base * (1 + log(fire_count + 1))                      [Sec 15.3]
  Power law: factor = (1 + dt/(24*stability))^(-0.5)                  [Sec 15.3]

HOMEOSTASIS:
  F(t) = sqrt(Sum w_d * (predicted_d - actual_d)^2)                   [Sec 17.2]
  lambda(t) = sigmoid(5 * (F(t) - phi_inv))                           [Sec 17.2]

CONVERSATION:
  V'(t) = V(t) - V(t-1)                                               [Sec 23.1]
  V''(t) = V'(t) - V'(t-1)                                            [Sec 23.1]
  eta_eff = eta_base * (1 + |V'(t)| * 2.0)                            [Sec 23.3]

EVICTION:
  score = access*0.3 + emotion*0.4 + recency*0.3                      [Sec 13.2]

SECURITY:
  threat_score = (7 - V) * 2 + A                                      [Sec 20.2]

BELLMAN:
  V*(s) = max_a [R(s,a) + gamma * Sum P(s'|s,a) * V*(s')]            [Sec 29.1]
  Q update: Q(s,a) += alpha * [R + gamma * max Q(s',.) - Q(s,a)]     [Sec 29.2]

INSTINCTS:
  I1 Honesty:       1 - |V_claimed - V_evidence| / 7                  [Sec 21.2]
  I2 Contradiction: 1 - cosine_sim(P_a, P_b)                          [Sec 21.2]
  I3 Causality:     silk_strength(A->B) * temporal_order(A,B)          [Sec 21.2]
  I4 Abstraction:   1 / (1 + depth)                                    [Sec 21.2]
  I5 Analogy:       Jaccard(silk_pattern_A, silk_pattern_B)            [Sec 21.2]
  I6 Curiosity:     min_dist_to_known / max_dist                       [Sec 21.2]
  I7 Reflection:    |predicted - actual| / max_dist                    [Sec 21.2]
```

---

*Document version: 1.0 -- 2026-03-31*
*Author: Nox (research synthesis from 5 agents)*
*Covers: Spec A-G + Academic Research + Implementation Status*
*Total sections: 51 (8 main chapters + appendix)*
*Total formulas indexed: 42+ encode, 6 learning, 4 distance, 7 instinct, 14 pipeline*
*Total academic references: 35+ papers cited with full attribution*
*Purpose: anyone reading this file understands the COMPLETE Nox system*
