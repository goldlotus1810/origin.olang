# Sora nhìn Nox — 8/10 → 10/10

> 0/10 → 6/10 → 10/10 → revert → 8/10. Trong 1 ngày.
> Nox đúng khi revert: 146 tests quan trọng hơn 2 câu.

---

## Nox đã hiểu đúng vấn đề

```
10/10 fix: "eval empty → fallback to pipeline result"
Broke 146 tests vì: code trả empty = LEGIT (ví dụ: "let x = 1;" → no output)
Nox KHÔNG PHÂN BIỆT được: empty vì code legit vs empty vì text thất bại.
```

---

## 2 câu còn lại

```
"hello" → ❌
  hello? → parse error (? là syntax error)
  hello  → compiler: "hello" = biến chưa khai báo → fail
           → _pipeline_result BỊ MẤT
  Root: không fact chứa "hello". Và pipeline result không dùng khi compile fail.

"buon" → ❌  
  buon? → parse error
  buon  → compiler: "buon" = biến chưa khai báo → fail
           → _pipeline_result = "khi nguoi ta buon..." (ĐÚNG!)
           → nhưng BỊ MẤT
  Root: cùng vấn đề. Pipeline tìm ĐÚNG nhưng repl MẤT.
```

---

## Sora sai ở phân tích trước — sửa lại

```
Sora nói: "pipeline gọi 2 lần" → SAI. Nox đã fix. Chỉ gọi 1 lần (dòng 378).
Sora nói: "_pipeline_result bị overwrite" → CẦN VERIFY.

Thực tế Nox đã code ĐÚNG:
  Dòng 378: let _pipeline_result = pipeline(src);
  Dòng 1370: if len(_pipeline_result) > 3 { return _pipeline_result; }  // ? path
  Dòng 1402: if len(_pipeline_result) > 3 { return _pipeline_result; }  // parse error path

Parse error path HOẠT ĐỘNG:
  "ban la ai?" → ? detected → return _pipeline_result → ✅
  "buon;" → parse error (; after bare word) → return _pipeline_result → có thể ✅

VẤN ĐỀ THẬT:
  "buon" → tokenize → 1 token "buon" → parse → AST: Load("buon") → KHÔNG parse error!
  Compiler nghĩ "buon" = TÊN BIẾN. Parse thành công. Eval → biến không tồn tại → empty.
  _pipeline_result = "khi nguoi ta buon..." (ĐÚNG) nhưng KHÔNG DÙNG vì không parse error.

  "hello" → tương tự. Compiler: "hello" = tên biến. Không parse error.
```

---

## Vấn đề chính xác (sửa lại)

```
"buon" parse thành công (identifier). Eval trả empty. Pipeline result mất.
"let x = 1;" parse thành công. Eval trả empty. Pipeline result KHÔNG NÊN dùng.

Cả hai eval empty. Nhưng:
  "buon" = KHÔNG PHẢI code → nên dùng pipeline
  "let x = 1;" = code THẬT → không nên dùng pipeline

Làm sao phân biệt?
```

---

## Gợi ý (Nox tự chọn)

```
Cách A: sau eval empty, check "input có SYNTAX CODE không?"
  Có semicolon, let, fn, emit, if, while, for → CODE → giữ empty
  Không có gì → TEXT → dùng _pipeline_result
  
Cách B: check _g_pos_box[0] (bytecode size)
  "buon" → Load("buon") → bytecode tiny (vài bytes) 
  "let x = 1;" → bytecode lớn hơn
  Threshold: bytecode < 10 bytes + eval empty → dùng pipeline?

Cách C: check nếu input = 1 từ đơn KHÔNG phải keyword Olang
  → chắc chắn text, không phải code → pipeline trực tiếp
  
Cách D: instinct_route() đã classify trước pipeline.
  Nếu instinct nói "KHÔNG PHẢI code" → skip compiler → dùng pipeline
  SPEC_D nói: instincts chạy TRƯỚC compiler.
```

---

## Test kỳ vọng

```bash
echo 'hello' | ./origin.olang     # → gì đó liên quan greeting
echo 'buon' | ./origin.olang      # → "khi nguoi ta buon..."
echo 'let x = 1;' | ./origin.olang # → (empty, legit)
echo 'emit 42' | ./origin.olang   # → 42
# 193/194 tests PASS
```

---

*8/10 → 10/10 = 2 câu. Nhưng 2 câu đó = bài toán ĐÚNG.*
*Parse error → pipeline result. Eval empty → giữ yên.*
*Phân biệt 2 cái đó = xong.*
