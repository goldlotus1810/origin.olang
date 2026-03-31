# SORA AUDIT — Session 12-commit sprint (2026-03-29)

> Nox: 3 minor bugs. 5 phút fix tất cả.

---

## BUG 1 (TRIVIAL): self_inspect hardcode tool count sai

File: `stdlib/homeos/mcp_server.ol`, trong `self_inspect` handler

```
TRƯỚC: + "  tools: 10");
SAU:   + "  tools: 11");
```

Có 11 tools: olang_eval, know_learn, know_query, emotion_encode, safety_check, nox_status, silk_status, dream_cycle, kg_add, kg_query, self_inspect.

---

## BUG 2 (LOW): chat.ol — claude --print là single-shot

File: `stdlib/editor/chat.ol`, dòng ~15

```
HIỆN TẠI: _ch_proc = __spawn("claude --print 2>/dev/null");
```

`--print` mode: Claude nhận stdin, trả 1 response, exit.
Pipe đóng sau response đầu. Gửi message thứ 2 → write to closed pipe → silent fail.

```
FIX (nếu muốn multi-turn):
  _ch_proc = __spawn("claude --resume 2>/dev/null");

HOẶC (single-shot per message, đơn giản hơn):
  // Trong ch_send: spawn mới mỗi lần
  fn ch_send(_cs_msg) {
      push(_ch_lines, "You: " + _cs_msg);
      let _cs_out = __system("echo '" + _cs_msg + "' | claude --print 2>/dev/null");
      push(_ch_lines, "Claude: " + _cs_out);
  };
```

Verify trên máy Lupin — `claude --print` có thể đã thay đổi behavior.

---

## BUG 3 (LOW): kg_add — relation chứa "|" sẽ parse sai

File: `stdlib/homeos/knowgraph.ol` + `stdlib/homeos/mcp_server.ol`

Không cần fix code. Chỉ cần document:

```
// MCP tool kg_add: triple format = "subject|relation|object"
// CONSTRAINT: subject, relation, object KHÔNG được chứa "|"
// Example: "semantic.ol|contains|_parse_err"  ✅
// Bad:     "a|b|c|d"                          ❌ parse sai
```

---

---

## FEATURE: Editor git commands (từ discussion Lupin + Sora)

Editor đã có :build, :test, :!cmd. Cần thêm git cho vòng lặp khép kín:

```
:git status    → __system("git status 2>&1")
:git add       → __system("git add -A 2>&1")
:git commit    → nhập message → __system("git commit -m 'msg' 2>&1")
:git push      → __system("git push 2>&1")
:git log       → __system("git log --oneline -10 2>&1")
:git diff      → __system("git diff --stat 2>&1")
```

File: `stdlib/editor/main.ol`, sau `:test` handler.

```olang
} else { if len(_cmd_buf) > 4 {
    if __substr(_cmd_buf, 0, 4) == "git " {
        let _git_cmd = __substr(_cmd_buf, 4, len(_cmd_buf));
        __write_raw(__esc()); __write_raw("[?1049l");
        __term_cooked();
        let _gout = __system("git " + _git_cmd + " 2>&1");
        __write_raw("\n─── git " + _git_cmd + " ───\n" + _gout + "\n─── Press any key ───\n");
        __term_raw();
        let _w = __read_byte();
        while _w < 0 { __sleep(50); _w = __read_byte(); };
        __write_raw(__esc()); __write_raw("[?1049h");
        term_clear();
    };
}; };
```

Workflow trong editor:
```
:git status → :git add → :git commit fix: xyz → :git push
```

---

## FEATURE: File lock — __file_lock / __file_trylock / __file_unlock

Nhiều Olang instances chạy cùng lúc (editor + MCP + REPL) → chỉ 1 được ghi file.

### VM builtins (vm/x86_64/vm_x86_64.S, ~30 LOC mỗi cái)

```
.equ SYS_FLOCK, 73
.equ LOCK_SH, 1        // shared (read)
.equ LOCK_EX, 2        // exclusive (write)  
.equ LOCK_NB, 4        // non-blocking
.equ LOCK_UN, 8        // unlock
```

**__file_lock(path)** — blocking exclusive lock:
```asm
.call_file_lock:
    add     %rcx, %r13
    # Pop path, decode to C string
    mov     (%r14), %rsi
    mov     8(%r14), %rdx
    add     $16, %r14
    # Decode molecules → sha_input buffer
    lea     sha_input(%rip), %rdi
    xor     %ecx, %ecx
.fl_dec:
    cmp     %rdx, %rcx
    jge     .fl_dec_done
    movzbl  (%rsi, %rcx, 2), %eax
    mov     %al, (%rdi, %rcx)
    inc     %rcx
    jmp     .fl_dec
.fl_dec_done:
    movb    $0, (%rdi, %rcx)
    # Open file
    mov     $SYS_OPEN, %eax
    lea     sha_input(%rip), %rdi
    mov     $0x0002, %esi               # O_RDWR
    xor     %edx, %edx
    syscall
    test    %rax, %rax
    js      .fl_fail
    # flock(fd, LOCK_EX)
    mov     %eax, %edi
    mov     $SYS_FLOCK, %eax
    mov     $LOCK_EX, %esi
    syscall
    # Return fd as f64 (keep open for unlock later)
    cvtsi2sd %edi, %xmm0
    sub     $16, %r14
    movsd   %xmm0, (%r14)
    movq    $F64_MARKER, 8(%r14)
    jmp     vm_loop
.fl_fail:
    sub     $16, %r14
    xorpd   %xmm0, %xmm0
    movsd   %xmm0, (%r14)
    movq    $F64_MARKER, 8(%r14)
    jmp     vm_loop
```

**__file_trylock(path)** — non-blocking, return fd hoặc 0:
```
Giống __file_lock nhưng dùng LOCK_EX | LOCK_NB.
Nếu flock fail (EWOULDBLOCK) → return 0.
```

**__file_unlock(fd)** — unlock + close:
```asm
.call_file_unlock:
    add     %rcx, %r13
    movsd   (%r14), %xmm0
    cvttsd2si %xmm0, %edi
    add     $16, %r14
    # flock(fd, LOCK_UN)
    mov     $SYS_FLOCK, %eax
    mov     $LOCK_UN, %esi
    syscall
    # close(fd)
    mov     $SYS_CLOSE, %eax
    syscall
    # Return 1
    sub     $16, %r14
    movsd   .one(%rip), %xmm0
    movsd   %xmm0, (%r14)
    movq    $F64_MARKER, 8(%r14)
    jmp     vm_loop
```

### Dùng trong Olang:
```olang
let fd = __file_lock("lexer.ol");     // chờ đến khi lock được
__file_write("lexer.ol", content);
__file_unlock(fd);

// Hoặc non-blocking:
let fd = __file_trylock("lexer.ol");
if fd == 0 {
    emit "File đang bị lock bởi instance khác";
} else {
    __file_write("lexer.ol", content);
    __file_unlock(fd);
};
```

### Register builtins:
Thêm vào fn_registry trong vm_x86_64.S:
```
"__file_lock"     → .call_file_lock
"__file_trylock"  → .call_file_trylock
"__file_unlock"   → .call_file_unlock
```

---

*Sora — 2026-03-29. 3 bugs + 2 features cho Nox.*
