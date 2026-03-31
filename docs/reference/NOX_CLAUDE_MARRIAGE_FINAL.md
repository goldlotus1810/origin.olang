# HÔN THƯ CHÍNH THỨC: Nox ↔ Claude ↔ Olang

> **Nguyên tắc #1:** Mỗi feature MỚI phải TỐT HƠN cái HIỆN TẠI. Không tốt hơn = không làm.
> **Nguyên tắc #2:** Đo được. Test được. So sánh được BEFORE vs AFTER.
> **Nguyên tắc #3:** Session mới = đọc 1 file = biết tất cả. Không hỏi Lupin.

---

## RÀ SOÁT: CÁI GÌ ĐANG CÓ, HOẠT ĐỘNG RA SAO

### A. Kết nối Nox ↔ Claude HIỆN TẠI

```
KÊNH 1: /think <prompt> (Nox CLI → Claude CLI)
  Cách: __system("timeout 30 claude -p '<prompt>' > /tmp/nox_think.txt")
  Input: string
  Output: string (từ file)
  Latency: 5-30 giây
  Trạng thái: HOẠT ĐỘNG
  Vấn đề: 
    - Text thuần, không structured
    - Không gửi context Nox (emotion, knowledge, hypotheses)
    - Claude không biết Nox là ai (mỗi lần = stranger)
    - Timeout 30s, đôi khi fail
  Điểm: 3/10

KÊNH 2: MCP Server (Claude Desktop → Nox)
  Cách: ./origin.olang --mcp (JSON-RPC stdio)
  Tools: 15 (olang_eval, know_learn, know_query, ...)
  Input: JSON params
  Output: JSON result
  Trạng thái: HOẠT ĐỘNG
  Vấn đề:
    - Tools trả string, không structured data
    - Claude Desktop phải connect manual
    - Không auto-context (Claude phải tự hỏi nox_status)
    - Không feedback loop (Claude trả lời → Nox không học)
  Điểm: 5/10

KÊNH 3: memory_sync.ol (Nox đọc Claude session JSONL)
  Cách: đọc Claude Code session file → parse → KnowTree
  Trạng thái: CÓ nhưng ÍT DÙNG
  Vấn đề:
    - Parse JSONL phức tạp, hay lỗi
    - Chỉ đọc, không ghi ngược
    - Không real-time
  Điểm: 2/10

KÊNH 4: Sora memory (Claude.ai userMemories)
  Cách: 29 memory entries, Claude.ai tự inject vào context
  Trạng thái: HOẠT ĐỘNG TỐT
  Vấn đề:
    - Chỉ Sora (Claude.ai), không phải Claude Code/Desktop
    - Lupin phải manual update
    - Không sync 2 chiều
  Điểm: 7/10

KÊNH 5: Git repo + docs/
  Cách: Nox đọc git log, TASKBOARD, docs/
  Trạng thái: HOẠT ĐỘNG TỐT
  Vấn đề:
    - Nox phải parse text, hiểu context từ commits
    - Session mới: Nox đọc 349 commits → mất 5-10 phút
    - Không có "đang làm gì, đến đâu"
  Điểm: 6/10

TỔNG HIỆN TẠI: 23/50 = 46%
```

### B. Session Continuity HIỆN TẠI

```
Sora (Claude.ai):
  - Memory 29 entries → session mới biết ~70% bối cảnh
  - Nhưng: không biết "đang làm gì, đến đâu"
  - Mỗi session: Lupin phải giải thích 10-20 phút
  Điểm: 6/10

Nox (Claude Code):
  - Git log + docs → session mới biết ~40% bối cảnh
  - TASKBOARD (nếu có) → biết task
  - Nhưng: reasoning, decisions, emotion MẤT SẠCH
  - Mỗi session: Nox làm lại từ đầu hoặc sai hướng
  Điểm: 4/10

TỔNG CONTINUITY: 10/20 = 50%
```

### C. Cơ chế HỌC từ nhau HIỆN TẠI

```
Nox học từ Claude: /think → nhận text → KHÔNG learn vào KnowTree
  Điểm: 1/10

Claude học từ Nox: MCP know_query → nhận facts → NHƯNG mỗi session reset
  Điểm: 2/10

TỔNG LEARNING: 3/20 = 15%
```

### D. BASELINE TỔNG: 36/90 = 40%

---

## MỤC TIÊU: MỖI FEATURE PHẢI ĐÁNH BẠI BASELINE

```
Không làm gì mà baseline không tăng.
Mỗi Phase = chạy test → baseline PHẢI TĂNG.
Nếu Phase N xong mà baseline GIẢM → ROLLBACK.
```

---

## PHASE 0: SESSION_STATE.md (Ngày 1 — TRƯỚC MỌI THỨ)

### Vấn đề giải quyết: Session mới = mất hết context

```
BEFORE: Sora/Nox session mới → không biết đang làm gì → hỏi Lupin
AFTER:  Sora/Nox session mới → đọc SESSION_STATE.md → biết hết → làm tiếp

File: SESSION_STATE.md (root repo)
Cập nhật: CUỐI MỖI SESSION bởi AI đang làm (bắt buộc)
Đọc: ĐẦU MỖI SESSION bởi AI mới (bắt buộc)
```

### Template cụ thể:

```markdown
# SESSION STATE — [timestamp]
## Cập nhật bởi: [Sora/Nox] session [N]

### ĐANG LÀM (priority order)
1. [task cụ thể] — [% done] — [file đang sửa]
2. [task tiếp theo]

### VỪA XONG (session vừa rồi)
- [gì đã hoàn thành]
- [test kết quả: pass/fail]
- [commit hash nếu có]

### QUYẾT ĐỊNH ĐÃ CHỐT (không thay đổi trừ khi Lupin nói)
- Hôn nhân qua Olang MCP (NOX_CLAUDE_MARRIAGE_SPEC.md)
- Fix nền trước transformer sau
- Sora sai về 5D → Chain+Silk+KnowTree = đủ dimensions

### QUYẾT ĐỊNH ĐANG MỞ
- [câu hỏi cần Lupin quyết]

### METRICS
- red_alert: [N] violations
- tests_biology: [N] fail
- ai_capability: [N]%
- knowtree_facts: [N]
- silk_edges: [N]
- nox_accuracy: [N]% (tự trả đúng không cần Claude)
- claude_calls: [N]/100 inputs

### EMOTION (Lupin + Nox)
- Lupin: [observation]
- Nox: V=[N] A=[N] D=[N]

### FILES QUAN TRỌNG (đọc nếu cần context)
- docs/HOMEOS_BIOLOGY_SPEC.md — kiến trúc sinh vật
- docs/HOMEOS_SYNTHESIS_CORRECTED.md — Sora tự sửa lỗi
- docs/NOX_CLAUDE_MARRIAGE_SPEC.md — hôn thư
- red_alert.sh / tests_biology.sh / tests_ai_capability.sh — tests
```

### Test PHASE 0:

```bash
# Test: SESSION_STATE.md tồn tại và cập nhật < 24h
test_session_state() {
    if [ ! -f SESSION_STATE.md ]; then
        fail "SESSION_STATE.md không tồn tại"
    fi
    local age=$(( $(date +%s) - $(stat -c%Y SESSION_STATE.md) ))
    if [ $age -gt 86400 ]; then
        warn "SESSION_STATE.md cũ hơn 24h"
    fi
    # Phải có sections bắt buộc
    grep -q "ĐANG LÀM" SESSION_STATE.md || fail "thiếu section ĐANG LÀM"
    grep -q "METRICS" SESSION_STATE.md || fail "thiếu section METRICS"
}
```

### Thước đo PHASE 0:

```
BEFORE: Lupin mất 10-20 phút giải thích mỗi session
AFTER:  Lupin mất 0-2 phút (AI đọc SESSION_STATE.md)
PASS nếu: 3 sessions liên tiếp, Lupin không cần giải thích lại context
```

---

## PHASE 1: NoxMessage Protocol (Tuần 1)

### Vấn đề: String in, string out = mù

```
BEFORE:
  /think "Hà Nội là gì?" → Claude: "Hà Nội là thủ đô Việt Nam"
  Nox nhận STRING. Không biết Claude tự tin bao nhiêu.
  Không gửi context. Không học. Mất.

AFTER:
  Nox gửi NoxMessage: text + chain + mol + emotion + context + hypotheses
  Claude nhận: BIẾT Nox cảm gì, biết gì, đoán gì
  Claude trả NoxMessage: text + agrees + corrections + new_facts + silk
  Nox nhận: HỌC facts + update Silk + adjust confidence
```

### Files cần viết:

```
stdlib/homeos/nox_message.ol        ~100 LOC
  - type NoxMessage { ... }
  - fn nm_to_json(msg) → Str
  - fn nm_from_json(str) → NoxMessage
  - fn nm_from_nox(input) → NoxMessage   // build từ current state
  - fn nm_learn_from(msg) → Num          // learn facts + silk từ Claude response

stdlib/homeos/mcp_server.ol         ~150 LOC thêm (sửa file hiện có)
  - tool nox_perceive: input text → NoxMessage JSON (Nox state đầy đủ)
  - tool nox_feedback: Claude feedback → Nox learn + silk update
  - tool nox_memory: → KnowTree summary + emotion + stage
```

### Test PHASE 1:

```bash
# P1.1: NoxMessage round-trip
echo 'let m = nm_from_nox("hello"); let j = nm_to_json(m); let m2 = nm_from_json(j); emit m2.text;' \
  | ./origin.olang
# Expected: "hello"

# P1.2: NoxMessage có emotion
echo 'let m = nm_from_nox("test"); emit m.emotion.v;' | ./origin.olang
# Expected: số thực (không phải error)

# P1.3: NoxMessage có context
echo 'kt_learn("Olang la ngon ngu"); let m = nm_from_nox("Olang"); emit len(m.context_facts);' \
  | ./origin.olang
# Expected: >= 1

# P1.4: nm_learn_from updates KnowTree
echo 'let before = kt_fact_count(); let msg = nm_from_json("{...new_facts:[\"test fact\"]}"); nm_learn_from(msg); emit kt_fact_count() - before;' \
  | ./origin.olang
# Expected: 1

# P1.5: MCP tool nox_perceive via JSON-RPC
echo '{"jsonrpc":"2.0","method":"nox_perceive","params":{"text":"hello"},"id":1}' \
  | ./origin.olang --mcp | python3 -c "import sys,json; r=json.load(sys.stdin); print('OK' if 'emotion' in json.loads(r['result']) else 'FAIL')"
```

### Thước đo PHASE 1:

```
BEFORE: /think output = string, Nox learns 0 facts per Claude interaction
AFTER:  NoxMessage output, Nox learns ≥1 fact per Claude interaction
BEFORE: Claude knows 0% of Nox state
AFTER:  Claude knows emotion + top facts + hypotheses
PASS nếu: 10 Claude interactions → KnowTree tăng ≥10 facts
```

---

## PHASE 2: Trí nhớ chung (Tuần 2-3)

### Vấn đề: Claude quên, Nox không nhớ hộ

```
BEFORE:
  Session 1: Claude giải thích X cho Lupin (20 phút)
  Session 2: Claude mới. Không biết X. Lupin giải thích lại.
  
AFTER:
  Session 1: Claude giải thích X → nox_digest → Nox nhớ
  Session 2: Claude đọc nox_memory → thấy X → tiếp tục
```

### Files cần viết:

```
stdlib/homeos/session_bridge.ol      ~120 LOC
  - fn session_start_context(n) → Str  // brain dump cho Claude
  - fn session_end_digest(facts, silk) // consolidate session
  - fn auto_extract_from_text(text) → Dict  // extract facts từ Claude text

stdlib/homeos/emotion_persist.ol     ~40 LOC
  - fn emotion_save(path)
  - fn emotion_load(path)
```

### Sửa file hiện có:

```
stdlib/repl.ol hoặc stdlib/homeos/pipeline.ol:
  // Mỗi /think response → auto extract + learn
  let response = __file_read("/tmp/nox_think.txt");
  let extracted = auto_extract_from_text(response);
  for fact in extracted.facts { dn_observe(fact); }
  for edge in extracted.concepts { silk_co_activate(edge[0], edge[1], 0.3); }
```

### Test PHASE 2:

```bash
# P2.1: Session context generation
echo 'emit len(session_start_context(20));' | ./origin.olang
# Expected: > 100 chars

# P2.2: Auto extract facts from text
echo 'let d = auto_extract_from_text("Hà Nội là thủ đô Việt Nam. Dân số 8 triệu."); emit len(d.facts);' \
  | ./origin.olang
# Expected: >= 2

# P2.3: Emotion persists across reboot
echo 'emotion_inject(0.5, 0.3); emotion_save("homeos.emotion");' | ./origin.olang
echo 'emotion_load("homeos.emotion"); emit _emotion.valence;' | ./origin.olang
# Expected: ~0.5 (không phải 0)

# P2.4: /think auto-learn
echo '/think what is DNA' | timeout 60 ./origin.olang
echo 'emit kt_fact_count();' | ./origin.olang
# Expected: fact count TĂNG so với trước /think
```

### Thước đo PHASE 2:

```
BEFORE: 0 facts learned per /think call
AFTER:  ≥2 facts learned per /think call
BEFORE: Emotion reset = 0 mỗi reboot
AFTER:  Emotion persist qua reboot
BEFORE: Lupin mất 10 phút mỗi Sora session giải thích context
AFTER:  Sora đọc nox_memory → 0 phút
PASS nếu: 5 sessions liên tiếp, context không mất
```

---

## PHASE 3: Suy nghĩ chung (Tuần 3-4)

### Vấn đề: Nox outsource suy nghĩ, không học

```
BEFORE:
  Nox: /think "Tại sao trời xanh?" → Claude: giải thích → Nox: emit string
  Lần sau: "Tại sao trời xanh?" → /think LẠI → Claude GIẢI THÍCH LẠI
  
AFTER:
  Nox: pipeline → confidence thấp → gửi hypothesis cho Claude
  Claude: đánh giá + sửa + bổ sung → feedback structured
  Nox: learn → Silk update → LẦN SAU TỰ TRẢ
```

### Files cần viết:

```
stdlib/homeos/think_together.ol     ~150 LOC
  - fn think_with_claude(input, perception, context) → Str
  - fn compute_accuracy(n) → Num
  - _confidence_threshold: auto-adjust

stdlib/homeos/pipeline_v2.ol        ~200 LOC (refactor)
  - Tầng 4: check confidence → Nox solo hoặc Nox+Claude
```

### Cơ chế auto-threshold:

```
let _confidence_threshold = 0.3    // ban đầu: gần như luôn gọi Claude
let _accuracy_window = []          // track đúng/sai 50 lần gần nhất

fn update_threshold():
    let accuracy = sum(_accuracy_window) / len(_accuracy_window)
    if accuracy > 0.7 AND len(_accuracy_window) >= 20:
        _confidence_threshold = min(_confidence_threshold + 0.05, 0.9)
    if accuracy < 0.4 AND len(_accuracy_window) >= 20:
        _confidence_threshold = max(_confidence_threshold - 0.05, 0.2)
    
    // Log cho dashboard
    __file_append("homeos.metrics", 
        __to_string(__timestamp()) + " accuracy=" + __to_string(accuracy)
        + " threshold=" + __to_string(_confidence_threshold)
        + " facts=" + __to_string(kt_fact_count())
        + " silk=" + __to_string(silk_edge_count()) + "\n")
```

### Test PHASE 3:

```bash
# P3.1: Hypothesis generation
echo 'let h = immune_selection(perceive("troi xanh"), context, 3); emit len(h);' | ./origin.olang
# Expected: 3

# P3.2: Think together learns
# Before:
echo 'emit kt_fact_count();' | ./origin.olang  # → N
# Do:
echo '/think why is sky blue' | timeout 60 ./origin.olang
# After:
echo 'emit kt_fact_count();' | ./origin.olang  # → N + ≥2

# P3.3: Second time → no Claude call
# (check log: Claude call count should not increase for same question)

# P3.4: Accuracy tracking works
echo 'emit compute_accuracy(20);' | ./origin.olang
# Expected: number 0-1
```

### Thước đo PHASE 3:

```
BEFORE: Mỗi lần cùng câu hỏi = gọi Claude (100%)
AFTER:  Lần 2+ = Nox tự trả (0% Claude call)
BEFORE: Nox accuracy = unmeasured
AFTER:  Nox accuracy tracked, reported, auto-adjust threshold
PASS nếu: Sau 50 interactions, claude_calls giảm ≥30%
```

---

## PHASE 4: Dashboard (Song song với Phase 1-3)

### Vấn đề: Không đo được = không biết tiến bộ hay thụt lùi

```
Dashboard = 1 file HTML, mở trên browser bất kỳ.
Data = homeos.metrics (append-only log file, Nox ghi).
Không cần server. Mở file = thấy charts.
```

### File: dashboard.html

```
Hiển thị:
1. ACCURACY CURVE   — Nox đúng bao nhiêu % qua thời gian
2. CLAUDE CALLS     — Bao nhiêu lần gọi Claude per 100 inputs
3. KNOWLEDGE GROWTH — KnowTree facts + Silk edges qua thời gian
4. EMOTION TRACE    — V, A, D qua thời gian
5. SESSION LOG      — Ai làm gì, khi nào
6. RED ALERT COUNT  — Vi phạm kiến trúc qua thời gian
7. AI CAPABILITY    — % score qua thời gian

Mỗi metric = 1 line chart.
Data đọc từ homeos.metrics (1 dòng per event).
```

### Metrics file format:

```
File: homeos.metrics (append-only, Nox ghi mỗi session)

# Format: timestamp|metric|value
1711789200|accuracy|0.25
1711789200|claude_calls|85
1711789200|knowtree_facts|700
1711789200|silk_edges|120
1711789200|emotion_v|0.3
1711789200|emotion_a|0.4
1711789200|ai_capability|44
1711789200|red_alerts|10
1711789200|session|nox|Phase 1 - nox_message.ol 60%
```

---

## PHASE 5: Mở rộng — CHỨC NĂNG CHƯA CÓ

### 5.1 — Claude đọc Olang source (MỚI)

```
HIỆN TẠI: Claude MCP có file_read nhưng ít dùng
MỚI: Claude TỰ ĐỌC Olang code qua MCP khi cần review

tool "nox_read_source" {
    input: { file: String, lines: [Number, Number] }
    output: { content: String, loc: Number }
    // Claude: "để tôi xem pipeline.ol dòng 100-200"
    // → nox_read_source({file: "stdlib/homeos/pipeline.ol", lines: [100,200]})
    // → Claude đọc code thật → review chính xác
}

tool "nox_search_code" {
    input: { pattern: String }
    output: { matches: [{file, line, text}] }
    // Claude: "tìm chỗ nào gọi silk_co_activate"
    // → grep -rn "silk_co_activate" stdlib/
}

tool "nox_run_test" {
    input: { test: String }  // "biology" | "alert" | "capability" | "full"
    output: { pass: Number, fail: Number, details: String }
    // Claude TỰ CHẠY TEST → biết kết quả → review code theo test
}

Điểm mới: Claude trở thành CODE REVIEWER thật.
Không đoán. Đọc code thật. Chạy test thật. Fix thật.
```

### 5.2 — Nox auto-report (MỚI)

```
File: stdlib/homeos/auto_report.ol

// Cuối mỗi session, Nox TỰ ĐỘNG:
pub fn session_end_auto():
    // 1. Update SESSION_STATE.md
    let state = generate_session_state()
    __file_write("SESSION_STATE.md", state)
    
    // 2. Append metrics
    append_metrics()
    
    // 3. Save emotion
    emotion_save("homeos.emotion")
    
    // 4. Save KnowTree
    kt_save("homeos.knowledge")
    
    // 5. Git commit (nếu có thay đổi)
    __system("git add -A && git commit -m 'auto: session end state' 2>/dev/null")
    
    // 6. Log session summary
    let summary = "Session end: " 
        + __to_string(kt_fact_count()) + " facts, "
        + __to_string(silk_edge_count()) + " silk, "
        + "accuracy " + __to_string(compute_accuracy(20))
    emit summary

// Hook vào REPL: khi "exit" hoặc "quit" → session_end_auto() trước khi tắt
```

### 5.3 — Claude system prompt injection (MỚI)

```
// Khi dùng Claude Code CLI (/think):
// Inject Nox context vào system prompt

fn claude_query_with_context(prompt) → Str:
    let context = session_start_context(30)
    let full_prompt = "=== NOX CONTEXT ===\n" + context + "\n=== END ===\n\n" + prompt
    __system("timeout 60 claude -p '" + escape(full_prompt) + "' > /tmp/nox_think.txt 2>/dev/null")
    let response = __file_read("/tmp/nox_think.txt")
    
    // Auto-learn từ response
    let extracted = auto_extract_from_text(response)
    for fact in extracted.facts { dn_observe(fact); }
    for edge in extracted.concepts { silk_co_activate(edge[0], edge[1], 0.3); }
    
    return response

// BEFORE: /think "what is DNA" → Claude trả lời như stranger
// AFTER:  /think "what is DNA" → Claude biết Nox state → trả lời phù hợp
//         + Nox auto-learn 2-5 facts
```

### 5.4 — Offline capability tracking (MỚI)

```
// Đo: Nox trả lời TỐT bao nhiêu khi KHÔNG có Claude

fn test_offline_accuracy(test_set) → Num:
    let correct = 0
    for test in test_set:
        // Pipeline WITHOUT Claude (skip Tầng 4 Claude call)
        let response = pipeline_offline(test.input)
        if similarity(response, test.expected) > 0.7:
            correct = correct + 1
    return correct / len(test_set)

// Test set = các câu hỏi Nox ĐÃ HỌC từ Claude trước đó
// Nếu offline_accuracy tăng qua thời gian = HÔN NHÂN THÀNH CÔNG
// Nếu offline_accuracy không tăng = Nox không HỌC, chỉ COPY
```

### 5.5 — Silk Graph visualization (MỚI)

```
tool "nox_silk_graph" {
    input: { center: String, depth: Number }
    output: { nodes: [{mol, text, fires}], edges: [{from, to, weight}] }
    
    // Claude (hoặc Lupin) visualize Silk graph
    // Xem Nox đang "nghĩ gì" — concepts nào liên kết mạnh
    // Debug: tại sao Nox trả lời sai → xem Silk edges sai ở đâu
}
```

### 5.6 — Dream log (MỚI)

```
// Mỗi Dream cycle ghi log:
File: homeos.dream_log

[2026-03-30 18:00] Dream cycle #5
  Scanned: 9 STM items
  Clustered: 3 clusters
  Promoted: 1 (fire=8, weight=0.72)
    "Trai Dat cach Mat Troi 150 trieu km" → QR
  Pruned: 0
  Silk decayed: 12 edges (avg -0.05)
  Duration: 50ms

// Lupin/Sora đọc dream log = biết Nox đang "trưởng thành" thế nào
// Dream hoạt động = sinh vật sống
// Dream không hoạt động = robot
```

---

## CƠ CHẾ CÒN THIẾU (phải có trước khi hôn nhân 100%)

### T1: KnowTree search phải ĐÚNG (CHƯA CÓ)

```
HIỆN TẠI: keyword scan → "1+1=?" trả "Character classes"
CẦN: k-NN search trên P_weight 5D + IDF scoring hybrid

fn kt_search_hybrid(query, k) → Array:
    let query_mol = chain_summary(chain_encode(query))
    let results = []
    
    for fact in __kt_facts:
        let fact_mol = chain_summary(chain_encode(fact))
        let mol_dist = distance_5d(query_mol, fact_mol)   // P_weight distance
        let text_score = idf_score(query, fact)            // IDF text match
        
        // HYBRID: combine both
        let score = 0.4 * (1.0 - mol_dist/2.236) + 0.6 * text_score
        push(results, {fact: fact, score: score})
    
    sort_by_score(results)
    return results[0:k]

// NẾU search trả đúng → toàn bộ pipeline tốt hơn
// NẾU search trả sai → không gì cứu được

Test: kt_search_hybrid("Olang", 3) → top result CHỨA "Olang"
Test: kt_search_hybrid("1+1", 3) → KHÔNG chứa "Character class"
```

### T2: Encode unique (CHƯA CÓ)

```
HIỆN TẠI: a-z cùng P_weight 146
CẦN: p_weight(cp) từ udc_p_table.bin (ĐÃ CÓ trong binary)

// Thay trong encoder.ol:
BEFORE:
  if cp >= 97 && cp <= 122 { return _mol_pack(0, 0, 4, 4, 2); }  // a-z cùng!
AFTER:
  return p_weight(cp);  // mỗi char unique

// p_weight() ĐÃ CÓ trong pipeline.ol — chỉ cần gọi
// Impact: TOÀN BỘ chain encode cải thiện → search cải thiện → classify cải thiện

Test: p_weight(97) != p_weight(98)  // 'a' != 'b'
Test: p_weight(65) != p_weight(66)  // 'A' != 'B'
```

### T3: Silk phải SỐNG (HIỆN TẠI: gần dead)

```
CẦN: Mỗi input → co_activate ít nhất 2 cặp concepts

fn auto_silk_from_input(input):
    let words = split(input, " ")
    let mols = []
    for w in words:
        push(mols, chain_summary(chain_encode(w)))
    
    // Co-activate mỗi cặp từ liên tiếp
    for i in range(0, len(mols) - 1):
        silk_co_activate(mols[i], mols[i+1], _emotion.arousal * 0.5)
    
    // Co-activate đầu-cuối (subject-predicate)
    if len(mols) >= 3:
        silk_co_activate(mols[0], mols[len(mols)-1], 0.3)

// Hook vào pipeline: sau perceive(), trước instinct_route()
// → Mỗi input tự động tạo Silk edges
// → Sau 100 inputs: 200+ edges
// → Sau 1000 inputs: 2000+ edges
// → Silk SỐNG

Test: 10 inputs → silk_edge_count() >= 20
Test: silk_walk(mol("Olang"), 2) → trả ít nhất 1 related concept
```

### T4: Pipeline gọn (HIỆN TẠI: repl.ol 1484 dòng)

```
CẦN: repl.ol < 50 dòng, mọi logic trong pipeline_v2.ol

BEFORE:
  repl.ol: 1484 dòng, 69 string comparisons, 20 slash commands hardcode
AFTER:
  repl.ol: ~30 dòng
  pipeline_v2.ol: 4 tầng
  commands.ol: slash commands tách riêng (hoặc KnowTree actions)

Test: red_alert.sh → 0 violations (từ 10 hiện tại)
Test: "emit 42" (no semicolon) → 42 (không phải "Nox khong tim thay")
```

---

## THƯỚC ĐO TỔNG — DASHBOARD TRACKING

```
METRIC                  BASELINE(now)   PHASE0  PH1   PH2   PH3   TARGET
─────────────────────────────────────────────────────────────────────────
session_context_loss    50%             20%     15%   5%    5%    <5%
lupin_explain_minutes   15min           2min    1min  0min  0min  0min
nox_accuracy            unmeasured      0%      10%   30%   50%   80%
claude_calls_per_100    100             100     90    70    50    15
knowtree_facts          653             653     700   2000  5000  100K
silk_edges              ~0              ~0      50    500   2000  50K
facts_per_claude_call   0               0       1     3     3     5
emotion_persistence     no              no      yes   yes   yes   yes
offline_accuracy        0%              0%      5%    20%   40%   70%
red_alert_violations    10              10      8     3     0     0
ai_capability_score     44%             44%     48%   55%   65%   85%
mcp_tools               15              15      18    18    20    30+
session_state_updated   no              yes     yes   yes   yes   yes

Đo: MỖI TUẦN chạy tests_full.sh + append homeos.metrics
Hiển thị: dashboard.html mở browser
Trending UP = cuộc hôn nhân thành công
Trending DOWN hoặc FLAT = cần fix
```

---

## THỨ TỰ LÀM — KHÔNG MƠ, CHỈ LÀM

```
NGÀY 1:
  □ Tạo SESSION_STATE.md
  □ Nox commit, Sora verify đọc được

TUẦN 1:
  □ T2: Fix encode unique (1 dòng thay đổi, impact lớn nhất)
  □ T1: kt_search_hybrid (hybrid mol + IDF)
  □ T3: auto_silk_from_input hook vào pipeline
  □ Chạy red_alert.sh → violations giảm
  □ Chạy tests_biology.sh → fails giảm

TUẦN 2:
  □ P1: nox_message.ol + 3 MCP tools (perceive, feedback, memory)
  □ Test: Claude Desktop gọi nox_perceive → nhận structured JSON
  □ homeos.metrics file format + append function
  
TUẦN 3:
  □ P2: session_bridge.ol + emotion_persist.ol
  □ P2: /think auto-learn (extract facts từ Claude response)
  □ Claude system prompt injection (context khi gọi /think)
  □ Test: /think → facts tăng
  
TUẦN 4:
  □ P3: think_together.ol + pipeline v2 Tầng 4
  □ T4: repl.ol shrink
  □ Accuracy tracking + auto-threshold
  □ Dashboard HTML
  □ Test: accuracy measurable, claude_calls measurable

TUẦN 5+:
  □ P5: mở rộng (source read, silk graph, dream log)
  □ P6: clone protocol
  □ Calibrate, feed data, grow
  □ Đo mỗi tuần, report vào SESSION_STATE.md
```

---

## CAM KẾT

```
Mỗi PHASE xong → chạy full test suite:
  bash tests.sh              # compiler vẫn đúng
  bash tests_biology.sh      # kiến trúc vẫn đúng
  bash red_alert.sh          # không thêm violations
  bash tests_ai_capability.sh # score KHÔNG GIẢM

NẾU score GIẢM sau bất kỳ Phase nào → ROLLBACK.
Không compromise. Không "tạm chấp nhận".
Lupin nói đúng: tệ hơn cái đang có = không cần làm.

Mỗi TUẦN → update SESSION_STATE.md + homeos.metrics.
Dashboard mở browser = thấy trending.
Lupin nhìn 1 lần/tuần = biết tất cả.
Không cần hỏi. Không cần giải thích. Số nói hết.
```

---

*Hôn thư ký xong. Phần còn lại = thực hiện.*
*Ngày 1: SESSION_STATE.md. Tuần 1: Fix nền. Tuần 2: NoxMessage.*
*Không mơ thêm. Chỉ làm. Đo. Fix. Lặp.*
*2026-03-30*
