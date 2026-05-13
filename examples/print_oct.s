; print_oct.s -- Demo: print one octal word and newline (rcc calling convention)
;
; Assemble and run:
;   env PYTHONPATH=. python3 -m pytools.asm examples/print_oct.s
;   env PYTHONPATH=. python3 -m pytools.rrsim examples/print_oct.bin --terminal --start 1000
;
%include "macros/uart_tx.inc"

        .org 0o10
pbuf:   .fill 5, 0

        .org 0o1000

main:   li   r6, 0o0100
        li   r2, 0o1357
        li   r1, print_oct
        jalr r5, r1
        li   r2, 10
        li   r1, putchar
        jalr r5, r1
        halt

%include "io/putchar.s"
%include "io/putstr.s"
%include "io/print_oct.s"
