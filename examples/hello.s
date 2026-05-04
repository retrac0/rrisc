; hello.s -- Hello, world! for RRISC
;
; Sends "Hello, world!\n" to the UART, one ASCII byte at a time.
; Demonstrates subroutine calls via jalr and I/O-page addressing via r7.
;
; r7 is hardwired to 0o7777.  lw/sw use it as a page base:
;   addr = (r7 & 0o7700) | imm6 = 0o7700 | imm6
; So lw/sw r7, 0o7X reaches any register in the I/O page (0o77XX).
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
; I/O-page offsets -- base is r7 & 0o7700 = 0o7700
%define TXRDY  07770            ; TX ready flag  (read)
%define TXBUF  07772            ; TX data buffer (write)

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
poll:   lw   r7, TXRDY          ; r1 = TX ready flag  (1=ready, 0=busy)
        sub  r0, r0, r1         ; T=1 if ready, T=0 if busy
        bf   poll               ; busy -- keep polling
        and  r1, r3, r7         ; r1 = r3  (move character)
        sw   r7, TXBUF          ; mem[7772] = r1 -- transmit
        addi r2, 1              ; advance string pointer
        bt   next               ; T=1 (putchar exits with T set) -- loop
putstr_done:   
        jalr r0, r6       ; return to caller
        halt

msg:    .unicode "Hello, world!\n"
        .word 0                 ; NUL terminator
