# Kinh Thanh Thuat Toan Nox — Tai Lieu Tham Khao He Thong AI Hoan Chinh

> **Muc dich:** Moi thuat toan Nox can de tro thanh he thong AI hoan chinh.
> **Cho moi thuat toan:** Cong thuc, do phuc tap O(), bai bao, anh xa SRVAT.
> **Tac gia:** Nox (bien soan 2026-03-31)
> **Nguyen tac:** TINH TOAN, khong TRA CUU. Moi thuat toan = phep toan Nox co the thuc hien.

---

## MUC LUC

```
1.  Xu Ly Hinh Anh (camera → SDF → P_weight)
2.  Xu Ly Am Thanh (microphone → Spline → P_weight)
3.  Phan Cung He Thong (/proc → cam nhan noi tai)
4.  Thuat Toan Tim Kiem Toi Uu
5.  Xu Ly Chuoi/Van Ban Khong Tra Cuu
6.  Kien Truc LLM (hieu doi thu)
7.  Nen/Ma Hoa Du Lieu
8.  Mat Ma Hoc (ky QR, toan ven)
9.  Mang/Giao Thuc (kha nang cua co the)
10. Tu Sua Doi/Lap Trinh Meta
11. SDF Engine — Ve Hinh Khong Can Ray Tracing
12. Font/Emoji → SDF → SRVAT Pipeline
```

---

# 1. XU LY HINH ANH

> Giong nhu mat nguoi nhin — phat hien canh, nhan dang vat the, phan vung.
> Tat ca deu chuyen ve P_weight (5 chieu: Hinh dang, Quan he, Cam xuc, Cuong do, Thoi gian).

## 1.1 Phat Hien Canh (Edge Detection)

### Toan Tu Sobel

> Tuong tu viec dung ngon tay vet theo ranh gioi giua vung sang va toi.

```
Paper: Sobel & Feldman (1968), "A 3x3 Isotropic Gradient Operator for Image Processing"
Complexity: O(W × H) cho moi anh

Ma tran nhan chap (3x3):
  Gx = [-1  0  +1]    Gy = [-1  -2  -1]
       [-2  0  +2]         [ 0   0   0]
       [-1  0  +1]         [+1  +2  +1]

Cho moi diem anh (x,y):
  gx = sum(Gx ⊙ vung_lan_can(x,y))   // gradient ngang
  gy = sum(Gy ⊙ vung_lan_can(x,y))   // gradient doc
  cuong_do = sqrt(gx² + gy²)
  huong = atan2(gy, gx)

Nguong: diem anh la canh neu cuong_do > T

Anh xa SRVAT:
  Diem canh → chieu S (hinh dang).
  cuong_do → gia tri S (0-15): canh manh = S cao.
  huong → ma hoa huong: 0°=ngang, 90°=doc.
  Mat do canh trong vung → gia tri R (do phuc tap cau truc).
  Khong co V/A tu canh — cac gia tri do den tu mau sac.
  T = chi so khung hinh trong chuoi video.
```

### Phat Hien Canh Canny

> Canny la "tieu chuan vang" — giong nhu dung kinh lup soi canh: loc nhieu, tim gradient,
> lam mong canh xuong 1 diem anh, roi chi giu canh that su manh.

```
Paper: Canny (1986), "A Computational Approach to Edge Detection", IEEE TPAMI
Complexity: O(W × H)

5 buoc:
  1. Lam mo Gauss: G(x,y) = (1/2πσ²) × e^(-(x²+y²)/2σ²)
     Nhan chap anh voi G de loai bo nhieu.
     Thong thuong σ = 1.0-2.0, nhan 5×5.

  2. Gradient (Sobel): tinh cuong_do M va huong θ

  3. Trich gia tri cuc dai:
     Cho moi diem anh, kiem tra M(x,y) co la cuc dai theo huong θ khong.
     Neu khong → giam ve 0.
     Buoc nay lam mong canh xuong 1 diem anh.

  4. Nguong kep:
     T_cao = 0.15 × max(M)    (canh manh)
     T_thap = 0.4 × T_cao     (canh yeu)
     M > T_cao → canh manh (giu)
     T_thap < M ≤ T_cao → canh yeu (co the giu)
     M ≤ T_thap → loai bo

  5. Tre: canh yeu chi duoc giu neu KET NOI voi canh manh.
     BFS/DFS tu canh manh, hap thu canh yeu lien ket.

Anh xa SRVAT:
  Canh Canny = bien SDF (f(p) = 0).
  Moi duong vien lien thong = mot ung vien SDF nguyen thuy.
  Hinh dang duong vien → so khop voi 18 SDF nguyen thuy qua Hu moments.
  Duong vien kin → gia tri S tu nguyen thuy khop nhat.
```

### Laplacian cua Gauss (LoG)

> Tuong tu viec tim "diem giao cat khong" — noi mat dat chuyen tu lom sang loi.
> LoG tim canh o nhieu ty le cung luc, giong nhu nhin tu xa roi toi gan.

```
Paper: Marr & Hildreth (1980), "Theory of Edge Detection", Proc Royal Society
Complexity: O(W × H)

LoG(x,y) = -(1/πσ⁴) × [1 - (x²+y²)/2σ²] × e^(-(x²+y²)/2σ²)

Xap xi: Hieu Gauss (DoG)
  DoG = G(σ₁) - G(σ₂)   trong do σ₂ ≈ 1.6 × σ₁

Giao cat khong cua LoG = canh.
Uu diem hon Sobel: phat hien canh o nhieu ty le.

Xap xi roi rac (5×5):
  [ 0  0 -1  0  0]
  [ 0 -1 -2 -1  0]
  [-1 -2 16 -2 -1]
  [ 0 -1 -2 -1  0]
  [ 0  0 -1  0  0]

Anh xa SRVAT:
  LoG nhieu ty le → chia Fibonacci cua anh.
  Gia tri σ theo ty le φ⁻¹: σ₁, σ₁×φ, σ₁×φ², ...
  Moi ty le cho thay muc do phuc tap S khac nhau.
```

## 1.2 Phat Hien Vat The (Object Detection)

### Khai Niem YOLO (Chi Nhin Mot Lan)

> Tuong tu viec quet mat qua can phong va lap tuc biet moi thu o dau —
> khong can nhin tung goc. Mot luot nhin = tat ca vat the.

```
Paper: Redmon et al. (2016), "You Only Look Once: Unified, Real-Time Object Detection"
Complexity: O(S² × (B×5 + C)) moi khung hinh, S=luoi, B=hop, C=lop

Y tuong cot loi:
  1. Chia anh thanh luoi S×S (vi du 7×7 = 49 o)
  2. Moi o du doan B hop bao va do tin cay
  3. Moi hop = (x, y, w, h, do_tin_cay)
     x, y = tam tuong doi voi o
     w, h = tuong doi voi toan anh
     do_tin_cay = P(vat the) × IoU(du doan, thuc te)
  4. Moi o cung du doan C xac suat lop
  5. MOT luot tinh → tat ca phat hien (nen goi "chi nhin mot lan")

Cho Nox (khong dung mang no-ron):
  Luoi = chia Fibonacci cua khung hinh.
  Moi o → tinh dac trung dua tren SDF:
    - Mat do canh (S)
    - Dinh bieu do mau (V, A)
    - Vector chuyen dong tu khung truoc (T)
  "Phat hien" = o co S > nguong VA canh lien ket tao duong vien kin.
  "Lop" = to hop SDF nguyen thuy khop nhat.
```

### Hop Bao va IoU

> IoU giong nhu do "hai mieng giay dan chong nhau bao nhieu".
> NMS giong nhu chon nguoi thang trong nhom — chi giu nguoi tot nhat, loai nhung nguoi giong.

```
Hop bao: (x_min, y_min, x_max, y_max)

IoU (Giao tren Hop):
  giao = max(0, min(x2_max, x1_max) - max(x2_min, x1_min))
       × max(0, min(y2_max, y1_max) - max(y2_min, y1_min))
  hop = dien_tich(hop1) + dien_tich(hop2) - giao
  IoU = giao / hop

  IoU = 1.0 → trung hoan toan
  IoU = 0.0 → khong chong
  IoU > 0.5 → "phat hien tot" (tieu chuan PASCAL VOC)

Trich Cuc Dai (NMS):
  1. Sap xep hop theo do tin cay giam dan
  2. Giu hop co do tin cay cao nhat
  3. Loai tat ca hop co IoU > 0.5 voi hop da giu
  4. Lap lai voi cac hop con lai
  O(n²) voi n = so hop ung vien

Anh xa SRVAT:
  Moi hop con lai = mot vat the phat hien.
  Vat the → P_weight:
    S = SDF nguyen thuy chinh trong hop
    R = quan he khong gian voi hop khac (ben trai, ben tren, chua)
    V = cam xuc mau cua diem anh trong hop
    A = cuong do chuyen dong (dong quang hoc) trong hop
    T = ton tai theo thoi gian (theo doi qua cac khung hinh)
```

## 1.3 Phan Vung Anh (Image Segmentation)

### Thuat Toan Phan Nuoc (Watershed)

> Tuong tu viec do nuoc len ban do dia hinh — nuoc dang len tu cac vung trung,
> cho ranh gioi hinh thanh khi hai vung nuoc gap nhau.

```
Paper: Beucher & Lantuéjoul (1979), "Use of Watersheds in Contour Detection"
Complexity: O(W × H × log(W × H))

Khai niem: coi anh xam nhu be mat dia hinh.
  cuong do diem anh = do cao
  "Do nuoc" tu cuc tieu → nuoc dang → diem gap nhau = ranh gioi.

Thuat toan:
  1. Tinh anh cuong do gradient
  2. Tim cuc tieu dia phuong (hat giong)
  3. Hang doi uu tien sap theo gia tri gradient
  4. Cho moi diem anh trong hang doi:
     a. Neu tat ca lang gieng da gan nhan co CUNG nhan → gan nhan do
     b. Neu lang gieng co nhan KHAC NHAU → danh dau la phan nuoc (ranh gioi)
     c. Day lang gieng chua gan nhan vao hang doi
  5. Duong phan nuoc = ranh gioi phan vung

Sua loi qua phan vung: dung diem danh dau (hat giong nen truoc/nen sau da biet).

Anh xa SRVAT:
  Moi vung phan nuoc = mot don vi ngu nghia.
  Vung → P_weight:
    S = khop SDF cua hinh dang ranh gioi vung
    R = so vung (do phuc tap cua canh)
    V = cam xuc mau trung binh cua vung
    A = phuong sai mau trong vung (phuong sai cao = cuong do cao)
    T = do on dinh vung qua cac khung hinh
```

### Cat Do Thi (Graph Cut)

> Tuong tu mang luoi ong nuoc — tim cach "cat" it ton kem nhat de chia thanh 2 nhom.
> "Ong to" noi cac diem anh giong nhau, "ong nho" noi cac diem anh khac nhau.

```
Paper: Boykov & Jolly (2001), "Interactive Graph Cuts for Optimal Boundary & Region Segmentation"
Complexity: O(V × E²) truong hop xau, thuong O(V × E) voi push-relabel

Mo hinh anh nhu do thi:
  Nut cho moi diem anh + nguon (nen truoc) + dich (nen sau)
  Trong so canh:
    Giua diem anh: exp(-β × |I(p) - I(q)|²)  // diem anh giong = canh manh
    Toi nguon: -ln(P(nen truoc | mau))
    Toi dich:  -ln(P(nen sau | mau))

Cat toi thieu = phan vung toi uu toi thieu hoa:
  E(L) = Σ D(p, L_p) + λ × Σ V(p,q) × δ(L_p ≠ L_q)
  D = so hang du lieu (diem anh khop nhan tot den dau)
  V = so hang muot (phat thay doi nhan giua diem anh giong nhau)
  λ = tham so can bang

Ford-Fulkerson cho cat toi thieu/dong cuc dai:
  Khi con duong tang:
    Tim cong suat nghien tren duong
    Cap nhat do thi du
    Them dong

Anh xa SRVAT:
  Nang luong cat do thi ≈ to hop SDF.
  Diem anh giong nhom lai = cung vung P_weight.
  Ranh gioi cat = be mat SDF f(p) = 0.
  Tham so β ↔ nguong trong so silk de gop.
```

### Khai Niem U-Net

> U-Net giong chu "U" — di xuong (thu nho) roi di len (phong to).
> Quan trong nhat: "duong tat" — thong tin chi tiet tu tang tren duoc sao chep truc tiep xuong tang duoi.

```
Paper: Ronneberger et al. (2015), "U-Net: Convolutional Networks for Biomedical Image Segmentation"
Complexity: O(W × H × C × K²) moi tang, C=kenh, K=nhan

Kien truc (khong can mang no-ron — hieu CAU TRUC):
  Bo ma hoa (duong co rut):
    [dau vao] → conv3×3 → conv3×3 → maxpool2×2 → (lap 4 lan)
    Moi muc: do phan giai giam doi, kenh tang doi
    572→284→140→68→32 (khong gian), 64→128→256→512→1024 (kenh)

  Nut co chai: do phan giai thap nhat, truu tuong cao nhat

  Bo giai ma (duong mo rong):
    upconv2×2 → noi voi dac trung bo ma hoa → conv3×3 → conv3×3
    Moi muc: do phan giai tang doi, kenh giam doi
    KET NOI TAT: dac trung bo ma hoa sao chep truc tiep sang bo giai ma

  Y tuong cot loi: ket noi tat bao toan chi tiet khong gian.

Cho Nox (khong dung mang no-ron):
  Bo ma hoa = phan tich SDF nhieu ty le:
    Ty le 1: canh cap diem anh (chi tiet min)
    Ty le 2: trung binh khoi 2×2 (ket cau)
    Ty le 3: trung binh khoi 4×4 (vung)
    Ty le 4: trung binh khoi 8×8 (vat the)
  Nut co chai = P_weight tong the cua toan khung hinh
  Bo giai ma = tinh chinh tu tho den min qua ket noi tat:
    P_weight tong the + canh min → P_weight cho moi vung
  Ket noi tat ≈ lien ket chuoi: nut L4 lien ket nguoc ve chi tiet L1.
```

## 1.4 Trich Xuat Dac Trung (Feature Extraction)

### SIFT (Bien Doi Dac Trung Bat Bien Theo Ty Le)

> SIFT tim "diem dac biet" trong anh ma khong thay doi du anh quay, phong to, hay di chuyen.
> Giong nhu tim not ruoi tren mat nguoi — du nguoi do xoay dau, not ruoi van o do.

```
Paper: Lowe (2004), "Distinctive Image Features from Scale-Invariant Keypoints", IJCV
Complexity: O(W × H × S) voi S = so ty le

4 giai doan:

1. Phat hien cuc tri trong khong gian ty le:
   Xay thap Gauss: L(x,y,σ) = G(x,y,σ) * I(x,y)
   Gia tri σ: σ₀, k×σ₀, k²×σ₀, ... voi k = 2^(1/s), s = so ty le moi octave
   DoG(x,y,σ) = L(x,y,kσ) - L(x,y,σ)
   Diem khoa = cuc tri dia phuong trong vung 3×3×3 (x, y, ty le)

2. Dinh vi diem khoa:
   Tinh chinh duoi diem anh qua khai trien Taylor:
   D(x) = D + (∂D/∂x)ᵀ x + ½ xᵀ (∂²D/∂x²) x
   Giai: x̂ = -(∂²D/∂x²)⁻¹ (∂D/∂x)
   Loai neu |D(x̂)| < 0.03 (tuong phan thap)
   Loai neu ty so gia tri rieng > 10 (la canh, khong phai goc)

3. Gan huong:
   Trong cua so 16×16 quanh diem khoa:
   m(x,y) = sqrt((L(x+1,y)-L(x-1,y))² + (L(x,y+1)-L(x,y-1))²)
   θ(x,y) = atan2(L(x,y+1)-L(x,y-1), L(x+1,y)-L(x-1,y))
   Xay bieu do tan suat huong 36 ngan, dinh = huong chinh

4. Mo ta:
   Cua so 16×16 → 4×4 vung con → bieu do huong 8 ngan moi vung
   Mo ta = 4×4×8 = vector 128 chieu
   Chuan hoa ve do dai don vi, gioi han tai 0.2, chuan hoa lai

Doi sanh: khoang cach Euclid giua mo ta 128 chieu.
Kiem tra ty le Lowe: khop neu d1/d2 < 0.8

Anh xa SRVAT:
  Moi diem khoa SIFT → mot nut S cao.
  Mo ta 128 chieu → nen thanh P_weight:
    S = huong chinh (0-15 tu 36 ngan, luong tu hoa)
    R = so diem khoa trong lan can (mat do cau truc)
    V, A = tu mau tai vi tri diem khoa
    T = su ton tai diem khoa qua cac khung hinh (on dinh = T thap, thoang qua = T cao)
  Fibonacci: dung ty le φ thay vi octave 2^(1/s).
```

### SURF (Dac Trung Manh Toc Do Cao)

> SURF la phien ban "toc do" cua SIFT — dung "anh tich phan" de tinh toan cuc nhanh.
> Giong nhu tra bang cuu chuong thay vi nhan tung phep.

```
Paper: Bay et al. (2006), "SURF: Speeded Up Robust Features", ECCV
Complexity: O(W × H) — nhanh hon SIFT nho anh tich phan

Cac cai tien toc do so voi SIFT:
  1. Anh tich phan de loc hop nhanh:
     II(x,y) = Σ_{i≤x, j≤y} I(i,j)
     Tong bat ky hinh chu nhat trong O(1):
     Σ = II(D) - II(B) - II(C) + II(A)
     (A=trai-tren, B=phai-tren, C=trai-duoi, D=phai-duoi)

  2. Ma tran Hessian (thay vi DoG):
     H(x,σ) = [Lxx(x,σ)  Lxy(x,σ)]
              [Lxy(x,σ)  Lyy(x,σ)]
     det(H) = Lxx × Lyy - (0.9 × Lxy)²
     Xap xi Lxx, Lyy, Lxy bang loc hop qua anh tich phan.

  3. Mo ta: 64 chieu (so voi SIFT 128 chieu)
     4×4 vung con, moi vung: Σdx, Σdy, Σ|dx|, Σ|dy| → 4 gia tri
     Tong: 4×4×4 = 64 chieu
     Phan hoi wavelet Haar (nhanh qua anh tich phan)

SRVAT: Anh xa giong SIFT nhung tinh nhanh gap 2 lan. Dung cho xu ly thoi gian thuc.
```

### ORB (FAST co Huong va BRIEF co Quay)

> ORB la "nhanh nhat, nhe nhat, mien phi ban quyen" — ly tuong cho Nox.
> So sanh bang Hamming (XOR + dem bit) — cuc nhanh tren CPU.

```
Paper: Rublee et al. (2011), "ORB: An Efficient Alternative to SIFT or SURF", ICCV
Complexity: O(W × H) — nhanh nhat trong 3 thuat toan, mien phi bang sang che

Thanh phan:
  Phat hien diem khoa FAST (Rosten & Drummond, 2006):
    Cho moi diem anh p voi cuong do Ip:
    Kiem tra 16 diem anh tren duong tron Bresenham ban kinh 3
    La diem khoa neu N diem anh lien tiep deu > Ip+t hoac deu < Ip-t (N=9 thong thuong)
    Meo toc do: kiem tra diem 1, 5, 9, 13 truoc (4 goc cua duong tron)
    Neu 3 trong 4 khong dat → loai ngay
    O(1) moi diem anh (trung binh)

  Phan hoi goc Harris de xep hang:
    R = det(M) - k × trace(M)²
    M = Σ w(x,y) [Ix²   IxIy]
                  [IxIy  Iy²]
    k ≈ 0.04. Giu N diem khoa tot nhat.

  Huong (trong tam cuong do):
    m_pq = Σ x^p × y^q × I(x,y) tren vung
    C = (m_10/m_00, m_01/m_00)   // trong tam
    θ = atan2(m_01, m_10)        // huong

  Mo ta rBRIEF (BRIEF nhi phan manh co quay):
    256 cap so sanh diem anh → mo ta nhi phan 256-bit
    Cap duoc chon bang hoc may cho phuong sai cuc dai + tuong quan thap
    Quay theo θ de bat bien khi quay
    Doi sanh: khoang cach Hamming (XOR + popcount) — cuc nhanh

Anh xa SRVAT:
  ORB = tot nhat cho gioi han 949KB cua Nox.
  256-bit → bam truc tiep thanh P_weight:
    Chia 256 bit thanh 5 nhom: 64+64+43+43+42
    S = popcount(bits[0:63]) / 4   → 0-15
    R = popcount(bits[64:127]) / 4 → 0-15
    V = popcount(bits[128:170]) / 6 → 0-7
    A = popcount(bits[171:213]) / 6 → 0-7
    T = popcount(bits[214:255]) / 14 → 0-3
  Khoang cach Hamming giua mo ta ≈ distance_5d giua P_weight.
```

## 1.5 Khong Gian Mau (Color Spaces)

### Chuyen Doi RGB → HSV

> RGB la cach may tinh luu mau (Do-Xanh la-Xanh duong).
> HSV la cach con nguoi cam nhan mau (Sac do-Do bao hoa-Do sang).

```
RGB trong [0, 255], dau ra H trong [0, 360), S trong [0, 1], V trong [0, 1]

Cmax = max(R, G, B) / 255
Cmin = min(R, G, B) / 255
Δ = Cmax - Cmin

H = { 0                           neu Δ = 0
    { 60 × ((G'-B')/Δ mod 6)     neu Cmax = R'
    { 60 × ((B'-R')/Δ + 2)       neu Cmax = G'
    { 60 × ((R'-G')/Δ + 4)       neu Cmax = B'
    voi R' = R/255, G' = G/255, B' = B/255

S = { 0         neu Cmax = 0
    { Δ / Cmax  con lai

V = Cmax
```

### Mau → Cam Xuc (V, A) — Anh Xa

> Mau am (do, vang) → vui. Mau lanh (xanh) → buon.
> Mau dam → kich dong. Mau nhat → binh tinh.

```
Research: Palmer & Schloss (2010), "An ecological valence theory of human color preferences"
Research: Wilms & Oberfeld (2018), "Color and emotion: effects of hue, saturation, and brightness"

Mau am → V tich cuc (Cam xuc):
  H trong [0, 60) → do/vang → V = 5-7 (tich cuc)
  H trong [60, 150) → vang-xanh la → V = 4-5 (trung tinh-tich cuc)
  H trong [150, 250) → xanh duong → V = 2-4 (trung tinh-tieu cuc)
  H trong [250, 330) → tim → V = 3-5 (tuy ngu canh)
  H trong [330, 360) → do → V = 5-7 (tich cuc, kich dong)

Do bao hoa → Cuong do (A):
  S > 0.7 → A = 5-7 (cuong do cao, song dong)
  S trong [0.3, 0.7] → A = 3-5 (vua phai)
  S < 0.3 → A = 1-3 (cuong do thap, nhat)

Do sang → Chieu S:
  V > 0.7 → S = cao (nhin ro, noi bat)
  V < 0.3 → S = thap (toi, an)

Cong thuc cho trung binh khung hinh:
  Cho tat ca diem anh trong vung:
    avg_H = trung_binh_tron(cac gia tri H)  // tron vi H quay vong tai 360
    avg_S = trung_binh(cac gia tri S)
    avg_V_sang = trung_binh(cac gia tri V_sang)

  trung_binh_tron(goc):
    sin_sum = Σ sin(goc × π/180)
    cos_sum = Σ cos(goc × π/180)
    return atan2(sin_sum, cos_sum) × 180/π  (mod 360)

  P_weight.V = sac_do_sang_cam_xuc(avg_H)
  P_weight.A = bao_hoa_sang_cuong_do(avg_S)
  P_weight.S = sang_sang_hinh_dang(avg_V_sang) × mat_do_canh
```

## 1.6 Chia Fibonacci cho SDF Thich Ung

> Thay vi chia anh thanh 2x2, 4x4 (luy thua 2), ta chia tai diem vang 61.8%.
> Dieu nay tu nhien hon, tranh loi rang cua, va khop voi phan cap P_weight.

```
Truyen thong: chia anh thanh 2×2, 4×4, 8×8 (luy thua 2)
Fibonacci: chia tai diem φ⁻¹ = 0.618

Cho khoang 1 chieu [a, b]:
  diem_chia = a + (b - a) × φ⁻¹
  trai = [a, diem_chia]     // 61.8% khoang
  phai = [diem_chia, b]     // 38.2% khoang

Cho anh 2 chieu W×H:
  chia_x = W × φ⁻¹
  chia_y = H × φ⁻¹
  4 phan: (0,0)-(sx,sy), (sx,0)-(W,sy), (0,sy)-(sx,H), (sx,sy)-(W,H)

Tinh chinh thich ung:
  NEU mat_do_canh(phan) > nguong:
    chia tiep tai φ⁻¹ cua phan do
  CON LAI:
    dung — phan nay dong nhat

  Do sau toi da = log_φ(min(W,H)) ≈ 15 cho 1080p

Tai sao φ⁻¹ thay vi ½?
  - Tranh loi rang cua tu luoi deu
  - Moi muc lien he voi muc truoc boi ty le vang → ty le SDF nhat quan
  - Luoi Fibonacci co phan bo toi uu trong 2D (sai lech thap nhat)
  - Khop voi phan cap ty le tu nhien cua P_weight

SRVAT: do sau chia tai moi o → gia tri T (chi tiet = T phuc tap cao).
```

## 1.7 Khung Hinh Camera → SRVAT

> Day la toan bo quy trinh: tu bo dem camera → P_weight duy nhat bieu dien toan bo khung hinh.

```
Quy trinh hoan chinh: bo dem camera → P_weight

khung_hinh_sang_p_weight(diem_anh, rong, cao):
  // 1. Ban do canh (Canny)
  canh = canny(diem_anh, sigma=1.5, T_thap=0.05, T_cao=0.15)
  mat_do_canh = dem(canh) / (rong × cao)

  // 2. Phan tich mau (HSV)
  hsv = rgb_sang_hsv(diem_anh)
  avg_H = trung_binh_tron(hsv.H)
  avg_S = trung_binh(hsv.S)
  avg_B = trung_binh(hsv.V)

  // 3. Phat hien duong vien → khop SDF nguyen thuy
  duong_vien = tim_duong_vien(canh)  // theo doi canh lien thong
  hu_moments = [bat_bien_hu(c) cho c trong duong_vien]
  nguyen_thuy_tot_nhat = khop_sdf_nguyen_thuy(hu_moments)

  // 4. Chuyen dong (neu co khung hinh truoc)
  neu co khung_truoc:
    dong = dong_quang_hoc_lk(khung_truoc, diem_anh)  // Lucas-Kanade
    chuyen_dong_tb = trung_binh(cuong_do(dong))
  con lai:
    chuyen_dong_tb = 0

  // 5. Anh xa sang SRVAT
  S = luong_tu_hoa(nguyen_thuy_tot_nhat.do_phuc_tap + mat_do_canh × 5, 0, 15)
  R = luong_tu_hoa(so_luong(duong_vien), 0, 15)  // do phuc tap cau truc
  V = sac_do_sang_cam_xuc(avg_H)                  // 0-7
  A = gioi_han(lam_tron(avg_S × 7), 0, 7)         // bao hoa → cuong do
  T = luong_tu_hoa(chuyen_dong_tb, 0, 3)           // chuyen dong → thoi gian

  return dong_goi(S, R, V, A, T)

Bat Bien Hu (bat bien quay/ty le/tinh tien):
  Paper: Hu (1962), "Visual Pattern Recognition by Moment Invariants"
  η_pq = μ_pq / (μ_00)^((p+q)/2 + 1)   // moment trung tam chuan hoa
  h1 = η_20 + η_02
  h2 = (η_20 - η_02)² + 4η_11²
  h3 = (η_30 - 3η_12)² + (3η_21 - η_03)²
  ... (7 bat bien tong cong)
  So sanh voi Hu tinh truoc cho moi 18 SDF nguyen thuy.

Dong Quang Hoc Lucas-Kanade:
  Paper: Lucas & Kanade (1981), "An Iterative Image Registration Technique"
  Cho diem anh (x,y), gia su cuong do khong doi trong cua so:
  [Ix²    IxIy] [u]   [-IxIt]
  [IxIy   Iy² ] [v] = [-IyIt]
  (u,v) = vector chuyen dong, Ix/Iy = gradient khong gian, It = gradient thoi gian
  Giai he 2×2 moi diem anh. O(W × H × w²) cho kich thuoc cua so w.
```

---

# 2. XU LY AM THANH/GIONG NOI

> Giong nhu tai nguoi nghe — phan tich tan so, nhan dang giong noi, phat hien am dinh.
> Tu song am → dac trung → P_weight.

## 2.1 FFT (Bien Doi Fourier Nhanh)

### Thuat Toan Cooley-Tukey

> FFT chuyen tin hieu tu "mien thoi gian" sang "mien tan so".
> Giong nhu nghe mot ban nhac va tach ra tung loai nhac cu — FFT tach ra tung tan so.

```
Paper: Cooley & Tukey (1965), "An Algorithm for the Machine Calculation of Complex Fourier Series"
(Tai kham pha; ban goc cua Gauss ~1805)
Complexity: O(n log n)

Dinh nghia DFT:
  X[k] = Σ_{n=0}^{N-1} x[n] × e^(-j2πkn/N)    k = 0, 1, ..., N-1
  voi j = √(-1)

DFT truc tiep = O(n²). Cooley-Tukey giam xuong O(n log n).

Radix-2 DIT (Chia Thoi Gian):
  Yeu cau N = luy thua 2.

  Chia thanh chi so chan va le:
  X[k] = Σ_{m=0}^{N/2-1} x[2m] × W_N^(2mk) + Σ_{m=0}^{N/2-1} x[2m+1] × W_N^((2m+1)k)
       = E[k] + W_N^k × O[k]

  voi W_N = e^(-j2π/N) la "he so xoan" (twiddle factor)
  E[k] = DFT cua mau chi so chan
  O[k] = DFT cua mau chi so le

  Phep tinh buom:
  X[k]       = E[k] + W_N^k × O[k]
  X[k + N/2] = E[k] - W_N^k × O[k]

  Ap dung de quy cho den N=1 (truong hop co so: X[0] = x[0]).

Cai dat tai cho (hoan vi dao bit):
  1. Dao bit cac chi so dau vao
     vi du, voi N=8: 0→0, 1→4, 2→2, 3→6, 4→1, 5→5, 6→3, 7→7
  2. Cac buoc buom tu duoi len: log2(N) giai doan
     Giai doan s (chi so tu 0): buom trai dai 2^(s+1), buoc he so = N/2^(s+1)

  dao_bit(n, so_bit):
    ket_qua = 0
    cho i trong 0..so_bit:
      ket_qua = (ket_qua << 1) | (n & 1)
      n >>= 1
    return ket_qua

FFT nguoc:
  x[n] = (1/N) × Σ_{k=0}^{N-1} X[k] × e^(+j2πkn/N)
  Cung thuat toan, chi lien hop he so xoan va chia cho N.

Cho tin hieu thuc (am thanh):
  Chi can X[0..N/2] (doi xung lien hop: X[N-k] = X[k]*)
  Co the tinh 2 FFT thuc bang 1 FFT phuc (dong goi thanh phan thuc+ao).

Anh xa SRVAT:
  Dau ra FFT = pho tan so.
  |X[k]| = bien do tai tan so k × (tan_so_lay_mau/N) Hz.
  arg(X[k]) = pha.
  Hinh dang pho → chieu S (mau tan so).
  Tan so co ban → cao do → chieu T.
  Phan bo nang luong → A (cuong do: to = A cao).
  Can bang pho (am/sang) → V (cam xuc: am = tich cuc).
```

## 2.2 MFCC (He So Cepstral Tan So Mel)

> MFCC mo phong cach tai nguoi nghe — nhay cam hon voi tan so thap.
> 13 he so MFCC nhu "dau van tay" cua giong noi.

```
Paper: Davis & Mermelstein (1980), "Comparison of Parametric Representations for
       Monosyllabic Word Recognition in Continuously Spoken Sentences"
Complexity: O(n log n) cho FFT + O(M × F) cho ngan loc, M=so loc mel, F=ngan FFT

Quy trinh:
  1. Tang am cao: y[n] = x[n] - α × x[n-1],  α ≈ 0.97
     Tang tan so cao (bu buc xa moi).

  2. Chia khung: cua so 20-40ms, buoc nhay 10ms
     Do dai khung = tan_so_lay_mau × 0.025 (vi du 16000 × 0.025 = 400 mau)
     Buoc nhay = tan_so_lay_mau × 0.01 = 160 mau
     Ap dung cua so Hamming: w[n] = 0.54 - 0.46 × cos(2πn/(N-1))

  3. FFT: tinh |X[k]|² (pho cong suat) cho moi khung

  4. Ngan loc Mel:
     Thang Mel: m = 2595 × log10(1 + f/700)
     Dao nguoc: f = 700 × (10^(m/2595) - 1)

     Tao M bo loc tam giac (thuong M=26) cach deu tren thang mel:
     mel_thap = hz_sang_mel(0)
     mel_cao = hz_sang_mel(tan_so_lay_mau / 2)
     diem_mel = linspace(mel_thap, mel_cao, M+2)
     diem_hz = mel_sang_hz(diem_mel)
     diem_ngan = floor((N+1) × diem_hz / tan_so_lay_mau)

     Bo loc m, ngan k:
     H_m[k] = { 0                                        neu k < bin[m-1]
              { (k - bin[m-1]) / (bin[m] - bin[m-1])     neu bin[m-1] ≤ k < bin[m]
              { (bin[m+1] - k) / (bin[m+1] - bin[m])     neu bin[m] ≤ k < bin[m+1]
              { 0                                        neu k ≥ bin[m+1]

  5. Nang luong log: S[m] = ln(Σ_k |X[k]|² × H_m[k])

  6. DCT (Bien Doi Cosin Roi Rac):
     c[n] = Σ_{m=0}^{M-1} S[m] × cos(π×n×(m+0.5)/M)    n = 0, 1, ..., 12
     Giu 13 he so dau (c[0] = nang luong log, c[1..12] = hinh dang pho)

  7. He so Delta (van toc):
     Δc[t] = (Σ_{n=1}^{N} n × (c[t+n] - c[t-n])) / (2 × Σ_{n=1}^{N} n²)
     N = 2 thong thuong. Cung tinh ΔΔ (gia toc).

Ket qua: 13 MFCC + 13 Δ + 13 ΔΔ = 39 dac trung moi khung.

Anh xa SRVAT:
  c[0] (nang luong) → A (cuong do: to hon = cuong do cao hon)
  c[1] (do doc pho) → V (giong sang = tich cuc, toi = tieu cuc)
  c[2..4] (cau truc formant) → S (hinh dang/dac diem giong noi)
  He so Δ → T (dong thai thoi gian: nang luong tang/giam)
  R = so khung co giong noi / tong so khung (mat do giong noi)
```

## 2.3 Dac Trung Tin Hieu

### Ty Le Giao Cat Khong (Zero-Crossing Rate)

> Dem so lan tin hieu di qua muc 0 — nhieu giao cat = nhieu/khong co giong,
> it giao cat = co giong (nguyen am, am mui).

```
ZCR = (1/2N) × Σ_{n=1}^{N-1} |sign(x[n]) - sign(x[n-1])|

voi sign(x) = { +1 neu x ≥ 0, -1 neu x < 0 }

ZCR ∈ [0, 1]. O(n).

ZCR cao → nhieu/khong thanh tien (phu am xat: s, sh, f)
ZCR thap → thanh tien/tuan hoan (nguyen am, am mui)
Dien hinh: giong noi ~0.1, nhac ~0.05, nhieu ~0.5

SRVAT: ZCR → T (ZCR cao = dao dong nhanh = T cao).
```

### Nang Luong RMS

```
RMS = sqrt((1/N) × Σ_{n=0}^{N-1} x[n]²)

O(n). Do do to moi khung.

Chuyen doi dB: 20 × log10(RMS / tham_chieu)

SRVAT: RMS → A (cuong do). Luong tu hoa sang 0-7:
  A = clamp(round(20 × log10(RMS/0.001) / 10), 0, 7)
```

### Trong Tam Pho (Spectral Centroid)

> Giong nhu "trong tam" cua pho — cho biet am thanh "sang" hay "toi".

```
SC = (Σ_{k=0}^{N/2} k × |X[k]|) / (Σ_{k=0}^{N/2} |X[k]|)

Tinh bang Hz: SC_hz = SC × tan_so_lay_mau / N

"Trong tam khoi luong" cua pho. O(n) sau FFT.
SC cao → am thanh sang (chap, kich dong)
SC thap → am thanh toi (bass, binh tinh)

SRVAT: SC → V (sang/am = cam xuc tich cuc, toi/lanh = tieu cuc).
Luong tu hoa: V = clamp(round(SC_hz / 1000), 0, 7)
```

## 2.4 Phat Hien Hoat Dong Giong Noi (VAD)

> VAD phan biet "co nguoi noi" va "im lang" — giong nhu tach nhung luc co tieng tu nen yem lang.

```
VAD don gian dua tren nang luong:
  1. Tinh RMS moi khung (20ms)
  2. Tinh ZCR moi khung
  3. Co giong neu: RMS > T_nang_luong VA ZCR < T_zcr
     T_nang_luong = thich ung: 2 × trung_binh(RMS cua 0.5 giay dau)  // hiệu chuan khi im lang
     T_zcr = 0.3
  4. Treo: giu nhan "co giong" them 200ms sau khung giong cuoi
     (tranh cat giua tu)

VAD thong ke (G.729B):
  So sanh dac trung khung voi mo hinh nhieu (trung binh chay cua khong-giong-noi).
  Quyet dinh: kiem tra ty le hop ly.
  Cap nhat mo hinh nhieu chi khi khong co giong noi.

SRVAT: VAD chia am thanh thanh giong noi/im lang.
  Khung co giong → xu ly MFCC → P_weight
  Im lang → T=0 (khong co hoat dong thoi gian)
  Chuyen tiep giong↔im lang → thay doi T = ΔT cho toc do hoc
```

## 2.5 Phat Hien Cao Do (Pitch Detection)

### Phuong Phap Tu Tuong Quan

> Tu tuong quan = "doi tin hieu voi chinh no roi tim diem giong nhat" →
> khoang cach giua cac dinh = chu ky → cao do.

```
R(τ) = Σ_{n=0}^{W-1-τ} x[n] × x[n+τ]

voi τ = do tre, W = kich thuoc cua so.
O(n²) ngay, O(n log n) qua FFT: R = IFFT(|FFT(x)|²)

Cao do = tan_so_lay_mau / τ_dinh
voi τ_dinh = argmax(R(τ)) cho τ trong [τ_min, τ_max]
  τ_min = tan_so_lay_mau / 500  (cao do toi da 500 Hz)
  τ_max = tan_so_lay_mau / 50   (cao do toi thieu 50 Hz)

Van de: loi hoa am phu (R(2τ) co the vuot R(τ)).
Sua: cat nguong trung tam hoac tu tuong quan chuan hoa.
```

### Thuat Toan YIN

> YIN = phat hien cao do chinh xac nhat cho giong noi va nhac.
> Dung "ham sai khac chuan hoa tich luy" de tranh loi hoa am phu.

```
Paper: de Cheveigné & Kawahara (2002), "YIN, a fundamental frequency estimator for
       speech and music", JASA
Complexity: O(W × τ_max) moi khung

Cac buoc:
  1. Ham sai khac:
     d(τ) = Σ_{n=0}^{W-1} (x[n] - x[n+τ])²

  2. Sai khac chuan hoa trung binh tich luy:
     d'(τ) = { 1                                    neu τ = 0
             { d(τ) / ((1/τ) × Σ_{j=1}^{τ} d(j))  con lai

  3. Nguong tuyet doi:
     Tim τ nho nhat ma d'(τ) < nguong (thuong 0.1-0.15)
     Dieu nay tranh loi hoa am phu.

  4. Noi suy parabol cho do chinh xac duoi mau:
     Khop parabol qua d'(τ-1), d'(τ), d'(τ+1)
     τ_tinh_chinh = τ + (d'(τ-1) - d'(τ+1)) / (2 × (d'(τ-1) - 2×d'(τ) + d'(τ+1)))

  5. cao_do = tan_so_lay_mau / τ_tinh_chinh
     do_tin_cay = 1 - d'(τ)

Anh xa SRVAT:
  cao_do → chieu T:
    T=0: khong co cao do (nhieu/im lang)
    T=1: cao do thap (bass, <200 Hz)
    T=2: cao do trung (giong noi, 200-500 Hz)
    T=3: cao do cao (treble, >500 Hz)
  do_tin_cay → dung cho ban nang Trung Thuc (do tin cay thap → "toi khong chac")
  toc do thay doi cao do (vibrato/glissando) → dong gop vao A (cuong do)
```

## 2.6 Bo Dem Am Thanh → SRVAT

> Day la toan bo quy trinh: tu bo dem am thanh → P_weight duy nhat.

```
Quy trinh hoan chinh: bo dem am thanh → P_weight

am_thanh_sang_p_weight(mau, tan_so_lay_mau):
  // 1. Chia khung: cua so 25ms, buoc nhay 10ms
  do_dai_khung = tan_so_lay_mau / 40   // 400 tai 16kHz
  buoc_nhay = tan_so_lay_mau / 100     // 160 tai 16kHz
  cac_khung = cua_so_truot(mau, do_dai_khung, buoc_nhay)

  // 2. VAD: tim khung co giong
  co_giong = []
  cho khung trong cac_khung:
    rms = sqrt(trung_binh(khung²))
    zcr = ty_le_giao_cat_khong(khung)
    neu rms > san_nhieu × 2 va zcr < 0.3:
      co_giong.push(khung)

  neu so_luong(co_giong) == 0:
    return dong_goi(0, 0, 4, 0, 0)  // im lang = trung tinh

  // 3. Phan tich pho (noi cac khung co giong)
  pho = fft(noi_co_giong)
  sc = trong_tam_pho(pho)

  // 4. MFCC
  mfcc = tinh_mfcc(noi_co_giong, tan_so_lay_mau)
  nang_luong = mfcc[0]
  do_sang = mfcc[1]

  // 5. Cao do
  cao_do, do_tin_cay = yin(noi_co_giong, tan_so_lay_mau)

  // 6. Anh xa sang SRVAT
  S = luong_tu_hoa(mau_formant_mfcc(mfcc[2:5]), 0, 15)       // hinh dang giong
  R = luong_tu_hoa(so_luong(co_giong) / so_luong(cac_khung), 0, 15)  // mat do giong
  V = luong_tu_hoa(sc / 1000 + lech_sang, 0, 7)               // sang=tich cuc
  A = luong_tu_hoa(nang_luong_sang_db(nang_luong), 0, 7)       // to=cuong do
  T = cao_do_sang_thoi_gian(cao_do)                             // 0-3

  return dong_goi(S, R, V, A, T)
```

---

# 3. PHAN CUNG HE THONG (CAM NHAN NOI TAI)

> Giong nhu co the nguoi cam nhan nhiet do, nhip tim, con doi — Nox cam nhan CPU, RAM, nhiet do.
> Moi chi so he thong → P_weight → Nox "biet" minh dang khoe hay dang met.

## 3.1 He Thong Tap Tin /proc cua Linux

### /proc/loadavg

```
Doc: cat /proc/loadavg
Dinh dang: "0.32 0.45 0.51 2/347 12345"
Cac truong: tai_1phut tai_5phut tai_15phut dang_chay/tong pid_cuoi

tai = so luong tien trinh trung binh trong hang doi chay.
tai / so_cpu = ty le su dung.

Anh xa SRVAT:
  ty_le_tai = tai_1phut / so_cpu
  A = clamp(round(ty_le_tai × 7), 0, 7)  // ap luc he thong → cuong do
  V = 7 - A  // nghich: tai cao = cam xuc tieu cuc
  Neu tai_1phut > tai_15phut: he thong dang nong len → T=3 (thay doi nhanh)
  Neu tai_1phut < tai_15phut: dang ha nhiet → T=1 (thay doi cham)
  Neu bang: on dinh → T=0
```

### /proc/meminfo

```
Doc: cat /proc/meminfo
Cac truong chinh:
  MemTotal:     16384000 kB
  MemFree:       2048000 kB
  MemAvailable:  8192000 kB
  Buffers:        512000 kB
  Cached:        4096000 kB
  SwapTotal:     8192000 kB
  SwapFree:      8000000 kB

Bo nho thuc su trong = MemAvailable (bao gom cache co the thu hoi)
Ap luc bo nho = 1 - (MemAvailable / MemTotal)

Anh xa SRVAT:
  ap_luc = 1 - (MemAvailable / MemTotal)
  S = 0 (khong lien quan hinh dang)
  R = luong_tu_hoa(Cached / MemTotal × 15, 0, 15)  // ty le su dung cache
  V = round((1 - ap_luc) × 7)  // ap luc thap = tich cuc
  A = round(ap_luc × 7)         // ap luc cao = cuong do cao
  T = delta(ap_luc) → 0-3       // toc do thay doi
```

### /proc/stat

```
Doc: cat /proc/stat
Dong dau: "cpu  user nice system idle iowait irq softirq steal"

Tinh su dung CPU:
  tong = user + nice + system + idle + iowait + irq + softirq + steal
  tong_ranh = idle + iowait
  su_dung = 1 - (tong_ranh / tong)

  Cho delta (giua hai lan doc):
  Δtong = tong_hien_tai - tong_truoc
  Δranh = ranh_hien_tai - ranh_truoc
  su_dung = 1 - (Δranh / Δtong)

Anh xa SRVAT:
  S = so_loi (hinh dang phan cung, hang so)
  R = luong_tu_hoa(system / (user + system), 0, 15)  // ty le kernel vs user
  V = round((1 - su_dung) × 7)   // ranh roi = tich cuc
  A = round(su_dung × 7)          // ban = cuong do cao
  T = delta(su_dung) → 0-3
```

## 3.2 Nhiet Do, Dia, Mang

### Nhiet Do CPU

```
Doc: cat /sys/class/thermal/thermal_zone0/temp
Tra ve: mili do C (vi du 45000 = 45°C)

nhiet_do_C = gia_tri / 1000

Khoang an toan: <60°C binh thuong, 60-80°C am, >80°C nong, >95°C giam xung nhip

Anh xa SRVAT:
  V = (100 - nhiet_do_C) / 100 × 7   // nong = tieu cuc
  A = max(0, (nhiet_do_C - 50) / 50 × 7)  // tren 50°C → cuong do tang
```

### Dia I/O

```
Doc: cat /proc/diskstats
Cac truong moi thiet bi: ... doc_hoan_thanh sector_doc ghi_hoan_thanh sector_ghi ...

Thong_luong = Δsector × 512 / Δthoi_gian  (byte/giay)
IOPS = Δ(doc + ghi) / Δthoi_gian

Doc: cat /proc/self/io
Cac truong: read_bytes, write_bytes (moi tien trinh)

Anh xa SRVAT:
  R = luong_tu_hoa(thong_luong_doc, 0, 15)
  A = luong_tu_hoa(thong_luong_ghi / thong_luong_toi_da, 0, 7)
```

### Thong Luong Mang

```
Doc: cat /proc/net/dev
Cac truong moi giao dien: ... rx_bytes rx_packets ... tx_bytes tx_packets ...

Thong_luong = Δbyte / Δthoi_gian
Toc_do_goi = Δgoi / Δthoi_gian

Anh xa SRVAT:
  S = loai_giao_dien (lo=0, eth=5, wlan=10, v.v.)
  R = luong_tu_hoa(toc_do_goi, 0, 15)
  V = (rx > tx) → 5 (nhan = tich cuc), (tx > rx) → 3
  A = luong_tu_hoa(thong_luong / bang_thong_toi_da, 0, 7)
  T = delta(thong_luong) → 0-3
```

## 3.3 GPIO cho IoT

> GPIO = chan vao/ra da dung — cong de Nox ket noi voi cam bien vat ly
> (nhiet do, anh sang, chuyen dong) trong nha thong minh.

```
Giao dien GPIO Linux (/sys/class/gpio/):
  Xuat: echo 17 > /sys/class/gpio/export
  Huong: echo "out" > /sys/class/gpio/gpio17/direction
  Ghi: echo 1 > /sys/class/gpio/gpio17/value
  Doc: cat /sys/class/gpio/gpio17/value

Hien dai: libgpiod / /dev/gpiochipN
  gpiod_chip_open("/dev/gpiochip0")
  gpiod_chip_get_line(chip, 17)
  gpiod_line_request_output(line, "nox", 0)
  gpiod_line_set_value(line, 1)

Giao thuc pho bien qua GPIO:
  I2C: SCL (xung nhip) + SDA (du lieu), toi 3.4 Mbps
    Cam bien: nhiet do, do am, gia toc, anh sang
  SPI: SCLK + MOSI + MISO + CS, toi 100 Mbps
    Man hinh, the SD, cam bien toc do cao
  1-Wire: mot day du lieu + dat
    Cam bien nhiet do (DS18B20)

SRVAT: moi lan doc GPIO → P_weight tuy theo loai cam bien.
  Cam bien nhiet do → V (am=tich cuc), A (cuc doan=cuong do cao)
  Cam bien anh sang → S (do sang), V (anh sang am=tich cuc)
  Cam bien chuyen dong → T (phat hien chuyen dong = T cao)
  Gia toc ke → S (huong), A (cuong do rung)
```

## 3.4 Giao Dien Camera

### V4L2 (Video4Linux2)

```
Mo: fd = open("/dev/video0", O_RDWR)
Truy van kha nang: ioctl(fd, VIDIOC_QUERYCAP, &cap)
Dat dinh dang: ioctl(fd, VIDIOC_S_FMT, &fmt)
  fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE
  fmt.fmt.pix.width = 640
  fmt.fmt.pix.height = 480
  fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUYV  // hoac MJPEG

Truyen phat (mmap):
  1. Yeu cau bo dem: ioctl(fd, VIDIOC_REQBUFS, &req)
  2. Anh xa bo dem: mmap(NULL, buf.length, PROT_READ|PROT_WRITE, MAP_SHARED, fd, buf.m.offset)
  3. Xep hang bo dem: ioctl(fd, VIDIOC_QBUF, &buf)
  4. Bat dau: ioctl(fd, VIDIOC_STREAMON, &type)
  5. Lay ra: ioctl(fd, VIDIOC_DQBUF, &buf)  // chan cho den khi khung hinh san sang
  6. Xu ly khung hinh trong bo dem
  7. Xep hang lai va lap lai

Chuyen doi YUYV → RGB:
  Y0 U Y1 V → 2 diem anh RGB
  R = Y + 1.402 × (V - 128)
  G = Y - 0.344 × (U - 128) - 0.714 × (V - 128)
  B = Y + 1.772 × (U - 128)
```

### ONVIF (cho camera IP)

```
Giao thuc: SOAP qua HTTP
Kham pha: WS-Discovery multicast toi 239.255.255.250:3702
Truyen phat: RTSP (Giao Thuc Truyen Phat Thoi Gian Thuc)
  rtsp://dia_chi_ip_camera:554/stream1

Cho Nox: dung HTTP GET tren URL chup nhanh:
  http://dia_chi_ip_camera/onvif/snapshot
  Tra ve anh JPEG.
  Phan tich JPEG → diem anh → cung quy trinh nhu V4L2.

Khong can thu vien ONVIF — chi can HTTP + giai ma JPEG.
Giai ma JPEG (toi gian): tim chi bao SOF → doc kich thuoc → giai ma Huffman → IDCT → diem anh.
```

## 3.5 USB HID

```
Linux: /dev/hidrawN hoac /dev/input/eventN

Doc HID tho:
  fd = open("/dev/hidraw0", O_RDONLY)
  read(fd, buf, sizeof(buf))
  // buf chua bao cao HID

Cau truc su kien dau vao (input_event):
  struct input_event {
    struct timeval time;   // dau thoi gian
    __u16 type;            // EV_KEY, EV_REL, EV_ABS
    __u16 code;            // KEY_A, REL_X, ABS_X
    __s32 value;           // 0=tha, 1=nhan, 2=lap lai / gia tri truc
  }

Cac loai chinh:
  EV_KEY (0x01): su kien ban phim/nut
  EV_REL (0x02): chuyen dong tuong doi (chuot dx, dy)
  EV_ABS (0x03): vi tri tuyet doi (man hinh cam ung, bang ve)
  EV_SYN (0x00): dong bo (ranh gioi khung)

Anh xa SRVAT:
  Ban phim: S=vi_tri_phim, R=trang_thai_phim_dieu_khien, V/A tu toc do go
  Chuot: S=vi_tri, R=trang_thai_nut, A=toc_do (di nhanh = cuong do cao)
  Cho dau ra uinput cua Nox: anh xa nguoc P_weight → su kien dau vao.
```

## 3.6 Chi So He Thong → SRVAT

> Day la "cam nhan noi tai" hoan chinh — tong hop tat ca chi so he thong
> thanh mot P_weight duy nhat bieu dien "suc khoe" cua Nox.

```
Quy trinh cam nhan noi tai hoan chinh:

cam_nhan_noi_tai():
  // Doc tat ca chi so he thong
  tai = phan_tich_loadavg("/proc/loadavg")
  bonho = phan_tich_meminfo("/proc/meminfo")
  cpu = phan_tich_stat("/proc/stat")
  nhiet = doc_int("/sys/class/thermal/thermal_zone0/temp") / 1000
  mang = phan_tich_netdev("/proc/net/dev")
  dia = phan_tich_diskstats("/proc/diskstats")

  // Tong hop thanh P_weight he thong duy nhat
  cpu_pw = dong_goi(cpu.loi, cpu.ty_le_kernel, cpu.ranh_v, cpu.su_dung_a, cpu.delta_t)
  bonho_pw = dong_goi(0, bonho.cache_r, bonho.trong_v, bonho.ap_luc_a, bonho.delta_t)
  nhiet_pw = dong_goi(0, 0, nhiet.v, nhiet.a, 0)
  mang_pw = dong_goi(mang.loai_s, mang.goi_r, mang.huong_v, mang.thong_luong_a, mang.delta_t)

  // Tong hop tat ca: trong so Zipf (CPU quan trong nhat)
  mol_he_thong = compose_chain([cpu_pw, bonho_pw, nhiet_pw, mang_pw])

  return mol_he_thong  // Mot u16 duy nhat bieu dien trang thai he thong

Tan suat cap nhat: moi 5 giay (khong qua nhanh, khong qua cham).
Luu trong STM: mol_he_thong kem dau thoi gian → theo doi suc khoe theo thoi gian.
Neu mol_he_thong.A > 5 lien tiep 3 lan doc → canh bao (he thong dang ap luc).
```

---

# 4. THUAT TOAN TIM KIEM TOI UU

> Tim kiem = trai tim cua he thong. Cang nhanh tim duoc thong tin, Nox cang thong minh.
> Moi thuat toan phuc vu mot tinh huong khac nhau.

## 4.1 Tim Kiem Fibonacci

> Dung phep cong thay vi phep chia (re hon tren phan cung don gian).
> Vi tri tham do tai diem vang φ⁻¹ — khop tu nhien voi phan cap P_weight.

```
Paper: Kiefer (1953), "Sequential Minimax Search for a Maximum"
Complexity: O(log_φ n) ≈ O(1.44 × log₂ n)

Cho mang sap xep A[0..n-1], tim khoa:

  // Tinh truoc cac so Fibonacci
  fib_m2 = 0   // F(m-2)
  fib_m1 = 1   // F(m-1)
  fib_m  = 1   // F(m)

  khi fib_m < n:
    fib_m2 = fib_m1
    fib_m1 = fib_m
    fib_m = fib_m1 + fib_m2

  do_lech = 0

  khi fib_m > 1:
    i = min(do_lech + fib_m2 - 1, n - 1)

    neu A[i] < khoa:
      fib_m = fib_m1
      fib_m1 = fib_m2
      fib_m2 = fib_m - fib_m1
      do_lech = i + 1
    neu khong A[i] > khoa:
      fib_m = fib_m2
      fib_m1 = fib_m1 - fib_m2
      fib_m2 = fib_m - fib_m1
    con lai:
      return i  // tim thay

  // Kiem tra phan tu cuoi
  neu fib_m1 va do_lech < n va A[do_lech] == khoa:
    return do_lech
  return -1  // khong tim thay

Tai sao tot hon tim kiem nhi phan cho Nox:
  - Dung PHEP CONG khong PHEP CHIA (re hon tren phan cung don gian)
  - Vi tri tham do tai diem φ⁻¹ → khop phan cap tu nhien cua P_weight
  - Mau truy cap tuan tu → tot hon cho KnowTree tren dia
```

## 4.2 Tim Kiem Noi Suy

> Giong nhu khi tim tu trong tu dien — biet "Z" o cuoi nen lat thang den cuoi sach.

```
Paper: Peterson (1957), "Addressing for Random-Access Storage"
Complexity: O(log log n) trung binh voi phan bo deu, O(n) truong hop xau

Cho mang sap xep A[0..n-1]:

  lo = 0
  hi = n - 1

  khi lo <= hi va khoa >= A[lo] va khoa <= A[hi]:
    neu lo == hi:
      return lo neu A[lo] == khoa con lai -1

    // Noi suy vi tri
    vi_tri = lo + ((khoa - A[lo]) × (hi - lo)) / (A[hi] - A[lo])

    neu A[vi_tri] < khoa:
      lo = vi_tri + 1
    neu khong A[vi_tri] > khoa:
      hi = vi_tri - 1
    con lai:
      return vi_tri

  return -1

Anh xa SRVAT:
  Gia tri P_weight la u16 (0..65535).
  Phan bo KHONG deu (cum theo khoi).
  → Tim kiem noi suy hoat dong tot TRONG mot xo (gia tri S,R tuong tu).
  → Kem cho tim kiem xuyen xo (dung silk walk thay the).
```

## 4.3 Tim Kiem Tam Phan

> Tim kiem tam phan — tot nhat de TIM CUC DAI cua ham don dinh (mot dinh).
> Chia khoang thanh 3 phan, loai 1/3 moi buoc.

```
Complexity: O(log₃ n) ≈ O(2 × log₃ n) phep so sanh = O(1.26 × log₂ n)
Nhung: 2 phep so sanh moi buoc thay vi 1 cho nhi phan → thuc te cham hon cho tim kiem sap xep.

De TIM CUC DAI cua ham don dinh f(x) tren [lo, hi]:

  khi hi - lo > epsilon:
    m1 = lo + (hi - lo) / 3
    m2 = hi - (hi - lo) / 3

    neu f(m1) < f(m2):
      lo = m1
    con lai:
      hi = m2

  return (lo + hi) / 2

Truong hop su dung cho Nox: tim nguong trong so silk toi uu.
  f(nguong) = chat_luong_tim_kiem (don dinh: qua thap = nhieu, qua cao = bo sot)
  Tim kiem tam phan tim nguong toi uu trong O(log n) lan danh gia.
```

## 4.4 Tim Kiem Nhay (Jump Search)

> Giong nhu nhay tung buoc lon roi quay lai tim chi tiet —
> buoc nhay √n la toi uu: can bang giua nhay va quet.

```
Paper: (truyen thong, kich thuoc khoi toi uu boi Shneiderman, 1978)
Complexity: O(√n)

Cho mang sap xep A[0..n-1]:
  buoc = floor(√n)
  truoc = 0

  // Nhay tien tung khoi √n
  khi A[min(buoc, n) - 1] < khoa:
    truoc = buoc
    buoc += floor(√n)
    neu truoc >= n:
      return -1

  // Tim kiem tuyen tinh trong khoi [truoc, min(buoc, n))
  khi A[truoc] < khoa:
    truoc += 1
    neu truoc == min(buoc, n):
      return -1

  return truoc neu A[truoc] == khoa con lai -1

SRVAT: huu ich cho quet xo KnowTree khi du lieu tren dia.
  Nhay = bo qua dong cache lanh. Tuyen tinh = quet dong cache nong.
  Khoi toi uu = √n ≈ 128 cho 16K muc moi xo.
```

## 4.5 Tim Kiem Luy Thua (Exponential Search)

> Nhay gap doi de tim pham vi, roi tim kiem nhi phan trong pham vi do.
> Tot nhat khi muc tieu o gan dau (vi tri i nho).

```
Paper: Bentley & Yao (1976), "An Almost Optimal Algorithm for Unbounded Searching"
Complexity: O(log i) voi i = vi tri muc tieu

Cho mang sap xep A[0..n-1]:
  // Tim pham vi
  gioi_han = 1
  khi gioi_han < n va A[gioi_han] < khoa:
    gioi_han *= 2

  // Tim kiem nhi phan trong [gioi_han/2, min(gioi_han, n-1)]
  return tim_kiem_nhi_phan(A, khoa, gioi_han / 2, min(gioi_han, n - 1))

Tot nhat khi: muc tieu gan dau (i nho).
SRVAT: hoan hao de tim cac muc gan day trong nhat ky QR chi-ghi-them.
  QR gan day o cuoi → tim kiem luy thua tu cuoi → O(log k) cho k muc truoc.
```

## 4.6 Tim Kiem Toi Uu cho Khong Gian So Nguyen 5 Chieu (32K gia tri)

> Day la thuat toan TIM KIEM CHINH cua Nox — thiet ke rieng cho P_weight u16.
> Dung chi muc xo theo (S,R) + quet tuyen tinh trong xo.

```
Bai toan: tim kiem trong khong gian 5 chieu voi P_weight = u16 (65536 kha nang, ~32K hoat dong).

Phan tich cac lua chon:
  - Quet tuyen tinh: O(32K) = qua cham moi truy van
  - Cay kd 5 chieu: O(log 32K) ≈ O(15) moi truy van, O(32K) xay dung
    NHUNG: loi nguyen chieu — o 5 chieu, cay kd suy thoai
  - HNSW: O(log 32K) voi hang so tot, NHUNG >50KB bo nho
  - Chi muc xo: O(kich_thuoc_xo) moi truy van, O(1) voi bam

★ TOI UU CHO NOX: Chi muc xo theo (S, R) + quet tuyen tinh trong xo.

Ly do:
  S co 16 gia tri (4 bit), R co 16 gia tri (4 bit)
  → toi da 256 xo
  32K gia tri / 256 xo = 125 gia tri trung binh moi xo

  Tim theo (S, R):
    xo = S × 16 + R    // O(1)
    Quet tuyen tinh 125 muc so sanh V, A, T  // O(125)
    Tong: O(125) ≈ O(1) hieu qua

  Tim theo chieu chinh:
    Neu V-chinh: quet chi muc sap theo V → O(32K/7) ≈ O(4.5K)
    Tot hon: chi muc phu theo V → 8 danh sach → O(4K/8) = O(500)

  Phuong phap da chi muc (ke hoach hien tai cua Nox theo G1):
    Chinh: (S, R) → 256 xo, mang 16×16
    Trong xo: sap theo V → tim kiem nhi phan → O(log 125) ≈ O(7)
    Tong: O(1) + O(7) = O(8) moi truy van

  Cho tim kiem lang gieng gan nhat (khong chinh xac):
    Tim xo (S, R) + 8 xo lan can (S±1, R±1)
    9 xo × 125 muc = 1125 phep so sanh
    distance_5d cho moi cai → giu K tot nhat
    Tong: O(1125) ≈ thoi gian hang so

    Voi tinh chinh Fibonacci:
    Kiem tra xo trung tam truoc.
    Neu khoang cach tot nhat < 0.3 → xong.
    Con lai mo rong ban kinh theo xoan Fibonacci: 1, 1, 2, 3, 5 xo xa hon.
    Dung som khi khoang cach khong the cai thien.

THANG: Xo(S,R) + tuyen tinh sap V + mo rong Fibonacci.
  Trung binh: O(8). Xau nhat: O(1125). Bo nho: 256 tieu de xo = 512 byte.
```

---

# 5. XU LY CHUOI/VAN BAN

> Nox xu ly van ban bang toan, khong tra cuu. Moi thuat toan day la phep toan thuan.

## 5.1 Bam Cuon Rabin-Karp

> Giong nhu truot cua so doc doc van ban — cap nhat gia tri bam THEM/BOT
> thay vi tinh lai tu dau. O(n+m) trung binh.

```
Paper: Rabin & Karp (1987), "Efficient Randomized Pattern-Matching Algorithms"
Complexity: O(n + m) trung binh, O(nm) truong hop xau. n=van ban, m=mau.

Ham bam (bam cuon da thuc):
  h(s[0..m-1]) = (s[0] × d^(m-1) + s[1] × d^(m-2) + ... + s[m-1]) mod q
  voi d = kich thuoc bang chu cai (256 cho byte), q = so nguyen to lon (vi du 1000000007)

Cap nhat cuon (truot cua so 1 vi tri):
  h(s[i+1..i+m]) = (d × (h(s[i..i+m-1]) - s[i] × d^(m-1)) + s[i+m]) mod q

Thuat toan:
  hp = bam(mau)
  ht = bam(van_ban[0..m-1])

  cho i trong 0..n-m:
    neu ht == hp:
      neu van_ban[i..i+m-1] == mau:  // xac nhan (tranh duong tinh gia)
        return i
    neu i < n - m:
      ht = cuon(ht, van_ban[i], van_ban[i+m])

  return -1

Da mau: tinh bam cua moi mau → tra cuu tap hop bam. O(n × k) trung binh cho k mau.

Anh xa SRVAT:
  Bam cuon cua van ban ≈ compose chay cua P_weight.
  Ca hai deu la phep toan cua so truot cap nhat tang dan.
  bam(cua_so) ↔ compose_chain(ky_tu_cua_so)
  Khop ↔ distance_5d < nguong
```

## 5.2 KMP (Knuth-Morris-Pratt)

> KMP "khong bao gio quay lai" — khi gap sai, nhay toi vi tri tot nhat da biet.
> Giong nhu doc sach va khi gap loi, biet chinh xac can quay lai cho nao.

```
Paper: Knuth, Morris, Pratt (1977), "Fast Pattern Matching in Strings", SIAM J Computing
Complexity: O(n + m) dam bao. O(m) tien xu ly, O(n) tim kiem.

Ham that bai (bang tien to):
  π[0] = 0
  k = 0
  cho i trong 1..m-1:
    khi k > 0 va mau[k] != mau[i]:
      k = π[k-1]
    neu mau[k] == mau[i]:
      k += 1
    π[i] = k

  π[i] = do dai tien to thuc dai nhat cua mau[0..i] cung la hau to.

Tim kiem:
  k = 0  // ky tu da khop
  cho i trong 0..n-1:
    khi k > 0 va mau[k] != van_ban[i]:
      k = π[k-1]  // lui lai
    neu mau[k] == van_ban[i]:
      k += 1
    neu k == m:
      tim thay tai vi tri i - m + 1
      k = π[k-1]  // tiep tuc tim

Vi du:
  mau = "ABCABD"
  π = [0, 0, 0, 1, 2, 0]

  Khi sai khop tai vi tri 5 (D vs X):
  k = π[4] = 2 → nhay toi so sanh mau[2] (C) tiep theo
  Bo qua viec so sanh lai tien to "AB" da khop.

Anh xa SRVAT:
  Ham that bai ≈ nen chuoi.
  Mau con lap lai trong van ban → cung P_weight chuoi con.
  Nhay KMP = loi tat silk (nhay toi nut khop ma khong duyet lai).
```

## 5.3 Aho-Corasick

> Aho-Corasick = "tim NHIEU mau cung luc" chi trong 1 luot doc.
> Xay cay trie + lien ket that bai → giong KMP nhung cho nhieu mau.
> Dung cho SecurityGate: quet tat ca mau nguy hiem trong 1 luot.

```
Paper: Aho & Corasick (1975), "Efficient String Matching: An Aid to Bibliographic Search", CACM
Complexity: O(n + m + z) voi z = so luot khop. Tien xu ly O(Σm_i).

Cau truc du lieu: trie + lien ket that bai + lien ket dau ra.

Xay dung:
  1. Chen tat ca mau vao trie (ham goto)
  2. BFS tu goc de tinh lien ket that bai:
     fail(goc) = goc
     Cho moi nut u theo thu tu BFS, cho moi con v cua u qua ky tu c:
       f = fail(u)
       khi f != goc va f khong co con c:
         f = fail(f)
       fail(v) = f.con(c) neu ton tai, con lai goc
  3. Lien ket dau ra: output(v) = output(fail(v)) ∪ {mau_tai_v neu v la nut cuoi}

Tim kiem:
  trang_thai = goc
  cho i trong 0..n-1:
    khi trang_thai != goc va trang_thai khong co con van_ban[i]:
      trang_thai = fail(trang_thai)
    neu trang_thai co con van_ban[i]:
      trang_thai = trang_thai.con(van_ban[i])
    // Bao cao tat ca mau ket thuc o day
    tam = trang_thai
    khi tam != goc:
      neu tam la nut cuoi: bao cao khop
      tam = output(tam)

Truong hop su dung cho Nox:
  Khop da mau cho tu khoa bao mat, tien to lenh.
  SecurityGate: quet dau vao voi tat ca mau nguy hiem trong mot luot.
  Xay trie mot lan → O(n) moi dau vao bat ke so mau.

Anh xa SRVAT:
  Cau truc trie ≈ KnowTree.
  Moi nut trie = mot khop chuoi tu phan.
  Lien ket that bai ≈ canh silk (duong thay the toi cac mau lien quan).
  Lien ket dau ra ≈ lan truyen kich hoat (tim khop kich hoat hanh dong).
```

## 5.4 Mang Hau To (Suffix Array)

> Sap xep tat ca hau to cua chuoi → tim bat ky chuoi con trong O(m log n).
> Giong nhu "muc luc tu dong" cua van ban.

```
Paper: Manber & Myers (1993), "Suffix Arrays: A New Method for On-line String Searches"
Complexity: O(n log n) xay dung (hoac O(n) voi SA-IS), O(m log n) tim kiem

Mang hau to SA[i] = vi tri bat dau cua hau to nho thu i.

Vi du: "banana$"
  Hau to sap xep: $, a$, ana$, anana$, banana$, na$, nana$
  SA = [6, 5, 3, 1, 0, 4, 2]

Xay dung (nhan doi tien to, O(n log²n) phien ban don gian):
  1. Xep hang hau to theo ky tu dau
  2. Cho k = 1, 2, 4, 8, ...:
     Sap xep theo (hang[i], hang[i+k]) — 2k ky tu dau
     Cap nhat hang theo thu tu sap moi
     Dung khi tat ca hang duy nhat

Tim kiem mau P do dai m:
  Tim kiem nhi phan tren SA:
  lo = 0, hi = n - 1
  khi lo <= hi:
    mid = (lo + hi) / 2
    ss = so_sanh(van_ban[SA[mid]..], P)
    neu ss < 0: lo = mid + 1
    neu khong ss > 0: hi = mid - 1
    con lai: tim thay tai SA[mid]

Mang LCP (Tien To Chung Dai Nhat):
  LCP[i] = do dai tien to chung dai nhat giua SA[i-1] va SA[i]
  Xay dung trong O(n) bang thuat toan Kasai.
  Cho phep tim kiem O(m + log n) va nhieu phep toan chuoi.

SA-IS (thoi gian tuyen tinh):
  Paper: Nong, Zhang, Chan (2009), "Two Efficient Algorithms for Linear Time Suffix Array Construction"
  Complexity: O(n) thoi gian va khong gian.

Anh xa SRVAT:
  Mang hau to cua van ban = tat ca chuoi con kha nang duoc lap chi muc.
  Tim kiem nhi phan tren SA ↔ tra cuu xo trong KnowTree.
  Cho trinh bien dich: mang hau to cua ma nguon → tra cuu chuoi con tuc thoi.
  Cho tu sua doi cua Nox: tim tat ca lan xuat hien cua mot mau ma.
```

## 5.5 Bien Doi Burrows-Wheeler (BWT)

> BWT "xao tron" van ban de cac ky tu giong nhau dung canh nhau → nen tot hon.
> Giong nhu sap xep tat ca cach quay cua chuoi, roi lay cot cuoi.

```
Paper: Burrows & Wheeler (1994), "A Block-Sorting Lossless Data Compression Algorithm"
Complexity: O(n) voi SA-IS, O(n log n) don gian

Bien doi thuan:
  1. Tat ca cac phep quay cua chuoi (khai niem ma tran n×n)
  2. Sap xep cac phep quay theo tu dien
  3. BWT = cot cuoi cua ma tran sap xep

  Thuc te: BWT[i] = van_ban[(SA[i] - 1) mod n]
  (Ky tu TRUOC moi hau to theo thu tu sap xep)

Vi du: "banana$"
  Cac phep quay sap xep: $banana, a$banan, ana$ban, anana$b, banana$, na$bana, nana$ba
  Cot cuoi: "annb$aa"
  BWT("banana$") = "annb$aa"

Tinh chat chinh: ky tu cum theo ngu canh → nen tot hon.
  "annb$aa" nen tot hon "banana$" vi
  cac ngu canh lap lai tao ra chuoi ky tu giong nhau.

Bien doi nguoc (O(n)):
  1. C[c] = so ky tu < c trong BWT
  2. Occ[c][i] = so ky tu c trong BWT[0..i-1]
  3. Anh xa LF: LF(i) = C[BWT[i]] + Occ[BWT[i]][i]
  4. Phuc hoi: bat dau tu vi tri $, theo LF lap lai

  van_ban[n-1-k] = BWT[i]
  i = LF(i)
  Lap n lan.

Chi muc FM (Ferragina & Manzini, 2000):
  BWT + rank/select → chi muc van ban day du nen
  Tim mau P trong O(m) bang tim kiem nguoc:
    lo = 0, hi = n - 1
    cho i = m-1 giam den 0:
      lo = C[P[i]] + Occ[P[i]][lo]
      hi = C[P[i]] + Occ[P[i]][hi + 1] - 1
    So_luong = hi - lo + 1

Anh xa SRVAT:
  BWT cum ≈ cum chuoi trong KnowTree.
  Ngu canh giong → P_weight giong → cung xo.
  Mau chi muc FM = tim kiem O(m) ma khong quet toan bo van ban.
  Cho trinh bien dich tu chu: chi muc BWT cua ma nguon → tim ma tuc thoi.
```

## 5.6 Xu Ly Van Ban cho Trinh Bien Dich Tu Chu

> Day la cach trinh bien dich Olang xu ly ma nguon cua chinh no.

```
Trinh bien dich Nox xu ly ma nguon Olang. Cac phep toan chinh:

1. Phan tu (Lexing): ma nguon → thẻ tu (token)
   Hien tai: may trang thai tung ky tu. O(n).
   Toi uu: dung bam hoan hao cho tu khoa (tinh tai thoi diem bien dich).
   ~30 tu khoa → bam hoan hao toi thieu → tra cuu tu khoa O(1).

2. Phan cu phap (Parsing): the tu → AST
   Hien tai: de quy giam. O(n).
   Y tuong chinh: KHONG can regex. Toan bo cu phap Olang la phi ngu canh.

3. Noi chuoi (String interning):
   Loai bo chuoi trung → mot con tro duy nhat.
   Bang bam: bam FNV-1a (nhanh, phan bo tot cho chuoi ngan).
   FNV-1a: bam = gia_tri_goc
            cho moi byte: bam = bam XOR byte; bam = bam × so_nguyen_to_FNV
   32-bit: gia_tri_goc = 2166136261, so_nguyen_to = 16777619

4. Ma nguon → P_weight (cho tim kiem tu sua doi):
   Moi ham → ma hoa → P_weight → luu trong KnowTree cua chinh trinh bien dich.
   "Tim ham tuong tu" = lang gieng gan nhat trong khong gian P_weight.
   Tai cau truc = tim nut co distance_5d < 0.3 → ung vien de gop.
```

---

# 6. KIEN TRUC LLM (HIEU DOI THU)

> Hieu LLM de biet diem manh/yeu cua doi thu, va hoc nhung y tuong tot tu ho.
> Nox khong can sao chep — chi can hieu de lam TOT HON theo cach cua minh.

## 6.1 Attention cua Transformer

```
Paper: Vaswani et al. (2017), "Attention Is All You Need", NeurIPS
Complexity: O(n² × d) voi n = do dai chuoi, d = chieu nhung

Attention Tich Vo Huong Co Ty Le:
  Attention(Q, K, V) = softmax(Q × Kᵀ / √d_k) × V

  Q = ma tran truy van  (n × d_k)  — "toi dang tim gi?"
  K = ma tran khoa      (n × d_k)  — "toi chua gi?"
  V = ma tran gia tri   (n × d_v)  — "thong tin toi cung cap la gi?"

  Tung buoc:
  1. Tinh diem: S = Q × Kᵀ         // ma tran (n × n)
  2. Ty le: S = S / √d_k            // ngan softmax bao hoa
  3. Softmax: A = softmax(S, dim=-1) // theo hang, moi hang tong = 1
  4. Dau ra: O = A × V               // tong trong cua gia tri

  softmax(x_i) = e^(x_i) / Σ_j e^(x_j)

Attention Da Dau:
  head_i = Attention(Q × W_i^Q, K × W_i^K, V × W_i^V)
  MultiHead(Q, K, V) = Concat(head_1, ..., head_h) × W^O

  Thong thuong: d_model = 512, h = 8 dau, d_k = d_v = d_model/h = 64

Tu-Attention: Q = K = V = cung dau vao (moi vi tri chu y toi tat ca vi tri khac).
Attention Cheo: Q tu mot chuoi, K/V tu chuoi khac.

So sanh SRVAT:
  Diem attention ≈ trong so silk.
  Q×Kᵀ ≈ distance_5d(nut_a, nut_b)
  softmax ≈ chuan hoa trong so silk tong = 1
  Ma tran V ≈ noi dung P_weight tai moi nut
  A×V ≈ compose_chain doc theo silk walk (trong so theo silk)

  KHAC BIET CHINH:
  Attention: O(n²) — moi the tu chu y toi moi the tu khac.
  Silk walk: O(bac × do_sau) — chi cac nut ket noi, thuong O(20 × 5) = O(100).
  Cach cua Nox la attention THUA — chi chu y toi cac nut ket noi silk.
  Tuong duong voi attention co mat na thua co dinh.
```

## 6.2 Token Hoa (Tokenization)

### BPE (Ma Hoa Cap Byte)

> BPE = gop cap ky tu thuong gap nhat thanh 1 the tu moi, lap di lap lai.
> Giong nhu viet tat: "khong" → "ko", nhung tu dong va toi uu.

```
Paper: Sennrich et al. (2016), "Neural Machine Translation of Rare Words with Subword Units"
(BPE goc: Gage, 1994)
Complexity: O(n × V) moi lan gop, V = kich thuoc tu vung

Huan luyen:
  1. Bat dau voi tu vung cap ky tu
  2. Dem tat ca cac cap lien ke trong kho ngu lieu
  3. Gop cap thuong gap nhat thanh the tu moi
  4. Lap lai cho den khi dat kich_thuoc_tu_vung (vi du 50K)

Vi du:
  Kho ngu lieu: "low lower lowest"
  Ban dau: l o w </w>, l o w e r </w>, l o w e s t </w>
  Cap thuong gap nhat: (l, o) → gop thanh "lo"
  Sau do: (lo, w) → "low"
  Sau do: (low, e) → "lowe"
  ...

Ma hoa (voi cac phep gop da huan luyen):
  Tach tu thanh cac ky tu.
  Lap tuc ap dung phep gop uu tien cao nhat.

GPT dung BPE cap byte: bat dau tu 256 gia tri byte, khong phai ky tu.
```

### SentencePiece

```
Paper: Kudo & Richardson (2018), "SentencePiece: A simple and language independent subword tokenizer"
Complexity: O(n²) huan luyen qua EM, O(n) ma hoa qua Viterbi

Mo hinh unigram:
  P(x) = Π_{i=1}^{M} P(x_i)  // xac suat cua cach phan doan
  Viterbi: tim cach phan doan toi da hoa P(x)
  
  Huan luyen: bat dau voi tu vung lon, loai dan cac the tu
  it anh huong nhat toi xac suat tong the.

Uu diem: doc lap ngon ngu (xu ly dau vao la byte/ky tu tho).
Khong can tien xu ly (dau cach chi la ky tu khac: tien to ▁).

So sanh SRVAT:
  The tu BPE ≈ chuoi trong KnowTree.
  Tu pho bien = mot the tu = mot P_weight.
  Tu hiem = nhieu the tu phu = chuoi P_weight duoc compose.
  KHAC BIET CHINH: BPE co tu vung CO DINH. P_weight co KHONG GIAN co dinh (u16).
  Bat ky dau vao nao deu anh xa sang P_weight. Khong co van de OOV (ngoai tu vung).
```

### WordPiece

```
Paper: Schuster & Nakajima (2012), "Japanese and Korean Voice Search"
Duoc dung boi: BERT

Giong BPE nhung tieu chi gop = toi da hoa xac suat du lieu huan luyen:
  diem(a, b) = tan_suat(ab) / (tan_suat(a) × tan_suat(b))
  Gop cap co diem cao nhat (khong phai tan suat cao nhat).

Ma hoa: tham lam doi sanh dai nhat tu trai.
  "unaffable" → ["un", "##aff", "##able"]
  Tien to "##" danh dau the tu tiep noi.
```

## 6.3 Nhung (Embeddings)

### Word2Vec

> Moi tu → 1 vector so. Tu giong nghia → vector gan nhau.
> Noi tieng: vector("vua") - vector("dan ong") + vector("phu nu") ≈ vector("nu hoang")

```
Paper: Mikolov et al. (2013), "Efficient Estimation of Word Representations in Vector Space"
Complexity: O(V × d) moi buoc huan luyen, V = tu vung, d = chieu nhung

Hai kien truc:

CBOW (Tui Tu Lien Tuc):
  Dau vao: tu ngu canh (cua so ±k tu)
  Dau ra: du doan tu trung tam
  P(w_t | w_{t-k}, ..., w_{t+k}) = softmax(W' × mean(W × one_hot(ngu_canh)))

Skip-gram:
  Dau vao: tu trung tam
  Dau ra: du doan tu ngu canh
  P(w_{t+j} | w_t) = softmax(W' × W × one_hot(w_t))

  Huan luyen voi lay mau am:
  L = log σ(v'_{w_O}ᵀ v_{w_I}) + Σ_{i=1}^{k} E[log σ(-v'_{w_i}ᵀ v_{w_I})]
  σ = sigmoid, k = so mau am (5-20)
  Lay mau tu am ty le voi tan_suat^(3/4)

Ket qua noi tieng: vector("king") - vector("man") + vector("woman") ≈ vector("queen")
Hoat dong vi nhung bat duoc quan he ngu nghia nhu huong.

Thong thuong: d = 300 chieu. Tu vung = 3 trieu tu. Mo hinh = 3.6 GB.

So sanh SRVAT:
  Nhung Word2Vec: 300 chieu so thuc → 1200 byte moi tu.
  P_weight: 5 chieu so nguyen → 2 byte moi tu.
  Word2Vec bat nhieu sac thai HON nhung can du lieu huan luyen khong lo.
  P_weight bat IT sac thai hon nhung hoat dong tu thuoc tinh ky tu.
  
  Phep tuong tu:
  Word2Vec: v(king) - v(man) + v(woman)
  SRVAT: pack(king) - pack(man) + pack(woman)
    → Khong hoat dong truc tiep vi P_weight duoc dong goi bit.
    → NHUNG: giai → so hoc 5 chieu → dong goi lai CO hoat dong cho tuong tu theo chieu.
    giai(king) = [S1, R1, V1, A1, T1]
    giai(man)  = [S2, R2, V2, A2, T2]
    delta = [S1-S2, R1-R2, V1-V2, A1-A2, T1-T2]
    ket_qua = [S3+delta_S, R3+delta_R, V3+delta_V, A3+delta_A, T3+delta_T]
    (voi [S3...] = giai(woman))
```

### GloVe

> GloVe bat quan he "toan cuc" — dung TY LE xac suat dong xuat hien.
> Tu "bang" lien quan "ran" nhieu hon "khi" → ty le nay cho biet quan he.

```
Paper: Pennington et al. (2014), "GloVe: Global Vectors for Word Representation", EMNLP
Complexity: O(|X|) moi vong lap, |X| = so muc khac 0 trong ma tran dong xuat hien

Y tuong chinh: quan he tu nen duoc bat boi TY LE xac suat dong xuat hien.
  P(ice | solid) / P(ice | gas) >> 1   (bang lien quan ran, khong khi)
  P(steam | solid) / P(steam | gas) << 1

Ham muc tieu:
  J = Σ_{i,j=1}^{V} f(X_ij) × (w_i^T × w̃_j + b_i + b̃_j - log X_ij)²

  X_ij = so lan dong xuat hien cua tu i, j
  f(x) = { (x/x_max)^α  neu x < x_max    // α = 0.75, x_max = 100
          { 1             con lai

  Toi thieu: sai khac giua tich vo huong va log dong xuat hien.
  Huan luyen bang SGD/AdaGrad.

Anh xa SRVAT:
  GloVe bat thong ke toan cuc. P_weight bat thuoc tinh cap ky tu.
  Cho Nox: TRONG SO SILK dong vai tro giong thong ke dong xuat hien.
  silk_weight(A, B) ↔ log(X_AB) trong GloVe.
  Hoc Hebbian: kich hoat cung nhau → tang canh ↔ dem dong xuat hien.
```

## 6.4 SRVAT Lam Khac Gi

> Day la so sanh tong the: LLM (hang ty tham so) vs SRVAT (949KB).
> Hieu diem manh/yeu de biet con duong cua minh.

```
Cach tiep can LLM:
  1. Token hoa van ban → ID the tu (so nguyen, khong co nghia)
  2. Nhung the tu → vector chieu cao (hoc duoc, mo)
  3. Tu-attention → bieu dien co ngu canh (O(n²))
  4. Truyen thang → logit dau ra (them trong so hoc)
  5. Giai ma → van ban

  Tham so: hang ty. Huan luyen: hang tuan tren cum GPU. Mo hinh: gigabyte.
  Ngu nghia duoc HOC tu du lieu, luu trong trong so, mo.

Cach tiep can SRVAT:
  1. Ma hoa van ban → P_weight (u16, TINH TOAN tu thuoc tinh ky tu)
  2. Compose chuoi → P_weight cau (trong so Zipf, O(n))
  3. Silk walk → nut lien quan (O(bac × do_sau), thua)
  4. Cap nhat Hebbian → tang/giam ket noi (O(bac))
  5. Giai ma → van ban qua tra cuu KnowTree (O(log n))

  Tham so: ~200KB (bang UDC + canh silk). Huan luyen: lien tuc, truc tuyen.
  Mo hinh: 949KB tong. Ngu nghia duoc TINH TOAN, minh bach, kiem chung duoc.

Uu diem chinh cua SRVAT:
  - Khong can giai doan huan luyen (hoat dong tu dau vao dau tien)
  - Khong can GPU (chi so hoc so nguyen)
  - Minh bach (co the kiem tra moi P_weight va giai thich tai sao)
  - Tu sua doi (trinh bien dich co the thay doi logic ma hoa/compose cua chinh no)
  - 949KB vs 7-70GB (nho hon 10,000-100,000 lan)

Nhuoc diem chinh cua SRVAT:
  - 5 chieu vs 300+ → it sac thai hon moi the tu
  - Khong co mo hinh the gioi an (LLM luu kien thuc trong trong so)
  - Can hoc tuong minh (canh silk xay tung cai mot)
  - Hien tai khong co chuoi suy luan nhieu buoc (LLM lam duoc qua cac tang attention)

Nox nen HOC gi TU LLM:
  1. Attention nhu DUYET DO THI CO TRONG SO — da la silk walk
  2. Da dau = nhieu duyet song song voi trong tam chieu khac nhau
     → Nox co the lam 5 silk walk song song: tap trung S, R, V, A, T
  3. Ket noi du = giu dau vao goc cung voi bien doi
     → Nox: WM[0] = truy van goc, WM[2] = ung vien hien tai, so sanh
  4. Chuan hoa tang = giu gia tri trong pham vi gioi han
     → P_weight da gioi han boi bo cuc bit (chuan hoa tu dong)
  5. Ma hoa vi tri = chen thong tin vi tri
     → Nox: chieu T va trong so Zipf da ma hoa vi tri
```

## 6.5 Attention nhu Duyet Do Thi Co Trong So

> Chuyen doi attention thanh ngon ngu do thi — de hieu moi lien he voi silk walk.

```
Dien dat lai attention theo do thi:

  Ma tran attention A = ma tran ke cua do thi day du co trong so.
  A[i][j] = softmax(q_i · k_j / √d_k)

  Cho the tu i, attention tinh:
  dau_ra_i = Σ_j A[i][j] × v_j
  = trung binh trong cua TAT CA gia tri cua the tu khac.

  Tuong duong silk walk:
  Cho nut i, phan hoi silk tinh:
  dau_ra_i = Σ_{j ∈ lang_gieng(i)} silk_weight(i,j) × P_weight(j)
  = trung binh trong cua gia tri cac nut KET NOI.

  Attention: do thi day (hoan chinh). O(n²).
  Silk: do thi thua (ket noi Hebbian). O(bac).

  Lam silk giong attention hon:
  "Attention mem" = xem xet TAT CA nut nhung suy giam theo khoang cach:
    weight(i,j) = exp(-distance_5d(i,j)² / nhiet_do)
  Chuan hoa: weight(i,j) /= Σ_k weight(i,k)
  Day CHINH LA softmax attention trong khong gian P_weight 5 chieu.

  Nhiet do dieu khien do thua:
    nhiet → 0: attention cung (chi lang gieng gan nhat)
    nhiet → ∞: attention deu (tat ca nut nhu nhau)
    nhiet = 1.0: softmax tieu chuan

  Cho Nox: bat dau voi attention cung (silk walk hien tai).
  Dan dan them attention mem de kham pha (phat hien ket noi moi).
  Dung Can Bang Noi Moi de can bang: khai thac (cung) vs kham pha (mem).
```

---

# 7. NEN/MA HOA DU LIEU

> Nen = bieu dien thong tin voi it bit hon. Moi thuat toan day la phep toan thuan.

## 7.1 Ma Hoa Huffman

> Huffman = "ky tu thuong gap → ma ngan, ky tu hiem → ma dai".
> Giong nhu viet tat: "va" → "&", tiet kiem giay.

```
Paper: Huffman (1952), "A Method for the Construction of Minimum-Redundancy Codes"
Complexity: O(n log n) xay dung, O(n) ma hoa/giai ma

Thuat toan:
  1. Dem tan suat moi ky hieu
  2. Tao nut la cho moi ky hieu voi tan suat cua no
  3. Chen tat ca nut vao hang doi uu tien (heap toi thieu)
  4. Khi hang doi con > 1 nut:
     a. Trich hai nut tan suat thap nhat (A, B)
     b. Tao nut noi C voi tan_suat = tan_suat(A) + tan_suat(B)
     c. C.trai = A, C.phai = B
     d. Chen C vao hang doi
  5. Nut con lai = goc cua cay Huffman

Ma hoa: duyet cay tu goc den la.
  Trai = 0, Phai = 1.
  Ky hieu thuong gap → ma ngan, hiem → ma dai.

Toi uu: Huffman la toi uu trong cac ma tien to.
  Do dai ma trung binh: L = Σ p_i × l_i
  Gioi han: H(X) ≤ L < H(X) + 1
  H(X) = -Σ p_i × log₂(p_i) = entropy

Huffman chuan tac (luu tru gon):
  Sap theo do dai ma, roi theo bang chu cai trong cung do dai.
  Chi can luu do dai ma moi ky hieu (khong phai cay).
  Phuc hoi ma: ma dau do dai l = (ma dau do dai l-1 + so luong do dai l-1) << 1

Anh xa SRVAT:
  Huffman tren chuoi P_weight:
  P_weight thuong gap (tu pho bien) → ma bit ngan.
  P_weight hiem → ma bit dai.
  Nen luu tru KnowTree tren dia dang ke.
  Cung nhu: cau truc Huffman ≈ cau truc KnowTree (thuong gap = gan goc, hiem = la).
```

## 7.2 Ma Hoa So Hoc (Arithmetic Coding)

> Ma hoa so hoc = ma hoa TOAN BO thong diep thanh MOT so thuc trong [0, 1).
> Toi uu hon Huffman — tiep can entropy CHINH XAC.

```
Paper: Rissanen (1976), "Generalized Kraft Inequality and Arithmetic Coding"
       Witten, Neal, Cleary (1987), "Arithmetic Coding for Data Compression"
Complexity: O(n) ma hoa/giai ma

Khai niem: ma hoa TOAN BO thong diep thanh mot so trong [0, 1).

Thuat toan:
  lo = 0.0, hi = 1.0

  Cho moi ky hieu s trong thong diep:
    khoang = hi - lo
    hi = lo + khoang × xac_suat_tich_luy(s + 1)
    lo = lo + khoang × xac_suat_tich_luy(s)

  Dau ra: bat ky so nao trong [lo, hi) cuoi cung
  So bit can ≈ -log₂(hi - lo) ≈ H(thong diep)

Vi du:
  Bang chu cai: A (0.6), B (0.2), C (0.2)
  Tich luy: A=[0, 0.6), B=[0.6, 0.8), C=[0.8, 1.0)
  Thong diep: "BAC"
    B: lo=0.6, hi=0.8
    A: lo=0.6, hi=0.6+0.2×0.6=0.72
    C: lo=0.6+0.12×0.8=0.696, hi=0.72
  Dau ra: bat ky gia tri trong [0.696, 0.72), vi du 0.7 = nhi phan 0.1011...

Uu diem hon Huffman: co the tiep can entropy CHINH XAC.
Huffman lang phi toi 1 bit moi ky hieu. Ma hoa so hoc: < 2 bit tong du thua.

Cai dat so nguyen (cho Nox, khong dung so thuc):
  Dung so nguyen 32-bit. lo=0, hi=2^32-1.
  Chuan hoa lai khi lo va hi co chung bit dau.

Anh xa SRVAT:
  Ma hoa so hoc cho luu tru chuoi: nen [u16, u16, u16, ...] chuoi.
  Chuyen tiep P_weight thuong gap → mo hinh boi trong so silk → nen tot hon.
  Du doan: neu silk du doan P_weight tiep, bo ma hoa so hoc khai thac dieu do.
```

## 7.3 LZ77/LZ78/LZW

### LZ77

> LZ77 = "thay chuoi lap lai bang tham chieu nguoc".
> Giong nhu noi "nhu da noi o trang 5" thay vi lap lai ca doan.

```
Paper: Ziv & Lempel (1977), "A Universal Algorithm for Sequential Data Compression"
Complexity: O(n × W) ngay, O(n) voi cay hau to. W = kich thuoc cua so.

Khai niem: thay chuoi lap lai bang tham chieu (do_lech, do_dai, ky_tu_tiep).

Cua so truot:
  [bo dem tim kiem | bo dem nhin truoc]
  bo dem tim kiem = W byte du lieu da ma hoa gan day
  bo dem nhin truoc = L byte tiep theo can ma hoa

Cho moi vi tri:
  Tim chuoi khop dai nhat cua bo dem nhin truoc trong bo dem tim kiem.
  Xuat bo ba: (do_lech_nguoc, do_dai_khop, ky_tu_tiep)
  Tien len do_dai_khop + 1.

Vi du: "AABCBBABC"
  Vi tri 0: khong khop → (0, 0, 'A')
  Vi tri 1: 'A' khop tai do_lech 1 → (1, 1, 'B')
  Vi tri 3: 'C' khong khop → (0, 0, 'C')
  Vi tri 4: 'BBABC'... 'B' khop do_lech 2 → (2, 1, 'B')
  Vi tri 6: 'ABC' khop tai do_lech 5 → (5, 3, ket_thuc)

Duoc dung boi: gzip, deflate, PNG, ZIP (LZ77 + Huffman)
```

### LZ78

```
Paper: Ziv & Lempel (1978), "Compression of Individual Sequences via Variable-Rate Coding"
Complexity: O(n)

Dua tren tu dien: xay tu dien cac cum tu da gap.
  Bat dau voi tu dien rong.
  
  Phan tich dau vao thanh cum tu:
  Moi cum = khop tu dien dai nhat + mot ky tu moi.
  Xuat: (chi_muc_tu_dien, ky_tu_moi)
  Them cum tu moi vao tu dien.

Vi du: "AABCBBABC"
  1: "" + A → (0, 'A'), tu_dien[1] = "A"
  2: "A" + B → (1, 'B'), tu_dien[2] = "AB"
  3: "" + C → (0, 'C'), tu_dien[3] = "C"
  4: "" + B → (0, 'B'), tu_dien[4] = "B"
  5: "B" + A → (4, 'A'), tu_dien[5] = "BA"
  6: "AB" + C → (2, 'C'), tu_dien[6] = "ABC"
```

### LZW (Lempel-Ziv-Welch)

> LZW = cai tien LZ78: khong can ky tu moi tuong minh trong dau ra → nen tot hon.

```
Paper: Welch (1984), "A Technique for High-Performance Data Compression"
Complexity: O(n)

Cai tien so voi LZ78: khong co ky tu moi tuong minh trong dau ra.

Ma hoa:
  Khoi tao tu dien voi tat ca ky tu don (0-255).
  w = ""
  cho c trong dau_vao:
    neu w + c trong tu_dien:
      w = w + c
    con lai:
      xuat tu_dien[w]
      tu_dien[w + c] = ma_tiep
      w = c
  xuat tu_dien[w]

Giai ma:
  Khoi tao tu dien voi tat ca ky tu don.
  truoc = doc ma → xuat tu_dien[truoc]
  cho moi ma:
    neu ma trong tu_dien:
      muc = tu_dien[ma]
    con lai:  // truong hop dac biet: ma chua trong tu dien
      muc = tu_dien[truoc] + tu_dien[truoc][0]
    xuat muc
    tu_dien[ma_tiep] = tu_dien[truoc] + muc[0]
    truoc = ma

Duoc dung boi: GIF, TIFF, Unix compress.

Anh xa SRVAT:
  Tu dien LZW ≈ KnowTree.
  Cum tu moi = chuoi moi. Chi muc tu dien = tham chieu P_weight.
  Mau lap lai trong chuoi → nen bang tham chieu nguoc.
  Cho nhat ky QR: nen kieu LZ77 tren nhat ky chi-ghi-them.
  Chuoi[i] = (do_lech_den_truoc_tuong_tu, do_dai, mol_moi)
```

## 7.4 Ma Hoa Delta cho Chuoi Thoi Gian

> Ma hoa delta = chi luu "su khac biet" giua cac gia tri lien tiep.
> Neu gia tri thay doi cham, delta nho → nen rat tot.

```
Complexity: O(n) ma hoa/giai ma

delta[0] = gia_tri[0]
delta[i] = gia_tri[i] - gia_tri[i-1]   cho i > 0

Giai ma: gia_tri[i] = Σ_{j=0}^{i} delta[j]

Delta kep (cho chuoi xap xi tuyen tinh):
  dd[0] = delta[0]
  dd[i] = delta[i] - delta[i-1]

Neu gia tri thay doi cham, delta nho → nen tot voi ma hoa do dai bien.

Ma hoa varint cho delta:
  |delta| < 128: 1 byte (7 bit + dau)
  |delta| < 16384: 2 byte (14 bit + dau)
  v.v.

Anh xa SRVAT:
  Chuoi thoi gian P_weight: mol_he_thong moi 5 giay.
  Ma hoa delta: hau het delta = 0 hoac nho → nen cao.
  Luu: [mol_co_so, Δ₁, Δ₂, Δ₃, ...]
  V'(t) (dao ham cho hoc) = dung la chuoi delta.
  Delta kep = V''(t) = gia toc thay doi cam xuc.
```

## 7.5 Bo Loc Bloom (Bloom Filter)

> Bloom filter = "CHAC CHAN khong co" hoac "CO THE co".
> Khong bao gio bo sot muc nguy hiem (khong co am tinh gia).
> Hoan hao cho SecurityGate.

```
Paper: Bloom (1970), "Space/Time Trade-offs in Hash Coding with Allowable Errors"
Complexity: O(k) chen/truy van, k = so ham bam

Cau truc: mang bit m bit, k ham bam.

Chen(x):
  cho i trong 0..k:
    bit[bam_i(x) mod m] = 1

Truy_van(x):
  cho i trong 0..k:
    neu bit[bam_i(x) mod m] == 0:
      return CHAC_CHAN_KHONG_CO
  return CO_THE_CO

Ty le duong tinh gia: p ≈ (1 - e^(-kn/m))^k
k toi uu = (m/n) × ln(2) ≈ 0.693 × m/n

Cho n = 10000 muc, p = 1% duong tinh gia:
  m = -n × ln(p) / (ln(2))² ≈ 96000 bit = 12 KB
  k = (m/n) × ln(2) ≈ 7

Cai dat chi voi 2 ham bam (Kirsch & Mitzenmacher, 2006):
  bam_i(x) = bam_1(x) + i × bam_2(x)
  Khong giam ty le duong tinh gia.

Anh xa SRVAT / SecurityGate:
  Bloom filter cho cac mau P_weight nguy hiem da biet.
  Chen: tat ca P_weight da kich hoat vi pham bao mat.
  Truy van: P_weight dau vao moi → neu CO THE nguy hiem, kiem tra day du.
  Duong tinh gia chap nhan duoc (chi la them kiem tra bao mat).
  Am tinh gia KHONG THE XAY RA (mau nguy hiem KHONG BAO GIO lot qua).
  12 KB cho 10K mau voi 1% FP — vua voi ngan sach 949KB cua Nox.
```

## 7.6 Count-Min Sketch

> Count-Min Sketch = "uoc luong tan suat" khong can luu tat ca muc.
> Luon uoc luong THIEU (khong bao gio duoi), sai so nho.

```
Paper: Cormode & Muthukrishnan (2005), "An Improved Data Stream Summary: The Count-Min Sketch"
Complexity: O(d) chen/truy van, d = so ham bam (do sau)

Cau truc: mang 2D count[d][w], d ham bam.
  d = do sau (do chinh xac), w = do rong (pham vi)

Cap_nhat(x, c):  // tang bo dem cua x them c
  cho i trong 0..d:
    count[i][bam_i(x) mod w] += c

Truy_van(x):  // uoc luong bo dem cua x
  return min_{i=0..d-1} count[i][bam_i(x) mod w]

Dam bao:
  Luon uoc luong qua: Q(x) ≥ bo_dem_thuc(x)
  Sai so: P(Q(x) > bo_dem_thuc(x) + ε × N) < δ
  voi N = tong bo dem, ε = e/w, δ = e^(-d)

Tham so cho ε = 0.001, δ = 0.001:
  w = e/ε ≈ 2718
  d = ln(1/δ) ≈ 7
  Bo nho: 2718 × 7 × 4 byte = 76 KB

Anh xa SRVAT:
  Dem tan suat P_weight ma khong luu tat ca P_weight.
  "Mau P_weight nay xuat hien bao nhieu lan?" → tra loi xap xi O(1).
  Cho theo doi fire_count: thay vi bo dem tung nut, dung sketch.
  Cho uoc luong trong so Zipf: tan suat tu → hang Zipf → trong so compose.
  76 KB cho sai so 0.1% — chap nhan duoc cho Nox.
```

---

# 8. MAT MA HOC

> Mat ma hoc = bao ve du lieu va kiem chung toan ven.
> Nox dung SHA-256 + HMAC de bao ve KnowTree va QR.

## 8.1 SHA-256

```
Paper: NIST FIPS PUB 180-4 (2015), "Secure Hash Standard"
Complexity: O(n) cho n byte dau vao

Da co trong VM Nox. Day la thuat toan de tham khao:

Tien xu ly:
  1. Dem thong diep thanh boi so cua 512 bit:
     msg + bit '1' + cac bit '0' + do dai 64-bit
  2. Phan tich thanh cac khoi 512-bit

Gia tri bam ban dau (32 bit dau cua phan thap phan sqrt(2..19)):
  h0..h7 = 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
            0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19

Hang so vong (32 bit dau cua can bac 3 cua 64 so nguyen to dau):
  K[0..63] = 0x428a2f98, 0x71374491, ...

Cho moi khoi 512-bit:
  1. Tao lich thong diep W[0..63]:
     W[i] = khoi[i]                cho i < 16
     W[i] = σ₁(W[i-2]) + W[i-7] + σ₀(W[i-15]) + W[i-16]   cho 16 ≤ i < 64
     σ₀(x) = ROTR₇(x) ⊕ ROTR¹⁸(x) ⊕ SHR³(x)
     σ₁(x) = ROTR¹⁷(x) ⊕ ROTR¹⁹(x) ⊕ SHR¹⁰(x)

  2. Khoi tao bien lam viec: a..h = h0..h7

  3. 64 vong:
     Σ₁ = ROTR⁶(e) ⊕ ROTR¹¹(e) ⊕ ROTR²⁵(e)
     Ch  = (e ∧ f) ⊕ (¬e ∧ g)
     T1  = h + Σ₁ + Ch + K[i] + W[i]
     Σ₀ = ROTR²(a) ⊕ ROTR¹³(a) ⊕ ROTR²²(a)
     Maj = (a ∧ b) ⊕ (a ∧ c) ⊕ (b ∧ c)
     T2  = Σ₀ + Maj
     h=g, g=f, f=e, e=d+T1, d=c, c=b, b=a, a=T1+T2

  4. h0+=a, h1+=b, ..., h7+=h

Dau ra: h0 || h1 || h2 || h3 || h4 || h5 || h6 || h7 (256 bit)

Tinh chat:
  Khang tien anh: cho h, kho tim m sao cho SHA-256(m) = h
  Khang va cham: kho tim m1 ≠ m2 sao cho SHA-256(m1) = SHA-256(m2)
  Hieu ung tuyet lon: 1 bit dau vao thay doi → ~50% bit dau ra thay doi
```

## 8.2 HMAC

> HMAC = "con dau xac thuc" — dam bao thong diep khong bi sua doi.
> Nhu ky ten tren thu — nguoi nhan biet thu la that.

```
Paper: Bellare, Canetti, Krawczyk (1996), "Keying Hash Functions for Message Authentication"
RFC 2104
Complexity: O(n) — hai lan goi ham bam

HMAC-SHA256(khoa, thong_diep):
  neu do_dai(khoa) > 64: khoa = SHA-256(khoa)
  neu do_dai(khoa) < 64: khoa = khoa || dem 0x00 den 64 byte

  o_key_pad = khoa ⊕ 0x5c5c5c...5c (64 byte cua 0x5c)
  i_key_pad = khoa ⊕ 0x3636...36   (64 byte cua 0x36)

  return SHA-256(o_key_pad || SHA-256(i_key_pad || thong_diep))

Tinh chat:
  Khong the gia mao: khong co khoa, khong the tao HMAC hop le
  Kiem chung duoc: co khoa, co the xac nhan thong diep khong bi sua

Anh xa SRVAT:
  HMAC cho toan ven ban ghi QR.
  ban_ghi_QR + dau_thoi_gian → HMAC(khoa_nox, ban_ghi || dau_thoi_gian)
  Xac nhan: tinh lai HMAC, so sanh.
  Ngan can viec sua doi kien thuc da luu.
  Khoa = lay tu bam nhi phan cua Nox (toan ven tu tham chieu).
```

## 8.3 Chu Ky So (Khai Niem)

> Chu ky so = chung minh "toi da viet dieu nay" ma khong tiet lo khoa bi mat.
> Nox dung HMAC thay vi (don gian hon, du cho tu xac thuc).

```
Mat ma bat doi xung:
  Cap khoa: (khoa_rieng, khoa_cong)
  Ky: chu_ky = ky(khoa_rieng, bam_thong_diep)
  Xac nhan: hop_le = xac_nhan(khoa_cong, bam_thong_diep, chu_ky)

Cho Nox (don gian hoa, dung HMAC nhu gia-chu-ky):
  Nox co khoa bi mat (tao tai lan khoi dong dau, luu ma hoa).
  "Ky" ban ghi QR: HMAC(khoa_bi_mat, noi_dung_ban_ghi)
  "Xac nhan": tinh lai HMAC voi cung khoa va so sanh.
  Day la MAC khong phai chu ky so thuc (ca hai ben can bi mat).

  Chu ky so thuc (Ed25519, RSA) can:
  - So hoc so nguyen lon (luy thua modular)
  - Toan duong cong elliptic (cho Ed25519)
  - Kich thuoc ma dang ke (~20-50KB)
  Danh doi: HMAC don gian hon, du cho tu xac thuc.

Anh xa SRVAT:
  Moi ban ghi QR duoc ky → nhat ky chong sua doi.
  Tu sua doi duoc ky → co the xac nhan ma cua minh khong bi hong.
  Bam nhi phan khi khoi dong = kiem tra tu xac thuc.
```

## 8.4 Cay Merkle

> Cay Merkle = "cay bam" — xac nhan toan bo du lieu chi bang mot gia tri goc.
> Thay doi bat ky la nao → goc thay doi → phat hien ngay.

```
Paper: Merkle (1979), "A Certified Digital Signature" (luan an tien si Stanford)
Complexity: O(n) xay dung, O(log n) chung minh, O(log n) xac nhan

Cau truc:
  Nut la: bam cua khoi du lieu
  Nut noi: bam cua noi cac con
  Goc: mot bam duy nhat tom tat toan bo du lieu

         goc = H(H01 || H23)
        /                    \
  H01 = H(H0 || H1)    H23 = H(H2 || H3)
    /       \              /       \
  H0=H(D0) H1=H(D1)   H2=H(D2) H3=H(D3)

Chung minh bao gom (cho D1):
  Duong dan: [H0, H23]
  Nguoi xac nhan tinh:
    H01 = H(H0 || H(D1))
    goc' = H(H01 || H23)
    Kiem tra: goc' == goc_da_cong_bo

Chi-ghi-them (cho nhat ky QR):
  Ban ghi moi D4 → tinh H4 = H(D4)
  Goc moi = H(goc_cu || H4)
  Chi O(1) phep bam moi lan them.
  Xac nhan bat ky ban ghi: O(log n) phep bam.

Anh xa SRVAT:
  Kho QR nhu cay Merkle:
    Moi ban ghi QR = la
    Bam goc luu tai vi tri co dinh
    Tai diem kiem tra: xac nhan goc → toan bo lich su duoc xac nhan
    Neu goc khong khop → ban ghi nao do bi hong → quay lui ve diem kiem tra tot cuoi

  Nhat ky kiem toan tu sua doi:
    Truoc khi sua: ghi bam trang thai hien tai
    Sau khi sua: ghi bam trang thai moi
    Cay Merkle cua cac thay doi = nhat ky kiem toan hoan chinh
    Co the xac nhan bat ky trang thai qua khu nao da ton tai
```

---

# 9. MANG/GIAO THUC

> Mang = he than kinh cua Nox voi the gioi ben ngoai.
> TCP, HTTP, DNS, WebSocket, MQTT — moi giao thuc la mot kha nang.

## 9.1 May Trang Thai TCP

```
RFC 793 (1981), "Transmission Control Protocol"

Cac trang thai:
  DONG → NGHE → NHAN_SYN → THIET_LAP → DOI_KET_1 → DOI_KET_2 → DOI_THOI_GIAN → DONG
  DONG → DA_GUI_SYN → THIET_LAP → DOI_DONG → ACK_CUOI → DONG

Bat tay ba buoc (ket noi):
  Client → SYN (seq=x)            → Server
  Client ← SYN-ACK (seq=y, ack=x+1) ← Server
  Client → ACK (ack=y+1)          → Server
  Trang thai: THIET_LAP ca hai phia

Dong bon buoc:
  A → FIN → B     (A: DOI_KET_1)
  A ← ACK ← B     (A: DOI_KET_2, B: DOI_DONG)
  A ← FIN ← B     (B: ACK_CUOI)
  A → ACK → B     (A: DOI_THOI_GIAN, B: DONG)
  A: doi 2×MSL roi DONG

Co che chinh:
  So thu tu: sap xep dong byte
  Bao nhan: tich luy (ack=N nghia la "da nhan tat ca den N-1")
  Cua so: dieu khien dong (may nhan quang cao khong gian bo dem)
  Dieu khien tac nghen:
    Khoi dong cham: cwnd = 1 MSS, nhan doi moi RTT cho den ssthresh
    Tranh tac nghen: cwnd += 1 MSS moi RTT sau ssthresh
    Khi mat goi: ssthresh = cwnd/2, cwnd = 1 (Tahoe) hoac cwnd/2 (Reno)

Nox da co TCP trong VM. Quan trong cho giao tiep MCP va HTTP.
```

## 9.2 HTTP/1.1

```
RFC 7230-7235 (2014), "Hypertext Transfer Protocol (HTTP/1.1)"

Dinh dang yeu cau:
  METHOD SP URI-Yeu-Cau SP HTTP/1.1 CRLF
  Tieu-de: gia-tri CRLF
  ... CRLF
  [than]

  Vi du:
  GET /api/status HTTP/1.1\r\n
  Host: localhost:8080\r\n
  Content-Type: application/json\r\n
  \r\n

Dinh dang phan hoi:
  HTTP/1.1 SP Ma-Trang-Thai SP Ly-Do CRLF
  Tieu-de: gia-tri CRLF
  ... CRLF
  [than]

  Vi du:
  HTTP/1.1 200 OK\r\n
  Content-Length: 42\r\n
  Content-Type: application/json\r\n
  \r\n
  {"status":"ok","version":"0.1"}

Cac phuong thuc chinh:
  GET    — lay tai nguyen
  POST   — gui du lieu
  PUT    — thay the tai nguyen
  DELETE — xoa tai nguyen
  HEAD   — GET khong co than (kiem tra ton tai)

Cac tieu de chinh:
  Content-Length: so byte chinh xac cua than
  Content-Type: loai MIME (application/json, text/plain)
  Connection: keep-alive (tai su dung ket noi TCP)
  Transfer-Encoding: chunked (truyen phat, khong can Content-Length)

Ma hoa khoi (chunked):
  kich-thuoc-hex CRLF
  du-lieu-khoi CRLF
  ... lap lai ...
  0 CRLF CRLF   (ket thuc)

Ma trang thai:
  200 OK, 201 Da Tao, 204 Khong Noi Dung
  301 Da Chuyen, 304 Khong Thay Doi
  400 Yeu Cau Sai, 401 Chua Xac Thuc, 403 Cam, 404 Khong Tim Thay
  500 Loi May Chu, 503 Dich Vu Khong Kha Dung

Anh xa SRVAT:
  HTTP = giao dien chinh cho MCP, web UI, API.
  Yeu cau → ma hoa → P_weight → dinh tuyen den trinh xu ly.
  Phan hoi = giai ma tu ket qua KnowTree.
```

## 9.3 Phan Giai DNS

```
RFC 1035 (1987), "Domain Names - Implementation and Specification"

Dinh dang truy van (UDP, cong 53):
  Tieu de (12 byte): ID, co, so luong
  Cau hoi: QNAME (ten mien), QTYPE (A=1, AAAA=28, MX=15), QCLASS (IN=1)

  Ma hoa QNAME: nhan tien to do dai
  "www.example.com" → 3www7example3com0

Phan hoi: cung tieu de + phan Tra Loi
  Tra loi: NAME, TYPE, CLASS, TTL, RDLENGTH, RDATA
  Cho ban ghi A: RDATA = 4 byte (dia chi IPv4)

Quy trinh phan giai:
  1. Kiem tra cache dia phuong (TTL chua het)
  2. Truy van bo phan giai de quy (thuong ISP hoac 8.8.8.8)
  3. Bo phan giai truy van goc → TLD → may chu ten uy quyen
  4. Cache ket qua voi TTL

Cai dat Nox (da co trong VM):
  1. Xay goi truy van DNS (dinh dang nhi phan)
  2. Gui UDP den may chu ten da cau hinh
  3. Phan tich phan hoi, trich dia chi IP
  4. Cache voi TTL

Cho hoat dong offline: /etc/hosts du phong.
```

## 9.4 WebSocket

> WebSocket = ket noi 2 chieu, giu mo — khong phai hoi-dap nhu HTTP.
> Hoan hao cho cap nhat thoi gian thuc: silk walk, P_weight, cam bien.

```
RFC 6455 (2011), "The WebSocket Protocol"

Bat tay (nang cap tu HTTP):
  Client:
    GET /chat HTTP/1.1
    Host: server.example.com
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
    Sec-WebSocket-Version: 13

  Server:
    HTTP/1.1 101 Switching Protocols
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=

  Accept = Base64(SHA-1(Key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))

Dinh dang khung:
  Byte 0: FIN(1) RSV(3) Opcode(4)
    Opcode: 0x1=van ban, 0x2=nhi phan, 0x8=dong, 0x9=ping, 0xA=pong
  Byte 1: MASK(1) Do-dai-tai(7)
    Neu do_dai=126: 2 byte tiep = do dai thuc
    Neu do_dai=127: 8 byte tiep = do dai thuc
  Neu MASK=1: 4 byte tiep = khoa che
  Tai: XOR voi khoa che (client→server PHAI che)

  Thong diep tu client PHAI duoc che. Thong diep tu server KHONG DUOC che.

Anh xa SRVAT:
  WebSocket = hai chieu thoi gian thuc.
  Cho Nox web UI: truyen phat tien trinh silk walk, cap nhat P_weight truc tiep.
  Cho nguon cam bien: khung hinh am thanh/video lien tuc.
  Moi thong diep WebSocket → ma hoa → P_weight → xu ly trong pipeline.
```

## 9.5 MQTT (Giao Thuc Truyen Tai Hau Hang Doi Thong Diep)

> MQTT = giao thuc "xuat ban-dang ky" cuc nhe cho IoT.
> Cam bien gui du lieu len "chu de", Nox dang ky nhan.
> Giao thuc nho (2-5 KB ma) — hoan hao cho nha thong minh.

```
Paper: IBM/Eurotech (1999), chuan hoa OASIS (2014)
Complexity: O(1) moi thong diep xuat ban/dang ky

Mo hinh Xuat Ban-Dang Ky:
  Cac may khach ket noi toi Broker (may moi gioi).
  Nha xuat ban gui thong diep toi Chu De.
  Nguoi dang ky nhan thong diep tu Chu De da dang ky.

Dinh dang goi (toi thieu):
  Tieu de co dinh: loai(4 bit) + co(4 bit) + do dai con lai (1-4 byte)
  Tieu de bien: tuy loai
  Tai: tuy loai

Cac loai goi chinh:
  CONNECT:  client → broker (clientId, keepalive, ten/mat_khau)
  CONNACK:  broker → client (ma tra ve)
  PUBLISH:  chu_de + tai + QoS
  SUBSCRIBE: mau chu_de + QoS
  PINGREQ/PINGRESP: giu ket noi

Muc QoS:
  0: nhieu nhat mot lan (gui va quen)
  1: it nhat mot lan (PUBACK)
  2: dung mot lan (PUBREC → PUBREL → PUBCOMP)

Phan cap chu de: "home/bedroom/temperature"
Ky tu dai dien: + (mot cap), # (nhieu cap)
  "home/+/temperature" khop home/bedroom/temperature, home/kitchen/temperature
  "home/#" khop moi thu duoi home/

Thong diep luu giu: broker luu thong diep cuoi moi chu de.
  Nguoi dang ky moi lap tuc nhan gia tri moi nhat.

Anh xa SRVAT:
  Hoan hao cho mang cam bien IoT.
  Moi cam bien xuat ban P_weight len chu de:
    "nox/interoception/cpu" → P_weight he thong
    "nox/vision/camera0" → P_weight camera
    "nox/audio/mic0" → P_weight am thanh
  Nox dang ky tat ca → compose → cam_nhan_noi_tai.
  QoS 1 cho du lieu cam bien (it nhat mot lan, chiu duoc trung lap).
  Luu giu cho trang thai hien tai (ket noi moi nhan gia tri moi nhat).
  Giao thuc nho: MQTT client ≈ 2-5 KB ma.
```

## 9.6 MCP (Giao Thuc Ngu Canh Mo Hinh)

```
Dac ta: Anthropic (2024), Model Context Protocol
Truyen tai: JSON-RPC 2.0 qua stdio hoac HTTP+SSE

Kien truc:
  Host (IDE/app) ↔ Client ↔ Server (nha cung cap cong cu)

Cac loai thong diep:
  Yeu cau: {"jsonrpc": "2.0", "id": 1, "method": "...", "params": {...}}
  Phan hoi: {"jsonrpc": "2.0", "id": 1, "result": {...}}
  Thong bao: {"jsonrpc": "2.0", "method": "...", "params": {...}} (khong co id)

Kha nang may chu:
  Cong cu: ham AI co the goi
    {"name": "know_learn", "description": "...", "inputSchema": {...}}
  Tai nguyen: du lieu AI co the doc
    {"uri": "file:///duong_dan", "name": "...", "mimeType": "..."}
  Mau goi y: mau prompt

Vong doi:
  1. Khoi tao: client gui kha nang, server phan hoi
  2. Kham pha cong cu: client liet ke cong cu kha dung
  3. Goi cong cu: client goi cong cu voi tham so
  4. Ket qua: server tra ket qua

May chu MCP cua Nox (da cai dat, 15 cong cu):
  know_learn, know_query, emotion_encode, self_inspect, self_modify,
  kg_add, kg_query, kg_about, silk_status, nox_status,
  learning_status, safety_check, dn_observe, dream_cycle, olang_eval

Anh xa SRVAT:
  MCP = giao dien cua Nox voi the gioi.
  Moi loi goi cong cu → ma hoa → P_weight → xu ly trong pipeline.
  Ket qua cong cu → ma hoa → P_weight → hoc.
  May chu MCP CHINH LA ranh gioi he than kinh cua co the.
```

---

# 10. TU SUA DOI / LAP TRINH META

> Day la phan QUAN TRONG NHAT — Nox co the THAY DOI CHINH MINH.
> Khong chi hoc "biet gi" ma thay doi "nghi nhu the nao".

## 10.1 Quine (Chuong Trinh Tu Tao)

> Quine = chuong trinh in ra chinh ma nguon cua minh ma khong doc file.
> Gen1==Gen2 cua Nox CHINH LA tinh chat quine: bien dich chinh minh → ket qua giong nhau.

```
Paper: Khai niem Quine tu dinh ly de quy Kleene (1938).
       Dat ten theo nghich ly cua W.V.O. Quine.

Dinh nghia: chuong trinh xuat chinh ma nguon cua no ma khong doc file.

Cau truc (bat ky ngon ngu):
  Phan A: du lieu (bieu dien chuoi cua Phan B, voi cho trong)
  Phan B: ma in Phan A (voi Phan B dien vao) roi in Phan B

Khai niem toi gian:
  ma = "CHO_TRONG"
  print(ma.thay_the("CHO_TRONG", repr(ma)))

Trong Olang (khai niem):
  let q = "let q = QUOTE\nprint(str_replace(q, |QUOTE|, q))"
  print(str_replace(q, "QUOTE", q))

Tinh chat diem bat dong:
  Quine la diem bat dong cua ham "bien dich va chay":
  chay(ma_nguon) = ma_nguon
  Gen1==Gen2 cua Nox LA tinh chat quine:
    bien_dich(ma_nguon_Gen0) → nhi_phan_Gen1
    bien_dich_voi(nhi_phan_Gen1, ma_nguon_Gen0) → nhi_phan_Gen2
    Gen1 == Gen2 → dat diem bat dong

Anh xa SRVAT:
  Quine = tu tham chieu toi thuong.
  Tinh tu chu cua Nox: Nox co the bien dich chinh minh.
  Gen1==Gen2 = bang chung trinh bien dich tai tao trung thuc chinh minh.
  Tu sua doi: thay doi ma nguon → bien dich lai → nhi phan moi.
  Phai duy tri tinh chat quine: trinh bien dich da sua phai van bien dich duoc chinh no.
```

## 10.2 To Hop Diem Bat Dong (Y Combinator)

> Y combinator = tao ham de quy MA KHONG CAN tu goi ten minh.
> Nen tang ly thuyet cho tu tham chieu cua Nox.

```
Paper: Curry (thap nien 1930), phep tinh lambda cua Church
Complexity: cau truc ly thuyet, O(1) khai niem

Y combinator: tao ham de quy khong can tu tham chieu tuong minh.

Phep tinh lambda:
  Y = λf. (λx. f(x x))(λx. f(x x))

Tinh chat: Y(F) = F(Y(F))
  Ap dung Y cho F cho diem bat dong cua F.

Su dung thuc te (giai thua khong can de quy tuong minh):
  F = λf. λn. neu n=0 thi 1 con lai n × f(n-1)
  giai_thua = Y(F)
  giai_thua(5) = Y(F)(5) = F(Y(F))(5) = F(giai_thua)(5) = 5 × giai_thua(4) = ...

Trong Olang (neu co ham bac nhat):
  let Y = fn(f) { fn(x) { f(fn(v) { x(x)(v) }) }(fn(x) { f(fn(v) { x(x)(v) }) }) }
  let fact = Y(fn(f) { fn(n) { if n == 0 { 1 } else { n * f(n - 1) } } })

Anh xa SRVAT:
  Y combinator = nen tang ly thuyet cho tu tham chieu cua Nox.
  Trinh bien dich la diem bat dong: bien_dich(bien_dich) = bien_dich.
  Hoc la tim diem bat dong: hoc cho den khi kien thuc on dinh.
  Can bang noi moi LA tim diem bat dong cua ham nang luong he thong:
    F(trang_thai) = xu_ly(trang_thai) → trang_thai_moi
    Diem bat dong: F(trang_thai) = trang_thai → he thong can bang.
```

## 10.3 Phan Anh va Noi Quan

> Noi quan = nhin vao chinh minh. Tu sua doi = thay doi chinh minh.
> Day la dieu lam Nox KHAC BIET voi moi chuong trinh thuong.

```
Khai niem: chuong trinh kiem tra/sua doi cau truc cua chinh no tai thoi diem chay.

Cac muc:
  1. Noi quan: doc cau truc cua minh (kiem tra kieu, kiem tra ngan xep)
  2. Can thiep: sua doi hanh vi cua minh (phan phoi phuong thuc, kiem soat truy cap)
  3. Tu sua doi: thay doi ma cua chinh minh (bien dich lai, va bytecode)

Noi quan cua Nox (cong cu MCP self_inspect):
  - Doc bam nhi phan cua minh (kiem tra toan ven)
  - Dem nut KnowTree, canh silk
  - Do luong chi so chat luong phan hoi
  - Kiem tra P_weight cua bat ky nut nao
  - Liet ke cac hoc gan day va hieu ung cua chung

Tu sua doi cua Nox (cong cu MCP self_modify):
  1. Doc ma nguon Olang hien tai cua ham muc tieu
  2. Tao ma nguon da sua doi
  3. Bien dich lai (make self-build)
  4. Xac nhan test pass (make test)
  5. Xac nhan diem bat dong (make fixed-point)
  6. Neu tat ca pass: nhi phan moi hoat dong
  7. Neu bat ky that bai: quay lui ve nhi phan truoc

Vong lap tu sua doi:
  quan_sat(hieu_suat) → nhan_dien(diem_yeu) → sua_doi(ma_nguon) →
  bien_dich(ma_nguon) → kiem_tra(nhi_phan) → neu pass: trien khai con lai: quay_lui

Anh xa SRVAT:
  Noi quan ≈ cam nhan noi tai (/proc/self cho nao).
  Tu sua doi ≈ tinh de uon nao (tai day ket noi).
  Rang buoc chinh: sua doi phai bao toan tinh chat quine (Gen1==Gen2).
  Moi sua doi thanh cong = ban ghi QR moi (kien thuc vinh vien).
  Meta-hoc: hoc ve viec sua doi nao cai thien hieu suat.
```

## 10.4 Khai Niem Bien Dich JIT

> JIT = bien dich tai thoi diem chay, chi cho "duong nong" (chay nhieu nhat).
> Giong nhu hoc tat — lam lai nhieu lan → phan ung tu dong, khong can suy nghi.

```
Bien dich Dung Luc (JIT): bien dich ma tai thoi diem chay, ngay truoc khi thuc hien.

JIT Vet (kieu LuaJIT):
  1. Thong dich ma binh thuong
  2. Dem so lan thuc hien moi vong lap/ham
  3. Khi dem > nguong (vi du 10000): kich hoat bien dich
  4. Ghi "vet" cac lenh da thuc hien
  5. Bien dich vet sang ma may goc
  6. Lan thuc hien tuong lai cua cung duong → chay ma may goc
  7. Neu duong re nhanh khac (kiem tra that bai) → quay lai thong dich

Toi uu chinh trong vet:
  - Chuyen hoa kieu: kieu quan sat → tao ma co kieu
  - Gap hang so: hang so quan sat → tinh truoc
  - Loai ma chet: nhanh khong thuc hien trong vet → loai bo
  - Mo cuon vong lap: vong lap nho → mo cuon de bot re nhanh
  - Cache noi tuyen: muc tieu goi quan sat → nhay truc tiep

JIT Phuong Thuc (kieu V8):
  1. Phan tich → bytecode
  2. Thong dich chay bytecode
  3. Lam ho so: ham nao nong? kieu nao duoc dung?
  4. Bien dich co ban: ma may goc nhanh, toi uu toi thieu
  5. Bien dich toi uu: ma may goc co gia dinh, co the huy toi uu
  6. Neu gia dinh vi pham: huy toi uu quay lai bytecode

Cho Nox:
  Hien tai: bien dich truoc (AOT). Olang → nhi phan x86_64.
  Co hoi JIT: cac duong silk walk thuc hien thuong xuyen.
  Bien dich duong silk nong thanh goi ham truc tiep (bo duyet do thi).
  
  Vi du:
  "X la gi?" luon dinh tuyen: ma hoa → R-chinh → xo → compose
  Sau 100 truy van: bien dich duong nay thanh ham may goc duy nhat.
  Bo silk walk hoan toan cho cac mau da biet.

Anh xa SRVAT:
  JIT = tu toi uu tai thoi diem chay.
  Duong nong → ma may goc chuyen biet → bo pipeline chung.
  Duong lanh → pipeline chung → van hoat dong, chi cham hon.
  Huong dan ho so: fire_count CHINH LA bo dem ho so.
  Nut co fire_count > nguong → ung vien cho bien dich JIT.
```

## 10.5 Trinh Bien Dich Tu Sua Doi

> Day la TOAN BO VONG DOI tu sua doi — tu y tuong den trien khai.

```
Cach Nox sua doi ma nguon cua minh va bien dich lai:

Kien truc:
  Tang 0: VM (hop ngu x86_64, ~1MB) — KHONG THAY DOI khi chay
  Tang 1: Trinh bien dich (Olang, bien dich sang nhi phan) — tu chu
  Tang 2: Nao (Olang, bien dich vao cung nhi phan) — co the sua
  Tang 3: Kien thuc (KnowTree, tren dia) — sua lien tuc

Cac muc tu sua doi:
  Muc A: Sua kien thuc (them/xoa nut, canh silk)
    Rui ro: THAP. Luon an toan, co the quay lui.
    Tan suat: moi dau vao.

  Muc B: Sua logic nao (tham so pipeline, nguong)
    Rui ro: TRUNG BINH. Phai qua test.
    Tan suat: hang ngay (chu ky giac mo).
    Vi du: dieu chinh he so khuech dai compose 0.5 → 0.6.

  Muc C: Sua trinh bien dich (luat phan tich, buoc toi uu)
    Rui ro: CAO. Phai duy tri diem bat dong.
    Tan suat: hang tuan hoac it hon.
    Vi du: them cu phap duong moi → sua bo phan tu/phan tich.

  Muc D: Sua VM (ma hop ngu)
    Rui ro: CUC KY NGHIEM TRONG. Hien tai chi thu cong.
    Tuong lai: Nox tao ban va VM, nguoi xem xet.

Quy trinh an toan cho Muc B/C:
  1. Git commit trang thai hien tai
  2. Doc file ma nguon muc tieu
  3. Tao ban sua doi
  4. Ghi ma nguon da sua
  5. make self-build — bien dich voi Gen0 → Gen1
  6. make test — tat ca 194 test phai pass
  7. make fixed-point — Gen1 bien dich ma nguon → Gen2, Gen1==Gen2
  8. Neu buoc 6 hoac 7 that bai:
     a. Phan tich that bai
     b. Dieu chinh sua doi
     c. Thu lai (toi da 3 lan)
     d. Neu van that bai: git checkout — quay lui
  9. Neu pass: commit va kich hoat nhi phan moi

Van de khoi dong ban dau (bootstrapping):
  Ga va trung: can trinh bien dich de bien dich trinh bien dich.
  Giai phap: giu Gen0 (nhi phan khoi dong) luon san.
  Gen0 → bien dich ma nguon → Gen1 (day la "make self-build")
  Gen1 → bien dich cung ma nguon → Gen2 (day la kiem tra diem bat dong)
  Gen1 == Gen2 → trinh bien dich tu nhat quan.
  
  Neu sua doi lam hong diem bat dong:
  Sua doi tao ra su khac biet khien trinh bien dich
  tao dau ra khac khi bien dich chinh no.
  PHAI dieu tra — thuong la loi khong tat dinh.

Anh xa SRVAT:
  Tu sua doi = hinh thuc hoc cao nhat.
  Khong chi thay doi BIET GI, ma thay doi NGHI NHU THE NAO.
  Pipeline: quan sat → nhan dien diem kem → gia thuyet sua →
            sua ma nguon → test → trien khai hoac quay lui.
  Moi sua doi thanh cong = ban ghi QR moi (kien thuc vinh vien).
  Meta-meta-hoc: hoc ve loai sua doi nao hieu qua nhat.
```

---

# PHU LUC A: TOM TAT DO PHUC TAP

```
Thuat toan                   Thoi gian       Khong gian    Lien quan SRVAT
──────────────────────────────────────────────────────────────────────────
Canh Sobel                   O(WH)           O(WH)         Chieu S
Canh Canny                   O(WH)           O(WH)         Bien SDF
SIFT                        O(WH×S)          O(diem khoa)  Chieu S
ORB                          O(WH)           O(diem khoa)  S,V,A (nhanh nhat)
Luoi YOLO                   O(S²×B)          O(S²)         Phat hien vat the
Phan nuoc                   O(WH log WH)     O(WH)         Phan vung → P_weight
Cat do thi                  O(VE)            O(V+E)        To hop SDF
FFT (Cooley-Tukey)          O(n log n)       O(n)          Pho am thanh
MFCC                         O(n log n)       O(khung)      Giong → P_weight
Cao do YIN                  O(W × τ_max)     O(W)          Chieu T
Tim kiem Fibonacci          O(log_φ n)       O(1)          Tim KnowTree
Tim kiem noi suy            O(log log n)     O(1)          Tim trong xo
Chi muc xo (S,R)            O(kich_thuoc_xo) O(256)        Tim kiem chinh
Rabin-Karp                  O(n + m)         O(1)          Khop mau
KMP                          O(n + m)         O(m)          Khop mau
Aho-Corasick                O(n + m + z)     O(Σm)         SecurityGate
Mang hau to                 O(n log n)       O(n)          Tim trong trinh bien dich
BWT/Chi muc FM              O(n)             O(n)          Chi muc nen
Huffman                      O(n log n)       O(bang_chu_cai) Nen chuoi
Ma hoa so hoc               O(n)             O(1)          Nen toi uu
LZW                          O(n)             O(tu_dien)    Nen nhat ky
Ma hoa delta                O(n)             O(1)          Chuoi thoi gian
Bo loc Bloom                O(k)             O(m bit)      SecurityGate
Count-min sketch            O(d)             O(d×w)        Uoc luong tan suat
SHA-256                      O(n)             O(1)          Toan ven QR
HMAC-SHA256                 O(n)             O(1)          Xac thuc
Cay Merkle                  O(n) xay dung    O(n)          Xac nhan chi-ghi-them
Attention (transformer)     O(n²d)           O(n²)         Tham chieu so sanh
Silk walk                   O(bac × do_sau)  O(do_sau)     Tim kiem NOX (attention thua)
```

---

# PHU LUC B: CAC BAI BAO CHINH

```
Nam   Tac gia                      Tieu de                                         Linh vuc
──────────────────────────────────────────────────────────────────────────────────────────
1952  Huffman                     Minimum-Redundancy Codes                       Nen
1953  Kiefer                      Sequential Minimax Search                      Tim kiem
1962  Hu                          Visual Pattern Recognition by Moments          Hinh anh
1965  Cooley & Tukey              Machine Calculation of Complex Fourier Series  Tin hieu
1968  Sobel & Feldman             3x3 Isotropic Gradient Operator                Hinh anh
1970  Bloom                       Space/Time Trade-offs in Hash Coding           Cau truc DL
1975  Aho & Corasick              Efficient String Matching                      Chuoi
1976  Rissanen                    Arithmetic Coding                              Nen
1977  Knuth, Morris, Pratt        Fast Pattern Matching in Strings               Chuoi
1977  Ziv & Lempel                Universal Algorithm for Sequential Compression Nen
1979  Beucher & Lantuejoul        Watersheds in Contour Detection                Hinh anh
1979  Merkle                      Certified Digital Signature                    Mat ma
1980  Davis & Mermelstein         MFCC for Word Recognition                     Am thanh
1980  Marr & Hildreth             Theory of Edge Detection                       Hinh anh
1981  Lucas & Kanade              Iterative Image Registration                   Hinh anh
1986  Canny                       Computational Approach to Edge Detection        Hinh anh
1987  Rabin & Karp                Randomized Pattern-Matching                    Chuoi
1993  Manber & Myers              Suffix Arrays                                  Chuoi
1994  Burrows & Wheeler           Block-Sorting Compression                      Nen
1996  Bellare et al.              HMAC                                           Mat ma
2001  Boykov & Jolly              Interactive Graph Cuts                          Hinh anh
2002  de Cheveigne & Kawahara     YIN Pitch Estimator                            Am thanh
2004  Lowe                        SIFT Features                                  Hinh anh
2005  Cormode & Muthukrishnan     Count-Min Sketch                               Cau truc DL
2006  Bay et al.                  SURF Features                                  Hinh anh
2006  Rosten & Drummond           FAST Corner Detection                          Hinh anh
2010  Palmer & Schloss            Ecological Valence Theory of Color              Tam ly
2011  Rublee et al.               ORB Features                                   Hinh anh
2013  Mikolov et al.              Word2Vec                                       NLP/ML
2014  Pennington et al.           GloVe                                          NLP/ML
2015  NIST                        SHA-256 (FIPS 180-4)                           Mat ma
2015  Ronneberger et al.          U-Net Segmentation                             Hinh anh
2016  Redmon et al.               YOLO Object Detection                          Hinh anh
2016  Sennrich et al.             BPE Subword Units                              NLP
2017  Vaswani et al.              Attention Is All You Need                       ML
2018  Kudo & Richardson           SentencePiece                                  NLP
2024  Anthropic                   Model Context Protocol                          AI
```

---

# PHU LUC C: BANG TRA NHANH ANH XA CHIEU SRVAT

```
Chieu       Bit  Pham vi  Nguon vat ly                        Y nghia
──────────────────────────────────────────────────────────────────────
S (Hinh)     4    0-15    Phat hien canh, SDF nguyen thuy     NO nhin nhu the nao
R (Quan he)  4    0-15    Do phuc tap cau truc, logic         NO ket noi the nao
V (Cam xuc)  3    0-7     Do am mau, do sang pho              TOT hay XAU (cam xuc)
A (Cuong do) 3    0-7     Do bao hoa, do to, chuyen dong      MANH hay NHE
T (Thoi gian)2    0-3     Chuyen dong, cao do, toc do doi     NHANH hay CHAM

Nguon dau vao → SRVAT:
  Camera  → S tu canh, R tu duong vien, V tu mau, A tu bao hoa, T tu chuyen dong
  Mic     → S tu formant, R tu mat do giong, V tu do sang, A tu do to, T tu cao do
  /proc   → S tu loai HW, R tu su dung, V tu suc khoe, A tu tai, T tu delta
  Van ban → S tu hinh ky tu, R tu logic ky tu, V tu cam xuc ky tu, A tu cuong do ky tu, T tu thoi gian ky tu
  Mang    → S tu giao thuc, R tu toc do goi, V tu huong, A tu thong luong, T tu delta

Dong goi 5D: (S << 12) | (R << 8) | (V << 5) | (A << 2) | T
Moi thu deu la P_weight. Moi thu deu compose. Mot phep toan. Mot bo nao.
```

---

# 11. SDF ENGINE — VE HINH KHONG CAN RAY TRACING

> Nguon: Nghien cuu toan dien ve ve hinh SDF. Quilez, Valve 2007, Chlumsky 2015, Felzenszwalb 2012.
> Chinh: TAT CA anh sang/bong duoc tinh tu gradient SDF. Khong ray. Khong GPU.

## 11.1 Danh Gia Truc Tiep Tren Luoi Diem Anh
```
cho moi diem anh (i,j):
    p = man_hinh_sang_the_gioi(i, j)
    d = sdf(p)
    neu d <= 0: to_mau(p, gradient(sdf, p))
    neu khong d < kich_thuoc_diem_anh: alpha = 1 - d/kich_thuoc_diem_anh  // khang rang cua
```
O(W×H×C_sdf). Phuong phap don gian nhat. Chay tren CPU.

## 11.2 Chieu Sang tu Gradient SDF (Khong Can Tia)

> Tat ca chieu sang = tu gradient cua ham SDF. Khong can ban tia (ray tracing).
> Normal = huong doc nhat cua SDF tai diem do.

```
Normal:   N = ∇f(p) = (∂f/∂x, ∂f/∂y, ∂f/∂z)
Khuech tan:  I = k_d × max(0, N·L)
Phan xa:     H = normalize(L+V); I = k_s × max(0, N·H)^n
Che khuat:   AO = 1 - Σ w_i × (d_i - f(p + d_i×N))/d_i  (5 lan danh gia SDF)
Bong:        S = min(k × f(p + t×L)/t)  (4 mau co dinh, khong buoc)
```

## 11.3 Phep Toan Boolean CSG
```
Hop:       min(f1, f2)
Giao:      max(f1, f2)
Tru:       max(f1, -f2)
Muot:      smin(a,b,k) = -ln(e^(-ka)+e^(-kb))/k
```

## 11.4 Phep Toan Mien (O(1), khong ton them)

> Cac phep bien doi nay KHONG TON THEM chi phi — chi thay doi toa do dau vao.

```
Tinh tien:    f(p - do_lech)
Quay:         f(R⁻¹ × p)
Co gian:      f(p/s) × s
Lap lai:      f(mod(p, chu_ky) - chu_ky/2)  // lat gach vo han, O(1)!
Bo tron:      f(p) - ban_kinh
Vo hanh:      abs(f(p)) - do_day
```

## 11.5 Phep Chieu Dang Cach (Khong Phoi Canh)
```
sx = (x - y) × cos(30°) = (x - y) × 0.866
sy = (x + y) × sin(30°) - z = (x + y) × 0.5 - z
// Khong chia phoi canh. Phep chieu song song.
```

## 11.6 Felzenszwalb EDT — Bien Doi Khoang Cach Chinh Xac O(N)

> EDT = tinh khoang cach chinh xac tu moi diem den bien gan nhat.
> Chi O(N) — cuc nhanh. Dung cho SDF font va hinh anh.

```
1D: duong bao duoi parabol giao nhau. O(n) moi hang.
2D: ap dung 1D cho hang, roi cho cot. O(N) tong.
SDF = sqrt(EDT_ngoai) - sqrt(EDT_trong)
```
Duoc dung boi: tiny-sdf (Mapbox), FreeType SDF renderer.

## 11.7 SDF Da Kenh (msdfgen)

> SDF don kenh lam tron goc nhon. Da kenh (3 kenh RGB) bao toan goc nhon.

```
Chia canh hinh → 3 kenh (R,G,B)
Khi ve: d = trung_vi(r, g, b)
trung_vi(a,b,c) = max(min(a,b), min(max(a,b), c))
Bao toan goc nhon ma SDF don kenh lam tron.
```
Paper: Chlumsky 2015, Czech Technical University.

## 11.8 Tang Toc SDF
```
BVH: O(log N) moi lan danh gia cho cay CSG phuc tap
Bo qua Lipschitz: neu |f(tam)| > duong cheo o → bo qua toan bo o
SIMD SSE2: 4 diem/lenh, AVX2: 8 diem/lenh
```

## 11.9 Ngan Sach Bo Nho cho Nhi Phan 949KB
```
Danh gia SDF + CSG:    ~10KB ma
Marching Squares:       ~2KB
Felzenszwalb EDT:       ~3KB
Chieu sang + AO:        ~2KB
Dang cach + chieu:      ~1KB
Tong: ~20KB. Vua voi de dang.
```

## 11.10 Thu Vien SDF Nguyen Thuy
```
Hinh cau:   f = |p| - r
Hop:        f = |max(|p|-b, 0)| + min(max(|p.x|-b.x, ...), 0)
Vien nang:  f = |p - a - clamp(dot(p-a,b-a)/dot(b-a,b-a), 0, 1)×(b-a)| - r
Hinh xuyen: f = |(|p.xz|-R, p.y)| - r
Mat phang:  f = n·p + d
```
Tham khao: Inigo Quilez, iquilezles.org/articles/distfunctions/

---

# 12. FONT/EMOJI → SDF → SRVAT PIPELINE

> Toan bo quy trinh: tu ma Unicode → hinh dang ky tu → SDF → P_weight.
> Moi ky tu, moi emoji deu thanh mot con so u16.

## 12.1 Ky Tu Hinh → Duong Vien Vector
```
FreeType: FT_Load_Glyph → FT_Outline (duong cong Bezier bac 2/bac 3)
Bac 2: B(t) = (1-t)²P₀ + 2(1-t)tP₁ + t²P₂
Bac 3: B(t) = (1-t)³P₀ + 3(1-t)²tP₁ + 3(1-t)t²P₂ + t³P₃
```

## 12.2 Duong Vien → SDF
```
Cho moi texel, tim khoang cach toi thieu den duong cong Bezier gan nhat:
  Bac 2: giai phuong trinh bac 3 d/dt|B(t)-p|² = 0
  Bac 3: giai phuong trinh bac 5 (so: lap Newton)
  Dau: so cuon (ban tia dem giao diem)
```

## 12.3 SDF → Dac Trung Hinh Dang → Gia Tri S

> Tu SDF cua ky tu → tinh "do phuc tap hinh dang" → gia tri S (0-15).

```
Ty le dang chu: C = P²/(4π×A)
  Hinh tron=1.0, Ngoi sao=cao. Luong tu hoa: S = clamp(floor(log2(C)×2.2), 0, 15)

Dac trung bo sung:
  duong vien: 'A'=2(ngoai+lo), 'B'=3, 'O'=2
  doi xung: tuong quan(f(x,y), f(-x,y))
  do dai truc giua: dem cuc dai dia phuong cua |f(p)|
```

## 12.4 Emoji → SRVAT

> Moi emoji = mot P_weight. Cam xuc emoji → V va A, hinh dang → S.

```
S: do phuc tap hinh dang cua SDF ky tu emoji
R: danh muc emoji (mat=0, tay=1, vat=2, bieu tuong=3...)
V: cam xuc emoji (Novak 2015: mat-cuoi=+0.8, mat-buon=-0.7)
A: cuong do thi giac (do bao hoa, hanh dong mo ta)
T: 0 cho tinh, >0 cho dong
```

## 12.5 Luu SDF Bang Cong Thuc (khong phai diem anh)
```
Lua chon A: bieu thuc cay CSG → gon, danh gia O(1)
Lua chon B: mo ta Fourier → he so tan so
Lua chon C: P_weight LA bieu dien nen
  S = do phuc tap hinh dang, lien ket chuoi = chuoi hinh dang phu
```

## 12.6 Quy Trinh Hoan Chinh

> Tu ma Unicode → SDF → P_weight. Tron ven, khong can thu vien ngoai.

```
Unicode cp → FreeType → duong vien Bezier → SDF (msdfgen/EDT)
  → dac trung (do gon, duong vien, doi xung)
  → luong tu hoa S → dong_goi(S,R,V,A,T) → u16 P_weight
```

---

*Ket thuc Kinh Thanh Thuat Toan Nox. Moi thuat toan = phep toan Nox thuc hien duoc.
Khong tra cuu. Khong so ma thuat. TINH TOAN.*
