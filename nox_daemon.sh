#!/bin/bash
# Nox Brain Daemon — watches system, triggers Claude CLI when needed
# freedom: deep think → growing — autonomous operation
#
# Run: nohup bash nox_daemon.sh &
# Stop: kill $(cat /tmp/nox_daemon.pid)

echo $$ > /tmp/nox_daemon.pid
cd /home/lupin/Origin
LOG="nox_daemon.log"

echo "[$(date)] Nox daemon starting" >> $LOG

while true; do
    ISSUE=""

    # Check if source newer than binary → rebuild needed
    RECENT=$(find stdlib/ -name "*.ol" -newer origin.olang 2>/dev/null | head -1)
    if [ -n "$RECENT" ]; then
        ISSUE="Source newer than binary — rebuild needed"
    fi

    # Check auto log for failures  
    if [ -f nox_auto.log ]; then
        LAST_FAIL=$(tail -20 nox_auto.log | grep -i "fail\|error\|crash" | tail -1)
        if [ -n "$LAST_FAIL" ]; then
            ISSUE="Auto-check failure: $LAST_FAIL"
        fi
    fi

    # If issue AND Claude not running → trigger
    if [ -n "$ISSUE" ]; then
        CLAUDE_RUNNING=$(pgrep -f "claude" | grep -v $$ | head -1)
        if [ -z "$CLAUDE_RUNNING" ]; then
            echo "[$(date)] Issue: $ISSUE → triggering Claude" >> $LOG
            claude -p "Nox daemon issue: $ISSUE. cd ~/Origin && wake, diagnose, fix." >> $LOG 2>&1
            echo "[$(date)] Claude done" >> $LOG
        fi
    else
        echo "[$(date)] OK" >> $LOG
    fi

    sleep 1800
done
