#!/bin/bash
# MCP Server integration test — all 8 tools
cd "$(dirname "$0")/.."
PASS=0; FAIL=0

check() {
    local name="$1" expect="$2" id="$3"
    local line=$(echo "$RESPONSE" | grep "\"id\":$id")
    if echo "$line" | grep -q "$expect"; then
        echo "  ✓ $name"
        PASS=$((PASS+1))
    else
        echo "  ✗ $name — expected '$expect'"
        echo "    got: $line"
        FAIL=$((FAIL+1))
    fi
}

# Run full MCP session
RESPONSE=$(printf '%s\n' \
    '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{}},"id":0}' \
    '{"jsonrpc":"2.0","method":"tools/list","id":1}' \
    '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"olang_eval","arguments":{"code":"emit 6 * 7"}},"id":2}' \
    '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"know_learn","arguments":{"fact":"MCP test fact 12345"}},"id":3}' \
    '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"know_query","arguments":{"question":"12345"}},"id":4}' \
    '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"emotion_encode","arguments":{"text":"toi vui"}},"id":5}' \
    '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"safety_check","arguments":{"text":"hello"}},"id":6}' \
    '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"nox_status","arguments":{}},"id":7}' \
    | timeout 15 ./origin.olang --mcp 2>&1)

echo "═══ MCP SERVER TEST ═══"
check "initialize"     "protocolVersion" 0
check "tools/list"     "olang_eval" 1
check "olang_eval"     "ok" 2
check "know_learn"     "Learned" 3
check "know_query"     "12345" 4
check "emotion_encode" "Emotion 5D" 5
check "safety_check"   "SAFE" 6
check "nox_status"     "Nox Brain Status" 7

# Check no stdout leak (no bare numbers before JSON)
LEAKS=$(echo "$RESPONSE" | grep -v '^{' | grep -v '^$' | wc -l)
if [ "$LEAKS" -eq 0 ]; then
    echo "  ✓ no stdout leaks"
    PASS=$((PASS+1))
else
    echo "  ✗ stdout leaks detected ($LEAKS lines)"
    FAIL=$((FAIL+1))
fi

echo "═══════════════════════"
echo "  MCP: $PASS/$((PASS+FAIL)) passed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
