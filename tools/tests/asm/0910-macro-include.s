; 0910-macro-include.s -- macros defined in an %include'd file
;
; Verifies: macros defined in a library include file are visible to the caller;
; %define names from the include (INIT=5) are substituted in expanded macro bodies.
;
; At halt: r1=0o017, r2=0o012

%include "0910-macro-include-lib.inc"

        .org 0o1000

        li    r1, INIT      ; r1 = 5
        double r1           ; r1 = 10 (0o012)
        and   r2, r1, r7    ; r2 = 10 (copy before step)
        add_step r1         ; r1 = 10 + INIT = 15 (0o017); INIT substituted in body
        halt
