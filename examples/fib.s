; fib.s -- Iterative Fibonacci for RRISC (no subroutines)
;
; Leaves F(n) in r2 and F(n-1) in r1 after the loop (n=10 iterations here).
; For subroutine calls, see fib-recursive.s + subr.inc.
;
        .org 0o1000

        and  r1, r0, r0   ; r1 = 0  = F(0)
        and  r2, r0, r0
        addi r2, 1        ; r2 = 1  = F(1)
        and  r3, r0, r0
        addi r3, 10       ; r3 = loop counter
        and  r4, r0, r0

loop:   addc r4, r1, r2   ; r4 = r1 + r2  (next Fibonacci; T=0 from bt not-taken)
        and  r1, r2, r7   ; r1 = r2        (slide window)
        and  r2, r4, r7   ; r2 = r4        (slide window)
        subi r3, 1        ; r3 = r3 - 1
        sub  r5, r0, r3   ; T=1 if r3 > 0 (borrow: 0 < r3)
        bt   loop         ; loop while counter > 0

done:   halt
