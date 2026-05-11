; 0500-hello.s -- Hello World via the UART terminal
;
; Polls TX RDY before writing each character, then halts.
; Run standalone: python sim.py tests/0500-hello.bin --terminal
;
; Register usage:
;   r1  pointer into string (advances each iteration)
;   r2  current SIXBIT character
;   r3  TX ready status
;   r5  TX RDY address (0o7770)
;   r6  TX BUF address (0o7772)

%define TXRDY  0o7770
%define TXBUF  0o7772

        .org 0o1000

        li   r5, TXRDY          ; r5 = TX ready address
        li   r6, TXBUF          ; r6 = TX buffer address
        li   r1, msg            ; r1 = pointer to start of string

loop:   lwr  r2, r1             ; load next SIXBIT character
        sub  r0, r0, r2         ; T=1 if r2!=0, T=0 if r2=0 (NUL terminator)
        bf   done               ; NUL -> done

txwait: lwr  r3, r5             ; read TX ready status
        sub  r0, r0, r3         ; T=1 if ready, T=0 if busy
        bf   txwait             ; busy -> keep polling

        swr  r2, r6             ; transmit character
        addi r1, 1              ; advance string pointer
        bt   loop               ; T=1 (from sub r0,r0,r3) -> next character

done:   halt

msg:    .sixbit "HELLO WORLD\n"
        .word 0                 ; NUL terminator
