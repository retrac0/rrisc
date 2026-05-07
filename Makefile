
CC      = cc
CFLAGS  = -O2 -Wall

CABAL  ?= cabal

.PHONY: all sim2 ras rsim rcc examples clean

all: sim2 ras rsim rcc

sim2: sim2.c
	$(CC) $(CFLAGS) -o $@ $<

# Haskell assembler → ./ras (flat assembler, asm.py replacement)
ras:
	cd hstools && $(CABAL) build exe:hsasm
	ln -sf "$$(cd hstools && $(CABAL) list-bin exe:hsasm)" "$(CURDIR)/ras"

# Haskell simulator → ./rsim (sim.py replacement)
rsim:
	cd hstools && $(CABAL) build exe:rsim
	ln -sf "$$(cd hstools && $(CABAL) list-bin exe:rsim)" "$(CURDIR)/rsim"

# RRISC C compiler → ./rcc
rcc:
	cd compiler && $(CABAL) build exe:rcc
	ln -sf "$$(cd compiler && $(CABAL) list-bin exe:rcc)" "$(CURDIR)/rcc"

examples:
	@make -C examples all

clean:
	-rm -f sim2 ras rsim rcc *.bin tests/*.bin tests/*.output tests/*.sim2.output tests/*.err
	-rm -f examples/*.bin examples/*.output examples/*.sim2.output
	-rm -rf examples/build
