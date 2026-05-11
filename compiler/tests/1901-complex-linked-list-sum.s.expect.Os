; rcc-generated assembly
%define RCC_CODE_BASE 0o12
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .section data
vals:
    .fill 5
nexts:
    .fill 5

    .section text

    .global main
main:
    subi r6, 20
_B_main_0:
    li r2, vals
    and r1, r6, r7
    swr r2, r1
    li r2, 10
    and r1, r6, r7
    lwr r1, r1
    swr r2, r1
    li r2, nexts
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
    li r2, 1
    and r1, r6, r7
    addi r1, 1
    lwr r1, r1
    swr r2, r1
    li r3, vals
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    li r2, 20
    and r1, r6, r7
    addi r1, 2
    lwr r1, r1
    swr r2, r1
    li r3, nexts
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    li r2, 2
    and r1, r6, r7
    addi r1, 3
    lwr r1, r1
    swr r2, r1
    li r3, vals
    li r2, 2
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
    li r2, 30
    and r1, r6, r7
    addi r1, 4
    lwr r1, r1
    swr r2, r1
    li r3, nexts
    li r2, 2
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 5
    swr r2, r1
    li r2, 3
    and r1, r6, r7
    addi r1, 5
    lwr r1, r1
    swr r2, r1
    li r3, vals
    li r2, 3
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
    li r2, 40
    and r1, r6, r7
    addi r1, 6
    lwr r1, r1
    swr r2, r1
    li r3, nexts
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
    li r3, vals
    li r2, 4
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 8
    swr r2, r1
    li r2, 50
    and r1, r6, r7
    addi r1, 8
    lwr r1, r1
    swr r2, r1
    and r2, r7, r7
    and r1, r6, r7
    addi r1, 9
    swr r2, r1
    li r3, nexts
    li r2, 4
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    and r1, r6, r7
    addi r1, 9
    lwr r2, r1
    and r1, r6, r7
    addi r1, 10
    lwr r1, r1
    swr r2, r1
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 11
    swr r2, r1
    clrt
    bf _B_main_6
_B_main_1:
    and r1, r6, r7
    addi r1, 13
    lwr r3, r1
    and r2, r0, r0
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    li r2, 1
    bf _L_main_ne_130
    li r2, 0
_L_main_ne_130:
    and r1, r6, r7
    addi r1, 12
    swr r2, r1
    and r1, r6, r7
    addi r1, 12
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_2
    clrt
    bf _B_main_4
_B_main_2:
    li r3, vals
    and r1, r6, r7
    addi r1, 13
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 14
    swr r2, r1
    and r1, r6, r7
    addi r1, 14
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 15
    swr r2, r1
    and r1, r6, r7
    addi r1, 17
    lwr r3, r1
    and r1, r6, r7
    addi r1, 15
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 16
    swr r2, r1
    li r3, nexts
    and r1, r6, r7
    addi r1, 13
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 18
    swr r2, r1
    and r1, r6, r7
    addi r1, 18
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 19
    swr r2, r1
    clrt
    bf _B_main_5
_B_main_4:
    and r1, r6, r7
    addi r1, 17
    lwr r2, r1
    clrt
    bf _epi_main
_B_main_5:
    and r1, r6, r7
    addi r1, 16
    lwr r2, r1
    and r1, r6, r7
    addi r1, 17
    swr r2, r1
    and r1, r6, r7
    addi r1, 19
    lwr r2, r1
    and r1, r6, r7
    addi r1, 13
    swr r2, r1
    clrt
    bf _B_main_1
_B_main_6:
    and r1, r6, r7
    addi r1, 11
    lwr r2, r1
    and r1, r6, r7
    addi r1, 17
    swr r2, r1
    and r1, r6, r7
    addi r1, 11
    lwr r2, r1
    and r1, r6, r7
    addi r1, 13
    swr r2, r1
    clrt
    bf _B_main_1
_epi_main:
    addi r6, 20
    jalr r0, r5
