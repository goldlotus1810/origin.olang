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

    # Guard page after Zone C (disabled for debug)
    # mov     rdi, rdx
    # mov     esi, GUARD_SIZE
    # xor     edx, edx
    # mov     eax, SYS_MPROTECT
    # syscall

    mov     rcx, [rip + zone_c_limit]
    lea     rcx, [rcx + GUARD_SIZE]
    mov     [rip + zone_b_base], rcx
    lea     rdx, [rcx + ZONE_B_SIZE]
    mov     [rip + zone_b_ptr], rdx      # Zone B grows DOWN from top
    mov     [rip + zone_b_top], rdx

    # Guard page after Zone B (disabled for debug)
    # mov     rdi, rdx
    # mov     esi, GUARD_SIZE
    # xor     edx, edx
    # mov     eax, SYS_MPROTECT
    # syscall

    mov     rcx, [rip + zone_b_top]
    lea     rcx, [rcx + GUARD_SIZE]
    mov     [rip + zone_a_base], rcx
    mov     [rip + zone_a_ptr], rcx      # Zone A starts here, grows up
    lea     rdx, [rcx + ZONE_A_SIZE]
    mov     [rip + zone_a_limit], rdx

    # r15 = Zone C allocator (turn temps)
    mov     r15, [rip + zone_c_base]

    # ── 4. Read bytecode into Zone A (permanent) ─────────────────────
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

    # ── 7. VM v2: always codegen format ─────────────────────────────
    mov     byte ptr [rip + bc_format], 1

    # ── 8. Enter VM loop ─────────────────────────────────────────────
    jmp     vm_loop

# ═══════════════════════════════════════════════════════════════════════════
# VM DISPATCH LOOP (Spec §4 — Threaded dispatch)
# ═══════════════════════════════════════════════════════════════════════════

vm_loop:
    # Bounds check
    cmp     r13, rbx
    jae     op_halt                 # PC >= bc_size → done

    # Fetch opcode + dispatch (always codegen format)
    movzx   eax, byte ptr [r12 + r13]
    inc     r13                     # PC++

dispatch_codegen:
    # Codegen format: opcode is direct index into jump table
    cmp     eax, 255
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
    movzx   ecx, word ptr [r12 + r13]  # byte_len (u16 LE)
    add     r13, 2                      # PC past len field
    # Copy data to Zone C heap
    mov     rdi, r15                # dest = current heap
    lea     rsi, [r12 + r13]        # src = bytecode
    mov     edx, ecx                # byte count
    push    rcx
    call    memcpy_inline
    pop     rcx
    # Push stack entry: ptr = heap, len = mol_count (bytes / 2)
    sub     r14, 16
    mov     [r14], r15              # ptr
    shr     ecx, 1                  # mol_count = byte_len / 2
    mov     [r14 + 8], rcx
    shl     ecx, 1                  # restore byte_len for heap bump
    add     r15, rcx                # bump heap
    add     r13, rcx                # advance PC past data
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
    # String: u16 molecules → convert to bytes, then write
    # rdi = mol ptr, rsi = mol_count
    push    rsi
    push    rdi
    # Convert u16 mols to bytes in Zone C temp buffer
    mov     rcx, rsi                # mol_count
    mov     rsi, rdi                # src = mol ptr
    mov     rdi, r15                # dst = heap temp
    mov     r8, r15                 # save start
.emit_mol2byte:
    test    rcx, rcx
    jz      .emit_write
    movzx   eax, word ptr [rsi]     # load u16 molecule
    cmp     eax, 0x80
    jae     .emit_multibyte
    mov     [rdi], al               # ASCII: just low byte
    inc     rdi
    add     rsi, 2
    dec     rcx
    jmp     .emit_mol2byte
.emit_multibyte:
    # For now: just emit low byte (handles Latin-1)
    # TODO: proper UTF-8 encoding for codepoints > 127
    mov     [rdi], al
    inc     rdi
    add     rsi, 2
    dec     rcx
    jmp     .emit_mol2byte
.emit_write:
    mov     rdx, rdi
    sub     rdx, r8                 # byte count
    mov     rsi, r8                 # buf = temp
    mov     edi, 1                  # stdout
    mov     eax, SYS_WRITE
    syscall
    pop     rdi
    pop     rsi                     # don't advance r15 (temp buffer, reusable)
    # Newline
    lea     rsi, [rip + str_newline]
    mov     edx, 1
    mov     edi, 1
    mov     eax, SYS_WRITE
    syscall
    DISPATCH

.emit_f64:
    # Convert f64 to u16 string, decode to bytes, print
    movq    xmm0, rdi               # f64 bits
    call    f64_to_string            # rax=ptr (u16 mols), rdx=mol count
    # Decode u16 → bytes for write
    mov     rsi, rax                 # u16 mol ptr
    mov     rcx, rdx                 # mol count
    lea     rdi, [r15 + 0x1000]      # temp decode buffer
    xor     r8d, r8d
.emit_f64_dec:
    cmp     r8, rcx
    jge     .emit_f64_write
    movzx   eax, word ptr [rsi + r8*2]
    mov     byte ptr [rdi + r8], al
    inc     r8
    jmp     .emit_f64_dec
.emit_f64_write:
    mov     rdx, r8                  # byte count
    mov     rsi, rdi                 # decoded buffer
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
    # Both strings: concat (u16 molecules — 2 bytes each)
    mov     rax, r15                # dest = new string on heap
    push    rsi                      # save a.len (mol count)
    push    rcx                      # save b.len (mol count)
    # Copy a: rsi bytes = a.len * 2
    push    rdx                      # save b.ptr
    mov     rcx, rsi                # a.len (mol count)
    shl     rcx, 1                  # × 2 = byte count
    mov     rsi, rdi                # a.ptr
    mov     rdi, r15
    mov     edx, ecx
    call    memcpy_inline
    pop     rdx                      # restore b.ptr
    pop     rcx                      # restore b.len
    pop     rsi                      # restore a.len
    # Advance heap past a
    mov     rdi, rsi
    shl     rdi, 1                  # a bytes
    add     r15, rdi
    # Copy b: rcx bytes = b.len * 2
    push    rsi                      # save a.len
    push    rcx                      # save b.len
    mov     rsi, rdx                # b.ptr
    mov     rdi, r15
    mov     edx, ecx
    shl     edx, 1                  # × 2
    call    memcpy_inline
    pop     rcx                      # b.len
    pop     rsi                      # a.len
    # Advance heap past b
    mov     rdx, rcx
    shl     rdx, 1
    add     r15, rdx
    # Result: ptr=rax, len=a.len+b.len
    add     rcx, rsi                # total mol count
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
    movsd   xmm0, [r14 + 16]       # a
    movsd   xmm1, [r14]            # b
    # Integer fast-path: if both are integer-valued, use integer div
    cvttsd2si rax, xmm0
    cvtsi2sd  xmm2, rax
    ucomisd   xmm0, xmm2
    jne       .div_float
    cvttsd2si rcx, xmm1
    cvtsi2sd  xmm2, rcx
    ucomisd   xmm1, xmm2
    jne       .div_float
    test      rcx, rcx
    jz        .div_float             # avoid div by 0
    cqo                              # sign-extend rax → rdx:rax
    idiv      rcx                    # rax = quotient
    cvtsi2sd  xmm0, rax
    add       r14, 16
    movsd     [r14], xmm0
    DISPATCH
.div_float:
    divsd   xmm0, xmm1
    add     r14, 16
    movsd   [r14], xmm0
    DISPATCH

op_mod:
    movsd   xmm0, [r14 + 16]       # a
    movsd   xmm1, [r14]            # b
    # Integer fast-path
    cvttsd2si rax, xmm0
    cvtsi2sd  xmm2, rax
    ucomisd   xmm0, xmm2
    jne       .mod_float
    cvttsd2si rcx, xmm1
    cvtsi2sd  xmm2, rcx
    ucomisd   xmm1, xmm2
    jne       .mod_float
    test      rcx, rcx
    jz        .mod_float
    cqo
    idiv      rcx                    # rdx = remainder
    cvtsi2sd  xmm0, rdx
    add       r14, 16
    movsd     [r14], xmm0
    DISPATCH
.mod_float:
    # a % b = a - floor(a/b) * b
    movsd   xmm2, xmm0
    divsd   xmm2, xmm1
    roundsd xmm2, xmm2, 1
    mulsd   xmm2, xmm1
    subsd   xmm0, xmm2
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
    # Compare bytes (u16 molecules = mol_count × 2 bytes)
    mov     rdi, rax                # a.ptr
    mov     rsi, rcx                # b.ptr
    mov     ecx, edx                # mol_count
    shl     ecx, 1                  # byte_count = mol_count × 2
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
    mov     rax, [r14 + 16]         # a.ptr
    mov     rdx, [r14 + 24]         # a.len
    mov     rcx, [r14]              # b.ptr
    mov     rsi, [r14 + 8]          # b.len
    lea     r14, [r14 + 16]         # pop one (use lea to preserve flags)
    cmp     rdx, F64_MARKER
    jne     .ne_str
    cmp     rsi, F64_MARKER
    jne     .ne_true                # different types → not equal
    cmp     rax, rcx                # compare f64 bits
    jne     .ne_true
    jmp     .ne_false
.ne_str:
    cmp     rdx, rsi                # same length?
    jne     .ne_true
    # Compare bytes
    push    rcx
    push    rdx
    mov     rdi, rax
    mov     rsi, rcx
    mov     ecx, edx
    shl     ecx, 1                  # byte_count = mol_count × 2
    repe    cmpsb
    pop     rdx
    pop     rcx
    jne     .ne_true
.ne_false:
    xor     eax, eax
    mov     [r14], rax
    mov     qword ptr [r14 + 8], F64_MARKER
    DISPATCH
.ne_true:
    mov     rax, 0x3FF0000000000000
    mov     [r14], rax
    mov     qword ptr [r14 + 8], F64_MARKER
    DISPATCH

op_lt:
    movsd   xmm0, [r14 + 16]       # a
    ucomisd xmm0, qword ptr [r14]  # compare a vs b
    lea     r14, [r14 + 16]
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
    lea     r14, [r14 + 16]
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
    lea     r14, [r14 + 16]
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
    lea     r14, [r14 + 16]
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
    # Read name length + name + argc
    movzx   ecx, byte ptr [r12 + r13]
    inc     r13
    lea     rdi, [r12 + r13]        # name ptr
    mov     edx, ecx                # name len
    mov     [rip + _call_save_name_ptr], rdi
    mov     [rip + _call_save_name_len], rdx
    push    rcx                      # save name len
    call    hash_fnv1a              # → rax = hash
    pop     rcx
    add     r13, rcx                # advance PC past name
    movzx   ecx, byte ptr [r12 + r13]  # argc
    inc     r13
    # Check var_matrix FIRST (user functions shadow builtins)
    # rax = hash, ecx = argc. Save both.
    mov     [rip + _call_save_hash], rax
    mov     [rip + _call_save_argc], ecx
    call    var_load_matrix          # rax=ptr, rdx=len
    test    rax, rax
    jz      .call_try_builtin        # not in var_matrix → try builtins
    cmp     rdx, CLOSURE_MARKER
    je      .call_closure            # found closure → call it
    # Found but not closure — fall through to builtin
.call_try_builtin:
    mov     rax, [rip + _call_save_hash]
    # Hash table lookup with linear probe (collision-safe)
    mov     esi, eax
    and     esi, 0x1FF               # slot = hash & 511
    lea     rdx, [rip + builtin_hash_table]
    mov     edi, 8                   # max 8 probes
.call_probe:
    mov     ecx, esi
    shl     ecx, 4                   # × 16 bytes per entry
    cmp     qword ptr [rdx + rcx], 0 # empty slot → not found
    je      .call_skip
    cmp     [rdx + rcx], rax         # hash match?
    jne     .call_probe_next
    jmp     [rdx + rcx + 8]          # match → jump to handler
.call_probe_next:
    inc     esi
    and     esi, 0x1FF
    dec     edi
    jnz     .call_probe
    jmp     .call_skip               # exhausted probes
.call_closure:
    # rax = body_pc (simple) or heap_ptr (captured)
    # Push to shadow call stack for error traces
    push    rax
    mov     rcx, [rip + call_stack_depth]
    cmp     rcx, 64
    jge     .cs_skip_push
    lea     rdi, [rip + call_stack]
    imul    rcx, rcx, 24             # 24 bytes per entry
    mov     rsi, [rip + _call_save_name_ptr]
    mov     [rdi + rcx], rsi         # name_ptr
    mov     rsi, [rip + _call_save_name_len]
    mov     [rdi + rcx + 8], rsi     # name_len
    mov     esi, r13d                # call site PC
    mov     [rdi + rcx + 16], rsi    # call_pc
    inc     qword ptr [rip + call_stack_depth]
.cs_skip_push:
    pop     rax
    push    r12                      # save bytecode base
    push    r13                      # save return PC
    push    rbx                      # save bc_size
    # Push MARKER to undo stack (for scope save/restore)
    push    rax                      # save closure value
    lea     rcx, [rip + var_save_top]
    mov     rdi, [rcx]
    mov     qword ptr [rdi], -1      # MARKER (slot_off = -1)
    add     rdi, 40                  # uniform 40-byte entry
    mov     [rcx], rdi
    pop     rax
    # Scope: depth++
    inc     qword ptr [rip + closure_depth]
    # Check: simple closure (body_pc < bc_size) or captured (heap ptr)?
    cmp     rax, rbx
    jb      .call_closure_simple
    # Captured closure: rax = heap ptr → [body_pc:8][cap_count:8][caps...]
    mov     rdi, rax
    mov     r13d, [rdi]              # body_pc from heap object
    mov     rcx, [rdi+8]             # capture_count
    test    rcx, rcx
    jz      .call_closure_dispatch
    lea     rsi, [rdi + 16]          # first capture
.call_closure_restore:
    push    rcx
    push    rsi
    mov     eax, [rsi]               # hash (lower 32 bits sufficient)
    mov     r8, [rsi+8]              # ptr/value
    mov     r9, [rsi+16]             # len/marker
    call    var_store_matrix
    pop     rsi
    pop     rcx
    add     rsi, 24
    dec     rcx
    jnz     .call_closure_restore
.call_closure_dispatch:
    DISPATCH
.call_closure_simple:
    mov     r13d, eax                # PC = body_pc
    DISPATCH
.call_skip:
    # Function not found — push 0
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# 0x08: Ret
op_ret:
    pop     rbx                      # restore bc_size
    pop     r13                      # restore return PC
    pop     r12                      # restore bytecode base
    # Pop shadow call stack
    cmp     qword ptr [rip + call_stack_depth], 0
    je      .cs_skip_pop
    dec     qword ptr [rip + call_stack_depth]
.cs_skip_pop:
    # Scope restore: pop undo stack until MARKER
    cmp     qword ptr [rip + closure_depth], 0
    je      .ret_no_scope
    dec     qword ptr [rip + closure_depth]
    # Pop undo entries, restore var_matrix slots
    push    rbx
    lea     rax, [rip + var_save_top]
    mov     rcx, [rax]               # current top
    lea     rdi, [rip + var_matrix]
.ret_undo:
    sub     rcx, 40                  # back one entry
    cmp     qword ptr [rcx], -1      # MARKER?
    je      .ret_undo_done
    # Restore: [slot_off:8][hash:8][depth:8][ptr:8][len:8]
    mov     rdx, [rcx]               # slot byte offset
    mov     rsi, [rcx + 8]
    mov     [rdi + rdx], rsi         # restore hash
    mov     rsi, [rcx + 16]
    mov     [rdi + rdx + 8], rsi     # restore depth
    mov     rsi, [rcx + 24]
    mov     [rdi + rdx + 16], rsi    # restore ptr
    mov     rsi, [rcx + 32]
    mov     [rdi + rdx + 24], rsi    # restore len
    jmp     .ret_undo
.ret_undo_done:
    # Consume MARKER
    lea     rax, [rip + var_save_top]
    mov     [rax], rcx               # top = before MARKER
    pop     rbx
.ret_no_scope:
    DISPATCH

# 0x09: Jmp [offset:4]
op_jmp:
    movsxd  rax, dword ptr [r12 + r13]  # sign-extend offset
    add     r13, 4
    add     r13, rax
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
    movsxd  rax, dword ptr [r12 + r13]  # sign-extend offset
    add     r13, 4
    add     r13, rax
    DISPATCH

# 0x0E: Loop [offset:4] — backward jump
op_loop:
    movsxd  rax, dword ptr [r12 + r13]  # sign-extend 32-bit offset to 64
    add     r13, 4
    add     r13, rax                # PC += offset (negative for backward)
    DISPATCH

# ── Variable ops: 0x02, 0x13 ──

# 0x02: Load [name_len:1][name:N]
op_load:
    movzx   ecx, byte ptr [r12 + r13]  # name_len
    inc     r13
    lea     rdi, [r12 + r13]            # name ptr
    mov     edx, ecx                    # name len
    push    rcx
    call    hash_fnv1a                  # rax = 64-bit hash
    pop     rcx
    add     r13, rcx                    # advance PC past name
    # Use lower 32 bits for matrix lookup
    mov     eax, eax                    # zero-extend to clear upper 32
    call    var_load_matrix
    sub     r14, 16
    mov     [r14], rax
    mov     [r14 + 8], rdx
    DISPATCH

# 0x13: Store [name_len:1][name:N]
op_store:
    movzx   ecx, byte ptr [r12 + r13]  # name_len
    inc     r13
    lea     rdi, [r12 + r13]            # name ptr
    mov     edx, ecx                    # name len
    push    rcx
    call    hash_fnv1a                  # rax = 64-bit hash
    pop     rcx
    add     r13, rcx                    # advance PC past name
    mov     r8, [r14]                   # val.ptr
    mov     r9, [r14 + 8]              # val.len
    add     r14, 16                     # pop
    mov     eax, eax                    # lower 32 bits
    call    var_store_matrix
    DISPATCH

# 0x16: StoreLocal [name_len:1][name:N] — let statement (shadows, undo on return)
op_store_local:
    movzx   ecx, byte ptr [r12 + r13]  # name_len
    inc     r13
    lea     rdi, [r12 + r13]            # name ptr
    mov     edx, ecx                    # name len
    push    rcx
    call    hash_fnv1a                  # rax = 64-bit hash
    pop     rcx
    add     r13, rcx                    # advance PC past name
    mov     r8, [r14]                   # val.ptr
    mov     r9, [r14 + 8]              # val.len
    add     r14, 16                     # pop
    mov     eax, eax                    # lower 32 bits
    call    var_store_local
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
# §13 CLOSURES
# ═══════════════════════════════════════════════════════════════════════════

# 0x24: CallClosure [name_len:1][name:N][argc:1]
op_call_closure:
    movzx   ecx, byte ptr [r12 + r13]
    inc     r13
    lea     rdi, [r12 + r13]
    mov     edx, ecx
    push    rcx
    call    hash_fnv1a
    pop     rcx
    add     r13, rcx
    movzx   ecx, byte ptr [r12 + r13]
    inc     r13
    push    rcx
    call    var_load_matrix
    pop     rcx
    test    rax, rax
    jz      .ccl_notfound
    push    r12
    push    r13
    push    rbx
    inc     qword ptr [rip + closure_depth]
    # Check: simple closure (body_pc) or captured closure (heap object)?
    cmp     rax, rbx                 # body_pc < bytecode_size?
    jb      .ccl_simple
    # Captured closure: rax = heap ptr → [body_pc:8][cap_count:8][caps...]
    mov     rdi, rax                 # save heap ptr
    mov     r13d, [rdi]              # body_pc from heap object
    mov     rcx, [rdi+8]             # capture_count
    test    rcx, rcx
    jz      .ccl_dispatch
    # Restore captured variables: each cap is [hash:8][ptr:8][len:8]
    lea     rsi, [rdi + 16]          # first capture
.ccl_restore_cap:
    push    rcx
    push    rsi
    mov     eax, [rsi]               # hash (lower 32 bits)
    mov     r8, [rsi+8]              # ptr/value
    mov     r9, [rsi+16]             # len/marker
    call    var_store_matrix         # eax=hash, r8=ptr, r9=len
    pop     rsi
    pop     rcx
    add     rsi, 24                  # next capture
    dec     rcx
    jnz     .ccl_restore_cap
.ccl_dispatch:
    DISPATCH
.ccl_simple:
    mov     r13d, eax                # simple: body_pc directly
    DISPATCH
.ccl_notfound:
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# 0x25: Closure [param_count:1][body_len:4][body...]
op_closure:
    movzx   ecx, byte ptr [r12 + r13]   # param_count (unused for now)
    inc     r13
    mov     eax, dword ptr [r12 + r13]            # body_len (u32 LE)
    add     r13, 4
    mov     edx, r13d                    # body_pc = current PC
    add     r13d, eax                    # skip body bytes
    sub     r14, 16
    mov     [r14], rdx                   # push body_pc
    mov     qword ptr [r14+8], CLOSURE_MARKER
    DISPATCH

# 0x30: ClosureCapture [param_count:1][capture_count:1][cap_names...][body_len:4][body...]
op_closure_cap:
    movzx   ecx, byte ptr [r12 + r13]   # param_count
    inc     r13
    movzx   edx, byte ptr [r12 + r13]   # capture_count
    inc     r13
    # Allocate heap object: [body_pc:8][capture_count:8][(hash:8,ptr:8,len:8)×N]
    mov     rbp, r15
    add     r15, 16                      # header space
    push    rcx
    push    rdx
    mov     ecx, edx
    test    ecx, ecx
    jz      .ccc_done
.ccc_loop:
    push    rcx
    movzx   ecx, byte ptr [r12 + r13]   # cap name len
    inc     r13
    lea     rdi, [r12 + r13]
    mov     edx, ecx
    push    rcx
    call    hash_fnv1a
    pop     rcx
    add     r13, rcx
    push    rax
    call    var_load_matrix
    mov     r8, rax
    mov     r9, rdx
    pop     rax
    mov     [r15], rax                   # hash
    mov     [r15+8], r8                  # ptr
    mov     [r15+16], r9                 # len
    add     r15, 24
    pop     rcx
    dec     ecx
    jnz     .ccc_loop
.ccc_done:
    pop     rdx                          # capture_count
    pop     rcx                          # param_count
    mov     eax, dword ptr [r12 + r13]            # body_len
    add     r13, 4
    mov     edi, r13d                    # body_pc
    add     r13d, eax                    # skip body
    mov     [rbp], rdi                   # store body_pc
    mov     [rbp+8], rdx                 # store capture_count
    sub     r14, 16
    mov     [r14], rbp                   # push heap object ptr
    mov     qword ptr [r14+8], CLOSURE_MARKER
    DISPATCH

# ═══════════════════════════════════════════════════════════════════════════
# §14 EXCEPTION HANDLING
# ═══════════════════════════════════════════════════════════════════════════

# 0x1A: TryBegin [catch_offset:4]
op_try_begin:
    mov     eax, dword ptr [r12 + r13]            # catch offset
    add     r13, 4
    # Push try frame on CPU stack: [catch_pc:8][saved_r14:8][saved_r15:8]
    push    r15                          # save heap
    push    r14                          # save VM stack
    push    rax                          # catch PC
    inc     qword ptr [rip + try_depth]
    DISPATCH

# 0x1B: CatchEnd — end of catch block, pop try frame
op_catch_end:
    cmp     qword ptr [rip + try_depth], 0
    je      .ce_skip
    pop     rax                          # discard catch_pc
    pop     r14                          # discard saved stack (we're past the try now)
    pop     r15                          # discard saved heap
    dec     qword ptr [rip + try_depth]
.ce_skip:
    DISPATCH

# 0x78: Throw — jump to catch handler
op_throw:
    cmp     qword ptr [rip + try_depth], 0
    je      .throw_uncaught
    pop     rax                          # catch_pc
    pop     r14                          # restore VM stack
    pop     r15                          # restore heap
    dec     qword ptr [rip + try_depth]
    mov     r13d, eax                    # jump to catch
    DISPATCH
.throw_uncaught:
    # Print "Error at line N" then halt
    # Find line table: at [r12 + code_size] where code_size is stored at [r12 + code_size]
    # Format: [code_size:4]["LN":2][count:4][(offset:4,line:4)×N]
    push    r13                          # save current PC (error location)
    # Line table starts right after code. First 4 bytes after code = code_size itself.
    # The code_size value is at bytecode[code_size] — but we need to find it.
    # Actually the bytecode is: [code bytes][code_size:4][LN:2][count:4][entries...]
    # code_size = position of first non-code byte.
    # The HALT opcode is the last code byte. It's at some position.
    # Simpler: read code_size from bc_size: line table = [bc_data + (bc_size - line_table_size)]
    # OR: just scan backward from bc_size for "LN" magic
    # Scan backward for magic 0xDEAD4C4E
    mov     ecx, ebx
    sub     ecx, 4
.tu_scan_back:
    cmp     ecx, 0
    jle     .tu_no_linetable
    cmp     dword ptr [r12 + rcx], 0xDEAD4C4E
    je      .tu_found_lt
    dec     ecx
    jmp     .tu_scan_back
.tu_found_lt:
    lea     rdi, [r12 + rcx]
    mov     ecx, [rdi+4]               # entry count
    lea     rsi, [rdi+8]               # first entry
    pop     rax                         # error PC (points after throw instruction)
    dec     eax                         # adjust to point AT the throw
    # Linear search: find last entry where offset <= error PC
    xor     edx, edx                    # best line = 0
.tu_search:
    test    ecx, ecx
    jz      .tu_print
    cmp     [rsi], eax                  # entry.offset <= error PC?
    ja      .tu_print                   # past our PC → stop
    mov     edx, [rsi+4]               # update best line
    add     rsi, 8
    dec     ecx
    jmp     .tu_search
.tu_print:
    # edx = source line number. Print "Error at line N\n"
    test    edx, edx
    jz      .tu_no_line
    # Convert line number to string and print
    push    rdx
    lea     rsi, [rip + .str_error_at]
    mov     edx, 14                     # "Error at line "
    mov     edi, 2                      # stderr
    mov     eax, SYS_WRITE
    syscall
    pop     rdx
    # Print line number (simple: convert to digits on stack)
    sub     rsp, 16
    mov     rdi, rsp
    add     rdi, 15
    mov     byte ptr [rdi], 10          # newline
    mov     ecx, 1                      # digit count (including newline)
    mov     eax, edx
.tu_digits:
    xor     edx, edx
    mov     esi, 10
    div     esi                         # eax=quotient, edx=remainder
    add     dl, 48                      # digit char
    dec     rdi
    mov     [rdi], dl
    inc     ecx
    test    eax, eax
    jnz     .tu_digits
    # Write digits
    mov     rsi, rdi
    mov     edx, ecx
    mov     edi, 2                      # stderr
    mov     eax, SYS_WRITE
    syscall
    add     rsp, 16
    # Print call stack trace
    mov     rcx, [rip + call_stack_depth]
    test    rcx, rcx
    jz      .tu_halt
    lea     rdi, [rip + call_stack]
    # Walk stack from top to bottom
.tu_trace_loop:
    test    rcx, rcx
    jz      .tu_halt
    dec     rcx
    push    rcx
    push    rdi
    # Print "  at " (4 bytes)
    lea     rsi, [rip + .str_at]
    mov     edx, 5
    mov     edi, 2
    mov     eax, SYS_WRITE
    syscall
    pop     rdi
    pop     rcx
    # Print function name (name_ptr, name_len from shadow stack entry)
    push    rcx
    push    rdi
    imul    rax, rcx, 24
    mov     rsi, [rdi + rax]         # name_ptr
    mov     edx, [rdi + rax + 8]     # name_len
    mov     edi, 2
    mov     eax, SYS_WRITE
    syscall
    # Print newline
    lea     rsi, [rip + str_newline]
    mov     edx, 1
    mov     edi, 2
    mov     eax, SYS_WRITE
    syscall
    pop     rdi
    pop     rcx
    jmp     .tu_trace_loop
.tu_halt:
    jmp     op_halt
.tu_no_line:
    pop     rax
.tu_no_linetable:
    # No line table or no match — just print generic error
    lea     rsi, [rip + .str_uncaught]
    mov     edx, 17                     # "Uncaught error!\n"
    mov     edi, 2
    mov     eax, SYS_WRITE
    syscall
    jmp     op_halt

.str_error_at:  .ascii "Error at line "
.str_at:        .ascii "  at "
.str_uncaught:  .ascii "Uncaught error!\n"

# ═══════════════════════════════════════════════════════════════════════════
# STRING CONCAT (Add on strings)
# ═══════════════════════════════════════════════════════════════════════════
# The op_add handler needs to detect string + string and concat.
# We modify op_add to check types:

string_concat:
    # rax=ptr_a, rdx=len_a (from caller), r8=ptr_b, r9=len_b
    # Allocate new string on heap: len_a + len_b u16 molecules
    mov     rdi, r15                     # dest
    mov     rcx, rdx                     # len_a mol count
    shl     rcx, 1                       # × 2 bytes
    mov     rsi, rax                     # src_a
    push    rdx
    push    r8
    push    r9
    mov     edx, ecx
    call    memcpy_inline                # copy a
    pop     r9
    pop     r8
    pop     rdx
    # Copy b after a
    lea     rdi, [r15 + rdx*2]          # dest = after a
    mov     rsi, r8                      # src_b
    mov     ecx, r9d
    shl     ecx, 1
    push    rdx
    push    r9
    mov     edx, ecx
    call    memcpy_inline
    pop     r9
    pop     rdx
    # Result
    mov     rax, r15                     # new ptr
    add     rdx, r9                      # total len = len_a + len_b
    lea     rcx, [rdx*2]
    add     r15, rcx                     # bump heap
    # Push result
    sub     r14, 16
    mov     [r14], rax
    mov     [r14+8], rdx
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

# 0x53: KtWalk — pop (depth, dim, mol) → push array of walked mols
# Walk via mol_matrix + silk_matrix (Hebbian edges), returns best neighbors
op_kt_walk:
    # Identical interface to SilkWalk — reuse implementation
    jmp     op_silk_walk

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
    # Hebbian strengthen: Δw = (1 - w/65535) × φ⁻³ × 1000
    # φ⁻³ ≈ 0.236, × 1000 = 236. Diminishing returns near saturation.
    mov     eax, 65535
    sub     eax, esi                 # (65535 - w)
    imul    eax, 236                 # × φ⁻³ × 1000
    shr     eax, 10                  # / 1024 ≈ / 1000
    add     esi, eax                 # w += Δw
    cmp     esi, 65535
    jle     .sf_store
    mov     esi, 65535
.sf_store:
    mov     word ptr [rdi + rdx*2], si
    DISPATCH
.sf_create:
    # Initial weight = φ⁻² × 65535 ≈ 25000 (not arbitrary 500)
    mov     word ptr [rdi + rdx*2], 25000
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
    imul    eax, 618                # ×φ⁻¹ ≈ 0.618 per 24h cycle
    mov     edx, eax
    shr     edx, 10                 # /1024 ≈ /1000 (fast approximation)
    mov     eax, edx
    mov     word ptr [rsi + rcx*2], ax
.sd_next:
    inc     ecx
    jmp     .sd_loop
.sd_done:
    DISPATCH

# 0x5A: SilkWalk — pop (depth, dim, mol) → push array of walked mols
# Greedy walk along dominant dimension, collecting mols with mol_matrix entries
op_silk_walk:
    # Pop 3: depth(f64), dim(f64), mol(f64/mol)
    movsd   xmm0, [r14]
    cvttsd2si r8d, xmm0             # r8d = depth
    movsd   xmm0, [r14+16]
    cvttsd2si ecx, xmm0             # ecx = dim (0-4)
    movsd   xmm0, [r14+32]
    cvttsd2si edx, xmm0             # edx = source mol
    add     r14, 48                  # pop 3
    push    rbx
    push    rbp
    mov     ebp, edx                 # ebp = current mol
    # Clamp depth 1..16
    test    r8d, r8d
    jle     .sw_empty
    cmp     r8d, 16
    jle     .sw_depth_ok
    mov     r8d, 16
.sw_depth_ok:
    # Compute dimension step: dim→shift [12,8,5,2,0]
    mov     ebx, 1                   # base
    cmp     ecx, 0
    je      .sw_dim_s
    cmp     ecx, 1
    je      .sw_dim_r
    cmp     ecx, 2
    je      .sw_dim_v
    cmp     ecx, 3
    je      .sw_dim_a
    jmp     .sw_dim_done             # dim=4(T): step=1
.sw_dim_s:
    shl     ebx, 12                  # 0x1000
    jmp     .sw_dim_done
.sw_dim_r:
    shl     ebx, 8                   # 0x100
    jmp     .sw_dim_done
.sw_dim_v:
    shl     ebx, 5                   # 0x20
    jmp     .sw_dim_done
.sw_dim_a:
    shl     ebx, 2                   # 0x4
.sw_dim_done:
    # Allocate result array: [cap:8][count:8][16 entries × 16 bytes]
    mov     r10, r15                 # array base
    mov     qword ptr [r15], 16      # capacity
    mov     qword ptr [r15+8], 0     # count = 0
    lea     r15, [r15 + 272]         # 16 + 16×16 = 272
    xor     r11d, r11d               # count = 0
    lea     r9, [rip + mol_matrix]
.sw_hop:
    test    r8d, r8d
    jle     .sw_finish
    dec     r8d
    # Try +1 step in dim
    lea     eax, [ebp + ebx]
    cmp     eax, 0xFFFF
    ja      .sw_try_neg
    movzx   ecx, word ptr [r9 + rax*2]
    test    ecx, ecx
    jnz     .sw_add
.sw_try_neg:
    # Try -1 step
    mov     eax, ebp
    sub     eax, ebx
    js      .sw_try_p2
    movzx   ecx, word ptr [r9 + rax*2]
    test    ecx, ecx
    jnz     .sw_add
.sw_try_p2:
    # Try +2 step
    lea     eax, [ebp + ebx*2]
    cmp     eax, 0xFFFF
    ja      .sw_try_n2
    movzx   ecx, word ptr [r9 + rax*2]
    test    ecx, ecx
    jnz     .sw_add
.sw_try_n2:
    # Try -2 step
    mov     eax, ebp
    sub     eax, ebx
    sub     eax, ebx
    js      .sw_finish
    movzx   ecx, word ptr [r9 + rax*2]
    test    ecx, ecx
    jz      .sw_finish               # no neighbor found
.sw_add:
    # eax = found mol → add to array, advance
    cmp     r11d, 16
    jge     .sw_finish
    mov     ebp, eax                 # current = found mol
    cvtsi2sd xmm0, eax
    mov     ecx, r11d
    shl     ecx, 4                   # byte offset = count × 16
    movsd   [r10 + 16 + rcx], xmm0
    mov     qword ptr [r10 + 16 + rcx + 8], MOL_MARKER
    inc     r11d
    mov     [r10+8], r11             # update count
    jmp     .sw_hop
.sw_finish:
    sub     r14, 16
    mov     [r14], r10
    mov     qword ptr [r14+8], ARRAY_MARKER
    pop     rbp
    pop     rbx
    DISPATCH
.sw_empty:
    # Return empty array
    mov     rax, r15
    mov     qword ptr [r15], 0
    mov     qword ptr [r15+8], 0
    add     r15, 16
    sub     r14, 16
    mov     [r14], rax
    mov     qword ptr [r14+8], ARRAY_MARKER
    pop     rbp
    pop     rbx
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
    mov     rax, [rip + zone_b_top]
    mov     [rip + zone_b_ptr], rax   # Zone B grows DOWN, reset to top
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
    push    rdx
    xor     edx, edx
    push    rcx
    mov     ecx, 1000
    div     ecx                      # exact /1000
    pop     rcx
    pop     rdx
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

# ═══════════════════════════════════════════════════════════════════════════
# §29 CAPABILITY-BASED SECURITY
# ═══════════════════════════════════════════════════════════════════════════

# 0xB0: CapCheck — pop (slot, required_perms) → push 1/0
op_cap_check:
    movsd   xmm0, [r14]
    cvttsd2si esi, xmm0              # required perms
    movsd   xmm0, [r14+16]
    cvttsd2si edi, xmm0              # slot
    add     r14, 32
    and     edi, 0xFF
    lea     rcx, [rip + cap_table]
    shl     edi, 3                   # × 8 bytes
    movzx   eax, word ptr [rcx + rdi + 5]
    and     eax, esi
    cmp     eax, esi
    je      .cpc_allow
    xor     eax, eax
    jmp     .cpc_push
.cpc_allow:
    mov     eax, 1
.cpc_push:
    sub     r14, 16
    cvtsi2sd xmm0, eax
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# 0xB1: CapCreate — pop (type, id, perms) → push slot
op_cap_create:
    movsd   xmm0, [r14]
    cvttsd2si esi, xmm0              # perms
    movsd   xmm0, [r14+16]
    cvttsd2si edx, xmm0              # id
    movsd   xmm0, [r14+32]
    cvttsd2si ecx, xmm0              # type
    add     r14, 48
    lea     rdi, [rip + cap_table]
    xor     eax, eax
.cc2_find:
    cmp     eax, 256
    jge     .cc2_full
    cmp     byte ptr [rdi + rax*8], 0
    je      .cc2_write
    inc     eax
    jmp     .cc2_find
.cc2_write:
    mov     byte ptr [rdi + rax*8], cl
    mov     dword ptr [rdi + rax*8 + 1], edx
    mov     word ptr [rdi + rax*8 + 5], si
    mov     byte ptr [rdi + rax*8 + 7], 0
    cvtsi2sd xmm0, eax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH
.cc2_full:
    sub     r14, 16
    mov     eax, -1
    cvtsi2sd xmm0, eax
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# 0xB2: CapDelegate — pop (slot, child_perms) → push child_slot
op_cap_delegate:
    movsd   xmm0, [r14]
    cvttsd2si esi, xmm0
    movsd   xmm0, [r14+16]
    cvttsd2si edi, xmm0
    add     r14, 32
    and     edi, 0xFF
    lea     rcx, [rip + cap_table]
    movzx   eax, word ptr [rcx + rdi*8 + 5]
    test    eax, 8                   # DELEGATE bit
    jz      .cd2_fail
    and     esi, eax                 # reduce permissions
    mov     cl, [rcx + rdi*8]        # type
    mov     edx, [rcx + rdi*8 + 1]  # id
    lea     rdi, [rip + cap_table]
    xor     eax, eax
.cd2_find:
    cmp     eax, 256
    jge     .cd2_fail
    cmp     byte ptr [rdi + rax*8], 0
    je      .cd2_create
    inc     eax
    jmp     .cd2_find
.cd2_create:
    mov     byte ptr [rdi + rax*8], cl
    mov     dword ptr [rdi + rax*8 + 1], edx
    mov     word ptr [rdi + rax*8 + 5], si
    cvtsi2sd xmm0, eax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH
.cd2_fail:
    sub     r14, 16
    mov     eax, -1
    cvtsi2sd xmm0, eax
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# 0xB3: CapRevoke — pop slot → revoke
op_cap_revoke:
    movsd   xmm0, [r14]
    cvttsd2si edi, xmm0
    add     r14, 16
    and     edi, 0xFF
    lea     rcx, [rip + cap_table]
    mov     qword ptr [rcx + rdi*8], 0
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# 0xB4: SecGate — SecurityGate check V/A
op_sec_gate:
    mov     ecx, [r14]               # mol
    add     r14, 16
    mov     edx, ecx
    shr     edx, 5
    and     edx, 0x7                 # V
    mov     esi, ecx
    shr     esi, 2
    and     esi, 0x7                 # A
    sub     r14, 16
    cmp     edx, 1                   # V ≤ 1?
    jg      .sg2_safe
    cmp     esi, 6                   # A ≥ 6?
    jl      .sg2_safe
    mov     eax, 1                   # CRISIS
    cvtsi2sd xmm0, eax
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH
.sg2_safe:
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# ═══════════════════════════════════════════════════════════════════════════
# §17 SELF-MODIFICATION SUPPORT
# ═══════════════════════════════════════════════════════════════════════════

# hot_reload_check: verify new bytecode header
# Input: rdi=ptr, rsi=size → eax=1 valid, 0 invalid
hot_reload_check:
    cmp     esi, 48
    jl      .hrc_fail
    cmp     dword ptr [rdi], 0x474E4C4F   # "OLNG" little-endian
    jne     .hrc_fail
    cmp     byte ptr [rdi+4], 2       # version 2
    jne     .hrc_fail
    mov     eax, 1
    ret
.hrc_fail:
    xor     eax, eax
    ret

# self_define_builtin: register runtime builtin
# edi=name_hash, esi=bytecode_offset → installs in table
self_define_builtin:
    mov     eax, edi
    and     eax, 0x1FF
    cmp     eax, 0x100
    jl      .sdb_skip                # reserved range
    lea     rcx, [rip + builtin_hash_table]
    lea     rdx, [r12 + rsi]
    mov     [rcx + rax*8], rdx
.sdb_skip:
    ret

# ═══════════════════════════════════════════════════════════════════════════
# §16 SIMD BATCH OPERATIONS (SSE2)

# mol_batch_dist_8: 8 molecular distances in 1 SSE2 pass
# Input: xmm0 = query broadcast, rsi = candidate u16 array ptr, ecx = offset
# Output: 8 distances in simd_temp buffer
# Clobbers: xmm1-xmm5
mol_batch_dist_8:
    movdqu  xmm1, [rsi + rcx*2]     # load 8 candidate mols
    # ΔS
    movdqa  xmm2, xmm0
    movdqa  xmm3, xmm1
    psrlw   xmm2, 12
    psrlw   xmm3, 12
    psubw   xmm2, xmm3
    pabsw   xmm2, xmm2              # |ΔS| × 1
    # ΔR
    movdqa  xmm3, xmm0
    movdqa  xmm4, xmm1
    psrlw   xmm3, 8
    movdqu  xmm5, [rip + simd_mask_0F]
    pand    xmm3, xmm5
    psrlw   xmm4, 8
    pand    xmm4, xmm5
    psubw   xmm3, xmm4
    pabsw   xmm3, xmm3
    paddw   xmm2, xmm3
    # ΔV × 2
    movdqa  xmm3, xmm0
    movdqa  xmm4, xmm1
    psrlw   xmm3, 5
    movdqu  xmm5, [rip + simd_mask_07]
    pand    xmm3, xmm5
    psrlw   xmm4, 5
    pand    xmm4, xmm5
    psubw   xmm3, xmm4
    pabsw   xmm3, xmm3
    psllw   xmm3, 1
    paddw   xmm2, xmm3
    # ΔA × 2
    movdqa  xmm3, xmm0
    movdqa  xmm4, xmm1
    psrlw   xmm3, 2
    pand    xmm3, xmm5              # reuse mask_07
    psrlw   xmm4, 2
    pand    xmm4, xmm5
    psubw   xmm3, xmm4
    pabsw   xmm3, xmm3
    psllw   xmm3, 1
    paddw   xmm2, xmm3
    # ΔT × 4
    movdqa  xmm3, xmm0
    movdqa  xmm4, xmm1
    movdqu  xmm5, [rip + simd_mask_03]
    pand    xmm3, xmm5
    pand    xmm4, xmm5
    psubw   xmm3, xmm4
    pabsw   xmm3, xmm3
    psllw   xmm3, 2
    paddw   xmm2, xmm3
    # xmm2 = 8 scaled distances
    movdqu  [rip + simd_temp], xmm2
    ret

# act_decay_simd: decay all 65536 act_matrix entries by factor (SSE2)
# ~8μs for full 128KB scan (vs ~65μs scalar)
act_decay_simd:
    lea     rsi, [rip + act_matrix]
    mov     ecx, 8192                # 65536/8
    movdqu  xmm1, [rip + simd_decay_factor]
.acds_loop:
    movdqu  xmm0, [rsi]
    pmulhuw xmm0, xmm1              # val * factor / 65536
    movdqu  [rsi], xmm0
    add     rsi, 16
    dec     ecx
    jnz     .acds_loop
    ret

op_unknown:
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
# Used by OP_STORE (bare assign) — mutates existing var, no scope save
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
    # Bare assign: mutate in place, DON'T change depth, DON'T save
    # (This is intentional global mutation like g_count = g_count + 1)
    mov     [rbx + rcx], eax         # hash
    mov     [rbx + rcx + 16], r8     # val.ptr
    mov     [rbx + rcx + 24], r9     # val.len
    # If slot was empty, set depth to current
    cmp     qword ptr [rbx + rcx + 8], 0
    jne     .vsm_done
    mov     rdx, [rip + closure_depth]
    mov     [rbx + rcx + 8], rdx
.vsm_done:
    pop     rbx
    ret

# var_store_local: eax=hash, r8=val.ptr, r9=val.len
# Used by OP_STORE_LOCAL (let statement) — creates local, saves old for undo
var_store_local:
    push    rbx
    mov     ecx, eax
    and     ecx, 0x3FFF
    shl     ecx, 5
    lea     rbx, [rip + var_matrix]
.vsl_probe:
    cmp     qword ptr [rbx + rcx], 0
    je      .vsl_write
    cmp     [rbx + rcx], eax
    je      .vsl_write
    add     ecx, 32
    cmp     ecx, 524288
    jb      .vsl_probe
    xor     ecx, ecx
    jmp     .vsl_probe
.vsl_write:
    # Save old value if inside closure AND depth differs
    cmp     qword ptr [rip + closure_depth], 0
    je      .vsl_no_save              # global scope → no save
    mov     rdx, [rip + closure_depth]
    cmp     [rbx + rcx + 8], rdx
    je      .vsl_no_save              # same depth → overwrite
    # Different depth → save for undo (shadowing)
    push    rax
    push    rdi
    lea     rdi, [rip + var_save_top]
    mov     rax, [rdi]
    mov     [rax], rcx               # slot byte offset
    mov     rdx, [rbx + rcx]
    mov     [rax + 8], rdx           # old hash
    mov     rdx, [rbx + rcx + 8]
    mov     [rax + 16], rdx          # old depth
    mov     rdx, [rbx + rcx + 16]
    mov     [rax + 24], rdx          # old ptr
    mov     rdx, [rbx + rcx + 24]
    mov     [rax + 32], rdx          # old len
    add     rax, 40
    mov     [rdi], rax
    pop     rdi
    pop     rax
.vsl_no_save:
    # Set depth to current
    mov     rdx, [rip + closure_depth]
    mov     [rbx + rcx + 8], rdx
    mov     [rbx + rcx], eax         # hash
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

# f64_to_string: xmm0=value → rax=ptr, rdx=len (on Zone C heap)
# Converts f64 to decimal string. Integer part only for now.
f64_to_string:
    # Output u16 molecules (not bytes) — VM string format
    push    r15                      # save heap ptr (= output start)
    cvttsd2si rax, xmm0             # integer part
    # Handle negative
    test    rax, rax
    jns     .f2s_pos
    mov     word ptr [r15], '-'      # u16 molecule
    add     r15, 2
    neg     rax
.f2s_pos:
    # Handle zero
    test    rax, rax
    jnz     .f2s_nonzero
    mov     word ptr [r15], '0'
    add     r15, 2
    jmp     .f2s_done
.f2s_nonzero:
    # Convert integer to decimal digits (reversed into temp u16 area)
    lea     rdi, [r15 + 48]          # temp end (room for 24 u16 digits)
    mov     r8, rdi
.f2s_digit:
    test    rax, rax
    jz      .f2s_copy
    xor     edx, edx
    mov     rcx, 10
    div     rcx                      # rax = quotient, rdx = remainder
    add     dl, '0'
    sub     rdi, 2                   # back 1 u16
    mov     word ptr [rdi], dx       # store as u16 molecule
    jmp     .f2s_digit
.f2s_copy:
    # Copy u16 digits from temp to output
    mov     rsi, rdi                 # src = first digit
    mov     rdi, r15                 # dst = output position
    mov     rcx, r8
    sub     rcx, rsi                 # byte count
    rep     movsb
    mov     r15, rdi                 # r15 past last digit
.f2s_done:
    pop     rax                      # rax = output start
    mov     rdx, r15
    sub     rdx, rax                 # rdx = total bytes
    shr     rdx, 1                   # rdx = mol count (bytes / 2)
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
    .quad   op_store_local  # 0x16 (StoreLocal — let statement)
    .quad   op_nop          # 0x17 (ScopeBegin stub)
    .quad   op_nop          # 0x18 (ScopeEnd stub)
    .quad   op_push_mol     # 0x19
    .quad   op_try_begin    # 0x1A TryBegin
    .quad   op_catch_end    # 0x1B CatchEnd
    .quad   op_store        # 0x1C (StoreUpdate = Store)
    .quad   op_nop          # 0x1D (Trace)
    .quad   op_nop          # 0x1E (Inspect)
    .quad   op_nop          # 0x1F (Assert)
    .quad   op_nop          # 0x20 (TypeOf)
    .quad   op_nop          # 0x21 (Why)
    .quad   op_nop          # 0x22 (Explain)
    .quad   op_nop          # 0x23 (Ffi)
    .quad   op_call_closure  # 0x24 CallClosure
    .quad   op_closure      # 0x25 Closure
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
    .quad   op_closure_cap  # 0x30 ClosureCapture
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
    .quad   op_throw        # 0x78 Throw
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
    # 0xB0-0xB4: Security (§29)
    .quad   op_cap_check, op_cap_create, op_cap_delegate, op_cap_revoke, op_sec_gate
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

# ═══ Builtin Jump Table (512 slots, auto-generated) ═══
# Index = FNV-1a(name) & 0x1FF. Collisions: linear probe.
# ═══ Builtin Hash Table (512 × 16 bytes = 8KB, auto-generated) ═══
# Entry: [hash:8][handler:8]. Dispatch: match hash → call, else probe next.
.align 8
builtin_hash_table:
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x230B1BF698686603  # __log
    .quad   .builtin_log
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x8E218B3185A1C411  # __array_slice
    .quad   .builtin_array_slice
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x234A766F8747B620  # __dict_keys
    .quad   .builtin_dict_keys
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x3A1642345E94EA24
    .quad   .builtin_str_find
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xE34AF099266AB028  # __mem_read32
    .quad   .builtin_mem_read32
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x9AC7CE5A9EB9FA35
    .quad   .builtin_heap_pin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x6CB96C9AE6FE4E41  # __u8_set
    .quad   .builtin_u8_set
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x4A829EA00BA2FE44  # __mem_write8
    .quad   .builtin_mem_write8
    .quad   0x1157F2DB94C06A45  # __readline
    .quad   .builtin_readline
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x2103FCFE38826C54
    .quad   .builtin_mx_w
    .quad   0xC2513AFE03098454  # __mmap
    .quad   .builtin_mmap
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xA4B7BF6E270F2A57
    .quad   .builtin_array_get
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x7DC336EFBBA1F85B
    .quad   .builtin_f64_to_le_bytes
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x2C6FF83E07A3C85D  # __str_to_num
    .quad   .builtin_str_to_num
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x79C07AA57E23765F  # __tcp_connect
    .quad   .builtin_tcp_connect
    .quad   0x29468D7CC2100660  # __f64_new
    .quad   .builtin_f64_new
    .quad   0xC8220FDA76231661
    .quad   .builtin_file_write
    .quad   0xC60CB074703A7C62  # __fd_open
    .quad   .builtin_fd_open
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x9E3D368BE8B3606A
    .quad   .builtin_ceil
    .quad   0x325D856BA281A26A
    .quad   .builtin_system
    .quad   0x1B63E5F6945BD26B  # __max (probe from 107)
    .quad   .builtin_max
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xECF7E3335641986E
    .quad   .builtin_bit_shr
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xDD3AF5492696D871
    .quad   .builtin_tcp_close
    .quad   0x79CE1073C7BA6272  # __log10
    .quad   .builtin_log10
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x67EB4FF1020B0474  # __v_push
    .quad   .builtin_v_push
    .quad   0x5F36C1716ED5B874  # __chain_copy
    .quad   .builtin_chain_copy
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x1C44C0F08C07EC77  # __mmap_file
    .quad   .builtin_mmap_file
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xB05BA22B379D087B  # __stm_count
    .quad   .builtin_stm_count
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x333F701075D38A7F  # __str_join
    .quad   .builtin_str_join
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x31F6E47C4AE5A082
    .quad   .builtin_bit_or
    .quad   0xC7FBC9042B95D482  # __fd_read
    .quad   .builtin_fd_read
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x476AF38F6AE2E487
    .quad   .builtin_type_of
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xD6D2AFF66DBA308A
    .quad   .builtin_exp
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x4A94D43F636D9492
    .quad   .builtin_array_with_cap
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x07515EC1BC3E1099
    .quad   .builtin_char_code
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x46A5AFF6ACD8369F  # __pow
    .quad   .builtin_pow
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x9BDA6199099438A1  # __atan
    .quad   .builtin_atan
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x1BA208C5DAE0ECA4  # __random
    .quad   .builtin_random
    .quad   0xC3A02D0FADAAA8A5
    .quad   .builtin_sqrt
    .quad   0x8415CC91A41356A6  # __pseudo_select
    .quad   .builtin_pseudo_select
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x29A788D52F20A4A8  # __act_decay
    .quad   .builtin_act_decay
    .quad   0xF2F5621EBF8B56A8  # __wm_read
    .quad   .builtin_wm_read
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x495BE76EAB8378AD
    .quad   .builtin_tcp_send
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x41219D25D562C6AF
    .quad   .builtin_str_index_of
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x526EB811B28D5CB2
    .quad   .builtin_range
    .quad   0xAC14F0D5445512B2  # __str_ends_with (probe from 178)
    .quad   .builtin_str_ends_with
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xCC77F04E614970B5  # __munmap
    .quad   .builtin_munmap
    .quad   0x3EE101F3C5E7F2B5  # __mem_write32
    .quad   .builtin_mem_write32
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x057869B5C5C376BC  # __negative_mark
    .quad   .builtin_negative_mark
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xECE98A081C4642C2
    .quad   .builtin_file_append_bytes
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x4DF573A9858FB4C5  # __array_reverse
    .quad   .builtin_array_reverse
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x24D59CBB354B1ECE  # __conv_tone
    .quad   .builtin_conv_tone
    .quad   0x83B7937C64038ACE  # __f64_set
    .quad   .builtin_f64_set
    .quad   0x8D90008B055AECD0  # __ioctl
    .quad   .builtin_ioctl
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xD219BD04DB53DED2
    .quad   .builtin_file_append
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x7551B73312F1D4D4
    .quad   .builtin_bit_and
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xC245BF77B27776D6  # __chain_quality
    .quad   .builtin_chain_quality
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xCA899B165A30E4D9  # __str_replace
    .quad   .builtin_str_replace
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xEE7C5F359328DCE9  # __time_now
    .quad   .builtin_time_now
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x304A3A896BAAE100
    .quad   .builtin_substr
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x376ECF78655E0703
    .quad   .builtin_char_at
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xA6097EB1CA418D06  # __fd_close
    .quad   .builtin_fd_close
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xECF7CD335641730C
    .quad   .builtin_bit_shl
    .quad   0xB28E0AF658B9C30D
    .quad   .builtin_abs
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x90134D214B786D0F
    .quad   .builtin_set_at
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x1B47FBF694437D15  # __min
    .quad   .builtin_min
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xAD9A9975BDE0C517
    .quad   .builtin_tcp_recv
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x5FCEDD9B2804CF1C  # __dict_set
    .quad   .builtin_dict_set
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x58745429B2B13D26  # __act_get
    .quad   .builtin_act_get
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x656D6D860AA4E534  # __sha256
    .quad   .builtin_sha256
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x6B056AF6C1EF9136  # __tan
    .quad   .builtin_tan
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xC3ADA5D879284B3B
    .quad   .builtin_write_raw
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xF446B504F965A543
    .quad   .builtin_log2
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x620D7E159BD4FF47  # __act_top_k
    .quad   .builtin_act_top_k
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x12726A191DCC2B4C
    .quad   .builtin_len
    .quad   0x1B7AE5F6946EB14C
    .quad   .builtin_mxr
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x779B5819564F2F50
    .quad   .builtin_pop_arr
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xCE5C6627B5591F52  # __crc32
    .quad   .builtin_crc32
    .quad   0xEBC46F7C9EFA6B52  # __f64_get
    .quad   .builtin_f64_get
    .quad   0x500EDE9AD5FFB553  # __u8_new
    .quad   .builtin_u8_new
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xF48798DEA5A8E159  # __bloom_check
    .quad   .builtin_bloom_check
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x3F9867C32BC1B166
    .quad   .builtin_to_string
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x5B523356365EF568  # __syscall
    .quad   .builtin_syscall
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xD0D2B17C7810176D  # __act_reset
    .quad   .builtin_act_reset
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xF2CD7EA5B92CBF7D  # __str_split
    .quad   .builtin_str_split
    .quad   0xF393AA7CA328597D  # __f64_dot
    .quad   .builtin_f64_dot
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x2E2D3BB803F9D582  # __batch_dist
    .quad   .builtin_batch_dist
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x9EEC1A86B3B21786
    .quad   .builtin_sleep
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x3B57F87CCC81F38D  # __f64_len
    .quad   .builtin_f64_len
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xC8B4C99B63B3BB90  # __dict_get
    .quad   .builtin_dict_get
    .quad   0xF10E316E51D66791
    .quad   .builtin_array_new
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x6C80030E2762459D
    .quad   .builtin_push
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xFBE159BD1C6EBFA7
    .quad   .builtin_str_trim
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x185FC0C022E829AF
    .quad   .builtin_floor
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x46660429A841B3B1  # __act_add
    .quad   .builtin_act_add
    .quad   0x061BEB9B86B295B2  # __dict_new
    .quad   .builtin_dict_new
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xAC4424D1CD437FBB  # __silk_weight
    .quad   .builtin_silk_weight
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x229C6ACCAE3B5DBE
    .quad   .builtin_file_read
    .quad   0x8436EA7A2C39DBBF  # __mem_read8
    .quad   .builtin_mem_read8
    .quad   0xAE298C0D45A467C0  # __stm_push
    .quad   .builtin_stm_push
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x6F0C4CBAC89C91C4
    .quad   .builtin_tcp_listen
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xBEE9FAE3C4AD93C7
    .quad   .builtin_heap_used
    .quad   0x4E03A6338DB8ADC8
    .quad   .builtin_bit_xor
    .quad   0x684C6A0B46DC21C9  # __atan2
    .quad   .builtin_atan2
    .quad   0xBDF45029EB7D1BCA  # __act_set
    .quad   .builtin_act_set
    .quad   0xC194C8A1C36B71CB  # __wm_bind
    .quad   .builtin_wm_bind
    .quad   0xF54D326409EE81CA  # __homeostasis
    .quad   .builtin_homeostasis
    .quad   0x03D3809AAB4F61CD  # __u8_get
    .quad   .builtin_u8_get
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x493ABC5CE7C7C7CF
    .quad   .builtin_tcp_accept
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x4DF51F96D54C8DDA  # __mol_dominant
    .quad   .builtin_mol_dominant
    .quad   0xC2CEE6D705C855DB  # __ffi_call
    .quad   .builtin_ffi_call
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xF8681D5A59E94FDF  # __str_starts_with
    .quad   .builtin_str_starts_with
    .quad   0xA95ABDDB8044CDE0  # __stm_query
    .quad   .builtin_stm_query
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xF73FC89220FC55E3  # __chain_compose
    .quad   .builtin_chain_compose
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x11C1AA218C63CDE9  # __wm_clear
    .quad   .builtin_wm_clear
    .quad   0xA401B8F65145D9EA  # __cos
    .quad   .builtin_cos
    .quad   0x2DCC3B6C275DC3E9  # __round (probe from 489)
    .quad   .builtin_round
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x2DAB4DF69EFB49EF  # __sin
    .quad   .builtin_sin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0xEC2A71D35F965BF1  # __array_sort
    .quad   .builtin_array_sort
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x5C50114C4A2FB9F9  # __silk_classify
    .quad   .builtin_silk_classify
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin
    .quad   0x0000000000000000
    .quad   .call_not_builtin

# ── More builtins (MUST be in .text section!) ──
.text

# __str_trim(str) → trimmed string (remove whitespace)
.builtin_str_trim:
    mov     rsi, [r14]               # ptr
    mov     rdx, [r14+8]             # len (mol count)
    add     r14, 16
    test    rdx, rdx
    jz      .bst_empty
    # Trim leading spaces
    xor     ecx, ecx
.bst_lead:
    cmp     rcx, rdx
    jge     .bst_empty
    movzx   eax, word ptr [rsi + rcx*2]
    cmp     eax, 32                  # space
    je      .bst_lead_next
    cmp     eax, 10                  # newline
    je      .bst_lead_next
    cmp     eax, 13                  # CR
    je      .bst_lead_next
    cmp     eax, 9                   # tab
    je      .bst_lead_next
    jmp     .bst_trail
.bst_lead_next:
    inc     rcx
    jmp     .bst_lead
.bst_trail:
    # Trim trailing
    mov     rdi, rdx
.bst_trail_loop:
    cmp     rdi, rcx
    jle     .bst_empty
    dec     rdi
    movzx   eax, word ptr [rsi + rdi*2]
    cmp     eax, 32
    je      .bst_trail_loop
    cmp     eax, 10
    je      .bst_trail_loop
    cmp     eax, 13
    je      .bst_trail_loop
    cmp     eax, 9
    je      .bst_trail_loop
    inc     rdi                      # rdi = end (exclusive)
    # Result: ptr = rsi + rcx*2, len = rdi - rcx
    sub     r14, 16
    lea     rax, [rsi + rcx*2]
    mov     [r14], rax
    sub     rdi, rcx
    mov     [r14+8], rdi
    DISPATCH
.bst_empty:
    sub     r14, 16
    xor     eax, eax
    mov     [r14], rax
    mov     qword ptr [r14+8], 0
    DISPATCH

# __system(cmd) → output string (fork + exec /bin/sh -c "cmd" + read pipe)
.builtin_system:
    mov     rsi, [r14]               # cmd ptr (u16 mols)
    mov     rdx, [r14+8]             # cmd len
    add     r14, 16
    # Decode cmd to ASCII on heap
    mov     rdi, r15
    xor     ecx, ecx
.bsys_dec:
    cmp     ecx, edx
    jge     .bsys_run
    movzx   eax, word ptr [rsi + rcx*2]
    mov     byte ptr [rdi + rcx], al
    inc     ecx
    jmp     .bsys_dec
.bsys_run:
    mov     byte ptr [rdi + rcx], 0
    push    rcx                      # save cmd len
    # Create pipe: pipe2(pipefd, 0)
    sub     rsp, 8
    mov     rdi, rsp                 # pipefd[2] on stack
    xor     esi, esi                 # flags = 0
    mov     eax, 22                  # SYS_pipe
    syscall
    mov     r8d, [rsp]               # read end
    mov     r9d, [rsp+4]             # write end
    add     rsp, 8
    # Fork
    mov     eax, 57                  # SYS_fork
    syscall
    test    eax, eax
    jz      .bsys_child
    # Parent: close write end, read from read end
    push    r8                       # save read fd
    mov     edi, r9d
    mov     eax, SYS_CLOSE
    syscall
    pop     rdi                      # read fd
    # Read output
    lea     rsi, [r15 + 4096]       # output buffer
    mov     edx, 0x10000            # max 64KB
    mov     eax, SYS_READ
    syscall
    mov     ecx, eax                 # bytes read
    push    rcx
    # Close read fd
    mov     eax, SYS_CLOSE
    syscall
    # Wait for child
    xor     edi, edi
    mov     edi, -1                  # any child
    xor     esi, esi
    xor     edx, edx
    xor     r10d, r10d
    mov     eax, 61                  # SYS_wait4
    syscall
    pop     rcx
    pop     rdx                      # discard saved cmd len
    test    ecx, ecx
    jle     .bsys_empty
    # Encode bytes to u16 mols
    lea     rsi, [r15 + 4096]
    lea     rdi, [r15 + 0x20000]    # mol output
    xor     edx, edx
.bsys_enc:
    cmp     edx, ecx
    jge     .bsys_result
    movzx   eax, byte ptr [rsi + rdx]
    mov     word ptr [rdi + rdx*2], ax
    inc     edx
    jmp     .bsys_enc
.bsys_result:
    sub     r14, 16
    mov     [r14], rdi
    mov     [r14+8], rcx
    DISPATCH
.bsys_empty:
    sub     r14, 16
    xor     eax, eax
    mov     [r14], rax
    mov     qword ptr [r14+8], 0
    DISPATCH
.bsys_child:
    # Child: close read end, dup write end to stdout
    mov     edi, r8d
    mov     eax, SYS_CLOSE
    syscall
    # dup2(write_end, 1) = stdout
    mov     edi, r9d
    mov     esi, 1
    mov     eax, 33                  # SYS_dup2
    syscall
    # dup2(write_end, 2) = stderr
    mov     edi, r9d
    mov     esi, 2
    mov     eax, 33
    syscall
    # Close original write fd
    mov     edi, r9d
    mov     eax, SYS_CLOSE
    syscall
    # exec /bin/sh -c "cmd"
    sub     rsp, 40                  # argv on stack
    lea     rax, [rip + str_bin_sh]
    mov     [rsp], rax               # argv[0] = "/bin/sh"
    lea     rax, [rip + str_dash_c]
    mov     [rsp+8], rax             # argv[1] = "-c"
    mov     [rsp+16], r15            # argv[2] = cmd (decoded earlier, still at r15)
    mov     qword ptr [rsp+24], 0    # argv[3] = NULL
    lea     rdi, [rip + str_bin_sh]  # path
    lea     rsi, [rsp]               # argv
    xor     edx, edx                 # envp = NULL
    mov     eax, 59                  # SYS_execve
    syscall
    # If exec fails, exit child
    mov     eax, SYS_EXIT
    mov     edi, 1
    syscall

# __str_index_of(haystack, needle) → index or -1
.builtin_str_index_of:
    mov     r8, [r14]                # needle ptr
    mov     r9, [r14+8]              # needle len
    mov     rsi, [r14+16]            # haystack ptr
    mov     rdx, [r14+24]            # haystack len
    add     r14, 32
    test    r9, r9
    jz      .bsio_nf                 # empty needle → -1
    cmp     r9, rdx
    jg      .bsio_nf                 # needle longer → -1
    xor     ecx, ecx                 # scan position
.bsio_scan:
    lea     rax, [rcx + r9]
    cmp     rax, rdx
    jg      .bsio_nf                 # not enough chars left
    # Compare needle at position ecx
    xor     edi, edi
.bsio_cmp:
    cmp     rdi, r9
    jge     .bsio_found
    lea     rax, [rcx + rdi]
    movzx   eax, word ptr [rsi + rax*2]
    movzx   r10d, word ptr [r8 + rdi*2]
    cmp     eax, r10d
    jne     .bsio_next
    inc     rdi
    jmp     .bsio_cmp
.bsio_found:
    cvtsi2sd xmm0, ecx
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH
.bsio_next:
    inc     ecx
    jmp     .bsio_scan
.bsio_nf:
    sub     r14, 16
    mov     rax, -1
    cvtsi2sd xmm0, rax
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __bit_shl(a, n) → a << n
.builtin_bit_shl:
    movsd   xmm0, [r14]             # n
    cvttsd2si ecx, xmm0
    movsd   xmm0, [r14+16]          # a
    cvttsd2si rax, xmm0
    add     r14, 16
    shl     rax, cl
    cvtsi2sd xmm0, rax
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __bit_shr(a, n) → a >> n (logical)
.builtin_bit_shr:
    movsd   xmm0, [r14]
    cvttsd2si ecx, xmm0
    movsd   xmm0, [r14+16]
    cvttsd2si rax, xmm0
    add     r14, 16
    shr     rax, cl
    cvtsi2sd xmm0, rax
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __file_append(path, content) → 0
.builtin_file_append:
    mov     r8, [r14]                # content ptr
    mov     r9, [r14+8]              # content len
    mov     rsi, [r14+16]            # path ptr
    mov     rdx, [r14+24]            # path len
    add     r14, 32
    # Decode path
    mov     rdi, r15
    xor     ecx, ecx
.bfa_dp:
    cmp     ecx, edx
    jge     .bfa_open
    movzx   eax, word ptr [rsi + rcx*2]
    mov     byte ptr [rdi + rcx], al
    inc     ecx
    jmp     .bfa_dp
.bfa_open:
    mov     byte ptr [rdi + rcx], 0
    mov     rdi, r15
    mov     esi, 0x441               # O_WRONLY|O_CREAT|O_APPEND
    mov     edx, 0x1A4              # 0644
    mov     eax, SYS_OPEN
    syscall
    test    eax, eax
    js      .bfa_done
    mov     edi, eax
    # Decode content
    lea     rsi, [r15 + 4096]
    xor     ecx, ecx
.bfa_dc:
    cmp     rcx, r9
    jge     .bfa_write
    movzx   eax, word ptr [r8 + rcx*2]
    mov     byte ptr [rsi + rcx], al
    inc     ecx
    jmp     .bfa_dc
.bfa_write:
    mov     rdx, rcx
    lea     rsi, [r15 + 4096]
    mov     eax, SYS_WRITE
    syscall
    mov     eax, SYS_CLOSE
    syscall
.bfa_done:
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __array_with_cap(capacity) → array with pre-allocated capacity
.builtin_array_with_cap:
    movsd   xmm0, [r14]
    cvttsd2si edi, xmm0
    add     r14, 16
    # Allocate: [capacity:8][count:8][entries...]
    mov     rax, r15
    mov     [r15], rdi               # capacity
    mov     qword ptr [r15+8], 0     # count = 0
    shl     rdi, 4                   # entries space = cap × 16
    add     rdi, 16                  # + header
    add     r15, rdi
    sub     r14, 16
    mov     [r14], rax
    mov     qword ptr [r14+8], ARRAY_MARKER
    DISPATCH

# __write_raw(string) → write bytes to stdout without newline
.builtin_write_raw:
    mov     rsi, [r14]
    mov     rdx, [r14+8]
    add     r14, 16
    # Decode u16 → bytes
    mov     rdi, r15
    xor     ecx, ecx
.bwr_dec:
    cmp     ecx, edx
    jge     .bwr_write
    movzx   eax, word ptr [rsi + rcx*2]
    mov     byte ptr [rdi + rcx], al
    inc     ecx
    jmp     .bwr_dec
.bwr_write:
    mov     rdx, rcx
    mov     rsi, r15
    mov     edi, 1
    mov     eax, SYS_WRITE
    syscall
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# type_of(value) → string describing type
.builtin_type_of:
    mov     rdx, [r14+8]            # len/marker
    add     r14, 16
    sub     r14, 16
    cmp     rdx, F64_MARKER
    je      .bto_num
    cmp     rdx, ARRAY_MARKER
    je      .bto_arr
    cmp     rdx, CLOSURE_MARKER
    je      .bto_fn
    cmp     rdx, MOL_MARKER
    je      .bto_mol
    cmp     rdx, DICT_MARKER
    je      .bto_dict
    # String (len >= 0)
    test    rdx, rdx
    js      .bto_num                 # negative marker we don't know → treat as number
    lea     rax, [rip + str_type_string]
    mov     [r14], rax
    mov     qword ptr [r14+8], 6
    DISPATCH
.bto_dict:
    lea     rax, [rip + str_type_dict]
    mov     [r14], rax
    mov     qword ptr [r14+8], 4     # "dict" = 4 chars
    DISPATCH
.bto_num:
    lea     rax, [rip + str_type_number]
    mov     [r14], rax
    mov     qword ptr [r14+8], 6
    DISPATCH
.bto_arr:
    lea     rax, [rip + str_type_array]
    mov     [r14], rax
    mov     qword ptr [r14+8], 5
    DISPATCH
.bto_fn:
    lea     rax, [rip + str_type_function]
    mov     [r14], rax
    mov     qword ptr [r14+8], 8
    DISPATCH
.bto_mol:
    lea     rax, [rip + str_type_molecule]
    mov     [r14], rax
    mov     qword ptr [r14+8], 8
    DISPATCH

# ── Additional builtins ──

# pop(array) → removed last element
.builtin_pop_arr:
    mov     rax, [r14]
    mov     rdx, [r14+8]
    add     r14, 16
    cmp     rdx, ARRAY_MARKER
    jne     .bpop_nop
    mov     rcx, [rax+8]
    test    rcx, rcx
    jz      .bpop_nop
    dec     rcx
    mov     [rax+8], rcx
    push    rcx
    shl     rcx, 4
    lea     rsi, [rax + 16 + rcx]
    pop     rcx
    sub     r14, 16
    mov     rdx, [rsi]
    mov     rdi, [rsi+8]
    mov     [r14], rdx
    mov     [r14+8], rdi
    DISPATCH
.bpop_nop:
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# range(start, end) → array
.builtin_range:
    movsd   xmm0, [r14]
    cvttsd2si esi, xmm0
    movsd   xmm0, [r14+16]
    cvttsd2si edi, xmm0
    add     r14, 32
    mov     ecx, esi
    sub     ecx, edi
    test    ecx, ecx
    jle     .brange_empty
    mov     rax, r15
    mov     [r15], rcx
    mov     [r15+8], rcx
    add     r15, 16
    xor     edx, edx
.brange_fill:
    cmp     edx, ecx
    jge     .brange_done
    mov     eax, edi
    add     eax, edx
    cvtsi2sd xmm0, eax
    movsd   [r15], xmm0
    mov     qword ptr [r15+8], F64_MARKER
    add     r15, 16
    inc     edx
    jmp     .brange_fill
.brange_done:
    mov     ecx, esi
    sub     ecx, edi
    shl     ecx, 4
    add     ecx, 16
    mov     rax, r15
    sub     rax, rcx
    sub     r14, 16
    mov     [r14], rax
    mov     qword ptr [r14+8], ARRAY_MARKER
    DISPATCH
.brange_empty:
    mov     rax, r15
    mov     qword ptr [r15], 0
    mov     qword ptr [r15+8], 0
    add     r15, 16
    sub     r14, 16
    mov     [r14], rax
    mov     qword ptr [r14+8], ARRAY_MARKER
    DISPATCH

# __array_new(elem0, elem1, ..., count) → array
# Stack: [count] [elemN-1] ... [elem0] (count on top)
.builtin_array_new:
    movsd   xmm0, [r14]
    cvttsd2si ecx, xmm0            # count
    add     r14, 16                 # pop count
    # Allocate array: [capacity:8][count:8][entries...]
    mov     rax, r15                # array ptr
    mov     edx, ecx
    cmp     edx, 8
    cmovl   edx, ecx
    mov     edi, 8                  # min capacity = 8
    cmp     edx, edi
    cmovg   edi, edx
    mov     [r15], rdi              # capacity
    mov     [r15 + 8], rcx         # count
    add     r15, 16
    # Copy elements from stack (they're in reverse order)
    test    ecx, ecx
    jz      .ban_done
    # Elements on stack: top = last pushed = elemN-1
    # Array wants: [0]=elem0, [1]=elem1, ...
    # Stack has: [r14]=elemN-1, [r14+16]=elemN-2, ..., [r14+(N-1)*16]=elem0
    mov     edx, ecx
    dec     edx                     # edx = N-1
.ban_copy:
    cmp     edx, 0
    jl      .ban_done
    # Copy stack[edx] to array[N-1-edx]
    mov     esi, ecx
    dec     esi
    sub     esi, edx                # array index = N-1-edx
    # Stack entry at r14 + edx*16
    push    rdx
    shl     edx, 4
    mov     rdi, [r14 + rdx]       # ptr
    mov     r8, [r14 + rdx + 8]    # len
    pop     rdx
    push    rdx
    mov     edx, esi
    shl     edx, 4
    mov     [r15 + rdx], rdi       # array[idx].ptr
    mov     [r15 + rdx + 8], r8    # array[idx].len
    pop     rdx
    dec     edx
    jmp     .ban_copy
.ban_done:
    # Advance heap past entries
    mov     edx, ecx
    shl     edx, 4
    add     r15, rdx
    # Pop all elements from stack
    shl     ecx, 4
    add     r14, rcx
    # Push array
    sub     r14, 16
    mov     [r14], rax
    mov     qword ptr [r14 + 8], ARRAY_MARKER
    DISPATCH

# Stub builtins
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

# __file_append_bytes(path, byte_array) → write raw bytes to file (append mode)
.builtin_file_append_bytes:
    movabs  rdx, 0xECE98A081C4642C2   # hash of __file_append_bytes
    cmp     rdx, rax
    jne     .builtin_f64_to_le_bytes
    # Pop byte_array, then path
    mov     r8, [r14]                # array ptr
    # Follow forward pointers
.bfab_fwd:
    cmp     qword ptr [r8], -2       # ARRAY_FORWARD?
    jne     .bfab_nofwd
    mov     r8, [r8 + 8]
    jmp     .bfab_fwd
.bfab_nofwd:
    mov     rsi, [r14 + 16]          # path ptr
    mov     rdx, [r14 + 24]          # path mol_count
    add     r14, 32
    # Decode path (u16 → bytes)
    mov     rdi, r15
    xor     ecx, ecx
.bfab_dp:
    cmp     ecx, edx
    jge     .bfab_open
    movzx   eax, word ptr [rsi + rcx*2]
    mov     byte ptr [rdi + rcx], al
    inc     ecx
    jmp     .bfab_dp
.bfab_open:
    mov     byte ptr [rdi + rcx], 0   # null terminate
    push    r8                        # save array ptr
    mov     rdi, r15
    mov     esi, 0x441                # O_WRONLY|O_CREAT|O_APPEND
    mov     edx, 0x1ED                # 0755
    mov     eax, SYS_OPEN
    syscall
    test    eax, eax
    js      .bfab_done
    mov     edi, eax                  # fd
    pop     r8                        # array ptr
    # Get array count
    mov     rcx, [r8 + 8]            # count (at offset 8 for cap-tracked)
    # Convert array elements (f64 byte values) to raw bytes
    lea     rsi, [r15 + 4096]         # output buffer
    xor     r9d, r9d                  # index
.bfab_convert:
    cmp     r9, rcx
    jge     .bfab_write
    # Array entry: [ptr:8][len:8] at offset 16 + index*16
    mov     r10, r9
    shl     r10, 4                    # index * 16
    add     r10, 16                   # skip header (cap+count)
    movsd   xmm0, qword ptr [r8 + r10]  # f64 bits
    cvttsd2si eax, xmm0              # byte value
    mov     byte ptr [rsi + r9], al
    inc     r9
    jmp     .bfab_convert
.bfab_write:
    mov     rdx, r9                   # byte count
    lea     rsi, [r15 + 4096]
    mov     eax, SYS_WRITE
    syscall
    # Close
    mov     eax, SYS_CLOSE
    syscall
    jmp     .bfab_ret
.bfab_done:
    pop     r8
.bfab_ret:
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __f64_to_le_bytes(f64_value) → array of 8 byte values
.builtin_f64_to_le_bytes:
    movabs  rdx, 0x7DC336EFBBA1F85B
    cmp     rdx, rax
    jne     .call_not_builtin
    # Pop f64 value
    mov     rax, [r14]               # f64 bits (stored as ptr)
    add     r14, 16
    # Build array: [capacity:8][count:8][byte0:16][byte1:16]...[byte7:16]
    mov     rdi, r15                 # array base
    mov     qword ptr [r15], 8      # capacity = 8
    mov     qword ptr [r15 + 8], 8  # count = 8
    add     r15, 16
    # Extract each byte from f64 bits (little-endian)
    mov     rcx, 8
.f2b_loop:
    movzx   edx, al                  # low byte
    # Store as f64 value in array entry [ptr:8][len:8]
    sub     rsp, 8
    cvtsi2sd xmm0, rdx
    movsd   [rsp], xmm0
    mov     rdx, [rsp]
    add     rsp, 8
    mov     [r15], rdx               # f64 bits of byte value
    mov     qword ptr [r15 + 8], F64_MARKER
    add     r15, 16
    shr     rax, 8                   # next byte
    dec     rcx
    jnz     .f2b_loop
    # Push array
    sub     r14, 16
    mov     [r14], rdi
    mov     qword ptr [r14 + 8], ARRAY_MARKER
    DISPATCH

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
    mov     rax, [r14]              # ptr field
    mov     rdx, [r14 + 8]          # len field
    cmp     rdx, F64_MARKER
    je      .blen_num
    cmp     rdx, ARRAY_MARKER
    je      .blen_array
    # String: len = mol count
    add     r14, 16
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
    # rax = array heap ptr (read before branch, not popped yet)
    # Follow forward pointers
.blen_fwd:
    cmp     qword ptr [rax], -2      # ARRAY_FORWARD?
    jne     .blen_nofwd
    mov     rax, [rax + 8]
    jmp     .blen_fwd
.blen_nofwd:
    add     r14, 16                 # pop now
    mov     rcx, [rax + 8]          # count (at offset 8, after capacity)
    sub     r14, 16
    cvtsi2sd xmm0, rcx
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
    # Bounds check: clamp start ≥ 0
    test    edi, edi
    jns     .bsub_start_ok
    xor     edi, edi
.bsub_start_ok:
    # Clamp end ≤ len
    cmp     esi, edx
    cmovg   esi, edx
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
    # Follow forward pointers
.bpush_fwd:
    cmp     qword ptr [rax], -2     # ARRAY_FORWARD?
    jne     .bpush_nofwd
    mov     rax, [rax + 8]
    jmp     .bpush_fwd
.bpush_nofwd:
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
    # rax = old array ptr, r8 = val.ptr, r9 = val.len, rdx = old capacity
    shl     rdx, 1                  # new capacity = 2×
    test    rdx, rdx
    jnz     .bpush_have_cap
    mov     rdx, 8                  # minimum capacity
.bpush_have_cap:
    # Save old array ptr for forward pointer
    mov     [rip + _push_old_arr], rax
    # Allocate new array on heap
    mov     rdi, rdx                # new capacity
    shl     rdi, 4
    add     rdi, 16                 # total bytes = cap*16 + 16 (header)
    mov     rsi, r15                # new array base
    add     r15, rdi                # bump allocate
    # Initialize new array header
    mov     [rsi], rdx              # new capacity
    mov     rax, [rip + _push_old_arr]
    mov     rcx, [rax + 8]          # old count
    mov     [rsi + 8], rcx          # copy count
    # Copy old entries
    push    rcx
    push    rsi
    lea     rdi, [rsi + 16]         # dest = new entries start
    mov     rax, [rip + _push_old_arr]
    lea     rax, [rax + 16]         # src = old entries start
    mov     rsi, rax                # rep movsb source
    shl     ecx, 4                  # byte count = old_count × 16
    rep     movsb
    pop     rsi                     # rsi = new array base
    pop     rcx                     # rcx = old count
    # Append new element at position [count]
    mov     rax, rcx
    shl     rax, 4
    mov     [rsi + 16 + rax], r8    # val.ptr
    mov     [rsi + 16 + rax + 8], r9 # val.len
    inc     qword ptr [rsi + 8]     # count++
    # Write FORWARD POINTER at old array location
    mov     rax, [rip + _push_old_arr]
    mov     qword ptr [rax], -2     # ARRAY_FORWARD marker
    mov     [rax + 8], rsi          # pointer to new array
    # Push new array
    sub     r14, 16
    mov     [r14], rsi
    mov     qword ptr [r14 + 8], ARRAY_MARKER
    DISPATCH

# __array_get(array, index) → value
.builtin_array_get:
    movsd   xmm0, [r14]            # index
    cvttsd2si edi, xmm0
    mov     rax, [r14+16]           # array ptr
    add     r14, 32                 # pop 2
    # Follow forward pointers
.bag_fwd:
    cmp     qword ptr [rax], -2
    jne     .bag_nofwd
    mov     rax, [rax + 8]
    jmp     .bag_fwd
.bag_nofwd:
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
    # Follow forward pointers
.bsa_fwd:
    cmp     qword ptr [rax], -2
    jne     .bsa_nofwd
    mov     rax, [rax + 8]
    jmp     .bsa_fwd
.bsa_nofwd:
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
# §45-§50 BRAIN BUILTINS (Session 17)
# ═══════════════════════════════════════════════════════════════════════════

# ── Activation Matrix builtins ──

# __act_set(mol, value) — set activation level
.builtin_act_set:
    movsd   xmm0, [r14+16]          # mol
    cvttsd2si edi, xmm0
    movsd   xmm0, [r14]             # value
    cvttsd2si esi, xmm0
    add     r14, 32
    call    act_set
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __act_get(mol) → activation value
.builtin_act_get:
    movsd   xmm0, [r14]
    cvttsd2si edi, xmm0
    add     r14, 16
    call    act_get
    cvtsi2sd xmm0, eax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __act_add(mol, delta) — add to activation
.builtin_act_add:
    movsd   xmm0, [r14+16]          # mol
    cvttsd2si edi, xmm0
    movsd   xmm0, [r14]             # delta
    cvttsd2si esi, xmm0
    add     r14, 32
    call    act_add
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __act_decay(factor) — decay all activations by factor/1000
.builtin_act_decay:
    movsd   xmm0, [r14]
    cvttsd2si edi, xmm0
    add     r14, 16
    call    act_decay_all
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __act_reset() — clear all activations
.builtin_act_reset:
    call    act_reset
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __act_top_k(k) → array of [mol, activation] pairs
.builtin_act_top_k:
    movsd   xmm0, [r14]
    cvttsd2si r8d, xmm0             # k
    add     r14, 16
    cmp     r8d, 32
    jle     .atk_ok
    mov     r8d, 32
.atk_ok:
    # Allocate result array
    mov     r10, r15
    mov     qword ptr [r15], 64      # capacity
    mov     qword ptr [r15+8], 0     # count
    lea     r15, [r15 + 16 + 64*16]  # header + max entries
    # Linear scan act_matrix, maintain top-k by simple insertion
    lea     rsi, [rip + act_matrix]
    xor     ecx, ecx                 # mol index
    xor     r9d, r9d                 # current count
.atk_scan:
    cmp     ecx, 65536
    jge     .atk_done
    movzx   eax, word ptr [rsi + rcx*2]
    test    eax, eax
    jz      .atk_next
    # Found non-zero activation — insert into result if top-k
    cmp     r9d, r8d
    jl      .atk_insert              # still room
    # Check if better than worst in result
    mov     edx, r9d
    dec     edx
    shl     edx, 5                   # ×32 (2 entries ×16 bytes each)
    movsd   xmm1, [r10 + 16 + rdx + 16] # last activation
    cvttsd2si edi, xmm1
    cmp     eax, edi
    jle     .atk_next                # not better
    dec     r9d                      # replace last
.atk_insert:
    mov     edx, r9d
    shl     edx, 5                   # offset for pair
    # Store mol
    cvtsi2sd xmm0, ecx
    movsd   [r10 + 16 + rdx], xmm0
    mov     qword ptr [r10 + 16 + rdx + 8], F64_MARKER
    # Store activation
    cvtsi2sd xmm0, eax
    movsd   [r10 + 16 + rdx + 16], xmm0
    mov     qword ptr [r10 + 16 + rdx + 24], F64_MARKER
    inc     r9d
    shl     r9d, 1                   # count = pairs ×2
    mov     [r10+8], r9              # update count
    shr     r9d, 1
.atk_next:
    inc     ecx
    jmp     .atk_scan
.atk_done:
    sub     r14, 16
    mov     [r14], r10
    mov     qword ptr [r14+8], ARRAY_MARKER
    DISPATCH

# ── Working Memory builtins ──

# __wm_bind(slot, mol) — set WM slot (0-3)
.builtin_wm_bind:
    movsd   xmm0, [r14+16]          # slot
    cvttsd2si edi, xmm0
    movsd   xmm0, [r14]             # mol
    cvttsd2si esi, xmm0
    add     r14, 32
    and     edi, 3
    lea     rax, [rip + wm_slots]
    mov     word ptr [rax + rdi*2], si
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __wm_read(slot) → mol value
.builtin_wm_read:
    movsd   xmm0, [r14]
    cvttsd2si edi, xmm0
    add     r14, 16
    and     edi, 3
    lea     rax, [rip + wm_slots]
    movzx   eax, word ptr [rax + rdi*2]
    cvtsi2sd xmm0, eax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __wm_clear() — zero all 4 WM slots
.builtin_wm_clear:
    lea     rax, [rip + wm_slots]
    mov     qword ptr [rax], 0
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# ── STM builtins ──

# __stm_push(mol, text) — push to STM (max 32)
.builtin_stm_push:
    mov     r8, [r14]                # text ptr
    mov     r9, [r14+8]              # text len
    movsd   xmm0, [r14+16]          # mol
    cvttsd2si edi, xmm0
    add     r14, 32
    # Get current count
    lea     rsi, [rip + stm_count]
    mov     ecx, [rsi]
    cmp     ecx, 32
    jge     .stp_evict
    jmp     .stp_store
.stp_evict:
    # Simple: overwrite oldest (slot 0), shift down
    # For simplicity, just wrap to slot (count % 32)
    mov     ecx, 31                  # use last slot
.stp_store:
    lea     rax, [rip + stm_entries]
    imul    edx, ecx, 48             # offset = slot × 48
    mov     word ptr [rax + rdx], di # mol
    mov     [rax + rdx + 8], r8      # text_ptr
    mov     [rax + rdx + 16], r9     # text_len
    # Timestamp = heap_used (rough proxy)
    mov     rsi, r15
    sub     rsi, [rip + heap_base]
    mov     [rax + rdx + 32], rsi    # timestamp
    mov     qword ptr [rax + rdx + 40], 0 # access_count
    # Update count
    lea     rsi, [rip + stm_count]
    mov     ecx, [rsi]
    cmp     ecx, 32
    jge     .stp_no_inc
    inc     ecx
    mov     [rsi], ecx
.stp_no_inc:
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __stm_query(mol) → nearest STM text (by mol distance)
.builtin_stm_query:
    movsd   xmm0, [r14]
    cvttsd2si ebp, xmm0              # query mol
    add     r14, 16
    push    rbx
    push    rbp
    lea     rsi, [rip + stm_entries]
    mov     ecx, [rip + stm_count]
    test    ecx, ecx
    jz      .stq_empty
    xor     r8d, r8d                 # best_idx
    mov     r9d, 0x7FFFFFFF          # best_dist
    xor     edx, edx                 # i
.stq_loop:
    cmp     edx, ecx
    jge     .stq_found
    push    rcx
    push    rdx
    push    rsi
    imul    eax, edx, 48
    movzx   edi, word ptr [rsi + rax] # stm mol
    mov     esi, ebp                  # query mol
    call    mol_dist_inline
    pop     rsi
    pop     rdx
    pop     rcx
    cmp     eax, r9d
    jge     .stq_next
    mov     r9d, eax
    mov     r8d, edx
.stq_next:
    inc     edx
    jmp     .stq_loop
.stq_found:
    # Return text from best entry
    imul    eax, r8d, 48
    mov     rax, [rsi + rax + 8]     # text_ptr
    mov     rdx, [rsi + r8*1 + 16]   # text_len — WRONG, fix:
    imul    r8d, r8d, 48
    mov     rdx, [rsi + r8 + 16]
    sub     r14, 16
    mov     [r14], rax
    mov     [r14+8], rdx
    pop     rbp
    pop     rbx
    DISPATCH
.stq_empty:
    sub     r14, 16
    xor     eax, eax
    mov     [r14], rax
    mov     qword ptr [r14+8], 0
    pop     rbp
    pop     rbx
    DISPATCH

# __stm_count() → number of STM entries
.builtin_stm_count:
    mov     eax, [rip + stm_count]
    cvtsi2sd xmm0, eax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# ── Pipeline builtins ──

# __pseudo_select(mol, gen, max) → deterministic pseudo-random
.builtin_pseudo_select:
    movsd   xmm0, [r14+32]          # mol
    cvttsd2si eax, xmm0
    movsd   xmm0, [r14+16]          # gen
    cvttsd2si ecx, xmm0
    movsd   xmm0, [r14]             # max
    cvttsd2si edx, xmm0
    add     r14, 48
    # result = (mol × 2654435761 + gen × 40503) % max
    imul    eax, 0x9E3779B1          # Fibonacci hash
    imul    ecx, 40503
    add     eax, ecx
    # mod max
    test    edx, edx
    jz      .ps_zero
    push    rdx
    xor     edx, edx
    pop     rcx
    div     ecx                      # edx = remainder
    mov     eax, edx
    jmp     .ps_done
.ps_zero:
    xor     eax, eax
.ps_done:
    cvtsi2sd xmm0, eax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __chain_quality(chain_arr, query_mol) → quality 0-1000
.builtin_chain_quality:
    movsd   xmm0, [r14]             # query_mol
    cvttsd2si ebp, xmm0
    mov     rax, [r14+16]            # chain array ptr
    add     r14, 32
    push    rbx
    push    rbp
    # Follow forward pointers
.cq_fwd:
    cmp     qword ptr [rax], -2
    jne     .cq_nofwd
    mov     rax, [rax + 8]
    jmp     .cq_fwd
.cq_nofwd:
    mov     rcx, [rax+8]            # count
    test    rcx, rcx
    jz      .cq_zero
    # Validity: all mols non-zero
    mov     r8d, 0                   # valid_count
    mov     r9d, 0                   # total dist
    xor     edx, edx
.cq_valid:
    cmp     edx, ecx
    jge     .cq_score
    shl     edx, 4
    movsd   xmm0, [rax + 16 + rdx]
    cvttsd2si esi, xmm0
    shr     edx, 4
    test    esi, esi
    jz      .cq_v_next
    inc     r8d
    # Distance to query
    push    rax
    push    rcx
    push    rdx
    mov     edi, esi
    mov     esi, ebp
    call    mol_dist_inline
    add     r9d, eax
    pop     rdx
    pop     rcx
    pop     rax
.cq_v_next:
    inc     edx
    jmp     .cq_valid
.cq_score:
    # validity = valid_count × 1000 / count
    imul    r8d, 1000
    push    rdx
    mov     eax, r8d
    xor     edx, edx
    div     ecx
    mov     r8d, eax                 # validity
    pop     rdx
    # affinity = 1000 - avg_dist × 1000 / 70
    mov     eax, r9d
    test    ecx, ecx
    jz      .cq_no_aff
    push    rdx
    xor     edx, edx
    div     ecx                      # avg dist
    imul    eax, 1000
    mov     ecx, 70
    xor     edx, edx
    div     ecx
    pop     rdx
    mov     r9d, 1000
    sub     r9d, eax
    test    r9d, r9d
    cmovs   r9d, edx                 # clamp to 0
.cq_no_aff:
    # quality = (300×validity + 400×affinity + 300×consistency) / 1000
    # Simplified: (validity + affinity) / 2
    add     r8d, r9d
    shr     r8d, 1
    cvtsi2sd xmm0, r8d
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    pop     rbp
    pop     rbx
    DISPATCH
.cq_zero:
    xorpd   xmm0, xmm0
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    pop     rbp
    pop     rbx
    DISPATCH

# __mol_dominant(mol) → dominant dimension (0=S,1=R,2=V,3=A,4=T)
.builtin_mol_dominant:
    movsd   xmm0, [r14]
    cvttsd2si eax, xmm0
    add     r14, 16
    # Extract dimensions, find largest
    mov     ecx, eax
    shr     ecx, 12
    and     ecx, 0xF                 # S
    mov     edx, eax
    shr     edx, 8
    and     edx, 0xF                 # R
    mov     esi, eax
    shr     esi, 5
    and     esi, 0x7                 # V (scale ×2)
    shl     esi, 1
    mov     edi, eax
    shr     edi, 2
    and     edi, 0x7                 # A (scale ×2)
    shl     edi, 1
    mov     r8d, eax
    and     r8d, 0x3                 # T (scale ×4)
    shl     r8d, 2
    # Find max
    xor     eax, eax                 # result dim = 0 (S)
    mov     r9d, ecx                 # max = S
    cmp     edx, r9d
    jle     .md_v
    mov     eax, 1
    mov     r9d, edx
.md_v:
    cmp     esi, r9d
    jle     .md_a
    mov     eax, 2
    mov     r9d, esi
.md_a:
    cmp     edi, r9d
    jle     .md_t
    mov     eax, 3
    mov     r9d, edi
.md_t:
    cmp     r8d, r9d
    jle     .md_done
    mov     eax, 4
.md_done:
    cvtsi2sd xmm0, eax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# ── Conversation Curve builtins ──

# __v_push(v) — push valence to history ring buffer
.builtin_v_push:
    movsd   xmm0, [r14]
    cvttsd2si eax, xmm0
    add     r14, 16
    lea     rcx, [rip + v_history]
    movzx   edx, byte ptr [rip + v_history_ptr]
    and     edx, 7                   # wrap at 8
    mov     byte ptr [rcx + rdx], al
    inc     edx
    mov     byte ptr [rip + v_history_ptr], dl
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __conv_tone() → tone (0-5: ENGAGED/SUPPORTIVE/PAUSE/REINFORCING/CELEBRATORY/GENTLE)
.builtin_conv_tone:
    lea     rcx, [rip + v_history]
    movzx   edx, byte ptr [rip + v_history_ptr]
    # V' = V[last] - V[last-1]
    mov     eax, edx
    dec     eax
    and     eax, 7
    movzx   esi, byte ptr [rcx + rax] # V(t)
    mov     eax, edx
    sub     eax, 2
    and     eax, 7
    movzx   edi, byte ptr [rcx + rax] # V(t-1)
    sub     esi, edi                   # V' = V(t) - V(t-1)
    # V'' = V'(t) - V'(t-1)
    mov     eax, edx
    sub     eax, 3
    and     eax, 7
    movzx   r8d, byte ptr [rcx + rax] # V(t-2)
    mov     r9d, edi
    sub     r9d, r8d                   # V'(t-1)
    mov     eax, esi
    sub     eax, r9d                   # V'' = V'(t) - V'(t-1)
    # Tone selection
    xor     edx, edx                   # default ENGAGED(0)
    cmp     esi, -1
    jg      .ct_check_pause
    mov     edx, 1                     # SUPPORTIVE (V' < -1)
    jmp     .ct_result
.ct_check_pause:
    cmp     eax, -2
    jg      .ct_check_reinforce
    mov     edx, 2                     # PAUSE (V'' < -2)
    jmp     .ct_result
.ct_check_reinforce:
    cmp     esi, 1
    jl      .ct_check_celebrate
    mov     edx, 3                     # REINFORCING (V' > 1)
    jmp     .ct_result
.ct_check_celebrate:
    cmp     eax, 2
    jl      .ct_check_gentle
    # Also check V(t) > 4
    mov     eax, edx
    dec     eax
    and     eax, 7
    movzx   edi, byte ptr [rcx + rax]
    cmp     edi, 4
    jle     .ct_check_gentle
    mov     edx, 4                     # CELEBRATORY
    jmp     .ct_result
.ct_check_gentle:
    movzx   edi, byte ptr [rcx]       # use slot 0 as proxy for current V
    cmp     edi, 2
    jg      .ct_result
    mov     edx, 5                     # GENTLE
.ct_result:
    cvtsi2sd xmm0, edx
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __homeostasis(predicted_mol, actual_mol) → free energy F (0-1000)
.builtin_homeostasis:
    movsd   xmm0, [r14+16]          # predicted
    cvttsd2si edi, xmm0
    movsd   xmm0, [r14]             # actual
    cvttsd2si esi, xmm0
    add     r14, 32
    call    mol_dist_inline          # eax = distance
    # F = distance × 1000 / 70 (normalize to 0-1000)
    imul    eax, 1000
    push    rdx
    xor     edx, edx
    mov     ecx, 70
    div     ecx
    pop     rdx
    cmp     eax, 1000
    jle     .ho_ok
    mov     eax, 1000
.ho_ok:
    cvtsi2sd xmm0, eax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# ── Silk enhanced builtins ──

# __silk_weight(mol_a, mol_b) → edge weight (0-65535)
.builtin_silk_weight:
    movsd   xmm0, [r14+16]          # mol_a
    cvttsd2si eax, xmm0
    movsd   xmm0, [r14]             # mol_b
    cvttsd2si ecx, xmm0
    add     r14, 32
    # Symmetric hash
    mov     edx, eax
    xor     edx, ecx
    imul    edx, 0x9E37
    mov     esi, eax
    add     esi, ecx
    add     edx, esi
    and     edx, 0xFFFF
    lea     rdi, [rip + silk_matrix]
    movzx   eax, word ptr [rdi + rdx*2]
    cvtsi2sd xmm0, eax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __silk_classify(mol) → branch_id (S×16 + R)
.builtin_silk_classify:
    movsd   xmm0, [r14]
    cvttsd2si eax, xmm0
    add     r14, 16
    mov     ecx, eax
    shr     ecx, 12
    and     ecx, 0xF                 # S
    mov     edx, eax
    shr     edx, 8
    and     edx, 0xF                 # R
    shl     ecx, 4
    add     ecx, edx                 # branch = S×16 + R
    cvtsi2sd xmm0, ecx
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# ── Security builtins ──

# __bloom_check(mol) → 1 if in bloom filter, 0 if not
.builtin_bloom_check:
    movsd   xmm0, [r14]
    cvttsd2si eax, xmm0
    add     r14, 16
    # 3 hash functions for bloom filter
    lea     rcx, [rip + bloom_filter]
    # h1 = mol & 0xFFFF
    mov     edx, eax
    and     edx, 0xFFFF
    shr     edx, 3                   # byte index
    mov     esi, eax
    and     esi, 7                   # bit index
    bt      dword ptr [rcx + rdx], esi
    jnc     .bc_no
    # h2 = (mol × 0x9E37) & 0xFFFF
    imul    edx, eax, 0x9E37
    and     edx, 0xFFFF
    shr     edx, 3
    mov     esi, edx
    imul    esi, eax, 0x9E37
    and     esi, 7
    bt      dword ptr [rcx + rdx], esi
    jnc     .bc_no
    # All hashes present → probably in set
    mov     eax, 1
    jmp     .bc_push
.bc_no:
    xor     eax, eax
.bc_push:
    cvtsi2sd xmm0, eax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __negative_mark(mol) — add to bloom filter (mark as prohibited)
.builtin_negative_mark:
    movsd   xmm0, [r14]
    cvttsd2si eax, xmm0
    add     r14, 16
    lea     rcx, [rip + bloom_filter]
    # h1
    mov     edx, eax
    and     edx, 0xFFFF
    shr     edx, 3
    mov     esi, eax
    and     esi, 7
    bts     dword ptr [rcx + rdx], esi
    # h2
    imul    edx, eax, 0x9E37
    and     edx, 0xFFFF
    shr     edx, 3
    mov     esi, edx
    imul    esi, eax, 0x9E37
    and     esi, 7
    bts     dword ptr [rcx + rdx], esi
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# ── String/Chain builtins ──

# __str_split(text, delim_char) → array of strings
# Splits u16 molecule string by delimiter codepoint
.builtin_str_split:
    movsd   xmm0, [r14]             # delim (as char code)
    cvttsd2si r8d, xmm0
    mov     rsi, [r14+16]            # text ptr
    mov     rdx, [r14+24]            # text len (mol count)
    add     r14, 32
    push    rbx
    push    rbp
    mov     ebp, r8d                 # ebp = delimiter (preserved)
    # Allocate result array
    mov     r10, r15
    mov     qword ptr [r15], 32
    mov     qword ptr [r15+8], 0
    lea     r15, [r15 + 16 + 32*16]
    xor     ecx, ecx                 # i = 0
    xor     r11d, r11d               # start = 0
    xor     r9d, r9d                 # count = 0
.ss_loop:
    cmp     ecx, edx
    jg      .ss_done
    je      .ss_emit_last
    movzx   eax, word ptr [rsi + rcx*2]
    cmp     eax, ebp                 # compare with delimiter (in ebp)
    je      .ss_emit
    inc     ecx
    jmp     .ss_loop
.ss_emit:
    # Emit segment [start..i)
    mov     eax, ecx
    sub     eax, r11d                # seg_len = i - start
    test    eax, eax
    jz      .ss_advance
    cmp     r9d, 32
    jge     .ss_advance
    mov     edi, r9d
    shl     edi, 4
    mov     ebx, r11d
    shl     ebx, 1                   # byte offset = start * 2
    lea     r8, [rsi + rbx]          # segment ptr
    mov     [r10 + 16 + rdi], r8
    mov     [r10 + 16 + rdi + 8], rax
    inc     r9d
    mov     [r10 + 8], r9
.ss_advance:
    inc     ecx
    mov     r11d, ecx                # start = i + 1
    jmp     .ss_loop
.ss_emit_last:
    mov     eax, edx
    sub     eax, r11d
    test    eax, eax
    jz      .ss_done
    cmp     r9d, 32
    jge     .ss_done
    mov     edi, r9d
    shl     edi, 4
    mov     ebx, r11d
    shl     ebx, 1
    lea     r8, [rsi + rbx]
    mov     [r10 + 16 + rdi], r8
    mov     [r10 + 16 + rdi + 8], rax
    inc     r9d
    mov     [r10 + 8], r9
.ss_done:
    sub     r14, 16
    mov     [r14], r10
    mov     qword ptr [r14+8], ARRAY_MARKER
    pop     rbp
    pop     rbx
    DISPATCH

# __chain_compose(chain_arr) → composed mol (Zipf-weighted)
.builtin_chain_compose:
    mov     rax, [r14]               # array ptr
    add     r14, 16
    # Follow forward
.cc_fwd:
    cmp     qword ptr [rax], -2
    jne     .cc_nofwd
    mov     rax, [rax + 8]
    jmp     .cc_fwd
.cc_nofwd:
    mov     rcx, [rax+8]            # count
    test    rcx, rcx
    jz      .cc_zero
    # BIOLOGICAL compose: S=Union(max), R=First(Zipf), V=Amplify, A=Max, T=First
    push    rbx
    xor     r8d, r8d                 # max_S
    mov     r9d, -1                  # first_R (unset)
    xor     r10d, r10d               # sum_V (for avg then amplify)
    xor     r11d, r11d               # max_A
    mov     ebx, -1                  # first_T (unset)
    xor     edx, edx
.cc_loop:
    cmp     edx, ecx
    jge     .cc_bio
    push    rdx
    shl     edx, 4
    movsd   xmm0, [rax + 16 + rdx]
    cvttsd2si esi, xmm0
    pop     rdx
    # S = Union = max
    mov     edi, esi
    shr     edi, 12
    and     edi, 0xF
    cmp     edi, r8d
    cmovg   r8d, edi
    # R = first (Zipf weighted)
    cmp     r9d, -1
    jne     .cc_r_skip
    mov     edi, esi
    shr     edi, 8
    and     edi, 0xF
    mov     r9d, edi
.cc_r_skip:
    # V = sum for amplify
    mov     edi, esi
    shr     edi, 5
    and     edi, 0x7
    add     r10d, edi
    # A = max
    mov     edi, esi
    shr     edi, 2
    and     edi, 0x7
    cmp     edi, r11d
    cmovg   r11d, edi
    # T = first
    cmp     ebx, -1
    jne     .cc_t_skip
    mov     edi, esi
    and     edi, 0x3
    mov     ebx, edi
.cc_t_skip:
    inc     edx
    jmp     .cc_loop
.cc_bio:
    # V amplify: base=avg, boost=|base-3|/2, result=base+sign*boost
    push    rdx
    mov     eax, r10d
    xor     edx, edx
    div     ecx                      # eax = avg_V
    mov     esi, eax
    sub     esi, 3                   # dev from midpoint
    mov     edi, esi
    neg     edi
    cmovs   edi, esi                 # abs(dev)
    shr     edi, 1                   # boost = |dev|/2
    test    esi, esi
    jns     .cc_v_pos
    sub     eax, edi                 # negative: amplify down
    xor     edx, edx
    test    eax, eax
    cmovs   eax, edx
    jmp     .cc_v_done
.cc_v_pos:
    add     eax, edi                 # positive: amplify up
    cmp     eax, 7
    jle     .cc_v_done
    mov     eax, 7
.cc_v_done:
    mov     r10d, eax
    pop     rdx
    # Handle unset R/T
    cmp     r9d, -1
    jne     .cc_r_ok
    xor     r9d, r9d
.cc_r_ok:
    cmp     ebx, -1
    jne     .cc_t_ok
    xor     ebx, ebx
.cc_t_ok:
    mov     eax, ebx                 # T for pack
    # Pack: (S<<12)|(R<<8)|(V<<5)|(A<<2)|T
    shl     r8d, 12
    shl     r9d, 8
    shl     r10d, 5
    shl     r11d, 2
    or      r8d, r9d
    or      r8d, r10d
    or      r8d, r11d
    or      r8d, eax
    pop     rbx
    cvtsi2sd xmm0, r8d
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH
.cc_zero:
    xorpd   xmm0, xmm0
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __chain_copy(chain_arr) → new array (deep copy on heap)
.builtin_chain_copy:
    mov     rax, [r14]               # array ptr
    add     r14, 16
.ccp_fwd:
    cmp     qword ptr [rax], -2
    jne     .ccp_nofwd
    mov     rax, [rax + 8]
    jmp     .ccp_fwd
.ccp_nofwd:
    mov     rcx, [rax+8]            # count
    mov     rdx, [rax]               # capacity
    # Allocate new array
    mov     rsi, r15
    mov     [r15], rdx               # capacity
    mov     [r15+8], rcx             # count
    # Copy entries
    push    rcx
    lea     rdi, [r15 + 16]
    lea     r8, [rax + 16]
    shl     ecx, 4                   # bytes = count × 16
    push    rsi
    mov     rsi, r8
    rep     movsb
    pop     rsi
    pop     rcx
    # Bump heap
    mov     rax, rdx
    shl     rax, 4
    add     rax, 16
    add     r15, rax
    sub     r14, 16
    mov     [r14], rsi
    mov     qword ptr [r14+8], ARRAY_MARKER
    DISPATCH

# __mmap(size) → address (MAP_PRIVATE|MAP_ANONYMOUS, 256MB max)
.builtin_mmap:
    movsd   xmm0, [r14]
    cvttsd2si rsi, xmm0             # size
    add     r14, 16
    xor     edi, edi                 # addr = NULL (kernel chooses)
    mov     edx, 3                   # PROT_READ|PROT_WRITE
    mov     r10d, 0x22               # MAP_PRIVATE|MAP_ANONYMOUS
    mov     r8d, -1                  # fd = -1
    xor     r9d, r9d                 # offset = 0
    mov     eax, 9                   # SYS_MMAP
    syscall
    cvtsi2sd xmm0, rax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __munmap(addr, size) → 0 on success
.builtin_munmap:
    movsd   xmm0, [r14+16]          # addr
    cvttsd2si rdi, xmm0
    movsd   xmm0, [r14]             # size
    cvttsd2si rsi, xmm0
    add     r14, 32
    mov     eax, 11                  # SYS_MUNMAP
    syscall
    cvtsi2sd xmm0, eax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __ioctl(fd, cmd, arg) → result
.builtin_ioctl:
    movsd   xmm0, [r14+32]          # fd
    cvttsd2si edi, xmm0
    movsd   xmm0, [r14+16]          # cmd (may be > 2^31, treat as u32)
    cvttsd2si rsi, xmm0
    movsd   xmm0, [r14]             # arg (can be 64-bit pointer)
    cvttsd2si rdx, xmm0
    add     r14, 48
    mov     eax, 16                  # SYS_IOCTL
    syscall
    cvtsi2sd xmm0, rax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __mmap_file(fd, size) → address (MAP_SHARED, file-backed)
.builtin_mmap_file:
    movsd   xmm0, [r14+16]          # fd
    cvttsd2si r8d, xmm0
    movsd   xmm0, [r14]             # size
    cvttsd2si rsi, xmm0
    add     r14, 32
    xor     edi, edi                 # addr = NULL
    mov     edx, 3                   # PROT_READ|PROT_WRITE
    mov     r10d, 1                  # MAP_SHARED
    xor     r9d, r9d                 # offset = 0
    mov     eax, 9                   # SYS_MMAP
    syscall
    cvtsi2sd xmm0, rax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __sha256(data) → hash string (64 hex chars)
.builtin_sha256:
    # Stub — return empty string (full SHA256 is 1400+ LOC)
    mov     rax, [r14]
    add     r14, 16
    sub     r14, 16
    xor     eax, eax
    mov     [r14], rax
    mov     qword ptr [r14+8], 0
    DISPATCH

# __crc32(data) → checksum number
.builtin_crc32:
    mov     rsi, [r14]               # data ptr
    mov     rdx, [r14+8]             # data len
    add     r14, 16
    # Simple CRC32 (polynomial 0xEDB88320)
    mov     eax, 0xFFFFFFFF
    xor     ecx, ecx
.crc_loop:
    cmp     ecx, edx
    jge     .crc_done
    movzx   edi, word ptr [rsi + rcx*2] # u16 mol
    xor     al, dil
    push    rcx
    mov     ecx, 8
.crc_bit:
    test    eax, 1
    jz      .crc_noxor
    shr     eax, 1
    xor     eax, 0xEDB88320
    jmp     .crc_next
.crc_noxor:
    shr     eax, 1
.crc_next:
    dec     ecx
    jnz     .crc_bit
    pop     rcx
    inc     ecx
    jmp     .crc_loop
.crc_done:
    not     eax
    cvtsi2sd xmm0, rax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __batch_dist(query_mol, array) → array of distances
.builtin_batch_dist:
    mov     rax, [r14]               # array ptr
    movsd   xmm0, [r14+16]          # query mol
    cvttsd2si ebp, xmm0
    add     r14, 32
    push    rbx
    push    rbp
.bd_fwd:
    cmp     qword ptr [rax], -2
    jne     .bd_nofwd
    mov     rax, [rax + 8]
    jmp     .bd_fwd
.bd_nofwd:
    mov     rcx, [rax+8]            # count
    # Allocate result array
    mov     r10, r15
    mov     [r15], rcx               # capacity = count
    mov     [r15+8], rcx             # count = count
    lea     r15, [r15 + 16]
    xor     edx, edx
.bd_loop:
    cmp     edx, ecx
    jge     .bd_done
    push    rax
    push    rcx
    push    rdx
    shl     edx, 4
    movsd   xmm0, [rax + 16 + rdx]
    cvttsd2si esi, xmm0
    mov     edi, ebp
    call    mol_dist_inline
    pop     rdx
    pop     rcx
    pop     rax
    cvtsi2sd xmm0, eax
    mov     esi, edx
    shl     esi, 4
    movsd   [r10 + 16 + rsi], xmm0
    mov     qword ptr [r10 + 16 + rsi + 8], F64_MARKER
    lea     r15, [r15 + 16]
    inc     edx
    jmp     .bd_loop
.bd_done:
    sub     r14, 16
    mov     [r14], r10
    mov     qword ptr [r14+8], ARRAY_MARKER
    pop     rbp
    pop     rbx
    DISPATCH

# ═══════════════════════════════════════════════════════════════════════════
# §18 SYSCALL + RAW MEMORY + FD BUILTINS (SS17 final)
# ═══════════════════════════════════════════════════════════════════════════

# __syscall(nr, a1, a2, a3, a4, a5, a6) → result
# Generic Linux syscall gateway — THE key to everything
.builtin_syscall:
    # Pop up to 7 args (nr + 6 args), right-to-left
    # Stack: [a6][a5][a4][a3][a2][a1][nr]  (TOS = a6)
    movsd   xmm0, [r14]             # a6
    cvttsd2si r9, xmm0
    movsd   xmm0, [r14+16]          # a5
    cvttsd2si r8, xmm0
    movsd   xmm0, [r14+32]          # a4
    cvttsd2si r10, xmm0
    movsd   xmm0, [r14+48]          # a3
    cvttsd2si rdx, xmm0
    movsd   xmm0, [r14+64]          # a2
    cvttsd2si rsi, xmm0
    movsd   xmm0, [r14+80]         # a1
    cvttsd2si rdi, xmm0
    movsd   xmm0, [r14+96]         # nr
    cvttsd2si rax, xmm0
    add     r14, 112                 # pop 7
    syscall
    cvtsi2sd xmm0, rax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __fd_open(path, flags) → fd
.builtin_fd_open:
    movsd   xmm0, [r14]             # flags
    cvttsd2si esi, xmm0
    mov     rdi, [r14+16]            # path ptr (u16 mols)
    mov     rdx, [r14+24]            # path len
    add     r14, 32
    # Decode u16 → bytes for syscall
    push    rsi
    mov     rcx, rdx                 # mol count
    mov     rsi, rdi                 # src = mol ptr
    mov     rdi, r15                 # dst = heap temp
.fdo_dec:
    test    rcx, rcx
    jz      .fdo_open
    movzx   eax, word ptr [rsi]
    mov     byte ptr [rdi], al
    add     rsi, 2
    inc     rdi
    dec     rcx
    jmp     .fdo_dec
.fdo_open:
    mov     byte ptr [rdi], 0        # null terminate
    mov     rdi, r15                 # path = decoded string
    pop     rsi                      # flags
    xor     edx, edx                 # mode = 0
    mov     eax, 2                   # SYS_OPEN
    syscall
    cvtsi2sd xmm0, rax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __fd_close(fd) → 0 on success
.builtin_fd_close:
    movsd   xmm0, [r14]
    cvttsd2si edi, xmm0
    add     r14, 16
    mov     eax, 3                   # SYS_CLOSE
    syscall
    cvtsi2sd xmm0, rax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __fd_read(fd, count) → string (raw bytes as u16 molecules)
.builtin_fd_read:
    movsd   xmm0, [r14]             # count
    cvttsd2si edx, xmm0
    movsd   xmm0, [r14+16]          # fd
    cvttsd2si edi, xmm0
    add     r14, 32
    # Read into temp buffer on heap
    mov     rsi, r15                 # buffer = heap
    push    rdx                      # save count
    mov     eax, 0                   # SYS_READ
    syscall
    pop     rdx
    # rax = bytes read (or negative error)
    test    rax, rax
    js      .fdr_err
    # Convert bytes → u16 molecules
    mov     rcx, rax                 # byte count
    mov     rsi, r15                 # src = raw bytes
    lea     rdi, [r15 + rcx + 16]    # dst = after raw bytes
    mov     r8, rdi                  # save start
    xor     edx, edx
.fdr_enc:
    cmp     edx, ecx
    jge     .fdr_done
    movzx   eax, byte ptr [rsi + rdx]
    mov     word ptr [rdi + rdx*2], ax
    inc     edx
    jmp     .fdr_enc
.fdr_done:
    sub     r14, 16
    mov     [r14], r8                # ptr to u16 molecules
    mov     [r14+8], rdx             # mol count = byte count
    # Bump heap past both buffers
    lea     r15, [r8 + rdx*2 + 16]
    DISPATCH
.fdr_err:
    sub     r14, 16
    xor     eax, eax
    mov     [r14], rax
    mov     qword ptr [r14+8], 0
    DISPATCH

# __mem_read8(addr, offset) → byte value (as number)
.builtin_mem_read8:
    movsd   xmm0, [r14+16]          # addr
    cvttsd2si rdi, xmm0
    movsd   xmm0, [r14]             # offset
    cvttsd2si rsi, xmm0
    add     r14, 32
    add     rdi, rsi
    movzx   eax, byte ptr [rdi]
    cvtsi2sd xmm0, eax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __mem_write8(addr, offset, value)
.builtin_mem_write8:
    movsd   xmm0, [r14+32]          # addr
    cvttsd2si rdi, xmm0
    movsd   xmm0, [r14+16]          # offset
    cvttsd2si rsi, xmm0
    movsd   xmm0, [r14]             # value
    cvttsd2si eax, xmm0
    add     r14, 48
    add     rdi, rsi
    mov     byte ptr [rdi], al
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __mem_read32(addr, offset) → u32 value (as number)
.builtin_mem_read32:
    movsd   xmm0, [r14+16]          # addr
    cvttsd2si rdi, xmm0
    movsd   xmm0, [r14]             # offset
    cvttsd2si rsi, xmm0
    add     r14, 32
    add     rdi, rsi
    mov     eax, [rdi]
    cvtsi2sd xmm0, rax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __mem_write32(addr, offset, value)
.builtin_mem_write32:
    movsd   xmm0, [r14+32]          # addr
    cvttsd2si rdi, xmm0
    movsd   xmm0, [r14+16]          # offset
    cvttsd2si rsi, xmm0
    movsd   xmm0, [r14]             # value
    cvttsd2si eax, xmm0
    add     r14, 48
    add     rdi, rsi
    mov     [rdi], eax
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# ═══════════════════════════════════════════════════════════════════════════
# S6: __readline() → string (read line from stdin, no trailing \n)
# ═══════════════════════════════════════════════════════════════════════════

.builtin_readline:
    # No args to pop (0 args)
    # Read bytes from fd 0 into Zone C as u16 mols
    mov     rdi, r15                 # result start
    xor     ecx, ecx                 # char count
.brl_loop:
    # read(0, &byte, 1)
    push    rcx
    push    rdi
    sub     rsp, 8                   # 1-byte buffer (aligned)
    mov     eax, SYS_READ            # 0
    xor     edi, edi                 # fd = 0 (stdin)
    mov     rsi, rsp                 # buffer
    mov     edx, 1                   # count = 1
    syscall
    cmp     rax, 0
    jle     .brl_eof                 # EOF or error → done
    movzx   eax, byte ptr [rsp]      # read byte
    add     rsp, 8
    pop     rdi
    pop     rcx
    cmp     eax, 10                  # newline?
    je      .brl_done
    cmp     eax, 0                   # null?
    je      .brl_done
    # Store as u16 mol
    mov     word ptr [r15], ax
    add     r15, 2
    inc     ecx
    cmp     ecx, 4096               # max 4096 chars
    jl      .brl_loop
    jmp     .brl_done
.brl_eof:
    add     rsp, 8
    pop     rdi
    pop     rcx
.brl_done:
    # Return: [ptr=rdi, len=ecx]
    sub     r14, 16
    mov     [r14], rdi
    mov     rax, rcx
    mov     [r14+8], rax
    DISPATCH

# ═══════════════════════════════════════════════════════════════════════════
# Phase 4.2: Typed f64/u8 arrays — contiguous, no tags
# f64 layout: [count:8][f64 × N], marker = -8
# u8 layout:  [count:8][u8 × N], marker = -9
# ═══════════════════════════════════════════════════════════════════════════

# __f64_new(count) → typed f64 array (zeroed)
.builtin_f64_new:
    movsd   xmm0, [r14]
    cvttsd2si ecx, xmm0
    add     r14, 16
    mov     rdi, r15
    mov     [r15], rcx
    lea     r15, [r15 + 8]
    # Zero N×8 bytes
    push    rcx
    push    rdi
    mov     rdi, r15
    shl     ecx, 3
    xor     eax, eax
    rep     stosb
    pop     rdi
    pop     rcx
    shl     rcx, 3
    add     r15, rcx
    sub     r14, 16
    mov     [r14], rdi
    mov     qword ptr [r14+8], -8
    DISPATCH

# __f64_get(arr, idx) → f64
.builtin_f64_get:
    movsd   xmm0, [r14]
    cvttsd2si ecx, xmm0
    mov     rax, [r14+16]
    add     r14, 32
    movsd   xmm0, [rax + 8 + rcx*8]
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], -1
    DISPATCH

# __f64_set(arr, idx, val) → arr
.builtin_f64_set:
    movsd   xmm0, [r14]
    movsd   xmm1, [r14+16]
    cvttsd2si ecx, xmm1
    mov     rax, [r14+32]
    add     r14, 48
    movsd   [rax + 8 + rcx*8], xmm0
    sub     r14, 16
    mov     [r14], rax
    mov     qword ptr [r14+8], -8
    DISPATCH

# __f64_len(arr) → count
.builtin_f64_len:
    mov     rax, [r14]
    mov     rcx, [rax]
    cvtsi2sd xmm0, rcx
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], -1
    DISPATCH

# __f64_dot(a, b, count) → scalar
.builtin_f64_dot:
    movsd   xmm0, [r14]
    cvttsd2si ecx, xmm0
    mov     rsi, [r14+16]
    mov     rdi, [r14+32]
    add     r14, 48
    lea     rdi, [rdi + 8]
    lea     rsi, [rsi + 8]
    xorpd   xmm0, xmm0
    xorpd   xmm2, xmm2              # SSE2 vector accumulator
    # AVX2 path: process 4 f64s at a time (256-bit)
    vxorpd  ymm2, ymm2, ymm2        # vector accumulator (4 × f64)
.f64d_avx:
    cmp     ecx, 4
    jl      .f64d_sse
    vmovupd ymm1, [rdi]             # 4 f64s from a
    vmulpd  ymm1, ymm1, [rsi]       # 4 pairwise multiplies
    vaddpd  ymm2, ymm2, ymm1        # accumulate
    add     rdi, 32
    add     rsi, 32
    sub     ecx, 4
    jmp     .f64d_avx
.f64d_sse:
    # Reduce ymm2 → xmm: add high 128 to low 128
    vextractf128 xmm1, ymm2, 1      # xmm1 = high 128 bits
    vaddpd  xmm2, xmm2, xmm1       # xmm2 = [lo0+lo2, lo1+lo3]
    # SSE2 path: process 2 at a time
.f64d_vec:
    cmp     ecx, 2
    jl      .f64d_tail
    movupd  xmm1, [rdi]
    movupd  xmm3, [rsi]
    mulpd   xmm1, xmm3
    addpd   xmm2, xmm1
    add     rdi, 16
    add     rsi, 16
    sub     ecx, 2
    jmp     .f64d_vec
.f64d_tail:
    # Reduce xmm2 = [a, b] → xmm0 += a + b
    movapd  xmm1, xmm2
    unpckhpd xmm1, xmm1
    addsd   xmm0, xmm2
    addsd   xmm0, xmm1
    # Remaining 0 or 1
    test    ecx, ecx
    jz      .f64d_cleanup
    movsd   xmm1, [rdi]
    mulsd   xmm1, [rsi]
    addsd   xmm0, xmm1
.f64d_cleanup:
    vzeroupper                       # clean AVX state
.f64d_dn:
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], -1
    DISPATCH

# __u8_new(count) → typed u8 array
.builtin_u8_new:
    movsd   xmm0, [r14]
    cvttsd2si ecx, xmm0
    add     r14, 16
    mov     rdi, r15
    mov     [r15], rcx
    lea     r15, [r15 + 8]
    push    rcx
    push    rdi
    mov     rdi, r15
    xor     eax, eax
    rep     stosb
    pop     rdi
    pop     rcx
    add     r15, rcx
    add     r15, 7
    and     r15, -8
    sub     r14, 16
    mov     [r14], rdi
    mov     qword ptr [r14+8], -9
    DISPATCH

# __u8_get(arr, idx) → byte as f64
.builtin_u8_get:
    movsd   xmm0, [r14]
    cvttsd2si ecx, xmm0
    mov     rax, [r14+16]
    add     r14, 32
    movzx   eax, byte ptr [rax + 8 + rcx]
    cvtsi2sd xmm0, eax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], -1
    DISPATCH

# __u8_set(arr, idx, val) → arr
.builtin_u8_set:
    movsd   xmm0, [r14]
    cvttsd2si eax, xmm0
    movsd   xmm1, [r14+16]
    cvttsd2si ecx, xmm1
    mov     rdx, [r14+32]
    add     r14, 48
    mov     byte ptr [rdx + 8 + rcx], al
    sub     r14, 16
    mov     [r14], rdx
    mov     qword ptr [r14+8], -9
    DISPATCH

# ═══════════════════════════════════════════════════════════════════════════
# Phase 3.1: FFI — call C function via pointer
# __ffi_call(fn_ptr, arg1, ..., argN, N) → result (integer)
# N = number of args (not counting fn_ptr and N itself). Max 6.
# All args converted from f64 to i64. Result i64 → f64.
# ═══════════════════════════════════════════════════════════════════════════
.builtin_ffi_call:
    # Read argc from top of stack
    movsd   xmm0, [r14]
    cvttsd2si ebp, xmm0             # argc
    add     r14, 16                  # pop argc
    # Read args in reverse order into temp storage
    sub     rsp, 48                  # 6 × 8 bytes
    xor     ecx, ecx
.ffc_read:
    cmp     ecx, ebp
    jge     .ffc_readfn
    movsd   xmm0, [r14]
    cvttsd2si rax, xmm0
    mov     [rsp + rcx*8], rax
    add     r14, 16
    inc     ecx
    jmp     .ffc_read
.ffc_readfn:
    # Read function pointer
    movsd   xmm0, [r14]
    cvttsd2si rax, xmm0
    add     r14, 16
    # Setup System V ABI regs (args are in stack[0..argc-1], reversed)
    # stack[0] = last arg pushed = argN-1. We need stack[argc-1] = arg0
    cmp     ebp, 1
    jl      .ffc_call
    mov     rdi, [rsp + rbp*8 - 8]
    cmp     ebp, 2
    jl      .ffc_call
    mov     rsi, [rsp + rbp*8 - 16]
    cmp     ebp, 3
    jl      .ffc_call
    mov     rdx, [rsp + rbp*8 - 24]
    cmp     ebp, 4
    jl      .ffc_call
    mov     rcx, [rsp + rbp*8 - 32]
    cmp     ebp, 5
    jl      .ffc_call
    mov     r8, [rsp + rbp*8 - 40]
    cmp     ebp, 6
    jl      .ffc_call
    mov     r9, [rsp + rbp*8 - 48]
.ffc_call:
    add     rsp, 48
    # Save VM registers (C function may clobber them)
    push    r12
    push    r13
    push    r14
    push    r15
    push    rbx
    # Align stack
    mov     r10, rsp
    and     rsp, -16
    push    r10
    # Call
    call    rax
    # Restore
    pop     rsp
    pop     rbx
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    # Return rax as f64
    cvtsi2sd xmm0, rax
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# ═══════════════════════════════════════════════════════════════════════════
# Phase 3.4: Array builtins
# ═══════════════════════════════════════════════════════════════════════════

# __array_sort(arr) → sorted arr (in-place insertion sort, numeric ascending)
.builtin_array_sort:
    mov     rax, [r14]               # array ptr
    # Follow forwarding
.bas_fwd:
    cmp     qword ptr [rax], -2
    jne     .bas_nofwd
    mov     rax, [rax+8]
    jmp     .bas_fwd
.bas_nofwd:
    mov     rcx, [rax+8]            # count
    cmp     rcx, 2
    jl      .bas_done                # 0 or 1 elements → already sorted
    push    rbx
    mov     rbx, rax                 # array base
    # Insertion sort: i=1..count-1
    mov     rsi, 1                   # i
.bas_outer:
    cmp     rsi, rcx
    jge     .bas_finish
    # key = arr[i]
    mov     rdi, rsi
    shl     rdi, 4
    add     rdi, 16                  # offset = 16 + i*16
    movsd   xmm0, [rbx + rdi]       # key.ptr (f64 bits)
    mov     r8, [rbx + rdi + 8]     # key.marker
    # j = i - 1
    mov     rdx, rsi
    dec     rdx
.bas_inner:
    cmp     rdx, 0
    jl      .bas_insert
    # Compare arr[j] > key
    mov     rdi, rdx
    shl     rdi, 4
    add     rdi, 16
    movsd   xmm1, [rbx + rdi]       # arr[j].ptr
    ucomisd xmm1, xmm0              # arr[j] > key?
    jbe     .bas_insert              # arr[j] <= key → stop
    # arr[j+1] = arr[j]
    mov     r9, [rbx + rdi]
    mov     r10, [rbx + rdi + 8]
    mov     [rbx + rdi + 16], r9
    mov     [rbx + rdi + 24], r10
    dec     rdx
    jmp     .bas_inner
.bas_insert:
    # arr[j+1] = key
    mov     rdi, rdx
    inc     rdi
    shl     rdi, 4
    add     rdi, 16
    movsd   [rbx + rdi], xmm0
    mov     [rbx + rdi + 8], r8
    inc     rsi
    mov     rcx, [rbx + 8]          # reload count (safe)
    jmp     .bas_outer
.bas_finish:
    pop     rbx
.bas_done:
    # Return the array (already on stack, in-place sort)
    DISPATCH

# __array_slice(arr, start, end) → new array
.builtin_array_slice:
    movsd   xmm0, [r14]             # end
    cvttsd2si r9d, xmm0
    movsd   xmm0, [r14+16]          # start
    cvttsd2si r8d, xmm0
    mov     rax, [r14+32]           # array ptr
    add     r14, 48                  # pop 3 args
    # Follow forwarding
.bsl_fwd:
    cmp     qword ptr [rax], -2
    jne     .bsl_nofwd
    mov     rax, [rax+8]
    jmp     .bsl_fwd
.bsl_nofwd:
    mov     rcx, [rax+8]            # count
    # Clamp
    cmp     r8d, 0
    jge     .bsl_s_ok
    xor     r8d, r8d
.bsl_s_ok:
    cmp     r9d, ecx
    jle     .bsl_e_ok
    mov     r9d, ecx
.bsl_e_ok:
    cmp     r8d, r9d
    jge     .bsl_empty
    # New array on heap
    mov     rdi, r15                 # new array base
    mov     edx, r9d
    sub     edx, r8d                 # new count
    mov     [r15], rdx               # capacity = count
    mov     [r15+8], rdx             # count
    lea     r15, [r15 + 16]
    # Copy elements
    xor     ecx, ecx
.bsl_copy:
    cmp     ecx, edx
    jge     .bsl_ret
    mov     esi, r8d
    add     esi, ecx
    shl     esi, 4
    add     esi, 16
    mov     r10, [rax + rsi]
    mov     r11, [rax + rsi + 8]
    mov     [r15], r10
    mov     [r15+8], r11
    add     r15, 16
    inc     ecx
    jmp     .bsl_copy
.bsl_ret:
    sub     r14, 16
    mov     [r14], rdi
    mov     qword ptr [r14+8], ARRAY_MARKER
    DISPATCH
.bsl_empty:
    # Return empty array
    mov     rdi, r15
    mov     qword ptr [r15], 0
    mov     qword ptr [r15+8], 0
    add     r15, 16
    sub     r14, 16
    mov     [r14], rdi
    mov     qword ptr [r14+8], ARRAY_MARKER
    DISPATCH

# __array_reverse(arr) → reversed arr (in-place)
.builtin_array_reverse:
    mov     rax, [r14]
.bar_fwd:
    cmp     qword ptr [rax], -2
    jne     .bar_nofwd
    mov     rax, [rax+8]
    jmp     .bar_fwd
.bar_nofwd:
    mov     rcx, [rax+8]            # count
    cmp     rcx, 2
    jl      .bar_done
    xor     esi, esi                 # left = 0
    mov     edi, ecx
    dec     edi                      # right = count-1
.bar_swap:
    cmp     esi, edi
    jge     .bar_done
    # Swap arr[left] and arr[right]
    mov     edx, esi
    shl     edx, 4
    add     edx, 16
    mov     r8, [rax + rdx]
    mov     r9, [rax + rdx + 8]
    mov     ecx, edi
    shl     ecx, 4
    add     ecx, 16
    mov     r10, [rax + rcx]
    mov     r11, [rax + rcx + 8]
    mov     [rax + rdx], r10
    mov     [rax + rdx + 8], r11
    mov     [rax + rcx], r8
    mov     [rax + rcx + 8], r9
    inc     esi
    dec     edi
    jmp     .bar_swap
.bar_done:
    DISPATCH

# __time_now() → milliseconds since epoch (f64)
.builtin_time_now:
    sub     rsp, 16                  # struct timespec {sec:8, nsec:8}
    mov     eax, SYS_CLOCK_GETTIME  # 228
    xor     edi, edi                 # CLOCK_REALTIME = 0
    mov     rsi, rsp
    syscall
    # Convert: ms = sec * 1000.0 + nsec / 1000000.0
    cvtsi2sd xmm0, qword ptr [rsp]   # seconds
    movsd    xmm1, [rip + .time_1000]
    mulsd    xmm0, xmm1               # sec * 1000
    cvtsi2sd xmm1, qword ptr [rsp+8]  # nanoseconds
    movsd    xmm2, [rip + .time_1m]
    divsd    xmm1, xmm2               # nsec / 1000000
    addsd    xmm0, xmm1               # total ms
    add      rsp, 16
    sub      r14, 16
    movsd    [r14], xmm0
    mov      qword ptr [r14+8], F64_MARKER
    DISPATCH
.time_1000: .quad 0x408F400000000000   # 1000.0
.time_1m:   .quad 0x412E848000000000   # 1000000.0

# ═══════════════════════════════════════════════════════════════════════════
# __tcp_connect(ip_str, port) → fd or -1
# Connects to ip:port via TCP. ip_str is "1.2.3.4" format.
# ═══════════════════════════════════════════════════════════════════════════
.builtin_tcp_connect:
    movsd   xmm0, [r14]             # port (f64)
    cvttsd2si edi, xmm0             # port as int
    mov     rsi, [r14+16]           # ip string ptr (u16 mols)
    mov     rdx, [r14+24]           # ip string len
    add     r14, 32                 # pop 2 args
    push    rdi                      # save port
    # Parse IP: "1.2.3.4" → 4 bytes
    # Decode u16 mols to ASCII bytes first
    sub     rsp, 64                  # temp buffer
    mov     rdi, rsp
    xor     ecx, ecx
.btc_decode:
    cmp     ecx, edx
    jge     .btc_decoded
    movzx   eax, word ptr [rsi + rcx*2]
    mov     byte ptr [rdi + rcx], al
    inc     ecx
    jmp     .btc_decode
.btc_decoded:
    mov     byte ptr [rdi + rcx], 0  # null terminate
    # Parse IP octets: simple manual parse
    xor     r8d, r8d                 # octet accumulator
    xor     r9d, r9d                 # byte index (0-3)
    xor     r10d, r10d               # result IP (network byte order)
    xor     ecx, ecx
.btc_parse_ip:
    movzx   eax, byte ptr [rdi + rcx]
    test    eax, eax
    jz      .btc_ip_done_last
    cmp     eax, 46                  # '.'
    je      .btc_ip_dot
    sub     eax, 48
    imul    r8d, r8d, 10
    add     r8d, eax
    inc     ecx
    jmp     .btc_parse_ip
.btc_ip_dot:
    # Store octet
    shl     r10d, 8
    or      r10d, r8d
    xor     r8d, r8d
    inc     r9d
    inc     ecx
    jmp     .btc_parse_ip
.btc_ip_done_last:
    shl     r10d, 8
    or      r10d, r8d
    # r10d now has IP in big-endian wrong order, need to bswap
    bswap   r10d
    add     rsp, 64
    pop     rdi                      # port

    # Build sockaddr_in on stack: [AF_INET:2][port:2][ip:4][zero:8]
    sub     rsp, 16
    mov     word ptr [rsp], 2        # AF_INET
    # Port in network byte order (big-endian)
    mov     eax, edi
    xchg    al, ah                   # swap bytes for network order
    mov     word ptr [rsp+2], ax     # port
    mov     dword ptr [rsp+4], r10d  # IP
    mov     qword ptr [rsp+8], 0     # padding

    # socket(AF_INET=2, SOCK_STREAM=1, 0)
    mov     eax, SYS_SOCKET          # 41
    mov     edi, 2                   # AF_INET
    mov     esi, 1                   # SOCK_STREAM
    xor     edx, edx                 # protocol = 0
    syscall
    test    eax, eax
    js      .btc_fail
    mov     r8d, eax                 # save fd

    # connect(fd, sockaddr, 16)
    mov     edi, r8d                 # fd
    mov     rsi, rsp                 # sockaddr_in ptr
    mov     edx, 16                  # addrlen
    mov     eax, SYS_CONNECT         # 42
    syscall
    add     rsp, 16                  # cleanup sockaddr
    test    eax, eax
    js      .btc_close_fail
    # Success: return fd
    cvtsi2sd xmm0, r8d
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH
.btc_close_fail:
    # Connect failed, close socket, sockaddr already on stack
    add     rsp, 16                  # cleanup sockaddr
    mov     edi, r8d
    mov     eax, SYS_CLOSE
    syscall
    jmp     .btc_ret_fail
.btc_fail:
    add     rsp, 16                  # cleanup sockaddr
.btc_ret_fail:
    sub     r14, 16
    mov     rax, -1
    cvtsi2sd xmm0, rax
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# ═══════════════════════════════════════════════════════════════════════════
# Phase 1.5: Math Builtins (SS23)
# ═══════════════════════════════════════════════════════════════════════════

# __sin(x) → sin(x)  [1 arg, uses x87 fsin]
.builtin_sin:
    fld     qword ptr [r14]
    fsin
    fstp    qword ptr [r14]
    DISPATCH

# __cos(x) → cos(x)
.builtin_cos:
    fld     qword ptr [r14]
    fcos
    fstp    qword ptr [r14]
    DISPATCH

# __tan(x) → tan(x) = sin/cos
.builtin_tan:
    fld     qword ptr [r14]
    fptan                           # st(0)=1, st(1)=tan(x)
    fstp    st(0)                   # pop the 1
    fstp    qword ptr [r14]
    DISPATCH

# __atan(x) → atan(x)
.builtin_atan:
    fld     qword ptr [r14]
    fld1
    fpatan                          # atan(st(1)/st(0)) = atan(x/1) = atan(x)
    fstp    qword ptr [r14]
    DISPATCH

# __atan2(y, x) → atan2(y, x)  [2 args]
.builtin_atan2:
    fld     qword ptr [r14+16]      # y
    fld     qword ptr [r14]         # x
    fpatan                          # atan(y/x)
    add     r14, 16                 # pop 1 arg (result replaces first)
    fstp    qword ptr [r14]
    DISPATCH

# __pow(base, exp) → base^exp  [2 args]
.builtin_pow:
    # x^y = 2^(y * log2(x))
    fld     qword ptr [r14]         # exp
    fld     qword ptr [r14+16]      # base
    fyl2x                           # st(0) = exp * log2(base)
    fld     st(0)
    frndint
    fxch
    fsub    st(0), st(1)
    f2xm1
    fld1
    faddp
    fscale
    fstp    st(1)
    add     r14, 16
    fstp    qword ptr [r14]
    DISPATCH

# __log(x) → ln(x)  (natural log)
.builtin_log:
    fldln2                          # ln(2)
    fld     qword ptr [r14]         # x
    fyl2x                           # ln(2) * log2(x) = ln(x)
    fstp    qword ptr [r14]
    DISPATCH

# __log10(x) → log10(x)
.builtin_log10:
    fldlg2                          # log10(2)
    fld     qword ptr [r14]
    fyl2x                           # log10(2) * log2(x) = log10(x)
    fstp    qword ptr [r14]
    DISPATCH

# __round(x) → nearest integer
.builtin_round:
    fld     qword ptr [r14]
    frndint
    fstp    qword ptr [r14]
    DISPATCH

# __min(a, b) → smaller  [2 args]
.builtin_min:
    movsd   xmm0, [r14+16]         # a
    movsd   xmm1, [r14]            # b
    minsd   xmm0, xmm1
    add     r14, 16
    movsd   [r14], xmm0
    DISPATCH

# __max(a, b) → larger  [2 args]
.builtin_max:
    movsd   xmm0, [r14+16]
    movsd   xmm1, [r14]
    maxsd   xmm0, xmm1
    add     r14, 16
    movsd   [r14], xmm0
    DISPATCH

# __random() → random f64 in [0, 1)  [0 args]
.builtin_random:
    sub     rsp, 8
    mov     eax, SYS_GETRANDOM     # 318
    mov     rdi, rsp                # buf (rdi = arg1)
    mov     esi, 8                  # buflen (rsi = arg2)
    xor     edx, edx                # flags (rdx = arg3) = 0
    syscall
    mov     rax, [rsp]
    add     rsp, 8
    # Convert u64 to [0,1): divide by 2^64
    # Method: mask to 52-bit mantissa, set exponent to 1.0, subtract 1.0
    mov     rcx, 0x3FF0000000000000 # 1.0 as f64
    shr     rax, 12                 # keep 52 bits
    or      rax, rcx                # exponent = 1.0, mantissa = random
    sub     r14, 16
    mov     [r14], rax
    mov     qword ptr [r14+8], F64_MARKER
    # Subtract 1.0 to get [0, 1)
    movsd   xmm0, [r14]
    movsd   xmm1, [rip + .random_one]
    subsd   xmm0, xmm1
    movsd   [r14], xmm0
    DISPATCH
.random_one:
    .quad   0x3FF0000000000000      # 1.0

# ═══════════════════════════════════════════════════════════════════════════
# S2: Dict Builtins (SS23) — struct support
# Layout: [cap:8][count:8][entries...] where entry = [key_ptr:8][key_len:8][val:8][val_marker:8] = 32 bytes
# ═══════════════════════════════════════════════════════════════════════════

# __dict_new() → empty dict (capacity 16)
.builtin_dict_new:
    mov     rax, r15                 # dict base
    mov     qword ptr [r15], 16      # capacity = 16
    mov     qword ptr [r15+8], 0     # count = 0
    # Zero out 16 entries × 32 bytes = 512 bytes
    lea     rdi, [r15 + 16]
    mov     ecx, 64                  # 512/8 = 64 qwords
    xor     eax, eax
    rep     stosq
    mov     rax, r15                 # save base before advancing
    add     r15, 528                 # 16 header + 512 entries
    sub     r14, 16
    mov     [r14], rax
    mov     qword ptr [r14+8], DICT_MARKER
    DISPATCH

# __dict_get(dict, key_str) → value (or 0 if not found)
.builtin_dict_get:
    mov     r8, [r14]                # key ptr
    mov     r9, [r14+8]              # key len
    mov     rax, [r14+16]            # dict ptr
    add     r14, 32                  # pop 2 args
    # Follow forwarding
.bdg_fwd:
    cmp     qword ptr [rax], -2
    jne     .bdg_nofwd
    mov     rax, [rax+8]
    jmp     .bdg_fwd
.bdg_nofwd:
    mov     rcx, [rax+8]            # count
    test    rcx, rcx
    jz      .bdg_notfound
    lea     rdi, [rax + 16]          # first entry
    xor     esi, esi                 # index
.bdg_scan:
    cmp     rsi, rcx
    jge     .bdg_notfound
    # Compare key: entry.key_ptr, entry.key_len vs r8, r9
    mov     rdx, [rdi]               # entry key ptr
    mov     r10, [rdi+8]             # entry key len
    cmp     r10, r9                  # same length?
    jne     .bdg_next
    # Compare bytes
    push    rsi
    push    rdi
    push    rcx
    xor     ecx, ecx
.bdg_cmp:
    cmp     rcx, r9
    jge     .bdg_found_pop
    movzx   eax, word ptr [rdx + rcx*2]
    movzx   r10d, word ptr [r8 + rcx*2]
    cmp     eax, r10d
    jne     .bdg_next_pop
    inc     rcx
    jmp     .bdg_cmp
.bdg_found_pop:
    pop     rcx
    pop     rdi
    pop     rsi
    # Found! Return value at [rdi+16], marker at [rdi+24]
    sub     r14, 16
    mov     rax, [rdi+16]
    mov     rdx, [rdi+24]
    mov     [r14], rax
    mov     [r14+8], rdx
    DISPATCH
.bdg_next_pop:
    pop     rcx
    pop     rdi
    pop     rsi
.bdg_next:
    add     rdi, 32                  # next entry
    inc     rsi
    jmp     .bdg_scan
.bdg_notfound:
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __dict_set(dict, key_str, value) → dict (mutates in place, returns same dict)
.builtin_dict_set:
    # Stack: [val:8][val_mk:8] [key_ptr:8][key_len:8] [dict_ptr:8][dict_mk:8]
    mov     r10, [r14]               # val
    mov     r11, [r14+8]             # val marker
    mov     r8, [r14+16]             # key ptr
    mov     r9, [r14+24]             # key len
    mov     rax, [r14+32]            # dict ptr
    add     r14, 48                  # pop 3 args
    # Follow forwarding
.bds_fwd:
    cmp     qword ptr [rax], -2
    jne     .bds_nofwd
    mov     rax, [rax+8]
    jmp     .bds_fwd
.bds_nofwd:
    mov     rcx, [rax+8]            # count
    push    rax                      # save dict ptr
    lea     rdi, [rax + 16]          # first entry
    xor     esi, esi
    # Search for existing key
.bds_scan:
    cmp     rsi, rcx
    jge     .bds_append
    mov     rdx, [rdi]               # entry key ptr
    cmp     [rdi+8], r9              # entry key len == key len?
    jne     .bds_snext
    # Compare key chars
    push    rsi
    push    rdi
    push    rcx
    xor     ecx, ecx
.bds_cmp:
    cmp     rcx, r9
    jge     .bds_update_pop
    movzx   eax, word ptr [rdx + rcx*2]
    movzx   esi, word ptr [r8 + rcx*2]
    cmp     eax, esi
    jne     .bds_snext_pop
    inc     rcx
    jmp     .bds_cmp
.bds_update_pop:
    pop     rcx
    pop     rdi
    pop     rsi
    # Key exists → update value
    mov     [rdi+16], r10
    mov     [rdi+24], r11
    pop     rax                      # dict ptr
    jmp     .bds_return
.bds_snext_pop:
    pop     rcx
    pop     rdi
    pop     rsi
.bds_snext:
    add     rdi, 32
    inc     rsi
    jmp     .bds_scan
.bds_append:
    # Key not found → append new entry
    pop     rax                      # dict ptr
    mov     rcx, [rax+8]            # count
    cmp     rcx, [rax]              # count >= capacity?
    jge     .bds_return              # full → silently fail (TODO: grow)
    # rdi already points to entries[count]
    mov     [rdi], r8                # key ptr
    mov     [rdi+8], r9              # key len
    mov     [rdi+16], r10            # value
    mov     [rdi+24], r11            # value marker
    inc     qword ptr [rax+8]        # count++
.bds_return:
    sub     r14, 16
    mov     [r14], rax
    mov     qword ptr [r14+8], DICT_MARKER
    DISPATCH

# __dict_keys(dict) → array of key strings
.builtin_dict_keys:
    mov     rax, [r14]               # dict ptr
    add     r14, 16                  # pop 1 arg
    # Follow forwarding
.bdk_fwd:
    cmp     qword ptr [rax], -2
    jne     .bdk_nofwd
    mov     rax, [rax+8]
    jmp     .bdk_fwd
.bdk_nofwd:
    mov     rcx, [rax+8]            # count
    push    rbx
    mov     rbx, rax                 # save dict ptr
    # Allocate result array on r15
    mov     rdi, r15                 # array base
    mov     [r15], rcx               # capacity = count
    mov     [r15+8], rcx             # count = count
    lea     r15, [r15 + 16]          # skip header
    # Copy key ptrs as string entries
    lea     rsi, [rbx + 16]          # first entry
    xor     edx, edx
.bdk_loop:
    cmp     rdx, rcx
    jge     .bdk_done
    mov     rax, [rsi]               # key ptr
    mov     r8, [rsi+8]              # key len
    mov     [r15], rax
    mov     [r15+8], r8
    add     r15, 16
    add     rsi, 32                  # next entry
    inc     rdx
    jmp     .bdk_loop
.bdk_done:
    pop     rbx
    sub     r14, 16
    mov     [r14], rdi               # array ptr
    mov     qword ptr [r14+8], ARRAY_MARKER
    DISPATCH

# ═══════════════════════════════════════════════════════════════════════════
# S1: New String Builtins (SS23)
# ═══════════════════════════════════════════════════════════════════════════

# __str_starts_with(text, prefix) → 0 or 1 (f64)
.builtin_str_starts_with:
    mov     r8, [r14]                # prefix ptr
    mov     r9, [r14+8]              # prefix len
    mov     rsi, [r14+16]            # text ptr
    mov     rdx, [r14+24]            # text len
    add     r14, 32                  # pop 2 args
    cmp     r9, rdx
    jg      .bssw_false              # prefix longer → false
    test    r9, r9
    jz      .bssw_true               # empty prefix → true
    xor     ecx, ecx
.bssw_cmp:
    cmp     rcx, r9
    jge     .bssw_true
    movzx   eax, word ptr [rsi + rcx*2]
    movzx   edi, word ptr [r8 + rcx*2]
    cmp     eax, edi
    jne     .bssw_false
    inc     rcx
    jmp     .bssw_cmp
.bssw_true:
    sub     r14, 16
    mov     rax, 1
    cvtsi2sd xmm0, rax
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH
.bssw_false:
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __str_ends_with(text, suffix) → 0 or 1 (f64)
.builtin_str_ends_with:
    mov     r8, [r14]                # suffix ptr
    mov     r9, [r14+8]              # suffix len
    mov     rsi, [r14+16]            # text ptr
    mov     rdx, [r14+24]            # text len
    add     r14, 32                  # pop 2 args
    cmp     r9, rdx
    jg      .bsew_false              # suffix longer → false
    test    r9, r9
    jz      .bsew_true               # empty suffix → true
    # Compare from end: text[len-suflen..len] vs suffix[0..suflen]
    mov     rcx, rdx
    sub     rcx, r9                  # rcx = offset where suffix should start
    xor     edi, edi
.bsew_cmp:
    cmp     rdi, r9
    jge     .bsew_true
    lea     rax, [rcx + rdi]
    movzx   eax, word ptr [rsi + rax*2]
    movzx   r10d, word ptr [r8 + rdi*2]
    cmp     eax, r10d
    jne     .bsew_false
    inc     rdi
    jmp     .bsew_cmp
.bsew_true:
    sub     r14, 16
    mov     rax, 1
    cvtsi2sd xmm0, rax
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH
.bsew_false:
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __str_to_num(str) → f64 (parse decimal number from string)
# Handles: integers, decimals, negative numbers
.builtin_str_to_num:
    mov     rsi, [r14]               # text ptr
    mov     rdx, [r14+8]             # text len
    add     r14, 16                  # pop 1 arg
    test    rdx, rdx
    jz      .bstn_zero
    # State: sign, integer part, fractional part
    xor     ecx, ecx                 # position
    xor     r8d, r8d                 # sign flag (0=positive)
    # Check leading minus
    movzx   eax, word ptr [rsi]
    cmp     eax, 45                  # '-'
    jne     .bstn_int
    mov     r8d, 1                   # negative
    inc     ecx
.bstn_int:
    xor     r9d, r9d                 # integer accumulator
.bstn_int_loop:
    cmp     ecx, edx
    jge     .bstn_build
    movzx   eax, word ptr [rsi + rcx*2]
    cmp     eax, 46                  # '.'
    je      .bstn_frac_start
    sub     eax, 48                  # '0'
    cmp     eax, 9
    ja      .bstn_build              # non-digit → stop
    imul    r9, r9, 10
    add     r9, rax
    inc     ecx
    jmp     .bstn_int_loop
.bstn_frac_start:
    inc     ecx                      # skip '.'
    xor     r10d, r10d               # frac accumulator
    mov     r11d, 1                  # frac divisor
.bstn_frac_loop:
    cmp     ecx, edx
    jge     .bstn_build_frac
    movzx   eax, word ptr [rsi + rcx*2]
    sub     eax, 48
    cmp     eax, 9
    ja      .bstn_build_frac
    imul    r10, r10, 10
    add     r10, rax
    imul    r11, r11, 10
    inc     ecx
    jmp     .bstn_frac_loop
.bstn_build_frac:
    # result = integer + frac/divisor
    cvtsi2sd xmm0, r9               # integer part
    cvtsi2sd xmm1, r10              # frac numerator
    cvtsi2sd xmm2, r11              # frac divisor
    divsd   xmm1, xmm2              # frac value
    addsd   xmm0, xmm1              # total
    test    r8d, r8d
    jz      .bstn_ret
    # Negate: xmm0 = 0 - xmm0
    xorpd   xmm1, xmm1
    subsd   xmm1, xmm0
    movsd   xmm0, xmm1
    jmp     .bstn_ret
.bstn_build:
    cvtsi2sd xmm0, r9
    test    r8d, r8d
    jz      .bstn_ret
    xorpd   xmm1, xmm1
    subsd   xmm1, xmm0
    movsd   xmm0, xmm1
.bstn_ret:
    sub     r14, 16
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH
.bstn_zero:
    sub     r14, 16
    xorpd   xmm0, xmm0
    movsd   [r14], xmm0
    mov     qword ptr [r14+8], F64_MARKER
    DISPATCH

# __str_join(array, separator) → string
# Join array of strings with separator between each
.builtin_str_join:
    mov     r8, [r14]                # sep ptr
    mov     r9, [r14+8]             # sep len
    mov     rax, [r14+16]            # array ptr
    add     r14, 32                  # pop 2 args
    # Follow array forwarding pointers
.bsj_fwd:
    cmp     qword ptr [rax], -2
    jne     .bsj_nofwd
    mov     rax, [rax + 8]
    jmp     .bsj_fwd
.bsj_nofwd:
    mov     rcx, [rax+8]            # array count
    test    rcx, rcx
    jz      .bsj_empty
    push    rbx
    push    rbp
    push    r12
    push    r13
    mov     rbx, rax                # array base
    mov     rbp, rcx                # array count
    mov     r12, r8                 # sep ptr
    mov     r13, r9                 # sep len
    # Destination = r15 (Zone C bump)
    mov     rdi, r15                # result start
    xor     ecx, ecx                # element index
.bsj_loop:
    cmp     rcx, rbp
    jge     .bsj_done
    # Get element: array[i] = [ptr:8][len:8] at offset 16 + i*16
    mov     rax, rcx
    shl     rax, 4                  # rax = i * 16
    add     rax, 16                 # skip header
    mov     rsi, [rbx + rax]        # element ptr
    mov     rdx, [rbx + rax + 8]    # element len (or marker if not string)
    # Skip non-string entries (f64 or nested array)
    cmp     rdx, -1                 # F64_MARKER
    je      .bsj_skip
    cmp     rdx, -3                 # ARRAY_MARKER
    je      .bsj_skip
    # Skip if len <= 0
    test    rdx, rdx
    jle     .bsj_skip
    # Add separator before element (except first)
    test    ecx, ecx
    jz      .bsj_copy_elem
    # Copy separator
    push    rcx
    push    rsi
    push    rdx
    xor     eax, eax
.bsj_copy_sep:
    cmp     rax, r13
    jge     .bsj_sep_done
    movzx   edx, word ptr [r12 + rax*2]
    mov     word ptr [r15], dx
    add     r15, 2
    inc     rax
    jmp     .bsj_copy_sep
.bsj_sep_done:
    pop     rdx
    pop     rsi
    pop     rcx
.bsj_copy_elem:
    # Copy element string
    push    rcx
    xor     eax, eax
.bsj_copy_ch:
    cmp     rax, rdx
    jge     .bsj_elem_done
    movzx   r10d, word ptr [rsi + rax*2]
    mov     word ptr [r15], r10w
    add     r15, 2
    inc     rax
    jmp     .bsj_copy_ch
.bsj_elem_done:
    pop     rcx
.bsj_skip:
    inc     rcx
    jmp     .bsj_loop
.bsj_done:
    # Result: ptr=rdi (saved start), len=(r15-rdi)/2
    mov     rax, r15
    sub     rax, rdi
    shr     rax, 1                  # byte count → mol count
    pop     r13
    pop     r12
    pop     rbp
    pop     rbx
    sub     r14, 16
    mov     [r14], rdi
    mov     [r14+8], rax
    DISPATCH
.bsj_empty:
    sub     r14, 16
    xor     eax, eax
    mov     [r14], rax
    mov     [r14+8], rax
    DISPATCH

# __str_replace(text, old, new) → string with all occurrences replaced
.builtin_str_replace:
    mov     r8, [r14]                # new ptr
    mov     r9, [r14+8]              # new len
    mov     r10, [r14+16]            # old ptr
    mov     r11, [r14+24]            # old len
    mov     rsi, [r14+32]            # text ptr
    mov     rdx, [r14+40]            # text len
    add     r14, 48                  # pop 3 args
    test    r11, r11
    jz      .bsr_copy_all            # empty old → just copy text
    push    rbx
    push    rbp
    push    r12
    push    r13
    push    r14                      # save stack ptr
    mov     rbx, rsi                 # text ptr
    mov     rbp, rdx                 # text len
    mov     r12, r10                 # old ptr
    mov     r13, r11                 # old len
    # Result built on r15
    mov     rdi, r15                 # result start
    xor     ecx, ecx                 # scan position
.bsr_scan:
    cmp     rcx, rbp
    jge     .bsr_finish
    # Check if old matches at position ecx
    lea     rax, [rcx + r13]
    cmp     rax, rbp
    jg      .bsr_copy_rest           # not enough chars left
    # Compare old at position
    xor     edx, edx
.bsr_cmp:
    cmp     rdx, r13
    jge     .bsr_matched
    lea     rax, [rcx + rdx]
    movzx   eax, word ptr [rbx + rax*2]
    movzx   r14d, word ptr [r12 + rdx*2]
    cmp     eax, r14d
    jne     .bsr_no_match
    inc     rdx
    jmp     .bsr_cmp
.bsr_matched:
    # Copy replacement (new) to output
    xor     eax, eax
.bsr_copy_new:
    cmp     rax, r9
    jge     .bsr_new_done
    movzx   edx, word ptr [r8 + rax*2]
    mov     word ptr [r15], dx
    add     r15, 2
    inc     rax
    jmp     .bsr_copy_new
.bsr_new_done:
    add     rcx, r13                 # skip past old in text
    jmp     .bsr_scan
.bsr_no_match:
    # Copy current char to output
    movzx   eax, word ptr [rbx + rcx*2]
    mov     word ptr [r15], ax
    add     r15, 2
    inc     rcx
    jmp     .bsr_scan
.bsr_copy_rest:
    # Copy remaining chars
    cmp     rcx, rbp
    jge     .bsr_finish
    movzx   eax, word ptr [rbx + rcx*2]
    mov     word ptr [r15], ax
    add     r15, 2
    inc     rcx
    jmp     .bsr_copy_rest
.bsr_finish:
    mov     rax, r15
    sub     rax, rdi
    shr     rax, 1                   # byte count → mol count
    pop     r14
    pop     r13
    pop     r12
    pop     rbp
    pop     rbx
    sub     r14, 16
    mov     [r14], rdi
    mov     [r14+8], rax
    DISPATCH
.bsr_copy_all:
    # Empty old: just return copy of text
    mov     rdi, r15
    xor     ecx, ecx
.bsr_copy_all_loop:
    cmp     rcx, rdx
    jge     .bsr_copy_all_done
    movzx   eax, word ptr [rsi + rcx*2]
    mov     word ptr [r15], ax
    add     r15, 2
    inc     rcx
    jmp     .bsr_copy_all_loop
.bsr_copy_all_done:
    sub     r14, 16
    mov     [r14], rdi
    mov     [r14+8], rdx
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
# Type name strings (u16 encoded for VM stack)
# SIMD constants (§16)
.align 16
simd_mask_0F:      .word 0x000F, 0x000F, 0x000F, 0x000F, 0x000F, 0x000F, 0x000F, 0x000F
simd_mask_07:      .word 0x0007, 0x0007, 0x0007, 0x0007, 0x0007, 0x0007, 0x0007, 0x0007
simd_mask_03:      .word 0x0003, 0x0003, 0x0003, 0x0003, 0x0003, 0x0003, 0x0003, 0x0003
simd_decay_factor: .word 0xF333, 0xF333, 0xF333, 0xF333, 0xF333, 0xF333, 0xF333, 0xF333
                   # 0xF333 = 62259 ≈ 0.95 × 65536

str_bin_sh:        .asciz "/bin/sh"
str_dash_c:        .asciz "-c"
str_type_number:   .word 'n','u','m','b','e','r'
str_type_string:   .word 's','t','r','i','n','g'
str_type_array:    .word 'a','r','r','a','y'
str_type_function: .word 'f','u','n','c','t','i','o','n'
str_type_molecule: .word 'm','o','l','e','c','u','l','e'
str_type_dict:     .word 'd','i','c','t'

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

# ── STM: 32 entries × 48 bytes = 1536 bytes ──
# Entry: [mol:2][pad:6][text_ptr:8][text_len:8][V:1][A:1][pad:6][timestamp:8][access:8]
.align 8
stm_entries:    .space 1536         # 32 × 48 bytes
stm_count:      .space 8            # current count (0-32)

# ── Bloom filter for negative knowledge (8KB) ──
.align 8
bloom_filter:   .space 8192         # 65536 bits = 8KB

# ── Homeostasis state ──
homeo_predicted: .space 8           # last predicted mol (f64)
homeo_mode:     .space 1            # 0=ACTING, 1=LEARNING
.align 8

# ── Misc ──
repl_heap_checkpoint: .space 8
_call_save_hash: .space 8
_call_save_argc: .space 8
_call_save_name_ptr: .space 8
_call_save_name_len: .space 8

# Shadow call stack for error traces (64 entries × 24 bytes = 1536 bytes)
.align 8
call_stack_depth: .space 8
call_stack:       .space 1536   # [(name_ptr:8, name_len:8, call_pc:8) × 64]
_push_old_arr: .space 8
try_depth:      .space 8

# SIMD temp buffer
.align 16
simd_temp:      .space 16              # 8 × u16 results

# §29: Capability table — 256 × 8 bytes = 2KB
# Entry: [type:1][id:4][perms:2][owner:1]
.align 8
cap_table:      .space 2048
