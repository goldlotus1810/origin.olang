#!/bin/bash
# Olang Code Analyzer — finds duplicates, conflicts, dead code
# Usage: bash tools/analyze.sh

STDLIB="stdlib"
B="\e[1m"; N="\e[0m"; R="\e[31m"; G="\e[32m"; Y="\e[33m"; C="\e[36m"

echo -e "${C}${B}═══ OLANG CODE ANALYZER ═══${N}"
echo ""

# ── 1. LOC Summary ──
echo -e "${B}[1] Lines of Code${N}"
total=0
for dir in bootstrap homeos lib; do
    if [ -d "$STDLIB/$dir" ]; then
        c=$(cat "$STDLIB/$dir"/*.ol 2>/dev/null | wc -l)
        n=$(ls "$STDLIB/$dir"/*.ol 2>/dev/null | wc -l)
        echo "  $dir/: $n files, $c LOC"
        total=$((total + c))
    fi
done
root_c=$(cat "$STDLIB"/*.ol 2>/dev/null | wc -l)
root_n=$(ls "$STDLIB"/*.ol 2>/dev/null | wc -l)
echo "  root: $root_n files, $root_c LOC"
total=$((total + root_c))
vm_loc=$(wc -l < vm/x86_64/vm_x86_64.S 2>/dev/null || echo 0)
echo "  VM ASM: $vm_loc LOC"
echo -e "  ${G}Total: $total LOC Olang + $vm_loc LOC ASM${N}"
echo ""

# ── 2. Duplicate Function Names ──
echo -e "${B}[2] Duplicate Function Names${N}"
grep -rn '^pub fn \|^fn ' "$STDLIB"/*.ol "$STDLIB"/**/*.ol 2>/dev/null \
    | sed 's/(.*//' | awk -F'fn ' '{print $2}' | sort | uniq -cd | sort -rn | while read cnt name; do
    if [ "$cnt" -gt 1 ]; then
        echo -e "  ${Y}$name${N} — defined $cnt times:"
        grep -rn "^pub fn $name\|^fn $name" "$STDLIB"/*.ol "$STDLIB"/**/*.ol 2>/dev/null | sed 's/^/    /'
    fi
done
echo ""

# ── 3. Global Variable Collisions ──
echo -e "${B}[3] Global Variables (top-level let)${N}"
grep -rn '^let ' "$STDLIB"/*.ol "$STDLIB"/**/*.ol 2>/dev/null \
    | grep -v '^\s*//' | sed 's/=.*//' | awk -F'let ' '{print $2}' | tr -d ' ;' | sort | uniq -cd | sort -rn | head -20 | while read cnt name; do
    if [ "$cnt" -gt 1 ] && [ ${#name} -gt 1 ]; then
        echo -e "  ${Y}$name${N} — defined $cnt times"
    fi
done
echo ""

# ── 4. Large Files (>200 LOC) ──
echo -e "${B}[4] Large Files (>200 LOC)${N}"
for f in "$STDLIB"/*.ol "$STDLIB"/**/*.ol; do
    [ -f "$f" ] || continue
    loc=$(wc -l < "$f")
    if [ "$loc" -gt 200 ]; then
        fname=$(echo "$f" | sed "s|$STDLIB/||")
        fns=$(grep -c '^pub fn \|^fn ' "$f")
        echo "  $fname: $loc LOC, $fns functions"
    fi
done
echo ""

# ── 5. Functions Without Callers ──
echo -e "${B}[5] Potentially Dead Functions${N}"
dead=0
grep -rn '^fn _[a-z]' "$STDLIB"/*.ol "$STDLIB"/**/*.ol 2>/dev/null | while IFS=: read file line rest; do
    fname=$(echo "$rest" | sed 's/fn //;s/(.*//')
    # Count references (excluding definition)
    refs=$(grep -r "$fname" "$STDLIB" 2>/dev/null | grep -v "^$file:$line:" | grep -c "$fname")
    if [ "$refs" -eq 0 ]; then
        fshort=$(echo "$file" | sed "s|$STDLIB/||")
        echo "  ${Y}$fname${N} in $fshort:$line — 0 references"
        dead=$((dead + 1))
    fi
done
echo ""

# ── 6. TODO/FIXME/HACK markers ──
echo -e "${B}[6] TODO/FIXME/HACK markers${N}"
count=$(grep -rn 'TODO\|FIXME\|HACK\|XXX\|STUB\|stub' "$STDLIB"/*.ol "$STDLIB"/**/*.ol 2>/dev/null | grep -v '^\s*//' | wc -l)
if [ "$count" -gt 0 ]; then
    grep -rn 'TODO\|FIXME\|HACK\|XXX\|STUB\|stub' "$STDLIB"/*.ol "$STDLIB"/**/*.ol 2>/dev/null | grep -v '^\s*//' | head -15 | while IFS= read line; do
        echo "  $line" | sed "s|$STDLIB/||"
    done
    [ "$count" -gt 15 ] && echo "  ... and $((count - 15)) more"
fi
echo ""

# ── 7. Builtin Coverage ──
echo -e "${B}[7] VM Builtins Usage${N}"
# Count builtins defined in VM
vm_builtins=$(grep -c '\.call_' vm/x86_64/vm_x86_64.S 2>/dev/null)
# Count builtins actually called from stdlib
used_builtins=$(grep -roh '__[a-z_]*' "$STDLIB"/*.ol "$STDLIB"/**/*.ol 2>/dev/null | sort -u | wc -l)
echo "  VM builtins: ~$vm_builtins handlers"
echo "  Stdlib uses: ~$used_builtins unique __xxx calls"
echo ""

# ── 8. File Size Distribution ──
echo -e "${B}[8] Binary${N}"
if [ -f origin.olang ]; then
    size=$(wc -c < origin.olang)
    echo "  origin.olang: $((size/1024))K ($size bytes)"
fi

echo ""
echo -e "${C}═══ ANALYSIS COMPLETE ═══${N}"
