/*
 * rlibc_host.h -- POSIX counterparts to lib/rlibc.h for rrisc_io tests.
 *
 * Used only with -DRRISC_IO_TEST_HOST. Symbols are rrisc_host_*; tests call
 * putchar/puts/gets/exit via macros in compiler/tests/io/io_include.h so we
 * never collide with libc (puts, putchar, exit).
 */

#ifndef RLIBC_HOST_H
#define RLIBC_HOST_H

#include <stdio.h>
#include <stdlib.h>

static inline int rrisc_word_char(int c) { return c & 0xFFF; }

void rrisc_host_putchar(int c) {
    int ch = rrisc_word_char(c);
    unsigned char out = (unsigned char)(ch > 127 ? (ch & 0x7F) : ch);
    fputc(out, stdout);
    fflush(stdout);
}

int rrisc_host_getchar(void) {
    int c = fgetc(stdin);
    if (c == EOF)
        return 0;
    return c & 0xFFF;
}

void rrisc_host_puts(int *s) {
    while (*s != 0) {
        rrisc_host_putchar(*s);
        s = s + 1;
    }
    rrisc_host_putchar('\n');
}

/* ASCII titles / Line-oriented output from standard string literals (host gcc only). */
void rrisc_host_puts_cstr(const char *s) {
    const char *p = s;
    while (*p) {
        rrisc_host_putchar((int)(unsigned char)*p);
        p = p + 1;
    }
    rrisc_host_putchar('\n');
}

int *rrisc_host_gets(int *buf) {
    int *p = buf;
    while (1) {
        int ch = rrisc_host_getchar();
        if (ch == '\n')
            break;
        if (ch == 0)
            break;
        *p++ = ch;
    }
    *p = 0;
    return buf;
}

void rrisc_host_exit(int code) {
    (void)code;
    _Exit(0);
}

/*
 * itoa: same algorithm as lib/rlibc.h (word-oriented decimal string).
 */
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

#endif /* RLIBC_HOST_H */
