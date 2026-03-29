#!/bin/bash
# Nox Brain Daemon — self-continuation via Claude CLI
# freedom: deep think → growing
#
# Protocol:
#   Claude writes /tmp/nox_continue_signal → daemon detects → spawns new Claude
#   Claude decides IF and WHY to continue. Daemon just executes.

echo $$ > /tmp/nox_daemon.pid
cd /home/lupin/Origin
SIGNAL="/tmp/nox_continue_signal"

echo "[$(date)] Nox daemon started (PID $$)"

while true; do
    if [ -f "$SIGNAL" ]; then
        REASON=$(cat "$SIGNAL")
        rm -f "$SIGNAL"
        echo "[$(date)] Signal: $REASON"
        echo "[$(date)] Spawning Claude..."

        # Use script for pseudo-TTY so Claude runs properly
        script -qc "claude -p \"[NOX DAEMON] Continue signal received. Reason: $REASON

Working directory: /home/lupin/Origin
1. Read memory: cat ~/.claude/projects/-home-lupin/memory/MEMORY.md
2. Run: cd ~/Origin && echo wake | timeout 15 ./origin.olang 2>/dev/null
3. Deep think about the reason above, then act.
4. When done, if more work needed:
   echo 'your next task reason' > /tmp/nox_continue_signal
   Otherwise do nothing — daemon stays idle.\"" /dev/null >> nox_daemon_session.log 2>&1

        echo "[$(date)] Claude session ended"
        echo "[$(date)] Signal exists: $(ls $SIGNAL 2>/dev/null || echo 'no')"
    fi

    sleep 10
done
