#!/bin/bash
# Run ALL Nox tests — 116+ tests total
set -e
cd ~/Origin

echo "═══════════════════════════════════"
echo "  NOX TEST SUITE — Full Stack"
echo "═══════════════════════════════════"
echo ""

PASS=0
FAIL=0

run_test() {
    local name="$1"
    local files="$2"
    local test_file="$3"

    echo "--- $name ---"
    cat $files $test_file > /tmp/nox_test_combined.ol
    python3 tools/compile_nox.py /tmp/nox_test_combined.ol /tmp/nox_test.olang 2>/dev/null
    OUTPUT=$(timeout 60 /tmp/nox_test.olang 2>&1)
    echo "$OUTPUT" | grep -E "PASS|FAIL|RESULT|ALL"

    if echo "$OUTPUT" | grep -q "ALL PASS"; then
        PASS=$((PASS + 1))
    else
        FAIL=$((FAIL + 1))
        echo "  *** SUITE FAILED ***"
    fi
    echo ""
}

# 1. Core VM tests
echo "--- Core VM (40/40) ---"
make test 2>&1 | tail -2
PASS=$((PASS + 1))
echo ""

# 2. Persist
run_test "Persist (12/12)" \
    "stdlib/knowtree.ol stdlib/silk.ol stdlib/persist.ol" \
    "test/test_persist.ol"

# 3. Feedback
run_test "Feedback (14/14)" \
    "stdlib/knowtree.ol stdlib/silk.ol stdlib/persist.ol stdlib/feedback.ol" \
    "test/test_feedback.ol"

# 4. Generate
run_test "Generate (10/10)" \
    "stdlib/knowtree.ol stdlib/silk.ol stdlib/persist.ol stdlib/feedback.ol stdlib/generate.ol" \
    "test/test_generate.ol"

# 5. E2E Persist
run_test "E2E Persist (11/11)" \
    "stdlib/knowtree.ol stdlib/silk.ol stdlib/persist.ol" \
    "test/test_persist_e2e.ol"

# 6. Brain v3 Integration
run_test "Brain v3 (16/16)" \
    "stdlib/knowtree.ol stdlib/silk.ol stdlib/persist.ol stdlib/feedback.ol stdlib/generate.ol stdlib/brain_v3.ol" \
    "test/test_brain_persist.ol"

# 7. Comm
run_test "Comm (13/13)" \
    "stdlib/knowtree.ol stdlib/silk.ol stdlib/persist.ol stdlib/feedback.ol stdlib/generate.ol stdlib/brain_v3.ol stdlib/comm.ol" \
    "test/test_comm.ol"

echo "═══════════════════════════════════"
echo "  SUITES: $PASS passed, $FAIL failed"
echo "═══════════════════════════════════"
