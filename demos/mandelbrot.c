/*
 * mandelbrot.c — ASCII Mandelbrot over UART; escape time mapped linearly to a glyph ramp.
 *
 * Same float + I/O contract as print_float.c (rlibc_float_calc.h, --embed-full-float-runtime).
 *
 * Chained float multiplies must be split (e.g. t = a * b; t = t * c): rcc may emit __mul
 * instead of __fmul for a*b*c or (a-b)*c otherwise.
 * Likewise (zr2 - zi2) + cr must be two assignments: rcc may emit integer add of addresses
 * after __fsub instead of __fadd.
 */
#include "rlibc_float_calc.h"

#define WIDTH 32
#define HEIGHT 24
#define MAX_ITER 32

/* ramp[0] = fastest escape; interior uses ' ' so ramp should not start with space */
#define RAMP_LEN 9

int main() {
    int *ramp;
    int py;
    int px;
    int k;
    int idx;
    float zr;
    float zi;
    float cr;
    float ci;
    float zr2;
    float zi2;
    float sumsq;
    float two;
    float four;
    float re_min;
    float re_max;
    float im_min;
    float im_max;
    float fw;
    float fh;
    float imx;
    float imy;
    float span;
    float zcross;

    ramp = ".:-=+*#%@";
    two = 2.0;
    four = 4.0;
    re_min = -2.0;
    re_max = 1.0;
    im_min = -1.0;
    im_max = 1.0;
    fw = (float)(WIDTH - 1);
    fh = (float)(HEIGHT - 1);

    py = 0;
    while (py < HEIGHT) {
        imy = (float)py / fh;
        span = im_max - im_min;
        span = span * imy;
        ci = im_max - span;
        px = 0;
        while (px < WIDTH) {
            imx = (float)px / fw;
            span = re_max - re_min;
            span = span * imx;
            cr = re_min + span;
            zr = 0.0;
            zi = 0.0;
            k = 0;
            while (k < MAX_ITER) {
                zr2 = zr * zr;
                zi2 = zi * zi;
                sumsq = zr2 + zi2;
                if (sumsq <= four) {
                    zcross = zr * zi;
                    zcross = two * zcross;
                    zi = zcross + ci;
                    zr = zr2 - zi2;
                    zr = zr + cr;
                    k = k + 1;
                } else {
                    break;
                }
            }
            if (k == MAX_ITER) {
                putchar(' ');
            } else {
                idx = (k * (RAMP_LEN - 1)) / (MAX_ITER - 1);
                putchar(ramp[idx]);
            }
            px = px + 1;
        }
        putchar('\n');
        py = py + 1;
    }
    return 0;
}
