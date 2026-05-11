; forth/primitives.s — primitive code words and octal numeric print

; ---------- Primitives ------------------------------------------------------

code_drop:
    lwr     r2, r6
    addi    r6, 1
    li      r3, prim_tail
    jalr    r0, r3

code_dup:
    lwr     r2, r6
    subi    r6, 1
    swr     r2, r6
    li      r3, prim_tail
    jalr    r0, r3

code_swap:
    lwr     r2, r6
    addi    r6, 1
    lwr     r3, r6
    addi    r6, 1
    subi    r6, 1
    swr     r2, r6
    subi    r6, 1
    swr     r3, r6
    li      r3, prim_tail
    jalr    r0, r3

code_plus:
    lwr     r3, r6
    addi    r6, 1
    lwr     r2, r6
    addi    r6, 1
    add     r2, r2, r3
    subi    r6, 1
    swr     r2, r6
    li      r3, prim_tail
    jalr    r0, r3

code_minus:
    lwr     r3, r6
    addi    r6, 1
    lwr     r2, r6
    addi    r6, 1
    sub     r2, r2, r3
    subi    r6, 1
    swr     r2, r6
    li      r3, prim_tail
    jalr    r0, r3

code_lit:
    lwr     r2, r1
    addi    r1, 1
    subi    r6, 1
    swr     r2, r6
    li      r3, prim_tail
    jalr    r0, r3

code_emit:
    lwr     r2, r6
    addi    r6, 1
    li      r3, var_saved_ip
    swr     r1, r3
    li      r3, forth_uart_tx_r2
    jalr    r5, r3
    li      r1, var_saved_ip
    lwr     r1, r1
    li      r3, prim_tail
    jalr    r0, r3

code_key:
    li      r3, var_saved_ip
    swr     r1, r3
    li      r3, forth_uart_rx_r2
    jalr    r5, r3
    li      r1, var_saved_ip
    lwr     r1, r1
    subi    r6, 1
    swr     r2, r6
    li      r3, prim_tail
    jalr    r0, r3

code_udot:
    lwr     r2, r6
    addi    r6, 1
    li      r3, var_saved_ip
    swr     r1, r3
    li      r3, print_oct_r2
    jalr    r5, r3
    li      r2, 32
    li      r3, forth_uart_tx_r2
    jalr    r5, r3
    li      r1, var_saved_ip
    lwr     r1, r1
    li      r3, prim_tail
    jalr    r0, r3

code_cr:
    li      r2, 10
    li      r3, var_saved_ip
    swr     r1, r3
    li      r3, forth_uart_tx_r2
    jalr    r5, r3
    li      r1, var_saved_ip
    lwr     r1, r1
    li      r3, prim_tail
    jalr    r0, r3

code_puts:
    lwr     r4, r6
    addi    r6, 1
    li      r3, puts0_r4
    jalr    r5, r3
    li      r3, prim_tail
    jalr    r0, r3

code_bye:
    halt

; Push octal digits least-significant first, then pop and print (unsigned)
print_oct_r2:
    li      r3, var_print_oct_lr
    swr     r5, r3
    sub     r0, r0, r2
    bt      pu_nz
    li      r2, 48
    li      r3, forth_uart_tx_r2
    jalr    r5, r3
    li      r3, var_print_oct_lr
    lwr     r5, r3
    jalr    r0, r5
pu_nz:
pu_collect:
    li      r3, 8
    sub     r0, r2, r3
    bt      pu_push_last
    li      r4, 0
pu_div8:
    li      r3, 8
    sub     r0, r2, r3
    bt      pu_got_rm
    subi    r2, 8
    addi    r4, 1
    li      r3, pu_div8
    jalr    r0, r3
pu_got_rm:
    ; r2 = remainder digit, r4 = quotient
    subi    r6, 1
    swr     r2, r6
    add     r2, r4, r0
    li      r3, pu_collect
    jalr    r0, r3
pu_push_last:
    subi    r6, 1
    swr     r2, r6
pu_emitloop:
    li      r3, RCC_STACK_TOP
    sub     r0, r6, r3
    bf      pu_done_emit
    lwr     r2, r6
    addi    r6, 1
    addi    r2, 48
    li      r3, var_saved_ip
    swr     r1, r3
    li      r3, forth_uart_tx_r2
    jalr    r5, r3
    li      r1, var_saved_ip
    lwr     r1, r1
    li      r3, pu_emitloop
    jalr    r0, r3
pu_done_emit:
    li      r3, var_print_oct_lr
    lwr     r5, r3
    jalr    r0, r5
