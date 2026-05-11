; forth/core.s — inner interpreter, FIND / MATCH, parse word & number, EXECUTE

; ---------- Inner interpreter -------------------------------------------------

    .global next
next:
    lwr     r3, r1
    addi    r1, 1
    lwr     r2, r3
    jalr    r0, r2

    .global docol
docol:
    subi    r4, 1
    swr     r1, r4
    addi    r3, 1
    add     r1, r3, r0
    li      r3, next
    jalr    r0, r3

    .global exit_
exit_:
    lwr     r1, r4
    addi    r4, 1
    li      r3, next
    jalr    r0, r3

; FIND — codeword field address in r2, or 0
find_word:
    li      r3, var_find_lr
    swr     r5, r3
    li      r2, var_latest
    lwr     r2, r2
fw_loop:
    sub     r0, r0, r2
    bf      fw_fail
    li      r3, var_parse_idx
    swr     r2, r3
    li      r3, match_entry
    jalr    r5, r3
    bt      fw_found
    li      r1, var_parse_idx
    lwr     r2, r1
    lwr     r2, r2
    li      r3, fw_loop
    jalr    r0, r3
fw_found:
    li      r1, var_parse_idx
    lwr     r2, r1
    add     r1, r2, r0
    addi    r1, 1
    lwr     r3, r1
    add     r1, r2, r0
    addi    r1, 2
    add     r1, r1, r3
    add     r2, r1, r0
    li      r3, var_find_lr
    lwr     r5, r3
    jalr    r0, r5
fw_fail:
    li      r2, 0
    li      r3, var_find_lr
    lwr     r5, r3
    jalr    r0, r5

; T=1 on match
match_entry:
    li      r1, var_saved_r5
    swr     r5, r1
    li      r1, var_parse_idx
    lwr     r2, r1
    add     r5, r2, r0
    addi    r5, 1
    lwr     r5, r5
    li      r1, var_word_len
    lwr     r1, r1
    sub     r0, r1, r5
    bt      match_fail
    sub     r0, r5, r1
    bt      match_fail
    addi    r2, 2
    li      r4, 0
match_ch:
    sub     r0, r4, r1
    bf      match_ok
    li      r3, word_buf
    add     r3, r3, r4
    lwr     r3, r3
    lwr     r5, r2
    addi    r2, 1
    addi    r4, 1
    sub     r0, r3, r5
    bt      match_ch_ne
    sub     r0, r5, r3
    bt      match_ch_ne
    li      r3, match_ch
    jalr    r0, r3
match_ch_ne:
    li      r3, match_fail
    jalr    r0, r3
match_ok:
    sub     r0, r0, r7
    li      r1, var_saved_r5
    lwr     r5, r1
    jalr    r0, r5
match_fail:
    clrt
    li      r1, var_saved_r5
    lwr     r5, r1
    jalr    r0, r5

parse_word:
    li      r2, 0
    li      r3, var_word_len
    swr     r2, r3
pw_skip:
    li      r2, var_tib_idx
    lwr     r3, r2
    li      r2, TIB_MAX
    sub     r0, r3, r2
    bf      pw_empty
    li      r2, tib
    add     r2, r2, r3
    lwr     r2, r2
    ; NUL marks end of filled TIB (see refill_tib); not skippable whitespace.
    sub     r0, r0, r2
    bf      pw_empty
    ; Whitespace: use r1 for 32 — r5 is the caller's return address (jalr r5, …).
    li      r1, 32
    sub     r0, r2, r1
    bt      pw_skip_adv
    sub     r0, r1, r2
    bt      pw_skip_done
pw_skip_adv:
    addi    r3, 1
    li      r2, var_tib_idx
    swr     r3, r2
    li      r3, pw_skip
    jalr    r0, r3
pw_skip_done:
pw_copy:
    li      r1, 32
    li      r2, var_tib_idx
    lwr     r3, r2
    li      r2, TIB_MAX
    sub     r0, r3, r2
    bf      pw_done
    li      r2, tib
    add     r2, r2, r3
    lwr     r2, r2
    sub     r0, r0, r2
    bf      pw_done
    sub     r0, r2, r1
    bt      pw_done
    sub     r0, r1, r2
    bt      pw_copy_put
    li      r3, pw_done
    jalr    r0, r3
pw_copy_put:
    li      r1, var_word_len
    lwr     r4, r1
    li      r1, WORD_MAX
    sub     r0, r4, r1
    bf      pw_done
    li      r1, word_buf
    add     r1, r1, r4
    swr     r2, r1
    addi    r4, 1
    li      r1, var_word_len
    swr     r4, r1
    addi    r3, 1
    li      r2, var_tib_idx
    swr     r3, r2
    li      r3, pw_copy
    jalr    r0, r3
pw_done:
    jalr    r0, r5
pw_empty:
    li      r2, 0
    li      r3, var_word_len
    swr     r2, r3
    jalr    r0, r5

; T=1 if parsed an unsigned octal number (digits 0–7 only)
parse_number:
    li      r1, var_saved_r5
    swr     r5, r1
    li      r1, var_word_len
    lwr     r2, r1
    sub     r0, r0, r2
    bf      pnum_fail
    li      r3, 0
    li      r4, 0
pnum_loop:
    sub     r0, r4, r2
    bf      pnum_ok
    li      r1, word_buf
    add     r1, r1, r4
    lwr     r1, r1
    li      r5, 48
    sub     r0, r1, r5
    bt      pnum_fail
    li      r5, 56
    sub     r0, r1, r5
    bf      pnum_fail
    subi    r1, 48
    add     r5, r3, r3
    add     r5, r5, r5
    add     r5, r5, r5
    add     r3, r5, r1
    addi    r4, 1
    li      r3, pnum_loop
    jalr    r0, r3
pnum_ok:
    subi    r6, 1
    swr     r3, r6
    sub     r0, r0, r7
    li      r1, var_saved_r5
    lwr     r5, r1
    jalr    r0, r5
pnum_fail:
    clrt
    li      r1, var_saved_r5
    lwr     r5, r1
    jalr    r0, r5

; r2 = codeword field address
execute_xt:
    add     r3, r2, r0
    lwr     r2, r3
    jalr    r0, r2
