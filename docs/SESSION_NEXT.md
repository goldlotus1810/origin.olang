# Session Tiep Theo

## TRẠNG THÁI: G1-G27 brain DONE. UDC table cần rebuild.

### Session 12 đã xong:
- Đọc + hiểu sâu toàn bộ A-F + UDC docs
- Viết SPEC_G_COMPLETE.md (27 sections)
- XÓA 4233 dòng brain code cũ → viết lại 900 dòng từ G
- Gen1 works, Gen1==Gen2, 193/194 tests ALL PASS
- G sections: 24/27 implemented (G15=hardware, G21/G23=docs)

### BƯỚC TIẾP THEO: Rebuild UDC P_weight Table

**Vấn đề:** udc_p_table.bin hiện tại dùng hardcoded defaults.
Thiếu: SDF formulas (S), Spline (T), Physics (V/A), Category theory (R).
42 sub-classifiers từ A3 chưa implement.

**Giải pháp:** Rebuild tools/build_full_udc.py với 42 formulas thật:
1. S: SDF type classify (18 primitives) từ UDC_S*_tree.md
2. R: Operator/relation classify từ UDC_R_RELATION_tree.md
3. V: NRC-VAD lexicon + emoji subgroup từ UDC_V_VALENCE_tree.md
4. A: Damped oscillator model từ UDC_A_AROUSAL_tree.md
5. T: Temporal classify từ UDC_T_TIME_tree.md

DNA đúng → mọi thứ downstream (silk, dream, instincts) đúng theo.

### ĐỌC TRƯỚC KHI LÀM GÌ:
1. **SPEC_G_COMPLETE.md** — THE implementation guide
2. **UDC_formulas.md** — 42 formula structure
3. **UDC_*_tree.md** — per-dimension formulas
4. **CLAUDE.md** — build rules

### Build:
```bash
cd ~/Origin && make vm && make self-build && make test && make fixed-point
# Or: origin_bootstrap.olang --build
```
