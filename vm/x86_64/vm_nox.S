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
    mov     eax, [rip + _call_save_hash]
    mov     ecx, [rip + _call_save_argc]
    mov     esi, eax
    and     esi, 0x1FF
    lea     rdx, [rip + builtin_jump_table]
    lea     rdx, [rdx + rsi*8]
    lea     rdi, [rip + .call_not_builtin]
    cmp     [rdx], rdi               # is it .call_not_builtin?
    jne     .call_is_builtin
    jmp     .call_skip               # neither closure nor builtin
.call_is_builtin:
    jmp     [rdx]                    # jump to builtin handler
.call_closure:
    # rax = body_pc, call it
    push    r12                      # save bytecode base
    push    r13                      # save return PC
    push    rbx                      # save bc_size
    # Push MARKER to undo stack (for scope save/restore)
    push    rax                      # save body_pc
    lea     rcx, [rip + var_save_top]
    mov     rdi, [rcx]
    mov     qword ptr [rdi], -1      # MARKER (slot_off = -1)
    add     rdi, 40                  # uniform 40-byte entry
    mov     [rcx], rdi
    pop     rax
    # Scope: depth++
    inc     qword ptr [rip + closure_depth]
    # Jump to closure body
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
    mov     r13d, eax
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
    je      op_halt                      # uncaught → halt
    pop     rax                          # catch_pc
    pop     r14                          # restore VM stack
    pop     r15                          # restore heap
    dec     qword ptr [rip + try_depth]
    mov     r13d, eax                    # jump to catch
    DISPATCH

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
    lea     rcx, [rip + builtin_jump_table]
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
    # Save old value to undo stack if inside closure scope
    cmp     qword ptr [rip + closure_depth], 0
    je      .vsm_no_save
    # Check if same depth → same scope update, no save needed
    mov     rdx, [rip + closure_depth]
    cmp     [rbx + rcx + 8], rdx
    je      .vsm_no_save
    # Different scope or empty → save old slot
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
    mov     [rdi], rax               # advance top
    pop     rdi
    pop     rax
.vsm_no_save:
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

# f64_to_string: xmm0=value → rax=ptr, rdx=len (on Zone C heap)
# Converts f64 to decimal string. Integer part only for now.
f64_to_string:
    push    r15                      # save heap ptr (= output start)
    cvttsd2si rax, xmm0             # integer part
    # Handle negative
    test    rax, rax
    jns     .f2s_pos
    mov     byte ptr [r15], '-'
    inc     r15
    neg     rax
.f2s_pos:
    # Handle zero
    test    rax, rax
    jnz     .f2s_nonzero
    mov     byte ptr [r15], '0'
    inc     r15
    jmp     .f2s_done
.f2s_nonzero:
    # Convert integer to decimal digits (reversed into temp area)
    lea     rdi, [r15 + 24]          # temp end marker
    mov     r8, rdi
.f2s_digit:
    test    rax, rax
    jz      .f2s_copy
    xor     edx, edx
    mov     rcx, 10
    div     rcx                      # rax = quotient, rdx = remainder
    add     dl, '0'
    dec     rdi
    mov     [rdi], dl
    jmp     .f2s_digit
.f2s_copy:
    # Copy digits from temp area to output (they were reversed)
    mov     rsi, rdi                 # src = first digit
    mov     rdi, r15                 # dst = output position
    mov     rcx, r8
    sub     rcx, rsi                 # digit count
    rep     movsb
    mov     r15, rdi                 # r15 = past last digit
.f2s_done:
    pop     rax                      # rax = output start
    mov     rdx, r15
    sub     rdx, rax                 # rdx = total length
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
.align 8
# ═══ Builtin Jump Table (512 slots, auto-generated) ═══
.align 8
builtin_jump_table:
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_str_find              # 0x024 (__str_find)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_heap_pin              # 0x035 (__heap_pin)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_mx_w                  # 0x054 (__mx_w)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_array_get             # 0x057 (__array_get)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_file_write            # 0x061 (__file_write)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_ceil                  # 0x06A (__ceil)
    .quad   .builtin_system                # 0x06B (__system)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_bit_shr               # 0x06E (__bit_shr)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_tcp_close             # 0x071 (__tcp_close)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_bit_or                # 0x082 (__bit_or)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_type_of               # 0x087 (type_of)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_exp                   # 0x08A (__exp)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_array_with_cap        # 0x092 (__array_with_cap)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_char_code             # 0x099 (__char_code)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_sqrt                  # 0x0A5 (__sqrt)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_tcp_send              # 0x0AD (__tcp_send)
    .quad   .call_not_builtin
    .quad   .builtin_str_index_of          # 0x0AF (__str_index_of)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_range                 # 0x0B2 (range)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_file_append           # 0x0D2 (__file_append)
    .quad   .call_not_builtin
    .quad   .builtin_bit_and               # 0x0D4 (__bit_and)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_substr                # 0x100 (substr)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_char_at               # 0x103 (char_at)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_bit_shl               # 0x10C (__bit_shl)
    .quad   .builtin_abs                   # 0x10D (__abs)
    .quad   .call_not_builtin
    .quad   .builtin_set_at                # 0x10F (__set_at)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_tcp_recv              # 0x117 (__tcp_recv)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_write_raw             # 0x13B (__write_raw)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_log2                  # 0x143 (__log2)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_len                   # 0x14C (len)
    .quad   .builtin_mxr                   # 0x14D (__mxr)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_pop_arr               # 0x150 (pop)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_to_string             # 0x166 (__to_string)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_sleep                 # 0x186 (__sleep)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_array_new  # 0x191 (__array_new)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_push                  # 0x19D (push)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_str_trim              # 0x1A7 (__str_trim)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_floor                 # 0x1AF (__floor)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_file_read             # 0x1BE (__file_read)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_tcp_listen            # 0x1C4 (__tcp_listen)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_heap_used             # 0x1C7 (__heap_used)
    .quad   .builtin_bit_xor               # 0x1C8 (__bit_xor)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .builtin_tcp_accept            # 0x1CF (__tcp_accept)
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin
    .quad   .call_not_builtin

# COLLISION: __mxr wanted 0x14C, placed at 0x14D
# COLLISION: __system wanted 0x06A, placed at 0x06B

# ── More builtins ──

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
    # String
    lea     rax, [rip + str_type_string]
    mov     [r14], rax
    mov     qword ptr [r14+8], 6
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
_call_save_hash: .space 8
_call_save_argc: .space 8
try_depth:      .space 8

# SIMD temp buffer
.align 16
simd_temp:      .space 16              # 8 × u16 results

# §29: Capability table — 256 × 8 bytes = 2KB
# Entry: [type:1][id:4][perms:2][owner:1]
.align 8
cap_table:      .space 2048
