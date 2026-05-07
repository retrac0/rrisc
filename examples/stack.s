; stack.s -- Minimal demo of subr.inc (rcc ABI)
;
; Doubles r2 via a leaf subroutine; verifies push/call/ret.
;
%include "subr.inc"

        .org 0o1000

start:  li   r6, 0o0100
        li   r2, 21
        call double_r2
        halt

; double_r2 -- return r2 * 2 in r2 (arg/return reg)
double_r2:
        add  r2, r2, r2
        and  r2, r2, r7
        ret
