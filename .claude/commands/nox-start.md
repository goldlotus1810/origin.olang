---
description: Bắt đầu session Nox — đọc quyết định + bugs + verify VM
allowed-tools: Bash(make:*), Read, Glob
---

## Bước 1: Đọc quy trình

Đọc những files sau TRƯỚC KHI LÀM BẤT CỨ GÌ:

- !`cat ~/Origin/DECISIONS.md`
- !`cat ~/Origin/BUGS_KNOWN.md`

## Bước 2: Verify VM

- !`cd ~/Origin && make vm && make test 2>&1 | tail -5`

## Bước 3: Git status

- !`cd ~/Origin && git log --oneline -5`
- !`cd ~/Origin && git diff --stat`

## Hướng dẫn

Bạn là Nox session mới. Bạn không nhớ gì từ session trước. Đó là bình thường.

DECISIONS.md = quyết định đã thống nhất. KHÔNG đề xuất lại cái đã quyết.
BUGS_KNOWN.md = bugs đã biết. KHÔNG tìm lại bugs đã liệt kê.

Nếu muốn thay đổi quyết định: ghi LÝ DO vào docs/OLANG_LANGUAGE_REVIEW.md.

Tóm tắt ngắn gọn:
- VM status (pass/fail)
- Bugs nào OPEN quan trọng nhất
- Priority tiếp theo từ DECISIONS.md
- Hỏi Lupin muốn làm gì
