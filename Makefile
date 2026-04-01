# Nox VM v2

.PHONY: vm test benchmark clean

vm:
	as --64 -o /tmp/vm_nox.o vm/x86_64/vm_nox.S
	ld -static -nostdlib --entry=_start -o vm/x86_64/vm_nox /tmp/vm_nox.o
	@echo "VM: vm/x86_64/vm_nox ($$(wc -c < vm/x86_64/vm_nox) bytes)"

test: vm
	python3 tools/compile_nox.py test/vm2/test_full.ol test/vm2/test_full.olang
	./test/vm2/test_full.olang

benchmark: vm
	python3 tools/compile_nox.py tools/eval/benchmark.ol tools/eval/benchmark.olang
	./tools/eval/benchmark.olang

clean:
	rm -f /tmp/vm_nox.o test/vm2/*.olang tools/eval/*.olang

# Python-free compilation (uses self-hosted compiler)
compile: vm
	@echo 'Usage: echo "source.ol\noutput.olang" > /tmp/.nox_args && tools/nox_compile.olang'

