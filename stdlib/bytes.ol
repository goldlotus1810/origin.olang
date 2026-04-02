// bytes.ol — Byte array utilities for binary I/O
// Depends on: __u8_new, __u8_get, __u8_set (VM builtins)

// Pack u16 little-endian into byte array at offset
fn u8_pack_u16(buf, offset, val) {
    __u8_set(buf, offset, __bit_and(val, 255));
    __u8_set(buf, offset + 1, __bit_and(__bit_shr(val, 8), 255));
};

// Unpack u16 little-endian from byte array at offset
fn u8_unpack_u16(buf, offset) {
    return __u8_get(buf, offset) + __u8_get(buf, offset + 1) * 256;
};

// Pack u32 little-endian
fn u8_pack_u32(buf, offset, val) {
    __u8_set(buf, offset, __bit_and(val, 255));
    __u8_set(buf, offset + 1, __bit_and(__bit_shr(val, 8), 255));
    __u8_set(buf, offset + 2, __bit_and(__bit_shr(val, 16), 255));
    __u8_set(buf, offset + 3, __bit_and(__bit_shr(val, 24), 255));
};

// Unpack u32 little-endian
fn u8_unpack_u32(buf, offset) {
    return __u8_get(buf, offset)
         + __u8_get(buf, offset + 1) * 256
         + __u8_get(buf, offset + 2) * 65536
         + __u8_get(buf, offset + 3) * 16777216;
};

// Copy bytes from src to dst
fn u8_copy(dst, dst_off, src, src_off, count) {
    let i = 0;
    while i < count {
        __u8_set(dst, dst_off + i, __u8_get(src, src_off + i));
        i = i + 1;
    };
};

// Compare byte arrays (returns 0 if equal, nonzero if different)
fn u8_compare(a, a_off, b, b_off, count) {
    let i = 0;
    while i < count {
        let diff = __u8_get(a, a_off + i) - __u8_get(b, b_off + i);
        if diff != 0 { return diff; };
        i = i + 1;
    };
    return 0;
};

// String to bytes (ASCII only, 1 char = 1 byte)
fn u8_from_string(str) {
    let n = len(str);
    let buf = __u8_new(n);
    let i = 0;
    while i < n {
        __u8_set(buf, i, __char_code(char_at(str, i)));
        i = i + 1;
    };
    return buf;
};

// Fill bytes with value
fn u8_fill(buf, offset, count, val) {
    let i = 0;
    while i < count {
        __u8_set(buf, offset + i, val);
        i = i + 1;
    };
};
