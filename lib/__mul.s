; __mul.s — signed 12-bit integer multiply for rcc-generated calls.
; ABI: factors in r3 (a) and r2 (b); product in r2 (a * b), masked to 12 bits.
; Scratch: r1 is accumulator; preserves callee ABI — leaf routine (jalr r0, r5).

    .global __mul

    .section text

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
