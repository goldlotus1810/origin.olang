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

// KnowTree with word indexing
let facts = [];

fn learn(text) {
    let idx = len(facts);
    push(facts, text);
    // Index EACH WORD in matrix
    let ws = 0;
    let i = 0;
    while i <= len(text) {
        let is_sp = 0;
        if i == len(text) { let is_sp = 1; } else {
            if __char_code(char_at(text, i)) == 32 { let is_sp = 1; };
        };
        if is_sp == 1 {
            if i > ws {
                let word = substr(text, ws, i);
                if len(word) >= 3 {
                    let wh = encode(word);
                    __mx_w(wh, idx + 1);
                };
            };
            let ws = i + 1;
        };
        let i = i + 1;
    };
    return idx;
};

fn query(text) {
    // Try each word in query
    let ws = 0;
    let i = 0;
    while i <= len(text) {
        let is_sp = 0;
        if i == len(text) { let is_sp = 1; } else {
            if __char_code(char_at(text, i)) == 32 { let is_sp = 1; };
        };
        if is_sp == 1 {
            if i > ws {
                let word = substr(text, ws, i);
                if len(word) >= 3 {
                    let wh = encode(word);
                    let mx = __mxr(wh);
                    if mx > 0 {
                        return __array_get(facts, mx - 1);
                    };
                };
            };
            let ws = i + 1;
        };
        let i = i + 1;
    };
    return "";
};

// Learn
learn("Olang la ngon ngu lap trinh tu host");
learn("Nox la AI tu hoc va tu viet lai chinh minh");
learn("Ha Noi la thu do Viet Nam");
learn("KnowTree luu tru facts va molecules");
learn("Pipeline xu ly input thanh response");

emit "Facts: " + __to_string(len(facts));
emit "Q Olang: " + query("Olang la gi");
emit "Q Nox: " + query("Nox la gi");
emit "Q Ha Noi: " + query("Ha Noi o dau");
emit "Q Pipeline: " + query("Pipeline hoat dong sao");
emit "Q unknown: [" + query("xyz random nothing") + "]";
