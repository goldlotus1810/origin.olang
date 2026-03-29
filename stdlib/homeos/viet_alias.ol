// stdlib/homeos/viet_alias.ol — Vietnamese Unicode → ASCII alias
//
// Lupin: "tieng Anh = ASCII don gian, tieng Viet = alias = unicode"
// Normalize Vietnamese diacritics to ASCII for matching:
//   "Hà Nội" → "Ha Noi"
//   "Việt Nam" → "Viet Nam"
// This makes text search work regardless of diacritics.

pub fn viet_normalize(_vn_text) {
    let _vn_out = "";
    let _vn_i = 0;
    let _vn_tlen = len(_vn_text);
    while _vn_i < _vn_tlen {
        let _vn_cp = __char_code(char_at(_vn_text, _vn_i));
        // ASCII passthrough (0-127)
        if _vn_cp < 128 {
            let _vn_out = _vn_out + char_at(_vn_text, _vn_i);
        };
        // Vietnamese vowels with diacritics → ASCII
        if _vn_cp >= 128 {
            let _vn_alias = _vn_map_cp(_vn_cp);
            let _vn_out = _vn_out + _vn_alias;
        };
        let _vn_i = _vn_i + 1;
    };
    return _vn_out;
}

// Map Vietnamese codepoints to ASCII equivalents
fn _vn_map_cp(_cp) {
    // à á ả ã ạ → a
    if _cp == 224 { return "a"; };  // à
    if _cp == 225 { return "a"; };  // á
    if _cp == 7843 { return "a"; }; // ả
    if _cp == 227 { return "a"; };  // ã
    if _cp == 7841 { return "a"; }; // ạ
    // ă ắ ằ ẳ ẵ ặ → a
    if _cp == 259 { return "a"; };  // ă
    if _cp == 7855 { return "a"; }; // ắ
    if _cp == 7857 { return "a"; }; // ằ
    if _cp == 7859 { return "a"; }; // ẳ
    if _cp == 7861 { return "a"; }; // ẵ
    if _cp == 7863 { return "a"; }; // ặ
    // â ấ ầ ẩ ẫ ậ → a
    if _cp == 226 { return "a"; };  // â
    if _cp == 7845 { return "a"; }; // ấ
    if _cp == 7847 { return "a"; }; // ầ
    if _cp == 7849 { return "a"; }; // ẩ
    if _cp == 7851 { return "a"; }; // ẫ
    if _cp == 7853 { return "a"; }; // ậ
    // è é ẻ ẽ ẹ → e
    if _cp == 232 { return "e"; };  // è
    if _cp == 233 { return "e"; };  // é
    if _cp == 7867 { return "e"; }; // ẻ
    if _cp == 7869 { return "e"; }; // ẽ
    if _cp == 7865 { return "e"; }; // ẹ
    // ê ế ề ể ễ ệ → e
    if _cp == 234 { return "e"; };  // ê
    if _cp == 7871 { return "e"; }; // ế
    if _cp == 7873 { return "e"; }; // ề
    if _cp == 7875 { return "e"; }; // ể
    if _cp == 7877 { return "e"; }; // ễ
    if _cp == 7879 { return "e"; }; // ệ
    // ì í ỉ ĩ ị → i
    if _cp == 236 { return "i"; };  // ì
    if _cp == 237 { return "i"; };  // í
    if _cp == 7881 { return "i"; }; // ỉ
    if _cp == 297 { return "i"; };  // ĩ
    if _cp == 7883 { return "i"; }; // ị
    // ò ó ỏ õ ọ → o
    if _cp == 242 { return "o"; };  // ò
    if _cp == 243 { return "o"; };  // ó
    if _cp == 7887 { return "o"; }; // ỏ
    if _cp == 245 { return "o"; };  // õ
    if _cp == 7885 { return "o"; }; // ọ
    // ô ố ồ ổ ỗ ộ → o
    if _cp == 244 { return "o"; };  // ô
    if _cp == 7889 { return "o"; }; // ố
    if _cp == 7891 { return "o"; }; // ồ
    if _cp == 7893 { return "o"; }; // ổ
    if _cp == 7895 { return "o"; }; // ỗ
    if _cp == 7897 { return "o"; }; // ộ
    // ơ ớ ờ ở ỡ ợ → o
    if _cp == 417 { return "o"; };  // ơ
    if _cp == 7899 { return "o"; }; // ớ
    if _cp == 7901 { return "o"; }; // ờ
    if _cp == 7903 { return "o"; }; // ở
    if _cp == 7905 { return "o"; }; // ỡ
    if _cp == 7907 { return "o"; }; // ợ
    // ù ú ủ ũ ụ → u
    if _cp == 249 { return "u"; };  // ù
    if _cp == 250 { return "u"; };  // ú
    if _cp == 7911 { return "u"; }; // ủ
    if _cp == 361 { return "u"; };  // ũ
    if _cp == 7909 { return "u"; }; // ụ
    // ư ứ ừ ử ữ ự → u
    if _cp == 432 { return "u"; };  // ư
    if _cp == 7913 { return "u"; }; // ứ
    if _cp == 7915 { return "u"; }; // ừ
    if _cp == 7917 { return "u"; }; // ử
    if _cp == 7919 { return "u"; }; // ữ
    if _cp == 7921 { return "u"; }; // ự
    // ỳ ý ỷ ỹ ỵ → y
    if _cp == 7923 { return "y"; }; // ỳ
    if _cp == 253 { return "y"; };  // ý
    if _cp == 7927 { return "y"; }; // ỷ
    if _cp == 7929 { return "y"; }; // ỹ
    if _cp == 7925 { return "y"; }; // ỵ
    // đ Đ → d
    if _cp == 273 { return "d"; };  // đ
    if _cp == 272 { return "D"; };  // Đ
    // Uppercase variants
    if _cp == 192 { return "A"; };  // À
    if _cp == 193 { return "A"; };  // Á
    if _cp == 194 { return "A"; };  // Â
    if _cp == 195 { return "A"; };  // Ã
    if _cp == 200 { return "E"; };  // È
    if _cp == 201 { return "E"; };  // É
    if _cp == 202 { return "E"; };  // Ê
    if _cp == 204 { return "I"; };  // Ì
    if _cp == 205 { return "I"; };  // Í
    if _cp == 210 { return "O"; };  // Ò
    if _cp == 211 { return "O"; };  // Ó
    if _cp == 212 { return "O"; };  // Ô
    if _cp == 213 { return "O"; };  // Õ
    if _cp == 217 { return "U"; };  // Ù
    if _cp == 218 { return "U"; };  // Ú
    if _cp == 221 { return "Y"; };  // Ý
    // Unknown → skip
    return "";
}
