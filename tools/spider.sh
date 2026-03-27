#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# SPIDER — Olang Bug Hunter
# Fixed regression tests + random fuzzer + logging
# Usage:
#   bash tools/spider.sh              — run fixed + 20 random tests
#   bash tools/spider.sh --fuzz 100   — run fixed + 100 random tests
#   bash tools/spider.sh --loop 5     — run 5 rounds continuously
#   bash tools/spider.sh --quick      — fixed tests only (no random)
# ═══════════════════════════════════════════════════════════════

BIN="${BIN:-./origin.olang}"
LOGDIR="logs"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/spider.log"
FUZZ_COUNT=20
LOOP_COUNT=1
QUICK=0
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --fuzz) FUZZ_COUNT="$2"; shift 2 ;;
        --loop) LOOP_COUNT="$2"; shift 2 ;;
        --quick) QUICK=1; shift ;;
        *) BIN="$1"; shift ;;
    esac
done

P=0; F=0; C=0; ERRS=""
TOTAL_BUGS=""

run() {
    local desc="$1" code="$2" expected="$3"
    local got
    got=$(echo "$code" | timeout 5 "$BIN" 2>/dev/null | sed -n '3p' | sed 's/⦿ //')
    if [ $? -ne 0 ] && [ -z "$got" ]; then
        C=$((C+1))
        ERRS="$ERRS\n  CRASH $desc"
        TOTAL_BUGS="$TOTAL_BUGS\n[$DATE] CRASH $desc | code: $code"
        return
    fi
    if [ "$got" = "$expected" ]; then
        P=$((P+1))
    else
        F=$((F+1))
        ERRS="$ERRS\n  FAIL $desc: got '$got' want '$expected'"
        TOTAL_BUGS="$TOTAL_BUGS\n[$DATE] FAIL $desc | got '$got' want '$expected' | code: $code"
    fi
}

run_round() {
    local round="$1"
    P=0; F=0; C=0; ERRS=""

    echo -e "\e[36m═══ SPIDER round $round — $(date '+%H:%M:%S') ═══\e[0m"

    # ══════════════════════════════════════
    # FIXED REGRESSION TESTS
    # ══════════════════════════════════════

    # ── Nested builtins (the boss) ──
    run "nest:sha_abc" 'emit __substr(__sha256("abc"),0,8);' "ba7816bf"
    run "nest:sha_test" 'emit __substr(__sha256("test"),0,8);' "9f86d081"
    run "nest:char+sha" 'emit char_at(__sha256("abc"),0);' "b"
    run "nest:tostr" 'emit __substr(__to_string(12345),0,3);' "123"
    run "nest:len+sha" 'emit len(__sha256("x"));' "64"
    run "nest:3level" 'let h=__sha256(__to_string(42)); emit __substr(__sha256(__to_string(42)),0,8)==__substr(h,0,8);' "1"
    run "nest:tostr2" 'emit __to_string(__to_string(99));' "99"
    run "nest:concat" 'emit len("ab"+"cd");' "4"

    # ── Interpolation ──
    run "int:add" 'emit $"{2+3}";' "5"
    run "int:mul" 'emit $"{7*6}";' "42"
    run "int:sub" 'emit $"{100-37}";' "63"
    run "int:var" 'let x=10; emit $"{x*2+1}";' "21"
    run "int:mix" 'let n=5; emit $"v={n*n}";' "v=25"
    run "int:div" 'emit $"{144/12}";' "12"

    # ── Operators ──
    run "op:prec" 'emit 2+3*4;' "14"
    run "op:paren" 'emit (2+3)*4;' "20"
    run "op:neg" 'emit 0-5;' "-5"
    run "op:mod" 'emit 17%5;' "2"
    run "op:cmp" 'emit 3>2;' "1"
    run "op:eq" 'emit 42==42;' "1"

    # ── Functions ──
    run "fn:basic" 'fn f(x){return x*2;}; emit f(21);' "42"
    run "fn:nested" 'fn f(x){return x+1;}; emit f(f(f(0)));' "3"
    run "fn:2arg" 'fn add(a,b){return a+b;}; emit add(add(1,2),add(3,4));' "10"
    run "fn:fib" 'fn fib(n){if n<2{return n;};return fib(n-1)+fib(n-2);}; emit fib(10);' "55"
    run "fn:fact" 'fn fact(n){if n<2{return 1;};return n*fact(n-1);}; emit fact(6);' "720"

    # ── Lambda + HOF ──
    run "lam:basic" 'let f=fn(x){return x*3;}; emit f(7);' "21"
    run "hof:map" 'emit map([1,2,3],fn(x){return x*10;});' "[10, 20, 30]"
    run "hof:filter" 'emit filter([1,2,3,4,5],fn(x){return x>3;});' "[4, 5]"
    run "hof:reduce" 'emit reduce([1,2,3,4],fn(a,b){return a+b;});' "10"
    run "hof:sort" 'emit sort([5,3,1,4,2]);' "[1, 2, 3, 4, 5]"
    run "hof:any" 'emit any([1,2,3],fn(x){return x>2;});' "1"
    run "hof:all" 'emit all([1,2,3],fn(x){return x>0;});' "1"

    # ── Strings ──
    run "str:len" 'emit len("hello");' "5"
    run "str:sub" 'emit __substr("abcdef",2,4);' "cd"
    run "str:cat" 'emit "ab"+"cd";' "abcd"
    run "str:trim" 'emit __str_trim("  hi  ");' "hi"

    # ── Arrays ──
    run "arr:idx" 'emit [10,20,30][1];' "20"
    run "arr:len" 'emit len([1,2,3,4]);' "4"
    run "arr:comp" 'emit [x*2 for x in [1,2,3]];' "[2, 4, 6]"
    run "arr:sort" 'emit sort([3,1,2])[0];' "1"

    # ── Crypto ──
    run "cry:sha_len" 'emit len(__sha256(""));' "64"
    run "cry:sha_empty" 'emit __substr(__sha256(""),0,8);' "e3b0c442"
    run "cry:sha_hello" 'let h=__sha256("hello"); emit __substr(h,0,8);' "2cf24dba"

    # ── JSON ──
    run "json:arr" 'emit json_parse("[1,2,3]");' "[1, 2, 3]"
    run "json:num" 'emit json_parse("42");' "42"
    run "json:bool" 'emit json_parse("true");' "1"

    # ── Edge cases ──
    run "edge:empty" 'emit len("");' "0"
    run "edge:zero" 'emit 0;' "0"
    run "edge:floor" 'emit __floor(3.7);' "3"
    run "edge:ceil" 'emit __ceil(3.2);' "4"
    run "edge:bool_t" 'emit 1==1;' "1"
    run "edge:bool_f" 'emit 1==2;' "0"

    # ── Try/catch ──
    run "try:catch" 'let c=0; try{__throw("x");}catch{let c=1;}; emit c;' "1"

    # ── NL Computing ──
    run "nl:fib" 'fib 10' "55"
    run "nl:sort" 'sort [3,1,2]' "[1, 2, 3]"
    run "nl:fact" 'fact 5' "120"

    local fixed_total=$((P + F + C))

    # ══════════════════════════════════════
    # RANDOM FUZZ TESTS
    # ══════════════════════════════════════
    if [ "$QUICK" -eq 0 ] && [ "$FUZZ_COUNT" -gt 0 ]; then
        while IFS=$'\t' read -r code expected desc; do
            [ -z "$code" ] && continue
            [ -z "$expected" ] && continue
            run "fuzz:$desc" "$code" "$expected"
        done < <(bash tools/spider-gen.sh "$FUZZ_COUNT" 2>/dev/null)
    fi

    # ── Summary ──
    local T=$((P + F + C))
    local fuzz_count=$((T - fixed_total))
    if [ $F -eq 0 ] && [ $C -eq 0 ]; then
        echo -e "\e[32m  SPIDER: $P/$T ALL CLEAN ($fixed_total fixed + $fuzz_count fuzz)\e[0m"
    else
        echo -e "\e[31m  SPIDER: $P/$T — $F fail, $C crash ($fixed_total fixed + $fuzz_count fuzz)\e[0m"
        echo -e "$ERRS"
    fi

    # ── Log ──
    echo "[$DATE] round=$round pass=$P fail=$F crash=$C total=$T fixed=$fixed_total fuzz=$fuzz_count" >> "$LOGFILE"
    if [ -n "$TOTAL_BUGS" ]; then
        echo -e "$TOTAL_BUGS" >> "$LOGFILE"
    fi
}

# ── Main loop ──
for r in $(seq 1 $LOOP_COUNT); do
    run_round $r
done

# Show log summary
if [ -f "$LOGFILE" ]; then
    lines=$(wc -l < "$LOGFILE")
    bugs=$(grep -c "FAIL\|CRASH" "$LOGFILE" 2>/dev/null)
    echo -e "\e[36m  Log: $LOGFILE ($lines entries, $bugs bug records)\e[0m"
fi
