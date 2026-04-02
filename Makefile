# Nox VM v2

.PHONY: vm test test-ol difftest benchmark clean self-build fixed-point

vm:
	as --64 -o /tmp/vm_nox.o vm/x86_64/vm_nox.S
	ld -static -nostdlib --entry=_start -o vm/x86_64/vm_nox /tmp/vm_nox.o
	@echo "VM: vm/x86_64/vm_nox ($$(wc -c < vm/x86_64/vm_nox) bytes)"

# Core test (uses Python compiler — firmware recovery only)
test: vm
	python3 tools/compile_nox.py test/vm2/test_full.ol test/vm2/test_full.olang
	./test/vm2/test_full.olang

# Full test suite using Olang compiler (NO Python)
test-ol: vm
	./tools/oltest.sh

# Differential test: Python vs Olang compiler output
difftest: vm
	./tools/difftest.sh

benchmark: vm
	python3 tools/compile_nox.py tools/eval/benchmark.ol tools/eval/benchmark.olang
	./tools/eval/benchmark.olang

# Self-build: compile compiler.ol with current compiler.olang
self-build: vm
	printf 'stdlib/compiler.ol\n/tmp/compiler_gen2.olang\n' > /tmp/.nox_args
	./compiler.olang
	cp /tmp/compiler_gen2.olang compiler.olang
	@echo "Self-build OK: compiler.olang ($$(wc -c < compiler.olang) bytes)"

# Fixed-point: Gen2 compiles itself → Gen3, verify Gen2==Gen3
fixed-point: self-build
	printf 'stdlib/compiler.ol\n/tmp/compiler_gen3.olang\n' > /tmp/.nox_args
	./compiler.olang
	diff /tmp/compiler_gen2.olang /tmp/compiler_gen3.olang
	@echo "Gen2==Gen3 MATCH (fixed point verified)"

clean:
	rm -f /tmp/vm_nox.o test/vm2/*.olang tools/eval/*.olang

