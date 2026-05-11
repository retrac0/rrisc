## RRISC float48 runtime (`lib/float`)

This directory implements a small **soft-float runtime** for RRISC using a custom
48-bit floating format stored in **4x 12-bit words** (“float48”).

### Public ABI (stable entry points)

All routines follow the RRISC calling convention:
- **`r5`**: link register (return address)
- **`r6`**: stack pointer
- Routines generally **clobber `r1–r4`** unless stated otherwise.

Float values are passed as pointers to 4 words:
- `w0`: sign/exp
- `w1..w3`: significand chunks (layout is consistent with `pytools/float48.py`)

Exported entry points:
- **`__fcopy(r2=*dst, r3=*src)`**
- **`__fneg(r2=*dst, r3=*src)`**
- **`__fadd(r2=*dst, r3=*a, r4=*b)`**
- **`__fsub(r2=*dst, r3=*a, r4=*b)`**
- **`__fmul(r2=*dst, r3=*a, r4=*b)`** (hi-precision model; see below)
- **`__fdiv(r2=*dst, r3=*a, r4=*b)`** (hi-precision model; see below)
- **`__fcmp(r2=*a, r3=*b) -> r2 = -1/0/+1`**
- **`__ftoi(r2=*a) -> r2 = int12`** (truncate; hi-precision)
- **`__itof(r2=*dst, r3=int12)`**
- **`__atof(r2=*str, r3=*dst)`**
- **`__ftoa(r2=*a, r3=*buf) -> r2=endptr`**

### Semantics & special cases

This runtime is intentionally small and pragmatic:
- **No subnormals**: underflow returns `+0`.
- `__fadd/__fsub` treat `exp==0` as zero and `exp==2047` as inf/NaN-ish (simplified).
- `__fcmp` returns 0 for NaN comparisons (see implementation notes in `__fcmp.s`).

Precision notes:
- **`__fmul`** and **`__fdiv`** currently operate on `sig_hi` (top 12 bits) only.
  - `__fmul`: 12×12 -> 24-bit product (writes `w3=0`).
  - `__fdiv`: long division over `sig_hi` (writes `w2=w3=0`).

### Integration

Most programs should include or link the bundled translation unit:
- `float/rrisc_float_bundle.s`

The bundle pulls in shared internal helpers (e.g. `_float_store_helpers.s`,
`_float_pack_helpers.s`) before the public routines so labels resolve cleanly.

