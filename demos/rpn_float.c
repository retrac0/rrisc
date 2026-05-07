/*
 * rpn_float.c -- RPN floating-point calculator (soft-float runtime).
 *
 * The soft-float runtime (lib/float/*.s) plus __atof/__ftoa is larger than the RRISC
 * flat 12-bit address space (4096 words: code + rodata + globals must all fit in
 * 0..0o7777).  python3 asm.py will fail with "li value … out of 12-bit range".
 * Use integer demos/rpn.c for the stock demos layout, or a host build / larger
 * memory model if you extend the architecture.
 *
 * Compile like demos/rpn.c (same flags), output e.g. demos/rpn_float.s
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
            while (*p == ' ' || *p == '\t') p++;
            if (*p == 0) break;

            if (isdigitch(*p) ||
                (*p == '-' && isdigitch(*(p + 1))) ||
                (*p == '.' && isdigitch(*(p + 1)))) {
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
