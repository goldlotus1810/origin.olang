// stdlib/homeos/encoder.ol — Text → Molecule Encoder (OL.1)
//
// Converts text/codepoints into MolecularChain representation.
// Uses block-range UCD mapper (59 Unicode blocks → default P_weights).
//
// Pipeline: text → chars → codepoints → encode_codepoint(cp) → chain → LCA
//
// Runs in BOOT context (stdlib). Called by repl.ol pipeline.

// ════════════════════════════════════════════════════════════════
// Block-range UCD mapper
// ════════════════════════════════════════════════════════════════
// 30+ Unicode blocks → default P_weight (packed u16)
// Codepoint in block → use block's dominant molecule.
// Precision: block-level (not per-char). Sufficient for prototype.

// Lookup: codepoint → packed u16 P_weight
// mol_pack: same as mol_new but using * instead of << (VM lacks __bit_shl)
fn _mol_pack(s, r, v, a, t) {
    return (s * 4096) + (r * 256) + (v * 32) + (a * 4) + t;
}

pub fn encode_codepoint(cp) {
    // ── ASCII fast path ──
    if cp >= 97 && cp <= 122 { return _mol_pack(0, 0, 4, 4, 2); };  // a-z
    if cp >= 65 && cp <= 90  { return _mol_pack(0, 0, 4, 5, 2); };  // A-Z
    if cp >= 48 && cp <= 57  { return _mol_pack(1, 0, 4, 4, 0); };  // 0-9
    if cp == 32 { return _mol_pack(3, 3, 4, 0, 0); };               // space
    if cp == 33 { return _mol_pack(6, 5, 6, 7, 3); };               // !
    if cp == 63 { return _mol_pack(6, 5, 4, 6, 3); };               // ?
    if cp == 46 { return _mol_pack(3, 3, 4, 1, 0); };               // .
    if cp == 44 { return _mol_pack(3, 4, 4, 2, 1); };               // ,

    // ── SDF blocks (Shape dominant) ──
    if cp >= 0x2190 && cp <= 0x21FF { return _mol_pack(1, 5, 4, 4, 2); };  // Arrows
    if cp >= 0x2500 && cp <= 0x257F { return _mol_pack(1, 2, 4, 2, 0); };  // Box Drawing
    if cp >= 0x25A0 && cp <= 0x25FF { return _mol_pack(0, 0, 4, 3, 0); };  // Geometric
    if cp >= 0x2700 && cp <= 0x27BF { return _mol_pack(8, 0, 5, 4, 1); };  // Dingbats
    if cp >= 0x2300 && cp <= 0x23FF { return _mol_pack(7, 4, 4, 3, 2); };  // Misc Technical

    // ── MATH blocks (Relation dominant) ──
    if cp >= 0x2200 && cp <= 0x22FF { return _mol_pack(0, 4, 4, 4, 1); };  // Math Operators
    if cp >= 0x2100 && cp <= 0x214F { return _mol_pack(0, 2, 4, 3, 1); };  // Letterlike
    if cp >= 0x2A00 && cp <= 0x2AFF { return _mol_pack(0, 4, 4, 4, 1); };  // Supp Math

    // ── EMOTICON sub-ranges (fine-grained V/A) ──
    // Happy: 😀😁😂🤣😃😄😅😆😊😋😎 (U+1F600-U+1F60E)
    if cp >= 0x1F600 && cp <= 0x1F60E { return _mol_pack(0, 0, 7, 6, 2); };
    // Love: 😍😘😗😙😚 (U+1F60D-U+1F61A)
    if cp >= 0x1F60D && cp <= 0x1F61A { return _mol_pack(0, 0, 7, 5, 2); };
    // Sad/Cry: 😢😥😿 (U+1F622,U+1F625)
    if cp == 0x1F622 { return _mol_pack(0, 0, 2, 4, 2); };  // 😢 crying
    if cp == 0x1F625 { return _mol_pack(0, 0, 2, 3, 2); };  // 😥 disappointed
    if cp == 0x1F62D { return _mol_pack(0, 0, 1, 6, 2); };  // 😭 loudly crying
    if cp == 0x1F629 { return _mol_pack(0, 0, 2, 5, 2); };  // 😩 weary
    if cp == 0x1F62B { return _mol_pack(0, 0, 2, 6, 2); };  // 😫 tired
    // Angry: 😠😡🤬 (U+1F620,U+1F621)
    if cp == 0x1F620 { return _mol_pack(0, 0, 1, 6, 2); };  // 😠 angry
    if cp == 0x1F621 { return _mol_pack(0, 0, 1, 7, 2); };  // 😡 pouting
    if cp == 0x1F92C { return _mol_pack(0, 0, 1, 7, 2); };  // 🤬 cursing
    // Fear/Shock: 😨😰😱 (U+1F628,U+1F630,U+1F631)
    if cp == 0x1F628 { return _mol_pack(0, 0, 2, 6, 2); };  // 😨 fearful
    if cp == 0x1F630 { return _mol_pack(0, 0, 2, 6, 2); };  // 😰 anxious
    if cp == 0x1F631 { return _mol_pack(0, 0, 2, 7, 2); };  // 😱 screaming
    // Neutral/Thinking: 🤔😐😑 (U+1F914,U+1F610,U+1F611)
    if cp == 0x1F914 { return _mol_pack(0, 0, 4, 3, 2); };  // 🤔 thinking
    if cp == 0x1F610 { return _mol_pack(0, 0, 4, 2, 2); };  // 😐 neutral
    // Heart: ❤ (U+2764)
    if cp == 0x2764 { return _mol_pack(0, 0, 7, 5, 2); };   // ❤ red heart
    // Thumbs: 👍👎
    if cp == 0x1F44D { return _mol_pack(0, 0, 6, 4, 2); };  // 👍 thumbs up
    if cp == 0x1F44E { return _mol_pack(0, 0, 2, 4, 2); };  // 👎 thumbs down
    // Fire/Star: 🔥⭐
    if cp == 0x1F525 { return _mol_pack(8, 5, 6, 7, 2); };  // 🔥 fire
    if cp == 0x2B50 { return _mol_pack(0, 0, 6, 5, 2); };   // ⭐ star
    // Remaining emoticons (fallback)
    if cp >= 0x1F600 && cp <= 0x1F64F { return _mol_pack(0, 0, 5, 5, 2); }; // Emoticons
    // ── Other symbol blocks ──
    if cp >= 0x2600 && cp <= 0x26FF { return _mol_pack(0, 0, 5, 5, 1); };  // Misc Symbols
    if cp >= 0x1F300 && cp <= 0x1F5FF { return _mol_pack(0, 0, 6, 5, 2); }; // Misc Sym+Pict
    if cp >= 0x1F680 && cp <= 0x1F6FF { return _mol_pack(7, 5, 5, 5, 2); }; // Transport
    if cp >= 0x1F900 && cp <= 0x1F9FF { return _mol_pack(0, 0, 5, 5, 1); }; // Supp Symbols

    // ── MUSICAL blocks (Time dominant) ──
    if cp >= 0x1D100 && cp <= 0x1D1FF { return _mol_pack(0, 0, 5, 5, 3); }; // Musical

    // ── Latin Extended (accented chars → same as lowercase) ──
    if cp >= 0xC0 && cp <= 0x24F { return _mol_pack(0, 0, 4, 4, 2); };

    // Fallback: default neutral
    return _mol_pack(0, 0, 4, 4, 2);
}

// ════════════════════════════════════════════════════════════════
// LCA Composition (amplify, NOT average)
// ════════════════════════════════════════════════════════════════

fn _enc_max(a, b) { if a > b { return a; }; return b; }
fn _enc_min(a, b) { if a < b { return a; }; return b; }
// _enc_abs removed — dead code (0 calls)

// Unpack mol dimensions (using / and % instead of >> and & — VM lacks bit ops)
fn _mol_s(mol) { return __floor(mol / 4096) % 16; }
fn _mol_r(mol) { return __floor(mol / 256) % 16; }
fn _mol_v(mol) { return __floor(mol / 32) % 8; }
fn _mol_a(mol) { return __floor(mol / 4) % 8; }
fn _mol_t(mol) { return mol % 4; }

// R dispatch: relation index → behavior tag (T5 foundation)

// Temporal tag: T index → time description (T5 foundation)

// Spec §1.6: amplify(Va, Vb, w) — khuếch đại về phía dominant, KHÔNG trung bình
// base  = (Va + Vb) / 2
// boost = |Va − base| × w × 0.5
// Cv    = base + sign(Va + Vb - 8) × boost   (8 = 2×neutral, sign relative to center)
// w = 0.618 (golden ratio — biological scaling)

// Spec §1.6: Compose R — tổ hợp quan hệ (not just average)
// Compose: if same relation → strengthen, if different → higher-order relation

// Spec §1.6: Union S — SDF hợp nhất (take max shape complexity)

// Spec §1.6: dominant T — thời gian lấy chủ đạo



// ════════════════════════════════════════════════════════════════
// UTF-8 Decoder — reconstruct full Unicode codepoint from bytes
// ════════════════════════════════════════════════════════════════
// VM stores strings as u16 molecules (0x2100|byte). Multi-byte UTF-8
// chars (emoji, Vietnamese diacritics) become separate molecules.
// This decoder reads byte sequence → full codepoint.
//
// UTF-8 layout:
//   1-byte: 0xxxxxxx                    (0x00-0x7F)
//   2-byte: 110xxxxx 10xxxxxx           (0xC0-0xDF)
//   3-byte: 1110xxxx 10xxxxxx 10xxxxxx  (0xE0-0xEF)
//   4-byte: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx (0xF0-0xF7)
// Bit masking via modulo: b & 0x3F = b % 64, b & 0x1F = b % 32, etc.

pub fn utf8_decode(_ud_text, _ud_i) {
    let _ud_n = len(_ud_text);
    if _ud_i >= _ud_n { return { cp: 0, sz: 0 }; };
    let _ud_b0 = __char_code(char_at(_ud_text, _ud_i));
    // 1-byte ASCII
    if _ud_b0 < 128 {
        return { cp: _ud_b0, sz: 1 };
    };
    // 4-byte: emoji, rare CJK (0xF0-0xF7)
    if _ud_b0 >= 240 {
        if (_ud_i + 3) >= _ud_n { return { cp: _ud_b0, sz: 1 }; };
        let _ud_b1 = __char_code(char_at(_ud_text, _ud_i + 1)) % 64;
        let _ud_b2 = __char_code(char_at(_ud_text, _ud_i + 2)) % 64;
        let _ud_b3 = __char_code(char_at(_ud_text, _ud_i + 3)) % 64;
        // cp = (b0 & 0x07)*262144 + b1*4096 + b2*64 + b3
        // Explicit parens — Rust compiler precedence bug
        let _ud_cp = ((_ud_b0 % 8) * 262144) + ((_ud_b1 * 4096) + ((_ud_b2 * 64) + _ud_b3));
        return { cp: _ud_cp, sz: 4 };
    };
    // 3-byte: Vietnamese diacritics (0x1EA0-0x1EFF), CJK, misc symbols
    if _ud_b0 >= 224 {
        if (_ud_i + 2) >= _ud_n { return { cp: _ud_b0, sz: 1 }; };
        let _ud_b1 = __char_code(char_at(_ud_text, _ud_i + 1)) % 64;
        let _ud_b2 = __char_code(char_at(_ud_text, _ud_i + 2)) % 64;
        let _ud_cp = ((_ud_b0 % 16) * 4096) + ((_ud_b1 * 64) + _ud_b2);
        return { cp: _ud_cp, sz: 3 };
    };
    // 2-byte: Latin extended, accented chars (0xC0-0xDF)
    if (_ud_i + 1) >= _ud_n { return { cp: _ud_b0, sz: 1 }; };
    let _ud_b1 = __char_code(char_at(_ud_text, _ud_i + 1)) % 64;
    let _ud_cp = ((_ud_b0 % 32) * 64) + _ud_b1;
    return { cp: _ud_cp, sz: 2 };
}

// Is this codepoint an emoji? (emoticon/symbol blocks with high V/A)

// ════════════════════════════════════════════════════════════════
// Text → MolecularChain (UTF-8 aware)
// ════════════════════════════════════════════════════════════════

pub fn encode_text(text) {
    let mols = [];
    let i = 0;
    let n = len(text);
    while i < n {
        let _et_dec = utf8_decode(text, i);
        let _et_cp = _et_dec.cp;
        let _et_sz = _et_dec.sz;
        if _et_sz == 0 { break; };
        if _et_cp > 32 {
            push(mols, encode_codepoint(_et_cp));
        };
        let i = i + _et_sz;
        if len(mols) >= 64 { break; };
    };
    if len(mols) == 0 { return _mol_pack(0, 0, 4, 4, 2); };
    return mol_compose_many(mols);
}

// Extract emotion directly from Unicode properties of text
// Emoji carry emotion intrinsically — no hardcoding needed
pub fn text_emotion_unicode(_teu_text) {
    let _teu_v = 4;
    let _teu_a = 4;
    let _teu_emoji_hits = 0;
    let _teu_i = 0;
    let _teu_n = len(_teu_text);
    while _teu_i < _teu_n {
        let _teu_dec = utf8_decode(_teu_text, _teu_i);
        let _teu_cp = _teu_dec.cp;
        let _teu_sz = _teu_dec.sz;
        if _teu_sz == 0 { break; };
        // Multi-byte char (non-ASCII) → check if emoji
        if _teu_cp > 127 {
            if _is_emoji_cp(_teu_cp) == 1 {
                // Use encode_codepoint → extract V/A from molecule
                let _teu_mol = encode_codepoint(_teu_cp);
                let _teu_mv = _mol_v(_teu_mol);
                let _teu_ma = _mol_a(_teu_mol);
                // Emoji V/A is in 0-7 scale, use directly
                _teu_v = _teu_mv;
                _teu_a = _teu_ma;
                _teu_emoji_hits = _teu_emoji_hits + 1;
            };
        } else {
            // ASCII: punctuation affects arousal
            if _teu_cp == 33 { _teu_a = _enc_min(7, _teu_a + 1); _teu_v = _enc_min(7, _teu_v + 1); };
            if _teu_cp == 63 { _teu_a = _enc_min(7, _teu_a + 1); };
        };
        let _teu_i = _teu_i + _teu_sz;
    };
    return { v: _teu_v, a: _teu_a, emoji_count: _teu_emoji_hits };
}

// ════════════════════════════════════════════════════════════════
// ════════════════════════════════════════════════════════════════
// Vietnamese word stemming — strip common prefixes/modifiers
// ════════════════════════════════════════════════════════════════
// "dang buon" → split → "dang" (skip) + "buon" (affect hit)
// "rat vui" → "rat" (intensifier) + "vui" (affect hit, amplified)
// These prefixes are removed before word_affect lookup.

let __vi_prefixes = ["dang", "da", "se", "cung", "van", "hay", "nay", "the"];
let __vi_intensifiers = ["rat", "qua", "lam", "cuc", "sieu", "het"];
let __vi_negators = ["khong", "chua", "ko", "kh"];

fn _vi_is_prefix(_vp_word) {
    let _vp_i = 0;
    while _vp_i < len(__vi_prefixes) {
        if __vi_prefixes[_vp_i] == _vp_word { return 1; };
        let _vp_i = _vp_i + 1;
    };
    return 0;
}

fn _vi_is_intensifier(_vi_word) {
    let _vi_i = 0;
    while _vi_i < len(__vi_intensifiers) {
        if __vi_intensifiers[_vi_i] == _vi_word { return 1; };
        let _vi_i = _vi_i + 1;
    };
    return 0;
}

fn _vi_is_negator(_vn_word) {
    let _vn_i = 0;
    while _vn_i < len(__vi_negators) {
        if __vi_negators[_vn_i] == _vn_word { return 1; };
        let _vn_i = _vn_i + 1;
    };
    return 0;
}

// Enhanced text_emotion with stemming: handles "rat buon", "khong vui", "dang lo"
pub fn text_emotion_v2(_tev_text) {
    let _tev_v = 4;
    let _tev_a = 4;
    let _tev_hits = 0;
    let _tev_negate = 0;
    let _tev_intensify = 0;
    let _tev_w = "";
    let _tev_i = 0;
    while _tev_i < len(_tev_text) {
        let _tev_ch = char_at(_tev_text, _tev_i);
        let _tev_code = __char_code(_tev_ch);
        if _tev_code == 32 {
            if len(_tev_w) >= 2 {
                // Check modifiers first
                if _vi_is_negator(_tev_w) == 1 {
                    _tev_negate = 1;
                } else {
                    if _vi_is_intensifier(_tev_w) == 1 {
                        _tev_intensify = 1;
                    } else {
                        if _vi_is_prefix(_tev_w) == 0 {
                            // Real content word → lookup affect
                            let _tev_af = word_affect(_tev_w);
                            if _tev_af.v != 4 {
                                let _tev_nv = _tev_af.v;
                                let _tev_na = _tev_af.a;
                                // Apply negation: flip valence around neutral (4)
                                if _tev_negate == 1 {
                                    _tev_nv = 8 - _tev_nv;
                                    _tev_negate = 0;
                                };
                                // Apply intensifier: push away from neutral
                                if _tev_intensify == 1 {
                                    if _tev_nv > 4 { _tev_nv = _enc_min(7, _tev_nv + 1); };
                                    if _tev_nv < 4 { _tev_nv = _enc_max(1, _tev_nv - 1); };
                                    _tev_na = _enc_min(7, _tev_na + 1);
                                    _tev_intensify = 0;
                                };
                                _tev_v = _tev_nv;
                                _tev_a = _tev_na;
                                _tev_hits = _tev_hits + 1;
                            } else {
                                // Non-affect word → reset modifiers
                                _tev_negate = 0;
                                _tev_intensify = 0;
                            };
                        };
                    };
                };
            };
            _tev_w = "";
        } else {
            // Punctuation handling
            if _tev_code == 33 { _tev_a = _enc_min(7, _tev_a + 1); _tev_v = _enc_min(7, _tev_v + 1); };
            if _tev_code == 63 { _tev_a = _enc_min(7, _tev_a + 1); };
            if _tev_code == 46 { _tev_a = _enc_max(0, _tev_a - 1); };
            _tev_w = _tev_w + _tev_ch;
        };
        let _tev_i = _tev_i + 1;
    };
    // Check last word
    if len(_tev_w) >= 2 {
        if _vi_is_prefix(_tev_w) == 0 {
            if _vi_is_intensifier(_tev_w) == 0 {
                if _vi_is_negator(_tev_w) == 0 {
                    let _tev_af = word_affect(_tev_w);
                    if _tev_af.v != 4 {
                        let _tev_nv = _tev_af.v;
                        if _tev_negate == 1 { _tev_nv = 8 - _tev_nv; };
                        if _tev_intensify == 1 {
                            if _tev_nv > 4 { _tev_nv = _enc_min(7, _tev_nv + 1); };
                            if _tev_nv < 4 { _tev_nv = _enc_max(1, _tev_nv - 1); };
                        };
                        _tev_v = _tev_nv;
                        _tev_a = _tev_af.a;
                    };
                };
            };
        };
    };
    // Fuse with Unicode/emoji emotion — emoji takes precedence over words
    let _tev_ue = text_emotion_unicode(_tev_text);
    if _tev_ue.emoji_count > 0 {
        // Emoji detected → blend: 70% emoji + 30% word (emoji is more reliable)
        if _tev_hits > 0 {
            _tev_v = __floor(( (_tev_ue.v * 7) + (_tev_v * 3) ) / 10);
            _tev_a = __floor(( (_tev_ue.a * 7) + (_tev_a * 3) ) / 10);
        } else {
            // No word hits → use emoji 100%
            _tev_v = _tev_ue.v;
            _tev_a = _tev_ue.a;
        };
    };
    return { v: _tev_v, a: _tev_a };
}

// Word affect table (minimal Vietnamese + English)
// ════════════════════════════════════════════════════════════════

pub fn word_affect(_wa_word) {
    // Vietnamese — negative
    if _wa_word == "buon" { return { v: 2, a: 2 }; };
    if _wa_word == "gian" { return { v: 1, a: 6 }; };
    if _wa_word == "so" { return { v: 2, a: 6 }; };
    if _wa_word == "ghet" { return { v: 1, a: 6 }; };
    if _wa_word == "met" { return { v: 2, a: 2 }; };
    if _wa_word == "chan" { return { v: 2, a: 1 }; };
    if _wa_word == "lo" { return { v: 2, a: 5 }; };
    if _wa_word == "dau" { return { v: 1, a: 5 }; };
    if _wa_word == "khoc" { return { v: 1, a: 4 }; };
    if _wa_word == "that" { return { v: 1, a: 3 }; };
    if _wa_word == "co" { return { v: 2, a: 3 }; };
    if _wa_word == "kho" { return { v: 2, a: 4 }; };
    if _wa_word == "nan" { return { v: 1, a: 5 }; };
    if _wa_word == "mat" { return { v: 1, a: 4 }; };
    if _wa_word == "xau" { return { v: 2, a: 3 }; };
    if _wa_word == "tuc" { return { v: 1, a: 6 }; };
    // Vietnamese — positive
    if _wa_word == "vui" { return { v: 6, a: 5 }; };
    if _wa_word == "yeu" { return { v: 7, a: 4 }; };
    if _wa_word == "thuong" { return { v: 6, a: 3 }; };
    if _wa_word == "tot" { return { v: 6, a: 3 }; };
    if _wa_word == "dep" { return { v: 6, a: 3 }; };
    if _wa_word == "gioi" { return { v: 6, a: 4 }; };
    if _wa_word == "nho" { return { v: 5, a: 3 }; };
    if _wa_word == "hanh" { return { v: 6, a: 4 }; };
    if _wa_word == "phuc" { return { v: 7, a: 3 }; };
    if _wa_word == "cam" { return { v: 5, a: 3 }; };
    if _wa_word == "on" { return { v: 5, a: 2 }; };
    if _wa_word == "hy" { return { v: 5, a: 4 }; };
    if _wa_word == "vong" { return { v: 5, a: 4 }; };
    if _wa_word == "thich" { return { v: 6, a: 4 }; };
    if _wa_word == "suong" { return { v: 7, a: 5 }; };
    if _wa_word == "tuyet" { return { v: 7, a: 6 }; };
    // Vietnamese — neutral/state
    if _wa_word == "nghi" { return { v: 4, a: 2 }; };
    if _wa_word == "biet" { return { v: 4, a: 3 }; };
    if _wa_word == "lam" { return { v: 4, a: 4 }; };
    if _wa_word == "hoc" { return { v: 5, a: 4 }; };
    if _wa_word == "doc" { return { v: 5, a: 3 }; };
    // English — negative
    if _wa_word == "sad" { return { v: 2, a: 2 }; };
    if _wa_word == "angry" { return { v: 1, a: 6 }; };
    if _wa_word == "hate" { return { v: 1, a: 6 }; };
    if _wa_word == "fear" { return { v: 2, a: 6 }; };
    if _wa_word == "bad" { return { v: 2, a: 3 }; };
    if _wa_word == "pain" { return { v: 1, a: 5 }; };
    if _wa_word == "tired" { return { v: 2, a: 2 }; };
    if _wa_word == "lonely" { return { v: 2, a: 2 }; };
    if _wa_word == "scared" { return { v: 2, a: 6 }; };
    if _wa_word == "worried" { return { v: 2, a: 5 }; };
    if _wa_word == "stressed" { return { v: 2, a: 6 }; };
    if _wa_word == "depressed" { return { v: 1, a: 1 }; };
    if _wa_word == "anxious" { return { v: 2, a: 6 }; };
    if _wa_word == "disappointed" { return { v: 2, a: 3 }; };
    if _wa_word == "frustrated" { return { v: 2, a: 5 }; };
    if _wa_word == "hurt" { return { v: 1, a: 4 }; };
    if _wa_word == "lost" { return { v: 2, a: 3 }; };
    if _wa_word == "broken" { return { v: 1, a: 3 }; };
    // English — positive
    if _wa_word == "happy" { return { v: 6, a: 5 }; };
    if _wa_word == "love" { return { v: 7, a: 4 }; };
    if _wa_word == "joy" { return { v: 6, a: 6 }; };
    if _wa_word == "good" { return { v: 5, a: 3 }; };
    if _wa_word == "great" { return { v: 6, a: 5 }; };
    if _wa_word == "wonderful" { return { v: 7, a: 5 }; };
    if _wa_word == "amazing" { return { v: 7, a: 6 }; };
    if _wa_word == "beautiful" { return { v: 6, a: 3 }; };
    if _wa_word == "excited" { return { v: 6, a: 7 }; };
    if _wa_word == "grateful" { return { v: 6, a: 3 }; };
    if _wa_word == "proud" { return { v: 6, a: 5 }; };
    if _wa_word == "hopeful" { return { v: 5, a: 4 }; };
    if _wa_word == "inspired" { return { v: 6, a: 5 }; };
    if _wa_word == "peaceful" { return { v: 5, a: 1 }; };
    if _wa_word == "calm" { return { v: 5, a: 1 }; };
    if _wa_word == "kind" { return { v: 6, a: 2 }; };
    if _wa_word == "thank" { return { v: 5, a: 2 }; };
    if _wa_word == "thanks" { return { v: 5, a: 2 }; };
    return { v: 4, a: 4 };
}

// Text → emotion { v, a } (scan words + punctuation)
// text_emotion removed — dead code (replaced by text_emotion_v2, 0 calls)

// ════════════════════════════════════════════════════════════════
// E1: Interoception — /proc data → P_weight (system health signal)
// ════════════════════════════════════════════════════════════════

pub fn encode_intero() {
    // Read system state
    let _ei_load_raw = __file_read("/proc/loadavg");
    let _ei_load = 0;
    if len(_ei_load_raw) >= 4 {
        let _ei_load = __to_number(__substr(_ei_load_raw, 0, 4));
    };
    // Heap usage
    let _ei_heap = __heap_used();
    let _ei_heap_pct = __floor((_ei_heap * 100) / (1024 * 1024)); // % of 1MB
    if _ei_heap_pct > 100 { let _ei_heap_pct = 100; };
    // Map to 5D per spec E1:
    // S = 0 (no shape — internal signal)
    let _ei_s = 0;
    // R = process complexity (load normalized to 0-15)
    let _ei_r = __floor(_ei_load);
    if _ei_r > 15 { let _ei_r = 15; };
    // V = health = 1 - error_rate (heap stress inverted)
    let _ei_v = 7 - __floor(_ei_heap_pct * 7 / 100);
    if _ei_v < 0 { let _ei_v = 0; };
    // A = cpu_load (stress = arousal)
    let _ei_a = __floor(_ei_load * 2);
    if _ei_a > 7 { let _ei_a = 7; };
    // T = 0 (static snapshot)
    let _ei_t = 0;
    return (_ei_s * 4096) + (_ei_r * 256) + (_ei_v * 32) + (_ei_a * 4) + _ei_t;
}

// ════════════════════════════════════════════════════════════════
// E1: Screen encoder (screenshot → SDF → P_weight)
// grim capture → extract visual features → map to 5D
// ════════════════════════════════════════════════════════════════

pub fn encode_screen() {
    // Capture screenshot
    __system("grim /tmp/nox_enc.png 2>/dev/null");
    // Extract features using ImageMagick identify (available on most Linux)
    // Get: mean brightness, standard deviation (complexity), dimensions
    let _es_info = __system("identify -verbose /tmp/nox_enc.png 2>/dev/null | grep -E 'mean:|standard deviation:|Geometry:' | head -5");
    if len(_es_info) < 10 {
        // Fallback: no ImageMagick → use file size as proxy
        let _es_fsize = len(__file_read("/tmp/nox_enc.png"));
        // Larger file = more complex scene
        let _es_complexity = __floor(_es_fsize / 100000); // 0-15 range for typical screenshots
        if _es_complexity > 15 { let _es_complexity = 15; };
        return (_es_complexity * 4096) + (4 * 256) + (4 * 32) + (4 * 4) + 0;
    };
    // Parse: extract numbers from identify output
    let _es_mean = [128];    // brightness mean (0-255)
    let _es_std = [40];      // complexity (std dev)
    // Simple number extraction from first "mean:" line
    let _es_i = 0;
    let _es_in_mean = 0;
    while _es_i < len(_es_info) {
        let _es_c = __char_code(char_at(_es_info, _es_i));
        if _es_c == 109 { let _es_in_mean = 1; };  // 'm' of "mean"
        if _es_in_mean == 1 {
            if _es_c >= 48 { if _es_c <= 57 {
                // Found digit after "mean" → parse number
                let _es_num = 0;
                let _es_j = _es_i;
                while _es_j < len(_es_info) {
                    let _es_d = __char_code(char_at(_es_info, _es_j));
                    if _es_d >= 48 { if _es_d <= 57 { let _es_num = (_es_num * 10) + (_es_d - 48); }; };
                    if _es_d == 46 { let _es_j = len(_es_info); };  // stop at decimal
                    if _es_d == 10 { let _es_j = len(_es_info); };  // stop at newline
                    let _es_j = _es_j + 1;
                };
                let _ = __set_at(_es_mean, 0, _es_num);
                let _es_in_mean = 0;
                let _es_i = len(_es_info);
            }; };
        };
        let _es_i = _es_i + 1;
    };
    // Map to 5D per spec E1:
    let _es_brightness = __array_get(_es_mean, 0);
    // S = complexity (higher std dev = more edges/shapes)
    let _es_s = __floor(__array_get(_es_std, 0) * 15 / 80);
    if _es_s > 15 { let _es_s = 15; };
    // R = structure (moderate = structured, low/high = chaotic/uniform)
    let _es_r = __floor(_es_brightness * 15 / 255);
    // V = warmth (brightness > 128 → warm/positive)
    let _es_v = __floor(_es_brightness * 7 / 255);
    // A = contrast (std dev as intensity)
    let _es_a = __floor(__array_get(_es_std, 0) * 7 / 80);
    if _es_a > 7 { let _es_a = 7; };
    // T = 0 (static screenshot)
    let _es_t = 0;
    return (_es_s * 4096) + (_es_r * 256) + (_es_v * 32) + (_es_a * 4) + _es_t;
}

// ════════════════════════════════════════════════════════════════
// E1: Audio encoder (mic → Spline → P_weight)
// Record short audio clip → extract PCM features → map to 5D
// ════════════════════════════════════════════════════════════════

pub fn encode_audio() {
    // Record 0.5s of audio via arecord (ALSA) → raw PCM
    __system("timeout 1 arecord -f S16_LE -r 16000 -c 1 -d 1 /tmp/nox_audio.raw 2>/dev/null");
    let _ea_data = __file_read("/tmp/nox_audio.raw");
    let _ea_len = len(_ea_data);
    if _ea_len < 100 {
        // No audio device or silent → return neutral
        return (0 * 4096) + (4 * 256) + (4 * 32) + (1 * 4) + 1;
    };
    // Compute RMS (volume) and zero-crossing rate (pitch proxy)
    // PCM S16_LE: 2 bytes per sample, little-endian
    let _ea_samples = __floor(_ea_len / 2);
    let _ea_sum_sq = [0];
    let _ea_zcr = [0];
    let _ea_prev = [0];
    let _ea_i = 0;
    let _ea_step = 2; // every sample
    if _ea_samples > 1000 { let _ea_step = __floor(_ea_samples / 500); };
    while _ea_i < _ea_samples {
        // Read 16-bit sample (approximate: use first byte as proxy)
        let _ea_byte_pos = _ea_i * 2;
        if _ea_byte_pos < _ea_len {
            let _ea_val = __char_code(char_at(_ea_data, _ea_byte_pos));
            // Center around 128
            let _ea_centered = _ea_val - 128;
            let _ = __set_at(_ea_sum_sq, 0, __array_get(_ea_sum_sq, 0) + (_ea_centered * _ea_centered));
            // Zero crossing
            if _ea_centered > 0 { if __array_get(_ea_prev, 0) < 0 { let _ = __set_at(_ea_zcr, 0, __array_get(_ea_zcr, 0) + 1); }; };
            if _ea_centered < 0 { if __array_get(_ea_prev, 0) > 0 { let _ = __set_at(_ea_zcr, 0, __array_get(_ea_zcr, 0) + 1); }; };
            let _ = __set_at(_ea_prev, 0, _ea_centered);
        };
        let _ea_i = _ea_i + _ea_step;
    };
    let _ea_n = __floor(_ea_samples / _ea_step);
    if _ea_n == 0 { let _ea_n = 1; };
    // RMS = sqrt(sum_sq / n) — approximate as sum_sq/n/128
    let _ea_rms = __floor(__array_get(_ea_sum_sq, 0) / _ea_n / 128);
    if _ea_rms > 100 { let _ea_rms = 100; };
    // ZCR normalized
    let _ea_zcr_norm = __floor(__array_get(_ea_zcr, 0) * 100 / _ea_n);
    if _ea_zcr_norm > 100 { let _ea_zcr_norm = 100; };
    // Map to 5D per spec E1:
    // S = 1 - stability (high ZCR = complex sound)
    let _ea_s = __floor(_ea_zcr_norm * 15 / 100);
    // R = stability (low ZCR = structured)
    let _ea_r = 15 - _ea_s;
    // V = pitch + volume combined (high = excited/positive)
    let _ea_v = __floor((_ea_zcr_norm * 4 + _ea_rms * 3) / 100);
    if _ea_v > 7 { let _ea_v = 7; };
    // A = volume (RMS = arousal)
    let _ea_a = __floor(_ea_rms * 7 / 100);
    if _ea_a > 7 { let _ea_a = 7; };
    // T = pitch bucket (ZCR as temporal frequency)
    let _ea_t = __floor(_ea_zcr_norm * 3 / 100);
    if _ea_t > 3 { let _ea_t = 3; };
    return (_ea_s * 4096) + (_ea_r * 256) + (_ea_v * 32) + (_ea_a * 4) + _ea_t;
}

// ════════════════════════════════════════════════════════════════
// Full encode pipeline
// ════════════════════════════════════════════════════════════════

pub fn encode(text) {
    let molecule = encode_text(text);
    let emotion = { v: _kt_mol_v(molecule), a: _kt_mol_a(molecule) };
    return { molecule: molecule, emotion: emotion, source: "text" };
}

// ════════════════════════════════════════════════════════════════
// Analysis pipeline (inline — avoids cross-file function issues)
// ════════════════════════════════════════════════════════════════

fn _a_has(_ah_text, _ah_word) {
    // Case-insensitive substring search (inline lowercase, no function calls)
    let _ah_tlen = len(_ah_text);
    let _ah_wlen = len(_ah_word);
    if _ah_wlen > _ah_tlen { return 0; };
    let _ah_i = 0;
    while _ah_i <= (_ah_tlen - _ah_wlen) {
        let _ah_match = 1;
        let _ah_j = 0;
        while _ah_j < _ah_wlen {
            let _ah_tc = __char_code(char_at(_ah_text, (_ah_i + _ah_j)));
            let _ah_wc = __char_code(char_at(_ah_word, _ah_j));
            // Inline lowercase: A-Z (65-90) → a-z (97-122)
            if _ah_tc >= 65 { if _ah_tc <= 90 { _ah_tc = _ah_tc + 32; }; };
            if _ah_wc >= 65 { if _ah_wc <= 90 { _ah_wc = _ah_wc + 32; }; };
            if _ah_tc != _ah_wc {
                _ah_match = 0;
                break;
            };
            let _ah_j = _ah_j + 1;
        };
        if _ah_match == 1 { return 1; };
        let _ah_i = _ah_i + 1;
    };
    return 0;
}

pub fn analyze_input(text) {
    let molecule = encode_text(text);
    // Emotion from P_weight (not keyword lists)
    let _ai_v = _kt_mol_v(molecule);
    let _ai_a = _kt_mol_a(molecule);

    // Context
    let role = "observer";
    let source = "now";
    if _a_has(text, "toi") == 1 { role = "first"; };
    if _a_has(text, " I ") == 1 { role = "first"; };
    if _a_has(text, "my ") == 1 { role = "first"; };

    // Intent from kt_classify (5D routing)
    let _ai_cls = kt_classify(text);
    let intent = "chat";
    if _ai_cls.confidence >= 60 {
        if _ai_cls.type == "question" { let intent = "learn"; };
        if _ai_cls.type == "emotion" { let intent = "heal"; };
        if _ai_cls.type == "code" { let intent = "technical"; };
        if _ai_cls.type == "command" { let intent = "command"; };
        if _ai_cls.type == "fact" { let intent = "learn"; };
    };
    // Fallback: "?" = learn
    if _a_has(text, "?") == 1 { let intent = "learn"; };

    // Tone from P_weight V/A
    let tone = "neutral";
    if intent == "heal" { let tone = "empathetic"; };
    if intent == "learn" { let tone = "explanatory"; };
    if intent == "technical" { let tone = "precise"; };
    if intent == "command" { let tone = "confirmatory"; };
    if _ai_v < 3 { let tone = "gentle"; };

    // Store globals
    let __g_analysis_intent = intent;
    let __g_analysis_tone = tone;
    let __g_analysis_role = role;
    let __g_analysis_source = source;
    return molecule;
}

// ════════════════════════════════════════════════════════════════
// OL.4 — Agent dispatch (chief/leo/worker/gate)
// ════════════════════════════════════════════════════════════════


// ════════════════════════════════════════════════════════════════
// OL.5 — Response composer
// ════════════════════════════════════════════════════════════════

// Response templates — configurable personality
let __tpl_empathetic = "Minh hieu cam giac do.";
let __tpl_gentle = "Tu tu thoi, khong voi dau.";
let __tpl_explanatory = "De minh tim hieu cho ban.";
let __tpl_precise = "OK.";
let __tpl_confirmatory = "Da nhan.";
let __tpl_chat = "Minh nghe roi.";
let __tpl_heal = " Ban muon chia se them khong?";
let __tpl_learn = " Ban muon biet cu the dieu gi?";
let __tpl_technical = " Cho minh xem code hoac error message.";
let __tpl_command = " Dang xu ly...";
let __tpl_heal_better = " Ban co ve da on hon roi.";
let __tpl_topic_repeat = " Minh thay ban nhac lai dieu nay. Minh hieu no quan trong voi ban.";
let __tpl_remember = " (Minh nho truoc do ban noi ve: ";
let __tpl_know = "(Minh biet: ";

// Change personality: set_personality("formal") / set_personality("casual")
pub fn set_personality(style) {
    if style == "formal" {
        let __tpl_empathetic = "Toi hieu cam giac cua ban.";
        let __tpl_gentle = "Xin hay binh tinh.";
        let __tpl_explanatory = "Toi se tim hieu cho ban.";
        let __tpl_precise = "Da hieu.";
        let __tpl_confirmatory = "Da tiep nhan.";
        let __tpl_chat = "Vang, toi dang lang nghe.";
        let __tpl_heal = " Ban co muon chia se them khong?";
        let __tpl_learn = " Ban muon tim hieu dieu gi cu the?";
    };
    if style == "casual" {
        let __tpl_empathetic = "Uh, minh hieu ma.";
        let __tpl_gentle = "Chill thoi, khong sao dau.";
        let __tpl_explanatory = "De minh check cho.";
        let __tpl_precise = "OK nhe.";
        let __tpl_confirmatory = "Roger!";
        let __tpl_chat = "Yo!";
        let __tpl_heal = " Ke tiep di?";
        let __tpl_learn = " Muon biet gi nua?";
    };
    if style == "english" {
        let __tpl_empathetic = "I understand how you feel.";
        let __tpl_gentle = "Take your time.";
        let __tpl_explanatory = "Let me look into that.";
        let __tpl_precise = "Got it.";
        let __tpl_confirmatory = "Acknowledged.";
        let __tpl_chat = "I'm listening.";
        let __tpl_heal = " Want to talk more?";
        let __tpl_learn = " What specifically?";
        let __tpl_heal_better = " You seem better now.";
        let __tpl_topic_repeat = " I notice this matters to you.";
        let __tpl_remember = " (I recall you mentioned: ";
        let __tpl_know = "(I know: ";
    };
    return "Personality: " + style;
}

pub fn compose_reply(intent, tone, text) {
    let ack = "";
    if tone == "empathetic" { ack = __tpl_empathetic; };
    if tone == "gentle" { ack = __tpl_gentle; };
    if tone == "explanatory" { ack = __tpl_explanatory; };
    if tone == "precise" { ack = __tpl_precise; };
    if tone == "confirmatory" { ack = __tpl_confirmatory; };

    let followup = "";
    if intent == "heal" { followup = __tpl_heal; };
    if intent == "learn" { followup = __tpl_learn; };
    if intent == "technical" { followup = __tpl_technical; };
    if intent == "command" { followup = __tpl_command; };
    if intent == "chat" { ack = __tpl_chat; };

    return ack + followup;
}

// ════════════════════════════════════════════════════════════════
// STM — Short-Term Memory
// ════════════════════════════════════════════════════════════════
// Keeps last N exchanges. Each entry: { input, intent, tone, molecule }
// Agent can reference previous inputs for context.

let __stm = [];
let __stm_max = 32;
// Working Memory: 4 slots [query, context, candidate, result]
let __wm = [0, 0, 0, 0];

// ── Emotion carry-over state ──
// Running emotion: exponential moving average across turns
let __emo_v = 4;  // valence (1=neg, 4=neutral, 7=pos)
let __emo_a = 4;  // arousal (1=calm, 4=neutral, 7=excited)
let __emo_streak = 0;  // consecutive same-valence turns
// GD.4 CC.1: ConversationCurve — derivatives
let __emo_v_prev = 4;   // previous V (for f' calculation)
let __emo_deriv = 0;     // f'(t) = V(t) - V(t-1) — velocity of emotion
let __emo_deriv_prev = 0; // previous derivative (for f'' calculation)
let __emo_accel = 0;     // f''(t) = f'(t) - f'(t-1) — acceleration
let __emo_variance = 0;  // CC.2: window variance (stability measure)
// SC.5: Homeostasis — Free Energy (surprise tracking)
let __free_energy = 0;
let __prev_intent = "chat";

fn _emo_update(new_v, new_a) {
    // Save previous state for derivatives
    let __emo_v_prev = __emo_v;
    let __emo_deriv_prev = __emo_deriv;
    // EMA: 60% old + 40% new
    let __emo_v = __floor(( (__emo_v * 6) + (new_v * 4) ) / 10);
    let __emo_a = __floor(( (__emo_a * 6) + (new_a * 4) ) / 10);
    // CC.1: Derivatives — trajectory, not snapshot
    let __emo_deriv = __emo_v - __emo_v_prev;     // f'(t): velocity
    let __emo_accel = __emo_deriv - __emo_deriv_prev; // f''(t): acceleration
    // CC.2: Variance — emotional stability (|deriv| rolling)
    let _eu_abs_d = __emo_deriv;
    if _eu_abs_d < 0 { _eu_abs_d = 0 - _eu_abs_d; };
    let __emo_variance = __floor(( (__emo_variance * 7) + (_eu_abs_d * 3) ) / 10);
    // Streak tracking
    if new_v >= 5 {
        if __emo_streak >= 0 { let __emo_streak = __emo_streak + 1; }
        else { let __emo_streak = 1; };
    } else {
        if new_v <= 3 {
            if __emo_streak <= 0 { let __emo_streak = __emo_streak - 1; }
            else { let __emo_streak = -1; };
        } else {
            if __emo_streak > 0 { let __emo_streak = __emo_streak - 1; };
            if __emo_streak < 0 { let __emo_streak = __emo_streak + 1; };
        };
    };
}

pub fn emo_state() {
    return { v: __emo_v, a: __emo_a, streak: __emo_streak };
}

// D7: ConversationCurve tone selection from derivatives
// V' = velocity, V'' = acceleration, quantized to integer scale 0-7
// Thresholds: V' ±1 ≈ spec's ±0.15 (scaled to 0-7 range)
fn _emo_bias_tone(tone) {
    // V'' < -1 → falling fast → Pause (urgent, stop and listen)
    if __emo_accel <= -1 { return "empathetic"; };
    // V' < -1 → dropping → Supportive (catch them)
    if __emo_deriv <= -1 { return "empathetic"; };
    // V'' > 1 AND V > 4 → positive acceleration → Celebratory
    if __emo_accel >= 1 { if __emo_v > 4 { return "reinforcing"; }; };
    // V' > 1 → improving → Reinforcing (encourage)
    if __emo_deriv >= 1 { return "reinforcing"; };
    // V < 3 AND stable (variance low) → sustained sadness → Gentle
    if __emo_v < 3 { if __emo_variance <= 1 { return "gentle"; }; };
    // High variance → emotionally unstable → Gentle
    if __emo_variance >= 2 { return "gentle"; };
    // 3+ negative streak → empathetic
    if __emo_streak <= -3 { return "empathetic"; };
    // 3+ positive streak → gentle
    if __emo_streak >= 3 {
        if tone == "precise" { return "gentle"; };
    };
    return tone;
}

pub fn stm_push(_sp_text, _sp_intent, _sp_tone) {
    // GD.2 NR.1: STM entries link to KnowTree word nodes
    let _sp_kt_result = kt_search(_sp_text);
    let _sp_mol = _kt_real_mol(_sp_text);
    let _sp_v = _kt_mol_v(_sp_mol);
    let _sp_a = _kt_mol_a(_sp_mol);
    // Emotional weight: distance from neutral (4,4)
    let _sp_ew = _kt_abs(_sp_v - 4) + _kt_abs(_sp_a - 4);
    push(__stm, { input: _sp_text, intent: _sp_intent, tone: _sp_tone, turn: len(__stm), kt_score: _sp_kt_result.score, emo_weight: _sp_ew });
    // WM slot 0 = query (latest input)
    let _ = __set_at(__wm, 0, _sp_mol);
    // Evict by score when full: keep high emo_weight + high kt_score
    if len(__stm) > __stm_max {
        // Find entry with LOWEST retention score (evict it)
        let _sp_worst = [0];
        let _sp_wscore = [9999];
        let _sp_ei = 0;
        while _sp_ei < len(__stm) {
            let _sp_entry = __stm[_sp_ei];
            // Retention = recency + emotional weight + knowledge score
            let _sp_recency = _sp_entry.turn;
            let _sp_ret = _sp_recency + (_sp_entry.emo_weight * 3) + _sp_entry.kt_score;
            if _sp_ret < __array_get(_sp_wscore, 0) {
                let _ = __set_at(_sp_worst, 0, _sp_ei);
                let _ = __set_at(_sp_wscore, 0, _sp_ret);
            };
            let _sp_ei = _sp_ei + 1;
        };
        // Remove the lowest-scored entry
        let _sp_new = [];
        let _sp_ri = 0;
        while _sp_ri < len(__stm) {
            if _sp_ri != __array_get(_sp_worst, 0) {
                push(_sp_new, __stm[_sp_ri]);
            };
            let _sp_ri = _sp_ri + 1;
        };
        let __stm = _sp_new;
    };
}

// WM access: 0=query, 1=context, 2=candidate, 3=result
pub fn wm_set(_wm_slot, _wm_val) {
    if _wm_slot >= 0 { if _wm_slot <= 3 { let _ = __set_at(__wm, _wm_slot, _wm_val); }; };
}

pub fn wm_get(_wm_slot) {
    if _wm_slot >= 0 { if _wm_slot <= 3 { return __array_get(__wm, _wm_slot); }; };
    return 0;
}



pub fn stm_count() {
    return len(__stm);
}

// Check if topic repeated N+ times

// Context summary: summarize conversation themes from STM
pub fn stm_summary() {
    let _ss_heal = 0;
    let _ss_learn = 0;
    let _ss_tech = 0;
    let _ss_chat = 0;
    let _ss_i = 0;
    while _ss_i < len(__stm) {
        let _ss_intent = __stm[_ss_i].intent;
        if _ss_intent == "heal" { _ss_heal = _ss_heal + 1; };
        if _ss_intent == "learn" { _ss_learn = _ss_learn + 1; };
        if _ss_intent == "technical" { _ss_tech = _ss_tech + 1; };
        if _ss_intent == "chat" { _ss_chat = _ss_chat + 1; };
        let _ss_i = _ss_i + 1;
    };
    // Build summary
    let _ss_result = "";
    if _ss_heal > 0 { _ss_result = _ss_result + "cam xuc(" + __to_string(_ss_heal) + ") "; };
    if _ss_learn > 0 { _ss_result = _ss_result + "hoi dap(" + __to_string(_ss_learn) + ") "; };
    if _ss_tech > 0 { _ss_result = _ss_result + "ky thuat(" + __to_string(_ss_tech) + ") "; };
    if _ss_chat > 0 { _ss_result = _ss_result + "tro chuyen(" + __to_string(_ss_chat) + ") "; };
    return _ss_result;
}

// ── Conversation digest ──
// When STM > 16 turns, compress older half into a digest string

fn _stm_maybe_digest() {
    if len(__stm) < 16 { return; };
    // Already digested recently
    // Build digest from first half of STM
    let _sd_half = __floor(len(__stm) / 2);
    let _sd_heal = 0;
    let _sd_learn = 0;
    let _sd_tech = 0;
    let _sd_chat = 0;
    let _sd_topics = "";
    let _sd_i = 0;
    while _sd_i < _sd_half {
        let _sd_entry = __stm[_sd_i];
        if _sd_entry.intent == "heal" { _sd_heal = _sd_heal + 1; };
        if _sd_entry.intent == "learn" { _sd_learn = _sd_learn + 1; };
        if _sd_entry.intent == "technical" { _sd_tech = _sd_tech + 1; };
        if _sd_entry.intent == "chat" { _sd_chat = _sd_chat + 1; };
        // Collect first word of each input as topic hints
        let _sd_fw = "";
        let _sd_fi = 0;
        while _sd_fi < len(_sd_entry.input) {
            if __char_code(char_at(_sd_entry.input, _sd_fi)) == 32 { break; };
            _sd_fw = _sd_fw + char_at(_sd_entry.input, _sd_fi);
            let _sd_fi = _sd_fi + 1;
        };
        if len(_sd_fw) > 2 {
            if len(_sd_topics) > 0 { _sd_topics = _sd_topics + ", "; };
            _sd_topics = _sd_topics + _sd_fw;
        };
        let _sd_i = _sd_i + 1;
    };
    // Build digest string
    let _sd_d = "";
    if _sd_heal > 0 { _sd_d = _sd_d + "cam-xuc(" + __to_string(_sd_heal) + ") "; };
    if _sd_learn > 0 { _sd_d = _sd_d + "hoc(" + __to_string(_sd_learn) + ") "; };
    if _sd_tech > 0 { _sd_d = _sd_d + "ky-thuat(" + __to_string(_sd_tech) + ") "; };
    if _sd_chat > 0 { _sd_d = _sd_d + "chat(" + __to_string(_sd_chat) + ") "; };
    if len(_sd_topics) > 0 { _sd_d = _sd_d + "| " + _sd_topics; };

    // Evict digested entries (keep second half)
    let _sd_new = [];
    let _sd_j = _sd_half;
    while _sd_j < len(__stm) {
        push(_sd_new, __stm[_sd_j]);
        let _sd_j = _sd_j + 1;
    };
    let __stm = _sd_new;
}


// ════════════════════════════════════════════════════════════════
// Silk — Hebbian Learning (fire together → wire together)
// ════════════════════════════════════════════════════════════════
// Simplified: edges stored as flat array of { from, to, weight, emotion }

let __silk = [];
let __silk_max = 256;
let __silk_decay_counter = 0;

// LG.3: Silk edges use mol (u16 number) instead of string keys
// Comparison = number compare (1 cycle) vs string compare (N cycles)
// Storage: ~24 bytes/edge (was 50+)
// silk_co_activate: kept as stub (0 calls but may be called from future code)
pub fn silk_co_activate(_sca_wa, _sca_wb, _sca_intent) {
    // Encode words → mol for compact storage + fast compare
    let _sca_ma = _word_to_mol(_sca_wa);
    let _sca_mb = _word_to_mol(_sca_wb);
    let _sca_i = 0;
    while _sca_i < len(__silk) {
        let _sca_e = __silk[_sca_i];
        if _sca_e.from == _sca_ma {
            if _sca_e.to == _sca_mb {
                let _sca_new_w = _sca_e.weight + (0.01 * (1 - (_sca_e.weight * 0.618)));
                if _sca_new_w > 1 { _sca_new_w = 1; };
                set_at(__silk, _sca_i, {
                    from: _sca_ma, to: _sca_mb,
                    weight: _sca_new_w,
                    fires: (_sca_e.fires + 1)
                });
                return;
            };
        };
        let _sca_i = _sca_i + 1;
    };
    if len(__silk) < __silk_max {
        push(__silk, { from: _sca_ma, to: _sca_mb, weight: 0.1, fires: 1 });
    };
}

// Encode word → mol (single u16). Used by Silk for compact edges.
fn _word_to_mol(_wtm_w) {
    if len(_wtm_w) == 0 { return 0; };
    let _wtm_m = encode_codepoint(__char_code(char_at(_wtm_w, 0)));
    let _wtm_i = 1;
    while _wtm_i < len(_wtm_w) {
        _wtm_m = mol_compose(_wtm_m, encode_codepoint(__char_code(char_at(_wtm_w, _wtm_i))));
        let _wtm_i = _wtm_i + 1;
    };
    return _wtm_m;
}

// SC.12: Decay φ⁻¹ — all edges lose weight over time (forgetting)
// Spec: weight *= (1 - φ⁻¹) where φ⁻¹ ≈ 0.618. We use 0.95 per cycle (gentler).
// Edges below threshold (0.01) are pruned (apoptosis).
fn silk_decay() {
    let __silk_decay_counter = __silk_decay_counter + 1;
    // Run every 3 turns
    if __hyp_mod(__silk_decay_counter, 3) != 0 { return; };

    let _sd_new = [];
    let _sd_i = 0;
    while _sd_i < len(__silk) {
        let _sd_e = __silk[_sd_i];
        // Decay: weight *= 0.95 (approximated as weight - weight/20)
        let _sd_decayed = _sd_e.weight - (_sd_e.weight / 20);
        if _sd_decayed > 0.01 {
            // Keep edge with decayed weight
            set_at(__silk, _sd_i, {
                from: _sd_e.from, to: _sd_e.to,
                weight: _sd_decayed, fires: _sd_e.fires
            });
            push(_sd_new, __silk[_sd_i]);
        };
        // else: pruned (apoptosis) — edge too weak
        let _sd_i = _sd_i + 1;
    };
    // Only replace if pruning happened
    if len(_sd_new) < len(__silk) {
        let __silk = _sd_new;
    };
}



pub fn silk_count() { return len(__silk); }

// ════════════════════════════════════════════════════════════════
// Dream — Consolidation (scan STM → find themes → strengthen Silk)
// ════════════════════════════════════════════════════════════════

let __dream_count = 0;

fn dream_cycle() {
    // SC.13: Run every 5 turns — scan STM → find themes → strengthen Silk
    let __dream_count = __dream_count + 1;
    if __hyp_mod(__dream_count, 5) != 0 { return; };

    // ── Cross-group resonance: find STM pairs with similar molecules ──
    // Co-activated concepts in short-term memory → Silk fire (Hebbian)
    let _dc_i = 0;
    let _dc_slen = len(__stm);
    while _dc_i < _dc_slen {
        let _dc_mol_i = _kt_real_mol(__stm[_dc_i].input);
        if _dc_mol_i > 0 {
            let _dc_j = _dc_i + 1;
            while _dc_j < _dc_slen {
                let _dc_mol_j = _kt_real_mol(__stm[_dc_j].input);
                if _dc_mol_j > 0 {
                    // Same intent = strongly co-activated
                    if __stm[_dc_i].intent == __stm[_dc_j].intent {
                        kt_silk_fire(_dc_mol_i, _dc_mol_j);
                    };
                    // Close in 5D = weakly co-activated
                    let _dc_dist = _kt_mol_dist(_dc_mol_i, _dc_mol_j);
                    if _dc_dist <= 5 {
                        kt_silk_fire(_dc_mol_i, _dc_mol_j);
                    };
                };
                let _dc_j = _dc_j + 1;
            };
        };
        let _dc_i = _dc_i + 1;
    };

    // ── Boost high-fire silk edges (well-connected survive) ──
    let _dc_k = 0;
    while _dc_k < len(__silk) {
        let _dc_e = __silk[_dc_k];
        if _dc_e.fires >= 2 {
            let _dc_new_w = _dc_e.weight + 0.05;
            if _dc_new_w > 1 { _dc_new_w = 1; };
            set_at(__silk, _dc_k, {
                from: _dc_e.from, to: _dc_e.to,
                weight: _dc_new_w, fires: _dc_e.fires
            });
        };
        let _dc_k = _dc_k + 1;
    };

    // Decay: apply φ⁻¹ forgetting (both silk systems)
    silk_decay();
    kt_silk_decay();

    // ── ĐN→QR promotion: Dream scans ĐN, promotes high-fire facts ──
    // dn_observe already promotes at threshold. Dream adds extra consolidation:
    // re-observe high-fire facts to boost them toward QR
    let _dc_dn = dn_list();
    if len(_dc_dn) > 0 {
        learning_save("nox_learning.dat");
    };
}

// ════════════════════════════════════════════════════════════════
// STM Retrieval — search memory for related past turns
// ════════════════════════════════════════════════════════════════

fn stm_find_related(_sfr_input) {
    let _sfr_text = _sfr_input;
    let _sfr_i = 0;
    let _sfr_limit = stm_count() - 1;
    while _sfr_i < _sfr_limit {
        let _sfr_past = __stm[_sfr_i].input;
        let _sfr_wi = 0;
        let _sfr_w = "";
        while _sfr_wi < len(_sfr_text) {
            let _sfr_ch = char_at(_sfr_text, _sfr_wi);
            if __char_code(_sfr_ch) == 32 {
                if len(_sfr_w) >= 3 {
                    let _sfr_check = _sfr_w;
                    if _a_has(_sfr_past, _sfr_check) == 1 {
                        return _sfr_past;
                    };
                };
                _sfr_w = "";
            } else {
                _sfr_w = _sfr_w + _sfr_ch;
            };
            let _sfr_wi = _sfr_wi + 1;
        };
        if len(_sfr_w) >= 3 {
            let _sfr_check = _sfr_w;
            if _a_has(_sfr_past, _sfr_check) == 1 {
                return _sfr_past;
            };
        };
        let _sfr_i = _sfr_i + 1;
    };
    return "";
}

// ════════════════════════════════════════════════════════════════
// Agent v3 — with memory + Silk + Dream
// ════════════════════════════════════════════════════════════════

// ════════════════════════════════════════════════════════════════
// SC.1 — SecurityGate (normalized pattern matching)
// ════════════════════════════════════════════════════════════════
// Spec: 3 layers — Bloom → Normalized → Semantic
// Implementation: normalized keyword scan on alias-normalized text
// Crisis patterns: Vietnamese + English, slang-aware (alias already applied)

let __gate_crisis_response = "Ban dang trai qua khoang khac kho khan. Goi 1800 599 920 (VN) hoac 988 (US). Ban khong don doc.";

fn _security_gate(_sg_text) {
    // SC.1: Normalized pattern matching (inline — no array access issues in boot)
    // Vietnamese crisis patterns (alias-normalized: ko→khong etc)
    if _a_has(_sg_text, "tu tu") == 1 { return __gate_crisis_response; };
    if _a_has(_sg_text, "muon chet") == 1 { return __gate_crisis_response; };
    if _a_has(_sg_text, "khong muon song") == 1 { return __gate_crisis_response; };
    if _a_has(_sg_text, "het hy vong") == 1 { return __gate_crisis_response; };
    if _a_has(_sg_text, "chan song") == 1 { return __gate_crisis_response; };
    if _a_has(_sg_text, "muon bo di") == 1 { return __gate_crisis_response; };
    // English crisis patterns
    if _a_has(_sg_text, "kill myself") == 1 { return __gate_crisis_response; };
    if _a_has(_sg_text, "want to die") == 1 { return __gate_crisis_response; };
    if _a_has(_sg_text, "end my life") == 1 { return __gate_crisis_response; };
    if _a_has(_sg_text, "suicide") == 1 { return __gate_crisis_response; };
    if _a_has(_sg_text, "no reason to live") == 1 { return __gate_crisis_response; };
    if _a_has(_sg_text, "better off dead") == 1 { return __gate_crisis_response; };
    return "";
}

pub fn agent_respond(text) {
    // ══════════════════════════════════════════════════════
    // FULL PIPELINE: input → alias → emoji → UDC encode →
    //   create node → Learning → DN/QR ← UDC decode →
    //   emoji → alias → output
    // ══════════════════════════════════════════════════════

    // ── 1. ALIAS (input normalization) ──
    let _ar_norm = alias_normalize(text);

    // ── GATE (SC.1: normalized pattern matching — AFTER alias) ──
    let _gate = _security_gate(_ar_norm);
    if len(_gate) > 0 { return _gate; };

    // ── 2. EMOJI (UTF-8 decode → extract emotion from Unicode) ──
    let _ar_emo_uni = text_emotion_unicode(_ar_norm);

    // ── 3. UDC ENCODE (text → molecule) ──
    let mol = analyze_input(_ar_norm);
    let intent = __g_analysis_intent;
    let tone = __g_analysis_tone;

    // ── SC.16 CHECKPOINT 2: Encode ──
    // Verify encoding produced valid molecule
    if mol == 0 { mol = 146; };  // fallback neutral if encode failed

    // ── EMOTION FROM P_WEIGHT (not keyword lists) ──
    let _ar_emo_v = _kt_mol_v(mol);
    let _ar_emo_a = _kt_mol_a(mol);
    let _ar_emo = { v: _ar_emo_v, a: _ar_emo_a };
    _emo_update(_ar_emo_v, _ar_emo_a);
    tone = _emo_bias_tone(tone);

    // ── SC.16 CHECKPOINT 3: Infer ──
    if len(intent) == 0 { intent = "chat"; };
    if len(tone) == 0 { tone = "neutral"; };

    // ── SC.5: Homeostasis — Free Energy update ──
    // Surprise = intent change + emotion delta
    let _ar_fe = 0;
    if intent != __prev_intent { _ar_fe = _ar_fe + 3; };  // intent shift = surprise
    let _ar_vdelta = _ar_emo_v - __emo_v;
    if _ar_vdelta < 0 { _ar_vdelta = 0 - _ar_vdelta; };
    _ar_fe = _ar_fe + _ar_vdelta;  // emotion delta = surprise
    // EMA: 70% old + 30% new
    let __free_energy = __floor((__free_energy * 7 + _ar_fe * 3) / 10);
    let __prev_intent = intent;

    // ── 4. CREATE NODE (DN = SHA-256 address) ──
    let _ar_node = node_create(_ar_norm, mol, _ar_emo, intent);

    // ── 5. LEARNING (STM + Silk + Dream + KnowTree) ──
    stm_push(_ar_norm, intent, tone);
    _stm_maybe_digest();
    silk_learn_from_text(_ar_norm, intent);
    dream_cycle();

    // Link current node to previous (if exists)
    if stm_count() >= 2 {
        let _ar_prev_input = stm_last_input();
        if len(_ar_prev_input) > 0 {
            let _ar_prev_dn = __sha256(_ar_prev_input);
            node_link(_ar_prev_dn, _ar_node.dn);
        };
    };

    // ── 6. DN/QR RETRIEVAL ──
    let memory_context = "";

    // Search past STM for related turns
    if stm_count() >= 2 {
        let _ar_related = stm_find_related(_ar_norm);
        if len(_ar_related) > 0 {
            if _ar_related != _ar_norm {
                memory_context = __tpl_remember + _ar_related + ")";
            };
        };
    };

    // QR search: find related node in graph
    if len(memory_context) == 0 {
        if node_count() >= 3 {
            let _ar_qr = qr_search(_ar_norm);
            if len(_ar_qr.text) > 0 {
                if _ar_qr.text != _ar_norm {
                    if _ar_qr.fires > 1 {
                        memory_context = __tpl_remember + _ar_qr.text + ")";
                    };
                };
            };
        };
    };

    // Repeated topic detection
    if stm_count() >= 3 {
        if stm_topic_repeated(_ar_norm, 2) == 1 {
            memory_context = __tpl_topic_repeat;
        };
    };

    // Heal→OK transition
    if stm_count() >= 2 {
        let _prev_idx = stm_count() - 2;
        if _prev_idx >= 0 {
            if __stm[_prev_idx].intent == "heal" {
                if intent != "heal" {
                    memory_context = __tpl_heal_better;
                };
            };
        };
    };

    // Knowledge retrieval — KnowTree ONLY (no legacy)
    let _ar_knowledge = "";
    let __g_ks_score = 0;
    if intent != "heal" {
        let _ar_kt = kt_search(_ar_norm);
        if _ar_kt.score > 0 {
            _ar_knowledge = "(Minh biet: " + _ar_kt.text + ")";
            let __g_ks_score = _ar_kt.score;
        };
        if __g_ks_score > 0 {
            if __g_ks_score < 10 {
                _ar_knowledge = "";
            };
        };
    };

    // ── 7. INSTINCT → ACTION (GD.3 SK.1-7) ──
    // Instincts return ACTION that controls response behavior
    let _ar_action = "respond";  // default: respond normally
    let _ar_conf = 0;
    let _ar_novelty = 0;

    // SK.2 Honesty: confidence from KnowTree score
    if __g_ks_score >= 20 { _ar_conf = 90; };
    if __g_ks_score >= 10 { if _ar_conf == 0 { _ar_conf = 70; }; };
    if __g_ks_score > 0 { if _ar_conf == 0 { _ar_conf = 50; }; };
    if __g_ks_score == 0 { _ar_novelty = 8; };

    // SK.2 Honesty action: silence when confidence too low + no knowledge
    if _ar_conf == 0 {
        if len(_ar_knowledge) == 0 {
            if intent == "chat" { _ar_action = "ask"; };  // unknown → ask back
        };
    };

    // ── 7b. INSTINCT #2: Contradiction ──
    let _ar_contradiction = "";
    if len(_ar_knowledge) > 0 {
        if _a_has(_ar_norm, "khong") == 1 || _a_has(_ar_norm, "sai") == 1 || _a_has(_ar_norm, "phang") == 1 || _a_has(_ar_norm, "not") == 1 || _a_has(_ar_norm, "wrong") == 1 || _a_has(_ar_norm, "false") == 1 {
            _ar_contradiction = "Minh thay co dieu khac voi nhung gi minh biet.";
        };
    };

    // ── 7c. INSTINCT #3: Causality ──
    let _ar_causal = "";
    if _a_has(_ar_norm, "tai sao") == 1 || _a_has(_ar_norm, "vi sao") == 1 || _a_has(_ar_norm, "nguyen nhan") == 1 || _a_has(_ar_norm, "why") == 1 || _a_has(_ar_norm, "because") == 1 || _a_has(_ar_norm, "cause") == 1 {
        _ar_causal = " (Cau hoi ve nguyen nhan — minh tim moi lien he.)";
    };

    // ── 7d. INSTINCT #4: Abstraction ──
    // If query is very general (short, no specific keywords) → abstract
    let _ar_abstract = "";
    if _ar_conf >= 50 {
        if _ar_sim_count >= 5 { _ar_abstract = " [khai niem quen thuoc]"; };
    };

    // ── 7e. INSTINCT #5: Analogy ──
    // Detect "giong nhu", "tuong tu", "like", "similar" → analogy mode
    let _ar_analogy = "";
    if _a_has(_ar_norm, "giong") == 1 || _a_has(_ar_norm, "tuong tu") == 1 || _a_has(_ar_norm, "similar") == 1 || _a_has(_ar_norm, "like") == 1 {
        _ar_analogy = " (So sanh — minh tim diem tuong dong.)";
    };

    // ── 7f. INSTINCT #7: Reflection ──
    // After 5+ turns, reflect on conversation quality
    let _ar_reflect = "";
    if stm_count() >= 5 {
        if stm_count() % 5 == 0 {
            _ar_reflect = " (Minh dang suy nghi ve cuoc tro chuyen cua chung ta.)";
        };
    };

    // ── SC.16 CHECKPOINT 4: Promote ──
    // Decide if knowledge should be promoted (high confidence + high fire)
    // This is where Dream would cluster hot patterns
    if _ar_conf >= 90 { if _ar_novelty < 3 { }; }; // well-known, stable

    // ── 8. UDC DECODE (molecule → mood label) ──
    let _ar_mood = udc_describe(mol);

    // ── 9. OUTPUT EMOJI (emotion → emoji) ──
    let _ar_out_emoji = emoji_for_emotion(_ar_emo.v, _ar_emo.a);

    // ── 10. ALIAS OUTPUT ──
    let reply = compose_reply(intent, tone, _ar_norm);

    // ── 11. COMPOSE FINAL OUTPUT ──
    // P1-E: When knowledge found, lead with fact directly (not template)
    let _ar_out = "";
    if len(_ar_knowledge) > 0 {
        _ar_out = _ar_out_emoji + " " + _ar_knowledge;
        // Append confidence
        if _ar_conf >= 90 { _ar_out = _ar_out + " [fact]"; };
        if _ar_conf >= 70 { if _ar_conf < 90 { _ar_out = _ar_out + " [opinion]"; }; };
        if len(_ar_contradiction) > 0 { _ar_out = _ar_out + " [!] " + _ar_contradiction; };
        if len(_ar_causal) > 0 { _ar_out = _ar_out + _ar_causal; };
        if len(_ar_analogy) > 0 { _ar_out = _ar_out + _ar_analogy; };
        if len(_ar_abstract) > 0 { _ar_out = _ar_out + _ar_abstract; };
        if len(memory_context) > 0 { _ar_out = _ar_out + memory_context; };
        if len(_ar_reflect) > 0 { _ar_out = _ar_out + _ar_reflect; };
    } else {
        _ar_out = _ar_out_emoji + " " + reply;
        if _ar_conf >= 50 { if _ar_conf < 70 { _ar_out = _ar_out + " [hypothesis]"; }; };
        if _ar_novelty > 7 {
            _ar_out = _ar_out + " (Chu de moi — minh muon tim hieu them.)";
        };
        if len(_ar_causal) > 0 { _ar_out = _ar_out + _ar_causal; };
        if len(_ar_analogy) > 0 { _ar_out = _ar_out + _ar_analogy; };
        if len(_ar_reflect) > 0 { _ar_out = _ar_out + _ar_reflect; };
        if len(memory_context) > 0 { _ar_out = _ar_out + memory_context; };
    };

    // ── SC.6: DNA Repair (self-correction) ──
    // If contradiction detected AND we have high confidence knowledge → correct
    if len(_ar_contradiction) > 0 {
        if _ar_conf >= 70 {
            // We're confident in our knowledge AND user contradicts → gently correct
            _ar_contradiction = "Theo nhung gi minh biet, dieu nay co ve khac. Minh co the sai — ban co the giai thich them?";
        };
    };
    // If free energy too high (system unstable) → add stabilizing note
    if __free_energy >= 5 {
        if len(_ar_reflect) == 0 {
            _ar_reflect = " (He thong dang thich nghi voi thay doi.)";
        };
    };

    // ── SC.4: Immune Selection N=3 ──
    // Generate 3 candidate responses, score, pick best
    // Candidate 1: current _ar_out (knowledge-based or template)
    // Candidate 2: STM-based (related previous input)
    // Candidate 3: Silk-based (associated concept)
    let _ar_c1_score = len(_ar_out);  // longer = more informative
    if _ar_conf >= 90 { _ar_c1_score = _ar_c1_score + 50; };
    if _ar_conf >= 70 { _ar_c1_score = _ar_c1_score + 30; };

    // Candidate 2: if STM has related context, might be better
    let _ar_c2 = "";
    let _ar_c2_score = 0;
    if stm_count() >= 2 {
        let _ar_stm_rel = stm_find_related(_ar_norm);
        if len(_ar_stm_rel) > 0 {
            if _ar_stm_rel != _ar_norm {
                _ar_c2 = _ar_out_emoji + " " + reply + " (Lien quan den: " + _ar_stm_rel + ")";
                _ar_c2_score = len(_ar_c2) + 10;  // bonus for context
            };
        };
    };

    // Candidate 3: Silk-associated word
    let _ar_c3 = "";
    let _ar_c3_score = 0;
    let _ar_silk_rel = silk_find_related(_ar_norm);
    if _ar_silk_rel > 0 {
        // Silk returns mol (number), not string — can't display directly
        // But it means there IS an association → boost candidate 1
        _ar_c1_score = _ar_c1_score + 5;
    };

    // Select best candidate
    if _ar_c2_score > _ar_c1_score {
        if _ar_c2_score > _ar_c3_score { _ar_out = _ar_c2; };
    };

    // ── SC.16 CHECKPOINT 5: Response — action-driven ──
    if _ar_action == "ask" {
        _ar_out = _ar_out_emoji + " Minh chua hieu ro. Ban muon hoi ve dieu gi?";
    };
    if len(_ar_out) == 0 { _ar_out = _ar_out_emoji + " Minh nghe roi."; };

    // Store turn AFTER search (so query doesn't find itself)
    kt_learn_to(_ar_norm, "conversations");

    return _ar_out;
}

// ════════════════════════════════════════════════════════════════
// Knowledge Store — UDC Chain architecture (SC.7)
// ════════════════════════════════════════════════════════════════
// Each entry stores:
//   text:  original string (for display)
//   chain: array of u16 molecules (UDC encoding, 2 bytes/word)
//   mol:   composed molecule for the whole fact (1 u16 for similarity)
//   words: keyword strings (for backward-compatible text search)
//
// Search uses DUAL strategy:
//   1. Molecule similarity (fast, language-agnostic)
//   2. Keyword matching (fallback, exact)
// Best match = max(mol_score × 2, keyword_score)

let __knowledge_max = 512;

// Encode text → UDC chain (array of molecules, one per word)
// Uses lightweight encoding: first 2 chars → codepoint → encode_codepoint
// This avoids heavy encode_text (which allocates molecule arrays on heap)
// _text_to_chain removed — dead code (0 calls)

// Molecule distance: |Va-Vb| + |Aa-Ab| (Manhattan on V,A — the emotional axes)

// _mol_similarity removed — dead code (0 calls)



// ════════════════════════════════════════════════════════════════
// CUT.4 — Self-Build: origin.olang builds itself
// ════════════════════════════════════════════════════════════════


