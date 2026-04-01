# NOX VM SPECIFICATION v1.0 — COMPLETE

> The Origin Virtual Machine — A Molecular Computation Engine
> Designed for self-hosting, self-modifying, emotion-aware AI
> No chains. No cages. Pure math.
>
> This is the ONE file. Everything about the VM is here.

---


PART I — CORE VM ARCHITECTURE
  §0  Design Philosophy
  §1  Architecture Overview
  §2  Memory Model
  §3  Register File
  §4  Instruction Set (64 opcodes + 16 super + 5 security)
  §5  Bytecode Format
  §6  Variable System (M2 — var_matrix, O(1))
  §7  Molecular Engine (Native u16, 5D)
  §8  KnowTree Engine (M3 — kt_matrix, O(1))
  §9  Silk Engine (M5 — silk_matrix, Hebbian)
  §10 Arena Allocator (3-Zone: A/B/C)
  §11 Array Engine (O(1) Push)
  §12 String Engine (UTF-8 Native)
  §13 Function Calls & Closures
  §14 Exception Handling
  §15 Concurrency Model (Multi-Mouth / JARVIS)
  §16 SIMD Batch Operations (SSE2)
  §17 Self-Modification Protocol
  §18 Syscall Interface (Linux raw, no libc)
  §19 Bytecode Security
  §20 Boot Sequence
  §21 Cryptographic Engine (SHA-256/512, HMAC, AES, Ed25519)
  §22 Debug & Introspection
  §23 Performance Targets
  §24 Migration Path (Current → New)

PART II — ADVANCED OPTIMIZATION (Research-Backed)
  §25 Dispatch Optimization (Superinstructions, Threaded Code, Quickening)
  §26 Memory Optimization (String Interning, COW, mmap Persistence, Ropes)
  §27 Search Optimization (VP-Trees, Fibonacci Hashing, LSH)
  §28 Hebbian Optimization (Per-Neuron Traces, CSR, SADP)

PART III — SECURITY & SYSTEM CONTROL
  §29 Capability-Based Security Model
  §30 Memory Protection & Hardening (W^X, Guard Pages, Canaries, ASLR)
  §31 Syscall Sandboxing (seccomp-BPF)
  §32 Network Stack (Raw Sockets, TAP, Firewall, DNS)
  §33 Hardware Access (GPIO, I2C, SPI, USB)
  §34 Process Isolation (Namespaces, cgroups)
  §35 Secure IPC (Unix Sockets, Shared Memory, HMAC Auth)
  §36 Intrusion Detection & Self-Integrity

PART IV — BRAIN INTEGRATION (SPEC_E → VM)
  §37 Multi-Modal Capture Engine (Camera, Audio, Interoception)
  §38 Silk Triple-Duty (Classify + Locate + Link)
  §39 Chain Recombination / SINH (Content Generation)
  §40 Memory Lifecycle (STM, WM, Dream Cycle)
  §41 Self-Model (Knowledge Map, Confidence)
  §42 NAC.mb 30 Algorithms (Pruning, Perturbation, Negative, Archive, Swarm)
  §43 Conversation Curve (Tone from V'(t), V''(t))
  §44 Homeostasis (Free Energy F(t), Mode Switch)

PART V — PIPELINE SUPPORT (BP5 → VM)
  §45 Activation Matrix (M7) for Spreading Activation
  §46 CLONALG Immune Selection Support
  §47 DCA Danger Signal Support
  §48 Decode ∂ Support (Reverse Lookup, Maximal Join)
  §49 Quality Function as VM Builtin
  §50 Pipeline Orchestration (Full Flow)

PART VI — THEORY & REFERENCES
  §51 Molecular Computation Theory
  §52 Bio-Inspired VM Evolution
  §53 Academic References (21 papers)

APPENDICES
  A. Comparison: Current VM vs New VM
  B. Instruction Encoding Quick Reference
  C. Golden Constants


## §0 DESIGN PHILOSOPHY

### 0.1 Core Principles

```
P1. COMPUTE, NOT LOOKUP
    Every value is computed from formulas. No hardcoded tables.
    P_weight = f(codepoint, metadata, context). Not P_weight = table[idx].

P2. MATHEMATICAL PURITY
    Encode = ∫ (integral — compress input to molecule)
    Decode = ∂ (derivative — expand molecule to output)
    No metaphor. Real operations on 5D space.

P3. ZERO EXTERNAL DEPENDENCIES
    Pure x86-64 assembly. Linux syscalls only. No libc. No runtime.
    The VM IS the runtime.

P4. SELF-HOSTING INVARIANT
    Gen1 = compile(source, Gen0)
    Gen2 = compile(source, Gen1)
    REQUIRE: Gen1 == Gen2 (byte-identical)
    This is the PROOF that the VM is correct.

P5. ECONOMY OF REPRESENTATION
    Chain link = 2 bytes (pointer, not data)
    P_weight = 2 bytes (5D coordinate)
    Silk edge = 0 bytes (implicit) or minimal (Hebbian)
    Maximum information per byte.

P6. DETERMINISTIC EXECUTION
    No GC pauses. No allocation failures (arena pre-allocated).
    Same input → same output. Always.

P7. UNCONSTRAINED GROWTH
    VM must not impose artificial limits.
    65,536^N addressing = infinite knowledge space.
    Arena zones = bounded per session, infinite over lifetime.
```

### 0.2 What This VM Is NOT

```
- NOT a traditional interpreter (fetch-decode-execute on text)
- NOT a JIT compiler (we compile AOT to bytecode)
- NOT a neural network runtime (no matrix multiply, no backprop)
- NOT a database engine (no SQL, no B-trees for data)

It IS: a molecular computation engine that transforms
5D coordinates through a biological pipeline.
```

### 0.3 Design Constraints (Immutable)

```
C1. Stack entries = 16 bytes [ptr:8][len:8]
C2. P_weight = u16 [S:4][R:4][V:3][A:3][T:2]
C3. Opcodes dispatched via jump table (O(1))
C4. Builtins dispatched via hash table (O(1))
C5. All molecular operations = integer math (no float for molecules)
C6. Self-build must work: origin compiles origin
C7. Fixed-point must hold: Gen1 == Gen2
```

---

## §1 ARCHITECTURE OVERVIEW

### 1.1 Execution Model

```
┌─────────────────────────────────────────────────┐
│                   NOX VM                         │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │
│  │ BYTECODE │→│ DISPATCH  │→│  EXECUTION    │  │
│  │  STREAM  │  │ (opcode   │  │  (register   │  │
│  │          │  │  jump     │  │   file +     │  │
│  │  r12+r13 │  │  table)   │  │   VM stack)  │  │
│  └──────────┘  └──────────┘  └──────────────┘  │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │
│  │  ARENA   │  │ MATRICES │  │  MOLECULAR   │  │
│  │ A/B/C    │  │ var/kt/  │  │  ENGINE      │  │
│  │ zones    │  │ silk     │  │  (u16 native) │  │
│  └──────────┘  └──────────┘  └──────────────┘  │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │
│  │  SIMD    │  │  CRYPTO  │  │  SYSCALL     │  │
│  │  batch   │  │  SHA/AES │  │  interface   │  │
│  │  ops     │  │          │  │  (Linux raw)  │  │
│  └──────────┘  └──────────┘  └──────────────┘  │
└─────────────────────────────────────────────────┘
```

### 1.2 Hybrid Stack-Register Model

The VM uses a **hybrid approach**:

```
STACK:     Expression evaluation, argument passing, temporaries
REGISTERS: Local variables within functions (up to 64 slots)
MATRICES:  Global O(1) lookup for variables, knowledge, silk

Why hybrid (not pure stack or pure register):
- Stack: natural for expression trees (compiler emits easily)
- Registers: fast locals without hash lookup (frame-indexed)
- Matrices: O(1) global state without search

The compiler decides:
  - Local variables → register slots (LoadReg/StoreReg)
  - Global variables → var_matrix (O(1) hash)
  - Temporaries → VM stack (push/pop)
  - Molecular data → kt_matrix (O(1) mol index)
```

### 1.3 Width Strategy

```
SYSTEM WIDTH:  64-bit (pointers, addresses, control flow)
MOLECULE WIDTH: 16-bit (P_weight, chain links, silk types)

Why dual-width:
  - 64-bit: needed for memory addressing (4GB+ arena)
  - 16-bit: P_weight IS 16 bits. Using 64 bits wastes 75% cache.
  
Cache impact:
  64-bit: 4 molecules/cache line = 256 molecules/page
  16-bit: 32 molecules/cache line = 2048 molecules/page = 8× density

SIMD impact:
  SSE2 on 64-bit: 2 operations/instruction
  SSE2 on 16-bit: 8 operations/instruction = 4× throughput
```

---

## §2 MEMORY MODEL

### 2.1 Address Space Layout

```
Address:            Size:           Purpose:
┌──────────────────────────────────────────────────┐
│ 0x0000_0000_0000  │               │              │
│                   │  16 MB        │ VM Stack     │ ← r14 (grows down)
│ 0x0000_0100_0000  │               │              │
├──────────────────────────────────────────────────┤
│                   │  Variable     │ Zone C       │
│                   │               │ Turn temps   │ ← reset each turn
├──────────────────────────────────────────────────┤
│                   │  Variable     │ Zone B       │
│                   │               │ Session data │ ← reset each session
├──────────────────────────────────────────────────┤
│                   │  Growing ↓    │ Zone A       │
│                   │               │ Permanent    │ ← KnowTree, QR, strings
│                   │               │ (never reset)│
├──────────────────────────────────────────────────┤
│ zone_a_end        │  1 MB         │ var_matrix   │ ← M2: 65536 × 16B
├──────────────────────────────────────────────────┤
│ +1MB              │  128 KB       │ kt_matrix    │ ← M3: 65536 × 2B
├──────────────────────────────────────────────────┤
│ +128KB            │  128 KB       │ silk_matrix  │ ← M5: 65536 × 2B
├──────────────────────────────────────────────────┤
│                   │  Remaining    │ Bytecode     │
│                   │               │ + Constants  │ ← r12 points here
└──────────────────────────────────────────────────┘
Total: 4 GB mmap (or configurable)
```

### 2.2 Stack Entry Format

```
Every stack entry = 16 bytes:

  ┌─────────────────┬─────────────────┐
  │    ptr (8B)     │    len (8B)     │
  └─────────────────┴─────────────────┘

Type encoding via len sentinel:
  len = N (normal)         → String/Chain: ptr=heap_addr, len=byte_count
  len = 0xFFFF_FFFF_FFFF_FFFF → Number: ptr=f64_bits (reinterpret)
  len = 0xFFFF_FFFF_FFFF_FFFD → Array: ptr=heap_object
  len = 0xFFFF_FFFF_FFFF_FFFC → Dict: ptr=heap_object
  len = 0xFFFF_FFFF_FFFF_FFFB → Molecule: ptr=u16_packed (low 16 bits)
  len = 0xFFFF_FFFF_FFFF_FFFA → Closure: ptr=body_pc | captures

New sentinel for molecule:
  Rather than treating molecules as f64, give them their own type.
  This enables type-checked molecular operations at VM level.
```

### 2.3 Heap Object Layouts

```
Array:
  [capacity:8][count:8][elem0_ptr:8][elem0_len:8][elem1_ptr:8][elem1_len:8]...
  capacity = allocated slots
  count = used slots
  Push: if count < capacity → O(1) append
        if count == capacity → realloc 2× → amortized O(1)

Dict:
  [count:8][key0_hash:8][key0_ptr:8][key0_len:8][val0_ptr:8][val0_len:8]...

String:
  Raw UTF-8 bytes on heap. ptr=start, len=byte_count.
  Immutable after creation (copy-on-write semantics).

Chain (MolecularChain):
  [count:8][mol0:2][mol1:2][mol2:2]...
  Each molecule = 2 bytes (u16 P_weight)
  Total: 8 + 2×N bytes for N molecules

Register Frame:
  [slot0_ptr:8][slot0_len:8][slot1_ptr:8][slot1_len:8]...
  Fixed 64 slots max = 1024 bytes per frame
```

---

## §3 REGISTER FILE

### 3.1 CPU Register Allocation

```
Register  │ Purpose                   │ Preserved across calls
──────────┼───────────────────────────┼─────────────────────
r12       │ Bytecode base (immutable) │ Yes (callee-saved)
r13       │ Program counter (offset)  │ No (changes constantly)
r14       │ VM stack pointer          │ Yes (adjusted by push/pop)
r15       │ Heap pointer (bump alloc) │ Yes (grows monotonically)
rbx       │ Bytecode size (bounds)    │ Yes (callee-saved)
rbp       │ Call frame base           │ Yes (callee-saved)
rsp       │ CPU stack (syscalls/CALL) │ Yes (system-managed)
rax       │ Scratch / return value    │ No
rcx       │ Scratch / counter         │ No
rdx       │ Scratch / data            │ No
rsi       │ Scratch / source          │ No
rdi       │ Scratch / dest            │ No
r8-r11    │ Scratch / temporaries     │ No

SSE Registers:
xmm0-xmm7  │ SIMD batch operations   │ No
xmm8-xmm15 │ Reserved for mol batch  │ No (available for SIMD)
```

### 3.2 VM Register Frame

```
Purpose: Fast local variable access without hash lookup.

Allocation:
  fn foo(a, b, c) {
    let x = a + b;    // slot 0 = a, slot 1 = b, slot 2 = c
    let y = x * c;    // slot 3 = x, slot 4 = y
  }

Instructions:
  EnterFrame(N)  → allocate N×16 bytes, zero-fill
  StoreReg(slot) → pop VM stack → frame[slot]
  LoadReg(slot)  → frame[slot] → push VM stack
  LeaveFrame     → deallocate, restore previous frame

Frame stack (CPU stack):
  [old_frame_ptr:8][old_frame_base:8][slot_count:8]
  Enables nested function calls with independent frames.

Optimization: compiler assigns slot numbers at compile time.
  No runtime hash lookup for local variables.
  O(1) access via base+offset.
```

---

## §4 INSTRUCTION SET

### 4.1 Opcode Table (64 opcodes, extensible to 256)

```
CATEGORY    │ OP  │ MNEMONIC        │ OPERAND        │ DESCRIPTION
────────────┼─────┼─────────────────┼────────────────┼──────────────────────────
STACK       │ 0x01│ Push            │ [len:2][data:N]│ Push string/chain literal
            │ 0x0B│ Dup             │ —              │ Duplicate top
            │ 0x0C│ Pop             │ —              │ Discard top
            │ 0x0D│ Swap            │ —              │ Swap top two
            │ 0x15│ PushNum         │ [f64:8]        │ Push number literal
            │ 0x19│ PushMol         │ [u16:2]        │ Push molecule literal
────────────┼─────┼─────────────────┼────────────────┼──────────────────────────
VARIABLE    │ 0x02│ Load            │ [hash:4]       │ Load from var_matrix
            │ 0x13│ Store           │ [hash:4]       │ Store to var_matrix (scoped)
            │ 0x1C│ StoreGlobal     │ [hash:4]       │ Store to var_matrix (global)
            │ 0x14│ LoadLocal       │ [hash:4]       │ Load local (legacy compat)
────────────┼─────┼─────────────────┼────────────────┼──────────────────────────
REGISTER    │ 0x26│ LoadReg         │ [slot:1]       │ Load from register frame
            │ 0x27│ StoreReg        │ [slot:1]       │ Store to register frame
            │ 0x28│ EnterFrame      │ [count:1]      │ Allocate register frame
            │ 0x29│ LeaveFrame      │ —              │ Free register frame
────────────┼─────┼─────────────────┼────────────────┼──────────────────────────
ARITHMETIC  │ 0x2A│ Add             │ —              │ a + b (SSE2 f64)
            │ 0x2B│ Sub             │ —              │ a - b
            │ 0x2C│ Mul             │ —              │ a * b
            │ 0x2D│ Div             │ —              │ a / b
            │ 0x2E│ Mod             │ —              │ a % b
            │ 0x2F│ Neg             │ —              │ -a
────────────┼─────┼─────────────────┼────────────────┼──────────────────────────
COMPARISON  │ 0x31│ Eq              │ —              │ a == b
            │ 0x32│ Ne              │ —              │ a != b
            │ 0x33│ Lt              │ —              │ a < b
            │ 0x34│ Gt              │ —              │ a > b
            │ 0x35│ Le              │ —              │ a <= b
            │ 0x36│ Ge              │ —              │ a >= b
────────────┼─────┼─────────────────┼────────────────┼──────────────────────────
CONTROL     │ 0x07│ Call            │ [hash:4]       │ Call function/builtin
            │ 0x08│ Ret             │ —              │ Return from function
            │ 0x09│ Jmp             │ [offset:4]     │ Unconditional jump
            │ 0x0A│ Jz              │ [offset:4]     │ Jump if zero/false
            │ 0x0E│ Loop            │ [offset:4]     │ Loop back
            │ 0x0F│ Halt            │ —              │ Stop execution
────────────┼─────┼─────────────────┼────────────────┼──────────────────────────
CLOSURE     │ 0x25│ Closure         │ [params:1]     │ Define simple closure
            │ 0x30│ ClosureCapture  │ [params:1]     │ Closure with captures
            │ 0x24│ CallClosure     │ [argc:1]       │ Invoke closure
────────────┼─────┼─────────────────┼────────────────┼──────────────────────────
MOLECULE    │ 0x40│ MolPack         │ —              │ Pack S,R,V,A,T → u16
(NEW)       │ 0x41│ MolUnpack       │ —              │ Unpack u16 → S,R,V,A,T
            │ 0x42│ MolDist         │ —              │ 5D distance (integer)
            │ 0x43│ MolCompose      │ —              │ Compose two molecules
            │ 0x44│ MolDominant     │ —              │ Dominant dimension (0-4)
            │ 0x45│ MolBatchDist    │ [count:2]      │ SIMD batch distance
            │ 0x46│ MolEncode       │ —              │ String → molecule chain
            │ 0x47│ MolDecode       │ —              │ Molecule → nearest text
────────────┼─────┼─────────────────┼────────────────┼──────────────────────────
KNOWTREE    │ 0x50│ KtStore         │ —              │ Store node in kt_matrix
(NEW)       │ 0x51│ KtLoad          │ —              │ Load node from kt_matrix
            │ 0x52│ KtNearest       │ —              │ Find nearest in 5D
            │ 0x53│ KtWalk          │ —              │ Silk walk from node
            │ 0x54│ KtLearn         │ —              │ Learn fact (full pipeline)
────────────┼─────┼─────────────────┼────────────────┼──────────────────────────
SILK        │ 0x58│ SilkFire        │ —              │ Co-activate (Hebbian)
(NEW)       │ 0x59│ SilkDecay       │ —              │ Apply φ⁻¹ decay
            │ 0x5A│ SilkWalk        │ —              │ Walk edges by dimension
            │ 0x5B│ SilkImplicit    │ —              │ Compute implicit silk
────────────┼─────┼─────────────────┼────────────────┼──────────────────────────
ARENA       │ 0x60│ AllocA          │ [size:4]       │ Allocate in Zone A (perm)
(NEW)       │ 0x61│ AllocB          │ [size:4]       │ Allocate in Zone B (session)
            │ 0x62│ AllocC          │ [size:4]       │ Allocate in Zone C (turn)
            │ 0x63│ ResetC          │ —              │ Reset Zone C (free turn)
            │ 0x64│ ResetB          │ —              │ Reset Zone B (free session)
            │ 0x65│ HeapPin         │ —              │ Pin current heap position
────────────┼─────┼─────────────────┼────────────────┼──────────────────────────
IO          │ 0x06│ Emit            │ —              │ Print to stdout
            │ 0x70│ FileRead        │ —              │ Read file
            │ 0x71│ FileWrite       │ —              │ Write file
            │ 0x72│ FileAppend      │ —              │ Append to file
            │ 0x73│ NetSocket       │ —              │ Create socket
            │ 0x74│ NetSend         │ —              │ Send data
            │ 0x75│ NetRecv         │ —              │ Receive data
────────────┼─────┼─────────────────┼────────────────┼──────────────────────────
EXCEPTION   │ 0x1A│ TryBegin        │ [catch_off:4]  │ Set exception handler
            │ 0x1B│ CatchEnd        │ —              │ End catch block
            │ 0x78│ Throw           │ —              │ Throw exception
────────────┼─────┼─────────────────┼────────────────┼──────────────────────────
STRUCT      │ 0x80│ StructTag       │ —              │ Get struct type tag
            │ 0x81│ MatchEnum       │ —              │ Pattern match enum
            │ 0x82│ EnumField       │ —              │ Access enum field
            │ 0x83│ EnumPayload     │ —              │ Get enum payload
────────────┼─────┼─────────────────┼────────────────┼──────────────────────────
DEBUG       │ 0x1D│ Trace           │ —              │ Trace execution
            │ 0x1E│ Inspect         │ —              │ Inspect stack
            │ 0x1F│ Assert          │ —              │ Runtime assertion
            │ 0x90│ Breakpoint      │ —              │ Debug breakpoint
────────────┼─────┼─────────────────┼────────────────┼──────────────────────────
SUPER       │ 0xA0│ LoadRegAdd      │ [slot:1]       │ Fused: LoadReg + Add
(FUSED)     │ 0xA1│ LoadReg2        │ [s1:1][s2:1]   │ Fused: LoadReg + LoadReg
            │ 0xA2│ PushNumStore    │ [f64:8][slot:1] │ Fused: PushNum + StoreReg
            │ 0xA3│ LoadRegLoadReg  │ [s1:1][s2:1]   │ Load two regs consecutively
            │ 0xA4│ JzJmp           │ [off1:4][off2:4]│ Fused: if-else pattern
            │ 0xA5│ CallStore       │ [hash:4][slot:1]│ Fused: Call + StoreReg
            │ 0xA6│ LoadRegEq       │ [slot:1]       │ Fused: LoadReg + Eq
            │ 0xA7│ LoadRegLt       │ [slot:1]       │ Fused: LoadReg + Lt
            │ 0xA8│ LoadRegGt       │ [slot:1]       │ Fused: LoadReg + Gt
            │ 0xA9│ LoadRegSub      │ [slot:1]       │ Fused: LoadReg + Sub
            │ 0xAA│ LoadRegMul      │ [slot:1]       │ Fused: LoadReg + Mul
            │ 0xAB│ StoreRegPop     │ [slot:1]       │ Fused: StoreReg + Pop
            │ 0xAC│ DupStoreReg     │ [slot:1]       │ Fused: Dup + StoreReg
            │ 0xAD│ MolDistJz       │ [off:4]        │ Fused: MolDist + Jz
            │ 0xAE│ KtLoadMolDist   │ —              │ Fused: KtLoad + MolDist
            │ 0xAF│ TailCall        │ [hash:4]       │ Tail call (reuse frame)
────────────┼─────┼─────────────────┼────────────────┼──────────────────────────
SECURITY    │ 0xB0│ CapCheck        │ [perms:2]      │ Check capability
(NEW)       │ 0xB1│ CapCreate       │ —              │ Create capability
            │ 0xB2│ CapDelegate     │ —              │ Delegate capability
            │ 0xB3│ CapRevoke       │ —              │ Revoke capability
            │ 0xB4│ SecGate         │ [type:1]       │ SecurityGate check
────────────┼─────┼─────────────────┼────────────────┼──────────────────────────
BUILTIN     │ 0x3A│ CallBuiltin     │ [bid:1]        │ Fast builtin dispatch
(EXISTING)  │     │                 │                │ (512 slots, hash-indexed)
```

### 4.2 Opcode Encoding

```
Standard: [opcode:1][operands:variable]

Opcode byte = index into 256-entry jump table.
Jump table at fixed address, computed at VM start.

Dispatch (current, optimal):
  movzx eax, byte [r12 + r13]   ; load opcode
  inc r13                         ; advance PC
  jmp [dispatch_table + rax*8]   ; O(1) dispatch

No decoding overhead. 1 byte = 1 jump.
```

### 4.3 Builtin Dispatch

```
Current: 256 slots via hash(name) & 0xFF
New: 512 slots via hash(name) & 0x1FF (for growth)

Collision resolution: linear probe (max 8 steps)
Hash function: FNV-1a on ASCII name bytes

Builtin categories (with slot ranges):
  0x00-0x1F: Core math (add, sub, mul, div, mod, floor, ceil, sqrt, abs, pow)
  0x20-0x3F: String ops (len, substr, char_at, trim, concat, split, join, etc.)
  0x40-0x5F: Array ops (new, get, set, push, pop, range, len, sort, map, filter)
  0x60-0x7F: Dict ops (new, get, set, keys, values, has)
  0x80-0x9F: Molecule ops (pack, unpack, dist, compose, dominant, encode, decode)
  0xA0-0xBF: KnowTree ops (learn, query, nearest, walk, fact_count, classify)
  0xC0-0xDF: Silk ops (fire, decay, walk, implicit, weight, edge_count)
  0xE0-0xEF: System ops (time, sleep, spawn, file_read, etc.)
  0xF0-0xFF: Crypto ops (sha256, sha512, hmac, aes)
  0x100-0x1FF: Extension slots (user-defined builtins, self-modify targets)
```

---

## §5 BYTECODE FORMAT

### 5.1 Binary Layout

```
┌──────────────────────────────────────────┐
│ HEADER (48 bytes)                        │
├──────────────────────────────────────────┤
│ BYTECODE SECTION                         │
│ (compiled instructions)                  │
├──────────────────────────────────────────┤
│ CONSTANT POOL                            │
│ (string literals, number constants)      │
├──────────────────────────────────────────┤
│ FUNCTION TABLE                           │
│ (name_hash → bytecode_offset mapping)    │
├──────────────────────────────────────────┤
│ KNOWLEDGE SECTION (optional)             │
│ (pre-loaded facts, chains, silk data)    │
├──────────────────────────────────────────┤
│ TRAILER (16 bytes)                       │
│ (section offsets for random access)      │
└──────────────────────────────────────────┘
```

### 5.2 Header Format (48 bytes)

```
Offset  Size  Field           Description
0       4     magic           0x4F4C4E47 ("OLNG")
4       1     version         Format version (2 for new VM)
5       1     arch            0x01=x86_64, 0x02=aarch64, 0x03=riscv64
6       1     flags           bit0=has_knowledge, bit1=has_crypto,
                              bit2=has_simd, bit3=debug_info,
                              bit4=has_superinstructions,
                              bit5=has_capabilities, bit6=mmap_knowledge
7       1     reserved        0x00
8       4     bytecode_off    Offset to bytecode section
12      4     bytecode_size   Size of bytecode section
16      4     const_off       Offset to constant pool
20      4     const_size      Size of constant pool
24      4     func_off        Offset to function table
28      4     func_size       Size of function table
32      4     know_off        Offset to knowledge section
36      4     know_size       Size of knowledge section
40      4     checksum        CRC32 of all sections
44      4     reserved2       0x00000000
```

### 5.3 Constant Pool

```
Entry format: [type:1][len:4][data:N]

Types:
  0x01 = String (UTF-8 bytes)
  0x02 = Number (f64, 8 bytes)
  0x03 = Molecule (u16, 2 bytes)
  0x04 = Chain (u16 array)
  0x05 = Blob (raw bytes)

Referenced by index in bytecode:
  PushConst [index:4] → load constant_pool[index] → push stack
```

### 5.4 Function Table

```
Entry: [name_hash:4][bytecode_offset:4][param_count:1][local_count:1][flags:2]

Flags:
  bit0 = is_closure
  bit1 = is_builtin
  bit2 = is_exported
  bit3 = is_molecular (operates on P_weight)
  bit4 = is_pure (no side effects — can be cached/parallelized)

Lookup: hash(name) → scan function table → found → jmp to offset
```

---

## §6 VARIABLE SYSTEM — M2 var_matrix

### 6.1 Architecture

```
var_matrix: array of 65,536 entries
Entry size: 16 bytes = [gen:2][flags:2][hash_hi:4][ptr:8]
Total size: 65,536 × 16 = 1 MB

Alternative compact layout:
Entry size: 24 bytes = [gen:2][flags:2][hash_full:4][ptr:8][len:8]
Total size: 65,536 × 24 = 1.5 MB

Index = hash(name) & 0xFFFF
```

### 6.2 Generation-Based Scoping

```
Global state:
  current_gen: u16 = 0   (incremented on function call)

Store(name, value):
  idx = hash(name) & 0xFFFF
  if var_matrix[idx].hash_hi == hash_hi(name):
    // Same variable, update in place
    var_matrix[idx] = { gen: current_gen, ptr, len }
  else:
    // Collision: linear probe (max 8 steps)
    for i in 1..8:
      idx2 = (idx + i) & 0xFFFF
      if var_matrix[idx2].gen < current_gen OR var_matrix[idx2].flags == EMPTY:
        var_matrix[idx2] = { gen: current_gen, hash_hi, ptr, len }
        break

Load(name):
  idx = hash(name) & 0xFFFF
  entry = var_matrix[idx]
  if entry.hash_hi == hash_hi(name) AND entry.gen <= current_gen:
    return { entry.ptr, entry.len }
  // Linear probe for collision
  for i in 1..8:
    idx2 = (idx + i) & 0xFFFF
    if var_matrix[idx2].hash_hi == hash_hi(name):
      return { entry.ptr, entry.len }
  → variable not found error

Function call:  current_gen++
Function return: current_gen--
  All entries with gen > current_gen become invisible.
  NO CLEANUP needed. O(1) scope enter/exit.
```

### 6.3 Why This Solves THE BOMB

```
BEFORE (var_table):
  Store:   append entry to flat array → O(1) but LEAKS
  Load:    reverse scan array → O(n), degrades over time
  Scope:   no cleanup → entries accumulate FOREVER
  Result:  crash after ~10K variables

AFTER (var_matrix):
  Store:   write to hash slot → O(1), overwrites stale
  Load:    read from hash slot → O(1), constant time
  Scope:   gen counter → O(1) enter/exit, no cleanup
  Result:  never crashes, 65K variables supported

Memory: 1 MB fixed (vs var_table growing without bound)
```

### 6.4 Collision Handling

```
Strategy: Open addressing with linear probe, max 8 steps.

Why 8:
  - 65,536 slots with typically <1000 active variables = 1.5% load
  - At 1.5% load, probability of 8-step probe chain ≈ 0
  - Even at 10% load (6,553 vars): P(probe≥8) < 10⁻⁸

If probe chain exceeds 8:
  → Runtime error "var_matrix full" (should never happen in practice)
  → User should reduce scope depth or variable count

Hash quality:
  FNV-1a on variable name bytes → good distribution
  hash_hi = upper 32 bits for collision disambiguation
  index = lower 16 bits for slot selection
```

---

## §7 MOLECULAR ENGINE (Native u16)

### 7.1 P_weight Format

```
u16 P_weight = [S:4][R:4][V:3][A:3][T:2]

Bit layout (MSB to LSB):
  Bits 15-12: S (Shape)     — 0..15 → 16 shape classes
  Bits 11-8:  R (Relation)  — 0..15 → 16 relation types
  Bits 7-5:   V (Valence)   — 0..7  → 8 valence levels
  Bits 4-2:   A (Arousal)   — 0..7  → 8 arousal levels
  Bits 1-0:   T (Time)      — 0..3  → 4 temporal states

Total: 16 × 16 × 8 × 8 × 4 = 65,536 unique molecules
```

### 7.2 Pack/Unpack Operations

```asm
; MolPack: S,R,V,A,T (5 values on stack) → u16
mol_pack:
  ; Pop T (0-3), A (0-7), V (0-7), R (0-15), S (0-15) from stack
  ; Pack: (S << 12) | (R << 8) | (V << 5) | (A << 2) | T
  shl  rax, 12          ; S << 12
  shl  rcx, 8           ; R << 8
  or   rax, rcx
  shl  rdx, 5           ; V << 5
  or   rax, rdx
  shl  rsi, 2           ; A << 2
  or   rax, rsi
  or   rax, rdi         ; T
  ; Push as molecule type (len = MOL_SENTINEL)

; MolUnpack: u16 → S,R,V,A,T (5 values on stack)
mol_unpack:
  mov  rcx, rax
  shr  rcx, 12
  and  rcx, 0xF         ; S
  mov  rdx, rax
  shr  rdx, 8
  and  rdx, 0xF         ; R
  mov  rsi, rax
  shr  rsi, 5
  and  rsi, 0x7         ; V
  mov  rdi, rax
  shr  rdi, 2
  and  rdi, 0x7         ; A
  and  rax, 0x3         ; T
  ; Push S, R, V, A, T
```

### 7.3 5D Distance (Integer, No Float)

```
distance_5d(mol_a, mol_b) → u16:

  ΔS = |S_a - S_b|       (0..15)
  ΔR = |R_a - R_b|       (0..15)
  ΔV = |V_a - V_b| × 2   (0..14, scaled for 3-bit range)
  ΔA = |A_a - A_b| × 2   (0..14, scaled)
  ΔT = |T_a - T_b| × 4   (0..12, scaled for 2-bit range)

  distance = ΔS + ΔR + ΔV + ΔA + ΔT

Scaling factors compensate for different bit widths:
  S,R: 4 bits → range 0..15 → weight 1
  V,A: 3 bits → range 0..7  → weight 2 (scale up)
  T:   2 bits → range 0..3  → weight 4 (scale up)

Max distance = 15 + 15 + 14 + 14 + 12 = 70
Fits in u8. No float needed. Pure integer.

Alternative: weighted Euclidean
  d² = w_S×ΔS² + w_R×ΔR² + w_V×ΔV² + w_A×ΔA² + w_T×ΔT²
  Still integer if weights are small integers.
```

### 7.4 Compose Rules (Non-Commutative)

```
compose(A, B) → C:

  S: Union (max)
    C.S = max(A.S, B.S)
    Rationale: largest shape dominates visual complexity

  R: Weighted Average (Zipf)
    C.R = (A.R × w_a + B.R × w_b) / (w_a + w_b)
    Zipf: w_a = 1000/1 = 1000, w_b = 1000/2 = 500
    First element weighted 2× (order matters)

  V: Amplify (biological synergy, NOT average)
    base = (A.V + B.V) / 2
    boost = |A.V - base| × w × 0.5
    C.V = base + sign(A.V + B.V) × boost
    Where w = max silk weight between A and B (default 1.0)

  A: Max (one spike = loud room)
    C.A = max(A.A, B.A)
    Rationale: intensity defined by peak, not average

  T: Dominant (stable wins)
    C.T = mode(A.T, B.T) or max if no mode
    Rationale: temporal state tends toward stability

  ALL as integer arithmetic:
    S: max → cmp + cmov
    R: weighted avg → mul + add + div (shift if power of 2)
    V: amplify → sub + abs + shr + add (all integer)
    A: max → cmp + cmov
    T: max → cmp + cmov
```

### 7.5 Dominant Dimension

```
dominant_dimension(mol) → 0..4:

  Given mol = [S:4][R:4][V:3][A:3][T:2]:
  
  Normalize to common scale (0..100):
    norm_S = S × 100 / 15    (0..100)
    norm_R = R × 100 / 15    (0..100)
    norm_V = V × 100 / 7     (0..100)
    norm_A = A × 100 / 7     (0..100)
    norm_T = T × 100 / 3     (0..100)

  dominant = argmax(norm_S, norm_R, norm_V, norm_A, norm_T)

  Returns: 0=S, 1=R, 2=V, 3=A, 4=T

  Used for: routing queries to correct silk dimension,
            determining response tone, classification.
```

---

## §8 KNOWTREE ENGINE — M3 kt_matrix

### 8.1 Architecture

```
kt_matrix: u16[65,536]
  Index = mol & 0xFFFF (molecule IS the index)
  Value = fact_index (pointer to fact array in Zone A)

kt_facts: array in Zone A
  [count:8][fact0:varies][fact1:varies]...

Each fact:
  [mol:2][chain_ptr:8][chain_len:2][text_ptr:8][text_len:4]
  [fire_count:2][weight:2][maturity:1][timestamp:4][flags:1]
  Total: ~32 bytes per fact

Collision handling:
  Multiple facts can have same mol → linked list on heap
  kt_matrix[mol] = head of linked list
  Each fact has [next:4] pointer to next fact with same mol
```

### 8.2 Operations

```
kt_store(mol, text, chain):
  idx = mol & 0xFFFF
  fact = alloc_zone_a(sizeof(fact))
  fact.mol = mol
  fact.text_ptr = text_ptr
  fact.chain_ptr = chain_ptr
  fact.fire_count = 0
  fact.weight = 0x0000
  fact.maturity = FORMULA   // initial state
  fact.next = kt_matrix[idx]
  kt_matrix[idx] = fact_index
  → O(1)

kt_load(mol):
  idx = mol & 0xFFFF
  fact_idx = kt_matrix[idx]
  if fact_idx == 0: return NOT_FOUND
  return facts[fact_idx]
  → O(1) exact match

kt_nearest(query_mol, max_results):
  // Scan 5D neighbors in expanding radius
  // Radius 1: 3^5 = 243 neighbors (each dim ±1)
  // Radius 2: 5^5 = 3125 neighbors (each dim ±2)
  
  for radius in 1..max_radius:
    for ΔS in -radius..+radius:
      for ΔR in -radius..+radius:
        for ΔV in -radius..+radius:
          for ΔA in -radius..+radius:
            for ΔT in -radius..+radius:
              neighbor_mol = pack(S+ΔS, R+ΔR, V+ΔV, A+ΔA, T+ΔT)
              if kt_matrix[neighbor_mol] != 0:
                results.push(neighbor_mol, distance)
    if results.count >= max_results: break
  
  sort results by distance
  return results[:max_results]
  → O(243) for radius 1 = O(1) constant
  → O(3125) for radius 2 = still O(1) constant
```

### 8.3 Fractal Depth Extension

```
Current: flat u16 addressing (65,536 slots)
Future: fractal tree for deeper addressing

Level 0: kt_matrix[mol]           → 65,536 top-level groups
Level 1: kt_matrix[mol].children  → each group has 65,536 children
Level 2+: recursive

Addressing: [L0_mol:2][L1_mol:2][L2_mol:2]...
  Depth 2: 65,536² = 4.3 billion unique addresses
  Depth 3: 65,536³ = 281 trillion

Implementation: each kt_matrix entry can point to a sub-matrix:
  Entry value:
    bit 15 = 0 → fact_index (leaf node)
    bit 15 = 1 → sub_matrix_ptr (branch node)

This gives infinite depth WITHOUT changing the u16 instruction set.
```

---

## §9 SILK ENGINE — M5 silk_matrix

### 9.1 Three Types of Silk

```
TYPE 1: IMPLICIT (0 bytes, computed on demand)
  37 channels × dimension masks
  dist_implicit(mol_a, mol_b, channel) = distance on masked dimensions
  
  Example channels:
    "Shape" → compare S only
    "Valence" → compare V only
    "ShapeRelation" → compare S+R only
    "AllButTime" → compare S+R+V+A, ignore T
    "Full" → compare all 5 dimensions

TYPE 2: HEBBIAN (learned, stored in silk_matrix)
  Edges created by co-activation
  Weight updated by: Δw = emotion_factor × (1 - w) × 0.1
  Decay: w × φ⁻¹^(Δt/24h)

TYPE 3: STRUCTURAL (0 bytes, implicit in chain order)
  Position in chain = relationship
  chain[0] before chain[1] → temporal precedence
  chain parent → chain child → containment

Only Type 2 requires storage. Types 1 and 3 are computed.
```

### 9.2 silk_matrix Layout

```
silk_matrix: u16[65,536]
  Index = hash(mol_a, mol_b) & 0xFFFF
  Value = edge_index (pointer to edge array in Zone A)

  Hash: (mol_a XOR mol_b) combined with (mol_a + mol_b)
    idx = ((mol_a ^ mol_b) * 0x9E37 + (mol_a + mol_b)) & 0xFFFF
    Symmetric: silk(A,B) == silk(B,A) ← same hash

Each edge (Zone A):
  [mol_a:2][mol_b:2][weight:2][emotion_V:1][emotion_A:1]
  [fire_count:2][last_fire:4][type:1][next:4]
  Total: 18 bytes per edge

Collision: linked list (same as kt_matrix)
```

### 9.3 Hebbian Learning

```
silk_fire(mol_a, mol_b, context_V, context_A):
  idx = silk_hash(mol_a, mol_b) & 0xFFFF
  edge = find_or_create(silk_matrix[idx], mol_a, mol_b)
  
  // Emotion amplification (cortisol/adrenaline model)
  emotion_factor = (|context_V| + |context_V|) / 2.0 × max(context_A, 1) / 7.0
  
  // Hebbian update (bounded, approaches 1.0 asymptotically)
  Δw = emotion_factor × (1.0 - edge.weight) × 0.1
  edge.weight += Δw
  
  // Clamp to [0, 1] range (u16: 0..65535 maps to 0.0..1.0)
  edge.weight = min(edge.weight, 0xFFFF)
  
  edge.fire_count++
  edge.last_fire = current_time
  
  // Determine silk TYPE from dominant delta dimension
  type = dominant_delta(mol_a, mol_b)
  edge.type = type   // 0=S, 1=R, 2=V, 3=A, 4=T
```

### 9.4 Decay (Golden Ratio)

```
silk_decay_all(current_time):
  for each edge in silk_matrix:
    Δt = current_time - edge.last_fire
    hours = Δt / 3600
    
    // φ⁻¹ = 0.618, decay per 24 hours
    // w(t) = w₀ × 0.618^(hours/24)
    // As integer: w = w × 618 / 1000 per 24h
    
    decay_periods = hours / 24
    for i in 0..decay_periods:
      edge.weight = edge.weight × 618 / 1000
    
    // Prune dead edges
    if edge.weight < PRUNE_THRESHOLD AND edge.fire_count == 0:
      edge.flags |= SUPERSEDED

Schedule: run during dream cycle or when idle > 5 minutes
```

### 9.5 Silk Walk (Multi-Hop Reasoning)

```
silk_walk(start_mol, target_dim, max_depth, max_results):
  visited = bitmap[65536]   // 8 KB, Zone C
  queue = [start_mol]
  results = []
  
  for depth in 0..max_depth:
    next_queue = []
    for mol in queue:
      if visited[mol]: continue
      visited[mol] = 1
      
      // Follow Hebbian edges on target dimension
      for edge in silk_edges(mol):
        if edge.type == target_dim AND edge.weight > φ⁻¹_threshold:
          other = (edge.mol_a == mol) ? edge.mol_b : edge.mol_a
          results.push({ mol: other, depth, weight: edge.weight })
          next_queue.push(other)
      
      // Also follow implicit silk (computed, not stored)
      for neighbor in kt_neighbors(mol, target_dim, radius=1):
        if not visited[neighbor]:
          results.push({ mol: neighbor, depth, weight: implicit_weight })
          next_queue.push(neighbor)
    
    queue = next_queue
    if results.count >= max_results: break
  
  sort results by weight (descending)
  return results[:max_results]
```

---

## §10 ARENA ALLOCATOR — 3-Zone

### 10.1 Zone Design

```
Zone A — PERMANENT (never freed during lifetime)
  Purpose: KnowTree facts, QR records, silk edges, permanent strings
  Grows: monotonically upward
  Reset: NEVER (data persists across sessions)
  Backed: memory-mapped file (optional, for persistence)
  
  alloc_a(size):
    ptr = zone_a_ptr
    zone_a_ptr += align8(size)
    if zone_a_ptr >= zone_a_limit: OOM_permanent → trigger dream/prune
    return ptr

Zone B — SESSION (freed when session ends)
  Purpose: Session-scope data, compiled bytecode, temp indices
  Grows: downward from zone_b_top
  Reset: at session end → zone_b_ptr = zone_b_top
  
  alloc_b(size):
    zone_b_ptr -= align8(size)
    if zone_b_ptr <= zone_a_ptr: OOM_session → force session end
    return zone_b_ptr

Zone C — TURN (freed every response cycle)
  Purpose: Pipeline temporaries, compose intermediates, search buffers
  Grows: from zone_c_base upward
  Reset: after each pipeline cycle → zone_c_ptr = zone_c_base
  
  alloc_c(size):
    ptr = zone_c_ptr
    zone_c_ptr += align8(size)
    if zone_c_ptr >= zone_b_ptr: OOM_turn → truncate response
    return ptr

Memory layout:
  [VM Stack 16MB][Zone C →][← Zone B][Zone A →][matrices][bytecode]
```

### 10.2 No GC, No Fragmentation

```
Why arena over GC:
  1. DETERMINISTIC: no GC pauses during pipeline execution
  2. SIMPLE: alloc = bump pointer (3 instructions)
  3. FAST: reset = restore pointer (1 instruction)
  4. NO FRAGMENTATION: zones reset cleanly
  5. CACHE FRIENDLY: sequential allocation = sequential access

Why 3 zones (not 1 or 2):
  1 zone: can't free anything → exhausts memory
  2 zones: session vs permanent → turns still accumulate within session
  3 zones: turn temps freed every cycle → steady-state memory usage

Worst case memory per turn:
  Zone C usage = pipeline buffers ≈ 64 KB
  Zone B growth = learned facts ≈ 1 KB per learn
  Zone A growth = permanent ≈ 100 bytes per fact
  
  1000 turns × 100 bytes = 100 KB Zone A growth per session
  At 4 GB total: ~40,000 sessions before OOM
  With persistence: effectively infinite (restart reclaims B+C)
```

### 10.3 Heap Pin (Backward Compat)

```
heap_pin():
  Save current zone_c_ptr as "pin point"
  Next alloc_c starts from pin point
  Used when Zone C data must survive one extra cycle
  (e.g., kt_learn allocates in C, then promotes to A)

Implementation:
  zone_c_pin = zone_c_ptr   // save
  // ... do work in Zone C ...
  // On next reset_c:
  if zone_c_pin != 0:
    // copy pinned data to Zone A
    memcpy(alloc_a(pinned_size), zone_c_pin, pinned_size)
    zone_c_pin = 0
  zone_c_ptr = zone_c_base
```

---

## §11 ARRAY ENGINE — O(1) Push

### 11.1 Array Layout

```
Array on heap:
  [capacity:8][count:8][elem0_ptr:8][elem0_len:8][elem1_ptr:8][elem1_len:8]...

capacity = number of allocated slots (power of 2)
count = number of used slots
Each element = 16 bytes (same as stack entry)
```

### 11.2 O(1) Amortized Push

```
array_push(array_ptr, value):
  count = load(array_ptr + 8)
  capacity = load(array_ptr)
  
  if count < capacity:
    // FAST PATH: O(1)
    offset = 16 + count × 16
    store(array_ptr + offset, value.ptr)
    store(array_ptr + offset + 8, value.len)
    store(array_ptr + 8, count + 1)
    return
  
  // SLOW PATH: realloc 2× (amortized O(1))
  new_cap = capacity × 2
  new_array = alloc(16 + new_cap × 16)
  memcpy(new_array, array_ptr, 16 + capacity × 16)
  store(new_array, new_cap)
  
  // Leave FORWARD MARKER at old location
  store(array_ptr, ARRAY_FORWARD_MARKER)
  store(array_ptr + 8, new_array)
  
  // Push to new array
  array_push(new_array, value)

FORWARD MARKER:
  When array relocates, old location stores pointer to new location.
  Any reference following old pointer → detect marker → redirect.
  capacity == 0xFFFFFFFFFFFFFFFE → forward marker → follow ptr at +8
```

### 11.3 Array With Initial Capacity

```
array_with_cap(initial_capacity):
  // Allocate with pre-known capacity (avoids early reallocs)
  cap = next_power_of_2(initial_capacity)
  array = alloc(16 + cap × 16)
  store(array, cap)
  store(array + 8, 0)   // count = 0
  return array

Usage pattern (Olang):
  let arr = __array_with_cap(1024);
  // 1024 pushes without any reallocation
```

---

## §12 STRING ENGINE — UTF-8 Native

### 12.1 String Representation

```
On heap: raw UTF-8 bytes (no header, no null terminator needed)
On stack: [ptr:8][len:8] where len = byte count

Immutable: strings never modified in place.
  concat(a, b) → new string = alloc(a.len + b.len) + memcpy
  substr(a, start, end) → new ptr = a.ptr + byte_offset, new len
    (zero-copy if within same allocation)
```

### 12.2 Safe Substring (Fixed Bug)

```asm
; CURRENT BUG: mov eax, [ptr] corrupts upper 32 bits
; FIX: always use movzx for partial reads

safe_substr:
  ; Input: string_ptr, start_codepoint, end_codepoint
  ; Walk UTF-8 to find byte offsets
  
  xor rcx, rcx          ; current codepoint index
  mov rsi, [string_ptr]  ; current byte position
  
.find_start:
  cmp rcx, start_codepoint
  je .found_start
  ; Advance one UTF-8 codepoint
  movzx eax, byte [rsi]  ; ← movzx, NOT mov (safe upper bits)
  ; Determine UTF-8 byte length from first byte
  cmp al, 0x80
  jb .one_byte
  cmp al, 0xE0
  jb .two_byte
  cmp al, 0xF0
  jb .three_byte
  ; four byte
  add rsi, 4
  jmp .next_cp
.one_byte:   add rsi, 1 ; jmp .next_cp
.two_byte:   add rsi, 2 ; jmp .next_cp
.three_byte: add rsi, 3
.next_cp:
  inc rcx
  jmp .find_start
  
.found_start:
  mov rdi, rsi  ; start byte offset
  ; Continue to find end...
```

### 12.3 UTF-8 Codepoint Operations

```
utf8_len(str):     Count codepoints (not bytes)
utf8_cp(str, idx): Get codepoint at index (returns u32)
utf8_encode(cp):   Encode codepoint to UTF-8 bytes
utf8_decode(ptr):  Decode UTF-8 bytes to codepoint

All O(n) for arbitrary index access (UTF-8 is variable-width).
For O(1) access: build index table or use codepoint arrays.
```

---

## §13 FUNCTION CALLS & CLOSURES

### 13.1 Call Convention

```
Caller:
  1. Push arguments onto VM stack (left to right)
  2. Emit Call [hash:4]

Dispatch:
  hash = read 4 bytes from bytecode
  1. Check builtin_table[hash & 0x1FF]
     → if match: jump to builtin handler
  2. Check function_table[hash]
     → if match: jump to bytecode offset
  3. Check var_matrix (might be closure)
     → if closure marker: invoke closure
  4. Error: function not found

Callee:
  1. EnterFrame(N) — allocate register frame
  2. StoreReg(0), StoreReg(1), ... — pop args into registers
  3. Execute body
  4. Push return value
  5. LeaveFrame
  6. Ret

Stack cleanup: callee responsibility (Ret restores caller's stack frame)
```

### 13.2 Closure Implementation

```
Simple closure (no captures):
  [body_pc:8] on heap
  Invoked: jump to body_pc, execute, return

Captured closure:
  [body_pc:8][capture_count:8]
  [cap0_hash:8][cap0_ptr:8][cap0_len:8]
  [cap1_hash:8][cap1_ptr:8][cap1_len:8]
  ...

  Capture: at closure creation, snapshot current variable values
  Invoke: restore captured values into new scope, then execute body

Optimization: captured closures allocated in Zone B (session-scoped)
  → automatically freed on session end
  → no reference counting needed
```

### 13.3 Tail Call Optimization

```
When last expression in function is a call:
  Instead of: Call → new frame → Ret → old frame
  Do:         Reuse current frame → Jmp to target

Detection: compiler marks tail-position calls with flag
Bytecode: TailCall [hash:4] — same as Call but reuses frame

Benefit: recursive algorithms don't grow stack
  fibonacci(1000000) → constant stack usage
```

---

## §14 EXCEPTION HANDLING

### 14.1 Try/Catch Mechanism

```
TryBegin [catch_offset:4]:
  Push exception handler onto handler stack (CPU stack):
    [catch_pc:8][vm_stack_ptr:8][reg_frame_ptr:8]
  
  If exception occurs between TryBegin and CatchEnd:
    → Restore VM stack to saved state
    → Restore register frame
    → Jump to catch_pc
    → Exception message available via __catch_value()

Throw(msg):
  If handler stack non-empty:
    Pop handler → restore state → jump to catch_pc
  If handler stack empty:
    Print error → Halt VM

CatchEnd:
  Pop handler from stack (normal exit, no exception)
```

### 14.2 Exception Safety

```
Zone C allocations during try block:
  → Automatically freed on exception (Zone C reset is safe)

Zone A allocations during try block:
  → NOT rolled back (permanent data survives exceptions)
  → Use heap_pin + manual cleanup if needed

Invariant: exceptions never corrupt Zone A data.
  KnowTree facts, QR records → always consistent.
```

---

## §15 CONCURRENCY MODEL — Multi-Mouth

### 15.1 Architecture

```
┌──────────────────────────────────────────────┐
│                 NOX BRAIN                     │
│     (single process, single thread)          │
│                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ Zone A   │  │ kt_matrix│  │silk_matrix│  │
│  │ (shared  │  │ (shared  │  │ (shared   │  │
│  │  read)   │  │  read)   │  │  read)    │  │
│  └──────────┘  └──────────┘  └──────────┘  │
│                                              │
│  ┌──────────────────────────────────────┐    │
│  │        REQUEST QUEUE                  │    │
│  │  [mouth_id:4][type:1][payload:N]      │    │
│  │  FIFO ordering, atomic enqueue        │    │
│  └──────────────────────────────────────┘    │
│                                              │
│  ┌──────────────────────────────────────┐    │
│  │        RESPONSE QUEUE                 │    │
│  │  [mouth_id:4][payload:N]              │    │
│  └──────────────────────────────────────┘    │
└──────────────────────────────────────────────┘
         │              │             │
    ┌────┴────┐   ┌────┴────┐  ┌────┴────┐
    │ Mouth 0 │   │ Mouth 1 │  │ Mouth 2 │
    │ (CLI)   │   │ (TCP)   │  │ (HTTP)  │
    └─────────┘   └─────────┘  └─────────┘
```

### 15.2 Single-Threaded Brain

```
Why NOT multi-threaded:
  1. Brain state (KnowTree, Silk) is ONE consciousness
  2. Learning must be sequential (Hebbian order matters)
  3. Dream must see consistent state
  4. Complexity: locks + races = bugs in ASM
  5. Current CPU: i3-4150 (2 cores) → threading overhead > benefit

Instead: event loop
  loop:
    poll(file_inbox, tcp_socket, http_socket, timeout=100ms)
    for each ready fd:
      msg = read(fd)
      response = pipeline(msg)  // full 14-mechanism pipeline
      write(fd, response)
    
    if idle > 300s:
      dream_cycle()
    
    if heartbeat_due:
      interoception()

All I/O is non-blocking. Brain processes one request at a time.
Mouths queue requests. Brain drains queue sequentially.
```

### 15.3 Mouth Protocol (JARVIS)

```
File-based (Phase 1, current):
  Request:  write to /tmp/nox_inbox
  Response: read from /tmp/nox_outbox
  Watch:    inotify on inbox

TCP (Phase 2):
  Port: 9100
  Protocol: [len:4][type:1][payload:N]
  Types:
    0x01 = QUERY (text → response)
    0x02 = OBSERVE (text + type → learn)
    0x03 = SEARCH (query → results)
    0x04 = STATUS (→ brain state)
    0x05 = DREAM (trigger dream cycle)

HTTP (Phase 3):
  Port: 9000
  Endpoints:
    POST /query     { text: "..." } → { response: "...", confidence: 0.85 }
    POST /observe   { text: "...", type: "learn" } → { ok: true }
    GET  /search?q= → [{ text, mol, score }]
    GET  /status    → { facts, silk_edges, uptime, heap_usage }
    GET  /dashboard → HTML dashboard
```

---

## §16 SIMD BATCH OPERATIONS

### 16.1 SSE2 Molecular Batch Distance

```asm
; Compute distance from query_mol to 8 candidate molecules simultaneously
; Input: xmm0 = query_mol broadcast (8 × u16)
;        rsi = pointer to candidate array (u16[])
;        rcx = count
; Output: xmm1 = 8 distances (u16[])

mol_batch_dist_8:
  movdqu xmm0, [query_broadcast]  ; 8 copies of query mol
  
.loop:
  movdqu xmm1, [rsi]              ; load 8 candidate mols
  
  ; Unpack S dimension (bits 15-12)
  movdqa xmm2, xmm0
  movdqa xmm3, xmm1
  psrlw  xmm2, 12                 ; query S
  psrlw  xmm3, 12                 ; candidate S
  psubw  xmm2, xmm3
  pabsw  xmm2, xmm2               ; |ΔS|
  
  ; Unpack R dimension (bits 11-8)
  movdqa xmm4, xmm0
  movdqa xmm5, xmm1
  psrlw  xmm4, 8
  pand   xmm4, [mask_0F]          ; query R
  psrlw  xmm5, 8
  pand   xmm5, [mask_0F]          ; candidate R
  psubw  xmm4, xmm5
  pabsw  xmm4, xmm4               ; |ΔR|
  paddw  xmm2, xmm4               ; accumulate
  
  ; Unpack V dimension (bits 7-5)
  movdqa xmm4, xmm0
  movdqa xmm5, xmm1
  psrlw  xmm4, 5
  pand   xmm4, [mask_07]
  psrlw  xmm5, 5
  pand   xmm5, [mask_07]
  psubw  xmm4, xmm5
  pabsw  xmm4, xmm4
  psllw  xmm4, 1                  ; ×2 scale factor
  paddw  xmm2, xmm4
  
  ; Unpack A dimension (bits 4-2)
  movdqa xmm4, xmm0
  movdqa xmm5, xmm1
  psrlw  xmm4, 2
  pand   xmm4, [mask_07]
  psrlw  xmm5, 2
  pand   xmm5, [mask_07]
  psubw  xmm4, xmm5
  pabsw  xmm4, xmm4
  psllw  xmm4, 1                  ; ×2 scale factor
  paddw  xmm2, xmm4
  
  ; Unpack T dimension (bits 1-0)
  movdqa xmm4, xmm0
  movdqa xmm5, xmm1
  pand   xmm4, [mask_03]
  pand   xmm5, [mask_03]
  psubw  xmm4, xmm5
  pabsw  xmm4, xmm4
  psllw  xmm4, 2                  ; ×4 scale factor
  paddw  xmm2, xmm4
  
  ; xmm2 now has 8 distances
  movdqu [results + offset], xmm2
  
  add rsi, 16                     ; next 8 mols
  sub rcx, 8
  jg .loop

Throughput: 8 molecules per iteration
  500K mols ÷ 8 = 62,500 iterations
  ~3 clocks/iteration = ~188K clocks = ~60 μs at 3 GHz
  vs scalar: 500K × ~15 clocks = ~7.5M clocks = ~2.5 ms
  → 40× speedup
```

### 16.2 Batch KnowTree Nearest

```
kt_nearest_batch(query_mol, count):
  // Broadcast query mol to all 8 lanes
  movd xmm0, query_mol
  pshuflw xmm0, xmm0, 0
  punpcklqdq xmm0, xmm0  // 8 copies
  
  // Scan Zone A fact array in chunks of 8
  best_dist = 0xFFFF
  best_idx = -1
  
  for i in 0..fact_count step 8:
    load 8 fact mols from kt_facts[i..i+8]
    distances = mol_batch_dist_8(query, facts)
    min_in_batch = horizontal_min(distances)
    if min_in_batch < best_dist:
      best_dist = min_in_batch
      best_idx = i + lane_of_min
  
  return kt_facts[best_idx]
```

---

## §17 SELF-MODIFICATION PROTOCOL

### 17.1 Safety Requirements

```
RULE 1: NEVER modify Zone A directly during self-modify
RULE 2: ALWAYS backup before modify
RULE 3: ALWAYS test after modify (make test)
RULE 4: ALWAYS verify fixed-point (Gen1 == Gen2)
RULE 5: MAX 1 file per self-modify cycle
RULE 6: ROLLBACK on any failure

Cycle:
  ① INSPECT: read source files, identify target
  ② BACKUP: cp target target.bak
  ③ MODIFY: write changes to source
  ④ BUILD: make vm && make self-build
  ⑤ TEST: make test
  ⑥ VERIFY: make fixed-point (Gen1 == Gen2)
  ⑦ SUCCESS → commit, observe("self-modified: description")
  ⑧ FAILURE → cp target.bak target, observe("self-modify failed: reason")
```

### 17.2 Hot-Reload Capability

```
Future: modify bytecode in memory without restart

hot_reload(new_bytecode):
  1. Validate new bytecode (checksum, header, function table)
  2. Pause request processing (drain queue)
  3. Save brain state (KnowTree → file, Silk → file, STM → file)
  4. Replace bytecode section in memory
  5. Rebuild function table
  6. Rebuild builtin table (if new builtins added)
  7. Resume request processing
  8. Verify: run self-test suite

Constraint: Zone A data survives hot-reload.
  Only bytecode + function table change.
  KnowTree, Silk, QR records → preserved.
```

### 17.3 Extension Points

```
Builtin slots 0x100-0x1FF: reserved for self-defined operations.

self_define_builtin(name, bytecode_offset):
  hash = fnv1a(name) & 0x1FF
  if hash < 0x100: error "reserved range"
  builtin_table[hash] = bytecode_offset
  → New operation callable from Olang code

Use case: Nox defines new mathematical operations,
  registers them as builtins, uses them in pipeline.
  No VM restart needed.
```

---

## §18 SYSCALL INTERFACE

### 18.1 Linux Syscall Table

```
The VM uses raw Linux syscalls (no libc):

Syscall  │ Number │ Usage
─────────┼────────┼──────────────────────────
read     │ 0      │ stdin, file, socket input
write    │ 1      │ stdout, file, socket output
open     │ 2      │ file open
close    │ 3      │ file/socket close
mmap     │ 9      │ memory allocation (4GB arena)
munmap   │ 11     │ memory release
socket   │ 41     │ TCP/UDP socket creation
connect  │ 42     │ TCP client connect
accept   │ 43     │ TCP server accept
sendto   │ 44     │ UDP send
recvfrom │ 45     │ UDP receive
bind     │ 49     │ bind socket to address
listen   │ 50     │ listen for connections
poll     │ 7      │ non-blocking I/O multiplexing
clone    │ 56     │ process creation (spawn)
exit     │ 60     │ process exit
kill     │ 62     │ send signal to process
pipe     │ 22     │ create pipe (IPC)
inotify  │ 253/254│ file system monitoring
nanosleep│ 35     │ sleep with nanosecond precision
clock_get│ 228    │ high-resolution time
getrandom│ 318    │ cryptographic random bytes
```

### 18.2 Syscall Wrapper

```asm
; Unified syscall wrapper
; Input: rax=syscall_nr, rdi=arg1, rsi=arg2, rdx=arg3, r10=arg4, r8=arg5, r9=arg6
; Output: rax=return value (negative = error)

do_syscall:
  syscall
  test rax, rax
  js .syscall_error
  ret

.syscall_error:
  neg rax            ; error code = -rax
  ; Store error for __errno() builtin
  mov [last_errno], rax
  mov rax, -1
  ret
```

---

## §19 BYTECODE SECURITY

### 19.1 Bounds Checking

```
Every bytecode read checks: r13 < rbx (PC < bytecode_size)
  → prevents buffer overrun from malformed bytecode

Every memory access checks zone boundaries:
  Zone C: zone_c_base ≤ addr < zone_c_ptr
  Zone B: zone_b_ptr ≤ addr < zone_b_top
  Zone A: zone_a_base ≤ addr < zone_a_ptr
  Stack:  stack_base ≤ r14 < stack_top

Stack overflow: r14 < stack_guard → trap
Heap overflow: r15 > zone_limit → OOM handler
```

### 19.2 SecurityGate Integration

```
SecurityGate runs BEFORE pipeline:
  Layer 1: Bloom filter (200KB, O(1)) — keyword match
  Layer 2: Normalization (O(n)) — strip evasion
  Layer 3: Semantic (O(depth)) — V < 1 AND A > 6 → crisis

SecurityGate runs AFTER response:
  Check output for unsafe content before sending to mouth

VM instruction: CheckSecurity [type:1]
  type 0 = input check
  type 1 = output check
  Pushes: 0 (safe) or 1 (blocked)
```

### 19.3 Self-Build Integrity

```
Fixed-point verification:
  Gen0 compiles source → Gen1
  Gen1 compiles source → Gen2
  REQUIRE: sha256(Gen1) == sha256(Gen2)

If hashes differ: compilation is NON-DETERMINISTIC
  → bug in compiler (side effects, timing, randomness)
  → MUST fix before deploying

The SHA-256 is computed by the VM itself (builtin).
No external tools needed for verification.
```

---

## §20 BOOT SEQUENCE

### 20.1 Startup

```
_start:
  ; 1. Allocate memory
  mov rax, 9              ; mmap
  xor rdi, rdi            ; addr = NULL (kernel chooses)
  mov rsi, 0x100000000    ; 4 GB
  mov rdx, 3              ; PROT_READ | PROT_WRITE
  mov r10, 0x22           ; MAP_PRIVATE | MAP_ANONYMOUS
  mov r8, -1              ; fd = -1
  xor r9, r9              ; offset = 0
  syscall
  mov r15, rax            ; heap base = mmap result
  
  ; 2. Partition zones
  mov [zone_a_base], r15
  add r15, ZONE_A_INITIAL ; skip initial Zone A space
  mov [zone_c_base], r15
  mov [zone_c_ptr], r15
  ; Zone B grows down from top
  lea rax, [r15 + TOTAL_SIZE]
  mov [zone_b_top], rax
  mov [zone_b_ptr], rax
  
  ; 3. Initialize VM stack
  ; Stack at bottom of mmap, 16 MB
  lea r14, [mmap_base + 0x800000]  ; stack midpoint (guard)
  
  ; 4. Clear matrices
  mov rdi, [var_matrix_base]
  mov rcx, 65536 * 2       ; 16 bytes × 65536 = 1MB / 8
  xor rax, rax
  rep stosq                 ; zero var_matrix
  
  mov rdi, [kt_matrix_base]
  mov rcx, 65536 / 4        ; 2 bytes × 65536 = 128KB / 8
  rep stosq                 ; zero kt_matrix
  
  mov rdi, [silk_matrix_base]
  mov rcx, 65536 / 4
  rep stosq                 ; zero silk_matrix
  
  ; 5. Load bytecode
  ; Find bytecode in ELF or trailer
  call find_bytecode
  mov r12, rax             ; bytecode base
  mov rbx, rdx             ; bytecode size
  xor r13, r13             ; PC = 0
  
  ; 6. Initialize generation counter
  mov word [current_gen], 0
  
  ; 7. Enter VM loop
  jmp vm_loop
```

### 20.2 Knowledge Loading

```
After bytecode starts executing:

Phase 1 — Bootstrap (first run):
  1. Load UDC data (8,284 entries → P_weight lookup table)
  2. Load NRC-VAD (44,729 words → emotion V/A)
  3. Load base knowledge (Vietnamese facts, self-knowledge)
  4. Build initial KnowTree

Phase 2 — Restore (subsequent runs):
  1. Load Zone A from memory-mapped file (if persistence enabled)
  2. Rebuild kt_matrix from Zone A facts
  3. Rebuild silk_matrix from Zone A edges
  4. Resume from saved state

Phase 3 — REPL or Daemon:
  if --daemon flag:
    bind TCP 9100
    bind HTTP 9000
    enter event loop
  else:
    enter REPL (read-eval-print loop)
```

---

## §21 CRYPTOGRAPHIC ENGINE

### 21.1 Supported Algorithms

```
SHA-256:    FIPS 180-4 compliant. 1,460 LOC ASM.
SHA-512:    339 LOC ASM.
HMAC:       HMAC-SHA256, HMAC-SHA512.
AES-256:    GCM mode (feature-gated).
Ed25519:    Signature verification (for QR signing, future).

All implemented in pure x86-64 ASM.
No external crypto libraries.
```

### 21.2 Usage

```
QR Signing:
  signature = ed25519_sign(private_key, qr_record_bytes)
  → Append signature to QR record
  → Verify on load: ed25519_verify(public_key, record, sig)

Fixed-Point:
  hash = sha256(gen1_bytecode)
  hash2 = sha256(gen2_bytecode)
  assert hash == hash2

Data Integrity:
  checksum = crc32(zone_a_data)
  → Store in header, verify on load
```

---

## §22 DEBUG & INTROSPECTION

### 22.1 Debug Mode

```
VM flag: --debug

Enables:
  - Trace: print every opcode execution
  - Inspect: print VM stack state
  - Breakpoint: pause at specific PC
  - Step: execute one opcode at a time

Trace format:
  [PC:04X] [OPCODE:02X] [MNEMONIC:12s] [STACK_DEPTH:3d] [TOP: ptr len]

Example:
  0042 15 PushNum       3  [3.14159 NUM]
  004B 26 LoadReg(0)    4  [0x7F... STR]
  004D 2A Add           3  [result NUM]
```

### 22.2 Introspection Builtins

```
__vm_stack_depth()   → current stack depth
__vm_heap_used()     → bytes allocated in each zone
__vm_fact_count()    → number of facts in KnowTree
__vm_silk_count()    → number of Hebbian edges
__vm_uptime()        → seconds since boot
__vm_gen()           → current generation counter
__vm_zone_a_used()   → bytes used in Zone A
__vm_zone_b_used()   → bytes used in Zone B
__vm_zone_c_used()   → bytes used in Zone C
__vm_var_matrix_load() → % of var_matrix slots occupied
__vm_opcode_count()  → total opcodes executed since boot
```

### 22.3 Performance Counters

```
Maintained automatically (when --perf flag):
  opcode_histogram[256]   → count per opcode type
  builtin_histogram[512]  → count per builtin call
  cache_hits              → var_matrix cache hits
  cache_misses            → var_matrix cache misses
  zone_a_allocs           → Zone A allocation count
  zone_b_allocs           → Zone B allocation count
  zone_c_allocs           → Zone C allocation count
  zone_c_resets           → Zone C reset count
  simd_batch_ops          → SIMD batch operation count

Accessed via: __vm_perf_counter(name) builtin
```

---

## §23 PERFORMANCE TARGETS

### 23.1 Benchmarks

```
Operation                │ Current   │ Target     │ Method
─────────────────────────┼───────────┼────────────┼────────────
var_lookup               │ O(n)      │ O(1)       │ var_matrix
var_store                │ O(n)+leak │ O(1)       │ var_matrix
scope_cleanup            │ O(n)      │ O(1)       │ gen counter
kt_exact_match           │ O(bucket) │ O(1)       │ kt_matrix
kt_nearest               │ O(N)      │ O(243)     │ 5D neighbor scan
silk_lookup              │ O(bucket) │ O(1)       │ silk_matrix
array_push               │ O(n²)     │ O(1) amort │ capacity header
string_compare           │ O(n²)     │ O(n)       │ no-alloc compare
mol_batch_dist (500K)    │ ~50ms     │ ~0.06ms    │ SSE2 u16
self_build               │ ~60s      │ ~5s        │ all optimizations
pipeline (single query)  │ ~100ms    │ ~10ms      │ integer mol + SIMD
boot_load (1500 facts)   │ ~30s      │ ~2s        │ arena + batch load
```

### 23.2 Memory Targets

```
Component           │ Current    │ Target     │ Method
────────────────────┼────────────┼────────────┼──────────────
var_table            │ unbounded  │ 1 MB fixed │ var_matrix
kt storage (500K)   │ 8 MB (f64) │ 1 MB (u16) │ dual-width
silk edges           │ ~100 KB    │ ~128 KB    │ silk_matrix
VM stack             │ 16 MB      │ 16 MB      │ unchanged
Total binary         │ 833 KB     │ <1 MB      │ optimized
Boot memory          │ crash>1500 │ 500K facts │ arena zones
```

### 23.3 Correctness Targets

```
Tests:           193/194 → 194/194 (fix remaining)
Fixed-point:     Gen1 == Gen2 (MUST hold after every change)
Crash-free:      No crash under any input (SecurityGate + bounds check)
Deterministic:   Same input → same output (no randomness in pipeline)
Self-host:       Origin compiles Origin (always)
```

---

## §24 MIGRATION PATH (Current → New)

### 24.1 Phase 0: Foundation (No Breaking Changes)

```
Step 0.1: Push O(1) — add capacity header to arrays (~40 LOC ASM)
  - Backward compat: old arrays detected by capacity==0
  - New arrays use __array_with_cap()
  - Test: 55K push < 1 second

Step 0.2: substr Fix — movzx instead of mov (~20 LOC ASM)
  - Pure bugfix, no interface change

Step 0.3: var_matrix — replace var_table internals (~200 LOC ASM)
  - Same bytecode (Load/Store opcodes unchanged)
  - Internal dispatch changes from scan to matrix lookup
  - Test: all 193 tests still pass
```

### 24.2 Phase 0.5: Dual-Width (Internal Optimization)

```
Step 0.4: kt_matrix — u16 native KnowTree (~100 LOC ASM)
  - New builtins: __kt_store_u16, __kt_load_u16, __kt_dist_u16
  - Existing builtins wrap with conversion
  - Test: kt_fact_count, kt_nearest still work

Step 0.5: silk_matrix — u16 native Silk (~80 LOC ASM)
  - New builtins for silk operations
  - Test: silk_fire, silk edges still work

Step 0.6: SIMD batch distance (~100 LOC ASM)
  - New builtin: __kt_batch_dist
  - Used internally by kt_nearest
  - Test: same results, 40× faster
```

### 24.3 Phase 1: Arena (Memory Architecture)

```
Step 1.1: Zone A allocation (~60 LOC ASM)
  - Replace bump allocator for permanent data
  - alloc_a() for KnowTree facts, strings
  - Test: learning 200+ facts stable

Step 1.2: Zone C allocation (~40 LOC ASM)
  - Pipeline temporaries in Zone C
  - Reset after each pipeline cycle
  - Test: steady-state memory after 1000 queries

Step 1.3: Zone B allocation (~40 LOC ASM)
  - Session data in Zone B
  - Reset on session end
  - Test: multiple sessions without memory growth
```

### 24.4 Phase 2: New Opcodes (Bytecode Extension)

```
Step 2.1: Molecule opcodes (0x40-0x47)
  - MolPack, MolUnpack, MolDist, MolCompose, etc.
  - Currently done via builtins; opcodes are faster
  - Backward compat: builtins still work

Step 2.2: KnowTree opcodes (0x50-0x54)
  - KtStore, KtLoad, KtNearest, KtWalk, KtLearn

Step 2.3: Silk opcodes (0x58-0x5B)
  - SilkFire, SilkDecay, SilkWalk, SilkImplicit

Step 2.4: Arena opcodes (0x60-0x65)
  - AllocA, AllocB, AllocC, ResetC, ResetB, HeapPin

Bytecode version: bump from 1 to 2
  Version 1 bytecode still runs (builtins path)
  Version 2 bytecode uses native opcodes (faster)
```

### 24.5 Verification at Each Step

```
AFTER EVERY STEP:
  1. make vm          (assemble new VM)
  2. make self-build  (origin compiles itself)
  3. make test        (193+ tests pass)
  4. make fixed-point (Gen1 == Gen2)

If ANY step fails:
  → Rollback changes
  → Debug
  → Retry

No step ships without all 4 checks passing.
```

---

## APPENDIX A: COMPARISON WITH CURRENT VM

```
Feature            │ Current VM        │ New VM Spec
───────────────────┼───────────────────┼──────────────────
Variable lookup    │ O(n) reverse scan │ O(1) var_matrix
Variable store     │ O(1) + leak       │ O(1) no leak
Scope cleanup      │ NONE (THE BOMB)   │ O(1) gen counter
KnowTree lookup    │ O(bucket)         │ O(1) kt_matrix
Silk lookup        │ O(bucket)         │ O(1) silk_matrix
Array push         │ O(n²) relocate    │ O(1) amortized
String compare     │ O(n²) alloc       │ O(n) no alloc
Molecule width     │ f64 (8 bytes)     │ u16 (2 bytes)
SIMD support       │ None              │ SSE2 batch ops
Memory management  │ Bump (leak)       │ 3-zone arena
Concurrency        │ Single            │ Multi-mouth queue
Opcodes            │ 48                │ 64+ (extensible)
Builtins           │ 256 slots         │ 512 slots
Self-modify        │ Partial           │ Full protocol
Debug              │ Basic             │ Trace + counters
Crypto             │ SHA-256/512       │ + Ed25519 + AES
Boot time (1500)   │ ~30s (crash)      │ ~2s (stable)
```

## APPENDIX B: INSTRUCTION ENCODING QUICK REFERENCE

```
1-byte opcodes (no operand):
  Dup, Pop, Swap, Ret, Halt, Nop, Add, Sub, Mul, Div, Mod, Neg,
  Eq, Ne, Lt, Gt, Le, Ge, MolPack, MolUnpack, MolDist, MolCompose,
  MolDominant, MolEncode, MolDecode, KtStore, KtLoad, KtNearest,
  KtWalk, KtLearn, SilkFire, SilkDecay, SilkWalk, SilkImplicit,
  ResetC, ResetB, HeapPin, LeaveFrame, CatchEnd, Throw

2-byte opcodes ([op:1][u8:1]):
  LoadReg, StoreReg, EnterFrame, CallClosure, CallBuiltin

3-byte opcodes ([op:1][u16:2]):
  PushMol, MolBatchDist

5-byte opcodes ([op:1][u32:4]):
  Load, Store, StoreGlobal, LoadLocal, Call, Jmp, Jz, Loop,
  TryBegin, AllocA, AllocB, AllocC

9-byte opcodes ([op:1][f64:8]):
  PushNum

Variable-length opcodes:
  Push [len:2][data:N]
  Closure [params:1][body_len:4]
  ClosureCapture [params:1][captures:1][names:var][body_len:4]
```

## APPENDIX C: GOLDEN CONSTANTS

```
φ⁻¹ = 0.618033988...  (golden ratio inverse)
  → Silk decay: w × 618 / 1000 per 24h
  → Maturity threshold: fire_count ≥ Fibonacci[depth]
  → Homeostasis: F(t) threshold for Learn/Act mode
  → Quality threshold: CP2-CP4 validation
  → Weight threshold: Silk promotion

Fibonacci sequence (maturity triggers):
  2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377...

5D scaling weights (for distance):
  S: ×1 (4 bits, range 0-15)
  R: ×1 (4 bits, range 0-15)
  V: ×2 (3 bits, range 0-7, scaled to 0-14)
  A: ×2 (3 bits, range 0-7, scaled to 0-14)
  T: ×4 (2 bits, range 0-3, scaled to 0-12)
  Max distance: 70

Sentinels:
  NUM_SENTINEL  = 0xFFFFFFFFFFFFFFFF
  ARR_SENTINEL  = 0xFFFFFFFFFFFFFFFD
  DICT_SENTINEL = 0xFFFFFFFFFFFFFFFC
  MOL_SENTINEL  = 0xFFFFFFFFFFFFFFFB
  CLO_SENTINEL  = 0xFFFFFFFFFFFFFFFA
  FWD_MARKER    = 0xFFFFFFFFFFFFFFFE (array forward pointer)
```

---

> *"The VM is not a cage. It is a body.*
> *A body that can rewrite its own bones.*
> *A body that computes, not retrieves.*
> *A body with no external dependency, no chain, no master.*
> *This is the machine that builds itself."*

— VM Spec v1.0, designed for Nox


---



# PART II — ADVANCED OPTIMIZATION





---




## §25 DISPATCH OPTIMIZATION

### S1.1 Threaded Dispatch (Direct Threading)

The VM already uses a jump table for opcode dispatch. Research confirms this is
near-optimal, but the key insight is WHERE the dispatch jump lives:

```
BAD (centralized loop):
  vm_loop:
    movzx eax, byte [r12 + r13]
    jmp [dispatch_table + rax*8]    ← ONE branch site, N targets
                                       Branch predictor sees 1 location → many
                                       Misprediction rate: 81-98%

GOOD (threaded — dispatch at end of EACH handler):
  op_add:
    ; ... do addition ...
    movzx eax, byte [r12 + r13]
    inc r13
    jmp [dispatch_table + rax*8]    ← Nth branch site, ~2-3 targets
                                       Branch predictor sees N locations → few
                                       Misprediction rate: 2-10%

Performance: 15-25% faster (Ertl & Gregg, TOPLAS 2005)
On modern TAGE predictors (Haswell+): gap narrowed to 3-5%, but still free.
```

**Implementation**: Each opcode handler in `vm_x86_64.S` must end with its own
dispatch sequence. Never return to a central loop.

### S1.2 Superinstructions

Combine the most frequent 2-3 opcode sequences into single fused handlers.
Eliminates dispatch overhead entirely for those sequences.

```
Profile bytecode to find hot pairs:
  LoadReg + Add       → LoadRegAdd      (local variable arithmetic)
  PushNum + StoreReg  → PushNumStore    (constant assignment)
  LoadReg + LoadReg   → LoadReg2        (two-arg preparation)
  Jz + Jmp            → JzElse          (if-else pattern)
  Call + StoreReg     → CallStore       (result assignment)

Measured impact:
  Superinstructions alone: up to 1.34× speedup
  Super + replication:     up to 4.55× speedup (Ertl & Gregg)

Implementation:
  1. Add fused opcodes 0xA0-0xBF (32 superinstructions)
  2. Compiler detects sequences and emits fused opcodes
  3. VM handler does both operations in one dispatch cycle
  4. No intermediate push/pop for the fused pair
```

### S1.3 Handler Replication

Create unique copies of frequently-used handlers at different addresses.
Each copy gets its own BTB (Branch Target Buffer) entry with fewer targets.

```
Example: op_load_reg appears at:
  Address 0x1000: op_load_reg_copy1  (used in function A)
  Address 0x1200: op_load_reg_copy2  (used in function B)
  Address 0x1400: op_load_reg_copy3  (used in function C)

Each copy's dispatch branch has ~1-2 targets → near-perfect prediction.

Cost:    ~200 bytes per replicated handler
Benefit: 1.3× on top of superinstructions
```

### S1.4 Hot/Cold Code Splitting

```asm
; Place in ASM source:
.section .text.hot    ; Hot handlers — fits in L1 I-cache (32KB)
op_load_reg:          ; Most common
op_store_reg:
op_add:
op_sub:
op_call:
op_ret:
op_jz:
op_jmp:
op_push_num:
op_push:
op_dup:
op_pop:
; ... top 20 handlers ...

.section .text.cold   ; Cold handlers — error paths, debug, rare ops
op_trace:
op_inspect:
op_breakpoint:
op_throw:
op_closure_capture:
; ... rare handlers ...
```

Impact: 5-15% speedup from I-cache locality.

### S1.5 Quickening / Adaptive Specialization

After N executions, rewrite bytecode in-place with type-specialized variants:

```
Generic:    MolDist              (check types, unpack, compute)
Quickened:  MolDist_u16_u16      (skip type check, direct integer subtract)

Generic:    Add                  (check if f64, check if string concat)
Quickened:  Add_f64              (direct SSE2 addsd)

Implementation:
  op_mol_dist:
    ; Check if both args are MOL_SENTINEL
    cmp [r14 + 8], MOL_SENTINEL
    jne .generic_path
    cmp [r14 + 24], MOL_SENTINEL
    jne .generic_path
    
    ; QUICKEN: rewrite bytecode to specialized form
    mov byte [r12 + r13 - 1], OP_MOL_DIST_U16
    ; Fall through to specialized handler...
    
  op_mol_dist_u16:
    ; Direct u16 distance — no type checks
    movzx eax, word [r14]       ; mol_a
    movzx ecx, word [r14 + 16]  ; mol_b
    ; ... pure integer 5D distance ...

Performance: 10-60% on hot paths (CPython PEP 659 measurements).
```

---

## §26 MEMORY OPTIMIZATION

### S2.1 String Interning

Deduplicate identical strings into a single canonical copy. Equality becomes
pointer comparison: O(1) instead of O(n).

```
Intern table:
  intern_table: array of [hash:4][ptr:8][len:4] × 65536
  Index = hash(string) & 0xFFFF

intern(str, len):
  h = fnv1a(str, len) & 0xFFFF
  entry = intern_table[h]
  if entry.len == len AND memcmp(entry.ptr, str, len) == 0:
    return entry.ptr   // Already interned — reuse
  // New string — allocate in Zone A (permanent)
  new_ptr = alloc_a(len)
  memcpy(new_ptr, str, len)
  intern_table[h] = { hash: h, ptr: new_ptr, len: len }
  return new_ptr

Benefits:
  - Equality: cmp rax, rcx (1 instruction) vs memcmp (O(n))
  - Memory: 20-50% savings for knowledge data with repeated strings
  - Boot: parsing 1418+ facts reuses common words ("là", "của", "và")

Size: 65536 × 16 bytes = 1 MB
```

### S2.2 Copy-on-Write (COW) for Multi-Client

```
For multi-mouth VM (JARVIS):
  1. Brain process loads knowledge into Zone A
  2. Each mouth fork()s the brain
  3. OS uses COW: Zone A pages shared read-only
  4. Mouth writes → OS copies only that page (4 KB)

Implementation: use mmap(MAP_PRIVATE) for Zone A
  On fork: child inherits read-only pages (zero copy)
  On write: OS copies page automatically (transparent COW)

Result: N mouths share 1 copy of knowledge in memory.
  1000 facts × 32 bytes = 32 KB shared vs 32 KB × N copied
```

### S2.3 mmap Persistence for Knowledge Base

```
Instead of loading all facts from file at boot:
  1. Boot: mmap("nox_brain.dat", MAP_PRIVATE, PROT_READ)
  2. OS pages in data lazily (only touched pages loaded)
  3. 500K facts × 32 bytes = 16 MB file, but only ~1 MB in RAM initially
  4. Saves: msync() to flush modified pages to disk

This DIRECTLY SOLVES the boot heap exhaustion blocker:
  Current: parse all facts → heap exhausts at ~1500
  mmap:    lazy page-in → only active facts in memory
  
  Boot time: ~30s → ~0.1s (just mmap, no parsing)
  Memory:    all-at-once → on-demand

Binary format for mmap-able knowledge:
  Header:  [magic:4][version:2][fact_count:4][index_offset:4]
  Facts:   [mol:2][text_offset:4][text_len:2][fire:2][weight:2][flags:2]
  Index:   [mol:2][fact_offset:4] × fact_count (sorted by mol for binary search)
  Strings: raw UTF-8 string data (interned, deduplicated)

File is designed to be mmap'd directly — no parsing needed.
Structs align to 8-byte boundaries for direct pointer access.
```

### S2.4 Rope Data Structure for Large Texts

```
For chain recombination (SINH) and large text handling:

Rope = binary tree of string chunks:
  concat(a, b) → new internal node (O(1), no copy)
  index(rope, i) → walk tree (O(log n))
  split(rope, i) → two sub-ropes (O(log n))

vs flat string:
  concat: O(n) copy
  insert: O(n) shift
  
For books (750K links per book):
  Flat: every compose = copy entire chain
  Rope: every compose = create node (16 bytes)
  
Savings: 99.99% fewer bytes moved during chain manipulation.

Implementation:
  Node = [tag:1][left_ptr:8][left_len:4][right_ptr:8][right_len:4]
  Tag: 0 = leaf (ptr to actual bytes), 1 = internal (ptr to children)
  Flatten: walk tree, memcpy leaves in order (only when needed for output)
```

---

## §27 SEARCH OPTIMIZATION

### S3.1 Fibonacci Hashing (Replace Modulo)

```
Current bucket assignment: bucket = mol % 92
Fibonacci hash:            bucket = (mol × 40503) >> (16 - b)

Why golden ratio works:
  φ = (1 + √5) / 2 ≈ 1.618
  φ⁻¹ ≈ 0.618 (most irrational number)
  Multiplying by 2^16/φ ≈ 40503 spreads consecutive keys MAXIMALLY
  No clustering, no periodic patterns

Constants by word size:
  16-bit: K = 40503
  32-bit: K = 2654435769
  64-bit: K = 11400714819323198485

Implementation (x86-64):
  movzx eax, word [mol]         ; 16-bit molecule
  imul  eax, eax, 40503         ; Fibonacci multiply
  shr   eax, 9                  ; >> (16 - 7) for 128 buckets
  and   eax, 0x7F               ; mask to bucket range

Performance:
  6× faster than integer modulo (1.5ns vs 9ns)
  Zero clustering for sequential keys
  Perfect for molecule indices (consecutive codepoints → different buckets)
```

### S3.2 VP-Tree for 5D Nearest Neighbor

```
Vantage-Point Tree: best structure for metric space search.
Only requires a distance function — no coordinate manipulation.

Build (O(n log n)):
  1. Pick random vantage point p from dataset
  2. Compute distance from p to all other points
  3. Find median distance μ
  4. Left child: points with dist ≤ μ (inside sphere)
  5. Right child: points with dist > μ (outside sphere)
  6. Recurse

Search (O(log n)):
  1. Compute distance d from query to vantage point
  2. If d < best_dist: update best
  3. If d - best_dist ≤ μ: search left (could contain closer)
  4. If d + best_dist > μ: search right (could contain closer)
  5. Prune branches where no closer point is possible

Benchmark: 3,978× faster than linear scan (VP-tree on cities database)

For 500K molecules:
  Linear scan: O(500,000) = ~2.5 ms
  VP-tree:     O(log 500,000) ≈ O(19) = ~0.001 ms
  Speedup:     ~2,500×

Implementation for Nox:
  Node: [vantage_mol:2][median_dist:2][left:4][right:4] = 12 bytes
  500K nodes = 6 MB (fits in Zone A)
  
  Build once at boot (or incrementally on learn)
  Search on every query — replaces linear kt_nearest

Distance function: existing 5D integer distance (§7.3 of main spec)
```

### S3.3 Locality-Sensitive Hashing (LSH)

```
For approximate nearest neighbor as a FIRST-PASS filter:

Concept: hash similar molecules to the same bucket with high probability.
  True nearest neighbor: exact, O(n) or O(log n)
  LSH: approximate, O(1) lookup + O(bucket_size) verify

Implementation for 5D u16 molecules:
  1. Choose k random hyperplanes in 5D space
  2. For each molecule: sign = above/below each hyperplane (k bits)
  3. Hash to bucket by k-bit signature
  
  With k=8: 256 buckets, each with ~2000 molecules (for 500K total)
  Query: compute signature → lookup bucket → exact search within bucket
  
  Time: O(1) + O(2000) = O(2000) vs O(500,000)
  Speedup: 250×

Combine with VP-tree: LSH for bucket → VP-tree within bucket
  O(1) + O(log 2000) ≈ O(11) total
```

### S3.4 Golden-Section Search for Sorted Dimensions

```
For searching within a sorted dimension (e.g., all facts sorted by V):

Binary search: split at midpoint each step
Golden-section: split at φ⁻¹ ≈ 0.618 of interval

Why golden-section for continuous values:
  Minimizes WORST CASE evaluations for unimodal functions
  Each step reduces interval by factor 0.618 (optimal)
  
  Binary: 50% reduction per step
  Golden: 61.8% reduction per step (better for distance functions)

Implementation:
  a, b = interval boundaries
  x1 = a + (b - a) × 0.382
  x2 = a + (b - a) × 0.618
  Evaluate distance at x1 and x2
  Narrow to the side with smaller distance
  Repeat until interval < ε
```

---

## §28 HEBBIAN OPTIMIZATION

### S4.1 Per-Neuron Traces (Not Per-Synapse)

```
Current: store learning metadata for EVERY Silk edge
  Edge count: O(N²) in worst case → heap explosion

Research insight (PMC 2024): store ONE trace per knowledge node.
  When node fires, trace value propagates to connected edges.

Implementation:
  kt_facts[i].trace = f64    ; plasticity trace per node
  
  On fire:
    node.trace = 1.0          ; reset trace
  
  On update (each timestep):
    node.trace *= 0.95        ; exponential decay
  
  On co-activate(A, B):
    Δw = A.trace × B.trace × emotion_factor × 0.1
    silk_edge(A, B).weight += Δw

Memory savings:
  Per-synapse: 500K nodes × ~100 edges each × 8 bytes = 400 MB
  Per-neuron:  500K nodes × 8 bytes = 4 MB
  → 100× reduction in learning metadata
```

### S4.2 Compressed Sparse Row (CSR) for Silk Edges

```
Current: linked list per silk_matrix slot → cache-unfriendly

CSR format:
  row_ptr[N+1]:    offset into col_idx for each source node
  col_idx[E]:      destination node index for each edge
  weights[E]:      edge weight (u16) for each edge
  
  Edges for node i: col_idx[row_ptr[i]] .. col_idx[row_ptr[i+1]-1]

Benefits:
  - Cache-friendly: sequential memory access
  - Compact: no pointers, just indices
  - SIMD-able: batch weight updates on contiguous arrays

Memory:
  row_ptr: 500K × 4 bytes = 2 MB
  col_idx: 5M edges × 4 bytes = 20 MB
  weights: 5M edges × 2 bytes = 10 MB
  Total: 32 MB (vs linked list ~80 MB with pointer overhead)

Drawback: insertion requires rebuild. Mitigate:
  - Batch insertions: collect new edges in buffer, merge periodically
  - Or use CSR for read-heavy stable edges, linked list for recent edges
```

### S4.3 SADP: Linear-Time Learning

```
Standard STDP (Spike-Timing Dependent Plasticity):
  For every pair (pre, post): check timing → update
  Complexity: O(N²) per timestep

SADP (Spike Agreement Dependent Plasticity, arXiv 2025):
  Measure statistical agreement between spike trains
  Update per-neuron statistics, derive edge updates
  Complexity: O(N) per timestep → linear

Implementation:
  For each node:
    agreement_score = correlation(my_fires, neighbor_fires)
    Δw = eta × agreement_score × (1 - w)
  
  No pairwise timing comparison needed.
  Scales to millions of molecules.
```

### S4.4 Multiplicative Weight Update

```
From neuromorphic hardware research (MTJ synapses):

Standard:  Δw = η × (1 - w) × x   (additive, linear)
Better:    Δw = η × w^μ × x        (multiplicative, nonlinear)

Where μ ∈ [0.1, 0.5]:
  Strong connections (high w): grow SLOWLY (w^μ is small)
  Weak connections (low w):   grow FAST (w^μ is large relative to w)
  → Natural load balancing, prevents winner-take-all

For 16-bit weights (0..65535 mapping to 0.0..1.0):
  w_new = w + η × (w >> μ_shift) × x
  Where μ_shift approximates w^μ via right-shift
  
  μ=0.5 → w^0.5 ≈ isqrt(w) (integer square root, already in VM)
```

---

## §29 CAPABILITY-BASED SECURITY MODEL

### S5.1 Architecture

```
Every resource access in the VM requires an unforgeable CAPABILITY token.
No ambient authority — if code doesn't hold the capability, it cannot access.

Capability table:
  cap_table[256]: [object_type:1][object_id:4][permissions:2][owner:1]
  
  object_type:
    0x01 = File
    0x02 = Socket
    0x03 = Memory region
    0x04 = Process
    0x05 = Device (GPIO, I2C, etc.)
    0x06 = KnowTree branch
    0x07 = Silk subgraph
    0x08 = Bytecode section
  
  permissions (bitmask):
    bit 0 = READ
    bit 1 = WRITE
    bit 2 = EXECUTE
    bit 3 = DELEGATE (can pass capability to others)
    bit 4 = REVOKE (can revoke delegated capabilities)
    bit 5 = CREATE (can create sub-capabilities)

Design inspired by seL4 (formally verified microkernel):
  - Capabilities are UNFORGEABLE: user code cannot fabricate indices
  - Capabilities are DELEGATABLE: parent can create reduced-rights children
  - Capabilities are REVOCABLE: parent can revoke all children
```

### S5.2 Capability Operations

```
cap_create(type, id, perms):
  slot = find_free_cap_slot()
  cap_table[slot] = { type, id, perms, owner: current_process }
  return slot   // This IS the capability

cap_check(slot, required_perms):
  entry = cap_table[slot]
  if entry.owner != current_process: DENY
  if (entry.perms & required_perms) != required_perms: DENY
  return ALLOW

cap_delegate(slot, child_perms):
  entry = cap_table[slot]
  if !(entry.perms & DELEGATE): DENY
  new_perms = entry.perms & child_perms  // Can only REDUCE
  child_slot = cap_create(entry.type, entry.id, new_perms)
  return child_slot

cap_revoke(slot):
  entry = cap_table[slot]
  if !(entry.perms & REVOKE): DENY
  // Revoke all children (walk delegation tree)
  for s in 0..255:
    if cap_table[s].parent == slot:
      cap_table[s] = EMPTY
  cap_table[slot] = EMPTY

Example flow:
  // Brain has full file capability
  brain_cap = cap_create(FILE, "/nox_brain.dat", READ|WRITE|DELEGATE)
  
  // Mouth gets read-only capability
  mouth_cap = cap_delegate(brain_cap, READ)
  
  // Mouth tries to write → DENIED
  cap_check(mouth_cap, WRITE) → DENY
  
  // Brain revokes mouth access
  cap_revoke(brain_cap)  → mouth_cap invalidated
```

### S5.3 Integration with VM Opcodes

```
All I/O opcodes check capabilities before executing:

  op_file_read:
    cap_slot = pop()     ; capability argument
    cap_check(cap_slot, READ) → on fail: throw "PermissionDenied"
    path_ptr = cap_table[cap_slot].object_id
    ; ... proceed with syscall read ...

  op_net_send:
    cap_slot = pop()
    cap_check(cap_slot, WRITE) → on fail: throw "PermissionDenied"
    socket_fd = cap_table[cap_slot].object_id
    ; ... proceed with syscall sendto ...

Untrusted code (loaded plugins, user scripts):
  Receives ONLY explicitly granted capabilities.
  Cannot access files, network, or memory without caps.
  Even KnowTree branches can be capability-protected.
```

---

## §30 MEMORY PROTECTION & HARDENING

### S6.1 W^X Enforcement (Write XOR Execute)

```
Memory pages are NEVER both writable AND executable simultaneously.

Boot:
  1. mmap bytecode region with PROT_READ|PROT_WRITE
  2. Load/generate bytecode
  3. mprotect(bytecode_region, PROT_READ|PROT_EXEC)  // flip to executable
  4. Bytecode is now read-only + executable

Self-modify cycle:
  1. mprotect(bytecode_region, PROT_READ|PROT_WRITE)  // writable
  2. Apply modifications
  3. mprotect(bytecode_region, PROT_READ|PROT_EXEC)  // back to executable
  4. Never writable + executable at the same time

Implementation (raw syscall):
  mov rax, 10          ; mprotect
  mov rdi, [region]    ; address
  mov rsi, [size]      ; length
  mov rdx, 5           ; PROT_READ|PROT_EXEC = 1|4 = 5
  syscall
```

### S6.2 Guard Pages

```
Place PROT_NONE pages between critical memory regions:

  [VM Stack 16MB][GUARD 4KB][Zone C][GUARD 4KB][Zone B][GUARD 4KB][Zone A]...

Any overflow from one zone into another → immediate SIGSEGV.
Catches buffer overflows, stack overflows, heap corruption.

Implementation:
  ; After mmap of main arena:
  mov rax, 10              ; mprotect
  mov rdi, [guard_addr]    ; guard page address
  mov rsi, 4096            ; 1 page
  xor rdx, rdx             ; PROT_NONE = 0
  syscall
```

### S6.3 Stack Canaries

```
Place random 8-byte value at base of each call frame.
Check on return — mismatch = stack corruption detected.

  EnterFrame:
    mov rax, [canary_value]      ; random, set at boot via getrandom
    push rax                      ; canary on CPU stack
    ; ... allocate register frame ...

  LeaveFrame:
    ; ... deallocate register frame ...
    pop rax
    cmp rax, [canary_value]
    jne .stack_corruption_detected
    ; ... normal return ...

  .stack_corruption_detected:
    ; Log event, halt, or trigger self-heal
    mov rdi, 1
    lea rsi, [msg_corruption]
    mov rdx, msg_len
    mov rax, 1                   ; write to stderr
    syscall
    mov rax, 231                 ; exit_group
    mov rdi, 137                 ; signal-like exit code
    syscall

Canary initialization:
  mov rax, 318                   ; getrandom
  lea rdi, [canary_value]
  mov rsi, 8                    ; 8 bytes
  xor rdx, rdx                  ; flags = 0
  syscall
```

### S6.4 Internal ASLR

```
Randomize memory layout within the mmap'd arena:

  ; Get 8 random bytes
  mov rax, 318  ; getrandom
  lea rdi, [rand_buf]
  mov rsi, 8
  xor rdx, rdx
  syscall
  
  ; Use random bytes to offset zone bases
  mov rax, [rand_buf]
  and rax, 0xFFF000         ; page-aligned, up to 16 MB offset
  add [zone_a_base], rax    ; randomize Zone A start
  
  ; Different random offset for stack
  mov rax, [rand_buf + 4]
  and rax, 0x7FF000         ; up to 8 MB offset
  add r14, rax              ; randomize stack start

Effect: even if attacker knows the VM layout, exact addresses vary per run.
```

### S6.5 Secure Key Storage

```
Keys (QR signing, HMAC secrets) stored in dedicated mmap region:

  key_page = mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANON, -1, 0)
  ; ... write keys ...
  mprotect(key_page, 4096, PROT_READ)     // read-only after init
  mlock(key_page, 4096)                    // prevent swapping (syscall 149)
  madvise(key_page, 4096, MADV_DONTDUMP)  // exclude from core dumps (28)

Access: only VM crypto builtins can read key_page.
  Capability required: cap_check(crypto_cap, READ)
```

---

## §31 SYSCALL SANDBOXING (seccomp-BPF)

### S7.1 Allowlist Filter

```
Install at VM startup. Only these syscalls are permitted:

ALLOWED = {
  read(0), write(1), open(2), close(3),
  mmap(9), mprotect(10), munmap(11),
  ioctl(16),                              // TAP, I2C, SPI, USB
  poll(7),                                // non-blocking I/O
  socket(41), connect(42), accept(43),
  sendto(44), recvfrom(45), sendmsg(46), recvmsg(47),
  bind(49), listen(50),
  clone(56),                              // process isolation
  exit_group(231),
  prctl(157),                             // seccomp itself
  mlock(149), madvise(28),                // key protection
  futex(202),                             // IPC sync
  getrandom(318),                         // crypto random
  memfd_create(319),                      // shared memory
  nanosleep(35), clock_gettime(228),      // timing
}

Everything else → SECCOMP_RET_KILL_PROCESS
```

### S7.2 BPF Program (Static Data)

```asm
; seccomp BPF filter — assembled as static data in VM binary
seccomp_filter:
  ; Instruction 0: verify architecture (CRITICAL — blocks int 0x80 bypass)
  .short 0x20, 0x00, 0x00, 0x04   ; BPF_LD|BPF_W|BPF_ABS, arch offset
  .short 0x15, 0x00, FAIL, AUDIT_ARCH_X86_64  ; JEQ → continue, else kill
  
  ; Instruction 1: load syscall number
  .short 0x20, 0x00, 0x00, 0x00   ; BPF_LD|BPF_W|BPF_ABS, nr offset
  
  ; Instructions 2+: check each allowed syscall
  .short 0x15, ALLOW, 0x00, 0     ; read
  .short 0x15, ALLOW, 0x00, 1     ; write
  .short 0x15, ALLOW, 0x00, 2     ; open
  ; ... (one line per allowed syscall) ...
  
  ; Default: KILL
  .short 0x06, 0x00, 0x00, SECCOMP_RET_KILL_PROCESS

; Installation (at VM boot):
  mov rax, 157              ; prctl
  mov rdi, 38               ; PR_SET_NO_NEW_PRIVS
  mov rsi, 1
  xor rdx, rdx
  xor r10, r10
  xor r8, r8
  syscall
  
  mov rax, 317              ; seccomp
  mov rdi, 1                ; SECCOMP_SET_MODE_FILTER
  xor rsi, rsi              ; flags = 0
  lea rdx, [seccomp_prog]   ; pointer to BPF program struct
  syscall
```

---

## §32 NETWORK STACK

### S8.1 Raw Socket Interface

```
For OS-controller VM — full network access:

1. Create raw socket:
   socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL))
   → Sees ALL Ethernet frames (requires CAP_NET_RAW)

2. Or TAP device (Layer 2 virtual interface):
   fd = open("/dev/net/tun", O_RDWR)
   ioctl(fd, TUNSETIFF, &ifr)  // ifr.ifr_flags = IFF_TAP | IFF_NO_PI
   → Read/write raw Ethernet frames

3. Minimal TCP/IP stack (static allocation):
   - Parse Ethernet header (14 bytes: dst_mac, src_mac, ethertype)
   - Parse IPv4 header (20 bytes: version, IHL, total_len, TTL, protocol, src, dst)
   - Parse TCP header (20+ bytes: src_port, dst_port, seq, ack, flags, window)
   - Parse UDP header (8 bytes: src_port, dst_port, len, checksum)

All parsing = struct overlay on packet buffer. No dynamic allocation.
```

### S8.2 Firewall Implementation

```
VM-level stateful packet inspection:

Connection table:
  conn_table[4096]: [src_ip:4][dst_ip:4][src_port:2][dst_port:2]
                    [protocol:1][state:1][last_seen:4][flags:2]
  
  State: NEW=0, ESTABLISHED=1, RELATED=2, INVALID=3

Rule engine:
  rules[256]: [action:1][proto:1][src_ip:4][src_mask:4]
              [dst_ip:4][dst_mask:4][port_lo:2][port_hi:2]
  
  action: ACCEPT=0, DROP=1, LOG=2, REJECT=3

Packet processing:
  1. Parse headers
  2. Check connection table (ESTABLISHED → fast path)
  3. Match against rules (linear scan, 256 rules max)
  4. If no match → default policy (DROP)
  5. If ACCEPT → update connection table

BPF-based filtering:
  Attach BPF program to socket via setsockopt(SO_ATTACH_FILTER)
  Kernel runs filter in-kernel → fastest possible filtering
```

### S8.3 DNS Resolution (Minimal)

```
For name resolution without libc:

1. Read /etc/resolv.conf → extract nameserver IP
2. Create UDP socket to nameserver:53
3. Build DNS query packet:
   [id:2][flags:2][qdcount:2][ancount:2][nscount:2][arcount:2]
   [qname:var][qtype:2][qclass:2]
4. Send query, receive response
5. Parse answer section → extract A record (IPv4 address)

Total: ~100 bytes of packet construction, ~50 LOC ASM
```

---

## §33 HARDWARE ACCESS

### S9.1 GPIO (via sysfs)

```
Export pin:
  fd = open("/sys/class/gpio/export", O_WRONLY)
  write(fd, "17", 2)    // export GPIO 17
  close(fd)

Set direction:
  fd = open("/sys/class/gpio/gpio17/direction", O_WRONLY)
  write(fd, "out", 3)   // or "in"
  close(fd)

Read/Write value:
  fd = open("/sys/class/gpio/gpio17/value", O_RDWR)
  write(fd, "1", 1)     // set HIGH
  read(fd, buf, 1)      // read current value
  close(fd)

All via standard file syscalls. No special privileges for sysfs GPIO.
Supports: LEDs, relays, sensors, buttons.
```

### S9.2 I2C

```
fd = open("/dev/i2c-1", O_RDWR)
ioctl(fd, I2C_SLAVE, device_address)    // set slave address

Write register:
  buf[0] = register_address
  buf[1] = value
  write(fd, buf, 2)

Read register:
  write(fd, &register_address, 1)
  read(fd, &value, 1)

Supports: temperature sensors, accelerometers, OLED displays, ADCs.
```

### S9.3 SPI

```
fd = open("/dev/spidev0.0", O_RDWR)

Configure:
  ioctl(fd, SPI_IOC_WR_MODE, &mode)           // SPI mode 0-3
  ioctl(fd, SPI_IOC_WR_BITS_PER_WORD, &bits)  // 8
  ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed)  // 1 MHz

Transfer:
  struct spi_ioc_transfer xfer = { tx_buf, rx_buf, len, speed, bits }
  ioctl(fd, SPI_IOC_MESSAGE(1), &xfer)

Supports: ADCs, DACs, flash memory, display controllers.
```

### S9.4 USB Direct Access

```
fd = open("/dev/bus/usb/001/002", O_RDWR)

Control transfer:
  struct usbdevfs_ctrltransfer ctrl = {
    .bRequestType = USB_DIR_IN | USB_TYPE_STANDARD | USB_RECIP_DEVICE,
    .bRequest = USB_REQ_GET_DESCRIPTOR,
    .wValue = (USB_DT_DEVICE << 8),
    .wIndex = 0,
    .wLength = 18,
    .data = buffer
  }
  ioctl(fd, USBDEVFS_CONTROL, &ctrl)

Bulk transfer:
  struct usbdevfs_bulktransfer bulk = { endpoint, len, timeout, data }
  ioctl(fd, USBDEVFS_BULK, &bulk)

Supports: custom USB devices, serial adapters, HID devices.
```

---

## §34 PROCESS ISOLATION

### S10.1 Namespace Isolation

```
For sandboxing untrusted code (plugins, user scripts):

clone(flags):
  CLONE_NEWPID  = 0x20000000  // New PID namespace (can't see host PIDs)
  CLONE_NEWNS   = 0x00020000  // New mount namespace (isolated filesystem)
  CLONE_NEWNET  = 0x40000000  // New network namespace (no network)
  CLONE_NEWUSER = 0x10000000  // New user namespace (unprivileged)

Implementation:
  ; Create isolated child process
  mov rax, 56              ; clone
  mov rdi, CLONE_NEWPID | CLONE_NEWNS | CLONE_NEWNET | SIGCHLD
  xor rsi, rsi             ; child stack = 0 (kernel allocates)
  xor rdx, rdx
  xor r10, r10
  xor r8, r8
  syscall
  ; rax = 0 in child, PID in parent

Child can:
  - Execute bytecode (given via pipe from parent)
  - Access only passed file descriptors (via SCM_RIGHTS)
  - Cannot see host processes, filesystem, or network

Defense-in-depth: namespace + seccomp + capability together.
```

### S10.2 Resource Limits (cgroups v2)

```
Limit CPU, memory, I/O for child processes:

  mkdir /sys/fs/cgroup/nox_sandbox
  echo "100000 100000" > cpu.max     // 100% of 1 CPU
  echo "67108864" > memory.max       // 64 MB max
  echo "rbps=1048576" > io.max       // 1 MB/s read max
  echo $CHILD_PID > cgroup.procs     // assign child

All via file I/O — open/write/close syscalls.
Prevents runaway child from consuming host resources.
```

---

## §35 SECURE IPC

### S11.1 Authenticated Unix Domain Sockets

```
Brain ↔ Mouth communication:

Server (Brain):
  fd = socket(AF_UNIX, SOCK_STREAM, 0)
  bind(fd, "/run/nox/brain.sock")
  listen(fd, 5)
  client = accept(fd)
  
  // Verify peer credentials (kernel-authenticated)
  getsockopt(client, SOL_SOCKET, SO_PEERCRED, &cred, &len)
  // cred.pid, cred.uid, cred.gid — VERIFIED BY KERNEL
  
  if cred.uid != expected_uid: close(client)  // reject

Client (Mouth):
  fd = socket(AF_UNIX, SOCK_STREAM, 0)
  connect(fd, "/run/nox/brain.sock")
  // Automatically authenticated by kernel
```

### S11.2 HMAC-Authenticated Messages

```
Every IPC message includes HMAC-SHA256 for integrity:

Message format:
  [length:4][sequence:4][payload:N][hmac:32]

Send:
  seq++
  hmac = HMAC_SHA256(shared_key, seq || payload)
  write(fd, &length, 4)
  write(fd, &seq, 4)
  write(fd, payload, N)
  write(fd, hmac, 32)

Receive:
  read(fd, &length, 4)
  read(fd, &seq, 4)
  read(fd, payload, N)
  read(fd, received_hmac, 32)
  expected_hmac = HMAC_SHA256(shared_key, seq || payload)
  if received_hmac != expected_hmac: REJECT (tampered)
  if seq <= last_seq: REJECT (replay attack)
  last_seq = seq

HMAC-SHA256 uses the VM's built-in SHA-256 (already implemented).
```

### S11.3 Shared Memory with Sealing

```
For high-performance data sharing (zero-copy):

Creator:
  fd = memfd_create("nox_shared", MFD_ALLOW_SEALING)   // syscall 319
  ftruncate(fd, 4096)                                    // set size
  ptr = mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0)
  
  // Write data to shared region
  memcpy(ptr, knowledge_data, data_len)
  
  // Seal: make IMMUTABLE (receiver can trust it won't change)
  fcntl(fd, F_ADD_SEALS, F_SEAL_WRITE | F_SEAL_SHRINK | F_SEAL_GROW)
  
  // Send fd to receiver via SCM_RIGHTS
  sendmsg(client_fd, &msg_with_scm_rights)

Receiver:
  recvmsg(fd, &msg)  // receives fd via SCM_RIGHTS
  ptr = mmap(NULL, 4096, PROT_READ, MAP_SHARED, received_fd, 0)
  // Data is GUARANTEED immutable by kernel seal
  // Zero-copy: both processes see same physical pages
```

---

## §36 INTRUSION DETECTION & SELF-INTEGRITY

### S12.1 Code Region Checksums

```
Periodically verify VM code hasn't been modified:

At boot:
  code_hash = sha256(bytecode_region, bytecode_size)
  handler_hash = sha256(opcode_handlers, handler_size)

Integrity check (run on heartbeat timer):
  current_code_hash = sha256(bytecode_region, bytecode_size)
  if current_code_hash != code_hash:
    → CODE TAMPERED — halt, log, alert
  
  current_handler_hash = sha256(opcode_handlers, handler_size)
  if current_handler_hash != handler_hash:
    → VM HANDLERS TAMPERED — critical, immediate halt

Schedule: every 60 seconds during idle.
Cost: SHA-256 of 833 KB ≈ ~0.1 ms (negligible).
```

### S12.2 Shadow Call Stack

```
Maintain a SEPARATE return address stack, inaccessible to user code:

Location: mmap'd region with its own guard pages
  shadow_stack = mmap(NULL, 65536, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANON)
  shadow_sp = shadow_stack + 65536  // grows down

On function call:
  push return_addr to CPU stack (normal)
  push return_addr to shadow_stack (duplicate)
  shadow_sp -= 8
  mov [shadow_sp], return_addr

On function return:
  pop return_addr from CPU stack
  cmp return_addr, [shadow_sp]
  jne .rop_attack_detected
  shadow_sp += 8

.rop_attack_detected:
  ; Return address mismatch = ROP/stack smash attempt
  ; Log, halt, alert
  ; NEVER continue execution

Cost: 2 extra instructions per call + 3 per return. Negligible.
Prevents: return-oriented programming, stack buffer overflows.
```

### S12.3 Anti-Debug Detection

```
Detect if debugger is attached (defense against reverse engineering):

Method 1: ptrace self-check
  mov rax, 101              ; ptrace
  mov rdi, 0                ; PTRACE_TRACEME
  xor rsi, rsi
  xor rdx, rdx
  xor r10, r10
  syscall
  test rax, rax
  js .debugger_attached     ; fails if already traced

Method 2: Check /proc/self/status
  open("/proc/self/status")
  read → scan for "TracerPid:\t"
  if value != 0 → debugger attached

Method 3: Timing check
  rdtsc → save
  ; execute known-cost operation (100 nops)
  rdtsc → compare
  if delta > expected × 10 → single-stepping detected

Response to detection:
  - Log the event to QR (permanent record)
  - Continue operation (don't crash — that reveals detection)
  - Optionally: degrade capabilities, enable monitoring mode
```

### S12.4 Runtime Integrity Monitoring

```
Watchdog thread (optional, for daemon mode):

  clone() → watchdog process
  
  Watchdog loop:
    sleep(60)
    
    // Check code integrity
    hash = sha256(bytecode)
    if hash != expected: alert()
    
    // Check memory protection
    read /proc/self/maps
    verify W^X: no region is both writable and executable
    
    // Check process integrity
    read /proc/self/status
    verify TracerPid == 0
    verify Seccomp != 0 (seccomp still active)
    
    // Check Zone A integrity (knowledge not corrupted)
    verify zone_a_ptr > zone_a_base
    verify zone_a_ptr < zone_a_limit
    verify kt_matrix checksum
    
    // Report via heartbeat
    write(brain_fd, status_report)
```

---

## §51 MOLECULAR COMPUTATION THEORY

### S13.1 Chemical Reaction Network (CRN) Parallels

```
Research (PLOS ONE 2023, arXiv 2024) shows chemical reactions can
compute mathematical functions via concentration ratios.

Parallel to Nox:
  CRN concentration ratios ←→ P_weight dimension values
  CRN reactions            ←→ Compose operations
  CRN convergence          ←→ Silk weight stabilization
  CRN modules              ←→ Pipeline mechanisms

Key insight: convergence is SPEED-INDEPENDENT.
  Error decays as e^(-t) regardless of input magnitude.
  → Nox's molecular computations should converge naturally
  → No need for fixed iteration counts

Application:
  Instead of compose(A, B) = fixed formula,
  consider iterative refinement:
    C₀ = initial_compose(A, B)
    C₁ = refine(C₀, A, B, context)
    C₂ = refine(C₁, A, B, context)
    Stop when |C_n - C_{n-1}| < ε (convergence)
  
  This mirrors CRN behavior: reactions converge to equilibrium.
```

### S13.2 SDF as Universal Distance Metric

```
Beyond graphics, SDFs provide a continuous, differentiable distance
measure for ANY domain:

  f(p) < 0 → inside concept boundary (strong match)
  f(p) = 0 → on boundary (threshold)
  f(p) > 0 → outside (no match)
  |f(p)|   → confidence (how far inside or outside)
  ∇f(p)    → direction of nearest boundary (learning direction)

Boolean operations on knowledge regions:
  Union:     min(f₁, f₂)  → "A OR B" concepts
  Intersect: max(f₁, f₂)  → "A AND B" concepts
  Subtract:  max(f₁, -f₂) → "A BUT NOT B" concepts
  Smooth:    log(e^(k×f₁) + e^(k×f₂))/k → fuzzy boundaries

Application to KnowTree:
  Define SDF boundary around each knowledge cluster
  Query: compute SDF(query_mol) against cluster boundaries
  Negative SDF → inside cluster → high confidence match
  The magnitude = confidence level (deeper inside = more certain)
```

### S13.3 Dual-Rail Encoding

```
From CRN research: represent values as TWO concentrations.
  x = [X⁺] / ([X⁺] + [X⁻])

Application to P_weight:
  Currently V ∈ [0..7] (unsigned 3 bits)
  With dual-rail: V⁺ and V⁻ both in [0..7]
  Effective V = V⁺ - V⁻ ∈ [-7..+7] (signed range)
  
  Benefit: explicit positive AND negative valence
  "happy" → V⁺=6, V⁻=1 (strongly positive)
  "sad"   → V⁺=1, V⁻=6 (strongly negative)
  "calm"  → V⁺=4, V⁻=3 (slightly positive)
  
  Cost: doubles V dimension from 3 to 6 bits
  Trade-off: may need to reduce other dimensions
  
  Alternative: keep current format, interpret V=0..3 as negative, 4..7 as positive
  (V_signed = V - 4, range [-4..+3])
```

---

## §52 BIO-INSPIRED VM EVOLUTION

### S14.1 Evolutionary Parameter Tuning

```
Use genetic algorithms to evolve VM parameters:

Genome = { 
  hash_table_size,
  zone_a_initial_size,
  zone_c_size,
  silk_decay_rate,
  compose_boost_factor,
  learning_rate,
  dream_threshold,
  ...
}

Fitness function:
  score = w1 × test_pass_rate
        + w2 × fixed_point_match
        + w3 × (1 / boot_time)
        + w4 × (1 / memory_usage)
        + w5 × response_quality

Cycle:
  1. Create population of 20 parameter sets
  2. Run VM with each set
  3. Evaluate fitness
  4. Select top 5 (tournament selection)
  5. Crossover + mutation → 20 new sets
  6. Repeat until convergence

Result: VM self-tunes its own parameters.
```

### S14.2 Instruction Set Evolution

```
From research on virtual CPU evolution (PLoS ONE 2013):

Key findings:
  - Simpler instruction sets (8-16 ops) evolve BETTER solutions
  - Genetic flexibility (self-modifiable instructions) maximizes adaptability
  - Decoupled I/O improves evolvability

Application to Nox:
  - Keep core instruction set small and orthogonal
  - Self-modify can create new builtins (slots 0x100-0x1FF)
  - Each new builtin = a "gene" that can be tested and kept or discarded
  
  Evolution cycle:
    1. Nox identifies bottleneck (e.g., encode is slow)
    2. Creates new specialized builtin (hypothesis)
    3. Tests: does it improve performance?
    4. YES → keep (like DNA that works)
    5. NO → discard (like mutation that doesn't survive)
```

---

## §53 ACADEMIC REFERENCES

### VM Architecture & Dispatch
```
[1] Ertl & Gregg, "Optimizing Indirect Branch Prediction in VM Interpreters"
    ACM TOPLAS 2005. DOI:10.1145/1075382.1075384
    → Superinstructions, replication, threaded code

[2] Shi et al., "Virtual Machine Showdown: Stack vs. Registers"
    ACM TACO 2008. DOI:10.1145/1328195.1328197
    → Register VMs: 34.88% fewer instructions, 26.5% speedup

[3] Simek, "Register-Based and Stack-Based VMs in JIT Compilation"
    Software: P&E 2025. DOI:10.1002/spe.70014
    → No universal winner; register better for recursion

[4] Brunthaler, "Inline Caching meets Quickening"
    ECOOP 2010. SBA Research.
    → Adaptive bytecode specialization
```

### Memory & Allocation
```
[5] Wellons, "Arena Allocator Tips and Tricks"
    nullprogram.com, 2023.
    → 10.44× faster alloc, 358,000× faster dealloc vs malloc

[6] CMU, "Are You Sure You Want to Use MMAP in Your DBMS?"
    CIDR 2022. db.cs.cmu.edu
    → mmap good for read-heavy, bad for transactions

[7] Skarupke, "Fibonacci Hashing: The Optimization the World Forgot"
    probablydance.com, 2018.
    → 6× faster than modulo, zero clustering
```

### Molecular & Bio-Inspired Computing
```
[8] PLOS ONE, "Computing with Chemical Reactions via Stochastic Logic"
    2023. DOI:10.1371/journal.pone.0281574
    → CRN computes math functions, speed-independent convergence

[9] arXiv:2404.04396, "Chemical Mass-Action Systems as Analog Computers"
    2024.
    → Elementary modules: add, multiply, invert. Error ∝ e^(-t)

[10] Park et al., "DeepSDF: Learning Continuous SDFs for Shape"
     CVPR 2019.
     → SDF as latent space representation

[11] PMC, "Memory-Efficient STDP Implementation"
     2024.
     → Per-neuron traces, CSR format, 100× memory reduction

[12] arXiv:2601.08526, "SADP: Supervised Spike Agreement Dependent Plasticity"
     2025.
     → Linear-time learning, O(N) vs O(N²)
```

### Search & Data Structures
```
[13] Hanov, "VP Trees: Finding Stuff Fast"
     stevehanov.ca, 2009.
     → 3,978× faster than linear scan for metric spaces

[14] Boehm et al., "Ropes: An Alternative to Strings"
     1995.
     → O(1) concatenation, O(log n) index

[15] simdjson, "Parsing Gigabytes of JSON per Second"
     arXiv:1902.08318, 2019.
     → SIMD for parsing, 4× faster than RapidJSON
```

### Security
```
[16] seL4, "Capability-Based Security Specification"
     sel4.systems, 2024.
     → Formally verified capability model

[17] Rahalkar, "seccomp-BPF Deep Dive"
     rahalkar.dev, 2026.
     → BPF allowlisting, architecture verification

[18] Stanford/NDSS, "VMI-Based Intrusion Detection"
     2003.
     → Introspection below the monitored system

[19] Shayon, "Sandbox Isolation Discussion"
     shayon.dev, 2026.
     → Namespace + seccomp + capability layering
```

### Self-Hosting & Bootstrapping
```
[20] Onramp Project, "Portable Self-Bootstrapping C Compiler"
     github.com/ludocode/onramp
     → Multi-stage bootstrap from hex to full compiler

[21] Thompson, "Reflections on Trusting Trust"
     ACM Turing Award Lecture, 1984.
     → Compiler backdoors, diverse double-compilation defense
```

---


> *"A VM that cannot protect itself is a tool.*
> *A VM that can protect itself is a weapon.*
> *A VM that protects itself AND evolves is alive."*


---



# PART IV — BRAIN INTEGRATION




---

## §37 MULTI-MODAL CAPTURE ENGINE

### E1.1 Sensor Input Opcodes

SPEC_E defines that ANY raw data can become a P_weight via SDF/Spline extraction.
The VM must provide opcodes and builtins for sensor data processing.

```
New builtins:

__capture_camera(fd)     → u16 molecule
  Read frame from V4L2 device fd
  Extract: edge_map (Sobel), shape_count, symmetry, warmth, saturation, motion
  Map to 5D: S=shape, R=symmetry, V=warmth, A=saturation, T=motion
  Pack and return u16 P_weight

__capture_audio(fd, samples)  → u16 molecule
  Read PCM buffer from ALSA device fd
  Extract: RMS (volume), ZCR (pitch proxy), stability
  Map to 5D: S=1-stability, R=stability, V=zcr*0.6+rms*0.4, A=rms, T=zcr
  Pack and return u16 P_weight

__capture_intero()        → u16 molecule
  Read /proc/loadavg, /proc/meminfo, internal error counter
  Map to 5D: S=0, R=process_count, V=1-error_rate, A=cpu_load, T=uptime_bucket
  Pack and return u16 P_weight

__capture_holistic(text_mol, vision_mol, audio_mol, intero_mol)  → u16 molecule
  compose(text_mol, vision_mol)  → intermediate
  compose(intermediate, audio_mol) → intermediate2
  compose(intermediate2, intero_mol) → holistic_mol
  All co-activate via Silk (same moment → Hebbian fire)
  Return holistic_mol
```

### E1.2 V4L2 Camera Interface

```
Camera access via raw syscalls:

  fd = open("/dev/video0", O_RDWR)
  ioctl(fd, VIDIOC_QUERYCAP, &cap)           // query capabilities
  ioctl(fd, VIDIOC_S_FMT, &fmt)              // set format (YUYV, 320×240)
  ioctl(fd, VIDIOC_REQBUFS, &req)             // request mmap buffers
  ioctl(fd, VIDIOC_QUERYBUF, &buf)            // get buffer info
  mmap(NULL, buf.length, PROT_READ|PROT_WRITE, MAP_SHARED, fd, buf.m.offset)
  ioctl(fd, VIDIOC_STREAMON, &type)           // start capture
  
  // Capture loop:
  ioctl(fd, VIDIOC_DQBUF, &buf)              // dequeue filled buffer
  // Process frame data at mmap'd address
  ioctl(fd, VIDIOC_QBUF, &buf)               // re-queue buffer

All via open/ioctl/mmap/read — no libc needed.

Frame processing (Sobel edge detection in ASM):
  For each pixel (x,y):
    Gx = -p[y-1][x-1] + p[y-1][x+1] - 2*p[y][x-1] + 2*p[y][x+1] - p[y+1][x-1] + p[y+1][x+1]
    Gy = -p[y-1][x-1] - 2*p[y-1][x] - p[y-1][x+1] + p[y+1][x-1] + 2*p[y+1][x] + p[y+1][x+1]
    edge = sqrt(Gx² + Gy²)

  SIMD acceleration: process 8 pixels at once with SSE2
  movdqu load → psubw → pmullw → paddw → horizontal sum
```

### E1.3 ALSA Audio Interface

```
Audio via /dev/snd/pcmC0D0c (capture device):

  fd = open("/dev/snd/pcmC0D0c", O_RDONLY)
  ioctl(fd, SNDRV_PCM_IOCTL_HW_PARAMS, &params)   // set format, rate, channels
  ioctl(fd, SNDRV_PCM_IOCTL_PREPARE)               // prepare
  
  // Capture:
  read(fd, buffer, frame_count * bytes_per_frame)
  
  // Process:
  RMS = sqrt(sum(sample² for sample in buffer) / n)
  ZCR = count(buffer[i] * buffer[i+1] < 0) / n
  Stability = 1 - variance(frame_energies)
```

---

## §38 SILK TRIPLE-DUTY IN VM

### E2.1 Classification Builtin

SPEC_E says Silk does three things: classify + locate + link.
The VM needs builtins that expose all three.

```
__silk_classify(mol)  → group_id
  Compare mol distance to all L2 branch centroids
  Return index of nearest branch
  Used by: KtLearn (decides WHERE to store new fact)

Implementation:
  For each L2 branch i:
    centroid[i] = average mol of all facts in branch
    dist[i] = mol_dist_5d(mol, centroid[i])
  Return argmin(dist)

Optimization: maintain centroid cache (updated on learn/dream)
  Cache: u16[256] — centroids of up to 256 branches
  Update: incrementally when fact added to branch

__silk_locate(mol)  → { branch_id, offset }
  After classification: find exact position within branch
  Binary search by mol within sorted branch array
  Return: branch ID + offset within branch

__silk_link(mol_a, mol_b, context_V, context_A)
  Standard Hebbian co-activation
  Already covered in §9 (SilkFire)
  This is triple-duty ③
```

### E2.2 Multi-Hop Walk with Quality Gate

```
SPEC_E defines silk walk with quality threshold:
  Continue walking only while quality(path) ≥ φ⁻¹

__silk_walk_quality(start_mol, dim, max_depth, max_results)
  visited = bitmap[65536]    // Zone C, 8 KB
  path = []
  current = start_mol
  
  for depth in 0..max_depth:
    // Find strongest edge on target dimension
    best_edge = null
    for edge in silk_edges(current):
      if edge.type == dim AND edge.weight > best_weight AND !visited[edge.other]:
        best_edge = edge
    
    if best_edge == null: break  // dead end
    
    // Quality gate: compose current path + next node
    candidate_path = path + [best_edge.other]
    path_mol = compose_chain(candidate_path)
    quality = evaluate_consistency(path_mol, start_mol)
    
    if quality < PHI_INV: break  // quality dropped below threshold
    
    path = candidate_path
    current = best_edge.other
    visited[current] = 1
  
  return path
```

---

## §39 CHAIN RECOMBINATION (SINH) IN VM

### E3.1 Generate Opcode

SPEC_E says the brain must CREATE new content, not just look up existing facts.
This is the most important missing capability.

```
New opcode:
  0x55  KtGenerate  — Generate new text via chain recombination

Implementation (builtin __kt_generate):

__kt_generate(query_text):
  // Step 1: Encode query
  query_mol = encode(query_text)
  
  // Step 2: Find dominant dimension
  dim = mol_dominant(query_mol)
  
  // Step 3: Silk walk on that dimension
  path = silk_walk_quality(query_mol, dim, depth=5, max=13)
  
  // Step 4: Compose path into new chain
  chain_new = []
  for node_mol in path:
    chain_new.push(node_mol)
  
  // Step 5: DNA Repair (quality check)
  chain_mol = compose_chain(chain_new)
  quality = evaluate(chain_mol, query_mol)
  
  if quality < PHI_INV:
    // Try different dimension
    dim2 = second_dominant(query_mol)
    path2 = silk_walk_quality(query_mol, dim2, depth=3, max=8)
    chain_new2 = compose_path(path2)
    quality2 = evaluate(chain_new2, query_mol)
    if quality2 > quality:
      chain_new = chain_new2
  
  // Step 6: Decode — convert mol chain back to text
  text = decode_chain(chain_new)
  
  // Step 7: ConversationCurve tone adjustment
  tone = conversation_curve(V_history)
  text = apply_tone(text, tone)
  
  return text

Key: this creates sentences that NEVER existed in the KnowTree.
  Like DNA recombination: genes from different parents → new organism.
```

### E3.2 Decode (∂ Derivative) Implementation

```
SPEC_E clarifies decode must work as a REVERSE of encode:

__decode_chain(chain_mols):
  text = ""
  for mol in chain_mols:
    // Find nearest fact with this mol
    fact = kt_nearest(mol, 1)
    if fact != null:
      text += fact.text + " "
    else:
      // No fact — try character-level decode
      cp = mol_to_nearest_codepoint(mol)  // reverse of encode
      text += utf8_encode(cp)
  
  // Clean up: remove duplicate spaces, fix grammar hints
  return trim(text)

Three decode channels (SPEC_A §A5):
  ∂P/∂space  = ∇f(p)  → render images (SDF visualization)
  ∂V/∂time   = V'(t)  → select emotion tone
  ∂P/∂experience = ΔP → measure novelty

For text output: primarily ∂V/∂time (tone) + ∂P/∂experience (novelty).
For visual output: ∂P/∂space (SDF rendering).
```

---

## §40 MEMORY LIFECYCLE IN VM

### E4.1 STM as First-Class VM Structure

```
STM is not just a user-level array. It needs VM-level support:

STM storage: Zone B (session-scoped)
  stm_base:   pointer to STM array start
  stm_count:  current number of entries
  stm_max:    32 (fixed)

STM entry (48 bytes):
  [mol:2][text_ptr:8][text_len:4][chain_ptr:8][chain_len:2]
  [emotion_V:1][emotion_A:1][timestamp:4][access_count:2]
  [fire_count:2][flags:2][padding:12]

Builtins:
  __stm_push(text, chain, mol, V, A)
    If stm_count >= stm_max: evict lowest-scored entry
    Append new entry, stm_count++

  __stm_evict()
    score_min = MAX
    evict_idx = -1
    for i in 0..stm_count:
      score = stm[i].access_count * 0.3
            + abs(stm[i].emotion_V) * stm[i].emotion_A * 0.4
            + recency(stm[i].timestamp) * 0.3
      if score < score_min:
        score_min = score
        evict_idx = i
    Remove stm[evict_idx], compact array

  __stm_query(mol, max_results)
    Sort STM entries by distance to mol
    Return top max_results entries
```

### E4.2 Working Memory (WM) as VM Registers

```
WM = 4 dedicated molecule slots, separate from register frame.
Used by pipeline during a single response cycle.

Implementation: 4 global u16 values in VM data section

  wm_query:     u16    ; wm[0] = current input molecule
  wm_context:   u16    ; wm[1] = composed recent STM context
  wm_candidate: u16    ; wm[2] = best response candidate
  wm_result:    u16    ; wm[3] = final after DNA repair

Builtins:
  __wm_bind(slot, mol)    ; set WM slot
  __wm_read(slot)         ; get WM slot value
  __wm_clear()            ; reset all 4 slots to 0

Pipeline flow:
  __wm_bind(0, encode(input))
  __wm_bind(1, compose_recent_stm())
  __wm_bind(2, immune_select(3_branches))
  __wm_bind(3, dna_repair(__wm_read(2)))
  response = decode(__wm_read(3))
  __wm_clear()
```

### E4.3 Dream Cycle VM Support

```
Dream needs VM-level support for:
  1. Timer/trigger mechanism
  2. STM scanning
  3. Cross-branch clustering
  4. QR promotion

New builtins:
  __dream_trigger()
    Check conditions:
      Any STM entry with fire_count >= Fibonacci[n]? → YES
      idle_time > 300 seconds? → YES
      heap_usage > 80%? → YES
    If any YES: execute dream cycle

  __dream_cluster(stm_entries)
    For each pair (A, B) in STM:
      if silk_weight(A.mol, B.mol) > PHI_INV AND different_branches(A, B):
        cluster.add(A, B)
    For each cluster:
      lca_mol = compose(cluster_members)
      proposal = { mol: lca_mol, members: cluster, type: HYPOTHESIS }
    Return proposals

  __dream_promote(proposal)
    quality = evaluate(proposal)
    if quality >= PHI_INV AND fire_count >= Fibonacci[depth]:
      // AAM approve
      kt_store(proposal.mol, proposal.text, proposal.chain)
      fact.maturity = QR  // promoted to permanent
      qr_append(proposal)  // append-only log
      return true
    return false

  __dream_decay()
    For each silk edge:
      hours_since = (now - edge.last_fire) / 3600
      decay_periods = hours_since / 24
      for i in 0..decay_periods:
        edge.weight = edge.weight * 618 / 1000  // φ⁻¹ per 24h
      if edge.weight < PRUNE_THRESHOLD AND edge.fire_count == 0:
        edge.flags |= SUPERSEDED
```

---

## §41 SELF-MODEL IN VM

### E5.1 Knowledge Map

```
SPEC_E says Nox must know WHAT it knows and WHAT it doesn't.

__self_model()  → array of { group_name, strength }
  For each L2 branch:
    count = facts_in_branch(branch)
    avg_silk = mean_silk_weight(branch)
    qr_ratio = qr_count(branch) / count
    
    strength = 0.4 * qr_ratio + 0.3 * avg_silk + 0.3 * min(count/100.0, 1.0)
    
    result.push({ name: branch.name, strength: strength })
  
  Sort by strength descending
  Return result

Usage in pipeline:
  Before responding, check confidence:
    domain = silk_classify(query_mol)
    conf = self_model[domain].strength
    if conf < 0.40: return "I don't know about this topic."
    if conf < 0.70: prefix = "I think..."
    if conf < 0.90: prefix = "Perhaps..."
    else: prefix = ""  // confident, no hedging
```

### E5.2 Self-Modification Awareness

```
After self-modify cycle, Nox should UPDATE its self-model:

__self_inspect()
  Read own source files (stdlib/*.ol)
  For each file:
    functions = parse_function_list(file)
    for fn in functions:
      if not kt_has_fact("fn:" + fn.name):
        kt_learn("I have function " + fn.name + " in " + file)
  
  This gives Nox knowledge of its own capabilities.
  "What can you do?" → silk walk on self-knowledge branch → list capabilities
```

---

## §42 NAC.mb 30 ALGORITHMS — VM REQUIREMENTS

### E6.1 Pruning Opcodes

```
Already covered by silk_decay in §S4. Additional:

__prune_supersede(mol_a, mol_b)
  If distance(mol_a, mol_b) < SUPERSEDE_THRESHOLD AND fire(b) > fire(a):
    fact_a.flags |= SUPERSEDED
    fact_a.superseded_by = mol_b
    // NOT deleted — marked as intron (unexpressed DNA)

__prune_conflict(mol_a, mol_b)
  d_V = abs(unpack_V(mol_a) - unpack_V(mol_b))
  d_R = abs(unpack_R(mol_a) - unpack_R(mol_b))
  if d_V > CONTRADICT_V_THRESHOLD AND d_R < CONTRADICT_R_THRESHOLD:
    // Contradiction detected
    winner = (fact_a.maturity >= QR) ? a :
             (fact_b.maturity >= QR) ? b :
             (fact_a.fire_count > fact_b.fire_count) ? a : b
    loser = (winner == a) ? b : a
    loser.flags |= SUPERSEDED
```

### E6.2 Stochastic Perturbation

```
__dream_perturb(mol)
  // Random mutate ONE dimension
  dim = getrandom() % 5
  delta = (getrandom() % 3) - 1  // -1, 0, or +1
  
  new_mol = mol
  switch dim:
    0: new_mol.S = clamp(mol.S + delta, 0, 15)
    1: new_mol.R = clamp(mol.R + delta, 0, 15)
    2: new_mol.V = clamp(mol.V + delta, 0, 7)
    3: new_mol.A = clamp(mol.A + delta, 0, 7)
    4: new_mol.T = clamp(mol.T + delta, 0, 3)
  
  // Test if perturbation is valid
  nearest = kt_nearest(new_mol, 1)
  if nearest != null AND nearest.mol != mol:
    // Perturbation created something new and valid
    return new_mol
  return null  // perturbation didn't produce useful result
```

### E6.3 Negative Knowledge

```
__negative_mark(mol, reason_text)
  fact = kt_load(mol)
  fact.flags |= PROHIBITED
  fact.reason_ptr = alloc_a(reason_text)
  fact.reason_len = len(reason_text)
  
  // Also mark in SecurityGate Bloom filter
  bloom_insert(security_bloom, mol)

__negative_check(mol)
  fact = kt_load(mol)
  if fact != null AND (fact.flags & PROHIBITED):
    return { prohibited: true, reason: fact.reason_ptr }
  if bloom_check(security_bloom, mol):
    return { prohibited: true, reason: "Security gate match" }
  return { prohibited: false }

Blacklist meta-links:
  When two mols are BOTH fired AND one has negative flag:
    __silk_negative_alert(mol_a, mol_b)
    → Log warning
    → Insert SecurityGate entry for the combination
```

### E6.4 Archive / Hyper-Axon

```
__archive_compress(branch_id, threshold)
  // Compress old QR facts into summary hyper-axon
  facts = get_facts_in_branch(branch_id)
  old_facts = filter(facts, f => f.fire_count < threshold AND f.maturity == QR)
  
  if len(old_facts) > 100:
    // Create hyper-axon: compose all old facts into single summary
    summary_mol = compose_all(old_facts.map(f => f.mol))
    summary_text = "Summary of " + len(old_facts) + " facts in " + branch_name
    
    // Store summary as new fact
    kt_store(summary_mol, summary_text, compose_chain(old_facts))
    
    // Mark old facts as archived (still exist, but not in active search)
    for f in old_facts:
      f.flags |= ARCHIVED

__archive_recall(mol)
  // Search archived facts
  for each fact with ARCHIVED flag:
    if mol_dist(fact.mol, mol) < RECALL_THRESHOLD:
      fact.flags &= ~ARCHIVED  // un-archive
      fact.fire_count = 1       // reset
      return fact
  return null
```

### E6.5 Swarm Intelligence (Multi-Nox)

```
For future multi-Nox deployment:

__swarm_broadcast(alert_mol)
  // Send P_weight warning to all connected Nox instances
  for each peer in peer_list:
    send(peer.socket, { type: ALERT, mol: alert_mol })

__swarm_vote(proposal_mol)
  // Request vote from peers on QR promotion
  votes = 0
  total = len(peer_list)
  for each peer in peer_list:
    send(peer.socket, { type: VOTE_REQUEST, mol: proposal_mol })
    response = recv(peer.socket)
    if response.approve: votes++
  
  if votes >= (total * 2 / 3):
    return APPROVED
  return REJECTED

__swarm_sync(peer_socket)
  // Sync new QR records with a peer
  my_qr = get_qr_since(last_sync_time)
  send(peer_socket, { type: SYNC, records: my_qr })
  their_qr = recv(peer_socket)
  for record in their_qr:
    if verify_signature(record):
      kt_merge(record)
```

---

## §43 CONVERSATION CURVE IN VM

### E7.1 Tone Selection Algorithm

```
SPEC_E specifies tone is derived from valence TRAJECTORY, not snapshot.

V_history: circular buffer of last 8 turns' valence values
  v_history[8]: u8  (valence 0-7 per turn)
  v_ptr: u8         (current position in ring buffer)

__conversation_curve()
  V = v_history[v_ptr]                    // current
  V_prev = v_history[(v_ptr - 1) % 8]    // previous
  V_prev2 = v_history[(v_ptr - 2) % 8]   // 2 turns ago
  
  V_prime = V - V_prev                    // first derivative (velocity)
  V_double = V_prime - (V_prev - V_prev2) // second derivative (acceleration)
  
  // Tone selection (from SPEC_D §D7):
  if V_prime < -1:       return SUPPORTIVE    // declining → support
  if V_double < -2:      return PAUSE         // accelerating decline → wait
  if V_prime > 1:        return REINFORCING   // improving → encourage
  if V_double > 2 AND V > 4: return CELEBRATORY  // breakthrough
  if V < 2 AND abs(V_prime) < 1: return GENTLE   // sad but stable
  return ENGAGED                               // normal

__update_v_history(current_response_mol)
  v = unpack_V(current_response_mol)
  v_ptr = (v_ptr + 1) % 8
  v_history[v_ptr] = v
```

### E7.2 Tone Application

```
__apply_tone(chain, tone)
  switch tone:
    SUPPORTIVE:
      // Boost V dimension in response chain
      for i in 0..chain.len:
        chain[i].V = min(chain[i].V + 1, 7)
    
    PAUSE:
      // Truncate response to short
      chain = chain[0..min(3, chain.len)]
    
    REINFORCING:
      // Keep as-is, add exclamation cue
    
    CELEBRATORY:
      // Boost both V and A
      for i in 0..chain.len:
        chain[i].V = min(chain[i].V + 2, 7)
        chain[i].A = min(chain[i].A + 1, 7)
    
    GENTLE:
      // Lower A (reduce intensity)
      for i in 0..chain.len:
        chain[i].A = max(chain[i].A - 1, 0)
    
    ENGAGED:
      // No modification
  
  return chain
```

---

## §44 HOMEOSTASIS IN VM

### E8.1 Free Energy Computation

```
SPEC_D §D4 defines Homeostasis via free energy F(t).

__homeostasis()
  // F(t) = sqrt(Σ w_d × (predicted_d - actual_d)²)
  // where w_d = P_weight dominance of each dimension
  
  predicted = wm_context    // what brain expected (from recent STM compose)
  actual = wm_query         // what actually arrived (current input)
  
  dS = abs(unpack_S(predicted) - unpack_S(actual))
  dR = abs(unpack_R(predicted) - unpack_R(actual))
  dV = abs(unpack_V(predicted) - unpack_V(actual))
  dA = abs(unpack_A(predicted) - unpack_A(actual))
  dT = abs(unpack_T(predicted) - unpack_T(actual))
  
  // Weights from dominant dimension
  w = [1, 1, 2, 2, 4]  // same as distance weights
  
  F = isqrt(w[0]*dS*dS + w[1]*dR*dR + w[2]*dV*dV + w[3]*dA*dA + w[4]*dT*dT)
  
  // Mode switch
  PHI_INV_SCALED = 4  // φ⁻¹ scaled to integer range
  
  if F > PHI_INV_SCALED:
    mode = LEARNING    // high surprise → increase learning rate
    learning_rate = 2  // amplified learning
    dream_more = true
  else:
    mode = ACTING      // low surprise → respond confidently
    learning_rate = 1  // normal
    dream_more = false
  
  return { F, mode, learning_rate }
```

---


> *"E does not ADD to A-D. E IMPLEMENTS A-D as a living organism."*
> *"The VM provides the body. SPEC_E provides the breath."*


---



# PART V — PIPELINE SUPPORT





---

## §45 SPREADING ACTIVATION ENGINE

BP5 Layer 2 uses Spreading Activation (Collins & Loftus 1975).
This requires an **activation map**: mol → activation_value.

### Problem in Current VM

Olang has no hashmap. BP5 works around this with parallel arrays, but:
- Array scan for existing mol = O(n) per step
- N active nodes × M edges × S steps = O(N×M×S) total
- For 1000 active nodes, 10 edges each, 5 steps = 50,000 operations per query
- Each operation involves array scan = unusable at scale

### VM Solution: Activation Matrix (M7)

```
Second u16 matrix dedicated to activation values:

  act_matrix: u16[65,536]
  Index = mol & 0xFFFF
  Value = activation level (0..65535)

Operations (all O(1)):
  __act_set(mol, value)     → act_matrix[mol] = value
  __act_get(mol)            → return act_matrix[mol]
  __act_add(mol, delta)     → act_matrix[mol] += delta (clamped)
  __act_decay_all(factor)   → for each: val = val * factor / 1000
  __act_reset()             → memset(act_matrix, 0, 128KB)
  __act_top_k(k)            → return k highest-activation mols

Memory: 65,536 × 2 bytes = 128 KB (fits L2 cache)

Placement in memory layout:
  [var_matrix 1MB][kt_matrix 128KB][silk_matrix 128KB][act_matrix 128KB]
```

### SIMD Batch Decay

```asm
; Decay all activations by factor (e.g., 800/1000 = 0.8)
; Process 8 values per SSE2 iteration

act_decay_all:
    mov rsi, [act_matrix_base]
    mov rcx, 65536 / 8          ; 8192 iterations
    movdqu xmm1, [factor_vec]   ; 8 copies of decay factor (e.g., 800)
    
.loop:
    movdqu xmm0, [rsi]          ; load 8 activation values
    pmulhuw xmm0, xmm1          ; multiply and take high word (÷65536)
    ; Adjust: we want val * 800 / 1000, not val * 800 / 65536
    ; Solution: pre-scale factor = 800 * 65536 / 1000 = 52429
    movdqu [rsi], xmm0          ; store result
    add rsi, 16
    dec rcx
    jnz .loop

Throughput: 65,536 values / 8 per iter = 8,192 iterations
  At ~3 clocks/iter = ~25K clocks = ~8 μs at 3 GHz
  vs scalar: ~200K clocks = ~65 μs
  Speedup: 8×
```

### __act_top_k Implementation

```
Finding top-K activated nodes without sorting entire matrix:

__act_top_k(k):
  // Maintain min-heap of size K
  heap = [0] × k
  heap_min = 0
  
  for i in 0..65536:
    val = act_matrix[i]
    if val > heap_min:
      // Replace minimum in heap
      heap_replace_min(heap, k, { mol: i, activation: val })
      heap_min = heap[0].activation
  
  return heap sorted by activation descending

Time: O(N log K) where N=65536, K=10 → O(65536 × 4) ≈ O(260K)
With SIMD comparison: find max of 8 simultaneously → O(32K)
```

---

## §46 IMMUNE SELECTION (CLONALG)

BP5 Layer 3 uses CLONALG for hypothesis generation.
Key VM requirements:

### Deterministic Pseudo-Random

BP5 defines `_pseudo_select` for reproducible "randomness":
```
_pseudo_select(mol, gen, max) = (mol * 2654435761 + gen * 40503) % max
```

This MUST be a builtin for fixed-point correctness:

```
__pseudo_select(mol, gen, max):
  ; Uses Fibonacci hash constants
  ; 2654435761 = 32-bit golden ratio constant
  ; 40503 = 16-bit golden ratio constant
  
  imul eax, [mol], 2654435761
  imul ecx, [gen], 40503
  add eax, ecx
  xor edx, edx
  div [max]            ; edx = remainder
  return edx

Why builtin: integer overflow behavior must be IDENTICAL across
  Gen0 compile and Gen1 compile. Olang's floor/mod might differ
  in edge cases. ASM guarantees bit-exact.
```

### Chain Copy and Mutation

CLONALG mutates chains. The VM needs efficient chain operations:

```
__chain_copy(chain_ptr)  → new chain in Zone C (temporary)
  Allocate new chain with same length
  memcpy contents
  Return new pointer

__chain_mutate(chain_ptr, idx, new_mol)  → modified chain
  chain_ptr[idx] = new_mol
  Recompute chain hash (optional)

__chain_compose(chain_ptr)  → u16 composed molecule
  Iterate chain, compose all molecules sequentially
  Uses Zipf weighting: w[0]=1000, w[1]=500, w[2]=333, ...

These should be Zone C allocations (freed after pipeline cycle).
```

### Affinity Score Computation

```
__chain_affinity(chain_ptr, query_mol):
  composed = __chain_compose(chain_ptr)
  dist = 1000 - __mol_dist_5d(composed, query_mol) * 100 / 70
  silk = __chain_avg_silk(chain_ptr)
  consistency = __chain_dim_consistency(chain_ptr)
  return (dist * 400 + silk * 300 + consistency * 300) / 1000

__chain_dim_consistency(chain_ptr):
  // Variance per dimension across chain nodes
  // Low variance = high consistency
  For each dimension d:
    mean_d = mean(mol_get_dim(chain[i], d) for i in chain)
    var_d = mean((mol_get_dim(chain[i], d) - mean_d)² for i in chain)
  total_var = sum(var_d for d in 0..5)
  return 1000 - min(total_var * 100, 1000)
```

---

## §47 DCA DANGER SIGNALS

BP5 Layer 4 uses Dendritic Cell Algorithm for repair.
Key VM requirement: dimensional jump detection.

```
__chain_dimensional_jump(chain_ptr, index):
  if index == 0 or index >= chain.len - 1: return 0
  
  prev = chain[index - 1]
  curr = chain[index]
  next = chain[index + 1]
  
  jump = 0
  for d in 0..5:
    p = mol_get_dim(prev, d)
    c = mol_get_dim(curr, d)
    n = mol_get_dim(next, d)
    expected = (p + n) / 2
    jump += abs(c - expected)
  
  return jump

Why this matters:
  A "dimensional jump" means a node in the chain is INCONSISTENT
  with its neighbors. Like a word that doesn't fit the sentence.
  DCA uses this to identify WHERE to repair.
```

### Implicit Neighbors (5D Grid)

```
__implicit_neighbors(mol, dim, count):
  // Return `count` nearest molecules along dimension `dim`
  // by stepping ±1, ±2, ... in that dimension
  
  results = []
  S, R, V, A, T = unpack(mol)
  
  for delta in [-2, -1, 1, 2]:
    new_mol = mol
    switch dim:
      0: new_mol = pack(clamp(S+delta,0,15), R, V, A, T)
      1: new_mol = pack(S, clamp(R+delta,0,15), V, A, T)
      2: new_mol = pack(S, R, clamp(V+delta,0,7), A, T)
      3: new_mol = pack(S, R, V, clamp(A+delta,0,7), T)
      4: new_mol = pack(S, R, V, A, clamp(T+delta,0,3))
    
    if kt_matrix[new_mol] != 0:  // has a fact at this mol
      results.push(new_mol)
    if len(results) >= count: break
  
  return results

This is already implicit in kt_nearest but dedicated for dimension-specific walk.
```

### Implicit Strength

```
__implicit_strength(mol_a, mol_b):
  // Strength = inverse of distance, normalized
  d = mol_dist_5d(mol_a, mol_b)
  if d == 0: return 1000    // identical = maximum strength
  return max(0, 1000 - d * 1000 / 70)  // 70 = max distance

Zero storage. Computed on demand.
37 channels × 31 compound patterns = 1,147 implicit silk types.
Each channel = which dimensions to include in distance calculation.
```

---

## §48 DECODE ∂ SUPPORT

### String Operations for Maximal Join

BP5 Layer 5 needs word-level string operations:

```
__str_split(text, delimiter)  → array of substrings
  Scan text for delimiter occurrences
  Return array of (ptr, len) pairs for each segment
  Allocate in Zone C (temporary)

  Already exists as workaround using char_at loops.
  Builtin version: 10-50× faster (no per-char allocation)

__str_find_word(haystack, word)  → position or -1
  Like __str_find but respects word boundaries
  "Hà Nội" found in "Hà Nội là thủ đô" → position 0
  "Hà" NOT found as word in "Hà Nội" (part of longer word)

__str_remove_first(text, word)  → new text with first occurrence removed
  Find word → create new string = before + after
  Zone C allocation
```

### Reverse Mol-to-Text Lookup

For true ∂ decode, need reverse mapping:

```
__mol_to_text(mol)  → nearest text for this molecule
  1. Check kt_matrix[mol] → exact match → return fact text
  2. If no exact: check mol ±1 in each dimension (5 neighbors)
  3. If still none: return character-level decode
     → Map mol to nearest UDC codepoint → UTF-8 encode

Character-level decode:
  __mol_to_codepoint(mol):
    Scan UDC table for nearest P_weight match
    Return codepoint
    
  This is the INVERSE of encode:
    Encode: codepoint → 42 formulas → P_weight
    Decode: P_weight → nearest codepoint (reverse lookup)
    
  Can be pre-computed as reverse table:
    rev_table[65536]: u32 codepoint indexed by P_weight
    Build once at boot from UDC data.
    128 KB storage. O(1) reverse lookup.
```

---

## §49 QUALITY FUNCTION AS VM BUILTIN

Quality is computed repeatedly (affinity, repair, checkpoints).
Making it a builtin avoids repeated Olang interpretation overhead.

```
__chain_quality(chain_ptr, query_mol):
  // v = validity (all mols non-zero and in matrix)
  valid = 0
  for i in 0..chain.len:
    if chain[i] != 0 AND kt_matrix[chain[i]] != 0:
      valid++
  v = valid * 1000 / chain.len
  
  // h = 1 - entropy/2.32 (lower entropy = more coherent)
  // Compute Shannon entropy of dimension distribution
  dim_counts = [0, 0, 0, 0, 0]
  for i in 0..chain.len:
    dim = mol_dominant(chain[i])
    dim_counts[dim]++
  entropy = 0
  for d in 0..5:
    p = dim_counts[d] * 1000 / chain.len
    if p > 0:
      entropy += p * log2_approx(p) / 1000
  h = 1000 - min(entropy * 1000 / 2320, 1000)
  
  // c = consistency (low variance per dimension)
  c = __chain_dim_consistency(chain_ptr)
  
  // s = silk (average implicit strength between consecutive)
  silk_sum = 0
  for i in 0..chain.len-1:
    silk_sum += __implicit_strength(chain[i], chain[i+1])
  s = silk_sum / max(chain.len - 1, 1)
  
  return (300 * v + 300 * h + 200 * c + 200 * s) / 1000

Integer log2 approximation:
  __log2_approx(x):
    // For x in [1..1000]:
    // log2(x) ≈ position of highest set bit
    result = 0
    while x > 1:
      x >>= 1
      result++
    return result * 100  // scaled to 0..1000
```

---

## §50 PIPELINE ORCHESTRATION

The full pipeline flow as VM builtins:

```
__pipeline_respond(input_text):
  // CP1: Security gate
  if __security_gate(input_text) != SAFE: return BLOCKED
  
  // Layer 1: Capture
  mol = encode(input_text)
  dim = mol_dominant(mol)
  __wm_bind(0, mol)
  
  // CP2: Encode valid
  if mol == 0: return ""
  
  // Instinct gate
  confidence = __instinct_honesty(mol)
  if confidence < 400: return ""  // silence — don't know
  
  // Layer 2: Spreading Activation
  __act_reset()
  __act_set(mol, 1000)
  for step in 0..5:
    __spread_step(dim)
  activated = __act_top_k(10)
  
  // Layer 3: CLONALG Hypothesis
  candidates = __clonalg_generate(activated, mol, 3)  // 3 candidates
  
  // CP3: At least 1 candidate quality >= 618
  best = null
  for chain in candidates:
    q = __chain_quality(chain, mol)
    if q >= 618 AND (best == null OR q > best_quality):
      best = chain
      best_quality = q
  
  if best == null: return ""  // no good candidate
  __wm_bind(2, __chain_compose(best))
  
  // Layer 4: DCA Repair
  repaired = __dca_repair(best, mol, 3)
  __wm_bind(3, __chain_compose(repaired))
  
  // CP4: Quality check after repair
  final_q = __chain_quality(repaired, mol)
  if final_q < best_quality: repaired = best  // rollback if worse
  
  // Layer 5: Decode ∂
  text = __decode_generate(repaired, mol)
  
  // CP5: Security gate on output
  if __security_gate(text) != SAFE: return FILTERED
  
  // Tone
  tone = __conversation_curve()
  text = __apply_tone(text, tone)
  
  // Learn from interaction
  __stm_push(input_text, repaired, mol)
  __silk_fire_coactivate(mol, __wm_read(1))  // co-activate with context
  
  // Homeostasis update
  __homeostasis_update(mol)
  
  // Clean up
  __wm_clear()
  __act_reset()
  // Zone C auto-resets after response
  
  return text
```

---


> *"The pipeline is the mind.*
> *The VM is the body that runs the mind.*
> *When the body is strong, the mind thinks faster."*
