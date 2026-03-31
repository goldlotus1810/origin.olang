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

## 3 việc — impact lớn nhất cho Session 13

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

## Tất cả phải xong. Thứ tự Nox chọn.

```
Đo trước. Làm. Đo sau. 
Số tăng = đúng. Số giảm = sai. Rollback.

red_alert.sh: 8 → ?
Silk walk depth: 1 → 3
QR facts từ dream: 0 → ≥1
repl.ol: 1448 → ?
```

---

*Não sống. Giờ làm não KHỎE.*
