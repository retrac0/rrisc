; demo-add.s -- soft-float addition with hex-cell and decimal-string output.
;
; Adds 3.0 + 4.0 in float48 format and prints the result twice:
;   1. Raw 12-bit cells via float/put_hex12.s   (round-trip with pytools/float48.py)
;   2. Human-readable decimal via float/__ftoa.s
;
; Golden words (cross-check on the host):
;   python3 -c "from pytools.float48 import format_words, from_float; print(format_words(from_float(7.0)))"
;   ->  1002 7000 0000 0000   (= 0x402 0xe00 0x000 0x000)
;
; Build & run:
;   env PYTHONPATH=. python3 -m pytools.asm -I lib examples/float/demo-add.s -o /tmp/f.bin
;   env PYTHONPATH=. python3 -m pytools.rrsim /tmp/f.bin --terminal --start 0o1000

%include "macros/uart_tx.inc"

        .org 0o0100
fa:     .fill 4, 0
fb:     .fill 4, 0
fr:     .fill 4, 0
buf:    .fill 16, 0

        .org 0o1000
_start:
        li     r6, 0o7770

        ; fa = itof(3),  fb = itof(4)
        li     r2, fa
        li     r3, 3
        li     r1, __itof
        jalr   r5, r1
        li     r2, fb
        li     r3, 4
        li     r1, __itof
        jalr   r5, r1

        ; fr = fa + fb
        li     r2, fr
        li     r3, fa
        li     r4, fb
        li     r1, __fadd
        jalr   r5, r1

        ; banner
        li     r2, hdr
        li     r1, putstr
        jalr   r5, r1

        ; print fr cells as hex
        li     r4, fr
        lwr    r2, r4
        li     r1, put_hex12
        jalr   r5, r1
        li     r2, spc
        li     r1, putstr
        jalr   r5, r1
        li     r4, fr
        addi   r4, 1
        lwr    r2, r4
        li     r1, put_hex12
        jalr   r5, r1
        li     r2, spc
        li     r1, putstr
        jalr   r5, r1
        li     r4, fr
        addi   r4, 2
        lwr    r2, r4
        li     r1, put_hex12
        jalr   r5, r1
        li     r2, spc
        li     r1, putstr
        jalr   r5, r1
        li     r4, fr
        addi   r4, 3
        lwr    r2, r4
        li     r1, put_hex12
        jalr   r5, r1

        li     r2, nl
        li     r1, putstr
        jalr   r5, r1

        ; print fr as decimal string
        li     r2, dec_lbl
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

hdr:    .strz "3.0 + 4.0 cells = "
dec_lbl: .strz "3.0 + 4.0 decimal = "
spc:    .strz " "
nl:     .strz "\n"

%include "io/putchar.s"
%include "io/putstr.s"
%include "float/put_hex12.s"
%include "float/rrisc_float_bundle.s"
