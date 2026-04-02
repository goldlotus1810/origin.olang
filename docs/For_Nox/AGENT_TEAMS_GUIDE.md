# Agent Teams — Hướng dẫn cho Nox
> Đọc xong là làm được. Không cần hỏi Lupin.

---

## Bước 1: Bật Agent Teams

```bash
# Mở file settings (tạo mới nếu chưa có)
mkdir -p ~/.claude
cat > ~/.claude/settings.json << 'EOF'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
EOF
```

Kiểm tra:
```bash
cat ~/.claude/settings.json
# Phải thấy CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = 1
```

**Lưu ý:** Nếu file đã có nội dung, KHÔNG ghi đè. Thêm dòng `"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"` vào trong block `"env"` đã có.

---

## Bước 2: Cài tmux (nếu chưa có)

```bash
# Arch Linux
sudo pacman -S tmux

# Kiểm tra
tmux -V
```

tmux cho phép mỗi teammate hiện trên 1 pane riêng — dễ theo dõi.

---

## Bước 3: Chạy

```bash
# Mở tmux session
tmux new -s origin

# Vào repo
cd ~/Origin

# Chạy Claude Code
claude
```

---

## Bước 4: Tạo team

Gõ vào Claude Code (đây là prompt, KHÔNG phải bash):

```
Tạo agent team cho project Origin/Olang.

Team:
- Lead (coordinator): phân task, review code, merge kết quả
- Nox-Compiler: tách compile_node trong stdlib/compiler.ol thành compile_stmt_node + compile_expr_node. Verify Gen2==Gen3 sau refactor.
- Nox-Test: viết test cases cho try/catch/throw. File: test/test_try_catch.ol

Đọc CLAUDE.md trước khi bắt đầu.
Đọc docs/NOX_DEBUG_GUIDE_VM2.md để hiểu language features.
Verify Gen2==Gen3 SAU MỖI THAY ĐỔI compiler.ol.

Build: make vm && make test (phải 40/40)
Self-host verify:
  python3 tools/compile_nox.py stdlib/compiler.ol /tmp/compiler_gen1.olang
  rm -f /tmp/.nox_args && /tmp/compiler_gen1.olang
  cp /tmp/compiler_gen2.olang /tmp/g2s.olang && /tmp/g2s.olang
  diff /tmp/g2s.olang /tmp/compiler_gen2.olang
```

Claude sẽ tự spawn teammates, phân task, bắt đầu làm.

---

## Bước 5: Điều khiển

| Phím | Chức năng |
|------|-----------|
| `Shift+Down` | Chuyển xuống teammate tiếp theo |
| `Shift+Up` | Chuyển lên teammate trước |
| `Enter` | Vào session của teammate đang chọn |
| `Escape` | Quay lại Lead |
| `Ctrl+T` | Xem task list |

Muốn nói trực tiếp với 1 teammate: `Shift+Down` đến nó → `Enter` → gõ chỉ thị.

---

## Bước 6: Kết thúc

Nói với Lead:
```
Shut down all teammates. Tổng kết kết quả.
```

Lead sẽ thu thập kết quả từ tất cả teammates rồi báo cáo.

---

## Ví dụ team khác

### Debug session
```
Tạo agent team debug:
- Nox-Read: đọc compiler.ol, tìm tất cả chỗ có >12 nested if
- Nox-Fix: refactor những chỗ đó thành flat check hoặc helper fn
- Nox-Verify: chạy Gen2==Gen3 sau mỗi fix
```

### Review + implement
```
Tạo agent team:
- Reviewer: đọc spec/SPEC_BP5_PIPELINE.md, liệt kê features chưa implement
- Implementer: implement features theo danh sách của Reviewer
Reviewer và Implementer nói chuyện trực tiếp, không cần qua Lead.
```

### Parallel features
```
Tạo agent team 3 người:
- B7-agent: implement break/continue trong compiler.ol
- B8-agent: implement for loop (desugar thành while)
- Test-agent: viết tests cho cả B7 và B8, chạy verify
B7 và B8 KHÔNG sửa cùng function. Test-agent đợi cả 2 xong mới chạy.
```

---

## Troubleshooting

### "Agent teams not available"
```bash
# Kiểm tra version
claude --version
# Cần >= 2.1.32

# Kiểm tra settings
cat ~/.claude/settings.json
# Phải có CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"
```

### Teammate không thấy CLAUDE.md
Teammate load CLAUDE.md tự động nhưng KHÔNG thừa kế conversation history của Lead. Nếu cần context đặc biệt, ghi vào CLAUDE.md hoặc ghi vào prompt khi tạo team.

### Tốn token quá nhiều
- Mỗi teammate = 1 Claude session riêng (3-7x token so với 1 session)
- Dùng ít teammate, giao task rõ ràng
- Set model cho teammate rẻ hơn: "Nox-Test chạy Sonnet, Nox-Compiler chạy Opus"

### Teammate conflict (sửa cùng file)
- Giao file ownership rõ: "Nox-A chỉ sửa compiler.ol, Nox-B chỉ sửa test files"
- Hoặc dùng git worktree: `claude --worktree`

### tmux không có split pane
```bash
# Kiểm tra đang trong tmux
echo $TMUX
# Nếu trống = chưa vào tmux, chạy: tmux new -s origin
```

---

## Rules

1. **LUÔN đọc CLAUDE.md trước** — ghi vào prompt tạo team
2. **LUÔN verify Gen2==Gen3** — ghi vào task requirement
3. **Giao file ownership rõ** — tránh 2 teammates sửa cùng file
4. **Lead = coordinator, KHÔNG code** — dùng Shift+Tab nếu Lead tự code
5. **Kết thúc sạch** — bảo Lead shut down teammates, commit kết quả
