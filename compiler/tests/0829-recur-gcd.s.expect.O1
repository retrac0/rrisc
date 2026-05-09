; rcc-generated assembly
%define RCC_CODE_BASE 0o1000
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o3000

    .section text

    .global gcd
gcd:
    subi r6, 1
    swr r5, r6
    subi r6, 5
    and r1, r6, r7
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    swr r3, r1
_B_gcd_0:
    and r1, r6, r7
    addi r1, 1
    lwr r3, r1
    and r2, r0, r0
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_gcd_ne_18
    li r2, 0
_L_gcd_ne_18:
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    sub r0, r0, r2
    bt _B_gcd_1
    clrt
    bf _B_gcd_3
_B_gcd_1:
    and r1, r6, r7
    lwr r2, r1
    clrt
    bf _epi_gcd
_B_gcd_3:
    and r1, r6, r7
    lwr r3, r1
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    li r1, __mod
    jalr r5, r1
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 3
    lwr r3, r1
    li r1, gcd
    jalr r5, r1
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    clrt
    bf _epi_gcd
_epi_gcd:
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
    li r2, 48
    li r3, 18
    li r1, gcd
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
