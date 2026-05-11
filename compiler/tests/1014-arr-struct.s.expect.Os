; rcc-generated assembly
%define RCC_CODE_BASE 0o1000
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .section text

    .global main
main:
    subi r6, 18
_B_main_0:
    and r2, r0, r0
    and r1, r6, r7
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    and r3, r1, r7
    and r1, r6, r7
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
    li r2, 1
    and r1, r6, r7
    addi r1, 1
    lwr r1, r1
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    and r3, r1, r7
    and r1, r6, r7
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
    and r1, r6, r7
    addi r1, 6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 7
    swr r2, r1
    li r2, 2
    and r1, r6, r7
    addi r1, 7
    lwr r1, r1
    swr r2, r1
    li r2, 2
    and r1, r6, r7
    addi r1, 8
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    and r3, r1, r7
    and r1, r6, r7
    addi r1, 8
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 9
    swr r2, r1
    li r2, 3
    and r1, r6, r7
    addi r1, 9
    lwr r1, r1
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    and r3, r1, r7
    and r1, r6, r7
    addi r1, 8
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    and r1, r6, r7
    addi r1, 10
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 11
    swr r2, r1
    li r2, 4
    and r1, r6, r7
    addi r1, 11
    lwr r1, r1
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    and r3, r1, r7
    and r1, r6, r7
    addi r1, 8
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 12
    swr r2, r1
    and r1, r6, r7
    addi r1, 12
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 13
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    and r3, r1, r7
    and r1, r6, r7
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 14
    swr r2, r1
    and r1, r6, r7
    addi r1, 14
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 15
    swr r2, r1
    and r1, r6, r7
    addi r1, 15
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 16
    swr r2, r1
    and r1, r6, r7
    addi r1, 13
    lwr r3, r1
    and r1, r6, r7
    addi r1, 16
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 17
    swr r2, r1
    and r1, r6, r7
    addi r1, 17
    lwr r2, r1
    clrt
    bf _epi_main
_epi_main:
    addi r6, 18
    jalr r0, r5
