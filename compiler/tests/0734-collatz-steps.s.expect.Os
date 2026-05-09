; rcc-generated assembly
%define RCC_CODE_BASE 0o1000
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .section text

    .global main
main:
    subi r6, 1
    swr r5, r6
    subi r6, 12
_B_main_0:
    li r2, 6
    and r1, r6, r7
    swr r2, r1
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
    clrt
    bf _B_main_10
_B_main_1:
    and r1, r6, r7
    addi r1, 3
    lwr r3, r1
    li r2, 1
    sub r1, r3, r2
    sub r0, r0, r1
    rol r2, r0
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_2
    clrt
    bf _B_main_8
_B_main_2:
    and r1, r6, r7
    addi r1, 3
    lwr r3, r1
    li r2, 2
    li r1, __mod
    jalr r5, r1
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
    and r1, r6, r7
    addi r1, 4
    lwr r3, r1
    and r2, r0, r0
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_50
    li r2, 0
_L_main_ne_50:
    and r1, r6, r7
    addi r1, 5
    swr r2, r1
    and r1, r6, r7
    addi r1, 5
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_3
    clrt
    bf _B_main_5
_B_main_3:
    and r1, r6, r7
    addi r1, 3
    lwr r3, r1
    li r2, 2
    li r1, __div
    jalr r5, r1
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
    clrt
    bf _B_main_12
_B_main_5:
    and r1, r6, r7
    addi r1, 3
    lwr r3, r1
    and r4, r3, r7
    li r2, 1
    and r2, r2, r2
_L_main_shift_loop_82:
    sub r0, r0, r2
    bf _L_main_shift_end_82
    clrt
    rol r3, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_main_shift_loop_82
_L_main_shift_end_82:
    and r2, r3, r7
    add r2, r4, r2
    and r1, r6, r7
    addi r1, 7
    swr r2, r1
    and r1, r6, r7
    addi r1, 7
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 8
    swr r2, r1
    clrt
    bf _B_main_11
_B_main_6:
    and r1, r6, r7
    addi r1, 10
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 9
    swr r2, r1
    clrt
    bf _B_main_9
_B_main_8:
    and r1, r6, r7
    addi r1, 10
    lwr r2, r1
    clrt
    bf _epi_main
_B_main_9:
    and r1, r6, r7
    addi r1, 11
    lwr r2, r1
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    and r1, r6, r7
    addi r1, 9
    lwr r2, r1
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    clrt
    bf _B_main_1
_B_main_10:
    and r1, r6, r7
    lwr r2, r1
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    clrt
    bf _B_main_1
_B_main_11:
    and r1, r6, r7
    addi r1, 8
    lwr r2, r1
    and r1, r6, r7
    addi r1, 11
    swr r2, r1
    clrt
    bf _B_main_6
_B_main_12:
    and r1, r6, r7
    addi r1, 6
    lwr r2, r1
    and r1, r6, r7
    addi r1, 11
    swr r2, r1
    clrt
    bf _B_main_6
_epi_main:
    addi r6, 12
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

; rcc: lib/librcc.s (integer multiply/divide/modulo)
%include "librcc.s"
