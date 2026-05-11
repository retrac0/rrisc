; 0800-jalr.s -- jalr: subroutine calls and long conditional branches
;
; jalr saves the return address (next PC) in rd and jumps to ra,
; matching the semantics of ARM BL / z/Series BAL.
; Return: jalr r0, link  (r0 hardwired zero discards the return address)
;
; Long conditional branch idiom (for targets beyond the +/-31-word bt/bf range):
;   long-bt:  bf skip; li r5, far; jalr r0, r5  -- jump if T=1
;   long-bf:  bt skip; li r5, far; jalr r0, r5  -- jump if T=0
; The short branch inverts the condition to skip the 3-word jump sequence.
;
; This test:
;   1. Calls double(3) -> r1=6, then double(6) -> r1=12
;   2. sub r2=10 vs r1=12: T=1 (borrow: 10 < 12)
;   3. Long-bt taken  -> big path: r3=1
;   4. Long-bf not taken (T=1, bt skips the jump) -> halt
;
; At halt: T=1  r1=0014  r2=0012  r3=0001  r4=0000

        .org 0o1000

        ; -- call double(3) --
        and  r1, r0, r0       ; r1 = 0
        addi r1, 3            ; r1 = 3
        li   r5, double
        jalr r6, r5           ; r6 = return addr, pc = double  ->  r1 = 6

        ; -- call double(r1=6) --
        li   r5, double
        jalr r6, r5           ;  ->  r1 = 12

        ; -- compare: r2=10 vs r1=12 --
        and  r2, r0, r0
        addi r2, 10           ; r2 = 10
        sub  r0, r2, r1       ; T=1 (borrow: 10 < 12)

        ; -- long-bt: if T=1, jump to big --
        bf   skip_bt          ; T=1 -> bf not taken, fall through to jump
        li   r5, big
        jalr r0, r5           ; long jump to big
skip_bt:
        halt                  ; small path (not reached in this run)

        ; -- big path --
big:    and  r3, r0, r0
        addi r3, 1            ; r3 = 1

        ; -- long-bf: if T=0, jump to far_label --
        ; T=1 here, so bt is taken and the jump is skipped
        bt   skip_bf          ; T=1 -> bt taken, skip the jump
        li   r5, far_label
        jalr r0, r5
skip_bf:
        halt

far_label:                    ; unreachable in this run
        addi r4, 1
        halt

        ; -- subroutine --
double: add  r1, r1, r1       ; r1 *= 2
        jalr r0, r6           ; return
