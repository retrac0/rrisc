/*
 * rpn_float.c -- soft-float RPN; int literals; truncated int print; fits 4k flat.
 */
#include "rlibc_float_calc.h"

float stk[8];
int stkptr;
int gsbuf[8];

int isdigitch(int c) {
    return c >= '0' && c <= '9';
}

void stk_push1(float r) {
    stk[stkptr] = r;
    stkptr++;
}

void stk_pop2(float *a, float *b) {
    stkptr--;
    *b = stk[stkptr];
    stkptr--;
    *a = stk[stkptr];
}

void do_arith(int op) {
    float a;
    float b;
    stk_pop2(&a, &b);
    if (op == 0) stk_push1(a + b);
    else if (op == 1) stk_push1(a - b);
    else if (op == 2) stk_push1(a * b);
    else stk_push1(a / b);
}

void do_neg() {
    float a;
    stkptr--;
    a = stk[stkptr];
    stk_push1(-a);
}

void do_dup() {
    float a;
    if (stkptr > 0) {
        a = stk[stkptr - 1];
        stk_push1(a);
    }
}

void do_print(int *sb) {
    int k;
    if (stkptr > 0) {
        k = (int)stk[stkptr - 1];
        itoa(k, sb);
        puts(sb);
    }
}

int *parse_int(int *p) {
    int n;
    int neg;
    int d;
    float r;
    n = 0;
    neg = 0;
    if (*p == '-') {
        neg = 1;
        p++;
    }
    while (isdigitch(*p)) {
        d = *p - '0';
        n = (n << 3) + (n << 1) + d;
        p++;
    }
    if (neg) n = -n;
    r = (float)n;
    stk_push1(r);
    return p;
}

int main() {
    int buf[24];
    int *p;

    stkptr = 0;
    while (1) {
        gets(buf);
        p = buf;
        while (*p != 0) {
            while (*p == ' ' || *p == '\t') p++;
            if (*p == 0) break;

            if (isdigitch(*p) ||
                (*p == '-' && isdigitch(*(p + 1)))) {
                p = parse_int(p);
            } else if (*p == '+') {
                do_arith(0);
                p++;
            } else if (*p == '-') {
                do_arith(1);
                p++;
            } else if (*p == '*') {
                do_arith(2);
                p++;
            } else if (*p == '/') {
                do_arith(3);
                p++;
            } else if (*p == 'n') {
                do_neg();
                p++;
            } else if (*p == 'p') {
                do_print(gsbuf);
                p++;
            } else if (*p == 'd') {
                do_dup();
                p++;
            } else if (*p == 'c') {
                stkptr = 0;
                p++;
            } else if (*p == 'q') {
                exit(0);
            } else {
                p++;
            }
        }
    }
    return 0;
}
