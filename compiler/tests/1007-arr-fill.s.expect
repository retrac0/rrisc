; rcc-generated assembly
%define RCC_CODE_BASE 0o1000
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .section text

    .global main
main:
    subi r6, 13
_B_main_0:
    and r2, r0, r0
    and r1, r6, r7
    swr r2, r1
    clrt
    bf _B_main_7
_B_main_1:
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    li r2, 5
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    rol r2, r0
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_2
    clrt
    bf _B_main_5
_B_main_2:
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    li r2, 1
    and r2, r2, r2
_L_main_shift_loop_35:
    sub r0, r0, r2
    bf _L_main_shift_end_35
    clrt
    rol r3, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_main_shift_loop_35
_L_main_shift_end_35:
    and r2, r3, r7
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    and r1, r6, r7
    addi r1, 5
    and r3, r1, r7
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    and r1, r6, r7
    addi r1, 4
    lwr r1, r1
    swr r2, r1
    clrt
    bf _B_main_3
_B_main_3:
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    clrt
    bf _B_main_6
_B_main_5:
    and r1, r6, r7
    addi r1, 5
    and r3, r1, r7
    li r2, 4
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 11
    swr r2, r1
    and r1, r6, r7
    addi r1, 11
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 12
    swr r2, r1
    and r1, r6, r7
    addi r1, 12
    lwr r2, r1
    clrt
    bf _epi_main
_B_main_6:
    and r1, r6, r7
    addi r1, 10
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    clrt
    bf _B_main_1
_B_main_7:
    and r1, r6, r7
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    clrt
    bf _B_main_1
_epi_main:
    addi r6, 13
    jalr r0, r5
