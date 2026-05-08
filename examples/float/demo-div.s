; demo-div.s -- soft-float division, exact-representable result.
;
; Divides 12.0 / 4.0 = 3.0 (all exact in float48). Showcases that the
; sig_hi-only __fdiv is precise when the quotient is itself representable
; in 12 bits of mantissa: q = floor((a_hi << 11) / b_hi), low cells zero.
;
; Golden words:
;   python3 -c "from float48 import format_words, from_float; print(format_words(from_float(3.0)))"
;   ->  1001 6000 0000 0000   (= 0x401 0xc00 0x000 0x000)
;
; Build & run:
;   python3 asm.py -I lib examples/float/demo-div.s -o /tmp/f.bin
;   python3 sim.py /tmp/f.bin --terminal --start 0o1000

%include "macros/uart_tx.inc"

        .org 0o0100
fa:     .fill 4, 0
fb:     .fill 4, 0
fr:     .fill 4, 0
buf:    .fill 16, 0

        .org 0o1000
_start:
        li     r6, 0o7770

        li     r2, fa
        li     r3, 12
        li     r1, __itof
        jalr   r5, r1
        li     r2, fb
        li     r3, 4
        li     r1, __itof
        jalr   r5, r1

        li     r2, fr
        li     r3, fa
        li     r4, fb
        li     r1, __fdiv
        jalr   r5, r1

        li     r2, hdr
        li     r1, putstr
        jalr   r5, r1
        li     r2, fr
        li     r3, buf
        li     r1, __ftoa
        jalr   r5, r1
        li     r2, buf
        li     r1, putstr
        jalr   r5, r1
        li     r2, nl
        li     r1, putstr
        jalr   r5, r1
        halt

hdr:    .unicode "12.0 / 4.0 = "
        .word 0
nl:     .unicode "\n"
        .word 0

%include "io/putchar.s"
%include "io/putstr.s"
%include "float/put_hex12.s"
%include "float/rrisc_float_bundle.s"
