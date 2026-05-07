/*
 * rlibc_io.h -- tiny subset of rlibc.h for compiler/tests/io (no float helpers).
 * Keeps putchar/getchar/puts/gets/itoa/exit in sync with rlibc.h for word-at-a-time I/O.
 */
#ifndef RLIBC_IO_H
#define RLIBC_IO_H

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
        if (ch == '\n')
            break;
        if (ch == 0)
            break;
        *p++ = ch;
    }
    *p = 0;
    return buf;
}

void exit(int code) {
    (void)code;
    asm("halt");
}

int *itoa(int n, int *buf) {
    int *p = buf;
    int neg = n < 0;
    if (neg) {
        n = -n;
    }
    if (n == 0) {
        *p++ = '0';
    } else {
        int *start = p;
        while (n) {
            *p++ = '0' + n % 10;
            n = n / 10;
        }
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
        for (i = len; i > 0; i = i - 1)
            buf[i] = buf[i - 1];
        buf[0] = '-';
        p++;
    }
    *p = 0;
    return buf;
}

#endif /* RLIBC_IO_H */
