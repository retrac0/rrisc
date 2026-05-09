; rcc-generated assembly
%define RCC_CODE_BASE 0o1000
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o3000

    .section text

    .global fact
fact:
    subi r6, 1
    swr r5, r6
    subi r6, 5
    and r1, r6, r7
    swr r2, r1
_B_fact_0:
    and r1, r6, r7
    lwr r3, r1
    li r2, 1
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r2, r3
    li r2, 1
    bf _L_fact_ne_16
    li r2, 0
_L_fact_ne_16:
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    sub r0, r0, r2
    bt _B_fact_1
    clrt
    bf _B_fact_3
_B_fact_1:
    li r2, 1
    clrt
    bf _epi_fact
_B_fact_3:
    and r1, r6, r7
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    li r1, fact
    jalr r5, r1
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    and r1, r6, r7
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
    bf _epi_fact
_epi_fact:
    addi r6, 5
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

    .global main
main:
    subi r6, 1
    swr r5, r6
    subi r6, 1
_B_main_0:
    li r2, 5
    li r1, fact
    jalr r5, r1
    and r1, r6, r7
    swr r2, r1
    and r1, r6, r7
    lwr r2, r1
    clrt
    bf _epi_main
_epi_main:
    addi r6, 1
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

; rcc: lib/librcc.s (integer multiply/divide/modulo)
%include "librcc.s"
