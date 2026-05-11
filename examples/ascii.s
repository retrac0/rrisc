; ascii.s -- Print printable ASCII via UART (rcc calling convention)
;
; Assemble and run:
;   env PYTHONPATH=. python3 -m pytools.asm examples/ascii.s
;   env PYTHONPATH=. python3 -m pytools.sim examples/ascii.bin --terminal --start 1000
;
%include "macros/uart_tx.inc"
        .org 0o1000

        li   r6, 0o0100
        li   r2, 0x20
        li   r3, 0x7F

next:   sub  r0, r2, r3
        bf   done
        li   r1, putchar
        jalr r5, r1
        addi r2, 1
        sub  r0, r0, r7
        bt   next

done:   li   r2, 10
        li   r1, putchar
        jalr r5, r1
        halt

%include "io/putchar.s"
