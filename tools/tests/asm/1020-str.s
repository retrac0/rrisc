; 1020-str.s -- test .str directive
;
; .str stores UTF-8 bytes one per word.  This test encodes "Hi€":
;   'H'  = 0x48         = 0o110
;   'i'  = 0x69         = 0o151
;   '€'  = U+20AC -> UTF-8 0xE2 0x82 0xAC = 0o342, 0o202, 0o254
;
; The code loads each byte into a register and halts; register values
; verify both single-byte ASCII and multi-byte UTF-8 encoding.
;
; At halt: r1=1020 r2=0110 r3=0151 r4=0342 r5=0202 r6=0254

        .org 0o1000

        li   r1, msg
        lwr  r2, r1             ; r2 = 'H'  (0o110)
        addi r1, 1
        lwr  r3, r1             ; r3 = 'i'  (0o151)
        addi r1, 1
        lwr  r4, r1             ; r4 = 0xE2 (0o342, first byte of €)
        addi r1, 1
        lwr  r5, r1             ; r5 = 0x82 (0o202, second byte of €)
        addi r1, 1
        lwr  r6, r1             ; r6 = 0xAC (0o254, third byte of €)
        halt

msg:    .str "Hi€"
