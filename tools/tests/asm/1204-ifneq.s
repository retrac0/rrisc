        .org 0o1000
%ifneq 1 2
        li r1, 1
%endif
%ifneq 3 3
        li r1, 99
%endif
        halt
