// ═══ Encode ∫ — 42 Formulas ═══
// Codepoint → P_weight (u16) = [S:4][R:4][V:3][A:3][T:2]
// TÍNH, không TRA. Mỗi giá trị = index vào công thức.
// Source: PLAN_FORMULA_ENGINE.md + Rust crates/olang/src/mol/

// ── Constants ──
let PHI = 1618;         // φ × 1000 = 1.618 × 1000
let PHI_INV = 618;      // φ⁻¹ × 1000
let PHI_INV2 = 382;     // φ⁻² × 1000
let PHI_INV3 = 236;     // φ⁻³ × 1000
let PROMOTE_W = 854;    // φ⁻¹ + φ⁻³ = 0.854 × 1000

// ── Tier 1: Master Encode ──
// F₀(cp) = [f_S(cp), f_R(cp), f_V(cp), f_A(cp), f_T(cp)]
fn encode_mol(text) {
    let result_mol = [0];  // accumulator
    let ei = 0;
    while ei < len(text) {
        let c = __char_code(char_at(text, ei));
        let mol = encode_char(c);
        if ei == 0 {
            let _ = __set_at(result_mol, 0, mol);
        } else {
            let prev = __array_get(result_mol, 0);
            let composed = compose_bio(prev, mol);
            let _ = __set_at(result_mol, 0, composed);
        };
        let ei = ei + 1;
    };
    return __array_get(result_mol, 0);
};

// ── Tier 2: Per-character encode ──
fn encode_char(cp) {
    let s = f_shape(cp);
    let r = f_relation(cp);
    let v = f_valence(cp);
    let a = f_arousal(cp);
    let t = f_time(cp);
    return mol_pack_5d(s, r, v, a, t);
};

fn mol_pack_5d(s, r, v, a, t) {
    return s * 4096 + r * 256 + v * 32 + a * 4 + t;
};

// ── Tier 3: 36 Sub-classifiers ──

// ═══ f_S: Shape (4 bits, 0-15) — SDF complexity ═══
// Unicode block → geometric complexity
fn f_shape(cp) {
    // Arrows → moderate complexity
    if cp >= 8592 { if cp <= 8703 { return 6; }; };   // 0x2190-0x21FF Arrows
    // Geometric shapes → direct mapping
    if cp >= 9632 { if cp <= 9727 { return shape_geometric(cp); }; };  // 0x25A0-0x25FF
    // Box drawing → low complexity
    if cp >= 9472 { if cp <= 9599 { return 2; }; };   // 0x2500-0x257F
    // Block elements → very low
    if cp >= 9600 { if cp <= 9631 { return 1; }; };   // 0x2580-0x259F
    // Braille → high (dot pattern)
    if cp >= 10240 { if cp <= 10495 { return 10; }; }; // 0x2800-0x28FF
    // Emoji → moderate
    if cp >= 127744 { if cp <= 128767 { return 5; }; }; // 0x1F300-0x1F7FF
    // Math symbols → moderate
    if cp >= 8704 { if cp <= 8959 { return 4; }; };   // 0x2200-0x22FF
    // Latin letters → low complexity (basic shapes)
    if cp >= 65 { if cp <= 90 { return 3; }; };       // A-Z uppercase
    if cp >= 97 { if cp <= 122 { return 2; }; };      // a-z lowercase
    // Digits → very low
    if cp >= 48 { if cp <= 57 { return 1; }; };       // 0-9
    // CJK → high complexity
    if cp >= 19968 { if cp <= 40959 { return 12; }; }; // 0x4E00-0x9FFF
    // Default
    return 1;
};

fn shape_geometric(cp) {
    // 18 SDF primitives mapping
    if cp == 9679 { return 0; };  // ● Sphere 0x25CF
    if cp == 9632 { return 1; };  // ■ Box 0x25A0
    if cp == 9644 { return 2; };  // ▬ Capsule 0x25AC
    if cp == 9661 { return 3; };  // ▽ Plane 0x25BD
    if cp == 9675 { return 4; };  // ○ Torus 0x25CB
    if cp == 9650 { return 6; };  // ▲ Cone 0x25B2
    if cp == 9645 { return 7; };  // ▭ Cylinder 0x25AD
    if cp == 9670 { return 8; };  // ◆ Octahedron 0x25C6
    if cp == 9651 { return 9; };  // △ Pyramid 0x25B3
    if cp == 9634 { return 12; }; // ▢ RoundBox 0x25A2
    return 5; // default geometric
};

// ═══ f_R: Relation (4 bits, 0-15) — Category Theory ═══
// R=0 Algebraic, R=1 Order, R=2 Representation, R=3 Numeral
// R=4 Punctuation, R=5 Currency, R=6 Additive, R=7 Automaton
// R=8-15 Category morphisms (Member, Subset, Equiv, etc.)
fn f_relation(cp) {
    // Math operators → R=0 (Algebraic)
    if cp == 43 { return 0; };   // +
    if cp == 45 { return 0; };   // -
    if cp == 42 { return 0; };   // *
    if cp == 47 { return 0; };   // /
    if cp == 37 { return 0; };   // %
    // Comparison → R=1 (Order)
    if cp == 60 { return 1; };   // <
    if cp == 62 { return 1; };   // >
    if cp == 61 { return 1; };   // =
    // Digits → R=3 (Numeral)
    if cp >= 48 { if cp <= 57 { return 3; }; };
    // Punctuation → R=4
    if cp == 40 { return 4; };   // (
    if cp == 41 { return 4; };   // )
    if cp == 91 { return 4; };   // [
    if cp == 93 { return 4; };   // ]
    if cp == 123 { return 4; };  // {
    if cp == 125 { return 4; };  // }
    if cp == 44 { return 4; };   // ,
    if cp == 59 { return 4; };   // ;
    if cp == 46 { return 4; };   // .
    // Currency → R=5
    if cp == 36 { return 5; };   // $
    // Unicode math → varies
    if cp >= 8704 { if cp <= 8959 {
        // ∈(8712)=8 Member, ⊂(8834)=9 Subset, ≡(8801)=10 Equiv
        // →(8594)=13 Causes, ≈(8776)=14 Similar
        if cp == 8712 { return 8; };   // ∈
        if cp == 8834 { return 9; };   // ⊂
        if cp == 8801 { return 10; };  // ≡
        if cp == 8869 { return 11; };  // ⊥
        if cp == 8728 { return 12; };  // ∘
        if cp == 8776 { return 14; };  // ≈
        return 0; // default math = algebraic
    }; };
    // Arrows → R=13 (Causes) or R=15 (DerivedFrom)
    if cp == 8594 { return 13; }; // → Causes
    if cp == 8592 { return 15; }; // ← DerivedFrom
    // Letters → R=8 (Member — elements of language)
    if cp >= 65 { if cp <= 122 { return 8; }; };
    // Default
    return 8;
};

// ═══ f_V: Valence (3 bits, 0-7) — Potential Energy ═══
// V=0 HighBarrier (repel), V=3-4 Flat (neutral), V=6-7 DeepWell (attract)
fn f_valence(cp) {
    // Exclamation/warning → low V (negative)
    if cp == 33 { return 2; };   // ! (slightly negative, urgent)
    // Question → neutral
    if cp == 63 { return 4; };   // ?
    // Heart/love → very positive
    if cp == 10084 { return 7; }; // ❤ 0x2764
    // Skull/death → very negative
    if cp == 9760 { return 0; };  // ☠ 0x2620
    // Smile emoji → positive
    if cp >= 128512 { if cp <= 128591 { return 6; }; }; // 0x1F600-0x1F64F
    // Letters → neutral (V=4)
    if cp >= 65 { if cp <= 122 { return 4; }; };
    // Digits → neutral
    if cp >= 48 { if cp <= 57 { return 4; }; };
    // Space/whitespace → flat neutral
    if cp == 32 { return 3; };
    if cp == 10 { return 3; };
    // Default neutral
    return 4;
};

// ═══ f_A: Arousal (3 bits, 0-7) — Critical Phenomena ═══
// A=0 Calm (subcritical), A=4 Moderate, A=7 Supercritical (explosive)
fn f_arousal(cp) {
    // Exclamation → high arousal
    if cp == 33 { return 6; };   // !
    // Question → moderate
    if cp == 63 { return 5; };   // ?
    // Uppercase → higher arousal than lowercase
    if cp >= 65 { if cp <= 90 { return 5; }; };  // A-Z
    if cp >= 97 { if cp <= 122 { return 3; }; }; // a-z
    // Digits → low arousal (calm computation)
    if cp >= 48 { if cp <= 57 { return 2; }; };
    // Math operators → moderate (structured)
    if cp >= 8704 { if cp <= 8959 { return 4; }; };
    // Emoji → high arousal
    if cp >= 127744 { if cp <= 128767 { return 6; }; };
    // Whitespace → very calm
    if cp == 32 { return 1; };
    if cp == 10 { return 0; };
    // Default moderate
    return 3;
};

// ═══ f_T: Time (2 bits, 0-3) — Temporal Dynamics ═══
// T=0 Static, T=1 Slow, T=2 Medium, T=3 Fast
fn f_time(cp) {
    // Musical notes → rhythmic
    if cp >= 9833 { if cp <= 9839 { return 3; }; };   // ♩♪♫♬ 0x2669-0x266F
    // Punctuation → boundary markers (static)
    if cp == 46 { return 0; };   // . (stop)
    if cp == 44 { return 1; };   // , (pause)
    if cp == 59 { return 1; };   // ; (slow pause)
    // Arrows → directional movement (fast)
    if cp >= 8592 { if cp <= 8703 { return 3; }; };
    // Letters → medium (flowing text)
    if cp >= 65 { if cp <= 122 { return 2; }; };
    // Digits → slow (computation)
    if cp >= 48 { if cp <= 57 { return 1; }; };
    // Default medium
    return 2;
};

// ═══ Biological Compose (from Rust LCA) ═══
// S=Union(max), R=First(Zipf), V=Amplify, A=Max, T=First
fn compose_bio(mol_a, mol_b) {
    let sa = __floor(mol_a / 4096) % 16;
    let ra = __floor(mol_a / 256) % 16;
    let va = __floor(mol_a / 32) % 8;
    let aa = __floor(mol_a / 4) % 8;
    let ta = mol_a % 4;
    let sb = __floor(mol_b / 4096) % 16;
    let rb = __floor(mol_b / 256) % 16;
    let vb = __floor(mol_b / 32) % 8;
    let ab = __floor(mol_b / 4) % 8;
    let tb = mol_b % 4;
    // S = Union (max)
    let s = sa;
    if sb > sa { let s = sb; };
    // R = First (Zipf: a dominates)
    let r = ra;
    // V = Amplify (synergy, NOT average)
    let v_base = __floor((va + vb) / 2);
    let v_dev = va - v_base;
    if v_dev < 0 { let v_dev = 0 - v_dev; };
    let v_boost = __floor(v_dev / 2);
    let v = v_base;
    if va + vb > 6 {
        let v = v_base + v_boost;
        if v > 7 { let v = 7; };
    } else {
        if va + vb < 6 {
            let v = v_base - v_boost;
            if v < 0 { let v = 0; };
        };
    };
    // A = Max
    let a = aa;
    if ab > aa { let a = ab; };
    // T = First (dominant)
    let t = ta;
    return mol_pack_5d(s, r, v, a, t);
};

// ═══ Formula Dispatch — R eval ═══
// R value → relationship type → compose rule
fn eval_relation(r_val, mol_a, mol_b) {
    // R=0: Algebraic (group) → add dimensions
    if r_val == 0 { return compose_algebraic(mol_a, mol_b); };
    // R=1: Order → return larger
    if r_val == 1 { if mol_a > mol_b { return mol_a; } else { return mol_b; }; };
    // R=13: Causes → preserve causal order (a→b, keep a's S+R, b's V+A)
    if r_val == 13 { return compose_causal(mol_a, mol_b); };
    // R=14: Similar → average (genuine similarity)
    if r_val == 14 { return compose_average(mol_a, mol_b); };
    // Default: biological compose
    return compose_bio(mol_a, mol_b);
};

fn compose_algebraic(mol_a, mol_b) {
    let sa = __floor(mol_a / 4096) % 16;
    let ra = __floor(mol_a / 256) % 16;
    let va = __floor(mol_a / 32) % 8;
    let aa = __floor(mol_a / 4) % 8;
    let sb = __floor(mol_b / 4096) % 16;
    let vb = __floor(mol_b / 32) % 8;
    let ab = __floor(mol_b / 4) % 8;
    // Group: add per dimension, mod range
    let s = (sa + sb) % 16;
    let v = (va + vb) % 8;
    let a = (aa + ab) % 8;
    return mol_pack_5d(s, ra, v, a, mol_a % 4);
};

fn compose_causal(mol_a, mol_b) {
    // a causes b: keep a's structure, b's emotion
    let sa = __floor(mol_a / 4096) % 16;
    let ra = __floor(mol_a / 256) % 16;
    let vb = __floor(mol_b / 32) % 8;
    let ab = __floor(mol_b / 4) % 8;
    let ta = mol_a % 4;
    return mol_pack_5d(sa, ra, vb, ab, ta);
};

fn compose_average(mol_a, mol_b) {
    let sa = __floor(mol_a / 4096) % 16;
    let ra = __floor(mol_a / 256) % 16;
    let va = __floor(mol_a / 32) % 8;
    let aa = __floor(mol_a / 4) % 8;
    let ta = mol_a % 4;
    let sb = __floor(mol_b / 4096) % 16;
    let rb = __floor(mol_b / 256) % 16;
    let vb = __floor(mol_b / 32) % 8;
    let ab = __floor(mol_b / 4) % 8;
    return mol_pack_5d(
        __floor((sa + sb) / 2),
        __floor((ra + rb) / 2),
        __floor((va + vb) / 2),
        __floor((aa + ab) / 2),
        ta
    );
};

// ═══ Valence Force — Physics dispatch ═══
// Returns force × 1000: positive = attract, negative = repel
fn valence_force(v_val) {
    if v_val == 0 { return 0 - 900; };  // HighBarrier: repel
    if v_val == 1 { return 0 - 400; };  // LowBarrier: mild repel
    if v_val == 2 { return 0 - 150; };  // VeryLowBarrier
    if v_val == 3 { return 0; };         // Flat (neutral)
    if v_val == 4 { return 0; };         // Flat (neutral)
    if v_val == 5 { return 350; };       // ShallowWell: mild attract
    if v_val == 6 { return 800; };       // DeepWell: strong attract
    if v_val == 7 { return 950; };       // VeryDeepWell: maximum attract
    return 0;
};

// ═══ Arousal State — Critical phenomena dispatch ═══
// Returns energy level × 1000
fn arousal_energy(a_val) {
    if a_val == 0 { return 50; };    // Calm (subcritical)
    if a_val == 1 { return 150; };   // Drowsy
    if a_val == 2 { return 300; };   // Relaxed
    if a_val == 3 { return 450; };   // Composed
    if a_val == 4 { return 600; };   // Moderate
    if a_val == 5 { return 750; };   // Engaged
    if a_val == 6 { return 900; };   // Excited (near critical)
    if a_val == 7 { return 1000; };  // Supercritical (explosive)
    return 500;
};

// ═══ Hebbian φ⁻³ learning ═══
fn hebbian_strengthen(weight, reward) {
    // Δw = reward × (1 - w/1000) × φ⁻³
    // weight and reward are 0-1000 scale
    let headroom = 1000 - weight;
    let delta = __floor(reward * headroom * PHI_INV3 / 1000000);
    let new_w = weight + delta;
    if new_w > 1000 { return 1000; };
    return new_w;
};

fn hebbian_decay(weight, hours) {
    // w × φ⁻¹^(hours/24)
    // Approximate: for each 24h, multiply by 618/1000
    let days = __floor(hours / 24);
    let w = weight;
    let di = 0;
    while di < days {
        w = __floor(w * PHI_INV / 1000);
        let di = di + 1;
    };
    return w;
};

// ═══ Maturity State Machine ═══
// 0=Formula, 1=Evaluating, 2=Mature (irreversible)
fn maturity_advance(state, fire_count, weight, depth) {
    if state == 2 { return 2; };  // Mature is irreversible
    if state == 0 {
        if fire_count > 0 { return 1; };  // Formula → Evaluating
        return 0;
    };
    // state == 1 (Evaluating)
    // Check promotion: weight ≥ 854 AND fire_count ≥ Fib(depth)
    if weight >= PROMOTE_W {
        let fib_threshold = fib(depth);
        if fire_count >= fib_threshold {
            return 2;  // Evaluating → Mature
        };
    };
    return 1;
};

fn fib(n) {
    if n < 2 { return 1; };
    let fa = [1];
    let fb = [1];
    let fi = 2;
    while fi <= n {
        let temp = __array_get(fa, 0) + __array_get(fb, 0);
        let _ = __set_at(fa, 0, __array_get(fb, 0));
        let _ = __set_at(fb, 0, temp);
        let fi = fi + 1;
    };
    return __array_get(fb, 0);
};

// ═══ Quality Function (φ⁻¹ threshold) ═══
fn quality(validity, coherence, consistency, silk_strength) {
    // Q = (300×v + 300×h + 200×c + 200×s) / 1000
    return __floor((300 * validity + 300 * coherence + 200 * consistency + 200 * silk_strength) / 1000);
};

fn quality_pass(q) {
    return q >= PHI_INV;  // ≥ 618
};
