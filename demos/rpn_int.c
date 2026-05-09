/*
 * rpn_int.c -- compact RPN integer calculator (RRISC 12-bit).
 * Build: make -C demos rpn.bin
 *
 * Operators: decimal numbers, + - * /, n p d c q (see test_rpn.sh).
 * Smaller globals and input buffer; merged + - * /; no debug putchar.
 * Use sp >= 2 / sp > 0 for checks (avoid sp < n in conditionals with this rcc).
 */
#include "rlibc_float_calc.h"

void rpn_emit_err();

#define STK_SZ 8

int stk[STK_SZ];
int sp;

int isdigitch(int c) {
    return c >= '0' && c <= '9';
}

int main() {
    int buf[36];
    int sbuf[8];
    int *p;
    int *q;
    int a;
    int b;
    int r;
    int neg;
    int val;
    int c;

    sp = 0;
    while (1) {
        gets(buf);
        p = buf;
        while (1) {
            c = *p;
            if (c == 0) {
                break;
            }
            while (c == ' ' || c == '\t') {
                p = p + 1;
                c = *p;
            }
            if (c == 0) {
                break;
            }

            q = p + 1;
            if (isdigitch(c) || (c == '-' && isdigitch(*q))) {
                neg = 0;
                if (c == '-') {
                    neg = 1;
                    p = p + 1;
                    c = *p;
                }
                val = 0;
                while (isdigitch(c)) {
                    val = val * 10 + (c - '0');
                    p = p + 1;
                    c = *p;
                }
                if (neg) {
                    val = 0 - val;
                }
                if (sp < STK_SZ) {
                    stk[sp] = val;
                    sp = sp + 1;
                } else {
                    rpn_emit_err();
                }
            } else if (c == '+' || c == '-' || c == '*' || c == '/') {
                if (sp >= 2) {
                    sp = sp - 1;
                    b = stk[sp];
                    sp = sp - 1;
                    a = stk[sp];
                    if (c == '/') {
                        if (b == 0) {
                            rpn_emit_err();
                        } else {
                            r = a / b;
                            stk[sp] = r;
                            sp = sp + 1;
                        }
                    } else {
                        if (c == '+') {
                            r = a + b;
                        } else if (c == '-') {
                            r = a - b;
                        } else {
                            r = a * b;
                        }
                        stk[sp] = r;
                        sp = sp + 1;
                    }
                } else {
                    rpn_emit_err();
                }
                p = p + 1;
            } else if (c == 'n') {
                if (sp > 0) {
                    a = stk[sp - 1];
                    r = 0 - a;
                    stk[sp - 1] = r;
                } else {
                    rpn_emit_err();
                }
                p = p + 1;
            } else if (c == 'p') {
                if (sp > 0) {
                    itoa(stk[sp - 1], sbuf);
                    puts(sbuf);
                } else {
                    rpn_emit_err();
                }
                p = p + 1;
            } else if (c == 'd') {
                if (sp > 0) {
                    if (sp < STK_SZ) {
                        a = stk[sp - 1];
                        stk[sp] = a;
                        sp = sp + 1;
                    } else {
                        rpn_emit_err();
                    }
                } else {
                    rpn_emit_err();
                }
                p = p + 1;
            } else if (c == 'c') {
                sp = 0;
                p = p + 1;
            } else if (c == 'q') {
                exit(0);
            } else {
                rpn_emit_err();
                p = p + 1;
            }
        }
    }
}
