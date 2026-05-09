/*
 * rpn_int.c -- RPN integer calculator for the RRISC 12-bit machine (fits in 4k words).
 *
 * For floating-point, see rpn_float.c.
 *
 * Build (from repo root):
 *   make -C demos rpn.bin
 *
 * Run (linked image: crt0 at --start 0o100, stack from RCC_STACK_TOP).
 * Use bash $'...' for --uart-preload: command substitution "$(printf ...)" strips a
 * trailing newline, so the second gets() would hang waiting after "q".
 *   python3 sim.py --terminal --mem ram:0:0o7770 --start 0o100 \
 *     --uart-preload $'3 4 + p\nq\n' demos/rpn.bin
 * Or feed stdin (no preload):  printf '%s\n' '3 4 + p' q | python3 sim.py ... demos/rpn.bin
 *
 * Operators (space-separated on one line or across multiple lines):
 *   NUMBER  push (decimal int, optional leading -)
 *   +  -  *  /   binary arithmetic (pop two, push result)
 *   n       negate (pop, push negative)
 *   p       print top of stack (does not pop)
 *   d       duplicate top of stack
 *   c       clear stack
 *   q       quit (halts simulator)
 *
 * On invalid input or runtime error, prints $$$ and a newline (rpn_emit_err in lib/rpn_err.s).
 * Use sp >= 2 / sp > 0 for stack checks — rcc mis-compiles sp < n in conditionals.
 */

/* UART + exit; itoa from lib/itoa.s (rcc auto-%include). Avoid rlibc.h here or
 * you get a duplicate 'itoa' label (C body + itoa.s). */
#include "rlibc_float_calc.h"

void rpn_emit_err();

int stk[16];
int sp = 0;

int isdigitch(int c) {
    return c >= '0' && c <= '9';
}

int main() {
    int buf[64];
    int sbuf[8];
    int *p;
    int a;
    int b;
    int r;
    int neg;
    int val;

    while (1) {
        putchar('!');
        putchar(' ');
        gets(buf);
        p = buf;

        while (*p != 0) {
            while (*p == ' ' || *p == '\t') p++;
            if (*p == 0) break;

            if (isdigitch(*p) ||
                (*p == '-' && isdigitch(*(p + 1)))) {
                neg = 0;
                if (*p == '-') {
                    neg = 1;
                    p++;
                }
                val = 0;
                while (isdigitch(*p)) {
                    val = val * 10 + (*p - '0');
                    p++;
                }
                if (neg) val = -val;
                if (sp < 16) {
                    stk[sp] = val;
                    sp++;
                } else {
                    rpn_emit_err();
                }
            } else if (*p == '+') {
                if (sp >= 2) {
                    sp--;
                    b = stk[sp];
                    sp--;
                    a = stk[sp];
                    r = a + b;
                    stk[sp] = r;
                    sp++;
                } else {
                    rpn_emit_err();
                }
                p++;
            } else if (*p == '-') {
                if (sp >= 2) {
                    sp--;
                    b = stk[sp];
                    sp--;
                    a = stk[sp];
                    r = a - b;
                    stk[sp] = r;
                    sp++;
                } else {
                    rpn_emit_err();
                }
                p++;
            } else if (*p == '*') {
                if (sp >= 2) {
                    sp--;
                    b = stk[sp];
                    sp--;
                    a = stk[sp];
                    r = a * b;
                    stk[sp] = r;
                    sp++;
                } else {
                    rpn_emit_err();
                }
                p++;
            } else if (*p == '/') {
                if (sp >= 2) {
                    b = stk[sp - 1];
                    if (b == 0) {
                        rpn_emit_err();
                    } else {
                        sp--;
                        b = stk[sp];
                        sp--;
                        a = stk[sp];
                        r = a / b;
                        stk[sp] = r;
                        sp++;
                    }
                } else {
                    rpn_emit_err();
                }
                p++;
            } else if (*p == 'n') {
                if (sp > 0) {
                    sp--;
                    a = stk[sp];
                    r = -a;
                    stk[sp] = r;
                    sp++;
                } else {
                    rpn_emit_err();
                }
                p++;
            } else if (*p == 'p') {
                if (sp > 0) {
                    itoa(stk[sp - 1], sbuf);
                    puts(sbuf);
                } else {
                    rpn_emit_err();
                }
                p++;
            } else if (*p == 'd') {
                if (sp > 0) {
                    if (sp < 16) {
                        a = stk[sp - 1];
                        stk[sp] = a;
                        sp++;
                    } else {
                        rpn_emit_err();
                    }
                } else {
                    rpn_emit_err();
                }
                p++;
            } else if (*p == 'c') {
                sp = 0;
                p++;
            } else if (*p == 'q') {
                exit(0);
            } else {
                rpn_emit_err();
                p++;
            }
        }
    }
    return 0;
}
