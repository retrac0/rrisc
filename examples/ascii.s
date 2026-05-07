; ascii.s -- Print printable ASCII characters via UART
;
; Sends ASCII bytes 0x20 through 0x7E to the UART, one byte at a time.
; Terminates when the generator reaches 0x7F, then halts.
;
; Assemble and run:
;   python asm.py examples/ascii.s
;   python sim.py examples/ascii.bin --terminal --start 1000
;
; Register usage (main):
;   r2  current ASCII character
;   r3  current character -- passed to putchar
;   r4  terminal limit (0x7F)
;   r5  putchar address
;   r6  return address for jalr calls
;
; Register usage (putchar):
;   r1  clobbered by lw/sw (implicit data register)
;   r3  character to send (input)
;   r6  return address (input)

%define TXRDY  0o7770           ; TX ready flag  (read)
%define TXBUF  0o7772           ; TX data buffer (write)

        .org 0o1000

        li   r2, 0x20           ; r2 = current ASCII character
        li   r4, 0x7F           ; r4 = terminal limit (stop before 0x7F)
        li   r5, putchar        ; r5 = putchar address

next:   add  r3, r2, r0         ; r3 = r2  (current character)
        sub  r0, r2, r4         ; T=1 if r2 < 0x7F, T=0 otherwise
        bf   done               ; stop once r2 reaches 0x7F
        jalr r6, r5             ; call putchar(r3)
        addi r2, 1              ; advance string pointer
        bt   next               ; T=1 (putchar exits with T set) -- loop
done:   li   r3, 10             ; print a new line
        jalr r6, r5
   halt

; putchar -- poll TXRDY, then send the character in r3 to the UART.
;   Exits with T=1 (a side effect of the TXRDY ready-check).
;   Clobbers: r1.
;
putchar:
        li   r1, TXRDY          ; r1 = TXRDY address
        lwr  r1, r1             ; r1 = TX ready flag  (1=ready, 0=busy)
        sub  r0, r0, r1         ; T=1 if ready, T=0 if busy
        bf   putchar            ; busy -- keep polling
        li   r1, TXBUF          ; r1 = TXBUF address
        swr  r3, r1             ; transmit character from r3
        jalr r0, r6             ; return
