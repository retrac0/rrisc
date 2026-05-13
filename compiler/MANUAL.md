# RRISC C Toolchain — User Manual

This manual is for the embedded programmer who already knows C and now has to write
code for **RRISC**, a 12-bit word-addressed machine with 4096 words of address space
and an octal-flavoured instruction set. It assumes you will spend serious time
**writing C that interoperates with hand-written assembly**: calling asm routines,
exposing C functions to asm, dropping `asm("…")` blocks into hot paths, and placing
buffers and code at known addresses.

The manual is organised in four parts.

| Part | Content |
|------|---------|
| I    | Orientation — the machine, the language, the toolchain in one page each |
| II   | Tutorial — one short worked program, end to end |
| III  | Cookbook — focused recipes for the common embedded jobs |
| IV   | Reference — CLI flags, types, ABI, memory layout, inline asm, runtime, omissions |

Companion documents:

- [`Arch.md`](../Arch.md) — the authoritative ISA reference. The manual cites it
  rather than restating bit-fields, opcode tables, or the multi-word arithmetic
  patterns.
- [`compiler/spec.md`](spec.md) — the language reference (precedence tables, EBNF
  grammar). Read it after this manual when you need a single-page lookup.
- [`docs/toolchain.md`](../docs/toolchain.md) — building `rcc` and **rrisc-tools**
  (`rras`, `rrld`, `rrsim`), the **`rcc` → `rras` → `rrld`** contract, object-format
  versioning, and how CI exercises the toolchain.

---

## Part I — Orientation

### 1. What this is, what it isn't

`rcc` accepts a small C-like language. It is **not** a C99 compiler. The deviations
matter for every line of code you write, so internalise them up front.

**Words, not bytes.** Memory is word-addressed. `lwr` and `swr` (the only
load/store instructions) operate on whole 12-bit words. There is no byte addressing.
Every type's size is measured in **words**:

```c
sizeof(int)       == 1
sizeof(int *)     == 1
sizeof(int[8])    == 8
sizeof(float)     == 4    /* 48-bit float48 */
sizeof(struct P)  == sum of fields, in words
```

**Pointer arithmetic is word-scaled.** `p + 1` adds 1 to the address regardless of
`sizeof(*p)`. `a[i]` is `*(a + i)` — i.e. word `i`, not byte `i*sizeof(*a)`. For
arrays of structs, the compiler does multiply `i` by `sizeof(struct S)`; if that
size is a power of two it compiles to a shift, otherwise it strength-reduces or calls
the **`__mul`** helper in **`lib/librcc.s`** (linked as **`librcc.o`** with **`crt0`**).
Prefer power-of-two
struct sizes in performance-sensitive code.

**12-bit `int`.** All integer arithmetic wraps at 12 bits. Signed range is
−2048..2047; unsigned range is 0..4095. There is no `char`, `short`, `long`, or
`double`.

**Structs and functions.** Struct **parameters** and **return values** use pointers
only (`struct S *`). Local variables of struct type — including initialisers and
compound literals — are supported; whole-struct assignment between variables is not
in the supported subset (copy fields or work through pointers).

**One C translation unit per `rcc` run.** `rcc` reads one `.c` file (after optional
host `cpp`) and emits one `.s`. There are no C-level `extern`/`static` or multi-file
linking inside the compiler; combine C sources with `#include`. To join separately
assembled **assembly** objects, use **`rras`** (default `.o` output) and **`rrld`** (see
[`docs/toolchain.md`](../docs/toolchain.md) for assembler / linker wiring,
and [compiler/spec.md §11b](spec.md#11b-rrisc-toolchain-rcc-and-rrisc-tools)).

**No function pointers, no `goto`, no `switch`, no variadics, no dynamic allocation.**
See [What is not implemented](#24-what-is-not-implemented) in the reference.

### 2. The machine in one page

A full reference lives in [`Arch.md`](../Arch.md). Here is the minimum you need
before reading any code:

```
Registers (all 12-bit):
    r0     hardwired 0      (writes silently ignored)
    r1     scratch / li-target / "address temp"   (caller-saved)
    r2     arg 1 / return value                   (caller-saved)
    r3     arg 2                                  (caller-saved)
    r4     arg 3                                  (caller-saved)
    r5     link register                          (callee-saved by non-leaf)
    r6     stack pointer, full descending         (callee-saved)
    r7     hardwired -1 (0o7777)                  (writes silently ignored)
    T      single condition flag, set by sub/add/addc/subi/rol/ror

Address space:
    0o0000 .. 0o7777      4096 words total
    0o7770 .. 0o7773      memory-mapped UART (see below)
    Default code base     0o1000
    Default data base     0o0000
    Default stack top     0o7770

UART (one byte per word in the low 8 bits):
    0o7770   read    TX_RDY    1 = transmitter ready for next byte
    0o7771   read    RX_RDY    1 = a byte is waiting in the receive FIFO
    0o7772   write   TX_BUF    write a byte to send
    0o7773   read    RX_BUF    read the received byte (consumes from FIFO)
```

A few RRISC-isms that bite C programmers:

- Numbers in the toolchain are **octal by default** when they look like
  addresses (e.g. `--start 1000` means 0o1000 in the simulators). Use the `0o`
  prefix in C source for clarity.
- There is no immediate-store form of `lw`/`sw`. Even a global access compiles
  to `li r1, addr; lwr r2, r1`. This is why r1 is reserved as the "address temp."
- The T flag is sticky between instructions. Most ops preserve it; only the
  arithmetic and rotate ops touch it (see `Arch.md` §"T Flag Summary"). Branches
  read T; they do not have a "compare and branch" form.
- The branch range is ±63 words. The assembler will automatically rewrite a
  `bt`/`bf` into a 3-instruction long-branch sequence when needed; you almost
  never have to think about it.

### 3. The toolchain in one diagram

```
             cpp (host preprocessor, optional)
                       │
            myprog.c   ▼   pre-processed .c
               └──► rcc ──► myprog.s  (RRISC assembly; prelude + %include crt0)
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
    rras --format bin -o myprog.bin      rras -o myprog.o
    (flat assemble)                          │
              │                               ▼
              │                         rrld  (link .o → .bin)
              │                               │
              └───────────────┬───────────────┘
                              ▼
                          myprog.bin  (12-bit words, 2 bytes each)
                              │
                              ▼
                  rrsim (Haskell)  or  pytools.rrsim (Python)  or  sim2 (C)
```

The usual **flat** path is `rcc` → **`rras --format bin`** → `.bin` → simulator. The
**relocatable** path (**`rras`** → **`.o`** → **`rrld`**) is how you combine hand-written
assembly objects with generated code or split asm across files; see
[`docs/toolchain.md`](../docs/toolchain.md). The three simulator implementations and
the two assembler implementations (`rras` vs deprecated `pytools.asm`) are
**behaviourally identical** for our purposes. This manual uses `rcc` / `rras` / `rrsim`
by default.

A typical full build is three commands:

```sh
rcc  --preprocessor "cpp -P -I lib"  myprog.c        -o myprog.s
rras  --format bin -I lib             myprog.s        -o myprog.bin
rrsim --terminal --start 0o1000       myprog.bin
```

The `--preprocessor` flag tells `rcc` to run a host-side `cpp` over the source
first. This is how `#include "rlibc.h"` works — `rcc` itself does not implement
the C preprocessor.

---

## Part II — Tutorial: Hello, UART

We will write a program that reads a line from the UART and echoes it back. Every
embedded program eventually does some variation of this, and it touches every part
of the toolchain.

Save this as `hello.c`:

```c
#include "rlibc_io.h"

int main() {
    int buf[64];
    gets(buf);
    puts(buf);
    exit(0);
    return 0;
}
```

Three things to notice. First, `int buf[64]` is a 64-word stack array — these are
12-bit words, so it holds 64 characters. Second, `gets` and `puts` come from
`lib/rlibc_io.h`, the small I/O subset of the standard library; it is a header-only
library that drops directly into your translation unit. Third, `exit(0)` is the
clean way to halt the simulator (it expands to a single `halt` instruction).

Build it:

```sh
rcc  --preprocessor "cpp -P -I lib"  hello.c  -o hello.s
rras  --format bin -I lib             hello.s  -o hello.bin
```

Run it under the simulator with the UART terminal attached:

```sh
echo "hello, RRISC" | rrsim --terminal --start 0o1000 hello.bin
```

You should see `hello, RRISC` echoed back.

A few notes on the invocation:

- **`--preprocessor "cpp -P …"`.** `rcc` does not understand `#include` or `#define`
  on its own. Pipe through host `cpp` to get those. The `-P` flag suppresses
  linemarkers, which `rcc` would not understand.
- **`-I` directories.** Both passed to `cpp` (so it can find `rlibc_io.h`) and to
  `rras` (so it can find `crt0.s`, which the compiler-emitted assembly `%include`s).
- **`--start 0o1000`.** This must match `rcc`'s `--code-base` (default `0o1000`).
  If you change the code base, change `--start` to match.
- **`--terminal`.** Without this, reads from `0o7771`/`0o7773` return zero and
  writes to `0o7772` are dropped. The terminal device hooks those addresses up to
  stdin/stdout.

If something does not work, two debugging knobs:

```sh
rcc --dump-tac hello.c          # print three-address IR (no asm output)
rrsim --trace hello.bin           # print every instruction as it executes
```

---

## Part III — Cookbook

Each recipe is a short C snippet you can drop into a real program, with two or
three sentences explaining why it works. None of these require modifying the
compiler.

### 5. Read a memory-mapped I/O register at a fixed address

```c
int read_uart_status(void) {
    int *rxrdy = (int *)0o7771;
    return *rxrdy;            /* 1 = a byte is available */
}
```

The `(int *)` cast turns a literal address into a pointer; `*rxrdy` compiles to
`li r1, 0o7771; lwr r2, r1`. Use this pattern for any device register. Pin the
pointer in a `const` global if you reuse it:

```c
const int * const TX_BUF = (int *)0o7772;
```

### 6. Call a hand-written assembly routine from C

Write `mul24.s`:

```asm
; mul24(int *result, int a, int b) — result[0..1] = a*b as a 24-bit value.
; ABI: r2=result, r3=a, r4=b.  Trashes r1; preserves r5/r6.
mul24:
    ;  ... your hand-rolled multiply ...
    jalr r0, r5                 ; return
```

Declare the prototype in C and call as normal:

```c
void mul24(int *result, int a, int b);   /* prototype only — definition is asm */

int main() {
    int wide[2];
    mul24(wide, 200, 300);
    return wide[0];                       /* low 12 bits of 60000 = 0xEA60 & 0xFFF */
}
```

Then `%include "mul24.s"` from the generated `myprog.s` (the easy way: keep your
hand-written asm next to your C and add a `%include` to the generated file in
your build script, or splice it into `crt0.s`'s wrapper).

The compiler's only obligation is to load arguments into r2/r3/r4, issue
`jalr r5, r1`, and read the return from r2. Your asm gets exactly that contract:
do whatever you want with r1–r4, but if you call other functions you must save
r5 (and restore r6 to your entry value before `jalr r0, r5`). See
[§20 Calling convention](#20-calling-convention).

### 7. Call a C function from assembly

The mirror image is just as straightforward. If C declares

```c
int add3(int a, int b, int c) { return a + b + c; }
```

then asm code calls it like any other RRISC function:

```asm
    li   r2, 10
    li   r3, 20
    li   r4, 30
    li   r1, add3
    jalr r5, r1            ; result lands in r2
```

Register names in `rcc`-emitted assembly match the C name unprefixed. There is no
name mangling.

### 8. Embed a constant table in rodata

```c
const int sin_table[16] = {
    0, 50, 98, 142, 180, 212, 236, 250,
    256, 250, 236, 212, 180, 142, 98, 50,
};
```

`const` globals go into the code/rodata section, which is **ROM-safe** under the
default split layout (`--code-base 0o1000`, `--data-base 0o0000`). Reading them is
no different from reading a mutable global: `li r1, sin_table; addi r1, i; lwr r2, r1`.

### 9. Inline one or two RRISC instructions with `asm("…")`

```c
int popcount_low(int x) {
    int n;
    /* Move x into r2 (the slot for x is already there as a side effect of being
       loaded for the next op), then use ror to drop the bottom bit into T and
       count the carry. */
    asm("ror r2, r2");
    asm("addc r3, r0, r0");  /* r3 = 0 + 0 + T  =  bit just shifted out */
    /* ... */
    n = 0;
    return n;
}
```

Two things to remember about `asm()`:

1. **The body is emitted verbatim.** Escape sequences in the string are not
   processed (`Parser.hs:346`). To put two instructions in one `asm` call, embed
   an actual newline:
   ```c
   asm("subi r6, 1
   swr r2, r6");
   ```
   Or — much cleaner — use two `asm()` calls.
2. **There is no GCC extended-asm syntax.** You cannot write
   `asm("..." : "=r"(x) : "r"(y))`. To shuffle a C variable in or out, take its
   address and use `lwr`/`swr` explicitly.

A more important hazard than register clobbering is described in
[§22 Inline asm](#22-inline-asm).

### 10. Pin a buffer at a known RAM address

```c
int *framebuffer = (int *)0o2000;

void clear(void) {
    int i;
    for (i = 0; i < 256; i = i + 1)
        framebuffer[i] = 0;
}
```

`rcc` will not place anything at `0o2000` unless you point `--data-base` at it,
so as long as you reserve that region in your memory map (e.g. with a `--mem`
flag to the simulator, or in your hardware design) this works directly. There
is no `__attribute__((section))` — pointer casts are the mechanism.

### 11. 24-bit arithmetic by hand

12 bits is not always enough. Two-word arithmetic with carry is straightforward
once you remember that `addc` reads and writes T:

```c
void add24(int *r, int *a, int *b) {
    asm("clrt");                         /* T = 0 */
    /* low word: r[0] = a[0] + b[0]; T = carry */
    /* high word: r[1] = a[1] + b[1] + T */
    /* This block hand-rolls those two adds because the compiler does not
       expose addc directly. The variables are addressed via stack-local r6
       offsets; rather than compute those by hand, load the pointers first: */
    asm("lwr r1, r3");                   /* r3 = a (already in slot)        */
    /* … see Arch.md "Multi-word add" for the canonical pattern …          */
}
```

The full multi-word add/subtract/shift sequences are in `Arch.md` under
"Multi-Word Arithmetic Patterns". Wrap each one in a small leaf function and
forget about it.

### 12. Float for one-off math without paying for it everywhere

Floats are 4-word values and arithmetic on them is **always** a runtime call —
`__fadd`, `__fsub`, `__fmul`, `__fdiv`, etc. The compiler is smart enough to
only `%include` the helpers a program actually calls (`Codegen.hs:80-96`):
write `int x = (int)(a + b)` between two floats and you pay for `__fadd` and
`__ftoi` but not `__fdiv`. So sprinkling a single `float_sqrt` call into an
otherwise integer program costs you ~200 words of code, not the whole library.

```c
#include "rlibc.h"
#include "rlmath.h"

int main() {
    float r;
    float n = 2.0;
    float_sqrt(&r, &n);
    /* r ≈ 1.41421 */
    return 0;
}
```

Note that floats are **always passed by pointer** — see [§18 Type system](#18-type-system).

### 13. Choose between split and packed memory layouts

Two layouts come up:

- **Split** (the default, ROM-safe): code+rodata at `--code-base` (default
  `0o1000`); mutable globals separately at `--data-base` (default `0o0000`).
  Use this when the code section is in ROM.
- **Packed**: pass `--data-base` ≥ `--code-base` and the compiler emits mutable
  globals first at `--data-base`, then the code immediately after them. Use
  this for an all-RAM image.

The relevant codegen logic is in `Codegen.hs:101-128`. For a typical embedded
target:

```sh
rcc --code-base 0o1000  --data-base 0o0000  --stack-top 0o7770  prog.c -o prog.s
```

If you change `--code-base`, also change `--start` on the simulator to match.

---

## Part IV — Reference

### 13. CLI: `rcc`

```
rcc [options] <input.c>
```

| Flag | Default | Effect |
|------|---------|--------|
| `-o <file>`             | stdout      | Write `.s` to `<file>` |
| `--code-base <n>`       | `0o1000`    | Address of `_start` and rodata |
| `--data-base <n>`       | `0o0000`    | Address of mutable globals (and BSS) |
| `--stack-top <n>`       | `0o7770`    | Initial value of r6 (stack grows down from here) |
| `--preprocessor "<cmd>"` | none       | Run `<cmd> <input>` over the source first; line markers stripped |
| `-O0`                   | —           | No Cytron SSA (plain CFG); no SSA opt pipeline; minimal TAC passes |
| `-Os`                   | **default** | Optimize for size (SSA + TAC defaults; includes CFG branch threading) |
| `-O1`                   | —           | Same SSA/TAC defaults as `-Os` today (reserved for future speed-oriented passes) |
| `-O2`                   | —           | Same as `-O1` (compat alias) |
| `--pass +id,-id,…`      | none        | Enable/disable individual SSA/TAC passes (unioned with the `-O` defaults) |
| `--optimize`            | —           | Compatibility: same as `-Os` |
| `--no-optimize`         | —           | Compatibility: same as `-O0` |
| `--dump-ast`            | off         | Print AST and exit |
| `--dump-ssa`            | off         | Print SSA program (debug) and exit |
| `--dump-tac`            | off         | Print TAC and exit |
| `-V`, `--version`       | —           | Print `rcc` version and exit |

Numbers in flags use the same lexical conventions as RRISC source: `0o1000` for
octal, `0xFF` for hex, decimal otherwise. `rcc` itself does not implement `#include`
or `#define`; pipe through `cpp -P` (or any other preprocessor that emits plain C
without linemarkers).

### 14. CLI: `rras`, `rrld`, and deprecated `pytools.asm`

The canonical assembler implementation in this repository is the Haskell tool **`rras`**. The Python driver **`python3 -m pytools.rras`** ([`pytools/rras.py`](../pytools/rras.py)) exposes the same CLI: **relocatable `.o`** output (default) is produced by the **Python** assembler ([`pytools/asm.py`](../pytools/asm.py) plus [`pytools/asm_obj_emit.py`](../pytools/asm_obj_emit.py)), emitting the same textual object format as the Haskell **`rras`**. Pass **`--format bin`** or **`--format readmemb`** for a **flat** image with the same encoder (same behaviour as deprecated **`pytools.asm`**). **`python3 -m pytools.rrld`** is the Python linker and matches Haskell **`rrld`** on textual `.o` files from **either** assembler.

The legacy Python flat assembler (**`python3 -m pytools.asm`**, [`pytools/asm.py`](../pytools/asm.py)) is **deprecated** (it prints a warning) and remains only for backward compatibility.

**Haskell `rras`** / **`python3 -m pytools.rras`** (default): emits a relocatable **`.o`** (`-o` optional; otherwise `<source>.o`). For a **flat** image, pass **`--format bin`** or **`--format readmemb`**; then `-o` names the `.bin` or `.mem` file.

`pytools.asm` keeps a legacy interface (flat output by default):

```
rras  source.s  [-o file.o]  [-I dir]…  [--format bin|readmemb]  [--list]  [--dump-syms file.o]
python3 -m pytools.rras  source.s  [-o file.o]  [-I dir]…   # Python .o / flat with --format
python3 -m pytools.asm  source.s  [-o output.bin]  [-I dir]…  [--format bin|readmemb]  [--list]
```

| Flag | `rras` default | Effect |
|------|---------|--------|
| `-o, --output <file>`           | `<source>.o` (no `--format`); with `--format`, `<source>.bin` or `.mem` | Output path |
| `-I <dir>`                      | (cwd only)     | Add include search dir; repeatable. Search order is the source file's directory, then `-I` dirs in order |
| `--format bin\|readmemb`        | (off — object mode) | Flat output: `bin` = raw bytes (see §17). `readmemb` = Verilog `$readmemb` text, one 12-bit binary word per line |
| `--list`                        | off            | Print an assembly listing to stdout (**flat mode only**) |
| `--dump-syms <file.o>`          | —              | Print symbols from a textual `.o` and exit |

`lw` and `sw` (without the `r` suffix) are deliberately rejected. Use `lwr` and
`swr` — every load/store on RRISC is register-indirect.

Branch relaxation is automatic: `bt`/`bf` past the ±63-word direct range are
rewritten into a three-instruction sequence by both implementations. You do not
need to think about branch distance in source.

### 15. CLI: `pytools.rrsim`, `rrsim` (Haskell), and `sim2`

Use **`python3 -m pytools.rrsim`** as the canonical Python simulator entry point (implementation in [`pytools/sim.py`](../pytools/sim.py)). The Haskell binary is **`rrsim`** from **`rrisc-tools`**.

All three accept the same flags:

```
python3 -m pytools.rrsim <binary.bin>  [--start ADDR]  [--terminal]  [--uart-preload STR]
                  [--trace]  [--bustrace]  [--summary]  [--randomize]
                  [--maxcycle N]  [--mem TYPE:BASE:SIZE]…  [--translate]
```

| Flag | Default | Effect |
|------|---------|--------|
| `--start ADDR`           | `0`            | Initial PC. **ADDR is parsed as octal** (bare `1000` means 0o1000). Use the same value as `rcc`'s `--code-base`. |
| `--terminal`             | off            | Attach the UART device at 0o7770–0o7773. Reads pull from stdin (or `--uart-preload`); writes echo to stdout |
| `--uart-preload STR`     | none           | Pre-fill the RX FIFO with a UTF-8 string and disable stdin. Useful for scripted runs |
| `--trace`                | off            | Print each instruction (PC, IR, disassembly) as it executes |
| `--bustrace`             | off            | Log every memory read and write |
| `--summary`              | off            | Print final register state and instruction count on halt |
| `--randomize`            | off            | Scramble r1–r6, T, and RAM before loading the program (catches use-of-uninitialised) |
| `--maxcycle N`           | unbounded      | Halt with error if more than `N` instructions execute |
| `--mem TYPE:BASE:SIZE`   | one default RAM bank | Add a memory bank. TYPE ∈ `ram`, `rom`, `io`. Repeatable. |
| `--translate`            | off            | Apply SIXBIT translation on terminal I/O. Default is raw UTF-8 bytes |

Halt: a program halts cleanly by executing the all-ones instruction (0o7777),
which the C runtime emits when `main` returns or `exit()` is called. The exit
code from the simulator is 0 on clean halt, non-zero if `--maxcycle` was
exceeded.

### 16. Assembler directives

The Haskell assembler (`rras`) is canonical; deprecated `pytools.asm` agrees on these forms:

| Directive | Form | Meaning |
|-----------|------|---------|
| `%define` | `%define NAME value` | Whole-word text substitution. `rcc` uses this to inject `RCC_CODE_BASE`, `RCC_DATA_BASE`, `RCC_STACK_TOP` for `crt0.s` |
| `%include` | `%include "file.s"` | Splice another source file inline. Searches the current source's directory, then `-I` dirs. Cycle detection. |
| `%ifdef` / `%ifeq` / `%ifneq` | `%ifdef NAME` … | Conditional inclusion. Pair with `%endif` |
| `%macro` / `%endm` | `%macro NAME [p1, p2]` … `%endm`  *or*  `%macro NAME N` … (positional `%1`..`%N`) | Macro definition. NASM-style positional or named parameters |
| `.global` / `.globl` | `.global name [, name …]` | **Object / linking (`rras` → `.o`, `rrld` only):** mark definitions as **global** (visible across `.o` files), like C file-scope symbols without `static`. Labels default to **local** (visible only within the same relocatable object). |
| `.local` | `.local name [, name …]` | **Linking:** force **local** linkage; later `.global` / `.globl` in the same file can still override for names listed again after `.local`. |
| `.word` | `.word v1, v2, …` | Emit one raw 12-bit word per value |
| `.float` | `.float f1, f2, …` | Emit four 12-bit words per float (48-bit float48 layout) |
| `.fill` | `.fill count [, value]` | `count` words of `value` (default 0) |
| `.align` | `.align N` | Advance the location counter to the next multiple of `N` |
| `.org` | `.org address` | Set the absolute address counter (no code emitted) |
| `.str` | `.str "string"` | Emit one word per UTF-8 byte |
| `.strz` | `.strz "string"` | Same as `.str` plus a trailing 0 word (NUL terminator) |
| `.sixbit` | `.sixbit "string"` | Emit one word per SIXBIT-encoded character |
| `.base` | `.base rN, value` | Declare a base register's compile-time value (for register-relative addressing) |

### 17. Binary format

`--format bin` (the default) produces a raw 2-byte-per-word file, little-endian:

```
byte 0 = word & 0xFF
byte 1 = (word >> 8) & 0x0F     ; upper four bits of byte 1 are unused
```

A 4096-word RRISC image is therefore 8192 bytes. The simulators reject files
whose length is not a multiple of 2.

`--format readmemb` produces a text file with one 12-bit binary word per line,
suitable for Verilog's `$readmemb`.

### 18. Type system

| Type      | Size (words) | Notes |
|-----------|--------------|-------|
| `int`     | 1            | Signed 12-bit; range −2048..2047 |
| `unsigned` | 1            | Same storage as `int`; comparisons use unsigned semantics |
| `bool`    | 1            | Alias of `int`. `true` and `false` are integer literals 1 and 0 |
| `void`    | —            | Function return type only |
| `float`   | 4            | 48-bit float48. **Always passed and returned by pointer** |
| `T *`     | 1            | Pointer to T |
| `T[N]`    | N×sizeof(T)  | Array. Decays to `T*` in expressions |
| `struct S`| sum of fields | Contiguous, declaration order. **Pass and return from functions by pointer only** (locals and compound literals are fine). |
| `typedef` | —            | Supported (`typedef struct Point Point;`) |

`sizeof` is a compile-time `int` constant returning words.

`const` on a global places it in rodata (the code section, ROM-safe). `const`
on a local has no storage effect; the compiler does not enforce write attempts
on `const` locals beyond the type system.

### 19. Expressions and statements

The grammar is in [`spec.md`](spec.md). The expression set the parser actually
accepts is a strict subset of C99, with three additions and a few omissions:

**Present and unrestricted:**
- All arithmetic, bitwise, shift, comparison, logical, and assignment operators in
  the precedence table in `spec.md`.
- Ternary `cond ? a : b`.
- Compound literals `(struct Point){3, 4}` — allocates a temporary and
  returns its address-or-value as appropriate.
- String literals `"hello\n"` — emitted as null-terminated word arrays in rodata
  with type `int *`. Supported escapes: `\n \t \r \0 \" \\`.
- Character literals `'A'` — integer constant equal to the character's Unicode
  code point. Same escapes as string literals.

**Statements:** `{…}`, declarations, expression-statements, `if`/`else`, `while`,
`for` (with C99-style declaration in init), `return [expr];`, `break`,
`continue`, and `asm("…");`.

**Not supported:** `goto`, `switch`/`case`, `do…while`. Transformed `do…while`
into `while (1) { …; if (!cond) break; }` if you need it.

### 20. Calling convention

**Source of truth for the codegen is `Codegen.hs:230-269`.**

```
r0 = 0 (hardwired)        r4 = arg 3                  caller-saved
r1 = scratch / li-target  r5 = link register          callee-saved by non-leaf
r2 = arg 1 / return       r6 = stack pointer (full descending)
r3 = arg 2                r7 = -1 (hardwired)
```

**Prologue** (every non-empty function):
```
subi r6, 1            ; push slot for r5
swr  r5, r6           ; save link register
subi r6, n            ; allocate n words for locals + spill slots
swr  r2, …            ; spill arg 1 into its slot
swr  r3, …            ; spill arg 2 …
swr  r4, …            ; spill arg 3 …
                      ; (stack args are loaded from the caller's push area)
```

**Epilogue:**
```
addi r6, n            ; free locals
lwr  r5, r6           ; restore link
addi r6, 1            ; pop saved-r5 slot
addi r6, numStack     ; pop any stack args the caller pushed
jalr r0, r5           ; return
```

**Stack arguments.** Arguments 4, 5, … are pushed by the **caller**, **right to
left** (`Codegen.hs:407-420`). The **callee** pops them in its epilogue. This
keeps the caller-side bookkeeping minimal (no per-call cleanup) at the cost of
making every call site that has stack args force the callee to know how many
were pushed — so cross-implementation function calls must agree on the
arity.

**Indirect calls.** The compiler always uses `r1` as the `li` target so that
`r2`–`r4` remain free for arguments:

```
li   r1, target_label
jalr r5, r1            ; r5 = return-address; pc = r1
```

If you write asm that calls a function, follow the same idiom.

**Float ABI.** Float arguments and float returns are always passed via a
**pointer to a 4-word slot**. The compiler-internal helper functions
(`__fadd`, `__fsub`, `__fmul`, `__fdiv`, `__fcmp`, `__ftoi`, `__itof`,
`__fcopy`, `__fneg`) take pointer arguments in `r2`/`r3`/`r4` and write their
result to the destination passed in `r2` (`__fcmp` is the exception: it
returns an int in `r2`). Float calls are lowered in
[`RCC/LowerToSSA.hs`](../src/RCC/LowerToSSA.hs) (`lowerFloatBinOp` / `floatArith`);
[`RCC/Codegen.hs`](../src/RCC/Codegen.hs) emits the `jalr` calling sequences.

### 21. Memory layout

`rcc` emits two logical sections, both relocatable via flags:

| Section | Default | Contents |
|---------|---------|----------|
| Code + rodata | `--code-base 0o1000` | Instructions, `const` globals, string literals, float constant pools |
| Data    | `--data-base 0o0000` | Mutable globals, BSS (zero-init), stack |

The compiler picks one of two layouts based on `--code-base` vs `--data-base`:

- **Split layout** — when `--code-base < --data-base` and the program has
  mutable globals. Output is: prologue (`%define`s + `%include "crt0.s"`),
  code at `code-base`, then `.org data-base` for mutable globals. ROM-safe.
- **Packed layout** — otherwise. Mutable globals first at `data-base`, then
  code immediately after them. Use this for all-RAM images.

The startup file `lib/crt0.s` is `%include`'d into every program by codegen.
It uses three `%define`d names — `RCC_CODE_BASE`,
`RCC_DATA_BASE`, `RCC_STACK_TOP` — which `rcc` emits ahead of the include based
on your flags. `crt0.s` itself is short:

```asm
    .org RCC_CODE_BASE
_start:
    li   r6, RCC_STACK_TOP
    li   r1, main
    jalr r5, r1
    halt
```

The stack grows downward from `--stack-top`. The default of `0o7770` keeps the
stack out of the UART region; if you push it lower you must reserve enough RAM
above the data segment.

### 22. Inline asm

`asm("…")` is the language's escape hatch. Read this section before using it.

**What the compiler does.** It emits the string literally into the output `.s`
file (`Codegen.hs:344`, `IAsmInline`). It does not parse, validate, or analyse
the body in any way. It does not save or restore any registers around the
block. It does not invalidate any spilled values.

**Why this is usually safe.** `rcc` uses naive spill-everything register
allocation. Between TAC instructions, every live C variable is in a stack slot;
registers `r1`–`r4` are scratch and hold no values that need to survive into
the next statement. So an `asm()` block can clobber `r1`–`r4` freely, and the
next C statement will reload from the stack what it needs.

**The actual hazards.**

1. **Do not write `r5`** — it is the link register, saved on entry.
2. **Do not modify `r6` without restoring it** before the next C statement, or
   you will corrupt the stack frame and break every subsequent local-variable
   access.
3. **Do not branch out of the `asm()` block** in a way that bypasses the
   function's epilogue. There is no way for the compiler to clean up after
   you.
4. **Do not store into the function's stack frame** at offsets the compiler
   chose for itself. If you need to write a C variable from asm, take its
   address with `&`, pass it in, and store through that pointer.
5. **String escapes are not processed** inside `asm("…")` (`Parser.hs:346`).
   `\n` in your source is two characters, not a newline. To put two
   instructions on separate lines either use two `asm()` calls or break the
   string with a real newline:
   ```c
   asm("addi r2, 1
   addi r2, 1");
   ```

There is **no GCC-extended-asm syntax** (no input/output operands, no
clobber list). To pass a value in or out, take its address with `&` and use
`lwr`/`swr` explicitly.

### 23. Runtime library and headers

Most of `lib/` is pulled in by hand-written asm or by listing sources on the
assembler / linker command line. Float helpers are **not** `%include`d by `rcc`;
link `lib/float/*.s` (flat assembly) or the matching `.o` files (`rras -o …`,
then `rrld`). The Haskell package **`rrisc-tools`** under [`tools/`](../tools/) provides `rrld` for relocatable
objects.

| File | Purpose |
|------|---------|
| `lib/crt0.s`        | Auto-included by `rcc`. Provides `_start`, sets `r6`, calls `main`, halts |
| `lib/rlibc.h`       | I/O (`putchar`, `getchar`, `puts`, `gets`), memory ops (`memcpy`, `memset`, `memcmp`), strings (`strlen`, `strcpy`, `strcat`, `strcmp`, `strchr`), conversion (`abs`, `atoi`, `itoa`), and float helpers (`ftoa`, `atof`). Use this for general programs |
| `lib/rlibc_io.h`    | Just I/O + `itoa` + `exit`. Use this when you do not need the float helpers and want a smaller binary |
| `lib/rlmath.h`      | Float math: `float_sqrt`, `float_abs`, `float_pow`. Requires `rlibc.h` first |
| `lib/rlibc_host.h`  | POSIX shim used **only** for host-side test builds. Not for RRISC programs |
| `lib/itoa.s`        | Asm-callable signed 12-bit `itoa`; used by `rcc` (via `rlibc.h`) and by `lib/float/__ftoa.s` |
| `lib/io/*.s`        | Asm-callable UART helpers: `putchar`, `putstr`, `getchar`, `print_oct` |
| `lib/macros/*.inc`  | Shared macros and `%define`s: `uart_tx.inc`, `uart_rx.inc`, `subr.inc`, `ror3.inc` |
| `lib/float/__*.s`   | Float helpers (`__fadd`, …, `__fneg`) plus string float I/O (`__ftoi`, `__itof`, `__atof`, `__ftoa`). Linked or assembled alongside `rcc` output — not auto-included in the generated `.s` |
| `lib/float/put_hex12.s` | Asm-callable hex-cell debug print (handy when poking float48 cells from a flat-asm program) |

Hand-written asm demos live under `examples/` (top level) and `examples/float/`
for the soft-float walk-throughs (`demo-add`, `demo-mul`, `demo-div`, `demo-parse`).
Assemble any of them with `cabal run rras -- --format bin -I lib examples/float/demo-add.s` (from the repo root, using [`cabal.project`](../cabal.project)) or a `rras` binary on your `PATH`.

**Float / runtime symbol names.** Globals that the compiler or headers rely on use a `__` prefix (`__fadd`, `__atof`, …). That keeps a single reserved namespace for the flat-assembler world: your C code and prototypes stay conventional (`atof`, `ftoa`, `+` on floats), while emitted `jalr` targets and `%include` bodies cannot collide with a user-defined asm label `fadd` or `atof`. Labels *inside* each `lib/float/*.s` file also use that prefix (or a file-unique prefix) so local branches do not pick up the user’s `skip:` by accident. An alternative would be unprefixed public globals (`atof`, `fadd`) with only locals underscored; that reads nicely in isolation but makes duplicate-symbol mistakes much easier whenever user asm or a second `%include` reuses a libc name.

The headers compile with both `rcc` and host `gcc` (the latter via
`rlibc_host.h`'s POSIX shim) which is how the test suite cross-checks behaviour.

### 24. What is not implemented

A non-exhaustive list of things a C programmer might reach for and not find:

- **No function pointers.** Calls go through compile-time labels. Dispatch
  tables must be done in asm.
- **No variadics.** No `…` in parameter lists; no `va_list`.
- **No `goto`.**
- **No `switch`/`case`.** Use `if`/`else` chains.
- **No `do…while`.**
- **No C-level multi-file linking or `extern`/`static`.** One `.c` file per `rcc`
  invocation → one `.s`. Combine C with `#include`. **Assembly-level** linking is
  supported: **`rras`** (`.o`) → **`rrld`**. See [`docs/toolchain.md`](../docs/toolchain.md)
  and [spec §11b](spec.md#11b-rrisc-toolchain-rcc-and-rrisc-tools).
- **No `extern` / `static` visibility modifiers.** Every top-level name is
  global to the translation unit.
- **No `char`, `short`, `long`, `double`.** Use `int` for character codes;
  no integer wider than 12 bits.
- **No dynamic allocation.** No `malloc`/`free`.
- **No struct passed or returned by value from functions.** Use `struct S *`.
  Local struct variables and compound literals are supported; whole-struct
  assignment between variables is not in the supported subset.
- **No GCC extended `asm`** — see [§22](#22-inline-asm).
- **No `volatile`, no atomics, no memory barriers.** The machine is uniprocessor
  and the simulators are sequential, so most uses of `volatile` are unnecessary;
  for true MMIO, the compiler does not aggressively cache loads/stores in
  registers across statements anyway (naive regalloc, every value spills).
- **No floating-point literals in initialiser lists for non-float globals.**
  Float literals only make sense in float context.
