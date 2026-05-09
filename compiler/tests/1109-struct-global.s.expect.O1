; rcc-generated assembly
%define RCC_CODE_BASE 0o2
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .section data
g:
    .fill 2

    .section text

    .global main
main:
    subi r6, 5
_B_main_0:
    li r2, 5
    li r1, g
    swr r2, r1
    li r3, g
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    swr r2, r1
    li r2, 6
    and r1, r6, r7
    lwr r1, r1
    swr r2, r1
    li r1, g
    lwr r2, r1
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
    li r3, g
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r3, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    clrt
    bf _epi_main
_epi_main:
    addi r6, 5
    jalr r0, r5
