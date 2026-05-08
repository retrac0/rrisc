; rcc-generated assembly
%define RCC_CODE_BASE 0o1
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .section data
g:
    .word 42

    .section text

    .global f
f:
    subi r6, 1
_B_f_0:
    li r1, g
    lwr r2, r1
    and r1, r6, r7
    swr r2, r1
    and r1, r6, r7
    lwr r2, r1
    clrt
    bf _epi_f
_epi_f:
    addi r6, 1
    jalr r0, r5

    .global main
main:
    subi r6, 1
    swr r5, r6
    subi r6, 1
_B_main_0:
    li r1, f
    jalr r5, r1
    and r1, r6, r7
    swr r2, r1
    and r1, r6, r7
    lwr r2, r1
    clrt
    bf _epi_main
_epi_main:
    addi r6, 1
    lwr r5, r6
    addi r6, 1
    jalr r0, r5
