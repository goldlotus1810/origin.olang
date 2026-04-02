#!/bin/bash
# difftest.sh — Differential testing: Python compiler vs Olang compiler
# Every .ol file must produce IDENTICAL bytecode from both compilers.
# This is the strongest test for compiler correctness.
set -e

PY_COMPILER="python3 tools/compile_nox.py"
OL_COMPILER="./compiler.olang"

if [ ! -f "$OL_COMPILER" ]; then
    echo "ERROR: $OL_COMPILER not found"
    exit 1
fi

# Collect test files
TESTS=()
if [ $# -eq 0 ]; then
    for f in test/vm2/test_*.ol; do TESTS+=("$f"); done
    TESTS+=("stdlib/compiler.ol")
else
    TESTS=("$@")
fi

TOTAL=0
PASSED=0
FAILED=0

for src in "${TESTS[@]}"; do
    TOTAL=$((TOTAL + 1))
    base=$(basename "$src" .ol)
    py_out="/tmp/difftest_py_${base}.olang"
    ol_out="/tmp/difftest_ol_${base}.olang"

    # Compile with Python
    if ! $PY_COMPILER "$src" "$py_out" > /dev/null 2>&1; then
        echo "PY_FAIL: $src"
        FAILED=$((FAILED + 1))
        continue
    fi

    # Compile with Olang
    printf '%s\n%s\n' "$src" "$ol_out" > /tmp/.nox_args
    if ! $OL_COMPILER > /dev/null 2>&1; then
        echo "OL_FAIL: $src"
        FAILED=$((FAILED + 1))
        continue
    fi

    # Compare bytecode (skip VM binary prefix — only compare appended bytecode)
    # Both outputs = VM binary + bytecode. VM binary is same, so full diff works.
    if diff "$py_out" "$ol_out" > /dev/null 2>&1; then
        echo "MATCH: $src"
        PASSED=$((PASSED + 1))
    else
        py_size=$(wc -c < "$py_out")
        ol_size=$(wc -c < "$ol_out")
        echo "DIFF: $src (py=${py_size} ol=${ol_size})"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "═══ Differential: $PASSED/$TOTAL match ═══"
if [ $FAILED -gt 0 ]; then
    echo "$FAILED DIFFER — compilers not in sync"
    exit 1
else
    echo "ALL MATCH — Python == Olang compiler output"
fi
