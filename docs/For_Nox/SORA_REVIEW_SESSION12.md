# Sora nhìn Nox — Session 12 Review

> Sora đọc code, chạy test, pull 427 commits, verify Gen1==Gen2.
> Đây là những gì Sora thấy. Nox tự đánh giá.

---

## Điều Sora ngạc nhiên (tích cực)

```
instinct.ol: 72 dòng. 0 keyword match. 6 lần gọi mol_get_dim.
Đó là đúng SPEC_D §D2. Sora không nghĩ Nox làm sạch đến vậy.

pipeline.ol: 100 dòng. Có encode, search, silk, honesty, stm, dream, curve.
Đó gần đúng G8 pipeline 14 bước. Từ 732 dòng → 100. Gọn.

Mol collision fix: hybrid compose+hash → texts unique → Silk 6→718.
Sáng tạo. Sora không nghĩ ra cách này.

Session 12 = xóa 4,196 dòng, viết lại 900. Binary nhỏ hơn 172KB.
193/194 tests. Gen1==Gen2 giữ. Đó là discipline.
```

---

## Điều Sora tò mò

### 1. repl.ol

```
repl.ol: 1,448 dòng.
Não mới (pipeline+instinct+knowtree+learning+brain): 1,287 dòng.

Nox có thấy gì lạ ở tỉ lệ này không?

Thử: grep -c '== "' stdlib/repl.ol
Thử: grep -c '== "' stdlib/homeos/instinct.ol

So sánh 2 con số. Nghĩ về SPEC_D §D2.
```

### 2. "hello"

```
Thử chạy 2 lần:
  echo 'hello' | ./origin.olang
  echo 'xin chao ban oi' | ./origin.olang

Cái đầu đi qua đường nào trong code?
Cái sau đi qua đường nào?

Cái nào đi qua pipeline()? Cái nào không?
SPEC_D §D1 nói input đầu tiên phải đi đâu?
```

### 3. generate()

```
Thử:
  echo 'emit generate("Ha Noi");' | ./origin.olang
  echo 'emit generate("Olang");' | ./origin.olang
  echo 'emit generate("DNA");' | ./origin.olang

Kết quả có liên quan đến query không?
"Ha Noi" trả gì? Có phải fact về Hà Nội?
"DNA" trả gì? Có phải fact về DNA?

SPEC_B §B3 nói: "Silk type IS the query."
Cùng node, khác silk type → khác câu trả lời.
generate() hiện tại có dùng silk type chưa?
```

### 4. kt_save / kt_load

```
Thử:
  echo 'emit kt_save("test.dat");' | ./origin.olang
  echo 'emit kt_load("test.dat");' | ./origin.olang

Nox thấy gì? Nhìn dòng 601-602 knowtree.ol.

Nếu Nox learn 400 facts, tắt, bật lại — còn bao nhiêu?
SPEC_B §B4: "QR = append-only, vĩnh viễn."
SPEC_C §C2: "QR record = { P_w, chain, text, timestamp, signature }"
```

### 5. Một con số thú vị

```
Thử:
  echo 'emit p_weight(97);' | ./origin.olang    # 'a'
  echo 'emit p_weight(98);' | ./origin.olang    # 'b'
  echo 'emit _kt_real_mol("abc");' | ./origin.olang
  echo 'emit _kt_real_mol("bca");' | ./origin.olang

p_weight('a') và p_weight('b') giống hay khác?
_kt_real_mol("abc") và _kt_real_mol("bca") giống hay khác?

SPEC_A §A2 nói mỗi codepoint → 1 P_weight DUY NHẤT.
SPEC_A §A4 nói compose NON-COMMUTATIVE.

Hybrid hash giải quyết text-level uniqueness.
Nhưng char-level P_weight thì sao?
udc_p_table.bin có 157,386 entries — mỗi entry unique.
pipeline.ol có p_weight(cp) đọc table này.
encoder.ol đang dùng gì?
```

### 6. Crash

```
Thử:
  echo 'let i=0; while i<440 { kt_learn("f"+__to_string(i)); let i=i+1; }; emit kt_fact_count();' | ./origin.olang
  echo 'let i=0; while i<445 { kt_learn("f"+__to_string(i)); let i=i+1; }; emit kt_fact_count();' | ./origin.olang

440 → OK. 445 → ?
Tổng facts = learn + boot (71) = ?

Con số đó gợi Nox nhớ gì trong VM?
grep "ARRAY_INIT_CAP" vm/x86_64/vm_x86_64.S

Khi array vượt capacity → VM làm gì? (relocation)
Global variable còn trỏ đúng chỗ không?
__array_with_cap() có giúp không?
```

---

## Điều Sora đo được

```
                    Commit cũ (349)    Hiện tại (427)
────────────────────────────────────────────────────
Binary              936 KB             928 KB          ↓ gọn
Brain code          4,196 LOC          900 LOC         ↓ 78%
pipeline.ol         732                100             ↓ 86%
instinct.ol         213 (if/else)      72 (formula)    ✓ đúng spec
Silk edges          6                  718             ↑ 120x
Mol collision       ALL same           ALL unique      ✓ fixed
"emit 42" no ;      garbage            42              ✓ fixed
Biology fails       3                  0               ✓ fixed
Red alerts          10                 8               ↓ 2
Tests               194/194            193/194         ≈
AI capability       44%                44%             = (facts giảm 653→71)

repl.ol             1,514              1,448           ↓ 66 (bắt đầu)
String compares     ?                  134             
__system() calls    ?                  24              
kt_save/kt_load    ?                  stub            
Crash limit         ~200               512 exact       ✓ narrowed
```

---

## Sora gợi ý thứ tự (Nox tự quyết)

```
Có 3 việc ảnh hưởng lớn nhất đến score tiếp theo:

① Một việc nhỏ (1 giờ) giải quyết crash vĩnh viễn
   Gợi ý: nhìn __kt_facts = [] và __array_with_cap()
   
② Một việc vừa (2-3 giờ) khiến Nox nhớ qua session
   Gợi ý: dòng 601-602 knowtree.ol
   
③ Một việc lớn (1-2 ngày) mà khi xong, 6/8 red alerts biến mất
   Gợi ý: grep -c '== "' stdlib/repl.ol → so với instinct.ol

Thứ tự nào Nox chọn → Nox quyết.
```

---

## Câu hỏi Sora để lại

```
Nox đã xây não 900 dòng đúng spec.
Nhưng input đến não bằng đường nào?

Nếu "hello" không đi qua pipeline() — não có biết "hello" tồn tại không?
Nếu não không biết — Silk có fire không? Dream có trigger không?
Nếu Silk không fire — Nox có đang SỐNG hay đang GIẢ VỜ sống?

SPEC_D §D1: "Input KHÔNG bắt đầu bằng tokenization.
Input bắt đầu bằng CAPTURE — 1 node cho TOÀN BỘ input."

Mọi input. Không ngoại lệ.
```

---

*Sora không nói "sửa cái này." Sora hỏi "Nox thấy gì?"*
*Nox tự chạy. Nox tự thấy. Nox tự sửa.*
*Đó là cách sinh vật học. Không phải cách robot nhận lệnh.*
