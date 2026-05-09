/*
 * rlibc_float_calc.h -- UART I/O + exit; itoa from lib/itoa.s (auto-%include by rcc).
 */
#ifndef RLIBC_FLOAT_CALC_H
#define RLIBC_FLOAT_CALC_H

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

int *gets(int *buf) {
    int *p = buf;
    while (1) {
        int ch = getchar();
        if (ch == 0) {
            break;
        }
        putchar(ch);
        if (ch == '\n') {
            break;
        }
        *p++ = ch;
    }
    *p = 0;
    return buf;
}

void exit(int code) {
    (void)code;
    asm("halt");
}

int *itoa(int n, int *buf);

#endif
