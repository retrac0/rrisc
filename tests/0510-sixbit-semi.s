; 0510-sixbit-semi.s -- verify semicolon inside .sixbit string is not treated as comment
;
; Prints "A;B\n" to the UART terminal.
; Without the _strip_comment fix, the semicolon in .sixbit "A;B\n" would be
; stripped as a comment, producing "A" only.

%define TXRDY  0o7770
%define TXBUF  0o7772

        .org 0o1000

        li   r5, TXRDY
        li   r6, TXBUF
        li   r1, msg

loop:   lwr  r2, r1
        sub  r0, r0, r2         ; T=0 if NUL
        bf   done

txwait: lwr  r3, r5
        sub  r0, r0, r3
        bf   txwait

        swr  r2, r6
        addi r1, 1
        bt   loop

done:   halt

msg:    .sixbit "A;B\n"
        .word 0
