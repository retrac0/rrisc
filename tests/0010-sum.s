; sum.asm -- sum of integers 1..N using a countdown loop
;
; r1 = accumulator (result: 1+2+...+N)
; r2 = counter (N down to 1)
; r3 = scratch for termination test
; r5 = 1 (constant)
; r7 = -1 (hardwired)
;
; Expected result: r1 = 210 (= 0o322) for N=20

%define N 20

        .org 0o1000

        and  r1, r0, r0 ; r1 = 0 (accumulator)
        and  r2, r0, r0
        addi r2, N      ; r2 = N (loop counter)
        and  r5, r0, r0
        addi r5, 1      ; r5 = 1

loop:   addc r1, r1, r2 ; sum += counter
        addi r2, -1     ; counter--
        sub  r3, r2, r5 ; T=1 if r2 < 1 (i.e. counter reached 0)
        bt   done       ; T=1 -> done
        bf   loop       ; T=0 -> continue

done:   halt
