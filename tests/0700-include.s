; 0700-include.s -- exercise %include: macros defined in an included file
;
; At halt: T=0  r1=0100  r2=0077  r3=0177

%include "0700-include-defs.inc"

        .org 0o1000

        li   r1, INCA      ; r1 = 0o0100  (64 decimal)
        li   r2, INCB      ; r2 = 0o0077  (63 decimal)
        sub  r0, r0, r0    ; clrt
        addc r3, r1, r2    ; r3 = 0o0177 (127 decimal)
        halt
