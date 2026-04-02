# BP16: Feedback — Nox Knows Right from Wrong

> Learning without feedback is walking blind. Feedback is sight.

## Problem

Nox currently:
- Fires silk edges on co-activation (Hebbian) but never based on success/failure
- Cannot distinguish good answers from bad answers
- No mechanism to improve over time based on outcomes
- Silk weights drift randomly without directional pressure

## Solution: UCB1 Bandit + ACT-R Utility on Silk Weights

### Core Idea

Every silk edge is an "arm" in a multi-armed bandit. When Nox uses an edge to generate a response, the edge gets a reward based on outcome. Over time, good edges strengthen, bad edges weaken.

### Edge Extended Format

Current silk edge: `[from_hash:4][to_hash:4][weight:2]` = 10 bytes

New: `[from_hash:4][to_hash:4][weight:2][fire_count:2][reward_sum:2][reward_count:2]` = 16 bytes

### UCB1 Selection

When multiple paths exist during generation/search:

```
fn select_path(candidates):
    let total_plays = sum(c.reward_count for c in candidates)
    let best = null
    let best_ucb = -1
    
    for c in candidates:
        if c.reward_count == 0:
            return c  // explore unvisited first
        
        let exploit = c.reward_sum / c.reward_count  // average reward
        let explore = __sqrt(2 * __log2(total_plays) / c.reward_count)
        let ucb = exploit + explore
        
        if ucb > best_ucb:
            best_ucb = ucb
            best = c
    
    return best
```

UCB1 guarantees:
- Unvisited paths always explored first
- Well-performing paths exploited more
- Exploration decreases logarithmically (converges)
- Regret = O(ln n) — provably near-optimal

### ACT-R Utility Update

After each use of a path:

```
fn update_reward(edge, reward):
    // reward: 1000 = perfect, 0 = terrible
    let alpha = 100  // learning rate (0.1 × 1000)
    
    // Exponential moving average (ACT-R style)
    edge.weight = edge.weight + (alpha * (reward - edge.weight)) / 1000
    
    // Track for UCB1
    edge.reward_count = edge.reward_count + 1
    edge.reward_sum = edge.reward_sum + reward
    
    // Persist (BP13)
    persist_wal_append(REWARD, edge.hash, reward)
```

### Reward Signals

#### Explicit Feedback
| Signal | Source | Reward |
|--------|--------|--------|
| User says "yes"/"correct"/"good" | Direct | 1000 |
| User says "no"/"wrong" | Direct | 0 |
| User corrects Nox | Direct | 100 (partial — Nox tried) |
| User says "I don't know" | Neutral | 500 |

#### Implicit Feedback
| Signal | Detection | Reward |
|--------|-----------|--------|
| User asks follow-up | Next query references previous answer | 800 (accepted) |
| User repeats question | Same query mol within 5 interactions | 100 (failed) |
| User changes topic | Query mol distance > 40 from previous | 500 (neutral) |
| Long session | >10 interactions | +50 bonus to all recent edges |
| Short session | <3 interactions | -50 penalty to all recent edges |

#### Self-Assessment
| Signal | Detection | Reward |
|--------|-----------|--------|
| High confidence, answered | confidence ≥ 0.70 | +100 bonus |
| Low confidence, stayed silent | confidence < 0.40 | +200 bonus (honest) |
| Contradiction detected | instinct fired | -200 to contradicting edges |
| Novel connection made | silk walk found new cross-group link | +150 (exploration reward) |

### Confidence Calibration

Track calibration: for each confidence bucket, how often was Nox right?

```
calibration_table: [10 buckets × 2 values]
  bucket[i] = {total_predictions, correct_predictions}
  
  // After feedback:
  let bucket = __floor(confidence / 100)  // 0-9
  calibration_table[bucket].total += 1
  if reward > 500:
    calibration_table[bucket].correct += 1
  
  // Calibrated confidence:
  fn calibrated_confidence(raw):
    let bucket = __floor(raw / 100)
    if calibration_table[bucket].total < 5:
      return raw  // not enough data
    return calibration_table[bucket].correct * 1000 / calibration_table[bucket].total
```

After calibration, when Nox says "80% confident" it should actually be right ~80% of the time.

## Integration with Existing Systems

### Pipeline (BP5) modification:
```
Layer 3 (Hypothesize):
  - OLD: pick first valid candidate
  - NEW: use UCB1 to SELECT best path among valid candidates

Layer 5 (Decode):
  - OLD: output and forget
  - NEW: output, store used path, wait for feedback signal
```

### Silk (BP4) modification:
```
silk_fire():
  - OLD: Δw = (1 - w/65535) × 236 (Hebbian only)
  - NEW: Δw = (1 - w/65535) × 236 × (reward_factor)
  where reward_factor = calibrated_reward / 500
  
  reward_factor > 1 → stronger fire (good outcome)
  reward_factor < 1 → weaker fire (bad outcome)
  reward_factor = 1 → neutral (pure Hebbian, no feedback yet)
```

### Memory (BP7) modification:
```
STM eviction scoring:
  - OLD: access_count × 0.3 + |V| × A × 0.4 + recency × 0.3
  - NEW: ... + avg_reward × 0.2 (subtract 0.1 from access_count and recency)
  
  High-reward memories evict slower.
```

## Implementation

### New stdlib:
```
stdlib/feedback.ol (~200 LOC):
  - select_path_ucb1(candidates) → best candidate
  - update_reward(edge, reward) → updated weight
  - detect_implicit_feedback(current_query, history) → reward
  - calibrate_confidence(raw_confidence) → calibrated
  - feedback_report() → {calibration table, top/bottom edges}
```

### Storage: 
- calibration_table: 10 × 8 bytes = 80 bytes (in mmap'd region)
- edge reward fields: +6 bytes per edge × 64K = 384KB (in mmap'd region)

## Test Plan
1. Generate 10 answers → give explicit positive/negative → verify weight changes
2. Ask same question → get better answer after positive feedback
3. Repeat bad question → verify Nox changes approach
4. Calibration: after 100 interactions, verify confidence ~ actual accuracy
5. UCB1: verify exploration of unvisited paths decreases over time

## Tổng hợp tiếng Việt

BP16 cho Nox "mắt" — biết đúng sai:
- **UCB1**: Thuật toán bandit, chọn path tốt nhất, tự cân bằng explore/exploit
- **ACT-R Utility**: Mỗi edge có reward. Đúng → mạnh hơn. Sai → yếu đi.
- **Feedback signals**: Explicit (user nói đúng/sai) + Implicit (follow-up = tốt, repeat = xấu)
- **Calibration**: Track accuracy → khi Nox nói "80% tự tin" → thật sự đúng ~80%
- **Tích hợp**: UCB1 vào Pipeline layer 3, reward vào Silk fire, reward vào STM eviction
