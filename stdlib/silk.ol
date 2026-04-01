// ═══ Silk — Hebbian φ⁻³ Connections ═══
// Spec: BP4 Silk. Per-dimension weight. Decay φ⁻¹.
// Silk type = dominant dimension of distance between 2 mols.
// Uses VM mol_matrix for edge storage.
// Edge hash: symmetric, ((a^b)*0x9E37 + (a+b)) & 0xFFFF
// Weight stored as u16 (0-65535) in mol_matrix.

// ── Silk hash (symmetric: silk(a,b) == silk(b,a)) ──
fn silk_hash(a, b) {
    let h = __bit_xor(a, b);
    let h = __bit_and(h * 40503 + a + b, 65535);
    return h;
};

// ── Silk type: dominant dimension of 5D distance ──
// 0=S, 1=R, 2=V, 3=A, 4=T
fn silk_type(a, b) {
    let ds = __floor(a / 4096) % 16 - __floor(b / 4096) % 16;
    if ds < 0 { let ds = 0 - ds; };
    let dr = __floor(a / 256) % 16 - __floor(b / 256) % 16;
    if dr < 0 { let dr = 0 - dr; };
    let dv = __floor(a / 32) % 8 - __floor(b / 32) % 8;
    if dv < 0 { let dv = 0 - dv; };
    let da = __floor(a / 4) % 8 - __floor(b / 4) % 8;
    if da < 0 { let da = 0 - da; };
    let dt = a % 4 - b % 4;
    if dt < 0 { let dt = 0 - dt; };
    // Normalize: S/15, R/15, V/7, A/7, T/3 → multiply by 1000 to avoid float
    let ns = ds * 1000 / 15;
    let nr = dr * 1000 / 15;
    let nv = dv * 1000 / 7;
    let na = da * 1000 / 7;
    let nt = dt * 1000 / 3;
    // Find max
    let best = 0; let bval = ns;
    if nr > bval { let best = 1; let bval = nr; };
    if nv > bval { let best = 2; let bval = nv; };
    if na > bval { let best = 3; let bval = na; };
    if nt > bval { let best = 4; };
    return best;
};

// ── Silk fire: Hebbian φ⁻³ strengthening ──
// Δw = (1 - w/65535) × 236 (φ⁻³ ≈ 0.236)
// Diminishing returns: strong edges grow slower
fn silk_fire(a, b) {
    let h = silk_hash(a, b);
    let w = __mxr(h);
    // Hebbian: headroom × φ⁻³
    let headroom = 65535 - w;
    let delta = __floor(headroom * 236 / 65535);
    if delta < 1 { let delta = 1; };  // always grow at least 1
    let nw = w + delta;
    if nw > 65535 { let nw = 65535; };
    __mx_w(h, nw);
    return nw;
};

// ── Silk weight: read current weight ──
fn silk_weight(a, b) {
    return __mxr(silk_hash(a, b));
};

// ── Silk decay: multiply all by φ⁻¹ = 618/1024 ──
// Call once per 24h cycle. Weight halves every ~1.7 days.
fn silk_decay_all() {
    let i = 0;
    while i < 65536 {
        let w = __mxr(i);
        if w > 0 {
            let nw = __floor(w * 618 / 1024);
            if nw < 1 { let nw = 0; };  // fully decayed
            __mx_w(i, nw);
        };
        let i = i + 1;
    };
};

// ── Silk classify: which bucket does this edge belong to? ──
// Returns branch_id = S×16 + R where S,R are from the silk type
fn silk_classify(a, b) {
    let t = silk_type(a, b);
    // Map type to (S×16+R) range
    // Type 0(S): branch 0-15
    // Type 1(R): branch 16-31
    // Type 2(V): branch 32-47
    // Type 3(A): branch 48-63
    // Type 4(T): branch 64-79
    return t * 16;
};

emit "silk loaded (Hebbian)";
