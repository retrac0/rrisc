/*
 * rlmath.h -- float math library for the RRISC 12-bit machine
 *
 * Requires rlibc.h (for float support) to be included first.
 * All functions take and return floats by pointer (float48, 4 words each).
 */

#ifndef RLMATH_H
#define RLMATH_H

/*
 * float_sqrt: Newton-Raphson square root, 20 iterations.
 * Converges in ~5 iterations for float48 precision.
 * *x must be >= 0; float_sqrt(0) = 0.
 */
void float_sqrt(float *result, float *x) {
    float zero = 0.0;
    float one = 1.0;
    float half = 0.5;
    float g;
    float tmp;
    int i;

    if (*x == zero) { *result = zero; return; }
    g = *x * half;
    if (g == zero) { g = one; }
    for (i = 0; i < 20; i = i + 1) {
        tmp = *x / g;
        g = (g + tmp) * half;
    }
    *result = g;
}

/* float_abs: *result = |*x| */
void float_abs(float *result, float *x) {
    float zero = 0.0;
    if (*x < zero) {
        *result = -*x;
    } else {
        *result = *x;
    }
}

/* float_pow: *result = (*x)^n  (integer exponent, n >= 0) */
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

#endif /* RLMATH_H */
