/*
 * rlmath.c -- float math library (compiled as its own translation unit).
 *
 * Do not include rlibc_float_calc.h here: that header defines putchar/puts/…
 * in every TU; linking two rcc objects would duplicate those symbols.
 * Only rlmath.h (prototypes) is needed — float ops lower to lib/float/*.s.
 */

#include "rlmath.h"

/*
 * float_sqrt: Newton-Raphson square root, 20 iterations.
 * *x must be >= 0; float_sqrt(0) = 0.
 */
void float_sqrt(float *result, float *x) {
    float zero = 0.0;
    float one = 1.0;
    float half = 0.5;
    float g;
    float tmp;
    float sum;
    int i;

    if (*x == zero) { *result = zero; return; }
    g = *x * half;
    if (g == zero) { g = one; }
    for (i = 0; i < 20; i = i + 1) {
        tmp = *x / g;
        /* Split add/mul: (g+tmp)*half must not fold into one assign or rcc
         * emits integer __mul instead of __fmul (see demos/print_float). */
        sum = g + tmp;
        g = sum * half;
    }
    *result = g;
}

void float_abs(float *result, float *x) {
    float zero = 0.0;
    if (*x < zero) {
        *result = -*x;
    } else {
        *result = *x;
    }
}

void float_pow(float *result, float *x, int n) {
    float one = 1.0;
    float r;
    int i;
    r = one;
    for (i = 0; i < n; i = i + 1) {
        r = r * *x;
    }
    *result = r;
}
