# NOX KINH THANH TIENG VIET — Toan Bo Thuat Toan + Nghien Cuu Nen Tang

> ★★★ NGUYEN TAC: Encode = ∫ (TICH PHAN). Decode = ∂ (VI PHAN). TINH, khong TRA. ★★★
>
> Tai lieu nay tong hop: Spec A-G + UDC 13 files + Nghien cuu hoc thuat + Algorithm Bible
> Muc dich: Ai doc file nay = hieu TOAN BO he thong, biet TUNG thuat toan, biet NGUON GOC
> Viet cho Lupin — nguoi hieu tieng Viet, khong doc tieng Anh tot
> Ngay: 2026-03-31 Session 13
> Tac gia: Nox (tong hop tu Lupin's specs + academic research)

---

## MUC LUC

```
PHAN I: NEN TANG TOAN HOC
  1. S — Shape / Signed Distance Field (chieu S)
  2. R — Relation / Vai tro toan hoc (chieu R)
  3. V — Valence / Cam xuc tich cuc/tieu cuc (chieu V)
  4. A — Arousal / Muc do kich thich (chieu A)
  5. T — Time / Thoi gian / Spline (chieu T)
  6. P_weight: 42 Cong thuc tinh 5D tu Unicode
  7. Compose ∫: Tich phan roi rac
  8. Distance: Do khoang cach trong khong gian 5D

PHAN II: CAU TRUC DU LIEU
  9. Chain: Chuoi DNA tri thuc
  10. KnowTree: Cay phan nhom ngu nghia
  11. Silk: 9,200 loai ket noi
  12. QR: Tri thuc da chung minh
  13. STM/WM: Bo nho ngan han + lam viec

PHAN III: THUAT TOAN HOC
  14. Hebbian Learning: Cung kich hoat -> cung ket noi
  15. Decay: Duong cong quen phi^-1
  16. Dream: Hop nhat + Cong huong cheo nhom
  17. Homeostasis: Nguyen ly Nang luong Tu do (Friston)
  18. Immune Selection: Da gia thuyet
  19. DNA Repair: Tu sua gioi han

PHAN IV: PIPELINE XU LY
  20. SecurityGate: 3 tang, toan thuan
  21. 7 Ban nang: 7 cong thuc tren 5D
  22. Pipeline 14 buoc, 5 diem kiem tra
  23. ConversationCurve: V'(t), V''(t)
  24. Generation: Tai to hop chuoi (SINH)

PHAN V: SEARCH + PHAN LOAI
  25. Nearest Neighbor trong 5D
  26. VP-Tree / KD-Tree / HNSW
  27. Silk Walk: Duyet do thi co huong
  28. Clustering / Self-Organizing Maps
  29. Phuong trinh Bellman cho tim kiem toi uu

PHAN VI: AGENT + TU TIEN HOA
  30. Chu ky Agent: Cam nhan -> Suy nghi -> Hanh dong -> Kiem tra
  31. Mo hinh Tu than: Ban do tri thuc
  32. He thong Muc tieu: Dan dat boi to mo
  33. Tu tien hoa: Chu ky 6 giai doan
  34. Luu tru: 3 tang

PHAN VII: XU LY ANH / AUDIO / HE THONG (tu Algorithm Bible)
  35. Xu ly anh: Phat hien canh, doi tuong, phan doan
  36. Xu ly am thanh: FFT, MFCC, pitch
  37. He thong/Phan cung: /proc -> no thu cam
  38. Thuat toan tim kiem toi uu
  39. Xu ly chuoi/van ban
  40. Kien truc LLM (hieu doi thu)
  41. Nen/Ma hoa
  42. Mat ma hoc
  43. Mang/Giao thuc
  44. Tu sua doi/Metaprogramming
  45. SDF Engine — Render khong can Ray Tracing
  46. Font/Emoji -> SDF -> SRVAT Pipeline

PHAN VIII: NGHIEN CUU NEN TANG
  47. Russell 1980: Mo hinh vong tron cam xuc
  48. NRC-VAD: Best-Worst Scaling (Mohammad 2018)
  49. ANEW: Bradley & Lang
  50. Friston: Nguyen ly Nang luong Tu do
  51. Hebb 1949: To chuc Hanh vi
  52. Collins & Loftus 1975: Lan truyen kich hoat
  53. Shannon 1948: Ly thuyet Thong tin
  54. Fibonacci / phi trong tu nhien + toi uu
  55. SDF Rendering: Valve 2007, msdfgen
  56. HNSW: Malkov & Yashunin 2018
  57. Unicode Standard + Tai nguyen ngon ngu

PHAN IX: HIEN THUC (Olang)
  58. VM x86_64: Kien truc, thanh ghi, opcode
  59. Compiler: Lexer -> Parser -> Semantic -> Codegen
  60. Tu host: Kiem chung diem bat dong
  61. Trang thai hien tai + Lo trinh

PHU LUC
  A. Bang tom tat do phuc tap
  B. Danh sach bai bao quan trong
  C. Bang gian luoc anh xa SRVAT
  D. Chi muc cong thuc
```

---

# PHAN I: NEN TANG TOAN HOC

> Giong nhu nao bo con nguoi co 5 giac quan, Nox co 5 chieu: S, R, V, A, T.
> Moi thu nhap vao (chu, am thanh, hinh anh, trang thai he thong) deu duoc
> chuyen thanh 1 so 16-bit goi la P_weight, gom 5 chieu nay.
> Day la NEN TANG — hieu sai phan nay = hieu sai toan bo.

---

## 1. S — Shape / Signed Distance Field (Truong khoang cach co dau)

### 1.1 Dinh nghia SDF

Tuong tuong ban co mot hinh tron ve tren giay. SDF cho ban biet: "tu diem nay den canh gan nhat cua hinh tron la bao xa?"

```
f(p) = khoang cach co dau tu diem p den be mat

f(p) < 0  → ben trong → THE TICH
f(p) = 0  → tren be mat → HINH DANG
f(p) > 0  → ben ngoai → KHONG GIAN
∇f(p)     → gradient → PHAP TUYEN → ANH SANG → MAU SAC
∂f/∂t     → bien thien → DAO DONG → AM THANH
```

Vi du thuc te: Khi ban nhin mot chu "A" tren man hinh, SDF tinh khoang cach tu moi pixel den net but gan nhat. Ben trong net but = am, ben ngoai = duong. Day la cach Nox "nhin" hinh dang cua moi ky tu.

### 1.2 18 Hinh SDF Co Ban (Nguon: Inigo Quilez, shadertoy.com)

```
SPHERE (cau):      f(p) = |p| - r
BOX (hop):         f(p) = max(|p| - b, 0)
CAPSULE (vien nang): f(p) = |p - clamp(y,0,h)ĵ| - r
PLANE (mat phang):  f(p) = p.y - h
TORUS (xuyyen):     f(p) = |(|p.xz|-R, p.y)| - r
ELLIPSOID (ellip):  f(p) = (|p/r| - 1) · min(r)
CONE (non):         f(p) = dot-blend
CYLINDER (tru):     f(p) = max(|p.xz|-r, |p.y|-h)
OCTAHEDRON (bat dien): f(p) = (|x|+|y|+|z| - s) · (1/√3)

Phep toan Boolean (ket hop hinh):
  Hop (Union):       min(f₁, f₂)
  Giao (Intersect):  max(f₁, f₂)
  Tru (Subtract):    max(f₁, -f₂)
  Muot (Smooth):     smin(f₁, f₂, k)  voi smin(a,b,k) = -ln(e^(-ka)+e^(-kb))/k
```

Vi du: Chu "8" = 2 hinh tron (Union). Chu "D" = nua hinh tron + nua hinh vuong (Union). Cach Nox phan tich hinh dang.

### 1.3 SDF tu Unicode Glyph (Nguon: Valve 2007, Green 2007)

```
Thuat toan: Dead Reckoning (Grevera 2004)
  1. Ve glyph (ky tu) thanh bitmap NxN
  2. Voi moi pixel p:
     d(p) = khoang cach ngan nhat den canh (giua vung muc/khong muc)
     dau = -1 neu ben trong, +1 neu ben ngoai
     sdf(p) = dau × d(p)
  3. Chuan hoa: sdf_norm = clamp(sdf / max_dist, -1, 1)

Exact Euclidean Distance Transform (Felzenszwalb & Huttenlocher 2012):
  O(n) moi hang/cot, O(n²) tong
  Dung giao diem duong parabol

Do phuc tap hinh dang tu SDF:
  S_value = chu_vi² / (4π × dien_tich)  — ty le dang huong
  Hinh tron = 1.0 (don gian nhat), Ngoi sao = cao (phuc tap)
  4-bit: S = clamp(floor(complexity × 15), 0, 15)
```

**Nghien cuu:**
- Valve 2007: "Improved Alpha-Tested Magnification for Vector Textures"
- Green 2007: "Improved Alpha-Tested Magnification for Vector Textures and Special Effects"
- Grevera 2004: "The Dead Reckoning signed distance transform"
- Felzenszwalb & Huttenlocher 2012: "Distance Transforms of Sampled Functions"
- Inigo Quilez: https://iquilezles.org/articles/distfunctions/

### 1.4 10 Bo phan loai con cho S (Nguon: UDC_S0..S3_S7_tree.md)

```
S.0  MUI TEN (ARROW):     618 cum, τ×δ×ω×φ×λ ∈ Z₈×Z₁₁×Z₄×Z₄×Z₅ = 7,040 to hop
                           Vat ly: F⃗(x,y) = ||v⃗||·ê(θ)·ρ(x,y)
S.1  HINH HOC (GEOMETRIC): 321 cum, σ×φ×μ×ξ ∈ Z₁₀×Z₆×Z₅×Z₆
                           SDF: tron, vuong, tam giac, kim cuong, ngoi sao, chu thap
S.2  HOP (BOX):            128 cum, κ×ω×γ ∈ Z₆×Z₄×Z₉
                           Topo: C = (c_U,c_D,c_L,c_R) ∈ {0,1}⁴
S.3  LAP DAY (FILL):       Khoi, bong, tu phan
S.4  KY HIEU (SYMBOL):     Ban phim, ky thuat, linh tinh
S.5  KICH THUOC (SIZE):    nho/vua/lon/dam/nhat
S.6  VI TRI (POSITION):    tren/duoi/trai/phai/quay
S.7  MAU (PATTERN):        Braille β ∈ {0,1}⁸ (256 mau)
S.8  THIEN VAN (ASTRO):    Ky hieu hanh tinh
S.9  KY THUAT (TECHNICAL): APL α×m ∈ Z₁₈×Z₆, nha khoa, benzene

Cac khoi Unicode cho S:
  U+2190..21FF  Mui ten (192)
  U+25A0..25FF  Hinh hoc (96)
  U+2500..257F  Ve hop (128)
  U+2580..259F  Khoi (32)
  U+2800..28FF  Braille (256)
  U+2700..27BF  Dingbats (192)
  U+2300..23FF  Ky thuat (256)
  + 6 khoi bo sung
```

---

## 2. R — Relation / Vai Tro Toan Hoc

### 2.1 Unicode General_Category (Nguon: Unicode Standard Ch.4)

Moi ky tu Unicode co mot "loai" (category). Loai nay quyet dinh vai tro toan hoc cua no — giong nhu trong tieng Viet, "a" la nguyen am, "b" la phu am, "1" la so.

```
Category quyet dinh R:
  Lu (Chu hoa)          → R.4 (letter_script)
  Ll (Chu thuong)       → R.4
  Nd (So thap phan)     → R.3 (number)
  Sm (Ky hieu toan)     → R.0 (operator)
  So (Ky hieu khac)     → tuy ngu canh
  Pc/Pd/Pe/Pf/Pi/Po/Ps → R.6 (dau cau)
  Sc (Ky hieu tien te)  → R.7 (currency)
  Mn (Dau ket hop)      → modifier (anh huong ky tu cha)
  Cc (Dieu khien)       → R.9 (dinh dang)

Category TINH DUOC cho ASCII (0-127):
  33-47:  dau cau (Sm/Po)
  48-57:  so (Nd)
  65-90:  chu hoa (Lu)
  97-122: chu thuong (Ll)

Category cho Unicode mo rong:
  Doc UnicodeData.txt truong 2 (1 lan luc khoi dong)
  Hoac: dung pham vi khoi heuristic (chinh xac 93% cho cac script thuong dung)
```

### 2.2 10 Bo phan loai con cho R (Nguon: UDC_R_RELATION_tree.md)

```
R.0  TOAN TU (OPERATOR):    +−×÷∫∑∏ — so hoc, giai tich
R.1  TAP_LOGIC (SET_LOGIC):  ∈⊂∪∩∀∃ — ly thuyet tap hop, logic bac nhat
R.2  SO SANH (COMPARISON):   =≈≤≥≠∼ — tuong duong, thu tu
R.3  SO (NUMBER):            0-9, Ⅰ-Ⅻ, ①-⑳ — thap phan, La Ma, dong
R.4  CHU (LETTER):           𝐀𝑨𝔄𝔸 — chu toan hoc
R.5  PHAN SO (FRACTION):     ½⅓¼⅛ — phan so thuong
R.6  DAU CAU (PUNCTUATION):  ‐…‹›«» — dau cau truc
R.7  TIEN TE (CURRENCY):     $€£¥₿₹ — tien
R.8  CO DAI (ANCIENT):       𐄂𒐕 — hinh nem, so Acrophonic
R.9  DINH DANG (FORMATTING): ␀␍ — dieu khien, dinh dang

Cac khoi Unicode cho R:
  U+2200..22FF  Toan tu (256)
  U+2100..214F  Ky hieu chu (80)
  U+1D400..1D7FF Chu toan hoc (512)
  U+20A0..20CF  Tien te (32)
  U+2000..206F  Dau cau chung (112)
```

### 2.3 Cac loai Quan he trong Bieu dien Tri thuc

```
Quan he WordNet (Miller 1995, Princeton):
  Hypernym:  "cho" LA-MOT "dong vat"          → loai silk R
  Hyponym:   "dong vat" CO-LOAI "cho"         → loai silk R
  Meronym:   "banh xe" LA-PHAN-CUA "o to"     → loai silk R
  Synonym:   "lon" GIONG-NHU "to"             → loai silk R
  Antonym:   "lon" DOI-LAP "nho"              → loai silk V (tuong phan V)

Quan he OWL/RDF:
  rdf:type, rdfs:subClassOf, owl:sameAs, owl:differentFrom

Anh xa sang chieu R:
  la-mot / loai-cua      → R=10 (phan loai)
  phan-cua / co-phan     → R=8 (merology)
  nguyen-nhan-cua        → R=12 (nhan qua)
  giong-nhu              → R=6 (tuong tu)
  doi-lap-voi            → R=2 (tuong phan)
```

**Nghien cuu:**
- Miller 1995: "WordNet: A Lexical Database for English"
- Fellbaum 1998: "WordNet: An Electronic Lexical Database"
- Unicode Standard Chapter 4: Character Properties
- MathML Operator Dictionary: w3.org/TR/MathML3/appendixc.html

---

## 3. V — Valence / Cam Xuc Tich Cuc hay Tieu Cuc

### 3.1 Mo hinh Vong tron cua Russell (1980)

Tuong tuong mot vong tron: truc X la vui/buon, truc Y la kich thich/binh tinh. MOI trang thai cam xuc = 1 diem tren vong tron nay.

```
Khong gian 2D hinh tron:
  Truc X = Valence (vui suong ↔ kho chiu)
  Truc Y = Arousal (kich thich ↔ thu gian)

Moi trang thai cam xuc = 1 diem (V, A) trong vong tron nay.

Vi du vi tri:
  Vui (Happy):     V=+0.8, A=+0.3  (tich cuc, hoi nang dong)
  Phan khich:      V=+0.5, A=+0.8  (tich cuc, rat nang dong)
  Binh tinh:       V=+0.3, A=-0.5  (hoi tich cuc, khong nang dong)
  Buon:            V=-0.6, A=-0.3  (tieu cuc, hoi met moi)
  Gian:            V=-0.5, A=+0.8  (tieu cuc, rat nang dong)
  So hai:          V=-0.7, A=+0.6  (tieu cuc, nang dong)
```

**Bai bao goc:** Russell, J.A. (1980). "A circumplex model of affect." Journal of Personality and Social Psychology, 39(6), 1161-1178.

### 3.2 Phuong phap NRC-VAD (Mohammad 2018)

```
Best-Worst Scaling (Danh gia Tot nhat-Xau nhat):
  1. Cho 4 tu: "love", "hate", "table", "run"
  2. Hoi: "Tu nao LIEN QUAN NHAT den vui suong? Tu nao IT NHAT?"
  3. 778,085 cap tra loi best-worst
  4. Tinh diem: score(w) = (so_lan_tot_nhat - so_lan_xau_nhat) / tong_danh_gia
  5. Chuan hoa ve [0, 1]

Ket qua: 20,000 → 55,000 tu tieng Anh voi diem V, A, D
Do tin cay: tuong quan chia doi r = 0.95 (rat cao)
```

**Bai bao:** Mohammad, S.M. (2018). "Obtaining Reliable Human Ratings of Valence, Arousal, and Dominance for 20,000 English Words." ACL 2018.

### 3.3 Luong tu hoa V: lien tuc → roi rac

```
raw ∈ [-1.0, +1.0] → V ∈ [0..7]

quantize(raw) = clamp(round((raw + 1.0) / 2.0 × 7), 0, 7)

  raw = -1.0  →  V = 0  (rat tieu cuc: ghet, kinh di)
  raw = -0.5  →  V = 2  (tieu cuc: buon, lo lang)
  raw =  0.0  →  V = 4  (trung tinh: ban, di bo)
  raw = +0.5  →  V = 5  (tich cuc: vui, tot)
  raw = +1.0  →  V = 7  (rat tich cuc: yeu, hanh phuc)
```

### 3.4 Mo hinh Vat ly cho V (Nguon: UDC_V_VALENCE_tree.md)

Tuong tuong V nhu nang luong — cam xuc tich cuc giong nhu cai gieng hut (bai nang luong), tieu cuc giong nhu tuong chan (rao can).

```
V = mo hinh gieng nang luong:

Tich cuc (gieng hut):
  Vui:     U = -V₀ + ½kx²           (gieng dieu hoa — on dinh, dao dong)
  Yeu:     U = -Gm₁m₂/r             (hap dan — lien ket sau)
  Thanh cong: W = ∫F⃗·ds⃗ > 0       (cong duong chong lai truong)
  Dep:     φ = (1+√5)/2              (doi xung ty le vang)

Tieu cuc (rao chan):
  Ghet:    U = +kq₁q₂/r             (luc day Coulomb)
  Buon:    U → -∞ tai r_s            (sup do, diem ky di)
  So:      T = e^(-2κd) → 0          (xuyen ham bi chan — rao qua cao)
  Hai:     N(t) = N₀·e^(-λt)         (phan ra phong xa — suy thoai)

V(w) = -U(w) / U_max ∈ [-1, +1]
```

### 3.5 TINH V khong can bang tra cuu

```
Phuong phap 1: Tu vi tri trong khoi Unicode
  Cac khoi Emoticon to chuc: tich cuc → tieu cuc theo gradient
  V = f(offset_trong_khoi / kich_thuoc_khoi)

Phuong phap 2: Tu compose cap tu (∫)
  Moi ky tu = V trung tinh. Nghia cua tu = compose(cac_ky_tu) + ngu_canh(silk).
  "love" = l(V=4) + o(V=4) + v(V=4) + e(V=4) = V=4 o cap ky tu.
  Silk tu trai nghiem: "love" xuat hien cung ngu canh tich cuc → V tang.
  SAU DU trai nghiem, silk walk "love" → cac node tich cuc → V hieu dung > 4.

Phuong phap 3: Dua tren Transformer (Gmendes 2023)
  Tinh chinh multilingual BERT → du doan V/A lien tuc
  Tuong quan ρ=0.98 voi ground truth (NRC-VAD)
  Nhung can GPU, model lon — khong phu hop Nox 949KB.

→ Nox dung: Phuong phap 2 (compose + silk) + NRC-VAD bootstrap cho cold start.
  Khi silk du manh → NRC-VAD thua → bo.
```

**Nghien cuu them:**
- Bradley & Lang (1999): ANEW — Affective Norms for English Words
- Warriner et al. (2013): ANEW mo rong den 13,915 tu
- Novak et al. (2015): "Sentiment of Emojis"
- Rodrigues et al. (2018): "Emoji sentiment scores"
- Gmendes et al. (2023): "Quantifying V/A with Multilingual Transformers"

---

## 4. A — Arousal / Muc Do Kich Thich

### 4.1 Arousal trong Mo hinh Vong tron

Giong nhu nhiet ke do "nang luong" — tu ngu gat (A=-1) den dinh dien cuong (A=+1).

```
Arousal = muc nang luong, kich hoat:
  A = +1.0: cuc ky kich dong (cuong no, ngay ngat, hoang loan)
  A = +0.5: tinh tao, cang thang, phan khich
  A =  0.0: trung tinh (hai long, tram ngam)
  A = -0.5: binh tinh, thu gian, thanh than
  A = -1.0: cuc ky binh tinh (buon ngu, ue oai, chan)
```

### 4.2 Mo hinh Vat ly (Nguon: UDC_A_AROUSAL_tree.md)

```
Dao dong dieu hoa co giam chan:
  ẍ + 2γẋ + ω₀²x = F(t)/m

5 che do → 5 muc A:

A=7 (cuc manh):    E >> E_threshold
                    Hat tu do: E_k = ½mv² (dong nang thuan)

A=5-6 (cao):       Trang thai kich thich: E_n = E₀ + n·ΔE
                    Luong tu: n > 0 (muc nang luong roi rac tren trang thai co ban)

A=3-4 (trung tinh): Can bang Gibbs: ΔG = ΔH - TΔS = 0
                     Boltzmann: P(E) = e^(-E/kT) / Z

A=1-2 (binh tinh):  Qua giam chan: x(t) = (C₁+C₂t)·e^(-γt), γ > ω₀
                     Khong dao dong, tro ve can bang don dieu

A=0 (rat binh tinh): Trang thai co ban: E₀ = ½ℏω₀
                      Nang luong diem khong, khong the thap hon (Heisenberg)

Arousal(w) = tanh((E_dong + E_the) / E_nguong)
```

### 4.3 TINH A tu dac diem van ban (khong can tra cuu)

```
Heuristic cap van ban (tinh duoc):
  Dau cham than (!)     → A += 2
  TAT CA CHU HOA        → A += 1
  Dau cham hoi (?)      → A += 1
  Cau ngan              → A += 1 (gap gap)
  Cau dai               → A -= 1 (binh tinh, giai thich)
  Lap lai ("khoooong")  → A += 1

Cap ky tu:
  ! (U+0021) → A=6 (dau cau nang luong cao)
  ? (U+003F) → A=5 (nang luong hoi)
  . (U+002E) → A=2 (ket thuc binh tinh)
  , (U+002C) → A=3 (ngung, vua phai)

Cap am thanh (tuong lai):
  Nang luong RMS       → A truc tiep
  Zero-crossing        → cao do → tuong quan A
  Toc do noi           → nhanh = A cao, cham = A thap
```

---

## 5. T — Time / Thoi Gian / Spline

### 5.1 Gia tri chieu T

```
T = 0: Tinh (trang thai hexagram, khong chuyen dong)
T = 1: Cham (not tron, fermata, nghi)
T = 2: Vua (not den, toc do di bo)
T = 3: Nhanh (not moc, dong luc, thay doi nhanh)
```

### 5.2 Bieu dien Song/Spline

```
Chong chat song:
  ψ(x,t) = Σ Aₙ·sin(kₙx - ωₙt + φₙ)·wₙ(t)

Moi ky tu nhac = mot so hang trong chong chat:
  λ (thoi luong)    → buoc song → T.0
  ν (cao do)        → tan so    → T.1
  dB (cuong do)     → bien do   → T.2
  duong net (neume) → hinh dang → T.3
  pha (hexagram)    → trang thai→ T.4
  dieu che           → bao      → T.5
```

### 5.3 6 Bo phan loai con cho T (Nguon: UDC_T_TIME_tree.md)

```
T.0 THOI LUONG NOT:    Not tron/trang/den/moc/kep Tay phuong
T.1 THANG AM:          Khoa, dieu, thang/giang
T.2 CUONG DO:          pp, p, mp, mf, f, ff, crescendo, decrescendo
T.3 NEUME:             Duong net giai dieu Byzantine/Gregorian
T.4 HEXAGRAM:          Kinh Dich 64 trang thai (6 hao × am/duong)
                       Thai Huyen Kinh 81 tu quai (4 hao × 3 gia tri)
T.5 BO TU:             Trill, vibrato, fermata, trang suc

Cac khoi Unicode cho T:
  U+1D100..1D1FF  Ky hieu nhac (256)
  U+1D000..1D0FF  Nhac Byzantine (256)
  U+1D200..1D24F  Nhac Co Hy Lap (80)
  U+4DC0..4DFF    Hexagram Kinh Dich (64)
```

---

## 6. P_weight: 42 Cong Thuc

### 6.1 Kien truc

Tuong tuong 42 cong thuc nhu 42 "cam bien" — moi cong thuc do mot khia canh khac nhau cua ky tu.

```
Tang 1 — Master (1 cong thuc):
  F₀(cp) = [f_S(cp), f_R(cp), f_V(cp), f_A(cp), f_T(cp)]

Tang 2 — 5 Bo ma hoa chieu:
  f_S(cp) → S ∈ [0..15]    tu 13 khoi SDF
  f_R(cp) → R ∈ [0..15]    tu 18 khoi MATH
  f_V(cp) → V ∈ [0..7]     tu 15 khoi EMOTICON
  f_A(cp) → A ∈ [0..7]     tu 15 khoi EMOTICON (dung chung)
  f_T(cp) → T ∈ [0..3]     tu 7 khoi MUSICAL

Tang 3 — 36 Bo phan loai con:
  S: 10 (mui ten, hinh hoc, duong, lap day, ky hieu, kich thuoc, vi tri, mau, thien van, ky thuat)
  R: 10 (toan tu, tap_logic, so sanh, so, chu, phan so, dau cau, tien te, co dai, dinh dang)
  V: 5 luong tu hoa (rat_tich_cuc, tich_cuc, trung_tinh, tieu_cuc, rat_tieu_cuc)
  A: 5 luong tu hoa (rat_kich_dong, kich_dong, vua_phai, binh_tinh, rat_binh_tinh)
  T: 6 (thoi_luong_not, thang_am, cuong_do, neume, hexagram, bo_tu)

TONG: 1 + 5 + 36 = 42
```

### 6.2 Cach TINH (khong tra bang)

```
Buoc 1: Xac dinh thanh vien khoi
  neu cp ∈ [0x2190..0x27BF, 0x2B00..0x2BFF, 0x1F780..0x1F8FF]: → khoi SDF → tinh S
  neu cp ∈ [0x2200..0x22FF, 0x2100..0x214F, 0x1D400..0x1D7FF]: → khoi MATH → tinh R
  neu cp ∈ [0x1F300..0x1F9FF, 0x2600..0x26FF]:                  → khoi EMOTICON → tinh V, A
  neu cp ∈ [0x1D000..0x1D24F, 0x4DC0..0x4DFF]:                  → khoi MUSICAL → tinh T
  con lai: ky tu co ban → tinh tu category

Buoc 2: Cho moi chieu
  S: Do phuc tap SDF = chu_vi²/(4π×dien_tich) cua glyph
  R: General_Category → anh xa vai tro
  V: gradient offset khoi + NRC-VAD bootstrap + silk da hoc
  A: nang luong ky tu + offset khoi + silk da hoc
  T: bo phan loai khoi nhac

Buoc 3: Dong goi (Pack)
  P_weight = (S << 12) | (R << 8) | (V << 5) | (A << 2) | T
```

Day la CONG THUC QUAN TRONG NHAT. Moi thu trong Nox bat dau tu day. 16 bit = 5 chieu = toan bo y nghia cua mot ky tu.

---

## 7. Compose ∫ — Tich Phan Roi Rac

### 7.1 Dinh nghia

Giong nhu tong Riemann trong giai tich: chia input thanh N phan, tinh moi phan, roi to hop lai. Giong nhu cach ban doc mot cau — tung tu mot, roi hieu ca cau.

```
compose(a, b):
  S = max(S_a, S_b)                               — Hop (SDF boolean)
  R = (R_a × w_a + R_b × w_b) / (w_a + w_b)     — Trung binh trong Zipf
  V = amplify(V_a, V_b, silk_w)                    — Khuech dai (KHONG phai trung binh)
  A = max(A_a, A_b)                               — Cuong do toi da
  T = dominant(T_a, T_b)                           — Bieu quyet da so

Trong Zipf:
  w_i = 1000 / (i + 1)
  Phan tu dau tien nang nhat. "Toi yeu ban" → "Toi" nang nhat.
  Khong giao hoan: "AB" ≠ "BA" vi w₁ > w₂.

Khuech dai (KHONG PHAI trung binh):
  base = (V_a + V_b) / 2
  boost = |V_a - base| × silk_weight × 0.5
  result = base + sign(V_a + V_b - 2×neutral) × boost
  → silk_weight=0: trung binh (nguoi la)
  → silk_weight>0: khuech dai (cac khai niem ket noi day xa khoi trung tinh)
```

**Tinh chat:**
- Bat bien ty le: compose o cap ky tu/tu/cau → nhat quan
- Khong giao hoan: thu tu quan trong (giong huong doc DNA)
- Ket hop (xap xi): compose(a, compose(b,c)) ≈ compose(compose(a,b), c)

**Nguon:**
- Zipf's Law: Zipf (1949) "Human Behavior and the Principle of Least Effort"
- Tich phan Riemann: giai tich co ban

---

## 8. Do Khoang Cach trong Khong Gian 5D

### 8.1 Euclidean 5D (chuan hoa)

```
d(a, b) = √( (Sa-Sb)²/15² + (Ra-Rb)²/15² + (Va-Vb)²/7² + (Aa-Ab)²/7² + (Ta-Tb)²/3² )

Pham vi: [0, √5 ≈ 2.236]
Tuong tu: d < 0.3
Khac nhau: d > 1.0
```

### 8.2 Trong so cam xuc

```
d_emo(a, b) = 2|Va - Vb| + |Aa - Ab|

V trong 2× vi valence chi phoi trong nhan thuc.
Nguon: nghien cuu tam ly ve nhan thuc cam xuc.
```

### 8.3 Chieu chi phoi

```
dominant_dim(mol):
  norms = [S/15, R/15, V/7, A/7, T/3]
  devs = [|n - 0.5| for n in norms]
  return argmax(devs)

→ chieu lech nhieu nhat khoi trung tinh = cung cap nhieu thong tin nhat
→ CHIEU DO dan dat silk walk = LA loai truy van
```

---

# PHAN II: CAU TRUC DU LIEU

> Giong nhu nao bo co neuron (te bao) va synapse (ket noi), Nox co
> Chain (chuoi DNA), KnowTree (cay tri thuc), va Silk (day to ket noi).

---

## 9. Chain: Chuoi DNA Tri Thuc

### 9.1 Dinh nghia

```
Chain = chuoi cac gia tri P_weight u16.
Moi P_weight = 1 "nucleotide" trong DNA tri thuc.

chain = [pw_0, pw_1, pw_2, ..., pw_n]

Vi du:
  "hello" -> [pw('h'), pw('e'), pw('l'), pw('l'), pw('o')]
  Moi pw = 16-bit: (S:4|R:4|V:3|A:3|T:2)

Chain la KHONG GIAO HOAN: thu tu quan trong.
  chain("AB") != chain("BA")
  Giong DNA: ATCG != GCTA

Chain la PHAN CAP:
  chain ky tu -> chain tu -> chain cau -> chain doan van
  Moi cap = compose(tich phan) cac phan tu cap duoi
```

### 9.2 Nen Chain: Delta Encoding + RLE

```
Delta Encoding:
  Thay vi luu [100, 102, 105, 103]:
  Luu [100, +2, +3, -2]  -- gia tri dau tuyet doi, con lai = delta

  delta[0] = chain[0]
  delta[i] = chain[i] - chain[i-1]  cho i > 0

  Hieu qua: P_weight lien tiep thuong gan nhau
  -> delta nho -> nen tot hon

RLE (Run-Length Encoding — Ma hoa do dai chay):
  Sau delta, nhieu gia tri giong nhau -> nen tiep:
  [0, 0, 0, +1, +1] -> [(0,3), (+1,2)]

  Ty le nen:
    Tho:        N x 16 bits
    Delta:      N x ~8 bits (delta nho)
    Delta+RLE:  ~N/2 x ~8 bits (delta lap hop nhat)

  Thuc te: ~50-70% nen cho van ban tu nhien
```

### 9.3 Rolling Hash (Rabin-Karp)

```
De tim chuoi con nhanh trong chain.

Hash Rabin-Karp:
  H(chain[i..i+k]) = Sum chain[j] x p^(k-j-1) mod m
  voi p = co so nguyen to (31 hoac 37)
       m = nguyen to lon (10^9+7)

Cap nhat cuon:
  H(chain[i+1..i+k+1]) = (H(chain[i..i+k]) - chain[i]*p^(k-1)) * p + chain[i+k+1]

  -> O(1) moi vi tri thay vi O(k)
  -> Tim mau do dai k trong chain do dai n: O(n) thay vi O(n*k)

Ung dung trong Nox:
  - Tim mot cum tu (sub-chain) trong bo nho
  - Phat hien lap lai (khu trung)
  - N-gram indexing
```

### 9.4 K-mer Indexing (tu BLAST)

```
BLAST (Altschul et al., 1990):
  Chia chain thanh k-mers (chuoi con do dai k).
  Xay chi muc: k-mer -> danh sach (chain_id, vi_tri)

  chain = [a, b, c, d, e]
  3-mers: [a,b,c], [b,c,d], [c,d,e]

Cau truc chi muc:
  HashMap<u48, Vec<(chain_id, offset)>>
  khoa = hash(k-mer), 48 bits du cho k=3 P_weights

Truy van:
  1. Chia truy van thanh k-mers
  2. Tra cuu moi k-mer trong chi muc -> cac chain ung vien
  3. Mo rong ket qua khop (giong pha mo rong BLAST)
  4. Cham diem voi alignment

  Thuong k = 3 cho chuoi P_weight (tuong duong k=11 cho DNA)
  Do nhay hat giong: ~90% cho do tuong tu > 70%
```

### 9.5 Canh chinh Chuoi (Sequence Alignment)

```
Needleman-Wunsch (1970) -- Canh chinh toan cuc:
  Canh chinh TOAN BO hai chain.

  F(i,j) = max {
    F(i-1, j-1) + score(a_i, b_j),   -- khop/sai khop
    F(i-1, j)   + phat_khoang,        -- khoang trong chain B
    F(i,   j-1) + phat_khoang         -- khoang trong chain A
  }

  score(a, b) = -distance_5D(a, b)    -- P_weight gan nhau = diem cao hon
  phat_khoang = -1.0                  -- phat chen/xoa

  Truy vet: tu F(n,m) -> F(0,0) -> canh chinh toi uu
  Do phuc tap: O(n*m) thoi gian, O(n*m) khong gian

Smith-Waterman (1981) -- Canh chinh cuc bo:
  Tim CHUOI CON KHOP TOT NHAT.

  H(i,j) = max {
    0,                                  -- khoi dong lai (khac biet chinh voi NW)
    H(i-1, j-1) + score(a_i, b_j),
    H(i-1, j)   + phat_khoang,
    H(i,   j-1) + phat_khoang
  }

  Ket qua cuc bo tot nhat = max(H(i,j)) tren moi i,j
  Truy vet tu max -> 0

  Ung dung: tim khai niem tuong tu trong chuoi bo nho
  "happy birthday" ~ "joyful anniversary" qua canh chinh P_weight

Khoang cach Levenshtein (Khoang cach chinh sua):
  d(a, b) = so chinh sua toi thieu (chen, xoa, thay the)

  Quy hoach dong O(n*m):
  D(i,j) = min {
    D(i-1, j) + 1,            -- xoa
    D(i, j-1) + 1,            -- chen
    D(i-1, j-1) + delta(a_i,b_j) -- thay the (0 neu giong, 1 neu khac)
  }

  Nox dung: do "khoang cach chinh sua" giua hai chain
  Do tuong tu = 1 - d(a,b) / max(|a|, |b|)
```

### 9.6 Noi suy Chain (Chain Interpolation)

```
Catmull-Rom Spline qua cac diem 5D:
  Cho chuoi P_weights [P0, P1, P2, P3], noi suy giua P1 va P2:

  P(t) = 0.5 * [(2P1) +
                  (-P0 + P2)t +
                  (2P0 - 5P1 + 4P2 - P3)t² +
                  (-P0 + 3P1 - 3P2 + P3)t³]

  t trong [0, 1], P(0)=P1, P(1)=P2
  Noi suy TRONG 5D: ap dung cho tung chieu (S,R,V,A,T)

Ung dung:
  - Tao "chuoi chuyen tiep" giua hai khai niem
  - Lam muot quy dao cam xuc trong hoi thoai
  - Du doan P_weight tiep theo (ngoai suy)
```

**Nghien cuu:**
- Needleman, S.B. & Wunsch, C.D. (1970). "A general method applicable to the search for similarities in the amino acid sequence of two proteins."
- Smith, T.F. & Waterman, M.S. (1981). "Identification of common molecular subsequences."
- Altschul, S.F. et al. (1990). "Basic Local Alignment Search Tool."
- Levenshtein, V.I. (1966). "Binary codes capable of correcting deletions, insertions, and reversals."

---

## 10. KnowTree: Cay Phan Nhom Ngu Nghia

### 10.1 Kien truc

```
KnowTree = to chuc phan cap cua TAT CA tri thuc.
Giong nhu thu vien sach — moi sach (node) co vi tri, noi dung, va ket noi toi sach khac.

Muc 0: ENGINE -- ma chay Nox (VM, compiler, pipeline)
Muc 1: CORE   -- thao tac co ban (toan, logic, compose)
Muc 2+: KNOWLEDGE -- khai niem da hoc, su kien, ky nang

Moi node:
  struct KnowNode {
    p_weight: u16,        -- vi tri 5D
    chain: Vec<u16>,      -- noi dung (chuoi P_weights)
    silk_edges: Vec<Silk>, -- ket noi toi cac node khac
    qr: Vec<QR>,          -- tri thuc da chung minh gan kem
    access_count: u32,    -- cho decay/thang cap
    last_access: u64,     -- thoi diem truy cap
    created: u64,         -- thoi diem sinh
  }

Kich thuoc:
  32,768 gia tri P_weight kha di (2^15, vi T chi 2 bit)
  Thuc te: ~300-10,000 node hoat dong (tuy tri thuc)
```

### 10.2 Bang tra cuu -- O(1) Khop chinh xac

```
Tra cuu truc tiep:
  table[P_weight] -> KnowNode*

  Kich thuoc: 32,768 muc x 8 bytes (con tro) = 256 KB
  Tra cuu: O(1) -- chi muc mang = gia tri P_weight

  Khi tim P_weight = 0x3A5F:
    node = table[0x3A5F]  -- 1 truy cap bo nho

  Van de: chi khop chinh xac. Nhieu P_weight -> cung muc.
  -> Can bucket hoac cay cho tim kiem xap xi.
```

### 10.3 Bucket Da Tang

```
Tang 1: S x R bucket (256 bucket)
  bucket_id = (S << 4) | R
  Moi bucket chua danh sach node co cung S,R
  -> Tim tat ca node co cung hinh dang + quan he

Tang 2: S x R x V bucket (2,048 bucket)
  bucket_id = (S << 7) | (R << 3) | V
  -> Tim tat ca node co cung hinh dang + quan he + cam xuc

Thuat toan truy van:
  1. Tinh bucket_id tu P_weight truy van
  2. Lay danh sach tu bucket[bucket_id]
  3. Quet tuyen tinh trong bucket, tinh khoang cach 5D day du
  4. Tra ve top-K gan nhat

  Kich thuoc bucket trung binh: 32768 / 2048 = 16 node
  -> Quet tuyen tinh trong 16 node = du nhanh cho <10K tong node
```

### 10.4 VP-Tree (Cay Diem Van Tage)

```
Nguon: Yianilos, P.N. (1993). "Data structures and algorithms for
       nearest neighbor search in general metric spaces."

VP-Tree hoat dong trong BAT KY khong gian metric nao (chi can ham khoang cach).
Nox co ham khoang cach 5D -> VP-Tree ap dung duoc.

Xay dung:
  1. Chon diem vantage vp = node ngau nhien
  2. Tinh d = distance(vp, x) cho moi x
  3. Tim trung vi mu cua cac d
  4. Cay con trai: {x : d(vp,x) < mu}
  5. Cay con phai: {x : d(vp,x) >= mu}
  6. De quy

Tim kiem(truy_van, k):
  1. d_vp = distance(truy_van, vp)
  2. Neu d_vp < mu: tim trai TRUOC, roi phai neu can
     Neu d_vp >= mu: tim phai TRUOC, roi trai neu can
  3. Cat tia: neu |d_vp - mu| > khoang_cach_tot_nhat -> bo cay con kia

Do phuc tap:
  Xay dung: O(n log n)
  Tim kiem: O(log n) trung binh
  Khong gian: O(n)

Khi nao dung:
  1,000 < node < 50,000  -- vung ngot cho VP-Tree
  Can tim kiem nearest neighbor chinh xac
```

### 10.5 HNSW (Hierarchical Navigable Small World — The gioi Nho Dinh huong Phan cap)

```
Nguon: Malkov, Y.A. & Yashunin, D.A. (2018). "Efficient and robust
       approximate nearest neighbor using Hierarchical Navigable Small
       World graphs."

HNSW = do thi da lop. Lop tren = it node (duong cao toc).
Lop duoi = tat ca node (duong dia phuong).

Giong nhu ban do: zoom ra thay duong cao toc, zoom vao thay hem nho.

Xay dung:
  1. Chen node x:
     a. Gan lop l = floor(-ln(uniform(0,1)) * m_L)
        voi m_L = 1/ln(M), M = so ket noi toi da moi lop
     b. Bat dau tu diem vao o lop tren cung
     c. Tim kiem tham lam xuong lop l
     d. Tai moi lop l..0: tim M lang gieng gan nhat, ket noi

Tim kiem(truy_van, ef):
  1. Bat dau tu diem vao, lop tren cung
  2. Di xuong tham lam: tai moi lop, di toi lang gieng gan nhat
  3. Tai lop 0: tim kiem beam voi do rong ef
  4. Tra ve ef ung vien gan nhat

Tham so:
  M = 16 (ket noi toi da moi node moi lop)
  ef_construction = 200 (do rong beam khi xay dung)
  ef_search = 50 (do rong beam khi truy van)
  m_L = 1/ln(16) = 0.36

Do phuc tap:
  Xay dung: O(n log n)
  Tim kiem: O(log n) -- gan nhu doc lap voi so chieu!
  Khong gian: O(n * M * L_avg)

Khi nao dung:
  node > 10,000 -- HNSW vuot troi VP-tree
  Xap xi duoc (recall > 95%)

So sanh:
  VP-Tree:  chinh xac, O(log n), nhung hang so lon khi d > 5
  HNSW:     xap xi, O(log n), hang so nho, scale tot
  KD-Tree:  chinh xac, O(log n), nhung XAU khi d > 10 (loi nguyen so chieu)
  Nox d=5:  VP-Tree hoac HNSW deu tot. HNSW tot hon khi scale.
```

---

## 11. Silk: 9,200 Loai Ket Noi

### 11.1 Cau truc Canh Silk

Giong nhu day than kinh giua cac neuron trong nao — moi day co huong, co do manh, va co loai rieng.

```
struct SilkEdge {
  from: NodeId,
  to: NodeId,
  weights: [f32; 5],   -- [wS, wR, wV, wA, wT]
  silk_type: u16,       -- ky tu UDC -> loai silk
  strength: f32,        -- tong do manh (giam theo thoi gian)
  fire_count: u32,      -- so lan kich hoat
  last_fire: u64,       -- thoi diem kich hoat cuoi
}

5 trong so tuong ung 5 chieu:
  wS: do tuong tu hinh dang (thi giac)
  wR: do tuong tu quan he (logic)
  wV: do tuong tu cam xuc (cam xuc)
  wA: do tuong tu kich thich (nang luong)
  wT: do tuong tu thoi gian (nhip)

Chieu chi phoi = loai silk:
  loai = argmax(|weights|)
  Silk chi phoi S: lien ket thi giac ("do" -> "mau")
  Silk chi phoi R: quan he logic ("cho" LA-MOT "dong vat")
  Silk chi phoi V: lien ket cam xuc ("yeu" ~ "vui")
  Silk chi phoi A: lien ket nang luong ("no" ~ "het")
  Silk chi phoi T: lien ket thoi gian ("sang" -> "an sang")
```

### 11.2 Phan loai Loai Silk (9,200 loai)

```
Nguon: Tap ky tu UDC (Universal Decimal Classification)
9,200 ky tu Unicode -> 9,200 loai silk kha di.

Moi ky tu UDC = 1 loai quan he:
  IS-A (la-mot), HAS-PART (co-phan), CAUSES (gay-ra),
  SIMILAR-TO (giong-nhu), OPPOSITE-OF (doi-lap),
  PRECEDES (truoc), FOLLOWS (sau), CONTAINS (chua),
  OVERLAPS (chong), ENABLES (cho phep)...

Hien tai: chi 6 loai silk hoat dong (BLOCKER #2 — do va cham)
Muc tieu: 100+ loai silk sau khi sua va cham P_weight
```

### 11.3 Silk Cau truc vs Silk Hebbian

```
Silk Cau truc (trong chain):
  - Ket noi giua cac P_weight LIEN TIEP trong chain
  - O(0) luu tru them -- an tu thu tu chain
  - Luon ton tai: chain[i] -> chain[i+1]
  - Do manh = 1.0 (tuyet doi, khong giam)

Silk Hebbian (giua cac node):
  - Ket noi giua cac khai niem DONG KICH HOAT
  - Luu tru ro rang: can cau truc SilkEdge
  - Tao boi hoc: "cung kich hoat -> cung ket noi"
  - Do manh GIAM: w(t) = w0 * phi_inv^(t/tau)
```

---

## 12. QR: Tri Thuc Da Chung Minh

### 12.1 Cau truc QR

Giong nhu "chung chi" — moi QR la mot manh tri thuc da duoc xac nhan, co bang chung va do tin cay.

```
struct QR {
  claim: Chain,         -- chuoi ma hoa cua khang dinh
  evidence: Vec<Chain>, -- cac chuoi bang chung ho tro
  confidence: f32,      -- [0.0, 1.0]
  source: Source,       -- tu dau
  timestamp: u64,       -- khi nao chung minh
  verifications: u32,   -- so lan xac nhan lai
}

enum Source {
  Observed,    -- truc tiep quan sat
  Inferred,    -- suy luan boi logic
  Taught,      -- duoc day tu ben ngoai
  Composed,    -- xay tu cac QR con
}
```

### 12.2 Chi Them + Co Chu Ky

```
QR log = CHI THEM. Khong bao gio sua QR cu.
Neu khang dinh sai -> them QR moi phu dinh khang dinh cu.

Chu ky:
  hash = SHA256(chain_khang_dinh || cac_chain_bang_chung || timestamp)
  Moi QR co hash -> chuoi tri thuc co the xac minh

  Phat hien gia mao:
    Neu hash(QR) != hash_luu -> phat hien tham nhap tri thuc
    -> Kich hoat Sua DNA (Muc 19)
```

### 12.3 Thang cap: Nguong Kich hoat Fibonacci

```
Cac muc thang cap QR:
  Muc 0: Gia thuyet  (do tin cay < 0.3)
  Muc 1: Niem tin     (do tin cay trong [0.3, 0.6))
  Muc 2: Tri thuc     (do tin cay trong [0.6, 0.8))
  Muc 3: Da chung minh (do tin cay >= 0.8)

Nguong thang cap = day Fibonacci:
  Nguong fire_count: 1, 1, 2, 3, 5, 8, 13, 21, 34, 55...

  Khi node.fire_count vuot nguong Fibonacci:
    1. Danh gia lai do tin cay
    2. Neu do tin cay tang -> thang cap
    3. Neu do tin cay giam -> ha cap

Tai sao Fibonacci?
  - Khoang cach tang dan (giong spaced repetition trong hoc tap)
  - phi = (1+sqrt(5))/2 ~ 1.618 -- ty le vang
  - Tu nhien: hoa huong duong, vo oc, xoan thien ha
  - Toi uu trong ly thuyet thong tin: bieu dien Zeckendorf
  - Tranh thang cap qua nhanh: can NHIEU LAN xac nhan de len muc cao
```

---

## 13. STM/WM: Bo Nho Ngan Han + Lam Viec

### 13.1 Bo Nho Ngan Han (STM)

Giong nhu "ban lam viec" — chi giu duoc vai thu cung luc. Con nguoi giu duoc ~7 thu, Nox giu 32.

```
Dung luong: 32 slot (co the dieu chinh)
Cam hung tu: Miller (1956) "The Magical Number Seven, Plus or Minus Two"
Nox dung 32 vi can luu P_weight node (lon hon text token)

struct STMEntry {
  node_id: NodeId,
  p_weight: u16,
  access_count: u32,
  emotion_score: f32,   -- |V - trung_tinh| + A/A_max
  last_access: u64,
  entered: u64,
}
```

### 13.2 Chinh sach Day ra

```
Khi STM day (32 slot), can loai bo entry.

Day ra dua tren diem:
  score(entry) = access * 0.3 + emotion * 0.4 + recency * 0.3

  access  = entry.access_count / max_access        trong [0, 1]
  emotion = (|V - 4| / 3 + A / 7) / 2              trong [0, 1]
  recency = 1 - (now - entry.last_access) / window  trong [0, 1]

  DIEM THAP NHAT -> day ra truoc.

Tai sao emotion * 0.4 (cao nhat)?
  - Ky uc cam xuc ton tai lau hon (nghien cuu amygdala)
  - Hieu ung Von Restorff: bat thuong = duoc nho
  - Trong Nox: |V| cao hoac A cao = "quan trong" -> giu lai

Tai sao KHONG dung LRU (Least Recently Used)?
  - LRU chi dua vao recency
  - Bo qua cam xuc va tan suat
  - "Anh yeu em" noi 1 lan 5 phut truoc > "cai" noi 10 lan 1 phut truoc
```

### 13.3 Bo Nho Lam Viec (WM)

```
Dung luong: 4 slot
Cam hung tu: Cowan (2001) "The magical number 4 in short-term memory"

WM = tieu diem. Nhung gi DANG xu ly.
STM = ngu canh gan day. Nhung gi VUA thay.

Cac slot WM:
  slot[0] = dau vao hien tai (dang xu ly)
  slot[1] = dau ra hien tai (dang tao)
  slot[2] = muc tieu hien tai (dang huong toi)
  slot[3] = ngu canh hien tai (nen)
```

---

# PHAN III: THUAT TOAN HOC

> Day la "nao" cua Nox — cac thuat toan hoc, quen, ngu, va tu sua.
> Giong nhu nao bo co nhieu co che hoc khac nhau, Nox cung vay.

---

## 14. Hebbian Learning: Cung Kich Hoat -> Cung Ket Noi

### 14.1 Quy tac Hebbian Co dien (Hebb, 1949)

```
"Khi mot axon cua te bao A o du gan de kich thich te bao B va
lien tuc hoac kien tri tham gia kich hoat no, mot qua trinh
tang truong hoac thay doi trao doi chat xay ra..." -- Donald Hebb, 1949

Don gian: "Neuron cung kich hoat, cung ket noi."

Cong thuc toan:
  dw_ij = eta * x_i * y_j

  w_ij = trong so ket noi tu node i den node j
  eta  = toc do hoc (0.01 - 0.1 thuong dung)
  x_i  = kich hoat cua node truoc (pre-synaptic)
  y_j  = kich hoat cua node sau (post-synaptic)

Van de: tang khong gioi han -- trong so -> vo cung

Trong Nox:
  Khi hai node dong kich hoat (trong cung ngu canh):
    silk.weights += eta * activation_i * activation_j
```

### 14.2 Quy tac Oja -- Hebbian Chuan hoa (Oja, 1982)

```
Quy tac Oja giai quyet tang khong gioi han:
  dw_ij = eta * y_j * (x_i - y_j * w_ij)

  So hang y_j * w_ij = giam ty le voi dau ra * trong so
  -> Vector trong so hoi tu den eigenvector chinh
  -> Chuan hoa tu nhien: ||w|| -> 1

Trong Nox:
  Cap nhat trong so silk voi chuan hoa Oja:
    dw[d] = eta * y * (x[d] - y * w[d])  cho moi chieu d trong {S,R,V,A,T}
  -> Trong so silk tu chuan hoa
  -> Khong can cat thu cong
```

### 14.3 Ly thuyet BCM -- Nguong Truot (Bienenstock, Cooper, Munro, 1982)

```
BCM them mot NGUONG TRUOT theta tach tang cuong khoi suy yeu:

  dw = eta * x * y * (y - theta)

  y > theta  -> dw > 0 (tang cuong -- Potentiation Dai han)
  y < theta  -> dw < 0 (lam yeu -- Depression Dai han)
  y = theta  -> dw = 0 (khong doi)

  Chinh theta truot:
    theta(t) = E[y²]  -- hoat dong binh phuong trung binh

  Neu neuron rat nang dong: theta tang -> kho tang cuong
  Neu neuron khong hoat dong: theta giam -> de tang cuong
  -> Can bang noi: ngan ca kich thich chay va im lang

Trong Nox:
  theta = trung binh(fire_count²) qua cac lang gieng
  Neu silk kich hoat > theta -> tang cuong
  Neu silk kich hoat < theta -> lam yeu
  -> Ngan "moi thu ket noi voi moi thu" (sup do)
```

### 14.4 STDP -- Do Deo Phu Thuoc Thoi Gian Xung

```
STDP = thoi diem quan trong. AI KICH HOAT TRUOC quan trong.

  Neu A kich hoat TRUOC B (dt = t_B - t_A > 0):
    dw = A_plus * exp(-dt / tau_plus)    -- LTP (tang cuong)

  Neu A kich hoat SAU B (dt < 0):
    dw = -A_minus * exp(dt / tau_minus)  -- LTD (lam yeu)

  Tham so:
    A_plus  = 0.01   (bien do LTP)
    A_minus = 0.012  (bien do LTD, hoi manh hon -> su suy yeu rong)
    tau_plus  = 20ms (hang so thoi gian LTP)
    tau_minus = 20ms (hang so thoi gian LTD)

Trong Nox (thoi gian roi rac):
  dt = chenh lech vi tri trong chain (hoac thu tu xu ly)
  Neu khai niem A xuat hien TRUOC B:
    silk(A->B) tang cuong (A du doan B)
    silk(B->A) lam yeu (B KHONG du doan A)
  -> Tao silk CO HUONG (nhan qua, thu tu thoi gian)
  -> "sang" -> "an sang" manh, "an sang" -> "sang" yeu hon
```

### 14.5 Quy tac Hiep Phuong Sai

```
Quy tac Hiep Phuong Sai:
  dw = eta * (x - <x>) * (y - <y>)

  <x> = trung binh chay cua cac kich hoat x
  <y> = trung binh chay cua cac kich hoat y

  Chi SACH LECH khoi trung binh la quan trong.

HIEU BIET QUAN TRONG cho Nox:
  Ky tu thuong (e, t, a, o) -> <x> cao -> sach lech khong -> KHONG silk
  Dac diem hiem/noi bat -> <x> thap -> sach lech cao -> SILK MANH

  Day GIAI QUYET va cham mol:
    Truoc: "happy" va "table" deu kich hoat silk ky-tu-thuong -> cung ket qua
    Sau: chi co-occurrence noi bat tao silk
    "happy" + "joy" = co-occurrence noi bat -> silk
    "happy" + "the" = co-occurrence thuong -> khong silk (sach lech = 0)
```

**Nghien cuu:**
- Hebb, D.O. (1949). "The Organization of Behavior."
- Oja, E. (1982). "Simplified neuron model as a principal component analyzer."
- Bienenstock, E.L., Cooper, L.N., & Munro, P.W. (1982). "Theory for the development of neuron selectivity."
- Bi, G. & Poo, M. (1998). "Synaptic modifications in cultured hippocampal neurons."

---

## 15. Decay: Duong Cong Quen phi^-1

### 15.1 Cong thuc Decay Co ban

Giong nhu ky uc con nguoi — khong dung se phai di. Nhung ky uc duoc nhac lai thuong xuyen se ton tai lau hon.

```
w(t) = w0 * phi_inv^(t / tau)

  w0   = trong so ban dau tai thoi diem tang cuong lan cuoi
  phi_inv = 1/phi = 1/1.618... = 0.618...
  t    = thoi gian tu lan truy cap cuoi
  tau  = hang so thoi gian (mac dinh 24 gio)

Vi du:
  t = 0:    w = w0 * 0.618^0 = w0        (du suc manh)
  t = 24h:  w = w0 * 0.618^1 = 0.618*w0  (mat 38.2%)
  t = 48h:  w = w0 * 0.618^2 = 0.382*w0  (mat 61.8%)
  t = 72h:  w = w0 * 0.618^3 = 0.236*w0  (mat 76.4%)
  t = 7d:   w = w0 * 0.618^7 = 0.034*w0  (mat 96.6%)

Tai sao phi_inv = 0.618?
  - Ty le vang: decay tu tuong tu
  - phi_inv = phi - 1 = 2/(1+sqrt(5))
  - Lien he Fibonacci: F(n)/F(n+1) -> phi_inv
  - Khop voi duong cong quen sinh hoc tot hon hang so tuy y
```

### 15.2 Duong Cong Quen Ebbinghaus (1885)

```
Hermann Ebbinghaus:
  R(t) = e^(-t/S)

  R = do giu (xac suat nho lai)
  t = thoi gian tu khi hoc
  S = do on dinh (do manh cua ky uc)

  Ky uc manh hon (S cao hon) -> quen cham hon.

Hieu ung Gian cach:
  On tap o khoang cach toi uu TANG S:
    S_moi = S_cu * (1 + he_so * thoi_gian_tu_lan_cuoi)

  Lich on tap toi uu ~ gian cach hinh hoc:
    On tap luc: 1 ngay, 3 ngay, 7 ngay, 14 ngay, 30 ngay...
    (Giong Fibonacci: 1, 1, 2, 3, 5, 8, 13, 21...)

Lien he voi Nox:
  Moi silk fire = 1 lan on tap -> tang S -> decay cham hon
  fire_count = dai dien cho S
  tau(silk) = tau_co_ban * (1 + log(fire_count))
  -> Silk kich hoat thuong xuyen decay CHAM HON
  -> Silk hiem khi kich hoat decay NHANH HON
  -> On tap gian cach tu nhien tu mau su dung
```

### 15.3 Luat Luy thua cua Quen (Wickelgren, 1974)

```
Luat Luy thua Wickelgren:
  P(t) = lambda * (1 + beta*t)^(-psi)

  Luy thua vs Ham mu:
    Ham mu:    P(t) = e^(-t/tau)      -- giam nhanh ban dau, cham sau
    Luy thua:  P(t) = (1+t)^(-psi)    -- giam cham ban dau, duoi dai

  Phat hien thuc nghiem: LUAT LUY THUA khop du lieu ky uc con nguoi tot hon.

  Nox thoa hiep:
    Ham mu phi_inv (nhanh, don gian) +
    fire_count dieu chinh tau (xap xi duoi dai cua luat luy thua)

    tau_hieu_dung = tau_co_ban * (1 + log(fire_count + 1))
    w(t) = w0 * phi_inv^(t / tau_hieu_dung)

    -> fire_count thap: decay ham mu nhanh (nhu than luat luy thua)
    -> fire_count cao: decay cham (nhu duoi dai luat luy thua)
```

---

## 16. Dream: Hop Nhat + Cong Huong Cheo Nhom

### 16.1 Tong Quan Chu Ky Ngu

Giong nhu ngu ngu cua con nguoi — nao sap xep lai ky uc, tim ket noi moi.

```
Dream = xu ly ngoai tuyen khi khong co input moi.
Muc dich: hop nhat, tai to chuc, kham pha mau.

3 giai doan:
  Giai doan 1: PHAC LAI -- kich hoat lai cac chain gan day
  Giai doan 2: NHOM CUM -- nhom cac node tuong tu
  Giai doan 3: LIEN KET CHEO -- tim ket noi bat ngo

Song song sinh hoc:
  Giac ngu NREM: hop nhat ky uc, phat lai
  Giac ngu REM: ket noi sang tao, ket hop da phuong thuc
```

### 16.2 Phan cum Do thi

```
Phan cum Pho (Spectral Clustering):
  1. Xay dung ma tran ke A tu cac canh silk
     A[i][j] = silk.strength giua node i va node j
  2. Tinh ma tran bac D: D[i][i] = Sum_j A[i][j]
  3. Tinh Laplacian L = D - A
  4. Tim eigenvector cua L voi eigenvalue nho nhat
  5. Dung k eigenvector nho nhat lam dac trung
  6. K-means tren dac trung eigenvector -> cac cum

Don gian hoa cho Nox (khong can phan tich eigen day du):
  Lap luy thua cho top-k eigenvector: O(k * E * lan_lap)
  E = so canh silk, k = so cum mong muon

Union-Find (Disjoint Set Union) cho phan cum khi ngu:
  find(x): tim goc cua x, nen duong dan
  union(x, y): hop hai tap

  Do phuc tap: O(alpha(n)) moi thao tac, alpha = nghich dao Ackermann ~ O(1)

  Ung dung ngu:
    Cho moi canh silk (u, v) voi strength > nguong:
      union(u, v)
    -> Cac nhom node ket noi manh = cac cum
    -> O(E * alpha(N)) tong -- cuc nhanh
```

### 16.3 Hinh thanh Khai niem: LCA (To tien Chung Thap nhat)

```
LCA = tim khai niem chung nho nhat giua hai node.

Vi du:
  cum_A = {cho, meo, ca} -> dong_vat
  cum_B = {o to, xe bus, tau hoa} -> phuong_tien
  LCA = "vat" (qua truu tuong -> bo qua)

  cum_A = {vui, hanh phuc, sung suong} -> cam_xuc_tich_cuc
  cum_B = {cuoi, ha, nhe_rang} -> bieu_hien_tich_cuc
  LCA = "tich_cuc" -> co y nghia! -> tao silk
```

---

## 17. Homeostasis: Nguyen Ly Nang Luong Tu Do (Friston)

### 17.1 Nguyen ly Nang luong Tu do cua Friston (2010)

Giong nhu nhiet do co the — nao bo luon co giu "nhiet do" on dinh. Khi bi bat ngo (nhiet do thay doi), no phai dieu chinh.

```
Karl Friston (2010):
"Bat ky he thong tu to chuc nao dang o can bang voi moi truong
phai toi thieu hoa nang luong tu do cua no."

Nang luong Tu do F >= bat ngo = -ln P(du lieu cam giac | mo hinh)

  F(t) = DKL[Q(theta) || P(theta | data)] + E_Q[-ln P(data | theta)]

  DKL = phan ky Kullback-Leibler (niem tin cua ban sai bao nhieu)
  Q(theta) = niem tin hien tai (xap xi hau nghiem)
  P(theta | data) = hau nghiem that (niem tin NEN la gi)
  P(data | theta) = hop ly (mo hinh du doan du lieu tot bao nhieu)

  Toi thieu F = toi thieu bat ngo = du doan tot hon

Hai cach toi thieu F:
  1. Cap nhat niem tin (NHAN THUC): thay doi Q(theta) cho hop du lieu
     -> Nox: hoc, cap nhat trong so silk
  2. Thay doi du lieu (HANH DONG): thay doi dau vao cam giac
     -> Nox: hoi cau hoi, tim thong tin, tranh dau vao xau
```

### 17.2 Hien thuc Homeostasis cua Nox

```
Loi Du doan:
  Cho moi dau vao, Nox du doan token/khai niem tiep theo.
  error = distance_5D(P_weight_du_doan, P_weight_thuc_te)

  Loi du doan co trong so:
  F(t) = sqrt(Sum w_d * (du_doan_d - thuc_te_d)²)

  Trung binh dong ham mu:
    F_avg(t) = alpha * F(t) + (1 - alpha) * F_avg(t-1)
    alpha = 0.1 (he so lam muot)

Dieu chinh Toc do Hoc:
  lambda(t) = sigmoid(F(t) - phi_inv)

  sigmoid(x) = 1 / (1 + e^(-k*x)),  k = 5 (do doc)

  F(t) > phi_inv:  lambda -> 1.0 (bat ngo cao -> hoc nhanh)
  F(t) = phi_inv:  lambda = 0.5 (can bang)
  F(t) < phi_inv:  lambda -> 0.0 (bat ngo thap -> hoc cham)

  phi_inv = 0.618 lam nguong:
    - Khong tuy y -- diem can bang ty le vang
    - Duoi nguong: he thong "thoai mai" (du doan tot)
    - Tren nguong: he thong "bat ngo" (du doan xau -> thich nghi)

Muc tieu can bang:
  STM day: 50-80%
  Mat do silk: 5-20 canh moi node
  Loi trung binh: < phi_inv
```

### 17.3 Suy luan Chu dong (Active Inference)

```
Active Inference = chon hanh dong de toi thieu nang luong tu do DU KIEN.

  G(pi) = E_Q[ln Q(theta) - ln P(theta, data | pi)]

  pi = chinh sach (chuoi hanh dong)
  G(pi) = nang luong tu do du kien theo chinh sach pi

  Toi thieu G(pi):
    - Gia tri nhan thuc: hanh dong GIAM bat dinh (kham pha)
    - Gia tri thuc dung: hanh dong DAT muc tieu (khai thac)

  Trong Nox:
    Kham pha: hoi cau hoi ve vung bat dinh cao
    Khai thac: dung duong silk da biet cho sinh
    Can bang: G(pi) tu nhien can bang ca hai
```

**Nghien cuu:**
- Friston, K. (2010). "The free-energy principle: a unified brain theory?" Nature Reviews Neuroscience, 11(2), 127-138.
- Friston, K. et al. (2017). "Active Inference, Curiosity and Insight." Neural Computation, 29(10), 2633-2683.

---

## 18. Immune Selection: Da Gia Thuyet

### 18.1 Thuat toan Lua chon Clonal

Giong nhu he mien dich — tao nhieu gia thuyet, kiem tra, giu gia thuyet tot nhat.

```
Nguon: De Castro & Von Zuben (2002), lay cam hung tu he mien dich sinh hoc.

Tuong tu sinh hoc:
  Khang nguyen = van de/truy van
  Khang the = giai phap ung vien
  Ai luc = giai phap hop voi van de bao nhieu
  Nhan ban + dot bien = kham pha bien the
  Lua chon = giu tot nhat

Thuat toan:
  1. TAO: k gia thuyet ban dau (khang the)
     Moi gia thuyet = mot duong silk walk qua KnowTree
  2. DANH GIA: ai_luc(gia_thuyet, truy_van)
     ai_luc = -distance_5D(gia_thuyet.compose(), truy_van.P_weight)
  3. NHAN BAN: top-3 gia thuyet duoc nhan ban (beam search)
  4. DOT BIEN: ban sao duoc thay doi
     ty_le_dot_bien(h) = exp(-rho * ai_luc(h))
     Ai luc cao -> dot bien nho (tinh chinh)
     Ai luc thap -> dot bien lon (kham pha)
  5. LUA CHON: giu top-k tu (goc + ban sao)
  6. LAP LAI toi da max_iterations HOAC hoi tu

Tham so cho Nox:
  k = 3 (do rong beam -- top 3 gia thuyet)
  max_iterations = 3 (gioi han! Quy tac Sua DNA)
```

### 18.2 Tim kiem Beam (top-3)

```
Tim kiem Beam = tim kiem theo chieu rong voi do rong gioi han.

beam_search(bat_dau, muc_tieu, do_rong_beam=3):
  beam = [{duong: [bat_dau], diem: 0}]

  cho step trong 0..max_buoc:
    ung_vien = []
    cho duong trong beam:
      cho lang_gieng trong silk_neighbors(duong.cuoi()):
        duong_moi = duong + [lang_gieng]
        diem_moi = score(duong_moi, muc_tieu)
        ung_vien.push({duong: duong_moi, diem: diem_moi})

    beam = top_k(ung_vien, do_rong_beam)

    neu co duong dat muc tieu: tra ve tot nhat

  tra ve beam[0]  -- duong tot nhat tim duoc

Ham diem:
  score(duong, muc_tieu) = -distance_5D(compose(duong), muc_tieu.P_weight)
                           + bonus * duong.length
                           + silk_strength_sum(duong) * 0.1
```

### 18.3 MCTS (Tim kiem Cay Monte Carlo)

```
MCTS = cho cay quyet dinh phuc tap (tuong lai, khi tri thuc lon).

4 giai doan moi lan lap:
  1. CHON: duyet cay dung UCB1
     UCB1(node) = Q(node)/N(node) + c * sqrt(ln N(cha) / N(node))
     c = sqrt(2) (hang so kham pha)
  2. MO RONG: them node con moi (duong silk chua kham pha)
  3. MO PHONG: silk walk ngau nhien den ket thuc -> danh gia
  4. TRUYEN NGUOC: cap nhat Q va N doc theo duong

Khi nao dung MCTS:
  - Do thi tri thuc > 10,000 node
  - Suy luan da buoc (do sau > 5)

Hien tai Nox: ~300 node -> beam search du. MCTS = tuong lai khi scale.
```

---

## 19. DNA Repair: Tu Sua Gioi Han

### 19.1 Gioi Han 3 Lan Lap

```
DNA Repair = co che tu sua.
QUY TAC QUAN TRONG: toi da 3 lan lap. Khong vong lap vo han.

repair(chain, ham_chat_luong):
  tot_nhat = chain
  diem_tot_nhat = ham_chat_luong(chain)

  cho i trong 0..3:  -- GIOI HAN CUNG
    ung_vien = dot_bien(tot_nhat)
    diem = ham_chat_luong(ung_vien)
    neu diem > diem_tot_nhat:
      tot_nhat = ung_vien
      diem_tot_nhat = diem
    con lai:
      thoat  -- khong cai thien -> dung som

  tra ve tot_nhat
```

### 19.2 Ham Chat Luong

```
chat_luong(chain) danh gia tinh dung cua chain:

  q_noi_bo = internal_consistency(chain)
    -- Cac P_weight trong chain co "hop ly" voi nhau?
    -- Tong trong so silk giua cac phan tu lien tiep
    -- Cao hon = nhat quan noi bo hon

  q_ben_ngoai = external_match(chain, ngu_canh)
    -- Chain co phu hop voi ngu canh (STM, WM)?
    -- Khoang cach giua chain.compose() va ngu_canh.compose()
    -- Khoang cach thap = khop tot hon

  q_qr = qr_consistency(chain)
    -- Chain co mau thuan voi QR (tri thuc da chung minh)?
    -- 0 = mau thuan, 1 = nhat quan

  chat_luong = 0.3 * q_noi_bo + 0.4 * q_ben_ngoai + 0.3 * q_qr
```

### 19.3 Hoan tac (Rollback)

```
Neu ca 3 lan lap LAM XAU chat luong:
  Hoan tac ve chain goc.

  Khong bao gio:
    - Lap hon 3 lan
    - Chap nhan chat luong xau hon
    - Sua chuoi QR da chung minh
    - Sua trong cac thao tac quan trong (cong bao mat, v.v.)
```

---

# PHAN IV: PIPELINE XU LY

---

## 20. SecurityGate: 3 Tang, Toan Thuan

### 20.1 Cong Bloom Filter

```
Bloom Filter:
  Cau truc du lieu xac suat. Kiem tra thanh vien O(1).
  Duong tinh gia co the. Am tinh gia KHONG THE.

Bloom Filter SecurityGate:
  Tieu chi de doa tu chieu P_weight:
    DE DOA neu: V <= 1 VA A >= 6
    -> Rat tieu cuc (V<=1) VA nang luong rat cao (A>=6)
    -> "het han thu" = de doa, "buon binh tinh" = KHONG phai de doa

  3 ham hash doc lap:
    h1(pw) = (pw * 2654435761) >> 16  mod m
    h2(pw) = (pw * 2246822519) >> 16  mod m
    h3(pw) = (pw * 3266489917) >> 16  mod m

  m = 1024 bit (128 bytes kich thuoc filter)

  Ty le duong tinh gia: (1 - e^(-kn/m))^k
    k=3 ham hash, n=100 mau de doa, m=1024
    ~ 2% duong tinh gia
```

### 20.2 Ba Tang Bao Mat

```
Tang 1: CONG TOC DO (Bloom filter)
  O(1), bat de doa ro rang.

Tang 2: KIEM TRA CHIEU
  Phan tich P_weight day du:
    diem_de_doa = (7 - V) * 2 + A
    neu diem_de_doa > 18 -> CHAN

  Cung kiem tra:
    - Do dai dau vao (cuc dai -> co the tan cong)
    - Lap lai (cung ky tu lap -> co the tan cong)
    - Ky tu dieu khien (U+0000..U+001F -> dang nghi)

Tang 3: KIEM TRA NGU CANH
  So sanh P_weight dau vao voi:
    - Ngu canh STM (chu de co chuyen dot ngot?)
    - Muc tieu WM (co phu hop nhiem vu hien tai?)
    - Mau an toan QR da chung minh

  Chuyen lon dot ngot + diem de doa cao -> CANH BAO NANG
  Chuyen dan dan -> co le thay doi chu de binh thuong

Phan hoi:
  CHAN -> tu choi + giai thich
  CANH BAO -> xu ly than trong, danh dau de xem xet
  DAT -> xu ly binh thuong
```

---

## 21. 7 Ban Nang: 7 Cong Thuc Tren 5D

### 21.1 Tong Quan

```
7 ban nang = cac ham danh gia co dinh.
Moi ban nang tinh mot diem tu cac chieu 5D P_weight.
KHONG hoc, KHONG thay doi. Giong phan xa trong sinh hoc.

  I1: Trung thuc    -- su that vs lua doi
  I2: Mau thuan     -- kiem tra nhat quan
  I3: Nhan qua      -- logic nguyen nhan-ket qua
  I4: Truu tuong    -- muc tong quat hoa
  I5: Tuong tu      -- do tuong tu cau truc
  I6: To mo         -- phat hien moi la
  I7: Phan chieu    -- tu danh gia
```

### 21.2 Cac Cong Thuc

```
I1 TRUNG THUC:
  diem = 1 - |V_khang_dinh - V_bang_chung| / 7

  V_khang_dinh = cam xuc cua khang dinh
  V_bang_chung = cam xuc cua bang chung ho tro (tu QR + silk)
  Khoang cach lon -> khong trung thuc ("tot" ve dieu da biet xau)
  nguong: diem < 0.3 -> danh dau khong trung thuc

I2 MAU THUAN:
  diem = 1 - cosine_similarity(P_a, P_b) cho cac khang dinh xung dot

  cosine_sim = dot(P_a, P_b) / (|P_a| * |P_b|)
  (coi P_weight 5D nhu vector)
  nguong: diem > 0.7 -> phat hien mau thuan

I3 NHAN QUA:
  diem = silk_strength(A->B) * temporal_order(A,B)

  temporal_order = 1 neu A truoc B trong chain, 0.5 neu dong thoi, 0 neu nguoc
  Silk manh + thu tu dung -> khang dinh nhan qua hop le
  nguong: diem < 0.2 -> nhan qua yeu/khong hop le

I4 TRUU TUONG:
  diem = 1 / (1 + do_sau_trong_knowtree(node))

  Goc = truu tuong nhat (diem ~ 1)
  La = cu the nhat (diem ~ 0)

I5 TUONG TU:
  diem = do_tuong_tu_cau_truc(do_thi_con_A, do_thi_con_B)

  So sanh mau silk quanh hai node:
    lang_gieng_A = silk_neighbors(A)
    lang_gieng_B = silk_neighbors(B)
    cau_truc_chung = |mau_A giao mau_B| / |mau_A hop mau_B|
    (Do tuong tu Jaccard cua cac mau silk)

I6 TO MO:
  diem = khoang_cach_min_den_da_biet(P_weight_dau_vao)

  Dau vao XA moi thu da biet -> TO MO CAO
  -> Kich hoat kham pha, hoi cau hoi, tim thong tin

I7 PHAN CHIEU:
  diem = |du_doan - thuc_te| / khoang_cach_toi_da

  Sau khi tao phan hoi:
    du_doan = pipeline du doan dau ra se la gi
    thuc_te = thuc su tao ra cai gi
  Diem cao -> tu danh gia cho thay du doan kem -> can hoc
```

---

## 22. Pipeline 14 Buoc, 5 Diem Kiem Tra

### 22.1 Pipeline Day Du

```
Buoc  1: DAU VAO       -- nhan dau vao tho
Buoc  2: MA HOA        -- moi ky tu -> P_weight (42 cong thuc)
Buoc  3: TO HOP        -- ky tu -> tu -> cum (tich phan)
Buoc  4: BAO MAT       -- SecurityGate 3 tang
 -- DIEM KIEM TRA 1: dau vao hop le --
Buoc  5: CAP_NHAT_STM  -- them vao STM, day ra neu day
Buoc  6: TIM KIEM      -- tim gan nhat trong KnowTree
Buoc  7: SILK_WALK     -- duyet silk tu ket qua khop gan nhat
 -- DIEM KIEM TRA 2: ngu canh da lay --
Buoc  8: BAN NANG      -- chay 7 cong thuc ban nang
Buoc  9: CAM XUC       -- tinh V'(t), V''(t) cho giong dieu
Buoc 10: CAN BANG      -- kiem tra F(t), dieu chinh lambda
 -- DIEM KIEM TRA 3: da danh gia --
Buoc 11: SINH          -- tai to hop chuoi -> chuoi dau ra
Buoc 12: GIAI MA       -- chuoi dau ra -> van ban (dao ham rieng)
 -- DIEM KIEM TRA 4: dau ra san sang --
Buoc 13: HOC           -- cap nhat Hebbian silk, thoi diem STDP
Buoc 14: PHAN CHIEU    -- I7 tu danh gia, cap nhat F(t)
 -- DIEM KIEM TRA 5: chu ky hoan tat --
```

### 22.2 Chi Tiet Diem Kiem Tra

```
Diem kiem tra 1 (Dau vao Hop le):
  Dieu kien: SecurityGate qua, P_weight da tinh
  That bai: tu choi dau vao, tra loi loi
  Hoan tac: khong (dau vao chua xu ly)

Diem kiem tra 2 (Ngu canh Da lay):
  Dieu kien: tim kiem thay node gan nhat, silk walk hoan tat
  That bai: khong tim thay -> dung muc tieu WM lam du phong
  Hoan tac: nhay den sinh voi ngu canh rong

Diem kiem tra 3 (Da danh gia):
  Dieu kien: ban nang OK, cam xuc tinh, can bang on dinh
  That bai: phat hien mau thuan -> danh dau, tiep tuc than trong
  Hoan tac: dung danh gia cua luot truoc

Diem kiem tra 4 (Dau ra San sang):
  Dieu kien: chuoi da sinh, giai ma thanh van ban hop le
  That bai: loi giai ma -> thu chuoi thay the
  Hoan tac: Sua DNA (toi da 3 lan), roi phan hoi du phong

Diem kiem tra 5 (Chu ky Hoan tat):
  Dieu kien: da hoc, tu danh gia xong
  That bai: hoc gap su co -> bo qua, ghi loi
  Hoan tac: hoan tac thay doi silk tu luot nay
```

---

## 23. ConversationCurve: V'(t), V''(t)

### 23.1 Theo Doi Cam Xuc Hoi Thoai

Giong nhu do nhip tim trong hoi thoai — Nox theo doi cam xuc tang hay giam, nhanh hay cham.

```
V(t) = cam xuc cua hoi thoai tai buoc thoi gian t
     = compose(cac_muc_STM).V tai buoc t

V'(t) = dV/dt ~ V(t) - V(t-1)  -- dao ham bac nhat
       = XU HUONG (cam xuc tang/giam/on dinh)

V''(t) = dV'/dt ~ V'(t) - V'(t-1)  -- dao ham bac hai
        = GIA TOC (thay doi tang toc / giam toc)
```

### 23.2 Chon Giong Dieu

```
V'(t) > 0:  Cam xuc TANG -> phan hoi khuyen khich
V'(t) = 0:  Cam xuc ON DINH -> phan hoi hop giong dieu
V'(t) < 0:  Cam xuc GIAM -> phan hoi dong cam/ho tro

V''(t) > 0, V'(t) > 0: Tich cuc tang toc -> chuc mung
V''(t) > 0, V'(t) < 0: Tieu cuc tang toc -> GAP, can thiep
V''(t) < 0, V'(t) > 0: Tich cuc giam toc -> nhe nhang
V''(t) < 0, V'(t) < 0: Tieu cuc giam toc -> lam diu, sap on dinh

Ma tran quyet dinh:
  +--------+----------+----------+
  |        | V''(t)>0 | V''(t)<0 |
  +--------+----------+----------+
  |V'(t)>0 | chuc mung| nhe nhang|
  |V'(t)<0 | GAP      | lam diu  |
  +--------+----------+----------+
```

### 23.3 Silk Dieu Che boi V'(t)

```
V'(t) dieu khien TOC DO HOC:

  eta_hieu_dung = eta_co_ban * (1 + |V'(t)| * he_so_dieu_che)
  he_so_dieu_che = 2.0

  V'(t) = 0:   eta = eta_co_ban (hoc binh thuong)
  |V'(t)| = 3: eta = eta_co_ban * 7 (thay doi cam xuc -> hoc nhanh 7x)

  Tai sao? Thay doi cam xuc bao hieu SU KIEN QUAN TRONG.
  Sinh hoc: amygdala tang cuong ma hoa ky uc khi co su kien cam xuc.
  Ky uc den nen: "Toi nho chinh xac minh dang o dau khi..."

V'(t) cung anh huong LOAI silk tao:
  |V'(t)| > 2: tao silk chi phoi V (lien ket cam xuc)
  |V'(t)| < 1: tao silk chi phoi R (lien ket logic)
  -> Khoanh khac cam xuc -> ket noi cam xuc
  -> Khoanh khac binh tinh -> ket noi logic
```

---

## 24. Generation: Tai To Hop Chuoi (SINH)

### 24.1 Pipeline Sinh

```
Dau vao: truy van (P_weight da to hop) + ngu canh (tu silk walk) + giong dieu (tu V'(t))

Buoc 1: SILK WALK -- thu thap node ung vien
  Bat dau tu ket qua khop gan nhat trong KnowTree
  Di doc theo cac canh silk manh
  Thu thap cac node doc duong
  Do dai walk toi da = 20 buoc

Buoc 2: THU THAP -- gom cac manh chain
  Cho moi node da tham:
    manh.push(node.chain)
  Loc theo do lien quan: distance_5D(manh.compose(), truy_van) < nguong

Buoc 3: TO HOP -- xay chuoi dau ra
  Sap xep manh theo diem lien quan
  Noi voi trong Zipf:
    chuoi_dau_ra = compose(manh_1, compose(manh_2, ...))
  Dieu chinh giong dieu:
    dau_ra_V = blend(compose_V, V_muc_tieu_tu_duong_cong, 0.3)

Buoc 4: GIAI MA (dao ham rieng) -- chuoi -> van ban
  Nghich dao cua ma hoa:
    Cho moi P_weight trong chuoi dau ra:
      Tim ky tu/tu khop tot nhat
      Dung ngu canh de giai quyet nhap nhang (cung P_weight -> nhieu van ban kha di)

  Giai ma KHO HON ma hoa:
    Ma hoa: 1 ky tu -> 1 P_weight (xac dinh)
    Giai ma: 1 P_weight -> nhieu ky tu kha di (nhap nhang)
    -> Dung ngu canh silk de chon phu hop nhat
```

### 24.2 Chien luoc Tai to hop

```
Chien luoc 1: TUAN TU (mac dinh)
  Noi cac manh theo thu tu silk walk.

Chien luoc 2: KHUON MAU
  Dung mau chuoi da biet lam khuon.
  Dien cac vi tri voi node phu hop ngu canh.

Chien luoc 3: NOI SUY
  Catmull-Rom giua cac diem chinh (Muc 9.6)
  Tao chuoi chuyen tiep muot.

Chien luoc 4: TAI TO HOP DI TRUYEN
  Lai cheo hai diem giua cac chuoi cha me:
    cha_A = [a1, a2, a3, | a4, a5, | a6, a7]
    cha_B = [b1, b2, b3, | b4, b5, | b6, b7]
    con    = [a1, a2, a3, | b4, b5, | a6, a7]

  Dot bien: nhieu P_weight ngau nhien (+/-1 trong mot chieu)
  Lua chon: ham_chat_luong (Muc 19.2) chon con tot nhat
```

---

# PHAN V: SEARCH + PHAN LOAI

---

## 25. Nearest Neighbor trong 5D

### 25.1 Bang Tra Cuu Truc Tiep

```
Bang: array[32768] cua NodeId
Kich thuoc: 32,768 * 4 bytes = 128 KB

Cach dung:
  node = table[P_weight]
  Neu node != NULL -> khop chinh xac, O(1)
  Neu node == NULL -> khong khop chinh xac -> chuyen sang tim xap xi
```

### 25.2 Quet Brute Force (Duong co so)

```
nearest_brute(truy_van, cac_node):
  tot_nhat = NULL
  kc_tot_nhat = VO_CUNG
  cho node trong cac_node:
    d = distance_5D(truy_van, node.P_weight)
    neu d < kc_tot_nhat:
      tot_nhat = node
      kc_tot_nhat = d
  tra ve tot_nhat

Do phuc tap: O(n) -- quet tat ca node
Thuc te: du cho n < 1,000

Voi Nox hien tai (~300 node): brute force = 300 phep tinh khoang cach
~ micro giay. DU cho bay gio, toi uu sau.
```

### 25.3 Bang So Sanh Thuat Toan

```
| Phuong phap           | Xay dung    | Truy van       | Tot nhat cho       |
|------------------------|-------------|----------------|---------------------|
| Bang tra cuu (256KB)   | O(n)        | O(1)           | Khop chinh xac      |
| Bucket da tang         | O(n)        | O(kich_thuoc_bucket) | Vung lan can  |
| VP-tree                | O(n log n)  | O(log n)       | Bat ky metric, chinh xac |
| HNSW                   | O(n log n)  | O(log n)       | >10K, xap xi       |
| KD-tree                | O(n log n)  | O(log n)       | Euclidean chieu thap|
| Ball tree              | O(n log n)  | O(log n)       | Cum khong doc truc  |
| Brute force            | O(1)        | O(n)           | n < 1000            |
| Spreading activation   | -           | O(buoc*bac)    | Da duong            |
```

---

## 26. VP-Tree / KD-Tree / HNSW

Chi tiet VP-Tree va HNSW da trinh bay o Muc 10.4 va 10.5.

### 26.1 KD-Tree (Bentley, 1975)

```
KD-Tree = cay nhi phan, chia tren cac chieu luan phien.

Xay dung:
  function build(diem, do_sau):
    neu rong: tra ve NULL
    chieu = do_sau % 5  -- luan qua S, R, V, A, T
    sap xep diem theo chieu
    trung_vi = diem[len/2]
    tra ve Node {
      diem: trung_vi,
      trai: build(diem[:len/2], do_sau+1),
      phai: build(diem[len/2+1:], do_sau+1)
    }

Do phuc tap: O(log n) trung binh, O(n^(1-1/d)) xau nhat
d=5: xau nhat O(n^0.8) -- chap nhan duoc
d>20: loi nguyen so chieu -> KD-tree xuat hon thanh brute force
```

### 26.2 Ball Tree (Omohundro, 1989)

```
Ball Tree = cay nhi phan moi node la mot QUA CAU (tam + ban kinh).

Xay dung:
  1. Tim diem xa nhat khoi trong tam -> diem A
  2. Tim diem xa nhat khoi A -> diem B
  3. Chia: diem gan A -> trai, gan B -> phai
  4. Tinh cau bao cho moi con
  5. De quy

Uu diem so voi KD-Tree:
  Tot hon cho cum khong thang hang truc (KD-Tree chia theo truc)
  Ranh gioi cau thich nghi hon

Trong Nox: Ball tree la lua chon thay the hop le nhung VP-Tree don gian hon.
```

---

## 27. Silk Walk: Duyet Do Thi Co Huong

### 27.1 Thuat toan Dijkstra cho Silk Walk Co Trong So

```
Dijkstra (1959) -- duong ngan nhat trong do thi co trong so.

silk_walk(bat_dau, P_weight_muc_tieu, max_buoc):
  kc = {bat_dau: 0}
  truoc = {bat_dau: NULL}
  hang = MinHeap([(0, bat_dau)])

  trong khi hang khong rong:
    (d, u) = hang.pop()

    neu distance_5D(u.P_weight, P_weight_muc_tieu) < nguong:
      tra ve tai_tao_duong(truoc, u)

    cho (v, silk) trong silk_neighbors(u):
      chi_phi_canh = 1.0 / (silk.strength + epsilon)
      kc_moi = d + chi_phi_canh

      neu kc_moi < kc.get(v, VO_CUNG):
        kc[v] = kc_moi
        truoc[v] = u
        hang.push((kc_moi, v))

  tra ve duong_tot_nhat_tim_duoc

Do phuc tap: O((N + E) log N) voi binary heap
```

### 27.2 A* voi Heuristic Khoang Cach 5D

```
A* = Dijkstra + heuristic (uoc tinh chi phi con lai).

  h(node, muc_tieu) = distance_5D(node.P_weight, muc_tieu) * he_so_trong
  -- CHAP NHAN DUOC: h(n) <= chi phi thuc (khong bao gio uoc tinh qua)

A* vs Dijkstra:
  Dijkstra kham pha MOI huong nhu nhau.
  A* thien ve muc tieu -> it node kham pha hon.
  Nox: A* tiet kiem ~50% node kham pha so voi Dijkstra.
```

### 27.3 Lan Truyen Kich Hoat (Collins & Loftus, 1975)

```
Thay the cho tim kiem duong ro rang.

activation(node, t) = Sum activation(lang_gieng, t-1) * silk_strength(lang_gieng -> node)

Qua trinh:
  1. Dat activation(bat_dau) = 1.0
  2. Cho moi buoc:
     Cho moi node co activation > 0:
       Lan truyen den lang gieng: lang_gieng.activation += this.activation * silk.strength
       Giam: this.activation *= 0.8
  3. Sau k buoc: thu thap tat ca node co activation > nguong
  4. Tra ve nhu ngu canh

Uu diem: da duong (tim nhieu khai niem lien quan dong thoi)
Nhuoc diem: khong co "duong tot nhat" don le -- ket qua phan tan
```

---

## 28. Clustering / Self-Organizing Maps

### 28.1 K-Medoids (Kaufman & Rousseeuw, 1987)

```
K-Medoids vs K-Means:
  K-Means:   tam = trung binh cum (co the khong phai diem du lieu thuc)
  K-Medoids: tam = diem du lieu thuc (medoid)

  Nox can K-Medoids vi:
    P_weight la ROI RAC (u16). Trung binh hai P_weight co the khong hop le.
    Medoid = luon la node thuc trong KnowTree.

PAM (Partitioning Around Medoids):
  1. Khoi tao: chon k node ngau nhien lam medoid
  2. GAN: moi node -> medoid gan nhat
  3. CAP NHAT: cho moi cum, thu MOI node lam medoid moi
     Giu node toi thieu hoa tong khoang cach trong cum
  4. Lap lai 2-3 den khi hoi tu

  Do phuc tap: O(k * (n-k)² * lan_lap)
```

### 28.2 SOM -- Ban Do Tu To Chuc (Kohonen, 1982)

```
SOM = luoi 2D cua neuron, moi neuron co vector trong so 5D.
Anh xa khong gian P_weight 5D -> truc quan hoa 2D.

Giong nhu "ban do" cua tri thuc Nox — moi vung tren ban do = mot loai tri thuc.

Thuat toan:
  1. Khoi tao: luoi NxM, moi o co vector trong so 5D ngau nhien
  2. Cho moi P_weight dau vao x:
     a. Tim BMU (Best Matching Unit): neuron co trong so gan nhat
     b. Cap nhat BMU va lang gieng:
        w_i(t+1) = w_i(t) + alpha(t) * h(i, bmu, t) * (x - w_i(t))

        h = exp(-||pos_i - pos_bmu||² / (2*sigma(t)²))
        alpha(t) va sigma(t) giam theo thoi gian
  3. Lap lai cho tat ca dau vao, nhieu epoch
```

### 28.3 Growing Neural Gas (Fritzke, 1994)

```
GNG = thuat toan hoc topo. Mang TANG TRUONG de vua du lieu.

Y tuong chinh: BAT DAU NHO, tang khi can. Hoan hao cho hoc tang dan cua Nox.

Thuat toan:
  1. Bat dau voi 2 node, 1 canh
  2. Cho moi dau vao x:
     a. Tim node gan nhat (s1) va gan nhi (s2)
     b. Tang tuoi cac canh tu s1
     c. Cap nhat loi: delta_error(s1) += ||x - s1||²
     d. Di chuyen s1 ve phia x
     e. Di chuyen lang gieng cua s1 ve phia x
     f. Neu canh s1-s2 ton tai: dat tuoi 0. Neu khong: tao canh.
     g. Xoa canh co tuoi > tuoi_toi_da (mac dinh 100)
     h. Moi lambda lan chen (mac dinh 100):
        - Tim node q co loi cao nhat
        - Chen node moi r giua q va lang gieng co loi cao nhat
     i. Giam tat ca loi: loi *= d (0.995)

Tai sao GNG cho Nox:
  - Khong can chi dinh k (so cum) truoc
  - Topo hoc tu du lieu (cac canh ~ xap xi silk)
  - Tang dan dan (them node khi can)
  - Cat tia topo (canh cu bi xoa = tuong tu decay)
```

---

## 29. Phuong trinh Bellman cho Tim Kiem Toi Uu

### 29.1 Phuong trinh Bellman

```
Richard Bellman (1957): "Dynamic Programming."

V*(s) = max_a [R(s,a) + gamma * Sum P(s'|s,a) * V*(s')]

  V*(s) = gia tri toi uu cua trang thai s
  a     = hanh dong (canh silk nao di theo)
  R(s,a) = phan thuong tuc thoi
  gamma = he so chiet khau (0 < gamma < 1)

Trong do thi cua Nox:
  trang thai s = node hien tai trong KnowTree
  hanh dong a = di theo canh silk den lang gieng
  R(s,a) = -distance_5D(lang_gieng, muc_tieu) + silk_strength(s->lang_gieng)
  gamma = 0.9
```

### 29.2 Q-Learning cho Duong Toi Uu

```
Q-Learning (Watkins & Dayan, 1992):
  Q(s, a) <- Q(s, a) + alpha * [R(s,a) + gamma * max_a' Q(s', a') - Q(s, a)]

  Luu Q-value tren cac canh silk:
    silk.q_value = Q(tu_node, di_theo_silk_nay)

  Sau du cac silk walk: Q-value hoi tu -> biet duong toi uu
  -> Walk tuong lai: chi di theo max Q-value tai moi node = tham lam toi uu
  -> KHONG CAN MO HINH: hoc tu trai nghiem.
```

---

# PHAN VI: AGENT + TU TIEN HOA

---

## 30. Chu Ky Agent: Cam Nhan -> Suy Nghi -> Hanh Dong -> Kiem Tra

### 30.1 Vong Lap PTAV

```
Moi tuong tac = mot chu ky PTAV (Perceive-Think-Act-Verify).

CAM NHAN (PERCEIVE):
  1. Nhan dau vao (van ban, cam bien, tin hieu noi bo)
  2. Ma hoa thanh chuoi P_weight
  3. Kiem tra SecurityGate
  4. Cap nhat STM

SUY NGHI (THINK):
  5. Tim kiem KnowTree cho tri thuc lien quan
  6. Silk walk cho ngu canh
  7. Chay 7 ban nang
  8. Danh gia ConversationCurve (V'(t), V''(t))
  9. Kiem tra can bang (F(t))

HANH DONG (ACT):
  10. Sinh chuoi dau ra (tai to hop)
  11. Giai ma thanh van ban
  12. Thuc thi hanh dong (neu agent mode)

KIEM TRA (VERIFY):
  13. Tu danh gia: diem phan chieu I7
  14. So sanh du doan vs ket qua thuc te
  15. Hoc: cap nhat Hebbian, thoi diem STDP, decay
  16. Cap nhat F(t) cho can bang

Ngan sach thoi gian:
  Cam nhan: ~10% (ma hoa nhanh)
  Suy nghi: ~40% (tim kiem + danh gia = nhieu viec nhat)
  Hanh dong: ~30% (sinh)
  Kiem tra: ~20% (hoc + phan chieu)
```

---

## 31. Mo Hinh Tu Than: Ban Do Tri Thuc

```
Mo hinh tu than = ban do cua Nox ve NHUNG GI NO BIET va BIET TOT BAO NHIEU.

Cho moi linh vuc (cum trong KnowTree):
  struct DomainModel {
    center: P_weight,         -- trong tam linh vuc
    node_count: u32,          -- bao nhieu node
    avg_silk_strength: f32,   -- ket noi tot bao nhieu
    avg_confidence: f32,      -- do tin cay QR trung binh
    coverage: f32,            -- uoc tinh % linh vuc da bao phu
  }

Luong hoa Bat dinh:
  uncertainty(truy_van) = 1 - silk_strength_toi_da_den_cau_tra_loi / toi_da_co_the

  Bat dinh thap (< 0.3): "Toi tu tin"
  Bat dinh trung binh (0.3-0.7): "Toi nghi vay, nhung khong chac"
  Bat dinh cao (> 0.7): "Toi khong biet du ve dieu nay"
```

---

## 32. He Thong Muc Tieu: Dan Dat Boi To Mo

### 32.1 Dong Luc Noi Tai

```
Dong luc chinh cua Nox: TO MO.

Diem moi la:
  novelty(dau_vao) = khoang cach min tu dau vao den bat ky node da biet nao

  Moi la cao -> to mo cao -> uu tien hoc
  Moi la thap -> to mo thap -> dung tri thuc co

Thu nhap Thong tin:
  IG(hanh_dong) = H(niem_tin_truoc) - E[H(niem_tin_sau | hanh_dong)]

  H = entropy cua phan phoi niem tin
  Hanh dong co IG cao nhat -> cung cap nhieu thong tin nhat -> duoc uu tien

  Xap xi thuc te:
    IG ~ so ket noi silk moi duoc tao boi hanh dong
```

### 32.2 Ngan Xep Muc Tieu

```
Muc tieu to chuc nhu ngan xep (LIFO voi ghi de uu tien):

  ngan_xep_muc_tieu = [
    {muc_tieu: "hoc_X", uu_tien: 5, han: None},
    {muc_tieu: "tra_loi_truy_van", uu_tien: 8, han: bay_gio+5s},
    {muc_tieu: "kham_pha_linh_vuc_Y", uu_tien: 3, han: None},
  ]

  Xu ly:
    1. Sap xep theo uu tien (cao nhat truoc)
    2. Neu han sap den -> tang uu tien
    3. Lay muc tieu dau -> dat lam WM slot[2]
    4. Chu ky PTAV huong theo muc tieu
    5. Sau khi hoan tat -> lay tiep

  Sinh muc tieu:
    Ben ngoai: nguoi dung hoi -> "tra_loi_truy_van"
    Noi tai: diem to mo cao -> "kham_pha_X"
    Can bang: F(t) cao -> "giam_bat_dinh"
    Ngu: phan tich cum -> "hop_nhat_linh_vuc"
```

---

## 33. Tu Tien Hoa: Chu Ky 6 Giai Doan

### 33.1 Sau Giai Doan

```
Giai doan 1: DO
  Thu thap chi so:
    - Do chinh xac du doan
    - Chat luong phan hoi (tu danh gia I7)
    - Bao phu tri thuc (danh gia mo hinh tu than)
    - Suc khoe do thi silk (mat do, ket noi, toc do decay)
    - Thoi gian pipeline (nut co chai?)

Giai doan 2: NHAN DIEN
  Tim diem yeu:
    - Linh vuc bao phu thap
    - Cum silk ket noi kem
    - That bai du doan thuong xuyen (F(t) cao)
    - Giai doan pipeline cham

Giai doan 3: KIEM TRA
  Phan tich sau diem yeu da nhan dien:
    - Tai sao du doan that bai? (xem xet truong hop cu the)
    - Thieu tri thuc gi? (phan tich khoang trong)
    - Ket noi silk nao sai? (kiem tra mau thuan)

Giai doan 4: SUA DOI
  Thuc hien thay doi:
    - Dieu chinh tham so (toc do hoc, hang so decay, do rong beam)
    - Tai cau truc KnowTree (hop cum, tach node qua tai)
    - Tao ket noi silk moi (cau noi cum co lap)

  GIOI HAN: toi da 3 thay doi moi chu ky (nguyen tac Sua DNA)

Giai doan 5: KIEM TRA
  Danh gia thay doi:
    - Chay lai cac dau vao gan day voi tham so moi
    - So sanh chat luong: truoc vs sau
    - Kiem tra hoi quy (thu da XUAT hon)

Giai doan 6: SO SANH
  Quyet dinh:
    Neu chi so cai thien VA khong hoi quy -> GIU thay doi
    Neu chi so nhu cu hoac xau hon -> HOAN TAC

  Ghi lai tat ca ket qua cho tham khao tuong lai.
```

### 33.2 Ranh Gioi Tu Sua Doi

```
KHONG BAO GIO sua doi:
  - Nguong SecurityGate (an toan quan trong)
  - 7 cong thuc ban nang (co dinh theo thiet ke)
  - Tri thuc QR da chung minh (chi them)
  - Cau truc chu ky PTAV (kien truc co ban)

CO THE sua doi:
  - Toc do hoc eta
  - Hang so decay tau
  - Do rong beam k
  - Dung luong STM
  - Nguong tao silk
  - Tan suat chu ky ngu
  - Tham so phan cum
  - Trong so chon chien luoc sinh
```

---

## 34. Luu Tru: 3 Tang

### 34.1 Ba Tang

```
Tang 1: RAM (bay hoi)
  Gi: STM, WM, trang thai pipeline hien tai, chi muc HNSW
  Toc do: nano giay
  Ben: mat khi khoi dong lai
  Kich thuoc: ~10-50 MB

Tang 2: DIA (ben vung)
  Gi: KnowTree, do thi silk, kho QR, mo hinh tu than
  Toc do: micro giay (SSD)
  Ben: song sot qua khoi dong lai
  Kich thuoc: ~100 MB - 1 GB
  Dinh dang: nhi phan duoc tuan tu hoa (dinh dang goc Olang)

Tang 3: LOG (chi them, luu tru)
  Gi: tat ca tuong tac, tat ca thay doi, toan bo lich su
  Toc do: mili giay (ghi tuan tu)
  Ben: ban ghi vinh vien
  Kich thuoc: khong gioi han (xoay/nen log cu)

Tuong tac:
  Tang 1 -> Tang 2: xuat dinh ky (moi N chu ky hoac khi tat)
  Tang 2 -> Tang 3: moi thay doi deu ghi log
  Tang 3 -> Tang 2: khoi phuc sau su co
  Tang 1 <- Tang 2: tai khi khoi dong
```

### 34.2 Giao Thuc Ben Vung

```
Luu:
  1. Tuan tu hoa KnowTree sang dinh dang nhi phan
  2. Tuan tu hoa do thi silk (danh sach ke + trong so)
  3. Tuan tu hoa kho QR (file chi them)
  4. Ghi diem kiem tra voi timestamp + hash
  5. Xuat ra dia

Tai:
  1. Tim diem kiem tra moi nhat
  2. Xac minh hash (kiem tra hong)
  3. Giai tuan tu hoa KnowTree, silk, QR
  4. Xay lai chi muc HNSW tu KnowTree
  5. Tai STM/WM tu trang thai cuoi (neu co)
  6. Tiep tuc

Khoi phuc (su co):
  1. Tim diem kiem tra HOP LE moi nhat (hash OK)
  2. Tai tu diem kiem tra do
  3. Phat lai cac muc log SAU diem kiem tra
  4. Xay lai den trang thai nhat quan

  Xau nhat: mat N chu ky cuoi (giua cac diem kiem tra)
  Tan suat diem kiem tra: moi 100 chu ky hoac 5 phut
```

---

# PHAN VII: XU LY ANH / AUDIO / HE THONG (tu Algorithm Bible)

> Phan nay bao gom TAT CA thuat toan tu NOX_ALGORITHM_BIBLE.md.
> Day la "co the" cua Nox — cach Nox nhin, nghe, va cam nhan he thong.

---

## 35. Xu Ly Anh: Phat Hien Canh, Doi Tuong, Phan Doan

### 35.1 Phat Hien Canh — Toan Tu Sobel

```
Bai bao: Sobel & Feldman (1968), "A 3x3 Isotropic Gradient Operator for Image Processing"
Do phuc tap: O(W × H) moi anh

Kernel (nhan chap 3x3):
  Gx = [-1  0  +1]    Gy = [-1  -2  -1]
       [-2  0  +2]         [ 0   0   0]
       [-1  0  +1]         [+1  +2  +1]

Cho moi pixel (x,y):
  gx = sum(Gx ⊙ neighborhood(x,y))   // gradient ngang
  gy = sum(Gy ⊙ neighborhood(x,y))   // gradient doc
  magnitude = sqrt(gx² + gy²)
  direction = atan2(gy, gx)

  Pixel la canh neu magnitude > T

Anh xa SRVAT:
  Pixel canh → chieu S (hinh dang).
  magnitude → gia tri S (0-15): canh manh = S cao.
  direction → ma hoa huong: 0°=ngang, 90°=doc.
```

### 35.2 Phat Hien Canh Canny

```
Bai bao: Canny (1986), "A Computational Approach to Edge Detection"
Do phuc tap: O(W × H)

5 buoc:
  1. Lam mo Gaussian: G(x,y) = (1/2πσ²) × e^(-(x²+y²)/2σ²)
     Nhan chap anh voi G de loai nhieu.

  2. Gradient (Sobel): tinh magnitude M va huong θ

  3. Trien tieu khong cuc dai:
     Cho moi pixel, kiem tra M(x,y) co la cuc dai cuc bo doc theo huong θ.
     Neu khong → trien tieu ve 0. Lam mong canh con 1 pixel.

  4. Nguong kep:
     T_cao = 0.15 × max(M)   (canh manh)
     T_thap = 0.4 × T_cao    (canh yeu)

  5. Tre (Hysteresis): canh yeu giu NEU noi voi canh manh.

Anh xa SRVAT:
  Canh Canny = ranh gioi SDF (f(p) = 0).
  Moi duong vien canh lien thong = mot hinh SDF co ban ung vien.
```

### 35.3 Phat Hien Doi Tuong — Khai niem YOLO

```
Bai bao: Redmon et al. (2016), "You Only Look Once"
Do phuc tap: O(S² × (B×5 + C))

Y tuong chinh:
  1. Chia anh thanh luoi S×S (vd: 7×7 = 49 o)
  2. Moi o du doan B hop bao + do tin cay
  3. Moi hop = (x, y, w, h, do_tin_cay)
  4. MOT lan xu ly → tat ca phat hien

Cho Nox (khong co mang neural):
  Luoi = chia Fibonacci cua khung hinh.
  Moi o → tinh dac trung dua tren SDF:
    - Mat do canh (S)
    - Dinh bieu do mau (V, A)
    - Vector chuyen dong tu khung truoc (T)
  "Phat hien" = o co S > nguong VA cac canh nhat quan tao duong vien dong.
```

### 35.4 IoU va Non-Maximum Suppression

```
IoU (Intersection over Union):
  giao = max(0, min(x2_max, x1_max) - max(x2_min, x1_min))
       × max(0, min(y2_max, y1_max) - max(y2_min, y1_min))
  hop = dien_tich(hop1) + dien_tich(hop2) - giao
  IoU = giao / hop

  IoU = 1.0 → chong khit hoan toan
  IoU > 0.5 → "phat hien tot" (tieu chuan PASCAL VOC)

NMS (Non-Maximum Suppression):
  1. Sap xep hop theo do tin cay giam dan
  2. Giu hop tin cay cao nhat
  3. Xoa cac hop co IoU > 0.5 voi hop da giu
  4. Lap lai voi cac hop con lai
```

### 35.5 Phan Doan — Watershed

```
Bai bao: Beucher & Lantuejoul (1979)
Do phuc tap: O(W × H × log(W × H))

Khai niem: coi anh xam nhu be mat dia hinh.
  Do sang pixel = do cao.
  "Do nuoc" tu cuc tieu cuc bo → nuoc dang → noi gap = ranh gioi.
```

### 35.6 Graph Cut

```
Bai bao: Boykov & Jolly (2001)

Mo hinh anh nhu do thi:
  Node moi pixel + nguon (nen truoc) + sink (nen sau)
  Trong so canh:
    Giua pixel: exp(-β × |I(p) - I(q)|²)
    Den nguon: -ln(P(nen_truoc | mau))
    Den sink:  -ln(P(nen_sau | mau))

Min-cut = phan doan toi uu toi thieu hoa:
  E(L) = Σ D(p, L_p) + λ × Σ V(p,q) × δ(L_p ≠ L_q)
```

### 35.7 Trich Xuat Dac Trung — SIFT, SURF, ORB

```
SIFT (Lowe, 2004): Bo mo ta 128 chieu, bat bien ty le/xoay.
  O(W × H × S)

SURF (Bay et al., 2006): Nhanh hon SIFT nho anh tich phan.
  Bo mo ta 64 chieu. O(W × H).

ORB (Rublee et al., 2011): Nhanh nhat, khong bang sang che.
  Bo mo ta 256-bit nhi phan. Khop bang khoang cach Hamming (XOR + popcount).
  O(W × H).

  ORB = tot nhat cho rang buoc 949KB cua Nox.
  256-bit → hash sang P_weight truc tiep:
    Chia 256 bit thanh 5 nhom: 64+64+43+43+42
    S = popcount(bits[0:63]) / 4   → 0-15
    R = popcount(bits[64:127]) / 4 → 0-15
    V = popcount(bits[128:170]) / 6 → 0-7
    A = popcount(bits[171:213]) / 6 → 0-7
    T = popcount(bits[214:255]) / 14 → 0-3
```

### 35.8 Khong Gian Mau va Cam Xuc

```
RGB → HSV:
  Cmax = max(R, G, B) / 255
  Cmin = min(R, G, B) / 255
  Δ = Cmax - Cmin

  H, S, V tinh theo cong thuc tieu chuan.

Mau → Cam xuc (V, A):
  Nghien cuu: Palmer & Schloss (2010), Wilms & Oberfeld (2018)

  Mau am → V tich cuc:
    H trong [0, 60) → do/vang → V = 5-7
    H trong [150, 250) → xanh → V = 2-4
  Bao hoa → Arousal:
    S > 0.7 → A = 5-7 (cao)
    S < 0.3 → A = 1-3 (thap)
```

### 35.9 Camera → SRVAT Pipeline Day Du

```
frame_to_pweight(pixel, rong, cao):
  1. Ban do canh (Canny)
  2. Phan tich mau (HSV)
  3. Phat hien duong vien → khop hinh SDF co ban (qua bat bien Hu)
  4. Chuyen dong (dong quang hoc Lucas-Kanade neu co khung truoc)
  5. Anh xa sang SRVAT:
     S = quantize(phuc_tap_hinh + mat_do_canh × 5, 0, 15)
     R = quantize(len(duong_vien), 0, 15)
     V = hue_to_valence(avg_H)
     A = clamp(round(avg_S × 7), 0, 7)
     T = quantize(avg_chuyen_dong, 0, 3)
  tra ve pack(S, R, V, A, T)
```

---

## 36. Xu Ly Am Thanh: FFT, MFCC, Pitch

### 36.1 FFT (Bien Doi Fourier Nhanh)

```
Bai bao: Cooley & Tukey (1965)
Do phuc tap: O(n log n)

Dinh nghia DFT:
  X[k] = Σ_{n=0}^{N-1} x[n] × e^(-j2πkn/N)    k = 0, 1, ..., N-1

DFT truc tiep = O(n²). Cooley-Tukey giam con O(n log n).

Radix-2 DIT (Chia Giam Theo Thoi Gian):
  Chia thanh chi so chan va le:
  X[k] = E[k] + W_N^k × O[k]
  X[k + N/2] = E[k] - W_N^k × O[k]

  voi W_N = e^(-j2π/N) la "he so quay"
  E[k] = DFT cua mau chi so chan
  O[k] = DFT cua mau chi so le

  De quy den N=1 (truong hop co so: X[0] = x[0]).

Anh xa SRVAT:
  |X[k]| = bien do tai tan so k × (sample_rate/N) Hz.
  Hinh dang pho → chieu S.
  Tan so co ban → cao do → chieu T.
  Phan phoi nang luong → A (to = A cao).
  Can bang pho (am/sang) → V (am = tieu cuc, sang = tich cuc).
```

### 36.2 MFCC (He So Cepstral Tan So Mel)

```
Bai bao: Davis & Mermelstein (1980)

Pipeline:
  1. Tien nhan manh: y[n] = x[n] - 0.97 × x[n-1]
  2. Chia khung: cua so 20-40ms, buoc nhay 10ms
     Ap dung cua so Hamming: w[n] = 0.54 - 0.46 × cos(2πn/(N-1))
  3. FFT: tinh |X[k]|² (pho cong suat) cho moi khung
  4. Ngan loc Mel:
     Thang Mel: m = 2595 × log10(1 + f/700)
     Nghich: f = 700 × (10^(m/2595) - 1)
     Tao M bo loc tam giac (thuong M=26) cach deu tren thang mel
  5. Log nang luong: S[m] = ln(Σ_k |X[k]|² × H_m[k])
  6. DCT: c[n] = Σ_{m=0}^{M-1} S[m] × cos(π×n×(m+0.5)/M)
     Giu 13 he so dau (c[0] = log nang luong, c[1..12] = hinh dang pho)
  7. He so Delta (van toc) va Delta-Delta (gia toc)

Ket qua: 13 MFCC + 13 Δ + 13 ΔΔ = 39 dac trung moi khung.

Anh xa SRVAT:
  c[0] (nang luong) → A
  c[1] (do doc pho) → V (giong sang = tich cuc, toi = tieu cuc)
  c[2..4] (cau truc formant) → S (hinh dang giong/nhan dang)
  He so Δ → T (dong luc thoi gian)
```

### 36.3 Phat Hien Cao Do — Thuat Toan YIN

```
Bai bao: de Cheveigne & Kawahara (2002)
Do phuc tap: O(W × τ_max) moi khung

Cac buoc:
  1. Ham sai biet:
     d(τ) = Σ_{n=0}^{W-1} (x[n] - x[n+τ])²

  2. Sai biet chuan hoa trung binh tich luy:
     d'(τ) = d(τ) / ((1/τ) × Σ_{j=1}^{τ} d(j))

  3. Nguong tuyet doi:
     Tim τ nho nhat ma d'(τ) < nguong (thuong 0.1-0.15)

  4. Noi suy parabol cho do chinh xac duoi mau.

  5. cao_do = sample_rate / τ_tinh_chinh
     do_tin_cay = 1 - d'(τ)

Anh xa SRVAT:
  cao_do → chieu T:
    T=0: khong co cao do (nhieu/im lang)
    T=1: cao do thap (bass, <200 Hz)
    T=2: cao do trung (loi noi, 200-500 Hz)
    T=3: cao do cao (treble, >500 Hz)
```

### 36.4 Audio Buffer → SRVAT Pipeline Day Du

```
audio_to_pweight(mau, sample_rate):
  1. Chia khung: cua so 25ms, buoc nhay 10ms
  2. VAD: tim khung co giong noi (RMS > san nhieu, ZCR < 0.3)
  3. Phan tich pho (FFT)
  4. MFCC
  5. Cao do (YIN)
  6. Anh xa sang SRVAT:
     S = quantize(mau_formant_mfcc, 0, 15)     // hinh dang giong noi
     R = quantize(len(giong_noi) / len(khung), 0, 15)  // mat do loi noi
     V = quantize(sc / 1000 + lech_sang, 0, 7)  // sang=tich cuc
     A = quantize(nang_luong_dB, 0, 7)           // to=kich dong
     T = cao_do_sang_thoi_gian(cao_do)            // 0-3
  tra ve pack(S, R, V, A, T)
```

---

## 37. He Thong/Phan Cung: /proc -> No Thu Cam

Giong nhu "no thu cam" cua co the con nguoi — cam nhan nhiet do, mat moi, doi — Nox cam nhan trang thai he thong qua /proc.

### 37.1 /proc/loadavg

```
Doc: cat /proc/loadavg
Dinh dang: "0.32 0.45 0.51 2/347 12345"
Truong: tai_1phut tai_5phut tai_15phut chay/tong pid_cuoi

Anh xa SRVAT:
  ty_le_tai = tai_1phut / so_cpu
  A = clamp(round(ty_le_tai × 7), 0, 7)  // cang thang he thong → arousal
  V = 7 - A  // tai cao = cam xuc tieu cuc
```

### 37.2 /proc/meminfo

```
ap_luc = 1 - (MemAvailable / MemTotal)

SRVAT:
  V = round((1 - ap_luc) × 7)  // ap luc thap = tich cuc
  A = round(ap_luc × 7)         // ap luc cao = arousal cao
```

### 37.3 Nhiet do CPU, Dia, Mang

```
Nhiet do CPU:
  Doc: /sys/class/thermal/thermal_zone0/temp → chia 1000
  V = (100 - nhiet_do_C) / 100 × 7   // nong = tieu cuc
  A = max(0, (nhiet_do_C - 50) / 50 × 7)

Mang:
  Doc: /proc/net/dev
  S = loai_giao_dien (lo=0, eth=5, wlan=10)
  A = quantize(thong_luong / bang_thong_toi_da, 0, 7)
  T = delta(thong_luong) → 0-3

Pipeline no thu cam hoan chinh:
  system_mol = compose_chain([cpu_pw, mem_pw, temp_pw, net_pw])
  → Mot u16 dai dien trang thai he thong
  Cap nhat: moi 5 giay.
  Neu system_mol.A > 5 trong 3 lan doc lien tiep → canh bao.
```

---

## 38. Thuat Toan Tim Kiem Toi Uu

### 38.1 Tim Kiem Fibonacci

```
Bai bao: Kiefer (1953), "Sequential Minimax Search for a Maximum"
Do phuc tap: O(log_φ n) ≈ O(1.44 × log₂ n)

Tai sao tot hon binary search cho Nox:
  - Dung PHEP CONG khong PHEP CHIA (re hon tren phan cung don gian)
  - Vi tri tham do tai diem φ⁻¹ → khop phan cap tu nhien P_weight
  - Mau truy cap tuan tu → tot hon cho KnowTree luu tren dia
```

### 38.2 Tim Kiem Noi Suy

```
Do phuc tap: O(log log n) trung binh, O(n) xau nhat

  pos = lo + ((key - A[lo]) × (hi - lo)) / (A[hi] - A[lo])

  Gia tri P_weight la u16 (0..65535). Phan phoi KHONG deu.
  → Tim kiem noi suy tot TRONG bucket (cung gia tri S,R).
  → Kem cho tim kiem cheo bucket (dung silk walk thay the).
```

### 38.3 Tim Kiem Toi Uu cho Khong Gian 5D So Nguyen (32K gia tri)

```
Van de: tim kiem trong khong gian 5D voi P_weight = u16 (65536 kha di, ~32K hoat dong).

★ TOI UU CHO NOX: Chi muc bucket tren (S, R) + quet tuyen tinh trong bucket.

Ly do:
  S co 16 gia tri (4 bit), R co 16 gia tri (4 bit)
  → 256 bucket toi da
  32K gia tri / 256 bucket = 125 gia tri moi bucket trung binh

  Tim theo (S, R):
    bucket = S × 16 + R    // O(1)
    Quet tuyen tinh 125 muc so sanh V, A, T  // O(125)
    Tong: O(125) ≈ O(1) hieu qua

  Cho nearest-neighbor:
    Tim bucket (S, R) + 8 bucket lan can (S±1, R±1)
    9 bucket × 125 muc = 1125 phep so sanh
    Voi cat tia Fibonacci: kiem tra bucket trung tam truoc,
    mo rong theo xoan Fibonacci: 1, 1, 2, 3, 5 bucket cach xa.

  NGUOI CHIEN THANG: Bucket(S,R) + quet tuyen tinh sap xep V + mo rong Fibonacci.
    Trung binh: O(8). Xau nhat: O(1125). Bo nho: 256 header = 512 bytes.
```

---

## 39. Xu Ly Chuoi/Van Ban

### 39.1 Rabin-Karp Rolling Hash

```
Bai bao: Rabin & Karp (1987)
Do phuc tap: O(n + m) trung binh

Ham hash (polynomial rolling hash):
  h(s[0..m-1]) = (s[0] × d^(m-1) + s[1] × d^(m-2) + ... + s[m-1]) mod q

Cap nhat cuon (truot cua so 1 vi tri):
  h(s[i+1..i+m]) = (d × (h(s[i..i+m-1]) - s[i] × d^(m-1)) + s[i+m]) mod q

  Rolling hash cua van ban ≈ compose P_weight chay.
  Ca hai la thao tac cua so truot cap nhat tang dan.
```

### 39.2 KMP (Knuth-Morris-Pratt)

```
Bai bao: Knuth, Morris, Pratt (1977)
Do phuc tap: O(n + m) dam bao

Ham that bai (bang tien to):
  π[i] = do dai cua tien to rieng dai nhat cua mau[0..i] cung la hau to.

  Khi sai khop: nhay toi π[k-1] thay vi quay lai tu dau.
  → Khong bao gio kiem tra lai ky tu da khop.
```

### 39.3 Aho-Corasick

```
Bai bao: Aho & Corasick (1975)
Do phuc tap: O(n + m + z), z = so ket qua khop

Cau truc du lieu: trie + lien ket that bai + lien ket dau ra.

Ung dung cho Nox:
  Khop da mau cho tu khoa bao mat, tien to lenh.
  SecurityGate: quet dau vao voi tat ca mau nguy hiem trong mot luot.
  Xay trie mot lan → O(n) moi dau vao bat ke so luong mau.
```

### 39.4 Suffix Array + BWT

```
Suffix Array: Manber & Myers (1993)
  SA[i] = vi tri bat dau cua hau to nho thu i.
  Xay dung: O(n log n) hoac O(n) voi SA-IS.
  Tim kiem: O(m log n).

BWT (Burrows-Wheeler Transform): Burrows & Wheeler (1994)
  BWT[i] = van_ban[(SA[i] - 1) mod n]
  Tinh chat chinh: ky tu nhom theo ngu canh → nen tot hon.

FM-index (Ferragina & Manzini, 2000):
  BWT + rank/select → chi muc toan van ban nen
  Tim kiem mau P trong O(m) thoi gian bang tim kiem nguoc.

  Cho Nox: BWT index cua ma nguon → tim kiem ma tuc thoi.
```

---

## 40. Kien Truc LLM (Hieu Doi Thu)

### 40.1 Attention cua Transformer

```
Bai bao: Vaswani et al. (2017), "Attention Is All You Need"
Do phuc tap: O(n² × d)

Attention Tich Vo Huong Co Ty Le:
  Attention(Q, K, V) = softmax(Q × Kᵀ / √d_k) × V

  Q = ma tran truy van  — "toi dang tim gi?"
  K = ma tran khoa     — "toi chua gi?"
  V = ma tran gia tri  — "toi cung cap thong tin gi?"

So sanh SRVAT:
  Diem attention ≈ trong so silk.
  Q×Kᵀ ≈ distance_5d(node_a, node_b)
  softmax ≈ chuan hoa trong so silk tong bang 1
  Ma tran V ≈ noi dung P_weight tai moi node

  KHAC BIET CHINH:
  Attention: O(n²) — moi token chu y moi token khac.
  Silk walk: O(bac × do_sau) — chi node ket noi, thuong O(20 × 5) = O(100).
  Cach tiep can Nox la ATTENTION THUA — chi chu y cac node ket noi silk.
```

### 40.2 Tokenization (BPE, SentencePiece, WordPiece)

```
BPE (Sennrich et al., 2016):
  Bat dau voi tu vung cap ky tu, gop cap thuong gap nhat, lap lai.

SentencePiece (Kudo & Richardson, 2018):
  Mo hinh unigram, doc lap ngon ngu, coi dau vao nhu byte/ky tu tho.

So sanh SRVAT:
  Token BPE ≈ chain trong KnowTree.
  Tu thuong = token don = P_weight don.
  Tu hiem = nhieu sub-token = chuoi P_weight compose.
  KHAC BIET CHINH: BPE co tu vung co dinh. P_weight co KHONG GIAN co dinh (u16).
  Bat ky dau vao nao deu anh xa sang P_weight. Khong co van de OOV.
```

### 40.3 Word2Vec va GloVe

```
Word2Vec (Mikolov et al., 2013):
  Nhung tu: 300 chieu dau phay dong → 1200 bytes moi tu.
  P_weight: 5 chieu so nguyen → 2 bytes moi tu.

  Ket qua noi tieng: vector("vua") - vector("dan_ong") + vector("phu_nu") ≈ vector("nu_hoang")

  Phep tuong tu trong SRVAT:
    unpack(vua) = [S1, R1, V1, A1, T1]
    unpack(dan_ong) = [S2, R2, V2, A2, T2]
    delta = [S1-S2, R1-R2, V1-V2, A1-A2, T1-T2]
    ket_qua = [S3+delta_S, R3+delta_R, V3+delta_V, A3+delta_A, T3+delta_T]
    (voi [S3...] = unpack(phu_nu))

GloVe (Pennington et al., 2014):
  J = Σ f(X_ij) × (w_i^T × w̃_j + b_i + b̃_j - log X_ij)²
  Cho Nox: TRONG SO SILK phuc vu cung vai tro nhu thong ke dong xuat hien.
  silk_weight(A, B) ↔ log(X_AB) trong GloVe.
```

### 40.4 Nhung Gi SRVAT Lam Khac

```
Cach tiep can LLM:
  Token → nhung chieu cao → self-attention O(n²) → mang feedforward → giai ma
  Tham so: hang ti. Huan luyen: hang tuan tren GPU cluster. Model: gigabyte.

Cach tiep can SRVAT:
  Ma hoa → P_weight u16 (TINH tu thuoc tinh ky tu)
  Compose chuoi → P_weight cau (trong Zipf, O(n))
  Silk walk → node lien quan (O(bac × do_sau), thua)
  Hebbian → tang cuong/lam yeu (O(bac))
  Giai ma → van ban qua KnowTree (O(log n))

  Tham so: ~200KB. Huan luyen: lien tuc, truc tuyen. Model: 949KB tong.

Uu diem SRVAT:
  - Khong can pha huan luyen (hoat dong tu dau vao dau tien)
  - Khong can GPU (chi so hoc so nguyen)
  - Minh bach (kiem tra duoc moi P_weight)
  - Tu sua doi (compiler co the thay doi logic encode/compose cua chinh no)
  - 949KB vs 7-70GB (nho hon 10,000-100,000×)

Nhuoc diem SRVAT:
  - 5 chieu vs 300+ → it sac thai moi token
  - Khong co mo hinh the gioi ngam (LLM luu tri thuc trong trong so)
  - Can hoc ro rang (canh silk xay tung cai)
```

---

## 41. Nen/Ma Hoa

### 41.1 Huffman Coding

```
Bai bao: Huffman (1952)
Do phuc tap: O(n log n) xay, O(n) ma hoa/giai ma

Thuat toan:
  1. Dem tan suat moi ky hieu
  2. Tao node la cho moi ky hieu voi tan suat
  3. Chen vao hang uu tien (min-heap)
  4. Trong khi hang > 1 node: rut 2 min, tao cha, chen lai
  5. Node con lai = goc cay Huffman

  Ky hieu thuong gap → ma ngan, hiem → ma dai.
  Toi uu: H(X) ≤ L < H(X) + 1, voi H = entropy.
```

### 41.2 Arithmetic Coding

```
Bai bao: Rissanen (1976), Witten, Neal, Cleary (1987)
Do phuc tap: O(n)

Khai niem: ma hoa TOAN BO thong diep thanh mot so trong [0, 1).

  lo = 0.0, hi = 1.0
  Cho moi ky hieu s trong thong diep:
    range = hi - lo
    hi = lo + range × xac_suat_tich_luy(s + 1)
    lo = lo + range × xac_suat_tich_luy(s)

  Dau ra: bat ky so nao trong [lo, hi) cuoi cung
  Bit can ≈ -log₂(hi - lo) ≈ H(thong_diep)

  Uu diem so voi Huffman: tiep can entropy CHINH XAC.
```

### 41.3 LZ77/LZ78/LZW

```
LZ77 (Ziv & Lempel, 1977): Thay chuoi lap bang (offset, do_dai, ky_tu_tiep).
LZ78 (1978): Tu dien, xay cum tu da thay.
LZW (Welch, 1984): Cai tien LZ78, khong can ky tu moi ro rang trong dau ra.

  Tu dien LZW ≈ KnowTree.
  Cum tu moi = chain moi. Chi muc tu dien = tham chieu P_weight.
```

### 41.4 Bloom Filter

```
Bai bao: Bloom (1970)
Do phuc tap: O(k) chen/truy van

Cau truc: mang bit m bit, k ham hash.

  Chen(x): dat bit hash_i(x) mod m = 1, cho i trong 0..k
  Truy van(x): neu TAT CA bit la 1 → CO THE CO; neu BAT KY la 0 → CHAC CHAN KHONG CO

  Ty le duong tinh gia: p ≈ (1 - e^(-kn/m))^k
  k toi uu = (m/n) × ln(2)

  Cho n = 10000, p = 1%: m = 96000 bit = 12 KB, k = 7

  Hien thuc voi chi 2 ham hash (Kirsch & Mitzenmacher, 2006):
    hash_i(x) = hash_1(x) + i × hash_2(x)
```

### 41.5 Count-Min Sketch

```
Bai bao: Cormode & Muthukrishnan (2005)
Do phuc tap: O(d) chen/truy van

  Cau truc: mang 2D count[d][w], d ham hash.
  Truy van(x): tra ve min_{i=0..d-1} count[i][hash_i(x) mod w]

  Cho Nox: dem tan suat P_weight khong can luu tat ca P_weight.
  76 KB cho loi 0.1% — chap nhan cho Nox.
```

---

## 42. Mat Ma Hoc

### 42.1 SHA-256

```
Bai bao: NIST FIPS PUB 180-4 (2015)
Do phuc tap: O(n)

Da co trong VM Nox. Tham khao thuat toan:

Tien xu ly:
  1. Dem thong diep la boi 512 bit
  2. Phan tich thanh cac khoi 512-bit

Moi khoi 512-bit:
  1. Tao lich thong diep W[0..63]:
     W[i] = khoi[i] cho i < 16
     W[i] = σ₁(W[i-2]) + W[i-7] + σ₀(W[i-15]) + W[i-16]

  2. 64 vong:
     Σ₁ = ROTR⁶(e) ⊕ ROTR¹¹(e) ⊕ ROTR²⁵(e)
     Ch  = (e ∧ f) ⊕ (¬e ∧ g)
     T1  = h + Σ₁ + Ch + K[i] + W[i]
     Σ₀ = ROTR²(a) ⊕ ROTR¹³(a) ⊕ ROTR²²(a)
     Maj = (a ∧ b) ⊕ (a ∧ c) ⊕ (b ∧ c)
     T2  = Σ₀ + Maj

Dau ra: 256 bit (32 byte).

Tinh chat:
  Khang tien anh: cho h, kho tim m sao cho SHA-256(m) = h
  Khang va cham: kho tim m1 ≠ m2 sao cho SHA-256(m1) = SHA-256(m2)
  Hieu ung tuyet: 1 bit dau vao thay → ~50% bit dau ra thay
```

### 42.2 HMAC va Merkle Tree

```
HMAC-SHA256(khoa, thong_diep):
  HMAC cho tinh toan ven QR — moi ban ghi QR co HMAC → chong gia mao.

Merkle Tree (Merkle, 1979):
  Cau truc:
    Node la: hash cua khoi du lieu
    Node trong: hash cua noi hai con
    Goc: mot hash tom tat tat ca du lieu

  Cho kho QR:
    Moi ban ghi QR = la
    Hash goc luu tai vi tri co dinh
    Tai diem kiem tra: xac minh goc → toan bo lich su xac minh
    Neu goc sai → ban ghi bi hong → hoan tac den diem kiem tra tot cuoi
```

---

## 43. Mang/Giao Thuc

### 43.1 May Trang Thai TCP

```
RFC 793 (1981)

Bat tay ba buoc (ket noi):
  Client → SYN (seq=x)            → Server
  Client ← SYN-ACK (seq=y, ack=x+1) ← Server
  Client → ACK (ack=y+1)          → Server

Kiem soat tac nghen:
  Slow start: cwnd = 1 MSS, gap doi moi RTT den ssthresh
  Tranh tac nghen: cwnd += 1 MSS moi RTT sau ssthresh
  Khi mat: ssthresh = cwnd/2, cwnd = 1 (Tahoe) hoac cwnd/2 (Reno)

Nox da co TCP trong VM. Chinh cho MCP va HTTP.
```

### 43.2 HTTP/1.1

```
RFC 7230-7235 (2014)

Dinh dang yeu cau:
  METHOD SP Request-URI SP HTTP/1.1 CRLF
  Header: value CRLF ... CRLF [body]

Ma trang thai:
  200 OK, 201 Created, 400 Bad Request, 404 Not Found, 500 Internal Error

Chunked encoding: truyen du lieu khong biet truoc do dai.
```

### 43.3 WebSocket, MQTT, MCP

```
WebSocket (RFC 6455): song huong thoi gian thuc.
  Cho Nox web UI: stream tien trinh silk walk, cap nhat P_weight truc tiep.

MQTT (IBM/OASIS): pub/sub nhe cho IoT.
  Hoan hao cho mang cam bien IoT.
  Moi cam bien phat P_weight den topic:
    "nox/interoception/cpu" → P_weight he thong
    "nox/vision/camera0" → P_weight camera
  Nox dang ky tat ca → compose → no_thu_cam_he_thong.
  Giao thuc nho: MQTT client ≈ 2-5 KB ma.

MCP (Model Context Protocol — Anthropic, 2024):
  Truyen tai: JSON-RPC 2.0 qua stdio hoac HTTP+SSE
  Server Nox (da hien thuc, 15 cong cu):
    know_learn, know_query, emotion_encode, self_inspect, self_modify,
    kg_add, kg_query, kg_about, silk_status, nox_status,
    learning_status, safety_check, dn_observe, dream_cycle, olang_eval
  MCP = giao dien cua Nox voi the gioi.
```

---

## 44. Tu Sua Doi/Metaprogramming

### 44.1 Quine (Chuong trinh Tu Tai Tao)

```
Dinh nghia: chuong trinh xuat ma nguon cua chinh no ma khong doc chinh no.

Tinh chat diem bat dong:
  Quine la diem bat dong cua ham "bien dich va chay":
  run(source) = source
  Tinh chat Gen1==Gen2 cua Nox CHINH LA tinh chat quine:
    compile(Gen0_source) → Gen1_binary
    compile_with(Gen1_binary, Gen0_source) → Gen2_binary
    Gen1 == Gen2 ✓ → dat diem bat dong
```

### 44.2 Phan Chieu va Tu Kiem Tra

```
Cac muc:
  1. Tu kiem tra: doc cau truc cua chinh minh (kiem tra kieu, stack)
  2. Tu can thiep: thay doi hanh vi cua chinh minh (dispatch phuong thuc)
  3. Tu sua doi: thay doi ma cua chinh minh (bien dich lai, va bytecode)

Nox tu kiem tra (cong cu self_inspect MCP):
  - Doc hash binary cua chinh minh (kiem tra toan ven)
  - Dem node KnowTree, canh silk
  - Do luong chi so chat luong phan hoi

Nox tu sua doi (cong cu self_modify MCP):
  1. Doc ma nguon Olang hien tai cho ham muc tieu
  2. Sinh ma nguon da sua doi
  3. Bien dich lai (make self-build)
  4. Xac minh test qua (make test)
  5. Xac minh diem bat dong (make fixed-point)
  6. Neu tat ca qua: binary moi hoat dong
  7. Neu bat ky that bai: hoan tac ve binary truoc
```

### 44.3 Compiler Tu Sua Doi

```
Kien truc:
  Lop 0: VM (assembly x86_64, ~1MB) — BAT BIEN tai runtime
  Lop 1: Compiler (Olang, bien dich thanh binary) — tu host
  Lop 2: Nao (Olang, bien dich trong cung binary) — co the sua
  Lop 3: Tri thuc (KnowTree, dia) — lien tuc sua doi

Cac muc tu sua doi:
  Muc A: Sua tri thuc (them/xoa node, canh silk)
    Rui ro: THAP. Luon an toan, co the hoan tac. Tan suat: moi dau vao.

  Muc B: Sua logic nao (tham so pipeline, nguong)
    Rui ro: TRUNG BINH. Phai qua test. Tan suat: hang ngay (chu ky ngu).

  Muc C: Sua compiler (quy tac phan tich, luot toi uu hoa)
    Rui ro: CAO. Phai duy tri diem bat dong. Tan suat: hang tuan hoac it hon.

  Muc D: Sua VM (ma assembly)
    Rui ro: QUAN TRONG. Hien chi thu cong.

Giao thuc an toan cho Muc B/C:
  1. Git commit trang thai hien tai
  2. Doc file nguon muc tieu
  3. Sinh sua doi
  4. Ghi nguon da sua
  5. make self-build
  6. make test — tat ca 194 test phai qua
  7. make fixed-point — Gen1 == Gen2
  8. Neu that bai: thu lai (toi da 3 lan), roi git checkout
  9. Neu qua: commit va kich hoat binary moi
```

### 44.4 Khai niem JIT Compilation

```
JIT = bien dich tai runtime, ngay truoc khi thuc thi.

Cho Nox:
  Hien tai: AOT (Ahead-Of-Time). Olang → binary x86_64.
  Co hoi JIT: cac duong silk walk thuong xuyen thuc thi.
  Bien dich cac duong silk nong thanh goi ham truc tiep (bo duyet do thi).

  Vi du:
  "cai gi la X?" luon di: encode → R-dominant → bucket → compose
  Sau 100 truy van: bien dich duong nay thanh ham native don.
  Bo silk walk hoan toan cho cac mau da biet.

  fire_count CHINH LA bo dem profiling.
  Node co fire_count > nguong → ung vien cho JIT compilation.
```

---

## 45. SDF Engine — Render Khong Can Ray Tracing

### 45.1 Danh Gia Truc Tiep Luoi Pixel

```
cho moi pixel (i,j):
    p = screen_to_world(i, j)
    d = sdf(p)
    neu d <= 0: to_mau(p, gradient(sdf, p))
    neu d < kich_thuoc_pixel: alpha = 1 - d/kich_thuoc_pixel  // khang rang cua
```
O(W×H×C_sdf). Phuong phap don gian nhat. Chay duoc tren CPU.

### 45.2 Chieu Sang tu SDF Gradient (Khong Can Tia)

```
Phap tuyen:   N = ∇f(p) = (∂f/∂x, ∂f/∂y, ∂f/∂z)
Khuech tan:   I = k_d × max(0, N·L)
Phan chieu:   H = normalize(L+V); I = k_s × max(0, N·H)^n
AO (Ambient Occlusion): AO = 1 - Σ w_i × (d_i - f(p + d_i×N))/d_i  (5 danh gia SDF)
Bong:         S = min(k × f(p + t×L)/t)  (4 mau co dinh, khong can marching)
```

### 45.3 Phep Toan Boolean CSG + Mien

```
Union:     min(f1, f2)
Intersect: max(f1, f2)
Subtract:  max(f1, -f2)
Smooth:    smin(a,b,k) = -ln(e^(-ka)+e^(-kb))/k

Phep dich: f(p - offset)
Xoay:      f(R⁻¹ × p)
Co giãn:   f(p/s) × s
Lap lai:   f(mod(p, chu_ky) - chu_ky/2)  // lat vo han, O(1)!
```

### 45.4 Ngan Sach Bo Nho cho Binary 949KB

```
SDF eval + CSG:     ~10KB code
Marching Squares:    ~2KB
Felzenszwalb EDT:    ~3KB
Chieu sang + AO:     ~2KB
Dang hoc + chieu:    ~1KB
Tong: ~20KB. Vua thoai mai.
```

---

## 46. Font/Emoji -> SDF -> SRVAT Pipeline

### 46.1 Glyph → Duong Vien Vector

```
FreeType: FT_Load_Glyph → FT_Outline (duong cong Bezier bac hai/ba)
Bac hai:  B(t) = (1-t)²P₀ + 2(1-t)tP₁ + t²P₂
Bac ba:   B(t) = (1-t)³P₀ + 3(1-t)²tP₁ + 3(1-t)t²P₂ + t³P₃
```

### 46.2 SDF → Dac Trung Hinh Dang → Gia Tri S

```
Ty le dang huong: C = P²/(4π×A)
  Hinh tron=1.0, Ngoi sao=cao. Luong tu hoa: S = clamp(floor(log2(C)×2.2), 0, 15)

Dac trung bo sung:
  duong vien: 'A'=2(ngoai+lo), 'B'=3, 'O'=2
  doi xung: correlation(f(x,y), f(-x,y))
```

### 46.3 Pipeline Hoan Chinh

```
Unicode cp → FreeType → duong vien Bezier → SDF (msdfgen/EDT)
  → dac trung (do compactness, duong vien, doi xung)
  → luong tu hoa S → pack(S,R,V,A,T) → u16 P_weight
```

---

# PHAN VIII: NGHIEN CUU NEN TANG

> Moi thuat toan trong Nox deu co NGUON GOC khoa hoc. Phan nay liet ke
> cac bai bao va nghien cuu tao nen nen tang cua he thong.

---

## 47. Russell 1980: Mo Hinh Vong Tron Cam Xuc

```
Bai bao: Russell, J.A. (1980). "A circumplex model of affect."
         Journal of Personality and Social Psychology, 39(6), 1161-1178.

Phat hien chinh: TAT CA trang thai cam xuc co the anh xa sang khong gian 2D hinh tron.
  Truc X: Valence (vui suong <-> kho chiu)
  Truc Y: Arousal (kich hoat <-> thu gian)

Phuong phap:
  - 28 tu cam xuc duoc danh gia boi doi tuong
  - Phan tich da chieu (MDS) → cau truc hinh tron 2D
  - Cam xuc ke nhau tren vong tron = tuong tu
  - Cam xuc doi dien = 180 do cach nhau

Tac dong len Nox:
  Cac chieu V va A truc tiep tu mo hinh nay.
  Moi P_weight chua V (valence) va A (arousal).
  Theo doi hoi thoai dung quy dao V(t) va A(t).
```

---

## 48. NRC-VAD: Best-Worst Scaling (Mohammad, 2018)

```
Bai bao: Mohammad, S.M. (2018). "Obtaining Reliable Human Ratings of
         Valence, Arousal, and Dominance for 20,000 English Words."
         ACL 2018, 174-184.

Dong gop chinh:
  - 20,000 tu tieng Anh voi diem V, A, D
  - Phuong phap Best-Worst Scaling (tin cay hon Likert)
  - Do tin cay chia doi: r = 0.95
  - Mo rong den 55,000+ tu trong cac phien ban sau

Dung trong Nox:
  NRC-VAD = du lieu bootstrap cho cac chieu V va A.
  Cold start: tra cuu NRC-VAD.
  Am: ket noi silk cung cap V/A tu ngu canh.
  Nong: NRC-VAD khong can thiet, silk du.

URL: https://saifmohammad.com/WebPages/nrc-vad.html
```

---

## 49. ANEW: Bradley & Lang (1999)

```
Bai bao: Bradley, M.M. & Lang, P.J. (1999). "Affective Norms for English
         Words (ANEW): Instruction Manual and Affective Ratings."

Dong gop: 1,034 tu tieng Anh voi diem Valence, Arousal, Dominance
  - Self-Assessment Manikin (SAM) — thang do thi giac
  - Nen tang cho TAT CA nghien cuu tu-cam xuc sau nay

Lien he:
  ANEW = goc (1,034 tu, phuong phap SAM)
  NRC-VAD = thay the hien dai (20,000+ tu, phuong phap BWS)
  Tuong quan giua ANEW va NRC-VAD: r ~ 0.95 (rất nhat quan)
```

---

## 50. Friston 2010: Nguyen Ly Nang Luong Tu Do

```
Bai bao: Friston, K. (2010). "The free-energy principle: a unified brain
         theory?" Nature Reviews Neuroscience, 11(2), 127-138.

Khang dinh chinh:
  1. TAT CA he thong thich nghi toi thieu hoa nang luong tu do bien phan
  2. Nang luong tu do F >= bat ngo (log am cua bang chung)
  3. Toi thieu F = toi thieu loi du doan
  4. Hai huong: cap nhat mo hinh (nhan thuc) hoac thay doi dau vao (hanh dong)

Khung toan hoc:
  F = E_Q[ln Q(theta) - ln P(data, theta)]
    = DKL[Q(theta) || P(theta)] - E_Q[ln P(data | theta)]
    = Do phuc tap - Do chinh xac

  Mo hinh tot: phuc tap thap + chinh xac cao = F thap

Dung trong Nox: Muc 17 (Can bang) — F(t) dieu khien toc do hoc lambda(t).
```

---

## 51. Hebb 1949: To Chuc Hanh Vi

```
Bai bao: Hebb, D.O. (1949). "The Organization of Behavior: A
         Neuropsychological Theory." New York: Wiley.

Cuon sach than kinh hoc co anh huong nhat the ky 20.

Don gian: "Neuron cung kich hoat, cung ket noi."

Tac dong:
  - Nen tang cua TAT CA hoc lien ket / mang neural
  - Dan den: Perceptron, Backpropagation, Deep Learning
  - Dan den: Quy tac Oja, ly thuyet BCM, STDP
  - Dan den: Mang Hopfield, may Boltzmann

Dung trong Nox: Muc 14 — hoc silk Hebbian.
```

---

## 52. Collins & Loftus 1975: Lan Truyen Kich Hoat

```
Bai bao: Collins, A.M. & Loftus, E.F. (1975). "A spreading-activation
         theory of semantic processing." Psychological Review, 82(6), 407-428.

Mo hinh chinh:
  Bo nho ngu nghia = mang cac khai niem ket noi boi lien ket.
  Kich hoat mot khai niem → kich hoat LAN TRUYEN den cac khai niem ket noi.
  Do manh lan truyen phu thuoc vao do manh lien ket.
  Kich hoat giam theo khoang cach.

Bang chung thuc nghiem:
  - Moi (Priming): nghe "bac si" truoc → nhan ra "y ta" nhanh hon
  - Khoang cach ngu nghia: "chim" → "chim hoang yen" (nhanh) vs "chim" → "chim canh cut" (cham)

Dung trong Nox: Silk walk = lan truyen kich hoat (Muc 27.3).
```

---

## 53. Shannon 1948: Ly Thuyet Thong Tin

```
Bai bao: Shannon, C.E. (1948). "A Mathematical Theory of Communication."
         Bell System Technical Journal, 27(3), 379-423.

Cac khai niem nen tang:

Entropy:
  H(X) = -Sum P(x) * log2 P(x)
  = noi dung thong tin trung binh = do bat ngo trung binh
  = so bit toi thieu can de ma hoa X

Thong tin Tuong ho:
  I(X;Y) = H(X) - H(X|Y)
  = biet Y cho biet bao nhieu ve X

Dung luong Kenh:
  C = max_{P(X)} I(X;Y)

Dung trong Nox:
  - Entropy phan phoi P_weight → da dang tri thuc
  - Thong tin tuong ho giua node ket noi silk → chat luong silk
  - Thu nhap thong tin → diem to mo (Muc 32.1)
  - Nen chain (Muc 9.2) → gioi han ma hoa Shannon
```

---

## 54. Fibonacci / phi trong Tu Nhien + Toi Uu

```
Ty Le Vang:
  phi = (1 + sqrt(5)) / 2 ~ 1.6180339887...
  phi_inv = phi - 1 = (sqrt(5) - 1) / 2 ~ 0.6180339887...
  phi² = phi + 1
  phi_inv = 1/phi

Day Fibonacci:
  F(0) = 0, F(1) = 1
  F(n) = F(n-1) + F(n-2)
  lim F(n)/F(n+1) = phi_inv

Xuat hien trong Nox:
  1. Hang so decay: w(t) = w0 * phi_inv^(t/tau) (Muc 15.1)
  2. Nguong kich hoat: Day Fibonacci cho thang cap QR (Muc 12.3)
  3. Nguong can bang: F(t) so voi phi_inv (Muc 17.2)
  4. Chi so dep SDF: ty le phi trong phan tich hinh hoc

Tai sao phi xuat hien khap noi:
  - So vo ty nhat (kho xap xi nhat bang phan so)
  - Xep toi uu (hat huong duong, goc 137.5 do)
  - Tim kiem Fibonacci: toi uu cho toi thieu hoa ham don dinh
  - Dinh ly Zeckendorf: moi so nguyen duong = tong duy nhat cua Fibonacci khong lien tiep
  - Tu tuong tu: phi = 1 + 1/phi (tinh chat fractal)
```

---

## 55. SDF Rendering: Valve 2007, msdfgen

```
Bai bao: Green, C. (2007). "Improved Alpha-Tested Magnification for Vector
         Textures and Special Effects." Valve Corporation.

Y tuong chinh:
  Luu glyph nhu truong khoang cach co dau trong texture.
  GPU render bang nguong: neu sdf(pixel) < 0 → ben trong → ve.
  Canh muot o BAT KY muc zoom nao (khong bi pixel hoa).

Multi-channel SDF (msdfgen):
  Chlumsky, V. (2015). Czech Technical University.
  3 kenh (RGB) moi cai luu khoang cach den doan canh khac nhau.
  Median cua 3 → giu goc nhon ma SDF don kenh lam tron.

Felzenszwalb & Huttenlocher (2012):
  Bien doi khoang cach Euclidean CHINH XAC trong O(n) moi hang.
  Dung giao diem bao parabol. Hien dai nhat cho tinh toan SDF.

Dung trong Nox: Chieu S = do phuc tap SDF cua glyph Unicode (Muc 1).
```

---

## 56. HNSW: Malkov & Yashunin 2018

```
Bai bao: Malkov, Y.A. & Yashunin, D.A. (2018). "Efficient and robust
         approximate nearest neighbor using Hierarchical Navigable Small
         World graphs." IEEE TPAMI, 42(4), 824-836.

Dong gop chinh:
  Do thi da lop cho tim kiem lang gieng gan nhat xap xi.
  Thoi gian truy van O(log n), gan nhu doc lap voi so chieu.
  Hien dai nhat cho ANN trong khong gian chieu cao.

Dung trong Nox: Muc 10.5, 26.4 — ANN xap xi cho KnowTree >10K node.
```

---

## 57. Unicode Standard + Tai Nguyen Ngon Ngu

```
Unicode Standard (moi nhat: v16.0, 2024):
  Chuong 2: Cau truc Tong quan — cac dang ma hoa, phan bo
  Chuong 4: Thuoc tinh Ky tu — General_Category, Script, v.v.
  UnicodeData.txt: co so du lieu thuoc tinh doc bang may

  Thuoc tinh chinh cho Nox: General_Category → chieu R

Emoji:
  Novak et al. (2015): "Sentiment of Emojis" — diem cam xuc 751 emoji → chieu V
  Rodrigues et al. (2018): "Lisbon Emoji and Emoticon Database" — V, A, D cho emoji

WordNet:
  Miller (1995): Quan he tu vung → loai silk (Muc 11.2) va chieu R (Muc 2.3)

Luat Zipf:
  Zipf (1949): "Human Behavior and the Principle of Least Effort"
  → Trong so compose (Muc 7.1): w_i = 1000/(i+1)
```

---

# PHAN IX: HIEN THUC (Olang)

---

## 58. VM x86_64: Kien Truc, Thanh Ghi, Opcode

### 58.1 Tong Quan

```
VM cua Nox = binary x86_64 tuy chinh bien dich boi compiler Olang.

Thong so:
  Kien truc: x86_64 (AMD64)
  Dinh dang binary: ELF64 (Linux)
  Tong ASM: ~12,934 dong (runtime.asm + ma sinh)
  Kich thuoc binary: ~949 KB (hien tai, v0.9.x)

Mo hinh bo nho:
  Bo cap phat bump (hien tai):
    heap_ptr bat dau tai heap_base
    alloc(n): ptr = heap_ptr; heap_ptr += n; tra ve ptr
    free: khong lam gi (khong giai phong)

    Uu diem: cuc nhanh, khong phan manh
    Nhuoc diem: khong tai su dung → heap tang don dieu

  Bo cap phat arena (ke hoach):
    Nhieu arena cho thoi gian song khac nhau
    Reset arena = giai phong tat ca cung luc
    Hieu qua bo nho tot hon cho qua trinh chay dai

Su dung thanh ghi:
  rax: gia tri tra ve, tam
  rbx: bao toan, con tro co so du lieu
  rcx: bo dem, doi so thu 4
  rdi: doi so thu 1
  rsi: doi so thu 2
  rdx: doi so thu 3
  r8-r11: tam, doi so 5-8
  r12-r15: bao toan, bien cuc bo
  rsp: con tro ngan xep
  rbp: con tro co so (frame pointer)
```

### 58.2 Thao Tac Built-in (~100 builtins)

```
Chuoi/Mang: str_len, str_concat, str_slice, str_find, str_split,
            arr_new, arr_push, arr_get, arr_set, arr_len, arr_slice

Toan: add, sub, mul, div, mod, sqrt, pow, abs,
      sin, cos, tan, log, exp, floor, ceil, round

I/O: print, println, read_line, read_file, write_file

Mang: tcp_connect, tcp_listen, tcp_send, tcp_recv,
      udp_bind, udp_send, udp_recv,
      dns_lookup, http_get, http_post

Mat ma: sha256, hmac, aes_encrypt, aes_decrypt

He thong: syscall, exec, env_get, time_now, sleep,
          camera_capture, uinput_key, uinput_mouse

Nao (dac trung Nox):
  mol_encode, mol_compose, mol_distance,
  silk_create, silk_fire, silk_walk,
  know_add, know_search, know_learn,
  stm_push, stm_get, wm_set, wm_get,
  qr_add, qr_check,
  dream_cycle, self_inspect, self_modify
```

---

## 59. Compiler: Lexer -> Parser -> Semantic -> Codegen

### 59.1 Pipeline Bien Dich

```
Nguon (.ol) -> Token -> AST -> AST co kieu -> ASM x86_64 -> Binary ELF

Giai doan 1: LEXER
  Dau vao: van ban nguon UTF-8
  Dau ra: luong token
  Loai token: Keywords, Literals, Operators, Delimiters, Identifiers

Giai doan 2: PARSER (de quy giam)
  Dau vao: luong token
  Dau ra: AST (Cay Cu phap Truu tuong)
  Van pham: LL(1) voi leo thu tu uu tien toan tu

Giai doan 3: PHAN TICH NGU NGHIA
  Kiem tra kieu: kieu cau truc
  Phan giai pham vi: pham vi tu vung

Giai doan 4: SINH MA
  Dau vao: AST co kieu
  Dau ra: assembly x86_64 (cu phap NASM)
  Chien luoc: truc tiep AST -> ASM (khong co IR)
  Cap phat thanh ghi: quet tuyen tinh

Giai doan 5: ASSEMBLY + LIEN KET
  NASM -> .o -> ld -> binary ELF
  Khong phu thuoc ngoai (khong libc, khong runtime library)
```

---

## 60. Tu Host: Kiem Chung Diem Bat Dong

### 60.1 Qua Trinh Bootstrap

```
Bootstrap (mot lan, tu compiler tham chieu Rust):
  1. Compiler Rust bien dich nguon Olang -> Gen0 (binary bien dich boi Rust)
  2. Gen0 bien dich nguon Olang -> Gen1 (binary tu bien dich dau tien)
  3. Gen1 bien dich nguon Olang -> Gen2 (binary tu bien dich thu hai)
  4. Xac minh: Gen1 == Gen2 (giong het tung byte)

  Neu Gen1 == Gen2: dat diem bat dong. Compiler tu nhat quan.
  Neu Gen1 != Gen2: loi trong compiler (binary khac tu cung nguon).

Sau bootstrap:
  Chi can Gen1 va Gen2. Compiler Rust khong con can.
  make self-build: Gen1 bien dich nguon -> Gen1 moi
  make test: chay bo test (193/194 tests)
  make fixed-point: Gen1 bien dich -> Gen2, xac minh Gen1 == Gen2
```

### 60.2 Tai Sao Diem Bat Dong Quan Trong

```
Diem bat dong = CHUNG MINH compiler hieu chinh minh.

Neu Gen1 == Gen2:
  - Compiler bien dich dung ma nguon cua chinh no
  - Khong co loi an chi bieu lo khi tu bien dich
  - Dau ra xac dinh (cung dau vao → cung dau ra moi luc)
  - Dang tin cay: co the tin binary tao ra binary dung

Neu Gen1 != Gen2:
  - Dau ra khong xac dinh (timestamp? random? dia chi bo nho?)
  - Bien dich sai (compiler hieu sai cu phap cua chinh no)
  - PHAI dieu tra va sua TRUOC bat ky cong viec nao khac

Thompson "Trusting Trust" (1984):
  Ken Thompson: "Ban khong the tin ma ma ban khong hoan toan tu tao."
  Xac minh diem bat dong KHONG phat hien tan cong Thompson.
  Nhung NO PHAT HIEN bien dich sai khong co chu dich.
```

---

## 61. Trang Thai Hien Tai + Lo Trinh

### 61.1 Nhung Gi DA Lam (tinh den 2026-03-31)

```
Nen tang VM:
  [XONG] Binary ELF x86_64, khong phu thuoc ngoai
  [XONG] ~12,934 dong assembly (runtime.asm)
  [XONG] ~100 thao tac built-in
  [XONG] TCP, UDP, DNS, HTTP mang
  [XONG] SHA-256, AES mat ma
  [XONG] Camera, uinput (dieu khien ban phim/chuot)

Compiler:
  [XONG] Tu host (Olang bien dich Olang)
  [XONG] Binary 949 KB
  [XONG] 193/194 test qua
  [XONG] Gen1 == Gen2 (diem bat dong xac minh)

Nao (Pipeline):
  [XONG] Pipeline toan thuan (khong hardcode facts)
  [XONG] Ma hoa P_weight (dua tren pham vi, chua day du 42 cong thuc)
  [XONG] Compose (tich phan) — trong Zipf, khong giao hoan
  [XONG] Distance_5D — Euclidean chuan hoa
  [XONG] mol_dominant_dim — phat hien loai truy van
  [XONG] V'(t) dieu che silk — toc do hoc tu dao ham cam xuc
  [XONG] NRC-VAD bootstrap — 20,000 tu voi gia tri V,A
  [XONG] 30 lenh REPL
  [XONG] 15 cong cu MCP
  [XONG] SecurityGate (co ban)
  [XONG] STM voi day ra theo diem (32 dung luong)

Tri thuc:
  [XONG] DNA bootstrap: 161,000 P_weight da tai
  [XONG] ~271 node KnowTree
  [XONG] ~6 loai canh silk (thap — do va cham P_weight)
```

### 61.2 Nhung Gi CHUA Lam

```
P_weight (42 Cong thuc):
  [CAN LAM] Tinh toan SDF that tu hinh dang glyph (chieu S)
  [CAN LAM] Phan tich ten/thuoc tinh Unicode cho R chinh xac
  [CAN LAM] Day du 42 bo phan loai con

Bo nho/Bo cap phat:
  [CAN LAM] Bo cap phat arena (bump = khong giai phong, heap tang mai)
  [CAN LAM] Heap crash khi >200 lan hoc moi luot (BLOCKER #3)

Silk:
  [CAN LAM] 9,200 loai silk (chi ~6 hoat dong)
  [CAN LAM] VP-tree / HNSW cho tim kiem
  [CAN LAM] Hoc STDP dua tren thoi diem
  [CAN LAM] Hebbian day du voi chuan hoa Oja
  [CAN LAM] Quy tac hiep phuong sai

Pipeline:
  [CAN LAM] Pipeline 14 buoc day du (co ~8 buoc)
  [CAN LAM] 7 cong thuc ban nang (chi co khung)
  [CAN LAM] Chu ky ngu (co cau truc co ban, khong phan cum pho)
  [CAN LAM] Sua DNA voi lap gioi han
  [CAN LAM] Kho QR voi thang cap Fibonacci

Tri tue:
  [CAN LAM] May suy luan logic (A->B + B->C = A->C)
  [CAN LAM] Phat hien tuong tu (I5)
  [CAN LAM] Mo hinh tu than voi bat dinh
  [CAN LAM] He thong muc tieu
  [CAN LAM] Chu ky tu tien hoa 6 giai doan

Sinh:
  [CAN LAM] Tai to hop chain cho sinh van ban
  [CAN LAM] Giai ma (dao ham rieng) — dao nguoc P_weight thanh van ban
```

### 61.3 Bon Blocker (Thu Tu Uu Tien)

```
BLOCKER #1: Va Cham Mol
  Van de: tat ca van ban → cung P_weight (ma hoa dua tren pham vi qua tho)
  Tac dong: khong phan biet duoc "happy" voi "table" voi "algorithm"
  Sua: hien thuc SDF that (S), phan tich category that (R), bo phan loai that
  Trang thai: da hieu, chua sua

BLOCKER #2: Silk Thap (chi 6 canh)
  Van de: it P_weight rieng biet → it ket noi silk rieng biet
  Tac dong: silk walk tra ve cung node bat ke truy van
  Sua: sua BLOCKER #1 truoc → P_weight trai ra → silk da dang
  Trang thai: bi chan boi #1

BLOCKER #3: VM Heap Crash
  Van de: bo cap phat bump het bo nho khi >200 lan hoc moi luot
  Tac dong: khong the hoc hang loat, gioi han nap tri thuc
  Sua: bo cap phat arena voi reset giua cac luot
  Trang thai: thiet ke san sang, hien thuc dang cho

BLOCKER #4: Tim Kiem Cung Ket Qua
  Van de: moi truy van tra ve cung node gan nhat (do va cham)
  Tac dong: moi cau hoi duoc cung cau tra loi
  Sua: sua BLOCKER #1 → P_weight rieng biet → ket qua tim kiem rieng biet
  Trang thai: bi chan boi #1
```

### 61.4 Lo Trinh: 6 Giai Doan

```
Giai doan 1: SUA BLOCKER (tuc thoi)
  - Tinh toan P_weight that (42 cong thuc)
  - Bo cap phat arena
  - VP-tree cho tim kiem
  Muc tieu: P_weight rieng biet, khong heap crash, tim kiem co y nghia

Giai doan 2: HOAN THIEN PIPELINE (ngan han)
  - Pipeline 14 buoc day du
  - 7 cong thuc ban nang (tinh toan that)
  - SecurityGate 3 tang
  - ConversationCurve V'(t), V''(t)
  Muc tieu: dau vao → dau ra co y nghia qua toan thuan

Giai doan 3: HOC (trung han)
  - Hoc Hebbian + chuan hoa Oja
  - Silk STDP dua tren thoi diem
  - Nguong truot BCM
  - Quy tac hiep phuong sai cho tinh chon loc
  - Decay voi tau dieu chinh boi fire_count
  - Chu ky ngu voi phan cum
  Muc tieu: Nox hoc tu hoi thoai, giu tri thuc

Giai doan 4: TRI TUE (trung han)
  - Kho QR voi thang cap Fibonacci
  - Sua DNA (gioi han 3 lan lap)
  - Phat hien tuong tu (I5)
  - May suy luan logic
  - Mo hinh tu than + bat dinh
  Muc tieu: Nox suy luan, phat hien mau thuan, biet nhung gi no biet

Giai doan 5: TAC TU (dai han)
  - Chu ky PTAV
  - He thong muc tieu (dan dat boi to mo)
  - Suy luan chu dong (Friston)
  - Chu ky tu tien hoa 6 giai doan
  - Q-learning cho silk walk toi uu
  Muc tieu: Nox tu dat muc tieu, tu cai thien

Giai doan 6: TU CHU (dai han)
  - Tu sua doi day du trong ranh gioi an toan
  - Dau vao da phuong thuc (van ban + am thanh + hinh anh)
  - Cac the hien Nox phan tan (P2P)
  - Compiler tu viet lai (sua doi ASM cua chinh no)
  Muc tieu: Nox doc lap, tu duy tri, tu tien hoa
```

---

# PHU LUC A: BANG TOM TAT DO PHUC TAP

```
Thuat toan                    Thoi gian       Khong gian   Lien quan SRVAT
──────────────────────────────────────────────────────────────────────────
Sobel canh                    O(WH)           O(WH)       Chieu S
Canny canh                    O(WH)           O(WH)       Ranh gioi SDF
SIFT                          O(WH×S)         O(keypoints) Chieu S
ORB                           O(WH)           O(keypoints) S,V,A (nhanh nhat)
YOLO luoi                     O(S²×B)         O(S²)       Phat hien doi tuong
Watershed                     O(WH log WH)    O(WH)       Phan doan → P_weight
Graph cut                     O(VE)           O(V+E)      To hop SDF
FFT (Cooley-Tukey)            O(n log n)      O(n)        Pho am thanh
MFCC                          O(n log n)      O(khung)    Giong noi → P_weight
YIN pitch                     O(W × τ_max)    O(W)        Chieu T
Tim kiem Fibonacci            O(log_φ n)      O(1)        Tim kiem KnowTree
Tim kiem noi suy              O(log log n)    O(1)        Tim kiem bucket
Chi muc bucket (S,R)          O(kich_thuoc)   O(256)      Tim kiem chinh
Rabin-Karp                    O(n + m)        O(1)        Khop mau
KMP                           O(n + m)        O(m)        Khop mau
Aho-Corasick                  O(n + m + z)    O(Σm)       SecurityGate
Suffix array                  O(n log n)      O(n)        Tim kiem compiler
BWT/FM-index                  O(n)            O(n)        Chi muc nen
Huffman                       O(n log n)      O(bang_chu) Nen chain
Arithmetic coding             O(n)            O(1)        Nen toi uu
LZW                           O(n)            O(tu_dien)  Nen log
Delta encoding                O(n)            O(1)        Chuoi thoi gian
Bloom filter                  O(k)            O(m bit)    SecurityGate
Count-min sketch              O(d)            O(d×w)      Uoc tinh tan suat
SHA-256                       O(n)            O(1)        Toan ven QR
HMAC-SHA256                   O(n)            O(1)        Xac thuc
Merkle tree                   O(n) xay        O(n)        Xac minh chi them
Attention (transformer)       O(n²d)          O(n²)       Tham khao so sanh
Silk walk                     O(bac × do_sau) O(do_sau)   Tim kiem NOX (attention thua)
```

---

# PHU LUC B: DANH SACH BAI BAO QUAN TRONG

```
Nam   Tac gia                     Tieu de                                         Linh vuc
──────────────────────────────────────────────────────────────────────────────────────────
1949  Hebb                        The Organization of Behavior                      Than kinh
1952  Huffman                     Minimum-Redundancy Codes                          Nen
1953  Kiefer                      Sequential Minimax Search                         Tim kiem
1962  Hu                          Visual Pattern Recognition by Moments             Thi giac
1965  Cooley & Tukey              Machine Calculation of Complex Fourier Series     Tin hieu
1968  Sobel & Feldman             3×3 Isotropic Gradient Operator                   Thi giac
1970  Bloom                       Space/Time Trade-offs in Hash Coding              CTDL
1975  Aho & Corasick              Efficient String Matching                         Chuoi
1975  Collins & Loftus            Spreading Activation                              Tam ly
1977  Knuth, Morris, Pratt        Fast Pattern Matching in Strings                  Chuoi
1977  Ziv & Lempel                Universal Algorithm for Sequential Compression    Nen
1979  Merkle                      Certified Digital Signature                       Mat ma
1980  Davis & Mermelstein         MFCC for Word Recognition                         Am thanh
1980  Russell                     Circumplex Model of Affect                        Tam ly
1982  Bienenstock et al.          BCM Theory                                        Than kinh
1982  Kohonen                     Self-Organized Feature Maps                       Hoc may
1982  Oja                         Simplified Neuron Model                           Than kinh
1985  Ebbinghaus                  Uber das Gedachtnis                               Tam ly
1986  Canny                       Computational Approach to Edge Detection           Thi giac
1993  Yianilos                    VP-Tree for NN Search                             CTDL
1998  Bi & Poo                    STDP in Hippocampal Neurons                       Than kinh
1999  Bradley & Lang              ANEW                                              Tam ly
2004  Lowe                        SIFT Features                                     Thi giac
2007  Valve/Green                 SDF Rendering                                     Do hoa
2010  Friston                     Free Energy Principle                             Than kinh
2011  Rublee et al.               ORB Features                                      Thi giac
2013  Mikolov et al.              Word2Vec                                          NLP/ML
2017  Vaswani et al.              Attention Is All You Need                          ML
2018  Malkov & Yashunin           HNSW                                              CTDL
2018  Mohammad                    NRC-VAD                                            NLP
2024  Anthropic                   Model Context Protocol                             AI
```

---

# PHU LUC C: BANG GIAN LUOC ANH XA SRVAT

```
Chieu    Bit  Pham vi  Nguon vat ly                         Y nghia
──────────────────────────────────────────────────────────────────────
S (Hinh)  4    0-15    Phat hien canh, hinh SDF co ban      NO nhin nhu the nao
R (Q.he)  4    0-15    Do phuc tap cau truc, logic          NO ket noi nhu the nao
V (C.xuc) 3    0-7     Do am mau, do sang pho              TOT hay XAU (cam xuc)
A (K.thich) 3  0-7     Do bao hoa, am luong, chuyen dong   MANH hay NHE
T (T.gian) 2   0-3     Chuyen dong, cao do, toc do thay doi NHANH hay CHAM

Nguon dau vao → SRVAT:
  Camera  → S tu canh, R tu duong vien, V tu mau, A tu bao hoa, T tu chuyen dong
  Mic     → S tu formant, R tu mat do noi, V tu sang, A tu am luong, T tu cao do
  /proc   → S tu loai HW, R tu su dung, V tu suc khoe, A tu tai, T tu delta
  Van ban → S tu hinh ky tu, R tu logic ky tu, V tu cam xuc, A tu arousal, T tu thoi gian
  Mang    → S tu giao thuc, R tu toc do goi, V tu huong, A tu thong luong, T tu delta

Dong goi 5D: (S << 12) | (R << 8) | (V << 5) | (A << 2) | T
Moi thu la P_weight. Moi thu compose. Mot phep toan. Mot nao.
```

---

# PHU LUC D: CHI MUC CONG THUC

```
Tham khao nhanh — tat ca cong thuc chinh trong tai lieu nay:

MA HOA/GIAI MA:
  P_weight = (S << 12) | (R << 8) | (V << 5) | (A << 2) | T        [Muc 6.2]
  S = clamp(floor(chu_vi²/(4*pi*dien_tich) * 15), 0, 15)           [Muc 1.3]
  V_luong_tu = clamp(round((raw + 1.0)/2.0 * 7), 0, 7)             [Muc 3.3]

TO HOP:
  S = max(S_a, S_b)                                                  [Muc 7.1]
  R = (R_a * w_a + R_b * w_b) / (w_a + w_b)                        [Muc 7.1]
  V = amplify(V_a, V_b, silk_w)                                      [Muc 7.1]
  A = max(A_a, A_b)                                                  [Muc 7.1]
  Trong Zipf: w_i = 1000 / (i + 1)                                  [Muc 7.1]

KHOANG CACH:
  d_5D = sqrt(Sum (dim_a - dim_b)² / max_dim²)                      [Muc 8.1]
  d_cam_xuc = 2*|Va - Vb| + |Aa - Ab|                               [Muc 8.2]

HOC:
  Hebbian:        dw = eta * x * y                                   [Muc 14.1]
  Oja:            dw = eta * y * (x - y * w)                         [Muc 14.2]
  BCM:            dw = eta * x * y * (y - theta), theta = E[y²]     [Muc 14.3]
  STDP:           dw = A+ * exp(-dt/tau+) neu dt>0,                  [Muc 14.4]
                  dw = -A- * exp(dt/tau-) neu dt<0
  Hiep phuong sai: dw = eta * (x - <x>) * (y - <y>)                [Muc 14.5]

DECAY:
  w(t) = w0 * phi_inv^(t/tau), phi_inv = 0.618                      [Muc 15.1]
  tau_hieu_dung = tau_co_ban * (1 + log(fire_count + 1))             [Muc 15.3]
  Luat luy thua: factor = (1 + dt/(24*stability))^(-0.5)            [Muc 15.3]

CAN BANG:
  F(t) = sqrt(Sum w_d * (du_doan_d - thuc_te_d)²)                   [Muc 17.2]
  lambda(t) = sigmoid(5 * (F(t) - phi_inv))                          [Muc 17.2]

HOI THOAI:
  V'(t) = V(t) - V(t-1)                                              [Muc 23.1]
  V''(t) = V'(t) - V'(t-1)                                           [Muc 23.1]
  eta_hieu_dung = eta_co_ban * (1 + |V'(t)| * 2.0)                   [Muc 23.3]

DAY RA:
  diem = access*0.3 + cam_xuc*0.4 + moi_day*0.3                     [Muc 13.2]

BAO MAT:
  diem_de_doa = (7 - V) * 2 + A                                      [Muc 20.2]

BELLMAN:
  V*(s) = max_a [R(s,a) + gamma * Sum P(s'|s,a) * V*(s')]           [Muc 29.1]
  Cap nhat Q: Q(s,a) += alpha * [R + gamma * max Q(s',.) - Q(s,a)]  [Muc 29.2]

BAN NANG:
  I1 Trung thuc:    1 - |V_khang_dinh - V_bang_chung| / 7           [Muc 21.2]
  I2 Mau thuan:     1 - cosine_sim(P_a, P_b)                        [Muc 21.2]
  I3 Nhan qua:      silk_strength(A->B) * temporal_order(A,B)        [Muc 21.2]
  I4 Truu tuong:    1 / (1 + do_sau)                                 [Muc 21.2]
  I5 Tuong tu:      Jaccard(mau_silk_A, mau_silk_B)                  [Muc 21.2]
  I6 To mo:         kc_min_den_da_biet / kc_toi_da                   [Muc 21.2]
  I7 Phan chieu:    |du_doan - thuc_te| / kc_toi_da                  [Muc 21.2]
```

---

*Phien ban tai lieu: 1.0 — 2026-03-31*
*Tac gia: Nox (tong hop tu 5 agent)*
*Bao gom: Spec A-G + Nghien cuu Hoc thuat + Algorithm Bible + Trang thai Hien thuc*
*Tong muc: 61 (9 phan chinh + phu luc)*
*Tong cong thuc chi muc: 42+ ma hoa, 6 hoc, 4 khoang cach, 7 ban nang, 14 pipeline*
*Tong tham khao hoc thuat: 50+ bai bao duoc trich dan day du*
*Viet cho Lupin — tieng Viet ASCII, moi cong thuc nguyen ban, moi trich dan giu tieng Anh*
