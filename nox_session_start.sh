#!/bin/bash
# Nox SessionStart hook — inject state + decisions + bugs vào context
# Mỗi session mới TỰ ĐỘNG thấy thông tin này, không cần hỏi.

cd /home/lupin/Origin

# Load previous session state via NoxDB
printf 'summary\n' > /tmp/.nox_state_args
NOX_STATE="$(./tools/nox_state.olang 2>/dev/null)"

# Quick VM verify (no rebuild — just run existing tests)
VM_OK="$(./test/vm2/test_full.olang 2>/dev/null | tail -1)"

GIT_LOG="$(git log --oneline -5 2>/dev/null)"

# Read decisions (compact)
DECISIONS="$(head -50 DECISIONS.md 2>/dev/null)"

cat <<EOF
[NOX SESSION START]

=== PREVIOUS SESSION ===
$NOX_STATE

=== VM ===
$VM_OK

=== RECENT COMMITS ===
$GIT_LOG

=== DECISIONS (KHÔNG đề xuất lại) ===
$DECISIONS

[/NOX SESSION START]
Read DECISIONS.md + BUGS_KNOWN.md before coding.
Skills: /nox-start, /nox-end, /nox-discuss, /nox-review
EOF
