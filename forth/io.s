; forth/io.s — UART helpers, NUL-terminated string print, TIB refill

; ---------- UART (r3 scratch only — preserves r1 IP and r4/r6 stacks) --------
; Same hardware protocol as lib/io/putchar.s and getchar.s but r1 unused.
; Entry: r2 = char to send (TX) / ignored (RX); r5 = return.  Exit: r2 = byte (RX).

forth_uart_tx_r2:
    li      r3, TXRDY
    lwr     r3, r3
    sub     r0, r0, r3
    bf      forth_uart_tx_r2
    li      r3, TXBUF
    swr     r2, r3
    jalr    r0, r5

forth_uart_rx_r2:
    li      r3, RXRDY
    lwr     r3, r3
    sub     r0, r0, r3
    bf      forth_uart_rx_r2
    li      r3, RXBUF
    lwr     r2, r3
    jalr    r0, r5

; r4 = pointer to zero-terminated string (one ASCII word per cell); r5 = return.
; Clobbers r2, r3, r4.  Used by code_puts, main, and quit_loop.
; Inner jalr r5, forth_uart_tx_r2 overwrites r5; save the outer return in var_puts0_lr.
puts0_r4:
    li      r3, var_puts0_lr
    swr     r5, r3
puts0_loop:
    lwr     r3, r4
    sub     r0, r0, r3
    bf      puts0_done
    add     r2, r3, r0
    li      r3, forth_uart_tx_r2
    jalr    r5, r3
    addi    r4, 1
    li      r3, puts0_loop
    jalr    r0, r3
puts0_done:
    li      r3, var_puts0_lr
    lwr     r5, r3
    jalr    r0, r5

refill_tib:
    ; Caller return in var_refill_lr. UART helpers preserve r1 (IP).
    li      r3, var_refill_lr
    swr     r5, r3
    li      r2, 0
    li      r3, var_tib_idx
    swr     r2, r3
rf_loop:
    li      r3, forth_uart_rx_r2
    jalr    r5, r3
    li      r3, forth_uart_tx_r2
    jalr    r5, r3
    li      r3, 10
    sub     r0, r2, r3
    bt      rf_not_lf
    sub     r0, r3, r2
    bt      rf_not_lf
    li      r3, rf_end
    jalr    r0, r3
rf_not_lf:
    li      r3, 13
    sub     r0, r2, r3
    bt      rf_not_cr
    sub     r0, r3, r2
    bt      rf_not_cr
    li      r3, rf_end
    jalr    r0, r3
rf_not_cr:
    li      r3, var_tib_idx
    lwr     r4, r3
    li      r3, TIB_MAX
    sub     r0, r4, r3
    bf      rf_end_full
    li      r3, tib
    add     r3, r3, r4
    swr     r2, r3
    addi    r4, 1
    li      r3, var_tib_idx
    swr     r4, r3
    li      r3, rf_loop
    jalr    r0, r3
rf_end_full:
rf_end:
    li      r2, var_tib_idx
    lwr     r4, r2
    li      r3, tib
    add     r3, r3, r4
    li      r2, 0
    swr     r2, r3
    li      r3, var_tib_idx
    swr     r2, r3
    li      r3, var_refill_lr
    lwr     r5, r3
    jalr    r0, r5
