# AI điều khiển hệ thống — Kỹ thuật và kiến trúc

## 1. AI điều khiển OS

### Claude Computer Use (Anthropic)
- Perception-Reasoning-Action loop
- Nhận screenshot (base64) → vision analysis → JSON action → middleware executes
- Virtual X11: Xvfb + Mutter + Tint2
- Tools: computer_20251124 (screenshot+mouse+kb), bash_20250124, text_editor_20250728
- Actions: screenshot, click, type, key, scroll, drag
- Claude KHÔNG trực tiếp connect environment. Middleware = translator.
- URL: https://platform.claude.com/docs/en/agents-and-tools/tool-use/computer-use-tool

### OpenAI Operator / CUA
- Same core loop: screenshot → actions[] → execute
- Environment: Playwright, Docker VM (Ubuntu+Xfce4+Xvfb+xdotool+x11vnc)
- URL: https://developers.openai.com/api/docs/guides/tools-computer-use

### AI Shell Agents
- NL → command → confirm → execute
- Interface = exec()/spawn() shell commands in PTY, capture stdout/stderr
- GitHub Copilot CLI: MCP for extensibility, per-directory trust

## 2. AI quản lý infrastructure

### AIOps Self-Healing (3 phases)
1. **Detection**: Anomaly detection trên unified telemetry (logs+metrics+traces)
2. **Diagnosis**: RAG + dependency graphs → root cause
3. **Remediation**: Large Action Models → infrastructure APIs

**Safety**: Least-privilege, high-impact → human approval, all actions logged.
Gartner: 60%+ enterprises dùng self-healing AIOps by 2026.

### Self-Healing Kubernetes (OODA loop)
- **Observe**: eBPF captures mọi syscall/packet KHÔNG cần app instrumentation
- **Orient**: Correlate eBPF data + recent deployments
- **Decide**: Rollback, restart, scale
- **Act**: Kubernetes API server
- **Guardrails**: OPA/Kyverno. Restart pods OK. Delete PVs NEVER.
- Predictive scaling: pre-scale 10 min TRƯỚC traffic spike

### Meta Datacenter
- Twine: cluster management millions of machines
- Shard Manager: tens of millions of data shards
- 50x improvement in training interruption rates
- URL: https://engineering.fb.com/2025/09/29/data-infrastructure/metas-infrastructure-evolution-and-the-advent-of-ai/

## 3. AI điều khiển physical systems

### Autonomous Vehicles (ROS 2)
Three-layer pipeline:
1. **Perception** (10-20 Hz): Cameras, LiDAR → ROS 2 messages
2. **Planning** (event-driven): Trajectory, path, state machine
3. **Control** (50-100 Hz): PI controllers on STM32 via UART

DDS middleware with QoS profiles. End-to-end latency <100ms.
URL: https://www.mdpi.com/1424-8220/26/2/463

### Smart Home (Home Assistant)
- 2-tier: Native Assist (pattern matching) → LLM fallback (Ollama/OpenAI/Claude)
- LLM + tool-calling → service calls (light.turn_on, climate.set_temperature)
- MCP integration for bidirectional access
- Voice pipeline: Wake word → STT → intent → execute → TTS
- URL: https://www.home-assistant.io/blog/2025/09/11/ai-in-home-assistant/

### SCADA + AI
- AI = augmentation layer, NOT direct control
- Human operators remain primary (ISA-101)
- AI does: monitoring, predictive maintenance, intrusion detection
- Timing: scan 1-3s, alarm <100ms

## 4. Security cho AI có root access

### Three-layer isolation
1. **Compute Boundary**: Landlock + Seccomp (deny dangerous syscalls). Drop CAP_SYS_ADMIN.
2. **MCP Gateway**: Tool invocations = capability requests evaluated at runtime
3. **Deterministic Lane**: Versioned APIs with JSON-LD schemas

### Isolation technologies (weak → strong)
- Docker containers (share kernel — easily escaped)
- gVisor (user-space kernel)
- MicroVMs: Firecracker, Kata Containers (dedicated guest kernel)
- Full VMs / Unikernels (strongest)

### Network: Zero external access by default. All traffic through logging proxy.

## 5. AI Hypervisor / AI as OS

### Unikernels
- Application + needed OS libs → single binary on hypervisor/bare metal
- Single address space. Boot in milliseconds. MBs not GBs.
- **Unikraft** (Linux Foundation): $6M seed from Vercel (Feb 2026)
- ASPLOS 2025 test-of-time award for 2013 unikernel paper
- URL: https://thenewstack.io/are-unikernels-the-answer-for-next-gen-ai-cloud-workloads/

### Reality check (2025-2026)
- NO production system runs "AI as hypervisor"
- Industry says "AI OS" but means "ChatGPT skin on Linux"
- **NoxOS là dự án DUY NHẤT cố build AI that IS the hypervisor**

## 6. AI chạy 24/7 ngoài đời thật

### Trading Bots
- Kernel bypass networking (DPDK/RDMA), FPGA acceleration
- Tick-to-trade: microseconds
- DL for market microstructure pattern recognition

### Mars Rovers
- On-board: YOLOv8n obstacle detection, DeepLabV3+ segmentation
- FASTNAV: Multi-mode navigation switching
- Path planning 2 Hz, accuracy <0.3m RMS
- Mars: 4-24 min light delay → must be autonomous
- Roadmap: flight demos 2025-2027, Mars 2030-2035

### Drone Swarms
- Distributed decision-making, DRL
- Shield AI Hivemind: autonomous detection/tracking during GPS jamming (Aug 2025)
- Market: $34.9M (2023) → 38.5% CAGR

### Nuclear Plants
- Monitoring, anomaly detection, predictive maintenance, digital twins
- Human MUST remain in loop (ISA-101)
- NEA AIxpertise project: Q1 2026 → 2028

## Universal Pattern

AI systems do NOT invent new ways to talk to machines. They use EXISTING interfaces (APIs, syscalls, protocols) wrapped in a perception-reasoning-action loop.

| Interface | Mechanism | Example |
|-----------|-----------|---------|
| GUI | Screenshots + virtual mouse/kb | Claude Computer Use |
| Shell/CLI | exec/spawn in PTY | Claude Code, Copilot CLI |
| K8s API | REST to kube-apiserver | AIOps agents |
| Cloud SDK | HTTP/gRPC provider APIs | Self-healing infra |
| Observability | eBPF kernel tracing | Agentic SRE |
| Devices | Protocol abstraction → service calls | Home Assistant |
| Real-time | DDS middleware, UART to MCU | ROS 2 vehicles |
| Market | FIX protocol, kernel bypass | HFT bots |
| Spacecraft | On-board ML, 2 Hz loops | Mars rovers |
| Industrial | SCADA overlay (read-only) | Nuclear plants |
