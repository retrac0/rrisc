; subr.inc -- push / pop / call / ret macros (rcc ABI; see Arch.md)
;
; Register convention:
;   r1  scratch / address temp (not used for args)
;   r2  arg 1 / return value
;   r3  arg 2
;   r4  arg 3
;   r5  link register (LR) -- return address from jalr r5, ra
;   r6  stack pointer (SP), full descending -- points to last pushed word
;   r7  hardwired -1 -- used by push for decrement
;
; Non-leaf functions must save/restore r5:
;   push r5
;   call other_func
;   pop  r5
;   ret

; push reg -- pre-decrement SP, then store reg at new top
%macro push reg
    subi r6, 1
    swr  reg, r6
%endm

; pop reg -- load from top of stack into reg, then post-increment SP
%macro pop reg
    lwr  reg, r6
    addi r6, 1
%endm

; call target -- call subroutine at label; return address in r5 (target via r1)
%macro call target
    li   r1, target
    jalr r5, r1
%endm

; callr ra -- call subroutine whose address is in register ra; return address in r5
%macro callr ra
    jalr r5, ra
%endm

; ret -- return to caller (jump to r5, discard new link in r0)
%macro ret
    jalr r0, r5
%endm
