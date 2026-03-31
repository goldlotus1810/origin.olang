# Session 13 — Fix 4 Blockers

## TRẠNG THÁI
- Brain: 900 lines, 24/27 G sections, Gen1==Gen2 ✓
- DNA: 161K P_weights, 41K aliases, 54K NRC-VAD, 13MB knowledge
- KnowTree: 271 nodes (71 boot + 200 VAD words)
- Diagnostics: kt_diagnostic(), kt_map(), kt_silk_stats()
- Tests: 193/194 ALL PASS

## FIX THESE (in order):

### BLOCKER #1: Mol Collision (CRITICAL)
ALL text → same P_weight. "Ha Noi" = "Olang" = mol 4240.
**Fix:** hybrid mol = compose(S,R,T) + hash(text) for uniqueness
**Verify:** `_kt_real_mol("Ha Noi") != _kt_real_mol("Olang")`

### BLOCKER #2+#4: Silk + Search (auto-fix from #1)
Only 6 silk edges. Same search result for all queries.
Fix #1 → different mols → different buckets → silk works → search works.

### BLOCKER #3: VM Heap
Crash after ~200 learns. Need multi-turn loading or VM fix.

## ĐỌC TRƯỚC:
1. `docs/SPEC_G_COMPLETE.md` — G2 (compose), G5 (nearest)
2. `CLAUDE.md` — rules
3. Run: `printf 'emit kt_diagnostic()\n' | timeout 5 ./origin_gen1.olang`

## Build:
```bash
cd ~/Origin && make self-build && make test
```
