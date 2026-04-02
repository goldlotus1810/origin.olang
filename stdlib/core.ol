// core.ol — Standard library for VM v2
// Every function here compiles and runs on vm_nox

// Array operations — push and len are VM builtins, no wrapper needed

// String operations
fn str(x) { return __to_string(x); };

// Math
fn abs(x) { if x < 0 { return 0 - x; }; return x; };
fn max(a, b) { if a > b { return a; }; return b; };
fn min(a, b) { if a < b { return a; }; return b; };

// Mol operations
fn mol_pack(s, r, v, a, t) {
    return s * 4096 + r * 256 + v * 32 + a * 4 + t;
};
fn mol_s(m) { return __floor(m / 4096) % 16; };
fn mol_r(m) { return __floor(m / 256) % 16; };
fn mol_v(m) { return __floor(m / 32) % 8; };
fn mol_a(m) { return __floor(m / 4) % 8; };
fn mol_t(m) { return m % 4; };

fn mol_dist(a, b) {
    let ds = abs(mol_s(a) - mol_s(b));
    let dr = abs(mol_r(a) - mol_r(b));
    let dv = abs(mol_v(a) - mol_v(b)) * 2;
    let da = abs(mol_a(a) - mol_a(b)) * 2;
    let dt = abs(mol_t(a) - mol_t(b)) * 4;
    return ds + dr + dv + da + dt;
};

fn mol_dominant(m) {
    let ns = mol_s(m) * 100 / 15;
    let nr = mol_r(m) * 100 / 15;
    let nv = mol_v(m) * 100 / 7;
    let na = mol_a(m) * 100 / 7;
    let nt = mol_t(m) * 100 / 3;
    let best = 0;
    let best_d = abs(ns - 50);
    if abs(nr - 50) > best_d { let best = 1; let best_d = abs(nr - 50); };
    if abs(nv - 50) > best_d { let best = 2; let best_d = abs(nv - 50); };
    if abs(na - 50) > best_d { let best = 3; let best_d = abs(na - 50); };
    if abs(nt - 50) > best_d { let best = 4; };
    return best;
};

// Implicit silk strength
fn implicit_strength(a, b) {
    let d = mol_dist(a, b);
    if d == 0 { return 1000; };
    let s = 1000 - d * 1000 / 70;
    if s < 0 { return 0; };
    return s;
};

emit "core.ol loaded";
