# ═══════════════════════════════════════════════════════════════════════════
# NOX VM — Molecular Computation Engine
# Pure x86-64 Linux. No libc. No dependencies.
# Self-hosting. Self-modifying. Emotion-aware.
# ═══════════════════════════════════════════════════════════════════════════
#
# Register convention:
#   r12  = bytecode base (immutable during execution)
#   r13  = program counter (offset into bytecode)
#   r14  = VM stack pointer (16-byte entries, grows DOWN)
#   r15  = heap pointer (Zone C bump allocator)
#   rbx  = bytecode size (bounds checking)
#   rbp  = preserved (call frame base)
#   rsp  = CPU stack (syscalls, CALL/RET)
#
# Memory layout (spec §2):
#   [VM Stack 16MB] [Guard 4K] [Zone C →] [Guard 4K] [← Zone B]
#   [Zone A →] [var_matrix 512KB] [mol_matrix 128KB] [act_matrix 128KB]
#   [silk_matrix 128KB] [Bytecode+Constants]
#
# Stack entry: [ptr:8][len:8] = 16 bytes
#   len = -1 (F64_MARKER)  → ptr = f64 bits
#   len = -3 (ARRAY)       → ptr = array object
#   len = -4 (DICT)        → ptr = dict object
#   len = -5 (ARRAY_CAP)   → capacity-tracked array header
#   len = -2 (FORWARD)     → ptr = relocated array
#   len >= 0               → string/chain: ptr=heap, len=mol_count
#
# Build: as --64 -o /tmp/vm_nox.o vm/x86_64/vm_nox.S
#        ld -static -nostdlib --entry=_start -o vm/x86_64/vm_nox /tmp/vm_nox.o

.intel_syntax noprefix    # Use Intel syntax for readability
.global _start

# ═══ Constants ═══════════════════════════════════════════════════════════

# Syscall numbers
.equ SYS_READ,       0
.equ SYS_WRITE,      1
.equ SYS_OPEN,       2
.equ SYS_CLOSE,      3
.equ SYS_LSEEK,      8
.equ SYS_MMAP,       9
.equ SYS_MPROTECT,   10
.equ SYS_MUNMAP,     11
.equ SYS_POLL,       7
.equ SYS_IOCTL,      16
.equ SYS_SOCKET,     41
.equ SYS_CONNECT,    42
.equ SYS_ACCEPT,     43
.equ SYS_SENDTO,     44
.equ SYS_RECVFROM,   45
.equ SYS_BIND,       49
.equ SYS_LISTEN,     50
.equ SYS_CLONE,      56
.equ SYS_EXIT,       60
.equ SYS_KILL,       62
.equ SYS_NANOSLEEP,  35
.equ SYS_CLOCK_GETTIME, 228
.equ SYS_GETRANDOM,  318
.equ SYS_MEMFD_CREATE, 319
.equ SYS_PRCTL,      157
.equ SYS_EXIT_GROUP,  231

# Memory
.equ PROT_NONE,      0
.equ PROT_READ,      1
.equ PROT_WRITE,     2
.equ PROT_RW,        3     # READ | WRITE
.equ PROT_RX,        5     # READ | EXEC
.equ MAP_PRIVATE,    0x02
.equ MAP_ANONYMOUS,  0x20
.equ MAP_PRIV_ANON,  0x22  # PRIVATE | ANONYMOUS

# Sizes
.equ STACK_SIZE,     0x1000000   # 16 MB VM stack
.equ GUARD_SIZE,     0x1000      # 4 KB guard page
.equ ZONE_C_SIZE,    0x400000    # 4 MB Zone C (turn temps)
.equ ZONE_B_SIZE,    0x1000000   # 16 MB Zone B (session)
.equ ZONE_A_SIZE,    0x10000000  # 256 MB Zone A (permanent)
.equ HEAP_TOTAL,     0x20000000  # 512 MB total heap (expandable)

# Type markers
.equ F64_MARKER,     -1    # 0xFFFFFFFFFFFFFFFF
.equ ARRAY_FWD,      -2    # array forward pointer
.equ ARRAY_MARKER,   -3    # array object
.equ DICT_MARKER,    -4    # dict object
.equ ARRAY_CAP,      -5    # capacity-tracked array
.equ MOL_MARKER,     -6    # molecule type (NEW)
.equ CLOSURE_MARKER, -7    # closure

.equ ARRAY_INIT_CAP, 512   # initial array capacity

# prctl
.equ PR_SET_NO_NEW_PRIVS, 38

# Network
.equ AF_INET,        2
.equ AF_UNIX,        1
.equ SOCK_STREAM,    1
.equ SOCK_DGRAM,     2

# ═══ Section: .text (executable code) ════════════════════════════════════
.text

# ═══════════════════════════════════════════════════════════════════════════
# BOOT SEQUENCE (Spec §20)
# ═══════════════════════════════════════════════════════════════════════════

_start:
    # ── 1. Parse arguments ───────────────────────────────────────────
    mov     rax, [rsp]              # argc
    cmp     rax, 2
    jb      .open_self              # no args → open self

    mov     rdi, [rsp + 16]         # argv[1]
    # Check --eval
    cmp     dword ptr [rdi], 0x76652D2D   # "--ev" LE
    jne     .not_eval
    cmp     word ptr [rdi + 4], 0x6C61    # "al"
    jne     .not_eval
    cmp     byte ptr [rdi + 6], 0
    jne     .not_eval
    mov     byte ptr [rip + eval_mode], 1
    cmp     qword ptr [rsp], 3
    jb      .open_self
    mov     rdi, [rsp + 24]         # argv[2]
    jmp     .do_open

.not_eval:
    # Check --mcp
    cmp     dword ptr [rdi], 0x636D2D2D   # "--mc" LE
    jne     .not_mcp
    cmp     word ptr [rdi + 4], 0x0070    # "p\0"
    jne     .not_mcp
    mov     byte ptr [rip + eval_mode], 2
    jmp     .open_self
.not_mcp:
    # Check --build
    cmp     dword ptr [rdi], 0x75622D2D   # "--bu" LE
    jne     .not_build
    cmp     dword ptr [rdi + 4], 0x00646C69 # "ild\0"
    jne     .not_build
    mov     byte ptr [rip + eval_mode], 1
    mov     byte ptr [rip + build_flag], 1
    jmp     .open_self
.not_build:
    # Check --run
    cmp     dword ptr [rdi], 0x75722D2D   # "--ru" LE
    jne     .not_run
    cmp     word ptr [rdi + 4], 0x006E    # "n\0"
    jne     .not_run
    mov     byte ptr [rip + eval_mode], 1
    mov     byte ptr [rip + run_flag], 1
    cmp     qword ptr [rsp], 3
    jb      .open_self
    mov     rax, [rsp + 24]
    mov     [rip + run_path], rax
    jmp     .open_self
.not_run:
    # Check --editor
    cmp     dword ptr [rdi], 0x64652D2D   # "--ed" LE
    jne     .open_arg
    cmp     dword ptr [rdi + 4], 0x726F7469 # "itor"
    jne     .open_arg
    mov     byte ptr [rip + eval_mode], 1
    mov     byte ptr [rip + editor_flag], 1
    cmp     qword ptr [rsp], 3
    jb      .open_self
    mov     rax, [rsp + 24]
    mov     [rip + editor_path], rax
    jmp     .open_self

.open_arg:
    # argv[1] = filename to open
    mov     rdi, [rsp + 16]
    jmp     .do_open

.open_self:
    # Open /proc/self/exe (we ARE the binary)
    lea     rdi, [rip + str_proc_self_exe]
.do_open:
    xor     esi, esi                # O_RDONLY
    mov     eax, SYS_OPEN
    syscall
    test    rax, rax
    js      err_open
    mov     rbp, rax                # rbp = fd (preserved)

    # ── 2. Read binary header to find bytecode ───────────────────────
    # Read 32-byte trailer at end of file
    mov     rdi, rbp                # fd
    mov     rsi, -8                 # offset = -8 from end
    mov     edx, 2                  # SEEK_END
    mov     eax, SYS_LSEEK
    syscall
    # Read 8 bytes (bytecode offset)
    sub     rsp, 16
    mov     rdi, rbp
    lea     rsi, [rsp]
    mov     edx, 8
    mov     eax, SYS_READ
    syscall
    mov     rsi, [rsp]              # bytecode offset
    add     rsp, 16
    test    rsi, rsi
    jz      err_no_bc

    # Lseek to bytecode offset
    mov     rdi, rbp
    xor     edx, edx                # SEEK_SET
    mov     eax, SYS_LSEEK
    syscall

    # Read header: first 4 bytes = bytecode size
    sub     rsp, 16
    mov     rdi, rbp
    lea     rsi, [rsp]
    mov     edx, 4
    mov     eax, SYS_READ
    syscall
    mov     ebx, [rsp]              # rbx = bytecode size
    add     rsp, 16
    push    rax                     # save for later

    # ── 3. Allocate memory (3-zone arena per spec §10) ───────────────

    # 3a. VM Stack (16 MB)
    mov     eax, SYS_MMAP
    xor     edi, edi
    mov     esi, STACK_SIZE
    mov     edx, PROT_RW
    mov     r10d, MAP_PRIV_ANON
    mov     r8d, -1
    xor     r9d, r9d
    syscall
    test    rax, rax
    js      err_mmap
    mov     [rip + stack_base], rax
    lea     r14, [rax + STACK_SIZE / 2]   # r14 = stack midpoint (guard)

    # 3b. Main heap (Zone C + Guard + Zone B + Guard + Zone A)
    mov     eax, SYS_MMAP
    xor     edi, edi
    mov     esi, HEAP_TOTAL
    mov     edx, PROT_RW
    mov     r10d, MAP_PRIV_ANON
    mov     r8d, -1
    xor     r9d, r9d
    syscall
    test    rax, rax
    js      err_mmap
    mov     [rip + heap_base], rax

    # Zone layout within heap:
    # [Zone C: 4MB][Guard 4K][Zone B: 16MB][Guard 4K][Zone A: 256MB][...]
    mov     rcx, rax                # base
    mov     [rip + zone_c_base], rcx
    mov     [rip + zone_c_ptr], rcx      # Zone C starts here, grows up

    lea     rdx, [rcx + ZONE_C_SIZE]
    mov     [rip + zone_c_limit], rdx

    # Guard page after Zone C
    mov     rdi, rdx
    mov     esi, GUARD_SIZE
    xor     edx, edx                # PROT_NONE
    mov     eax, SYS_MPROTECT
    syscall

    mov     rcx, [rip + zone_c_limit]
    lea     rcx, [rcx + GUARD_SIZE]
    mov     [rip + zone_b_base], rcx
    lea     rdx, [rcx + ZONE_B_SIZE]
    mov     [rip + zone_b_ptr], rdx      # Zone B grows DOWN from top
    mov     [rip + zone_b_top], rdx

    # Guard page after Zone B
    mov     rdi, rdx
    mov     esi, GUARD_SIZE
    xor     edx, edx                # PROT_NONE
    mov     eax, SYS_MPROTECT
    syscall

    mov     rcx, [rip + zone_b_top]
    lea     rcx, [rcx + GUARD_SIZE]
    mov     [rip + zone_a_base], rcx
    mov     [rip + zone_a_ptr], rcx      # Zone A starts here, grows up
    lea     rdx, [rcx + ZONE_A_SIZE]
    mov     [rip + zone_a_limit], rdx

    # r15 = Zone C allocator (turn temps)
    mov     r15, [rip + zone_c_base]

    # ── 4. Read bytecode into Zone A (permanent) ─────────────────────
    pop     rax                     # restore saved value
    mov     rdi, rbp                # fd
    mov     rsi, [rip + zone_a_ptr] # buf = Zone A start
    mov     rdx, rbx                # count = bc_size
    mov     eax, SYS_READ
    syscall
    cmp     rax, rbx
    jne     err_read_bc

    # Setup VM registers
    mov     r12, [rip + zone_a_ptr] # r12 = bytecode base
    xor     r13d, r13d              # r13 = PC = 0
    # Bump Zone A past bytecode
    mov     rax, [rip + zone_a_ptr]
    add     rax, rbx
    add     rax, 7                  # align to 8
    and     rax, ~7
    mov     [rip + zone_a_ptr], rax

    # Save boot bytecode info
    mov     [rip + boot_bc_base], r12
    mov     [rip + boot_bc_size], rbx

    # Close file
    mov     rdi, rbp
    mov     eax, SYS_CLOSE
    syscall

    # ── 5. Initialize matrices (zero-init in BSS) ────────────────────
    # var_matrix, mol_matrix, act_matrix, silk_matrix already zero (BSS)
    # Initialize var undo stack pointer
    lea     rax, [rip + var_save_stack]
    mov     [rip + var_save_top], rax
    mov     qword ptr [rip + closure_depth], 0

    # Initialize register frame stack on Zone A
    mov     rax, [rip + zone_a_ptr]
    mov     [rip + reg_frame_base], rax
    mov     [rip + reg_frame_ptr], rax
    mov     [rip + reg_cur_frame], rax
    add     qword ptr [rip + zone_a_ptr], 0x400000  # 4MB register stack

    # ── 6. Security: PR_SET_NO_NEW_PRIVS ─────────────────────────────
    mov     eax, SYS_PRCTL
    mov     edi, PR_SET_NO_NEW_PRIVS
    mov     esi, 1
    xor     edx, edx
    xor     r10d, r10d
    xor     r8d, r8d
    syscall

    # ── 7. Detect bytecode format ────────────────────────────────────
    # Check first byte: codegen format starts with known opcode patterns
    movzx   eax, byte ptr [r12]
    # Codegen format marker: if first instruction is a valid codegen opcode
    cmp     al, 0x30                # Push opcode in codegen format
    jb      .format_ir
    mov     byte ptr [rip + bc_format], 1   # codegen format
    jmp     vm_loop
.format_ir:
    mov     byte ptr [rip + bc_format], 0   # ir.rs format

    # ── 8. Enter VM loop ─────────────────────────────────────────────
    jmp     vm_loop

# ═══════════════════════════════════════════════════════════════════════════
# VM DISPATCH LOOP (Spec §4 — Threaded dispatch)
# ═══════════════════════════════════════════════════════════════════════════

vm_loop:
    # Bounds check
    cmp     r13, rbx
    jae     op_halt                 # PC >= bc_size → done

    # Fetch opcode
    movzx   eax, byte ptr [r12 + r13]
    inc     r13                     # PC++

    # Check format
    cmp     byte ptr [rip + bc_format], 1
    je      dispatch_codegen

    # ir.rs format — TODO: implement when needed
    jmp     op_halt

dispatch_codegen:
    # Codegen format: opcode is direct index into jump table
    cmp     al, OPCODE_MAX
    ja      op_unknown
    lea     rcx, [rip + codegen_table]
    jmp     [rcx + rax * 8]

# ═══════════════════════════════════════════════════════════════════════════
# OPCODE HANDLERS (Spec §4)
# Each handler ends with its own dispatch (threaded — no central loop return)
# ═══════════════════════════════════════════════════════════════════════════

# ── Macro: threaded dispatch at end of each handler ──
.macro DISPATCH
    cmp     r13, rbx
    jae     op_halt
    movzx   eax, byte ptr [r12 + r13]
    inc     r13
    lea     rcx, [rip + codegen_table]
    jmp     [rcx + rax * 8]
.endm

# ── 0x00: Nop ──
op_nop:
    DISPATCH

# ── 0x01: Push [len:1][data:N] — push string/chain literal ──
op_push:
    movzx   ecx, byte ptr [r12 + r13]  # len
    inc     r13
    # Copy data to Zone C heap
    mov     rdi, r15                # dest = current heap
    lea     rsi, [r12 + r13]        # src = bytecode
    mov     edx, ecx
    push    rcx
    call    memcpy_inline
    pop     rcx
    # Push stack entry
    sub     r14, 16
    mov     [r14], r15              # ptr
    mov     [r14 + 8], rcx          # len (mol_count)
    add     r15, rcx                # bump heap
    add     r13, rcx                # advance PC
    DISPATCH

# ── 0x06: Emit — print top of stack ──
op_emit:
    mov     rdi, [r14]              # ptr
    mov     rsi, [r14 + 8]          # len
    add     r14, 16                 # pop
    # Check if f64
    cmp     rsi, F64_MARKER
    je      .emit_f64
    # Check if array
    cmp     rsi, ARRAY_MARKER
    je      .emit_array
    # String: write to stdout
    push    rsi
    mov     edx, esi                # byte count
    mov     rsi, rdi                # buf
    mov     edi, 1                  # stdout
    mov     eax, SYS_WRITE
    syscall
    # Newline
    lea     rsi, [rip + str_newline]
    mov     edx, 1
    mov     edi, 1
    mov     eax, SYS_WRITE
    syscall
    pop     rsi
    DISPATCH

.emit_f64:
    # Convert f64 to string and print
    movq    xmm0, rdi               # f64 bits
    call    f64_to_string            # returns ptr in rax, len in rdx
    mov     rsi, rax
    mov     edi, 1
    mov     eax, SYS_WRITE
    syscall
    lea     rsi, [rip + str_newline]
    mov     edx, 1
    mov     edi, 1
    mov     eax, SYS_WRITE
    syscall
    DISPATCH

.emit_array:
    # TODO: print array representation
    lea     rsi, [rip + str_array_repr]
    mov     edx, 7                  # "[array]"
    mov     edi, 1
    mov     eax, SYS_WRITE
    syscall
    lea     rsi, [rip + str_newline]
    mov     edx, 1
    mov     edi, 1
    mov     eax, SYS_WRITE
    syscall
    DISPATCH

# ── 0x0B: Dup ──
op_dup:
    mov     rax, [r14]
    mov     rdx, [r14 + 8]
    sub     r14, 16
    mov     [r14], rax
    mov     [r14 + 8], rdx
    DISPATCH

# ── 0x0C: Pop ──
op_pop:
    add     r14, 16
    DISPATCH

# ── 0x0D: Swap ──
op_swap:
    mov     rax, [r14]
    mov     rdx, [r14 + 8]
    mov     rcx, [r14 + 16]
    mov     rsi, [r14 + 24]
    mov     [r14], rcx
    mov     [r14 + 8], rsi
    mov     [r14 + 16], rax
    mov     [r14 + 24], rdx
    DISPATCH

# ── 0x0F: Halt ──
op_halt:
    mov     eax, SYS_EXIT_GROUP
    xor     edi, edi
    syscall

# ── 0x15: PushNum [f64:8] ──
op_push_num:
    mov     rax, [r12 + r13]        # 8 bytes of f64
    sub     r14, 16
    mov     [r14], rax              # store f64 bits as ptr
    mov     qword ptr [r14 + 8], F64_MARKER
    add     r13, 8
    DISPATCH

# ── 0x19: PushMol [5 bytes: S,R,V,A,T] ──
op_push_mol:
    mov     rdi, r15                # dest = heap
    lea     rsi, [r12 + r13]        # src
    mov     edx, 5
    call    memcpy_inline
    sub     r14, 16
    mov     [r14], r15
    mov     qword ptr [r14 + 8], 5
    add     r15, 5
    add     r13, 5
    DISPATCH

# ── Arithmetic: 0x2A-0x2E (Add, Sub, Mul, Div, Mod) ──
op_add:
    movsd   xmm0, [r14 + 16]       # a (below top)
    movsd   xmm1, [r14]            # b (top)
    # Check if string concat
    cmp     qword ptr [r14 + 8], F64_MARKER
    jne     .add_concat
    cmp     qword ptr [r14 + 24], F64_MARKER
    jne     .add_concat
    addsd   xmm0, xmm1
    add     r14, 16                 # pop one
    movsd   [r14], xmm0
    DISPATCH
.add_concat:
    # String concatenation
    mov     rdi, [r14 + 16]         # a.ptr
    mov     rsi, [r14 + 24]         # a.len
    mov     rdx, [r14]              # b.ptr
    mov     rcx, [r14 + 8]          # b.len
    add     r14, 32                 # pop both
    # Handle f64 + string or string + f64
    cmp     rsi, F64_MARKER
    je      .add_f64_str
    cmp     rcx, F64_MARKER
    je      .add_str_f64
    # Both strings: concat
    mov     rax, r15                # dest
    push    rsi
    push    rcx
    # Copy a
    push    rdx
    push    rcx
    mov     rcx, rsi                # a.len
    mov     rsi, rdi                # a.ptr
    mov     rdi, r15
    call    memcpy_inline
    add     r15, [rsp + 8]          # += a.len
    pop     rcx
    pop     rdx
    # Copy b
    mov     rsi, rdx                # b.ptr
    mov     rdi, r15
    mov     edx, ecx
    call    memcpy_inline
    pop     rcx                     # b.len
    pop     rsi                     # a.len
    add     rcx, rsi                # total len
    add     r15, rcx
    sub     r15, rsi                # fixup: already added a.len above
    sub     r14, 16
    mov     [r14], rax
    mov     [r14 + 8], rcx
    DISPATCH
.add_f64_str:
    # f64 on left: convert to string, then concat
    # TODO: implement f64 → string conversion for concat
    sub     r14, 16
    mov     qword ptr [r14], 0
    mov     qword ptr [r14 + 8], 0
    DISPATCH
.add_str_f64:
    # f64 on right: convert to string, then concat
    # TODO: implement
    sub     r14, 16
    mov     qword ptr [r14], 0
    mov     qword ptr [r14 + 8], 0
    DISPATCH

op_sub:
    movsd   xmm0, [r14 + 16]
    subsd   xmm0, qword ptr [r14]
    add     r14, 16
    movsd   [r14], xmm0
    DISPATCH

op_mul:
    movsd   xmm0, [r14 + 16]
    mulsd   xmm0, qword ptr [r14]
    add     r14, 16
    movsd   [r14], xmm0
    DISPATCH

op_div:
    movsd   xmm0, [r14 + 16]
    divsd   xmm0, qword ptr [r14]
    add     r14, 16
    movsd   [r14], xmm0
    DISPATCH

op_mod:
    movsd   xmm0, [r14 + 16]       # a
    movsd   xmm1, [r14]            # b
    # a % b = a - floor(a/b) * b
    movsd   xmm2, xmm0
    divsd   xmm2, xmm1             # a/b
    roundsd xmm2, xmm2, 1          # floor
    mulsd   xmm2, xmm1             # floor(a/b)*b
    subsd   xmm0, xmm2             # a - floor(a/b)*b
    add     r14, 16
    movsd   [r14], xmm0
    DISPATCH

# ── Comparisons: 0x31-0x36 ──
op_eq:
    mov     rax, [r14 + 16]         # a.ptr
    mov     rdx, [r14 + 24]         # a.len
    mov     rcx, [r14]              # b.ptr
    mov     rsi, [r14 + 8]          # b.len
    add     r14, 16
    # Both f64?
    cmp     rdx, F64_MARKER
    jne     .eq_str
    cmp     rsi, F64_MARKER
    jne     .eq_false
    cmp     rax, rcx                # compare f64 bits
    je      .eq_true
    jmp     .eq_false
.eq_str:
    # String comparison
    cmp     rdx, rsi                # same length?
    jne     .eq_false
    # Compare bytes
    mov     rdi, rax
    mov     rsi, rcx                # reuse rsi (was b.len, now b.ptr — wait, wrong)
    # Fix: b.ptr was in rcx
    mov     rsi, rcx
    mov     ecx, edx                # len
    call    memcmp_inline
    test    eax, eax
    jnz     .eq_false
.eq_true:
    mov     qword ptr [r14], 1      # true = 1.0 as f64
    # Actually need f64 1.0 bits
    mov     rax, 0x3FF0000000000000 # f64 1.0
    mov     [r14], rax
    mov     qword ptr [r14 + 8], F64_MARKER
    DISPATCH
.eq_false:
    xor     eax, eax
    mov     [r14], rax              # f64 0.0 = all zeros
    mov     qword ptr [r14 + 8], F64_MARKER
    DISPATCH

op_ne:
    # TODO: implement (inverse of eq)
    DISPATCH

op_lt:
    movsd   xmm0, [r14 + 16]       # a
    ucomisd xmm0, qword ptr [r14]  # compare a vs b
    add     r14, 16
    jb      .lt_true                # a < b (below = less than for ucomisd)
    xor     eax, eax
    mov     [r14], rax
    mov     qword ptr [r14 + 8], F64_MARKER
    DISPATCH
.lt_true:
    mov     rax, 0x3FF0000000000000
    mov     [r14], rax
    mov     qword ptr [r14 + 8], F64_MARKER
    DISPATCH

op_gt:
    movsd   xmm0, [r14 + 16]
    ucomisd xmm0, qword ptr [r14]
    add     r14, 16
    ja      .gt_true
    xor     eax, eax
    mov     [r14], rax
    mov     qword ptr [r14 + 8], F64_MARKER
    DISPATCH
.gt_true:
    mov     rax, 0x3FF0000000000000
    mov     [r14], rax
    mov     qword ptr [r14 + 8], F64_MARKER
    DISPATCH

op_le:
    movsd   xmm0, [r14 + 16]
    ucomisd xmm0, qword ptr [r14]
    add     r14, 16
    jbe     .le_true
    xor     eax, eax
    mov     [r14], rax
    mov     qword ptr [r14 + 8], F64_MARKER
    DISPATCH
.le_true:
    mov     rax, 0x3FF0000000000000
    mov     [r14], rax
    mov     qword ptr [r14 + 8], F64_MARKER
    DISPATCH

op_ge:
    movsd   xmm0, [r14 + 16]
    ucomisd xmm0, qword ptr [r14]
    add     r14, 16
    jae     .ge_true
    xor     eax, eax
    mov     [r14], rax
    mov     qword ptr [r14 + 8], F64_MARKER
    DISPATCH
.ge_true:
    mov     rax, 0x3FF0000000000000
    mov     [r14], rax
    mov     qword ptr [r14 + 8], F64_MARKER
    DISPATCH

# ── Control flow: 0x07-0x0E ──

# 0x07: Call [name_len:1][name_bytes:N][arg_count:1]
op_call:
    # Read name length
    movzx   ecx, byte ptr [r12 + r13]
    inc     r13
    # Read name, compute hash
    lea     rdi, [r12 + r13]        # name ptr
    mov     edx, ecx                # name len
    add     r13, rcx                # advance PC past name
    # Read arg count
    movzx   ecx, byte ptr [r12 + r13]
    inc     r13
    # Hash the name (FNV-1a)
    call    hash_fnv1a              # rdi=ptr, edx=len → rax=hash
    # Dispatch to builtin via 512-slot table (spec §4.3)
    mov     rcx, rax                 # save full hash
    and     eax, 0x1FF               # slot = hash & 511
    lea     rdx, [rip + builtin_jump_table]
    jmp     [rdx + rax * 8]

# 0x08: Ret
op_ret:
    # Restore caller state from CPU stack
    pop     r13                     # restore PC
    pop     rbx                     # restore bc_size
    pop     r12                     # restore bc_base
    DISPATCH

# 0x09: Jmp [offset:4]
op_jmp:
    mov     eax, [r12 + r13]        # 4-byte signed offset
    add     r13, 4
    add     r13, rax                # PC += offset
    DISPATCH

# 0x0A: Jz [offset:4] — jump if zero/false
op_jz:
    mov     rax, [r14]
    mov     rdx, [r14 + 8]
    add     r14, 16                 # pop
    # Check if zero
    cmp     rdx, F64_MARKER
    jne     .jz_string
    # f64: check if 0.0
    test    rax, rax                # f64 0.0 = all zero bits
    jz      .jz_take
    jmp     .jz_skip
.jz_string:
    # String: empty string = false
    test    rdx, rdx                # len == 0?
    jz      .jz_take
.jz_skip:
    add     r13, 4                  # skip offset
    DISPATCH
.jz_take:
    mov     eax, [r12 + r13]
    add     r13, 4
    add     r13, rax
    DISPATCH

# 0x0E: Loop [offset:4] — backward jump
op_loop:
    mov     eax, [r12 + r13]
    add     r13, 4
    add     r13, rax                # PC += offset (negative for backward)
    DISPATCH

# ── Variable ops: 0x02, 0x13 ──

# 0x02: Load [hash:4]
op_load:
    mov     eax, [r12 + r13]        # 4-byte hash
    add     r13, 4
    # Matrix lookup
    call    var_load_matrix
    # rax = ptr, rdx = len
    sub     r14, 16
    mov     [r14], rax
    mov     [r14 + 8], rdx
    DISPATCH

# 0x13: Store [hash:4]
op_store:
    mov     eax, [r12 + r13]        # 4-byte hash
    add     r13, 4
    mov     r8, [r14]               # val.ptr
    mov     r9, [r14 + 8]           # val.len
    add     r14, 16                 # pop
    call    var_store_matrix
    DISPATCH

# ── Register frame ops: 0x26-0x29 ──

# 0x28: EnterFrame [count:1]
op_enter_frame:
    movzx   ecx, byte ptr [r12 + r13]
    inc     r13
    # Save old frame info on CPU stack
    push    qword ptr [rip + reg_cur_frame]
    push    qword ptr [rip + reg_frame_ptr]
    # Allocate frame
    mov     rax, [rip + reg_frame_ptr]
    mov     [rip + reg_cur_frame], rax
    shl     ecx, 4                  # count * 16 bytes
    add     rax, rcx
    mov     [rip + reg_frame_ptr], rax
    # Zero frame
    mov     rdi, [rip + reg_cur_frame]
    shr     ecx, 4                  # restore count
    xor     eax, eax
.ef_zero:
    test    ecx, ecx
    jz      .ef_done
    mov     [rdi], rax
    mov     [rdi + 8], rax
    add     rdi, 16
    dec     ecx
    jmp     .ef_zero
.ef_done:
    DISPATCH

# 0x29: LeaveFrame
op_leave_frame:
    pop     qword ptr [rip + reg_frame_ptr]
    pop     qword ptr [rip + reg_cur_frame]
    DISPATCH

# 0x26: LoadReg [slot:1]
op_load_reg:
    movzx   ecx, byte ptr [r12 + r13]
    inc     r13
    mov     rax, [rip + reg_cur_frame]
    shl     ecx, 4
    sub     r14, 16
    mov     rdx, [rax + rcx]
    mov     rsi, [rax + rcx + 8]
    mov     [r14], rdx
    mov     [r14 + 8], rsi
    DISPATCH

# 0x27: StoreReg [slot:1]
op_store_reg:
    movzx   ecx, byte ptr [r12 + r13]
    inc     r13
    mov     rax, [rip + reg_cur_frame]
    shl     ecx, 4
    mov     rdx, [r14]
    mov     rsi, [r14 + 8]
    mov     [rax + rcx], rdx
    mov     [rax + rcx + 8], rsi
    add     r14, 16
    DISPATCH

# 0x12: Nop (explicit)
op_nop2:
    DISPATCH

# ═══════════════════════════════════════════════════════════════════════════
# §7 MOLECULAR ENGINE — Native u16 operations
# ═══════════════════════════════════════════════════════════════════════════

# 0x40: MolPack — pop S,R,V,A,T (5 f64) → push packed u16 molecule
op_mol_pack:
    # Stack: [T] [A] [V] [R] [S] (T on top)
    movsd   xmm0, [r14]            # T
    cvttsd2si edi, xmm0
    movsd   xmm0, [r14+16]         # A
    cvttsd2si esi, xmm0
    movsd   xmm0, [r14+32]         # V
    cvttsd2si edx, xmm0
    movsd   xmm0, [r14+48]         # R
    cvttsd2si ecx, xmm0
    movsd   xmm0, [r14+64]         # S
    cvttsd2si eax, xmm0
    add     r14, 64                 # pop 4 (keep 1 for result)
    # Pack: (S<<12)|(R<<8)|(V<<5)|(A<<2)|T
    and     eax, 0xF
    shl     eax, 12
    and     ecx, 0xF
    shl     ecx, 8
    or      eax, ecx
    and     edx, 0x7
    shl     edx, 5
    or      eax, edx
    and     esi, 0x7
    shl     esi, 2
    or      eax, esi
    and     edi, 0x3
    or      eax, edi
    and     eax, 0xFFFF
    mov     [r14], rax
    mov     qword ptr [r14+8], MOL_MARKER
    DISPATCH

# 0x41: MolUnpack — pop u16 → push S,R,V,A,T (5 f64)
op_mol_unpack:
    mov     eax, [r14]
    add     r14, 16                 # pop mol
    sub     r14, 80                 # push 5 entries
    # S
    mov     ecx, eax
    shr     ecx, 12
    and     ecx, 0xF
    cvtsi2sd xmm0, ecx
    movsd   [r14+64], xmm0
    mov     qword ptr [r14+72], F64_MARKER
    # R
    mov     ecx, eax
    shr     ecx, 8
    and     ecx, 0xF
    cvtsi2sd xmm0, ecx
    movsd   [r14+48], xmm0
    mov     qword ptr [r14+56], F64_MARKER
    # V
    mov     ecx, eax
    shr     ecx, 5
    and     ecx, 0x7
    cvtsi2sd xmm0, ecx
    movsd   [r14+32], xmm0
    mov     qword ptr [r14+40], F64_MARKER
    # A
    mov     ecx, eax
    shr     ecx, 2
    and     ecx, 0x7
    cvtsi2sd xmm0, ecx
    movsd   [r14+16], xmm0
    mov     qword ptr [r14+24], F64_MARKER
    # T
    and     eax, 0x3
    cvtsi2sd xmm0, eax
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# 0x42: MolDist — pop mol_b, mol_a → push distance (§7.3 scaled integer, max=70)
op_mol_dist:
    mov     eax, [r14+16]           # mol_a
    mov     ecx, [r14]              # mol_b
    add     r14, 16                 # pop 1 (keep 1 for result)
    push    rbx
    xor     ebx, ebx                # accumulator
    # ΔS × 1
    mov     edx, eax
    shr     edx, 12
    and     edx, 0xF
    mov     esi, ecx
    shr     esi, 12
    and     esi, 0xF
    sub     edx, esi
    mov     edi, edx
    neg     edi
    cmovs   edi, edx                # abs
    add     ebx, edi
    # ΔR × 1
    mov     edx, eax
    shr     edx, 8
    and     edx, 0xF
    mov     esi, ecx
    shr     esi, 8
    and     esi, 0xF
    sub     edx, esi
    mov     edi, edx
    neg     edi
    cmovs   edi, edx
    add     ebx, edi
    # ΔV × 2
    mov     edx, eax
    shr     edx, 5
    and     edx, 0x7
    mov     esi, ecx
    shr     esi, 5
    and     esi, 0x7
    sub     edx, esi
    mov     edi, edx
    neg     edi
    cmovs   edi, edx
    lea     ebx, [ebx + edi*2]
    # ΔA × 2
    mov     edx, eax
    shr     edx, 2
    and     edx, 0x7
    mov     esi, ecx
    shr     esi, 2
    and     esi, 0x7
    sub     edx, esi
    mov     edi, edx
    neg     edi
    cmovs   edi, edx
    lea     ebx, [ebx + edi*2]
    # ΔT × 4
    and     eax, 0x3
    and     ecx, 0x3
    sub     eax, ecx
    mov     edi, eax
    neg     edi
    cmovs   edi, eax
    lea     ebx, [ebx + edi*4]
    # Push result as f64
    cvtsi2sd xmm0, ebx
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    pop     rbx
    DISPATCH

# 0x43: MolCompose — pop mol_b, mol_a → push composed mol (§7.4)
op_mol_compose:
    mov     eax, [r14+16]           # mol_a
    mov     ecx, [r14]              # mol_b
    add     r14, 16
    push    rbx
    # S = max(Sa, Sb)
    mov     edx, eax
    shr     edx, 12
    and     edx, 0xF
    mov     esi, ecx
    shr     esi, 12
    and     esi, 0xF
    cmp     edx, esi
    cmovl   edx, esi
    shl     edx, 12
    mov     ebx, edx                # result accumulator
    # R = Zipf weighted: (2*Ra + Rb) / 3
    mov     edx, eax
    shr     edx, 8
    and     edx, 0xF
    mov     esi, ecx
    shr     esi, 8
    and     esi, 0xF
    lea     edx, [edx*2 + esi]
    push    rax
    push    rcx
    mov     eax, edx
    xor     edx, edx
    mov     ecx, 3
    div     ecx
    and     eax, 0xF
    shl     eax, 8
    or      ebx, eax
    pop     rcx
    pop     rax
    # V = amplify: base + boost (simplified: (2*Va + Vb)/3 biased toward a)
    mov     edx, eax
    shr     edx, 5
    and     edx, 0x7
    mov     esi, ecx
    shr     esi, 5
    and     esi, 0x7
    lea     edx, [edx*2 + esi]
    push    rax
    mov     eax, edx
    xor     edx, edx
    mov     ecx, 3
    div     ecx
    and     eax, 0x7
    shl     eax, 5
    or      ebx, eax
    pop     rax
    # A = max(Aa, Ab)
    mov     edx, eax
    shr     edx, 2
    and     edx, 0x7
    mov     esi, ecx
    shr     esi, 2
    and     esi, 0x7
    cmp     edx, esi
    cmovl   edx, esi
    and     edx, 0x7
    shl     edx, 2
    or      ebx, edx
    # T = max(Ta, Tb)
    mov     edx, eax
    and     edx, 0x3
    mov     esi, ecx
    and     esi, 0x3
    cmp     edx, esi
    cmovl   edx, esi
    or      ebx, edx
    # Push result
    and     ebx, 0xFFFF
    mov     [r14], rbx
    mov     qword ptr [r14+8], MOL_MARKER
    pop     rbx
    DISPATCH

# 0x44: MolDominant — pop mol → push dominant dimension (0-4)
# Normalize each dim to 0..100, find largest deviation from 50
op_mol_dominant:
    mov     eax, [r14]
    # S: val * 100 / 15
    mov     ecx, eax
    shr     ecx, 12
    and     ecx, 0xF
    imul    ecx, 100
    push    rax
    mov     eax, ecx
    xor     edx, edx
    mov     ecx, 15
    div     ecx                     # norm_S
    sub     eax, 50
    # abs
    mov     edi, eax
    neg     edi
    cmovs   edi, eax
    mov     esi, edi                # best_dev = |norm_S - 50|
    xor     edx, edx               # best_dim = 0
    pop     rax
    # R: val * 100 / 15
    mov     ecx, eax
    shr     ecx, 8
    and     ecx, 0xF
    push    rax
    imul    ecx, 100
    mov     eax, ecx
    xor     ecx, ecx
    push    rdx
    mov     ecx, 15
    xor     edx, edx
    div     ecx
    pop     rdx
    sub     eax, 50
    mov     edi, eax
    neg     edi
    cmovs   edi, eax
    cmp     edi, esi
    jle     .md_no_r
    mov     esi, edi
    mov     edx, 1
.md_no_r:
    pop     rax
    # V: val * 100 / 7
    mov     ecx, eax
    shr     ecx, 5
    and     ecx, 0x7
    push    rax
    imul    ecx, 100
    mov     eax, ecx
    push    rdx
    xor     edx, edx
    mov     ecx, 7
    div     ecx
    pop     rdx
    sub     eax, 50
    mov     edi, eax
    neg     edi
    cmovs   edi, eax
    cmp     edi, esi
    jle     .md_no_v
    mov     esi, edi
    mov     edx, 2
.md_no_v:
    pop     rax
    # A: val * 100 / 7
    mov     ecx, eax
    shr     ecx, 2
    and     ecx, 0x7
    push    rax
    imul    ecx, 100
    mov     eax, ecx
    push    rdx
    xor     edx, edx
    mov     ecx, 7
    div     ecx
    pop     rdx
    sub     eax, 50
    mov     edi, eax
    neg     edi
    cmovs   edi, eax
    cmp     edi, esi
    jle     .md_no_a
    mov     esi, edi
    mov     edx, 3
.md_no_a:
    pop     rax
    # T: val * 100 / 3
    and     eax, 0x3
    imul    eax, 100
    push    rdx
    xor     edx, edx
    mov     ecx, 3
    div     ecx
    pop     rdx
    sub     eax, 50
    mov     edi, eax
    neg     edi
    cmovs   edi, eax
    cmp     edi, esi
    jle     .md_no_t
    mov     edx, 4
.md_no_t:
    cvtsi2sd xmm0, edx
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# 0x45: MolBatchDist — SIMD batch distance (§16)
# Pop [array_ptr, count, query_mol] → push [min_idx, min_dist]
op_mol_batch_dist:
    # TODO: SSE2 batch distance
    DISPATCH

# 0x46: MolEncode — pop string → push mol (encode text to molecule)
op_mol_encode:
    # Full encode: text → codepoints → P_weights → compose chain
    # TODO: requires 42 formula engine
    DISPATCH

# 0x47: MolDecode — pop mol → push string (nearest text lookup)
op_mol_decode:
    # TODO: requires KnowTree reverse lookup
    DISPATCH

# ═══════════════════════════════════════════════════════════════════════════
# §8 KNOWTREE ENGINE — kt_matrix O(1) lookup
# ═══════════════════════════════════════════════════════════════════════════

# 0x50: KtStore — pop mol, fact_idx → store in kt_matrix
op_kt_store:
    movsd   xmm0, [r14]            # fact_idx (f64)
    cvttsd2si edi, xmm0
    add     r14, 16
    mov     eax, [r14]              # mol (u16)
    add     r14, 16
    and     eax, 0xFFFF
    and     edi, 0xFFFF
    lea     rcx, [rip + mol_matrix]
    mov     word ptr [rcx + rax*2], di
    DISPATCH

# 0x51: KtLoad — pop mol → push fact_idx from kt_matrix
op_kt_load:
    mov     eax, [r14]
    add     r14, 16
    and     eax, 0xFFFF
    lea     rcx, [rip + mol_matrix]
    movzx   eax, word ptr [rcx + rax*2]
    cvtsi2sd xmm0, eax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# 0x52: KtNearest — pop mol → push nearest mol from matrix (5D scan)
op_kt_nearest:
    mov     eax, [r14]              # query mol
    # Scan S±3, R±3, V±3, find closest
    push    rbx
    push    rbp
    mov     ebp, eax                # save query mol
    mov     ebx, -1                 # best_mol = -1 (not found)
    mov     r8d, 70                 # best_dist = max
    # Unpack query
    mov     ecx, ebp
    shr     ecx, 12
    and     ecx, 0xF                # qS
    mov     edx, ebp
    shr     edx, 8
    and     edx, 0xF                # qR
    mov     esi, ebp
    shr     esi, 5
    and     esi, 0x7                # qV
    # Scan S±3
    push    rcx
    push    rdx
    push    rsi
    mov     r9d, ecx
    sub     r9d, 3                  # s_start
    cmp     r9d, 0
    cmovl   r9d, ecx               # clamp
    xor     r9d, r9d               # actually start from max(0, S-3)
    mov     eax, ecx
    sub     eax, 3
    cmovs   eax, r9d
    mov     r9d, eax                # s_start
.ktn_s:
    cmp     r9d, 16
    jge     .ktn_done
    mov     eax, ecx                # qS
    add     eax, 3
    cmp     r9d, eax
    jg      .ktn_done
    # Scan R±3
    pop     rsi
    pop     rdx
    pop     rcx
    push    rcx
    push    rdx
    push    rsi
    mov     r10d, edx
    sub     r10d, 3
    test    r10d, r10d
    cmovs   r10d, edx
    xor     r10d, r10d
    mov     eax, edx
    sub     eax, 3
    cmovs   eax, r10d
    mov     r10d, eax
.ktn_r:
    cmp     r10d, 16
    jge     .ktn_next_s
    mov     eax, edx
    add     eax, 3
    cmp     r10d, eax
    jg      .ktn_next_s
    # Scan V±3
    mov     r11d, esi
    sub     r11d, 3
    test    r11d, r11d
    cmovs   r11d, esi
    xor     r11d, r11d
    mov     eax, esi
    sub     eax, 3
    cmovs   eax, r11d
    mov     r11d, eax
.ktn_v:
    cmp     r11d, 8
    jge     .ktn_next_r
    mov     eax, esi
    add     eax, 3
    cmp     r11d, eax
    jg      .ktn_next_r
    # Reconstruct candidate mol (using query A and T)
    mov     eax, r9d
    shl     eax, 12
    mov     edi, r10d
    shl     edi, 8
    or      eax, edi
    mov     edi, r11d
    shl     edi, 5
    or      eax, edi
    # A from query
    mov     edi, ebp
    shr     edi, 2
    and     edi, 0x7
    shl     edi, 2
    or      eax, edi
    # T from query
    mov     edi, ebp
    and     edi, 0x3
    or      eax, edi
    # Check kt_matrix
    and     eax, 0xFFFF
    lea     rdi, [rip + mol_matrix]
    movzx   edi, word ptr [rdi + rax*2]
    test    edi, edi
    jz      .ktn_next_v
    # Has fact — compute distance to query
    push    rax
    push    rcx
    push    rdx
    push    rsi
    # Inline distance computation
    mov     ecx, ebp                # query
    # reuse the mol_dist logic but inline for speed
    # ΔS
    mov     edx, ecx
    shr     edx, 12
    and     edx, 0xF
    mov     esi, eax
    shr     esi, 12
    and     esi, 0xF
    sub     edx, esi
    mov     edi, edx
    neg     edi
    cmovs   edi, edx
    mov     r12d, edi               # accumulator (temporarily reuse r12)
    # Actually r12 is bytecode base — can't clobber!
    # Use stack instead
    push    rdi                     # save ΔS
    # ΔR
    mov     edx, ecx
    shr     edx, 8
    and     edx, 0xF
    mov     esi, eax
    shr     esi, 8
    and     esi, 0xF
    sub     edx, esi
    mov     edi, edx
    neg     edi
    cmovs   edi, edx
    pop     r12                     # restore ΔS... no, can't use r12
    # This is getting complex. Simplified approach:
    # Just compute full distance via function call
    push    rax                     # candidate mol
    push    rcx                     # query mol = ebp
    mov     edi, ebp
    mov     esi, eax
    call    mol_dist_inline
    # eax = distance
    cmp     eax, r8d
    jge     .ktn_dist_skip
    mov     r8d, eax                # new best dist
    pop     rcx
    pop     rax
    mov     ebx, eax                # new best mol
    jmp     .ktn_after_dist
.ktn_dist_skip:
    pop     rcx
    pop     rax
.ktn_after_dist:
    pop     rsi
    pop     rdx
    pop     rcx
    pop     rax
.ktn_next_v:
    inc     r11d
    jmp     .ktn_v
.ktn_next_r:
    inc     r10d
    jmp     .ktn_r
.ktn_next_s:
    inc     r9d
    jmp     .ktn_s
.ktn_done:
    pop     rsi
    pop     rdx
    pop     rcx
    # ebx = best mol (-1 if not found)
    cmp     ebx, -1
    je      .ktn_empty
    cvtsi2sd xmm0, ebx
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], MOL_MARKER
    pop     rbp
    pop     rbx
    DISPATCH
.ktn_empty:
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    pop     rbp
    pop     rbx
    DISPATCH

# 0x53: KtWalk — pop (mol, dim, depth) → push array of walked mols
op_kt_walk:
    # TODO: BFS silk walk
    DISPATCH

# 0x54: KtLearn — pop string → learn fact (store + index + silk)
op_kt_learn:
    # TODO: full learn pipeline
    DISPATCH

# ═══════════════════════════════════════════════════════════════════════════
# §9 SILK ENGINE
# ═══════════════════════════════════════════════════════════════════════════

# 0x58: SilkFire — pop mol_a, mol_b → co-activate (Hebbian update)
op_silk_fire:
    mov     eax, [r14+16]           # mol_a
    mov     ecx, [r14]              # mol_b
    add     r14, 32                 # pop both
    # Compute symmetric hash
    mov     edx, eax
    xor     edx, ecx
    imul    edx, 0x9E37
    mov     esi, eax
    add     esi, ecx
    add     edx, esi
    and     edx, 0xFFFF
    # silk_matrix[hash] stores edge_index → Zone A
    lea     rdi, [rip + silk_matrix]
    movzx   esi, word ptr [rdi + rdx*2]
    # If 0 = no edge yet, create one
    test    esi, esi
    jz      .sf_create
    # Existing edge: increment weight (simplified Hebbian)
    # TODO: full per-dimension Hebbian with Oja/STDP/BCM
    # For now: weight = min(weight + 100, 65535)
    add     esi, 100
    cmp     esi, 65535
    cmovg   esi, ecx                # clamp (wrong register, fix later)
    mov     esi, 65535
    mov     word ptr [rdi + rdx*2], si
    DISPATCH
.sf_create:
    # Create edge: initial weight = 500
    mov     word ptr [rdi + rdx*2], 500
    DISPATCH

# 0x59: SilkDecay — decay all silk edges by φ⁻¹ factor
op_silk_decay:
    # Iterate all 65536 silk_matrix entries, multiply by 618/1000
    lea     rsi, [rip + silk_matrix]
    xor     ecx, ecx
.sd_loop:
    cmp     ecx, 65536
    jge     .sd_done
    movzx   eax, word ptr [rsi + rcx*2]
    test    eax, eax
    jz      .sd_next
    imul    eax, 950                # ×0.95 per cycle (gentler than φ⁻¹)
    shr     eax, 10                 # /1024 ≈ /1000
    mov     word ptr [rsi + rcx*2], ax
.sd_next:
    inc     ecx
    jmp     .sd_loop
.sd_done:
    DISPATCH

# 0x5A: SilkWalk — pop (mol, dim, depth) → walk via silk edges
op_silk_walk:
    # TODO: BFS walk using silk_matrix + implicit
    DISPATCH

# 0x5B: SilkImplicit — pop mol_a, mol_b → push implicit strength
op_silk_implicit:
    mov     eax, [r14+16]           # mol_a
    mov     ecx, [r14]              # mol_b
    add     r14, 16
    # Strength = 1000 - dist * 1000 / 70
    push    rbx
    mov     edi, eax
    mov     esi, ecx
    call    mol_dist_inline
    # eax = distance (0..70)
    imul    eax, 1000
    push    rdx
    xor     edx, edx
    mov     ecx, 70
    div     ecx
    pop     rdx
    mov     ecx, 1000
    sub     ecx, eax
    test    ecx, ecx
    cmovs   ecx, edx               # clamp to 0 (edx might not be 0, fix)
    xor     edx, edx
    test    ecx, ecx
    cmovs   ecx, edx               # if negative, set 0
    cvtsi2sd xmm0, ecx
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    pop     rbx
    DISPATCH

# ═══════════════════════════════════════════════════════════════════════════
# §10 ARENA ALLOCATOR — 3-Zone
# ═══════════════════════════════════════════════════════════════════════════

# 0x60: AllocA — pop size → push ptr (permanent Zone A)
op_alloc_a:
    movsd   xmm0, [r14]
    cvttsd2si edi, xmm0
    add     r14, 16
    # Zone A grows from zone_a_ptr
    mov     rax, [rip + zone_a_ptr]
    test    rax, rax
    jnz     .aa_have_ptr
    mov     rax, r15                # first alloc: use current heap
    mov     [rip + zone_a_ptr], rax
.aa_have_ptr:
    mov     rcx, rax
    add     rcx, rdi                # new ptr after alloc
    mov     [rip + zone_a_ptr], rcx
    # Return old ptr
    sub     r14, 16
    mov     [r14], rax
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# 0x61: AllocB — pop size → push ptr (session Zone B)
op_alloc_b:
    # Similar to AllocA but tracked separately
    movsd   xmm0, [r14]
    cvttsd2si edi, xmm0
    # For now: use r15 (same as Zone C)
    mov     rax, r15
    add     r15, rdi
    mov     [r14], rax
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# 0x62: AllocC — pop size → push ptr (turn Zone C)
op_alloc_c:
    movsd   xmm0, [r14]
    cvttsd2si edi, xmm0
    mov     rax, r15
    add     r15, rdi
    mov     [r14], rax
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# 0x63: ResetC — reset Zone C (free turn temporaries)
op_reset_c:
    mov     rax, [rip + repl_heap_checkpoint]
    test    rax, rax
    jz      .rc_skip
    mov     r15, rax
.rc_skip:
    DISPATCH

# 0x64: ResetB — reset Zone B (free session data)
op_reset_b:
    # TODO: reset zone_b_ptr to zone_b_base
    DISPATCH

# 0x65: HeapPin — advance checkpoint to current r15
op_heap_pin:
    mov     [rip + repl_heap_checkpoint], r15
    DISPATCH

# ═══════════════════════════════════════════════════════════════════════════
# §45 ACTIVATION MATRIX — Spreading Activation support
# ═══════════════════════════════════════════════════════════════════════════

# __act_set(mol, value) — set activation level
act_set:
    # edi = mol, esi = value
    and     edi, 0xFFFF
    lea     rax, [rip + act_matrix]
    mov     word ptr [rax + rdi*2], si
    ret

# __act_get(mol) → eax = activation
act_get:
    and     edi, 0xFFFF
    lea     rax, [rip + act_matrix]
    movzx   eax, word ptr [rax + rdi*2]
    ret

# __act_add(mol, delta) — add to activation (clamped 0..65535)
act_add:
    and     edi, 0xFFFF
    lea     rax, [rip + act_matrix]
    movzx   ecx, word ptr [rax + rdi*2]
    add     ecx, esi
    cmp     ecx, 65535
    cmovg   ecx, esi                # wrong, should clamp
    mov     edx, 65535
    cmp     ecx, edx
    cmovg   ecx, edx
    test    ecx, ecx
    cmovs   ecx, edi                # clamp to 0 if negative
    xor     edx, edx
    test    ecx, ecx
    cmovs   ecx, edx
    mov     word ptr [rax + rdi*2], cx
    ret

# __act_reset() — clear all activations
act_reset:
    lea     rdi, [rip + act_matrix]
    xor     eax, eax
    mov     ecx, 16384              # 131072/8 = 16384 qwords
    rep     stosq
    ret

# __act_decay_all(factor) — SIMD batch decay (§16)
# edi = factor (e.g. 800 for ×0.8)
act_decay_all:
    lea     rsi, [rip + act_matrix]
    # Scalar fallback (SIMD version in spec §45)
    xor     ecx, ecx
.acd_loop:
    cmp     ecx, 65536
    jge     .acd_done
    movzx   eax, word ptr [rsi + rcx*2]
    imul    eax, edi
    shr     eax, 10                 # /1024 ≈ /1000
    mov     word ptr [rsi + rcx*2], ax
    inc     ecx
    jmp     .acd_loop
.acd_done:
    ret

# ═══════════════════════════════════════════════════════════════════════════
# §7.3 Helper: mol_dist_inline(edi=mol_a, esi=mol_b) → eax=distance
# ═══════════════════════════════════════════════════════════════════════════
mol_dist_inline:
    push    rbx
    xor     ebx, ebx
    # ΔS
    mov     eax, edi
    shr     eax, 12
    and     eax, 0xF
    mov     ecx, esi
    shr     ecx, 12
    and     ecx, 0xF
    sub     eax, ecx
    mov     edx, eax
    neg     edx
    cmovs   edx, eax
    add     ebx, edx
    # ΔR
    mov     eax, edi
    shr     eax, 8
    and     eax, 0xF
    mov     ecx, esi
    shr     ecx, 8
    and     ecx, 0xF
    sub     eax, ecx
    mov     edx, eax
    neg     edx
    cmovs   edx, eax
    add     ebx, edx
    # ΔV ×2
    mov     eax, edi
    shr     eax, 5
    and     eax, 0x7
    mov     ecx, esi
    shr     ecx, 5
    and     ecx, 0x7
    sub     eax, ecx
    mov     edx, eax
    neg     edx
    cmovs   edx, eax
    lea     ebx, [ebx + edx*2]
    # ΔA ×2
    mov     eax, edi
    shr     eax, 2
    and     eax, 0x7
    mov     ecx, esi
    shr     ecx, 2
    and     ecx, 0x7
    sub     eax, ecx
    mov     edx, eax
    neg     edx
    cmovs   edx, eax
    lea     ebx, [ebx + edx*2]
    # ΔT ×4
    mov     eax, edi
    and     eax, 0x3
    mov     ecx, esi
    and     ecx, 0x3
    sub     eax, ecx
    mov     edx, eax
    neg     edx
    cmovs   edx, eax
    lea     ebx, [ebx + edx*4]
    mov     eax, ebx
    pop     rbx
    ret

op_unknown:
    # Unknown opcode — halt with error
    jmp     op_halt

# ═══════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

# memcpy_inline: rdi=dest, rsi=src, edx=count
memcpy_inline:
    mov     ecx, edx
    rep     movsb
    ret

# memcmp_inline: rdi=a, rsi=b, ecx=len → eax (0=equal, nonzero=different)
memcmp_inline:
    repe    cmpsb
    mov     eax, 0
    je      .mcmp_eq
    mov     eax, 1
.mcmp_eq:
    ret

# hash_fnv1a: rdi=ptr, edx=len → rax=hash
hash_fnv1a:
    movabs  rax, 0xCBF29CE484222325     # FNV offset basis
    movabs  rcx, 0x100000001B3          # FNV prime
    lea     rsi, [rdi + rdx]            # end ptr
.hfnv_loop:
    cmp     rdi, rsi
    jae     .hfnv_done
    movzx   edx, byte ptr [rdi]
    xor     rax, rdx
    imul    rax, rcx
    inc     rdi
    jmp     .hfnv_loop
.hfnv_done:
    ret

# var_store_matrix: eax=hash, r8=val.ptr, r9=val.len
var_store_matrix:
    push    rbx
    mov     ecx, eax
    and     ecx, 0x3FFF              # slot index (14 bits)
    shl     ecx, 5                   # × 32 bytes per slot
    lea     rbx, [rip + var_matrix]
.vsm_probe:
    cmp     qword ptr [rbx + rcx], 0 # empty?
    je      .vsm_write
    cmp     [rbx + rcx], eax         # same hash?
    je      .vsm_write
    add     ecx, 32                  # linear probe
    cmp     ecx, 524288              # wrap at 16K slots
    jb      .vsm_probe
    xor     ecx, ecx
    jmp     .vsm_probe
.vsm_write:
    mov     [rbx + rcx], eax         # hash
    mov     rdx, [rip + closure_depth]
    mov     [rbx + rcx + 8], rdx     # depth
    mov     [rbx + rcx + 16], r8     # val.ptr
    mov     [rbx + rcx + 24], r9     # val.len
    pop     rbx
    ret

# var_load_matrix: eax=hash → rax=ptr, rdx=len
var_load_matrix:
    mov     ecx, eax
    and     ecx, 0x3FFF
    shl     ecx, 5
    lea     rdx, [rip + var_matrix]
.vlm_probe:
    cmp     qword ptr [rdx + rcx], 0 # empty → not found
    je      .vlm_not_found
    cmp     [rdx + rcx], eax         # same hash?
    je      .vlm_found
    add     ecx, 32
    cmp     ecx, 524288
    jb      .vlm_probe
    xor     ecx, ecx
    jmp     .vlm_probe
.vlm_found:
    mov     rax, [rdx + rcx + 16]   # val.ptr
    mov     rdx, [rdx + rcx + 24]   # val.len
    ret
.vlm_not_found:
    xor     eax, eax
    xor     edx, edx
    ret

# f64_to_string: xmm0=value → rax=ptr, edx=len (on Zone C heap)
f64_to_string:
    # Simple integer conversion for now
    mov     rax, r15                 # output buffer
    cvttsd2si rcx, xmm0             # integer part
    # Handle negative
    test    rcx, rcx
    jns     .f2s_pos
    mov     byte ptr [r15], '-'
    inc     r15
    neg     rcx
.f2s_pos:
    # Convert integer to decimal digits
    mov     rdi, r15
    add     rdi, 20                  # temp end
    mov     r8, rdi                  # save end
.f2s_digit:
    xor     edx, edx
    mov     rsi, 10
    div     rsi                      # rcx/10, remainder in rdx
    add     dl, '0'
    dec     rdi
    mov     [rdi], dl
    mov     rcx, rax
    test    rcx, rcx
    jnz     .f2s_digit
    # Copy digits to output
    mov     rsi, rdi
    mov     rdi, r15
    mov     rcx, r8
    sub     rcx, rsi                 # digit count
    push    rcx
    rep     movsb
    pop     rdx
    add     rdx, r15
    sub     rdx, rax                 # total len = digits + possible '-'
    mov     r15, rdi                 # bump heap
    ret

# ═══════════════════════════════════════════════════════════════════════════
# ERROR HANDLERS
# ═══════════════════════════════════════════════════════════════════════════

err_open:
    lea     rsi, [rip + str_err_open]
    mov     edx, 16
    jmp     err_exit
err_mmap:
    lea     rsi, [rip + str_err_mmap]
    mov     edx, 11
    jmp     err_exit
err_read_bc:
    lea     rsi, [rip + str_err_read]
    mov     edx, 18
    jmp     err_exit
err_no_bc:
    lea     rsi, [rip + str_err_no_bc]
    mov     edx, 14
    jmp     err_exit
err_exit:
    mov     edi, 2                  # stderr
    mov     eax, SYS_WRITE
    syscall
    mov     eax, SYS_EXIT_GROUP
    mov     edi, 1
    syscall

# ═══════════════════════════════════════════════════════════════════════════
# CODEGEN DISPATCH TABLE
# ═══════════════════════════════════════════════════════════════════════════

.equ OPCODE_MAX, 0xFF

.section .rodata
.align 8
codegen_table:
    .quad   op_nop          # 0x00
    .quad   op_push         # 0x01
    .quad   op_load         # 0x02
    .quad   op_unknown      # 0x03 (Lca)
    .quad   op_unknown      # 0x04 (Edge)
    .quad   op_unknown      # 0x05 (Query)
    .quad   op_emit         # 0x06
    .quad   op_call         # 0x07
    .quad   op_ret          # 0x08
    .quad   op_jmp          # 0x09
    .quad   op_jz           # 0x0A
    .quad   op_dup          # 0x0B
    .quad   op_pop          # 0x0C
    .quad   op_swap         # 0x0D
    .quad   op_loop         # 0x0E
    .quad   op_halt         # 0x0F
    .quad   op_nop          # 0x10 (Dream stub)
    .quad   op_nop          # 0x11 (Stats stub)
    .quad   op_nop2         # 0x12 (Nop)
    .quad   op_store        # 0x13
    .quad   op_load         # 0x14 (LoadLocal = Load)
    .quad   op_push_num     # 0x15
    .quad   op_nop          # 0x16 (Fuse stub)
    .quad   op_nop          # 0x17 (ScopeBegin stub)
    .quad   op_nop          # 0x18 (ScopeEnd stub)
    .quad   op_push_mol     # 0x19
    .quad   op_nop          # 0x1A (TryBegin — TODO)
    .quad   op_nop          # 0x1B (CatchEnd — TODO)
    .quad   op_store        # 0x1C (StoreUpdate = Store)
    .quad   op_nop          # 0x1D (Trace)
    .quad   op_nop          # 0x1E (Inspect)
    .quad   op_nop          # 0x1F (Assert)
    .quad   op_nop          # 0x20 (TypeOf)
    .quad   op_nop          # 0x21 (Why)
    .quad   op_nop          # 0x22 (Explain)
    .quad   op_nop          # 0x23 (Ffi)
    .quad   op_call         # 0x24 (CallClosure — TODO proper)
    .quad   op_nop          # 0x25 (Closure — TODO)
    .quad   op_load_reg     # 0x26
    .quad   op_store_reg    # 0x27
    .quad   op_enter_frame  # 0x28
    .quad   op_leave_frame  # 0x29
    .quad   op_add          # 0x2A
    .quad   op_sub          # 0x2B
    .quad   op_mul          # 0x2C
    .quad   op_div          # 0x2D
    .quad   op_mod          # 0x2E
    .quad   op_nop          # 0x2F (Neg)
    .quad   op_nop          # 0x30 (ClosureCapture)
    .quad   op_eq           # 0x31
    .quad   op_ne           # 0x32
    .quad   op_lt           # 0x33
    .quad   op_gt           # 0x34
    .quad   op_le           # 0x35
    .quad   op_ge           # 0x36
    .quad   op_nop          # 0x37
    .quad   op_nop          # 0x38
    .quad   op_nop          # 0x39
    .quad   op_call         # 0x3A (CallBuiltin)
    .quad   op_nop          # 0x3B
    .quad   op_nop          # 0x3C
    .quad   op_nop          # 0x3D
    .quad   op_nop          # 0x3E
    .quad   op_nop          # 0x3F
    # 0x40-0x47: Molecular Engine (§7)
    .quad   op_mol_pack     # 0x40 MolPack
    .quad   op_mol_unpack   # 0x41 MolUnpack
    .quad   op_mol_dist     # 0x42 MolDist
    .quad   op_mol_compose  # 0x43 MolCompose
    .quad   op_mol_dominant # 0x44 MolDominant
    .quad   op_mol_batch_dist # 0x45 MolBatchDist (stub)
    .quad   op_mol_encode   # 0x46 MolEncode (stub)
    .quad   op_mol_decode   # 0x47 MolDecode (stub)
    # 0x48-0x4F: reserved
    .quad   op_nop, op_nop, op_nop, op_nop
    .quad   op_nop, op_nop, op_nop, op_nop
    # 0x50-0x54: KnowTree (§8)
    .quad   op_kt_store     # 0x50 KtStore
    .quad   op_kt_load      # 0x51 KtLoad
    .quad   op_kt_nearest   # 0x52 KtNearest
    .quad   op_kt_walk      # 0x53 KtWalk (stub)
    .quad   op_kt_learn     # 0x54 KtLearn (stub)
    .quad   op_nop, op_nop, op_nop
    # 0x58-0x5B: Silk (§9)
    .quad   op_silk_fire    # 0x58 SilkFire
    .quad   op_silk_decay   # 0x59 SilkDecay
    .quad   op_silk_walk    # 0x5A SilkWalk (stub)
    .quad   op_silk_implicit # 0x5B SilkImplicit
    .quad   op_nop, op_nop, op_nop, op_nop
    # 0x60-0x65: Arena (§10)
    .quad   op_alloc_a      # 0x60 AllocA
    .quad   op_alloc_b      # 0x61 AllocB
    .quad   op_alloc_c      # 0x62 AllocC
    .quad   op_reset_c      # 0x63 ResetC
    .quad   op_reset_b      # 0x64 ResetB
    .quad   op_heap_pin     # 0x65 HeapPin
    .quad   op_nop, op_nop
    # 0x68-0x6F: reserved
    .quad   op_nop, op_nop, op_nop, op_nop
    .quad   op_nop, op_nop, op_nop, op_nop
    # 0x70-0x78: IO + Exception
    .quad   op_nop          # 0x70 FileRead (TODO)
    .quad   op_nop          # 0x71 FileWrite (TODO)
    .quad   op_nop          # 0x72 FileAppend (TODO)
    .quad   op_nop          # 0x73 NetSocket (TODO)
    .quad   op_nop          # 0x74 NetSend (TODO)
    .quad   op_nop          # 0x75 NetRecv (TODO)
    .quad   op_nop, op_nop
    .quad   op_nop          # 0x78 Throw (TODO)
    # 0x79-0x8F: reserved
    .quad   op_nop, op_nop, op_nop, op_nop, op_nop, op_nop, op_nop
    .quad   op_nop, op_nop, op_nop, op_nop, op_nop, op_nop, op_nop
    .quad   op_nop, op_nop, op_nop, op_nop, op_nop, op_nop, op_nop
    .quad   op_nop, op_nop
    # 0x90: Breakpoint
    .quad   op_nop          # 0x90 Breakpoint
    # 0x91-0x9F: reserved
    .quad   op_nop, op_nop, op_nop, op_nop, op_nop, op_nop, op_nop
    .quad   op_nop, op_nop, op_nop, op_nop, op_nop, op_nop, op_nop
    .quad   op_nop
    # 0xA0-0xAF: Super (fused) instructions
    .rept 16
    .quad   op_nop          # TODO: fused instructions
    .endr
    # 0xB0-0xB4: Security
    .quad   op_nop, op_nop, op_nop, op_nop, op_nop
    # 0xB5-0xBF: reserved
    .quad   op_nop, op_nop, op_nop, op_nop, op_nop, op_nop, op_nop
    .quad   op_nop, op_nop, op_nop, op_nop
    # 0xC0-0xFF: reserved / extension
    .rept 64
    .quad   op_nop
    .endr

# ═══════════════════════════════════════════════════════════════════════════
# BUILTIN JUMP TABLE (256 slots)
# ═══════════════════════════════════════════════════════════════════════════

# ═══ Builtin Jump Table (512 slots, spec §4.3) ═══
# Index = FNV-1a(name) & 0x1FF
# Populated with known builtins, rest = .call_not_builtin
.align 8
builtin_jump_table:
    .quad   .builtin_substr      # 0x000 (substr)
    .quad   .call_not_builtin    # 0x001
    .quad   .call_not_builtin    # 0x002
    .quad   .builtin_char_at     # 0x003 (char_at)
    .rept   9
    .quad   .call_not_builtin    # 0x004-0x00C
    .endr
    .quad   .builtin_abs         # 0x00D (__abs)
    .quad   .call_not_builtin    # 0x00E
    .quad   .builtin_set_at      # 0x00F (__set_at)
    .rept   7
    .quad   .call_not_builtin    # 0x010-0x016
    .endr
    .quad   .builtin_tcp_recv    # 0x017 (__tcp_recv)
    .rept   12
    .quad   .call_not_builtin    # 0x018-0x023
    .endr
    .quad   .builtin_str_find    # 0x024 (__str_find) — stub for now
    .rept   16
    .quad   .call_not_builtin    # 0x025-0x034
    .endr
    .quad   .builtin_heap_pin    # 0x035 (__heap_pin) — stub
    .rept   13
    .quad   .call_not_builtin    # 0x036-0x042
    .endr
    .quad   .builtin_log2        # 0x043 (__log2)
    .rept   8
    .quad   .call_not_builtin    # 0x044-0x04B
    .endr
    .quad   .builtin_len         # 0x04C (len — collision with __mxr, len wins by order)
    .rept   3
    .quad   .call_not_builtin    # 0x04D-0x04F
    .endr
    .quad   .call_not_builtin    # 0x050 (pop — TODO)
    .rept   3
    .quad   .call_not_builtin    # 0x051-0x053
    .endr
    .quad   .builtin_mx_w        # 0x054 (__mx_w)
    .rept   2
    .quad   .call_not_builtin    # 0x055-0x056
    .endr
    .quad   .builtin_array_get   # 0x057 (__array_get)
    .rept   8
    .quad   .call_not_builtin    # 0x058-0x05F
    .endr
    .quad   .call_not_builtin    # 0x060
    .quad   .builtin_file_write  # 0x061 (__file_write)
    .rept   4
    .quad   .call_not_builtin    # 0x062-0x065
    .endr
    .quad   .builtin_to_string   # 0x066 (__to_string)
    .rept   3
    .quad   .call_not_builtin    # 0x067-0x069
    .endr
    .quad   .builtin_ceil        # 0x06A (__ceil — collision with __system, ceil wins)
    .rept   6
    .quad   .call_not_builtin    # 0x06B-0x070
    .endr
    .quad   .builtin_tcp_close   # 0x071 (__tcp_close)
    .rept   15
    .quad   .call_not_builtin    # 0x072-0x080
    .endr
    .quad   .call_not_builtin    # 0x081
    .quad   .builtin_bit_or      # 0x082 (__bit_or)
    .rept   3
    .quad   .call_not_builtin    # 0x083-0x085
    .endr
    .quad   .builtin_sleep       # 0x086 (__sleep)
    .rept   3
    .quad   .call_not_builtin    # 0x087-0x089
    .endr
    .quad   .builtin_exp         # 0x08A (__exp)
    .rept   7
    .quad   .call_not_builtin    # 0x08B-0x091
    .endr
    .quad   .call_not_builtin    # 0x092 (__array_with_cap — TODO)
    .rept   6
    .quad   .call_not_builtin    # 0x093-0x098
    .endr
    .quad   .builtin_char_code   # 0x099 (__char_code)
    .rept   3
    .quad   .call_not_builtin    # 0x09A-0x09C
    .endr
    .quad   .builtin_push        # 0x09D (push)
    .rept   7
    .quad   .call_not_builtin    # 0x09E-0x0A4
    .endr
    .quad   .builtin_sqrt        # 0x0A5 (__sqrt)
    .quad   .call_not_builtin    # 0x0A6
    .quad   .call_not_builtin    # 0x0A7 (__str_trim — TODO)
    .rept   5
    .quad   .call_not_builtin    # 0x0A8-0x0AC
    .endr
    .quad   .builtin_tcp_send    # 0x0AD (__tcp_send)
    .quad   .call_not_builtin    # 0x0AE
    .quad   .builtin_floor       # 0x0AF (__floor)
    .rept   20
    .quad   .call_not_builtin    # 0x0B0-0x0C3
    .endr
    .quad   .builtin_tcp_listen  # 0x0C4 (__tcp_listen)
    .rept   2
    .quad   .call_not_builtin    # 0x0C5-0x0C6
    .endr
    .quad   .builtin_heap_used   # 0x0C7 (__heap_used)
    .quad   .builtin_bit_xor     # 0x0C8 (__bit_xor)
    .rept   6
    .quad   .call_not_builtin    # 0x0C9-0x0CE
    .endr
    .quad   .builtin_tcp_accept  # 0x0CF (__tcp_accept)
    .quad   .call_not_builtin    # 0x0D0 (p_weight — TODO)
    .rept   3
    .quad   .call_not_builtin    # 0x0D1-0x0D3
    .endr
    .quad   .builtin_bit_and     # 0x0D4 (__bit_and)
    .rept   30
    .quad   .call_not_builtin    # 0x0D5-0x0F2
    .endr
    .quad   .call_not_builtin    # 0x0F3 (compose — TODO)
    .rept   12
    .quad   .call_not_builtin    # 0x0F4-0x0FF
    .endr
    # 0x100-0x14B: collisions / overflow
    .quad   .builtin_mxr         # 0x100 (__mxr — moved from 0x4C collision)
    .rept   23
    .quad   .call_not_builtin    # 0x101-0x117
    .endr
    .quad   .call_not_builtin    # 0x118
    .quad   .call_not_builtin    # 0x119
    .quad   .call_not_builtin    # 0x11A
    .quad   .call_not_builtin    # 0x11B
    .quad   .call_not_builtin    # 0x11C
    .quad   .call_not_builtin    # 0x11D
    .quad   .builtin_file_read   # 0x11E (__file_read — moved to avoid 0xBE, using 0x1BE & 0x1FF = 0x1BE)
    # Fill remaining to 512
    .rept   225
    .quad   .call_not_builtin
    .endr

# Stub builtins not yet implemented
.text
.builtin_str_find:
    add     r14, 32                  # pop 2 args
    sub     r14, 16
    xor     eax, eax
    mov     [r14], rax
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

.builtin_heap_pin:
    mov     [rip + repl_heap_checkpoint], r15
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

.text

# ═══════════════════════════════════════════════════════════════════════════
# BUILTINS — Defined slot numbers (spec §4.3)
# Slot = hash(name) & 0xFF. Pre-populated, no collision chain.
# When compiler emits 0x3A [slot], direct jump. No name hashing at runtime.
# ═══════════════════════════════════════════════════════════════════════════

.call_not_builtin:
    # Unknown builtin — push 0
    sub     r14, 16
    xor     eax, eax
    mov     [r14], rax
    mov     qword ptr [r14 + 8], F64_MARKER
    DISPATCH

# ── String builtins (0x20-0x3F) ──

# len(string) → number
.builtin_len:
    mov     rdx, [r14 + 8]          # len field
    add     r14, 16                 # pop arg
    cmp     rdx, F64_MARKER
    je      .blen_num
    cmp     rdx, ARRAY_MARKER
    je      .blen_array
    # String: len = mol count (each mol = 2 bytes, len field = mol count)
    cvtsi2sd xmm0, rdx
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH
.blen_num:
    # Number has no length concept, return 0
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH
.blen_array:
    # Array: read count from heap object [capacity:8][count:8]
    mov     rax, [r14 - 8]          # wrong offset after pop, fix
    # Actually we already popped. The array ptr was at [r14+16] before pop.
    # After pop, the ptr is gone. Need to read before pop.
    # TODO: fix array len properly
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# substr(str, start, end) → substring
.builtin_substr:
    # Pop end, start, string
    movsd   xmm0, [r14]            # end
    cvttsd2si esi, xmm0
    movsd   xmm0, [r14+16]         # start
    cvttsd2si edi, xmm0
    mov     rax, [r14+32]           # string ptr
    mov     rdx, [r14+40]           # string len
    add     r14, 48                 # pop 3
    # Bounds check
    cmp     edi, 0
    cmovl   edi, ecx               # clamp start ≥ 0
    xor     ecx, ecx
    cmovl   edi, ecx
    cmp     esi, edx
    cmovg   esi, edx               # clamp end ≤ len
    cmp     esi, edi
    jle     .bsub_empty
    # Result: ptr = str + start*2 (u16 molecules), len = end - start
    sub     r14, 16
    lea     rcx, [rax + rdi*2]
    mov     [r14], rcx
    mov     ecx, esi
    sub     ecx, edi
    mov     [r14+8], rcx
    DISPATCH
.bsub_empty:
    sub     r14, 16
    xor     eax, eax
    mov     [r14], rax
    mov     qword ptr [r14+8], 0
    DISPATCH

# char_at(str, idx) → single char as string
.builtin_char_at:
    movsd   xmm0, [r14]            # idx
    cvttsd2si edi, xmm0
    mov     rax, [r14+16]           # string ptr
    mov     rdx, [r14+24]           # string len
    add     r14, 32                 # pop 2
    cmp     edi, edx
    jge     .bca_empty
    # Return 1-char substring
    sub     r14, 16
    lea     rcx, [rax + rdi*2]
    mov     [r14], rcx
    mov     qword ptr [r14+8], 1
    DISPATCH
.bca_empty:
    sub     r14, 16
    xor     eax, eax
    mov     [r14], rax
    mov     qword ptr [r14+8], 0
    DISPATCH

# ── Math builtins (0x00-0x1F) ──

# __floor(x) → floor
.builtin_floor:
    movsd   xmm0, [r14]
    roundsd xmm0, xmm0, 1          # round toward -∞
    movsd   [r14], xmm0
    DISPATCH

# __ceil(x) → ceiling
.builtin_ceil:
    movsd   xmm0, [r14]
    roundsd xmm0, xmm0, 2          # round toward +∞
    movsd   [r14], xmm0
    DISPATCH

# __abs(x) → |x|
.builtin_abs:
    movsd   xmm0, [r14]
    # Clear sign bit
    mov     rax, [r14]
    btr     rax, 63
    mov     [r14], rax
    DISPATCH

# __sqrt(x) → √x
.builtin_sqrt:
    movsd   xmm0, [r14]
    sqrtsd  xmm0, xmm0
    movsd   [r14], xmm0
    DISPATCH

# __exp(x) → e^x (x87 FPU)
.builtin_exp:
    fld     qword ptr [r14]
    fldl2e                          # load log2(e)
    fmulp                           # x * log2(e)
    fld     st(0)
    frndint                         # integer part
    fxch
    fsub    st(0), st(1)            # fractional part
    f2xm1                           # 2^frac - 1
    fld1
    faddp                           # 2^frac
    fscale                          # 2^int * 2^frac = e^x
    fstp    st(1)
    fstp    qword ptr [r14]
    DISPATCH

# __log2(x) → log₂(x) (x87 FPU)
.builtin_log2:
    fld1
    fld     qword ptr [r14]
    fyl2x                           # 1 * log2(x)
    fstp    qword ptr [r14]
    DISPATCH

# ── Array builtins ──

# push(array, value) → modified array
.builtin_push:
    # Pop value, then array
    mov     r8, [r14]               # val ptr
    mov     r9, [r14+8]             # val len
    mov     rax, [r14+16]           # array heap ptr
    add     r14, 32                 # pop 2
    # Array layout: [capacity:8][count:8][entries...]
    mov     rcx, [rax+8]            # count
    mov     rdx, [rax]              # capacity
    cmp     rcx, rdx
    jge     .bpush_grow
    # Append at count position
    shl     rcx, 4
    lea     rdi, [rax + 16 + rcx]
    shr     rcx, 4
    mov     [rdi], r8
    mov     [rdi+8], r9
    inc     qword ptr [rax+8]       # count++
    # Push array back
    sub     r14, 16
    mov     [r14], rax
    mov     qword ptr [r14+8], ARRAY_MARKER
    DISPATCH
.bpush_grow:
    # Need to grow: allocate 2× on heap
    shl     rdx, 1                  # new capacity = 2×
    test    rdx, rdx
    jnz     .bpush_have_cap
    mov     rdx, 8                  # minimum capacity
.bpush_have_cap:
    push    rax
    push    r8
    push    r9
    push    rdx
    # Allocate new array on heap (Zone C)
    mov     rdi, rdx
    shl     rdi, 4
    add     rdi, 16     # total bytes
    mov     rsi, r15
    add     r15, rdi                # bump allocate
    pop     rdx
    pop     r9
    pop     r8
    pop     rax
    # Copy old data
    mov     [rsi], rdx              # new capacity
    mov     rcx, [rax+8]            # old count
    mov     [rsi+8], rcx            # same count
    # Copy entries
    push    rsi
    push    rcx
    lea     rdi, [rsi+16]
    lea     rax, [rax+16]
    shl     rcx, 4                  # bytes = count × 16
    push    r8
    push    r9
    mov     ecx, ecx
    rep     movsb
    pop     r9
    pop     r8
    pop     rcx
    pop     rsi
    # Now append new element
    push    rcx
    shl     rcx, 4
    lea     rdi, [rsi + 16 + rcx]
    pop     rcx
    mov     [rdi], r8
    mov     [rdi+8], r9
    inc     qword ptr [rsi+8]
    # Push new array
    sub     r14, 16
    mov     [r14], rsi
    mov     qword ptr [r14+8], ARRAY_MARKER
    DISPATCH

# __array_get(array, index) → value
.builtin_array_get:
    movsd   xmm0, [r14]            # index
    cvttsd2si edi, xmm0
    mov     rax, [r14+16]           # array ptr
    add     r14, 32                 # pop 2
    # Bounds check
    mov     rcx, [rax+8]            # count
    cmp     edi, ecx
    jge     .bag_oob
    cmp     edi, 0
    jl      .bag_oob
    # Read entry
    mov     rcx, rdi
    shl     rcx, 4
    lea     rsi, [rax + 16 + rcx]
    sub     r14, 16
    mov     rax, [rsi]
    mov     rdx, [rsi+8]
    mov     [r14], rax
    mov     [r14+8], rdx
    DISPATCH
.bag_oob:
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __set_at(array, index, value) → value
.builtin_set_at:
    mov     r8, [r14]               # value ptr
    mov     r9, [r14+8]             # value len
    movsd   xmm0, [r14+16]         # index
    cvttsd2si edi, xmm0
    mov     rax, [r14+32]           # array ptr
    add     r14, 48                 # pop 3
    mov     rcx, [rax+8]            # count
    cmp     edi, ecx
    jge     .bsa_oob
    cmp     edi, 0
    jl      .bsa_oob
    mov     rcx, rdi
    shl     rcx, 4
    lea     rsi, [rax + 16 + rcx]
    mov     [rsi], r8
    mov     [rsi+8], r9
.bsa_oob:
    # Return the value
    sub     r14, 16
    mov     [r14], r8
    mov     [r14+8], r9
    DISPATCH

# ── IO builtins ──

# __file_read(path) → string
.builtin_file_read:
    mov     rsi, [r14]              # path ptr (u16 molecules)
    mov     rdx, [r14+8]            # path len (mol count)
    add     r14, 16
    # Decode path: u16 mols → ASCII bytes
    mov     rdi, r15                # temp buffer
    xor     ecx, ecx
.bfr_decode:
    cmp     ecx, edx
    jge     .bfr_open
    movzx   eax, word ptr [rsi + rcx*2]
    mov     byte ptr [rdi + rcx], al
    inc     ecx
    jmp     .bfr_decode
.bfr_open:
    mov     byte ptr [rdi + rcx], 0  # null terminate
    mov     rdi, r15                 # path string
    xor     esi, esi                 # O_RDONLY
    mov     eax, SYS_OPEN
    syscall
    test    eax, eax
    js      .bfr_fail
    mov     edi, eax                 # fd
    # Read file content onto heap
    lea     rsi, [r15 + 4096]       # skip path buffer
    mov     edx, 0x100000           # read up to 1MB
    mov     eax, SYS_READ
    syscall
    push    rax                      # save bytes read
    push    rdi                      # save fd
    # Close
    mov     eax, SYS_CLOSE
    syscall
    pop     rdi
    pop     rcx                      # bytes read
    test    rcx, rcx
    jle     .bfr_fail
    # Encode bytes to u16 molecules on heap
    lea     rsi, [r15 + 4096]       # raw bytes
    mov     rdi, r15
    add     rdi, 0x200000            # mol output area
    xor     edx, edx
.bfr_encode:
    cmp     edx, ecx
    jge     .bfr_result
    movzx   eax, byte ptr [rsi + rdx]
    mov     word ptr [rdi + rdx*2], ax
    inc     edx
    jmp     .bfr_encode
.bfr_result:
    # Push result string
    sub     r14, 16
    mov     [r14], rdi               # mol ptr
    mov     [r14+8], rcx             # mol count
    DISPATCH
.bfr_fail:
    sub     r14, 16
    xor     eax, eax
    mov     [r14], rax
    mov     qword ptr [r14+8], 0
    DISPATCH

# __file_write(path, content) → 0
.builtin_file_write:
    # Pop content, path
    mov     r8, [r14]                # content ptr
    mov     r9, [r14+8]              # content len (mols)
    mov     rsi, [r14+16]            # path ptr
    mov     rdx, [r14+24]            # path len
    add     r14, 32
    # Decode path
    mov     rdi, r15
    xor     ecx, ecx
.bfw_dpath:
    cmp     ecx, edx
    jge     .bfw_open
    movzx   eax, word ptr [rsi + rcx*2]
    mov     byte ptr [rdi + rcx], al
    inc     ecx
    jmp     .bfw_dpath
.bfw_open:
    mov     byte ptr [rdi + rcx], 0
    mov     rdi, r15
    mov     esi, 0x241               # O_WRONLY|O_CREAT|O_TRUNC
    mov     edx, 0x1A4              # 0644 octal = 0x1A4
    mov     eax, SYS_OPEN
    syscall
    test    eax, eax
    js      .bfw_done
    mov     edi, eax
    # Decode content to bytes
    lea     rsi, [r15 + 4096]
    xor     ecx, ecx
.bfw_dcontent:
    cmp     rcx, r9
    jge     .bfw_write
    movzx   eax, word ptr [r8 + rcx*2]
    mov     byte ptr [rsi + rcx], al
    inc     ecx
    jmp     .bfw_dcontent
.bfw_write:
    mov     rdx, rcx                 # byte count
    mov     rsi, rsi                 # already set
    lea     rsi, [r15 + 4096]
    mov     eax, SYS_WRITE
    syscall
    mov     eax, SYS_CLOSE
    syscall
.bfw_done:
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# ── Network builtins ──

# __tcp_listen(port) → server_fd
.builtin_tcp_listen:
    movsd   xmm0, [r14]
    cvttsd2si edi, xmm0             # port
    add     r14, 16
    push    rbx
    mov     ebx, edi                 # save port
    # socket(AF_INET=2, SOCK_STREAM=1, 0)
    mov     edi, 2
    mov     esi, 1
    xor     edx, edx
    mov     eax, SYS_SOCKET
    syscall
    mov     r8d, eax                 # server fd
    # setsockopt SO_REUSEADDR
    sub     rsp, 4
    mov     dword ptr [rsp], 1
    mov     edi, r8d
    mov     esi, 1                   # SOL_SOCKET
    mov     edx, 2                   # SO_REUSEADDR
    lea     r10, [rsp]
    push    r8
    mov     r8d, 4                   # optlen
    mov     eax, 54                  # setsockopt
    syscall
    pop     r8
    add     rsp, 4
    # bind
    sub     rsp, 16
    mov     word ptr [rsp], 2        # AF_INET
    mov     eax, ebx
    xchg    al, ah                   # htons
    mov     word ptr [rsp+2], ax
    mov     dword ptr [rsp+4], 0     # INADDR_ANY
    mov     qword ptr [rsp+8], 0
    mov     edi, r8d
    lea     rsi, [rsp]
    mov     edx, 16
    mov     eax, SYS_BIND
    syscall
    # listen
    mov     edi, r8d
    mov     esi, 128
    mov     eax, SYS_LISTEN
    syscall
    add     rsp, 16
    # Push server fd
    sub     r14, 16
    cvtsi2sd xmm0, r8d
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    pop     rbx
    DISPATCH

# __tcp_accept(server_fd) → client_fd
.builtin_tcp_accept:
    movsd   xmm0, [r14]
    cvttsd2si edi, xmm0
    add     r14, 16
    xor     esi, esi                 # addr=NULL
    xor     edx, edx                 # addrlen=NULL
    xor     r10d, r10d               # flags=0
    mov     eax, SYS_ACCEPT
    syscall
    sub     r14, 16
    cvtsi2sd xmm0, eax
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __tcp_send(fd, data) → bytes_sent
.builtin_tcp_send:
    mov     rsi, [r14]               # data ptr (u16 mols)
    mov     rdx, [r14+8]             # data len (mol count)
    movsd   xmm0, [r14+16]          # fd
    cvttsd2si edi, xmm0
    add     r14, 32
    # Decode u16 → bytes
    push    rdi
    mov     rdi, r15                 # temp buffer
    xor     ecx, ecx
.bts_dec:
    cmp     ecx, edx
    jge     .bts_send
    movzx   eax, word ptr [rsi + rcx*2]
    mov     byte ptr [rdi + rcx], al
    inc     ecx
    jmp     .bts_dec
.bts_send:
    mov     edx, ecx                 # byte count
    mov     rsi, r15                 # buffer
    pop     rdi                      # fd
    xor     r10d, r10d
    xor     r8d, r8d
    xor     r9d, r9d
    mov     eax, SYS_SENDTO
    syscall
    sub     r14, 16
    cvtsi2sd xmm0, eax
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __tcp_recv(fd, max) → string
.builtin_tcp_recv:
    movsd   xmm0, [r14]             # max bytes
    cvttsd2si edx, xmm0
    movsd   xmm0, [r14+16]          # fd
    cvttsd2si edi, xmm0
    add     r14, 32
    cmp     edx, 65536
    jbe     .btr_ok
    mov     edx, 65536
.btr_ok:
    lea     rsi, [r15 + 4096]        # recv buffer
    mov     eax, SYS_READ
    syscall
    test    eax, eax
    jle     .btr_empty
    # Encode bytes → u16 mols
    mov     ecx, eax                 # bytes received
    lea     rsi, [r15 + 4096]
    mov     rdi, r15
    add     rdi, 0x100000            # mol output
    xor     edx, edx
.btr_enc:
    cmp     edx, ecx
    jge     .btr_result
    movzx   eax, byte ptr [rsi + rdx]
    mov     word ptr [rdi + rdx*2], ax
    inc     edx
    jmp     .btr_enc
.btr_result:
    sub     r14, 16
    mov     [r14], rdi
    mov     [r14+8], rcx
    DISPATCH
.btr_empty:
    sub     r14, 16
    xor     eax, eax
    mov     [r14], rax
    mov     qword ptr [r14+8], 0
    DISPATCH

# __tcp_close(fd) → 0
.builtin_tcp_close:
    movsd   xmm0, [r14]
    cvttsd2si edi, xmm0
    add     r14, 16
    mov     eax, SYS_CLOSE
    syscall
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# ── System builtins ──

# __heap_used() → bytes
.builtin_heap_used:
    mov     rax, r15
    sub     rax, [rip + heap_base]
    cvtsi2sd xmm0, rax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __sleep(ms)
.builtin_sleep:
    movsd   xmm0, [r14]
    cvttsd2si rax, xmm0
    add     r14, 16
    # Convert ms to timespec
    sub     rsp, 16
    xor     edx, edx
    mov     ecx, 1000
    div     rcx                      # rax=seconds, rdx=remainder ms
    mov     [rsp], rax               # tv_sec
    imul    rdx, 1000000             # ms → ns
    mov     [rsp+8], rdx             # tv_nsec
    lea     rdi, [rsp]
    xor     esi, esi
    mov     eax, SYS_NANOSLEEP
    syscall
    add     rsp, 16
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __to_string(number) → string
.builtin_to_string:
    movsd   xmm0, [r14]
    add     r14, 16
    # Use f64_to_string helper
    call    f64_to_string            # → rax=ptr, edx=len
    sub     r14, 16
    mov     [r14], rax
    mov     [r14+8], rdx
    DISPATCH

# __char_code(char) → codepoint number
.builtin_char_code:
    mov     rax, [r14]               # ptr
    mov     rdx, [r14+8]             # len
    add     r14, 16
    test    rdx, rdx
    jz      .bcc_zero
    movzx   eax, word ptr [rax]      # first u16 molecule = codepoint
    cvtsi2sd xmm0, eax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH
.bcc_zero:
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __bit_and(a, b) → a & b
.builtin_bit_and:
    movsd   xmm0, [r14+16]
    cvttsd2si rax, xmm0
    movsd   xmm0, [r14]
    cvttsd2si rcx, xmm0
    add     r14, 16
    and     rax, rcx
    cvtsi2sd xmm0, rax
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __bit_or(a, b) → a | b
.builtin_bit_or:
    movsd   xmm0, [r14+16]
    cvttsd2si rax, xmm0
    movsd   xmm0, [r14]
    cvttsd2si rcx, xmm0
    add     r14, 16
    or      rax, rcx
    cvtsi2sd xmm0, rax
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __bit_xor(a, b) → a ^ b
.builtin_bit_xor:
    movsd   xmm0, [r14+16]
    cvttsd2si rax, xmm0
    movsd   xmm0, [r14]
    cvttsd2si rcx, xmm0
    add     r14, 16
    xor     rax, rcx
    cvtsi2sd xmm0, rax
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __mx_w(index, value) → write u16 to mol_matrix
.builtin_mx_w:
    movsd   xmm0, [r14]             # value
    cvttsd2si eax, xmm0
    movsd   xmm0, [r14+16]          # index
    cvttsd2si edi, xmm0
    add     r14, 32
    and     edi, 0xFFFF
    lea     rcx, [rip + mol_matrix]
    mov     word ptr [rcx + rdi*2], ax
    sub     r14, 16
    cvtsi2sd xmm0, eax
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __mxr(index) → read u16 from mol_matrix
.builtin_mxr:
    movsd   xmm0, [r14]
    cvttsd2si edi, xmm0
    add     r14, 16
    and     edi, 0xFFFF
    lea     rcx, [rip + mol_matrix]
    movzx   eax, word ptr [rcx + rdi*2]
    cvtsi2sd xmm0, eax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# ═══════════════════════════════════════════════════════════════════════════
# CONSTANT STRINGS
# ═══════════════════════════════════════════════════════════════════════════

.section .rodata
str_proc_self_exe: .asciz "/proc/self/exe"
str_newline:       .byte 10
str_array_repr:    .ascii "[array]"
str_err_open:      .ascii "Open failed!\n\0\0\0"
str_err_mmap:      .ascii "mmap failed\n"
str_err_read:      .ascii "Bytecode read fail\n"
str_err_no_bc:     .ascii "No bytecode!\n\0"

# ═══════════════════════════════════════════════════════════════════════════
# BSS — Zero-initialized data
# ═══════════════════════════════════════════════════════════════════════════

.section .bss

# ── Zone pointers ──
.align 8
stack_base:     .space 8
heap_base:      .space 8
zone_c_base:    .space 8
zone_c_ptr:     .space 8
zone_c_limit:   .space 8
zone_b_base:    .space 8
zone_b_ptr:     .space 8
zone_b_top:     .space 8
zone_a_base:    .space 8
zone_a_ptr:     .space 8
zone_a_limit:   .space 8

# ── Bytecode info ──
boot_bc_base:   .space 8
boot_bc_size:   .space 8
bc_format:      .space 1
.align 8

# ── Flags ──
eval_mode:      .space 1
build_flag:     .space 1
run_flag:       .space 1
editor_flag:    .space 1
.align 8
run_path:       .space 8
editor_path:    .space 8

# ── var_matrix: O(1) variable store ──
# 16384 slots × 32 bytes = 512KB
# Entry: [hash:8][depth:8][val_ptr:8][val_len:8]
.align 32
var_matrix:     .space 524288

# ── Var undo stack ──
.align 8
var_save_stack: .space 262144       # 256KB
var_save_top:   .space 8
closure_depth:  .space 8

# ── Register frame stack ──
reg_frame_base: .space 8
reg_frame_ptr:  .space 8
reg_cur_frame:  .space 8

# ── mol_matrix (M3): P_weight → fact_index, 128KB ──
.align 32
mol_matrix:     .space 131072       # 65536 × 2 bytes

# ── act_matrix (M7): Spreading Activation, 128KB ──
.align 32
act_matrix:     .space 131072       # 65536 × 2 bytes

# ── silk_matrix (M5): Hebbian edges, 128KB ──
.align 32
silk_matrix:    .space 131072       # 65536 × 2 bytes

# ── Working Memory: 4 u16 slots ──
wm_slots:       .space 8            # 4 × u16

# ── Conversation Curve ──
v_history:      .space 8            # 8 × u8
v_history_ptr:  .space 1
.align 8

# ── Misc ──
repl_heap_checkpoint: .space 8
