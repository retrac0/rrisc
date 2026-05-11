; rolror.asm -- test ror and rol for RRISC (12-bit)
;
; ror: rd = rotate_right(ra, 1)  -- bit 0 -> T,  old T -> bit 11
; rol: rd = rotate_left(ra, 1)   -- bit 11 -> T, old T -> bit 0
;
; T acts as the 13th bit of the rotation, so 13 consecutive rors (or rols)
; starting with T=0 rotate a value through a full 13-bit cycle back to itself.
;
; Test 1: 13 x ror of r1=1 with T=0 -> r1=1, T=0
; Test 2: 13 x rol of r2=1 with T=0 -> r2=1, T=0
; Test 3: 6  x ror of r3=0o7700    -> r3=0o0077 (logical right shift by 6)
; Test 4: 6  x rol of r4=r3        -> r4=0o7700 (shift back)
;
; Expected final register state (verify with python3 -m pytools.sim --trace):
;   r1 = 0001   r2 = 0001   r3 = 0077   r4 = 7700   T = 0

        .org 0o1000

        ; -- Test 1: 13-step ror cycle --
        sub  r0, r0, r0 ; T = 0  (0-0 never borrows)
        and  r1, r0, r0 ; r1 = 0
        addi r1, 1      ; r1 = 0001
        ror  r1, r1     ; 0001 -> 0000, T=1
        ror  r1, r1     ; 0000 -> 4000, T=0
        ror  r1, r1     ; 4000 -> 2000
        ror  r1, r1     ; 2000 -> 1000
        ror  r1, r1     ; 1000 -> 0400
        ror  r1, r1     ; 0400 -> 0200
        ror  r1, r1     ; 0200 -> 0100
        ror  r1, r1     ; 0100 -> 0040
        ror  r1, r1     ; 0040 -> 0020
        ror  r1, r1     ; 0020 -> 0010
        ror  r1, r1     ; 0010 -> 0004
        ror  r1, r1     ; 0004 -> 0002
        ror  r1, r1     ; 0002 -> 0001, T=0  <- back to start

        ; -- Test 2: 13-step rol cycle --
        and  r2, r0, r0 ; r2 = 0
        addi r2, 1      ; r2 = 0001
        rol  r2, r2     ; 0001 -> 0002
        rol  r2, r2     ; 0002 -> 0004
        rol  r2, r2     ; 0004 -> 0010
        rol  r2, r2     ; 0010 -> 0020
        rol  r2, r2     ; 0020 -> 0040
        rol  r2, r2     ; 0040 -> 0100
        rol  r2, r2     ; 0100 -> 0200
        rol  r2, r2     ; 0200 -> 0400
        rol  r2, r2     ; 0400 -> 1000
        rol  r2, r2     ; 1000 -> 2000
        rol  r2, r2     ; 2000 -> 4000
        rol  r2, r2     ; 4000 -> 0000, T=1
        rol  r2, r2     ; 0000 -> 0001, T=0  <- back to start

        ; -- Test 3: ror as logical right shift by 6 --
        ; Lower 6 bits of 0o7700 are 0, so they rotate out without touching T.
        lui  r3, 0o77   ; r3 = 0o7700  (bits 11-6 set, bits 5-0 clear)
        ror  r3, r3     ; 7700 -> 3740
        ror  r3, r3     ; 3740 -> 1760
        ror  r3, r3     ; 1760 -> 0770
        ror  r3, r3     ; 0770 -> 0374
        ror  r3, r3     ; 0374 -> 0176
        ror  r3, r3     ; 0176 -> 0077, T=0

        ; -- Test 4: rol as logical left shift by 6 --
        ; Upper 6 bits of 0o0077 are 0, so they rotate out without touching T.
        and  r4, r3, r7 ; r4 = 0o0077  (move)
        rol  r4, r4     ; 0077 -> 0176
        rol  r4, r4     ; 0176 -> 0374
        rol  r4, r4     ; 0374 -> 0770
        rol  r4, r4     ; 0770 -> 1760
        rol  r4, r4     ; 1760 -> 3740
        rol  r4, r4     ; 3740 -> 7700, T=0

        halt
