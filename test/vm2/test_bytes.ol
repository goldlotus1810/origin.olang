// Test byte array builtins: __u8_new, __u8_get, __u8_set
import "stdlib/test.ol"

// Create byte array
let buf = __u8_new(10);
assert("u8_new returns something", buf != 0);

// Set and get bytes
__u8_set(buf, 0, 65);
__u8_set(buf, 1, 66);
__u8_set(buf, 2, 67);
check("u8_get 0", __u8_get(buf, 0), 65);
check("u8_get 1", __u8_get(buf, 1), 66);
check("u8_get 2", __u8_get(buf, 2), 67);

// Default is zero
check("u8_default_zero", __u8_get(buf, 5), 0);

// Overwrite
__u8_set(buf, 0, 90);
check("u8_overwrite", __u8_get(buf, 0), 90);

// Use for binary packing (u16 little-endian)
let pkt = __u8_new(4);
let val = 0x1234;
__u8_set(pkt, 0, __bit_and(val, 255));
__u8_set(pkt, 1, __bit_and(__bit_shr(val, 8), 255));
check("pack_lo", __u8_get(pkt, 0), 0x34);
check("pack_hi", __u8_get(pkt, 1), 0x12);

// Unpack back
let unpacked = __u8_get(pkt, 0) + __u8_get(pkt, 1) * 256;
check("unpack_u16", unpacked, 0x1234);

test_summary();
