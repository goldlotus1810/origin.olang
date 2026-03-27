// stdlib/crypto/hmac.ol — HMAC-SHA256 (RFC 2104)
// Uses __sha256 builtin for hash

pub fn hmac_sha256(_hm_key, _hm_msg) {
    // Pad key to 64 bytes (SHA-256 block size)
    let _hm_k = _hm_key;
    if len(_hm_k) > 64 {
        _hm_k = __sha256(_hm_k);
    };
    // Pad with zeros to 64 bytes
    while len(_hm_k) < 128 {
        _hm_k = _hm_k + "0";
    };
    // Now _hm_k is 128 hex chars = 64 bytes

    // Build ipad (0x36) and opad (0x5c) XOR'd keys
    let _hm_ipad = "";
    let _hm_opad = "";
    let _hm_i = 0;
    while _hm_i < 128 {
        let _hm_h1 = _hex_val(char_at(_hm_k, _hm_i));
        let _hm_h2 = _hex_val(char_at(_hm_k, _hm_i + 1));
        let _hm_byte = _hm_h1 * 16 + _hm_h2;
        let _hm_ib = __bit_xor(_hm_byte, 0x36);
        let _hm_ob = __bit_xor(_hm_byte, 0x5C);
        _hm_ipad = _hm_ipad + _hex_byte(_hm_ib);
        _hm_opad = _hm_opad + _hex_byte(_hm_ob);
        _hm_i = _hm_i + 2;
    };

    // HMAC = SHA256(opad || SHA256(ipad || message))
    // Convert hex ipad to raw string for concatenation
    let _hm_inner_input = _hex_to_str(_hm_ipad) + _hm_msg;
    let _hm_inner_hash = __sha256(_hm_inner_input);
    let _hm_outer_input = _hex_to_str(_hm_opad) + _hex_to_str(_hm_inner_hash);
    return __sha256(_hm_outer_input);
}

fn _hex_val(_hv_c) {
    let _hv_code = __char_code(_hv_c);
    if _hv_code >= 97 { return _hv_code - 87; };
    if _hv_code >= 65 { return _hv_code - 55; };
    return _hv_code - 48;
}

fn _hex_byte(_hb_n) {
    let _hb_hi = __floor(_hb_n / 16);
    let _hb_lo = _hb_n % 16;
    return _hex_char(_hb_hi) + _hex_char(_hb_lo);
}

fn _hex_char(_hc_n) {
    if _hc_n < 10 { return __chr(_hc_n + 48); };
    return __chr(_hc_n + 87);
}

fn _hex_to_str(_hts_hex) {
    let _hts_out = "";
    let _hts_i = 0;
    while _hts_i < len(_hts_hex) {
        let _hts_h1 = _hex_val(char_at(_hts_hex, _hts_i));
        let _hts_h2 = _hex_val(char_at(_hts_hex, _hts_i + 1));
        _hts_out = _hts_out + __chr(_hts_h1 * 16 + _hts_h2);
        _hts_i = _hts_i + 2;
    };
    return _hts_out;
}
