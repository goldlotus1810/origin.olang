// knowtree.ol — KnowTree for VM v2
// Parallel arrays + mol_matrix O(1) + bucket fallback

let __kt_facts = [];
let __kt_facts_mol = [];
let __kt_count = [0];

fn kt_fact_count() { return __array_get(__kt_count, 0); };

fn kt_learn(text) {
    let idx = __array_get(__kt_count, 0);
    push(__kt_facts, text);
    push(__kt_facts_mol, 0);
    let _ = __set_at(__kt_count, 0, idx + 1);
    return idx;
};

fn kt_fact_at(i) {
    if i < __array_get(__kt_count, 0) {
        return __array_get(__kt_facts, i);
    };
    return "";
};

fn kt_nearest_text(mol) {
    // Matrix exact: O(1)
    let mx = __mxr(mol);
    if mx > 0 {
        let fi = mx - 1;
        if fi < __array_get(__kt_count, 0) {
            return __array_get(__kt_facts, fi);
        };
    };
    // Fallback: scan all facts, find min distance
    let best_i = 0 - 1;
    let best_d = 99999;
    let i = 0;
    let n = __array_get(__kt_count, 0);
    while i < n {
        let fm = __array_get(__kt_facts_mol, i);
        if fm > 0 {
            let d = mol_dist(mol, fm);
            if d < best_d { let best_d = d; let best_i = i; };
        };
        let i = i + 1;
    };
    if best_i >= 0 { return __array_get(__kt_facts, best_i); };
    return "";
};

emit "knowtree loaded";
