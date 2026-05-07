
CC      = cc
CFLAGS  = -O2 -Wall

CABAL  ?= cabal

.PHONY: all sim2 ras hsim rcc examples clean

all: sim2 ras hsim rcc

sim2: sim2.c
	$(CC) $(CFLAGS) -o $@ $<

# Haskell assembler → ./ras (flat assembler, asm.py replacement)
ras:
	cd hstools && $(CABAL) build exe:hsasm
	ln -sf "$$(cd hstools && $(CABAL) list-bin exe:hsasm)" "$(CURDIR)/ras"

# Haskell simulator → ./hsim (sim.py replacement)
hsim:
	cd hstools && $(CABAL) build exe:hsim
	ln -sf "$$(cd hstools && $(CABAL) list-bin exe:hsim)" "$(CURDIR)/hsim"

# RRISC C compiler → ./rcc
rcc:
	cd compiler && $(CABAL) build exe:rcc
	ln -sf "$$(cd compiler && $(CABAL) list-bin exe:rcc)" "$(CURDIR)/rcc"

examples: ras
	for src in examples/*.s; do \
		./ras "$$src" || exit 1; \
	done

clean:
	-rm -f sim2 ras hsim rcc *.bin tests/*.bin tests/*.output tests/*.sim2.output tests/*.err
	-rm -f examples/*.bin examples/*.output examples/*.sim2.output
