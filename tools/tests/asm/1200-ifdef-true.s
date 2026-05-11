%define FLAG 1
        .org 0o1000
%ifdef FLAG
        li r1, 1
%endif
        halt
