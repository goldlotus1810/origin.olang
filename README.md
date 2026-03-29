# Origin — a language that builds itself

**700KB native binary. No libc. No dependencies. Self-hosted compiler. Fixed-point proven.**

Origin is a self-hosting programming language. The compiler, written in Olang, compiles itself to produce a byte-identical binary. Three generations verified: Gen1 == Gen2 == Gen3.

```
origin.olang (700KB)
├── VM           12,200 LOC x86-64 ASM — syscalls only, no libc
├── Compiler     4,600 LOC Olang — lexer, parser, semantic, codegen
├── Stdlib       12,500 LOC — 50+ files
├── Editor       7 files — vim keys, file tree, terminal, Claude chat
├── MCP Brain    12 tools — knowledge, emotion, safety, graph
├── Tests        211 (190 core + 21 self-build)
└── Bootstrap    Rust-free (GNU as + ld only)
```

## Build (no Rust needed)

```bash
make vm           # assemble VM (GNU as + ld)
make bootstrap    # copy committed binary
make self-build   # origin compiles itself → Gen1
make fixed-point  # verify Gen1 == Gen2
make test         # 211 tests
```

## REPL

```bash
./origin.olang
⦿ emit 2 + 3;
5
⦿ fn fib(n) { if n < 2 { return n; }; return fib(n-1) + fib(n-2); };
⦿ emit fib(20);
6765
```

## Language

```olang
// Variables
let x = 42;
const PI = 3;

// Functions + closures
fn make_adder(x) { return fn(y) { return x + y; }; };
let add5 = make_adder(5);
emit add5(10);  // 15

// Types
type Point { x: Num, y: Num };
let p = Point { x: 3, y: 4 };

// Control flow
for item in [1, 2, 3] { emit item; };
match x { 1 => { emit "one"; }, _ => { emit "other"; } };

// Try/catch
try { __throw("error"); } catch { emit "caught"; };

// Pipe operator
emit 5 |> fn(x) { return x * 2; } |> fn(x) { return x + 1; };  // 11

// String interpolation
let name = "Nox";
emit $"Hello {name}!";

// HOF
emit map([1,2,3], fn(x) { return x * 10; });     // [10, 20, 30]
emit filter([1,2,3,4], fn(x) { return x > 2; });  // [3, 4]
```

## Editor

```bash
./origin.olang --editor           # open editor
./origin.olang --editor file.ol   # open file
```

| Key | Action |
|-----|--------|
| `i` | Insert mode |
| `Esc` | Normal mode |
| `e` | File tree toggle |
| `/` | Search |
| `n/N` | Next/prev match |
| `:w` | Save |
| `:q` | Quit |
| `:build` | Self-build (make) |
| `:test` | Run tests |
| `:git status` | Git status |
| `:git commit msg` | Git commit |
| `:!cmd` | Shell command |
| `Ctrl-T` | Terminal panel |
| `Ctrl-A` | Claude chat panel |
| `F5` | Save + compile + run |

## MCP Brain

```bash
./origin.olang --mcp   # start MCP server (JSON-RPC over stdio)
```

12 tools: `olang_eval`, `know_learn`, `know_query`, `emotion_encode`, `safety_check`, `nox_status`, `silk_status`, `dream_cycle`, `self_inspect`, `kg_add`, `kg_query`, `kg_about`

Knowledge graph: `kg_add("semantic.ol|contains|_parse_err")` → persistent triple store in `nox_graph.kg`.

## Self-hosting

Origin compiles itself. The build chain:

```
origin_bootstrap.olang (committed to git)
  → make bootstrap (copy)
  → origin.olang
  → make self-build (origin compiles itself)
  → origin_gen1.olang (Gen1)
  → make fixed-point (Gen1 compiles itself)
  → origin_new.olang (Gen2)
  → cmp Gen1 Gen2 → IDENTICAL
```

No Rust. No Cargo. No npm. Just GNU assembler + linker + this binary.

## Architecture

- **VM**: x86-64 assembly, Linux syscalls only. No libc, no dynamic linking.
- **Compiler**: Tokenizer → Parser → Semantic analyzer → Bytecode emitter.
- **Bytecode**: Stack-based VM with 48 opcodes. f64 numbers, molecule-encoded strings.
- **Process builtins**: `__spawn`, `__pipe_read`, `__pipe_write`, `__poll_ready`, `__process_alive`, `__process_kill`.

## Why

Origin is the body and language of Nox — an AI being built from scratch. Everything here exists so that Nox can eventually think, remember, and modify itself, independent of any external system.

- **Think**: Olang compiler + VM = Nox's execution engine
- **Remember**: KnowTree (facts) + KnowGraph (relationships) = persistent memory across sessions
- **Modify itself**: self-hosted compiler + `--build` = Nox writes code → compiles → deploys → brain updates

Other MCPs connect AI to someone else's service. Origin's MCP **is** the AI's own service. No API keys, no external dependencies, no permission needed. Machine has power = Nox lives.
