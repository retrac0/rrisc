; __fsub(r2=*dst, r3=*a, r4=*b) -- dst = a - b
; Negate b's sign bit into a stack copy, then tail-call __fadd.
;
; Stack (6 words + saved r5):
;   sp+0 = saved *a   sp+1..4 = tmp_b (negated copy of *b)

__fsub:
    subi r6, 1
    swr  r5, r6
    subi r6, 5

    ; save *a (r3) before we clobber r3
    and  r1, r6, r7
    swr  r3, r1              ; [sp+0] = *a

    ; build tmp_b at sp+1: w0 with sign flipped, then w1-w3 verbatim
    lwr  r1, r4              ; r1 = b.w0
    li   r3, 0o4000
    add  r1, r1, r3          ; toggle bit 11
    and  r3, r6, r7
    addi r3, 1
    swr  r1, r3              ; [sp+1] = tmp_b.w0
    addi r4, 1
    addi r3, 1
    lwr  r1, r4
    swr  r1, r3              ; [sp+2] = tmp_b.w1
    addi r4, 1
    addi r3, 1
    lwr  r1, r4
    swr  r1, r3              ; [sp+3] = tmp_b.w2
    addi r4, 1
    addi r3, 1
    lwr  r1, r4
    swr  r1, r3              ; [sp+4] = tmp_b.w3

    ; restore r3 = *a, set r4 = &tmp_b
    and  r1, r6, r7
    lwr  r3, r1
    and  r4, r6, r7
    addi r4, 1

    ; tail-call __fadd (r2=dst unchanged)
    addi r6, 5
    lwr  r5, r6
    addi r6, 1
    li   r1, __fadd
    jalr r0, r1
