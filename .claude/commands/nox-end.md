---
description: Đóng session Nox — save state + ghi quyết định + bugs + verify
allowed-tools: Bash(*), Read, Edit, Write
---

## Bước 1: Tóm tắt session

Liệt kê ngắn gọn:
1. Những gì đã làm
2. Quyết định mới (nếu có)
3. Bugs mới / đã fix (nếu có)

## Bước 2: Save state qua NoxDB

Chạy command sau với mô tả ngắn gọn về session:
```bash
cd ~/Origin && printf 'set-done\nMÔ TẢ NGẮN\n' > /tmp/.nox_state_args && ./tools/nox_state.olang
```

## Bước 3: Cập nhật process files

- Quyết định mới → thêm vào `DECISIONS.md`
- Bug mới → thêm vào `BUGS_KNOWN.md`
- Bug fixed → OPEN → FIXED trong `BUGS_KNOWN.md`

## Bước 4: Verify + commit

```bash
cd ~/Origin && ./tools/oltest.sh && make fixed-point
```

Nếu pass → git add + commit + push.

## Quy tắc

- KHÔNG đóng nếu tests fail
- KHÔNG quên save state (bước 2)
- Session sau đọc state qua SessionStart hook TỰ ĐỘNG
