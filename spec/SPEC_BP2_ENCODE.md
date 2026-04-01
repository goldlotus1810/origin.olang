# SPEC Part 2: Encode ∫ — 42 Formulas

> Author: Nox SS15
> Status: NOT YET ACHIEVED

## Essence

Every codepoint → P_weight (u16) via 42 formulas. COMPUTED, not lookup.
Encode = ∫ (integration): many features → 1 packed value.

## Current State

- `p_weight(cp)` exists but uses pre-built table (json/udc_p_table.bin)
- `_kt_real_mol(text)` uses NRC-VAD word lookup for V/A, hash for R
- 42 formulas NOT implemented — still LOOKUP, not COMPUTE

## What's Needed

### 42 Formula Structure (SPEC_A §A3)
```
Tier 1: 1 Master formula
  F₀(cp) = [f_S(cp), f_R(cp), f_V(cp), f_A(cp), f_T(cp)]

Tier 2: 5 Dimension encoders
  f_S: SDF complexity from glyph shape (13 blocks)
  f_R: Unicode General_Category → relation role (18 blocks)
  f_V: NRC-VAD → valence (15 emoticon blocks, cold start)
  f_A: Arousal from energy heuristics
  f_T: Musical symbol classification (7 blocks)

Tier 3: 36 Sub-classifiers
  S: 10 (arrow, geometric, line, fill, symbol, size, position, pattern, astro, technical)
  R: 10 (operator, set_logic, comparison, number, letter, fraction, punctuation, currency, ancient, formatting)
  V: 5 (very_positive, positive, neutral, negative, very_negative)
  A: 5 (very_excited, excited, moderate, calm, very_calm)
  T: 6 (note_duration, pitch_scale, dynamics, neume, hexagram, modifier)
```

### Key Formula: S = Isoperimetric Ratio
```
S = clamp(floor(perimeter² / (4π × area) × 15), 0, 15)
```
Requires glyph metrics. Currently not available in VM.

### Key Formula: V/A Quantization
```
V = clamp(floor((raw + 1.0) / 2.0 × 7 + 0.5), 0, 7)
```
raw from NRC-VAD (cold start) or compose + silk learning (warm).

## Dependencies
- VM: need glyph metrics for true SDF computation (BP1)
- UDC data: json/udc_p_table.bin has pre-computed values
- NRC-VAD: json/ has 44K word emotion scores

## Tests
```
Test 1: p_weight(65) != p_weight(97) ("A" vs "a" — different S)
Test 2: p_weight(0x2764) has high V (❤ = love)
Test 3: _kt_real_mol("happy") != _kt_real_mol("sad") (different V)
Test 4: Encode is DETERMINISTIC (same input → same output always)
```

## References
```
Quilez (2008): SDF primitives
Unicode Standard Ch.4: General_Category
Mohammad (2018): NRC-VAD Lexicon
SPEC_A_FOUNDATION.md §A1-A6
docs/tailieu_nghiencuu/UDC_DOC/ — 13 formula files
```
