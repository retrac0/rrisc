; __fdiv(r2=*dst, r3=*a, r4=*b) -- dst = a / b  (float48)
;
; Precision: this routine works on `sig_hi` (top 12 bits of the 36-bit
; significand) only. That gives ~12 bits of mantissa precision in the
; result -- the low two words of the result are always written zero.
; Mantissa-level rounding errors of up to ~1 ulp at sig_hi are expected.
;
; Algorithm: 23-step long division producing q = floor((a_hi << 11) / b_hi).
; Each iter shifts the next dividend bit (MSB-first from a_hi, then zeros)
; into a 13-bit running remainder via T, compares with b_hi, conditionally
; subtracts and sets a quotient bit. After 23 iters q is in [2^10, 2^12).
;
; The trick: a single `rol rem, rem` with T_in = (the next dividend bit)
; gives us exactly `rem = (rem<<1) | bit_in`, and T_out = old bit 11 of rem
; = bit 12 of the new rem. We thus carry the overflow bit through T to a
; second-stage compare without losing the dividend bit.
;
; Specials: a is zero -> result 0; b is zero -> result inf; a inf -> inf;
; b inf -> 0 (simplified, no NaN).
;
; Stack frame (9 words + saved r5):
;   sp+0 *dst    sp+1 sign_a  sp+2 exp_a   sp+3 a_hi
;   sp+4 sign_b  sp+5 exp_b   sp+6 b_hi    sp+7 rsign  sp+8 count

%define FD_DST    0
%define FD_SIGN_A 1
%define FD_EXP_A  2
%define FD_A_HI   3
%define FD_SIGN_B 4
%define FD_EXP_B  5
%define FD_B_HI   6
%define FD_RSIGN  7
%define FD_COUNT  8

; r1 is used as the FD_* address scratch. Do NOT pass r1 as the value reg.
%macro FD_LD 2
    and  r1, r6, r7
    addi r1, %2
    lwr  %1, r1
%endm

%macro FD_ST 2          ; FD_ST reg, offset    -- reg must NOT be r1
    and  r1, r6, r7
    addi r1, %2
    swr  %1, r1
%endm

__fdiv:
    subi r6, 1
    swr  r5, r6
    subi r6, 9

    FD_ST r2, FD_DST

    ; ---- unpack a (r3 = *a) ----
    lwr  r1, r3
    clrt
    rol  r1, r1                ; T = bit 11 of a.w0
    and  r2, r0, r0
    addc r2, r0, r0            ; r2 = sign_a
    FD_ST r2, FD_SIGN_A
    lwr  r1, r3
    li   r2, 0o3777
    and  r2, r1, r2            ; exp_a
    FD_ST r2, FD_EXP_A
    addi r3, 1
    lwr  r2, r3
    FD_ST r2, FD_A_HI

    ; ---- unpack b (r4 = *b) ----
    lwr  r1, r4
    clrt
    rol  r1, r1
    and  r2, r0, r0
    addc r2, r0, r0
    FD_ST r2, FD_SIGN_B
    lwr  r1, r4
    li   r2, 0o3777
    and  r2, r1, r2
    FD_ST r2, FD_EXP_B
    addi r4, 1
    lwr  r2, r4
    FD_ST r2, FD_B_HI

    ; ---- result sign = sign_a XOR sign_b ----
    FD_LD r2, FD_SIGN_A
    FD_LD r3, FD_SIGN_B
    add  r4, r2, r3
    clrt
    ror  r4, r4                ; T = bit 0 of (sign_a + sign_b) = XOR
    and  r4, r0, r0
    addc r4, r0, r0
    FD_ST r4, FD_RSIGN

    ; ---- specials ----
    FD_LD r2, FD_EXP_A
    FD_LD r3, FD_EXP_B
    sub  r0, r0, r3
    bf   __fdiv_inf            ; b == 0 -> inf
    sub  r0, r0, r2
    bf   __fdiv_zero           ; a == 0 -> 0
    li   r4, 2047
    sub  r0, r2, r4
    bf   __fdiv_inf            ; a == inf -> inf
    sub  r0, r3, r4
    bf   __fdiv_zero           ; b == inf -> 0

    ; ---- division: q = floor((a_hi << 11) / b_hi)  using 23 iters ----
    ; r3 holds b_hi for the duration of the loop.
    ; r5 holds num (initially a_hi). We rol it left once per iter; after
    ; 12 rotations num is back to a_hi, but bit 11 is already 0 since we
    ; rotated zeros into bit 0; this naturally feeds zeros for iters 13..23.
    FD_LD r3, FD_B_HI
    FD_LD r5, FD_A_HI
    and  r4, r0, r0            ; r4 = q (12-bit)
    and  r2, r0, r0            ; r2 = rem (12-bit; T flag covers bit 12)
    ; FD_ST clobbers r1, so stage the count in r2 (still zero) and put it back.
    li   r2, 23
    FD_ST r2, FD_COUNT
    and  r2, r0, r0            ; r2 = 0 again (rem)

__fdiv_loop:
    ; Step 1: extract bit 11 of num into T, shift num left zero-filled.
    clrt
    rol  r5, r5                ; T = old bit 11 of num; r5 = (num<<1)|0

    ; Step 2: rem = (rem<<1) | T  AND  T = old bit 11 of rem (= bit 12 of new rem).
    rol  r2, r2

    ; Step 3: capture overflow flag into r1 (clobbers T harmlessly).
    and  r1, r0, r0
    addc r1, r0, r0            ; r1 = 1 iff rem overflowed bit 11

    ; Step 4: compare 13-bit rem with b_hi (12-bit). If overflow, force sub.
    sub  r0, r0, r1            ; T=1 iff r1 != 0
    bt   __fdiv_do_sub
    sub  r0, r2, r3            ; T=1 iff rem < b_hi (borrow)
    bt   __fdiv_skip_sub

__fdiv_do_sub:
    ; rem -= b_hi. Works for both fits-in-12-bit and overflow cases:
    ; if rem was 13-bit (= 2^12 + r2_low), then in 12-bit arithmetic
    ; (r2_low - b_hi) mod 2^12 = (2^12 + r2_low - b_hi) mod 2^12 = the
    ; correct 12-bit truncation since 2^12 + r2_low - b_hi < 2^12.
    sub  r2, r2, r3
    ; q = (q << 1) | 1
    clrt
    rol  r4, r4
    addi r4, 1
    sub  r0, r0, r7            ; T=1
    bt   __fdiv_loop_step

__fdiv_skip_sub:
    ; q = q << 1
    clrt
    rol  r4, r4

__fdiv_loop_step:
    ; FD_LD/FD_ST clobber r1, so we cannot use the macros to bump count
    ; (the value reg would alias the address scratch). Inline the load,
    ; decrement, store, then reload b_hi (clobbered as scratch) before the
    ; conditional branch.
    and  r1, r6, r7
    addi r1, FD_COUNT
    lwr  r3, r1                ; r3 = count
    subi r3, 1
    swr  r3, r1                ; count -= 1
    sub  r0, r0, r3            ; T=1 iff new count != 0
    ; reuse r1 (points at [sp+FD_COUNT]) to reload b_hi at [sp+FD_B_HI]
    subi r1, 2
    lwr  r3, r1                ; r3 = b_hi (lwr preserves T)
    bt   __fdiv_loop

    ; ---- exponent ----
    FD_LD r5, FD_EXP_A
    FD_LD r1, FD_EXP_B
    sub  r5, r5, r1
    li   r1, 1024
    add  r5, r5, r1            ; r5 = exp_a - exp_b + 1024 (exp_r tentative)

    ; q is in [2^10, 2^12). If bit 11 of q is set, q is already normalized.
    ; Otherwise q is in [2^10, 2^11): shift left once and decrement exp.
    and  r1, r4, r7
    clrt
    rol  r1, r1                ; T = bit 11 of q
    bt   __fdiv_pack
    clrt
    rol  r4, r4
    subi r5, 1

__fdiv_pack:
    ; underflow / overflow checks
    sub  r0, r0, r5
    bf   __fdiv_zero           ; exp_r == 0 -> zero (don't bother with subnormals)
    li   r1, 2047
    sub  r0, r5, r1
    bf   __fdiv_inf

    FD_LD r2, FD_DST
    li   r1, 0o3777
    and  r5, r5, r1
    FD_LD r1, FD_RSIGN
    sub  r0, r0, r1
    bf   __fdiv_pack_nosign
    li   r1, 0o4000
    add  r5, r5, r1
__fdiv_pack_nosign:
    swr  r5, r2
    addi r2, 1
    swr  r4, r2
    addi r2, 1
    and  r1, r0, r0
    swr  r1, r2
    addi r2, 1
    swr  r1, r2
    addi r6, 9
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5

__fdiv_zero:
    FD_LD r2, FD_DST
    li   r1, __fstore_zero
    jalr r5, r1
    addi r6, 9
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5

__fdiv_inf:
    FD_LD r2, FD_DST
    FD_LD r3, FD_RSIGN
    li   r1, __fstore_inf
    jalr r5, r1
    addi r6, 9
    lwr  r5, r6
    addi r6, 1
    jalr r0, r5
