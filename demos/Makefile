ROOT    := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))..
RCC_DIR := $(ROOT)/compiler
CABAL  ?= cabal

# cabal run emits progress to stderr; -v0 silences it
RCC := $(CABAL) -v0 run --project-file $(RCC_DIR)/cabal.project rcc --

# Haskell assembler (same stack as run_tests.py); run from repo root for cabal.project
HSASM_RUN := cd $(ROOT) && $(CABAL) -v0 run hsasm --

# Full 0o7770-word flat RAM, IO page at 0o7770, code starting at 0o100.
# Globals at 0o6600 (~65 words); stack grows down from 0o7770 (~580 words of stack).
# Code space: 0o100..0o6577 (~3392 words).
CODE_BASE  := 0o100
DATA_BASE  := 0o6600
STACK_TOP  := 0o7770
SIM_MEM    := --mem ram:0:0o7770
SIM_START  := --start $(CODE_BASE)
SIM := python3 $(ROOT)/sim.py --terminal $(SIM_MEM) $(SIM_START)

RCC_FLAGS := --code-base $(CODE_BASE) --data-base $(DATA_BASE) --stack-top $(STACK_TOP)

.PHONY: all run rpn_float clean

all: rpn.bin

# Soft-float RPN: source is supported, but the linked image exceeds 4k words on
# the stock ISA; assembly fails (see rpn_float.c header). Kept for experimentation.
rpn_float.s: rpn_float.c $(ROOT)/lib/rlibc.h
	cd $(RCC_DIR) && $(RCC) $(RCC_FLAGS) \
	    --preprocessor "cpp -P -I $(ROOT)/lib" \
	    $(ROOT)/demos/rpn_float.c -o $(ROOT)/demos/rpn_float.s

rpn_float.bin: rpn_float.s
	$(HSASM_RUN) -I lib demos/rpn_float.s -o demos/rpn_float.bin

rpn.s: rpn.c $(ROOT)/lib/rlibc.h
	cd $(RCC_DIR) && $(RCC) $(RCC_FLAGS) \
	    --preprocessor "cpp -P -I $(ROOT)/lib" \
	    $(ROOT)/demos/rpn.c -o $(ROOT)/demos/rpn.s

rpn.bin: rpn.s
	$(HSASM_RUN) -I lib demos/rpn.s -o demos/rpn.bin

run: rpn.bin
	$(SIM) rpn.bin

clean:
	rm -f rpn.s rpn.bin rpn_float.s rpn_float.bin
