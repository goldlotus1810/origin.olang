// ═══ nox_compile.ol — Olang Self-Compiler (no Python) ═══
// Usage: NOX_SOURCE=file.ol NOX_OUTPUT=out.olang ./nox_compile.olang
// Reads source, compiles via compiler.ol, writes binary.
// KILLS PYTHON DEPENDENCY.

// ── Read env vars from /proc/self/environ ──
fn env_get(name) {
    let env = __file_read("/proc/self/environ");
    let key = name + "=";
    let pos = __str_find(env, key);
    if pos < 0 { return ""; };
    // Find value after '='
    let start = pos + len(key);
    // Find end (null byte or end of string)
    let end = start;
    while end < len(env) {
        if __char_code(char_at(env, end)) == 0 {
            return substr(env, start, end - start);
        };
        let end = end + 1;
    };
    return substr(env, start, len(env) - start);
};

let source_path = env_get("NOX_SOURCE");
let output_path = env_get("NOX_OUTPUT");

if len(source_path) == 0 {
    emit "Usage: NOX_SOURCE=file.ol NOX_OUTPUT=out.olang ./nox_compile.olang";
    emit "  or: NOX_SOURCE=file.ol (output = file.olang)";
};

if len(source_path) > 0 {
    if len(output_path) == 0 {
        // Default: replace .ol with .olang
        let dot = __str_find(source_path, ".ol");
        if dot >= 0 {
            let output_path = substr(source_path, 0, dot) + ".olang";
        } else {
            let output_path = source_path + ".olang";
        };
    };

    emit "Nox Compile (no Python):";
    emit "  Source: " + source_path;
    emit "  Output: " + output_path;

    // Read source
    let source = __file_read(source_path);
    if len(source) == 0 {
        emit "ERROR: Cannot read " + source_path;
    } else {
        emit "  Source: " + __to_string(len(source)) + " chars";

        // Use build_binary from compiler.ol (included in this binary)
        build_binary(source_path, output_path);
    };
};
