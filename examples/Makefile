# Assemble and (optionally) run RRISC examples under this directory.
#
#   make              # assemble everything into build/
#   make run          # assemble, then run each example in the simulator
#   make run-one RUN=hello       # run a single program (see: make list)
#   make float                   # only the float/* demos (demo-add, demo-mul, ...)
#   make clean
#
# Requires Python 3 on PATH. Assembler flags match the in-tree demos.

ROOT     := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))..
# Recursive invoke: default to POSIX `make` (some environments set MAKE to a non-make binary).
MK       ?= make
ASM      := python3 $(ROOT)/asm.py -I $(ROOT)/lib
SIM      := python3 $(ROOT)/sim.py --terminal --start 0o1000
MAXCY    ?= 10000000

BUILDDIR := build

# Top-level *.s plus float/*.s.
SRC          := $(sort $(wildcard *.s))
FLOAT_SRC    := $(sort $(wildcard float/*.s))
BINS         := $(patsubst %.s,$(BUILDDIR)/%.bin,$(SRC))
FLOAT_BIN    := $(patsubst float/%.s,$(BUILDDIR)/float/%.bin,$(FLOAT_SRC))

.PHONY: all float run run-one list clean

all: $(BINS) $(FLOAT_BIN)

float: $(FLOAT_BIN)

list:
	@echo "Top-level examples (make run-one RUN=<name>):"
	@echo "  $(basename $(SRC))"
	@echo "Float demos (make run-one RUN=float/<name>):"
	@echo "  $(patsubst float/%.s,float/%,$(FLOAT_SRC))"

$(BUILDDIR) $(BUILDDIR)/float:
	mkdir -p $@

$(BUILDDIR)/%.bin: %.s | $(BUILDDIR)
	$(ASM) $< -o $@

$(BUILDDIR)/float/%.bin: float/%.s | $(BUILDDIR)/float
	$(ASM) $< -o $@

run: all
	@set -e; for b in $(BINS) $(FLOAT_BIN); do \
		echo "==== $$b ===="; \
		$(SIM) --maxcycle $(MAXCY) $$b; \
	done

run-one:
	@test -n "$(RUN)" || (echo "Usage: make run-one RUN=<name>   (try: make list)"; exit 1)
	@$(MK) -C "$(dir $(abspath $(lastword $(MAKEFILE_LIST))))" $(BUILDDIR)/$(RUN).bin
	$(SIM) --maxcycle $(MAXCY) $(BUILDDIR)/$(RUN).bin

clean:
	rm -rf $(BUILDDIR)
