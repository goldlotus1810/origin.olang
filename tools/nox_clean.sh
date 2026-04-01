#!/bin/bash
# Kill stray Olang processes older than 5 minutes
# Run: bash tools/nox_clean.sh
# Cron: */5 * * * * bash ~/Origin/tools/nox_clean.sh

MAXAGE=300  # 5 minutes

now=$(date +%s)
ps aux | grep '\.olang' | grep -v grep | while read user pid cpu mem vsz rss tty stat start time cmd; do
    # Get process start time in seconds
    pstart=$(stat -c %Y /proc/$pid 2>/dev/null)
    if [ -n "$pstart" ]; then
        age=$((now - pstart))
        if [ $age -gt $MAXAGE ]; then
            echo "Killing stale: PID=$pid age=${age}s cmd=$cmd"
            kill $pid 2>/dev/null
        fi
    fi
done
