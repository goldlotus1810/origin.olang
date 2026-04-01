// ═══ heartbeat.ol — io_uring Async I/O Engine ═══
// Organ 5 of BP12 Parasitic Kernel
// Nox heartbeat: async read/write/accept/send/recv — zero syscall per I/O
// Syscalls: 425 (io_uring_setup), 426 (io_uring_enter)
// SQE = 64 bytes, CQE = 16 bytes
// Reference: docs/references/io_uring.h, io_uring_guide.pdf
//
// Key insight from io_uring_guide.pdf:
//   SQ ring + CQ ring = shared memory between app and kernel
//   App writes SQE, increments tail → kernel reads, processes, writes CQE
//   With SQPOLL: kernel thread polls SQ → ZERO syscalls for submission
//   This is Nox's heartbeat — always pumping I/O without blocking

// ── Opcodes (from io_uring.h enum io_uring_op) ──
let IO_NOP = 0;
let IO_READ = 22;
let IO_WRITE = 23;
let IO_SEND = 26;
let IO_RECV = 27;
let IO_ACCEPT = 13;
let IO_CONNECT = 16;
let IO_OPENAT = 18;
let IO_CLOSE = 19;
let IO_TIMEOUT = 11;
let IO_SOCKET = 45;

// ── State ──
let _io_fd = [0 - 1];
let _io_sq = [0];     // SQ ring base
let _io_cq = [0];     // CQ ring base
let _io_sqes = [0];   // SQE array base
let _io_sq_mask = [0];
let _io_cq_mask = [0];
let _io_sq_tail_off = [0];   // offset of tail in SQ ring
let _io_cq_head_off = [0];   // offset of head in CQ ring
let _io_cq_tail_off = [0];   // offset of tail in CQ ring
let _io_cq_cqes_off = [0];   // offset of CQEs in CQ ring
let _io_sq_array_off = [0];  // offset of array in SQ ring
let _io_local_sq_tail = [0];
let _io_local_cq_head = [0];

// ═══ SETUP ═══
fn io_setup(entries) {
    let params = __mmap(4096);
    // Zero
    let i = 0; while i < 256 { __mem_write8(params, i, 0); let i = i + 1; };

    let fd = __syscall(425, entries, params, 0, 0, 0, 0);
    if fd < 0 { __munmap(params, 4096); return fd; };
    let _ = __set_at(_io_fd, 0, fd);

    // Read params
    let sq_entries = __mem_read32(params, 0);
    let cq_entries = __mem_read32(params, 4);

    // SQ offsets (at params + 40)
    let sq_head_off = __mem_read32(params, 40);
    let sq_tail_off = __mem_read32(params, 44);
    let sq_mask_off = __mem_read32(params, 48);
    let sq_array_off = __mem_read32(params, 64);
    let _ = __set_at(_io_sq_tail_off, 0, sq_tail_off);
    let _ = __set_at(_io_sq_array_off, 0, sq_array_off);

    // CQ offsets (at params + 80)
    let cq_head_off = __mem_read32(params, 80);
    let cq_tail_off = __mem_read32(params, 84);
    let cq_mask_off = __mem_read32(params, 88);
    let cq_cqes_off = __mem_read32(params, 100);
    let _ = __set_at(_io_cq_head_off, 0, cq_head_off);
    let _ = __set_at(_io_cq_tail_off, 0, cq_tail_off);
    let _ = __set_at(_io_cq_cqes_off, 0, cq_cqes_off);

    // mmap SQ ring
    let sq_sz = sq_array_off + sq_entries * 4;
    let sq = __syscall(9, 0, sq_sz, 3, 1, fd, 0);
    let _ = __set_at(_io_sq, 0, sq);
    let _ = __set_at(_io_sq_mask, 0, __mem_read32(sq, sq_mask_off));

    // mmap CQ ring (offset 0x8000000)
    let cq_sz = cq_cqes_off + cq_entries * 16;
    let cq = __syscall(9, 0, cq_sz, 3, 1, fd, 134217728);
    let _ = __set_at(_io_cq, 0, cq);
    let _ = __set_at(_io_cq_mask, 0, __mem_read32(cq, cq_mask_off));

    // mmap SQEs (offset 0x10000000)
    let sqe_sz = sq_entries * 64;
    let sqes = __syscall(9, 0, sqe_sz, 3, 1, fd, 268435456);
    let _ = __set_at(_io_sqes, 0, sqes);

    // Read initial tail/head
    let _ = __set_at(_io_local_sq_tail, 0, __mem_read32(sq, sq_tail_off));
    let _ = __set_at(_io_local_cq_head, 0, __mem_read32(cq, cq_head_off));

    __munmap(params, 4096);
    return fd;
};

// ═══ SUBMIT SQE ═══
fn io_prep(opcode, fd, buf_addr, length, offset, user_data) {
    let sqes = __array_get(_io_sqes, 0);
    let mask = __array_get(_io_sq_mask, 0);
    let tail = __array_get(_io_local_sq_tail, 0);
    let idx = __bit_and(tail, mask);
    let sqe = idx * 64;

    // Zero SQE first (64 bytes)
    let zi = 0; while zi < 64 { __mem_write8(sqes, sqe + zi, 0); let zi = zi + 1; };

    // Fill SQE
    __mem_write8(sqes, sqe, opcode);                // opcode
    __mem_write32(sqes, sqe + 4, fd);               // fd
    // offset (u64) at +8
    __mem_write32(sqes, sqe + 8, offset % 4294967296);
    __mem_write32(sqes, sqe + 12, __floor(offset / 4294967296));
    // addr (u64) at +16
    __mem_write32(sqes, sqe + 16, buf_addr % 4294967296);
    __mem_write32(sqes, sqe + 20, __floor(buf_addr / 4294967296));
    // len at +24
    __mem_write32(sqes, sqe + 24, length);
    // user_data (u64) at +32
    __mem_write32(sqes, sqe + 32, user_data);

    // Update SQ array
    let sq = __array_get(_io_sq, 0);
    let arr_off = __array_get(_io_sq_array_off, 0);
    __mem_write32(sq, arr_off + idx * 4, idx);

    // Advance tail
    let _ = __set_at(_io_local_sq_tail, 0, tail + 1);
    // Write tail to ring (kernel reads this)
    __mem_write32(sq, __array_get(_io_sq_tail_off, 0), tail + 1);

    return idx;
};

fn io_submit(count) {
    // io_uring_enter(fd, to_submit, min_complete, flags, sig)
    return __syscall(426, __array_get(_io_fd, 0), count, 0, 0, 0, 0);
};

fn io_submit_and_wait(count) {
    // Submit and wait for at least 1 completion
    return __syscall(426, __array_get(_io_fd, 0), count, 1, 1, 0, 0);  // flags=IORING_ENTER_GETEVENTS=1
};

// ═══ POLL COMPLETIONS ═══
fn io_poll() {
    // Returns: [user_data, result] or [0, 0] if no completion
    let cq = __array_get(_io_cq, 0);
    let head = __array_get(_io_local_cq_head, 0);
    let tail = __mem_read32(cq, __array_get(_io_cq_tail_off, 0));

    if head == tail { return 0; };  // empty

    let mask = __array_get(_io_cq_mask, 0);
    let cqe_base = __array_get(_io_cq_cqes_off, 0);
    let cqe_off = cqe_base + __bit_and(head, mask) * 16;

    // CQE: [user_data:8][res:4][flags:4]
    let user_data = __mem_read32(cq, cqe_off);
    let result = __mem_read32(cq, cqe_off + 8);

    // Advance head
    let _ = __set_at(_io_local_cq_head, 0, head + 1);
    __mem_write32(cq, __array_get(_io_cq_head_off, 0), head + 1);

    // Pack into single return: user_data * 65536 + (result & 0xFFFF)
    // Or just return result (caller tracks user_data separately)
    return result;
};

// ═══ HIGH-LEVEL OPS ═══
fn io_read(fd, buf, len) {
    io_prep(IO_READ, fd, buf, len, 0, fd);
    return io_submit_and_wait(1);
};

fn io_write(fd, buf, len) {
    io_prep(IO_WRITE, fd, buf, len, 0, fd);
    return io_submit_and_wait(1);
};

// ═══ CLEANUP ═══
fn io_close() {
    if __array_get(_io_fd, 0) >= 0 {
        __fd_close(__array_get(_io_fd, 0));
        let _ = __set_at(_io_fd, 0, 0 - 1);
    };
};

emit "heartbeat.ol loaded — io_uring ready";
