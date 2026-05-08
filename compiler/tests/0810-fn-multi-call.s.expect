; rcc-generated assembly
%define RCC_CODE_BASE 0o1000
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .section text

    .global inc
inc:
    subi r6, 2
    and r1, r6, r7
    swr r2, r1
_B_inc_0:
    and r1, r6, r7
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    clrt
    bf _epi_inc
_epi_inc:
    addi r6, 2
    jalr r0, r5

    .global main
main:
    subi r6, 1
    swr r5, r6
    subi r6, 3
_B_main_0:
    li r2, 1
    li r1, inc
    jalr r5, r1
    and r1, r6, r7
    swr r2, r1
    and r1, r6, r7
    lwr r2, r1
    li r1, inc
    jalr r5, r1
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    li r1, inc
    jalr r5, r1
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
    lwr r5, r6
    addi r6, 1
    jalr r0, r5
