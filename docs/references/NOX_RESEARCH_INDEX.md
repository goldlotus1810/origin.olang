# NOX Research Index — External Knowledge Base

All research conducted 2026-04-01. Stored in `docs/research/`.

## Research Files

| # | File | Topic | Key Insight |
|---|------|-------|-------------|
| 01 | [virus_trojan_architecture](../research/01_virus_trojan_architecture.md) | How autonomous software survives in systems | 5 principles: parasitic execution, event-driven persistence, self-modifying code, redundant self-repair, substrate independence |
| 02 | [languages_similar_to_olang](../research/02_languages_similar_to_olang.md) | Programming languages comparison | Closest: MeTTa (AGI), NARS (reasoning), Forth (minimal bare-metal). None combine ALL Olang features. |
| 03 | [ai_models_similar_to_nox](../research/03_ai_models_similar_to_nox.md) | AI systems comparison | Closest: NARS (philosophy), DGM (self-modify), HTM (bio). No existing system = AI IS the OS. |
| 04 | [overcome_nox_limitations](../research/04_overcome_nox_limitations.md) | Solutions for 7 Nox limitations | All solvable with classical AI (1960s-1990s). ~2,650 LOC. No neural networks needed. |
| 05 | [ai_communication_networks](../research/05_ai_communication_networks.md) | AI-to-AI protocols, swarm, social | Stack: MCP (tools) + A2A (agents) + mDNS (discovery) + stigmergy (shared state) |
| 06 | [ai_controlling_systems](../research/06_ai_controlling_systems.md) | How AI controls machines | Universal pattern: existing interfaces + perception-reasoning-action loop |
| 07 | [underground_similar_projects](../research/07_underground_similar_projects.md) | Obscure/indie projects like Nox | (pending — agent searching Hackaday, HN, GitHub, Reddit) |

## Key External Systems to Study

| System | Why | URL |
|--------|-----|-----|
| **NARS** (Pei Wang) | Closest philosophy: AIKR, revisable beliefs, continuous learning | https://github.com/opennars/OpenNARS-for-Applications |
| **MeTTa** (OpenCog) | Closest language: AGI-specific, self-modifying, knowledge built-in | https://github.com/trueagi-io/hyperon-experimental |
| **Forth** | Closest implementation: minimal self-hosting bare-metal | https://github.com/kragen/stoneknifeforth |
| **ACT-R** | Closest learning model: activation + decay (like silk) | https://act-r.psy.cmu.edu/ |
| **DGM** (Sakana AI) | Self-modifying AI benchmark | https://sakana.ai/dgm/ |
| **HRR** (Tony Plate) | Solution for richer encoding | https://redwood.berkeley.edu/wp-content/uploads/2020/08/Plate-HRR-IEEE-TransNN.pdf |
| **A2A** (Google) | Agent-to-agent communication standard | https://google.github.io/A2A/ |
| **io_uring** | Async I/O for Nox body | https://kernel.dk/io_uring.pdf |

## Key Techniques to Implement

| Technique | For What | Effort | Source |
|-----------|----------|--------|--------|
| mmap persistence | Silk weights survive restart | ~400 LOC | Linux mmap(2) |
| Template NLG | Generation without LLM | ~500 LOC | ELIZA, commercial NLG |
| UCB1 bandit | Feedback/reinforcement | ~200 LOC | Multi-armed bandit theory |
| HRR encoding | Rich 64-byte representations | ~600 LOC | Tony Plate IEEE paper |
| Forth coop tasks | Concurrency | ~250 LOC | Brad Rodriguez paper |
| LRU + mmap | Break heap limit | ~400 LOC | OS demand paging |
| Agent Cards (A2A) | Network communication | ~300 LOC | Google A2A spec |
