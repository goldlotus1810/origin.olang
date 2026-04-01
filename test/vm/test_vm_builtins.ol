# Test VM builtins: act_matrix, pw_dist5, wm, mol_dominant

# ═══ Test __pw_dist5 (5D weighted distance) ═══
# mol_a = pack(S=15, R=0, V=0, A=0, T=0) = 0xF000 = 61440
# mol_b = pack(S=0, R=0, V=0, A=0, T=0) = 0x0000 = 0
# Expected: |ΔS|=15, |ΔR|=0, |ΔV|=0, |ΔA|=0, |ΔT|=0 → distance = 15
let _d1 = __pw_dist5(61440, 0);
if _d1 == 15 {
    emit "PASS pw_dist5 S-only";
} else {
    emit "FAIL pw_dist5 S-only: got " + _d1;
};

# mol_a = pack(S=0, R=0, V=7, A=0, T=0) = 0x00E0 = 224
# mol_b = pack(S=0, R=0, V=0, A=0, T=0) = 0
# Expected: |ΔV|=7 × 2 = 14
let _d2 = __pw_dist5(224, 0);
if _d2 == 14 {
    emit "PASS pw_dist5 V-only";
} else {
    emit "FAIL pw_dist5 V-only: got " + _d2;
};

# mol_a = pack(S=0, R=0, V=0, A=0, T=3) = 3
# mol_b = pack(S=0, R=0, V=0, A=0, T=0) = 0
# Expected: |ΔT|=3 × 4 = 12
let _d3 = __pw_dist5(3, 0);
if _d3 == 12 {
    emit "PASS pw_dist5 T-only";
} else {
    emit "FAIL pw_dist5 T-only: got " + _d3;
};

# Max distance: all dims maxed vs zero
# S=15, R=15, V=7, A=7, T=3 = 0xFFFF = 65535
# Distance = 15 + 15 + 14 + 14 + 12 = 70
let _d4 = __pw_dist5(65535, 0);
if _d4 == 70 {
    emit "PASS pw_dist5 max distance";
} else {
    emit "FAIL pw_dist5 max distance: got " + _d4;
};

# Same mol → distance 0
let _d5 = __pw_dist5(12345, 12345);
if _d5 == 0 {
    emit "PASS pw_dist5 same mol";
} else {
    emit "FAIL pw_dist5 same mol: got " + _d5;
};

# ═══ Test __wm_set / __wm_get ═══
__wm_set(0, 42);
__wm_set(1, 1000);
__wm_set(2, 65535);
__wm_set(3, 0);
let _w0 = __wm_get(0);
let _w1 = __wm_get(1);
let _w2 = __wm_get(2);
let _w3 = __wm_get(3);
if _w0 == 42 {
    emit "PASS wm slot 0";
} else {
    emit "FAIL wm slot 0: got " + _w0;
};
if _w1 == 1000 {
    emit "PASS wm slot 1";
} else {
    emit "FAIL wm slot 1: got " + _w1;
};
if _w2 == 65535 {
    emit "PASS wm slot 2";
} else {
    emit "FAIL wm slot 2: got " + _w2;
};
if _w3 == 0 {
    emit "PASS wm slot 3";
} else {
    emit "FAIL wm slot 3: got " + _w3;
};

# ═══ Test __mol_dominant ═══
# S dominant: S=15, others low → pack(15,0,0,0,0) = 0xF000 = 61440
let _dom1 = __mol_dominant(61440);
if _dom1 == 0 {
    emit "PASS mol_dominant S";
} else {
    emit "FAIL mol_dominant S: got " + _dom1;
};

# V dominant: V=7, others 0 → pack(0,0,7,0,0) = 0x00E0 = 224
let _dom3 = __mol_dominant(224);
if _dom3 == 2 {
    emit "PASS mol_dominant V";
} else {
    emit "FAIL mol_dominant V: got " + _dom3;
};

# T dominant: T=3, others 0 → pack(0,0,0,0,3) = 3
let _dom5 = __mol_dominant(3);
if _dom5 == 4 {
    emit "PASS mol_dominant T";
} else {
    emit "FAIL mol_dominant T: got " + _dom5;
};
