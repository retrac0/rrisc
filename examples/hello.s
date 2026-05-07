; hello.s -- Hello, world! for RRISC (rcc calling convention)
;
; Assemble and run:
;   python asm.py examples/hello.s
;   python sim.py examples/hello.bin --terminal --start 1000
;
%include "macros/uart_tx.inc"
        .org 0o1000

        li   r6, 0o0100         ; SP just above RAM (default sim: RAM 0o0000..0o0077)
        li   r2, msg
        li   r1, putstr
        jalr r5, r1
        halt

msg:    .unicode "Hello, world!\n"
        .word 0

%include "io/putchar.s"
%include "io/putstr.s"
