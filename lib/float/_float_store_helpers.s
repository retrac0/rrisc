; Shared helpers to write common float48 results (4 words).
; Calling convention: r5=link, r6=sp. Clobbers r1,r4.

; __fstore_zero(r2=*dst) -- write +0.0f
.global __fstore_zero
__fstore_zero:
    and  r1, r0, r0
    swr  r1, r2
    addi r2, 1
    swr  r1, r2
    addi r2, 1
    swr  r1, r2
    addi r2, 1
    swr  r1, r2
    jalr r0, r5

; __fstore_inf(r2=*dst, r3=sign) -- write +/-inf (no NaN payload)
.global __fstore_inf
__fstore_inf:
    li   r4, 2047
    sub  r0, r0, r3
    bf   __fstore_inf_pos
    li   r1, 0o4000
    add  r4, r4, r1
__fstore_inf_pos:
    swr  r4, r2
    addi r2, 1
    and  r1, r0, r0
    swr  r1, r2
    addi r2, 1
    swr  r1, r2
    addi r2, 1
    swr  r1, r2
    jalr r0, r5

