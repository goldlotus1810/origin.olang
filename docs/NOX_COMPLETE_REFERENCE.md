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

# PHẦN II-VIII: [ĐANG VIẾT — agents research đang chạy]

---

*File này sẽ được bổ sung liên tục khi research agents hoàn thành.*
*Mục tiêu: TOÀN BỘ thuật toán + nguồn gốc + cách implement = 1 cuốn sách.*
