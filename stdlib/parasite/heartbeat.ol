// ═══ Heartbeat — io_uring Async I/O ═══
// Organ 5 of BP12 Parasitic Kernel
// io_uring: kernel-level async I/O with near-zero overhead
// Syscalls: 425 (io_uring_setup), 426 (io_uring_enter)
// SQE = 64 bytes, CQE = 16 bytes

// ── Constants ──
// io_uring_setup flags
let IORING_SETUP_SQPOLL = 2;      // kernel thread polls SQ

// io_uring ops
let IORING_OP_NOP = 0;
let IORING_OP_READV = 1;
let IORING_OP_WRITEV = 2;
let IORING_OP_READ = 22;
let IORING_OP_WRITE = 23;
let IORING_OP_OPENAT = 18;
let IORING_OP_CLOSE = 19;
let IORING_OP_ACCEPT = 13;
let IORING_OP_CONNECT = 16;
let IORING_OP_SEND = 26;
let IORING_OP_RECV = 27;
let IORING_OP_POLL_ADD = 6;
let IORING_OP_TIMEOUT = 11;

// mmap offsets for io_uring
let IORING_OFF_SQ_RING = 0;
let IORING_OFF_CQ_RING = 134217728;    // 0x8000000
let IORING_OFF_SQES = 268435456;        // 0x10000000

// ── io_uring params struct layout (120 bytes) ──
// [sq_entries:4][cq_entries:4][flags:4][sq_thread_cpu:4]
// [sq_thread_idle:4][features:4][wq_fd:4][resv:12]
// [sq_off (40B)][cq_off (40B)]
// sq_off: [head:4][tail:4][ring_mask:4][ring_entries:4][flags:4][dropped:4][array:4][resv1:4][user_addr:8]
// cq_off: [head:4][tail:4][ring_mask:4][ring_entries:4][overflow:4][cqes:4][flags:4][resv1:4][user_addr:8]

// ── State ──
let uring_fd = [0 - 1];       // ring file descriptor
let uring_sq = [0];            // SQ ring mmap address
let uring_cq = [0];            // CQ ring mmap address
let uring_sqes = [0];          // SQE array mmap address
let uring_sq_mask = [0];       // SQ ring mask
let uring_cq_mask = [0];       // CQ ring mask
let uring_sq_tail = [0];       // current SQ tail
let uring_ready = [0];

// ── Setup io_uring ──
fn uring_setup(entries) {
    // Allocate params buffer (120 bytes) using mmap
    let params = __mmap(4096);  // 1 page for params
    if params == 0 { emit "uring: mmap failed"; return 0 - 1; };

    // Zero out params
    let zi = 0;
    while zi < 120 {
        __mem_write8(params, zi, 0);
        let zi = zi + 1;
    };

    // Write sq_entries
    __mem_write32(params, 0, entries);

    // syscall 425 = io_uring_setup(entries, params)
    let fd = __syscall(425, entries, params, 0, 0, 0, 0);
    if fd < 0 {
        emit "uring_setup failed: " + __to_string(fd);
        __munmap(params, 4096);
        return fd;
    };

    let _ = __set_at(uring_fd, 0, fd);

    // Read ring params
    let sq_entries_actual = __mem_read32(params, 0);
    let cq_entries_actual = __mem_read32(params, 4);

    // sq_off starts at offset 40 in params
    let sq_head_off = __mem_read32(params, 40);
    let sq_tail_off = __mem_read32(params, 44);
    let sq_ring_mask_off = __mem_read32(params, 48);
    let sq_ring_entries_off = __mem_read32(params, 52);
    let sq_array_off = __mem_read32(params, 64);

    // cq_off starts at offset 80 in params
    let cq_head_off = __mem_read32(params, 80);
    let cq_tail_off = __mem_read32(params, 84);
    let cq_ring_mask_off = __mem_read32(params, 88);
    let cq_cqes_off = __mem_read32(params, 96);

    // mmap SQ ring
    let sq_ring_sz = sq_array_off + sq_entries_actual * 4;
    let sq = __syscall(9, 0, sq_ring_sz, 3, 1, fd, 0);  // mmap(NULL, sz, PROT_RW, MAP_SHARED, fd, IORING_OFF_SQ_RING)
    let _ = __set_at(uring_sq, 0, sq);

    // mmap CQ ring
    let cq_ring_sz = cq_cqes_off + cq_entries_actual * 16;
    let cq = __syscall(9, 0, cq_ring_sz, 3, 1, fd, IORING_OFF_CQ_RING);
    let _ = __set_at(uring_cq, 0, cq);

    // mmap SQEs
    let sqes_sz = sq_entries_actual * 64;
    let sqes = __syscall(9, 0, sqes_sz, 3, 1, fd, IORING_OFF_SQES);
    let _ = __set_at(uring_sqes, 0, sqes);

    // Read ring masks
    let _ = __set_at(uring_sq_mask, 0, __mem_read32(sq, sq_ring_mask_off));
    let _ = __set_at(uring_cq_mask, 0, __mem_read32(cq, cq_ring_mask_off));

    // Read initial tail
    let _ = __set_at(uring_sq_tail, 0, __mem_read32(sq, sq_tail_off));

    let _ = __set_at(uring_ready, 0, 1);
    __munmap(params, 4096);

    emit "uring: fd=" + __to_string(fd) + " sq=" + __to_string(sq_entries_actual) + " cq=" + __to_string(cq_entries_actual);
    return fd;
};

// ── Submit NOP (simplest test) ──
fn uring_submit_nop() {
    if __array_get(uring_ready, 0) == 0 { return 0 - 1; };
    let sqes = __array_get(uring_sqes, 0);
    let sq = __array_get(uring_sq, 0);
    let mask = __array_get(uring_sq_mask, 0);
    let tail = __array_get(uring_sq_tail, 0);
    let idx = __bit_and(tail, mask);

    // Write SQE at sqes + idx*64
    let sqe_addr = sqes + idx * 64;
    __mem_write8(sqe_addr, 0, IORING_OP_NOP);  // opcode
    __mem_write8(sqe_addr, 1, 0);                // flags
    // user_data at offset 32
    __mem_write32(sqe_addr, 32, 42);             // marker

    // Update SQ array: sq_array[idx] = idx
    // sq_array_off is typically at offset 64+
    // For simplicity, write to sq_ring + array_off + idx*4
    // We assume array starts right after the ring header

    // Increment tail
    let new_tail = tail + 1;
    let _ = __set_at(uring_sq_tail, 0, new_tail);
    // Write tail to ring (offset 4 in sq ring = tail)
    __mem_write32(sq, 4, new_tail);

    // Submit: syscall 426 = io_uring_enter(fd, to_submit, min_complete, flags, sig, sigsz)
    let ret = __syscall(426, __array_get(uring_fd, 0), 1, 0, 0, 0, 0);
    return ret;
};

// ── Poll completions ──
fn uring_poll() {
    if __array_get(uring_ready, 0) == 0 { return 0 - 1; };
    let cq = __array_get(uring_cq, 0);
    let mask = __array_get(uring_cq_mask, 0);

    // Read head and tail
    let head = __mem_read32(cq, 0);  // cq_head at offset 0
    let tail = __mem_read32(cq, 4);  // cq_tail at offset 4

    if head == tail { return 0; };  // no completions

    let count = [0];
    while head != tail {
        let idx = __bit_and(head, mask);
        // CQE at cq + cqes_offset + idx*16
        // cqes_offset is typically at offset in cq_off struct
        // CQE: [user_data:8][res:4][flags:4]
        let head = head + 1;
        let _ = __set_at(count, 0, __array_get(count, 0) + 1);
    };

    // Update head
    __mem_write32(cq, 0, head);
    return __array_get(count, 0);
};

// ── Cleanup ──
fn uring_destroy() {
    if __array_get(uring_fd, 0) >= 0 {
        __fd_close(__array_get(uring_fd, 0));
        let _ = __set_at(uring_fd, 0, 0 - 1);
        let _ = __set_at(uring_ready, 0, 0);
    };
};

emit "heartbeat loaded";
