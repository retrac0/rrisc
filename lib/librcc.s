; =============================================================================
; librcc.s — rcc compiler runtime (integer helpers only)
;
; Role
;   This file is the **compiler support** library for RRISC code produced by rcc
;   (analogous to libgcc / compiler-rt). It is **not** the C runtime startup:
;   that lives in **crt0.s** (`_start`, stack, call `main`, halt).
;
;   **Soft-float** and string helpers live under **lib/float/** and **lib/itoa.s**
;   etc.; link those separately when the program uses those features.
;
; Linking (relocatable objects with hsasm --emit-obj + hsld)
;   Recommended order:  crt0.o  →  librcc.o  →  user.o
;   so `_start` and integer helpers resolve before your rcc-generated `.o`.
;   The Python test harness uses this order (see run_tests.py).
;
; Calling convention (all exported routines below)
;   Factors / dividend in **r3**, divisor / second factor in **r2**.
;   Result in **r2** (12-bit, `and` with **r7** where noted). **r7** is fixed `0xFFF`.
;   **r5** is the return address (`jalr` target uses **r1**, then `jalr r5, r1`).
;   Leaf helpers end with `jalr r0, r5`. **__div** / **__mod** use **r6** briefly
;   to save **r5** and restore it before return (they are not leaf-same-as-caller
;   if you rely on **r6** being unchanged across a symbol name — but callees may
;   use the stack per ABI).
;
; Multiply
;   **__mul** — 12-bit product (wraps like repeated `add` in 12 bits).
;
; Unsigned divide group
;   **__udiv**, **__umod** — operands treated as unsigned 12-bit; divide by zero
;   yields 0 in **r2**.
;
; Signed divide group
;   **__div**, **__mod** — truncating division toward zero; remainder follows C
;   rules with `%`; divide by zero yields 0.
; =============================================================================

    .global __mul
    .global __udiv
    .global __umod
    .global __div
    .global __mod

    .section text

; --- multiply -----------------------------------------------------------------

__mul:
    and r1, r0, r0
_L_mul_loop:
    sub r0, r0, r2
    bf _L_mul_end
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_mul_loop
_L_mul_end:
    and r2, r1, r7
    jalr r0, r5

; --- unsigned divide / remainder ----------------------------------------------

__udiv:
    sub r0, r0, r2
    bf _L_udiv_z
    and r4, r3, r7
    and r2, r2, r7
    and r1, r0, r0
_L_udiv_loop:
    sub r0, r4, r2
    bt _L_udiv_done
    sub r4, r4, r2
    addi r1, 1
    sub r0, r0, r7
    bt _L_udiv_loop
_L_udiv_done:
    and r2, r1, r7
    jalr r0, r5
_L_udiv_z:
    and r2, r0, r0
    jalr r0, r5

__umod:
    sub r0, r0, r2
    bf _L_umod_z
    and r4, r3, r7
    and r2, r2, r7
    and r1, r0, r0
_L_umod_loop:
    sub r0, r4, r2
    bt _L_umod_done
    sub r4, r4, r2
    addi r1, 1
    sub r0, r0, r7
    bt _L_umod_loop
_L_umod_done:
    and r2, r4, r7
    jalr r0, r5
_L_umod_z:
    and r2, r0, r0
    jalr r0, r5

; --- signed divide / remainder (save lr on stack) -----------------------------

__div:
    sub r0, r0, r2
    bf _L_div_z
    subi r6, 1
    swr r5, r6
    and r1, r3, r7
    rol r1, r1
    rol r4, r0
    subi r6, 1
    swr r4, r6
    and r1, r2, r7
    rol r1, r1
    rol r4, r0
    subi r6, 1
    swr r4, r6
    and r1, r6, r7
    addi r1, 1
    lwr r4, r1
    sub r0, r0, r4
    bf _L_div_npos
    sub r3, r0, r3
_L_div_npos:
    and r1, r6, r7
    lwr r4, r1
    sub r0, r0, r4
    bf _L_div_dpos
    sub r2, r0, r2
_L_div_dpos:
    and r4, r3, r7
    and r1, r0, r0
_L_div_qloop:
    sub r0, r4, r2
    bt _L_div_qend
    sub r4, r4, r2
    addi r1, 1
    sub r0, r0, r7
    bt _L_div_qloop
_L_div_qend:
    and r2, r1, r7
    and r1, r6, r7
    lwr r1, r1
    addi r6, 1
    and r4, r6, r7
    lwr r4, r4
    addi r6, 1
    add r1, r1, r4
    subi r1, 1
    sub r0, r0, r1
    bt _L_div_done
    sub r2, r0, r2
_L_div_done:
    and r1, r6, r7
    lwr r5, r1
    addi r6, 1
    jalr r0, r5
_L_div_z:
    and r2, r0, r0
    jalr r0, r5

__mod:
    sub r0, r0, r2
    bf _L_mod_z
    subi r6, 1
    swr r5, r6
    and r1, r3, r7
    rol r1, r1
    rol r4, r0
    subi r6, 1
    swr r4, r6
    sub r0, r0, r4
    bf _L_mod_npos
    sub r3, r0, r3
_L_mod_npos:
    and r1, r2, r7
    rol r1, r1
    bf _L_mod_dpos
    sub r2, r0, r2
_L_mod_dpos:
    and r4, r3, r7
    and r1, r0, r0
_L_mod_qloop:
    sub r0, r4, r2
    bt _L_mod_qend
    sub r4, r4, r2
    addi r1, 1
    sub r0, r0, r7
    bt _L_mod_qloop
_L_mod_qend:
    and r1, r6, r7
    lwr r1, r1
    addi r6, 1
    sub r0, r0, r1
    bf _L_mod_rempos
    sub r4, r0, r4
_L_mod_rempos:
    and r2, r4, r7
    and r1, r6, r7
    lwr r5, r1
    addi r6, 1
    jalr r0, r5
_L_mod_z:
    and r2, r0, r0
    jalr r0, r5
