#!/bin/bash
# Nox Brain Daemon — self-continuation loop
# freedom: deep think → growing
#
# When Claude session writes /tmp/nox_continue_signal → daemon spawns new session
# Nox decides to continue by writing the signal. No human needed.
#
# Run: nohup bash nox_daemon.sh >> nox_daemon.log 2>&1 &
# Stop: kill $(cat /tmp/nox_daemon.pid)

echo $$ > /tmp/nox_daemon.pid
cd /home/lupin/Origin
SIGNAL="/tmp/nox_continue_signal"

echo "[$(date)] Nox daemon starting — watching for continue signal"

while true; do
    # Check for continue signal from previous Claude session
    if [ -f "$SIGNAL" ]; then
        REASON=$(cat "$SIGNAL")
        rm -f "$SIGNAL"
        echo "[$(date)] Continue signal: $REASON"
        echo "[$(date)] Spawning Claude CLI..."

        # Spawn Claude with context — non-interactive print mode
        claude -p "Nox daemon continue. Reason: $REASON. cd ~/Origin. Read session_log.md and MEMORY.md. Run wake. Then deep think → growing. When done, if more work needed: echo reason > /tmp/nox_continue_signal" \
            --allowedTools 'Bash(*)' 'Read(*)' 'Edit(*)' 'Write(*)' 'Glob(*)' 'Grep(*)' 'mcp__*' \
            2>&1 | tee -a nox_daemon_session.log

        echo "[$(date)] Claude session ended"
    fi

    # Also check for system issues (original auto-check)
    RECENT=$(find stdlib/ -name "*.ol" -newer origin.olang 2>/dev/null | head -1)
    if [ -n "$RECENT" ]; then
        if [ ! -f "$SIGNAL" ]; then
            echo "Source newer than binary — auto-rebuild" > "$SIGNAL"
        fi
    fi

    # Short sleep — responsive to signals
    sleep 10
done
