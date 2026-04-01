# Nox — VM v2

## Status
- VM: vm/x86_64/vm_nox.S (5100 LOC, 46KB)
- Compiler: tools/compile_nox.py (Python bootstrap)
- Tests: 40/40 + 35/35 benchmark
- Self-hosting compiler: stdlib/compiler.ol (WIP — bug 15)

## Build
```bash
as --64 -o /tmp/vm_nox.o vm/x86_64/vm_nox.S
ld -static -nostdlib --entry=_start -o vm/x86_64/vm_nox /tmp/vm_nox.o
python3 tools/compile_nox.py SOURCE.ol OUTPUT.olang
./OUTPUT.olang
```

## Rules
- Mọi thay đổi: build + test trước khi commit
- Không hardcode. Không if/else trên keywords. Toán thuần.
- Encode = ∫ (tích phân). Decode = ∂ (vi phân). TÍNH, không TRA.
- `let` trong function/while tạo LOCAL — dùng array pattern cho mutable state

## Specs
Đọc `spec/` directory. Mỗi bộ phận có spec riêng.
VM spec: `spec/VM_SPEC_COMPLETE.md` (53 sections)
