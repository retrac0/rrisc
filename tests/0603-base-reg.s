; 0603-base-reg.s -- base directive with user-declared register base
;
; Declares r3 holds 0o0000 (zero page), then uses a full 12-bit label address
; in that page as the lw/sw operand.  The assembler computes the 6-bit offset.
;
; scratch1 and scratch2 are in zero page (0o0062, 0o0063) -- page 0o0000.
;
; At halt:
;   r2 = 0o1234   (round-trip through zero-page scratchpad via label)
;   r5 = 0o5670

        .org 0o0062
scratch1: .word 0
scratch2: .word 0

        .org 0o1000

        .base r3, 0o0000        ; r3 will hold 0 (zero-page base)
        addi r3, 0              ; r3 = 0

        li   r1, 0o1234
        sw   r3, scratch1       ; mem[scratch1=0o0062] = 0o1234, using 12-bit label
        li   r1, 0o5670
        sw   r3, scratch2       ; mem[scratch2=0o0063] = 0o5670

        lw   r3, scratch1       ; r1 = 0o1234
        and  r2, r1, r7         ; r2 = r1  (move)
        lw   r3, scratch2       ; r1 = 0o5670
        and  r5, r1, r7         ; r5 = r1  (move)

        halt
