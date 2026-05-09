# RRISC C Language Specification

A simplified C-like language targeting the RRISC 12-bit word-addressed machine.

This is the **language reference** (precedence tables, EBNF, ABI table). For a
tutorial, cookbook, and toolchain walkthrough aimed at embedded programmers,
see [`MANUAL.md`](MANUAL.md). The hardware ISA reference is [`Arch.md`](../Arch.md).

---

## 1. Design Goals

- Word-oriented: all values are 12-bit words; no byte addressing
- C-like syntax: familiar control flow, functions, pointers, structs
- Reflects hardware: pointer arithmetic is word-scaled, `sizeof` returns word counts
- ROM compatible: no self-modifying code; read-only data lives in the code section
- Strong typing: implicit numeric conversions limited; pointer/integer conversions require explicit cast

---

## 2. Types

### Primitive

| Type       | Words | Description                                                      |
|------------|-------|------------------------------------------------------------------|
| `int`      | 1     | Signed 12-bit word; range −2048..2047                            |
| `unsigned` | 1     | Same storage as `int`; comparisons use unsigned semantics        |
| `bool`     | 1     | Alias of `int`; `true` and `false` are integer literals 1 and 0  |
| `void`     | —     | No value; used as function return type only                      |
| `float`    | 4     | 48-bit `float48`. **Always passed and returned by pointer.**     |

`unsigned int` is accepted as a synonym for `unsigned`. Float arithmetic compiles to
runtime helper calls (`__fadd`, `__fsub`, `__fmul`, `__fdiv`, `__fcmp`, `__ftoi`,
`__itof`, `__fcopy`, `__fneg`). Implementations live under `lib/float/`. The compiler
does not embed those files; supply them when assembling (for example list the needed
`.s` files or link prebuilt `.o` objects with `hsld`).

### Derived

| Type            | Words          | Description                                  |
|-----------------|----------------|----------------------------------------------|
| `T *`           | 1              | Pointer to T; holds a 12-bit word address    |
| `T [N]`         | N × sizeof(T)  | Array of N elements of type T                |
| `struct S`      | sum of fields  | Aggregate; fields laid out contiguously      |

No `char`, `double`, `long`, or `short` in v1.

### sizeof

`sizeof` returns the size of a type or expression in **words** (not bytes).

```
sizeof(int)          == 1
sizeof(int *)        == 1
sizeof(int [8])      == 8
sizeof(struct {int x; int y;}) == 2
```

`sizeof` is a compile-time constant expression. It may appear anywhere a constant is valid.

### Pointer Arithmetic

Pointer arithmetic is **word-scaled**: `p + n` adds `n` to the address, independent of `sizeof(*p)`.
This matches the hardware directly.

```c
int arr[4];
int *p = arr;
p + 2        // address of arr[2], i.e. &arr + 2
```

Array indexing `a[i]` is defined as `*(a + i)`.
For arrays of structs, element `i` is at `base + i * sizeof(struct S)`. Since there is no
hardware multiply, the compiler emits a left shift when `sizeof(struct S)` is a power of two,
and otherwise either strength-reduces small constant factors or calls the **`__mul`** runtime
in [`lib/__mul.s`](../lib/__mul.s). Prefer power-of-two struct sizes in performance-sensitive code.

---

## 3. Integer Literals

Literals support the same formats as the RRISC assembler:

| Format        | Example     | Notes                     |
|---------------|-------------|---------------------------|
| Decimal       | `42`        |                           |
| Octal         | `0o77`      | Prefix `0o`               |
| Hexadecimal   | `0xFF`      | Prefix `0x`               |
| Binary        | `0b1010`    | Prefix `0b`               |

All integer literals are 12-bit values (0–4095). Out-of-range literals are a compile error.

### Character Literals

```
'A'    'a'    '\n'    '\t'    '\r'    '\0'    '\\'    '\''
```

A character literal is an integer constant equal to the character's Unicode code
point. Supported escapes: `\n \t \r \0 \\ \'`.

### Floating-Point Literals

```
1.5    3.14    1.0e-3    2.5f
```

A float literal has type `float`. The optional `f`/`F`/`l`/`L` suffix is accepted
and ignored. Float literals are emitted as 4-word constant pools in rodata.

### String Literals

```
"hello\n"
```

A string literal has type `int *` and is emitted as a null-terminated array of
words in rodata, one word per character. Supported escapes: `\n \t \r \0 \\ \"`.
String literals inside `asm("…")` are treated as raw text — no escape processing.

---

## 4. Expressions

Operators, in decreasing precedence:

| Precedence | Operators                          | Associativity | Notes                            |
|------------|------------------------------------|---------------|----------------------------------|
| 14         | `(expr)`, `f(args)`, `a[i]`, `.`, `->` | left      | primary / postfix                |
| 13         | `++` `--` (postfix)                | left          |                                  |
| 12         | `++` `--` (prefix), `-`, `!`, `~`, `*`, `&`, `sizeof` | right | unary  |
| 12         | `(type) expr`                      | right         | cast                             |
| 12         | `(type){expr, …}`                  | right         | compound literal                 |
| 11         | `*`  `/`  `%`                      | left          | `int` mul/div/mod expand inline in codegen; `float` uses `__fmul`/`__fdiv` (and related helpers) |
| 10         | `+`  `-`                           | left          |                                  |
| 9          | `<<` `>>`                          | left          |                                  |
| 8          | `<`  `<=` `>` `>=`                 | left          | unsigned for `unsigned`, signed for `int` |
| 7          | `==` `!=`                          | left          |                                  |
| 6          | `&`                                | left          | bitwise AND                      |
| 5          | `^`                                | left          | bitwise XOR                      |
| 4          | `\|`                               | left          | bitwise OR                       |
| 3          | `&&`                               | left          | short-circuit                    |
| 2          | `\|\|`                             | left          | short-circuit                    |
| 1.5        | `cond ? a : b`                     | right         | ternary                          |
| 1          | `=` `+=` `-=` `*=` `/=` `%=` `&=` `\|=` `^=` `<<=` `>>=` | right | assignment |

### Semantics

- All arithmetic wraps at 12 bits.
- Comparison operators yield `int` 1 (true) or 0 (false).
- `&&` and `||` short-circuit; yield 1 or 0.
- `!expr` yields 1 if `expr == 0`, else 0.
- Bitwise operators act on all 12 bits.
- Right shift (`>>`) is arithmetic (sign-extending).
- `*p` dereferences pointer `p`; UB if `p` is invalid.
- `&lvalue` takes the address of an lvalue.
- `a[i]` is `*(a + i)`; word-scaled as noted above.
- `p->f` is `(*p).f`.
- `sizeof(T)` is a compile-time `int` constant returning words.
- `cond ? a : b` evaluates `cond`, then exactly one of the branches.
- `(type){e1, e2, …}` is a compound literal: it allocates a temporary of `type`
  with the given initialiser and yields it as an expression.
- A `"…"` string literal yields type `int *` pointing to a null-terminated word
  array in rodata; see §3.

### Casts

Explicit cast: `(type) expr`. Valid casts:
- `(int)` from any pointer type
- `(T *)` from `int` or any other pointer type

Implicit conversions: integer to pointer and pointer to integer are **not** implicit; a cast
is required. Integer arithmetic does not widen.

---

## 5. Statements

```
block       →  '{' stmt* '}'
stmt        →  block
             | decl_stmt
             | expr ';'
             | 'if' '(' expr ')' stmt ( 'else' stmt )?
             | 'while' '(' expr ')' stmt
             | 'for' '(' for_init expr? ';' expr? ')' stmt
             | 'return' expr? ';'
             | 'break' ';'
             | 'continue' ';'
             | 'asm' '(' string_lit ')' ';'

for_init    →  decl_stmt | expr ';' | ';'
```

- `if`/`while`/`for` conditions are true when non-zero.
- `break` and `continue` apply to the nearest enclosing loop.
- `for` init may declare a variable scoped to the loop.
- Empty `return;` is valid in `void` functions; `return expr;` in typed functions.

### Inline Assembly

```c
asm("addi r2, 1");          // single instruction, verbatim
asm("li r1, 0o7770
lwr r2, r1");               // multiple instructions: embed a real newline
```

The string is emitted **verbatim** into the output `.s` file. **Escape sequences
are not processed** inside `asm("…")`; to put two instructions on separate lines,
either use two `asm()` calls or break the string with a real newline.

The compiler does **not** parse, validate, or analyse the body, **does not save
or restore any registers** around the block, and **does not invalidate** any
spilled values. Because codegen uses naive spill-everything register allocation,
all live C values sit in stack slots between statements; `r1`–`r4` are scratch
across `asm()` blocks and clobbering them is harmless. The actual hazards are:

- Writing `r5` (link register, saved on entry).
- Modifying `r6` (stack pointer) without restoring it.
- Branching out of `asm()` in a way that bypasses the function epilogue.
- Storing into the function's stack frame at unintended offsets.

There is no GCC extended-`asm` syntax (no operand lists, no clobber list). To
move a C value in or out, take its address with `&` and use `lwr`/`swr`.

---

## 6. Declarations

### Variables

```c
int x;                    // zero-initialised global
int x = 42;               // initialised global
int arr[8];               // array of 8 ints
int arr[4] = {1,2,3,4};  // initialised array
const int K = 0o77;       // read-only; placed in rodata alongside code
struct Point p;           // struct variable
```

`const` globals are placed in the code/rodata section (ROM-safe).
Non-`const` globals are placed in the data section (RAM).

Local variable declarations may appear at the start of a block or inline (as in C99).

### Structs

```c
struct Point {
    int x;
    int y;
};

struct Node {
    int val;
    struct Node *next;
};
```

- Fields are laid out in declaration order, one word per field (or `sizeof(field)` words for arrays).
- Anonymous structs and unions are not supported.
- Structs may only be passed or returned by pointer; see §8.

### Typedefs

```c
typedef int Word;
typedef struct Point Point;
typedef int *IntPtr;
```

### Forward Declarations

```c
struct Node;               // forward struct declaration
int foo(int x);            // function prototype
```

---

## 7. Functions

```c
int add(int a, int b) {
    return a + b;
}

void print(int *buf, int len) { ... }
```

- At most 3 register arguments (see §8); additional arguments are pushed right-to-left
  by the **caller** before the call and popped by the **callee** in its epilogue.
- Functions are not variadic.
- Recursion is fully supported.
- Functions may be forward-declared; all definitions must appear in the same translation unit.
- No function pointers.

### Entry Point

The compiler prints `%define` lines for `RCC_CODE_BASE`, `RCC_DATA_BASE`, and `RCC_STACK_TOP`,
then `%include`s [`lib/crt0.s`](../lib/crt0.s), which sets `_start`, initialises **r6** from
`RCC_STACK_TOP`, and calls `main` with `jalr`. The logical effect matches:

```asm
_start:
    li   r6, RCC_STACK_TOP
    li   r1, main
    jalr r5, r1
    halt
```

See [`MANUAL.md`](MANUAL.md) for the exact prelude layout and memory options.

`main` has signature `int main()` or `void main()`.

---

## 8. Calling Convention

Fixed roles (see **Arch.md** for the full ABI):

| Role           | Register | Notes |
|----------------|----------|--------|
| Arg 1          | r2       | |
| Arg 2          | r3       | |
| Arg 3          | r4       | |
| Return value   | r2       | Overlaps arg 1 |
| Scratch        | r1       | **Not** used for arguments. Address/`li` temp, short sequences; **caller-saved** |
| Link register  | r5       | Return address from `jalr r5, …`. **Non-leaf** callees save/restore **r5** on the stack |
| Stack pointer  | r6       | Full descending; points to last pushed word |
| Hardwired zero | r0       | |
| Hardwired −1   | r7       | |

**Caller-saved:** r1, r2, r3, r4 — assume clobbered across a call except the defined return
value in **r2**.

**Callee-saved:** **r5** (when making nested calls) and **r6** (stack must be balanced on
return). There is no separate callee-saved *data* register; long-lived values use stack slots.

**Indirect calls** use **r1** for the target address (`li r1, f; jalr r5, r1`) so **r2–r4**
remain available for the first three arguments.

Args beyond three are pushed **right-to-left** by the caller; the **callee** pops them in its
epilogue.

Only pointers to structs may be passed or returned. Floats are likewise always
passed and returned via a `float *` argument; the compiler-internal helpers
(`__fadd`/`__fsub`/`__fmul`/`__fdiv`/`__fcmp`/`__ftoi`/`__itof`/`__fcopy`/`__fneg`)
take pointers in r2/r3/r4 and write their result through the destination
pointer in r2 (`__fcmp` returns an `int` in r2).

---

## 9. Memory Model

The compiler emits two sections, both configurable via command-line flags:

| Section      | Default address | Contents                              | ROM-safe? |
|--------------|-----------------|---------------------------------------|-----------|
| `.text`      | `0o1000`        | Code + `const` globals (rodata)       | Yes       |
| `.data`      | `0o0000`        | Mutable globals, BSS (zero-init)      | No        |

The stack grows downward from a configurable `STACK_TOP` (default: `0o7770`, just
below the UART region).

Memory access uses `lwr`/`swr` uniformly for both global variables and pointer dereferences:
- Global at compile-time address A: `li r1, A; lwr rN, r1`
- Pointer dereference `*p` (p in register): `lwr rN, rP`

---

## 10. Scope and Lifetime

- **File scope**: declarations outside any function; lifetime = program duration.
- **Block scope**: declarations inside `{}`; lifetime = enclosing block.
- **Function prototype scope**: parameter names in prototypes (not accessible).
- Inner scopes may shadow outer names.
- No dynamic allocation in v1; raw pointer manipulation via `(int *)` casts and `asm` is possible.

---

## 11. Undefined Behaviour

The following are undefined (no diagnostic required):

- Dereferencing a null or invalid pointer
- Out-of-bounds array access
- Signed integer overflow (wraps at 12 bits by convention)
- Using an uninitialised local variable (an implementation may emit an optional warning)
- Calling a function through an incompatible declaration (an implementation may emit an
  optional warning when this can be detected)

---

## 11a. What is not implemented

The following commonly-expected C features are intentionally absent at the **language** level.
See [`MANUAL.md`](MANUAL.md) for discussion and workarounds.

- `goto`, `switch`/`case`, `do…while`
- Function pointers
- Variadic functions (`…`)
- **`extern` / `static`**, and **multiple C translation units** compiled separately by `rcc`
  (one `.c` file in → one `.s` file out). Combine sources with `#include` or split work across
  **assembly** objects (see §11b).
- `char`, `short`, `long`, `double`
- Dynamic allocation (no `malloc`/`free`)
- Structs **passed to or returned from functions by value** (use `struct S *`; local struct
  variables and compound literals are supported)
- GCC extended `asm` (operand/clobber lists)

---

## 11b. RRISC toolchain (`rcc` and hstools)

The **language** is implemented by **`rcc`** ([`compiler/`](../compiler)), which emits RRISC
assembly (`.s`) including the crt0 prelude above.

The **hstools** package ([`hstools/`](../hstools)) provides the supported assembler and linker:
**`hsasm`** (also installed as **`ras`**) turns `.s` into a flat `.bin`/`.mem` image or, with
**`--emit-obj`**, into relocatable **`.o`** files; **`hsld`** links one or more `.o` files into a
final image. **`rsim`** is the Haskell simulator (alternatives: `sim.py`, `sim2`). Bases and
defines must stay consistent with the `%define` lines `rcc` emits — see
[`docs/toolchain.md`](../docs/toolchain.md) for the contract, build commands, and object-format
versioning.

**`rcc` driver (summary).** Typical flags: `-o`, `--code-base`, `--data-base`, `--stack-top`,
`--preprocessor`, **`-O0`** (no optimizations), **`-Os`** (default, optimize for size),
**`-O2`**, **`--pass +name,-name`** (per-pass overrides), **`--dump-ast`**, **`--dump-tac`**,
**`--dump-ssa`**, **`--optimize` / `--no-optimize`** (compat aliases for `-Os` / `-O0`). Full CLI
and workflow examples are in [`MANUAL.md`](MANUAL.md).

---

## 12. Grammar (EBNF)

```ebnf
program      = top_decl* EOF

top_decl     = struct_decl
             | typedef_decl
             | func_decl
             | var_decl

struct_decl  = 'struct' IDENT '{' field+ '}' ';'
field        = type IDENT ( '[' const_expr ']' )? ';'

typedef_decl = 'typedef' type IDENT ';'

func_decl    = type IDENT '(' params ')' ( block | ';' )
params       = ( param ( ',' param )* )?
param        = type IDENT

var_decl     = ( 'const' )? type IDENT ( '[' const_expr ']' )? ( '=' initialiser )? ';'
initialiser  = expr | '{' expr ( ',' expr )* '}'

type         = base_type star*
             | 'struct' IDENT star*
base_type    = 'int' | 'void' | 'float' | 'bool' | 'unsigned' ( 'int' )?
star         = '*'

block        = '{' stmt* '}'
stmt         = block
             | var_decl
             | expr ';'
             | 'if' '(' expr ')' stmt ( 'else' stmt )?
             | 'while' '(' expr ')' stmt
             | 'for' '(' for_init expr? ';' expr? ')' stmt
             | 'return' expr? ';'
             | 'break' ';'
             | 'continue' ';'
             | 'asm' '(' STRING ')' ';'
for_init     = var_decl | expr ';' | ';'

(* Expressions — precedence encoded in grammar levels *)
expr         = assign
assign       = ternary ( assign_op assign )?
assign_op    = '=' | '+=' | '-=' | '*=' | '/=' | '%='
             | '&=' | '|=' | '^=' | '<<=' | '>>='
ternary      = logor ( '?' expr ':' assign )?
logor        = logand ( '||' logand )*
logand       = bitor  ( '&&' bitor  )*
bitor        = bitxor ( '|'  bitxor )*
bitxor       = bitand ( '^'  bitand )*
bitand       = equal  ( '&'  equal  )*
equal        = relat  ( ( '==' | '!=' ) relat )*
relat        = shift  ( ( '<' | '<=' | '>' | '>=' ) shift )*
shift        = addit  ( ( '<<' | '>>' ) addit )*
addit        = mult   ( ( '+' | '-' ) mult )*
mult         = unary  ( ( '*' | '/' | '%' ) unary )*
unary        = ( '-' | '!' | '~' | '*' | '&' | '++' | '--' ) unary
             | 'sizeof' '(' ( type | expr ) ')'
             | '(' type ')' unary                          (* cast *)
             | '(' type ')' '{' expr (',' expr)* '}'       (* compound literal *)
             | postfix
postfix      = primary ( postfix_op )*
postfix_op   = '[' expr ']'
             | '.' IDENT
             | '->' IDENT
             | '(' args ')'
             | '++'
             | '--'
args         = ( expr ( ',' expr )* )?
primary      = IDENT
             | INT_LIT | FLOAT_LIT | CHAR_LIT | STR_LIT
             | 'true' | 'false'
             | '(' expr ')'

(* Lexical *)
IDENT        = [a-zA-Z_][a-zA-Z0-9_]*
INT_LIT      = [0-9]+
             | '0' [0-7]+
             | '0o' [0-7]+
             | '0x' [0-9a-fA-F]+
             | '0b' [01]+
FLOAT_LIT    = [0-9]+ '.' [0-9]* ( [eE] [+-]? [0-9]+ )? [fFlL]?
CHAR_LIT     = "'" ( char | '\\' esc ) "'"
STR_LIT      = '"' ( char | '\\' esc )* '"'         (* expression context *)
STRING       = '"' [^"]* '"'                          (* asm("…") body — raw text, no escapes *)
esc          = 'n' | 't' | 'r' | '0' | '\\' | "'" | '"'
```

Comments: `//` to end of line; `/* ... */` block (non-nesting).

---

## 13. Runtime

**Integer `*`, `/`, and `%`.** Division and modulo expand inline in the code generator.
Multiplication uses **`lib/__mul.s`** (`__mul`) when neither operand is amenable to cheap
strength reduction (e.g. multiply by 0/1, by a power of two via shift, or by 3/5/6 via
shift-and-add); otherwise the product is emitted without a library call.

The compiler emits calls to the symbols below when needed; assembly sources live in `lib/`.
The compiler output `%include`s `lib/crt0.s` for `_start`. Soft-float and string helpers are
**not** inlined into the generated `.s`; link `lib/float/*.s` (or prebuilt `.o` objects from
`lib/float/`) so **`hsld`** or flat **`hsasm`** resolves `__f*` symbols as documented in
[`docs/toolchain.md`](../docs/toolchain.md).

| Symbol     | Signature                                        | Description                              | Source                |
|------------|--------------------------------------------------|------------------------------------------|-----------------------|
| `_start`   | —                                                | Entry point; inits stack, calls `main`   | `lib/crt0.s` (auto-included) |
| `__mul`    | `(int a, int b) int` (args **r3**, **r2**; product **r2**) | 12-bit multiply (wraps like repeated `add`) | [`lib/__mul.s`](../lib/__mul.s) (link with `hsld`; see `run_tests.py`) |
| `__fadd`   | `(float *dst, float *a, float *b)`               | `*dst = *a + *b`                         | `lib/float/__fadd.s`  |
| `__fsub`   | `(float *dst, float *a, float *b)`               | `*dst = *a − *b`                         | `lib/float/__fsub.s`  |
| `__fmul`   | `(float *dst, float *a, float *b)`               | `*dst = *a × *b`                         | `lib/float/__fmul.s`  |
| `__fdiv`   | `(float *dst, float *a, float *b)`               | `*dst = *a ÷ *b`                         | `lib/float/__fdiv.s`  |
| `__fcmp`   | `(float *a, float *b) int`                       | -1 / 0 / +1 in r2                        | `lib/float/__fcmp.s`  |
| `__ftoi`   | `(float *src) int`                               | Truncate to int                          | `lib/float/__ftoi.s`  |
| `__itof`   | `(float *dst, int n)`                            | Promote int to float                     | `lib/float/__itof.s`  |
| `__fcopy`  | `(float *dst, float *src)`                       | Copy 4 words                             | `lib/float/__fcopy.s` |
| `__fneg`   | `(float *dst, float *src)`                       | Negate                                   | `lib/float/__fneg.s`  |
| `__atof`   | `(int *s, float *dst)`                           | Parse decimal ASCII into float48         | `lib/float/__atof.s`  |
| `__ftoa`   | `(float *src, int *buf) int *`                   | 4-decimal-digit string render            | `lib/float/__ftoa.s`  |
| `itoa`     | `(int n, int *buf) int *`                        | Signed 12-bit decimal string             | `lib/itoa.s`          |

---

## 14. Example

```c
struct Point {
    int x;
    int y;
};

int dot(struct Point *a, struct Point *b) {
    return a->x * b->x + a->y * b->y;
}

int arr[4] = {1, 2, 3, 4};

int main() {
    struct Point p = {3, 4};
    struct Point q = {1, 2};
    int d = dot(&p, &q);
    /* Write `d` to the UART by going through a real pointer; do NOT rely on
       r1 holding a particular value across a C statement boundary. */
    int *txbuf = (int *)0o7772;
    *txbuf = d;
    return 0;
}
```
