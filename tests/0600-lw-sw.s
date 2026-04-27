; 0600-lw-sw.s -- test lw/sw page-addressed instructions (implicit r1)
;
; lw rB, imm6 : r1 = mem[(rB & 0o7700) | imm6]
; sw rB, imm6 : mem[(rB & 0o7700) | imm6] = r1
;
; Uses zero-page scratchpad (0o60, 0o61) well above the code region.
; Also verifies that lower 6 bits of the base register are ignored.
;
; At halt:
;   r2 = 0o1234  lw r0 round-trip
;   r3 = 0o5670  lw r0 round-trip
;   r5 = 0o1234  lw with non-zero low bits in base (same result as r0)

        .org 0o1000

        li   r1, 0o1234
        sw   r0, 0o60       ; mem[0o0060] = 0o1234
        li   r1, 0o5670
        sw   r0, 0o61       ; mem[0o0061] = 0o5670

        lw   r0, 0o60       ; r1 = mem[0o0060] = 0o1234
        and  r2, r1, r7     ; r2 = r1  (move)
        lw   r0, 0o61       ; r1 = mem[0o0061] = 0o5670
        and  r3, r1, r7     ; r3 = r1  (move)

        ; verify lower bits of base are ignored: addi r4,5 -> r4=5
        ; (5 & 0o7700) = 0, so lw r4,0o60 -> mem[0o0060]
        addi r4, 5
        lw   r4, 0o60       ; r1 = mem[0o0060] = 0o1234
        and  r5, r1, r7     ; r5 = r1  (move)

        halt
