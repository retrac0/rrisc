; 1100-radix-modes.s -- test C-style number literal formats
;
;   r1 = 0xff    (hex prefix)     = 255 decimal = 0377 octal
;   r2 = 0100    (C-style octal)  = 64 decimal  = 0100 octal
;   r3 = 0b1010  (binary prefix)  = 10 decimal  = 0012 octal
;   r4 = 0o17    (Python octal)   = 15 decimal  = 0017 octal
;   r5 = 42      (decimal)        = 42 decimal  = 0052 octal

        .org 0o1000
        li r1, 0xff
        li r2, 0100
        li r3, 0b1010
        li r4, 0o17
        li r5, 42
        halt
