#!/bin/bash
# oltest.sh — Compile + run .ol test files using Olang compiler (no Python)
# Usage: ./tools/oltest.sh test/vm2/test_throw_across.ol
#        ./tools/oltest.sh test/vm2/           # run all .ol in dir
#        ./tools/oltest.sh                     # run all tests

set -e

COMPILER="./compiler.olang"
VM="./vm/x86_64/vm_nox"

if [ ! -f "$COMPILER" ]; then
    echo "ERROR: $COMPILER not found. Run: make vm && build compiler first."
    exit 1
fi
if [ ! -f "$VM" ]; then
    echo "ERROR: $VM not found. Run: make vm first."
    exit 1
fi

run_test() {
    local src="$1"
    local out="/tmp/oltest_$(basename "$src" .ol).olang"

    # Compile
    printf '%s\n%s\n' "$src" "$out" > /tmp/.nox_args
    if ! "$COMPILER" > /tmp/oltest_compile.log 2>&1; then
        echo "COMPILE FAIL: $src"
        cat /tmp/oltest_compile.log
        return 1
    fi

    # Run
    local result
    if result=$("$out" 2>&1); then
        if echo "$result" | grep -q "ALL PASS"; then
            local count=$(echo "$result" | grep -oP '\d+/\d+ tests passed' | head -1)
            echo "PASS: $src ($count)"
            return 0
        elif echo "$result" | grep -q "FAIL"; then
            echo "FAIL: $src"
            echo "$result" | grep "FAIL"
            return 1
        else
            echo "OK: $src (no test framework)"
            return 0
        fi
    else
        echo "CRASH: $src (exit code $?)"
        echo "$result" | tail -5
        return 1
    fi
}

# Collect test files
TESTS=()
if [ $# -eq 0 ]; then
    # Default: all test files
    for f in test/vm2/test_*.ol; do
        TESTS+=("$f")
    done
elif [ -d "$1" ]; then
    for f in "$1"/test_*.ol; do
        TESTS+=("$f")
    done
else
    TESTS=("$@")
fi

# Run
TOTAL=0
PASSED=0
FAILED=0

for t in "${TESTS[@]}"; do
    TOTAL=$((TOTAL + 1))
    if run_test "$t"; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "═══ $PASSED/$TOTAL test files passed ═══"
if [ $FAILED -gt 0 ]; then
    echo "$FAILED FAILED"
    exit 1
else
    echo "ALL PASS"
fi
