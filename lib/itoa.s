; itoa.s -- decimal int to string (matches rlibc.h contract)
;
;   int *itoa(int n, int *buf);
;
; Entry:  r2 = n (12-bit signed), r3 = buf (at least 6 words), r5 = return
; Exit:   r2 = buf, NUL-terminated decimal at *buf.  Clobbers r1, r4.
;
; Special case: n == -2048 emits "-2048" (unary minus has no 12-bit positive twin).
; __ftoa depends on this symbol name — keep it exactly `itoa`.

%define I_N     0
%define I_BUF   1
%define I_P     2
%define I_NEG   3
%define I_START 4
%define I_QUOT  5
%define I_REM   6
%define I_END   7
%define I_TMP   8
%define I_FRAME 12

itoa:
        subi   r6, 1
        swr    r5, r6
        subi   r6, I_FRAME

        and    r1, r6, r7
        addi   r1, I_N
        swr    r2, r1
        and    r1, r6, r7
        addi   r1, I_BUF
        swr    r3, r1

        ; neg = (n < 0) for 12-bit signed: compare via bias trick (same as rcc)
        and    r1, r6, r7
        addi   r1, I_N
        lwr    r3, r1
        and    r2, r0, r0
        li     r1, 0o4000
        add    r3, r3, r1
        add    r2, r2, r1
        sub    r1, r3, r2
        rol    r2, r0
        and    r1, r6, r7
        addi   r1, I_NEG
        swr    r2, r1

        and    r1, r6, r7
        addi   r1, I_NEG
        lwr    r2, r1
        sub    r0, r0, r2
        bf     itoa_not_neg

        ; n < 0: MIN (-2048) ?
        and    r1, r6, r7
        addi   r1, I_N
        lwr    r2, r1
        sub    r3, r0, r2
        and    r1, r6, r7
        addi   r1, I_N
        lwr    r4, r1
        sub    r0, r3, r4
        bf     itoa_min2048

        ; n = -n
        and    r1, r6, r7
        addi   r1, I_N
        lwr    r2, r1
        sub    r2, r0, r2
        and    r1, r6, r7
        addi   r1, I_N
        swr    r2, r1

itoa_not_neg:
        ; p = buf
        and    r1, r6, r7
        addi   r1, I_BUF
        lwr    r2, r1
        and    r1, r6, r7
        addi   r1, I_P
        swr    r2, r1

        ; if (n == 0) *p++ = '0'
        and    r1, r6, r7
        addi   r1, I_N
        lwr    r3, r1
        sub    r0, r0, r3
        bt     itoa_digits

        and    r1, r6, r7
        addi   r1, I_P
        lwr    r4, r1
        li     r1, 48
        swr    r1, r4
        addi   r4, 1
        and    r1, r6, r7
        addi   r1, I_P
        swr    r4, r1
        li     r1, itoa_after_digits
        jalr   r0, r1

itoa_digits:
        ; start = p
        and    r1, r6, r7
        addi   r1, I_P
        lwr    r2, r1
        and    r1, r6, r7
        addi   r1, I_START
        swr    r2, r1

itoa_while_n:
        and    r1, r6, r7
        addi   r1, I_N
        lwr    r2, r1
        sub    r0, r0, r2
        bf     itoa_endwhile_n

        ; rem = n; quot = 0; while rem >= 10: rem -= 10; quot++
        and    r1, r6, r7
        addi   r1, I_N
        lwr    r4, r1
        and    r2, r0, r0
itoa_udiv10:
        li     r1, 10
        sub    r0, r4, r1
        bt     itoa_udiv10_done
        sub    r4, r4, r1
        li     r1, 1
        add    r2, r2, r1
        li     r1, itoa_udiv10
        jalr   r0, r1
itoa_udiv10_done:
        and    r1, r6, r7
        addi   r1, I_QUOT
        swr    r2, r1
        and    r1, r6, r7
        addi   r1, I_REM
        swr    r4, r1

        ; *p++ = '0' + rem
        and    r1, r6, r7
        addi   r1, I_REM
        lwr    r2, r1
        li     r1, 48
        add    r2, r1, r2
        and    r1, r6, r7
        addi   r1, I_P
        lwr    r4, r1
        swr    r2, r4
        addi   r4, 1
        and    r1, r6, r7
        addi   r1, I_P
        swr    r4, r1

        ; n = quot
        and    r1, r6, r7
        addi   r1, I_QUOT
        lwr    r2, r1
        and    r1, r6, r7
        addi   r1, I_N
        swr    r2, r1

        li     r1, itoa_while_n
        jalr   r0, r1

itoa_endwhile_n:
        ; reverse [start, p-1]
        and    r1, r6, r7
        addi   r1, I_P
        lwr    r3, r1
        li     r1, 1
        sub    r3, r3, r1
        and    r1, r6, r7
        addi   r1, I_END
        swr    r3, r1

itoa_rev_loop:
        and    r1, r6, r7
        addi   r1, I_START
        lwr    r2, r1
        and    r1, r6, r7
        addi   r1, I_END
        lwr    r3, r1
        sub    r0, r2, r3
        bf     itoa_rev_done

        lwr    r4, r2
        lwr    r1, r3
        swr    r1, r2
        swr    r4, r3

        li     r1, 1
        add    r2, r2, r1
        li     r1, 1
        sub    r3, r3, r1
        and    r1, r6, r7
        addi   r1, I_START
        swr    r2, r1
        and    r1, r6, r7
        addi   r1, I_END
        swr    r3, r1
        li     r1, itoa_rev_loop
        jalr   r0, r1

itoa_rev_done:

itoa_after_digits:
        ; if (neg) shift right one slot and insert '-'
        and    r1, r6, r7
        addi   r1, I_NEG
        lwr    r2, r1
        sub    r0, r0, r2
        bf     itoa_nul_terminate

        ; len = p - buf
        and    r1, r6, r7
        addi   r1, I_P
        lwr    r2, r1
        and    r1, r6, r7
        addi   r1, I_BUF
        lwr    r3, r1
        sub    r2, r2, r3
        and    r1, r6, r7
        addi   r1, I_TMP
        swr    r2, r1

itoa_neg_shift:
        and    r1, r6, r7
        addi   r1, I_TMP
        lwr    r2, r1
        sub    r0, r0, r2
        bf     itoa_neg_shift_done

        and    r1, r6, r7
        addi   r1, I_BUF
        lwr    r3, r1
        and    r1, r6, r7
        addi   r1, I_TMP
        lwr    r2, r1
        li     r1, 1
        sub    r4, r2, r1
        add    r2, r3, r4
        lwr    r4, r2
        and    r1, r6, r7
        addi   r1, I_TMP
        lwr    r2, r1
        add    r2, r3, r2
        swr    r4, r2

        and    r1, r6, r7
        addi   r1, I_TMP
        lwr    r2, r1
        subi   r2, 1
        swr    r2, r1
        li     r1, itoa_neg_shift
        jalr   r0, r1

itoa_neg_shift_done:
        and    r1, r6, r7
        addi   r1, I_BUF
        lwr    r4, r1
        li     r1, 45
        swr    r1, r4
        and    r1, r6, r7
        addi   r1, I_P
        lwr    r4, r1
        addi   r4, 1
        swr    r4, r1

itoa_nul_terminate:
        and    r1, r6, r7
        addi   r1, I_P
        lwr    r4, r1
        and    r1, r0, r0
        swr    r1, r4

        and    r1, r6, r7
        addi   r1, I_BUF
        lwr    r2, r1
        addi   r6, I_FRAME
        lwr    r5, r6
        addi   r6, 1
        jalr   r0, r5

itoa_min2048:
        and    r1, r6, r7
        addi   r1, I_BUF
        lwr    r4, r1
        li     r1, 45
        swr    r1, r4
        addi   r4, 1
        li     r1, 50
        swr    r1, r4
        addi   r4, 1
        li     r1, 48
        swr    r1, r4
        addi   r4, 1
        li     r1, 52
        swr    r1, r4
        addi   r4, 1
        li     r1, 56
        swr    r1, r4
        addi   r4, 1
        and    r1, r0, r0
        swr    r1, r4
        and    r1, r6, r7
        addi   r1, I_BUF
        lwr    r2, r1
        addi   r6, I_FRAME
        lwr    r5, r6
        addi   r6, 1
        jalr   r0, r5
