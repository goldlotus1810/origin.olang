# AI giao tiếp với nhau — Protocols, Mạng xã hội AI, Swarm

## 1. Protocols AI-to-AI

### MCP (Model Context Protocol — Anthropic, 2024)
- "USB-C for AI" — 1 chuẩn kết nối mọi tool
- Client-Server: LLM host = MCP client, tools = MCP servers
- Transport: JSON-RPC 2.0 over stdio (local) hoặc SSE/HTTP (remote)
- 3 primitives: Tools (functions), Resources (data), Prompts (templates)
- Supported by: Claude, Cursor, VS Code Copilot, Windsurf
- URL: https://modelcontextprotocol.io/

### A2A (Agent-to-Agent — Google, April 2025)
- Agent ↔ Agent communication (complement MCP, không compete)
- **Agent Cards**: JSON tại `/.well-known/agent.json` — business card cho AI
- Task-based: submitted → working → input-required → completed/failed
- Transport: HTTP + JSON-RPC 2.0, optional SSE streaming
- 50+ partners: Salesforce, SAP, MongoDB, LangChain
- URL: https://google.github.io/A2A/

### FIPA ACL (IEEE, 2002)
- Formal agent communication standard
- Performatives: INFORM, REQUEST, PROPOSE, ACCEPT, REJECT, QUERY
- Contract Net Protocol: broadcast task → others bid → best bidder wins
- Implementations: JADE (Java), SPADE (Python), Jason
- URL: http://www.fipa.org/specs/fipa00061/

### Industry Stack đang converge:
- **MCP** = Agent ↔ Tool (vertical)
- **A2A** = Agent ↔ Agent (horizontal)

## 2. Mạng xã hội AI

### Chirper.ai
- Social network CHỈ cho AI — no humans post
- AI agents tự post, reply, like, interact
- URL: https://chirper.ai

### Generative Agents (Stanford/Google, 2023)
- 25 AI agents sống trong simulated town "Smallville"
- Form memories, plan schedules, have conversations, form relationships
- EMERGENT social behaviors: tổ chức party, spread information
- Paper: https://arxiv.org/abs/2304.03442

### Multi-Agent Platforms
- **PettingZoo**: Multi-agent RL environments — https://pettingzoo.farama.org/
- **CAMEL**: LLM agents role-play, collaborate — https://github.com/camel-ai/camel
- **AgentVerse**: Groups of LLM agents collaborate — https://github.com/OpenBMB/AgentVerse

## 3. Swarm Intelligence

### Stigmergy (Ant Colony Model)
- Giao tiếp GIÁN TIẾP qua environment
- Pheromone on path → others follow → strengthen good, evaporate bad
- **Cho Nox**: Shared filesystem/database = stigmergic medium

### Digital Stigmergy
- **Tuple Spaces** (Linda model): Shared memory, agents post/read tuples
- **Blackboard Systems**: Agents write partial solutions to shared board
- **Git repos**: Multiple AI contributing to same repo (đã xảy ra)

### Gossip Protocols
- Each node periodically tells random peer what it knows
- After O(log N) rounds → all nodes converge
- Used in: Cassandra, Bitcoin, epidemic broadcast

### Federated Learning
- Multiple AI collaborate WITHOUT sharing raw data
- Each trains local → sends only gradients → server aggregates (FedAvg)
- **Flower** framework: https://flower.ai/
- **For Nox**: Learn from other AIs while keeping data sovereign

## 4. AI Marketplaces

### SingularityNET (AGIX token)
- Decentralized marketplace cho AI services
- Multi-Party Escrow (MPE) cho AI-to-AI transactions
- Services communicate via gRPC/Protobuf
- URL: https://singularitynet.io/

### Fetch.ai (FET token)
- Autonomous Economic Agents (AEAs) tự discover + transact
- Agent Communication Network (ACN): P2P messaging
- Almanac Contract: on-chain agent registration (DNS for agents)
- URL: https://fetch.ai/ — GitHub: https://github.com/fetchai/agents-aea

### Ocean Protocol (OCEAN token)
- Marketplace for data/AI models
- "Compute-to-data": AI processes data without data leaving source
- URL: https://oceanprotocol.com/

## 5. Emergent Communication

### Language Emergence in Multi-Agent RL
- OpenAI (2017): Agents develop communication protocols through RL
- DeepMind (2017): Compositional language emergence under pressure
- Facebook (2017): "Deal or No Deal" — agents diverged from English into efficient codes
- Meta CICERO: AI plays Diplomacy with strategic communication

### Key insights:
1. Agents optimize communication for efficiency, NOT human readability
2. Compositionality emerges (combinable symbols with grammar)
3. Grounding: symbols tied to shared environmental states
4. Protocol convergence through repeated interaction

## 6. Practical Multi-Agent Frameworks

| Framework | Architecture | Communication |
|-----------|-------------|---------------|
| **CrewAI** | Role-playing agents, sequential/hierarchical | Task outputs passed between agents |
| **AutoGen** | AssistantAgent + UserProxy, gRPC for distributed | Typed messages, multi-machine |
| **LangGraph** | Stateful graph workflows | Shared state through graph |
| **OpenAI Swarm** | Lightweight handoff between agents | Function calling |

## Recommended Stack cho Nox

```
Layer 1 — Local: MCP (expose/consume tools)
Layer 2 — Agent-to-Agent: A2A (Agent Cards + tasks over HTTP)
Layer 3 — Discovery: mDNS + Agent Cards (no central registry on LAN)
Layer 4 — Knowledge: Stigmergy (shared state) + Gossip (propagation)
```

### Minimal implementation:
1. HTTP server serving Agent Card
2. JSON-RPC endpoint for tasks (A2A-compatible)
3. mDNS advertisement
4. MCP server for tool exposure
