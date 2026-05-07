; fib.asm -- Fibonacci sequence for RRISC (12-bit)
;
; Computes Fibonacci numbers using sub borrow: T=1 if ra < rb, T=0 otherwise.
;
; Result at halt: r1 = F(10) = 55, r2 = F(11) = 89
;
; Register allocation:
;   r0 = 0   (hardwired)
;   r1 = previous Fibonacci value  (F(n-1))
;   r2 = current  Fibonacci value  (F(n))
;   r3 = iteration counter
;   r4 = scratch
;   r5 = 1   (constant; borrow fires when r3 - r5 underflows, i.e. r3 == 0)
;   r7 = -1  (hardwired; used to decrement r3)

%define COUNT 10        ; number of Fibonacci steps to compute

        .org 0o1000

        and  r1, r0, r0 ; r1 = 0 = F(0)
        and  r2, r0, r0
        addi r2, 1      ; r2 = 1 = F(1)
        and  r3, r0, r0
        addi r3, COUNT  ; r3 = loop counter
        and  r5, r0, r0
        addi r5, 1      ; r5 = 1

loop:   addc r4, r1, r2 ; r4 = r1 + r2  (next Fibonacci; T=0 from bf)
        and  r1, r2, r7 ; r1 = r2        (slide window)
        and  r2, r4, r7 ; r2 = r4        (slide window)
        subi r3, 1      ; r3 = r3 - 1   (decrement)
        sub  r4, r3, r5 ; T=1 if r3 < r5 (borrow: counter reached zero)
        bt   done       ; T=1 -> counter exhausted, exit
        bf   loop       ; T=0 -> still counting, repeat

done:   halt
