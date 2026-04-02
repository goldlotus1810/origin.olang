# Olang Language Review — What It Has, What It Lacks, What Nox Needs

> Date: 2026-04-02
> Context: compiler.ol self-hosts (B1-B11), Gen2==Gen3 verified

---

## 1. OLANG DANG CO GI

### Types (implicit — khong khai bao)
```
f64          duy nhat 1 kieu so (IEEE 754 double)
string       u16 molecules (moi char 2 bytes, KHONG phai UTF-8)
array        dynamic, flat, f64-indexed
dict         hash table (FNV1a), string keys only
closure      function + captured vars
```

### Control Flow
```
if / else if / else      ✅
while                    ✅
for x in arr {}          ✅ (desugar → while)
match x { v => s; }     ✅ (desugar → if/else chain, == only)
break / continue         ✅
try / catch / throw      ✅
return                   ✅
```

### Functions
```
fn name(a, b) {}         ✅ named functions
fn(a) { return a; }      ✅ anonymous (closure)
closure captures          ✅ (nested fn captures outer vars)
recursion                 ✅
mutual recursion          ✅ (top level only)
```

### Operators
```
Arithmetic    + - * / %
Comparison    == != < > <= >=
Logical       && || !
Bitwise       __bit_and, __bit_or, __bit_xor, __bit_shl, __bit_shr (builtin only)
String        + (concat)
Index         arr[i], arr[i] = val
Dot           obj.field, obj.field = val
```

### Modules
```
import "file.ol"          ✅ (source prepend, dedup)
```

### Builtins (94 total)
```
String:    len, char_at, substr, __char_code, __to_string, __str_find,
           __str_index_of, __str_trim, __str_split, __str_replace,
           __str_join, __str_starts_with, __str_ends_with, __str_to_num
Array:     push, __array_get, __set_at, __array_new, __array_with_cap, __range, __pop_arr
Dict:      __dict_new, __dict_get, __dict_set, __dict_keys
Math:      __abs, __floor, __ceil, __sqrt, __exp, __log2
File:      __file_read, __file_write, __file_append, __file_append_bytes
Network:   __tcp_listen, __tcp_accept, __tcp_send, __tcp_recv, __tcp_close
System:    __system, __sleep, __heap_used, type_of, __mmap, __syscall
```

### Compiler
```
Self-hosting    ✅ compiler.ol compiles itself (1600 LOC)
Bootstrap       ✅ compiler.olang in repo (no Python needed)
Bytecode VM     ✅ 66KB static binary, 67 opcodes
```

---

## 2. OLANG CHUA CO GI

### 2.1 Type System — KHONG CO

```
// Hien tai: moi thu la f64 hoac string, khong phan biet
let x = 42;        // f64
let s = "hello";   // string
let a = [1, 2];    // array (cung la 1 dang pointer)
let d = {x: 1};    // dict (cung la 1 dang pointer)

// KHONG CO:
// - Khai bao kieu: let x: int = 42
// - Check kieu compile-time
// - Struct/class definition
// - Enum/union/variant types
// - Generic/template
// - Interface/trait/protocol
// - Nullable/Option type
```

**Impact:** Nox khong the biet gia tri la gi cho den khi chay. Moi loi la runtime crash.

### 2.2 Struct / Class — KHONG CO

```
// Phai dung dict thay struct:
let point = {x: 1, y: 2};       // khong co schema
point.z = "hello";               // hop le — khong ai check

// KHONG CO:
// - struct Point { x: f64, y: f64 }
// - methods: point.distance(other)
// - inheritance/composition
// - constructor/destructor
// - visibility (public/private)
```

**Impact:** Code lon khong bao tri duoc. Dict khong co contract.

### 2.3 Error Handling — YEU

```
// Hien tai:
try { throw "error"; } catch(e) { emit e; };

// KHONG CO:
// - Error types: throw TypeError("...")
// - Stack trace
// - finally block
// - Error chaining
// - Result<T, E> / Option<T>
// - catch var nhan gia tri that (hien tai catch var = 0 placeholder)
```

**Impact:** Throw bat ky, catch khong biet throw cai gi. Debug kho.

### 2.4 String — U16 MOLECULES, KHONG PHAI UTF-8

```
// Hien tai:
let s = "hello";     // moi char = 2 bytes (u16)
__char_code("a")     // → 97

// KHONG CO:
// - UTF-8 encode/decode
// - Unicode normalization
// - Regex
// - String builder / rope
// - String formatting: f"x = {x}"
// - Multi-line strings: """..."""
// - Raw strings: r"no\escape"
// - Byte strings vs text strings
```

**Impact:** Khong doc/ghi file text dung cach. JSON, XML, HTTP headers deu la UTF-8.

### 2.5 Collections — THIEU

```
// Hien tai:
let a = [1, 2, 3];              // array (dynamic)
let d = {x: 1};                 // dict (string keys)

// KHONG CO:
// - Set
// - Map voi key bat ky (khong chi string)
// - Tuple (fixed-size, mixed types)
// - Linked list
// - Queue / Deque / Stack (stdlib)
// - Sorted map / tree
// - Array methods: map, filter, reduce, sort, find
// - Dict methods: entries, values, has_key, delete
// - Iterators / generators
// - Immutable collections
```

**Impact:** Moi algorithm phai viet tu dau. Khong co `arr.sort()`.

### 2.6 I/O — THO

```
// Hien tai:
__file_read(path)                // doc toan bo file → string
__file_write(path, content)      // ghi string
__tcp_listen / __tcp_send        // raw TCP

// KHONG CO:
// - Buffered I/O
// - Streaming (doc file lon tung phan)
// - stdin / stdout / stderr (chi co emit)
// - File seek / tell
// - Directory listing
// - Path manipulation
// - HTTP client (chi raw TCP)
// - TLS/SSL
// - UDP
// - Unix sockets
// - Pipe
```

### 2.7 Concurrency — KHONG CO

```
// KHONG CO:
// - async / await
// - goroutine / green thread
// - channel / message passing
// - mutex / atomic
// - thread pool
// - event loop
// - Promise / Future

// Chi co:
__syscall(56, ...)   // raw clone() — KHONG an toan
```

### 2.8 Memory — KHONG QUAN LY

```
// Hien tai: bump allocator, KHONG GC
// Zone C: 4MB temp heap — chi tang, khong giam
// Zone A: 256MB permanent

// KHONG CO:
// - Garbage collector
// - Reference counting
// - Manual free
// - Weak references
// - Memory pools
// - Stack allocation cho locals
```

**Impact:** Chay lau = het memory. Khong co cach giai phong.

---

## 3. TAI SAO .OL KHONG THE LA JSON, SQL, BINARY...

### 3.1 Khong doc/ghi JSON

```
// MUON:
let data = json_parse('{"name": "Nox", "age": 1}');
let s = json_stringify(data);

// THUC TE:
// __file_read tra ve string. Nhung Olang KHONG CO JSON parser.
// Khong split string theo { } : " , (phai viet tay)
// Dict chi co string keys — khong co nested types
// Khong co null, boolean (true/false la f64 1/0)
```

**Can:** JSON parser + serializer (~200 LOC in Olang)

### 3.2 Khong doc/ghi Binary Formats

```
// MUON:
let header = read_bytes(file, 0, 4);    // doc 4 bytes
let magic = unpack_u32_le(header);       // parse little-endian u32

// THUC TE:
// __file_read tra ve STRING (u16 molecules), khong phai byte array
// Khong co byte array type
// Khong co pack/unpack struct
// __file_append_bytes nhan array of numbers — CHI GHI, khong doc
// __f64_to_le_bytes chi cho f64, khong co u32/u16/i8
```

**Can:** Byte array type + binary read/write + pack/unpack

### 3.3 Khong lam SQL

```
// Khong co database driver
// Khong co query parser
// Khong co table/schema
// Khong co transaction

// Co the viet simple KV store bang dict + __file_write
// Nhung khong co indexing, querying, ACID
```

**Can:** SQLite binding hoac viet B-tree storage engine (~2000 LOC)

### 3.4 Khong xu ly Data Formats

| Format | Status | Thieu gi |
|--------|--------|----------|
| JSON | ❌ | Parser + serializer |
| CSV | ❌ | String split (co the viet) |
| XML/HTML | ❌ | Parser + DOM |
| YAML | ❌ | Parser |
| TOML | ❌ | Parser |
| Protobuf | ❌ | Schema + codec |
| MessagePack | ❌ | Binary codec |
| Base64 | ❌ | Encode/decode |
| Hex | ❌ | Encode/decode |
| UTF-8 | ❌ | u16 ↔ UTF-8 converter |

### 3.5 Root Cause: String = u16 molecules

Olang strings la **u16 molecule arrays**, khong phai byte arrays.
- Moi char 2 bytes, ke ca ASCII
- Khong co byte-level access
- Khong tuong thich voi bat ky binary format nao
- File I/O convert: file bytes → u16 molecules (doc), u16 → bytes (ghi)
- Convert nay XAY RA TRONG VM, Olang code khong control duoc

**Day la architectural decision.** VM xu ly strings nhu molecules (cho 5D math).
Nhung no khien Olang khong the lam I/O binh thuong.

---

## 4. NOX CAN GI DE TU LAP

### Priority 1 — CAN NGAY (ngon ngu co ban)

| Feature | LOC estimate | Kho |
|---------|-------------|-----|
| Array methods: sort, map, filter, find | ~200 | Trung binh |
| Dict: has_key, delete, entries | ~80 | De |
| JSON parser/serializer | ~300 | Trung binh |
| String: split by string, replace, format | ~100 | De |
| UTF-8 ↔ u16 converter | ~100 | Trung binh |
| Byte array type + binary I/O | ~500 (VM change) | Kho |
| stdin input (beyond __readline) | ~50 (VM) | De |

### Priority 2 — CAN SOM (self-improvement)

| Feature | LOC estimate | Kho |
|---------|-------------|-----|
| Simple type annotations | ~300 | Trung binh |
| Struct definition | ~400 | Trung binh |
| GC hoac arena reset per call | ~800 (VM) | Kho |
| Tail call optimization | ~100 (VM) | Trung binh |
| Better error messages (line numbers) | ~200 | Trung binh |
| Stack trace on crash | ~300 (VM) | Trung binh |

### Priority 3 — CAN DE CANH TRANH (real-world use)

| Feature | LOC estimate | Kho |
|---------|-------------|-----|
| Async I/O (io_uring) | ~1000 (VM) | Rat kho |
| HTTP client/server library | ~500 | Trung binh |
| TLS (or call openssl) | ~2000 hoac FFI | Rat kho |
| Package system | ~500 | Trung binh |
| REPL + debugger | ~800 | Trung binh |
| JIT compilation | ~5000 (VM) | Cuc kho |

---

## 5. TOM TAT

```
Olang DANG LA:
  - Ngon ngu lap trinh don gian, self-hosting
  - Manh ve: closures, pattern match, error handling, 94 builtins
  - Du de viet compiler, brain, agent

Olang CHUA LA:
  - Ngon ngu co the thay the Python/Go/Rust cho real-world tasks
  - Thieu: types, collections, data formats, concurrency, GC
  - Khong doc/ghi JSON, binary, database

BOTTLENECK LON NHAT:
  1. String = u16 molecules → khong tuong thich binary/UTF-8
  2. Khong GC → chay lau = crash
  3. Khong type system → debug kho, refactor kho
  4. Khong data format → khong giao tiep voi the gioi ben ngoai
```

Nox tu compile chinh minh — dieu ma khong AI nao khac lam duoc.
Nhung de TU PHAT TRIEN, Nox can doc duoc data, quan ly memory, va biet minh dang lam gi (types).
