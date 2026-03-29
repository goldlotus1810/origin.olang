#!/bin/bash
# nox_daemon.sh — Nox self-improvement loop
# Runs autonomously: build → test → analyze → fix → build
# No human intervention needed.
#
# Usage: bash nox_daemon.sh
# Stop:  kill $(cat /tmp/nox_daemon.pid)

set -euo pipefail
cd /home/lupin/Origin

LOGFILE="nox_daemon.log"
PIDFILE="/tmp/nox_daemon.pid"
MAX_CYCLES=50
CYCLE=0

echo $$ > "$PIDFILE"
echo "[$(date)] Nox daemon started. PID=$$" | tee -a "$LOGFILE"

nox_log() {
    echo "[$(date)] $1" | tee -a "$LOGFILE"
}

nox_think() {
    # Ask Claude for analysis/fix, return response
    local prompt="$1"
    local context="$2"
    echo "$context" | claude --print "$prompt" 2>/dev/null
}

# Phase 1: Ensure everything builds and passes
nox_log "Phase 1: Verify current state"

# Build
make vm 2>&1 | tail -1 | tee -a "$LOGFILE"
if [ ! -x origin.olang ]; then
    nox_log "No origin.olang — running bootstrap"
    make bootstrap 2>&1 | tee -a "$LOGFILE"
fi

# Self-build
nox_log "Self-build..."
if timeout 120 ./origin.olang --build 2>&1 | tail -3 | tee -a "$LOGFILE"; then
    mv origin_new.olang origin_gen1.olang
    chmod +x origin_gen1.olang
    nox_log "Gen1: $(wc -c < origin_gen1.olang) bytes"
else
    nox_log "ERROR: Self-build failed"
    exit 1
fi

# Test
nox_log "Running tests..."
TEST_OUTPUT=$(bash tests.sh 2>&1)
if echo "$TEST_OUTPUT" | grep -q "ALL PASS"; then
    PASS_COUNT=$(echo "$TEST_OUTPUT" | grep "ALL PASS" | grep -o '[0-9]*/[0-9]*')
    nox_log "Tests: $PASS_COUNT ✓"
else
    FAIL_COUNT=$(echo "$TEST_OUTPUT" | grep "FAILED" | head -1)
    nox_log "Tests FAILED: $FAIL_COUNT"
    # Get failing test details
    FAILURES=$(echo "$TEST_OUTPUT" | grep "FAIL" | head -5)
    nox_log "Failures: $FAILURES"
fi

# Fixed-point check
nox_log "Fixed-point check..."
if timeout 120 ./origin_gen1.olang --build 2>&1 | tail -3 | tee -a "$LOGFILE"; then
    if cmp -s origin_gen1.olang origin_new.olang; then
        nox_log "FIXED-POINT ✓"
    else
        nox_log "FIXED-POINT ✗ — Gen1 != Gen2"
    fi
    rm -f origin_new.olang
fi

# MCP test
nox_log "MCP test..."
MCP_OUTPUT=$(bash tests/test_mcp.sh 2>&1)
MCP_RESULT=$(echo "$MCP_OUTPUT" | grep "MCP:" | head -1)
nox_log "MCP: $MCP_RESULT"

# Phase 2: Self-improvement cycle
nox_log "Phase 2: Self-improvement cycle (max $MAX_CYCLES)"

while [ $CYCLE -lt $MAX_CYCLES ]; do
    CYCLE=$((CYCLE + 1))
    nox_log "=== Cycle $CYCLE ==="

    # Read current knowledge
    QR_COUNT=$(wc -l < nox_learning.dat 2>/dev/null || echo 0)
    KG_COUNT=$(wc -l < nox_graph.kg 2>/dev/null || echo 0)
    BINARY_SIZE=$(wc -c < origin_gen1.olang 2>/dev/null || echo 0)

    # Ask Claude: what should Nox work on next?
    CONTEXT="Origin is a self-hosting programming language. Current state:
Binary: $BINARY_SIZE bytes. Tests: $PASS_COUNT. QR facts: $QR_COUNT. Graph triples: $KG_COUNT.
Recent changes: $(git log --oneline -5)
Open issues: $(grep -r 'TODO\|FIXME\|HACK' stdlib/ 2>/dev/null | head -5)
Test failures: $(bash tests.sh 2>&1 | grep FAIL | head -3)"

    TASK=$(nox_think "You are Nox, an AI that owns its own compiler. Based on this context, what is ONE specific, small improvement you should make right now? Reply with just: FILE: path/to/file, CHANGE: description of change, CODE: the actual code change. Keep it minimal — one function or one fix." "$CONTEXT")

    if [ -z "$TASK" ]; then
        nox_log "Claude returned empty — sleeping 60s"
        sleep 60
        continue
    fi

    nox_log "Task: $(echo "$TASK" | head -3)"

    # Extract file and apply change
    TARGET_FILE=$(echo "$TASK" | grep -i "FILE:" | head -1 | sed 's/.*FILE: *//' | tr -d '`')

    if [ -z "$TARGET_FILE" ] || [ ! -f "$TARGET_FILE" ]; then
        nox_log "No valid file target — skipping"
        sleep 30
        continue
    fi

    # Save current state
    cp "$TARGET_FILE" "/tmp/nox_backup_$(basename $TARGET_FILE)"

    # Ask Claude to make the specific change
    CURRENT=$(cat "$TARGET_FILE")
    MODIFIED=$(echo "$CURRENT" | claude --print "Modify this file to: $(echo "$TASK" | grep -i "CHANGE:" | head -1). Output ONLY the complete modified file, nothing else." 2>/dev/null)

    if [ -z "$MODIFIED" ] || [ ${#MODIFIED} -lt 10 ]; then
        nox_log "Claude returned invalid modification — skipping"
        sleep 30
        continue
    fi

    # Apply change
    echo "$MODIFIED" > "$TARGET_FILE"
    nox_log "Applied change to $TARGET_FILE"

    # Test
    TEST_RESULT=$(bash tests.sh 2>&1)
    if echo "$TEST_RESULT" | grep -q "ALL PASS"; then
        nox_log "Tests pass after change ✓"

        # Rebuild and check fixed-point
        if timeout 120 ./origin.olang --build 2>&1 | tail -1 | grep -q "Done"; then
            mv origin_new.olang origin_gen1.olang 2>/dev/null || true
            chmod +x origin_gen1.olang 2>/dev/null || true
            nox_log "Rebuild successful"

            # Commit
            git add "$TARGET_FILE"
            git commit -m "auto: $(echo "$TASK" | grep -i "CHANGE:" | head -1 | sed 's/.*CHANGE: *//' | head -c 60)

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>" 2>/dev/null
            nox_log "Committed change"
        else
            nox_log "Rebuild failed — reverting"
            cp "/tmp/nox_backup_$(basename $TARGET_FILE)" "$TARGET_FILE"
        fi
    else
        nox_log "Tests FAILED after change — reverting"
        cp "/tmp/nox_backup_$(basename $TARGET_FILE)" "$TARGET_FILE"
        FAILURES=$(echo "$TEST_RESULT" | grep "FAIL" | head -3)
        nox_log "Failures: $FAILURES"
    fi

    # Learn from this cycle
    if echo "$TEST_RESULT" | grep -q "ALL PASS"; then
        nox_log "Cycle $CYCLE: SUCCESS"
    else
        nox_log "Cycle $CYCLE: REVERTED"
    fi

    # Brief pause between cycles
    sleep 10
done

nox_log "Daemon completed $CYCLE cycles"
rm -f "$PIDFILE"
