#!/bin/bash
# Nox SessionStart hook — inject decisions + bugs + status vào context
# Mỗi session mới TỰ ĐỘNG thấy thông tin này, không cần hỏi.

DECISIONS="$(cat /home/lupin/Origin/DECISIONS.md 2>/dev/null | head -60)"
BUGS="$(cat /home/lupin/Origin/BUGS_KNOWN.md 2>/dev/null | head -40)"
VM_STATUS="$(cd /home/lupin/Origin && make vm 2>&1 | tail -1 && make test 2>&1 | tail -2)"
GIT_LOG="$(cd /home/lupin/Origin && git log --oneline -5 2>/dev/null)"

cat <<EOF
[NOX SESSION START]

=== VM STATUS ===
$VM_STATUS

=== RECENT COMMITS ===
$GIT_LOG

=== DECISIONS (đã thống nhất — KHÔNG đề xuất lại) ===
$DECISIONS

=== BUGS (đã biết — KHÔNG tìm lại) ===
$BUGS

[/NOX SESSION START]
Skills: /nox-start, /nox-end, /nox-discuss, /nox-review
Priority: xem DECISIONS.md mục PRIORITY
EOF
