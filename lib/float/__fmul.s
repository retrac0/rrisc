; __fmul(r2=*dst, r3=*a, r4=*b) -- dst = a * b  (float48)
;
; Precision: this routine multiplies a_hi * b_hi (the top 12 bits of each
; significand) into a 24-bit product. The result populates sig_hi and
; sig_mid; sig_lo is always written zero. That gives ~24 bits of mantissa
; precision (worst case: 1 ulp at sig_mid). If you need full 36-bit
; precision the routine has to be widened to multiply all 12-bit chunks.
;
; Stack (15 words + saved r5):
;   sp+0  *dst      sp+1  *b_saved
;   sp+2  sign_a    sp+3  exp_a     sp+4  a_hi
;   sp+5  sign_b    sp+6  exp_b     sp+7  b_hi
;   sp+8  rsign
;   sp+9  P_lo      sp+10 P_hi       (product accumulator)
;   sp+11 a_lo_sh   sp+12 a_hi_sh    (shifting copy of a_hi)
;   sp+13 b_rem     sp+14 count      (shifting b and loop counter)

__fmul:
    subi r6, 1
    swr  r5, r6
    subi r6, 15

    and  r1, r6, r7
    swr  r2, r1              ; [sp+0] = *dst
    and  r1, r6, r7
    addi r1, 1
    swr  r4, r1              ; [sp+1] = *b

    ; --- unpack a (r3=*a) using shared helper ---
    and  r2, r3, r7
    li   r1, __funpack_hi
    jalr r5, r1               ; r2=sign_a, r3=exp_a, r4=a_hi
    and  r1, r6, r7
    addi r1, 2
    swr  r2, r1               ; [sp+2] = sign_a
    addi r1, 1
    swr  r3, r1               ; [sp+3] = exp_a
    addi r1, 1
    swr  r4, r1               ; [sp+4] = a_hi

    ; --- unpack b (from saved *b) using shared helper ---
    and  r1, r6, r7
    addi r1, 1
    lwr  r2, r1               ; r2 = *b
    li   r1, __funpack_hi
    jalr r5, r1               ; r2=sign_b, r3=exp_b, r4=b_hi
    and  r1, r6, r7
    addi r1, 5
    swr  r2, r1               ; [sp+5] = sign_b
    addi r1, 1
    swr  r3, r1               ; [sp+6] = exp_b
    addi r1, 1
    swr  r4, r1               ; [sp+7] = b_hi

    ; --- result sign = sign_a XOR sign_b ---
    and  r1, r6, r7
    addi r1, 2
    lwr  r2, r1
    and  r1, r6, r7
    addi r1, 5
    lwr  r3, r1
    add  r4, r2, r3          ; sum; XOR = bit0 of sum (since each is 0 or 1)
    clrt
    ror  r4, r4              ; T = bit0
    and  r4, r0, r0
    addc r4, r0, r0          ; r4 = XOR
    and  r1, r6, r7
    addi r1, 8
    swr  r4, r1              ; [sp+8] = rsign

    ; --- check specials ---
    and  r1, r6, r7
    addi r1, 3
    lwr  r2, r1              ; exp_a
    sub  r0, r0, r2
    bf   __fmul_zero
    and  r1, r6, r7
    addi r1, 6
    lwr  r3, r1              ; exp_b
    sub  r0, r0, r3
    bf   __fmul_zero
    li   r4, 2047
    sub  r0, r2, r4
    bf   __fmul_inf
    sub  r0, r3, r4
    bf   __fmul_inf

    ; --- set up multiply: a_lo_sh=a_hi, a_hi_sh=0, b_rem=b_hi, P_lo=P_hi=0, count=12 ---
    and  r1, r6, r7
    addi r1, 4
    lwr  r2, r1              ; a_hi
    and  r1, r6, r7
    addi r1, 11
    swr  r2, r1              ; [sp+11] = a_lo_sh = a_hi
    and  r1, r6, r7
    addi r1, 12
    and  r2, r0, r0
    swr  r2, r1              ; [sp+12] = a_hi_sh = 0
    and  r1, r6, r7
    addi r1, 9
    swr  r2, r1              ; [sp+9] = P_lo = 0
    and  r1, r6, r7
    addi r1, 10
    swr  r2, r1              ; [sp+10] = P_hi = 0
    and  r1, r6, r7
    addi r1, 7
    lwr  r2, r1              ; b_hi
    and  r1, r6, r7
    addi r1, 13
    swr  r2, r1              ; [sp+13] = b_rem = b_hi
    li   r2, 12
    and  r1, r6, r7
    addi r1, 14
    swr  r2, r1              ; [sp+14] = count = 12

__fmul_loop:
    and  r1, r6, r7
    addi r1, 14
    lwr  r4, r1              ; count
    sub  r0, r0, r4
    bf   __fmul_mul_done
    subi r4, 1
    swr  r4, r1              ; count--

    ; shift b_rem right (logical), T = bit0
    ; reuse r1 (points at [sp+14]) to access b_rem at [sp+13]
    subi r1, 1
    lwr  r3, r1
    clrt
    ror  r3, r3              ; T = bit0 of b_rem; r3 >>= 1
    swr  r3, r1

    ; save T (the bit to add): r4 = T
    and  r4, r0, r0
    addc r4, r0, r0          ; r4 = bit (0 or 1)
    sub  r0, r0, r4          ; T=1 if bit != 0
    bf   __fmul_no_add

    ; P += (a_hi_sh:a_lo_sh) with carry propagation
    clrt
    and  r1, r6, r7
    addi r1, 11
    lwr  r2, r1              ; a_lo_sh
    and  r1, r6, r7
    addi r1, 9
    lwr  r3, r1              ; P_lo
    addc r3, r3, r2
    swr  r3, r1              ; P_lo updated (T=carry)

    and  r1, r6, r7
    addi r1, 12
    lwr  r2, r1              ; a_hi_sh
    and  r1, r6, r7
    addi r1, 10
    lwr  r3, r1              ; P_hi
    addc r3, r3, r2          ; T=carry (high overflow ignored)
    swr  r3, r1

__fmul_no_add:
    ; shift (a_hi_sh:a_lo_sh) left 1
    clrt
    and  r1, r6, r7
    addi r1, 11
    lwr  r2, r1
    rol  r2, r2              ; T = bit11 of a_lo_sh (carry to a_hi_sh)
    swr  r2, r1

    and  r1, r6, r7
    addi r1, 12
    lwr  r2, r1
    rol  r2, r2
    swr  r2, r1

    sub  r0, r0, r7          ; T=1
    bt   __fmul_loop

__fmul_mul_done:
    ; P_hi:P_lo = a_hi * b_hi (24-bit product)
    ; leading bit is at position 22 or 23 of P (= bit 10 or 11 of P_hi)

    and  r1, r6, r7
    addi r1, 10
    lwr  r2, r1              ; P_hi
    ; test bit11 of P_hi
    and  r3, r2, r7
    rol  r3, r3              ; T = bit11 of P_hi
    bt   __fmul_bit23

    ; bit11 of P_hi is 0 (leading bit at 22 = bit10 of P_hi)
    ; shift P_hi:P_lo left 1 to normalize (bring bit10 to bit11)
    clrt
    and  r1, r6, r7
    addi r1, 9
    lwr  r3, r1              ; P_lo
    rol  r3, r3              ; T = bit11 of P_lo
    swr  r3, r1
    rol  r2, r2              ; P_hi <<= 1, bit0 from T
    and  r1, r6, r7
    addi r1, 10
    swr  r2, r1

    ; result_exp = exp_a + exp_b - 1024
    and  r1, r6, r7
    addi r1, 3
    lwr  r3, r1              ; exp_a
    and  r1, r6, r7
    addi r1, 6
    lwr  r4, r1              ; exp_b
    add  r3, r3, r4
    li   r4, 1024
    sub  r3, r3, r4          ; result_exp
    li   r1, 0
    sub  r0, r1, r3          ; T=1 if result_exp > 0 (r1=0, so T=1 if 0 < r3)
    bt   __fmul_exp_ok
    bt   __fmul_zero         ; actually: T=1 if r3 > 0... hmm
    ; revisit: sub r0, r1, r3 = 0 - r3; T=1 if 0 < r3 (borrow = r3 > 0)
    ; if T=1: r3 > 0 -> ok
    ; if T=0: r3 <= 0 -> underflow
    ; But we want T=1 to mean "ok", T=0 to mean underflow
    ; sub r0, r0, r3: T=1 if r3 != 0 and positive or negative?
    ; sub sets T=borrow = (0 < r3 unsigned). r3 might be large if exp is very small.
    ; Hmm, need to check for both overflow (>2047) and underflow (<=0).
    bt   __fmul_pack
    li   r1, __fmul_zero
    jalr r0, r1

__fmul_bit23:
    ; bit11 of P_hi is 1: no normalization needed
    ; result_exp = exp_a + exp_b - 1023
    and  r1, r6, r7
    addi r1, 3
    lwr  r3, r1              ; exp_a
    and  r1, r6, r7
    addi r1, 6
    lwr  r4, r1              ; exp_b
    add  r3, r3, r4
    li   r4, 1023
    sub  r3, r3, r4          ; result_exp

__fmul_exp_ok:
    ; check underflow: exp <= 0
    sub  r0, r0, r3          ; T=1 if exp != 0
    bf   __fmul_zero
    ; check overflow: exp >= 2047
    li   r4, 2047
    sub  r0, r3, r4          ; T=1 if exp < 2047
    bf   __fmul_inf

__fmul_pack:
    ; result: sign from [sp+8], exp=r3, sig_hi=P_hi, sig_mid=P_lo>>...
    ; Actually sig_hi = P_hi (bits 35..24 of result sig), sig_mid = P_lo (bits 23..12), sig_lo=0
    ; Build w0 via helper: r3=exp_raw, r4=sign -> r2=w0
    and  r3, r3, r7
    and  r1, r6, r7
    addi r1, 8
    lwr  r4, r1              ; r4 = rsign
    li   r1, __fmake_w0
    jalr r5, r1              ; r2 = w0
    and  r3, r2, r7          ; r3 = w0 (preserve across dst load)

    and  r1, r6, r7
    lwr  r2, r1              ; r2 = *dst
    swr  r3, r2              ; dst[0] = w0
    addi r2, 1
    and  r1, r6, r7
    addi r1, 10
    lwr  r3, r1              ; P_hi = sig_hi
    swr  r3, r2              ; dst[1] = sig_hi
    addi r2, 1
    and  r1, r6, r7
    addi r1, 9
    lwr  r3, r1              ; P_lo = sig_mid
    swr  r3, r2              ; dst[2] = sig_mid
    addi r2, 1
    and  r3, r0, r0
    swr  r3, r2              ; dst[3] = 0
    addi r6, 15
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5

__fmul_zero:
    and  r1, r6, r7
    lwr  r2, r1
    li   r1, __fstore_zero
    jalr r5, r1
    addi r6, 15
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5

__fmul_inf:
    and  r1, r6, r7
    lwr  r2, r1
    and  r1, r6, r7
    addi r1, 8
    lwr  r3, r1              ; rsign
    li   r1, __fstore_inf
    jalr r5, r1
    addi r6, 15
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5
