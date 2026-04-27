; 1010-fill-align.s -- test .fill and .align directives
;
; Memory layout (starting at 0o1000):
;   0o1000-0o1006: code (7 words, halt at 0o1006)
;   0o1007:        one zero pad word from .align 4
;   0o1010-0o1012: zeros_block (.fill 3, no value -- defaults to 0)
;   0o1013-0o1016: vals_block  (.fill 2*2, 0o1234 -- expression count)
;
; At halt: T=0 PC=1007 r1=1013 r2=0000 r3=1234 r7=7777

        .org 0o1000

        li   r1, zeros_block    ; r1 = 0o1010
        lwr  r2, r1             ; r2 = 0 (first word of .fill 3)
        li   r1, vals_block     ; r1 = 0o1013
        lwr  r3, r1             ; r3 = 0o1234 (first word of .fill 2*2, 0o1234)
        halt

        .align 4                ; advance 0o1007 -> 0o1010 (1 pad word)
zeros_block:
        .fill 3                 ; 3 zero words (default value = 0)
vals_block:
        .fill 2*2, 0o1234       ; 4 words of 0o1234 (count is an expression)
