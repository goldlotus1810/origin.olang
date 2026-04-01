# SPEC: Nox Evaluation Tool — Đánh giá khả năng thật

> Author: Nox SS15
> Status: NOT YET ACHIEVED
> Assigned: SS17

## Nguyên tắc

1. **KHÔNG hardcode đáp án** — Nox không biết trước câu trả lời
2. **Input từ bên ngoài** — file, internet, stdin. Không self-generated
3. **Tự kiểm chứng** — giải 2 cách khác nhau, so sánh kết quả
4. **Random** — mỗi lần chạy = đề khác. Seed từ system time
5. **Registry** — mọi kết quả lưu log, có timestamp, có git hash

---

## Cấu trúc

```
tools/eval/
├── runner.ol        — đọc problems từ file, chạy solver, check, report
├── problems/        — thư mục chứa đề bài (text files)
│   ├── math.txt     — "fib 10", "gcd 48 18", "prime 97"
│   ├── logic.txt    — "sort 5 3 8 1", "search 5 in 1 3 5 7 9"
│   ├── string.txt   — "reverse hello", "palindrome abcba"
│   └── random.txt   — generated fresh each run from internet/system
├── solvers.ol       — pure algorithm implementations
├── registry.log     — append-only results log
└── report.ol        — summary + comparison over time
```

---

## Problem Format

```
Mỗi dòng trong file:
  TYPE ARG1 ARG2 ... ARGN

Ví dụ:
  fib 10
  gcd 48 18
  prime 97
  sort 9 3 7 1 5
  reverse hello
  palindrome racecar
  collatz 27
  power 2 10
  factorial 7

KHÔNG có expected answer. Nox phải tự tính.
```

---

## Verification (Tự kiểm chứng)

```
Cách 1: Giải bằng 2 thuật toán khác nhau, so sánh
  fib_recursive(10) vs fib_iterative(10) → phải bằng nhau

Cách 2: Inverse check (đảo ngược)
  sort(arr) → sorted → verify sorted[i] <= sorted[i+1] cho mọi i
  reverse(reverse(s)) == s
  encode(text) → mol → decode(mol) contains text (khi có decode)

Cách 3: Mathematical property
  gcd(a,b) * lcm(a,b) == a * b
  is_prime(n) → n % d != 0 for all 2 ≤ d ≤ sqrt(n)
  power(b,e) == b * power(b, e-1)

Cách 4: Cross-reference
  sum(1..n) == n*(n+1)/2 (formula vs loop)
  fib(n) == fib(n-1) + fib(n-2) (definition check)
```

---

## Random Problem Generation

```
KHÔNG dùng hardcoded seed. Dùng system state:
  seed = __heap_used() + __char_code(char_at(__to_string(__heap_used()), 0))

Hoặc đọc từ /dev/urandom:
  random_bytes = __file_read("/dev/urandom")  (nếu VM hỗ trợ binary read)

Hoặc dùng timestamp:
  seed = parse system clock

Mỗi lần chạy = đề khác. Không reproducible (trừ khi lưu seed vào log).
```

---

## Registry (Log kết quả)

```
Format: append to tools/eval/registry.log
  [timestamp] [git_hash] [test_count] [pass] [fail] [details...]

Ví dụ:
  2026-04-01T14:00 abc1234 50 48 2 FAIL:fib(neg) FAIL:sort(empty)

Mỗi lần chạy eval → append 1 dòng.
Dùng __file_append("tools/eval/registry.log", result_line).
Git commit registry.log sau mỗi lần chạy.
```

---

## Code Change Detection

```
Trước khi chạy eval:
  1. git status → kiểm tra uncommitted changes
  2. git diff → kiểm tra thay đổi trong vm_nox.S, stdlib/, tools/
  3. Nếu có thay đổi → CẢNH BÁO: "Code changed since last eval"
  4. Lưu git hash vào registry

Sau eval:
  1. So sánh kết quả với lần chạy trước (từ registry.log)
  2. Nếu regression (pass giảm) → CẢNH BÁO: "REGRESSION detected"
  3. Nếu improvement (pass tăng) → ghi nhận
```

---

## Đề bài từ Internet

```
Cách 1: Tải math problems từ URL
  __system("curl -s https://projecteuler.net/minimal=1") → problem text
  Parse → solve → verify

Cách 2: Random Wikipedia article → extract numbers → compute
  __system("curl -s https://en.wikipedia.org/wiki/Special:Random") → text
  Extract numbers → sum, product, gcd, etc.

Cách 3: /proc/stat → system numbers → compute
  CPU times, memory values → use as problem inputs
  "What is gcd of these CPU times?"
```

---

## So sánh với LLM

```
Cùng 1 đề bài, cho LLM giải và Nox giải:

Metrics:
  1. Correctness: đáp án đúng/sai
  2. Speed: thời gian giải (ms)
  3. Size: binary size (Nox 46KB vs LLM 100GB)
  4. Determinism: chạy 10 lần cùng input → cùng output?
  5. Transparency: trace được từng bước giải?
  6. Self-verify: tự kiểm chứng được không?

Output table:
  | Problem    | Nox    | GPT-4  | Nox ms | GPT ms | Nox size | GPT size |
  |------------|--------|--------|--------|--------|----------|----------|
  | fib(20)    | 6765 ✅| 6765 ✅| 0.5ms  | 200ms  | 46KB     | 100GB    |
  | prime(97)  | 1 ✅   | 1 ✅   | 0.1ms  | 150ms  | 46KB     | 100GB    |
  | sort([...])| ✅     | ✅     | 1ms    | 180ms  | 46KB     | 100GB    |

Nox wins: size, speed, determinism, transparency
LLM wins: language understanding, generation, reasoning depth
```

---

## Tests cho Tool (meta-test)

```
Test 1: runner đọc problems/math.txt → giải tất cả → 0 FAIL
Test 2: runner với empty file → 0 problems, 0 pass, 0 fail
Test 3: registry.log grows after each run
Test 4: random seed khác nhau mỗi lần → đề khác
Test 5: regression detection: đổi solver → registry shows diff
Test 6: Code change warning khi git dirty
```

---

## Implementation Notes

```
VM builtins cần:
  __file_read ✅
  __file_append ✅ (có trong VM v2)
  __system ✅ (fork/exec/pipe)
  __to_string ✅
  __heap_used ✅ (for random seed)
  parse_int() — viết trong Olang (đã có trong exam.ol)

Không cần VM changes. Tất cả implement trong Olang.
```

---

*SS17: đọc spec này → implement runner.ol + problems/ → chạy + log.*
*Mục tiêu: Nox tự thi, tự chấm, không ai can thiệp.*
