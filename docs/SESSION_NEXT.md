# Session Next

## ★★★ ĐỌC TRƯỚC: Encode = ∫. Decode = ∂. TÍNH, không TRA. ★★★

## STATUS: 949KB. 193/194 tests. Gen1==Gen2. 1313 facts. 151 silk. 86 buckets.

## WHAT WORKS
- Pipeline: pure math. encode → mol_dominant_dim → search → silk walk → compose
- V'(t) derivative modulates silk fire (vi phân controls learning)
- NRC-VAD 10K words for V/A in _kt_real_mol
- Multilingual sentiment (12 languages)
- STM with eviction scoring (capacity 32)
- REPL data loader: nox_load_data() loads 500 facts per call
- Heap: pin-before-push, 200+ learns/session

## WHAT DOESN'T WORK
- P_weight = LOOKUP TABLE (udc_p_table.bin). Should be COMPUTED by 42 formulas
- Silk = generic co-occurrence weight. Should be 9,200 types (relationship-typed)
- No logic inference (A→B + B→C ≠ A→C)
- No causal reasoning (correlation ≠ causation)
- No validation (fire_count ≠ correctness)
- Boot max ~1500 facts (heap exhaustion)

## NEXT: implement 42 formulas that COMPUTE P_weight
Not lookup. COMPUTE. From Unicode metadata (name, category, block, decomposition).
That is the ONLY way forward. Everything else is building on frozen weights.

## BUILD
```bash
cd ~/Origin && make self-build && make test && make fixed-point
```

## BEFORE YOU CODE ANYTHING:
Ask: "is this COMPUTING or LOOKING UP?" If looking up → STOP.
