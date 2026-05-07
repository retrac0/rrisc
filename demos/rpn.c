/*
 * rpn.c -- RPN integer calculator for the RRISC 12-bit machine (fits in 4k words).
 *
 * For floating-point (larger binary, typically >4k words), see rpn_float.c.
 *
 * Compile:
 *   rcc --preprocessor "cpp -P -I lib" demos/rpn.c -o demos/rpn.s
 *
 * Optimizations are on by default (needed to fit this demo in 4k words). Use
 * --no-optimize only for debugging TAC/asm (large programs may fail to assemble).
 *   python3 asm.py -I lib demos/rpn.s -o demos/rpn.bin
 *
 * Run (PC must be the code entry; with default rcc layout this is often 0o21):
 *   python3 sim.py --terminal --start 0o21 demos/rpn.bin
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

#include "rlibc.h"

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
