%define A 1
        .org 0o1000
%ifeq 1 1
%ifdef A
        li r1, 1
%endif
%endif
%ifeq 1 2
%ifdef A
        li r1, 99
%endif
%endif
        halt
