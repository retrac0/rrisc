/*
 * rpn.c -- RPN floating-point calculator for the RRISC 12-bit machine
 *
 * Compile:
 *   rcc --preprocessor "cpp -P -I lib" demos/rpn.c -o demos/rpn.s
 *   python3 asm.py -I lib demos/rpn.s -o demos/rpn.bin
 *
 * Run interactively:
 *   python3 sim.py --terminal --start 0o1000 demos/rpn.bin
 *
 * Run scripted (piped input):
 *   echo "3.0 4.0 + p q" | python3 sim.py --terminal --start 0o1000 demos/rpn.bin
 *
 * Operators (space-separated on one line or across multiple lines):
 *   NUMBER  push (integer or decimal, optional leading -)
 *   +  -  *  /   binary arithmetic (pop two, push result)
 *   n       negate (pop, push negative)
 *   p       print top of stack (does not pop)
 *   d       duplicate top of stack
 *   c       clear stack
 *   q       quit (halts simulator)
 */

#include "rlibc.h"

float stk[16];
int sp = 0;

int isdigitch(int c) {
    return c >= '0' && c <= '9';
}

int main() {
    int buf[64];
    int sbuf[16];
    int *p;
    float a;
    float b;
    float r;

    while (1) {
        gets(buf);
        p = buf;

        while (*p != 0) {
            /* skip whitespace */
            while (*p == ' ' || *p == '\t') p++;
            if (*p == 0) break;

            if (isdigitch(*p) ||
                (*p == '-' && isdigitch(*(p + 1))) ||
                (*p == '.' && isdigitch(*(p + 1)))) {
                /* parse number and push */
                atof(p, &r);
                if (*p == '-') p++;
                while (isdigitch(*p) || *p == '.') p++;
                stk[sp] = r;
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
                    ftoa(&stk[sp - 1], sbuf);
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
