; 0300-literals.s -- test .word (multi-value) and .float directives
;
; Data section (starting at label 'data', address 012):
;   .word 01234, 05670, 052    -> 3 integer words (C-style octal)
;   .float 1.0, -2.5           -> 8 words (4 per float)
;
; The code loads selected words into registers and halts; the expected
; register state at halt verifies the assembled bit patterns.
;
; At halt: T=0 r1=1014 r2=1234 r3=5670 r4=052 r5=2000 r6=6001

        .org 01000

        li   r1, data       ; r1 = address of data (1014)
        lwr r2, r1         ; r2 = 1234  (first  .word value)
        addi r1, 1
        lwr r3, r1         ; r3 = 5670  (second .word value)
        addi r1, 1
        lwr r4, r1         ; r4 = 052   (third  .word value, 42 decimal)
        addi r1, 1
        lwr r5, r1         ; r5 = 2000  (word 0 of 1.0 float)
        addi r1, 4
        lwr r6, r1         ; r6 = 6001  (word 0 of -2.5 float)
        halt

data:   .word 01234, 05670, 052
        .float 1.0, -2.5
