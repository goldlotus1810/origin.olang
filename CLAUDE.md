# Nox — VM v2 (SS25 current)

## ★★★ ĐỌC TRƯỚC KHI LÀM BẤT CỨ GÌ ★★★
1. **[DECISIONS.md](DECISIONS.md)** — Quyết định đã thống nhất. KHÔNG đề xuất lại.
2. **[BUGS_KNOWN.md](BUGS_KNOWN.md)** — Bugs đã biết. KHÔNG tìm lại.
3. **[docs/OLANG_LANGUAGE_REVIEW.md](docs/OLANG_LANGUAGE_REVIEW.md)** — Thảo luận 3 người, 5 rounds. Đọc nếu cần context.

```bash
make vm && make test && make benchmark   # verify 40/40 + 35/35
git log --oneline -10
```
Đọc `spec/NOX_MASTER_SPEC.md` — master document.
Đọc `spec/` — mỗi bộ phận có spec riêng. Hiểu trước, code sau.

## Build
```bash
make vm                 # as + ld → vm/x86_64/vm_nox (66KB, 94 builtins)
make test               # compile + run test_full.ol (40/40)
make benchmark          # compile + run benchmark.ol (35/35)

# Self-hosting compiler (NO Python needed):
printf 'source.ol\noutput.olang\n' > /tmp/.nox_args && ./compiler.olang

# Python bootstrap (firmware recovery only — DECISION A5):
python3 tools/compile_nox.py SOURCE.ol OUTPUT.olang

# Verify self-hosting — ALWAYS check OUTPUT not just exit code:
python3 tools/compile_nox.py stdlib/compiler.ol /tmp/gen1.olang
rm -f /tmp/.nox_args && /tmp/gen1.olang                    # gen1→gen2
rm -f /tmp/gen3.olang && printf 'stdlib/compiler.ol\n/tmp/gen3.olang\n' > /tmp/.nox_args
/tmp/compiler_gen2.olang                                    # gen2→gen3
diff /tmp/compiler_gen2.olang /tmp/gen3.olang               # MUST match
```

## Status (SS25 — 2026-04-02)
- VM: vm/x86_64/vm_nox.S (8301 LOC, 66KB, 94 builtins)
- Compiler: stdlib/compiler.ol (1711 LOC, self-hosting, B1-B11 complete)
- Bootstrap: compiler.olang in repo (Python no longer required for bootstrap)
- Python: tools/compile_nox.py (1222 LOC, kept as firmware recovery — DECISION A5)
- Gen2==Gen3: ✅ REAL fixed point (38761 bytes, verified output — not just exit code)
- Stdlib: json.ol (JSON parse+stringify), 20+ brain/encode/knowtree files
- Tests: 40/40 core + 28 feature + 10 stress tests
- Known bugs: 6 critical + 5 high — see BUGS_KNOWN.md
- Next priority: P1 throw/rsp, P2 f64+string, P3 Zone C 64MB — see DECISIONS.md

## VM Builtins (94 total)
```
String:      len, substr, char_at, __char_code, __to_string, __str_find,
             __str_index_of, __str_trim, __write_raw, __str_split,
             __str_replace, __str_join, __str_starts_with, __str_ends_with,
             __str_to_num, __readline
Array:       push, __array_get, __set_at, __array_new, __array_with_cap,
             __range, __pop_arr
Dict:        __dict_new, __dict_get, __dict_set, __dict_keys
Math:        __abs, __floor, __ceil, __sqrt, __exp, __log2
Bit:         __bit_and, __bit_or, __bit_xor, __bit_shl, __bit_shr
File:        __file_read, __file_write, __file_append, __file_append_bytes,
             __fd_open, __fd_read, __fd_close
Network:     __tcp_listen, __tcp_accept, __tcp_send, __tcp_recv, __tcp_close
System:      __system, __sleep, __heap_used, __heap_pin, type_of,
             __f64_to_le_bytes, __mmap, __munmap, __ioctl, __mmap_file, __syscall
Matrix:      __mx_w, __mxr
Memory:      __mem_read8, __mem_write8, __mem_read32, __mem_write32
Activation:  __act_set, __act_get, __act_add, __act_decay, __act_reset,
             __act_top_k
WM/STM:     __wm_bind, __wm_read, __wm_clear, __stm_push, __stm_query,
             __stm_count
Pipeline:    __pseudo_select, __chain_quality, __mol_dominant,
             __chain_compose, __chain_copy, __batch_dist
Conversation: __v_push, __conv_tone
Homeostasis: __homeostasis
Silk:        __silk_weight, __silk_classify
Security:    __bloom_check, __negative_mark
Crypto:      __crc32, __sha256 (stub)
```

## VM Opcodes
```
Stack:    0x00 Nop, 0x01 Push, 0x06 Emit, 0x0B Dup, 0x0C Pop, 0x0D Swap
Var:      0x02 Load, 0x13 Store (bare assign), 0x16 StoreLocal (let)
Num:      0x15 PushNum, 0x19 PushMol
Control:  0x07 Call, 0x08 Ret, 0x09 Jmp, 0x0A Jz, 0x0E Loop, 0x0F Halt
Closure:  0x24 CallClosure, 0x25 Closure, 0x30 ClosureCapture
Frame:    0x26 LoadReg, 0x27 StoreReg, 0x28 EnterFrame, 0x29 LeaveFrame
Arith:    0x2A Add, 0x2B Sub, 0x2C Mul, 0x2D Div, 0x2E Mod
Compare:  0x31-0x36 Eq/Ne/Lt/Gt/Le/Ge
Except:   0x1A TryBegin, 0x1B CatchEnd, 0x78 Throw
Mol:      0x40-0x47 Pack/Unpack/Dist/Compose/Dominant/BatchDist/Encode/Decode
KnowTree: 0x50-0x54 Store/Load/Nearest/Walk/Learn
Silk:     0x58-0x5B Fire(φ⁻³)/Decay(φ⁻¹)/Walk/Implicit
Arena:    0x60-0x65 AllocA/B/C/ResetC/ResetB/HeapPin
Security: 0xB0-0xB4 CapCheck/Create/Delegate/Revoke/SecGate
```

## Key Fixes
### SS17
- OP_STORE_LOCAL (0x16): let vs bare assign — scope isolation
- SilkFire: φ⁻³ Hebbian (diminishing returns), initial weight=25000
- SilkDecay: φ⁻¹ = 618/1024 per 24h cycle
- chain_compose: biological (S=Union, R=Zipf, V=Amplify, A=Max, T=First)
- Bug 15 FIXED: compiler.ol self-hosts
- Benchmark hang FIXED: scope leak was root cause
### SS25 — CRITICAL (self-hosting was FAKE before these)
- Hex lexer: `0x01` → tokenized as `0` + `x01` → all opcodes = 0 → Gen2 was NOP binary
- Escape dependency: `c == "\""` fails in self-compiled code → use `__char_code(c) == 34`
- __file_read heap: source at r15+0x200000 overwritten → `"" + __file_read()` workaround
- for+continue: increment after body → infinite loop → move increment before body
- nested for: `__for_arr`/`__for_i` name collision → unique `__fa0`/`__fi0` per loop

## KHÔNG BAO GIỜ
- Hardcode data, if/else trên keywords → dùng toán 5D
- Code trước khi đọc DECISIONS.md + BUGS_KNOWN.md → ĐỌC TRƯỚC
- Nói "done" → verify OUTPUT trước (Gen2==Gen3 giả đã xảy ra)
- `let x = x + 1` trong while/fn → dùng `let x = [0]; __set_at(x, 0, ...)`
- `let arr = []` rồi push >8 → dùng `__array_with_cap(N)`
- Đề xuất FFI → DECISION A2: tự chủ > tiện lợi
- Đề xuất GC mark-sweep → DECISION A3: quá phức tạp, dùng arena reset
- Đề xuất decompiler → DECISION A6: dùng template slots thay thế
- `c == "\""` hoặc `c == "\\"` → dùng `__char_code(c) == 34` / `== 92`
- Port mù quáng từ Rust → hiểu spec A-D trước, so sánh, rồi quyết định

## Olang Language Features (SS25 — compiler.ol self-hosts ALL)
```
Core:        let, fn, if/else, while, return, emit
Control:     try/catch/throw      — B6 (ABSOLUTE offset for TryBegin)
             break/continue       — B7 (g_break_patches + g_loop_start)
             for x in arr {}      — B8 (desugar → while, unique __fa/__fi names)
             match x { v => s; }  — B9 (desugar → if/else chain, reverse build)
Data:        {key: val}           — B4 (TK_COLON, AST_DICT, __dict_new)
             expr.field           — B5 (postfix dot → __dict_get)
             expr.field = val     — B5 (dot assign → __dict_set)
             arr[i] / arr[i]=val  — B3 (postfix bracket → __array_get/__set_at)
             !expr                — B2 (→ expr == 0)
Strings:     \n \r \t \0 \\ \"   — B1 (emit_string escape convert, __char_code based)
Modules:     import "file.ol"     — B10 (resolve_imports, source prepend, dedup)
Closures:    fn captures outer    — B11 (find_free_vars, OP_CLOSURE_CAP 0x30, g_fn_depth)
Stdlib:      json.ol              — JSON parse + stringify (199 LOC, pure Olang)
```
**Known issues:** See BUGS_KNOWN.md (6 critical VM bugs, 5 high)
**Compiler workarounds:** `"" + __file_read()` for heap safety, `__char_code() == 34` not `"\""` for self-compile
**Verify:** `make fixed-point` — Gen2==Gen3 MUST check OUTPUT not just exit code

## Nguyên tắc
- Encode = ∫ (tích phân). Decode = ∂ (vi phân). TÍNH, không TRA.
- P_weight = u16 = [S:4][R:4][V:3][A:3][T:2] = 65536 molecules
- Distance = |ΔS| + |ΔR| + 2|ΔV| + 2|ΔA| + 4|ΔT| (weighted Manhattan, max=70)
- Compose = biological: S=Union(max), R=Zipf(first), V=Amplify, A=Max, T=First
- Silk fire = φ⁻³ Hebbian: Δw = (1-w/65535) × 236
- Silk decay = φ⁻¹ per 24h: w × 618/1024
- Quality threshold = φ⁻¹ = 618/1000
- QR promotion = weight ≥ 854 AND fire ≥ Fib(depth)
- Học = thay đổi weights. Không phải lưu thêm strings.

## Architecture
```
+----------------------------------------------------------+
| NOX BRAIN (Olang)                                        |
|   brain.ol: Capture → Activate → Hypothesize → Repair → Decode → Evaluate |
|   encode.ol: 42 formulas (COMPUTED)                      |
|   KnowTree, Silk, 7 Instincts, Agent PTAVF, 15 Mechanisms |
+----------------------------------------------------------+
| NOX BODY — Parasitic Library OS (Olang + ASM)            |
|   Eyes(fb0) Hands(evdev) Voice(raw socket)               |
|   Memory(mmap) Heartbeat(io_uring) Spine(clone)          |
|   Evolution(KVM ring-0) Inject(eBPF)                     |
+----------------------------------------------------------+
| LINUX HOST — Exokernel (chỉ là driver layer)             |
|   ~22 syscalls | /dev/* | /proc/* | /sys/*               |
+----------------------------------------------------------+
```

## Specs
### Process (đọc TRƯỚC specs)
- [DECISIONS.md](DECISIONS.md) — Quyết định đã thống nhất (A1-A8, P1-P6, X1-X5)
- [BUGS_KNOWN.md](BUGS_KNOWN.md) — Bugs đã biết (6 critical + 5 high + 4 medium)
- [docs/OLANG_LANGUAGE_REVIEW.md](docs/OLANG_LANGUAGE_REVIEW.md) — 5-round review, 3 người
- [spec/SPEC_R1_COMPILER_SYNC.md](spec/SPEC_R1_COMPILER_SYNC.md) — R1 complete, B1-B11

### Master
- [NOX_MASTER_SPEC](spec/NOX_MASTER_SPEC.md) — THE master document

### Brain (gốc rễ — KHÔNG sửa)
- [SPEC_A](docs/SPEC_A_FOUNDATION.md) — SDF, P_weight, Encode ∫, Decode ∂
- [SPEC_B](docs/SPEC_B_STRUCTURE.md) — Chain, KnowTree, Silk
- [SPEC_C](docs/SPEC_C_NEURON.md) — Neuron lifecycle, physics
- [SPEC_D](docs/SPEC_D_PIPELINE.md) — 15 mechanisms, 6 checkpoints, 7 instincts, PTAVF
- [SPEC_E](docs/SPEC_E_ORGANISM.md) — Organism, self-model
- [SPEC_F](docs/SPEC_F_AGENT.md) — Agent, autonomy

### Blueprints (implementation)
- [BP2 Encode](spec/SPEC_BP2_ENCODE.md) — 42 formulas
- [BP3 KnowTree](spec/SPEC_BP3_KNOWTREE.md) — fractal tree, QR
- [BP4 Silk](spec/SPEC_BP4_SILK.md) — covariance, adaptive decay
- [BP5 Pipeline](spec/SPEC_BP5_PIPELINE_EN.md) — 5 layers, CLONALG, DCA
- [BP6 Instincts](spec/SPEC_BP6_INSTINCTS.md) — 7 pure 5D formulas
- [BP7 Memory](spec/SPEC_BP7_MEMORY.md) — observations, retrieval
- [BP8 JARVIS](spec/SPEC_BP8_JARVIS.md) — 1 brain N mouths
- [BP9 Agent](spec/SPEC_BP9_AGENT.md) — PTAV loop
- [BP10 Data](spec/SPEC_BP10_DATA.md) — 500K facts
- [BP11 Body](spec/SPEC_BP11_BODY.md) — camera, audio, interoception
- [BP12 Parasite](spec/SPEC_BP12_PARASITE.md) — 7 organs, 5 phases, Forth scheduling
- [BP13 Persistence](spec/SPEC_BP13_PERSISTENCE.md) — mmap + WAL + NKB + LTP model
- [BP14 Generation](spec/SPEC_BP14_GENERATION.md) — Retrieve → Recombine → Template NLG
- [BP15 Communication](spec/SPEC_BP15_COMMUNICATION.md) — A2A + mDNS + HTTP server
- [BP16 Feedback](spec/SPEC_BP16_FEEDBACK.md) — UCB1 bandit + ACT-R utility + calibration

### Research (SS22)
- [docs/research/](docs/research/) — 7 files, all external research
- [docs/references/NOX_RESEARCH_INDEX.md](docs/references/NOX_RESEARCH_INDEX.md) — index

### Reference Library — [docs/references/INDEX.md](docs/references/INDEX.md)
196MB: Exokernel, Intel SDM, AMD APM, OSTEP, xv6, io_uring, eBPF, KVM, AIMA, OSDev Wiki, kernel headers

### From Rust (reference only — verify against A-D before using)
- [Formula Engine](spec/PLAN_FORMULA_ENGINE.md) — R/V/A/T dispatch (2114 LOC)
- [ref/rust_mol/](ref/rust_mol/) — 9 key Rust files for reference
- ⚠️ Rust LR=φ⁻³ vs Spec C3 LR=0.1 — BP4 says adaptive β₀×fire^(-0.35)
- ⚠️ Rust distance=similarity overlap vs Spec A2=Euclidean — VM uses weighted Manhattan (BP3)

## Đã giải quyết
- ~~Bug 15: compiler.ol parse error~~ ✅ OP_STORE_LOCAL fixed scope (SS17)
- ~~Benchmark hang~~ ✅ scope leak fixed (SS17)
- ~~Heap blocker (1500 facts)~~ ✅ __mmap 256MB (SS21)
- ~~Push realloc~~ ✅ capacity tracking + grow 2× (SS21)
- ~~Gen2==Gen3 giả (hex bug)~~ ✅ lexer scan 0x prefix (SS25)
- ~~Escape dependency~~ ✅ __char_code thay string compare (SS25)
- ~~file_read heap corrupt~~ ✅ workaround "" + (SS25, VM fix pending)
- ~~for+continue infinite loop~~ ✅ increment trước body (SS25)
- ~~nested for name collision~~ ✅ unique __fa/__fi per loop (SS25)
- ~~R1 B1-B11~~ ✅ compiler.ol self-hosts all features (SS25)

## Chưa giải quyết — xem BUGS_KNOWN.md
6 critical (CRASH-1/2/3, DATA-2/4, CORRUPT-2) + 5 high + 4 medium
