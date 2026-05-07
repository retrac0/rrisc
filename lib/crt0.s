; crt0.s -- C runtime startup for rcc-generated programs.
; The compiler emits %define directives for these before %include-ing this file:
;   RCC_CODE_BASE  -- .org address (default 0o1000)
;   RCC_STACK_TOP  -- initial r6 value
;   RCC_DATA_BASE  -- .org address for writable globals (compiler emits separately)
;
; ABI: r6=SP, r5=LR; target address in r1 for jalr (r2–r4 unused here).

    .org RCC_CODE_BASE
_start:
    li   r6, RCC_STACK_TOP
    li   r1, main
    jalr r5, r1
    halt
