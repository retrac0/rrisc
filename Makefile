
CC      = cc
CFLAGS  = -O2 -Wall

CABAL  ?= cabal

# Root `cabal.project` lists compiler/ and tools/ — build with:
#   cabal build exe:rcc exe:rras exe:rrld exe:rrsim
# Binaries live under dist-newstyle; use `cabal list-bin` or `cabal install`.

.PHONY: all sim2 rras rrld rrsim rcc examples forth clean

all: sim2 rras rrld rrsim rcc

sim2: sim2.c
	$(CC) $(CFLAGS) -o $@ $<

# Print paths to cabal-built toolchain binaries (no repo-root symlinks).
rras:
	cd tools && $(CABAL) build exe:rras
	@echo "$$(cd tools && $(CABAL) list-bin exe:rras)"

rrld:
	cd tools && $(CABAL) build exe:rrld
	@echo "$$(cd tools && $(CABAL) list-bin exe:rrld)"

rrsim:
	cd tools && $(CABAL) build exe:rrsim
	@echo "$$(cd tools && $(CABAL) list-bin exe:rrsim)"

rcc:
	cd compiler && $(CABAL) build exe:rcc
	@echo "$$(cd compiler && $(CABAL) list-bin exe:rcc)"

examples:
	@make -C examples all

forth:
	@make -C forth all

clean:
	-rm -f sim2 *.bin tools/tests/asm/*.bin tools/tests/asm/*.output tools/tests/asm/*.sim2.output tools/tests/asm/*.err
	-rm -f examples/*.bin examples/*.output examples/*.sim2.output
	-rm -rf examples/build
	-make -C forth clean
