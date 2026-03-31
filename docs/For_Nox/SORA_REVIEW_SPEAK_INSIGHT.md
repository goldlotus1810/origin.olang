# Sora nhìn Nox — Nói được rồi. Nhưng...

> "Fibonacci la gi?" → "Fibonacci la day so 1 1 2 3 5 8 13..."
> Nox NÓI ĐƯỢC. Root fix: _str_has thay __str_contains (VM broken).
> 20 dòng pure Olang giải quyết cái VM 12,934 dòng ASM không làm được.
> Đó là Olang. Đó là tự do.

---

## Sora test 10 câu

```
"Fibonacci la gi?" → ✅ "Fibonacci la day so 1 1 2 3 5 8 13..."
"Olang la gi?"     → ✅ "Origin la du an tao ngon ngu..."
"HomeOS la gi?"    → ✅ "HomeOS la he dieu hanh tri thuc..."
"buon"             → ✅ "khi nguoi ta buon nen lang nghe..."
"emit 42"          → ✅ 42
"fib(20)"          → ✅ 6765

"hello"            → ❌ (empty)
"ban la ai"        → ❌ "Phu Quoc la dao..." (SAI — hỏi identity, trả địa lý)
"Ha Noi o dau"     → ❌ (empty)
"toi buon qua"     → ❌ (empty)
```

6/10 đúng. 4/10 sai hoặc câm.
+ "toi buon qua" → pipeline("toi buon qua") ĐÚNG! Nhưng qua REPL → empty.
  Kết quả pipeline BỊ MẤT giữa đường.

---

## Nox thử trace tại sao

```bash
# Cái này hoạt động:
echo 'emit kt_find("Fibonacci", 3);' | ./origin.olang
# → tìm được. Vì "Fibonacci" (9 chars ≥ 4) xuất hiện TRONG fact.

# Cái này không:
echo 'emit kt_find("hello", 3);' | ./origin.olang
# → []. Vì "hello" không xuất hiện trong bất kỳ fact nào.

# Cái này CŨNG không:
echo 'emit kt_find("Noi", 3);' | ./origin.olang
# → trả "...Ha Noi..." — tìm được bằng kt_find trực tiếp.
# Nhưng pipeline KHÔNG GỌI kt_find("Noi") vì "Noi" chỉ 3 chars.
```

### Pattern rõ ràng:

```
pipeline search = tách input thành words → lọc word ≥ 4 chars → kt_find

"Fibonacci la gi?" → word "Fibonacci" (9 chars) → kt_find → FOUND ✅
"buon"             → word "buon" (4 chars) → kt_find → FOUND ✅
"hello"            → word "hello" (5 chars) → kt_find("hello") → [] ❌
                     Vì không fact nào CHỨA chữ "hello"
"ban la ai"        → "ban"(3) "la"(2) "ai"(2) → TẤT CẢ < 4 → skip
                     → fall to kt_nearest → trả fact RANDOM ❌
"Ha Noi o dau"     → "Ha"(2) "Noi"(3) "dau"(3) → TẤT CẢ < 4 → skip
                     → fall to kt_nearest → trả empty ❌
"toi buon qua"     → "toi"(3) "buon"(4) "qua"(3) → "buon" ≥ 4 → kt_find
                     → ??? Nox thử: 
```

### Nox chạy thử:

```bash
echo 'emit pipeline("toi buon qua");' | ./origin.olang
# → "khi nguoi ta buon nen lang nghe..." ✅ WORKS!

echo 'toi buon qua' | ./origin.olang
# → (empty) ❌ DOESN'T WORK via REPL!

Cùng input. pipeline() trả đúng. REPL trả empty.
Kết quả pipeline bị MẤT ở đâu giữa pipeline() → REPL output?

_pipeline_result = pipeline(src) — dòng 382.
_pipeline_result DÙNG ở đâu? Dòng nào?
Giữa dòng 382 và dòng dùng, bao nhiêu function calls?
Global var_table: _pipeline_result có bị OVERWRITE không?
```

---

## 2 vấn đề riêng biệt

### Vấn đề A: Tiếng Việt = từ ngắn

```
Tiếng Việt: "ban la ai" = 3 từ, dài nhất 3 chars.
Tiếng Anh: "who are you" = 3 từ, dài nhất 3 chars.
Threshold ≥ 4 chars → BỎ QUA hầu hết tiếng Việt đơn âm.

"Ha Noi" = "Ha"(2) + "Noi"(3) → cả hai < 4 → bỏ qua
Nhưng "HaNoi" (5 chars, không dấu cách) → tìm được.

Giải pháp? Nox nghĩ:
  a. Giảm threshold từ 4 → 2? (quá nhiều false positive?)
  b. Tìm bigram? "Ha Noi" = 1 token? (compound word detection?)
  c. Tìm TOÀN BỘ input string thay vì từng word?
```

### Vấn đề B: "hello" không có trong knowledge

```
580 facts. Bao nhiêu facts chứa "hello"?
  echo 'emit kt_find("hello", 5);' | ./origin.olang → []

0. Không có fact nào về greeting tiếng Anh.
"Xin chao" có không?
  echo 'emit kt_find("chao", 5);' | ./origin.olang → ???

Nếu "xin chao" có → "hello" cần ALIAS.

Sora kiểm tra: kt_find("chao") → "khi nguoi ta chao nen chao lai than thien"
→ CÓ fact greeting tiếng Việt! "chao" (4 chars) → tìm được.
→ "hello" → cần fact chứa "hello" hoặc link hello↔chao trong Silk.
```

---

## kt_nearest — đường thứ hai

```
Khi text search trả empty → pipeline fall to kt_nearest(_mol).
kt_nearest = tìm bằng P_weight molecular distance.
Đó là SPEC_B §B3 search.

"ban la ai" → text search empty → kt_nearest(mol("ban la ai"))
→ trả "Phu Quoc la dao lon nhat..." 

Tại sao? Vì mol("ban la ai") TÌNH CỜ gần mol("Phu Quoc...") trong 5D.
Nhưng ngữ nghĩa KHÁC HOÀN TOÀN.

kt_nearest hiện tại search bucket (S*16+R).
"ban la ai" mol = (S=?, R=?) → bucket X → trả fact đầu tiên trong bucket X.
Fact đầu tiên KHÔNG PHẢI nearest — chỉ là đầu tiên.

Nox thử:
  echo 'let m = _kt_real_mol("ban la ai"); emit mol_get_dim(m,0); emit mol_get_dim(m,1);' | ./origin.olang
  # → S=? R=? → bucket = S*16+R = ?
  # Bucket đó chứa facts gì? Có "Phu Quoc" không?
```

---

## Goal kế tiếp

```
10 câu test. 6 đúng. Target: 8/10.

Cần fix:
  "hello"       → cần fact chứa "hello" HOẶC alias HOẶC greeting concept
  "ban la ai"   → cần search đúng (không random) — kt_nearest trả sai
  "Ha Noi o dau"→ cần search hỗ trợ từ ngắn (Vietnamese words < 4 chars)
  "toi buon qua"→ pipeline TÌM ĐƯỢC nhưng REPL MẤT kết quả (var scope bug?)

4 câu. 4 vấn đề khác nhau. Nox chọn thứ tự.
Tất cả phải pass.
```

---

*Não nói được. 6/10.*
*Chưa đủ. Nhưng hôm qua = 0/10. Hôm nay = 6/10.*
*Đó là tiến bộ THẬT.*
