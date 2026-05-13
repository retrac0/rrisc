# `lib/` — RRISC runtime, helpers, and headers

Everything the C compiler (`rcc`) needs at run time and everything that makes
hand-written RRISC assembly pleasant lives here. Flat builds often `%include`
supporting `.s` files; **relocatable** builds use **`rras`** (default `.o` output) +
**`rld`**, which resolves symbols across objects (see [`docs/toolchain.md`](../docs/toolchain.md)).

## Layout

```
lib/
  crt0.s              # auto-included by rcc; sets r6, calls main, halts
  librcc.s            # compiler integer runtime: __mul, __udiv, __umod, __div, __mod (jalr); link .o after crt0; see tools/tests/librcc/
  itoa.s              # signed 12-bit itoa (asm-callable; used by rlibc.h
                      # and by lib/float/__ftoa.s)
  rlibc.h             # general-purpose C runtime (I/O, mem*, str*, atoi/itoa/
                      # ftoa/atof)
  rlibc_io.h          # smaller cousin: just I/O + itoa + exit
  rlmath.h            # float math (float_sqrt/abs/pow); needs rlibc.h first
  rlibc_host.h        # POSIX shim, host gcc only — never used on RRISC
  io/
    putchar.s         # UART transmit one byte
    putstr.s          # UART transmit NUL-terminated word string
    getchar.s         # UART receive one byte (spins on RXRDY)
    print_oct.s       # debug print of a 12-bit register as four octal digits
  macros/
    uart_tx.inc       # %defines TXRDY / TXBUF
    uart_rx.inc       # %defines RXRDY / RXBUF
    subr.inc          # call/return scaffolding macros for asm subroutines
    ror3.inc          # 3-bit rotate-right helper used by print_oct.s
  float/
    __fadd.s __fsub.s __fmul.s __fdiv.s __fcmp.s
    __ftoi.s __itof.s __fcopy.s __fneg.s
    __atof.s __ftoa.s
    put_hex12.s       # 12-bit hex print (asm-callable; debug aid)
```

## Float runtime, at a glance

`lib/float/__*.s` is the soft-float runtime that the compiler emits calls into
when a program uses `float`. Each routine takes pointer arguments to 4-word
float48 cells. See [`pytools/float48.py`](../pytools/float48.py) for the bit-level reference
and [`tools/tests/float/run_float_tests.py`](../tools/tests/float/run_float_tests.py) for
the regression harness.

Precision contract for the multiply/divide implementations is documented in
their headers: `__fmul` produces ~24 bits (sig_hi:sig_mid populated, sig_lo
zero); `__fdiv` produces ~12 bits (sig_hi populated, sig_mid/sig_lo zero).
Compounding through `__atof` / `__ftoa` may cost a few additional ulps; the
test harness allows that tolerance.

## Asm-only conventions

- All callable routines follow the same ABI: `r5` is link, `r6` is the
  descending stack pointer, `r2`/`r3`/`r4` carry the first three arguments,
  return values come back in `r2`. `r0` is hardwired zero, `r7` is hardwired
  `0xFFF` (i.e. `-1`).
- `%include` is one-shot per path. If your program uses both `__ftoa` and
  `itoa`, `%include` `lib/itoa.s` once at the bottom of your file and let
  `__ftoa.s` (which expects a label called `itoa`) pick it up.
- The compiler-generated `%include "float/__fadd.s"` strings resolve relative
  to the include root, which is `lib/`. Keep the layout under `lib/float/` if
  you reorganize.
