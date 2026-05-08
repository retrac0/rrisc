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
    sub r0, r0, r2
    bf _L_gcd_mod_done_43
    and r1, r3, r7
    rol r1, r1
    rol r4, r0
    subi r6, 1
    swr r4, r6
    sub r0, r0, r4
    bf _L_gcd_mod_npos_43
    sub r3, r0, r3
_L_gcd_mod_npos_43:
    and r1, r2, r7
    rol r1, r1
    bf _L_gcd_mod_dpos_43
    sub r2, r0, r2
_L_gcd_mod_dpos_43:
    and r4, r3, r7
    and r1, r0, r0
_L_gcd_udiv_loop_59:
    sub r0, r4, r2
    bt _L_gcd_udiv_end_59
    sub r4, r4, r2
    addi r1, 1
    sub r0, r0, r7
    bt _L_gcd_udiv_loop_59
_L_gcd_udiv_end_59:
    and r1, r6, r7
    lwr r1, r1
    addi r6, 1
    sub r0, r0, r1
    bf _L_gcd_mod_rpos_43
    sub r4, r0, r4
_L_gcd_mod_rpos_43:
    and r2, r4, r7
_L_gcd_mod_done_43:
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
