; rcc-generated assembly
%define RCC_CODE_BASE 0o1
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .section data
flag:
    .word 0

    .section text

    .global set_flag
set_flag:
_B_set_flag_0:
    li r2, 1
    li r1, flag
    swr r2, r1
    li r2, 1
    clrt
    bf _epi_set_flag
_epi_set_flag:
    jalr r0, r5

    .global main
main:
    subi r6, 1
    swr r5, r6
    subi r6, 2
_B_main_0:
    clrt
    bf _B_main_1
_B_main_1:
    li r1, set_flag
    jalr r5, r1
    and r1, r6, r7
    swr r2, r1
    and r1, r6, r7
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_4
    clrt
    bf _B_main_2
_B_main_2:
    clrt
    bf _B_main_5
_B_main_4:
    clrt
    bf _B_main_5
_B_main_5:
    li r1, flag
    lwr r2, r1
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
