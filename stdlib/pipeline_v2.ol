// pipeline_v2.ol — Full pipeline on VM v2

fn abs(x) { if x < 0 { return 0 - x; }; return x; };

fn encode(text) {
    let h = 5381;
    let i = 0;
    while i < len(text) {
        let c = __char_code(char_at(text, i));
        let h = __bit_and(h * 33 + c, 65535);
        let i = i + 1;
    };
    return h;
};

fn mol_v(m) { return __floor(m / 32) % 8; };
fn mol_a(m) { return __floor(m / 4) % 8; };

// Security gate: V ≤ 1 AND A ≥ 6 → crisis
fn security_gate(text) {
    let mol = encode(text);
    if mol_v(mol) < 2 {
        if mol_a(mol) > 5 { return 1; };
    };
    return 0;
};

// KnowTree (uses globals from knowtree.ol)
// Assumes: facts[], learn(), query() already defined

fn pipeline(input) {
    // CP1: Security
    if security_gate(input) == 1 {
        return "Neu ban can ho tro, xin goi 1800 599 920";
    };
    
    // Search by word match
    let result = query(input);
    
    // Honesty gate: no result → silence
    if len(result) == 0 { return ""; };
    
    // Silk fire between input and result
    let im = encode(input);
    let rm = encode(result);
    silk_fire(im, rm);
    
    return result;
};

emit "pipeline_v2 loaded";
