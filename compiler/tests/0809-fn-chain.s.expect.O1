; rcc-generated assembly
%define RCC_CODE_BASE 0o1000
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .section text

    .global dbl
dbl:
    subi r6, 2
    and r1, r6, r7
    swr r2, r1
_B_dbl_0:
    and r1, r6, r7
    lwr r3, r1
    li r2, 1
    and r2, r2, r2
_L_dbl_shift_loop_10:
    sub r0, r0, r2
    bf _L_dbl_shift_end_10
    clrt
    rol r3, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_dbl_shift_loop_10
_L_dbl_shift_end_10:
    and r2, r3, r7
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    clrt
    bf _epi_dbl
_epi_dbl:
    addi r6, 2
    jalr r0, r5

    .global tri
tri:
    subi r6, 2
    and r1, r6, r7
    swr r2, r1
_B_tri_0:
    and r1, r6, r7
    lwr r3, r1
    and r4, r3, r7
    li r2, 1
    and r2, r2, r2
_L_tri_shift_loop_11:
    sub r0, r0, r2
    bf _L_tri_shift_end_11
    clrt
    rol r3, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_tri_shift_loop_11
_L_tri_shift_end_11:
    and r2, r3, r7
    add r2, r4, r2
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    clrt
    bf _epi_tri
_epi_tri:
    addi r6, 2
    jalr r0, r5

    .global main
main:
    subi r6, 1
    swr r5, r6
    subi r6, 2
_B_main_0:
    li r2, 4
    li r1, tri
    jalr r5, r1
    and r1, r6, r7
    swr r2, r1
    and r1, r6, r7
    lwr r2, r1
    li r1, dbl
    jalr r5, r1
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    clrt
    bf _epi_main
_epi_main:
    addi r6, 2
    lwr r5, r6
    addi r6, 1
    jalr r0, r5
