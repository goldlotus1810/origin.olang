// Test stdlib/bytes.ol utilities
import "stdlib/test.ol"
import "stdlib/bytes.ol"

// u16 pack/unpack
let buf = __u8_new(16);
u8_pack_u16(buf, 0, 0x1234);
check("pack_u16_lo", __u8_get(buf, 0), 0x34);
check("pack_u16_hi", __u8_get(buf, 1), 0x12);
check("unpack_u16", u8_unpack_u16(buf, 0), 0x1234);

// u32 pack/unpack
u8_pack_u32(buf, 4, 305419896);
check("unpack_u32", u8_unpack_u32(buf, 4), 305419896);

// Edge: zero
u8_pack_u32(buf, 8, 0);
check("u32_zero", u8_unpack_u32(buf, 8), 0);

// Edge: max u16
u8_pack_u16(buf, 12, 65535);
check("u16_max", u8_unpack_u16(buf, 12), 65535);

// Copy
let src = __u8_new(4);
__u8_set(src, 0, 10);
__u8_set(src, 1, 20);
__u8_set(src, 2, 30);
__u8_set(src, 3, 40);
let dst = __u8_new(4);
u8_copy(dst, 0, src, 0, 4);
check("copy_0", __u8_get(dst, 0), 10);
check("copy_3", __u8_get(dst, 3), 40);

// Compare
check("cmp_equal", u8_compare(src, 0, dst, 0, 4), 0);
__u8_set(dst, 2, 99);
assert("cmp_differ", u8_compare(src, 0, dst, 0, 4) != 0);

// String to bytes
let hello = u8_from_string("ABC");
check("str2bytes_0", __u8_get(hello, 0), 65);
check("str2bytes_1", __u8_get(hello, 1), 66);
check("str2bytes_2", __u8_get(hello, 2), 67);

// Fill
let zbuf = __u8_new(8);
u8_fill(zbuf, 0, 8, 0xFF);
check("fill_0", __u8_get(zbuf, 0), 255);
check("fill_7", __u8_get(zbuf, 7), 255);

test_summary();
