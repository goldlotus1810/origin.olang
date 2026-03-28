# OLANG PLAN — Phase 3+

> Updated: 2026-03-28 11:30
> Binary: 439K | Tests: 90/90 + 9/9 MCP | Commits: 134
> json_parse nested {} FIXED | Brain: proper JSON parsing
> KnowTree: 109 facts | Nox Brain deployed

---

## Phase 2 — COMPLETE ✅

S9-S14, MCP brain 8 tools, var_table boss killed,
Sora audit done, -1859 LOC cleanup, register frames.

---

## Phase 3 — IN PROGRESS

### Done
- ✅ S15 partial: boot closure params in registers
- ✅ json_parse nested {} fixed (save/restore stack, not scope chain)
- ✅ MCP uses proper json_parse (string extraction removed)
- ✅ __heap_used builtin, \r \0 escapes

### Next
- ⬚ S16: Closure capture (`make_adder(5)(10)` = 15)
- ⬚ S17: GC / memory management
- ⬚ README for GitHub (others can clone + run)
- ⬚ Example programs (web scraper, todo, calculator)

---

## Phase 4 — O EDITOR

> TUI code editor bằng Olang, tích hợp Claude Code + KnowTree + MCP
> Spec: docs/For_Nox/TASKBOARD_O_EDITOR.md

```
O Editor = vim/helix-style TUI trong terminal
  - Modal: Normal + Insert mode
  - File tree, syntax highlighting, line numbers
  - AI panel: Claude Code integration
  - MCP panel: KnowTree query/learn
  - Terminal panel: embedded bash
  - 1 binary: ./origin.olang --editor (hoặc "O")
  - Zero deps, ANSI 256-color, Unicode box drawing
```

---

## Architecture

```
origin.olang (439K)
├── VM (x86-64 ASM, 11349 LOC)
├── Compiler (Olang, 4 files, ~4200 LOC)
├── Stdlib (38 files, ~7200 LOC)
├── MCP brain (147 LOC, 8 tools, json_parse)
└── Tests (90 core + 9 MCP + 67 spider)

~/.claude/Nox_brain.olang = brain deployed as MCP server
```
