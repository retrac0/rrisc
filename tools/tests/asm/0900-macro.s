; 0900-macro.s -- parameterized macro expansion
; Tests zero-arg, single-arg, and two-arg macros
;
; %macro nop2:         zero-arg, emits two nop instructions
; %macro double reg:   reg += reg
; %macro mov dst, src: dst = src (via add dst, src, r0)
;
; label on a macro invocation line (result:) is attached to the first
; expanded instruction.
;
; At halt: r1=0o010, r2=0o010, r3=0o010

%macro nop2
    nop
    nop
%endm

%macro double reg
    addc reg, reg, reg
%endm

%macro mov dst, src
    and dst, src, r7
%endm

        .org 0o1000

        li      r1, 2     ; r1 = 2
        double  r1        ; r1 = 4
        double  r1        ; r1 = 8 (0o010)
result: mov r2, r1        ; r2 = 8 -- label on invocation attaches to expansion
        mov r3, r2        ; r3 = 8
        nop2
        halt
