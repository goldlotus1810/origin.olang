// homeos/byte_utils.ol — Shared byte buffer helpers (LE encoding)
// Used by: elf_emit.ol, fat_header.ol, builder.ol, wasm_emit.ol

pub fn push_bytes(buf, bytes) {
  let _pb_i = 0;
  while _pb_i < len(bytes) {
    push(buf, bytes[_pb_i]);
    let _pb_i = _pb_i + 1;
  };
}

pub fn push_u16(buf, val) {
  push(buf, val % 256);
  push(buf, __floor(val / 256) % 256);
}

pub fn push_u32(buf, val) {
  push(buf, val % 256);
  push(buf, __floor(val / 256) % 256);
  push(buf, __floor(val / 65536) % 256);
  push(buf, __floor(val / 16777216) % 256);
}

pub fn push_u64(buf, val) {
  push_u32(buf, val % 4294967296);
  push_u32(buf, __floor(val / 4294967296));
}
