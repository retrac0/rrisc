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
;   zero-page 0o20..0o24: NUL-terminated ASCII digit buffer (clobbered)
;
; --- putstr calling convention (from hello.s) ---
;   r2  pointer to NUL-terminated word string
;   r6  return address
;   r1, r3, r4, r5, T  clobbered
;
; --- putchar calling convention ---
;   r3  character to send
;   r4  return address
;   r1, T  clobbered; exits with T=1

%define TXRDY  0o70     ; 0o7700|0o70 = 0o7770: TX ready flag (read)
%define TXBUF  0o72     ; 0o7700|0o72 = 0o7772: TX data buffer (write)

; ror3 reg -- rotate reg right by 3 (destructive: upper bits become garbage).
; Each ror updates T; clrt before addc (ASCII conversion) clears that carry-in.
%macro ror3 reg
        ror  reg, reg
        ror  reg, reg
        ror  reg, reg
%endm

%macro jal d, r, l

        li r, l 
        jalr d, r
%endm        

        .octal 

; --- octoa ---
; Builds a NUL-terminated ASCII string in memory

.org 10

pbuf:  .fill 4, 0
       .word 0
        
        .org 1000

main:
        li   r2, 1357
        jal  r6, r1, print_oct
        li   r3, 10             ; '\n'
        jal  r4, r5, putchar
        halt

;
; Digits are extracted LSB-first but stored in descending address order
; (digit 0 at 0o23, digit 3 at 0o20) so putstr scanning upward from 0o20
; prints the MSB digit first.  ASCII conversion (add '0') happens at store
; time using r3 = 0o060 loaded once up front.
print_oct:
        li   r3, 60          ; r3 = '0' = 48
        li   r4, 07          ; r4 = 3-bit mask

        sub  r0, r0, r0         ; clrt (T unknown at entry)
        and  r1, r2, r4         ; digit 0 (LSB, bits 2:0)
        addc r1, r1, r3         ; → ASCII (T=0 from clrt)
        sw   r0, pbuf+3           ; buffer[3]

        ror3 r2

        sub  r0, r0, r0         ; clrt (ror3 leaves T unpredictable)
        and  r1, r2, r4         ; digit 1 (bits 5:3)
        addc r1, r1, r3
        sw   r0, pbuf+2           ; buffer[2]

        ror3 r2

        sub  r0, r0, r0         ; clrt
        and  r1, r2, r4         ; digit 2 (bits 8:6)
        addc r1, r1, r3
        sw   r0, pbuf+1             ; buffer[1]

        ror3 r2

        sub  r0, r0, r0         ; clrt
        and  r1, r2, r4         ; digit 3 (MSB, bits 11:9)
        addc r1, r1, r3
        sw   r0, pbuf           ; buffer[0]

        and  r1, r0, r0         ; r1 = 0
        sw   r0, 24           ; buffer[4] = NUL

        li   r2, pbuf           ; r2 → start of buffer
        jal r0, r5, putstr            ; tail-call putstr; it returns via r6 to our caller


; --- putstr ---
; Print the NUL-terminated string of words starting at r2.
putstr:
        li   r5, putchar
next:   lwr  r3, r2             ; r3 = mem[r2]
        sub  r0, r0, r3         ; T=1 if nonzero, T=0 if NUL
        bf   putstr_done
        jalr r4, r5             ; call putchar(r3); putchar exits with T=1
        addi r2, 1
        bt   next               ; T=1 — always loops back
putstr_done:
        jalr r0, r6

; --- putchar ---
; Poll TXRDY, then transmit r3.  Exits with T=1.
putchar:
        lw   r7, TXRDY          ; r1 = TX ready flag (1=ready, 0=busy)
        sub  r0, r0, r1         ; T=1 if ready
        bf   putchar
        and  r1, r3, r7         ; r1 = r3  (move character)
        sw   r7, TXBUF
        jalr r0, r4
