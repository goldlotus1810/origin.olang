// ═══ UI Dashboard — Nox System Dashboard ═══
// Modern dark theme terminal dashboard
// Layout: Header | Status | Knowledge | Log | Input
//
// ┌──────────────── NOX BRAIN v3 ─────────────────┐
// │ Status: ALIVE  Facts: 48  Silk: 10  Heap: 2MB  │
// ├────────────────────────────────────────────────┤
// │ Knowledge        │ System Log                   │
// │  > Ha Noi...     │  [02:41] boot: 48 facts     │
// │  > fire is...    │  [02:41] silk: 10 edges      │
// │  > water is...   │  [02:42] query: Ha Noi       │
// │                  │  [02:42] → answer found       │
// ├────────────────────────────────────────────────┤
// │ nox>                                            │
// └────────────────────────────────────────────────┘

let DASH_W = 120;    // terminal width
let DASH_H = 40;     // terminal height
let DASH_SPLIT = 50; // left panel width

// ═══ LOG BUFFER ═══
let dash_log = __array_with_cap(100);
let dash_log_count = [0];

fn dash_add_log(msg) {
    push(dash_log, msg);
    let _ = __set_at(dash_log_count, 0, __array_get(dash_log_count, 0) + 1);
};

// ═══ DRAW HEADER ═══
fn dash_header() {
    // Row 1: title bar
    ui_term_color_bg(15, 15, 25);
    ui_term_color_fg(79, 195, 247);  // cyan
    ui_term_bold();
    ui_term_fill(1, 1, DASH_W, 1);
    ui_term_text(1, 2, " NOX BRAIN v3 ");
    ui_term_reset();
    ui_term_color_bg(15, 15, 25);
    ui_term_color_fg(100, 100, 120);
    ui_term_text(1, 18, " | 6-layer PTAVF | Olang VM 55KB | ");
    ui_term_reset();
};

// ═══ DRAW STATUS BAR ═══
fn dash_status() {
    let kt_n = __array_get(kt_count, 0);
    let heap = __heap_used();

    // Count silk edges
    let silk_c = [0];
    let si = 0;
    while si < 65536 {
        if __mxr(si) > 0 { let _ = __set_at(silk_c, 0, __array_get(silk_c, 0) + 1); };
        let si = si + 256;  // sample every 256th for speed
    };

    ui_term_color_bg(22, 22, 30);
    ui_term_fill(2, 1, DASH_W, 1);

    // Status indicator
    ui_term_color_fg(129, 199, 132);  // green
    ui_term_text(2, 2, " ● ALIVE");

    // Facts
    ui_term_color_fg(200, 200, 210);
    ui_term_text(2, 12, " Facts: ");
    ui_term_color_fg(79, 195, 247);
    ui_term_text(2, 20, __to_string(kt_n));

    // Silk
    ui_term_color_fg(200, 200, 210);
    ui_term_text(2, 26, " Silk: ");
    ui_term_color_fg(79, 195, 247);
    ui_term_text(2, 33, __to_string(__array_get(silk_c, 0)));

    // Heap
    ui_term_color_fg(200, 200, 210);
    ui_term_text(2, 40, " Heap: ");
    ui_term_color_fg(255, 213, 79);  // yellow
    ui_term_text(2, 47, __to_string(heap));

    ui_term_reset();
};

// ═══ DRAW BORDER ═══
fn dash_border() {
    ui_term_color_fg(50, 50, 65);  // dim border
    // Horizontal lines
    ui_term_hline(3, 1, DASH_W);
    ui_term_hline(DASH_H - 3, 1, DASH_W);
    // Vertical divider
    ui_term_vline(4, DASH_SPLIT, DASH_H - 7);
    // Corners/intersections
    ui_term_move(3, DASH_SPLIT); __write_raw("┬");
    ui_term_move(DASH_H - 3, DASH_SPLIT); __write_raw("┴");
    ui_term_reset();
};

// ═══ DRAW KNOWLEDGE PANEL (left) ═══
fn dash_knowledge() {
    ui_term_color_fg(79, 195, 247);
    ui_term_bold();
    ui_term_text(4, 2, " Knowledge");
    ui_term_reset();

    let kt_n = __array_get(kt_count, 0);
    let max_show = DASH_H - 8;
    if kt_n < max_show { let max_show = kt_n; };

    let i = 0;
    while i < max_show {
        let text = __array_get(kt_texts, i);
        // Truncate to panel width
        let show = text;
        if len(text) > DASH_SPLIT - 4 {
            let show = substr(text, 0, DASH_SPLIT - 7) + "...";
        };
        ui_term_color_fg(180, 180, 190);
        ui_term_text(5 + i, 3, show);
        let i = i + 1;
    };
    ui_term_reset();
};

// ═══ DRAW LOG PANEL (right) ═══
fn dash_log_panel() {
    ui_term_color_fg(79, 195, 247);
    ui_term_bold();
    ui_term_text(4, DASH_SPLIT + 2, " System Log");
    ui_term_reset();

    let lc = __array_get(dash_log_count, 0);
    let max_show = DASH_H - 8;
    let start = 0;
    if lc > max_show { let start = lc - max_show; };

    let i = start;
    let row = 0;
    while i < lc {
        let msg = __array_get(dash_log, i);
        let show = msg;
        let panel_w = DASH_W - DASH_SPLIT - 3;
        if len(msg) > panel_w {
            let show = substr(msg, 0, panel_w - 3) + "...";
        };
        ui_term_color_fg(150, 150, 160);
        ui_term_text(5 + row, DASH_SPLIT + 2, show);
        let i = i + 1;
        let row = row + 1;
    };
    ui_term_reset();
};

// ═══ DRAW INPUT BAR ═══
fn dash_input_bar() {
    ui_term_color_bg(22, 22, 30);
    ui_term_fill(DASH_H - 2, 1, DASH_W, 1);
    ui_term_color_fg(79, 195, 247);
    ui_term_text(DASH_H - 2, 2, " nox> ");
    ui_term_color_fg(200, 200, 210);
    ui_term_reset();
};

// ═══ DRAW FULL DASHBOARD ═══
fn dash_draw() {
    ui_term_clear();
    ui_term_hide_cursor();
    ui_term_color_bg(10, 10, 15);  // dark bg
    ui_term_fill(1, 1, DASH_W, DASH_H);

    dash_header();
    dash_status();
    dash_border();
    dash_knowledge();
    dash_log_panel();
    dash_input_bar();

    // Move cursor to input
    ui_term_show_cursor();
    ui_term_move(DASH_H - 2, 8);
};

emit "ui_dashboard loaded";
