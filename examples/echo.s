; echo.s -- echo each UART byte back until a newline (or null) arrives.
;
; Demonstrates the new getchar / putchar pair and the UART RX/TX macros.
; The newline terminator keeps the demo halting under the test harness;
; a continuous-echo variant would just need the bf/halt block removed.
;
; Build & pipe input:
;   env PYTHONPATH=. python3 -m pytools.asm -I lib examples/echo.s -o /tmp/echo.bin
;   echo 'hello' | env PYTHONPATH=. python3 -m pytools.rrsim /tmp/echo.bin --terminal --start 0o1000

%include "macros/uart_tx.inc"
%include "macros/uart_rx.inc"

        .org 0o1000
_start:
        li   r6, 0o7770
echo_loop:
        li   r1, getchar
        jalr r5, r1
        ; r2 = char; halt on null
        sub  r0, r0, r2
        bf   echo_done
        li   r1, putchar
        jalr r5, r1
        ; halt after echoing newline (10): equality check via two-step compare
        li   r3, 10
        sub  r1, r2, r3            ; T=1 iff char < 10
        bt   echo_loop_keep
        sub  r0, r0, r1            ; T=1 iff char != 10
        bt   echo_loop_keep
        sub  r0, r0, r7            ; T=1: matched newline -> stop
        bt   echo_done
echo_loop_keep:
        sub  r0, r0, r7
        bt   echo_loop
echo_done:
        halt

%include "io/putchar.s"
%include "io/getchar.s"
