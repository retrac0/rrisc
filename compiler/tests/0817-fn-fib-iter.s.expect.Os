; rcc-generated assembly
%define RCC_CODE_BASE 0o1000
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .section text

    .global fib
fib:
    subi r6, 10
    and r1, r6, r7
    swr r2, r1
_B_fib_0:
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
    li r2, 1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    clrt
    bf _B_fib_7
_B_fib_1:
    and r1, r6, r7
    addi r1, 5
    lwr r3, r1
    and r1, r6, r7
    lwr r2, r1
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    rol r2, r0
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    sub r0, r0, r2
    bt _B_fib_2
    clrt
    bf _B_fib_5
_B_fib_2:
    and r1, r6, r7
    addi r1, 7
    lwr r3, r1
    and r1, r6, r7
    addi r1, 8
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
    clrt
    bf _B_fib_3
_B_fib_3:
    and r1, r6, r7
    addi r1, 5
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 9
    swr r2, r1
    clrt
    bf _B_fib_6
_B_fib_5:
    and r1, r6, r7
    addi r1, 7
    lwr r2, r1
    clrt
    bf _epi_fib
_B_fib_6:
    and r1, r6, r7
    addi r1, 9
    lwr r2, r1
    and r1, r6, r7
    addi r1, 5
    swr r2, r1
    and r1, r6, r7
    addi r1, 6
    lwr r2, r1
    and r1, r6, r7
    addi r1, 8
    swr r2, r1
    and r1, r6, r7
    addi r1, 8
    lwr r2, r1
    and r1, r6, r7
    addi r1, 7
    swr r2, r1
    clrt
    bf _B_fib_1
_B_fib_7:
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    and r1, r6, r7
    addi r1, 5
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    and r1, r6, r7
    addi r1, 8
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 7
    swr r2, r1
    clrt
    bf _B_fib_1
_epi_fib:
    addi r6, 10
    jalr r0, r5

    .global main
main:
    subi r6, 1
    swr r5, r6
    subi r6, 1
_B_main_0:
    li r2, 10
    li r1, fib
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
