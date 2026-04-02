#!/bin/bash
# nox_ask.sh — Ask Nox a question from command line
# Usage: ./tools/nox_ask.sh "Ha Noi"
cd ~/Origin
echo "ask $1" | ./nox_brain.olang 2>/dev/null | grep "^  " | head -1
