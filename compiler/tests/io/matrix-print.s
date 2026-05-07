; rcc-generated assembly
%define RCC_CODE_BASE 0o22
%define RCC_DATA_BASE 0o0
%define RCC_STACK_TOP 0o7770

    .org 0o0
MATRIX_A:
    .word 1, 2, 3, 4, 5, 6, 7, 8, 9
MATRIX_B:
    .word 9, 8, 7, 6, 5, 4, 3, 2, 1
%include "crt0.s"


putchar:
    subi r6, 1
    swr r5, r6
    subi r6, 5
    and r1, r6, r7
    swr r2, r1
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
_L_while_0:
    li r1, 4088
    lwr r2, r1
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    sub r0, r0, r2
    bt _L_putchar_not_zero_28
    li r2, 1
    sub r0, r0, r7
    bt _L_putchar_not_end_28
_L_putchar_not_zero_28:
    li r2, 0
_L_putchar_not_end_28:
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    sub r0, r0, r2
    bf _L_endwhile_1
    li r1, _L_while_0
    jalr r0, r1
_L_endwhile_1:
;; *buf=c
    and r1, r6, r7
    lwr r2, r1
    li r1, 4090
    swr r2, r1
    li r1, _epi_putchar
    jalr r0, r1
_epi_putchar:
    addi r6, 5
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

puts:
    subi r6, 1
    swr r5, r6
    subi r6, 4
    and r1, r6, r7
    swr r2, r1
;; while (*s!=0)
_L_while_4:
    and r1, r6, r7
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
    bf _L_endwhile_5
;; putchar(*s)
    and r1, r6, r7
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    li r1, putchar
    jalr r5, r1
;; s=s+1
    and r1, r6, r7
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    and r1, r6, r7
    swr r2, r1
    li r1, _L_while_4
    jalr r0, r1
_L_endwhile_5:
;; putchar(10)
    li r2, 10
    li r1, putchar
    jalr r5, r1
    li r1, _epi_puts
    jalr r0, r1
_epi_puts:
    addi r6, 4
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

exit:
    subi r6, 1
    swr r5, r6
    subi r6, 1
    and r1, r6, r7
    swr r2, r1
;; (void)code
    halt
    li r1, _epi_exit
    jalr r0, r1
_epi_exit:
    addi r6, 1
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

itoa:
    subi r6, 1
    swr r5, r6
    subi r6, 34
    and r1, r6, r7
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    swr r3, r1
;; int* p = ...
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
;; int neg = ...
    and r1, r6, r7
    lwr r3, r1
    and r2, r0, r0
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    rol r2, r0
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
;; if (neg)
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    sub r0, r0, r2
    bf _L_endif_10
;; n=-n
    and r1, r6, r7
    lwr r2, r1
    sub r2, r0, r2
    and r1, r6, r7
    addi r1, 5
    swr r2, r1
    and r1, r6, r7
    addi r1, 5
    lwr r2, r1
    and r1, r6, r7
    swr r2, r1
_L_endif_10:
;; if (n==0)
    and r1, r6, r7
    lwr r3, r1
    and r2, r0, r0
    sub r1, r3, r2
    sub r0, r0, r1
    bt _L_else_11
;; *p++=48
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 7
    swr r2, r1
    and r1, r6, r7
    addi r1, 7
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    li r2, 48
    and r1, r6, r7
    addi r1, 6
    lwr r1, r1
    swr r2, r1
    li r1, _L_endif_12
    jalr r0, r1
_L_else_11:
;; int* start = ...
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    and r1, r6, r7
    addi r1, 8
    swr r2, r1
;; while (n)
_L_while_13:
    and r1, r6, r7
    lwr r2, r1
    sub r0, r0, r2
    bf _L_endwhile_14
;; *p++=48+n%10
    and r1, r6, r7
    lwr r3, r1
    li r2, 10
    sub r0, r0, r2
    bf _L_itoa_mod_done_107
    and r1, r3, r7
    rol r1, r1
    rol r4, r0
    subi r6, 1
    swr r4, r6
    sub r0, r0, r4
    bf _L_itoa_mod_npos_107
    sub r3, r0, r3
_L_itoa_mod_npos_107:
    and r1, r2, r7
    rol r1, r1
    bf _L_itoa_mod_dpos_107
    sub r2, r0, r2
_L_itoa_mod_dpos_107:
    and r4, r3, r7
    and r1, r0, r0
_L_itoa_udiv_loop_123:
    sub r0, r4, r2
    bt _L_itoa_udiv_end_123
    sub r4, r4, r2
    addi r1, 1
    sub r0, r0, r7
    bt _L_itoa_udiv_loop_123
_L_itoa_udiv_end_123:
    and r1, r6, r7
    lwr r1, r1
    addi r6, 1
    sub r0, r0, r1
    bf _L_itoa_mod_rpos_107
    sub r4, r0, r4
_L_itoa_mod_rpos_107:
    and r2, r4, r7
_L_itoa_mod_done_107:
    and r1, r6, r7
    addi r1, 9
    swr r2, r1
    li r3, 48
    and r1, r6, r7
    addi r1, 9
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    and r1, r6, r7
    addi r1, 11
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 12
    swr r2, r1
    and r1, r6, r7
    addi r1, 12
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    and r1, r6, r7
    addi r1, 10
    lwr r2, r1
    and r1, r6, r7
    addi r1, 11
    lwr r1, r1
    swr r2, r1
;; n=n/10
    and r1, r6, r7
    lwr r3, r1
    li r2, 10
    sub r0, r0, r2
    bf _L_itoa_div_done_184
    and r1, r3, r7
    rol r1, r1
    rol r4, r0
    subi r6, 1
    swr r4, r6
    and r1, r2, r7
    rol r1, r1
    rol r4, r0
    subi r6, 1
    swr r4, r6
    and r1, r6, r7
    addi r1, 1
    lwr r4, r1
    sub r0, r0, r4
    bf _L_itoa_div_npos_184
    sub r3, r0, r3
_L_itoa_div_npos_184:
    and r1, r6, r7
    lwr r4, r1
    sub r0, r0, r4
    bf _L_itoa_div_dpos_184
    sub r2, r0, r2
_L_itoa_div_dpos_184:
    and r4, r3, r7
    and r1, r0, r0
_L_itoa_udiv_loop_209:
    sub r0, r4, r2
    bt _L_itoa_udiv_end_209
    sub r4, r4, r2
    addi r1, 1
    sub r0, r0, r7
    bt _L_itoa_udiv_loop_209
_L_itoa_udiv_end_209:
    and r2, r1, r7
    and r1, r6, r7
    lwr r1, r1
    addi r6, 1
    and r4, r6, r7
    lwr r4, r4
    addi r6, 1
    add r1, r1, r4
    subi r1, 1
    sub r0, r0, r1
    bt _L_itoa_div_done_184
    sub r2, r0, r2
_L_itoa_div_done_184:
    and r1, r6, r7
    addi r1, 13
    swr r2, r1
    and r1, r6, r7
    addi r1, 13
    lwr r2, r1
    and r1, r6, r7
    swr r2, r1
    li r1, _L_while_13
    jalr r0, r1
_L_endwhile_14:
;; int* end = ...
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    and r1, r6, r7
    addi r1, 14
    swr r2, r1
    and r1, r6, r7
    addi r1, 14
    lwr r2, r1
    and r1, r6, r7
    addi r1, 15
    swr r2, r1
;; while (start<end)
_L_while_15:
    and r1, r6, r7
    addi r1, 8
    lwr r3, r1
    and r1, r6, r7
    addi r1, 15
    lwr r2, r1
    sub r1, r3, r2
    bf _L_endwhile_16
;; int tmp = ...
    and r1, r6, r7
    addi r1, 8
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 16
    swr r2, r1
    and r1, r6, r7
    addi r1, 16
    lwr r2, r1
    and r1, r6, r7
    addi r1, 17
    swr r2, r1
;; *start++=*end
    and r1, r6, r7
    addi r1, 15
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 18
    swr r2, r1
    and r1, r6, r7
    addi r1, 8
    lwr r2, r1
    and r1, r6, r7
    addi r1, 19
    swr r2, r1
    and r1, r6, r7
    addi r1, 8
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 20
    swr r2, r1
    and r1, r6, r7
    addi r1, 20
    lwr r2, r1
    and r1, r6, r7
    addi r1, 8
    swr r2, r1
    and r1, r6, r7
    addi r1, 18
    lwr r2, r1
    and r1, r6, r7
    addi r1, 19
    lwr r1, r1
    swr r2, r1
;; *end--=tmp
    and r1, r6, r7
    addi r1, 15
    lwr r2, r1
    and r1, r6, r7
    addi r1, 21
    swr r2, r1
    and r1, r6, r7
    addi r1, 15
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    and r1, r6, r7
    addi r1, 22
    swr r2, r1
    and r1, r6, r7
    addi r1, 22
    lwr r2, r1
    and r1, r6, r7
    addi r1, 15
    swr r2, r1
    and r1, r6, r7
    addi r1, 17
    lwr r2, r1
    and r1, r6, r7
    addi r1, 21
    lwr r1, r1
    swr r2, r1
    li r1, _L_while_15
    jalr r0, r1
_L_endwhile_16:
_L_endif_12:
;; if (neg)
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    sub r0, r0, r2
    bf _L_endif_17
;; int len = ...
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    sub r2, r3, r2
    and r1, r6, r7
    addi r1, 23
    swr r2, r1
    and r1, r6, r7
    addi r1, 23
    lwr r2, r1
    and r1, r6, r7
    addi r1, 24
    swr r2, r1
;; int i
;; for (...; i>0; ...)
    and r1, r6, r7
    addi r1, 23
    lwr r2, r1
    and r1, r6, r7
    addi r1, 25
    swr r2, r1
_L_for_18:
    and r1, r6, r7
    addi r1, 25
    lwr r3, r1
    and r2, r0, r0
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r2, r3
    bf _L_endfor_20
;; buf[i]=buf[i-1]
    and r1, r6, r7
    addi r1, 25
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    and r1, r6, r7
    addi r1, 26
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r3, r1
    and r1, r6, r7
    addi r1, 26
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 27
    swr r2, r1
    and r1, r6, r7
    addi r1, 27
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 28
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r3, r1
    and r1, r6, r7
    addi r1, 25
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 29
    swr r2, r1
    and r1, r6, r7
    addi r1, 28
    lwr r2, r1
    and r1, r6, r7
    addi r1, 29
    lwr r1, r1
    swr r2, r1
_L_forcont_19:
    and r1, r6, r7
    addi r1, 25
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    and r1, r6, r7
    addi r1, 30
    swr r2, r1
    and r1, r6, r7
    addi r1, 30
    lwr r2, r1
    and r1, r6, r7
    addi r1, 25
    swr r2, r1
    li r1, _L_for_18
    jalr r0, r1
_L_endfor_20:
;; buf[0]=45
    and r1, r6, r7
    addi r1, 1
    lwr r3, r1
    and r2, r0, r0
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 31
    swr r2, r1
    li r2, 45
    and r1, r6, r7
    addi r1, 31
    lwr r1, r1
    swr r2, r1
;; p++
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    and r1, r6, r7
    addi r1, 32
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 33
    swr r2, r1
    and r1, r6, r7
    addi r1, 33
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
_L_endif_17:
;; *p=0
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 2
    lwr r1, r1
    swr r2, r1
;; return buf
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    li r1, _epi_itoa
    jalr r0, r1
_epi_itoa:
    addi r6, 34
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

print_cell:
    subi r6, 1
    swr r5, r6
    subi r6, 14
    and r1, r6, r7
    swr r2, r1
;; int[8] buf
;; int* p
;; p=itoa(v,buf)
    and r1, r6, r7
    lwr r2, r1
    and r1, r6, r7
    addi r1, 1
    and r3, r1, r7
    li r1, itoa
    jalr r5, r1
    and r1, r6, r7
    addi r1, 9
    swr r2, r1
    and r1, r6, r7
    addi r1, 9
    lwr r2, r1
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
;; while (*p)
_L_while_21:
    and r1, r6, r7
    addi r1, 10
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 11
    swr r2, r1
    and r1, r6, r7
    addi r1, 11
    lwr r2, r1
    sub r0, r0, r2
    bf _L_endwhile_22
;; putchar(*p)
    and r1, r6, r7
    addi r1, 10
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 12
    swr r2, r1
    and r1, r6, r7
    addi r1, 12
    lwr r2, r1
    li r1, putchar
    jalr r5, r1
;; p=p+1
    and r1, r6, r7
    addi r1, 10
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 13
    swr r2, r1
    and r1, r6, r7
    addi r1, 13
    lwr r2, r1
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    li r1, _L_while_21
    jalr r0, r1
_L_endwhile_22:
;; putchar(32)
    li r2, 32
    li r1, putchar
    jalr r5, r1
;; putchar(32)
    li r2, 32
    li r1, putchar
    jalr r5, r1
    li r1, _epi_print_cell
    jalr r0, r1
_epi_print_cell:
    addi r6, 14
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

print_mat_rows:
    subi r6, 1
    swr r5, r6
    subi r6, 9
    and r1, r6, r7
    swr r2, r1
;; int r
;; int c
;; for (...; r<3; ...)
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
_L_for_23:
    and r1, r6, r7
    addi r1, 1
    lwr r3, r1
    li r2, 3
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    bf _L_endfor_25
;; putchar(32)
    li r2, 32
    li r1, putchar
    jalr r5, r1
;; putchar(32)
    li r2, 32
    li r1, putchar
    jalr r5, r1
;; for (...; c<3; ...)
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
_L_for_26:
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    li r2, 3
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    bf _L_endfor_28
;; print_cell(m[r*3+c])
    and r1, r6, r7
    addi r1, 1
    lwr r3, r1
    li r2, 3
    and r1, r0, r0
_L_print_mat_rows_mul_loop_52:
    sub r0, r0, r2
    bf _L_print_mat_rows_mul_end_52
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_print_mat_rows_mul_loop_52
_L_print_mat_rows_mul_end_52:
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    and r1, r6, r7
    addi r1, 3
    lwr r3, r1
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
    and r1, r6, r7
    lwr r3, r1
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 5
    swr r2, r1
    and r1, r6, r7
    addi r1, 5
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
    and r1, r6, r7
    addi r1, 6
    lwr r2, r1
    li r1, print_cell
    jalr r5, r1
_L_forcont_27:
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 7
    swr r2, r1
    and r1, r6, r7
    addi r1, 7
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    li r1, _L_for_26
    jalr r0, r1
_L_endfor_28:
;; putchar(10)
    li r2, 10
    li r1, putchar
    jalr r5, r1
_L_forcont_24:
    and r1, r6, r7
    addi r1, 1
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
    addi r1, 1
    swr r2, r1
    li r1, _L_for_23
    jalr r0, r1
_L_endfor_25:
    li r1, _epi_print_mat_rows
    jalr r0, r1
_epi_print_mat_rows:
    addi r6, 9
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

mat_add_flat:
    subi r6, 1
    swr r5, r6
    subi r6, 12
    and r1, r6, r7
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    swr r3, r1
    and r1, r6, r7
    addi r1, 2
    swr r4, r1
    and r1, r6, r7
    addi r1, 13
    lwr r2, r1
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
;; int i
;; for (...; i<n; ...)
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
_L_for_29:
    and r1, r6, r7
    addi r1, 4
    lwr r3, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    bf _L_endfor_31
;; out[i]=a[i]+b[i]
    and r1, r6, r7
    lwr r3, r1
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 5
    swr r2, r1
    and r1, r6, r7
    addi r1, 5
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r3, r1
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 7
    swr r2, r1
    and r1, r6, r7
    addi r1, 7
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 8
    swr r2, r1
    and r1, r6, r7
    addi r1, 6
    lwr r3, r1
    and r1, r6, r7
    addi r1, 8
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 9
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    and r1, r6, r7
    addi r1, 9
    lwr r2, r1
    and r1, r6, r7
    addi r1, 10
    lwr r1, r1
    swr r2, r1
_L_forcont_30:
    and r1, r6, r7
    addi r1, 4
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 11
    swr r2, r1
    and r1, r6, r7
    addi r1, 11
    lwr r2, r1
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
    li r1, _L_for_29
    jalr r0, r1
_L_endfor_31:
    li r1, _epi_mat_add_flat
    jalr r0, r1
_epi_mat_add_flat:
    addi r6, 12
    lwr r5, r6
    addi r6, 1
    addi r6, 1
    jalr r0, r5

mat_mul_flat:
    subi r6, 1
    swr r5, r6
    subi r6, 24
    and r1, r6, r7
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    swr r3, r1
    and r1, r6, r7
    addi r1, 2
    swr r4, r1
    and r1, r6, r7
    addi r1, 25
    lwr r2, r1
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
;; int i
;; int j
;; int k
;; int sum
;; for (...; i<n; ...)
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
_L_for_32:
    and r1, r6, r7
    addi r1, 4
    lwr r3, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    bf _L_endfor_34
;; for (...; j<n; ...)
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 5
    swr r2, r1
_L_for_35:
    and r1, r6, r7
    addi r1, 5
    lwr r3, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    bf _L_endfor_37
;; sum=0
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
;; for (...; k<n; ...)
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 7
    swr r2, r1
_L_for_38:
    and r1, r6, r7
    addi r1, 7
    lwr r3, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    bf _L_endfor_40
;; sum=sum+a[i*n+k]*b[k*n+j]
    and r1, r6, r7
    addi r1, 4
    lwr r3, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    and r1, r0, r0
_L_mat_mul_flat_mul_loop_86:
    sub r0, r0, r2
    bf _L_mat_mul_flat_mul_end_86
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_mat_mul_flat_mul_loop_86
_L_mat_mul_flat_mul_end_86:
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 8
    swr r2, r1
    and r1, r6, r7
    addi r1, 8
    lwr r3, r1
    and r1, r6, r7
    addi r1, 7
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 9
    swr r2, r1
    and r1, r6, r7
    lwr r3, r1
    and r1, r6, r7
    addi r1, 9
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    and r1, r6, r7
    addi r1, 10
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 11
    swr r2, r1
    and r1, r6, r7
    addi r1, 7
    lwr r3, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    and r1, r0, r0
_L_mat_mul_flat_mul_loop_131:
    sub r0, r0, r2
    bf _L_mat_mul_flat_mul_end_131
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_mat_mul_flat_mul_loop_131
_L_mat_mul_flat_mul_end_131:
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 12
    swr r2, r1
    and r1, r6, r7
    addi r1, 12
    lwr r3, r1
    and r1, r6, r7
    addi r1, 5
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 13
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r3, r1
    and r1, r6, r7
    addi r1, 13
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 14
    swr r2, r1
    and r1, r6, r7
    addi r1, 14
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 15
    swr r2, r1
    and r1, r6, r7
    addi r1, 11
    lwr r3, r1
    and r1, r6, r7
    addi r1, 15
    lwr r2, r1
    and r1, r0, r0
_L_mat_mul_flat_mul_loop_177:
    sub r0, r0, r2
    bf _L_mat_mul_flat_mul_end_177
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_mat_mul_flat_mul_loop_177
_L_mat_mul_flat_mul_end_177:
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 16
    swr r2, r1
    and r1, r6, r7
    addi r1, 6
    lwr r3, r1
    and r1, r6, r7
    addi r1, 16
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 17
    swr r2, r1
    and r1, r6, r7
    addi r1, 17
    lwr r2, r1
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
_L_forcont_39:
    and r1, r6, r7
    addi r1, 7
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 18
    swr r2, r1
    and r1, r6, r7
    addi r1, 18
    lwr r2, r1
    and r1, r6, r7
    addi r1, 7
    swr r2, r1
    li r1, _L_for_38
    jalr r0, r1
_L_endfor_40:
;; out[i*n+j]=sum
    and r1, r6, r7
    addi r1, 4
    lwr r3, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    and r1, r0, r0
_L_mat_mul_flat_mul_loop_231:
    sub r0, r0, r2
    bf _L_mat_mul_flat_mul_end_231
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_mat_mul_flat_mul_loop_231
_L_mat_mul_flat_mul_end_231:
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 19
    swr r2, r1
    and r1, r6, r7
    addi r1, 19
    lwr r3, r1
    and r1, r6, r7
    addi r1, 5
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 20
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    and r1, r6, r7
    addi r1, 20
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 21
    swr r2, r1
    and r1, r6, r7
    addi r1, 6
    lwr r2, r1
    and r1, r6, r7
    addi r1, 21
    lwr r1, r1
    swr r2, r1
_L_forcont_36:
    and r1, r6, r7
    addi r1, 5
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 22
    swr r2, r1
    and r1, r6, r7
    addi r1, 22
    lwr r2, r1
    and r1, r6, r7
    addi r1, 5
    swr r2, r1
    li r1, _L_for_35
    jalr r0, r1
_L_endfor_37:
_L_forcont_33:
    and r1, r6, r7
    addi r1, 4
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 23
    swr r2, r1
    and r1, r6, r7
    addi r1, 23
    lwr r2, r1
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
    li r1, _L_for_32
    jalr r0, r1
_L_endfor_34:
    li r1, _epi_mat_mul_flat
    jalr r0, r1
_epi_mat_mul_flat:
    addi r6, 24
    lwr r5, r6
    addi r6, 1
    addi r6, 1
    jalr r0, r5

main:
    subi r6, 1
    swr r5, r6
    subi r6, 18
;; int[9] s
;; int[9] p
;; mat_add_flat(MATRIX_A,MATRIX_B,s,9)
    li r2, 9
    subi r6, 1
    swr r2, r6
    li r2, MATRIX_A
    li r3, MATRIX_B
    and r1, r6, r7
    addi r1, 1
    and r4, r1, r7
    li r1, mat_add_flat
    jalr r5, r1
;; mat_mul_flat(MATRIX_A,MATRIX_B,p,3)
    li r2, 3
    subi r6, 1
    swr r2, r6
    li r2, MATRIX_A
    li r3, MATRIX_B
    and r1, r6, r7
    addi r1, 10
    and r4, r1, r7
    li r1, mat_mul_flat
    jalr r5, r1
;; puts("Matrix A (3x3):")
    li r2, _L_str_41
    li r1, puts
    jalr r5, r1
;; print_mat_rows(MATRIX_A)
    li r2, MATRIX_A
    li r1, print_mat_rows
    jalr r5, r1
;; putchar(10)
    li r2, 10
    li r1, putchar
    jalr r5, r1
;; puts("Matrix B (3x3):")
    li r2, _L_str_42
    li r1, puts
    jalr r5, r1
;; print_mat_rows(MATRIX_B)
    li r2, MATRIX_B
    li r1, print_mat_rows
    jalr r5, r1
;; putchar(10)
    li r2, 10
    li r1, putchar
    jalr r5, r1
;; puts("A + B:")
    li r2, _L_str_43
    li r1, puts
    jalr r5, r1
;; print_mat_rows(s)
    and r1, r6, r7
    and r2, r1, r7
    li r1, print_mat_rows
    jalr r5, r1
;; putchar(10)
    li r2, 10
    li r1, putchar
    jalr r5, r1
;; puts("A * B:")
    li r2, _L_str_44
    li r1, puts
    jalr r5, r1
;; print_mat_rows(p)
    and r1, r6, r7
    addi r1, 9
    and r2, r1, r7
    li r1, print_mat_rows
    jalr r5, r1
;; exit(0)
    and r2, r0, r0
    li r1, exit
    jalr r5, r1
;; return 0
    and r2, r0, r0
    li r1, _epi_main
    jalr r0, r1
_epi_main:
    addi r6, 18
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

_L_str_41:
    .word 77, 97, 116, 114, 105, 120, 32, 65, 32, 40, 51, 120, 51, 41, 58, 0
_L_str_42:
    .word 77, 97, 116, 114, 105, 120, 32, 66, 32, 40, 51, 120, 51, 41, 58, 0
_L_str_43:
    .word 65, 32, 43, 32, 66, 58, 0
_L_str_44:
    .word 65, 32, 42, 32, 66, 58, 0
