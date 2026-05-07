; __atof(int *s, float *result) -- parse decimal ASCII into float48 *result
; C ABI: r2=s, r3=result. Clobbers r1–r4. Frame 35 words (offsets 0..34).
;
;   0..3   zero   4..7   ten     8..11  fval    12..15 frac
;   16..19 scale  20..23 digit   24..27 fdiv_tmp
;   28     neg    29     ipart   30     p (string cursor)
;   31     pad    32     saved_s      33     saved_result

%define AT_ZERO   0
%define AT_TEN    4
%define AT_FVAL   8
%define AT_FRAC   12
%define AT_SCALE  16
%define AT_DIGIT  20
%define AT_TMP    24
%define AT_NEG    28
%define AT_IPART  29
%define AT_P      30
%define AT_PAD    31
%define AT_SV_S   32
%define AT_SV_RES 33

__atof:
    subi r6, 1
    swr  r5, r6
    subi r6, 35

    and  r1, r6, r7
    addi r1, AT_SV_S
    swr  r2, r1
    and  r1, r6, r7
    addi r1, AT_SV_RES
    swr  r3, r1

    and  r2, r6, r7
    addi r2, AT_ZERO
    and  r3, r0, r0
    li   r1, __itof
    jalr r5, r1
    and  r2, r6, r7
    addi r2, AT_TEN
    li   r3, 10
    li   r1, __itof
    jalr r5, r1

    and  r1, r6, r7
    addi r1, AT_NEG
    swr  r0, r1
    and  r1, r6, r7
    addi r1, AT_IPART
    swr  r0, r1

    and  r1, r6, r7
    addi r1, AT_SV_S
    lwr  r2, r1
    and  r1, r6, r7
    addi r1, AT_P
    swr  r2, r1

__atof_skip_ws:
    and  r1, r6, r7
    addi r1, AT_P
    lwr  r4, r1
    lwr  r1, r4
    sub  r0, r0, r1
    bf   __atof_ws_done
    li   r2, 32
    sub  r0, r1, r2
    bf   __atof_ws_done
    li   r2, 9
    sub  r0, r1, r2
    bf   __atof_ws_done
    addi r4, 1
    and  r1, r6, r7
    addi r1, AT_P
    swr  r4, r1
    sub  r0, r0, r7
    bt   __atof_skip_ws
__atof_ws_done:
    and  r1, r6, r7
    addi r1, AT_P
    lwr  r4, r1
    lwr  r1, r4
    li   r2, 45
    sub  r0, r1, r2
    bf   __atof_no_minus
    and  r1, r6, r7
    addi r1, AT_NEG
    li   r2, 1
    swr  r2, r1
    addi r4, 1
    and  r1, r6, r7
    addi r1, AT_P
    swr  r4, r1
    sub  r0, r0, r7
    bt   __atof_after_sign
__atof_no_minus:
    and  r1, r6, r7
    addi r1, AT_P
    lwr  r4, r1
    lwr  r1, r4
    li   r2, 43
    sub  r0, r1, r2
    bf   __atof_after_sign
    addi r4, 1
    and  r1, r6, r7
    addi r1, AT_P
    swr  r4, r1
__atof_after_sign:
    and  r1, r6, r7
    addi r1, AT_IPART
    swr  r0, r1
__atof_int_loop:
    and  r1, r6, r7
    addi r1, AT_P
    lwr  r4, r1
    lwr  r1, r4
    sub  r0, r0, r1
    bf   __atof_int_done
    and  r2, r1, r7
    li   r3, 48
    li   r1, 0o4000
    add  r2, r2, r1
    add  r3, r3, r1
    sub  r1, r2, r3
    bt   __atof_int_done
    lwr  r2, r4
    and  r3, r2, r7
    li   r2, 57
    li   r1, 0o4000
    add  r3, r3, r1
    add  r2, r2, r1
    sub  r1, r2, r3
    bt   __atof_int_done
    lwr  r1, r4
    li   r3, 48
    sub  r2, r1, r3
    and  r1, r6, r7
    addi r1, AT_IPART
    lwr  r3, r1
    add  r1, r3, r3
    add  r1, r1, r1
    add  r1, r1, r3
    add  r1, r1, r1
    add  r3, r1, r2
    and  r1, r6, r7
    addi r1, AT_IPART
    swr  r3, r1
    addi r4, 1
    and  r1, r6, r7
    addi r1, AT_P
    swr  r4, r1
    sub  r0, r0, r7
    bt   __atof_int_loop
__atof_int_done:
    and  r2, r6, r7
    addi r2, AT_FVAL
    and  r1, r6, r7
    addi r1, AT_IPART
    lwr  r3, r1
    li   r1, __itof
    jalr r5, r1

    and  r2, r6, r7
    addi r2, AT_FRAC
    and  r3, r6, r7
    addi r3, AT_ZERO
    li   r1, __fcopy
    jalr r5, r1
    and  r2, r6, r7
    addi r2, AT_SCALE
    and  r3, r6, r7
    addi r3, AT_TEN
    li   r1, __fcopy
    jalr r5, r1

    and  r1, r6, r7
    addi r1, AT_P
    lwr  r4, r1
    lwr  r1, r4
    li   r2, 46
    sub  r0, r1, r2
    bf   __atof_combine
    addi r4, 1
    and  r1, r6, r7
    addi r1, AT_P
    swr  r4, r1

__atof_frac_loop:
    and  r1, r6, r7
    addi r1, AT_P
    lwr  r4, r1
    lwr  r1, r4
    sub  r0, r0, r1
    bf   __atof_combine
    and  r2, r1, r7
    li   r3, 48
    li   r1, 0o4000
    add  r2, r2, r1
    add  r3, r3, r1
    sub  r1, r2, r3
    bt   __atof_combine
    lwr  r2, r4
    and  r3, r2, r7
    li   r2, 57
    li   r1, 0o4000
    add  r3, r3, r1
    add  r2, r2, r1
    sub  r1, r2, r3
    bt   __atof_combine
    lwr  r1, r4
    li   r3, 48
    sub  r2, r1, r3          ; r2 = digit 0..9
    and  r1, r6, r7
    addi r1, AT_DIGIT
    and  r3, r2, r7          ; r3 = digit for __itof
    and  r2, r1, r7          ; r2 = &digit (float slot)
    li   r1, __itof
    jalr r5, r1
    and  r2, r6, r7
    addi r2, AT_TMP
    and  r3, r6, r7
    addi r3, AT_DIGIT
    and  r4, r6, r7
    addi r4, AT_SCALE
    li   r1, __fdiv
    jalr r5, r1
    and  r2, r6, r7
    addi r2, AT_FRAC
    and  r3, r6, r7
    addi r3, AT_FRAC
    and  r4, r6, r7
    addi r4, AT_TMP
    li   r1, __fadd
    jalr r5, r1
    and  r2, r6, r7
    addi r2, AT_SCALE
    and  r3, r6, r7
    addi r3, AT_SCALE
    and  r4, r6, r7
    addi r4, AT_TEN
    li   r1, __fmul
    jalr r5, r1
    and  r1, r6, r7
    addi r1, AT_P
    lwr  r4, r1
    addi r4, 1
    swr  r4, r1
    sub  r0, r0, r7
    bt   __atof_frac_loop

__atof_combine:
    and  r2, r6, r7
    addi r2, AT_FVAL
    and  r3, r6, r7
    addi r3, AT_FVAL
    and  r4, r6, r7
    addi r4, AT_FRAC
    li   r1, __fadd
    jalr r5, r1

    and  r1, r6, r7
    addi r1, AT_NEG
    lwr  r2, r1
    sub  r0, r0, r2
    bf   __atof_store
    and  r2, r6, r7
    addi r2, AT_FVAL
    and  r3, r6, r7
    addi r3, AT_FVAL
    li   r1, __fneg
    jalr r5, r1
__atof_store:
    and  r1, r6, r7
    addi r1, AT_SV_RES
    lwr  r2, r1
    and  r3, r6, r7
    addi r3, AT_FVAL
    li   r1, __fcopy
    jalr r5, r1

    addi r6, 35
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5
