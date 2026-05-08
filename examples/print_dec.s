; print_dec.s -- exercise lib/itoa.s on signed 12-bit integers.
;
; Calls itoa(n, buf) for a small set of values (including the -2048 corner
; case) and prints the result through putstr. Showcases an asm-only caller
; for a routine the C compiler also emits inline.

%include "macros/uart_tx.inc"

        .org 0o0100
buf:    .fill 8, 0
nl:     .word 10, 0

        .org 0o1000
_start:
        li     r6, 0o7770

        ; print 0
        li     r2, 0
        li     r1, print_int
        jalr   r5, r1
        ; print 7
        li     r2, 7
        li     r1, print_int
        jalr   r5, r1
        ; print -1
        li     r2, 0o7777          ; -1 in 12-bit two's complement
        li     r1, print_int
        jalr   r5, r1
        ; print 2047 (largest positive)
        li     r2, 2047
        li     r1, print_int
        jalr   r5, r1
        ; print -2048 (most-negative; itoa special-cases this)
        li     r2, 0o4000          ; -2048
        li     r1, print_int
        jalr   r5, r1

        halt

; print_int(r2 = signed 12-bit n) -- itoa into buf, putstr it, then newline.
print_int:
        subi   r6, 1
        swr    r5, r6
        li     r3, buf
        li     r1, itoa
        jalr   r5, r1
        li     r2, buf
        li     r1, putstr
        jalr   r5, r1
        li     r2, nl
        li     r1, putstr
        jalr   r5, r1
        lwr    r5, r6
        addi   r6, 1
        jalr   r0, r5

%include "io/putchar.s"
%include "io/putstr.s"
%include "itoa.s"
