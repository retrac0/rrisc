; crt0.s — RRISC C runtime startup (linked separately from rcc output).
;
; The compiler does not %include this file. Build with ras -o crt0.o and link
; with rld before the rcc-generated object (crt0.o first), using --code-base and
; --data-base matching the program's %define RCC_* lines.
;
; Defaults below suit standalone assembly; tests/build scripts pass -D RCC_STACK_TOP=...
; ABI: r6=SP, r5=LR; jalr target in r1.

%define RCC_STACK_TOP 0o3000

    .global _start

    .section text

_start:
    li   r6, RCC_STACK_TOP
    li   r1, main
    jalr r5, r1
    halt
