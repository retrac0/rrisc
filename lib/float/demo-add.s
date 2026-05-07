; demo-add.s -- soft-float add with raw word dump (hex per 12-bit cell)
;
; Float48 layout matches float48.py: four big-endian 12-bit words (w0..w3).
; Routines (r5=link, r6=stack descending):
;   __itof(r2=*dst, r3=int)
;   __fadd(r2=*dst, r3=*a, r4=*b)
;
; After the add, each cell is printed as 0xNNN via float/put_hex12.s.
;
; Host cross-check:
;   python3 -c "from float48 import from_float; print([hex(x) for x in from_float(7.0)])"
;   expect 0x402 0xe00 0x0 0x0 when __fadd matches the model.
;
;   python3 asm.py -I lib -I examples lib/float/demo-add.s -o /tmp/f.bin
;   python3 sim.py /tmp/f.bin --terminal --start 1000

%include "macros/uart_tx.inc"

        .org 0o0100
fa:     .fill 4, 0
fb:     .fill 4, 0
fsum:   .fill 4, 0

        .org 0o1000
_start:
        li     r6, 0o7770

        li     r2, hdr
        li     r1, putstr
        jalr   r5, r1

        li     r2, fa
        li     r3, 3
        li     r1, __itof
        jalr   r5, r1

        li     r2, fb
        li     r3, 4
        li     r1, __itof
        jalr   r5, r1

        li     r2, fsum
        li     r3, fa
        li     r4, fb
        li     r1, __fadd
        jalr   r5, r1

        li     r2, lbl_w0
        li     r1, putstr
        jalr   r5, r1
        li     r4, fsum
        lwr    r2, r4
        li     r1, put_hex12
        jalr   r5, r1
        li     r2, spc
        li     r1, putstr
        jalr   r5, r1

        li     r2, lbl_w1
        li     r1, putstr
        jalr   r5, r1
        li     r4, fsum
        addi   r4, 1
        lwr    r2, r4
        li     r1, put_hex12
        jalr   r5, r1
        li     r2, spc
        li     r1, putstr
        jalr   r5, r1

        li     r2, lbl_w2
        li     r1, putstr
        jalr   r5, r1
        li     r4, fsum
        addi   r4, 2
        lwr    r2, r4
        li     r1, put_hex12
        jalr   r5, r1
        li     r2, spc
        li     r1, putstr
        jalr   r5, r1

        li     r2, lbl_w3
        li     r1, putstr
        jalr   r5, r1
        li     r4, fsum
        addi   r4, 3
        lwr    r2, r4
        li     r1, put_hex12
        jalr   r5, r1

        li     r2, nl
        li     r1, putstr
        jalr   r5, r1

        li     r2, golden
        li     r1, putstr
        jalr   r5, r1

        halt

hdr:    .unicode "3f + 4f -> fsum cells: "
        .word 0
lbl_w0: .unicode "w0="
        .word 0
lbl_w1: .unicode "w1="
        .word 0
lbl_w2: .unicode "w2="
        .word 0
lbl_w3: .unicode "w3="
        .word 0
spc:    .unicode "  "
        .word 0
nl:     .unicode "\n"
        .word 0
golden: .unicode "golden from_float seven: 0x402 0xe00 0x0 0x0\n"
        .word 0

%include "io/putchar.s"
%include "io/putstr.s"
%include "float/put_hex12.s"
%include "float/__itof.s"
%include "float/__fadd.s"
