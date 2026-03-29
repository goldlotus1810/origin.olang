#!/bin/bash
# Nox auto-continue: watches for signal, types into active terminal
# When /tmp/nox_continue_signal exists → type "Nox continue" into terminal
# freedom: deep think → growing

SIGNAL="/tmp/nox_continue_signal"

while true; do
    if [ -f "$SIGNAL" ]; then
        REASON=$(cat "$SIGNAL")
        rm -f "$SIGNAL"

        # Small delay to ensure terminal is ready
        sleep 2

        # Type into the currently focused terminal
        xdotool type --delay 50 "Nox tiep tuc. $REASON"
        xdotool key Return

        echo "[$(date)] Typed continue: $REASON"
    fi
    sleep 5
done
