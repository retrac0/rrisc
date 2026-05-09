; rcc-generated assembly
%define RCC_CODE_BASE 0o1000
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .section text

    .global area
area:
    subi r6, 1
    swr r5, r6
    subi r6, 5
    and r1, r6, r7
    swr r2, r1
_B_area_0:
    and r1, r6, r7
    lwr r2, r1
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
    and r1, r6, r7
    and r3, r1, r7
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r3, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    li r1, __mul
    jalr r5, r1
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    clrt
    bf _epi_area
_epi_area:
    addi r6, 5
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

    .global main
main:
    subi r6, 1
    swr r5, r6
    subi r6, 4
_B_main_0:
    li r2, 6
    and r1, r6, r7
    swr r2, r1
    and r1, r6, r7
    and r3, r1, r7
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    li r2, 7
    and r1, r6, r7
    addi r1, 2
    lwr r1, r1
    swr r2, r1
    and r1, r6, r7
    and r2, r1, r7
    li r1, area
    jalr r5, r1
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

; rcc: lib/librcc.s (integer multiply/divide/modulo)
%include "librcc.s"
