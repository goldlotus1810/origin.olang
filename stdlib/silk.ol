// silk.ol — Hebbian silk edges on VM v2
// Uses silk_matrix (BSS, 65536 × u16) for edge weights
// Symmetric: silk(A,B) == silk(B,A)

fn silk_hash(a, b) {
    let h = __bit_xor(a, b);
    let h = __bit_and(h * 40503 + a + b, 65535);
    return h;
};

fn silk_fire(a, b) {
    let h = silk_hash(a, b);
    let w = __mxr(h);
    // Hebbian bounded: w + 100, max 65535
    let nw = w + 100;
    if nw > 65535 { let nw = 65535; };
    __mx_w(h, nw);
    return nw;
};

fn silk_weight(a, b) {
    return __mxr(silk_hash(a, b));
};

fn silk_decay_all() {
    // Decay all silk edges by ×0.95
    // Iterate 0..65535, multiply by 950/1000
    let i = 0;
    while i < 65536 {
        let w = __mxr(i);
        if w > 0 {
            let nw = __floor(w * 950 / 1000);
            __mx_w(i, nw);
        };
        let i = i + 1;
    };
};

emit "silk loaded";
