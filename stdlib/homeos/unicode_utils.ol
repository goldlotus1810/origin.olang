// homeos/unicode_utils.ol — Unicode utilities for Vietnamese text
// strip_diacritics: "tổng" → "tong", "sắp xếp" → "sap xep"

// Vietnamese codepoint → ASCII base character
fn _vn_base(cp) {
    // À-Ã, Å (192-195,197) → A
    if cp >= 192 { if cp <= 195 { return 65; }; };
    if cp == 197 { return 65; };
    // à-ã, å (224-227,229) → a
    if cp >= 224 { if cp <= 227 { return 97; }; };
    if cp == 229 { return 97; };
    // Ă (258-259) → A/a
    if cp == 258 { return 65; };
    if cp == 259 { return 97; };
    // Â (194) → A, â (226) → a (already covered above)
    // È-Ë (200-203) → E
    if cp >= 200 { if cp <= 203 { return 69; }; };
    // è-ë (232-235) → e
    if cp >= 232 { if cp <= 235 { return 101; }; };
    // Ê (202) already covered, ê (234) already covered
    // Ì-Ï (204-207) → I
    if cp >= 204 { if cp <= 207 { return 73; }; };
    // ì-ï (236-239) → i
    if cp >= 236 { if cp <= 239 { return 105; }; };
    // Ò-Ö (210-214) → O
    if cp >= 210 { if cp <= 214 { return 79; }; };
    // ò-ö (242-246) → o
    if cp >= 242 { if cp <= 246 { return 111; }; };
    // Ô (212) already covered, ô (244) already covered
    // Ơ (416-417) → O/o
    if cp == 416 { return 79; };
    if cp == 417 { return 111; };
    // Ù-Ü (217-220) → U
    if cp >= 217 { if cp <= 220 { return 85; }; };
    // ù-ü (249-252) → u
    if cp >= 249 { if cp <= 252 { return 117; }; };
    // Ư (431-432) → U/u
    if cp == 431 { return 85; };
    if cp == 432 { return 117; };
    // Ý (221) → Y, ý (253) → y
    if cp == 221 { return 89; };
    if cp == 253 { return 121; };
    // Đ (272) → D, đ (273) → d
    if cp == 272 { return 68; };
    if cp == 273 { return 100; };
    // Vietnamese extended: U+1EA0-U+1EFF
    if cp >= 7840 { if cp <= 7929 {
        // Ạ-Ặ (7840-7863) → A/a
        if cp >= 7840 { if cp <= 7863 { if (cp - 7840) % 2 == 0 { return 65; } else { return 97; }; }; };
        // Ẹ-Ệ (7864-7879) → E/e
        if cp >= 7864 { if cp <= 7879 { if (cp - 7864) % 2 == 0 { return 69; } else { return 101; }; }; };
        // Ỉ-Ị (7880-7883) → I/i
        if cp >= 7880 { if cp <= 7883 { if (cp - 7880) % 2 == 0 { return 73; } else { return 105; }; }; };
        // Ọ-Ợ (7884-7907) → O/o
        if cp >= 7884 { if cp <= 7907 { if (cp - 7884) % 2 == 0 { return 79; } else { return 111; }; }; };
        // Ụ-Ự (7908-7921) → U/u
        if cp >= 7908 { if cp <= 7921 { if (cp - 7908) % 2 == 0 { return 85; } else { return 117; }; }; };
        // Ỳ-Ỹ (7922-7929) → Y/y
        if cp >= 7922 { if cp <= 7929 { if (cp - 7922) % 2 == 0 { return 89; } else { return 121; }; }; };
    }; };
    return 0;  // not a diacritical character
}

// Strip all Vietnamese diacritics from a string
// "tổng" → "tong", "Hà Nội" → "Ha Noi"
pub fn strip_diacritics(_sd_text) {
    let _sd_result = "";
    let _sd_i = 0;
    let _sd_len = len(_sd_text);
    while _sd_i < _sd_len {
        let _sd_code = __char_code(char_at(_sd_text, _sd_i));
        if _sd_code < 128 {
            // ASCII — keep as-is
            _sd_result = _sd_result + char_at(_sd_text, _sd_i);
            let _sd_i = _sd_i + 1;
        } else {
            // Multi-byte UTF-8: get full codepoint
            let _sd_cp = __utf8_cp(_sd_text, _sd_i);
            let _sd_bytes = __utf8_len(_sd_text, _sd_i);
            let _sd_base = _vn_base(_sd_cp);
            if _sd_base > 0 {
                _sd_result = _sd_result + __chr(_sd_base);
            } else {
                // Keep non-Vietnamese Unicode: copy all bytes
                let _sd_bi = 0;
                while _sd_bi < _sd_bytes {
                    _sd_result = _sd_result + char_at(_sd_text, _sd_i + _sd_bi);
                    let _sd_bi = _sd_bi + 1;
                };
            };
            let _sd_i = _sd_i + _sd_bytes;
        };
    };
    return _sd_result;
}
