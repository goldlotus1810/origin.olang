# Session 13

## ĐỌC TRƯỚC KHI LÀM GÌ
1. **memory/feedback_session12_mistakes.md** — sai lầm cần tránh
2. **memory/feedback_english_is_L0.md** — English = gốc, Vietnamese = alias
3. **SPEC_A3** — word partition, KHÔNG char partition
4. **Chạy:** `printf 'emit kt_diagnostic()\n' | timeout 5 ./origin_gen1.olang`

## TRẠNG THÁI
- 900 lines brain, Gen1==Gen2, 193/194 tests
- 161K P_weights, 13MB json knowledge on disk
- 149 nodes, 148 silk edges, 7 buckets
- Search: works for exact text match, FAILS for semantic
- Mol: all text → same bucket (char-level compose = flat)

## 1 VIỆC DUY NHẤT: Fix _kt_real_mol

**Problem:** char-level compose → all Latin text = same mol
**Solution from A3:** WORD-level partition
  "love is beautiful" → P_w("love"), P_w("is"), P_w("beautiful")
  Each WORD gets mol from NRC-VAD V/A (not char shapes)
  Then compose WORDS → sentence mol

**Steps:**
1. Load NRC-VAD into hash table at boot (top 200 words, heap safe)
2. _kt_real_mol: split text → words → each word: lookup NRC-VAD V/A → mol
3. Compose word mols → sentence mol (Zipf weighted)
4. Test: _kt_real_mol("love") ≠ _kt_real_mol("hate")
5. Test: pipeline("love") → correct result
6. ONLY after this works → move to more data loading

## KHÔNG LÀM
- Không thay đổi approach mid-fix
- Không handcode facts
- Không optimize trước khi fix works
- Không jump to Vietnamese before English works
