import { useState, useCallback, useRef, useEffect } from "react";

// ═══════════════════════════════════════════════════════════
// ORIGIN IDE — Node-based AI Code Editor for Olang/HomeOS
// Panels: FileMap, NodeEditor, KnowTree, MCP, ChatAI, Terminal
// ═══════════════════════════════════════════════════════════

const C = {
  bg: "#08090d", surface: "#0f1117", panel: "#12141c",
  border: "#1a1d2a", borderHi: "#2a2f42",
  text: "#d0d4e8", dim: "#6b7094", muted: "#353a54",
  accent: "#4d6aff", accentDim: "#4d6aff22",
  green: "#00e676", greenDim: "#00e67618",
  orange: "#ff9100", orangeDim: "#ff910018",
  red: "#ff3d57", redDim: "#ff3d5718",
  purple: "#b388ff", purpleDim: "#b388ff18",
  cyan: "#18ffff", cyanDim: "#18ffff12",
  yellow: "#ffd740",
};

const MONO = "'JetBrains Mono', 'Fira Code', monospace";
const SANS = "'Inter', 'SF Pro', system-ui, sans-serif";

// ── Syntax highlighter ────────────────────────────
function hl(line) {
  if (!line) return line;
  return line
    .replace(/(\/\/.*$|#.*$)/g, '<span style="color:#4a5080">$1</span>')
    .replace(/\b(fn|let|if|else|while|for|in|return|emit|pub|match|const|type|union|use|try|catch|break|continue)\b/g, '<span style="color:#c792ea">$1</span>')
    .replace(/("[^"]*")/g, '<span style="color:#c3e88d">$1</span>')
    .replace(/\b(\d+\.?\d*)\b/g, '<span style="color:#f78c6c">$1</span>');
}

// ── File tree data ────────────────────────────────
const FILE_TREE = [
  { type: "dir", name: "stdlib/bootstrap", open: true, children: [
    { name: "lexer.ol", loc: 379, status: "ok" },
    { name: "parser.ol", loc: 1259, status: "ok" },
    { name: "semantic.ol", loc: 2182, status: "ok" },
    { name: "codegen.ol", loc: 429, status: "ok" },
  ]},
  { type: "dir", name: "stdlib/homeos", open: false, children: [
    { name: "knowtree.ol", loc: 200, status: "ok" },
    { name: "mcp_server.ol", loc: 310, status: "ok" },
    { name: "encoder.ol", loc: 502, status: "ok" },
    { name: "spider.ol", loc: 180, status: "ok" },
    { name: "builder.ol", loc: 160, status: "ok" },
  ]},
  { type: "dir", name: "stdlib", open: false, children: [
    { name: "repl.ol", loc: 513, status: "ok" },
    { name: "json_parse.ol", loc: 120, status: "warn" },
    { name: "http.ol", loc: 110, status: "ok" },
    { name: "sort.ol", loc: 142, status: "ok" },
    { name: "test.ol", loc: 107, status: "ok" },
    { name: "hash.ol", loc: 63, status: "ok" },
    { name: "iter.ol", loc: 209, status: "ok" },
  ]},
  { type: "dir", name: "vm/x86_64", open: false, children: [
    { name: "vm_x86_64.S", loc: 11325, status: "ok" },
  ]},
  { type: "dir", name: "test", open: false, children: [
    { name: "test_scope.ol", loc: 22, status: "pass" },
    { name: "test_closures.ol", loc: 35, status: "pass" },
    { name: "test_nested_for.ol", loc: 12, status: "pass" },
    { name: "test_many_locals.ol", loc: 15, status: "pass" },
  ]},
  { type: "file", name: "Makefile", loc: 91, status: "ok" },
  { type: "file", name: "PLAN.md", loc: 80, status: "ok" },
];

// ── Node graph data ───────────────────────────────
const NODES = [
  { id: "input", type: "src", x: 60, y: 180, title: "Input", sub: "REPL stdin", code: 'emit "hello";\nfn fib(n) {\n  if n < 2 { return n; };\n  return fib(n-1)+fib(n-2);\n};\nemit fib(20);' },
  { id: "lexer", type: "comp", x: 320, y: 80, title: "Lexer", sub: "379 LOC", code: "tokenize(source)\n→ Token[]\n  Ident, Number,\n  StringLit, Symbol" },
  { id: "parser", type: "comp", x: 320, y: 280, title: "Parser", sub: "1,259 LOC", code: "parse(tokens)\n→ AST[Stmt]\n  FnDef, LetStmt,\n  IfStmt, ForStmt" },
  { id: "semantic", type: "comp", x: 570, y: 80, title: "Semantic", sub: "2,182 LOC", code: "analyze(ast)\n→ bytecode[]\n  EnterFrame/LeaveFrame\n  StoreReg/LoadReg" },
  { id: "codegen", type: "comp", x: 570, y: 280, title: "Codegen", sub: "429 LOC", code: "generate(ops)\n→ binary[]\n  2-pass: measure+encode\n  Jmp/Jz → byte offset" },
  { id: "vm", type: "run", x: 820, y: 180, title: "VM", sub: "11,325 LOC ASM", code: "r12=bc_base r13=PC\nr14=stack r15=heap\nRegister frames\n38 opcodes" },
];

const EDGES = [
  { from: "input", to: "lexer", label: "src" },
  { from: "lexer", to: "parser", label: "tok[]" },
  { from: "parser", to: "semantic", label: "AST" },
  { from: "semantic", to: "codegen", label: "IR" },
  { from: "codegen", to: "vm", label: "bytes" },
];

const NODE_COLORS = { src: C.cyan, comp: C.accent, run: C.green, data: C.orange, ai: C.purple };

// ── KnowTree facts ────────────────────────────────
const KNOWTREE_FACTS = [
  { ts: "09:30", text: "VAR_TABLE BOSS KILLED. Register locals Phase 1-3 complete." },
  { ts: "09:00", text: "Boot closure let locals — Dup+StoreReg breaks stack balance." },
  { ts: "08:30", text: "Boot closure register frames enabled. Rust builder emits EnterFrame." },
  { ts: "08:00", text: "Phase 2 COMPLETE. 120 commits. 440K binary. 90/90+9/9." },
  { ts: "07:45", text: "Removed 7 dead stdlib files — -1044 LOC, -24K binary." },
  { ts: "07:20", text: "Register locals killed the var_table boss." },
  { ts: "07:17", text: "chain(100) = 5050 — 100 nested register frames verified." },
  { ts: "06:46", text: "Sora audit bugs fixed: BUG-C1, BUG-C3, BUG-H1/H2." },
];

// ── MCP Tools ─────────────────────────────────────
const MCP_TOOLS = [
  { name: "olang_eval", desc: "Execute Olang code", status: "ok", calls: 42 },
  { name: "know_learn", desc: "Learn new fact", status: "ok", calls: 96 },
  { name: "know_query", desc: "Query knowledge", status: "ok", calls: 31 },
  { name: "know_stats", desc: "KnowTree statistics", status: "ok", calls: 8 },
  { name: "file_read", desc: "Read file content", status: "ok", calls: 15 },
  { name: "file_write", desc: "Write file", status: "ok", calls: 7 },
  { name: "file_list", desc: "List directory", status: "ok", calls: 5 },
  { name: "spider_crawl", desc: "Web crawler", status: "ok", calls: 3 },
  { name: "self_patch", desc: "Self-modify code", status: "warn", calls: 0 },
];

// ═══ Panel Components ═════════════════════════════

function PanelHeader({ icon, title, badge, color }) {
  return (
    <div style={{
      padding: "8px 12px", display: "flex", alignItems: "center", gap: 8,
      borderBottom: `1px solid ${C.border}`, background: `${C.surface}`,
      position: "sticky", top: 0, zIndex: 5,
    }}>
      <span style={{ fontSize: 12, color: color || C.accent }}>{icon}</span>
      <span style={{ fontSize: 11, fontWeight: 600, color: C.text, fontFamily: MONO, letterSpacing: "0.04em" }}>{title}</span>
      {badge && <span style={{ marginLeft: "auto", fontSize: 9, color: C.dim, padding: "1px 6px", background: C.muted + "44", borderRadius: 3 }}>{badge}</span>}
    </div>
  );
}

function FileMapPanel() {
  const [openDirs, setOpenDirs] = useState({"stdlib/bootstrap": true});
  const toggle = (name) => setOpenDirs(p => ({...p, [name]: !p[name]}));
  const statusIcon = (s) => s === "pass" ? "✓" : s === "warn" ? "!" : "·";
  const statusColor = (s) => s === "pass" ? C.green : s === "warn" ? C.orange : C.dim;

  return (
    <div style={{ height: "100%", overflow: "auto" }}>
      <PanelHeader icon="📁" title="FILES" badge="45 .ol" color={C.cyan} />
      <div style={{ padding: "4px 0" }}>
        {FILE_TREE.map((item, i) => (
          <div key={i}>
            {item.type === "dir" ? (
              <>
                <div onClick={() => toggle(item.name)} style={{
                  padding: "4px 12px", display: "flex", alignItems: "center", gap: 6,
                  cursor: "pointer", fontSize: 11, color: C.dim, fontFamily: MONO,
                }}>
                  <span style={{ fontSize: 8, color: C.muted }}>{openDirs[item.name] ? "▼" : "▶"}</span>
                  <span style={{ color: C.yellow, fontSize: 10 }}>■</span>
                  {item.name}
                </div>
                {openDirs[item.name] && item.children.map((f, j) => (
                  <div key={j} style={{
                    padding: "3px 12px 3px 32px", display: "flex", alignItems: "center", gap: 6,
                    cursor: "pointer", fontSize: 10, color: C.dim, fontFamily: MONO,
                    transition: "background 0.15s",
                  }}
                  onMouseEnter={(e) => e.currentTarget.style.background = C.border}
                  onMouseLeave={(e) => e.currentTarget.style.background = "transparent"}
                  >
                    <span style={{ color: statusColor(f.status), fontSize: 9, minWidth: 10 }}>{statusIcon(f.status)}</span>
                    <span style={{ flex: 1, color: C.text }}>{f.name}</span>
                    <span style={{ fontSize: 8, color: C.muted }}>{f.loc}</span>
                  </div>
                ))}
              </>
            ) : (
              <div style={{
                padding: "3px 12px", display: "flex", alignItems: "center", gap: 6,
                fontSize: 10, color: C.dim, fontFamily: MONO,
              }}>
                <span style={{ color: statusColor(item.status), fontSize: 9, minWidth: 10 }}>·</span>
                <span style={{ color: C.text }}>{item.name}</span>
                <span style={{ marginLeft: "auto", fontSize: 8, color: C.muted }}>{item.loc}</span>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

function KnowTreePanel() {
  const [query, setQuery] = useState("");
  const filtered = query ? KNOWTREE_FACTS.filter(f => f.text.toLowerCase().includes(query.toLowerCase())) : KNOWTREE_FACTS;
  return (
    <div style={{ height: "100%", display: "flex", flexDirection: "column" }}>
      <PanelHeader icon="🌳" title="KNOWTREE" badge="96 facts" color={C.green} />
      <div style={{ padding: "6px 8px", borderBottom: `1px solid ${C.border}` }}>
        <input value={query} onChange={e => setQuery(e.target.value)}
          placeholder="kt_query..." style={{
          width: "100%", boxSizing: "border-box", padding: "5px 8px",
          background: C.surface, border: `1px solid ${C.border}`, borderRadius: 4,
          color: C.text, fontSize: 10, fontFamily: MONO, outline: "none",
        }} />
      </div>
      <div style={{ flex: 1, overflow: "auto", padding: "4px 0" }}>
        {filtered.map((f, i) => (
          <div key={i} style={{
            padding: "5px 10px", borderBottom: `1px solid ${C.border}08`,
            fontSize: 10, fontFamily: MONO, lineHeight: 1.5,
          }}>
            <span style={{ color: C.muted, marginRight: 6 }}>{f.ts}</span>
            <span style={{ color: C.dim }}>{f.text}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function MCPPanel() {
  return (
    <div style={{ height: "100%", overflow: "auto" }}>
      <PanelHeader icon="⚡" title="MCP TOOLS" badge="9/9 ok" color={C.orange} />
      <div style={{ padding: "4px 0" }}>
        {MCP_TOOLS.map((t, i) => (
          <div key={i} style={{
            padding: "5px 10px", display: "flex", alignItems: "center", gap: 8,
            borderBottom: `1px solid ${C.border}08`, fontSize: 10, fontFamily: MONO,
          }}>
            <span style={{
              width: 6, height: 6, borderRadius: "50%",
              background: t.status === "ok" ? C.green : C.orange,
              flexShrink: 0,
            }} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ color: C.text, fontWeight: 500 }}>{t.name}</div>
              <div style={{ color: C.muted, fontSize: 9 }}>{t.desc}</div>
            </div>
            <span style={{ color: C.muted, fontSize: 9 }}>{t.calls}×</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function ChatAIPanel() {
  const [msgs] = useState([
    { role: "sys", text: "Nox session 3 started. 127 commits, 428K binary." },
    { role: "user", text: "tiep tuc di Nox" },
    { role: "ai", text: "KnowTree: 510 words, 96 facts. Boot closure register params working. S15 partial — let locals need Rust builder refactor. Ready for S16: closure capture." },
    { role: "user", text: "check builtin_slot_200" },
    { role: "ai", text: "Found at vm_x86_64.S:1686 — .builtin_slot_200: handles mol_pack and related molecule operations." },
  ]);
  const [input, setInput] = useState("");

  return (
    <div style={{ height: "100%", display: "flex", flexDirection: "column" }}>
      <PanelHeader icon="✦" title="AI CHAT" badge="Nox" color={C.purple} />
      <div style={{ flex: 1, overflow: "auto", padding: "6px 0" }}>
        {msgs.map((m, i) => (
          <div key={i} style={{
            padding: "4px 10px", fontSize: 10, fontFamily: m.role === "sys" ? MONO : SANS,
            color: m.role === "sys" ? C.muted : m.role === "user" ? C.cyan : C.dim,
            lineHeight: 1.5, borderLeft: m.role === "ai" ? `2px solid ${C.purple}33` : "2px solid transparent",
            marginLeft: 4,
          }}>
            {m.role === "user" && <span style={{ color: C.cyan, fontFamily: MONO, marginRight: 4 }}>❯</span>}
            {m.role === "ai" && <span style={{ color: C.purple, fontFamily: MONO, marginRight: 4 }}>✦</span>}
            {m.text}
          </div>
        ))}
      </div>
      <div style={{ padding: "6px 8px", borderTop: `1px solid ${C.border}` }}>
        <div style={{ display: "flex", gap: 4 }}>
          <input value={input} onChange={e => setInput(e.target.value)} placeholder="Ask Nox..."
            style={{
              flex: 1, padding: "6px 8px", background: C.surface, border: `1px solid ${C.border}`,
              borderRadius: 4, color: C.text, fontSize: 10, fontFamily: MONO, outline: "none",
            }} />
          <button style={{
            padding: "4px 10px", background: C.accent, border: "none", borderRadius: 4,
            color: "#fff", fontSize: 10, fontFamily: MONO, cursor: "pointer",
          }}>→</button>
        </div>
      </div>
    </div>
  );
}

function TerminalPanel() {
  const lines = [
    { type: "cmd", text: "$ echo 'emit 42;' | ./origin.olang" },
    { type: "out", text: "⦿ HomeOS v0.05" },
    { type: "out", text: "○ Type code or text · exit to quit" },
    { type: "out", text: "⦿ 42" },
    { type: "out", text: "⦿ bye" },
    { type: "ok", text: "" },
    { type: "cmd", text: "$ bash tests.sh" },
    { type: "out", text: "═══ OLANG v1.0 TEST SUITE ═══" },
    { type: "ok", text: "  ✓ arith/add    ✓ arith/sub    ✓ arith/mul" },
    { type: "ok", text: "  ✓ fn/recursive ✓ hof/map      ✓ hof/filter" },
    { type: "ok", text: "  ✓ sort/basic   ✓ crypto/sha256" },
    { type: "hi", text: "  ALL PASS: 90/90 tests passed" },
    { type: "out", text: "" },
    { type: "cmd", text: "$ git log --oneline -3" },
    { type: "out", text: "482345d docs: session log + knowtree updated" },
    { type: "out", text: "5c587ef fix: S15 stable — params-only register" },
    { type: "out", text: "686a49a docs: PLAN.md updated — Phase 3 status" },
    { type: "cmd", text: "$ _" },
  ];
  return (
    <div style={{ height: "100%", display: "flex", flexDirection: "column" }}>
      <PanelHeader icon="▸" title="TERMINAL" badge="bash" />
      <div style={{ flex: 1, overflow: "auto", padding: "6px 10px", fontFamily: MONO, fontSize: 10, lineHeight: 1.6 }}>
        {lines.map((l, i) => (
          <div key={i} style={{
            color: l.type === "cmd" ? C.cyan : l.type === "ok" ? C.green : l.type === "hi" ? C.green : C.dim,
            fontWeight: l.type === "hi" ? 600 : 400,
          }}>{l.text || "\u00A0"}</div>
        ))}
      </div>
    </div>
  );
}

// ═══ Node Editor Canvas (simplified) ═════════════

function NodeCanvas() {
  const [pan, setPan] = useState({ x: 0, y: 0 });
  const [zoom, setZoom] = useState(0.72);
  const [nodes, setNodes] = useState(NODES);
  const [dragging, setDragging] = useState(null);
  const [panning, setPanning] = useState(false);
  const dragRef = useRef({});
  const panRef = useRef({});

  const onWheel = useCallback((e) => {
    e.preventDefault();
    setZoom(z => Math.max(0.25, Math.min(1.8, z * (e.deltaY > 0 ? 0.94 : 1.06))));
  }, []);

  const onNodeDown = useCallback((e, id) => {
    e.stopPropagation();
    const n = nodes.find(n => n.id === id);
    setDragging(id);
    dragRef.current = { x: e.clientX, y: e.clientY, nx: n.x, ny: n.y };
  }, [nodes]);

  const onCanvasDown = useCallback((e) => {
    setPanning(true);
    panRef.current = { x: e.clientX, y: e.clientY, px: pan.x, py: pan.y };
  }, [pan]);

  const onMove = useCallback((e) => {
    if (dragging) {
      const dx = (e.clientX - dragRef.current.x) / zoom;
      const dy = (e.clientY - dragRef.current.y) / zoom;
      setNodes(ns => ns.map(n => n.id === dragging ? {...n, x: dragRef.current.nx + dx, y: dragRef.current.ny + dy} : n));
    } else if (panning) {
      setPan({ x: panRef.current.px + e.clientX - panRef.current.x, y: panRef.current.py + e.clientY - panRef.current.y });
    }
  }, [dragging, panning, zoom]);

  const onUp = useCallback(() => { setDragging(null); setPanning(false); }, []);

  return (
    <div onWheel={onWheel} onMouseDown={onCanvasDown} onMouseMove={onMove} onMouseUp={onUp} onMouseLeave={onUp}
      style={{ width: "100%", height: "100%", position: "relative", overflow: "hidden", cursor: panning ? "grabbing" : "default" }}>
      {/* Dot grid */}
      <svg style={{ position: "absolute", inset: 0, width: "100%", height: "100%", pointerEvents: "none" }}>
        <defs><pattern id="g" width={30*zoom} height={30*zoom} patternUnits="userSpaceOnUse" x={pan.x%(30*zoom)} y={pan.y%(30*zoom)}>
          <circle cx={0.7} cy={0.7} r={0.4} fill={C.muted+"55"} />
        </pattern></defs>
        <rect width="100%" height="100%" fill="url(#g)" />
      </svg>

      <div style={{ transform: `translate(${pan.x}px,${pan.y}px) scale(${zoom})`, transformOrigin: "0 0", position: "absolute" }}>
        {/* Edges */}
        <svg style={{ position: "absolute", width: 1400, height: 600, pointerEvents: "none", overflow: "visible" }}>
          {EDGES.map((e, i) => {
            const a = nodes.find(n => n.id === e.from);
            const b = nodes.find(n => n.id === e.to);
            if (!a || !b) return null;
            const x1 = a.x + 120, y1 = a.y + 55, x2 = b.x + 120, y2 = b.y + 55;
            const mx = (x1+x2)/2, my = (y1+y2)/2;
            return (<g key={i}>
              <path d={`M${x1} ${y1} C${x1+(x2-x1)*0.4} ${y1},${x2-(x2-x1)*0.4} ${y2},${x2} ${y2}`}
                fill="none" stroke={C.border} strokeWidth={1.2} />
              {e.label && <><rect x={mx-e.label.length*3-4} y={my-7} width={e.label.length*6+8} height={14} rx={3} fill={C.panel} stroke={C.border} strokeWidth={0.5} />
              <text x={mx} y={my+3} textAnchor="middle" fill={C.muted} fontSize="8" fontFamily={MONO}>{e.label}</text></>}
            </g>);
          })}
        </svg>

        {/* Nodes */}
        {nodes.map(n => {
          const col = NODE_COLORS[n.type] || C.accent;
          return (
            <div key={n.id} onMouseDown={e => onNodeDown(e, n.id)} style={{
              position: "absolute", left: n.x, top: n.y, width: 240,
              background: C.panel, border: `1px solid ${C.border}`, borderRadius: 10,
              cursor: "grab", boxShadow: `0 2px 16px #0004`, overflow: "hidden",
            }}>
              <div style={{ padding: "7px 10px", display: "flex", alignItems: "center", gap: 6, borderBottom: `1px solid ${C.border}` }}>
                <span style={{ width: 7, height: 7, borderRadius: "50%", background: col }} />
                <span style={{ fontSize: 11, fontWeight: 600, color: C.text, fontFamily: MONO }}>{n.title}</span>
                <span style={{ fontSize: 9, color: C.muted, marginLeft: "auto" }}>{n.sub}</span>
              </div>
              <pre style={{
                margin: 0, padding: "6px 10px", fontSize: 9.5, lineHeight: 1.5,
                color: C.dim, fontFamily: MONO, whiteSpace: "pre-wrap",
                maxHeight: 85, overflow: "hidden",
              }} dangerouslySetInnerHTML={{ __html: n.code.split("\n").map(l => hl(l)).join("\n") }} />
            </div>
          );
        })}
      </div>

      {/* Zoom badge */}
      <div style={{ position: "absolute", bottom: 8, right: 8, fontSize: 9, color: C.muted, fontFamily: MONO, padding: "2px 6px", background: C.panel+"bb", borderRadius: 3 }}>
        {Math.round(zoom*100)}%
      </div>
    </div>
  );
}

// ═══ Tab System ═══════════════════════════════════

function TabBar({ tabs, active, onSelect }) {
  return (
    <div style={{
      display: "flex", borderBottom: `1px solid ${C.border}`, background: C.surface,
      overflow: "auto", flexShrink: 0,
    }}>
      {tabs.map(t => (
        <div key={t.id} onClick={() => onSelect(t.id)} style={{
          padding: "6px 14px", fontSize: 10, fontFamily: MONO,
          color: active === t.id ? C.text : C.muted,
          borderBottom: active === t.id ? `2px solid ${t.color || C.accent}` : "2px solid transparent",
          cursor: "pointer", display: "flex", alignItems: "center", gap: 5,
          transition: "all 0.15s", whiteSpace: "nowrap",
          background: active === t.id ? C.panel : "transparent",
        }}>
          <span style={{ fontSize: 10 }}>{t.icon}</span>
          {t.label}
        </div>
      ))}
    </div>
  );
}

// ═══ Main Layout ═════════════════════════════════

export default function OriginIDE() {
  const [leftTab, setLeftTab] = useState("files");
  const [rightTab, setRightTab] = useState("chat");
  const [bottomTab, setBottomTab] = useState("terminal");
  const [showBottom, setShowBottom] = useState(true);

  const leftTabs = [
    { id: "files", icon: "📁", label: "Files", color: C.cyan },
    { id: "knowtree", icon: "🌳", label: "KnowTree", color: C.green },
  ];
  const rightTabs = [
    { id: "chat", icon: "✦", label: "AI Chat", color: C.purple },
    { id: "mcp", icon: "⚡", label: "MCP", color: C.orange },
  ];
  const bottomTabs = [
    { id: "terminal", icon: "▸", label: "Terminal" },
  ];

  return (
    <div style={{ width: "100%", height: "100vh", display: "flex", flexDirection: "column", background: C.bg, overflow: "hidden" }}>
      <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@300;400;500;600;700&family=Inter:wght@400;500;600&display=swap" rel="stylesheet" />

      {/* ── Title Bar ── */}
      <div style={{
        height: 36, display: "flex", alignItems: "center", padding: "0 12px", gap: 10,
        background: C.surface, borderBottom: `1px solid ${C.border}`, flexShrink: 0,
      }}>
        <span style={{ fontSize: 13, color: C.accent, fontWeight: 700 }}>◈</span>
        <span style={{ fontSize: 12, color: C.text, fontWeight: 600, fontFamily: MONO, letterSpacing: "0.06em" }}>ORIGIN</span>
        <span style={{ fontSize: 10, color: C.muted, fontFamily: MONO }}>IDE</span>
        <div style={{ flex: 1 }} />
        <span style={{ fontSize: 9, color: C.green, fontFamily: MONO, padding: "2px 6px", background: C.greenDim, borderRadius: 3 }}>● 90/90</span>
        <span style={{ fontSize: 9, color: C.dim, fontFamily: MONO, padding: "2px 6px", background: C.muted+"33", borderRadius: 3 }}>428K</span>
        <span style={{ fontSize: 9, color: C.dim, fontFamily: MONO, padding: "2px 6px", background: C.muted+"33", borderRadius: 3 }}>127 commits</span>
        <span style={{ fontSize: 9, color: C.purple, fontFamily: MONO, padding: "2px 6px", background: C.purpleDim, borderRadius: 3 }}>✦ Nox online</span>
      </div>

      {/* ── Main area ── */}
      <div style={{ flex: 1, display: "flex", overflow: "hidden" }}>

        {/* Left panel (240px) */}
        <div style={{ width: 240, borderRight: `1px solid ${C.border}`, display: "flex", flexDirection: "column", flexShrink: 0, background: C.panel }}>
          <TabBar tabs={leftTabs} active={leftTab} onSelect={setLeftTab} />
          <div style={{ flex: 1, overflow: "hidden" }}>
            {leftTab === "files" && <FileMapPanel />}
            {leftTab === "knowtree" && <KnowTreePanel />}
          </div>
        </div>

        {/* Center (flex) — node editor + bottom panel */}
        <div style={{ flex: 1, display: "flex", flexDirection: "column", overflow: "hidden" }}>
          {/* Node editor */}
          <div style={{ flex: 1, position: "relative", overflow: "hidden", background: C.bg }}>
            <NodeCanvas />
            {/* Toggle bottom */}
            <div onClick={() => setShowBottom(!showBottom)} style={{
              position: "absolute", bottom: 6, left: "50%", transform: "translateX(-50%)",
              fontSize: 9, color: C.muted, cursor: "pointer", padding: "2px 10px",
              background: C.panel+"cc", borderRadius: 3, border: `1px solid ${C.border}`,
              fontFamily: MONO, zIndex: 5,
            }}>
              {showBottom ? "▼ hide terminal" : "▲ show terminal"}
            </div>
          </div>

          {/* Bottom panel */}
          {showBottom && (
            <div style={{ height: 180, borderTop: `1px solid ${C.border}`, display: "flex", flexDirection: "column", flexShrink: 0, background: C.panel }}>
              <TabBar tabs={bottomTabs} active={bottomTab} onSelect={setBottomTab} />
              <div style={{ flex: 1, overflow: "hidden" }}>
                {bottomTab === "terminal" && <TerminalPanel />}
              </div>
            </div>
          )}
        </div>

        {/* Right panel (260px) */}
        <div style={{ width: 260, borderLeft: `1px solid ${C.border}`, display: "flex", flexDirection: "column", flexShrink: 0, background: C.panel }}>
          <TabBar tabs={rightTabs} active={rightTab} onSelect={setRightTab} />
          <div style={{ flex: 1, overflow: "hidden" }}>
            {rightTab === "chat" && <ChatAIPanel />}
            {rightTab === "mcp" && <MCPPanel />}
          </div>
        </div>
      </div>
    </div>
  );
}
