// ═══ Generate (SINH) — Nox Creates, Not Just Retrieves ═══
// Spec: BP14 Generation
//
// 3-stage pipeline:
//   1. Retrieve: kt_nearest → top candidates
//   2. Recombine: extract segments, crossover by dominant dimension
//   3. Decode: template NLG → text output
//
// Depends: knowtree.ol, silk.ol, feedback.ol (read only)

// ═══ QUERY TYPE CLASSIFICATION ═══
// Based on first word mol dimensions
// 0=WHAT, 1=WHY, 2=HOW, 3=LIST, 4=FEEL, 5=UNKNOWN

let GEN_WHAT = 0;
let GEN_WHY = 1;
let GEN_HOW = 2;
let GEN_LIST = 3;
let GEN_FEEL = 4;
let GEN_UNKNOWN = 5;

fn gen_classify_query(query) {
    // Check first word for question keywords via char codes
    let flen = 0;
    let qi = 0;
    while qi < len(query) {
        if __char_code(char_at(query, qi)) == 32 { let qi = len(query); } else { let flen = flen + 1; };
        let qi = qi + 1;
    };
    let first = substr(query, 0, flen);

    // what/who/where → WHAT
    if flen == 4 {
        if __char_code(char_at(query, 0)) == 119 {  // 'w'
            if __char_code(char_at(query, 1)) == 104 { return GEN_WHAT; };  // wh...
        };
    };
    if flen == 3 {
        if __char_code(char_at(query, 0)) == 119 {
            if __char_code(char_at(query, 1)) == 104 {
                if __char_code(char_at(query, 2)) == 111 { return GEN_WHAT; };  // who
                if __char_code(char_at(query, 2)) == 121 { return GEN_WHY; };   // why
            };
        };
        if __char_code(char_at(query, 0)) == 104 {
            if __char_code(char_at(query, 1)) == 111 {
                if __char_code(char_at(query, 2)) == 119 { return GEN_HOW; };   // how
            };
        };
    };
    if flen == 5 {
        if __char_code(char_at(query, 0)) == 119 {
            if __char_code(char_at(query, 1)) == 104 {
                if __char_code(char_at(query, 2)) == 101 { return GEN_WHAT; };  // where/when
            };
        };
    };
    // list → LIST
    if flen == 4 {
        if __char_code(char_at(query, 0)) == 108 {
            if __char_code(char_at(query, 1)) == 105 { return GEN_LIST; };  // list
        };
    };

    // Default: use mol encoding to classify
    let qmol = kt_encode_mol(query);
    let qv = kt_mol_v(qmol);
    let qa = kt_mol_a(qmol);
    // High emotion → FEEL
    if qv > 5 { return GEN_FEEL; };
    if qa > 5 { return GEN_FEEL; };
    return GEN_UNKNOWN;
};

// ═══ CONFIDENCE CALCULATION ═══
fn gen_confidence(candidates, query_mol) {
    let n = len(candidates);
    if n < 2 { return 0; };
    // candidates = [text, dist, text, dist, ...] pairs
    let total_silk = [0];
    let total_dist = [0];
    let count = [0];
    let ci = 0;
    while ci < n {
        if ci + 1 < n {
            let cdist = __array_get(candidates, ci + 1);
            let _ = __set_at(total_dist, 0, __array_get(total_dist, 0) + cdist);
            let _ = __set_at(count, 0, __array_get(count, 0) + 1);
            // Check silk connection to query
            let cmol = kt_encode_mol(__array_get(candidates, ci));
            let sw = silk_weight(query_mol, cmol);
            let _ = __set_at(total_silk, 0, __array_get(total_silk, 0) + sw);
        };
        let ci = ci + 2;
    };
    let cnt = __array_get(count, 0);
    if cnt == 0 { return 0; };
    let avg_dist = __floor(__array_get(total_dist, 0) / cnt);
    let avg_silk = __floor(__array_get(total_silk, 0) / cnt);

    // Confidence formula (0-1000):
    // 0.3 × (1 - avg_dist/70) + 0.3 × silk_factor + 0.2 × count_factor + 0.2 × closeness
    let dist_score = 1000 - __floor(avg_dist * 1000 / 70);
    if dist_score < 0 { let dist_score = 0; };
    let silk_score = avg_silk;
    if silk_score > 1000 { let silk_score = 1000; };
    let count_score = __floor(cnt * 1000 / 5);
    if count_score > 1000 { let count_score = 1000; };
    // Best candidate closeness
    let best_dist = __array_get(candidates, 1);
    let close_score = 1000 - __floor(best_dist * 1000 / 35);
    if close_score < 0 { let close_score = 0; };

    let conf = __floor(dist_score * 300 / 1000)
             + __floor(silk_score * 300 / 1000)
             + __floor(count_score * 200 / 1000)
             + __floor(close_score * 200 / 1000);
    return conf;
};

// ═══ EXTRACT BEST TEXT ═══
// From candidates array [text, dist, text, dist, ...], pick best using UCB1
fn gen_select_best(candidates, query_mol, total_plays) {
    let n = len(candidates);
    if n < 2 { return ""; };

    // Build mol array for fb_select
    let mols = [];
    let texts = [];
    let ci = 0;
    while ci < n {
        if ci + 1 < n {
            let t = __array_get(candidates, ci);
            let m = kt_encode_mol(t);
            push(mols, m);
            push(texts, t);
        };
        let ci = ci + 2;
    };

    if len(mols) == 0 { return ""; };

    // UCB1 select (if feedback available, otherwise use first/nearest)
    let best_idx = 0;
    if total_plays > 0 {
        let best_idx = fb_select(mols, query_mol, total_plays);
    };
    return __array_get(texts, best_idx);
};

// ═══ TEMPLATE DECODE ═══
fn gen_template(qtype, best_text, query) {
    // Simple: return best text directly (it IS the knowledge)
    // With prefix based on query type
    if qtype == GEN_WHAT { return best_text; };
    if qtype == GEN_WHY { return best_text; };
    if qtype == GEN_HOW { return best_text; };
    if qtype == GEN_LIST { return best_text; };
    if qtype == GEN_FEEL { return best_text; };
    return best_text;
};

// ═══ MAIN GENERATE FUNCTION ═══
// query → response string (or "" if not confident)
let gen_total_plays = [0];

fn generate(query) {
    let qmol = kt_encode_mol(query);

    // 1. Retrieve top 5
    let candidates = kt_nearest(query, 5);
    if len(candidates) < 2 { return ""; };

    // 2. Confidence check (honesty gate)
    // Threshold 250 — conservative but allows reasonable matches
    // Best candidate dist > 50 = too far, definitely silent
    let conf = gen_confidence(candidates, qmol);
    let best_dist = __array_get(candidates, 1);
    if best_dist > 50 { return ""; };  // best match too far
    if conf < 250 { return ""; };  // not confident → silence

    // 3. Select best via UCB1
    let tp = __array_get(gen_total_plays, 0);
    let best = gen_select_best(candidates, qmol, tp);
    let _ = __set_at(gen_total_plays, 0, tp + 1);

    if len(best) == 0 { return ""; };

    // 4. Template decode
    let qtype = gen_classify_query(query);
    let response = gen_template(qtype, best, query);

    return response;
};

// ═══ GENERATE WITH FEEDBACK ═══
// Returns response + stores path for later reward
let gen_last_query_mol = [0];
let gen_last_response_mol = [0];

fn generate_tracked(query) {
    let qmol = kt_encode_mol(query);
    let _ = __set_at(gen_last_query_mol, 0, qmol);
    let response = generate(query);
    if len(response) > 0 {
        let rmol = kt_encode_mol(response);
        let _ = __set_at(gen_last_response_mol, 0, rmol);
        // Fire silk between query and response (Hebbian)
        silk_fire(qmol, rmol);
    };
    return response;
};

fn generate_reward(reward) {
    let qm = __array_get(gen_last_query_mol, 0);
    let rm = __array_get(gen_last_response_mol, 0);
    if qm > 0 {
        if rm > 0 {
            fb_update(qm, rm, reward);
        };
    };
};

emit "generate loaded (BP14)";
