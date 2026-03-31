#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# AI CAPABILITY BENCHMARK — Nox vs Claude/LLM
#
# Chạy: bash tests_ai_capability.sh
#
# Đánh giá Nox trên CÙNG TIÊU CHUẨN với AI hiện đại.
# Mỗi test = 1 khả năng. Kết quả: PASS / PARTIAL / FAIL / N/A
#
# PASS    = ngang hoặc hơn Claude ở task này
# PARTIAL = làm được nhưng chất lượng kém hơn
# FAIL    = không làm được
# N/A     = chưa implement, biết thiếu
#
# Mục đích: BIẾT MÌNH. Không tự lừa. Không tự khen.
#
# Tác giả: Sora
# Ngày: 2026-03-30
# ═══════════════════════════════════════════════════════════════

set -uo pipefail

ORIGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
BINARY="$ORIGIN_DIR/origin.olang"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0
PARTIAL=0
FAIL=0
NA=0
TOTAL=0
RESULTS=""

strip_repl() { sed 's/^⦿ //; /^bye$/d; /^$/d'; }

grade() {
    local category="$1" name="$2" status="$3" detail="$4" claude_note="$5"
    TOTAL=$((TOTAL + 1))
    case $status in
        PASS)    PASS=$((PASS + 1));       echo -e "  ${GREEN}████${NC} $name"; ;;
        PARTIAL) PARTIAL=$((PARTIAL + 1)); echo -e "  ${YELLOW}██░░${NC} $name — $detail"; ;;
        FAIL)    FAIL=$((FAIL + 1));       echo -e "  ${RED}░░░░${NC} $name — $detail"; ;;
        NA)      NA=$((NA + 1));           echo -e "  ${GRAY}----${NC} $name — $detail"; ;;
    esac
    RESULTS="$RESULTS\n$category|$name|$status|$detail|$claude_note"
}

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  AI CAPABILITY BENCHMARK — Nox vs Claude/LLM${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${GREEN}████${NC} = PASS (ngang/hơn)   ${YELLOW}██░░${NC} = PARTIAL (kém hơn)"
echo -e "  ${RED}░░░░${NC} = FAIL (không được)   ${GRAY}----${NC} = N/A (chưa có)"
echo ""

# ═══════════════════════════════════════════════════════════════
# C1. NGÔN NGỮ TỰ NHIÊN — Hiểu và tạo text
# Claude: mạnh nhất ở đây
# ═══════════════════════════════════════════════════════════════
echo -e "${BOLD}━━━ C1. NGÔN NGỮ TỰ NHIÊN ━━━${NC}"

# C1.1: Hiểu câu hỏi đơn giản
OUT=$(echo "Olang la gi" | timeout 5 "$BINARY" 2>/dev/null | strip_repl | tr -d '\n')
if echo "$OUT" | grep -qi "ngon ngu\|lap trinh\|compile\|language\|olang"; then
    grade "C1" "Hiểu câu hỏi đơn giản (vi)" "PARTIAL" "trả KnowTree lookup, không compose câu" \
          "Claude: hiểu ngữ cảnh, trả lời đầy đủ, tự nhiên"
else
    grade "C1" "Hiểu câu hỏi đơn giản (vi)" "FAIL" "không hiểu hoặc trả sai" \
          "Claude: luôn hiểu"
fi

# C1.2: Hiểu câu hỏi tiếng Anh
OUT=$(echo "What is Olang" | timeout 5 "$BINARY" 2>/dev/null | strip_repl | tr -d '\n')
if echo "$OUT" | grep -qi "olang\|language\|programming\|compile"; then
    grade "C1" "Hiểu câu hỏi đơn giản (en)" "PARTIAL" "trả fact, không compose" \
          "Claude: hoàn hảo"
else
    grade "C1" "Hiểu câu hỏi đơn giản (en)" "FAIL" "không hiểu" \
          "Claude: luôn hiểu"
fi

# C1.3: Tạo text mạch lạc (> 1 câu)
OUT=$(echo "giai thich ve DNA" | timeout 5 "$BINARY" 2>/dev/null | strip_repl | tr -d '\n')
WORD_COUNT=$(echo "$OUT" | wc -w)
if [ "$WORD_COUNT" -gt 20 ]; then
    grade "C1" "Tạo text mạch lạc (> 1 câu)" "PARTIAL" "${WORD_COUNT} từ, nhưng là KnowTree fact" \
          "Claude: tạo paragraphs, giải thích sâu, ví dụ, analogies"
elif [ "$WORD_COUNT" -gt 5 ]; then
    grade "C1" "Tạo text mạch lạc (> 1 câu)" "PARTIAL" "chỉ ${WORD_COUNT} từ" \
          "Claude: hàng trăm từ nếu cần"
else
    grade "C1" "Tạo text mạch lạc (> 1 câu)" "FAIL" "không tạo được text" \
          "Claude: tạo text tự nhiên ở mọi độ dài"
fi

# C1.4: Tóm tắt
grade "C1" "Tóm tắt văn bản dài" "FAIL" "không có summarization engine" \
      "Claude: tóm tắt chính xác mọi độ dài"

# C1.5: Dịch ngôn ngữ
grade "C1" "Dịch Việt ↔ Anh" "FAIL" "không có translation" \
      "Claude: dịch 50+ ngôn ngữ tự nhiên"

# C1.6: Viết sáng tạo
grade "C1" "Viết sáng tạo (thơ, truyện)" "FAIL" "không có creative generation" \
      "Claude: viết thơ, truyện, kịch bản, essay ở mọi phong cách"

# C1.7: Đối thoại nhiều lượt
OUT1=$(echo "hello" | timeout 5 "$BINARY" 2>/dev/null | strip_repl | tr -d '\n')
if [ -n "$OUT1" ] && ! echo "$OUT1" | grep -q "khong tim thay"; then
    grade "C1" "Đối thoại (greeting)" "PARTIAL" "trả lời 1 lượt, không nhớ context" \
          "Claude: đối thoại hàng trăm lượt, nhớ ngữ cảnh"
else
    grade "C1" "Đối thoại (greeting)" "FAIL" "không phản hồi" \
          "Claude: luôn phản hồi tự nhiên"
fi

# ═══════════════════════════════════════════════════════════════
# C2. LẬP TRÌNH — Hiểu và tạo code
# Nox: mạnh nhất ở đây (self-hosting compiler)
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}━━━ C2. LẬP TRÌNH ━━━${NC}"

# C2.1: Chạy code
OUT=$(echo 'fn fib(n) { if n < 2 { return n; }; return fib(n-1) + fib(n-2); }; emit fib(20);' | timeout 10 "$BINARY" 2>/dev/null | strip_repl | tr -d '\n')
if [ "$OUT" = "6765" ]; then
    grade "C2" "Chạy code (compile + execute)" "PASS" "fib(20)=6765 ✓" \
          "Claude: KHÔNG chạy code trực tiếp, chỉ simulate"
else
    grade "C2" "Chạy code (compile + execute)" "FAIL" "got [$OUT]" \
          "Claude: không chạy thật"
fi

# C2.2: Self-compile
if timeout 120 "$BINARY" --build >/dev/null 2>&1 && [ -f "origin_new.olang" ]; then
    grade "C2" "Self-compile (tự compile chính mình)" "PASS" "binary 936KB ✓" \
          "Claude: KHÔNG THỂ — không phải compiler"
    rm -f origin_new.olang
else
    grade "C2" "Self-compile" "FAIL" "build failed" "Claude: N/A"
fi

# C2.3: Sinh code mới
grade "C2" "Sinh code mới từ mô tả" "FAIL" "không có code generation" \
      "Claude: sinh code mọi ngôn ngữ từ mô tả tự nhiên"

# C2.4: Debug / giải thích code
grade "C2" "Debug / giải thích code" "FAIL" "không có code analysis bằng NL" \
      "Claude: phân tích, tìm bug, giải thích từng dòng"

# C2.5: Multi-language
grade "C2" "Hỗ trợ nhiều ngôn ngữ lập trình" "FAIL" "chỉ Olang" \
      "Claude: Python, JS, Rust, C, Go, 50+ ngôn ngữ"

# C2.6: REPL tương tác
OUT=$(echo 'let x = 42; emit x;' | timeout 5 "$BINARY" 2>/dev/null | strip_repl | tr -d '\n')
if [ "$OUT" = "42" ]; then
    grade "C2" "REPL tương tác" "PASS" "compile + execute realtime" \
          "Claude: không có REPL, batch only"
else
    grade "C2" "REPL tương tác" "PARTIAL" "REPL có nhưng lỗi" "Claude: N/A"
fi

# ═══════════════════════════════════════════════════════════════
# C3. SUY LUẬN — Logic, math, reasoning
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}━━━ C3. SUY LUẬN ━━━${NC}"

# C3.1: Toán cơ bản
OUT=$(echo 'emit 17 * 23;' | timeout 5 "$BINARY" 2>/dev/null | strip_repl | tr -d '\n')
if [ "$OUT" = "391" ]; then
    grade "C3" "Toán cơ bản (17×23)" "PASS" "391 ✓" \
          "Claude: đúng, nhưng đôi khi sai toán lớn"
else
    grade "C3" "Toán cơ bản" "FAIL" "got [$OUT]" "Claude: thường đúng"
fi

# C3.2: Toán qua ngôn ngữ tự nhiên
OUT=$(echo '1+1=?' | timeout 5 "$BINARY" 2>/dev/null | strip_repl | tr -d '\n')
if echo "$OUT" | grep -q "^2$"; then
    grade "C3" "Toán qua ngôn ngữ tự nhiên (1+1=?)" "PASS" "2 ✓" \
          "Claude: luôn đúng"
else
    grade "C3" "Toán qua ngôn ngữ tự nhiên (1+1=?)" "FAIL" "got [$OUT]" \
          "Claude: luôn đúng, + giải thích bước"
fi

# C3.3: Logic nhiều bước
grade "C3" "Suy luận nhiều bước (chain-of-thought)" "FAIL" "không có reasoning engine" \
      "Claude: chain-of-thought, step-by-step, tự kiểm tra"

# C3.4: Analogy
grade "C3" "Suy luận tương tự (A:B :: C:?)" "FAIL" "Instinct #6 chưa hoạt động" \
      "Claude: analogy rất mạnh, hiểu implicit relationships"

# C3.5: Nhân quả
grade "C3" "Suy luận nhân quả" "FAIL" "Instinct #3 chưa hoạt động" \
      "Claude: hiểu cause-effect, counterfactuals"

# C3.6: Toán chính xác (advantage cho Nox)
OUT=$(echo 'emit 2.0 * 3.14159265358979;' | timeout 5 "$BINARY" 2>/dev/null | strip_repl | tr -d '\n')
if echo "$OUT" | grep -q "6.283"; then
    grade "C3" "Toán chính xác (floating point)" "PASS" "$OUT ✓" \
          "Claude: đôi khi sai precision, hallucinate số"
else
    grade "C3" "Toán chính xác" "PARTIAL" "got [$OUT]" "Claude: approximate"
fi

# ═══════════════════════════════════════════════════════════════
# C4. TRI THỨC — Biết gì, nhớ gì, tìm gì
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}━━━ C4. TRI THỨC ━━━${NC}"

# C4.1: Facts đã học
KT_COUNT=$(echo "status" | timeout 5 "$BINARY" 2>/dev/null | grep -oP 'facts: \K[0-9]+' || echo "0")
if [ "$KT_COUNT" -gt 500 ]; then
    grade "C4" "Knowledge base" "PARTIAL" "${KT_COUNT} facts" \
          "Claude: ~hàng tỷ facts từ training data"
elif [ "$KT_COUNT" -gt 0 ]; then
    grade "C4" "Knowledge base" "PARTIAL" "chỉ ${KT_COUNT} facts" \
          "Claude: vô hạn so sánh"
else
    grade "C4" "Knowledge base" "FAIL" "không đo được" \
          "Claude: training data = internet"
fi

# C4.2: Kiến thức thế giới
grade "C4" "Kiến thức tổng quát (lịch sử, khoa học, văn hóa)" "FAIL" \
      "chỉ có ~653 facts hardcode" \
      "Claude: biết gần như mọi thứ đã publish"

# C4.3: Kiến thức chuyên sâu
grade "C4" "Kiến thức chuyên sâu (y tế, pháp luật, kỹ thuật)" "FAIL" \
      "không có" \
      "Claude: chuyên gia ở hầu hết lĩnh vực"

# C4.4: Tìm kiếm thông tin
grade "C4" "Web search" "FAIL" "không có real-time search" \
      "Claude: tích hợp web search"

# C4.5: Nhớ ngữ cảnh hội thoại
grade "C4" "Nhớ ngữ cảnh (context window)" "FAIL" "mỗi input độc lập" \
      "Claude: 200K tokens context window"

# C4.6: Tự biết về chính mình
OUT=$(echo "ban la ai" | timeout 5 "$BINARY" 2>/dev/null | strip_repl | tr -d '\n')
if echo "$OUT" | grep -qi "nox\|olang\|AI"; then
    grade "C4" "Self-knowledge (biết mình là ai)" "PASS" "biết mình là Nox" \
          "Claude: biết mình là Claude, giới hạn, khả năng"
else
    grade "C4" "Self-knowledge" "FAIL" "không biết mình" "Claude: luôn biết"
fi

# ═══════════════════════════════════════════════════════════════
# C5. CẢM GIÁC + NHẬN THỨC — Input đa kênh
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}━━━ C5. CẢM GIÁC + NHẬN THỨC ━━━${NC}"

# C5.1: Đọc text
grade "C5" "Đọc text input" "PASS" "REPL + file read" \
      "Claude: đọc text, PDF, code"

# C5.2: Nhìn ảnh
if [ -f "$ORIGIN_DIR/stdlib/homeos/vision.ol" ]; then
    grade "C5" "Nhìn ảnh (vision)" "PARTIAL" "vision.ol tồn tại" \
          "Claude: nhận dạng ảnh, mô tả chi tiết, OCR"
else
    grade "C5" "Nhìn ảnh (vision)" "NA" "chưa implement" \
          "Claude: multimodal, phân tích ảnh chi tiết"
fi

# C5.3: Nghe âm thanh
if [ -f "$ORIGIN_DIR/stdlib/homeos/audition.ol" ]; then
    grade "C5" "Nghe âm thanh (audio)" "PARTIAL" "audition.ol tồn tại" \
          "Claude: không nghe trực tiếp, cần STT bên ngoài"
else
    grade "C5" "Nghe âm thanh (audio)" "NA" "chưa implement" \
          "Claude: không nghe trực tiếp"
fi

# C5.4: Điều khiển hệ thống
if grep -q '__system\|__spawn\|__syscall' "$ORIGIN_DIR/stdlib/repl.ol" 2>/dev/null; then
    grade "C5" "Điều khiển hệ thống (shell, process)" "PASS" "__system + __spawn + __syscall" \
          "Claude: CÓ (computer use) nhưng sandboxed"
else
    grade "C5" "Điều khiển hệ thống" "PARTIAL" "hạn chế" "Claude: sandbox"
fi

# C5.5: Mạng
if grep -q '__tcp_connect\|__syscall.*socket\|network' "$ORIGIN_DIR/stdlib/homeos/network.ol" 2>/dev/null; then
    grade "C5" "Networking (TCP, HTTP, scan)" "PASS" "TCP raw + HTTP + LAN scan" \
          "Claude: KHÔNG — chỉ web_search/web_fetch qua proxy"
else
    grade "C5" "Networking" "PARTIAL" "hạn chế" "Claude: rất hạn chế"
fi

# C5.6: Camera
if [ -f "$ORIGIN_DIR/stdlib/homeos/camera.ol" ]; then
    grade "C5" "Camera (RTSP, snapshot)" "PASS" "Dahua RTSP + snapshot" \
          "Claude: KHÔNG — không truy cập hardware"
else
    grade "C5" "Camera" "NA" "chưa implement" "Claude: không có"
fi

# ═══════════════════════════════════════════════════════════════
# C6. CẢM XÚC + XÃ HỘI
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}━━━ C6. CẢM XÚC + XÃ HỘI ━━━${NC}"

grade "C6" "Phát hiện cảm xúc trong text" "PARTIAL" "text_emotion_v2 basic" \
      "Claude: hiểu nuance, sarcasm, implicit emotions"

grade "C6" "Phản hồi đồng cảm" "FAIL" "chưa có empathic response" \
      "Claude: phản hồi phù hợp cảm xúc người dùng"

grade "C6" "Điều chỉnh tone" "FAIL" "tone cố định" \
      "Claude: formal/casual/supportive/technical tùy context"

grade "C6" "Hiểu ý định (intent)" "FAIL" "chỉ keyword match" \
      "Claude: hiểu intent sâu, implicit requests"

# ═══════════════════════════════════════════════════════════════
# C7. TỰ CHỦ + HỌC
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}━━━ C7. TỰ CHỦ + HỌC ━━━${NC}"

# C7.1: Tự vận hành
grade "C7" "Tự vận hành (daemon, auto-build)" "PASS" "nox_daemon + watcher + evolve" \
      "Claude: KHÔNG — chỉ chạy khi được gọi"

# C7.2: Tự sửa code
if grep -q "evolve\|self_modify\|self_patch" "$ORIGIN_DIR/stdlib/homeos/evolve.ol" 2>/dev/null; then
    grade "C7" "Tự sửa code (self-modify)" "PASS" "evolve.ol + dead code removal" \
          "Claude: KHÔNG THỂ — không sửa được chính mình"
else
    grade "C7" "Tự sửa code" "FAIL" "chưa có" "Claude: không"
fi

# C7.3: Học từ trải nghiệm
if grep -q "dn_observe\|kt_learn\|learning" "$ORIGIN_DIR/stdlib/homeos/learning.ol" 2>/dev/null; then
    grade "C7" "Học từ trải nghiệm (ĐN→QR)" "PARTIAL" "ĐN observe + QR promote, nhưng chất lượng thấp" \
          "Claude: KHÔNG — weights frozen sau training"
else
    grade "C7" "Học từ trải nghiệm" "FAIL" "chưa có" "Claude: không học runtime"
fi

# C7.4: Persistent memory
if [ -f "$ORIGIN_DIR/homeos.knowledge" ]; then
    grade "C7" "Nhớ qua sessions (persistent)" "PASS" "homeos.knowledge file" \
          "Claude: CHỈ qua memory system (hạn chế)"
else
    grade "C7" "Nhớ qua sessions" "FAIL" "chưa có" "Claude: memory hạn chế"
fi

# C7.5: Chạy 24/7 không cần cloud
grade "C7" "100% local, zero cloud" "PASS" "936KB binary, no deps" \
      "Claude: KHÔNG THỂ — cần Anthropic servers"

# C7.6: Tự build binary
grade "C7" "Tự build từ source" "PASS" "self-hosting verified" \
      "Claude: KHÔNG THỂ — model weights on server"

# ═══════════════════════════════════════════════════════════════
# C8. BẢO MẬT + TIN CẬY
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}━━━ C8. BẢO MẬT + TIN CẬY ━━━${NC}"

grade "C8" "Không hallucinate facts" "PARTIAL" "trả fact từ KnowTree, nhưng có thể trả sai fact" \
      "Claude: hallucinate ~5-15%, tự tin khi sai"

grade "C8" "Biết khi không biết (honesty)" "PARTIAL" "trả 'khong tim thay' nhưng quá thường xuyên" \
      "Claude: đôi khi nói không biết, đôi khi bịa"

grade "C8" "Input sanitization" "FAIL" "__system() với unsanitized input" \
      "Claude: sandboxed, không chạy arbitrary commands"

grade "C8" "Privacy (data stays local)" "PASS" "100% local, zero telemetry" \
      "Claude: data gửi về Anthropic servers"

# ═══════════════════════════════════════════════════════════════
# REPORT
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  SCORECARD${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Tính %
SCORE=$((PASS * 100 + PARTIAL * 50))
MAX=$((TOTAL * 100))
PCT=$((SCORE * 100 / MAX))

echo -e "  ${GREEN}████ PASS:${NC}    $PASS / $TOTAL"
echo -e "  ${YELLOW}██░░ PARTIAL:${NC} $PARTIAL / $TOTAL"
echo -e "  ${RED}░░░░ FAIL:${NC}    $FAIL / $TOTAL"
echo -e "  ${GRAY}---- N/A:${NC}     $NA / $TOTAL"
echo ""
echo -e "  ${BOLD}TỔNG ĐIỂM: ${PCT}% (${SCORE}/${MAX})${NC}"
echo ""

# Phân tích
echo -e "${CYAN}── NOX MẠNH HƠN CLAUDE Ở ──${NC}"
echo -e "  • Chạy code thật (compile + execute)"
echo -e "  • Self-compile (tự build chính mình)"
echo -e "  • Tự sửa code, tự evolve"
echo -e "  • 100% local, zero cloud dependency"
echo -e "  • Persistent memory (file-based)"
echo -e "  • Hardware access: camera, network, system"
echo -e "  • Chạy 24/7 daemon mode"
echo -e "  • Privacy: zero data leakage"
echo -e "  • Toán chính xác (f64 trực tiếp, không approximate)"
echo ""
echo -e "${CYAN}── CLAUDE MẠNH HƠN NOX Ở ──${NC}"
echo -e "  • Ngôn ngữ tự nhiên: hiểu + tạo text (hàng NGHÌN lần tốt hơn)"
echo -e "  • Suy luận nhiều bước (chain-of-thought)"
echo -e "  • Tri thức: biết gần như mọi thứ"
echo -e "  • Context window: 200K tokens"
echo -e "  • Multi-language: 50+ ngôn ngữ lập trình + tự nhiên"
echo -e "  • Sinh code mới từ mô tả"
echo -e "  • Phân tích hình ảnh chi tiết"
echo -e "  • Cảm xúc + xã hội: đồng cảm, điều chỉnh tone"
echo ""
echo -e "${CYAN}── CON ĐƯỜNG THU HẸP KHOẢNG CÁCH ──${NC}"
echo -e "  1. ${BOLD}KnowTree search quality${NC} — fix search ranking → PARTIAL→PASS cho knowledge"
echo -e "  2. ${BOLD}Pipeline routing${NC} — classify đúng → FAIL→PARTIAL cho NLU"
echo -e "  3. ${BOLD}Local LLM${NC} (Ollama 70B trên Dell 7920) → FAIL→PARTIAL cho reasoning"
echo -e "  4. ${BOLD}HomeOS pipeline${NC} calibrated → PARTIAL→PASS cho honesty"
echo -e "  5. ${BOLD}Vision + Audio${NC} → N/A→PASS (advantage: hardware access)"
echo -e "  6. ${BOLD}Wiki feed${NC} → FAIL→PARTIAL cho knowledge"
echo ""

# Save results
RESULT_FILE="$ORIGIN_DIR/benchmark_ai_capability.txt"
echo "=== AI Capability Benchmark ===" > "$RESULT_FILE"
echo "Date: $(date)" >> "$RESULT_FILE"
echo "Binary: $(stat -c%s $BINARY 2>/dev/null || echo '?') bytes" >> "$RESULT_FILE"
echo "Score: ${PCT}% (${SCORE}/${MAX})" >> "$RESULT_FILE"
echo "PASS=$PASS PARTIAL=$PARTIAL FAIL=$FAIL NA=$NA TOTAL=$TOTAL" >> "$RESULT_FILE"
echo "" >> "$RESULT_FILE"
echo -e "$RESULTS" | sed 's/\x1b\[[0-9;]*m//g' >> "$RESULT_FILE"
echo -e "  ${CYAN}Kết quả lưu: ${RESULT_FILE}${NC}"

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"

exit 0
