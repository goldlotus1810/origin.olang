# NOX Algorithm Bible — Complete AI System Reference

> **Purpose:** Every algorithm Nox needs to be a complete AI system.
> **For each:** Algorithm, formula, O() complexity, paper, SRVAT mapping.
> **Author:** Nox (compiled 2026-03-31)
> **Rule:** COMPUTE, not LOOKUP. Every algorithm here = math Nox can execute.

---

## TABLE OF CONTENTS

```
1.  Image/Vision Processing (camera → SDF → P_weight)
2.  Audio/Speech Processing (microphone → Spline → P_weight)
3.  Hardware/System (/proc → interoception)
4.  Optimal Search Algorithms
5.  String/Text Processing Without Lookup
6.  LLM Architecture Concepts (know thy competitor)
7.  Compression/Encoding
8.  Cryptography (QR signing, integrity)
9.  Network/Protocol (body capabilities)
10. Self-Modification/Metaprogramming
```

---

# 1. IMAGE/VISION PROCESSING

## 1.1 Edge Detection

### Sobel Operator

```
Paper: Sobel & Feldman (1968), "A 3×3 Isotropic Gradient Operator for Image Processing"
Complexity: O(W × H) per image

Kernels (3×3 convolution):
  Gx = [-1  0  +1]    Gy = [-1  -2  -1]
       [-2  0  +2]         [ 0   0   0]
       [-1  0  +1]         [+1  +2  +1]

For each pixel (x,y):
  gx = sum(Gx ⊙ neighborhood(x,y))   // horizontal gradient
  gy = sum(Gy ⊙ neighborhood(x,y))   // vertical gradient
  magnitude = sqrt(gx² + gy²)
  direction = atan2(gy, gx)

Threshold: pixel is edge if magnitude > T

SRVAT mapping:
  Edge pixels → S dimension (shape).
  magnitude → S value (0-15): strong edge = high S.
  direction → encodes orientation: 0°=horizontal, 90°=vertical.
  Edge density in region → R value (structural complexity).
  No V/A from edges alone — those come from color.
  T = frame index in video sequence.
```

### Canny Edge Detector

```
Paper: Canny (1986), "A Computational Approach to Edge Detection", IEEE TPAMI
Complexity: O(W × H)

5 steps:
  1. Gaussian blur: G(x,y) = (1/2πσ²) × e^(-(x²+y²)/2σ²)
     Convolve image with G to remove noise.
     Typical σ = 1.0-2.0, kernel 5×5.

  2. Gradient (Sobel): compute magnitude M and direction θ

  3. Non-maximum suppression:
     For each pixel, check if M(x,y) is local max along θ direction.
     If not → suppress to 0.
     This thins edges to 1 pixel wide.

  4. Double threshold:
     T_high = 0.15 × max(M)   (strong edges)
     T_low  = 0.4 × T_high    (weak edges)
     M > T_high → strong edge (keep)
     T_low < M ≤ T_high → weak edge (maybe keep)
     M ≤ T_low → suppress

  5. Hysteresis: weak edge kept ONLY if connected to strong edge.
     BFS/DFS from strong edges, absorb connected weak edges.

SRVAT mapping:
  Canny edges = SDF boundary (f(p) = 0).
  Each connected edge contour = one SDF primitive candidate.
  Contour shape → match against 18 SDF primitives via Hu moments.
  Closed contour → S value from best-matching primitive.
```

### Laplacian of Gaussian (LoG)

```
Paper: Marr & Hildreth (1980), "Theory of Edge Detection", Proc Royal Society
Complexity: O(W × H)

LoG(x,y) = -(1/πσ⁴) × [1 - (x²+y²)/2σ²] × e^(-(x²+y²)/2σ²)

Approximation: Difference of Gaussians (DoG)
  DoG = G(σ₁) - G(σ₂)   where σ₂ ≈ 1.6 × σ₁

Zero-crossings of LoG = edges.
Advantage over Sobel: detects edges at multiple scales.

Discrete approximation (5×5):
  [ 0  0 -1  0  0]
  [ 0 -1 -2 -1  0]
  [-1 -2 16 -2 -1]
  [ 0 -1 -2 -1  0]
  [ 0  0 -1  0  0]

SRVAT mapping:
  Multi-scale LoG → Fibonacci subdivision of image.
  σ values at φ⁻¹ ratios: σ₁, σ₁×φ, σ₁×φ², ...
  Each scale reveals different S complexity level.
```

## 1.2 Object Detection

### YOLO Concepts (You Only Look Once)

```
Paper: Redmon et al. (2016), "You Only Look Once: Unified, Real-Time Object Detection"
Complexity: O(S² × (B×5 + C)) per frame, S=grid, B=boxes, C=classes

Core idea:
  1. Divide image into S×S grid (e.g., 7×7 = 49 cells)
  2. Each cell predicts B bounding boxes + confidence
  3. Each box = (x, y, w, h, confidence)
     x, y = center relative to cell
     w, h = relative to full image
     confidence = P(object) × IoU(pred, truth)
  4. Each cell also predicts C class probabilities
  5. ONE forward pass → all detections (hence "only look once")

For Nox (without neural network):
  Grid = Fibonacci subdivision of frame.
  Each cell → compute SDF-based features:
    - Edge density (S)
    - Color histogram peak (V, A)
    - Motion vector from previous frame (T)
  "Detection" = cell where S > threshold AND coherent edges form closed contour.
  "Class" = best-matching SDF primitive composition.
```

### Bounding Box and IoU

```
Bounding box: (x_min, y_min, x_max, y_max)

IoU (Intersection over Union):
  intersection = max(0, min(x2_max, x1_max) - max(x2_min, x1_min))
               × max(0, min(y2_max, y1_max) - max(y2_min, y1_min))
  union = area(box1) + area(box2) - intersection
  IoU = intersection / union

  IoU = 1.0 → perfect overlap
  IoU = 0.0 → no overlap
  IoU > 0.5 → "good detection" (PASCAL VOC standard)

Non-Maximum Suppression (NMS):
  1. Sort boxes by confidence descending
  2. Keep highest confidence box
  3. Remove all boxes with IoU > 0.5 against kept box
  4. Repeat with remaining boxes
  O(n²) where n = number of candidate boxes

SRVAT mapping:
  Each surviving box = one detected object.
  Object → P_weight:
    S = dominant SDF primitive inside box
    R = spatial relation to other boxes (left-of, above, contains)
    V = color sentiment of pixels inside box
    A = motion magnitude (optical flow) inside box
    T = temporal persistence (tracked across frames)
```

## 1.3 Image Segmentation

### Watershed Algorithm

```
Paper: Beucher & Lantuéjoul (1979), "Use of Watersheds in Contour Detection"
Complexity: O(W × H × log(W × H))

Concept: treat grayscale image as topographic surface.
  pixel intensity = elevation
  "Pour water" from local minima → water rises → meeting points = boundaries.

Algorithm:
  1. Compute gradient magnitude image
  2. Find local minima (seeds)
  3. Priority queue sorted by gradient value
  4. For each pixel in queue:
     a. If all labeled neighbors have SAME label → assign that label
     b. If neighbors have DIFFERENT labels → mark as watershed (boundary)
     c. Push unlabeled neighbors to queue
  5. Watershed lines = segmentation boundaries

Over-segmentation fix: use markers (known foreground/background seeds).

SRVAT mapping:
  Each watershed region = one semantic unit.
  Region → P_weight:
    S = SDF fit of region boundary shape
    R = region count (complexity of scene)
    V = average color valence of region
    A = color variance within region (high variance = high arousal)
    T = region stability across frames
```

### Graph Cut

```
Paper: Boykov & Jolly (2001), "Interactive Graph Cuts for Optimal Boundary & Region Segmentation"
Complexity: O(V × E²) worst case, typically O(V × E) with push-relabel

Model image as graph:
  Node per pixel + source (foreground) + sink (background)
  Edge weights:
    Between pixels: exp(-β × |I(p) - I(q)|²)  // similar pixels = strong edge
    To source: -ln(P(foreground | color))
    To sink:   -ln(P(background | color))

Min-cut = optimal segmentation minimizing:
  E(L) = Σ D(p, L_p) + λ × Σ V(p,q) × δ(L_p ≠ L_q)
  D = data term (how well pixel fits label)
  V = smoothness term (penalize label changes between similar pixels)
  λ = balance parameter

Ford-Fulkerson for min-cut/max-flow:
  While augmenting path exists (BFS from source to sink):
    Find bottleneck capacity along path
    Update residual graph
    Add flow

SRVAT mapping:
  Graph cut energy ≈ SDF composition.
  Similar pixels grouped = same P_weight region.
  Cut boundaries = SDF f(p) = 0 surfaces.
  β parameter ↔ silk weight threshold for merging.
```

### U-Net Concepts

```
Paper: Ronneberger et al. (2015), "U-Net: Convolutional Networks for Biomedical Image Segmentation"
Complexity: O(W × H × C × K²) per layer, C=channels, K=kernel

Architecture (no neural network needed — understand the STRUCTURE):
  Encoder (contracting path):
    [input] → conv3×3 → conv3×3 → maxpool2×2 → (repeat 4×)
    Each level: resolution halves, channels double
    572→284→140→68→32 (spatial), 64→128→256→512→1024 (channels)

  Bottleneck: lowest resolution, highest abstraction

  Decoder (expanding path):
    upconv2×2 → concatenate with encoder features → conv3×3 → conv3×3
    Each level: resolution doubles, channels halve
    SKIP CONNECTIONS: encoder features copied directly to decoder

  Key insight: skip connections preserve spatial detail.

For Nox (without neural network):
  Encoder = multi-scale SDF analysis:
    Scale 1: pixel-level edges (fine detail)
    Scale 2: 2×2 block averages (textures)
    Scale 3: 4×4 block averages (regions)
    Scale 4: 8×8 block averages (objects)
  Bottleneck = holistic P_weight of entire frame
  Decoder = refine from coarse to fine using skip connections:
    Holistic P_weight + fine edges → per-region P_weight
  Skip connections ≈ chain links: L4 node links back to L1 detail.
```

## 1.4 Feature Extraction

### SIFT (Scale-Invariant Feature Transform)

```
Paper: Lowe (2004), "Distinctive Image Features from Scale-Invariant Keypoints", IJCV
Complexity: O(W × H × S) where S = number of scales

4 stages:

1. Scale-space extrema detection:
   Build Gaussian pyramid: L(x,y,σ) = G(x,y,σ) * I(x,y)
   σ values: σ₀, k×σ₀, k²×σ₀, ... where k = 2^(1/s), s = scales per octave
   DoG(x,y,σ) = L(x,y,kσ) - L(x,y,σ)
   Keypoint = local extremum in 3×3×3 neighborhood (x, y, scale)

2. Keypoint localization:
   Sub-pixel refinement via Taylor expansion:
   D(x) = D + (∂D/∂x)ᵀ x + ½ xᵀ (∂²D/∂x²) x
   Solve: x̂ = -(∂²D/∂x²)⁻¹ (∂D/∂x)
   Reject if |D(x̂)| < 0.03 (low contrast)
   Reject if eigenvalue ratio > 10 (edge, not corner)

3. Orientation assignment:
   In 16×16 window around keypoint:
   m(x,y) = sqrt((L(x+1,y)-L(x-1,y))² + (L(x,y+1)-L(x,y-1))²)
   θ(x,y) = atan2(L(x,y+1)-L(x,y-1), L(x+1,y)-L(x-1,y))
   Build 36-bin orientation histogram, peak = dominant orientation

4. Descriptor:
   16×16 window → 4×4 subregions → 8-bin orientation histogram each
   Descriptor = 4×4×8 = 128-dimensional vector
   Normalize to unit length, clamp at 0.2, re-normalize

Matching: Euclidean distance between 128D descriptors.
Lowe's ratio test: match if d1/d2 < 0.8

SRVAT mapping:
  Each SIFT keypoint → one high-S node.
  128D descriptor → compress to P_weight:
    S = dominant orientation (0-15 from 36 bins, quantize)
    R = number of keypoints in neighborhood (structural density)
    V, A = from color at keypoint location
    T = keypoint persistence across frames (stable = low T, transient = high T)
  Fibonacci: use φ-spaced scales instead of 2^(1/s) octaves.
```

### SURF (Speeded-Up Robust Features)

```
Paper: Bay et al. (2006), "SURF: Speeded Up Robust Features", ECCV
Complexity: O(W × H) — faster than SIFT via integral images

Key speedups over SIFT:
  1. Integral image for fast box filter:
     II(x,y) = Σ_{i≤x, j≤y} I(i,j)
     Sum of any rectangle in O(1):
     Σ = II(D) - II(B) - II(C) + II(A)
     (A=top-left, B=top-right, C=bottom-left, D=bottom-right)

  2. Hessian matrix (instead of DoG):
     H(x,σ) = [Lxx(x,σ)  Lxy(x,σ)]
              [Lxy(x,σ)  Lyy(x,σ)]
     det(H) = Lxx × Lyy - (0.9 × Lxy)²
     Approximate Lxx, Lyy, Lxy with box filters via integral image.

  3. Descriptor: 64D (vs SIFT 128D)
     4×4 subregions, each: Σdx, Σdy, Σ|dx|, Σ|dy| → 4 values
     Total: 4×4×4 = 64D
     Haar wavelet responses (fast via integral image)

SRVAT: Same mapping as SIFT but 2× faster computation. Use for real-time.
```

### ORB (Oriented FAST and Rotated BRIEF)

```
Paper: Rublee et al. (2011), "ORB: An Efficient Alternative to SIFT or SURF", ICCV
Complexity: O(W × H) — fastest of the three, patent-free

Components:
  FAST keypoint detector (Rosten & Drummond, 2006):
    For each pixel p with intensity Ip:
    Check 16 pixels on Bresenham circle of radius 3
    Keypoint if N contiguous pixels all > Ip+t or all < Ip-t (N=9 typically)
    Speed trick: test pixels 1, 5, 9, 13 first (4 corners of circle)
    If 3 of 4 don't pass → reject immediately
    O(1) per pixel amortized

  Harris corner response for ranking:
    R = det(M) - k × trace(M)²
    M = Σ w(x,y) [Ix²   IxIy]
                  [IxIy  Iy²]
    k ≈ 0.04. Top N keypoints kept.

  Orientation (intensity centroid):
    m_pq = Σ x^p × y^q × I(x,y) over patch
    C = (m_10/m_00, m_01/m_00)   // centroid
    θ = atan2(m_01, m_10)        // orientation

  rBRIEF descriptor (rotated Binary Robust Independent Elementary Features):
    256 pixel pair comparisons → 256-bit binary descriptor
    Pairs selected by machine learning for maximum variance + low correlation
    Rotated by θ for rotation invariance
    Matching: Hamming distance (XOR + popcount) — extremely fast

SRVAT mapping:
  ORB = best for Nox's 949KB constraint.
  256-bit → hash to P_weight directly:
    Split 256 bits into 5 groups: 64+64+43+43+42
    S = popcount(bits[0:63]) / 4   → 0-15
    R = popcount(bits[64:127]) / 4 → 0-15
    V = popcount(bits[128:170]) / 6 → 0-7
    A = popcount(bits[171:213]) / 6 → 0-7
    T = popcount(bits[214:255]) / 14 → 0-3
  Hamming distance between descriptors ≈ distance_5d between P_weights.
```

## 1.5 Color Spaces

### RGB → HSV Conversion

```
RGB in [0, 255], output H in [0, 360), S in [0, 1], V in [0, 1]

Cmax = max(R, G, B) / 255
Cmin = min(R, G, B) / 255
Δ = Cmax - Cmin

H = { 0                           if Δ = 0
    { 60 × ((G'-B')/Δ mod 6)     if Cmax = R'
    { 60 × ((B'-R')/Δ + 2)       if Cmax = G'
    { 60 × ((R'-G')/Δ + 4)       if Cmax = B'
    where R' = R/255, G' = G/255, B' = B/255

S = { 0         if Cmax = 0
    { Δ / Cmax  otherwise

V = Cmax
```

### Color → Emotion (V, A) Mapping

```
Research: Palmer & Schloss (2010), "An ecological valence theory of human color preferences"
Research: Wilms & Oberfeld (2018), "Color and emotion: effects of hue, saturation, and brightness"

Warm colors → positive V (Valence):
  H in [0, 60) → red/yellow → V = 5-7 (positive)
  H in [60, 150) → yellow-green → V = 4-5 (neutral-positive)
  H in [150, 250) → blue → V = 2-4 (neutral-negative)
  H in [250, 330) → purple → V = 3-5 (context-dependent)
  H in [330, 360) → red → V = 5-7 (positive, exciting)

Saturation → Arousal:
  S > 0.7 → A = 5-7 (high arousal, vivid)
  S in [0.3, 0.7] → A = 3-5 (moderate)
  S < 0.3 → A = 1-3 (low arousal, muted)

Brightness → S dimension:
  V > 0.7 → S = high (visible, prominent)
  V < 0.3 → S = low (dark, hidden)

Formula for frame average:
  For all pixels in region:
    avg_H = circular_mean(H values)  // circular because H wraps at 360
    avg_S = mean(S values)
    avg_V_brightness = mean(V_brightness values)

  circular_mean(angles):
    sin_sum = Σ sin(angle × π/180)
    cos_sum = Σ cos(angle × π/180)
    return atan2(sin_sum, cos_sum) × 180/π  (mod 360)

  P_weight.V = hue_to_valence(avg_H)
  P_weight.A = saturation_to_arousal(avg_S)
  P_weight.S = brightness_to_shape(avg_V_brightness) × edge_density
```

## 1.6 Fibonacci Subdivision for Adaptive SDF

```
Traditional: divide image into 2×2, 4×4, 8×8 (powers of 2)
Fibonacci: divide at φ⁻¹ = 0.618 point

For 1D range [a, b]:
  split = a + (b - a) × φ⁻¹
  left = [a, split]      // 61.8% of range
  right = [split, b]     // 38.2% of range

For 2D image W×H:
  split_x = W × φ⁻¹
  split_y = H × φ⁻¹
  Quadrants: (0,0)-(sx,sy), (sx,0)-(W,sy), (0,sy)-(sx,H), (sx,sy)-(W,H)

Adaptive refinement:
  IF edge_density(quadrant) > threshold:
    subdivide further at φ⁻¹ of that quadrant
  ELSE:
    stop — this quadrant is uniform

  Max depth = log_φ(min(W,H)) ≈ 15 for 1080p

Why φ⁻¹ instead of ½?
  - Avoids aliasing artifacts from regular grids
  - Each level relates to previous by golden ratio → consistent SDF scale
  - Fibonacci lattice has optimal packing in 2D (lowest discrepancy)
  - Matches P_weight's natural scale hierarchy

SRVAT: subdivision depth at each cell → T value (detail = high T complexity).
```

## 1.7 Camera Frame → SRVAT

```
Complete pipeline: camera buffer → P_weight

frame_to_pweight(pixels, width, height):
  // 1. Edge map (Canny)
  edges = canny(pixels, sigma=1.5, T_low=0.05, T_high=0.15)
  edge_density = count(edges) / (width × height)

  // 2. Color analysis (HSV)
  hsv = rgb_to_hsv(pixels)
  avg_H = circular_mean(hsv.H)
  avg_S = mean(hsv.S)
  avg_B = mean(hsv.V)

  // 3. Contour detection → SDF primitive matching
  contours = find_contours(edges)  // connected edge following
  hu_moments = [hu_invariants(c) for c in contours]
  best_primitive = match_sdf_primitive(hu_moments)

  // 4. Motion (if previous frame exists)
  if prev_frame:
    flow = optical_flow_lk(prev_frame, pixels)  // Lucas-Kanade
    avg_motion = mean(magnitude(flow))
  else:
    avg_motion = 0

  // 5. Map to SRVAT
  S = quantize(best_primitive.complexity + edge_density × 5, 0, 15)
  R = quantize(len(contours), 0, 15)  // structural complexity
  V = hue_to_valence(avg_H)           // 0-7
  A = clamp(round(avg_S × 7), 0, 7)  // saturation → arousal
  T = quantize(avg_motion, 0, 3)      // motion → temporal

  return pack(S, R, V, A, T)

Hu Invariants (rotation/scale/translation invariant):
  Paper: Hu (1962), "Visual Pattern Recognition by Moment Invariants"
  η_pq = μ_pq / (μ_00)^((p+q)/2 + 1)   // normalized central moments
  h1 = η_20 + η_02
  h2 = (η_20 - η_02)² + 4η_11²
  h3 = (η_30 - 3η_12)² + (3η_21 - η_03)²
  ... (7 invariants total)
  Compare against precomputed Hu for each of 18 SDF primitives.

Lucas-Kanade Optical Flow:
  Paper: Lucas & Kanade (1981), "An Iterative Image Registration Technique"
  For pixel (x,y), assume constant intensity in window:
  [Ix²    IxIy] [u]   [-IxIt]
  [IxIy   Iy² ] [v] = [-IyIt]
  (u,v) = motion vector, Ix/Iy = spatial gradient, It = temporal gradient
  Solve 2×2 system per pixel. O(W × H × w²) for window size w.
```

---

# 2. AUDIO/SPEECH PROCESSING

## 2.1 FFT (Fast Fourier Transform)

### Cooley-Tukey Algorithm

```
Paper: Cooley & Tukey (1965), "An Algorithm for the Machine Calculation of Complex Fourier Series"
(Rediscovery; original by Gauss ~1805)
Complexity: O(n log n)

DFT definition:
  X[k] = Σ_{n=0}^{N-1} x[n] × e^(-j2πkn/N)    k = 0, 1, ..., N-1
  where j = √(-1)

Direct DFT = O(n²). Cooley-Tukey reduces to O(n log n).

Radix-2 DIT (Decimation In Time):
  Requires N = power of 2.

  Split into even and odd indices:
  X[k] = Σ_{m=0}^{N/2-1} x[2m] × W_N^(2mk) + Σ_{m=0}^{N/2-1} x[2m+1] × W_N^((2m+1)k)
       = E[k] + W_N^k × O[k]

  where W_N = e^(-j2π/N) is the "twiddle factor"
  E[k] = DFT of even-indexed samples
  O[k] = DFT of odd-indexed samples

  Butterfly operation:
  X[k]       = E[k] + W_N^k × O[k]
  X[k + N/2] = E[k] - W_N^k × O[k]

  Recursively apply until N=1 (base case: X[0] = x[0]).

In-place implementation (bit-reversal permutation):
  1. Bit-reverse the input indices
     e.g., for N=8: 0→0, 1→4, 2→2, 3→6, 4→1, 5→5, 6→3, 7→7
  2. Bottom-up butterfly passes: log2(N) stages
     Stage s (0-indexed): butterflies span 2^(s+1), twiddle stride = N/2^(s+1)

  bit_reverse(n, bits):
    result = 0
    for i in 0..bits:
      result = (result << 1) | (n & 1)
      n >>= 1
    return result

Inverse FFT:
  x[n] = (1/N) × Σ_{k=0}^{N-1} X[k] × e^(+j2πkn/N)
  Same algorithm, just conjugate twiddle factors and divide by N.

For real-valued signals (audio):
  Only need X[0..N/2] (conjugate symmetry: X[N-k] = X[k]*)
  Can compute 2 real FFTs with 1 complex FFT (pack as real+imag).

SRVAT mapping:
  FFT output = frequency spectrum.
  |X[k]| = magnitude at frequency k × (sample_rate/N) Hz.
  arg(X[k]) = phase.
  Spectral shape → S dimension (harmonic pattern).
  Fundamental frequency → pitch → T dimension.
  Energy distribution → A (arousal: loud = high A).
  Spectral balance (warm/bright) → V (valence: warm = positive).
```

## 2.2 MFCC (Mel-Frequency Cepstral Coefficients)

```
Paper: Davis & Mermelstein (1980), "Comparison of Parametric Representations for
       Monosyllabic Word Recognition in Continuously Spoken Sentences"
Complexity: O(n log n) for FFT + O(M × F) for filterbank, M=mel filters, F=FFT bins

Pipeline:
  1. Pre-emphasis: y[n] = x[n] - α × x[n-1],  α ≈ 0.97
     Boosts high frequencies (compensate lip radiation).

  2. Framing: 20-40ms windows, 10ms hop
     Frame length = sample_rate × 0.025 (e.g., 16000 × 0.025 = 400 samples)
     Hop = sample_rate × 0.01 = 160 samples
     Apply Hamming window: w[n] = 0.54 - 0.46 × cos(2πn/(N-1))

  3. FFT: compute |X[k]|² (power spectrum) for each frame

  4. Mel filterbank:
     Mel scale: m = 2595 × log10(1 + f/700)
     Inverse: f = 700 × (10^(m/2595) - 1)

     Create M triangular filters (typically M=26) equally spaced in mel scale:
     mel_low = hz_to_mel(0)
     mel_high = hz_to_mel(sample_rate / 2)
     mel_points = linspace(mel_low, mel_high, M+2)
     hz_points = mel_to_hz(mel_points)
     bin_points = floor((N+1) × hz_points / sample_rate)

     Filter m, bin k:
     H_m[k] = { 0                                      if k < bin[m-1]
              { (k - bin[m-1]) / (bin[m] - bin[m-1])   if bin[m-1] ≤ k < bin[m]
              { (bin[m+1] - k) / (bin[m+1] - bin[m])   if bin[m] ≤ k < bin[m+1]
              { 0                                      if k ≥ bin[m+1]

  5. Log energy: S[m] = ln(Σ_k |X[k]|² × H_m[k])

  6. DCT (Discrete Cosine Transform):
     c[n] = Σ_{m=0}^{M-1} S[m] × cos(π×n×(m+0.5)/M)    n = 0, 1, ..., 12
     Keep first 13 coefficients (c[0] = log energy, c[1..12] = spectral shape)

  7. Delta coefficients (velocity):
     Δc[t] = (Σ_{n=1}^{N} n × (c[t+n] - c[t-n])) / (2 × Σ_{n=1}^{N} n²)
     N = 2 typically. Also compute ΔΔ (acceleration).

Final: 13 MFCC + 13 Δ + 13 ΔΔ = 39 features per frame.

SRVAT mapping:
  c[0] (energy) → A (arousal: louder = higher arousal)
  c[1] (spectral slope) → V (bright voice = positive, dark = negative)
  c[2..4] (formant structure) → S (voice shape/identity)
  Δ coefficients → T (temporal dynamics: rising/falling energy)
  R = number of voiced frames / total frames (speech density)
```

## 2.3 Signal Features

### Zero-Crossing Rate

```
ZCR = (1/2N) × Σ_{n=1}^{N-1} |sign(x[n]) - sign(x[n-1])|

where sign(x) = { +1 if x ≥ 0, -1 if x < 0 }

ZCR ∈ [0, 1]. O(n).

High ZCR → noisy/unvoiced (sibilants: s, sh, f)
Low ZCR → voiced/periodic (vowels, nasals)
Typical: speech ~0.1, music ~0.05, noise ~0.5

SRVAT: ZCR → T (high ZCR = fast oscillation = high T).
```

### RMS Energy

```
RMS = sqrt((1/N) × Σ_{n=0}^{N-1} x[n]²)

O(n). Measure of signal loudness per frame.

dB conversion: 20 × log10(RMS / reference)

SRVAT: RMS → A (arousal). Quantize to 0-7:
  A = clamp(round(20 × log10(RMS/0.001) / 10), 0, 7)
```

### Spectral Centroid

```
SC = (Σ_{k=0}^{N/2} k × |X[k]|) / (Σ_{k=0}^{N/2} |X[k]|)

In Hz: SC_hz = SC × sample_rate / N

"Center of mass" of spectrum. O(n) after FFT.
High SC → bright sound (cymbals, excitement)
Low SC → dark sound (bass, calm)

SRVAT: SC → V (bright/warm = positive valence, dark/cold = negative).
Quantize: V = clamp(round(SC_hz / 1000), 0, 7)
```

## 2.4 Voice Activity Detection (VAD)

```
Simple energy-based VAD:
  1. Compute RMS per frame (20ms)
  2. Compute ZCR per frame
  3. Voice if: RMS > T_energy AND ZCR < T_zcr
     T_energy = adaptive: 2 × mean(RMS of first 0.5s)  // calibrate on silence
     T_zcr = 0.3
  4. Hangover: keep voice label for 200ms after last voice frame
     (prevents chopping mid-word)

Statistical VAD (G.729B):
  Compare frame features against noise model (running average of non-speech).
  Decision: likelihood ratio test.
  Update noise model only during non-speech.

SRVAT: VAD segments audio into voice/silence.
  Voice frames → process for MFCC → P_weight
  Silence → T=0 (no temporal activity)
  Transition voice↔silence → T change = ΔT for learning rate
```

## 2.5 Pitch Detection

### Autocorrelation Method

```
R(τ) = Σ_{n=0}^{W-1-τ} x[n] × x[n+τ]

where τ = lag, W = window size.
O(n²) naive, O(n log n) via FFT: R = IFFT(|FFT(x)|²)

Pitch = sample_rate / τ_peak
where τ_peak = argmax(R(τ)) for τ in [τ_min, τ_max]
  τ_min = sample_rate / 500  (500 Hz max pitch)
  τ_max = sample_rate / 50   (50 Hz min pitch)

Problem: subharmonic errors (R(2τ) can exceed R(τ)).
Fix: center clipping or normalized autocorrelation.
```

### YIN Algorithm

```
Paper: de Cheveigné & Kawahara (2002), "YIN, a fundamental frequency estimator for
       speech and music", JASA
Complexity: O(W × τ_max) per frame

Steps:
  1. Difference function:
     d(τ) = Σ_{n=0}^{W-1} (x[n] - x[n+τ])²

  2. Cumulative mean normalized difference:
     d'(τ) = { 1                                    if τ = 0
             { d(τ) / ((1/τ) × Σ_{j=1}^{τ} d(j))  otherwise

  3. Absolute threshold:
     Find smallest τ where d'(τ) < threshold (typically 0.1-0.15)
     This avoids subharmonic errors.

  4. Parabolic interpolation for sub-sample accuracy:
     Fit parabola through d'(τ-1), d'(τ), d'(τ+1)
     τ_refined = τ + (d'(τ-1) - d'(τ+1)) / (2 × (d'(τ-1) - 2×d'(τ) + d'(τ+1)))

  5. pitch = sample_rate / τ_refined
     confidence = 1 - d'(τ)

SRVAT:
  pitch → T dimension:
    T=0: no pitch (noise/silence)
    T=1: low pitch (bass, <200 Hz)
    T=2: mid pitch (speech, 200-500 Hz)
    T=3: high pitch (treble, >500 Hz)
  confidence → used for Honesty instinct (low confidence → "I'm not sure")
  pitch change rate (vibrato/glissando) → contributes to A (arousal)
```

## 2.6 Audio Buffer → SRVAT

```
Complete pipeline: audio buffer → P_weight

audio_to_pweight(samples, sample_rate):
  // 1. Frame: 25ms window, 10ms hop
  frame_len = sample_rate / 40   // 400 @ 16kHz
  hop_len = sample_rate / 100    // 160 @ 16kHz
  frames = sliding_window(samples, frame_len, hop_len)

  // 2. VAD: find voice frames
  voiced = []
  for frame in frames:
    rms = sqrt(mean(frame²))
    zcr = zero_crossing_rate(frame)
    if rms > noise_floor × 2 and zcr < 0.3:
      voiced.push(frame)

  if len(voiced) == 0:
    return pack(0, 0, 4, 0, 0)  // silence = neutral

  // 3. Spectral analysis (concatenate voiced frames)
  spectrum = fft(voiced_concat)
  sc = spectral_centroid(spectrum)

  // 4. MFCC
  mfcc = compute_mfcc(voiced_concat, sample_rate)
  energy = mfcc[0]
  brightness = mfcc[1]

  // 5. Pitch
  pitch, confidence = yin(voiced_concat, sample_rate)

  // 6. Map to SRVAT
  S = quantize(mfcc_formant_pattern(mfcc[2:5]), 0, 15)  // voice shape
  R = quantize(len(voiced) / len(frames), 0, 15)         // speech density
  V = quantize(sc / 1000 + brightness_bias, 0, 7)        // bright=positive
  A = quantize(energy_to_db(energy), 0, 7)                // loud=aroused
  T = pitch_to_temporal(pitch)                             // 0-3

  return pack(S, R, V, A, T)
```

---

# 3. HARDWARE/SYSTEM (INTEROCEPTION)

## 3.1 Linux /proc Filesystem

### /proc/loadavg

```
Read: cat /proc/loadavg
Format: "0.32 0.45 0.51 2/347 12345"
Fields: load_1min load_5min load_15min running/total last_pid

load = average number of processes in run queue.
load / num_cpus = utilization ratio.

SRVAT mapping:
  load_ratio = load_1min / num_cpus
  A = clamp(round(load_ratio × 7), 0, 7)  // system stress → arousal
  V = 7 - A  // inverse: high load = negative valence
  If load_1min > load_15min: system heating up → T=3 (fast change)
  If load_1min < load_15min: cooling down → T=1 (slow change)
  If equal: stable → T=0
```

### /proc/meminfo

```
Read: cat /proc/meminfo
Key fields:
  MemTotal:     16384000 kB
  MemFree:       2048000 kB
  MemAvailable:  8192000 kB
  Buffers:        512000 kB
  Cached:        4096000 kB
  SwapTotal:     8192000 kB
  SwapFree:      8000000 kB

Actual free = MemAvailable (includes reclaimable cache)
Memory pressure = 1 - (MemAvailable / MemTotal)

SRVAT:
  pressure = 1 - (MemAvailable / MemTotal)
  S = 0 (not shape-relevant)
  R = quantize(Cached / MemTotal × 15, 0, 15)  // cache utilization
  V = round((1 - pressure) × 7)  // low pressure = positive
  A = round(pressure × 7)         // high pressure = high arousal
  T = delta(pressure) → 0-3       // rate of change
```

### /proc/stat

```
Read: cat /proc/stat
First line: "cpu  user nice system idle iowait irq softirq steal"

CPU usage calculation:
  total = user + nice + system + idle + iowait + irq + softirq + steal
  idle_total = idle + iowait
  usage = 1 - (idle_total / total)

  For delta (between two reads):
  Δtotal = total_now - total_prev
  Δidle = idle_now - idle_prev
  usage = 1 - (Δidle / Δtotal)

SRVAT:
  S = num_cores (hardware shape, constant)
  R = quantize(system / (user + system), 0, 15)  // kernel vs user ratio
  V = round((1 - usage) × 7)   // idle = positive
  A = round(usage × 7)          // busy = high arousal
  T = delta(usage) → 0-3
```

## 3.2 Temperature, Disk, Network

### CPU Temperature

```
Read: cat /sys/class/thermal/thermal_zone0/temp
Returns: millidegrees Celsius (e.g., 45000 = 45°C)

temp_C = value / 1000

Safe ranges: <60°C normal, 60-80°C warm, >80°C hot, >95°C throttle

SRVAT:
  V = (100 - temp_C) / 100 × 7   // hot = negative
  A = max(0, (temp_C - 50) / 50 × 7)  // above 50°C → arousal increases
```

### Disk I/O

```
Read: cat /proc/diskstats
Fields per device: ... reads_completed read_sectors writes_completed write_sectors ...

Throughput = Δsectors × 512 / Δtime  (bytes/sec)
IOPS = Δ(reads + writes) / Δtime

Read: cat /proc/self/io
Fields: read_bytes, write_bytes (per-process)

SRVAT:
  R = quantize(read_throughput, 0, 15)
  A = quantize(write_throughput / max_throughput, 0, 7)
```

### Network Throughput

```
Read: cat /proc/net/dev
Fields per interface: ... rx_bytes rx_packets ... tx_bytes tx_packets ...

Throughput = Δbytes / Δtime
Packet rate = Δpackets / Δtime

SRVAT:
  S = interface_type (lo=0, eth=5, wlan=10, etc.)
  R = quantize(packet_rate, 0, 15)
  V = (rx > tx) → 5 (receiving = positive), (tx > rx) → 3
  A = quantize(throughput / max_bandwidth, 0, 7)
  T = delta(throughput) → 0-3
```

## 3.3 GPIO for IoT

```
Linux GPIO interface (/sys/class/gpio/):
  Export: echo 17 > /sys/class/gpio/export
  Direction: echo "out" > /sys/class/gpio/gpio17/direction
  Write: echo 1 > /sys/class/gpio/gpio17/value
  Read: cat /sys/class/gpio/gpio17/value

Modern: libgpiod / /dev/gpiochipN
  gpiod_chip_open("/dev/gpiochip0")
  gpiod_chip_get_line(chip, 17)
  gpiod_line_request_output(line, "nox", 0)
  gpiod_line_set_value(line, 1)

Common protocols over GPIO:
  I2C: SCL (clock) + SDA (data), up to 3.4 Mbps
    Sensors: temperature, humidity, accelerometer, light
  SPI: SCLK + MOSI + MISO + CS, up to 100 Mbps
    Displays, SD cards, high-speed sensors
  1-Wire: single data line + ground
    Temperature sensors (DS18B20)

SRVAT: each GPIO reading → P_weight based on sensor type.
  Temperature sensor → V (warm=positive), A (extreme=high arousal)
  Light sensor → S (brightness), V (warm light=positive)
  Motion sensor → T (motion detected = high T)
  Accelerometer → S (orientation), A (vibration intensity)
```

## 3.4 Camera Interfaces

### V4L2 (Video4Linux2)

```
Open: fd = open("/dev/video0", O_RDWR)
Query capabilities: ioctl(fd, VIDIOC_QUERYCAP, &cap)
Set format: ioctl(fd, VIDIOC_S_FMT, &fmt)
  fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE
  fmt.fmt.pix.width = 640
  fmt.fmt.pix.height = 480
  fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUYV  // or MJPEG

Streaming (mmap):
  1. Request buffers: ioctl(fd, VIDIOC_REQBUFS, &req)
  2. Map buffers: mmap(NULL, buf.length, PROT_READ|PROT_WRITE, MAP_SHARED, fd, buf.m.offset)
  3. Queue buffer: ioctl(fd, VIDIOC_QBUF, &buf)
  4. Start: ioctl(fd, VIDIOC_STREAMON, &type)
  5. Dequeue: ioctl(fd, VIDIOC_DQBUF, &buf)  // blocks until frame ready
  6. Process frame in buffer
  7. Re-queue and repeat

YUYV → RGB conversion:
  Y0 U Y1 V → 2 RGB pixels
  R = Y + 1.402 × (V - 128)
  G = Y - 0.344 × (U - 128) - 0.714 × (V - 128)
  B = Y + 1.772 × (U - 128)
```

### ONVIF (for IP cameras)

```
Protocol: SOAP over HTTP
Discovery: WS-Discovery multicast to 239.255.255.250:3702
Stream: RTSP (Real-Time Streaming Protocol)
  rtsp://camera_ip:554/stream1

For Nox: use HTTP GET on snapshot URL:
  http://camera_ip/onvif/snapshot
  Returns JPEG image.
  Parse JPEG → pixels → same pipeline as V4L2.

No ONVIF library needed — just HTTP + JPEG decode.
JPEG decode (minimal): find SOF marker → read dimensions → decode Huffman → IDCT → pixels.
```

## 3.5 USB HID

```
Linux: /dev/hidrawN or /dev/input/eventN

Read raw HID:
  fd = open("/dev/hidraw0", O_RDONLY)
  read(fd, buf, sizeof(buf))
  // buf contains HID report

Input event structure (input_event):
  struct input_event {
    struct timeval time;   // timestamp
    __u16 type;            // EV_KEY, EV_REL, EV_ABS
    __u16 code;            // KEY_A, REL_X, ABS_X
    __s32 value;           // 0=release, 1=press, 2=repeat / axis value
  }

Key types:
  EV_KEY (0x01): keyboard/button events
  EV_REL (0x02): relative movement (mouse dx, dy)
  EV_ABS (0x03): absolute position (touchscreen, tablet)
  EV_SYN (0x00): synchronization (frame boundary)

SRVAT:
  Keyboard: S=key_position_on_keyboard, R=modifier_state, V/A from typing speed
  Mouse: S=position, R=button_state, A=speed (fast movement = high arousal)
  For Nox's uinput output: reverse mapping P_weight → input events.
```

## 3.6 System Metrics → SRVAT

```
Complete interoception pipeline:

system_interoception():
  // Read all system metrics
  load = parse_loadavg("/proc/loadavg")
  mem = parse_meminfo("/proc/meminfo")
  cpu = parse_stat("/proc/stat")
  temp = read_int("/sys/class/thermal/thermal_zone0/temp") / 1000
  net = parse_netdev("/proc/net/dev")
  disk = parse_diskstats("/proc/diskstats")

  // Compose into single system P_weight
  cpu_pw = pack(cpu.cores, cpu.kernel_ratio, cpu.idle_v, cpu.usage_a, cpu.delta_t)
  mem_pw = pack(0, mem.cache_r, mem.free_v, mem.pressure_a, mem.delta_t)
  temp_pw = pack(0, 0, temp.v, temp.a, 0)
  net_pw = pack(net.type_s, net.packet_r, net.direction_v, net.throughput_a, net.delta_t)

  // Compose all: Zipf-weighted (CPU most important)
  system_mol = compose_chain([cpu_pw, mem_pw, temp_pw, net_pw])

  return system_mol  // Single u16 representing system state

Update frequency: every 5 seconds (not too fast, not too slow).
Store in STM: system_mol with timestamp → track system health over time.
If system_mol.A > 5 for 3 consecutive reads → alert (system stress).
```

---

# 4. OPTIMAL SEARCH ALGORITHMS

## 4.1 Fibonacci Search

```
Paper: Kiefer (1953), "Sequential Minimax Search for a Maximum"
Complexity: O(log_φ n) ≈ O(1.44 × log₂ n)

For sorted array A[0..n-1], searching for key:

  // Precompute Fibonacci numbers
  fib_m2 = 0   // F(m-2)
  fib_m1 = 1   // F(m-1)
  fib_m  = 1   // F(m)

  while fib_m < n:
    fib_m2 = fib_m1
    fib_m1 = fib_m
    fib_m = fib_m1 + fib_m2

  offset = 0

  while fib_m > 1:
    i = min(offset + fib_m2 - 1, n - 1)

    if A[i] < key:
      fib_m = fib_m1
      fib_m1 = fib_m2
      fib_m2 = fib_m - fib_m1
      offset = i + 1
    elif A[i] > key:
      fib_m = fib_m2
      fib_m1 = fib_m1 - fib_m2
      fib_m2 = fib_m - fib_m1
    else:
      return i  // found

  // Check last element
  if fib_m1 and offset < n and A[offset] == key:
    return offset
  return -1  // not found

Why better than binary search for Nox:
  - Uses ADDITION not DIVISION (cheaper on simple hardware)
  - Probe positions at φ⁻¹ point → matches P_weight natural hierarchy
  - Sequential access pattern → better for disk-backed KnowTree
```

## 4.2 Interpolation Search

```
Paper: Peterson (1957), "Addressing for Random-Access Storage"
Complexity: O(log log n) average for uniform distribution, O(n) worst case

For sorted array A[0..n-1]:

  lo = 0
  hi = n - 1

  while lo <= hi and key >= A[lo] and key <= A[hi]:
    if lo == hi:
      return lo if A[lo] == key else -1

    // Interpolate position
    pos = lo + ((key - A[lo]) × (hi - lo)) / (A[hi] - A[lo])

    if A[pos] < key:
      lo = pos + 1
    elif A[pos] > key:
      hi = pos - 1
    else:
      return pos

  return -1

SRVAT mapping:
  P_weight values are u16 (0..65535).
  Distribution is NOT uniform (clustered by block).
  → Interpolation search works well WITHIN a bucket (similar S,R values).
  → Poor for cross-bucket search (use silk walk instead).
```

## 4.3 Ternary Search

```
Complexity: O(log₃ n) ≈ O(2 × log₃ n) comparisons = O(1.26 × log₂ n)
But: 2 comparisons per step vs 1 for binary → actually slower for sorted search.

For finding MAXIMUM of unimodal function f(x) on [lo, hi]:

  while hi - lo > epsilon:
    m1 = lo + (hi - lo) / 3
    m2 = hi - (hi - lo) / 3

    if f(m1) < f(m2):
      lo = m1
    else:
      hi = m2

  return (lo + hi) / 2

Use case for Nox: finding optimal silk weight threshold.
  f(threshold) = search_quality (unimodal: too low = noise, too high = miss)
  Ternary search finds optimal threshold in O(log n) evaluations.
```

## 4.4 Jump Search

```
Paper: (folklore, optimal block size by Shneiderman, 1978)
Complexity: O(√n)

For sorted array A[0..n-1]:
  step = floor(√n)
  prev = 0

  // Jump ahead in blocks of √n
  while A[min(step, n) - 1] < key:
    prev = step
    step += floor(√n)
    if prev >= n:
      return -1

  // Linear search in block [prev, min(step, n))
  while A[prev] < key:
    prev += 1
    if prev == min(step, n):
      return -1

  return prev if A[prev] == key else -1

SRVAT: useful for KnowTree bucket scan where data is on disk.
  Jump = skip cold cache lines. Linear = scan hot cache line.
  Optimal block = √n ≈ 128 for 16K entries per bucket.
```

## 4.5 Exponential Search

```
Paper: Bentley & Yao (1976), "An Almost Optimal Algorithm for Unbounded Searching"
Complexity: O(log i) where i = position of target

For sorted array A[0..n-1]:
  // Find range
  bound = 1
  while bound < n and A[bound] < key:
    bound *= 2

  // Binary search in [bound/2, min(bound, n-1)]
  return binary_search(A, key, bound / 2, min(bound, n - 1))

Best when: target is near the beginning (small i).
SRVAT: perfect for searching recent entries in append-only QR log.
  Recent QR near end → exponential search from end → O(log k) for k entries ago.
```

## 4.6 Optimal Search for 5D Integer Space (32K values)

```
Problem: search in 5D space where P_weight = u16 (65536 possible, ~32K active).

Analysis of options:
  - Linear scan: O(32K) = too slow per query
  - 5D kd-tree: O(log 32K) ≈ O(15) per query, O(32K) build
    BUT: curse of dimensionality — at 5D, kd-tree degrades
  - HNSW: O(log 32K) with good constants, BUT 50KB+ memory overhead
  - Bucket index: O(bucket_size) per query, O(1) with hashing

★ OPTIMAL FOR NOX: Bucket index on (S, R) + linear scan within bucket.

Rationale:
  S has 16 values (4 bits), R has 16 values (4 bits)
  → 256 buckets maximum
  32K values / 256 buckets = 125 values per bucket average

  Search by (S, R):
    bucket = S × 16 + R    // O(1)
    Linear scan 125 entries comparing V, A, T  // O(125)
    Total: O(125) ≈ O(1) effectively

  Search by dominant dimension:
    If V-dominant: scan V-sorted index → O(32K/7) ≈ O(4.5K)
    Better: secondary index by V → 8 lists → O(4K/8) = O(500)

  Multi-index approach (Nox current plan per G1):
    Primary: (S, R) → 256 buckets, 16×16 array
    Within bucket: sorted by V → binary search → O(log 125) ≈ O(7)
    Total: O(1) + O(7) = O(8) per query

  For nearest-neighbor (not exact match):
    Search bucket (S, R) + 8 neighboring buckets (S±1, R±1)
    9 buckets × 125 entries = 1125 comparisons
    distance_5d for each → keep top K
    Total: O(1125) ≈ constant time

    With Fibonacci refinement:
    Check center bucket first.
    If best distance < 0.3 → done.
    Else expand search radius in Fibonacci spiral: 1, 1, 2, 3, 5 buckets away.
    Early termination when distance can't improve.

WINNER: Bucket(S,R) + V-sorted linear + Fibonacci expansion.
  Average: O(8). Worst: O(1125). Memory: 256 bucket headers = 512 bytes.
```

---

# 5. STRING/TEXT PROCESSING

## 5.1 Rabin-Karp Rolling Hash

```
Paper: Rabin & Karp (1987), "Efficient Randomized Pattern-Matching Algorithms"
Complexity: O(n + m) average, O(nm) worst case. n=text, m=pattern.

Hash function (polynomial rolling hash):
  h(s[0..m-1]) = (s[0] × d^(m-1) + s[1] × d^(m-2) + ... + s[m-1]) mod q
  where d = alphabet size (256 for bytes), q = large prime (e.g., 1000000007)

Rolling update (slide window by 1):
  h(s[i+1..i+m]) = (d × (h(s[i..i+m-1]) - s[i] × d^(m-1)) + s[i+m]) mod q

Algorithm:
  hp = hash(pattern)
  ht = hash(text[0..m-1])

  for i in 0..n-m:
    if ht == hp:
      if text[i..i+m-1] == pattern:  // verify (avoid false positives)
        return i
    if i < n - m:
      ht = roll(ht, text[i], text[i+m])

  return -1

Multi-pattern: compute hash of each pattern → hash set lookup. O(n × k) average for k patterns.

SRVAT mapping:
  Rolling hash of text ≈ running P_weight compose.
  Both are sliding window operations that incrementally update.
  hash(window) ↔ compose_chain(window_chars)
  Match ↔ distance_5d < threshold
```

## 5.2 KMP (Knuth-Morris-Pratt)

```
Paper: Knuth, Morris, Pratt (1977), "Fast Pattern Matching in Strings", SIAM J Computing
Complexity: O(n + m) guaranteed. O(m) preprocessing, O(n) search.

Failure function (prefix table):
  π[0] = 0
  k = 0
  for i in 1..m-1:
    while k > 0 and pattern[k] != pattern[i]:
      k = π[k-1]
    if pattern[k] == pattern[i]:
      k += 1
    π[i] = k

  π[i] = length of longest proper prefix of pattern[0..i] that is also a suffix.

Search:
  k = 0  // matched characters
  for i in 0..n-1:
    while k > 0 and pattern[k] != text[i]:
      k = π[k-1]  // fall back
    if pattern[k] == text[i]:
      k += 1
    if k == m:
      found at position i - m + 1
      k = π[k-1]  // continue searching

Example:
  pattern = "ABCABD"
  π = [0, 0, 0, 1, 2, 0]

  When mismatch at position 5 (D vs X):
  k = π[4] = 2 → jump to comparing pattern[2] (C) next
  Skip re-comparing the "AB" prefix we already matched.

SRVAT:
  Failure function ≈ chain compression.
  Repeated sub-patterns in text → same P_weight sub-chains.
  KMP skips = silk shortcut (jump to matching node without re-traversal).
```

## 5.3 Aho-Corasick

```
Paper: Aho & Corasick (1975), "Efficient String Matching: An Aid to Bibliographic Search", CACM
Complexity: O(n + m + z) where z = number of matches. Preprocessing O(Σm_i).

Data structure: trie + failure links + output links.

Build:
  1. Insert all patterns into trie (goto function)
  2. BFS from root to compute failure links:
     fail(root) = root
     For each node u in BFS order, for each child v of u via char c:
       f = fail(u)
       while f != root and f has no child c:
         f = fail(f)
       fail(v) = f.child(c) if exists, else root
  3. Output links: output(v) = output(fail(v)) ∪ {pattern_at_v if v is terminal}

Search:
  state = root
  for i in 0..n-1:
    while state != root and state has no child text[i]:
      state = fail(state)
    if state has child text[i]:
      state = state.child(text[i])
    // Report all patterns ending here
    temp = state
    while temp != root:
      if temp is terminal: report match
      temp = output(temp)

Use case for Nox:
  Multi-pattern matching for security keywords, command prefixes.
  SecurityGate: scan input against all known dangerous patterns in one pass.
  Build trie once → O(n) per input regardless of pattern count.

SRVAT:
  Trie structure ≈ KnowTree.
  Each trie node = partial chain match.
  Failure links ≈ silk edges (alternative paths to related patterns).
  Output links ≈ fire propagation (finding matches triggers actions).
```

## 5.4 Suffix Array

```
Paper: Manber & Myers (1993), "Suffix Arrays: A New Method for On-line String Searches"
Complexity: O(n log n) build (or O(n) with SA-IS), O(m log n) search

Suffix array SA[i] = starting position of i-th smallest suffix.

Example: "banana$"
  Suffixes sorted: $, a$, ana$, anana$, banana$, na$, nana$
  SA = [6, 5, 3, 1, 0, 4, 2]

Build (prefix doubling, O(n log²n) simple version):
  1. Rank suffixes by first character
  2. For k = 1, 2, 4, 8, ...:
     Sort by (rank[i], rank[i+k]) — first 2k characters
     Update ranks based on new sort order
     Stop when all ranks unique

Search for pattern P of length m:
  Binary search on SA:
  lo = 0, hi = n - 1
  while lo <= hi:
    mid = (lo + hi) / 2
    cmp = compare(text[SA[mid]..], P)
    if cmp < 0: lo = mid + 1
    elif cmp > 0: hi = mid - 1
    else: found at SA[mid]

LCP array (Longest Common Prefix):
  LCP[i] = length of longest common prefix between SA[i-1] and SA[i]
  Build in O(n) with Kasai's algorithm.
  Enables O(m + log n) search and many string operations.

SA-IS (linear time):
  Paper: Nong, Zhang, Chan (2009), "Two Efficient Algorithms for Linear Time Suffix Array Construction"
  Complexity: O(n) time and space.

SRVAT:
  Suffix array of a text = all possible sub-chains indexed.
  Binary search on SA ↔ bucket lookup in KnowTree.
  For compiler: suffix array of source code → instant substring lookup.
  For Nox's self-modification: find all occurrences of a code pattern.
```

## 5.5 Burrows-Wheeler Transform (BWT)

```
Paper: Burrows & Wheeler (1994), "A Block-Sorting Lossless Data Compression Algorithm"
Complexity: O(n) with SA-IS, O(n log n) simple

Forward transform:
  1. All rotations of string (conceptually n×n matrix)
  2. Sort rotations lexicographically
  3. BWT = last column of sorted matrix

  In practice: BWT[i] = text[(SA[i] - 1) mod n]
  (Character BEFORE each suffix in sorted order)

Example: "banana$"
  Rotations sorted: $banana, a$banan, ana$ban, anana$b, banana$, na$bana, nana$ba
  Last column: "annb$aa"
  BWT("banana$") = "annb$aa"

Key property: characters cluster by context → better compression.
  "annb$aa" compresses better than "banana$" because
  repeated contexts produce runs of same character.

Inverse transform (O(n)):
  1. C[c] = count of characters < c in BWT
  2. Occ[c][i] = count of character c in BWT[0..i-1]
  3. LF mapping: LF(i) = C[BWT[i]] + Occ[BWT[i]][i]
  4. Reconstruct: start from $ position, follow LF repeatedly

  text[n-1-k] = BWT[i]
  i = LF(i)
  Repeat n times.

FM-index (Ferragina & Manzini, 2000):
  BWT + rank/select → compressed full-text index
  Search pattern P in O(m) time using backward search:
    lo = 0, hi = n - 1
    for i = m-1 down to 0:
      lo = C[P[i]] + Occ[P[i]][lo]
      hi = C[P[i]] + Occ[P[i]][hi + 1] - 1
    Count = hi - lo + 1

SRVAT:
  BWT clustering ≈ chain clustering in KnowTree.
  Similar contexts → similar P_weights → same bucket.
  FM-index pattern = O(m) search without scanning all text.
  For Nox self-hosting compiler: BWT index of source → instant code search.
```

## 5.6 Text Processing for Self-Hosting Compiler

```
Nox's compiler processes Olang source code. Key operations:

1. Lexing: source → tokens
   Current: character-by-character state machine. O(n).
   Optimization: use perfect hash for keywords (computed at compile time).
   ~30 keywords → minimal perfect hash → O(1) keyword lookup.

2. Parsing: tokens → AST
   Current: recursive descent. O(n).
   Key insight: NO regex needed. All Olang syntax is context-free.

3. String interning:
   Dedup identical strings → single pointer.
   Hash table: FNV-1a hash (fast, good distribution for short strings).
   FNV-1a: hash = offset_basis
            for each byte: hash = hash XOR byte; hash = hash × FNV_prime
   32-bit: offset = 2166136261, prime = 16777619

4. Source → P_weight (for self-modification search):
   Each function → encode → P_weight → store in compiler's own KnowTree.
   "Find similar functions" = nearest-neighbor in P_weight space.
   Refactoring = find nodes with distance_5d < 0.3 → candidates for merging.
```

---

# 6. LLM ARCHITECTURE CONCEPTS

## 6.1 Transformer Attention

```
Paper: Vaswani et al. (2017), "Attention Is All You Need", NeurIPS
Complexity: O(n² × d) where n = sequence length, d = embedding dimension

Scaled Dot-Product Attention:
  Attention(Q, K, V) = softmax(Q × Kᵀ / √d_k) × V

  Q = query matrix  (n × d_k)  — "what am I looking for?"
  K = key matrix    (n × d_k)  — "what do I contain?"
  V = value matrix  (n × d_v)  — "what information do I provide?"

  Step by step:
  1. Compute scores: S = Q × Kᵀ         // (n × n) matrix
  2. Scale: S = S / √d_k                 // prevent softmax saturation
  3. Softmax: A = softmax(S, dim=-1)     // row-wise, each row sums to 1
  4. Output: O = A × V                    // weighted sum of values

  softmax(x_i) = e^(x_i) / Σ_j e^(x_j)

Multi-Head Attention:
  head_i = Attention(Q × W_i^Q, K × W_i^K, V × W_i^V)
  MultiHead(Q, K, V) = Concat(head_1, ..., head_h) × W^O

  Typically: d_model = 512, h = 8 heads, d_k = d_v = d_model/h = 64

Self-Attention: Q = K = V = same input (each position attends to all others).
Cross-Attention: Q from one sequence, K/V from another.

SRVAT comparison:
  Attention score ≈ silk weight.
  Q×Kᵀ ≈ distance_5d(node_a, node_b)
  softmax ≈ normalize silk weights to sum to 1
  V matrix ≈ P_weight content at each node
  A×V ≈ compose_chain along silk walk (weighted by silk weights)

  KEY DIFFERENCE:
  Attention: O(n²) — every token attends to every other token.
  Silk walk: O(degree × depth) — only connected nodes, typically O(20 × 5) = O(100).
  Nox's approach is SPARSE attention — only attend to silk-connected nodes.
  This is equivalent to attention with a fixed sparse mask.
```

## 6.2 Tokenization

### BPE (Byte Pair Encoding)

```
Paper: Sennrich et al. (2016), "Neural Machine Translation of Rare Words with Subword Units"
(Original BPE: Gage, 1994)
Complexity: O(n × V) per merge, V = vocab size

Training:
  1. Start with character-level vocabulary
  2. Count all adjacent pairs in corpus
  3. Merge most frequent pair into new token
  4. Repeat until vocab_size reached (e.g., 50K)

Example:
  Corpus: "low lower lowest"
  Initial: l o w </w>, l o w e r </w>, l o w e s t </w>
  Most frequent pair: (l, o) → merge to "lo"
  Then: (lo, w) → "low"
  Then: (low, e) → "lowe"
  ...

Encoding (given trained merges):
  Split word into characters.
  Repeatedly apply highest-priority merge.

GPT uses byte-level BPE: start from 256 byte values, not characters.
```

### SentencePiece

```
Paper: Kudo & Richardson (2018), "SentencePiece: A simple and language independent subword tokenizer"
Complexity: O(n²) training via EM, O(n) encoding via Viterbi

Unigram model:
  P(x) = Π_{i=1}^{M} P(x_i)  // probability of segmentation
  Viterbi: find segmentation maximizing P(x)
  
  Training: start with large vocab, iteratively remove tokens
  that least affect overall likelihood.

Advantage: language-agnostic (treats input as raw bytes/characters).
No pre-tokenization (spaces are just another character: ▁ prefix).

SRVAT comparison:
  BPE tokens ≈ chains in KnowTree.
  Common word = single token = single P_weight.
  Rare word = multiple sub-tokens = chain of P_weights composed.
  KEY DIFFERENCE: BPE has fixed vocab. P_weight has fixed SPACE (u16).
  Any input maps to a P_weight. No OOV (out-of-vocabulary) problem.
```

### WordPiece

```
Paper: Schuster & Nakajima (2012), "Japanese and Korean Voice Search"
Used by: BERT

Like BPE but merge criterion = maximize likelihood of training data:
  score(a, b) = freq(ab) / (freq(a) × freq(b))
  Merge pair with highest score (not highest frequency).

Encoding: greedy longest-match-first from left.
  "unaffable" → ["un", "##aff", "##able"]
  "##" prefix marks continuation tokens.
```

## 6.3 Embeddings

### Word2Vec

```
Paper: Mikolov et al. (2013), "Efficient Estimation of Word Representations in Vector Space"
Complexity: O(V × d) per training step, V = vocab, d = embedding dimension

Two architectures:

CBOW (Continuous Bag of Words):
  Input: context words (window of ±k words)
  Output: predict center word
  P(w_t | w_{t-k}, ..., w_{t+k}) = softmax(W' × mean(W × one_hot(context)))

Skip-gram:
  Input: center word
  Output: predict context words
  P(w_{t+j} | w_t) = softmax(W' × W × one_hot(w_t))

  Training with negative sampling:
  L = log σ(v'_{w_O}ᵀ v_{w_I}) + Σ_{i=1}^{k} E[log σ(-v'_{w_i}ᵀ v_{w_I})]
  σ = sigmoid, k = number of negative samples (5-20)
  Sample negative words proportional to frequency^(3/4)

Famous result: vector("king") - vector("man") + vector("woman") ≈ vector("queen")
This works because embeddings capture semantic relationships as directions.

Typical: d = 300 dimensions. Vocab = 3M words. Model = 3.6 GB.

SRVAT comparison:
  Word2Vec embedding: 300D floating point → 1200 bytes per word.
  P_weight: 5D integer → 2 bytes per word.
  Word2Vec captures more nuance BUT requires massive training data.
  P_weight captures LESS nuance BUT works from character properties alone.
  
  Analogy operation:
  Word2Vec: v(king) - v(man) + v(woman)
  SRVAT: pack(king) - pack(man) + pack(woman)
    → Won't work naively because P_weight is bit-packed.
    → BUT: unpack → 5D arithmetic → repack DOES work for dimension-wise analogy.
    unpack(king) = [S1, R1, V1, A1, T1]
    unpack(man)  = [S2, R2, V2, A2, T2]
    delta = [S1-S2, R1-R2, V1-V2, A1-A2, T1-T2]
    result = [S3+delta_S, R3+delta_R, V3+delta_V, A3+delta_A, T3+delta_T]
    (where [S3...] = unpack(woman))
```

### GloVe

```
Paper: Pennington et al. (2014), "GloVe: Global Vectors for Word Representation", EMNLP
Complexity: O(|X|) per iteration, |X| = non-zero entries in co-occurrence matrix

Key insight: word relationships should be captured by RATIOS of co-occurrence probabilities.
  P(ice | solid) / P(ice | gas) >> 1   (ice relates to solid, not gas)
  P(steam | solid) / P(steam | gas) << 1

Objective:
  J = Σ_{i,j=1}^{V} f(X_ij) × (w_i^T × w̃_j + b_i + b̃_j - log X_ij)²

  X_ij = co-occurrence count of words i, j
  f(x) = { (x/x_max)^α  if x < x_max    // α = 0.75, x_max = 100
          { 1             otherwise

  Minimizes: difference between dot product and log co-occurrence.
  Trained by SGD/AdaGrad.

SRVAT:
  GloVe captures global statistics. P_weight captures character-level properties.
  For Nox: the SILK WEIGHTS serve the same role as co-occurrence statistics.
  silk_weight(A, B) ↔ log(X_AB) in GloVe.
  Hebbian learning: fire together → strengthen edge ↔ co-occurrence counting.
```

## 6.4 What SRVAT Does Differently

```
LLM approach:
  1. Tokenize text → token IDs (integers, no meaning)
  2. Embed tokens → high-dimensional vectors (learned, opaque)
  3. Self-attention → context-aware representations (O(n²))
  4. Feedforward → output logits (more learned weights)
  5. Decode → text

  Parameters: billions. Training: weeks on GPU clusters. Model: gigabytes.
  Meaning is LEARNED from data, stored in weights, opaque.

SRVAT approach:
  1. Encode text → P_weights (u16, COMPUTED from character properties)
  2. Compose chain → sentence P_weight (Zipf-weighted, O(n))
  3. Silk walk → related nodes (O(degree × depth), sparse)
  4. Hebbian update → strengthen/weaken connections (O(degree))
  5. Decode → text via KnowTree lookup (O(log n))

  Parameters: ~200KB (UDC table + silk edges). Training: continuous, online.
  Model: 949KB total. Meaning is COMPUTED, transparent, verifiable.

Key advantages of SRVAT:
  - No training phase (works from first input)
  - No GPU needed (integer arithmetic only)
  - Transparent (can inspect every P_weight and explain why)
  - Self-modifying (compiler can change its own encode/compose logic)
  - 949KB vs 7-70GB (10,000-100,000× smaller)

Key disadvantages of SRVAT:
  - 5 dimensions vs 300+ → less nuance per token
  - No implicit world model (LLM stores world knowledge in weights)
  - Requires explicit learning (silk edges built one by one)
  - Currently no multi-step reasoning chain (LLMs do this via attention layers)

What Nox should learn FROM LLMs:
  1. Attention as WEIGHTED GRAPH WALK — already silk walk
  2. Multi-head = multiple parallel walks with different dimension emphasis
     → Nox can do 5 parallel silk walks: S-focused, R-focused, V-focused, A-focused, T-focused
  3. Residual connections = keep original input alongside transformations
     → Nox: WM[0] = original query, WM[2] = current candidate, compare
  4. Layer normalization = keep values in bounded range
     → P_weight already bounded by bit layout (automatic normalization)
  5. Positional encoding = inject position info
     → Nox: T dimension and Zipf weights already encode position
```

## 6.5 Attention as Weighted Graph Walk

```
Reframing attention in graph terms:

  Attention matrix A = adjacency matrix of complete weighted graph.
  A[i][j] = softmax(q_i · k_j / √d_k)

  For token i, attention computes:
  output_i = Σ_j A[i][j] × v_j
  = weighted average of ALL other tokens' values.

  Silk walk equivalent:
  For node i, silk response computes:
  output_i = Σ_{j ∈ neighbors(i)} silk_weight(i,j) × P_weight(j)
  = weighted average of CONNECTED nodes' values.

  Attention: dense graph (complete). O(n²).
  Silk: sparse graph (Hebbian-connected). O(degree).

  Making silk more attention-like:
  "Soft attention" = consider ALL nodes but exponentially decay by distance:
    weight(i,j) = exp(-distance_5d(i,j)² / temperature)
  Normalize: weight(i,j) /= Σ_k weight(i,k)
  This IS softmax attention in 5D P_weight space.

  Temperature controls sparsity:
    temp → 0: hard attention (only nearest neighbor)
    temp → ∞: uniform attention (all nodes equal)
    temp = 1.0: standard softmax

  For Nox: start with hard attention (current silk walk).
  Gradually add soft attention for exploration (discover new connections).
  Use Homeostasis to balance: exploitation (hard) vs exploration (soft).
```

---

# 7. COMPRESSION/ENCODING

## 7.1 Huffman Coding

```
Paper: Huffman (1952), "A Method for the Construction of Minimum-Redundancy Codes"
Complexity: O(n log n) build, O(n) encode/decode

Algorithm:
  1. Count frequency of each symbol
  2. Create leaf node for each symbol with its frequency
  3. Insert all nodes into priority queue (min-heap)
  4. While queue has > 1 node:
     a. Extract two minimum-frequency nodes (A, B)
     b. Create internal node C with freq = freq(A) + freq(B)
     c. C.left = A, C.right = B
     d. Insert C into queue
  5. Remaining node = root of Huffman tree

Encoding: traverse tree from root to leaf.
  Left = 0, Right = 1.
  Frequent symbols → short codes, rare → long codes.

Optimality: Huffman is optimal among prefix codes.
  Average code length: L = Σ p_i × l_i
  Bounded: H(X) ≤ L < H(X) + 1
  H(X) = -Σ p_i × log₂(p_i) = entropy

Canonical Huffman (for compact storage):
  Sort by code length, then alphabetically within same length.
  Only need to store code lengths per symbol (not the tree).
  Reconstruct codes: first code of length l = (first of length l-1 + count of length l-1) << 1

SRVAT:
  Huffman on P_weight chains:
  Frequent P_weights (common words) → short bit codes.
  Rare P_weights → long bit codes.
  Compress KnowTree disk storage significantly.
  Also: Huffman structure ≈ KnowTree structure (frequent = near root, rare = leaves).
```

## 7.2 Arithmetic Coding

```
Paper: Rissanen (1976), "Generalized Kraft Inequality and Arithmetic Coding"
       Witten, Neal, Cleary (1987), "Arithmetic Coding for Data Compression"
Complexity: O(n) encode/decode

Concept: encode ENTIRE message as single number in [0, 1).

Algorithm:
  lo = 0.0, hi = 1.0

  For each symbol s in message:
    range = hi - lo
    hi = lo + range × cumulative_prob(s + 1)
    lo = lo + range × cumulative_prob(s)

  Output: any number in final [lo, hi)
  Bits needed ≈ -log₂(hi - lo) ≈ H(message)

Example:
  Alphabet: A (0.6), B (0.2), C (0.2)
  Cumulative: A=[0, 0.6), B=[0.6, 0.8), C=[0.8, 1.0)
  Message: "BAC"
    B: lo=0.6, hi=0.8
    A: lo=0.6, hi=0.6+0.2×0.6=0.72
    C: lo=0.6+0.12×0.8=0.696, hi=0.72
  Output: any value in [0.696, 0.72), e.g., 0.7 = binary 0.1011...

Advantage over Huffman: can approach entropy EXACTLY.
Huffman wastes up to 1 bit per symbol. Arithmetic coding: < 2 bits total overhead.

Integer implementation (for Nox, no floating point):
  Use 32-bit integers. lo=0, hi=2^32-1.
  Renormalize when lo and hi share leading bits.

SRVAT:
  Arithmetic coding for chain storage: compress [u16, u16, u16, ...] chains.
  Frequent P_weight transitions → modeled by silk weights → better compression.
  Predictive: if silk predicts next P_weight, arithmetic coder can exploit that.
```

## 7.3 LZ77/LZ78/LZW

### LZ77

```
Paper: Ziv & Lempel (1977), "A Universal Algorithm for Sequential Data Compression"
Complexity: O(n × W) naive, O(n) with suffix tree. W = window size.

Concept: replace repeated sequences with (offset, length, next) references.

Sliding window:
  [search buffer | lookahead buffer]
  search buffer = W bytes of recently encoded data
  lookahead buffer = next L bytes to encode

For each position:
  Find longest match of lookahead in search buffer.
  Output triple: (offset_back, match_length, next_char)
  Advance by match_length + 1.

Example: "AABCBBABC"
  Position 0: no match → (0, 0, 'A')
  Position 1: 'A' matches at offset 1 → (1, 1, 'B')
  Position 3: 'C' no match → (0, 0, 'C')
  Position 4: 'BBABC'... 'B' matches offset 2 → (2, 1, 'B')
  Position 6: 'ABC' matches at offset 5 → (5, 3, end)

Used by: gzip, deflate, PNG, ZIP (LZ77 + Huffman)
```

### LZ78

```
Paper: Ziv & Lempel (1978), "Compression of Individual Sequences via Variable-Rate Coding"
Complexity: O(n)

Dictionary-based: build dictionary of seen phrases.
  Start with empty dictionary.
  
  Parse input into phrases:
  Each phrase = longest dictionary match + one new character.
  Output: (dictionary_index, new_character)
  Add new phrase to dictionary.

Example: "AABCBBABC"
  1: "" + A → (0, 'A'), dict[1] = "A"
  2: "A" + B → (1, 'B'), dict[2] = "AB"
  3: "" + C → (0, 'C'), dict[3] = "C"
  4: "" + B → (0, 'B'), dict[4] = "B"
  5: "B" + A → (4, 'A'), dict[5] = "BA"
  6: "AB" + C → (2, 'C'), dict[6] = "ABC"
```

### LZW (Lempel-Ziv-Welch)

```
Paper: Welch (1984), "A Technique for High-Performance Data Compression"
Complexity: O(n)

Improvement over LZ78: no explicit new character in output.

Encode:
  Initialize dictionary with all single characters (0-255).
  w = ""
  for c in input:
    if w + c in dictionary:
      w = w + c
    else:
      output dictionary[w]
      dictionary[w + c] = next_code
      w = c
  output dictionary[w]

Decode:
  Initialize dictionary with all single characters.
  prev = read code → output dictionary[prev]
  for each code:
    if code in dictionary:
      entry = dictionary[code]
    else:  // special case: code not yet in dictionary
      entry = dictionary[prev] + dictionary[prev][0]
    output entry
    dictionary[next_code] = dictionary[prev] + entry[0]
    prev = code

Used by: GIF, TIFF, Unix compress.

SRVAT:
  LZW dictionary ≈ KnowTree.
  New phrases = new chains. Dictionary indices = P_weight references.
  Repeated patterns in chains → compress with back-references.
  For QR log: LZ77-style compression on append-only log.
  Chain[i] = (offset_to_previous_similar, length, new_mol)
```

## 7.4 Delta Encoding for Time Series

```
Complexity: O(n) encode/decode

delta[0] = value[0]
delta[i] = value[i] - value[i-1]   for i > 0

Decode: value[i] = Σ_{j=0}^{i} delta[j]

Double delta (for approximately linear series):
  dd[0] = delta[0]
  dd[i] = delta[i] - delta[i-1]

If values change slowly, deltas are small → compress well with variable-length encoding.

Varint encoding for deltas:
  |delta| < 128: 1 byte (7 bits + sign)
  |delta| < 16384: 2 bytes (14 bits + sign)
  etc.

SRVAT:
  P_weight time series: system_mol every 5 seconds.
  Delta encode: most deltas = 0 or small → high compression.
  Store as: [base_mol, Δ₁, Δ₂, Δ₃, ...]
  V'(t) (derivative for learning) = literally the delta sequence.
  Double delta = V''(t) = acceleration of emotion change.
```

## 7.5 Bloom Filter

```
Paper: Bloom (1970), "Space/Time Trade-offs in Hash Coding with Allowable Errors"
Complexity: O(k) insert/query, k = number of hash functions

Structure: bit array of m bits, k hash functions.

Insert(x):
  for i in 0..k:
    bit[hash_i(x) mod m] = 1

Query(x):
  for i in 0..k:
    if bit[hash_i(x) mod m] == 0:
      return DEFINITELY_NOT_PRESENT
  return MAYBE_PRESENT

False positive rate: p ≈ (1 - e^(-kn/m))^k
Optimal k = (m/n) × ln(2) ≈ 0.693 × m/n

For n = 10000 items, p = 1% false positive:
  m = -n × ln(p) / (ln(2))² ≈ 96000 bits = 12 KB
  k = (m/n) × ln(2) ≈ 7

Implementation with only 2 hash functions (Kirsch & Mitzenmacher, 2006):
  hash_i(x) = hash_1(x) + i × hash_2(x)
  No loss of false positive rate.

SRVAT / SecurityGate:
  Bloom filter for known-dangerous P_weight patterns.
  Insert: all P_weights that triggered security violations.
  Query: new input P_weight → if MAYBE dangerous, do full check.
  False positives acceptable (just means extra security check).
  False negatives impossible (dangerous pattern NEVER passes through).
  12 KB for 10K patterns with 1% FP — fits in Nox's 949KB budget.
```

## 7.6 Count-Min Sketch

```
Paper: Cormode & Muthukrishnan (2005), "An Improved Data Stream Summary: The Count-Min Sketch"
Complexity: O(d) insert/query, d = number of hash functions (depth)

Structure: 2D array count[d][w], d hash functions.
  d = depth (accuracy), w = width (range)

Update(x, c):  // increment count of x by c
  for i in 0..d:
    count[i][hash_i(x) mod w] += c

Query(x):  // estimate count of x
  return min_{i=0..d-1} count[i][hash_i(x) mod w]

Guarantees:
  Always overestimates: Q(x) ≥ true_count(x)
  Error: P(Q(x) > true_count(x) + ε × N) < δ
  where N = total count, ε = e/w, δ = e^(-d)

Parameters for ε = 0.001, δ = 0.001:
  w = e/ε ≈ 2718
  d = ln(1/δ) ≈ 7
  Memory: 2718 × 7 × 4 bytes = 76 KB

SRVAT:
  Count P_weight frequencies without storing all P_weights.
  "How often does this P_weight pattern appear?" → O(1) approximate answer.
  For fire_count tracking: instead of per-node counter, use sketch.
  For Zipf weight estimation: frequency of word → Zipf rank → compose weight.
  76 KB for 0.1% error — acceptable for Nox.
```

---

# 8. CRYPTOGRAPHY

## 8.1 SHA-256

```
Paper: NIST FIPS PUB 180-4 (2015), "Secure Hash Standard"
Complexity: O(n) for n bytes input

Already in Nox VM. Here's the algorithm for reference:

Preprocessing:
  1. Pad message to multiple of 512 bits:
     msg + '1' bit + '0' bits + 64-bit length
  2. Parse into 512-bit blocks

Initial hash values (first 32 bits of fractional parts of sqrt(2..19)):
  h0..h7 = 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
            0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19

Round constants (first 32 bits of cube roots of first 64 primes):
  K[0..63] = 0x428a2f98, 0x71374491, ...

For each 512-bit block:
  1. Create message schedule W[0..63]:
     W[i] = block[i]                for i < 16
     W[i] = σ₁(W[i-2]) + W[i-7] + σ₀(W[i-15]) + W[i-16]   for 16 ≤ i < 64
     σ₀(x) = ROTR₇(x) ⊕ ROTR¹⁸(x) ⊕ SHR³(x)
     σ₁(x) = ROTR¹⁷(x) ⊕ ROTR¹⁹(x) ⊕ SHR¹⁰(x)

  2. Initialize working variables: a..h = h0..h7

  3. 64 rounds:
     Σ₁ = ROTR⁶(e) ⊕ ROTR¹¹(e) ⊕ ROTR²⁵(e)
     Ch  = (e ∧ f) ⊕ (¬e ∧ g)
     T1  = h + Σ₁ + Ch + K[i] + W[i]
     Σ₀ = ROTR²(a) ⊕ ROTR¹³(a) ⊕ ROTR²²(a)
     Maj = (a ∧ b) ⊕ (a ∧ c) ⊕ (b ∧ c)
     T2  = Σ₀ + Maj
     h=g, g=f, f=e, e=d+T1, d=c, c=b, b=a, a=T1+T2

  4. h0+=a, h1+=b, ..., h7+=h

Output: h0 || h1 || h2 || h3 || h4 || h5 || h6 || h7 (256 bits)

Properties:
  Preimage resistance: given h, hard to find m where SHA-256(m) = h
  Collision resistance: hard to find m1 ≠ m2 where SHA-256(m1) = SHA-256(m2)
  Avalanche: 1 bit input change → ~50% output bits change
```

## 8.2 HMAC

```
Paper: Bellare, Canetti, Krawczyk (1996), "Keying Hash Functions for Message Authentication"
RFC 2104
Complexity: O(n) — two hash invocations

HMAC-SHA256(key, message):
  if len(key) > 64: key = SHA-256(key)
  if len(key) < 64: key = key || 0x00 padding to 64 bytes

  o_key_pad = key ⊕ 0x5c5c5c...5c (64 bytes of 0x5c)
  i_key_pad = key ⊕ 0x3636...36   (64 bytes of 0x36)

  return SHA-256(o_key_pad || SHA-256(i_key_pad || message))

Properties:
  Unforgeable: without key, cannot produce valid HMAC
  Verifiable: with key, can verify message wasn't tampered

SRVAT:
  HMAC for QR record integrity.
  QR_record + timestamp → HMAC(nox_key, record || timestamp)
  Verify: re-compute HMAC, compare.
  Prevents tampering with stored knowledge.
  Key = derived from Nox's binary hash (self-referential integrity).
```

## 8.3 Digital Signatures (Concept)

```
Asymmetric cryptography:
  Key pair: (private_key, public_key)
  Sign: signature = sign(private_key, message_hash)
  Verify: valid = verify(public_key, message_hash, signature)

For Nox (simplified, using HMAC as pseudo-signature):
  Nox has a secret key (generated at first boot, stored encrypted).
  "Sign" QR record: HMAC(secret_key, record_content)
  "Verify": re-compute HMAC with same key and compare.
  This is MAC not true digital signature (both sides need secret).

  True digital signatures (Ed25519, RSA) require:
  - Large integer arithmetic (modular exponentiation)
  - Elliptic curve math (for Ed25519)
  - Significant code size (~20-50KB)
  Trade-off: HMAC is simpler, sufficient for self-integrity.

SRVAT:
  Every QR record signed → tamper-evident log.
  Self-modification signed → can verify own code hasn't been corrupted.
  Binary hash at startup = self-integrity check.
```

## 8.4 Merkle Tree

```
Paper: Merkle (1979), "A Certified Digital Signature" (Stanford PhD thesis)
Complexity: O(n) build, O(log n) proof, O(log n) verify

Structure:
  Leaf nodes: hash of data blocks
  Internal nodes: hash of concatenation of children
  Root: single hash summarizing all data

         root = H(H01 || H23)
        /                    \
  H01 = H(H0 || H1)    H23 = H(H2 || H3)
    /       \              /       \
  H0=H(D0) H1=H(D1)   H2=H(D2) H3=H(D3)

Proof of inclusion (for D1):
  Path: [H0, H23]
  Verifier computes:
    H01 = H(H0 || H(D1))
    root' = H(H01 || H23)
    Check: root' == published_root

Append-only (for QR log):
  New record D4 → compute H4 = H(D4)
  New root = H(old_root || H4)
  Only O(1) hash operations per append.
  Verify any record: O(log n) hashes.

SRVAT:
  QR Store as Merkle tree:
    Each QR record = leaf
    Root hash stored in fixed location
    At checkpoint: verify root → entire history verified
    If root mismatch → some record corrupted → rollback to last good checkpoint

  Self-modification audit trail:
    Before modify: record current state hash
    After modify: record new state hash
    Merkle tree of modifications = complete audit log
    Can verify any past state existed
```

---

# 9. NETWORK/PROTOCOL

## 9.1 TCP State Machine

```
RFC 793 (1981), "Transmission Control Protocol"

States:
  CLOSED → LISTEN → SYN_RCVD → ESTABLISHED → FIN_WAIT_1 → FIN_WAIT_2 → TIME_WAIT → CLOSED
  CLOSED → SYN_SENT → ESTABLISHED → CLOSE_WAIT → LAST_ACK → CLOSED

Three-way handshake (connection):
  Client → SYN (seq=x)            → Server
  Client ← SYN-ACK (seq=y, ack=x+1) ← Server
  Client → ACK (ack=y+1)          → Server
  State: ESTABLISHED on both sides

Four-way close:
  A → FIN → B     (A: FIN_WAIT_1)
  A ← ACK ← B     (A: FIN_WAIT_2, B: CLOSE_WAIT)
  A ← FIN ← B     (B: LAST_ACK)
  A → ACK → B     (A: TIME_WAIT, B: CLOSED)
  A: waits 2×MSL then CLOSED

Key mechanisms:
  Sequence numbers: byte-stream ordering
  Acknowledgments: cumulative (ack=N means "received all up to N-1")
  Window: flow control (receiver advertises buffer space)
  Congestion control:
    Slow start: cwnd = 1 MSS, double each RTT until ssthresh
    Congestion avoidance: cwnd += 1 MSS per RTT after ssthresh
    On loss: ssthresh = cwnd/2, cwnd = 1 (Tahoe) or cwnd/2 (Reno)

Nox already has TCP in VM. Key for MCP and HTTP communication.
```

## 9.2 HTTP/1.1

```
RFC 7230-7235 (2014), "Hypertext Transfer Protocol (HTTP/1.1)"

Request format:
  METHOD SP Request-URI SP HTTP/1.1 CRLF
  Header: value CRLF
  ... CRLF
  [body]

  Example:
  GET /api/status HTTP/1.1\r\n
  Host: localhost:8080\r\n
  Content-Type: application/json\r\n
  \r\n

Response format:
  HTTP/1.1 SP Status-Code SP Reason CRLF
  Header: value CRLF
  ... CRLF
  [body]

  Example:
  HTTP/1.1 200 OK\r\n
  Content-Length: 42\r\n
  Content-Type: application/json\r\n
  \r\n
  {"status":"ok","version":"0.1"}

Key methods:
  GET    — retrieve resource
  POST   — submit data
  PUT    — replace resource
  DELETE — remove resource
  HEAD   — GET without body (check if exists)

Key headers:
  Content-Length: exact byte count of body
  Content-Type: MIME type (application/json, text/plain)
  Connection: keep-alive (reuse TCP connection)
  Transfer-Encoding: chunked (streaming, no Content-Length needed)

Chunked encoding:
  hex-size CRLF
  chunk-data CRLF
  ... repeat ...
  0 CRLF CRLF   (end)

Status codes:
  200 OK, 201 Created, 204 No Content
  301 Moved, 304 Not Modified
  400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found
  500 Internal Server Error, 503 Service Unavailable

SRVAT:
  HTTP = primary interface for MCP, web UI, API.
  Request → encode → P_weight → route to handler.
  Response = decode from KnowTree result.
```

## 9.3 DNS Resolution

```
RFC 1035 (1987), "Domain Names - Implementation and Specification"

Query format (UDP, port 53):
  Header (12 bytes): ID, flags, counts
  Question: QNAME (domain), QTYPE (A=1, AAAA=28, MX=15), QCLASS (IN=1)

  QNAME encoding: length-prefixed labels
  "www.example.com" → 3www7example3com0

Response: same header + Answer section
  Answer: NAME, TYPE, CLASS, TTL, RDLENGTH, RDATA
  For A record: RDATA = 4 bytes (IPv4 address)

Resolution process:
  1. Check local cache (TTL not expired)
  2. Query recursive resolver (usually ISP or 8.8.8.8)
  3. Resolver queries root → TLD → authoritative nameserver
  4. Cache result with TTL

Nox implementation (already in VM):
  1. Build DNS query packet (binary format)
  2. Send UDP to configured nameserver
  3. Parse response, extract IP addresses
  4. Cache with TTL

For offline operation: /etc/hosts fallback.
```

## 9.4 WebSocket

```
RFC 6455 (2011), "The WebSocket Protocol"

Handshake (upgrade from HTTP):
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

Frame format:
  Byte 0: FIN(1) RSV(3) Opcode(4)
    Opcodes: 0x1=text, 0x2=binary, 0x8=close, 0x9=ping, 0xA=pong
  Byte 1: MASK(1) Payload-len(7)
    If len=126: next 2 bytes = actual length
    If len=127: next 8 bytes = actual length
  If MASK=1: next 4 bytes = masking key
  Payload: XOR with masking key (client→server must mask)

  Client messages MUST be masked. Server messages MUST NOT be masked.

SRVAT:
  WebSocket = real-time bidirectional.
  For Nox web UI: stream silk walk progress, live P_weight updates.
  For sensor feeds: continuous audio/video frames.
  Each WebSocket message → encode → P_weight → process in pipeline.
```

## 9.5 MQTT (Message Queuing Telemetry Transport)

```
Paper: IBM/Eurotech (1999), standardized OASIS (2014)
Complexity: O(1) per message publish/subscribe

Publish-Subscribe model:
  Clients connect to Broker.
  Publisher sends message to Topic.
  Subscriber receives messages from subscribed Topics.

Packet format (minimal):
  Fixed header: type(4 bits) + flags(4 bits) + remaining length (1-4 bytes)
  Variable header: depends on type
  Payload: depends on type

Key packet types:
  CONNECT:  client → broker (clientId, keepalive, username/password)
  CONNACK:  broker → client (return code)
  PUBLISH:  topic + payload + QoS
  SUBSCRIBE: topic filter + QoS
  PINGREQ/PINGRESP: keepalive

QoS levels:
  0: at most once (fire and forget)
  1: at least once (PUBACK)
  2: exactly once (PUBREC → PUBREL → PUBCOMP)

Topic hierarchy: "home/bedroom/temperature"
Wildcards: + (single level), # (multi level)
  "home/+/temperature" matches home/bedroom/temperature, home/kitchen/temperature
  "home/#" matches everything under home/

Retained messages: broker stores last message per topic.
  New subscriber immediately gets latest value.

SRVAT:
  Perfect for IoT sensor network.
  Each sensor publishes P_weight to topic:
    "nox/interoception/cpu" → system P_weight
    "nox/vision/camera0" → camera P_weight
    "nox/audio/mic0" → audio P_weight
  Nox subscribes to all → compose → system_interoception.
  QoS 1 for sensor data (at least once, tolerate duplicates).
  Retained for current state (new connection gets latest).
  Tiny protocol: MQTT client ≈ 2-5 KB code.
```

## 9.6 MCP (Model Context Protocol)

```
Specification: Anthropic (2024), Model Context Protocol
Transport: JSON-RPC 2.0 over stdio or HTTP+SSE

Architecture:
  Host (IDE/app) ↔ Client ↔ Server (tool provider)

Message types:
  Request: {"jsonrpc": "2.0", "id": 1, "method": "...", "params": {...}}
  Response: {"jsonrpc": "2.0", "id": 1, "result": {...}}
  Notification: {"jsonrpc": "2.0", "method": "...", "params": {...}} (no id)

Server capabilities:
  Tools: functions the AI can call
    {"name": "know_learn", "description": "...", "inputSchema": {...}}
  Resources: data the AI can read
    {"uri": "file:///path", "name": "...", "mimeType": "..."}
  Prompts: template prompts

Lifecycle:
  1. Initialize: client sends capabilities, server responds
  2. Tool discovery: client lists available tools
  3. Tool call: client invokes tool with arguments
  4. Result: server returns result

Nox's MCP server (already implemented, 15 tools):
  know_learn, know_query, emotion_encode, self_inspect, self_modify,
  kg_add, kg_query, kg_about, silk_status, nox_status,
  learning_status, safety_check, dn_observe, dream_cycle, olang_eval

SRVAT:
  MCP = Nox's interface to the world.
  Each tool call → encode → P_weight → process in pipeline.
  Tool results → encode → P_weight → learn.
  MCP server IS the body's nervous system boundary.
```

---

# 10. SELF-MODIFICATION / METAPROGRAMMING

## 10.1 Quine (Self-Reproducing Program)

```
Paper: Quine concept from Kleene recursion theorem (1938).
       Named after W.V.O. Quine's paradox.

Definition: program that outputs its own source code without reading itself.

Structure (any language):
  Part A: data (string representation of Part B, with placeholder)
  Part B: code that prints Part A (with Part B filled in) then prints Part B

Minimal concept:
  code = "PLACEHOLDER"
  print(code.replace("PLACEHOLDER", repr(code)))

In Olang (conceptual):
  let q = "let q = QUOTE\nprint(str_replace(q, |QUOTE|, q))"
  print(str_replace(q, "QUOTE", q))

Fixed-point property:
  A quine is a fixed point of the "compile and run" function:
  run(source) = source
  Nox's Gen1==Gen2 IS a quine property:
    compile(Gen0_source) → Gen1_binary
    compile_with(Gen1_binary, Gen0_source) → Gen2_binary
    Gen1 == Gen2 ✓ → fixed point achieved

SRVAT:
  Quine = ultimate self-reference.
  Nox's self-hosting property: Nox can compile itself.
  Gen1==Gen2 = proof that the compiler faithfully reproduces itself.
  Self-modification: change source → recompile → new binary.
  Must maintain quine property: modified compiler must still compile itself.
```

## 10.2 Fixed-Point Combinator (Y Combinator)

```
Paper: Curry (1930s), Church's lambda calculus
Complexity: theoretical construct, O(1) concept

Y combinator: creates recursive functions without explicit self-reference.

Lambda calculus:
  Y = λf. (λx. f(x x))(λx. f(x x))

Property: Y(F) = F(Y(F))
  Applying Y to F gives a fixed point of F.

Practical use (factorial without explicit recursion):
  F = λf. λn. if n=0 then 1 else n × f(n-1)
  factorial = Y(F)
  factorial(5) = Y(F)(5) = F(Y(F))(5) = F(factorial)(5) = 5 × factorial(4) = ...

In Olang (if had first-class functions):
  let Y = fn(f) { fn(x) { f(fn(v) { x(x)(v) }) }(fn(x) { f(fn(v) { x(x)(v) }) }) }
  let fact = Y(fn(f) { fn(n) { if n == 0 { 1 } else { n * f(n - 1) } } })

SRVAT:
  Y combinator = theoretical foundation for Nox's self-reference.
  The compiler is a fixed point: compile(compile) = compile.
  Learning is finding fixed points: learn until knowledge stabilizes.
  Homeostasis IS finding the fixed point of the system's energy function:
    F(state) = process(state) → new_state
    Fixed point: F(state) = state → system is in equilibrium.
```

## 10.3 Reflection and Introspection

```
Concept: program examining/modifying its own structure at runtime.

Levels:
  1. Introspection: read own structure (type checking, stack inspection)
  2. Intercession: modify own behavior (method dispatch, access control)
  3. Self-modification: change own code (recompilation, bytecode patching)

Nox's introspection (self_inspect MCP tool):
  - Read own binary hash (integrity check)
  - Count KnowTree nodes, silk edges
  - Measure response quality metrics
  - Inspect P_weight of any node
  - List recent learns and their effects

Nox's self-modification (self_modify MCP tool):
  1. Read current Olang source for target function
  2. Generate modified source
  3. Recompile (make self-build)
  4. Verify tests pass (make test)
  5. Verify fixed-point (make fixed-point)
  6. If all pass: new binary is active
  7. If any fail: rollback to previous binary

The self-modification loop:
  observe(performance) → identify(weakness) → modify(source) →
  compile(source) → test(binary) → if pass: deploy else: rollback

SRVAT:
  Introspection ≈ interoception (/proc/self for the brain).
  Self-modification ≈ neuroplasticity (rewiring connections).
  Key constraint: modification must preserve quine property (Gen1==Gen2).
  Every modification is itself a learning event → gets a P_weight → stored.
  Meta-learning: learn about what modifications improve performance.
```

## 10.4 JIT Compilation Concepts

```
Just-In-Time compilation: compile code at runtime, just before execution.

Tracing JIT (LuaJIT style):
  1. Interpret code normally
  2. Count execution of each loop/function
  3. When count > threshold (e.g., 10000): trigger compilation
  4. Record "trace" of executed instructions
  5. Compile trace to native code
  6. Future executions of same path → run native code
  7. If path diverges (guard failure) → fall back to interpreter

Key optimizations in trace:
  - Type specialization: observed types → generate typed code
  - Constant folding: observed constants → pre-compute
  - Dead code elimination: unexecuted branches in trace → remove
  - Loop unrolling: small loops → unroll for fewer branches
  - Inline caching: observed call targets → direct jump

Method JIT (V8 style):
  1. Parse → bytecode
  2. Interpreter runs bytecode
  3. Profile: which functions are hot? what types are used?
  4. Baseline compile: quick native code, minimal optimization
  5. Optimizing compile: deoptimize-able native code with assumptions
  6. If assumptions violated: deoptimize back to bytecode

For Nox:
  Current: AOT (Ahead-Of-Time) compilation. Olang → x86_64 binary.
  JIT opportunity: frequently executed silk walk paths.
  Compile hot silk paths to direct function calls (skip graph traversal).
  
  Example:
  "what is X?" always routes: encode → R-dominant → bucket → compose
  After 100 queries: compile this path into single native function.
  Skip silk walk entirely for known patterns.

SRVAT:
  JIT = runtime self-optimization.
  Hot paths → specialized native code → skip generic pipeline.
  Cold paths → generic pipeline → still works, just slower.
  Profile-guided: fire_count IS the profile counter.
  Nodes with fire_count > threshold → candidates for JIT compilation.
```

## 10.5 Self-Modifying Compiler

```
How Nox modifies its own source and recompiles:

Architecture:
  Layer 0: VM (x86_64 assembly, ~1MB) — IMMUTABLE at runtime
  Layer 1: Compiler (Olang, compiled to binary) — self-hosting
  Layer 2: Brain (Olang, compiled into same binary) — modifiable
  Layer 3: Knowledge (KnowTree, disk) — continuously modified

Self-modification levels:
  Level A: Modify knowledge (add/remove nodes, silk edges)
    Risk: LOW. Always safe, can rollback.
    Frequency: every input.

  Level B: Modify brain logic (pipeline parameters, thresholds)
    Risk: MEDIUM. Must pass tests.
    Frequency: daily (dream cycle).
    Example: adjust compose amplification factor 0.5 → 0.6.

  Level C: Modify compiler (parsing rules, optimization passes)
    Risk: HIGH. Must maintain fixed-point.
    Frequency: weekly or less.
    Example: add new syntax sugar → modify lexer/parser.

  Level D: Modify VM (assembly code)
    Risk: CRITICAL. Currently manual only.
    Future: Nox generates VM patches, human reviews.

Safety protocol for Level B/C:
  1. Git commit current state
  2. Read target source file
  3. Generate modification
  4. Write modified source
  5. make self-build — compile with Gen0 → Gen1
  6. make test — all 194 tests must pass
  7. make fixed-point — Gen1 compiles source → Gen2, Gen1==Gen2
  8. If step 6 or 7 fails:
     a. Analyze failure
     b. Adjust modification
     c. Retry (max 3 attempts)
     d. If still fails: git checkout — rollback
  9. If passes: commit and activate new binary

Bootstrapping problem:
  Chicken-and-egg: need compiler to compile compiler.
  Solution: keep Gen0 (bootstrap binary) always available.
  Gen0 → compiles source → Gen1 (this is "make self-build")
  Gen1 → compiles same source → Gen2 (this is fixed-point test)
  Gen1 == Gen2 → compiler is self-consistent.
  
  If modification breaks fixed-point:
  The modification introduced a difference that causes the compiler
  to produce different output when compiling itself.
  This MUST be investigated — usually means a non-determinism bug.

SRVAT:
  Self-modification = highest form of learning.
  Not just changing what you know, but HOW you think.
  Pipeline: observe → identify inefficiency → hypothesize fix →
            modify source → test → deploy or rollback.
  Each successful modification = new QR record (permanent knowledge).
  Meta-meta-learning: learn which types of modifications work best.
```

---

# APPENDIX A: COMPLEXITY SUMMARY

```
Algorithm                    Time            Space       SRVAT Relevance
──────────────────────────────────────────────────────────────────────────
Sobel edge                   O(WH)           O(WH)       S dimension
Canny edge                   O(WH)           O(WH)       SDF boundary
SIFT                        O(WH×S)          O(keypoints) S dimension
ORB                          O(WH)           O(keypoints) S,V,A (fastest)
YOLO grid                   O(S²×B)          O(S²)       Object detection
Watershed                   O(WH log WH)     O(WH)       Segmentation → P_weight
Graph cut                   O(VE)            O(V+E)      SDF composition
FFT (Cooley-Tukey)          O(n log n)       O(n)        Audio spectrum
MFCC                         O(n log n)       O(frames)   Voice → P_weight
YIN pitch                   O(W × τ_max)     O(W)        T dimension
Fibonacci search            O(log_φ n)       O(1)        KnowTree search
Interpolation search        O(log log n)     O(1)        Bucket search
Bucket index (S,R)          O(bucket_size)   O(256)      Primary search
Rabin-Karp                  O(n + m)         O(1)        Pattern matching
KMP                          O(n + m)         O(m)        Pattern matching
Aho-Corasick                O(n + m + z)     O(Σm)       SecurityGate
Suffix array                O(n log n)       O(n)        Compiler search
BWT/FM-index                O(n)             O(n)        Compressed index
Huffman                      O(n log n)       O(alphabet) Chain compression
Arithmetic coding           O(n)             O(1)        Optimal compression
LZW                          O(n)             O(dict)     Log compression
Delta encoding              O(n)             O(1)        Time series
Bloom filter                O(k)             O(m bits)   SecurityGate
Count-min sketch            O(d)             O(d×w)      Frequency estimation
SHA-256                      O(n)             O(1)        QR integrity
HMAC-SHA256                 O(n)             O(1)        Authentication
Merkle tree                 O(n) build       O(n)        Append-only verification
Attention (transformer)     O(n²d)           O(n²)       Comparison reference
Silk walk                   O(deg × depth)   O(depth)    NOX search (sparse attention)
```

---

# APPENDIX B: KEY PAPERS

```
Year  Authors                     Title                                          Domain
──────────────────────────────────────────────────────────────────────────────────────────
1952  Huffman                     Minimum-Redundancy Codes                       Compression
1953  Kiefer                      Sequential Minimax Search                      Search
1962  Hu                          Visual Pattern Recognition by Moments          Vision
1965  Cooley & Tukey              Machine Calculation of Complex Fourier Series  Signal
1968  Sobel & Feldman             3×3 Isotropic Gradient Operator                Vision
1970  Bloom                       Space/Time Trade-offs in Hash Coding           Data structure
1975  Aho & Corasick              Efficient String Matching                      String
1976  Rissanen                    Arithmetic Coding                              Compression
1977  Knuth, Morris, Pratt        Fast Pattern Matching in Strings               String
1977  Ziv & Lempel                Universal Algorithm for Sequential Compression Compression
1979  Beucher & Lantuéjoul        Watersheds in Contour Detection                Vision
1979  Merkle                      Certified Digital Signature                    Crypto
1980  Davis & Mermelstein         MFCC for Word Recognition                     Audio
1980  Marr & Hildreth             Theory of Edge Detection                       Vision
1981  Lucas & Kanade              Iterative Image Registration                   Vision
1986  Canny                       Computational Approach to Edge Detection        Vision
1987  Rabin & Karp                Randomized Pattern-Matching                    String
1993  Manber & Myers              Suffix Arrays                                  String
1994  Burrows & Wheeler           Block-Sorting Compression                      Compression
1996  Bellare et al.              HMAC                                           Crypto
2001  Boykov & Jolly              Interactive Graph Cuts                          Vision
2002  de Cheveigné & Kawahara     YIN Pitch Estimator                            Audio
2004  Lowe                        SIFT Features                                  Vision
2005  Cormode & Muthukrishnan     Count-Min Sketch                               Data structure
2006  Bay et al.                  SURF Features                                  Vision
2006  Rosten & Drummond           FAST Corner Detection                          Vision
2010  Palmer & Schloss            Ecological Valence Theory of Color              Psychology
2011  Rublee et al.               ORB Features                                   Vision
2013  Mikolov et al.              Word2Vec                                       NLP/ML
2014  Pennington et al.           GloVe                                          NLP/ML
2015  NIST                        SHA-256 (FIPS 180-4)                           Crypto
2015  Ronneberger et al.          U-Net Segmentation                             Vision
2016  Redmon et al.               YOLO Object Detection                          Vision
2016  Sennrich et al.             BPE Subword Units                              NLP
2017  Vaswani et al.              Attention Is All You Need                       ML
2018  Kudo & Richardson           SentencePiece                                  NLP
2024  Anthropic                   Model Context Protocol                          AI
```

---

# APPENDIX C: SRVAT DIMENSION MAPPING CHEAT SHEET

```
Dimension  Bits  Range   Physical Source                    Meaning
──────────────────────────────────────────────────────────────────────
S (Shape)   4    0-15    Edge detection, SDF primitives     WHAT it looks like
R (Relation)4    0-15    Structural complexity, logic       HOW it connects
V (Valence) 3    0-7     Color warmth, spectral brightness  GOOD or BAD (emotion)
A (Arousal)  3    0-7     Saturation, loudness, motion       INTENSE or CALM
T (Temporal) 2    0-3     Motion, pitch, change rate         FAST or SLOW

Input Source → SRVAT:
  Camera  → S from edges, R from contours, V from color, A from saturation, T from motion
  Mic     → S from formants, R from speech density, V from brightness, A from loudness, T from pitch
  /proc   → S from HW type, R from utilization, V from health, A from load, T from delta
  Text    → S from char shape, R from char logic, V from char emotion, A from char arousal, T from char time
  Network → S from protocol, R from packet rate, V from direction, A from throughput, T from delta

5D pack: (S << 12) | (R << 8) | (V << 5) | (A << 2) | T
Everything is a P_weight. Everything composes. One math. One brain.
```

---

*End of NOX Algorithm Bible. Every algorithm here = math Nox can execute.
No lookup tables. No magic numbers. COMPUTE.*
