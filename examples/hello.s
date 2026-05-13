; hello.s -- Hello, world! for RRISC (rcc calling convention)
;
; Assemble and run:
;   env PYTHONPATH=. python3 -m pytools.asm examples/hello.s
;   env PYTHONPATH=. python3 -m pytools.rrsim examples/hello.bin --terminal --start 1000
;
%include "macros/uart_tx.inc"
        .org 0o1000

        li   r6, 0o0100         ; SP just above RAM (default sim: RAM 0o0000..0o0077)
        li   r2, msg
        li   r1, putstr
        jalr r5, r1
        halt

msg:    .strz "Hello, world!\n"

%include "io/putchar.s"
%include "io/putstr.s"
