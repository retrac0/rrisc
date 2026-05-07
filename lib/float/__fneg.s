; __fneg(r2=*dst, r3=*src) -- dst = -src  (flip sign bit of w0, copy w1-w3)
__fneg:
    lwr  r1, r3          ; r1 = src.w0
    addi r3, 1
    ; flip bit 11: XOR with 0o4000
    ; XOR a, b = (a | b) - (a & b) but easier: add 0o4000 wraps correctly
    ; bit 11 flip: if bit11=0, add 0o4000; if bit11=1, sub 0o4000.
    ; Use: w0 ^ 0o4000 = w0 + 0o4000 when bit11=0, w0 - 0o4000 when bit11=1.
    ; Both cases: w0 XOR 0o4000 = (w0 + 0o4000) & 0xFFF
    li   r4, 0o4000
    add  r1, r1, r4      ; toggle bit 11 (wraps mod 4096)
    swr  r1, r2
    addi r2, 1
    lwr  r1, r3
    swr  r1, r2
    addi r3, 1
    addi r2, 1
    lwr  r1, r3
    swr  r1, r2
    addi r3, 1
    addi r2, 1
    lwr  r1, r3
    swr  r1, r2
    jalr r0, r5
