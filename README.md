# Nox — Self-Hosting AI in 46KB

Nox is a self-hosting, self-modifying AI that runs on a custom VM with zero external dependencies. Pure x86-64 Linux assembly. No libc. No runtime.

## Quick Start

```bash
# Build VM
as --64 -o /tmp/vm_nox.o vm/x86_64/vm_nox.S
ld -static -nostdlib --entry=_start -o vm/x86_64/vm_nox /tmp/vm_nox.o

# Compile + run
python3 tools/compile_nox.py your_program.ol output.olang
./output.olang

# Run tests (40/40)
python3 tools/compile_nox.py test/vm2/test_full.ol test/vm2/test_full.olang
./test/vm2/test_full.olang

# Run benchmark (35/35)
python3 tools/compile_nox.py tools/eval/benchmark.ol tools/eval/benchmark.olang
./tools/eval/benchmark.olang
```

## What Works

- **VM**: 5100 LOC x86-64 assembly, 46KB binary
- **Language**: let, fn, if/else, while, recursion, arrays, strings, closures, try/catch
- **Recursion**: fib(10)=55, fib(20)=6765, fact(5)=120
- **Builtins**: 43+ (math, string, array, file I/O, network, bitwise, crypto)
- **Molecular Engine**: 5D P_weight encoding (S,R,V,A,T), compose, distance
- **KnowTree**: word-indexed O(1) fact lookup via mol_matrix
- **Silk**: Hebbian edge learning, implicit strength, decay
- **Pipeline**: security gate, encode, search, silk fire, response
- **Tests**: 40 unit tests + 35 benchmarks + 60+ algorithm challenges
- **Self-build**: compiler in Python (Olang self-hosting compiler in progress)

## Architecture

```
vm/x86_64/vm_nox.S     — VM (5100 LOC, 46KB binary)
tools/compile_nox.py    — Bootstrap compiler (Python → Olang bytecode)
stdlib/                 — Standard library (Olang)
  core.ol               — abs, max, min, mol operations
  knowtree.ol           — Word-indexed knowledge store
  silk.ol               — Hebbian edge learning
  pipeline_v2.ol        — Input → encode → search → respond
  compiler.ol           — Self-hosting compiler (WIP)
spec/                   — Specifications (11 parts + VM spec)
test/vm2/               — Test suite
tools/eval/             — Benchmark + challenge book
```

## 5D Molecular Encoding

Every input encodes into a 16-bit molecule: `P_weight = [S:4][R:4][V:3][A:3][T:2]`

- **S** (Shape): structural complexity (SDF)
- **R** (Relation): semantic role (operator, noun, verb)
- **V** (Valence): emotion polarity (positive/negative)
- **A** (Arousal): intensity level (calm/excited)
- **T** (Time): temporal state (static/dynamic)

65,536 possible molecules. Distance = scaled Manhattan. Compose = non-commutative (order matters).

## Specs

| Part | Topic | Status |
|------|-------|--------|
| BP1 | VM | Done (5100 LOC) |
| BP2 | Encode (42 formulas) | Spec written |
| BP3 | KnowTree (fractal tree) | Working (word-indexed) |
| BP4 | Silk (Hebbian learning) | Working (covariance + decay) |
| BP5 | Pipeline (Decode ∂) | Working (search + response) |
| BP6 | Instincts (7 formulas) | Spec written |
| BP7 | Memory (observations) | Spec written |
| BP8 | JARVIS (1 brain N mouths) | Spec written |
| BP9 | Agent (PTAV loop) | Spec written |
| BP10 | Data (500K facts) | Spec written |
| BP11 | Body (camera/audio) | Spec written |

## Numbers

```
VM binary:     46 KB (vs LLM: 100+ GB)
Dependencies:  0 (vs LLM: CUDA, Python, cloud)
Tests:         40/40 unit + 35/35 benchmark
Determinism:   Gen1 == Gen2 (byte-identical self-build target)
Boot time:     <1ms (vs LLM: minutes)
```

## License

MIT
