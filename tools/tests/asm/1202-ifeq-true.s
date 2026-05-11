%define M 2+3
        .org 0o1000
%ifeq M 5
        li r1, 1
%endif
        halt
