; rcc-generated assembly
%define RCC_CODE_BASE 0o1000
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .section text

    .global main
main:
    subi r6, 38
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
    addi r1, 11
    swr r2, r1
    li r2, 1
    and r1, r6, r7
    addi r1, 11
    lwr r1, r1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    and r3, r1, r7
    li r2, 2
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 12
    swr r2, r1
    li r2, 1
    and r1, r6, r7
    addi r1, 12
    lwr r1, r1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    and r3, r1, r7
    li r2, 3
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 13
    swr r2, r1
    li r2, 2
    and r1, r6, r7
    addi r1, 13
    lwr r1, r1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    and r3, r1, r7
    li r2, 4
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 14
    swr r2, r1
    li r2, 2
    and r1, r6, r7
    addi r1, 14
    lwr r1, r1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    and r3, r1, r7
    li r2, 5
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 15
    swr r2, r1
    li r2, 3
    and r1, r6, r7
    addi r1, 15
    lwr r1, r1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    and r3, r1, r7
    li r2, 6
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 16
    swr r2, r1
    li r2, 3
    and r1, r6, r7
    addi r1, 16
    lwr r1, r1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    and r3, r1, r7
    li r2, 7
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 17
    swr r2, r1
    li r2, 3
    and r1, r6, r7
    addi r1, 17
    lwr r1, r1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    and r3, r1, r7
    li r2, 8
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 18
    swr r2, r1
    li r2, 3
    and r1, r6, r7
    addi r1, 18
    lwr r1, r1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    and r3, r1, r7
    li r2, 9
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 19
    swr r2, r1
    li r2, 1
    and r1, r6, r7
    addi r1, 19
    lwr r1, r1
    swr r2, r1
    li r2, 1
    and r1, r6, r7
    addi r1, 20
    swr r2, r1
    clrt
    bf _B_main_13
_B_main_1:
    and r1, r6, r7
    addi r1, 22
    lwr r3, r1
    li r2, 10
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    rol r2, r0
    and r1, r6, r7
    addi r1, 21
    swr r2, r1
    and r1, r6, r7
    addi r1, 21
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_2
    clrt
    bf _B_main_11
_B_main_2:
    and r1, r6, r7
    addi r1, 1
    and r3, r1, r7
    and r1, r6, r7
    addi r1, 22
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 23
    swr r2, r1
    and r1, r6, r7
    addi r1, 23
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 24
    swr r2, r1
    and r1, r6, r7
    addi r1, 22
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    and r1, r6, r7
    addi r1, 25
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    and r3, r1, r7
    and r1, r6, r7
    addi r1, 25
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 26
    swr r2, r1
    and r1, r6, r7
    addi r1, 26
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 27
    swr r2, r1
    and r1, r6, r7
    addi r1, 24
    lwr r3, r1
    and r1, r6, r7
    addi r1, 27
    lwr r2, r1
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_208
    li r2, 0
_L_main_ne_208:
    and r1, r6, r7
    addi r1, 28
    swr r2, r1
    and r1, r6, r7
    addi r1, 28
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_3
    clrt
    bf _B_main_7
_B_main_3:
    and r1, r6, r7
    addi r1, 30
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 29
    swr r2, r1
    and r1, r6, r7
    addi r1, 29
    lwr r3, r1
    and r1, r6, r7
    addi r1, 32
    lwr r2, r1
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r2, r3
    rol r2, r0
    and r1, r6, r7
    addi r1, 31
    swr r2, r1
    and r1, r6, r7
    addi r1, 31
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_14
_B_main_5:
    clrt
    bf _B_main_16
_B_main_7:
    li r2, 1
    and r1, r6, r7
    addi r1, 33
    swr r2, r1
    clrt
    bf _B_main_15
_B_main_9:
    and r1, r6, r7
    addi r1, 22
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 34
    swr r2, r1
    clrt
    bf _B_main_12
_B_main_11:
    and r1, r6, r7
    addi r1, 32
    lwr r2, r1
    clrt
    bf _epi_main
_B_main_12:
    and r1, r6, r7
    addi r1, 34
    lwr r2, r1
    and r1, r6, r7
    addi r1, 22
    swr r2, r1
    and r1, r6, r7
    addi r1, 35
    lwr r2, r1
    and r1, r6, r7
    addi r1, 30
    swr r2, r1
    and r1, r6, r7
    addi r1, 36
    lwr r2, r1
    and r1, r6, r7
    addi r1, 32
    swr r2, r1
    clrt
    bf _B_main_1
_B_main_13:
    and r1, r6, r7
    addi r1, 20
    lwr r2, r1
    and r1, r6, r7
    addi r1, 22
    swr r2, r1
    and r1, r6, r7
    addi r1, 20
    lwr r2, r1
    and r1, r6, r7
    addi r1, 30
    swr r2, r1
    and r1, r6, r7
    addi r1, 20
    lwr r2, r1
    and r1, r6, r7
    addi r1, 32
    swr r2, r1
    clrt
    bf _B_main_1
_B_main_14:
    and r1, r6, r7
    addi r1, 29
    lwr r2, r1
    and r1, r6, r7
    addi r1, 37
    swr r2, r1
    clrt
    bf _B_main_5
_B_main_15:
    and r1, r6, r7
    addi r1, 33
    lwr r2, r1
    and r1, r6, r7
    addi r1, 35
    swr r2, r1
    and r1, r6, r7
    addi r1, 32
    lwr r2, r1
    and r1, r6, r7
    addi r1, 36
    swr r2, r1
    clrt
    bf _B_main_9
_B_main_16:
    and r1, r6, r7
    addi r1, 29
    lwr r2, r1
    and r1, r6, r7
    addi r1, 35
    swr r2, r1
    and r1, r6, r7
    addi r1, 37
    lwr r2, r1
    and r1, r6, r7
    addi r1, 36
    swr r2, r1
    clrt
    bf _B_main_9
_epi_main:
    addi r6, 38
    jalr r0, r5
