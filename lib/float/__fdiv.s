; __fdiv(r2=*dst, r3=*a, r4=*b) -- dst = a / b  (float48)
;
; Uses sig_hi only. Computes q = (a_hi << 12) / b_hi via 12-step restoring division.
; exp_r = exp_a - exp_b + BIAS.
;
; Stack (14 words + saved r5):
;   sp+0 *dst    sp+1 *b_saved
;   sp+2 sign_a  sp+3 exp_a    sp+4 a_hi
;   sp+5 sign_b  sp+6 exp_b    sp+7 b_hi
;   sp+8 rsign   sp+9 rem      sp+10 quot   sp+11 num   sp+12 count

__fdiv:
    subi r6, 1
    swr  r5, r6
    subi r6, 13

    and  r1, r6, r7
    swr  r2, r1
    and  r1, r6, r7
    addi r1, 1
    swr  r4, r1

    ; unpack a
    lwr  r1, r3
    li   r2, 0o3777
    and  r2, r1, r2
    and  r4, r6, r7
    addi r4, 3
    swr  r2, r4
    rol  r1, r1
    and  r2, r0, r0
    addc r2, r0, r0
    and  r4, r6, r7
    addi r4, 2
    swr  r2, r4
    addi r3, 1
    lwr  r2, r3
    and  r4, r6, r7
    addi r4, 4
    swr  r2, r4              ; a_hi

    ; unpack b
    and  r3, r6, r7
    addi r3, 1
    lwr  r3, r3              ; *b
    lwr  r1, r3
    li   r2, 0o3777
    and  r2, r1, r2
    and  r4, r6, r7
    addi r4, 6
    swr  r2, r4
    rol  r1, r1
    and  r2, r0, r0
    addc r2, r0, r0
    and  r4, r6, r7
    addi r4, 5
    swr  r2, r4
    addi r3, 1
    lwr  r2, r3
    and  r4, r6, r7
    addi r4, 7
    swr  r2, r4              ; b_hi

    ; result sign = sign_a XOR sign_b
    and  r1, r6, r7
    addi r1, 2
    lwr  r2, r1
    and  r1, r6, r7
    addi r1, 5
    lwr  r3, r1
    add  r4, r2, r3
    clrt
    ror  r4, r4
    and  r4, r0, r0
    addc r4, r0, r0
    and  r1, r6, r7
    addi r1, 8
    swr  r4, r1

    ; specials
    and  r1, r6, r7
    addi r1, 6
    lwr  r3, r1
    sub  r0, r0, r3
    bf   __fdiv_inf          ; b zero -> inf
    and  r1, r6, r7
    addi r1, 3
    lwr  r2, r1
    sub  r0, r0, r2
    bf   __fdiv_zero         ; a zero -> zero
    li   r4, 2047
    sub  r0, r2, r4
    bf   __fdiv_inf
    sub  r0, r3, r4
    bf   __fdiv_zero         ; b inf -> zero

    ; --- division: q = (a_hi << 12) / b_hi ---
    ; We shift a_hi bits out one at a time (from bit 11 downward = 12 bits).
    ; rem starts at 0; each step: rem = rem*2 + next_bit; if rem>=b_hi: rem-=b_hi, q|=1.
    ; b_hi kept in r3 throughout; everything else in/from stack.

    ; init
    and  r1, r6, r7
    addi r1, 7
    lwr  r3, r1              ; r3 = b_hi (constant during loop)

    and  r1, r6, r7
    addi r1, 4
    lwr  r2, r1              ; a_hi
    and  r1, r6, r7
    addi r1, 11
    swr  r2, r1              ; [sp+11] = num = a_hi

    and  r2, r0, r0
    and  r1, r6, r7
    addi r1, 9
    swr  r2, r1              ; [sp+9] = rem = 0
    and  r1, r6, r7
    addi r1, 10
    swr  r2, r1              ; [sp+10] = quot = 0

    li   r2, 12
    and  r1, r6, r7
    addi r1, 12
    swr  r2, r1              ; [sp+12] = count = 12

__fdiv_loop:
    and  r1, r6, r7
    addi r1, 12
    lwr  r4, r1              ; count
    sub  r0, r0, r4          ; T=1 if count!=0
    bf   __fdiv_loop_done
    subi r4, 1
    swr  r4, r1              ; count--

    ; shift num left, extract bit11 -> into r4 (0 or 1)
    and  r1, r6, r7
    addi r1, 11
    lwr  r2, r1              ; num
    and  r4, r2, r7
    rol  r4, r4              ; T = bit11 of num (the next numerator bit)
    rol  r2, r2              ; num <<= 1 (shift out bit11)
    swr  r2, r1              ; store updated num
    and  r4, r0, r0
    addc r4, r0, r0          ; r4 = extracted bit (0 or 1)

    ; rem = rem*2 + bit
    and  r1, r6, r7
    addi r1, 9
    lwr  r2, r1              ; rem
    clrt
    rol  r2, r2              ; rem <<= 1 (T was 0 from clrt... wait: clrt was not called)
    ; oops: need clrt before rol to ensure bit0 = 0 (not old T)
    ; fix: clrt before rol r2
    ; redo:
    and  r1, r6, r7
    addi r1, 9
    lwr  r2, r1              ; rem (reload since we clobbered r2 above during num shift)
    ; Wait, r2 was overwritten above. Let me be more careful.
    ; ABOVE: r2 = num (loaded from sp+11), then modified, stored. r2 = updated_num.
    ; So r2 is still updated_num. I need to reload rem.
    ; (Already loading it here from sp+9, so that's correct.)
    clrt
    rol  r2, r2              ; rem <<= 1; T = old bit11 of rem (lost, ok since rem < b_hi <= 0xFFF)
    add  r2, r2, r4          ; rem += bit (r4 is 0 or 1; add is fine, no carry expected)

    ; if rem >= r3 (b_hi): rem -= b_hi; set quotient bit
    sub  r0, r2, r3          ; T=1 if rem < b_hi (borrow)
    bt   __fdiv_no_sub       ; branch if rem < b_hi (T=1 = borrow = true)

    ; rem >= b_hi
    sub  r2, r2, r3          ; rem -= b_hi
    and  r1, r6, r7
    addi r1, 9
    swr  r2, r1              ; store rem

    ; quotient = (quot << 1) | 1
    and  r1, r6, r7
    addi r1, 10
    lwr  r2, r1
    clrt
    rol  r2, r2
    addi r2, 1
    swr  r2, r1
    sub  r0, r0, r7
    bt   __fdiv_loop

__fdiv_no_sub:
    ; rem < b_hi: just shift quotient left
    and  r1, r6, r7
    addi r1, 9
    swr  r2, r1              ; store rem (unchanged value in r2)

    and  r1, r6, r7
    addi r1, 10
    lwr  r2, r1
    clrt
    rol  r2, r2
    swr  r2, r1
    sub  r0, r0, r7
    bt   __fdiv_loop

__fdiv_loop_done:
    ; quot in [sp+10], compute exponent
    and  r1, r6, r7
    addi r1, 10
    lwr  r2, r1              ; r2 = quotient (12-bit)

    and  r1, r6, r7
    addi r1, 3
    lwr  r3, r1              ; exp_a
    and  r1, r6, r7
    addi r1, 6
    lwr  r4, r1              ; exp_b
    sub  r3, r3, r4
    li   r4, 1024
    add  r3, r3, r4          ; exp_r = exp_a - exp_b + 1024

    ; normalize: if bit11 of quot not set, shift left and adjust exp
    and  r4, r2, r7
    rol  r4, r4              ; T = bit11 of quot
    bt   __fdiv_pack
    ; bit11 clear: shift left 1 to normalize
    clrt
    rol  r2, r2
    subi r3, 1               ; T=borrow; if r3 was 0 underflows (ok, we check below)

__fdiv_pack:
    sub  r0, r0, r3
    bf   __fdiv_zero
    li   r4, 2047
    sub  r0, r3, r4
    bf   __fdiv_inf

    and  r1, r6, r7
    lwr  r1, r1              ; *dst
    li   r4, 0o3777
    and  r3, r3, r4
    and  r4, r6, r7
    addi r4, 8
    lwr  r4, r4              ; rsign
    sub  r0, r0, r4
    bf   __fdiv_pack_nosign
    li   r4, 0o4000
    add  r3, r3, r4
__fdiv_pack_nosign:
    swr  r3, r1
    addi r1, 1
    swr  r2, r1
    addi r1, 1
    and  r4, r0, r0
    swr  r4, r1
    addi r1, 1
    swr  r4, r1
    addi r6, 13
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5

__fdiv_zero:
    and  r1, r6, r7
    lwr  r2, r1
    and  r1, r0, r0
    swr  r1, r2
    addi r2, 1
    swr  r1, r2
    addi r2, 1
    swr  r1, r2
    addi r2, 1
    swr  r1, r2
    addi r6, 13
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5

__fdiv_inf:
    and  r1, r6, r7
    lwr  r2, r1
    and  r1, r6, r7
    addi r1, 8
    lwr  r3, r1
    li   r4, 2047
    sub  r0, r0, r3
    bf   __fdiv_inf_pos
    li   r1, 0o4000
    add  r4, r4, r1
__fdiv_inf_pos:
    swr  r4, r2
    addi r2, 1
    and  r1, r0, r0
    swr  r1, r2
    addi r2, 1
    swr  r1, r2
    addi r2, 1
    swr  r1, r2
    addi r6, 13
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5
