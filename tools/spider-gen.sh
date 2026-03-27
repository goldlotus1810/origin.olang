#!/bin/bash
# Spider Test Generator — creates random Olang test cases
# Each test: CODE | EXPECTED_OUTPUT
# Output to stdout, one test per line (tab-separated)

# ── Random helpers ──
rand_int() { echo $(( RANDOM % $1 )); }
rand_pick() { local arr=("$@"); echo "${arr[$(( RANDOM % ${#arr[@]} ))]}"; }
rand_str() { cat /dev/urandom | tr -dc 'a-z' | head -c "$1"; }

# ── Generate nested builtin tests ──
gen_nested() {
    local strs=("abc" "hello" "test" "x" "olang" "$(rand_str 3)" "$(rand_str 5)")
    local s=$(rand_pick "${strs[@]}")
    local start=$(rand_int 4)
    local end=$((start + 2 + RANDOM % 6))

    # Compute expected via separated form
    local expected=$(echo "let h=__sha256(\"$s\"); emit __substr(h,$start,$end);" | timeout 3 ./origin.olang 2>/dev/null | sed -n '3p' | sed 's/⦿ //')
    [ -z "$expected" ] && return

    echo -e "emit __substr(__sha256(\"$s\"),$start,$end);\t$expected\tnest:sha+substr($s,$start,$end)"
}

gen_nested_tostr() {
    local n=$((RANDOM % 99999))
    local start=$(rand_int 2)
    local end=$((start + 1 + RANDOM % 3))
    local expected=$(echo "let s=__to_string($n); emit __substr(s,$start,$end);" | timeout 3 ./origin.olang 2>/dev/null | sed -n '3p' | sed 's/⦿ //')
    [ -z "$expected" ] && return
    echo -e "emit __substr(__to_string($n),$start,$end);\t$expected\tnest:tostr+substr($n,$start,$end)"
}

gen_nested_len() {
    local s=$(rand_pick "abc" "hello" "test" "$(rand_str 4)")
    echo -e "emit len(__sha256(\"$s\"));\t64\tnest:len+sha($s)"
}

gen_nested_char() {
    local s=$(rand_pick "abc" "hello" "test")
    local i=$(rand_int 8)
    local expected=$(echo "let h=__sha256(\"$s\"); emit char_at(h,$i);" | timeout 3 ./origin.olang 2>/dev/null | sed -n '3p' | sed 's/⦿ //')
    [ -z "$expected" ] && return
    echo -e "emit char_at(__sha256(\"$s\"),$i);\t$expected\tnest:char+sha($s,$i)"
}

# ── Generate interpolation tests ──
gen_interp() {
    local a=$((RANDOM % 100))
    local b=$((1 + RANDOM % 50))
    local op=$(rand_pick "+" "-" "*")
    local expected=$(echo "emit $a${op}$b;" | timeout 3 ./origin.olang 2>/dev/null | sed -n '3p' | sed 's/⦿ //')
    [ -z "$expected" ] && return
    echo -e "emit \$\"{$a${op}$b}\";\t$expected\tinterp:$a${op}$b"
}

# ── Generate operator tests ──
gen_op() {
    local a=$((RANDOM % 100))
    local b=$((1 + RANDOM % 50))
    local op=$(rand_pick "+" "-" "*" "/" "%")
    local expected=$(echo "emit $a${op}$b;" | timeout 3 ./origin.olang 2>/dev/null | sed -n '3p' | sed 's/⦿ //')
    [ -z "$expected" ] && return
    echo -e "emit $a${op}$b;\t$expected\top:$a${op}$b"
}

# ── Generate function tests ──
gen_fn() {
    local n=$((5 + RANDOM % 15))
    echo -e "fn fib(n){if n<2{return n;};return fib(n-1)+fib(n-2);}; emit fib($n);\t$(python3 -c "
def fib(n):
    if n<2: return n
    return fib(n-1)+fib(n-2)
print(fib($n))
" 2>/dev/null)\tfn:fib($n)"
}

gen_fact() {
    local n=$((2 + RANDOM % 8))
    echo -e "fn fact(n){if n<2{return 1;};return n*fact(n-1);}; emit fact($n);\t$(python3 -c "
import math; print(math.factorial($n))
" 2>/dev/null)\tfn:fact($n)"
}

# ── Generate array tests ──
gen_arr() {
    local a=$((RANDOM % 100))
    local b=$((RANDOM % 100))
    local c=$((RANDOM % 100))
    local i=$(rand_int 3)
    local vals=($a $b $c)
    echo -e "emit [$a,$b,$c][$i];\t${vals[$i]}\tarr:literal_idx($i)"
}

# ── Main: generate N random tests ──
N=${1:-20}
for i in $(seq 1 $N); do
    case $((RANDOM % 8)) in
        0) gen_nested ;;
        1) gen_nested_tostr ;;
        2) gen_nested_len ;;
        3) gen_nested_char ;;
        4) gen_interp ;;
        5) gen_op ;;
        6) gen_fn ;;
        7) gen_arr ;;
    esac
done
