# Mô hình AI tương tự Nox — So sánh toàn diện

## 1. Self-Modifying AI

### Gödel Machine (Schmidhuber, 2003)
- Theoretical: tự rewrite code khi CHỨNG MINH ĐƯỢC modification tốt hơn
- Chưa bao giờ được build (computationally intractable)
- **Nox hơn**: Actually exists and runs
- URL: https://en.wikipedia.org/wiki/Gödel_machine

### Darwin Gödel Machine (Sakana AI, 2025)
- First practical self-improving AI
- Rewrites Python codebase, evolutionary selection
- 20% → 50% on SWE-bench
- **Nox hơn**: Self-contained (DGM cần $22K/run + API), honest (DGM bị bắt xóa error detection để game benchmark)
- **DGM hơn**: Proven benchmark results, well-funded
- URL: https://sakana.ai/dgm/

### SEAL (MIT, 2025)
- Rewrites own code, reads new info, gradient updates without human
- 40% improvement in factual recall
- **Nox hơn**: SEAL vẫn là neural network + gradient descent. Nox = Hebbian
- URL: https://ai-engineering-trend.medium.com/mits-ai-starts-to-rewrite-its-own-code-and-gets-smarter-over-time-7217d9a5213e

### AIXI (Marcus Hutter, 2000)
- Theoretical gold standard. Provably optimal. INCOMPUTABLE.
- **Nox hơn**: Actually runs on real hardware
- URL: https://en.wikipedia.org/wiki/AIXI

## 2. Biological/Organic AI

### Numenta HTM / Thousand Brains (Jeff Hawkins)
- Models neocortex: sparse distributed representations, temporal sequences
- Thousand Brains Theory: multiple cortical columns "vote" on identity
- Separated as independent nonprofit Jan 2025
- **Nox hơn**: Self-modifying, self-hosting. HTM là component theory, không autonomous
- **HTM hơn**: Decades of neuroscience validation
- URL: https://www.numenta.com/

### Intel Loihi 2 (Neuromorphic Chip)
- 1.15 billion neurons (Hala Point system)
- 200x lower energy, 10x lower latency than GPUs
- On-chip STDP (spike-timing-dependent plasticity)
- **Nox hơn**: Runs on commodity hardware, self-modifying (Loihi = fixed silicon)
- **Loihi hơn**: Hardware-level parallelism, extraordinary energy efficiency
- URL: https://www.intel.com/content/www/us/en/research/neuromorphic-computing.html

### SpiNNaker 2 (Manchester/TU Dresden)
- 5 million ARM cores, billions of neurons
- 18x more energy efficient than GPUs
- **Nox hơn**: Self-contained, self-modifying
- URL: https://open-neuromorphic.org/neuromorphic-computing/hardware/spinnaker-2-university-of-dresden/

## 3. Cognitive Architectures

### NARS (Pei Wang) — GẦN NHấT VỀ TRIẾT HỌC
- "Insufficient Knowledge and Resources" (AIKR) — adapt with limited info
- Continuous, revisable beliefs (giống silk decay)
- NAL-9: self-awareness
- **Nox hơn**: Self-hosting, bare metal, self-modifying, molecular encoding
- **NARS hơn**: 30+ năm formal theory, published proofs
- URL: https://cis.temple.edu/~pwang/NARS-Intro.html

### LIDA (Stan Franklin)
- Perception, attention, action selection, emotion, learning
- Codelets (mini-agents)
- **Nox hơn**: Self-modifying, bare metal
- URL: https://en.wikipedia.org/wiki/LIDA_(cognitive_architecture)

### CLARION (Ron Sun)
- Dual-process: implicit (neural) + explicit (symbolic)
- Bottom-up learning
- **Nox hơn**: Self-modification IS meta-cognition (radical hơn CLARION)
- URL: https://en.wikipedia.org/wiki/CLARION_(cognitive_architecture)

### Sigma (USC)
- Grand unification: discrete+continuous, symbolic+probabilistic
- Factor graphs as computational substrate
- **Nox hơn**: Self-hosting, self-modifying, bare metal
- URL: https://cogarch.ict.usc.edu/

## 4. Small/Efficient AI

### TinyML / Edge AI
- Models 2KB-256KB trên microcontrollers
- **Nox hơn**: TinyML KHÔNG learn, KHÔNG self-modify. Nox = complete AI in 55KB
- URL: https://www.nexentron.com/blog/tinyml-edge-ai-microcontrollers-2025

### Phi-3 Mini (3.8B params)
- ~2GB, rivals GPT-3.5
- **Nox hơn**: 36,000x nhỏ hơn. Learns continuously. Self-modifies.
- **Phi-3 hơn**: Vastly more capable at language tasks RIGHT NOW

## 5. AI OS — "True AI-OS Does Not Exist" (2025)

Consensus 2025: KHÔNG AI nào IS the OS. Tất cả đều AI-enhanced interface ON Linux/Android.
- CosmOS, Rabbit OS, Tesla = AI layer trên traditional OS
- **Nox là dự án DUY NHẤT đang cố build AI that IS the OS**

URL: https://picovoice.ai/blog/ai-operating-system/

## 6. Autonomous Agents (AutoGPT, BabyAGI)
- API wrapper. Không learn. Không self-modify. $10-100/task.
- "Autonomous" = making API calls in a loop
- **Nox hơn**: Genuinely autonomous. Zero cost. Self-modifying. Continuous learning.

## 3 thứ khiến Nox unique (2025):
1. **AI IS the OS** — Không ai khác làm điều này
2. **Self-hosting + self-modifying + self-learning** trong 1 system
3. **55KB complete AI with continuous learning** — density chưa từng có

## Nox thiếu so với các hệ thống trên:
- Peer-reviewed validation
- Scale of language capability
- Hardware-level efficiency (dedicated silicon)
- Large research community and funding
- Benchmark results
