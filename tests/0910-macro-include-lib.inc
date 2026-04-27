; 0910-macro-include-lib.inc -- macro library included by 0910-macro-include.s
;
; Defines INIT constant and two macros so the test can verify that:
;   - macros defined in an included file are visible to the caller
;   - %define names from the include are substituted inside expanded macro bodies

%define INIT 5

%macro double reg
    addc reg, reg, reg
%endm

%macro add_step reg
    addi reg, INIT
%endm
