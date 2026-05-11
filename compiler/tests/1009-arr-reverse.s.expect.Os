; rcc-generated assembly
%define RCC_CODE_BASE 0o1000
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .section text

    .global main
main:
    subi r6, 21
_B_main_0:
    and r1, r6, r7
    addi r1, 1
    and r2, r1, r7
    and r1, r6, r7
    swr r2, r1
    li r2, 1
    and r1, r6, r7
    lwr r1, r1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    and r3, r1, r7
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 5
    swr r2, r1
    li r2, 2
    and r1, r6, r7
    addi r1, 5
    lwr r1, r1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    and r3, r1, r7
    li r2, 2
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
    li r2, 3
    and r1, r6, r7
    addi r1, 6
    lwr r1, r1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    and r3, r1, r7
    li r2, 3
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 7
    swr r2, r1
    li r2, 4
    and r1, r6, r7
    addi r1, 7
    lwr r1, r1
    swr r2, r1
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 8
    swr r2, r1
    li r2, 3
    and r1, r6, r7
    addi r1, 9
    swr r2, r1
    clrt
    bf _B_main_6
_B_main_1:
    and r1, r6, r7
    addi r1, 11
    lwr r3, r1
    and r1, r6, r7
    addi r1, 12
    lwr r2, r1
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    rol r2, r0
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    and r1, r6, r7
    addi r1, 10
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_2
    clrt
    bf _B_main_4
_B_main_2:
    and r1, r6, r7
    addi r1, 1
    and r3, r1, r7
    and r1, r6, r7
    addi r1, 11
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 13
    swr r2, r1
    and r1, r6, r7
    addi r1, 13
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 14
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    and r3, r1, r7
    and r1, r6, r7
    addi r1, 12
    lwr r2, r1
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
    addi r1, 16
    lwr r2, r1
    and r1, r6, r7
    addi r1, 13
    lwr r1, r1
    swr r2, r1
    and r1, r6, r7
    addi r1, 14
    lwr r2, r1
    and r1, r6, r7
    addi r1, 15
    lwr r1, r1
    swr r2, r1
    and r1, r6, r7
    addi r1, 11
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 17
    swr r2, r1
    and r1, r6, r7
    addi r1, 12
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    and r1, r6, r7
    addi r1, 18
    swr r2, r1
    clrt
    bf _B_main_5
_B_main_4:
    and r1, r6, r7
    addi r1, 1
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 19
    swr r2, r1
    and r1, r6, r7
    addi r1, 19
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 20
    swr r2, r1
    and r1, r6, r7
    addi r1, 20
    lwr r2, r1
    clrt
    bf _epi_main
_B_main_5:
    and r1, r6, r7
    addi r1, 18
    lwr r2, r1
    and r1, r6, r7
    addi r1, 12
    swr r2, r1
    and r1, r6, r7
    addi r1, 17
    lwr r2, r1
    and r1, r6, r7
    addi r1, 11
    swr r2, r1
    clrt
    bf _B_main_1
_B_main_6:
    and r1, r6, r7
    addi r1, 9
    lwr r2, r1
    and r1, r6, r7
    addi r1, 12
    swr r2, r1
    and r1, r6, r7
    addi r1, 8
    lwr r2, r1
    and r1, r6, r7
    addi r1, 11
    swr r2, r1
    clrt
    bf _B_main_1
_epi_main:
    addi r6, 21
    jalr r0, r5
