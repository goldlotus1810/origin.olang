# HomeOS — origin.olang build system
# Usage:
#   make              — self-build (no Rust needed)
#   make vm           — assemble + link VM only
#   make bootstrap    — initial build with Rust (first time only)
#   make test         — run 205 tests
#   make fixed-point  — verify Gen1 == Gen2
#   make clean        — remove build artifacts

AS       = as
LD       = ld
VM_SRC   = vm/x86_64/vm_x86_64.S
VM_OBJ   = /tmp/vm_olang.o
VM_BIN   = vm/x86_64/vm_x86_64
STDLIB   = stdlib
OUTPUT   = origin.olang
GEN1     = origin_gen1.olang

.PHONY: all vm build bootstrap test fixed-point clean self-build

# Default: self-build (requires working origin.olang)
all: self-build

# Assemble VM (pure GNU as + ld, no Rust)
vm:
	$(AS) --64 -o $(VM_OBJ) $(VM_SRC)
	$(LD) -static -nostdlib --entry=_start -o $(VM_BIN) $(VM_OBJ)
	@echo "VM: $(VM_BIN) ($$(stat -c%s $(VM_BIN)) bytes)"

# Self-build: origin.olang compiles itself → Gen1
self-build: vm
	@test -x $(OUTPUT) || (echo "ERROR: $(OUTPUT) not found. Run 'make bootstrap' first."; exit 1)
	./$(OUTPUT) --build
	mv origin_new.olang $(GEN1)
	chmod +x $(GEN1)
	@echo "Gen1: $(GEN1) ($$(stat -c%s $(GEN1)) bytes)"

# Fixed-point: Gen1 compiles itself → Gen2, verify Gen1 == Gen2
fixed-point: self-build
	./$(GEN1) --build
	@if cmp -s $(GEN1) origin_new.olang; then \
		echo "FIXED-POINT: Gen1 == Gen2 ✓"; \
	else \
		echo "DIFFER: Gen1 != Gen2 ✗"; exit 1; \
	fi
	@rm -f origin_new.olang

# Bootstrap: initial build with Rust compiler (one-time setup)
bootstrap: vm
	@test -d ../Origin_project || (echo "ERROR: ../Origin_project not found (Rust compiler)"; exit 1)
	../Origin_project/target/release/builder \
		--vm $(VM_BIN) --wrap \
		--stdlib $(STDLIB) --codegen \
		-o $(OUTPUT)
	chmod +x $(OUTPUT)
	@echo "Bootstrap: $(OUTPUT) ($$(stat -c%s $(OUTPUT)) bytes)"

# Run all tests
test:
	bash tests.sh

# Clean
clean:
	rm -f $(VM_OBJ) $(GEN1) origin_new.olang origin_gen2.olang origin_gen3.olang
