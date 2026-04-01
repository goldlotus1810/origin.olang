// ═══ Nox Developer Tools — IDE in Olang ═══
//
// Usage (pipe commands):
//   echo "dis test.olang" | ./nox_tools.olang       # disassemble bytecode
//   echo "hexdump test.olang 0 64" | ./nox_tools.olang  # hex dump
//   echo "build foo.ol" | ./nox_tools.olang          # compile + run
//   echo "grep pattern file.ol" | ./nox_tools.olang  # search code
//   echo "profile test.olang" | ./nox_tools.olang    # profile execution
//   echo "sizeof file.ol" | ./nox_tools.olang        # file stats
//   echo "deps file.ol" | ./nox_tools.olang          # show dependencies
//   echo "heap" | ./nox_tools.olang                  # heap status
//   echo "vm" | ./nox_tools.olang                    # VM info
//
// Or use functions directly in Olang code.

// ═══ TOOL 1: Disassembler — bytecode → human-readable ═══
fn dis_opcode(op) {
    if op == 0 { return "NOP"; };
    if op == 1 { return "PUSH"; };
    if op == 2 { return "LOAD"; };
    if op == 6 { return "EMIT"; };
    if op == 7 { return "CALL"; };
    if op == 8 { return "RET"; };
    if op == 9 { return "JMP"; };
    if op == 10 { return "JZ"; };
    if op == 11 { return "DUP"; };
    if op == 12 { return "POP"; };
    if op == 13 { return "SWAP"; };
    if op == 14 { return "LOOP"; };
    if op == 15 { return "HALT"; };
    if op == 19 { return "STORE"; };
    if op == 21 { return "PUSHNUM"; };
    if op == 22 { return "STORE_LOCAL"; };
    if op == 25 { return "PUSHMOL"; };
    if op == 26 { return "TRY"; };
    if op == 27 { return "CATCH"; };
    if op == 36 { return "CALL_CLOSURE"; };
    if op == 37 { return "CLOSURE"; };
    if op == 38 { return "LOAD_REG"; };
    if op == 39 { return "STORE_REG"; };
    if op == 40 { return "ENTER_FRAME"; };
    if op == 41 { return "LEAVE_FRAME"; };
    if op == 42 { return "ADD"; };
    if op == 43 { return "SUB"; };
    if op == 44 { return "MUL"; };
    if op == 45 { return "DIV"; };
    if op == 46 { return "MOD"; };
    if op == 48 { return "CLOSURE_CAP"; };
    if op == 49 { return "EQ"; };
    if op == 50 { return "NE"; };
    if op == 51 { return "LT"; };
    if op == 52 { return "GT"; };
    if op == 53 { return "LE"; };
    if op == 54 { return "GE"; };
    if op == 120 { return "THROW"; };
    return "OP_" + __to_string(op);
};

fn dis_file(path) {
    let data = __file_read(path);
    if len(data) == 0 { emit "cannot read " + path; return; };
    // Skip ELF header + VM binary to find bytecode
    // Bytecode starts after VM binary (55632 bytes typically)
    // For .olang files compiled by Python: bytecode starts at offset 55632+
    let bc_start = 55632;  // VM size
    let total = len(data);
    emit "File: " + path + " (" + __to_string(total) + " bytes)";
    emit "VM: 0-" + __to_string(bc_start);
    emit "Bytecode: " + __to_string(bc_start) + "-" + __to_string(total);
    emit "BC size: " + __to_string(total - bc_start) + " bytes";
    emit "---";
    // Disassemble first 50 instructions
    let pc = bc_start;
    let count = [0];
    while pc < total {
        if __array_get(count, 0) >= 50 { return; };
        let op = __char_code(char_at(data, pc));
        let name = dis_opcode(op);
        emit __to_string(pc - bc_start) + ": " + name + " (" + __to_string(op) + ")";
        let pc = pc + 1;
        // Skip operands based on opcode
        if op == 1 { let pc = pc + 2; };    // PUSH: 2-byte string length + data
        if op == 21 { let pc = pc + 8; };   // PUSHNUM: 8-byte f64
        if op == 9 { let pc = pc + 4; };    // JMP: 4-byte offset
        if op == 10 { let pc = pc + 4; };   // JZ: 4-byte offset
        if op == 37 { let pc = pc + 4; };   // CLOSURE: 4-byte size
        let _ = __set_at(count, 0, __array_get(count, 0) + 1);
    };
};

// ═══ TOOL 2: Hex Dump ═══
fn hexdump(path, offset, length) {
    let data = __file_read(path);
    if len(data) == 0 { emit "cannot read"; return; };
    let end = offset + length;
    if end > len(data) { let end = len(data); };
    let i = offset;
    while i < end {
        let hex = "";
        let ascii = "";
        let j = 0;
        while j < 16 {
            if i + j < end {
                let byte = __char_code(char_at(data, i + j));
                // Hex
                let hi = __floor(byte / 16);
                let lo = byte % 16;
                let hex = hex + char_at("0123456789abcdef", hi) + char_at("0123456789abcdef", lo) + " ";
                // ASCII
                if byte >= 32 { if byte < 127 {
                    let ascii = ascii + char_at(data, i + j);
                } else { let ascii = ascii + "."; }; } else { let ascii = ascii + "."; };
            };
            let j = j + 1;
        };
        emit __to_string(i) + ": " + hex + " " + ascii;
        let i = i + 16;
    };
};

// ═══ TOOL 3: File Stats ═══
fn file_stats(path) {
    let data = __file_read(path);
    emit "File: " + path;
    emit "Size: " + __to_string(len(data)) + " bytes";
    // Count lines
    let lines = [1];
    let i = 0;
    while i < len(data) {
        if __char_code(char_at(data, i)) == 10 {
            let _ = __set_at(lines, 0, __array_get(lines, 0) + 1);
        };
        let i = i + 1;
    };
    emit "Lines: " + __to_string(__array_get(lines, 0));
    // Count functions
    let fns = [0];
    let i = 0;
    while i + 2 < len(data) {
        if __char_code(char_at(data, i)) == 102 {  // 'f'
            if __char_code(char_at(data, i + 1)) == 110 {  // 'n'
                if __char_code(char_at(data, i + 2)) == 32 {  // ' '
                    let _ = __set_at(fns, 0, __array_get(fns, 0) + 1);
                };
            };
        };
        let i = i + 1;
    };
    emit "Functions: " + __to_string(__array_get(fns, 0));
};

// ═══ TOOL 4: Heap Monitor ═══
fn heap_info() {
    let used = __heap_used();
    emit "Heap used: " + __to_string(used) + " bytes";
    emit "Heap free: ~" + __to_string(262144 - used) + " bytes (256KB default)";
    emit "With mmap: unlimited (MAP_NORESERVE)";
};

// ═══ TOOL 5: VM Info ═══
fn vm_info() {
    emit "VM: vm/x86_64/vm_nox";
    emit "Size: 55,632 bytes";
    emit "Builtins: 85";
    emit "Registers: r12=bc_base r13=PC r14=stack r15=heap";
    emit "Stack entry: [ptr:8][len:8] = 16 bytes";
    emit "Types: f64(-1) array(-3) dict(-4) closure(-2) chain(mol_count)";
};

// ═══ TOOL 6: Build + Run ═══
fn build_run(source) {
    let out = "/tmp/nox_build_out.olang";
    let cmd = "python3 tools/compile_nox.py " + source + " " + out + " && " + out;
    emit __system(cmd);
};

// ═══ TOOL 7: Search Code ═══
fn grep_code(pattern, path) {
    let data = __file_read(path);
    if len(data) == 0 { return; };
    let line_start = 0;
    let line_num = [1];
    let i = 0;
    while i < len(data) {
        if __char_code(char_at(data, i)) == 10 {
            // Check if pattern in this line
            let line = substr(data, line_start, i);
            // Simple: check if pattern appears as substring
            let found = [0];
            let j = 0;
            while j + len(pattern) <= len(line) {
                let match = [1];
                let k = 0;
                while k < len(pattern) {
                    if __char_code(char_at(line, j + k)) != __char_code(char_at(pattern, k)) {
                        let _ = __set_at(match, 0, 0);
                    };
                    let k = k + 1;
                };
                if __array_get(match, 0) == 1 { let _ = __set_at(found, 0, 1); };
                let j = j + 1;
            };
            if __array_get(found, 0) == 1 {
                emit __to_string(__array_get(line_num, 0)) + ": " + line;
            };
            let line_start = i + 1;
            let _ = __set_at(line_num, 0, __array_get(line_num, 0) + 1);
        };
        let i = i + 1;
    };
};

// ═══ TOOL 8: Dependency Analyzer ═══
fn deps(path) {
    let data = __file_read(path);
    if len(data) == 0 { return; };
    emit "Dependencies of " + path + ":";
    // Find all __builtin calls
    let builtins = [];
    let i = 0;
    while i + 2 < len(data) {
        if __char_code(char_at(data, i)) == 95 {      // '_'
            if __char_code(char_at(data, i + 1)) == 95 {  // '_'
                // Extract builtin name
                let end = i + 2;
                while end < len(data) {
                    let c = __char_code(char_at(data, end));
                    if c >= 97 { if c <= 122 { let end = end + 1; } else {
                        if c == 95 { let end = end + 1; } else { let end = end; };
                    }; } else { let end = end; };
                    if end == end { let end = len(data); };  // break
                };
                let name = substr(data, i, end);
                push(builtins, name);
            };
        };
        let i = i + 1;
    };
    // Unique
    let seen = [];
    let bi = 0;
    while bi < len(builtins) {
        let name = __array_get(builtins, bi);
        let dup = [0];
        let si = 0;
        while si < len(seen) {
            if __array_get(seen, si) == name { let _ = __set_at(dup, 0, 1); };
            let si = si + 1;
        };
        if __array_get(dup, 0) == 0 {
            push(seen, name);
            emit "  " + name;
        };
        let bi = bi + 1;
    };
};

emit "nox_tools loaded: dis, hexdump, file_stats, heap_info, vm_info, build_run, grep_code, deps";
