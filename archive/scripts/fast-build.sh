#!/bin/bash
# Fast incremental build — only recompile if source changed
# Compares source mtime vs cached bytecode mtime
# Falls back to full build if cache missing

ORIGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CACHE_DIR="$ORIGIN_DIR/.build-cache"
BINARY="$ORIGIN_DIR/origin.olang"

mkdir -p "$CACHE_DIR"

needs_rebuild() {
    local src_newest=$(find "$ORIGIN_DIR/stdlib" "$ORIGIN_DIR/vm" -name "*.ol" -o -name "*.S" 2>/dev/null | xargs stat -c %Y 2>/dev/null | sort -rn | head -1)
    local bin_mtime=$(stat -c %Y "$BINARY" 2>/dev/null || echo 0)

    if [ -z "$src_newest" ] || [ "$src_newest" -gt "$bin_mtime" ]; then
        return 0  # needs rebuild
    fi
    return 1  # up to date
}

if needs_rebuild; then
    echo "Source changed — rebuilding..."
    time make -C "$ORIGIN_DIR" self-build 2>&1 | tail -5
else
    echo "Up to date — no rebuild needed."
    echo "Binary: $BINARY ($(stat -c %s "$BINARY") bytes)"
fi
