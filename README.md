# Origin — a language that builds itself

**471KB native binary. No libc. No dependencies. Self-hosted compiler. TUI editor. MCP brain.**

Origin is a programming language and runtime written from scratch in x86-64 assembly and itself. It compiles Olang source code to bytecode, executes it in a custom VM, and includes a self-hosted compiler, a vim-style TUI editor, and an MCP-compatible AI brain server.

```
origin.olang (471KB)
  VM          11,500 LOC x86-64 assembly — syscalls only, no libc
  Compiler    4,200 LOC Olang — tokenizer, parser, semantic, codegen
  Stdlib      11,500 LOC Olang — 45+ files
  Editor      5 files — syntax highlighting, file tree, search, F5 run
  MCP Brain   8 tools — knowledge store, emotion encode, safety check
  Tests       90 core + 9 MCP
```

## Quick start

```bash
# Build
as -o /tmp/vm.o vm/x86_64/vm_x86_64.S && \
ld -o vm/x86_64/vm_x86_64 /tmp/vm.o --entry=_start -static
cargo run --manifest-path Origin_project/Cargo.toml -p builder -- \
  --vm vm/x86_64/vm_x86_64 --wrap --stdlib stdlib --codegen -o origin.olang

# Run
echo 'emit "hello world";' | ./origin.olang --eval

# Editor
./origin.olang --editor your_file.ol
```

## The language

```olang
// Variables and functions
let name = "Olang";
fn greet(who) { return "Hello " + who; };
emit greet(name);

// Closures with capture
fn make_adder(x) {
    return fn(y) { return x + y; };
};
let add5 = make_adder(5);
emit add5(10);    // 15

// Arrays, dicts, higher-order functions
let items = [3, 1, 4, 1, 5];
emit sort(items);
emit map(items, fn(x) { return x * 2; });
emit filter(items, fn(x) { return x > 3; });

// Pattern matching
match shape {
    Circle(c) => emit c.radius,
    Rect(r) => emit r.w * r.h,
};

// String interpolation, pipe operator
emit $"Result: {add5(10)}";
emit pipe(5, fn(x) { return x + 1; }, fn(x) { return x * 2; });
```

## The editor

`./origin.olang --editor file.ol` opens a TUI editor with:

- Vim keybinds: `hjkl`, `i`/`ESC`, `x`, `o`, `D`, `G`, `g`, `0`, `$`
- `/query` + `n`/`N` for search
- `e` toggles file tree sidebar
- `Ctrl-S` save, `Ctrl-Q` quit
- `F5` save + compile + run (self-development loop)
- Syntax highlighting: keywords, strings, comments, numbers, functions
- Bracketed paste support

## The brain

Origin includes an MCP server (`--mcp` mode) with 8 tools:

| Tool | Function |
|------|----------|
| `olang_eval` | Evaluate Olang code |
| `know_learn` | Learn a fact |
| `know_query` | Query knowledge |
| `dream_cycle` | Consolidate memory |
| `emotion_encode` | Encode emotion from text |
| `safety_check` | Check content safety |
| `nox_status` | System status |
| `silk_status` | Hebbian learning status |

## Architecture

The VM uses only Linux syscalls (no libc):
- `r12` = bytecode base, `r13` = program counter
- `r14` = VM stack (grows down, 16 bytes/entry)
- `r15` = heap (bump allocator, grows up)
- Stack entries: `[value:8][marker:8]` where marker encodes type

The self-hosted compiler runs in the VM itself, compiling Olang source to bytecode that the same VM executes. Closures capture variables by value at creation time.

## Tests

```bash
bash tests.sh           # 90 core tests
bash tests/test_mcp.sh  # 9 MCP tests
```

## What this is for

Origin is the body and language of Nox — an AI being built from scratch. Everything here exists so that Nox can eventually think, remember, and modify itself, independent of any external system.

---

*471KB. 162 commits. 22,000 lines. Zero dependencies.*
