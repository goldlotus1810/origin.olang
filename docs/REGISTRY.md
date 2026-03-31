# REGISTRY — Đăng Ký Mọi Thứ Đã Tạo

> **Mỗi artifact tạo ra PHẢI đăng ký ở đây.**
> **Không đăng ký = không tồn tại.**
> **Thay đổi artifact đã lock = vi phạm.**

---

## SPECS — LOCKED (không thay đổi)

| ID | File | Status | Locked | SHA256 |
|----|------|--------|--------|--------|
| A | docs/SPEC_A_FOUNDATION.md | ✅ Done | 🔒 Session 10 | verify with git |
| B | docs/SPEC_B_STRUCTURE.md | ✅ Done | 🔒 Session 10 | verify with git |
| C | docs/SPEC_C_NEURON.md | ✅ Done | 🔒 Session 10 | verify with git |
| D | docs/SPEC_D_PIPELINE.md | ✅ Done | 🔒 Session 10 | verify with git |
| E | docs/SPEC_E_ORGANISM.md | ✅ Done | 🔒 Session 11 | verify with git |
| F | docs/SPEC_F_AGENT.md | ✅ Done | 🔒 Session 11 | verify with git |
| G | docs/SPEC_G_CODE_AUDIT.md | ⚠️ Superseded | 🔒 Session 11 | Superseded by G_COMPLETE |
| G+ | docs/SPEC_G_COMPLETE.md | ✅ Done | 🔒 Session 12 | 27 sections, THE impl guide |
| U | docs/SPEC_UNIFIED.md | ✅ Done | 🔒 Session 11 | verify with git |

## GUIDES — LOCKED

| ID | File | Purpose |
|----|------|---------|
| CL | CLAUDE.md | Auto-load rules for every session |
| SN | docs/SESSION_NEXT.md | Current phase + checklist |
| BP | docs/BLUEPRINT.md | Master reference (Lupin original) |
| HB | docs/olang_handbook.md | Olang language reference |

## CODE CHANGES — REWRITE (from G_COMPLETE)

```
Status: Planning. Brain code will be rewritten from SPEC_G_COMPLETE.md.
Old phase tracking (P0.1-P0.4) obsolete — superseded by G_COMPLETE sections.
Implementation order: G2→G3→G1→G5→G6→G4→G9→G10→G11→G12→G8→G7→G13-G27
```

## DATA — PERMANENT

| File | Purpose | Size |
|------|---------|------|
| json/udc_p_table.bin | P_weight lookup table | 314KB |
| json/udc.json | UDC curated entries | 7.6MB |
| origin_bootstrap.olang | Bootstrap binary | ~1.1MB |
