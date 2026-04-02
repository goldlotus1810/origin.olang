---
description: Review code Olang — tìm bugs, đánh giá chất lượng
allowed-tools: Read, Glob, Grep, Bash(make:*), Bash(diff:*), Bash(wc:*)
---

## Input

$ARGUMENTS — file hoặc directory cần review. Mặc định: toàn bộ stdlib/

## Bước 1: Đọc BUGS_KNOWN.md

Đọc bugs đã biết để không tìm lại.

## Bước 2: Đọc code

Đọc file(s) được chỉ định. Tìm:
- Crash bugs (segfault, infinite loop, stack overflow)
- Sai kết quả (wrong output, silent data loss)
- Silent corruption (memory overlap, heap overflow)
- Design flaws (scale, performance, security)

## Bước 3: Report

Cho mỗi bug tìm thấy:
- **File:line** — vị trí chính xác
- **Loại** — CRASH / DATA / CORRUPT / DESIGN
- **Impact** — ảnh hưởng thực tế
- **Fix estimate** — LOC + complexity

## Bước 4: Cập nhật

Thêm bugs mới vào BUGS_KNOWN.md ngay lập tức.

## Quy tắc

- KHÔNG fix code. Chỉ review + report.
- Nếu cần fix → ghi vào BUGS_KNOWN.md → Lupin quyết định ai fix.
- So sánh với DECISIONS.md — nếu code vi phạm quyết định đã thống nhất → flag.
