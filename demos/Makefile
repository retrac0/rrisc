ROOT    := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))..
RCC_DIR := $(ROOT)/compiler

# cabal run emits progress to stderr; -v0 silences it
RCC := cabal -v0 run --project-file $(RCC_DIR)/cabal.project rcc --

ASM := python3 $(ROOT)/asm.py -I $(ROOT)/lib

# Full 0o7770-word flat RAM, IO page at 0o7770, code starting at 0o100.
# Globals at 0o6600 (~65 words); stack grows down from 0o7770 (~580 words of stack).
# Code space: 0o100..0o6577 (~3392 words).
CODE_BASE  := 0o100
DATA_BASE  := 0o6600
STACK_TOP  := 0o7770
SIM_MEM    := --mem ram:0:0o7770
SIM_START  := --start $(CODE_BASE)
SIM := python3 $(ROOT)/sim.py --terminal $(SIM_MEM) $(SIM_START)

RCC_FLAGS := --optimize --code-base $(CODE_BASE) --data-base $(DATA_BASE) --stack-top $(STACK_TOP)

.PHONY: all run clean

all: rpn.bin

rpn.s: rpn.c $(ROOT)/lib/rlibc.h
	cd $(RCC_DIR) && $(RCC) $(RCC_FLAGS) \
	    --preprocessor "cpp -P -I $(ROOT)/lib" \
	    $(ROOT)/demos/rpn.c -o $(ROOT)/demos/rpn.s

rpn.bin: rpn.s
	$(ASM) rpn.s -o rpn.bin

run: rpn.bin
	$(SIM) rpn.bin

clean:
	rm -f rpn.s rpn.bin
