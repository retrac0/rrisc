; luiaddi.asm -- test lui and addi
;
; addi rd, imm  ->  rd = rd + sign_extend(imm6)
; lui  rd, imm  ->  rd = imm6 << 6  (clears lower 6 bits)
;
; Test 1: addi accumulates across multiple instructions
;   r1 = 0 + 7 + 7 + 7 = 21 = 0o025
;
; Test 2: addi sign-extends negative immediates
;   0o77 = 63 = -1 as signed 6-bit (bit 5 set)
;   r2 = 0 + (-1) + (-1) = -2 = 0o7776
;
; Test 3: lui places the immediate in bits 11-6, clears bits 5-0
;   r3 = 0o5200
;
; Test 4: lui + addi, positive lower 6 bits (no compensation needed)
;   r4 = 0o3736
;
; Test 5: lui + addi, negative lower 6 bits (upper must be pre-incremented)
;   Target 0o5265: lower6 = 0o65 = 53, sign_extend = -11
;   lui r5, 0o53 (=upper6+1) then addi r5, 0o65 -> 0o5300 + (-11) = 0o5265
;
; Expected at halt: r1=0025  r2=7776  r3=5200  r4=3736  r5=5265  T=0

        .org 0o1000

        ; Test 1: addi accumulates
        and  r1, r0, r0         ; r1 = 0
        addi r1, 7
        addi r1, 7
        addi r1, 7              ; r1 = 0o025

        ; Test 2: sign-extended negative immediate
        and  r2, r0, r0         ; r2 = 0
        addi r2, 0o77           ; r2 = 0o7777  (-1)
        addi r2, 0o77           ; r2 = 0o7776  (-2)

        ; Test 3: lui basic
        lui  r3, 0o52           ; r3 = 0o5200

        ; Test 4: full constant, positive lower6
        lui  r4, 0o37           ; r4 = 0o3700
        addi r4, 0o36           ; r4 = 0o3736  (lower6=30, positive, no compensation)

        ; Test 5: full constant, negative lower6 (pre-increment upper)
        lui  r5, 0o53           ; r5 = 0o5300  (upper = 0o52 + 1 to offset sign extension)
        addi r5, 0o65           ; r5 = 0o5265  (lower6=53 sign-extends to -11)

        halt
