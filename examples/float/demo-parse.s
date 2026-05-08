; demo-parse.s -- decimal ASCII -> float48 -> decimal ASCII round-trip.
;
; Parses "12.5" with __atof, prints the four 12-bit cells in hex, and
; round-trips back to a decimal string with __ftoa.
;
; Golden words:
;   python3 -c "from float48 import format_words, from_float; print(format_words(from_float(12.5)))"
;   ->  2003 6200 0000 0000   (= 0x403 0xc80 0x000 0x000)
;
; Build & run:
;   python3 asm.py -I lib examples/float/demo-parse.s -o /tmp/f.bin
;   python3 sim.py /tmp/f.bin --terminal --start 0o1000

%include "macros/uart_tx.inc"

        .org 0o0100
src:    .word 49, 50, 46, 53, 0          ; "12.5"
fr:     .fill 4, 0
buf:    .fill 16, 0

        .org 0o1000
_start:
        li     r6, 0o7770

        ; fr = atof("12.5")
        li     r2, src
        li     r3, fr
        li     r1, __atof
        jalr   r5, r1

        ; print cells (hex)
        li     r2, hdr_hex
        li     r1, putstr
        jalr   r5, r1
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

        ; round-trip back to decimal
        li     r2, hdr_dec
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

hdr_hex: .unicode "atof 12.5 cells   = "
         .word 0
hdr_dec: .unicode "atof 12.5 decimal = "
         .word 0
spc:    .unicode " "
        .word 0
nl:     .unicode "\n"
        .word 0

%include "io/putchar.s"
%include "io/putstr.s"
%include "itoa.s"
%include "float/put_hex12.s"
%include "float/__fcopy.s"
%include "float/__fneg.s"
%include "float/__itof.s"
%include "float/__ftoi.s"
%include "float/__fadd.s"
%include "float/__fsub.s"
%include "float/__fmul.s"
%include "float/__fdiv.s"
%include "float/__atof.s"
%include "float/__ftoa.s"
