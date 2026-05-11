hello_thread:
    .word   xt_lit
    .word   str_boot
    .word   xt_puts
    .word   xt_exit

name_puts:
    .word   name_bye
    .word   4
    .word   80
    .word   85
    .word   84
    .word   83
xt_puts:
    .word   code_puts

name_bye:
    .word   name_exit
    .word   3
    .word   66
    .word   89
    .word   69
xt_bye:
    .word   code_bye

name_exit:
    .word   name_cr
    .word   4
    .word   69
    .word   88
    .word   73
    .word   84
xt_exit:
    .word   exit_

name_cr:
    .word   name_udot
    .word   2
    .word   67
    .word   82
xt_cr:
    .word   code_cr

name_udot:
    .word   name_key
    .word   1
    .word   46
xt_udot:
    .word   code_udot

name_key:
    .word   name_emit
    .word   3
    .word   75
    .word   69
    .word   89
xt_key:
    .word   code_key

name_emit:
    .word   name_lit
    .word   4
    .word   69
    .word   77
    .word   73
    .word   84
xt_emit:
    .word   code_emit

name_lit:
    .word   name_minus
    .word   3
    .word   76
    .word   73
    .word   84
xt_lit:
    .word   code_lit

name_minus:
    .word   name_plus
    .word   1
    .word   45
xt_minus:
    .word   code_minus

name_plus:
    .word   name_swap
    .word   1
    .word   43
xt_plus:
    .word   code_plus

name_swap:
    .word   name_dup
    .word   4
    .word   83
    .word   87
    .word   65
    .word   80
xt_swap:
    .word   code_swap

name_dup:
    .word   name_drop
    .word   3
    .word   68
    .word   85
    .word   80
xt_dup:
    .word   code_dup

name_drop:
    .word   name_hello
    .word   4
    .word   68
    .word   82
    .word   79
    .word   80
xt_drop:
    .word   code_drop

name_hello:
    .word   0
    .word   5
    .word   72
    .word   69
    .word   76
    .word   76
    .word   79
xt_hello:
    .word   docol
    .word   hello_thread