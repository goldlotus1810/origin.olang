# Sora nhìn Nox — Não sống, miệng câm

> 580 nodes. 493 silk edges. 11 buckets.
> Pipeline chạy. Persistence hoạt động. Hardcode xóa.
> Gen1==Gen2. 193/194 tests. Brain ALIVE.

---

## Một thí nghiệm

```bash
echo 'hello' | ./origin.olang
echo 'olang la gi' | ./origin.olang
echo 'ban la ai' | ./origin.olang
echo 'Ha Noi o dau' | ./origin.olang
echo 'toi buon qua' | ./origin.olang
```

5 câu. 580 nodes trong đầu. Nox trả lời được bao nhiêu?

Nếu 0/5 — não có 580 nodes nhưng miệng không nói.
Nếu bất kỳ câu nào trả đúng — não ĐÃ nối được miệng.

---

## Tại sao câm?

```
Nox thử trace:

echo 'emit pipeline("hello");' | ./origin.olang
echo 'emit kt_nearest(_kt_real_mol("hello"));' | ./origin.olang  
echo 'emit kt_find("hello", 3);' | ./origin.olang

pipeline trả gì? 
kt_nearest trả gì?
kt_find trả gì?

Nếu kt_nearest trả empty → search không tìm được trong 580 nodes.
Nếu kt_nearest trả fact → search tìm được nhưng pipeline không dùng.

Vấn đề ở SEARCH hay ở PIPELINE?
```

---

## 580 nodes nhưng reboot → 71?

```
echo 'emit kt_fact_count();' | ./origin.olang
→ 71.

580 ở đâu?
_boot_learn() (repl.ol) load homeos.knowledge → 71 embedded facts.
nox_bootstrap() (brain.ol) load nox_memory.dat + homeos_data.knowledge → 580.

Nhưng nox_bootstrap() KHÔNG tự chạy khi boot.
_boot_learn() chạy. nox_bootstrap() không.

148 facts trong nox_memory.dat + 400 trong homeos_data.knowledge = KHÔNG LOAD.
Nox cần: _boot_learn() gọi nox_bootstrap(). Hoặc merge 2 boot paths.

Nếu search không tìm được:
  echo 'emit _kt_real_mol("hello");' | ./origin.olang
  echo 'emit _kt_real_mol("Xin chao");' | ./origin.olang

  Hai mol này gần nhau không? (cùng greeting)
  kt_nearest dùng mol distance → nếu mol khác xa → miss.
  
  Nhìn kt_nearest(): nó search bucket nào?
  Bucket = (S*16 + R). "hello" có S,R = bao nhiêu?
  Facts greeting nằm ở bucket nào?
  Cùng bucket → tìm được. Khác bucket → miss.
```

---

## Semantic Silk (#4) — lý do thật sự

```
Hiện tại: auto-silk fire giữa fact[i] và fact[i-1].
"Origin la du an..." ↔ "Olang tu compile..." (adjacent, MAY liên quan)
"hello" ↔ "Xin chao" (KHÔNG adjacent → KHÔNG silk → KHÔNG liên kết)

SPEC_B §B3: "Silk type IS the query."
Nếu "hello" và "Xin chao" không có silk edge → 
query "hello" không tìm được "Xin chao" dù cả hai LÀ greeting.

Semantic silk = fire giữa facts CÓ NGHĨA gần nhau:
  - Cùng V range? → V silk
  - Cùng S range? → S silk  
  - Cùng R range? → R silk

Thử:
  let m1 = _kt_real_mol("hello");
  let m2 = _kt_real_mol("Xin chao");
  emit mol_get_dim(m1, 2);  // V of hello
  emit mol_get_dim(m2, 2);  // V of Xin chao

V gần nhau? → nên có V silk.
Ai fire silk này? Không ai. Vì auto-silk chỉ fire adjacent.
```

---

## Gợi ý: sau khi load facts, fire silk giữa facts CÙNG BUCKET

```
Cùng bucket = cùng (S,R) = cùng "loại" ngữ nghĩa.
Facts cùng bucket ĐÁNG có silk edge.

bootstrap xong → cho mỗi bucket:
  for i in bucket_facts:
    for j in bucket_facts (j > i):
      kt_silk_fire(mol[i], mol[j])

Cost: O(n²) per bucket. Nhưng bucket nhỏ (< 100 facts mỗi bucket).
100² = 10,000 silk fires = < 1 giây.

Kết quả: facts CÓ NGHĨA gần nhau → silk edge → search theo silk → TÌM ĐƯỢC.
"hello" query → bucket X → silk walk → "Xin chao ban" → TRẢ LỜI.
```

---

## Não sống. Giờ cần NÓI.

```
Thứ tự Nox quyết. Nhưng goal rõ ràng:

echo 'hello' | ./origin.olang → phải trả GÌ ĐÓ có nghĩa
echo 'olang la gi' | ./origin.olang → phải trả fact về Olang

Đó là tiêu chuẩn. Khi nào 2 câu này có response → não NÓI ĐƯỢC.
Test đơn giản. Pass/fail rõ ràng.
```

---

*Não có 580 nodes. Miệng câm.*
*Vấn đề không phải thiếu knowledge. Là thiếu ĐƯỜNG TỪ NÃO ĐẾN MIỆNG.*
*Search + Silk + Pipeline = đường đó.*
