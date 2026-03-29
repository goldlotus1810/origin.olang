#!/bin/bash
# Feed large documents into Nox's brain in safe chunks
# Usage: bash scripts/feed_knowledge.sh [file1] [file2] ...
# Default: feeds all docs/*.md + homeos.knowledge

ORIGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BINARY="$ORIGIN_DIR/origin.olang"

if [ ! -x "$BINARY" ]; then
    echo "Error: $BINARY not found"
    exit 1
fi

CHUNK_SIZE=6000  # 6KB per chunk — safe for heap
TOTAL_FACTS=0

feed_file() {
    local file="$1"
    local content
    local len

    if [ ! -f "$file" ]; then
        echo "  Skip: $file (not found)"
        return
    fi

    # Strip markdown if .md
    if [[ "$file" == *.md ]]; then
        # Remove code blocks, strip # > * | [ ] `
        content=$(sed '/^```/,/^```/d' "$file" | sed 's/^[#>*|`~-]/ /g; s/\[//g; s/\]//g')
    else
        content=$(cat "$file")
    fi

    len=${#content}
    echo "  $file: ${len} chars"

    # Split into chunks and feed each via REPL
    local offset=0
    local chunk_num=0
    while [ $offset -lt $len ]; do
        local chunk="${content:$offset:$CHUNK_SIZE}"
        # Extend to next newline
        local extra="${content:$((offset + CHUNK_SIZE)):200}"
        local nl_pos=$(echo "$extra" | grep -bo $'\n' | head -1 | cut -d: -f1)
        if [ -n "$nl_pos" ]; then
            chunk="${content:$offset:$((CHUNK_SIZE + nl_pos))}"
            offset=$((offset + CHUNK_SIZE + nl_pos + 1))
        else
            offset=$((offset + CHUNK_SIZE))
        fi

        # Feed chunk as learn commands (split by sentence)
        local facts=0
        while IFS= read -r sentence; do
            # Skip short lines, code lines, empty lines
            [ ${#sentence} -lt 15 ] && continue
            echo "$sentence" | grep -qE '[{};].*[{};]' && continue
            echo "$sentence" | grep -qE '^(fn |let |if |while )' && continue

            echo "learn $sentence" | timeout 5 "$BINARY" >/dev/null 2>&1
            facts=$((facts + 1))
        done <<< "$(echo "$chunk" | tr '.' '\n' | tr '!' '\n' | tr '?' '\n')"

        TOTAL_FACTS=$((TOTAL_FACTS + facts))
        chunk_num=$((chunk_num + 1))
        echo "    chunk $chunk_num: +$facts facts (total: $TOTAL_FACTS)"
    done
}

echo "=== Nox Knowledge Feeder ==="
echo "Binary: $BINARY"
echo ""

if [ $# -gt 0 ]; then
    for f in "$@"; do
        feed_file "$f"
    done
else
    echo "Feeding default docs..."
    feed_file "$ORIGIN_DIR/docs/olang_handbook.md"
    feed_file "$ORIGIN_DIR/docs/BLUEPRINT.md"
    feed_file "$ORIGIN_DIR/docs/LANGUAGE_GENOME.md"
fi

echo ""
echo "=== Done: $TOTAL_FACTS facts fed ==="
echo "Verify: echo 'inspect' | $BINARY"
