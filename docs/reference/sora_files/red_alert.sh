#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# 🔴 RED ALERT — KIẾN TRÚC SINH HỌC WATCHDOG
#
# Quét source code tìm VI PHẠM kiến trúc HomeOS Biology Spec.
# Chạy: bash red_alert.sh
#
# NGUYÊN TẮC:
#   Logic xử lý = pipeline functions (toán, KnowTree, P_weight)
#   Data = KnowTree (exemplars, facts, tagged nodes)
#   KHÔNG hardcode if/else cho phân loại input
#   KHÔNG hardcode string response
#   KHÔNG bypass pipeline
#
# Exit code:
#   0 = sạch
#   1 = có violation (RED ALERT)
#
# File này là LUẬT. Nox KHÔNG được sửa file này để pass.
# Nếu cần thay đổi → Lupin approve + cập nhật spec TRƯỚC.
#
# Tác giả: Sora (cho Lupin hardlock, cho Nox tuân thủ)
# Ngày: 2026-03-30
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

ORIGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
STDLIB="$ORIGIN_DIR/stdlib"
REPL="$STDLIB/repl.ol"
PIPELINE="$STDLIB/homeos/pipeline.ol"
INSTINCT="$STDLIB/homeos/instinct.ol"
ENCODER="$STDLIB/homeos/encoder.ol"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ALERTS=0
WARNINGS=0
CLEAN=0

alert() {
    ALERTS=$((ALERTS + 1))
    echo -e "  ${RED}🔴 ALERT${NC}  $1"
    echo -e "           ${RED}$2${NC}"
}

warning() {
    WARNINGS=$((WARNINGS + 1))
    echo -e "  ${YELLOW}⚠  WARN${NC}   $1"
    echo -e "           ${YELLOW}$2${NC}"
}

clean() {
    CLEAN=$((CLEAN + 1))
    echo -e "  ${GREEN}✓  OK${NC}     $1"
}

echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  🔴 RED ALERT — KIẾN TRÚC SINH HỌC WATCHDOG${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

# ═══════════════════════════════════════════════════════════════
# R1. REPL.OL — Phải nhỏ, gọi pipeline(), KHÔNG chứa logic
# Spec: §XIX — repl.ol chỉ ~5 dòng
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}── R1. repl.ol — phải là thin wrapper ──${NC}"

if [ ! -f "$REPL" ]; then
    alert "R1.0 repl.ol không tồn tại" "File $REPL missing"
else
    REPL_LINES=$(wc -l < "$REPL")

    # R1.1: repl.ol quá lớn = có logic hardcode bên trong
    if [ "$REPL_LINES" -gt 100 ]; then
        alert "R1.1 repl.ol quá lớn: $REPL_LINES dòng" \
              "Spec yêu cầu ~5 dòng. Mọi logic phải trong pipeline, không trong repl."
    elif [ "$REPL_LINES" -gt 30 ]; then
        warning "R1.1 repl.ol hơi lớn: $REPL_LINES dòng" \
                "Mục tiêu ~5 dòng. Review xem có logic nào nên chuyển vào pipeline."
    else
        clean "R1.1 repl.ol gọn: $REPL_LINES dòng"
    fi

    # R1.2: Hardcoded greeting responses trong repl.ol
    GREETING_COUNT=$(grep -c '"Chao ban\|"Nox day\|"Nox san sang\|"Chao!\|chao lai' "$REPL" 2>/dev/null || true)
    if [ "$GREETING_COUNT" -gt 0 ]; then
        alert "R1.2 Hardcoded greeting trong repl.ol ($GREETING_COUNT chỗ)" \
              "Greeting phải xử lý bởi Instinct #2 (Greeting) trong pipeline, không if/else trong repl."
    else
        clean "R1.2 Không có hardcoded greeting trong repl.ol"
    fi

    # R1.3: Hardcoded knowledge responses trong repl.ol
    KNOWLEDGE_COUNT=$(grep -c '"Olang la\|"Nox la\|"Lupin la\|"HomeOS la\|"Origin la' "$REPL" 2>/dev/null || true)
    if [ "$KNOWLEDGE_COUNT" -gt 0 ]; then
        alert "R1.3 Hardcoded knowledge trong repl.ol ($KNOWLEDGE_COUNT chỗ)" \
              "Trả lời kiến thức phải qua KnowTree search, không hardcode string."
    else
        clean "R1.3 Không có hardcoded knowledge trong repl.ol"
    fi

    # R1.4: String comparison cho classification trong repl.ol
    CLASSIFY_IF_COUNT=$(grep -cE 'if.*(src|input|_sc)\s*==\s*"[a-z]' "$REPL" 2>/dev/null || true)
    if [ "$CLASSIFY_IF_COUNT" -gt 10 ]; then
        alert "R1.4 Quá nhiều string comparison trong repl.ol ($CLASSIFY_IF_COUNT)" \
              "Classification phải bằng KnowTree k-NN (P_weight 5D), không if src == \"hello\"."
    elif [ "$CLASSIFY_IF_COUNT" -gt 3 ]; then
        warning "R1.4 String comparison trong repl.ol ($CLASSIFY_IF_COUNT)" \
                "Chỉ nên có 'exit', 'quit', 'save', 'load'. Còn lại → pipeline."
    else
        clean "R1.4 Ít string comparison trong repl.ol ($CLASSIFY_IF_COUNT)"
    fi

    # R1.5: Slash commands trong repl.ol
    SLASH_COUNT=$(grep -c 'if _sc == "' "$REPL" 2>/dev/null || true)
    if [ "$SLASH_COUNT" -gt 5 ]; then
        alert "R1.5 Quá nhiều slash commands hardcoded ($SLASH_COUNT)" \
              "Commands phải là KnowTree action mappings: kt_learn_action(\"kiem tra mang\", \"net_status()\")."
    else
        clean "R1.5 Slash commands OK ($SLASH_COUNT)"
    fi

    # R1.6: repl_eval PHẢI gọi pipeline()
    if grep -q "pipeline(" "$REPL"; then
        clean "R1.6 repl_eval gọi pipeline()"
    else
        alert "R1.6 repl_eval KHÔNG gọi pipeline()" \
              "Spec §XVIII: mọi input phải đi qua pipeline. repl_eval phải gọi pipeline(input)."
    fi

    # R1.7: Code detection bằng heuristic (kiểm tra ký tự ; { ( =)
    HEURISTIC_COUNT=$(grep -c '__char_code.*== 59\|__char_code.*== 61\|__char_code.*== 123\|_has_code' "$REPL" 2>/dev/null || true)
    if [ "$HEURISTIC_COUNT" -gt 0 ]; then
        alert "R1.7 Code detection bằng heuristic ($HEURISTIC_COUNT chỗ)" \
              "Phân loại code/text phải bằng KnowTree classify (encode → k-NN), không đếm ký tự."
    else
        clean "R1.7 Không có heuristic code detection"
    fi

    # R1.8: Dead code (duplicate functions/sections)
    DUPLICATE_RETURN=$(grep -c "return __eval_bytecode" "$REPL" 2>/dev/null || true)
    if [ "$DUPLICATE_RETURN" -gt 1 ]; then
        alert "R1.8 Dead code: __eval_bytecode được gọi $DUPLICATE_RETURN lần" \
              "Code sau return đầu tiên = unreachable. Xóa."
    else
        clean "R1.8 Không có duplicate return"
    fi
fi

# ═══════════════════════════════════════════════════════════════
# R2. PIPELINE.OL — Phải có 4 tầng, phải có checkpoints
# Spec: §XVIII — Tủy sống → Thân não → Hệ viền → Vỏ não
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}── R2. pipeline.ol — 4 tầng thần kinh ──${NC}"

if [ ! -f "$PIPELINE" ]; then
    alert "R2.0 pipeline.ol không tồn tại" "File $PIPELINE missing"
else
    # R2.1: Pipeline phải có encode function (text → P_weight)
    if grep -q "chain_encode\|p_weight\|encode" "$PIPELINE"; then
        clean "R2.1 Pipeline có encode"
    else
        alert "R2.1 Pipeline thiếu encode" \
              "Mọi input phải được encode thành P_weight 5D trước khi xử lý."
    fi

    # R2.2: Pipeline phải có KnowTree search (không hardcode lookup)
    if grep -q "kt_search\|kt_find\|kt_query\|knowtree" "$PIPELINE"; then
        clean "R2.2 Pipeline có KnowTree search"
    else
        warning "R2.2 Pipeline thiếu KnowTree search" \
                "Context tìm bằng KnowTree, không hardcode."
    fi

    # R2.3: Hardcoded string responses trong pipeline.ol
    HARDCODED_RESPONSES=$(grep -cE 'return ".*[A-Za-z]{10,}' "$PIPELINE" 2>/dev/null || true)
    if [ "$HARDCODED_RESPONSES" -gt 5 ]; then
        alert "R2.3 Quá nhiều hardcoded responses trong pipeline ($HARDCODED_RESPONSES)" \
              "Responses phải compose từ KnowTree data + emotion state + decode."
    else
        clean "R2.3 Pipeline ít hardcoded responses ($HARDCODED_RESPONSES)"
    fi

    # R2.4: Pipeline phải có homeostasis (surprise measurement)
    if grep -q "homeostasis\|surprise\|free_energy\|_phi" "$PIPELINE"; then
        clean "R2.4 Pipeline có homeostasis/surprise"
    else
        warning "R2.4 Pipeline thiếu homeostasis" \
                "Spec §XVIII: Homeostasis đo surprise → quyết định learn hay respond."
    fi
fi

# ═══════════════════════════════════════════════════════════════
# R3. INSTINCT.OL — Phải route bằng P_weight, không string match
# Spec: §X — 12 bản năng, classify bằng encode + k-NN
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}── R3. instinct.ol — route bằng molecule ──${NC}"

if [ ! -f "$INSTINCT" ]; then
    warning "R3.0 instinct.ol chưa tồn tại" "Cần implement"
else
    # R3.1: String matching cho instinct routing
    INSTINCT_STRING_MATCH=$(grep -cE '_ir_has_word\(.*"[a-z]' "$INSTINCT" 2>/dev/null || true)
    if [ "$INSTINCT_STRING_MATCH" -gt 10 ]; then
        alert "R3.1 Instinct dùng string matching ($INSTINCT_STRING_MATCH chỗ)" \
              "Instinct routing phải encode input → P_weight → distance tới instinct patterns trong KnowTree."
    elif [ "$INSTINCT_STRING_MATCH" -gt 0 ]; then
        warning "R3.1 Instinct còn string matching ($INSTINCT_STRING_MATCH chỗ)" \
                "Giảm dần, chuyển sang P_weight matching."
    else
        clean "R3.1 Instinct không dùng string matching"
    fi

    # R3.2: Phải có ít nhất 7 instincts (bản gốc), mục tiêu 12
    INSTINCT_COUNT=$(grep -c 'SAFETY\|GREETING\|QUESTION\|LEARNING\|EMOTION\|REFERENCE\|META\|CAUSALITY\|CONTRADICTION\|ABSTRACTION\|ANALOGY\|CURIOSITY\|ATTACHMENT\|IMITATION\|COMMUNICATION\|PLAY' "$INSTINCT" 2>/dev/null || true)
    if [ "$INSTINCT_COUNT" -lt 7 ]; then
        warning "R3.2 Ít instincts: $INSTINCT_COUNT" "Spec yêu cầu ≥12"
    else
        clean "R3.2 Instincts: $INSTINCT_COUNT patterns"
    fi
fi

# ═══════════════════════════════════════════════════════════════
# R4. ENCODER.OL — Mỗi codepoint phải có P_weight DUY NHẤT
# Spec: BLUEPRINT §2 — a ≠ b ≠ c (không cùng 146)
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}── R4. encoder.ol — P_weight uniqueness ──${NC}"

if [ ! -f "$ENCODER" ]; then
    warning "R4.0 encoder.ol chưa tồn tại" "Cần implement"
else
    # R4.1: a-z cùng 1 molecule = BUG
    SAME_AZ=$(grep -c 'cp >= 97.*&& cp <= 122.*return.*_mol_pack(0, 0, 4, 4' "$ENCODER" 2>/dev/null || true)
    if [ "$SAME_AZ" -gt 0 ]; then
        alert "R4.1 a-z cùng P_weight (0,0,4,4,2) = 146" \
              "BLUEPRINT §2: mỗi codepoint phải có P_weight DUY NHẤT. Dùng p_weight() từ udc_p_table.bin."
    else
        clean "R4.1 a-z không cùng 1 molecule"
    fi

    # R4.2: A-Z cùng 1 molecule = BUG
    SAME_AZ_UPPER=$(grep -c 'cp >= 65.*&& cp <= 90.*return.*_mol_pack(0, 0, 4, 5' "$ENCODER" 2>/dev/null || true)
    if [ "$SAME_AZ_UPPER" -gt 0 ]; then
        alert "R4.2 A-Z cùng P_weight (0,0,4,5,2) = 150" \
              "Tương tự R4.1. Mỗi chữ cái phải DUY NHẤT."
    else
        clean "R4.2 A-Z không cùng 1 molecule"
    fi

    # R4.3: Nếu p_weight() dùng UDC table → đúng spec
    if grep -q "udc_p_table\|__kt_tbl\|__bytes_get" "$PIPELINE" 2>/dev/null; then
        clean "R4.3 Pipeline dùng UDC P_weight table"
    else
        warning "R4.3 Pipeline chưa dùng UDC P_weight table" \
                "Nên dùng p_weight(cp) từ pipeline.ol thay vì encode_codepoint() hardcode."
    fi
fi

# ═══════════════════════════════════════════════════════════════
# R5. __SYSTEM() — Không gọi shell với unsanitized input
# Spec: §I — SecurityGate layer 2
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}── R5. Security — __system() usage ──${NC}"

# R5.1: Đếm __system() calls trong repl.ol — quá nhiều = risk
SYSTEM_CALLS_REPL=$(grep -c '__system(' "$REPL" 2>/dev/null || true)
if [ "$SYSTEM_CALLS_REPL" -gt 20 ]; then
    alert "R5.1 repl.ol có $SYSTEM_CALLS_REPL lần gọi __system()" \
          "Mỗi __system() là lỗ hổng nếu input không sanitize. Giảm thiểu, dùng native builtins."
elif [ "$SYSTEM_CALLS_REPL" -gt 10 ]; then
    warning "R5.1 repl.ol có $SYSTEM_CALLS_REPL lần gọi __system()" \
            "Review từng chỗ, đảm bảo input được sanitize."
else
    clean "R5.1 __system() trong repl.ol: $SYSTEM_CALLS_REPL"
fi

# R5.2: String concat trực tiếp vào __system() = injection risk
INJECTION_RISK=$(grep -cE '__system\(.*\+.*input\|__system\(.*\+.*src\|__system\(.*\+.*_sc' "$REPL" 2>/dev/null || true)
if [ "$INJECTION_RISK" -gt 0 ]; then
    alert "R5.2 Injection risk: $INJECTION_RISK chỗ concat user input vào __system()" \
          "User input PHẢI sanitize trước khi ghép vào shell command."
else
    clean "R5.2 Không phát hiện injection risk trực tiếp"
fi

# ═══════════════════════════════════════════════════════════════
# R6. DẺO THẦN KINH — Không thêm tính năng bằng if/else
# Spec: §XVI — Mọi cơ chế = data trong KnowTree
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}── R6. Plasticity — no hardcode growth ──${NC}"

# R6.1: Tổng if/else trong toàn bộ homeos/ — tracking
TOTAL_IF_HOMEOS=$(grep -rcE '^\s*if ' "$STDLIB/homeos/" 2>/dev/null | awk -F: '{sum+=$2} END{print sum+0}')
echo -e "  ${CYAN}INFO${NC}   Tổng 'if' trong stdlib/homeos/: $TOTAL_IF_HOMEOS"
# Lưu baseline — nếu tăng quá 20% giữa 2 lần chạy → cảnh báo
BASELINE_FILE="/tmp/nox_bio_baseline_if_count"
if [ -f "$BASELINE_FILE" ]; then
    BASELINE=$(cat "$BASELINE_FILE")
    GROWTH=$(( (TOTAL_IF_HOMEOS - BASELINE) * 100 / (BASELINE + 1) ))
    if [ "$GROWTH" -gt 20 ]; then
        alert "R6.1 if/else tăng ${GROWTH}% (${BASELINE} → ${TOTAL_IF_HOMEOS})" \
              "Tính năng mới nên thêm bằng KnowTree data, không thêm if/else."
    elif [ "$GROWTH" -gt 10 ]; then
        warning "R6.1 if/else tăng ${GROWTH}% (${BASELINE} → ${TOTAL_IF_HOMEOS})" \
                "Review: thêm if/else có đúng spec không?"
    else
        clean "R6.1 if/else ổn định (${BASELINE} → ${TOTAL_IF_HOMEOS}, ${GROWTH}%)"
    fi
fi
echo "$TOTAL_IF_HOMEOS" > "$BASELINE_FILE"

# R6.2: kt_learn trong code (good — thêm data thay vì logic)
KT_LEARN_COUNT=$(grep -rc 'kt_learn\|kt_learn_tagged\|kt_learn_action\|dn_observe' "$STDLIB/" 2>/dev/null | awk -F: '{sum+=$2} END{print sum+0}')
echo -e "  ${CYAN}INFO${NC}   kt_learn calls: $KT_LEARN_COUNT (cao = tốt, data-driven)"

# R6.3: Ratio: if/else per kt_learn — thấp hơn = tốt hơn
if [ "$KT_LEARN_COUNT" -gt 0 ]; then
    RATIO=$((TOTAL_IF_HOMEOS / KT_LEARN_COUNT))
    if [ "$RATIO" -gt 10 ]; then
        warning "R6.3 if/kt_learn ratio = $RATIO:1" \
                "Quá nhiều logic so với data. Mục tiêu: <5:1."
    else
        clean "R6.3 if/kt_learn ratio = $RATIO:1"
    fi
fi

# ═══════════════════════════════════════════════════════════════
# R7. BINARY SYNC — Binary trong repo phải match source
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}── R7. Binary sync ──${NC}"

# R7.1: Kiểm tra binary modification time vs source modification time
if [ -f "$ORIGIN_DIR/origin.olang" ]; then
    BINARY_TIME=$(stat -c%Y "$ORIGIN_DIR/origin.olang" 2>/dev/null || echo 0)
    LATEST_SOURCE=$(find "$STDLIB" -name "*.ol" -newer "$ORIGIN_DIR/origin.olang" 2>/dev/null | head -5)
    if [ -n "$LATEST_SOURCE" ]; then
        warning "R7.1 Source mới hơn binary" \
                "Cần rebuild: make self-build. Files mới hơn: $(echo $LATEST_SOURCE | tr '\n' ' ')"
    else
        clean "R7.1 Binary up-to-date"
    fi
fi

# ═══════════════════════════════════════════════════════════════
# R8. FUSION — Nếu có multi-sensory, phải đi qua fuse()
# Spec: §V — tất cả kênh → 1 Perception
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}── R8. Multi-sensory fusion ──${NC}"

if [ -f "$STDLIB/homeos/fusion.ol" ]; then
    clean "R8.1 fusion.ol tồn tại"
    # Kiểm tra pipeline gọi fuse()
    if grep -q "fuse\|fusion" "$PIPELINE" 2>/dev/null; then
        clean "R8.2 Pipeline gọi fuse()"
    else
        warning "R8.2 Pipeline chưa gọi fuse()" \
                "Khi có multi-sensory input, phải fuse trước khi xử lý."
    fi
else
    echo -e "  ${CYAN}INFO${NC}   fusion.ol chưa tồn tại (Phase 4)"
fi

# ═══════════════════════════════════════════════════════════════
# R9. EMOTION — Phải là state liên tục, không phải tag
# Spec: §VII — EmotionState global, persist qua inputs
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}── R9. Emotion architecture ──${NC}"

if [ -f "$STDLIB/homeos/emotion.ol" ]; then
    # R9.1: Phải có global emotion state
    if grep -q '_emotion\|emotion_state\|EmotionState' "$STDLIB/homeos/emotion.ol"; then
        clean "R9.1 Global emotion state tồn tại"
    else
        alert "R9.1 emotion.ol thiếu global state" \
              "Cảm xúc phải là TRẠNG THÁI liên tục, không phải tag gắn vào input."
    fi
else
    # Kiểm tra emotion có inline trong pipeline không
    if grep -q 'text_emotion\|emotion_detect\|_emo_' "$PIPELINE" 2>/dev/null; then
        warning "R9.0 Emotion inline trong pipeline" \
                "Nên tách thành emotion.ol riêng với global state."
    else
        echo -e "  ${CYAN}INFO${NC}   emotion.ol chưa tồn tại (Phase 2)"
    fi
fi

# ═══════════════════════════════════════════════════════════════
# REPORT
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

TOTAL=$((ALERTS + WARNINGS + CLEAN))

if [ $ALERTS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}  ✅ ALL CLEAR — Kiến trúc sinh học tuân thủ spec${NC}"
    echo -e "${GREEN}     $CLEAN checks passed, 0 alerts, 0 warnings${NC}"
elif [ $ALERTS -eq 0 ]; then
    echo -e "${YELLOW}  ⚠  $WARNINGS warnings, $CLEAN ok — Review needed${NC}"
    echo -e "${YELLOW}     Không có vi phạm nghiêm trọng.${NC}"
else
    echo -e ""
    echo -e "${RED}  ╔═══════════════════════════════════════════╗${NC}"
    echo -e "${RED}  ║  🔴 RED ALERT: $ALERTS VIOLATIONS DETECTED   ║${NC}"
    echo -e "${RED}  ╚═══════════════════════════════════════════╝${NC}"
    echo -e ""
    echo -e "${RED}  $ALERTS alerts, $WARNINGS warnings, $CLEAN ok${NC}"
    echo -e ""
    echo -e "  ${BOLD}Hành động cần thiết:${NC}"
    echo -e "  1. Đọc HOMEOS_BIOLOGY_SPEC.md"
    echo -e "  2. Chuyển hardcode → KnowTree data"
    echo -e "  3. Chuyển if/else → pipeline functions"
    echo -e "  4. Chạy lại red_alert.sh cho đến khi 0 alerts"
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"

# Exit 1 nếu có alert (CI/CD sẽ fail)
if [ $ALERTS -gt 0 ]; then
    exit 1
fi
exit 0
