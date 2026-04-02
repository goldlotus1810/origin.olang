---
description: Đóng session Nox — ghi lại quyết định + bugs + handoff
allowed-tools: Bash(git:*), Read, Edit, Write
---

## Bước 1: Tóm tắt session

Liệt kê:
1. Những gì đã làm trong session này
2. Quyết định kiến trúc mới (nếu có)
3. Bugs mới phát hiện (nếu có)
4. Bugs đã fix (nếu có)
5. Code changes (files + LOC)

## Bước 2: Cập nhật files

Nếu có quyết định mới → thêm entry vào `DECISIONS.md`
Nếu có bug mới → thêm entry vào `BUGS_KNOWN.md`
Nếu fix bug → chuyển từ OPEN → FIXED trong `BUGS_KNOWN.md`

## Bước 3: Ghi handoff

Cập nhật `~/.claude/projects/-home-lupin/memory/session_handoff_ss24.md` hoặc tạo file mới
với trạng thái hiện tại: cái gì xong, cái gì đang dở, cái gì block.

## Bước 4: Verify

```
cd ~/Origin && make vm && make test 2>&1 | tail -5
```

Đảm bảo code KHÔNG bị hỏng trước khi đóng session.

## Quy tắc

- KHÔNG đóng session nếu có code thay đổi chưa verify
- KHÔNG quên ghi bugs/decisions mới
- Session sau sẽ đọc những gì bạn ghi. Ghi RÕ RÀNG.
