; fib-recursive.s -- Recursive Fibonacci (rcc ABI + subr.inc)
;
; fib(n): argument and return in r2.  SP starts at 0o0100 (RAM 0o00..0o77 in default sim).
;
%include "subr.inc"

        .org 0o1000

start:  li   r6, 0o0100
        li   r2, 16
        call fib
        halt

fib:    push r5
        push r2

        sub  r0, r0, r2
        bf   fib_leaf
        li   r1, 1
        sub  r4, r2, r1
        sub  r0, r0, r4
        bf   fib_leaf

        subi r2, 1
        push r5
        call fib
        pop  r5
        push r2

        and  r4, r6, r7
        addi r4, 1
        lwr  r2, r4
        subi r2, 2

        push r5
        call fib
        pop  r5

        lwr  r4, r6
        add  r2, r2, r4

        addi r6, 1
        addi r6, 1
        pop  r5
        ret

fib_leaf:
        and  r2, r2, r7
        addi r6, 1
        pop  r5
        ret
