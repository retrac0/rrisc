; print_oct.s -- Print a 12-bit word as 4 octal digits via UART.
;
; A 12-bit word is exactly 4 octal digits (3 bits each).  This program
; demonstrates the print_oct subroutine by printing 0o1357, then a newline.
;
; Assemble and run:
;   python asm.py examples/print_oct.s
;   python sim.py examples/print_oct.bin --terminal --start 1000
;
; --- print_oct calling convention ---
;   r2  value to print (clobbered)
;   r6  return address
;   r1, r3, r4, r5, T  clobbered
;   zero-page 0o10..0o14: NUL-terminated ASCII digit buffer (clobbered)
;
; --- putstr calling convention ---
;   r2  pointer to NUL-terminated word string
;   r6  return address
;   r1, r3, r4, r5, T  clobbered
;
; --- putchar calling convention ---
;   r3  character to send
;   r4  return address
;   r1, T  clobbered; exits with T=1

%define TXRDY  0o7770   ; TX ready flag (read)
%define TXBUF  0o7772   ; TX data buffer (write)

; ror3 reg -- rotate reg right by 3 (destructive: upper bits become garbage).
%macro ror3 reg
        ror  reg, reg
        ror  reg, reg
        ror  reg, reg
%endm

%macro jal d, r, l
        li r, l
        jalr d, r
%endm

; digit buffer in zero-page RAM
.org 0o10
pbuf:  .fill 5, 0       ; 4 digits + NUL terminator

        .org 0o1000

main:
        li   r2, 0o1357
        jal  r6, r1, print_oct
        li   r3, 010            ; '\n'
        jal  r4, r5, putchar
        halt

;
; Digits are extracted LSB-first but stored in descending address order
; so putstr scanning upward from pbuf prints MSB digit first.
; Uses r5 as a descending pointer into pbuf.
print_oct:
        li   r3, 060            ; r3 = '0' = 48
        li   r4, 07             ; r4 = 3-bit mask
        li   r5, pbuf+3         ; r5 = pointer to LSB digit slot

        and  r1, r2, r4         ; digit 0 (LSB, bits 2:0)
        add  r1, r1, r3         ; -> ASCII
        swr  r1, r5             ; buffer[3]
        subi r5, 1

        ror3 r2

        and  r1, r2, r4         ; digit 1 (bits 5:3)
        add  r1, r1, r3
        swr  r1, r5             ; buffer[2]
        subi r5, 1

        ror3 r2

        and  r1, r2, r4         ; digit 2 (bits 8:6)
        add  r1, r1, r3
        swr  r1, r5             ; buffer[1]
        subi r5, 1

        ror3 r2

        and  r1, r2, r4         ; digit 3 (MSB, bits 11:9)
        add  r1, r1, r3
        swr  r1, r5             ; buffer[0]

        and  r1, r0, r0         ; r1 = 0 (NUL)
        li   r5, pbuf+4
        swr  r1, r5             ; buffer[4] = NUL

        li   r2, pbuf           ; r2 -> start of buffer
        jal  r0, r5, putstr     ; tail-call putstr; it returns via r6 to our caller

; --- putstr ---
; Print the NUL-terminated string of words starting at r2.
putstr:
        li   r5, putchar
next:   lwr  r3, r2             ; r3 = mem[r2]
        sub  r0, r0, r3         ; T=1 if nonzero, T=0 if NUL
        bf   putstr_done
        jalr r4, r5             ; call putchar(r3); exits with T=1
        addi r2, 1
        bt   next
putstr_done:
        jalr r0, r6

; --- putchar ---
; Poll TXRDY, then transmit r3.  Exits with T=1.
putchar:
        li   r1, TXRDY
        lwr  r1, r1             ; r1 = TX ready flag
        sub  r0, r0, r1         ; T=1 if ready
        bf   putchar
        li   r1, TXBUF
        swr  r3, r1             ; transmit r3
        jalr r0, r4
