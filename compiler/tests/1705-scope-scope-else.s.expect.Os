; rcc-generated assembly
%define RCC_CODE_BASE 0o1000
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .section text

    .global main
main:
    subi r6, 2
_B_main_0:
    clrt
    bf _B_main_3
_B_main_3:
    li r2, 77
    and r1, r6, r7
    swr r2, r1
    clrt
    bf _B_main_5
_B_main_4:
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    clrt
    bf _epi_main
_B_main_5:
    and r1, r6, r7
    lwr r2, r1
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
    clrt
    bf _B_main_4
_epi_main:
    addi r6, 2
    jalr r0, r5
