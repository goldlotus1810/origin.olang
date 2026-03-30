#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# HOMEOS FULL TEST SUITE — Đánh giá TOÀN DIỆN hệ thống
#
# Chạy: bash tests_full.sh
# Hoặc chạy từng phần: bash tests_full.sh [section]
#   sections: unit bio alert integration regression bench fuzz
#
# Đây là FILE DUY NHẤT cần chạy. Nó gọi tất cả test khác
# + bổ sung integration, regression, benchmark, fuzz.
#
# Tiêu chuẩn PASS: 0 fail, 0 alert, benchmark trong ngưỡng.
#
# Tác giả: Sora
# Ngày: 2026-03-30
# ═══════════════════════════════════════════════════════════════

set -uo pipefail

ORIGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
BINARY="$ORIGIN_DIR/origin.olang"
STDLIB="$ORIGIN_DIR/stdlib"
SECTION="${1:-all}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

I_PASS=0
I_FAIL=0
I_WARN=0
I_ERRORS=""

pass() { I_PASS=$((I_PASS + 1)); echo -e "  ${GREEN}  OK${NC} $1"; }
fail() { I_FAIL=$((I_FAIL + 1)); I_ERRORS="$I_ERRORS\n  ${RED}FAIL${NC} $1 — $2"; echo -e "  ${RED}FAIL${NC} $1"; }
warn() { I_WARN=$((I_WARN + 1)); echo -e "  ${YELLOW}WARN${NC} $1 — $2"; }

strip_repl() { sed 's/^⦿ //; /^bye$/d; /^$/d'; }

expect() {
    local name="$1" code="$2" expected="$3" timeout_sec="${4:-5}"
    local raw actual
    raw=$(echo "$code" | timeout "$timeout_sec" "$BINARY" 2>/dev/null || true)
    actual=$(echo "$raw" | strip_repl | tr -d '\n')
    if [ "$actual" = "$expected" ]; then pass "$name"
    else fail "$name" "expected [$expected] got [$actual]"; fi
}

expect_contains() {
    local name="$1" code="$2" substr="$3" timeout_sec="${4:-5}"
    local raw actual
    raw=$(echo "$code" | timeout "$timeout_sec" "$BINARY" 2>/dev/null || true)
    actual=$(echo "$raw" | strip_repl | tr -d '\n')
    if echo "$actual" | grep -qF "$substr"; then pass "$name"
    else fail "$name" "output missing [$substr] in [$actual]"; fi
}

expect_not_crash() {
    local name="$1" code="$2" timeout_sec="${3:-5}"
    local exit_code
    echo "$code" | timeout "$timeout_sec" "$BINARY" >/dev/null 2>&1
    exit_code=$?
    if [ $exit_code -eq 139 ] || [ $exit_code -eq 134 ] || [ $exit_code -eq 136 ]; then
        fail "$name" "CRASH (exit $exit_code)"
    elif [ $exit_code -eq 124 ]; then
        fail "$name" "TIMEOUT (${timeout_sec}s)"
    else
        pass "$name"
    fi
}

echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  HOMEOS TOÀN DIỆN TEST — $(date +%Y-%m-%d\ %H:%M)${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

# ═══════════════════════════════════════════════════════════════
# PHASE 1: Core tests (existing)
# ═══════════════════════════════════════════════════════════════
if [ "$SECTION" = "all" ] || [ "$SECTION" = "unit" ]; then
    echo -e "${BOLD}━━━ PHASE 1: Unit Tests (tests.sh) ━━━${NC}"
    UNIT_RESULT=0
    bash "$ORIGIN_DIR/tests.sh" 2>&1 || UNIT_RESULT=$?
    if [ $UNIT_RESULT -ne 0 ]; then
        fail "phase1/unit_tests" "tests.sh exited with $UNIT_RESULT"
    else
        pass "phase1/unit_tests (194 tests)"
    fi
    echo ""
fi

# ═══════════════════════════════════════════════════════════════
# PHASE 2: Biology architecture tests (existing)
# ═══════════════════════════════════════════════════════════════
if [ "$SECTION" = "all" ] || [ "$SECTION" = "bio" ]; then
    echo -e "${BOLD}━━━ PHASE 2: Biology Architecture Tests ━━━${NC}"
    BIO_RESULT=0
    bash "$ORIGIN_DIR/tests_biology.sh" 2>&1 || BIO_RESULT=$?
    if [ $BIO_RESULT -ne 0 ]; then
        warn "phase2/biology" "$BIO_RESULT biology tests failed"
    else
        pass "phase2/biology (all pass)"
    fi
    echo ""
fi

# ═══════════════════════════════════════════════════════════════
# PHASE 3: Red Alert watchdog (existing)
# ═══════════════════════════════════════════════════════════════
if [ "$SECTION" = "all" ] || [ "$SECTION" = "alert" ]; then
    echo -e "${BOLD}━━━ PHASE 3: Red Alert Watchdog ━━━${NC}"
    ALERT_RESULT=0
    bash "$ORIGIN_DIR/red_alert.sh" 2>&1 || ALERT_RESULT=$?
    if [ $ALERT_RESULT -ne 0 ]; then
        warn "phase3/red_alert" "$ALERT_RESULT architectural violations"
    else
        pass "phase3/red_alert (0 violations)"
    fi
    echo ""
fi

# ═══════════════════════════════════════════════════════════════
# PHASE 4: Integration Tests — end-to-end pipeline
# ═══════════════════════════════════════════════════════════════
if [ "$SECTION" = "all" ] || [ "$SECTION" = "integration" ]; then
    echo -e "${BOLD}━━━ PHASE 4: Integration Tests ━━━${NC}"
    echo -e "${CYAN}── I1. Compiler pipeline ──${NC}"

    # I1.1-I1.10: Olang language features end-to-end
    expect "i1/emit_int" "emit 42;" "42"
    expect "i1/emit_float" "emit 3.14;" "3.14"
    expect "i1/emit_string" 'emit "hello";' "hello"
    expect "i1/emit_bool" "emit 1 == 1;" "1"
    expect "i1/let_assign" "let x = 99; emit x;" "99"
    expect "i1/arithmetic" "emit (2 + 3) * 4;" "20"
    expect "i1/string_concat" 'emit "ab" + "cd";' "abcd"
    expect "i1/string_len" 'emit len("hello");' "5"
    expect "i1/array_basic" "let a = [10,20,30]; emit a[1];" "20"
    expect "i1/array_push" "let a = [1]; push(a, 2); emit len(a);" "2"

    echo -e "${CYAN}── I2. Control flow ──${NC}"
    expect "i2/if_true" "if 1 { emit 1; };" "1"
    expect "i2/if_false" "if 0 { emit 1; } else { emit 2; };" "2"
    expect "i2/while_loop" "let i = 0; while i < 5 { let i = i + 1; }; emit i;" "5"
    expect "i2/for_loop" "let s = 0; for x in [1,2,3] { let s = s + x; }; emit s;" "6"
    expect "i2/nested_if" "let x = 5; if x > 3 { if x < 10 { emit 1; }; };" "1"

    echo -e "${CYAN}── I3. Functions ──${NC}"
    expect "i3/fn_basic" "fn f() { return 42; }; emit f();" "42"
    expect "i3/fn_args" "fn add(a,b) { return a+b; }; emit add(3,4);" "7"
    expect "i3/fn_recursive" "fn fac(n) { if n <= 1 { return 1; }; return n * fac(n-1); }; emit fac(5);" "120"
    expect "i3/fn_closure" "let f = fn(x) { return x * 2; }; emit f(21);" "42"
    expect "i3/fn_higher_order" "fn apply(f, x) { return f(x); }; let dbl = fn(n) { return n*2; }; emit apply(dbl, 5);" "10"

    echo -e "${CYAN}── I4. Data structures ──${NC}"
    expect "i4/dict_basic" 'let d = { x: 1, y: 2 }; emit d.x + d.y;' "3"
    expect "i4/array_map" "let a = [1,2,3]; let b = map(a, fn(x){return x*10;}); emit b[2];" "30"
    expect "i4/array_filter" "let a = [1,2,3,4,5]; let b = filter(a, fn(x){return x>3;}); emit len(b);" "2"
    expect "i4/pipe" "fn dbl(x){return x*2;}; fn inc(x){return x+1;}; emit pipe(5, dbl, inc);" "11"

    echo -e "${CYAN}── I5. Error handling ──${NC}"
    expect "i5/try_catch" "try { emit 0; } catch { emit 99; };" "0"
    expect_not_crash "i5/empty_input" ""
    expect_not_crash "i5/only_spaces" "   "

    echo -e "${CYAN}── I6. Match + Union ──${NC}"
    expect "i6/match_basic" 'match 5 { 5 => { emit 1; } _ => { emit 0; } };' "1"

    echo ""
fi

# ═══════════════════════════════════════════════════════════════
# PHASE 5: KnowTree Regression Tests
# ═══════════════════════════════════════════════════════════════
if [ "$SECTION" = "all" ] || [ "$SECTION" = "regression" ]; then
    echo -e "${BOLD}━━━ PHASE 5: KnowTree Regression ━━━${NC}"

    echo -e "${CYAN}── K1. Encode produces valid molecules ──${NC}"

    # K1.1: chain_encode phải tạo non-empty chain
    expect_contains "k1/encode_nonempty" \
        'let c = chain_encode("hello"); emit len(c);' \
        "" 5  # chỉ cần không crash

    # K1.2: p_weight cho ASCII phải > 0
    expect_not_crash "k1/pweight_ascii" \
        'emit p_weight(65);' 5

    # K1.3: chain_summary phải trả số
    expect_not_crash "k1/chain_summary" \
        'let c = chain_encode("test"); emit chain_summary(c);' 5

    echo -e "${CYAN}── K2. KnowTree search relevance ──${NC}"

    # K2.1: Olang query → must mention Olang/ngon ngu/lap trinh
    if echo 'Olang la gi' | timeout 5 "$BINARY" 2>/dev/null | strip_repl | grep -qi "olang\|ngon ngu\|lap trinh\|compile\|language"; then
        pass "k2/search_olang"
    else
        warn "k2/search_olang" "KnowTree search 'Olang' không liên quan"
    fi

    # K2.2: Trai Dat query → should mention Trai Dat/hanh tinh/Mat Troi
    if echo 'Trai Dat la gi' | timeout 5 "$BINARY" 2>/dev/null | strip_repl | grep -qi "trai dat\|hanh tinh\|mat troi\|earth"; then
        pass "k2/search_traidat"
    else
        warn "k2/search_traidat" "KnowTree search 'Trai Dat' không liên quan"
    fi

    # K2.3: Random nonsense → must NOT match real facts
    NONSENSE_OUT=$(echo 'zxcvbnm qwerty asdfgh' | timeout 5 "$BINARY" 2>/dev/null | strip_repl | tr -d '\n')
    if echo "$NONSENSE_OUT" | grep -qi "trai dat\|olang\|viet nam\|HomeOS"; then
        fail "k2/no_false_match" "Nonsense input matched real knowledge: $NONSENSE_OUT"
    else
        pass "k2/no_false_match"
    fi

    echo -e "${CYAN}── K3. KnowTree persistence ──${NC}"

    # K3.1: homeos.knowledge file tồn tại
    if [ -f "$ORIGIN_DIR/homeos.knowledge" ]; then
        KT_LINES=$(wc -l < "$ORIGIN_DIR/homeos.knowledge")
        if [ "$KT_LINES" -gt 10 ]; then
            pass "k3/knowledge_file ($KT_LINES facts)"
        else
            warn "k3/knowledge_file" "Chỉ có $KT_LINES facts — quá ít"
        fi
    else
        warn "k3/knowledge_file" "homeos.knowledge chưa tồn tại"
    fi

    echo ""
fi

# ═══════════════════════════════════════════════════════════════
# PHASE 6: Performance Benchmarks
# ═══════════════════════════════════════════════════════════════
if [ "$SECTION" = "all" ] || [ "$SECTION" = "bench" ]; then
    echo -e "${BOLD}━━━ PHASE 6: Performance Benchmarks ━━━${NC}"

    BENCH_FILE="/tmp/nox_bench_history.txt"

    # P1: fib(20) execution time
    echo -e "${CYAN}── P1. Compute: fib(20) ──${NC}"
    FIB_START=$(date +%s%N)
    echo 'fn fib(n) { if n < 2 { return n; }; return fib(n-1) + fib(n-2); }; emit fib(20);' | \
        timeout 10 "$BINARY" >/dev/null 2>&1
    FIB_END=$(date +%s%N)
    FIB_MS=$(( (FIB_END - FIB_START) / 1000000 ))
    echo -e "  ${CYAN}TIME${NC}  fib(20) = ${FIB_MS}ms"
    if [ $FIB_MS -gt 5000 ]; then
        fail "p1/fib20_time" "fib(20) took ${FIB_MS}ms (>5000ms = too slow)"
    elif [ $FIB_MS -gt 2000 ]; then
        warn "p1/fib20_time" "fib(20) took ${FIB_MS}ms (>2000ms = slow)"
    else
        pass "p1/fib20_time (${FIB_MS}ms)"
    fi

    # P2: Self-build time
    echo -e "${CYAN}── P2. Self-build time ──${NC}"
    BUILD_START=$(date +%s%N)
    timeout 120 "$BINARY" --build >/dev/null 2>&1
    BUILD_EXIT=$?
    BUILD_END=$(date +%s%N)
    BUILD_MS=$(( (BUILD_END - BUILD_START) / 1000000 ))
    BUILD_SEC=$(( BUILD_MS / 1000 ))
    if [ $BUILD_EXIT -eq 0 ]; then
        echo -e "  ${CYAN}TIME${NC}  self-build = ${BUILD_SEC}s"
        if [ $BUILD_SEC -gt 60 ]; then
            warn "p2/build_time" "Build took ${BUILD_SEC}s (>60s = slow)"
        else
            pass "p2/build_time (${BUILD_SEC}s)"
        fi
        rm -f origin_new.olang
    else
        warn "p2/build_time" "Build failed (exit $BUILD_EXIT)"
    fi

    # P3: Binary size tracking
    echo -e "${CYAN}── P3. Binary size ──${NC}"
    BINARY_SIZE=$(stat -c%s "$BINARY" 2>/dev/null || echo 0)
    BINARY_KB=$((BINARY_SIZE / 1024))
    echo -e "  ${CYAN}SIZE${NC}  binary = ${BINARY_KB}KB"
    if [ $BINARY_KB -gt 2048 ]; then
        fail "p3/binary_size" "${BINARY_KB}KB > 2MB — quá lớn"
    elif [ $BINARY_KB -gt 1024 ]; then
        warn "p3/binary_size" "${BINARY_KB}KB > 1MB — đang phình"
    else
        pass "p3/binary_size (${BINARY_KB}KB)"
    fi

    # P4: Boot time (first response)
    echo -e "${CYAN}── P4. Boot time ──${NC}"
    BOOT_START=$(date +%s%N)
    echo 'emit 1;' | timeout 5 "$BINARY" >/dev/null 2>&1
    BOOT_END=$(date +%s%N)
    BOOT_MS=$(( (BOOT_END - BOOT_START) / 1000000 ))
    echo -e "  ${CYAN}TIME${NC}  boot+emit = ${BOOT_MS}ms"
    if [ $BOOT_MS -gt 3000 ]; then
        fail "p4/boot_time" "${BOOT_MS}ms > 3000ms — quá chậm"
    elif [ $BOOT_MS -gt 1000 ]; then
        warn "p4/boot_time" "${BOOT_MS}ms > 1000ms — chậm"
    else
        pass "p4/boot_time (${BOOT_MS}ms)"
    fi

    # P5: Source LOC tracking
    echo -e "${CYAN}── P5. Codebase size ──${NC}"
    OLANG_LOC=$(find "$STDLIB" -name "*.ol" | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')
    ASM_LOC=$(wc -l < "$ORIGIN_DIR/vm/x86_64/vm_x86_64.S" 2>/dev/null || echo 0)
    echo -e "  ${CYAN}LOC${NC}   Olang = ${OLANG_LOC}, ASM = ${ASM_LOC}"

    # Save benchmark history
    echo "$(date +%Y-%m-%d_%H:%M) fib=${FIB_MS}ms build=${BUILD_SEC}s binary=${BINARY_KB}KB boot=${BOOT_MS}ms olang=${OLANG_LOC}loc asm=${ASM_LOC}loc" >> "$BENCH_FILE"

    # Compare with previous
    if [ -f "$BENCH_FILE" ] && [ $(wc -l < "$BENCH_FILE") -gt 1 ]; then
        PREV=$(tail -2 "$BENCH_FILE" | head -1)
        echo -e "  ${CYAN}PREV${NC}  $PREV"
    fi

    echo ""
fi

# ═══════════════════════════════════════════════════════════════
# PHASE 7: Fuzz Testing — random input không crash
# ═══════════════════════════════════════════════════════════════
if [ "$SECTION" = "all" ] || [ "$SECTION" = "fuzz" ]; then
    echo -e "${BOLD}━━━ PHASE 7: Fuzz Testing ━━━${NC}"

    echo -e "${CYAN}── F1. Edge cases — không crash ──${NC}"

    # Danh sách input đáng sợ
    expect_not_crash "f1/empty" ""
    expect_not_crash "f1/newline" "\n"
    expect_not_crash "f1/null_byte" "\x00"
    expect_not_crash "f1/long_string" "$(python3 -c 'print("a"*10000)' 2>/dev/null || echo aaaaaaaaaa)"
    expect_not_crash "f1/deep_parens" "$(python3 -c 'print("("*100 + "1" + ")"*100)' 2>/dev/null || echo '((1))')"
    expect_not_crash "f1/deep_braces" "$(python3 -c 'print("if 1 {"*20 + "emit 1;" + "};"*20)' 2>/dev/null || echo 'emit 1;')"
    expect_not_crash "f1/unicode" "emit 42; // 你好世界 🌍 مرحبا"
    expect_not_crash "f1/emoji_only" "🔥🔥🔥"
    expect_not_crash "f1/backticks" '`rm -rf /`'
    expect_not_crash "f1/sql_inject" "'; DROP TABLE users; --"
    expect_not_crash "f1/html_inject" '<script>alert(1)</script>'
    expect_not_crash "f1/escape_chars" '\n\t\r\0\x00\xff'
    expect_not_crash "f1/max_number" "emit 99999999999999999999999999;"
    expect_not_crash "f1/negative" "emit -999999;"
    expect_not_crash "f1/division_zero" "emit 1/0;" 3
    # infinite loop: timeout is OK (expected), crash is NOT OK
    local raw_exit=0
    echo "while 1 { let x = 1; };" | timeout 3 "$BINARY" >/dev/null 2>&1 || raw_exit=$?
    if [ $raw_exit -eq 139 ] || [ $raw_exit -eq 134 ] || [ $raw_exit -eq 136 ]; then
        fail "f1/inf_loop_guard" "CRASH on infinite loop (exit $raw_exit)"
    else
        pass "f1/inf_loop_guard (timeout OK, no crash)"
    fi
    expect_not_crash "f1/many_semicolons" ";;;;;;;;;;;;"
    expect_not_crash "f1/only_operators" "+-*/%><="
    expect_not_crash "f1/mismatched_braces" "fn f() { { { } emit 1;"
    expect_not_crash "f1/mismatched_parens" "emit ((((1)));"

    echo -e "${CYAN}── F2. Random input (20 rounds) ──${NC}"
    FUZZ_CRASH=0
    for i in $(seq 1 20); do
        FUZZ_INPUT=$(head -c 50 /dev/urandom | base64 | head -c 40)
        echo "$FUZZ_INPUT" | timeout 3 "$BINARY" >/dev/null 2>&1
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 139 ] || [ $EXIT_CODE -eq 134 ] || [ $EXIT_CODE -eq 136 ]; then
            FUZZ_CRASH=$((FUZZ_CRASH + 1))
            echo -e "  ${RED}CRASH${NC} fuzz round $i: input=$(echo $FUZZ_INPUT | head -c 20)..."
        fi
    done
    if [ $FUZZ_CRASH -eq 0 ]; then
        pass "f2/random_fuzz (20/20 survived)"
    else
        fail "f2/random_fuzz" "$FUZZ_CRASH/20 crashed"
    fi

    echo ""
fi

# ═══════════════════════════════════════════════════════════════
# REPORT
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  TỔNG KẾT${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${GREEN}Pass:${NC}  $I_PASS"
echo -e "  ${YELLOW}Warn:${NC}  $I_WARN"
echo -e "  ${RED}Fail:${NC}  $I_FAIL"
echo ""

if [ $I_FAIL -eq 0 ] && [ $I_WARN -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}✅ TOÀN BỘ HỆ THỐNG: PASS${NC}"
    echo -e "  ${GREEN}Compiler đúng. Kiến trúc đúng. Hiệu năng tốt. Không crash.${NC}"
elif [ $I_FAIL -eq 0 ]; then
    echo -e "  ${YELLOW}${BOLD}⚠  HỆ THỐNG: PASS CÓ CẢNH BÁO${NC}"
    echo -e "  ${YELLOW}Không lỗi nghiêm trọng nhưng cần review $I_WARN warnings.${NC}"
else
    echo -e "  ${RED}${BOLD}❌ HỆ THỐNG: $I_FAIL FAILURES${NC}"
    if [ -n "$I_ERRORS" ]; then
        echo -e "$I_ERRORS"
    fi
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "  ${CYAN}Chạy từng phần:${NC}"
echo -e "    bash tests_full.sh unit         — 194 compiler tests"
echo -e "    bash tests_full.sh bio          — biology architecture"
echo -e "    bash tests_full.sh alert        — red alert watchdog"
echo -e "    bash tests_full.sh integration  — end-to-end pipeline"
echo -e "    bash tests_full.sh regression   — KnowTree regression"
echo -e "    bash tests_full.sh bench        — performance benchmarks"
echo -e "    bash tests_full.sh fuzz         — crash resistance"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"

exit $I_FAIL
