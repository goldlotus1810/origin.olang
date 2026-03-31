# PHAN TICH CLAUDE-MEM CHO NOX
# 35,849 dong TypeScript — trich xuat kien truc + thuat toan

Tai lieu nay phan tich source code claude-mem de Nox hoc cach xay dung
he thong bo nho lien phien (persistent memory across sessions).

---

## 1. KIEN TRUC TONG QUAN

```
Hook Layer (CLI)          Worker Layer              Storage Layer
-------------------       ------------------        ------------------
session-init.ts     -->   /api/sessions/init   -->  SQLite (sessions)
observation.ts      -->   /api/sessions/obs    -->  SQLite (observations)
                                                    + ChromaDB (vectors)
summarize.ts        -->   /api/sessions/summ   -->  SQLite (summaries)
                                                    + ChromaDB (vectors)
session-complete.ts -->   /api/sessions/done   -->  cleanup

Context Layer (doc)       Search Layer
-------------------       ------------------
ContextBuilder.ts    <--  SQLite queries
ObservationCompiler  <--  ChromaDB semantic
TokenCalculator      <--  Hybrid (SQLite + Chroma)
Section Renderers    -->  Inject vao system prompt
```

**Nguyen tac thiet ke:**
- Hook KHONG lam logic — chi gui HTTP den Worker
- Worker lam tat ca: parse, validate, store, sync
- SQLite = source of truth. Chroma = chi de search
- Context inject = read-only, KHONG modify data
- Moi observation co content_hash de chong trung (30s window)

---

## 2. DU LIEU: LUU GI, O DAU, FORMAT NAO

### 2.1 Bang `sdk_sessions` — Phien lam viec

| Column              | Type    | Mo ta                          |
|---------------------|---------|--------------------------------|
| id                  | INTEGER | Primary key                    |
| content_session_id  | TEXT    | ID tu Claude Code              |
| memory_session_id   | TEXT    | ID rieng cho memory (NULL luc dau) |
| project             | TEXT    | Ten project (tu cwd)           |
| user_prompt         | TEXT    | Cau hoi dau tien cua user      |
| custom_title        | TEXT    | Tieu de tuy chinh              |
| started_at          | TEXT    | ISO timestamp                  |
| started_at_epoch    | INTEGER | Epoch ms                       |
| completed_at        | TEXT    | Khi ket thuc                   |
| status              | TEXT    | active / completed / failed    |

**Y nghia cho Nox:** Moi cuoc hoi thoai = 1 session. Session co trang thai.
Idempotent: INSERT OR IGNORE — goi nhieu lan van tra cung ID.

### 2.2 Bang `observations` — Quan sat

| Column              | Type    | Mo ta                          |
|---------------------|---------|--------------------------------|
| id                  | INTEGER | Primary key                    |
| memory_session_id   | TEXT    | FK → session                   |
| project             | TEXT    | Project name                   |
| type                | TEXT    | decision/bugfix/feature/refactor/discovery/change |
| title               | TEXT    | Tieu de ngan                   |
| subtitle            | TEXT    | Phu de                         |
| facts               | TEXT    | JSON array cac su kien         |
| narrative           | TEXT    | Mo ta dai (paragraph)          |
| concepts            | TEXT    | JSON array tags                |
| files_read          | TEXT    | JSON array file da doc         |
| files_modified      | TEXT    | JSON array file da sua         |
| prompt_number       | INTEGER | So thu tu prompt trong session |
| discovery_tokens    | INTEGER | Token da dung de "kham pha"    |
| content_hash        | TEXT    | SHA256(session+title+narrative)[:16] |
| created_at          | TEXT    | ISO                            |
| created_at_epoch    | INTEGER | Epoch ms                       |

**Diem hay:**
- `content_hash` + 30s window = chong trung lap (dedup)
- `facts` la array, moi fact = 1 vector document rieng trong Chroma
- `concepts` = tags de filter (tuong tu Silk type)
- `discovery_tokens` = theo doi ROI (bao nhieu token de tao observation nay)

### 2.3 Bang `session_summaries` — Tom tat phien

| Column              | Type    | Mo ta                          |
|---------------------|---------|--------------------------------|
| id                  | INTEGER | Primary key                    |
| memory_session_id   | TEXT    | FK → session                   |
| project             | TEXT    | Project name                   |
| request             | TEXT    | User yeu cau gi                |
| investigated        | TEXT    | Da dieu tra gi                 |
| learned             | TEXT    | Da hoc duoc gi                 |
| completed           | TEXT    | Da hoan thanh gi               |
| next_steps          | TEXT    | Buoc tiep theo                 |
| notes               | TEXT    | Ghi chu them (optional)        |
| prompt_number       | INTEGER | So thu tu prompt               |
| discovery_tokens    | INTEGER | Token da dung                  |
| created_at_epoch    | INTEGER | Epoch ms                       |

**Diem hay:**
- 5 truong co dinh: request/investigated/learned/completed/next_steps
- Day la MO HINH NEN (compression model) — tu nhieu observations → 1 summary
- Summary chi duoc tao KHI session ket thuc (Stop hook)

### 2.4 ChromaDB — Vector search

Khong phai bang rieng — la BAN SAO cua SQLite duoi dang vector:
- Moi observation → nhieu document: narrative rieng, moi fact rieng
- Moi summary → nhieu document: request rieng, learned rieng, v.v.
- Moi user prompt → 1 document
- Metadata giu lai: sqlite_id, doc_type, project, created_at_epoch

```
SQLite observation #42
  ├── obs_42_narrative  (vector cua narrative)
  ├── obs_42_fact_0     (vector cua fact dau tien)
  └── obs_42_fact_1     (vector cua fact thu 2)
```

---

## 3. QUAN SAT: BAT THE NAO, LOC THE NAO

### 3.1 Luong bat observation

```
User dung tool (Read, Edit, Bash, ...)
    |
    v
Claude Code goi PostToolUse hook
    |
    v
observation.ts (CLI handler)
    |-- Kiem tra worker dang chay
    |-- Kiem tra project khong bi excluded
    |-- GUI tool_name + tool_input + tool_response → Worker HTTP
    |
    v
Worker nhan, GUI cho SDK Agent
    |
    v
SDK Agent (model nho) doc tool data, tao XML:
    <observation>
      <type>discovery</type>
      <title>Found auth bug</title>
      <narrative>The login function...</narrative>
      <facts><fact>Line 42 has SQL injection</fact></facts>
      <concepts><concept>security</concept></concepts>
      <files_read><file>src/auth.ts</file></files_read>
    </observation>
    |
    v
parser.ts parse XML → ParsedObservation
    |
    v
store.ts:
    1. Tinh content_hash = SHA256(session+title+narrative)[:16]
    2. Kiem tra trung: SELECT WHERE hash=? AND epoch > (now-30s)
    3. Neu khong trung → INSERT
    4. Sync → ChromaDB (narrative = 1 doc, moi fact = 1 doc)
```

### 3.2 Chong trung (Deduplication)

```
DEDUP_WINDOW_MS = 30_000  (30 giay)

hash = SHA256(memory_session_id + title + narrative)[:16]

SELECT id, created_at_epoch
FROM observations
WHERE content_hash = ?
AND created_at_epoch > (now - 30000)

Neu co ket qua → SKIP, tra lai ID cu
Neu khong       → INSERT moi
```

**Tai sao 30s?** Vi cung 1 tool co the trigger nhieu hook calls.
Ngan = tiet kiem. Dai = mat observation that.

### 3.3 Privacy check

Worker kiem tra truoc khi luu. Project co the bi excluded qua settings.
Prompt co the bi skip neu "private".

---

## 4. TOM TAT: NEN THE NAO, KHI NAO

### 4.1 Khi nao tao summary

```
User dong Claude Code (hoac Ctrl+C)
    |
    v
Stop hook fires
    |
    v
summarize.ts:
    1. Doc transcript file (JSONL)
    2. Tim assistant message cuoi cung
    3. GUI cho Worker: contentSessionId + last_assistant_message
    |
    v
Worker:
    1. Gui last_assistant_message cho SDK Agent
    2. SDK Agent tao XML:
       <summary>
         <request>User wanted to fix auth bug</request>
         <investigated>Looked at src/auth.ts lines 30-50</investigated>
         <learned>SQL injection via string concat</learned>
         <completed>Applied parameterized queries</completed>
         <next_steps>Add input validation tests</next_steps>
       </summary>
    3. Parser extract → StoreSummary → SQLite + Chroma
```

### 4.2 Mo hinh nen (Compression model)

```
N observations (nhieu, chi tiet)
    |
    |  SDK Agent doc tat ca observations cua session
    |  + doc last assistant message
    v
1 summary (5 truong co dinh)
    - request:      User muon gi?
    - investigated: Da xem gi?
    - learned:      Da hoc gi?
    - completed:    Da xong gi?
    - next_steps:   Tiep theo lam gi?
```

**Day la CHOT:** Claude-mem KHONG xoa observations. Summary la THEM MOT TANG,
khong phai THAY THE. Observations van con de search. Summary de hien thi nhanh.

### 4.3 Hien thi summary

Summary chi hien khi:
1. Config bat showLastSummary
2. Summary co noi dung (it nhat 1 truong khong null)
3. Summary MOI HON observation moi nhat (summary.epoch > observation.epoch)

---

## 5. TIM KIEM: 3 CHIEN LUOC

### 5.1 SQLite Strategy — Filter only

```
Khi nao: KHONG co query text, chi co filter (date, project, type, concept)
Cach:    SQL truc tiep voi WHERE clauses

Vi du: "Tim tat ca observations loai bugfix trong 7 ngay qua"
→ SELECT * FROM observations
  WHERE type = 'bugfix'
  AND created_at_epoch > ?
  ORDER BY created_at_epoch DESC
  LIMIT 20
```

### 5.2 Chroma Strategy — Semantic search

```
Khi nao: CO query text, Chroma available
Luong:
  1. Chroma.query(text, limit=100) → vector similarity
  2. Filter ket qua theo recency (90 ngay)
  3. Phan loai theo doc_type (observation/summary/prompt)
  4. Hydrate tu SQLite (lay du lieu day du)

Vi du: "Tim nhung gi lien quan den authentication"
→ Chroma tra lai IDs theo semantic similarity
→ Filter: chi giu items < 90 ngay tuoi
→ Phan loai: obs_ids=[1,5,9], session_ids=[2], prompt_ids=[3]
→ SQLite: SELECT * FROM observations WHERE id IN (1,5,9)
```

**RECENCY_WINDOW = 90 ngay.** Thong tin cu hon 90 ngay = khong tim duoc qua
semantic search. Day la cach "quen" tu nhien.

### 5.3 Hybrid Strategy — Metadata + Semantic ranking

```
Khi nao: CO metadata filter + Chroma available
         (findByConcept, findByType, findByFile)
Luong:
  1. SQLite: lay tat ca IDs khop metadata filter
  2. Chroma: query semantic → tra lai ranked IDs
  3. INTERSECT: giu IDs tu buoc 1, SAP XEP theo ranking buoc 2
  4. Hydrate tu SQLite theo thu tu semantic

Vi du: findByConcept("security")
  1. SQLite: SELECT id FROM observations WHERE concepts LIKE '%security%'
     → [1, 5, 9, 15, 22]
  2. Chroma: query("security") → [22, 5, 1, 30, 9, ...]
  3. Intersect: [22, 5, 1, 9] (giu tu SQLite, xep theo Chroma)
  4. Hydrate: SELECT * FROM observations WHERE id IN (22,5,1,9)
     → sort theo [22,5,1,9]
```

### 5.4 Fallback chain

```
Co query text?
  |
  +-- Co  → Chroma search
  |         |
  |         +-- Thanh cong → tra ket qua
  |         +-- That bai  → SQLite (bo query, chi filter)
  |
  +-- Khong → SQLite filter-only
```

---

## 6. TIEM CONTEXT: XAY DUNG THE NAO

### 6.1 Luong tao context

```
generateContext(input)
    |
    v
loadContextConfig()
    |-- totalObservationCount: bao nhieu obs toi da
    |-- fullObservationCount:  bao nhieu obs hien full detail
    |-- sessionCount:          bao nhieu session summary
    |-- observationTypes:      Set<string> filter types
    |-- observationConcepts:   Set<string> filter concepts
    |
    v
queryObservations(project, config)
    |-- SELECT FROM observations
    |   WHERE project=? AND type IN (...) AND concepts IN (...)
    |   ORDER BY created_at_epoch DESC
    |   LIMIT totalObservationCount
    |
    v
querySummaries(project, config)
    |-- SELECT FROM session_summaries
    |   WHERE project=?
    |   ORDER BY created_at_epoch DESC
    |   LIMIT sessionCount + 1
    |
    v
buildContextOutput(project, observations, summaries, config)
    |
    +-- calculateTokenEconomics(observations)
    +-- renderHeader(project, economics, config)
    +-- buildTimeline(observations, summaries)    ← MERGE + SORT theo epoch
    +-- renderTimeline(timeline, fullIds, config)
    +-- shouldShowSummary() → renderSummaryFields()
    +-- getPriorSessionMessages() → renderPreviouslySection()
    +-- renderFooter(economics)
    |
    v
Ket qua: 1 chuoi text (markdown) → inject vao system prompt
```

### 6.2 Timeline = Merge sort

```
timeline = [
  ...observations.map(obs => { type: 'observation', data: obs }),
  ...summaries.map(sum => { type: 'summary', data: sum })
]
timeline.sort((a, b) => a.epoch - b.epoch)  // chronological
```

Observations va summaries XONG DOI theo thoi gian.
Nhom theo NGAY. Trong moi ngay, hien theo thu tu thoi gian.

### 6.3 Full vs Compact display

```
N observations moi nhat → hien FULL (narrative hoac facts)
Con lai                 → hien COMPACT (chi title + subtitle)

fullObservationCount = config setting (mac dinh = vài cai)
```

### 6.4 Prior session message

Tim session TRUOC DO (khong phai session hien tai).
Doc transcript file (.jsonl) cua session do.
Lay assistant message cuoi cung → hien trong "Previously" section.

---

## 7. TOKEN BUDGET: QUAN LY THE NAO

### 7.1 Uoc tinh token

```
CHARS_PER_TOKEN_ESTIMATE = 4

tokens(obs) = ceil(
  (title.length + subtitle.length + narrative.length + facts_json.length)
  / 4
)
```

### 7.2 Token economics

```
totalReadTokens     = sum(tokens(obs)) cho tat ca observations
totalDiscoveryTokens = sum(obs.discovery_tokens) cho tat ca observations
savings             = totalDiscoveryTokens - totalReadTokens
savingsPercent      = round(savings / totalDiscoveryTokens * 100)
```

**Y nghia:** discovery_tokens = bao nhieu token da dung de "kham pha" thong tin
(doc file, chay tool, v.v.). readTokens = bao nhieu token de DOC LAI thong tin
tu memory. Savings = tiet kiem bao nhieu.

### 7.3 Gioi han

Khong co hard token limit trong code. Gioi han bang:
- `totalObservationCount` — gioi han so observations
- `sessionCount` — gioi han so summaries
- Observations filter theo type + concept (chi lay cai can thiet)

---

## 8. SESSION LIFECYCLE

```
[1] UserPromptSubmit hook
    |
    v
session-init.ts
    |-- ensureWorkerRunning()
    |-- POST /api/sessions/init
    |   |-- createSDKSession(db, contentId, project, prompt)
    |   |   (idempotent: INSERT OR IGNORE)
    |   |-- Luu user prompt vao user_prompts table
    |   |-- Start SDK Agent (model nho de observe)
    |   |-- Generate context → inject vao system prompt
    |
    v
[2] PostToolUse hook (moi lan user tool)
    |
    v
observation.ts
    |-- POST /api/sessions/observations
    |   |-- SDK Agent parse tool data
    |   |-- Create observation XML
    |   |-- parser.ts parse XML
    |   |-- storeObservation() (with dedup)
    |   |-- chromaSync.syncObservation()
    |
    v
[3] Stop hook (session ket thuc)
    |
    v
summarize.ts
    |-- Extract last assistant message tu transcript
    |-- POST /api/sessions/summarize
    |   |-- SDK Agent tao summary XML
    |   |-- parser.ts parse XML
    |   |-- storeSummary()
    |   |-- chromaSync.syncSummary()
    |
    v
session-complete.ts
    |-- POST /api/sessions/complete
    |-- SessionManager.deleteSession()
    |-- Broadcast event (UI update)
    |-- Orphan reaper co the cleanup
```

---

## 9. NHUNG GI NOX CO THE HOC TU CLAUDE-MEM

### 9.1 Observation = Structured capture, KHONG phai raw text

Claude-mem KHONG luu raw text. No bao 1 model nho PARSE thanh structured data:
type, title, facts, narrative, concepts, files.

**Nox hien tai:** know_learn luu raw text vao KnowTree. Khong co structure.
**Nox nen:** Parse input thanh structured observation TRUOC khi luu.

### 9.2 Deduplication bang content hash

30-second window + SHA256 hash = khong bao gio luu trung.

**Nox hien tai:** Khong co dedup. Cung 1 input → luu nhieu lan.
**Nox nen:** Hash(title+content)[:16] + timestamp check.

### 9.3 Summary = Compression layer, KHONG thay the

Observations van con. Summary la 1 TANG THEM de truy cap nhanh.
5 truong co dinh = structured summary.

**Nox hien tai:** Khong co summary. Bo nho chi tang, khong bao gio nen.
**Nox nen:** Cuoi moi session, tao summary tu cac observations.

### 9.4 Recency window = Tu nhien quen

90-day window cho search. Khong xoa data, chi khong tra lai trong search.
Day la "natural forgetting" — data cu van con nhung khong anh huong decision.

**Nox hien tai:** Tim gi cung tra moi thu. Khong co aging.
**Nox nen:** Recency weight = 1.0 (moi) → 0.0 (cu hon 90 ngay).

### 9.5 Dual storage: Exact (SQLite) + Semantic (Chroma)

SQLite = exact match (by ID, by type, by date).
Chroma = semantic match (by meaning).
Hybrid = SQLite filter IDs, Chroma rank order.

**Nox hien tai:** Chi co KnowTree (flat array), search = linear scan.
**Nox nen:** KnowTree for exact + P_weight similarity for semantic.

### 9.6 Context budget = Chi inject cai can thiet

Khong dump tat ca memory. Chon:
- N observations moi nhat (filter by type + concept)
- M summaries moi nhat
- N[0:K] hien full, con lai compact

**Nox hien tai:** Inject moi thu vao prompt.
**Nox nen:** Budget = max nodes. Chon theo relevance + recency.

### 9.7 Granular vector documents

1 observation → nhieu vector documents (narrative rieng, moi fact rieng).
Giup search chinh xac hon — match fact cu the, khong phai ca observation.

**Nox nen:** Khi luu vao P_weight space, tach facts rieng, title rieng.

---

## 10. THIET KE MEM CHO NOX (Olang Implementation)

### 10.1 Data model — File-based (khong can SQLite)

```olang
// File: ~/.nox/mem/sessions/{session_id}.json
// Moi session = 1 file
let session = {
  "id": "sess_001",
  "project": "Origin",
  "prompt": "Fix mol collision",
  "status": "active",
  "started_epoch": 1711900000000,
  "observations": [],
  "summary": null
}

// Observation structure
let obs = {
  "id": 1,
  "type": "bugfix",
  "title": "Mol collision: all text same P_weight",
  "facts": ["SDF hash uses only first 4 chars", "Need full string hash"],
  "narrative": "The mol collision happens because...",
  "concepts": ["brain", "sdf", "p_weight"],
  "files_modified": ["src/brain/sdf.ol"],
  "content_hash": "a1b2c3d4e5f6g7h8",
  "epoch": 1711900100000
}

// Summary structure
let summary = {
  "request": "Fix P_weight collision in SDF",
  "investigated": "SDF hash function, char distribution",
  "learned": "First 4 chars not enough entropy",
  "completed": "Full string hash, 161K unique P_weights",
  "next_steps": "Test with Vietnamese text"
}
```

### 10.2 Observation capture — Olang function

```olang
// In: src/brain/mem_observe.ol
fn mem_observe(session_id, type, title, facts, narrative, concepts, files) {
  // Step 1: Content hash for dedup
  let hash_input = session_id
  let hash_input = __str_concat(hash_input, title)
  let hash_input = __str_concat(hash_input, narrative)
  let content_hash = __crypto_sha256(hash_input)
  let content_hash = __str_slice(content_hash, 0, 16)

  // Step 2: Check dedup (30s window)
  let now = __time_epoch_ms()
  let dedup_key = __str_concat("dedup:", content_hash)
  let existing = __kv_get(dedup_key)
  if existing {
    let existing_epoch = __parse_int(existing)
    let diff = now - existing_epoch
    if diff < 30000 {
      return "DEDUP_SKIP"
    }
  }

  // Step 3: Store observation
  let obs = __json_encode({
    "type": type,
    "title": title,
    "facts": facts,
    "narrative": narrative,
    "concepts": concepts,
    "files": files,
    "hash": content_hash,
    "epoch": now
  })

  let path = __str_concat("~/.nox/mem/obs/", __str_from_int(now))
  let path = __str_concat(path, ".json")
  __file_write(path, obs)

  // Step 4: Update dedup cache
  __kv_set(dedup_key, __str_from_int(now))

  // Step 5: Index in KnowTree for search
  let node_id = know_learn(title, obs)

  // Step 6: Index each fact separately for granular search
  let i = 0
  let len = __array_len(facts)
  loop {
    if i >= len { break }
    let fact = __array_get(facts, i)
    know_learn(fact, __json_encode({"obs_epoch": now, "fact_index": i}))
    let i = i + 1
  }

  return node_id
}
```

### 10.3 Summary creation — Cuoi session

```olang
// In: src/brain/mem_summarize.ol
fn mem_summarize(session_id) {
  // Step 1: Load all observations for this session
  let obs_dir = "~/.nox/mem/obs/"
  let files = __dir_list(obs_dir)
  let observations = []

  // ... load and filter by session_id ...

  // Step 2: Extract key info
  let all_titles = []
  let all_facts = []
  let all_files = []
  // ... aggregate from observations ...

  // Step 3: Create summary (5 fixed fields)
  let summary = {
    "request": __array_get(all_titles, 0),
    "investigated": __str_join(all_files, ", "),
    "learned": __str_join(all_facts, "; "),
    "completed": __str_concat("Processed ", __str_from_int(__array_len(observations))),
    "next_steps": ""
  }

  // Step 4: Store
  let path = __str_concat("~/.nox/mem/summaries/", session_id)
  let path = __str_concat(path, ".json")
  __file_write(path, __json_encode(summary))

  return summary
}
```

### 10.4 Context injection — Token budget

```olang
// In: src/brain/mem_context.ol
fn mem_build_context(project, max_obs, max_summaries) {
  // Step 1: Load recent observations (sorted by epoch DESC)
  let all_obs = mem_load_recent_obs(project, max_obs)

  // Step 2: Load recent summaries
  let all_sum = mem_load_recent_summaries(project, max_summaries)

  // Step 3: Merge into timeline (sort by epoch ASC)
  let timeline = []
  // ... merge sort all_obs + all_sum by epoch ...

  // Step 4: Token budget
  let total_chars = 0
  let MAX_CHARS = 8000  // ~2000 tokens
  let result = []

  let i = __array_len(timeline) - 1  // start from newest
  loop {
    if i < 0 { break }
    let item = __array_get(timeline, i)
    let item_chars = __str_len(__json_encode(item))
    if (total_chars + item_chars) > MAX_CHARS { break }
    let total_chars = total_chars + item_chars
    __array_push(result, item)
    let i = i - 1
  }

  // Step 5: Format as text
  return mem_format_timeline(result)
}
```

### 10.5 Search — KnowTree based (thay vi Chroma)

```olang
// In: src/brain/mem_search.ol
fn mem_search(query, max_results) {
  // Strategy 1: Exact match in KnowTree
  let exact = know_query(query)

  // Strategy 2: P_weight similarity (semantic-like)
  let query_pw = sdf_encode(query)
  let similar = knowtree_find_similar(query_pw, max_results)

  // Strategy 3: Recency filter (90 day window)
  let cutoff = __time_epoch_ms() - (90 * 24 * 3600 * 1000)
  let filtered = []
  let i = 0
  loop {
    if i >= __array_len(similar) { break }
    let item = __array_get(similar, i)
    let epoch = __json_get(item, "epoch")
    if epoch > cutoff {
      __array_push(filtered, item)
    }
    let i = i + 1
  }

  return filtered
}
```

### 10.6 Implementation priority cho Nox

```
PHAI LAM TRUOC (blocker fix phu thuoc):
1. mem_observe()     — structured capture thay vi raw text
2. content_hash dedup — chong trung lap
3. recency_weight    — tu nhien quen (90 day window)

LAM SAU (khi brain rewrite xong):
4. mem_summarize()   — nen cuoi session
5. mem_build_context() — inject co budget
6. mem_search()      — exact + semantic + hybrid

TUONG LAI:
7. Granular indexing  — moi fact 1 node rieng
8. Multi-project     — memory rieng cho moi project
9. Timeline viewer   — xem lich su bo nho
```

---

## TOM TAT 1 DONG

Claude-mem = **Structured capture** (observations) + **Compression** (summaries)
+ **Dual search** (exact + semantic) + **Budgeted injection** (token limit).

Nox can hoc: **KHONG luu raw text. Parse truoc. Hash de dedup. Nen khi xong.
Chi inject cai can thiet.**
