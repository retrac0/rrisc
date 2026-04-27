; 1100-radix-modes.s -- test .decimal and .octal radix mode directives
;
; Demonstrates:
;   - radix set by included file (.octal in defs.inc)
;   - .decimal and .octal switch default number base mid-file
;   - explicit 0x/0o prefix always overrides the active mode
;   - same macro body uses the radix active at each call site
;
; At halt: r1=0012, r2=0010, r3=0377, r4=0010, r5=0012, r6=0010

%include "1100-radix-modes-defs.inc"   ; sets .octal, defines CONST=10 (oct=8 dec)

%macro load_ten reg
    li reg, 10
%endm

        .org 1000           ; octal 1000 (mode from include)

        .decimal
        li   r1, 10         ; r1 = 10 decimal (0o12)
        .octal
        li   r2, 10         ; r2 = 10 octal = 8 decimal (0o10)
        li   r3, 0xff       ; r3 = 255 decimal (0o377) -- explicit hex, ignores mode
        li   r4, CONST      ; r4 = CONST expands to "10", parsed octal = 8 (0o10)
        .decimal
        load_ten r5         ; macro: li r5, 10 under decimal mode = 10 (0o12)
        .octal
        load_ten r6         ; macro: li r6, 10 under octal mode = 8 (0o10)
        halt
