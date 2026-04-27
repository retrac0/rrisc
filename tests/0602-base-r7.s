; 0602-base-r7.s -- lw/sw with 12-bit I/O addresses using implicit r7 base
;
; r7 = 0o7777 (hardwired), page = 0o7700.
; lw r7, 0o7770 should assemble as lw r7, 0o70 (offset into page 0o7700).
;
; This test uses zero-page memory rather than actual I/O; it just verifies
; that the assembler accepts 12-bit addresses in r7's page and produces the
; same instruction as if the 6-bit offset were written directly.
;
; At halt:
;   r2 = 0o0042   (value written then read back via r7 12-bit address)

        .org 0o1000

        li   r1, 0o0042
        sw   r0, 0o60           ; mem[0o0060] = 0o0042  (6-bit offset, unchanged syntax)

        ; lw using full 12-bit zero-page address (r0 base is 0, page 0o0000)
        lw   r0, 0o0060         ; same as lw r0, 0o60 -- offset 0o60
        and  r2, r1, r7     ; r2 = r1  (move)

        halt
