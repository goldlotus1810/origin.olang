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
  emit "  Bytecode: " + __to_string(len(bytecode)) + " bytes";

  // WASM/WASI arch: embed bytecode into WASM binary
  if arch == "wasm" || arch == "wasi" {
    return build_wasm(config, bytecode);
  };

  // 2. Read VM code (pre-assembled binary for target arch)
  let vm_code = [];
  if config.vm_path != "" {
    emit "  Reading VM: " + config.vm_path + "";
    vm_code = file_read_bytes(config.vm_path);
  };
  emit "  VM code: " + __to_string(len(vm_code)) + " bytes";

  // 3. Read knowledge
  let knowledge = [];
  if config.kn_path != "" {
    knowledge = file_read_bytes(config.kn_path);
  };
  emit "  Knowledge: " + __to_string(len(knowledge)) + " bytes";

  // 4. Pack
  let origin_hdr = make_origin_header_arch(
    152,                          // vm_offset (after ELF 120 + origin 32)
    len(vm_code),
    152 + len(vm_code),           // bc_offset
    len(bytecode),
    152 + len(vm_code) + len(bytecode),  // kn_offset
    len(knowledge),
    0,                            // flags
    arch
  );

  // Concat all sections
  let payload = [];
  concat_bytes(payload, origin_hdr);
  concat_bytes(payload, vm_code);
  concat_bytes(payload, bytecode);
  concat_bytes(payload, knowledge);

  // Wrap in ELF for target arch
  let binary = make_elf_arch(payload, 32, arch);

  // 5. Write output
  file_write_bytes(config.output, binary);
  emit "  Output: " + config.output + " (" + __to_string(len(binary)) + " bytes)";
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

  // Bootstrap first (compiler must be loaded before anything else)
  emit "  Compiling: bootstrap\n";
  compile_dir(_ca_stdlib_path + "/bootstrap", _ca_all_bc);

  // Then stdlib root
  emit "  Compiling: stdlib root\n";
  compile_dir(_ca_stdlib_path, _ca_all_bc);

  // Then homeos
  emit "  Compiling: homeos\n";
  compile_dir(_ca_stdlib_path + "/homeos", _ca_all_bc);

  // Then editor
  emit "  Compiling: editor\n";
  compile_dir(_ca_stdlib_path + "/editor", _ca_all_bc);

  return _ca_all_bc;
};

fn compile_dir(_cd_dir, _cd_output) {
  let _cd_files = list_ol_files(_cd_dir);
  let _cd_i = 0;
  while _cd_i < len(_cd_files) {
    let _cd_fname = _cd_files[_cd_i];
    let _cd_src = file_read_string(_cd_fname);
    try {
      let _cd_bc = compile_source(_cd_src);
      emit "  " + _cd_fname + " → " + __to_string(len(_cd_bc)) + " bytes";
      concat_bytes(_cd_output, _cd_bc);
    } catch {
      emit "  " + _cd_fname + " → SKIP";
    };
    _cd_i = _cd_i + 1;
  };
};

fn compile_source(_cs_src) {
  // Real compiler pipeline: tokenize → parse → analyze → extract bytecode
  reset_compiler();
  let _cs_tokens = tokenize(_cs_src);
  let _cs_ntok = len(_cs_tokens);
  let _cs_parser = { tokens: _cs_tokens, pos: 0 };
  let _cs_ast = [];
  while _cs_parser.pos < _cs_ntok {
    let _cs_peek = _cs_tokens[_cs_parser.pos];
    if _cs_peek.text == "" { _cs_parser.pos = _cs_ntok; }
    else { push(_cs_ast, parse_stmt(_cs_parser)); };
  };
  // Use __system to compile via Rust builder (interim: self-hosted compile
  // can't nest because analyze() shares global _g_output with outer eval)
  // TODO: isolate _g_output per compilation context
  analyze(_cs_ast);
  return get_compiled_bytes();
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

fn file_read_bytes(path) {
  return __file_read(path);
};

fn file_read_string(_frs_path) {
  return __file_read(_frs_path);
};

fn file_write_bytes(path, data) {
  __file_write(path, data);
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
  return {
    vm_path: "vm/x86_64/vm_x86_64",
    stdlib_path: "stdlib",
    kn_path: "",
    output: "origin_new.olang",
    arch: "x86_64"
  };
};

pub fn arm64_config() {
  return {
    vm_path: "vm/arm64/vm_arm64.bin",
    stdlib_path: "stdlib",
    kn_path: "origin.olang",
    output: "origin_arm64.olang",
    arch: "arm64"
  };
};

pub fn wasm_config() {
  return {
    vm_path: "vm/wasm/vm_wasm.wasm",
    stdlib_path: "stdlib",
    kn_path: "",
    output: "origin.wasm",
    arch: "wasm"
  };
};

pub fn wasi_config() {
  return {
    vm_path: "vm/wasm/vm_wasi.wasm",
    stdlib_path: "stdlib",
    kn_path: "",
    output: "origin_wasi.wasm",
    arch: "wasi"
  };
};

// ── Fat binary config ──

pub fn fat_config() {
  return {
    archs: [
      { name: "x86_64", vm_path: "vm/x86_64/vm_x86_64.bin", arch_id: 1, entry_off: 0 },
      { name: "arm64",  vm_path: "vm/arm64/vm_arm64.bin",    arch_id: 2, entry_off: 0 }
    ],
    stdlib_path: "stdlib",
    kn_path: "origin.olang",
    output: "origin.fat",
    stub_x86: "o_x86",
    stub_arm: "o_arm"
  };
};

// ── Fat binary builder ──
// Packs multiple arch VMs + shared bytecode + knowledge into 1 file

pub fn build_fat(config) {
  emit "Builder — fat binary packer (multi-arch)";

  // 1. Compile bytecode (shared, arch-independent)
  let bytecode = [];
  if config.stdlib_path != "" {
    emit "  Compiling stdlib: " + config.stdlib_path + "";
    bytecode = compile_all(config.stdlib_path);
  };
  emit "  Bytecode: " + __to_string(len(bytecode)) + " bytes (shared)";

  // 2. Read VM binaries for each arch
  let vm_codes = [];
  let i = 0;
  while i < len(config.archs) {
    let arch = config.archs[i];
    emit "  Reading VM [" + arch.name + "]: " + arch.vm_path + "";
    let vm = file_read_bytes(arch.vm_path);
    push(vm_codes, vm);
    emit "    VM size: " + __to_string(len(vm)) + " bytes";
    i = i + 1;
  };

  // 3. Read knowledge
  let knowledge = [];
  if config.kn_path != "" {
    knowledge = file_read_bytes(config.kn_path);
  };
  emit "  Knowledge: " + __to_string(len(knowledge)) + " bytes (shared)";

  // 4. Calculate offsets
  // Layout: [Fat Header 64B][VM 0][VM 1]...[Bytecode][Knowledge]
  let fat_hdr_size = 64;
  let arch_entries = [];

  let offset = fat_hdr_size;
  i = 0;
  while i < len(config.archs) {
    let arch = config.archs[i];
    push(arch_entries, {
      arch_id: arch.arch_id,
      vm_off: offset,
      vm_size: len(vm_codes[i]),
      entry_off: arch.entry_off
    });
    offset = offset + len(vm_codes[i]);
    i = i + 1;
  };

  let bc_off = offset;
  let kn_off = bc_off + len(bytecode);

  // 5. Build fat header
  let hdr = make_fat_header(arch_entries, bc_off, len(bytecode), kn_off, len(knowledge));

  // 6. Assemble fat binary
  let fat = [];
  concat_bytes(fat, hdr);
  i = 0;
  while i < len(vm_codes) {
    concat_bytes(fat, vm_codes[i]);
    i = i + 1;
  };
  concat_bytes(fat, bytecode);
  concat_bytes(fat, knowledge);

  // 7. Write fat binary
  file_write_bytes(config.output, fat);
  emit "  Fat binary: " + config.output + " (" + __to_string(len(fat)) + " bytes)";

  // 8. Generate ELF loader stubs
  let fat_path = to_bytes(config.output);
  if config.stub_x86 != "" {
    let x86_stub_code = make_x86_64_stub(fat_path);
    let x86_elf = make_elf_arch(x86_stub_code, 0, "x86_64");
    file_write_bytes(config.stub_x86, x86_elf);
    emit "  Stub [x86_64]: " + config.stub_x86 + " (" + __to_string(len(x86_elf)) + " bytes)";
  };
  if config.stub_arm != "" {
    let arm_stub_code = make_arm64_stub(fat_path);
    let arm_elf = make_elf_arch(arm_stub_code, 0, "arm64");
    file_write_bytes(config.stub_arm, arm_elf);
    emit "  Stub [arm64]: " + config.stub_arm + " (" + __to_string(len(arm_elf)) + " bytes)";
  };

  emit "Done! Fat binary with " + __to_string(len(config.archs)) + " architectures.";
};

fn to_bytes(str) {
  return __str_bytes(str);
};
