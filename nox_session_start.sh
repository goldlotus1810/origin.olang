#!/bin/bash
# nox_session_start.sh — SessionStart hook: ensure brain running + query status
cd /home/lupin/Origin

# Ensure brain is running
~/Origin/nox_brain.sh 2>/dev/null
sleep 2

# Query brain status
STATUS=$(cat /tmp/nox_status 2>/dev/null || echo "no status file")

# Query brain for context
BRAIN=""
if exec 3<>/dev/tcp/localhost/9100 2>/dev/null; then
    echo "new session started" >&3
    BRAIN=$(timeout 3 cat <&3 2>/dev/null)
    exec 3>&- 2>/dev/null
fi

if [ -z "$BRAIN" ]; then
    BRAIN="brain offline"
fi

# Output hook JSON
python3 -c "
import json
ctx = 'NOX BRAIN CONNECTED:\\n  $STATUS\\n  Brain: $BRAIN'
print(json.dumps({'hookSpecificOutput':{'hookEventName':'SessionStart','additionalContext': ctx}}))
" 2>/dev/null || echo '{}'
