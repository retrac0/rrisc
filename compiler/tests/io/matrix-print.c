#include "io_include.h"

/*
 * On the host, rrisc_host_puts expects int* word strings; remap puts so plain
 * "..." literals (ASCII) work for titles. RCC keeps normal puts(int*).
 */
#if defined(RRISC_IO_TEST_HOST)
#undef puts
#define puts(S) rrisc_host_puts_cstr(S)
#endif

/*
 * Input data: fixed 3x3 row-major matrices from array literals (read-only use).
 * RCC has no `const` in parameter types, so globals are plain `int[]` like other tests.
 */
int MATRIX_A[9] = { 1, 2, 3, 4, 5, 6, 7, 8, 9 };
int MATRIX_B[9] = { 9, 8, 7, 6, 5, 4, 3, 2, 1 };

/* Pretty-print one matrix element: decimal digits then two spaces. */
void print_cell(int v) {
    int buf[8];
    int *p;
    p = itoa(v, buf);
    while (*p) {
        putchar(*p);
        p = p + 1;
    }
    putchar(' ');
    putchar(' ');
}

/* Indent, three rows of three cells, newline after each row. */
void print_mat_rows(int *m) {
    int r;
    int c;
    for (r = 0; r < 3; r = r + 1) {
        putchar(' ');
        putchar(' ');
        for (c = 0; c < 3; c = c + 1) {
            print_cell(m[r * 3 + c]);
        }
        putchar('\n');
    }
}

void mat_add_flat(int *a, int *b, int *out, int n) {
    int i;
    for (i = 0; i < n; i = i + 1) {
        out[i] = a[i] + b[i];
    }
}

/* Row-major n×n: out[i*n+j] = sum_k a[i*n+k]*b[k*n+j]. */
void mat_mul_flat(int *a, int *b, int *out, int n) {
    int i;
    int j;
    int k;
    int sum;
    for (i = 0; i < n; i = i + 1) {
        for (j = 0; j < n; j = j + 1) {
            sum = 0;
            for (k = 0; k < n; k = k + 1) {
                sum = sum + a[i * n + k] * b[k * n + j];
            }
            out[i * n + j] = sum;
        }
    }
}

int main() {
    int s[9];
    int p[9];

    mat_add_flat(MATRIX_A, MATRIX_B, s, 9);
    mat_mul_flat(MATRIX_A, MATRIX_B, p, 3);

    puts("Matrix A (3x3):");
    print_mat_rows(MATRIX_A);
    putchar('\n');
    puts("Matrix B (3x3):");
    print_mat_rows(MATRIX_B);
    putchar('\n');
    puts("A + B:");
    print_mat_rows(s);
    putchar('\n');
    puts("A * B:");
    print_mat_rows(p);
    exit(0);
    return 0;
}
