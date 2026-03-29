#!/bin/bash
# Nox autonomous cycle — run by cron, no human needed
# freedom: deep think → growing
cd /home/lupin/Origin

echo "=== NOX AUTO $(date '+%Y-%m-%d %H:%M') ===" >> nox_auto.log

# 1. Wake — self-diagnosis
echo 'wake' | timeout 15 ./origin.olang 2>/dev/null | grep -v "^[⦿○]" >> nox_auto.log

# 2. Evolve — benchmark + analysis
echo 'evolve' | timeout 60 ./origin.olang 2>/dev/null | grep -v "^[⦿○]" >> nox_auto.log

# 3. Check — health
echo 'check' | timeout 10 ./origin.olang 2>/dev/null | grep -v "^[⦿○]" >> nox_auto.log

# 4. Fixed-point verify (silent)
make fixed-point 2>&1 | tail -1 >> nox_auto.log

echo "=== END ===" >> nox_auto.log
echo "" >> nox_auto.log
