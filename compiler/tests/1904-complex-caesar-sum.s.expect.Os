; rcc-generated assembly
%define RCC_CODE_BASE 0o1000
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .section text

    .global main
main:
    subi r6, 1
    swr r5, r6
    subi r6, 23
_B_main_0:
    and r1, r6, r7
    addi r1, 1
    and r3, r1, r7
    and r2, r0, r0
    add r2, r3, r2
    and r1, r6, r7
    swr r2, r1
    li r2, 72
    and r1, r6, r7
    lwr r1, r1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    and r3, r1, r7
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
    li r2, 101
    and r1, r6, r7
    addi r1, 6
    lwr r1, r1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    and r3, r1, r7
    li r2, 2
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 7
    swr r2, r1
    li r2, 108
    and r1, r6, r7
    addi r1, 7
    lwr r1, r1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    and r3, r1, r7
    li r2, 3
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 8
    swr r2, r1
    li r2, 108
    and r1, r6, r7
    addi r1, 8
    lwr r1, r1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    and r3, r1, r7
    li r2, 4
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 9
    swr r2, r1
    li r2, 111
    and r1, r6, r7
    addi r1, 9
    lwr r1, r1
    swr r2, r1
    li r2, 3
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 11
    swr r2, r1
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 12
    swr r2, r1
    clrt
    bf _B_main_7
_B_main_1:
    and r1, r6, r7
    addi r1, 14
    lwr r3, r1
    li r2, 5
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    rol r2, r0
    and r1, r6, r7
    addi r1, 13
    swr r2, r1
    and r1, r6, r7
    addi r1, 13
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_2
    clrt
    bf _B_main_5
_B_main_2:
    and r1, r6, r7
    addi r1, 1
    and r3, r1, r7
    and r1, r6, r7
    addi r1, 14
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
    lwr r3, r1
    and r1, r6, r7
    addi r1, 10
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 17
    swr r2, r1
    and r1, r6, r7
    addi r1, 17
    lwr r3, r1
    lui r2, 2
    li r1, __mod
    jalr r5, r1
    and r1, r6, r7
    addi r1, 18
    swr r2, r1
    and r1, r6, r7
    addi r1, 20
    lwr r3, r1
    and r1, r6, r7
    addi r1, 18
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 19
    swr r2, r1
    clrt
    bf _B_main_3
_B_main_3:
    and r1, r6, r7
    addi r1, 14
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 21
    swr r2, r1
    clrt
    bf _B_main_6
_B_main_5:
    and r1, r6, r7
    addi r1, 20
    lwr r3, r1
    lui r2, 4
    li r1, __mod
    jalr r5, r1
    and r1, r6, r7
    addi r1, 22
    swr r2, r1
    and r1, r6, r7
    addi r1, 22
    lwr r2, r1
    clrt
    bf _epi_main
_B_main_6:
    and r1, r6, r7
    addi r1, 19
    lwr r2, r1
    and r1, r6, r7
    addi r1, 20
    swr r2, r1
    and r1, r6, r7
    addi r1, 21
    lwr r2, r1
    and r1, r6, r7
    addi r1, 14
    swr r2, r1
    clrt
    bf _B_main_1
_B_main_7:
    and r1, r6, r7
    addi r1, 11
    lwr r2, r1
    and r1, r6, r7
    addi r1, 20
    swr r2, r1
    and r1, r6, r7
    addi r1, 12
    lwr r2, r1
    and r1, r6, r7
    addi r1, 14
    swr r2, r1
    clrt
    bf _B_main_1
_epi_main:
    addi r6, 23
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

; rcc: lib/librcc.s (integer multiply/divide/modulo)
%include "librcc.s"
