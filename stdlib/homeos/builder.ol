// homeos/builder.ol — Self-sufficient builder
// Replaces Rust builder: compile .ol → bytecode, pack with VM → origin.olang
//
// Usage: origin.olang runs this to build a new origin.olang
//   o run builder.ol --stdlib stdlib/ --output origin_new.olang
//   o run builder.ol --stdlib stdlib/ --arch arm64 --output origin_arm64.olang

pub fn build(config) {
  let arch = config.arch;
  emit "Builder — origin.olang packer (Olang) [" + arch + "]";

  // 1. Compile all .ol → bytecode (arch-independent)
  let bytecode = [];
  if config.stdlib_path != "" {
    emit "  Compiling stdlib: " + config.stdlib_path + "";
    bytecode = compile_all(config.stdlib_path);
  };
  emit "  Bytecode: " + __to_string(len(bytecode)) + " bytes (" + __to_string(_g_fold_count[0]) + " constants folded)";

  // WASM/WASI arch: embed bytecode into WASM binary
  if arch == "wasm" || arch == "wasi" {
    return build_wasm(config, bytecode);
  };

  // 2. Read VM binary (full ELF — used as-is, data appended after it)
  let vm_code = [];
  if config.vm_path != "" {
    emit "  Reading VM: " + config.vm_path;
    vm_code = file_read_bytes(config.vm_path);
  };
  let vm_size = len(vm_code);
  emit "  VM: " + __to_string(vm_size) + " bytes";

  // 3. Read knowledge
  let knowledge = [];
  if config.kn_path != "" {
    if len(config.kn_path) > 0 { knowledge = file_read_bytes(config.kn_path); };
  };
  emit "  Knowledge: " + __to_string(len(knowledge)) + " bytes";

  // 4. Build: VM binary + Origin Header + Bytecode + Knowledge + Trailer
  // Layout: [VM ELF][Origin Hdr 32B][Bytecode][Knowledge][Trailer 8B]
  let hdr_offset = vm_size;
  let bc_offset = hdr_offset + 32;
  let kn_offset = bc_offset + len(bytecode);

  let binary = [];
  // Copy VM binary as-is
  concat_bytes(binary, vm_code);
  // Origin Header (32 bytes)
  let origin_hdr = make_origin_header_arch(
    0,                            // vm_offset (not used — VM IS the binary)
    vm_size,
    bc_offset,                    // bc_offset
    len(bytecode),
    kn_offset,                    // kn_offset
    len(knowledge),
    1,                            // flags (1 = codegen format)
    arch
  );
  concat_bytes(binary, origin_hdr);
  // Bytecode
  concat_bytes(binary, bytecode);
  // Knowledge
  concat_bytes(binary, knowledge);
  // Trailer: 8-byte u64 LE pointing to Origin Header
  push_u64(binary, hdr_offset);

  // 5. Write output
  emit "  Writing: " + __to_string(len(binary)) + " bytes";
  file_write_bytes(config.output, binary);
  emit "  Output: " + config.output;
  emit "Done!";
};

fn build_wasm(config, bytecode) {
  // Read pre-compiled WASM VM binary
  let vm_wasm = [];
  if config.vm_path != "" {
    emit "  Reading WASM VM: " + config.vm_path + "";
    vm_wasm = file_read_bytes(config.vm_path);
  };
  emit "  WASM VM: " + __to_string(len(vm_wasm)) + " bytes";

  // Embed bytecode into WASM
  let binary = make_wasm_with_bytecode(vm_wasm, bytecode);
  emit "  WASM + bytecode: " + __to_string(len(binary)) + " bytes";

  // Write output
  file_write_bytes(config.output, binary);
  emit "  Output: " + config.output + " (" + __to_string(len(binary)) + " bytes)";
  emit "Done!";
};

fn compile_all(_ca_stdlib_path) {
  let _ca_all_bc = [];

  // Compile bootstrap files explicitly (compile_dir corrupts dir path after 1st file)
  emit "  Compiling: bootstrap";
  emit "  codegen.ol...";
  compile_one_file("stdlib/bootstrap/codegen.ol", _ca_all_bc);
  compile_one_file("stdlib/bootstrap/lexer.ol", _ca_all_bc);
  compile_one_file("stdlib/bootstrap/parser.ol", _ca_all_bc);
  compile_one_file("stdlib/bootstrap/semantic.ol", _ca_all_bc);
  // Compile stdlib root files
  compile_dir("stdlib", _ca_all_bc);
  // Compile homeos files
  compile_dir("stdlib/homeos", _ca_all_bc);
  emit "  (stdlib/homeos/editor skipped for boot test)";

  // Final Halt
  push(_ca_all_bc, 15);
  return _ca_all_bc;
};

let _cd_global_count = [0];
let _cd_max_files = [999];   // Set to N for testing, 999 for unlimited

fn compile_one_file(_cof_path, _cof_output) {
  let _cof_src = __file_read(_cof_path);
  if len(_cof_src) == 0 { return; };
  let _cof_bc = compile_source(_cof_src);
  // NO __heap_pin() here — temp objects (tokens, AST) should NOT become permanent
  // Only the bytecode in _cof_output needs to survive
  let _cof_bclen = len(_cof_bc);
  emit "  " + _cof_path + " → " + __to_string(_cof_bclen) + " bytes";
  if _cof_bclen < 2 { return; };
  if __floor(_cof_bc[_cof_bclen - 1]) == 15 { set_at(_cof_bc, _cof_bclen - 1, 18); };
  let _cof_base = len(_cof_output);
  if _cof_base > 0 { relocate_jumps(_cof_bc, _cof_bclen, _cof_base); };
  let _cof_bi = 0;
  while _cof_bi < _cof_bclen { push(_cof_output, _cof_bc[_cof_bi]); _cof_bi = _cof_bi + 1; };
};

fn compile_dir(_xcd_dir, _xcd_output) {
  // Read file list once, pin heap to protect strings from compile_source corruption
  let _xcd_flist = list_ol_files(_xcd_dir);
  __heap_pin();
  let _xcd_idx = 0;
  let _xcd_total = len(_xcd_flist);
  while _xcd_idx < _xcd_total {
    let _xcd_path = _xcd_flist[_xcd_idx];
    let _xcd_src = __file_read(_xcd_path);
    if len(_xcd_src) > 0 {
      let _xcd_bc = compile_source(_xcd_src);
      let _xcd_bclen = len(_xcd_bc);
      emit "  #" + __to_string(_xcd_idx) + " → " + __to_string(_xcd_bclen) + " bytes";
      if _xcd_bclen > 0 {
        if __floor(_xcd_bc[_xcd_bclen - 1]) == 15 { set_at(_xcd_bc, _xcd_bclen - 1, 18); };
        let _xcd_base = len(_xcd_output);
        if _xcd_base > 0 { relocate_jumps(_xcd_bc, _xcd_bclen, _xcd_base); };
        let _xcd_bi = 0;
        while _xcd_bi < _xcd_bclen { push(_xcd_output, _xcd_bc[_xcd_bi]); _xcd_bi = _xcd_bi + 1; };
      };
      // NO __heap_pin() — let temp objects be reusable
    };
    _xcd_idx = _xcd_idx + 1;
  };
};

fn compile_source(_cs_src) {
  reset_compiler();
  let _cs_tokens = tokenize(_cs_src);
  let _cs_ntok = len(_cs_tokens);
  let _cs_parser = { tokens: _cs_tokens, pos: 0 };
  let _cs_ast = [];
  let _cs_errors = 0;
  while _cs_parser.pos < _cs_ntok {
    let _cs_peek = _cs_tokens[_cs_parser.pos];
    if _cs_peek.text == "" { _cs_parser.pos = _cs_ntok; }
    else {
      let _cs_prev_pos = _cs_parser.pos;
      try { push(_cs_ast, parse_stmt(_cs_parser)); }
      catch { _cs_errors = _cs_errors + 1; };
      if _cs_parser.pos == _cs_prev_pos { _cs_parser.pos = _cs_parser.pos + 1; };
      if _cs_errors > 10 { _cs_parser.pos = _cs_ntok; };
    };
  };
  return compile_isolated(_cs_ast);
};

fn list_ol_files(_lof_dir) {
  let _lof_all = __readdir(_lof_dir);
  let _lof_result = [];
  let _lof_i = 0;
  while _lof_i < len(_lof_all) {
    let _lof_name = _lof_all[_lof_i];
    let _lof_nlen = len(_lof_name);
    if _lof_nlen > 3 {
      if __substr(_lof_name, _lof_nlen - 3, _lof_nlen) == ".ol" {
        push(_lof_result, _lof_dir + "/" + _lof_name);
      };
    };
    _lof_i = _lof_i + 1;
  };
  return _lof_result;
};

fn file_read_bytes(_frb_path) {
  // Read file as raw byte buffer, convert to byte value array
  let _frb_buf = __file_read_bytes(_frb_path);
  let _frb_len = __bytes_len(_frb_buf);
  let _frb_arr = [];
  let _frb_i = 0;
  while _frb_i < _frb_len {
    push(_frb_arr, __bytes_get(_frb_buf, _frb_i));
    _frb_i = _frb_i + 1;
  };
  return _frb_arr;
};

// file_read_string removed — dead code (trivial wrapper, 0 calls)

fn file_write_bytes(_fwb_path, _fwb_data) {
  let _fwb_len = len(_fwb_data);
  let _fwb_buf = __bytes_new(_fwb_len);
  let _fwb_i = 0;
  while _fwb_i < _fwb_len {
    __bytes_set(_fwb_buf, _fwb_i, __floor(_fwb_data[_fwb_i]));
    _fwb_i = _fwb_i + 1;
  };
  __bytes_write(_fwb_path, _fwb_buf, _fwb_len);
};

fn concat_bytes(dst, src) {
  let i = 0;
  while i < len(src) {
    push(dst, src[i]);
    i = i + 1;
  };
};

// ── Default config ──

pub fn default_config() {
  let _dc_cfg = { vm_path: "vm/x86_64/vm_x86_64", stdlib_path: "stdlib", kn_path: "", output: "origin_new.olang", arch: "x86_64" };
  return _dc_cfg;
};

// arm64_config, wasm_config, wasi_config removed — dead code (0 calls)
// Multi-arch support deferred — x86_64 only for now

// fat_config, build_fat: multi-arch deferred — stub only
pub fn build_fat(config) { return "Multi-arch deferred"; };
// Original build_fat body removed (~90 lines)
// _build_fat_original removed — dead code (0 calls)

fn to_bytes(str) {
  return __str_bytes(str);
};

// relocate_jumps MUST be last function in file — Rust compiler generates
// bad jump targets for complex if-else chains, corrupting later fn definitions.
fn relocate_jumps(_rj_bc, _rj_len, _rj_base) {
  // Scan bytecode, add _rj_base to all Jmp/Jz/TryBegin targets
  // NOTE: Rust compiler has NO operator precedence (all left-to-right)
  //       so ALL mixed +/* expressions MUST use explicit parentheses!
  let _rj_pc = 0;
  while _rj_pc < _rj_len {
    let _rj_tag = __floor(_rj_bc[_rj_pc]);
    _rj_pc = _rj_pc + 1;
    let _rj_skip = 0;
    if _rj_tag == 1 { if _rj_pc + 2 <= _rj_len { let _rj_slen = __floor(_rj_bc[_rj_pc]) + (__floor(_rj_bc[_rj_pc+1]) * 256); _rj_skip = 2 + (_rj_slen * 2); }; };
    if _rj_tag == 2 { if _rj_pc < _rj_len { _rj_skip = 1 + __floor(_rj_bc[_rj_pc]); }; };
    if _rj_tag == 7 { if _rj_pc < _rj_len { _rj_skip = 1 + __floor(_rj_bc[_rj_pc]); }; };
    if _rj_tag == 19 { if _rj_pc < _rj_len { _rj_skip = 1 + __floor(_rj_bc[_rj_pc]); }; };
    if _rj_tag == 20 { if _rj_pc < _rj_len { _rj_skip = 1 + __floor(_rj_bc[_rj_pc]); }; };
    if _rj_tag == 28 { if _rj_pc < _rj_len { _rj_skip = 1 + __floor(_rj_bc[_rj_pc]); }; };
    if _rj_tag == 9 { _rj_skip = 4; };
    if _rj_tag == 10 { _rj_skip = 4; };
    if _rj_tag == 26 { _rj_skip = 4; };
    if _rj_tag == 14 { _rj_skip = 4; };
    if _rj_tag == 21 { _rj_skip = 8; };
    if _rj_tag == 25 { _rj_skip = 2; };
    if _rj_tag == 37 { _rj_skip = 5; };
    if _rj_tag == 36 { if _rj_pc < _rj_len { _rj_skip = 2 + __floor(_rj_bc[_rj_pc]); }; };
    if _rj_tag == 38 { _rj_skip = 1; };
    if _rj_tag == 39 { _rj_skip = 1; };
    if _rj_tag == 40 { _rj_skip = 1; };
    if _rj_tag == 48 {
      if _rj_pc + 2 <= _rj_len {
        let _rj_ccnt = __floor(_rj_bc[_rj_pc + 1]);
        let _rj_cskip = 2;
        let _rj_ci = 0;
        while _rj_ci < _rj_ccnt {
          if _rj_pc + _rj_cskip < _rj_len { _rj_cskip = _rj_cskip + 1 + __floor(_rj_bc[_rj_pc + _rj_cskip]); };
          _rj_ci = _rj_ci + 1;
        };
        _rj_skip = _rj_cskip + 4;
      };
    };
    if _rj_tag == 9 {
      if _rj_pc + 4 <= _rj_len {
        let _rj_b0 = __floor(_rj_bc[_rj_pc]);
        let _rj_b1 = __floor(_rj_bc[_rj_pc+1]);
        let _rj_b2 = __floor(_rj_bc[_rj_pc+2]);
        let _rj_b3 = __floor(_rj_bc[_rj_pc+3]);
        let _rj_t = _rj_b0 + (_rj_b1 * 256) + (_rj_b2 * 65536) + (_rj_b3 * 16777216) + _rj_base;
        set_at(_rj_bc, _rj_pc, __floor(_rj_t) % 256);
        set_at(_rj_bc, _rj_pc+1, __floor(_rj_t / 256) % 256);
        set_at(_rj_bc, _rj_pc+2, __floor(_rj_t / 65536) % 256);
        set_at(_rj_bc, _rj_pc+3, __floor(_rj_t / 16777216) % 256);
      };
    };
    if _rj_tag == 10 {
      if _rj_pc + 4 <= _rj_len {
        let _rj_b0 = __floor(_rj_bc[_rj_pc]);
        let _rj_b1 = __floor(_rj_bc[_rj_pc+1]);
        let _rj_b2 = __floor(_rj_bc[_rj_pc+2]);
        let _rj_b3 = __floor(_rj_bc[_rj_pc+3]);
        let _rj_t = _rj_b0 + (_rj_b1 * 256) + (_rj_b2 * 65536) + (_rj_b3 * 16777216) + _rj_base;
        set_at(_rj_bc, _rj_pc, __floor(_rj_t) % 256);
        set_at(_rj_bc, _rj_pc+1, __floor(_rj_t / 256) % 256);
        set_at(_rj_bc, _rj_pc+2, __floor(_rj_t / 65536) % 256);
        set_at(_rj_bc, _rj_pc+3, __floor(_rj_t / 16777216) % 256);
      };
    };
    if _rj_tag == 26 {
      if _rj_pc + 4 <= _rj_len {
        let _rj_b0 = __floor(_rj_bc[_rj_pc]);
        let _rj_b1 = __floor(_rj_bc[_rj_pc+1]);
        let _rj_b2 = __floor(_rj_bc[_rj_pc+2]);
        let _rj_b3 = __floor(_rj_bc[_rj_pc+3]);
        let _rj_t = _rj_b0 + (_rj_b1 * 256) + (_rj_b2 * 65536) + (_rj_b3 * 16777216) + _rj_base;
        set_at(_rj_bc, _rj_pc, __floor(_rj_t) % 256);
        set_at(_rj_bc, _rj_pc+1, __floor(_rj_t / 256) % 256);
        set_at(_rj_bc, _rj_pc+2, __floor(_rj_t / 65536) % 256);
        set_at(_rj_bc, _rj_pc+3, __floor(_rj_t / 16777216) % 256);
      };
    };
    _rj_pc = _rj_pc + _rj_skip;
  };
};
