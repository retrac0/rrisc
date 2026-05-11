; forth/forth.s — minimal indirect-threaded Forth for RRISC
;
; Structure follows Richard Jones's jonesforth (see references/jonesforth-riscv/)
; and jjyr's RISC-V port: NEXT / DOCOL / EXIT, dictionary headers, outer interpreter.
;
; Register map (inner interpreter):
;   r1  IP — address into threaded code (one word per token)
;   r3  xt pointer (codeword cell) preserved for DOCOL
;   r4  return stack pointer (grows down from RSTACK0)
;   r6  data stack pointer (grows down from RCC_STACK_TOP; ABI matches crt0)
;
; Long jumps: li r3, label ; jalr r0, r3
;
; Example programs (after each "ok " prompt, type words separated by spaces, then newline).
; Each typed character is echoed on the UART as it is read (refill_tib → forth_uart_tx_r2).
; Built-ins are BYE EXIT CR . KEY EMIT + - DUP SWAP DROP HELLO PUTS (see dictionary below).
;   PUTS — C-style: pop data address of a zero-terminated string (one char per word); print until NUL.
;       Example: push the address of a .word string then PUTS (see HELLO / str_boot in this file).
;
;   BYE
;       Halt the machine — good for scripted runs: demos/test_forth.sh smoke (UART preload).
;
;   HELLO
;       Execute the threaded HELLO definition (DOCOL … EXIT); prints the same banner as boot.
;
;   3 4 + .
;       RPN stack: push 3 and 4, add, print top with "." (unsigned octal plus trailing space).
;
;   7 3 - .
;       Octal literals: 7-3 = 4; prints "4 ".
;
;   5 DUP + .
;       Duplicate the top item (5 5 +) and print — exercises DUP and +.
;
;   HELLO CR 52 .
;       Chained control: banner, newline (CR), push 52 (octal 42 decimal), print with ".".
;
;   1 2 SWAP - .
;       SWAP then subtract (2 - 1); prints "1 ".
;
; Build & smoke test:  make -C demos forth.bin && ./demos/test_forth.sh smoke
; Interactive UART:    make -C demos run-forth   (type lines; end with BYE to halt)
;
; Sources: io.s (UART / puts / refill), core.s (NEXT / FIND / parse), primitives.s (code words).

%define RCC_CODE_BASE 0o100
%define RCC_DATA_BASE 0o6600
%define RCC_STACK_TOP 0o7770

%define RSTACK0       0o7740
%define TIB_MAX       40
%define WORD_MAX      24

%include "macros/uart_tx.inc"
%include "macros/uart_rx.inc"

    .section text

    .global main

%include "io.s"
%include "core.s"
%include "primitives.s"
%include "dict.s" 


; ---------- main --------------------------------------------------------------

main:
    li      r6, RCC_STACK_TOP
    li      r4, RSTACK0
    li      r2, name_puts
    li      r3, var_latest
    swr     r2, r3

    li      r3, var_saved_ip
    swr     r1, r3
    li      r4, str_boot
    li      r3, puts0_r4
    jalr    r5, r3
    li      r1, var_saved_ip
    lwr     r1, r1

quit_loop:
    li      r3, var_saved_ip
    swr     r1, r3
    li      r4, str_ok
    li      r3, puts0_r4
    jalr    r5, r3
    li      r1, var_saved_ip
    lwr     r1, r1

read_line:
    li      r3, refill_tib
    jalr    r5, r3
    li      r3, parse_word
    jalr    r5, r3

    li      r1, var_word_len
    lwr     r2, r1
    sub     r0, r0, r2
    bf      read_line

    li      r3, find_word
    jalr    r5, r3
    sub     r0, r0, r2
    bf      q_try_num

    li      r3, execute_xt
    jalr    r5, r3
    li      r3, quit_loop
    jalr    r0, r3
q_try_num:
    li      r3, parse_number
    jalr    r5, r3
    bt      quit_loop

    li      r3, var_saved_ip
    swr     r1, r3
    li      r4, str_unknown
    li      r3, puts0_r4
    jalr    r5, r3
    li      r1, var_saved_ip
    lwr     r1, r1
    li      r3, quit_loop
    jalr    r0, r3

    .section data

var_saved_ip:   .word 0
var_saved_r5:   .word 0
var_refill_lr:  .word 0
var_find_lr:    .word 0
var_latest:     .word 0
var_word_len:   .word 0
var_tib_idx:    .word 0
var_parse_idx:  .word 0

tib:            .fill 41
word_buf:       .fill 24

; .strz: UTF-8 bytes one per word + trailing 0 (PUTS / puts0_r4).
str_boot:
    .strz "\nrrisc forth\n"

str_ok:
    .strz "ok "

str_unknown:
    .strz "?\n"
