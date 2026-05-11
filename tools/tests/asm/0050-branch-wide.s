; 0050-branch-wide.s -- verify branch offsets beyond the old ±31 limit
;
; With the r7 extension bf/bt accept -64..+63.  Both test branches here use
; an offset of ±33, which was previously out of range.
;
; Result at halt: r1=0001 r2=0001

        .org 0o1000

        and  r1, r0, r0         ; r1 = 0
        and  r2, r0, r0         ; r2 = 0

        ; --- Test 1: wide forward bf (offset +33) ---
        sub  r0, r0, r0         ; T = 0
        bf   fwd_target         ; taken (T=0); offset = fwd_target - here = +33
        halt                    ; NOT reached
        .fill 31                ; gap: 1 halt + 31 fill = 32 words → offset = 33

fwd_target:
        addi r1, 1              ; r1 = 1

        ; --- Test 2: wide backward bf (offset -33) ---
        sub  r0, r0, r0         ; T = 0
        bf   wide_back          ; forward jump to wide_back; offset = +33
        ; NOT reached:
back_target:
        addi r2, 1              ; r2 = 1
        halt

        .fill 30                ; gap: 2 (back_target+halt) + 30 fill = 32 → backward offset -33

wide_back:
        sub  r0, r0, r0         ; T = 0
        bf   back_target        ; taken (T=0); offset = back_target - here = -33
        halt                    ; NOT reached
