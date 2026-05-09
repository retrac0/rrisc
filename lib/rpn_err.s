; rpn_err.s -- print "$$$\n" for demos/rpn_int.c (keeps rcc from mis-sizing main's frame).
    .section text

    .global rpn_emit_err
rpn_emit_err:
    subi r6, 1
    swr r5, r6
    li r2, 36
    li r1, putchar
    jalr r5, r1
    li r2, 36
    li r1, putchar
    jalr r5, r1
    li r2, 36
    li r1, putchar
    jalr r5, r1
    li r2, 10
    li r1, putchar
    jalr r5, r1
    lwr r5, r6
    addi r6, 1
    jalr r0, r5
