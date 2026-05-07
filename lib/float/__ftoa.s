; __ftoa(float *f, int *buf) -- decimal string with 4 fractional digits; returns ptr to NUL.
; C ABI: r2=f, r3=buf. Clobbers r1–r4. Requires label `itoa`. Frame 36 words.
;
;   0..3   x        4..7   frac      8..11  ipfloat   12..15 dfloat
;   16..19 ten      20     sv_f      21     sv_buf    22     p
;   23     ipart    24     frac_iter (counts down from 4)

%define FT_X       0
%define FT_FRAC    4
%define FT_IPFLT   8
%define FT_DFLT    12
%define FT_TEN     16
%define FT_SV_F    20
%define FT_SV_BUF  21
%define FT_P       22
%define FT_IPART   23
%define FT_ITER    24

__ftoa:
    subi r6, 1
    swr  r5, r6
    subi r6, 36

    and  r1, r6, r7
    addi r1, FT_SV_F
    swr  r2, r1
    and  r1, r6, r7
    addi r1, FT_SV_BUF
    swr  r3, r1
    and  r1, r6, r7
    addi r1, FT_P
    swr  r3, r1

    and  r1, r6, r7
    addi r1, FT_SV_F
    lwr  r4, r1
    lwr  r1, r4
    sub  r0, r0, r1
    bf   __ftoa_not_all_zero
    addi r4, 1
    lwr  r1, r4
    sub  r0, r0, r1
    bf   __ftoa_not_all_zero
    addi r4, 1
    lwr  r1, r4
    sub  r0, r0, r1
    bf   __ftoa_not_all_zero
    addi r4, 1
    lwr  r1, r4
    sub  r0, r0, r1
    bf   __ftoa_not_all_zero
    and  r1, r6, r7
    addi r1, FT_SV_BUF
    lwr  r4, r1
    li   r1, 48
    swr  r1, r4
    addi r4, 1
    li   r1, 46
    swr  r1, r4
    addi r4, 1
    li   r1, 48
    swr  r1, r4
    addi r4, 1
    swr  r1, r4
    addi r4, 1
    swr  r1, r4
    addi r4, 1
    swr  r1, r4
    addi r4, 1
    and  r1, r0, r0
    swr  r1, r4
    and  r2, r4, r7
    addi r6, 36
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5

__ftoa_not_all_zero:
    and  r2, r6, r7
    addi r2, FT_X
    and  r1, r6, r7
    addi r1, FT_SV_F
    lwr  r3, r1
    li   r1, __fcopy
    jalr r5, r1

    and  r2, r6, r7
    addi r2, FT_TEN
    li   r3, 10
    li   r1, __itof
    jalr r5, r1

    clrt
    and  r2, r6, r7
    addi r2, FT_X
    lwr  r1, r2
    and  r3, r1, r7
    rol  r3, r3
    bf   __ftoa_pos
    and  r1, r6, r7
    addi r1, FT_SV_BUF
    lwr  r4, r1
    li   r1, 45
    swr  r1, r4
    addi r4, 1
    and  r1, r6, r7
    addi r1, FT_P
    swr  r4, r1
    and  r2, r6, r7
    addi r2, FT_X
    and  r3, r6, r7
    addi r3, FT_X
    li   r1, __fneg
    jalr r5, r1
__ftoa_pos:
    and  r2, r6, r7
    addi r2, FT_X
    li   r1, __ftoi
    jalr r5, r1
    and  r1, r6, r7
    addi r1, FT_IPART
    swr  r2, r1

    and  r1, r6, r7
    addi r1, FT_IPART
    lwr  r2, r1
    and  r1, r6, r7
    addi r1, FT_P
    lwr  r3, r1
    li   r1, itoa
    jalr r5, r1

__ftoa_scan0:
    and  r1, r6, r7
    addi r1, FT_P
    lwr  r4, r1
    lwr  r1, r4
    sub  r0, r0, r1
    bf   __ftoa_scan_done
    addi r4, 1
    and  r1, r6, r7
    addi r1, FT_P
    swr  r4, r1
    sub  r0, r0, r7
    bt   __ftoa_scan0
__ftoa_scan_done:
    and  r1, r6, r7
    addi r1, FT_P
    lwr  r4, r1
    li   r1, 46
    swr  r1, r4
    addi r4, 1
    and  r1, r6, r7
    addi r1, FT_P
    swr  r4, r1

    li   r3, 4
    and  r1, r6, r7
    addi r1, FT_ITER
    swr  r3, r1

__ftoa_frac_outer:
    and  r1, r6, r7
    addi r1, FT_ITER
    lwr  r3, r1
    sub  r0, r0, r3
    bf   __ftoa_finish
    and  r2, r6, r7
    addi r2, FT_IPFLT
    and  r1, r6, r7
    addi r1, FT_IPART
    lwr  r3, r1
    li   r1, __itof
    jalr r5, r1
    and  r2, r6, r7
    addi r2, FT_FRAC
    and  r3, r6, r7
    addi r3, FT_X
    and  r4, r6, r7
    addi r4, FT_IPFLT
    li   r1, __fsub
    jalr r5, r1
    and  r2, r6, r7
    addi r2, FT_FRAC
    and  r3, r6, r7
    addi r3, FT_FRAC
    and  r4, r6, r7
    addi r4, FT_TEN
    li   r1, __fmul
    jalr r5, r1
    and  r2, r6, r7
    addi r2, FT_FRAC
    li   r1, __ftoi
    jalr r5, r1
    and  r4, r2, r7          ; r4 = digit
    li   r3, 48
    add  r2, r4, r3          ; ascii
    and  r1, r6, r7
    addi r1, FT_P
    lwr  r4, r1
    swr  r2, r4
    addi r4, 1
    swr  r4, r1
    and  r2, r6, r7
    addi r2, FT_DFLT
    and  r3, r4, r7
    li   r1, __itof
    jalr r5, r1
    and  r2, r6, r7
    addi r2, FT_FRAC
    and  r3, r6, r7
    addi r3, FT_FRAC
    and  r4, r6, r7
    addi r4, FT_DFLT
    li   r1, __fsub
    jalr r5, r1
    and  r1, r6, r7
    addi r1, FT_ITER
    lwr  r3, r1
    subi r3, 1
    swr  r3, r1
    sub  r0, r0, r7
    bt   __ftoa_frac_outer

__ftoa_finish:
    and  r1, r6, r7
    addi r1, FT_P
    lwr  r4, r1
    and  r1, r0, r0
    swr  r1, r4
    and  r2, r4, r7
    addi r6, 36
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5
