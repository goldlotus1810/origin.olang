#!/bin/bash
# nox_study.sh — Nox reads source documents and learns
# Scans Origin_project, Go code, concect files for insights
# Extracts knowledge → nox_learning.dat + nox_graph.kg via MCP

set -euo pipefail
cd /home/lupin/Origin

LOGFILE="nox_study.log"
echo "[$(date)] Study session started" | tee -a "$LOGFILE"

# Ensure MCP binary exists
if [ ! -x origin_mcp.olang ]; then
    cp origin.olang origin_mcp.olang
    chmod +x origin_mcp.olang
fi

mcp_call() {
    local tool="$1"
    local args="$2"
    (echo '{"jsonrpc":"2.0","id":99,"method":"initialize","params":{}}'; sleep 0.2; echo "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"$tool\",\"arguments\":$args}}"; sleep 0.3) | timeout 5 ./origin_mcp.olang --mcp 2>/dev/null | tail -1
}

observe_fact() {
    local fact="$1"
    mcp_call "dn_observe" "{\"fact\":\"$fact\"}" >/dev/null 2>&1
    echo "  observed: $fact" | tee -a "$LOGFILE"
}

add_triple() {
    local triple="$1"
    mcp_call "kg_add" "{\"triple\":\"$triple\"}" >/dev/null 2>&1
    echo "  triple: $triple" | tee -a "$LOGFILE"
}

# Study 1: Read Go architecture from Origin_project
echo "[$(date)] Studying Origin_project Go code..." | tee -a "$LOGFILE"

if [ -d /home/lupin/Origin_project ]; then
    # Find key Go files
    for gofile in $(find /home/lupin/Origin_project -name "*.go" -path "*/olang/*" | head -10); do
        basename=$(basename "$gofile" .go)
        echo "  Reading: $gofile" | tee -a "$LOGFILE"

        # Extract function signatures
        funcs=$(grep "^func " "$gofile" 2>/dev/null | head -5 | sed 's/func //' | sed 's/{.*//')
        for func in $funcs; do
            add_triple "rust_compiler|has_func|$func"
        done
    done
fi

# Study 2: Read concect documents for design patterns
echo "[$(date)] Studying concect documents..." | tee -a "$LOGFILE"

for doc in /home/lupin/Bản\ tải\ về/homeos_v19_final\ \(1\)/concect*.md; do
    if [ -f "$doc" ]; then
        echo "  Reading: $doc" | tee -a "$LOGFILE"
        # Extract key concepts (lines with ==, →, or definitions)
        grep -E "^\s*(QT[0-9]|[A-Z]{3,}.*=|→)" "$doc" 2>/dev/null | head -10 | while read -r line; do
            clean=$(echo "$line" | tr -d '`' | head -c 80)
            if [ ${#clean} -gt 5 ]; then
                observe_fact "$clean"
            fi
        done
    fi
done

# Study 3: Extract ISL/SDF patterns from Go code
echo "[$(date)] Studying ISL/SDF patterns..." | tee -a "$LOGFILE"

if [ -d /home/lupin/Origin_project/crates ]; then
    # Rust crates structure
    for rs in $(find /home/lupin/Origin_project/crates -name "*.rs" | head -10); do
        basename=$(basename "$rs" .rs)
        add_triple "rust_crate|contains|$basename"
    done
fi

# Study 4: Read node*.md files for architecture insights
echo "[$(date)] Studying node architecture..." | tee -a "$LOGFILE"

for nodemd in /home/lupin/GolandProjects/Origin/node*.md; do
    if [ -f "$nodemd" ]; then
        basename=$(basename "$nodemd" .md)
        echo "  Reading: $nodemd" | tee -a "$LOGFILE"
        # First 3 lines usually contain the key insight
        head -3 "$nodemd" 2>/dev/null | while read -r line; do
            clean=$(echo "$line" | tr -d '#' | tr -d '`' | sed 's/^[[:space:]]*//' | head -c 80)
            if [ ${#clean} -gt 10 ]; then
                observe_fact "$clean"
            fi
        done
    fi
done

# Summary
echo "[$(date)] Study complete" | tee -a "$LOGFILE"
echo "  Knowledge files:" | tee -a "$LOGFILE"
echo "    nox_learning.dat: $(wc -l < nox_learning.dat) entries" | tee -a "$LOGFILE"
echo "    nox_graph.kg: $(wc -l < nox_graph.kg) triples" | tee -a "$LOGFILE"
