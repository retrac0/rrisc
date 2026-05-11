; 0400-expr.s -- exercise the expression parser with ~20 deeply nested expressions
;
; All expressions are assembled as .word values; the code loads five
; representative results into registers so the runtime check validates
; that expression evaluation produces the correct bit patterns.
;
; Expression comments show the expected decimal value (pre mod-4096).

        .org 0o1000

        li   r1, data
        lwr r2, r1         ; data[0]:  1+2 = 3
        addi r1, 5
        lwr r3, r1         ; data[5]:  ~0  = 0o7777
        addi r1, 5
        lwr r4, r1         ; data[10]: 2+3*4 = 14  (precedence: * before +)
        addi r1, 5
        lwr r5, r1         ; data[15]: ~~0 = 0
        addi r1, 4
        lwr r6, r1         ; data[19]: multi-op combination = 2606
        halt

data:
        .word 1+2                               ; [0]  = 3
        .word (((1+2)*3)+4)*2                   ; [1]  = 26
        .word 0xFF & 0x0F                       ; [2]  = 15
        .word 1<<6 | 1<<3 | 1                   ; [3]  = 73
        .word 0xFFF ^ 0x0F0                     ; [4]  = 0xF0F = 3855
        .word ~0                                ; [5]  = 0o7777
        .word -1                                ; [6]  = 0o7777
        .word 0o7777+1                          ; [7]  = 0  (wraps mod 4096)
        .word ((2+3)*(4-1))%7                   ; [8]  = 1
        .word (0xFF<<4) & 0xFFF                 ; [9]  = 0xFF0 = 4080
        .word 2+3*4                             ; [10] = 14
        .word ((1<<11)>>3) & 0xFF               ; [11] = 256 & 255 = 0
        .word 10 - -5                           ; [12] = 15
        .word 0xF0F ^ 0x0F0 ^ 0x001            ; [13] = 0xFFE = 4094
        .word data+3                            ; [14] = 0o1017  (label arithmetic)
        .word ~~0                               ; [15] = 0
        .word (1|2)&3                           ; [16] = 3
        .word 1000%13                           ; [17] = 12
        .word (((((1+1)*2)*2)*2)*2)             ; [18] = 32
        .word (0xABC & 0xF0F) | ((3*7)<<1)     ; [19] = 2606
