; rcc-generated assembly
%define RCC_CODE_BASE 0o3
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .section data
a:
    .word 5, 10, 15

    .section text

    .global main
main:
    subi r6, 2
_B_main_0:
    li r3, a
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    swr r2, r1
    and r1, r6, r7
    lwr r1, r1
    lwr r2, r1
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
    jalr r0, r5
