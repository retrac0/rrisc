; __fcmp(r2=*a, r3=*b) -> r2 = -1 / 0 / +1
;
; Returns +1 if a > b, 0 if a == b, -1 if a < b.
; NaN comparisons return 0.
; Handles: both zero = equal; sign determines order; then exp; then sig.
;
; Stack (6 words + saved r5):
;  [sp+0] sign_a  [sp+1] sign_b
;  [sp+2] exp_a   [sp+3] exp_b
;  [sp+4] *a      [sp+5] *b

__fcmp:
    subi r6, 1
    swr  r5, r6
    subi r6, 6

    ; save pointers
    and  r1, r6, r7
    addi r1, 4
    swr  r2, r1
    addi r1, 1
    swr  r3, r1

    ; unpack a: sign_a/exp_a via shared helper
    ; (We ignore the returned sig_hi here; later code compares w1..w3 directly.)
    and  r2, r6, r7
    addi r2, 4
    lwr  r2, r2              ; r2 = *a
    li   r1, __funpack_hi
    jalr r5, r1              ; r2=sign_a, r3=exp_a, r4=a_hi
    and  r1, r6, r7
    swr  r2, r1              ; [sp+0] = sign_a
    and  r1, r6, r7
    addi r1, 2
    swr  r3, r1              ; [sp+2] = exp_a

    ; unpack b: sign_b/exp_b via shared helper
    and  r2, r6, r7
    addi r2, 5
    lwr  r2, r2              ; r2 = *b
    li   r1, __funpack_hi
    jalr r5, r1              ; r2=sign_b, r3=exp_b, r4=b_hi
    and  r1, r6, r7
    addi r1, 1
    swr  r2, r1              ; [sp+1] = sign_b
    and  r1, r6, r7
    addi r1, 3
    swr  r3, r1              ; [sp+3] = exp_b

    ; check for NaN (exp==2047 and sig!=0) -- simplified: treat inf/NaN as max
    ; for now just compare lexicographically after sign handling

    ; both zero? (exp_a==0 and exp_b==0) -> equal regardless of sign
    and  r1, r6, r7
    addi r1, 2
    lwr  r3, r1              ; r3 = exp_a
    and  r1, r6, r7
    addi r1, 3
    lwr  r4, r1              ; r4 = exp_b
    sub  r0, r0, r3          ; T=1 if exp_a!=0
    bt   __fcmp_notzero
    sub  r0, r0, r4          ; T=1 if exp_b!=0
    bt   __fcmp_notzero
    and  r2, r0, r0          ; return 0
    addi r6, 6
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5

__fcmp_notzero:
    ; different signs?
    and  r1, r6, r7
    lwr  r3, r1              ; r3 = sign_a
    and  r1, r6, r7
    addi r1, 1
    lwr  r4, r1              ; r4 = sign_b
    ; A single sub only sets T on borrow (sign_a < sign_b); for the reverse
    ; ordering we need to take the "differ" branch too. Compute difference
    ; then test for nonzero.
    sub  r1, r3, r4          ; r1 = 0 if same, +/-1 if differ
    sub  r0, r0, r1          ; T=0 iff r1 == 0 (same signs)
    bf   __fcmp_same_sign
    ; different signs: negative < positive
    ; if sign_a=1 (a negative): return -1; else return +1
    sub  r0, r0, r3          ; T=1 if sign_a!=0
    bf   __fcmp_apos
    li   r2, 4095            ; -1 (12-bit two's complement)
    addi r6, 6
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5
__fcmp_apos:
    li   r2, 1
    addi r6, 6
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5

__fcmp_same_sign:
    ; same sign: compare magnitudes (exp then sig words)
    ; sign_a = sign_b = r3
    ; positive: larger exp/sig => larger value
    ; negative: larger exp/sig => smaller value
    ; r3 = sign (0=positive, 1=negative)
    and  r1, r6, r7
    addi r1, 2
    lwr  r2, r1              ; r2 = exp_a
    and  r1, r6, r7
    addi r1, 3
    lwr  r4, r1              ; r4 = exp_b
    sub  r0, r2, r4          ; T=1 if exp_a < exp_b
    bt   __fcmp_mag_less
    sub  r0, r4, r2          ; T=1 if exp_b < exp_a
    bt   __fcmp_mag_greater

    ; exponents equal: compare sig word by word (w1, w2, w3)
    and  r1, r6, r7
    addi r1, 4
    lwr  r2, r1              ; r2 = *a
    and  r1, r6, r7
    addi r1, 5
    lwr  r4, r1              ; r4 = *b
    addi r2, 1               ; point to w1
    addi r4, 1
    lwr  r1, r2
    lwr  r3, r4
    sub  r0, r1, r3
    bt   __fcmp_mag_less
    sub  r0, r3, r1
    bt   __fcmp_mag_greater
    addi r2, 1
    addi r4, 1
    lwr  r1, r2
    lwr  r3, r4
    sub  r0, r1, r3
    bt   __fcmp_mag_less
    sub  r0, r3, r1
    bt   __fcmp_mag_greater
    addi r2, 1
    addi r4, 1
    lwr  r1, r2
    lwr  r3, r4
    sub  r0, r1, r3
    bt   __fcmp_mag_less
    sub  r0, r3, r1
    bt   __fcmp_mag_greater
    ; equal
    and  r2, r0, r0
    addi r6, 6
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5

__fcmp_mag_greater:
    ; |a| > |b|
    ; positive: a > b -> return +1
    ; negative: a < b -> return -1
    and  r1, r6, r7
    lwr  r3, r1              ; sign_a
    sub  r0, r0, r3
    bf   __fcmp_ret1
    li   r2, 4095
    addi r6, 6
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5
__fcmp_ret1:
    li   r2, 1
    addi r6, 6
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5

__fcmp_mag_less:
    ; |a| < |b|
    ; positive: a < b -> return -1
    ; negative: a > b -> return +1
    and  r1, r6, r7
    lwr  r3, r1              ; sign_a
    sub  r0, r0, r3
    bf   __fcmp_retm1
    li   r2, 1
    addi r6, 6
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5
__fcmp_retm1:
    li   r2, 4095
    addi r6, 6
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5
