# RRISC C Language Specification

A simplified C-like language targeting the RRISC 12-bit word-addressed machine.

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

| Type   | Words | Description                          |
|--------|-------|--------------------------------------|
| `int`  | 1     | Signed 12-bit word (range -2048..2047 / 0..4095 unsigned) |
| `void` | —     | No value; used as function return type only |

### Derived

| Type            | Words          | Description                                  |
|-----------------|----------------|----------------------------------------------|
| `T *`           | 1              | Pointer to T; holds a 12-bit word address    |
| `T [N]`         | N              | Array of N elements of type T                |
| `struct S`      | sum of fields  | Aggregate; fields laid out contiguously      |

No `char`, `float`, `double`, `long`, `short`, or `unsigned` in v1.

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
hardware multiply, this compiles to a shift when `sizeof` is a power of two, and to a runtime
library call (`__mul`) otherwise. Prefer power-of-two struct sizes in performance-sensitive code.

---

## 3. Integer Literals

Literals support the same formats as the RRISC assembler:

| Format        | Example     | Notes                     |
|---------------|-------------|---------------------------|
| Decimal       | `42`        |                           |
| Octal         | `0o77`      | Prefix `0o`               |
| Hexadecimal   | `0xFF`      | Prefix `0x`               |
| Binary        | `0b1010`    | Prefix `0b`               |

All literals are 12-bit values (0–4095). Out-of-range literals are a compile error.

Character literals are not supported (no `char` type).

---

## 4. Expressions

Operators, in decreasing precedence:

| Precedence | Operators                          | Associativity | Notes                            |
|------------|------------------------------------|---------------|----------------------------------|
| 14         | `(expr)`, `f(args)`, `a[i]`, `.`, `->` | left      | primary / postfix                |
| 13         | `++` `--` (postfix)                | left          |                                  |
| 12         | `++` `--` (prefix), `-`, `!`, `~`, `*`, `&`, `sizeof` | right | unary  |
| 11         | `*`  `/`  `%`                      | left          | mul/div compile to `__mul`/`__div` |
| 10         | `+`  `-`                           | left          |                                  |
| 9          | `<<` `>>`                          | left          |                                  |
| 8          | `<`  `<=` `>` `>=`                 | left          |                                  |
| 7          | `==` `!=`                          | left          |                                  |
| 6          | `&`                                | left          | bitwise AND                      |
| 5          | `^`                                | left          | bitwise XOR                      |
| 4          | `\|`                               | left          | bitwise OR                       |
| 3          | `&&`                               | left          | short-circuit                    |
| 2          | `\|\|`                             | left          | short-circuit                    |
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
- `sizeof(T)` is a compile-time `int` constant.

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
asm("addi r2, 1");   // single instruction, verbatim
asm("li r1, 0o7770\nlwr r2, r1");  // newline-separated multiple instructions
```

The string is emitted verbatim into the output `.s` file. The compiler makes no assumptions
about register effects; all live values are considered clobbered after `asm`.

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
  before the call and popped by the callee.
- Functions are not variadic in v1.
- Recursion is fully supported.
- Functions may be forward-declared; all definitions must appear in the same translation unit.
- No function pointers in v1.

### Entry Point

The compiler emits a `_start` label that initialises the stack pointer (r6) and calls `main`:

```asm
_start:
    li   r6, STACK_TOP
    call main
    halt
```

`main` has signature `int main()` or `void main()`.

---

## 8. Calling Convention

| Role           | Register | Notes                                         |
|----------------|----------|-----------------------------------------------|
| Arg 1          | r2       |                                               |
| Arg 2          | r3       |                                               |
| Arg 3          | r4       |                                               |
| Return value   | r2       | Overlaps arg 1                                |
| Link register  | r5       | Holds return address; callee must save/restore in non-leaf functions |
| Stack pointer  | r6       | Full descending; points to last pushed word   |
| Scratch        | r1       | Implicit target of `lwr`-via-`li`; caller-saved |
| Hardwired zero | r0       | Read-only constant 0                          |
| Hardwired −1   | r7       | Read-only constant −1 (0o7777)                |

**Caller-saved:** r1, r2, r3 (may be clobbered by a call)  
**Callee-saved:** r4, r5 (non-leaf callees must preserve these)

Args beyond r4 are pushed right-to-left by the caller; the callee pops them in its epilogue.

Only pointers to structs may be passed or returned.

---

## 9. Memory Model

The compiler emits two sections, both configurable via command-line flags:

| Section      | Default address | Contents                              | ROM-safe? |
|--------------|-----------------|---------------------------------------|-----------|
| `.text`      | `0o1000`        | Code + `const` globals (rodata)       | Yes       |
| `.data`      | `0o0000`        | Mutable globals, BSS (zero-init)      | No        |

The stack grows downward from a configurable `STACK_TOP` (default: `.data` base).

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
- Using an uninitialised local variable but compiler should emit optional warning)
- Calling a function through an incompatible declaration but compiler should emit 
  optional warning when this can be detected

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
base_type    = 'int' | 'void'
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
             | 'asm' '(' STRING ';'
for_init     = var_decl | expr ';' | ';'

(* Expressions — precedence encoded in grammar levels *)
expr         = assign
assign       = cond ( assign_op assign )?
assign_op    = '=' | '+=' | '-=' | '*=' | '/=' | '%='
             | '&=' | '|=' | '^=' | '<<=' | '>>='
cond         = logor
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
             | '(' type ')' unary           (* cast *)
             | postfix
postfix      = primary ( postfix_op )*
postfix_op   = '[' expr ']'
             | '.' IDENT
             | '->' IDENT
             | '(' args ')'
             | '++'
             | '--'
args         = ( expr ( ',' expr )* )?
primary      = IDENT | INT_LIT | '(' expr ')'

(* Lexical *)
IDENT        = [a-zA-Z_][a-zA-Z0-9_]*
INT_LIT      = [0-9]+
             | '0o' [0-7]+
             | '0x' [0-9a-fA-F]+
             | '0b' [01]+
STRING       = '"' [^"]* '"'       (* no escape sequences in asm strings *)
```

Comments: `//` to end of line; `/* ... */` block (non-nesting).

---

## 13. Runtime Library (v1 Sketch)

The compiler emits calls to these symbols when needed; a hand-written `runtime.s` provides them:

| Symbol   | Signature         | Description                      |
|----------|-------------------|----------------------------------|
| `__mul`  | `(int, int) int`  | Software multiply                |
| `__div`  | `(int, int) int`  | Software divide                  |
| `__mod`  | `(int, int) int`  | Software modulo                  |
| `_start` | —                 | Entry point; inits stack, calls main |

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
    asm("swr r2, r1");   // write result to I/O — r1 holds output address
    return 0;
}
```
