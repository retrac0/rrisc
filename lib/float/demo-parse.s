; demo-parse.s -- __atof on a tiny NUL-terminated ASCII string
;
; ABI: __atof(r2=int* string words, r3=float* dst)
;
; Source table `src` holds UTF-8 bytes in the low 8 bits of each word, same as
; rlibc int* strings.  After parsing, each 12-bit cell of *dst is printed as
; 0xNNN (unsigned view) for easy comparison with float48.from_float on the host.
;
; Host cross-check:
;   python3 -c "from float48 import from_float; print([hex(x) for x in from_float(12.5)])"
;   expect 0x403 0xc80 0x0 0x0 when __atof matches the model.
;
;   python3 asm.py -I lib -I examples lib/float/demo-parse.s -o /tmp/f.bin
;   python3 sim.py /tmp/f.bin --terminal --start 1000

%include "macros/uart_tx.inc"

        .org 0o0100
src:    .word 49, 50, 46, 53, 0
fval:   .fill 4, 0

        .org 0o1000
_start:
        li     r6, 0o7770

        li     r2, hdr
        li     r1, putstr
        jalr   r5, r1

        li     r2, src
        li     r3, fval
        li     r1, __atof
        jalr   r5, r1

        li     r2, lbl_w0
        li     r1, putstr
        jalr   r5, r1
        li     r4, fval
        lwr    r2, r4
        li     r1, put_hex12
        jalr   r5, r1
        li     r2, spc
        li     r1, putstr
        jalr   r5, r1

        li     r2, lbl_w1
        li     r1, putstr
        jalr   r5, r1
        li     r4, fval
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
        li     r4, fval
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
        li     r4, fval
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

hdr:    .unicode "parse 12.5 decimal ASCII via __atof -> cells: "
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
golden: .unicode "golden from_float twelve point five: 0x403 0xc80 0x0 0x0\n"
        .word 0

%include "io/putchar.s"
%include "io/putstr.s"
%include "float/put_hex12.s"
%include "float/__fcopy.s"
%include "float/__fneg.s"
%include "float/__fadd.s"
%include "float/__fsub.s"
%include "float/__fmul.s"
%include "float/__fdiv.s"
%include "float/__fcmp.s"
%include "float/__ftoi.s"
%include "float/__itof.s"
%include "float/__atof.s"
