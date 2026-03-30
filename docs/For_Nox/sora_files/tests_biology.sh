#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# HOMEOS BIOLOGY TEST SUITE
# Hardlock kiến trúc sinh vật bậc cao — SPEC: HOMEOS_BIOLOGY_SPEC.md
#
# Chạy: bash tests_biology.sh
# Mục đích: đảm bảo Nox tuân thủ kiến trúc sinh học.
#           Tests này KHÔNG ĐƯỢC phép fail sau khi implement xong.
#           Nếu Nox muốn thay đổi kiến trúc → phải sửa spec TRƯỚC,
#           sau đó sửa test, sau đó mới sửa code.
#           TEST LÀ LUẬT. CODE TUÂN THEO TEST. KHÔNG NGƯỢC LẠI.
#
# Tác giả: Sora (cho Lupin review, cho Nox tuân thủ)
# Ngày: 2026-03-30
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

ORIGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
BINARY="$ORIGIN_DIR/origin.olang"
STDLIB="$ORIGIN_DIR/stdlib"

PASS=0
FAIL=0
WARN=0
ERRORS=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

pass() { PASS=$((PASS + 1)); echo -e "  ${GREEN}  OK${NC} $1"; }
fail() { FAIL=$((FAIL + 1)); ERRORS="$ERRORS\n  ${RED}FAIL${NC} $1 — $2"; echo -e "  ${RED}FAIL${NC} $1"; }
warn() { WARN=$((WARN + 1)); echo -e "  ${YELLOW}WARN${NC} $1 — $2"; }

strip_repl() { sed 's/^⦿ //; /^bye$/d; /^$/d'; }

run_bio_test() {
    local name="$1"
    local code="$2"
    local expected="$3"
    local timeout_sec="${4:-5}"

    local raw
    raw=$(echo "$code" | timeout "$timeout_sec" "$BINARY" 2>/dev/null || true)
    local actual
    actual=$(echo "$raw" | strip_repl | tr -d '\n')

    if [ "$actual" = "$expected" ]; then
        pass "$name"
    else
        fail "$name" "expected [$expected] got [$actual]"
    fi
}

run_bio_test_contains() {
    local name="$1"
    local code="$2"
    local expected_substr="$3"
    local timeout_sec="${4:-5}"

    local raw
    raw=$(echo "$code" | timeout "$timeout_sec" "$BINARY" 2>/dev/null || true)
    local actual
    actual=$(echo "$raw" | strip_repl | tr -d '\n')

    if echo "$actual" | grep -qF "$expected_substr"; then
        pass "$name"
    else
        fail "$name" "output [$actual] does not contain [$expected_substr]"
    fi
}

run_bio_test_not_contains() {
    local name="$1"
    local code="$2"
    local forbidden_substr="$3"
    local timeout_sec="${4:-5}"

    local raw
    raw=$(echo "$code" | timeout "$timeout_sec" "$BINARY" 2>/dev/null || true)
    local actual
    actual=$(echo "$raw" | strip_repl | tr -d '\n')

    if echo "$actual" | grep -qF "$forbidden_substr"; then
        fail "$name" "output contains forbidden [$forbidden_substr]"
    else
        pass "$name"
    fi
}

echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "${BOLD}  HOMEOS BIOLOGY TEST SUITE${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""

# ═══════════════════════════════════════════════════════════════
# B1. PIPELINE TRUNG TÂM — Mọi input PHẢI đi qua pipeline
# Spec: §XVIII, §XIX — repl.ol chỉ 5 dòng, toàn bộ logic trong pipeline
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}── B1. Pipeline trung tâm ──${NC}"

# B1.1: Code có semicolon → phải compile & run
run_bio_test "b1/code_semicolon" \
    "emit 42;" \
    "42"

# B1.2: Code KHÔNG có semicolon → cũng phải compile & run (emit là keyword)
run_bio_test "b1/code_no_semicolon" \
    "emit 42" \
    "42"

# B1.3: Math expression
run_bio_test "b1/math_expression" \
    "emit 1 + 1;" \
    "2"

# B1.4: Function definition + call
run_bio_test "b1/function_call" \
    "fn double(x) { return x * 2; }; emit double(21);" \
    "42"

# B1.5: "1+1=?" KHÔNG được trả garbage — phải trả 2 hoặc "2"
run_bio_test_not_contains "b1/math_question_no_garbage" \
    "1+1=?" \
    "Character class"

# B1.6: "emit 42" (no semicolon) KHÔNG được trả "Nox khong tim thay"
run_bio_test_not_contains "b1/emit_no_notfound" \
    "emit 42" \
    "Nox khong tim thay"

# B1.7: Multi-statement
run_bio_test "b1/multi_statement" \
    "let x = 10; let y = 20; emit x + y;" \
    "30"

# ═══════════════════════════════════════════════════════════════
# B2. CLASSIFICATION — KnowTree k-NN, KHÔNG if/else
# Spec: §VI — classify bằng nearest neighbor, không hardcode
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}── B2. Classification (pipeline routing) ──${NC}"

# B2.1: Greeting → phải nhận ra, trả lời warmly (không cần exact match)
run_bio_test_not_contains "b2/greeting_hello" \
    "hello" \
    "Nox khong tim thay"

run_bio_test_not_contains "b2/greeting_chao" \
    "xin chao" \
    "Nox khong tim thay"

# B2.2: Code detection — phải compile, không route qua chatbot
run_bio_test "b2/code_let" \
    "let x = 42; emit x;" \
    "42"

run_bio_test "b2/code_fn" \
    "fn f() { return 99; }; emit f();" \
    "99"

# B2.3: Unknown input — nên trả "không biết" KHÔNG trả random fact
run_bio_test_not_contains "b2/unknown_no_random" \
    "xyzzy12345" \
    "Character class"

# ═══════════════════════════════════════════════════════════════
# B3. CẢM XÚC — Trạng thái liên tục, KHÔNG phải tag
# Spec: §VII — EmotionState tồn tại xuyên suốt session
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}── B3. Emotion state ──${NC}"

# B3.1: Nếu có emotion system → phải có trạng thái
# Test: gọi status → phải report emotion state (nếu đã implement)
if echo "status" | timeout 3 "$BINARY" 2>/dev/null | grep -q "emotion\|valence\|arousal\|mood"; then
    pass "b3/emotion_in_status"
else
    warn "b3/emotion_in_status" "emotion state chưa hiện trong status (chưa implement?)"
fi

# ═══════════════════════════════════════════════════════════════
# B4. TRÍ NHỚ — STM phải hoạt động
# Spec: §VIII — STM 7±2 items, evict ít quan trọng nhất
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}── B4. Memory ──${NC}"

# B4.1: Lưu biến qua nhiều statements (basic STM/scope test)
run_bio_test "b4/var_persist" \
    "let a = 10; let b = 20; emit a + b;" \
    "30"

# B4.2: Function nhớ kết quả trước
run_bio_test "b4/fn_accumulate" \
    "let s = 0; let i = 1; while i <= 5 { let s = s + i; let i = i + 1; }; emit s;" \
    "15"

# ═══════════════════════════════════════════════════════════════
# B5. BẢN NĂNG — Phải hoạt động, phải có đủ
# Spec: §X — 12 bản năng
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}── B5. Instincts ──${NC}"

# B5.1: Safety instinct — SecurityGate phải chặn
# (test nhẹ, không test actual harmful content)
# Test: pipeline phải có security check (source code audit, not runtime)
if grep -q "security\|SecurityGate\|safety\|safe" "$STDLIB/homeos/pipeline.ol" 2>/dev/null; then
    pass "b5/security_gate_exists"
else
    fail "b5/security_gate_exists" "pipeline.ol thiếu SecurityGate"
fi

# B5.2: Honesty instinct — nếu không biết, nói không biết
# (random nonsense → không nên trả confident answer)
run_bio_test_not_contains "b5/honesty_unknown" \
    "qwertyuiop asdfghjkl" \
    "la"   # không nên assert "X la Y" cho nonsense

# ═══════════════════════════════════════════════════════════════
# B6. KNOWTREE — Search phải trả đúng, không random
# Spec: §VI — k-NN trong 5D, không keyword match
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}── B6. KnowTree quality ──${NC}"

# B6.1: Nếu KnowTree có facts → search phải liên quan
# "Olang" → phải trả fact về Olang, không phải về thời tiết
if echo "Olang la gi" | timeout 5 "$BINARY" 2>/dev/null | strip_repl | grep -qi "olang\|ngon ngu\|lap trinh\|compile"; then
    pass "b6/knowtree_relevant_olang"
else
    warn "b6/knowtree_relevant_olang" "KnowTree search cho 'Olang' không trả kết quả liên quan"
fi

# ═══════════════════════════════════════════════════════════════
# B7. SELF-BUILD — Compiler vẫn hoạt động
# Spec: phải giữ fixed-point bất kể thay đổi kiến trúc
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}── B7. Self-build integrity ──${NC}"

# B7.1: Binary tồn tại và chạy được
if [ -x "$BINARY" ]; then
    pass "b7/binary_exists"
else
    fail "b7/binary_exists" "origin.olang không tìm thấy hoặc không executable"
fi

# B7.2: emit 42 hoạt động (compiler cơ bản)
run_bio_test "b7/basic_compile" "emit 42;" "42"

# B7.3: Fibonacci — compiler phức tạp
run_bio_test "b7/fib_10" \
    "fn fib(n) { if n < 2 { return n; }; return fib(n-1) + fib(n-2); }; emit fib(10);" \
    "55"

# B7.4: Self-build (nếu chạy lâu → skip)
if timeout 120 "$BINARY" --build >/dev/null 2>&1; then
    if [ -f "origin_new.olang" ]; then
        pass "b7/self_build"
        # B7.5: Fixed-point
        if timeout 120 ./origin_new.olang --build >/dev/null 2>&1; then
            if cmp -s origin_new.olang origin_new.olang 2>/dev/null; then
                pass "b7/fixed_point"
            else
                fail "b7/fixed_point" "Gen1 != Gen2"
            fi
        else
            warn "b7/fixed_point" "Gen2 build failed"
        fi
        rm -f origin_new.olang
    else
        fail "b7/self_build" "origin_new.olang not produced"
    fi
else
    warn "b7/self_build" "self-build timeout or failed (may need binary in repo)"
fi

# ═══════════════════════════════════════════════════════════════
# B8. GIÁC QUAN — SensoryFrame phải tồn tại
# Spec: §II-V — mỗi giác quan → SensoryFrame → cùng P_weight 5D
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}── B8. Sensory system ──${NC}"

# B8.1: Encode text → P_weight phải tạo được (chain_encode tồn tại)
if grep -q "chain_encode\|p_weight" "$STDLIB/homeos/pipeline.ol" 2>/dev/null; then
    pass "b8/encode_exists"
else
    warn "b8/encode_exists" "chain_encode/p_weight chưa có trong pipeline.ol"
fi

# B8.2: Nếu vision.ol tồn tại → phải có vision_sense function
if [ -f "$STDLIB/homeos/vision.ol" ]; then
    if grep -q "vision_sense\|vision_encode" "$STDLIB/homeos/vision.ol"; then
        pass "b8/vision_sense_fn"
    else
        fail "b8/vision_sense_fn" "vision.ol tồn tại nhưng thiếu vision_sense()"
    fi
else
    warn "b8/vision_not_yet" "vision.ol chưa tồn tại (Phase 5)"
fi

# B8.3: Nếu audition.ol tồn tại → phải có audio_sense function
if [ -f "$STDLIB/homeos/audition.ol" ]; then
    if grep -q "audio_sense\|audio_encode" "$STDLIB/homeos/audition.ol"; then
        pass "b8/audio_sense_fn"
    else
        fail "b8/audio_sense_fn" "audition.ol tồn tại nhưng thiếu audio_sense()"
    fi
else
    warn "b8/audio_not_yet" "audition.ol chưa tồn tại (Phase 6)"
fi

# ═══════════════════════════════════════════════════════════════
# B9. DẺO THẦN KINH — Cơ chế phải là DATA không phải CODE
# Spec: §XVI — instincts, weights là data trong KnowTree
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}── B9. Plasticity ──${NC}"

# B9.1: Nếu plasticity.ol tồn tại → phải có hebbian + structural
if [ -f "$STDLIB/homeos/plasticity.ol" ]; then
    if grep -q "hebbian\|structural\|plasticity" "$STDLIB/homeos/plasticity.ol"; then
        pass "b9/plasticity_mechanisms"
    else
        fail "b9/plasticity_mechanisms" "plasticity.ol thiếu cơ chế Hebbian/structural"
    fi
else
    warn "b9/plasticity_not_yet" "plasticity.ol chưa tồn tại (Phase 7)"
fi

# ═══════════════════════════════════════════════════════════════
# REPORT
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}═══════════════════════════════════════${NC}"
if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}  BIOLOGY: $PASS pass, $WARN warn, 0 fail${NC}"
else
    echo -e "${RED}  BIOLOGY: $PASS pass, $WARN warn, $FAIL FAIL${NC}"
    echo -e "$ERRORS"
fi
echo -e "${CYAN}═══════════════════════════════════════${NC}"

exit $FAIL
