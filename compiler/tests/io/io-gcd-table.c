#include "io_include.h"

/* Binary GCD-style subtraction (positive inputs only); avoids a broken mod/swap lowering path. */
int gcd(int a, int b) {
  while (a != b) {
    if (a > b) {
      a = a - b;
    } else {
      b = b - a;
    }
  }
  return a;
}

void print_int(int v) {
  int buf[12];
  int *p = itoa(v, buf);
  while (*p) {
    putchar(*p);
    p = p + 1;
  }
}

int main() {
  int i = 1;
  while (i <= 8) {
    int j = 1;
    while (j <= 8) {
      print_int(gcd(i, j));
      if (j < 8) {
        putchar(' ');
      }
      j = j + 1;
    }
    putchar('\n');
    i = i + 1;
  }
  exit(0);
  return 0;
}
