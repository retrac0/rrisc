; rcc-generated assembly
%define RCC_CODE_BASE 0o100
%define RCC_DATA_BASE 0o6600
%define RCC_STACK_TOP 0o7770

    .section text

    .global putchar
putchar:
    subi r6, 9
    and r1, r6, r7
    swr r2, r1
_B_putchar_0:
;; int* rdy = ...
    li r2, 4088
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
;; int* buf = ...
    li r2, 4090
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
;; while (!*rdy)
    clrt
    bf _B_putchar_6
_B_putchar_1:
    and r1, r6, r7
    addi r1, 1
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    sub r0, r0, r2
    bt _L_putchar_not_zero_32
    li r2, 1
    sub r0, r0, r7
    bt _L_putchar_not_end_32
_L_putchar_not_zero_32:
    li r2, 0
_L_putchar_not_end_32:
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    sub r0, r0, r2
    bt _B_putchar_2
    clrt
    bf _B_putchar_4
_B_putchar_2:
    clrt
    bf _B_putchar_5
_B_putchar_4:
;; *buf=c
    and r1, r6, r7
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r1, r1
    swr r2, r1
    clrt
    bf _epi_putchar
_B_putchar_5:
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    and r1, r6, r7
    addi r1, 5
    swr r2, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
    clrt
    bf _B_putchar_1
_B_putchar_6:
    and r1, r6, r7
    addi r1, 7
    lwr r2, r1
    and r1, r6, r7
    addi r1, 5
    swr r2, r1
    and r1, r6, r7
    addi r1, 8
    lwr r2, r1
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
    clrt
    bf _B_putchar_1
_epi_putchar:
    addi r6, 9
    jalr r0, r5

    .global getchar
getchar:
    subi r6, 9
_B_getchar_0:
;; int* rdy = ...
    li r2, 4089
    and r1, r6, r7
    swr r2, r1
;; int* buf = ...
    li r2, 4091
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
;; while (!*rdy)
    clrt
    bf _B_getchar_6
_B_getchar_1:
    and r1, r6, r7
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    sub r0, r0, r2
    bt _L_getchar_not_zero_28
    li r2, 1
    sub r0, r0, r7
    bt _L_getchar_not_end_28
_L_getchar_not_zero_28:
    li r2, 0
_L_getchar_not_end_28:
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    sub r0, r0, r2
    bt _B_getchar_2
    clrt
    bf _B_getchar_4
_B_getchar_2:
    clrt
    bf _B_getchar_5
_B_getchar_4:
;; return *buf
    and r1, r6, r7
    addi r1, 1
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    clrt
    bf _epi_getchar
_B_getchar_5:
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
    addi r1, 6
    swr r2, r1
    clrt
    bf _B_getchar_1
_B_getchar_6:
    and r1, r6, r7
    addi r1, 7
    lwr r2, r1
    and r1, r6, r7
    addi r1, 5
    swr r2, r1
    and r1, r6, r7
    addi r1, 8
    lwr r2, r1
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
    clrt
    bf _B_getchar_1
_epi_getchar:
    addi r6, 9
    jalr r0, r5

    .global puts
puts:
    subi r6, 1
    swr r5, r6
    subi r6, 19
    and r1, r6, r7
    swr r2, r1
_B_puts_0:
;; while (*s!=0)
    clrt
    bf _B_puts_6
_B_puts_1:
    and r1, r6, r7
    addi r1, 2
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r3, r1
    and r2, r0, r0
    sub r1, r3, r2
    sub r0, r0, r1
    rol r2, r0
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    sub r0, r0, r2
    bt _B_puts_2
    clrt
    bf _B_puts_4
_B_puts_2:
;; putchar(*s)
    and r1, r6, r7
    addi r1, 2
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    li r1, putchar
    jalr r5, r1
    and r1, r6, r7
    addi r1, 5
    swr r2, r1
;; s=s+1
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
    and r1, r6, r7
    addi r1, 6
    lwr r2, r1
    and r1, r6, r7
    addi r1, 7
    swr r2, r1
    clrt
    bf _B_puts_5
_B_puts_4:
;; putchar(10)
    li r2, 10
    li r1, putchar
    jalr r5, r1
    and r1, r6, r7
    addi r1, 8
    swr r2, r1
    clrt
    bf _epi_puts
_B_puts_5:
    and r1, r6, r7
    addi r1, 7
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    and r1, r6, r7
    addi r1, 6
    lwr r2, r1
    and r1, r6, r7
    addi r1, 9
    swr r2, r1
    and r1, r6, r7
    addi r1, 5
    lwr r2, r1
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    and r1, r6, r7
    addi r1, 11
    swr r2, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    and r1, r6, r7
    addi r1, 12
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 13
    swr r2, r1
    clrt
    bf _B_puts_1
_B_puts_6:
    and r1, r6, r7
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    and r1, r6, r7
    addi r1, 14
    lwr r2, r1
    and r1, r6, r7
    addi r1, 9
    swr r2, r1
    and r1, r6, r7
    addi r1, 15
    lwr r2, r1
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    and r1, r6, r7
    addi r1, 16
    lwr r2, r1
    and r1, r6, r7
    addi r1, 11
    swr r2, r1
    and r1, r6, r7
    addi r1, 17
    lwr r2, r1
    and r1, r6, r7
    addi r1, 12
    swr r2, r1
    and r1, r6, r7
    addi r1, 18
    lwr r2, r1
    and r1, r6, r7
    addi r1, 13
    swr r2, r1
    clrt
    bf _B_puts_1
_epi_puts:
    addi r6, 19
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

    .global gets
gets:
    subi r6, 1
    swr r5, r6
    subi r6, 26
    and r1, r6, r7
    swr r2, r1
_B_gets_0:
;; int* p = ...
    and r1, r6, r7
    lwr r2, r1
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
;; while (1)
    clrt
    bf _B_gets_12
_B_gets_1:
    li r2, 1
    sub r0, r0, r2
    bt _B_gets_2
    clrt
    bf _B_gets_15
_B_gets_2:
;; int ch = ...
    li r1, getchar
    jalr r5, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
;; if (ch==10)
    and r1, r6, r7
    addi r1, 3
    lwr r3, r1
    li r2, 10
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_gets_ne_44
    li r2, 0
_L_gets_ne_44:
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    sub r0, r0, r2
    bt _B_gets_3
    clrt
    bf _B_gets_5
_B_gets_3:
;; break
    clrt
    bf _B_gets_14
_B_gets_5:
;; if (ch==0)
    and r1, r6, r7
    addi r1, 3
    lwr r3, r1
    and r2, r0, r0
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_gets_ne_70
    li r2, 0
_L_gets_ne_70:
    and r1, r6, r7
    addi r1, 5
    swr r2, r1
    and r1, r6, r7
    addi r1, 5
    lwr r2, r1
    sub r0, r0, r2
    bt _B_gets_6
    clrt
    bf _B_gets_8
_B_gets_6:
;; break
    clrt
    bf _B_gets_13
_B_gets_8:
;; *p++=ch
    and r1, r6, r7
    addi r1, 7
    lwr r2, r1
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
    and r1, r6, r7
    addi r1, 7
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 8
    swr r2, r1
    and r1, r6, r7
    addi r1, 8
    lwr r2, r1
    and r1, r6, r7
    addi r1, 9
    swr r2, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    and r1, r6, r7
    addi r1, 6
    lwr r1, r1
    swr r2, r1
    clrt
    bf _B_gets_11
_B_gets_10:
;; *p=0
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 7
    lwr r1, r1
    swr r2, r1
;; return buf
    and r1, r6, r7
    lwr r2, r1
    clrt
    bf _epi_gets
_B_gets_11:
    and r1, r6, r7
    addi r1, 9
    lwr r2, r1
    and r1, r6, r7
    addi r1, 7
    swr r2, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    and r1, r6, r7
    addi r1, 8
    lwr r2, r1
    and r1, r6, r7
    addi r1, 11
    swr r2, r1
    and r1, r6, r7
    addi r1, 6
    lwr r2, r1
    and r1, r6, r7
    addi r1, 12
    swr r2, r1
    and r1, r6, r7
    addi r1, 5
    lwr r2, r1
    and r1, r6, r7
    addi r1, 13
    swr r2, r1
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    and r1, r6, r7
    addi r1, 14
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    and r1, r6, r7
    addi r1, 15
    swr r2, r1
    clrt
    bf _B_gets_1
_B_gets_12:
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 7
    swr r2, r1
    and r1, r6, r7
    addi r1, 16
    lwr r2, r1
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    and r1, r6, r7
    addi r1, 17
    lwr r2, r1
    and r1, r6, r7
    addi r1, 11
    swr r2, r1
    and r1, r6, r7
    addi r1, 18
    lwr r2, r1
    and r1, r6, r7
    addi r1, 12
    swr r2, r1
    and r1, r6, r7
    addi r1, 19
    lwr r2, r1
    and r1, r6, r7
    addi r1, 13
    swr r2, r1
    and r1, r6, r7
    addi r1, 20
    lwr r2, r1
    and r1, r6, r7
    addi r1, 14
    swr r2, r1
    and r1, r6, r7
    addi r1, 21
    lwr r2, r1
    and r1, r6, r7
    addi r1, 15
    swr r2, r1
    clrt
    bf _B_gets_1
_B_gets_13:
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    and r1, r6, r7
    addi r1, 22
    swr r2, r1
    and r1, r6, r7
    addi r1, 5
    lwr r2, r1
    and r1, r6, r7
    addi r1, 23
    swr r2, r1
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    and r1, r6, r7
    addi r1, 24
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    and r1, r6, r7
    addi r1, 25
    swr r2, r1
    clrt
    bf _B_gets_10
_B_gets_14:
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    and r1, r6, r7
    addi r1, 22
    swr r2, r1
    and r1, r6, r7
    addi r1, 13
    lwr r2, r1
    and r1, r6, r7
    addi r1, 23
    swr r2, r1
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    and r1, r6, r7
    addi r1, 24
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    and r1, r6, r7
    addi r1, 25
    swr r2, r1
    clrt
    bf _B_gets_10
_B_gets_15:
    and r1, r6, r7
    addi r1, 10
    lwr r2, r1
    and r1, r6, r7
    addi r1, 22
    swr r2, r1
    and r1, r6, r7
    addi r1, 13
    lwr r2, r1
    and r1, r6, r7
    addi r1, 23
    swr r2, r1
    and r1, r6, r7
    addi r1, 14
    lwr r2, r1
    and r1, r6, r7
    addi r1, 24
    swr r2, r1
    and r1, r6, r7
    addi r1, 15
    lwr r2, r1
    and r1, r6, r7
    addi r1, 25
    swr r2, r1
    clrt
    bf _B_gets_10
_epi_gets:
    addi r6, 26
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

    .global exit
exit:
    subi r6, 1
_B_exit_0:
;; (void)code
    halt
    clrt
    bf _epi_exit
_epi_exit:
    addi r6, 1
    jalr r0, r5

    .global isdigitch
isdigitch:
    subi r6, 9
    and r1, r6, r7
    swr r2, r1
_B_isdigitch_0:
;; return c>=48&&c<=57
    and r1, r6, r7
    lwr r3, r1
    li r2, 48
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    li r2, 1
    bf _L_isdigitch_ne_15
    li r2, 0
_L_isdigitch_ne_15:
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    sub r0, r0, r2
    bt _B_isdigitch_1
    clrt
    bf _B_isdigitch_7
_B_isdigitch_1:
    and r1, r6, r7
    lwr r3, r1
    li r2, 57
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r2, r3
    li r2, 1
    bf _L_isdigitch_ne_37
    li r2, 0
_L_isdigitch_ne_37:
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    sub r0, r0, r2
    bt _B_isdigitch_2
    clrt
    bf _B_isdigitch_6
_B_isdigitch_2:
    li r2, 1
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    clrt
    bf _B_isdigitch_9
_B_isdigitch_4:
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
    clrt
    bf _B_isdigitch_8
_B_isdigitch_5:
    and r1, r6, r7
    addi r1, 5
    lwr r2, r1
    clrt
    bf _epi_isdigitch
_B_isdigitch_6:
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
    clrt
    bf _B_isdigitch_4
_B_isdigitch_7:
    and r1, r6, r7
    addi r1, 7
    lwr r2, r1
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
    clrt
    bf _B_isdigitch_4
_B_isdigitch_8:
    and r1, r6, r7
    addi r1, 6
    lwr r2, r1
    and r1, r6, r7
    addi r1, 8
    swr r2, r1
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    and r1, r6, r7
    addi r1, 5
    swr r2, r1
    clrt
    bf _B_isdigitch_5
_B_isdigitch_9:
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    and r1, r6, r7
    addi r1, 8
    swr r2, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    and r1, r6, r7
    addi r1, 5
    swr r2, r1
    clrt
    bf _B_isdigitch_5
_epi_isdigitch:
    addi r6, 9
    jalr r0, r5

    .global emit_err
emit_err:
    subi r6, 1
    swr r5, r6
    subi r6, 4
_B_emit_err_0:
;; putchar(36)
    li r2, 36
    li r1, putchar
    jalr r5, r1
    and r1, r6, r7
    swr r2, r1
;; putchar(36)
    li r2, 36
    li r1, putchar
    jalr r5, r1
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
;; putchar(36)
    li r2, 36
    li r1, putchar
    jalr r5, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
;; putchar(10)
    li r2, 10
    li r1, putchar
    jalr r5, r1
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    clrt
    bf _epi_emit_err
_epi_emit_err:
    addi r6, 4
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

    .global main
main:
    subi r6, 1
    swr r5, r6
    li r1, 1928
    sub r6, r6, r1
_B_main_0:
;; int[64] buf
;; alloclocal buf
;; int[8] sbuf
;; alloclocal sbuf
;; int* p
;; int a
;; int b
;; int r
;; int neg
;; int val
;; while (1)
    clrt
    bf _B_main_121
_B_main_1:
    li r2, 1
    sub r0, r0, r2
    bt _B_main_2
    clrt
    bf _B_main_119
_B_main_2:
;; gets(buf)
    and r1, r6, r7
    addi r1, 1
    and r2, r1, r7
    li r1, gets
    jalr r5, r1
    and r1, r6, r7
    swr r2, r1
;; p=buf
    and r1, r6, r7
    addi r1, 1
    and r2, r1, r7
    li r1, 65
    add r1, r1, r6
    swr r2, r1
;; while (*p!=0)
    clrt
    bf _B_main_123
_B_main_3:
    li r1, 67
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 66
    add r1, r1, r6
    swr r2, r1
    li r1, 66
    add r1, r1, r6
    lwr r3, r1
    and r2, r0, r0
    sub r1, r3, r2
    sub r0, r0, r1
    rol r2, r0
    li r1, 68
    add r1, r1, r6
    swr r2, r1
    li r1, 68
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_4
    clrt
    bf _B_main_187
_B_main_4:
;; while (*p==32||*p==9)
    clrt
    bf _B_main_125
_B_main_5:
    li r1, 70
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 69
    add r1, r1, r6
    swr r2, r1
    li r1, 69
    add r1, r1, r6
    lwr r3, r1
    li r2, 32
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_89
    li r2, 0
_L_main_ne_89:
    li r1, 71
    add r1, r1, r6
    swr r2, r1
    li r1, 71
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_127
    clrt
    bf _B_main_6
_B_main_6:
    li r1, 70
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 72
    add r1, r1, r6
    swr r2, r1
    li r1, 72
    add r1, r1, r6
    lwr r3, r1
    li r2, 9
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_117
    li r2, 0
_L_main_ne_117:
    li r1, 73
    add r1, r1, r6
    swr r2, r1
    li r1, 73
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_126
    clrt
    bf _B_main_7
_B_main_7:
    and r2, r0, r0
    li r1, 74
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_129
_B_main_9:
    li r2, 1
    li r1, 75
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_128
_B_main_10:
    li r1, 76
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_11
    clrt
    bf _B_main_13
_B_main_11:
;; p++
    li r1, 70
    add r1, r1, r6
    lwr r2, r1
    li r1, 77
    add r1, r1, r6
    swr r2, r1
    li r1, 70
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 78
    add r1, r1, r6
    swr r2, r1
    li r1, 78
    add r1, r1, r6
    lwr r2, r1
    li r1, 79
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_124
_B_main_13:
;; if (*p==0)
    li r1, 70
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 80
    add r1, r1, r6
    swr r2, r1
    li r1, 80
    add r1, r1, r6
    lwr r3, r1
    and r2, r0, r0
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_192
    li r2, 0
_L_main_ne_192:
    li r1, 81
    add r1, r1, r6
    swr r2, r1
    li r1, 81
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_14
    clrt
    bf _B_main_16
_B_main_14:
;; break
    clrt
    bf _B_main_186
_B_main_16:
;; if (isdigitch(*p)||*p==45&&isdigitch(*p+1))
    li r1, 70
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 82
    add r1, r1, r6
    swr r2, r1
    li r1, 82
    add r1, r1, r6
    lwr r2, r1
    li r1, isdigitch
    jalr r5, r1
    li r1, 83
    add r1, r1, r6
    swr r2, r1
    li r1, 83
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_135
    clrt
    bf _B_main_17
_B_main_17:
    li r1, 70
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 84
    add r1, r1, r6
    swr r2, r1
    li r1, 84
    add r1, r1, r6
    lwr r3, r1
    li r2, 45
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_248
    li r2, 0
_L_main_ne_248:
    li r1, 85
    add r1, r1, r6
    swr r2, r1
    li r1, 85
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_18
    clrt
    bf _B_main_131
_B_main_18:
    li r1, 70
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 86
    add r1, r1, r6
    swr r2, r1
    li r1, 86
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 87
    add r1, r1, r6
    swr r2, r1
    li r1, 87
    add r1, r1, r6
    lwr r2, r1
    li r1, isdigitch
    jalr r5, r1
    li r1, 88
    add r1, r1, r6
    swr r2, r1
    li r1, 88
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_19
    clrt
    bf _B_main_130
_B_main_19:
    li r2, 1
    li r1, 89
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_133
_B_main_21:
    and r2, r0, r0
    li r1, 90
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_132
_B_main_22:
    li r1, 91
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_134
    clrt
    bf _B_main_23
_B_main_23:
    and r2, r0, r0
    li r1, 92
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_137
_B_main_25:
    li r2, 1
    li r1, 93
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_136
_B_main_26:
    li r1, 94
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_27
    clrt
    bf _B_main_41
_B_main_27:
;; neg=0
    and r2, r0, r0
    li r1, 95
    add r1, r1, r6
    swr r2, r1
;; if (*p==45)
    li r1, 70
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 96
    add r1, r1, r6
    swr r2, r1
    li r1, 96
    add r1, r1, r6
    lwr r3, r1
    li r2, 45
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_357
    li r2, 0
_L_main_ne_357:
    li r1, 97
    add r1, r1, r6
    swr r2, r1
    li r1, 97
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_28
    clrt
    bf _B_main_139
_B_main_28:
;; neg=1
    li r2, 1
    li r1, 98
    add r1, r1, r6
    swr r2, r1
;; p++
    li r1, 70
    add r1, r1, r6
    lwr r2, r1
    li r1, 99
    add r1, r1, r6
    swr r2, r1
    li r1, 70
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 100
    add r1, r1, r6
    swr r2, r1
    li r1, 100
    add r1, r1, r6
    lwr r2, r1
    li r1, 101
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_138
_B_main_29:
;; val=0
    and r2, r0, r0
    li r1, 102
    add r1, r1, r6
    swr r2, r1
;; while (isdigitch(*p))
    clrt
    bf _B_main_141
_B_main_30:
    li r1, 104
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 103
    add r1, r1, r6
    swr r2, r1
    li r1, 103
    add r1, r1, r6
    lwr r2, r1
    li r1, isdigitch
    jalr r5, r1
    li r1, 105
    add r1, r1, r6
    swr r2, r1
    li r1, 105
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_31
    clrt
    bf _B_main_33
_B_main_31:
;; val=val*10+*p-48
    li r1, 107
    add r1, r1, r6
    lwr r3, r1
    li r2, 10
    li r1, __mul
    jalr r5, r1
    li r1, 106
    add r1, r1, r6
    swr r2, r1
    li r1, 104
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 108
    add r1, r1, r6
    swr r2, r1
    li r1, 108
    add r1, r1, r6
    lwr r3, r1
    li r2, 48
    sub r2, r3, r2
    li r1, 109
    add r1, r1, r6
    swr r2, r1
    li r1, 106
    add r1, r1, r6
    lwr r3, r1
    li r1, 109
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 110
    add r1, r1, r6
    swr r2, r1
    li r1, 110
    add r1, r1, r6
    lwr r2, r1
    li r1, 111
    add r1, r1, r6
    swr r2, r1
;; p++
    li r1, 104
    add r1, r1, r6
    lwr r2, r1
    li r1, 112
    add r1, r1, r6
    swr r2, r1
    li r1, 104
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 113
    add r1, r1, r6
    swr r2, r1
    li r1, 113
    add r1, r1, r6
    lwr r2, r1
    li r1, 114
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_140
_B_main_33:
;; if (neg)
    li r1, 115
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_34
    clrt
    bf _B_main_143
_B_main_34:
;; val=-val
    li r1, 107
    add r1, r1, r6
    lwr r2, r1
    sub r2, r0, r2
    li r1, 116
    add r1, r1, r6
    swr r2, r1
    li r1, 116
    add r1, r1, r6
    lwr r2, r1
    li r1, 117
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_142
_B_main_35:
;; if (sp>=16)
    li r1, sp
    lwr r2, r1
    li r1, 118
    add r1, r1, r6
    swr r2, r1
    li r1, 118
    add r1, r1, r6
    lwr r3, r1
    li r2, 16
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    li r2, 1
    bf _L_main_ne_538
    li r2, 0
_L_main_ne_538:
    li r1, 119
    add r1, r1, r6
    swr r2, r1
    li r1, 119
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_36
    clrt
    bf _B_main_38
_B_main_36:
;; emit_err()
    li r1, emit_err
    jalr r5, r1
    li r1, 120
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_145
_B_main_38:
;; stk[sp]=val
    li r1, sp
    lwr r2, r1
    li r1, 121
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 121
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 122
    add r1, r1, r6
    swr r2, r1
    li r1, 123
    add r1, r1, r6
    lwr r2, r1
    li r1, 122
    add r1, r1, r6
    lwr r1, r1
    swr r2, r1
;; sp++
    li r1, sp
    lwr r2, r1
    li r1, 124
    add r1, r1, r6
    swr r2, r1
    li r1, 124
    add r1, r1, r6
    lwr r2, r1
    li r1, 125
    add r1, r1, r6
    swr r2, r1
    li r1, 124
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 126
    add r1, r1, r6
    swr r2, r1
    li r1, 126
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
    clrt
    bf _B_main_144
_B_main_39:
    clrt
    bf _B_main_185
_B_main_41:
;; if (*p==43)
    li r1, 70
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 127
    add r1, r1, r6
    swr r2, r1
    li r1, 127
    add r1, r1, r6
    lwr r3, r1
    li r2, 43
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_628
    li r2, 0
_L_main_ne_628:
    lui r1, 2
    add r1, r1, r6
    swr r2, r1
    lui r1, 2
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_42
    clrt
    bf _B_main_48
_B_main_42:
;; if (sp<2)
    li r1, sp
    lwr r2, r1
    li r1, 129
    add r1, r1, r6
    swr r2, r1
    li r1, 129
    add r1, r1, r6
    lwr r3, r1
    li r2, 2
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    rol r2, r0
    li r1, 130
    add r1, r1, r6
    swr r2, r1
    li r1, 130
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_43
    clrt
    bf _B_main_45
_B_main_43:
;; emit_err()
    li r1, emit_err
    jalr r5, r1
    li r1, 131
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_147
_B_main_45:
;; b=stk[sp-1]
    li r1, sp
    lwr r2, r1
    li r1, 132
    add r1, r1, r6
    swr r2, r1
    li r1, 132
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    li r1, 133
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 133
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 134
    add r1, r1, r6
    swr r2, r1
    li r1, 134
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 135
    add r1, r1, r6
    swr r2, r1
    li r1, 135
    add r1, r1, r6
    lwr r2, r1
    li r1, 136
    add r1, r1, r6
    swr r2, r1
;; a=stk[sp-2]
    li r1, sp
    lwr r2, r1
    li r1, 137
    add r1, r1, r6
    swr r2, r1
    li r1, 137
    add r1, r1, r6
    lwr r3, r1
    li r2, 2
    sub r2, r3, r2
    li r1, 138
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 138
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 139
    add r1, r1, r6
    swr r2, r1
    li r1, 139
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 140
    add r1, r1, r6
    swr r2, r1
    li r1, 140
    add r1, r1, r6
    lwr r2, r1
    li r1, 141
    add r1, r1, r6
    swr r2, r1
;; sp-=2
    li r1, sp
    lwr r2, r1
    li r1, 142
    add r1, r1, r6
    swr r2, r1
    li r1, 142
    add r1, r1, r6
    lwr r3, r1
    li r2, 2
    sub r2, r3, r2
    li r1, 143
    add r1, r1, r6
    swr r2, r1
    li r1, 143
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
;; r=a+b
    li r1, 141
    add r1, r1, r6
    lwr r3, r1
    li r1, 136
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 144
    add r1, r1, r6
    swr r2, r1
    li r1, 144
    add r1, r1, r6
    lwr r2, r1
    li r1, 145
    add r1, r1, r6
    swr r2, r1
;; stk[sp]=r
    li r1, sp
    lwr r2, r1
    li r1, 146
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 146
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 147
    add r1, r1, r6
    swr r2, r1
    li r1, 145
    add r1, r1, r6
    lwr r2, r1
    li r1, 147
    add r1, r1, r6
    lwr r1, r1
    swr r2, r1
;; sp++
    li r1, sp
    lwr r2, r1
    li r1, 148
    add r1, r1, r6
    swr r2, r1
    li r1, 148
    add r1, r1, r6
    lwr r2, r1
    li r1, 149
    add r1, r1, r6
    swr r2, r1
    li r1, 148
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 150
    add r1, r1, r6
    swr r2, r1
    li r1, 150
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
    clrt
    bf _B_main_146
_B_main_46:
;; p++
    li r1, 70
    add r1, r1, r6
    lwr r2, r1
    li r1, 151
    add r1, r1, r6
    swr r2, r1
    li r1, 70
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 152
    add r1, r1, r6
    swr r2, r1
    li r1, 152
    add r1, r1, r6
    lwr r2, r1
    li r1, 153
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_183
_B_main_48:
;; if (*p==45)
    li r1, 70
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 154
    add r1, r1, r6
    swr r2, r1
    li r1, 154
    add r1, r1, r6
    lwr r3, r1
    li r2, 45
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_871
    li r2, 0
_L_main_ne_871:
    li r1, 155
    add r1, r1, r6
    swr r2, r1
    li r1, 155
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_49
    clrt
    bf _B_main_55
_B_main_49:
;; if (sp<2)
    li r1, sp
    lwr r2, r1
    li r1, 156
    add r1, r1, r6
    swr r2, r1
    li r1, 156
    add r1, r1, r6
    lwr r3, r1
    li r2, 2
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    rol r2, r0
    li r1, 157
    add r1, r1, r6
    swr r2, r1
    li r1, 157
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_50
    clrt
    bf _B_main_52
_B_main_50:
;; emit_err()
    li r1, emit_err
    jalr r5, r1
    li r1, 158
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_149
_B_main_52:
;; b=stk[sp-1]
    li r1, sp
    lwr r2, r1
    li r1, 159
    add r1, r1, r6
    swr r2, r1
    li r1, 159
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    li r1, 160
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 160
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 161
    add r1, r1, r6
    swr r2, r1
    li r1, 161
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 162
    add r1, r1, r6
    swr r2, r1
    li r1, 162
    add r1, r1, r6
    lwr r2, r1
    li r1, 163
    add r1, r1, r6
    swr r2, r1
;; a=stk[sp-2]
    li r1, sp
    lwr r2, r1
    li r1, 164
    add r1, r1, r6
    swr r2, r1
    li r1, 164
    add r1, r1, r6
    lwr r3, r1
    li r2, 2
    sub r2, r3, r2
    li r1, 165
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 165
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 166
    add r1, r1, r6
    swr r2, r1
    li r1, 166
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 167
    add r1, r1, r6
    swr r2, r1
    li r1, 167
    add r1, r1, r6
    lwr r2, r1
    li r1, 168
    add r1, r1, r6
    swr r2, r1
;; sp-=2
    li r1, sp
    lwr r2, r1
    li r1, 169
    add r1, r1, r6
    swr r2, r1
    li r1, 169
    add r1, r1, r6
    lwr r3, r1
    li r2, 2
    sub r2, r3, r2
    li r1, 170
    add r1, r1, r6
    swr r2, r1
    li r1, 170
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
;; r=a-b
    li r1, 168
    add r1, r1, r6
    lwr r3, r1
    li r1, 163
    add r1, r1, r6
    lwr r2, r1
    sub r2, r3, r2
    li r1, 171
    add r1, r1, r6
    swr r2, r1
    li r1, 171
    add r1, r1, r6
    lwr r2, r1
    li r1, 172
    add r1, r1, r6
    swr r2, r1
;; stk[sp]=r
    li r1, sp
    lwr r2, r1
    li r1, 173
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 173
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 174
    add r1, r1, r6
    swr r2, r1
    li r1, 172
    add r1, r1, r6
    lwr r2, r1
    li r1, 174
    add r1, r1, r6
    lwr r1, r1
    swr r2, r1
;; sp++
    li r1, sp
    lwr r2, r1
    li r1, 175
    add r1, r1, r6
    swr r2, r1
    li r1, 175
    add r1, r1, r6
    lwr r2, r1
    li r1, 176
    add r1, r1, r6
    swr r2, r1
    li r1, 175
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 177
    add r1, r1, r6
    swr r2, r1
    li r1, 177
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
    clrt
    bf _B_main_148
_B_main_53:
;; p++
    li r1, 70
    add r1, r1, r6
    lwr r2, r1
    li r1, 178
    add r1, r1, r6
    swr r2, r1
    li r1, 70
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 179
    add r1, r1, r6
    swr r2, r1
    li r1, 179
    add r1, r1, r6
    lwr r2, r1
    li r1, 180
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_181
_B_main_55:
;; if (*p==42)
    li r1, 70
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 181
    add r1, r1, r6
    swr r2, r1
    li r1, 181
    add r1, r1, r6
    lwr r3, r1
    li r2, 42
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_1114
    li r2, 0
_L_main_ne_1114:
    li r1, 182
    add r1, r1, r6
    swr r2, r1
    li r1, 182
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_56
    clrt
    bf _B_main_62
_B_main_56:
;; if (sp<2)
    li r1, sp
    lwr r2, r1
    li r1, 183
    add r1, r1, r6
    swr r2, r1
    li r1, 183
    add r1, r1, r6
    lwr r3, r1
    li r2, 2
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    rol r2, r0
    li r1, 184
    add r1, r1, r6
    swr r2, r1
    li r1, 184
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_57
    clrt
    bf _B_main_59
_B_main_57:
;; emit_err()
    li r1, emit_err
    jalr r5, r1
    li r1, 185
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_151
_B_main_59:
;; b=stk[sp-1]
    li r1, sp
    lwr r2, r1
    li r1, 186
    add r1, r1, r6
    swr r2, r1
    li r1, 186
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    li r1, 187
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 187
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 188
    add r1, r1, r6
    swr r2, r1
    li r1, 188
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 189
    add r1, r1, r6
    swr r2, r1
    li r1, 189
    add r1, r1, r6
    lwr r2, r1
    li r1, 190
    add r1, r1, r6
    swr r2, r1
;; a=stk[sp-2]
    li r1, sp
    lwr r2, r1
    li r1, 191
    add r1, r1, r6
    swr r2, r1
    li r1, 191
    add r1, r1, r6
    lwr r3, r1
    li r2, 2
    sub r2, r3, r2
    lui r1, 3
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    lui r1, 3
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 193
    add r1, r1, r6
    swr r2, r1
    li r1, 193
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 194
    add r1, r1, r6
    swr r2, r1
    li r1, 194
    add r1, r1, r6
    lwr r2, r1
    li r1, 195
    add r1, r1, r6
    swr r2, r1
;; sp-=2
    li r1, sp
    lwr r2, r1
    li r1, 196
    add r1, r1, r6
    swr r2, r1
    li r1, 196
    add r1, r1, r6
    lwr r3, r1
    li r2, 2
    sub r2, r3, r2
    li r1, 197
    add r1, r1, r6
    swr r2, r1
    li r1, 197
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
;; r=a*b
    li r1, 195
    add r1, r1, r6
    lwr r3, r1
    li r1, 190
    add r1, r1, r6
    lwr r2, r1
    li r1, __mul
    jalr r5, r1
    li r1, 198
    add r1, r1, r6
    swr r2, r1
    li r1, 198
    add r1, r1, r6
    lwr r2, r1
    li r1, 199
    add r1, r1, r6
    swr r2, r1
;; stk[sp]=r
    li r1, sp
    lwr r2, r1
    li r1, 200
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 200
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 201
    add r1, r1, r6
    swr r2, r1
    li r1, 199
    add r1, r1, r6
    lwr r2, r1
    li r1, 201
    add r1, r1, r6
    lwr r1, r1
    swr r2, r1
;; sp++
    li r1, sp
    lwr r2, r1
    li r1, 202
    add r1, r1, r6
    swr r2, r1
    li r1, 202
    add r1, r1, r6
    lwr r2, r1
    li r1, 203
    add r1, r1, r6
    swr r2, r1
    li r1, 202
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 204
    add r1, r1, r6
    swr r2, r1
    li r1, 204
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
    clrt
    bf _B_main_150
_B_main_60:
;; p++
    li r1, 70
    add r1, r1, r6
    lwr r2, r1
    li r1, 205
    add r1, r1, r6
    swr r2, r1
    li r1, 70
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 206
    add r1, r1, r6
    swr r2, r1
    li r1, 206
    add r1, r1, r6
    lwr r2, r1
    li r1, 207
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_179
_B_main_62:
;; if (*p==47)
    li r1, 70
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 208
    add r1, r1, r6
    swr r2, r1
    li r1, 208
    add r1, r1, r6
    lwr r3, r1
    li r2, 47
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_1358
    li r2, 0
_L_main_ne_1358:
    li r1, 209
    add r1, r1, r6
    swr r2, r1
    li r1, 209
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_63
    clrt
    bf _B_main_73
_B_main_63:
;; if (sp<2)
    li r1, sp
    lwr r2, r1
    li r1, 210
    add r1, r1, r6
    swr r2, r1
    li r1, 210
    add r1, r1, r6
    lwr r3, r1
    li r2, 2
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    rol r2, r0
    li r1, 211
    add r1, r1, r6
    swr r2, r1
    li r1, 211
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_64
    clrt
    bf _B_main_66
_B_main_64:
;; emit_err()
    li r1, emit_err
    jalr r5, r1
    li r1, 212
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_155
_B_main_66:
;; b=stk[sp-1]
    li r1, sp
    lwr r2, r1
    li r1, 213
    add r1, r1, r6
    swr r2, r1
    li r1, 213
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    li r1, 214
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 214
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 215
    add r1, r1, r6
    swr r2, r1
    li r1, 215
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 216
    add r1, r1, r6
    swr r2, r1
    li r1, 216
    add r1, r1, r6
    lwr r2, r1
    li r1, 217
    add r1, r1, r6
    swr r2, r1
;; a=stk[sp-2]
    li r1, sp
    lwr r2, r1
    li r1, 218
    add r1, r1, r6
    swr r2, r1
    li r1, 218
    add r1, r1, r6
    lwr r3, r1
    li r2, 2
    sub r2, r3, r2
    li r1, 219
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 219
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 220
    add r1, r1, r6
    swr r2, r1
    li r1, 220
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 221
    add r1, r1, r6
    swr r2, r1
    li r1, 221
    add r1, r1, r6
    lwr r2, r1
    li r1, 222
    add r1, r1, r6
    swr r2, r1
;; if (b==0)
    li r1, 217
    add r1, r1, r6
    lwr r3, r1
    and r2, r0, r0
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_1485
    li r2, 0
_L_main_ne_1485:
    li r1, 223
    add r1, r1, r6
    swr r2, r1
    li r1, 223
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_67
    clrt
    bf _B_main_69
_B_main_67:
;; emit_err()
    li r1, emit_err
    jalr r5, r1
    li r1, 224
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_153
_B_main_69:
;; sp-=2
    li r1, sp
    lwr r2, r1
    li r1, 225
    add r1, r1, r6
    swr r2, r1
    li r1, 225
    add r1, r1, r6
    lwr r3, r1
    li r2, 2
    sub r2, r3, r2
    li r1, 226
    add r1, r1, r6
    swr r2, r1
    li r1, 226
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
;; r=a/b
    li r1, 222
    add r1, r1, r6
    lwr r3, r1
    li r1, 217
    add r1, r1, r6
    lwr r2, r1
    li r1, __div
    jalr r5, r1
    li r1, 227
    add r1, r1, r6
    swr r2, r1
    li r1, 227
    add r1, r1, r6
    lwr r2, r1
    li r1, 228
    add r1, r1, r6
    swr r2, r1
;; stk[sp]=r
    li r1, sp
    lwr r2, r1
    li r1, 229
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 229
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 230
    add r1, r1, r6
    swr r2, r1
    li r1, 228
    add r1, r1, r6
    lwr r2, r1
    li r1, 230
    add r1, r1, r6
    lwr r1, r1
    swr r2, r1
;; sp++
    li r1, sp
    lwr r2, r1
    li r1, 231
    add r1, r1, r6
    swr r2, r1
    li r1, 231
    add r1, r1, r6
    lwr r2, r1
    li r1, 232
    add r1, r1, r6
    swr r2, r1
    li r1, 231
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 233
    add r1, r1, r6
    swr r2, r1
    li r1, 233
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
    clrt
    bf _B_main_152
_B_main_70:
    clrt
    bf _B_main_154
_B_main_71:
;; p++
    li r1, 70
    add r1, r1, r6
    lwr r2, r1
    li r1, 234
    add r1, r1, r6
    swr r2, r1
    li r1, 70
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 235
    add r1, r1, r6
    swr r2, r1
    li r1, 235
    add r1, r1, r6
    lwr r2, r1
    li r1, 236
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_177
_B_main_73:
;; if (*p==110)
    li r1, 70
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 237
    add r1, r1, r6
    swr r2, r1
    li r1, 237
    add r1, r1, r6
    lwr r3, r1
    li r2, 110
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_1636
    li r2, 0
_L_main_ne_1636:
    li r1, 238
    add r1, r1, r6
    swr r2, r1
    li r1, 238
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_74
    clrt
    bf _B_main_80
_B_main_74:
;; if (sp<1)
    li r1, sp
    lwr r2, r1
    li r1, 239
    add r1, r1, r6
    swr r2, r1
    li r1, 239
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    rol r2, r0
    li r1, 240
    add r1, r1, r6
    swr r2, r1
    li r1, 240
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_75
    clrt
    bf _B_main_77
_B_main_75:
;; emit_err()
    li r1, emit_err
    jalr r5, r1
    li r1, 241
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_157
_B_main_77:
;; sp--
    li r1, sp
    lwr r2, r1
    li r1, 242
    add r1, r1, r6
    swr r2, r1
    li r1, 242
    add r1, r1, r6
    lwr r2, r1
    li r1, 243
    add r1, r1, r6
    swr r2, r1
    li r1, 242
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    li r1, 244
    add r1, r1, r6
    swr r2, r1
    li r1, 244
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
;; a=stk[sp]
    li r1, sp
    lwr r2, r1
    li r1, 245
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 245
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 246
    add r1, r1, r6
    swr r2, r1
    li r1, 246
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 247
    add r1, r1, r6
    swr r2, r1
    li r1, 247
    add r1, r1, r6
    lwr r2, r1
    li r1, 248
    add r1, r1, r6
    swr r2, r1
;; r=-a
    li r1, 248
    add r1, r1, r6
    lwr r2, r1
    sub r2, r0, r2
    li r1, 249
    add r1, r1, r6
    swr r2, r1
    li r1, 249
    add r1, r1, r6
    lwr r2, r1
    li r1, 250
    add r1, r1, r6
    swr r2, r1
;; stk[sp]=r
    li r1, sp
    lwr r2, r1
    li r1, 251
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 251
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 252
    add r1, r1, r6
    swr r2, r1
    li r1, 250
    add r1, r1, r6
    lwr r2, r1
    li r1, 252
    add r1, r1, r6
    lwr r1, r1
    swr r2, r1
;; sp++
    li r1, sp
    lwr r2, r1
    li r1, 253
    add r1, r1, r6
    swr r2, r1
    li r1, 253
    add r1, r1, r6
    lwr r2, r1
    li r1, 254
    add r1, r1, r6
    swr r2, r1
    li r1, 253
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 255
    add r1, r1, r6
    swr r2, r1
    li r1, 255
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
    clrt
    bf _B_main_156
_B_main_78:
;; p++
    li r1, 70
    add r1, r1, r6
    lwr r2, r1
    lui r1, 4
    add r1, r1, r6
    swr r2, r1
    li r1, 70
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 257
    add r1, r1, r6
    swr r2, r1
    li r1, 257
    add r1, r1, r6
    lwr r2, r1
    li r1, 258
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_175
_B_main_80:
;; if (*p==112)
    li r1, 70
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 259
    add r1, r1, r6
    swr r2, r1
    li r1, 259
    add r1, r1, r6
    lwr r3, r1
    li r2, 112
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_1839
    li r2, 0
_L_main_ne_1839:
    li r1, 260
    add r1, r1, r6
    swr r2, r1
    li r1, 260
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_81
    clrt
    bf _B_main_87
_B_main_81:
;; if (sp<1)
    li r1, sp
    lwr r2, r1
    li r1, 261
    add r1, r1, r6
    swr r2, r1
    li r1, 261
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    rol r2, r0
    li r1, 262
    add r1, r1, r6
    swr r2, r1
    li r1, 262
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_82
    clrt
    bf _B_main_84
_B_main_82:
;; emit_err()
    li r1, emit_err
    jalr r5, r1
    li r1, 263
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_159
_B_main_84:
;; itoa(stk[sp-1],sbuf)
    li r1, sp
    lwr r2, r1
    li r1, 264
    add r1, r1, r6
    swr r2, r1
    li r1, 264
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    li r1, 265
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 265
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 266
    add r1, r1, r6
    swr r2, r1
    li r1, 266
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 267
    add r1, r1, r6
    swr r2, r1
    li r1, 267
    add r1, r1, r6
    lwr r2, r1
    li r1, 269
    add r1, r1, r6
    and r3, r1, r7
    li r1, itoa
    jalr r5, r1
    li r1, 268
    add r1, r1, r6
    swr r2, r1
;; puts(sbuf)
    li r1, 269
    add r1, r1, r6
    and r2, r1, r7
    li r1, puts
    jalr r5, r1
    li r1, 277
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_158
_B_main_85:
;; p++
    li r1, 70
    add r1, r1, r6
    lwr r2, r1
    li r1, 278
    add r1, r1, r6
    swr r2, r1
    li r1, 70
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 279
    add r1, r1, r6
    swr r2, r1
    li r1, 279
    add r1, r1, r6
    lwr r2, r1
    li r1, 280
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_173
_B_main_87:
;; if (*p==100)
    li r1, 70
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 281
    add r1, r1, r6
    swr r2, r1
    li r1, 281
    add r1, r1, r6
    lwr r3, r1
    li r2, 100
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_1979
    li r2, 0
_L_main_ne_1979:
    li r1, 282
    add r1, r1, r6
    swr r2, r1
    li r1, 282
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_88
    clrt
    bf _B_main_99
_B_main_88:
;; if (sp<1||sp>=16)
    li r1, sp
    lwr r2, r1
    li r1, 283
    add r1, r1, r6
    swr r2, r1
    li r1, 283
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    rol r2, r0
    li r1, 284
    add r1, r1, r6
    swr r2, r1
    li r1, 284
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_161
    clrt
    bf _B_main_89
_B_main_89:
    li r1, sp
    lwr r2, r1
    li r1, 285
    add r1, r1, r6
    swr r2, r1
    li r1, 285
    add r1, r1, r6
    lwr r3, r1
    li r2, 16
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    li r2, 1
    bf _L_main_ne_2033
    li r2, 0
_L_main_ne_2033:
    li r1, 286
    add r1, r1, r6
    swr r2, r1
    li r1, 286
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_160
    clrt
    bf _B_main_90
_B_main_90:
    and r2, r0, r0
    li r1, 287
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_163
_B_main_92:
    li r2, 1
    li r1, 288
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_162
_B_main_93:
    li r1, 289
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_94
    clrt
    bf _B_main_96
_B_main_94:
;; emit_err()
    li r1, emit_err
    jalr r5, r1
    li r1, 290
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_165
_B_main_96:
;; a=stk[sp-1]
    li r1, sp
    lwr r2, r1
    li r1, 291
    add r1, r1, r6
    swr r2, r1
    li r1, 291
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    li r1, 292
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 292
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 293
    add r1, r1, r6
    swr r2, r1
    li r1, 293
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 294
    add r1, r1, r6
    swr r2, r1
    li r1, 294
    add r1, r1, r6
    lwr r2, r1
    li r1, 295
    add r1, r1, r6
    swr r2, r1
;; stk[sp]=a
    li r1, sp
    lwr r2, r1
    li r1, 296
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 296
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 297
    add r1, r1, r6
    swr r2, r1
    li r1, 295
    add r1, r1, r6
    lwr r2, r1
    li r1, 297
    add r1, r1, r6
    lwr r1, r1
    swr r2, r1
;; sp++
    li r1, sp
    lwr r2, r1
    li r1, 298
    add r1, r1, r6
    swr r2, r1
    li r1, 298
    add r1, r1, r6
    lwr r2, r1
    li r1, 299
    add r1, r1, r6
    swr r2, r1
    li r1, 298
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 300
    add r1, r1, r6
    swr r2, r1
    li r1, 300
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
    clrt
    bf _B_main_164
_B_main_97:
;; p++
    li r1, 70
    add r1, r1, r6
    lwr r2, r1
    li r1, 301
    add r1, r1, r6
    swr r2, r1
    li r1, 70
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 302
    add r1, r1, r6
    swr r2, r1
    li r1, 302
    add r1, r1, r6
    lwr r2, r1
    li r1, 303
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_171
_B_main_99:
;; if (*p==99)
    li r1, 70
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 304
    add r1, r1, r6
    swr r2, r1
    li r1, 304
    add r1, r1, r6
    lwr r3, r1
    li r2, 99
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_2201
    li r2, 0
_L_main_ne_2201:
    li r1, 305
    add r1, r1, r6
    swr r2, r1
    li r1, 305
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_100
    clrt
    bf _B_main_102
_B_main_100:
;; sp=0
    and r2, r0, r0
    li r1, sp
    swr r2, r1
;; p++
    li r1, 70
    add r1, r1, r6
    lwr r2, r1
    li r1, 306
    add r1, r1, r6
    swr r2, r1
    li r1, 70
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 307
    add r1, r1, r6
    swr r2, r1
    li r1, 307
    add r1, r1, r6
    lwr r2, r1
    li r1, 308
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_169
_B_main_102:
;; if (*p==113)
    li r1, 70
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 309
    add r1, r1, r6
    swr r2, r1
    li r1, 309
    add r1, r1, r6
    lwr r3, r1
    li r2, 113
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_2258
    li r2, 0
_L_main_ne_2258:
    li r1, 310
    add r1, r1, r6
    swr r2, r1
    li r1, 310
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _B_main_103
    clrt
    bf _B_main_105
_B_main_103:
;; exit(0)
    and r2, r0, r0
    li r1, exit
    jalr r5, r1
    li r1, 311
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_167
_B_main_105:
;; emit_err()
    li r1, emit_err
    jalr r5, r1
    li r1, 312
    add r1, r1, r6
    swr r2, r1
;; p++
    li r1, 70
    add r1, r1, r6
    lwr r2, r1
    li r1, 313
    add r1, r1, r6
    swr r2, r1
    li r1, 70
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 314
    add r1, r1, r6
    swr r2, r1
    li r1, 314
    add r1, r1, r6
    lwr r2, r1
    li r1, 315
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_166
_B_main_106:
    clrt
    bf _B_main_168
_B_main_107:
    clrt
    bf _B_main_170
_B_main_108:
    clrt
    bf _B_main_172
_B_main_109:
    clrt
    bf _B_main_174
_B_main_110:
    clrt
    bf _B_main_176
_B_main_111:
    clrt
    bf _B_main_178
_B_main_112:
    clrt
    bf _B_main_180
_B_main_113:
    clrt
    bf _B_main_182
_B_main_114:
    clrt
    bf _B_main_184
_B_main_115:
    clrt
    bf _B_main_122
_B_main_117:
    clrt
    bf _B_main_120
_B_main_119:
;; return 0
    and r2, r0, r0
    clrt
    bf _epi_main
_B_main_120:
    li r1, 317
    add r1, r1, r6
    lwr r2, r1
    li r1, 316
    add r1, r1, r6
    swr r2, r1
    li r1, 319
    add r1, r1, r6
    lwr r2, r1
    li r1, 318
    add r1, r1, r6
    swr r2, r1
    li r1, 321
    add r1, r1, r6
    lwr r2, r1
    lui r1, 5
    add r1, r1, r6
    swr r2, r1
    li r1, 323
    add r1, r1, r6
    lwr r2, r1
    li r1, 322
    add r1, r1, r6
    swr r2, r1
    li r1, 325
    add r1, r1, r6
    lwr r2, r1
    li r1, 324
    add r1, r1, r6
    swr r2, r1
    li r1, 327
    add r1, r1, r6
    lwr r2, r1
    li r1, 326
    add r1, r1, r6
    swr r2, r1
    li r1, 329
    add r1, r1, r6
    lwr r2, r1
    li r1, 328
    add r1, r1, r6
    swr r2, r1
    li r1, 331
    add r1, r1, r6
    lwr r2, r1
    li r1, 330
    add r1, r1, r6
    swr r2, r1
    li r1, 333
    add r1, r1, r6
    lwr r2, r1
    li r1, 332
    add r1, r1, r6
    swr r2, r1
    li r1, 335
    add r1, r1, r6
    lwr r2, r1
    li r1, 334
    add r1, r1, r6
    swr r2, r1
    li r1, 337
    add r1, r1, r6
    lwr r2, r1
    li r1, 336
    add r1, r1, r6
    swr r2, r1
    li r1, 339
    add r1, r1, r6
    lwr r2, r1
    li r1, 338
    add r1, r1, r6
    swr r2, r1
    li r1, 341
    add r1, r1, r6
    lwr r2, r1
    li r1, 340
    add r1, r1, r6
    swr r2, r1
    li r1, 343
    add r1, r1, r6
    lwr r2, r1
    li r1, 342
    add r1, r1, r6
    swr r2, r1
    li r1, 345
    add r1, r1, r6
    lwr r2, r1
    li r1, 344
    add r1, r1, r6
    swr r2, r1
    li r1, 347
    add r1, r1, r6
    lwr r2, r1
    li r1, 346
    add r1, r1, r6
    swr r2, r1
    li r1, 349
    add r1, r1, r6
    lwr r2, r1
    li r1, 348
    add r1, r1, r6
    swr r2, r1
    li r1, 351
    add r1, r1, r6
    lwr r2, r1
    li r1, 350
    add r1, r1, r6
    swr r2, r1
    li r1, 353
    add r1, r1, r6
    lwr r2, r1
    li r1, 352
    add r1, r1, r6
    swr r2, r1
    li r1, 355
    add r1, r1, r6
    lwr r2, r1
    li r1, 354
    add r1, r1, r6
    swr r2, r1
    li r1, 357
    add r1, r1, r6
    lwr r2, r1
    li r1, 356
    add r1, r1, r6
    swr r2, r1
    li r1, 359
    add r1, r1, r6
    lwr r2, r1
    li r1, 358
    add r1, r1, r6
    swr r2, r1
    li r1, 361
    add r1, r1, r6
    lwr r2, r1
    li r1, 360
    add r1, r1, r6
    swr r2, r1
    li r1, 363
    add r1, r1, r6
    lwr r2, r1
    li r1, 362
    add r1, r1, r6
    swr r2, r1
    li r1, 365
    add r1, r1, r6
    lwr r2, r1
    li r1, 364
    add r1, r1, r6
    swr r2, r1
    li r1, 367
    add r1, r1, r6
    lwr r2, r1
    li r1, 366
    add r1, r1, r6
    swr r2, r1
    li r1, 369
    add r1, r1, r6
    lwr r2, r1
    li r1, 368
    add r1, r1, r6
    swr r2, r1
    li r1, 371
    add r1, r1, r6
    lwr r2, r1
    li r1, 370
    add r1, r1, r6
    swr r2, r1
    li r1, 373
    add r1, r1, r6
    lwr r2, r1
    li r1, 372
    add r1, r1, r6
    swr r2, r1
    li r1, 375
    add r1, r1, r6
    lwr r2, r1
    li r1, 374
    add r1, r1, r6
    swr r2, r1
    li r1, 377
    add r1, r1, r6
    lwr r2, r1
    li r1, 376
    add r1, r1, r6
    swr r2, r1
    li r1, 379
    add r1, r1, r6
    lwr r2, r1
    li r1, 378
    add r1, r1, r6
    swr r2, r1
    li r1, 381
    add r1, r1, r6
    lwr r2, r1
    li r1, 380
    add r1, r1, r6
    swr r2, r1
    li r1, 383
    add r1, r1, r6
    lwr r2, r1
    li r1, 382
    add r1, r1, r6
    swr r2, r1
    li r1, 385
    add r1, r1, r6
    lwr r2, r1
    lui r1, 6
    add r1, r1, r6
    swr r2, r1
    li r1, 387
    add r1, r1, r6
    lwr r2, r1
    li r1, 386
    add r1, r1, r6
    swr r2, r1
    li r1, 389
    add r1, r1, r6
    lwr r2, r1
    li r1, 388
    add r1, r1, r6
    swr r2, r1
    li r1, 391
    add r1, r1, r6
    lwr r2, r1
    li r1, 390
    add r1, r1, r6
    swr r2, r1
    li r1, 393
    add r1, r1, r6
    lwr r2, r1
    li r1, 392
    add r1, r1, r6
    swr r2, r1
    li r1, 395
    add r1, r1, r6
    lwr r2, r1
    li r1, 394
    add r1, r1, r6
    swr r2, r1
    li r1, 397
    add r1, r1, r6
    lwr r2, r1
    li r1, 396
    add r1, r1, r6
    swr r2, r1
    li r1, 399
    add r1, r1, r6
    lwr r2, r1
    li r1, 398
    add r1, r1, r6
    swr r2, r1
    li r1, 401
    add r1, r1, r6
    lwr r2, r1
    li r1, 400
    add r1, r1, r6
    swr r2, r1
    li r1, 403
    add r1, r1, r6
    lwr r2, r1
    li r1, 402
    add r1, r1, r6
    swr r2, r1
    li r1, 405
    add r1, r1, r6
    lwr r2, r1
    li r1, 404
    add r1, r1, r6
    swr r2, r1
    li r1, 407
    add r1, r1, r6
    lwr r2, r1
    li r1, 406
    add r1, r1, r6
    swr r2, r1
    li r1, 409
    add r1, r1, r6
    lwr r2, r1
    li r1, 408
    add r1, r1, r6
    swr r2, r1
    li r1, 411
    add r1, r1, r6
    lwr r2, r1
    li r1, 410
    add r1, r1, r6
    swr r2, r1
    li r1, 413
    add r1, r1, r6
    lwr r2, r1
    li r1, 412
    add r1, r1, r6
    swr r2, r1
    li r1, 415
    add r1, r1, r6
    lwr r2, r1
    li r1, 414
    add r1, r1, r6
    swr r2, r1
    li r1, 417
    add r1, r1, r6
    lwr r2, r1
    li r1, 416
    add r1, r1, r6
    swr r2, r1
    li r1, 419
    add r1, r1, r6
    lwr r2, r1
    li r1, 418
    add r1, r1, r6
    swr r2, r1
    li r1, 421
    add r1, r1, r6
    lwr r2, r1
    li r1, 420
    add r1, r1, r6
    swr r2, r1
    li r1, 423
    add r1, r1, r6
    lwr r2, r1
    li r1, 422
    add r1, r1, r6
    swr r2, r1
    li r1, 425
    add r1, r1, r6
    lwr r2, r1
    li r1, 424
    add r1, r1, r6
    swr r2, r1
    li r1, 427
    add r1, r1, r6
    lwr r2, r1
    li r1, 426
    add r1, r1, r6
    swr r2, r1
    li r1, 429
    add r1, r1, r6
    lwr r2, r1
    li r1, 428
    add r1, r1, r6
    swr r2, r1
    li r1, 431
    add r1, r1, r6
    lwr r2, r1
    li r1, 430
    add r1, r1, r6
    swr r2, r1
    li r1, 433
    add r1, r1, r6
    lwr r2, r1
    li r1, 432
    add r1, r1, r6
    swr r2, r1
    li r1, 435
    add r1, r1, r6
    lwr r2, r1
    li r1, 434
    add r1, r1, r6
    swr r2, r1
    li r1, 437
    add r1, r1, r6
    lwr r2, r1
    li r1, 436
    add r1, r1, r6
    swr r2, r1
    li r1, 439
    add r1, r1, r6
    lwr r2, r1
    li r1, 438
    add r1, r1, r6
    swr r2, r1
    li r1, 441
    add r1, r1, r6
    lwr r2, r1
    li r1, 440
    add r1, r1, r6
    swr r2, r1
    li r1, 443
    add r1, r1, r6
    lwr r2, r1
    li r1, 442
    add r1, r1, r6
    swr r2, r1
    li r1, 445
    add r1, r1, r6
    lwr r2, r1
    li r1, 444
    add r1, r1, r6
    swr r2, r1
    li r1, 447
    add r1, r1, r6
    lwr r2, r1
    li r1, 446
    add r1, r1, r6
    swr r2, r1
    li r1, 449
    add r1, r1, r6
    lwr r2, r1
    lui r1, 7
    add r1, r1, r6
    swr r2, r1
    li r1, 451
    add r1, r1, r6
    lwr r2, r1
    li r1, 450
    add r1, r1, r6
    swr r2, r1
    li r1, 453
    add r1, r1, r6
    lwr r2, r1
    li r1, 452
    add r1, r1, r6
    swr r2, r1
    li r1, 455
    add r1, r1, r6
    lwr r2, r1
    li r1, 454
    add r1, r1, r6
    swr r2, r1
    li r1, 457
    add r1, r1, r6
    lwr r2, r1
    li r1, 456
    add r1, r1, r6
    swr r2, r1
    li r1, 459
    add r1, r1, r6
    lwr r2, r1
    li r1, 458
    add r1, r1, r6
    swr r2, r1
    li r1, 461
    add r1, r1, r6
    lwr r2, r1
    li r1, 460
    add r1, r1, r6
    swr r2, r1
    li r1, 463
    add r1, r1, r6
    lwr r2, r1
    li r1, 462
    add r1, r1, r6
    swr r2, r1
    li r1, 465
    add r1, r1, r6
    lwr r2, r1
    li r1, 464
    add r1, r1, r6
    swr r2, r1
    li r1, 467
    add r1, r1, r6
    lwr r2, r1
    li r1, 466
    add r1, r1, r6
    swr r2, r1
    li r1, 469
    add r1, r1, r6
    lwr r2, r1
    li r1, 468
    add r1, r1, r6
    swr r2, r1
    li r1, 471
    add r1, r1, r6
    lwr r2, r1
    li r1, 470
    add r1, r1, r6
    swr r2, r1
    li r1, 473
    add r1, r1, r6
    lwr r2, r1
    li r1, 472
    add r1, r1, r6
    swr r2, r1
    li r1, 475
    add r1, r1, r6
    lwr r2, r1
    li r1, 474
    add r1, r1, r6
    swr r2, r1
    li r1, 477
    add r1, r1, r6
    lwr r2, r1
    li r1, 476
    add r1, r1, r6
    swr r2, r1
    li r1, 479
    add r1, r1, r6
    lwr r2, r1
    li r1, 478
    add r1, r1, r6
    swr r2, r1
    li r1, 481
    add r1, r1, r6
    lwr r2, r1
    li r1, 480
    add r1, r1, r6
    swr r2, r1
    li r1, 483
    add r1, r1, r6
    lwr r2, r1
    li r1, 482
    add r1, r1, r6
    swr r2, r1
    li r1, 485
    add r1, r1, r6
    lwr r2, r1
    li r1, 484
    add r1, r1, r6
    swr r2, r1
    li r1, 487
    add r1, r1, r6
    lwr r2, r1
    li r1, 486
    add r1, r1, r6
    swr r2, r1
    li r1, 489
    add r1, r1, r6
    lwr r2, r1
    li r1, 488
    add r1, r1, r6
    swr r2, r1
    li r1, 491
    add r1, r1, r6
    lwr r2, r1
    li r1, 490
    add r1, r1, r6
    swr r2, r1
    li r1, 493
    add r1, r1, r6
    lwr r2, r1
    li r1, 492
    add r1, r1, r6
    swr r2, r1
    li r1, 495
    add r1, r1, r6
    lwr r2, r1
    li r1, 494
    add r1, r1, r6
    swr r2, r1
    li r1, 497
    add r1, r1, r6
    lwr r2, r1
    li r1, 496
    add r1, r1, r6
    swr r2, r1
    li r1, 499
    add r1, r1, r6
    lwr r2, r1
    li r1, 498
    add r1, r1, r6
    swr r2, r1
    li r1, 501
    add r1, r1, r6
    lwr r2, r1
    li r1, 500
    add r1, r1, r6
    swr r2, r1
    li r1, 68
    add r1, r1, r6
    lwr r2, r1
    li r1, 502
    add r1, r1, r6
    swr r2, r1
    li r1, 504
    add r1, r1, r6
    lwr r2, r1
    li r1, 503
    add r1, r1, r6
    swr r2, r1
    li r1, 506
    add r1, r1, r6
    lwr r2, r1
    li r1, 505
    add r1, r1, r6
    swr r2, r1
    li r1, 508
    add r1, r1, r6
    lwr r2, r1
    li r1, 507
    add r1, r1, r6
    swr r2, r1
    li r1, 510
    add r1, r1, r6
    lwr r2, r1
    li r1, 509
    add r1, r1, r6
    swr r2, r1
    lui r1, 8
    add r1, r1, r6
    lwr r2, r1
    li r1, 511
    add r1, r1, r6
    swr r2, r1
    li r1, 514
    add r1, r1, r6
    lwr r2, r1
    li r1, 513
    add r1, r1, r6
    swr r2, r1
    li r1, 516
    add r1, r1, r6
    lwr r2, r1
    li r1, 515
    add r1, r1, r6
    swr r2, r1
    li r1, 518
    add r1, r1, r6
    lwr r2, r1
    li r1, 517
    add r1, r1, r6
    swr r2, r1
    li r1, 520
    add r1, r1, r6
    lwr r2, r1
    li r1, 519
    add r1, r1, r6
    swr r2, r1
    li r1, 522
    add r1, r1, r6
    lwr r2, r1
    li r1, 521
    add r1, r1, r6
    swr r2, r1
    li r1, 524
    add r1, r1, r6
    lwr r2, r1
    li r1, 523
    add r1, r1, r6
    swr r2, r1
    li r1, 526
    add r1, r1, r6
    lwr r2, r1
    li r1, 525
    add r1, r1, r6
    swr r2, r1
    li r1, 528
    add r1, r1, r6
    lwr r2, r1
    li r1, 527
    add r1, r1, r6
    swr r2, r1
    li r1, 530
    add r1, r1, r6
    lwr r2, r1
    li r1, 529
    add r1, r1, r6
    swr r2, r1
    li r1, 532
    add r1, r1, r6
    lwr r2, r1
    li r1, 531
    add r1, r1, r6
    swr r2, r1
    li r1, 534
    add r1, r1, r6
    lwr r2, r1
    li r1, 533
    add r1, r1, r6
    swr r2, r1
    li r1, 536
    add r1, r1, r6
    lwr r2, r1
    li r1, 535
    add r1, r1, r6
    swr r2, r1
    li r1, 538
    add r1, r1, r6
    lwr r2, r1
    li r1, 537
    add r1, r1, r6
    swr r2, r1
    li r1, 540
    add r1, r1, r6
    lwr r2, r1
    li r1, 539
    add r1, r1, r6
    swr r2, r1
    li r1, 542
    add r1, r1, r6
    lwr r2, r1
    li r1, 541
    add r1, r1, r6
    swr r2, r1
    li r1, 544
    add r1, r1, r6
    lwr r2, r1
    li r1, 543
    add r1, r1, r6
    swr r2, r1
    li r1, 546
    add r1, r1, r6
    lwr r2, r1
    li r1, 545
    add r1, r1, r6
    swr r2, r1
    li r1, 548
    add r1, r1, r6
    lwr r2, r1
    li r1, 547
    add r1, r1, r6
    swr r2, r1
    li r1, 550
    add r1, r1, r6
    lwr r2, r1
    li r1, 549
    add r1, r1, r6
    swr r2, r1
    li r1, 552
    add r1, r1, r6
    lwr r2, r1
    li r1, 551
    add r1, r1, r6
    swr r2, r1
    li r1, 554
    add r1, r1, r6
    lwr r2, r1
    li r1, 553
    add r1, r1, r6
    swr r2, r1
    li r1, 556
    add r1, r1, r6
    lwr r2, r1
    li r1, 555
    add r1, r1, r6
    swr r2, r1
    li r1, 558
    add r1, r1, r6
    lwr r2, r1
    li r1, 557
    add r1, r1, r6
    swr r2, r1
    li r1, 560
    add r1, r1, r6
    lwr r2, r1
    li r1, 559
    add r1, r1, r6
    swr r2, r1
    li r1, 562
    add r1, r1, r6
    lwr r2, r1
    li r1, 561
    add r1, r1, r6
    swr r2, r1
    li r1, 564
    add r1, r1, r6
    lwr r2, r1
    li r1, 563
    add r1, r1, r6
    swr r2, r1
    li r1, 566
    add r1, r1, r6
    lwr r2, r1
    li r1, 565
    add r1, r1, r6
    swr r2, r1
    li r1, 568
    add r1, r1, r6
    lwr r2, r1
    li r1, 567
    add r1, r1, r6
    swr r2, r1
    li r1, 570
    add r1, r1, r6
    lwr r2, r1
    li r1, 569
    add r1, r1, r6
    swr r2, r1
    li r1, 572
    add r1, r1, r6
    lwr r2, r1
    li r1, 571
    add r1, r1, r6
    swr r2, r1
    li r1, 574
    add r1, r1, r6
    lwr r2, r1
    li r1, 573
    add r1, r1, r6
    swr r2, r1
    lui r1, 9
    add r1, r1, r6
    lwr r2, r1
    li r1, 575
    add r1, r1, r6
    swr r2, r1
    li r1, 578
    add r1, r1, r6
    lwr r2, r1
    li r1, 577
    add r1, r1, r6
    swr r2, r1
    li r1, 580
    add r1, r1, r6
    lwr r2, r1
    li r1, 579
    add r1, r1, r6
    swr r2, r1
    li r1, 582
    add r1, r1, r6
    lwr r2, r1
    li r1, 581
    add r1, r1, r6
    swr r2, r1
    li r1, 584
    add r1, r1, r6
    lwr r2, r1
    li r1, 583
    add r1, r1, r6
    swr r2, r1
    li r1, 586
    add r1, r1, r6
    lwr r2, r1
    li r1, 585
    add r1, r1, r6
    swr r2, r1
    li r1, 588
    add r1, r1, r6
    lwr r2, r1
    li r1, 587
    add r1, r1, r6
    swr r2, r1
    li r1, 590
    add r1, r1, r6
    lwr r2, r1
    li r1, 589
    add r1, r1, r6
    swr r2, r1
    li r1, 592
    add r1, r1, r6
    lwr r2, r1
    li r1, 591
    add r1, r1, r6
    swr r2, r1
    li r1, 594
    add r1, r1, r6
    lwr r2, r1
    li r1, 593
    add r1, r1, r6
    swr r2, r1
    li r1, 596
    add r1, r1, r6
    lwr r2, r1
    li r1, 595
    add r1, r1, r6
    swr r2, r1
    li r1, 598
    add r1, r1, r6
    lwr r2, r1
    li r1, 597
    add r1, r1, r6
    swr r2, r1
    li r1, 600
    add r1, r1, r6
    lwr r2, r1
    li r1, 599
    add r1, r1, r6
    swr r2, r1
    li r1, 602
    add r1, r1, r6
    lwr r2, r1
    li r1, 601
    add r1, r1, r6
    swr r2, r1
    li r1, 604
    add r1, r1, r6
    lwr r2, r1
    li r1, 603
    add r1, r1, r6
    swr r2, r1
    li r1, 606
    add r1, r1, r6
    lwr r2, r1
    li r1, 605
    add r1, r1, r6
    swr r2, r1
    li r1, 608
    add r1, r1, r6
    lwr r2, r1
    li r1, 607
    add r1, r1, r6
    swr r2, r1
    li r1, 610
    add r1, r1, r6
    lwr r2, r1
    li r1, 609
    add r1, r1, r6
    swr r2, r1
    li r1, 612
    add r1, r1, r6
    lwr r2, r1
    li r1, 611
    add r1, r1, r6
    swr r2, r1
    li r1, 614
    add r1, r1, r6
    lwr r2, r1
    li r1, 613
    add r1, r1, r6
    swr r2, r1
    li r1, 616
    add r1, r1, r6
    lwr r2, r1
    li r1, 615
    add r1, r1, r6
    swr r2, r1
    li r1, 618
    add r1, r1, r6
    lwr r2, r1
    li r1, 617
    add r1, r1, r6
    swr r2, r1
    li r1, 620
    add r1, r1, r6
    lwr r2, r1
    li r1, 619
    add r1, r1, r6
    swr r2, r1
    li r1, 622
    add r1, r1, r6
    lwr r2, r1
    li r1, 621
    add r1, r1, r6
    swr r2, r1
    li r1, 624
    add r1, r1, r6
    lwr r2, r1
    li r1, 623
    add r1, r1, r6
    swr r2, r1
    li r1, 626
    add r1, r1, r6
    lwr r2, r1
    li r1, 625
    add r1, r1, r6
    swr r2, r1
    li r1, 628
    add r1, r1, r6
    lwr r2, r1
    li r1, 627
    add r1, r1, r6
    swr r2, r1
    li r1, 630
    add r1, r1, r6
    lwr r2, r1
    li r1, 629
    add r1, r1, r6
    swr r2, r1
    li r1, 632
    add r1, r1, r6
    lwr r2, r1
    li r1, 631
    add r1, r1, r6
    swr r2, r1
    li r1, 634
    add r1, r1, r6
    lwr r2, r1
    li r1, 633
    add r1, r1, r6
    swr r2, r1
    li r1, 636
    add r1, r1, r6
    lwr r2, r1
    li r1, 635
    add r1, r1, r6
    swr r2, r1
    li r1, 638
    add r1, r1, r6
    lwr r2, r1
    li r1, 637
    add r1, r1, r6
    swr r2, r1
    lui r1, 10
    add r1, r1, r6
    lwr r2, r1
    li r1, 639
    add r1, r1, r6
    swr r2, r1
    li r1, 642
    add r1, r1, r6
    lwr r2, r1
    li r1, 641
    add r1, r1, r6
    swr r2, r1
    li r1, 644
    add r1, r1, r6
    lwr r2, r1
    li r1, 643
    add r1, r1, r6
    swr r2, r1
    li r1, 646
    add r1, r1, r6
    lwr r2, r1
    li r1, 645
    add r1, r1, r6
    swr r2, r1
    li r1, 648
    add r1, r1, r6
    lwr r2, r1
    li r1, 647
    add r1, r1, r6
    swr r2, r1
    li r1, 650
    add r1, r1, r6
    lwr r2, r1
    li r1, 649
    add r1, r1, r6
    swr r2, r1
    li r1, 652
    add r1, r1, r6
    lwr r2, r1
    li r1, 651
    add r1, r1, r6
    swr r2, r1
    li r1, 654
    add r1, r1, r6
    lwr r2, r1
    li r1, 653
    add r1, r1, r6
    swr r2, r1
    li r1, 656
    add r1, r1, r6
    lwr r2, r1
    li r1, 655
    add r1, r1, r6
    swr r2, r1
    li r1, 658
    add r1, r1, r6
    lwr r2, r1
    li r1, 657
    add r1, r1, r6
    swr r2, r1
    li r1, 660
    add r1, r1, r6
    lwr r2, r1
    li r1, 659
    add r1, r1, r6
    swr r2, r1
    li r1, 662
    add r1, r1, r6
    lwr r2, r1
    li r1, 661
    add r1, r1, r6
    swr r2, r1
    li r1, 664
    add r1, r1, r6
    lwr r2, r1
    li r1, 663
    add r1, r1, r6
    swr r2, r1
    li r1, 666
    add r1, r1, r6
    lwr r2, r1
    li r1, 665
    add r1, r1, r6
    swr r2, r1
    li r1, 668
    add r1, r1, r6
    lwr r2, r1
    li r1, 667
    add r1, r1, r6
    swr r2, r1
    li r1, 670
    add r1, r1, r6
    lwr r2, r1
    li r1, 669
    add r1, r1, r6
    swr r2, r1
    li r1, 672
    add r1, r1, r6
    lwr r2, r1
    li r1, 671
    add r1, r1, r6
    swr r2, r1
    li r1, 674
    add r1, r1, r6
    lwr r2, r1
    li r1, 673
    add r1, r1, r6
    swr r2, r1
    li r1, 676
    add r1, r1, r6
    lwr r2, r1
    li r1, 675
    add r1, r1, r6
    swr r2, r1
    li r1, 678
    add r1, r1, r6
    lwr r2, r1
    li r1, 677
    add r1, r1, r6
    swr r2, r1
    li r1, 680
    add r1, r1, r6
    lwr r2, r1
    li r1, 679
    add r1, r1, r6
    swr r2, r1
    li r1, 682
    add r1, r1, r6
    lwr r2, r1
    li r1, 681
    add r1, r1, r6
    swr r2, r1
    li r1, 684
    add r1, r1, r6
    lwr r2, r1
    li r1, 683
    add r1, r1, r6
    swr r2, r1
    li r1, 686
    add r1, r1, r6
    lwr r2, r1
    li r1, 685
    add r1, r1, r6
    swr r2, r1
    li r1, 688
    add r1, r1, r6
    lwr r2, r1
    li r1, 687
    add r1, r1, r6
    swr r2, r1
    li r1, 690
    add r1, r1, r6
    lwr r2, r1
    li r1, 689
    add r1, r1, r6
    swr r2, r1
    li r1, 692
    add r1, r1, r6
    lwr r2, r1
    li r1, 691
    add r1, r1, r6
    swr r2, r1
    li r1, 694
    add r1, r1, r6
    lwr r2, r1
    li r1, 693
    add r1, r1, r6
    swr r2, r1
    li r1, 696
    add r1, r1, r6
    lwr r2, r1
    li r1, 695
    add r1, r1, r6
    swr r2, r1
    li r1, 698
    add r1, r1, r6
    lwr r2, r1
    li r1, 697
    add r1, r1, r6
    swr r2, r1
    li r1, 700
    add r1, r1, r6
    lwr r2, r1
    li r1, 699
    add r1, r1, r6
    swr r2, r1
    li r1, 702
    add r1, r1, r6
    lwr r2, r1
    li r1, 701
    add r1, r1, r6
    swr r2, r1
    lui r1, 11
    add r1, r1, r6
    lwr r2, r1
    li r1, 703
    add r1, r1, r6
    swr r2, r1
    li r1, 706
    add r1, r1, r6
    lwr r2, r1
    li r1, 705
    add r1, r1, r6
    swr r2, r1
    li r1, 708
    add r1, r1, r6
    lwr r2, r1
    li r1, 707
    add r1, r1, r6
    swr r2, r1
    li r1, 710
    add r1, r1, r6
    lwr r2, r1
    li r1, 709
    add r1, r1, r6
    swr r2, r1
    li r1, 712
    add r1, r1, r6
    lwr r2, r1
    li r1, 711
    add r1, r1, r6
    swr r2, r1
    li r1, 714
    add r1, r1, r6
    lwr r2, r1
    li r1, 713
    add r1, r1, r6
    swr r2, r1
    li r1, 716
    add r1, r1, r6
    lwr r2, r1
    li r1, 715
    add r1, r1, r6
    swr r2, r1
    li r1, 66
    add r1, r1, r6
    lwr r2, r1
    li r1, 717
    add r1, r1, r6
    swr r2, r1
    and r1, r6, r7
    lwr r2, r1
    li r1, 718
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_1
_B_main_121:
    li r1, 719
    add r1, r1, r6
    lwr r2, r1
    li r1, 316
    add r1, r1, r6
    swr r2, r1
    li r1, 720
    add r1, r1, r6
    lwr r2, r1
    li r1, 318
    add r1, r1, r6
    swr r2, r1
    li r1, 721
    add r1, r1, r6
    lwr r2, r1
    lui r1, 5
    add r1, r1, r6
    swr r2, r1
    li r1, 722
    add r1, r1, r6
    lwr r2, r1
    li r1, 322
    add r1, r1, r6
    swr r2, r1
    li r1, 723
    add r1, r1, r6
    lwr r2, r1
    li r1, 324
    add r1, r1, r6
    swr r2, r1
    li r1, 724
    add r1, r1, r6
    lwr r2, r1
    li r1, 326
    add r1, r1, r6
    swr r2, r1
    li r1, 725
    add r1, r1, r6
    lwr r2, r1
    li r1, 328
    add r1, r1, r6
    swr r2, r1
    li r1, 726
    add r1, r1, r6
    lwr r2, r1
    li r1, 330
    add r1, r1, r6
    swr r2, r1
    li r1, 727
    add r1, r1, r6
    lwr r2, r1
    li r1, 332
    add r1, r1, r6
    swr r2, r1
    li r1, 728
    add r1, r1, r6
    lwr r2, r1
    li r1, 334
    add r1, r1, r6
    swr r2, r1
    li r1, 729
    add r1, r1, r6
    lwr r2, r1
    li r1, 336
    add r1, r1, r6
    swr r2, r1
    li r1, 730
    add r1, r1, r6
    lwr r2, r1
    li r1, 338
    add r1, r1, r6
    swr r2, r1
    li r1, 731
    add r1, r1, r6
    lwr r2, r1
    li r1, 340
    add r1, r1, r6
    swr r2, r1
    li r1, 732
    add r1, r1, r6
    lwr r2, r1
    li r1, 342
    add r1, r1, r6
    swr r2, r1
    li r1, 733
    add r1, r1, r6
    lwr r2, r1
    li r1, 344
    add r1, r1, r6
    swr r2, r1
    li r1, 734
    add r1, r1, r6
    lwr r2, r1
    li r1, 346
    add r1, r1, r6
    swr r2, r1
    li r1, 735
    add r1, r1, r6
    lwr r2, r1
    li r1, 348
    add r1, r1, r6
    swr r2, r1
    li r1, 736
    add r1, r1, r6
    lwr r2, r1
    li r1, 350
    add r1, r1, r6
    swr r2, r1
    li r1, 737
    add r1, r1, r6
    lwr r2, r1
    li r1, 352
    add r1, r1, r6
    swr r2, r1
    li r1, 738
    add r1, r1, r6
    lwr r2, r1
    li r1, 354
    add r1, r1, r6
    swr r2, r1
    li r1, 739
    add r1, r1, r6
    lwr r2, r1
    li r1, 356
    add r1, r1, r6
    swr r2, r1
    li r1, 740
    add r1, r1, r6
    lwr r2, r1
    li r1, 358
    add r1, r1, r6
    swr r2, r1
    li r1, 741
    add r1, r1, r6
    lwr r2, r1
    li r1, 360
    add r1, r1, r6
    swr r2, r1
    li r1, 742
    add r1, r1, r6
    lwr r2, r1
    li r1, 362
    add r1, r1, r6
    swr r2, r1
    li r1, 743
    add r1, r1, r6
    lwr r2, r1
    li r1, 364
    add r1, r1, r6
    swr r2, r1
    li r1, 744
    add r1, r1, r6
    lwr r2, r1
    li r1, 366
    add r1, r1, r6
    swr r2, r1
    li r1, 745
    add r1, r1, r6
    lwr r2, r1
    li r1, 368
    add r1, r1, r6
    swr r2, r1
    li r1, 746
    add r1, r1, r6
    lwr r2, r1
    li r1, 370
    add r1, r1, r6
    swr r2, r1
    li r1, 747
    add r1, r1, r6
    lwr r2, r1
    li r1, 372
    add r1, r1, r6
    swr r2, r1
    li r1, 748
    add r1, r1, r6
    lwr r2, r1
    li r1, 374
    add r1, r1, r6
    swr r2, r1
    li r1, 749
    add r1, r1, r6
    lwr r2, r1
    li r1, 376
    add r1, r1, r6
    swr r2, r1
    li r1, 750
    add r1, r1, r6
    lwr r2, r1
    li r1, 378
    add r1, r1, r6
    swr r2, r1
    li r1, 751
    add r1, r1, r6
    lwr r2, r1
    li r1, 380
    add r1, r1, r6
    swr r2, r1
    li r1, 752
    add r1, r1, r6
    lwr r2, r1
    li r1, 382
    add r1, r1, r6
    swr r2, r1
    li r1, 753
    add r1, r1, r6
    lwr r2, r1
    lui r1, 6
    add r1, r1, r6
    swr r2, r1
    li r1, 754
    add r1, r1, r6
    lwr r2, r1
    li r1, 386
    add r1, r1, r6
    swr r2, r1
    li r1, 755
    add r1, r1, r6
    lwr r2, r1
    li r1, 388
    add r1, r1, r6
    swr r2, r1
    li r1, 756
    add r1, r1, r6
    lwr r2, r1
    li r1, 390
    add r1, r1, r6
    swr r2, r1
    li r1, 757
    add r1, r1, r6
    lwr r2, r1
    li r1, 392
    add r1, r1, r6
    swr r2, r1
    li r1, 758
    add r1, r1, r6
    lwr r2, r1
    li r1, 394
    add r1, r1, r6
    swr r2, r1
    li r1, 759
    add r1, r1, r6
    lwr r2, r1
    li r1, 396
    add r1, r1, r6
    swr r2, r1
    li r1, 760
    add r1, r1, r6
    lwr r2, r1
    li r1, 398
    add r1, r1, r6
    swr r2, r1
    li r1, 761
    add r1, r1, r6
    lwr r2, r1
    li r1, 400
    add r1, r1, r6
    swr r2, r1
    li r1, 762
    add r1, r1, r6
    lwr r2, r1
    li r1, 402
    add r1, r1, r6
    swr r2, r1
    li r1, 763
    add r1, r1, r6
    lwr r2, r1
    li r1, 404
    add r1, r1, r6
    swr r2, r1
    li r1, 764
    add r1, r1, r6
    lwr r2, r1
    li r1, 406
    add r1, r1, r6
    swr r2, r1
    li r1, 765
    add r1, r1, r6
    lwr r2, r1
    li r1, 408
    add r1, r1, r6
    swr r2, r1
    li r1, 766
    add r1, r1, r6
    lwr r2, r1
    li r1, 410
    add r1, r1, r6
    swr r2, r1
    li r1, 767
    add r1, r1, r6
    lwr r2, r1
    li r1, 412
    add r1, r1, r6
    swr r2, r1
    lui r1, 12
    add r1, r1, r6
    lwr r2, r1
    li r1, 414
    add r1, r1, r6
    swr r2, r1
    li r1, 769
    add r1, r1, r6
    lwr r2, r1
    li r1, 416
    add r1, r1, r6
    swr r2, r1
    li r1, 770
    add r1, r1, r6
    lwr r2, r1
    li r1, 418
    add r1, r1, r6
    swr r2, r1
    li r1, 771
    add r1, r1, r6
    lwr r2, r1
    li r1, 420
    add r1, r1, r6
    swr r2, r1
    li r1, 772
    add r1, r1, r6
    lwr r2, r1
    li r1, 422
    add r1, r1, r6
    swr r2, r1
    li r1, 773
    add r1, r1, r6
    lwr r2, r1
    li r1, 424
    add r1, r1, r6
    swr r2, r1
    li r1, 774
    add r1, r1, r6
    lwr r2, r1
    li r1, 426
    add r1, r1, r6
    swr r2, r1
    li r1, 775
    add r1, r1, r6
    lwr r2, r1
    li r1, 428
    add r1, r1, r6
    swr r2, r1
    li r1, 776
    add r1, r1, r6
    lwr r2, r1
    li r1, 430
    add r1, r1, r6
    swr r2, r1
    li r1, 777
    add r1, r1, r6
    lwr r2, r1
    li r1, 432
    add r1, r1, r6
    swr r2, r1
    li r1, 778
    add r1, r1, r6
    lwr r2, r1
    li r1, 434
    add r1, r1, r6
    swr r2, r1
    li r1, 779
    add r1, r1, r6
    lwr r2, r1
    li r1, 436
    add r1, r1, r6
    swr r2, r1
    li r1, 780
    add r1, r1, r6
    lwr r2, r1
    li r1, 438
    add r1, r1, r6
    swr r2, r1
    li r1, 781
    add r1, r1, r6
    lwr r2, r1
    li r1, 440
    add r1, r1, r6
    swr r2, r1
    li r1, 782
    add r1, r1, r6
    lwr r2, r1
    li r1, 442
    add r1, r1, r6
    swr r2, r1
    li r1, 783
    add r1, r1, r6
    lwr r2, r1
    li r1, 444
    add r1, r1, r6
    swr r2, r1
    li r1, 784
    add r1, r1, r6
    lwr r2, r1
    li r1, 446
    add r1, r1, r6
    swr r2, r1
    li r1, 785
    add r1, r1, r6
    lwr r2, r1
    lui r1, 7
    add r1, r1, r6
    swr r2, r1
    li r1, 786
    add r1, r1, r6
    lwr r2, r1
    li r1, 450
    add r1, r1, r6
    swr r2, r1
    li r1, 787
    add r1, r1, r6
    lwr r2, r1
    li r1, 452
    add r1, r1, r6
    swr r2, r1
    li r1, 788
    add r1, r1, r6
    lwr r2, r1
    li r1, 454
    add r1, r1, r6
    swr r2, r1
    li r1, 789
    add r1, r1, r6
    lwr r2, r1
    li r1, 456
    add r1, r1, r6
    swr r2, r1
    li r1, 790
    add r1, r1, r6
    lwr r2, r1
    li r1, 458
    add r1, r1, r6
    swr r2, r1
    li r1, 791
    add r1, r1, r6
    lwr r2, r1
    li r1, 460
    add r1, r1, r6
    swr r2, r1
    li r1, 792
    add r1, r1, r6
    lwr r2, r1
    li r1, 462
    add r1, r1, r6
    swr r2, r1
    li r1, 793
    add r1, r1, r6
    lwr r2, r1
    li r1, 464
    add r1, r1, r6
    swr r2, r1
    li r1, 794
    add r1, r1, r6
    lwr r2, r1
    li r1, 466
    add r1, r1, r6
    swr r2, r1
    li r1, 795
    add r1, r1, r6
    lwr r2, r1
    li r1, 468
    add r1, r1, r6
    swr r2, r1
    li r1, 796
    add r1, r1, r6
    lwr r2, r1
    li r1, 470
    add r1, r1, r6
    swr r2, r1
    li r1, 797
    add r1, r1, r6
    lwr r2, r1
    li r1, 472
    add r1, r1, r6
    swr r2, r1
    li r1, 798
    add r1, r1, r6
    lwr r2, r1
    li r1, 474
    add r1, r1, r6
    swr r2, r1
    li r1, 799
    add r1, r1, r6
    lwr r2, r1
    li r1, 476
    add r1, r1, r6
    swr r2, r1
    li r1, 800
    add r1, r1, r6
    lwr r2, r1
    li r1, 478
    add r1, r1, r6
    swr r2, r1
    li r1, 801
    add r1, r1, r6
    lwr r2, r1
    li r1, 480
    add r1, r1, r6
    swr r2, r1
    li r1, 802
    add r1, r1, r6
    lwr r2, r1
    li r1, 482
    add r1, r1, r6
    swr r2, r1
    li r1, 803
    add r1, r1, r6
    lwr r2, r1
    li r1, 484
    add r1, r1, r6
    swr r2, r1
    li r1, 804
    add r1, r1, r6
    lwr r2, r1
    li r1, 486
    add r1, r1, r6
    swr r2, r1
    li r1, 805
    add r1, r1, r6
    lwr r2, r1
    li r1, 488
    add r1, r1, r6
    swr r2, r1
    li r1, 806
    add r1, r1, r6
    lwr r2, r1
    li r1, 490
    add r1, r1, r6
    swr r2, r1
    li r1, 807
    add r1, r1, r6
    lwr r2, r1
    li r1, 492
    add r1, r1, r6
    swr r2, r1
    li r1, 808
    add r1, r1, r6
    lwr r2, r1
    li r1, 494
    add r1, r1, r6
    swr r2, r1
    li r1, 809
    add r1, r1, r6
    lwr r2, r1
    li r1, 496
    add r1, r1, r6
    swr r2, r1
    li r1, 810
    add r1, r1, r6
    lwr r2, r1
    li r1, 498
    add r1, r1, r6
    swr r2, r1
    li r1, 811
    add r1, r1, r6
    lwr r2, r1
    li r1, 500
    add r1, r1, r6
    swr r2, r1
    li r1, 812
    add r1, r1, r6
    lwr r2, r1
    li r1, 502
    add r1, r1, r6
    swr r2, r1
    li r1, 813
    add r1, r1, r6
    lwr r2, r1
    li r1, 503
    add r1, r1, r6
    swr r2, r1
    li r1, 814
    add r1, r1, r6
    lwr r2, r1
    li r1, 505
    add r1, r1, r6
    swr r2, r1
    li r1, 815
    add r1, r1, r6
    lwr r2, r1
    li r1, 507
    add r1, r1, r6
    swr r2, r1
    li r1, 816
    add r1, r1, r6
    lwr r2, r1
    li r1, 509
    add r1, r1, r6
    swr r2, r1
    li r1, 817
    add r1, r1, r6
    lwr r2, r1
    li r1, 511
    add r1, r1, r6
    swr r2, r1
    li r1, 818
    add r1, r1, r6
    lwr r2, r1
    li r1, 513
    add r1, r1, r6
    swr r2, r1
    li r1, 819
    add r1, r1, r6
    lwr r2, r1
    li r1, 515
    add r1, r1, r6
    swr r2, r1
    li r1, 820
    add r1, r1, r6
    lwr r2, r1
    li r1, 517
    add r1, r1, r6
    swr r2, r1
    li r1, 821
    add r1, r1, r6
    lwr r2, r1
    li r1, 519
    add r1, r1, r6
    swr r2, r1
    li r1, 822
    add r1, r1, r6
    lwr r2, r1
    li r1, 521
    add r1, r1, r6
    swr r2, r1
    li r1, 823
    add r1, r1, r6
    lwr r2, r1
    li r1, 523
    add r1, r1, r6
    swr r2, r1
    li r1, 824
    add r1, r1, r6
    lwr r2, r1
    li r1, 525
    add r1, r1, r6
    swr r2, r1
    li r1, 825
    add r1, r1, r6
    lwr r2, r1
    li r1, 527
    add r1, r1, r6
    swr r2, r1
    li r1, 826
    add r1, r1, r6
    lwr r2, r1
    li r1, 529
    add r1, r1, r6
    swr r2, r1
    li r1, 827
    add r1, r1, r6
    lwr r2, r1
    li r1, 531
    add r1, r1, r6
    swr r2, r1
    li r1, 828
    add r1, r1, r6
    lwr r2, r1
    li r1, 533
    add r1, r1, r6
    swr r2, r1
    li r1, 829
    add r1, r1, r6
    lwr r2, r1
    li r1, 535
    add r1, r1, r6
    swr r2, r1
    li r1, 830
    add r1, r1, r6
    lwr r2, r1
    li r1, 537
    add r1, r1, r6
    swr r2, r1
    li r1, 831
    add r1, r1, r6
    lwr r2, r1
    li r1, 539
    add r1, r1, r6
    swr r2, r1
    lui r1, 13
    add r1, r1, r6
    lwr r2, r1
    li r1, 541
    add r1, r1, r6
    swr r2, r1
    li r1, 833
    add r1, r1, r6
    lwr r2, r1
    li r1, 543
    add r1, r1, r6
    swr r2, r1
    li r1, 834
    add r1, r1, r6
    lwr r2, r1
    li r1, 545
    add r1, r1, r6
    swr r2, r1
    li r1, 835
    add r1, r1, r6
    lwr r2, r1
    li r1, 547
    add r1, r1, r6
    swr r2, r1
    li r1, 836
    add r1, r1, r6
    lwr r2, r1
    li r1, 549
    add r1, r1, r6
    swr r2, r1
    li r1, 837
    add r1, r1, r6
    lwr r2, r1
    li r1, 551
    add r1, r1, r6
    swr r2, r1
    li r1, 838
    add r1, r1, r6
    lwr r2, r1
    li r1, 553
    add r1, r1, r6
    swr r2, r1
    li r1, 839
    add r1, r1, r6
    lwr r2, r1
    li r1, 555
    add r1, r1, r6
    swr r2, r1
    li r1, 840
    add r1, r1, r6
    lwr r2, r1
    li r1, 557
    add r1, r1, r6
    swr r2, r1
    li r1, 841
    add r1, r1, r6
    lwr r2, r1
    li r1, 559
    add r1, r1, r6
    swr r2, r1
    li r1, 842
    add r1, r1, r6
    lwr r2, r1
    li r1, 561
    add r1, r1, r6
    swr r2, r1
    li r1, 843
    add r1, r1, r6
    lwr r2, r1
    li r1, 563
    add r1, r1, r6
    swr r2, r1
    li r1, 844
    add r1, r1, r6
    lwr r2, r1
    li r1, 565
    add r1, r1, r6
    swr r2, r1
    li r1, 845
    add r1, r1, r6
    lwr r2, r1
    li r1, 567
    add r1, r1, r6
    swr r2, r1
    li r1, 846
    add r1, r1, r6
    lwr r2, r1
    li r1, 569
    add r1, r1, r6
    swr r2, r1
    li r1, 847
    add r1, r1, r6
    lwr r2, r1
    li r1, 571
    add r1, r1, r6
    swr r2, r1
    li r1, 848
    add r1, r1, r6
    lwr r2, r1
    li r1, 573
    add r1, r1, r6
    swr r2, r1
    li r1, 849
    add r1, r1, r6
    lwr r2, r1
    li r1, 575
    add r1, r1, r6
    swr r2, r1
    li r1, 850
    add r1, r1, r6
    lwr r2, r1
    li r1, 577
    add r1, r1, r6
    swr r2, r1
    li r1, 851
    add r1, r1, r6
    lwr r2, r1
    li r1, 579
    add r1, r1, r6
    swr r2, r1
    li r1, 852
    add r1, r1, r6
    lwr r2, r1
    li r1, 581
    add r1, r1, r6
    swr r2, r1
    li r1, 853
    add r1, r1, r6
    lwr r2, r1
    li r1, 583
    add r1, r1, r6
    swr r2, r1
    li r1, 854
    add r1, r1, r6
    lwr r2, r1
    li r1, 585
    add r1, r1, r6
    swr r2, r1
    li r1, 855
    add r1, r1, r6
    lwr r2, r1
    li r1, 587
    add r1, r1, r6
    swr r2, r1
    li r1, 856
    add r1, r1, r6
    lwr r2, r1
    li r1, 589
    add r1, r1, r6
    swr r2, r1
    li r1, 857
    add r1, r1, r6
    lwr r2, r1
    li r1, 591
    add r1, r1, r6
    swr r2, r1
    li r1, 858
    add r1, r1, r6
    lwr r2, r1
    li r1, 593
    add r1, r1, r6
    swr r2, r1
    li r1, 859
    add r1, r1, r6
    lwr r2, r1
    li r1, 595
    add r1, r1, r6
    swr r2, r1
    li r1, 860
    add r1, r1, r6
    lwr r2, r1
    li r1, 597
    add r1, r1, r6
    swr r2, r1
    li r1, 861
    add r1, r1, r6
    lwr r2, r1
    li r1, 599
    add r1, r1, r6
    swr r2, r1
    li r1, 862
    add r1, r1, r6
    lwr r2, r1
    li r1, 601
    add r1, r1, r6
    swr r2, r1
    li r1, 863
    add r1, r1, r6
    lwr r2, r1
    li r1, 603
    add r1, r1, r6
    swr r2, r1
    li r1, 864
    add r1, r1, r6
    lwr r2, r1
    li r1, 605
    add r1, r1, r6
    swr r2, r1
    li r1, 865
    add r1, r1, r6
    lwr r2, r1
    li r1, 607
    add r1, r1, r6
    swr r2, r1
    li r1, 866
    add r1, r1, r6
    lwr r2, r1
    li r1, 609
    add r1, r1, r6
    swr r2, r1
    li r1, 867
    add r1, r1, r6
    lwr r2, r1
    li r1, 611
    add r1, r1, r6
    swr r2, r1
    li r1, 868
    add r1, r1, r6
    lwr r2, r1
    li r1, 613
    add r1, r1, r6
    swr r2, r1
    li r1, 869
    add r1, r1, r6
    lwr r2, r1
    li r1, 615
    add r1, r1, r6
    swr r2, r1
    li r1, 870
    add r1, r1, r6
    lwr r2, r1
    li r1, 617
    add r1, r1, r6
    swr r2, r1
    li r1, 871
    add r1, r1, r6
    lwr r2, r1
    li r1, 619
    add r1, r1, r6
    swr r2, r1
    li r1, 872
    add r1, r1, r6
    lwr r2, r1
    li r1, 621
    add r1, r1, r6
    swr r2, r1
    li r1, 873
    add r1, r1, r6
    lwr r2, r1
    li r1, 623
    add r1, r1, r6
    swr r2, r1
    li r1, 874
    add r1, r1, r6
    lwr r2, r1
    li r1, 625
    add r1, r1, r6
    swr r2, r1
    li r1, 875
    add r1, r1, r6
    lwr r2, r1
    li r1, 627
    add r1, r1, r6
    swr r2, r1
    li r1, 876
    add r1, r1, r6
    lwr r2, r1
    li r1, 629
    add r1, r1, r6
    swr r2, r1
    li r1, 877
    add r1, r1, r6
    lwr r2, r1
    li r1, 631
    add r1, r1, r6
    swr r2, r1
    li r1, 878
    add r1, r1, r6
    lwr r2, r1
    li r1, 633
    add r1, r1, r6
    swr r2, r1
    li r1, 879
    add r1, r1, r6
    lwr r2, r1
    li r1, 635
    add r1, r1, r6
    swr r2, r1
    li r1, 880
    add r1, r1, r6
    lwr r2, r1
    li r1, 637
    add r1, r1, r6
    swr r2, r1
    li r1, 881
    add r1, r1, r6
    lwr r2, r1
    li r1, 639
    add r1, r1, r6
    swr r2, r1
    li r1, 882
    add r1, r1, r6
    lwr r2, r1
    li r1, 641
    add r1, r1, r6
    swr r2, r1
    li r1, 883
    add r1, r1, r6
    lwr r2, r1
    li r1, 643
    add r1, r1, r6
    swr r2, r1
    li r1, 884
    add r1, r1, r6
    lwr r2, r1
    li r1, 645
    add r1, r1, r6
    swr r2, r1
    li r1, 885
    add r1, r1, r6
    lwr r2, r1
    li r1, 647
    add r1, r1, r6
    swr r2, r1
    li r1, 886
    add r1, r1, r6
    lwr r2, r1
    li r1, 649
    add r1, r1, r6
    swr r2, r1
    li r1, 887
    add r1, r1, r6
    lwr r2, r1
    li r1, 651
    add r1, r1, r6
    swr r2, r1
    li r1, 888
    add r1, r1, r6
    lwr r2, r1
    li r1, 653
    add r1, r1, r6
    swr r2, r1
    li r1, 889
    add r1, r1, r6
    lwr r2, r1
    li r1, 655
    add r1, r1, r6
    swr r2, r1
    li r1, 890
    add r1, r1, r6
    lwr r2, r1
    li r1, 657
    add r1, r1, r6
    swr r2, r1
    li r1, 891
    add r1, r1, r6
    lwr r2, r1
    li r1, 659
    add r1, r1, r6
    swr r2, r1
    li r1, 892
    add r1, r1, r6
    lwr r2, r1
    li r1, 661
    add r1, r1, r6
    swr r2, r1
    li r1, 893
    add r1, r1, r6
    lwr r2, r1
    li r1, 663
    add r1, r1, r6
    swr r2, r1
    li r1, 894
    add r1, r1, r6
    lwr r2, r1
    li r1, 665
    add r1, r1, r6
    swr r2, r1
    li r1, 895
    add r1, r1, r6
    lwr r2, r1
    li r1, 667
    add r1, r1, r6
    swr r2, r1
    lui r1, 14
    add r1, r1, r6
    lwr r2, r1
    li r1, 669
    add r1, r1, r6
    swr r2, r1
    li r1, 897
    add r1, r1, r6
    lwr r2, r1
    li r1, 671
    add r1, r1, r6
    swr r2, r1
    li r1, 898
    add r1, r1, r6
    lwr r2, r1
    li r1, 673
    add r1, r1, r6
    swr r2, r1
    li r1, 899
    add r1, r1, r6
    lwr r2, r1
    li r1, 675
    add r1, r1, r6
    swr r2, r1
    li r1, 900
    add r1, r1, r6
    lwr r2, r1
    li r1, 677
    add r1, r1, r6
    swr r2, r1
    li r1, 901
    add r1, r1, r6
    lwr r2, r1
    li r1, 679
    add r1, r1, r6
    swr r2, r1
    li r1, 902
    add r1, r1, r6
    lwr r2, r1
    li r1, 681
    add r1, r1, r6
    swr r2, r1
    li r1, 903
    add r1, r1, r6
    lwr r2, r1
    li r1, 683
    add r1, r1, r6
    swr r2, r1
    li r1, 904
    add r1, r1, r6
    lwr r2, r1
    li r1, 685
    add r1, r1, r6
    swr r2, r1
    li r1, 905
    add r1, r1, r6
    lwr r2, r1
    li r1, 687
    add r1, r1, r6
    swr r2, r1
    li r1, 906
    add r1, r1, r6
    lwr r2, r1
    li r1, 689
    add r1, r1, r6
    swr r2, r1
    li r1, 907
    add r1, r1, r6
    lwr r2, r1
    li r1, 691
    add r1, r1, r6
    swr r2, r1
    li r1, 908
    add r1, r1, r6
    lwr r2, r1
    li r1, 693
    add r1, r1, r6
    swr r2, r1
    li r1, 909
    add r1, r1, r6
    lwr r2, r1
    li r1, 695
    add r1, r1, r6
    swr r2, r1
    li r1, 910
    add r1, r1, r6
    lwr r2, r1
    li r1, 697
    add r1, r1, r6
    swr r2, r1
    li r1, 911
    add r1, r1, r6
    lwr r2, r1
    li r1, 699
    add r1, r1, r6
    swr r2, r1
    li r1, 912
    add r1, r1, r6
    lwr r2, r1
    li r1, 701
    add r1, r1, r6
    swr r2, r1
    li r1, 913
    add r1, r1, r6
    lwr r2, r1
    li r1, 703
    add r1, r1, r6
    swr r2, r1
    li r1, 914
    add r1, r1, r6
    lwr r2, r1
    li r1, 705
    add r1, r1, r6
    swr r2, r1
    li r1, 915
    add r1, r1, r6
    lwr r2, r1
    li r1, 707
    add r1, r1, r6
    swr r2, r1
    li r1, 916
    add r1, r1, r6
    lwr r2, r1
    li r1, 709
    add r1, r1, r6
    swr r2, r1
    li r1, 917
    add r1, r1, r6
    lwr r2, r1
    li r1, 711
    add r1, r1, r6
    swr r2, r1
    li r1, 918
    add r1, r1, r6
    lwr r2, r1
    li r1, 713
    add r1, r1, r6
    swr r2, r1
    li r1, 919
    add r1, r1, r6
    lwr r2, r1
    li r1, 715
    add r1, r1, r6
    swr r2, r1
    li r1, 920
    add r1, r1, r6
    lwr r2, r1
    li r1, 717
    add r1, r1, r6
    swr r2, r1
    li r1, 921
    add r1, r1, r6
    lwr r2, r1
    li r1, 718
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_1
_B_main_122:
    li r1, 922
    add r1, r1, r6
    lwr r2, r1
    li r1, 317
    add r1, r1, r6
    swr r2, r1
    li r1, 923
    add r1, r1, r6
    lwr r2, r1
    li r1, 319
    add r1, r1, r6
    swr r2, r1
    li r1, 924
    add r1, r1, r6
    lwr r2, r1
    li r1, 67
    add r1, r1, r6
    swr r2, r1
    li r1, 925
    add r1, r1, r6
    lwr r2, r1
    li r1, 323
    add r1, r1, r6
    swr r2, r1
    li r1, 926
    add r1, r1, r6
    lwr r2, r1
    li r1, 325
    add r1, r1, r6
    swr r2, r1
    li r1, 927
    add r1, r1, r6
    lwr r2, r1
    li r1, 327
    add r1, r1, r6
    swr r2, r1
    li r1, 928
    add r1, r1, r6
    lwr r2, r1
    li r1, 329
    add r1, r1, r6
    swr r2, r1
    li r1, 929
    add r1, r1, r6
    lwr r2, r1
    li r1, 331
    add r1, r1, r6
    swr r2, r1
    li r1, 930
    add r1, r1, r6
    lwr r2, r1
    li r1, 333
    add r1, r1, r6
    swr r2, r1
    li r1, 931
    add r1, r1, r6
    lwr r2, r1
    li r1, 335
    add r1, r1, r6
    swr r2, r1
    li r1, 932
    add r1, r1, r6
    lwr r2, r1
    li r1, 337
    add r1, r1, r6
    swr r2, r1
    li r1, 933
    add r1, r1, r6
    lwr r2, r1
    li r1, 339
    add r1, r1, r6
    swr r2, r1
    li r1, 934
    add r1, r1, r6
    lwr r2, r1
    li r1, 341
    add r1, r1, r6
    swr r2, r1
    li r1, 935
    add r1, r1, r6
    lwr r2, r1
    li r1, 343
    add r1, r1, r6
    swr r2, r1
    li r1, 936
    add r1, r1, r6
    lwr r2, r1
    li r1, 345
    add r1, r1, r6
    swr r2, r1
    li r1, 937
    add r1, r1, r6
    lwr r2, r1
    li r1, 347
    add r1, r1, r6
    swr r2, r1
    li r1, 939
    add r1, r1, r6
    lwr r2, r1
    li r1, 938
    add r1, r1, r6
    swr r2, r1
    li r1, 940
    add r1, r1, r6
    lwr r2, r1
    li r1, 351
    add r1, r1, r6
    swr r2, r1
    li r1, 941
    add r1, r1, r6
    lwr r2, r1
    li r1, 353
    add r1, r1, r6
    swr r2, r1
    li r1, 942
    add r1, r1, r6
    lwr r2, r1
    li r1, 355
    add r1, r1, r6
    swr r2, r1
    li r1, 943
    add r1, r1, r6
    lwr r2, r1
    li r1, 357
    add r1, r1, r6
    swr r2, r1
    li r1, 944
    add r1, r1, r6
    lwr r2, r1
    li r1, 359
    add r1, r1, r6
    swr r2, r1
    li r1, 945
    add r1, r1, r6
    lwr r2, r1
    li r1, 361
    add r1, r1, r6
    swr r2, r1
    li r1, 946
    add r1, r1, r6
    lwr r2, r1
    li r1, 363
    add r1, r1, r6
    swr r2, r1
    li r1, 947
    add r1, r1, r6
    lwr r2, r1
    li r1, 365
    add r1, r1, r6
    swr r2, r1
    li r1, 948
    add r1, r1, r6
    lwr r2, r1
    li r1, 367
    add r1, r1, r6
    swr r2, r1
    li r1, 949
    add r1, r1, r6
    lwr r2, r1
    li r1, 369
    add r1, r1, r6
    swr r2, r1
    li r1, 951
    add r1, r1, r6
    lwr r2, r1
    li r1, 950
    add r1, r1, r6
    swr r2, r1
    li r1, 952
    add r1, r1, r6
    lwr r2, r1
    li r1, 373
    add r1, r1, r6
    swr r2, r1
    li r1, 953
    add r1, r1, r6
    lwr r2, r1
    li r1, 375
    add r1, r1, r6
    swr r2, r1
    li r1, 954
    add r1, r1, r6
    lwr r2, r1
    li r1, 377
    add r1, r1, r6
    swr r2, r1
    li r1, 955
    add r1, r1, r6
    lwr r2, r1
    li r1, 379
    add r1, r1, r6
    swr r2, r1
    li r1, 956
    add r1, r1, r6
    lwr r2, r1
    li r1, 381
    add r1, r1, r6
    swr r2, r1
    li r1, 957
    add r1, r1, r6
    lwr r2, r1
    li r1, 383
    add r1, r1, r6
    swr r2, r1
    li r1, 958
    add r1, r1, r6
    lwr r2, r1
    li r1, 385
    add r1, r1, r6
    swr r2, r1
    li r1, 959
    add r1, r1, r6
    lwr r2, r1
    li r1, 387
    add r1, r1, r6
    swr r2, r1
    lui r1, 15
    add r1, r1, r6
    lwr r2, r1
    li r1, 389
    add r1, r1, r6
    swr r2, r1
    li r1, 961
    add r1, r1, r6
    lwr r2, r1
    li r1, 391
    add r1, r1, r6
    swr r2, r1
    li r1, 963
    add r1, r1, r6
    lwr r2, r1
    li r1, 962
    add r1, r1, r6
    swr r2, r1
    li r1, 964
    add r1, r1, r6
    lwr r2, r1
    li r1, 395
    add r1, r1, r6
    swr r2, r1
    li r1, 965
    add r1, r1, r6
    lwr r2, r1
    li r1, 397
    add r1, r1, r6
    swr r2, r1
    li r1, 966
    add r1, r1, r6
    lwr r2, r1
    li r1, 399
    add r1, r1, r6
    swr r2, r1
    li r1, 967
    add r1, r1, r6
    lwr r2, r1
    li r1, 401
    add r1, r1, r6
    swr r2, r1
    li r1, 968
    add r1, r1, r6
    lwr r2, r1
    li r1, 403
    add r1, r1, r6
    swr r2, r1
    li r1, 969
    add r1, r1, r6
    lwr r2, r1
    li r1, 405
    add r1, r1, r6
    swr r2, r1
    li r1, 970
    add r1, r1, r6
    lwr r2, r1
    li r1, 407
    add r1, r1, r6
    swr r2, r1
    li r1, 971
    add r1, r1, r6
    lwr r2, r1
    li r1, 409
    add r1, r1, r6
    swr r2, r1
    li r1, 972
    add r1, r1, r6
    lwr r2, r1
    li r1, 411
    add r1, r1, r6
    swr r2, r1
    li r1, 973
    add r1, r1, r6
    lwr r2, r1
    li r1, 413
    add r1, r1, r6
    swr r2, r1
    li r1, 975
    add r1, r1, r6
    lwr r2, r1
    li r1, 974
    add r1, r1, r6
    swr r2, r1
    li r1, 976
    add r1, r1, r6
    lwr r2, r1
    li r1, 417
    add r1, r1, r6
    swr r2, r1
    li r1, 977
    add r1, r1, r6
    lwr r2, r1
    li r1, 419
    add r1, r1, r6
    swr r2, r1
    li r1, 978
    add r1, r1, r6
    lwr r2, r1
    li r1, 421
    add r1, r1, r6
    swr r2, r1
    li r1, 979
    add r1, r1, r6
    lwr r2, r1
    li r1, 423
    add r1, r1, r6
    swr r2, r1
    li r1, 980
    add r1, r1, r6
    lwr r2, r1
    li r1, 425
    add r1, r1, r6
    swr r2, r1
    li r1, 981
    add r1, r1, r6
    lwr r2, r1
    li r1, 427
    add r1, r1, r6
    swr r2, r1
    li r1, 982
    add r1, r1, r6
    lwr r2, r1
    li r1, 429
    add r1, r1, r6
    swr r2, r1
    li r1, 983
    add r1, r1, r6
    lwr r2, r1
    li r1, 431
    add r1, r1, r6
    swr r2, r1
    li r1, 984
    add r1, r1, r6
    lwr r2, r1
    li r1, 433
    add r1, r1, r6
    swr r2, r1
    li r1, 985
    add r1, r1, r6
    lwr r2, r1
    li r1, 435
    add r1, r1, r6
    swr r2, r1
    li r1, 71
    add r1, r1, r6
    lwr r2, r1
    li r1, 986
    add r1, r1, r6
    swr r2, r1
    li r1, 987
    add r1, r1, r6
    lwr r2, r1
    li r1, 439
    add r1, r1, r6
    swr r2, r1
    li r1, 988
    add r1, r1, r6
    lwr r2, r1
    li r1, 441
    add r1, r1, r6
    swr r2, r1
    li r1, 989
    add r1, r1, r6
    lwr r2, r1
    li r1, 443
    add r1, r1, r6
    swr r2, r1
    li r1, 990
    add r1, r1, r6
    lwr r2, r1
    li r1, 445
    add r1, r1, r6
    swr r2, r1
    li r1, 991
    add r1, r1, r6
    lwr r2, r1
    li r1, 447
    add r1, r1, r6
    swr r2, r1
    li r1, 992
    add r1, r1, r6
    lwr r2, r1
    li r1, 449
    add r1, r1, r6
    swr r2, r1
    li r1, 993
    add r1, r1, r6
    lwr r2, r1
    li r1, 451
    add r1, r1, r6
    swr r2, r1
    li r1, 994
    add r1, r1, r6
    lwr r2, r1
    li r1, 453
    add r1, r1, r6
    swr r2, r1
    li r1, 995
    add r1, r1, r6
    lwr r2, r1
    li r1, 455
    add r1, r1, r6
    swr r2, r1
    li r1, 996
    add r1, r1, r6
    lwr r2, r1
    li r1, 457
    add r1, r1, r6
    swr r2, r1
    li r1, 69
    add r1, r1, r6
    lwr r2, r1
    li r1, 997
    add r1, r1, r6
    swr r2, r1
    li r1, 998
    add r1, r1, r6
    lwr r2, r1
    li r1, 461
    add r1, r1, r6
    swr r2, r1
    li r1, 999
    add r1, r1, r6
    lwr r2, r1
    li r1, 463
    add r1, r1, r6
    swr r2, r1
    li r1, 1000
    add r1, r1, r6
    lwr r2, r1
    li r1, 465
    add r1, r1, r6
    swr r2, r1
    li r1, 1001
    add r1, r1, r6
    lwr r2, r1
    li r1, 467
    add r1, r1, r6
    swr r2, r1
    li r1, 1002
    add r1, r1, r6
    lwr r2, r1
    li r1, 469
    add r1, r1, r6
    swr r2, r1
    li r1, 1003
    add r1, r1, r6
    lwr r2, r1
    li r1, 471
    add r1, r1, r6
    swr r2, r1
    li r1, 1004
    add r1, r1, r6
    lwr r2, r1
    li r1, 473
    add r1, r1, r6
    swr r2, r1
    li r1, 1005
    add r1, r1, r6
    lwr r2, r1
    li r1, 475
    add r1, r1, r6
    swr r2, r1
    li r1, 1006
    add r1, r1, r6
    lwr r2, r1
    li r1, 477
    add r1, r1, r6
    swr r2, r1
    li r1, 1007
    add r1, r1, r6
    lwr r2, r1
    li r1, 479
    add r1, r1, r6
    swr r2, r1
    li r1, 76
    add r1, r1, r6
    lwr r2, r1
    li r1, 1008
    add r1, r1, r6
    swr r2, r1
    li r1, 1009
    add r1, r1, r6
    lwr r2, r1
    li r1, 483
    add r1, r1, r6
    swr r2, r1
    li r1, 1010
    add r1, r1, r6
    lwr r2, r1
    li r1, 485
    add r1, r1, r6
    swr r2, r1
    li r1, 1011
    add r1, r1, r6
    lwr r2, r1
    li r1, 487
    add r1, r1, r6
    swr r2, r1
    li r1, 1012
    add r1, r1, r6
    lwr r2, r1
    li r1, 489
    add r1, r1, r6
    swr r2, r1
    li r1, 1013
    add r1, r1, r6
    lwr r2, r1
    li r1, 491
    add r1, r1, r6
    swr r2, r1
    li r1, 1014
    add r1, r1, r6
    lwr r2, r1
    li r1, 493
    add r1, r1, r6
    swr r2, r1
    li r1, 1015
    add r1, r1, r6
    lwr r2, r1
    li r1, 495
    add r1, r1, r6
    swr r2, r1
    li r1, 1016
    add r1, r1, r6
    lwr r2, r1
    li r1, 497
    add r1, r1, r6
    swr r2, r1
    li r1, 1017
    add r1, r1, r6
    lwr r2, r1
    li r1, 499
    add r1, r1, r6
    swr r2, r1
    li r1, 1018
    add r1, r1, r6
    lwr r2, r1
    li r1, 501
    add r1, r1, r6
    swr r2, r1
    li r1, 68
    add r1, r1, r6
    lwr r2, r1
    li r1, 1019
    add r1, r1, r6
    swr r2, r1
    li r1, 1020
    add r1, r1, r6
    lwr r2, r1
    li r1, 504
    add r1, r1, r6
    swr r2, r1
    li r1, 1021
    add r1, r1, r6
    lwr r2, r1
    li r1, 506
    add r1, r1, r6
    swr r2, r1
    li r1, 1022
    add r1, r1, r6
    lwr r2, r1
    li r1, 508
    add r1, r1, r6
    swr r2, r1
    li r1, 1023
    add r1, r1, r6
    lwr r2, r1
    li r1, 510
    add r1, r1, r6
    swr r2, r1
    lui r1, 16
    add r1, r1, r6
    lwr r2, r1
    lui r1, 8
    add r1, r1, r6
    swr r2, r1
    li r1, 1025
    add r1, r1, r6
    lwr r2, r1
    li r1, 514
    add r1, r1, r6
    swr r2, r1
    li r1, 1026
    add r1, r1, r6
    lwr r2, r1
    li r1, 516
    add r1, r1, r6
    swr r2, r1
    li r1, 1027
    add r1, r1, r6
    lwr r2, r1
    li r1, 518
    add r1, r1, r6
    swr r2, r1
    li r1, 1028
    add r1, r1, r6
    lwr r2, r1
    li r1, 520
    add r1, r1, r6
    swr r2, r1
    li r1, 1029
    add r1, r1, r6
    lwr r2, r1
    li r1, 522
    add r1, r1, r6
    swr r2, r1
    li r1, 1030
    add r1, r1, r6
    lwr r2, r1
    li r1, 524
    add r1, r1, r6
    swr r2, r1
    li r1, 1031
    add r1, r1, r6
    lwr r2, r1
    li r1, 526
    add r1, r1, r6
    swr r2, r1
    li r1, 1032
    add r1, r1, r6
    lwr r2, r1
    li r1, 528
    add r1, r1, r6
    swr r2, r1
    li r1, 1033
    add r1, r1, r6
    lwr r2, r1
    li r1, 530
    add r1, r1, r6
    swr r2, r1
    li r1, 1034
    add r1, r1, r6
    lwr r2, r1
    li r1, 532
    add r1, r1, r6
    swr r2, r1
    li r1, 1035
    add r1, r1, r6
    lwr r2, r1
    li r1, 534
    add r1, r1, r6
    swr r2, r1
    li r1, 1036
    add r1, r1, r6
    lwr r2, r1
    li r1, 536
    add r1, r1, r6
    swr r2, r1
    li r1, 1037
    add r1, r1, r6
    lwr r2, r1
    li r1, 538
    add r1, r1, r6
    swr r2, r1
    li r1, 1038
    add r1, r1, r6
    lwr r2, r1
    li r1, 540
    add r1, r1, r6
    swr r2, r1
    li r1, 1039
    add r1, r1, r6
    lwr r2, r1
    li r1, 542
    add r1, r1, r6
    swr r2, r1
    li r1, 1040
    add r1, r1, r6
    lwr r2, r1
    li r1, 544
    add r1, r1, r6
    swr r2, r1
    li r1, 1041
    add r1, r1, r6
    lwr r2, r1
    li r1, 546
    add r1, r1, r6
    swr r2, r1
    li r1, 1042
    add r1, r1, r6
    lwr r2, r1
    li r1, 548
    add r1, r1, r6
    swr r2, r1
    li r1, 1043
    add r1, r1, r6
    lwr r2, r1
    li r1, 550
    add r1, r1, r6
    swr r2, r1
    li r1, 1044
    add r1, r1, r6
    lwr r2, r1
    li r1, 552
    add r1, r1, r6
    swr r2, r1
    li r1, 1045
    add r1, r1, r6
    lwr r2, r1
    li r1, 554
    add r1, r1, r6
    swr r2, r1
    li r1, 1046
    add r1, r1, r6
    lwr r2, r1
    li r1, 556
    add r1, r1, r6
    swr r2, r1
    li r1, 1047
    add r1, r1, r6
    lwr r2, r1
    li r1, 558
    add r1, r1, r6
    swr r2, r1
    li r1, 1048
    add r1, r1, r6
    lwr r2, r1
    li r1, 560
    add r1, r1, r6
    swr r2, r1
    li r1, 1049
    add r1, r1, r6
    lwr r2, r1
    li r1, 562
    add r1, r1, r6
    swr r2, r1
    li r1, 1050
    add r1, r1, r6
    lwr r2, r1
    li r1, 564
    add r1, r1, r6
    swr r2, r1
    li r1, 1051
    add r1, r1, r6
    lwr r2, r1
    li r1, 566
    add r1, r1, r6
    swr r2, r1
    li r1, 1052
    add r1, r1, r6
    lwr r2, r1
    li r1, 568
    add r1, r1, r6
    swr r2, r1
    li r1, 1053
    add r1, r1, r6
    lwr r2, r1
    li r1, 570
    add r1, r1, r6
    swr r2, r1
    li r1, 1054
    add r1, r1, r6
    lwr r2, r1
    li r1, 572
    add r1, r1, r6
    swr r2, r1
    li r1, 1055
    add r1, r1, r6
    lwr r2, r1
    li r1, 574
    add r1, r1, r6
    swr r2, r1
    li r1, 1056
    add r1, r1, r6
    lwr r2, r1
    lui r1, 9
    add r1, r1, r6
    swr r2, r1
    li r1, 1057
    add r1, r1, r6
    lwr r2, r1
    li r1, 578
    add r1, r1, r6
    swr r2, r1
    li r1, 1058
    add r1, r1, r6
    lwr r2, r1
    li r1, 580
    add r1, r1, r6
    swr r2, r1
    li r1, 1059
    add r1, r1, r6
    lwr r2, r1
    li r1, 582
    add r1, r1, r6
    swr r2, r1
    li r1, 1060
    add r1, r1, r6
    lwr r2, r1
    li r1, 584
    add r1, r1, r6
    swr r2, r1
    li r1, 1061
    add r1, r1, r6
    lwr r2, r1
    li r1, 586
    add r1, r1, r6
    swr r2, r1
    li r1, 1062
    add r1, r1, r6
    lwr r2, r1
    li r1, 588
    add r1, r1, r6
    swr r2, r1
    li r1, 1063
    add r1, r1, r6
    lwr r2, r1
    li r1, 590
    add r1, r1, r6
    swr r2, r1
    li r1, 1064
    add r1, r1, r6
    lwr r2, r1
    li r1, 592
    add r1, r1, r6
    swr r2, r1
    li r1, 1065
    add r1, r1, r6
    lwr r2, r1
    li r1, 594
    add r1, r1, r6
    swr r2, r1
    li r1, 1066
    add r1, r1, r6
    lwr r2, r1
    li r1, 596
    add r1, r1, r6
    swr r2, r1
    li r1, 1067
    add r1, r1, r6
    lwr r2, r1
    li r1, 598
    add r1, r1, r6
    swr r2, r1
    li r1, 1068
    add r1, r1, r6
    lwr r2, r1
    li r1, 600
    add r1, r1, r6
    swr r2, r1
    li r1, 1069
    add r1, r1, r6
    lwr r2, r1
    li r1, 602
    add r1, r1, r6
    swr r2, r1
    li r1, 1070
    add r1, r1, r6
    lwr r2, r1
    li r1, 604
    add r1, r1, r6
    swr r2, r1
    li r1, 1071
    add r1, r1, r6
    lwr r2, r1
    li r1, 606
    add r1, r1, r6
    swr r2, r1
    li r1, 1072
    add r1, r1, r6
    lwr r2, r1
    li r1, 608
    add r1, r1, r6
    swr r2, r1
    li r1, 1073
    add r1, r1, r6
    lwr r2, r1
    li r1, 610
    add r1, r1, r6
    swr r2, r1
    li r1, 1074
    add r1, r1, r6
    lwr r2, r1
    li r1, 612
    add r1, r1, r6
    swr r2, r1
    li r1, 1075
    add r1, r1, r6
    lwr r2, r1
    li r1, 614
    add r1, r1, r6
    swr r2, r1
    li r1, 1076
    add r1, r1, r6
    lwr r2, r1
    li r1, 616
    add r1, r1, r6
    swr r2, r1
    li r1, 1077
    add r1, r1, r6
    lwr r2, r1
    li r1, 618
    add r1, r1, r6
    swr r2, r1
    li r1, 1078
    add r1, r1, r6
    lwr r2, r1
    li r1, 620
    add r1, r1, r6
    swr r2, r1
    li r1, 1079
    add r1, r1, r6
    lwr r2, r1
    li r1, 622
    add r1, r1, r6
    swr r2, r1
    li r1, 1080
    add r1, r1, r6
    lwr r2, r1
    li r1, 624
    add r1, r1, r6
    swr r2, r1
    li r1, 1081
    add r1, r1, r6
    lwr r2, r1
    li r1, 626
    add r1, r1, r6
    swr r2, r1
    li r1, 83
    add r1, r1, r6
    lwr r2, r1
    li r1, 628
    add r1, r1, r6
    swr r2, r1
    li r1, 1082
    add r1, r1, r6
    lwr r2, r1
    li r1, 630
    add r1, r1, r6
    swr r2, r1
    li r1, 1083
    add r1, r1, r6
    lwr r2, r1
    li r1, 632
    add r1, r1, r6
    swr r2, r1
    li r1, 1084
    add r1, r1, r6
    lwr r2, r1
    li r1, 634
    add r1, r1, r6
    swr r2, r1
    li r1, 1085
    add r1, r1, r6
    lwr r2, r1
    li r1, 636
    add r1, r1, r6
    swr r2, r1
    li r1, 1086
    add r1, r1, r6
    lwr r2, r1
    li r1, 638
    add r1, r1, r6
    swr r2, r1
    li r1, 1087
    add r1, r1, r6
    lwr r2, r1
    lui r1, 10
    add r1, r1, r6
    swr r2, r1
    lui r1, 17
    add r1, r1, r6
    lwr r2, r1
    li r1, 642
    add r1, r1, r6
    swr r2, r1
    li r1, 1089
    add r1, r1, r6
    lwr r2, r1
    li r1, 644
    add r1, r1, r6
    swr r2, r1
    li r1, 1090
    add r1, r1, r6
    lwr r2, r1
    li r1, 646
    add r1, r1, r6
    swr r2, r1
    li r1, 1091
    add r1, r1, r6
    lwr r2, r1
    li r1, 648
    add r1, r1, r6
    swr r2, r1
    li r1, 82
    add r1, r1, r6
    lwr r2, r1
    li r1, 650
    add r1, r1, r6
    swr r2, r1
    li r1, 1092
    add r1, r1, r6
    lwr r2, r1
    li r1, 652
    add r1, r1, r6
    swr r2, r1
    li r1, 1093
    add r1, r1, r6
    lwr r2, r1
    li r1, 654
    add r1, r1, r6
    swr r2, r1
    li r1, 1094
    add r1, r1, r6
    lwr r2, r1
    li r1, 656
    add r1, r1, r6
    swr r2, r1
    li r1, 1095
    add r1, r1, r6
    lwr r2, r1
    li r1, 658
    add r1, r1, r6
    swr r2, r1
    li r1, 1096
    add r1, r1, r6
    lwr r2, r1
    li r1, 660
    add r1, r1, r6
    swr r2, r1
    li r1, 1097
    add r1, r1, r6
    lwr r2, r1
    li r1, 662
    add r1, r1, r6
    swr r2, r1
    li r1, 1098
    add r1, r1, r6
    lwr r2, r1
    li r1, 664
    add r1, r1, r6
    swr r2, r1
    li r1, 1099
    add r1, r1, r6
    lwr r2, r1
    li r1, 666
    add r1, r1, r6
    swr r2, r1
    li r1, 1100
    add r1, r1, r6
    lwr r2, r1
    li r1, 668
    add r1, r1, r6
    swr r2, r1
    li r1, 1101
    add r1, r1, r6
    lwr r2, r1
    li r1, 670
    add r1, r1, r6
    swr r2, r1
    li r1, 94
    add r1, r1, r6
    lwr r2, r1
    li r1, 672
    add r1, r1, r6
    swr r2, r1
    li r1, 1102
    add r1, r1, r6
    lwr r2, r1
    li r1, 674
    add r1, r1, r6
    swr r2, r1
    li r1, 1103
    add r1, r1, r6
    lwr r2, r1
    li r1, 676
    add r1, r1, r6
    swr r2, r1
    li r1, 1104
    add r1, r1, r6
    lwr r2, r1
    li r1, 678
    add r1, r1, r6
    swr r2, r1
    li r1, 1105
    add r1, r1, r6
    lwr r2, r1
    li r1, 680
    add r1, r1, r6
    swr r2, r1
    li r1, 1106
    add r1, r1, r6
    lwr r2, r1
    li r1, 682
    add r1, r1, r6
    swr r2, r1
    li r1, 1107
    add r1, r1, r6
    lwr r2, r1
    li r1, 684
    add r1, r1, r6
    swr r2, r1
    li r1, 1108
    add r1, r1, r6
    lwr r2, r1
    li r1, 686
    add r1, r1, r6
    swr r2, r1
    li r1, 1109
    add r1, r1, r6
    lwr r2, r1
    li r1, 688
    add r1, r1, r6
    swr r2, r1
    li r1, 1110
    add r1, r1, r6
    lwr r2, r1
    li r1, 690
    add r1, r1, r6
    swr r2, r1
    li r1, 1111
    add r1, r1, r6
    lwr r2, r1
    li r1, 692
    add r1, r1, r6
    swr r2, r1
    li r1, 81
    add r1, r1, r6
    lwr r2, r1
    li r1, 1112
    add r1, r1, r6
    swr r2, r1
    li r1, 1113
    add r1, r1, r6
    lwr r2, r1
    li r1, 696
    add r1, r1, r6
    swr r2, r1
    li r1, 1114
    add r1, r1, r6
    lwr r2, r1
    li r1, 698
    add r1, r1, r6
    swr r2, r1
    li r1, 1115
    add r1, r1, r6
    lwr r2, r1
    li r1, 700
    add r1, r1, r6
    swr r2, r1
    li r1, 1116
    add r1, r1, r6
    lwr r2, r1
    li r1, 702
    add r1, r1, r6
    swr r2, r1
    li r1, 1117
    add r1, r1, r6
    lwr r2, r1
    lui r1, 11
    add r1, r1, r6
    swr r2, r1
    li r1, 1118
    add r1, r1, r6
    lwr r2, r1
    li r1, 706
    add r1, r1, r6
    swr r2, r1
    li r1, 1119
    add r1, r1, r6
    lwr r2, r1
    li r1, 708
    add r1, r1, r6
    swr r2, r1
    li r1, 1120
    add r1, r1, r6
    lwr r2, r1
    li r1, 710
    add r1, r1, r6
    swr r2, r1
    li r1, 1121
    add r1, r1, r6
    lwr r2, r1
    li r1, 712
    add r1, r1, r6
    swr r2, r1
    li r1, 1122
    add r1, r1, r6
    lwr r2, r1
    li r1, 714
    add r1, r1, r6
    swr r2, r1
    li r1, 80
    add r1, r1, r6
    lwr r2, r1
    li r1, 1123
    add r1, r1, r6
    swr r2, r1
    li r1, 66
    add r1, r1, r6
    lwr r2, r1
    li r1, 1124
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_3
_B_main_123:
    li r1, 316
    add r1, r1, r6
    lwr r2, r1
    li r1, 317
    add r1, r1, r6
    swr r2, r1
    li r1, 318
    add r1, r1, r6
    lwr r2, r1
    li r1, 319
    add r1, r1, r6
    swr r2, r1
    li r1, 65
    add r1, r1, r6
    lwr r2, r1
    li r1, 67
    add r1, r1, r6
    swr r2, r1
    li r1, 322
    add r1, r1, r6
    lwr r2, r1
    li r1, 323
    add r1, r1, r6
    swr r2, r1
    li r1, 324
    add r1, r1, r6
    lwr r2, r1
    li r1, 325
    add r1, r1, r6
    swr r2, r1
    li r1, 326
    add r1, r1, r6
    lwr r2, r1
    li r1, 327
    add r1, r1, r6
    swr r2, r1
    li r1, 328
    add r1, r1, r6
    lwr r2, r1
    li r1, 329
    add r1, r1, r6
    swr r2, r1
    li r1, 330
    add r1, r1, r6
    lwr r2, r1
    li r1, 331
    add r1, r1, r6
    swr r2, r1
    li r1, 332
    add r1, r1, r6
    lwr r2, r1
    li r1, 333
    add r1, r1, r6
    swr r2, r1
    li r1, 334
    add r1, r1, r6
    lwr r2, r1
    li r1, 335
    add r1, r1, r6
    swr r2, r1
    li r1, 336
    add r1, r1, r6
    lwr r2, r1
    li r1, 337
    add r1, r1, r6
    swr r2, r1
    li r1, 338
    add r1, r1, r6
    lwr r2, r1
    li r1, 339
    add r1, r1, r6
    swr r2, r1
    li r1, 340
    add r1, r1, r6
    lwr r2, r1
    li r1, 341
    add r1, r1, r6
    swr r2, r1
    li r1, 342
    add r1, r1, r6
    lwr r2, r1
    li r1, 343
    add r1, r1, r6
    swr r2, r1
    li r1, 344
    add r1, r1, r6
    lwr r2, r1
    li r1, 345
    add r1, r1, r6
    swr r2, r1
    li r1, 346
    add r1, r1, r6
    lwr r2, r1
    li r1, 347
    add r1, r1, r6
    swr r2, r1
    li r1, 348
    add r1, r1, r6
    lwr r2, r1
    li r1, 938
    add r1, r1, r6
    swr r2, r1
    li r1, 350
    add r1, r1, r6
    lwr r2, r1
    li r1, 351
    add r1, r1, r6
    swr r2, r1
    li r1, 352
    add r1, r1, r6
    lwr r2, r1
    li r1, 353
    add r1, r1, r6
    swr r2, r1
    li r1, 354
    add r1, r1, r6
    lwr r2, r1
    li r1, 355
    add r1, r1, r6
    swr r2, r1
    li r1, 356
    add r1, r1, r6
    lwr r2, r1
    li r1, 357
    add r1, r1, r6
    swr r2, r1
    li r1, 358
    add r1, r1, r6
    lwr r2, r1
    li r1, 359
    add r1, r1, r6
    swr r2, r1
    li r1, 360
    add r1, r1, r6
    lwr r2, r1
    li r1, 361
    add r1, r1, r6
    swr r2, r1
    li r1, 362
    add r1, r1, r6
    lwr r2, r1
    li r1, 363
    add r1, r1, r6
    swr r2, r1
    li r1, 364
    add r1, r1, r6
    lwr r2, r1
    li r1, 365
    add r1, r1, r6
    swr r2, r1
    li r1, 366
    add r1, r1, r6
    lwr r2, r1
    li r1, 367
    add r1, r1, r6
    swr r2, r1
    li r1, 368
    add r1, r1, r6
    lwr r2, r1
    li r1, 369
    add r1, r1, r6
    swr r2, r1
    li r1, 370
    add r1, r1, r6
    lwr r2, r1
    li r1, 950
    add r1, r1, r6
    swr r2, r1
    li r1, 372
    add r1, r1, r6
    lwr r2, r1
    li r1, 373
    add r1, r1, r6
    swr r2, r1
    li r1, 374
    add r1, r1, r6
    lwr r2, r1
    li r1, 375
    add r1, r1, r6
    swr r2, r1
    li r1, 376
    add r1, r1, r6
    lwr r2, r1
    li r1, 377
    add r1, r1, r6
    swr r2, r1
    li r1, 378
    add r1, r1, r6
    lwr r2, r1
    li r1, 379
    add r1, r1, r6
    swr r2, r1
    li r1, 380
    add r1, r1, r6
    lwr r2, r1
    li r1, 381
    add r1, r1, r6
    swr r2, r1
    li r1, 382
    add r1, r1, r6
    lwr r2, r1
    li r1, 383
    add r1, r1, r6
    swr r2, r1
    lui r1, 6
    add r1, r1, r6
    lwr r2, r1
    li r1, 385
    add r1, r1, r6
    swr r2, r1
    li r1, 386
    add r1, r1, r6
    lwr r2, r1
    li r1, 387
    add r1, r1, r6
    swr r2, r1
    li r1, 388
    add r1, r1, r6
    lwr r2, r1
    li r1, 389
    add r1, r1, r6
    swr r2, r1
    li r1, 390
    add r1, r1, r6
    lwr r2, r1
    li r1, 391
    add r1, r1, r6
    swr r2, r1
    li r1, 392
    add r1, r1, r6
    lwr r2, r1
    li r1, 962
    add r1, r1, r6
    swr r2, r1
    li r1, 394
    add r1, r1, r6
    lwr r2, r1
    li r1, 395
    add r1, r1, r6
    swr r2, r1
    li r1, 396
    add r1, r1, r6
    lwr r2, r1
    li r1, 397
    add r1, r1, r6
    swr r2, r1
    li r1, 398
    add r1, r1, r6
    lwr r2, r1
    li r1, 399
    add r1, r1, r6
    swr r2, r1
    li r1, 400
    add r1, r1, r6
    lwr r2, r1
    li r1, 401
    add r1, r1, r6
    swr r2, r1
    li r1, 402
    add r1, r1, r6
    lwr r2, r1
    li r1, 403
    add r1, r1, r6
    swr r2, r1
    li r1, 404
    add r1, r1, r6
    lwr r2, r1
    li r1, 405
    add r1, r1, r6
    swr r2, r1
    li r1, 406
    add r1, r1, r6
    lwr r2, r1
    li r1, 407
    add r1, r1, r6
    swr r2, r1
    li r1, 408
    add r1, r1, r6
    lwr r2, r1
    li r1, 409
    add r1, r1, r6
    swr r2, r1
    li r1, 410
    add r1, r1, r6
    lwr r2, r1
    li r1, 411
    add r1, r1, r6
    swr r2, r1
    li r1, 412
    add r1, r1, r6
    lwr r2, r1
    li r1, 413
    add r1, r1, r6
    swr r2, r1
    li r1, 414
    add r1, r1, r6
    lwr r2, r1
    li r1, 974
    add r1, r1, r6
    swr r2, r1
    li r1, 416
    add r1, r1, r6
    lwr r2, r1
    li r1, 417
    add r1, r1, r6
    swr r2, r1
    li r1, 418
    add r1, r1, r6
    lwr r2, r1
    li r1, 419
    add r1, r1, r6
    swr r2, r1
    li r1, 420
    add r1, r1, r6
    lwr r2, r1
    li r1, 421
    add r1, r1, r6
    swr r2, r1
    li r1, 422
    add r1, r1, r6
    lwr r2, r1
    li r1, 423
    add r1, r1, r6
    swr r2, r1
    li r1, 424
    add r1, r1, r6
    lwr r2, r1
    li r1, 425
    add r1, r1, r6
    swr r2, r1
    li r1, 426
    add r1, r1, r6
    lwr r2, r1
    li r1, 427
    add r1, r1, r6
    swr r2, r1
    li r1, 428
    add r1, r1, r6
    lwr r2, r1
    li r1, 429
    add r1, r1, r6
    swr r2, r1
    li r1, 430
    add r1, r1, r6
    lwr r2, r1
    li r1, 431
    add r1, r1, r6
    swr r2, r1
    li r1, 432
    add r1, r1, r6
    lwr r2, r1
    li r1, 433
    add r1, r1, r6
    swr r2, r1
    li r1, 434
    add r1, r1, r6
    lwr r2, r1
    li r1, 435
    add r1, r1, r6
    swr r2, r1
    li r1, 436
    add r1, r1, r6
    lwr r2, r1
    li r1, 986
    add r1, r1, r6
    swr r2, r1
    li r1, 438
    add r1, r1, r6
    lwr r2, r1
    li r1, 439
    add r1, r1, r6
    swr r2, r1
    li r1, 440
    add r1, r1, r6
    lwr r2, r1
    li r1, 441
    add r1, r1, r6
    swr r2, r1
    li r1, 442
    add r1, r1, r6
    lwr r2, r1
    li r1, 443
    add r1, r1, r6
    swr r2, r1
    li r1, 444
    add r1, r1, r6
    lwr r2, r1
    li r1, 445
    add r1, r1, r6
    swr r2, r1
    li r1, 446
    add r1, r1, r6
    lwr r2, r1
    li r1, 447
    add r1, r1, r6
    swr r2, r1
    lui r1, 7
    add r1, r1, r6
    lwr r2, r1
    li r1, 449
    add r1, r1, r6
    swr r2, r1
    li r1, 450
    add r1, r1, r6
    lwr r2, r1
    li r1, 451
    add r1, r1, r6
    swr r2, r1
    li r1, 452
    add r1, r1, r6
    lwr r2, r1
    li r1, 453
    add r1, r1, r6
    swr r2, r1
    li r1, 454
    add r1, r1, r6
    lwr r2, r1
    li r1, 455
    add r1, r1, r6
    swr r2, r1
    li r1, 456
    add r1, r1, r6
    lwr r2, r1
    li r1, 457
    add r1, r1, r6
    swr r2, r1
    li r1, 458
    add r1, r1, r6
    lwr r2, r1
    li r1, 997
    add r1, r1, r6
    swr r2, r1
    li r1, 460
    add r1, r1, r6
    lwr r2, r1
    li r1, 461
    add r1, r1, r6
    swr r2, r1
    li r1, 462
    add r1, r1, r6
    lwr r2, r1
    li r1, 463
    add r1, r1, r6
    swr r2, r1
    li r1, 464
    add r1, r1, r6
    lwr r2, r1
    li r1, 465
    add r1, r1, r6
    swr r2, r1
    li r1, 466
    add r1, r1, r6
    lwr r2, r1
    li r1, 467
    add r1, r1, r6
    swr r2, r1
    li r1, 468
    add r1, r1, r6
    lwr r2, r1
    li r1, 469
    add r1, r1, r6
    swr r2, r1
    li r1, 470
    add r1, r1, r6
    lwr r2, r1
    li r1, 471
    add r1, r1, r6
    swr r2, r1
    li r1, 472
    add r1, r1, r6
    lwr r2, r1
    li r1, 473
    add r1, r1, r6
    swr r2, r1
    li r1, 474
    add r1, r1, r6
    lwr r2, r1
    li r1, 475
    add r1, r1, r6
    swr r2, r1
    li r1, 476
    add r1, r1, r6
    lwr r2, r1
    li r1, 477
    add r1, r1, r6
    swr r2, r1
    li r1, 478
    add r1, r1, r6
    lwr r2, r1
    li r1, 479
    add r1, r1, r6
    swr r2, r1
    li r1, 480
    add r1, r1, r6
    lwr r2, r1
    li r1, 1008
    add r1, r1, r6
    swr r2, r1
    li r1, 482
    add r1, r1, r6
    lwr r2, r1
    li r1, 483
    add r1, r1, r6
    swr r2, r1
    li r1, 484
    add r1, r1, r6
    lwr r2, r1
    li r1, 485
    add r1, r1, r6
    swr r2, r1
    li r1, 486
    add r1, r1, r6
    lwr r2, r1
    li r1, 487
    add r1, r1, r6
    swr r2, r1
    li r1, 488
    add r1, r1, r6
    lwr r2, r1
    li r1, 489
    add r1, r1, r6
    swr r2, r1
    li r1, 490
    add r1, r1, r6
    lwr r2, r1
    li r1, 491
    add r1, r1, r6
    swr r2, r1
    li r1, 492
    add r1, r1, r6
    lwr r2, r1
    li r1, 493
    add r1, r1, r6
    swr r2, r1
    li r1, 494
    add r1, r1, r6
    lwr r2, r1
    li r1, 495
    add r1, r1, r6
    swr r2, r1
    li r1, 496
    add r1, r1, r6
    lwr r2, r1
    li r1, 497
    add r1, r1, r6
    swr r2, r1
    li r1, 498
    add r1, r1, r6
    lwr r2, r1
    li r1, 499
    add r1, r1, r6
    swr r2, r1
    li r1, 500
    add r1, r1, r6
    lwr r2, r1
    li r1, 501
    add r1, r1, r6
    swr r2, r1
    li r1, 502
    add r1, r1, r6
    lwr r2, r1
    li r1, 1019
    add r1, r1, r6
    swr r2, r1
    li r1, 503
    add r1, r1, r6
    lwr r2, r1
    li r1, 504
    add r1, r1, r6
    swr r2, r1
    li r1, 505
    add r1, r1, r6
    lwr r2, r1
    li r1, 506
    add r1, r1, r6
    swr r2, r1
    li r1, 507
    add r1, r1, r6
    lwr r2, r1
    li r1, 508
    add r1, r1, r6
    swr r2, r1
    li r1, 509
    add r1, r1, r6
    lwr r2, r1
    li r1, 510
    add r1, r1, r6
    swr r2, r1
    li r1, 511
    add r1, r1, r6
    lwr r2, r1
    lui r1, 8
    add r1, r1, r6
    swr r2, r1
    li r1, 513
    add r1, r1, r6
    lwr r2, r1
    li r1, 514
    add r1, r1, r6
    swr r2, r1
    li r1, 515
    add r1, r1, r6
    lwr r2, r1
    li r1, 516
    add r1, r1, r6
    swr r2, r1
    li r1, 517
    add r1, r1, r6
    lwr r2, r1
    li r1, 518
    add r1, r1, r6
    swr r2, r1
    li r1, 519
    add r1, r1, r6
    lwr r2, r1
    li r1, 520
    add r1, r1, r6
    swr r2, r1
    li r1, 521
    add r1, r1, r6
    lwr r2, r1
    li r1, 522
    add r1, r1, r6
    swr r2, r1
    li r1, 523
    add r1, r1, r6
    lwr r2, r1
    li r1, 524
    add r1, r1, r6
    swr r2, r1
    li r1, 525
    add r1, r1, r6
    lwr r2, r1
    li r1, 526
    add r1, r1, r6
    swr r2, r1
    li r1, 527
    add r1, r1, r6
    lwr r2, r1
    li r1, 528
    add r1, r1, r6
    swr r2, r1
    li r1, 529
    add r1, r1, r6
    lwr r2, r1
    li r1, 530
    add r1, r1, r6
    swr r2, r1
    li r1, 531
    add r1, r1, r6
    lwr r2, r1
    li r1, 532
    add r1, r1, r6
    swr r2, r1
    li r1, 533
    add r1, r1, r6
    lwr r2, r1
    li r1, 534
    add r1, r1, r6
    swr r2, r1
    li r1, 535
    add r1, r1, r6
    lwr r2, r1
    li r1, 536
    add r1, r1, r6
    swr r2, r1
    li r1, 537
    add r1, r1, r6
    lwr r2, r1
    li r1, 538
    add r1, r1, r6
    swr r2, r1
    li r1, 539
    add r1, r1, r6
    lwr r2, r1
    li r1, 540
    add r1, r1, r6
    swr r2, r1
    li r1, 541
    add r1, r1, r6
    lwr r2, r1
    li r1, 542
    add r1, r1, r6
    swr r2, r1
    li r1, 543
    add r1, r1, r6
    lwr r2, r1
    li r1, 544
    add r1, r1, r6
    swr r2, r1
    li r1, 545
    add r1, r1, r6
    lwr r2, r1
    li r1, 546
    add r1, r1, r6
    swr r2, r1
    li r1, 547
    add r1, r1, r6
    lwr r2, r1
    li r1, 548
    add r1, r1, r6
    swr r2, r1
    li r1, 549
    add r1, r1, r6
    lwr r2, r1
    li r1, 550
    add r1, r1, r6
    swr r2, r1
    li r1, 551
    add r1, r1, r6
    lwr r2, r1
    li r1, 552
    add r1, r1, r6
    swr r2, r1
    li r1, 553
    add r1, r1, r6
    lwr r2, r1
    li r1, 554
    add r1, r1, r6
    swr r2, r1
    li r1, 555
    add r1, r1, r6
    lwr r2, r1
    li r1, 556
    add r1, r1, r6
    swr r2, r1
    li r1, 557
    add r1, r1, r6
    lwr r2, r1
    li r1, 558
    add r1, r1, r6
    swr r2, r1
    li r1, 559
    add r1, r1, r6
    lwr r2, r1
    li r1, 560
    add r1, r1, r6
    swr r2, r1
    li r1, 561
    add r1, r1, r6
    lwr r2, r1
    li r1, 562
    add r1, r1, r6
    swr r2, r1
    li r1, 563
    add r1, r1, r6
    lwr r2, r1
    li r1, 564
    add r1, r1, r6
    swr r2, r1
    li r1, 565
    add r1, r1, r6
    lwr r2, r1
    li r1, 566
    add r1, r1, r6
    swr r2, r1
    li r1, 567
    add r1, r1, r6
    lwr r2, r1
    li r1, 568
    add r1, r1, r6
    swr r2, r1
    li r1, 569
    add r1, r1, r6
    lwr r2, r1
    li r1, 570
    add r1, r1, r6
    swr r2, r1
    li r1, 571
    add r1, r1, r6
    lwr r2, r1
    li r1, 572
    add r1, r1, r6
    swr r2, r1
    li r1, 573
    add r1, r1, r6
    lwr r2, r1
    li r1, 574
    add r1, r1, r6
    swr r2, r1
    li r1, 575
    add r1, r1, r6
    lwr r2, r1
    lui r1, 9
    add r1, r1, r6
    swr r2, r1
    li r1, 577
    add r1, r1, r6
    lwr r2, r1
    li r1, 578
    add r1, r1, r6
    swr r2, r1
    li r1, 579
    add r1, r1, r6
    lwr r2, r1
    li r1, 580
    add r1, r1, r6
    swr r2, r1
    li r1, 581
    add r1, r1, r6
    lwr r2, r1
    li r1, 582
    add r1, r1, r6
    swr r2, r1
    li r1, 583
    add r1, r1, r6
    lwr r2, r1
    li r1, 584
    add r1, r1, r6
    swr r2, r1
    li r1, 585
    add r1, r1, r6
    lwr r2, r1
    li r1, 586
    add r1, r1, r6
    swr r2, r1
    li r1, 587
    add r1, r1, r6
    lwr r2, r1
    li r1, 588
    add r1, r1, r6
    swr r2, r1
    li r1, 589
    add r1, r1, r6
    lwr r2, r1
    li r1, 590
    add r1, r1, r6
    swr r2, r1
    li r1, 591
    add r1, r1, r6
    lwr r2, r1
    li r1, 592
    add r1, r1, r6
    swr r2, r1
    li r1, 593
    add r1, r1, r6
    lwr r2, r1
    li r1, 594
    add r1, r1, r6
    swr r2, r1
    li r1, 595
    add r1, r1, r6
    lwr r2, r1
    li r1, 596
    add r1, r1, r6
    swr r2, r1
    li r1, 597
    add r1, r1, r6
    lwr r2, r1
    li r1, 598
    add r1, r1, r6
    swr r2, r1
    li r1, 599
    add r1, r1, r6
    lwr r2, r1
    li r1, 600
    add r1, r1, r6
    swr r2, r1
    li r1, 601
    add r1, r1, r6
    lwr r2, r1
    li r1, 602
    add r1, r1, r6
    swr r2, r1
    li r1, 603
    add r1, r1, r6
    lwr r2, r1
    li r1, 604
    add r1, r1, r6
    swr r2, r1
    li r1, 605
    add r1, r1, r6
    lwr r2, r1
    li r1, 606
    add r1, r1, r6
    swr r2, r1
    li r1, 607
    add r1, r1, r6
    lwr r2, r1
    li r1, 608
    add r1, r1, r6
    swr r2, r1
    li r1, 609
    add r1, r1, r6
    lwr r2, r1
    li r1, 610
    add r1, r1, r6
    swr r2, r1
    li r1, 611
    add r1, r1, r6
    lwr r2, r1
    li r1, 612
    add r1, r1, r6
    swr r2, r1
    li r1, 613
    add r1, r1, r6
    lwr r2, r1
    li r1, 614
    add r1, r1, r6
    swr r2, r1
    li r1, 615
    add r1, r1, r6
    lwr r2, r1
    li r1, 616
    add r1, r1, r6
    swr r2, r1
    li r1, 617
    add r1, r1, r6
    lwr r2, r1
    li r1, 618
    add r1, r1, r6
    swr r2, r1
    li r1, 619
    add r1, r1, r6
    lwr r2, r1
    li r1, 620
    add r1, r1, r6
    swr r2, r1
    li r1, 621
    add r1, r1, r6
    lwr r2, r1
    li r1, 622
    add r1, r1, r6
    swr r2, r1
    li r1, 623
    add r1, r1, r6
    lwr r2, r1
    li r1, 624
    add r1, r1, r6
    swr r2, r1
    li r1, 625
    add r1, r1, r6
    lwr r2, r1
    li r1, 626
    add r1, r1, r6
    swr r2, r1
    li r1, 627
    add r1, r1, r6
    lwr r2, r1
    li r1, 628
    add r1, r1, r6
    swr r2, r1
    li r1, 629
    add r1, r1, r6
    lwr r2, r1
    li r1, 630
    add r1, r1, r6
    swr r2, r1
    li r1, 631
    add r1, r1, r6
    lwr r2, r1
    li r1, 632
    add r1, r1, r6
    swr r2, r1
    li r1, 633
    add r1, r1, r6
    lwr r2, r1
    li r1, 634
    add r1, r1, r6
    swr r2, r1
    li r1, 635
    add r1, r1, r6
    lwr r2, r1
    li r1, 636
    add r1, r1, r6
    swr r2, r1
    li r1, 637
    add r1, r1, r6
    lwr r2, r1
    li r1, 638
    add r1, r1, r6
    swr r2, r1
    li r1, 639
    add r1, r1, r6
    lwr r2, r1
    lui r1, 10
    add r1, r1, r6
    swr r2, r1
    li r1, 641
    add r1, r1, r6
    lwr r2, r1
    li r1, 642
    add r1, r1, r6
    swr r2, r1
    li r1, 643
    add r1, r1, r6
    lwr r2, r1
    li r1, 644
    add r1, r1, r6
    swr r2, r1
    li r1, 645
    add r1, r1, r6
    lwr r2, r1
    li r1, 646
    add r1, r1, r6
    swr r2, r1
    li r1, 647
    add r1, r1, r6
    lwr r2, r1
    li r1, 648
    add r1, r1, r6
    swr r2, r1
    li r1, 649
    add r1, r1, r6
    lwr r2, r1
    li r1, 650
    add r1, r1, r6
    swr r2, r1
    li r1, 651
    add r1, r1, r6
    lwr r2, r1
    li r1, 652
    add r1, r1, r6
    swr r2, r1
    li r1, 653
    add r1, r1, r6
    lwr r2, r1
    li r1, 654
    add r1, r1, r6
    swr r2, r1
    li r1, 655
    add r1, r1, r6
    lwr r2, r1
    li r1, 656
    add r1, r1, r6
    swr r2, r1
    li r1, 657
    add r1, r1, r6
    lwr r2, r1
    li r1, 658
    add r1, r1, r6
    swr r2, r1
    li r1, 659
    add r1, r1, r6
    lwr r2, r1
    li r1, 660
    add r1, r1, r6
    swr r2, r1
    li r1, 661
    add r1, r1, r6
    lwr r2, r1
    li r1, 662
    add r1, r1, r6
    swr r2, r1
    li r1, 663
    add r1, r1, r6
    lwr r2, r1
    li r1, 664
    add r1, r1, r6
    swr r2, r1
    li r1, 665
    add r1, r1, r6
    lwr r2, r1
    li r1, 666
    add r1, r1, r6
    swr r2, r1
    li r1, 667
    add r1, r1, r6
    lwr r2, r1
    li r1, 668
    add r1, r1, r6
    swr r2, r1
    li r1, 669
    add r1, r1, r6
    lwr r2, r1
    li r1, 670
    add r1, r1, r6
    swr r2, r1
    li r1, 671
    add r1, r1, r6
    lwr r2, r1
    li r1, 672
    add r1, r1, r6
    swr r2, r1
    li r1, 673
    add r1, r1, r6
    lwr r2, r1
    li r1, 674
    add r1, r1, r6
    swr r2, r1
    li r1, 675
    add r1, r1, r6
    lwr r2, r1
    li r1, 676
    add r1, r1, r6
    swr r2, r1
    li r1, 677
    add r1, r1, r6
    lwr r2, r1
    li r1, 678
    add r1, r1, r6
    swr r2, r1
    li r1, 679
    add r1, r1, r6
    lwr r2, r1
    li r1, 680
    add r1, r1, r6
    swr r2, r1
    li r1, 681
    add r1, r1, r6
    lwr r2, r1
    li r1, 682
    add r1, r1, r6
    swr r2, r1
    li r1, 683
    add r1, r1, r6
    lwr r2, r1
    li r1, 684
    add r1, r1, r6
    swr r2, r1
    li r1, 685
    add r1, r1, r6
    lwr r2, r1
    li r1, 686
    add r1, r1, r6
    swr r2, r1
    li r1, 687
    add r1, r1, r6
    lwr r2, r1
    li r1, 688
    add r1, r1, r6
    swr r2, r1
    li r1, 689
    add r1, r1, r6
    lwr r2, r1
    li r1, 690
    add r1, r1, r6
    swr r2, r1
    li r1, 691
    add r1, r1, r6
    lwr r2, r1
    li r1, 692
    add r1, r1, r6
    swr r2, r1
    li r1, 693
    add r1, r1, r6
    lwr r2, r1
    li r1, 1112
    add r1, r1, r6
    swr r2, r1
    li r1, 695
    add r1, r1, r6
    lwr r2, r1
    li r1, 696
    add r1, r1, r6
    swr r2, r1
    li r1, 697
    add r1, r1, r6
    lwr r2, r1
    li r1, 698
    add r1, r1, r6
    swr r2, r1
    li r1, 699
    add r1, r1, r6
    lwr r2, r1
    li r1, 700
    add r1, r1, r6
    swr r2, r1
    li r1, 701
    add r1, r1, r6
    lwr r2, r1
    li r1, 702
    add r1, r1, r6
    swr r2, r1
    li r1, 703
    add r1, r1, r6
    lwr r2, r1
    lui r1, 11
    add r1, r1, r6
    swr r2, r1
    li r1, 705
    add r1, r1, r6
    lwr r2, r1
    li r1, 706
    add r1, r1, r6
    swr r2, r1
    li r1, 707
    add r1, r1, r6
    lwr r2, r1
    li r1, 708
    add r1, r1, r6
    swr r2, r1
    li r1, 709
    add r1, r1, r6
    lwr r2, r1
    li r1, 710
    add r1, r1, r6
    swr r2, r1
    li r1, 711
    add r1, r1, r6
    lwr r2, r1
    li r1, 712
    add r1, r1, r6
    swr r2, r1
    li r1, 713
    add r1, r1, r6
    lwr r2, r1
    li r1, 714
    add r1, r1, r6
    swr r2, r1
    li r1, 715
    add r1, r1, r6
    lwr r2, r1
    li r1, 1123
    add r1, r1, r6
    swr r2, r1
    li r1, 717
    add r1, r1, r6
    lwr r2, r1
    li r1, 1124
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_3
_B_main_124:
    li r1, 79
    add r1, r1, r6
    lwr r2, r1
    li r1, 70
    add r1, r1, r6
    swr r2, r1
    li r1, 78
    add r1, r1, r6
    lwr r2, r1
    li r1, 939
    add r1, r1, r6
    swr r2, r1
    li r1, 77
    add r1, r1, r6
    lwr r2, r1
    li r1, 951
    add r1, r1, r6
    swr r2, r1
    li r1, 963
    add r1, r1, r6
    lwr r2, r1
    li r1, 1125
    add r1, r1, r6
    swr r2, r1
    li r1, 975
    add r1, r1, r6
    lwr r2, r1
    li r1, 1126
    add r1, r1, r6
    swr r2, r1
    li r1, 71
    add r1, r1, r6
    lwr r2, r1
    li r1, 1127
    add r1, r1, r6
    swr r2, r1
    li r1, 69
    add r1, r1, r6
    lwr r2, r1
    li r1, 1128
    add r1, r1, r6
    swr r2, r1
    li r1, 76
    add r1, r1, r6
    lwr r2, r1
    li r1, 1129
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_5
_B_main_125:
    li r1, 67
    add r1, r1, r6
    lwr r2, r1
    li r1, 70
    add r1, r1, r6
    swr r2, r1
    li r1, 938
    add r1, r1, r6
    lwr r2, r1
    li r1, 939
    add r1, r1, r6
    swr r2, r1
    li r1, 950
    add r1, r1, r6
    lwr r2, r1
    li r1, 951
    add r1, r1, r6
    swr r2, r1
    li r1, 962
    add r1, r1, r6
    lwr r2, r1
    li r1, 1125
    add r1, r1, r6
    swr r2, r1
    li r1, 974
    add r1, r1, r6
    lwr r2, r1
    li r1, 1126
    add r1, r1, r6
    swr r2, r1
    li r1, 986
    add r1, r1, r6
    lwr r2, r1
    li r1, 1127
    add r1, r1, r6
    swr r2, r1
    li r1, 997
    add r1, r1, r6
    lwr r2, r1
    li r1, 1128
    add r1, r1, r6
    swr r2, r1
    li r1, 1008
    add r1, r1, r6
    lwr r2, r1
    li r1, 1129
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_5
_B_main_126:
    li r1, 73
    add r1, r1, r6
    lwr r2, r1
    li r1, 1130
    add r1, r1, r6
    swr r2, r1
    li r1, 72
    add r1, r1, r6
    lwr r2, r1
    li r1, 1131
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_9
_B_main_127:
    li r1, 1125
    add r1, r1, r6
    lwr r2, r1
    li r1, 1130
    add r1, r1, r6
    swr r2, r1
    li r1, 1126
    add r1, r1, r6
    lwr r2, r1
    li r1, 1131
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_9
_B_main_128:
    li r1, 1130
    add r1, r1, r6
    lwr r2, r1
    li r1, 963
    add r1, r1, r6
    swr r2, r1
    li r1, 1131
    add r1, r1, r6
    lwr r2, r1
    li r1, 975
    add r1, r1, r6
    swr r2, r1
    li r1, 75
    add r1, r1, r6
    lwr r2, r1
    li r1, 76
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_10
_B_main_129:
    li r1, 73
    add r1, r1, r6
    lwr r2, r1
    li r1, 963
    add r1, r1, r6
    swr r2, r1
    li r1, 72
    add r1, r1, r6
    lwr r2, r1
    li r1, 975
    add r1, r1, r6
    swr r2, r1
    li r1, 74
    add r1, r1, r6
    lwr r2, r1
    li r1, 76
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_10
_B_main_130:
    li r1, 88
    add r1, r1, r6
    lwr r2, r1
    li r1, 1132
    add r1, r1, r6
    swr r2, r1
    li r1, 87
    add r1, r1, r6
    lwr r2, r1
    li r1, 1133
    add r1, r1, r6
    swr r2, r1
    li r1, 86
    add r1, r1, r6
    lwr r2, r1
    li r1, 1134
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_21
_B_main_131:
    li r1, 501
    add r1, r1, r6
    lwr r2, r1
    li r1, 1132
    add r1, r1, r6
    swr r2, r1
    li r1, 518
    add r1, r1, r6
    lwr r2, r1
    li r1, 1133
    add r1, r1, r6
    swr r2, r1
    li r1, 540
    add r1, r1, r6
    lwr r2, r1
    li r1, 1134
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_21
_B_main_132:
    li r1, 1132
    add r1, r1, r6
    lwr r2, r1
    li r1, 1135
    add r1, r1, r6
    swr r2, r1
    li r1, 1133
    add r1, r1, r6
    lwr r2, r1
    li r1, 1136
    add r1, r1, r6
    swr r2, r1
    li r1, 1134
    add r1, r1, r6
    lwr r2, r1
    li r1, 1137
    add r1, r1, r6
    swr r2, r1
    li r1, 90
    add r1, r1, r6
    lwr r2, r1
    li r1, 91
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_22
_B_main_133:
    li r1, 88
    add r1, r1, r6
    lwr r2, r1
    li r1, 1135
    add r1, r1, r6
    swr r2, r1
    li r1, 87
    add r1, r1, r6
    lwr r2, r1
    li r1, 1136
    add r1, r1, r6
    swr r2, r1
    li r1, 86
    add r1, r1, r6
    lwr r2, r1
    li r1, 1137
    add r1, r1, r6
    swr r2, r1
    li r1, 89
    add r1, r1, r6
    lwr r2, r1
    li r1, 91
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_22
_B_main_134:
    li r1, 1135
    add r1, r1, r6
    lwr r2, r1
    li r1, 1138
    add r1, r1, r6
    swr r2, r1
    li r1, 1136
    add r1, r1, r6
    lwr r2, r1
    li r1, 1139
    add r1, r1, r6
    swr r2, r1
    li r1, 1137
    add r1, r1, r6
    lwr r2, r1
    li r1, 1140
    add r1, r1, r6
    swr r2, r1
    li r1, 85
    add r1, r1, r6
    lwr r2, r1
    li r1, 1141
    add r1, r1, r6
    swr r2, r1
    li r1, 84
    add r1, r1, r6
    lwr r2, r1
    li r1, 1142
    add r1, r1, r6
    swr r2, r1
    li r1, 91
    add r1, r1, r6
    lwr r2, r1
    li r1, 1143
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_25
_B_main_135:
    li r1, 501
    add r1, r1, r6
    lwr r2, r1
    li r1, 1138
    add r1, r1, r6
    swr r2, r1
    li r1, 518
    add r1, r1, r6
    lwr r2, r1
    li r1, 1139
    add r1, r1, r6
    swr r2, r1
    li r1, 540
    add r1, r1, r6
    lwr r2, r1
    li r1, 1140
    add r1, r1, r6
    swr r2, r1
    li r1, 562
    add r1, r1, r6
    lwr r2, r1
    li r1, 1141
    add r1, r1, r6
    swr r2, r1
    li r1, 584
    add r1, r1, r6
    lwr r2, r1
    li r1, 1142
    add r1, r1, r6
    swr r2, r1
    li r1, 606
    add r1, r1, r6
    lwr r2, r1
    li r1, 1143
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_25
_B_main_136:
    li r1, 1138
    add r1, r1, r6
    lwr r2, r1
    li r1, 1018
    add r1, r1, r6
    swr r2, r1
    li r1, 1139
    add r1, r1, r6
    lwr r2, r1
    li r1, 1027
    add r1, r1, r6
    swr r2, r1
    li r1, 1140
    add r1, r1, r6
    lwr r2, r1
    li r1, 1038
    add r1, r1, r6
    swr r2, r1
    li r1, 1141
    add r1, r1, r6
    lwr r2, r1
    li r1, 1049
    add r1, r1, r6
    swr r2, r1
    li r1, 1142
    add r1, r1, r6
    lwr r2, r1
    li r1, 1060
    add r1, r1, r6
    swr r2, r1
    li r1, 1143
    add r1, r1, r6
    lwr r2, r1
    li r1, 1071
    add r1, r1, r6
    swr r2, r1
    li r1, 93
    add r1, r1, r6
    lwr r2, r1
    li r1, 94
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_26
_B_main_137:
    li r1, 1135
    add r1, r1, r6
    lwr r2, r1
    li r1, 1018
    add r1, r1, r6
    swr r2, r1
    li r1, 1136
    add r1, r1, r6
    lwr r2, r1
    li r1, 1027
    add r1, r1, r6
    swr r2, r1
    li r1, 1137
    add r1, r1, r6
    lwr r2, r1
    li r1, 1038
    add r1, r1, r6
    swr r2, r1
    li r1, 85
    add r1, r1, r6
    lwr r2, r1
    li r1, 1049
    add r1, r1, r6
    swr r2, r1
    li r1, 84
    add r1, r1, r6
    lwr r2, r1
    li r1, 1060
    add r1, r1, r6
    swr r2, r1
    li r1, 91
    add r1, r1, r6
    lwr r2, r1
    li r1, 1071
    add r1, r1, r6
    swr r2, r1
    li r1, 92
    add r1, r1, r6
    lwr r2, r1
    li r1, 94
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_26
_B_main_138:
    li r1, 101
    add r1, r1, r6
    lwr r2, r1
    li r1, 1144
    add r1, r1, r6
    swr r2, r1
    li r1, 98
    add r1, r1, r6
    lwr r2, r1
    li r1, 115
    add r1, r1, r6
    swr r2, r1
    li r1, 100
    add r1, r1, r6
    lwr r2, r1
    li r1, 1145
    add r1, r1, r6
    swr r2, r1
    li r1, 99
    add r1, r1, r6
    lwr r2, r1
    li r1, 1146
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_29
_B_main_139:
    li r1, 70
    add r1, r1, r6
    lwr r2, r1
    li r1, 1144
    add r1, r1, r6
    swr r2, r1
    li r1, 95
    add r1, r1, r6
    lwr r2, r1
    li r1, 115
    add r1, r1, r6
    swr r2, r1
    li r1, 493
    add r1, r1, r6
    lwr r2, r1
    li r1, 1145
    add r1, r1, r6
    swr r2, r1
    li r1, 495
    add r1, r1, r6
    lwr r2, r1
    li r1, 1146
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_29
_B_main_140:
    li r1, 111
    add r1, r1, r6
    lwr r2, r1
    li r1, 107
    add r1, r1, r6
    swr r2, r1
    li r1, 114
    add r1, r1, r6
    lwr r2, r1
    li r1, 104
    add r1, r1, r6
    swr r2, r1
    li r1, 113
    add r1, r1, r6
    lwr r2, r1
    li r1, 1147
    add r1, r1, r6
    swr r2, r1
    li r1, 112
    add r1, r1, r6
    lwr r2, r1
    li r1, 1148
    add r1, r1, r6
    swr r2, r1
    li r1, 110
    add r1, r1, r6
    lwr r2, r1
    li r1, 1149
    add r1, r1, r6
    swr r2, r1
    li r1, 109
    add r1, r1, r6
    lwr r2, r1
    li r1, 1150
    add r1, r1, r6
    swr r2, r1
    li r1, 108
    add r1, r1, r6
    lwr r2, r1
    li r1, 1151
    add r1, r1, r6
    swr r2, r1
    li r1, 106
    add r1, r1, r6
    lwr r2, r1
    lui r1, 18
    add r1, r1, r6
    swr r2, r1
    li r1, 105
    add r1, r1, r6
    lwr r2, r1
    li r1, 1153
    add r1, r1, r6
    swr r2, r1
    li r1, 103
    add r1, r1, r6
    lwr r2, r1
    li r1, 1154
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_30
_B_main_141:
    li r1, 102
    add r1, r1, r6
    lwr r2, r1
    li r1, 107
    add r1, r1, r6
    swr r2, r1
    li r1, 1144
    add r1, r1, r6
    lwr r2, r1
    li r1, 104
    add r1, r1, r6
    swr r2, r1
    li r1, 475
    add r1, r1, r6
    lwr r2, r1
    li r1, 1147
    add r1, r1, r6
    swr r2, r1
    li r1, 477
    add r1, r1, r6
    lwr r2, r1
    li r1, 1148
    add r1, r1, r6
    swr r2, r1
    li r1, 479
    add r1, r1, r6
    lwr r2, r1
    li r1, 1149
    add r1, r1, r6
    swr r2, r1
    li r1, 483
    add r1, r1, r6
    lwr r2, r1
    li r1, 1150
    add r1, r1, r6
    swr r2, r1
    li r1, 485
    add r1, r1, r6
    lwr r2, r1
    li r1, 1151
    add r1, r1, r6
    swr r2, r1
    li r1, 487
    add r1, r1, r6
    lwr r2, r1
    lui r1, 18
    add r1, r1, r6
    swr r2, r1
    li r1, 489
    add r1, r1, r6
    lwr r2, r1
    li r1, 1153
    add r1, r1, r6
    swr r2, r1
    li r1, 491
    add r1, r1, r6
    lwr r2, r1
    li r1, 1154
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_30
_B_main_142:
    li r1, 117
    add r1, r1, r6
    lwr r2, r1
    li r1, 123
    add r1, r1, r6
    swr r2, r1
    li r1, 116
    add r1, r1, r6
    lwr r2, r1
    li r1, 1155
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_35
_B_main_143:
    li r1, 107
    add r1, r1, r6
    lwr r2, r1
    li r1, 123
    add r1, r1, r6
    swr r2, r1
    li r1, 473
    add r1, r1, r6
    lwr r2, r1
    li r1, 1155
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_35
_B_main_144:
    li r1, 126
    add r1, r1, r6
    lwr r2, r1
    li r1, 1156
    add r1, r1, r6
    swr r2, r1
    li r1, 125
    add r1, r1, r6
    lwr r2, r1
    li r1, 1157
    add r1, r1, r6
    swr r2, r1
    li r1, 124
    add r1, r1, r6
    lwr r2, r1
    li r1, 1158
    add r1, r1, r6
    swr r2, r1
    li r1, 122
    add r1, r1, r6
    lwr r2, r1
    li r1, 1159
    add r1, r1, r6
    swr r2, r1
    li r1, 121
    add r1, r1, r6
    lwr r2, r1
    li r1, 1160
    add r1, r1, r6
    swr r2, r1
    li r1, 467
    add r1, r1, r6
    lwr r2, r1
    li r1, 1161
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_39
_B_main_145:
    li r1, 455
    add r1, r1, r6
    lwr r2, r1
    li r1, 1156
    add r1, r1, r6
    swr r2, r1
    li r1, 457
    add r1, r1, r6
    lwr r2, r1
    li r1, 1157
    add r1, r1, r6
    swr r2, r1
    li r1, 461
    add r1, r1, r6
    lwr r2, r1
    li r1, 1158
    add r1, r1, r6
    swr r2, r1
    li r1, 463
    add r1, r1, r6
    lwr r2, r1
    li r1, 1159
    add r1, r1, r6
    swr r2, r1
    li r1, 465
    add r1, r1, r6
    lwr r2, r1
    li r1, 1160
    add r1, r1, r6
    swr r2, r1
    li r1, 120
    add r1, r1, r6
    lwr r2, r1
    li r1, 1161
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_39
_B_main_146:
    li r1, 145
    add r1, r1, r6
    lwr r2, r1
    li r1, 1162
    add r1, r1, r6
    swr r2, r1
    li r1, 136
    add r1, r1, r6
    lwr r2, r1
    li r1, 1163
    add r1, r1, r6
    swr r2, r1
    li r1, 141
    add r1, r1, r6
    lwr r2, r1
    li r1, 1164
    add r1, r1, r6
    swr r2, r1
    li r1, 150
    add r1, r1, r6
    lwr r2, r1
    li r1, 1165
    add r1, r1, r6
    swr r2, r1
    li r1, 149
    add r1, r1, r6
    lwr r2, r1
    li r1, 1166
    add r1, r1, r6
    swr r2, r1
    li r1, 148
    add r1, r1, r6
    lwr r2, r1
    li r1, 1167
    add r1, r1, r6
    swr r2, r1
    li r1, 147
    add r1, r1, r6
    lwr r2, r1
    li r1, 1168
    add r1, r1, r6
    swr r2, r1
    li r1, 146
    add r1, r1, r6
    lwr r2, r1
    li r1, 1169
    add r1, r1, r6
    swr r2, r1
    li r1, 144
    add r1, r1, r6
    lwr r2, r1
    li r1, 1170
    add r1, r1, r6
    swr r2, r1
    li r1, 143
    add r1, r1, r6
    lwr r2, r1
    li r1, 1171
    add r1, r1, r6
    swr r2, r1
    li r1, 142
    add r1, r1, r6
    lwr r2, r1
    li r1, 1172
    add r1, r1, r6
    swr r2, r1
    li r1, 140
    add r1, r1, r6
    lwr r2, r1
    li r1, 1173
    add r1, r1, r6
    swr r2, r1
    li r1, 139
    add r1, r1, r6
    lwr r2, r1
    li r1, 1174
    add r1, r1, r6
    swr r2, r1
    li r1, 138
    add r1, r1, r6
    lwr r2, r1
    li r1, 1175
    add r1, r1, r6
    swr r2, r1
    li r1, 137
    add r1, r1, r6
    lwr r2, r1
    li r1, 1176
    add r1, r1, r6
    swr r2, r1
    li r1, 135
    add r1, r1, r6
    lwr r2, r1
    li r1, 1177
    add r1, r1, r6
    swr r2, r1
    li r1, 134
    add r1, r1, r6
    lwr r2, r1
    li r1, 1178
    add r1, r1, r6
    swr r2, r1
    li r1, 133
    add r1, r1, r6
    lwr r2, r1
    li r1, 1179
    add r1, r1, r6
    swr r2, r1
    li r1, 132
    add r1, r1, r6
    lwr r2, r1
    li r1, 1180
    add r1, r1, r6
    swr r2, r1
    li r1, 445
    add r1, r1, r6
    lwr r2, r1
    li r1, 1181
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_46
_B_main_147:
    li r1, 319
    add r1, r1, r6
    lwr r2, r1
    li r1, 1162
    add r1, r1, r6
    swr r2, r1
    li r1, 325
    add r1, r1, r6
    lwr r2, r1
    li r1, 1163
    add r1, r1, r6
    swr r2, r1
    li r1, 327
    add r1, r1, r6
    lwr r2, r1
    li r1, 1164
    add r1, r1, r6
    swr r2, r1
    li r1, 409
    add r1, r1, r6
    lwr r2, r1
    li r1, 1165
    add r1, r1, r6
    swr r2, r1
    li r1, 411
    add r1, r1, r6
    lwr r2, r1
    li r1, 1166
    add r1, r1, r6
    swr r2, r1
    li r1, 413
    add r1, r1, r6
    lwr r2, r1
    li r1, 1167
    add r1, r1, r6
    swr r2, r1
    li r1, 417
    add r1, r1, r6
    lwr r2, r1
    li r1, 1168
    add r1, r1, r6
    swr r2, r1
    li r1, 419
    add r1, r1, r6
    lwr r2, r1
    li r1, 1169
    add r1, r1, r6
    swr r2, r1
    li r1, 421
    add r1, r1, r6
    lwr r2, r1
    li r1, 1170
    add r1, r1, r6
    swr r2, r1
    li r1, 423
    add r1, r1, r6
    lwr r2, r1
    li r1, 1171
    add r1, r1, r6
    swr r2, r1
    li r1, 425
    add r1, r1, r6
    lwr r2, r1
    li r1, 1172
    add r1, r1, r6
    swr r2, r1
    li r1, 427
    add r1, r1, r6
    lwr r2, r1
    li r1, 1173
    add r1, r1, r6
    swr r2, r1
    li r1, 429
    add r1, r1, r6
    lwr r2, r1
    li r1, 1174
    add r1, r1, r6
    swr r2, r1
    li r1, 431
    add r1, r1, r6
    lwr r2, r1
    li r1, 1175
    add r1, r1, r6
    swr r2, r1
    li r1, 433
    add r1, r1, r6
    lwr r2, r1
    li r1, 1176
    add r1, r1, r6
    swr r2, r1
    li r1, 435
    add r1, r1, r6
    lwr r2, r1
    li r1, 1177
    add r1, r1, r6
    swr r2, r1
    li r1, 439
    add r1, r1, r6
    lwr r2, r1
    li r1, 1178
    add r1, r1, r6
    swr r2, r1
    li r1, 441
    add r1, r1, r6
    lwr r2, r1
    li r1, 1179
    add r1, r1, r6
    swr r2, r1
    li r1, 443
    add r1, r1, r6
    lwr r2, r1
    li r1, 1180
    add r1, r1, r6
    swr r2, r1
    li r1, 131
    add r1, r1, r6
    lwr r2, r1
    li r1, 1181
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_46
_B_main_148:
    li r1, 172
    add r1, r1, r6
    lwr r2, r1
    li r1, 1182
    add r1, r1, r6
    swr r2, r1
    li r1, 163
    add r1, r1, r6
    lwr r2, r1
    li r1, 1183
    add r1, r1, r6
    swr r2, r1
    li r1, 168
    add r1, r1, r6
    lwr r2, r1
    li r1, 1184
    add r1, r1, r6
    swr r2, r1
    li r1, 177
    add r1, r1, r6
    lwr r2, r1
    li r1, 1185
    add r1, r1, r6
    swr r2, r1
    li r1, 176
    add r1, r1, r6
    lwr r2, r1
    li r1, 1186
    add r1, r1, r6
    swr r2, r1
    li r1, 175
    add r1, r1, r6
    lwr r2, r1
    li r1, 1187
    add r1, r1, r6
    swr r2, r1
    li r1, 174
    add r1, r1, r6
    lwr r2, r1
    li r1, 1188
    add r1, r1, r6
    swr r2, r1
    li r1, 173
    add r1, r1, r6
    lwr r2, r1
    li r1, 1189
    add r1, r1, r6
    swr r2, r1
    li r1, 171
    add r1, r1, r6
    lwr r2, r1
    li r1, 1190
    add r1, r1, r6
    swr r2, r1
    li r1, 170
    add r1, r1, r6
    lwr r2, r1
    li r1, 1191
    add r1, r1, r6
    swr r2, r1
    li r1, 169
    add r1, r1, r6
    lwr r2, r1
    li r1, 1192
    add r1, r1, r6
    swr r2, r1
    li r1, 167
    add r1, r1, r6
    lwr r2, r1
    li r1, 1193
    add r1, r1, r6
    swr r2, r1
    li r1, 166
    add r1, r1, r6
    lwr r2, r1
    li r1, 1194
    add r1, r1, r6
    swr r2, r1
    li r1, 165
    add r1, r1, r6
    lwr r2, r1
    li r1, 1195
    add r1, r1, r6
    swr r2, r1
    li r1, 164
    add r1, r1, r6
    lwr r2, r1
    li r1, 1196
    add r1, r1, r6
    swr r2, r1
    li r1, 162
    add r1, r1, r6
    lwr r2, r1
    li r1, 1197
    add r1, r1, r6
    swr r2, r1
    li r1, 161
    add r1, r1, r6
    lwr r2, r1
    li r1, 1198
    add r1, r1, r6
    swr r2, r1
    li r1, 160
    add r1, r1, r6
    lwr r2, r1
    li r1, 1199
    add r1, r1, r6
    swr r2, r1
    li r1, 159
    add r1, r1, r6
    lwr r2, r1
    li r1, 1200
    add r1, r1, r6
    swr r2, r1
    li r1, 395
    add r1, r1, r6
    lwr r2, r1
    li r1, 1201
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_53
_B_main_149:
    li r1, 319
    add r1, r1, r6
    lwr r2, r1
    li r1, 1182
    add r1, r1, r6
    swr r2, r1
    li r1, 325
    add r1, r1, r6
    lwr r2, r1
    li r1, 1183
    add r1, r1, r6
    swr r2, r1
    li r1, 327
    add r1, r1, r6
    lwr r2, r1
    li r1, 1184
    add r1, r1, r6
    swr r2, r1
    li r1, 359
    add r1, r1, r6
    lwr r2, r1
    li r1, 1185
    add r1, r1, r6
    swr r2, r1
    li r1, 361
    add r1, r1, r6
    lwr r2, r1
    li r1, 1186
    add r1, r1, r6
    swr r2, r1
    li r1, 363
    add r1, r1, r6
    lwr r2, r1
    li r1, 1187
    add r1, r1, r6
    swr r2, r1
    li r1, 365
    add r1, r1, r6
    lwr r2, r1
    li r1, 1188
    add r1, r1, r6
    swr r2, r1
    li r1, 367
    add r1, r1, r6
    lwr r2, r1
    li r1, 1189
    add r1, r1, r6
    swr r2, r1
    li r1, 369
    add r1, r1, r6
    lwr r2, r1
    li r1, 1190
    add r1, r1, r6
    swr r2, r1
    li r1, 373
    add r1, r1, r6
    lwr r2, r1
    li r1, 1191
    add r1, r1, r6
    swr r2, r1
    li r1, 375
    add r1, r1, r6
    lwr r2, r1
    li r1, 1192
    add r1, r1, r6
    swr r2, r1
    li r1, 377
    add r1, r1, r6
    lwr r2, r1
    li r1, 1193
    add r1, r1, r6
    swr r2, r1
    li r1, 379
    add r1, r1, r6
    lwr r2, r1
    li r1, 1194
    add r1, r1, r6
    swr r2, r1
    li r1, 381
    add r1, r1, r6
    lwr r2, r1
    li r1, 1195
    add r1, r1, r6
    swr r2, r1
    li r1, 383
    add r1, r1, r6
    lwr r2, r1
    li r1, 1196
    add r1, r1, r6
    swr r2, r1
    li r1, 385
    add r1, r1, r6
    lwr r2, r1
    li r1, 1197
    add r1, r1, r6
    swr r2, r1
    li r1, 387
    add r1, r1, r6
    lwr r2, r1
    li r1, 1198
    add r1, r1, r6
    swr r2, r1
    li r1, 389
    add r1, r1, r6
    lwr r2, r1
    li r1, 1199
    add r1, r1, r6
    swr r2, r1
    li r1, 391
    add r1, r1, r6
    lwr r2, r1
    li r1, 1200
    add r1, r1, r6
    swr r2, r1
    li r1, 158
    add r1, r1, r6
    lwr r2, r1
    li r1, 1201
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_53
_B_main_150:
    li r1, 199
    add r1, r1, r6
    lwr r2, r1
    li r1, 1202
    add r1, r1, r6
    swr r2, r1
    li r1, 190
    add r1, r1, r6
    lwr r2, r1
    li r1, 1203
    add r1, r1, r6
    swr r2, r1
    li r1, 195
    add r1, r1, r6
    lwr r2, r1
    li r1, 1204
    add r1, r1, r6
    swr r2, r1
    li r1, 193
    add r1, r1, r6
    lwr r2, r1
    li r1, 1205
    add r1, r1, r6
    swr r2, r1
    lui r1, 3
    add r1, r1, r6
    lwr r2, r1
    li r1, 1206
    add r1, r1, r6
    swr r2, r1
    li r1, 191
    add r1, r1, r6
    lwr r2, r1
    li r1, 1207
    add r1, r1, r6
    swr r2, r1
    li r1, 189
    add r1, r1, r6
    lwr r2, r1
    li r1, 1208
    add r1, r1, r6
    swr r2, r1
    li r1, 188
    add r1, r1, r6
    lwr r2, r1
    li r1, 1209
    add r1, r1, r6
    swr r2, r1
    li r1, 187
    add r1, r1, r6
    lwr r2, r1
    li r1, 1210
    add r1, r1, r6
    swr r2, r1
    li r1, 186
    add r1, r1, r6
    lwr r2, r1
    li r1, 1211
    add r1, r1, r6
    swr r2, r1
    li r1, 343
    add r1, r1, r6
    lwr r2, r1
    li r1, 1212
    add r1, r1, r6
    swr r2, r1
    li r1, 204
    add r1, r1, r6
    lwr r2, r1
    li r1, 1213
    add r1, r1, r6
    swr r2, r1
    li r1, 203
    add r1, r1, r6
    lwr r2, r1
    li r1, 1214
    add r1, r1, r6
    swr r2, r1
    li r1, 202
    add r1, r1, r6
    lwr r2, r1
    li r1, 1215
    add r1, r1, r6
    swr r2, r1
    li r1, 201
    add r1, r1, r6
    lwr r2, r1
    lui r1, 19
    add r1, r1, r6
    swr r2, r1
    li r1, 200
    add r1, r1, r6
    lwr r2, r1
    li r1, 1217
    add r1, r1, r6
    swr r2, r1
    li r1, 198
    add r1, r1, r6
    lwr r2, r1
    li r1, 1218
    add r1, r1, r6
    swr r2, r1
    li r1, 197
    add r1, r1, r6
    lwr r2, r1
    li r1, 1219
    add r1, r1, r6
    swr r2, r1
    li r1, 196
    add r1, r1, r6
    lwr r2, r1
    li r1, 1220
    add r1, r1, r6
    swr r2, r1
    li r1, 194
    add r1, r1, r6
    lwr r2, r1
    li r1, 1221
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_60
_B_main_151:
    li r1, 319
    add r1, r1, r6
    lwr r2, r1
    li r1, 1202
    add r1, r1, r6
    swr r2, r1
    li r1, 325
    add r1, r1, r6
    lwr r2, r1
    li r1, 1203
    add r1, r1, r6
    swr r2, r1
    li r1, 327
    add r1, r1, r6
    lwr r2, r1
    li r1, 1204
    add r1, r1, r6
    swr r2, r1
    li r1, 329
    add r1, r1, r6
    lwr r2, r1
    li r1, 1205
    add r1, r1, r6
    swr r2, r1
    li r1, 331
    add r1, r1, r6
    lwr r2, r1
    li r1, 1206
    add r1, r1, r6
    swr r2, r1
    li r1, 333
    add r1, r1, r6
    lwr r2, r1
    li r1, 1207
    add r1, r1, r6
    swr r2, r1
    li r1, 335
    add r1, r1, r6
    lwr r2, r1
    li r1, 1208
    add r1, r1, r6
    swr r2, r1
    li r1, 337
    add r1, r1, r6
    lwr r2, r1
    li r1, 1209
    add r1, r1, r6
    swr r2, r1
    li r1, 339
    add r1, r1, r6
    lwr r2, r1
    li r1, 1210
    add r1, r1, r6
    swr r2, r1
    li r1, 341
    add r1, r1, r6
    lwr r2, r1
    li r1, 1211
    add r1, r1, r6
    swr r2, r1
    li r1, 185
    add r1, r1, r6
    lwr r2, r1
    li r1, 1212
    add r1, r1, r6
    swr r2, r1
    li r1, 698
    add r1, r1, r6
    lwr r2, r1
    li r1, 1213
    add r1, r1, r6
    swr r2, r1
    li r1, 700
    add r1, r1, r6
    lwr r2, r1
    li r1, 1214
    add r1, r1, r6
    swr r2, r1
    li r1, 702
    add r1, r1, r6
    lwr r2, r1
    li r1, 1215
    add r1, r1, r6
    swr r2, r1
    lui r1, 11
    add r1, r1, r6
    lwr r2, r1
    lui r1, 19
    add r1, r1, r6
    swr r2, r1
    li r1, 706
    add r1, r1, r6
    lwr r2, r1
    li r1, 1217
    add r1, r1, r6
    swr r2, r1
    li r1, 708
    add r1, r1, r6
    lwr r2, r1
    li r1, 1218
    add r1, r1, r6
    swr r2, r1
    li r1, 710
    add r1, r1, r6
    lwr r2, r1
    li r1, 1219
    add r1, r1, r6
    swr r2, r1
    li r1, 712
    add r1, r1, r6
    lwr r2, r1
    li r1, 1220
    add r1, r1, r6
    swr r2, r1
    li r1, 714
    add r1, r1, r6
    lwr r2, r1
    li r1, 1221
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_60
_B_main_152:
    li r1, 228
    add r1, r1, r6
    lwr r2, r1
    li r1, 1222
    add r1, r1, r6
    swr r2, r1
    li r1, 233
    add r1, r1, r6
    lwr r2, r1
    li r1, 1223
    add r1, r1, r6
    swr r2, r1
    li r1, 232
    add r1, r1, r6
    lwr r2, r1
    li r1, 1224
    add r1, r1, r6
    swr r2, r1
    li r1, 231
    add r1, r1, r6
    lwr r2, r1
    li r1, 1225
    add r1, r1, r6
    swr r2, r1
    li r1, 230
    add r1, r1, r6
    lwr r2, r1
    li r1, 1226
    add r1, r1, r6
    swr r2, r1
    li r1, 229
    add r1, r1, r6
    lwr r2, r1
    li r1, 1227
    add r1, r1, r6
    swr r2, r1
    li r1, 227
    add r1, r1, r6
    lwr r2, r1
    li r1, 1228
    add r1, r1, r6
    swr r2, r1
    li r1, 226
    add r1, r1, r6
    lwr r2, r1
    li r1, 1229
    add r1, r1, r6
    swr r2, r1
    li r1, 225
    add r1, r1, r6
    lwr r2, r1
    li r1, 1230
    add r1, r1, r6
    swr r2, r1
    li r1, 660
    add r1, r1, r6
    lwr r2, r1
    li r1, 1231
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_70
_B_main_153:
    li r1, 319
    add r1, r1, r6
    lwr r2, r1
    li r1, 1222
    add r1, r1, r6
    swr r2, r1
    li r1, 642
    add r1, r1, r6
    lwr r2, r1
    li r1, 1223
    add r1, r1, r6
    swr r2, r1
    li r1, 644
    add r1, r1, r6
    lwr r2, r1
    li r1, 1224
    add r1, r1, r6
    swr r2, r1
    li r1, 646
    add r1, r1, r6
    lwr r2, r1
    li r1, 1225
    add r1, r1, r6
    swr r2, r1
    li r1, 648
    add r1, r1, r6
    lwr r2, r1
    li r1, 1226
    add r1, r1, r6
    swr r2, r1
    li r1, 652
    add r1, r1, r6
    lwr r2, r1
    li r1, 1227
    add r1, r1, r6
    swr r2, r1
    li r1, 654
    add r1, r1, r6
    lwr r2, r1
    li r1, 1228
    add r1, r1, r6
    swr r2, r1
    li r1, 656
    add r1, r1, r6
    lwr r2, r1
    li r1, 1229
    add r1, r1, r6
    swr r2, r1
    li r1, 658
    add r1, r1, r6
    lwr r2, r1
    li r1, 1230
    add r1, r1, r6
    swr r2, r1
    li r1, 224
    add r1, r1, r6
    lwr r2, r1
    li r1, 1231
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_70
_B_main_154:
    li r1, 1222
    add r1, r1, r6
    lwr r2, r1
    li r1, 1232
    add r1, r1, r6
    swr r2, r1
    li r1, 217
    add r1, r1, r6
    lwr r2, r1
    li r1, 1233
    add r1, r1, r6
    swr r2, r1
    li r1, 222
    add r1, r1, r6
    lwr r2, r1
    li r1, 1234
    add r1, r1, r6
    swr r2, r1
    li r1, 1223
    add r1, r1, r6
    lwr r2, r1
    li r1, 1235
    add r1, r1, r6
    swr r2, r1
    li r1, 1224
    add r1, r1, r6
    lwr r2, r1
    li r1, 1236
    add r1, r1, r6
    swr r2, r1
    li r1, 1225
    add r1, r1, r6
    lwr r2, r1
    li r1, 1237
    add r1, r1, r6
    swr r2, r1
    li r1, 1226
    add r1, r1, r6
    lwr r2, r1
    li r1, 1238
    add r1, r1, r6
    swr r2, r1
    li r1, 1227
    add r1, r1, r6
    lwr r2, r1
    li r1, 1239
    add r1, r1, r6
    swr r2, r1
    li r1, 1228
    add r1, r1, r6
    lwr r2, r1
    li r1, 1240
    add r1, r1, r6
    swr r2, r1
    li r1, 1229
    add r1, r1, r6
    lwr r2, r1
    li r1, 1241
    add r1, r1, r6
    swr r2, r1
    li r1, 1230
    add r1, r1, r6
    lwr r2, r1
    li r1, 1242
    add r1, r1, r6
    swr r2, r1
    li r1, 1231
    add r1, r1, r6
    lwr r2, r1
    li r1, 1243
    add r1, r1, r6
    swr r2, r1
    li r1, 223
    add r1, r1, r6
    lwr r2, r1
    li r1, 1244
    add r1, r1, r6
    swr r2, r1
    li r1, 221
    add r1, r1, r6
    lwr r2, r1
    li r1, 1245
    add r1, r1, r6
    swr r2, r1
    li r1, 220
    add r1, r1, r6
    lwr r2, r1
    li r1, 1246
    add r1, r1, r6
    swr r2, r1
    li r1, 219
    add r1, r1, r6
    lwr r2, r1
    li r1, 1247
    add r1, r1, r6
    swr r2, r1
    li r1, 218
    add r1, r1, r6
    lwr r2, r1
    li r1, 1248
    add r1, r1, r6
    swr r2, r1
    li r1, 216
    add r1, r1, r6
    lwr r2, r1
    li r1, 1249
    add r1, r1, r6
    swr r2, r1
    li r1, 215
    add r1, r1, r6
    lwr r2, r1
    li r1, 1250
    add r1, r1, r6
    swr r2, r1
    li r1, 214
    add r1, r1, r6
    lwr r2, r1
    li r1, 1251
    add r1, r1, r6
    swr r2, r1
    li r1, 213
    add r1, r1, r6
    lwr r2, r1
    li r1, 1252
    add r1, r1, r6
    swr r2, r1
    li r1, 682
    add r1, r1, r6
    lwr r2, r1
    li r1, 1253
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_71
_B_main_155:
    li r1, 319
    add r1, r1, r6
    lwr r2, r1
    li r1, 1232
    add r1, r1, r6
    swr r2, r1
    li r1, 325
    add r1, r1, r6
    lwr r2, r1
    li r1, 1233
    add r1, r1, r6
    swr r2, r1
    li r1, 327
    add r1, r1, r6
    lwr r2, r1
    li r1, 1234
    add r1, r1, r6
    swr r2, r1
    li r1, 642
    add r1, r1, r6
    lwr r2, r1
    li r1, 1235
    add r1, r1, r6
    swr r2, r1
    li r1, 644
    add r1, r1, r6
    lwr r2, r1
    li r1, 1236
    add r1, r1, r6
    swr r2, r1
    li r1, 646
    add r1, r1, r6
    lwr r2, r1
    li r1, 1237
    add r1, r1, r6
    swr r2, r1
    li r1, 648
    add r1, r1, r6
    lwr r2, r1
    li r1, 1238
    add r1, r1, r6
    swr r2, r1
    li r1, 652
    add r1, r1, r6
    lwr r2, r1
    li r1, 1239
    add r1, r1, r6
    swr r2, r1
    li r1, 654
    add r1, r1, r6
    lwr r2, r1
    li r1, 1240
    add r1, r1, r6
    swr r2, r1
    li r1, 656
    add r1, r1, r6
    lwr r2, r1
    li r1, 1241
    add r1, r1, r6
    swr r2, r1
    li r1, 658
    add r1, r1, r6
    lwr r2, r1
    li r1, 1242
    add r1, r1, r6
    swr r2, r1
    li r1, 660
    add r1, r1, r6
    lwr r2, r1
    li r1, 1243
    add r1, r1, r6
    swr r2, r1
    li r1, 662
    add r1, r1, r6
    lwr r2, r1
    li r1, 1244
    add r1, r1, r6
    swr r2, r1
    li r1, 664
    add r1, r1, r6
    lwr r2, r1
    li r1, 1245
    add r1, r1, r6
    swr r2, r1
    li r1, 666
    add r1, r1, r6
    lwr r2, r1
    li r1, 1246
    add r1, r1, r6
    swr r2, r1
    li r1, 668
    add r1, r1, r6
    lwr r2, r1
    li r1, 1247
    add r1, r1, r6
    swr r2, r1
    li r1, 670
    add r1, r1, r6
    lwr r2, r1
    li r1, 1248
    add r1, r1, r6
    swr r2, r1
    li r1, 674
    add r1, r1, r6
    lwr r2, r1
    li r1, 1249
    add r1, r1, r6
    swr r2, r1
    li r1, 676
    add r1, r1, r6
    lwr r2, r1
    li r1, 1250
    add r1, r1, r6
    swr r2, r1
    li r1, 678
    add r1, r1, r6
    lwr r2, r1
    li r1, 1251
    add r1, r1, r6
    swr r2, r1
    li r1, 680
    add r1, r1, r6
    lwr r2, r1
    li r1, 1252
    add r1, r1, r6
    swr r2, r1
    li r1, 212
    add r1, r1, r6
    lwr r2, r1
    li r1, 1253
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_71
_B_main_156:
    li r1, 250
    add r1, r1, r6
    lwr r2, r1
    li r1, 1254
    add r1, r1, r6
    swr r2, r1
    li r1, 248
    add r1, r1, r6
    lwr r2, r1
    li r1, 1255
    add r1, r1, r6
    swr r2, r1
    li r1, 255
    add r1, r1, r6
    lwr r2, r1
    li r1, 1256
    add r1, r1, r6
    swr r2, r1
    li r1, 254
    add r1, r1, r6
    lwr r2, r1
    li r1, 1257
    add r1, r1, r6
    swr r2, r1
    li r1, 253
    add r1, r1, r6
    lwr r2, r1
    li r1, 1258
    add r1, r1, r6
    swr r2, r1
    li r1, 252
    add r1, r1, r6
    lwr r2, r1
    li r1, 1259
    add r1, r1, r6
    swr r2, r1
    li r1, 251
    add r1, r1, r6
    lwr r2, r1
    li r1, 1260
    add r1, r1, r6
    swr r2, r1
    li r1, 249
    add r1, r1, r6
    lwr r2, r1
    li r1, 1261
    add r1, r1, r6
    swr r2, r1
    li r1, 247
    add r1, r1, r6
    lwr r2, r1
    li r1, 1262
    add r1, r1, r6
    swr r2, r1
    li r1, 246
    add r1, r1, r6
    lwr r2, r1
    li r1, 1263
    add r1, r1, r6
    swr r2, r1
    li r1, 245
    add r1, r1, r6
    lwr r2, r1
    li r1, 1264
    add r1, r1, r6
    swr r2, r1
    li r1, 244
    add r1, r1, r6
    lwr r2, r1
    li r1, 1265
    add r1, r1, r6
    swr r2, r1
    li r1, 243
    add r1, r1, r6
    lwr r2, r1
    li r1, 1266
    add r1, r1, r6
    swr r2, r1
    li r1, 242
    add r1, r1, r6
    lwr r2, r1
    li r1, 1267
    add r1, r1, r6
    swr r2, r1
    li r1, 626
    add r1, r1, r6
    lwr r2, r1
    li r1, 1268
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_78
_B_main_157:
    li r1, 319
    add r1, r1, r6
    lwr r2, r1
    li r1, 1254
    add r1, r1, r6
    swr r2, r1
    li r1, 327
    add r1, r1, r6
    lwr r2, r1
    li r1, 1255
    add r1, r1, r6
    swr r2, r1
    li r1, 600
    add r1, r1, r6
    lwr r2, r1
    li r1, 1256
    add r1, r1, r6
    swr r2, r1
    li r1, 602
    add r1, r1, r6
    lwr r2, r1
    li r1, 1257
    add r1, r1, r6
    swr r2, r1
    li r1, 604
    add r1, r1, r6
    lwr r2, r1
    li r1, 1258
    add r1, r1, r6
    swr r2, r1
    li r1, 608
    add r1, r1, r6
    lwr r2, r1
    li r1, 1259
    add r1, r1, r6
    swr r2, r1
    li r1, 610
    add r1, r1, r6
    lwr r2, r1
    li r1, 1260
    add r1, r1, r6
    swr r2, r1
    li r1, 612
    add r1, r1, r6
    lwr r2, r1
    li r1, 1261
    add r1, r1, r6
    swr r2, r1
    li r1, 614
    add r1, r1, r6
    lwr r2, r1
    li r1, 1262
    add r1, r1, r6
    swr r2, r1
    li r1, 616
    add r1, r1, r6
    lwr r2, r1
    li r1, 1263
    add r1, r1, r6
    swr r2, r1
    li r1, 618
    add r1, r1, r6
    lwr r2, r1
    li r1, 1264
    add r1, r1, r6
    swr r2, r1
    li r1, 620
    add r1, r1, r6
    lwr r2, r1
    li r1, 1265
    add r1, r1, r6
    swr r2, r1
    li r1, 622
    add r1, r1, r6
    lwr r2, r1
    li r1, 1266
    add r1, r1, r6
    swr r2, r1
    li r1, 624
    add r1, r1, r6
    lwr r2, r1
    li r1, 1267
    add r1, r1, r6
    swr r2, r1
    li r1, 241
    add r1, r1, r6
    lwr r2, r1
    li r1, 1268
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_78
_B_main_158:
    li r1, 277
    add r1, r1, r6
    lwr r2, r1
    li r1, 1269
    add r1, r1, r6
    swr r2, r1
    li r1, 268
    add r1, r1, r6
    lwr r2, r1
    li r1, 1270
    add r1, r1, r6
    swr r2, r1
    li r1, 267
    add r1, r1, r6
    lwr r2, r1
    li r1, 1271
    add r1, r1, r6
    swr r2, r1
    li r1, 266
    add r1, r1, r6
    lwr r2, r1
    li r1, 1272
    add r1, r1, r6
    swr r2, r1
    li r1, 265
    add r1, r1, r6
    lwr r2, r1
    li r1, 1273
    add r1, r1, r6
    swr r2, r1
    li r1, 264
    add r1, r1, r6
    lwr r2, r1
    li r1, 1274
    add r1, r1, r6
    swr r2, r1
    li r1, 586
    add r1, r1, r6
    lwr r2, r1
    li r1, 1275
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_85
_B_main_159:
    li r1, 572
    add r1, r1, r6
    lwr r2, r1
    li r1, 1269
    add r1, r1, r6
    swr r2, r1
    li r1, 574
    add r1, r1, r6
    lwr r2, r1
    li r1, 1270
    add r1, r1, r6
    swr r2, r1
    lui r1, 9
    add r1, r1, r6
    lwr r2, r1
    li r1, 1271
    add r1, r1, r6
    swr r2, r1
    li r1, 578
    add r1, r1, r6
    lwr r2, r1
    li r1, 1272
    add r1, r1, r6
    swr r2, r1
    li r1, 580
    add r1, r1, r6
    lwr r2, r1
    li r1, 1273
    add r1, r1, r6
    swr r2, r1
    li r1, 582
    add r1, r1, r6
    lwr r2, r1
    li r1, 1274
    add r1, r1, r6
    swr r2, r1
    li r1, 263
    add r1, r1, r6
    lwr r2, r1
    li r1, 1275
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_85
_B_main_160:
    li r1, 286
    add r1, r1, r6
    lwr r2, r1
    li r1, 1276
    add r1, r1, r6
    swr r2, r1
    li r1, 285
    add r1, r1, r6
    lwr r2, r1
    li r1, 1277
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_92
_B_main_161:
    li r1, 552
    add r1, r1, r6
    lwr r2, r1
    li r1, 1276
    add r1, r1, r6
    swr r2, r1
    li r1, 554
    add r1, r1, r6
    lwr r2, r1
    li r1, 1277
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_92
_B_main_162:
    li r1, 1276
    add r1, r1, r6
    lwr r2, r1
    li r1, 1278
    add r1, r1, r6
    swr r2, r1
    li r1, 1277
    add r1, r1, r6
    lwr r2, r1
    li r1, 1279
    add r1, r1, r6
    swr r2, r1
    li r1, 288
    add r1, r1, r6
    lwr r2, r1
    li r1, 289
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_93
_B_main_163:
    li r1, 286
    add r1, r1, r6
    lwr r2, r1
    li r1, 1278
    add r1, r1, r6
    swr r2, r1
    li r1, 285
    add r1, r1, r6
    lwr r2, r1
    li r1, 1279
    add r1, r1, r6
    swr r2, r1
    li r1, 287
    add r1, r1, r6
    lwr r2, r1
    li r1, 289
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_93
_B_main_164:
    li r1, 295
    add r1, r1, r6
    lwr r2, r1
    lui r1, 20
    add r1, r1, r6
    swr r2, r1
    li r1, 300
    add r1, r1, r6
    lwr r2, r1
    li r1, 1281
    add r1, r1, r6
    swr r2, r1
    li r1, 299
    add r1, r1, r6
    lwr r2, r1
    li r1, 1282
    add r1, r1, r6
    swr r2, r1
    li r1, 298
    add r1, r1, r6
    lwr r2, r1
    li r1, 1283
    add r1, r1, r6
    swr r2, r1
    li r1, 297
    add r1, r1, r6
    lwr r2, r1
    li r1, 1284
    add r1, r1, r6
    swr r2, r1
    li r1, 296
    add r1, r1, r6
    lwr r2, r1
    li r1, 1285
    add r1, r1, r6
    swr r2, r1
    li r1, 294
    add r1, r1, r6
    lwr r2, r1
    li r1, 1286
    add r1, r1, r6
    swr r2, r1
    li r1, 293
    add r1, r1, r6
    lwr r2, r1
    li r1, 1287
    add r1, r1, r6
    swr r2, r1
    li r1, 292
    add r1, r1, r6
    lwr r2, r1
    li r1, 1288
    add r1, r1, r6
    swr r2, r1
    li r1, 291
    add r1, r1, r6
    lwr r2, r1
    li r1, 1289
    add r1, r1, r6
    swr r2, r1
    li r1, 550
    add r1, r1, r6
    lwr r2, r1
    li r1, 1290
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_97
_B_main_165:
    li r1, 327
    add r1, r1, r6
    lwr r2, r1
    lui r1, 20
    add r1, r1, r6
    swr r2, r1
    li r1, 530
    add r1, r1, r6
    lwr r2, r1
    li r1, 1281
    add r1, r1, r6
    swr r2, r1
    li r1, 532
    add r1, r1, r6
    lwr r2, r1
    li r1, 1282
    add r1, r1, r6
    swr r2, r1
    li r1, 534
    add r1, r1, r6
    lwr r2, r1
    li r1, 1283
    add r1, r1, r6
    swr r2, r1
    li r1, 536
    add r1, r1, r6
    lwr r2, r1
    li r1, 1284
    add r1, r1, r6
    swr r2, r1
    li r1, 538
    add r1, r1, r6
    lwr r2, r1
    li r1, 1285
    add r1, r1, r6
    swr r2, r1
    li r1, 542
    add r1, r1, r6
    lwr r2, r1
    li r1, 1286
    add r1, r1, r6
    swr r2, r1
    li r1, 544
    add r1, r1, r6
    lwr r2, r1
    li r1, 1287
    add r1, r1, r6
    swr r2, r1
    li r1, 546
    add r1, r1, r6
    lwr r2, r1
    li r1, 1288
    add r1, r1, r6
    swr r2, r1
    li r1, 548
    add r1, r1, r6
    lwr r2, r1
    li r1, 1289
    add r1, r1, r6
    swr r2, r1
    li r1, 290
    add r1, r1, r6
    lwr r2, r1
    li r1, 1290
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_97
_B_main_166:
    li r1, 315
    add r1, r1, r6
    lwr r2, r1
    li r1, 1291
    add r1, r1, r6
    swr r2, r1
    li r1, 314
    add r1, r1, r6
    lwr r2, r1
    li r1, 1292
    add r1, r1, r6
    swr r2, r1
    li r1, 313
    add r1, r1, r6
    lwr r2, r1
    li r1, 1293
    add r1, r1, r6
    swr r2, r1
    li r1, 312
    add r1, r1, r6
    lwr r2, r1
    li r1, 1294
    add r1, r1, r6
    swr r2, r1
    li r1, 510
    add r1, r1, r6
    lwr r2, r1
    li r1, 1295
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_106
_B_main_167:
    li r1, 70
    add r1, r1, r6
    lwr r2, r1
    li r1, 1291
    add r1, r1, r6
    swr r2, r1
    li r1, 504
    add r1, r1, r6
    lwr r2, r1
    li r1, 1292
    add r1, r1, r6
    swr r2, r1
    li r1, 506
    add r1, r1, r6
    lwr r2, r1
    li r1, 1293
    add r1, r1, r6
    swr r2, r1
    li r1, 508
    add r1, r1, r6
    lwr r2, r1
    li r1, 1294
    add r1, r1, r6
    swr r2, r1
    li r1, 311
    add r1, r1, r6
    lwr r2, r1
    li r1, 1295
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_106
_B_main_168:
    li r1, 1291
    add r1, r1, r6
    lwr r2, r1
    li r1, 1296
    add r1, r1, r6
    swr r2, r1
    li r1, 1292
    add r1, r1, r6
    lwr r2, r1
    li r1, 1297
    add r1, r1, r6
    swr r2, r1
    li r1, 1293
    add r1, r1, r6
    lwr r2, r1
    li r1, 1298
    add r1, r1, r6
    swr r2, r1
    li r1, 1294
    add r1, r1, r6
    lwr r2, r1
    li r1, 1299
    add r1, r1, r6
    swr r2, r1
    li r1, 1295
    add r1, r1, r6
    lwr r2, r1
    li r1, 1300
    add r1, r1, r6
    swr r2, r1
    li r1, 310
    add r1, r1, r6
    lwr r2, r1
    li r1, 1301
    add r1, r1, r6
    swr r2, r1
    li r1, 309
    add r1, r1, r6
    lwr r2, r1
    li r1, 1302
    add r1, r1, r6
    swr r2, r1
    li r1, 516
    add r1, r1, r6
    lwr r2, r1
    li r1, 1303
    add r1, r1, r6
    swr r2, r1
    li r1, 520
    add r1, r1, r6
    lwr r2, r1
    li r1, 1304
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_107
_B_main_169:
    li r1, 308
    add r1, r1, r6
    lwr r2, r1
    li r1, 1296
    add r1, r1, r6
    swr r2, r1
    li r1, 504
    add r1, r1, r6
    lwr r2, r1
    li r1, 1297
    add r1, r1, r6
    swr r2, r1
    li r1, 506
    add r1, r1, r6
    lwr r2, r1
    li r1, 1298
    add r1, r1, r6
    swr r2, r1
    li r1, 508
    add r1, r1, r6
    lwr r2, r1
    li r1, 1299
    add r1, r1, r6
    swr r2, r1
    li r1, 510
    add r1, r1, r6
    lwr r2, r1
    li r1, 1300
    add r1, r1, r6
    swr r2, r1
    lui r1, 8
    add r1, r1, r6
    lwr r2, r1
    li r1, 1301
    add r1, r1, r6
    swr r2, r1
    li r1, 514
    add r1, r1, r6
    lwr r2, r1
    li r1, 1302
    add r1, r1, r6
    swr r2, r1
    li r1, 307
    add r1, r1, r6
    lwr r2, r1
    li r1, 1303
    add r1, r1, r6
    swr r2, r1
    li r1, 306
    add r1, r1, r6
    lwr r2, r1
    li r1, 1304
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_107
_B_main_170:
    li r1, 1296
    add r1, r1, r6
    lwr r2, r1
    li r1, 1305
    add r1, r1, r6
    swr r2, r1
    li r1, 327
    add r1, r1, r6
    lwr r2, r1
    li r1, 1306
    add r1, r1, r6
    swr r2, r1
    li r1, 1297
    add r1, r1, r6
    lwr r2, r1
    li r1, 1307
    add r1, r1, r6
    swr r2, r1
    li r1, 1298
    add r1, r1, r6
    lwr r2, r1
    li r1, 1308
    add r1, r1, r6
    swr r2, r1
    li r1, 1299
    add r1, r1, r6
    lwr r2, r1
    li r1, 1309
    add r1, r1, r6
    swr r2, r1
    li r1, 1300
    add r1, r1, r6
    lwr r2, r1
    li r1, 1310
    add r1, r1, r6
    swr r2, r1
    li r1, 1301
    add r1, r1, r6
    lwr r2, r1
    li r1, 1311
    add r1, r1, r6
    swr r2, r1
    li r1, 1302
    add r1, r1, r6
    lwr r2, r1
    li r1, 1312
    add r1, r1, r6
    swr r2, r1
    li r1, 1303
    add r1, r1, r6
    lwr r2, r1
    li r1, 1313
    add r1, r1, r6
    swr r2, r1
    li r1, 1304
    add r1, r1, r6
    lwr r2, r1
    li r1, 1314
    add r1, r1, r6
    swr r2, r1
    li r1, 305
    add r1, r1, r6
    lwr r2, r1
    li r1, 1315
    add r1, r1, r6
    swr r2, r1
    li r1, 304
    add r1, r1, r6
    lwr r2, r1
    li r1, 1316
    add r1, r1, r6
    swr r2, r1
    li r1, 526
    add r1, r1, r6
    lwr r2, r1
    li r1, 1317
    add r1, r1, r6
    swr r2, r1
    li r1, 528
    add r1, r1, r6
    lwr r2, r1
    li r1, 1318
    add r1, r1, r6
    swr r2, r1
    li r1, 530
    add r1, r1, r6
    lwr r2, r1
    li r1, 1319
    add r1, r1, r6
    swr r2, r1
    li r1, 532
    add r1, r1, r6
    lwr r2, r1
    li r1, 1320
    add r1, r1, r6
    swr r2, r1
    li r1, 534
    add r1, r1, r6
    lwr r2, r1
    li r1, 1321
    add r1, r1, r6
    swr r2, r1
    li r1, 536
    add r1, r1, r6
    lwr r2, r1
    li r1, 1322
    add r1, r1, r6
    swr r2, r1
    li r1, 538
    add r1, r1, r6
    lwr r2, r1
    li r1, 1323
    add r1, r1, r6
    swr r2, r1
    li r1, 542
    add r1, r1, r6
    lwr r2, r1
    li r1, 1324
    add r1, r1, r6
    swr r2, r1
    li r1, 544
    add r1, r1, r6
    lwr r2, r1
    li r1, 1325
    add r1, r1, r6
    swr r2, r1
    li r1, 546
    add r1, r1, r6
    lwr r2, r1
    li r1, 1326
    add r1, r1, r6
    swr r2, r1
    li r1, 548
    add r1, r1, r6
    lwr r2, r1
    li r1, 1327
    add r1, r1, r6
    swr r2, r1
    li r1, 550
    add r1, r1, r6
    lwr r2, r1
    li r1, 1328
    add r1, r1, r6
    swr r2, r1
    li r1, 552
    add r1, r1, r6
    lwr r2, r1
    li r1, 1329
    add r1, r1, r6
    swr r2, r1
    li r1, 554
    add r1, r1, r6
    lwr r2, r1
    li r1, 1330
    add r1, r1, r6
    swr r2, r1
    li r1, 556
    add r1, r1, r6
    lwr r2, r1
    li r1, 1331
    add r1, r1, r6
    swr r2, r1
    li r1, 558
    add r1, r1, r6
    lwr r2, r1
    li r1, 1332
    add r1, r1, r6
    swr r2, r1
    li r1, 560
    add r1, r1, r6
    lwr r2, r1
    li r1, 1333
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_108
_B_main_171:
    li r1, 303
    add r1, r1, r6
    lwr r2, r1
    li r1, 1305
    add r1, r1, r6
    swr r2, r1
    lui r1, 20
    add r1, r1, r6
    lwr r2, r1
    li r1, 1306
    add r1, r1, r6
    swr r2, r1
    li r1, 504
    add r1, r1, r6
    lwr r2, r1
    li r1, 1307
    add r1, r1, r6
    swr r2, r1
    li r1, 506
    add r1, r1, r6
    lwr r2, r1
    li r1, 1308
    add r1, r1, r6
    swr r2, r1
    li r1, 508
    add r1, r1, r6
    lwr r2, r1
    li r1, 1309
    add r1, r1, r6
    swr r2, r1
    li r1, 510
    add r1, r1, r6
    lwr r2, r1
    li r1, 1310
    add r1, r1, r6
    swr r2, r1
    lui r1, 8
    add r1, r1, r6
    lwr r2, r1
    li r1, 1311
    add r1, r1, r6
    swr r2, r1
    li r1, 514
    add r1, r1, r6
    lwr r2, r1
    li r1, 1312
    add r1, r1, r6
    swr r2, r1
    li r1, 516
    add r1, r1, r6
    lwr r2, r1
    li r1, 1313
    add r1, r1, r6
    swr r2, r1
    li r1, 520
    add r1, r1, r6
    lwr r2, r1
    li r1, 1314
    add r1, r1, r6
    swr r2, r1
    li r1, 522
    add r1, r1, r6
    lwr r2, r1
    li r1, 1315
    add r1, r1, r6
    swr r2, r1
    li r1, 524
    add r1, r1, r6
    lwr r2, r1
    li r1, 1316
    add r1, r1, r6
    swr r2, r1
    li r1, 302
    add r1, r1, r6
    lwr r2, r1
    li r1, 1317
    add r1, r1, r6
    swr r2, r1
    li r1, 301
    add r1, r1, r6
    lwr r2, r1
    li r1, 1318
    add r1, r1, r6
    swr r2, r1
    li r1, 1281
    add r1, r1, r6
    lwr r2, r1
    li r1, 1319
    add r1, r1, r6
    swr r2, r1
    li r1, 1282
    add r1, r1, r6
    lwr r2, r1
    li r1, 1320
    add r1, r1, r6
    swr r2, r1
    li r1, 1283
    add r1, r1, r6
    lwr r2, r1
    li r1, 1321
    add r1, r1, r6
    swr r2, r1
    li r1, 1284
    add r1, r1, r6
    lwr r2, r1
    li r1, 1322
    add r1, r1, r6
    swr r2, r1
    li r1, 1285
    add r1, r1, r6
    lwr r2, r1
    li r1, 1323
    add r1, r1, r6
    swr r2, r1
    li r1, 1286
    add r1, r1, r6
    lwr r2, r1
    li r1, 1324
    add r1, r1, r6
    swr r2, r1
    li r1, 1287
    add r1, r1, r6
    lwr r2, r1
    li r1, 1325
    add r1, r1, r6
    swr r2, r1
    li r1, 1288
    add r1, r1, r6
    lwr r2, r1
    li r1, 1326
    add r1, r1, r6
    swr r2, r1
    li r1, 1289
    add r1, r1, r6
    lwr r2, r1
    li r1, 1327
    add r1, r1, r6
    swr r2, r1
    li r1, 1290
    add r1, r1, r6
    lwr r2, r1
    li r1, 1328
    add r1, r1, r6
    swr r2, r1
    li r1, 1278
    add r1, r1, r6
    lwr r2, r1
    li r1, 1329
    add r1, r1, r6
    swr r2, r1
    li r1, 1279
    add r1, r1, r6
    lwr r2, r1
    li r1, 1330
    add r1, r1, r6
    swr r2, r1
    li r1, 284
    add r1, r1, r6
    lwr r2, r1
    li r1, 1331
    add r1, r1, r6
    swr r2, r1
    li r1, 283
    add r1, r1, r6
    lwr r2, r1
    li r1, 1332
    add r1, r1, r6
    swr r2, r1
    li r1, 289
    add r1, r1, r6
    lwr r2, r1
    li r1, 1333
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_108
_B_main_172:
    li r1, 1305
    add r1, r1, r6
    lwr r2, r1
    li r1, 1334
    add r1, r1, r6
    swr r2, r1
    li r1, 1306
    add r1, r1, r6
    lwr r2, r1
    li r1, 1335
    add r1, r1, r6
    swr r2, r1
    li r1, 1307
    add r1, r1, r6
    lwr r2, r1
    li r1, 1336
    add r1, r1, r6
    swr r2, r1
    li r1, 1308
    add r1, r1, r6
    lwr r2, r1
    li r1, 1337
    add r1, r1, r6
    swr r2, r1
    li r1, 1309
    add r1, r1, r6
    lwr r2, r1
    li r1, 1338
    add r1, r1, r6
    swr r2, r1
    li r1, 1310
    add r1, r1, r6
    lwr r2, r1
    li r1, 1339
    add r1, r1, r6
    swr r2, r1
    li r1, 1311
    add r1, r1, r6
    lwr r2, r1
    li r1, 1340
    add r1, r1, r6
    swr r2, r1
    li r1, 1312
    add r1, r1, r6
    lwr r2, r1
    li r1, 1341
    add r1, r1, r6
    swr r2, r1
    li r1, 1313
    add r1, r1, r6
    lwr r2, r1
    li r1, 1342
    add r1, r1, r6
    swr r2, r1
    li r1, 1314
    add r1, r1, r6
    lwr r2, r1
    li r1, 1343
    add r1, r1, r6
    swr r2, r1
    li r1, 1315
    add r1, r1, r6
    lwr r2, r1
    lui r1, 21
    add r1, r1, r6
    swr r2, r1
    li r1, 1316
    add r1, r1, r6
    lwr r2, r1
    li r1, 1345
    add r1, r1, r6
    swr r2, r1
    li r1, 1317
    add r1, r1, r6
    lwr r2, r1
    li r1, 1346
    add r1, r1, r6
    swr r2, r1
    li r1, 1318
    add r1, r1, r6
    lwr r2, r1
    li r1, 1347
    add r1, r1, r6
    swr r2, r1
    li r1, 1319
    add r1, r1, r6
    lwr r2, r1
    li r1, 1348
    add r1, r1, r6
    swr r2, r1
    li r1, 1320
    add r1, r1, r6
    lwr r2, r1
    li r1, 1349
    add r1, r1, r6
    swr r2, r1
    li r1, 1321
    add r1, r1, r6
    lwr r2, r1
    li r1, 1350
    add r1, r1, r6
    swr r2, r1
    li r1, 1322
    add r1, r1, r6
    lwr r2, r1
    li r1, 1351
    add r1, r1, r6
    swr r2, r1
    li r1, 1323
    add r1, r1, r6
    lwr r2, r1
    li r1, 1352
    add r1, r1, r6
    swr r2, r1
    li r1, 1324
    add r1, r1, r6
    lwr r2, r1
    li r1, 1353
    add r1, r1, r6
    swr r2, r1
    li r1, 1325
    add r1, r1, r6
    lwr r2, r1
    li r1, 1354
    add r1, r1, r6
    swr r2, r1
    li r1, 1326
    add r1, r1, r6
    lwr r2, r1
    li r1, 1355
    add r1, r1, r6
    swr r2, r1
    li r1, 1327
    add r1, r1, r6
    lwr r2, r1
    li r1, 1356
    add r1, r1, r6
    swr r2, r1
    li r1, 1328
    add r1, r1, r6
    lwr r2, r1
    li r1, 1357
    add r1, r1, r6
    swr r2, r1
    li r1, 1329
    add r1, r1, r6
    lwr r2, r1
    li r1, 1358
    add r1, r1, r6
    swr r2, r1
    li r1, 1330
    add r1, r1, r6
    lwr r2, r1
    li r1, 1359
    add r1, r1, r6
    swr r2, r1
    li r1, 1331
    add r1, r1, r6
    lwr r2, r1
    li r1, 1360
    add r1, r1, r6
    swr r2, r1
    li r1, 1332
    add r1, r1, r6
    lwr r2, r1
    li r1, 1361
    add r1, r1, r6
    swr r2, r1
    li r1, 1333
    add r1, r1, r6
    lwr r2, r1
    li r1, 1362
    add r1, r1, r6
    swr r2, r1
    li r1, 282
    add r1, r1, r6
    lwr r2, r1
    li r1, 1363
    add r1, r1, r6
    swr r2, r1
    li r1, 281
    add r1, r1, r6
    lwr r2, r1
    li r1, 1364
    add r1, r1, r6
    swr r2, r1
    li r1, 568
    add r1, r1, r6
    lwr r2, r1
    li r1, 1365
    add r1, r1, r6
    swr r2, r1
    li r1, 570
    add r1, r1, r6
    lwr r2, r1
    li r1, 1366
    add r1, r1, r6
    swr r2, r1
    li r1, 572
    add r1, r1, r6
    lwr r2, r1
    li r1, 1367
    add r1, r1, r6
    swr r2, r1
    li r1, 574
    add r1, r1, r6
    lwr r2, r1
    li r1, 1368
    add r1, r1, r6
    swr r2, r1
    lui r1, 9
    add r1, r1, r6
    lwr r2, r1
    li r1, 1369
    add r1, r1, r6
    swr r2, r1
    li r1, 578
    add r1, r1, r6
    lwr r2, r1
    li r1, 1370
    add r1, r1, r6
    swr r2, r1
    li r1, 580
    add r1, r1, r6
    lwr r2, r1
    li r1, 1371
    add r1, r1, r6
    swr r2, r1
    li r1, 582
    add r1, r1, r6
    lwr r2, r1
    li r1, 1372
    add r1, r1, r6
    swr r2, r1
    li r1, 586
    add r1, r1, r6
    lwr r2, r1
    li r1, 1373
    add r1, r1, r6
    swr r2, r1
    li r1, 588
    add r1, r1, r6
    lwr r2, r1
    li r1, 1374
    add r1, r1, r6
    swr r2, r1
    li r1, 590
    add r1, r1, r6
    lwr r2, r1
    li r1, 1375
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_109
_B_main_173:
    li r1, 280
    add r1, r1, r6
    lwr r2, r1
    li r1, 1334
    add r1, r1, r6
    swr r2, r1
    li r1, 327
    add r1, r1, r6
    lwr r2, r1
    li r1, 1335
    add r1, r1, r6
    swr r2, r1
    li r1, 504
    add r1, r1, r6
    lwr r2, r1
    li r1, 1336
    add r1, r1, r6
    swr r2, r1
    li r1, 506
    add r1, r1, r6
    lwr r2, r1
    li r1, 1337
    add r1, r1, r6
    swr r2, r1
    li r1, 508
    add r1, r1, r6
    lwr r2, r1
    li r1, 1338
    add r1, r1, r6
    swr r2, r1
    li r1, 510
    add r1, r1, r6
    lwr r2, r1
    li r1, 1339
    add r1, r1, r6
    swr r2, r1
    lui r1, 8
    add r1, r1, r6
    lwr r2, r1
    li r1, 1340
    add r1, r1, r6
    swr r2, r1
    li r1, 514
    add r1, r1, r6
    lwr r2, r1
    li r1, 1341
    add r1, r1, r6
    swr r2, r1
    li r1, 516
    add r1, r1, r6
    lwr r2, r1
    li r1, 1342
    add r1, r1, r6
    swr r2, r1
    li r1, 520
    add r1, r1, r6
    lwr r2, r1
    li r1, 1343
    add r1, r1, r6
    swr r2, r1
    li r1, 522
    add r1, r1, r6
    lwr r2, r1
    lui r1, 21
    add r1, r1, r6
    swr r2, r1
    li r1, 524
    add r1, r1, r6
    lwr r2, r1
    li r1, 1345
    add r1, r1, r6
    swr r2, r1
    li r1, 526
    add r1, r1, r6
    lwr r2, r1
    li r1, 1346
    add r1, r1, r6
    swr r2, r1
    li r1, 528
    add r1, r1, r6
    lwr r2, r1
    li r1, 1347
    add r1, r1, r6
    swr r2, r1
    li r1, 530
    add r1, r1, r6
    lwr r2, r1
    li r1, 1348
    add r1, r1, r6
    swr r2, r1
    li r1, 532
    add r1, r1, r6
    lwr r2, r1
    li r1, 1349
    add r1, r1, r6
    swr r2, r1
    li r1, 534
    add r1, r1, r6
    lwr r2, r1
    li r1, 1350
    add r1, r1, r6
    swr r2, r1
    li r1, 536
    add r1, r1, r6
    lwr r2, r1
    li r1, 1351
    add r1, r1, r6
    swr r2, r1
    li r1, 538
    add r1, r1, r6
    lwr r2, r1
    li r1, 1352
    add r1, r1, r6
    swr r2, r1
    li r1, 542
    add r1, r1, r6
    lwr r2, r1
    li r1, 1353
    add r1, r1, r6
    swr r2, r1
    li r1, 544
    add r1, r1, r6
    lwr r2, r1
    li r1, 1354
    add r1, r1, r6
    swr r2, r1
    li r1, 546
    add r1, r1, r6
    lwr r2, r1
    li r1, 1355
    add r1, r1, r6
    swr r2, r1
    li r1, 548
    add r1, r1, r6
    lwr r2, r1
    li r1, 1356
    add r1, r1, r6
    swr r2, r1
    li r1, 550
    add r1, r1, r6
    lwr r2, r1
    li r1, 1357
    add r1, r1, r6
    swr r2, r1
    li r1, 552
    add r1, r1, r6
    lwr r2, r1
    li r1, 1358
    add r1, r1, r6
    swr r2, r1
    li r1, 554
    add r1, r1, r6
    lwr r2, r1
    li r1, 1359
    add r1, r1, r6
    swr r2, r1
    li r1, 556
    add r1, r1, r6
    lwr r2, r1
    li r1, 1360
    add r1, r1, r6
    swr r2, r1
    li r1, 558
    add r1, r1, r6
    lwr r2, r1
    li r1, 1361
    add r1, r1, r6
    swr r2, r1
    li r1, 560
    add r1, r1, r6
    lwr r2, r1
    li r1, 1362
    add r1, r1, r6
    swr r2, r1
    li r1, 564
    add r1, r1, r6
    lwr r2, r1
    li r1, 1363
    add r1, r1, r6
    swr r2, r1
    li r1, 566
    add r1, r1, r6
    lwr r2, r1
    li r1, 1364
    add r1, r1, r6
    swr r2, r1
    li r1, 279
    add r1, r1, r6
    lwr r2, r1
    li r1, 1365
    add r1, r1, r6
    swr r2, r1
    li r1, 278
    add r1, r1, r6
    lwr r2, r1
    li r1, 1366
    add r1, r1, r6
    swr r2, r1
    li r1, 1269
    add r1, r1, r6
    lwr r2, r1
    li r1, 1367
    add r1, r1, r6
    swr r2, r1
    li r1, 1270
    add r1, r1, r6
    lwr r2, r1
    li r1, 1368
    add r1, r1, r6
    swr r2, r1
    li r1, 1271
    add r1, r1, r6
    lwr r2, r1
    li r1, 1369
    add r1, r1, r6
    swr r2, r1
    li r1, 1272
    add r1, r1, r6
    lwr r2, r1
    li r1, 1370
    add r1, r1, r6
    swr r2, r1
    li r1, 1273
    add r1, r1, r6
    lwr r2, r1
    li r1, 1371
    add r1, r1, r6
    swr r2, r1
    li r1, 1274
    add r1, r1, r6
    lwr r2, r1
    li r1, 1372
    add r1, r1, r6
    swr r2, r1
    li r1, 1275
    add r1, r1, r6
    lwr r2, r1
    li r1, 1373
    add r1, r1, r6
    swr r2, r1
    li r1, 262
    add r1, r1, r6
    lwr r2, r1
    li r1, 1374
    add r1, r1, r6
    swr r2, r1
    li r1, 261
    add r1, r1, r6
    lwr r2, r1
    li r1, 1375
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_109
_B_main_174:
    li r1, 319
    add r1, r1, r6
    lwr r2, r1
    li r1, 1376
    add r1, r1, r6
    swr r2, r1
    li r1, 1334
    add r1, r1, r6
    lwr r2, r1
    li r1, 1377
    add r1, r1, r6
    swr r2, r1
    li r1, 1335
    add r1, r1, r6
    lwr r2, r1
    li r1, 1378
    add r1, r1, r6
    swr r2, r1
    li r1, 1336
    add r1, r1, r6
    lwr r2, r1
    li r1, 1379
    add r1, r1, r6
    swr r2, r1
    li r1, 1337
    add r1, r1, r6
    lwr r2, r1
    li r1, 1380
    add r1, r1, r6
    swr r2, r1
    li r1, 1338
    add r1, r1, r6
    lwr r2, r1
    li r1, 1381
    add r1, r1, r6
    swr r2, r1
    li r1, 1339
    add r1, r1, r6
    lwr r2, r1
    li r1, 1382
    add r1, r1, r6
    swr r2, r1
    li r1, 1340
    add r1, r1, r6
    lwr r2, r1
    li r1, 1383
    add r1, r1, r6
    swr r2, r1
    li r1, 1341
    add r1, r1, r6
    lwr r2, r1
    li r1, 1384
    add r1, r1, r6
    swr r2, r1
    li r1, 1342
    add r1, r1, r6
    lwr r2, r1
    li r1, 1385
    add r1, r1, r6
    swr r2, r1
    li r1, 1343
    add r1, r1, r6
    lwr r2, r1
    li r1, 1386
    add r1, r1, r6
    swr r2, r1
    lui r1, 21
    add r1, r1, r6
    lwr r2, r1
    li r1, 1387
    add r1, r1, r6
    swr r2, r1
    li r1, 1345
    add r1, r1, r6
    lwr r2, r1
    li r1, 1388
    add r1, r1, r6
    swr r2, r1
    li r1, 1346
    add r1, r1, r6
    lwr r2, r1
    li r1, 1389
    add r1, r1, r6
    swr r2, r1
    li r1, 1347
    add r1, r1, r6
    lwr r2, r1
    li r1, 1390
    add r1, r1, r6
    swr r2, r1
    li r1, 1348
    add r1, r1, r6
    lwr r2, r1
    li r1, 1391
    add r1, r1, r6
    swr r2, r1
    li r1, 1349
    add r1, r1, r6
    lwr r2, r1
    li r1, 1392
    add r1, r1, r6
    swr r2, r1
    li r1, 1350
    add r1, r1, r6
    lwr r2, r1
    li r1, 1393
    add r1, r1, r6
    swr r2, r1
    li r1, 1351
    add r1, r1, r6
    lwr r2, r1
    li r1, 1394
    add r1, r1, r6
    swr r2, r1
    li r1, 1352
    add r1, r1, r6
    lwr r2, r1
    li r1, 1395
    add r1, r1, r6
    swr r2, r1
    li r1, 1353
    add r1, r1, r6
    lwr r2, r1
    li r1, 1396
    add r1, r1, r6
    swr r2, r1
    li r1, 1354
    add r1, r1, r6
    lwr r2, r1
    li r1, 1397
    add r1, r1, r6
    swr r2, r1
    li r1, 1355
    add r1, r1, r6
    lwr r2, r1
    li r1, 1398
    add r1, r1, r6
    swr r2, r1
    li r1, 1356
    add r1, r1, r6
    lwr r2, r1
    li r1, 1399
    add r1, r1, r6
    swr r2, r1
    li r1, 1357
    add r1, r1, r6
    lwr r2, r1
    li r1, 1400
    add r1, r1, r6
    swr r2, r1
    li r1, 1358
    add r1, r1, r6
    lwr r2, r1
    li r1, 1401
    add r1, r1, r6
    swr r2, r1
    li r1, 1359
    add r1, r1, r6
    lwr r2, r1
    li r1, 1402
    add r1, r1, r6
    swr r2, r1
    li r1, 1360
    add r1, r1, r6
    lwr r2, r1
    li r1, 1403
    add r1, r1, r6
    swr r2, r1
    li r1, 1361
    add r1, r1, r6
    lwr r2, r1
    li r1, 1404
    add r1, r1, r6
    swr r2, r1
    li r1, 1362
    add r1, r1, r6
    lwr r2, r1
    li r1, 1405
    add r1, r1, r6
    swr r2, r1
    li r1, 1363
    add r1, r1, r6
    lwr r2, r1
    li r1, 1406
    add r1, r1, r6
    swr r2, r1
    li r1, 1364
    add r1, r1, r6
    lwr r2, r1
    li r1, 1407
    add r1, r1, r6
    swr r2, r1
    li r1, 1365
    add r1, r1, r6
    lwr r2, r1
    lui r1, 22
    add r1, r1, r6
    swr r2, r1
    li r1, 1366
    add r1, r1, r6
    lwr r2, r1
    li r1, 1409
    add r1, r1, r6
    swr r2, r1
    li r1, 1367
    add r1, r1, r6
    lwr r2, r1
    li r1, 1410
    add r1, r1, r6
    swr r2, r1
    li r1, 1368
    add r1, r1, r6
    lwr r2, r1
    li r1, 1411
    add r1, r1, r6
    swr r2, r1
    li r1, 1369
    add r1, r1, r6
    lwr r2, r1
    li r1, 1412
    add r1, r1, r6
    swr r2, r1
    li r1, 1370
    add r1, r1, r6
    lwr r2, r1
    li r1, 1413
    add r1, r1, r6
    swr r2, r1
    li r1, 1371
    add r1, r1, r6
    lwr r2, r1
    li r1, 1414
    add r1, r1, r6
    swr r2, r1
    li r1, 1372
    add r1, r1, r6
    lwr r2, r1
    li r1, 1415
    add r1, r1, r6
    swr r2, r1
    li r1, 1373
    add r1, r1, r6
    lwr r2, r1
    li r1, 1416
    add r1, r1, r6
    swr r2, r1
    li r1, 1374
    add r1, r1, r6
    lwr r2, r1
    li r1, 1417
    add r1, r1, r6
    swr r2, r1
    li r1, 1375
    add r1, r1, r6
    lwr r2, r1
    li r1, 1418
    add r1, r1, r6
    swr r2, r1
    li r1, 260
    add r1, r1, r6
    lwr r2, r1
    li r1, 1419
    add r1, r1, r6
    swr r2, r1
    li r1, 259
    add r1, r1, r6
    lwr r2, r1
    li r1, 1420
    add r1, r1, r6
    swr r2, r1
    li r1, 596
    add r1, r1, r6
    lwr r2, r1
    li r1, 1421
    add r1, r1, r6
    swr r2, r1
    li r1, 598
    add r1, r1, r6
    lwr r2, r1
    li r1, 1422
    add r1, r1, r6
    swr r2, r1
    li r1, 600
    add r1, r1, r6
    lwr r2, r1
    li r1, 1423
    add r1, r1, r6
    swr r2, r1
    li r1, 602
    add r1, r1, r6
    lwr r2, r1
    li r1, 1424
    add r1, r1, r6
    swr r2, r1
    li r1, 604
    add r1, r1, r6
    lwr r2, r1
    li r1, 1425
    add r1, r1, r6
    swr r2, r1
    li r1, 608
    add r1, r1, r6
    lwr r2, r1
    li r1, 1426
    add r1, r1, r6
    swr r2, r1
    li r1, 610
    add r1, r1, r6
    lwr r2, r1
    li r1, 1427
    add r1, r1, r6
    swr r2, r1
    li r1, 612
    add r1, r1, r6
    lwr r2, r1
    li r1, 1428
    add r1, r1, r6
    swr r2, r1
    li r1, 614
    add r1, r1, r6
    lwr r2, r1
    li r1, 1429
    add r1, r1, r6
    swr r2, r1
    li r1, 616
    add r1, r1, r6
    lwr r2, r1
    li r1, 1430
    add r1, r1, r6
    swr r2, r1
    li r1, 618
    add r1, r1, r6
    lwr r2, r1
    li r1, 1431
    add r1, r1, r6
    swr r2, r1
    li r1, 620
    add r1, r1, r6
    lwr r2, r1
    li r1, 1432
    add r1, r1, r6
    swr r2, r1
    li r1, 622
    add r1, r1, r6
    lwr r2, r1
    li r1, 1433
    add r1, r1, r6
    swr r2, r1
    li r1, 624
    add r1, r1, r6
    lwr r2, r1
    li r1, 1434
    add r1, r1, r6
    swr r2, r1
    li r1, 626
    add r1, r1, r6
    lwr r2, r1
    li r1, 1435
    add r1, r1, r6
    swr r2, r1
    li r1, 630
    add r1, r1, r6
    lwr r2, r1
    li r1, 1436
    add r1, r1, r6
    swr r2, r1
    li r1, 632
    add r1, r1, r6
    lwr r2, r1
    li r1, 1437
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_110
_B_main_175:
    li r1, 1254
    add r1, r1, r6
    lwr r2, r1
    li r1, 1376
    add r1, r1, r6
    swr r2, r1
    li r1, 258
    add r1, r1, r6
    lwr r2, r1
    li r1, 1377
    add r1, r1, r6
    swr r2, r1
    li r1, 1255
    add r1, r1, r6
    lwr r2, r1
    li r1, 1378
    add r1, r1, r6
    swr r2, r1
    li r1, 504
    add r1, r1, r6
    lwr r2, r1
    li r1, 1379
    add r1, r1, r6
    swr r2, r1
    li r1, 506
    add r1, r1, r6
    lwr r2, r1
    li r1, 1380
    add r1, r1, r6
    swr r2, r1
    li r1, 508
    add r1, r1, r6
    lwr r2, r1
    li r1, 1381
    add r1, r1, r6
    swr r2, r1
    li r1, 510
    add r1, r1, r6
    lwr r2, r1
    li r1, 1382
    add r1, r1, r6
    swr r2, r1
    lui r1, 8
    add r1, r1, r6
    lwr r2, r1
    li r1, 1383
    add r1, r1, r6
    swr r2, r1
    li r1, 514
    add r1, r1, r6
    lwr r2, r1
    li r1, 1384
    add r1, r1, r6
    swr r2, r1
    li r1, 516
    add r1, r1, r6
    lwr r2, r1
    li r1, 1385
    add r1, r1, r6
    swr r2, r1
    li r1, 520
    add r1, r1, r6
    lwr r2, r1
    li r1, 1386
    add r1, r1, r6
    swr r2, r1
    li r1, 522
    add r1, r1, r6
    lwr r2, r1
    li r1, 1387
    add r1, r1, r6
    swr r2, r1
    li r1, 524
    add r1, r1, r6
    lwr r2, r1
    li r1, 1388
    add r1, r1, r6
    swr r2, r1
    li r1, 526
    add r1, r1, r6
    lwr r2, r1
    li r1, 1389
    add r1, r1, r6
    swr r2, r1
    li r1, 528
    add r1, r1, r6
    lwr r2, r1
    li r1, 1390
    add r1, r1, r6
    swr r2, r1
    li r1, 530
    add r1, r1, r6
    lwr r2, r1
    li r1, 1391
    add r1, r1, r6
    swr r2, r1
    li r1, 532
    add r1, r1, r6
    lwr r2, r1
    li r1, 1392
    add r1, r1, r6
    swr r2, r1
    li r1, 534
    add r1, r1, r6
    lwr r2, r1
    li r1, 1393
    add r1, r1, r6
    swr r2, r1
    li r1, 536
    add r1, r1, r6
    lwr r2, r1
    li r1, 1394
    add r1, r1, r6
    swr r2, r1
    li r1, 538
    add r1, r1, r6
    lwr r2, r1
    li r1, 1395
    add r1, r1, r6
    swr r2, r1
    li r1, 542
    add r1, r1, r6
    lwr r2, r1
    li r1, 1396
    add r1, r1, r6
    swr r2, r1
    li r1, 544
    add r1, r1, r6
    lwr r2, r1
    li r1, 1397
    add r1, r1, r6
    swr r2, r1
    li r1, 546
    add r1, r1, r6
    lwr r2, r1
    li r1, 1398
    add r1, r1, r6
    swr r2, r1
    li r1, 548
    add r1, r1, r6
    lwr r2, r1
    li r1, 1399
    add r1, r1, r6
    swr r2, r1
    li r1, 550
    add r1, r1, r6
    lwr r2, r1
    li r1, 1400
    add r1, r1, r6
    swr r2, r1
    li r1, 552
    add r1, r1, r6
    lwr r2, r1
    li r1, 1401
    add r1, r1, r6
    swr r2, r1
    li r1, 554
    add r1, r1, r6
    lwr r2, r1
    li r1, 1402
    add r1, r1, r6
    swr r2, r1
    li r1, 556
    add r1, r1, r6
    lwr r2, r1
    li r1, 1403
    add r1, r1, r6
    swr r2, r1
    li r1, 558
    add r1, r1, r6
    lwr r2, r1
    li r1, 1404
    add r1, r1, r6
    swr r2, r1
    li r1, 560
    add r1, r1, r6
    lwr r2, r1
    li r1, 1405
    add r1, r1, r6
    swr r2, r1
    li r1, 564
    add r1, r1, r6
    lwr r2, r1
    li r1, 1406
    add r1, r1, r6
    swr r2, r1
    li r1, 566
    add r1, r1, r6
    lwr r2, r1
    li r1, 1407
    add r1, r1, r6
    swr r2, r1
    li r1, 568
    add r1, r1, r6
    lwr r2, r1
    lui r1, 22
    add r1, r1, r6
    swr r2, r1
    li r1, 570
    add r1, r1, r6
    lwr r2, r1
    li r1, 1409
    add r1, r1, r6
    swr r2, r1
    li r1, 572
    add r1, r1, r6
    lwr r2, r1
    li r1, 1410
    add r1, r1, r6
    swr r2, r1
    li r1, 574
    add r1, r1, r6
    lwr r2, r1
    li r1, 1411
    add r1, r1, r6
    swr r2, r1
    lui r1, 9
    add r1, r1, r6
    lwr r2, r1
    li r1, 1412
    add r1, r1, r6
    swr r2, r1
    li r1, 578
    add r1, r1, r6
    lwr r2, r1
    li r1, 1413
    add r1, r1, r6
    swr r2, r1
    li r1, 580
    add r1, r1, r6
    lwr r2, r1
    li r1, 1414
    add r1, r1, r6
    swr r2, r1
    li r1, 582
    add r1, r1, r6
    lwr r2, r1
    li r1, 1415
    add r1, r1, r6
    swr r2, r1
    li r1, 586
    add r1, r1, r6
    lwr r2, r1
    li r1, 1416
    add r1, r1, r6
    swr r2, r1
    li r1, 588
    add r1, r1, r6
    lwr r2, r1
    li r1, 1417
    add r1, r1, r6
    swr r2, r1
    li r1, 590
    add r1, r1, r6
    lwr r2, r1
    li r1, 1418
    add r1, r1, r6
    swr r2, r1
    li r1, 592
    add r1, r1, r6
    lwr r2, r1
    li r1, 1419
    add r1, r1, r6
    swr r2, r1
    li r1, 594
    add r1, r1, r6
    lwr r2, r1
    li r1, 1420
    add r1, r1, r6
    swr r2, r1
    li r1, 257
    add r1, r1, r6
    lwr r2, r1
    li r1, 1421
    add r1, r1, r6
    swr r2, r1
    lui r1, 4
    add r1, r1, r6
    lwr r2, r1
    li r1, 1422
    add r1, r1, r6
    swr r2, r1
    li r1, 1256
    add r1, r1, r6
    lwr r2, r1
    li r1, 1423
    add r1, r1, r6
    swr r2, r1
    li r1, 1257
    add r1, r1, r6
    lwr r2, r1
    li r1, 1424
    add r1, r1, r6
    swr r2, r1
    li r1, 1258
    add r1, r1, r6
    lwr r2, r1
    li r1, 1425
    add r1, r1, r6
    swr r2, r1
    li r1, 1259
    add r1, r1, r6
    lwr r2, r1
    li r1, 1426
    add r1, r1, r6
    swr r2, r1
    li r1, 1260
    add r1, r1, r6
    lwr r2, r1
    li r1, 1427
    add r1, r1, r6
    swr r2, r1
    li r1, 1261
    add r1, r1, r6
    lwr r2, r1
    li r1, 1428
    add r1, r1, r6
    swr r2, r1
    li r1, 1262
    add r1, r1, r6
    lwr r2, r1
    li r1, 1429
    add r1, r1, r6
    swr r2, r1
    li r1, 1263
    add r1, r1, r6
    lwr r2, r1
    li r1, 1430
    add r1, r1, r6
    swr r2, r1
    li r1, 1264
    add r1, r1, r6
    lwr r2, r1
    li r1, 1431
    add r1, r1, r6
    swr r2, r1
    li r1, 1265
    add r1, r1, r6
    lwr r2, r1
    li r1, 1432
    add r1, r1, r6
    swr r2, r1
    li r1, 1266
    add r1, r1, r6
    lwr r2, r1
    li r1, 1433
    add r1, r1, r6
    swr r2, r1
    li r1, 1267
    add r1, r1, r6
    lwr r2, r1
    li r1, 1434
    add r1, r1, r6
    swr r2, r1
    li r1, 1268
    add r1, r1, r6
    lwr r2, r1
    li r1, 1435
    add r1, r1, r6
    swr r2, r1
    li r1, 240
    add r1, r1, r6
    lwr r2, r1
    li r1, 1436
    add r1, r1, r6
    swr r2, r1
    li r1, 239
    add r1, r1, r6
    lwr r2, r1
    li r1, 1437
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_110
_B_main_176:
    li r1, 1376
    add r1, r1, r6
    lwr r2, r1
    li r1, 1438
    add r1, r1, r6
    swr r2, r1
    li r1, 1377
    add r1, r1, r6
    lwr r2, r1
    li r1, 1439
    add r1, r1, r6
    swr r2, r1
    li r1, 325
    add r1, r1, r6
    lwr r2, r1
    li r1, 1440
    add r1, r1, r6
    swr r2, r1
    li r1, 1378
    add r1, r1, r6
    lwr r2, r1
    li r1, 1441
    add r1, r1, r6
    swr r2, r1
    li r1, 1379
    add r1, r1, r6
    lwr r2, r1
    li r1, 1442
    add r1, r1, r6
    swr r2, r1
    li r1, 1380
    add r1, r1, r6
    lwr r2, r1
    li r1, 1443
    add r1, r1, r6
    swr r2, r1
    li r1, 1381
    add r1, r1, r6
    lwr r2, r1
    li r1, 1444
    add r1, r1, r6
    swr r2, r1
    li r1, 1382
    add r1, r1, r6
    lwr r2, r1
    li r1, 1445
    add r1, r1, r6
    swr r2, r1
    li r1, 1383
    add r1, r1, r6
    lwr r2, r1
    li r1, 1446
    add r1, r1, r6
    swr r2, r1
    li r1, 1384
    add r1, r1, r6
    lwr r2, r1
    li r1, 1447
    add r1, r1, r6
    swr r2, r1
    li r1, 1385
    add r1, r1, r6
    lwr r2, r1
    li r1, 1448
    add r1, r1, r6
    swr r2, r1
    li r1, 1386
    add r1, r1, r6
    lwr r2, r1
    li r1, 1449
    add r1, r1, r6
    swr r2, r1
    li r1, 1387
    add r1, r1, r6
    lwr r2, r1
    li r1, 1450
    add r1, r1, r6
    swr r2, r1
    li r1, 1388
    add r1, r1, r6
    lwr r2, r1
    li r1, 1451
    add r1, r1, r6
    swr r2, r1
    li r1, 1389
    add r1, r1, r6
    lwr r2, r1
    li r1, 1452
    add r1, r1, r6
    swr r2, r1
    li r1, 1390
    add r1, r1, r6
    lwr r2, r1
    li r1, 1453
    add r1, r1, r6
    swr r2, r1
    li r1, 1391
    add r1, r1, r6
    lwr r2, r1
    li r1, 1454
    add r1, r1, r6
    swr r2, r1
    li r1, 1392
    add r1, r1, r6
    lwr r2, r1
    li r1, 1455
    add r1, r1, r6
    swr r2, r1
    li r1, 1393
    add r1, r1, r6
    lwr r2, r1
    li r1, 1456
    add r1, r1, r6
    swr r2, r1
    li r1, 1394
    add r1, r1, r6
    lwr r2, r1
    li r1, 1457
    add r1, r1, r6
    swr r2, r1
    li r1, 1395
    add r1, r1, r6
    lwr r2, r1
    li r1, 1458
    add r1, r1, r6
    swr r2, r1
    li r1, 1396
    add r1, r1, r6
    lwr r2, r1
    li r1, 1459
    add r1, r1, r6
    swr r2, r1
    li r1, 1397
    add r1, r1, r6
    lwr r2, r1
    li r1, 1460
    add r1, r1, r6
    swr r2, r1
    li r1, 1398
    add r1, r1, r6
    lwr r2, r1
    li r1, 1461
    add r1, r1, r6
    swr r2, r1
    li r1, 1399
    add r1, r1, r6
    lwr r2, r1
    li r1, 1462
    add r1, r1, r6
    swr r2, r1
    li r1, 1400
    add r1, r1, r6
    lwr r2, r1
    li r1, 1463
    add r1, r1, r6
    swr r2, r1
    li r1, 1401
    add r1, r1, r6
    lwr r2, r1
    li r1, 1464
    add r1, r1, r6
    swr r2, r1
    li r1, 1402
    add r1, r1, r6
    lwr r2, r1
    li r1, 1465
    add r1, r1, r6
    swr r2, r1
    li r1, 1403
    add r1, r1, r6
    lwr r2, r1
    li r1, 1466
    add r1, r1, r6
    swr r2, r1
    li r1, 1404
    add r1, r1, r6
    lwr r2, r1
    li r1, 1467
    add r1, r1, r6
    swr r2, r1
    li r1, 1405
    add r1, r1, r6
    lwr r2, r1
    li r1, 1468
    add r1, r1, r6
    swr r2, r1
    li r1, 1406
    add r1, r1, r6
    lwr r2, r1
    li r1, 1469
    add r1, r1, r6
    swr r2, r1
    li r1, 1407
    add r1, r1, r6
    lwr r2, r1
    li r1, 1470
    add r1, r1, r6
    swr r2, r1
    lui r1, 22
    add r1, r1, r6
    lwr r2, r1
    li r1, 1471
    add r1, r1, r6
    swr r2, r1
    li r1, 1409
    add r1, r1, r6
    lwr r2, r1
    lui r1, 23
    add r1, r1, r6
    swr r2, r1
    li r1, 1410
    add r1, r1, r6
    lwr r2, r1
    li r1, 1473
    add r1, r1, r6
    swr r2, r1
    li r1, 1411
    add r1, r1, r6
    lwr r2, r1
    li r1, 1474
    add r1, r1, r6
    swr r2, r1
    li r1, 1412
    add r1, r1, r6
    lwr r2, r1
    li r1, 1475
    add r1, r1, r6
    swr r2, r1
    li r1, 1413
    add r1, r1, r6
    lwr r2, r1
    li r1, 1476
    add r1, r1, r6
    swr r2, r1
    li r1, 1414
    add r1, r1, r6
    lwr r2, r1
    li r1, 1477
    add r1, r1, r6
    swr r2, r1
    li r1, 1415
    add r1, r1, r6
    lwr r2, r1
    li r1, 1478
    add r1, r1, r6
    swr r2, r1
    li r1, 1416
    add r1, r1, r6
    lwr r2, r1
    li r1, 1479
    add r1, r1, r6
    swr r2, r1
    li r1, 1417
    add r1, r1, r6
    lwr r2, r1
    li r1, 1480
    add r1, r1, r6
    swr r2, r1
    li r1, 1418
    add r1, r1, r6
    lwr r2, r1
    li r1, 1481
    add r1, r1, r6
    swr r2, r1
    li r1, 1419
    add r1, r1, r6
    lwr r2, r1
    li r1, 1482
    add r1, r1, r6
    swr r2, r1
    li r1, 1420
    add r1, r1, r6
    lwr r2, r1
    li r1, 1483
    add r1, r1, r6
    swr r2, r1
    li r1, 1421
    add r1, r1, r6
    lwr r2, r1
    li r1, 1484
    add r1, r1, r6
    swr r2, r1
    li r1, 1422
    add r1, r1, r6
    lwr r2, r1
    li r1, 1485
    add r1, r1, r6
    swr r2, r1
    li r1, 1423
    add r1, r1, r6
    lwr r2, r1
    li r1, 1486
    add r1, r1, r6
    swr r2, r1
    li r1, 1424
    add r1, r1, r6
    lwr r2, r1
    li r1, 1487
    add r1, r1, r6
    swr r2, r1
    li r1, 1425
    add r1, r1, r6
    lwr r2, r1
    li r1, 1488
    add r1, r1, r6
    swr r2, r1
    li r1, 1426
    add r1, r1, r6
    lwr r2, r1
    li r1, 1489
    add r1, r1, r6
    swr r2, r1
    li r1, 1427
    add r1, r1, r6
    lwr r2, r1
    li r1, 1490
    add r1, r1, r6
    swr r2, r1
    li r1, 1428
    add r1, r1, r6
    lwr r2, r1
    li r1, 1491
    add r1, r1, r6
    swr r2, r1
    li r1, 1429
    add r1, r1, r6
    lwr r2, r1
    li r1, 1492
    add r1, r1, r6
    swr r2, r1
    li r1, 1430
    add r1, r1, r6
    lwr r2, r1
    li r1, 1493
    add r1, r1, r6
    swr r2, r1
    li r1, 1431
    add r1, r1, r6
    lwr r2, r1
    li r1, 1494
    add r1, r1, r6
    swr r2, r1
    li r1, 1432
    add r1, r1, r6
    lwr r2, r1
    li r1, 1495
    add r1, r1, r6
    swr r2, r1
    li r1, 1433
    add r1, r1, r6
    lwr r2, r1
    li r1, 1496
    add r1, r1, r6
    swr r2, r1
    li r1, 1434
    add r1, r1, r6
    lwr r2, r1
    li r1, 1497
    add r1, r1, r6
    swr r2, r1
    li r1, 1435
    add r1, r1, r6
    lwr r2, r1
    li r1, 1498
    add r1, r1, r6
    swr r2, r1
    li r1, 1436
    add r1, r1, r6
    lwr r2, r1
    li r1, 1499
    add r1, r1, r6
    swr r2, r1
    li r1, 1437
    add r1, r1, r6
    lwr r2, r1
    li r1, 1500
    add r1, r1, r6
    swr r2, r1
    li r1, 238
    add r1, r1, r6
    lwr r2, r1
    li r1, 1501
    add r1, r1, r6
    swr r2, r1
    li r1, 237
    add r1, r1, r6
    lwr r2, r1
    li r1, 1502
    add r1, r1, r6
    swr r2, r1
    li r1, 638
    add r1, r1, r6
    lwr r2, r1
    li r1, 1503
    add r1, r1, r6
    swr r2, r1
    lui r1, 10
    add r1, r1, r6
    lwr r2, r1
    li r1, 1504
    add r1, r1, r6
    swr r2, r1
    li r1, 642
    add r1, r1, r6
    lwr r2, r1
    li r1, 1505
    add r1, r1, r6
    swr r2, r1
    li r1, 644
    add r1, r1, r6
    lwr r2, r1
    li r1, 1506
    add r1, r1, r6
    swr r2, r1
    li r1, 646
    add r1, r1, r6
    lwr r2, r1
    li r1, 1507
    add r1, r1, r6
    swr r2, r1
    li r1, 648
    add r1, r1, r6
    lwr r2, r1
    li r1, 1508
    add r1, r1, r6
    swr r2, r1
    li r1, 652
    add r1, r1, r6
    lwr r2, r1
    li r1, 1509
    add r1, r1, r6
    swr r2, r1
    li r1, 654
    add r1, r1, r6
    lwr r2, r1
    li r1, 1510
    add r1, r1, r6
    swr r2, r1
    li r1, 656
    add r1, r1, r6
    lwr r2, r1
    li r1, 1511
    add r1, r1, r6
    swr r2, r1
    li r1, 658
    add r1, r1, r6
    lwr r2, r1
    li r1, 1512
    add r1, r1, r6
    swr r2, r1
    li r1, 660
    add r1, r1, r6
    lwr r2, r1
    li r1, 1513
    add r1, r1, r6
    swr r2, r1
    li r1, 662
    add r1, r1, r6
    lwr r2, r1
    li r1, 1514
    add r1, r1, r6
    swr r2, r1
    li r1, 664
    add r1, r1, r6
    lwr r2, r1
    li r1, 1515
    add r1, r1, r6
    swr r2, r1
    li r1, 666
    add r1, r1, r6
    lwr r2, r1
    li r1, 1516
    add r1, r1, r6
    swr r2, r1
    li r1, 668
    add r1, r1, r6
    lwr r2, r1
    li r1, 1517
    add r1, r1, r6
    swr r2, r1
    li r1, 670
    add r1, r1, r6
    lwr r2, r1
    li r1, 1518
    add r1, r1, r6
    swr r2, r1
    li r1, 674
    add r1, r1, r6
    lwr r2, r1
    li r1, 1519
    add r1, r1, r6
    swr r2, r1
    li r1, 676
    add r1, r1, r6
    lwr r2, r1
    li r1, 1520
    add r1, r1, r6
    swr r2, r1
    li r1, 678
    add r1, r1, r6
    lwr r2, r1
    li r1, 1521
    add r1, r1, r6
    swr r2, r1
    li r1, 680
    add r1, r1, r6
    lwr r2, r1
    li r1, 1522
    add r1, r1, r6
    swr r2, r1
    li r1, 682
    add r1, r1, r6
    lwr r2, r1
    li r1, 1523
    add r1, r1, r6
    swr r2, r1
    li r1, 684
    add r1, r1, r6
    lwr r2, r1
    li r1, 1524
    add r1, r1, r6
    swr r2, r1
    li r1, 686
    add r1, r1, r6
    lwr r2, r1
    li r1, 1525
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_111
_B_main_177:
    li r1, 1232
    add r1, r1, r6
    lwr r2, r1
    li r1, 1438
    add r1, r1, r6
    swr r2, r1
    li r1, 236
    add r1, r1, r6
    lwr r2, r1
    li r1, 1439
    add r1, r1, r6
    swr r2, r1
    li r1, 1233
    add r1, r1, r6
    lwr r2, r1
    li r1, 1440
    add r1, r1, r6
    swr r2, r1
    li r1, 1234
    add r1, r1, r6
    lwr r2, r1
    li r1, 1441
    add r1, r1, r6
    swr r2, r1
    li r1, 504
    add r1, r1, r6
    lwr r2, r1
    li r1, 1442
    add r1, r1, r6
    swr r2, r1
    li r1, 506
    add r1, r1, r6
    lwr r2, r1
    li r1, 1443
    add r1, r1, r6
    swr r2, r1
    li r1, 508
    add r1, r1, r6
    lwr r2, r1
    li r1, 1444
    add r1, r1, r6
    swr r2, r1
    li r1, 510
    add r1, r1, r6
    lwr r2, r1
    li r1, 1445
    add r1, r1, r6
    swr r2, r1
    lui r1, 8
    add r1, r1, r6
    lwr r2, r1
    li r1, 1446
    add r1, r1, r6
    swr r2, r1
    li r1, 514
    add r1, r1, r6
    lwr r2, r1
    li r1, 1447
    add r1, r1, r6
    swr r2, r1
    li r1, 516
    add r1, r1, r6
    lwr r2, r1
    li r1, 1448
    add r1, r1, r6
    swr r2, r1
    li r1, 520
    add r1, r1, r6
    lwr r2, r1
    li r1, 1449
    add r1, r1, r6
    swr r2, r1
    li r1, 522
    add r1, r1, r6
    lwr r2, r1
    li r1, 1450
    add r1, r1, r6
    swr r2, r1
    li r1, 524
    add r1, r1, r6
    lwr r2, r1
    li r1, 1451
    add r1, r1, r6
    swr r2, r1
    li r1, 526
    add r1, r1, r6
    lwr r2, r1
    li r1, 1452
    add r1, r1, r6
    swr r2, r1
    li r1, 528
    add r1, r1, r6
    lwr r2, r1
    li r1, 1453
    add r1, r1, r6
    swr r2, r1
    li r1, 530
    add r1, r1, r6
    lwr r2, r1
    li r1, 1454
    add r1, r1, r6
    swr r2, r1
    li r1, 532
    add r1, r1, r6
    lwr r2, r1
    li r1, 1455
    add r1, r1, r6
    swr r2, r1
    li r1, 534
    add r1, r1, r6
    lwr r2, r1
    li r1, 1456
    add r1, r1, r6
    swr r2, r1
    li r1, 536
    add r1, r1, r6
    lwr r2, r1
    li r1, 1457
    add r1, r1, r6
    swr r2, r1
    li r1, 538
    add r1, r1, r6
    lwr r2, r1
    li r1, 1458
    add r1, r1, r6
    swr r2, r1
    li r1, 542
    add r1, r1, r6
    lwr r2, r1
    li r1, 1459
    add r1, r1, r6
    swr r2, r1
    li r1, 544
    add r1, r1, r6
    lwr r2, r1
    li r1, 1460
    add r1, r1, r6
    swr r2, r1
    li r1, 546
    add r1, r1, r6
    lwr r2, r1
    li r1, 1461
    add r1, r1, r6
    swr r2, r1
    li r1, 548
    add r1, r1, r6
    lwr r2, r1
    li r1, 1462
    add r1, r1, r6
    swr r2, r1
    li r1, 550
    add r1, r1, r6
    lwr r2, r1
    li r1, 1463
    add r1, r1, r6
    swr r2, r1
    li r1, 552
    add r1, r1, r6
    lwr r2, r1
    li r1, 1464
    add r1, r1, r6
    swr r2, r1
    li r1, 554
    add r1, r1, r6
    lwr r2, r1
    li r1, 1465
    add r1, r1, r6
    swr r2, r1
    li r1, 556
    add r1, r1, r6
    lwr r2, r1
    li r1, 1466
    add r1, r1, r6
    swr r2, r1
    li r1, 558
    add r1, r1, r6
    lwr r2, r1
    li r1, 1467
    add r1, r1, r6
    swr r2, r1
    li r1, 560
    add r1, r1, r6
    lwr r2, r1
    li r1, 1468
    add r1, r1, r6
    swr r2, r1
    li r1, 564
    add r1, r1, r6
    lwr r2, r1
    li r1, 1469
    add r1, r1, r6
    swr r2, r1
    li r1, 566
    add r1, r1, r6
    lwr r2, r1
    li r1, 1470
    add r1, r1, r6
    swr r2, r1
    li r1, 568
    add r1, r1, r6
    lwr r2, r1
    li r1, 1471
    add r1, r1, r6
    swr r2, r1
    li r1, 570
    add r1, r1, r6
    lwr r2, r1
    lui r1, 23
    add r1, r1, r6
    swr r2, r1
    li r1, 572
    add r1, r1, r6
    lwr r2, r1
    li r1, 1473
    add r1, r1, r6
    swr r2, r1
    li r1, 574
    add r1, r1, r6
    lwr r2, r1
    li r1, 1474
    add r1, r1, r6
    swr r2, r1
    lui r1, 9
    add r1, r1, r6
    lwr r2, r1
    li r1, 1475
    add r1, r1, r6
    swr r2, r1
    li r1, 578
    add r1, r1, r6
    lwr r2, r1
    li r1, 1476
    add r1, r1, r6
    swr r2, r1
    li r1, 580
    add r1, r1, r6
    lwr r2, r1
    li r1, 1477
    add r1, r1, r6
    swr r2, r1
    li r1, 582
    add r1, r1, r6
    lwr r2, r1
    li r1, 1478
    add r1, r1, r6
    swr r2, r1
    li r1, 586
    add r1, r1, r6
    lwr r2, r1
    li r1, 1479
    add r1, r1, r6
    swr r2, r1
    li r1, 588
    add r1, r1, r6
    lwr r2, r1
    li r1, 1480
    add r1, r1, r6
    swr r2, r1
    li r1, 590
    add r1, r1, r6
    lwr r2, r1
    li r1, 1481
    add r1, r1, r6
    swr r2, r1
    li r1, 592
    add r1, r1, r6
    lwr r2, r1
    li r1, 1482
    add r1, r1, r6
    swr r2, r1
    li r1, 594
    add r1, r1, r6
    lwr r2, r1
    li r1, 1483
    add r1, r1, r6
    swr r2, r1
    li r1, 596
    add r1, r1, r6
    lwr r2, r1
    li r1, 1484
    add r1, r1, r6
    swr r2, r1
    li r1, 598
    add r1, r1, r6
    lwr r2, r1
    li r1, 1485
    add r1, r1, r6
    swr r2, r1
    li r1, 600
    add r1, r1, r6
    lwr r2, r1
    li r1, 1486
    add r1, r1, r6
    swr r2, r1
    li r1, 602
    add r1, r1, r6
    lwr r2, r1
    li r1, 1487
    add r1, r1, r6
    swr r2, r1
    li r1, 604
    add r1, r1, r6
    lwr r2, r1
    li r1, 1488
    add r1, r1, r6
    swr r2, r1
    li r1, 608
    add r1, r1, r6
    lwr r2, r1
    li r1, 1489
    add r1, r1, r6
    swr r2, r1
    li r1, 610
    add r1, r1, r6
    lwr r2, r1
    li r1, 1490
    add r1, r1, r6
    swr r2, r1
    li r1, 612
    add r1, r1, r6
    lwr r2, r1
    li r1, 1491
    add r1, r1, r6
    swr r2, r1
    li r1, 614
    add r1, r1, r6
    lwr r2, r1
    li r1, 1492
    add r1, r1, r6
    swr r2, r1
    li r1, 616
    add r1, r1, r6
    lwr r2, r1
    li r1, 1493
    add r1, r1, r6
    swr r2, r1
    li r1, 618
    add r1, r1, r6
    lwr r2, r1
    li r1, 1494
    add r1, r1, r6
    swr r2, r1
    li r1, 620
    add r1, r1, r6
    lwr r2, r1
    li r1, 1495
    add r1, r1, r6
    swr r2, r1
    li r1, 622
    add r1, r1, r6
    lwr r2, r1
    li r1, 1496
    add r1, r1, r6
    swr r2, r1
    li r1, 624
    add r1, r1, r6
    lwr r2, r1
    li r1, 1497
    add r1, r1, r6
    swr r2, r1
    li r1, 626
    add r1, r1, r6
    lwr r2, r1
    li r1, 1498
    add r1, r1, r6
    swr r2, r1
    li r1, 630
    add r1, r1, r6
    lwr r2, r1
    li r1, 1499
    add r1, r1, r6
    swr r2, r1
    li r1, 632
    add r1, r1, r6
    lwr r2, r1
    li r1, 1500
    add r1, r1, r6
    swr r2, r1
    li r1, 634
    add r1, r1, r6
    lwr r2, r1
    li r1, 1501
    add r1, r1, r6
    swr r2, r1
    li r1, 636
    add r1, r1, r6
    lwr r2, r1
    li r1, 1502
    add r1, r1, r6
    swr r2, r1
    li r1, 235
    add r1, r1, r6
    lwr r2, r1
    li r1, 1503
    add r1, r1, r6
    swr r2, r1
    li r1, 234
    add r1, r1, r6
    lwr r2, r1
    li r1, 1504
    add r1, r1, r6
    swr r2, r1
    li r1, 1235
    add r1, r1, r6
    lwr r2, r1
    li r1, 1505
    add r1, r1, r6
    swr r2, r1
    li r1, 1236
    add r1, r1, r6
    lwr r2, r1
    li r1, 1506
    add r1, r1, r6
    swr r2, r1
    li r1, 1237
    add r1, r1, r6
    lwr r2, r1
    li r1, 1507
    add r1, r1, r6
    swr r2, r1
    li r1, 1238
    add r1, r1, r6
    lwr r2, r1
    li r1, 1508
    add r1, r1, r6
    swr r2, r1
    li r1, 1239
    add r1, r1, r6
    lwr r2, r1
    li r1, 1509
    add r1, r1, r6
    swr r2, r1
    li r1, 1240
    add r1, r1, r6
    lwr r2, r1
    li r1, 1510
    add r1, r1, r6
    swr r2, r1
    li r1, 1241
    add r1, r1, r6
    lwr r2, r1
    li r1, 1511
    add r1, r1, r6
    swr r2, r1
    li r1, 1242
    add r1, r1, r6
    lwr r2, r1
    li r1, 1512
    add r1, r1, r6
    swr r2, r1
    li r1, 1243
    add r1, r1, r6
    lwr r2, r1
    li r1, 1513
    add r1, r1, r6
    swr r2, r1
    li r1, 1244
    add r1, r1, r6
    lwr r2, r1
    li r1, 1514
    add r1, r1, r6
    swr r2, r1
    li r1, 1245
    add r1, r1, r6
    lwr r2, r1
    li r1, 1515
    add r1, r1, r6
    swr r2, r1
    li r1, 1246
    add r1, r1, r6
    lwr r2, r1
    li r1, 1516
    add r1, r1, r6
    swr r2, r1
    li r1, 1247
    add r1, r1, r6
    lwr r2, r1
    li r1, 1517
    add r1, r1, r6
    swr r2, r1
    li r1, 1248
    add r1, r1, r6
    lwr r2, r1
    li r1, 1518
    add r1, r1, r6
    swr r2, r1
    li r1, 1249
    add r1, r1, r6
    lwr r2, r1
    li r1, 1519
    add r1, r1, r6
    swr r2, r1
    li r1, 1250
    add r1, r1, r6
    lwr r2, r1
    li r1, 1520
    add r1, r1, r6
    swr r2, r1
    li r1, 1251
    add r1, r1, r6
    lwr r2, r1
    li r1, 1521
    add r1, r1, r6
    swr r2, r1
    li r1, 1252
    add r1, r1, r6
    lwr r2, r1
    li r1, 1522
    add r1, r1, r6
    swr r2, r1
    li r1, 1253
    add r1, r1, r6
    lwr r2, r1
    li r1, 1523
    add r1, r1, r6
    swr r2, r1
    li r1, 211
    add r1, r1, r6
    lwr r2, r1
    li r1, 1524
    add r1, r1, r6
    swr r2, r1
    li r1, 210
    add r1, r1, r6
    lwr r2, r1
    li r1, 1525
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_111
_B_main_178:
    li r1, 1438
    add r1, r1, r6
    lwr r2, r1
    li r1, 1526
    add r1, r1, r6
    swr r2, r1
    li r1, 1439
    add r1, r1, r6
    lwr r2, r1
    li r1, 1527
    add r1, r1, r6
    swr r2, r1
    li r1, 1440
    add r1, r1, r6
    lwr r2, r1
    li r1, 1528
    add r1, r1, r6
    swr r2, r1
    li r1, 1441
    add r1, r1, r6
    lwr r2, r1
    li r1, 1529
    add r1, r1, r6
    swr r2, r1
    li r1, 329
    add r1, r1, r6
    lwr r2, r1
    li r1, 1530
    add r1, r1, r6
    swr r2, r1
    li r1, 331
    add r1, r1, r6
    lwr r2, r1
    li r1, 1531
    add r1, r1, r6
    swr r2, r1
    li r1, 333
    add r1, r1, r6
    lwr r2, r1
    li r1, 1532
    add r1, r1, r6
    swr r2, r1
    li r1, 335
    add r1, r1, r6
    lwr r2, r1
    li r1, 1533
    add r1, r1, r6
    swr r2, r1
    li r1, 337
    add r1, r1, r6
    lwr r2, r1
    li r1, 1534
    add r1, r1, r6
    swr r2, r1
    li r1, 339
    add r1, r1, r6
    lwr r2, r1
    li r1, 1535
    add r1, r1, r6
    swr r2, r1
    li r1, 341
    add r1, r1, r6
    lwr r2, r1
    lui r1, 24
    add r1, r1, r6
    swr r2, r1
    li r1, 343
    add r1, r1, r6
    lwr r2, r1
    li r1, 1537
    add r1, r1, r6
    swr r2, r1
    li r1, 345
    add r1, r1, r6
    lwr r2, r1
    li r1, 1538
    add r1, r1, r6
    swr r2, r1
    li r1, 347
    add r1, r1, r6
    lwr r2, r1
    li r1, 1539
    add r1, r1, r6
    swr r2, r1
    li r1, 1442
    add r1, r1, r6
    lwr r2, r1
    li r1, 1540
    add r1, r1, r6
    swr r2, r1
    li r1, 1443
    add r1, r1, r6
    lwr r2, r1
    li r1, 1541
    add r1, r1, r6
    swr r2, r1
    li r1, 1444
    add r1, r1, r6
    lwr r2, r1
    li r1, 1542
    add r1, r1, r6
    swr r2, r1
    li r1, 1445
    add r1, r1, r6
    lwr r2, r1
    li r1, 1543
    add r1, r1, r6
    swr r2, r1
    li r1, 1446
    add r1, r1, r6
    lwr r2, r1
    li r1, 1544
    add r1, r1, r6
    swr r2, r1
    li r1, 1447
    add r1, r1, r6
    lwr r2, r1
    li r1, 1545
    add r1, r1, r6
    swr r2, r1
    li r1, 1448
    add r1, r1, r6
    lwr r2, r1
    li r1, 1546
    add r1, r1, r6
    swr r2, r1
    li r1, 1449
    add r1, r1, r6
    lwr r2, r1
    li r1, 1547
    add r1, r1, r6
    swr r2, r1
    li r1, 1450
    add r1, r1, r6
    lwr r2, r1
    li r1, 1548
    add r1, r1, r6
    swr r2, r1
    li r1, 1451
    add r1, r1, r6
    lwr r2, r1
    li r1, 1549
    add r1, r1, r6
    swr r2, r1
    li r1, 1452
    add r1, r1, r6
    lwr r2, r1
    li r1, 1550
    add r1, r1, r6
    swr r2, r1
    li r1, 1453
    add r1, r1, r6
    lwr r2, r1
    li r1, 1551
    add r1, r1, r6
    swr r2, r1
    li r1, 1454
    add r1, r1, r6
    lwr r2, r1
    li r1, 1552
    add r1, r1, r6
    swr r2, r1
    li r1, 1455
    add r1, r1, r6
    lwr r2, r1
    li r1, 1553
    add r1, r1, r6
    swr r2, r1
    li r1, 1456
    add r1, r1, r6
    lwr r2, r1
    li r1, 1554
    add r1, r1, r6
    swr r2, r1
    li r1, 1457
    add r1, r1, r6
    lwr r2, r1
    li r1, 1555
    add r1, r1, r6
    swr r2, r1
    li r1, 1458
    add r1, r1, r6
    lwr r2, r1
    li r1, 1556
    add r1, r1, r6
    swr r2, r1
    li r1, 1459
    add r1, r1, r6
    lwr r2, r1
    li r1, 1557
    add r1, r1, r6
    swr r2, r1
    li r1, 1460
    add r1, r1, r6
    lwr r2, r1
    li r1, 1558
    add r1, r1, r6
    swr r2, r1
    li r1, 1461
    add r1, r1, r6
    lwr r2, r1
    li r1, 1559
    add r1, r1, r6
    swr r2, r1
    li r1, 1462
    add r1, r1, r6
    lwr r2, r1
    li r1, 1560
    add r1, r1, r6
    swr r2, r1
    li r1, 1463
    add r1, r1, r6
    lwr r2, r1
    li r1, 1561
    add r1, r1, r6
    swr r2, r1
    li r1, 1464
    add r1, r1, r6
    lwr r2, r1
    li r1, 1562
    add r1, r1, r6
    swr r2, r1
    li r1, 1465
    add r1, r1, r6
    lwr r2, r1
    li r1, 1563
    add r1, r1, r6
    swr r2, r1
    li r1, 1466
    add r1, r1, r6
    lwr r2, r1
    li r1, 1564
    add r1, r1, r6
    swr r2, r1
    li r1, 1467
    add r1, r1, r6
    lwr r2, r1
    li r1, 1565
    add r1, r1, r6
    swr r2, r1
    li r1, 1468
    add r1, r1, r6
    lwr r2, r1
    li r1, 1566
    add r1, r1, r6
    swr r2, r1
    li r1, 1469
    add r1, r1, r6
    lwr r2, r1
    li r1, 1567
    add r1, r1, r6
    swr r2, r1
    li r1, 1470
    add r1, r1, r6
    lwr r2, r1
    li r1, 1568
    add r1, r1, r6
    swr r2, r1
    li r1, 1471
    add r1, r1, r6
    lwr r2, r1
    li r1, 1569
    add r1, r1, r6
    swr r2, r1
    lui r1, 23
    add r1, r1, r6
    lwr r2, r1
    li r1, 1570
    add r1, r1, r6
    swr r2, r1
    li r1, 1473
    add r1, r1, r6
    lwr r2, r1
    li r1, 1571
    add r1, r1, r6
    swr r2, r1
    li r1, 1474
    add r1, r1, r6
    lwr r2, r1
    li r1, 1572
    add r1, r1, r6
    swr r2, r1
    li r1, 1475
    add r1, r1, r6
    lwr r2, r1
    li r1, 1573
    add r1, r1, r6
    swr r2, r1
    li r1, 1476
    add r1, r1, r6
    lwr r2, r1
    li r1, 1574
    add r1, r1, r6
    swr r2, r1
    li r1, 1477
    add r1, r1, r6
    lwr r2, r1
    li r1, 1575
    add r1, r1, r6
    swr r2, r1
    li r1, 1478
    add r1, r1, r6
    lwr r2, r1
    li r1, 1576
    add r1, r1, r6
    swr r2, r1
    li r1, 1479
    add r1, r1, r6
    lwr r2, r1
    li r1, 1577
    add r1, r1, r6
    swr r2, r1
    li r1, 1480
    add r1, r1, r6
    lwr r2, r1
    li r1, 1578
    add r1, r1, r6
    swr r2, r1
    li r1, 1481
    add r1, r1, r6
    lwr r2, r1
    li r1, 1579
    add r1, r1, r6
    swr r2, r1
    li r1, 1482
    add r1, r1, r6
    lwr r2, r1
    li r1, 1580
    add r1, r1, r6
    swr r2, r1
    li r1, 1483
    add r1, r1, r6
    lwr r2, r1
    li r1, 1581
    add r1, r1, r6
    swr r2, r1
    li r1, 1484
    add r1, r1, r6
    lwr r2, r1
    li r1, 1582
    add r1, r1, r6
    swr r2, r1
    li r1, 1485
    add r1, r1, r6
    lwr r2, r1
    li r1, 1583
    add r1, r1, r6
    swr r2, r1
    li r1, 1486
    add r1, r1, r6
    lwr r2, r1
    li r1, 1584
    add r1, r1, r6
    swr r2, r1
    li r1, 1487
    add r1, r1, r6
    lwr r2, r1
    li r1, 1585
    add r1, r1, r6
    swr r2, r1
    li r1, 1488
    add r1, r1, r6
    lwr r2, r1
    li r1, 1586
    add r1, r1, r6
    swr r2, r1
    li r1, 1489
    add r1, r1, r6
    lwr r2, r1
    li r1, 1587
    add r1, r1, r6
    swr r2, r1
    li r1, 1490
    add r1, r1, r6
    lwr r2, r1
    li r1, 1588
    add r1, r1, r6
    swr r2, r1
    li r1, 1491
    add r1, r1, r6
    lwr r2, r1
    li r1, 1589
    add r1, r1, r6
    swr r2, r1
    li r1, 1492
    add r1, r1, r6
    lwr r2, r1
    li r1, 1590
    add r1, r1, r6
    swr r2, r1
    li r1, 1493
    add r1, r1, r6
    lwr r2, r1
    li r1, 1591
    add r1, r1, r6
    swr r2, r1
    li r1, 1494
    add r1, r1, r6
    lwr r2, r1
    li r1, 1592
    add r1, r1, r6
    swr r2, r1
    li r1, 1495
    add r1, r1, r6
    lwr r2, r1
    li r1, 1593
    add r1, r1, r6
    swr r2, r1
    li r1, 1496
    add r1, r1, r6
    lwr r2, r1
    li r1, 1594
    add r1, r1, r6
    swr r2, r1
    li r1, 1497
    add r1, r1, r6
    lwr r2, r1
    li r1, 1595
    add r1, r1, r6
    swr r2, r1
    li r1, 1498
    add r1, r1, r6
    lwr r2, r1
    li r1, 1596
    add r1, r1, r6
    swr r2, r1
    li r1, 1499
    add r1, r1, r6
    lwr r2, r1
    li r1, 1597
    add r1, r1, r6
    swr r2, r1
    li r1, 1500
    add r1, r1, r6
    lwr r2, r1
    li r1, 1598
    add r1, r1, r6
    swr r2, r1
    li r1, 1501
    add r1, r1, r6
    lwr r2, r1
    li r1, 1599
    add r1, r1, r6
    swr r2, r1
    li r1, 1502
    add r1, r1, r6
    lwr r2, r1
    lui r1, 25
    add r1, r1, r6
    swr r2, r1
    li r1, 1503
    add r1, r1, r6
    lwr r2, r1
    li r1, 1601
    add r1, r1, r6
    swr r2, r1
    li r1, 1504
    add r1, r1, r6
    lwr r2, r1
    li r1, 1602
    add r1, r1, r6
    swr r2, r1
    li r1, 1505
    add r1, r1, r6
    lwr r2, r1
    li r1, 1603
    add r1, r1, r6
    swr r2, r1
    li r1, 1506
    add r1, r1, r6
    lwr r2, r1
    li r1, 1604
    add r1, r1, r6
    swr r2, r1
    li r1, 1507
    add r1, r1, r6
    lwr r2, r1
    li r1, 1605
    add r1, r1, r6
    swr r2, r1
    li r1, 1508
    add r1, r1, r6
    lwr r2, r1
    li r1, 1606
    add r1, r1, r6
    swr r2, r1
    li r1, 1509
    add r1, r1, r6
    lwr r2, r1
    li r1, 1607
    add r1, r1, r6
    swr r2, r1
    li r1, 1510
    add r1, r1, r6
    lwr r2, r1
    li r1, 1608
    add r1, r1, r6
    swr r2, r1
    li r1, 1511
    add r1, r1, r6
    lwr r2, r1
    li r1, 1609
    add r1, r1, r6
    swr r2, r1
    li r1, 1512
    add r1, r1, r6
    lwr r2, r1
    li r1, 1610
    add r1, r1, r6
    swr r2, r1
    li r1, 1513
    add r1, r1, r6
    lwr r2, r1
    li r1, 1611
    add r1, r1, r6
    swr r2, r1
    li r1, 1514
    add r1, r1, r6
    lwr r2, r1
    li r1, 1612
    add r1, r1, r6
    swr r2, r1
    li r1, 1515
    add r1, r1, r6
    lwr r2, r1
    li r1, 1613
    add r1, r1, r6
    swr r2, r1
    li r1, 1516
    add r1, r1, r6
    lwr r2, r1
    li r1, 1614
    add r1, r1, r6
    swr r2, r1
    li r1, 1517
    add r1, r1, r6
    lwr r2, r1
    li r1, 1615
    add r1, r1, r6
    swr r2, r1
    li r1, 1518
    add r1, r1, r6
    lwr r2, r1
    li r1, 1616
    add r1, r1, r6
    swr r2, r1
    li r1, 1519
    add r1, r1, r6
    lwr r2, r1
    li r1, 1617
    add r1, r1, r6
    swr r2, r1
    li r1, 1520
    add r1, r1, r6
    lwr r2, r1
    li r1, 1618
    add r1, r1, r6
    swr r2, r1
    li r1, 1521
    add r1, r1, r6
    lwr r2, r1
    li r1, 1619
    add r1, r1, r6
    swr r2, r1
    li r1, 1522
    add r1, r1, r6
    lwr r2, r1
    li r1, 1620
    add r1, r1, r6
    swr r2, r1
    li r1, 1523
    add r1, r1, r6
    lwr r2, r1
    li r1, 1621
    add r1, r1, r6
    swr r2, r1
    li r1, 1524
    add r1, r1, r6
    lwr r2, r1
    li r1, 1622
    add r1, r1, r6
    swr r2, r1
    li r1, 1525
    add r1, r1, r6
    lwr r2, r1
    li r1, 1623
    add r1, r1, r6
    swr r2, r1
    li r1, 209
    add r1, r1, r6
    lwr r2, r1
    li r1, 1624
    add r1, r1, r6
    swr r2, r1
    li r1, 208
    add r1, r1, r6
    lwr r2, r1
    li r1, 1625
    add r1, r1, r6
    swr r2, r1
    li r1, 692
    add r1, r1, r6
    lwr r2, r1
    li r1, 1626
    add r1, r1, r6
    swr r2, r1
    li r1, 696
    add r1, r1, r6
    lwr r2, r1
    li r1, 1627
    add r1, r1, r6
    swr r2, r1
    li r1, 698
    add r1, r1, r6
    lwr r2, r1
    li r1, 1628
    add r1, r1, r6
    swr r2, r1
    li r1, 700
    add r1, r1, r6
    lwr r2, r1
    li r1, 1629
    add r1, r1, r6
    swr r2, r1
    li r1, 702
    add r1, r1, r6
    lwr r2, r1
    li r1, 1630
    add r1, r1, r6
    swr r2, r1
    lui r1, 11
    add r1, r1, r6
    lwr r2, r1
    li r1, 1631
    add r1, r1, r6
    swr r2, r1
    li r1, 706
    add r1, r1, r6
    lwr r2, r1
    li r1, 1632
    add r1, r1, r6
    swr r2, r1
    li r1, 708
    add r1, r1, r6
    lwr r2, r1
    li r1, 1633
    add r1, r1, r6
    swr r2, r1
    li r1, 710
    add r1, r1, r6
    lwr r2, r1
    li r1, 1634
    add r1, r1, r6
    swr r2, r1
    li r1, 712
    add r1, r1, r6
    lwr r2, r1
    li r1, 1635
    add r1, r1, r6
    swr r2, r1
    li r1, 714
    add r1, r1, r6
    lwr r2, r1
    li r1, 1636
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_112
_B_main_179:
    li r1, 1202
    add r1, r1, r6
    lwr r2, r1
    li r1, 1526
    add r1, r1, r6
    swr r2, r1
    li r1, 207
    add r1, r1, r6
    lwr r2, r1
    li r1, 1527
    add r1, r1, r6
    swr r2, r1
    li r1, 1203
    add r1, r1, r6
    lwr r2, r1
    li r1, 1528
    add r1, r1, r6
    swr r2, r1
    li r1, 1204
    add r1, r1, r6
    lwr r2, r1
    li r1, 1529
    add r1, r1, r6
    swr r2, r1
    li r1, 1205
    add r1, r1, r6
    lwr r2, r1
    li r1, 1530
    add r1, r1, r6
    swr r2, r1
    li r1, 1206
    add r1, r1, r6
    lwr r2, r1
    li r1, 1531
    add r1, r1, r6
    swr r2, r1
    li r1, 1207
    add r1, r1, r6
    lwr r2, r1
    li r1, 1532
    add r1, r1, r6
    swr r2, r1
    li r1, 1208
    add r1, r1, r6
    lwr r2, r1
    li r1, 1533
    add r1, r1, r6
    swr r2, r1
    li r1, 1209
    add r1, r1, r6
    lwr r2, r1
    li r1, 1534
    add r1, r1, r6
    swr r2, r1
    li r1, 1210
    add r1, r1, r6
    lwr r2, r1
    li r1, 1535
    add r1, r1, r6
    swr r2, r1
    li r1, 1211
    add r1, r1, r6
    lwr r2, r1
    lui r1, 24
    add r1, r1, r6
    swr r2, r1
    li r1, 1212
    add r1, r1, r6
    lwr r2, r1
    li r1, 1537
    add r1, r1, r6
    swr r2, r1
    li r1, 184
    add r1, r1, r6
    lwr r2, r1
    li r1, 1538
    add r1, r1, r6
    swr r2, r1
    li r1, 183
    add r1, r1, r6
    lwr r2, r1
    li r1, 1539
    add r1, r1, r6
    swr r2, r1
    li r1, 504
    add r1, r1, r6
    lwr r2, r1
    li r1, 1540
    add r1, r1, r6
    swr r2, r1
    li r1, 506
    add r1, r1, r6
    lwr r2, r1
    li r1, 1541
    add r1, r1, r6
    swr r2, r1
    li r1, 508
    add r1, r1, r6
    lwr r2, r1
    li r1, 1542
    add r1, r1, r6
    swr r2, r1
    li r1, 510
    add r1, r1, r6
    lwr r2, r1
    li r1, 1543
    add r1, r1, r6
    swr r2, r1
    lui r1, 8
    add r1, r1, r6
    lwr r2, r1
    li r1, 1544
    add r1, r1, r6
    swr r2, r1
    li r1, 514
    add r1, r1, r6
    lwr r2, r1
    li r1, 1545
    add r1, r1, r6
    swr r2, r1
    li r1, 516
    add r1, r1, r6
    lwr r2, r1
    li r1, 1546
    add r1, r1, r6
    swr r2, r1
    li r1, 520
    add r1, r1, r6
    lwr r2, r1
    li r1, 1547
    add r1, r1, r6
    swr r2, r1
    li r1, 522
    add r1, r1, r6
    lwr r2, r1
    li r1, 1548
    add r1, r1, r6
    swr r2, r1
    li r1, 524
    add r1, r1, r6
    lwr r2, r1
    li r1, 1549
    add r1, r1, r6
    swr r2, r1
    li r1, 526
    add r1, r1, r6
    lwr r2, r1
    li r1, 1550
    add r1, r1, r6
    swr r2, r1
    li r1, 528
    add r1, r1, r6
    lwr r2, r1
    li r1, 1551
    add r1, r1, r6
    swr r2, r1
    li r1, 530
    add r1, r1, r6
    lwr r2, r1
    li r1, 1552
    add r1, r1, r6
    swr r2, r1
    li r1, 532
    add r1, r1, r6
    lwr r2, r1
    li r1, 1553
    add r1, r1, r6
    swr r2, r1
    li r1, 534
    add r1, r1, r6
    lwr r2, r1
    li r1, 1554
    add r1, r1, r6
    swr r2, r1
    li r1, 536
    add r1, r1, r6
    lwr r2, r1
    li r1, 1555
    add r1, r1, r6
    swr r2, r1
    li r1, 538
    add r1, r1, r6
    lwr r2, r1
    li r1, 1556
    add r1, r1, r6
    swr r2, r1
    li r1, 542
    add r1, r1, r6
    lwr r2, r1
    li r1, 1557
    add r1, r1, r6
    swr r2, r1
    li r1, 544
    add r1, r1, r6
    lwr r2, r1
    li r1, 1558
    add r1, r1, r6
    swr r2, r1
    li r1, 546
    add r1, r1, r6
    lwr r2, r1
    li r1, 1559
    add r1, r1, r6
    swr r2, r1
    li r1, 548
    add r1, r1, r6
    lwr r2, r1
    li r1, 1560
    add r1, r1, r6
    swr r2, r1
    li r1, 550
    add r1, r1, r6
    lwr r2, r1
    li r1, 1561
    add r1, r1, r6
    swr r2, r1
    li r1, 552
    add r1, r1, r6
    lwr r2, r1
    li r1, 1562
    add r1, r1, r6
    swr r2, r1
    li r1, 554
    add r1, r1, r6
    lwr r2, r1
    li r1, 1563
    add r1, r1, r6
    swr r2, r1
    li r1, 556
    add r1, r1, r6
    lwr r2, r1
    li r1, 1564
    add r1, r1, r6
    swr r2, r1
    li r1, 558
    add r1, r1, r6
    lwr r2, r1
    li r1, 1565
    add r1, r1, r6
    swr r2, r1
    li r1, 560
    add r1, r1, r6
    lwr r2, r1
    li r1, 1566
    add r1, r1, r6
    swr r2, r1
    li r1, 564
    add r1, r1, r6
    lwr r2, r1
    li r1, 1567
    add r1, r1, r6
    swr r2, r1
    li r1, 566
    add r1, r1, r6
    lwr r2, r1
    li r1, 1568
    add r1, r1, r6
    swr r2, r1
    li r1, 568
    add r1, r1, r6
    lwr r2, r1
    li r1, 1569
    add r1, r1, r6
    swr r2, r1
    li r1, 570
    add r1, r1, r6
    lwr r2, r1
    li r1, 1570
    add r1, r1, r6
    swr r2, r1
    li r1, 572
    add r1, r1, r6
    lwr r2, r1
    li r1, 1571
    add r1, r1, r6
    swr r2, r1
    li r1, 574
    add r1, r1, r6
    lwr r2, r1
    li r1, 1572
    add r1, r1, r6
    swr r2, r1
    lui r1, 9
    add r1, r1, r6
    lwr r2, r1
    li r1, 1573
    add r1, r1, r6
    swr r2, r1
    li r1, 578
    add r1, r1, r6
    lwr r2, r1
    li r1, 1574
    add r1, r1, r6
    swr r2, r1
    li r1, 580
    add r1, r1, r6
    lwr r2, r1
    li r1, 1575
    add r1, r1, r6
    swr r2, r1
    li r1, 582
    add r1, r1, r6
    lwr r2, r1
    li r1, 1576
    add r1, r1, r6
    swr r2, r1
    li r1, 586
    add r1, r1, r6
    lwr r2, r1
    li r1, 1577
    add r1, r1, r6
    swr r2, r1
    li r1, 588
    add r1, r1, r6
    lwr r2, r1
    li r1, 1578
    add r1, r1, r6
    swr r2, r1
    li r1, 590
    add r1, r1, r6
    lwr r2, r1
    li r1, 1579
    add r1, r1, r6
    swr r2, r1
    li r1, 592
    add r1, r1, r6
    lwr r2, r1
    li r1, 1580
    add r1, r1, r6
    swr r2, r1
    li r1, 594
    add r1, r1, r6
    lwr r2, r1
    li r1, 1581
    add r1, r1, r6
    swr r2, r1
    li r1, 596
    add r1, r1, r6
    lwr r2, r1
    li r1, 1582
    add r1, r1, r6
    swr r2, r1
    li r1, 598
    add r1, r1, r6
    lwr r2, r1
    li r1, 1583
    add r1, r1, r6
    swr r2, r1
    li r1, 600
    add r1, r1, r6
    lwr r2, r1
    li r1, 1584
    add r1, r1, r6
    swr r2, r1
    li r1, 602
    add r1, r1, r6
    lwr r2, r1
    li r1, 1585
    add r1, r1, r6
    swr r2, r1
    li r1, 604
    add r1, r1, r6
    lwr r2, r1
    li r1, 1586
    add r1, r1, r6
    swr r2, r1
    li r1, 608
    add r1, r1, r6
    lwr r2, r1
    li r1, 1587
    add r1, r1, r6
    swr r2, r1
    li r1, 610
    add r1, r1, r6
    lwr r2, r1
    li r1, 1588
    add r1, r1, r6
    swr r2, r1
    li r1, 612
    add r1, r1, r6
    lwr r2, r1
    li r1, 1589
    add r1, r1, r6
    swr r2, r1
    li r1, 614
    add r1, r1, r6
    lwr r2, r1
    li r1, 1590
    add r1, r1, r6
    swr r2, r1
    li r1, 616
    add r1, r1, r6
    lwr r2, r1
    li r1, 1591
    add r1, r1, r6
    swr r2, r1
    li r1, 618
    add r1, r1, r6
    lwr r2, r1
    li r1, 1592
    add r1, r1, r6
    swr r2, r1
    li r1, 620
    add r1, r1, r6
    lwr r2, r1
    li r1, 1593
    add r1, r1, r6
    swr r2, r1
    li r1, 622
    add r1, r1, r6
    lwr r2, r1
    li r1, 1594
    add r1, r1, r6
    swr r2, r1
    li r1, 624
    add r1, r1, r6
    lwr r2, r1
    li r1, 1595
    add r1, r1, r6
    swr r2, r1
    li r1, 626
    add r1, r1, r6
    lwr r2, r1
    li r1, 1596
    add r1, r1, r6
    swr r2, r1
    li r1, 630
    add r1, r1, r6
    lwr r2, r1
    li r1, 1597
    add r1, r1, r6
    swr r2, r1
    li r1, 632
    add r1, r1, r6
    lwr r2, r1
    li r1, 1598
    add r1, r1, r6
    swr r2, r1
    li r1, 634
    add r1, r1, r6
    lwr r2, r1
    li r1, 1599
    add r1, r1, r6
    swr r2, r1
    li r1, 636
    add r1, r1, r6
    lwr r2, r1
    lui r1, 25
    add r1, r1, r6
    swr r2, r1
    li r1, 638
    add r1, r1, r6
    lwr r2, r1
    li r1, 1601
    add r1, r1, r6
    swr r2, r1
    lui r1, 10
    add r1, r1, r6
    lwr r2, r1
    li r1, 1602
    add r1, r1, r6
    swr r2, r1
    li r1, 642
    add r1, r1, r6
    lwr r2, r1
    li r1, 1603
    add r1, r1, r6
    swr r2, r1
    li r1, 644
    add r1, r1, r6
    lwr r2, r1
    li r1, 1604
    add r1, r1, r6
    swr r2, r1
    li r1, 646
    add r1, r1, r6
    lwr r2, r1
    li r1, 1605
    add r1, r1, r6
    swr r2, r1
    li r1, 648
    add r1, r1, r6
    lwr r2, r1
    li r1, 1606
    add r1, r1, r6
    swr r2, r1
    li r1, 652
    add r1, r1, r6
    lwr r2, r1
    li r1, 1607
    add r1, r1, r6
    swr r2, r1
    li r1, 654
    add r1, r1, r6
    lwr r2, r1
    li r1, 1608
    add r1, r1, r6
    swr r2, r1
    li r1, 656
    add r1, r1, r6
    lwr r2, r1
    li r1, 1609
    add r1, r1, r6
    swr r2, r1
    li r1, 658
    add r1, r1, r6
    lwr r2, r1
    li r1, 1610
    add r1, r1, r6
    swr r2, r1
    li r1, 660
    add r1, r1, r6
    lwr r2, r1
    li r1, 1611
    add r1, r1, r6
    swr r2, r1
    li r1, 662
    add r1, r1, r6
    lwr r2, r1
    li r1, 1612
    add r1, r1, r6
    swr r2, r1
    li r1, 664
    add r1, r1, r6
    lwr r2, r1
    li r1, 1613
    add r1, r1, r6
    swr r2, r1
    li r1, 666
    add r1, r1, r6
    lwr r2, r1
    li r1, 1614
    add r1, r1, r6
    swr r2, r1
    li r1, 668
    add r1, r1, r6
    lwr r2, r1
    li r1, 1615
    add r1, r1, r6
    swr r2, r1
    li r1, 670
    add r1, r1, r6
    lwr r2, r1
    li r1, 1616
    add r1, r1, r6
    swr r2, r1
    li r1, 674
    add r1, r1, r6
    lwr r2, r1
    li r1, 1617
    add r1, r1, r6
    swr r2, r1
    li r1, 676
    add r1, r1, r6
    lwr r2, r1
    li r1, 1618
    add r1, r1, r6
    swr r2, r1
    li r1, 678
    add r1, r1, r6
    lwr r2, r1
    li r1, 1619
    add r1, r1, r6
    swr r2, r1
    li r1, 680
    add r1, r1, r6
    lwr r2, r1
    li r1, 1620
    add r1, r1, r6
    swr r2, r1
    li r1, 682
    add r1, r1, r6
    lwr r2, r1
    li r1, 1621
    add r1, r1, r6
    swr r2, r1
    li r1, 684
    add r1, r1, r6
    lwr r2, r1
    li r1, 1622
    add r1, r1, r6
    swr r2, r1
    li r1, 686
    add r1, r1, r6
    lwr r2, r1
    li r1, 1623
    add r1, r1, r6
    swr r2, r1
    li r1, 688
    add r1, r1, r6
    lwr r2, r1
    li r1, 1624
    add r1, r1, r6
    swr r2, r1
    li r1, 690
    add r1, r1, r6
    lwr r2, r1
    li r1, 1625
    add r1, r1, r6
    swr r2, r1
    li r1, 206
    add r1, r1, r6
    lwr r2, r1
    li r1, 1626
    add r1, r1, r6
    swr r2, r1
    li r1, 205
    add r1, r1, r6
    lwr r2, r1
    li r1, 1627
    add r1, r1, r6
    swr r2, r1
    li r1, 1213
    add r1, r1, r6
    lwr r2, r1
    li r1, 1628
    add r1, r1, r6
    swr r2, r1
    li r1, 1214
    add r1, r1, r6
    lwr r2, r1
    li r1, 1629
    add r1, r1, r6
    swr r2, r1
    li r1, 1215
    add r1, r1, r6
    lwr r2, r1
    li r1, 1630
    add r1, r1, r6
    swr r2, r1
    lui r1, 19
    add r1, r1, r6
    lwr r2, r1
    li r1, 1631
    add r1, r1, r6
    swr r2, r1
    li r1, 1217
    add r1, r1, r6
    lwr r2, r1
    li r1, 1632
    add r1, r1, r6
    swr r2, r1
    li r1, 1218
    add r1, r1, r6
    lwr r2, r1
    li r1, 1633
    add r1, r1, r6
    swr r2, r1
    li r1, 1219
    add r1, r1, r6
    lwr r2, r1
    li r1, 1634
    add r1, r1, r6
    swr r2, r1
    li r1, 1220
    add r1, r1, r6
    lwr r2, r1
    li r1, 1635
    add r1, r1, r6
    swr r2, r1
    li r1, 1221
    add r1, r1, r6
    lwr r2, r1
    li r1, 1636
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_112
_B_main_180:
    li r1, 1526
    add r1, r1, r6
    lwr r2, r1
    li r1, 1637
    add r1, r1, r6
    swr r2, r1
    li r1, 1527
    add r1, r1, r6
    lwr r2, r1
    li r1, 1638
    add r1, r1, r6
    swr r2, r1
    li r1, 1528
    add r1, r1, r6
    lwr r2, r1
    li r1, 1639
    add r1, r1, r6
    swr r2, r1
    li r1, 1529
    add r1, r1, r6
    lwr r2, r1
    li r1, 1640
    add r1, r1, r6
    swr r2, r1
    li r1, 1530
    add r1, r1, r6
    lwr r2, r1
    li r1, 1641
    add r1, r1, r6
    swr r2, r1
    li r1, 1531
    add r1, r1, r6
    lwr r2, r1
    li r1, 1642
    add r1, r1, r6
    swr r2, r1
    li r1, 1532
    add r1, r1, r6
    lwr r2, r1
    li r1, 1643
    add r1, r1, r6
    swr r2, r1
    li r1, 1533
    add r1, r1, r6
    lwr r2, r1
    li r1, 1644
    add r1, r1, r6
    swr r2, r1
    li r1, 1534
    add r1, r1, r6
    lwr r2, r1
    li r1, 1645
    add r1, r1, r6
    swr r2, r1
    li r1, 1535
    add r1, r1, r6
    lwr r2, r1
    li r1, 1646
    add r1, r1, r6
    swr r2, r1
    lui r1, 24
    add r1, r1, r6
    lwr r2, r1
    li r1, 1647
    add r1, r1, r6
    swr r2, r1
    li r1, 1537
    add r1, r1, r6
    lwr r2, r1
    li r1, 1648
    add r1, r1, r6
    swr r2, r1
    li r1, 1538
    add r1, r1, r6
    lwr r2, r1
    li r1, 1649
    add r1, r1, r6
    swr r2, r1
    li r1, 1539
    add r1, r1, r6
    lwr r2, r1
    li r1, 1650
    add r1, r1, r6
    swr r2, r1
    li r1, 182
    add r1, r1, r6
    lwr r2, r1
    li r1, 1651
    add r1, r1, r6
    swr r2, r1
    li r1, 181
    add r1, r1, r6
    lwr r2, r1
    li r1, 1652
    add r1, r1, r6
    swr r2, r1
    li r1, 355
    add r1, r1, r6
    lwr r2, r1
    li r1, 1653
    add r1, r1, r6
    swr r2, r1
    li r1, 357
    add r1, r1, r6
    lwr r2, r1
    li r1, 1654
    add r1, r1, r6
    swr r2, r1
    li r1, 359
    add r1, r1, r6
    lwr r2, r1
    li r1, 1655
    add r1, r1, r6
    swr r2, r1
    li r1, 361
    add r1, r1, r6
    lwr r2, r1
    li r1, 1656
    add r1, r1, r6
    swr r2, r1
    li r1, 363
    add r1, r1, r6
    lwr r2, r1
    li r1, 1657
    add r1, r1, r6
    swr r2, r1
    li r1, 365
    add r1, r1, r6
    lwr r2, r1
    li r1, 1658
    add r1, r1, r6
    swr r2, r1
    li r1, 367
    add r1, r1, r6
    lwr r2, r1
    li r1, 1659
    add r1, r1, r6
    swr r2, r1
    li r1, 369
    add r1, r1, r6
    lwr r2, r1
    li r1, 1660
    add r1, r1, r6
    swr r2, r1
    li r1, 373
    add r1, r1, r6
    lwr r2, r1
    li r1, 1661
    add r1, r1, r6
    swr r2, r1
    li r1, 375
    add r1, r1, r6
    lwr r2, r1
    li r1, 1662
    add r1, r1, r6
    swr r2, r1
    li r1, 377
    add r1, r1, r6
    lwr r2, r1
    li r1, 1663
    add r1, r1, r6
    swr r2, r1
    li r1, 379
    add r1, r1, r6
    lwr r2, r1
    lui r1, 26
    add r1, r1, r6
    swr r2, r1
    li r1, 381
    add r1, r1, r6
    lwr r2, r1
    li r1, 1665
    add r1, r1, r6
    swr r2, r1
    li r1, 383
    add r1, r1, r6
    lwr r2, r1
    li r1, 1666
    add r1, r1, r6
    swr r2, r1
    li r1, 385
    add r1, r1, r6
    lwr r2, r1
    li r1, 1667
    add r1, r1, r6
    swr r2, r1
    li r1, 387
    add r1, r1, r6
    lwr r2, r1
    li r1, 1668
    add r1, r1, r6
    swr r2, r1
    li r1, 389
    add r1, r1, r6
    lwr r2, r1
    li r1, 1669
    add r1, r1, r6
    swr r2, r1
    li r1, 391
    add r1, r1, r6
    lwr r2, r1
    li r1, 1670
    add r1, r1, r6
    swr r2, r1
    li r1, 395
    add r1, r1, r6
    lwr r2, r1
    li r1, 1671
    add r1, r1, r6
    swr r2, r1
    li r1, 397
    add r1, r1, r6
    lwr r2, r1
    li r1, 1672
    add r1, r1, r6
    swr r2, r1
    li r1, 399
    add r1, r1, r6
    lwr r2, r1
    li r1, 1673
    add r1, r1, r6
    swr r2, r1
    li r1, 1540
    add r1, r1, r6
    lwr r2, r1
    li r1, 1674
    add r1, r1, r6
    swr r2, r1
    li r1, 1541
    add r1, r1, r6
    lwr r2, r1
    li r1, 1675
    add r1, r1, r6
    swr r2, r1
    li r1, 1542
    add r1, r1, r6
    lwr r2, r1
    li r1, 1676
    add r1, r1, r6
    swr r2, r1
    li r1, 1543
    add r1, r1, r6
    lwr r2, r1
    li r1, 1677
    add r1, r1, r6
    swr r2, r1
    li r1, 1544
    add r1, r1, r6
    lwr r2, r1
    li r1, 1678
    add r1, r1, r6
    swr r2, r1
    li r1, 1545
    add r1, r1, r6
    lwr r2, r1
    li r1, 1679
    add r1, r1, r6
    swr r2, r1
    li r1, 1546
    add r1, r1, r6
    lwr r2, r1
    li r1, 1680
    add r1, r1, r6
    swr r2, r1
    li r1, 1547
    add r1, r1, r6
    lwr r2, r1
    li r1, 1681
    add r1, r1, r6
    swr r2, r1
    li r1, 1548
    add r1, r1, r6
    lwr r2, r1
    li r1, 1682
    add r1, r1, r6
    swr r2, r1
    li r1, 1549
    add r1, r1, r6
    lwr r2, r1
    li r1, 1683
    add r1, r1, r6
    swr r2, r1
    li r1, 1550
    add r1, r1, r6
    lwr r2, r1
    li r1, 1684
    add r1, r1, r6
    swr r2, r1
    li r1, 1551
    add r1, r1, r6
    lwr r2, r1
    li r1, 1685
    add r1, r1, r6
    swr r2, r1
    li r1, 1552
    add r1, r1, r6
    lwr r2, r1
    li r1, 1686
    add r1, r1, r6
    swr r2, r1
    li r1, 1553
    add r1, r1, r6
    lwr r2, r1
    li r1, 1687
    add r1, r1, r6
    swr r2, r1
    li r1, 1554
    add r1, r1, r6
    lwr r2, r1
    li r1, 1688
    add r1, r1, r6
    swr r2, r1
    li r1, 1555
    add r1, r1, r6
    lwr r2, r1
    li r1, 1689
    add r1, r1, r6
    swr r2, r1
    li r1, 1556
    add r1, r1, r6
    lwr r2, r1
    li r1, 1690
    add r1, r1, r6
    swr r2, r1
    li r1, 1557
    add r1, r1, r6
    lwr r2, r1
    li r1, 1691
    add r1, r1, r6
    swr r2, r1
    li r1, 1558
    add r1, r1, r6
    lwr r2, r1
    li r1, 1692
    add r1, r1, r6
    swr r2, r1
    li r1, 1559
    add r1, r1, r6
    lwr r2, r1
    li r1, 1693
    add r1, r1, r6
    swr r2, r1
    li r1, 1560
    add r1, r1, r6
    lwr r2, r1
    li r1, 1694
    add r1, r1, r6
    swr r2, r1
    li r1, 1561
    add r1, r1, r6
    lwr r2, r1
    li r1, 1695
    add r1, r1, r6
    swr r2, r1
    li r1, 1562
    add r1, r1, r6
    lwr r2, r1
    li r1, 1696
    add r1, r1, r6
    swr r2, r1
    li r1, 1563
    add r1, r1, r6
    lwr r2, r1
    li r1, 1697
    add r1, r1, r6
    swr r2, r1
    li r1, 1564
    add r1, r1, r6
    lwr r2, r1
    li r1, 1698
    add r1, r1, r6
    swr r2, r1
    li r1, 1565
    add r1, r1, r6
    lwr r2, r1
    li r1, 1699
    add r1, r1, r6
    swr r2, r1
    li r1, 1566
    add r1, r1, r6
    lwr r2, r1
    li r1, 1700
    add r1, r1, r6
    swr r2, r1
    li r1, 1567
    add r1, r1, r6
    lwr r2, r1
    li r1, 1701
    add r1, r1, r6
    swr r2, r1
    li r1, 1568
    add r1, r1, r6
    lwr r2, r1
    li r1, 1702
    add r1, r1, r6
    swr r2, r1
    li r1, 1569
    add r1, r1, r6
    lwr r2, r1
    li r1, 1703
    add r1, r1, r6
    swr r2, r1
    li r1, 1570
    add r1, r1, r6
    lwr r2, r1
    li r1, 1704
    add r1, r1, r6
    swr r2, r1
    li r1, 1571
    add r1, r1, r6
    lwr r2, r1
    li r1, 1705
    add r1, r1, r6
    swr r2, r1
    li r1, 1572
    add r1, r1, r6
    lwr r2, r1
    li r1, 1706
    add r1, r1, r6
    swr r2, r1
    li r1, 1573
    add r1, r1, r6
    lwr r2, r1
    li r1, 1707
    add r1, r1, r6
    swr r2, r1
    li r1, 1574
    add r1, r1, r6
    lwr r2, r1
    li r1, 1708
    add r1, r1, r6
    swr r2, r1
    li r1, 1575
    add r1, r1, r6
    lwr r2, r1
    li r1, 1709
    add r1, r1, r6
    swr r2, r1
    li r1, 1576
    add r1, r1, r6
    lwr r2, r1
    li r1, 1710
    add r1, r1, r6
    swr r2, r1
    li r1, 1577
    add r1, r1, r6
    lwr r2, r1
    li r1, 1711
    add r1, r1, r6
    swr r2, r1
    li r1, 1578
    add r1, r1, r6
    lwr r2, r1
    li r1, 1712
    add r1, r1, r6
    swr r2, r1
    li r1, 1579
    add r1, r1, r6
    lwr r2, r1
    li r1, 1713
    add r1, r1, r6
    swr r2, r1
    li r1, 1580
    add r1, r1, r6
    lwr r2, r1
    li r1, 1714
    add r1, r1, r6
    swr r2, r1
    li r1, 1581
    add r1, r1, r6
    lwr r2, r1
    li r1, 1715
    add r1, r1, r6
    swr r2, r1
    li r1, 1582
    add r1, r1, r6
    lwr r2, r1
    li r1, 1716
    add r1, r1, r6
    swr r2, r1
    li r1, 1583
    add r1, r1, r6
    lwr r2, r1
    li r1, 1717
    add r1, r1, r6
    swr r2, r1
    li r1, 1584
    add r1, r1, r6
    lwr r2, r1
    li r1, 1718
    add r1, r1, r6
    swr r2, r1
    li r1, 1585
    add r1, r1, r6
    lwr r2, r1
    li r1, 1719
    add r1, r1, r6
    swr r2, r1
    li r1, 1586
    add r1, r1, r6
    lwr r2, r1
    li r1, 1720
    add r1, r1, r6
    swr r2, r1
    li r1, 1587
    add r1, r1, r6
    lwr r2, r1
    li r1, 1721
    add r1, r1, r6
    swr r2, r1
    li r1, 1588
    add r1, r1, r6
    lwr r2, r1
    li r1, 1722
    add r1, r1, r6
    swr r2, r1
    li r1, 1589
    add r1, r1, r6
    lwr r2, r1
    li r1, 1723
    add r1, r1, r6
    swr r2, r1
    li r1, 1590
    add r1, r1, r6
    lwr r2, r1
    li r1, 1724
    add r1, r1, r6
    swr r2, r1
    li r1, 1591
    add r1, r1, r6
    lwr r2, r1
    li r1, 1725
    add r1, r1, r6
    swr r2, r1
    li r1, 1592
    add r1, r1, r6
    lwr r2, r1
    li r1, 1726
    add r1, r1, r6
    swr r2, r1
    li r1, 1593
    add r1, r1, r6
    lwr r2, r1
    li r1, 1727
    add r1, r1, r6
    swr r2, r1
    li r1, 1594
    add r1, r1, r6
    lwr r2, r1
    lui r1, 27
    add r1, r1, r6
    swr r2, r1
    li r1, 1595
    add r1, r1, r6
    lwr r2, r1
    li r1, 1729
    add r1, r1, r6
    swr r2, r1
    li r1, 1596
    add r1, r1, r6
    lwr r2, r1
    li r1, 1730
    add r1, r1, r6
    swr r2, r1
    li r1, 1597
    add r1, r1, r6
    lwr r2, r1
    li r1, 1731
    add r1, r1, r6
    swr r2, r1
    li r1, 1598
    add r1, r1, r6
    lwr r2, r1
    li r1, 1732
    add r1, r1, r6
    swr r2, r1
    li r1, 1599
    add r1, r1, r6
    lwr r2, r1
    li r1, 1733
    add r1, r1, r6
    swr r2, r1
    lui r1, 25
    add r1, r1, r6
    lwr r2, r1
    li r1, 1734
    add r1, r1, r6
    swr r2, r1
    li r1, 1601
    add r1, r1, r6
    lwr r2, r1
    li r1, 1735
    add r1, r1, r6
    swr r2, r1
    li r1, 1602
    add r1, r1, r6
    lwr r2, r1
    li r1, 1736
    add r1, r1, r6
    swr r2, r1
    li r1, 1603
    add r1, r1, r6
    lwr r2, r1
    li r1, 1737
    add r1, r1, r6
    swr r2, r1
    li r1, 1604
    add r1, r1, r6
    lwr r2, r1
    li r1, 1738
    add r1, r1, r6
    swr r2, r1
    li r1, 1605
    add r1, r1, r6
    lwr r2, r1
    li r1, 1739
    add r1, r1, r6
    swr r2, r1
    li r1, 1606
    add r1, r1, r6
    lwr r2, r1
    li r1, 1740
    add r1, r1, r6
    swr r2, r1
    li r1, 1607
    add r1, r1, r6
    lwr r2, r1
    li r1, 1741
    add r1, r1, r6
    swr r2, r1
    li r1, 1608
    add r1, r1, r6
    lwr r2, r1
    li r1, 1742
    add r1, r1, r6
    swr r2, r1
    li r1, 1609
    add r1, r1, r6
    lwr r2, r1
    li r1, 1743
    add r1, r1, r6
    swr r2, r1
    li r1, 1610
    add r1, r1, r6
    lwr r2, r1
    li r1, 1744
    add r1, r1, r6
    swr r2, r1
    li r1, 1611
    add r1, r1, r6
    lwr r2, r1
    li r1, 1745
    add r1, r1, r6
    swr r2, r1
    li r1, 1612
    add r1, r1, r6
    lwr r2, r1
    li r1, 1746
    add r1, r1, r6
    swr r2, r1
    li r1, 1613
    add r1, r1, r6
    lwr r2, r1
    li r1, 1747
    add r1, r1, r6
    swr r2, r1
    li r1, 1614
    add r1, r1, r6
    lwr r2, r1
    li r1, 1748
    add r1, r1, r6
    swr r2, r1
    li r1, 1615
    add r1, r1, r6
    lwr r2, r1
    li r1, 1749
    add r1, r1, r6
    swr r2, r1
    li r1, 1616
    add r1, r1, r6
    lwr r2, r1
    li r1, 1750
    add r1, r1, r6
    swr r2, r1
    li r1, 1617
    add r1, r1, r6
    lwr r2, r1
    li r1, 1751
    add r1, r1, r6
    swr r2, r1
    li r1, 1618
    add r1, r1, r6
    lwr r2, r1
    li r1, 1752
    add r1, r1, r6
    swr r2, r1
    li r1, 1619
    add r1, r1, r6
    lwr r2, r1
    li r1, 1753
    add r1, r1, r6
    swr r2, r1
    li r1, 1620
    add r1, r1, r6
    lwr r2, r1
    li r1, 1754
    add r1, r1, r6
    swr r2, r1
    li r1, 1621
    add r1, r1, r6
    lwr r2, r1
    li r1, 1755
    add r1, r1, r6
    swr r2, r1
    li r1, 1622
    add r1, r1, r6
    lwr r2, r1
    li r1, 1756
    add r1, r1, r6
    swr r2, r1
    li r1, 1623
    add r1, r1, r6
    lwr r2, r1
    li r1, 1757
    add r1, r1, r6
    swr r2, r1
    li r1, 1624
    add r1, r1, r6
    lwr r2, r1
    li r1, 1758
    add r1, r1, r6
    swr r2, r1
    li r1, 1625
    add r1, r1, r6
    lwr r2, r1
    li r1, 1759
    add r1, r1, r6
    swr r2, r1
    li r1, 1626
    add r1, r1, r6
    lwr r2, r1
    li r1, 1760
    add r1, r1, r6
    swr r2, r1
    li r1, 1627
    add r1, r1, r6
    lwr r2, r1
    li r1, 1761
    add r1, r1, r6
    swr r2, r1
    li r1, 1628
    add r1, r1, r6
    lwr r2, r1
    li r1, 1762
    add r1, r1, r6
    swr r2, r1
    li r1, 1629
    add r1, r1, r6
    lwr r2, r1
    li r1, 1763
    add r1, r1, r6
    swr r2, r1
    li r1, 1630
    add r1, r1, r6
    lwr r2, r1
    li r1, 1764
    add r1, r1, r6
    swr r2, r1
    li r1, 1631
    add r1, r1, r6
    lwr r2, r1
    li r1, 1765
    add r1, r1, r6
    swr r2, r1
    li r1, 1632
    add r1, r1, r6
    lwr r2, r1
    li r1, 1766
    add r1, r1, r6
    swr r2, r1
    li r1, 1633
    add r1, r1, r6
    lwr r2, r1
    li r1, 1767
    add r1, r1, r6
    swr r2, r1
    li r1, 1634
    add r1, r1, r6
    lwr r2, r1
    li r1, 1768
    add r1, r1, r6
    swr r2, r1
    li r1, 1635
    add r1, r1, r6
    lwr r2, r1
    li r1, 1769
    add r1, r1, r6
    swr r2, r1
    li r1, 1636
    add r1, r1, r6
    lwr r2, r1
    li r1, 1770
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_113
_B_main_181:
    li r1, 1182
    add r1, r1, r6
    lwr r2, r1
    li r1, 1637
    add r1, r1, r6
    swr r2, r1
    li r1, 180
    add r1, r1, r6
    lwr r2, r1
    li r1, 1638
    add r1, r1, r6
    swr r2, r1
    li r1, 1183
    add r1, r1, r6
    lwr r2, r1
    li r1, 1639
    add r1, r1, r6
    swr r2, r1
    li r1, 1184
    add r1, r1, r6
    lwr r2, r1
    li r1, 1640
    add r1, r1, r6
    swr r2, r1
    li r1, 329
    add r1, r1, r6
    lwr r2, r1
    li r1, 1641
    add r1, r1, r6
    swr r2, r1
    li r1, 331
    add r1, r1, r6
    lwr r2, r1
    li r1, 1642
    add r1, r1, r6
    swr r2, r1
    li r1, 333
    add r1, r1, r6
    lwr r2, r1
    li r1, 1643
    add r1, r1, r6
    swr r2, r1
    li r1, 335
    add r1, r1, r6
    lwr r2, r1
    li r1, 1644
    add r1, r1, r6
    swr r2, r1
    li r1, 337
    add r1, r1, r6
    lwr r2, r1
    li r1, 1645
    add r1, r1, r6
    swr r2, r1
    li r1, 339
    add r1, r1, r6
    lwr r2, r1
    li r1, 1646
    add r1, r1, r6
    swr r2, r1
    li r1, 341
    add r1, r1, r6
    lwr r2, r1
    li r1, 1647
    add r1, r1, r6
    swr r2, r1
    li r1, 343
    add r1, r1, r6
    lwr r2, r1
    li r1, 1648
    add r1, r1, r6
    swr r2, r1
    li r1, 345
    add r1, r1, r6
    lwr r2, r1
    li r1, 1649
    add r1, r1, r6
    swr r2, r1
    li r1, 347
    add r1, r1, r6
    lwr r2, r1
    li r1, 1650
    add r1, r1, r6
    swr r2, r1
    li r1, 351
    add r1, r1, r6
    lwr r2, r1
    li r1, 1651
    add r1, r1, r6
    swr r2, r1
    li r1, 353
    add r1, r1, r6
    lwr r2, r1
    li r1, 1652
    add r1, r1, r6
    swr r2, r1
    li r1, 179
    add r1, r1, r6
    lwr r2, r1
    li r1, 1653
    add r1, r1, r6
    swr r2, r1
    li r1, 178
    add r1, r1, r6
    lwr r2, r1
    li r1, 1654
    add r1, r1, r6
    swr r2, r1
    li r1, 1185
    add r1, r1, r6
    lwr r2, r1
    li r1, 1655
    add r1, r1, r6
    swr r2, r1
    li r1, 1186
    add r1, r1, r6
    lwr r2, r1
    li r1, 1656
    add r1, r1, r6
    swr r2, r1
    li r1, 1187
    add r1, r1, r6
    lwr r2, r1
    li r1, 1657
    add r1, r1, r6
    swr r2, r1
    li r1, 1188
    add r1, r1, r6
    lwr r2, r1
    li r1, 1658
    add r1, r1, r6
    swr r2, r1
    li r1, 1189
    add r1, r1, r6
    lwr r2, r1
    li r1, 1659
    add r1, r1, r6
    swr r2, r1
    li r1, 1190
    add r1, r1, r6
    lwr r2, r1
    li r1, 1660
    add r1, r1, r6
    swr r2, r1
    li r1, 1191
    add r1, r1, r6
    lwr r2, r1
    li r1, 1661
    add r1, r1, r6
    swr r2, r1
    li r1, 1192
    add r1, r1, r6
    lwr r2, r1
    li r1, 1662
    add r1, r1, r6
    swr r2, r1
    li r1, 1193
    add r1, r1, r6
    lwr r2, r1
    li r1, 1663
    add r1, r1, r6
    swr r2, r1
    li r1, 1194
    add r1, r1, r6
    lwr r2, r1
    lui r1, 26
    add r1, r1, r6
    swr r2, r1
    li r1, 1195
    add r1, r1, r6
    lwr r2, r1
    li r1, 1665
    add r1, r1, r6
    swr r2, r1
    li r1, 1196
    add r1, r1, r6
    lwr r2, r1
    li r1, 1666
    add r1, r1, r6
    swr r2, r1
    li r1, 1197
    add r1, r1, r6
    lwr r2, r1
    li r1, 1667
    add r1, r1, r6
    swr r2, r1
    li r1, 1198
    add r1, r1, r6
    lwr r2, r1
    li r1, 1668
    add r1, r1, r6
    swr r2, r1
    li r1, 1199
    add r1, r1, r6
    lwr r2, r1
    li r1, 1669
    add r1, r1, r6
    swr r2, r1
    li r1, 1200
    add r1, r1, r6
    lwr r2, r1
    li r1, 1670
    add r1, r1, r6
    swr r2, r1
    li r1, 1201
    add r1, r1, r6
    lwr r2, r1
    li r1, 1671
    add r1, r1, r6
    swr r2, r1
    li r1, 157
    add r1, r1, r6
    lwr r2, r1
    li r1, 1672
    add r1, r1, r6
    swr r2, r1
    li r1, 156
    add r1, r1, r6
    lwr r2, r1
    li r1, 1673
    add r1, r1, r6
    swr r2, r1
    li r1, 504
    add r1, r1, r6
    lwr r2, r1
    li r1, 1674
    add r1, r1, r6
    swr r2, r1
    li r1, 506
    add r1, r1, r6
    lwr r2, r1
    li r1, 1675
    add r1, r1, r6
    swr r2, r1
    li r1, 508
    add r1, r1, r6
    lwr r2, r1
    li r1, 1676
    add r1, r1, r6
    swr r2, r1
    li r1, 510
    add r1, r1, r6
    lwr r2, r1
    li r1, 1677
    add r1, r1, r6
    swr r2, r1
    lui r1, 8
    add r1, r1, r6
    lwr r2, r1
    li r1, 1678
    add r1, r1, r6
    swr r2, r1
    li r1, 514
    add r1, r1, r6
    lwr r2, r1
    li r1, 1679
    add r1, r1, r6
    swr r2, r1
    li r1, 516
    add r1, r1, r6
    lwr r2, r1
    li r1, 1680
    add r1, r1, r6
    swr r2, r1
    li r1, 520
    add r1, r1, r6
    lwr r2, r1
    li r1, 1681
    add r1, r1, r6
    swr r2, r1
    li r1, 522
    add r1, r1, r6
    lwr r2, r1
    li r1, 1682
    add r1, r1, r6
    swr r2, r1
    li r1, 524
    add r1, r1, r6
    lwr r2, r1
    li r1, 1683
    add r1, r1, r6
    swr r2, r1
    li r1, 526
    add r1, r1, r6
    lwr r2, r1
    li r1, 1684
    add r1, r1, r6
    swr r2, r1
    li r1, 528
    add r1, r1, r6
    lwr r2, r1
    li r1, 1685
    add r1, r1, r6
    swr r2, r1
    li r1, 530
    add r1, r1, r6
    lwr r2, r1
    li r1, 1686
    add r1, r1, r6
    swr r2, r1
    li r1, 532
    add r1, r1, r6
    lwr r2, r1
    li r1, 1687
    add r1, r1, r6
    swr r2, r1
    li r1, 534
    add r1, r1, r6
    lwr r2, r1
    li r1, 1688
    add r1, r1, r6
    swr r2, r1
    li r1, 536
    add r1, r1, r6
    lwr r2, r1
    li r1, 1689
    add r1, r1, r6
    swr r2, r1
    li r1, 538
    add r1, r1, r6
    lwr r2, r1
    li r1, 1690
    add r1, r1, r6
    swr r2, r1
    li r1, 542
    add r1, r1, r6
    lwr r2, r1
    li r1, 1691
    add r1, r1, r6
    swr r2, r1
    li r1, 544
    add r1, r1, r6
    lwr r2, r1
    li r1, 1692
    add r1, r1, r6
    swr r2, r1
    li r1, 546
    add r1, r1, r6
    lwr r2, r1
    li r1, 1693
    add r1, r1, r6
    swr r2, r1
    li r1, 548
    add r1, r1, r6
    lwr r2, r1
    li r1, 1694
    add r1, r1, r6
    swr r2, r1
    li r1, 550
    add r1, r1, r6
    lwr r2, r1
    li r1, 1695
    add r1, r1, r6
    swr r2, r1
    li r1, 552
    add r1, r1, r6
    lwr r2, r1
    li r1, 1696
    add r1, r1, r6
    swr r2, r1
    li r1, 554
    add r1, r1, r6
    lwr r2, r1
    li r1, 1697
    add r1, r1, r6
    swr r2, r1
    li r1, 556
    add r1, r1, r6
    lwr r2, r1
    li r1, 1698
    add r1, r1, r6
    swr r2, r1
    li r1, 558
    add r1, r1, r6
    lwr r2, r1
    li r1, 1699
    add r1, r1, r6
    swr r2, r1
    li r1, 560
    add r1, r1, r6
    lwr r2, r1
    li r1, 1700
    add r1, r1, r6
    swr r2, r1
    li r1, 564
    add r1, r1, r6
    lwr r2, r1
    li r1, 1701
    add r1, r1, r6
    swr r2, r1
    li r1, 566
    add r1, r1, r6
    lwr r2, r1
    li r1, 1702
    add r1, r1, r6
    swr r2, r1
    li r1, 568
    add r1, r1, r6
    lwr r2, r1
    li r1, 1703
    add r1, r1, r6
    swr r2, r1
    li r1, 570
    add r1, r1, r6
    lwr r2, r1
    li r1, 1704
    add r1, r1, r6
    swr r2, r1
    li r1, 572
    add r1, r1, r6
    lwr r2, r1
    li r1, 1705
    add r1, r1, r6
    swr r2, r1
    li r1, 574
    add r1, r1, r6
    lwr r2, r1
    li r1, 1706
    add r1, r1, r6
    swr r2, r1
    lui r1, 9
    add r1, r1, r6
    lwr r2, r1
    li r1, 1707
    add r1, r1, r6
    swr r2, r1
    li r1, 578
    add r1, r1, r6
    lwr r2, r1
    li r1, 1708
    add r1, r1, r6
    swr r2, r1
    li r1, 580
    add r1, r1, r6
    lwr r2, r1
    li r1, 1709
    add r1, r1, r6
    swr r2, r1
    li r1, 582
    add r1, r1, r6
    lwr r2, r1
    li r1, 1710
    add r1, r1, r6
    swr r2, r1
    li r1, 586
    add r1, r1, r6
    lwr r2, r1
    li r1, 1711
    add r1, r1, r6
    swr r2, r1
    li r1, 588
    add r1, r1, r6
    lwr r2, r1
    li r1, 1712
    add r1, r1, r6
    swr r2, r1
    li r1, 590
    add r1, r1, r6
    lwr r2, r1
    li r1, 1713
    add r1, r1, r6
    swr r2, r1
    li r1, 592
    add r1, r1, r6
    lwr r2, r1
    li r1, 1714
    add r1, r1, r6
    swr r2, r1
    li r1, 594
    add r1, r1, r6
    lwr r2, r1
    li r1, 1715
    add r1, r1, r6
    swr r2, r1
    li r1, 596
    add r1, r1, r6
    lwr r2, r1
    li r1, 1716
    add r1, r1, r6
    swr r2, r1
    li r1, 598
    add r1, r1, r6
    lwr r2, r1
    li r1, 1717
    add r1, r1, r6
    swr r2, r1
    li r1, 600
    add r1, r1, r6
    lwr r2, r1
    li r1, 1718
    add r1, r1, r6
    swr r2, r1
    li r1, 602
    add r1, r1, r6
    lwr r2, r1
    li r1, 1719
    add r1, r1, r6
    swr r2, r1
    li r1, 604
    add r1, r1, r6
    lwr r2, r1
    li r1, 1720
    add r1, r1, r6
    swr r2, r1
    li r1, 608
    add r1, r1, r6
    lwr r2, r1
    li r1, 1721
    add r1, r1, r6
    swr r2, r1
    li r1, 610
    add r1, r1, r6
    lwr r2, r1
    li r1, 1722
    add r1, r1, r6
    swr r2, r1
    li r1, 612
    add r1, r1, r6
    lwr r2, r1
    li r1, 1723
    add r1, r1, r6
    swr r2, r1
    li r1, 614
    add r1, r1, r6
    lwr r2, r1
    li r1, 1724
    add r1, r1, r6
    swr r2, r1
    li r1, 616
    add r1, r1, r6
    lwr r2, r1
    li r1, 1725
    add r1, r1, r6
    swr r2, r1
    li r1, 618
    add r1, r1, r6
    lwr r2, r1
    li r1, 1726
    add r1, r1, r6
    swr r2, r1
    li r1, 620
    add r1, r1, r6
    lwr r2, r1
    li r1, 1727
    add r1, r1, r6
    swr r2, r1
    li r1, 622
    add r1, r1, r6
    lwr r2, r1
    lui r1, 27
    add r1, r1, r6
    swr r2, r1
    li r1, 624
    add r1, r1, r6
    lwr r2, r1
    li r1, 1729
    add r1, r1, r6
    swr r2, r1
    li r1, 626
    add r1, r1, r6
    lwr r2, r1
    li r1, 1730
    add r1, r1, r6
    swr r2, r1
    li r1, 630
    add r1, r1, r6
    lwr r2, r1
    li r1, 1731
    add r1, r1, r6
    swr r2, r1
    li r1, 632
    add r1, r1, r6
    lwr r2, r1
    li r1, 1732
    add r1, r1, r6
    swr r2, r1
    li r1, 634
    add r1, r1, r6
    lwr r2, r1
    li r1, 1733
    add r1, r1, r6
    swr r2, r1
    li r1, 636
    add r1, r1, r6
    lwr r2, r1
    li r1, 1734
    add r1, r1, r6
    swr r2, r1
    li r1, 638
    add r1, r1, r6
    lwr r2, r1
    li r1, 1735
    add r1, r1, r6
    swr r2, r1
    lui r1, 10
    add r1, r1, r6
    lwr r2, r1
    li r1, 1736
    add r1, r1, r6
    swr r2, r1
    li r1, 642
    add r1, r1, r6
    lwr r2, r1
    li r1, 1737
    add r1, r1, r6
    swr r2, r1
    li r1, 644
    add r1, r1, r6
    lwr r2, r1
    li r1, 1738
    add r1, r1, r6
    swr r2, r1
    li r1, 646
    add r1, r1, r6
    lwr r2, r1
    li r1, 1739
    add r1, r1, r6
    swr r2, r1
    li r1, 648
    add r1, r1, r6
    lwr r2, r1
    li r1, 1740
    add r1, r1, r6
    swr r2, r1
    li r1, 652
    add r1, r1, r6
    lwr r2, r1
    li r1, 1741
    add r1, r1, r6
    swr r2, r1
    li r1, 654
    add r1, r1, r6
    lwr r2, r1
    li r1, 1742
    add r1, r1, r6
    swr r2, r1
    li r1, 656
    add r1, r1, r6
    lwr r2, r1
    li r1, 1743
    add r1, r1, r6
    swr r2, r1
    li r1, 658
    add r1, r1, r6
    lwr r2, r1
    li r1, 1744
    add r1, r1, r6
    swr r2, r1
    li r1, 660
    add r1, r1, r6
    lwr r2, r1
    li r1, 1745
    add r1, r1, r6
    swr r2, r1
    li r1, 662
    add r1, r1, r6
    lwr r2, r1
    li r1, 1746
    add r1, r1, r6
    swr r2, r1
    li r1, 664
    add r1, r1, r6
    lwr r2, r1
    li r1, 1747
    add r1, r1, r6
    swr r2, r1
    li r1, 666
    add r1, r1, r6
    lwr r2, r1
    li r1, 1748
    add r1, r1, r6
    swr r2, r1
    li r1, 668
    add r1, r1, r6
    lwr r2, r1
    li r1, 1749
    add r1, r1, r6
    swr r2, r1
    li r1, 670
    add r1, r1, r6
    lwr r2, r1
    li r1, 1750
    add r1, r1, r6
    swr r2, r1
    li r1, 674
    add r1, r1, r6
    lwr r2, r1
    li r1, 1751
    add r1, r1, r6
    swr r2, r1
    li r1, 676
    add r1, r1, r6
    lwr r2, r1
    li r1, 1752
    add r1, r1, r6
    swr r2, r1
    li r1, 678
    add r1, r1, r6
    lwr r2, r1
    li r1, 1753
    add r1, r1, r6
    swr r2, r1
    li r1, 680
    add r1, r1, r6
    lwr r2, r1
    li r1, 1754
    add r1, r1, r6
    swr r2, r1
    li r1, 682
    add r1, r1, r6
    lwr r2, r1
    li r1, 1755
    add r1, r1, r6
    swr r2, r1
    li r1, 684
    add r1, r1, r6
    lwr r2, r1
    li r1, 1756
    add r1, r1, r6
    swr r2, r1
    li r1, 686
    add r1, r1, r6
    lwr r2, r1
    li r1, 1757
    add r1, r1, r6
    swr r2, r1
    li r1, 688
    add r1, r1, r6
    lwr r2, r1
    li r1, 1758
    add r1, r1, r6
    swr r2, r1
    li r1, 690
    add r1, r1, r6
    lwr r2, r1
    li r1, 1759
    add r1, r1, r6
    swr r2, r1
    li r1, 692
    add r1, r1, r6
    lwr r2, r1
    li r1, 1760
    add r1, r1, r6
    swr r2, r1
    li r1, 696
    add r1, r1, r6
    lwr r2, r1
    li r1, 1761
    add r1, r1, r6
    swr r2, r1
    li r1, 698
    add r1, r1, r6
    lwr r2, r1
    li r1, 1762
    add r1, r1, r6
    swr r2, r1
    li r1, 700
    add r1, r1, r6
    lwr r2, r1
    li r1, 1763
    add r1, r1, r6
    swr r2, r1
    li r1, 702
    add r1, r1, r6
    lwr r2, r1
    li r1, 1764
    add r1, r1, r6
    swr r2, r1
    lui r1, 11
    add r1, r1, r6
    lwr r2, r1
    li r1, 1765
    add r1, r1, r6
    swr r2, r1
    li r1, 706
    add r1, r1, r6
    lwr r2, r1
    li r1, 1766
    add r1, r1, r6
    swr r2, r1
    li r1, 708
    add r1, r1, r6
    lwr r2, r1
    li r1, 1767
    add r1, r1, r6
    swr r2, r1
    li r1, 710
    add r1, r1, r6
    lwr r2, r1
    li r1, 1768
    add r1, r1, r6
    swr r2, r1
    li r1, 712
    add r1, r1, r6
    lwr r2, r1
    li r1, 1769
    add r1, r1, r6
    swr r2, r1
    li r1, 714
    add r1, r1, r6
    lwr r2, r1
    li r1, 1770
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_113
_B_main_182:
    li r1, 1637
    add r1, r1, r6
    lwr r2, r1
    li r1, 1771
    add r1, r1, r6
    swr r2, r1
    li r1, 1638
    add r1, r1, r6
    lwr r2, r1
    li r1, 1772
    add r1, r1, r6
    swr r2, r1
    li r1, 1639
    add r1, r1, r6
    lwr r2, r1
    li r1, 1773
    add r1, r1, r6
    swr r2, r1
    li r1, 1640
    add r1, r1, r6
    lwr r2, r1
    li r1, 1774
    add r1, r1, r6
    swr r2, r1
    li r1, 1641
    add r1, r1, r6
    lwr r2, r1
    li r1, 1775
    add r1, r1, r6
    swr r2, r1
    li r1, 1642
    add r1, r1, r6
    lwr r2, r1
    li r1, 1776
    add r1, r1, r6
    swr r2, r1
    li r1, 1643
    add r1, r1, r6
    lwr r2, r1
    li r1, 1777
    add r1, r1, r6
    swr r2, r1
    li r1, 1644
    add r1, r1, r6
    lwr r2, r1
    li r1, 1778
    add r1, r1, r6
    swr r2, r1
    li r1, 1645
    add r1, r1, r6
    lwr r2, r1
    li r1, 1779
    add r1, r1, r6
    swr r2, r1
    li r1, 1646
    add r1, r1, r6
    lwr r2, r1
    li r1, 1780
    add r1, r1, r6
    swr r2, r1
    li r1, 1647
    add r1, r1, r6
    lwr r2, r1
    li r1, 1781
    add r1, r1, r6
    swr r2, r1
    li r1, 1648
    add r1, r1, r6
    lwr r2, r1
    li r1, 1782
    add r1, r1, r6
    swr r2, r1
    li r1, 1649
    add r1, r1, r6
    lwr r2, r1
    li r1, 1783
    add r1, r1, r6
    swr r2, r1
    li r1, 1650
    add r1, r1, r6
    lwr r2, r1
    li r1, 1784
    add r1, r1, r6
    swr r2, r1
    li r1, 1651
    add r1, r1, r6
    lwr r2, r1
    li r1, 1785
    add r1, r1, r6
    swr r2, r1
    li r1, 1652
    add r1, r1, r6
    lwr r2, r1
    li r1, 1786
    add r1, r1, r6
    swr r2, r1
    li r1, 1653
    add r1, r1, r6
    lwr r2, r1
    li r1, 1787
    add r1, r1, r6
    swr r2, r1
    li r1, 1654
    add r1, r1, r6
    lwr r2, r1
    li r1, 1788
    add r1, r1, r6
    swr r2, r1
    li r1, 1655
    add r1, r1, r6
    lwr r2, r1
    li r1, 1789
    add r1, r1, r6
    swr r2, r1
    li r1, 1656
    add r1, r1, r6
    lwr r2, r1
    li r1, 1790
    add r1, r1, r6
    swr r2, r1
    li r1, 1657
    add r1, r1, r6
    lwr r2, r1
    li r1, 1791
    add r1, r1, r6
    swr r2, r1
    li r1, 1658
    add r1, r1, r6
    lwr r2, r1
    lui r1, 28
    add r1, r1, r6
    swr r2, r1
    li r1, 1659
    add r1, r1, r6
    lwr r2, r1
    li r1, 1793
    add r1, r1, r6
    swr r2, r1
    li r1, 1660
    add r1, r1, r6
    lwr r2, r1
    li r1, 1794
    add r1, r1, r6
    swr r2, r1
    li r1, 1661
    add r1, r1, r6
    lwr r2, r1
    li r1, 1795
    add r1, r1, r6
    swr r2, r1
    li r1, 1662
    add r1, r1, r6
    lwr r2, r1
    li r1, 1796
    add r1, r1, r6
    swr r2, r1
    li r1, 1663
    add r1, r1, r6
    lwr r2, r1
    li r1, 1797
    add r1, r1, r6
    swr r2, r1
    lui r1, 26
    add r1, r1, r6
    lwr r2, r1
    li r1, 1798
    add r1, r1, r6
    swr r2, r1
    li r1, 1665
    add r1, r1, r6
    lwr r2, r1
    li r1, 1799
    add r1, r1, r6
    swr r2, r1
    li r1, 1666
    add r1, r1, r6
    lwr r2, r1
    li r1, 1800
    add r1, r1, r6
    swr r2, r1
    li r1, 1667
    add r1, r1, r6
    lwr r2, r1
    li r1, 1801
    add r1, r1, r6
    swr r2, r1
    li r1, 1668
    add r1, r1, r6
    lwr r2, r1
    li r1, 1802
    add r1, r1, r6
    swr r2, r1
    li r1, 1669
    add r1, r1, r6
    lwr r2, r1
    li r1, 1803
    add r1, r1, r6
    swr r2, r1
    li r1, 1670
    add r1, r1, r6
    lwr r2, r1
    li r1, 1804
    add r1, r1, r6
    swr r2, r1
    li r1, 1671
    add r1, r1, r6
    lwr r2, r1
    li r1, 1805
    add r1, r1, r6
    swr r2, r1
    li r1, 1672
    add r1, r1, r6
    lwr r2, r1
    li r1, 1806
    add r1, r1, r6
    swr r2, r1
    li r1, 1673
    add r1, r1, r6
    lwr r2, r1
    li r1, 1807
    add r1, r1, r6
    swr r2, r1
    li r1, 155
    add r1, r1, r6
    lwr r2, r1
    li r1, 1808
    add r1, r1, r6
    swr r2, r1
    li r1, 154
    add r1, r1, r6
    lwr r2, r1
    li r1, 1809
    add r1, r1, r6
    swr r2, r1
    li r1, 405
    add r1, r1, r6
    lwr r2, r1
    li r1, 1810
    add r1, r1, r6
    swr r2, r1
    li r1, 407
    add r1, r1, r6
    lwr r2, r1
    li r1, 1811
    add r1, r1, r6
    swr r2, r1
    li r1, 409
    add r1, r1, r6
    lwr r2, r1
    li r1, 1812
    add r1, r1, r6
    swr r2, r1
    li r1, 411
    add r1, r1, r6
    lwr r2, r1
    li r1, 1813
    add r1, r1, r6
    swr r2, r1
    li r1, 413
    add r1, r1, r6
    lwr r2, r1
    li r1, 1814
    add r1, r1, r6
    swr r2, r1
    li r1, 417
    add r1, r1, r6
    lwr r2, r1
    li r1, 1815
    add r1, r1, r6
    swr r2, r1
    li r1, 419
    add r1, r1, r6
    lwr r2, r1
    li r1, 1816
    add r1, r1, r6
    swr r2, r1
    li r1, 421
    add r1, r1, r6
    lwr r2, r1
    li r1, 1817
    add r1, r1, r6
    swr r2, r1
    li r1, 423
    add r1, r1, r6
    lwr r2, r1
    li r1, 1818
    add r1, r1, r6
    swr r2, r1
    li r1, 425
    add r1, r1, r6
    lwr r2, r1
    li r1, 1819
    add r1, r1, r6
    swr r2, r1
    li r1, 427
    add r1, r1, r6
    lwr r2, r1
    li r1, 1820
    add r1, r1, r6
    swr r2, r1
    li r1, 429
    add r1, r1, r6
    lwr r2, r1
    li r1, 1821
    add r1, r1, r6
    swr r2, r1
    li r1, 431
    add r1, r1, r6
    lwr r2, r1
    li r1, 1822
    add r1, r1, r6
    swr r2, r1
    li r1, 433
    add r1, r1, r6
    lwr r2, r1
    li r1, 1823
    add r1, r1, r6
    swr r2, r1
    li r1, 435
    add r1, r1, r6
    lwr r2, r1
    li r1, 1824
    add r1, r1, r6
    swr r2, r1
    li r1, 439
    add r1, r1, r6
    lwr r2, r1
    li r1, 1825
    add r1, r1, r6
    swr r2, r1
    li r1, 441
    add r1, r1, r6
    lwr r2, r1
    li r1, 1826
    add r1, r1, r6
    swr r2, r1
    li r1, 443
    add r1, r1, r6
    lwr r2, r1
    li r1, 1827
    add r1, r1, r6
    swr r2, r1
    li r1, 445
    add r1, r1, r6
    lwr r2, r1
    li r1, 1828
    add r1, r1, r6
    swr r2, r1
    li r1, 447
    add r1, r1, r6
    lwr r2, r1
    li r1, 1829
    add r1, r1, r6
    swr r2, r1
    li r1, 449
    add r1, r1, r6
    lwr r2, r1
    li r1, 1830
    add r1, r1, r6
    swr r2, r1
    li r1, 1674
    add r1, r1, r6
    lwr r2, r1
    li r1, 1831
    add r1, r1, r6
    swr r2, r1
    li r1, 1675
    add r1, r1, r6
    lwr r2, r1
    li r1, 1832
    add r1, r1, r6
    swr r2, r1
    li r1, 1676
    add r1, r1, r6
    lwr r2, r1
    li r1, 1833
    add r1, r1, r6
    swr r2, r1
    li r1, 1677
    add r1, r1, r6
    lwr r2, r1
    li r1, 1834
    add r1, r1, r6
    swr r2, r1
    li r1, 1678
    add r1, r1, r6
    lwr r2, r1
    li r1, 1835
    add r1, r1, r6
    swr r2, r1
    li r1, 1679
    add r1, r1, r6
    lwr r2, r1
    li r1, 1836
    add r1, r1, r6
    swr r2, r1
    li r1, 1680
    add r1, r1, r6
    lwr r2, r1
    li r1, 1837
    add r1, r1, r6
    swr r2, r1
    li r1, 1681
    add r1, r1, r6
    lwr r2, r1
    li r1, 1838
    add r1, r1, r6
    swr r2, r1
    li r1, 1682
    add r1, r1, r6
    lwr r2, r1
    li r1, 1839
    add r1, r1, r6
    swr r2, r1
    li r1, 1683
    add r1, r1, r6
    lwr r2, r1
    li r1, 1840
    add r1, r1, r6
    swr r2, r1
    li r1, 1684
    add r1, r1, r6
    lwr r2, r1
    li r1, 1841
    add r1, r1, r6
    swr r2, r1
    li r1, 1685
    add r1, r1, r6
    lwr r2, r1
    li r1, 1842
    add r1, r1, r6
    swr r2, r1
    li r1, 1686
    add r1, r1, r6
    lwr r2, r1
    li r1, 1843
    add r1, r1, r6
    swr r2, r1
    li r1, 1687
    add r1, r1, r6
    lwr r2, r1
    li r1, 1844
    add r1, r1, r6
    swr r2, r1
    li r1, 1688
    add r1, r1, r6
    lwr r2, r1
    li r1, 1845
    add r1, r1, r6
    swr r2, r1
    li r1, 1689
    add r1, r1, r6
    lwr r2, r1
    li r1, 1846
    add r1, r1, r6
    swr r2, r1
    li r1, 1690
    add r1, r1, r6
    lwr r2, r1
    li r1, 1847
    add r1, r1, r6
    swr r2, r1
    li r1, 1691
    add r1, r1, r6
    lwr r2, r1
    li r1, 1848
    add r1, r1, r6
    swr r2, r1
    li r1, 1692
    add r1, r1, r6
    lwr r2, r1
    li r1, 1849
    add r1, r1, r6
    swr r2, r1
    li r1, 1693
    add r1, r1, r6
    lwr r2, r1
    li r1, 1850
    add r1, r1, r6
    swr r2, r1
    li r1, 1694
    add r1, r1, r6
    lwr r2, r1
    li r1, 1851
    add r1, r1, r6
    swr r2, r1
    li r1, 1695
    add r1, r1, r6
    lwr r2, r1
    li r1, 1852
    add r1, r1, r6
    swr r2, r1
    li r1, 1696
    add r1, r1, r6
    lwr r2, r1
    li r1, 1853
    add r1, r1, r6
    swr r2, r1
    li r1, 1697
    add r1, r1, r6
    lwr r2, r1
    li r1, 1854
    add r1, r1, r6
    swr r2, r1
    li r1, 1698
    add r1, r1, r6
    lwr r2, r1
    li r1, 1855
    add r1, r1, r6
    swr r2, r1
    li r1, 1699
    add r1, r1, r6
    lwr r2, r1
    lui r1, 29
    add r1, r1, r6
    swr r2, r1
    li r1, 1700
    add r1, r1, r6
    lwr r2, r1
    li r1, 1857
    add r1, r1, r6
    swr r2, r1
    li r1, 1701
    add r1, r1, r6
    lwr r2, r1
    li r1, 1858
    add r1, r1, r6
    swr r2, r1
    li r1, 1702
    add r1, r1, r6
    lwr r2, r1
    li r1, 1859
    add r1, r1, r6
    swr r2, r1
    li r1, 1703
    add r1, r1, r6
    lwr r2, r1
    li r1, 1860
    add r1, r1, r6
    swr r2, r1
    li r1, 1704
    add r1, r1, r6
    lwr r2, r1
    li r1, 1861
    add r1, r1, r6
    swr r2, r1
    li r1, 1705
    add r1, r1, r6
    lwr r2, r1
    li r1, 1862
    add r1, r1, r6
    swr r2, r1
    li r1, 1706
    add r1, r1, r6
    lwr r2, r1
    li r1, 1863
    add r1, r1, r6
    swr r2, r1
    li r1, 1707
    add r1, r1, r6
    lwr r2, r1
    li r1, 1864
    add r1, r1, r6
    swr r2, r1
    li r1, 1708
    add r1, r1, r6
    lwr r2, r1
    li r1, 1865
    add r1, r1, r6
    swr r2, r1
    li r1, 1709
    add r1, r1, r6
    lwr r2, r1
    li r1, 1866
    add r1, r1, r6
    swr r2, r1
    li r1, 1710
    add r1, r1, r6
    lwr r2, r1
    li r1, 1867
    add r1, r1, r6
    swr r2, r1
    li r1, 1711
    add r1, r1, r6
    lwr r2, r1
    li r1, 1868
    add r1, r1, r6
    swr r2, r1
    li r1, 1712
    add r1, r1, r6
    lwr r2, r1
    li r1, 1869
    add r1, r1, r6
    swr r2, r1
    li r1, 1713
    add r1, r1, r6
    lwr r2, r1
    li r1, 1870
    add r1, r1, r6
    swr r2, r1
    li r1, 1714
    add r1, r1, r6
    lwr r2, r1
    li r1, 1871
    add r1, r1, r6
    swr r2, r1
    li r1, 1715
    add r1, r1, r6
    lwr r2, r1
    li r1, 1872
    add r1, r1, r6
    swr r2, r1
    li r1, 1716
    add r1, r1, r6
    lwr r2, r1
    li r1, 1873
    add r1, r1, r6
    swr r2, r1
    li r1, 1717
    add r1, r1, r6
    lwr r2, r1
    li r1, 1874
    add r1, r1, r6
    swr r2, r1
    li r1, 1718
    add r1, r1, r6
    lwr r2, r1
    li r1, 1875
    add r1, r1, r6
    swr r2, r1
    li r1, 1719
    add r1, r1, r6
    lwr r2, r1
    li r1, 1876
    add r1, r1, r6
    swr r2, r1
    li r1, 1720
    add r1, r1, r6
    lwr r2, r1
    li r1, 1877
    add r1, r1, r6
    swr r2, r1
    li r1, 1721
    add r1, r1, r6
    lwr r2, r1
    li r1, 1878
    add r1, r1, r6
    swr r2, r1
    li r1, 1722
    add r1, r1, r6
    lwr r2, r1
    li r1, 1879
    add r1, r1, r6
    swr r2, r1
    li r1, 1723
    add r1, r1, r6
    lwr r2, r1
    li r1, 1880
    add r1, r1, r6
    swr r2, r1
    li r1, 1724
    add r1, r1, r6
    lwr r2, r1
    li r1, 1881
    add r1, r1, r6
    swr r2, r1
    li r1, 1725
    add r1, r1, r6
    lwr r2, r1
    li r1, 1882
    add r1, r1, r6
    swr r2, r1
    li r1, 1726
    add r1, r1, r6
    lwr r2, r1
    li r1, 1883
    add r1, r1, r6
    swr r2, r1
    li r1, 1727
    add r1, r1, r6
    lwr r2, r1
    li r1, 1884
    add r1, r1, r6
    swr r2, r1
    lui r1, 27
    add r1, r1, r6
    lwr r2, r1
    li r1, 1885
    add r1, r1, r6
    swr r2, r1
    li r1, 1729
    add r1, r1, r6
    lwr r2, r1
    li r1, 1886
    add r1, r1, r6
    swr r2, r1
    li r1, 1730
    add r1, r1, r6
    lwr r2, r1
    li r1, 1887
    add r1, r1, r6
    swr r2, r1
    li r1, 1731
    add r1, r1, r6
    lwr r2, r1
    li r1, 1888
    add r1, r1, r6
    swr r2, r1
    li r1, 1732
    add r1, r1, r6
    lwr r2, r1
    li r1, 1889
    add r1, r1, r6
    swr r2, r1
    li r1, 1733
    add r1, r1, r6
    lwr r2, r1
    li r1, 1890
    add r1, r1, r6
    swr r2, r1
    li r1, 1734
    add r1, r1, r6
    lwr r2, r1
    li r1, 1891
    add r1, r1, r6
    swr r2, r1
    li r1, 1735
    add r1, r1, r6
    lwr r2, r1
    li r1, 1892
    add r1, r1, r6
    swr r2, r1
    li r1, 1736
    add r1, r1, r6
    lwr r2, r1
    li r1, 1893
    add r1, r1, r6
    swr r2, r1
    li r1, 1737
    add r1, r1, r6
    lwr r2, r1
    li r1, 1894
    add r1, r1, r6
    swr r2, r1
    li r1, 1738
    add r1, r1, r6
    lwr r2, r1
    li r1, 1895
    add r1, r1, r6
    swr r2, r1
    li r1, 1739
    add r1, r1, r6
    lwr r2, r1
    li r1, 1896
    add r1, r1, r6
    swr r2, r1
    li r1, 1740
    add r1, r1, r6
    lwr r2, r1
    li r1, 1897
    add r1, r1, r6
    swr r2, r1
    li r1, 1741
    add r1, r1, r6
    lwr r2, r1
    li r1, 1898
    add r1, r1, r6
    swr r2, r1
    li r1, 1742
    add r1, r1, r6
    lwr r2, r1
    li r1, 1899
    add r1, r1, r6
    swr r2, r1
    li r1, 1743
    add r1, r1, r6
    lwr r2, r1
    li r1, 1900
    add r1, r1, r6
    swr r2, r1
    li r1, 1744
    add r1, r1, r6
    lwr r2, r1
    li r1, 1901
    add r1, r1, r6
    swr r2, r1
    li r1, 1745
    add r1, r1, r6
    lwr r2, r1
    li r1, 1902
    add r1, r1, r6
    swr r2, r1
    li r1, 1746
    add r1, r1, r6
    lwr r2, r1
    li r1, 1903
    add r1, r1, r6
    swr r2, r1
    li r1, 1747
    add r1, r1, r6
    lwr r2, r1
    li r1, 1904
    add r1, r1, r6
    swr r2, r1
    li r1, 1748
    add r1, r1, r6
    lwr r2, r1
    li r1, 1905
    add r1, r1, r6
    swr r2, r1
    li r1, 1749
    add r1, r1, r6
    lwr r2, r1
    li r1, 1906
    add r1, r1, r6
    swr r2, r1
    li r1, 1750
    add r1, r1, r6
    lwr r2, r1
    li r1, 1907
    add r1, r1, r6
    swr r2, r1
    li r1, 1751
    add r1, r1, r6
    lwr r2, r1
    li r1, 1908
    add r1, r1, r6
    swr r2, r1
    li r1, 1752
    add r1, r1, r6
    lwr r2, r1
    li r1, 1909
    add r1, r1, r6
    swr r2, r1
    li r1, 1753
    add r1, r1, r6
    lwr r2, r1
    li r1, 1910
    add r1, r1, r6
    swr r2, r1
    li r1, 1754
    add r1, r1, r6
    lwr r2, r1
    li r1, 1911
    add r1, r1, r6
    swr r2, r1
    li r1, 1755
    add r1, r1, r6
    lwr r2, r1
    li r1, 1912
    add r1, r1, r6
    swr r2, r1
    li r1, 1756
    add r1, r1, r6
    lwr r2, r1
    li r1, 1913
    add r1, r1, r6
    swr r2, r1
    li r1, 1757
    add r1, r1, r6
    lwr r2, r1
    li r1, 1914
    add r1, r1, r6
    swr r2, r1
    li r1, 1758
    add r1, r1, r6
    lwr r2, r1
    li r1, 1915
    add r1, r1, r6
    swr r2, r1
    li r1, 1759
    add r1, r1, r6
    lwr r2, r1
    li r1, 1916
    add r1, r1, r6
    swr r2, r1
    li r1, 1760
    add r1, r1, r6
    lwr r2, r1
    li r1, 1917
    add r1, r1, r6
    swr r2, r1
    li r1, 1761
    add r1, r1, r6
    lwr r2, r1
    li r1, 1918
    add r1, r1, r6
    swr r2, r1
    li r1, 1762
    add r1, r1, r6
    lwr r2, r1
    li r1, 1919
    add r1, r1, r6
    swr r2, r1
    li r1, 1763
    add r1, r1, r6
    lwr r2, r1
    lui r1, 30
    add r1, r1, r6
    swr r2, r1
    li r1, 1764
    add r1, r1, r6
    lwr r2, r1
    li r1, 1921
    add r1, r1, r6
    swr r2, r1
    li r1, 1765
    add r1, r1, r6
    lwr r2, r1
    li r1, 1922
    add r1, r1, r6
    swr r2, r1
    li r1, 1766
    add r1, r1, r6
    lwr r2, r1
    li r1, 1923
    add r1, r1, r6
    swr r2, r1
    li r1, 1767
    add r1, r1, r6
    lwr r2, r1
    li r1, 1924
    add r1, r1, r6
    swr r2, r1
    li r1, 1768
    add r1, r1, r6
    lwr r2, r1
    li r1, 1925
    add r1, r1, r6
    swr r2, r1
    li r1, 1769
    add r1, r1, r6
    lwr r2, r1
    li r1, 1926
    add r1, r1, r6
    swr r2, r1
    li r1, 1770
    add r1, r1, r6
    lwr r2, r1
    li r1, 1927
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_114
_B_main_183:
    li r1, 1162
    add r1, r1, r6
    lwr r2, r1
    li r1, 1771
    add r1, r1, r6
    swr r2, r1
    li r1, 153
    add r1, r1, r6
    lwr r2, r1
    li r1, 1772
    add r1, r1, r6
    swr r2, r1
    li r1, 1163
    add r1, r1, r6
    lwr r2, r1
    li r1, 1773
    add r1, r1, r6
    swr r2, r1
    li r1, 1164
    add r1, r1, r6
    lwr r2, r1
    li r1, 1774
    add r1, r1, r6
    swr r2, r1
    li r1, 329
    add r1, r1, r6
    lwr r2, r1
    li r1, 1775
    add r1, r1, r6
    swr r2, r1
    li r1, 331
    add r1, r1, r6
    lwr r2, r1
    li r1, 1776
    add r1, r1, r6
    swr r2, r1
    li r1, 333
    add r1, r1, r6
    lwr r2, r1
    li r1, 1777
    add r1, r1, r6
    swr r2, r1
    li r1, 335
    add r1, r1, r6
    lwr r2, r1
    li r1, 1778
    add r1, r1, r6
    swr r2, r1
    li r1, 337
    add r1, r1, r6
    lwr r2, r1
    li r1, 1779
    add r1, r1, r6
    swr r2, r1
    li r1, 339
    add r1, r1, r6
    lwr r2, r1
    li r1, 1780
    add r1, r1, r6
    swr r2, r1
    li r1, 341
    add r1, r1, r6
    lwr r2, r1
    li r1, 1781
    add r1, r1, r6
    swr r2, r1
    li r1, 343
    add r1, r1, r6
    lwr r2, r1
    li r1, 1782
    add r1, r1, r6
    swr r2, r1
    li r1, 345
    add r1, r1, r6
    lwr r2, r1
    li r1, 1783
    add r1, r1, r6
    swr r2, r1
    li r1, 347
    add r1, r1, r6
    lwr r2, r1
    li r1, 1784
    add r1, r1, r6
    swr r2, r1
    li r1, 351
    add r1, r1, r6
    lwr r2, r1
    li r1, 1785
    add r1, r1, r6
    swr r2, r1
    li r1, 353
    add r1, r1, r6
    lwr r2, r1
    li r1, 1786
    add r1, r1, r6
    swr r2, r1
    li r1, 355
    add r1, r1, r6
    lwr r2, r1
    li r1, 1787
    add r1, r1, r6
    swr r2, r1
    li r1, 357
    add r1, r1, r6
    lwr r2, r1
    li r1, 1788
    add r1, r1, r6
    swr r2, r1
    li r1, 359
    add r1, r1, r6
    lwr r2, r1
    li r1, 1789
    add r1, r1, r6
    swr r2, r1
    li r1, 361
    add r1, r1, r6
    lwr r2, r1
    li r1, 1790
    add r1, r1, r6
    swr r2, r1
    li r1, 363
    add r1, r1, r6
    lwr r2, r1
    li r1, 1791
    add r1, r1, r6
    swr r2, r1
    li r1, 365
    add r1, r1, r6
    lwr r2, r1
    lui r1, 28
    add r1, r1, r6
    swr r2, r1
    li r1, 367
    add r1, r1, r6
    lwr r2, r1
    li r1, 1793
    add r1, r1, r6
    swr r2, r1
    li r1, 369
    add r1, r1, r6
    lwr r2, r1
    li r1, 1794
    add r1, r1, r6
    swr r2, r1
    li r1, 373
    add r1, r1, r6
    lwr r2, r1
    li r1, 1795
    add r1, r1, r6
    swr r2, r1
    li r1, 375
    add r1, r1, r6
    lwr r2, r1
    li r1, 1796
    add r1, r1, r6
    swr r2, r1
    li r1, 377
    add r1, r1, r6
    lwr r2, r1
    li r1, 1797
    add r1, r1, r6
    swr r2, r1
    li r1, 379
    add r1, r1, r6
    lwr r2, r1
    li r1, 1798
    add r1, r1, r6
    swr r2, r1
    li r1, 381
    add r1, r1, r6
    lwr r2, r1
    li r1, 1799
    add r1, r1, r6
    swr r2, r1
    li r1, 383
    add r1, r1, r6
    lwr r2, r1
    li r1, 1800
    add r1, r1, r6
    swr r2, r1
    li r1, 385
    add r1, r1, r6
    lwr r2, r1
    li r1, 1801
    add r1, r1, r6
    swr r2, r1
    li r1, 387
    add r1, r1, r6
    lwr r2, r1
    li r1, 1802
    add r1, r1, r6
    swr r2, r1
    li r1, 389
    add r1, r1, r6
    lwr r2, r1
    li r1, 1803
    add r1, r1, r6
    swr r2, r1
    li r1, 391
    add r1, r1, r6
    lwr r2, r1
    li r1, 1804
    add r1, r1, r6
    swr r2, r1
    li r1, 395
    add r1, r1, r6
    lwr r2, r1
    li r1, 1805
    add r1, r1, r6
    swr r2, r1
    li r1, 397
    add r1, r1, r6
    lwr r2, r1
    li r1, 1806
    add r1, r1, r6
    swr r2, r1
    li r1, 399
    add r1, r1, r6
    lwr r2, r1
    li r1, 1807
    add r1, r1, r6
    swr r2, r1
    li r1, 401
    add r1, r1, r6
    lwr r2, r1
    li r1, 1808
    add r1, r1, r6
    swr r2, r1
    li r1, 403
    add r1, r1, r6
    lwr r2, r1
    li r1, 1809
    add r1, r1, r6
    swr r2, r1
    li r1, 152
    add r1, r1, r6
    lwr r2, r1
    li r1, 1810
    add r1, r1, r6
    swr r2, r1
    li r1, 151
    add r1, r1, r6
    lwr r2, r1
    li r1, 1811
    add r1, r1, r6
    swr r2, r1
    li r1, 1165
    add r1, r1, r6
    lwr r2, r1
    li r1, 1812
    add r1, r1, r6
    swr r2, r1
    li r1, 1166
    add r1, r1, r6
    lwr r2, r1
    li r1, 1813
    add r1, r1, r6
    swr r2, r1
    li r1, 1167
    add r1, r1, r6
    lwr r2, r1
    li r1, 1814
    add r1, r1, r6
    swr r2, r1
    li r1, 1168
    add r1, r1, r6
    lwr r2, r1
    li r1, 1815
    add r1, r1, r6
    swr r2, r1
    li r1, 1169
    add r1, r1, r6
    lwr r2, r1
    li r1, 1816
    add r1, r1, r6
    swr r2, r1
    li r1, 1170
    add r1, r1, r6
    lwr r2, r1
    li r1, 1817
    add r1, r1, r6
    swr r2, r1
    li r1, 1171
    add r1, r1, r6
    lwr r2, r1
    li r1, 1818
    add r1, r1, r6
    swr r2, r1
    li r1, 1172
    add r1, r1, r6
    lwr r2, r1
    li r1, 1819
    add r1, r1, r6
    swr r2, r1
    li r1, 1173
    add r1, r1, r6
    lwr r2, r1
    li r1, 1820
    add r1, r1, r6
    swr r2, r1
    li r1, 1174
    add r1, r1, r6
    lwr r2, r1
    li r1, 1821
    add r1, r1, r6
    swr r2, r1
    li r1, 1175
    add r1, r1, r6
    lwr r2, r1
    li r1, 1822
    add r1, r1, r6
    swr r2, r1
    li r1, 1176
    add r1, r1, r6
    lwr r2, r1
    li r1, 1823
    add r1, r1, r6
    swr r2, r1
    li r1, 1177
    add r1, r1, r6
    lwr r2, r1
    li r1, 1824
    add r1, r1, r6
    swr r2, r1
    li r1, 1178
    add r1, r1, r6
    lwr r2, r1
    li r1, 1825
    add r1, r1, r6
    swr r2, r1
    li r1, 1179
    add r1, r1, r6
    lwr r2, r1
    li r1, 1826
    add r1, r1, r6
    swr r2, r1
    li r1, 1180
    add r1, r1, r6
    lwr r2, r1
    li r1, 1827
    add r1, r1, r6
    swr r2, r1
    li r1, 1181
    add r1, r1, r6
    lwr r2, r1
    li r1, 1828
    add r1, r1, r6
    swr r2, r1
    li r1, 130
    add r1, r1, r6
    lwr r2, r1
    li r1, 1829
    add r1, r1, r6
    swr r2, r1
    li r1, 129
    add r1, r1, r6
    lwr r2, r1
    li r1, 1830
    add r1, r1, r6
    swr r2, r1
    li r1, 504
    add r1, r1, r6
    lwr r2, r1
    li r1, 1831
    add r1, r1, r6
    swr r2, r1
    li r1, 506
    add r1, r1, r6
    lwr r2, r1
    li r1, 1832
    add r1, r1, r6
    swr r2, r1
    li r1, 508
    add r1, r1, r6
    lwr r2, r1
    li r1, 1833
    add r1, r1, r6
    swr r2, r1
    li r1, 510
    add r1, r1, r6
    lwr r2, r1
    li r1, 1834
    add r1, r1, r6
    swr r2, r1
    lui r1, 8
    add r1, r1, r6
    lwr r2, r1
    li r1, 1835
    add r1, r1, r6
    swr r2, r1
    li r1, 514
    add r1, r1, r6
    lwr r2, r1
    li r1, 1836
    add r1, r1, r6
    swr r2, r1
    li r1, 516
    add r1, r1, r6
    lwr r2, r1
    li r1, 1837
    add r1, r1, r6
    swr r2, r1
    li r1, 520
    add r1, r1, r6
    lwr r2, r1
    li r1, 1838
    add r1, r1, r6
    swr r2, r1
    li r1, 522
    add r1, r1, r6
    lwr r2, r1
    li r1, 1839
    add r1, r1, r6
    swr r2, r1
    li r1, 524
    add r1, r1, r6
    lwr r2, r1
    li r1, 1840
    add r1, r1, r6
    swr r2, r1
    li r1, 526
    add r1, r1, r6
    lwr r2, r1
    li r1, 1841
    add r1, r1, r6
    swr r2, r1
    li r1, 528
    add r1, r1, r6
    lwr r2, r1
    li r1, 1842
    add r1, r1, r6
    swr r2, r1
    li r1, 530
    add r1, r1, r6
    lwr r2, r1
    li r1, 1843
    add r1, r1, r6
    swr r2, r1
    li r1, 532
    add r1, r1, r6
    lwr r2, r1
    li r1, 1844
    add r1, r1, r6
    swr r2, r1
    li r1, 534
    add r1, r1, r6
    lwr r2, r1
    li r1, 1845
    add r1, r1, r6
    swr r2, r1
    li r1, 536
    add r1, r1, r6
    lwr r2, r1
    li r1, 1846
    add r1, r1, r6
    swr r2, r1
    li r1, 538
    add r1, r1, r6
    lwr r2, r1
    li r1, 1847
    add r1, r1, r6
    swr r2, r1
    li r1, 542
    add r1, r1, r6
    lwr r2, r1
    li r1, 1848
    add r1, r1, r6
    swr r2, r1
    li r1, 544
    add r1, r1, r6
    lwr r2, r1
    li r1, 1849
    add r1, r1, r6
    swr r2, r1
    li r1, 546
    add r1, r1, r6
    lwr r2, r1
    li r1, 1850
    add r1, r1, r6
    swr r2, r1
    li r1, 548
    add r1, r1, r6
    lwr r2, r1
    li r1, 1851
    add r1, r1, r6
    swr r2, r1
    li r1, 550
    add r1, r1, r6
    lwr r2, r1
    li r1, 1852
    add r1, r1, r6
    swr r2, r1
    li r1, 552
    add r1, r1, r6
    lwr r2, r1
    li r1, 1853
    add r1, r1, r6
    swr r2, r1
    li r1, 554
    add r1, r1, r6
    lwr r2, r1
    li r1, 1854
    add r1, r1, r6
    swr r2, r1
    li r1, 556
    add r1, r1, r6
    lwr r2, r1
    li r1, 1855
    add r1, r1, r6
    swr r2, r1
    li r1, 558
    add r1, r1, r6
    lwr r2, r1
    lui r1, 29
    add r1, r1, r6
    swr r2, r1
    li r1, 560
    add r1, r1, r6
    lwr r2, r1
    li r1, 1857
    add r1, r1, r6
    swr r2, r1
    li r1, 564
    add r1, r1, r6
    lwr r2, r1
    li r1, 1858
    add r1, r1, r6
    swr r2, r1
    li r1, 566
    add r1, r1, r6
    lwr r2, r1
    li r1, 1859
    add r1, r1, r6
    swr r2, r1
    li r1, 568
    add r1, r1, r6
    lwr r2, r1
    li r1, 1860
    add r1, r1, r6
    swr r2, r1
    li r1, 570
    add r1, r1, r6
    lwr r2, r1
    li r1, 1861
    add r1, r1, r6
    swr r2, r1
    li r1, 572
    add r1, r1, r6
    lwr r2, r1
    li r1, 1862
    add r1, r1, r6
    swr r2, r1
    li r1, 574
    add r1, r1, r6
    lwr r2, r1
    li r1, 1863
    add r1, r1, r6
    swr r2, r1
    lui r1, 9
    add r1, r1, r6
    lwr r2, r1
    li r1, 1864
    add r1, r1, r6
    swr r2, r1
    li r1, 578
    add r1, r1, r6
    lwr r2, r1
    li r1, 1865
    add r1, r1, r6
    swr r2, r1
    li r1, 580
    add r1, r1, r6
    lwr r2, r1
    li r1, 1866
    add r1, r1, r6
    swr r2, r1
    li r1, 582
    add r1, r1, r6
    lwr r2, r1
    li r1, 1867
    add r1, r1, r6
    swr r2, r1
    li r1, 586
    add r1, r1, r6
    lwr r2, r1
    li r1, 1868
    add r1, r1, r6
    swr r2, r1
    li r1, 588
    add r1, r1, r6
    lwr r2, r1
    li r1, 1869
    add r1, r1, r6
    swr r2, r1
    li r1, 590
    add r1, r1, r6
    lwr r2, r1
    li r1, 1870
    add r1, r1, r6
    swr r2, r1
    li r1, 592
    add r1, r1, r6
    lwr r2, r1
    li r1, 1871
    add r1, r1, r6
    swr r2, r1
    li r1, 594
    add r1, r1, r6
    lwr r2, r1
    li r1, 1872
    add r1, r1, r6
    swr r2, r1
    li r1, 596
    add r1, r1, r6
    lwr r2, r1
    li r1, 1873
    add r1, r1, r6
    swr r2, r1
    li r1, 598
    add r1, r1, r6
    lwr r2, r1
    li r1, 1874
    add r1, r1, r6
    swr r2, r1
    li r1, 600
    add r1, r1, r6
    lwr r2, r1
    li r1, 1875
    add r1, r1, r6
    swr r2, r1
    li r1, 602
    add r1, r1, r6
    lwr r2, r1
    li r1, 1876
    add r1, r1, r6
    swr r2, r1
    li r1, 604
    add r1, r1, r6
    lwr r2, r1
    li r1, 1877
    add r1, r1, r6
    swr r2, r1
    li r1, 608
    add r1, r1, r6
    lwr r2, r1
    li r1, 1878
    add r1, r1, r6
    swr r2, r1
    li r1, 610
    add r1, r1, r6
    lwr r2, r1
    li r1, 1879
    add r1, r1, r6
    swr r2, r1
    li r1, 612
    add r1, r1, r6
    lwr r2, r1
    li r1, 1880
    add r1, r1, r6
    swr r2, r1
    li r1, 614
    add r1, r1, r6
    lwr r2, r1
    li r1, 1881
    add r1, r1, r6
    swr r2, r1
    li r1, 616
    add r1, r1, r6
    lwr r2, r1
    li r1, 1882
    add r1, r1, r6
    swr r2, r1
    li r1, 618
    add r1, r1, r6
    lwr r2, r1
    li r1, 1883
    add r1, r1, r6
    swr r2, r1
    li r1, 620
    add r1, r1, r6
    lwr r2, r1
    li r1, 1884
    add r1, r1, r6
    swr r2, r1
    li r1, 622
    add r1, r1, r6
    lwr r2, r1
    li r1, 1885
    add r1, r1, r6
    swr r2, r1
    li r1, 624
    add r1, r1, r6
    lwr r2, r1
    li r1, 1886
    add r1, r1, r6
    swr r2, r1
    li r1, 626
    add r1, r1, r6
    lwr r2, r1
    li r1, 1887
    add r1, r1, r6
    swr r2, r1
    li r1, 630
    add r1, r1, r6
    lwr r2, r1
    li r1, 1888
    add r1, r1, r6
    swr r2, r1
    li r1, 632
    add r1, r1, r6
    lwr r2, r1
    li r1, 1889
    add r1, r1, r6
    swr r2, r1
    li r1, 634
    add r1, r1, r6
    lwr r2, r1
    li r1, 1890
    add r1, r1, r6
    swr r2, r1
    li r1, 636
    add r1, r1, r6
    lwr r2, r1
    li r1, 1891
    add r1, r1, r6
    swr r2, r1
    li r1, 638
    add r1, r1, r6
    lwr r2, r1
    li r1, 1892
    add r1, r1, r6
    swr r2, r1
    lui r1, 10
    add r1, r1, r6
    lwr r2, r1
    li r1, 1893
    add r1, r1, r6
    swr r2, r1
    li r1, 642
    add r1, r1, r6
    lwr r2, r1
    li r1, 1894
    add r1, r1, r6
    swr r2, r1
    li r1, 644
    add r1, r1, r6
    lwr r2, r1
    li r1, 1895
    add r1, r1, r6
    swr r2, r1
    li r1, 646
    add r1, r1, r6
    lwr r2, r1
    li r1, 1896
    add r1, r1, r6
    swr r2, r1
    li r1, 648
    add r1, r1, r6
    lwr r2, r1
    li r1, 1897
    add r1, r1, r6
    swr r2, r1
    li r1, 652
    add r1, r1, r6
    lwr r2, r1
    li r1, 1898
    add r1, r1, r6
    swr r2, r1
    li r1, 654
    add r1, r1, r6
    lwr r2, r1
    li r1, 1899
    add r1, r1, r6
    swr r2, r1
    li r1, 656
    add r1, r1, r6
    lwr r2, r1
    li r1, 1900
    add r1, r1, r6
    swr r2, r1
    li r1, 658
    add r1, r1, r6
    lwr r2, r1
    li r1, 1901
    add r1, r1, r6
    swr r2, r1
    li r1, 660
    add r1, r1, r6
    lwr r2, r1
    li r1, 1902
    add r1, r1, r6
    swr r2, r1
    li r1, 662
    add r1, r1, r6
    lwr r2, r1
    li r1, 1903
    add r1, r1, r6
    swr r2, r1
    li r1, 664
    add r1, r1, r6
    lwr r2, r1
    li r1, 1904
    add r1, r1, r6
    swr r2, r1
    li r1, 666
    add r1, r1, r6
    lwr r2, r1
    li r1, 1905
    add r1, r1, r6
    swr r2, r1
    li r1, 668
    add r1, r1, r6
    lwr r2, r1
    li r1, 1906
    add r1, r1, r6
    swr r2, r1
    li r1, 670
    add r1, r1, r6
    lwr r2, r1
    li r1, 1907
    add r1, r1, r6
    swr r2, r1
    li r1, 674
    add r1, r1, r6
    lwr r2, r1
    li r1, 1908
    add r1, r1, r6
    swr r2, r1
    li r1, 676
    add r1, r1, r6
    lwr r2, r1
    li r1, 1909
    add r1, r1, r6
    swr r2, r1
    li r1, 678
    add r1, r1, r6
    lwr r2, r1
    li r1, 1910
    add r1, r1, r6
    swr r2, r1
    li r1, 680
    add r1, r1, r6
    lwr r2, r1
    li r1, 1911
    add r1, r1, r6
    swr r2, r1
    li r1, 682
    add r1, r1, r6
    lwr r2, r1
    li r1, 1912
    add r1, r1, r6
    swr r2, r1
    li r1, 684
    add r1, r1, r6
    lwr r2, r1
    li r1, 1913
    add r1, r1, r6
    swr r2, r1
    li r1, 686
    add r1, r1, r6
    lwr r2, r1
    li r1, 1914
    add r1, r1, r6
    swr r2, r1
    li r1, 688
    add r1, r1, r6
    lwr r2, r1
    li r1, 1915
    add r1, r1, r6
    swr r2, r1
    li r1, 690
    add r1, r1, r6
    lwr r2, r1
    li r1, 1916
    add r1, r1, r6
    swr r2, r1
    li r1, 692
    add r1, r1, r6
    lwr r2, r1
    li r1, 1917
    add r1, r1, r6
    swr r2, r1
    li r1, 696
    add r1, r1, r6
    lwr r2, r1
    li r1, 1918
    add r1, r1, r6
    swr r2, r1
    li r1, 698
    add r1, r1, r6
    lwr r2, r1
    li r1, 1919
    add r1, r1, r6
    swr r2, r1
    li r1, 700
    add r1, r1, r6
    lwr r2, r1
    lui r1, 30
    add r1, r1, r6
    swr r2, r1
    li r1, 702
    add r1, r1, r6
    lwr r2, r1
    li r1, 1921
    add r1, r1, r6
    swr r2, r1
    lui r1, 11
    add r1, r1, r6
    lwr r2, r1
    li r1, 1922
    add r1, r1, r6
    swr r2, r1
    li r1, 706
    add r1, r1, r6
    lwr r2, r1
    li r1, 1923
    add r1, r1, r6
    swr r2, r1
    li r1, 708
    add r1, r1, r6
    lwr r2, r1
    li r1, 1924
    add r1, r1, r6
    swr r2, r1
    li r1, 710
    add r1, r1, r6
    lwr r2, r1
    li r1, 1925
    add r1, r1, r6
    swr r2, r1
    li r1, 712
    add r1, r1, r6
    lwr r2, r1
    li r1, 1926
    add r1, r1, r6
    swr r2, r1
    li r1, 714
    add r1, r1, r6
    lwr r2, r1
    li r1, 1927
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_114
_B_main_184:
    li r1, 317
    add r1, r1, r6
    lwr r2, r1
    li r1, 922
    add r1, r1, r6
    swr r2, r1
    li r1, 1771
    add r1, r1, r6
    lwr r2, r1
    li r1, 923
    add r1, r1, r6
    swr r2, r1
    li r1, 1772
    add r1, r1, r6
    lwr r2, r1
    li r1, 924
    add r1, r1, r6
    swr r2, r1
    li r1, 323
    add r1, r1, r6
    lwr r2, r1
    li r1, 925
    add r1, r1, r6
    swr r2, r1
    li r1, 1773
    add r1, r1, r6
    lwr r2, r1
    li r1, 926
    add r1, r1, r6
    swr r2, r1
    li r1, 1774
    add r1, r1, r6
    lwr r2, r1
    li r1, 927
    add r1, r1, r6
    swr r2, r1
    li r1, 1775
    add r1, r1, r6
    lwr r2, r1
    li r1, 928
    add r1, r1, r6
    swr r2, r1
    li r1, 1776
    add r1, r1, r6
    lwr r2, r1
    li r1, 929
    add r1, r1, r6
    swr r2, r1
    li r1, 1777
    add r1, r1, r6
    lwr r2, r1
    li r1, 930
    add r1, r1, r6
    swr r2, r1
    li r1, 1778
    add r1, r1, r6
    lwr r2, r1
    li r1, 931
    add r1, r1, r6
    swr r2, r1
    li r1, 1779
    add r1, r1, r6
    lwr r2, r1
    li r1, 932
    add r1, r1, r6
    swr r2, r1
    li r1, 1780
    add r1, r1, r6
    lwr r2, r1
    li r1, 933
    add r1, r1, r6
    swr r2, r1
    li r1, 1781
    add r1, r1, r6
    lwr r2, r1
    li r1, 934
    add r1, r1, r6
    swr r2, r1
    li r1, 1782
    add r1, r1, r6
    lwr r2, r1
    li r1, 935
    add r1, r1, r6
    swr r2, r1
    li r1, 1783
    add r1, r1, r6
    lwr r2, r1
    li r1, 936
    add r1, r1, r6
    swr r2, r1
    li r1, 1784
    add r1, r1, r6
    lwr r2, r1
    li r1, 937
    add r1, r1, r6
    swr r2, r1
    li r1, 1785
    add r1, r1, r6
    lwr r2, r1
    li r1, 940
    add r1, r1, r6
    swr r2, r1
    li r1, 1786
    add r1, r1, r6
    lwr r2, r1
    li r1, 941
    add r1, r1, r6
    swr r2, r1
    li r1, 1787
    add r1, r1, r6
    lwr r2, r1
    li r1, 942
    add r1, r1, r6
    swr r2, r1
    li r1, 1788
    add r1, r1, r6
    lwr r2, r1
    li r1, 943
    add r1, r1, r6
    swr r2, r1
    li r1, 1789
    add r1, r1, r6
    lwr r2, r1
    li r1, 944
    add r1, r1, r6
    swr r2, r1
    li r1, 1790
    add r1, r1, r6
    lwr r2, r1
    li r1, 945
    add r1, r1, r6
    swr r2, r1
    li r1, 1791
    add r1, r1, r6
    lwr r2, r1
    li r1, 946
    add r1, r1, r6
    swr r2, r1
    lui r1, 28
    add r1, r1, r6
    lwr r2, r1
    li r1, 947
    add r1, r1, r6
    swr r2, r1
    li r1, 1793
    add r1, r1, r6
    lwr r2, r1
    li r1, 948
    add r1, r1, r6
    swr r2, r1
    li r1, 1794
    add r1, r1, r6
    lwr r2, r1
    li r1, 949
    add r1, r1, r6
    swr r2, r1
    li r1, 1795
    add r1, r1, r6
    lwr r2, r1
    li r1, 952
    add r1, r1, r6
    swr r2, r1
    li r1, 1796
    add r1, r1, r6
    lwr r2, r1
    li r1, 953
    add r1, r1, r6
    swr r2, r1
    li r1, 1797
    add r1, r1, r6
    lwr r2, r1
    li r1, 954
    add r1, r1, r6
    swr r2, r1
    li r1, 1798
    add r1, r1, r6
    lwr r2, r1
    li r1, 955
    add r1, r1, r6
    swr r2, r1
    li r1, 1799
    add r1, r1, r6
    lwr r2, r1
    li r1, 956
    add r1, r1, r6
    swr r2, r1
    li r1, 1800
    add r1, r1, r6
    lwr r2, r1
    li r1, 957
    add r1, r1, r6
    swr r2, r1
    li r1, 1801
    add r1, r1, r6
    lwr r2, r1
    li r1, 958
    add r1, r1, r6
    swr r2, r1
    li r1, 1802
    add r1, r1, r6
    lwr r2, r1
    li r1, 959
    add r1, r1, r6
    swr r2, r1
    li r1, 1803
    add r1, r1, r6
    lwr r2, r1
    lui r1, 15
    add r1, r1, r6
    swr r2, r1
    li r1, 1804
    add r1, r1, r6
    lwr r2, r1
    li r1, 961
    add r1, r1, r6
    swr r2, r1
    li r1, 1805
    add r1, r1, r6
    lwr r2, r1
    li r1, 964
    add r1, r1, r6
    swr r2, r1
    li r1, 1806
    add r1, r1, r6
    lwr r2, r1
    li r1, 965
    add r1, r1, r6
    swr r2, r1
    li r1, 1807
    add r1, r1, r6
    lwr r2, r1
    li r1, 966
    add r1, r1, r6
    swr r2, r1
    li r1, 1808
    add r1, r1, r6
    lwr r2, r1
    li r1, 967
    add r1, r1, r6
    swr r2, r1
    li r1, 1809
    add r1, r1, r6
    lwr r2, r1
    li r1, 968
    add r1, r1, r6
    swr r2, r1
    li r1, 1810
    add r1, r1, r6
    lwr r2, r1
    li r1, 969
    add r1, r1, r6
    swr r2, r1
    li r1, 1811
    add r1, r1, r6
    lwr r2, r1
    li r1, 970
    add r1, r1, r6
    swr r2, r1
    li r1, 1812
    add r1, r1, r6
    lwr r2, r1
    li r1, 971
    add r1, r1, r6
    swr r2, r1
    li r1, 1813
    add r1, r1, r6
    lwr r2, r1
    li r1, 972
    add r1, r1, r6
    swr r2, r1
    li r1, 1814
    add r1, r1, r6
    lwr r2, r1
    li r1, 973
    add r1, r1, r6
    swr r2, r1
    li r1, 1815
    add r1, r1, r6
    lwr r2, r1
    li r1, 976
    add r1, r1, r6
    swr r2, r1
    li r1, 1816
    add r1, r1, r6
    lwr r2, r1
    li r1, 977
    add r1, r1, r6
    swr r2, r1
    li r1, 1817
    add r1, r1, r6
    lwr r2, r1
    li r1, 978
    add r1, r1, r6
    swr r2, r1
    li r1, 1818
    add r1, r1, r6
    lwr r2, r1
    li r1, 979
    add r1, r1, r6
    swr r2, r1
    li r1, 1819
    add r1, r1, r6
    lwr r2, r1
    li r1, 980
    add r1, r1, r6
    swr r2, r1
    li r1, 1820
    add r1, r1, r6
    lwr r2, r1
    li r1, 981
    add r1, r1, r6
    swr r2, r1
    li r1, 1821
    add r1, r1, r6
    lwr r2, r1
    li r1, 982
    add r1, r1, r6
    swr r2, r1
    li r1, 1822
    add r1, r1, r6
    lwr r2, r1
    li r1, 983
    add r1, r1, r6
    swr r2, r1
    li r1, 1823
    add r1, r1, r6
    lwr r2, r1
    li r1, 984
    add r1, r1, r6
    swr r2, r1
    li r1, 1824
    add r1, r1, r6
    lwr r2, r1
    li r1, 985
    add r1, r1, r6
    swr r2, r1
    li r1, 1825
    add r1, r1, r6
    lwr r2, r1
    li r1, 987
    add r1, r1, r6
    swr r2, r1
    li r1, 1826
    add r1, r1, r6
    lwr r2, r1
    li r1, 988
    add r1, r1, r6
    swr r2, r1
    li r1, 1827
    add r1, r1, r6
    lwr r2, r1
    li r1, 989
    add r1, r1, r6
    swr r2, r1
    li r1, 1828
    add r1, r1, r6
    lwr r2, r1
    li r1, 990
    add r1, r1, r6
    swr r2, r1
    li r1, 1829
    add r1, r1, r6
    lwr r2, r1
    li r1, 991
    add r1, r1, r6
    swr r2, r1
    li r1, 1830
    add r1, r1, r6
    lwr r2, r1
    li r1, 992
    add r1, r1, r6
    swr r2, r1
    lui r1, 2
    add r1, r1, r6
    lwr r2, r1
    li r1, 993
    add r1, r1, r6
    swr r2, r1
    li r1, 127
    add r1, r1, r6
    lwr r2, r1
    li r1, 994
    add r1, r1, r6
    swr r2, r1
    li r1, 455
    add r1, r1, r6
    lwr r2, r1
    li r1, 995
    add r1, r1, r6
    swr r2, r1
    li r1, 457
    add r1, r1, r6
    lwr r2, r1
    li r1, 996
    add r1, r1, r6
    swr r2, r1
    li r1, 461
    add r1, r1, r6
    lwr r2, r1
    li r1, 998
    add r1, r1, r6
    swr r2, r1
    li r1, 463
    add r1, r1, r6
    lwr r2, r1
    li r1, 999
    add r1, r1, r6
    swr r2, r1
    li r1, 465
    add r1, r1, r6
    lwr r2, r1
    li r1, 1000
    add r1, r1, r6
    swr r2, r1
    li r1, 467
    add r1, r1, r6
    lwr r2, r1
    li r1, 1001
    add r1, r1, r6
    swr r2, r1
    li r1, 469
    add r1, r1, r6
    lwr r2, r1
    li r1, 1002
    add r1, r1, r6
    swr r2, r1
    li r1, 471
    add r1, r1, r6
    lwr r2, r1
    li r1, 1003
    add r1, r1, r6
    swr r2, r1
    li r1, 473
    add r1, r1, r6
    lwr r2, r1
    li r1, 1004
    add r1, r1, r6
    swr r2, r1
    li r1, 475
    add r1, r1, r6
    lwr r2, r1
    li r1, 1005
    add r1, r1, r6
    swr r2, r1
    li r1, 477
    add r1, r1, r6
    lwr r2, r1
    li r1, 1006
    add r1, r1, r6
    swr r2, r1
    li r1, 479
    add r1, r1, r6
    lwr r2, r1
    li r1, 1007
    add r1, r1, r6
    swr r2, r1
    li r1, 483
    add r1, r1, r6
    lwr r2, r1
    li r1, 1009
    add r1, r1, r6
    swr r2, r1
    li r1, 485
    add r1, r1, r6
    lwr r2, r1
    li r1, 1010
    add r1, r1, r6
    swr r2, r1
    li r1, 487
    add r1, r1, r6
    lwr r2, r1
    li r1, 1011
    add r1, r1, r6
    swr r2, r1
    li r1, 489
    add r1, r1, r6
    lwr r2, r1
    li r1, 1012
    add r1, r1, r6
    swr r2, r1
    li r1, 491
    add r1, r1, r6
    lwr r2, r1
    li r1, 1013
    add r1, r1, r6
    swr r2, r1
    li r1, 493
    add r1, r1, r6
    lwr r2, r1
    li r1, 1014
    add r1, r1, r6
    swr r2, r1
    li r1, 495
    add r1, r1, r6
    lwr r2, r1
    li r1, 1015
    add r1, r1, r6
    swr r2, r1
    li r1, 497
    add r1, r1, r6
    lwr r2, r1
    li r1, 1016
    add r1, r1, r6
    swr r2, r1
    li r1, 499
    add r1, r1, r6
    lwr r2, r1
    li r1, 1017
    add r1, r1, r6
    swr r2, r1
    li r1, 1831
    add r1, r1, r6
    lwr r2, r1
    li r1, 1020
    add r1, r1, r6
    swr r2, r1
    li r1, 1832
    add r1, r1, r6
    lwr r2, r1
    li r1, 1021
    add r1, r1, r6
    swr r2, r1
    li r1, 1833
    add r1, r1, r6
    lwr r2, r1
    li r1, 1022
    add r1, r1, r6
    swr r2, r1
    li r1, 1834
    add r1, r1, r6
    lwr r2, r1
    li r1, 1023
    add r1, r1, r6
    swr r2, r1
    li r1, 1835
    add r1, r1, r6
    lwr r2, r1
    lui r1, 16
    add r1, r1, r6
    swr r2, r1
    li r1, 1836
    add r1, r1, r6
    lwr r2, r1
    li r1, 1025
    add r1, r1, r6
    swr r2, r1
    li r1, 1837
    add r1, r1, r6
    lwr r2, r1
    li r1, 1026
    add r1, r1, r6
    swr r2, r1
    li r1, 1838
    add r1, r1, r6
    lwr r2, r1
    li r1, 1028
    add r1, r1, r6
    swr r2, r1
    li r1, 1839
    add r1, r1, r6
    lwr r2, r1
    li r1, 1029
    add r1, r1, r6
    swr r2, r1
    li r1, 1840
    add r1, r1, r6
    lwr r2, r1
    li r1, 1030
    add r1, r1, r6
    swr r2, r1
    li r1, 1841
    add r1, r1, r6
    lwr r2, r1
    li r1, 1031
    add r1, r1, r6
    swr r2, r1
    li r1, 1842
    add r1, r1, r6
    lwr r2, r1
    li r1, 1032
    add r1, r1, r6
    swr r2, r1
    li r1, 1843
    add r1, r1, r6
    lwr r2, r1
    li r1, 1033
    add r1, r1, r6
    swr r2, r1
    li r1, 1844
    add r1, r1, r6
    lwr r2, r1
    li r1, 1034
    add r1, r1, r6
    swr r2, r1
    li r1, 1845
    add r1, r1, r6
    lwr r2, r1
    li r1, 1035
    add r1, r1, r6
    swr r2, r1
    li r1, 1846
    add r1, r1, r6
    lwr r2, r1
    li r1, 1036
    add r1, r1, r6
    swr r2, r1
    li r1, 1847
    add r1, r1, r6
    lwr r2, r1
    li r1, 1037
    add r1, r1, r6
    swr r2, r1
    li r1, 1848
    add r1, r1, r6
    lwr r2, r1
    li r1, 1039
    add r1, r1, r6
    swr r2, r1
    li r1, 1849
    add r1, r1, r6
    lwr r2, r1
    li r1, 1040
    add r1, r1, r6
    swr r2, r1
    li r1, 1850
    add r1, r1, r6
    lwr r2, r1
    li r1, 1041
    add r1, r1, r6
    swr r2, r1
    li r1, 1851
    add r1, r1, r6
    lwr r2, r1
    li r1, 1042
    add r1, r1, r6
    swr r2, r1
    li r1, 1852
    add r1, r1, r6
    lwr r2, r1
    li r1, 1043
    add r1, r1, r6
    swr r2, r1
    li r1, 1853
    add r1, r1, r6
    lwr r2, r1
    li r1, 1044
    add r1, r1, r6
    swr r2, r1
    li r1, 1854
    add r1, r1, r6
    lwr r2, r1
    li r1, 1045
    add r1, r1, r6
    swr r2, r1
    li r1, 1855
    add r1, r1, r6
    lwr r2, r1
    li r1, 1046
    add r1, r1, r6
    swr r2, r1
    lui r1, 29
    add r1, r1, r6
    lwr r2, r1
    li r1, 1047
    add r1, r1, r6
    swr r2, r1
    li r1, 1857
    add r1, r1, r6
    lwr r2, r1
    li r1, 1048
    add r1, r1, r6
    swr r2, r1
    li r1, 1858
    add r1, r1, r6
    lwr r2, r1
    li r1, 1050
    add r1, r1, r6
    swr r2, r1
    li r1, 1859
    add r1, r1, r6
    lwr r2, r1
    li r1, 1051
    add r1, r1, r6
    swr r2, r1
    li r1, 1860
    add r1, r1, r6
    lwr r2, r1
    li r1, 1052
    add r1, r1, r6
    swr r2, r1
    li r1, 1861
    add r1, r1, r6
    lwr r2, r1
    li r1, 1053
    add r1, r1, r6
    swr r2, r1
    li r1, 1862
    add r1, r1, r6
    lwr r2, r1
    li r1, 1054
    add r1, r1, r6
    swr r2, r1
    li r1, 1863
    add r1, r1, r6
    lwr r2, r1
    li r1, 1055
    add r1, r1, r6
    swr r2, r1
    li r1, 1864
    add r1, r1, r6
    lwr r2, r1
    li r1, 1056
    add r1, r1, r6
    swr r2, r1
    li r1, 1865
    add r1, r1, r6
    lwr r2, r1
    li r1, 1057
    add r1, r1, r6
    swr r2, r1
    li r1, 1866
    add r1, r1, r6
    lwr r2, r1
    li r1, 1058
    add r1, r1, r6
    swr r2, r1
    li r1, 1867
    add r1, r1, r6
    lwr r2, r1
    li r1, 1059
    add r1, r1, r6
    swr r2, r1
    li r1, 1868
    add r1, r1, r6
    lwr r2, r1
    li r1, 1061
    add r1, r1, r6
    swr r2, r1
    li r1, 1869
    add r1, r1, r6
    lwr r2, r1
    li r1, 1062
    add r1, r1, r6
    swr r2, r1
    li r1, 1870
    add r1, r1, r6
    lwr r2, r1
    li r1, 1063
    add r1, r1, r6
    swr r2, r1
    li r1, 1871
    add r1, r1, r6
    lwr r2, r1
    li r1, 1064
    add r1, r1, r6
    swr r2, r1
    li r1, 1872
    add r1, r1, r6
    lwr r2, r1
    li r1, 1065
    add r1, r1, r6
    swr r2, r1
    li r1, 1873
    add r1, r1, r6
    lwr r2, r1
    li r1, 1066
    add r1, r1, r6
    swr r2, r1
    li r1, 1874
    add r1, r1, r6
    lwr r2, r1
    li r1, 1067
    add r1, r1, r6
    swr r2, r1
    li r1, 1875
    add r1, r1, r6
    lwr r2, r1
    li r1, 1068
    add r1, r1, r6
    swr r2, r1
    li r1, 1876
    add r1, r1, r6
    lwr r2, r1
    li r1, 1069
    add r1, r1, r6
    swr r2, r1
    li r1, 1877
    add r1, r1, r6
    lwr r2, r1
    li r1, 1070
    add r1, r1, r6
    swr r2, r1
    li r1, 1878
    add r1, r1, r6
    lwr r2, r1
    li r1, 1072
    add r1, r1, r6
    swr r2, r1
    li r1, 1879
    add r1, r1, r6
    lwr r2, r1
    li r1, 1073
    add r1, r1, r6
    swr r2, r1
    li r1, 1880
    add r1, r1, r6
    lwr r2, r1
    li r1, 1074
    add r1, r1, r6
    swr r2, r1
    li r1, 1881
    add r1, r1, r6
    lwr r2, r1
    li r1, 1075
    add r1, r1, r6
    swr r2, r1
    li r1, 1882
    add r1, r1, r6
    lwr r2, r1
    li r1, 1076
    add r1, r1, r6
    swr r2, r1
    li r1, 1883
    add r1, r1, r6
    lwr r2, r1
    li r1, 1077
    add r1, r1, r6
    swr r2, r1
    li r1, 1884
    add r1, r1, r6
    lwr r2, r1
    li r1, 1078
    add r1, r1, r6
    swr r2, r1
    li r1, 1885
    add r1, r1, r6
    lwr r2, r1
    li r1, 1079
    add r1, r1, r6
    swr r2, r1
    li r1, 1886
    add r1, r1, r6
    lwr r2, r1
    li r1, 1080
    add r1, r1, r6
    swr r2, r1
    li r1, 1887
    add r1, r1, r6
    lwr r2, r1
    li r1, 1081
    add r1, r1, r6
    swr r2, r1
    li r1, 1888
    add r1, r1, r6
    lwr r2, r1
    li r1, 1082
    add r1, r1, r6
    swr r2, r1
    li r1, 1889
    add r1, r1, r6
    lwr r2, r1
    li r1, 1083
    add r1, r1, r6
    swr r2, r1
    li r1, 1890
    add r1, r1, r6
    lwr r2, r1
    li r1, 1084
    add r1, r1, r6
    swr r2, r1
    li r1, 1891
    add r1, r1, r6
    lwr r2, r1
    li r1, 1085
    add r1, r1, r6
    swr r2, r1
    li r1, 1892
    add r1, r1, r6
    lwr r2, r1
    li r1, 1086
    add r1, r1, r6
    swr r2, r1
    li r1, 1893
    add r1, r1, r6
    lwr r2, r1
    li r1, 1087
    add r1, r1, r6
    swr r2, r1
    li r1, 1894
    add r1, r1, r6
    lwr r2, r1
    lui r1, 17
    add r1, r1, r6
    swr r2, r1
    li r1, 1895
    add r1, r1, r6
    lwr r2, r1
    li r1, 1089
    add r1, r1, r6
    swr r2, r1
    li r1, 1896
    add r1, r1, r6
    lwr r2, r1
    li r1, 1090
    add r1, r1, r6
    swr r2, r1
    li r1, 1897
    add r1, r1, r6
    lwr r2, r1
    li r1, 1091
    add r1, r1, r6
    swr r2, r1
    li r1, 1898
    add r1, r1, r6
    lwr r2, r1
    li r1, 1092
    add r1, r1, r6
    swr r2, r1
    li r1, 1899
    add r1, r1, r6
    lwr r2, r1
    li r1, 1093
    add r1, r1, r6
    swr r2, r1
    li r1, 1900
    add r1, r1, r6
    lwr r2, r1
    li r1, 1094
    add r1, r1, r6
    swr r2, r1
    li r1, 1901
    add r1, r1, r6
    lwr r2, r1
    li r1, 1095
    add r1, r1, r6
    swr r2, r1
    li r1, 1902
    add r1, r1, r6
    lwr r2, r1
    li r1, 1096
    add r1, r1, r6
    swr r2, r1
    li r1, 1903
    add r1, r1, r6
    lwr r2, r1
    li r1, 1097
    add r1, r1, r6
    swr r2, r1
    li r1, 1904
    add r1, r1, r6
    lwr r2, r1
    li r1, 1098
    add r1, r1, r6
    swr r2, r1
    li r1, 1905
    add r1, r1, r6
    lwr r2, r1
    li r1, 1099
    add r1, r1, r6
    swr r2, r1
    li r1, 1906
    add r1, r1, r6
    lwr r2, r1
    li r1, 1100
    add r1, r1, r6
    swr r2, r1
    li r1, 1907
    add r1, r1, r6
    lwr r2, r1
    li r1, 1101
    add r1, r1, r6
    swr r2, r1
    li r1, 1908
    add r1, r1, r6
    lwr r2, r1
    li r1, 1102
    add r1, r1, r6
    swr r2, r1
    li r1, 1909
    add r1, r1, r6
    lwr r2, r1
    li r1, 1103
    add r1, r1, r6
    swr r2, r1
    li r1, 1910
    add r1, r1, r6
    lwr r2, r1
    li r1, 1104
    add r1, r1, r6
    swr r2, r1
    li r1, 1911
    add r1, r1, r6
    lwr r2, r1
    li r1, 1105
    add r1, r1, r6
    swr r2, r1
    li r1, 1912
    add r1, r1, r6
    lwr r2, r1
    li r1, 1106
    add r1, r1, r6
    swr r2, r1
    li r1, 1913
    add r1, r1, r6
    lwr r2, r1
    li r1, 1107
    add r1, r1, r6
    swr r2, r1
    li r1, 1914
    add r1, r1, r6
    lwr r2, r1
    li r1, 1108
    add r1, r1, r6
    swr r2, r1
    li r1, 1915
    add r1, r1, r6
    lwr r2, r1
    li r1, 1109
    add r1, r1, r6
    swr r2, r1
    li r1, 1916
    add r1, r1, r6
    lwr r2, r1
    li r1, 1110
    add r1, r1, r6
    swr r2, r1
    li r1, 1917
    add r1, r1, r6
    lwr r2, r1
    li r1, 1111
    add r1, r1, r6
    swr r2, r1
    li r1, 1918
    add r1, r1, r6
    lwr r2, r1
    li r1, 1113
    add r1, r1, r6
    swr r2, r1
    li r1, 1919
    add r1, r1, r6
    lwr r2, r1
    li r1, 1114
    add r1, r1, r6
    swr r2, r1
    lui r1, 30
    add r1, r1, r6
    lwr r2, r1
    li r1, 1115
    add r1, r1, r6
    swr r2, r1
    li r1, 1921
    add r1, r1, r6
    lwr r2, r1
    li r1, 1116
    add r1, r1, r6
    swr r2, r1
    li r1, 1922
    add r1, r1, r6
    lwr r2, r1
    li r1, 1117
    add r1, r1, r6
    swr r2, r1
    li r1, 1923
    add r1, r1, r6
    lwr r2, r1
    li r1, 1118
    add r1, r1, r6
    swr r2, r1
    li r1, 1924
    add r1, r1, r6
    lwr r2, r1
    li r1, 1119
    add r1, r1, r6
    swr r2, r1
    li r1, 1925
    add r1, r1, r6
    lwr r2, r1
    li r1, 1120
    add r1, r1, r6
    swr r2, r1
    li r1, 1926
    add r1, r1, r6
    lwr r2, r1
    li r1, 1121
    add r1, r1, r6
    swr r2, r1
    li r1, 1927
    add r1, r1, r6
    lwr r2, r1
    li r1, 1122
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_115
_B_main_185:
    li r1, 123
    add r1, r1, r6
    lwr r2, r1
    li r1, 922
    add r1, r1, r6
    swr r2, r1
    li r1, 319
    add r1, r1, r6
    lwr r2, r1
    li r1, 923
    add r1, r1, r6
    swr r2, r1
    li r1, 104
    add r1, r1, r6
    lwr r2, r1
    li r1, 924
    add r1, r1, r6
    swr r2, r1
    li r1, 115
    add r1, r1, r6
    lwr r2, r1
    li r1, 925
    add r1, r1, r6
    swr r2, r1
    li r1, 325
    add r1, r1, r6
    lwr r2, r1
    li r1, 926
    add r1, r1, r6
    swr r2, r1
    li r1, 327
    add r1, r1, r6
    lwr r2, r1
    li r1, 927
    add r1, r1, r6
    swr r2, r1
    li r1, 329
    add r1, r1, r6
    lwr r2, r1
    li r1, 928
    add r1, r1, r6
    swr r2, r1
    li r1, 331
    add r1, r1, r6
    lwr r2, r1
    li r1, 929
    add r1, r1, r6
    swr r2, r1
    li r1, 333
    add r1, r1, r6
    lwr r2, r1
    li r1, 930
    add r1, r1, r6
    swr r2, r1
    li r1, 335
    add r1, r1, r6
    lwr r2, r1
    li r1, 931
    add r1, r1, r6
    swr r2, r1
    li r1, 337
    add r1, r1, r6
    lwr r2, r1
    li r1, 932
    add r1, r1, r6
    swr r2, r1
    li r1, 339
    add r1, r1, r6
    lwr r2, r1
    li r1, 933
    add r1, r1, r6
    swr r2, r1
    li r1, 341
    add r1, r1, r6
    lwr r2, r1
    li r1, 934
    add r1, r1, r6
    swr r2, r1
    li r1, 343
    add r1, r1, r6
    lwr r2, r1
    li r1, 935
    add r1, r1, r6
    swr r2, r1
    li r1, 345
    add r1, r1, r6
    lwr r2, r1
    li r1, 936
    add r1, r1, r6
    swr r2, r1
    li r1, 347
    add r1, r1, r6
    lwr r2, r1
    li r1, 937
    add r1, r1, r6
    swr r2, r1
    li r1, 351
    add r1, r1, r6
    lwr r2, r1
    li r1, 940
    add r1, r1, r6
    swr r2, r1
    li r1, 353
    add r1, r1, r6
    lwr r2, r1
    li r1, 941
    add r1, r1, r6
    swr r2, r1
    li r1, 355
    add r1, r1, r6
    lwr r2, r1
    li r1, 942
    add r1, r1, r6
    swr r2, r1
    li r1, 357
    add r1, r1, r6
    lwr r2, r1
    li r1, 943
    add r1, r1, r6
    swr r2, r1
    li r1, 359
    add r1, r1, r6
    lwr r2, r1
    li r1, 944
    add r1, r1, r6
    swr r2, r1
    li r1, 361
    add r1, r1, r6
    lwr r2, r1
    li r1, 945
    add r1, r1, r6
    swr r2, r1
    li r1, 363
    add r1, r1, r6
    lwr r2, r1
    li r1, 946
    add r1, r1, r6
    swr r2, r1
    li r1, 365
    add r1, r1, r6
    lwr r2, r1
    li r1, 947
    add r1, r1, r6
    swr r2, r1
    li r1, 367
    add r1, r1, r6
    lwr r2, r1
    li r1, 948
    add r1, r1, r6
    swr r2, r1
    li r1, 369
    add r1, r1, r6
    lwr r2, r1
    li r1, 949
    add r1, r1, r6
    swr r2, r1
    li r1, 373
    add r1, r1, r6
    lwr r2, r1
    li r1, 952
    add r1, r1, r6
    swr r2, r1
    li r1, 375
    add r1, r1, r6
    lwr r2, r1
    li r1, 953
    add r1, r1, r6
    swr r2, r1
    li r1, 377
    add r1, r1, r6
    lwr r2, r1
    li r1, 954
    add r1, r1, r6
    swr r2, r1
    li r1, 379
    add r1, r1, r6
    lwr r2, r1
    li r1, 955
    add r1, r1, r6
    swr r2, r1
    li r1, 381
    add r1, r1, r6
    lwr r2, r1
    li r1, 956
    add r1, r1, r6
    swr r2, r1
    li r1, 383
    add r1, r1, r6
    lwr r2, r1
    li r1, 957
    add r1, r1, r6
    swr r2, r1
    li r1, 385
    add r1, r1, r6
    lwr r2, r1
    li r1, 958
    add r1, r1, r6
    swr r2, r1
    li r1, 387
    add r1, r1, r6
    lwr r2, r1
    li r1, 959
    add r1, r1, r6
    swr r2, r1
    li r1, 389
    add r1, r1, r6
    lwr r2, r1
    lui r1, 15
    add r1, r1, r6
    swr r2, r1
    li r1, 391
    add r1, r1, r6
    lwr r2, r1
    li r1, 961
    add r1, r1, r6
    swr r2, r1
    li r1, 395
    add r1, r1, r6
    lwr r2, r1
    li r1, 964
    add r1, r1, r6
    swr r2, r1
    li r1, 397
    add r1, r1, r6
    lwr r2, r1
    li r1, 965
    add r1, r1, r6
    swr r2, r1
    li r1, 399
    add r1, r1, r6
    lwr r2, r1
    li r1, 966
    add r1, r1, r6
    swr r2, r1
    li r1, 401
    add r1, r1, r6
    lwr r2, r1
    li r1, 967
    add r1, r1, r6
    swr r2, r1
    li r1, 403
    add r1, r1, r6
    lwr r2, r1
    li r1, 968
    add r1, r1, r6
    swr r2, r1
    li r1, 405
    add r1, r1, r6
    lwr r2, r1
    li r1, 969
    add r1, r1, r6
    swr r2, r1
    li r1, 407
    add r1, r1, r6
    lwr r2, r1
    li r1, 970
    add r1, r1, r6
    swr r2, r1
    li r1, 409
    add r1, r1, r6
    lwr r2, r1
    li r1, 971
    add r1, r1, r6
    swr r2, r1
    li r1, 411
    add r1, r1, r6
    lwr r2, r1
    li r1, 972
    add r1, r1, r6
    swr r2, r1
    li r1, 413
    add r1, r1, r6
    lwr r2, r1
    li r1, 973
    add r1, r1, r6
    swr r2, r1
    li r1, 417
    add r1, r1, r6
    lwr r2, r1
    li r1, 976
    add r1, r1, r6
    swr r2, r1
    li r1, 419
    add r1, r1, r6
    lwr r2, r1
    li r1, 977
    add r1, r1, r6
    swr r2, r1
    li r1, 421
    add r1, r1, r6
    lwr r2, r1
    li r1, 978
    add r1, r1, r6
    swr r2, r1
    li r1, 423
    add r1, r1, r6
    lwr r2, r1
    li r1, 979
    add r1, r1, r6
    swr r2, r1
    li r1, 425
    add r1, r1, r6
    lwr r2, r1
    li r1, 980
    add r1, r1, r6
    swr r2, r1
    li r1, 427
    add r1, r1, r6
    lwr r2, r1
    li r1, 981
    add r1, r1, r6
    swr r2, r1
    li r1, 429
    add r1, r1, r6
    lwr r2, r1
    li r1, 982
    add r1, r1, r6
    swr r2, r1
    li r1, 431
    add r1, r1, r6
    lwr r2, r1
    li r1, 983
    add r1, r1, r6
    swr r2, r1
    li r1, 433
    add r1, r1, r6
    lwr r2, r1
    li r1, 984
    add r1, r1, r6
    swr r2, r1
    li r1, 435
    add r1, r1, r6
    lwr r2, r1
    li r1, 985
    add r1, r1, r6
    swr r2, r1
    li r1, 439
    add r1, r1, r6
    lwr r2, r1
    li r1, 987
    add r1, r1, r6
    swr r2, r1
    li r1, 441
    add r1, r1, r6
    lwr r2, r1
    li r1, 988
    add r1, r1, r6
    swr r2, r1
    li r1, 443
    add r1, r1, r6
    lwr r2, r1
    li r1, 989
    add r1, r1, r6
    swr r2, r1
    li r1, 445
    add r1, r1, r6
    lwr r2, r1
    li r1, 990
    add r1, r1, r6
    swr r2, r1
    li r1, 447
    add r1, r1, r6
    lwr r2, r1
    li r1, 991
    add r1, r1, r6
    swr r2, r1
    li r1, 449
    add r1, r1, r6
    lwr r2, r1
    li r1, 992
    add r1, r1, r6
    swr r2, r1
    li r1, 451
    add r1, r1, r6
    lwr r2, r1
    li r1, 993
    add r1, r1, r6
    swr r2, r1
    li r1, 453
    add r1, r1, r6
    lwr r2, r1
    li r1, 994
    add r1, r1, r6
    swr r2, r1
    li r1, 1156
    add r1, r1, r6
    lwr r2, r1
    li r1, 995
    add r1, r1, r6
    swr r2, r1
    li r1, 1157
    add r1, r1, r6
    lwr r2, r1
    li r1, 996
    add r1, r1, r6
    swr r2, r1
    li r1, 1158
    add r1, r1, r6
    lwr r2, r1
    li r1, 998
    add r1, r1, r6
    swr r2, r1
    li r1, 1159
    add r1, r1, r6
    lwr r2, r1
    li r1, 999
    add r1, r1, r6
    swr r2, r1
    li r1, 1160
    add r1, r1, r6
    lwr r2, r1
    li r1, 1000
    add r1, r1, r6
    swr r2, r1
    li r1, 1161
    add r1, r1, r6
    lwr r2, r1
    li r1, 1001
    add r1, r1, r6
    swr r2, r1
    li r1, 119
    add r1, r1, r6
    lwr r2, r1
    li r1, 1002
    add r1, r1, r6
    swr r2, r1
    li r1, 118
    add r1, r1, r6
    lwr r2, r1
    li r1, 1003
    add r1, r1, r6
    swr r2, r1
    li r1, 1155
    add r1, r1, r6
    lwr r2, r1
    li r1, 1004
    add r1, r1, r6
    swr r2, r1
    li r1, 1147
    add r1, r1, r6
    lwr r2, r1
    li r1, 1005
    add r1, r1, r6
    swr r2, r1
    li r1, 1148
    add r1, r1, r6
    lwr r2, r1
    li r1, 1006
    add r1, r1, r6
    swr r2, r1
    li r1, 1149
    add r1, r1, r6
    lwr r2, r1
    li r1, 1007
    add r1, r1, r6
    swr r2, r1
    li r1, 1150
    add r1, r1, r6
    lwr r2, r1
    li r1, 1009
    add r1, r1, r6
    swr r2, r1
    li r1, 1151
    add r1, r1, r6
    lwr r2, r1
    li r1, 1010
    add r1, r1, r6
    swr r2, r1
    lui r1, 18
    add r1, r1, r6
    lwr r2, r1
    li r1, 1011
    add r1, r1, r6
    swr r2, r1
    li r1, 105
    add r1, r1, r6
    lwr r2, r1
    li r1, 1012
    add r1, r1, r6
    swr r2, r1
    li r1, 103
    add r1, r1, r6
    lwr r2, r1
    li r1, 1013
    add r1, r1, r6
    swr r2, r1
    li r1, 1145
    add r1, r1, r6
    lwr r2, r1
    li r1, 1014
    add r1, r1, r6
    swr r2, r1
    li r1, 1146
    add r1, r1, r6
    lwr r2, r1
    li r1, 1015
    add r1, r1, r6
    swr r2, r1
    li r1, 97
    add r1, r1, r6
    lwr r2, r1
    li r1, 1016
    add r1, r1, r6
    swr r2, r1
    li r1, 96
    add r1, r1, r6
    lwr r2, r1
    li r1, 1017
    add r1, r1, r6
    swr r2, r1
    li r1, 504
    add r1, r1, r6
    lwr r2, r1
    li r1, 1020
    add r1, r1, r6
    swr r2, r1
    li r1, 506
    add r1, r1, r6
    lwr r2, r1
    li r1, 1021
    add r1, r1, r6
    swr r2, r1
    li r1, 508
    add r1, r1, r6
    lwr r2, r1
    li r1, 1022
    add r1, r1, r6
    swr r2, r1
    li r1, 510
    add r1, r1, r6
    lwr r2, r1
    li r1, 1023
    add r1, r1, r6
    swr r2, r1
    lui r1, 8
    add r1, r1, r6
    lwr r2, r1
    lui r1, 16
    add r1, r1, r6
    swr r2, r1
    li r1, 514
    add r1, r1, r6
    lwr r2, r1
    li r1, 1025
    add r1, r1, r6
    swr r2, r1
    li r1, 516
    add r1, r1, r6
    lwr r2, r1
    li r1, 1026
    add r1, r1, r6
    swr r2, r1
    li r1, 520
    add r1, r1, r6
    lwr r2, r1
    li r1, 1028
    add r1, r1, r6
    swr r2, r1
    li r1, 522
    add r1, r1, r6
    lwr r2, r1
    li r1, 1029
    add r1, r1, r6
    swr r2, r1
    li r1, 524
    add r1, r1, r6
    lwr r2, r1
    li r1, 1030
    add r1, r1, r6
    swr r2, r1
    li r1, 526
    add r1, r1, r6
    lwr r2, r1
    li r1, 1031
    add r1, r1, r6
    swr r2, r1
    li r1, 528
    add r1, r1, r6
    lwr r2, r1
    li r1, 1032
    add r1, r1, r6
    swr r2, r1
    li r1, 530
    add r1, r1, r6
    lwr r2, r1
    li r1, 1033
    add r1, r1, r6
    swr r2, r1
    li r1, 532
    add r1, r1, r6
    lwr r2, r1
    li r1, 1034
    add r1, r1, r6
    swr r2, r1
    li r1, 534
    add r1, r1, r6
    lwr r2, r1
    li r1, 1035
    add r1, r1, r6
    swr r2, r1
    li r1, 536
    add r1, r1, r6
    lwr r2, r1
    li r1, 1036
    add r1, r1, r6
    swr r2, r1
    li r1, 538
    add r1, r1, r6
    lwr r2, r1
    li r1, 1037
    add r1, r1, r6
    swr r2, r1
    li r1, 542
    add r1, r1, r6
    lwr r2, r1
    li r1, 1039
    add r1, r1, r6
    swr r2, r1
    li r1, 544
    add r1, r1, r6
    lwr r2, r1
    li r1, 1040
    add r1, r1, r6
    swr r2, r1
    li r1, 546
    add r1, r1, r6
    lwr r2, r1
    li r1, 1041
    add r1, r1, r6
    swr r2, r1
    li r1, 548
    add r1, r1, r6
    lwr r2, r1
    li r1, 1042
    add r1, r1, r6
    swr r2, r1
    li r1, 550
    add r1, r1, r6
    lwr r2, r1
    li r1, 1043
    add r1, r1, r6
    swr r2, r1
    li r1, 552
    add r1, r1, r6
    lwr r2, r1
    li r1, 1044
    add r1, r1, r6
    swr r2, r1
    li r1, 554
    add r1, r1, r6
    lwr r2, r1
    li r1, 1045
    add r1, r1, r6
    swr r2, r1
    li r1, 556
    add r1, r1, r6
    lwr r2, r1
    li r1, 1046
    add r1, r1, r6
    swr r2, r1
    li r1, 558
    add r1, r1, r6
    lwr r2, r1
    li r1, 1047
    add r1, r1, r6
    swr r2, r1
    li r1, 560
    add r1, r1, r6
    lwr r2, r1
    li r1, 1048
    add r1, r1, r6
    swr r2, r1
    li r1, 564
    add r1, r1, r6
    lwr r2, r1
    li r1, 1050
    add r1, r1, r6
    swr r2, r1
    li r1, 566
    add r1, r1, r6
    lwr r2, r1
    li r1, 1051
    add r1, r1, r6
    swr r2, r1
    li r1, 568
    add r1, r1, r6
    lwr r2, r1
    li r1, 1052
    add r1, r1, r6
    swr r2, r1
    li r1, 570
    add r1, r1, r6
    lwr r2, r1
    li r1, 1053
    add r1, r1, r6
    swr r2, r1
    li r1, 572
    add r1, r1, r6
    lwr r2, r1
    li r1, 1054
    add r1, r1, r6
    swr r2, r1
    li r1, 574
    add r1, r1, r6
    lwr r2, r1
    li r1, 1055
    add r1, r1, r6
    swr r2, r1
    lui r1, 9
    add r1, r1, r6
    lwr r2, r1
    li r1, 1056
    add r1, r1, r6
    swr r2, r1
    li r1, 578
    add r1, r1, r6
    lwr r2, r1
    li r1, 1057
    add r1, r1, r6
    swr r2, r1
    li r1, 580
    add r1, r1, r6
    lwr r2, r1
    li r1, 1058
    add r1, r1, r6
    swr r2, r1
    li r1, 582
    add r1, r1, r6
    lwr r2, r1
    li r1, 1059
    add r1, r1, r6
    swr r2, r1
    li r1, 586
    add r1, r1, r6
    lwr r2, r1
    li r1, 1061
    add r1, r1, r6
    swr r2, r1
    li r1, 588
    add r1, r1, r6
    lwr r2, r1
    li r1, 1062
    add r1, r1, r6
    swr r2, r1
    li r1, 590
    add r1, r1, r6
    lwr r2, r1
    li r1, 1063
    add r1, r1, r6
    swr r2, r1
    li r1, 592
    add r1, r1, r6
    lwr r2, r1
    li r1, 1064
    add r1, r1, r6
    swr r2, r1
    li r1, 594
    add r1, r1, r6
    lwr r2, r1
    li r1, 1065
    add r1, r1, r6
    swr r2, r1
    li r1, 596
    add r1, r1, r6
    lwr r2, r1
    li r1, 1066
    add r1, r1, r6
    swr r2, r1
    li r1, 598
    add r1, r1, r6
    lwr r2, r1
    li r1, 1067
    add r1, r1, r6
    swr r2, r1
    li r1, 600
    add r1, r1, r6
    lwr r2, r1
    li r1, 1068
    add r1, r1, r6
    swr r2, r1
    li r1, 602
    add r1, r1, r6
    lwr r2, r1
    li r1, 1069
    add r1, r1, r6
    swr r2, r1
    li r1, 604
    add r1, r1, r6
    lwr r2, r1
    li r1, 1070
    add r1, r1, r6
    swr r2, r1
    li r1, 608
    add r1, r1, r6
    lwr r2, r1
    li r1, 1072
    add r1, r1, r6
    swr r2, r1
    li r1, 610
    add r1, r1, r6
    lwr r2, r1
    li r1, 1073
    add r1, r1, r6
    swr r2, r1
    li r1, 612
    add r1, r1, r6
    lwr r2, r1
    li r1, 1074
    add r1, r1, r6
    swr r2, r1
    li r1, 614
    add r1, r1, r6
    lwr r2, r1
    li r1, 1075
    add r1, r1, r6
    swr r2, r1
    li r1, 616
    add r1, r1, r6
    lwr r2, r1
    li r1, 1076
    add r1, r1, r6
    swr r2, r1
    li r1, 618
    add r1, r1, r6
    lwr r2, r1
    li r1, 1077
    add r1, r1, r6
    swr r2, r1
    li r1, 620
    add r1, r1, r6
    lwr r2, r1
    li r1, 1078
    add r1, r1, r6
    swr r2, r1
    li r1, 622
    add r1, r1, r6
    lwr r2, r1
    li r1, 1079
    add r1, r1, r6
    swr r2, r1
    li r1, 624
    add r1, r1, r6
    lwr r2, r1
    li r1, 1080
    add r1, r1, r6
    swr r2, r1
    li r1, 626
    add r1, r1, r6
    lwr r2, r1
    li r1, 1081
    add r1, r1, r6
    swr r2, r1
    li r1, 630
    add r1, r1, r6
    lwr r2, r1
    li r1, 1082
    add r1, r1, r6
    swr r2, r1
    li r1, 632
    add r1, r1, r6
    lwr r2, r1
    li r1, 1083
    add r1, r1, r6
    swr r2, r1
    li r1, 634
    add r1, r1, r6
    lwr r2, r1
    li r1, 1084
    add r1, r1, r6
    swr r2, r1
    li r1, 636
    add r1, r1, r6
    lwr r2, r1
    li r1, 1085
    add r1, r1, r6
    swr r2, r1
    li r1, 638
    add r1, r1, r6
    lwr r2, r1
    li r1, 1086
    add r1, r1, r6
    swr r2, r1
    lui r1, 10
    add r1, r1, r6
    lwr r2, r1
    li r1, 1087
    add r1, r1, r6
    swr r2, r1
    li r1, 642
    add r1, r1, r6
    lwr r2, r1
    lui r1, 17
    add r1, r1, r6
    swr r2, r1
    li r1, 644
    add r1, r1, r6
    lwr r2, r1
    li r1, 1089
    add r1, r1, r6
    swr r2, r1
    li r1, 646
    add r1, r1, r6
    lwr r2, r1
    li r1, 1090
    add r1, r1, r6
    swr r2, r1
    li r1, 648
    add r1, r1, r6
    lwr r2, r1
    li r1, 1091
    add r1, r1, r6
    swr r2, r1
    li r1, 652
    add r1, r1, r6
    lwr r2, r1
    li r1, 1092
    add r1, r1, r6
    swr r2, r1
    li r1, 654
    add r1, r1, r6
    lwr r2, r1
    li r1, 1093
    add r1, r1, r6
    swr r2, r1
    li r1, 656
    add r1, r1, r6
    lwr r2, r1
    li r1, 1094
    add r1, r1, r6
    swr r2, r1
    li r1, 658
    add r1, r1, r6
    lwr r2, r1
    li r1, 1095
    add r1, r1, r6
    swr r2, r1
    li r1, 660
    add r1, r1, r6
    lwr r2, r1
    li r1, 1096
    add r1, r1, r6
    swr r2, r1
    li r1, 662
    add r1, r1, r6
    lwr r2, r1
    li r1, 1097
    add r1, r1, r6
    swr r2, r1
    li r1, 664
    add r1, r1, r6
    lwr r2, r1
    li r1, 1098
    add r1, r1, r6
    swr r2, r1
    li r1, 666
    add r1, r1, r6
    lwr r2, r1
    li r1, 1099
    add r1, r1, r6
    swr r2, r1
    li r1, 668
    add r1, r1, r6
    lwr r2, r1
    li r1, 1100
    add r1, r1, r6
    swr r2, r1
    li r1, 670
    add r1, r1, r6
    lwr r2, r1
    li r1, 1101
    add r1, r1, r6
    swr r2, r1
    li r1, 674
    add r1, r1, r6
    lwr r2, r1
    li r1, 1102
    add r1, r1, r6
    swr r2, r1
    li r1, 676
    add r1, r1, r6
    lwr r2, r1
    li r1, 1103
    add r1, r1, r6
    swr r2, r1
    li r1, 678
    add r1, r1, r6
    lwr r2, r1
    li r1, 1104
    add r1, r1, r6
    swr r2, r1
    li r1, 680
    add r1, r1, r6
    lwr r2, r1
    li r1, 1105
    add r1, r1, r6
    swr r2, r1
    li r1, 682
    add r1, r1, r6
    lwr r2, r1
    li r1, 1106
    add r1, r1, r6
    swr r2, r1
    li r1, 684
    add r1, r1, r6
    lwr r2, r1
    li r1, 1107
    add r1, r1, r6
    swr r2, r1
    li r1, 686
    add r1, r1, r6
    lwr r2, r1
    li r1, 1108
    add r1, r1, r6
    swr r2, r1
    li r1, 688
    add r1, r1, r6
    lwr r2, r1
    li r1, 1109
    add r1, r1, r6
    swr r2, r1
    li r1, 690
    add r1, r1, r6
    lwr r2, r1
    li r1, 1110
    add r1, r1, r6
    swr r2, r1
    li r1, 692
    add r1, r1, r6
    lwr r2, r1
    li r1, 1111
    add r1, r1, r6
    swr r2, r1
    li r1, 696
    add r1, r1, r6
    lwr r2, r1
    li r1, 1113
    add r1, r1, r6
    swr r2, r1
    li r1, 698
    add r1, r1, r6
    lwr r2, r1
    li r1, 1114
    add r1, r1, r6
    swr r2, r1
    li r1, 700
    add r1, r1, r6
    lwr r2, r1
    li r1, 1115
    add r1, r1, r6
    swr r2, r1
    li r1, 702
    add r1, r1, r6
    lwr r2, r1
    li r1, 1116
    add r1, r1, r6
    swr r2, r1
    lui r1, 11
    add r1, r1, r6
    lwr r2, r1
    li r1, 1117
    add r1, r1, r6
    swr r2, r1
    li r1, 706
    add r1, r1, r6
    lwr r2, r1
    li r1, 1118
    add r1, r1, r6
    swr r2, r1
    li r1, 708
    add r1, r1, r6
    lwr r2, r1
    li r1, 1119
    add r1, r1, r6
    swr r2, r1
    li r1, 710
    add r1, r1, r6
    lwr r2, r1
    li r1, 1120
    add r1, r1, r6
    swr r2, r1
    li r1, 712
    add r1, r1, r6
    lwr r2, r1
    li r1, 1121
    add r1, r1, r6
    swr r2, r1
    li r1, 714
    add r1, r1, r6
    lwr r2, r1
    li r1, 1122
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_115
_B_main_186:
    li r1, 70
    add r1, r1, r6
    lwr r2, r1
    li r1, 321
    add r1, r1, r6
    swr r2, r1
    li r1, 939
    add r1, r1, r6
    lwr r2, r1
    li r1, 349
    add r1, r1, r6
    swr r2, r1
    li r1, 951
    add r1, r1, r6
    lwr r2, r1
    li r1, 371
    add r1, r1, r6
    swr r2, r1
    li r1, 963
    add r1, r1, r6
    lwr r2, r1
    li r1, 393
    add r1, r1, r6
    swr r2, r1
    li r1, 975
    add r1, r1, r6
    lwr r2, r1
    li r1, 415
    add r1, r1, r6
    swr r2, r1
    li r1, 71
    add r1, r1, r6
    lwr r2, r1
    li r1, 437
    add r1, r1, r6
    swr r2, r1
    li r1, 69
    add r1, r1, r6
    lwr r2, r1
    li r1, 459
    add r1, r1, r6
    swr r2, r1
    li r1, 76
    add r1, r1, r6
    lwr r2, r1
    li r1, 481
    add r1, r1, r6
    swr r2, r1
    li r1, 81
    add r1, r1, r6
    lwr r2, r1
    li r1, 694
    add r1, r1, r6
    swr r2, r1
    li r1, 80
    add r1, r1, r6
    lwr r2, r1
    li r1, 716
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_117
_B_main_187:
    li r1, 67
    add r1, r1, r6
    lwr r2, r1
    li r1, 321
    add r1, r1, r6
    swr r2, r1
    li r1, 938
    add r1, r1, r6
    lwr r2, r1
    li r1, 349
    add r1, r1, r6
    swr r2, r1
    li r1, 950
    add r1, r1, r6
    lwr r2, r1
    li r1, 371
    add r1, r1, r6
    swr r2, r1
    li r1, 962
    add r1, r1, r6
    lwr r2, r1
    li r1, 393
    add r1, r1, r6
    swr r2, r1
    li r1, 974
    add r1, r1, r6
    lwr r2, r1
    li r1, 415
    add r1, r1, r6
    swr r2, r1
    li r1, 986
    add r1, r1, r6
    lwr r2, r1
    li r1, 437
    add r1, r1, r6
    swr r2, r1
    li r1, 997
    add r1, r1, r6
    lwr r2, r1
    li r1, 459
    add r1, r1, r6
    swr r2, r1
    li r1, 1008
    add r1, r1, r6
    lwr r2, r1
    li r1, 481
    add r1, r1, r6
    swr r2, r1
    li r1, 1112
    add r1, r1, r6
    lwr r2, r1
    li r1, 694
    add r1, r1, r6
    swr r2, r1
    li r1, 1123
    add r1, r1, r6
    lwr r2, r1
    li r1, 716
    add r1, r1, r6
    swr r2, r1
    clrt
    bf _B_main_117
_epi_main:
    li r1, 1928
    add r6, r6, r1
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

; rcc: runtime library (auto-included)
%include "itoa.s"

; rcc: lib/librcc.s (integer multiply/divide/modulo)
%include "librcc.s"

    .section data
stk:
    .fill 16
sp:
    .word 0
