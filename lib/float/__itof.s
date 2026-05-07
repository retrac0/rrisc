; __itof(r2=*dst, r3=int) -- convert 12-bit signed int to float48
;
; Algorithm:
;   if n == 0: emit +0
;   if n < 0: sign=1, n = -n
;   normalize: shift n left until bit 11 set (count shifts as e-adjustment)
;   place n in sig_hi (bits 35..24); sig_mid=sig_lo=0
;   exp = 1024 + 11 - extra_left_shifts  (representing value = n * 2^(exp-1024-35))
;     = 1024 + 35 - (35 - 11 - left_shifts) ... simplify:
;     after normalizing, the integer value n sits at sig_hi with bit 11 as leading bit.
;     value = sig_hi * 2^(exp-1024-35)
;     n = sig_hi * 2^(11 - 35) * 2^(exp-1024) ... let's just count:
;     after left-shifting n by k places, n_shifted = n << k  (bit 11 = leading 1)
;     The actual value = n = n_shifted * 2^(-k)
;     n_shifted placed at sig_hi => value = n_shifted * 2^(exp-1024-35)
;     so n = n_shifted * 2^(exp-1024-35) * 2^(-k)?  No:
;     sig = n_shifted as bits 35..24, sig_mid=sig_lo=0 => sig_full = n_shifted << 24
;     value = sig_full * 2^(exp-1024-35)
;           = (n << k) << 24 * 2^(exp-1024-35)
;           = n * 2^(k+24) * 2^(exp-1024-35)
;           = n exactly when k+24 + exp-1024-35 = 0 => exp = 1024+35-24-k = 1035-k
;   exp_raw = 1035 - k  where k = number of left shifts to normalize n into bit 11.
;
; Stack frame (8 words):
;   [r6+0] = sign
;   [r6+1] = ptr_dst  (r2 saved)

__itof:
    subi r6, 1
    swr  r5, r6
    subi r6, 2

    ; save dst ptr
    and  r1, r6, r7
    addi r1, 1
    swr  r2, r1              ; [r6+1] = *dst

    ; n = r3; check zero
    sub  r0, r0, r3          ; T=1 if n != 0
    bf   __itof_zero

    ; extract sign
    and  r1, r3, r7          ; r1 = n
    rol  r1, r1               ; T = bit11 (sign)
    and  r4, r0, r0
    addc r4, r0, r0           ; r4 = sign bit
    and  r1, r6, r7
    swr  r4, r1              ; [r6+0] = sign

    ; if negative, negate
    sub  r0, r0, r4          ; T=1 if sign!=0
    bf   __itof_positive
    sub  r3, r0, r3          ; r3 = -n (magnitude)

__itof_positive:
    ; r3 = magnitude (positive, 12-bit, nonzero)
    ; normalize: shift left until bit 11 is set; count in r4
    and  r4, r0, r0          ; r4 = k (shift count)
__itof_norm_loop:
    and  r1, r3, r7          ; r1 = r3
    rol  r1, r1               ; T = bit11 of r3
    bt   __itof_normed       ; leading 1 found
    clrt
    rol  r3, r3               ; r3 <<= 1
    addi r4, 1
    sub  r0, r0, r7           ; T=1 always
    bt   __itof_norm_loop

__itof_normed:
    ; r3 = normalized magnitude (bit 11 = 1), r4 = shift count k
    ; exp_raw = 1035 - k
    li   r1, 1035
    sub  r1, r1, r4          ; r1 = exp_raw
    ; build w0: sign << 11 | exp_raw
    and  r1, r1, r7          ; mask exp to 12 bits (should already be)
    li   r4, 0o3777
    and  r1, r1, r4          ; keep only bits 10:0 of exp
    and  r2, r6, r7
    lwr  r4, r2              ; r4 = sign
    ; sign bit: if sign=1, OR bit 11
    sub  r0, r0, r4          ; T=1 if sign
    bf   __itof_nosign
    li   r4, 0o4000
    add  r1, r1, r4
__itof_nosign:
    ; write w0
    and  r2, r6, r7
    addi r2, 1
    lwr  r2, r2              ; r2 = *dst
    swr  r1, r2              ; dst[0] = w0
    addi r2, 1
    swr  r3, r2              ; dst[1] = sig_hi = normalized magnitude
    addi r2, 1
    ; dst[2] = dst[3] = 0
    and  r1, r0, r0
    swr  r1, r2
    addi r2, 1
    swr  r1, r2
    addi r6, 2
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5

__itof_zero:
    ; emit +0: all four words = 0
    and  r1, r0, r0
    swr  r1, r2
    addi r2, 1
    swr  r1, r2
    addi r2, 1
    swr  r1, r2
    addi r2, 1
    swr  r1, r2
    addi r6, 2
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5
