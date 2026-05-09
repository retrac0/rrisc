; rcc-generated assembly
%define RCC_CODE_BASE 0o1000
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .section text

    .global main
main:
    subi r6, 4
_B_main_0:
    and r1, r6, r7
    addi r1, 1
    and r2, r1, r7
    and r1, r6, r7
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    and r1, r6, r7
    lwr r3, r1
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_23
    li r2, 0
_L_main_ne_23:
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    clrt
    bf _epi_main
_epi_main:
    addi r6, 4
    jalr r0, r5
