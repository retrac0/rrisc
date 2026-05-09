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
 */

/* UART + exit; itoa from lib/itoa.s (rcc auto-%include). Avoid rlibc.h here or
 * you get a duplicate 'itoa' label (C body + itoa.s). */
#include "rlibc_float_calc.h"

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
                stk[sp] = val;
                sp++;
            } else if (*p == '+') {
                sp--; b = stk[sp];
                sp--; a = stk[sp];
                r = a + b;
                stk[sp] = r; sp++;
                p++;
            } else if (*p == '-') {
                sp--; b = stk[sp];
                sp--; a = stk[sp];
                r = a - b;
                stk[sp] = r; sp++;
                p++;
            } else if (*p == '*') {
                sp--; b = stk[sp];
                sp--; a = stk[sp];
                r = a * b;
                stk[sp] = r; sp++;
                p++;
            } else if (*p == '/') {
                sp--; b = stk[sp];
                sp--; a = stk[sp];
                r = a / b;
                stk[sp] = r; sp++;
                p++;
            } else if (*p == 'n') {
                sp--; a = stk[sp];
                r = -a;
                stk[sp] = r; sp++;
                p++;
            } else if (*p == 'p') {
                if (sp > 0) {
                    itoa(stk[sp - 1], sbuf);
                    puts(sbuf);
                }
                p++;
            } else if (*p == 'd') {
                if (sp > 0) {
                    a = stk[sp - 1];
                    stk[sp] = a; sp++;
                }
                p++;
            } else if (*p == 'c') {
                sp = 0;
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
