; rcc-generated assembly
%define RCC_CODE_BASE 0o1000
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .section text

    .global main
main:
    subi r6, 1
    swr r5, r6
    subi r6, 17
_B_main_0:
    and r1, r6, r7
    and r2, r1, r7
    li r3, _L_flit_0
    li r1, __fcopy
    jalr r5, r1
    and r1, r6, r7
    addi r1, 4
    and r2, r1, r7
    li r3, _L_flit_1
    li r1, __fcopy
    jalr r5, r1
    and r1, r6, r7
    addi r1, 8
    and r2, r1, r7
    and r1, r6, r7
    and r3, r1, r7
    and r1, r6, r7
    addi r1, 4
    and r4, r1, r7
    li r1, __fsub
    jalr r5, r1
    and r1, r6, r7
    addi r1, 12
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 8
    and r3, r1, r7
    li r1, __fcopy
    jalr r5, r1
    and r1, r6, r7
    addi r1, 12
    and r2, r1, r7
    li r1, __ftoi
    jalr r5, r1
    and r1, r6, r7
    addi r1, 16
    swr r2, r1
    and r1, r6, r7
    addi r1, 16
    lwr r2, r1
    clrt
    bf _epi_main
_epi_main:
    addi r6, 17
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

; rcc: runtime library (auto-included)
%include "float/_float_store_helpers.s"
%include "float/_float_pack_helpers.s"
%include "float/__fcopy.s"
%include "float/__fadd.s"
%include "float/__fsub.s"
%include "float/__ftoi.s"

_L_flit_0:
    .word 1026, 2560, 0, 0
_L_flit_1:
    .word 1025, 2048, 0, 0
