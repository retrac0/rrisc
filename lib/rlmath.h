/*
 * rlmath.h -- float math declarations for the RRISC 12-bit machine.
 *
 * Include rlibc.h or rlibc_float_calc.h first (float / I/O support).
 * Implementations live in lib/rlmath.c (compiled and linked separately).
 */

#ifndef RLMATH_H
#define RLMATH_H

void float_sqrt(float *result, float *x);
void float_abs(float *result, float *x);
void float_pow(float *result, float *x, int n);

#endif /* RLMATH_H */
