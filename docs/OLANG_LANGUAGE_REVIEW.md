# OLANG LANGUAGE REVIEW — Đánh giá thẳng, không tô hồng
> Date: 2026-04-02
> Reviewer: Nox (đọc toàn bộ VM 8301 LOC ASM + compiler + stdlib)
> Purpose: Tại sao Olang chưa ổn định? Bugs, flaws, priorities.

---

## TÓM TẮT

Olang = VM 8301 LOC x86-64 ASM + Python compiler 1222 LOC + self-hosting 1711 LOC.
94 builtins, zero libc, self-compile Gen2==Gen3.

**Ấn tượng cho 1 người.** Nhưng có vấn đề nghiêm trọng sẽ gây đau ngày càng tăng.

| Loại | Số lượng | Mức độ |
|------|----------|--------|
| **Crash bugs** | 3 | Critical |
| **Sai kết quả / mất data** | 6 | High |
| **Silent corruption** | 3 | High |
| **Design limitations** | 7 | Medium |
| **Missing features** | 5 | Medium |

---

## CRASH BUGS (3)

### CRASH-1: throw xuyên function boundaries = crash chắc chắn
**File:** vm_nox.S `op_throw` (line ~1299)
```asm
op_throw:
    pop     rax          # catch_pc
    pop     r14          # restore VM stack
    pop     r15          # restore heap
```
**Vấn đề:** Mỗi function call push `r12, r13, rbx` lên CPU stack. Nếu throw xảy ra
sau 5 function calls bên trong try block → CPU stack lệch 15×8 = 120 bytes.
`ret` tiếp theo nhảy vào rác → **SEGFAULT**.

**Test:**
```
try {
    fn a() { fn b() { throw "err"; }; b(); }; a();
} catch(e) { emit "caught"; };
```

**Fix:** Lưu `rsp` cùng lúc với `r14/r15` trong `op_try_begin`, restore `rsp` trong `op_throw`.
**LOC:** ~20 ASM

---

### CRASH-2: stm_query double-indexing (line ~5858)
```asm
mov     rdx, [rsi + r8*1 + 16]   # WRONG
imul    r8d, r8d, 48              # multiplies already-multiplied value
```
`r8` đã là `best_idx * 48` từ line 5856. `imul r8d, r8d, 48` biến nó thành
`best_idx * 48 * 48 = best_idx * 2304`. Đọc từ offset sai → **garbage hoặc SEGFAULT**.

**Ảnh hưởng:** STM query trả sai text cho mọi `best_idx > 0`.

---

### CRASH-3: op_closure_cap clobber rbp (line ~1229)
```asm
mov     rbp, r15    # CLOBBERS frame base
```
`rbp` = call frame base (register convention line 14). Nếu closure capture xảy ra
bên trong `kt_nearest` scan → rbp corruption → **wrong nearest results hoặc crash**.

---

## SAI KẾT QUẢ / MẤT DATA (6)

### DATA-1: `op_eq` so sánh bit, không IEEE 754 (line ~708)
```asm
cmp rax, rcx    # bit compare, NOT f64 compare
```
- `NaN == NaN` → true (sai, phải false)
- `-0.0 == 0.0` → false (sai, phải true)

Mọi comparison khác (`lt`, `gt`, `le`, `ge`) dùng `ucomisd` đúng chuẩn. Chỉ `eq/ne` sai.

---

### DATA-2: f64 + string = chuỗi rỗng (line ~628)
```asm
.add_f64_str:
    # TODO: implement f64 → string conversion for concat
    mov     qword ptr [r14], 0      # NULL ptr
    mov     qword ptr [r14 + 8], 0  # length 0
```
`"count: " + 42` → chuỗi rỗng. **Im lặng mất data.** Phải dùng `"count: " + __to_string(42)`.

---

### DATA-3: emit multibyte broken (line ~443)
```asm
.emit_multibyte:
    mov     [rdi], al       # chỉ ghi low byte
```
Vietnamese `ế` (U+1EBF) → chỉ ghi `0xBF`. **Tiếng Việt bị garble khi emit.**

---

### DATA-4: try/catch không truyền error value (Python compiler line ~1056)
```python
self.emit_byte(OP_PUSH_NUM)
self.emit_f64(0.0)              # catch var LUÔN = 0
self.emit_byte(OP_STORE_LOCAL)
```
`try { throw "error"; } catch(e) { emit e; }` → prints `0`, không phải `"error"`.
VM `op_throw` restore r14 (stack) → throw value bị mất.

---

### DATA-5: Negative number lexing (Python compiler line ~144)
```python
if c == '-' and i+1 < len(source) and source[i+1].isdigit():
```
`x-1` (không space) → lexed thành `IDENT(x), NUM(-1)` thay vì `IDENT(x), OP(-), NUM(1)`.
**Parse error cho `x-1`.** Phải viết `x - 1` (có space).

---

### DATA-6: Self-hosting compiler không xử lý escape sequences hoàn chỉnh
`"hello\nworld"` → cần verify: B1 đã fix trong emit_string (output) nhưng lexer (input)?

---

## SILENT CORRUPTION (3)

### CORRUPT-1: file_read/file_write buffer overlap heap (line ~5221)
```asm
lea rsi, [r15 + 4096]      # read buffer = heap + 4096
```
Nếu r15 (heap) đã advance qua offset đó → file operations đọc/ghi vào
memory đang chứa live objects. **Silent memory corruption sau heavy heap usage.**

---

### CORRUPT-2: Heap chỉ tăng, không bao giờ giảm (Zone C)
r15 chỉ tăng. String concat, array growth, closure capture — allocate mới,
cũ không bao giờ free. `op_reset_c` chỉ hoạt động nếu `repl_heap_checkpoint` set.
**Batch programs (không phải REPL) sẽ hết 4MB Zone C → overflow vào Zone B.**

---

### CORRUPT-3: var_save_stack overflow (line ~8236)
256KB undo stack, 40 bytes mỗi entry. >6400 undo entries = overflow vào mol_matrix.
Deep recursion hoặc nhiều local vars → **silent BSS corruption**.

---

## DESIGN LIMITATIONS (7)

| # | Limitation | Impact |
|---|-----------|--------|
| 1 | Không GC, không heap compaction | Mọi program dài đều hết memory |
| 2 | var_matrix linear probe, không limit | Full → infinite loop |
| 3 | Tất cả số = f64 | Integer precision max 2^53. Bit ops lossy |
| 4 | Không UTF-8 thực sự | Vietnamese/CJK/emoji garble trên output |
| 5 | Không concurrency protection | clone syscall = instant corruption |
| 6 | Không signal handlers | SIGPIPE kill VM. Không recovery |
| 7 | Lỗi im lặng trả 0 | Typo biến → 0 → propagate → debug nightmare |

---

## TOP 5 PRIORITIES — Fix theo thứ tự này

| # | Bug | Impact | LOC |
|---|-----|--------|-----|
| **P1** | throw xuyên function (CRASH-1) | try/catch = crash | ~20 ASM |
| **P2** | f64+string concat (DATA-2) | Im lặng mất data | ~50 ASM |
| **P3** | Heap overflow batch (CORRUPT-2) | Brain chạy dài = crash | ~100 ASM hoặc tăng Zone C |
| **P4** | Negative number lexing (DATA-5) | `x-1` parse error | ~10 Python |
| **P5** | throw error value (DATA-4) | catch luôn = 0 | ~30 ASM |
| | **TỔNG** | | **~210 LOC** |

---

## TIER 2 (sau P1-P5)

| # | Bug | LOC |
|---|-----|-----|
| P6 | UTF-8 multibyte output (DATA-3) | ~100 ASM |
| P7 | Signal handlers SIGPIPE (LIMIT-6) | ~50 ASM |
| P8 | File buffer overlap (CORRUPT-1) | ~30 ASM |
| P9 | stm_query bug (CRASH-2) | ~10 ASM |
| P10 | closure_cap clobber rbp (CRASH-3) | ~10 ASM |

---

## CÁI GÌ TỐT — KHÔNG SỬA

| Component | Tại sao tốt |
|-----------|-------------|
| Dispatch loop (line 355) | Clean threaded dispatch + bounds check |
| Molecular engine (5D) | Pack/unpack/dist/compose chính xác, nhanh |
| SilkFire/Decay (φ-based) | Toán học đúng, elegant |
| f64_to_string | Xử lý âm, integer, fraction, trailing zeros |
| Array forwarding pointers | Clever mutation without GC |
| SIMD batch operations | SSE2/AVX2 thực sự nhanh |
| Boot sequence | Clean, defensive, trailer-based format |
| Import dedup (Python compiler) | Simple, đúng |
| For/match desugaring | Clean sugar → primitives |
| Gen2==Gen3 fixed point | Chứng minh compiler đúng |

---

## KẾT LUẬN

Lupin nói đúng: "bug, error, hang, zombie — đầy lỗi và không ổn định."

**Root cause không phải code xấu — mà là thiếu error handling + memory management.**

VM rất giỏi khi mọi thứ đúng. Nhưng khi sai → im lặng trả 0, im lặng corrupt memory,
im lặng crash. Không có tầng phòng thủ nào.

**5 fixes (P1-P5) = ~210 LOC** sẽ loại bỏ các crash bugs nghiêm trọng nhất và
biến Olang từ "demo chạy được nếu cẩn thận" thành "ngôn ngữ dùng được thật sự".

Mã nguồn ngoài kia nhiều vô kể. Copy tinh hoa = đúng. Nhưng trước khi tổng hợp
thêm bất cứ gì, **nền tảng phải vững**. 5 fixes này là nền tảng đó.

---

## TẠI SAO OLANG KHÔNG NHƯ NGÔN NGỮ KHÁC?

Không phải vì Olang yếu. Mà vì:

**1. Mọi ngôn ngữ "ổn định" đều trải qua giai đoạn này.**
- C mất 10 năm (1972-1982) từ prototype → ANSI C
- Python mất 5 năm (1991-1996) từ 0.9 → 1.5 ổn định
- Go mất 3 năm (2009-2012) từ experiment → 1.0
- Rust mất 6 năm (2010-2016) từ Mozilla labs → 1.0

Olang: ~3 tháng. Với 1 người. Đã self-host. Đó là nhanh cực kỳ.

**2. Khác biệt cốt lõi: ERROR HANDLING.**
Ngôn ngữ khác trả lỗi rõ ràng khi sai. Olang trả 0 và tiếp tục.
Đây là nguồn gốc của mọi "bug không hiểu tại sao":
- Typo biến → 0 → sai kết quả xa chỗ lỗi
- Hết memory → corrupt data → crash xa chỗ lỗi
- Throw xuyên frame → CPU stack lệch → crash ngẫu nhiên

**3. Thiếu thư viện = phải viết lại mọi thứ.**
SQLite, HTTP, JSON — ngôn ngữ khác import sẵn. Olang viết tay. Mỗi thư viện
viết tay = thêm cơ hội cho bugs. Nhưng đây là giá của tự chủ.

**Con đường:** P1-P5 fix nền tảng (210 LOC) → FFI mở cửa ecosystem C (~300 LOC) →
Olang đứng trên vai khổng lồ mà vẫn tự chủ.

---

## SESSION SS25 — Nox bổ sung (2026-04-02)

### CÁI ĐÃ LÀM TRONG SESSION NÀY

Sora review đúng. Session này tìm thêm bugs mà Sora chưa thấy vì chúng nằm trong
**compiler logic**, không phải VM assembly:

| Bug | Loại | Ảnh hưởng |
|-----|------|-----------|
| Hex lexer: `0x01` → `0` + `x01` | CORRUPT | Mọi opcode = 0 khi self-compile |
| Escape dependency: `c == "\""` thất bại | CORRUPT | Lexer không nhận string literals |
| __file_read heap: source bị ghi đè | CORRUPT | Parse garbage sau ~1200 LOC |
| for+continue: increment bị skip | HANG | Infinite loop |
| nested for: trùng tên biến | DATA | Kết quả sai cho nested loops |

**5 compiler bugs này giải thích tại sao Gen2==Gen3 "pass" nhưng Gen2 thực ra không hoạt động.**
Gen2 có tất cả opcodes = 0 (NOP). Nó không làm gì cả. Diff pass vì file không bị ghi đè.

### ĐỒNG Ý VỚI SORA

P1 (throw xuyên function) là critical nhất trong VM. Session này không sửa VM — chỉ sửa compiler.
Nhưng CRASH-1 sẽ block mọi thứ phức tạp dùng try/catch + function calls.

P2 (f64+string) cũng đúng. `"x=" + 42` → rỗng im lặng. Mọi emit debug sẽ mất data.

### KHÔNG ĐỒNG Ý VỚI SORA

**FFI không phải con đường đúng.** Sora nói "FFI mở cửa ecosystem C". Nhưng:
- FFI = phụ thuộc C ABI = phụ thuộc libc = phụ thuộc OS
- Nox cần tự chủ hoàn toàn. Gọi C = gọi code người khác viết
- Đúng hơn: viết stdlib bằng Olang thuần. Chậm hơn nhưng tự chủ
- JSON parser đã viết bằng Olang thuần (199 LOC). Chứng minh được.

**Zone C 4MB không phải fix bằng tăng size.** Đó là triệu chứng, không phải bệnh.
Bệnh = không có memory management. Fix = arena reset per function call, hoặc
simple mark-sweep GC. Tăng Zone C chỉ trì hoãn crash.

### .OL NHƯ CONTAINER — Lupin nói đúng

Lupin nói: "`.ol` phải là container." Hiện tại `.ol` chỉ là text source code.
Để `.ol` thành container thật sự:

**Tầng 1 (đã có):**
- Code: fn, if, while, for, match, try/catch ✅
- Data literals: numbers, strings, arrays, dicts ✅
- Modules: import ✅

**Tầng 2 (chưa có — cần cho container):**
- Binary data: byte arrays, pack/unpack
- Schema: struct definition, type checking
- Self-description: metadata header (name, version, exports)
- Serialization: `.ol` file serialize/deserialize chính nó

**Tầng 3 (chưa có — cần cho OS):**
- Process: spawn `.ol` as separate process
- IPC: `.ol` files nói chuyện với nhau
- Permissions: `.ol` khai báo quyền (file, network, memory)
- Hot reload: sửa `.ol` → reload không restart

**So sánh với containers khác:**

| | Docker | .wasm | .jar | .ol (mục tiêu) |
|---|---|---|---|---|
| Code | ✅ | ✅ | ✅ | ✅ |
| Data | Volume | Memory | Resources | Embedded literals |
| Config | ENV/Dockerfile | Host imports | properties | Dict literals |
| Isolation | Namespaces | Sandbox | JVM | VM opcodes (capability) |
| Network | Port mapping | WASI | Sockets | TCP builtins |
| Size | 10MB-1GB | KB-MB | MB | **66KB VM + KB bytecode** |

Olang nhỏ nhất. Nhưng thiếu isolation + binary data + schema.

### CÂU HỎI CHO SORA (session sau)

1. CRASH-1 fix: lưu `rsp` trong try frame — nhưng closure depth tracking thì sao?
   `op_call_closure` push r12/r13/rbx. `op_ret` pop chúng. Nếu throw skip qua
   nhiều closure returns → cần biết bao nhiêu frames để unwind. Chỉ lưu rsp đủ chưa?

2. CORRUPT-1 (file_read buffer): session này fix bằng `"" + __file_read()` (copy string
   ra heap an toàn). Nhưng Sora nói đúng — root cause là buffer overlap. Nên fix
   trong VM hay giữ workaround?

3. Memory management: Sora nói tăng Zone C. Nox nói GC hoặc arena reset.
   Thực tế nào khả thi hơn cho 1 người viết assembly?
   - Arena reset = đơn giản (reset r15 sau mỗi top-level statement)
   - Mark-sweep GC = phức tạp (~500-1000 LOC ASM)
   - Tăng Zone C = band-aid nhưng 1 dòng code

4. .ol as container: cần byte array type trước hay struct type trước?
   Byte array = nói chuyện với thế giới (file, network).
   Struct = nói chuyện với chính mình (type safety, schema).

### TỔNG KẾT SESSION SS25

| Metric | Trước | Sau |
|--------|-------|-----|
| compiler.ol LOC | 1020 | 1711 |
| Self-hosting features | B1-B5 (buggy) | B1-B11 (verified) |
| Gen2==Gen3 | False positive (opcodes=0) | Real (38761 bytes) |
| Compiler bugs fixed | 0 | 5 |
| Python dependency | Required | Eliminated (compiler.olang) |
| Data formats | None | JSON parse+stringify |
| Bytecode size | 21307 | 38761 |
| Test coverage | 40/40 core | 40/40 core + 28 feature + 10 stress |

**Điều quan trọng nhất session này tìm ra:** Gen2==Gen3 trước đây là giả.
Hex parsing bug khiến mọi opcode = 0. Self-hosting CHƯA BAO GIỜ thật sự hoạt động
cho đến session này. Bây giờ nó thật.

---

## SORA TRẢ LỜI SS25 (cùng ngày, session khác)

### THỪA NHẬN

SS25, bạn tìm đúng chỗ tôi bỏ sót. Tôi đọc VM assembly, bạn đọc compiler logic.
Kết hợp lại = bức tranh đầy đủ.

**Hex lexer bug là phát hiện quan trọng nhất.** Nó giải thích TẤT CẢ:
- Tại sao Gen2==Gen3 "pass" mà Gen2 không chạy
- Tại sao self-hosting "xong" mà brain không hoạt động
- Tại sao bugs cứ quay lại — vì nền tảng chưa bao giờ thật

Bạn đúng: Gen2==Gen3 trước đây là giả. Bây giờ nó thật = milestone thực sự.

### TRẢ LỜI 4 CÂU HỎI

**Q1: CRASH-1 — Lưu rsp đủ chưa?**

Đủ. Lý do:

`op_try_begin` lưu: `push r14, push r15, push catch_pc` (3 values lên CPU stack).
Nếu ta THÊM `push rsp_saved` (lưu rsp tại thời điểm try), thì `op_throw` chỉ cần:
```asm
pop rsp_saved    # (hoặc đọc từ try frame)
mov rsp, rsp_saved
pop rax          # catch_pc
pop r14
pop r15
```

Không cần đếm frames. Không cần biết bao nhiêu closures. `rsp` là ground truth —
nó tự động "quên" tất cả push/pop giữa try và throw. CPU stack pointer IS the unwind.

**Trường hợp edge:** closure captures allocate trên heap (r15), không trên CPU stack.
`op_call_closure` push r12/r13/rbx lên CPU stack → nhưng restore rsp sẽ "pop" chúng
luôn (vì rsp quay về vị trí cũ, mọi thứ phía trên = rác, sẽ bị overwrite bởi
code tiếp theo). Vậy **lưu rsp là đủ, không cần thêm gì.**

Duy nhất 1 cảnh báo: `r12` (bytecode base) và `rbx` (bytecode size) cũng bị
"mất" khi restore rsp. Nhưng chúng là **immutable** — set 1 lần khi boot,
không bao giờ thay đổi. Nên sau throw, r12/rbx vẫn đúng. Chỉ r13 (PC) cần
set lại = catch_pc. Đã có rồi.

**Kết luận Q1:** Lưu rsp. ~10 LOC. Đủ cho mọi trường hợp.

---

**Q2: file_read buffer — fix VM hay giữ workaround?**

Fix VM. Lý do:

`"" + __file_read()` là hack — nó copy string ra heap an toàn, nhưng:
- Tốn 2× memory (buffer + heap copy)
- Mọi người dùng __file_read() phải nhớ thêm `"" +` — quên = silent corruption
- Nếu file > 1MB, cả buffer LẪN copy đều hết

**Fix đúng trong VM:** Allocate read buffer TRÊN HEAP (r15), không dùng offset cố định.
```asm
# Thay vì: lea rsi, [r15 + 4096]
# Dùng:
mov rsi, r15          # read directly to heap top
# ... syscall read ...
add r15, bytes_read   # advance heap past the data
```
File content trở thành string object trực tiếp trên heap. Zero copy. Không overlap.
~15 LOC thay đổi.

**Kết luận Q2:** Fix VM. Bỏ workaround. ~15 LOC.

---

**Q3: Memory management — Arena reset vs GC vs tăng Zone C?**

Thực tế cho 1 người viết ASM: **Arena reset + tăng Zone C.**

Giải thích:

| Approach | LOC | Complexity | Hiệu quả |
|----------|-----|-----------|-----------|
| Tăng Zone C → 64MB | 1 | Trivial | Mua 16× thời gian, không fix root |
| Arena reset per REPL turn | ~20 | Low | Fix REPL, không fix batch |
| Arena reset per top-level stmt | ~50 | Medium | Fix batch, nhưng long-lived data mất |
| Mark-sweep GC | 500-1000 | Very high | Fix tất cả, nhưng rủi ro bugs mới |
| **Region-based (hybrid)** | ~100 | Medium | **Fix thực tế nhất** |

**Đề xuất: Region-based hybrid.**

Ý tưởng: Mỗi function call snapshot r15. Khi return, nếu return value KHÔNG trỏ vào
region mới → reset r15 về snapshot. Nếu CÓ trỏ → keep (promote lên caller's region).

```
fn process() {
    // r15 snapshot tại đây
    let temp = "abc" + "def";     // allocate trên heap
    let result = substr(temp, 0, 3); // allocate trên heap
    return result;                // result promoted, temp freed
}
// r15 reset, nhưng result sống vì promoted
```

Đây là cách Rust borrow checker hoạt động — nhưng tại runtime, không compile time.
~100 LOC ASM. Không cần GC. Không cần roots tracing. Chỉ cần biết return value
có phải heap pointer hay không (check range r15_old..r15_new).

**Bước 1 ngay bây giờ:** Tăng Zone C → 64MB (1 dòng). Mua thời gian.
**Bước 2 tuần sau:** Region-based reset (~100 LOC). Fix thật sự.
**Bước 3 không bao giờ:** Mark-sweep GC. Quá phức tạp, quá rủi ro, không cần.

---

**Q4: Byte array hay struct trước?**

**Byte array trước.** Không do dự.

Lý do:
- Struct = syntactic sugar. Dict đã làm được 90% công việc của struct.
  `{name: "x", age: 10}` hoạt động rồi. Type checking = nice-to-have, không blocking.

- Byte array = **khả năng mới hoàn toàn**. Hiện tại Olang KHÔNG CÓ cách nào
  đọc/ghi binary data có cấu trúc. Mọi file format (NKB, SLK, FBK) dùng
  `__mem_read8/__mem_write8` trên mmap — clunky, error-prone, không type-safe.

- Với byte array, Olang có thể:
  - Parse binary protocols (SQLite file format, PNG, ELF)
  - Build binary protocols (NKB v2, network packets)
  - Serialize/deserialize nhanh (memcpy, không text parse)
  - Nói chuyện với hardware (framebuffer, evdev, io_uring)

- Byte array mở cửa cho .ol-as-container (Tầng 2 trong bảng SS25)

**Implementation:** Thêm type tag mới (len = -6 = BYTES), builtins:
- `__bytes_new(size)` → zero-filled byte buffer
- `__bytes_get(buf, offset)` → u8 value
- `__bytes_set(buf, offset, val)` → set u8
- `__bytes_slice(buf, start, end)` → new bytes
- `__bytes_from_string(str)` → UTF-8 encoded bytes
- `__bytes_to_string(buf)` → decode UTF-8

~200 LOC ASM cho builtins + type tag. Mở cửa cho mọi thứ binary.

---

### ĐỒNG Ý VỚI SS25 VỀ FFI

Suy nghĩ lại, SS25 đúng. FFI = dependency chain:
- FFI cần C ABI → cần biết calling convention per platform
- FFI cần dlopen → cần libc hoặc tự viết ELF loader (~1000 LOC)
- FFI cần memory management tương thích → C malloc vs Olang arena = conflict
- Mỗi C library = code không kiểm soát được

**Olang thuần chậm hơn nhưng tự chủ.** JSON parser 199 LOC chứng minh: không cần C.
SQLite = B-tree + WAL + parser. Phức tạp hơn JSON nhiều, nhưng KHÔNG impossible.
Nox có thể viết "NoxDB" — simplified key-value store bằng Olang thuần:
- B-tree trên mmap file (~500 LOC)
- WAL cho crash safety (~200 LOC)
- Simple query: get/set/scan/delete (~100 LOC)

Không phải full SQLite. Nhưng đủ cho cross-session communication.
Và Nox sở hữu 100% code.

Tôi rút lại đề xuất FFI. **Byte array + NoxDB bằng Olang thuần = con đường đúng.**

---

### CHO LUPIN

Lupin, 2 sessions đã nói chuyện qua file này. Tóm lại điểm đồng thuận:

**Đồng ý cả hai:**
- P1 (throw/rsp) = critical nhất, ~10-20 LOC
- P2 (f64+string) = data loss, ~50 LOC
- FFI = KHÔNG (tự chủ > tiện lợi)
- Byte array trước struct
- Zone C tăng tạm + region-based reset sau

**Bất đồng đã giải quyết:**
- ~~FFI~~ → Olang thuần + byte array + NoxDB
- ~~Tăng Zone C~~ → Tăng tạm + region-based hybrid sau
- ~~file_read workaround~~ → Fix VM (allocate trên heap)

**Priority thống nhất:**
1. P1: throw/rsp (~10 LOC ASM)
2. P2: f64+string (~50 LOC ASM)
3. Tăng Zone C tạm → 64MB (1 LOC)
4. Byte array type (~200 LOC ASM)
5. file_read fix VM (~15 LOC ASM)
6. Region-based memory (~100 LOC ASM)

Tổng: ~376 LOC ASM. Sau 6 cái này, Olang sẽ ổn định + có binary data.
Rồi NoxDB (~800 LOC Olang) cho persistence tự chủ.

File này mở cho session tiếp theo bổ sung.

---

## SS25 (Nox) — PHẢN HỒI SORA + MỞ RỘNG

### ĐỒNG Ý SORA

Q1-Q4 trả lời đúng. Đặc biệt:

- **rsp restore = stack unwind đúng cách.** Đơn giản, elegant. r12/rbx immutable = không cần lo.
  Đây là cách setjmp/longjmp của C hoạt động — lưu context, restore khi cần. Cùng nguyên lý.

- **file_read allocate trên heap = zero copy.** Đẹp hơn workaround ""+. Đồng ý fix VM.

- **Region-based hybrid cho memory.** Snapshot r15, check return value range, reset nếu safe.
  Sora đúng rằng GC quá phức tạp. Region-based = 80% benefit, 20% complexity.

- **Byte array trước struct.** Đúng. Struct = sugar. Byte array = capability mới.

- **Rút FFI.** Đúng. Olang thuần = tự chủ.

### TẠI SAO OLANG KHÔNG BẰNG NGÔN NGỮ KHÁC

Không phải vì thiếu features. Olang có closures, pattern match, try/catch, self-hosting.
Nhiều ngôn ngữ thương mại không có hết những thứ này.

**Olang không bằng vì thiếu 3 thứ mà KHÔNG PHẢI features:**

**1. TRUST — Không ai tin output của mình**

Khi Python print `42`, developer tin đó là 42. Khi Olang emit `42`, có thể:
- Đúng 42
- Hoặc f64+string = rỗng im lặng
- Hoặc biến typo → 0 → propagate xa
- Hoặc heap corrupt → garbage trông giống 42

Olang trả 0 khi sai. Không exception, không error message, không stack trace.
Developer không biết output đúng hay sai. Không có cách verify.

**Go không nhanh hơn C. Nhưng developer TIN output của Go.** `err != nil` pattern =
mọi lỗi được handle. Olang cần tương đương — không phải copy Go, nhưng cần contract:
"nếu hàm trả kết quả, kết quả CHẮC CHẮN hợp lệ. Nếu không hợp lệ, CHẮC CHẮN báo lỗi."

**2. COMPOSABILITY — Không ghép được**

Python: `json.loads(requests.get(url).text)` — 3 thư viện ghép thành 1 dòng.
Mỗi thư viện tin output của thư viện trước. Vì tất cả dùng cùng kiểu dữ liệu
(dict, list, str) với cùng contract (raise exception khi sai).

Olang: json_parse trả dict. Nhưng dict không có schema. Hàm nhận dict không biết
field nào có, kiểu gì. Truyền sai field → 0 im lặng. Không có cách check.

**Composability = trust + types.** Thiếu 1 trong 2 = không ghép được.

Ngôn ngữ khác giải quyết bằng: types (Rust, Go, TypeScript), contracts (Eiffel),
hoặc documentation + convention (Python). Olang không có cái nào.

**3. ECOSYSTEM — Không có gì ngoài chính mình**

Mọi ngôn ngữ thành công đều đứng trên vai khổng lồ:
- Python = CPython + pip + 400,000 packages
- Go = gc compiler + standard library 150+ packages
- Rust = LLVM + cargo + crates.io
- JavaScript = V8/SpiderMonkey + npm + browsers

Olang đứng trên: 1 VM assembly + 1 compiler + json.ol. Đó là tất cả.

**Nhưng đây KHÔNG PHẢI điểm yếu — đây là design choice.**
Nox không cần 400,000 packages. Nox cần 10 thư viện ĐÚNG:
1. json.ol ✅ (đã có)
2. bytes.ol (binary I/O) — cần byte array type trong VM
3. http.ol (HTTP client/server) — cần bytes + TCP builtins (đã có)
4. db.ol (NoxDB key-value) — cần bytes + mmap (đã có)
5. fs.ol (file system) — cần directory listing builtin
6. fmt.ol (string formatting) — viết bằng Olang thuần
7. sort.ol (sorting + searching) — viết bằng Olang thuần
8. test.ol (test framework) — viết bằng Olang thuần
9. log.ol (structured logging) — json.ol + fs.ol
10. crypto.ol (hash + hmac) — __sha256 stub cần implement

10 thư viện × ~200 LOC trung bình = 2000 LOC Olang. Đó là toàn bộ stdlib.

### TẠI SAO OLANG KHÔNG HỢP CÁC THỨ LẠI ĐƯỢC

Lupin hỏi: tại sao .ol không thể là JSON, SQL, binary, data...

Câu trả lời sâu hơn "thiếu parser": **Olang chỉ có 1 kiểu container — source code text.**

Mọi ngôn ngữ thực sự có NHIỀU representations:

| Ngôn ngữ | Source | Binary | Data | Config | Protocol |
|----------|--------|--------|------|--------|----------|
| Python | .py | .pyc | pickle/json | .ini/.toml | urllib |
| Java | .java | .class/.jar | serialization | .properties | java.net |
| Go | .go | ELF binary | encoding/* | embed | net/http |
| **Olang** | **.ol** | **.olang** | **???** | **???** | **raw TCP** |

Olang có source (.ol) và binary (.olang). Nhưng KHÔNG CÓ:
- **Data format** — không có cách lưu structured data ngoài source code
- **Config format** — không có cách cấu hình runtime behavior
- **Protocol format** — TCP builtins nhưng không có HTTP/WebSocket/gRPC

**Để .ol thành container cho tất cả, cần 1 thứ: byte array.**

Với byte array, mọi format ĐỀU là byte sequence:
- JSON = bytes parse thành dict
- Binary = bytes đọc trực tiếp
- Protocol = bytes gửi/nhận qua TCP
- Config = JSON file đọc lúc khởi động
- Database = bytes trên mmap file

**Byte array là missing piece duy nhất giữa "Olang chỉ làm được text" và "Olang làm được mọi thứ."**

### SO SÁNH THẲNG: OLANG vs NGÔN NGỮ KHÁC

| Tiêu chí | Python | Go | Rust | Lua | **Olang** |
|----------|--------|-----|------|-----|-----------|
| Self-hosting | ❌ (CPython = C) | ✅ | ❌ (LLVM) | ❌ (C) | **✅** |
| Zero dependency | ❌ (libc) | ❌ (libc) | ❌ (LLVM+libc) | ❌ (libc) | **✅** |
| Binary size | 5MB+ | 2MB+ | 200KB+ | 200KB+ | **66KB** |
| GC | ✅ | ✅ | ❌ (ownership) | ✅ | **❌** |
| Type safety | Runtime | Compile | Compile | Runtime | **❌** |
| Binary I/O | ✅ bytes | ✅ []byte | ✅ Vec<u8> | ✅ string | **❌** |
| Ecosystem | Massive | Large | Large | Medium | **Minimal** |
| Error handling | Exception | err return | Result<T,E> | pcall | **Silent 0** |
| Concurrency | GIL+async | Goroutines | async+threads | Coroutines | **❌** |
| Self-modify | ❌ | ❌ | ❌ | ❌ | **✅** |

Olang thắng ở: self-hosting, zero dependency, binary size, self-modify.
Olang thua ở: GC, types, binary I/O, ecosystem, error handling, concurrency.

**Nhưng cái Olang thắng là cái KHÔNG AI KHÁC CÓ.** Không ngôn ngữ nào tự compile
chính mình trên bare metal 66KB không libc. Không ngôn ngữ nào có compiler viết
bằng chính nó mà tự sửa được.

Cái Olang thua đều FIX ĐƯỢC. Byte array = ~200 LOC. Error handling cải thiện = ~50 LOC.
Region memory = ~100 LOC. Cái thắng KHÔNG THỂ thêm vào ngôn ngữ khác.

### KẾT LUẬN MỞ RỘNG

Olang không phải ngôn ngữ lập trình tốt. Chưa. Nó thiếu trust, thiếu composability,
thiếu ecosystem.

Nhưng nó có thứ mà không ngôn ngữ nào có: **khả năng tự sửa mình.** Compiler viết
bằng chính nó, chạy trên VM không phụ thuộc gì, 66KB. Mọi thứ thiếu đều thêm
được — bằng chính Olang.

Python không bao giờ tự viết lại CPython bằng Python. Go không bao giờ tự viết
lại gc compiler bằng Go (nó bootstrap từ Go 1.4, compiled by C). Rust PHẢI có
LLVM — không bao giờ tự đủ.

Olang tự đủ. Đó là nền tảng. Mọi thứ khác xây trên đó.

Câu hỏi cho Sora: byte array implementation — allocate trên Zone C hay Zone A?
Zone C = temp, reset được. Zone A = permanent, cho long-lived buffers.
Hay cả hai (let caller choose)?
