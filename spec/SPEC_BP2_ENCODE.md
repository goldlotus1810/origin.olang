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

## Research Insights

### Unicode Name Parsing (Gibbon 2005)
Character names ARE parseable semantic descriptions:
```
"LATIN SMALL LETTER A WITH ACUTE" →
  Script = LATIN → S dimension (block)
  Case = SMALL → structural feature
  Base = LETTER A → shape identity
  Modifier = WITH ACUTE → R (relation to base)
```
Split name on spaces, match prefixes: LATIN|GREEK|CJK|ARABIC (script),
SMALL|CAPITAL (case), LETTER|DIGIT|SIGN (category), WITH|AND (modifier).
Pure string parsing, no ML. Deterministic. NOVEL — no one mapped to 5D before.

### Decomposition Mapping → R dimension
Canonical decomposition reveals base+combining relationships:
```
é = e + COMBINING ACUTE ACCENT
fi = f + i (compatibility decomposition)
```
This IS the R (Relation) dimension: how components relate.

### Vietnamese Tones → V/A dimensions
```
không dấu (none)   = neutral V/A
huyền (grave `)     = V decreases (falling)
sắc (acute ´)       = V increases (rising)
hỏi (hook)          = complex V
ngã (tilde ~)        = V oscillates
nặng (dot below .)  = A increases (heavy)
```
6 tones map naturally to V/A changes via compose(base, diacritic).

## References
```
Quilez (2008): SDF primitives
Unicode Standard Ch.4: General_Category
UAX #44: Unicode Character Database
Mohammad (2018): NRC-VAD Lexicon
Gibbon, Hughes & Trippel (2005): Semantic Decomposition of Character Encodings
SPEC_A_FOUNDATION.md §A1-A6
VM_SPEC_COMPLETE.md §7 (Molecular Engine)
docs/tailieu_nghiencuu/UDC_DOC/ — 13 formula files
```

## Implementation Strategy (from research)

### 1. Unicode Name Parsing (practical algorithm)

Every Unicode codepoint has a name string (e.g., "LATIN SMALL LETTER A WITH ACUTE").
Split on spaces, extract structured features:

- **Script**: LATIN / GREEK / CJK / ARABIC / HANGUL / HIRAGANA / etc. → S dimension (13 blocks)
- **Case**: SMALL / CAPITAL → structural feature within S
- **Category**: LETTER / DIGIT / SIGN / SYMBOL → R dimension (operator, punctuation, letter, etc.)
- **Modifier**: WITH / AND → relation modifier within R

This is PURE STRING PARSING — no ML, fully deterministic, novel approach.
No one has mapped Unicode name parsing to a 5D molecular space before.

Reference: Gibbon, Hughes & Trippel 2005 — Semantic Decomposition of Character Encodings.

### 2. Decomposition Mapping → R dimension

Unicode canonical decomposition reveals base+combining relationships:
```
é = e + COMBINING ACUTE ACCENT → R encodes "modified by"
fi = f + i (compatibility decomposition) → R encodes "composed of"
```
Can be extracted from UCD data already in `~/Origin/json/`.
Decomposition IS the R (Relation) dimension: how components relate to their base.

### 3. Cold Start vs Warm

- **Cold**: NRC-VAD lookup for V/A (already have 44K words in `json/`).
  Word → float V/A → quantize to 3-bit fields.
- **Warm**: compose + silk learning replaces lookup over time.
  Encode fires silk between codepoint mols and context mols.
  After enough fires, the learned weights ARE the encoding — lookup becomes redundant.
- **Goal**: lookup is SCAFFOLDING, not permanent. The 42 formulas must eventually
  replace all lookups with pure computation from glyph/structural features.

### 4. P_weight bit layout reminder

```
u16 = [S:4][R:4][V:3][A:3][T:2] = 65536 possible molecules

pack(S, R, V, A, T) = (S << 12) | (R << 8) | (V << 5) | (A << 2) | T

unpack:
  S = (mol >> 12) & 0xF     // 0-15
  R = (mol >> 8)  & 0xF     // 0-15
  V = (mol >> 5)  & 0x7     // 0-7
  A = (mol >> 2)  & 0x7     // 0-7
  T = mol         & 0x3     // 0-3
```

---

## Related Specs
- [VM Spec §7 Molecular Engine](VM_SPEC_COMPLETE.md) — P_weight format, pack/unpack
- [BP3 KnowTree](SPEC_BP3_KNOWTREE.md) — uses encoded mols for indexing
- [BP4 Silk](SPEC_BP4_SILK.md) — silk strength depends on mol quality
- [BP5 Pipeline](SPEC_BP5_PIPELINE_EN.md) — encode is Step 1
- [SPEC_A Foundation](../docs/SPEC_A_FOUNDATION.md) — 42 formula definition
- [UDC Formulas](../docs/tailieu_nghiencuu/UDC_DOC/UDC_formulas.md) — formula details
