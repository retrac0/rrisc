# Loadable flat image: lib/crt0.s + Forth asm (CODE_BASE/DATA_BASE/STACK_TOP below).
ROOT := $(abspath ..)
CABAL ?= cabal
RAS := cd $(ROOT) && $(CABAL) -v0 run rras --
RLD := cd $(ROOT) && $(CABAL) -v0 run rrld --

CODE_BASE  := 0o100
DATA_BASE  := 0o6600
STACK_TOP  := 0o7770
SIM_MEM    := --mem ram:0:0o7770
SIM_START  := --start $(CODE_BASE)
SIM := env PYTHONPATH=$(ROOT) python3 -m pytools.rrsim --terminal $(SIM_MEM) $(SIM_START)

CRT0 := $(ROOT)/lib/crt0.s
FORTH_SRCS := $(wildcard $(CURDIR)/*.s)

.PHONY: all clean run

all: forth.bin

forth.user.o: main.s $(FORTH_SRCS)
	$(RAS) forth/main.s -I forth -I lib -o $(CURDIR)/forth.user.o

forth.crt0.o: $(CRT0)
	$(RAS) lib/crt0.s -o $(CURDIR)/forth.crt0.o -D RCC_STACK_TOP=$(STACK_TOP)

forth.bin: forth.user.o forth.crt0.o
	$(RLD) $(CURDIR)/forth.crt0.o $(CURDIR)/forth.user.o -o $(CURDIR)/forth.bin \
	    --code-base $(CODE_BASE) --data-base $(DATA_BASE)

run: forth.bin
	$(SIM) $(CURDIR)/forth.bin

clean:
	rm -f forth.user.o forth.crt0.o forth.bin forth.o
