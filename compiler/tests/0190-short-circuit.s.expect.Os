; rcc-generated assembly
%define RCC_CODE_BASE 0o1
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .section data
side_effect_called:
    .word 0

    .section text

    .global main
main:
    subi r6, 3
_B_main_5:
    and r2, r0, r0
    and r1, r6, r7
    swr r2, r1
    and r1, r6, r7
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_6
    clrt
    bf _B_main_12
_B_main_6:
    li r2, 99
    li r1, side_effect_called
    swr r2, r1
_B_main_12:
    li r2, 1
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_13
    clrt
    bf _B_main_14
_B_main_13:
    and r2, r0, r0
    li r1, side_effect_called
    swr r2, r1
_B_main_14:
    li r1, side_effect_called
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    clrt
    bf _epi_main
_epi_main:
    addi r6, 3
    jalr r0, r5
