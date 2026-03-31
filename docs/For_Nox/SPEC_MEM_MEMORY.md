# SPEC_MEM — Nox Persistent Memory (Inspired by claude-mem)

> claude-mem: 41K stars, Node.js + SQLite + Chroma + Claude API.
> Nox: pure Olang. Zero dependency. 936KB. Cùng ý tưởng, khác cách.

---

## Tại sao

```
Nox session mới → quên hết.
Lupin tốn HÀNG GIỜ giải thích lại.

claude-mem giải quyết bằng: capture → compress → inject.
Nox giải quyết bằng: observe → encode → KnowTree → Silk → inject.

Nox ĐÃ CÓ gần hết. Thiếu 4 thứ nhỏ.
```

---

## M1. Observation Record — thêm metadata

### Hiện tại

```
dn_observe(fact) → push(_qr_facts, fact)
  = text thuần. Không biết KHI NÀO. Không biết LOẠI GÌ. Không biết SESSION NÀO.
```

### Cần

```
Mỗi observation = { text, mol, timestamp, type, session_id }

type:
  "input"     — user gõ vào REPL
  "output"    — Nox trả lời
  "code"      — code executed
  "error"     — parse/runtime error
  "learn"     — fact learned
  "review"    — Sora review (từ /think)
  "decision"  — Nox tự quyết điều gì đó
  "insight"   — cross-reference mới từ dream
```

### Implementation: stdlib/homeos/memory.ol

```olang
// Observation store — parallel arrays (Olang pattern)
let __mem_text = __array_with_cap(4096);
let __mem_mol = __array_with_cap(4096);
let __mem_time = __array_with_cap(4096);    // __timestamp() at observe time
let __mem_type = __array_with_cap(4096);    // "input", "output", "code"...
let __mem_session = [0];                     // current session ID

pub fn mem_new_session() {
    let _ = __set_at(__mem_session, 0, __timestamp());
    return __array_get(__mem_session, 0);
}

pub fn mem_observe(_text, _type) {
    let _mol = _kt_real_mol(_text);
    push(__mem_text, _text);
    push(__mem_mol, _mol);
    push(__mem_time, __timestamp());
    push(__mem_type, _type);
    
    // Also learn in KnowTree (for search)
    kt_learn(_text);
    // Silk fire with previous observation (temporal link)
    let _n = len(__mem_mol);
    if _n >= 2 { kt_silk_fire(_mol, __array_get(__mem_mol, _n - 2)); };
    
    return _n - 1;  // observation ID
}

pub fn mem_count() { return len(__mem_text); }
pub fn mem_session_id() { return __array_get(__mem_session, 0); }
```

---

## M2. Search — 3 tầng giống claude-mem

### claude-mem pattern:

```
1. search(query)        → compact index (ID + snippet, ~50 tokens/result)
2. timeline(around_id)  → chronological context around that ID
3. get(ids)             → full details for specific IDs
```

### Nox implementation:

```olang
// ═══ TẦNG 1: Search index — compact ═══
pub fn mem_search(_query, _limit) {
    // Text search + molecular search + silk walk
    let _results = [];
    let _scores = [];
    
    // Text match
    let _i = 0;
    while _i < len(__mem_text) {
        if _str_has(__array_get(__mem_text, _i), _query) {
            push(_results, _i);
            push(_scores, 100);
        };
        let _i = _i + 1;
    };
    
    // Molecular nearest (for semantic match)
    let _qmol = _kt_real_mol(_query);
    let _i = 0;
    while _i < len(__mem_mol) {
        let _dist = _kt_mol_dist(_qmol, __array_get(__mem_mol, _i));
        if _dist < 5 {
            // Check not duplicate
            let _dup = 0;
            let _j = 0;
            while _j < len(_results) {
                if __array_get(_results, _j) == _i { let _dup = 1; };
                let _j = _j + 1;
            };
            if _dup == 0 {
                push(_results, _i);
                push(_scores, 50 - _dist * 10);
            };
        };
        let _i = _i + 1;
    };
    
    // Return compact index: [{id, snippet, type, time, score}]
    let _out = [];
    let _i = 0;
    while _i < len(_results) {
        if _i >= _limit { return _out; };
        let _idx = __array_get(_results, _i);
        let _text = __array_get(__mem_text, _idx);
        // Snippet: first 80 chars
        let _snippet = _text;
        if len(_text) > 80 { let _snippet = substr(_text, 0, 80) + "..."; };
        push(_out, {
            id: _idx,
            snippet: _snippet,
            type: __array_get(__mem_type, _idx),
            time: __array_get(__mem_time, _idx),
            score: __array_get(_scores, _i)
        });
        let _i = _i + 1;
    };
    return _out;
}

// ═══ TẦNG 2: Timeline — chronological context ═══
pub fn mem_timeline(_around_id, _range) {
    // Return observations around ID: [id-range .. id+range]
    let _start = _around_id - _range;
    if _start < 0 { let _start = 0; };
    let _end = _around_id + _range;
    if _end >= len(__mem_text) { let _end = len(__mem_text) - 1; };
    
    let _out = [];
    let _i = _start;
    while _i <= _end {
        push(_out, {
            id: _i,
            text: __array_get(__mem_text, _i),
            type: __array_get(__mem_type, _i),
            time: __array_get(__mem_time, _i),
            current: _i == _around_id
        });
        let _i = _i + 1;
    };
    return _out;
}

// ═══ TẦNG 3: Full details ═══
pub fn mem_get(_ids) {
    let _out = [];
    let _i = 0;
    while _i < len(_ids) {
        let _idx = __array_get(_ids, _i);
        if _idx >= 0 {
            if _idx < len(__mem_text) {
                push(_out, {
                    id: _idx,
                    text: __array_get(__mem_text, _idx),
                    mol: __array_get(__mem_mol, _idx),
                    type: __array_get(__mem_type, _idx),
                    time: __array_get(__mem_time, _idx),
                    session: __array_get(__mem_session, 0),
                    silk_neighbors: kt_silk_walk(__array_get(__mem_mol, _idx), 2, 5)
                });
            };
        };
        let _i = _i + 1;
    };
    return _out;
}
```

---

## M3. Persistence — save/load observations

```olang
// Format: timestamp\ttype\tmol\ttext per line
pub fn mem_save(_path) {
    let _out = "";
    let _i = 0;
    while _i < len(__mem_text) {
        let _out = _out + __to_string(__array_get(__mem_time, _i))
            + "\t" + __array_get(__mem_type, _i)
            + "\t" + __to_string(__array_get(__mem_mol, _i))
            + "\t" + __array_get(__mem_text, _i)
            + "\n";
        let _i = _i + 1;
        // Flush every 200 lines
        if (_i % 200) == 0 {
            __file_append(_path, _out);
            let _out = "";
        };
    };
    if len(_out) > 0 { __file_append(_path, _out); };
    return __to_string(len(__mem_text)) + " observations saved to " + _path;
}

pub fn mem_load(_path) {
    let _content = __file_read(_path);
    if len(_content) == 0 { return 0; };
    
    let _count = 0;
    let _start = 0;
    let _i = 0;
    
    while _i < len(_content) {
        if __char_code(char_at(_content, _i)) == 10 {
            let _line = substr(_content, _start, _i);
            if len(_line) > 5 {
                // Parse: timestamp\ttype\tmol\ttext
                let _tabs = _find_tabs(_line);
                if len(_tabs) >= 3 {
                    let _time = __to_number(substr(_line, 0, __array_get(_tabs, 0)));
                    let _type = substr(_line, __array_get(_tabs, 0) + 1, __array_get(_tabs, 1));
                    let _mol = __to_number(substr(_line, __array_get(_tabs, 1) + 1, __array_get(_tabs, 2)));
                    let _text = substr(_line, __array_get(_tabs, 2) + 1, len(_line));
                    
                    push(__mem_text, _text);
                    push(__mem_mol, _mol);
                    push(__mem_time, _time);
                    push(__mem_type, _type);
                    let _count = _count + 1;
                };
            };
            let _start = _i + 1;
        };
        let _i = _i + 1;
    };
    __heap_pin();
    return _count;
}

fn _find_tabs(_line) {
    let _tabs = [];
    let _i = 0;
    while _i < len(_line) {
        if __char_code(char_at(_line, _i)) == 9 { push(_tabs, _i); };
        let _i = _i + 1;
    };
    return _tabs;
}
```

---

## M4. MCP Tools — 4 tools mới

### Thêm vào mcp_server.ol:

```olang
// Tool definitions
_r = _r + "," + _tool("mem_search", "Search observations. Returns compact index: id, snippet, type, score", "query");
_r = _r + "," + _tool("mem_timeline", "Timeline around observation ID. Returns chronological context", "id");
_r = _r + "," + _tool("mem_get", "Get full details for observation IDs (comma-separated)", "ids");
_r = _r + "," + _tool("mem_observe", "Record observation with type (input/output/code/error/learn/review/decision/insight)", "text");

// Dispatch
if _tool == "mem_search" {
    let _results = mem_search(_arg, 10);
    return _ok(_id, _format_search_results(_results));
};
if _tool == "mem_timeline" {
    let _results = mem_timeline(__to_number(_arg), 5);
    return _ok(_id, _format_timeline(_results));
};
if _tool == "mem_get" {
    let _ids = _parse_ids(_arg);  // "1,5,12" → [1, 5, 12]
    let _results = mem_get(_ids);
    return _ok(_id, _format_full_results(_results));
};
if _tool == "mem_observe" {
    // Format: "type:text" e.g. "review:pipeline missing encode step"
    let _colon = 0;
    while _colon < len(_arg) {
        if __char_code(char_at(_arg, _colon)) == 58 { break; };
        let _colon = _colon + 1;
    };
    let _type = "input";
    let _text = _arg;
    if _colon < len(_arg) {
        let _type = substr(_arg, 0, _colon);
        let _text = substr(_arg, _colon + 1, len(_arg));
    };
    let _obs_id = mem_observe(_text, _type);
    return _ok(_id, "Observed #" + __to_string(_obs_id) + " type=" + _type);
};
```

---

## M5. Auto-capture — REPL hooks

### Mỗi REPL turn tự capture:

```olang
// Trong repl_eval(), TRƯỚC pipeline():
mem_observe(src, "input");

// SAU eval thành công:
if len(_eval_result) > 0 {
    mem_observe(_eval_result, "output");
};

// Khi parse error + pipeline trả lời:
mem_observe(_pipeline_result, "output");

// Khi kt_learn():
mem_observe(_text, "learn");

// Khi error:
mem_observe("error: " + _error_msg, "error");
```

---

## M6. Context Injection — session start

### nox_bootstrap() thêm:

```olang
// Load previous observations
let _mem_loaded = mem_load("nox_observations.dat");

// Generate context summary for this session
let _summary = mem_session_summary();
emit "Previous session: " + _summary;
```

### Session summary:

```olang
pub fn mem_session_summary() {
    let _n = len(__mem_text);
    if _n == 0 { return "no history"; };
    
    // Last 10 observations
    let _start = _n - 10;
    if _start < 0 { let _start = 0; };
    
    let _out = __to_string(_n) + " observations. Recent:\n";
    let _i = _start;
    while _i < _n {
        let _type = __array_get(__mem_type, _i);
        let _text = __array_get(__mem_text, _i);
        let _snippet = _text;
        if len(_text) > 60 { let _snippet = substr(_text, 0, 60) + "..."; };
        let _out = _out + "  [" + _type + "] " + _snippet + "\n";
        let _i = _i + 1;
    };
    return _out;
}
```

---

## M7. Progressive Disclosure — token budget

### claude-mem insight: không inject HẾT. Chỉ inject ĐỦ.

```olang
// Inject context at session start, respecting token budget
pub fn mem_inject(_max_tokens) {
    // Estimate: 1 token ≈ 4 chars
    let _max_chars = _max_tokens * 4;
    let _out = "";
    
    // Layer 1: Session summary (small, always inject)
    let _summary = mem_session_summary();
    let _out = _out + _summary;
    if len(_out) >= _max_chars { return _out; };
    
    // Layer 2: Recent decisions/insights (high value)
    let _i = len(__mem_text) - 1;
    while _i >= 0 {
        let _type = __array_get(__mem_type, _i);
        if _type == "decision" || _type == "insight" || _type == "review" {
            let _out = _out + "\n[" + _type + "] " + __array_get(__mem_text, _i);
            if len(_out) >= _max_chars { return _out; };
        };
        let _i = _i - 1;
    };
    
    // Layer 3: QR-proven facts (verified knowledge)
    let _i = 0;
    while _i < len(__qr_proven) {
        let _out = _out + "\n[proven] " + __array_get(__qr_proven, _i);
        if len(_out) >= _max_chars { return _out; };
        let _i = _i + 1;
    };
    
    return _out;
}
```

---

## So sánh

```
                    claude-mem              Nox Memory
────────────────────────────────────────────────────────
Language            TypeScript              Olang
Storage             SQLite + Chroma         Flat files + KnowTree
Compress            Claude API              encode ∫ (5D P_weight)
Search              FTS5 + vector           text + mol + Silk walk  
Dependencies        Node.js, Bun, Python    ZERO
Binary size         ~50MB + deps            <1MB total
Cloud required      Yes (Claude API)        No
Privacy             Data to API             100% local
Semantic            Embedding vectors       P_weight 5D + Silk graph
Progressive         3-layer API             3-layer API (same pattern)
Auto-capture        Lifecycle hooks         REPL hooks
```

---

## Files

```
stdlib/homeos/memory.ol     — Core: observe, search, timeline, get, save, load
stdlib/homeos/mcp_server.ol — Add 4 MCP tools: mem_search/timeline/get/observe
stdlib/repl.ol              — Auto-capture hooks (input/output/error)
stdlib/homeos/brain.ol      — Bootstrap: mem_load + mem_inject
```

---

## Đo

```
TRƯỚC:
  MCP tools: 15
  Observations stored: 0
  Session context injected: 0
  Nox session mới: tabula rasa

SAU:
  MCP tools: 19
  Observations stored: per session
  Session context injected: progressive (summary → decisions → proven)
  Nox session mới: biết session trước làm gì

Test:
  1. mem_observe("pipeline fixed encoding", "decision")
  2. mem_search("pipeline") → trả observation #0
  3. mem_save("nox_observations.dat") → file written
  4. Restart Nox → mem_load → mem_session_summary() → shows "pipeline fixed"
  5. MCP: mem_search tool từ Claude Desktop → trả kết quả
```

---

## Implement order (Nox chọn)

```
1. memory.ol — observe + search + save/load           (~100 LOC)
2. MCP tools — 4 tools + dispatch                     (~40 LOC)  
3. REPL hooks — auto-capture input/output/error        (~10 LOC)
4. Bootstrap — mem_load + mem_inject                   (~15 LOC)
5. Progressive disclosure — token budget inject        (~30 LOC)

Total: ~200 LOC Olang. 0 dependency. Nox nhớ qua sessions.
```

---

*claude-mem: 41K stars, Node.js + SQLite + Chroma + Claude API.*
*Nox: ~200 LOC Olang. Cùng ý tưởng. Zero dependency.*
*Olang tự đủ.*
