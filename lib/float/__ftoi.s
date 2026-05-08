; __ftoi(r2=*f) -> r2 = int  -- convert float48 to 12-bit signed int (truncate)
;
; value = (-1)^sign * sig * 2^(exp - 1024 - 35)
; shift = exp - 1024 - 35  (= exp - 1059)
; If shift >= 0: result = sig << shift  (but clamped to 12 bits)
; If shift < 0:  result = sig >> (-shift)
; Zero/inf/NaN -> 0
;
; Stack frame (12 words after saved r5):
;   [r6+0]  = sign
;   [r6+1]  = exp
;   [r6+2]  = sig_hi (w1)
;   [r6+3]  = sig_mid (w2)
;   [r6+4]  = sig_lo (w3)
;   [r6+5]  = scratch

__ftoi:
    subi r6, 1
    swr  r5, r6
    subi r6, 6

    ; load w0 -> extract sign and exp
    lwr  r1, r2
    ; sign = bit 11 of w0
    clrt
    and  r3, r1, r7         ; r3 = w0
    rol  r3, r3              ; T = bit11 (sign); T must be 0 before rol
    ; save sign: T=1 means negative
    ; r4 = sign (0 or 1)
    and  r4, r0, r0          ; r4 = 0
    addc r4, r0, r0          ; r4 = T (= sign bit)
    and  r1, r6, r7
    swr  r4, r1              ; [r6+0] = sign

    ; exp = w0 & 0o3777 (bits 10:0)
    lwr  r1, r2
    li   r3, 0o3777
    and  r3, r1, r3          ; r3 = exp_raw
    and  r1, r6, r7
    addi r1, 1
    swr  r3, r1              ; [r6+1] = exp_raw

    ; load w1, w2, w3
    and  r1, r2, r7          ; r1 = ptr
    addi r1, 1
    lwr  r4, r1              ; r4 = sig_hi
    and  r1, r6, r7
    addi r1, 2
    swr  r4, r1              ; [r6+2] = sig_hi

    and  r1, r2, r7
    addi r1, 2
    lwr  r4, r1              ; r4 = sig_mid
    and  r1, r6, r7
    addi r1, 3
    swr  r4, r1              ; [r6+3] = sig_mid

    and  r1, r2, r7
    addi r1, 3
    lwr  r4, r1              ; r4 = sig_lo
    and  r1, r6, r7
    addi r1, 4
    swr  r4, r1              ; [r6+4] = sig_lo

    ; check exp_raw: 0 -> return 0; 2047 -> return 0
    and  r1, r6, r7
    addi r1, 1
    lwr  r3, r1              ; r3 = exp_raw
    sub  r0, r0, r3          ; T=1 if exp != 0
    bf   __ftoi_zero
    li   r4, 2047
    sub  r0, r3, r4
    sub  r0, r0, r0          ; T=0 (need T=1 if equal)
    sub  r1, r3, r4          ; r1 = exp - 2047; T=1 if exp<2047
    bt   __ftoi_nonspecial
__ftoi_zero:
    and  r2, r0, r0
    addi r6, 6
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5

__ftoi_nonspecial:
    ; We work with the top 12 bits of the significand only (sig_hi: bits 35..24).
    ; That gives ~12 bits of precision which is all a 12-bit signed result can
    ; hold anyway. value ~= sig_hi * 2^(exp - BIAS - 11) = sig_hi * 2^(exp-1035).
    ; shift = exp - 1035
    ; r3 = exp_raw
    li   r4, 1035
    sub  r3, r3, r4          ; r3 = shift (signed 12-bit)
    ; if shift >= 12 (positive): result overflows 12 bits -> return 0
    ; if shift <= -12 (negative): sig_hi fully shifted out -> return 0

    and  r1, r6, r7
    addi r1, 2
    lwr  r2, r1              ; r2 = sig_hi (result starts here, magnitude)

    ; determine sign of shift: bit 11 of r3
    clrt
    and  r1, r3, r7          ; r1 = r3
    rol  r1, r1               ; T = bit11 of shift (T must be 0 before rol)
    bt   __ftoi_right_shift

__ftoi_left_shift:
    ; shift r2 left by r3 positions (r3 >= 0, r3 < 12 for useful result)
    li   r4, 12
    sub  r0, r3, r4           ; T=1 if r3 < 12
    bf   __ftoi_zero          ; shift >= 12 -> overflow -> return 0
__ftoi_lshift_loop:
    sub  r0, r0, r3           ; T=1 if r3 != 0
    bf   __ftoi_apply_sign
    clrt
    rol  r2, r2
    subi r3, 1
    sub  r0, r0, r7           ; T=1 always
    bt   __ftoi_lshift_loop

__ftoi_right_shift:
    ; shift is negative: r3 = shift (negative, in two's complement 12-bit)
    ; actual right-shift amount = -r3 = 0 - r3
    sub  r3, r0, r3           ; r3 = -shift (positive)
    ; if r3 >= 12 -> sig_hi shifted to 0 -> return 0
    li   r4, 12
    sub  r0, r3, r4           ; T=1 if r3 < 12
    bf   __ftoi_zero
__ftoi_rshift_loop:
    sub  r0, r0, r3           ; T=1 if r3 != 0
    bf   __ftoi_apply_sign
    ; logical right shift by 1 (sig_hi is unsigned magnitude; bit 11 is just
    ; the leading 1 of the float significand, NOT a sign bit).
    clrt
    ror  r2, r2
    subi r3, 1
    sub  r0, r0, r7           ; T=1 always
    bt   __ftoi_rshift_loop

__ftoi_apply_sign:
    ; r2 = absolute magnitude; apply sign
    and  r1, r6, r7
    lwr  r3, r1              ; r3 = sign (0=pos, 1=neg)
    sub  r0, r0, r3          ; T=1 if sign != 0
    bf   __ftoi_done
    sub  r2, r0, r2          ; r2 = -r2
__ftoi_done:
    addi r6, 6
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5
