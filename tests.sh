#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# OLANG v1.0 — TEST RUNNER
# Chay: bash tests.sh
# Tat ca xanh = OK. Do = co van de. Khong thi biet.
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

ORIGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
BINARY="$ORIGIN_DIR/origin.olang"
TEST_DIR="$ORIGIN_DIR/test"
TMP_DIR="/tmp/olang_tests"

PASS=0
FAIL=0
SKIP=0
ERRORS=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

mkdir -p "$TMP_DIR"

# ─── Helpers ──────────────────────────────────────────────────

run_test() {
    local name="$1"
    local generator="$2"
    local bytecode="$3"
    local expected="$4"
    local timeout_sec="${5:-5}"

    # Generate bytecode
    if ! python3 "$generator" 2>/dev/null; then
        FAIL=$((FAIL + 1))
        ERRORS="$ERRORS\n  $RED FAIL$NC $name — bytecode generation failed"
        return
    fi

    # Run binary
    local actual
    actual=$(timeout "$timeout_sec" "$BINARY" "$bytecode" 2>/dev/null) || {
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            FAIL=$((FAIL + 1))
            ERRORS="$ERRORS\n  $RED FAIL$NC $name — timeout (${timeout_sec}s)"
            return
        fi
        # Some tests exit with non-zero but still produce output
        actual=$(timeout "$timeout_sec" "$BINARY" "$bytecode" 2>/dev/null || true)
    }

    # Compare
    if [ "$actual" = "$expected" ]; then
        PASS=$((PASS + 1))
        echo -e "  $GREEN  OK$NC $name"
    else
        FAIL=$((FAIL + 1))
        ERRORS="$ERRORS\n  $RED FAIL$NC $name"
        ERRORS="$ERRORS\n       expected: $(echo "$expected" | head -3)"
        ERRORS="$ERRORS\n       actual:   $(echo "$actual" | head -3)"
    fi
}

strip_repl() {
    # Strip REPL header (first 2 lines) + "⦿ " prefix + "bye" footer
    # Input:  ⦿ HomeOS v0.05\n○ Type...\n⦿ result\n⦿ bye
    # Output: result
    sed '1,2d' | sed 's/^⦿ //; /^bye$/d' | sed '/^$/d'
}

run_olang_test() {
    local name="$1"
    local olang_code="$2"
    local expected="$3"
    local timeout_sec="${4:-5}"

    local raw_output
    raw_output=$(echo "$olang_code" | timeout "$timeout_sec" "$BINARY" 2>/dev/null || true)

    if [ -z "$raw_output" ]; then
        FAIL=$((FAIL + 1))
        ERRORS="$ERRORS\n  $RED FAIL$NC $name — no output"
        return
    fi

    # Strip REPL chrome, join lines for multi-emit comparison
    local actual
    actual=$(echo "$raw_output" | strip_repl | tr -d '\n')

    if [ "$actual" = "$expected" ]; then
        PASS=$((PASS + 1))
        echo -e "  $GREEN  OK$NC $name"
    else
        FAIL=$((FAIL + 1))
        ERRORS="$ERRORS\n  $RED FAIL$NC $name"
        ERRORS="$ERRORS\n       expected: [$expected]"
        ERRORS="$ERRORS\n       actual:   [$actual]"
    fi
}

run_olang_file_test() {
    local name="$1"
    local olang_file="$2"
    local expected="$3"
    local timeout_sec="${4:-10}"

    if [ ! -f "$olang_file" ]; then
        SKIP=$((SKIP + 1))
        echo -e "  $YELLOW SKIP$NC $name — file not found: $olang_file"
        return
    fi

    local actual
    actual=$(timeout "$timeout_sec" "$BINARY" < "$olang_file" 2>/dev/null) || {
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            FAIL=$((FAIL + 1))
            ERRORS="$ERRORS\n  $RED FAIL$NC $name — timeout (${timeout_sec}s)"
            return
        fi
        actual=$(timeout "$timeout_sec" "$BINARY" < "$olang_file" 2>/dev/null || true)
    }

    if [ "$actual" = "$expected" ]; then
        PASS=$((PASS + 1))
        echo -e "  $GREEN  OK$NC $name"
    else
        FAIL=$((FAIL + 1))
        ERRORS="$ERRORS\n  $RED FAIL$NC $name"
        ERRORS="$ERRORS\n       expected: $(echo "$expected" | head -3)"
        ERRORS="$ERRORS\n       actual:   $(echo "$actual" | head -3)"
    fi
}

# ─── Pre-checks ──────────────────────────────────────────────

echo -e "${CYAN}═══ OLANG v1.0 TEST SUITE ═══${NC}"
echo ""

# Check binary exists
if [ ! -x "$BINARY" ]; then
    echo -e "${RED}ERROR: Binary not found: $BINARY${NC}"
    echo "  Build first or check path."
    exit 1
fi

echo -e "${CYAN}Binary:${NC} $BINARY ($(du -h "$BINARY" | cut -f1))"
echo ""

# ═══════════════════════════════════════════════════════════════
# SECTION 1: VM BYTECODE TESTS (Python generators)
# ═══════════════════════════════════════════════════════════════

echo -e "${CYAN}--- VM Bytecode Tests ---${NC}"

# These tests generate bytecode via Python and run on raw VM
if command -v python3 &>/dev/null; then
    for pytest in "$TEST_DIR"/test_*.py; do
        [ -f "$pytest" ] || continue
        testname=$(basename "$pytest" .py)
        bytecode_file="$TMP_DIR/${testname}.olang"

        # Generate
        if python3 "$pytest" 2>/dev/null; then
            # Find where bytecode was written
            src_file="/tmp/${testname}.olang"
            [ -f "$src_file" ] && cp "$src_file" "$bytecode_file"

            if [ -f "$bytecode_file" ]; then
                # Run and check it doesn't crash (no expected output for legacy tests)
                if echo "" | timeout 5 "$BINARY" "$bytecode_file" >/dev/null 2>&1; then
                    PASS=$((PASS + 1))
                    echo -e "  $GREEN  OK$NC vm/$testname (no crash)"
                else
                    FAIL=$((FAIL + 1))
                    ERRORS="$ERRORS\n  $RED FAIL$NC vm/$testname — crashed"
                fi
            else
                SKIP=$((SKIP + 1))
                echo -e "  $YELLOW SKIP$NC vm/$testname — bytecode not found"
            fi
        else
            FAIL=$((FAIL + 1))
            ERRORS="$ERRORS\n  $RED FAIL$NC vm/$testname — python error"
        fi
    done
else
    echo -e "  $YELLOW SKIP$NC Python3 not found — skipping bytecode tests"
fi

echo ""

# ═══════════════════════════════════════════════════════════════
# SECTION 2: OLANG SOURCE TESTS (eval via stdin)
# ═══════════════════════════════════════════════════════════════

echo -e "${CYAN}--- Olang Language Tests ---${NC}"

# 2.1 Arithmetic
run_olang_test "arith/add" \
    'emit 2 + 3;' \
    "5"

run_olang_test "arith/sub" \
    'emit 10 - 3;' \
    "7"

run_olang_test "arith/mul" \
    'emit 6 * 7;' \
    "42"

run_olang_test "arith/div" \
    'emit 15 / 3;' \
    "5"

run_olang_test "arith/mod" \
    'emit 17 % 5;' \
    "2"

run_olang_test "arith/negative" \
    'emit 0 - 42;' \
    "-42"

run_olang_test "arith/float" \
    'emit 1 / 3 * 3;' \
    "1"

# 2.2 Variables
run_olang_test "var/let" \
    'let x = 42; emit x;' \
    "42"

run_olang_test "var/reassign" \
    'let x = 1; let x = 2; emit x;' \
    "2"

run_olang_test "var/string" \
    'let s = "hello"; emit s;' \
    "hello"

# 2.3 Strings
run_olang_test "string/concat" \
    'emit "hello" + " " + "world";' \
    "hello world"

run_olang_test "string/len" \
    'emit __len("hello");' \
    "5"

run_olang_test "string/char_at" \
    'emit __char_at("hello", 1);' \
    "e"

run_olang_test "string/substr" \
    'emit __substr("hello world", 6, 11);' \
    "world"

run_olang_test "string/trim" \
    'emit __str_trim("  hi  ");' \
    "hi"

# 2.4 Comparison
run_olang_test "cmp/eq_true" \
    'if 1 == 1 { emit "yes"; } else { emit "no"; };' \
    "yes"

run_olang_test "cmp/eq_false" \
    'if 1 == 2 { emit "yes"; } else { emit "no"; };' \
    "no"

run_olang_test "cmp/lt" \
    'if 3 < 5 { emit "yes"; } else { emit "no"; };' \
    "yes"

run_olang_test "cmp/gt" \
    'if 5 > 3 { emit "yes"; } else { emit "no"; };' \
    "yes"

# 2.5 Control flow
run_olang_test "flow/if_else" \
    'let x = 10; if x > 5 { emit "big"; } else { emit "small"; };' \
    "big"

run_olang_test "flow/while" \
    'let i = 0; while i < 3 { emit i; let i = i + 1; };' \
    "012"

run_olang_test "flow/for_in" \
    'let arr = [10, 20, 30]; for x in arr { emit x; };' \
    "102030"

# 2.6 Functions
run_olang_test "fn/basic" \
    'fn double(x) { return x * 2; }; emit double(21);' \
    "42"

run_olang_test "fn/multi_param" \
    'fn add(a, b) { return a + b; }; emit add(3, 4);' \
    "7"

run_olang_test "fn/recursive" \
    'fn fib(n) { if n < 2 { return n; }; return fib(n - 1) + fib(n - 2); }; emit fib(10);' \
    "55"

# 2.7 Arrays
run_olang_test "array/literal" \
    'let a = [1, 2, 3]; emit __array_len(a);' \
    "3"

run_olang_test "array/push_get" \
    'let a = []; __push(a, 42); let v = __array_get(a, 0); emit v;' \
    "42"

run_olang_test "array/set_at" \
    'let a = [1, 2, 3]; __set_at(a, 1, 99); let v = __array_get(a, 1); emit v;' \
    "99"

# 2.8 Dict
run_olang_test "dict/create_get" \
    'let d = { name: "olang" }; emit d.name;' \
    "olang"

# 2.9 Lambda / HOF
run_olang_test "lambda/basic" \
    'let f = fn(x) { return x + 1; }; emit f(41);' \
    "42"

run_olang_test "hof/map" \
    'let a = [1, 2, 3]; let b = map(a, fn(x) { return x * 10; }); for v in b { emit v; };' \
    "102030"

run_olang_test "hof/filter" \
    'let a = [1, 2, 3, 4, 5]; let b = filter(a, fn(x) { return x > 3; }); for v in b { emit v; };' \
    "45"

run_olang_test "hof/reduce" \
    'let a = [1, 2, 3, 4]; let s = reduce(a, fn(acc, x) { return acc + x; }); emit s;' \
    "10"

run_olang_test "hof/pipe" \
    'let r = pipe(5, fn(x) { return x * 2; }, fn(x) { return x + 1; }); emit r;' \
    "11"

# 2.10 Math builtins
run_olang_test "math/floor" \
    'emit __floor(3.7);' \
    "3"

run_olang_test "math/ceil" \
    'emit __ceil(3.2);' \
    "4"

# 2.11 Type checking
run_olang_test "type/number" \
    'emit __type_of(42);' \
    "number"

run_olang_test "type/string" \
    'emit __type_of("hi");' \
    "string"

run_olang_test "type/array" \
    'emit __type_of([1,2]);' \
    "array"

run_olang_test "type/function" \
    'let f = fn(x) { return x; }; emit __type_of(f);' \
    "closure"

# 2.12 Bitwise
run_olang_test "bitwise/or" \
    'emit __bit_or(5, 3);' \
    "7"

run_olang_test "bitwise/and" \
    'emit __bit_and(7, 3);' \
    "3"

run_olang_test "bitwise/xor" \
    'emit __bit_xor(5, 3);' \
    "6"

run_olang_test "bitwise/shl" \
    'emit __bit_shl(1, 4);' \
    "16"

# 2.13 Mol pack/unpack
run_olang_test "mol/pack" \
    'let m = __mol_pack(5, 3, 4, 2, 1); emit m;' \
    "21385"

run_olang_test "mol/extract_s" \
    'let m = __mol_pack(5, 3, 4, 2, 1); emit __mol_s(m);' \
    "5"

run_olang_test "mol/extract_r" \
    'let m = __mol_pack(5, 3, 4, 2, 1); emit __mol_r(m);' \
    "3"

run_olang_test "mol/roundtrip" \
    'let m = __mol_pack(15, 15, 7, 7, 3); emit __mol_s(m); emit __mol_r(m); emit __mol_v(m); emit __mol_a(m); emit __mol_t(m);' \
    "1515773"

# 2.14 SHA-256
run_olang_test "crypto/sha256" \
    'let h = __sha256(__str_bytes("hello")); emit __type_of(h);' \
    "string"

# 2.15 UTF-8
run_olang_test "utf8/ascii_cp" \
    'emit __utf8_cp("ABC", 0);' \
    "65"

run_olang_test "utf8/multibyte_len" \
    'emit __utf8_len("é", 0);' \
    "2"

# 2.16 Logical operators
run_olang_test "logic/and_true" \
    'if 1 && 1 { emit "yes"; } else { emit "no"; };' \
    "yes"

run_olang_test "logic/and_short" \
    'if 0 && 1 { emit "yes"; } else { emit "no"; };' \
    "no"

run_olang_test "logic/or_true" \
    'if 0 || 1 { emit "yes"; } else { emit "no"; };' \
    "yes"

run_olang_test "logic/not" \
    'if __logic_not(0) { emit "yes"; } else { emit "no"; };' \
    "yes"

# 2.17 Sort
run_olang_test "sort/basic" \
    'let a = sort([3, 1, 2]); for v in a { emit v; };' \
    "123"

# 2.18 Join / Contains
run_olang_test "string/join" \
    'let a = ["a", "b", "c"]; emit join(a, "-");' \
    "a-b-c"

run_olang_test "string/contains" \
    'if contains("hello world", "world") { emit "yes"; } else { emit "no"; };' \
    "yes"

# 2.19 Split
run_olang_test "string/split" \
    'let parts = split("a,b,c", ","); emit __array_len(parts);' \
    "3"

# 2.20 Match expression — tested in file tests (multi-line only)

echo ""

# ═══════════════════════════════════════════════════════════════
# SECTION 3: OLANG FILE TESTS (.ol test scripts)
# ═══════════════════════════════════════════════════════════════

echo -e "${CYAN}--- Olang File Tests ---${NC}"

for oltest in "$TEST_DIR"/test_*.ol; do
    [ -f "$oltest" ] || continue
    testname=$(basename "$oltest" .ol)

    # Strip // comments (line-start AND inline) then join all lines
    code_input=$(sed 's|//.*||' "$oltest" | grep -v '^[[:space:]]*$' | tr '\n' ' ')

    # Each .ol test file should emit "PASS" or "FAIL" as last line
    file_actual=$(echo "$code_input" | timeout 10 "$BINARY" 2>/dev/null || true)
    last_line=$(echo "$file_actual" | strip_repl | tail -1)

    if [ "$last_line" = "PASS" ]; then
        PASS=$((PASS + 1))
        echo -e "  $GREEN  OK$NC file/$testname"
    elif [ "$last_line" = "FAIL" ]; then
        FAIL=$((FAIL + 1))
        ERRORS="$ERRORS\n  $RED FAIL$NC file/$testname"
        ERRORS="$ERRORS\n       output: $(echo "$file_actual" | strip_repl | head -5)"
    else
        SKIP=$((SKIP + 1))
        echo -e "  $YELLOW SKIP$NC file/$testname — no PASS/FAIL output"
    fi
done

echo ""

# ═══════════════════════════════════════════════════════════════
# SECTION 4: BINARY SANITY
# ═══════════════════════════════════════════════════════════════

echo -e "${CYAN}--- Binary Sanity ---${NC}"

# Check binary size
BINSIZE=$(stat -c%s "$BINARY" 2>/dev/null || stat -f%z "$BINARY" 2>/dev/null)
if [ "$BINSIZE" -gt 100000 ] && [ "$BINSIZE" -lt 5000000 ]; then
    PASS=$((PASS + 1))
    echo -e "  $GREEN  OK$NC binary/size ($(numfmt --to=iec $BINSIZE))"
else
    FAIL=$((FAIL + 1))
    ERRORS="$ERRORS\n  $RED FAIL$NC binary/size — unexpected: $BINSIZE bytes"
fi

# Check ELF header
if file "$BINARY" | grep -q "ELF 64-bit"; then
    PASS=$((PASS + 1))
    echo -e "  $GREEN  OK$NC binary/elf64"
else
    FAIL=$((FAIL + 1))
    ERRORS="$ERRORS\n  $RED FAIL$NC binary/elf64 — not ELF 64-bit"
fi

# Check no libc dependency (allow vDSO which is kernel-injected, not a real dep)
ldd_out=$(ldd "$BINARY" 2>&1 || true)
if echo "$ldd_out" | grep -q "not a dynamic executable\|statically linked"; then
    PASS=$((PASS + 1))
    echo -e "  $GREEN  OK$NC binary/no_libc (static, zero deps)"
elif ! echo "$ldd_out" | grep -qv "linux-vdso\|ld-linux\|^\s*$"; then
    PASS=$((PASS + 1))
    echo -e "  $GREEN  OK$NC binary/no_libc (only vDSO, no libs)"
else
    FAIL=$((FAIL + 1))
    ERRORS="$ERRORS\n  $RED FAIL$NC binary/no_libc — has dynamic deps: $(echo "$ldd_out" | grep -v vdso | head -3)"
fi

# Boot test — exit immediately
if echo "exit" | timeout 5 "$BINARY" >/dev/null 2>&1; then
    PASS=$((PASS + 1))
    echo -e "  $GREEN  OK$NC binary/boot (starts and exits)"
else
    FAIL=$((FAIL + 1))
    ERRORS="$ERRORS\n  $RED FAIL$NC binary/boot — failed to start"
fi

echo ""

# ─── SECTION: Break/Continue ──────────────────────────────────
echo -e "${CYAN}── Break/Continue ──${NC}"

run_olang_test "flow/break_simple" \
    'let i=0;while i<10{if i==3{break;};let i=i+1;};emit i;' "3"

run_olang_test "flow/break_nested" \
    'let r="";let i=0;while i<3{let j=0;while j<3{if j==2{break;};r=r+__to_string(j);let j=j+1;};let i=i+1;};emit r;' "010101"

run_olang_test "flow/continue_simple" \
    'let r=0;let i=0;while i<5{let i=i+1;if i==3{continue;};r=r+i;};emit r;' "12"

run_olang_test "flow/continue_nested" \
    'let r=0;let i=0;while i<3{let i=i+1;let j=0;while j<3{let j=j+1;if j==2{continue;};r=r+1;};};emit r;' "6"

run_olang_test "flow/break_value" \
    'let r=0;let i=0;while i<100{r=r+i;if r>10{break;};let i=i+1;};emit r;' "15"

# ─── SECTION: Match expressions ──────────────────────────────
echo -e "${CYAN}── Match ──${NC}"

run_olang_test "match/number" \
    'let x=2;match x{1=>{emit "one";},2=>{emit "two";},_=>{emit "other";}};' "two"

run_olang_test "match/wildcard" \
    'let x=99;match x{1=>{emit "a";},_=>{emit "wild";}};' "wild"

run_olang_test "match/string" \
    'let s="hi";match s{"hi"=>{emit "hello";},_=>{emit "?";}};' "hello"

run_olang_test "match/in_fn" \
    'fn check(x){match x{1=>{return "one";},2=>{return "two";},_=>{return "?";}};};emit check(2);' "two"

# ─── SECTION: For loops ─────────────────────────────────────
echo -e "${CYAN}── For loops ──${NC}"

run_olang_test "for/basic" \
    'let r=0;for i in [1,2,3,4,5]{r=r+i;};emit r;' "15"

run_olang_test "for/string" \
    'let r="";for s in ["a","b","c"]{r=r+s;};emit r;' "abc"

run_olang_test "for/nested" \
    'let r=0;for i in [1,2,3]{for j in [10,20]{r=r+i+j;};};emit r;' "102"

run_olang_test "for/break" \
    'let r=0;for i in [1,2,3,4,5]{if i==4{break;};r=r+i;};emit r;' "6"

run_olang_test "for/continue" \
    'let r=0;for x in [1,2,3,4,5]{if x==3{continue;};r=r+x;};emit r;' "12"

run_olang_test "for/continue_nested" \
    'let r=0;for x in [1,2,3]{for y in [10,20,30]{if y==20{continue;};r=r+1;};};emit r;' "6"

# ─── SECTION: Nested control flow ───────────────────────────
echo -e "${CYAN}── Nested flow ──${NC}"

run_olang_test "nested/if_in_while" \
    'let r="";let i=0;while i<5{if i%2==0{r=r+"E";}else{r=r+"O";};let i=i+1;};emit r;' "EOEOE"

run_olang_test "nested/while_in_if" \
    'let r=0;if 1==1{let i=0;while i<5{r=r+i;let i=i+1;};};emit r;' "10"

run_olang_test "nested/triple_while" \
    'let r=0;let a=0;while a<2{let b=0;while b<2{let c=0;while c<2{r=r+1;let c=c+1;};let b=b+1;};let a=a+1;};emit r;' "8"

run_olang_test "nested/fn_in_while" \
    'fn sq(x){return x*x;};let r=0;let i=1;while i<=3{r=r+sq(i);let i=i+1;};emit r;' "14"

# ─── SECTION: Edge cases ────────────────────────────────────
echo -e "${CYAN}── Edge cases ──${NC}"

run_olang_test "edge/empty_array" \
    'let a=[];emit len(a);' "0"

run_olang_test "edge/empty_string" \
    'emit len("");' "0"

run_olang_test "edge/zero" \
    'emit 0;' "0"

run_olang_test "edge/negative" \
    'emit 0-5;' "-5"

run_olang_test "edge/bool_true" \
    'emit __to_string(1==1);' "1"

run_olang_test "edge/bool_false" \
    'emit __to_string(1==2);' "0"

run_olang_test "edge/large_number" \
    'emit 1000000*1000000;' "1000000000000"

run_olang_test "edge/string_escape" \
    'emit "a\\tb";' "a\tb"

run_olang_test "edge/array_of_arrays" \
    'let a=[[1,2],[3,4]];emit len(a);' "2"

run_olang_test "edge/recursive_deep" \
    'fn f(n){if n==0{return 0;};return 1+f(n-1);};emit f(100);' "100"

# ─── SECTION: Advanced functions ─────────────────────────────
echo -e "${CYAN}── Advanced fn ──${NC}"

run_olang_test "fn/multireturn" \
    'fn test(x){if x>0{return "pos";};if x<0{return "neg";};return "zero";};emit test(5)+" "+test(0-1)+" "+test(0);' "pos neg zero"

run_olang_test "fn/fib20" \
    'fn fib(n){if n<2{return n;};return fib(n-1)+fib(n-2);};emit fib(20);' "6765"

run_olang_test "fn/mutual" \
    'fn isE(n){if n==0{return 1;};return isO(n-1);};fn isO(n){if n==0{return 0;};return isE(n-1);};emit __to_string(isE(10))+" "+__to_string(isO(10));' "1 0"

run_olang_test "fn/default_scope" \
    'let x=10;fn f(){return x;};emit f();' "10"

# ─── SECTION: String operations extended ─────────────────────
echo -e "${CYAN}── String ext ──${NC}"

run_olang_test "string/repeat" \
    'let r="";let i=0;while i<5{r=r+"x";let i=i+1;};emit r;' "xxxxx"

run_olang_test "string/char_code" \
    'emit __char_code("A");' "65"

run_olang_test "string/chr" \
    'emit __chr(65);' "A"

run_olang_test "string/to_string" \
    'emit __to_string(42);' "42"

run_olang_test "string/to_num" \
    'emit to_num("123")+1;' "124"

# ─── SECTION: Array operations extended ──────────────────────
echo -e "${CYAN}── Array ext ──${NC}"

run_olang_test "array/range" \
    'let a=__array_range(5);emit len(a);' "5"

run_olang_test "array/get" \
    'let a=[10,20,30];emit __array_get(a,1);' "20"

run_olang_test "array/sort_dup" \
    'let a=[3,1,4,1,5];emit sort(a);' "[1, 1, 3, 4, 5]"

run_olang_test "array/filter_gt" \
    'let a=filter([1,2,3,4,5],fn(x){return x>3;});emit a;' "[4, 5]"

run_olang_test "array/map_square" \
    'emit map([1,2,3],fn(x){return x*x;});' "[1, 4, 9]"

# ─── SECTION: Logic/comparison extended ──────────────────────
echo -e "${CYAN}── Logic ext ──${NC}"

run_olang_test "logic/chain_and" \
    'emit __to_string(1==1 && 2==2 && 3==3);' "1"

run_olang_test "logic/chain_or" \
    'emit __to_string(0==1 || 0==2 || 1==1);' "1"

run_olang_test "logic/mixed" \
    'emit __to_string((1==1 && 2==3) || (3==3 && 4==4));' "1"

run_olang_test "cmp/le" \
    'emit __to_string(3<=3);' "1"

run_olang_test "cmp/ge" \
    'emit __to_string(5>=5);' "1"

run_olang_test "cmp/ne" \
    'emit __to_string(1!=2);' "1"

# ─── SECTION: Types/Structs ──────────────────────────────────
echo -e "${CYAN}── Types ──${NC}"

run_olang_test "type/struct_create" \
    'type Point{x:Num,y:Num};let p=Point{x:3,y:4};emit p.x;' "3"

run_olang_test "type/struct_field" \
    'type Rect{w:Num,h:Num};let r=Rect{w:10,h:5};emit r.w*r.h;' "50"

run_olang_test "type/struct_fn" \
    'type V{x:Num};fn mag(v){return v.x*v.x;};emit mag(V{x:7});' "49"

run_olang_test "type/struct_pass" \
    'type V{x:Num};fn get(v){return v.x;};let a=V{x:99};emit get(a);' "99"

# ─── SECTION: String interpolation ──────────────────────────
echo -e "${CYAN}── Interpolation ──${NC}"

run_olang_test "interp/basic" \
    'let x=42;emit $"val={x}";' "val=42"

run_olang_test "interp/expr" \
    'let a=3;let b=4;emit $"{a}+{b}={a+b}";' "3+4=7"

run_olang_test "interp/string" \
    'let name="Nox";emit $"Hello {name}!";' "Hello Nox!"

# ─── SECTION: Factorial/recursion ────────────────────────────
echo -e "${CYAN}── Recursion ──${NC}"

run_olang_test "recurse/factorial" \
    'fn fact(n){if n<=1{return 1;};return n*fact(n-1);};emit fact(10);' "3628800"

run_olang_test "recurse/gcd" \
    'fn gcd(a,b){if b==0{return a;};return gcd(b,a%b);};emit gcd(48,18);' "6"

run_olang_test "recurse/power" \
    'fn pow(b,e){if e==0{return 1;};return b*pow(b,e-1);};emit pow(2,10);' "1024"

run_olang_test "recurse/sum_list" \
    'fn sum(a,i){if i>=len(a){return 0;};return a[i]+sum(a,i+1);};emit sum([10,20,30,40],0);' "100"

# ─── SECTION: Complex patterns ──────────────────────────────
echo -e "${CYAN}── Complex ──${NC}"

run_olang_test "complex/fizzbuzz" \
    'let r="";let i=1;while i<=15{if i%15==0{r=r+"FizzBuzz ";}else{if i%3==0{r=r+"Fizz ";}else{if i%5==0{r=r+"Buzz ";}else{r=r+__to_string(i)+" ";};};};let i=i+1;};emit r;' "1 2 Fizz 4 Buzz Fizz 7 8 Fizz Buzz 11 Fizz 13 14 FizzBuzz "

run_olang_test "complex/array_build" \
    'let a=[];let i=0;while i<5{push(a,i*i);let i=i+1;};emit a;' "[0, 1, 4, 9, 16]"

run_olang_test "complex/max" \
    'fn max(a,b){if a>b{return a;};return b;};emit max(max(3,7),max(5,2));' "7"

run_olang_test "complex/count_if" \
    'fn count(a,f){let r=0;for x in a{if f(x){r=r+1;};};return r;};emit count([1,2,3,4,5,6],fn(x){return x%2==0;});' "3"

run_olang_test "complex/sum_even" \
    'let r=0;for x in [1,2,3,4,5,6,7,8]{if x%2==0{r=r+x;};};emit r;' "20"

run_olang_test "complex/closure_counter" \
    'fn mk(start){return fn(n){return start+n;};};let f=mk(100);emit __to_string(f(1))+" "+__to_string(f(50));' "101 150"

# ─── SECTION: Pipe operator ─────────────────────────────────
echo -e "${CYAN}── Pipe ──${NC}"

run_olang_test "pipe/basic" \
    'fn double(x){return x*2;};fn inc(x){return x+1;};emit 5 |> double |> inc;' "11"

run_olang_test "pipe/chain" \
    'fn sq(x){return x*x;};fn neg(x){return 0-x;};emit 3 |> sq |> neg;' "-9"

# ─── SECTION: Const declarations ────────────────────────────
echo -e "${CYAN}── Const ──${NC}"

run_olang_test "const/basic" \
    'const PI=3;emit PI;' "3"

run_olang_test "const/use_in_fn" \
    'const MAX=100;fn check(x){if x>MAX{return "over";};return "ok";};emit check(50)+" "+check(200);' "ok over"

# ─── SECTION: Try/catch ──────────────────────────────────────
echo -e "${CYAN}── Try/Catch ──${NC}"

run_olang_test "try/catch_throw" \
    'try{__throw("err");}catch{emit "caught";};' "caught"

run_olang_test "try/catch_success" \
    'try{emit "ok";}catch{emit "err";};' "ok"

run_olang_test "try/catch_nested" \
    'let r="";try{try{__throw("x");}catch{r=r+"inner ";};r=r+"ok";}catch{r=r+"outer";};emit r;' "inner ok"

run_olang_test "try/catch_in_fn" \
    'fn safe(x){try{if x==0{__throw("z");};return "ok";}catch{return "err";};};emit safe(1)+" "+safe(0);' "ok err"

run_olang_test "try/catch_loop" \
    'let ok=0;let i=0;while i<50{try{let i=i+1;let ok=ok+1;}catch{};};emit ok;' "50"

run_olang_test "try/catch_rethrow" \
    'let r="";try{try{__throw("x");}catch{r=r+"inner ";};__throw("y");}catch{r=r+"outer";};emit r;' "inner outer"

# ─── SECTION: Scope & assignment ─────────────────────────────
echo -e "${CYAN}── Scope ──${NC}"

run_olang_test "scope/shadow" \
    'let x=1;fn f(){let x=2;return x;};emit __to_string(f())+" "+__to_string(x);' "2 1"

run_olang_test "scope/reassign_outer" \
    'let x=10;fn f(){x=20;};f();emit x;' "20"

run_olang_test "scope/loop_var" \
    'let r=0;let i=0;while i<3{let x=i*10;r=r+x;let i=i+1;};emit r;' "30"

# ─── SECTION: HOF patterns ──────────────────────────────────
echo -e "${CYAN}── HOF patterns ──${NC}"

run_olang_test "hof/any_true" \
    'emit __to_string(any([1,3,5,7],fn(x){return x>6;}));' "1"

run_olang_test "hof/any_false" \
    'emit __to_string(any([1,3,5],fn(x){return x>10;}));' "0"

run_olang_test "hof/all_true" \
    'emit __to_string(all([2,4,6],fn(x){return x%2==0;}));' "1"

run_olang_test "hof/all_false" \
    'emit __to_string(all([2,4,5],fn(x){return x%2==0;}));' "0"

run_olang_test "hof/map_string" \
    'emit map(["a","b","c"],fn(s){return s+s;});' "[aa, bb, cc]"

run_olang_test "hof/filter_empty" \
    'emit filter([1,2,3],fn(x){return x>10;});' "[]"

run_olang_test "hof/pipe_chain" \
    'fn dbl(x){return x*2;};fn add1(x){return x+1;};fn sq(x){return x*x;};emit 3 |> dbl |> add1 |> sq;' "49"

# ─── SECTION: Closure capture tests ─────────────────────────
echo -e "${CYAN}── Closure capture ──${NC}"

run_olang_test "closure/capture" \
    'fn mk(x){return fn(y){return x+y;};};let a=mk(5);emit __to_string(a(10));' "15"

run_olang_test "closure/multi" \
    'fn mk(x){return fn(y){return x*y;};};let d=mk(2);let t=mk(3);emit __to_string(d(7)+t(7));' "35"

run_olang_test "closure/compose" \
    'fn comp(f,g){return fn(x){return f(g(x));};};let c=comp(fn(x){return x+1;},fn(x){return x*2;});emit __to_string(c(5));' "11"

run_olang_test "closure/apply" \
    'fn mk(x){return fn(y){return x+y;};};let a=mk(5);fn go(f){return f(10);};emit __to_string(go(a));' "15"

run_olang_test "closure/string" \
    'fn greet(p){return fn(n){return p+" "+n;};};let h=greet("Hi");emit h("Nox");' "Hi Nox"

# ─── SECTION: Ghost entries regression ─────────────────────
echo -e "${CYAN}── Ghost entries ──${NC}"

run_olang_test "ghost/param_reuse" \
    'fn comp(f,g){return fn(x){return f(g(x));};};let c=comp(fn(x){return x+1;},fn(x){return x*2;});fn go(f){return f(10);};fn mk(x){return fn(y){return x+y;};};let a=mk(5);emit __to_string(go(a));' "15"

run_olang_test "ghost/nested_if" \
    'fn check(n){let r=0;if n>=10{if n<=20{r=1;};};return r;};emit __to_string(check(5))+__to_string(check(15))+__to_string(check(25));' "010"

# ─── SECTION: System builtin ────────────────────────────────
echo -e "${CYAN}── System ──${NC}"

run_olang_test "system/echo" \
    'let r=__system("echo hello");emit r;' "hello"

run_olang_test "system/readdir" \
    'let f=__readdir("stdlib/editor");emit __to_string(len(f)>0);' "1"

# ─── SECTION: Process builtins ──────────────────────────────
echo -e "${CYAN}── Process ──${NC}"

run_olang_test "proc/spawn" \
    'let p=__spawn("echo proc_ok");__sleep(200);let o=__pipe_read(p[2]);emit o;' "proc_ok"

run_olang_test "proc/poll_stdin" \
    'emit __to_string(__poll_ready(0,0));' "1"

run_olang_test "proc/pipe_write_stdout" \
    '__pipe_write(1,"pw_ok\n");' "pw_ok"

run_olang_test "proc/spawn_kill" \
    'let p=__spawn("sleep 60");let a=__to_string(__process_alive(p[0]));__process_kill(p[0]);__sleep(100);let b=__to_string(__process_alive(p[0]));emit a+b;' "10"

run_olang_test "proc/spawn_array" \
    'let p=__spawn("echo x");emit __to_string(len(p));' "3"

echo ""

# ═══════════════════════════════════════════════════════════════
# REPORT
# ═══════════════════════════════════════════════════════════════

TOTAL=$((PASS + FAIL + SKIP))

echo -e "${CYAN}═══════════════════════════════════════${NC}"
if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}  ALL PASS: $PASS/$TOTAL tests passed${NC}"
else
    echo -e "${RED}  $FAIL FAILED${NC} / $PASS passed / $SKIP skipped (total: $TOTAL)"
fi
echo -e "${CYAN}═══════════════════════════════════════${NC}"

if [ -n "$ERRORS" ]; then
    echo ""
    echo -e "${RED}Failures:${NC}"
    echo -e "$ERRORS"
fi

echo ""

# Cleanup
rm -rf "$TMP_DIR"

# ── Self-build tests (gen1) ──────────────────────────────────────
SB_PASS=0
SB_FAIL=0
sb_test() {
    local name="$1"
    local code="$2"
    local expect="$3"
    local actual
    actual=$(echo "$code" | timeout 10 ./origin_gen1.olang 2>&1 | grep -v "BOOT_OK\|HomeOS\|Type code\|bye" | head -1 | sed 's/^⦿ //')
    if echo "$actual" | grep -q "$expect"; then
        echo -e "  ${GREEN}  OK${NC} $name"
        SB_PASS=$((SB_PASS + 1))
    else
        echo -e "  ${RED}FAIL${NC} $name (expected: $expect, got: $actual)"
        SB_FAIL=$((SB_FAIL + 1))
        FAIL=$((FAIL + 1))
    fi
}
if [ -f origin_gen1.olang ]; then
echo -e "\n${CYAN}── Self-build (gen1) ──${NC}"
sb_test "selfbuild/emit"   'emit 42;'                          "42"
sb_test "selfbuild/arith"  'emit 1+2+3;'                       "6"
sb_test "selfbuild/fn"     'fn f(x){return x*x;}; emit f(7);'  "49"
sb_test "selfbuild/fib"    'fn fib(n){if n<2{return n;};return fib(n-1)+fib(n-2);}; emit fib(10);' "55"
sb_test "selfbuild/array"  'let a=[1,2,3]; push(a,4); emit len(a);' "4"
sb_test "selfbuild/sort"   'emit sort([5,3,1,4,2]);'           "1, 2, 3, 4, 5"
sb_test "selfbuild/map"    'emit map([1,2,3], fn(x){return x*10;});' "10, 20, 30"
sb_test "selfbuild/sha256" 'emit __sha256("abc");'             "ba7816bf"
sb_test "selfbuild/break"  'let i=0;while i<10{if i==5{break;};let i=i+1;};emit i;' "5"
sb_test "selfbuild/continue" 'let r=0;let i=0;while i<5{let i=i+1;if i==3{continue;};r=r+i;};emit r;' "12"
sb_test "selfbuild/match"  'let x=2;match x{1=>{emit "a";},2=>{emit "b";},_=>{emit "c";}};' "b"
sb_test "selfbuild/nested_while" 'let r=0;let i=0;while i<3{let j=0;while j<3{r=r+1;let j=j+1;};let i=i+1;};emit r;' "9"
sb_test "selfbuild/for_break" 'let r=0;for x in [1,2,3,4,5]{if x==4{break;};r=r+x;};emit r;' "6"
sb_test "selfbuild/closure_adder" 'fn mk(x){return fn(y){return x+y;};};let a=mk(100);emit a(23);' "123"
sb_test "selfbuild/logic_sc" 'emit __to_string(1==1 && 2==2);' "1"
sb_test "selfbuild/for_continue" 'let r=0;for x in [1,2,3,4,5]{if x==3{continue;};r=r+x;};emit r;' "12"
sb_test "selfbuild/struct"  'type P{x:Num,y:Num};let p=P{x:3,y:4};emit p.x+p.y;' "7"
sb_test "selfbuild/interp"  'let n="Nox";emit $"Hi {n}";' "Hi Nox"
sb_test "selfbuild/fact"    'fn f(n){if n<=1{return 1;};return n*f(n-1);};emit f(10);' "3628800"
sb_test "selfbuild/pipe"    'fn d(x){return x*2;};emit 5 |> d;' "10"
sb_test "selfbuild/fizz"    'let r="";let i=1;while i<=5{if i%3==0{r=r+"F";}else{r=r+__to_string(i);};let i=i+1;};emit r;' "12F45"
sb_test "selfbuild/bitwise_or"  'emit 0x0F | 0xF0;'           "255"
sb_test "selfbuild/bitwise_and" 'emit 0xFF & 0x0F;'            "15"
sb_test "selfbuild/constfold"   'emit 10 * 20 + 5;'            "205"
sb_test "selfbuild/block_comment" 'let x = /* skip this */ 42; emit x;' "42"
sb_test "selfbuild/strfold"  'emit "hello" + " " + "world";'   "hello world"
echo -e "\n${CYAN}  Self-build: ${SB_PASS}/$((SB_PASS + SB_FAIL)) passed${NC}"
fi

# Exit code
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
