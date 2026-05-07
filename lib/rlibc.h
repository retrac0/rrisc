/*
 * rlibc.h -- minimal C library for the RRISC 12-bit machine
 *
 * Usage (requires host preprocessor):
 *   rcc [--no-optimize] --preprocessor "cpp -P" myprogram.c
 *   #include "rlibc.h"   (in your .c file)
 *
 * All values are 12-bit words.  Strings are int* with a null word terminator.
 * I/O uses the UART at the top of the address space:
 *   0o7770  TX RDY (read: 1=ready)   0o7772  TX BUF (write: send char)
 *   0o7771  RX RDY (read: 1=ready)   0o7773  RX BUF (read: recv char)
 */

#ifndef RLIBC_H
#define RLIBC_H

/* ---- I/O ---- */

void putchar(int c) {
    int *rdy = (int *)0o7770;
    int *buf = (int *)0o7772;
    while (!*rdy) {}
    *buf = c;
}

int getchar() {
    int *rdy = (int *)0o7771;
    int *buf = (int *)0o7773;
    while (!*rdy) {}
    return *buf;
}

void puts(int *s) {
    while (*s != 0) {
        putchar(*s);
        s = s + 1;
    }
    putchar('\n');
}

/* Read a line into buf (no bounds check); strips newline; returns buf. */
int *gets(int *buf) {
    int *p = buf;
    while (1) {
        int ch = getchar();
        if (ch == '\n') break;
        if (ch == 0) break;
        *p++ = ch;
    }
    *p = 0;
    return buf;
}

/* ---- Memory ---- */

int *memcpy(int *d, int *s, int n) {
    int *r = d;
    while (n--) *d++ = *s++;
    return r;
}

int *memset(int *d, int v, int n) {
    int *r = d;
    while (n--) *d++ = v;
    return r;
}

int memcmp(int *a, int *b, int n) {
    while (n > 0 && *a == *b) { a++; b++; n = n - 1; }
    return n == 0 ? 0 : *a - *b;
}

/* ---- String ---- */

int strlen(int *s) {
    int n = 0;
    while (s[n]) n = n + 1;
    return n;
}

int *strcpy(int *d, int *s) {
    int *r = d;
    while ((*d++ = *s++)) {}
    return r;
}

int *strcat(int *d, int *s) {
    int *r = d;
    while (*d) d++;
    while ((*d++ = *s++)) {}
    return r;
}

int strcmp(int *a, int *b) {
    while (*a && *a == *b) { a++; b++; }
    return *a - *b;
}

/* Return pointer to first occurrence of c in s, or 0 if not found. */
int *strchr(int *s, int c) {
    while (*s && *s != c) s++;
    return *s == c ? s : 0;
}

/* ---- Conversion ---- */

int abs(int x) {
    return x < 0 ? -x : x;
}

/* atoi: parse leading whitespace, optional '-', then digits. */
int atoi(int *s) {
    int n = 0;
    int neg = 0;
    while (*s == ' ' || *s == '\t') s++;
    if (*s == '-') { neg = 1; s++; }
    while (*s >= '0' && *s <= '9') n = n * 10 + (*s++ - '0');
    return neg ? -n : n;
}

/*
 * itoa: convert n to null-terminated decimal string in buf.
 * buf must hold at least 6 words (sign + 4 digits + NUL for 12-bit range).
 * Returns buf.  Handles 12-bit MIN (-2048): unary minus has no positive twin,
 * so "n = -n" would leave n unchanged and break the digit loop; emit "-2048".
 */
int *itoa(int n, int *buf) {
    int *p = buf;
    int neg = n < 0;
    if (neg) {
        int m = -n;
        if (m == n) {
            *p++ = '-';
            *p++ = '2';
            *p++ = '0';
            *p++ = '4';
            *p++ = '8';
            *p = 0;
            return buf;
        }
        n = m;
    }
    if (n == 0) { *p++ = '0'; }
    else {
        int *start = p;
        while (n) {
            *p++ = '0' + n % 10;
            n = n / 10;
        }
        /* reverse digits in place */
        int *end = p - 1;
        while (start < end) {
            int tmp = *start;
            *start++ = *end;
            *end-- = tmp;
        }
    }
    if (neg) {
        int len = p - buf;
        int i;
        for (i = len; i > 0; i = i - 1) buf[i] = buf[i - 1];
        buf[0] = '-';
        p++;
    }
    *p = 0;
    return buf;
}

/*
 * ftoa / atof: implemented in lib/float/__ftoa.s and lib/float/__atof.s (included by rcc
 * when these functions are called). Prototypes only here — do not add C bodies or
 * you will duplicate symbols at assembly time.
 */
int *ftoa(float *f, int *buf);
void atof(int *s, float *result);

/* ---- Control ---- */

void exit(int code) {
    (void)code;
    asm("halt");
}

#endif /* RLIBC_H */
