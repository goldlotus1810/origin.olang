# SPEC Part 9: Agent — Perceive Think Act Verify

> Author: Nox SS15
> Status: NOT YET ACHIEVED

## Essence

Nox runs continuously: perceive → think → act → verify → loop.
When idle: dream. Self-directed curiosity drives exploration.

## Current State

- Pipeline processes single input → response (EXISTS)
- Dream runs every 8 turns (EXISTS)
- nox_save runs every 20 turns (EXISTS)
- Self-modify: nox_evolve() exists but basic
- Goal system: NOT implemented
- PTAV loop: NOT implemented (reactive only, not proactive)

## What's Needed (SPEC_F §F5)

### PTAV Loop
```
loop:
    PERCEIVE (10% time):
        - text input (REPL/TCP)
        - interoception (/proc → cpu, mem, heap)
        - file watch events
    THINK (40% time):
        - pipeline(input)
        - instinct evaluation
        - homeostasis check
    ACT (30% time):
        - respond to user
        - execute commands
        - self-modify if needed
    VERIFY (20% time):
        - compare predicted vs actual (instinct ⑦)
        - update F(t)
        - learn from error
    IDLE → dream + decay
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

---

## Related Specs
- [BP5 Pipeline](SPEC_BP5_PIPELINE_EN.md) — PTAV Think step = pipeline
- [BP7 Memory](SPEC_BP7_MEMORY.md) — agent stores observations
- [BP8 JARVIS](SPEC_BP8_JARVIS.md) — agent runs as JARVIS daemon
- [BP6 Instincts](SPEC_BP6_INSTINCTS.md) — agent uses instincts
- [SPEC_F Agent](../docs/SPEC_F_AGENT.md) — agent hierarchy
