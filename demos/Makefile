ROOT    := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))..
RCC_DIR := $(ROOT)/compiler
CABAL  ?= cabal

# cabal run emits progress to stderr; -v0 silences it
RCC := $(CABAL) -v0 run --project-file $(RCC_DIR)/cabal.project rcc --

# Haskell assembler / linker (same stack as run_tests.py); run from repo root for cabal.project
RAS_RUN := cd $(ROOT) && $(CABAL) -v0 run ras --
RLD_RUN  := cd $(ROOT) && $(CABAL) -v0 run rld --

# Full 0o7770-word flat RAM, IO page at 0o7770, code starting at 0o100.
# Globals at 0o6600 (~65 words); stack grows down from 0o7770 (~580 words of stack).
# Code space: 0o100..0o6577 (~3392 words).
CODE_BASE  := 0o100
DATA_BASE  := 0o6600
STACK_TOP  := 0o7770
SIM_MEM    := --mem ram:0:0o7770
SIM_START  := --start $(CODE_BASE)
SIM := env PYTHONPATH=$(ROOT) python3 -m pytools.sim --terminal $(SIM_MEM) $(SIM_START)

RCC_FLAGS := --code-base $(CODE_BASE) --data-base $(DATA_BASE) --stack-top $(STACK_TOP)

.PHONY: all run rpn_float clean forth run-forth

all: rpn.bin

# Standalone Forth-style demo: forth/ at repo root (hand-written asm, no rcc)
FORTH_SRCS := $(wildcard $(ROOT)/forth/*.s)
forth.bin: $(FORTH_SRCS)
	$(RAS_RUN) lib/crt0.s -o demos/forth.crt0.o \
	    -D RCC_STACK_TOP=$(STACK_TOP)
	$(RAS_RUN) forth/forth.s -I forth -I lib -o demos/forth.user.o
	$(RLD_RUN) demos/forth.crt0.o demos/forth.user.o -o demos/forth.bin \
	    --code-base $(CODE_BASE) --data-base $(DATA_BASE)

run-forth: forth.bin
	$(SIM) demos/forth.bin

# Soft-float RPN: -O0 keeps this demo under 4k words with lib/itoa.s (not C itoa).
RPN_FLOAT_RCC_FLAGS := $(RCC_FLAGS) -O0

rpn_float.s: rpn_float.c $(ROOT)/lib/rlibc_float_calc.h
	cd $(RCC_DIR) && $(RCC) $(RPN_FLOAT_RCC_FLAGS) \
	    --preprocessor "cpp -P -I $(ROOT)/lib" \
	    $(ROOT)/demos/rpn_float.c -o $(ROOT)/demos/rpn_float.s

# Link crt0 + user only (no librcc): this program strength-reduces stkptr*4 and uses no idiv.
rpn_float.bin: rpn_float.s
	$(RAS_RUN) lib/crt0.s -o demos/rpn_float.crt0.o \
	    -D RCC_STACK_TOP=$(STACK_TOP)
	$(RAS_RUN) demos/rpn_float.s -I lib -o demos/rpn_float.user.o
	$(RLD_RUN) demos/rpn_float.crt0.o demos/rpn_float.user.o -o demos/rpn_float.bin \
	    --code-base $(CODE_BASE) --data-base $(DATA_BASE)

rpn_int.s: rpn_int.c $(ROOT)/lib/rlibc_float_calc.h
	cd $(RCC_DIR) && $(RCC) $(RCC_FLAGS) \
	    --preprocessor "cpp -P -I $(ROOT)/lib" \
	    $(ROOT)/demos/rpn_int.c -o $(ROOT)/demos/rpn_int.s

# Integer RPN needs __div/__mul; rcc already %include's librcc.s at end of rpn.s — do not link librcc.o twice.
# ../lib/rpn_err.s: hand-written rpn_emit_err so rcc does not place a void helper before main (stack bug).
rpn.bin: rpn_int.s $(ROOT)/lib/rpn_err.s
	$(RAS_RUN) lib/crt0.s -o demos/rpn.crt0.o \
	    -D RCC_STACK_TOP=$(STACK_TOP)
	$(RAS_RUN) demos/rpn_int.s -I lib -o demos/rpn.user.o
	$(RAS_RUN) lib/rpn_err.s -I lib -o lib/rpn_err.o
	$(RLD_RUN) demos/rpn.crt0.o lib/rpn_err.o demos/rpn.user.o -o demos/rpn.bin \
	    --code-base $(CODE_BASE) --data-base $(DATA_BASE)

run: rpn.bin
	$(SIM) rpn.bin

clean:
	rm -f rpn.s rpn.bin rpn_float.s rpn_float.bin \
	    demos/rpn.crt0.o demos/rpn.user.o $(ROOT)/lib/rpn_err.o \
	    demos/rpn_float.crt0.o demos/rpn_float.user.o \
	    demos/forth.bin demos/forth.crt0.o demos/forth.user.o
