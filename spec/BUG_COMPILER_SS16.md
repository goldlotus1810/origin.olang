# BUG: Compiler uses hash bytes as variable names

## Found by: SS15 debugging add(10, 20) → returns 20 instead of 30

## Issue
Compiler emits Store/Load with FNV-1a hash bytes as "name" instead of
actual variable name string. The VM's var_store_matrix then hashes these
hash bytes AGAIN, producing wrong slot lookups.

## Evidence
```
Closure body for fn add(a, b):
  Store(a5f10186)   ← these are hash bytes, not "a"
  Store(8cec0186)   ← hash bytes, not "b"
  Load(8cec0186)    ← loads "b" hash
  Load(a5f10186)    ← loads "a" hash
  Add
  Ret
```

## Expected
```
  Store [1] "a"     ← 1-byte name "a"
  Store [1] "b"     ← 1-byte name "b"
  Load  [1] "b"
  Load  [1] "a"
  Add
  Ret
```

## Root Cause
In compile_nox.py, Store/Load emit:
  [opcode][4-byte hash] instead of [opcode][name_len:1][name_bytes:N]

The VM expects name_len + name_bytes format. When it receives hash bytes,
name_len = first hash byte (e.g. 0xA5 = 165), which reads 165 bytes of
garbage as the "name", then hashes THAT garbage.

## Fix
In compiler, change Store/Load emission to:
  emit(OP_STORE)
  emit(len(name))      # 1 byte: name length
  emit(name.encode())  # N bytes: actual name string

NOT:
  emit(OP_STORE)
  emit(hash_bytes)     # WRONG — VM will re-hash these bytes

## Impact
- Multi-arg functions broken (all args map to wrong slots)
- add(10, 20) → 20 (second arg overwrites first due to hash collision)
- Single-arg functions work by accident (only 1 var, no collision)
