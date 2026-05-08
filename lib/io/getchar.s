; getchar.s -- UART receive one character (rcc ABI)
;
; Entry:  r5 = return address
; Exit:   r2 = received character (low 8 bits in 12-bit reg)
; Clobbers: r1 (scratch).  T may be 1 on return (last poll saw ready).
;
; Spins until RXRDY = 1, then reads RXBUF. Pair with putchar for echo loops.
;
; Include macros/uart_rx.inc before this file (defines RXRDY / RXBUF).

getchar:
        li   r1, RXRDY
        lwr  r1, r1
        sub  r0, r0, r1
        bf   getchar
        li   r1, RXBUF
        lwr  r2, r1
        jalr r0, r5
