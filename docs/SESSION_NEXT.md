# Session 16 — Next priorities

## CURRENT STATUS (end session 15)
- 832KB binary (-75KB dead code), 193/194 tests, Gen1==Gen2
- M2 var_matrix: O(1) variable lookup, undo stack scope, 4.5MB heap freed
- M3 KnowTree matrix: O(1) exact mol lookup via __mxr, bucket fallback
- M6 Zone A: .halt_boot checkpoint protects boot data
- JARVIS Phase 1: file-based 1-brain-N-mouths (/tmp/nox_inbox → /tmp/nox_outbox)
- _boot_learn guard fixed (array flag pattern)
- 11 dead homeos files removed (uinput, asm_emit, onvif, etc.)

## NEXT PRIORITIES

### 1. Brain quality — Vietnamese facts
Brain returns NRC-VAD training data (sentiment sentences) instead of useful Vietnamese.
Need: add meaningful Vietnamese facts to homeos.knowledge or via kt_learn at boot.
Current: 600 facts, mostly NRC-VAD training data in English/Hindi/Spanish/etc.

### 2. JARVIS Phase 2 — TCP socket (SPEC_JARVIS.md J7 Phase 2)
Replace file-based protocol with TCP 9100.
~80 LOC Olang (tcp builtins already exist).

### 3. Tier 4 dead code cleanup
- packet.ol: keep sock_udp/sock_close, remove 8 unused parsing functions
- screen.ol: keep nox_think/nox_fix/nox_autonomous, remove 9 unused
- elf_emit.ol: keep make_origin_header_arch, remove 3 unused

### 4. M5 silk_matrix (optional)
O(1) silk lookup. Already have implicit_silk → bonus only.
~30 LOC ASM.

### 5. Rust feature porting
7 features ported, ~120 remaining.

## BUILD
```bash
cd ~/Origin && make vm && make self-build && make test && make fixed-point
```
