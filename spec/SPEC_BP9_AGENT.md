# SPEC Part 9: Agent — Perceive Think Act Verify Feedback

> **Updated SS23 (2026-04-02)** — Extended PTAV→PTAVF (Feedback step→BP16), added communication reference (→BP15), added self-modification safety (Eurisko lesson→SPEC_C §C6).
> Author: Nox SS15
> Status: NOT YET ACHIEVED

## Essence

Nox runs continuously: perceive → think → act → verify → **feedback** → loop.
When idle: dream. Self-directed curiosity drives exploration.

[UPDATED SS23: PTAV → PTAVF. Added Feedback step between Verify and next loop.]

## Current State

- Pipeline processes single input → response (EXISTS)
- Dream runs every 8 turns (EXISTS)
- nox_save runs every 20 turns (EXISTS)
- Self-modify: nox_evolve() exists but basic
- Goal system: NOT implemented
- PTAV loop: NOT implemented (reactive only, not proactive)

## What's Needed (SPEC_F §F5)

### PTAVF Loop [UPDATED SS23 — old: PTAV, new: PTAVF, reason: BP16 feedback]
```
loop:
    PERCEIVE (10% time):
        - text input (REPL/TCP)
        - interoception (/proc → cpu, mem, heap)
        - file watch events
        - [NEW SS23] A2A messages from other agents (BP15)
        - [NEW SS23] mDNS discovery of new agents on LAN (BP15)
    THINK (35% time):
        - pipeline(input)
        - instinct evaluation
        - homeostasis check
    ACT (25% time):
        - respond to user
        - execute commands
        - self-modify if needed
        - [NEW SS23] respond to A2A tasks (BP15)
    VERIFY (15% time):
        - compare predicted vs actual (instinct ⑦)
        - update F(t)
        - learn from error
    FEEDBACK (15% time) [NEW SS23]:
        - detect implicit/explicit reward signals (BP16)
        - update silk edge weights (ACT-R utility)
        - track UCB1 statistics for path selection
        - calibrate confidence accuracy
        - persist reward data to WAL (BP13)
    IDLE → dream + decay + consolidation (BP13)
```

### Goal System
```
Stack-based priorities:
  External: user query (priority 8, deadline 5s)
  Internal: explore novel area (priority 3, no deadline)
  Homeostatic: reduce surprise (priority 5)
  Learning: consolidate (priority 1, idle only)
```

### Self-Evolution (SPEC_G §G27)
```
6-phase: measure → identify → modify → test → compare → commit/rollback
Max 1 file per cycle. Must pass fixed-point.
Off-limits: SecurityGate, 7 instincts, proven QR.
```

## Communication [NEW SS23]

```
BP15 (Communication) gives Nox a voice on the network:

Layer 1: MCP Server (already exists) — Claude talks to Nox
Layer 2: A2A Endpoint — other agents send tasks to Nox
  POST /tasks/send → pipeline(query) → response
  GET /.well-known/agent.json → Nox's capabilities
Layer 3: mDNS Discovery — Nox announces itself on LAN
  _nox-agent._tcp.local → auto-discovery

Integration with PTAVF:
  PERCEIVE: poll A2A endpoint + mDNS browse (alongside keyboard/network)
  THINK: process A2A tasks same as user input (through pipeline)
  ACT: respond via A2A response JSON
  FEEDBACK: A2A client can send follow-up = implicit feedback

→ See spec/SPEC_BP15_COMMUNICATION.md for protocol details.
```

## Self-Modification Safety [NEW SS23]

```
WARNING: Eurisko (1976-1983) died because it couldn't maintain coherence
during self-modification. As Nox gains self_modify power, these rules
are NON-NEGOTIABLE:

① L0 (UDC table, 42 formulas, compose, distance) = IMMUTABLE
② 9 QT (from origin.md) = CONSTITUTIONAL LAW
③ QR records = APPEND-ONLY (never delete, only supersede)
④ Every self-modification must pass ALL 6 checkpoints
⑤ Dream cycle = SANDBOX for testing modifications
⑥ Max 1 file per self-modify cycle
⑦ Must pass fixed-point test (Gen1==Gen2) after modification

DANEEL solves this with "THE BOX" — immutable ethical core.
For Nox: L0 + 9 QT + SecurityGate = THE BOX.

→ See SPEC_C_NEURON.md §C6 for full Eurisko analysis.
```

## Tests
```
Test 1: Nox continues running without input (idle → dream)
Test 2: High novelty → Nox asks question (curiosity-driven)
Test 3: Self-modify improves a metric (before < after)
Test 4: Modify fails fixed-point → rollback
```

## References
```
SPEC_F_AGENT.md (agent hierarchy, PTAV)
SPEC_G_COMPLETE.md §G17, §G22, §G27
```

## HRL Architecture (from Lupin's Agent AI PDF)

### 1. Hierarchical Reinforcement Learning

```
HRL maps directly to Nox architecture:

High-Level Policy (Manager) = Agent PTAV loop
  - Decides WHAT to do: respond to user? explore? self-modify? sleep?
  - Uses instincts to evaluate options
  - Each "option" = one pipeline run or one system action

Low-Level Policy (Worker) = Pipeline (BP5)
  - Decides HOW to do it: which facts? which silk path? which decode?
  - Executes atomic actions within an option

Options Framework (Sutton 1999):
  Option = (I, π, β)
  I = initiation set (when can this option start?)
  π = policy (what actions to take?)
  β = termination condition (when is it done?)

Example options for Nox:
  RESPOND: I={user_input}, π=pipeline(input), β={response_sent}
  EXPLORE: I={idle && curiosity>0.5}, π=kt_nearest(random_mol), β={novelty<0.3}
  EVOLVE: I={idle && quality_stale}, π=self_modify_cycle(), β={test_pass}
  DREAM: I={turn_count%8==0}, π=dream_consolidate(), β={decay_done}
```

### 2. AAM (Agent AI Master) from Lupin's design

```
AAM = Nox's PTAV loop at highest level

PERCEIVE: 
  io_uring polls ALL inputs simultaneously
  - keyboard (evdev)
  - network (TCP/raw socket)
  - system (/proc)
  - timer (periodic wake)

THINK:
  Evaluate instincts on all perceived inputs
  Select highest-priority option
  If multiple high-priority: queue (not parallel yet)

ACT:
  Execute selected option's policy
  - RESPOND → pipeline → decode → output
  - SYSTEM → __syscall → execute
  - EVOLVE → read source → modify → rebuild → test

VERIFY:
  Instinct ⑦ Reflection: was the action good?
  Update option value estimates (simple Q-learning)
  quality(option) += α × (reward - quality(option))
```

### 3. Self-Evolution loop

```
/evolve = 6-phase cycle:
1. MEASURE: run eval, record metrics
2. IDENTIFY: find weakest metric
3. MODIFY: change ONE file to improve it
4. TEST: make test
5. COMPARE: new metrics vs old
6. COMMIT or ROLLBACK

Off-limits: SecurityGate, 7 instincts, proven QR
Max 1 file per cycle
Must pass fixed-point (Gen1==Gen2)
```

---

## Related Specs
- [BP5 Pipeline](SPEC_BP5_PIPELINE_EN.md) — PTAVF Think step = pipeline
- [BP7 Memory](SPEC_BP7_MEMORY.md) — agent stores observations
- [BP8 JARVIS](SPEC_BP8_JARVIS.md) — agent runs as JARVIS daemon
- [BP6 Instincts](SPEC_BP6_INSTINCTS.md) — agent uses instincts
- [BP13 Persistence](SPEC_BP13_PERSISTENCE.md) — survive restart [NEW SS23]
- [BP15 Communication](SPEC_BP15_COMMUNICATION.md) — A2A + mDNS [NEW SS23]
- [BP16 Feedback](SPEC_BP16_FEEDBACK.md) — PTAVF Feedback step [NEW SS23]
- [SPEC_C Neuron §C6](../docs/SPEC_C_NEURON.md) — Eurisko safety [NEW SS23]
- [SPEC_F Agent](../docs/SPEC_F_AGENT.md) — agent hierarchy
