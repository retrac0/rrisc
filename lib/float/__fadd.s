; __fadd(r2=*dst, r3=*a, r4=*b) -- dst = a + b  (float48)
;
; Stack frame (16 words below saved r5):
;   sp+0  sign_a    sp+1  exp_a
;   sp+2  a_hi      sp+3  a_mid     sp+4  a_lo
;   sp+5  sign_b    sp+6  exp_b
;   sp+7  b_hi      sp+8  b_mid     sp+9  b_lo
;   sp+10 *dst      sp+11 result_sign
;   sp+12 res_hi    sp+13 res_mid   sp+14 res_lo
;   sp+15 res_exp
;
; Calling convention: r5=link, r6=sp; clobbers r1-r4.

%define FA_SIGN_A   0
%define FA_EXP_A    1
%define FA_A_HI     2
%define FA_A_MID    3
%define FA_A_LO     4
%define FA_SIGN_B   5
%define FA_EXP_B    6
%define FA_B_HI     7
%define FA_B_MID    8
%define FA_B_LO     9
%define FA_DST     10
%define FA_RSIGN   11
%define FA_R_HI    12
%define FA_R_MID   13
%define FA_R_LO    14
%define FA_R_EXP   15

; --- helper macro: load word at sp+offset into register ---
%macro FA_LD 2        ; FA_LD reg, offset
    and  r1, r6, r7
    addi r1, %2
    lwr  %1, r1
%endm

%macro FA_ST 2        ; FA_ST reg, offset
    and  r1, r6, r7
    addi r1, %2
    swr  %1, r1
%endm

__fadd:
    subi r6, 1
    swr  r5, r6
    subi r6, 16

    FA_ST r2, FA_DST

    ; ---- unpack a ----
    lwr  r1, r3              ; r1 = a.w0
    li   r2, 0o3777
    and  r2, r1, r2          ; exp_a
    FA_ST r2, FA_EXP_A
    rol  r1, r1
    and  r2, r0, r0
    addc r2, r0, r0
    FA_ST r2, FA_SIGN_A
    addi r3, 1
    lwr  r2, r3
    FA_ST r2, FA_A_HI
    addi r3, 1
    lwr  r2, r3
    FA_ST r2, FA_A_MID
    addi r3, 1
    lwr  r2, r3
    FA_ST r2, FA_A_LO

    ; ---- unpack b ----
    lwr  r1, r4              ; r1 = b.w0
    li   r2, 0o3777
    and  r2, r1, r2
    FA_ST r2, FA_EXP_B
    rol  r1, r1
    and  r2, r0, r0
    addc r2, r0, r0
    FA_ST r2, FA_SIGN_B
    addi r4, 1
    lwr  r2, r4
    FA_ST r2, FA_B_HI
    addi r4, 1
    lwr  r2, r4
    FA_ST r2, FA_B_MID
    addi r4, 1
    lwr  r2, r4
    FA_ST r2, FA_B_LO

    ; ---- special cases ----
    FA_LD r2, FA_EXP_A
    FA_LD r3, FA_EXP_B
    li    r4, 2047
    sub   r0, r2, r4
    bf    __fadd_a_special    ; exp_a == 2047 -> inf/NaN
    sub   r0, r3, r4
    bf    __fadd_b_special
    sub   r0, r0, r2          ; T=1 if exp_a != 0
    bt    __fadd_a_nonzero
    ; a is zero: return b
    FA_LD r2, FA_DST
    ; copy b back from saved words
    FA_LD r3, FA_SIGN_B
    FA_LD r4, FA_EXP_B
    ; reconstruct b.w0 and write
    li    r1, 0o3777
    and   r4, r4, r1
    sub   r0, r0, r3
    bf    __fadd_ret_b_nosign
    li    r1, 0o4000
    add   r4, r4, r1
__fadd_ret_b_nosign:
    swr   r4, r2
    addi  r2, 1
    FA_LD r1, FA_B_HI
    swr   r1, r2
    addi  r2, 1
    FA_LD r1, FA_B_MID
    swr   r1, r2
    addi  r2, 1
    FA_LD r1, FA_B_LO
    swr   r1, r2
    addi  r6, 16
    lwr   r5, r6
    addi  r6, 1
    jalr  r0, r5

__fadd_b_special:
    ; exp_b == 2047: return b (or NaN if a also 2047, but simplified: just return b)
    FA_LD r2, FA_DST
    FA_LD r3, FA_SIGN_B
    FA_LD r4, FA_EXP_B
    li    r1, 0o3777
    and   r4, r4, r1
    sub   r0, r0, r3
    bf    __fadd_ret_b_nosign
    li    r1, 0o4000
    add   r4, r4, r1
    ; jump back into the copy code above
    swr   r4, r2
    addi  r2, 1
    FA_LD r1, FA_B_HI
    swr   r1, r2
    addi  r2, 1
    FA_LD r1, FA_B_MID
    swr   r1, r2
    addi  r2, 1
    FA_LD r1, FA_B_LO
    swr   r1, r2
    addi  r6, 16
    lwr   r5, r6
    addi  r6, 1
    jalr  r0, r5

__fadd_a_special:
    ; exp_a == 2047: return a
    FA_LD r2, FA_DST
    FA_LD r3, FA_SIGN_A
    FA_LD r4, FA_EXP_A
    li    r1, 0o3777
    and   r4, r4, r1
    sub   r0, r0, r3
    bf    __fadd_ret_a_nosign
    li    r1, 0o4000
    add   r4, r4, r1
__fadd_ret_a_nosign:
    swr   r4, r2
    addi  r2, 1
    FA_LD r1, FA_A_HI
    swr   r1, r2
    addi  r2, 1
    FA_LD r1, FA_A_MID
    swr   r1, r2
    addi  r2, 1
    FA_LD r1, FA_A_LO
    swr   r1, r2
    addi  r6, 16
    lwr   r5, r6
    addi  r6, 1
    jalr  r0, r5

__fadd_a_nonzero:
    FA_LD r3, FA_EXP_B
    sub   r0, r0, r3          ; T=1 if exp_b != 0
    bt    __fadd_both_normal
    ; b is zero: return a
    FA_LD r2, FA_DST
    FA_LD r3, FA_SIGN_A
    FA_LD r4, FA_EXP_A
    li    r1, 0o3777
    and   r4, r4, r1
    sub   r0, r0, r3
    bf    __fadd_ret_a_nosign
    li    r1, 0o4000
    add   r4, r4, r1
    swr   r4, r2
    addi  r2, 1
    FA_LD r1, FA_A_HI
    swr   r1, r2
    addi  r2, 1
    FA_LD r1, FA_A_MID
    swr   r1, r2
    addi  r2, 1
    FA_LD r1, FA_A_LO
    swr   r1, r2
    addi  r6, 16
    lwr   r5, r6
    addi  r6, 1
    jalr  r0, r5

__fadd_both_normal:
    ; ---- ensure exp_a >= exp_b (swap if not) ----
    FA_LD r2, FA_EXP_A
    FA_LD r3, FA_EXP_B
    sub   r0, r2, r3          ; T=1 if exp_a < exp_b
    bf    __fadd_no_swap
    ; swap a and b in the frame
    FA_LD r1, FA_SIGN_A
    FA_LD r4, FA_SIGN_B
    FA_ST r4, FA_SIGN_A
    FA_ST r1, FA_SIGN_B
    FA_ST r3, FA_EXP_A
    FA_ST r2, FA_EXP_B
    FA_LD r1, FA_A_HI
    FA_LD r4, FA_B_HI
    FA_ST r4, FA_A_HI
    FA_ST r1, FA_B_HI
    FA_LD r1, FA_A_MID
    FA_LD r4, FA_B_MID
    FA_ST r4, FA_A_MID
    FA_ST r1, FA_B_MID
    FA_LD r1, FA_A_LO
    FA_LD r4, FA_B_LO
    FA_ST r4, FA_A_LO
    FA_ST r1, FA_B_LO

__fadd_no_swap:
    ; ---- align b: shift sig_b right by (exp_a - exp_b) ----
    FA_LD r2, FA_EXP_A
    FA_LD r3, FA_EXP_B
    sub   r4, r2, r3          ; r4 = diff = exp_a - exp_b (>=0)
    ; if diff >= 36, sig_b becomes 0
    li    r1, 36
    sub   r0, r4, r1          ; T=1 if diff < 36
    bf    __fadd_b_zeroed
    ; shift sig_b right by r4
    ; stash diff in FA_R_EXP (scratch until result exp is written); FA_* clobber r1.
    and   r1, r4, r7          ; r1 = diff
    FA_ST r1, FA_R_EXP
__fadd_align_loop:
    FA_LD r1, FA_R_EXP
    sub   r0, r0, r1          ; T=1 if count != 0
    bf    __fadd_aligned
    ; logical right shift sig_b by 1: clrt then ror hi,mid,lo
    clrt
    FA_LD r2, FA_B_HI
    ror   r2, r2
    FA_ST r2, FA_B_HI
    FA_LD r3, FA_B_MID
    ror   r3, r3
    FA_ST r3, FA_B_MID
    FA_LD r4, FA_B_LO
    ror   r4, r4
    FA_ST r4, FA_B_LO
    FA_LD r2, FA_R_EXP
    subi  r2, 1
    FA_ST r2, FA_R_EXP
    sub   r0, r0, r7          ; T=1
    bt    __fadd_align_loop

__fadd_b_zeroed:
    and   r1, r0, r0
    FA_ST r1, FA_B_HI
    FA_ST r1, FA_B_MID
    FA_ST r1, FA_B_LO

__fadd_aligned:
    ; ---- add or subtract significands ----
    FA_LD r2, FA_SIGN_A
    FA_LD r3, FA_SIGN_B
    sub   r0, r2, r3          ; T=1 if signs differ
    bt    __fadd_subtract
    ; same sign: add
    FA_ST r2, FA_RSIGN
    FA_LD r2, FA_EXP_A
    FA_ST r2, FA_R_EXP
    ; 36-bit add: lo, mid, hi with carry chain
    clrt
    FA_LD r2, FA_A_LO
    FA_LD r3, FA_B_LO
    addc  r2, r2, r3
    FA_ST r2, FA_R_LO
    FA_LD r2, FA_A_MID
    FA_LD r3, FA_B_MID
    addc  r2, r2, r3
    FA_ST r2, FA_R_MID
    FA_LD r2, FA_A_HI
    FA_LD r3, FA_B_HI
    addc  r2, r2, r3          ; T = carry out (overflow bit 36)
    FA_ST r2, FA_R_HI
    ; if carry (T=1): shift result right 1, increment exp
    bf    __fadd_add_done
    ; carry: ror hi,mid,lo with T=1 (fills bit 11 of hi with 1 = leading bit)
    ror   r2, r2              ; r2 = r_hi >> 1 with bit11=1 (T was 1)
    FA_ST r2, FA_R_HI
    FA_LD r3, FA_R_MID
    ror   r3, r3
    FA_ST r3, FA_R_MID
    FA_LD r4, FA_R_LO
    ror   r4, r4
    FA_ST r4, FA_R_LO
    FA_LD r2, FA_R_EXP
    addi  r2, 1
    FA_ST r2, FA_R_EXP
    ; check overflow: exp == 2047 -> inf
    li    r3, 2047
    sub   r0, r2, r3
    bf    __fadd_overflow
    sub   r0, r2, r3          ; recheck (bf checks T=0 = equal)
    bt    __fadd_add_done     ; exp < 2047 is fine
__fadd_overflow:
    ; return inf with result sign
    FA_LD r2, FA_DST
    FA_LD r3, FA_RSIGN
    li    r4, 2047
    sub   r0, r0, r3
    bf    __fadd_inf_nosign
    li    r1, 0o4000
    add   r4, r4, r1
__fadd_inf_nosign:
    swr   r4, r2
    addi  r2, 1
    and   r1, r0, r0
    swr   r1, r2
    addi  r2, 1
    swr   r1, r2
    addi  r2, 1
    swr   r1, r2
    addi  r6, 16
    lwr   r5, r6
    addi  r6, 1
    jalr  r0, r5

__fadd_add_done:
    ; write result
    li    r1, 4
    sub   r0, r1, r1          ; T=0
    sub   r0, r0, r1          ; T=1 (go to pack path)
    bt    __fadd_pack

__fadd_subtract:
    ; different signs: subtract smaller aligned sig from larger
    ; result_sign = sign_a (the larger magnitude, after swap)
    FA_LD r2, FA_SIGN_A
    FA_ST r2, FA_RSIGN
    FA_LD r2, FA_EXP_A
    FA_ST r2, FA_R_EXP
    ; 36-bit subtract: result = sig_a - sig_b
    ; use two's complement: result = sig_a + ~sig_b + 1
    ; set T=1 for the +1
    sub   r0, r0, r7          ; T=1 (0 - (-1) = 1, borrow=1)
    FA_LD r2, FA_B_LO
    sub   r2, r7, r2          ; ~b_lo
    FA_LD r3, FA_A_LO
    addc  r3, r3, r2
    FA_ST r3, FA_R_LO
    FA_LD r2, FA_B_MID
    sub   r2, r7, r2
    FA_LD r3, FA_A_MID
    addc  r3, r3, r2
    FA_ST r3, FA_R_MID
    FA_LD r2, FA_B_HI
    sub   r2, r7, r2
    FA_LD r3, FA_A_HI
    addc  r3, r3, r2
    FA_ST r3, FA_R_HI
    ; check zero
    FA_LD r2, FA_R_HI
    FA_LD r3, FA_R_MID
    FA_LD r4, FA_R_LO
    add   r1, r2, r3
    add   r1, r1, r4
    sub   r0, r0, r1          ; T=1 if nonzero
    bf    __fadd_zero_result
    ; normalize: shift left until bit11 of r_hi is set
__fadd_norm_loop:
    clrt
    FA_LD r2, FA_R_HI
    and   r1, r2, r7
    rol   r1, r1              ; T = bit11 of r_hi (T must be 0 before rol)
    bt    __fadd_normed
    ; shift left
    clrt
    FA_LD r4, FA_R_LO
    rol   r4, r4
    FA_ST r4, FA_R_LO
    FA_LD r3, FA_R_MID
    rol   r3, r3
    FA_ST r3, FA_R_MID
    rol   r2, r2
    FA_ST r2, FA_R_HI
    FA_LD r3, FA_R_EXP
    subi  r3, 1
    FA_ST r3, FA_R_EXP
    ; if exp <= 0: underflow to 0
    sub   r0, r0, r3          ; T=1 if exp != 0
    bf    __fadd_zero_result
    sub   r0, r0, r7          ; T=1
    bt    __fadd_norm_loop

__fadd_normed:
__fadd_pack:
    ; ---- pack result into dst ----
    FA_LD r2, FA_DST
    FA_LD r3, FA_R_EXP
    li    r4, 0o3777
    and   r3, r3, r4          ; exp bits 10:0
    FA_LD r4, FA_RSIGN
    sub   r0, r0, r4          ; T=1 if negative
    bf    __fadd_pack_nosign
    li    r1, 0o4000
    add   r3, r3, r1
__fadd_pack_nosign:
    swr   r3, r2              ; dst[0] = w0
    addi  r2, 1
    FA_LD r1, FA_R_HI
    swr   r1, r2
    addi  r2, 1
    FA_LD r1, FA_R_MID
    swr   r1, r2
    addi  r2, 1
    FA_LD r1, FA_R_LO
    swr   r1, r2
    addi  r6, 16
    lwr   r5, r6
    addi  r6, 1
    jalr  r0, r5

__fadd_zero_result:
    FA_LD r2, FA_DST
    and   r1, r0, r0
    swr   r1, r2
    addi  r2, 1
    swr   r1, r2
    addi  r2, 1
    swr   r1, r2
    addi  r2, 1
    swr   r1, r2
    addi  r6, 16
    lwr   r5, r6
    addi  r6, 1
    jalr  r0, r5
