; rcc-generated assembly
%define RCC_CODE_BASE 0o1000
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .section text

    .global abs_val
abs_val:
    subi r6, 3
    and r1, r6, r7
    swr r2, r1
_B_abs_val_0:
    and r1, r6, r7
    lwr r3, r1
    and r2, r0, r0
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
    bt _B_abs_val_1
    clrt
    bf _B_abs_val_3
_B_abs_val_1:
    and r3, r0, r0
    and r1, r6, r7
    lwr r2, r1
    sub r2, r3, r2
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    clrt
    bf _epi_abs_val
_B_abs_val_3:
    and r1, r6, r7
    lwr r2, r1
    clrt
    bf _epi_abs_val
_epi_abs_val:
    addi r6, 3
    jalr r0, r5

    .global main
main:
    subi r6, 1
    swr r5, r6
    subi r6, 4
_B_main_0:
    li r2, 4089
    and r1, r6, r7
    swr r2, r1
    and r1, r6, r7
    lwr r2, r1
    li r1, abs_val
    jalr r5, r1
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
    li r2, 3
    li r1, abs_val
    jalr r5, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r3, r1
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    clrt
    bf _epi_main
_epi_main:
    addi r6, 4
    lwr r5, r6
    addi r6, 1
    jalr r0, r5
