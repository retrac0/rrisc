; put_hex12.s -- print r2 as 0xNNN (three hex digits, lower-case), no newline
;
; Entry: r2 = 12-bit value, r5 = link.  Clobbers r1–r4.  Needs putchar + uart_tx.inc.

put_hex12:
        subi   r6, 1
        swr    r5, r6

        and    r4, r2, r7

        li     r2, 48
        li     r1, putchar
        jalr   r5, r1
        li     r2, 120
        li     r1, putchar
        jalr   r5, r1

        ; high nibble (bits 11..8): value / 256
        and    r2, r0, r0
__put_hex12_256:
        li     r1, 256
        sub    r0, r4, r1
        bt     __put_hex12_256_done
        sub    r4, r4, r1
        li     r1, 1
        add    r2, r2, r1
        li     r1, __put_hex12_256
        jalr   r0, r1
__put_hex12_256_done:
        li     r1, 10
        sub    r0, r2, r1
        bt     __put_hex12_256_dec
        li     r1, 87
        add    r2, r1, r2
        li     r1, __put_hex12_256_emit
        jalr   r0, r1
__put_hex12_256_dec:
        li     r1, 48
        add    r2, r1, r2
__put_hex12_256_emit:
        li     r1, putchar
        jalr   r5, r1

        ; mid nibble (bits 7..4): r4 / 16
        and    r2, r0, r0
__put_hex12_16:
        li     r1, 16
        sub    r0, r4, r1
        bt     __put_hex12_16_done
        sub    r4, r4, r1
        li     r1, 1
        add    r2, r2, r1
        li     r1, __put_hex12_16
        jalr   r0, r1
__put_hex12_16_done:
        li     r1, 10
        sub    r0, r2, r1
        bt     __put_hex12_16_dec
        li     r1, 87
        add    r2, r1, r2
        li     r1, __put_hex12_16_emit
        jalr   r0, r1
__put_hex12_16_dec:
        li     r1, 48
        add    r2, r1, r2
__put_hex12_16_emit:
        li     r1, putchar
        jalr   r5, r1

        ; low nibble (bits 3..0): r4 remainder
        and    r2, r4, r7
        li     r1, 10
        sub    r0, r2, r1
        bt     __put_hex12_lo_dec
        li     r1, 87
        add    r2, r1, r2
        li     r1, __put_hex12_lo_emit
        jalr   r0, r1
__put_hex12_lo_dec:
        li     r1, 48
        add    r2, r1, r2
__put_hex12_lo_emit:
        li     r1, putchar
        jalr   r5, r1

        lwr    r5, r6
        addi   r6, 1
        jalr   r0, r5
