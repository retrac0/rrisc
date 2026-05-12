; rcc-generated assembly
%define RCC_CODE_BASE 0o1000
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .section text

    .global main
main:
    subi r6, 1
    swr r5, r6
    subi r6, 2
_B_main_0:
    li r2, _L_flit_0
    li r3, _L_flit_1
    li r1, __fcmp
    jalr r5, r1
    and r1, r6, r7
    swr r2, r1
    and r1, r6, r7
    lwr r3, r1
    and r2, r0, r0
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    rol r2, r0
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    clrt
    bf _epi_main
_epi_main:
    addi r6, 2
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

; rcc: runtime library (auto-included)
%include "float/_float_store_helpers.s"
%include "float/_float_pack_helpers.s"
%include "float/__fcmp.s"

_L_flit_0:
    .word 1024, 2048, 0, 0
_L_flit_1:
    .word 1025, 2048, 0, 0
