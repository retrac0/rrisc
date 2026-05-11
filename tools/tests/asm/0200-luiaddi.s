; luiaddi.asm -- test lui and addi (unsigned)
;
; addi rd, imm  ->  rd = rd + imm  (unsigned 0..63, no sign-extension)
; lui  rd, imm  ->  rd = imm6 << 6  (clears lower 6 bits)
;
; Test 1: addi accumulates across multiple instructions
;   r1 = 0 + 7 + 7 + 7 = 21 = 0o025
;
; Test 2: addi adds unsigned (0o77=63, no sign-extension)
;   r2 = 0 + 63 = 63 = 0o077
;
; Test 3: lui places the immediate in bits 11-6, clears bits 5-0
;   r3 = 0o5200
;
; Test 4: lui + addi, positive lower 6 bits
;   r4 = 0o3736
;
; Test 5: lui + addi, no compensation needed (addi is now unsigned)
;   Target 0o5265: upper6 = 0o52, lower6 = 0o65 = 53
;   lui r5, 0o52 then addi r5, 0o65 -> 0o5200 + 53 = 0o5265
;
; Expected at halt: r1=0025  r2=0077  r3=5200  r4=3736  r5=5265  T=0

        .org 0o1000

        ; Test 1: addi accumulates
        and  r1, r0, r0         ; r1 = 0
        addi r1, 7
        addi r1, 7
        addi r1, 7              ; r1 = 0o025

        ; Test 2: unsigned immediate (63 stays 63, not sign-extended to -1)
        and  r2, r0, r0         ; r2 = 0
        addi r2, 63             ; r2 = 63 = 0o077

        ; Test 3: lui basic
        lui  r3, 0o52           ; r3 = 0o5200

        ; Test 4: full constant, lower6 fits in unsigned addi
        lui  r4, 0o37           ; r4 = 0o3700
        addi r4, 0o36           ; r4 = 0o3736

        ; Test 5: full constant, no compensation needed with unsigned addi
        lui  r5, 0o52           ; r5 = 0o5200  (exact upper6, no +1)
        addi r5, 0o65           ; r5 = 0o5265  (lower6=53, unsigned add)

        halt
