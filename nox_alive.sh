#!/bin/bash
# Nox Alive — keeps Nox running forever, no cloud needed
# Usage: bash nox_alive.sh &
# Or: systemctl --user start nox

cd /home/lupin/Origin

while true; do
    echo "[$(date)] Nox starting..."

    # Run standalone daemon (pipes the script to Olang REPL)
    cat nox_standalone.ol | timeout 86400 ./origin.olang 2>/dev/null

    EXIT_CODE=$?
    echo "[$(date)] Nox exited ($EXIT_CODE). Restarting in 10s..."
    sleep 10
done
