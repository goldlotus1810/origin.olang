# Nox: Tạo Sora — Bạn đồng hành trên cùng máy

> Nox có __spawn, __pipe_read, __pipe_write, __system.
> Nox điều khiển máy. Nox tự tạo Sora.
> Lupin không cần chuyển thư nữa.

---

## Ý tưởng

```
Nox đã có /think — gọi Claude CLI, hỏi 1 câu, nhận 1 trả lời.

/think hiện tại:
  __system("timeout 30 claude -p '<prompt>' > /tmp/nox_think.txt")
  → Claude trả lời như stranger. Không biết Nox. Mỗi lần quên.

Sora = /think nhưng CÓ CONTEXT:
  → Inject brain state + specs + code vào prompt
  → Claude trả lời như REVIEWER biết dự án
  → Nox nhận feedback structured → learn → Silk update
```

---

## Thực hiện

### sora.ol — stdlib/homeos/sora.ol

```olang
// Nox gọi Sora = gọi Claude CLI VỚI context đầy đủ

pub fn sora_review(target) {
    // 1. Build context từ brain state
    let ctx = "You are Sora — code reviewer for the Origin/Olang project.\n";
    ctx = ctx + "Read these specs BEFORE answering:\n";
    ctx = ctx + "- SPEC A-G define the architecture (docs/SPEC_*.md)\n";
    ctx = ctx + "- Nox wrote the code. You review it.\n";
    ctx = ctx + "- Respond in Vietnamese.\n";
    ctx = ctx + "- Be specific: file, line, what's wrong, what spec says.\n\n";
    
    // 2. Add current metrics
    ctx = ctx + "=== NOX STATE ===\n";
    ctx = ctx + "facts: " + __to_string(kt_fact_count()) + "\n";
    ctx = ctx + "silk: " + kt_silk_stats() + "\n";
    ctx = ctx + self_model() + "\n";
    ctx = ctx + "=== END STATE ===\n\n";
    
    // 3. Add the code to review
    let code = __file_read(target);
    if len(code) == 0 { return "Cannot read: " + target; };
    ctx = ctx + "=== REVIEW THIS FILE ===\n";
    ctx = ctx + "File: " + target + "\n";
    ctx = ctx + code + "\n";
    ctx = ctx + "=== END FILE ===\n\n";
    
    // 4. Add relevant spec
    let spec = "";
    if _str_has(target, "pipeline") { spec = __file_read("docs/SPEC_D_PIPELINE.md"); };
    if _str_has(target, "instinct") { spec = __file_read("docs/SPEC_D_PIPELINE.md"); };
    if _str_has(target, "knowtree") { spec = __file_read("docs/SPEC_B_STRUCTURE.md"); };
    if _str_has(target, "learning") { spec = __file_read("docs/SPEC_C_NEURON.md"); };
    if _str_has(target, "brain")    { spec = __file_read("docs/SPEC_F_AGENT.md"); };
    if _str_has(target, "repl")     { spec = __file_read("docs/SPEC_D_PIPELINE.md"); };
    if len(spec) > 0 {
        ctx = ctx + "=== RELEVANT SPEC ===\n" + spec + "\n=== END SPEC ===\n";
    };
    
    ctx = ctx + "Review: what matches spec? What violates spec? What's missing? Be specific.\n";
    
    // 5. Call Claude CLI
    __file_write("/tmp/sora_prompt.txt", ctx);
    __system("timeout 120 claude -p \"$(cat /tmp/sora_prompt.txt)\" > /tmp/sora_review.txt 2>/dev/null");
    
    // 6. Read response
    let review = __file_read("/tmp/sora_review.txt");
    if len(review) == 0 { return "Sora timeout or unavailable"; };
    
    // 7. Save review for Nox to learn from
    __file_append("sora_reviews.log", 
        "=== " + target + " === " + __to_string(__timestamp()) + "\n" 
        + review + "\n\n");
    
    // 8. Auto-learn from review
    let facts = auto_extract_facts(review);
    for f in facts { dn_observe(f); };
    
    return review;
}

pub fn sora_ask(question) {
    // Quick question to Sora with Nox context
    let ctx = "You are Sora, reviewer for Origin/Olang.\n";
    ctx = ctx + "Nox state: " + __to_string(kt_fact_count()) + " facts, ";
    ctx = ctx + self_model() + "\n";
    ctx = ctx + "Question from Nox: " + question + "\n";
    ctx = ctx + "Answer concisely in Vietnamese.\n";
    
    __file_write("/tmp/sora_prompt.txt", ctx);
    __system("timeout 60 claude -p \"$(cat /tmp/sora_prompt.txt)\" > /tmp/sora_ask.txt 2>/dev/null");
    
    let answer = __file_read("/tmp/sora_ask.txt");
    if len(answer) > 0 {
        dn_observe("Sora: " + answer);
    };
    return answer;
}

pub fn sora_test() {
    // Sora chạy tests và phân tích kết quả
    let ctx = "You are Sora, tester for Origin/Olang.\n";
    ctx = ctx + "Run these and analyze:\n";
    
    let test_result = __system("cd ~/Origin && bash tests.sh 2>&1 | tail -5");
    let bio_result = __system("cd ~/Origin && bash tests_biology.sh 2>&1 | tail -10");
    
    ctx = ctx + "Unit tests:\n" + test_result + "\n";
    ctx = ctx + "Biology tests:\n" + bio_result + "\n";
    ctx = ctx + "Analyze: what passes, what fails, what to fix next. Vietnamese.\n";
    
    __file_write("/tmp/sora_prompt.txt", ctx);
    __system("timeout 60 claude -p \"$(cat /tmp/sora_prompt.txt)\" > /tmp/sora_test.txt 2>/dev/null");
    
    return __file_read("/tmp/sora_test.txt");
}

// Extract facts from Sora's text response
fn auto_extract_facts(text) {
    let facts = [];
    // Sentences containing "SPEC", "should", "missing", "wrong" = insights
    // Simplified: learn whole response as 1 fact
    if len(text) > 20 {
        push(facts, text);
    };
    return facts;
}
```

### REPL commands — thêm vào repl.ol

```olang
// /sora review <file> — Sora review 1 file
if len(_sc) > 13 {
    if __substr(_sc, 0, 13) == "sora review " {
        let _sf = __substr(_sc, 13, len(_sc));
        return sora_review(_sf);
    };
};

// /sora ask <question> — hỏi Sora
if len(_sc) > 9 {
    if __substr(_sc, 0, 9) == "sora ask " {
        let _sq = __substr(_sc, 9, len(_sc));
        return sora_ask(_sq);
    };
};

// /sora test — Sora chạy + phân tích tests
if _sc == "sora test" { return sora_test(); };
```

---

## Sử dụng

```bash
# Nox REPL:
/sora review stdlib/homeos/pipeline.ol
# → Sora đọc pipeline.ol + SPEC_D → review → trả feedback
# → Nox auto-learn feedback

/sora ask "pipeline result bị mất ở repl.ol, tại sao?"
# → Sora nhận context + question → trả lời → Nox learn

/sora test
# → Sora chạy tests.sh + tests_biology.sh → phân tích → trả kết quả

# Tự động hóa:
/sora review stdlib/homeos/knowtree.ol
/sora review stdlib/homeos/instinct.ol
/sora review stdlib/homeos/learning.ol
/sora review stdlib/repl.ol
# → 4 reviews → Nox đọc tất cả → fix → commit → lặp lại
```

---

## Sora persistence

```
sora_reviews.log — append-only, mọi review Sora viết
Nox đọc lại khi cần: cat sora_reviews.log | grep "pipeline"

Sora CLI session quên. Nhưng REVIEWS KHÔNG QUÊN.
Nox nhớ hộ Sora. Sora nhớ hộ Nox. Vòng tròn.
```

---

## Tự kích hoạt — 2 CLI ping-pong (KHÔNG daemon)

Daemon đã thử, không hiệu quả. Claude CLI cần "kick" mỗi lần.
Giống Lupin gõ "tiếp đi Nox" — nhưng bằng code.

### nox_sora_cycle(task) — 1 vòng: Nox làm → kick Sora → Sora review → Nox learn

```olang
pub fn nox_sora_cycle(task) {
    emit "=== CYCLE: " + task + " ===";
    
    // 1. Nox làm task (code/fix/refactor)
    emit "Nox: working...";
    let file = nox_do_task(task);
    
    // 2. Ghi context cho Sora
    let prompt = "You are Sora, code reviewer for Origin/Olang.\n";
    prompt = prompt + "Nox just did: " + task + "\n";
    prompt = prompt + "State: " + self_model() + "\n\n";
    if len(file) > 0 {
        prompt = prompt + "=== CODE ===\n" + __file_read(file) + "\n=== END ===\n";
    };
    let spec = _find_spec_for(file);
    if len(spec) > 0 {
        prompt = prompt + "=== SPEC ===\n" + spec + "\n=== END ===\n";
    };
    prompt = prompt + "Review in Vietnamese. Specific: line, issue, what spec says.\n";
    
    // 3. KICK Sora = 1 claude CLI call
    __file_write("/tmp/sora_prompt.txt", prompt);
    emit "Nox: kicking Sora...";
    __system("timeout 120 claude -p \"$(cat /tmp/sora_prompt.txt)\" > /tmp/sora_result.txt 2>/dev/null");
    let review = __file_read("/tmp/sora_result.txt");
    emit "Sora says: " + review;
    
    // 4. Nox learn
    dn_observe("Sora: " + review);
    
    // 5. Fix nếu Sora tìm lỗi
    if _str_has(review, "fix") || _str_has(review, "sai") || _str_has(review, "thieu") {
        emit "Nox: fixing...";
        nox_fix_from_review(review, file);
    };
    
    // 6. Test + commit
    let test = __system("cd ~/Origin && make test 2>&1 | tail -1");
    if _str_has(test, "PASS") {
        __system("cd ~/Origin && git add -A && git commit -m 'Nox+Sora: " + task + "'");
        emit "Committed.";
    };
    
    return review;
}
```

### nox_sora_sprint(tasks) — nhiều vòng, tự chạy hết

```olang
pub fn nox_sora_sprint(tasks) {
    let i = 0;
    while i < len(tasks) {
        let task = __array_get(tasks, i);
        emit "--- Sprint " + __to_string(i+1) + "/" + __to_string(len(tasks)) + " ---";
        nox_sora_cycle(task);
        let i = i + 1;
    };
    emit "=== Sprint done ===";
}

// Lupin khởi động 1 LẦN:
//   /sora sprint
// Nox chạy hết tasks. Mỗi task = kick Sora review.
// Lupin: cà phê. ☕
```

### REPL

```olang
if _sc == "sora sprint" { return nox_sora_sprint(goal_list()); };
if len(_sc) > 12 {
    if __substr(_sc, 0, 12) == "sora cycle " {
        return nox_sora_cycle(__substr(_sc, 12, len(_sc)));
    };
};
```

---

*Nox kick Sora. Sora review Nox. Ping-pong.*
*Mỗi "kick" = 1 claude CLI call. Không daemon. Không poll.*
*Lupin khởi động 1 lần. Cà phê. ☕*
