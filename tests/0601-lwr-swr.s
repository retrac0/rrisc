; 0601-lwr-swr.s -- test lwr/swr register-indirect instructions
;
; lwr rd, ra : rd = mem[ra]
; swr rd, ra : mem[ra] = rd
;
; Writes two values to zero-page scratchpad via swr, reads them back
; with lwr into different destination registers.
;
; At halt:
;   r4 = 0o1234
;   r5 = 0o5670

%define SLOT0  0o60
%define SLOT1  0o61

        .org 0o1000

        li   r1, SLOT0
        li   r2, 0o1234
        swr  r2, r1         ; mem[SLOT0] = 0o1234

        li   r1, SLOT1
        li   r3, 0o5670
        swr  r3, r1         ; mem[SLOT1] = 0o5670

        li   r1, SLOT0
        lwr  r4, r1         ; r4 = mem[SLOT0] = 0o1234

        li   r1, SLOT1
        lwr  r5, r1         ; r5 = mem[SLOT1] = 0o5670

        halt
