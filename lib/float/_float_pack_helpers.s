; Common helpers used across multiple float routines.
; Calling convention: r5=link, r6=sp.
; Each helper documents its own clobbers/args/returns.
;
; __funpack_hi(r2=*src) -> r2=sign (0/1), r3=exp_raw (0..2047), r4=sig_hi (w1)
;   Loads src[0] and src[1]. Does NOT advance *src.
;   Clobbers r1.
;
; __fstore_w0_w1_w2_0(r2=*dst, r3=w0, r4=w1, r1=w2) -> writes 4 words with w3=0.
;   Clobbers r1 (writes 0 for w3).
;
; __fmake_w0(r3=exp_raw, r4=sign) -> r2=w0
;   w0 format: bit11=sign, bits10:0=exp_raw.
;   Clobbers r1.

.global __funpack_hi
__funpack_hi:
    ; sign from bit 11 of w0
    lwr  r1, r2
    clrt
    rol  r1, r1              ; T = bit 11
    and  r3, r0, r0
    addc r3, r0, r0          ; r3 = sign (0/1)

    ; exp_raw = w0 & 0o3777
    lwr  r1, r2
    li   r4, 0o3777
    and  r4, r1, r4          ; r4 = exp_raw

    ; sig_hi = w1
    addi r2, 1
    lwr  r1, r2              ; r1 = sig_hi
    subi r2, 1

    ; return values in r2,r3,r4
    and  r2, r3, r7          ; r2 = sign
    and  r3, r4, r7          ; r3 = exp_raw
    and  r4, r1, r7          ; r4 = sig_hi
    jalr r0, r5

.global __fstore_w0_w1_w2_0
__fstore_w0_w1_w2_0:
    swr  r3, r2
    addi r2, 1
    swr  r4, r2
    addi r2, 1
    swr  r1, r2
    addi r2, 1
    and  r1, r0, r0
    swr  r1, r2
    jalr r0, r5

.global __fmake_w0
__fmake_w0:
    li   r1, 0o3777
    and  r2, r3, r1          ; r2 = exp bits 10:0
    sub  r0, r0, r4          ; T=1 if sign != 0
    bf   __fmake_w0_pos
    li   r1, 0o4000
    add  r2, r2, r1
__fmake_w0_pos:
    jalr r0, r5

