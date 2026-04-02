// ═══ UI SDF — Signed Distance Field Rendering ═══
// Spec: SPEC_A Foundation — SDF as root abstraction
//
// SDF = function mapping point → distance-to-surface
// Inside = negative, on edge = 0, outside = positive
// Used for: anti-aliased shapes, smooth corners, shadows, glow
//
// All rendering in integer math (×1000 for precision)
// Output: terminal block characters with color gradients

// ═══ SDF PRIMITIVES ═══
// All take (px, py) in 1000ths, return distance in 1000ths
// Negative = inside, 0 = edge, positive = outside

// Circle: center (cx,cy), radius r
fn sdf_circle(px, py, cx, cy, r) {
    let dx = px - cx;
    let dy = py - cy;
    // sqrt(dx²+dy²) - r
    let dist_sq = dx * dx + dy * dy;
    let dist = __floor(__sqrt(dist_sq));
    return dist - r;
};

// Rectangle: center (cx,cy), half-width hw, half-height hh
fn sdf_rect(px, py, cx, cy, hw, hh) {
    let dx = px - cx; if dx < 0 { let dx = 0 - dx; };
    let dy = py - cy; if dy < 0 { let dy = 0 - dy; };
    let ex = dx - hw;
    let ey = dy - hh;
    // max(ex,ey) for inside, length(max(e,0)) for outside
    if ex < 0 { if ey < 0 {
        // Inside: return max(ex,ey) = most negative
        if ex > ey { return ex; };
        return ey;
    }; };
    // Outside
    let ox = ex; if ox < 0 { let ox = 0; };
    let oy = ey; if oy < 0 { let oy = 0; };
    return __floor(__sqrt(ox * ox + oy * oy));
};

// Rounded rectangle: center, half-size, corner radius
fn sdf_round_rect(px, py, cx, cy, hw, hh, r) {
    return sdf_rect(px, py, cx, cy, hw - r, hh - r) - r;
};

// Line segment: from (ax,ay) to (bx,by)
fn sdf_line(px, py, ax, ay, bx, by) {
    let bax = bx - ax; let bay = by - ay;
    let pax = px - ax; let pay = py - ay;
    let dot_pa_ba = pax * bax + pay * bay;
    let dot_ba_ba = bax * bax + bay * bay;
    if dot_ba_ba == 0 { return __floor(__sqrt(pax * pax + pay * pay)); };
    let t = __floor(dot_pa_ba * 1000 / dot_ba_ba);
    if t < 0 { let t = 0; };
    if t > 1000 { let t = 1000; };
    let cx = ax + __floor(bax * t / 1000);
    let cy = ay + __floor(bay * t / 1000);
    let dx = px - cx; let dy = py - cy;
    return __floor(__sqrt(dx * dx + dy * dy));
};

// ═══ SDF OPERATIONS ═══

// Union: min(a, b)
fn sdf_union(a, b) { if a < b { return a; }; return b; };

// Intersection: max(a, b)
fn sdf_intersect(a, b) { if a > b { return a; }; return b; };

// Subtraction: max(a, -b)
fn sdf_subtract(a, b) {
    let nb = 0 - b;
    if a > nb { return a; };
    return nb;
};

// Smooth union (smooth min)
fn sdf_smooth_union(a, b, k) {
    if k == 0 { return sdf_union(a, b); };
    let h = b - a + k;
    if h < 0 { let h = 0; };
    if h > k * 2 { let h = k * 2; };
    let h = __floor(h * 1000 / (k * 2));  // normalize to 0-1000
    let blend = __floor(h * h * k / (4 * 1000 * 1000));
    let m = sdf_union(a, b);
    return m - blend;
};

// ═══ SDF → TERMINAL RENDERING ═══
// Map SDF distance to character + color

// Block characters by fill level:
// Full block: █ (0x2588)
// 7/8: ▉ (0x2589), 3/4: ▊ (0x258A), 5/8: ▋ (0x258B)
// 1/2: ▌ (0x258C), 3/8: ▍ (0x258D), 1/4: ▎ (0x258E), 1/8: ▏ (0x258F)
// Or use shading: ░ ▒ ▓ █

fn sdf_shade(dist) {
    // dist < -500 → full inside → █
    // dist -500..-100 → mostly inside → ▓
    // dist -100..100 → edge → ▒
    // dist 100..500 → mostly outside → ░
    // dist > 500 → outside → space
    if dist < 0 - 500 { return 4; };      // full
    if dist < 0 - 100 { return 3; };      // heavy
    if dist < 100     { return 2; };      // medium
    if dist < 500     { return 1; };      // light
    return 0;                              // empty
};

fn sdf_draw_shade(row, col, shade) {
    ui_term_move(row, col);
    if shade == 4 { __write_raw("█"); };
    if shade == 3 { __write_raw("▓"); };
    if shade == 2 { __write_raw("▒"); };
    if shade == 1 { __write_raw("░"); };
    if shade == 0 { __write_raw(" "); };
};

// ═══ RENDER SDF SHAPE TO TERMINAL ═══
// Renders an SDF function over a rectangular region
// sdf_fn must be: fn(px, py) → distance
// Maps terminal (col,row) to SDF coordinates: px = col*1000, py = row*2000 (chars are ~2:1)

fn sdf_render_rect(row, col, w, h, cx, cy, hw, hh, r, fg_r, fg_g, fg_b) {
    ui_term_color_fg(fg_r, fg_g, fg_b);
    let ry = 0;
    while ry < h {
        let rx = 0;
        while rx < w {
            let px = (col + rx) * 1000;
            let py = (row + ry) * 2000;  // aspect ratio correction
            let d = sdf_round_rect(px, py, cx * 1000, cy * 2000, hw * 1000, hh * 2000, r * 1000);
            let shade = sdf_shade(d);
            if shade > 0 { sdf_draw_shade(row + ry, col + rx, shade); };
            let rx = rx + 1;
        };
        let ry = ry + 1;
    };
    ui_term_reset();
};

fn sdf_render_circle(row, col, w, h, cx, cy, radius, fg_r, fg_g, fg_b) {
    ui_term_color_fg(fg_r, fg_g, fg_b);
    let ry = 0;
    while ry < h {
        let rx = 0;
        while rx < w {
            let px = (col + rx) * 1000;
            let py = (row + ry) * 2000;
            let d = sdf_circle(px, py, cx * 1000, cy * 2000, radius * 1000);
            let shade = sdf_shade(d);
            if shade > 0 { sdf_draw_shade(row + ry, col + rx, shade); };
            let rx = rx + 1;
        };
        let ry = ry + 1;
    };
    ui_term_reset();
};

emit "ui_sdf loaded";
