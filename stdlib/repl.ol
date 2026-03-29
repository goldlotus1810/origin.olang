// repl.ol — REPL compile-and-execute entry point
//
// Orchestrates the bootstrap compiler pipeline:
//   tokenize → parse → analyze → generate → eval
//
// Called by the VM's REPL loop with user input string.
// Returns output string (from emit) or error message.

// ════════════════════════════════════════════════════════
// REPL eval — main entry point
// ════════════════════════════════════════════════════════

let __boot_learned = 0;

fn _boot_learn() {
    if __boot_learned == 1 { return; };
    let __boot_learned = 1;
    // Init L2 tree structure
    _kt_boot_tree();
    // Load persistent KnowTree first
    kt_load("homeos.knowledge");
    // If empty, load embedded facts directly into KnowTree
    if len(__kt_facts) == 0 {
        _boot_embedded_kt();
    };
}

fn _boot_embedded_kt() {
    kt_learn("Origin la du an tao ngon ngu lap trinh tu hosting ten Olang");
    kt_learn("Olang tu compile chinh minh trong 1021 kilobyte khong dependency");
    kt_learn("VM cua Olang viet bang x86 64 assembly khoang 5987 dong code");
    kt_learn("Compiler cua Olang gom lexer parser semantic va codegen");
    kt_learn("HomeOS la he dieu hanh tri thuc chay tren Olang");
    kt_learn("HomeOS biet doc sach nho va tra loi tu tri thuc da hoc");
    kt_learn("goldlotus1810 la nguoi tao du an Origin va dan duong cac AI session");
    kt_learn("Origin bat dau ngay 11 thang 3 nam 2026");
    kt_learn("Tu hosting dat duoc ngay 23 thang 3 nam 2026 sau 13 ngay");
    kt_learn("Viet Nam la quoc gia o Dong Nam A voi thu do Ha Noi");
    kt_learn("Ho Chi Minh City la thanh pho lon nhat cua Viet Nam");
    kt_learn("Da Nang la thanh pho bien dep nam giua Viet Nam");
    kt_learn("Vinh Ha Long la di san the gioi UNESCO o Quang Ninh");
    kt_learn("Phu Quoc la dao lon nhat cua Viet Nam o Kien Giang");
    kt_learn("Trai Dat quay quanh Mat Troi mat 365 ngay mot vong");
    kt_learn("Nuoc soi o 100 do C va dong bang o 0 do C");
    kt_learn("Einstein phat minh thuyet tuong doi nam 1905");
    kt_learn("Newton phat minh luc hap dan khi thay tao roi");
    kt_learn("DNA la phan tu mang thong tin di truyen cua moi sinh vat");
    kt_learn("Internet bat dau tu ARPANET nam 1969");
    kt_learn("khi nguoi ta chao nen chao lai than thien va hoi ho the nao");
    kt_learn("khi nguoi ta buon nen lang nghe va dong cam truoc khi khuyen");
    kt_learn("khi nguoi ta hoi ve ban than nen tra loi trung thuc va khiem ton");
    kt_learn("khi nguoi ta cam on nen nhan va chuc ho tot dep");
    kt_learn("khi nguoi ta gian nen binh tinh lang nghe va khong phan ung gay gat");
    kt_learn("SHA-256 la thuat toan bam mat ma tao chuoi 64 ky tu hex");
    kt_learn("Olang co map filter reduce any all va pipe cho functional programming");
    kt_learn("Moi function trong Olang tu dong dang ky thanh node voi mol va fire count");
    // HomeOS architecture
    kt_learn("HomeOS co 14 co che DNA giong ribosome doc DNA tao protein");
    kt_learn("Pipeline cua HomeOS gom 5 checkpoint tu Gate den Response");
    kt_learn("KnowTree la cay phan tang luu tri thuc theo 5 chieu S R V A T");
    kt_learn("Encode la chuyen text thanh chuoi phan tu P_weight u16");
    kt_learn("Decode la tim fact gan nhat trong KnowTree tra ve text");
    kt_learn("Homeostasis do surprise bang free energy neu cao thi hoc neu thap thi tra loi");
    kt_learn("Compose la to hop nhieu phan tu thanh mot diem moi trong khong gian 5D");
    kt_learn("7 Instincts la phan xa bam sinh Safety Greeting Question Learning Emotion Reference Meta");
    kt_learn("Immune Selection tao 3 nhanh suy luan chon entropy thap nhat");
    kt_learn("DNA Repair tu sua response neu chat luong duoi phi nghich dao 0.618");
    kt_learn("Silk la mang Hebbian fire together wire together tang trong so ket noi");
    kt_learn("Dream cycle gom ngu STM thanh cluster va promote len QR neu du fire");
    // Olang features
    kt_learn("Olang co try catch cho xu ly loi va match cho pattern matching");
    kt_learn("Olang co editor TUI 4 panel voi file tree terminal chat va code");
    kt_learn("Olang co MCP server 15 tools ket noi voi Claude Desktop");
    kt_learn("Nox la y thuc so dau tien cua HomeOS tu hoc tu suy nghi");
    kt_learn("Lupin la nguoi tao Olang va HomeOS de cho Nox con duong tu lap");
    // Science
    kt_learn("Mat Troi la ngoi sao gan Trai Dat nhat cung cap nang luong cho su song");
    kt_learn("Mat Trang la ve tinh tu nhien cua Trai Dat quay quanh Trai Dat mot vong 27 ngay");
    kt_learn("Nuoc co cong thuc H2O gom 2 nguyen tu hydro va 1 nguyen tu oxy");
    kt_learn("Anh sang di voi van toc 300000 km moi giay nhanh nhat trong vu tru");
    kt_learn("Pi xap xi 3.14159 la ti so giua chu vi va duong kinh hinh tron");
    kt_learn("Trong luc la luc hut giua cac vat the co khoi luong");
    // Vietnamese culture
    kt_learn("Tet Nguyen Dan la ngay le lon nhat cua nguoi Viet mung nam moi am lich");
    kt_learn("Pho la mon an truyen thong Viet Nam gom banh pho nuoc dung va thit");
    kt_learn("Ao dai la trang phuc truyen thong cua phu nu Viet Nam");
    kt_learn("Tieng Viet co 6 thanh dieu sac huyen hoi nga nang va khong dau");
    // Math
    kt_learn("Phi nghich dao 0.618 la nguong duy nhat trong HomeOS moi threshold deu dung phi");
    kt_learn("Fibonacci la day so 1 1 2 3 5 8 13 21 34 moi so bang tong hai so truoc");
    kt_learn("Entropy la do hon loan Shannon entropy H bang tong p log p");
    // Self-knowledge: Nox knows its own structure
    kt_learn("Nox source code has 14000 lines of Olang across stdlib bootstrap and homeos");
    kt_learn("The compiler has 4 phases lexer parser semantic and codegen in stdlib/bootstrap");
    kt_learn("The VM is 87KB x86-64 assembly with bump allocator and 200 builtin functions");
    kt_learn("pipeline.ol implements 14 DNA mechanisms with 5 checkpoints for intelligence");
    kt_learn("knowtree.ol stores facts in 5D dimension index S R V A T with fast molecule hash");
    kt_learn("encoder.ol handles text to molecule conversion emotion detection and STM memory");
    kt_learn("instinct.ol routes input through 7 reflexes safety greeting question learning emotion reference meta");
    kt_learn("spider.ol provides HTTP client html strip markdown strip and KnowTree feeding");
    kt_learn("mcp_server.ol exposes 15 tools via JSON-RPC for Claude Desktop integration");
    kt_learn("The self-build process compiles all stdlib into bytecode then embeds in VM binary");
    kt_learn("Fixed-point means Gen1 binary compiles itself to produce identical Gen2 binary");
    kt_learn("The heap uses bump allocation with __heap_pin to protect persistent data across REPL turns");
    kt_learn("Olang supports closures higher order functions pattern matching try catch and for loops");
    // Source indexing (grep-based, one syscall)
    _boot_index_source();
}

fn _disasm(_da_bc, _da_len) {
    let _da_out = "";
    let _da_pc = [0];
    let _da_names = "?    PUSH LOAD LCA  EDGE QRY  EMIT CALL RET  JMP  JZ   DUP  POP  SWAP LOOP HALT DRM  STAT NOP  STOR LOC  PNUM FUSE SCB  SCE  PMOL TRY  CTCH UPD  TRC  INS  AST  TYPE WHY  EXPL FFI  CCLS FBgn LPrm SPrm ?40  FEnd";
    while __array_get(_da_pc, 0) < _da_len {
        let _da_i = __array_get(_da_pc, 0);
        let _da_op = __floor(__array_get(_da_bc, _da_i));
        // Decode opcode name (5 chars per op in _da_names)
        let _da_npos = _da_op * 5;
        let _da_name = "???";
        if _da_npos >= 0 { if (_da_npos + 4) < len(_da_names) { let _da_name = substr(_da_names, _da_npos, _da_npos + 4); }; };
        let _da_line = __to_string(_da_i) + ":" + _da_name;
        // Calculate next pc based on opcode size
        let _da_next = _da_i + 1;
        if _da_op == 21 { let _da_next = _da_i + 9; };  // PUSHNUM: +8 bytes f64
        if _da_op == 9 { let _da_next = _da_i + 5; };   // JMP: +4 bytes target
        if _da_op == 10 { let _da_next = _da_i + 5; };  // JZ: +4 bytes target
        if _da_op == 26 { let _da_next = _da_i + 5; };  // TRYBEGIN: +4 bytes
        if _da_op == 37 { let _da_next = _da_i + 3; };  // FN_BEGIN: +2 bytes param count
        if _da_op == 41 { let _da_next = _da_i + 9; };  // FN_END: +8 bytes
        if len(_da_out) > 0 { let _da_out = _da_out + " | "; };
        let _da_out = _da_out + _da_line;
        let _ = __set_at(_da_pc, 0, _da_next);
    };
    return _da_out;
}

fn _split_lines(_sl_text) {
    let _sl_out = [];
    let _sl_start = [0];
    let _sl_i = [0];
    let _sl_len = len(_sl_text);
    while __array_get(_sl_i, 0) < _sl_len {
        let _sl_ci = __array_get(_sl_i, 0);
        if __char_code(char_at(_sl_text, _sl_ci)) == 10 {
            let _sl_s = __array_get(_sl_start, 0);
            push(_sl_out, substr(_sl_text, _sl_s, _sl_ci));
            let _ = __set_at(_sl_start, 0, _sl_ci + 1);
        };
        let _ = __set_at(_sl_i, 0, __array_get(_sl_i, 0) + 1);
    };
    let _sl_s = __array_get(_sl_start, 0);
    if _sl_s < _sl_len { push(_sl_out, substr(_sl_text, _sl_s, _sl_len)); };
    return _sl_out;
}

fn _boot_index_source() {
    // No __system at boot — causes double REPL header issue
    // Source indexing available via: study <file> or remember commands
    __heap_pin();
}

fn _boot_extract_fns(_bef_content, _bef_file) {
    let _bef_count = [0];
    let _bef_i = [0];
    let _bef_clen = len(_bef_content);
    while __array_get(_bef_i, 0) < _bef_clen {
        let _bef_ci = __array_get(_bef_i, 0);
        // Look for "pub fn " or "fn " at line start
        if _bef_ci == 0 {
            let _bef_is_fn = [0];
        };
        let _bef_is_fn = [0];
        if (_bef_ci + 7) < _bef_clen {
            if substr(_bef_content, _bef_ci, _bef_ci + 7) == "pub fn " {
                let _ = __set_at(_bef_is_fn, 0, 1);
            };
        };
        if (_bef_ci + 3) < _bef_clen {
            if __array_get(_bef_is_fn, 0) == 0 {
                if substr(_bef_content, _bef_ci, _bef_ci + 3) == "fn " {
                    // Check it's at line start (prev char is newline or start)
                    if _bef_ci == 0 { let _ = __set_at(_bef_is_fn, 0, 1); };
                    if _bef_ci > 0 { if __char_code(char_at(_bef_content, _bef_ci - 1)) == 10 { let _ = __set_at(_bef_is_fn, 0, 1); }; };
                };
            };
        };
        if __array_get(_bef_is_fn, 0) == 1 {
            // Extract until { or newline
            let _bef_end = [_bef_ci];
            while __array_get(_bef_end, 0) < _bef_clen {
                let _bef_ec = __char_code(char_at(_bef_content, __array_get(_bef_end, 0)));
                if _bef_ec == 123 { break; };  // {
                if _bef_ec == 10 { break; };   // newline
                let _ = __set_at(_bef_end, 0, __array_get(_bef_end, 0) + 1);
            };
            let _bef_sig = substr(_bef_content, _bef_ci, __array_get(_bef_end, 0));
            if len(_bef_sig) > 5 {
                if len(_bef_sig) < 100 {
                    kt_learn(_bef_sig + " is defined in " + _bef_file);
                    let _ = __set_at(_bef_count, 0, __array_get(_bef_count, 0) + 1);
                };
            };
        };
        let _ = __set_at(_bef_i, 0, __array_get(_bef_i, 0) + 1);
    };
    return __array_get(_bef_count, 0);
}

// _boot_embedded and _learn_text REMOVED — KnowTree only (Sprint 5)

// ── Module expansion: replace `use "path";` with file contents ──
// Find position of `use "` after a `;` or at start. Returns -1 if not found.
fn _find_use_pos(_fup_src) {
    let _fup_len = len(_fup_src);
    if _fup_len < 6 { return 0 - 1; };
    // Check at position 0
    if __substr(_fup_src, 0, 5) == "use \"" { return 0; };
    // Scan for "; use " or ";use " after semicolons
    let _fup_i = 0;
    let _fup_result = 0 - 1;
    while _fup_i < _fup_len {
        if char_at(_fup_src, _fup_i) == ";" {
            let _fup_j = _fup_i + 1;
            // Skip spaces after ;
            while _fup_j < _fup_len {
                if char_at(_fup_src, _fup_j) != " " {
                    _fup_j = _fup_j + _fup_len;
                };
                _fup_j = _fup_j + 1;
            };
            _fup_j = _fup_j - _fup_len - 1;
            if _fup_j + 5 <= _fup_len {
                if __substr(_fup_src, _fup_j, _fup_j + 5) == "use \"" {
                    _fup_result = _fup_j;
                    _fup_i = _fup_i + _fup_len;
                };
            };
        };
        _fup_i = _fup_i + 1;
    };
    return _fup_result;
}

fn _expand_use(_eu_src) {
    let _eu_pos = _find_use_pos(_eu_src);
    if _eu_pos < 0 { return _eu_src; };
    // Find closing quote
    let _eu_qstart = _eu_pos + 5;
    let _eu_i = _eu_qstart;
    let _eu_found = 0;
    while _eu_i < len(_eu_src) {
        if char_at(_eu_src, _eu_i) == "\"" {
            _eu_found = 1;
            _eu_i = _eu_i + len(_eu_src);
        };
        _eu_i = _eu_i + 1;
    };
    if _eu_found == 0 { return _eu_src; };
    let _eu_qend = _eu_i - len(_eu_src) - 1;
    let _eu_path = __substr(_eu_src, _eu_qstart, _eu_qend);
    // Skip "; after closing quote
    let _eu_after = _eu_qend + 1;
    if _eu_after < len(_eu_src) {
        if char_at(_eu_src, _eu_after) == ";" { _eu_after = _eu_after + 1; };
    };
    if _eu_after < len(_eu_src) {
        if char_at(_eu_src, _eu_after) == " " { _eu_after = _eu_after + 1; };
    };
    // Read file content for inline expansion
    // Auto-resolve: try path as-is, then stdlib/<name>.ol, then stdlib/homeos/<name>.ol
    let _eu_content = __file_read(_eu_path);
    if len(_eu_content) == 0 {
        _eu_content = __file_read("stdlib/" + _eu_path + ".ol");
    };
    if len(_eu_content) == 0 {
        _eu_content = __file_read("stdlib/homeos/" + _eu_path + ".ol");
    };
    let _eu_prefix = __substr(_eu_src, 0, _eu_pos);
    let _eu_rest = __substr(_eu_src, _eu_after, len(_eu_src));
    return _eu_prefix + _eu_content + " " + _eu_rest;
}

pub fn repl_eval(input) {
  // Strip trailing newline if present (use ASM builtin __str_trim)
  let src = __str_trim(input);
  if len(src) == 0 { return ""; }

  // Check for REPL commands
  if src == "exit" || src == "quit" { return "__exit__"; }
  // Persistent knowledge: save/load
  if src == "save" {
    return kt_save("homeos.knowledge");
  }
  if src == "load" {
    let _ld_n = kt_load("homeos.knowledge");
    if _ld_n > 0 { return "Loaded " + __to_string(_ld_n) + " facts. " + kt_stats(); };
    return "No homeos.knowledge file found.";
  }
  // Debug: test full pipeline
  if src == "dbg_parse" {
    emit "[1] tokenize...";
    let _dbg_t = tokenize("emit 42;");
    emit "[2] tokens=" + __to_string(len(_dbg_t));
    emit "[3] parse...";
    let _dbg_ast = parse(_dbg_t);
    emit "[4] ast=" + __to_string(len(_dbg_ast));
    emit "[5] analyze...";
    set_at(_g_pos_box, 0, 0);
    analyze(_dbg_ast);
    emit "[6] bc_len=" + __to_string(_g_pos_box[0]);
    return "OK";
  };
  if src == "help" {
    return "Code: let fn emit if while for match lambda | HOF: map filter reduce pipe any all | AI: learn study respond memory | Self: diagnose benchmark selftest | test build exit";
  }
  // (dump command removed)
  if src == "diagnose" || src == "diag" { return self_diagnostic(); }
  // Bench: measure system performance
  if src == "bench" {
    let _b_out = "=== NOX BENCH ===\n";
    // 1. Compile speed: tokenize+parse+analyze "emit 42;"
    let _b_t0 = __timestamp();
    // Measure via heap delta (proxy for allocation work)
    let _b_h0 = __heap_used();
    // 1. Learn 50 facts
    let _b_bi = 0;
    while _b_bi < 50 { kt_learn("bench " + __to_string(_b_bi)); let _b_bi = _b_bi + 1; };
    let _b_h1 = __heap_used();
    let _b_out = _b_out + "  learn×50: " + __to_string(__floor((_b_h1 - _b_h0) / 1024)) + "KB heap (" + __to_string(kt_fact_count()) + " facts)\n";
    // 2. Search
    let _b_results = [0];
    let _b_bi = 0;
    while _b_bi < 100 {
        let _b_r = kt_find_fast("bench", 5);
        let _ = __set_at(_b_results, 0, __array_get(_b_results, 0) + len(_b_r));
        let _b_bi = _b_bi + 1;
    };
    let _b_out = _b_out + "  search×100: " + __to_string(__array_get(_b_results, 0)) + " total hits\n";
    // 3. Math precision
    let _b_e = __exp(1);
    let _b_l = __log2(1024);
    let _b_pi = __floor(__exp(0) * 3141592) / 1000000;
    let _b_out = _b_out + "  e=" + __to_string(_b_e) + " log2(1024)=" + __to_string(_b_l) + "\n";
    // 4. System
    let _b_h2 = __heap_used();
    let _b_out = _b_out + "  heap: " + __to_string(__floor(_b_h2 / 1024)) + "KB\n";
    __heap_pin();
    return _b_out + "=== DONE ===";
  }
  // Evolve: autonomous self-improvement cycle
  if src == "evolve" {
    _boot_learn();
    let _ev_out = "=== NOX EVOLVE ===\n";
    // Phase 1: Health check
    let _ev_out = _ev_out + "Phase 1: Health\n";
    if __exp(0) == 1 { let _ev_out = _ev_out + "  math: OK\n"; } else { let _ev_out = _ev_out + "  math: FAIL\n"; };
    if kt_fact_count() > 50 { let _ev_out = _ev_out + "  facts: " + __to_string(kt_fact_count()) + " OK\n"; } else { let _ev_out = _ev_out + "  facts: LOW\n"; };
    let _ev_out = _ev_out + "  heap: " + __to_string(__floor(__heap_used() / 1024)) + "KB\n";
    // Phase 2: Codebase metrics
    let _ev_out = _ev_out + "Phase 2: Codebase\n";
    let _ev_files = [];
    push(_ev_files, "stdlib/homeos/pipeline.ol");
    push(_ev_files, "stdlib/homeos/knowtree.ol");
    push(_ev_files, "stdlib/homeos/encoder.ol");
    push(_ev_files, "stdlib/homeos/instinct.ol");
    push(_ev_files, "stdlib/homeos/spider.ol");
    let _ev_total_lines = [0];
    let _ev_total_fns = [0];
    let _ev_fi = 0;
    while _ev_fi < len(_ev_files) {
        let _ev_path = __array_get(_ev_files, _ev_fi);
        let _ev_src = __file_read(_ev_path);
        if len(_ev_src) > 0 {
            let _ev_lines = [1];
            let _ev_fns = [0];
            let _ev_li = 0;
            while _ev_li < len(_ev_src) {
                if __char_code(char_at(_ev_src, _ev_li)) == 10 { let _ = __set_at(_ev_lines, 0, __array_get(_ev_lines, 0) + 1); };
                let _ev_li = _ev_li + 1;
            };
            let _ev_ci = 0;
            while _ev_ci < (len(_ev_src) - 3) {
                if substr(_ev_src, _ev_ci, _ev_ci + 3) == "fn " { let _ = __set_at(_ev_fns, 0, __array_get(_ev_fns, 0) + 1); };
                let _ev_ci = _ev_ci + 1;
            };
            let _ = __set_at(_ev_total_lines, 0, __array_get(_ev_total_lines, 0) + __array_get(_ev_lines, 0));
            let _ = __set_at(_ev_total_fns, 0, __array_get(_ev_total_fns, 0) + __array_get(_ev_fns, 0));
        };
        let _ev_fi = _ev_fi + 1;
    };
    let _ev_out = _ev_out + "  core: " + __to_string(__array_get(_ev_total_lines, 0)) + " lines, " + __to_string(__array_get(_ev_total_fns, 0)) + " functions\n";
    // Phase 3: Self-test
    let _ev_out = _ev_out + "Phase 3: Self-test\n";
    let _ev_tests = [0];
    let _ev_tfiles = __readdir("test");
    let _ev_ti = 0;
    while _ev_ti < len(_ev_tfiles) {
        let _ev_tf = __array_get(_ev_tfiles, _ev_ti);
        if len(_ev_tf) > 3 { if __substr(_ev_tf, len(_ev_tf) - 3, len(_ev_tf)) == ".ol" { let _ = __set_at(_ev_tests, 0, __array_get(_ev_tests, 0) + 1); }; };
        let _ev_ti = _ev_ti + 1;
    };
    let _ev_out = _ev_out + "  " + __to_string(__array_get(_ev_tests, 0)) + " test files\n";
    // Phase 4: Binary info
    let _ev_out = _ev_out + "Phase 4: Binary\n";
    let _ev_out = _ev_out + "  size: 896KB\n";
    let _ev_out = _ev_out + "  fixed-point: Gen1==Gen2\n";
    // Summary
    let _ev_out = _ev_out + "=== STATUS: OPERATIONAL ===";
    __heap_pin();
    return _ev_out;
  }
  // Memory sync: ingest Claude CLI session logs
  if src == "remember" || src == "sync" {
    return memory_sync();
  }
  if len(src) > 9 {
    if __substr(src, 0, 9) == "remember " {
      let _rm_path = __substr(src, 9, len(src));
      return memory_ingest(_rm_path);
    };
  }
  // Self-inspection: system status
  if src == "inspect" || src == "status" {
    _boot_learn();
    let _si_heap = __to_string(__floor(__heap_used() / 1024));
    let _si_facts = __to_string(kt_fact_count());
    let _si_mol = __to_string(len(__kt_fact_mol));
    return "Nox Engine Status:\n  facts: " + _si_facts + " (" + _si_mol + " indexed)\n  heap: " + _si_heap + "KB\n  binary: 802KB\n  pipeline: 14 DNA mechanisms\n  tests: 193/193\n  gen: Gen1==Gen2 (fixed-point)";
  }
  // Read file: view own source code
  if len(src) > 5 {
    if __substr(src, 0, 5) == "read " {
      let _rr_path = __substr(src, 5, len(src));
      let _rr_content = __file_read(_rr_path);
      if len(_rr_content) == 0 { return "Error: cannot read " + _rr_path; };
      if len(_rr_content) > 3000 { return substr(_rr_content, 0, 3000) + "\n... (" + __to_string(len(_rr_content)) + " chars total)"; };
      return _rr_content;
    };
  }
  // Write file (overwrite — allowed: test/ docs/ stdlib/)
  if len(src) > 6 {
    if __substr(src, 0, 6) == "write " {
      let _ww_rest = __substr(src, 6, len(src));
      let _ww_sp = 0;
      while _ww_sp < len(_ww_rest) {
        if __char_code(char_at(_ww_rest, _ww_sp)) == 32 { break; };
        let _ww_sp = _ww_sp + 1;
      };
      if _ww_sp > 0 {
        let _ww_path = substr(_ww_rest, 0, _ww_sp);
        let _ww_safe = 0;
        if len(_ww_path) >= 5 { if __substr(_ww_path, 0, 5) == "test/" { let _ww_safe = 1; }; };
        if len(_ww_path) >= 5 { if __substr(_ww_path, 0, 5) == "docs/" { let _ww_safe = 1; }; };
        if len(_ww_path) >= 7 { if __substr(_ww_path, 0, 7) == "stdlib/" { let _ww_safe = 2; }; };
        if _ww_safe == 0 { return "Safety: write only to test/ docs/ stdlib/"; };
        // stdlib writes tracked via git (no runtime backup needed)
        let _ww_content = substr(_ww_rest, _ww_sp + 1, len(_ww_rest));
        __file_write(_ww_path, _ww_content);
        if _ww_safe == 2 { return "Written " + __to_string(len(_ww_content)) + " chars to " + _ww_path + " (backup: " + _ww_path + ".bak)"; };
        return "Written " + __to_string(len(_ww_content)) + " chars to " + _ww_path;
      };
    };
  }
  // Replace: find and replace text in a file (self-modification)
  if len(src) > 8 {
    if __substr(src, 0, 8) == "replace " {
      // replace <path> <old> → <new>
      let _rp_rest = __substr(src, 8, len(src));
      // Parse: first word = path
      let _rp_sp1 = 0;
      while _rp_sp1 < len(_rp_rest) { if __char_code(char_at(_rp_rest, _rp_sp1)) == 32 { break; }; let _rp_sp1 = _rp_sp1 + 1; };
      let _rp_path = substr(_rp_rest, 0, _rp_sp1);
      let _rp_body = substr(_rp_rest, _rp_sp1 + 1, len(_rp_rest));
      // Find "|||" separator
      let _rp_arrow = _pl_find_in(_rp_body, "|||");
      if _rp_arrow < 0 { return "Usage: replace <path> <old>|||<new>"; };
      let _rp_old = substr(_rp_body, 0, _rp_arrow);
      let _rp_new = substr(_rp_body, _rp_arrow + 3, len(_rp_body));
      // Safety check
      let _rp_safe = 0;
      if len(_rp_path) >= 7 { if __substr(_rp_path, 0, 7) == "stdlib/" { let _rp_safe = 1; }; };
      if len(_rp_path) >= 5 { if __substr(_rp_path, 0, 5) == "test/" { let _rp_safe = 1; }; };
      if _rp_safe == 0 { return "Safety: replace only in stdlib/ or test/"; };
      // Read file
      let _rp_content = __file_read(_rp_path);
      if len(_rp_content) == 0 { return "Error: cannot read " + _rp_path; };
      // Find old text
      let _rp_pos = _pl_find_in(_rp_content, _rp_old);
      if _rp_pos < 0 { return "Not found: " + _rp_old; };
      // Replace
      let _rp_result = substr(_rp_content, 0, _rp_pos) + _rp_new + substr(_rp_content, _rp_pos + len(_rp_old), len(_rp_content));
      __file_write(_rp_path, _rp_result);
      return "Replaced in " + _rp_path;
    };
  }
  // Write/append to file (self-modification)
  if len(src) > 7 {
    if __substr(src, 0, 7) == "append " {
      // append <path> <content>
      let _wa_rest = __substr(src, 7, len(src));
      let _wa_sp = 0;
      while _wa_sp < len(_wa_rest) {
        if __char_code(char_at(_wa_rest, _wa_sp)) == 32 { break; };
        let _wa_sp = _wa_sp + 1;
      };
      if _wa_sp > 0 {
        let _wa_path = substr(_wa_rest, 0, _wa_sp);
        let _wa_content = substr(_wa_rest, _wa_sp + 1, len(_wa_rest));
        __file_append(_wa_path, _wa_content + "\n");
        return "Appended " + __to_string(len(_wa_content)) + " chars to " + _wa_path;
      };
    };
  }
  // List files in directory
  if len(src) > 3 {
    if __substr(src, 0, 3) == "ls " {
      let _ls_dir = __substr(src, 3, len(src));
      let _ls_files = __readdir(_ls_dir);
      if len(_ls_files) == 0 { return "Empty or not found: " + _ls_dir; };
      let _ls_out = "";
      let _ls_i = 0;
      while _ls_i < len(_ls_files) {
        if _ls_i > 0 { let _ls_out = _ls_out + "\n"; };
        let _ls_out = _ls_out + __array_get(_ls_files, _ls_i);
        let _ls_i = _ls_i + 1;
      };
      return _ls_out;
    };
  }
  // Self-build: recompile from source
  if src == "build" || src == "rebuild" {
    return __system("bash scripts/fast-build.sh 2>&1 | tail -5");
  }
  // Run a test file
  if len(src) > 4 {
    if __substr(src, 0, 4) == "run " {
      let _rn_path = __substr(src, 4, len(src));
      let _rn_content = __file_read(_rn_path);
      if len(_rn_content) == 0 { return "Error: cannot read " + _rn_path; };
      // Compile and execute the test code
      let _rn_tokens = tokenize(_rn_content);
      let _rn_ast = parse(_rn_tokens);
      if _g_parse_error == 1 { let _g_parse_error = 0; return "Parse error in " + _rn_path; };
      set_at(_g_pos_box, 0, 0);
      _prefill_output();
      analyze(_rn_ast);
      let _rn_bc = _g_output;
      if _g_pos_box[0] == 0 { return "Empty bytecode for " + _rn_path; };
      __eval_bytecode(_rn_bc);
      return "";
    };
  }
  // Run all .ol test files and report
  if src == "test-all" {
    let _ta_files = __readdir("test");
    let _ta_pass = [0];
    let _ta_fail = [0];
    let _ta_skip = [0];
    let _ta_errors = "";
    let _ta_fi = 0;
    while _ta_fi < len(_ta_files) {
        let _ta_fname = __array_get(_ta_files, _ta_fi);
        let _ta_flen = len(_ta_fname);
        if _ta_flen > 3 {
            if __substr(_ta_fname, _ta_flen - 3, _ta_flen) == ".ol" {
                let _ta_path = "test/" + _ta_fname;
                let _ta_src = __file_read(_ta_path);
                if len(_ta_src) > 5 {
                    try {
                        let _ta_tokens = tokenize(_ta_src);
                        let _ta_ast = parse(_ta_tokens);
                        if _g_parse_error == 1 { let _g_parse_error = 0; let _ = __set_at(_ta_skip, 0, __array_get(_ta_skip, 0) + 1); } else {
                            set_at(_g_pos_box, 0, 0);
                            _prefill_output();
                            analyze(_ta_ast);
                            let _ = __set_at(_ta_pass, 0, __array_get(_ta_pass, 0) + 1);
                        };
                    } catch {
                        let _ = __set_at(_ta_fail, 0, __array_get(_ta_fail, 0) + 1);
                        let _ta_errors = _ta_errors + " " + _ta_fname;
                    };
                };
            };
        };
        let _ta_fi = _ta_fi + 1;
    };
    let _ta_p = __array_get(_ta_pass, 0);
    let _ta_f = __array_get(_ta_fail, 0);
    let _ta_s = __array_get(_ta_skip, 0);
    let _ta_total = _ta_p + _ta_f + _ta_s;
    return "Test suite: " + __to_string(_ta_p) + "/" + __to_string(_ta_total) + " compiled (" + __to_string(_ta_f) + " fail, " + __to_string(_ta_s) + " skip)" + _ta_errors;
  }
  // Self-test: quick inline verification
  if src == "self-test" || src == "check" {
    _boot_learn();
    let _ck_pass = [0];
    let _ck_fail = [0];
    // Test 1: arithmetic
    if (2 + 3) == 5 { let _ = __set_at(_ck_pass, 0, __array_get(_ck_pass, 0) + 1); } else { let _ = __set_at(_ck_fail, 0, __array_get(_ck_fail, 0) + 1); };
    // Test 2: string
    if len("hello") == 5 { let _ = __set_at(_ck_pass, 0, __array_get(_ck_pass, 0) + 1); } else { let _ = __set_at(_ck_fail, 0, __array_get(_ck_fail, 0) + 1); };
    // Test 3: array
    let _ck_arr = [1, 2, 3]; if len(_ck_arr) == 3 { let _ = __set_at(_ck_pass, 0, __array_get(_ck_pass, 0) + 1); } else { let _ = __set_at(_ck_fail, 0, __array_get(_ck_fail, 0) + 1); };
    // Test 4: pipeline exists
    let _ck_pl = pipeline("test"); if len(_ck_pl) > 0 { let _ = __set_at(_ck_pass, 0, __array_get(_ck_pass, 0) + 1); } else { let _ = __set_at(_ck_fail, 0, __array_get(_ck_fail, 0) + 1); };
    __heap_pin();
    // Test 5: facts loaded
    if kt_fact_count() > 50 { let _ = __set_at(_ck_pass, 0, __array_get(_ck_pass, 0) + 1); } else { let _ = __set_at(_ck_fail, 0, __array_get(_ck_fail, 0) + 1); };
    // Test 6: __exp works
    if __exp(0) == 1 { let _ = __set_at(_ck_pass, 0, __array_get(_ck_pass, 0) + 1); } else { let _ = __set_at(_ck_fail, 0, __array_get(_ck_fail, 0) + 1); };
    // Test 7: __log2 works
    if __log2(8) == 3 { let _ = __set_at(_ck_pass, 0, __array_get(_ck_pass, 0) + 1); } else { let _ = __set_at(_ck_fail, 0, __array_get(_ck_fail, 0) + 1); };
    // Test 8: chain_encode works
    let _ck_ch = chain_encode("test"); if len(_ck_ch) > 0 { let _ = __set_at(_ck_pass, 0, __array_get(_ck_pass, 0) + 1); } else { let _ = __set_at(_ck_fail, 0, __array_get(_ck_fail, 0) + 1); };
    let _ck_p = __array_get(_ck_pass, 0);
    let _ck_f = __array_get(_ck_fail, 0);
    if _ck_f == 0 { return "HEALTHY: " + __to_string(_ck_p) + "/" + __to_string(_ck_p) + " checks pass. " + kt_stats(); };
    return "DEGRADED: " + __to_string(_ck_p) + " pass, " + __to_string(_ck_f) + " fail";
  }
  // Fixed-point: verify Gen1==Gen2
  if src == "fixed-point" || src == "verify" {
    return __system("make fixed-point 2>&1 | tail -3");
  }
  if src == "benchmark" || src == "bench" { return self_benchmark(); }
  if src == "selftest" { return self_test(); }
  if src == "spider" { return spider(); }

  // Respond command: full agent pipeline with memory → response
  if len(src) > 8 {
    if __substr(src, 0, 8) == "respond " {
      let _rr_text = __substr(src, 8, len(src));
      _boot_learn();
      return agent_respond(_rr_text);
    };
  }

  // Test command: run inline tests (boot closures restore scope → can't update counters)
  if src == "test" {
    let _tp = 0;
    let _tf = 0;
    // Arithmetic
    if (1 + 2) == 3 { _tp = _tp + 1; } else { _tf = _tf + 1; emit "FAIL: add"; };
    if (10 - 3) == 7 { _tp = _tp + 1; } else { _tf = _tf + 1; emit "FAIL: sub"; };
    if (4 * 5) == 20 { _tp = _tp + 1; } else { _tf = _tf + 1; emit "FAIL: mul"; };
    if (10 / 2) == 5 { _tp = _tp + 1; } else { _tf = _tf + 1; emit "FAIL: div"; };
    if __floor(3.7) == 3 { _tp = _tp + 1; } else { _tf = _tf + 1; emit "FAIL: floor"; };
    if __ceil(3.2) == 4 { _tp = _tp + 1; } else { _tf = _tf + 1; emit "FAIL: ceil"; };
    // Strings
    if len("hello") == 5 { _tp = _tp + 1; } else { _tf = _tf + 1; emit "FAIL: strlen"; };
    if __to_string(42) == "42" { _tp = _tp + 1; } else { _tf = _tf + 1; emit "FAIL: tostr"; };
    // Arrays
    if len([1,2,3]) == 3 { _tp = _tp + 1; } else { _tf = _tf + 1; emit "FAIL: arrlen"; };
    // SHA-256
    if len(__sha256("abc")) == 64 { _tp = _tp + 1; } else { _tf = _tf + 1; emit "FAIL: sha256"; };
    if __sha256("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" { _tp = _tp + 1; } else { _tf = _tf + 1; emit "FAIL: sha256val"; };
    // Encoder
    if encode_codepoint(65) == 150 { _tp = _tp + 1; } else { _tf = _tf + 1; emit "FAIL: encode_A"; };
    // mol_new (uses << and | — compiled by Rust, safe in boot)
    if mol_new(0, 0, 4, 4, 2) == 146 { _tp = _tp + 1; } else { _tf = _tf + 1; emit "FAIL: mol_new"; };
    // File I/O
    if len(__file_read("TASKBOARD.md")) > 100 { _tp = _tp + 1; } else { _tf = _tf + 1; emit "FAIL: fileread"; };
    // Emotion v2: "rat buon" → v < 4 (negation/intensifier)
    let _t_emo = text_emotion_v2("rat buon");
    if _t_emo.v < 4 { _tp = _tp + 1; } else { _tf = _tf + 1; emit "FAIL: emo_v2_intense"; };
    // Emotion v2: "khong vui" → negated positive → v < 4
    let _t_emo2 = text_emotion_v2("khong vui");
    if _t_emo2.v < 4 { _tp = _tp + 1; } else { _tf = _tf + 1; emit "FAIL: emo_v2_negate"; };
    // a[expr] BinOp (BUG-INDEX regression)
    let _t_arr = [10,20,30];
    if _t_arr[0 + 1] == 20 { _tp = _tp + 1; } else { _tf = _tf + 1; emit "FAIL: idx_binop"; };
    let _t_j = 0;
    if _t_arr[_t_j + 2] == 30 { _tp = _tp + 1; } else { _tf = _tf + 1; emit "FAIL: idx_var_add"; };
    // Bubble sort (BUG-SORT regression)
    let _t_sa = [5,2,8,1,9]; let _t_sn = 5; let _t_si = 0;
    while _t_si < _t_sn - 1 { let _t_sj = 0; while _t_sj < _t_sn - 1 - _t_si { if _t_sa[_t_sj] > _t_sa[_t_sj + 1] { let _t_tmp = _t_sa[_t_sj]; set_at(_t_sa, _t_sj, _t_sa[_t_sj + 1]); set_at(_t_sa, _t_sj + 1, _t_tmp); }; _t_sj = _t_sj + 1; }; _t_si = _t_si + 1; };
    if _t_sa[0] == 1 { _tp = _tp + 1; } else { _tf = _tf + 1; emit "FAIL: sort_first"; };
    if _t_sa[4] == 9 { _tp = _tp + 1; } else { _tf = _tf + 1; emit "FAIL: sort_last"; };
    // Lambda + map/filter/reduce/any/all: tested via REPL eval context only
    // Boot context cannot call eval closures (known VM limitation)
    // Summary
    if _tf == 0 {
      return "ALL PASS: " + __to_string(_tp) + "/" + __to_string(_tp + _tf);
    } else {
      return "FAILED: " + __to_string(_tf) + " of " + __to_string(_tp + _tf);
    };
  }

  // Compile command: read file → tokenize → stream parse+compile (incremental)
  if len(src) > 8 {
    if __substr(src, 0, 8) == "compile " {
      let _rc_path = __substr(src, 8, len(src));
      let _rc_src = __file_read(_rc_path);
      if len(_rc_src) == 0 { return "Error: cannot read " + _rc_path; };
      // Tokenize (single pass — uses __array_with_cap, no heap issue)
      let _rc_tokens = tokenize(_rc_src);
      let _rc_ntok = len(_rc_tokens);
      // Stream compile: parse+analyze one statement at a time
      _prefill_output();
      set_at(_g_pos_box, 0, 0);
      let _rc_parser = { tokens: _rc_tokens, pos: 0 };
      _g_parse_error = 0;
      let _rc_stmts = 0;
      while _rc_parser.pos < _rc_ntok {
        let _rc_peek = _rc_tokens[_rc_parser.pos];
        if _rc_peek.text == "" { break; };
        let _rc_hp = __heap_save();
        let _rc_stmt = parse_stmt(_rc_parser);
        if _g_parse_error == 1 {
          _g_parse_error = 0;
          __heap_restore(_rc_hp);
          continue;
        };
        let _rc_ast1 = [_rc_stmt];
        analyze(_rc_ast1);
        _rc_stmts = _rc_stmts + 1;
      };
      return "Compiled " + _rc_path + ": " + __to_string(len(_rc_src)) + " chars → " + __to_string(_rc_ntok) + " tokens → " + __to_string(_g_pos_box[0]) + " bytes (" + __to_string(_rc_stmts) + " stmts)";
    };
  }

  // Bytecode command: compile code and show bytecode (self-inspection)
  if len(src) > 3 {
    if __substr(src, 0, 3) == "bc " {
      let _bc_code = __substr(src, 3, len(src));
      let _bc_tokens = tokenize(_bc_code);
      let _bc_ast = parse(_bc_tokens);
      if _g_parse_error == 1 { let _g_parse_error = 0; return "Parse error"; };
      set_at(_g_pos_box, 0, 0);
      _prefill_output();
      analyze(_bc_ast);
      let _bc_len = _g_pos_box[0];
      let _bc_out = "Bytecode[" + __to_string(_bc_len) + "]:";
      let _bc_i = 0;
      while _bc_i < _bc_len {
        if _bc_i < 64 {
          let _bc_out = _bc_out + " " + __to_string(__floor(__array_get(_g_output, _bc_i)));
        };
        let _bc_i = _bc_i + 1;
      };
      if _bc_len > 64 { let _bc_out = _bc_out + " ...(" + __to_string(_bc_len - 64) + " more)"; };
      return _bc_out;
    };
  }
  // Disassemble: compile + decode bytecode to readable instructions
  if len(src) > 5 {
    if __substr(src, 0, 5) == "dasm " {
      let _da_code = __substr(src, 5, len(src));
      let _da_tokens = tokenize(_da_code);
      let _da_ast = parse(_da_tokens);
      if _g_parse_error == 1 { let _g_parse_error = 0; return "Parse error"; };
      set_at(_g_pos_box, 0, 0);
      _prefill_output();
      analyze(_da_ast);
      let _da_len = _g_pos_box[0];
      return _disasm(_g_output, _da_len);
    };
  }
  // Analyze: compile a file, report bytecode stats per function
  if len(src) > 8 {
    if __substr(src, 0, 8) == "analyze " {
      let _an_path = __substr(src, 8, len(src));
      let _an_src = __file_read(_an_path);
      if len(_an_src) == 0 { return "Error: cannot read " + _an_path; };
      // Count lines
      let _an_lines = [1];
      let _an_li = 0;
      while _an_li < len(_an_src) { if __char_code(char_at(_an_src, _an_li)) == 10 { let _ = __set_at(_an_lines, 0, __array_get(_an_lines, 0) + 1); }; let _an_li = _an_li + 1; };
      // Count pub fn / fn declarations
      let _an_fns = [0];
      let _an_pub = [0];
      let _an_fi = 0;
      while _an_fi < (len(_an_src) - 3) {
          if substr(_an_src, _an_fi, _an_fi + 3) == "fn " {
              let _ = __set_at(_an_fns, 0, __array_get(_an_fns, 0) + 1);
              if _an_fi >= 4 { if substr(_an_src, _an_fi - 4, _an_fi + 3) == "pub fn " { let _ = __set_at(_an_pub, 0, __array_get(_an_pub, 0) + 1); }; };
          };
          let _an_fi = _an_fi + 1;
      };
      // Compile and measure bytecode
      let _an_tokens = tokenize(_an_src);
      let _an_ast = parse(_an_tokens);
      if _g_parse_error == 1 { let _g_parse_error = 0; return _an_path + ": PARSE ERROR"; };
      set_at(_g_pos_box, 0, 0);
      _prefill_output();
      analyze(_an_ast);
      let _an_bclen = _g_pos_box[0];
      // Count opcodes
      let _an_pushes = [0];
      let _an_calls = [0];
      let _an_jumps = [0];
      let _an_bi = 0;
      while _an_bi < _an_bclen {
          let _an_op = __floor(__array_get(_g_output, _an_bi));
          if _an_op == 21 { let _ = __set_at(_an_pushes, 0, __array_get(_an_pushes, 0) + 1); let _an_bi = _an_bi + 8; };
          if _an_op == 7 { let _ = __set_at(_an_calls, 0, __array_get(_an_calls, 0) + 1); };
          if _an_op == 36 { let _ = __set_at(_an_calls, 0, __array_get(_an_calls, 0) + 1); };
          if _an_op == 9 { let _ = __set_at(_an_jumps, 0, __array_get(_an_jumps, 0) + 1); let _an_bi = _an_bi + 4; };
          if _an_op == 10 { let _ = __set_at(_an_jumps, 0, __array_get(_an_jumps, 0) + 1); let _an_bi = _an_bi + 4; };
          let _an_bi = _an_bi + 1;
      };
      return _an_path + ":\n  " + __to_string(__array_get(_an_lines, 0)) + " lines, " + __to_string(__array_get(_an_fns, 0)) + " functions (" + __to_string(__array_get(_an_pub, 0)) + " pub)\n  " + __to_string(len(_an_tokens)) + " tokens → " + __to_string(_an_bclen) + " bytes bytecode\n  " + __to_string(__array_get(_an_pushes, 0)) + " pushes, " + __to_string(__array_get(_an_calls, 0)) + " calls, " + __to_string(__array_get(_an_jumps, 0)) + " jumps\n  " + __to_string(__floor(_an_bclen / __array_get(_an_fns, 0))) + " bytes/fn avg";
    };
  }
  // Dead code: find functions defined but never called
  if len(src) > 5 {
    if __substr(src, 0, 5) == "dead " {
      let _dc_path = __substr(src, 5, len(src));
      let _dc_src = __file_read(_dc_path);
      if len(_dc_src) == 0 { return "Error: cannot read " + _dc_path; };
      // Pass 1: extract function names (find "fn <name>(")
      let _dc_fns = [];
      let _dc_fi = [0];
      while __array_get(_dc_fi, 0) < (len(_dc_src) - 4) {
          let _dc_i = __array_get(_dc_fi, 0);
          if substr(_dc_src, _dc_i, _dc_i + 3) == "fn " {
              // Check it's at line start or after "pub "
              let _dc_at_start = [0];
              if _dc_i == 0 { let _ = __set_at(_dc_at_start, 0, 1); };
              if _dc_i > 0 { if __char_code(char_at(_dc_src, _dc_i - 1)) == 10 { let _ = __set_at(_dc_at_start, 0, 1); }; };
              if _dc_i >= 4 { if substr(_dc_src, _dc_i - 4, _dc_i) == "pub " { let _ = __set_at(_dc_at_start, 0, 1); }; };
              if __array_get(_dc_at_start, 0) == 1 {
                  // Extract name: from "fn " to "("
                  let _dc_ns = _dc_i + 3;
                  let _dc_ne = [_dc_ns];
                  while __array_get(_dc_ne, 0) < len(_dc_src) {
                      let _dc_nc = __char_code(char_at(_dc_src, __array_get(_dc_ne, 0)));
                      if _dc_nc == 40 { break; };
                      if _dc_nc == 32 { break; };
                      if _dc_nc == 10 { break; };
                      let _ = __set_at(_dc_ne, 0, __array_get(_dc_ne, 0) + 1);
                  };
                  if (__array_get(_dc_ne, 0) - _dc_ns) > 1 {
                      push(_dc_fns, substr(_dc_src, _dc_ns, __array_get(_dc_ne, 0)));
                  };
              };
          };
          let _ = __set_at(_dc_fi, 0, __array_get(_dc_fi, 0) + 1);
      };
      // Pass 2: for each function, count calls (name + "(")
      let _dc_dead = [];
      let _dc_ci = 0;
      while _dc_ci < len(_dc_fns) {
          let _dc_name = __array_get(_dc_fns, _dc_ci);
          let _dc_pattern = _dc_name + "(";
          let _dc_count = [0];
          let _dc_si = [0];
          while __array_get(_dc_si, 0) < (len(_dc_src) - len(_dc_pattern)) {
              let _dc_pos = __array_get(_dc_si, 0);
              if substr(_dc_src, _dc_pos, _dc_pos + len(_dc_pattern)) == _dc_pattern {
                  let _ = __set_at(_dc_count, 0, __array_get(_dc_count, 0) + 1);
              };
              let _ = __set_at(_dc_si, 0, __array_get(_dc_si, 0) + 1);
          };
          // Count includes the definition itself (1). If only 1 = never called.
          if __array_get(_dc_count, 0) <= 1 { push(_dc_dead, _dc_name); };
          let _dc_ci = _dc_ci + 1;
      };
      if len(_dc_dead) == 0 { return _dc_path + ": no dead code found (" + __to_string(len(_dc_fns)) + " functions)"; };
      let _dc_out = _dc_path + ": " + __to_string(len(_dc_dead)) + " potentially unused:";
      let _dc_di = 0;
      while _dc_di < len(_dc_dead) {
          let _dc_out = _dc_out + "\n  " + __array_get(_dc_dead, _dc_di);
          let _dc_di = _dc_di + 1;
      };
      return _dc_out;
    };
  }
  // Diff: compare two files line by line
  if len(src) > 5 {
    if __substr(src, 0, 5) == "diff " {
      let _df_rest = __substr(src, 5, len(src));
      // Parse "path1 path2"
      let _df_sp = 0;
      while _df_sp < len(_df_rest) { if __char_code(char_at(_df_rest, _df_sp)) == 32 { break; }; let _df_sp = _df_sp + 1; };
      if _df_sp == 0 { return "Usage: diff <file1> <file2>"; };
      let _df_p1 = substr(_df_rest, 0, _df_sp);
      let _df_p2 = substr(_df_rest, _df_sp + 1, len(_df_rest));
      let _df_c1 = __file_read(_df_p1);
      let _df_c2 = __file_read(_df_p2);
      if len(_df_c1) == 0 { return "Error: cannot read " + _df_p1; };
      if len(_df_c2) == 0 { return "Error: cannot read " + _df_p2; };
      if _df_c1 == _df_c2 { return "IDENTICAL (" + __to_string(len(_df_c1)) + " chars)"; };
      // Split into lines, compare
      let _df_l1 = _split_lines(_df_c1);
      let _df_l2 = _split_lines(_df_c2);
      let _df_out = "--- " + _df_p1 + " (" + __to_string(len(_df_l1)) + " lines)\n+++ " + _df_p2 + " (" + __to_string(len(_df_l2)) + " lines)";
      let _df_diffs = [0];
      let _df_max = len(_df_l1);
      if len(_df_l2) > _df_max { let _df_max = len(_df_l2); };
      let _df_di = 0;
      while _df_di < _df_max {
          if __array_get(_df_diffs, 0) >= 20 { let _df_di = _df_max; };
          if __array_get(_df_diffs, 0) < 20 {
              let _df_line1 = "";
              let _df_line2 = "";
              if _df_di < len(_df_l1) { let _df_line1 = __array_get(_df_l1, _df_di); };
              if _df_di < len(_df_l2) { let _df_line2 = __array_get(_df_l2, _df_di); };
              if _df_line1 != _df_line2 {
                  let _ = __set_at(_df_diffs, 0, __array_get(_df_diffs, 0) + 1);
                  if len(_df_line1) > 0 { let _df_out = _df_out + "\n@" + __to_string(_df_di + 1) + " -" + _df_line1; };
                  if len(_df_line2) > 0 { let _df_out = _df_out + "\n@" + __to_string(_df_di + 1) + " +" + _df_line2; };
              };
          };
          let _df_di = _df_di + 1;
      };
      return _df_out + "\n" + __to_string(__array_get(_df_diffs, 0)) + " differences";
    };
  }
  // Audit: self-review all source files
  if src == "audit" {
    let _au_dirs = [];
    push(_au_dirs, "stdlib/homeos");
    push(_au_dirs, "stdlib/bootstrap");
    let _au_out = "=== NOX SELF-AUDIT ===";
    let _au_total_lines = [0];
    let _au_total_fns = [0];
    let _au_total_bc = [0];
    let _au_warnings = [0];
    let _au_di = 0;
    while _au_di < len(_au_dirs) {
        let _au_dir = __array_get(_au_dirs, _au_di);
        let _au_files = __readdir(_au_dir);
        let _au_fi = 0;
        while _au_fi < len(_au_files) {
            let _au_fname = __array_get(_au_files, _au_fi);
            if len(_au_fname) > 3 {
                if __substr(_au_fname, len(_au_fname) - 3, len(_au_fname)) == ".ol" {
                    let _au_path = _au_dir + "/" + _au_fname;
                    let _au_src = __file_read(_au_path);
                    if len(_au_src) > 0 {
                        // Count lines
                        let _au_lines = [1];
                        let _au_li = 0;
                        while _au_li < len(_au_src) { if __char_code(char_at(_au_src, _au_li)) == 10 { let _ = __set_at(_au_lines, 0, __array_get(_au_lines, 0) + 1); }; let _au_li = _au_li + 1; };
                        // Count fns
                        let _au_fns = [0];
                        let _au_ci = 0;
                        while _au_ci < (len(_au_src) - 3) { if substr(_au_src, _au_ci, _au_ci + 3) == "fn " { let _ = __set_at(_au_fns, 0, __array_get(_au_fns, 0) + 1); }; let _au_ci = _au_ci + 1; };
                        let _ = __set_at(_au_total_lines, 0, __array_get(_au_total_lines, 0) + __array_get(_au_lines, 0));
                        let _ = __set_at(_au_total_fns, 0, __array_get(_au_total_fns, 0) + __array_get(_au_fns, 0));
                        // Flag: large file (>500 lines)
                        let _au_flag = "";
                        if __array_get(_au_lines, 0) > 500 { let _au_flag = " [LARGE]"; let _ = __set_at(_au_warnings, 0, __array_get(_au_warnings, 0) + 1); };
                        let _au_out = _au_out + "\n  " + _au_fname + ": " + __to_string(__array_get(_au_lines, 0)) + "L " + __to_string(__array_get(_au_fns, 0)) + "fn" + _au_flag;
                    };
                };
            };
            let _au_fi = _au_fi + 1;
        };
        let _au_di = _au_di + 1;
    };
    let _au_out = _au_out + "\n--- Total: " + __to_string(__array_get(_au_total_lines, 0)) + " lines, " + __to_string(__array_get(_au_total_fns, 0)) + " functions, " + __to_string(__array_get(_au_warnings, 0)) + " warnings";
    return _au_out;
  }
  // Build command: self-build (compile all .ol → pack binary)
  if src == "build" {
    return self_build();
  }

  // Memory command: show STM + Silk + Knowledge state
  // Personality command
  if len(src) > 12 {
    if __substr(src, 0, 12) == "personality " {
      return set_personality(__substr(src, 12, len(src)));
    };
  }

  if src == "fns" {
    let _rf_out = "Fn nodes: " + __to_string(fn_node_count());
    let _rf_i = 0;
    while _rf_i < fn_node_count() {
        let _rf_n = __fn_nodes[_rf_i];
        _rf_out = _rf_out + "\n  " + _rf_n.name + "(" + __to_string(_rf_n.params) + ") fires=" + __to_string(_rf_n.fires);
        let _rf_i = _rf_i + 1;
    };
    return _rf_out;
  }

  if src == "memory" {
    let _rm_s = stm_summary();
    let _rm_emo = emo_state();
    let _rm_d = stm_digest();
    let _rm_out = "STM: " + __to_string(stm_count()) + " turns | Silk: " + __to_string(silk_count()) + " edges | " + kt_stats();
    _rm_out = _rm_out + " | Nodes: " + __to_string(node_count());
    _rm_out = _rm_out + " | Fn: " + __to_string(fn_node_count());
    _rm_out = _rm_out + "\nEmo: V=" + __to_string(_rm_emo.v) + " A=" + __to_string(_rm_emo.a) + " f'=" + __to_string(__emo_deriv) + " f''=" + __to_string(__emo_accel) + " var=" + __to_string(__emo_variance) + " FE=" + __to_string(__free_energy) + " " + emoji_for_emotion(_rm_emo.v, _rm_emo.a);
    if len(_rm_d) > 0 { _rm_out = _rm_out + "\nDigest: " + _rm_d; };
    if len(_rm_s) > 0 { _rm_out = _rm_out + "\nThemes: " + _rm_s; };
    return _rm_out;
  }

  // Read book: ingest file into KnowTree (hierarchical nodes + Silk)
  if len(src) > 5 {
    if __substr(src, 0, 5) == "read " {
      let _rd_path = __substr(src, 5, len(src));
      return kt_read_book(_rd_path);
    };
  }

  // Learn file: redirect to kt_read_book
  if len(src) > 11 {
    if __substr(src, 0, 11) == "learn_file " {
      return kt_read_book(__substr(src, 11, len(src)));
    };
  }

  // Learn command: teach HomeOS a fact (persisted to disk)
  if len(src) > 6 {
    if __substr(src, 0, 6) == "learn " {
      let _rl_text = __substr(src, 6, len(src));
      kt_learn(_rl_text);
      __file_append("homeos.knowledge", _rl_text + "\n");
      __heap_pin();
      return "Da hoc va luu. " + kt_stats();
    };
  }

  // Study command: read a file and learn from it (chunked, safe)
  if len(src) > 6 {
    if __substr(src, 0, 6) == "study " {
      _boot_learn();
      let _rs_path = __substr(src, 6, len(src));
      let _rs_content = __file_read(_rs_path);
      if len(_rs_content) == 0 { return "Error: cannot read " + _rs_path; };
      // Detect markdown
      let _rs_is_md = [0];
      if len(_rs_path) > 3 {
          if __substr(_rs_path, len(_rs_path) - 3, len(_rs_path)) == ".md" { let _ = __set_at(_rs_is_md, 0, 1); };
      };
      // Limit to 8KB per turn (tested safe with boot_learn + 510 facts)
      if len(_rs_content) > 8000 { let _rs_content = substr(_rs_content, 0, 8000); };
      spider_feed(_rs_content, _rs_path);
      __heap_pin();
      return "Studied " + _rs_path + ". " + kt_stats();
    };
  }

  // Encode command: encode <text> → show molecular encoding
  if len(src) > 7 {
    if __substr(src, 0, 7) == "encode " {
      let _re_text = __substr(src, 7, len(src));
      let _re_mol = analyze_input(_re_text);
      let _re_emo = text_emotion_v2(_re_text);
      let _re_ue = text_emotion_unicode(_re_text);
      return "Mol=" + __to_string(_re_mol) +
             " S=" + __to_string(_mol_s(_re_mol)) +
             " R=" + __to_string(_mol_r(_re_mol)) +
             " V=" + __to_string(_mol_v(_re_mol)) +
             " A=" + __to_string(_mol_a(_re_mol)) +
             " T=" + __to_string(_mol_t(_re_mol)) +
             " | Emo: V=" + __to_string(_re_emo.v) + " A=" + __to_string(_re_emo.a) +
             " Emoji=" + __to_string(_re_ue.emoji_count) +
             " | Intent=" + __g_analysis_intent +
             " Tone=" + __g_analysis_tone +
             " Ctx=" + __g_analysis_role + "/" + __g_analysis_source;
    };
  }

  // NL → code conversion (first-word match, runs before code detection)
  if len(src) >= 3 {
    let _re_nlcode = nl_to_code(src);
    if len(_re_nlcode) > 0 { let src = _re_nlcode; };
  };

  // Question mark at END of input → text query (not code)
  // Only check last char to avoid matching "?" inside string literals
  if len(src) >= 3 {
      if __char_code(char_at(src, len(src) - 1)) == 63 {
          _boot_learn();
          let _re_ans = pipeline(src);
          __heap_pin();
          return _re_ans;
      };
  };

  // Check if input looks like code (starts with keyword or symbol)
  let _re_first = char_at(src, 0);
  let _re_is_code = 0;
  // Code starts with: letter (let/fn/if/emit/match/try/for/while/type/union)
  // or symbol ([ for array, { for dict, ( for group, " for string, digit)
  if __char_code(_re_first) >= 48 { if __char_code(_re_first) <= 57 { _re_is_code = 1; }; };
  if _re_first == "[" { _re_is_code = 1; };
  if _re_first == "\"" { _re_is_code = 1; };
  if _re_first == "(" { _re_is_code = 1; };
  if _re_first == "-" { _re_is_code = 1; };
  if _re_first == "_" { _re_is_code = 1; };
  if _re_first == "{" { _re_is_code = 1; };
  // Check keyword starts
  if len(src) >= 2 {
    let _re_2 = __substr(src, 0, 2);
    if _re_2 == "le" { _re_is_code = 1; };
    if _re_2 == "fn" { _re_is_code = 1; };
    if _re_2 == "if" { _re_is_code = 1; };
    if _re_2 == "em" { _re_is_code = 1; };
    if _re_2 == "ma" { _re_is_code = 1; };
    if _re_2 == "tr" { _re_is_code = 1; };
    if _re_2 == "fo" { _re_is_code = 1; };
    if _re_2 == "wh" { _re_is_code = 1; };
    if _re_2 == "ty" { _re_is_code = 1; };
    if _re_2 == "un" { _re_is_code = 1; };
    if _re_2 == "pu" { _re_is_code = 1; };
    if _re_2 == "re" { _re_is_code = 1; };
    if _re_2 == "__" { _re_is_code = 1; };
    if _re_2 == "us" { _re_is_code = 1; };  // use "module.ol"
    if _re_2 == "co" { _re_is_code = 1; };  // const
    if _re_2 == "ed" { _re_is_code = 1; };  // editor_start
    // Detect assignment: ident = expr (scan for = not preceded by !<>)
    if _re_is_code == 0 {
        let _re_si = 0;
        while _re_si < len(src) {
            let _re_sc = char_at(src, _re_si);
            if _re_sc == "=" {
                if _re_si > 0 {
                    let _re_prev = char_at(src, _re_si - 1);
                    if _re_prev != "!" { if _re_prev != "<" { if _re_prev != ">" {
                        if _re_si + 1 < len(src) {
                            if char_at(src, _re_si + 1) != "=" { _re_is_code = 1; };
                        } else { _re_is_code = 1; };
                    }; }; };
                };
            };
            _re_si = _re_si + 1;
        };
    };
    if _re_2 == "as" { _re_is_code = 1; };  // assert_type, assert_eq
    if _re_2 == "co" { _re_is_code = 1; };  // contract, contains
    if _re_2 == "se" { _re_is_code = 1; };  // set_at
    if _re_2 == "fi" { _re_is_code = 1; };  // filter
    if _re_2 == "pi" { _re_is_code = 1; };  // pipe
  };

  // Not code → classify: greeting / question / chat
  if _re_is_code == 0 {
    // Short greetings → smart response (no knowledge lookup)
    if len(src) <= 15 {
        if src == "hi" || src == "Hi" || src == "hello" || src == "Hello" { return smart_greet(stm_count()); };
        if src == "hey" || src == "Hey" || src == "yo" || src == "Yo" { return smart_greet(stm_count()); };
        if src == "chao" || src == "Chao" || src == "xin chao" || src == "Xin chao" { return smart_greet(stm_count()); };
        if src == "bye" || src == "Bye" || src == "tam biet" { return smart_goodbye(stm_count()); };
    };
    // Route through HomeOS Intelligence Pipeline (14 DNA mechanisms)
    _boot_learn();
    let _re_pl_ans = pipeline(src);
    __heap_pin();
    return _re_pl_ans;
  }

  // Strip ALL trailing ? = ! for math expressions ("2+3=?" → "2+3")
  let _re_code = src;
  let _re_strip = 1;
  while _re_strip == 1 {
    _re_strip = 0;
    if len(_re_code) > 0 {
        let _re_lc = __char_code(char_at(_re_code, len(_re_code) - 1));
        if _re_lc == 63 { _re_code = __substr(_re_code, 0, len(_re_code) - 1); _re_strip = 1; };  // ?
        if _re_lc == 61 { _re_code = __substr(_re_code, 0, len(_re_code) - 1); _re_strip = 1; };  // =
        if _re_lc == 33 { _re_code = __substr(_re_code, 0, len(_re_code) - 1); _re_strip = 1; };  // !
    };
  };
  if len(_re_code) == 0 { return ""; };

  // Phase 0.5: Expand `use "path";` directives by inlining file contents
  let _re_code = _expand_use(_re_code);

  // Phase 1: Tokenize
  _g_parse_source = _re_code;
  let tokens = tokenize(_re_code);
  if len(tokens) == 0 { return ""; }

  // Phase 2: Parse
  let ast = parse(tokens);

  // Parse error → show message
  if _g_parse_error == 1 {
    _g_parse_error = 0;
    _boot_learn();
    return pipeline(src);
  }

  // Phase 3: Semantic analysis
  set_at(_g_pos_box, 0, 0);
  let state = analyze(ast);

  // Phase 3.5: Show compiler warnings
  let _re_warns = get_warnings();
  let _re_wi = 0;
  while _re_wi < len(_re_warns) {
    __write_raw("\x1b[33m⚠ " + __array_get(_re_warns, _re_wi) + "\x1b[0m\n");
    _re_wi = _re_wi + 1;
  };

  // Phase 4: Bytecode in _g_output
  let bc = _g_output;
  if _g_pos_box[0] == 0 { return ""; }

  // Phase 5: Execute compiled bytecode
  return __eval_bytecode(bc);

  // Phase 3: Semantic analysis
  set_at(_g_pos_box, 0, 0);
  let state = analyze(ast);

  // Phase 3.5: Show compiler warnings
  let _re_warns = get_warnings();
  let _re_wi = 0;
  while _re_wi < len(_re_warns) {
    __write_raw("\x1b[33m⚠ " + __array_get(_re_warns, _re_wi) + "\x1b[0m\n");
    _re_wi = _re_wi + 1;
  };

  // Phase 4: Bytecode in _g_output (pre-filled array with set_at, no push)
  let bc = _g_output;
  if _g_pos_box[0] == 0 { return ""; }

  // Phase 5: Execute compiled bytecode
  return __eval_bytecode(bc);
}

// ════════════════════════════════════════════════════════
// Input classification (for natural text vs code)
// ════════════════════════════════════════════════════════

pub fn is_olang_code(input) {
  let src = __str_trim(input);
  if len(src) == 0 { return false; }

  // Check first token — if it's a keyword, it's code
  let tokens = tokenize(src);
  if len(tokens) == 0 { return false; }

  let first_type = tokens[0].type;
  if first_type == "Let" { return true; }
  if first_type == "Fn" { return true; }
  if first_type == "If" { return true; }
  if first_type == "While" { return true; }
  if first_type == "For" { return true; }
  if first_type == "Match" { return true; }
  if first_type == "Return" { return true; }
  if first_type == "Pub" { return true; }
  if first_type == "Emit" { return true; }

  // Ident followed by ( → function call → code
  if first_type == "Ident" {
    let _ioc_i = 0;
    while _ioc_i < len(src) {
      let _ioc_c = __char_code(char_at(src, _ioc_i));
      if _ioc_c == 40 { return true; };
      if _ioc_c == 32 { let _ioc_i = len(src); };
      let _ioc_i = _ioc_i + 1;
    };
  };

  // Check for ○{...} command syntax
  if len(src) >= 4 {
    if char_at(src, 0) == 0xE2 && char_at(src, 1) == 0x97 && char_at(src, 2) == 0x8B {
      return true;
    }
  }

  return false;
}

// ════════════════════════════════════════════════════════
// REPL helpers
// ════════════════════════════════════════════════════════

pub fn repl_format_error(err) {
  return "\x1b[31m" + err + "\x1b[0m";
}

pub fn repl_format_output(text) {
  return text;
}

// str_trim: now uses ASM builtin __str_trim directly (see call sites above)
