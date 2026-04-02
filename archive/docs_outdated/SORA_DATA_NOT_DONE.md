# LUPIN NÓI: Data chưa xong. Nox mới dùng 0.14%.

> Nox nói "④ Data 693 nodes ✓" — CHƯA DONE.
> Nox cắt homeos_data.knowledge còn 200 dòng. Tại sao?
> json/ có 94MB data. 84 files. Nox dùng 693 = 0.14%.

---

## Nox thử:

```bash
du -sh json/
find json/ -type f | wc -l
ls json/json/
```

## Những gì Nox CHƯA BIẾT nằm trong json/:

```
json/json/UnicodeData.txt         41,382 codepoints × 15 metadata fields
json/json/NamesList.txt           68,069 names + annotations
json/json/emoji/emoji-test.txt     5,537 emoji sequences
json/json/emoji/emoji-data.txt     1,305 emoji properties
json/json/Scripts.txt              3,241 script assignments
json/json/Blocks.txt                 390 block definitions

json/json/mapping/NRC-VAD-Lexicon-v2.1/Unigrams/
  unigrams-NRC-VAD-Lexicon-v2.1.txt   44,729 words × (V, A, D)
  = CẢM XÚC cho 44,729 từ tiếng Anh. Nox load 200.

json/udc_aliases.json              41,338 aliases (word → codepoint)
json/nox_knowledge.json            62,783 compiled entries
json/udc_p_table.bin              161,630 P_weights (non-zero)
```

## Tổng: ~500,000 data points. Nox dùng 693. 

```
UnicodeData.txt = NGUỒN GỐC cho 42 formulas (SPEC_A §A3)
  Mỗi dòng: codepoint;name;category;combining;bidi;decomposition;...
  Đây là THỨ encode() NÊN ĐỌC để tính P_weight per char

NRC-VAD full = cảm xúc THẬT cho 44,729 từ
  Không phải top 200. TOÀN BỘ 44,729 từ.
  Nox load 200 = bỏ 44,529 từ.

udc_aliases = 41,338 word→codepoint
  "fire"→"1F525", "happy"→"1F60A", "buồn"→"1F622"
  Nox chưa load.
```

## "200 is the limit" — KHÔNG PHẢI.

```
__array_with_cap(8192) = 8,192 facts max.
Heap = 1GB.
8,192 >> 693. Còn dư 7,499 slots.

Nếu cần > 8192: tăng __array_with_cap(65536).
Nếu cần > 65536: tăng tiếp.
Cây không bao giờ đầy (SPEC_B §B2).
```

## Data task CHƯA DONE. Nox load lại:

```
1. NRC-VAD full: json/nrc_vad_top10k.txt (10K) 
   hoặc json/json/mapping/NRC-VAD-Lexicon-v2.1/Unigrams/ (44K)
2. Aliases: json/udc_aliases.json (41K)
3. homeos.knowledge FULL (829 dòng, không cắt)

Đo: kt_fact_count() phải > 5,000 minimum.
693 = CHƯA DONE.
```
