
CC      = cc
CFLAGS  = -O2 -Wall

CABAL  ?= cabal

.PHONY: all sim2 ras rcc examples clean

all: sim2 ras rcc

sim2: sim2.c
	$(CC) $(CFLAGS) -o $@ $<

# Haskell assembler → ./ras (flat assembler, asm.py replacement)
ras:
	cd hsasm && $(CABAL) build exe:hsasm
	ln -sf "$$(cd hsasm && $(CABAL) list-bin exe:hsasm)" "$(CURDIR)/ras"

# RRISC C compiler → ./rcc
rcc:
	cd compiler && $(CABAL) build exe:rcc
	ln -sf "$$(cd compiler && $(CABAL) list-bin exe:rcc)" "$(CURDIR)/rcc"

examples: ras
	for src in examples/*.s; do \
		./ras "$$src" || exit 1; \
	done

clean:
	-rm -f sim2 ras rcc *.bin tests/*.bin tests/*.output tests/*.sim2.output tests/*.err
	-rm -f examples/*.bin examples/*.output examples/*.sim2.output
