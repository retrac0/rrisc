#include "io_include.h"

/* Deterministic isqrt without relying on div rounding in Newton iteration. */
int isqrt(int n) {
  if (n <= 0) {
    return 0;
  }
  int r = 0;
  while (1) {
    int np1 = r + 1;
    int sq = np1 * np1;
    if (sq > n) {
      break;
    }
    r = np1;
  }
  return r;
}

int main() {
  int n = 1;
  while (n <= 40) {
    int buf[12];
    puts(itoa(isqrt(n), buf));
    n = n + 1;
  }
  exit(0);
  return 0;
}
