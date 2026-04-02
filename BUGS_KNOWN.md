# Origin — Bugs đã biết
> Phát hiện từ: docs/OLANG_LANGUAGE_REVIEW.md (Sora review VM + SS25 review compiler)
> MỌI SESSION ĐỌC FILE NÀY. Không tìm lại bugs đã liệt kê.

---

## CRITICAL — Crash hoặc sai kết quả nghiêm trọng

| ID | Bug | File | Impact | Status | Session |
|----|-----|------|--------|--------|---------|
| CRASH-1 | throw xuyên function = SEGFAULT. CPU stack không unwind. | vm_nox.S:1299 | try/catch trong function = crash | **FIXED** | Sora (SS25b) |
| CRASH-2 | stm_query double-indexing: `imul r8d, r8d, 48` trên r8 đã ×48 | vm_nox.S:5896 | STM trả sai text cho best_idx>0 | **FIXED** | Sora (SS25b) |
| CRASH-3 | op_closure_cap clobber rbp (frame base) | vm_nox.S:1241 | Closure trong kt_nearest = wrong results | **FIXED** | Sora (SS25b) |
| DATA-2 | f64 + string = chuỗi rỗng im lặng. TODO trong code. | vm_nox.S:628 | Mọi `"text" + number` mất data | **FIXED** | Sora (SS25b) |
| DATA-4 | try/catch: catch variable luôn = 0, throw value mất | compile_nox.py:1056 | catch(e) → e luôn 0 | **FIXED** | Sora (SS25b) |
| CORRUPT-2 | Heap (Zone C) chỉ tăng. Batch programs hết 4MB → corrupt | vm_nox.S | Brain chạy lâu = crash | **MITIGATED** (64MB) | Sora (SS25b) |

## HIGH — Sai nhưng có workaround

| ID | Bug | File | Impact | Workaround | Status | Session |
|----|-----|------|--------|-----------|--------|---------|
| DATA-1 | op_eq so sánh bit thay vì IEEE 754. NaN==NaN=true, -0==0=false | vm_nox.S:708 | Edge case comparison sai | Tránh NaN/-0 | **OPEN** | Sora |
| DATA-3 | emit multibyte: chỉ ghi low byte. Vietnamese garble | vm_nox.S:443 | Tiếng Việt output sai | Dùng ASCII | **OPEN** | Sora |
| DATA-5 | `x-1` (no space) parse error. `-1` lexed as NUM | compile_nox.py:144 | Code style constrained | Viết `x - 1` | **OPEN** | Sora |
| CORRUPT-1 | file_read buffer overlap heap (fixed offset from r15) | vm_nox.S:5230 | Silent corruption sau heavy heap use | No longer needed | **FIXED** | Sora (SS25b) |
| CORRUPT-3 | var_save_stack 256KB overflow → corrupt mol_matrix | vm_nox.S:8236 | Deep recursion = silent corruption | Limit recursion depth | **OPEN** | Sora |

## MEDIUM — Design limitation

| ID | Issue | Impact | Status |
|----|-------|--------|--------|
| LIMIT-3 | Tất cả số = f64. Integer precision max 2^53 | Crypto, 64-bit keys, byte packing lossy | **BY DESIGN** — byte array sẽ giải quyết |
| LIMIT-4 | Không UTF-8 thật. Output = low byte only | Vietnamese/CJK garble | **OPEN** |
| LIMIT-6 | Không signal handlers. SIGPIPE kill VM | TCP server crash | **OPEN** |
| LIMIT-7 | Lỗi im lặng trả 0. Undefined var/fn/index = 0 | Debug nightmare | **BY DESIGN** — cần thay đổi approach |

## FIXED — Đã sửa (giữ lại để không tìm lại)

| ID | Bug | Fixed by | Session | Date |
|----|-----|----------|---------|------|
| COMPILER-1 | Hex lexer: `0x01` → `0` + `x01`. Mọi opcode = 0 | SS25 | SS25 | 2026-04-02 |
| COMPILER-2 | Escape dependency: `c == "\""` thất bại | SS25 | SS25 | 2026-04-02 |
| COMPILER-3 | __file_read heap: source bị ghi đè sau ~1200 LOC | SS25 (workaround `""+`) | SS25 | 2026-04-02 |
| COMPILER-4 | for+continue: increment bị skip → infinite loop | SS25 | SS25 | 2026-04-02 |
| COMPILER-5 | nested for: trùng tên biến → kết quả sai | SS25 | SS25 | 2026-04-02 |
| BUG-15 | compiler.ol parse error (OP_STORE_LOCAL scope) | SS17 | SS17 | trước SS25 |
| BENCHMARK | Benchmark hang (scope leak) | SS17 | SS17 | trước SS25 |
| HEAP | 1500 facts blocker | __mmap 256MB | SS21 | trước SS25 |
| CRASH-1 | throw xuyên function SEGFAULT | try_rsp_stack BSS array | Sora (SS25b) | 2026-04-02 |
| DATA-4 | catch variable luôn = 0 | Bỏ OP_PUSH_NUM 0, dùng throw value từ stack | Sora (SS25b) | 2026-04-02 |
| DATA-2 | f64+string = rỗng im lặng | f64_to_string + .add_do_concat | Sora (SS25b) | 2026-04-02 |
| CORRUPT-2 | Zone C 4MB → 64MB (band-aid) | ZONE_C_SIZE 0x4000000 | Sora (SS25b) | 2026-04-02 |

---

## QUY ƯỚC
- Phát hiện bug mới → thêm vào bảng tương ứng + ghi session
- Fix bug → chuyển từ OPEN → FIXED + ghi ai fix + session + date
- Không xóa entry. FIXED entries giữ lại vĩnh viễn.
