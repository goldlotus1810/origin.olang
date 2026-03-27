#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# SPIDER DAEMON — Chạy 24/7, tự tìm bug, ghi log
# Usage:
#   bash tools/spider-daemon.sh start   — chạy nền
#   bash tools/spider-daemon.sh stop    — dừng
#   bash tools/spider-daemon.sh status  — xem trạng thái
#   bash tools/spider-daemon.sh tail    — xem log realtime
# ═══════════════════════════════════════════════════════════════

DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$DIR/origin.olang"
LOGDIR="$DIR/logs"
LOGFILE="$LOGDIR/spider-daemon.log"
PIDFILE="$LOGDIR/spider-daemon.pid"
BUGFILE="$LOGDIR/spider-bugs.log"
STATSFILE="$LOGDIR/spider-stats.csv"

mkdir -p "$LOGDIR"

# ── Helpers ──
rand_int() { echo $(( RANDOM % $1 )); }
rand_pick() { local a=("$@"); echo "${a[$(( RANDOM % ${#a[@]} ))]}"; }
rand_str() { cat /dev/urandom 2>/dev/null | tr -dc 'a-z' | head -c "$1"; }

run_test() {
    local code="$1" expected="$2" desc="$3"
    local got
    got=$(echo "$code" | timeout 5 "$BIN" 2>/dev/null | sed -n '3p' | sed 's/⦿ //')
    local exit_code=$?
    if [ $exit_code -eq 139 ] || [ $exit_code -eq 137 ]; then
        echo "CRASH|$desc|$code" >> "$BUGFILE"
        return 2
    fi
    if [ "$got" = "$expected" ]; then
        return 0
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] FAIL $desc | got '$got' want '$expected' | $code" >> "$BUGFILE"
        return 1
    fi
}

# ── Test generators ──
gen_nested_sha() {
    local s=$(rand_pick "abc" "hello" "test" "x" "$(rand_str 3)" "$(rand_str 5)")
    local start=$(rand_int 4)
    local end=$((start + 2 + RANDOM % 6))
    if [ $end -gt 64 ]; then end=64; fi
    local exp=$(echo "let h=__sha256(\"$s\"); emit __substr(h,$start,$end);" | timeout 3 "$BIN" 2>/dev/null | sed -n '3p' | sed 's/⦿ //')
    [ -z "$exp" ] && return 1
    run_test "emit __substr(__sha256(\"$s\"),$start,$end);" "$exp" "nest:sha($s,$start,$end)"
}

gen_nested_tostr() {
    local n=$((RANDOM % 99999))
    local start=$(rand_int 2)
    local slen=${#n}
    local end=$((start + 1 + RANDOM % (slen - start > 0 ? slen - start : 1)))
    if [ $end -gt $slen ]; then end=$slen; fi
    local exp=$(echo "let s=__to_string($n); emit __substr(s,$start,$end);" | timeout 3 "$BIN" 2>/dev/null | sed -n '3p' | sed 's/⦿ //')
    [ -z "$exp" ] && return 1
    run_test "emit __substr(__to_string($n),$start,$end);" "$exp" "nest:tostr($n,$start,$end)"
}

gen_interp() {
    local a=$((RANDOM % 100))
    local b=$((1 + RANDOM % 50))
    local op=$(rand_pick "+" "-" "*")
    local exp=$(echo "emit $a${op}$b;" | timeout 3 "$BIN" 2>/dev/null | sed -n '3p' | sed 's/⦿ //')
    [ -z "$exp" ] && return 1
    run_test "emit \$\"{$a${op}$b}\";" "$exp" "interp:$a${op}$b"
}

gen_operator() {
    local a=$((RANDOM % 100))
    local b=$((1 + RANDOM % 50))
    local op=$(rand_pick "+" "-" "*")
    local exp=$(echo "emit $a${op}$b;" | timeout 3 "$BIN" 2>/dev/null | sed -n '3p' | sed 's/⦿ //')
    [ -z "$exp" ] && return 1
    run_test "emit $a${op}$b;" "$exp" "op:$a${op}$b"
}

gen_fib() {
    local n=$((5 + RANDOM % 15))
    local exp=$(python3 -c "
def f(n):
    if n<2: return n
    return f(n-1)+f(n-2)
print(f($n))" 2>/dev/null)
    [ -z "$exp" ] && return 1
    run_test "fn fib(n){if n<2{return n;};return fib(n-1)+fib(n-2);}; emit fib($n);" "$exp" "fn:fib($n)"
}

gen_array_idx() {
    local a=$((RANDOM % 100))
    local b=$((RANDOM % 100))
    local c=$((RANDOM % 100))
    local i=$(rand_int 3)
    local vals=($a $b $c)
    run_test "emit [$a,$b,$c][$i];" "${vals[$i]}" "arr:[$a,$b,$c][$i]"
}

gen_sort() {
    local a=$((RANDOM % 20))
    local b=$((RANDOM % 20))
    local c=$((RANDOM % 20))
    local sorted=$(echo -e "$a\n$b\n$c" | sort -n | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')
    run_test "emit sort([$a,$b,$c]);" "[$sorted]" "sort:[$a,$b,$c]"
}

gen_len_concat() {
    local s1=$(rand_str $((1 + RANDOM % 5)))
    local s2=$(rand_str $((1 + RANDOM % 5)))
    local exp=${#s1}
    exp=$((exp + ${#s2}))
    run_test "emit len(\"$s1\"+\"$s2\");" "$exp" "len:$s1+$s2"
}

# ── Fixed regression suite ──
run_fixed() {
    local p=0 f=0 c=0
    while IFS=$'\t' read -r code expected desc; do
        [ -z "$code" ] && continue
        run_test "$code" "$expected" "fixed:$desc"
        case $? in
            0) p=$((p+1)) ;;
            1) f=$((f+1)) ;;
            2) c=$((c+1)) ;;
        esac
    done <<'FIXED'
emit __substr(__sha256("abc"),0,8);	ba7816bf	sha_abc
emit __substr(__sha256("test"),0,8);	9f86d081	sha_test
emit char_at(__sha256("abc"),0);	b	char_sha
emit __substr(__to_string(12345),0,3);	123	tostr_sub
emit len(__sha256("x"));	64	len_sha
emit __to_string(__to_string(99));	99	tostr2
emit len("ab"+"cd");	4	concat_len
emit $"{2+3}";	5	interp_add
emit $"{7*6}";	42	interp_mul
emit $"{100-37}";	63	interp_sub
emit 2+3*4;	14	prec
emit (2+3)*4;	20	paren
emit 17%5;	2	mod
emit 3>2;	1	cmp
fn f(x){return x*2;}; emit f(21);	42	fn_basic
fn fib(n){if n<2{return n;};return fib(n-1)+fib(n-2);}; emit fib(10);	55	fib10
emit sort([5,3,1,4,2]);	[1, 2, 3, 4, 5]	sort
emit [10,20,30][1];	20	arr_idx
emit len("hello");	5	str_len
emit __substr("abcdef",2,4);	cd	str_sub
emit len(__sha256(""));	64	sha_empty_len
emit __substr(__sha256(""),0,8);	e3b0c442	sha_empty
emit map([1,2,3],fn(x){return x*10;});	[10, 20, 30]	map
emit filter([1,2,3,4,5],fn(x){return x>3;});	[4, 5]	filter
emit reduce([1,2,3,4],fn(a,b){return a+b;});	10	reduce
emit json_parse("[1,2,3]");	[1, 2, 3]	json_arr
emit json_parse("42");	42	json_num
fib 10	55	nl_fib
sort [3,1,2]	[1, 2, 3]	nl_sort
FIXED
    echo "$p $f $c"
}

# ── Daemon loop ──
daemon_run() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Spider daemon started (PID $$)" >> "$LOGFILE"
    echo "pass,fail,crash,total,timestamp" >> "$STATSFILE" 2>/dev/null

    local round=0
    while true; do
        round=$((round + 1))
        local total_p=0 total_f=0 total_c=0

        # Check binary exists
        if [ ! -f "$BIN" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Binary not found: $BIN" >> "$LOGFILE"
            sleep 30
            continue
        fi

        # Run fixed tests
        read fp ff fc <<< $(run_fixed)
        total_p=$((total_p + fp))
        total_f=$((total_f + ff))
        total_c=$((total_c + fc))

        # Run 20 random fuzz tests
        for i in $(seq 1 20); do
            case $((RANDOM % 8)) in
                0) gen_nested_sha ;;
                1) gen_nested_tostr ;;
                2) gen_interp ;;
                3) gen_operator ;;
                4) gen_fib ;;
                5) gen_array_idx ;;
                6) gen_sort ;;
                7) gen_len_concat ;;
            esac
            case $? in
                0) total_p=$((total_p + 1)) ;;
                1) total_f=$((total_f + 1)) ;;
                2) total_c=$((total_c + 1)) ;;
            esac
        done

        local total=$((total_p + total_f + total_c))
        local ts=$(date '+%Y-%m-%d %H:%M:%S')

        # Log stats
        echo "$total_p,$total_f,$total_c,$total,$ts" >> "$STATSFILE"

        if [ $total_f -gt 0 ] || [ $total_c -gt 0 ]; then
            echo "[$ts] R$round: $total_p/$total FAIL=$total_f CRASH=$total_c" >> "$LOGFILE"
        else
            # Only log every 10th clean round to keep log small
            if [ $((round % 10)) -eq 0 ]; then
                echo "[$ts] R$round: $total_p/$total ALL CLEAN" >> "$LOGFILE"
            fi
        fi

        # Wait 60 seconds between rounds
        sleep 60
    done
}

# ── Commands ──
case "${1:-status}" in
    start)
        if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
            echo "Spider daemon already running (PID $(cat "$PIDFILE"))"
            exit 1
        fi
        echo "Starting spider daemon..."
        cd "$DIR"
        nohup bash "$0" _daemon >> "$LOGFILE" 2>&1 &
        echo $! > "$PIDFILE"
        echo "Spider daemon started (PID $!)"
        echo "  Log:   $LOGFILE"
        echo "  Bugs:  $BUGFILE"
        echo "  Stats: $STATSFILE"
        echo "  Stop:  bash tools/spider-daemon.sh stop"
        ;;
    _daemon)
        daemon_run
        ;;
    stop)
        if [ -f "$PIDFILE" ]; then
            pid=$(cat "$PIDFILE")
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid" 2>/dev/null
                # Kill child processes too
                pkill -P "$pid" 2>/dev/null
                rm -f "$PIDFILE"
                echo "Spider daemon stopped (was PID $pid)"
            else
                rm -f "$PIDFILE"
                echo "Spider daemon not running (stale PID)"
            fi
        else
            echo "Spider daemon not running"
        fi
        ;;
    status)
        if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
            pid=$(cat "$PIDFILE")
            echo "Spider daemon: RUNNING (PID $pid)"
            if [ -f "$STATSFILE" ]; then
                rounds=$(wc -l < "$STATSFILE")
                rounds=$((rounds - 1))
                echo "  Rounds: $rounds"
                tail -1 "$STATSFILE" | awk -F, '{print "  Last:   pass="$1" fail="$2" crash="$3" total="$4" at "$5}'
            fi
            if [ -f "$BUGFILE" ] && [ -s "$BUGFILE" ]; then
                bugs=$(wc -l < "$BUGFILE")
                echo "  Bugs found: $bugs"
                echo "  Latest:"
                tail -3 "$BUGFILE" | sed 's/^/    /'
            else
                echo "  Bugs found: 0"
            fi
        else
            echo "Spider daemon: STOPPED"
            if [ -f "$STATSFILE" ]; then
                rounds=$(grep -c ',' "$STATSFILE" 2>/dev/null)
                echo "  Historical rounds: $rounds"
            fi
            if [ -f "$BUGFILE" ]; then
                bugs=$(wc -l < "$BUGFILE" 2>/dev/null)
                echo "  Historical bugs: $bugs"
            fi
        fi
        ;;
    tail)
        echo "Watching spider logs (Ctrl+C to stop)..."
        tail -f "$LOGFILE" "$BUGFILE" 2>/dev/null
        ;;
    report)
        echo "═══ SPIDER REPORT ═══"
        if [ -f "$STATSFILE" ]; then
            total_rounds=$(grep -c ',' "$STATSFILE" 2>/dev/null)
            total_tests=$(awk -F, 'NR>1{s+=$4}END{print s}' "$STATSFILE" 2>/dev/null)
            total_pass=$(awk -F, 'NR>1{s+=$1}END{print s}' "$STATSFILE" 2>/dev/null)
            total_fail=$(awk -F, 'NR>1{s+=$2}END{print s}' "$STATSFILE" 2>/dev/null)
            total_crash=$(awk -F, 'NR>1{s+=$3}END{print s}' "$STATSFILE" 2>/dev/null)
            echo "  Rounds:  $total_rounds"
            echo "  Tests:   $total_tests"
            echo "  Pass:    $total_pass"
            echo "  Fail:    $total_fail"
            echo "  Crash:   $total_crash"
        fi
        if [ -f "$BUGFILE" ] && [ -s "$BUGFILE" ]; then
            echo ""
            echo "  Bugs found:"
            cat "$BUGFILE" | sed 's/^/    /'
        else
            echo "  No bugs found!"
        fi
        ;;
    *)
        echo "Usage: bash tools/spider-daemon.sh {start|stop|status|tail|report}"
        ;;
esac
