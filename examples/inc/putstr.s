; putstr.s -- print NUL-terminated string of words (rcc ABI)
;
; Entry:  r2 = pointer to first word of string
;         r5 = return address
; Uses stack (push r5 / push r2) across putchar calls.
;
; Include inc/uart_tx.inc before this file.

putstr:
        subi r6, 1
        swr  r5, r6
putstr_next:
        lwr  r1, r2
        sub  r0, r0, r1
        bf   putstr_done
        subi r6, 1
        swr  r2, r6
        and  r2, r1, r7
        li   r1, putchar
        jalr r5, r1
        lwr  r2, r6
        addi r6, 1
        addi r2, 1
        sub  r0, r0, r7
        bt   putstr_next
putstr_done:
        lwr  r5, r6
        addi r6, 1
        jalr r0, r5
