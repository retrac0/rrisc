; fib-recursive.s -- Recursive Fibonacci using stack.lib
;
; Computes fib(n) using recursive calls and an explicit stack.
; The stack grows downward from the end of RAM at 0o77.
; `r6` is initialized to 0o100 so the first `push` stores at 0o77.
;
; Register usage:
;   r2  input argument n
;   r3  return value fib(n)
;   r4  temporary address/value
;   r5  link register (stack.lib call/ret)
;   r6  stack pointer
;   r7  hardwired -1
;
%include "stack.lib"
        .org 0o1000

start:
        li   r6, 0o100          ; empty stack pointer above RAM end
        li   r2, 16           ; compute fib(16) = ...
        call fib
        halt

; fib(n): return fib(n) in r3.
; Uses the stack to save the caller link and the current argument.
fib:
        push r5
        push r2

        sub  r0, r0, r2         ; T=0 if n==0, T=1 if n>0
        bf   fib_leaf
        li   r1, 1
        sub  r4, r2, r1         ; r4 = n-1; T=borrow (0, since n>0)
        sub  r0, r0, r4         ; T=0 if n==1, T=1 if n>1
        bf   fib_leaf

        ; fib(n-1)
        subi r2, 1              ; r2 = n - 1
        push r5
        call fib
        pop  r5
        push r3                 ; save fib(n-1)

        ; restore original n and compute fib(n-2)
        and  r4, r6, r7         ; r4 = r6  (move, T-independent)
        addi r4, 1              ; r4 = r6 + 1 = address of saved argument n
        lwr  r2, r4
        subi r2, 2              ; r2 = n - 2
        push r5
        call fib
        pop  r5

        lwr  r4, r6             ; load saved fib(n-1)
        add  r3, r3, r4         ; r3 = fib(n-2) + fib(n-1)

        addi r6, 1              ; pop saved fib(n-1)
        addi r6, 1              ; pop saved argument n
        pop  r5
        ret

fib_leaf:
        and  r3, r2, r7         ; r3 = n  (move, T-independent)
        addi r6, 1              ; pop saved argument n
        pop  r5
        ret
