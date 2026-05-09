; rcc-generated assembly
%define RCC_CODE_BASE 0o1000
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .section text

    .global main
main:
    subi r6, 7
_B_main_0:
    li r2, 1
    and r1, r6, r7
    swr r2, r1
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
    clrt
    bf _B_main_6
_B_main_1:
    and r1, r6, r7
    addi r1, 3
    lwr r3, r1
    li r2, 8
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
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
    bf _B_main_4
_B_main_2:
    and r1, r6, r7
    addi r1, 5
    lwr r3, r1
    li r2, 1
    and r2, r2, r2
_L_main_shift_loop_39:
    sub r0, r0, r2
    bf _L_main_shift_end_39
    clrt
    rol r3, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_main_shift_loop_39
_L_main_shift_end_39:
    and r2, r3, r7
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
    and r1, r6, r7
    addi r1, 3
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
    clrt
    bf _B_main_5
_B_main_4:
    and r1, r6, r7
    addi r1, 5
    lwr r2, r1
    clrt
    bf _epi_main
_B_main_5:
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    and r1, r6, r7
    addi r1, 5
    swr r2, r1
    and r1, r6, r7
    addi r1, 6
    lwr r2, r1
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    clrt
    bf _B_main_1
_B_main_6:
    and r1, r6, r7
    lwr r2, r1
    and r1, r6, r7
    addi r1, 5
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    clrt
    bf _B_main_1
_epi_main:
    addi r6, 7
    jalr r0, r5
