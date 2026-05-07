; rcc-generated assembly
%define RCC_CODE_BASE 0o100
%define RCC_DATA_BASE 0o4000
%define RCC_STACK_TOP 0o7770
%include "crt0.s"
%include "float/__fcopy.s"
%include "float/__fneg.s"
%include "float/__fadd.s"
%include "float/__fsub.s"
%include "float/__fmul.s"
%include "float/__fdiv.s"
%include "float/__fcmp.s"
%include "float/__ftoi.s"
%include "float/__itof.s"


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
    bt _L_putchar_not_zero_30
    li r2, 1
    sub r0, r0, r7
    bt _L_putchar_not_end_30
_L_putchar_not_zero_30:
    li r2, 0
_L_putchar_not_end_30:
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    sub r0, r0, r2
    bt _L_putchar_ifz_skip_44
    li r1, _L_endwhile_1
    jalr r0, r1
_L_putchar_ifz_skip_44:
    li r1, _L_while_0
    jalr r0, r1
_L_endwhile_1:
;; *buf=c
    and r1, r6, r7
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r1, r1
    swr r2, r1
    li r1, _epi_putchar
    jalr r0, r1
_epi_putchar:
    addi r6, 5
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

getchar:
    subi r6, 1
    swr r5, r6
    subi r6, 5
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
_L_while_2:
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
    bt _L_getchar_not_zero_26
    li r2, 1
    sub r0, r0, r7
    bt _L_getchar_not_end_26
_L_getchar_not_zero_26:
    li r2, 0
_L_getchar_not_end_26:
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    sub r0, r0, r2
    bt _L_getchar_ifz_skip_40
    li r1, _L_endwhile_3
    jalr r0, r1
_L_getchar_ifz_skip_40:
    li r1, _L_while_2
    jalr r0, r1
_L_endwhile_3:
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
    li r1, _epi_getchar
    jalr r0, r1
_epi_getchar:
    addi r6, 5
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

puts:
    subi r6, 1
    swr r5, r6
    subi r6, 7
    and r1, r6, r7
    swr r2, r1
;; while (*s)
_L_while_4:
    and r1, r6, r7
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    sub r0, r0, r2
    bt _L_puts_ifz_skip_19
    li r1, _L_endwhile_5
    jalr r0, r1
_L_puts_ifz_skip_19:
;; putchar(*s++)
    and r1, r6, r7
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
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
    li r1, _L_while_4
    jalr r0, r1
_L_endwhile_5:
;; putchar(10)
    li r2, 10
    li r1, putchar
    jalr r5, r1
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
    li r1, _epi_puts
    jalr r0, r1
_epi_puts:
    addi r6, 7
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

gets:
    subi r6, 1
    swr r5, r6
    subi r6, 9
    and r1, r6, r7
    swr r2, r1
;; int* p = ...
    and r1, r6, r7
    lwr r2, r1
    and r1, r6, r7
    addi r1, 1
    swr r2, r1
;; int c
;; while (c=getchar()!=10&&c!=0)
_L_while_6:
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
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    li r2, 10
    sub r1, r3, r2
    sub r0, r0, r1
    rol r2, r0
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    sub r0, r0, r2
    bt _L_gets_ifz_skip_41
    li r1, _L_and_false_8
    jalr r0, r1
_L_gets_ifz_skip_41:
    and r1, r6, r7
    addi r1, 3
    lwr r3, r1
    and r2, r0, r0
    sub r1, r3, r2
    sub r0, r0, r1
    rol r2, r0
    and r1, r6, r7
    addi r1, 5
    swr r2, r1
    and r1, r6, r7
    addi r1, 5
    lwr r2, r1
    sub r0, r0, r2
    bt _L_gets_ifz_skip_59
    li r1, _L_and_false_8
    jalr r0, r1
_L_gets_ifz_skip_59:
    li r2, 1
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
    li r1, _L_and_end_9
    jalr r0, r1
_L_and_false_8:
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
_L_and_end_9:
    and r1, r6, r7
    addi r1, 6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_gets_ifz_skip_79
    li r1, _L_endwhile_7
    jalr r0, r1
_L_gets_ifz_skip_79:
;; *p++=c
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 7
    swr r2, r1
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
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    and r1, r6, r7
    addi r1, 7
    lwr r1, r1
    swr r2, r1
    li r1, _L_while_6
    jalr r0, r1
_L_endwhile_7:
;; *p=0
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 1
    lwr r1, r1
    swr r2, r1
;; return buf
    and r1, r6, r7
    lwr r2, r1
    li r1, _epi_gets
    jalr r0, r1
_epi_gets:
    addi r6, 9
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

itoa:
    subi r6, 1
    swr r5, r6
    subi r6, 37
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
    addi r1, 4
    lwr r2, r1
    sub r0, r0, r2
    bt _L_itoa_ifz_skip_40
    li r1, _L_endif_51
    jalr r0, r1
_L_itoa_ifz_skip_40:
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
_L_endif_51:
;; if (n==0)
    and r1, r6, r7
    lwr r3, r1
    and r2, r0, r0
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_itoa_ne_63
    li r2, 0
_L_itoa_ne_63:
    and r1, r6, r7
    addi r1, 6
    swr r2, r1
    and r1, r6, r7
    addi r1, 6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_itoa_ifz_skip_74
    li r1, _L_else_52
    jalr r0, r1
_L_itoa_ifz_skip_74:
;; *p++=48
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    and r1, r6, r7
    addi r1, 7
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
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
    addi r1, 2
    swr r2, r1
    li r2, 48
    and r1, r6, r7
    addi r1, 7
    lwr r1, r1
    swr r2, r1
    li r1, _L_endif_53
    jalr r0, r1
_L_else_52:
;; int* start = ...
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    and r1, r6, r7
    addi r1, 9
    swr r2, r1
;; while (n)
_L_while_54:
    and r1, r6, r7
    lwr r2, r1
    sub r0, r0, r2
    bt _L_itoa_ifz_skip_119
    li r1, _L_endwhile_55
    jalr r0, r1
_L_itoa_ifz_skip_119:
;; *p++=48+n%10
    and r1, r6, r7
    lwr r3, r1
    li r2, 10
    sub r0, r0, r2
    bf _L_itoa_mod_done_127
    and r1, r3, r7
    rol r1, r1
    rol r4, r0
    subi r6, 1
    swr r4, r6
    sub r0, r0, r4
    bf _L_itoa_mod_npos_127
    sub r3, r0, r3
_L_itoa_mod_npos_127:
    and r1, r2, r7
    rol r1, r1
    bf _L_itoa_mod_dpos_127
    sub r2, r0, r2
_L_itoa_mod_dpos_127:
    and r4, r3, r7
    and r1, r0, r0
_L_itoa_udiv_loop_143:
    sub r0, r4, r2
    bt _L_itoa_udiv_end_143
    sub r4, r4, r2
    addi r1, 1
    sub r0, r0, r7
    bt _L_itoa_udiv_loop_143
_L_itoa_udiv_end_143:
    and r1, r6, r7
    lwr r1, r1
    addi r6, 1
    sub r0, r0, r1
    bf _L_itoa_mod_rpos_127
    sub r4, r0, r4
_L_itoa_mod_rpos_127:
    and r2, r4, r7
_L_itoa_mod_done_127:
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    li r3, 48
    and r1, r6, r7
    addi r1, 10
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 11
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    and r1, r6, r7
    addi r1, 12
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
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
    addi r1, 2
    swr r2, r1
    and r1, r6, r7
    addi r1, 11
    lwr r2, r1
    and r1, r6, r7
    addi r1, 12
    lwr r1, r1
    swr r2, r1
;; n=n/10
    and r1, r6, r7
    lwr r3, r1
    li r2, 10
    sub r0, r0, r2
    bf _L_itoa_div_done_204
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
    bf _L_itoa_div_npos_204
    sub r3, r0, r3
_L_itoa_div_npos_204:
    and r1, r6, r7
    lwr r4, r1
    sub r0, r0, r4
    bf _L_itoa_div_dpos_204
    sub r2, r0, r2
_L_itoa_div_dpos_204:
    and r4, r3, r7
    and r1, r0, r0
_L_itoa_udiv_loop_229:
    sub r0, r4, r2
    bt _L_itoa_udiv_end_229
    sub r4, r4, r2
    addi r1, 1
    sub r0, r0, r7
    bt _L_itoa_udiv_loop_229
_L_itoa_udiv_end_229:
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
    bt _L_itoa_div_done_204
    sub r2, r0, r2
_L_itoa_div_done_204:
    and r1, r6, r7
    addi r1, 14
    swr r2, r1
    and r1, r6, r7
    addi r1, 14
    lwr r2, r1
    and r1, r6, r7
    swr r2, r1
    li r1, _L_while_54
    jalr r0, r1
_L_endwhile_55:
;; int* end = ...
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    and r1, r6, r7
    addi r1, 15
    swr r2, r1
    and r1, r6, r7
    addi r1, 15
    lwr r2, r1
    and r1, r6, r7
    addi r1, 16
    swr r2, r1
;; while (start<end)
_L_while_56:
    and r1, r6, r7
    addi r1, 9
    lwr r3, r1
    and r1, r6, r7
    addi r1, 16
    lwr r2, r1
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    rol r2, r0
    and r1, r6, r7
    addi r1, 17
    swr r2, r1
    and r1, r6, r7
    addi r1, 17
    lwr r2, r1
    sub r0, r0, r2
    bt _L_itoa_ifz_skip_298
    li r1, _L_endwhile_57
    jalr r0, r1
_L_itoa_ifz_skip_298:
;; int tmp = ...
    and r1, r6, r7
    addi r1, 9
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 18
    swr r2, r1
    and r1, r6, r7
    addi r1, 18
    lwr r2, r1
    and r1, r6, r7
    addi r1, 19
    swr r2, r1
;; *start++=*end
    and r1, r6, r7
    addi r1, 16
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 20
    swr r2, r1
    and r1, r6, r7
    addi r1, 9
    lwr r2, r1
    and r1, r6, r7
    addi r1, 21
    swr r2, r1
    and r1, r6, r7
    addi r1, 9
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
    addi r1, 9
    swr r2, r1
    and r1, r6, r7
    addi r1, 20
    lwr r2, r1
    and r1, r6, r7
    addi r1, 21
    lwr r1, r1
    swr r2, r1
;; *end--=tmp
    and r1, r6, r7
    addi r1, 16
    lwr r2, r1
    and r1, r6, r7
    addi r1, 23
    swr r2, r1
    and r1, r6, r7
    addi r1, 16
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    and r1, r6, r7
    addi r1, 24
    swr r2, r1
    and r1, r6, r7
    addi r1, 24
    lwr r2, r1
    and r1, r6, r7
    addi r1, 16
    swr r2, r1
    and r1, r6, r7
    addi r1, 19
    lwr r2, r1
    and r1, r6, r7
    addi r1, 23
    lwr r1, r1
    swr r2, r1
    li r1, _L_while_56
    jalr r0, r1
_L_endwhile_57:
_L_endif_53:
;; if (neg)
    and r1, r6, r7
    addi r1, 4
    lwr r2, r1
    sub r0, r0, r2
    bt _L_itoa_ifz_skip_388
    li r1, _L_endif_58
    jalr r0, r1
_L_itoa_ifz_skip_388:
;; int len = ...
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    sub r2, r3, r2
    and r1, r6, r7
    addi r1, 25
    swr r2, r1
    and r1, r6, r7
    addi r1, 25
    lwr r2, r1
    and r1, r6, r7
    addi r1, 26
    swr r2, r1
;; int i
;; for (...; i>0; ...)
    and r1, r6, r7
    addi r1, 26
    lwr r2, r1
    and r1, r6, r7
    addi r1, 27
    swr r2, r1
_L_for_59:
    and r1, r6, r7
    addi r1, 27
    lwr r3, r1
    and r2, r0, r0
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r2, r3
    rol r2, r0
    and r1, r6, r7
    addi r1, 28
    swr r2, r1
    and r1, r6, r7
    addi r1, 28
    lwr r2, r1
    sub r0, r0, r2
    bt _L_itoa_ifz_skip_434
    li r1, _L_endfor_61
    jalr r0, r1
_L_itoa_ifz_skip_434:
;; buf[i]=buf[i-1]
    and r1, r6, r7
    addi r1, 27
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    and r1, r6, r7
    addi r1, 29
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r3, r1
    and r1, r6, r7
    addi r1, 29
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 30
    swr r2, r1
    and r1, r6, r7
    addi r1, 30
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 31
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    lwr r3, r1
    and r1, r6, r7
    addi r1, 27
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 32
    swr r2, r1
    and r1, r6, r7
    addi r1, 31
    lwr r2, r1
    and r1, r6, r7
    addi r1, 32
    lwr r1, r1
    swr r2, r1
_L_forcont_60:
    and r1, r6, r7
    addi r1, 27
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    and r1, r6, r7
    addi r1, 33
    swr r2, r1
    and r1, r6, r7
    addi r1, 33
    lwr r2, r1
    and r1, r6, r7
    addi r1, 27
    swr r2, r1
    li r1, _L_for_59
    jalr r0, r1
_L_endfor_61:
;; buf[0]=45
    and r1, r6, r7
    addi r1, 1
    lwr r3, r1
    and r2, r0, r0
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 34
    swr r2, r1
    li r2, 45
    and r1, r6, r7
    addi r1, 34
    lwr r1, r1
    swr r2, r1
;; p++
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    and r1, r6, r7
    addi r1, 35
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 36
    swr r2, r1
    and r1, r6, r7
    addi r1, 36
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
_L_endif_58:
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
    addi r6, 37
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

ftoa:
    subi r6, 1
    swr r5, r6
    subi r6, 61
    and r1, r6, r7
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    swr r3, r1
;; float zero = ...
    and r1, r6, r7
    addi r1, 2
    and r2, r1, r7
    li r3, _L_flit_62
    li r1, __fcopy
    jalr r5, r1
;; float ten = ...
    and r1, r6, r7
    addi r1, 6
    and r2, r1, r7
    li r3, _L_flit_63
    li r1, __fcopy
    jalr r5, r1
;; int* p = ...
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
;; float x
;; int ipart
;; float frac
;; int digit
;; int i
;; x=*f
    and r1, r6, r7
    addi r1, 11
    and r2, r1, r7
    and r1, r6, r7
    lwr r3, r1
    li r1, __fcopy
    jalr r5, r1
;; if (x==zero)
    and r1, r6, r7
    addi r1, 11
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 2
    and r3, r1, r7
    li r1, __fcmp
    jalr r5, r1
    and r1, r6, r7
    addi r1, 19
    swr r2, r1
    and r1, r6, r7
    addi r1, 19
    lwr r3, r1
    and r2, r0, r0
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_ftoa_ne_62
    li r2, 0
_L_ftoa_ne_62:
    and r1, r6, r7
    addi r1, 20
    swr r2, r1
    and r1, r6, r7
    addi r1, 20
    lwr r2, r1
    sub r0, r0, r2
    bt _L_ftoa_ifz_skip_73
    li r1, _L_endif_64
    jalr r0, r1
_L_ftoa_ifz_skip_73:
;; *p++=48
    and r1, r6, r7
    addi r1, 10
    lwr r2, r1
    and r1, r6, r7
    addi r1, 21
    swr r2, r1
    and r1, r6, r7
    addi r1, 10
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
    addi r1, 10
    swr r2, r1
    li r2, 48
    and r1, r6, r7
    addi r1, 21
    lwr r1, r1
    swr r2, r1
;; *p++=46
    and r1, r6, r7
    addi r1, 10
    lwr r2, r1
    and r1, r6, r7
    addi r1, 23
    swr r2, r1
    and r1, r6, r7
    addi r1, 10
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 24
    swr r2, r1
    and r1, r6, r7
    addi r1, 24
    lwr r2, r1
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    li r2, 46
    and r1, r6, r7
    addi r1, 23
    lwr r1, r1
    swr r2, r1
;; *p++=48
    and r1, r6, r7
    addi r1, 10
    lwr r2, r1
    and r1, r6, r7
    addi r1, 25
    swr r2, r1
    and r1, r6, r7
    addi r1, 10
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 26
    swr r2, r1
    and r1, r6, r7
    addi r1, 26
    lwr r2, r1
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    li r2, 48
    and r1, r6, r7
    addi r1, 25
    lwr r1, r1
    swr r2, r1
;; *p++=48
    and r1, r6, r7
    addi r1, 10
    lwr r2, r1
    and r1, r6, r7
    addi r1, 27
    swr r2, r1
    and r1, r6, r7
    addi r1, 10
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 28
    swr r2, r1
    and r1, r6, r7
    addi r1, 28
    lwr r2, r1
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    li r2, 48
    and r1, r6, r7
    addi r1, 27
    lwr r1, r1
    swr r2, r1
;; *p++=48
    and r1, r6, r7
    addi r1, 10
    lwr r2, r1
    and r1, r6, r7
    addi r1, 29
    swr r2, r1
    and r1, r6, r7
    addi r1, 10
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 30
    swr r2, r1
    and r1, r6, r7
    addi r1, 30
    lwr r2, r1
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    li r2, 48
    and r1, r6, r7
    addi r1, 29
    lwr r1, r1
    swr r2, r1
;; *p++=48
    and r1, r6, r7
    addi r1, 10
    lwr r2, r1
    and r1, r6, r7
    addi r1, 31
    swr r2, r1
    and r1, r6, r7
    addi r1, 10
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 32
    swr r2, r1
    and r1, r6, r7
    addi r1, 32
    lwr r2, r1
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    li r2, 48
    and r1, r6, r7
    addi r1, 31
    lwr r1, r1
    swr r2, r1
;; *p=0
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 10
    lwr r1, r1
    swr r2, r1
;; return p
    and r1, r6, r7
    addi r1, 10
    lwr r2, r1
    li r1, _epi_ftoa
    jalr r0, r1
_L_endif_64:
;; if (x<zero)
    and r1, r6, r7
    addi r1, 11
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 2
    and r3, r1, r7
    li r1, __fcmp
    jalr r5, r1
    and r1, r6, r7
    addi r1, 33
    swr r2, r1
    and r1, r6, r7
    addi r1, 33
    lwr r3, r1
    and r2, r0, r0
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    rol r2, r0
    and r1, r6, r7
    addi r1, 34
    swr r2, r1
    and r1, r6, r7
    addi r1, 34
    lwr r2, r1
    sub r0, r0, r2
    bt _L_ftoa_ifz_skip_274
    li r1, _L_endif_65
    jalr r0, r1
_L_ftoa_ifz_skip_274:
;; *p++=45
    and r1, r6, r7
    addi r1, 10
    lwr r2, r1
    and r1, r6, r7
    addi r1, 35
    swr r2, r1
    and r1, r6, r7
    addi r1, 10
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 36
    swr r2, r1
    and r1, r6, r7
    addi r1, 36
    lwr r2, r1
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    li r2, 45
    and r1, r6, r7
    addi r1, 35
    lwr r1, r1
    swr r2, r1
;; x=-x
    and r1, r6, r7
    addi r1, 11
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 11
    and r3, r1, r7
    li r1, __fneg
    jalr r5, r1
_L_endif_65:
;; ipart=(int)x
    and r1, r6, r7
    addi r1, 11
    and r2, r1, r7
    li r1, __ftoi
    jalr r5, r1
    and r1, r6, r7
    addi r1, 37
    swr r2, r1
    and r1, r6, r7
    addi r1, 37
    lwr r2, r1
    and r1, r6, r7
    addi r1, 38
    swr r2, r1
;; itoa(ipart,p)
    and r1, r6, r7
    addi r1, 38
    lwr r2, r1
    and r1, r6, r7
    addi r1, 10
    lwr r3, r1
    li r1, itoa
    jalr r5, r1
    and r1, r6, r7
    addi r1, 39
    swr r2, r1
;; while (*p)
_L_while_66:
    and r1, r6, r7
    addi r1, 10
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 40
    swr r2, r1
    and r1, r6, r7
    addi r1, 40
    lwr r2, r1
    sub r0, r0, r2
    bt _L_ftoa_ifz_skip_354
    li r1, _L_endwhile_67
    jalr r0, r1
_L_ftoa_ifz_skip_354:
;; p++
    and r1, r6, r7
    addi r1, 10
    lwr r2, r1
    and r1, r6, r7
    addi r1, 41
    swr r2, r1
    and r1, r6, r7
    addi r1, 10
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 42
    swr r2, r1
    and r1, r6, r7
    addi r1, 42
    lwr r2, r1
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    li r1, _L_while_66
    jalr r0, r1
_L_endwhile_67:
;; *p++=46
    and r1, r6, r7
    addi r1, 10
    lwr r2, r1
    and r1, r6, r7
    addi r1, 43
    swr r2, r1
    and r1, r6, r7
    addi r1, 10
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 44
    swr r2, r1
    and r1, r6, r7
    addi r1, 44
    lwr r2, r1
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    li r2, 46
    and r1, r6, r7
    addi r1, 43
    lwr r1, r1
    swr r2, r1
;; frac=x-(float)ipart
    and r1, r6, r7
    addi r1, 45
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 38
    lwr r3, r1
    li r1, __itof
    jalr r5, r1
    and r1, r6, r7
    addi r1, 15
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 11
    and r3, r1, r7
    and r1, r6, r7
    addi r1, 45
    and r4, r1, r7
    li r1, __fsub
    jalr r5, r1
;; for (...; i<4; ...)
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 49
    swr r2, r1
_L_for_68:
    and r1, r6, r7
    addi r1, 49
    lwr r3, r1
    li r2, 4
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    rol r2, r0
    and r1, r6, r7
    addi r1, 50
    swr r2, r1
    and r1, r6, r7
    addi r1, 50
    lwr r2, r1
    sub r0, r0, r2
    bt _L_ftoa_ifz_skip_450
    li r1, _L_endfor_70
    jalr r0, r1
_L_ftoa_ifz_skip_450:
;; frac=frac*ten
    and r1, r6, r7
    addi r1, 15
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 15
    and r3, r1, r7
    and r1, r6, r7
    addi r1, 6
    and r4, r1, r7
    li r1, __fmul
    jalr r5, r1
;; digit=(int)frac
    and r1, r6, r7
    addi r1, 15
    and r2, r1, r7
    li r1, __ftoi
    jalr r5, r1
    and r1, r6, r7
    addi r1, 51
    swr r2, r1
    and r1, r6, r7
    addi r1, 51
    lwr r2, r1
    and r1, r6, r7
    addi r1, 52
    swr r2, r1
;; *p++=48+digit
    li r3, 48
    and r1, r6, r7
    addi r1, 52
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 53
    swr r2, r1
    and r1, r6, r7
    addi r1, 10
    lwr r2, r1
    and r1, r6, r7
    addi r1, 54
    swr r2, r1
    and r1, r6, r7
    addi r1, 10
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 55
    swr r2, r1
    and r1, r6, r7
    addi r1, 55
    lwr r2, r1
    and r1, r6, r7
    addi r1, 10
    swr r2, r1
    and r1, r6, r7
    addi r1, 53
    lwr r2, r1
    and r1, r6, r7
    addi r1, 54
    lwr r1, r1
    swr r2, r1
;; frac=frac-(float)digit
    and r1, r6, r7
    addi r1, 56
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 52
    lwr r3, r1
    li r1, __itof
    jalr r5, r1
    and r1, r6, r7
    addi r1, 15
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 15
    and r3, r1, r7
    and r1, r6, r7
    addi r1, 56
    and r4, r1, r7
    li r1, __fsub
    jalr r5, r1
_L_forcont_69:
    and r1, r6, r7
    addi r1, 49
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 60
    swr r2, r1
    and r1, r6, r7
    addi r1, 60
    lwr r2, r1
    and r1, r6, r7
    addi r1, 49
    swr r2, r1
    li r1, _L_for_68
    jalr r0, r1
_L_endfor_70:
;; *p=0
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 10
    lwr r1, r1
    swr r2, r1
;; return p
    and r1, r6, r7
    addi r1, 10
    lwr r2, r1
    li r1, _epi_ftoa
    jalr r0, r1
_epi_ftoa:
    addi r6, 61
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

atof:
    subi r6, 1
    swr r5, r6
    lui r1, 1
    sub r6, r6, r1
    and r1, r6, r7
    swr r2, r1
    and r1, r6, r7
    addi r1, 1
    swr r3, r1
;; int* p = ...
    and r1, r6, r7
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
;; int neg = ...
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
;; int ipart = ...
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
;; float fval
;; float frac
;; float scale
;; float ten = ...
    and r1, r6, r7
    and r2, r1, r7
    li r3, _L_flit_71
    li r1, __fcopy
    jalr r5, r1
;; float zero = ...
    and r1, r6, r7
    and r2, r1, r7
    li r3, _L_flit_72
    li r1, __fcopy
    jalr r5, r1
;; float d
;; while (*p==32||*p==9)
_L_while_73:
    and r1, r6, r7
    addi r1, 2
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 21
    swr r2, r1
    and r1, r6, r7
    addi r1, 21
    lwr r3, r1
    li r2, 32
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_atof_ne_58
    li r2, 0
_L_atof_ne_58:
    and r1, r6, r7
    addi r1, 22
    swr r2, r1
    and r1, r6, r7
    addi r1, 22
    lwr r2, r1
    sub r0, r0, r2
    bf _L_atof_ifnz_skip_69
    li r1, _L_or_true_75
    jalr r0, r1
_L_atof_ifnz_skip_69:
    and r1, r6, r7
    addi r1, 2
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 23
    swr r2, r1
    and r1, r6, r7
    addi r1, 23
    lwr r3, r1
    li r2, 9
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_atof_ne_86
    li r2, 0
_L_atof_ne_86:
    and r1, r6, r7
    addi r1, 24
    swr r2, r1
    and r1, r6, r7
    addi r1, 24
    lwr r2, r1
    sub r0, r0, r2
    bf _L_atof_ifnz_skip_97
    li r1, _L_or_true_75
    jalr r0, r1
_L_atof_ifnz_skip_97:
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 25
    swr r2, r1
    li r1, _L_or_end_76
    jalr r0, r1
_L_or_true_75:
    li r2, 1
    and r1, r6, r7
    addi r1, 25
    swr r2, r1
_L_or_end_76:
    and r1, r6, r7
    addi r1, 25
    lwr r2, r1
    sub r0, r0, r2
    bt _L_atof_ifz_skip_117
    li r1, _L_endwhile_74
    jalr r0, r1
_L_atof_ifz_skip_117:
;; p++
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    and r1, r6, r7
    addi r1, 26
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 27
    swr r2, r1
    and r1, r6, r7
    addi r1, 27
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    li r1, _L_while_73
    jalr r0, r1
_L_endwhile_74:
;; if (*p==45)
    and r1, r6, r7
    addi r1, 2
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 28
    swr r2, r1
    and r1, r6, r7
    addi r1, 28
    lwr r3, r1
    li r2, 45
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_atof_ne_159
    li r2, 0
_L_atof_ne_159:
    and r1, r6, r7
    addi r1, 29
    swr r2, r1
    and r1, r6, r7
    addi r1, 29
    lwr r2, r1
    sub r0, r0, r2
    bt _L_atof_ifz_skip_170
    li r1, _L_else_77
    jalr r0, r1
_L_atof_ifz_skip_170:
;; neg=1
    li r2, 1
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
;; p++
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    and r1, r6, r7
    addi r1, 30
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 31
    swr r2, r1
    and r1, r6, r7
    addi r1, 31
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    li r1, _L_endif_78
    jalr r0, r1
_L_else_77:
;; if (*p==43)
    and r1, r6, r7
    addi r1, 2
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 32
    swr r2, r1
    and r1, r6, r7
    addi r1, 32
    lwr r3, r1
    li r2, 43
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_atof_ne_217
    li r2, 0
_L_atof_ne_217:
    and r1, r6, r7
    addi r1, 33
    swr r2, r1
    and r1, r6, r7
    addi r1, 33
    lwr r2, r1
    sub r0, r0, r2
    bt _L_atof_ifz_skip_228
    li r1, _L_endif_79
    jalr r0, r1
_L_atof_ifz_skip_228:
;; p++
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    and r1, r6, r7
    addi r1, 34
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 35
    swr r2, r1
    and r1, r6, r7
    addi r1, 35
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
_L_endif_79:
_L_endif_78:
;; while (*p>=48&&*p<=57)
_L_while_80:
    and r1, r6, r7
    addi r1, 2
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 36
    swr r2, r1
    and r1, r6, r7
    addi r1, 36
    lwr r3, r1
    li r2, 48
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    li r2, 1
    bf _L_atof_ne_272
    li r2, 0
_L_atof_ne_272:
    and r1, r6, r7
    addi r1, 37
    swr r2, r1
    and r1, r6, r7
    addi r1, 37
    lwr r2, r1
    sub r0, r0, r2
    bt _L_atof_ifz_skip_283
    li r1, _L_and_false_82
    jalr r0, r1
_L_atof_ifz_skip_283:
    and r1, r6, r7
    addi r1, 2
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 38
    swr r2, r1
    and r1, r6, r7
    addi r1, 38
    lwr r3, r1
    li r2, 57
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r2, r3
    li r2, 1
    bf _L_atof_ne_302
    li r2, 0
_L_atof_ne_302:
    and r1, r6, r7
    addi r1, 39
    swr r2, r1
    and r1, r6, r7
    addi r1, 39
    lwr r2, r1
    sub r0, r0, r2
    bt _L_atof_ifz_skip_313
    li r1, _L_and_false_82
    jalr r0, r1
_L_atof_ifz_skip_313:
    li r2, 1
    and r1, r6, r7
    addi r1, 40
    swr r2, r1
    li r1, _L_and_end_83
    jalr r0, r1
_L_and_false_82:
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 40
    swr r2, r1
_L_and_end_83:
    and r1, r6, r7
    addi r1, 40
    lwr r2, r1
    sub r0, r0, r2
    bt _L_atof_ifz_skip_333
    li r1, _L_endwhile_81
    jalr r0, r1
_L_atof_ifz_skip_333:
;; ipart=ipart*10+*p-48
    and r1, r6, r7
    addi r1, 4
    lwr r3, r1
    li r2, 10
    and r1, r0, r0
_L_atof_mul_loop_342:
    sub r0, r0, r2
    bf _L_atof_mul_end_342
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_atof_mul_loop_342
_L_atof_mul_end_342:
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 41
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 42
    swr r2, r1
    and r1, r6, r7
    addi r1, 42
    lwr r3, r1
    li r2, 48
    sub r2, r3, r2
    and r1, r6, r7
    addi r1, 43
    swr r2, r1
    and r1, r6, r7
    addi r1, 41
    lwr r3, r1
    and r1, r6, r7
    addi r1, 43
    lwr r2, r1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 44
    swr r2, r1
    and r1, r6, r7
    addi r1, 44
    lwr r2, r1
    and r1, r6, r7
    addi r1, 4
    swr r2, r1
;; p++
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    and r1, r6, r7
    addi r1, 45
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 46
    swr r2, r1
    and r1, r6, r7
    addi r1, 46
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    li r1, _L_while_80
    jalr r0, r1
_L_endwhile_81:
;; fval=(float)ipart
    and r1, r6, r7
    addi r1, 5
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 4
    lwr r3, r1
    li r1, __itof
    jalr r5, r1
;; frac=zero
    and r1, r6, r7
    addi r1, 9
    and r2, r1, r7
    and r1, r6, r7
    and r3, r1, r7
    li r1, __fcopy
    jalr r5, r1
;; scale=ten
    and r1, r6, r7
    addi r1, 13
    and r2, r1, r7
    and r1, r6, r7
    and r3, r1, r7
    li r1, __fcopy
    jalr r5, r1
;; if (*p==46)
    and r1, r6, r7
    addi r1, 2
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 47
    swr r2, r1
    and r1, r6, r7
    addi r1, 47
    lwr r3, r1
    li r2, 46
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_atof_ne_449
    li r2, 0
_L_atof_ne_449:
    and r1, r6, r7
    addi r1, 48
    swr r2, r1
    and r1, r6, r7
    addi r1, 48
    lwr r2, r1
    sub r0, r0, r2
    bt _L_atof_ifz_skip_460
    li r1, _L_endif_84
    jalr r0, r1
_L_atof_ifz_skip_460:
;; p++
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    and r1, r6, r7
    addi r1, 49
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 50
    swr r2, r1
    and r1, r6, r7
    addi r1, 50
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
;; while (*p>=48&&*p<=57)
_L_while_85:
    and r1, r6, r7
    addi r1, 2
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 51
    swr r2, r1
    and r1, r6, r7
    addi r1, 51
    lwr r3, r1
    li r2, 48
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r3, r2
    li r2, 1
    bf _L_atof_ne_502
    li r2, 0
_L_atof_ne_502:
    and r1, r6, r7
    addi r1, 52
    swr r2, r1
    and r1, r6, r7
    addi r1, 52
    lwr r2, r1
    sub r0, r0, r2
    bt _L_atof_ifz_skip_513
    li r1, _L_and_false_87
    jalr r0, r1
_L_atof_ifz_skip_513:
    and r1, r6, r7
    addi r1, 2
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 53
    swr r2, r1
    and r1, r6, r7
    addi r1, 53
    lwr r3, r1
    li r2, 57
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r2, r3
    li r2, 1
    bf _L_atof_ne_532
    li r2, 0
_L_atof_ne_532:
    and r1, r6, r7
    addi r1, 54
    swr r2, r1
    and r1, r6, r7
    addi r1, 54
    lwr r2, r1
    sub r0, r0, r2
    bt _L_atof_ifz_skip_543
    li r1, _L_and_false_87
    jalr r0, r1
_L_atof_ifz_skip_543:
    li r2, 1
    and r1, r6, r7
    addi r1, 55
    swr r2, r1
    li r1, _L_and_end_88
    jalr r0, r1
_L_and_false_87:
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 55
    swr r2, r1
_L_and_end_88:
    and r1, r6, r7
    addi r1, 55
    lwr r2, r1
    sub r0, r0, r2
    bt _L_atof_ifz_skip_563
    li r1, _L_endwhile_86
    jalr r0, r1
_L_atof_ifz_skip_563:
;; d=(float)*p-48
    and r1, r6, r7
    addi r1, 2
    lwr r1, r1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 56
    swr r2, r1
    and r1, r6, r7
    addi r1, 56
    lwr r3, r1
    li r2, 48
    sub r2, r3, r2
    and r1, r6, r7
    addi r1, 57
    swr r2, r1
    and r1, r6, r7
    addi r1, 17
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 57
    lwr r3, r1
    li r1, __itof
    jalr r5, r1
;; frac=frac+d/scale
    and r1, r6, r7
    addi r1, 58
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 17
    and r3, r1, r7
    and r1, r6, r7
    addi r1, 13
    and r4, r1, r7
    li r1, __fdiv
    jalr r5, r1
    and r1, r6, r7
    addi r1, 9
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 9
    and r3, r1, r7
    and r1, r6, r7
    addi r1, 58
    and r4, r1, r7
    li r1, __fadd
    jalr r5, r1
;; scale=scale*ten
    and r1, r6, r7
    addi r1, 13
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 13
    and r3, r1, r7
    and r1, r6, r7
    and r4, r1, r7
    li r1, __fmul
    jalr r5, r1
;; p++
    and r1, r6, r7
    addi r1, 2
    lwr r2, r1
    and r1, r6, r7
    addi r1, 62
    swr r2, r1
    and r1, r6, r7
    addi r1, 2
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    and r1, r6, r7
    addi r1, 63
    swr r2, r1
    and r1, r6, r7
    addi r1, 63
    lwr r2, r1
    and r1, r6, r7
    addi r1, 2
    swr r2, r1
    li r1, _L_while_85
    jalr r0, r1
_L_endwhile_86:
_L_endif_84:
;; fval=fval+frac
    and r1, r6, r7
    addi r1, 5
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 5
    and r3, r1, r7
    and r1, r6, r7
    addi r1, 9
    and r4, r1, r7
    li r1, __fadd
    jalr r5, r1
;; if (neg)
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    sub r0, r0, r2
    bt _L_atof_ifz_skip_667
    li r1, _L_endif_89
    jalr r0, r1
_L_atof_ifz_skip_667:
;; fval=-fval
    and r1, r6, r7
    addi r1, 5
    and r2, r1, r7
    and r1, r6, r7
    addi r1, 5
    and r3, r1, r7
    li r1, __fneg
    jalr r5, r1
_L_endif_89:
;; *result=fval
    and r1, r6, r7
    addi r1, 1
    lwr r2, r1
    and r1, r6, r7
    addi r1, 5
    and r3, r1, r7
    li r1, __fcopy
    jalr r5, r1
    li r1, _epi_atof
    jalr r0, r1
_epi_atof:
    lui r1, 1
    add r6, r6, r1
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

isdigitch:
    subi r6, 1
    swr r5, r6
    subi r6, 4
    and r1, r6, r7
    swr r2, r1
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
    bt _L_isdigitch_ifz_skip_26
    li r1, _L_and_false_90
    jalr r0, r1
_L_isdigitch_ifz_skip_26:
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
    bt _L_isdigitch_ifz_skip_48
    li r1, _L_and_false_90
    jalr r0, r1
_L_isdigitch_ifz_skip_48:
    li r2, 1
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
    li r1, _L_and_end_91
    jalr r0, r1
_L_and_false_90:
    and r2, r0, r0
    and r1, r6, r7
    addi r1, 3
    swr r2, r1
_L_and_end_91:
    and r1, r6, r7
    addi r1, 3
    lwr r2, r1
    li r1, _epi_isdigitch
    jalr r0, r1
_epi_isdigitch:
    addi r6, 4
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

main:
    subi r6, 1
    swr r5, r6
    li r1, 286
    sub r6, r6, r1
;; int[64] buf
;; int[16] sbuf
;; int* p
;; float a
;; float b
;; float r
;; while (1)
_L_while_92:
;; gets(buf)
    and r1, r6, r7
    and r2, r1, r7
    li r1, gets
    jalr r5, r1
    li r1, 92
    add r1, r1, r6
    swr r2, r1
;; p=buf
    and r1, r6, r7
    and r2, r1, r7
    li r1, 93
    add r1, r1, r6
    swr r2, r1
;; while (*p!=0)
_L_while_94:
    li r1, 93
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 94
    add r1, r1, r6
    swr r2, r1
    li r1, 94
    add r1, r1, r6
    lwr r3, r1
    and r2, r0, r0
    sub r1, r3, r2
    sub r0, r0, r1
    rol r2, r0
    li r1, 95
    add r1, r1, r6
    swr r2, r1
    li r1, 95
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_main_ifz_skip_51
    li r1, _L_endwhile_95
    jalr r0, r1
_L_main_ifz_skip_51:
;; while (*p==32||*p==9)
_L_while_96:
    li r1, 93
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 96
    add r1, r1, r6
    swr r2, r1
    li r1, 96
    add r1, r1, r6
    lwr r3, r1
    li r2, 32
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_70
    li r2, 0
_L_main_ne_70:
    li r1, 97
    add r1, r1, r6
    swr r2, r1
    li r1, 97
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bf _L_main_ifnz_skip_81
    li r1, _L_or_true_98
    jalr r0, r1
_L_main_ifnz_skip_81:
    li r1, 93
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 98
    add r1, r1, r6
    swr r2, r1
    li r1, 98
    add r1, r1, r6
    lwr r3, r1
    li r2, 9
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_98
    li r2, 0
_L_main_ne_98:
    li r1, 99
    add r1, r1, r6
    swr r2, r1
    li r1, 99
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bf _L_main_ifnz_skip_109
    li r1, _L_or_true_98
    jalr r0, r1
_L_main_ifnz_skip_109:
    and r2, r0, r0
    li r1, 100
    add r1, r1, r6
    swr r2, r1
    li r1, _L_or_end_99
    jalr r0, r1
_L_or_true_98:
    li r2, 1
    li r1, 100
    add r1, r1, r6
    swr r2, r1
_L_or_end_99:
    li r1, 100
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_main_ifz_skip_129
    li r1, _L_endwhile_97
    jalr r0, r1
_L_main_ifz_skip_129:
;; p++
    li r1, 93
    add r1, r1, r6
    lwr r2, r1
    li r1, 101
    add r1, r1, r6
    swr r2, r1
    li r1, 93
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 102
    add r1, r1, r6
    swr r2, r1
    li r1, 102
    add r1, r1, r6
    lwr r2, r1
    li r1, 93
    add r1, r1, r6
    swr r2, r1
    li r1, _L_while_96
    jalr r0, r1
_L_endwhile_97:
;; if (*p==0)
    li r1, 93
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 103
    add r1, r1, r6
    swr r2, r1
    li r1, 103
    add r1, r1, r6
    lwr r3, r1
    and r2, r0, r0
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_171
    li r2, 0
_L_main_ne_171:
    li r1, 104
    add r1, r1, r6
    swr r2, r1
    li r1, 104
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_main_ifz_skip_182
    li r1, _L_endif_100
    jalr r0, r1
_L_main_ifz_skip_182:
;; break
    li r1, _L_endwhile_95
    jalr r0, r1
_L_endif_100:
;; if (isdigitch(*p)||*p==45&&isdigitch(*p+1)||*p==46&&isdig...
    li r1, 93
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 105
    add r1, r1, r6
    swr r2, r1
    li r1, 105
    add r1, r1, r6
    lwr r2, r1
    li r1, isdigitch
    jalr r5, r1
    li r1, 106
    add r1, r1, r6
    swr r2, r1
    li r1, 106
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bf _L_main_ifnz_skip_210
    li r1, _L_or_true_103
    jalr r0, r1
_L_main_ifnz_skip_210:
    li r1, 93
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 107
    add r1, r1, r6
    swr r2, r1
    li r1, 107
    add r1, r1, r6
    lwr r3, r1
    li r2, 45
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_227
    li r2, 0
_L_main_ne_227:
    li r1, 108
    add r1, r1, r6
    swr r2, r1
    li r1, 108
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_main_ifz_skip_238
    li r1, _L_and_false_105
    jalr r0, r1
_L_main_ifz_skip_238:
    li r1, 93
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 109
    add r1, r1, r6
    swr r2, r1
    li r1, 109
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 110
    add r1, r1, r6
    swr r2, r1
    li r1, 110
    add r1, r1, r6
    lwr r2, r1
    li r1, isdigitch
    jalr r5, r1
    li r1, 111
    add r1, r1, r6
    swr r2, r1
    li r1, 111
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_main_ifz_skip_269
    li r1, _L_and_false_105
    jalr r0, r1
_L_main_ifz_skip_269:
    li r2, 1
    li r1, 112
    add r1, r1, r6
    swr r2, r1
    li r1, _L_and_end_106
    jalr r0, r1
_L_and_false_105:
    and r2, r0, r0
    li r1, 112
    add r1, r1, r6
    swr r2, r1
_L_and_end_106:
    li r1, 112
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bf _L_main_ifnz_skip_289
    li r1, _L_or_true_103
    jalr r0, r1
_L_main_ifnz_skip_289:
    and r2, r0, r0
    li r1, 113
    add r1, r1, r6
    swr r2, r1
    li r1, _L_or_end_104
    jalr r0, r1
_L_or_true_103:
    li r2, 1
    li r1, 113
    add r1, r1, r6
    swr r2, r1
_L_or_end_104:
    li r1, 113
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bf _L_main_ifnz_skip_309
    li r1, _L_or_true_101
    jalr r0, r1
_L_main_ifnz_skip_309:
    li r1, 93
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 114
    add r1, r1, r6
    swr r2, r1
    li r1, 114
    add r1, r1, r6
    lwr r3, r1
    li r2, 46
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_326
    li r2, 0
_L_main_ne_326:
    li r1, 115
    add r1, r1, r6
    swr r2, r1
    li r1, 115
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_main_ifz_skip_337
    li r1, _L_and_false_107
    jalr r0, r1
_L_main_ifz_skip_337:
    li r1, 93
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 116
    add r1, r1, r6
    swr r2, r1
    li r1, 116
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 117
    add r1, r1, r6
    swr r2, r1
    li r1, 117
    add r1, r1, r6
    lwr r2, r1
    li r1, isdigitch
    jalr r5, r1
    li r1, 118
    add r1, r1, r6
    swr r2, r1
    li r1, 118
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_main_ifz_skip_368
    li r1, _L_and_false_107
    jalr r0, r1
_L_main_ifz_skip_368:
    li r2, 1
    li r1, 119
    add r1, r1, r6
    swr r2, r1
    li r1, _L_and_end_108
    jalr r0, r1
_L_and_false_107:
    and r2, r0, r0
    li r1, 119
    add r1, r1, r6
    swr r2, r1
_L_and_end_108:
    li r1, 119
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bf _L_main_ifnz_skip_388
    li r1, _L_or_true_101
    jalr r0, r1
_L_main_ifnz_skip_388:
    and r2, r0, r0
    li r1, 120
    add r1, r1, r6
    swr r2, r1
    li r1, _L_or_end_102
    jalr r0, r1
_L_or_true_101:
    li r2, 1
    li r1, 120
    add r1, r1, r6
    swr r2, r1
_L_or_end_102:
    li r1, 120
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_main_ifz_skip_408
    li r1, _L_else_109
    jalr r0, r1
_L_main_ifz_skip_408:
;; atof(p,&r)
    li r1, 88
    add r1, r1, r6
    and r2, r1, r7
    li r1, 121
    add r1, r1, r6
    swr r2, r1
    li r1, 93
    add r1, r1, r6
    lwr r2, r1
    li r1, 121
    add r1, r1, r6
    lwr r3, r1
    li r1, atof
    jalr r5, r1
    li r1, 122
    add r1, r1, r6
    swr r2, r1
;; if (*p==45)
    li r1, 93
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 123
    add r1, r1, r6
    swr r2, r1
    li r1, 123
    add r1, r1, r6
    lwr r3, r1
    li r2, 45
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_444
    li r2, 0
_L_main_ne_444:
    li r1, 124
    add r1, r1, r6
    swr r2, r1
    li r1, 124
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_main_ifz_skip_455
    li r1, _L_endif_111
    jalr r0, r1
_L_main_ifz_skip_455:
;; p++
    li r1, 93
    add r1, r1, r6
    lwr r2, r1
    li r1, 125
    add r1, r1, r6
    swr r2, r1
    li r1, 93
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
    li r1, 93
    add r1, r1, r6
    swr r2, r1
_L_endif_111:
;; while (isdigitch(*p)||*p==46)
_L_while_112:
    li r1, 93
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 127
    add r1, r1, r6
    swr r2, r1
    li r1, 127
    add r1, r1, r6
    lwr r2, r1
    li r1, isdigitch
    jalr r5, r1
    lui r1, 2
    add r1, r1, r6
    swr r2, r1
    lui r1, 2
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bf _L_main_ifnz_skip_502
    li r1, _L_or_true_114
    jalr r0, r1
_L_main_ifnz_skip_502:
    li r1, 93
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 129
    add r1, r1, r6
    swr r2, r1
    li r1, 129
    add r1, r1, r6
    lwr r3, r1
    li r2, 46
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_519
    li r2, 0
_L_main_ne_519:
    li r1, 130
    add r1, r1, r6
    swr r2, r1
    li r1, 130
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bf _L_main_ifnz_skip_530
    li r1, _L_or_true_114
    jalr r0, r1
_L_main_ifnz_skip_530:
    and r2, r0, r0
    li r1, 131
    add r1, r1, r6
    swr r2, r1
    li r1, _L_or_end_115
    jalr r0, r1
_L_or_true_114:
    li r2, 1
    li r1, 131
    add r1, r1, r6
    swr r2, r1
_L_or_end_115:
    li r1, 131
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_main_ifz_skip_550
    li r1, _L_endwhile_113
    jalr r0, r1
_L_main_ifz_skip_550:
;; p++
    li r1, 93
    add r1, r1, r6
    lwr r2, r1
    li r1, 132
    add r1, r1, r6
    swr r2, r1
    li r1, 93
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 133
    add r1, r1, r6
    swr r2, r1
    li r1, 133
    add r1, r1, r6
    lwr r2, r1
    li r1, 93
    add r1, r1, r6
    swr r2, r1
    li r1, _L_while_112
    jalr r0, r1
_L_endwhile_113:
;; stk[sp]=r
    li r1, sp
    lwr r2, r1
    li r1, 134
    add r1, r1, r6
    swr r2, r1
    li r1, 134
    add r1, r1, r6
    lwr r3, r1
    li r2, 4
    and r1, r0, r0
_L_main_mul_loop_588:
    sub r0, r0, r2
    bf _L_main_mul_end_588
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_main_mul_loop_588
_L_main_mul_end_588:
    and r2, r1, r7
    li r1, 135
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 135
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 136
    add r1, r1, r6
    swr r2, r1
    li r1, 136
    add r1, r1, r6
    lwr r2, r1
    li r1, 88
    add r1, r1, r6
    and r3, r1, r7
    li r1, __fcopy
    jalr r5, r1
;; sp++
    li r1, sp
    lwr r2, r1
    li r1, 137
    add r1, r1, r6
    swr r2, r1
    li r1, 137
    add r1, r1, r6
    lwr r2, r1
    li r1, 138
    add r1, r1, r6
    swr r2, r1
    li r1, 137
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 139
    add r1, r1, r6
    swr r2, r1
    li r1, 139
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
    li r1, _L_endif_110
    jalr r0, r1
_L_else_109:
;; if (*p==43)
    li r1, 93
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 140
    add r1, r1, r6
    swr r2, r1
    li r1, 140
    add r1, r1, r6
    lwr r3, r1
    li r2, 43
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_659
    li r2, 0
_L_main_ne_659:
    li r1, 141
    add r1, r1, r6
    swr r2, r1
    li r1, 141
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_main_ifz_skip_670
    li r1, _L_else_116
    jalr r0, r1
_L_main_ifz_skip_670:
;; sp--
    li r1, sp
    lwr r2, r1
    li r1, 142
    add r1, r1, r6
    swr r2, r1
    li r1, 142
    add r1, r1, r6
    lwr r2, r1
    li r1, 143
    add r1, r1, r6
    swr r2, r1
    li r1, 142
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    li r1, 144
    add r1, r1, r6
    swr r2, r1
    li r1, 144
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
;; b=stk[sp]
    li r1, sp
    lwr r2, r1
    li r1, 145
    add r1, r1, r6
    swr r2, r1
    li r1, 145
    add r1, r1, r6
    lwr r3, r1
    li r2, 4
    and r1, r0, r0
_L_main_mul_loop_709:
    sub r0, r0, r2
    bf _L_main_mul_end_709
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_main_mul_loop_709
_L_main_mul_end_709:
    and r2, r1, r7
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
    li r1, 84
    add r1, r1, r6
    and r2, r1, r7
    li r1, 147
    add r1, r1, r6
    lwr r3, r1
    li r1, __fcopy
    jalr r5, r1
;; sp--
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
    sub r2, r3, r2
    li r1, 150
    add r1, r1, r6
    swr r2, r1
    li r1, 150
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
;; a=stk[sp]
    li r1, sp
    lwr r2, r1
    li r1, 151
    add r1, r1, r6
    swr r2, r1
    li r1, 151
    add r1, r1, r6
    lwr r3, r1
    li r2, 4
    and r1, r0, r0
_L_main_mul_loop_773:
    sub r0, r0, r2
    bf _L_main_mul_end_773
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_main_mul_loop_773
_L_main_mul_end_773:
    and r2, r1, r7
    li r1, 152
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 152
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 153
    add r1, r1, r6
    swr r2, r1
    li r1, 80
    add r1, r1, r6
    and r2, r1, r7
    li r1, 153
    add r1, r1, r6
    lwr r3, r1
    li r1, __fcopy
    jalr r5, r1
;; r=a+b
    li r1, 88
    add r1, r1, r6
    and r2, r1, r7
    li r1, 80
    add r1, r1, r6
    and r3, r1, r7
    li r1, 84
    add r1, r1, r6
    and r4, r1, r7
    li r1, __fadd
    jalr r5, r1
;; stk[sp]=r
    li r1, sp
    lwr r2, r1
    li r1, 154
    add r1, r1, r6
    swr r2, r1
    li r1, 154
    add r1, r1, r6
    lwr r3, r1
    li r2, 4
    and r1, r0, r0
_L_main_mul_loop_824:
    sub r0, r0, r2
    bf _L_main_mul_end_824
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_main_mul_loop_824
_L_main_mul_end_824:
    and r2, r1, r7
    li r1, 155
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 155
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 156
    add r1, r1, r6
    swr r2, r1
    li r1, 156
    add r1, r1, r6
    lwr r2, r1
    li r1, 88
    add r1, r1, r6
    and r3, r1, r7
    li r1, __fcopy
    jalr r5, r1
;; sp++
    li r1, sp
    lwr r2, r1
    li r1, 157
    add r1, r1, r6
    swr r2, r1
    li r1, 157
    add r1, r1, r6
    lwr r2, r1
    li r1, 158
    add r1, r1, r6
    swr r2, r1
    li r1, 157
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 159
    add r1, r1, r6
    swr r2, r1
    li r1, 159
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
;; p++
    li r1, 93
    add r1, r1, r6
    lwr r2, r1
    li r1, 160
    add r1, r1, r6
    swr r2, r1
    li r1, 93
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 161
    add r1, r1, r6
    swr r2, r1
    li r1, 161
    add r1, r1, r6
    lwr r2, r1
    li r1, 93
    add r1, r1, r6
    swr r2, r1
    li r1, _L_endif_117
    jalr r0, r1
_L_else_116:
;; if (*p==45)
    li r1, 93
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 162
    add r1, r1, r6
    swr r2, r1
    li r1, 162
    add r1, r1, r6
    lwr r3, r1
    li r2, 45
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_916
    li r2, 0
_L_main_ne_916:
    li r1, 163
    add r1, r1, r6
    swr r2, r1
    li r1, 163
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_main_ifz_skip_927
    li r1, _L_else_118
    jalr r0, r1
_L_main_ifz_skip_927:
;; sp--
    li r1, sp
    lwr r2, r1
    li r1, 164
    add r1, r1, r6
    swr r2, r1
    li r1, 164
    add r1, r1, r6
    lwr r2, r1
    li r1, 165
    add r1, r1, r6
    swr r2, r1
    li r1, 164
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    li r1, 166
    add r1, r1, r6
    swr r2, r1
    li r1, 166
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
;; b=stk[sp]
    li r1, sp
    lwr r2, r1
    li r1, 167
    add r1, r1, r6
    swr r2, r1
    li r1, 167
    add r1, r1, r6
    lwr r3, r1
    li r2, 4
    and r1, r0, r0
_L_main_mul_loop_966:
    sub r0, r0, r2
    bf _L_main_mul_end_966
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_main_mul_loop_966
_L_main_mul_end_966:
    and r2, r1, r7
    li r1, 168
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 168
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 169
    add r1, r1, r6
    swr r2, r1
    li r1, 84
    add r1, r1, r6
    and r2, r1, r7
    li r1, 169
    add r1, r1, r6
    lwr r3, r1
    li r1, __fcopy
    jalr r5, r1
;; sp--
    li r1, sp
    lwr r2, r1
    li r1, 170
    add r1, r1, r6
    swr r2, r1
    li r1, 170
    add r1, r1, r6
    lwr r2, r1
    li r1, 171
    add r1, r1, r6
    swr r2, r1
    li r1, 170
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    li r1, 172
    add r1, r1, r6
    swr r2, r1
    li r1, 172
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
;; a=stk[sp]
    li r1, sp
    lwr r2, r1
    li r1, 173
    add r1, r1, r6
    swr r2, r1
    li r1, 173
    add r1, r1, r6
    lwr r3, r1
    li r2, 4
    and r1, r0, r0
_L_main_mul_loop_1030:
    sub r0, r0, r2
    bf _L_main_mul_end_1030
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_main_mul_loop_1030
_L_main_mul_end_1030:
    and r2, r1, r7
    li r1, 174
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 174
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 175
    add r1, r1, r6
    swr r2, r1
    li r1, 80
    add r1, r1, r6
    and r2, r1, r7
    li r1, 175
    add r1, r1, r6
    lwr r3, r1
    li r1, __fcopy
    jalr r5, r1
;; r=a-b
    li r1, 88
    add r1, r1, r6
    and r2, r1, r7
    li r1, 80
    add r1, r1, r6
    and r3, r1, r7
    li r1, 84
    add r1, r1, r6
    and r4, r1, r7
    li r1, __fsub
    jalr r5, r1
;; stk[sp]=r
    li r1, sp
    lwr r2, r1
    li r1, 176
    add r1, r1, r6
    swr r2, r1
    li r1, 176
    add r1, r1, r6
    lwr r3, r1
    li r2, 4
    and r1, r0, r0
_L_main_mul_loop_1081:
    sub r0, r0, r2
    bf _L_main_mul_end_1081
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_main_mul_loop_1081
_L_main_mul_end_1081:
    and r2, r1, r7
    li r1, 177
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 177
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 178
    add r1, r1, r6
    swr r2, r1
    li r1, 178
    add r1, r1, r6
    lwr r2, r1
    li r1, 88
    add r1, r1, r6
    and r3, r1, r7
    li r1, __fcopy
    jalr r5, r1
;; sp++
    li r1, sp
    lwr r2, r1
    li r1, 179
    add r1, r1, r6
    swr r2, r1
    li r1, 179
    add r1, r1, r6
    lwr r2, r1
    li r1, 180
    add r1, r1, r6
    swr r2, r1
    li r1, 179
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 181
    add r1, r1, r6
    swr r2, r1
    li r1, 181
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
;; p++
    li r1, 93
    add r1, r1, r6
    lwr r2, r1
    li r1, 182
    add r1, r1, r6
    swr r2, r1
    li r1, 93
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 183
    add r1, r1, r6
    swr r2, r1
    li r1, 183
    add r1, r1, r6
    lwr r2, r1
    li r1, 93
    add r1, r1, r6
    swr r2, r1
    li r1, _L_endif_119
    jalr r0, r1
_L_else_118:
;; if (*p==42)
    li r1, 93
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 184
    add r1, r1, r6
    swr r2, r1
    li r1, 184
    add r1, r1, r6
    lwr r3, r1
    li r2, 42
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_1173
    li r2, 0
_L_main_ne_1173:
    li r1, 185
    add r1, r1, r6
    swr r2, r1
    li r1, 185
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_main_ifz_skip_1184
    li r1, _L_else_120
    jalr r0, r1
_L_main_ifz_skip_1184:
;; sp--
    li r1, sp
    lwr r2, r1
    li r1, 186
    add r1, r1, r6
    swr r2, r1
    li r1, 186
    add r1, r1, r6
    lwr r2, r1
    li r1, 187
    add r1, r1, r6
    swr r2, r1
    li r1, 186
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    li r1, 188
    add r1, r1, r6
    swr r2, r1
    li r1, 188
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
;; b=stk[sp]
    li r1, sp
    lwr r2, r1
    li r1, 189
    add r1, r1, r6
    swr r2, r1
    li r1, 189
    add r1, r1, r6
    lwr r3, r1
    li r2, 4
    and r1, r0, r0
_L_main_mul_loop_1223:
    sub r0, r0, r2
    bf _L_main_mul_end_1223
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_main_mul_loop_1223
_L_main_mul_end_1223:
    and r2, r1, r7
    li r1, 190
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 190
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 191
    add r1, r1, r6
    swr r2, r1
    li r1, 84
    add r1, r1, r6
    and r2, r1, r7
    li r1, 191
    add r1, r1, r6
    lwr r3, r1
    li r1, __fcopy
    jalr r5, r1
;; sp--
    li r1, sp
    lwr r2, r1
    lui r1, 3
    add r1, r1, r6
    swr r2, r1
    lui r1, 3
    add r1, r1, r6
    lwr r2, r1
    li r1, 193
    add r1, r1, r6
    swr r2, r1
    lui r1, 3
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    li r1, 194
    add r1, r1, r6
    swr r2, r1
    li r1, 194
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
;; a=stk[sp]
    li r1, sp
    lwr r2, r1
    li r1, 195
    add r1, r1, r6
    swr r2, r1
    li r1, 195
    add r1, r1, r6
    lwr r3, r1
    li r2, 4
    and r1, r0, r0
_L_main_mul_loop_1287:
    sub r0, r0, r2
    bf _L_main_mul_end_1287
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_main_mul_loop_1287
_L_main_mul_end_1287:
    and r2, r1, r7
    li r1, 196
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 196
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 197
    add r1, r1, r6
    swr r2, r1
    li r1, 80
    add r1, r1, r6
    and r2, r1, r7
    li r1, 197
    add r1, r1, r6
    lwr r3, r1
    li r1, __fcopy
    jalr r5, r1
;; r=a*b
    li r1, 88
    add r1, r1, r6
    and r2, r1, r7
    li r1, 80
    add r1, r1, r6
    and r3, r1, r7
    li r1, 84
    add r1, r1, r6
    and r4, r1, r7
    li r1, __fmul
    jalr r5, r1
;; stk[sp]=r
    li r1, sp
    lwr r2, r1
    li r1, 198
    add r1, r1, r6
    swr r2, r1
    li r1, 198
    add r1, r1, r6
    lwr r3, r1
    li r2, 4
    and r1, r0, r0
_L_main_mul_loop_1338:
    sub r0, r0, r2
    bf _L_main_mul_end_1338
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_main_mul_loop_1338
_L_main_mul_end_1338:
    and r2, r1, r7
    li r1, 199
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 199
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 200
    add r1, r1, r6
    swr r2, r1
    li r1, 200
    add r1, r1, r6
    lwr r2, r1
    li r1, 88
    add r1, r1, r6
    and r3, r1, r7
    li r1, __fcopy
    jalr r5, r1
;; sp++
    li r1, sp
    lwr r2, r1
    li r1, 201
    add r1, r1, r6
    swr r2, r1
    li r1, 201
    add r1, r1, r6
    lwr r2, r1
    li r1, 202
    add r1, r1, r6
    swr r2, r1
    li r1, 201
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 203
    add r1, r1, r6
    swr r2, r1
    li r1, 203
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
;; p++
    li r1, 93
    add r1, r1, r6
    lwr r2, r1
    li r1, 204
    add r1, r1, r6
    swr r2, r1
    li r1, 93
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 205
    add r1, r1, r6
    swr r2, r1
    li r1, 205
    add r1, r1, r6
    lwr r2, r1
    li r1, 93
    add r1, r1, r6
    swr r2, r1
    li r1, _L_endif_121
    jalr r0, r1
_L_else_120:
;; if (*p==47)
    li r1, 93
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 206
    add r1, r1, r6
    swr r2, r1
    li r1, 206
    add r1, r1, r6
    lwr r3, r1
    li r2, 47
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_1430
    li r2, 0
_L_main_ne_1430:
    li r1, 207
    add r1, r1, r6
    swr r2, r1
    li r1, 207
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_main_ifz_skip_1441
    li r1, _L_else_122
    jalr r0, r1
_L_main_ifz_skip_1441:
;; sp--
    li r1, sp
    lwr r2, r1
    li r1, 208
    add r1, r1, r6
    swr r2, r1
    li r1, 208
    add r1, r1, r6
    lwr r2, r1
    li r1, 209
    add r1, r1, r6
    swr r2, r1
    li r1, 208
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    li r1, 210
    add r1, r1, r6
    swr r2, r1
    li r1, 210
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
;; b=stk[sp]
    li r1, sp
    lwr r2, r1
    li r1, 211
    add r1, r1, r6
    swr r2, r1
    li r1, 211
    add r1, r1, r6
    lwr r3, r1
    li r2, 4
    and r1, r0, r0
_L_main_mul_loop_1480:
    sub r0, r0, r2
    bf _L_main_mul_end_1480
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_main_mul_loop_1480
_L_main_mul_end_1480:
    and r2, r1, r7
    li r1, 212
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 212
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 213
    add r1, r1, r6
    swr r2, r1
    li r1, 84
    add r1, r1, r6
    and r2, r1, r7
    li r1, 213
    add r1, r1, r6
    lwr r3, r1
    li r1, __fcopy
    jalr r5, r1
;; sp--
    li r1, sp
    lwr r2, r1
    li r1, 214
    add r1, r1, r6
    swr r2, r1
    li r1, 214
    add r1, r1, r6
    lwr r2, r1
    li r1, 215
    add r1, r1, r6
    swr r2, r1
    li r1, 214
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    li r1, 216
    add r1, r1, r6
    swr r2, r1
    li r1, 216
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
;; a=stk[sp]
    li r1, sp
    lwr r2, r1
    li r1, 217
    add r1, r1, r6
    swr r2, r1
    li r1, 217
    add r1, r1, r6
    lwr r3, r1
    li r2, 4
    and r1, r0, r0
_L_main_mul_loop_1544:
    sub r0, r0, r2
    bf _L_main_mul_end_1544
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_main_mul_loop_1544
_L_main_mul_end_1544:
    and r2, r1, r7
    li r1, 218
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 218
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 219
    add r1, r1, r6
    swr r2, r1
    li r1, 80
    add r1, r1, r6
    and r2, r1, r7
    li r1, 219
    add r1, r1, r6
    lwr r3, r1
    li r1, __fcopy
    jalr r5, r1
;; r=a/b
    li r1, 88
    add r1, r1, r6
    and r2, r1, r7
    li r1, 80
    add r1, r1, r6
    and r3, r1, r7
    li r1, 84
    add r1, r1, r6
    and r4, r1, r7
    li r1, __fdiv
    jalr r5, r1
;; stk[sp]=r
    li r1, sp
    lwr r2, r1
    li r1, 220
    add r1, r1, r6
    swr r2, r1
    li r1, 220
    add r1, r1, r6
    lwr r3, r1
    li r2, 4
    and r1, r0, r0
_L_main_mul_loop_1595:
    sub r0, r0, r2
    bf _L_main_mul_end_1595
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_main_mul_loop_1595
_L_main_mul_end_1595:
    and r2, r1, r7
    li r1, 221
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 221
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 222
    add r1, r1, r6
    swr r2, r1
    li r1, 222
    add r1, r1, r6
    lwr r2, r1
    li r1, 88
    add r1, r1, r6
    and r3, r1, r7
    li r1, __fcopy
    jalr r5, r1
;; sp++
    li r1, sp
    lwr r2, r1
    li r1, 223
    add r1, r1, r6
    swr r2, r1
    li r1, 223
    add r1, r1, r6
    lwr r2, r1
    li r1, 224
    add r1, r1, r6
    swr r2, r1
    li r1, 223
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 225
    add r1, r1, r6
    swr r2, r1
    li r1, 225
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
;; p++
    li r1, 93
    add r1, r1, r6
    lwr r2, r1
    li r1, 226
    add r1, r1, r6
    swr r2, r1
    li r1, 93
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 227
    add r1, r1, r6
    swr r2, r1
    li r1, 227
    add r1, r1, r6
    lwr r2, r1
    li r1, 93
    add r1, r1, r6
    swr r2, r1
    li r1, _L_endif_123
    jalr r0, r1
_L_else_122:
;; if (*p==110)
    li r1, 93
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 228
    add r1, r1, r6
    swr r2, r1
    li r1, 228
    add r1, r1, r6
    lwr r3, r1
    li r2, 110
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_1687
    li r2, 0
_L_main_ne_1687:
    li r1, 229
    add r1, r1, r6
    swr r2, r1
    li r1, 229
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_main_ifz_skip_1698
    li r1, _L_else_124
    jalr r0, r1
_L_main_ifz_skip_1698:
;; sp--
    li r1, sp
    lwr r2, r1
    li r1, 230
    add r1, r1, r6
    swr r2, r1
    li r1, 230
    add r1, r1, r6
    lwr r2, r1
    li r1, 231
    add r1, r1, r6
    swr r2, r1
    li r1, 230
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    li r1, 232
    add r1, r1, r6
    swr r2, r1
    li r1, 232
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
;; a=stk[sp]
    li r1, sp
    lwr r2, r1
    li r1, 233
    add r1, r1, r6
    swr r2, r1
    li r1, 233
    add r1, r1, r6
    lwr r3, r1
    li r2, 4
    and r1, r0, r0
_L_main_mul_loop_1737:
    sub r0, r0, r2
    bf _L_main_mul_end_1737
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_main_mul_loop_1737
_L_main_mul_end_1737:
    and r2, r1, r7
    li r1, 234
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 234
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 235
    add r1, r1, r6
    swr r2, r1
    li r1, 80
    add r1, r1, r6
    and r2, r1, r7
    li r1, 235
    add r1, r1, r6
    lwr r3, r1
    li r1, __fcopy
    jalr r5, r1
;; r=-a
    li r1, 88
    add r1, r1, r6
    and r2, r1, r7
    li r1, 80
    add r1, r1, r6
    and r3, r1, r7
    li r1, __fneg
    jalr r5, r1
;; stk[sp]=r
    li r1, sp
    lwr r2, r1
    li r1, 236
    add r1, r1, r6
    swr r2, r1
    li r1, 236
    add r1, r1, r6
    lwr r3, r1
    li r2, 4
    and r1, r0, r0
_L_main_mul_loop_1785:
    sub r0, r0, r2
    bf _L_main_mul_end_1785
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_main_mul_loop_1785
_L_main_mul_end_1785:
    and r2, r1, r7
    li r1, 237
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 237
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 238
    add r1, r1, r6
    swr r2, r1
    li r1, 238
    add r1, r1, r6
    lwr r2, r1
    li r1, 88
    add r1, r1, r6
    and r3, r1, r7
    li r1, __fcopy
    jalr r5, r1
;; sp++
    li r1, sp
    lwr r2, r1
    li r1, 239
    add r1, r1, r6
    swr r2, r1
    li r1, 239
    add r1, r1, r6
    lwr r2, r1
    li r1, 240
    add r1, r1, r6
    swr r2, r1
    li r1, 239
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 241
    add r1, r1, r6
    swr r2, r1
    li r1, 241
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
;; p++
    li r1, 93
    add r1, r1, r6
    lwr r2, r1
    li r1, 242
    add r1, r1, r6
    swr r2, r1
    li r1, 93
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 243
    add r1, r1, r6
    swr r2, r1
    li r1, 243
    add r1, r1, r6
    lwr r2, r1
    li r1, 93
    add r1, r1, r6
    swr r2, r1
    li r1, _L_endif_125
    jalr r0, r1
_L_else_124:
;; if (*p==112)
    li r1, 93
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 244
    add r1, r1, r6
    swr r2, r1
    li r1, 244
    add r1, r1, r6
    lwr r3, r1
    li r2, 112
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_1877
    li r2, 0
_L_main_ne_1877:
    li r1, 245
    add r1, r1, r6
    swr r2, r1
    li r1, 245
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_main_ifz_skip_1888
    li r1, _L_else_126
    jalr r0, r1
_L_main_ifz_skip_1888:
;; if (sp>0)
    li r1, sp
    lwr r2, r1
    li r1, 246
    add r1, r1, r6
    swr r2, r1
    li r1, 246
    add r1, r1, r6
    lwr r3, r1
    and r2, r0, r0
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r2, r3
    rol r2, r0
    li r1, 247
    add r1, r1, r6
    swr r2, r1
    li r1, 247
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_main_ifz_skip_1914
    li r1, _L_endif_128
    jalr r0, r1
_L_main_ifz_skip_1914:
;; ftoa(&stk[sp-1],sbuf)
    li r1, sp
    lwr r2, r1
    li r1, 248
    add r1, r1, r6
    swr r2, r1
    li r1, 248
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    li r1, 249
    add r1, r1, r6
    swr r2, r1
    li r1, 249
    add r1, r1, r6
    lwr r3, r1
    li r2, 4
    and r1, r0, r0
_L_main_mul_loop_1936:
    sub r0, r0, r2
    bf _L_main_mul_end_1936
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_main_mul_loop_1936
_L_main_mul_end_1936:
    and r2, r1, r7
    li r1, 250
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 250
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 251
    add r1, r1, r6
    swr r2, r1
    li r1, sp
    lwr r2, r1
    li r1, 252
    add r1, r1, r6
    swr r2, r1
    li r1, 252
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    li r1, 253
    add r1, r1, r6
    swr r2, r1
    li r1, 253
    add r1, r1, r6
    lwr r3, r1
    li r2, 4
    and r1, r0, r0
_L_main_mul_loop_1974:
    sub r0, r0, r2
    bf _L_main_mul_end_1974
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_main_mul_loop_1974
_L_main_mul_end_1974:
    and r2, r1, r7
    li r1, 254
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 254
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 255
    add r1, r1, r6
    swr r2, r1
    li r1, 255
    add r1, r1, r6
    lwr r2, r1
    lui r1, 4
    add r1, r1, r6
    swr r2, r1
    lui r1, 4
    add r1, r1, r6
    lwr r2, r1
    lui r1, 1
    add r1, r1, r6
    and r3, r1, r7
    li r1, ftoa
    jalr r5, r1
    li r1, 257
    add r1, r1, r6
    swr r2, r1
;; puts(sbuf)
    lui r1, 1
    add r1, r1, r6
    and r2, r1, r7
    li r1, puts
    jalr r5, r1
    li r1, 258
    add r1, r1, r6
    swr r2, r1
_L_endif_128:
;; p++
    li r1, 93
    add r1, r1, r6
    lwr r2, r1
    li r1, 259
    add r1, r1, r6
    swr r2, r1
    li r1, 93
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 260
    add r1, r1, r6
    swr r2, r1
    li r1, 260
    add r1, r1, r6
    lwr r2, r1
    li r1, 93
    add r1, r1, r6
    swr r2, r1
    li r1, _L_endif_127
    jalr r0, r1
_L_else_126:
;; if (*p==100)
    li r1, 93
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 261
    add r1, r1, r6
    swr r2, r1
    li r1, 261
    add r1, r1, r6
    lwr r3, r1
    li r2, 100
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_2060
    li r2, 0
_L_main_ne_2060:
    li r1, 262
    add r1, r1, r6
    swr r2, r1
    li r1, 262
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_main_ifz_skip_2071
    li r1, _L_else_129
    jalr r0, r1
_L_main_ifz_skip_2071:
;; if (sp>0)
    li r1, sp
    lwr r2, r1
    li r1, 263
    add r1, r1, r6
    swr r2, r1
    li r1, 263
    add r1, r1, r6
    lwr r3, r1
    and r2, r0, r0
    li r1, 0o4000
    add r3, r3, r1
    add r2, r2, r1
    sub r1, r2, r3
    rol r2, r0
    li r1, 264
    add r1, r1, r6
    swr r2, r1
    li r1, 264
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_main_ifz_skip_2097
    li r1, _L_endif_131
    jalr r0, r1
_L_main_ifz_skip_2097:
;; a=stk[sp-1]
    li r1, sp
    lwr r2, r1
    li r1, 265
    add r1, r1, r6
    swr r2, r1
    li r1, 265
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    sub r2, r3, r2
    li r1, 266
    add r1, r1, r6
    swr r2, r1
    li r1, 266
    add r1, r1, r6
    lwr r3, r1
    li r2, 4
    and r1, r0, r0
_L_main_mul_loop_2119:
    sub r0, r0, r2
    bf _L_main_mul_end_2119
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_main_mul_loop_2119
_L_main_mul_end_2119:
    and r2, r1, r7
    li r1, 267
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 267
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 268
    add r1, r1, r6
    swr r2, r1
    li r1, 80
    add r1, r1, r6
    and r2, r1, r7
    li r1, 268
    add r1, r1, r6
    lwr r3, r1
    li r1, __fcopy
    jalr r5, r1
;; stk[sp]=a
    li r1, sp
    lwr r2, r1
    li r1, 269
    add r1, r1, r6
    swr r2, r1
    li r1, 269
    add r1, r1, r6
    lwr r3, r1
    li r2, 4
    and r1, r0, r0
_L_main_mul_loop_2158:
    sub r0, r0, r2
    bf _L_main_mul_end_2158
    add r1, r1, r3
    subi r2, 1
    sub r0, r0, r7
    bt _L_main_mul_loop_2158
_L_main_mul_end_2158:
    and r2, r1, r7
    li r1, 270
    add r1, r1, r6
    swr r2, r1
    li r3, stk
    li r1, 270
    add r1, r1, r6
    lwr r2, r1
    add r2, r3, r2
    li r1, 271
    add r1, r1, r6
    swr r2, r1
    li r1, 271
    add r1, r1, r6
    lwr r2, r1
    li r1, 80
    add r1, r1, r6
    and r3, r1, r7
    li r1, __fcopy
    jalr r5, r1
;; sp++
    li r1, sp
    lwr r2, r1
    li r1, 272
    add r1, r1, r6
    swr r2, r1
    li r1, 272
    add r1, r1, r6
    lwr r2, r1
    li r1, 273
    add r1, r1, r6
    swr r2, r1
    li r1, 272
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 274
    add r1, r1, r6
    swr r2, r1
    li r1, 274
    add r1, r1, r6
    lwr r2, r1
    li r1, sp
    swr r2, r1
_L_endif_131:
;; p++
    li r1, 93
    add r1, r1, r6
    lwr r2, r1
    li r1, 275
    add r1, r1, r6
    swr r2, r1
    li r1, 93
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 276
    add r1, r1, r6
    swr r2, r1
    li r1, 276
    add r1, r1, r6
    lwr r2, r1
    li r1, 93
    add r1, r1, r6
    swr r2, r1
    li r1, _L_endif_130
    jalr r0, r1
_L_else_129:
;; if (*p==99)
    li r1, 93
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 277
    add r1, r1, r6
    swr r2, r1
    li r1, 277
    add r1, r1, r6
    lwr r3, r1
    li r2, 99
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_2251
    li r2, 0
_L_main_ne_2251:
    li r1, 278
    add r1, r1, r6
    swr r2, r1
    li r1, 278
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_main_ifz_skip_2262
    li r1, _L_else_132
    jalr r0, r1
_L_main_ifz_skip_2262:
;; sp=0
    and r2, r0, r0
    li r1, sp
    swr r2, r1
;; p++
    li r1, 93
    add r1, r1, r6
    lwr r2, r1
    li r1, 279
    add r1, r1, r6
    swr r2, r1
    li r1, 93
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 280
    add r1, r1, r6
    swr r2, r1
    li r1, 280
    add r1, r1, r6
    lwr r2, r1
    li r1, 93
    add r1, r1, r6
    swr r2, r1
    li r1, _L_endif_133
    jalr r0, r1
_L_else_132:
;; if (*p==113)
    li r1, 93
    add r1, r1, r6
    lwr r1, r1
    lwr r2, r1
    li r1, 281
    add r1, r1, r6
    swr r2, r1
    li r1, 281
    add r1, r1, r6
    lwr r3, r1
    li r2, 113
    sub r1, r3, r2
    sub r0, r0, r1
    li r2, 1
    bf _L_main_ne_2308
    li r2, 0
_L_main_ne_2308:
    li r1, 282
    add r1, r1, r6
    swr r2, r1
    li r1, 282
    add r1, r1, r6
    lwr r2, r1
    sub r0, r0, r2
    bt _L_main_ifz_skip_2319
    li r1, _L_else_134
    jalr r0, r1
_L_main_ifz_skip_2319:
;; exit(0)
    and r2, r0, r0
    li r1, exit
    jalr r5, r1
    li r1, 283
    add r1, r1, r6
    swr r2, r1
    li r1, _L_endif_135
    jalr r0, r1
_L_else_134:
;; p++
    li r1, 93
    add r1, r1, r6
    lwr r2, r1
    li r1, 284
    add r1, r1, r6
    swr r2, r1
    li r1, 93
    add r1, r1, r6
    lwr r3, r1
    li r2, 1
    add r2, r3, r2
    li r1, 285
    add r1, r1, r6
    swr r2, r1
    li r1, 285
    add r1, r1, r6
    lwr r2, r1
    li r1, 93
    add r1, r1, r6
    swr r2, r1
_L_endif_135:
_L_endif_133:
_L_endif_130:
_L_endif_127:
_L_endif_125:
_L_endif_123:
_L_endif_121:
_L_endif_119:
_L_endif_117:
_L_endif_110:
    li r1, _L_while_94
    jalr r0, r1
_L_endwhile_95:
    li r1, _L_while_92
    jalr r0, r1
_L_endwhile_93:
;; return 0
    and r2, r0, r0
    li r1, _epi_main
    jalr r0, r1
_epi_main:
    li r1, 286
    add r6, r6, r1
    lwr r5, r6
    addi r6, 1
    jalr r0, r5

_L_flit_62:
    .word 0, 0, 0, 0
_L_flit_63:
    .word 1027, 2560, 0, 0
_L_flit_71:
    .word 1027, 2560, 0, 0
_L_flit_72:
    .word 0, 0, 0, 0

    .org 0o4000
stk:
    .fill 64
sp:
    .word 0
