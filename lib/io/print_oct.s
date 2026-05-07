; print_oct.s -- print r2 as four octal digits via UART (rcc ABI)
;
; Entry:  r2 = value (clobbered)
;         r5 = return address
; Saves r5 on stack; tail-calls putstr.  Requires pbuf (5 words) defined by caller.
;
%include "macros/ror3.inc"

print_oct:
        subi r6, 1
        swr  r5, r6
        li   r3, 060
        li   r4, 07
        li   r1, pbuf+3

        and  r5, r2, r4
        add  r5, r5, r3
        swr  r5, r1
        subi r1, 1
        ror3 r2

        and  r5, r2, r4
        add  r5, r5, r3
        swr  r5, r1
        subi r1, 1
        ror3 r2

        and  r5, r2, r4
        add  r5, r5, r3
        swr  r5, r1
        subi r1, 1
        ror3 r2

        and  r5, r2, r4
        add  r5, r5, r3
        swr  r5, r1

        and  r5, r0, r0
        li   r1, pbuf+4
        swr  r5, r1

        li   r2, pbuf
        lwr  r5, r6
        addi r6, 1
        li   r1, putstr
        jalr r0, r1
