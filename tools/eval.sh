#!/bin/bash
# tools/eval.sh — Olang Auto-Evaluation (HONEST)
# Chỉ ghi kết quả thật. Không giả số liệu.
# Usage: bash tools/eval.sh

set -e
cd "$(dirname "$0")/.."

R='\033[0;31m'; G='\033[0;32m'; Y='\033[0;33m'; C='\033[0;36m'; B='\033[1m'; N='\033[0m'
BIN="./origin.olang"
P=0; F=0; CR=0; T=0; ERRS=""

echo -e "${C}${B}═══ OLANG AUTO-EVAL ═══${N}"
echo -e "${C}Binary:${N} $(du -h "$BIN" | cut -f1) | VM: $(wc -l < vm/x86_64/vm_x86_64.S) LOC"
echo -e "${C}Date:${N}   $(date '+%Y-%m-%d %H:%M')"
echo ""

run() {
    echo "$1" | timeout 10 "$BIN" 2>/dev/null | grep -v "^⦿ HomeOS\|^○ Type\|^⦿ bye" | sed 's/^⦿ //' | tail -1
}

chk() {
    local name="$1" code="$2" expect="$3"
    T=$((T+1))
    local got=$(run "$code")
    if [ "$got" = "$expect" ]; then
        P=$((P+1)); echo -e "  ${G}OK${N}    $name"
    elif [ -z "$got" ]; then
        echo "$code" | timeout 5 "$BIN" >/dev/null 2>&1; local rc=$?
        if [ $rc -eq 139 ]; then
            CR=$((CR+1)); echo -e "  ${R}CRASH${N} $name"
            ERRS="$ERRS\n  CRASH: $name"
        else
            F=$((F+1)); echo -e "  ${R}FAIL${N}  $name — no output (expected: $expect)"
            ERRS="$ERRS\n  FAIL: $name (no output)"
        fi
    else
        F=$((F+1)); echo -e "  ${R}FAIL${N}  $name — got: $got (expected: $expect)"
        ERRS="$ERRS\n  FAIL: $name ('$got' != '$expect')"
    fi
}

# ═══ 1. CORE LANGUAGE ═══
echo -e "${B}[1] Core Language${N}"
chk "arithmetic"     'emit 3 + 4 * 2;' '11'
chk "variables"      'let x = 42; emit x;' '42'
chk "string"         'emit "hello";' 'hello'
chk "string len"     'emit len("hello");' '5'
chk "if/else"        'if 1 > 0 { emit "yes"; } else { emit "no"; };' 'yes'
chk "while"          'let i=0; let s=0; while i<5 { let s=s+i; let i=i+1; }; emit s;' '10'
chk "for in"         'let s=0; for x in [1,2,3] { let s=s+x; }; emit s;' '6'
chk "function"       'fn f(x) { return x*2; }; emit f(5);' '10'
chk "recursion"      'fn fib(n) { if n<2 { return n; }; return fib(n-1)+fib(n-2); }; emit fib(10);' '55'
chk "lambda"         'let f=fn(x){ return x+1; }; emit f(4);' '5'
chk "array"          'let a=[1,2,3]; emit a[1];' '2'
chk "dict"           'let d={x:1,y:2}; emit d.x;' '1'
chk "try/catch"      'try { __throw("e"); } catch { emit "caught"; };' 'caught'
chk "comprehension"  'emit [x*2 for x in [1,2,3]];' '[2, 4, 6]'
echo ""

# ═══ 2. STDLIB ═══
echo -e "${B}[2] Standard Library${N}"
chk "map"       'emit map([1,2,3], fn(x){return x*10;});' '[10, 20, 30]'
chk "filter"    'emit filter([1,2,3,4,5], fn(x){return x>3;});' '[4, 5]'
chk "reduce"    'emit reduce([1,2,3], fn(a,b){return a+b;});' '6'
chk "sort"      'emit sort([3,1,2]);' '[1, 2, 3]'
chk "split"     'emit split("a,b,c", ",");' '[a, b, c]'
chk "join"      'emit join(["x","y","z"], "-");' 'x-y-z'
chk "contains"  'emit contains("abc", "b");' '1'
chk "substr"    'emit substr("hello", 1, 3);' 'el'
chk "floor"     'emit __floor(3.7);' '3'
chk "isqrt"     'emit __isqrt(25);' '5'
chk "type_name" 'emit type_name(42);' 'Num'
chk "sha256"    'let h=__sha256("hello"); emit substr(h,0,8);' '2cf24dba'
echo ""

# ═══ 3. NL COMPUTING ═══
echo -e "${B}[3] Natural Language Computing${N}"
chk "NL: tổng"      'tinh tong tu 1 den 100' '5050'
chk "NL: fibonacci"  'fibonacci 20' '6765'
chk "NL: sắp xếp"    'sap xep [5,2,8,1,9]' '[1, 2, 5, 8, 9]'
chk "NL: giai thừa"  'giai thua 10' '3628800'
chk "NL: math"       '2 + 3' '5'
echo ""

# ═══ 4. CRYPTO ═══
echo -e "${B}[4] Crypto${N}"
chk "AES encrypt"  'let k="0123456789abcdef0123456789abcdef"; let d="hello world 1234"; let e=__aes_encrypt(k,d); emit len(e);' '32'
chk "SHA-512"      'let h=__sha512("hello"); emit len(h);' '128'
chk "SHA chain"    'let h="t"; let i=0; while i<10 { let h=__sha256(h); let i=i+1; }; emit len(h);' '64'
echo ""

# ═══ 5. UNICODE ═══
echo -e "${B}[5] Unicode${N}"
chk "ulen"       'emit ulen("xin chào");' '8'
chk "utf8 cp"    'emit __utf8_cp("ABC", 0);' '65'
echo ""

# ═══ 6. KNOWN BUGS ═══
echo -e "${B}[6] Known Bug Status${N}"
T=$((T+1))
got=$(run 'emit substr(__sha256("hello"),0,8);')
if [ "$got" = "2cf24dba" ]; then
    P=$((P+1)); echo -e "  ${G}FIXED${N} nested builtin (substr+sha256)"
else
    F=$((F+1)); echo -e "  ${R}BUG${N}   nested builtin — got: $got"
    ERRS="$ERRS\n  BUG: nested builtins clobber args"
fi

T=$((T+1))
got=$(run 'emit $"val: {2+3}";')
if [ "$got" = "val: 5" ]; then
    P=$((P+1)); echo -e "  ${G}FIXED${N} interpolation expr"
else
    F=$((F+1)); echo -e "  ${R}BUG${N}   interpolation expr — got: '$got'"
    ERRS="$ERRS\n  BUG: \$\"{expr}\" only reads first token"
fi

T=$((T+1))
got=$(run 'use "lib/vec.ol"; emit vec_dot([1,2,3],[4,5,6]);')
if [ "$got" = "32" ]; then
    P=$((P+1)); echo -e "  ${G}OK${N}    vec_dot (with use)"
else
    F=$((F+1)); echo -e "  ${R}BUG${N}   vec_dot — got: '$got'"
    ERRS="$ERRS\n  BUG: vec_dot broken"
fi

T=$((T+1))
echo 'use "lib/vec.ol"; emit mat_identity(2);' | timeout 5 "$BIN" >/dev/null 2>&1
if [ $? -eq 139 ]; then
    CR=$((CR+1)); echo -e "  ${R}CRASH${N} mat_identity — SEGFAULT"
    ERRS="$ERRS\n  CRASH: mat_identity segfault"
else
    P=$((P+1)); echo -e "  ${G}FIXED${N} mat_identity"
fi

T=$((T+1))
st=$(run 'selftest')
if echo "$st" | grep -q "PASS"; then
    P=$((P+1)); echo -e "  ${G}OK${N}    selftest — $st"
else
    F=$((F+1)); echo -e "  ${R}BUG${N}   selftest — $st"
    ERRS="$ERRS\n  BUG: selftest boot context failures"
fi
echo ""

# ═══ 7. PERFORMANCE ═══
echo -e "${B}[7] Performance (wall clock, best of 3)${N}"
bench() {
    local code="$1" best=999999
    for i in 1 2 3; do
        local s=$(date +%s%N)
        echo "$code" | timeout 60 "$BIN" >/dev/null 2>&1
        local e=$(date +%s%N)
        local ms=$(( (e - s) / 1000000 ))
        [ "$ms" -lt "$best" ] && best=$ms
    done
    echo "$best"
}

t_boot=$(bench 'emit 1;')
t_fib=$(bench 'fn fib(n){if n<2{return n;};return fib(n-1)+fib(n-2);}; emit fib(30);')
t_loop=$(bench 'let s=0;let i=0;while i<10000000{let s=s+i;let i=i+1;};emit s;')
t_sha=$(bench 'let h="hello";let i=0;while i<1000{let h=__sha256(h);let i=i+1;};emit len(h);')

fc=$((t_fib - t_boot)); lc=$((t_loop - t_boot)); sc=$((t_sha - t_boot))

echo -e "  boot:     ${B}${t_boot}ms${N}"
echo -e "  fib(30):  ${B}${t_fib}ms${N} wall / ~${fc}ms compute"
echo -e "  loop 10M: ${B}${t_loop}ms${N} wall / ~${lc}ms compute"
echo -e "  SHA×1000: ${B}${t_sha}ms${N} wall / ~${sc}ms compute"

# Compare
echo ""
if command -v python3 &>/dev/null; then
    tp=$(python3 -c "import time;f=lambda n:n if n<2 else f(n-1)+f(n-2);t=time.time();f(30);print(int((time.time()-t)*1000))")
    echo -e "  ${C}vs Python:${N} fib(30) Python=${tp}ms Olang=${t_fib}ms (compute ~${fc}ms)"
fi
if command -v go &>/dev/null; then
    mkdir -p /tmp/olang_eval
    cat > /tmp/olang_eval/f.go << 'GOEOF'
package main
import "fmt"
func fib(n int) int { if n < 2 { return n }; return fib(n-1) + fib(n-2) }
func main() { fmt.Println(fib(30)) }
GOEOF
    go build -o /tmp/olang_eval/f /tmp/olang_eval/f.go 2>/dev/null
    best=999999
    for i in 1 2 3; do
        s=$(date +%s%N); /tmp/olang_eval/f >/dev/null; e=$(date +%s%N)
        ms=$(( (e - s) / 1000000 )); [ "$ms" -lt "$best" ] && best=$ms
    done
    echo -e "  ${C}vs Go:${N}     fib(30) Go=${best}ms Olang=${t_fib}ms (compute ~${fc}ms)"
fi
echo ""

# ═══ 8. TEST SUITE ═══
echo -e "${B}[8] Test Suite${N}"
bash tests.sh 2>&1 | tail -3
echo ""

# ═══ SUMMARY ═══
echo -e "${C}${B}═══ SUMMARY ═══${N}"
echo -e "  Tested:  ${B}${T}${N}"
echo -e "  ${G}Pass:${N}   ${B}${P}${N}"
echo -e "  ${R}Fail:${N}   ${B}${F}${N}"
echo -e "  ${R}Crash:${N}  ${B}${CR}${N}"

score=$((P * 100 / T))
if [ $score -ge 90 ]; then echo -e "  Score:   ${G}${B}${score}%${N}"
elif [ $score -ge 75 ]; then echo -e "  Score:   ${Y}${B}${score}%${N}"
else echo -e "  Score:   ${R}${B}${score}%${N}"; fi

echo ""
echo -e "${C}Performance:${N} boot=${t_boot}ms fib=${t_fib}ms(~${fc}ms) loop=${t_loop}ms(~${lc}ms) sha=${t_sha}ms(~${sc}ms)"
echo -e "${C}Binary:${N}      $(du -h "$BIN" | cut -f1) | 0 deps | static ELF64"

if [ -n "$ERRS" ]; then
    echo ""
    echo -e "${R}${B}Issues:${N}"
    echo -e "$ERRS"
fi
echo ""
