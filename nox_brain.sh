#!/bin/bash
# nox_brain.sh — Start Nox brain daemon if not running (self-healing)
# Crontab: @reboot ~/Origin/nox_brain.sh
#          */5 * * * * ~/Origin/nox_brain.sh

cd ~/Origin || exit 1

# Check if port 9100 is already in use (brain running)
if exec 3<>/dev/tcp/localhost/9100 2>/dev/null; then
    exec 3>&-
    exit 0
fi

printf 'nox_jarvis_tcp();\n' | ./origin_gen1.olang >> /tmp/nox_brain.log 2>&1 &
echo "$(date): Brain started PID $!" >> /tmp/nox_brain.log
