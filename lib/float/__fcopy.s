; __fcopy(r2=*dst, r3=*src) -- copy 4-word float from src to dst
__fcopy:
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
    addi r3, 1
    addi r2, 1
    lwr  r1, r3
    swr  r1, r2
    jalr r0, r5
