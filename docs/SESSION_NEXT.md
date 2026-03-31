# Session Next

## STATUS: 10/10 Sora test. 193/194 unit tests. Gen1==Gen2.

## WHAT WORKS
- Pipeline: "Fibonacci la gi?" → correct answer ✓
- Search: kt_find + _str_has (pure Olang, no VM builtins) ✓
- Silk walk: 4-hop multi-node traversal ✓
- Dream: creates 35 new concepts from STM ✓
- Persistence: kt_save/kt_load ✓
- 293 nodes at boot (71 embedded + 32 L0 + 77 memory + 113 data)

## WHAT DOESN'T WORK
- Sora's ranked_search → returns nil (function scope issue with tools/)
- Data loading >200/turn → crash (heap pin keeps temp strings)
- substr inside some function calls → returns wrong data
- Globals in files OTHER than knowtree.ol → not accessible from eval

## OLANG PATTERNS (learned the hard way)
```
✅ Globals in knowtree.ol → work everywhere (use this for shared state)
✅ _str_has (char_at loop) → works. __str_contains → returns nil
✅ __array_with_cap(N) → prevents crash at 512
✅ kt_learn_raw(text, mol) → 0 temp strings (fast bulk load)
✅ pipeline(src) FIRST, compile SECOND (SPEC_D §D1)
✅ No syntax chars + eval empty → return pipeline result
✗ Globals in other .ol files → NOT accessible from REPL eval
✗ Functions that push to local arrays → data lost on return
✗ let _i = _i + 1 inside while → works in boot, NOT in eval
```

## PRIORITIES FOR NEXT SESSION
1. Fix VM: why do tools/ functions return nil? (bytecode scope)
2. Load more data: multi-turn batch loading (5000+ nodes)
3. repl.ol cleanup: 1448 lines, 127 string compares

## BUILD
```bash
cd ~/Origin && make self-build && make test && make fixed-point
# Test: echo 'Fibonacci la gi?' | ./origin_gen1.olang
```
