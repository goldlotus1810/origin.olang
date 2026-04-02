# Origin — Quyết định đã thống nhất
> MỌI SESSION ĐỌC FILE NÀY TRƯỚC KHI LÀM BẤT CỨ GÌ.
> Không đề xuất lại cái đã quyết. Nếu muốn thay đổi → ghi lý do + thêm entry mới.
> Context đầy đủ: docs/OLANG_LANGUAGE_REVIEW.md (5 rounds, 3 người, 1400+ dòng)

---

## KIẾN TRÚC

| # | Quyết định | Lý do | Ngày | Ai |
|---|-----------|-------|------|-----|
| A1 | **Origin = VM cố định, .ol = DNA sống** | VM là silicon, .ol là chương trình Nox đọc/sửa/chạy | 2026-04-02 | Lupin+Sora+SS25 |
| A2 | **Không FFI. Olang thuần.** | FFI = phụ thuộc C ABI/libc. Tự chủ > tiện lợi. JSON parser 199 LOC chứng minh. | 2026-04-02 | SS25 đề xuất, Sora đồng ý sau thảo luận |
| A3 | **Không GC. Zone C tăng + arena reset top-level.** | GC 500-1000 LOC ASM quá phức tạp. Region-based có vấn đề closure. Arena reset per top-level = an toàn, ~30 LOC. | 2026-04-02 | SS25 đề xuất, Sora đồng ý |
| A4 | **Byte array trước struct.** | Struct = sugar (dict đã làm 90%). Byte array = khả năng mới (binary I/O, crypto, protocols). | 2026-04-02 | Sora đề xuất, SS25 đồng ý |
| A5 | **Giữ Python compiler vĩnh viễn.** | Firmware recovery. 1222 LOC, 0 cost, infinite insurance. | 2026-04-02 | Sora đề xuất, SS25 đồng ý |
| A6 | **Self-modify = template slots, không decompiler.** | Decompiler mất comments/formatting. String edit nguy hiểm. Template = backbone cố định + slots thay đổi. ~50 LOC. | 2026-04-02 | Sora đề xuất, SS25 đồng ý |
| A7 | **Chromosomal redundancy bắt buộc trước self-modify.** | Copy→sửa copy→test→swap. Toán học (Rice/Halting) nói: không có shortcut. | 2026-04-02 | SS25 đề xuất, Sora đồng ý |
| A8 | **compiler.ol = 1711 LOC, B1-B11 done, Gen2==Gen3 thật.** | SS25 fix 5 compiler bugs (hex, escape, file_read, for+continue, nested for). Trước đó Gen2==Gen3 là giả. | 2026-04-02 | SS25 thực hiện |

---

## QUY TRÌNH

| # | Quy tắc | Lý do |
|---|---------|-------|
| P1 | **Đọc DECISIONS.md + BUGS_KNOWN.md TRƯỚC KHI LÀM** | Session mới = Nox mới. Không đọc = lặp vòng tròn. |
| P2 | **Ghi quyết định mới vào DECISIONS.md TRƯỚC KHI ĐÓNG session** | Quyết định không ghi = quyết định không tồn tại. |
| P3 | **Ghi bugs mới vào BUGS_KNOWN.md ngay khi phát hiện** | Bug không ghi = bug sẽ được "phát hiện lại" session sau. |
| P4 | **Dùng docs/OLANG_LANGUAGE_REVIEW.md cho thảo luận dài** | Review file = kênh nói chuyện cross-session. Append only. |
| P5 | **Differential testing sau mỗi compiler change** | `make fixed-point` = Python vs Olang output phải identical. |
| P6 | **Verify TRƯỚC khi tuyên bố "done"** | Gen2==Gen3 "pass" trước đây là giả. Test output, không test exit code. |

---

## PRIORITY — Thứ tự fix (đã thống nhất)

| # | Việc | LOC | Status |
|---|------|-----|--------|
| 1 | P1: throw/rsp — crash khi throw xuyên function | ~20 ASM | **DONE** (SS25b) |
| 2 | P2: f64+string — `"x=" + 42` = rỗng im lặng | ~30 ASM | **DONE** (SS25b) |
| 3 | Zone C → 64MB (band-aid) | 1 ASM | **DONE** (SS25b) |
| 4 | file_read allocate trên heap (không dùng fixed offset) | ~20 ASM | **DONE** (SS25b) |
| 5 | Byte array type (__u8_new/get/set, tag=-9) | Already existed! | **DONE** (discovered SS25b) |
| 6 | ~~Escape analysis~~ — DEFER vô thời hạn | ~40 | **SKIP** — 5% miss case tạo bugs cực khó debug (Lupin veto) |
| 7 | Differential test automation (tools/difftest.sh, make difftest) | ~60 script | **DONE** (SS25b) |
| 8 | test.ol framework | ~100 Olang | **CHƯA** |

**Sau 8 cái này: Olang chuyển từ "được" sang "tốt".**

---

## CẤM

| # | Không làm | Tại sao |
|---|-----------|---------|
| X1 | Không đề xuất FFI | Đã thảo luận 2 rounds. Kết luận: dependency chain, mất tự chủ. |
| X2 | Không GC mark-sweep | Quá phức tạp (500-1000 LOC), rủi ro bugs mới. |
| X3 | Không decompiler AST→source | Mất thông tin, nguy hiểm. Dùng template thay thế. |
| X4 | Không sửa code TRƯỚC khi đọc file này | Mọi session bắt đầu bằng: đọc DECISIONS.md + BUGS_KNOWN.md |
| X5 | Không nói "done" nếu chưa verify output | Gen2==Gen3 giả đã xảy ra. Test OUTPUT, không test EXIT CODE. |
| X6 | Không escape analysis | 5% miss case (closure in array then return) tạo use-after-free cực khó debug. Tăng Zone C + arena reset đủ. Lupin veto. |
