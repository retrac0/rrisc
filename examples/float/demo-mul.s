; demo-mul.s -- soft-float multiplication, exact-representable inputs.
;
; Multiplies 1.5 * 1.5 = 2.25 (all three are exactly representable in float48).
; Prints the result as hex cells and as a decimal string.
;
; Golden words:
;   python3 -c "from float48 import format_words, from_float; print(format_words(from_float(2.25)))"
;   ->  1001 4400 0000 0000   (= 0x401 0x900 0x000 0x000)
;
; __fmul has documented sig_hi/sig_mid precision (~24 bits): for 1.5 the
; product 0x900 << 12 fits exactly in sig_hi:sig_mid so the result is exact.
;
; Build & run:
;   python3 asm.py -I lib examples/float/demo-mul.s -o /tmp/f.bin
;   python3 sim.py /tmp/f.bin --terminal --start 0o1000

%include "macros/uart_tx.inc"

        .org 0o0100
src_a:  .word 49, 46, 53, 0          ; "1.5"
src_b:  .word 49, 46, 53, 0          ; "1.5"
fa:     .fill 4, 0
fb:     .fill 4, 0
fr:     .fill 4, 0
buf:    .fill 16, 0

        .org 0o1000
_start:
        li     r6, 0o7770

        ; fa = atof("1.5"),  fb = atof("1.5")
        li     r2, src_a
        li     r3, fa
        li     r1, __atof
        jalr   r5, r1
        li     r2, src_b
        li     r3, fb
        li     r1, __atof
        jalr   r5, r1

        ; fr = fa * fb
        li     r2, fr
        li     r3, fa
        li     r4, fb
        li     r1, __fmul
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

hdr:    .unicode "1.5 * 1.5 = "
        .word 0
nl:     .unicode "\n"
        .word 0

%include "io/putchar.s"
%include "io/putstr.s"
%include "float/put_hex12.s"
%include "float/rrisc_float_bundle.s"
