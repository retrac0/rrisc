; hello.s -- Hello, world! for RRISC
;
; Sends "Hello, world!\n" to the UART, one ASCII byte at a time.
; Demonstrates subroutine calls via jalr and I/O-page addressing via r7.
;
; Assemble and run:
;   python asm.py examples/hello.s
;   python sim.py examples/hello.bin --terminal --start 1000
;
; Register usage (main):
;   r2  string pointer
;   r3  current character -- passed to putchar
;   r6  return address (input to putstr)
;
%define TXRDY  0o7770           ; TX ready flag  (read)
%define TXBUF  0o7772           ; TX data buffer (write)

        .org 01000

        li   r2, msg            ; r2 = pointer to first character
        li   r5, putstr         ; r5 = putstr address
        jalr r6, r5             ; call putstr(r2)
        halt

; putstr -- print a NUL-terminated string using putchar.
;
;   r2  string pointer
;   r3  current character -- passed to putchar
;   r6  return address (input)
;
putstr:
next:   lwr  r3, r2            ; r3 = mem[r2]  (current character)
        sub  r0, r0, r3         ; T=1 if non-NUL, T=0 if NUL
        bf   putstr_done        ; end of string
poll:   li   r1, TXRDY          ; r1 = TXRDY address
        lwr  r1, r1             ; r1 = TX ready flag  (1=ready, 0=busy)
        sub  r0, r0, r1         ; T=1 if ready, T=0 if busy
        bf   poll               ; busy -- keep polling
        li   r1, TXBUF          ; r1 = TXBUF address
        swr  r3, r1             ; transmit character from r3
        addi r2, 1              ; advance string pointer
        bt   next               ; T=1 (putchar exits with T set) -- loop
putstr_done:   
        jalr r0, r6       ; return to caller
        halt

msg:    .unicode "Hello, world!\n"
        .word 0                 ; NUL terminator
