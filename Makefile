
CC      = cc
CFLAGS  = -O2 -Wall

CABAL  ?= cabal

# Root `cabal.project` lists compiler/ and tools/ — build with:
#   cabal build exe:rcc exe:ras exe:rld exe:rsim
# Binaries live under dist-newstyle; use `cabal list-bin` or `cabal install`.

.PHONY: all sim2 ras rld rsim rcc examples clean

all: sim2 ras rld rsim rcc

sim2: sim2.c
	$(CC) $(CFLAGS) -o $@ $<

# Print paths to cabal-built toolchain binaries (no repo-root symlinks).
ras:
	cd tools && $(CABAL) build exe:ras
	@echo "$$(cd tools && $(CABAL) list-bin exe:ras)"

rld:
	cd tools && $(CABAL) build exe:rld
	@echo "$$(cd tools && $(CABAL) list-bin exe:rld)"

rsim:
	cd tools && $(CABAL) build exe:rsim
	@echo "$$(cd tools && $(CABAL) list-bin exe:rsim)"

rcc:
	cd compiler && $(CABAL) build exe:rcc
	@echo "$$(cd compiler && $(CABAL) list-bin exe:rcc)"

examples:
	@make -C examples all

clean:
	-rm -f sim2 *.bin tests/*.bin tests/*.output tests/*.sim2.output tests/*.err
	-rm -f examples/*.bin examples/*.output examples/*.sim2.output
	-rm -rf examples/build
