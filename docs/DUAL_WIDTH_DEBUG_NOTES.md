# Dual-Width u16 Builtins — Debug Notes

## Van de da giai quyet:
1. **Hash computation**: str_bytes() tra LOW BYTES ONLY (ASCII), KHONG phai molecule bytes
   → Hash = FNV-1a tren ASCII bytes, KHONG phai u16 molecule bytes
   
2. **Jump table**: 256 slots (AND $0xFF), KHONG phai 128 (AND $0x7F)
   → Slot = hash & 0xFF

3. **Table offset**: builtin_jump_table label tai line 12505, slot 0 tai line **12506**
   → Slot N = line (12506 + N)

## Correct hashes (ASCII FNV-1a):
```python
def fnv1a_ascii(name):
    h = 0xcbf29ce484222325
    for c in name:
        h ^= ord(c)
        h = (h * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF
    return h

__kt16_alloc: hash=0x3CAD3B655641B231 slot=49  (FREE)
__kt16_get:   hash=0x06FE4EB875595B38 slot=56  (TAKEN - builtin_slot_56)
__kt16_store: hash=0xF724C1E8D06E4BFD slot=253 (TAKEN - builtin_slot_253)
__pw_dist5:   hash=0x4D5EB87F0C82209E slot=158 (TAKEN - builtin_slot_158)
```

## Van de con lai:
- Slot 56, 253, 158 da co builtins khac → can CHAIN (add hash check, jne to existing handler)
- Slot 49 FREE → __kt16_alloc co the implement truc tiep
- Cac slot taken can: `check my hash → je my_impl; jmp existing_handler`

## Cach fix (session 14):
1. Slot 49: truc tiep `.quad .builtin_kt16_alloc`
2. Slots 56, 253, 158: rename builtin labels
   ```asm
   .builtin_kt16_get:
       movabs  $0x06FE4EB875595B38, %rdx
       cmp     %rdx, %rax
       je      .call_kt16_get
       jmp     .builtin_slot_56_original   ; chain to existing
   ```
3. Move existing slot handlers to `_original` suffix
4. Test: emit __kt16_alloc(100); emit __kt16_get(ptr, 0); emit __pw_dist5(65535, 0);

## Hoac: dung ten KHAC co slot FREE
```python
# Tim ten co slot 100% free (khong co builtin nao)
# Free slots (verified): 4, 7, 49, 85 (check 12506+N in jump table)
```
