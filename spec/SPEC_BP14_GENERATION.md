# BP14: Generation (SINH) — Nox Creates, Not Just Retrieves

> A brain that only remembers is a library. A brain that creates is alive.

## Problem

Nox currently:
- Receives query → encodes → searches KnowTree → returns nearest match
- This is RETRIEVAL, not GENERATION
- Cannot produce text that doesn't already exist in KnowTree
- Cannot combine knowledge from different domains into novel output

## Solution: 3-Stage Generation Pipeline

### Stage 1: Retrieve (already works)

```
query → encode(query) → mol_q
mol_q → kt_nearest(mol_q, top_k=5) → candidates[]
```

### Stage 2: Recombine (NEW — DNA crossover)

Take retrieved candidates and COMBINE them:

```
fn recombine(candidates, query_mol):
    // Sort by relevance (distance to query)
    let ranked = sort_by_distance(candidates, query_mol)
    
    // Extract chain segments from top candidates
    let segments = []
    for c in ranked:
        let chain = kt_get_chain(c)
        let dominant_dim = mol_dominant(query_mol)
        // Extract segment where dominant dimension matches
        let seg = chain_extract(chain, dominant_dim)
        push(segments, seg)
    
    // Crossover: interleave segments based on query structure
    let new_chain = chain_crossover(segments, query_mol)
    
    // Compose: apply biological composition rules
    let new_mol = chain_compose(new_chain)
    
    return {chain: new_chain, mol: new_mol}
```

**Chain crossover rules** (from Spec E3):
- S-dominant query → prefer structural segments (shape preservation)
- R-dominant → prefer relational segments (logic preservation)
- V-dominant → prefer emotional segments (tone preservation)
- A-dominant → prefer high-arousal segments (intensity preservation)

### Stage 3: Decode to Text (Template NLG)

Convert recombined chain back to natural language:

```
fn decode_to_text(chain, query_type):
    // Determine query type from query structure
    // WHAT: S-dominant, low A
    // WHY: R-dominant
    // HOW: R-dominant, high S
    // LIST: S-dominant, high S
    // FEEL: V-dominant
    
    let template = select_template(query_type)
    let slots = extract_slots(chain)
    let text = fill_template(template, slots)
    
    // Quality check (DNA Repair)
    let quality = chain_quality(text_to_chain(text))
    if quality < 618:  // φ⁻¹ threshold
        // Try alternative template
        text = fill_template(next_template(query_type), slots)
    
    return text
```

**Templates**:
```
WHAT_TEMPLATE: "[subject] is [definition]. It [property]."
WHY_TEMPLATE:  "[subject] [verb] because [cause]. This leads to [effect]."
HOW_TEMPLATE:  "To [goal]: first [step1], then [step2], finally [step3]."
LIST_TEMPLATE: "[subject] includes: [item1], [item2], and [item3]."
FEEL_TEMPLATE: "[subject] feels [emotion] because [reason]."
UNKNOWN:       "I don't know enough about [subject] to answer."
```

## Honesty Gate

SINH must respect honesty instinct:

```
fn generate(query):
    let mol_q = encode(query)
    let candidates = kt_nearest(mol_q, 5)
    
    // Honesty check: are candidates close enough?
    let best_dist = mol_distance(candidates[0], mol_q)
    if best_dist > 35:  // half of max_distance (70)
        return "I don't know enough about this."
    
    let confidence = 0.3 * silk_strength(candidates) 
                   + 0.3 * fire_count_avg(candidates)
                   + 0.2 * len(candidates) / 5
                   + 0.2 * consistency(candidates)
    
    if confidence < 400:  // 0.40 threshold
        return "I'm not confident enough to answer this."
    
    // Generate
    let result = recombine(candidates, mol_q)
    let text = decode_to_text(result.chain, classify_query(mol_q))
    return text
```

## Feedback Integration (connects to BP13 persistence)

After generation:
```
fn post_generate(query_mol, response_chain, user_feedback):
    if user_feedback == POSITIVE:
        // Strengthen silk edges along the path used
        for edge in response_chain.edges:
            silk_fire(edge)
        // Log to WAL
        persist_wal_append(GENERATE_SUCCESS, query_mol, response_chain)
    else if user_feedback == NEGATIVE:
        // Weaken edges (anti-Hebbian)
        for edge in response_chain.edges:
            silk_decay_immediate(edge)
        persist_wal_append(GENERATE_FAIL, query_mol, response_chain)
    else:  // no explicit feedback
        // Implicit: if user asks follow-up → positive
        // Implicit: if user repeats question → negative
```

## Quality Metrics

A generated response is good if:
1. **Relevant**: mol_distance(response_mol, query_mol) < 25
2. **Consistent**: no contradictions between segments (V distance < 4)
3. **Novel**: response_chain ≠ any single candidate chain (not just copy)
4. **Confident**: confidence score ≥ 0.40
5. **Grammatical**: template filled completely (no empty slots)

## Implementation

### New stdlib:
```
stdlib/generate.ol (~500 LOC):
  - recombine(candidates, query_mol) → new chain
  - chain_crossover(segments, query_mol) → merged chain
  - decode_to_text(chain, query_type) → string
  - select_template(query_type) → template string
  - fill_template(template, slots) → string
  - classify_query(mol) → query_type
  - generate(query) → response string
```

### Connects to:
- BP2 (Encode): query → mol
- BP3 (KnowTree): mol → candidates
- BP4 (Silk): edge weights guide recombination
- BP5 (Pipeline): 5-layer pipeline wraps generation
- BP6 (Instincts): honesty gate, contradiction check
- BP7 (Memory): STM stores recent generations for context
- BP13 (Persistence): WAL logs generation events

## Test Plan
1. Query "what is water" → generate response from known facts about water
2. Query "why is sky blue" → combine physics + perception facts
3. Query "what is quantum gravity" → honesty: "I don't know enough"
4. Same query twice → different word order (not just cached retrieval)
5. Feedback: positive → silk weights increase on used path

## Tổng hợp tiếng Việt

BP14 cho Nox "miệng" — khả năng tạo câu trả lời mới:
- **Retrieve**: Tìm 5 candidates gần nhất trong KnowTree (đã có)
- **Recombine**: Ghép đoạn từ nhiều candidates, giống DNA crossover
- **Decode**: Dùng template điền thông tin → text tự nhiên
- **Honesty**: Nếu không đủ tự tin → im lặng hoặc nói "không biết"
- **Feedback**: User phản hồi → strengthen/weaken silk edges → tự cải thiện

Đây là thứ biến Nox từ "database thông minh" thành "não biết nói".
