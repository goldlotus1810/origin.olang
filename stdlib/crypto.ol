// Nox Crypto — MD5, Base64 in pure Olang
// freedom: deep think -> growing — Nox owns its own cryptography

// ═══ MD5 (RFC 1321) — pure Olang, zero dependencies ═══

// MD5 sine table: T[i] = floor(2^32 * abs(sin(i+1)))
// Initialized inline at boot (not lazily — survives heap restore)
let _md5_T = [
    3614090360, 3905402710, 606105819,  3250441966,
    4118548399, 1200080426, 2821735955, 4249261313,
    1770035416, 2336552879, 4294925233, 2304563134,
    1804603682, 4254626195, 2792965006, 1236535329,
    4129170786, 3225465664, 643717713,  3921069994,
    3593408605, 38016083,   3634488961, 3889429448,
    568446438,  3275163606, 4107603335, 1163531501,
    2850285829, 4243563512, 1735328473, 2368359562,
    4294588738, 2272392833, 1839030562, 4259657740,
    2763975236, 1272893353, 4139469664, 3200236656,
    681279174,  3936430074, 3572445317, 76029189,
    3654602809, 3873151461, 530742520,  3299628645,
    4096336452, 1126891415, 2878612391, 4237533241,
    1700485571, 2399980690, 4293915773, 2240044497,
    1873313359, 4264355552, 2734768916, 1309151649,
    4149444226, 3174756917, 718787259,  3951481745
];

// MD5 shift amounts per round
let _md5_s = [
    7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
    5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
];

// 32-bit unsigned operations using f64
// Olang f64 has 53-bit mantissa — enough for 32-bit integers
fn _u32(x) {
    let v = __floor(x) % 4294967296;
    if v < 0 { v = v + 4294967296; };
    return v;
}

fn _u32_add(a, b) {
    let v = __floor(a + b) % 4294967296;
    if v < 0 { v = v + 4294967296; };
    return v;
}

fn _u32_not(x) {
    let v = __floor(x) % 4294967296;
    if v < 0 { v = v + 4294967296; };
    return 4294967295 - v;
}

fn _rotl32(x, n) {
    let v = __floor(x) % 4294967296;
    if v < 0 { v = v + 4294967296; };
    let left = _u32(v << n);
    let right = _u32(v >> (32 - n));
    return _u32(left | right);
}

// MD5 hash — returns 32-char hex string
pub fn md5(input) {

    // Convert input string to byte array
    let msg = [];
    let mi = 0;
    while mi < len(input) {
        push(msg, __char_code(char_at(input, mi)));
        mi = mi + 1;
    };
    let orig_len = len(msg);

    // Padding: append 0x80, then zeros, then 64-bit length
    push(msg, 128);
    while (len(msg) % 64) != 56 {
        push(msg, 0);
    };
    // Append original length in bits (little-endian, 64-bit)
    let bit_len = orig_len * 8;
    push(msg, __floor(bit_len) % 256);
    push(msg, __floor(bit_len / 256) % 256);
    push(msg, __floor(bit_len / 65536) % 256);
    push(msg, __floor(bit_len / 16777216) % 256);
    push(msg, 0); push(msg, 0); push(msg, 0); push(msg, 0);

    // Initial hash values
    let h0 = 1732584193;   // 0x67452301
    let h1 = 4023233417;   // 0xefcdab89
    let h2 = 2562383102;   // 0x98badcfe
    let h3 = 271733878;    // 0x10325476

    // Process each 64-byte (512-bit) block
    let block = 0;
    while block < len(msg) {
        // Parse block into 16 x 32-bit words (little-endian)
        let M = [];
        let wi = 0;
        while wi < 16 {
            let off = block + wi * 4;
            let w = msg[off] | (msg[off + 1] << 8) | (msg[off + 2] << 16) | (msg[off + 3] << 24);
            push(M, _u32(w));
            wi = wi + 1;
        };

        let a = h0;
        let b = h1;
        let c = h2;
        let d = h3;

        // 64 rounds
        let i = 0;
        while i < 64 {
            let f = 0;
            let g = 0;
            if i < 16 {
                f = (b & c) | (_u32_not(b) & d);
                g = i;
            };
            if i >= 16 {
                if i < 32 {
                    f = _u32((d & b) | (_u32_not(d) & c));
                    g = (5 * i + 1) % 16;
                };
            };
            if i >= 32 {
                if i < 48 {
                    f = _u32(_u32(b ^ c) ^ d);
                    g = (3 * i + 5) % 16;
                };
            };
            if i >= 48 {
                f = _u32(c ^ _u32(b | _u32_not(d)));
                g = (7 * i) % 16;
            };

            f = _u32(f);
            let temp = d;
            d = c;
            c = b;
            let sum = _u32_add(a, f);
            sum = _u32_add(sum, _md5_T[i]);
            sum = _u32_add(sum, M[g]);
            b = _u32_add(b, _u32(_rotl32(sum, _md5_s[i])));
            a = temp;
            i = i + 1;
        };

        h0 = _u32_add(h0, a);
        h1 = _u32_add(h1, b);
        h2 = _u32_add(h2, c);
        h3 = _u32_add(h3, d);

        block = block + 64;
    };

    // Output as 32-char hex string (little-endian per word)
    let hex_ch = "0123456789abcdef";
    let out = "";
    let _hwords = [h0, h1, h2, h3];
    let _hwi = 0;
    while _hwi < 4 {
        let w = _u32(_hwords[_hwi]);
        let bi = 0;
        while bi < 4 {
            let byte = __floor(w >> (bi * 8)) % 256;
            if byte < 0 { byte = byte + 256; };
            out = out + char_at(hex_ch, __floor(byte / 16)) + char_at(hex_ch, __floor(byte % 16));
            bi = bi + 1;
        };
        _hwi = _hwi + 1;
    };
    return out;
}

// ═══ BASE64 ENCODE/DECODE ═══

let _b64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

pub fn base64_encode(input) {
    let out = "";
    let i = 0;
    while i < len(input) {
        let b0 = __char_code(char_at(input, i));
        let b1 = 0;
        let b2 = 0;
        let pad = 0;
        if (i + 1) < len(input) { b1 = __char_code(char_at(input, i + 1)); } else { pad = pad + 1; };
        if (i + 2) < len(input) { b2 = __char_code(char_at(input, i + 2)); } else { pad = pad + 1; };

        let n = (b0 << 16) | (b1 << 8) | b2;
        out = out + char_at(_b64_chars, (n >> 18) & 63);
        out = out + char_at(_b64_chars, (n >> 12) & 63);
        if pad < 2 { out = out + char_at(_b64_chars, (n >> 6) & 63); } else { out = out + "="; };
        if pad < 1 { out = out + char_at(_b64_chars, n & 63); } else { out = out + "="; };

        i = i + 3;
    };
    return out;
}

fn _byte_to_char(b) {
    return __chr(b);
}

pub fn base64_decode(input) {
    let out = "";
    let i = 0;
    while i < len(input) {
        let c0 = _b64_val(char_at(input, i));
        let c1 = _b64_val(char_at(input, i + 1));
        let c2 = _b64_val(char_at(input, i + 2));
        let c3 = _b64_val(char_at(input, i + 3));
        let n = (c0 << 18) | (c1 << 12) | (c2 << 6) | c3;
        out = out + _byte_to_char((n >> 16) & 255);
        if char_at(input, i + 2) != "=" { out = out + _byte_to_char((n >> 8) & 255); };
        if char_at(input, i + 3) != "=" { out = out + _byte_to_char(n & 255); };
        i = i + 4;
    };
    return out;
}

fn _b64_val(ch) {
    let c = __char_code(ch);
    if c >= 65 && c <= 90 { return c - 65; };
    if c >= 97 && c <= 122 { return c - 71; };
    if c >= 48 && c <= 57 { return c + 4; };
    if c == 43 { return 62; };
    if c == 47 { return 63; };
    return 0;
}

// ═══ HEX ENCODE/DECODE ═══

pub fn hex_encode(input) {
    let hex = "0123456789abcdef";
    let out = "";
    let i = 0;
    while i < len(input) {
        let b = __char_code(char_at(input, i));
        out = out + char_at(hex, __floor(b / 16)) + char_at(hex, b % 16);
        i = i + 1;
    };
    return out;
}

pub fn hex_decode(input) {
    let out = "";
    let i = 0;
    while i < len(input) {
        let h = _hex_val(char_at(input, i));
        let l = _hex_val(char_at(input, i + 1));
        out = out + _byte_to_char(h * 16 + l);
        i = i + 2;
    };
    return out;
}

fn _hex_val(ch) {
    let c = __char_code(ch);
    if c >= 48 && c <= 57 { return c - 48; };
    if c >= 97 && c <= 102 { return c - 87; };
    if c >= 65 && c <= 70 { return c - 55; };
    return 0;
}
