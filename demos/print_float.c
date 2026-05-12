/*
 * print_float.c — print sqrt(42) using rlmath (float_sqrt) and ftoa/puts.
 *
 * Use rlibc_float_calc.h (not full rlibc.h) so itoa comes only from lib/itoa.s
 * via the float runtime; a C itoa body would duplicate that symbol.
 *
 * Float locals live on the stack; their addresses are passed to float_sqrt and
 * ftoa like globals.
 */
#include "rlibc_float_calc.h"

int *ftoa(float *f, int *buf);

#include "rlmath.h"

int buf[24];

int main() {
    float n;
    float r;
    n = 42.0;
    float_sqrt(&r, &n);
    ftoa(&r, buf);
    puts(buf);
    return 0;
}
