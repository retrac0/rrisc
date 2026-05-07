; putchar.s -- UART transmit one character (rcc ABI)
;
; Entry:  r2 = character (12-bit; low byte used for ASCII)
;         r5 = return address
; Clobbers: r1 (scratch).  T may be 1 on return (last poll saw ready).
;
; Include macros/uart_tx.inc before this file (defines TXRDY / TXBUF).

putchar:
        li   r1, TXRDY
        lwr  r1, r1
        sub  r0, r0, r1
        bf   putchar
        li   r1, TXBUF
        swr  r2, r1
        jalr r0, r5
