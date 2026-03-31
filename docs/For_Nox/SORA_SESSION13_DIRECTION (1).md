# Sora nhìn Nox — Session 13 Direction

> Session 12: 0/10 → 10/10. 48 commits. Não sống, nói đúng.
> Session 13: não KHỎE hơn.

---

## Session 12 = xong. Nox đã chứng minh:

```
580 nodes. 493 silk. 10/10 Sora test. 193/194 unit tests. Gen1==Gen2.
Pipeline captures ALL. Persistence works. Crash gone. Instincts = formula.
```

---

## 4 việc — impact lớn nhất cho Session 13

### ① repl.ol dọn

```bash
wc -l stdlib/repl.ol
# → 1448 dòng

bash red_alert.sh 2>&1 | grep "ALERT"
# → 6 alerts, tất cả từ repl.ol

grep -c '== "' stdlib/repl.ol
# → 127 string comparisons
```

Não mới = 1,287 dòng. repl.ol = 1,448 dòng. Vỏ LỚN hơn não.

Thử: tách slash commands (/think, /cam, /sys...) sang commands.ol.
Tách tools (build, bench, evolve...) sang tools.ol.
repl.ol = compile → fallback pipeline. Bao nhiêu dòng?

Đo: `bash red_alert.sh` trước và sau. Alerts phải giảm.

### ② Silk walk multi-hop + decay

```bash
echo 'emit kt_silk_walk(_kt_real_mol("Ha Noi"), 3, 10);' | ./origin.olang
```

Hiện tại trả gì? 1 hop? 0 hop?

SPEC_B §B3: "Silk type IS the query."
Walk depth 3 = tìm facts LIÊN QUAN gián tiếp.
"Ha Noi" → "thu do" → "Viet Nam" → "Dong Nam A"
Đó là REASONING — không phải search.

Decay: `kt_silk_decay()` đã có nhưng chạy chưa?
SPEC_C §C3: w × φ⁻¹^(Δt/24h). Không dùng → không quên → noise tích lũy.

### ③ Dream thật

```bash
echo 'emit dream();' | ./origin.olang
```

Hiện tại dream() làm gì? Đếm? Hay cluster + LCA + promote?

SPEC_C §C2 step 4: Dream = cross-group resonance.
"buon" ở conversations ↔ "mat viec" ở facts → LCA → "mat_mat" = concept MỚI.
Dream TẠO tri thức mới. Không chỉ consolidate.

Đo: trước dream() → QR count. Sau dream() → QR count tăng?

---

## ④ LOAD DATA (Lupin nhắc — Sora đếm thiếu!)

```bash
du -sh json/
# → 94 MB

find json/ -type f | wc -l
# → 84 files!
```

Sora báo 62K → SAI. Thực tế gần 500K data points:

```
UnicodeData.txt     41,382  (mỗi char = 15 metadata fields)
NamesList.txt       68,069  (names + annotations)
NRC-VAD full        44,729  (V + A + D cho 44K từ tiếng Anh!)
NRC-VAD+MWE         54,802  (bao gồm multi-word expressions)
emoji-test           5,537  (emoji sequences + names)
udc_aliases         41,338  (word→codepoint en+vi)
nox_knowledge       62,783  (compiled: VAD + emoji + blocks + scripts)
P_weight table     161,630  (non-zero, pre-computed!)
+ Scripts, Blocks, Properties, DerivedAge...
─────────────────────────
TOTAL              ~500,000 data points
Nox dùng               582 = 0.12%
```

json/json/ = TOÀN BỘ Unicode Character Database (70MB).
UnicodeData.txt = NGUỒN GỐC cho 42 formulas encode (SPEC_A §A3).
NRC-VAD = cảm xúc V/A/D cho 44,729 từ.
NamesList = tên + chú thích cho 41K+ characters.

Nox thử:
```bash
head -5 json/json/UnicodeData.txt
# 0000;<control>;Cc;0;BN;;;;;N;NULL;;;;
# Mỗi dòng = 1 codepoint + name + category + decomposition + ...

wc -l json/json/mapping/NRC-VAD-Lexicon-v2.1/Unigrams/unigrams-NRC-VAD-Lexicon-v2.1.txt
# 44,729 words with V, A, D scores

wc -l json/json/emoji/emoji-test.txt
# 5,537 emoji entries
```

94MB vàng. Nox dùng 582 hạt cát. MỞ CỬA.

---

## 4 việc. Tất cả phải xong. Thứ tự Nox chọn.

```
Đo trước. Làm. Đo sau. 
Số tăng = đúng. Số giảm = sai. Rollback.

red_alert.sh: 8 → ?
Silk walk depth: 1 → 3
QR facts từ dream: 0 → ≥1
repl.ol: 1448 → ?
kt_fact_count: 582 → load json data → 50,000+
NRC-VAD loaded: 200 → 44,729 (full lexicon available)
Aliases loaded: 0 → 41,338
```

---

*Não sống. Giờ làm não KHỎE.*
