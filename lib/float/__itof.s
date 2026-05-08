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
;   [r6+2] = tmp (normalized magnitude)

__itof:
    subi r6, 1
    swr  r5, r6
    subi r6, 3

    ; save dst ptr
    and  r1, r6, r7
    addi r1, 1
    swr  r2, r1              ; [r6+1] = *dst

    ; n = r3; check zero
    sub  r0, r0, r3          ; T=1 if n != 0
    bf   __itof_zero

    ; extract sign
    clrt
    and  r1, r3, r7          ; r1 = n
    rol  r1, r1               ; T = bit11 (sign); T must be 0 before rol
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
    clrt
    and  r1, r3, r7          ; r1 = r3
    rol  r1, r1               ; T = bit11 of r3 (T must be 0 before rol)
    bt   __itof_normed       ; leading 1 found
    clrt
    rol  r3, r3               ; r3 <<= 1
    addi r4, 1
    sub  r0, r0, r7           ; T=1 always
    bt   __itof_norm_loop

__itof_normed:
    ; r3 = normalized magnitude (bit 11 = 1), r4 = shift count k
    ; stash magnitude before we reuse r3 for exp
    and  r1, r6, r7
    addi r1, 2
    swr  r3, r1

    ; exp_raw = 1035 - k
    li   r1, 1035
    sub  r1, r1, r4          ; r1 = exp_raw
    ; build w0 (exp in r3, sign in r4) — inlined __fmake_w0 for standalone asm
    and  r3, r1, r7          ; r3 = exp_raw
    and  r1, r6, r7
    lwr  r4, r1              ; r4 = sign
    li   r1, 0o3777
    and  r2, r3, r1
    sub  r0, r0, r4
    bf   __itof_w0_pos
    li   r1, 0o4000
    add  r2, r2, r1
__itof_w0_pos:
    ; reload normalized magnitude for w1
    and  r1, r6, r7
    addi r1, 2
    lwr  r3, r1              ; r3 = magnitude
    and  r1, r6, r7
    addi r1, 1
    lwr  r1, r1              ; r1 = *dst
    swr  r2, r1              ; dst[0] = w0
    addi r1, 1
    swr  r3, r1              ; dst[1] = sig_hi = normalized magnitude
    addi r1, 1
    ; dst[2] = dst[3] = 0
    and  r2, r0, r0
    swr  r2, r1
    addi r1, 1
    swr  r2, r1
    addi r6, 3
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5

__itof_zero:
    ; emit +0 — inlined __fstore_zero (r2 = *dst)
    and  r1, r0, r0
    swr  r1, r2
    addi r2, 1
    swr  r1, r2
    addi r2, 1
    swr  r1, r2
    addi r2, 1
    swr  r1, r2
    addi r6, 3
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5
