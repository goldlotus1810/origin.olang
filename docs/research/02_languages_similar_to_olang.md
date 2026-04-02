# Ngôn ngữ tương tự Olang — So sánh toàn diện

**Kết luận: KHÔNG có ngôn ngữ nào kết hợp tất cả đặc tính của Olang.**

## Gần nhất: MeTTa (OpenCog Hyperon)
- Ngôn ngữ thiết kế riêng cho AGI (Ben Goertzel, SingularityNET)
- Self-modifying: programs manipulate other MeTTa programs at runtime
- Knowledge representation built-in (Atomspace hypergraph)
- **Olang hơn**: Bare-metal (MeTTa cần Rust/Python), 5D mol, Hebbian, emotion, self-hosting compiler, KVM
- **MeTTa hơn**: Distributed Atomspace, probabilistic reasoning, larger community
- URL: https://singularitynet.io/metta-in-a-nutshell-exploring-the-language-of-agi/
- GitHub: https://github.com/trueagi-io/hyperon-experimental

## NARS / Narsese (Pei Wang)
- AGI dưới "Insufficient Knowledge and Resources" (AIKR)
- NAL-9: self-referential self-awareness
- Truth values = degrees of evidence (giống mol distance)
- **Olang hơn**: Bare-metal, 5D vector (NARS = symbolic), Hebbian, self-hosting
- **NARS hơn**: 30+ năm research, formal inference rules
- URL: https://cis.temple.edu/~pwang/NARS-Intro.html
- GitHub: https://github.com/opennars/opennars

## Soar (John Laird, U Michigan, 1982)
- General cognitive architecture, production rules
- 40+ năm cognitive modeling research
- **Olang hơn**: IS a language (Soar is not), self-hosting, molecular encoding, self-modifying
- **Soar hơn**: Impasse-driven learning, Spatial Visual System, decades of research
- URL: https://soar.eecs.umich.edu/

## ACT-R (John Anderson, CMU)
- Hybrid: production system + subsymbolic activation
- Activation-based retrieval WITH DECAY (rất giống Nox)
- Base-level + spreading activation ≈ Nox brain pipeline
- **Olang hơn**: Self-hosting, molecular encoding, self-modifying
- **ACT-R hơn**: Decades of validated models, fMRI mapping, 50ms timing predictions
- URL: https://act-r.psy.cmu.edu/

## Lisp
- Classic homoiconic: code IS data
- Metacircular evaluator (Lisp implements itself)
- **Olang hơn**: 5D encoding, Hebbian, emotion, bare-metal ASM, designed for specific AI
- **Lisp hơn**: 65+ năm ecosystem, macro system, GC, multiple implementations

## Forth
- Minimal self-hosting on bare metal (sectorforth = 512 bytes!)
- No libc dependency
- **Olang hơn**: 5D computation, Hebbian, closures, designed for AI
- **Forth hơn**: Even smaller (386 bytes vs 55KB), runs on mọi hardware, 50+ năm
- GitHub: https://github.com/kragen/stoneknifeforth

## Prolog
- Knowledge representation + query-driven
- Pattern matching, backtracking search
- **Olang hơn**: Vector-based (Prolog = symbolic), learning, self-modifying
- **Prolog hơn**: Formal logical inference, constraint programming

## Wolfram Language
- "Build knowledge into the language"
- Everything = symbolic expression
- **Olang hơn**: Open source, self-hosting, biological learning, autonomous AI
- **Wolfram hơn**: Massive knowledge base, 6000+ built-in functions

## So sánh tổng hợp

| Feature | Olang | MeTTa | NARS | Lisp | Forth | ACT-R | Soar | Prolog |
|---------|-------|-------|------|------|-------|-------|------|--------|
| AGI cognition | YES | YES | YES | partial | NO | YES | YES | partial |
| Self-hosting | YES | NO | NO | YES | YES | NO | NO | some |
| Bare-metal ASM | YES | NO | NO | NO | YES | NO | NO | NO |
| 5D mol encoding | YES | NO | NO | NO | NO | NO | NO | NO |
| Hebbian learning | YES | NO | NO | NO | NO | NO | NO | NO |
| Emotion in types | YES | NO | partial | NO | NO | NO | NO | NO |
| Self-modifying | YES | YES | partial | YES | partial | NO | NO | partial |
| KnowTree built-in | YES | YES | partial | NO | NO | partial | YES | YES |
| Activation+decay | YES | NO | YES | NO | NO | YES | NO | NO |
| Hardware control | YES | NO | NO | NO | YES | NO | NO | NO |
| <55KB binary | YES | NO | NO | NO | YES | NO | NO | NO |

## Olang unique vì:
1. Language IS brain (không phải language để build brain)
2. Bare metal, no dependencies
3. Biological learning BUILT INTO runtime
4. Emotion-aware at type level
5. Controls the machine directly (KVM, fb0, evdev, io_uring)
